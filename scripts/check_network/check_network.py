#!/usr/bin/env python3
"""
Validates evaluated frablab network configuration JSON (from network-schema.nix):
- Strict IPv4/IPv6 CIDR syntax, prefix bounds, and cross-subnet overlap detection
- Duplicate VLAN ID and reverse DNS zone detection (IPv4 and IPv6)
- IP containment, boundary reservations, duplicate IPs, and DHCP collisions
- MAC format, unicast check, and per-subnet uniqueness
- DNS label/domain/email syntax, FQDN length limits, and forward-zone collisions
"""

import argparse
import ipaddress
from itertools import combinations
import json
from pathlib import Path
import re
import sys

_DNS_LABEL_PART = r"[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?"
DNS_LABEL_RE = re.compile(rf"^{_DNS_LABEL_PART}\Z")
ALIAS_RE = re.compile(rf"^{_DNS_LABEL_PART}(\.{_DNS_LABEL_PART})*\Z")
MAC_RE = re.compile(
    r"^(([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}|([0-9a-fA-F]{2}-){5}[0-9a-fA-F]{2})\Z"
)
_EMAIL_LOCAL_RE = re.compile(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+\Z")
MAX_DNS_NAME_LEN = 253


def _is_valid_domain(name: str, *, allow_trailing_dot: bool = False) -> bool:
    stripped = name[:-1] if allow_trailing_dot and name.endswith(".") else name
    return (
        bool(stripped)
        and len(stripped) <= MAX_DNS_NAME_LEN
        and bool(ALIAS_RE.match(stripped))
    )


def _is_valid_email(email: str) -> bool:
    local, sep, dom = email.partition("@")
    if (
        not sep
        or not local
        or local.startswith(".")
        or local.endswith(".")
        or ".." in local
        or not _EMAIL_LOCAL_RE.match(local)
    ):
        return False
    return _is_valid_domain(dom, allow_trailing_dot=True)


def _check_ip_in_network(
    ip: ipaddress.IPv4Address | ipaddress.IPv6Address,
    net: ipaddress.IPv4Network | ipaddress.IPv6Network,
    subject: str,
    errors: list[str],
) -> bool:
    if ip not in net:
        errors.append(f"{subject} {ip} is outside subnet {net}")
        return False
    if net.version == 4 and net.prefixlen < 31:
        if ip in (net.network_address, net.broadcast_address):
            errors.append(f"{subject} {ip} cannot be network or broadcast address")
    elif net.version == 6 and net.prefixlen < 127 and ip == net.network_address:
        errors.append(f"{subject} {ip} cannot be subnet-router anycast address")
    return True


def _check_dns_ips(dns: dict, label: str, errors: list[str]) -> None:
    for version, cls, key in (
        (4, ipaddress.IPv4Address, "ipv4"),
        (6, ipaddress.IPv6Address, "ipv6"),
    ):
        for ip in dns.get(key, []):
            try:
                cls(ip)
            except ValueError as e:
                errors.append(f"{label}: invalid IPv{version} DNS address '{ip}' ({e})")


def _collect_reserved_names(data: dict, errors: list[str]) -> set[str]:
    reserved = {"dns"}
    for sname, subnet in data.get("subnets", {}).items():
        reserved.add(sname.lower())
        for hname in subnet.get("hosts", {}):
            reserved.add(f"{hname}.{sname}".lower())
        gw_name = subnet.get("gateway", {}).get("name", "gateway")
        reserved.add(f"{gw_name}.{sname}".lower())

    def walk_subdomains(subs: dict, suffix: str = "") -> None:
        for sub_name, sub_val in subs.items():
            if (
                not sub_name
                or sub_name.startswith(".")
                or sub_name.endswith(".")
                or ".." in sub_name
                or any(ch.isspace() or ord(ch) < 32 for ch in sub_name)
            ):
                errors.append(
                    f"Network: extraRecords.subdomains has invalid subdomain key {sub_name!r}"
                )
                continue
            fq_rel = f"{sub_name}.{suffix}" if suffix else sub_name
            norm = fq_rel.lower()
            if norm in reserved:
                errors.append(
                    f"Network: extraRecords.subdomains '{fq_rel}' collides with reserved DNS name or host '{fq_rel}'"
                )
            else:
                reserved.add(norm)
            if isinstance(sub_val, dict) and isinstance(
                nested := sub_val.get("subdomains"), dict
            ):
                walk_subdomains(nested, fq_rel)

    walk_subdomains(data.get("extraRecords", {}).get("subdomains", {}))
    return reserved


def _check_dhcp(
    dhcp: dict | None,
    sname: str,
    v4_net: ipaddress.IPv4Network | None,
    errors: list[str],
) -> tuple[ipaddress.IPv4Address, ipaddress.IPv4Address] | None:
    if not dhcp:
        return None
    start_str, end_str = dhcp["start"], dhcp["end"]
    try:
        start_ip = ipaddress.IPv4Address(start_str)
        end_ip = ipaddress.IPv4Address(end_str)
    except ValueError as e:
        errors.append(
            f"Subnet '{sname}': invalid DHCP range '{start_str}'..'{end_str}' ({e})"
        )
        return None

    bounds_ok = v4_net is not None and all(
        [
            _check_ip_in_network(ip, v4_net, f"Subnet '{sname}': DHCP {bound}", errors)
            for bound, ip in (("start", start_ip), ("end", end_ip))
        ]
    )
    if start_ip > end_ip:
        errors.append(
            f"Subnet '{sname}': DHCP start ({start_ip}) must be <= end ({end_ip})"
        )
        return None
    return (start_ip, end_ip) if bounds_ok else None


def _check_mac(
    mac: str, seen_macs: dict[str, str], label: str, errors: list[str]
) -> None:
    if not MAC_RE.match(mac):
        errors.append(f"{label}: invalid MAC address '{mac}'")
        return
    norm = mac.replace("-", ":").lower()
    if norm in ("00:00:00:00:00:00", "ff:ff:ff:ff:ff:ff") or (int(norm[:2], 16) & 1):
        errors.append(
            f"{label}: invalid MAC address '{mac}' (must be a unicast hardware address)"
        )
        return
    if norm in seen_macs:
        errors.append(
            f"{label}: duplicate MAC address '{mac}' (already used by '{seen_macs[norm]}')"
        )
    else:
        seen_macs[norm] = label


def _check_endpoint_ip(
    ip_str: str,
    version: int,
    net: ipaddress.IPv4Network | ipaddress.IPv6Network | None,
    has_cidr: bool,
    seen_ips: dict,
    dhcp_range: tuple[ipaddress.IPv4Address, ipaddress.IPv4Address] | None,
    sname: str,
    entity_name: str,
    errors: list[str],
) -> None:
    try:
        ip = ipaddress.ip_address(ip_str)
    except ValueError as e:
        errors.append(
            f"Subnet '{sname}', {entity_name}: invalid IPv{version} '{ip_str}' ({e})"
        )
        return

    if ip.version != version:
        errors.append(
            f"Subnet '{sname}', {entity_name}: expected IPv{version} address, got '{ip_str}'"
        )
        return

    if not has_cidr:
        errors.append(
            f"Subnet '{sname}', {entity_name}: IPv{version} '{ip_str}' is defined but subnet has no 'cidr{6 if version == 6 else ''}'"
        )
        return

    if net is None or not _check_ip_in_network(
        ip, net, f"Subnet '{sname}', {entity_name}: IPv{version}", errors
    ):
        return

    if ip in seen_ips:
        errors.append(
            f"Subnet '{sname}': duplicate IPv{version} {ip} assigned to {entity_name} and {seen_ips[ip]}"
        )
    else:
        seen_ips[ip] = entity_name

    if (
        isinstance(ip, ipaddress.IPv4Address)
        and dhcp_range
        and dhcp_range[0] <= ip <= dhcp_range[1]
    ):
        errors.append(
            f"Subnet '{sname}', {entity_name}: IP {ip} collides with DHCP range ({dhcp_range[0]} - {dhcp_range[1]})"
        )


def _check_dns_label(
    name: str, kind: str, sname: str, domain: str, label: str, errors: list[str]
) -> None:
    if not DNS_LABEL_RE.match(name):
        errors.append(
            f"{label}: invalid {kind} name '{name}' (must be RFC 1123 DNS label: alphanumeric and hyphen, 1-63 chars, no leading/trailing hyphen)"
        )
    elif domain and len(f"{name}.{sname}.{domain}") > MAX_DNS_NAME_LEN:
        errors.append(
            f"{label}: FQDN '{name}.{sname}.{domain}' exceeds {MAX_DNS_NAME_LEN} characters"
        )


def validate_network(data: dict) -> list[str]:
    """Validates evaluated network configuration JSON and returns a list of error strings."""
    errors: list[str] = []

    domain, dhcp_domain = data["domain"], data["dhcpDomain"]
    if not _is_valid_domain(domain):
        errors.append(f"Network: invalid 'domain' {domain!r}")
    if not _is_valid_domain(dhcp_domain):
        errors.append(f"Network: invalid 'dhcpDomain' {dhcp_domain!r}")
    if domain.lower() == dhcp_domain.lower():
        errors.append(
            f"Network: 'dhcpDomain' ({dhcp_domain!r}) cannot be the same as 'domain' ({domain!r})"
        )
    ns = data["ns"]
    if not ns.endswith(".") or not _is_valid_domain(ns, allow_trailing_dot=True):
        errors.append(f"Network: invalid 'ns' {ns!r} (must be an FQDN ending with '.')")
    if not _is_valid_email(data["adminEmail"]):
        errors.append(f"Network: invalid 'adminEmail' {data['adminEmail']!r}")

    _check_dns_ips(data.get("dns", {}), "Global DNS", errors)
    reserved_names = _collect_reserved_names(data, errors)

    seen_ids: dict[int, str] = {}
    seen_snames: dict[str, str] = {}
    seen_rev_v4: dict[str, str] = {}
    seen_rev_v6: dict[str, str] = {}
    seen_aliases: dict[str, str] = {}
    v4_nets: dict[str, ipaddress.IPv4Network] = {}
    v6_nets: dict[str, ipaddress.IPv6Network] = {}

    for sname, subnet in data.get("subnets", {}).items():
        if not DNS_LABEL_RE.match(sname):
            errors.append(
                f"Subnet '{sname}': invalid subnet name (must be RFC 1123 DNS label: alphanumeric and hyphen, 1-63 chars, no leading/trailing hyphen)"
            )
        norm_sname = sname.lower()
        if norm_sname == "dns":
            errors.append(
                f"Subnet '{sname}': subnet name collides with reserved DNS name 'dns'"
            )
        if norm_sname in seen_snames:
            errors.append(
                f"Subnet '{sname}': duplicate subnet name (case-insensitive collision with '{seen_snames[norm_sname]}')"
            )
        else:
            seen_snames[norm_sname] = sname

        sid = subnet["id"]
        if sid in seen_ids:
            errors.append(
                f"Subnet '{sname}': duplicate ID {sid} (already used by '{seen_ids[sid]}')"
            )
        else:
            seen_ids[sid] = sname

        _check_dns_ips(subnet.get("dns", {}), f"Subnet '{sname}', DNS", errors)

        v4_net = None
        try:
            v4_net = ipaddress.IPv4Network(subnet["cidr"], strict=True)
            v4_nets[sname] = v4_net
            if not (24 <= v4_net.prefixlen <= 30):
                errors.append(
                    f"Subnet '{sname}': IPv4 prefix length /{v4_net.prefixlen} is outside supported range /24../30"
                )
        except ValueError as e:
            errors.append(
                f"Subnet '{sname}': invalid IPv4 CIDR '{subnet['cidr']}' ({e})"
            )

        v6_net = None
        cidr6 = subnet.get("cidr6")
        if cidr6 is not None:
            try:
                v6_net = ipaddress.IPv6Network(cidr6, strict=True)
                v6_nets[sname] = v6_net
                if not (4 <= v6_net.prefixlen <= 124 and v6_net.prefixlen % 4 == 0):
                    errors.append(
                        f"Subnet '{sname}': IPv6 prefix length /{v6_net.prefixlen} must be a multiple of 4 within /4../124 for reverse DNS delegation"
                    )
            except ValueError as e:
                errors.append(f"Subnet '{sname}': invalid IPv6 CIDR '{cidr6}' ({e})")

        for field, seen_rev in (
            ("reverseZone", seen_rev_v4),
            ("reverseZone6", seen_rev_v6),
        ):
            if rev := subnet.get(field):
                norm_rev = rev.rstrip(".").lower()
                if norm_rev in seen_rev:
                    errors.append(
                        f"Subnet '{sname}': duplicate {field} '{rev}' (already used by subnet '{seen_rev[norm_rev]}'). "
                        "Multiple subnets sharing the same reverse zone is not supported by BIND."
                    )
                else:
                    seen_rev[norm_rev] = sname

        dhcp_range = _check_dhcp(subnet.get("dhcp"), sname, v4_net, errors)
        gw = subnet["gateway"]
        gw_name = gw.get("name", "gateway")
        _check_dns_label(
            gw_name, "gateway", sname, domain, f"Subnet '{sname}', Gateway", errors
        )

        hosts = subnet.get("hosts", {})
        seen_hosts: dict[str, str] = {}
        for hname in hosts:
            host_label = f"Subnet '{sname}', Host '{hname}'"
            _check_dns_label(hname, "host", sname, domain, host_label, errors)
            norm_hname = hname.lower()
            if norm_hname == gw_name.lower():
                errors.append(
                    f"{host_label}: host name cannot be the same as gateway name '{gw_name}'"
                )
            elif norm_hname in seen_hosts:
                errors.append(
                    f"{host_label}: duplicate host name (case-insensitive collision with '{seen_hosts[norm_hname]}')"
                )
            else:
                seen_hosts[norm_hname] = hname

        seen_v4: dict = {}
        seen_v6: dict = {}
        seen_macs: dict[str, str] = {}
        endpoints = [
            ("gateway", f"Subnet '{sname}', Gateway", gw),
            *(
                (f"Host '{hname}'", f"Subnet '{sname}', Host '{hname}'", host)
                for hname, host in hosts.items()
            ),
        ]
        for entity_name, label, ep in endpoints:
            _check_endpoint_ip(
                ep["ipv4"],
                4,
                v4_net,
                True,
                seen_v4,
                dhcp_range,
                sname,
                entity_name,
                errors,
            )
            if (ipv6 := ep.get("ipv6")) is not None:
                _check_endpoint_ip(
                    ipv6,
                    6,
                    v6_net,
                    cidr6 is not None,
                    seen_v6,
                    None,
                    sname,
                    entity_name,
                    errors,
                )
            if (mac := ep.get("mac")) is not None:
                _check_mac(mac, seen_macs, label, errors)
            for alias in ep.get("aliases", []):
                norm_alias = alias.lower()
                if not ALIAS_RE.match(alias):
                    errors.append(f"{label}: invalid alias '{alias}'")
                elif domain and len(f"{alias}.{domain}") > MAX_DNS_NAME_LEN:
                    errors.append(
                        f"{label}: alias FQDN '{alias}.{domain}' exceeds {MAX_DNS_NAME_LEN} characters"
                    )
                elif norm_alias in reserved_names:
                    errors.append(
                        f"{label}: alias '{alias}' collides with reserved DNS name or host '{alias}'"
                    )
                elif norm_alias in seen_aliases:
                    errors.append(
                        f"{label}: duplicate alias '{alias}' (already used by '{seen_aliases[norm_alias]}')"
                    )
                else:
                    seen_aliases[norm_alias] = label

    suffix = f".{domain.lower()}"
    if dhcp_domain.lower().endswith(suffix):
        rel_dhcp = dhcp_domain[: -len(suffix)].lower()
        if rel_dhcp in reserved_names:
            errors.append(
                f"Network: 'dhcpDomain' ({dhcp_domain!r}) collides with reserved DNS name or host '{rel_dhcp}'"
            )
        elif rel_dhcp in seen_aliases:
            errors.append(
                f"Network: 'dhcpDomain' ({dhcp_domain!r}) collides with alias '{rel_dhcp}' (used by '{seen_aliases[rel_dhcp]}')"
            )

    for label, nets in (("IPv4", v4_nets), ("IPv6", v6_nets)):
        for (s1, n1), (s2, n2) in combinations(sorted(nets.items()), 2):
            if n1.overlaps(n2):
                errors.append(
                    f"Subnet collision ({label}): '{s1}' ({n1}) overlaps with '{s2}' ({n2})"
                )

    return errors


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate evaluated frablab network configuration JSON."
    )
    parser.add_argument(
        "network_json", type=Path, help="Path to evaluated network.json"
    )
    args = parser.parse_args()

    if not args.network_json.is_file():
        print(f"Error: file not found: {args.network_json}", file=sys.stderr)
        sys.exit(1)

    try:
        data = json.loads(args.network_json.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as e:
        print(f"Error reading JSON from {args.network_json}: {e}", file=sys.stderr)
        sys.exit(1)

    if errors := validate_network(data):
        print(
            f"Network configuration validation FAILED ({len(errors)} error(s)):",
            file=sys.stderr,
        )
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        sys.exit(1)

    print("Network configuration is valid.")


if __name__ == "__main__":
    main()

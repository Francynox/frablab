#!/usr/bin/env python3
"""
Unit tests for check_network.py negative and boundary validation.
"""

import unittest
from check_network import validate_network


class TestCheckNetwork(unittest.TestCase):
    def get_base_valid_network(self):
        return {
            "domain": "home.arpa",
            "dhcpDomain": "dhcp.home.arpa",
            "ns": "ns.home.arpa.",
            "adminEmail": "admin@home.arpa",
            "dns": {"ipv4": ["10.0.80.250"], "ipv6": [], "servers": ["10.0.80.250"]},
            "subnets": {
                "main": {
                    "id": 1,
                    "cidr": "10.0.10.0/24",
                    "reverseZone": "10.0.10.in-addr.arpa",
                    "gateway": {
                        "ipv4": "10.0.10.254",
                        "name": "gateway",
                        "aliases": [],
                    },
                    "dhcp": {
                        "start": "10.0.10.100",
                        "end": "10.0.10.200",
                    },
                    "hosts": {
                        "server": {
                            "ipv4": "10.0.10.10",
                            "mac": "00:11:22:33:44:55",
                            "aliases": ["srv"],
                        }
                    },
                }
            },
        }

    def test_valid_network(self):
        net = self.get_base_valid_network()
        errors = validate_network(net)
        self.assertEqual(errors, [])

    def test_strict_cidr_host_bits(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["cidr"] = "10.0.10.5/24"
        errors = validate_network(net)
        self.assertTrue(any("invalid IPv4 CIDR" in e for e in errors))

    def test_overlapping_cidrs(self):
        net = self.get_base_valid_network()
        net["subnets"]["sub2"] = {
            "id": 2,
            "cidr": "10.0.10.128/25",
            "reverseZone": "10.0.10.in-addr.arpa",
            "gateway": {"ipv4": "10.0.10.253", "name": "gw2"},
            "hosts": {},
        }
        errors = validate_network(net)
        self.assertTrue(any("Subnet collision" in e for e in errors))

    def test_duplicate_subnet_id(self):
        net = self.get_base_valid_network()
        net["subnets"]["sub2"] = {
            "id": 1,
            "cidr": "10.0.20.0/24",
            "reverseZone": "20.0.10.in-addr.arpa",
            "gateway": {"ipv4": "10.0.20.254", "name": "gw2"},
            "hosts": {},
        }
        errors = validate_network(net)
        self.assertTrue(any("duplicate ID 1" in e for e in errors))

    def test_gateway_outside_subnet(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["gateway"]["ipv4"] = "192.168.1.1"
        errors = validate_network(net)
        self.assertTrue(any("outside subnet" in e for e in errors))

    def test_host_outside_subnet(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server"]["ipv4"] = "10.0.20.10"
        errors = validate_network(net)
        self.assertTrue(any("outside subnet" in e for e in errors))

    def test_gateway_dhcp_collision(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["gateway"]["ipv4"] = "10.0.10.150"
        errors = validate_network(net)
        self.assertTrue(any("collides with DHCP range" in e for e in errors))

    def test_host_dhcp_collision(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server"]["ipv4"] = "10.0.10.150"
        errors = validate_network(net)
        self.assertTrue(any("collides with DHCP range" in e for e in errors))

    def test_duplicate_host_ips(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server2"] = {
            "ipv4": "10.0.10.10",
        }
        errors = validate_network(net)
        self.assertTrue(any("duplicate IPv4 10.0.10.10" in e for e in errors))

    def test_duplicate_ip_with_gateway(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server"]["ipv4"] = "10.0.10.254"
        errors = validate_network(net)
        self.assertTrue(any("duplicate IPv4 10.0.10.254" in e for e in errors))

    def test_bad_dhcp_range_start_after_end(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["dhcp"]["start"] = "10.0.10.200"
        net["subnets"]["main"]["dhcp"]["end"] = "10.0.10.100"
        errors = validate_network(net)
        self.assertTrue(any("must be <= end" in e for e in errors))

    def test_bad_dhcp_range_outside_subnet(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["dhcp"]["start"] = "10.0.20.100"
        errors = validate_network(net)
        self.assertTrue(any("outside subnet" in e for e in errors))

    def test_invalid_mac_format(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server"]["mac"] = "invalid-mac"
        errors = validate_network(net)
        self.assertTrue(any("invalid MAC address" in e for e in errors))

    def test_duplicate_mac(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server2"] = {
            "ipv4": "10.0.10.20",
            "mac": "00-11-22-33-44-55",  # Same MAC different format
        }
        errors = validate_network(net)
        self.assertTrue(any("duplicate MAC address" in e for e in errors))

    def test_alias_collision_with_subnet_name(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server"]["aliases"] = ["main"]
        errors = validate_network(net)
        self.assertTrue(any("collides with reserved DNS name" in e for e in errors))

    def test_alias_collision_with_dns(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server"]["aliases"] = ["dns"]
        errors = validate_network(net)
        self.assertTrue(any("collides with reserved DNS name" in e for e in errors))

    def test_alias_collision_with_host_fqdn(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server2"] = {
            "ipv4": "10.0.10.20",
            "aliases": ["server.main"],
        }
        errors = validate_network(net)
        self.assertTrue(any("collides with reserved DNS name" in e for e in errors))

    def test_alias_same_as_host_allowed(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server"]["aliases"] = ["server"]
        errors = validate_network(net)
        self.assertEqual(errors, [])

    def test_duplicate_reverse_zone(self):
        net = self.get_base_valid_network()
        net["subnets"]["sub2"] = {
            "id": 2,
            "cidr": "10.0.100.0/29",
            "reverseZone": "100.0.10.in-addr.arpa",
            "gateway": {"ipv4": "10.0.100.1", "name": "gw1"},
            "hosts": {},
        }
        net["subnets"]["sub3"] = {
            "id": 3,
            "cidr": "10.0.100.8/29",
            "reverseZone": "100.0.10.in-addr.arpa",
            "gateway": {"ipv4": "10.0.100.9", "name": "gw2"},
            "hosts": {},
        }
        errors = validate_network(net)
        self.assertTrue(any("duplicate reverseZone" in e for e in errors))

    def test_duplicate_alias(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server2"] = {
            "ipv4": "10.0.10.20",
            "aliases": ["srv"],
        }
        errors = validate_network(net)
        self.assertTrue(any("duplicate alias 'srv'" in e for e in errors))

    def test_host_named_same_as_gateway(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["gateway"] = {
            "ipv4": "10.0.10.15",
        }
        errors = validate_network(net)
        self.assertTrue(
            any("host name cannot be the same as gateway name" in e for e in errors)
        )

    def test_ipv4_prefixlen_too_large(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["cidr"] = "10.0.10.0/23"
        errors = validate_network(net)
        self.assertTrue(any("outside supported range /24../30" in e for e in errors))

    def test_ipv4_prefixlen_too_small(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["cidr"] = "10.0.10.0/31"
        errors = validate_network(net)
        self.assertTrue(any("outside supported range /24../30" in e for e in errors))

    def test_alias_collision_with_extra_records(self):
        net = self.get_base_valid_network()
        net["extraRecords"] = {
            "subdomains": {
                "grafana": {"a": ["10.0.10.50"]},
            }
        }
        net["subnets"]["main"]["hosts"]["server"]["aliases"] = ["grafana"]
        errors = validate_network(net)
        self.assertTrue(any("collides with reserved DNS name" in e for e in errors))

    def test_extra_records_collision_with_subnet_or_dns(self):
        net = self.get_base_valid_network()
        net["extraRecords"] = {
            "subdomains": {
                "main": {"a": ["10.0.10.50"]},
            }
        }
        errors = validate_network(net)
        self.assertTrue(any("collides with reserved DNS name" in e for e in errors))

    def test_same_mac_across_different_subnets_allowed(self):
        net = self.get_base_valid_network()
        net["subnets"]["sub2"] = {
            "id": 2,
            "cidr": "10.0.20.0/24",
            "reverseZone": "20.0.10.in-addr.arpa",
            "gateway": {"ipv4": "10.0.20.254", "name": "gw2"},
            "hosts": {
                "laptop": {
                    "ipv4": "10.0.20.50",
                    "mac": "00:11:22:33:44:55",  # Same MAC as main.server
                }
            },
        }
        errors = validate_network(net)
        self.assertEqual(errors, [])

    def test_invalid_dns_label_subnet_name(self):
        net = self.get_base_valid_network()
        net["subnets"]["main_net"] = net["subnets"].pop("main")
        errors = validate_network(net)
        self.assertTrue(any("invalid subnet name" in e for e in errors))

    def test_invalid_dns_label_gateway_name(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["gateway"]["name"] = "-gateway"
        errors = validate_network(net)
        self.assertTrue(any("invalid gateway name" in e for e in errors))

    def test_invalid_dns_label_host_name(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server_1"] = net["subnets"]["main"][
            "hosts"
        ].pop("server")
        errors = validate_network(net)
        self.assertTrue(any("invalid host name" in e for e in errors))

    def test_extra_records_collision_with_host_fqdn(self):
        net = self.get_base_valid_network()
        net["extraRecords"] = {
            "subdomains": {
                "server.main": {"a": ["10.0.10.50"]},
            }
        }
        errors = validate_network(net)
        self.assertTrue(
            any(
                "collides with reserved DNS name or host 'server.main'" in e
                for e in errors
            )
        )

    def test_alias_regex_rejects_underscores(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server"]["aliases"] = ["my_srv"]
        errors = validate_network(net)
        self.assertTrue(any("invalid alias 'my_srv'" in e for e in errors))

    def test_alias_regex_rejects_leading_trailing_hyphens(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server"]["aliases"] = ["-srv"]
        errors = validate_network(net)
        self.assertTrue(any("invalid alias '-srv'" in e for e in errors))

    def test_case_insensitive_duplicate_subnet_name(self):
        net = self.get_base_valid_network()
        net["subnets"]["Main"] = {
            "id": 2,
            "cidr": "10.0.20.0/24",
            "reverseZone": "20.0.10.in-addr.arpa",
            "gateway": {"ipv4": "10.0.20.254", "name": "gw2"},
            "hosts": {},
        }
        errors = validate_network(net)
        self.assertTrue(
            any(
                "duplicate subnet name (case-insensitive collision with 'main')" in e
                for e in errors
            )
        )

    def test_case_insensitive_duplicate_host_name(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["Server"] = {
            "ipv4": "10.0.10.20",
        }
        errors = validate_network(net)
        self.assertTrue(
            any(
                "duplicate host name (case-insensitive collision with 'server')" in e
                for e in errors
            )
        )

    def test_case_insensitive_host_vs_gateway_name(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["Gateway"] = {
            "ipv4": "10.0.10.20",
        }
        errors = validate_network(net)
        self.assertTrue(
            any("host name cannot be the same as gateway name" in e for e in errors)
        )

    def test_case_insensitive_alias_collision(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server2"] = {
            "ipv4": "10.0.10.20",
            "aliases": ["SRV"],
        }
        errors = validate_network(net)
        self.assertTrue(any("duplicate alias 'SRV'" in e for e in errors))

    def test_case_insensitive_reserved_name_collision(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server"]["aliases"] = ["DNS"]
        errors = validate_network(net)
        self.assertTrue(
            any("collides with reserved DNS name or host 'DNS'" in e for e in errors)
        )

    def test_valid_ipv6_subnet_and_reverse_zone(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["cidr6"] = "fd00:42:1::/64"
        net["subnets"]["main"]["reverseZone6"] = (
            "0.0.0.0.1.0.0.0.2.4.0.0.0.0.d.f.ip6.arpa"
        )
        net["subnets"]["main"]["gateway"]["ipv6"] = "fd00:42:1::254"
        net["subnets"]["main"]["hosts"]["server"]["ipv6"] = "fd00:42:1::10"
        errors = validate_network(net)
        self.assertEqual(errors, [])

    def test_ipv6_prefixlen_not_multiple_of_4(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["cidr6"] = "fd00:42:1::/62"
        errors = validate_network(net)
        self.assertTrue(
            any("must be a multiple of 4 within /4../124" in e for e in errors)
        )

    def test_ipv6_prefixlen_zero_rejected(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["cidr6"] = "::/0"
        errors = validate_network(net)
        self.assertTrue(
            any("must be a multiple of 4 within /4../124" in e for e in errors)
        )

    def test_ipv6_prefixlen_128_rejected(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["cidr6"] = "fd00:42:1::/128"
        errors = validate_network(net)
        self.assertTrue(
            any("must be a multiple of 4 within /4../124" in e for e in errors)
        )

    def test_duplicate_reverse_zone6(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["cidr6"] = "fd00:42:1::/64"
        net["subnets"]["main"]["reverseZone6"] = (
            "0.0.0.0.1.0.0.0.2.4.0.0.0.0.d.f.ip6.arpa"
        )
        net["subnets"]["sub2"] = {
            "id": 2,
            "cidr": "10.0.20.0/24",
            "reverseZone": "20.0.10.in-addr.arpa",
            "cidr6": "fd00:42:1::/64",
            "reverseZone6": "0.0.0.0.1.0.0.0.2.4.0.0.0.0.d.f.ip6.arpa",
            "gateway": {"ipv4": "10.0.20.254", "name": "gw2"},
            "hosts": {},
        }
        errors = validate_network(net)
        self.assertTrue(any("duplicate reverseZone6" in e for e in errors))

    def test_overlapping_ipv6_cidrs(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["cidr6"] = "fd00:42::/56"
        net["subnets"]["main"]["reverseZone6"] = "0.0.2.4.0.0.0.0.d.f.ip6.arpa"
        net["subnets"]["sub2"] = {
            "id": 2,
            "cidr": "10.0.20.0/24",
            "reverseZone": "20.0.10.in-addr.arpa",
            "cidr6": "fd00:42:0:1::/64",
            "reverseZone6": "1.0.0.0.0.0.0.0.2.4.0.0.0.0.d.f.ip6.arpa",
            "gateway": {"ipv4": "10.0.20.254", "name": "gw2"},
            "hosts": {},
        }
        errors = validate_network(net)
        self.assertTrue(any("Subnet collision (IPv6)" in e for e in errors))

    def test_subnet_named_dns_rejected(self):
        net = self.get_base_valid_network()
        net["subnets"]["DNS"] = {
            "id": 2,
            "cidr": "10.0.20.0/24",
            "reverseZone": "20.0.10.in-addr.arpa",
            "gateway": {"ipv4": "10.0.20.254", "name": "gw2"},
            "hosts": {},
        }
        errors = validate_network(net)
        self.assertTrue(
            any("collides with reserved DNS name 'dns'" in e for e in errors)
        )

    def test_alias_collision_with_nested_extra_records(self):
        net = self.get_base_valid_network()
        net["extraRecords"] = {
            "subdomains": {
                "foo": {
                    "subdomains": {
                        "bar": {"A": ["10.0.10.50"]},
                    }
                }
            }
        }
        net["subnets"]["main"]["hosts"]["server"]["aliases"] = ["bar.foo"]
        errors = validate_network(net)
        self.assertTrue(any("collides with reserved DNS name" in e for e in errors))

    def test_empty_mac_rejected(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server"]["mac"] = ""
        errors = validate_network(net)
        self.assertTrue(any("invalid MAC address" in e for e in errors))

    def test_empty_ipv6_rejected(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["cidr6"] = "fd00:42:1::/64"
        net["subnets"]["main"]["reverseZone6"] = (
            "0.0.0.0.1.0.0.0.2.4.0.0.0.0.d.f.ip6.arpa"
        )
        net["subnets"]["main"]["hosts"]["server"]["ipv6"] = ""
        errors = validate_network(net)
        self.assertTrue(any("invalid IPv6" in e for e in errors))

    def test_gateway_invalid_mac_and_duplicate_mac_with_host(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["gateway"]["mac"] = "bad-mac"
        errors = validate_network(net)
        self.assertTrue(any("Gateway: invalid MAC address" in e for e in errors))

        net = self.get_base_valid_network()
        net["subnets"]["main"]["gateway"]["mac"] = "00:11:22:33:44:55"
        errors = validate_network(net)
        self.assertTrue(any("duplicate MAC address" in e for e in errors))

    def test_mac_mixed_separators_broadcast_zero_multicast_rejected(self):
        for bad_mac in [
            "00:11-22:33-44:55",
            "00:00:00:00:00:00",
            "ff:ff:ff:ff:ff:ff",
            "01:00:5e:00:00:01",
            "00:11:22:33:44:55\n",
        ]:
            net = self.get_base_valid_network()
            net["subnets"]["main"]["hosts"]["server"]["mac"] = bad_mac
            errors = validate_network(net)
            self.assertTrue(
                any("invalid MAC address" in e for e in errors),
                f"Expected invalid MAC error for {bad_mac!r}, got {errors}",
            )

    def test_trailing_newline_rejected_in_labels_and_aliases(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["hosts"]["server"]["aliases"] = ["srv\n"]
        errors = validate_network(net)
        self.assertTrue(any("invalid alias" in e for e in errors))

        net = self.get_base_valid_network()
        net["subnets"]["main\n"] = net["subnets"].pop("main")
        errors = validate_network(net)
        self.assertTrue(any("invalid subnet name" in e for e in errors))

    def test_top_level_domain_dhcp_domain_ns_admin_email(self):
        net = self.get_base_valid_network()
        net["dhcpDomain"] = "home.arpa"
        errors = validate_network(net)
        self.assertTrue(any("cannot be the same as 'domain'" in e for e in errors))

        net = self.get_base_valid_network()
        net["dhcpDomain"] = "main.home.arpa"
        errors = validate_network(net)
        self.assertTrue(any("collides with reserved DNS name" in e for e in errors))

        net = self.get_base_valid_network()
        net["ns"] = "bad host!"
        errors = validate_network(net)
        self.assertTrue(any("invalid 'ns'" in e for e in errors))

        net = self.get_base_valid_network()
        net["ns"] = "ns.home.arpa"
        errors = validate_network(net)
        self.assertTrue(any("invalid 'ns'" in e for e in errors))

        net = self.get_base_valid_network()
        net["adminEmail"] = "not-an-email"
        errors = validate_network(net)
        self.assertTrue(any("invalid 'adminEmail'" in e for e in errors))

    def test_dhcp_outside_subnet_no_cascading_host_collisions(self):
        net = self.get_base_valid_network()
        net["subnets"]["main"]["dhcp"]["start"] = "10.0.9.1"
        net["subnets"]["main"]["dhcp"]["end"] = "10.0.11.254"
        errors = validate_network(net)
        self.assertTrue(
            any("DHCP start" in e and "outside subnet" in e for e in errors)
        )
        self.assertTrue(any("DHCP end" in e and "outside subnet" in e for e in errors))
        self.assertFalse(any("collides with DHCP range" in e for e in errors))

    def test_fqdn_length_limit_enforced(self):
        net = self.get_base_valid_network()
        long_alias = ".".join(["a" * 60] * 4) + ".x"
        net["subnets"]["main"]["hosts"]["server"]["aliases"] = [long_alias]
        errors = validate_network(net)
        self.assertTrue(any("exceeds 253 characters" in e for e in errors))

    def test_extra_records_wildcard_and_underscore_allowed_whitespace_rejected(self):
        net = self.get_base_valid_network()
        net["extraRecords"] = {
            "subdomains": {
                "*": {"A": ["10.0.10.50"]},
                "_acme-challenge": {"TXT": ["token"]},
            }
        }
        self.assertEqual(validate_network(net), [])

        net["extraRecords"] = {"subdomains": {"bad name": {"A": ["10.0.10.50"]}}}
        errors = validate_network(net)
        self.assertTrue(any("invalid subdomain key" in e for e in errors))


if __name__ == "__main__":
    unittest.main()

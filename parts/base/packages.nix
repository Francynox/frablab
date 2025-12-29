{
  flake.nixosModules.base-packages =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      cfg = config.frablab.base;
    in
    {
      options.frablab.base.packages.enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.enable;
        description = "Enable default system packages";
      };

      config = lib.mkIf cfg.packages.enable {
        environment.systemPackages = with pkgs; [
          # core tools
          git
          vim

          # archives
          zip
          xz
          zstd
          unzipNLS
          p7zip

          # networking tools
          mtr # A network diagnostic tool
          iperf3
          dnsutils # `dig` + `nslookup`
          ldns # replacement of `dig`, it provide the command `drill`
          wget
          curl
          aria2 # A lightweight multi-protocol & multi-source command-line download utility
          socat # replacement of openbsd-netcat
          nmap # A utility for network discovery and security auditing
          ipcalc # it is a calculator for the IPv4/v6 addresses
          iptraf-ng # A network traffic monitor

          # Text Processing
          # Docs: https://github.com/learnbyexample/Command-line-text-processing
          gnugrep # GNU grep, provides `grep`/`egrep`/`fgrep`
          gnused # GNU sed, very powerful(mainly for replacing text in files)
          gawk # GNU awk, a pattern scanning and processing language
          jq # A lightweight and flexible command-line JSON processor

          # misc
          file
          findutils
          which
          tree
          gnutar
          rsync
          gum
          procps
          just
          btop
          iotop
        ];
      };
    };
}

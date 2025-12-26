{ pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    inputs.vscode-server.nixosModules.default
  ];

  environment.systemPackages = with pkgs; [
    act
    ssh-to-age
    sops
  ];

  programs.bash.interactiveShellInit = ''
    auth-sops() {
      if [ -f /etc/ssh/ssh_host_ed25519_key ]; then
        export SOPS_AGE_KEY=$(sudo ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key)
      else
        echo "Error: Host key not found."
      fi
    }
  '';

  programs = {
    git = {
      enable = true;
    };
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        openssl
        curl
        glib
        util-linux
        icu
        libunwind
        libuuid
      ];
    };
  };

  services.vscode-server.enable = true;

  virtualisation.docker = {
    enable = true;
  };

  networking.hostName = "nixos-dev";
}

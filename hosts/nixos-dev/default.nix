{ inputs, ... }:
{

  networking.hostName = "nixos-dev";

  imports = [
    inputs.vscode-server.nixosModules.default
    ./development.nix
  ];

  frablab.base = {
    persistence = {
      additionalDirectories = [
        "/var/lib/docker"
      ];
    };

    users = {
      enable = true;
      admin = {
        extraGroups = [ "docker" ];
        exportDeploySshKey = true;
        passwordlessSudo = true;
        persistenceDirectories = [
          "Projects"
          ".vscode-server"
          ".antigravity-server"
          ".antigravity-ide-server"
          ".gemini"
          ".npm-global"
        ];
        persistenceFiles = [
          ".gitconfig"
        ];
      };
    };
  };

  services.francynox.auto-update = {
    push-server.enable = true;
    dates = "*-*-* 02:00:00";
  };

  frablab.base.networking = {
    mode = "static";
    static = {
      subnet = "mgmt";
    };
  };
}

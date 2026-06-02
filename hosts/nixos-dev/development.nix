{ pkgs, constants, ... }:
{
  environment.systemPackages = with pkgs; [
    act
    ssh-to-age
    sops
    git-filter-repo
    treefmt
    uv
    nodejs_24
    xauth
    xclock
    xeyes
  ];

  environment.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  programs.bash.interactiveShellInit = ''
    auth-sops() {
      if [ -f ${constants.sopsKeyPath} ]; then
        export SOPS_AGE_KEY=$(sudo ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i ${constants.sopsKeyPath})
      else
        echo "Error: Host key not found."
      fi
    }
    export PATH="$HOME/.npm-global/bin:$PATH"
  '';

  programs = {
    git.enable = true;
    direnv.enable = true;
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

  services = {
    vscode-server.enable = true;
    openssh = {
      settings = {
        X11Forwarding = true;
      };
    };
  };

  virtualisation.docker = {
    enable = true;
  };
}

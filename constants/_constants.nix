{
  sopsKeyPath = "/nix/secret/sops_key";
  flakeUrl = "github:Francynox/frablab";
  adminSshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJyYmElWbBrcNn+JDXUvV0VZP9ITcnVtW/h2Y26g2TP7"
  ];

  substituters = [
    "https://cache.nixos.org"
    "https://francynox.cachix.org"
  ];
  trustedPublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "francynox.cachix.org-1:p66qHTBuD6sRBIggOCoB2iSjmtqLs4a3Fvh3nImvTsg="
  ];
}

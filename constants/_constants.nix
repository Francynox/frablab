{
  sopsKeyPath = "/nix/secret/sops_key";
  remoteSecretsUrl = "https://raw.githubusercontent.com/Francynox/frablab/main/secrets/secrets.yaml";
  flakeUrl = "github:Francynox/frablab";
  adminSshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJyYmElWbBrcNn+JDXUvV0VZP9ITcnVtW/h2Y26g2TP7"
  ];
}

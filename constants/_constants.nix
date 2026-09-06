{
  sopsKeyPath = "/nix/secret/sops_key";
  remoteSecretsUrl = "https://raw.githubusercontent.com/Francynox/frablab/main/secrets/secrets.yaml";
  flakeUrl = "github:Francynox/frablab";
  adminInitialHashedPassword = "$6$hwDphFD.UY.MLmFp$2YKY68ZzLYzgRu7Opu4qGAKn9W6k4GLpv2kTHCUh2Nhl4guFsIKHQcnxQhEkkRorEjk3uPm3xy1zgEnwDRW07/";
  adminSshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJyYmElWbBrcNn+JDXUvV0VZP9ITcnVtW/h2Y26g2TP7"
  ];
}

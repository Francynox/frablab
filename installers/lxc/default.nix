{ self, ... }:
{
  # Pure configuration for LXC
  imports = [ self.nixosModules.lxc ];
}

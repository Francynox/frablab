{
  flake.nixosModules.network =
    { inputs, ... }:
    {
      imports = [
        inputs.frablab-config.lib.networkSchema
      ];

      config.frablab.network = inputs.frablab-config.lib.network;
    };
}

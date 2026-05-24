{
  flake.nixosModules.network =
    { frablabConfig, ... }:
    {
      imports = [
        frablabConfig.networkSchema
      ];

      config.frablab.network = frablabConfig.network;
    };
}

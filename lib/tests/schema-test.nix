{ lib }:
let
  eval =
    networkConfig:
    (lib.evalModules {
      modules = [
        ../network/network-schema.nix
        { frablab.network = networkConfig; }
      ];
    }).config.frablab.network;

  validNetwork = {
    ns = "mimir.service.home.arpa.";
    adminEmail = "admin@home.arpa";
    subnets.main = {
      id = 1;
      prefix = "192.168.1";
      hosts.server = "10";
    };
  };

  validResult = eval validNetwork;

  # Negative tests: tryEval + deepSeq to surface throws during submodule validation.
  badRangeEval = builtins.tryEval (
    builtins.deepSeq (eval (
      validNetwork
      // {
        subnets.main = validNetwork.subnets.main // {
          dhcpRange = {
            start = 200;
            end = 100;
          };
        };
      }
    )) true
  );

  badEndEval = builtins.tryEval (
    builtins.deepSeq (eval (
      validNetwork
      // {
        subnets.main = validNetwork.subnets.main // {
          dhcpRange = {
            start = 100;
            end = 255;
          };
        };
      }
    )) true
  );

  tests = {
    testDefaultDomain = {
      expr = validResult.domain;
      expected = "home.arpa";
    };
    testHostIp = {
      expr = validResult.hosts.main.server.ip;
      expected = "192.168.1.10";
    };
    testHostFqdn = {
      expr = validResult.hosts.main.server.fqdn;
      expected = "server.main.home.arpa";
    };
    testDefaultGateway = {
      expr = validResult.hosts.main.gateway.ip;
      expected = "192.168.1.254";
    };
    testBadDhcpRangeFails = {
      expr = badRangeEval.success;
      expected = false;
    };
    testBadDhcpEndFails = {
      expr = badEndEval.success;
      expected = false;
    };
  };
in
lib.runTests tests

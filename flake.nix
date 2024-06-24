{
  description = "A nixvim configuration";

  nixConfig = {
    extra-substituters = [ "https://nickhu.cachix.org" ];
    extra-trusted-public-keys = [ "nickhu.cachix.org-1:WWNzID27ud1BdPmaSFnkZZqNiu9k0uWgQRb5mTWxSjo=" ];
  };

  inputs = {
    nixvim.url = "github:nix-community/nixvim";
    nixpkgs.follows = "nixvim/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    tree-sitter-forester = {
      url = "github:kentookura/tree-sitter-forester";
      flake = false;
    };
    forester-nvim = {
      url = "github:NickHu/forester.nvim";
      flake = false;
    };
    lsp-progress-nvim = {
      url = "github:linrongbin16/lsp-progress.nvim";
      flake = false;
    };
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ flake-parts.flakeModules.easyOverlay ];
      systems = [ "x86_64-linux" ];
      perSystem =
        { config
        , self'
        , inputs'
        , pkgs
        , system
        , ...
        }:
        let
          nixvimLib = inputs.nixvim.lib.${system};
          nixvim' = inputs'.nixvim.legacyPackages;
          nvim = nixvim'.makeNixvimWithModule {
            inherit pkgs;
            module = import ./config;
          };
        in
        rec
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (final: prev: {
                tree-sitter-grammars = prev.tree-sitter-grammars // {
                  tree-sitter-forester = prev.tree-sitter.buildGrammar {
                    language = "forester";
                    version = "unstable-${inputs.tree-sitter-forester.lastModifiedDate}";
                    src = inputs.tree-sitter-forester;
                  };
                };
                vimPlugins = prev.vimPlugins.extend (final': prev': {
                  forester-nvim = final.vimUtils.buildVimPlugin {
                    pname = "forester.nvim";
                    version = "unstable-${inputs.forester-nvim.lastModifiedDate}";
                    src = inputs.forester-nvim;
                  };
                  lsp-progress-nvim = final.vimUtils.buildVimPlugin {
                    pname = "lsp-progress.nvim";
                    version = "unstable-${inputs.lsp-progress-nvim.lastModifiedDate}";
                    src = inputs.lsp-progress-nvim;
                  };
                });
              })
            ];
          };
          overlayAttrs = {
            inherit (_module.args.pkgs) vimPlugins tree-sitter-grammars;
          };
          checks = {
            # Run `nix flake check .` to verify that your config is not broken
            default = nixvimLib.check.mkTestDerivationFromNvim {
              inherit nvim;
              name = "A nixvim configuration";
            };
          };

          packages = {
            # Lets you run `nix run .` to start nixvim
            default = nvim;
          };
        };
    };
}

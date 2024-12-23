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
      url = "github:kentookura/forester.nvim";
      flake = false;
    };
    nvim-scissors = {
      url = "github:chrisgrieser/nvim-scissors";
      flake = false;
    };
    multicursor-nvim = {
      url = "github:jake-stewart/multicursor.nvim";
      flake = false;
    };
    treewalker-nvim = {
      url = "github:aaronik/treewalker.nvim";
      flake = false;
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ flake-parts.flakeModules.easyOverlay ];
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        let
          nixvimLib = inputs.nixvim.lib.${system};
          nixvim' = inputs'.nixvim.legacyPackages;
          nvim = nixvim'.makeNixvimWithModule {
            inherit pkgs;
            module = import ./config;
          };
        in
        rec {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (final: prev: {
                neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (old: {
                  patches = old.patches ++ [
                    # Fix byte index encoding bounds.
                    # - https://github.com/neovim/neovim/pull/30747
                    # - https://github.com/nix-community/nixvim/issues/2390
                    (final.fetchpatch {
                      name = "fix-lsp-str_byteindex_enc-bounds-checking-30747.patch";
                      url = "https://patch-diff.githubusercontent.com/raw/neovim/neovim/pull/30747.patch";
                      hash = "sha256-2oNHUQozXKrHvKxt7R07T9YRIIx8W3gt8cVHLm2gYhg=";
                    })
                  ];
                });
                tree-sitter-grammars = prev.tree-sitter-grammars // {
                  tree-sitter-forester = prev.tree-sitter.buildGrammar {
                    language = "forester";
                    version = "unstable-${inputs.tree-sitter-forester.lastModifiedDate}";
                    src = inputs.tree-sitter-forester;
                  };
                };
                vimPlugins = prev.vimPlugins.extend (
                  final': prev': {
                    forester-nvim = final.vimUtils.buildVimPlugin {
                      pname = "forester.nvim";
                      version = "unstable-${inputs.forester-nvim.lastModifiedDate}";
                      src = inputs.forester-nvim;
                    };
                    nvim-scissors = final.vimUtils.buildVimPlugin {
                      pname = "nvim-scissors";
                      version = "unstable-${inputs.nvim-scissors.lastModifiedDate}";
                      src = inputs.nvim-scissors;
                    };
                    multicursor-nvim = final.vimUtils.buildVimPlugin {
                      pname = "multicursor.nvim";
                      version = "unstable-${inputs.multicursor-nvim.lastModifiedDate}";
                      src = inputs.multicursor-nvim;
                    };
                    treewalker-nvim = final.vimUtils.buildVimPlugin {
                      pname = "treewalker.nvim";
                      version = "unstable-${inputs.treewalker-nvim.lastModifiedDate}";
                      src = inputs.treewalker-nvim;
                    };
                  }
                );
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

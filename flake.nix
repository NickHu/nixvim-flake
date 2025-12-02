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
      url = "github:jetjinser/tree-sitter-forester/regrammar";
      flake = false;
    };
    multicursor-nvim = {
      url = "github:jake-stewart/multicursor.nvim";
      flake = false;
    };
    vim-texabbrev = {
      url = "github:78g/vim-texabbrev";
      flake = false;
    };
    unicode-latex = {
      url = "github:ViktorQvarfordt/unicode-latex";
      flake = false;
    };
    treewalker-nvim = {
      url = "github:aaronik/treewalker.nvim";
      flake = false;
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      overlay = final: prev: {
        tree-sitter-grammars = prev.tree-sitter-grammars // {
          tree-sitter-forester = prev.tree-sitter.buildGrammar {
            language = "forester";
            version = "unstable-${inputs.tree-sitter-forester.lastModifiedDate}";
            src = inputs.tree-sitter-forester;
          };
        };
        vimPlugins = prev.vimPlugins.extend (
          final': prev': {
            multicursor-nvim = final.vimUtils.buildVimPlugin {
              pname = "multicursor.nvim";
              version = "unstable-${inputs.multicursor-nvim.lastModifiedDate}";
              src = inputs.multicursor-nvim;
            };
            vim-texabbrev =
              (final.vimUtils.buildVimPlugin {
                pname = "vim-texabbrev";
                version = "unstable-${inputs.vim-texabbrev.lastModifiedDate}";
                src = inputs.vim-texabbrev;
              }).overrideAttrs
                (
                  finalAttrs: previousAttrs: {
                    passthru = previousAttrs.passthru // {
                      latex-unicode = builtins.fromJSON (builtins.readFile "${inputs.unicode-latex}/latex-unicode.json");
                    };
                  }
                );
            treewalker-nvim = final.vimUtils.buildVimPlugin {
              pname = "treewalker.nvim";
              version = "unstable-${inputs.treewalker-nvim.lastModifiedDate}";
              src = inputs.treewalker-nvim;
            };
          }
        );
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake = {
        overlays.default = overlay;
      };
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        {
          inputs',
          system,
          ...
        }:
        let
          nixvimLib = inputs.nixvim.lib.${system};
          nixvim' = inputs'.nixvim.legacyPackages;
          nvim = (nixvim'.makeNixvimWithModule { module = import ./config; }).extend {
            nixpkgs.overlays = [ overlay ];
          };
        in
        {
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

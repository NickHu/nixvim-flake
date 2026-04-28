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
    vim-texabbrev = {
      url = "github:78g/vim-texabbrev";
      flake = false;
    };
    unicode-latex = {
      url = "github:ViktorQvarfordt/unicode-latex";
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
            org-roam-nvim = prev'.org-roam-nvim.overrideAttrs (
              finalAttrs: previousAttrs: {
                patches = (previousAttrs.patches or [ ]) ++ [
                  (builtins.fetchurl {
                    url = "https://github.com/chipsenkbeil/org-roam.nvim/commit/0be640feb6d78a1539cda7456d76f343f8cea5ea.patch";
                    sha256 = "sha256:0i1whi08cfymna11afwhs3wcl5k8q96d6s7hhi1ma8lz000l7bm6";
                  })
                ];
              }
            );
            vim-texabbrev =
              (final.vimUtils.buildVimPlugin {
                pname = "vim-texabbrev";
                version = "unstable-${inputs.vim-texabbrev.lastModifiedDate}";
                src = inputs.vim-texabbrev;
              }).overrideAttrs
                (
                  finalAttrs: previousAttrs: {
                    passthru = previousAttrs.passthru // {
                      latex-unicode =
                        builtins.fromJSON (builtins.readFile "${inputs.unicode-latex}/latex-unicode.json")
                        // {
                          # S
                          "\\circ" = "∘";
                          "\\emptyset" = "∅";
                          # eth
                          "\\gets" = "←";
                          "\\land" = "∧";
                          "\\lor" = "∨";
                          "\\neq" = "≠";
                          "\\ngeqq" = "≱";
                          "\\nleqq" = "≰";
                          "\\owns" = "∋";
                          "\\triangle" = "∆";
                        };
                    };
                  }
                );
            snacks-nvim = prev'.snacks-nvim.overrideAttrs (
              finalAttrs: previousAttrs: {
                patches = (previousAttrs.patches or [ ]) ++ [
                  (builtins.toFile "0001-image-use-lualatex-instead-of-pdflatex.patch" ''
                    From c652007a29f3363ad75e07bc502972ef1fbff8b1 Mon Sep 17 00:00:00 2001
                    From: Nick Hu <me@nickhu.co.uk>
                    Date: Thu, 5 Mar 2026 12:10:26 +0000
                    Subject: [PATCH] image: use lualatex instead of pdflatex

                    ---
                     lua/snacks/image/convert.lua | 2 +-
                     lua/snacks/image/init.lua    | 6 +++---
                     2 files changed, 4 insertions(+), 4 deletions(-)

                    diff --git a/lua/snacks/image/convert.lua b/lua/snacks/image/convert.lua
                    index e2aaa44e..281e31f6 100644
                    --- a/lua/snacks/image/convert.lua
                    +++ b/lua/snacks/image/convert.lua
                    @@ -99,7 +99,7 @@ local commands = {
                             args = { "-Z", "continue-on-errors", "--outdir", "{cache}", "{src}" },
                           },
                           {
                    -        cmd = "pdflatex",
                    +        cmd = "lualatex",
                             cwd = "{dirname}",
                             args = { "-output-directory={cache}", "-interaction=nonstopmode", "{src}" },
                           },
                    diff --git a/lua/snacks/image/init.lua b/lua/snacks/image/init.lua
                    index 038016e1..d1d114a9 100644
                    --- a/lua/snacks/image/init.lua
                    +++ b/lua/snacks/image/init.lua
                    @@ -129,7 +129,7 @@ local defaults = {
                         ---@type table<string,snacks.image.args>
                         magick = {
                           default = { "{src}[0]", "-scale", "1920x1080>" }, -- default for raster images
                    -      vector = { "-density", 192, "{src}[{page}]" }, -- used by vector images like svg
                    +      vector = { "-density", 192, "{src}[{page}]" },    -- used by vector images like svg
                           math = { "-density", 192, "{src}[{page}]", "-trim" },
                           pdf = { "-density", 192, "{src}[{page}]", "-background", "white", "-alpha", "remove", "-trim" },
                         },
                    @@ -352,14 +352,14 @@ function M.health()
                         Snacks.health.warn("`gs` is required to render PDF files")
                       end
                     
                    -  if Snacks.health.have_tool({ "tectonic", "pdflatex" }) then
                    +  if Snacks.health.have_tool({ "tectonic", "lualatex" }) then
                         if langs.latex then
                           Snacks.health.ok("LaTeX math equations are supported")
                         else
                           Snacks.health.warn("The `latex` treesitter parser is required to render LaTeX math expressions")
                         end
                       else
                    -    Snacks.health.warn("`tectonic` or `pdflatex` is required to render LaTeX math expressions")
                    +    Snacks.health.warn("`tectonic` or `lualatex` is required to render LaTeX math expressions")
                       end
                     
                       if Snacks.health.have_tool("mmdc") then
                    -- 
                    2.53.0
                  '')
                ];
              }
            );
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
          nvim =
            (nixvim'.makeNixvimWithModule {
              module = import ./config;
              extraSpecialArgs = {
                calendar = "default";
              };
            }).extend
              {
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

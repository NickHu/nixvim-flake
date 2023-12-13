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
                zk = (prev.zk.overrideAttrs (oldAttrs: {
                  patches = pkgs.lib.optionals (oldAttrs ? patches) oldAttrs.patches ++ [
                    (builtins.toFile "tree-filetype.patch" ''
                      diff --git a/internal/adapter/lsp/document.go b/internal/adapter/lsp/document.go
                      index 05233fb..30d1558 100644
                      --- a/internal/adapter/lsp/document.go
                      +++ b/internal/adapter/lsp/document.go
                      @@ -32,7 +32,7 @@ func newDocumentStore(fs core.FileStorage, logger util.Logger) *documentStore {
 
                       func (s *documentStore) DidOpen(params protocol.DidOpenTextDocumentParams, notify glsp.NotifyFunc) (*document, error) {
                       	langID := params.TextDocument.LanguageID
                      -	if langID != "markdown" && langID != "vimwiki" && langID != "pandoc" {
                      +	if langID != "markdown" && langID != "vimwiki" && langID != "pandoc" && langID != "tree" {
                       		return nil, nil
                       	}
                    '')
                  ];
                }));
              })
            ];
          };
          overlayAttrs = {
            inherit (_module.args.pkgs) zk;
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

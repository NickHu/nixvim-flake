{
  description = "A nixvim configuration";

  nixConfig = {
    extra-substituters = [ "https://nickhu.cachix.org" ];
    extra-trusted-public-keys = [ "nickhu.cachix.org-1:WWNzID27ud1BdPmaSFnkZZqNiu9k0uWgQRb5mTWxSjo=" ];
  };

  inputs = {
    nixvim.url = "github:nix-community/nixvim";
    nixpkgs.follows = "nixvim/nixpkgs";
    cornelis = {
      url = "github:agda/cornelis";
      inputs.nixpkgs.follows = "nixvim/nixpkgs";
    };
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
            cornelis = prev'.cornelis.overrideAttrs (
              finalAttrs: previousAttrs: {
                postInstall = ''
                  substituteInPlace $out/ftplugin/agda.vim \
                    --subst-var-by CORNELIS "${
                      inputs.cornelis.packages.${final.stdenv.hostPlatform.system}.cornelis.bin
                    }/bin/cornelis"
                '';
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
                  # https://github.com/folke/snacks.nvim/pull/2911
                  (final.fetchpatch {
                    name = "snacks-2911-clear-conceal-lines.patch";
                    url = "https://github.com/folke/snacks.nvim/pull/2911.diff";
                    hash = "sha256-p9sSqH2yLhj1jbLh3ZhEaDRRbspqG8JJRSL+hHU/v38=";
                  })
                  # https://github.com/folke/snacks.nvim/pull/2647
                  (final.fetchpatch {
                    name = "snacks-2647-latex-inline-hover.patch";
                    url = "https://github.com/folke/snacks.nvim/pull/2647.diff";
                    hash = "sha256-GodVRH9cugSquX2m2BOlECpMInZ/iv4fCyiRJAXD8qo=";
                  })
                  # Local follow-up to #2647 (+ #2802 line check; that PR conflicts after #2647)
                  (builtins.toFile "0002-image-should-hide-after-hover-inline.patch" ''
                    From 3c54690c54b43e281d58cac09d8a8fdab09ce70a Mon Sep 17 00:00:00 2001
                    From: Nick Hu <me@nickhu.co.uk>
                    Date: Tue, 14 Jul 2026 17:54:11 +0900
                    Subject: [PATCH] fix(image): should_hide + cursor line check after
                     hover+inline

                    ---
                     lua/snacks/image/doc.lua    |  4 +-
                     lua/snacks/image/inline.lua | 79 +++++++++++++------------------------
                     2 files changed, 29 insertions(+), 54 deletions(-)

                    diff --git a/lua/snacks/image/doc.lua b/lua/snacks/image/doc.lua
                    index 95c7fb1..3a041b2 100644
                    --- a/lua/snacks/image/doc.lua
                    +++ b/lua/snacks/image/doc.lua
                    @@ -366,7 +366,7 @@ function M.match_at_cursor(cb)
                           local range = img.range
                           if range then
                             if
                    -          (range[1] == range[3] and cursor[2] >= range[2] and cursor[2] <= range[4])
                    +          (range[1] == range[3] and range[1] == cursor[1] and cursor[2] >= range[2] and cursor[2] <= range[4])
                               or (range[1] ~= range[3] and cursor[1] >= range[1] and cursor[1] <= range[3])
                             then
                               return cb(img)
                    @@ -419,8 +419,6 @@ function M.hover()
                         local win = Snacks.win(Snacks.win.resolve(Snacks.image.config.doc, "snacks_image", {
                           show = false,
                           enter = false,
                    -      -- Place the hover preview after the end of the math expression,
                    -      -- so it doesn't cover the closing delimiters.
                           relative = bufpos and "win" or nil,
                           win = bufpos and current_win or nil,
                           bufpos = bufpos,
                    diff --git a/lua/snacks/image/inline.lua b/lua/snacks/image/inline.lua
                    index 27f7595..61b6023 100644
                    --- a/lua/snacks/image/inline.lua
                    +++ b/lua/snacks/image/inline.lua
                    @@ -21,7 +21,7 @@ function M.new(buf)
                         buffer = buf,
                         callback = vim.schedule_wrap(update),
                       })
                    -  vim.api.nvim_create_autocmd({ "ModeChanged", "CursorMoved" }, {
                    +  vim.api.nvim_create_autocmd({ "ModeChanged", "CursorMoved", "CursorMovedI" }, {
                         group = group,
                         buffer = buf,
                         callback = function(ev)
                    @@ -37,44 +37,36 @@ function M.new(buf)
                       return self
                     end

                    -function M:conceal()
                    -  local mode = vim.fn.mode():sub(1, 1):lower() ---@type string
                    -  if mode == "i" or mode == "s" then
                    -    for _, img in pairs(self.imgs) do
                    -      if img.opts.conceal then
                    -        img:hide()
                    -      else
                    -        img:show()
                    -      end
                    -    end
                    -    return
                    +---@param img snacks.image.Placement
                    +---@param mode string
                    +function M:should_hide(img, mode)
                    +  if not img.opts.conceal or not img.opts.range then
                    +    return false
                       end
                    -  for _, img in pairs(self.imgs) do
                    -    img:show()
                    +  local range = img.opts.range
                    +  local from, to = vim.fn.line("v"), vim.fn.line(".")
                    +  from, to = math.min(from, to), math.max(from, to)
                    +  if range[3] < from or range[1] > to then
                    +    return false
                       end
                    -
                    -  local cursor = vim.api.nvim_win_get_cursor(0)
                    -  local row, col = cursor[1], cursor[2]
                    -  for _, img in pairs(self.imgs) do
                    -    local range = img.opts.conceal and img.opts.range
                    -    if range then
                    -      local inside = (range[1] == range[3] and row == range[1] and col >= range[2] and col <= range[4])
                    -        or (range[1] ~= range[3] and row >= range[1] and row <= range[3])
                    -      if inside then
                    -        img:hide()
                    -      end
                    -    end
                    +  -- Without concealcursor, Neovim reveals concealed text on the cursor line.
                    +  if mode == "i" or mode == "s" or not vim.wo.concealcursor:find(mode, 1, true) then
                    +    return true
                       end
                    -
                    -  if vim.wo.concealcursor:find(mode) then
                    -    return
                    +  local col = vim.api.nvim_win_get_cursor(0)[2]
                    +  if range[1] == range[3] then
                    +    return col >= range[2] and col <= range[4]
                       end
                    -  local from, to = vim.fn.line("v"), vim.fn.line(".")
                    -  from, to = math.min(from, to), math.max(from, to)
                    -  local hide = self:get(from, to)
                    -  for _, img in pairs(hide) do
                    -    if img.opts.conceal then
                    +  return true
                    +end
                    +
                    +function M:conceal()
                    +  local mode = vim.fn.mode():sub(1, 1):lower() ---@type string
                    +  for _, img in pairs(self.imgs) do
                    +    if self:should_hide(img, mode) then
                           img:hide()
                    +    else
                    +      img:show()
                         end
                       end
                     end
                    @@ -141,27 +133,12 @@ function M:update()
                                 type = i.type,
                                 ---@param p snacks.image.Placement
                                 on_update_pre = function(p)
                    -              local mode = vim.api.nvim_get_mode().mode:sub(1, 1):lower()
                                   if p.buf ~= vim.api.nvim_get_current_buf() then
                                     p.hidden = false
                                     return
                                   end
                    -              if (mode == "i" or mode == "s") and p.opts.conceal then
                    -                p.hidden = true
                    -                return
                    -              end
                    -              if mode == "n" and p.opts.conceal and p.opts.range then
                    -                local cursor = vim.api.nvim_win_get_cursor(0)
                    -                local row, col = cursor[1], cursor[2]
                    -                local range = p.opts.range
                    -                local inside = (range[1] == range[3] and row == range[1] and col >= range[2] and col <= range[4])
                    -                  or (range[1] ~= range[3] and row >= range[1] and row <= range[3])
                    -                if inside then
                    -                  p.hidden = true
                    -                  return
                    -                end
                    -              end
                    -              p.hidden = false
                    +              local mode = vim.api.nvim_get_mode().mode:sub(1, 1):lower()
                    +              p.hidden = self:should_hide(p, mode)
                                 end,
                                 ---@param p snacks.image.Placement
                                 on_update = function(p)
                    --
                    2.54.0
                  '')
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

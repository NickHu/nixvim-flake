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
                    From 590f96536ae7d99cc4d17323f967c22fdd10364a Mon Sep 17 00:00:00 2001
                    From: Nick Hu <me@nickhu.co.uk>
                    Date: Tue, 14 Jul 2026 17:54:11 +0900
                    Subject: [PATCH] fix(image): should_hide + cursor line check after
                     hover+inline

                    ---
                     lua/snacks/image/doc.lua    |  2 +-
                     lua/snacks/image/inline.lua | 84 +++++++++++++------------------------
                     2 files changed, 30 insertions(+), 56 deletions(-)

                    diff --git a/lua/snacks/image/doc.lua b/lua/snacks/image/doc.lua
                    index 95c7fb1..9fd8580 100644
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
                    diff --git a/lua/snacks/image/inline.lua b/lua/snacks/image/inline.lua
                    index 27f7595..a89e4c8 100644
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
                    @@ -37,44 +37,38 @@ function M.new(buf)
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
                    +  if not img.opts.conceal or not img.opts.range or self.buf ~= vim.api.nvim_get_current_buf() then
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
                    +  -- without concealcursor Neovim reveals the source on the cursor line anyway,
                    +  -- so the image has to go whatever the column
                    +  if mode == "i" or mode == "s" or not vim.wo.concealcursor:find(mode, 1, true) then
                    +    return true
                       end
                    -
                    -  if vim.wo.concealcursor:find(mode) then
                    -    return
                    +  -- the source stays concealed, so only give way where the cursor really is
                    +  if range[1] == range[3] then
                    +    local col = vim.api.nvim_win_get_cursor(0)[2]
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
                    +  local mode = vim.fn.mode():sub(1, 1):lower()
                    +  for _, img in pairs(self.imgs) do
                    +    if self:should_hide(img, mode) then
                           img:hide()
                    +    else
                    +      img:show()
                         end
                       end
                     end
                    @@ -141,27 +135,7 @@ function M:update()
                                 type = i.type,
                                 ---@param p snacks.image.Placement
                                 on_update_pre = function(p)
                    -              local mode = vim.api.nvim_get_mode().mode:sub(1, 1):lower()
                    -              if p.buf ~= vim.api.nvim_get_current_buf() then
                    -                p.hidden = false
                    -                return
                    -              end
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
                    +              p.hidden = self:should_hide(p, vim.fn.mode():sub(1, 1):lower())
                                 end,
                                 ---@param p snacks.image.Placement
                                 on_update = function(p)
                  '')
                  (builtins.toFile "0001-image-use-lualatex-instead-of-pdflatex.patch" ''
                    From c652007a29f3363ad75e07bc502972ef1fbff8b1 Mon Sep 17 00:00:00 2001
                    From: Nick Hu <me@nickhu.co.uk>
                    Date: Thu, 5 Mar 2026 12:10:26 +0000
                    Subject: [PATCH] image: use lualatex instead of pdflatex

                    ---
                     lua/snacks/image/convert.lua | 2 +-
                     lua/snacks/image/init.lua    | 4 ++--
                     2 files changed, 3 insertions(+), 3 deletions(-)

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
                  # Surface renders that failed or that LaTeX only half-produced,
                  # instead of showing a broken image or nothing at all.
                  (builtins.toFile "0003-image-report-render-errors.patch" ''
                    --- a/lua/snacks/image/convert.lua
                    +++ b/lua/snacks/image/convert.lua
                    @@ -113,6 +113,16 @@ local commands = {
                         on_error = function(step)
                           local pdf = assert(step.meta.pdf, "No pdf file") --[[@as string]]
                           if step.meta.pdf and vim.fn.getfsize(pdf) > 0 then
                    +        -- errors, but a usable pdf: render it anyway and report what went wrong
                    +        if Snacks.image.config.convert.notify and step.proc then
                    +          local errors = vim.tbl_filter(function(line)
                    +            return line:find("^!") ~= nil
                    +          end, vim.split(step.proc:out() .. "\n" .. step.proc:err(), "\n"))
                    +          if #errors > 0 then
                    +            local msg = "# Rendered with LaTeX errors\n```\n" .. table.concat(errors, "\n") .. "\n```"
                    +            Snacks.notify.warn(msg, { title = "Snacks Image" })
                    +          end
                    +        end
                             return true
                           end
                         end,
                    --- a/lua/snacks/image/placement.lua
                    +++ b/lua/snacks/image/placement.lua
                    @@ -111,6 +111,21 @@ end

                     function M:error()
                       if self.opts.inline then
                    +    -- an inline placement has no window of its own to show the error in
                    +    local pos = self.opts.range or self.opts.pos
                    +    self:_render({
                    +      {
                    +        row = pos[1] - 1,
                    +        col = pos[2],
                    +        virt_text = { { "⚠ render failed", "DiagnosticError" } },
                    +        virt_text_pos = "eol",
                    +        virt_text_hide = false,
                    +      },
                    +    })
                    +    -- `update` never runs for a failed image, so sync the owner's index here
                    +    if self.opts.on_update then
                    +      self.opts.on_update(self)
                    +    end
                         return
                       end
                       local msg = "# Image Conversion Failed:\n\n"
                  '')
                  # Editing a formula spawned a full LaTeX run per keystroke, mostly on
                  # syntactically broken input, and nothing ever cancelled the superseded
                  # runs -- so real previews queued behind dead work.
                  (builtins.toFile "0004-image-avoid-needless-compiles.patch" ''
                    --- a/lua/snacks/image/convert.lua
                    +++ b/lua/snacks/image/convert.lua
                    @@ -210,7 +210,8 @@ local commands = {
                     local have = {} ---@type table<string, boolean>
                     local proc_queue = {} ---@type snacks.spawn.Proc[]
                     local proc_running = 0 ---@type number
                    -local MAX_PROCS = 3
                    +-- a document of diagrams needs one LaTeX run per formula, and each is single-threaded
                    +local MAX_PROCS = math.max(3, math.min(8, #(uv.cpu_info() or {})))

                     ---@param proc? snacks.spawn.Proc
                     local function schedule(proc)
                    @@ -379,7 +380,7 @@ end
                     function Convert:on_done()
                       local step = self:current()
                       self._done = true
                    -  if self._err and Snacks.image.config.convert.notify then
                    +  if self._err and Snacks.image.config.convert.notify and not self.aborted then
                         local title = step and ("Conversion failed at step `%s`"):format(step.name) or "Conversion failed"
                         if step and step.proc then
                           step.proc:debug({ title = title })
                    @@ -403,6 +404,9 @@ function Convert:abort()
                       self._err = "Aborted"
                       for _, step in ipairs(self.steps) do
                         if step.proc then
                    +      -- a queued proc has no handle yet, so `kill` alone would let it start
                    +      -- once its turn comes round
                    +      step.proc.aborted = true
                           step.proc:kill()
                         end
                       end
                    --- a/lua/snacks/image/image.lua
                    +++ b/lua/snacks/image/image.lua
                    @@ -206,6 +206,12 @@ function M:del(pid)

                       if not next(self.placements) then
                         terminal.request({ a = "d", d = "i", i = self.id })
                    +    -- nothing displays this image any more, so stop converting it and forget it,
                    +    -- letting a later request for the same source start afresh
                    +    if self._convert and not self._convert:done() then
                    +      self._convert:abort()
                    +      images[self.file] = nil
                    +    end
                       end
                     end

                    --- a/lua/snacks/image/inline.lua
                    +++ b/lua/snacks/image/inline.lua
                    @@ -2,6 +2,7 @@
                     ---@field buf number
                     ---@field imgs table<number, snacks.image.Placement>
                     ---@field idx table<number, snacks.image.Placement>
                    +---@field deferred? boolean a visible image was left unconverted while it is being edited
                     local M = {}
                     M.__index = M

                    @@ -27,6 +28,9 @@ function M.new(buf)
                         callback = function(ev)
                           if ev.buf == self.buf and ev.buf == vim.api.nvim_get_current_buf() then
                             self:conceal()
                    +        if self.deferred then
                    +          update()
                    +        end
                           end
                         end,
                       })
                    @@ -40,10 +44,19 @@ end
                     ---@param img snacks.image.Placement
                     ---@param mode string
                     function M:should_hide(img, mode)
                    -  if not img.opts.conceal or not img.opts.range or self.buf ~= vim.api.nvim_get_current_buf() then
                    +  if not img.opts.conceal then
                    +    return false
                    +  end
                    +  return self:is_revealed(img.opts.range, mode)
                    +end
                    +
                    +--- Whether Neovim is currently revealing the concealed source in `range`.
                    +---@param range? number[]
                    +---@param mode string
                    +function M:is_revealed(range, mode)
                    +  if not range or self.buf ~= vim.api.nvim_get_current_buf() then
                         return false
                       end
                    -  local range = img.opts.range
                       local from, to = vim.fn.line("v"), vim.fn.line(".")
                       from, to = math.min(from, to), math.max(from, to)
                       if range[3] < from or range[1] > to then
                    @@ -113,6 +126,8 @@ function M:update()
                       Snacks.image.doc.find_visible(self.buf, function(imgs)
                         local visible = self:visible()
                         local stats = { new = 0, del = 0, update = 0 }
                    +    local mode = vim.fn.mode():sub(1, 1):lower()
                    +    self.deferred = false
                         for _, i in ipairs(imgs) do
                           local img ---@type snacks.image.Placement?
                           for v, o in pairs(visible) do
                    @@ -122,7 +137,13 @@ function M:update()
                               break
                             end
                           end
                    -      if not img then
                    +      local img_conceal = vim.b[self.buf].snacks_image_conceal or conceal(i.lang, i.type)
                    +      -- A block being edited is revealed rather than rendered. Converting it now
                    +      -- would run LaTeX on every intermediate keystroke, queued ahead of images
                    +      -- that are actually on screen, so wait until the cursor leaves.
                    +      if not img and img_conceal and self:is_revealed(i.range, mode) then
                    +        self.deferred = true
                    +      elseif not img then
                             stats.new = stats.new + 1
                             img = Snacks.image.placement.new(
                               self.buf,
                    @@ -131,7 +152,7 @@ function M:update()
                                 pos = i.pos,
                                 range = i.range,
                                 inline = true,
                    -            conceal = vim.b[self.buf].snacks_image_conceal or conceal(i.lang, i.type),
                    +            conceal = img_conceal,
                                 type = i.type,
                                 ---@param p snacks.image.Placement
                                 on_update_pre = function(p)
                  '')
                  # Inline images were laid out against the wrong widths: concealed text
                  # still wraps, and the gutter is not the image's to use.
                  (builtins.toFile "0005-image-fix-inline-sizing.patch" ''
                    --- a/lua/snacks/image/placement.lua
                    +++ b/lua/snacks/image/placement.lua
                    @@ -364,6 +364,28 @@ function M:render_grid(loc)
                       else
                         local is_inline = has_before or has_after
                         local icon = Snacks.image.config.icons[self.opts.type or "image"] or Snacks.image.config.icons.image
                    +    -- Concealed text still occupies its width when wrapping, so a long line in
                    +    -- the block leaves blank rows behind the image. Hide the lines outright and
                    +    -- anchor above them: virt_lines on a concealed line are concealed as well.
                    +    if conceal and not is_inline and range[1] > 1 and vim.fn.has("nvim-0.11.4") == 1 then
                    +      extmarks[#extmarks + 1] = {
                    +        row = range[1] - 1,
                    +        col = 0,
                    +        end_row = range[3] - 1,
                    +        conceal_lines = "",
                    +        virt_text_hide = false,
                    +      }
                    +      extmarks[#extmarks + 1] = {
                    +        row = range[1] - 2,
                    +        col = 0,
                    +        ---@param l string
                    +        virt_lines = vim.tbl_map(function(l)
                    +          return { { l, hl } }
                    +        end, img),
                    +        virt_text_hide = false,
                    +      }
                    +      return self:_render(extmarks)
                    +    end
                         -- render below in virtual lines
                         extmarks[#extmarks + 1] = {
                           row = range[1] - 1,
                    @@ -392,11 +414,9 @@ function M:_render(extmarks)
                           e.virt_text = nil
                           e.conceal = nil
                           e.conceal_lines = nil
                    -      if e.virt_lines then
                    -        e.virt_lines = vim.tbl_map(function(l)
                    -          return { { "" } }
                    -        end, e.virt_lines)
                    -      end
                    +      -- the source lines are revealed again, so rows for the image would only
                    +      -- push them down
                    +      e.virt_lines = nil
                         end
                       end
                       local eids = {} ---@type number[]
                    @@ -469,7 +489,9 @@ function M:state()
                       local zindex = vim.api.nvim_win_get_config(0).zindex or 0

                       for _, win in ipairs(self:wins()) do
                    -    width = math.min(width, vim.api.nvim_win_get_width(win))
                    +    -- the gutter is not available to the image; `can_overlay` measures it likewise
                    +    local info = vim.fn.getwininfo(win)[1]
                    +    width = math.min(width, info.width - info.textoff)
                         height = math.min(height, vim.api.nvim_win_get_height(win))
                         if is_fallback then
                           local z = vim.api.nvim_win_get_config(win).zindex or 0
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

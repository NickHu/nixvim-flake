{ config
, pkgs
, helpers
, ...
}: {
  config = {
    files = {
      "ftplugin/ocaml.lua" = {
        opts = {
          formatexpr = "v:lua.require'conform'.formatexpr({ 'formatters': [ 'ocamlformat' ]})";
        };
      };
      "ftplugin/tex.lua" = {
        autoCmd = [{
          event = [ "BufWritePost" ];
          command = "call vimtex#toc#refresh()";
        }];
        opts = {
          conceallevel = 2;
        };
      };
      "ftplugin/forester.lua" = {
        opts = {
          cindent = true;
          cinoptions = "+0";
        };
        userCommands = {
          "ForesterNew" = {
            command = helpers.mkRaw ''
              function(opts)
                local prefix = opts.args
                local handle = io.popen('forester new --dest=trees --prefix=' .. prefix .. ' --random')
                if not handle then
                  print('Failed to run forester')
                  return
                end

                local result = handle:read("*a")
                handle:close()

                -- Extract 'foo-0001' from the result 'trees/foo-0001.tree'
                local match = string.match(result, "trees/(%g+(%-[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]))%.tree")
                if match then
                  -- Insert the extracted string into the current buffer
                  vim.api.nvim_put({match}, 'c', false, true)
                  -- Open the new tree in a new buffer
                  vim.cmd('e ' .. result)
                else
                  print('No match found in the command output: ' .. result)
                end
              end
            '';
            desc = "Create new forester tree";
            nargs = 1;
          };
        };
      };
    };
    autoCmd = [
      {
        event = "User";
        group = "lualine_augroup";
        pattern = "LspProgressStatusUpdated";
        callback = helpers.mkRaw ''
          require("lualine").refresh
        '';
      }
      {
        event = "ModeChanged";
        pattern = "*";
        callback = helpers.mkRaw ''
          function()
            if ((vim.v.event.old_mode == 's' and vim.v.event.new_mode == 'n') or vim.v.event.old_mode == 'i')
                and require('luasnip').session.current_nodes[vim.api.nvim_get_current_buf()]
                and not require('luasnip').session.jump_active
            then
              require('luasnip').unlink_current()
            end
          end
        '';
      }
    ];
    autoGroups = {
      lualine_augroup = {
        clear = true;
      };
    };
    extraPlugins = with pkgs.vimPlugins; [
      {
        plugin = lsp-progress-nvim;
        config = ''
          lua require("lsp-progress").setup()
        '';
      }
      ltex_extra-nvim
      nvim-solarized-lua
      {
        plugin = nvim-scissors;
        config = ''
          lua require("scissors").setup({ snippetDir = "~/Dropbox/nixvim-flake/snippets", })
        '';
      }
      {
        plugin = nvim-web-devicons;
        config = ''
          lua require("nvim-web-devicons").setup()
        '';
      }
      {
        plugin = forester-nvim;
        config = ''
          lua require("forester").setup({ opts = { forests = { "~/Dropbox/forest" }, tree_dirs = { "trees" }, conceal = true, } })
        '';
      }
      pest-vim
      vim-eunuch
      vim-nix
      {
        plugin = vim-pandoc;
        config = ''
          let g:pandoc#biblio#bibs = ["bibliography.bib"]
          let g:pandoc#command#latex_engine="lualatex"
          let g:pandoc#command#autoexec_on_writes=1
          let g:pandoc#completion#bib#mode='citeproc'
          let g:pandoc#folding#fold_fenced_codeblocks=1
          let g:pandoc#syntax#codeblocks#ignore=['definition']
          let g:pandoc#syntax#use_definition_lists=0
        '';
      }
      vim-pandoc-syntax
      vim-rhubarb
      {
        plugin = multicursor-nvim;
        config = ''
          lua require("multicursor-nvim").setup()
        '';
      }
    ];
    colorscheme = "solarized";
    globals = {
      tex_flavor = "latex";
    };
    opts = {
      clipboard = "unnamed";
      colorcolumn = "80";
      expandtab = true;
      formatexpr = "v:lua.require'conform'.formatexpr()";
      jumpoptions = [ "stack" "view" ];
      linebreak = true;
      mouse = "vi";
      number = true;
      relativenumber = true;
      signcolumn = "number";
      shiftwidth = 2;
      showbreak = "↳ ";
      spelllang = "en_gb";
      undodir = "/home/nick/.cache/nvim/undo"; # TODO: make generic over home
      undofile = true;
      updatetime = 750;
    };
    keymaps = pkgs.lib.attrsets.mapAttrsToList
      (original: replacement: {
        mode = [ "n" "x" ] ++ (pkgs.lib.optional (original != "i") "o") ++ (pkgs.lib.optional (original == "gN") "v");
        key = original;
        action = replacement;
      })
      {
        # colemak-dh
        "m" = "h";
        "gm" = "gh";
        "n" = "j";
        "gn" = "gj";
        "e" = "k";
        "ge" = "gk";
        "i" = "l";
        "M" = "H";
        "gM" = "gH";
        "N" = "J";
        "gN" = "gJ";
        "I" = "L";
        # recover lost keys
        "k" = "n";
        "K" = "N";
        "l" = "e";
        "gl" = "ge";
        "L" = "E";
        "gL" = "gE";
        "h" = "i";
        "gh" = "gi";
        "H" = "I";
        "gH" = "gI";
        "j" = "m";
        "gj" = "gm";
        "J" = "M";
        "gJ" = "gM";
      } ++ [
      {
        mode = [ "n" "v" ];
        key = "<C-Up>";
        action = helpers.mkRaw "function() require('multicursor-nvim').lineAddCursor(-1) end";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" "v" ];
        key = "<C-Down>";
        action = helpers.mkRaw "function() require('multicursor-nvim').lineAddCursor(1) end";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" "v" ];
        key = "<Up>";
        action = helpers.mkRaw "function() require('multicursor-nvim').lineSkipCursor(-1) end";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" "v" ];
        key = "<Down>";
        action = helpers.mkRaw "function() require('multicursor-nvim').lineSkipCursor(1) end";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" "v" ];
        key = "<C-k>";
        action = helpers.mkRaw "function() require('multicursor-nvim').matchAddCursor(1) end";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" "v" ];
        key = "<leader>k";
        action = helpers.mkRaw "function() require('multicursor-nvim').matchSkipCursor(1) end";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" "v" ];
        key = "<C-S-k>";
        action = helpers.mkRaw "function() require('multicursor-nvim').matchAddCursor(-1) end";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" "v" ];
        key = "<leader>K";
        action = helpers.mkRaw "function() require('multicursor-nvim').matchSkipCursor(-1) end";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" "v" ];
        key = "<Left>";
        action = helpers.mkRaw "require('multicursor-nvim').nextCursor";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" "v" ];
        key = "<Right>";
        action = helpers.mkRaw "require('multicursor-nvim').prevCursor";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" "v" ];
        key = "<leader>x";
        action = helpers.mkRaw "require('multicursor-nvim').deleteCursor";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" ];
        key = "<C-LeftMouse>";
        action = helpers.mkRaw "require('multicursor-nvim').handleMouse";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" "v" ];
        key = "<C-q>";
        action = helpers.mkRaw "require('multicursor-nvim').toggleCursor";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" "v" ];
        key = "<leader><C-q>";
        action = helpers.mkRaw "require('multicursor-nvim').duplicateCursors";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" ];
        key = "<Esc>";
        action = helpers.mkRaw ''
          function()
            if not require('multicursor-nvim').cursorsEnabled() then
              require('multicursor-nvim').enableCursors()
            elseif require('multicursor-nvim').hasCursors() then
              require('multicursor-nvim').clearCursors()
            else
              -- Default <esc> handler.
            end
          end
        '';
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" "v" ];
        key = "<leader>a";
        action = helpers.mkRaw "require('multicursor-nvim').alignCursors";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "v" ];
        key = "<C-s>";
        action = helpers.mkRaw "require('multicursor-nvim').splitCursors";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "v" ];
        key = "H";
        action = helpers.mkRaw "insertVisualH";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "v" ];
        key = "A";
        action = helpers.mkRaw "require('multicursor-nvim').appendVisual";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" "v" ];
        key = "<C-m>";
        action = helpers.mkRaw "require('multicursor-nvim').matchCursors";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "v" ];
        key = "<leader><C-t>";
        action = helpers.mkRaw "function() require('multicursor-nvim').transposeCursors(1) end";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "v" ];
        key = "<leader><C-S-t>";
        action = helpers.mkRaw "function() require('multicursor-nvim').transposeCursors(-1) end";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" "x" "o" ];
        key = "<leader>s";
        action = helpers.mkRaw "function() require('flash').jump() end";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" "x" "o" ];
        key = "<leader>S";
        action = helpers.mkRaw "function() require('flash').treesitter() end";
        options = {
          silent = true;
        };
      }
      {
        mode = "o";
        key = "r";
        action = helpers.mkRaw "function() require('flash').remote() end";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "o" "x" ];
        key = "R";
        action = helpers.mkRaw "function() require('flash').treesitter_search() end";
        options = {
          silent = true;
        };
      }
      {
        mode = "c";
        key = "<C-s>";
        action = helpers.mkRaw "function() require('flash').toggle() end";
        options = {
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>u";
        action = ":UndotreeToggle<CR>";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "i" "s" ];
        key = "<M-n>";
        action = "<Plug>luasnip-next-choice";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "i" "s" ];
        key = "<M-p>";
        action = "<Plug>luasnip-prev-choice";
        options = {
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<C-m>"; # this also maps <CR> due to legacy terminal behavior
        action = ":<C-U>TmuxNavigateLeft<CR>";
        options = {
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<CR>";
        action = "<CR>";
        options = {
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<C-n>";
        action = ":<C-U>TmuxNavigateDown<CR>";
        options = {
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<C-e>";
        action = ":<C-U>TmuxNavigateUp<CR>";
        options = {
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<C-i>"; # this also maps <Tab> due to legacy terminal behavior
        action = ":<C-U>TmuxNavigateRight<CR>";
        options = {
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>bd";
        action = helpers.mkRaw "MiniBufremove.delete";
        options = {
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<Tab>";
        action = "<Tab>";
        options = {
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-e>";
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-i>";
      }
    ] ++ pkgs.lib.attrsets.mapAttrsToList
      (key: action: {
        mode = "n";
        inherit key;
        action = "<Cmd>Lspsaga " + action + "<CR>";
        options = {
          silent = true;
        };
      })
      {
        "[d" = "diagnostic_jump_prev";
        "]d" = "diagnostic_jump_next";
        "<leader>e" = "show_buf_diagnostics";
        "<leader>E" = "show_workspace_diagnostics";
        "<leader>t" = "outline";
        "<M-Enter>" = "term_toggle";
        "<M-e>" = "show_cursor_diagnostics";
        "<M-]>" = "goto_definition";
        "<M-l>" = "code_action";
        "<M-r>" = "rename";
        "<M-p>" = "finder";
        "E" = "hover_doc";
        "g+" = "outgoing_calls";
        "g-" = "incoming_calls";
        "gt" = "goto_type_definition";
      };
    plugins = {
      bufferline = {
        enable = true;
        settings.options.diagnostics = "nvim_lsp";
      };
      clangd-extensions.enable = true;
      conform-nvim = {
        enable = true;
        settings = {
          formatters_by_ft = {
            ocaml = [ [ "ocp-indent" "ocamlformat" ] ];
          };
          format_after_save = helpers.mkRaw ''
            function(bufnr)
              -- Disable with a global or buffer-local variable
              if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                return
              end
              if not slow_format_filetypes[vim.bo[bufnr].filetype] then
                return
              end
              return { lsp_fallback = true }
            end
          '';
          format_on_save = helpers.mkRaw ''
            function(bufnr)
              -- Disable with a global or buffer-local variable
              if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                return
              end
              if slow_format_filetypes[vim.bo[bufnr].filetype] then
                return
              end
              local function on_format(err)
                if err and err:match("timeout$") then
                  slow_format_filetypes[vim.bo[bufnr].filetype] = true
                end
              end
              return { timeout_ms = 200, lsp_fallback = true }, on_format
            end
          '';
        };
      };
      copilot-lua = {
        enable = true;
        filetypes = {
          "*" = true;
        };
        suggestion = {
          autoTrigger = true;
          keymap.accept = "<Right>";
        };
      };
      fugitive.enable = true;
      gitsigns.enable = true;
      indent-blankline.enable = true;
      rustaceanvim = {
        enable = true;
        settings.tools = {
          enable_clippy = true;
        };
      };
      flash = {
        enable = true;
        settings.modes.search.enabled = true;
      };
      lsp = {
        enable = true;
        inlayHints = true;
        onAttach = ''
          if client.name == "ltex" then
            require("ltex_extra").setup {
              load_langs = {
                "en-GB"
              }
            }
          end
        '';
        servers = {
          ltex = {
            enable = true;
            settings = {
              language = "en-GB";
            };
            extraOptions = {
              get_language_id = helpers.mkRaw ''
                function(_, filetype)
                  local language_id_mapping = {
                    bib = 'bibtex',
                    plaintex = 'tex',
                    rnoweb = 'sweave',
                    rst = 'restructuredtext',
                    tex = 'latex',
                    xhtml = 'xhtml',
                    pandoc = 'markdown',
                    forester = 'latex',
                  }
                  local language_id = language_id_mapping[filetype]
                  if language_id then
                    return language_id
                  else
                    return filetype
                  end
                end
              '';
            };
            filetypes = [
              "bib"
              "gitcommit"
              "org"
              "plaintex"
              "rst"
              "rnoweb"
              "tex"
              "pandoc"
              "quarto"
              "rmd"
              "forester"
            ];
          };
          lua-ls.enable = true;
          nixd.enable = true;
          ocamllsp.enable = true;
          ocamllsp.package = null;
          pest-ls.enable = true;
          tailwindcss.enable = true;
          svelte.enable = true;
          texlab = {
            enable = true;
            extraOptions.settings.texlab = {
              build = {
                args = [
                  "-pdf"
                  "-shell-escape"
                  "-interaction=nonstopmode"
                  "-synctex=1"
                  "%f"
                  "-auxdir=texlab-build"
                  "-outdir=texlab-build"
                ];
                auxDirectory = "texlab-build";
                logDirectory = "texlab-build";
              };
              forwardSearch.executable = "zathura";
              chktex = {
                onOpenAndSave = true;
                onEdit = true;
              };
              latexindent.modifyLineBreaks = true;
            };
          };
        };
        keymaps = {
          diagnostic = {
            "<M-q>" = "setloclist";
          };
          lspBuf = {
            "<M-f>" = "format";
            "<M-k>" = "signature_help";
            "<M-w>a" = "add_workspace_folder";
            "<M-w>d" = "remove_workspace_folder";
            "gD" = "document_symbol";
            "gW" = "workspace_symbol";
            "gd" = "declaration";
            "gi" = "implementation";
            "gr" = "references";
          };
          silent = true;
        };
      };
      lspkind = {
        enable = true;
        cmp = {
          enable = true;
          menu = {
            buffer = "[Buffer]";
            calc = "[Calc]";
            cmdline = "[cmdline]";
            cmp_pandoc = "[Pandoc]";
            dap = "[DAP]";
            latex_symbols = "[LaTeX]";
            luasnip = "[LuaSnip]";
            nvim_lsp = "[LSP]";
            nvim_lsp_document_symbol = "[LSP doc]";
            nvim_lsp_signature_help = "[LSP sig]";
            nvim_lua = "[Lua]";
            path = "[Path]";
            spell = "[Spell]";
            treesitter = "[TS]";
          };
        };
      };
      lspsaga = {
        enable = true;
      };
      lualine = {
        enable = true;
        extensions = [
          "fugitive"
          "fzf"
          "nvim-dap-ui"
          "nvim-tree"
          "quickfix"
        ];
        sections = {
          lualine_c = [
            {
              name = "filename";
              extraConfig = {
                path = 1;
              };
            }
            {
              name = helpers.mkRaw ''
                require("lsp-progress").progress
              '';
            }
          ];
        };
      };
      luasnip = {
        enable = true;
        settings = {
          enable_autosnippets = true;
          store_selection_keys = "<Tab>";
        };
        fromLua = [{ } { paths = "~/Dropbox/nixvim-flake/snippets"; }];
        fromVscode = [{ } { paths = "~/Dropbox/nixvim-flake/snippets"; }];
      };
      mini = {
        enable = true;
        modules = {
          ai = { };
          align = { };
          bracketed = { };
          bufremove = { };
          indentscope = {
            draw = {
              animation = helpers.mkRaw "require('mini.indentscope').gen_animation.none()";
            };
            symbol = "▎";
          };
          operators = { };
          pairs = { };
          splitjoin = { };
          sessions = { };
          starter = { };
          trailspace = { };
        };
      };
      markdown-preview.enable = true;
      cmp = {
        enable = true;
        cmdline = {
          "/" = {
            mapping = helpers.mkRaw "cmp.mapping.preset.cmdline()";
            sources = [
              {
                name = "nvim_lsp_document_symbol";
              }
              {
                name = "buffer";
              }
            ];
          };
          ":" = {
            mapping = helpers.mkRaw ''
              cmp.mapping.preset.cmdline({
                ["<CR>"] = {
                  c = cmp.mapping.confirm()
                }
              })
            '';
            sources = [
              {
                name = "path";
              }
              {
                name = "cmdline";
                option = {
                  ignore_cmds = [
                    "Man"
                    "!"
                  ];
                };
              }
            ];
          };
        };
        filetype = {
          "dapui_watches" = {
            sources = [
              {
                name = "dap";
              }
            ];
          };
          "dap-repl" = {
            sources = [
              {
                name = "dap";
              }
            ];
          };
        };
        settings = {
          mapping = helpers.mkRaw ''
            cmp.mapping.preset.insert({
              ['<C-b>'] = cmp.mapping.scroll_docs(-4),
              ['<C-f>'] = cmp.mapping.scroll_docs(4),
              ['<CR>'] = cmp.mapping.confirm(),
              ['<Tab>'] =
                cmp.mapping(
                  function(fallback)
                    local has_words_before = function()
                      unpack = unpack or table.unpack
                      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                      return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
                    end
                    local luasnip = require("luasnip")
                    if luasnip.expand_or_locally_jumpable() then
                      luasnip.expand_or_jump()
                    elseif cmp.visible() then
                      cmp.select_next_item()
                    elseif has_words_before() then
                      cmp.complete()
                    else
                      fallback()
                    end
                  end,
                  { "i", "s" }),
              ['<S-Tab>'] =
                cmp.mapping(
                  function(fallback)
                    local luasnip = require("luasnip")
                    if luasnip.locally_jumpable(-1) then
                      luasnip.jump(-1)
                    elseif cmp.visible() then
                      cmp.select_prev_item()
                    else
                      fallback()
                    end
                  end,
                  { "i", "s" }),
            })
          '';
          snippet.expand = ''
            function(args)
              require('luasnip').lsp_expand(args.body)
            end
          '';
          sources = [
            {
              name = "nvim_lsp_signature_help";
              groupIndex = 0;
            }
            {
              name = "nvim_lsp";
              groupIndex = 1;
            }
            {
              name = "luasnip";
              groupIndex = 1;
            }
            {
              name = "calc";
              groupIndex = 1;
            }
            {
              name = "path";
              groupIndex = 1;
            }
            {
              name = "buffer";
              groupIndex = 2;
            }
            {
              name = "treesitter";
              groupIndex = 2;
            }
            {
              name = "cmp_pandoc";
              groupIndex = 1;
            }
            {
              name = "latex_symbols";
              groupIndex = 1;
            }
            {
              name = "spell";
              groupIndex = 1;
            }
          ];
        };
      };
      nvim-colorizer.enable = true;
      nvim-tree = {
        enable = true;
        onAttach = helpers.mkRaw ''
          function(bufnr)
            local api = require("nvim-tree.api")
            local function opts(desc)
              return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
            end
            vim.keymap.set('n', '<C-]>',   api.tree.change_root_to_node,        opts('CD'))
            vim.keymap.set('n', '<M-o>',   api.node.open.replace_tree_buffer,   opts('Open: In Place'))
            vim.keymap.set('n', '<C-e>',   api.node.show_info_popup,            opts('Info'))
            vim.keymap.set('n', '<C-r>',   api.fs.rename_sub,                   opts('Rename: Omit Filename'))
            vim.keymap.set('n', '<C-t>',   api.node.open.tab,                   opts('Open: New Tab'))
            vim.keymap.set('n', '<C-v>',   api.node.open.vertical,              opts('Open: Vertical Split'))
            vim.keymap.set('n', '<C-h>',   api.node.open.horizontal,            opts('Open: Horizontal Split'))
            vim.keymap.set('n', '<BS>',    api.node.navigate.parent_close,      opts('Close Directory'))
            vim.keymap.set('n', '<CR>',    api.node.open.edit,                  opts('Open'))
            vim.keymap.set('n', '<Tab>',   api.node.open.preview,               opts('Open Preview'))
            vim.keymap.set('n', '>',       api.node.navigate.sibling.next,      opts('Next Sibling'))
            vim.keymap.set('n', '<',       api.node.navigate.sibling.prev,      opts('Previous Sibling'))
            vim.keymap.set('n', '.',       api.node.run.cmd,                    opts('Run Command'))
            vim.keymap.set('n', '-',       api.tree.change_root_to_parent,      opts('Up'))
            vim.keymap.set('n', 'a',       api.fs.create,                       opts('Create File Or Directory'))
            vim.keymap.set('n', 'bd',      api.marks.bulk.delete,               opts('Delete Bookmarked'))
            vim.keymap.set('n', 'bt',      api.marks.bulk.trash,                opts('Trash Bookmarked'))
            vim.keymap.set('n', 'bmv',     api.marks.bulk.move,                 opts('Move Bookmarked'))
            vim.keymap.set('n', 'B',       api.tree.toggle_no_buffer_filter,    opts('Toggle Filter: No Buffer'))
            vim.keymap.set('n', 'c',       api.fs.copy.node,                    opts('Copy'))
            vim.keymap.set('n', 'C',       api.tree.toggle_git_clean_filter,    opts('Toggle Filter: Git Clean'))
            vim.keymap.set('n', '[c',      api.node.navigate.git.prev,          opts('Prev Git'))
            vim.keymap.set('n', ']c',      api.node.navigate.git.next,          opts('Next Git'))
            vim.keymap.set('n', 'd',       api.fs.remove,                       opts('Delete'))
            vim.keymap.set('n', 'D',       api.fs.trash,                        opts('Trash'))
            vim.keymap.set('n', 'zR',      api.tree.expand_all,                 opts('Expand All'))
            vim.keymap.set('n', '<M-r>',   api.fs.rename_basename,              opts('Rename: Basename'))
            vim.keymap.set('n', ']d',      api.node.navigate.diagnostics.next,  opts('Next Diagnostic'))
            vim.keymap.set('n', '[d',      api.node.navigate.diagnostics.prev,  opts('Prev Diagnostic'))
            vim.keymap.set('n', 'F',       api.live_filter.clear,               opts('Live Filter: Clear'))
            vim.keymap.set('n', 'f',       api.live_filter.start,               opts('Live Filter: Start'))
            vim.keymap.set('n', 'g?',      api.tree.toggle_help,                opts('Help'))
            vim.keymap.set('n', 'gy',      api.fs.copy.absolute_path,           opts('Copy Absolute Path'))
            vim.keymap.set('n', 'M',       api.tree.toggle_hidden_filter,       opts('Toggle Filter: Dotfiles'))
            vim.keymap.set('n', 'gi',      api.tree.toggle_gitignore_filter,    opts('Toggle Filter: Git Ignore'))
            vim.keymap.set('n', 'N',       api.node.navigate.sibling.last,      opts('Last Sibling'))
            vim.keymap.set('n', 'E',       api.node.navigate.sibling.first,     opts('First Sibling'))
            vim.keymap.set('n', 'I',       api.node.open.toggle_group_empty,    opts('Toggle Group Empty'))
            vim.keymap.set('n', 'J',       api.tree.toggle_no_bookmark_filter,  opts('Toggle Filter: No Bookmark'))
            vim.keymap.set('n', 'j',       api.marks.toggle,                    opts('Toggle Bookmark'))
            vim.keymap.set('n', 'o',       api.node.open.edit,                  opts('Open'))
            vim.keymap.set('n', 'O',       api.node.open.no_window_picker,      opts('Open: No Window Picker'))
            vim.keymap.set('n', 'p',       api.fs.paste,                        opts('Paste'))
            vim.keymap.set('n', 'P',       api.node.navigate.parent,            opts('Parent Directory'))
            vim.keymap.set('n', 'q',       api.tree.close,                      opts('Close'))
            vim.keymap.set('n', 'r',       api.fs.rename,                       opts('Rename'))
            vim.keymap.set('n', 'R',       api.tree.reload,                     opts('Refresh'))
            vim.keymap.set('n', 's',       api.node.run.system,                 opts('Run System'))
            vim.keymap.set('n', 'S',       api.tree.search_node,                opts('Search'))
            vim.keymap.set('n', 'u',       api.fs.rename_full,                  opts('Rename: Full Path'))
            vim.keymap.set('n', 'U',       api.tree.toggle_custom_filter,       opts('Toggle Filter: Hidden'))
            vim.keymap.set('n', 'W',       api.tree.collapse_all,               opts('Collapse'))
            vim.keymap.set('n', 'x',       api.fs.cut,                          opts('Cut'))
            vim.keymap.set('n', 'y',       api.fs.copy.filename,                opts('Copy Name'))
            vim.keymap.set('n', 'Y',       api.fs.copy.relative_path,           opts('Copy Relative Path'))
            vim.keymap.set('n', '<2-LeftMouse>',  api.node.open.edit,           opts('Open'))
            vim.keymap.set('n', '<2-RightMouse>', api.tree.change_root_to_node, opts('CD'))
          end
        '';
      };
      rainbow-delimiters.enable = true;
      surround.enable = true;
      treesitter = {
        enable = true;
        grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars ++ [
          pkgs.tree-sitter-grammars.tree-sitter-forester
        ];
        folding = true;
        settings = {
          highlight.enable = true;
          incremental_selection = {
            enable = true;
            keymaps = {
              init_selection = "<C-Space>";
              node_incremental = "<C-Space>";
              node_decremental = "<BS>";
            };
          };
          indent.enable = true;
        };
      };
      treesitter-context.enable = true;
      treesitter-refactor = {
        enable = true;
        highlightDefinitions.enable = true;
        navigation.enable = true;
        smartRename.enable = true;
      };
      telescope = {
        enable = true;
        extensions = {
          fzf-native.enable = true;
        };
        keymaps = {
          "<leader>/" = "live_grep";
          "<leader>d" = "diagnostics";
          "<leader>b" = "buffers";
          "<leader>f" = "find_files";
        };
      };
      tmux-navigator = {
        enable = true;
        settings = {
          no_mappings = true;
          no_wrap = true;
        };
      };
      typescript-tools.enable = true;
      undotree = {
        enable = true;
      };
      vim-matchup = {
        enable = true;
        enableSurround = true;
        enableTransmute = true;
        treesitterIntegration.enable = true;
      };
      which-key.enable = true;
      texpresso.enable = true;
      vimtex = {
        enable = true;
        settings = {
          compiler_latexmk = {
            aux_dir = "build";
            out_dir = "build";
            options = [
              "-shell-escape"
              "-verbose"
              "-file-line-error"
              "-synctex=1"
              "-interaction=nonstopmode"
            ];
          };
          fold_enabled = 1;
          format_enabled = 1;
          view_method = "zathura";
          view_use_temp_files = true;
          quickfix_open_on_warning = 0;
        };
        texlivePackage = null; # don't install texlive at all
      };
    };
    extraConfigLuaPre = ''
      -- disable netrw at the very start of your init.lua
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      local slow_format_filetypes = {}

      local mc = require('multicursor-nvim')
      local TERM_CODES = require('multicursor-nvim.term-codes')
      -- patch https://github.com/jake-stewart/multicursor.nvim/blob/99d704ab32a7a07ffa198370b4b177a23dfce8ec/lua/multicursor-nvim/examples.lua#L344-L360 for colemak-dh
      function insertVisualH()
          local mode = vim.fn.mode()
          mc.action(function(ctx)
              ctx:forEachCursor(function(cursor)
                  cursor:splitVisualLines()
              end)
              ctx:forEachCursor(function(cursor)
                  cursor:feedkeys(
                      (cursor:atVisualStart() and "" or "o")
                          .. "<esc>"
                          .. (mode == TERM_CODES.CTRL_V and "" or "^"),
                      { keycodes = true }
                  )
              end)
          end)
          mc.feedkeys(mode == TERM_CODES.CTRL_V and "h" or "H", { remap = true })
      end
    '';
    userCommands = {
      "LuaSnipEdit" = {
        command = "lua require('luasnip.loaders').edit_snippet_files()";
        desc = "Edit Snippets";
      };
      "FormatDisable" = {
        bang = true;
        command = ''
          if <bang>v:true
            let g:disable_autoformat = v:true
          else
            let b:disable_autoformat = v:true
          endif
        '';
        desc = "Disable autoformat-on-save";
      };
      "FormatEnable" = {
        command = ''
          let b:disable_autoformat = v:false
          let g:disable_autoformat = v:false
        '';
        desc = "Re-enable autoformat-on-save";
      };
    };
  };
}

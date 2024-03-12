{ config
, pkgs
, helpers
, ...
}: {
  config = {
    files = {
      "ftplugin/tex.lua" = {
        autoCmd = [{
          event = [ "BufWritePost" ];
          command = "call vimtex#toc#refresh()";
        }];
        options = {
          conceallevel = 2;
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
        plugin = tmux-navigator;
        config = ''
          let g:tmux_navigator_no_mappings = 1
        '';
      }
    ];
    colorscheme = "solarized";
    filetype = {
      extension = {
        tree = "tree";
      };
    };
    globals = {
      tex_flavor = "latex";
      tmux_navigator_no_mappings = 1;
    };
    options = {
      clipboard = "unnamed";
      colorcolumn = "80";
      expandtab = true;
      linebreak = true;
      mouse = "vi";
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      showbreak = "↳ ";
      spelllang = "en_gb";
      undodir = "/home/nick/.cache/nvim/undo"; # TODO: make generic over home
      undofile = true;
      updatetime = 750;
    };
    keymaps = [
      {
        mode = [ "n" "x" "o" ];
        key = "<leader>s";
        lua = true;
        action = "function() require('flash').jump() end";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "n" "x" "o" ];
        key = "<leader>S";
        lua = true;
        action = "function() require('flash').treesitter() end";
        options = {
          silent = true;
        };
      }
      {
        mode = "o";
        key = "r";
        lua = true;
        action = "function() require('flash').remote() end";
        options = {
          silent = true;
        };
      }
      {
        mode = [ "o" "x" ];
        key = "R";
        lua = true;
        action = "function() require('flash').treesitter_search() end";
        options = {
          silent = true;
        };
      }
      {
        mode = "c";
        key = "<C-s>";
        lua = true;
        action = "function() require('flash').toggle() end";
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
        key = "<C-m>";
        action = ":<C-U>TmuxNavigateLeft<CR>";
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
        key = "<C-i>";
        action = ":<C-U>TmuxNavigateRight<CR>";
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
      } ++ pkgs.lib.attrsets.mapAttrsToList
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
      };
    plugins = {
      bufferline = {
        enable = true;
        diagnostics = "nvim_lsp";
      };
      clangd-extensions.enable = true;
      conform-nvim = {
        enable = true;
        extraOptions = {
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
      rust-tools = {
        enable = true;
        server = {
          check.command = "clippy";
        };
      };
      flash = {
        enable = true;
      };
      lsp = {
        enable = true;
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
                    tree = 'latex',
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
              "tree"
            ];
          };
          lua-ls.enable = true;
          nixd.enable = true;
          ocamllsp.enable = true;
          pest_ls.enable = true;
          tailwindcss.enable = true;
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
        extraConfig = {
          enable_autosnippets = true;
        };
        fromLua = [{ } { paths = "~/Dropbox/nixvim-flake/snippets"; }];
      };
      mini = {
        enable = true;
        modules = {
          ai = { };
          align = { };
          bracketed = { };
          bufremove = { };
          comment = { };
          operators = { };
          pairs = { };
          splitjoin = { };
          surround = {
            mappings = {
              add = "ys";
              delete = "ds";
              find = "";
              find_left = "";
              highlight = "";
              replace = "cs";
              update_n_lines = "";
            };
          };
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
          mapping = {
            "<C-b>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<CR>" = "cmp.mapping.confirm()";
            "<Tab>" = ''
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
                { "i", "s" })
            '';
            "<S-Tab>" = ''
              cmp.mapping(
                function(fallback)
                  local luasnip = require("luasnip")
                  if luasnip.jumpable(-1) then
                    luasnip.jump(-1)
                  elseif cmp.visible() then
                    cmp.select_prev_item()
                  else
                    fallback()
                  end
                end,
                { "i", "s" })
            '';
          };
          snippet.expand = "luasnip";
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
      nvim-tree.enable = true;
      rainbow-delimiters.enable = true;
      treesitter = {
        enable = true;
        disabledLanguages = [ "latex" ];
        folding = true;
        grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars ++ [
          pkgs.tree-sitter-grammars.tree-sitter-forester
        ];
        incrementalSelection = {
          enable = true;
          keymaps = {
            initSelection = "<C-Space>";
            nodeIncremental = "<C-Space>";
            nodeDecremental = "<BS>";
          };
        };
        indent = true;
        nixvimInjections = true;
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
      tmux-navigator.enable = true;
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
      # These cmp plugins aren't be auto-enabled (no detection in extraConfigLuaPost)
      cmp-cmdline.enable = true;
      cmp-dap.enable = true;
      cmp-nvim-lsp-document-symbol.enable = true;
    };
    extraConfigLuaPre = ''
      local slow_format_filetypes = {}
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

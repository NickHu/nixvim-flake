{
  config,
  pkgs,
  ...
}: {
  config = {
    enableMan = false;
    extraPlugins = with pkgs.vimPlugins; [
      friendly-snippets
      nvim-solarized-lua
      {
        plugin = nvim-web-devicons;
        config = ''
          lua require("nvim-web-devicons").setup()
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
      vim-repeat
      vim-rhubarb
      vim-sleuth
      vim-speeddating
      vim-surround
      vim-unimpaired
      {
        plugin = telescope-ui-select-nvim;
        config = ''
          lua require("telescope").load_extension("ui-select")
        '';
      }
    ];
    colorscheme = "solarized";
    globals = {
      tex_flavor = "latex";
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
        mode = "n";
        key = "<leader>u";
        action = ":UndotreeToggle<CR>";
        options = {
          silent = true;
          noremap = true;
        };
      }
      {
        mode = "n";
        key = "<leader>e";
        action = "function () require('telescope.builtin').diagnostics({ bufnr = 0}) end";
        lua = true;
        options = {
          silent = config.plugins.telescope.keymapsSilent;
        };
      }
  ];
    plugins = {
      bufferline = {
        enable = true;
        diagnostics = "nvim_lsp";
      };
      comment-nvim.enable = true;
      copilot-lua = {
        enable = true;
        filetypes = {
          "*" = true;
        };
        suggestion = {
          autoTrigger = true;
          keymap.accept = "<C-l>";
        };
      };
      fidget.enable = true;
      fugitive.enable = true;
      gitsigns.enable = true;
      indent-blankline.enable = true;
      rust-tools = {
        enable = true;
        server = {
          check.command = "clippy";
        };
      };
      lsp = {
        enable = true;
        servers = {
          ltex = {
            enable = true;
            settings.language = "en-GB";
          };
          nil_ls.enable = true;
          pest_ls.enable = true;
          texlab = {
            enable = true;
            extraOptions.settings.texlab = {
              build = {
                args = [
                  "-pdf"
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
            "<M-e>" = "open_float";
            "<M-q>" = "setloclist";
            "[d" = "goto_prev";
            "]d" = "goto_next";
          };
          lspBuf = {
            "<M-]>" = "definition";
            "<M-f>" = "format";
            "<M-k>" = "signature_help";
            "<M-l>" = "code_action";
            "<M-r>" = "rename";
            "<M-w>a" = "add_workspace_folder";
            "<M-w>d" = "remove_workspace_folder";
            "K" = "hover";
            "g+" = "outgoing_calls";
            "g-" = "incoming_calls";
            "gD" = "document_symbol";
            "gW" = "workspace_symbol";
            "gd" = "declaration";
            "gi" = "implementation";
            "gr" = "references";
            "gt" = "type_definition";
          };
        };
      };
      lsp-format.enable = true;
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
      lualine = {
        enable = true;
        extensions = [
          "fzf"
          "nvim-dap-ui"
          "nvim-tree"
          "quickfix"
          "symbols-outline"
        ];
        sections = {
          lualine_c = [
            {
              name = "filename";
              extraConfig = {
                path = 1;
              };
            }
          ];
        };
      };
      luasnip = {
        enable = true;
        fromVscode = [{}];
      };
      markdown-preview.enable = true;
      nvim-autopairs = {
        enable = true;
        checkTs = true;
      };
      nvim-cmp = {
        enable = true;
        mappingPresets = ["insert" "cmdline"];
        mapping = {
          "<C-b>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<Tab>" = {
            modes = ["i" "s"];
            action = ''
              function(fallback)
                local has_words_before = function()
                  unpack = unpack or table.unpack
                  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
                end
                local luasnip = require("luasnip")
                if cmp.visible() then
                  cmp.select_next_item()
                elseif luasnip.expand_or_locally_jumpable() then
                  luasnip.expand_or_jump()
                elseif has_words_before() then
                  cmp.complete()
                else
                  fallback()
                end
              end
            '';
          };
          "<S-Tab>" = {
            modes = ["i" "s"];
            action = ''
              function(fallback)
                local luasnip = require("luasnip")
                if cmp.visible() then
                  cmp.select_prev_item()
                elseif luasnip.jumpable(-1) then
                  luasnip.jump(-1)
                else
                  fallback()
                end
              end
            '';
          };
        };
        snippet.expand = "luasnip";
        sources = [
          {
            name = "nvim_lsp";
            groupIndex = 1;
          }
          {
            name = "nvim_lsp_signature_help";
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
      nvim-colorizer.enable = true;
      nvim-tree.enable = true;
      rainbow-delimiters.enable = true;
      treesitter = {
        enable = true;
        folding = true;
        incrementalSelection.enable = true;
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
          "<leader>E" = "diagnostics";
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
        extraConfig = {
          compiler_latexmk = {
            aux_dir = "build";
            out_dir = "build";
          };
          view_method = "zathura";
          view_use_temp_files = 2;
        };
      };
      # These cmp plugins aren't be auto-enabled (no detection in extraConfigLuaPost)
      cmp-cmdline.enable = true;
      cmp-dap.enable = true;
      cmp-nvim-lsp-document-symbol.enable = true;
    };
    extraConfigLuaPost = ''
      local cmp = require("cmp")
      cmp.setup.cmdline('/', {
        sources = cmp.config.sources({
          { name = 'nvim_lsp_document_symbol' }
        }, {
          { name = 'buffer' }
        })
      })
      cmp.setup.cmdline(':', {
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline' }
        })
      })
      cmp.setup.filetype({ "dap-repl", "dapui_watches" }, {
        sources = {
          { name = "dap" },
        },
      })
    '';
  };
}

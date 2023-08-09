{ pkgs, ... }:
{
  config = {
    extraPlugins = with pkgs.vimPlugins; [
      friendly-snippets
      nvim-solarized-lua
      vim-unimpaired
    ];
    colorscheme = "solarized";
    options = {
      colorcolumn = "80";
      expandtab = true;
      linebreak = true;
      mouse = "vi";
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      showbreak = "↳ ";
      updatetime = 750;
    };
    plugins = {
      bufferline.enable = true;
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
      lualine.enable = true;
      lsp = {
        enable = true;
      };
      luasnip = {
        enable = true;
        fromVscode = [{ }];
      };
      markdown-preview.enable = true;
      nvim-cmp = {
        enable = true;
        mappingPresets = [ "insert" "cmdline" ];
        mapping = {
          "<C-b>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<Tab>" = {
            modes = [ "i" "s" ];
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
            modes = [ "i" "s" ];
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
          { name = "nvim_lsp"; groupIndex = 1; }
          { name = "nvim_lsp_signature_help"; groupIndex = 1; }
          { name = "luasnip"; groupIndex = 1; }
          { name = "calc"; groupIndex = 1; }
          { name = "path"; groupIndex = 1; }
          { name = "buffer"; groupIndex = 2; }
          { name = "treesitter"; groupIndex = 2; }
          { name = "cmp_pandoc"; groupIndex = 1; }
          { name = "spell"; groupIndex = 1; }
          { name = "latex_symbols"; groupIndex = 1; }
        ];
      };
      treesitter = {
        enable = true;
        folding = true;
        incrementalSelection.enable = true;
        indent = true;
        nixvimInjections = true;
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

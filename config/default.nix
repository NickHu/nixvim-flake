{ pkgs, ... }:
{
  config = {
    extraPlugins = with pkgs.vimPlugins; [
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
                if cmp.visible() then
                  cmp.select_next_item()
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
                if cmp.visible() then
                  cmp.select_prev_item()
                else
                  fallback()
                end
              end
            '';
          };
        };
        sources = [
          { name = "nvim_lsp"; groupIndex = 1; }
          { name = "nvim_lsp_signature_help"; groupIndex = 1; }
          { name = "calc"; groupIndex = 1; }
          { name = "path"; groupIndex = 1; }
          { name = "buffer"; groupIndex = 2; }
          { name = "cmp_pandoc"; groupIndex = 1; }
          { name = "spell"; groupIndex = 1; }
          { name = "latex_symbols"; groupIndex = 1; }
        ];
      };
    };
  };
}

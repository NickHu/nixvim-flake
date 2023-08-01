{ pkgs, ... }:
{
  config = {
    extraPlugins = with pkgs.vimPlugins; [ nvim-solarized-lua ];
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
      markdown-preview.enable = true;
    };
  };
}

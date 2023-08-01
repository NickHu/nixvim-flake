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
      lualine.enable = true;
    };
  };
}

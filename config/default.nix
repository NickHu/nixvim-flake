{
  lib,
  pkgs,
  calendar,
  ...
}:
{
  config =
    let
      latexmkArgs = [
        "-shell-escape"
        "-verbose"
        "-file-line-error"
        "-synctex=1"
        "-interaction=nonstopmode"
      ];
    in
    {
      files = {
        "ftplugin/agda.lua" = {
          autoCmd = [
            {
              event = [
                "QuitPre"
              ];
              command = ":CornelisCloseInfoWindows";
            }
          ];
          keymaps = [
            {
              key = "<leader>l";
              action = ":CornelisLoad<CR>";
            }
            {
              key = "<leader>r";
              action = ":CornelisRefine<CR>";
            }
            {
              key = "<leader>d";
              action = ":CornelisMakeCase<CR>";
            }
            {
              key = "<leader>,";
              action = ":CornelisTypeContext<CR>";
            }
            {
              key = "<leader>.";
              action = ":CornelisTypeContextInfer<CR>";
            }
            {
              key = "<leader>n";
              action = ":CornelisSolve<CR>";
            }
            {
              key = "<leader>a";
              action = ":CornelisAuto<CR>";
            }
            {
              key = "<C-]>";
              action = ":CornelisGoToDefinition<CR>";
            }
            {
              key = "[/";
              action = ":CornelisPrevGoal<CR>";
            }
            {
              key = "]/";
              action = ":CornelisNextGoal<CR>";
            }
            {
              key = "<C-a>";
              action = ":CornelisInc<CR>";
            }
            {
              key = "<C-x>";
              action = ":CornelisDec<CR>";
            }
          ];
        };
        "ftplugin/ocaml.lua" = {
          opts = {
            formatexpr = "v:lua.require'conform'.formatexpr({ 'formatters': [ 'ocamlformat' ]})";
          };
        };
        "ftplugin/tex.lua" = {
          autoCmd = [
            {
              event = [ "BufWritePost" ];
              command = "call vimtex#toc#refresh()";
            }
          ];
          opts = {
            conceallevel = 2;
          };
        };
        "ftplugin/forester.lua" = {
          opts = {
            cindent = true;
            cinoptions = "+0";
            foldmethod = "indent";
          };
          userCommands = {
            "ForesterNew" = {
              command = lib.nixvim.mkRaw ''
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
        "ftplugin/org.lua" = {
          keymaps = [
            {
              key = "<S-CR>";
              action = "<Cmd>lua require('orgmode').action('org_mappings.meta_return')<CR>";
              mode = [ "i" ];
              options = {
                silent = true;
              };
            }
          ];
          userCommands = builtins.listToAttrs (
            map
              (x: {
                name = "Z${x}";
                value = {
                  command = lib.nixvim.mkRaw ''
                    function()
                      local seek = require('zotcite.seek')
                      seek.refs("", function(ref)
                        if not ref then return end
                        vim.api.nvim_put({ref.value.${x}}, 'c', true, true)
                      end)
                    end
                  '';
                  desc = "Insert Zotero item ${x} at cursor";
                  nargs = 0;
                };
              })
              [
                "display"
                "title"
              ]
          );

          extraConfigLua = ''
            vim.cmd("TexAbbrev")
            vim.cmd("TexAbbrevExtra")
            require('zotcite.config').init() -- zotcite is a ftplugin
          '';
        };
      };
      filetype = {
        extension = {
          tree = "forester";
        };
      };
      autoCmd = [
        {
          event = "User";
          group = "lualine_augroup";
          pattern = "LspProgressStatusUpdated";
          callback = lib.nixvim.mkRaw ''
            require("lualine").refresh
          '';
        }
        {
          event = "ModeChanged";
          pattern = "*";
          callback = lib.nixvim.mkRaw ''
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
      extraPlugins =
        let
          stripNewlines = str: builtins.replaceStrings [ "\n" ] [ "" ] str;
        in
        with pkgs.vimPlugins;
        [
          {
            plugin = lsp-progress-nvim;
            config = ''
              lua require("lsp-progress").setup()
            '';
          }
          ltex_extra-nvim
          {
            plugin = nvim-scissors;
            config = stripNewlines ''
              lua require("scissors").setup({
                snippetDir = "~/Dropbox/nixvim-flake/snippets",
              })
            '';
          }
          {
            plugin = org-roam-nvim;
            config = stripNewlines ''
              lua require("org-roam").setup({
                directory = "~/Dropbox/roam",
                extensions = {
                  dailies = {
                    directory = "journal",
                    templates = {
                      d = {
                        description = "default",
                        template = "* %U %?",
                        target = "%<%Y-%m-%d>.org",
                      },
                    },
                  },
                },
              })
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
          {
            plugin = vim-texabbrev;
            config = ''
              let g:texabbrev_table = [
                \ ${
                  lib.strings.concatMapAttrsStringSep ",\n  \\ " (
                    n: v:
                    "['${builtins.replaceStrings [ "\\" ] [ "" ] n}', '${
                      builtins.replaceStrings [ "⎪" "|" ] [ "\\⎪" "\\|" ] v
                    }']"
                  ) (lib.filterAttrs (n: v: builtins.substring 0 1 n == "\\") vim-texabbrev.passthru.latex-unicode)
                } ]
              let g:texabbrev_table_extra = [
                \ ${
                  lib.strings.concatMapAttrsStringSep ",\n  \\ " (n: v: "['${n}', '${v}']") (
                    lib.filterAttrs (n: v: !(builtins.substring 0 1 n == "\\")) vim-texabbrev.passthru.latex-unicode
                  )
                } ]
              func s:TexAbbrevExtra()
                for pair in g:texabbrev_table_extra
                  silent execute "abbrev <buffer> ".pair[0]." ".pair[1]
                endfor
              endfun
              func s:TexUnabbrevExtra()
                for pair in g:texabbrev_table_extra
                  silent! execute "unabbrev <buffer> ".pair[0]
                endfor
              endfun
              command TexAbbrevExtra call s:TexAbbrevExtra()
              command TexUnabbrevExtra call s:TexUnabbrevExtra()
            '';
          }
          {
            plugin = treewalker-nvim;
          }
        ];
      extraPackages = with pkgs; [
        nixfmt
        ocamlPackages.ocp-indent
        ocamlformat
        sqlite # for zotcite
      ];
      lsp = {
        inlayHints.enable = true;
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
          clangd.enable = true;
          hls.enable = true;
          ltex = {
            enable = true;
            config = {
              cmd = [ "ltex-ls-plus" ];
              ltex = {
                language = "en-GB";
                additionalRules.enablePickyRules = true;
              };
            };
          };
          lua_ls.enable = true;
          nixd.enable = true;
          ocamllsp.enable = true;
          pest_ls.enable = true;
          pyright.enable = true;
          ruff.enable = true;
          texlab = {
            enable = true;
            config.texlab = {
              build = {
                args = [
                  "-pdf"
                ]
                ++ latexmkArgs
                ++ [
                  "%f"
                ];
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
        keymaps =
          let
            diagnostic = {
              "<M-e>" = "open_float";
              "<M-q>" = "setloclist";
              "[d" = "goto_prev";
              "]d" = "goto_next";
            };
            lspBuf = {
              "<M-]>" = "definition";
              "<M-f>" = "format";
              "<M-l>" = "code_action";
              "<M-r>" = "rename";
              "<M-s>" = "signature_help";
              "<M-w>a" = "add_workspace_folder";
              "<M-w>d" = "remove_workspace_folder";
              "E" = "hover";
              "g+" = "outgoing_calls";
              "g-" = "incoming_calls";
              "gD" = "document_symbol";
              "gW" = "workspace_symbol";
              "gd" = "declaration";
              "gI" = "implementation";
              "gr" = "references";
              "gt" = "type_definition";
            };
          in
          lib.mapAttrsToList (name: value: {
            key = name;
            action = lib.nixvim.mkRaw "vim.diagnostic.${value}";
          }) diagnostic
          ++ lib.mapAttrsToList (name: value: {
            key = name;
            lspBufAction = value;
          }) lspBuf;
      };
      globals = {
        tex_flavor = "latex";
        mapleader = "\\";
      };
      opts = {
        clipboard = "unnamed";
        colorcolumn = "80";
        expandtab = true;
        fillchars = "eob:\ ,fold:\ ,foldopen:,foldsep:\ ,foldclose:";
        formatexpr = "v:lua.require'conform'.formatexpr()";
        foldclose = "all";
        foldlevelstart = 99;
        foldopen = "all";
        foldtext = "";
        jumpoptions = [
          "stack"
          "view"
        ];
        linebreak = true;
        number = true;
        relativenumber = true;
        shiftwidth = 2;
        showbreak = "↳ ";
        spelllang = "en_gb";
        undodir = lib.nixvim.mkRaw "vim.fn.expand('$HOME/.cache/nvim/undo')";
        undofile = true;
        updatetime = 750;
        wrap = true;
      };
      keymaps =
        pkgs.lib.attrsets.mapAttrsToList
          (original: replacement: {
            mode = [
              "n"
              "x"
            ]
            ++ (pkgs.lib.optional (original != "i") "o")
            ++ (pkgs.lib.optional (original == "gN") "v");
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
            "H" = "I";
            "j" = "m";
            "gj" = "gm";
            "J" = "M";
            "gJ" = "gM";
          }
        ++ [
          {
            mode = [
              "n"
              "v"
            ];
            key = "<C-Up>";
            action = lib.nixvim.mkRaw "function() require('multicursor-nvim').lineAddCursor(-1) end";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "n"
              "v"
            ];
            key = "<C-Down>";
            action = lib.nixvim.mkRaw "function() require('multicursor-nvim').lineAddCursor(1) end";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "n"
              "v"
            ];
            key = "<Up>";
            action = lib.nixvim.mkRaw "function() require('multicursor-nvim').lineSkipCursor(-1) end";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "n"
              "v"
            ];
            key = "<Down>";
            action = lib.nixvim.mkRaw "function() require('multicursor-nvim').lineSkipCursor(1) end";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "n"
              "v"
            ];
            key = "<C-k>";
            action = lib.nixvim.mkRaw "function() require('multicursor-nvim').matchAddCursor(1) end";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "n"
              "v"
            ];
            key = "<leader>k";
            action = lib.nixvim.mkRaw "function() require('multicursor-nvim').matchSkipCursor(1) end";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "n"
              "v"
            ];
            key = "<C-S-k>";
            action = lib.nixvim.mkRaw "function() require('multicursor-nvim').matchAddCursor(-1) end";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "n"
              "v"
            ];
            key = "<leader>K";
            action = lib.nixvim.mkRaw "function() require('multicursor-nvim').matchSkipCursor(-1) end";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "n"
              "v"
            ];
            key = "<Left>";
            action = lib.nixvim.mkRaw "require('multicursor-nvim').nextCursor";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "n"
              "v"
            ];
            key = "<Right>";
            action = lib.nixvim.mkRaw "require('multicursor-nvim').prevCursor";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "n"
              "v"
            ];
            key = "<leader>x";
            action = lib.nixvim.mkRaw "require('multicursor-nvim').deleteCursor";
            options = {
              silent = true;
            };
          }
          {
            mode = [ "n" ];
            key = "<C-LeftMouse>";
            action = lib.nixvim.mkRaw "require('multicursor-nvim').handleMouse";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "n"
              "v"
            ];
            key = "<C-q>";
            action = lib.nixvim.mkRaw "require('multicursor-nvim').toggleCursor";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "n"
              "v"
            ];
            key = "<leader><C-q>";
            action = lib.nixvim.mkRaw "require('multicursor-nvim').duplicateCursors";
            options = {
              silent = true;
            };
          }
          {
            mode = [ "n" ];
            key = "<Esc>";
            action = lib.nixvim.mkRaw ''
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
            mode = [
              "n"
              "v"
            ];
            key = "<leader>a";
            action = lib.nixvim.mkRaw "require('multicursor-nvim').alignCursors";
            options = {
              silent = true;
            };
          }
          {
            mode = [ "v" ];
            key = "<C-s>";
            action = lib.nixvim.mkRaw "require('multicursor-nvim').splitCursors";
            options = {
              silent = true;
            };
          }
          {
            mode = [ "v" ];
            key = "H";
            action = lib.nixvim.mkRaw "insertVisualH";
            options = {
              silent = true;
            };
          }
          {
            mode = [ "v" ];
            key = "A";
            action = lib.nixvim.mkRaw "require('multicursor-nvim').appendVisual";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "n"
              "v"
            ];
            key = "<C-m>";
            action = lib.nixvim.mkRaw "require('multicursor-nvim').matchCursors";
            options = {
              silent = true;
            };
          }
          {
            mode = [ "v" ];
            key = "<leader><C-t>";
            action = lib.nixvim.mkRaw "function() require('multicursor-nvim').transposeCursors(1) end";
            options = {
              silent = true;
            };
          }
          {
            mode = [ "v" ];
            key = "<leader><C-S-t>";
            action = lib.nixvim.mkRaw "function() require('multicursor-nvim').transposeCursors(-1) end";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "n"
              "x"
              "o"
            ];
            key = "<C-j>";
            action = lib.nixvim.mkRaw "function() require('flash').jump() end";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "n"
              "x"
              "o"
            ];
            key = "<C-S-j>";
            action = lib.nixvim.mkRaw "function() require('flash').treesitter() end";
            options = {
              silent = true;
            };
          }
          {
            mode = "o";
            key = "r";
            action = lib.nixvim.mkRaw "function() require('flash').remote() end";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "o"
              "x"
            ];
            key = "R";
            action = lib.nixvim.mkRaw "function() require('flash').treesitter_search() end";
            options = {
              silent = true;
            };
          }
          {
            mode = "c";
            key = "<C-s>";
            action = lib.nixvim.mkRaw "function() require('flash').toggle() end";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "i"
              "s"
            ];
            key = "<M-n>";
            action = "<Plug>luasnip-next-choice";
            options = {
              silent = true;
            };
          }
          {
            mode = [
              "i"
              "s"
            ];
            key = "<M-p>";
            action = "<Plug>luasnip-prev-choice";
            options = {
              silent = true;
            };
          }
          {
            mode = "n";
            key = "<C-m>"; # this also maps <CR> due to legacy terminal behavior
            action = "<C-w>h";
            options = {
              silent = true;
              desc = "Focus on left window";
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
            action = "<C-w>j";
            options = {
              silent = true;
              desc = "Focus on below window";
            };
          }
          {
            mode = "n";
            key = "<C-e>";
            action = "<C-w>k";
            options = {
              silent = true;
              desc = "Focus on above window";
            };
          }
          {
            mode = "n";
            key = "<C-i>"; # this also maps <Tab> due to legacy terminal behavior
            action = "<C-w>l";
            options = {
              silent = true;
              desc = "Focus on right window";
            };
          }
          {
            mode = "n";
            key = "<M-C-m>";
            action = "<C-w><";
            options = {
              silent = true;
              desc = "Decrease window width";
            };
          }
          {
            mode = "n";
            key = "<M-C-n>";
            action = "<C-w>-";
            options = {
              silent = true;
              desc = "Decrease window height";
            };
          }
          {
            mode = "n";
            key = "<M-C-e>";
            action = "<C-w>+";
            options = {
              silent = true;
              desc = "Increase window height";
            };
          }
          {
            mode = "n";
            key = "<M-C-i>";
            action = "<C-w>>";
            options = {
              silent = true;
              desc = "Increase window width";
            };
          }
          {
            mode = "n";
            key = "<leader>bd";
            action = lib.nixvim.mkRaw "function() Snacks.bufdelete() end";
            options = {
              silent = true;
              desc = "Buffer delete";
            };
          }
          {
            mode = "n";
            key = "<leader>fe";
            action = lib.nixvim.mkRaw "function() Snacks.explorer() end";
            options = {
              silent = true;
              desc = "Snacks explorer";
            };
          }
          {
            mode = "n";
            key = "<leader>go";
            action = lib.nixvim.mkRaw "function() MiniDiff.toggle_overlay() end";
            options = {
              silent = true;
              desc = "mini.diff overlay";
            };
          }
          {
            mode = "n";
            key = "<leader>fm";
            action = lib.nixvim.mkRaw "function() MiniFiles.open() end";
            options = {
              silent = true;
              desc = "mini.files open";
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
        ]
        ++
          pkgs.lib.attrsets.mapAttrsToList
            (key: action: {
              mode = "n";
              inherit key;
              action = lib.nixvim.mkRaw ("function() Snacks.picker.pick(\"" + action + "\") end");
              options = {
                silent = true;
              };
            })
            {
              "<leader>/" = "grep";
              "<leader>b" = "buffers";
              "<leader>d" = "diagnostics";
              "<leader>f" = "files";
              "<leader>gS" = "git_stash";
              "<leader>gd" = "git_diff";
              "<leader>gs" = "git_status";
              "<leader>u" = "undo";
            }
        ++
          pkgs.lib.attrsets.mapAttrsToList
            (key: action: {
              mode = "n";
              inherit key;
              action = "<Cmd>Treewalker " + action + "<CR>";
              options = {
                silent = true;
              };
            })
            {
              "<Up>" = "Up";
              "<Down>" = "Down";
              "<Left>" = "Left";
              "<Right>" = "Right";
            };
      plugins = {
        blink-cmp = {
          enable = true;
          settings = {
            completion = {
              documentation.auto_show = true;
              ghost_text.enabled = true;
              menu = {
                auto_show = false;
                draw = {
                  columns = [
                    {
                      __unkeyed-1 = "label";
                      __unkeyed-2 = "label_description";
                      gap = 1;
                    }
                    {
                      __unkeyed-1 = "kind_icon";
                      gap = 1;
                      __unkeyed-2 = "kind";
                    }
                  ];
                  components.kind_icon = {
                    text = lib.nixvim.mkRaw ''
                      function(ctx)
                        local kind_icon, _, _ = require('mini.icons').get('lsp', ctx.kind)
                        return kind_icon
                      end
                    '';
                    highlight = lib.nixvim.mkRaw ''
                      function(ctx)
                        local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
                        return hl
                      end
                    '';
                  };
                };
              };
              list.selection.preselect = lib.nixvim.mkRaw ''
                function(ctx)
                  return not require('blink.cmp').snippet_active({ direction = 1 })
                end
              '';
            };
            keymap = {
              preset = "super-tab";
              "<Up>" = [
                "show"
                "select_prev"
                "fallback"
              ];
              "<C-p>" = [
                "show"
                "select_prev"
                "fallback_to_mappings"
              ];
              "<Down>" = [
                "show"
                "select_next"
                "fallback"
              ];
              "<C-n>" = [
                "show"
                "select_next"
                "fallback_to_mappings"
              ];
              "<CR>" = [
                (lib.nixvim.mkRaw ''
                  function(cmp)
                    if cmp.is_menu_visible() then return cmp.accept() end
                  end
                '')
                "fallback"
              ];
            };
            signature.enabled = true;
            snippets.preset = "luasnip";
            sources = {
              default = [
                "lsp"
                "path"
                "snippets"
                "buffer"
                "git"
                "copilot"
              ];
              providers = {
                copilot = {
                  async = true;
                  module = "blink-copilot";
                  name = "copilot";
                  score_offset = 100;
                };
                git = {
                  module = "blink-cmp-git";
                  name = "git";
                  enabled = lib.nixvim.mkRaw ''
                    function()
                      return vim.tbl_contains({ 'octo', 'gitcommit', 'markdown' }, vim.bo.filetype)
                    end
                  '';
                };
              };
            };
          };
        };
        blink-cmp-git.enable = true;
        blink-copilot.enable = true;
        bufferline = {
          enable = true;
          settings.options.diagnostics = "nvim_lsp";
        };
        clangd-extensions.enable = true;
        colorizer.enable = true;
        conform-nvim = {
          enable = true;
          settings = {
            formatters_by_ft = {
              ocaml = [
                "ocp-indent"
                "ocamlformat"
              ];
            };
            default_format_opts.lsp_format = "fallback";
            format_after_save = lib.nixvim.mkRaw ''
              function(bufnr)
                -- Disable with a global or buffer-local variable
                if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                  return
                end
                if not slow_format_filetypes[vim.bo[bufnr].filetype] then
                  return
                end
                return { lsp_format = "fallback" }
              end
            '';
            format_on_save = lib.nixvim.mkRaw ''
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
                return { timeout_ms = 200, lsp_format = "fallback" }, on_format
              end
            '';
          };
        };
        copilot-chat.enable = true;
        copilot-lua = {
          enable = true;
          settings = {
            filetypes = {
              "*" = true;
            };
            panel.enabled = false;
            suggestions.enabled = false;
          };
        };
        cornelis = {
          enable = true;
          settings = {
            agda_prefix = "<C-k>";
          };
        };
        fugitive.enable = true;
        gitsigns.enable = true;
        rustaceanvim = {
          enable = true;
          settings = {
            server.default_settings."rust-analyzer" = {
              files.excludeDirs = [ ".direnv" ];
            };
            tools = {
              enable_clippy = true;
            };
          };
        };
        flash = {
          enable = true;
          settings.modes.search.enabled = true;
        };
        lualine = {
          enable = true;
          settings = {
            extensions = [
              "fugitive"
              "fzf"
              "nvim-dap-ui"
              "quickfix"
            ];
            sections = {
              lualine_c = [
                {
                  __unkeyed-1 = "filename";
                  path = 1;
                }
                (lib.nixvim.mkRaw "require('lsp-progress').progress")
              ];
            };
          };
        };
        luasnip = {
          enable = true;
          settings = {
            enable_autosnippets = true;
            store_selection_keys = "<Tab>";
          };
          fromLua = [
            { }
            { paths = "~/Dropbox/nixvim-flake/snippets"; }
          ];
          fromVscode = [
            { }
            { paths = "~/Dropbox/nixvim-flake/snippets"; }
          ];
        };
        mini = {
          enable = true;
          mockDevIcons = true;
          modules = {
            ai = {
              custom_textobjects =
                lib.mapAttrs
                  (
                    name: value:
                    lib.nixvim.mkRaw ''
                      require('mini.ai').gen_spec.treesitter({ a = '@${value}.outer', i = '@${value}.inner' })
                    ''
                  )
                  {
                    C = "call";
                    c = "comment";
                    f = "function";
                    s = "statement";
                  };
            };
            align = { };
            basics = {
              options = {
                basic = true;
                extra_ui = true;
              };
              autocommands = {
                basic = true;
              };
            };
            bracketed = { };
            diff = { };
            files = {
              mappings = {
                go_in = "i";
                go_in_plus = "I";
                go_out = "m";
                go_out_plus = "M";
                mark_set = "j";
              };
            };
            icons = { };
            operators = { };
            pairs = { };
            sessions = { };
            splitjoin = { };
            starter = { };
            trailspace = { };
          };
        };
        orgmode = {
          enable = true;
          settings =
            let
              orgmode-google-fuse-mount = "~/.local/state/orgmode-google-fuse/google";
            in
            {
              org_agenda_files = [
                "${orgmode-google-fuse-mount}/**/*"
              ];
              org_default_notes_file = "~/Dropbox/roam/refile.org";
              org_capture_templates = {
                c = {
                  description = "Google Calendar";
                  template = ''
                    * %?
                    %^T--%^T
                  '';
                  target = "${orgmode-google-fuse-mount}/calendars/${calendar}.org";
                };
                t = {
                  description = "Google Task (inbox)";
                  template = ''
                    * TODO %?
                  '';
                  target = "${orgmode-google-fuse-mount}/tasks/Inbox.org";
                };
              };
              org_startup_indented = true;
              ui.input.use_vim_ui = true;
            };
        };
        rainbow-delimiters.enable = true;
        snacks = {
          enable = true;
          settings = {
            bigfile.enabled = true;
            bufdelete.enabled = true;
            explorer.enabled = true;
            image = {
              enabled = true;
              math.latex.tpl = ''
                \documentclass[preview,border=0pt,varwidth,12pt]{standalone}
                \usepackage{''${packages}}
                ''${header}
                \begin{document}
                { \''${font_size} \selectfont
                  \color[HTML]{''${color}}
                ''${content}}
                \end{document}
              '';
            };
            indent.enabled = true;
            input.enabled = true;
            notifier.enabled = true;
            picker.enabled = true;
            profiler.enabled = true;
            scope.enabled = true;
            # statuscolumn.enabled = true;
            words.enabled = true;
          };
        };
        vim-surround.enable = true;
        treesitter = {
          enable = true;
          grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars ++ [
            pkgs.tree-sitter-grammars.tree-sitter-forester
          ];
          folding.enable = true;
          highlight.enable = true;
          indent.enable = true;
        };
        treesitter-context = {
          enable = true;
          settings.max_lines = 3;
        };
        treesitter-textobjects = {
          enable = true;
        };
        typescript-tools.enable = true;
        vim-matchup = {
          enable = true;
          settings = {
            surround_enabled = 1;
            transmute_enabled = 1;
            treesitter.enable = true;
          };
        };
        which-key.enable = true;
        texpresso.enable = true;
        vimtex = {
          enable = true;
          settings = {
            compiler_latexmk = {
              options = latexmkArgs;
            };
            fold_enabled = 1;
            format_enabled = 1;
            view_method = "zathura_simple";
            view_use_temp_files = true;
            view_zathura_use_synctex = lib.nixvim.mkRaw ''
              not(vim.fn.has("mac") == 1)
            '';
            quickfix_open_on_warning = 0;
            syntax_conceal = {
              greek = 0;
              math_bounds = 0;
              math_delimiters = 0;
              math_fracs = 0;
              math_super_sub = 0;
              math_symbols = 0;
            };
          };
          texlivePackage = null; # don't install texlive at all
        };
        zotcite = {
          enable = true;
          settings = {
            filetypes = [
              "tex"
              "org"
            ];
          };
        };
      };
      extraConfigLuaPre = ''
        -- profiling
        if vim.env.PROF then
          require("snacks.profiler").startup({
            startup = { },
          })
        end
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

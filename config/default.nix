{
  pkgs,
  helpers,
  ...
}:
{
  config = {
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
          plugin = tex2uni-nvim;
          config = ''
            lua require("tex2uni").setup({ft = {"*.org"}})
          '';
        }
        {
          plugin = treewalker-nvim;
        }
      ];
    extraPackages = with pkgs; [
      nixfmt-rfc-style
      ocamlPackages.ocp-indent
      ocamlformat
    ];
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
      undodir = helpers.mkRaw "vim.fn.expand('$HOME/.cache/nvim/undo')";
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
          action = helpers.mkRaw "function() require('multicursor-nvim').lineAddCursor(-1) end";
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
          action = helpers.mkRaw "function() require('multicursor-nvim').lineAddCursor(1) end";
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
          action = helpers.mkRaw "function() require('multicursor-nvim').lineSkipCursor(-1) end";
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
          action = helpers.mkRaw "function() require('multicursor-nvim').lineSkipCursor(1) end";
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
          action = helpers.mkRaw "function() require('multicursor-nvim').matchAddCursor(1) end";
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
          action = helpers.mkRaw "function() require('multicursor-nvim').matchSkipCursor(1) end";
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
          action = helpers.mkRaw "function() require('multicursor-nvim').matchAddCursor(-1) end";
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
          action = helpers.mkRaw "function() require('multicursor-nvim').matchSkipCursor(-1) end";
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
          action = helpers.mkRaw "require('multicursor-nvim').nextCursor";
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
          action = helpers.mkRaw "require('multicursor-nvim').prevCursor";
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
          mode = [
            "n"
            "v"
          ];
          key = "<C-q>";
          action = helpers.mkRaw "require('multicursor-nvim').toggleCursor";
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
          mode = [
            "n"
            "v"
          ];
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
          mode = [
            "n"
            "v"
          ];
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
          mode = [
            "n"
            "x"
            "o"
          ];
          key = "<C-j>";
          action = helpers.mkRaw "function() require('flash').jump() end";
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
          mode = [
            "o"
            "x"
          ];
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
          action = helpers.mkRaw "function() Snacks.bufdelete() end";
          options = {
            silent = true;
            desc = "Buffer delete";
          };
        }
        {
          mode = "n";
          key = "<leader>fe";
          action = helpers.mkRaw "function() Snacks.explorer() end";
          options = {
            silent = true;
            desc = "Snacks explorer";
          };
        }
        {
          mode = "n";
          key = "<leader>go";
          action = helpers.mkRaw "function() MiniDiff.toggle_overlay() end";
          options = {
            silent = true;
            desc = "mini.diff overlay";
          };
        }
        {
          mode = "n";
          key = "<leader>fm";
          action = helpers.mkRaw "function() MiniFiles.open() end";
          options = {
            silent = true;
            desc = "mini.files open";
          };
        }
        {
          mode = "n";
          key = "<leader>ojo";
          action = "<Cmd>OrgJournal<CR>";
          options = {
            silent = true;
            desc = "open journal (today)";
          };
        }
        {
          mode = "n";
          key = "<leader>ojp";
          action = "<Cmd>OrgJournalPrev<CR>";
          options = {
            silent = true;
            desc = "open journal (yesterday)";
          };
        }
        {
          mode = "n";
          key = "<leader>ojn";
          action = "<Cmd>OrgJournalNext<CR>";
          options = {
            silent = true;
            desc = "open journal (tomorrow)";
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
            action = helpers.mkRaw ("function() Snacks.picker.pick(\"" + action + "\") end");
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
    plugins =
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
                    text = helpers.mkRaw ''
                      function(ctx)
                        local kind_icon, _, _ = require('mini.icons').get('lsp', ctx.kind)
                        return kind_icon
                      end
                    '';
                    highlight = helpers.mkRaw ''
                      function(ctx)
                        local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
                        return hl
                      end
                    '';
                  };
                };
              };
              list.selection.preselect = helpers.mkRaw ''
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
                (helpers.mkRaw ''
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
                  enabled = helpers.mkRaw ''
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
            format_after_save = helpers.mkRaw ''
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
            hls = {
              enable = true;
              installGhc = false;
            };
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
            lua_ls.enable = true;
            nixd.enable = true;
            ocamllsp.enable = true;
            ocamllsp.package = null;
            pest_ls.enable = true;
            pyright.enable = true;
            ruff.enable = true;
            tailwindcss.enable = true;
            svelte.enable = true;
            texlab = {
              enable = true;
              extraOptions.settings.texlab = {
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
              "<M-l>" = "code_action";
              "<M-r>" = "rename";
              "<M-w>a" = "add_workspace_folder";
              "<M-w>d" = "remove_workspace_folder";
              "E" = "hover";
              "g+" = "outgoing_calls";
              "g-" = "incoming_calls";
              "gD" = "document_symbol";
              "gE" = "signature_help";
              "gW" = "workspace_symbol";
              "gd" = "declaration";
              "gI" = "implementation";
              "gr" = "references";
              "gt" = "type_definition";
            };
            silent = true;
          };
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
                (helpers.mkRaw "require('lsp-progress').progress")
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
            ai = { };
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
          settings = {
            org_agenda_files = "~/Dropbox/forest/org/**/*";
            org_default_notes_file = "~/Dropbox/forest/org/refile.org";
            org_capture_templates = {
              j = {
                description = "Journal";
                template = "** %<%H:%M> %?";
                target = "~/Dropbox/forest/org/journal/%<%Y-%m-%d>.org";
                datetree = {
                  tree_type = "custom";
                  tree = [
                    {
                      format = "%A %d/%m/%Y";
                      pattern = "^.*(%d%d)/(%d%d)/(%d%d%d%d)$";
                      order = [
                        3
                        2
                        1
                      ];
                    }
                  ];
                };
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
          folding = true;
          settings = {
            highlight = {
              enable = true;
              disable = [ "latex" ]; # use vimtex
            };
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
        treesitter-context = {
          enable = true;
          settings.max_lines = 3;
        };
        treesitter-refactor = {
          enable = true;
          settings = {
            highlightDefinitions.enable = true;
            navigation.enable = true;
            smartRename.enable = true;
          };
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
            view_zathura_use_synctex = helpers.mkRaw ''
              not(vim.fn.has("mac") == 1)
            '';
            quickfix_open_on_warning = 0;
          };
          texlivePackage = null; # don't install texlive at all
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
    userCommands =
      let
        journalDir = "~/Dropbox/forest/org/journal/";
      in
      {
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
        "OrgJournal" = {
          command = helpers.mkRaw ''
            function(opts)
              local date = os.date("%Y-%m-%d")
              local file = "${journalDir}" .. date .. ".org"
              vim.cmd('e ' .. file)
              vim.cmd('normal! G')
            end
          '';
          desc = "Open today's journal";
          nargs = 0;
        };
        "OrgJournalPrev" = {
          command = helpers.mkRaw ''
            function(opts)
              local current_file = vim.fn.expand("%:p")
              local year, month, day = current_file:match(vim.fn.expand("${journalDir}") .. "(%d%d%d%d)-(%d%d)-(%d%d).org")
              if not year or not month or not day then
                print("Current file is not a valid journal file")
                return
              end
              local date = os.date("%Y-%m-%d", os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day) }) - 24 * 60 * 60)
              local file = "${journalDir}" .. date .. ".org"
              vim.cmd('e ' .. file)
              vim.cmd('normal! G')
            end
          '';
          desc = "Open yesterday's journal";
          nargs = 0;
        };
        "OrgJournalNext" = {
          command = helpers.mkRaw ''
            function(opts)
              local current_file = vim.fn.expand("%:p")
              local year, month, day = current_file:match(vim.fn.expand("${journalDir}") .. "(%d%d%d%d)-(%d%d)-(%d%d).org")
              if not year or not month or not day then
                print("Current file is not a valid journal file")
                return
              end
              local date = os.date("%Y-%m-%d", os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day) }) + 24 * 60 * 60)
              local file = "${journalDir}" .. date .. ".org"
              vim.cmd('e ' .. file)
              vim.cmd('normal! G')
            end
          '';
          desc = "Open tomorrow's journal";
          nargs = 0;
        };
      };
  };
}

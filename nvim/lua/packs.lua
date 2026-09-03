local gh = function(x) return 'https://github.com/' .. x end

vim.pack.add({
  -- ── Core libs ───────────────────────────────────────────────────────
  { src = gh('nvim-lua/plenary.nvim')                                           }, -- plenary: required by telescope
  { src = gh('vhyrro/luarocks.nvim')                                            },
  { src = gh('nvim-tree/nvim-web-devicons')                                     },

  -- ── Editor ──────────────────────────────────────────────────────────
  { src = gh('stevearc/oil.nvim')                                               },
  { src = gh('nvim-mini/mini.nvim')                                             },
  { src = gh('jake-stewart/multicursor.nvim')                                   },
  { src = gh('hat0uma/csvview.nvim')                                            },
  { src = gh('chentoast/marks.nvim')                                            },

  -- ── UI ──────────────────────────────────────────────────────────────
  { src = gh('folke/snacks.nvim')                                               },
  { src = gh('folke/which-key.nvim')                                            },
  { src = gh('lewis6991/gitsigns.nvim')                                         },
  { src = gh('karb94/neoscroll.nvim')                                           },
  { src = gh('lukas-reineke/indent-blankline.nvim')                             },
  { src = gh('brenoprata10/nvim-highlight-colors')                              },
  { src = gh('MeanderingProgrammer/render-markdown.nvim')                       },
  { src = gh('folke/todo-comments.nvim')                                        },

  -- ── Completion ──────────────────────────────────────────────────────
  { src = gh('saghen/blink.cmp'),    version = vim.version.range('*')           },

  -- ── Treesitter ──────────────────────────────────────────────────────
  { src = gh("nvim-treesitter/nvim-treesitter")                                 },
  { src = gh("nvim-treesitter/nvim-treesitter-textobjects")                     },

  -- ── Telescope ───────────────────────────────────────────────────────
  { src = gh('nvim-telescope/telescope-file-browser.nvim')                      },
  { src = gh('nvim-telescope/telescope-media-files.nvim')                       },
  { src = gh('nvim-telescope/telescope.nvim')                                   },

  -- ── LSP ─────────────────────────────────────────────────────────────
  { src = gh("williamboman/mason.nvim")                                         },
  { src = gh("williamboman/mason-lspconfig.nvim")                               },
  { src = gh("p00f/clangd_extensions.nvim")                                     },
  { src = gh('folke/lazydev.nvim')                                              },
  { src = gh('neovim/nvim-lspconfig')                                           },

  -- ── Colorschemes ────────────────────────────────────────────────────
  { src = gh('rebelot/kanagawa.nvim')                                           },
  { src = gh('ellisonleao/gruvbox.nvim')                                        },
  { src = gh('mellow-theme/mellow.nvim')                                        },
  { src = gh('navarasu/onedark.nvim')                                           },
  { src = gh('gbprod/nord.nvim')                                                },
})

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
      vim.schedule(function() vim.cmd("TSUpdate") end)
    end
  end,
})

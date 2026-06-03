local function full_url(pack_list)
  local result = {}
  for _, p in ipairs(pack_list) do
    local pack_data = {
      url = "https://github.com/" .. p[1],
      version = p.version or ''
    }
    table.insert(result, pack_data)
  end
  return result
end

local gh = function(x) return 'https://github.com/' .. x end

vim.pack.add({
  { src = gh('vhyrro/luarocks.nvim')                                            },
  { src = gh('nvim-tree/nvim-web-devicons')                                     },
  { src = gh('stevearc/oil.nvim')                                               },
  { src = gh('nvim-mini/mini.nvim'), version = '*'                              },
  { src = gh('folke/snacks.nvim')                                               },
  { src = gh('saghen/blink.cmp'),    version = vim.version.range('*')           },
  { src = gh("nvim-treesitter/nvim-treesitter")                                 },
  { src = gh("nvim-treesitter/nvim-treesitter-textobjects")                     },
  { src = gh('folke/todo-comments.nvim')                                        },
  { src = gh('MeanderingProgrammer/render-markdown.nvim')                       },
  { src = gh('jake-stewart/multicursor.nvim')                                   },
  { src = gh('folke/which-key.nvim')                                            },
  { src = gh('nvim-lua/plenary.nvim')                                           },
  { src = gh('nvim-telescope/telescope-file-browser.nvim')                      },
  { src = gh('nvim-telescope/telescope-media-files.nvim')                       },
  { src = gh('nvim-telescope/telescope.nvim')                                   },
  { src = gh("williamboman/mason.nvim")                                         },
  { src = gh("williamboman/mason-lspconfig.nvim")                               },
  { src = gh("p00f/clangd_extensions.nvim")                                     },
  { src = gh('folke/lazydev.nvim')                                              },
  { src = gh('neovim/nvim-lspconfig')                                           },
  { src = gh('rebelot/kanagawa.nvim')                                           },
  { src = gh('ellisonleao/gruvbox.nvim')                                        },
  { src = gh('mellow-theme/mellow.nvim')                                        },
  { src = gh('navarasu/onedark.nvim')                                           },
  { src = gh('gbprod/nord.nvim')                                                },
  { src = gh('lewis6991/gitsigns.nvim')                                         },
  { src = gh('hat0uma/csvview.nvim')                                            },
  { src = gh('chentoast/marks.nvim')                                            },
  { src = gh('karb94/neoscroll.nvim')                                           },
  { src = gh('lukas-reineke/indent-blankline.nvim')                             },
  { src = gh('brenoprata10/nvim-highlight-colors')                              },
})

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
      if not ev.data.active then vim.cmd.packadd("nvim-treesitter") end
      vim.cmd("TSUpdate")
    end
    if name == "telescope-fzf-native.nvim" and (kind == "install" or kind == "update") then
      local path = vim.fn.stdpath("data") .. "/site/pack/nvim/opt/telescope-fzf-native.nvim"
      vim.fn.system({ "make", "-C", path })
    end
  end,
})

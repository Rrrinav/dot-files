vim.filetype.add({
  extension = {
    phos = "rust",
    phosasm = "asmh8300"
  }
})


vim.filetype.add { extension = { ebnf = 'ebnf' } }


vim.filetype.add({
  pattern = {
    [".*/hypr/.*%.conf"] = "hyprlang",
  },
  extension = {
    ebnf = "ebnf",
  },
})


vim.filetype.add({
  extension = {
    cppm = 'cpp',
    ixx = 'cpp',
    ccm = 'cpp',
  }
})

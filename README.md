# nvim-telescope-ctags-plus

Telescope extension for faster ctags jumps in large codebases.

## Features

- `jump_to_tag()` for `g]`-style jumps with Telescope picker + preview
- single-match fast path (`jump_if_single = true` by default)
- visual selection support (useful for Ruby symbols like `:foo`)
- readtags-first query with fallback to `vim.fn.taglist()`
- better default path/text visibility (`fname_width = 60`, `show_line = true`)

## Installation

### lazy.nvim

```lua
{
  "gnfisher/nvim-telescope-ctags-plus",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("telescope").setup({
      extensions = {
        ctags_plus = {
          -- optional overrides (these are the defaults):
          -- readtags_cmd = "readtags",
          -- use_readtags = true,
          -- match = "exact", -- "exact" | "prefix" | "icase" | "prefix_icase"
          -- jump_if_single = true,
          -- word_source = "visual_or_cword", -- "cword" | "visual" | "visual_or_cword"
          -- fname_width = 60,
          -- show_line = true,
        },
      },
    })
    require("telescope").load_extension("ctags_plus")
  end,
}
```

### vim-plug

```vim
Plug 'gnfisher/nvim-telescope-ctags-plus'
```

```lua
require("telescope").load_extension("ctags_plus")
```

## Usage

```vim
nnoremap g] <cmd>lua require('telescope').extensions.ctags_plus.jump_to_tag()<cr>
xnoremap g] <cmd>lua require('telescope').extensions.ctags_plus.jump_to_tag({ word_source = 'visual' })<cr>
nnoremap <leader>ft <cmd>lua require('telescope').extensions.ctags_plus.select_tag()<cr>
```

## About long path/line text in Telescope rows

Telescope rows are clipped to the picker width. To show more context:

- increase `fname_width` (for path visibility)
- keep `show_line = true` (shows more of tag definition text)
- use a wider Telescope layout for this picker

## Healthcheck

```vim
:checkhealth ctags_plus
```

## Development

```bash
make test
make lint
make check
```

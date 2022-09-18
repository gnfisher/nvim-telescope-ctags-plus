# nvim-telescope-ctags-plus

The goal of this telescope extension is to make browsing ctags in a large
project more pleasant. Currently it only adds a simple `jump_to_tag` option,
which will give you a telescope picker of all matching ctag entries with
preview. 

## Installation

### vim-plug

```
Plug 'gnfisher/nvim-telescope-ctags-plus'
```

### Telescope setup

You'll need to load the extension.

```
require('telescope').load_extension('ctags_plus')
```

And then map it to something. I replace `g]` as so:

```
nnoremap g] <cmd>lua require('telescope').extensions.ctags_plus.jump_to_tag()<cr>
```

## The future

I would like to add more functionality to this in the future, including:

- [ ] Automatically jump to the tag if there is only one possible match
- [ ] Possibly handle no matches better than an empty picker (do nothing, show
  message in the neovim footer?)
- [ ] Make the picker window look nicer (we borrow from the
  `make_entry.gen_from_ctags` function in telescope currently).

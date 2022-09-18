return require("telescope").register_extension {
  setup = function(ext_config, config)
    -- access extension config and user config
  end,
  exports = {
    jump_to_tag = require("nvim-telescope-ctags-plus").jump_to_tag
  },
}

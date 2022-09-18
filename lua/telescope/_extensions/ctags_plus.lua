return require("telescope").register_extension {
  setup = function(ext_config, config)
    -- access extension config and user config
  end,
  exports = {
    jump_to_tag = require("nvim_telescope_ctags_plus").jump_to_tag
  },
}

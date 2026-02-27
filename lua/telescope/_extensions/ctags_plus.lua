local ctags_plus = require("ctags_plus")

return require("telescope").register_extension({
  setup = function(ext_config)
    ctags_plus.setup(ext_config)
  end,
  exports = {
    jump_to_tag = ctags_plus.jump_to_tag,
    select_tag = ctags_plus.select_tag,
  },
})

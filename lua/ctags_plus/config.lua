local M = {}

local defaults = {
  readtags_cmd = "readtags",
  use_readtags = true,
  match = "exact",
  jump_if_single = true,
  word_source = "visual_or_cword",
  fname_width = 60,
  show_line = true,
}

local state = vim.deepcopy(defaults)

function M.setup(opts)
  state = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

function M.get(opts)
  return vim.tbl_deep_extend("force", vim.deepcopy(state), opts or {})
end

function M.defaults()
  return vim.deepcopy(defaults)
end

return M

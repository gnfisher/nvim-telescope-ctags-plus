local config = require("ctags_plus.config")
local jump = require("ctags_plus.jump")
local picker = require("ctags_plus.picker")
local query = require("ctags_plus.query")
local tagfiles = require("ctags_plus.tagfiles")
local word = require("ctags_plus.word")

local M = {}

local function notify(message, level)
  require("telescope.utils").notify("ctags_plus", {
    msg = message,
    level = level or "INFO",
  })
end

function M.setup(opts)
  config.setup(opts)
end

function M.jump_to_tag(opts)
  opts = config.get(opts or {})
  opts.bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

  local query_word = word.resolve(opts)
  if query_word == nil or vim.trim(query_word) == "" then
    notify("No tag query found under cursor/selection", "WARN")
    return
  end

  local resolved_tagfiles = tagfiles.resolve(opts)
  if vim.tbl_isempty(resolved_tagfiles) then
    notify("No tags file found. Create one with ctags -R", "ERROR")
    return
  end

  local entries, resolved_query, err = query.find_with_symbol_fallback(opts, resolved_tagfiles, query_word)
  if err then
    notify(err, "WARN")
  end

  if vim.tbl_isempty(entries) then
    notify(string.format("No tags found for '%s'", query_word), "INFO")
    return
  end

  if opts.jump_if_single ~= false and #entries == 1 then
    jump.apply(entries[1])
    return
  end

  picker.open(opts, entries, opts.prompt_title or ("Tags for: " .. resolved_query))
end

function M.select_tag(opts)
  opts = opts or {}

  vim.ui.input({
    prompt = "Tag > ",
    default = opts.default_text or "",
  }, function(input)
    if input == nil then
      return
    end

    local value = vim.trim(input)
    if value == "" then
      return
    end

    M.jump_to_tag(vim.tbl_extend("force", opts, { word = value }))
  end)
end

return M

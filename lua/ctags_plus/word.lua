local M = {}

local visual_modes = {
  v = true,
  V = true,
  ["\22"] = true,
}

local function get_visual_selection(bufnr)
  local mode = vim.api.nvim_get_mode().mode
  if not visual_modes[mode] then
    return nil
  end

  local start_mark = vim.api.nvim_buf_get_mark(bufnr, "<")
  local end_mark = vim.api.nvim_buf_get_mark(bufnr, ">")
  if start_mark[1] == 0 or end_mark[1] == 0 then
    return nil
  end

  local srow, scol = start_mark[1] - 1, start_mark[2]
  local erow, ecol = end_mark[1] - 1, end_mark[2]

  if srow > erow or (srow == erow and scol > ecol) then
    srow, erow = erow, srow
    scol, ecol = ecol, scol
  end

  local lines = vim.api.nvim_buf_get_text(bufnr, srow, scol, erow, ecol + 1, {})
  local text = vim.trim(table.concat(lines, "\n"))
  if text == "" then
    return nil
  end

  return text
end

function M.resolve(opts)
  opts = opts or {}

  if opts.word and opts.word ~= "" then
    return opts.word
  end

  local source = opts.word_source or "visual_or_cword"
  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

  if source == "visual" then
    return get_visual_selection(bufnr) or ""
  end

  if source == "visual_or_cword" then
    return get_visual_selection(bufnr) or vim.fn.expand("<cword>")
  end

  return vim.fn.expand("<cword>")
end

function M.normalize(word)
  if word == nil then
    return ""
  end

  local normalized = vim.trim(word)
  if normalized:sub(1, 1) == ":" then
    return normalized:sub(2)
  end

  return normalized
end

return M

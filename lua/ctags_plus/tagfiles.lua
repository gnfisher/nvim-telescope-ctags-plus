local M = {}

local function as_list(value)
  if value == nil then
    return vim.fn.tagfiles()
  end

  if type(value) == "table" then
    return value
  end

  return { value }
end

function M.resolve(opts)
  opts = opts or {}

  local raw = as_list(opts.ctags_file or opts.tagfiles)
  local resolved = {}
  local seen = {}

  for _, tagfile in ipairs(raw) do
    local expanded = vim.fn.expand(tagfile, true)
    if expanded ~= "" and not seen[expanded] then
      seen[expanded] = true
      table.insert(resolved, expanded)
    end
  end

  return resolved
end

return M

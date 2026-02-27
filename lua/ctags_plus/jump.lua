local M = {}

local function jump_within_buffer(selection)
  if selection.scode and selection.scode ~= "" then
    local scode = selection.scode:gsub([[\/]], "/"):gsub("[%]~*]", function(char)
      return "\\" .. char
    end)
    vim.cmd("keepjumps norm! gg")
    vim.fn.search(scode)
    vim.cmd("norm! zz")
    return
  end

  vim.api.nvim_win_set_cursor(0, { selection.lnum or 1, 0 })
end

function M.post_select(selection)
  if selection == nil then
    return
  end

  jump_within_buffer(selection)
end

function M.apply(selection)
  if selection == nil then
    return
  end

  local path = selection.path or selection.filename
  if path and path ~= "" then
    vim.cmd.edit(vim.fn.fnameescape(path))
  end

  jump_within_buffer(selection)
end

return M

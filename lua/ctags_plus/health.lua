local M = {}

local function get_health_functions()
  if vim.health then
    return vim.health.start, vim.health.ok, vim.health.warn
  end

  local legacy = require("health")
  return legacy.report_start, legacy.report_ok, legacy.report_warn
end

function M.check()
  local start, ok, warn = get_health_functions()

  start("ctags_plus")

  if vim.fn.executable("readtags") == 1 then
    ok("readtags executable found")
  else
    warn("readtags executable not found; ctags_plus will fall back to vim.fn.taglist()")
  end

  local tagfiles = vim.fn.tagfiles()
  if vim.tbl_isempty(tagfiles) then
    warn("No tag files resolved from current 'tags' option")
    return
  end

  ok(string.format("Resolved %d tag file(s) from current 'tags' option", #tagfiles))
end

return M

local word = require("ctags_plus.word")

local M = {}

local function parse_lines(lines, opts)
  local make_entry = require("telescope.make_entry")
  local entry_maker = opts.entry_maker or make_entry.gen_from_ctags(opts)
  local entries = {}

  for _, line in ipairs(lines) do
    local entry = entry_maker(line)
    if entry then
      table.insert(entries, entry)
    end
  end

  return entries
end

local function normalize_cmd(cmd)
  local normalized = tostring(cmd or "1")
  normalized = normalized:gsub(';"$', "")
  normalized = normalized:gsub("\n", "")
  normalized = normalized:gsub("\t", " ")
  return normalized
end

local function escape_regex_literal(text)
  return vim.fn.escape(text, [[\.^$~[]*\/]])
end

function M.build_readtags_command(opts, tagfiles, query_word)
  opts = opts or {}

  local cmd = { opts.readtags_cmd or "readtags", "-e" }
  local match = opts.match or "exact"

  if match == "prefix" or match == "prefix_icase" then
    table.insert(cmd, "-p")
  end

  if match == "icase" or match == "prefix_icase" then
    table.insert(cmd, "-i")
  end

  for _, tagfile in ipairs(tagfiles) do
    table.insert(cmd, "-t")
    table.insert(cmd, tagfile)
  end

  table.insert(cmd, "-")
  table.insert(cmd, query_word)

  return cmd
end

function M.build_taglist_pattern(query_word, match)
  local escaped = escape_regex_literal(query_word)

  if match == "prefix" then
    return "^" .. escaped
  end

  if match == "icase" then
    return "\\c^" .. escaped .. "$"
  end

  if match == "prefix_icase" then
    return "\\c^" .. escaped
  end

  return "^" .. escaped .. "$"
end

function M.taglist_to_ctags_line(tag)
  local name = tag.name or tag.tagname or ""
  local filename = tag.filename or tag.file or ""
  local cmd = normalize_cmd(tag.cmd or tag.line or 1)
  local extension_fields = {}

  if tag.kind and tag.kind ~= "" then
    table.insert(extension_fields, "kind:" .. tag.kind)
  end

  if tag.line then
    table.insert(extension_fields, "line:" .. tostring(tag.line))
  end

  local line = string.format("%s\t%s\t%s;\"", name, filename, cmd)
  if vim.tbl_isempty(extension_fields) then
    table.insert(extension_fields, "kind:")
  end

  return line .. "\t" .. table.concat(extension_fields, "\t")
end

function M.find_with_readtags(opts, tagfiles, query_word)
  local cmd = M.build_readtags_command(opts, tagfiles, query_word)
  local output = vim.fn.systemlist(cmd)
  local shell_error = vim.v.shell_error

  if shell_error ~= 0 and not vim.tbl_isempty(output) then
    return {}, string.format("readtags failed: %s", table.concat(output, "\n"))
  end

  return parse_lines(output, opts), nil
end

function M.find_with_taglist(opts, query_word)
  local pattern = M.build_taglist_pattern(query_word, opts.match)
  local tags = vim.fn.taglist(pattern)
  local lines = {}

  for _, tag in ipairs(tags) do
    table.insert(lines, M.taglist_to_ctags_line(tag))
  end

  return parse_lines(lines, opts), nil
end

function M.find(opts, tagfiles, query_word)
  local readtags_cmd = opts.readtags_cmd or "readtags"

  if opts.use_readtags ~= false and vim.fn.executable(readtags_cmd) == 1 then
    return M.find_with_readtags(opts, tagfiles, query_word)
  end

  return M.find_with_taglist(opts, query_word)
end

function M.find_with_symbol_fallback(opts, tagfiles, query_word)
  local entries, err = M.find(opts, tagfiles, query_word)
  if not vim.tbl_isempty(entries) then
    return entries, query_word, err
  end

  local normalized = word.normalize(query_word)
  if normalized ~= "" and normalized ~= query_word then
    local fallback_entries, fallback_err = M.find(opts, tagfiles, normalized)
    return fallback_entries, normalized, fallback_err
  end

  return entries, query_word, err
end

return M

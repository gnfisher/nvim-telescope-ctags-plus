local actions = require "telescope.actions"
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local previewers = require "telescope.previewers"
local action_state = require "telescope.actions.state"
local action_set = require "telescope.actions.set"
local utils = require "telescope.utils"
local conf = require("telescope.config").values
local entry_display = require "telescope.pickers.entry_display"

local flatten = vim.tbl_flatten
local Path = require "plenary.path"

local ctags_plus = {}

local handle_entry_index = function(opts, t, k)
  local override = ((opts or {}).entry_index or {})[k]
  if not override then
    return
  end

  local val, save = override(t, opts)
  if save then
    rawset(t, k, val)
  end
  return val
end

local function gen_from_ctags(opts)
  opts = opts or {}

  local show_kind = vim.F.if_nil(opts.show_kind, true)
  local cwd = utils.path_expand(opts.cwd or vim.loop.cwd())
  local current_file = Path:new(vim.api.nvim_buf_get_name(opts.bufnr)):normalize(cwd)

  local display_items = {
    { width = 16 },
    { remaining = true },
  }

  local idx = 1
  local hidden = utils.is_path_hidden(opts)
  if not hidden then
    table.insert(display_items, idx, { width = vim.F.if_nil(opts.fname_width, 30) })
    idx = idx + 1
  end

  if opts.show_line then
    table.insert(display_items, idx, { width = 30 })
  end

  local displayer = entry_display.create {
    separator = " │ ",
    items = display_items,
  }

  local make_display = function(entry)
    local display_path, path_style = utils.transform_path(opts, entry.filename)

    local scode
    if opts.show_line then
      scode = entry.scode
    end

    if hidden then
      return displayer {
        entry.tag,
        scode,
      }
    else
      return displayer {
        {
          display_path,
          function()
            return path_style or {}
          end,
        },
        entry.tag,
        entry.kind,
        scode,
      }
    end
  end

  local mt = {}
  mt.__index = function(t, k)
    local override = handle_entry_index(opts, t, k)
    if override then
      return override
    end

    if k == "path" then
      local retpath = Path:new({ t.filename }):absolute()
      if not vim.loop.fs_access(retpath, "R") then
        retpath = t.filename
      end
      return retpath
    end
  end

  local current_file_cache = {}
  return function(tag_data)
    local tag = tag_data.name
    local file = tag_data.filename
    local scode = tag_data.cmd:sub(3, -2)
    local kind = tag_data.kind
    local line = tag_data.line

    if Path.path.sep == "\\" then
      file = string.gsub(file, "/", "\\")
    end

    if opts.only_current_file then
      if current_file_cache[file] == nil then
        current_file_cache[file] = Path:new(file):normalize(cwd) == current_file
      end

      if current_file_cache[file] == false then
        return nil
      end
    end

    local tag_entry = {}
    if opts.only_sort_tags then
      tag_entry.ordinal = tag
    else
      tag_entry.ordinal = file .. ": " .. tag
    end

    tag_entry.display = make_display
    tag_entry.scode = scode
    tag_entry.tag = tag
    tag_entry.filename = file
    tag_entry.col = 1
    tag_entry.lnum = line and tonumber(line) or 1
    if show_kind then
      tag_entry.kind = kind
    end

    return setmetatable(tag_entry, mt)
  end
end

local tag_not_found_msg = { msg = "No tags found!", level = "ERROR", }

function SplitCursorCompound()
  -- 获取当前行和光标位置
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1  -- 列从 1 开始

  -- 定义复合词模式（字母、数字、下划线、点号）
  local pattern = "[%w_%.]+"

  -- 查找复合词起始和结束位置
  local start = col
  while start > 1 do
    local char = line:sub(start-1, start-1)
    if not char:match(pattern) then break end
    start = start - 1
  end

  local finish = col
  while finish <= #line do
    local char = line:sub(finish, finish)
    if not char:match(pattern) then break end
    finish = finish + 1
  end

  -- 提取完整复合词
  local full_word = line:sub(start, finish-1)

  -- 分割为两部分（按最后一个点号分隔）
  local parts = {}
  for part in full_word:gmatch("[^.]+") do
    table.insert(parts, part)
  end

  if #parts >= 2 then
    -- 组合前缀和后缀（如 "ApkMod" 和 "isMobilePlatform"）
    local prefix = parts[#parts-1]
    local suffix = parts[#parts]
    return prefix, suffix
  else
    -- 无点号时返回整个词和空字符串
    return "", full_word
  end
end

-- 提取文件名（不带扩展名）
local function get_filename(path)
    -- 获取文件名（带扩展名）
    local filename_with_ext = path:match("[^\\/]+$")
    -- 去掉扩展名
    return filename_with_ext:gsub("%..+$", "")
end


ctags_plus.jump_to_tag = function(opts)
  -- Get the word under the cursor presently
  local mod, word = SplitCursorCompound()
  --print("****************word", mod, word)

  local tags = vim.fn.taglist(string.format("^%s$\\C", word))
  local size = #tags
  if size == 0 then
    utils.notify("gnfisher.ctags_plus", tag_not_found_msg)
    return
  end

  if mod == "" and size == 1 then
    vim.cmd.tag(word)
    return
  end
  if mod == "" then
      mod = vim.fn.expand("%:t:r")
  end
  if mod and mod ~= "" then
      -- 3. 遍历标签查找包含特定字符串的条目
      for _, tag in ipairs(tags) do
          -- 检查标签名或文件名是否包含目标字符串（按需修改条件）
          if get_filename(tag.filename) == mod then
              -- 4. 执行跳转逻辑
              vim.cmd("edit! " .. tag.filename)  -- 打开文件

              -- 处理 cmd 字段（行号或搜索命令）
              if tonumber(tag.cmd) then
                  vim.cmd("normal! " .. tag.cmd .. "G")  -- 跳转到行号
              else
                  vim.cmd(tag.cmd)  -- 执行搜索命令（如 /^pattern/）
              end

              -- 找到第一个匹配项后立即跳转（若需选择多个结果可调整）
              return
          end
      end
	  utils.notify("gnfisher.ctags_plus", tag_not_found_msg)
	  return
  end

  opts = opts or {}
  opts.bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
 
  local finder_opt = {
    results = tags,
    entry_maker = vim.F.if_nil(opts.entry_maker, gen_from_ctags(opts)),
  }

  pickers.new(opts, {
    push_cursor_on_edit = true,
    prompt_title = "Matching Tags",
    finder = finders.new_table(finder_opt),
    previewer = previewers.ctags.new(opts),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function()
        action_set.select:enhance {
          post = function()
            local selection = action_state.get_selected_entry()
            if not selection then
              return
            end

            if selection.scode then
              -- un-escape / then escape required
              -- special chars for vim.fn.search()
              -- ] ~ *
              local scode = selection.scode:gsub([[\/]], "/"):gsub("[%]~*]", function(x)
                return "\\" .. x
              end)

              vim.cmd "keepjumps norm! gg"
              vim.fn.search(scode)
              vim.cmd "norm! zz"
            else
              vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
            end
          end,
        }
      return true
    end,
  })
  :find()
end

return ctags_plus

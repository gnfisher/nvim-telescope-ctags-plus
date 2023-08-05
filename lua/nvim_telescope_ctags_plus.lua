-- The idea is to create a picker that replaces the functionality of `g[` in vim.
-- TODO: But also it should just jump to the tag if there is only a single match.

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local previewers = require "telescope.previewers"
local action_state = require "telescope.actions.state"
local action_set = require "telescope.actions.set"
local make_entry = require "telescope.make_entry"
local utils = require "telescope.utils"
local conf = require("telescope.config").values

local flatten = vim.tbl_flatten

local ctags_plus = {}

local function buf_vtext()
  local a_orig = vim.fn.getreg('a')
  local mode = vim.fn.mode()
  if mode ~= 'v' and mode ~= 'V' then
    vim.cmd([[normal! gv]])
  end
  vim.cmd([[silent! normal! "aygv]])
  local text = vim.fn.getreg('a')
  vim.fn.setreg('a', a_orig)
  return text
end

local function visual_or_cword()
  local mode = vim.fn.mode()
  if mode == 'v' or mode == 'V' then
    return buf_vtext()
  end
  return vim.fn.expand('<cword>')
end

ctags_plus.jump_to_tag = function(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
  -- Get the word under the cursor presently
  local word = visual_or_cword()
  -- Get tag file
  local tagfiles = opts.ctags_file and { opts.ctags_file } or vim.fn.tagfiles()
  for i, ctags_file in ipairs(tagfiles) do
    tagfiles[i] = vim.fn.expand(ctags_file, true)
  end
  -- Raise error if there is no tags file
  if vim.tbl_isempty(tagfiles) then
    utils.notify("gnfisher.ctags_plus", {
      msg = "No tags file found. Create one with ctags -R",
      level = "ERROR",
    })
    return
  end

  opts.entry_maker = vim.F.if_nil(opts.entry_maker, make_entry.gen_from_ctags(opts))

  pickers.new(opts, {
    prompt_title = "Tags for: " .. word,
    finder = finders.new_oneshot_job(flatten { "readtags", "-e", "-t", tagfiles, "-", word }, opts),
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

            vim.cmd "norm! gg"
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

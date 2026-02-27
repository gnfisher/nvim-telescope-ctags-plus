local action_set = require("telescope.actions.set")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")

local jump = require("ctags_plus.jump")

local M = {}

local function resolve_previewer(opts)
  if previewers.ctags and previewers.ctags.new then
    return previewers.ctags.new(opts)
  end

  return conf.qflist_previewer(opts)
end

function M.open(opts, entries, prompt_title)
  pickers
    .new(opts, {
      prompt_title = prompt_title or "Matching Tags",
      finder = finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return entry
        end,
      }),
      previewer = resolve_previewer(opts),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function()
        action_set.select:enhance({
          post = function()
            jump.post_select(action_state.get_selected_entry())
          end,
        })
        return true
      end,
    })
    :find()
end

return M

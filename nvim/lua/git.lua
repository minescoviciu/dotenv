local previewers = require('telescope.previewers')
local builtin = require('telescope.builtin')
local M = {}

local pretty_show = [[--pretty=format:%C(auto)%H%C(reset) %C(auto)%d%C(reset)%nAuthor: %C(green)%an%C(reset) <%ae>%nCommitted: %C(auto,cyan)%ar%C(reset) (%ah)%n%n    %s%n%n    %b]]

-- TODO add extra git commands based on the filename when needed
local delta_bcommits = previewers.new_termopen_previewer {
  get_command = function(entry)
    return { 'git', '-c', 'delta.side-by-side=false', 'diff', pretty_show, entry.value .. '^!', '--', entry.current_file }
  end
}

local delta = previewers.new_termopen_previewer {
  get_command = function(entry)
    return { 'git', '-c', 'delta.side-by-side=false', 'diff', pretty_show, entry.value .. '^!' }
  end
}

local show = previewers.new_termopen_previewer {
  get_command = function (entry)
    return { 'git', 'show', pretty_show, entry.value}
  end
}

local show_previewer = previewers.new_termopen_previewer {
  get_command = function (entry)
    return { 'git', '-c', 'delta.side-by-side=false', 'show',
      [[--pretty=format:%C(auto)%H%C(reset) %C(auto)%d%C(reset)%nAuthor: %an %C(green)<%ae>%C(reset)  %nCommitted: %C(blue)%ar%C(reset)%n%n%C(yellow)%s%C(reset)%n%n%b]],
      "--color", entry.value .. '^!' }
  end
}

M.git_bcommits = function(opts)
  opts = opts or {}
  opts.previewer = {
    show,
  }

  builtin.git_bcommits(opts)
end

M.git_commits = function(opts)
  opts = opts or {}
  opts.previewer = {
    show,
    -- previewers.git_commit_diff_to_head.new(opts),
  }
  opts.layout_config = {
    preview_width = 0.7
  }

  builtin.git_commits(opts)
end

return M

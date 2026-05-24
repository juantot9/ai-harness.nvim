local config = require("ai-harness.config")
local terminal = require("ai-harness.terminal")
local context = require("ai-harness.context")
local refs = require("ai-harness.refs")

local M = {}

function M.setup(opts)
  config.setup(opts)
end

M.open = terminal.open
M.toggle = terminal.toggle
M.send = terminal.send_prompt

M.send_current_file = context.send_current_file
M.send_selection = context.send_range
M.send_visible_context = context.send_visible_context
M.send_open_buffers = context.send_open_buffers
M.send_diagnostics = context.send_diagnostics
M.send_git_diff = context.send_git_diff
M.send_git_diff_staged = context.send_git_diff_staged

M.goto_reference = refs.goto_reference
M.goto_reference_under_cursor = refs.goto_reference_under_cursor

return M

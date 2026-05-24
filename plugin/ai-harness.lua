if vim.g.loaded_ai_harness == 1 then
  return
end
vim.g.loaded_ai_harness = 1

local ai = require("ai-harness")

vim.api.nvim_create_user_command("AIHarnessOpen", function(opts)
  local cmd = opts.args ~= "" and opts.args or nil
  ai.open(cmd)
end, {
  nargs = "?",
  complete = "shellcmd",
  desc = "Open an AI harness terminal",
})

vim.api.nvim_create_user_command("AIHarnessToggle", function(opts)
  local cmd = opts.args ~= "" and opts.args or nil
  ai.toggle(cmd)
end, {
  nargs = "?",
  complete = "shellcmd",
  desc = "Toggle the AI harness terminal",
})

vim.api.nvim_create_user_command("AIHarnessSendFile", function()
  ai.send_current_file()
end, {
  desc = "Send the current file to the AI harness",
})

vim.api.nvim_create_user_command("AIHarnessSendSelection", function(opts)
  ai.send_selection(opts.line1, opts.line2)
end, {
  range = true,
  desc = "Send the selected range to the AI harness",
})

vim.api.nvim_create_user_command("AIHarnessSendVisible", function()
  ai.send_visible_context()
end, {
  desc = "Send visible lines in the current window to the AI harness",
})

vim.api.nvim_create_user_command("AIHarnessSendOpenBuffers", function()
  ai.send_open_buffers()
end, {
  desc = "Send listed open buffers to the AI harness",
})

vim.api.nvim_create_user_command("AIHarnessSendDiagnostics", function()
  ai.send_diagnostics()
end, {
  desc = "Send diagnostics for the current buffer to the AI harness",
})

vim.api.nvim_create_user_command("AIHarnessSendGitDiff", function()
  ai.send_git_diff()
end, {
  desc = "Send the current git diff to the AI harness",
})

vim.api.nvim_create_user_command("AIHarnessSendGitDiffStaged", function()
  ai.send_git_diff_staged()
end, {
  desc = "Send the staged git diff to the AI harness",
})

vim.api.nvim_create_user_command("AIHarnessGotoReference", function(opts)
  local ref = opts.args ~= "" and opts.args or nil
  ai.goto_reference(ref)
end, {
  nargs = "?",
  complete = "file",
  desc = "Open a file reference from the AI harness conversation",
})

local terminal = require("ai-harness.terminal")

local M = {}

local function fenced_block(label, filetype, body)
  filetype = filetype or ""
  return table.concat({
    label,
    "",
    "```" .. filetype,
    body,
    "```",
  }, "\n")
end

local function current_path(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return "[No Name]"
  end
  return name
end

function M.send_current_file()
  local bufnr = vim.api.nvim_get_current_buf()
  if terminal.is_harness_buffer(bufnr) then
    vim.notify("Switch to a source buffer before sending a file.", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local path = current_path(bufnr)
  local filetype = vim.bo[bufnr].filetype
  local body = table.concat(lines, "\n")

  terminal.send_prompt(fenced_block("Here is the current file: " .. path, filetype, body))
end

function M.send_range(line1, line2)
  local bufnr = vim.api.nvim_get_current_buf()
  if terminal.is_harness_buffer(bufnr) then
    vim.notify("Switch to a source buffer before sending a selection.", vim.log.levels.WARN)
    return
  end

  line1 = tonumber(line1)
  line2 = tonumber(line2)
  if not line1 or not line2 then
    vim.notify("No range selected.", vim.log.levels.WARN)
    return
  end
  if line1 > line2 then
    line1, line2 = line2, line1
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, line1 - 1, line2, false)
  local path = current_path(bufnr)
  local filetype = vim.bo[bufnr].filetype
  local body = table.concat(lines, "\n")
  local label = string.format("Here is %s lines %d-%d:", path, line1, line2)

  terminal.send_prompt(fenced_block(label, filetype, body))
end

function M.send_visible_context()
  local bufnr = vim.api.nvim_get_current_buf()
  if terminal.is_harness_buffer(bufnr) then
    vim.notify("Switch to a source buffer before sending visible context.", vim.log.levels.WARN)
    return
  end

  local winid = vim.api.nvim_get_current_win()
  local line1 = vim.fn.line("w0", winid)
  local line2 = vim.fn.line("w$", winid)
  M.send_range(line1, line2)
end

function M.send_open_buffers()
  local parts = { "Here are the listed buffers I currently have open:" }

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].buflisted and not terminal.is_harness_buffer(bufnr) then
      local path = current_path(bufnr)
      local filetype = vim.bo[bufnr].filetype
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      table.insert(parts, fenced_block(path, filetype, table.concat(lines, "\n")))
    end
  end

  terminal.send_prompt(table.concat(parts, "\n\n"))
end

local function send_git_diff(args, label)
  if not terminal.is_running() then
    vim.notify("AI harness is not running. Use :AIHarnessOpen first.", vim.log.levels.ERROR)
    return
  end

  local cmd = { "git", "diff" }
  for _, arg in ipairs(args or {}) do
    table.insert(cmd, arg)
  end

  local output = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to run " .. table.concat(cmd, " ") .. ": " .. table.concat(output, "\n"), vim.log.levels.ERROR)
    return
  end

  if vim.tbl_isempty(output) then
    terminal.send_prompt(label .. " is empty.")
    return
  end

  terminal.send_prompt(fenced_block(label .. ":", "diff", table.concat(output, "\n")))
end

function M.send_git_diff()
  send_git_diff({}, "Here is the current git diff")
end

function M.send_git_diff_staged()
  send_git_diff({ "--staged" }, "Here is the staged git diff")
end

function M.send_diagnostics()
  local bufnr = vim.api.nvim_get_current_buf()
  if terminal.is_harness_buffer(bufnr) then
    vim.notify("Switch to a source buffer before sending diagnostics.", vim.log.levels.WARN)
    return
  end

  local diagnostics = vim.diagnostic.get(bufnr)
  local path = current_path(bufnr)
  if vim.tbl_isempty(diagnostics) then
    terminal.send_prompt("There are no diagnostics for " .. path .. ".")
    return
  end

  local lines = { "Here are the diagnostics for " .. path .. ":" }
  for _, diagnostic in ipairs(diagnostics) do
    local severity = vim.diagnostic.severity[diagnostic.severity] or "UNKNOWN"
    table.insert(lines, string.format(
      "- %s:%d:%d [%s] %s",
      path,
      diagnostic.lnum + 1,
      diagnostic.col + 1,
      severity,
      diagnostic.message
    ))
  end

  terminal.send_prompt(table.concat(lines, "\n"))
end

return M

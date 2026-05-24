local config = require("ai-harness.config")

local M = {}

M.state = {
  job_id = nil,
  bufnr = nil,
  winid = nil,
  cmd = nil,
}

local function is_valid_window(winid)
  return winid and vim.api.nvim_win_is_valid(winid)
end

local function is_valid_buffer(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

function M.is_running()
  if not M.state.job_id then
    return false
  end

  return vim.fn.jobwait({ M.state.job_id }, 0)[1] == -1
end

local function resolve_size(size, total)
  if type(size) == "number" and size > 0 and size < 1 then
    return math.floor(total * size)
  end
  return size
end

local function open_float(window)
  local float = window.float or {}
  local width = resolve_size(float.width or 0.8, vim.o.columns)
  local height = resolve_size(float.height or 0.8, vim.o.lines)

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  local bufnr = vim.api.nvim_create_buf(false, true)
  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = float.border or "rounded",
  })

  return winid, bufnr
end

local function open_split(window)
  local position = window.position or "right"
  local size = window.size or 0.35

  if position == "left" then
    vim.cmd("topleft vertical split")
  elseif position == "bottom" then
    vim.cmd("botright split")
  elseif position == "top" then
    vim.cmd("topleft split")
  else
    vim.cmd("botright vertical split")
  end

  if position == "left" or position == "right" then
    local width = resolve_size(size, vim.o.columns)
    if type(width) == "number" and width >= 1 then
      vim.cmd("vertical resize " .. width)
    end
    if window.full_height ~= false then
      vim.cmd(position == "left" and "wincmd H" or "wincmd L")
    end
  else
    local height = resolve_size(size, vim.o.lines)
    if type(height) == "number" and height >= 1 then
      vim.cmd("resize " .. height)
    end
  end

  return vim.api.nvim_get_current_win()
end

local function open_window()
  local window = config.options.window

  if window.type == "tab" then
    vim.cmd("tabnew")
    return vim.api.nvim_get_current_win()
  end

  if window.type == "float" then
    return open_float(window)
  end

  return open_split(window)
end

local function apply_terminal_options(bufnr)
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].filetype = "ai-harness"
end

function M.open(cmd)
  cmd = cmd or config.options.default_cmd

  if is_valid_window(M.state.winid) and is_valid_buffer(M.state.bufnr) and M.is_running() then
    vim.api.nvim_set_current_win(M.state.winid)
    vim.cmd("startinsert")
    return
  end

  local winid, float_bufnr
  if is_valid_window(M.state.winid) then
    winid = M.state.winid
    vim.api.nvim_set_current_win(winid)
  else
    winid, float_bufnr = open_window()
  end

  local bufnr = float_bufnr or vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(winid, bufnr)

  local job_id = vim.fn.termopen(cmd, {
    on_exit = function(exited_job_id)
      if M.state.job_id == exited_job_id then
        M.state.job_id = nil
      end
    end,
  })
  if job_id <= 0 then
    vim.notify("Failed to start AI harness: " .. tostring(cmd), vim.log.levels.ERROR)
    return
  end

  M.state.job_id = job_id
  M.state.bufnr = bufnr
  M.state.winid = winid
  M.state.cmd = cmd

  apply_terminal_options(bufnr)

  local refs = require("ai-harness.refs")
  refs.attach(bufnr)

  local lhs = config.options.keymaps.terminal_goto_reference
  if lhs and lhs ~= "" then
    vim.keymap.set("n", lhs, function()
      refs.goto_reference_under_cursor()
    end, { buffer = bufnr, desc = "AI Harness: goto file reference" })
  end

  vim.cmd("startinsert")
end

function M.toggle(cmd)
  if is_valid_window(M.state.winid) then
    vim.api.nvim_win_hide(M.state.winid)
    return
  end

  if is_valid_buffer(M.state.bufnr) then
    local winid = open_window()
    vim.api.nvim_win_set_buf(winid, M.state.bufnr)
    M.state.winid = winid
    vim.cmd("startinsert")
    return
  end

  M.open(cmd)
end

function M.send(text)
  if not M.is_running() then
    vim.notify("AI harness is not running. Use :AIHarnessOpen first.", vim.log.levels.ERROR)
    return false
  end

  vim.api.nvim_chan_send(M.state.job_id, text)
  return true
end

function M.send_prompt(text)
  if not text or text == "" then
    return false
  end
  return M.send(text .. "\n")
end

function M.is_harness_buffer(bufnr)
  return bufnr == M.state.bufnr
end

return M

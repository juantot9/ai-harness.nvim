local terminal = require("ai-harness.terminal")

local M = {}

local uv = vim.uv or vim.loop
local namespace = vim.api.nvim_create_namespace("ai-harness-refs")
local refresh_timers = {}

-- Reference parsing ---------------------------------------------------------

local function strip_punctuation(text)
  return text:gsub("^[`'\"(<{%[]+", ""):gsub("[`'\").,;:>%]}]+$", "")
end

local function parse_reference(text)
  if not text or text == "" then
    return nil
  end

  text = strip_punctuation(text)

  local file, line, col = text:match("^(.+):(%d+):(%d+)$")
  if file then
    return file, tonumber(line), tonumber(col)
  end

  file, line = text:match("^(.+):(%d+)$")
  if file then
    return file, tonumber(line), 1
  end

  return text, 1, 1
end

local function looks_like_path(text)
  return text:find("/", 1, true) or text:find(".", 1, true)
end

local function references_in_line(line)
  local refs = {}

  for start_col, raw_text in line:gmatch("()([%w%._%-%+/~]+:?%d*:?:?%d*)") do
    local text = strip_punctuation(raw_text)

    if text ~= "" and looks_like_path(text) then
      table.insert(refs, {
        text = text,
        start_col = start_col,
        end_col = start_col + #raw_text - 1,
      })
    end
  end

  return refs
end

local function reference_at(line, col)
  for _, ref in ipairs(references_in_line(line)) do
    if ref.start_col <= col and col <= ref.end_col then
      return ref.text
    end
  end

  return nil
end

local function reference_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1

  return reference_at(line, col) or vim.fn.expand("<cfile>")
end

-- File opening --------------------------------------------------------------

local function file_exists(path)
  return path and vim.fn.filereadable(path) == 1
end

local function resolve_file(path)
  if file_exists(path) then
    return path
  end

  local cwd_path = vim.fs.joinpath(vim.fn.getcwd(), path)
  if file_exists(cwd_path) then
    return cwd_path
  end

  return nil
end

local function target_window()
  local current = vim.api.nvim_get_current_win()

  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    if winid ~= current and not terminal.is_harness_buffer(bufnr) then
      return winid
    end
  end

  vim.cmd("leftabove vsplit")
  return vim.api.nvim_get_current_win()
end

function M.goto_reference(ref)
  ref = ref or reference_under_cursor()

  local file, line, col = parse_reference(ref)
  local resolved = resolve_file(file)

  if not resolved then
    vim.notify("No readable file reference under cursor: " .. tostring(ref), vim.log.levels.WARN)
    return
  end

  vim.api.nvim_set_current_win(target_window())
  vim.cmd.edit(vim.fn.fnameescape(resolved))

  local last_line = vim.api.nvim_buf_line_count(0)
  line = math.max(1, math.min(line or 1, last_line))
  col = math.max(1, col or 1)

  vim.api.nvim_win_set_cursor(0, { line, col - 1 })
end

function M.goto_reference_under_cursor()
  M.goto_reference(reference_under_cursor())
end

-- Highlighting --------------------------------------------------------------

local function highlight_reference(bufnr, row, ref)
  vim.api.nvim_buf_set_extmark(bufnr, namespace, row, ref.start_col - 1, {
    end_col = ref.end_col,
    hl_group = "AIHarnessReference",
  })
end

local function refresh_highlights(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for row, line in ipairs(lines) do
    for _, ref in ipairs(references_in_line(line)) do
      highlight_reference(bufnr, row - 1, ref)
    end
  end
end

local function stop_refresh_timer(bufnr)
  local timer = refresh_timers[bufnr]
  if not timer then
    return
  end

  timer:stop()
  timer:close()
  refresh_timers[bufnr] = nil
end

local function schedule_refresh(bufnr)
  if not refresh_timers[bufnr] then
    refresh_timers[bufnr] = uv.new_timer()
  end

  refresh_timers[bufnr]:stop()
  refresh_timers[bufnr]:start(150, 0, function()
    vim.schedule(function()
      refresh_highlights(bufnr)
    end)
  end)
end

-- Mouse behavior ------------------------------------------------------------

function M.open_reference_under_cursor(opts)
  opts = opts or {}

  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local ref = reference_at(line, col)

  if ref then
    M.goto_reference(ref)
    return true
  end

  if opts.insert_if_miss then
    vim.cmd("startinsert")
  end

  return false
end

local function set_mouse_keymaps(bufnr)
  local normal_click = "<LeftMouse><Cmd>lua require('ai-harness.refs').open_reference_under_cursor()<CR>"
  vim.keymap.set("n", "<LeftMouse>", normal_click, {
    buffer = bufnr,
    desc = "AI Harness: open clicked file reference",
  })

  local terminal_click = "<LeftMouse><Cmd>lua require('ai-harness.refs').open_reference_under_cursor({ insert_if_miss = true })<CR>"
  vim.keymap.set("t", "<LeftMouse>", "<C-\\><C-n>" .. terminal_click, {
    buffer = bufnr,
    desc = "AI Harness: open clicked file reference",
  })
end

-- Attachment ----------------------------------------------------------------

function M.attach(bufnr)
  vim.api.nvim_set_hl(0, "AIHarnessReference", { underline = true, default = true })

  refresh_highlights(bufnr)
  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function()
      schedule_refresh(bufnr)
    end,
    on_reload = function()
      schedule_refresh(bufnr)
    end,
    on_detach = function()
      stop_refresh_timer(bufnr)
    end,
  })

  set_mouse_keymaps(bufnr)
end

-- Test-visible helpers ------------------------------------------------------

M.parse_reference = parse_reference
M.references_in_line = references_in_line
M.reference_at = reference_at

return M

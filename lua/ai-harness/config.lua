local M = {}

M.defaults = {
  default_cmd = "pi",
  window = {
    type = "split", -- "split", "float", or "tab"
    position = "right", -- "right", "left", "bottom", or "top"
    size = 0.35,
    full_height = true,
    float = {
      width = 0.8,
      height = 0.8,
      border = "rounded",
    },
  },
  keymaps = {
    terminal_goto_reference = "gf",
  },
  highlight = {
    enabled = true,
    max_lines = 500,
    debounce_ms = 150,
  },
}

M.options = vim.deepcopy(M.defaults)

local function merge(defaults, opts)
  return vim.tbl_deep_extend("force", defaults, opts or {})
end

function M.setup(opts)
  M.options = merge(vim.deepcopy(M.defaults), opts)
end

return M

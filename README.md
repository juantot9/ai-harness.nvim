# ai-harness.nvim

Open terminal-based AI coding agents inside Neovim and send editor context to them.

This plugin intentionally starts as a small terminal wrapper. It works with tools like `pi`, `claude`, `codex`, `aider`, or any other command-line AI harness that can run in a terminal.

## Features

- Open an AI harness in a vertical split, horizontal split, tab, or floating window.
- Send the current file, visual selection/range, visible lines, open buffers, diagnostics, or git diffs.
- Highlight AI conversation file references such as `src/main.lua:42:3`.
- Jump from highlighted file references back into Neovim with `gf` or mouse click.

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "your-name/ai-harness.nvim",
  config = function()
    require("ai-harness").setup({
      default_cmd = "pi",
      window = {
        type = "vertical",
        width = 0.35,
      },
    })
  end,
}
```

For local development:

```lua
{
  dir = "~/Escritorio/repos/ai-harness.nvim",
  config = function()
    require("ai-harness").setup()
  end,
}
```

## Commands

```vim
:AIHarnessOpen [cmd]
:AIHarnessToggle [cmd]
:AIHarnessSendFile
:'<,'>AIHarnessSendSelection
:AIHarnessSendVisible
:AIHarnessSendOpenBuffers
:AIHarnessSendDiagnostics
:AIHarnessSendGitDiff
:AIHarnessSendGitDiffStaged
:AIHarnessGotoReference [file[:line[:col]]]
```

Examples:

```vim
:AIHarnessOpen pi
:AIHarnessOpen claude
:AIHarnessGotoReference lua/ai-harness/init.lua:10
```

Inside the AI terminal buffer:

- `gf` runs `AIHarnessGotoReference` for the reference under the cursor.
- Clicking a highlighted file reference opens that file location.

## Suggested keymaps

```lua
local ai = require("ai-harness")

vim.keymap.set("n", "<leader>aa", function() ai.open() end, { desc = "Open AI harness" })
vim.keymap.set("n", "<leader>at", function() ai.toggle() end, { desc = "Toggle AI harness" })
vim.keymap.set("n", "<leader>af", ai.send_current_file, { desc = "Send current file" })
vim.keymap.set("v", "<leader>as", ":AIHarnessSendSelection<CR>", { desc = "Send selection" })
vim.keymap.set("n", "<leader>av", ai.send_visible_context, { desc = "Send visible lines" })
vim.keymap.set("n", "<leader>ad", ai.send_diagnostics, { desc = "Send diagnostics" })
vim.keymap.set("n", "<leader>ag", ai.send_git_diff, { desc = "Send git diff" })
vim.keymap.set("n", "<leader>aG", ai.send_git_diff_staged, { desc = "Send staged git diff" })
```

## Configuration

Defaults:

```lua
require("ai-harness").setup({
  default_cmd = "pi",
  window = {
    type = "vertical", -- "vertical", "horizontal", "float", or "tab"
    width = 0.35,
    height = 0.35,
    float = {
      width = 0.8,
      height = 0.8,
      border = "rounded",
    },
  },
  keymaps = {
    terminal_goto_reference = "gf",
  },
})
```

## Development

Run tests with:

```bash
make test
```

## Notes

- The plugin does not implement a native AI chat UI yet. It wraps existing terminal harnesses.
- Authentication, model selection, tools, and permissions are handled by the harness command you run.
- File reference detection is intentionally simple in the first version and supports `file`, `file:line`, and `file:line:col`.

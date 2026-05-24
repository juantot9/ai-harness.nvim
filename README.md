# ai-harness.nvim

Open terminal-based AI coding agents inside Neovim and send editor context to them.

`ai-harness.nvim` is a small Neovim wrapper around command-line AI tools such as `pi`, `claude`, `codex`, `aider`, or any other interactive command that can run in a terminal.

It does not implement its own AI chat UI. Authentication, model selection, permissions, and tool execution are handled by the AI harness command you choose to run.

## Features

- Open an AI harness in a vertical split, horizontal split, tab, or floating window.
- Send useful editor context to the harness:
  - current file
  - visual selection/range
  - visible lines
  - open buffers
  - diagnostics
  - git diffs
- Highlight file references in AI output, such as `src/main.lua:42:3`.
- Jump from AI output back into Neovim with `gf` or mouse click.

## Requirements

- Neovim 0.10 or newer recommended.
- At least one terminal AI harness installed and available in `$PATH`, for example:
  - `pi`
  - `claude`
  - `codex`
  - `aider`

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "juantot9/ai-harness.nvim",
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

Use a different default harness if preferred:

```lua
require("ai-harness").setup({
  default_cmd = "claude",
})
```

## Quick start

Open the default harness:

```vim
:AIHarnessOpen
```

Open a specific command:

```vim
:AIHarnessOpen claude
:AIHarnessOpen aider
```

Send the current file:

```vim
:AIHarnessSendFile
```

Send a visual selection:

```vim
:'<,'>AIHarnessSendSelection
```

When the AI output contains a reference like this:

```text
lua/ai-harness/init.lua:10
```

Move the cursor over it and press `gf`, or click the highlighted reference.

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

Default configuration:

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
  highlight = {
    enabled = true,
    max_lines = 500,
    debounce_ms = 150,
  },
})
```

Reference highlighting is limited to recent terminal lines by default for predictable performance. `gf` and click detection still parse the current line directly.

To disable highlighting:

```lua
require("ai-harness").setup({
  highlight = {
    enabled = false,
  },
})
```

## Supported file references

The plugin recognizes simple file references in AI output:

```text
file
file:line
file:line:column
src/main.lua:42
/home/user/project/src/main.lua:42:3
```

Detection is intentionally simple and may highlight some false positives, such as URLs or version-like strings.

## Development

Clone the repository and run the tests:

```bash
git clone https://github.com/juantot9/ai-harness.nvim.git
cd ai-harness.nvim
make test
```

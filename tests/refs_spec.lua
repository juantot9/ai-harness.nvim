vim.opt.runtimepath:prepend(vim.fn.getcwd())

local refs = require("ai-harness.refs")

local function eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s\nexpected: %s\nactual:   %s", message or "assertion failed", vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local function parse_case(input, expected_file, expected_line, expected_col)
  local file, line, col = refs.parse_reference(input)
  eq(file, expected_file, "file mismatch for " .. input)
  eq(line, expected_line, "line mismatch for " .. input)
  eq(col, expected_col, "col mismatch for " .. input)
end

parse_case("src/main.lua", "src/main.lua", 1, 1)
parse_case("src/main.lua:42", "src/main.lua", 42, 1)
parse_case("src/main.lua:42:3", "src/main.lua", 42, 3)
parse_case("`src/main.lua:42`", "src/main.lua", 42, 1)
parse_case("(src/main.lua:42)", "src/main.lua", 42, 1)
parse_case("./src/main.lua:42", "./src/main.lua", 42, 1)
parse_case("/home/user/project/src/main.lua:42", "/home/user/project/src/main.lua", 42, 1)
parse_case("lua/ai-harness/init.lua:10.", "lua/ai-harness/init.lua", 10, 1)

local line = "Please edit `lua/ai-harness/init.lua:12:3`, then check README.md:8."
eq(refs.reference_at(line, line:find("init", 1, true)), "lua/ai-harness/init.lua:12:3", "embedded lua ref not found")
eq(refs.reference_at(line, line:find("README", 1, true)), "README.md:8", "embedded README ref not found")
eq(refs.reference_at(line, 1), nil, "non-reference text should not match")

local found = refs.references_in_line("Refs: ./a.lua:1 and /tmp/b.txt:2:3 and plain words")
eq(#found, 2, "should find two references")
eq(found[1].text, "./a.lua:1", "first reference mismatch")
eq(found[2].text, "/tmp/b.txt:2:3", "second reference mismatch")

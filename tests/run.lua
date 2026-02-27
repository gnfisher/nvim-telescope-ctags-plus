package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local query = require("ctags_plus.query")
local tagfiles = require("ctags_plus.tagfiles")
local word = require("ctags_plus.word")

local failures = {}
local test_names = {}
local tests = {}

local function format(value)
  return vim.inspect(value)
end

local function assert_equal(actual, expected)
  if vim.deep_equal(actual, expected) then
    return
  end

  error(string.format("expected %s, got %s", format(expected), format(actual)))
end

local function test(name, fn)
  table.insert(test_names, name)
  tests[name] = fn
end

test("build_readtags_command repeats -t for each tag file", function()
  local cmd = query.build_readtags_command({
    readtags_cmd = "readtags",
    match = "prefix_icase",
  }, { "./tags", "/tmp/tags" }, "User")

  assert_equal(cmd, {
    "readtags",
    "-e",
    "-p",
    "-i",
    "-t",
    "./tags",
    "-t",
    "/tmp/tags",
    "-",
    "User",
  })
end)

test("build_taglist_pattern supports exact and icase", function()
  assert_equal(query.build_taglist_pattern("Foo.Bar", "exact"), "^Foo\\.Bar$")
  assert_equal(query.build_taglist_pattern("Foo.Bar", "icase"), "\\c^Foo\\.Bar$")
end)

test("taglist_to_ctags_line strips duplicate trailer in cmd", function()
  local line = query.taglist_to_ctags_line({
    name = "foo",
    filename = "lib/example.rb",
    cmd = "/^def foo$/;\"",
    kind = "f",
    line = 12,
  })

  assert_equal(line, "foo\tlib/example.rb\t/^def foo$/;\"\tkind:f\tline:12")
end)

test("taglist_to_ctags_line always includes extension fields", function()
  local line = query.taglist_to_ctags_line({
    name = "foo",
    filename = "lib/example.rb",
    cmd = "123",
  })

  assert_equal(line, "foo\tlib/example.rb\t123;\"\tkind:")
end)

test("tagfiles.resolve deduplicates ctags_file values", function()
  local resolved = tagfiles.resolve({
    ctags_file = {
      "./tags",
      "./tags",
      "./tmp/../tags",
    },
  })

  assert_equal(#resolved, 2)
end)

test("word.normalize removes ruby symbol prefix", function()
  assert_equal(word.normalize(":hello"), "hello")
  assert_equal(word.normalize("hello"), "hello")
end)

table.sort(test_names)

for _, name in ipairs(test_names) do
  local ok, err = pcall(tests[name])
  if ok then
    print("PASS: " .. name)
  else
    table.insert(failures, string.format("FAIL: %s\n%s", name, err))
  end
end

if #failures > 0 then
  print("\nTest failures:")
  for _, failure in ipairs(failures) do
    print(failure)
  end
  os.exit(1)
end

print(string.format("\nAll %d tests passed.", #test_names))

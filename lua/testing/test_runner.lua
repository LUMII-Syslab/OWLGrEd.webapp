module(..., package.seeall)

local report = require("reporter.report")
local lfs = require 'lfs'
-- local luacov
require 'busted'

local pathseparator = _G.package.config:sub(1,1)
local defaultoutput = "testing.tda_test_status_output"
local defaultpattern = '_spec.lua$'
local ansicolors = require "ansicolors"

local function sub_dir(dir)
  local dirs = {dir}
  local function yieldtree()
    dir = table.remove(dirs, #dirs)
    if dir then
      for entry in lfs.dir(dir) do
        if entry ~= "." and entry ~= ".." and entry:sub(1, 1) ~= "." then
          entry=dir..pathseparator..entry
          local attr=lfs.attributes(entry)
          if attr.mode == "directory" then
            table.insert(dirs, entry)
          else
            coroutine.yield(entry,attr)
          end
        end
      end

      return yieldtree()
    end
  end
  return coroutine.wrap(yieldtree)
end

local split = function(string, sep)
  local sep, fields = sep or ".", {}
  local pattern = ("([^%s]+)"):format(sep)
  string:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end



local function default_spec_dir_paths()
  local result = {}

  local function add_path_if_exists(path)
    path = path .. "\\spec"
    if lfs.attributes(path, "mode") then
      table.insert(result, path)
    end
  end

  add_path_if_exists(tda.GetRuntimePath())
  add_path_if_exists(tda.GetToolPath())
  add_path_if_exists(tda.GetProjectPath())


  -- FIXME
  -- add plugin spec directories to default list

  return result
end




-- <full name> PENDING
--    at <path to file>, line <line number>
-- ...
--
-- <full name> FAILED
--   Error: <error string>
--      at <path to file>, line <line number>
-- ...
-- 
-- Executed <failed or error> of <total number of test> in <time it took>
--    <number pending> Pending
--    <number errors> Errors
--    <number failed> Failed
local function formated_test_run_results(test_batch_stats)
  local final_message_components = {}

  local problem_listing_order = {
    "file_access_errors",
    "file_load_errors",
    "exception",
    "failure",
    "pending",
  }
  for _, problem_kind in ipairs(problem_listing_order) do
    table.insert(final_message_components, table.concat(test_batch_stats[problem_kind], "\n\n"))
  end




  return table.concat(final_message_components, "\n\n\n")
end



local function format_test_batch_stats(test_batch_stats)
  local total_number_of_test = test_batch_stats.statistics.total_number_of_tests
  local number_passed = #test_batch_stats.success
  local number_failed = #test_batch_stats.failure
  local number_pending = #test_batch_stats.pending
  local number_exceptions = #test_batch_stats.exception
  local time_ms = test_batch_stats.statistics.time_in_ms
  local number_load_errors = #test_batch_stats.file_load_errors
  local number_access_errors = #test_batch_stats.file_access_errors

  local number_executed = number_passed + number_failed + number_pending
  local stats =  string.format("Executed %d of %d in %dms",
                        number_executed,
                        total_number_of_test,
                        time_ms)


  local number_ignored = total_number_of_test - number_executed

  stats = stats .. "\n    " .. number_passed .. " Passed"

  if number_pending > 0 then
    stats = stats .. "\n    " .. number_pending .. " Pending"
  end

  if number_failed > 0 then
    stats = stats .. "\n\n    " .. number_failed .. " Failed"
  end

  if number_exceptions > 0 then
    local suffix = "s"
    if number_exceptions == 1 then suffix = "" end 
    stats = stats .. string.format("\n    %d Ignored because of %d Exception", number_ignored, number_exceptions) .. suffix
  end

  if number_access_errors > 0 then
    local suffix = "s"
    if number_access_errors == 1 then suffix = "" end 
    stats = stats .. "\n    " .. number_access_errors .. " Test File Access Error" .. suffix
  end

  if number_load_errors > 0 then
    local suffix = "s"
    if number_load_errors == 1 then suffix = "" end 
    stats = stats .. "\n    " .. number_load_errors .. " Test Load Error" .. suffix
  end

  return stats
  end


--[[
{
  root_paths = {path1, path2}, -- "test script file/folder. Folders will be traversed for any file that matches the --pattern option."
  output = LIBRARY, -- "output library to load", defaultoutput
  pattern = pattern, -- "only run test files matching the Lua pattern", defaultpattern
  tags = tags, -- "only run tests with these #tags, e.g. 'tag1,tag2,tag3'"
  do_coverage_analysis = false, -- "do code coverage analysis (requires 'LuaCov' to be installed)"
  verbose = false, -- "verbose output of errors"
  suppress_pending = false, -- "suppress 'pending' test output"
  defer_print = true, -- "defer print to when test suite is complete"
}
--]]
function run(args)
  args = args or {}
  assert(type(args) == "table")

  -- remove previous spec from busted environment
  busted:reset()

  -- set default arg values if missing
  args.root_paths = args.root_paths or default_spec_dir_paths()
  assert(type(args.root_paths) == "table", "root_paths must be a list of spec file/folder paths")
  args.output = args.output or defaultoutput
  args.pattern = args.pattern or defaultpattern
  args.tags = args.tags or ""
  args.do_coverage_analysis = args.do_coverage_analysis or false
  args.verbose = args.verbose or false
  args.suppress_pending = args.suppress_pending or true
  args.defer_print = args.defer_print or false

  -- list for storing spec file load errors
  local errors = {}

  local root_paths = args.root_paths

  -- perform coverage analysis
  if args.do_coverage_analysis then
    local result, luacov = pcall(require, "luacov.runner")
    if not result then
      return print("LuaCov not found on the system, try running with do_coverage_analysis = false, or install LuaCov first")
    end
    -- call it to start
    luacov()
    -- exclude busted files
    table.insert(luacov.configuration.exclude, "test_runner$")
    table.insert(luacov.configuration.exclude, "busted%.")
    table.insert(luacov.configuration.exclude, "luassert%.")
    table.insert(luacov.configuration.exclude, "say%.")
  end

  -- output formater
  local output

  -- load output formatter
  if args.output then
    if args.output:match(".lua") then
      local o, err = loadfile(args.output)

      if not err then
        output = assert ( o() , "Unable to open output module" ) ()
      else
        output = require('busted.output.'..defaultoutput)()
      end
    else
      output = require(args.output)()
    end
  else
    output = require('busted.output.'..defaultoutput)()
  end

  busted.options = {
    verbose = args.verbose,
    suppress_pending = args.suppress_pending,
    defer_print = args.defer_print,
    tags = split(args.tags, ","),
    output = output,
  }

  local load_errors = {
    file_access_errors = {}, -- formated file access errors
    file_load_errors = {}, -- formated file load errors
  }

  local spec_file_names_for_reporting = {}

  local function dosinglefile(filename)
    -- store test file name for reporting
    local path_reverse = string.reverse(filename)
    local spec_file_name = string.reverse(string.sub(path_reverse, 1, string.find(path_reverse, "\\") - 1))
    table.insert(spec_file_names_for_reporting, spec_file_name)


    local file, err = loadfile(filename)
    if file then
      file, err = pcall(function() file() end)
    end
    if err then
      local path, line, problem = string.match(err, "([^:]*:[^:]+):(%d+):%s(.*)")

      local error_message_components = {
        "An error occurred while loading a test:  LOAD_EXCEPTION",
        "  at: " .. path .. ", line " .. line,
        "  Exception: " .. problem,
      }

      table.insert(load_errors.file_load_errors, table.concat(error_message_components, "\n"))
    end
  end


  if not args.defer_print then
    print("\n\n\n\n---------------------------------")
    print("------", "Running Tests", "------")
    print("---------------------------------\n")
  end


  for _, path in ipairs(root_paths) do
    local mode, err = lfs.attributes(path, "mode")
    if mode == nil then
      local error_message_components = {
        "An error occurred while accessing file/directory:  FILE_ACCESS_EXCEPTION",
        "  Exception: " .. err,
      }

      table.insert(load_errors.file_access_errors, table.concat(error_message_components, "\n"))

    else
      if mode == "file" then
        dosinglefile(path)
      else
        local pattern = args.pattern ~= "" and args.pattern or defaultpattern
        for filename,attr in sub_dir(path) do
          if attr.mode == 'file' then
            local basename = filename:match("[\\/]([^\\/]-)$")
            if basename:find(pattern) then
              dosinglefile(filename)
            end
          end
        end
      end
    end
  end



  local status = busted()

  -- insert file access and load exceptions into status
  status.file_load_errors = load_errors.file_load_errors
  status.file_access_errors = load_errors.file_access_errors

  status_string = formated_test_run_results(status) .. "\n\n\n" .. format_test_batch_stats(status)


  report.event("unit-testing-test-run", {
    test_scripts = spec_file_names_for_reporting,
    results = status_string,
    stats = function() return format_test_batch_stats(status) end,
  })

  if not args.defer_print then
    print(format_test_batch_stats(status))
  end

  return status_string
end
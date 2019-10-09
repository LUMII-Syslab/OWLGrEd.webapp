--interface:
--  output.short_status
--  output.descriptive_status
--  output.currently_executing

-- prepend all enclosing context descriptions to test description
local function format_full_test_name(test_status)
  local context_path = test_status.context_path
  local full_test_name_components = {}

  if #context_path > 1 then
    -- skip global context name
    for i = 2, #context_path do
      table.insert(full_test_name_components, context_path[i])
    end
  end
  -- add test name to the end
  table.insert(full_test_name_components, test_status.description)

  return table.concat(full_test_name_components, " ")
end

local function parse_error_message(error_message)
  path, line, problem = string.match(error_message, "([^:]*:[^:]+):(%d+):%s(.*)")
  return path, line, string.gsub(string.gsub(problem, "\n", " "), "\t", "\n\t")
end

function total_number_of_tests(context_tree, options)
  if context_tree.type == "test" then
    return 1
  elseif context_tree.type == "describe" then
    local count = 0
    for _, context_sub_tree in ipairs(context_tree) do
      count = count + total_number_of_tests(context_sub_tree, options)
    end
    return count
  elseif context_tree.type == "pending" then
    if options.surpress_pending then
      return 0
    else
      return 1
    end
  else
    error("no other context type should be possible  " .. context_tree.type)
  end
end

-- returns test kind and formated test result description
function test_status_to_string(test_status)
  if test_status.type == "failure" then
    local path, line, problem = parse_error_message(test_status.err)

    -- handle exepctions in setup functions, etc.
    if test_status.kind ~= "test" then
      local message_components = {
        format_full_test_name(test_status) .. " EXCEPTION",
        "  at: " .. path .. ", line " .. line,
        "  Exception: " .. problem,
      }
      
      return "exception", table.concat(message_components, "\n")

    else -- handle normal test kind
      local message_components = {
        format_full_test_name(test_status) .. " FAILED",
        "  at: " .. path .. ", line " .. line,
        "  Error: " .. problem,
      }
      
      return "failure", table.concat(message_components, "\n")
    end

  elseif test_status.type == "pending" then
    local message_components = {
      format_full_test_name(test_status) .. " PENDING",
      "  at: " .. test_status.info.short_src .. ", line " .. test_status.info.linedefined,
    }
    
    return "pending", table.concat(message_components, "\n")
  
  elseif test_status.type == "success" then
    return "success", format_full_test_name(test_status) .. " Success"
  else
    error("no other status should be possible")
  end

  return kind, formatted_status
end

local output = function()
  return {
    header = function(context_tree)
    end,

    footer = function(context_tree)
    end,

    formatted_status = function(statuses, options, ms, context_tree)
      local number_of_passed = 0

      local status_reports = {
        exception = {},
        failure = {},
        pending = {},
        success = {},
        statistics = {
          total_number_of_tests = total_number_of_tests(context_tree, options),
          time_in_ms = ms,
        },
      }

      for _, test_status in ipairs(statuses) do
        local kind, formatted = test_status_to_string(test_status)
        table.insert(status_reports[kind], formatted)
      end

      return status_reports
    end,

    currently_executing = function(test_status, options)
      local kind, formated_test_message = test_status_to_string(test_status)
      print(formated_test_message, "\n\n")
    end
  }
end

return output

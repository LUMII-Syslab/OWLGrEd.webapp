-- return truthy if we're in a coroutine
local function in_coroutine()
  local current_routine, main = coroutine.running()
  -- need check to the main variable for 5.2, it's nil for 5.1
  return current_routine and (main == nil or main == false)
end

local function new_initial_context()
  return { type = "describe", description = "global", before_each_stack = {}, after_each_stack = {} }
end 

-- returns a new description list with the new description appended
local function append_context_description(description_list, new_description)
  description_list = description_list or {}
  local result = {}
  for _, v in ipairs(description_list) do
    table.insert(result, v)
  end
  table.insert(result, new_description)

  return result
end

local busted = {
  root_context = new_initial_context(),
  options = {},

  reset_and_return_root_context = function(self)
    self.root_context = new_initial_context()
    return self.root_context
  end,

  __call = function(self)
    local failures = 0
    self.output = self.options.output

    --run test
    local function test(description, callback, no_output, context_path, kind)
      local debug_info = debug.getinfo(callback)

      local info = {
        source = debug_info.source,
        short_src = debug_info.short_src,
        linedefined = debug_info.linedefined,
      }

      local stack_trace = ""

      local function err_handler(err)
        stack_trace = debug.traceback("", 4)
        return err
      end

      local status, err = xpcall(callback, err_handler)

      local test_status = {}

      if not status then
        test_status = { type = "failure", kind = kind, description = description, info = info, context_path = context_path, trace = stack_trace, err = err }
        failures = failures + 1
      else
        test_status = { type = "success", kind = kind, description = description, info = info, context_path = context_path }
      end

      if not no_output and not self.options.defer_print then
        self.output.currently_executing(test_status, self.options)
      end

      return test_status
    end

    -- run setup/teardown
    local function run_setup(context, stype, decsription, context_path)
      if not context[stype] then
        return true
      else
        if type(context[stype]) == "function" then
          local result = test("Failed running test initializer '"..stype.."'", context[stype], true, context_path, stype)
          return (result.type == "success"), result
        elseif type(context[stype]) == "table" then
          if #context[stype] > 0 then
            local result

            for i,v in pairs(context[stype]) do
              result = test("Failed running test initializer '"..decsription.."'", v, true, context_path, stype)

              if result.type ~= "success" then
                return (result.type == "success"), result
              end
            end

            return (result.type == "success"), result
          else
            return true
          end
        end
      end
    end

    --run test case
    local function run_context(context, context_path)
      local match = false

      context_path = append_context_description(context_path, context.description)

      if self.options.tags and #self.options.tags > 0 then
        for i,t in ipairs(self.options.tags) do
          if context.description:find("#"..t) then
            match = true
          end
        end
      else
        match = true
      end

      local status = { description = context.description, type = "description", run = match }
      local setup_ok, setup_error

      setup_ok, setup_error = run_setup(context, "setup", context_path)

      if setup_ok then
        for i,v in ipairs(context) do
          if v.type == "test" then
            setup_ok, setup_error = run_setup(context, "before_each_stack", "before_each", context_path)
            if not setup_ok then break end

            table.insert(status, test(v.description, v.callback, nil, context_path, "test"))

            setup_ok, setup_error = run_setup(context, "after_each_stack", "after_each", context_path)
            if not setup_ok then break end
          elseif v.type == "describe" then
            table.insert(status, coroutine.create(function() run_context(v, context_path) end))
          elseif v.type == "pending" then
            local pending_test_status = { type = "pending", description = v.description, info = v.info, context_path = context_path }
            v.callback(pending_test_status)
            table.insert(status, pending_test_status)
          end
        end
      end

      if setup_ok then setup_ok, setup_error = run_setup(context, "teardown") end

      if not setup_ok then table.insert(status, setup_error) end
      if in_coroutine() then
        coroutine.yield(status)
      else
        return true, status
      end
    end

    local play_sound = function(failures)
      math.randomseed(os.time())

      if self.options.failure_messages and #self.options.failure_messages > 0 and
         self.options.success_messages and #self.options.success_messages > 0 then
        if failures and failures > 0 then
          io.popen("say \""..failure_messages[math.random(1, #failure_messages)]:format(failures).."\"")
        else
          io.popen("say \""..success_messages[math.random(1, #success_messages)].."\"")
        end
      end
    end

    local ms = os.clock()

    if not self.options.defer_print then
      print(self.output.header(self.root_context))
    end

    --fire off tests, return status list
    local function get_statuses(done, list)
      local ret = {}
      for i,v in pairs(list) do
        local vtype = type(v)
        if vtype == "thread" then
          local res = get_statuses(coroutine.resume(v))
          for key,value in pairs(res) do
            table.insert(ret, value)
          end
        elseif vtype == "table" then
          table.insert(ret, v)
        end
      end
      return ret
    end

    local old_TEST = _TEST
    _TEST = busted._VERSION
    local statuses = get_statuses(run_context(self.root_context, {}))

    --final run time
    ms = os.clock() - ms

    if self.options.defer_print then
      print(self.output.header(self.root_context))
    end

    local status_string = self.output.formatted_status(statuses, self.options, ms, self.root_context)

    if self.options.sound then
      play_sound(failures)
    end

    if not self.options.defer_print then
      print(self.output.footer(self.root_context))
    end

    _TEST = old_TEST
    return status_string, failures
  end
}
return setmetatable(busted, busted)

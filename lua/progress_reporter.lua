module(..., package.seeall)

function default_progress_function(x)
  -- return 100 * (x+(1-x)/2)^8
	return 100 * x
end

function create_progress_logger(estimated_number_of_calls, progress_bar_title, progress_function)
  progress_function = progress_function or default_progress_function

  estimated_number_of_calls = estimated_number_of_calls or 100

  if estimated_number_of_calls > 0 then
    local calls_so_far = 0
  
    tda.SetProgressMessage(progress_bar_title)
    tda.SetProgressBar(0)
  
    return function (message)
      if message then
        tda.SetProgressMessage(message)
      else
        calls_so_far = calls_so_far + 1
        --print("calls so far " .. calls_so_far .. " / " .. estimated_number_of_calls)
        local message = string.format("%s %d / %d", progress_bar_title, calls_so_far, estimated_number_of_calls)
        log(string.format("%d in Kbytes | %s", collectgarbage("count"), message))
        tda.SetProgressMessage(message)
        tda.SetProgressBar(progress_function(calls_so_far / estimated_number_of_calls))
      end
    end
  else
    return function() end
	end
end

-- tda.CallFunctionWithPleaseWaitWindow("progress_reporter.progress_reporter_test", 10)
function progress_reporter_test(number_of_steps)
  local report_progress = create_progress_logger(number_of_steps, "task with " .. number_of_steps .. " steps")

  local function sleep(sec)
    local socket = require("socket")
    socket.select(nil, nil, sec)
  end

  for i = 1, number_of_steps do
    sleep(1)
    report_progress()
  end
end

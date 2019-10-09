module(..., package.seeall)

require("socket")

test_runner = require("testing.test_runner")


local default_host = "*" --"127.0.0.1"
local default_port = 5432
local timeout = 5
local server_name = "TDA unit testing server"



function start(host, port)
  host = host or default_host
  port = port or default_port

  local udp = assert(socket.udp())

  assert(udp:setsockname(host, port))
  assert(udp:settimeout(5))


  ip, port = udp:getsockname()
  assert(ip, port)

  log(server_name .. " started on " .. ip .. ":" .. port)

  while 1 do
		
    data, ip, port = udp:receivefrom()

    if data then
			
      log(server_name .. " received data from", ip, port)

      if data == "exit" then
        log(server_name .. " exit request received -- quiting")
        udp:sendto("quiting", ip, port)
        break
      end
	
      -- FIXME should execute in main thread, because some functions
      -- may need to call engine commands (and they crash the system from other threads)
      -- but we need to pass back the test results and execute_in_main_tread currently doesn't
      -- local status_string, failures = execute_in_main_tread("unit_testing_server.run_test", data)
      
      -- local status_string, failures = run_tests(data)
      local status_string, errors = test_runner.run({
        verbose = true,
        -- root_paths = {tda.GetRuntimePath().."\\spec\\test_spec.lua"},
      })
      
      -- log(server_name .. " test run results:", "\n\t"..status_string)
      log(server_name.. " sending answer")

      udp:sendto(status_string, ip, port)

      log(server_name.. " answer sent")
    end
  end
  udp:close()
end

function stop(port)
  host = default_host
  port = port or default_port

  udp = socket.udp()
  udp:setpeername(host, port)
  udp:settimeout(5)

  udp:send("exit")
  dgram = udp:receive()

  assert(dgram == "quiting")

  udp:close()
end

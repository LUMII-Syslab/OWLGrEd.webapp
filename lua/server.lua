module(..., package.seeall)
require("socket")
require("owl_protege_export")

local ip = "127.0.0.1";

function start()
  local server = assert(socket.bind(ip, 6543))

  local ip, port = server:getsockname()

  log("Waiting for data from protege on " .. ip .. ":" .. port)

  while 1 do
		
    local client = server:accept()
		
    local data, err = client:receive('*a')
		
    if data then
			
      log("received data from", client:getpeername())
      if data == "exit" then
        log("exit request received, quiting")
        break
      end
      
		 -- local file = io.open("data_from_protege.lua", "w")
     -- file:write(dumptable(data))
     -- file:close()   
	

      execute_in_main_tread("owl_protege.import_from_protege", data)
      
      -- client:send(line .. "\n")
    else
      log("error in receive", err, client:getpeername())
    end
  
    client:close()
  end
end

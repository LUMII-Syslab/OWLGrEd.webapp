socket = require("socket")

host = "localhost"
port = 5432
timeout = 0.3

local project_base_path

if arg then
    host = arg[1] ~= "" and arg[1] or host
    port = arg[2] ~= "" and arg[2] or port
    project_base_path = arg[3] ~= "" and arg[3]
end

function run_test()
	-- host = socket.dns.toip(host)
	-- print(host)

	-- establish connection to server
	udp = assert(socket.udp())
	assert(udp:setpeername(host, port))
	udp:settimeout(timeout)


	test = "run all"

	-- send test data
	assert(udp:send(test))

	test_results = assert(udp:receive())

	-- replace path seperators with correct values
	test_results = string.gsub(test_results, "\\", "/")

	if project_base_path then
		-- FIXME
		-- need to somehow get the correct value for windows
		-- tda base path, to replace with the mac path

		-- local remote_prefix = string.find()
		test_results = string.gsub(test_results, "X:", project_base_path)
	end

	assert(udp:close())

	return test_results
end

local function err_handler(err)
	stack_trace = debug.traceback("", 4)
	return err
end

local status, test_results__or__err = xpcall(run_test, err_handler)
if not status then
	print("connection to tda failed", test_results__or__err)
else
	print(test_results__or__err)
end


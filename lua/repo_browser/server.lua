module(..., package.seeall)

require "xavante"
require "xavante.httpd"
require "xavante.vhostshandler"
require "xavante.urlhandler"
require "xavante.filehandler"
require "xavante.indexhandler"

XAVANTE_WEB = tda.GetRuntimePath() .. "\\public"


-- full file path
-- the file should be just script (not module)
-- that returns one function - function(req, res)
function load_handler_from_file_on_each_request(one_time_handler_path)
	return function(req, res)
		assert(one_time_handler_path)
		assert(type(one_time_handler_path) == "string")

		log("load one time handler from file", one_time_handler_path)

		local handler_path = one_time_handler_path

		local f, err = loadfile(handler_path)

		if err then
			log("error loading one time handler\n", err .. "\n", debug.traceback())
		else
			log("one time handler script loaded")

			local status, one_time_handler = xpcall(f, debug.traceback)

			if status then
				local status, new_res = xpcall(function() return one_time_handler(req, res) end, debug.traceback)
				if status then
					res = new_res
				else
					print(new_res .. "\n", debug.traceback())
				end
			else
				print(one_time_handler .. "\n", debug.traceback())
			end
		end
		-- print(dumpstring(res))
		return res
	end
end


function start()
	xavante.httpd.handle_request = xavante.vhostshandler {
		[""] = xavante.urlhandler {
			["/tda_web/"] = xavante.filehandler(XAVANTE_WEB),

			["/repo_browser/"] = xavante.filehandler(tda.GetRuntimePath() .. '/lua/repo_browser'),
			["/browser.html"] = xavante.indexhandler("/repo_browser/browser.html"),
			["/diagrams"] = function(req, res)
				local json = require("reporter.dkjson")
				res.headers["Content-Type"] = "application/json"
				res.content = json.encode(require("repo_browser.diagrams").all_diagrams_in_table_form())
			end,
			["/property_diagram_types"] = function(req, res)
				local json = require("reporter.dkjson")
				res.content = json.encode(require("repo_browser.property_diagram_types").property_diagram_defs_in_table_form())
			end,
			["/lQuery"] = require('repo_browser.lQuery_handler').handler,
		}
	}

	xavante.httpd.register ("*", 8080, "Xavante 1.3")

	function is_finished()
		log(os.date("%X"))
	end

	xavante.start(is_finished)
end
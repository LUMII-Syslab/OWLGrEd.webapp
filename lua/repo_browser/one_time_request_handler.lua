require "xavante.vhostshandler"
require "xavante.urlhandler"
require "xavante.filehandler"

XAVANTE_WEB = tda.GetRuntimePath()

-- return function(req, res)
-- 	print("------\n\n\n\n-------")
-- 	res.content = "abc"
-- end

return xavante.vhostshandler {
	[""] = xavante.urlhandler {
		["/"] = xavante.filehandler (XAVANTE_WEB.."/"),
		["/img"] = xavante.filehandler (XAVANTE_WEB.."/img"),
		["/tda_web"] = xavante.filehandler (XAVANTE_WEB.."/tda_web"),
	}
}

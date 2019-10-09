module(..., package.seeall)

require "lQuery"


function get_compartment(parent, path)
	if not parent or parent == "" or parent:is_empty() then
		return lQuery("")
	end

	local head = string.match(path, "%a+")
	local tail = string.sub(path, string.len(head)+2)
	
	local compartment_type = parent:find("/elemType/compartType[id='"..head.."'], /compartType/subCompartType[id='"..head.."']")
	
	if compartment_type:is_empty() then
		parent = get_compartment(parent, "ASFictitious"..head)
	end
	
	local type_string = "/compartType[id='"..head.."']"
	compartment = parent:find("/compartment:has("..type_string.."), /subCompartment:has("..type_string..")")
	
	if compartment:is_empty() then
		compartment = core.add_compart(parent:find("/elemType"..type_string..", /compartType/subCompartType[id='"..head.."']"), parent)
	end
	
	if string.len(tail) > 0 then
		return get_compartment(compartment, tail)
	else
		return compartment
	end
end

function strict_get_compartment(parent, path)
	if not parent or parent == "" or parent:is_empty() then
		return lQuery("")
	end

	local head = string.match(path, "%a+")
	local tail = string.sub(path, string.len(head)+2)
	
	local compartment_type = parent:find("/elemType/compartType[id='"..head.."'], /compartType/subCompartType[id='"..head.."']")
	
	if compartment_type:is_empty() then
		parent = strict_get_compartment(parent, "ASFictitious"..head)
	end
	
	if parent:is_empty() then
		return lQuery("")
	end
	
	local type_string = "/compartType[id='"..head.."']"
	compartment = parent:find("/compartment:has("..type_string.."), /subCompartment:has("..type_string..")")
	
	if compartment:is_empty() then
		return lQuery("")
	end
	
	if string.len(tail) > 0 then
		return strict_get_compartment(compartment, tail)
	else
		return compartment
	end
end

function create_compartment(parent, path)
	if not parent or parent == "" or parent:is_empty() then
		return lQuery("")
	end

	local head = string.match(path, "%a+")
	local tail = string.sub(path, string.len(head)+2)
	local is_multiple = false
	
	local compartment_type = parent:find("/elemType/compartType[id='"..head.."'], /compartType/subCompartType[id='"..head.."']")
	
	if compartment_type:is_empty() then
		parent = create_compartment(parent, "ASFictitious"..head)
	end
	
	if string.sub(parent:find("/elemType, /compartType"):attr("id"), 0, 12) == "ASFictitious" then
		is_multiple = true
	end
	
	local type_string = "/compartType[id='"..head.."']"
	compartment = parent:find("/compartment:has("..type_string.."), /subCompartment:has("..type_string..")")
	
	if compartment:is_empty() or is_multiple then
		compartment = core.add_compart(parent:find("/elemType"..type_string..", /compartType/subCompartType[id='"..head.."']"), parent)
	end
	
	if string.len(tail) > 0 then
		return create_compartment(compartment, tail)
	else
		return compartment
	end
end

function strict_create_compartment(parent, path)
	if not parent or parent == "" or parent:is_empty() then
		return lQuery("")
	end

	local head = string.match(path, "%a+")
	local tail = string.sub(path, string.len(head)+2)
	local is_multiple = false
	
	local compartment_type = parent:find("/elemType/compartType[id='"..head.."'], /compartType/subCompartType[id='"..head.."']")
	
	if compartment_type:is_empty() then
		parent = strict_create_compartment(parent, "ASFictitious"..head)
	end
	
	if parent:is_empty() then
		return lQuery("")
	end
	
	if string.sub(parent:find("/elemType, /compartType"):attr("id"), 0, 12) == "ASFictitious" then
		is_multiple = true
	end
	
	local type_string = "/compartType[id='"..head.."']"
	compartment = parent:find("/compartment:has("..type_string.."), /subCompartment:has("..type_string..")")
	
	if compartment:is_empty() or is_multiple then
		compartment = core.add_compart(parent:find("/elemType"..type_string..", /compartType/subCompartType[id='"..head.."']"), parent)
	else
		return lQuery("")
	end
	
	if string.len(tail) > 0 then
		return strict_create_compartment(compartment, tail)
	else
		return compartment
	end
end

module(..., package.seeall)

oo = require("oop")

Color = oo.class({
	_rgb = {255, 0, 255},
	__init = function(self, x, y, z, m)
		local me = {}

		if m == 'rgb' then
			me._rgb = {x, y, z}
		elseif m == 'lab' then
			me._rgb = lab2rgb(x,y,z)
		elseif m == 'tda' then
			me._rgb = tda2rgb(x)
		elseif m == 'hex' then
			me._rgb = hex2rgb(x)
		else
			error("unsuported color mode")
		end

		return setmetatable(me, self)
	end,
})



function Color:get_color_diff(color2)
	local self_lab = self:lab()
	local color2_lab = color2:lab()

	return {
		self_lab[1] - color2_lab[1],
		self_lab[2] - color2_lab[2],
		self_lab[3] - color2_lab[3],
	}
end

function Color:add_diff(diff_in_lab)
	local self_lab = self:lab()

	return Color(
		self_lab[1] + diff_in_lab[1],
		self_lab[2] + diff_in_lab[2],
		self_lab[3] + diff_in_lab[3],
		'lab'
	)
end

function Color:subtract_diff(diff_in_lab)
	local self_lab = self:lab()

	return Color(
		self_lab[1] - diff_in_lab[1],
		self_lab[2] - diff_in_lab[2],
		self_lab[3] - diff_in_lab[3],
		'lab'
	)
end



function Color:rgb()
	return self._rgb
end

function Color:lab()
	return rgb2lab(self._rgb)
end

function Color:hcl()
	return rgb2hcl(self._rgb)
end

function Color:hex()
	return rgb2hex(self._rgb)
end

function Color:tda()
	return rgb2tda(self._rgb)
end

--
-- L*a*b* scale by David Dalrymple
-- http://davidad.net/colorviz/
--
function lab2xyz(l, a, b)
	--[[
	Convert from L*a*b* doubles to XYZ doubles
	Formulas drawn from http://en.wikipedia.org/wiki/Lab_color_spaces
	]]--

	if type(l) == "table" and #l == 3 then
		l, a, b = l[1], l[2], l[3]
	end
	

	local function finv(t)
		if t > (6.0/29.0) then
			return t*t*t
		else
			return 3*(6.0/29.0)*(6.0/29.0)*(t-4.0/29.0)
		end
	end
	local sl = (l+0.16) / 1.16
	local ill = {0.96421, 1.00000, 0.82519}
	local y = ill[2] * finv(sl)
	local x = ill[1] * finv(sl + (a/5.0))
	local z = ill[3] * finv(sl - (b/2.0))

	return {x, y, z}
end

function xyz2lab(x, y, z)
	-- 6500K color templerature
	if type(x) == "table" and #x == 3 then
		x, y, z = x[1], x[2], x[3]
	end

	local ill = {0.96421, 1.00000, 0.82519}
	local function f(t)
		if t > math.pow(6.0/29.0,3) then
			return math.pow(t, 1/3)
		else
			return (1/3)*(29/6)*(29/6)*t+4.0/29.0
		end
	end
	local l = 1.16 * f(y/ill[2]) - 0.16
	local a = 5 * (f(x/ill[1]) - f(y/ill[2]))
	local b = 2 * (f(y/ill[2]) - f(z/ill[3]))

	return {l, a, b}
end



function rgb2xyz(r, g, b)
	if type(r) == "table" and #r == 3 then
		r, g, b = r[1], r[2], r[3]
	end

	local function correct(c)
		a = 0.055
		if c <= 0.04045 then
			return c/12.92
		else
			return math.pow((c+a)/(1+a), 2.4)
		end
	end

	local rl = correct(r/255.0)
	local gl = correct(g/255.0)
	local bl = correct(b/255.0)

	local x = 0.4124 * rl + 0.3576 * gl + 0.1805 * bl
	local y = 0.2126 * rl + 0.7152 * gl + 0.0722 * bl
	local z = 0.0193 * rl + 0.1192 * gl + 0.9505 * bl
	
	return {x, y, z}
end


local function round(num, idp)
	return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

function xyz2rgb(x, y, z)
	--[[
	Convert from XYZ doubles to sRGB bytes
	Formulas drawn from http://en.wikipedia.org/wiki/Srgb
	]]--
	if type(x) == "table" and #x == 3 then
		x, y, z = x[1], x[2], x[3]
	end

	local rl =  3.2406*x - 1.5372*y - 0.4986*z
	local gl = -0.9689*x + 1.8758*y + 0.0415*z
	local bl =  0.0557*x - 0.2040*y + 1.0570*z
	local clip = math.min(rl,gl,bl) < -0.001 or math.max(rl,gl,bl) > 1.001
	if clip then
		if rl<0.0 then
			rl = 0.0
		elseif rl>1.0 then
			rl = 1.0
		end

		if gl<0.0 then
			gl = 0.0
		elseif gl>1.0 then
			gl = 1.0
		end

		if bl<0.0 then 
			bl = 0.0
		elseif bl>1.0 then
			bl = 1.0
		end
	end

	-- Uncomment the below to detect clipping by making clipped zones red.
	-- if clip then
	-- 	rl, gl, bl = nil, nil, nil
	-- end

	local function correct(cl)
		local a = 0.055
		if cl<=0.0031308 then
			return 12.92*cl
		else
			return (1+a)*math.pow(cl,1/2.4)-a
		end
	end

	local r = round(255.0*correct(rl))
	local g = round(255.0*correct(gl))
	local b = round(255.0*correct(bl))

	return {r,g,b}
end



function lab2rgb(l, a, b)
	--[[
	Convert from LAB doubles to sRGB bytes
	(just composing the above transforms)
	]]--

	if type(l) == "table" and #l == 3 then
		l, a, b = l[1], l[2], l[3]
	end

	local x, y, z = lab2xyz(l, a, b)
	
	return xyz2rgb(x, y, z)
end

function rgb2lab(r, g, b)
	if type(r) == "table" and #r == 3 then
		r, g, b = r[1], r[2], r[3]
	end

	local x, y, z = rgb2xyz(r, g, b)

	return xyz2lab(x, y, z)
end


function rgb2hcl(r, g, b)
	if type(r) == "table" and #r == 3 then
		r, g, b = r[1], r[2], r[3]
	end

	local l, a, b = rgb2lab(r, g, b)
	
	return lab2hcl(l, a, b)
end

function lab2hcl(l, a, b)
	--[[
	Convert from a qualitative parameter c and a quantitative parameter l to a 24-bit pixel. These formulas were invented by David Dalrymple to obtain maximum contrast without going out of gamut if the parameters are in the range 0-1.

	A saturation multiplier was added by Gregor Aisch
	]]--

	if type(l) == "table" and #l == 3 then
		l, a, b = l[1], l[2], l[3]
	end

	local L = l
	l = (l-0.09) / 0.61

	local r = math.sqrt(a*a + b*b)
	local s = r / (l*0.311+0.125)

	local TAU = 6.283185307179586476925287

	local angle = 0
	if a ~= 0 and b ~= 0 then
		angle = math.atan2(a,b)
	end

	local c = (TAU/6 - angle) / TAU
	c = c * 360
	if c < 0 then
		c = c + 360
	end

	return {c, s, l}
end


function hex2rgb(hex)
    local b, g, r, u

    if (#hex == 4 or #hex == 7) then 
    	hex = string.gsub(hex, "^.", "")
    end

    if (hex.length == 3) then
      hex = hex:gsub("(.)(.)(.)", "%1%1%2%2%3%3")
    end

    local r, g, b = string.match(hex, "(..)(..)(..)")
    return {tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)}
end

function rgb2hex(r, g, b)
    if type(r) == "table" and #r == 3 then
		r, g, b = r[1], r[2], r[3]
	end
	assert(type(r) == "number")
	assert(type(g) == "number")
	assert(type(b) == "number")

    return string.format("#%02x%02x%02x", r,g,b)
end



function rgb2tda(r, g, b)
	if type(r) == "table" and #r == 3 then
		r, g, b = r[1], r[2], r[3]
	end
	assert(type(r) == "number")
	assert(type(g) == "number")
	assert(type(b) == "number")

	-- tda wants blue, green, red.
	local hex_form = string.format("%02x", b) ..
	       string.format("%02x", g) ..
	       string.format("%02x", r)
	return tonumber(hex_form, 16)
end

function tda2rgb(tda_color_int)
	-- tda has blue, green, red.
	local bgr = string.format("%06x", tda_color_int)
	local rgb = string.gsub(bgr, "(..)(..)(..)", "%3;%2;%1")
	local r, g, b = string.match(rgb, "(..);(..);(..)")
	return {tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)}
end

--
-- static constructors
--

function rgb(r, g, b)
	return Color(r, g, b, 'rgb')
end

function lab(l, a, b)
	return Color(l, a, b, 'lab')
end

function hex(hex)
	return Color(hex, nil, nil, 'hex')
end

function tda(tda_int)
	return Color(tda_int, nil, nil, 'tda')
end


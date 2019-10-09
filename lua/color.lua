module(..., package.seeall)

-- from http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/

-- HSV values in [0..1]
-- returns [r, g, b] values from 0 to 255
function hsv_to_rgb(h, s, v)
  local h_i = math.floor(h*6)
  local f = h*6 - h_i
  local p = v * (1 - s)
  local q = v * (1 - f*s)
  local t = v * (1 - (1 - f) * s)

  local r, g, b

  if h_i == 0 then
    r, g, b = v, t, p
  elseif h_i == 1 then
    r, g, b = q, v, p
  elseif h_i == 2 then 
    r, g, b = p, v, t
  elseif h_i == 3 then
    r, g, b = p, q, v
  elseif h_i == 4 then
    r, g, b = t, p, v
  elseif h_i == 5 then
    r, g, b = v, p, q
  else
    error("unhandled h_1:  " .. h_i)
  end

  return math.floor(r*256), math.floor(g*256), math.floor(b*256)
end

-- random rgb values given saturation and value
-- hue is random
function random_hue_rgb(s, v)
  -- use golden ratio
  local golden_ratio_conjugate = 0.618033988749895

  h = math.random() -- use random start value
  h = h + golden_ratio_conjugate
  h = h % 1
  return hsv_to_rgb(h, s, v)
end



function rgb_to_tda_int(red, green, blue)
  assert(type(red) == "number")
  assert(type(green) == "number")
  assert(type(blue) == "number")
  -- tda wants blue, green, red.
  local hex_form = string.format("%02x", blue) ..
           string.format("%02x", green) ..
           string.format("%02x", red)
  return tonumber(hex_form, 16)
end



function tda_to_bgr_hex(tda_color_int)
  -- tda has red, blue, green.
  bgr = string.format("%x", tda_color_int)

  return string.gsub(bgr, "(..)(..)(..)", "%1%3%2")
end


function tda_to_rgb_int(tda_color_int)
  -- tda has blue, green, red.
  local bgr = string.format("%x", tda_color_int)
  local rgb = string.gsub(bgr, "(..)(..)(..)", "%3;%2;%1")
  local r, g, b = string.match(rgb, "(..);(..);(..)")
  return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end


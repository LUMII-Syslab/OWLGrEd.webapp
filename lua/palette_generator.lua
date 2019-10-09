module(..., package.seeall)

require('chroma')

local function isNaN(n)
	return n ~= n
end

local function map(tbl, func)
	local newtbl = {}
	for i,v in pairs(tbl) do
		newtbl[i] = func(v)
	end
	return newtbl
end

local function filter(tbl, func)
     local newtbl= {}
     for i,v in ipairs(tbl) do
         if func(v, i) then
	     	table.insert(newtbl, v)
         end
     end
     return newtbl
 end

local function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


function generate(colorsCount, checkColor, forceMode, quality)
	-- Default
	if colorsCount == nil then
		colorsCount = 8
	end
	if checkColor == nil then
		checkColor = function(x) return true end
	end
	if forceMode == nil then
		forceMode = false
	end
	if quality == nil then
		quality = 50
	end
	
	if forceMode then
		-- Force Vector Mode
		
		local colors = {}
		
		-- It will be necessary to check if a Lab color exists in the rgb space.
		local function checkLab(lab)
			local color = chroma.lab(lab[1], lab[2], lab[3])
			return not(isNaN(color:rgb()[1])) and color:rgb()[1]>=0 and color:rgb()[2]>=0 and color:rgb()[3]>=0 and color:rgb()[1]<256 and color:rgb()[2]<256 and color:rgb()[3]<256 and checkColor(color)
		end
		
		-- Init
		local vectors = {}
		for i=1, colorsCount do
			-- Find a valid Lab color
			local color = {math.random(),2*math.random()-1,2*math.random()-1}
			while not checkLab(color) do
				color = {math.random(),2*math.random()-1,2*math.random()-1}
			end
			table.insert(colors, color)
		end
		
		-- Force vector: repulsion
		local repulsion = 0.2
		local speed = 0.05
		local steps = quality * 20
		while steps > 0 do
			steps = steps - 1
			-- Init
			for i=1, #colors do
				vectors[i] = {dl = 0, da = 0, db =0}
			end

			-- Compute Force
			for i=1, #colors do
				local colorA = colors[i]
				for j=1, i do
					local colorB = colors[j]
					
					-- repulsion force
					local dl = colorA[1]-colorB[1]
					local da = colorA[2]-colorB[2]
					local db = colorA[3]-colorB[3]
					local d = math.sqrt(math.pow(dl, 2)+math.pow(da, 2)+math.pow(db, 2))
					if d>0 then
						local force = repulsion/math.pow(d,2)
						
						vectors[i].dl = vectors[i].dl + dl * force / d
						vectors[i].da = vectors[i].da + da * force / d
						vectors[i].db = vectors[i].db + db * force / d
						
						vectors[j].dl = vectors[j].dl - dl * force / d
						vectors[j].da = vectors[j].da - da * force / d
						vectors[j].db = vectors[j].db - db * force / d
					else
						-- Jitter
						vectors[j].dl = vectors[j].dl + 0.02 - 0.04 * math.random()
						vectors[j].da = vectors[j].da + 0.02 - 0.04 * math.random()
						vectors[j].db = vectors[j].db + 0.02 - 0.04 * math.random()
					end
				end
			end
			-- Apply Force
			for i=1,#colors do
				local color = colors[i]
				local displacement = speed * math.sqrt(math.pow(vectors[i].dl, 2)+math.pow(vectors[i].da, 2)+math.pow(vectors[i].db, 2))
				if displacement>0 then
					local ratio = speed * math.min(0.1, displacement)/displacement
					candidateLab = {color[1] + vectors[i].dl*ratio, color[2] + vectors[i].da*ratio, color[3] + vectors[i].db*ratio}
					if checkLab(candidateLab) then
						colors[i] = candidateLab
					end
				end
			end
		end
		
		return map(colors, function(lab) return chroma.lab(lab[1], lab[2], lab[3]) end)
	
	else		
		-- K-Means Mode
		function checkColor2(color)
			-- Check that a color is valid: it must verify our checkColor condition, but also be in the color space
			-- local lab = color:lab()
			-- local hcl = color:hcl()
			local rgb = color:rgb()
			return not(isNaN(rgb[1])) and rgb[1]>=0 and rgb[2]>=0 and rgb[3]>=0 and rgb[1]<256 and rgb[2]<256 and rgb[3]<256 and checkColor(color)
		end
		
		local kMeans = {}
		for i=1,colorsCount do
			local lab = {math.random(),2*math.random()-1,2*math.random()-1}
			while not checkColor2(chroma.lab(lab)) do
				lab = {math.random(),2*math.random()-1,2*math.random()-1}
			end
			table.insert(kMeans, lab)
		end
		
		local colorSamples = {}
		local samplesClosest = {}
		for l=0,1,0.05 do
			for a=-1,1,0.1 do
				for b=-1,1,0.1 do
					if checkColor2(chroma.lab(l, a, b)) then
						table.insert(colorSamples, {l, a, b})
						table.insert(samplesClosest, nil)
					end
				end
			end
		end
		
		-- Steps
		local steps = quality
		while steps > 0 do
			steps = steps - 1
			-- kMeans -> Samples Closest
			for i=1, #colorSamples do
				local lab = colorSamples[i]
				local minDistance = 1000000
				for j=1, #kMeans do
					local kMean = kMeans[j]
					local distance = math.sqrt(math.pow(lab[1]-kMean[1], 2) + math.pow(lab[2]-kMean[2], 2) + math.pow(lab[3]-kMean[3], 2))
					if distance < minDistance then
						minDistance = distance
						samplesClosest[i] = j
					end
				end
			end
			
			-- Samples -> kMeans
			local freeColorSamples = shallowcopy(colorSamples) -- colorSamples.slice(0)
			for j=1, #kMeans do
				local count = 0
				local candidateKMean = {0, 0, 0}
				for i=1, #colorSamples do
					if samplesClosest[i] == j then
						count = count + 1
						candidateKMean[1] = candidateKMean[1] +colorSamples[i][1]
						candidateKMean[2] = candidateKMean[2] +colorSamples[i][2]
						candidateKMean[3] = candidateKMean[3] +colorSamples[i][3]
					end
				end
				if count ~= 0 then
					candidateKMean[1] = candidateKMean[1] / count
					candidateKMean[2] = candidateKMean[2] / count
					candidateKMean[3] = candidateKMean[3] / count
				end
				
				if count ~= 0 and candidateKMean and checkColor2(chroma.lab(candidateKMean[1], candidateKMean[2], candidateKMean[3])) then
					kMeans[j] = candidateKMean
				else
					-- The candidate kMean is out of the boundaries of the color space, or unfound.
					if #freeColorSamples > 0 then
						-- We just search for the closest FREE color of the candidate kMean
						local minDistance = 10000000000
						local closest = -1
						for i=1, #freeColorSamples do
							local distance = math.sqrt(math.pow(freeColorSamples[i][1]-candidateKMean[1], 2) + math.pow(freeColorSamples[i][2]-candidateKMean[2], 2) + math.pow(freeColorSamples[i][3]-candidateKMean[3], 2))
							if distance < minDistance then
								minDistance = distance
								closest = i
							end
						end
						kMeans[j] = colorSamples[closest]

					else
						-- Then we just search for the closest color of the candidate kMean
						local minDistance = 10000000000
						local closest = -1
						for i=1, #colorSamples do
							local distance = math.sqrt(math.pow(colorSamples[i][1]-candidateKMean[1], 2) + math.pow(colorSamples[i][2]-candidateKMean[2], 2) + math.pow(colorSamples[i][3]-candidateKMean[3], 2))
							if distance < minDistance then
								minDistance = distance
								closest = i
							end
						end
						kMeans[j] = colorSamples[closest]
					end
				end
				freeColorSamples = filter(freeColorSamples, function(color)
					return color[1] ~= kMeans[j][1]
						or color[2] ~= kMeans[j][2]
						or color[3] ~= kMeans[j][3]
				end)
			end
		end

		return map(kMeans, function(lab) return chroma.lab(lab[1], lab[2], lab[3]) end)
	end
end

function diffSort(colorsToSort)
	-- Sort
	local diffColors = {table.remove(colorsToSort, 1)}
	while #colorsToSort >0 do
		local index = -1
		local maxDistance = -1
		for candidate_index=1, #colorsToSort do
			local d = 1000000000
			for i=1, #diffColors do
				local colorA = colorsToSort[candidate_index]:lab()
				local colorB = diffColors[i]:lab()
				local dl = colorA[1] - colorB[1]
				local da = colorA[2] - colorB[2]
				local db = colorA[3] - colorB[3]
				d = math.min(d, math.sqrt(math.pow(dl, 2) + math.pow(da, 2) + math.pow(db, 2)))
			end
			if d > maxDistance then
				maxDistance = d
				index = candidate_index;
			end
		end
		local color = colorsToSort[index]
		table.insert(diffColors, color)
		colorsToSort = filter(colorsToSort, function(c, i) return i ~= index end)
	end
	return diffColors
end
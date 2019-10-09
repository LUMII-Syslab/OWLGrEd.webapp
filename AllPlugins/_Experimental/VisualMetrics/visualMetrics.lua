module(..., package.seeall)
--[[
	ontloģijas attēlojuma kvalitātes novērtēšnas spraudnis nodrošina sekojošu funckkionalitāti:
	1) aprēkina kvalitātes metriku vērtības
	2) attēlo aprēķinatās vērtības
	3) nodrošina lietotājam iespēju mainīt metriku koeficientu vērtības un attēlot izmaiņas
--]]


--ceļs uz koeficientu mapi
local project_path_coef=tda.GetProjectPath().."\\Plugins\\VisualMetrics\\coefficients"
--atļauto failu tipu saraksts
local fileTypeString = "JSON file (*.json)\nALL files (*.*)"

local l_name_clases = {} -- index lai atrastu klasi pēc nosaukuma
local l_atribute_type = {} --atribūtu tipi, lai noteiktu klases nosaukuma izmantojumu atribūtu nosaukumos
local l_clases_extended_name = {} --unikālo klašu saraksts, kuru nosaukumi ir lietoti ārpus klases (atribūts, restriction, disjoint)
--klašu un fork elementu saraksti
local class_list={}
local fork_list={}
--klašu un fork elementu metriku saraksti
local l_clases = {}
local l_forks = {}

--diagramma
local v_diagram
--metriku saraksts
local l_metrics = {}

-- metriku summas
local klases=0
local linijas=0
local atributi=0
local virs_atr=0
local virs_atr_nep=0			
local paslinijas=0
local krustojumi=0			
local lin_viens_x=0			
local lin_varaiki_x=0			
local vispar_lin=0
local virs_linijas=0
local virs_linijas_nep=0		
local nos_poz=0					
local nos_neg=0		
local nos_restr=0			
local c_connected_class_has_elements = 0
local c_extended_total = 0;

--kopējā metriku summa	
local total=0
--attēlošanas identēšanas simbols
local spacing=""
--attēlošanas nosaukumi, noklusējuma koeficienti
local default_prop = {
		["klases"] ={["koef"]=1, ["alias"]="Class Nodes"}
		,["linijas"] ={["koef"]=1, ["alias"]="Lines"}
		,["atributi"] ={["koef"]=0.2, ["alias"]="Attributes"}
		,["virs_atr"] ={["koef"]=0.2, ["alias"]=spacing.."Attributes at super class"}
		,["virs_atr_nep"] ={["koef"]=0.2, ["alias"]=spacing.."Attributes at super class"}
		,["paslinijas"] ={["koef"]=1.25, ["alias"]=spacing.."Class self lines"}
		,["krustojumi"]={["koef"]=1, ["alias"]=spacing.."Line intersections"}
		,["lin_viens_x"] ={["koef"]=0.2, ["alias"]=spacing.."Lines with single bend"}
		,["lin_varaiki_x"] ={["koef"]=1, ["alias"]=spacing.."Lines with multiple bends"}
		,["vispar_lin"] ={["koef"]=1.6, ["alias"]=spacing.."Generalization lines"}
		,["virs_linijas"] = {["koef"]=0.3, ["alias"]=spacing.."Lines at super class"}
		,["virs_linijas_nep"] ={["koef"]=0.3, ["alias"]=spacing.."Lines at super class"}
		--,["nos_poz"]={["koef"]=1, ["alias"]=spacing.."As atribute type"}
		,["nos_neg"]={["koef"]=0.1, ["alias"]=spacing.."Class in disjoint list"}
		--,["nos_restr"]={["koef"]=1, ["alias"]=spacing.."As restriction"}
		--,["nos_restr_u"]={["koef"]=2, ["alias"]=spacing.."As restriction (unique)"}
		--,["nos_poz_u"]={["koef"]=2, ["alias"]=spacing.."As atribute type (unique)"}
		--,["nos_neg_u"]={["koef"]=0, ["alias"]=spacing.."As disjoint class (unique)"}
		--,["nos_uniq"]={["koef"]=1, ["alias"]=spacing.."Unique class name uses"}
		--,["sub_c_ncon_count_wth_atr"]={["koef"]=1, ["alias"]=spacing.."Sub class count (super has attributes)"}
		--,["super_c_ncon_count"]={["koef"]=2, ["alias"]=spacing.."Super class count"}
		--,["super_c_con_has_elem"]={["koef"]=0.05, ["alias"]=spacing.."Sub class count (sup. not empty)"}
		,["extended_class_name_u"]={["koef"]=2, ["alias"]=spacing.."Unique uses"}
		,["extended_class_name_t"]={["koef"]=1, ["alias"]=spacing.."Total uses"}
}

--attēlošanas secība
local order = {"klases"
				,"linijas"
				,"atributi"
				--,"Extended use of class name"
				--	,"nos_poz_u"
				--	,"nos_poz"
				--	,"nos_neg_u"
					,"nos_neg"
				--	,"nos_restr_u"
				--	,"nos_restr"
				--	,"nos_uniq"
				,"Line metrics"
					,"paslinijas"
					,"krustojumi"
					,"lin_viens_x"
					,"lin_varaiki_x"
					,"vispar_lin"
				,"Super class is connected"
					,"virs_atr"
					,"virs_linijas"
					--,"super_c_con_has_elem"
				,"Super class is not connected"
					,"virs_atr_nep"
					--,"sub_c_ncon_count_wth_atr"
					--,"super_c_ncon_count"
					,"virs_linijas_nep"
				,"Class name as text (attribute type, restriction, super class)"
					,"extended_class_name_u"
					,"extended_class_name_t"
			}

--=======================
-- Datu apstrāde daļa
--=======================
function calculateMetrics()
	
	--saglabā līniju izvietojumu
	utilities.execute_cmd("SaveDgrCmd", {graphDiagram = utilities.current_diagram()})
	--aizpilda datu struktūras
	class_list, fork_list = populateTables()
	
	
	--=======================
	-- 1. vienkāršu līniju metriku aprēķināšana
	--=======================
	--līniju skaita aprēķināšana
	countLines()
	--ienākošo vispārinošo līniju skaits
	vispar_lin = generalzionCount()
	

	--=======================
	-- 2. pamata metriku aprēķinšāna klasēm un potenciāli neesošo metriku definēšana
	--=======================
	for a in class_list do 
		l_clases[a:attr("location")] = {["c_attributes"]=classAtrCount(a)
			,["c_lines_from"]=classLinesFromCount(a)
			,["c_self_lines"]=selfLineCount(a)
			,["c_restrictions_as_text"]=0
			,["c_super_atr_gen"]=0
			,["c_super_lines_gen"]=0
			,["c_super_atr_text"]=0
			,["c_super_lines_text"]=0
			,["c_name_as_atr"]=0
			,["c_disjoint_text"]=0
			,["c_connected_class_has_elements"]=0		
			,["c_super_count"]=0		
			,["c_restriction_count"]=0
			,["c_attribute_count"]=0
		}
		
		--klašu skaits
		klases = klases + 1 	
	end
	
	
	--=======================
	-- 3. parējo klašu metriku aprēķināšana
	--=======================
	--fork elementu apstrāde (va veikt pēc klašu pamatelementu pielasīšanas (atribūtu skaits, izejošās līnijas))
	forkPrepare(fork_list)
	--virsklašu metriku aprēķināšana (var veikt pēc forkPrepare() apstrādes)
	superClassMetrics()
	-- papildus klases metriku apstrāde
	local p1 -- neizmanto. bija metrika sub_c_ncon_count_wth_atr
	local p2 --nezimanto. bija metrika super_c_ncon_count
	p1, p2= classMetricsContinued(class_list)
		
	--=======================
	-- 4. līniju metriku apstrāde
	--=======================
	-- liniju metriku apstrāde
	lineEvaluation()


	--=======================
	-- 5. klases metriku skaitu summēšana
	--=======================
	for k,v in pairs(l_clases) do
		atributi=atributi+v["c_attributes"]
		virs_atr=virs_atr+v["c_super_atr_gen"]
		paslinijas=paslinijas+v["c_self_lines"]
		virs_linijas=virs_linijas+v["c_super_lines_gen"]
		virs_atr_nep=virs_atr_nep+v["c_super_atr_text"]
		virs_linijas_nep=virs_linijas_nep+v["c_super_lines_text"]
		nos_poz=nos_poz+v["c_name_as_atr"]
		nos_neg=nos_neg+v["c_disjoint_text"]
		nos_restr=nos_restr+v["c_restrictions_as_text"]
		c_connected_class_has_elements=c_connected_class_has_elements+v["c_connected_class_has_elements"]
		c_extended_total=c_extended_total+v["c_super_count"]+v["c_restriction_count"]+v["c_attribute_count"]
	end
	

	local c_res=0
	local c_disj=0
	local c_attrib = 0
	local c_uniq = 0
	local c_extended_unique = 0
	for k,v in pairs(l_clases_extended_name) do
		if v["disjoint"] then
			c_disj=c_disj+1
		end
		if v["attribute"] then
			c_attrib=c_attrib+1
		end
		if v["restriction"] then
			c_res=c_res+1
		end		
		
		if v["restriction"] or v["attribute"] or v["super"] then
			c_extended_unique=c_extended_unique+1
		end
		
		c_uniq=c_uniq+1
	end
	
	--=======================
	-- 6. sagatvo datus attēlošanai
	--=======================
	l_metrics={
		["klases"] = {["count"]=klases, ["koif"]=default_prop["klases"]["koef"]}
		,["linijas"] = {["count"]=linijas, ["koif"]=default_prop["linijas"]["koef"]}
		,["atributi"] = {["count"]=atributi, ["koif"]=default_prop["atributi"]["koef"]}
		,["virs_atr"] = {["count"]=virs_atr, ["koif"]=default_prop["virs_atr"]["koef"]}
		,["virs_atr_nep"] = {["count"]=virs_atr_nep, ["koif"]=default_prop["virs_atr_nep"]["koef"]}
		,["paslinijas"] = {["count"]=paslinijas, ["koif"]=default_prop["paslinijas"]["koef"]}
		,["krustojumi"] = {["count"]=krustojumi, ["koif"]=default_prop["krustojumi"]["koef"]}
		,["lin_viens_x"] = {["count"]=lin_viens_x, ["koif"]=default_prop["lin_viens_x"]["koef"]}
		,["lin_varaiki_x"] = {["count"]=lin_varaiki_x, ["koif"]=default_prop["lin_varaiki_x"]["koef"]}
		,["vispar_lin"] = {["count"]=vispar_lin, ["koif"]=default_prop["vispar_lin"]["koef"]}
		,["virs_linijas"] = {["count"]=virs_linijas, ["koif"]=default_prop["virs_linijas"]["koef"]}
		,["virs_linijas_nep"] = {["count"]=virs_linijas_nep, ["koif"]=default_prop["virs_linijas_nep"]["koef"]}
		--,["nos_poz"] = {["count"]=nos_poz, ["koif"]=default_prop["nos_poz"]["koef"]}
		,["nos_neg"] = {["count"]=nos_neg, ["koif"]=default_prop["nos_neg"]["koef"]}
		--,["nos_restr"] = {["count"]=nos_restr, ["koif"]=default_prop["nos_restr"]["koef"]}
		--,["nos_poz_u"] = {["count"]=c_attrib, ["koif"]=default_prop["nos_poz_u"]["koef"]}
		--,["nos_neg_u"] = {["count"]=c_disj, ["koif"]=default_prop["nos_neg_u"]["koef"]}
		--,["nos_restr_u"] = {["count"]=c_res, ["koif"]=default_prop["nos_restr_u"]["koef"]}
		--,["nos_uniq"] = {["count"]=c_uniq, ["koif"]=default_prop["nos_uniq"]["koef"]}
		--,["sub_c_ncon_count_wth_atr"] = {["count"]=p1, ["koif"]=default_prop["sub_c_ncon_count_wth_atr"]["koef"]}
		--,["super_c_ncon_count"] = {["count"]=p2, ["koif"]=default_prop["super_c_ncon_count"]["koef"]}
		--,["super_c_con_has_elem"] = {["count"]=c_connected_class_has_elements, ["koif"]=default_prop["super_c_con_has_elem"]["koef"]}
		,["extended_class_name_u"] = {["count"]=c_extended_unique, ["koif"]=default_prop["extended_class_name_u"]["koef"]}
		,["extended_class_name_t"] = {["count"]=c_extended_total, ["koif"]=default_prop["extended_class_name_t"]["koef"]}	
		
	}
	--uzstāda lietotāja koeficientus, ja tādi ir
	loadPrevCoef()
	--aprēķina metriku kopsummu balstoties uz koeficentu vērtībām
	for k,v in pairs(l_metrics) do
		l_metrics[k]["sum"]=l_metrics[k]["koif"]*l_metrics[k]["count"]
		total=total+l_metrics[k]["sum"]
	end

end

--metriku apstrāde, kas var tikt veikta pēc vienkāršo metriku aprēķināšanas
function classMetricsContinued(class_list)
	local p1=0
	local p2=0
	local l1={} --saraksta ar virsklasēm
	local l2={} --saraksts ar unikālām apaksklasēm ,uru virskalsēm ir līnija vai atribūti
	for a in class_list do
	
		
		-- klasēm piesaistītais elementu skaits (netieši)
		local super = a:find("/compartment/subCompartment:has(/compartType[id='SuperClasses'])")
		for sup in super do
			local ff_2 = sup:attr("value") or '-'
			local isRestriction, match_end = string.find(ff_2, " only ")
			--asptrāde, ja rstriction ir iteikts kā superklase
			if isRestriction then
				ff_2 = ff_2:sub(match_end+1)
				local p_loc = l_name_clases[ff_2]
				--klase eksistē
				if p_loc ~= nil then
					--total
					l_clases[a:attr("location")]["c_restriction_count"] = l_clases[a:attr("location")]["c_restriction_count"] + 1
					--unique
					if l_clases_extended_name[a:attr("location")] then
						l_clases_extended_name[a:attr("location")]["restriction"] = 1
					else
						l_clases_extended_name[a:attr("location")] = {["restriction"] = 1}
					end
				end
				
			else	
				local p_loc = l_name_clases[ff_2]
				--klase eksistē
				if p_loc ~= nil then
					l_clases[a:attr("location")]["c_super_atr_text"] = l_clases[a:attr("location")]["c_super_atr_text"] + l_clases[p_loc]["c_attributes"]
					l_clases[a:attr("location")]["c_super_lines_text"] = l_clases[a:attr("location")]["c_super_lines_text"] + l_clases[p_loc]["c_lines_from"]
					
					--nepiesasitīto virsklašu skaits
					l1[p_loc]=1
					--nepiesasito apakšaklšu sakits, kurām virsklaše ir norādīts kuat viens atribūts
					--if l_clases[p_loc]["c_attributes"]>0 or l_clases[p_loc]["c_lines_from"]>0 then
						--unique
						l2[a:find("/compartment:has(/compartType[id='Name'])"):attr("value")]=1
						
						--atzīmē ka klase ir tesktuālā formā definētā kā virsklase
						
						if l_clases_extended_name[p_loc] then
							l_clases_extended_name[p_loc]["super"] = 1
						else
							l_clases_extended_name[p_loc] = {["super"] = 1}
						end
						
						--total
						l_clases[a:attr("location")]["c_super_count"] = l_clases[a:attr("location")]["c_super_count"] + 1
					--end
					
				end
			end
		end
		
		--klases nosaukums kā atribūts
		local as_atr = a:find("/compartment/subCompartment:has(/compartType[id='Attributes'])")
		for t in as_atr do
			local asd = t:find("/subCompartment/subCompartment:has(/compartType[id='Type'])"):attr("value")
			--print("ATR: "..asd)
			local p_loc = l_name_clases[asd]
			if p_loc ~= nil then
				
				if l_clases[a:attr("location")]["c_name_as_atr"] then
					l_clases[a:attr("location")]["c_name_as_atr"] = l_clases[a:attr("location")]["c_name_as_atr"] + 1
				else
					l_clases[a:attr("location")]["c_name_as_atr"]=1
				end
				--atzīmē, ka klase ir izmantota kā atribūta tips
				if l_clases_extended_name[a:attr("location")] then
					l_clases_extended_name[a:attr("location")]["attribute"] = 1
				else
					l_clases_extended_name[a:attr("location")] = {["attribute"] = 1}
				end
				if l_clases[a:attr("location")]["c_attribute_count"] then
					l_clases[a:attr("location")]["c_attribute_count"] = l_clases[a:attr("location")]["c_attribute_count"] + 1
				else
					l_clases[a:attr("location")]["c_attribute_count"] = 1
				end
			end
		end
		
		--klases nosaukums disjoint sarakstā
		local dis = a:find("/compartment/subCompartment:has(/compartType[id='DisjointClasses'])")
		for r in dis do
			local ff_1 = r:attr("value") or '-'
			local p_loc = l_name_clases[ff_1]
			if p_loc ~= nil then
				l_clases[a:attr("location")]["c_disjoint_text"] = l_clases[a:attr("location")]["c_disjoint_text"] + 1
				--atzīmē ka klase ir izmantota disjoint sarakstā
				if l_clases_extended_name[a:attr("location")] then
					l_clases_extended_name[a:attr("location")]["disjoint"] = 1
				else
					l_clases_extended_name[a:attr("location")] = {["disjoint"] = 1}
				end
			end
		end
		
	end
	
	--[[
	--novecojuās/neizmantotas metrikas
	for k,v in pairs(l1) do
		p1=p1+1
	end
	
	for k,v in pairs(l2) do
		p2=p2+1
	end
	--]]
	return p1, p2
end

--vispārinošo klašu metrikas
function superClassMetrics()
	-- klasēm pierakssta virsklašu elementu skaitus (fork)
	local asoc_to_fork = v_diagram:find("/element:has(/elemType[id='AssocToFork'])")
	for a in asoc_to_fork do 
		l_clases[a:find("/start"):attr("location")]["c_super_atr_gen"]=l_forks[a:find("/end"):attr("location")]["c_class_atr"]
		l_clases[a:find("/start"):attr("location")]["c_super_lines_gen"]=l_forks[a:find("/end"):attr("location")]["c_class_lines"]
		l_clases[a:find("/start"):attr("location")]["c_connected_class_has_elements"]=l_forks[a:find("/end"):attr("location")]["c_connected_class_has_elements"]
	end
	
	-- klasēm piesaistīts elementu skaits (tieši)
	local l_gen = v_diagram:find("/element:has(/elemType[id='Generalization'])") 
	for a in l_gen do
		l_clases[a:find("/start"):attr("location")]["c_super_atr_gen"]=l_clases[a:find("/start"):attr("location")]["c_super_atr_gen"]+l_clases[a:find("/end"):attr("location")]["c_attributes"]
		l_clases[a:find("/start"):attr("location")]["c_super_lines_gen"]=l_clases[a:find("/start"):attr("location")]["c_super_lines_gen"]+l_clases[a:find("/end"):attr("location")]["c_lines_from"]
		if l_clases[a:find("/end"):attr("location")]["c_lines_from"]>0 or l_clases[a:find("/end"):attr("location")]["c_attributes"]>0 then
			l_clases[a:find("/start"):attr("location")]["c_connected_class_has_elements"]=l_clases[a:find("/start"):attr("location")]["c_connected_class_has_elements"]+1
		end
		--print("--end atr: "..)
	end
end

--fork elementu apstrāde
function forkPrepare(fork_list)
	-- fork elementi. rezultāta tiek iegūts katra fork elementa virsklašu elementu skaiti un to var izmantot, lai noteiktu tieši pakārtoto klašu virsklašu elementu skaitus
	for a in fork_list do
		local sum_a = 0 --fork saistīto virsklašu atribūtu skaits
		local sum_l = 0 --fork sasitīto virsklašu līniju skaits
		local sum_r = 0 --fork sasitīto virsklašu restriction līnijas, kas izteitkas tekstuāli skaits
		local sum_class_has_elemtns = 0 --fork sasitīto virsklašu skaits, kurām ir izejošās līnijas vai atribūti
		
		--fork elementiem saskaita virsklašu atribūtus un sagalbā
		local gen = v_diagram:find("/element:has(/elemType[id='GeneralizationToFork']):has(/start[location='"..a:attr("location").."'])")
		for b in gen do
			sum_a = sum_a + l_clases[b:find("/end"):attr("location")]["c_attributes"]
			sum_l = sum_l + l_clases[b:find("/end"):attr("location")]["c_lines_from"]
			sum_r = sum_r + l_clases[b:find("/end"):attr("location")]["c_restrictions_as_text"]
			if l_clases[b:find("/end"):attr("location")]["c_attributes"] > 0 then
				sum_class_has_elemtns = sum_class_has_elemtns + 1
			elseif l_clases[b:find("/end"):attr("location")]["c_lines_from"] then
				sum_class_has_elemtns = sum_class_has_elemtns + 1
			end
		end
		l_forks[a:attr("location")]["c_class_atr"]=sum_a
		l_forks[a:attr("location")]["c_class_lines"]=sum_l
		l_forks[a:attr("location")]["c_restrictions_as_text"]=sum_r
		l_forks[a:attr("location")]["c_connected_class_has_elements"]=sum_class_has_elemtns
	end
end

--līniju skaits
function countLines()
	local v_line = v_diagram:find("/element/eStart")
	for a in v_line 
	do 
		linijas = linijas + 1 
	end
end

--struktūru aizpildīšana
function populateTables()
	-- atrod diagrammu
	--v_diagram = utilities.active_elements():find("/graphDiagram")
	v_diagram=utilities.current_diagram()
	-- elementus identificē pēc atrašanās vietas diagrammā, jo koordinātas nevar sakrist
	-- klases elementi
	local class_list = v_diagram:find("/element:has(/elemType[id='Class'])")
	for a in class_list do
		l_clases[a:attr("location")] = {["location"]=a:attr("location")}
		l_name_clases[a:find("/compartment:has(/compartType[id='Name'])"):attr("value")]=a:attr("location")
		
		-- atribūtu tipi var būt klases nosaukumi
		l_atribute_type[a:find("/compartment:has(/compartType[id='Name'])"):attr("value")]=0	
	end
	-- tas pats ar fork elementiem
	local fork_list = v_diagram:find("/element:has(/elemType[id='HorizontalFork'])") 
	for a in fork_list do
		l_forks[a:attr("location")] = {["location"]=a:attr("location")}
	end	
	return class_list, fork_list
end


--liniju apstrāde
function lineEvaluation()
	local l_lines_point = {}
	local l_line = v_diagram:find("/element/eStart")
	for a in l_line do
		local p_loc = a:attr("location")
		p_loc = p_loc:gsub("\\","|")
		p_loc=p_loc:sub(3)
		local splitted = mysplit(p_loc, "|")
			--print(p_loc)
			--printTableHelper(splitted)
		-- līnijas locījumu skaits
			-- līniju ar vienu locījumu raksturo vērtība 3, jo:
				-- sākums  - beigas = 2
				-- viens locījums =1
		local c_loc = #splitted
		if c_loc>3 then
			lin_varaiki_x=lin_varaiki_x+1
		elseif c_loc==3 then
			lin_viens_x=lin_viens_x+1
		end
		
		--krustpunkti
		local points12 = {}
		local points34 = {}
		local x1=0
		local y1=0
		local x2=0
		local y2=0
		local x3=0
		local y3=0
		local x4=0
		local y4=0
		--iet caur visiām apstrādātjām līnijām
		for k,v in pairs(l_lines_point) do
			--iet caur visām apstrāda'to līniju apakšlīnijām
			for kk, vv in pairs (v) do
				-- ja ir pirmais punkts, tad tikai aizplda sākuma vērtības
				points12=mysplit(vv, ",")
				if kk==1 then
					x1=points12[1]
					y1=points12[2]
				else
					x2=points12[1]
					y2=points12[2]
					
					-- salīdzina ar jaunajām apakšlīnijām
					for kkk, vvv in pairs(splitted) do
						points34=mysplit(vvv, ",")
						if kkk==1 then
							x3=points34[1]
							y3=points34[2]
						else
							x4=points34[1]
							y4=points34[2]
							
							--atrod krustpunktus
							krustojumi = krustojumi + checkCross(x1,y1,x2,y2,x3,y3,x4,y4)
							
							--pārbīda punktus
							x3=x4
							y3=y4
						end						
					end
					
					--pārbīda punktus
					x1=x2
					y1=y2
				end
			end
		end
		
		--sagatvo līniju krustpunktu skaita noteikšanas tabulu
		table.insert(l_lines_point, splitted)
	end
end


-- nosaka, vai līnijas krustojas
function checkCross(a, b, c, d, e, f, g, h)
	local first = 0
	local second  = 0
	local cross_x=0
	local cross_y=0

	local x1 = tonumber(a)
	local y1 = tonumber(b)
	local x2 = tonumber(c)
	local y2 = tonumber(d)
	local x3 = tonumber(e)
	local y3 = tonumber(f)
	local x4 = tonumber(g)
	local y4 = tonumber(h)

	
	if x1==x2 then
		first=1
	elseif y1==y2 then
		first=2
	end
	
	if x3==x4 then
		second=1
	elseif y3==y4 then
		second=2
	end
	
	if first==second then
		--līnijas ir paralēlas
		return 0
	end
	
	--print(first..":"..second)
	--print(x1..","..y1.."	"..x2..","..y2)
	--print(x3..","..y3.."	"..x4..","..y4)
	
	if first == 1 then
		if (x3<x1 and x4>x1) or (x3>x1 and x4<x1) then
			cross_x=1
		end
		if (y1<y3 and y2>y3) or (y1>y3 and y2<y3) then
			cross_y=1
		end
	else
		if (x1<x3 and x2>x3) or (x1>x3 and x2<x3) then
			cross_x=1
		end
		if (y1>y3 and y1<y4) or (y1<y3 and y1>y4) then
			cross_y=1
		end
	end
	
	if cross_x == 1 and cross_y==1 then
		return 1
	else 
		return 0
	end
	
end

-- klases izejošo līniju skaits
function classLinesFromCount(p_class)
	local c_count = 0
	local line_list = v_diagram:find("/element/eStart:has(/start[location='"..p_class:attr("location").."'])")
	for a in line_list do
		c_count = c_count + 1
	end
	return c_count
end

-- klases pašlīniju skaists
function selfLineCount(p_class)
	local c_count = 0
	local line_list = v_diagram:find("/element/eStart:has(/start[location='"..p_class:attr("location").."']):has(/end[location='"..p_class:attr("location").."'])")
	for a in line_list do
		c_count = c_count + 1
	end
	return c_count
end

-- nosaka vispārinošo līniju skaitu. atzīmē ka klase ir izmantota kā virskalse
function generalzionCount ()
	local g_list = v_diagram:find("/element:has(/elemType[id='Generalization'])") 
	local g_list_fork = v_diagram:find("/element:has(/elemType[id='GeneralizationToFork'])")
	local c_count = 0
	for a in g_list do
		c_count = c_count + 1
				
	end
	for a in g_list_fork do
		c_count = c_count + 1		
	end	
	return c_count
end

--klases atribūtu skaits
function classAtrCount(p_class)
	local c_atr = 0
	local v_atr = p_class:find("/compartment/subCompartment:has(/compartType[id='Attributes'])")
	--local v_atr = p_class:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousAttributes'])")
		for a in v_atr do 
			if  not (a:attr("value") == nil or a:attr("value") == '') then
				c_atr = c_atr + 1 
				--print("atr: " .. a:attr("value"))	
			end
		end
			--print("--ATR: "..c_atr)
	return c_atr
end


function loadPrevCoef()
	local path=project_path_coef.."\\last_used.json"
	file = io.open(path, "r")
	if file == nil then return end
	while true do 
		line = file:read()
        if line == nil then break end
		if line ~= "{" and line ~= "}" then
			line = line:gsub("\"", "")
			line = line:gsub("\t", "")
			line = line:gsub(",", "")
			split = mysplit(line, ":")
			if l_metrics[split[1]] ~= nil and tonumber(split[2])~=nil then
				l_metrics[split[1]]["koif"]=tonumber(split[2])
			end	
		end
	end
	file:close()
end

--=================
-- Attēlošana
--=================

--grafiskā loga pamatelements
local form

--izveido grafisko leitotāja saskarni
function showDialog()
	calculateMetrics()
	
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.VisualMetrics.visualMetrics.close()")
  })
  
  local save_coef_button = lQuery.create("D#Button", {
    caption = "Save"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.VisualMetrics.visualMetrics.saveCoef()")
  })
  
  local load_default_coef_button = lQuery.create("D#Button", {
    caption = "Load default"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.VisualMetrics.visualMetrics.loadDefaultCoef()")
  })

  local load_coef = lQuery.create("D#Button", {
    caption = "Load"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.VisualMetrics.visualMetrics.ChoseCoefFile()")
  })
  
  form = lQuery.create("D#Form", {
    id = "qEval"
    ,caption = "Visual Metrics"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.VisualMetrics.visualMetrics.close()")
	,component = {	
		lQuery.create("D#HorizontalBox", {
			id = "HorForm"
			,minimumWidth = 300
			,component = { 
				lQuery.create("D#Row", { bottomMargin = 7, component={
					lQuery.create("D#Label", {caption="Metric"})
					,lQuery.create("D#Label", {caption="Coefficent"})
					,lQuery.create("D#Label", {caption="Count"})
					,lQuery.create("D#Label", {caption="Value"})
				}}),
				createRowsForViews()
			}
		}),
		lQuery.create("D#HorizontalBox", {

			id = "total"
			,minimumWidth = 300
			--,topMargin = 7
			,component = { 

				lQuery.create("D#Row", {id='tot_1', component={
					lQuery.create("D#Label", {caption="Total:"})
					,lQuery.create("D#Label", {caption=total, id="tot"})}})


			}
		}),
		lQuery.create("D#HorizontalBox", {
		-- horizontalAlignment = 1
		id = "actions"
		,topMargin = 7
		,component = {
		  load_coef,
		  load_default_coef_button,
		  save_coef_button			  
		  }
	  }),
		lQuery.create("D#HorizontalBox", {
			-- horizontalAlignment = 1
			id = "closeForm"
			--,topMargin = 15
			,component = {
			  
			  close_button			  
			  }
		  })
    }
  })
  
  setInactive(form)
  dialog_utilities.show_form(form)
	--print("end")
end

--veic darības, kas sasitītas ar loga aizvēršanu
function close()
  --saglabā koeficientus
  writeCoefToFile(lQuery("D#Event/source/container/container"):find("/component[id='HorForm']/component/component[type_1=koef]"), project_path_coef.."\\last_used.json")
  lQuery("D#Event"):delete()
  utilities.close_form("qEval")
end

--padara koeficientu laukus nerediģējamus, ja attiecigā metrika nav fiskēta
function setInactive(form)
	local koef = form:find("/component[id='HorForm']/component[type_1=my_row]")
	for a in koef do
		if tonumber(a:find("/component[type_1=count]"):attr("caption")) == 0 then
			a:find("/component[type_1=koef]"):attr({readOnly=true})
		end
	end
end

--izveido metriku rindas
function createRowsForViews()
	return map_table(l_metrics, function(obj, k) 
		local checked
		if default_prop[k] == nil then
			return lQuery.create("D#VerticalBox", {component={
					lQuery.create("D#Label", {caption=k})
				}})
		else
			return lQuery.create("D#Row", {id="r_"..k, type_1="my_row", component={
				lQuery.create("D#Label", {caption=default_prop[k]["alias"]})
				,lQuery.create("D#InputField", {
					id = k
					--,width = 20
					,type_1="koef"
					,text = obj["koif"]
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.VisualMetrics.visualMetrics.changed()")}
				})
				,lQuery.create("D#Label", {caption=obj["count"], id="c_"..k, type_1="count",leftMargin = 17})
				,lQuery.create("D#Label", {caption=obj["sum"], id="l_"..k, type_1 = "sum",leftMargin = 7})

			}})
		end
	end)
end

--apstrādā notikumu, kad viektas izmaiņas koefcienta laukā
function changed()
	local id = lQuery("D#Event/source"):attr("id")
	local val = lQuery("D#Event/source/container/container/container") --qEval
	local v_total = val:find("/component[id ='total' ]/component[id ='tot_1']/component[id='tot']")
	-- rinda
	local row = val:find("/component[id='HorForm']/component[id=".."r_"..id.."]")
	--koef
	local koef = val:find("/component[id='HorForm']/component[id=".."r_"..id.."]/component[id=".."l_"..id.."]")
	--skaits
	local num = tonumber(row:find("/component[id="..id.."]"):attr("text"))
	if num ~= nil then
		--atjauno metrikas summu
		--koef:attr({caption=row:find("/component[id=".."c_"..id.."]"):attr("caption")*row:find("/component[id="..id.."]"):attr("text")})
		calculateMertric(val, id)
		--atjauno kopējo summu
		calculateTotal(val)

	else
		koef:attr({caption=0})
		v_total:attr({caption=0})

	end
	dialog_utilities.refresh_form_component(koef)
	dialog_utilities.refresh_form_component(v_total)
end

--apstrādā pogas Save nospiešanas notikumu 
function saveCoef()
	local a = "-"
	local typeIndex = nil
	a, typeIndex = tda.BrowseForFile("Save", fileTypeString, project_path_coef or "", "", true)
	if a and a~="" and a~=" " then
		local koefs = lQuery("D#Event/source/container/container"):find("/component[id='HorForm']/component/component[type_1=koef]")
		writeCoefToFile(koefs, a)	
	end
end

--apstrādā pogas Load nospiešanas notikumu
function ChoseCoefFile() 
	local a = "-"
	local typeIndex = nil
	a, typeIndex = tda.BrowseForFile("Open", fileTypeString, project_path_coef or "", "", false)
	if a and a~="" and a~=" " then
		local val = lQuery("D#Event/source/container/container")
		loadCoefFromFile(a, val)	
	end
end

--apstrādā pogas Load default nospiešanas notikumu
function loadDefaultCoef()
	local val = lQuery("D#Event/source/container/container") --qEval
	--print("ID: "..val:attr("id"))
	for k, v in pairs(default_prop) do
		val:find("/component[id='HorForm']/component/component[id="..k.."]"):attr({text=v["koef"]})
		calculateMertric(val, k)
	end
	calculateTotal(val)
	dialog_utilities.refresh_form_component(val)
end

--============
-- Dialoga logā izmantotās aprēķina funckijas
--============

--iegūst vienas metrikas summu
function calculateMertric(val, id)
	local row = val:find("/component[id='HorForm']/component[id=".."r_"..id.."]")
	local koef = val:find("/component[id='HorForm']/component[id=".."r_"..id.."]/component[id=".."l_"..id.."]")
	
	local a  = row:find("/component[id=".."c_"..id.."]"):attr("caption") or '-'
	local b = row:find("/component[id="..id.."]"):attr("text") or '-'
	--print(id)
	--print(a)
	--print(b)
	
	koef:attr({caption=row:find("/component[id=".."c_"..id.."]"):attr("caption")*row:find("/component[id="..id.."]"):attr("text")})

end
--iegūst metriku kopējo summu
function calculateTotal(val)
	local sum=0
	local sums = val:find("/component[id='HorForm']/component/component[type_1=sum]")
	for a in sums do
		sum=sum+tonumber(a:attr("caption"))
		--print(a:attr("caption"))
	end
	local v_total = val:find("/component[id ='total' ]/component[id ='tot_1']/component[id='tot']")
	v_total:attr({caption=sum})
end

--saglabā koefcientu vērtības norādītajā failā
function writeCoefToFile(koefs, path)
	--local path=tda.GetProjectPath().."\\Plugins\\VisualMetrics\\coefficients\\last_used.json"
	file = io.open(path, "w+")
	--local val = lQuery("D#Event/source/container/container") --qEval
	--local koefs = val:find("/component[id='HorForm']/component/component[type_1=koef]")
	local nr = 0
	if file == nil then
		return
	end
	
	file:write("{\n")
	for a in koefs do
		num=tonumber(a:attr("text"))
		if num == nil then
			num=0
		end
		if nr==0 then
			nr=1
		else
			file:write(",\n")
		end
		file:write("\t\""..a:attr("id").."\":"..num)
	end
	file:write("\n}")
	file:close()
end

--veic norādīto koeficnetu vērtību ielādi
function loadCoefFromFile(file_path, val)
	local par = {}
	local koefs = val:find("/component[id='HorForm']/component/component[type_1=koef]")
	file = io.open(file_path, "r")
	if file == nil then return end
	while true do 
		line = file:read()
        if line == nil then break end
		if line ~= "{" and line ~= "}" then
			line = line:gsub("\"", "")
			line = line:gsub("\t", "")
			line = line:gsub(",", "")
			split = mysplit(line, ":")
			par[split[1]]=split[2]
			
		end
	end
	for a in koefs do
		if par[a:attr("id")] ~= nil then
			a:attr({text=par[a:attr("id")]})
			calculateMertric(val, a:attr("id"))
		end
	end
	calculateTotal(val)
	dialog_utilities.refresh_form_component(val)
	file:close()
end



--==============
-- Palīgfunkcijas
--==============

-- string sadalīšanas palīgfunkcija
function mysplit(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end

--tabulas izprintēsānas funkcija
function printTableHelper(t,spacing)
	local spacing = spacing or ''
    if type(t)~='table' then
        print(spacing..tostring(t))
    else
        for k,v in pairs(t) do
            print(spacing..tostring(k),v)
            if type(v)=='table' then 
                printTableHelper(v,spacing..'\t')
            end
        end
    end
end

--tabulas map palīgfunkcija
function map_table(tbl, f)
    local t = {}
    --for k,v in pairs(tbl) do
    --    table.insert(t, f(v, k))
    --end
	for k, v in pairs(order) do 
		table.insert(t, f(tbl[v],v))
	end
    return t
end
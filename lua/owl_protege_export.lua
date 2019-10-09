module(..., package.seeall)

require "socket"

function export_data(ip, port, ontology_data_array)
  local tcp = assert(socket.tcp())
  assert(tcp:connect(ip, port))
  
  local array_to_serialize = {}
  for _, ontology_data in ipairs(ontology_data_array) do
    table.insert(array_to_serialize, {
      ontology = ontology_data.ontology,
      expressions = ontology_data.expressions or {},
      ontology_uri = ontology_data.ontology_uri or "",
      ontology_import_iris = ontology_data.ontology_import_iris or {}
    })
  end
  
  data_to_send = serialize_to_clojure_string_form(array_to_serialize)
  
  assert(tcp:send(data_to_send))
end

function export_test()
  -- local ip, port = "172.16.55.1", 1234
  local ip, port = "127.0.0.1", 1234
  log("protege send test start")

  str = [[
  Prefix(:=<http://lumii.lv/test.owl#>)

  Ontology(<http://lumii.lv/test.owl>
  Declaration(Class(:A))
  Declaration(Class(:B))
  Declaration(Class(:C))
  
  Declaration(NamedIndividual(:ind))
  
  Declaration(ObjectProperty(:b_c))
  ObjectPropertyDomain(:b_c :A)
  ObjectPropertyRange(:b_c ObjectUnionOf(:B :C))
  
  Declaration(ObjectProperty(:prop1))
  Declaration(ObjectProperty(:prop2))
  
  Declaration(DataProperty(:attr1))
  
  Declaration(Datatype(:dt))
  )

]]
  export_data(ip, port, {
    ontology_uri = "http://lumii.lv/test.owl",
    ontology = str,
    ontology_import_iris = {"http://lumii.lv/imported_test.owl"},
    expressions = {
      OWLDatatype = {
        OWLDatatypeDefinitionAxiom = {
          {"http://lumii.lv/test.owl#dt", "integer[< 5]"}
        }
      },
      
      OWLClass = {
        OWLSubClassOfAxiom = {
          {"http://lumii.lv/test.owl#A", "prop1 only (C or B) "},
          {"http://lumii.lv/test.owl#C", "Nothing"}
        },
        OWLDisjointClassesAxiom = {
          {"http://lumii.lv/test.owl#B", "C or Nothing"}
        },
        OWLEquivalentClassesAxiom = {
          {"http://lumii.lv/test.owl#A", "B"}
        }
      },
      OWLNamedIndividual = {
        OWLClassAssertionAxiom = {
          {"http://lumii.lv/test.owl#ind", "Thing"}
        }
      },
      
      OWLObjectProperty = {
        OWLObjectPropertyDomainAxiom = {
          {"http://lumii.lv/test.owl#prop2", "prop1 some B"},
          {"http://lumii.lv/test.owl#prop2", "prop1 max 2 A or Nothing"}
        },
        OWLObjectPropertyRangeAxiom = {
          {"http://lumii.lv/test.owl#prop2", "prop1 some A"}
        }
      },
      OWLDataProperty = {
        OWLDataPropertyDomainAxiom = {
          {"http://lumii.lv/test.owl#attr1", "prop1 min 3 A"}
        },
        OWLDataPropertyRangeAxiom = {
          {"http://lumii.lv/test.owl#attr1", "not(int)"},
          {"http://lumii.lv/test.owl#attr1", "integer[< 5]"}
        }
      }
    }
  })
  log("send test done")
end


function serialize_to_clojure_string_form(t)
  local stringify = {
    -- Keys are all possible strings that type() may return,
    -- per http://www.lua.org/manual/5.1/manual.html#pdf-type.
    ["nil"]       = function(v) return "nil" end,
    ["string"]    = function(v) return string.format("%q", v) end,
    ["number"]    = function(v) return tostring(v) end,
    ["boolean"]   = function(v) return tostring(v) end,
    ["function"]  = function(v) error("cannot serialize to clojure a " .. type(v)) end,
    ["thread"]    = function(v) error("cannot serialize to clojure a " .. type(v)) end,
    ["userdata"]  = function(v) error("cannot serialize to clojure a " .. type(v)) end
  }
  
  local function to_clojure(v)
    return stringify[type(v)](v)
  end
  
  local function is_array(t)
  	if #t == 0 then
  	  return false
  	end
  	
  	local is_index = function(k)
  		if type(k) == "number" and k > 0 then
  			if math.floor(k) == k then
  				return true
  			end
  		end
  		return false
  	end
  	for k,v in pairs(t) do
  		if not is_index(k) then
  			return false
  		end
  	end
  	return true
  end
  
  stringify["table"] = function(v)
    local results = {}
    
    if is_array(v) then
      for _, val in ipairs(v) do
        table.insert(results, to_clojure(val))
      end
      return "[" .. table.concat(results, " ") .. "]"
    else
      for key, val in pairs(v) do
        table.insert(results, to_clojure(key) .. " " .. to_clojure(val))
      end
      return "{" .. table.concat(results, " ") .. "}"
    end
  end
  
  return to_clojure(t)
end


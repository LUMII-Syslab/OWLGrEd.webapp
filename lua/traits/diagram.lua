module(..., package.seeall)

require "utilities"

local element_traits = require "traits/element"


local traits = {}


-- ------
-- diagram traits
-- ------

function traits.type (self)
  return self:find("/graphDiagramType")
end

-- Diagram operations --

function traits.excute_cmd (self, command_class_name, features)
  features = features or {}
  features["graphDiagram"] = self
  
  utilities.execute_cmd(command_class_name, features)
  
  return self
end

function traits.open (self)
  return self:each(utilities.open_diagram)
end

function traits.close (self)
  return self:each(utilities.close_diagram)
end

function traits.set_caption (self, caption)
  return self
          :attr("caption", caption)
          :excute_cmd("UpdateDgrCmd")
end

function traits.get_caption (self)
  return self:attr("caption")
end

-- Element selection --

function traits.elements (self)
  return self
          :find("/element")
            :mixin(element_traits)
            :set_checkpoint(self)
end

function traits.elements_by_type_id (self, type_id_str)
  return self
          :elements()
            :filter_has_links_to_some("elemType",
                                      self
                                        :type()
                                          :find("/elemType[id='" .. type_id_str .. "']"))
              :set_checkpoint(self)
end

function traits.selected_elements (self)
  return self
          :elements()
            :filter_has_links_to_some("collection", self:find("/collection"))
              :set_checkpoint(self)
end


-- Element creation --

function traits.add_element (self)
  
end



return traits
module(..., package.seeall)

require "utilities"

local diagram_traits = require "traits/diagram"


local traits = {}


-- ------
-- project traits
-- ------

function traits.active_diagram (self)
  return utilities
          .current_diagram()
            :mixin(diagram_traits)
            :set_checkpoint(self)
end

function traits.diagrams (self)
  return self
          :find("GraphDiagram")
            :mixin(diagram_traits)
            :set_checkpoint(self)
end

function traits.diagrams_by_type_id (self, type_id_str)
  return self
          :diagrams()
            :filter_has_links_to_some("graphDiagramType",
                                       self
                                        :type()
                                          :find("/graphDiagramType[id='" .. type_id_str .. "']"))
              :set_checkpoint(self)
end

function traits.diagrams_with_caption (self, caption)
  return self
          :diagrams()
            :filter_attr_value_equals("caption", caption)
              :set_checkpoint(self)
end



return traits
module(..., package.seeall)

local diagram_traits = require "traits/diagram"
local compartment_traits = require "traits/compartment"


local traits = {}


-- ------
-- element traits
-- ------

function traits.diagram (self)
  return self
          :find("/graphDiagram")
            :mixin(diagram_traits)
end

function traits.activate (self)
  self
    :diagram()
      :excute_cmd("ActiveElementCmd",
                  {element = self})
  return self
end

function traits.compartments (self)
  return self
          :find("/compartment")
            :mixin(compartment_traits)
            :set_checkpoint(self)
end

function traits.compartments_by_type_id (self, type_id_str)
  return self
          :compartments()
            :filter_has_links_to_some("compartType",
                                      self
                                        :type()
                                          :find("/compartType[id='" .. type_id_str .. "']"))
              :set_checkpoint(self)
end

function traits.type (self)
  return self:find("/elemType")
end



return traits
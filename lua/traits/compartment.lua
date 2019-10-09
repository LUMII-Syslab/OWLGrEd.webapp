module(..., package.seeall)


local traits = {}


-- ------
-- compartment traits
-- ------

function traits.get_value (self)
  return self:attr("value")
end

function traits.set_value (self, value)
  self:attr("value", value)
  return self
end

function traits.compartments (self)
  return self
          :find("/subCompartment")
            :mixin(traits)
            :set_checkpoint(self)
end

function traits.compartments_by_type_id (self, type_id_str)
  return self
          :compartments()
            :filter_has_links_to_some("subCompartType",
                                      self
                                        :type()
                                          :find("/subCompartType[id='" .. type_id_str .. "']"))
              :set_checkpoint(self)
end

function traits.type (self)
  return self:find("/compartType")
end



return trait
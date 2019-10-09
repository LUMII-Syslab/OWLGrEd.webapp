module(..., package.seeall)

--[[
{
	graph_diagram_type_id_1 = {
		elem_type_id_1 = {
			{
				compart_type_id = name_1,
				field_type = "input_field",
				caption = caption_1
			},
			{
				compart_type_id = name_2,
				field_type = "check_box",
				caption = caption_2
			}
		}
	}

	
}
--]]

function property_diagram_defs_in_table_form()
  local result = {}
  local diagram_types = lQuery('GraphDiagramType:has(/elemType/propertyDiagram:has(/propertyRow,/propertyTab/propertyRow))')
  for diagram_type in diagram_types do
    local diagram_type_id = diagram_type:attr('id')

    assert(type(diagram_type_id) == "string" and diagram_type_id ~= "")


    for elem_type in diagram_type:find('/elemType:has(/propertyDiagram:has(/propertyRow,/propertyTab/propertyRow))') do
      local local_elem_type_id = elem_type:attr('id')
      assert(type(local_elem_type_id) == "string" and local_elem_type_id ~= "")

      local absolute_elem_type_id = string.format("%s.%s", diagram_type_id, local_elem_type_id)

      local property_rows = {}

      for property_row in elem_type:find('/propertyDiagram'):find('/propertyRow,/propertyTab/propertyRow') do
        local local_compart_type_id = property_row:find('/compartType'):assert_not_empty():attr('id')
        assert(type(local_compart_type_id) == "string" and local_compart_type_id ~= "")

        local absolute_compart_type_id = string.format("%s.%s", absolute_elem_type_id, local_compart_type_id)

        table.insert(property_rows, {
          row_type = property_row:attr('rowType'),
          compart_type_id = absolute_compart_type_id,
          caption = property_row:attr('caption'),
          choice_items = property_row:find('/compartType/choiceItem'):map(function(ci) return ci:attr('value') end),
        })
      end

      result[absolute_elem_type_id] = property_rows

    end
  end

  return result
end
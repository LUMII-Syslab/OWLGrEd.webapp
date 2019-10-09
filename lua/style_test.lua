module(..., package.seeall)

require("mii_rep_obj")
-- mii_rep_obj.add_property("Compartment", "isGroup", mii_rep_obj.property_base_type.boolean)


function create_or_get_test_data()
  -- get a test diagram
  dgr = lQuery("GraphDiagram[id=style_test]")

  -- if the test diagram dosn't exist, create a test diagram with some style
  if dgr:is_empty() then
    dgr = lQuery.create("GraphDiagram", {
      caption = "style test",
      id = "style_test",
      graphDiagramType = lQuery.create("GraphDiagramType", {
        caption = "style test diagram style"
      })
    })
  end

  utilities.open_diagram(dgr)

  -- get a test node
  node = dgr:find("/element[id=node_test]")

  if node:is_empty() then
    node = lQuery.create("Node", {
      id = "node_test",
      graphDiagram = dgr,
      elemStyle = lQuery.create("NodeStyle", {

      }),
      compartment = {
        -- name compartment
        lQuery.create("Compartment", {
          input = "P#A",
          compartStyle = lQuery.create("CompartStyle", {
            caption = "name",
            fontStyle = 1, -- bold
          }),
          subCompartment = {
            lQuery.create("Compartment", {
              input = "P",
            }),
            lQuery.create("Compartment", {
              input = "A",
            })
          }
        }),

        -- attr group compartment
        lQuery.create("Compartment", {
          input = "attr1:String\nattr2:Bool",
          isGroup = true,
          compartStyle = lQuery.create("CompartStyle", {
            caption = "attr group",

          }),
          subCompartment = {
            --attr1
            lQuery.create("Compartment", {
              input = "attr1:String",
              compartStyle = lQuery.create("CompartStyle", {
                caption = "attr1-style",
                fontColor = "255"
              }),
              subCompartment = {
                lQuery.create("Compartment", {
                  input = "attr1",
                }),
                lQuery.create("Compartment", {
                  input = "String",
                })
              }
            }),

            --attr2
            lQuery.create("Compartment", {
              input = "attr2:Bool",
              compartStyle = lQuery.create("CompartStyle", {
                caption = "attr2-style",
                fontColor = "16711680"
              }),
              subCompartment = {
                lQuery.create("Compartment", {
                  input = "attr2",
                }),
                lQuery.create("Compartment", {
                  input = "Bool",
                })
              }
            })
          }
        }),
      }
    })
  end

  -- get a test node
  edge = dgr:find("/element[id=edge_test]")

  if edge:is_empty() then
    edge = lQuery.create("Edge", {
      id = "edge_test",
      graphDiagram = dgr,
      elemStyle = lQuery.create("EdgeStyle", {

      }),
      ["start"] = node,
      ["end"] = lQuery.create("Node", {
        id = "node2_test",
        graphDiagram = dgr,
        elemStyle = lQuery.create("NodeStyle", {

        })
      }),
      compartment = {
        -- start name compartment
        lQuery.create("Compartment", {
          input = "Start#A",
          compartStyle = lQuery.create("CompartStyle", {
            caption = "start name",
            adjustment = 1 + 4, -- start, left
            fontStyle = 1, -- bold
          }),
          subCompartment = {
            lQuery.create("Compartment", {
              input = "Start",
            }),
            lQuery.create("Compartment", {
              input = "A",
            })
          }
        }),

        -- end name compartment
        lQuery.create("Compartment", {
          input = "End#A",
          compartStyle = lQuery.create("CompartStyle", {
            caption = "end name",
            adjustment = 2 + 8, -- end, right
            fontStyle = 1, -- bold
          }),
          subCompartment = {
            lQuery.create("Compartment", {
              input = "End",
            }),
            lQuery.create("Compartment", {
              input = "A",
            })
          }
        }),


        -- start attr group compartment
        lQuery.create("Compartment", {
          input = "s_attr1:String\ns_attr2:Bool",
          isGroup = true,
          compartStyle = lQuery.create("CompartStyle", {
            caption = "start attr group",
            adjustment = 1 + 8, -- start, right
          }),
          subCompartment = {
            -- start attr1
            lQuery.create("Compartment", {
              input = "s_attr1:String",
              compartStyle = lQuery.create("CompartStyle", {
                caption = "s_attr1-style",
                fontColor = "255",
                adjustment = 1 + 8, -- start, right
              }),
              subCompartment = {
                lQuery.create("Compartment", {
                  input = "s_attr1",
                }),
                lQuery.create("Compartment", {
                  input = "String",
                })
              }
            }),

            -- start attr2
            lQuery.create("Compartment", {
              input = "s_attr2:Bool",
              compartStyle = lQuery.create("CompartStyle", {
                caption = "s_attr2-style",
                fontColor = "16711680",
                adjustment = 1 + 8, -- start, right
              }),
              subCompartment = {
                lQuery.create("Compartment", {
                  input = "s_attr2",
                }),
                lQuery.create("Compartment", {
                  input = "Bool",
                })
              }
            })
          }
        }),


        -- end attr group compartment
        lQuery.create("Compartment", {
          input = "e_attr1:String\ne_attr2:Bool",
          isGroup = true,
          compartStyle = lQuery.create("CompartStyle", {
            caption = "end attr group",
            adjustment = 2 + 4, -- end, left
          }),
          subCompartment = {
            --end attr1
            lQuery.create("Compartment", {
              input = "e_attr1:String",
              compartStyle = lQuery.create("CompartStyle", {
                caption = "e_attr1-style",
                fontColor = "255",
                adjustment = 2 + 4, -- end, left
              }),
              subCompartment = {
                lQuery.create("Compartment", {
                  input = "e_attr1",
                }),
                lQuery.create("Compartment", {
                  input = "String",
                })
              }
            }),

            --end attr2
            lQuery.create("Compartment", {
              input = "e_attr2:Bool",
              compartStyle = lQuery.create("CompartStyle", {
                caption = "e_attr2-style",
                fontColor = "16711680",
                adjustment = 2 + 4, -- end, left
              }),
              subCompartment = {
                lQuery.create("Compartment", {
                  input = "e_attr2",
                }),
                lQuery.create("Compartment", {
                  input = "Bool",
                })
              }
            })
          }
        }),
      }
    })
  end
  
  return dgr, node, edge
end

function refresh_test_data()
  local dgr, node, edge = create_or_get_test_data()
  
  utilities.refresh_element({node, edge}, dgr)
  
  -- refresh tree
  utilities.execute_cmd("OkCmd")
end

function toggle_groups()
  local dgr = create_or_get_test_data()
  
  local compartments = dgr:find("/element/compartment"):transitive_closure("/subCompartment")
  
  local is_group_false = compartments:find("[isGroup=false]")
  local is_group_true = compartments:find("[isGroup=true]")
  
  is_group_false:attr("isGroup", "true")
  is_group_true:attr("isGroup", "false")
  
  compartments:log("isGroup", "input")
  
  refresh_test_data()
end
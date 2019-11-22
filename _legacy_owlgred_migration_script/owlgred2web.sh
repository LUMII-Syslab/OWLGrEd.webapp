#!/bin/sh

# TDA_DIR is the directory containing the cloned git repository
# of legacy OWLGrEd/TDA1.5
TDA_DIR=/mnt/c/tda1.5

# BASE_DIR is the OWLGrEd.app directory witihin webappos/apps,
# where OWLGrEd for webAppOS will be located; the script will
# work with the $BASE_DIR/lua and $BASE_DIR/AllPlugins dirs
BASE_DIR=/mnt/d/webappos.org/webappos/apps/OWLGrEd.app
CUR_DIR=$(dirname "$0")

#if false; then
cp -r $TDA_DIR/TdaFramework/Plugins $BASE_DIR/AllPlugins


cp -r $TDA_DIR/TdaFramework/Tools/OWLGrEd/lua $BASE_DIR/
cp -r $TDA_DIR/TdaFramework/Bin/lua $BASE_DIR/
      # ^^^ overwrites initialize.lua
rm -r $BASE_DIR/lua/clibs

sed -i 's/configurator.Dialog/configurator.dialog/g' $BASE_DIR/lua/configurator/delete.lua
sed -i 's/require("lua_mii_rep")/require("lua_raapi")/g' $BASE_DIR/lua/configurator/toolbar.lua

sed -i 's/rep.Save()/-- rep.Save()/g' $BASE_DIR/lua/configurator/toolbar.lua
sed -i 's/GetObjectTypeIdByName/findClass/g' $BASE_DIR/lua/configurator/toolbar.lua
sed -i 's/GetInverseLinkTypeId/getInverseAssociationEnd/g' $BASE_DIR/lua/configurator/toolbar.lua
sed -i 's/function(x) return rep.GetLinkTypeIdList(x.id) end/function(x)\
                  local retVal = {}\
                  local it = rep.getIteratorForAllOutgoingAssociationEnds(x.id)\
                  local r = rep.resolveIteratorFirst(it)\
                  local i = 0\
                  while (r) do\
                    i = i+1\
                    retVal[i] = r\
                    r = rep.resolveIteratorNext(it)\
                  end\
                  rep.freeIterator(it)\
                  return retVal\
           end/g' $BASE_DIR/lua/configurator/toolbar.lua
sed -i 's/local role_list = rep.GetLinkTypeAttributes(link_id)/local role_list = {}\
        local inv_id = rep.getInverserAssociationEnd(link_id)\
        if rep.isComposition(link_id) then\
          role_list.role = 12\
          role_list.inv_role = 2\
        elseif rep.isComposition(inv_id) then\
          role_list.role = 2\
          role_list.inv_role = 12\
        else\
          role_list.role = 4\
          role_list.inv_role = 4\
        end\
        role_list.link_type_id = link_id\
        role_list.inv_link_type_id = inv_id\
        role_list.cardinality = 2\
        role_list.inv_cardinality = 2\
        role_list.object_type_id = rep.getTargetClass(link_id)\
        role_list.inv_object_type_id = rep.getSourceClass(link_id)/g' $BASE_DIR/lua/configurator/toolbar.lua
sed -i 's/local sub_class_list = rep.GetExtensionIdList(class_id)/local sub_class_list = {}\
        local it = raapi.getIteratorForDirectSubClasses(class_id)\
        local subclass_id = raapi.resolveIteratorFirst(it)\
        local i = 0\
        while (subclass_id) do\
          i = i+1\
          sub_class_list[i] = subclass_id\
          subclass_id = raapi.resolveIteratorNext(it)\
        end\
        raapi.freeIterator(it)/g' $BASE_DIR/lua/configurator/toolbar.lua
sed -i 's/GetTypeName/getRoleName/g' $BASE_DIR/lua/configurator/toolbar.lua
sed -i 's/require("lua_mii_rep")/require("lua_raapi")/g' $BASE_DIR/lua/configurator/delta.lua

sed -i 's/link_ids\[class.name\] = rep.GetLinkTypeIdList(class.id)/link_ids[class.name] = {}\
                  local it = rep.getIteratorForAllOutgoingAssociationEnds(self.id)\
                  local r = rep.resolveIteratorFirst(it)\
                  local i = 0\
                  while (r) do\
                    i = i+1\
                    link_ids[class.name][i] = r\
                    r = rep.resolveIteratorNext(it)\
                  end\
                  rep.freeIterator(it)/g' $BASE_DIR/lua/configurator/delta.lua


sed -i 's/local role_attributes = rep.GetLinkTypeAttributes(link)/-- local role_attributes = rep.GetLinkTypeAttributes(link)/g' $BASE_DIR/lua/configurator/delta.lua
sed -i 's/local role_name = rep.GetTypeName(role_attributes.link_type_id)/-- local role_name = rep.GetTypeName(role_attributes.link_type_id)\
                  local role_name = rep.getRoleName(link)/g' $BASE_DIR/lua/configurator/delta.lua

sed -i 's/function create_project()/function create_project()\
    lQuery.create("AttachEngineCommand", {\
	name = "GraphDiagramEngine" })\
                :link("submitter", lQuery("Submitter"))\
                :delete()\
    lQuery.create("AttachEngineCommand", {\
	name = "TreeEngine" })\
                :link("submitter", lQuery("Submitter"))\
                :delete()\
    lQuery.create("AttachEngineCommand", {\
	name = "DialogEngine" })\
                :link("submitter", lQuery("Submitter"))\
                :delete()/g' $BASE_DIR/lua/root.lua

sed -i 's/return string.match/return "some id" --removed string.match/g' $BASE_DIR/lua/project_open_trace.lua
sed -i 's/os.difftime/0 -- removed os.difftime/g' $BASE_DIR/lua/project_open_trace.lua
sed -i 's/get_session_value/1234, -- by SK: removed get_session_value/g' $BASE_DIR/lua/project_open_trace.lua

sed -i 's/dumptable = inspect/dumptable = inspect\
\
function eval(string_to_eval)\
  log("---> eval called, got length", #string_to_eval)\
  return loadstring("return " .. string_to_eval)()\
end/g' $BASE_DIR/lua/initialize.lua
sed -i 's/local style_str = element_or_compartment:attr("style")/local style_str = element_or_compartment:attr("style")\
        if (style_str == nil) then\
          style_str = "" -- by SK\
        end/g' $BASE_DIR/lua/graph_diagram_style_utils.lua



sed -i ':a;N;$!ba;s/function close_form(form_id)\r\n/function close_form(form_id)\
-- changed by SK \
    local ev\
        if (form_id == nil) or (form_id=="") then\
          ev = lQuery("D#Event") -- \[info = 'Close'\]\
        else\
      ev = lQuery("D#Form\[id = " .. form_id .. "\]"):find("\/event")\
    end\
-- changed by SK/g' $BASE_DIR/lua/dialog_utilities.lua

sed -i 's/if form_id == nil then/if (form_id == nil) or (form_id=="") then/g' $BASE_DIR/lua/dialog_utilities.lua

sed -i 's/form = get_form_from_component(button)/if (button:size()==0) then\
              form = lQuery("D#Form")\
              if (form:size()>1) then\
                local maxID = form:get(1).id\
                local i = 2\
                while (i<=form:size()) do\
                  if (form:get(i).id > maxID) then\
                    maxID = form:get(i).id\
                  end\
                  i = i+1\
                end\
                form = lQuery("D#Form\[id = " .. maxID .. "\]")\
              end\
            else\
              form = get_form_from_component(button)\
            end/g' $BASE_DIR/lua/dialog_utilities.lua


sed -i 's/delete_container_components(form)/-- delete_container_components(form)/g' $BASE_DIR/lua/dialog_utilities.lua
sed -i 's/delete_container_components(lQuery/-- delete_container_components(lQuery/g' $BASE_DIR/lua/dialog_utilities.lua
sed -i 's/form:delete()/-- form:delete()/g' $BASE_DIR/lua/dialog_utilities.lua


sed -i 's/if sub_compart_delimiter ~= "" then/if (sub_compart_delimiter ~= nil) and (sub_compart_delimiter ~= "") then -- by SK/g' $BASE_DIR/lua/core.lua



sed -i 's/*all/*a/g' $BASE_DIR/lua/config_properties.lua
sed -i 's/*all/*a/g' $BASE_DIR/lua/save.lua
sed -i ':a;N;$!ba;s/function comboBox_changed()\r\n/function comboBox_changed(ev) -- /g' $BASE_DIR/lua/interpreter/Properties.lua
sed -i ':a;N;$!ba;s/function update_presentation()\r\n/function update_presentation(ev) --/g' $BASE_DIR/lua/interpreter/Properties.lua


sed -i 's/function close_form()/function close_form(ev)/g' $BASE_DIR/lua/interpreter/Properties.lua
sed -i 's/local form = lQuery("D#Event"):find("\/source\/defaultButtonForm")/if (ev==nil) or (ev:size()==0) then\
    ev = lQuery("D#Event")\
  end\
    local form = ev:find("\/source\/defaultButtonForm")\
    if (form:size()==0) then\
          local form = ev:find("\/source")\
    end/g' $BASE_DIR/lua/interpreter/Properties.lua

sed -i 's/d.close_form()/if (form:size()>0) then\
            d.close_form(form:get(1).id)\
        else\
            d.close_form()\
        end/g' $BASE_DIR/lua/interpreter/Properties.lua

sed -i 's/utilities.execute_cmd("PopUpCmd", {popUpDiagram = popUpDiagram, graphDiagram = diagram})/--by SK: this is the second popup command, which is not needed: utilities.execute_cmd("PopUpCmd", {popUpDiagram = popUpDiagram, graphDiagram = diagram})/g' $BASE_DIR/lua/interpreter/RClick.lua


cp $CUR_DIR/libs/LuLPeg.lua $BASE_DIR/lua/libs/
cp $CUR_DIR/libs/lpeg.lua $BASE_DIR/lua/libs/

sed -i 's/function attribute(self, v1, v2, v3)/function attribute(selfx, v1, v2, v3)\
    local self=selfx/g' $BASE_DIR/lua/libs/lQuery.lua

sed -i 's/return obj:get_property(attr_name)/local retval = obj:get_property(attr_name)\
    if retval then\
      return retval\
    else\
      return default\
    end/g' $BASE_DIR/lua/libs/lQuery.lua


sed -i 's/m = require "lpeg"/m = require("lpeg")/g' $BASE_DIR/lua/libs/lQuery_selector_parser.lua
sed -i 's/local start_sym = m.R("az", "AZ") + m.S"_"/--paplasinats, lai stradatu ar TDA 2 (jo tur klasu vardos var but ::)\
local start_sym = m.R("az", "AZ") + m.S"_" + m.P"::"/g' $BASE_DIR/lua/libs/lQuery_selector_parser.lua

sed -i 's/local sym = start_sym + m.R"09" + m.S"#"/local sym = start_sym + m.R"09" + m.S"#" + m.P"::"/g' $BASE_DIR/lua/libs/lQuery_selector_parser.lua
sed -i 's/local value_without_quotes = m.C((1 - m.S"\]),")\^0) \* space/local value_without_quotes = m.C((m.P(1) - m.S"\]),")^0) * space -- m.P(1) corrected by SK/g' $BASE_DIR/lua/libs/lQuery_selector_parser.lua
sed -i 's/m.C((1/m.C((m.P(1)/g' $BASE_DIR/lua/libs/lQuery_selector_parser.lua
sed -i 's/((1/((m.P(1)/g' $BASE_DIR/lua/libs/lQuery_selector_parser.lua

cp $CUR_DIR/libs/mii_rep_obj.lua $BASE_DIR/lua/libs/
sed -i 's/m = require "lpeg"/m = require("lpeg")/g' $BASE_DIR/lua/libs/re.lua

sed -i 's/module(..., package.seeall)$/module("utilities", package.seeall)/' $BASE_DIR/lua/libs/utilities.lua
sed -i 's/lQuery = require("lQuery")/lQuery = require("lQuery")\
/' $BASE_DIR/lua/libs/utilities.lua

sed -i 'H;1h;$!d;x;s/function activate_element(element)\(.*\)function save_dgr_cmd(diagram)/function save_dgr_cmd(diagram)/g' $BASE_DIR/lua/libs/utilities.lua
sed -i 'H;1h;$!d;x;s/function activate_element(element)\(.*\)tda.ExecuteCommand/function activate_element(element)\
  local diagram = element:find("\/graphDiagram")\
-- added by SK\
\
    diagram:find("\/collection"):each(function(coll)\
      coll:remove_link("element", coll:find("\/element"))\
    end)\
\
    diagram:find("\/collection"):delete()\
    local coll = lQuery.create("Collection", {element = element})\
    diagram:link("collection", coll)\
\
-- added by SK\
  tda.ExecuteCommand/g' $BASE_DIR/lua/libs/utilities.lua
sed -i 's/local path = table.concat(current_path_steps, "\\\\")/local path = table.concat(current_path_steps, "\/")\
    local pathdot = table.concat(current_path_steps, "\.")/g' $BASE_DIR/lua/libs/utilities.lua

sed -i 's/if is_file_in_lua_path(lua_package_search_path, path) then/if is_file_in_lua_path(lua_package_search_path, path) or is_file_in_lua_path(lua_package_search_path, pathdot) then/g' $BASE_DIR/lua/libs/utilities.lua
sed -i 's/v = require(path)/v = require(pathdot)/g' $BASE_DIR/lua/libs/utilities.lua

sed -i 's/\*all/\*a/g' $BASE_DIR/lua/plugin_mechanism/loader.lua
sed -i 's/plugin_mechanism.loader.refresh_plugins/&()/g' $BASE_DIR/lua/plugin_mechanism/loader.lua


mv $BASE_DIR/lua/reporter/report.lua $BASE_DIR/lua/reporter/report_original.lua 
cp $CUR_DIR/reporter/report.lua $BASE_DIR/lua/reporter/report.lua

sed -i 's/*all/*a/g' $BASE_DIR/lua/interpreter/ProjectProcessing.lua

sed -i 's/rep = require("lua_mii_rep")//g' $BASE_DIR/lua/configurator/configurator.lua

sed -i 's/utilities.enqued_cmd("ExecTransfCmd"/-- utilities.enqued_cmd("ExecTransfCmd"/g' $BASE_DIR/lua/empty_project_dialog.lua


sed -i 's/local utils = require "plugin_mechanism.utils"/local utils = require "plugin_mechanism.utils"\
require("parameters") -- by SK\
require("exportOntology") -- by SK/g' $BASE_DIR/lua/interpreter/ProjectProcessing.lua

sed -i 's/function project_opened(ev_in)/function project_opened(ev_in)\
parameters.config_OWL_PP() -- by SK\
if not lQuery.model.class_exists("OWL_PP#ExportParameter") then\
  exportOntology.exportParameterMetamodel() -- by SK\
end/g' $BASE_DIR/lua/interpreter/ProjectProcessing.lua

sed -i 's/1.5\*estimate_import_item_count/1.0\*estimate_import_item_count/g' $BASE_DIR/lua/owl_protege.lua
#fi

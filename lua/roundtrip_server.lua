module(..., package.seeall)

tda_to_protege = require "tda_to_protege_4_1"
require "owl_protege"
require "owl_protege_export"

function start()
  local server = assert(socket.bind("*", 65432))

   local ip, port = server:getsockname()

   log("Roundtrip server started on " .. port)

   while 1 do
     local client = server:accept()

     local data, err = client:receive('*l')

     if data then
       log("received test data from", client:getpeername())
       if data == "exit" then
         log("exit request received, quiting")
         break
       end
       local t = os.time(); log("import start")
       local dgr = owl_protege.deserialize_ontology_data(eval(data))
       log("import finished in " .. (os.time() - t) .. " seconds")
       
       t = os.time(); log("export start")
       local iri, str, global_table, iris_table = tda_to_protege.export_ontology(dgr, dgr:find("/source"), function() end)
       local data_to_send = owl_protege_export.serialize_to_clojure_string_form({
         ontology = str,
         expressions = global_table,
         ontology_uri = iri,
         ontology_import_iris = iris_table
       })
       log("export finished in " .. (os.time() - t) .. " seconds")
       client:send(data_to_send)
     else
       log("error in receive", err, client:getpeername())
     end

     client:close()
   end
end
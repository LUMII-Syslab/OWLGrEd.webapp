module(..., package.seeall)

require("utilities")

require("serialize")

-- require("profiler")
function run_test(file_name)
  file_name = file_name or "export_test"
  log("\n\n--- start export", "saved in", file_name)
  local start_time = os.time()
  local objects_to_export = utilities.current_diagram()--:log({"caption"})
  -- profiler.start()
  serialize.save_to_file(objects_to_export, serialize.export_spec, file_name)
  -- profiler.stop()
  log("export finished in ", os.time() - start_time)


  log("start import")
  start_time = os.time()
  -- profiler.start()
  local graphDiagram = serialize.import_from_file("export_test"):log("caption")
  -- profiler.stop()
  log("import finished in ", os.time() - start_time)

  utilities.execute_cmd("ActiveDgrCmd", {graphDiagram = graphDiagram})
  utilities.execute_cmd("OkCmd")
end
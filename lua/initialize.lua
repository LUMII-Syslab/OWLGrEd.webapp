inspect = require 'inspect'
dumptable = inspect

function eval(string_to_eval)
  log("---> eval called, got length", #string_to_eval)
  return loadstring("return " .. string_to_eval)()
end


function thread_resource_clean_up(thread)
  log("thread_resource_clean_up")
  local java_pipe_pointer = retrieve_java_pipe_handle_pointer_address()
  if java_pipe_pointer ~= 0 then
    require("java")
    java.close_java_pipe()
  end
end


function execute_pointer_integer_proc(function_path, obj_id, int)
return utilities.execute_fn(function_path, lQuery(obj_id), int)
end

function log(...)
  local str = ""
  for _, v in ipairs(arg) do
    str = str .. tostring(v) .. "    "
  end
  console_log(str)
end

print = log

tda = require("lua_tda")
-- tda.ShowInformationBar("lua initialized")

lQuery = require("lQuery")
require "utilities"

-- set global getfield, used in c++ functions
getfield = utilities.getfield

function execute_proc(function_path)
  return utilities.execute_fn(function_path)
end

function execute_pointer_proc(function_path, obj_id)
  return utilities.execute_fn(function_path, lQuery(obj_id))
end

function execute_str_proc(function_path, str)
  return utilities.execute_fn(function_path, str)
end

function execute_string_proc_returning_string(function_path, str)
  return utilities.execute_fn(function_path, str)
end

function execute_pointer_proc_returning_string(function_path, obj_id)
  return utilities.execute_fn(function_path, lQuery(obj_id))
end

function execute_pointer_pointer_proc_returning_string(function_path, obj_id_1, obj_id_2)
  print(obj_id_1, obj_id_2)
  local obj_1, obj_2 = lQuery({}), lQuery({}) -- empty collections
  
  -- if not empty object, then initialize lQuery collection to that obj
  if obj_id_1 ~= 0 then
    obj_1 = lQuery(obj_id_1)
  end

  if obj_id_2 ~= 0 then
    obj_2 = lQuery(obj_id_2)
  end

  return utilities.execute_fn(function_path, obj_1, obj_2)
end

function execute_pointer_pointer_proc_returning_int_and_string(function_path, obj_id_1, obj_id_2)
  print(obj_id_1, obj_id_2)
  local obj_1, obj_2 = lQuery({}), lQuery({}) -- empty collections
  
  -- if not empty object, then initialize lQuery collection to that obj
  if obj_id_1 ~= 0 then
    obj_1 = lQuery(obj_id_1)
  end

  if obj_id_2 ~= 0 then
    obj_2 = lQuery(obj_id_2)
  end

  return utilities.execute_fn(function_path, obj_1, obj_2)
end

function execute_pointer_proc_returning_pointer(function_path, obj_id)
  return utilities.execute_fn(function_path, lQuery(obj_id)):id()
end

function execute_pointer_pointer_pointer_proc(function_path, obj_id_1, obj_id_2, obj_id_3)
  return utilities.execute_fn(function_path, lQuery(obj_id_1), lQuery(obj_id_2), lQuery(obj_id_3))
end

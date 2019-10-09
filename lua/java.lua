module(..., package.seeall)
require("lua_java")

local jar_file_dir = tda.GetRuntimePath() .. "\\jars"

function get_jar_paths(path)
	require("lfs")

	local jar_paths = {}

	for name in lfs.dir(path) do
		local file_path = path .. "\\" .. name

		if lfs.attributes(file_path, "mode") == "file" and string.find(file_path, "%.jar$") then
			table.insert(jar_paths, file_path)

		elseif name ~= "." and name ~= ".." and lfs.attributes(file_path, "mode") == "directory" then
			local sub_paths = get_jar_paths(file_path)
			for _, p in ipairs(sub_paths) do
				table.insert(jar_paths, p)
			end
		end
	end
	
	return jar_paths
end

function get_native_lib_folder_paths(path)
	require("lfs")

	local lib_folder_paths = {}

	for name in lfs.dir(path) do
		local file_path = path .. "\\" .. name

		if name ~= "." and name ~= ".." and lfs.attributes(file_path, "mode") == "directory" then
			table.insert(lib_folder_paths, file_path)
			
			local sub_paths = get_native_lib_folder_paths(file_path)
			for _, p in ipairs(sub_paths) do
				table.insert(lib_folder_paths, p)
			end
		end
	end

	return lib_folder_paths
end

function call_static_class_method_through_piped_process(class_name, public_static_method_name, string_arg)
	local old_path = getenv("PATH")

	--
	-- set up path to find jvm
	--
	local tda_path = tda.GetRuntimePath()
	local jvm_path = tda_path .. "\\jre\\bin;" .. tda_path .. "\\jre\\bin\\client;"
	setenv("PATH", jvm_path .. old_path)

	-- read handle pointer adress
	local java_pipe_handle_address = retrieve_java_pipe_handle_pointer_address()

	local jvm_options = {
		string.format('-Djava.class.path=%s', table.concat(get_jar_paths(jar_file_dir), ";")),
		string.format('-Djava.library.path=%s', table.concat(get_native_lib_folder_paths(jar_file_dir), ";")),
		-- '-verbose:jni',
		'-Xmx64m',
	}
	
	local java_pipe_handle_address, value, err = lua_java.call_java_through_pipe(java_pipe_handle_address, jvm_options, class_name, public_static_method_name, string_arg)

	-- store handle pointer address in dll, to persist across lua calls
	-- because need to have c++ pointer to jvm
	store_java_pipe_handle_pointer_address(java_pipe_handle_address)

	-- restore path
	setenv("PATH", old_path)

	if err then
		error(string.format("\nJVM Error - \n\t%s\n", err), 2)
	end
	
	--print(jvm_pointer, no_error, value_or_error)
	return value
end

function close_java_pipe()
	local java_pipe_handle_address = retrieve_java_pipe_handle_pointer_address()
	lua_java.java_pipe_close(java_pipe_handle_address)
	store_java_pipe_handle_pointer_address(0)
end

function call_static_class_method(...)
	return call_static_class_method_through_piped_process(...)
end

--[[ example java class:
public class Test {
  public static String my_method(String arg) {
      return "got: " + arg;
  }
}
--]]
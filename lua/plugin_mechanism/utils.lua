module(..., package.seeall)

require "lfs"

function get_subfolder_names(path)
  local names = {}
  
  for d in lfs.dir(path) do
    if lfs.attributes(path .. "/" .. d, "mode") == "directory" and d ~= "." and d ~= ".." then -- these are not plugins
      table.insert(names, d)
    end
  end
  return names
end

function copy(src_path, target_path)
  local mode = lfs.attributes(src_path, "mode")
  if mode == "directory" then
    lfs.mkdir(target_path)
  
    for d in lfs.dir(src_path) do
      if d ~= "." and d ~= ".." then -- these are not plugins
        local src, trg = src_path .. "/" .. d, target_path .. "/" .. d
        copy(src, trg)
      end
    end
  elseif mode == "file" then
    local fail_on_exists = false
    tda.CopyFile(src_path, target_path, fail_on_exists)
  end
end

function delete(path)
  tda.DeleteFileOrFolder(path)
end
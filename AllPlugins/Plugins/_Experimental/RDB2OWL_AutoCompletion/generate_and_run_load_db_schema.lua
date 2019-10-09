log = print
require "lua_mii_rep"
lQuery = require "lQuery"

local arg={...}

--~ if (arg[2]==nil) then
--~ 	arg[2]="com.microsoft.sqlserver.jdbc.SQLServerDriver"
--~ end
--~ if (arg[3]==nil) then
--~ 	arg[3]="jdbc:sqlserver://GUNTARS-PC:1433;databaseName=school;user=school;password=s"
--~ end
--~ if (arg[4]==nil) then
--~ 	arg[4]="dbo"
--~ end
if (arg[2]==nil) then
	arg[2]="C:\\manas_lietas\\Zinatne\\mani_darbi\\mii_rep\\mii_repozitorijs\\rdb2owl_mm"
end
if (arg[3]==nil) then
	arg[3]=""
end

local dbName=arg[1]
--~ local jdbcClassName=arg[2]
--~ local connectionString=arg[3]
--~ local schema=arg[4]
local repo_path = arg[2]
local prefix=arg[3]

print("dbName=" .. dbName)
print("repo_path=" .. repo_path)
print("prefix=" .. prefix)

--assert(lua_mii_rep.Connect(repo_path))
database=lQuery(prefix .. "Database[dbName=" .. dbName .. "]" )
if (database:is_not_empty()) then
	jdbcClassName=database:attr("jdbcDriver")
	connectionString=database:attr("connection")
	schema=database:attr("schema")
end
--assert(lua_mii_rep.Disconnect())
if (database:is_empty()) then
	return
end

require("java")
function load_java()
	class_name = "SourceDBProcessor"
	method_name = "main4Lua"
	arg = "-jdbcClassName " .. jdbcClassName .. " -connectionString " .. connectionString .. " -schema " .. schema
	print("Before java call")
	rez = java.call_static_class_method(class_name, method_name, arg)
	print("-- java vm loaded --")

end

load_java()
loadstring(rez)()


--assert(lua_mii_rep.Connect(repo_path))


for tNr, tInfo in ipairs(dbTables) do
	-- delete old info for this table (PK/FK keys, columns and the table itself
	lQuery(prefix.."Table[tName=" .. tInfo.tableName .."]/column/pKey"):delete()
	lQuery(prefix.."Table[tName=" .. tInfo.tableName .."]/column/fKey"):delete()
	lQuery(prefix.."Table[tName=" .. tInfo.tableName .."]/column"):delete()
	lQuery(prefix.."Table[tName=" .. tInfo.tableName .."]"):delete()
end

database=lQuery(prefix .. "Database[dbName=" .. dbName .. "]" )
--database=lQuery(prefix .. "Database"):first()
for tNr, tInfo in ipairs(dbTables) do
	print(tNr .. ". " .. tInfo.tableName)
	local newTable=lQuery.create(prefix.."Table")
	newTable:attr("tName", tInfo.tableName)
	newTable:link("database", database)
	for cNr, colName in ipairs(tInfo.columns) do
		print("     " .. cNr .. ".  " .. colName)
		local newColumn=lQuery.create(prefix.."Column")
		newColumn:attr("colName", colName)
		newTable:link("column", newColumn)
	end
end

--Process Primary Keys
for tName, colName in pairs(pk) do
	print(tName .. " PK " .. colName)
	tableObject=lQuery(prefix.."Table[tName=" .. tName .. "]")
	if (tableObject~=nil) then
		columnObject=tableObject:find("/column[colName=" .. colName .. "]")
		if (columnObject~=nill) then
			-- Create PKey such that: tableObject->PKey->columnObject
			local pKeyObject=lQuery.create(prefix.."PKey")
			tableObject:link("pKey", pKeyObject)
			pKeyObject:link("column", columnObject)
		end
	end
end

--Process Foreign Keys
for fkTableName, fkInfos in pairs(fk) do
	print("fkTableName=" .. fkTableName)
	for _,fkInfo in ipairs(fkInfos) do
		for fkColumnName, targetTableName in pairs(fkInfo) do
			print("FK: " .. fkTableName .. "." .. fkColumnName .. " --> " .. targetTableName)
			fkTableObject=lQuery(prefix.."Table[tName=" .. fkTableName .. "]")
			targetTableObject=lQuery(prefix.."Table[tName=" .. targetTableName .. "]")
			if (fkTableObject~=nil and targetTableObject~=nil) then
				fkColumnObject=fkTableObject:find("/column[colName=" .. fkColumnName .. "]")
				--Create FKey object fKey such that: fkColumnObject <-- fKey --> targetTableObject
				local fKey=lQuery.create(prefix.."FKey")
				fKey:log()
				fkColumnObject:log()
				fKey:link("column", fkColumnObject)
				fKey:link("target", targetTableObject)
			end
		end
	end
end

print("save repo at " .. repo_path, assert(lua_mii_rep.Save()))
--print("close repo at " .. repo_path, assert(lua_mii_rep.Disconnect()))
print("close repo at " .. repo_path)







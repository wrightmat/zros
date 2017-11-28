local common_functions = {}

-- originally from http://stackoverflow.com/questions/6075262/lua-table-tostringtablename-and-table-fromstringstringtable-functions
-- modified fixed a serialization issue with invalid name. and wrap with 2 functions to serialize / deserialize

function tableToString(tbl)
	return table.concat(tbl, ",") .. ","
end

function stringToTable(str)
  local sep, fields = ",", {}
  str:gsub("([^"..sep.."]*)"..sep, function(c)
    table.insert(fields, c)
  end)
  return fields
end

return common_functions
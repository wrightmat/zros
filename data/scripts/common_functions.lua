local common_functions = {}

-- Originally from http://stackoverflow.com/questions/6075262/lua-table-tostringtablename-and-table-fromstringstringtable-functions
-- modified fixed a serialization issue with invalid name. and wrap with 2 functions to serialize / deserialize
-- Split function added separately from Stack Overflow.

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

function string:split(delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( self, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
  end
  table.insert( result, string.sub( self, from  ) )
  return result
end

return common_functions
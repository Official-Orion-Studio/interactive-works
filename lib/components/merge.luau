-- Constants
local none = newproxy(true)

local noneMetatable = getmetatable(none :: any) :: { __tostring: () -> string }
noneMetatable.__tostring = function()
	return "dictionary.none"
end

--[[
    Merges tables.

    @param ...table<any, any>
]]
return function<T>(...: any): T
	local result: any = table.clone(select(1, ...))

	for dictionaryIndex = 2, select("#", ...) do
		local dictionary = select(dictionaryIndex, ...)

		if type(dictionary) ~= "table" then
			continue
		end

		for key, value in dictionary do
			result[key] = if value == none then nil else value
		end
	end

	return result
end

-- Module
local Reflect = {}

--[[
    Attaches metadata to a constructor.
    
    @param ctor - The constructor
    @param metadata - The metadata to attach
]]
function Reflect.attachMetadata(ctor: any, metadata: { [any]: any }): nil
	assert(
		typeof(ctor) == "table",
		"Reflect.attachMetadata can't attach metadata to a non-singleton."
	)
	assert(typeof(metadata) == "table", "Reflect.attachMetadata can't attach metadata.")

	if not ctor._medata then
		ctor._metadata = {}
	end

	for key, value in metadata do
		ctor._metadata[key] = value
	end

	return nil
end

--[[
    Gets metadata from a constructor.
    
    @param ctor - The constructor
    @param key - The key to get
    @returns - The metadata
]]
function Reflect.getMetadata(ctor: any): any
	assert(
		typeof(ctor) == "table",
		"Reflect.getMetadataAll can't get metadata from a non-singleton."
	)

	return ctor._metadata
end

function Reflect.getAttachedMetadata(ctor: any, key: any): { [any]: any }
	assert(typeof(ctor) == "table", "Reflect.getMetadata can't get metadata from a non-singleton.")

	return ctor._metadata[key]
end

-- Export
return Reflect

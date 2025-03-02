-- Dependencies
local Types = require(script.Parent.util.types)

-- Module
local Reflect = {}

--[[
    Attaches metadata to a constructor.
    
    @param ctor - The constructor
    @param metadata - The metadata to attach
]]
function Reflect.attachMetadata(ctor: Types.Singleton, metadata: { [any]: any }): nil
    assert(typeof(ctor) == "table", "Reflect.attachMetadata can't attach metadata to a non-singleton.")
    assert(typeof(metadata) == "table", "Reflect.attachMetadata can't attach metadata.")

    for key, value in metadata do
        ctor[key] = value
    end

    return nil
end

--[[
    Gets metadata from a constructor.
    
    @param ctor - The constructor
    @param key - The key to get
    @returns - The metadata
]]
function Reflect.getMetadata(ctor: Types.Singleton, key: any): any
    assert(typeof(ctor) == "table", "Reflect.getMetadata can't get metadata from a non-singleton.")
    
    return ctor[key]
end

-- Export
return Reflect
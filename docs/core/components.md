# Components

Interactive exposes a rich API when it comes to components, allowing developers to create their own behavior for instances. Components are also available to access lifecyles which are custom-made or by default (except `onInit`). A Component is useful to represent Instances instead of using them directly, being able to encapsulate behavior in a "container" makes it easier to add functionality or even to debug.

## Declaring a component

Components have a variety of useful fields which Singletons don't expose. But every single component requires to have at least a `tag`, everything else is optional.
```lua title="src/server/components/component.luau"
local framework = require(...)

local component = {
    tag = "MyTag",
}

function component:onStart(singletonsBag)
    ...
end

function component:destroy()
    ...
end

return framework.createComponent(component)
```

This is the basic boilerplate required to construct a component. Components can also have a constructor where they define inner elements for it's functionality.

### Configuration

Components have a vast majority of configuration, this is to open the possibility to either delimit, or expand the functionality of your Component. 

The next properties can be added to the initial Component.

#### defaults

They describe default attributes for your Instance to have.

The next example demonstrates a component which will have an `example` attribute of value `Vector.zero`.
```lua
{
    defaults = {
        example = Vector3.zero,
    },
}
```

#### instanceGuard

A function that takes the instance being added and **SHOULD** return a boolean. It should be used to verify the tree of your instance if you require so. For example, a `character` component, the `instanceGuard` could be useful to look into it and try to find a `Humanoid`.

The next example demonstrates a component which is only constructed when the instance is a `Model`.
```lua
{
    instanceGuard = function(instance: Instance)
        return instance:IsA("Model")
    end,
}
```

#### ancestors

An Instance list which is verified against to construct the component. If the Instance tagged isn't a descendant of ANY of the provided paths, it will throw.

The next example demonstrates a component which is only constructed when the Instance is a descendant of `Workspace`.
```
{
    ancestors = { Workspace },
}
```

#### ignoreFlags

A boolean which describes if the flags should be ignored. This applies to errors while constructing the Component, or ancestors issues, even `instanceGuard` flags will be ignored.

:::danger
This property should be avoided, use only if necessary.
:::

### Constructed component

A constructed component is what you use within the object itself, and it exposes two properties and a lifecycle which is useful to manipulate the Instance.

#### instance

The Instance which was tagged can be accessed from here. It should be the only way of accessing such Instance.

The next example prints the full name (path) of the Instance tagged.
```luau
function <component>:onStart()
    print(`I was tagged with {self.tag} and my path is {self.instance:GetFullName()}`)
end
```

#### attributes

This is an object which can be accessed at any time, and it's updated through the Component's life. Accessing attributes from here is preferred over `self.instance:GetAttribute()`, as the latter is inconvinient.

The next example prints all the attributes a component may have!
```luau
function <component>:onStart()
    print(self.attributes)
end
```

#### onAttributeChanged

This lifecycle is only available to Components. It exposes which attribute and it's new value.

The next example prints the changes on a component by its attributes.
```luau
function <component>:onAttributeChanged(attribute, value)
    print(attribute .. " was changed. New value is: ", value)
end
```
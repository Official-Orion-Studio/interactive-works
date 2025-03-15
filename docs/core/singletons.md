# Singletons

Interactive allows you to create Services and Controllers in the server and client respectively. Folliwing the phylosophy of creating once, and exposing it in a singular point of access.

- Services run on the server and they are limited to certain lifecycles being used that can only be used on the client.
- Controllers run on the client and they are not limited to lifecycles.

## Lifecycles

Singletons (and later on Components) can implement lifecycles themselves. The main lifecycles are `onInit` and `onStart`.

:::info
All lifecycles should start with the `on` word, this is the only way (as of right now) that lifecycles will be registered for services implementing them.
:::

The way to implement custom-made lifecycles is via the `modding` library. Which will be revisited on a later chapter.

For the next example though, we are going to be using the `utility` library so we can implement an `onPlayerAdded` lifecycle as shown below
```lua title="src/server/services/first.luau"
local Players = game:GetService("Players")

local framework = require(...)
local utility = framework.utility

local firstService = {
    name = "firstService"
}

function firstService:constructor()
    self.addedSignals = {}
end

function firstService:onStart()
    utility.setupLifecycle(self.addedSignals, "onPlayerAdded")

    Players.PlayerAdded:Connect(function(player)
        utility.initLifecycle(self.addedSignals, "onPlayerJoin", player)
    end)
end

return framework.createService(firstService)
```

And another service can use it:
```lua title="src/server/services/second.luau"
local framework = require(...)

local secondService = {
    name = "secondService"
}

function secondService:onPlayerAdded(player: Player)
    print(player .. " has joined the game!")
end

return framework.createService(secondService)
```

Have in mind that it doesn't matter if `secondService` is resolved first than `firstService`, lifecycles are binded if there's not a listener at the moment is resolved.
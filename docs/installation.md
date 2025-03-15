---
sidebar_position: 2
---

# Installation

Installing Interactive is as easy as any other tool in Roblox. As of right now, Interactive doesn't include a Roblox Asset which you can include in Roblox Studio. The only way to get Interactive is via `wally`. This also means that you will need to use Rojo (or any other script's syncing tool) to use Interactive.

If you don't have wally installed, you can install it [here](https://wally.run/install).

### Installing Interactive

First off you'll want install the interactive framework. For this, you would need to modify your `wally.toml` as next:
```toml title="/wally.toml"
[dependencies]
interactive = "siriuslatte/interactiveworks@version"
```

And run the next command on your terminal (at your project's root).
```bash
wally install
```

### Accessing Interactive

For those who may not be familiar with `wally`. The way to access the framework will be as shown below:
```lua title="src/server/runtime.luau"
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local framework = require(ReplicatedStorage.Packages.interactive)

framework.addPath(script.Parent)
framework.init()
```

The script shows the most simple way of adding the whole `server` folder into the execution lifecycle of Interactive.
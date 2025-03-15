---
sidebar_position: 1
---

# Introduction

Interactive, a Luau framework that aims to tackle a global problem, by giving a unique solution.

## Why does this exists?

This may be a good question to start with. Interactive has been designed to ease how we make games here at Orion Studios. Throught development of our first experience we saw the urge to change to an actual framework which could provide us a centralized functionality. 

For this reason, Interactive was born. And we would like to give you a warm welcome into it.

:::tip
Thanks to flamework for being such a great inspiration on Interactive!
:::

### Structure

Interactive exposes a structure which may be familiar to almost all developers in the platform, which are Singletons and Components. If you haven't, we invite you over to read about them and come back to this document once you have made your research.

## Example

Creating a new singleton/component is as easy as defining the object and calling `Interactive.create...()`. Here's an example:

```lua title="src/server/services/service.luau"
local framework = ...
local service = {
  name = "MyService"
}

return framework.createService(service)
```
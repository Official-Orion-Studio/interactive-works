---
sidebar_position: 2
---

# Lifecycles

Lifecycles are something that has been explored before and we will continue to do so in this section. But no we will explain each lifecycle available (by default) on Singletons and some on Components.

## onInit

The `onInit` lifecycle is the first step on initializing a singleton/component, it's also where we expose a servicesBag where you can retrieve services from (for *now*). This method doesn't yield and lifecycles aren't affected between each other.

## onStart 

The `onStart` lifecycle is the stage where all services are expected to be on an initialized state. This method doesn't yield and lifecycles aren't affected between each other.

## onTick

This is a lifecycle exposed to all singletons and components, directly binded to `RunService.Heartbeat`.

## onPhysics

This is a lifecycle exposed to all singletons and components, directly binded to `RunService.PreSimulation`.

## onRender

This is a lifecycle exposed to all singletons and components, directly binded to `RunService.PreRender`.

:::warning
This lifecycle can only be binded on the client, if there's a service that may include, it will throw.
:::
"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[782],{8205:e=>{e.exports=JSON.parse('{"functions":[{"name":"create","desc":"Checks and registers a singleton. Making sure to bind its lifecycles as well.\\n\\nLifecycle methods are methods that are called at a specific time during the singleton\'s lifecycle,\\nand these are called by another singletons that may have setup such lifecycles. All lifecycles\\nshould start with `on...`, as it\'s currently the only way to differentiate from methods.\\n\\n```lua\\nlocal singleton = {\\n\\tname = \\"Singleton\\",\\n\\tonInit = function(self, servicesBag)\\n\\t\\t...\\n\\tend,\\n\\tonStart = function(self)\\n\\t\\t...\\n\\tend,\\n\\tonLifecycle = function(self)\\n\\t\\t... -- This will be called sometime in execution.\\n\\tend\\n}\\n```","params":[{"name":"config","desc":"The singleton\'s config.","lua_type":"SingletonConfig"}],"returns":[{"desc":"","lua_type":"SingletonConfig\\n"}],"function_type":"static","source":{"line":98,"path":"lib/singleton.luau"}},{"name":"get","desc":"Returns a singleton by its name. If the singleton hasn\'t been initialized, it will be\\ninitialized and returned.","params":[{"name":"key","desc":"","lua_type":"string"}],"returns":[{"desc":"","lua_type":"SingletonConfig"}],"function_type":"static","source":{"line":142,"path":"lib/singleton.luau"}},{"name":"createService","desc":"Creates a service on the server.","params":[{"name":"config","desc":"","lua_type":"SingletonConfig"}],"returns":[{"desc":"","lua_type":"SingletonConfig\\n"}],"function_type":"static","realm":["Server"],"source":{"line":166,"path":"lib/singleton.luau"}},{"name":"createController","desc":"Creates a controller on the client.","params":[{"name":"config","desc":"","lua_type":"SingletonConfig"}],"returns":[{"desc":"","lua_type":"SingletonConfig\\n"}],"function_type":"static","realm":["Client"],"source":{"line":184,"path":"lib/singleton.luau"}},{"name":"getService","desc":"Returns a service by its name. This method should only be called by the server.","params":[{"name":"key","desc":"","lua_type":"string"}],"returns":[{"desc":"","lua_type":"SingletonConfig\\n"}],"function_type":"static","realm":["Server"],"source":{"line":198,"path":"lib/singleton.luau"}},{"name":"getController","desc":"Returns a controller by its name.","params":[{"name":"key","desc":"","lua_type":"string"}],"returns":[{"desc":"","lua_type":"SingletonConfig\\n"}],"function_type":"static","realm":["Client"],"source":{"line":214,"path":"lib/singleton.luau"}}],"properties":[],"types":[{"name":"SingletonConfig","desc":"Represents a singleton\'s configuration.","fields":[{"name":"name","lua_type":"string,","desc":""},{"name":"loadOrder?","lua_type":"number,","desc":""},{"name":"constructor?","lua_type":"() -> (),","desc":""},{"name":"onInit?","lua_type":"(servicesBag) -> (),","desc":""},{"name":"onStart?","lua_type":"() -> (),","desc":""},{"name":"onTick?","lua_type":"(dt: number) -> (),","desc":""},{"name":"onPhysics?","lua_type":"(dt: number) -> (),","desc":""},{"name":"onRender?","lua_type":"(dt: number) -> (),","desc":""}],"source":{"line":22,"path":"lib/singleton.luau"}}],"name":"Singleton","desc":"Singletons are objects that are instantiated only once and can be accessed from a single \\npoint of the application. They are useful for managing global state, functionality\\nand keeping logic where it belongs. \\n\\nSingletons should hold logic to only one system at a time, making sure that\\nseparate logic or functionality not-related to the main system is kept in a separate\\nsingleton.\\n\\nHere\'s an example of a singleton:\\n\\n```lua title=\\"src/server/services/service.luau\\"\\nlocal framework = require(...)\\nlocal service = {\\n\\tname = \\"Service\\",\\n}\\n\\nfunction service:onInit(servicesBag)\\n\\t...\\nend\\n\\nfunction service:onStart()\\n\\t...\\nend\\n\\nreturn framework.createService(service)\\n```","source":{"line":70,"path":"lib/singleton.luau"}}')}}]);
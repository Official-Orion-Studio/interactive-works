--[=[
	An enum value used to represent the Promise's status.
	@interface Status
	@tag enum
	@within Promise
	.Started "Started" -- The Promise is executing, and not settled yet.
	.Resolved "Resolved" -- The Promise finished successfully.
	.Rejected "Rejected" -- The Promise was rejected.
	.Cancelled "Cancelled" -- The Promise was cancelled before it finished.
]=]
export type Status = "Started" | "Resolved" | "Rejected" | "Cancelled"

--[=[
	A Promise is an object that represents a value that will exist in the future, but doesn't right now.
	Promises allow you to then attach callbacks that can run once the value becomes available (known as *resolving*),
	or if an error has occurred (known as *rejecting*).

	@class Promise
	@__index prototype
]=]
export type Promise = {
	--[=[
		Chains onto an existing Promise and returns a new Promise.

		:::warning
		Within the failure handler, you should never assume that the rejection value is a string. Some rejections within the Promise library are represented by [[Error]] objects. If you want to treat it as a string for debugging, you should call `tostring` on it first.
		:::

		You can return a Promise from the success or failure handler and it will be chained onto.

		Calling `andThen` on a cancelled Promise returns a cancelled Promise.

		:::tip
		If the Promise returned by `andThen` is cancelled, `successHandler` and `failureHandler` will not run.

		To run code no matter what, use [Promise:finally].
		:::

		@param successHandler (...: any) -> ...any
		@param failureHandler? (...: any) -> ...any
		@return Promise<...any>
	]=]
	andThen: (
		self: Promise,
		successHandler: (...any) -> ...any,
		failureHandler: ((...any) -> ...any)?
	) -> Promise,
	--[=[
		Attaches an `andThen` handler to this Promise that calls the given callback with the predefined arguments. The resolved value is discarded.

		```lua
			promise:andThenCall(someFunction, "some", "arguments")
		```

		This is sugar for

		```lua
			promise:andThen(function()
			return someFunction("some", "arguments")
			end)
		```

		@param callback (...: any) -> any
		@param ...? any -- Additional arguments which will be passed to `callback`
		@return Promise
	]=]
	andThenCall: <TArgs...>(self: Promise, callback: (TArgs...) -> ...any, TArgs...) -> any,
	--[=[
		Attaches an `andThen` handler to this Promise that discards the resolved value and returns the given value from it.

		```lua
			promise:andThenReturn("some", "values")
		```

		This is sugar for

		```lua
			promise:andThen(function()
				return "some", "values"
			end)
		```

		:::caution
		Promises are eager, so if you pass a Promise to `andThenReturn`, it will begin executing before `andThenReturn` is reached in the chain. Likewise, if you pass a Promise created from [[Promise.reject]] into `andThenReturn`, it's possible that this will trigger the unhandled rejection warning. If you need to return a Promise, it's usually best practice to use [[Promise.andThen]].
		:::

		@param ... any -- Values to return from the function
		@return Promise
	]=]
	andThenReturn: (self: Promise, ...any) -> Promise,

	--[=[
		Yields the current thread until the given Promise completes. Returns true if the Promise resolved, followed by the values that the promise resolved or rejected with.

		:::caution
		If the Promise gets cancelled, this function will return `false`, which is indistinguishable from a rejection. If you need to differentiate, you should use [[Promise.awaitStatus]] instead.
		:::

		```lua
			local worked, value = getTheValue():await()

		if worked then
			print("got", value)
		else
			warn("it failed")
		end
		```

		@yields
		@return boolean -- `true` if the Promise successfully resolved
		@return ...any -- The values the Promise resolved or rejected with.
	]=]
	await: (self: Promise) -> (boolean, ...any),
	--[=[
		Yields the current thread until the given Promise completes. Returns the Promise's status, followed by the values that the promise resolved or rejected with.

		@yields
		@return Status -- The Status representing the fate of the Promise
		@return ...any -- The values the Promise resolved or rejected with.
	]=]
	awaitStatus: (self: Promise) -> (Status, ...any),

	--[=[
		Cancels this promise, preventing the promise from resolving or rejecting. Does not do anything if the promise is already settled.

		Cancellations will propagate upwards and downwards through chained promises.

		Promises will only be cancelled if all of their consumers are also cancelled. This is to say that if you call `andThen` twice on the same promise, and you cancel only one of the child promises, it will not cancel the parent promise until the other child promise is also cancelled.

		```lua
			promise:cancel()
		```
	]=]
	cancel: (self: Promise) -> (),

	--[=[
		Shorthand for `Promise:andThen(nil, failureHandler)`.

		Returns a Promise that resolves if the `failureHandler` worked without encountering an additional error.

		:::warning
		Within the failure handler, you should never assume that the rejection value is a string. Some rejections within the Promise library are represented by [[Error]] objects. If you want to treat it as a string for debugging, you should call `tostring` on it first.
		:::

		Calling `catch` on a cancelled Promise returns a cancelled Promise.

		:::tip
		If the Promise returned by `catch` is cancelled,  `failureHandler` will not run.

		To run code no matter what, use [Promise:finally].
		:::

		@param failureHandler (...: any) -> ...any
		@return Promise<...any>
	]=]
	catch: (self: Promise, failureHandler: (...any) -> ...any) -> Promise,
	--[=[
		Yields the current thread until the given Promise completes. Returns the values that the promise resolved with.

		```lua
		local worked = pcall(function()
			print("got", getTheValue():expect())
		end)

		if not worked then
			warn("it failed")
		end
		```

		This is essentially sugar for:

		```lua
		select(2, assert(promise:await()))
		```

		**Errors** if the Promise rejects or gets cancelled.

		@error any -- Errors with the rejection value if this Promise rejects or gets cancelled.
		@yields
		@return ...any -- The values the Promise resolved with.
	]=]
	expect: (self: Promise) -> ...any,

	--[=[
		Set a handler that will be called regardless of the promise's fate. The handler is called when the promise is
		resolved, rejected, *or* cancelled.

		Returns a new Promise that:
		- resolves with the same values that this Promise resolves with.
		- rejects with the same values that this Promise rejects with.
		- is cancelled if this Promise is cancelled.

		If the value you return from the handler is a Promise:
		- We wait for the Promise to resolve, but we ultimately discard the resolved value.
		- If the returned Promise rejects, the Promise returned from `finally` will reject with the rejected value from the
		*returned* promise.
		- If the `finally` Promise is cancelled, and you returned a Promise from the handler, we cancel that Promise too.

		Otherwise, the return value from the `finally` handler is entirely discarded.

		:::note Cancellation
		As of Promise v4, `Promise:finally` does not count as a consumer of the parent Promise for cancellation purposes.
		This means that if all of a Promise's consumers are cancelled and the only remaining callbacks are finally handlers,
		the Promise is cancelled and the finally callbacks run then and there.

		Cancellation still propagates through the `finally` Promise though: if you cancel the `finally` Promise, it can cancel
		its parent Promise if it had no other consumers. Likewise, if the parent Promise is cancelled, the `finally` Promise
		will also be cancelled.
		:::

		```lua
		local thing = createSomething()

		doSomethingWith(thing)
			:andThen(function()
				print("It worked!")
				-- do something..
			end)
			:catch(function()
				warn("Oh no it failed!")
			end)
			:finally(function()
				-- either way, destroy thing

				thing:Destroy()
			end)

		```

		@param finallyHandler (status: Status) -> ...any
		@return Promise<...any>
	]=]
	finally: (self: Promise, finallyHandler: (status: Status) -> ...any) -> Promise,

	--[=[
		Same as `andThenCall`, except for `finally`.

		Attaches a `finally` handler to this Promise that calls the given callback with the predefined arguments.

		@param callback (...: any) -> any
		@param ...? any -- Additional arguments which will be passed to `callback`
		@return Promise
	]=]
	finallyCall: <TArgs...>(self: Promise, callback: (TArgs...) -> ...any, TArgs...) -> Promise,
	--[=[
		Attaches a `finally` handler to this Promise that discards the resolved value and returns the given value from it.

		```lua
			promise:finallyReturn("some", "values")
		```

		This is sugar for

		```lua
			promise:finally(function()
				return "some", "values"
			end)
		```

		@param ... any -- Values to return from the function
		@return Promise
	]=]
	finallyReturn: (self: Promise, ...any) -> Promise,

	--[=[
		Returns the current Promise status.

		@return Status
	]=]
	getStatus: (self: Promise) -> Status,
	--[=[
		Chains a Promise from this one that is resolved if this Promise is already resolved, and rejected if it is not resolved at the time of calling `:now()`. This can be used to ensure your `andThen` handler occurs on the same frame as the root Promise execution.

		```lua
		doSomething()
			:now()
			:andThen(function(value)
				print("Got", value, "synchronously.")
			end)
		```

		If this Promise is still running, Rejected, or Cancelled, the Promise returned from `:now()` will reject with the `rejectionValue` if passed, otherwise with a `Promise.Error(Promise.Error.Kind.NotResolvedInTime)`. This can be checked with [[Error.isKind]].

		@param rejectionValue? any -- The value to reject with if the Promise isn't resolved
		@return Promise
	]=]
	now: (self: Promise, rejectionValue: any?) -> Promise,
	--[=[
		Similar to [Promise.andThen](#andThen), except the return value is the same as the value passed to the handler. In other words, you can insert a `:tap` into a Promise chain without affecting the value that downstream Promises receive.

		```lua
			getTheValue()
			:tap(print)
			:andThen(function(theValue)
				print("Got", theValue, "even though print returns nil!")
			end)
		```

		If you return a Promise from the tap handler callback, its value will be discarded but `tap` will still wait until it resolves before passing the original value through.

		@param tapHandler (...: any) -> ...any
		@return Promise<...any>
	]=]
	tap: (self: Promise, tapHandler: (...any) -> ...any) -> Promise,
	--[=[
		Returns a new Promise that resolves if the chained Promise resolves within `seconds` seconds, or rejects if execution time exceeds `seconds`. The chained Promise will be cancelled if the timeout is reached.

		Rejects with `rejectionValue` if it is non-nil. If a `rejectionValue` is not given, it will reject with a `Promise.Error(Promise.Error.Kind.TimedOut)`. This can be checked with [[Error.isKind]].

		```lua
		getSomething():timeout(5):andThen(function(something)
			-- got something and it only took at max 5 seconds
		end):catch(function(e)
			-- Either getting something failed or the time was exceeded.

			if Promise.Error.isKind(e, Promise.Error.Kind.TimedOut) then
				warn("Operation timed out!")
			else
				warn("Operation encountered an error!")
			end
		end)
		```

		Sugar for:

		```lua
		Promise.race({
			Promise.delay(seconds):andThen(function()
				return Promise.reject(
					rejectionValue == nil
					and Promise.Error.new({ kind = Promise.Error.Kind.TimedOut })
					or rejectionValue
				)
			end),
			promise
		})
		```

		@param seconds number
		@param rejectionValue? any -- The value to reject with if the timeout is reached
		@return Promise
	]=]
	timeout: (self: Promise, seconds: number, rejectionValue: any?) -> Promise,
}

export type TypedPromise<T...> = {
	--[=[
		Chains onto an existing Promise and returns a new Promise.

		:::warning
		Within the failure handler, you should never assume that the rejection value is a string. Some rejections within the Promise library are represented by [[Error]] objects. If you want to treat it as a string for debugging, you should call `tostring` on it first.
		:::

		You can return a Promise from the success or failure handler and it will be chained onto.

		Calling `andThen` on a cancelled Promise returns a cancelled Promise.

		:::tip
		If the Promise returned by `andThen` is cancelled, `successHandler` and `failureHandler` will not run.

		To run code no matter what, use [Promise:finally].
		:::

		@param successHandler (...: any) -> ...any
		@param failureHandler? (...: any) -> ...any
		@return Promise<...any>
	]=]
	andThen: (
		self: Promise,
		successHandler: (T...) -> ...any,
		failureHandler: ((...any) -> ...any)?
	) -> Promise,
	--[=[
		Attaches an `andThen` handler to this Promise that calls the given callback with the predefined arguments. The resolved value is discarded.

		```lua
			promise:andThenCall(someFunction, "some", "arguments")
		```

		This is sugar for

		```lua
			promise:andThen(function()
			return someFunction("some", "arguments")
			end)
		```

		@param callback (...: any) -> any
		@param ...? any -- Additional arguments which will be passed to `callback`
		@return Promise
	]=]
	andThenCall: <TArgs...>(self: Promise, callback: (TArgs...) -> ...any, TArgs...) -> Promise,
	--[=[
		Attaches an `andThen` handler to this Promise that discards the resolved value and returns the given value from it.

		```lua
			promise:andThenReturn("some", "values")
		```

		This is sugar for

		```lua
			promise:andThen(function()
				return "some", "values"
			end)
		```

		:::caution
		Promises are eager, so if you pass a Promise to `andThenReturn`, it will begin executing before `andThenReturn` is reached in the chain. Likewise, if you pass a Promise created from [[Promise.reject]] into `andThenReturn`, it's possible that this will trigger the unhandled rejection warning. If you need to return a Promise, it's usually best practice to use [[Promise.andThen]].
		:::

		@param ... any -- Values to return from the function
		@return Promise
	]=]
	andThenReturn: (self: Promise, ...any) -> Promise,

	--[=[
		Yields the current thread until the given Promise completes. Returns true if the Promise resolved, followed by the values that the promise resolved or rejected with.

		:::caution
		If the Promise gets cancelled, this function will return `false`, which is indistinguishable from a rejection. If you need to differentiate, you should use [[Promise.awaitStatus]] instead.
		:::

		```lua
			local worked, value = getTheValue():await()

		if worked then
			print("got", value)
		else
			warn("it failed")
		end
		```

		@yields
		@return boolean -- `true` if the Promise successfully resolved
		@return ...any -- The values the Promise resolved or rejected with.
	]=]
	await: (self: Promise) -> (boolean, T...),
	--[=[
		Yields the current thread until the given Promise completes. Returns the Promise's status, followed by the values that the promise resolved or rejected with.

		@yields
		@return Status -- The Status representing the fate of the Promise
		@return ...any -- The values the Promise resolved or rejected with.
	]=]
	awaitStatus: (self: Promise) -> (Status, T...),

	--[=[
		Cancels this promise, preventing the promise from resolving or rejecting. Does not do anything if the promise is already settled.

		Cancellations will propagate upwards and downwards through chained promises.

		Promises will only be cancelled if all of their consumers are also cancelled. This is to say that if you call `andThen` twice on the same promise, and you cancel only one of the child promises, it will not cancel the parent promise until the other child promise is also cancelled.

		```lua
			promise:cancel()
		```
	]=]
	cancel: (self: Promise) -> (),
	--[=[
		Shorthand for `Promise:andThen(nil, failureHandler)`.

		Returns a Promise that resolves if the `failureHandler` worked without encountering an additional error.

		:::warning
		Within the failure handler, you should never assume that the rejection value is a string. Some rejections within the Promise library are represented by [[Error]] objects. If you want to treat it as a string for debugging, you should call `tostring` on it first.
		:::

		Calling `catch` on a cancelled Promise returns a cancelled Promise.

		:::tip
		If the Promise returned by `catch` is cancelled,  `failureHandler` will not run.

		To run code no matter what, use [Promise:finally].
		:::

		@param failureHandler (...: any) -> ...any
		@return Promise<...any>
	]=]
	catch: (self: Promise, failureHandler: (...any) -> ...any) -> Promise,
	--[=[
		Yields the current thread until the given Promise completes. Returns the values that the promise resolved with.

		```lua
		local worked = pcall(function()
			print("got", getTheValue():expect())
		end)

		if not worked then
			warn("it failed")
		end
		```

		This is essentially sugar for:

		```lua
		select(2, assert(promise:await()))
		```

		**Errors** if the Promise rejects or gets cancelled.

		@error any -- Errors with the rejection value if this Promise rejects or gets cancelled.
		@yields
		@return ...any -- The values the Promise resolved with.
	]=]
	expect: (self: Promise) -> T...,

	--[=[
		Set a handler that will be called regardless of the promise's fate. The handler is called when the promise is
		resolved, rejected, *or* cancelled.

		Returns a new Promise that:
		- resolves with the same values that this Promise resolves with.
		- rejects with the same values that this Promise rejects with.
		- is cancelled if this Promise is cancelled.

		If the value you return from the handler is a Promise:
		- We wait for the Promise to resolve, but we ultimately discard the resolved value.
		- If the returned Promise rejects, the Promise returned from `finally` will reject with the rejected value from the
		*returned* promise.
		- If the `finally` Promise is cancelled, and you returned a Promise from the handler, we cancel that Promise too.

		Otherwise, the return value from the `finally` handler is entirely discarded.

		:::note Cancellation
		As of Promise v4, `Promise:finally` does not count as a consumer of the parent Promise for cancellation purposes.
		This means that if all of a Promise's consumers are cancelled and the only remaining callbacks are finally handlers,
		the Promise is cancelled and the finally callbacks run then and there.

		Cancellation still propagates through the `finally` Promise though: if you cancel the `finally` Promise, it can cancel
		its parent Promise if it had no other consumers. Likewise, if the parent Promise is cancelled, the `finally` Promise
		will also be cancelled.
		:::

		```lua
		local thing = createSomething()

		doSomethingWith(thing)
			:andThen(function()
				print("It worked!")
				-- do something..
			end)
			:catch(function()
				warn("Oh no it failed!")
			end)
			:finally(function()
				-- either way, destroy thing

				thing:Destroy()
			end)

		```

		@param finallyHandler (status: Status) -> ...any
		@return Promise<...any>
	]=]
	finally: (self: Promise, finallyHandler: (status: Status) -> ...any) -> Promise,
	--[=[
		Same as `andThenCall`, except for `finally`.

		Attaches a `finally` handler to this Promise that calls the given callback with the predefined arguments.

		@param callback (...: any) -> any
		@param ...? any -- Additional arguments which will be passed to `callback`
		@return Promise
	]=]
	finallyCall: <TArgs...>(self: Promise, callback: (TArgs...) -> ...any, TArgs...) -> Promise,
	--[=[
		Attaches a `finally` handler to this Promise that discards the resolved value and returns the given value from it.

		```lua
			promise:finallyReturn("some", "values")
		```

		This is sugar for

		```lua
			promise:finally(function()
				return "some", "values"
			end)
		```

		@param ... any -- Values to return from the function
		@return Promise
	]=]
	finallyReturn: (self: Promise, ...any) -> Promise,

	--[=[
		Returns the current Promise status.

		@return Status
	]=]
	getStatus: (self: Promise) -> Status,
	--[=[
		Chains a Promise from this one that is resolved if this Promise is already resolved, and rejected if it is not resolved at the time of calling `:now()`. This can be used to ensure your `andThen` handler occurs on the same frame as the root Promise execution.

		```lua
		doSomething()
			:now()
			:andThen(function(value)
				print("Got", value, "synchronously.")
			end)
		```

		If this Promise is still running, Rejected, or Cancelled, the Promise returned from `:now()` will reject with the `rejectionValue` if passed, otherwise with a `Promise.Error(Promise.Error.Kind.NotResolvedInTime)`. This can be checked with [[Error.isKind]].

		@param rejectionValue? any -- The value to reject with if the Promise isn't resolved
		@return Promise
	]=]
	now: (self: Promise, rejectionValue: any?) -> Promise,
	--[=[
		Similar to [Promise.andThen](#andThen), except the return value is the same as the value passed to the handler. In other words, you can insert a `:tap` into a Promise chain without affecting the value that downstream Promises receive.

		```lua
			getTheValue()
			:tap(print)
			:andThen(function(theValue)
				print("Got", theValue, "even though print returns nil!")
			end)
		```

		If you return a Promise from the tap handler callback, its value will be discarded but `tap` will still wait until it resolves before passing the original value through.

		@param tapHandler (...: any) -> ...any
		@return Promise<...any>
	]=]
	tap: (self: Promise, tapHandler: (T...) -> ...any) -> Promise,
	--[=[
		Returns a new Promise that resolves if the chained Promise resolves within `seconds` seconds, or rejects if execution time exceeds `seconds`. The chained Promise will be cancelled if the timeout is reached.

		Rejects with `rejectionValue` if it is non-nil. If a `rejectionValue` is not given, it will reject with a `Promise.Error(Promise.Error.Kind.TimedOut)`. This can be checked with [[Error.isKind]].

		```lua
		getSomething():timeout(5):andThen(function(something)
			-- got something and it only took at max 5 seconds
		end):catch(function(e)
			-- Either getting something failed or the time was exceeded.

			if Promise.Error.isKind(e, Promise.Error.Kind.TimedOut) then
				warn("Operation timed out!")
			else
				warn("Operation encountered an error!")
			end
		end)
		```

		Sugar for:

		```lua
		Promise.race({
			Promise.delay(seconds):andThen(function()
				return Promise.reject(
					rejectionValue == nil
					and Promise.Error.new({ kind = Promise.Error.Kind.TimedOut })
					or rejectionValue
				)
			end),
			promise
		})
		```

		@param seconds number
		@param rejectionValue? any -- The value to reject with if the timeout is reached
		@return Promise
	]=]
	timeout: (self: Promise, seconds: number, rejectionValue: any?) -> Promise,
}

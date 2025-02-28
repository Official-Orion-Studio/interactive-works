local framework = require(game:GetService("ReplicatedStorage").lib)

local controller
do
    controller = {
        name = "MyController"
    }

    local function onStart(self)
        print("A controller has been loaded!")
    end

    controller.onStart = onStart

    local testingDelta = 0
    local function onRender(self, delta: number)
        if testingDelta <= 0 then
            testingDelta = testingDelta + delta

            print("Testing onRender: " .. testingDelta)
        end
    end

    controller.onRender = onRender
end

return framework.createController(controller)
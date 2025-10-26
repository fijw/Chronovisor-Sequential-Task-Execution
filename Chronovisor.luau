--[[
    @Library:
    ```
         ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ 
        |___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
                                                                                                                 
                                                                                                                 
         _                                                                                                     _ 
        | |                             _____ _                       _                                       | |
        | |                            |     | |_ ___ ___ ___ ___ _ _|_|___ ___ ___                           | |
        | |                            |   --|   |  _| . |   | . | | | |_ -| . |  _|                          | |
        | |                            |_____|_|_|_| |___|_|_|___|\_/|_|___|___|_|                            | |
        |_|                                                                                                   |_|
         _                                                                                                     _ 
        | |            _____               _                 _ _ _          __    _ _                         | |
        | |     ___   |  _  |___ ___ _____|_|___ ___ ___ ___| |_| |_ ___   |  |  |_| |_ ___ ___ ___ _ _       | |
        | |    | .'|  |   __|  _| . |     | |_ -| -_|_ -|___| | | '_| -_|  |  |__| | . |  _| .'|  _| | |      | |
        | |    |__,|  |__|  |_| |___|_|_|_|_|___|___|___|   |_|_|_,_|___|  |_____|_|___|_| |__,|_| |_  |      | |
        |_|                                                                                        |___|      |_|
         _                                                                                                     _ 
        | |                                 _        _          _____     _                                   | |
        | |                     _____ ___ _| |___   | |_ _ _   |  |  |___|_|___ ___ ___                       | |
        | |                    |     | .'| . | -_|  | . | | |  |    -| .'| |  _| . |_ -|                      | |
        | |                    |_|_|_|__,|___|___|  |___|_  |  |__|__|__,|_|_| |___|___|                      | |
        |_|                                             |___|                                                 |_|
                                                                                                                 
                                                                                                                 
         ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ ___ 
        |___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|
    ```

    @Description: Executes a function and allows for error handling.
    @Description: This can be used to double check things like
    @Description: trading, or other important functions, fully
    @Description: execute their sequential actions.

    @Example:
    ```luau
        local testFnPrint
        = function(inputNum: number)
            print("Test", inputNum)
        end

        local testFnWarn
        = function(err: string?, inputNum: number)
            warn(err, "Test", inputNum)
        end

        local testFnError
        = function()
            local a: any = ""
            a += 1
        end

        -- Basic testing.
        do
            local Test = Chronovisor(testFnPrint, 1)
                
            Test:afterSeconds(1):execute(testFnPrint, 2):afterSeconds(2):execute(testFnPrint, 3)
                        
            Test:execute(testFnPrint, 4):execute(testFnPrint, 5)
        end

        -- Loop testing.
        do
            -- Loop with no delay testing.
            do
                Chronovisor(function() print("hi lol") end)
                :onError("Chronovisor Stop")

                :afterSeconds(5)

                :execute(function() print("hi lol #2") end)
                :onError("Chronovisor Stop")

                :afterSeconds(2)

                :execute(function() print("hi lol #3") end)
                :onError("Chronovisor Stop")

                :loop()
            end

            -- Loop with delay testing.
            do
                Chronovisor(function() print("hi lol #4") end)
                :onError("Chronovisor Stop")

                :afterSeconds(5)

                :execute(function() print("hi lol #5") end)
                :onError("Chronovisor Stop")

                :loop(2)
            end
        end

        -- Extensive error catch testing.
        do
            Chronovisor(testFnPrint, 6)
            :onError(testFnWarn, 1)

            :afterSeconds(3)

            :execute(testFnPrint, 7)
            :onError(testFnWarn, 2)

            :execute(testFnError)
            :onError(
                function(err: string?)
                    warn(err, "Stop error test 1! (stopping)")
                end,

                "Chronovisor Stop"
            )

            :execute(
                function()
                    local a: any = ""
                    a += 1

                    print("Stop error test 2! (should be stopped)")
                end
            )
            :onError("Chronovisor Stop")

            :execute(
                function()
                    print("Stop error test 3! (should be extra stopped)")
                end
            )
            :onError(
                function(err: string?, inputNum: number)
                    warn(err, inputNum)
                end,

                2
            )
        end
    ```
]]
--!strict
--!optimize 2


local HttpService = game:GetService("HttpService")


--[[ @section Types ]]
type ChronovisorStop = "Chronovisor Stop"


type ErrorCallbackType<T...> = (err: string?, T...) -> (...any)
type ExecuteCallbackType<T...> = (T...) -> (...any)


type DestroyedChronovisor = setmetatable
<
    {},

    {
        __call: (self: DestroyedChronovisor) -> (DestroyedChronovisor),

        __index
        : {
            onError: (self: DestroyedChronovisor) -> (DestroyedChronovisor),
            execute: (self: DestroyedChronovisor) -> (DestroyedChronovisor),

            afterSeconds: (self: DestroyedChronovisor) -> (DestroyedChronovisor),

            destroy: (self: DestroyedChronovisor) -> (DestroyedChronovisor),

            loop: (self: DestroyedChronovisor) -> (DestroyedChronovisor)
        }
    }
>


type Inheritance
= {
    onError
    : <U...>(
        self: Chronovisor,
        input: ErrorCallbackType<U...> | ChronovisorStop,
        U...
    ) -> (Chronovisor),

    execute: <P...>(self: Chronovisor, func: ExecuteCallbackType<P...>, P...) -> (Chronovisor),
    afterSeconds: (self: Chronovisor, seconds: number) -> (Chronovisor),

    destroy: (self: Chronovisor) -> (DestroyedChronovisor),

    loop: (self: Chronovisor, delay: number?) -> (Chronovisor)
}

type Chronovisor = setmetatable
<
    {
        id: string,

        success: boolean?,
        err: string?,


        waits: number?,
        
        catchesErrors: { func: ErrorCallbackType<...any>, params: { any } }?,
        executes: { func: ExecuteCallbackType<...any>, params: { any } }?,


        PreviousSteps: { [string]: Chronovisor }?
    },

    { __index: Inheritance }
>
--[[ @end_section Types ]]


--[[ @section Variables ]]
local Constructor = {}
local Inheritance = {} :: Inheritance

local Chronovisor = {}
--[[ @end_section Variables ]]


--[[ @section Constructor ]]
--[[
    Usage: Prevent errors with an inputted function.
    param    func    ExecuteCallbackType<P...>
    param    ...    <P...>
    Return: Chronovisor
]]
function Constructor:__call<P...>(func: ExecuteCallbackType<P...>, ...: P...): Chronovisor
    local success, err = pcall(func, ...)

    local NewChronovisor
    = {
        id = HttpService:GenerateGUID(false),
        PreviousSteps = {}
    } :: Chronovisor

    setmetatable(NewChronovisor :: Chronovisor, { __index = Inheritance })

    -- Add the new Chronovisor to it's own previous steps.
    do
        local ClonedChronovisor = NewChronovisor

        ClonedChronovisor.PreviousSteps = nil
        ClonedChronovisor.executes = { func = func, params = { ... } }

        ClonedChronovisor.success = success
        ClonedChronovisor.err = err;

        NewChronovisor.PreviousSteps = { [NewChronovisor.id] = ClonedChronovisor }
    end

    return NewChronovisor
end

setmetatable(Chronovisor, { __call = Constructor.__call })
--[[ @end_section Constructor ]]


--[[ @section Inheritance ]]
--[[
    Usage: Handles errors with an inputted function.
    param    func   ErrorCallbackType<U...> | ChronovisorStop
    param    ...    <U...>
    Return: Chronovisor | DestroyedChronovisor
]]
function Inheritance:onError
<U...>(
    input: ErrorCallbackType<U...> | ChronovisorStop,
    ...: U...
): Chronovisor | DestroyedChronovisor
    -- Add the catches errors table to the self steps.
    do
        local FoundChronovisor = (self.PreviousSteps :: { [string]: Chronovisor })[self.id]
        if not FoundChronovisor then return self end

        FoundChronovisor.catchesErrors
        = {
            func = input :: ErrorCallbackType<...any>,
            params = { ... }
        }
    end

    if typeof(input) == "string" and input == "Chronovisor Stop" then
        assert(typeof(input) == "string", "Input must be a string.")

        if not self.success then
            local DestroyedChronovisor = self:destroy()
            return DestroyedChronovisor
        end
    elseif typeof(input) == "function" then
        assert(typeof(input) == "function", "Input must be a function.")

        if not self.success then
            input(self.err, ...)

            local Args = { ... }
            if Args[1] ~= "Chronovisor Stop" :: any then return self end

            local DestroyedChronovisor = self:destroy()
            return DestroyedChronovisor
        end
    end

    return self
end

--[[
    Usage: Waits for a number of seconds.
    param    seconds    number
    Return: Chronovisor?
]]
function Inheritance:afterSeconds(seconds: number): Chronovisor?
    -- Add the waits seconds to the self steps.
    do
        local FoundChronovisor = (self.PreviousSteps :: { [string]: Chronovisor })[self.id]
        if not FoundChronovisor then return nil end

        FoundChronovisor.waits = seconds
    end

    task.wait(seconds)

    return self
end

--[[
    Usage: Creates a new Chronovisor.
    param    func    ExecuteCallbackType<P...>
    param    ...    <P...>
    Return: Chronovisor?
]]
function Inheritance:execute<P...>(func: ExecuteCallbackType<P...>, ...: P...): Chronovisor?
    local NewChronovisor = Chronovisor(func, ...)
    if not NewChronovisor then return nil end

    for i: string, v: Chronovisor in pairs(self.PreviousSteps :: { [string]: Chronovisor }) do
        v.PreviousSteps = nil

        (NewChronovisor.PreviousSteps :: { [string]: Chronovisor })[i] = v
    end

    return NewChronovisor
end

--[[
    Usage: Destroys the Chronovisor.
    Return: DestroyedChronovisor
]]
function Inheritance:destroy(): DestroyedChronovisor
    self.success = nil
    self.err = nil

    setmetatable(self :: DestroyedChronovisor,
        {
            __call = function() return self end,

            __index
            = {
                onError = function() return self end,
                execute = function() return self end,

                afterSeconds = function() return self end,

                destroy = function() return self end
            }
        }
    )

    local DestroyedChronovisor = self :: DestroyedChronovisor
    return DestroyedChronovisor
end

--[[
    Usage: Loops the Chronovisor.
    Return: Chronovisor
]]
function Inheritance:loop(delay: number?): Chronovisor
    while task.wait(delay) do
        for i: string, v: Chronovisor in pairs(self.PreviousSteps :: { [string]: Chronovisor }) do
            local unpackedParams = table.unpack((v.executes :: { [string]: any }).params)

            if (v.executes :: { [string]: any }).func then v.executes.func(unpackedParams) end
            if (v.catchesErrors :: { [string]: any }).func and not v.success then v.catchesErrors.func(unpackedParams) end
            if v.waits then task.wait(v.waits) end
        end
    end

    return self
end
--[[ @end_section Inheritance ]]


table.freeze(Chronovisor)
return Chronovisor

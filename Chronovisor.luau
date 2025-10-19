--[[
    @Framework:
    ```
         /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$  
        |______/|______/|______/|______/|______/|______/|______/|______/|______/|______/|______/|______/|______/|______/  
                                                                                                                  
                                                                                                                  
                                                                                                                  
         /$$       /$$$$$$$              /$$                                   /$$             /$$   /$$              /$$ 
        | $$      | $$__  $$            | $$                                  |__/            | $$  | $/             | $$ 
        | $$      | $$  \ $$ /$$   /$$ /$$$$$$    /$$$$$$   /$$$$$$   /$$$$$$  /$$  /$$$$$$$ /$$$$$$|_//$$$$$$$      | $$ 
        |__/      | $$$$$$$ | $$  | $$|_  $$_/   /$$__  $$ /$$__  $$ /$$__  $$| $$ /$$_____/|_  $$_/  /$$_____/      |__/ 
         /$$      | $$__  $$| $$  | $$  | $$    | $$$$$$$$| $$  \ $$| $$$$$$$$| $$|  $$$$$$   | $$   |  $$$$$$        /$$ 
        | $$      | $$  \ $$| $$  | $$  | $$ /$$| $$_____/| $$  | $$| $$_____/| $$ \____  $$  | $$ /$$\____  $$      | $$ 
        | $$      | $$$$$$$/|  $$$$$$$  |  $$$$/|  $$$$$$$|  $$$$$$$|  $$$$$$$| $$ /$$$$$$$/  |  $$$$//$$$$$$$/      | $$ 
        |__/      |_______/  \____  $$   \___/   \_______/ \____  $$ \_______/|__/|_______/    \___/ |_______/       |__/ 
                             /$$  | $$                     /$$  \ $$                                                      
                            |  $$$$$$/                    |  $$$$$$/                                                      
                             \______/                      \______/                                                       
         /$$       /$$$$$$$$                                                                           /$$             /$$
        | $$      | $$_____/                                                                          | $$            | $$
        | $$      | $$     /$$$$$$  /$$$$$$  /$$$$$$/$$$$   /$$$$$$  /$$  /$$  /$$  /$$$$$$   /$$$$$$ | $$   /$$      | $$
        |__/      | $$$$$ /$$__  $$|____  $$| $$_  $$_  $$ /$$__  $$| $$ | $$ | $$ /$$__  $$ /$$__  $$| $$  /$$/      |__/
         /$$      | $$__/| $$  \__/ /$$$$$$$| $$ \ $$ \ $$| $$$$$$$$| $$ | $$ | $$| $$  \ $$| $$  \__/| $$$$$$/        /$$
        | $$      | $$   | $$      /$$__  $$| $$ | $$ | $$| $$_____/| $$ | $$ | $$| $$  | $$| $$      | $$_  $$       | $$
        | $$      | $$   | $$     |  $$$$$$$| $$ | $$ | $$|  $$$$$$$|  $$$$$/$$$$/|  $$$$$$/| $$      | $$ \  $$      | $$
        |__/      |__/   |__/      \_______/|__/ |__/ |__/ \_______/ \_____/\___/  \______/ |__/      |__/  \__/      |__/
                                                                                                                  
                                                                                                                  

         /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$ /$$$$$$  
        |______/|______/|______/|______/|______/|______/|______/|______/|______/|______/|______/|______/|______/|______/  
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


        local Test = Chronovisor(testFnPrint, 1)
        
        Test:afterSeconds(1):execute(testFnPrint, 2):afterSeconds(2):execute(testFnPrint, 3)
                
        Test:execute(testFnPrint, 4):execute(testFnPrint, 5)

        Chronovisor(testFnPrint, 6)
        :onError(testFnWarn, 1)

        :afterSeconds(3)

        :execute(testFnPrint, 7)
        :onError(testFnWarn, 2)

        :execute(testFnError)
        :onError(
            {
                func
                = function(err: string?)
                    warn(err, "Stop error test 1! (stopping)")
                end,

                thenStop = "stop"
            }
        )

        :execute(
            function()
                local a: any = ""
                a += 1

                print("Stop error test 2! (should be stopped)")
            end
        )
        :onError("stop")

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
    ```
]]
--!strict
--!optimize 2


--[[ @section Types ]]
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
        }
    }
>


type Inheritance
= {
    onError: <U...>(
        self: Chronovisor,

        input: ErrorCallbackType<U...>
        | "stop"
        | {
            func: ErrorCallbackType<U...>,
            thenStop: "stop"
        },
        
        U...
    ) -> (Chronovisor),

    execute: <P...>(self: Chronovisor, func: ExecuteCallbackType<P...>, P...) -> (Chronovisor),
    afterSeconds: (self: Chronovisor, seconds: number) -> (Chronovisor),

    destroy: (self: Chronovisor) -> (DestroyedChronovisor),
}

type Chronovisor = setmetatable
<
    {
        success: boolean?,
        err: string?
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
        success = success,
        err = err
    } :: Chronovisor

    setmetatable(NewChronovisor :: Chronovisor, { __index = Inheritance })

    return NewChronovisor
end

setmetatable(Chronovisor, { __call = Constructor.__call })
--[[ @end_section Constructor ]]


--[[ @section Inheritance ]]
--[[
    Usage: Handles errors with an inputted function.
    param    func   ErrorCallbackType<U...>
    param    ...    <U...>
    Return: Chronovisor
]]
function Inheritance:onError<U...>
(
    input: ErrorCallbackType<U...>
    | "stop"
    | {
        func: ErrorCallbackType<U...>,
        thenStop: "stop"
    },

    ...: U...
): Chronovisor?
    if typeof(input) == "string" and input == "stop" then
        assert(typeof(input) == "string", "Input must be a string.")

        if not self.success then
            local DestroyedChronovisor = self:destroy()
            return DestroyedChronovisor
        end
    elseif typeof(input) == "function" then
        assert(typeof(input) == "function", "Input must be a function.")
        if not self.success then input(self.err, ...) end
    elseif typeof(input) == "table" and input.thenStop == "stop" then
        assert(typeof(input) == "table", "Input must be a table.")

        if not self.success then
            input.func(self.err, ...)

            local DestroyedChronovisor = self:destroy()
            return DestroyedChronovisor
        end
    end

    return self
end

--[[
    Usage: Waits for a number of seconds.
    param    seconds    number
    Return: Chronovisor
]]
function Inheritance:afterSeconds(seconds: number): Chronovisor
    task.wait(seconds)

    return self
end

--[[
    Usage: Creates a new Chronovisor.
    param    func    ExecuteCallbackType<P...>
    param    ...    <P...>
    Return: Chronovisor
]]
function Inheritance:execute<P...>(func: ExecuteCallbackType<P...>, ...: P...): Chronovisor
    local NewChronovisor = Chronovisor(func, ...)
    return NewChronovisor
end

--[[
    Usage: Destroys the Chronovisor.
    Return
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
--[[ @end_section Inheritance ]]


table.freeze(Chronovisor)
return Chronovisor

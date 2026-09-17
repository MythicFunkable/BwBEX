--[[

░████████                     ░████████   ░██████████ ░██    ░██ 
░██    ░██                    ░██    ░██  ░██          ░██  ░██  
░██    ░██  ░██    ░██    ░██ ░██    ░██  ░██           ░██░██   
░████████   ░██    ░██    ░██ ░████████   ░█████████     ░███    
░██     ░██  ░██  ░████  ░██  ░██     ░██ ░██           ░██░██   
░██     ░██   ░██░██ ░██░██   ░██     ░██ ░██          ░██  ░██  
░█████████     ░███   ░███    ░█████████  ░██████████ ░██    ░██ 
                                                                 
                a BwBEXtension library!                                      
                                                                 
    A library of various feature additions made from
    the ideas of other members in the community

    The credits of any inspiration that I take will be 
    provided above the function itself
    
    Made by Sempur Mythica
    Credits to psq95, sufferneer, and CatChris for their 
    existing knowledge and scripts!

]]

---@class BwBEX
---@field scraps table
---@field smoothInflate table
---@field pressureLink table
---@field linkAnimation table
---@field animateTexture table
---@field vibrate table
---@field float table
---@field PehkuiLink table
---@field PlayerAlive boolean
local BwBEX = {
    paused = false,
    BwB = client:isModLoaded("better_with_blimps"),
    scraps = {},
    smoothInflate = {},
    pressureLink = {},
    pressureLoop = {},
    linkAnimation = {},
    animateTexture = {},
    overinflate = {},
    vibrate = {},
    float = {},
    inflate = {},
    deflate = {},
    PehkuiLink = {},
    maxPressureAnimation = {},
    pressure = 0,
    maxPressure = 20,
    floatEffectBlacklist = {
        "better_with_blimps.juiced",
        "better_with_blimps.waterlogged"
    },
    PlayerAlive = true
}
BwBEX.__index = BwBEX
---@return BwBEX

if not BwBEX.BwB then print("Better with Blimps is not installed! BwBEX is off") end

-- Basic functions
local function RandomFloat(min, max)
    return min + math.random() * (max - min)
end

local function GetDelta(LastClientTime)
    return (client.getSystemTime()-LastClientTime)/100
end

local function GetPressure()
    -- -- Clear the old slot just incase
    -- BwBEX.pressureSlot = nil

    -- if player:isLoaded() and BwBEX.BwB and BwBEX.PlayerAlive then
    --     local NBTAttribs = player:getNbt().Attributes
    --     local AttributeName = "better_with_blimps:inflated_attribute"

    --     local function FetchNBTSlot()
    --         for i,v in pairs(NBTAttribs) do
    --             if NBTAttribs[i].Name == AttributeName then
    --                 BwBEX.pressureSlot = i -- this search should only be needed once
    --                 break
    --             end
    --         end

    --         return BwBEX.pressureSlot
    --     end

    --     local Value = NBTAttribs[FetchNBTSlot()].Base

    --     if not type(Value) == "number" or not Value then
    --         Value = 0
    --     end

    --     return Value
    -- end

    -- return 0

    BwBEX.pressureSlot = nil

    if player:isLoaded() and player:isAlive() then
        --Afterwards, we make an anti break check to ensure that the bookmarked location is not invalid, and if it is we reset the bookmark to prevent an infinite break and skip this check entirely
        if(player:getNbt()["Attributes"][BwBEX.pressureSlot] == nil) then
            BwBEX.pressureSlot = 1
            BwBEX.pressure = 0
        end

        --Then we check the bookmarked location for the value. If it is right we use that
        if(player:getNbt()["Attributes"][BwBEX.pressureSlot]["Name"] == "better_with_blimps:inflated_attribute") then
            BwBEX.pressure = player:getNbt()["Attributes"][BwBEX.pressureSlot]["Base"]
        else
            --if it fails, we then search to find it, and break once we do to prevent unneeded searches
            for i, v in pairs(player:getNbt()["Attributes"]) do
                if(player:getNbt()["Attributes"][i]["Name"] == "better_with_blimps:inflated_attribute") then
                    --We also set a new bookmark here, via a second value called InfSlot. This gives us an easy way to skip searches in the future
                    BwBEX.pressureSlot = i
                    BwBEX.pressure = player:getNbt()["Attributes"][i]["Base"]
                end
            end
        end
    end
    
    --If the number is invalid, or was never set because the player isn't loaded / alive, we default it to 0
    if(type(BwBEX.pressure) ~= "number") then
        BwBEX.pressure = 0
    end

    --Finally, we return the stored inflation value
    return BwBEX.pressure
end

local function CountDict(dict)
    local count = 0
    for _,__ in pairs(dict) do
        count = count + 1
    end
    return count
end

local function FindValueInTable(table, value)
    for _,v in pairs(table) do
        if v == value then
            return true
        end
    end
end

--- Returns a clone of a specified table
---@param tbl table Table of contents to clone
local function CloneTable(tbl)
    local tbl_type = type(tbl)
    local copy
    if tbl_type == 'table' then
        copy = {}
        for tbl_key, tbl_value in pairs(tbl) do
            copy[tbl_key] = tbl_value
        end
    else -- number, string, boolean, etc
        copy = tbl
    end
    
    return copy or nil
end

local function SearchTable(tbl, obj)
    for index,value in ipairs(tbl) do
        if value == obj then
            return index, value
        end
    end
    
    return nil
end

--- Function that checks for a specified status effect, returning `false` if none is found and `nil` if the player is not loaded
---@param requested string The effect to look for
local function CheckForStatus(requested)
    if not player:isLoaded() then return end

    local effects = BwBEX.currentStatuses
    if not effects then return nil end

    for _,effect in pairs(effects) do
        if string.find(effect.name, requested) then
            return effect
        end
    end

    return false
end

-- Main loop
if BwBEX.BwB then
    function events.tick()
        -- why do i have to check if the player is LOADED ALL THE TIME!!!!!!
        if player:isLoaded() then
            -- Pressure slot check that must be done for some reason
            if player:isAlive() ~= BwBEX.PlayerAlive then
                -- on the last tick, we were dead, but now we're alive
                BwBEX.pressureSlot = nil
            end
            BwBEX.PlayerAlive = player:isAlive()
        end
        
        -- Paused check
        BwBEX.paused = client:isPaused() and #world:getPlayers() < 2 and host:isHost()

        if not BwBEX.paused and BwBEX.PlayerAlive then -- the amount of CHECKS i have to run!
            -- BwBEX.pressure = GetPressure()
            GetPressure()
            BwBEX.currentStatuses = host:getStatusEffects()
        end
    end
end


-- API functions

---Credit to sufferneer!! Provide a dictionary of model parts to cause them to vibrate when your pressure reaches a specific threshold.
---@param dict table A dictionary of contents describing the intensity of the vibration effect on the selected model parts. Example of a valid dictionary will be provided below this function.
---@param threshold number? A percentage of the meter that must be filled before this effect become noticable. 0 is no pressure, 1 is max pressure. If no number is provided, the default is 0.6 (60%).
---@param options table? A table containing additional initial configurations for this object.
function BwBEX.vibrate:new(dict, threshold, options)
    if not BwBEX.BwB then return end

    self = setmetatable({}, BwBEX.vibrate)
    self.__index = self
    self.parts = dict
    self.threshold = threshold or 0.6
    self.threshold = math.clamp(self.threshold, 0, 1)
    self.MaxPressureSize = 0.01
    self.Speed = 1
    self.strainIntensity = 1
    self.shakeIntensity = 1
    self.rotationAngle = 2

    if options then -- throws an error without this
        self.Speed = options.Speed or 1
        self.strainIntensity = options.strainIntensity or 1
        self.shakeIntensity = options.shakeIntensity or 1
        self.rotationAngle = options.rotationAngle or 2
    end
    
    local Pressurized = false
    local LastStrainDelta = client.getSystemTime()
    local DeltaSum = 0
    local MaxSum = 1
    local PressureSize = RandomFloat(0.0025, self.MaxPressureSize)

    local GoalRotations = {}

    local function ResetGoalRotations()
        GoalRotations = {}
        
        if self.rotationAngle == 0 then return end -- means this module is DISABLED!

        for _,object in pairs(self.parts) do
            for _,part in pairs(object) do
                GoalRotations[part] = vec(RandomFloat(-self.rotationAngle, self.rotationAngle), RandomFloat(-self.rotationAngle, self.rotationAngle), RandomFloat(-self.rotationAngle, self.rotationAngle))
            end
        end
    end

    ResetGoalRotations()

    local function SetScaleOfPart(part, scale)
        if type(part) == "ModelPart" then
            -- this is a part!
            part:setOffsetScale(scale)
        else
            -- this is a table!
            for _,object in pairs(part) do
                object:setOffsetScale(scale)
            end
        end
    end

    local function SetRotOfPart(part, rotation)
        if type(part) == "ModelPart" then
            -- this is a part!
            part:setOffsetRot(rotation)
        else
            -- this is a table!
            for _,object in pairs(part) do
                object:setOffsetRot(rotation)
            end
        end
    end

    function events.post_render()
        local delta = GetDelta(LastStrainDelta) -- WHY DID YOU MAKE ME DO THIS.
        local PseudoRandomIntensity = RandomFloat(0.25, 2) -- Randomness
        local CurrentThreshold = BwBEX.pressure/BwBEX.maxPressure

        if not BwBEX.paused then            
            if CurrentThreshold >= self.threshold then
                local deltaTime = (1/20 * (self.Speed/10)) / delta -- Modifying the speed of the effect. Divided by delta for frame time consistencies (otherwise it'll get slower the worse your frames are)

                -- computing 
                local Strength = math.lerp(0, 1, (CurrentThreshold-self.threshold)/(1-self.threshold)) -- Figuring out how strong the effect should be overall
                local arithmetic = ((Strength * PseudoRandomIntensity) * (PressureSize * (math.sin(math.pi * DeltaSum)))) -- The actual math in determining how much to add to the offset scale
                
                for tension, partTable in pairs(self.parts) do
                    for _,part in pairs(partTable) do
                        SetScaleOfPart(part, 1 + (arithmetic * (self.strainIntensity * tension)))
                        SetRotOfPart(part, (GoalRotations[part] or vec(0,0,0)) * ((arithmetic * 20) * (self.shakeIntensity * tension))) -- arithmetic * 20 makes it ROUGHLY visible, since arithmetic is way too small for it
                    end
                end

                DeltaSum = DeltaSum + deltaTime
                
                if not Pressurized then
                    Pressurized = true
                end
            else
                if Pressurized then
                    for _,partTable in pairs(self.parts) do
                        for _,part in pairs(partTable) do
                            -- part:setOffsetScale(1)
                            SetScaleOfPart(part, 1)
                            SetRotOfPart(part, vec(0, 0, 0))
                        end
                    end
                    Pressurized = false
                end
            end

            if DeltaSum > MaxSum then
                DeltaSum = 0
                -- Make a new pseudo random part size for the next one
                PressureSize = RandomFloat(0.0025, self.MaxPressureSize)
                -- GoalRot = vec(RandomFloat(0, 2), RandomFloat(0, 2), RandomFloat(0, 2))
                ResetGoalRotations()
                PseudoRandomIntensity = RandomFloat(0.25, 2)
            end
        end

        LastStrainDelta = client.getSystemTime()
    end

    function events.world_tick()
        local math = BwBEX.pressure/BwBEX.maxPressure

        if math ~= CurrentThreshold then
            CurrentThreshold = math
        end
    end

    return self
end

--[[

    Example of a valid vibrate model table
    local Parts = {
        [2] = { -- intensity, table containing parts
            modelpaths.HighBelly,
            modelpaths.MidBelly,
            modelpaths.LowBelly,
        },
        [0.5] = {
        -- Creaking butt
            modelpaths.Butt
        },
        [1] = {
            -- Creaking cheeks
            modelpaths.Head.BloatFeatures.RightMawCheek,
            modelpaths.Head.BloatFeatures.LeftMawCheek,
        }
    }

]]


---Causes your body to float! Scales with pressure.
---@param model ModelPart The root folder of your model to float! Example: models["bbmodel"].root
---@param blacklist boolean? Should this module be disabled while you possess certain status effects? (Check floatEffectBlacklist for the effects)
---@param threshold number? A percentage of the inflation in decimal form (a float from 0 to 1) that you want to begin floating at. Default is 0.2 (20%)
---@param intensity number? A value that determines how intense the effect is. It scales with your inflation linearly, so do keep that in mind! Default is 1.
---@param offset number? A value to determine the original offset of your model. This will help you keep the model from clipping into the floor when this module is active!
function BwBEX.float:new(model, blacklist, threshold, intensity, offset)
    if not BwBEX.BwB then return end

    self = setmetatable({}, BwBEX.float)
    self.__index = self
    self.threshold = threshold or (1/5)
    self.threshold = math.clamp(self.threshold, 0, 1)
    self.intensity = intensity or 1
    self.blacklist = blacklist or true
    self.offset = offset or 1.5
    self.speed = 1 -- How fast the effect is

    local LastFloatDelta = client.getSystemTime()
    local DeltaFloatSum = 0
    local DeltaFloatMax = 2

    local function VerifyBlacklist()
        if not self.blacklist then return false end

        for _,value in pairs(BwBEX.floatEffectBlacklist) do
            local status = CheckForStatus(value)

            if status then return true end
        end

        return false
    end

    function events.post_render(_, context)
        local delta = GetDelta(LastFloatDelta)
        local CurrentThreshold = BwBEX.pressure/BwBEX.maxPressure

        if not BwBEX.paused and context ~= "FIRST_PERSON" then
            if BwBEX.pressure > (BwBEX.maxPressure*self.threshold) and not VerifyBlacklist() then
                local deltaTime = (1/20 * (self.speed/500)) / delta -- Modifying the speed of the effect. Divided by delta for frame time consistencies (otherwise it'll get slower the worse your frames are)
                local Strength = math.lerp(0, 1, (CurrentThreshold-self.threshold)/(1-self.threshold)) -- Figuring out how strong the effect should be overall

                local arithmetic = ((Strength * self.intensity) * (math.sin(math.pi * DeltaFloatSum)))

                -- uhhhhHhhh time management i think,
                DeltaFloatSum = DeltaFloatSum + deltaTime

                model:setPos(vec(0, arithmetic+(self.offset * Strength), 0))
            else
                DeltaFloatSum = 0
                model:setPos(vec(0, 0, 0))
            end

            if DeltaFloatSum > DeltaFloatMax then
                DeltaFloatSum = 0
            end
        end

        LastFloatDelta = client.getSystemTime()
    end

    return self
end

--- Credit to psq95!
--- Smooths out your inflation depending on the provided smoothing value. Designed to REPLACE the existing animinflate from the BwBAPI! Called as a variable, which returns the target time.
---@param anim Animation The inflation animation to link to this function
---@param smoothing number? A smoothing value for the inflation animation. Default is 40.
function BwBEX.smoothInflate:new(anim, smoothing)
    if not BwBEX.BwB then return end
    self = setmetatable({}, BwBEX.smoothInflate)
    self.__index = self

    self.targetTime = 0
    self.anim = anim
    self.smoothing = smoothing or 40
    self.smoothing = math.max(1, self.smoothing)

    -- setup animation
    self.anim:play()
    self.anim:pause()
    self.anim:setTime(0)

    function events.render()
        self.targetTime = (BwBEX.pressure / BwBEX.maxPressure) * self.anim:getLength()

        if self.anim:getTime() == self.targetTime then return end -- This should not be running when the player is not inflating

        local mathz = self.anim:getTime() + (self.targetTime - self.anim:getTime()) / (self.smoothing)

        if mathz > self.anim:getLength() then
            error(string.format("Value 'mathz' tried to go above the maximum:\n%s vs %s", mathz, self.anim:getLength()))
        end

        mathz = math.clamp(mathz, 0, self.anim:getLength()) -- Clamp the value
        self.anim:setTime(mathz)
    end

    return self
end

---Adds scrap models to inflated death if Confetti is located
---@param model ModelPart|table The PRIMARY model. This may also be a table, incase you have multiple models to toggle.
---@param scraps ModelPart The scraps model. Proper format provided in wiki
---@param threshold number? A percentage of the inflation in decimal form (a float from 0 to 1) that you want the game to summon scraps at. Default is 0.5 (50%)
function BwBEX.scraps:new(model, scraps, threshold)
    if not BwBEX.BwB then return end

    self = setmetatable({}, BwBEX.scraps)
    self.__index = self
    self.model = model
    self.scraps = scraps
    self.threshold = threshold or 0.5
    self.threshold = math.clamp(self.threshold, 0, 1)

    local Confetti
    for _, path in ipairs(listFiles("/", true)) do
        if string.find(path, "confetti") then Confetti = require(path) break end
    end

    assert(Confetti, "Confetti was not located in your model! Please add it before using this function")
    
    --- 'False' is visible
    local function UpdateModelVisibility(state)
        local value = state and 1 or 0

        if type(model) == "ModelPart" then
            -- this is a model
            self.model:setOpacity(value)
        else
            -- this is a table!
            for index,part in ipairs(self.model) do
                part:setOpacity(value)
            end
        end
    end

    -- register meshes
    local MeshTbl = {}

    for index,child in pairs(self.scraps:getChildren()) do
        -- register mesh
        Confetti.registerMesh(child:getName(), child)
        table.insert(MeshTbl, index, child:getName())
    end
    
    local dead = false
    function events.tick()
        if BwBEX.pressure > (BwBEX.maxPressure * self.threshold) then
            if not player:isAlive() and not dead then
                -- make model invisible immediately
                UpdateModelVisibility(false)
                
                -- create particle
                for _,meshName in pairs(MeshTbl) do
                    for i=0, math.random(16, 64), 1 do
                        local Position = player:getPos():add(vec(math.random(-100, 100) / 75, math.random(0, 200) / 100, math.random(-100, 100) / 75))
                        local Velocity = vec((math.random(-100, 100) / 100)  * 1.5, (math.random(-25, 100) / 100) * 1.5, (math.random(-100, 100) / 100)  * 1.5)
                        
                        local ScrapOptions = { -- This has to be initiated for *each* particle
                            lifetime = math.random(1200,2400),
                            friction = 0.90,
                            scale  = math.random(100,200) / 100,
                            acceleration = vec(0,-0.025,0),
                            rotation = vec(math.random(0,180),math.random(0,180),math.random(0,180)),
                            rotationOverTime = vec(math.random(-10,10),math.random(-10,10),math.random(-10,10)),
                            ticker = function(particle)
                                local x,y,z = particle.velocity:unpack()
                                if (world.getBlockState(particle._position+vec(x,0,0)):isSolidBlock() or world.getBlockState(particle._position-vec(x,0,0)):isSolidBlock() or world.getBlockState(particle._position+vec(0,y,0)):isSolidBlock() or world.getBlockState(particle._position-vec(0,y,0)):isSolidBlock() or world.getBlockState(particle._position+vec(0,0,z)):isSolidBlock() or world.getBlockState(particle._position-vec(0,0,z)):isSolidBlock()) then
                                    if(particle.lifetime < particle.options["lifetime"] - 5) then
                                    particle.velocity = vec(0,0,0)
                                    particle.options["rotationOverTime"] = vec(0,0,0)
                                    particle.options["acceleration"] = vec(0,0,0)
                                    particle.options["friction"] = 0
                                    end
                                end
                                Confetti.defaultTicker(particle)
                            end
                        }

                        Confetti.newParticle(meshName, Position, Velocity, ScrapOptions)
                    end
                end

                -- finally, set dead variable
                dead = true
            end
        end

        if player:isAlive() and dead then
            -- we just came back to life
            -- update model visibility
            UpdateModelVisibility(true)
            dead = false
        end
    end

    return self
end

--- A function dedicated to creating pressure links. At the specified threshold, run the specified function constantly. Simple!
--- This function runs every WORLD tick! It may lag behind when the server you're playing on is struggling.
--- Recommended to send a ping function through this, especially in regards to player changes.
---@param threshold number The percent threshold on the inflation meter, in decimal form, to start the link
---@param linkFunc function The function you want to run at this threshold. Has an innate argument: the player's pressure.
function BwBEX.pressureLink:new(threshold, linkFunc)
    if not BwBEX.BwB then return end
    self = setmetatable({}, BwBEX.pressureLink)
    self.__index = self
    self.linkedFunction = linkFunc
    self.threshold = self.threshold
    self.active = nil -- nil because we want this to update once on first run

    local LastActive = self.active

    function events.world_tick()
        self.active = BwBEX.pressure > (BwBEX.maxPressure*threshold) -- check if the current pressure is past the specified threshold

        if LastActive ~= self.active then -- if it needs to be checked
            linkFunc(self.active) -- run the linked function
        end

        LastActive = self.active
    end

    return self
end

--- Mirror of pressureLink, except it still so long as the threshold is met.
--- This function runs every WORLD tick! It may lag behind when the server you're playing on is struggling.
---@param threshold number The percent threshold on the inflation meter, in decimal form, to start the link
---@param linkFunc function The function you want to run at this threshold. Has an innate argument: the player's pressure.
function BwBEX.pressureLoop:new(threshold, linkFunc)
    if not BwBEX.BwB then return end
    self = setmetatable({}, BwBEX.pressureLink)
    self.__index = self
    self.linkedFunction = linkFunc
    self.threshold = threshold

    function events.world_tick()
        if BwBEX.pressure > (BwBEX.maxPressure*self.threshold) then
            linkFunc()
        end
    end

    return self
end

--- Credit to Sufferneer once again!
--- A function that will play a dedicated animation inbetween a specific period of time. 
--- Good for animations that will play when you reach a certain size (e.g. your butt suddenly inflating)
---@param anim Animation The animation you want to play at the specified size.
---@param threshold number? The percent threshold on the inflation meter, in decimal form, that you want the linked animation to play at. Default is 0.3 (30%).
---@param message string|table? Do you want a specialized chat message to be sent when this module activates? Provide a string or a table, and it'll choose a message and make you chat it!
function BwBEX.linkAnimation:new(anim, threshold, message)
    if not BwBEX.BwB then return end
    if not anim then error("No animation provided to linkAnimation function!") end
    
    self = setmetatable({}, BwBEX.linkAnimation)
    self.__index = self
    self.animation = anim
    self.threshold = threshold or 0.3
    self.active = false 
    self.chance = 1
    self.message = message
    self.chattable = true
    self.eyes = 1

    local LastThreshold

    function events.world_tick()
        if BwBEX.paused then return end
        local current = BwBEX.pressure / BwBEX.maxPressure

        if current ~= LastThreshold and current >= self.threshold then
            local function SetAsActive()
                if not self.active then
                    self.animation:play()

                    if self.message and self.chattable then
                        local Symbols = {"@", "O", "-", "><", "<>"}
                        local SymbolNumber = math.random(1, #Symbols)
                        local Symbol = Symbols[SymbolNumber]
                        local Symbol1
                        local Symbol2
                        local FirstSlashArithmetic = math.round(math.clamp(current * 10, 3, BwBEX.maxPressure/2))
                        local SecondSlashArithmetic = math.round(math.clamp(current * 20, 5, BwBEX.maxPressure))
                        local SlashCount = math.random(FirstSlashArithmetic, SecondSlashArithmetic)
                        local SlashString = ""
                        local Teardrop = math.random(0, 2)
                        local TeardropString = ""

                        if string.len(Symbol) == 2 then
                            -- use two eyes instead of 1
                            Symbol1 = string.sub(Symbol, 1,1)
                            Symbol2 = string.sub(Symbol, 2,2)
                        end

                        -- eye configuration
                        ---@param DoubleSymbolMode boolean
                        local function AddMoreEyes(DoubleSymbolMode)
                            if DoubleSymbolMode then
                                local Symbol1Temp = Symbol1 -- temporarily copying this string
                                local Symbol2Temp = Symbol2 -- temporarily copying this string

                                for i=1, self.eyes-1 do
                                    Symbol1 = Symbol1 .. Symbol1Temp
                                    Symbol2 = Symbol2 .. Symbol2Temp
                                end
                            else
                                local SymbolTemp = Symbol -- temporarily copying this string
                                for i=1, self.eyes-1 do
                                    Symbol = Symbol .. SymbolTemp
                                end
                            end
                        end

                        AddMoreEyes(Symbol1 and true or false)

                        -- blush configuration
                        for i=1, SlashCount do
                            SlashString = SlashString .. "/"
                        end

                        -- sweatdrop configuration
                        for i=1, Teardrop do
                            TeardropString = TeardropString .. "'"
                        end

                        local RandomMessage
                        if type(self.message) == "table" then
                            -- this is a table!
                            RandomMessage = self.message[math.random(1, #self.message)]
                        end

                        local FinalMessage = (RandomMessage or self.message) .. string.format(" %s%s%s%s", Symbol1 or Symbol, SlashString, Symbol2 or Symbol, TeardropString)
                        host:sendChatMessage(FinalMessage)
                    end

                    self.active = true
                end
            end

            if self.chance == 1 then
                -- obviously, don't need to do math for this!
                SetAsActive()
            else
                local chance = math.random(1, self.chance)

                if chance == 1 then
                    -- YIPPEE
                    SetAsActive()
                end
            end
        else
            if self.active and current < self.threshold then
                self.animation:stop()
                self.active = false
            end
        end

        LastThreshold = current
    end

    return self
end

--[[

    Sound settings table
    {
        Name = "minecraft:ui.toast.in",
        Volume = 1.5,
        Pitch = 0.8
    }

]]

local defaultTextureConfig = {
    Speed = 1, -- The overall speed at which this effect will occur
    MaxThreshold = 0.6, -- The percent of the meter that you want this effect to reach the specified speed at.
    -- StartingPixel = vec(0, 0) -- The pixel that you want this effect to ALWAYS start at.
    -- Method
}
--- Credit to Sufferneer!
--- BUGGY, WORK IN PROGRESS!!!
--- This is *supposed* to be a function that will *attempt* to create a texture transition effect to change your skin while under a status effect.
--- Provide a model, the original texture, the effect texture, and some settings, then allow this library to do the rest!
--- Note: this function becomes faster the more inflated you are.
---@param model ModelPart The original model to be used for texture switching.
---@param originalTexture string The name of the original texture the model is currently using.
---@param newTexture string The name of the new texture that you want this model to switch to.
---@param effect string The name of a valid status effect that you want this function to check for.
---@param config table? A dictionary containing additional settings for this effect. A default table will otherwise be used.
function BwBEX.animateTexture:new(model, originalTexture, newTexture, effect, config)
    if not BwBEX.BwB then return end
    -- if not config then config = defaultTextureConfig end
    self = setmetatable({}, BwBEX.animateTexture)
    self.__index = self
    -- Variable setup
    self.model = model
    self.originalTexture = textures:copy(string.format("%s_Original", effect), textures[originalTexture])
    self.newTexture = textures:copy(string.format("%s_New", effect), textures[newTexture])
    self.mixedTexture = textures:copy(string.format("%s_Mixed", effect), textures[originalTexture])
    self.effect = effect
    self.config = config or CloneTable(defaultTextureConfig)

    local TextureDimensions = self.originalTexture:getDimensions()
    
    local UnmodifiedPixels = {}

    local function ResetUnmodifiedPixels()
        for i=0, TextureDimensions.x-1, 1 do
            for o=0, TextureDimensions.y-1, 1 do
                table.insert(UnmodifiedPixels, vec(i, o))
            end
        end
    end

    ResetUnmodifiedPixels()

    -- Function
    local function UpdateTexture()
        local AlignmentTable = {
            [0] = vec(0, 0),
            [1] = vec(0, 1),
            [2] = vec(1, 1),
            [3] = vec(1, 0),
            [4] = vec(1, -1),
            [5] = vec(0, -1),
            [6] = vec(-1, -0),
            [7] = vec(-1, 0),
            [8] = vec(-1, 1),
            [9] = vec(-1, -1)
        }

        local function UpdatePixel(vector, index)
            if #UnmodifiedPixels == 0 then return end -- STOP TRYING TO UPDATE THERE LITERALLY AREN'T ANY MORE
            local sanitizedVector = vec(math.clamp(vector.x, 0, TextureDimensions.x-1), math.clamp(vector.y, 0, TextureDimensions.y-1))

            local pixel = self.newTexture:getPixel(sanitizedVector.x, sanitizedVector.y)

            -- pixel check
            if self.config.RandomPixels then
                if self.newTexture:getPixel(sanitizedVector.x, sanitizedVector.y) == pixel then
                    -- the color data here is the same, so get a different one
                    local number = math.random(0, #UnmodifiedPixels)
                    sanitizedVector = UnmodifiedPixels[number]
                    index = number
                    pixel = self.newTexture:getPixel(sanitizedVector.x, sanitizedVector.y)
                end
            end

            -- get the colors
            local Colors = vec(pixel.r, pixel.g, pixel.b, pixel.a)
            -- set new pixel
            -- print(sanitizedVector)
            self.mixedTexture:setPixel(sanitizedVector.x, sanitizedVector.y, Colors)
            -- update texture
            self.mixedTexture:update()

            table.remove(UnmodifiedPixels, index)
        end

        --[[
        
            TODO
            1. select a random pixel
            2. move once outside of it
            3. color in that pixel
        
        ]]

        if self.mixedTexture ~= self.newTexture then
            for i=1, 5 do
                local index = math.random(0, #UnmodifiedPixels)
                local alignmentVector = UnmodifiedPixels[index]

                for _,value in pairs(AlignmentTable) do
                    UpdatePixel(alignmentVector + value, index)
                    UpdatePixel(alignmentVector + (value * 2), index)
                end
            end

            self.model:setPrimaryTexture("CUSTOM", self.mixedTexture)
        end
    end

    -- local function SendTextureToServer(texture)
    --     self.model:setPrimaryTexture("CUSTOM", texture)
    -- end

    -- pings.SendTextureToServer = SendTextureToServer

    -- Primary function loop
    local threshold = BwBEX.maxPressure*self.config.MaxThreshold
    local CurrentSpeed = math.clamp(self.config.Speed * (BwBEX.pressure/threshold), 2, 10)
    local defaultTimer = 1
    local pingCounter = 0
    local timer = defaultTimer / CurrentSpeed
    local LastTexTime = client.getSystemTime()
    local eff = nil
    local active = false
    function events.render()
        if BwBEX.paused then return end
        local delta = GetDelta(LastTexTime)
        if timer <= 0 and eff then
            UpdateTexture()

            -- pingCounter = pingCounter + 1
            -- if pingCounter >= 10 then
            --     pingCounter = 0
            --     pings.SendTextureToServer(self.mixedTexture)
            -- end
            
            timer = defaultTimer / CurrentSpeed
            if not active then active = true end
        else
            if not eff and active then
                -- we don't have the effect
                UnmodifiedPixels = {} -- empty the table 
                self.model:setPrimaryTexture("CUSTOM", self.originalTexture) -- reset texture to original
                -- pings.SendTextureToServer(self.originalTexture)
                self.mixedTexture = textures:copy(string.format("%s_Mixed", effect), textures[originalTexture]) -- reset mixed texture
                ResetUnmodifiedPixels()
                active = false
            end
            
            timer = timer - delta
        end

        LastTexTime = client.getSystemTime()
    end

    function events.tick()
        eff = CheckForStatus(self.effect)
        CurrentSpeed = math.clamp(self.config.Speed * (BwBEX.pressure/threshold), 2, 10) -- set speed
    end

    return self
end

--- Credit to psq95, to CatChris for the code, and to spritesodaguzzler for the idea (unintentionally)!
--- Creates a smoothed overinflation animation, and is also responsible for strain.
---@param strain Animation? Plays this animation when your body 'strains' or overinflates.
---@param overinflation Animation An overinflation animation. Consider this an imaginary secondary layer to your initial inflation.
function BwBEX.overinflate:new(overinflation, strain)
    if not BwBEX.BwB then return end
    self = setmetatable({}, BwBEX.overinflate)
    self.__index = self

    -- variable setting
    self.strainAnim = strain
    self.overinflateAnim = overinflation
    self.maxPoints = 12
    self.targetTime = 0
    self.points = 0
    self.factor = 2 -- Set to 1 to disable this effect
    self.smoothing = 20
    self.threshold = 0.95

    local NextOverinflate = false

    --- sanity
    local SanityCheck = 0
    function events.tick()
        SanityCheck = SanityCheck + 1

        if SanityCheck % 15 == 0 then
            self.factor = math.max(1, self.factor)
            self.smoothing = math.max(1, self.smoothing)
            self.threshold = math.clamp(self.threshold, 0, 1)
        end
    end

    function events.on_play_sound(id, pos, vol, pitch, loop, category)
        if not player:isLoaded() then return end

        if id:find("overinflate") and (pos - player:getPos()):length() < 1 and BwBEX.pressure >= BwBEX.maxPressure then
            if self.strainAnim then
                if self.strainAnim:isPlaying() then
                    self.strainAnim:stop()
                end
                self.strainAnim:play()
            end

            self.points = math.clamp((self.points + 1), 0, self.maxPoints)

            NextOverinflate = true
        end
    end

    if self.overinflateAnim then
        -- setup overinflation animation
        self.overinflateAnim:play()
        self.overinflateAnim:pause()
        self.overinflateAnim:setTime(0)
        function events.tick()
            if BwBEX.pressure <= (BwBEX.maxPressure * self.threshold) and self.points ~= 0 then
                -- reset all points
                self.points = 0
            end
        end

        local LastPoints = 0
        function events.render()
            -- self.targetTime = (BwBEX.pressure / BwBEX.maxPressure) * self.anim:getLength()
            self.targetTime = (self.points / self.maxPoints) * self.overinflateAnim:getLength()

            if self.overinflateAnim:getTime() == self.targetTime then return end -- This should not be running when the player is not inflating

            if NextOverinflate then
                local TranslatedFactor = self.factor
                if self.factor > 1 and LastPoints == (self.maxPoints - 1) then
                    -- this next inflate should have factor IGNORED in the math
                    TranslatedFactor = 1
                end

                local overinflateExtraMath = math.clamp((self.targetTime * TranslatedFactor), 0, self.overinflateAnim:getLength())
                -- self.overinflateAnim:setTime(overinflateExtraMath)
                if overinflateExtraMath ~= self.targetTime then
                    self.overinflateAnim:setTime(overinflateExtraMath)
                end
                NextOverinflate = false

                LastPoints = self.points
            end

            local mathz = self.overinflateAnim:getTime() + (self.targetTime - self.overinflateAnim:getTime()) / (self.smoothing)

            if mathz > self.overinflateAnim:getLength() then
                error(string.format("Value 'mathz' tried to go above the maximum:\n%s vs %s", mathz, self.overinflateAnim:getLength()))
            end

            mathz = math.clamp(mathz, 0, self.overinflateAnim:getLength()) -- Clamp the value
            self.overinflateAnim:setTime(mathz)
        end
    end

    return self
end

--- Credit to yoshi364 (Percy) for the idea!
--- This function runs every time you inflate.
--- This function also runs every WORLD tick! It may lag behind when the server you're playing on is struggling.
---@param linkFunc function The function you want to run each time you INflate.
function BwBEX.inflate:new(linkFunc)
    if not BwBEX.BwB then return end
    self = setmetatable({}, BwBEX.inflate)
    self.__index = self
    self.linkedFunction = linkFunc
    self.active = nil -- nil because we want this to update once on first run

    local LastPressure = BwBEX.pressure
    function events.world_tick()
        if BwBEX.pressure > LastPressure then
            self.linkedFunction()
        end
        -- update the last pressure value
        LastPressure = BwBEX.pressure
    end

    return self
end

--- Inverse of BwBEX.inflate.
--- This function runs every WORLD tick! It may lag behind when the server you're playing on is struggling.
---@param linkFunc function The function you want to run each time you DEflate.
function BwBEX.deflate:new(linkFunc)
    if not BwBEX.BwB then return end
    self = setmetatable({}, BwBEX.deflate)
    self.__index = self
    self.linkedFunction = linkFunc
    self.active = nil -- nil because we want this to update once on first run

    local LastPressure = BwBEX.pressure
    function events.world_tick()
        if BwBEX.pressure < LastPressure then
            self.linkedFunction()
        end
        -- update the last pressure value
        LastPressure = BwBEX.pressure
    end

    return self
end

---@param details table A valid dictionary of details describing your hitboxes from stage 0 to stage X. 
---@param smoothInflate any First use BwBEX.smoothInflate on an animation. Then provide that as a variable here!
function BwBEX.PehkuiLink:new(details, smoothInflate)
    if not BwBEX.BwB then return end
    self = setmetatable({}, BwBEX.PehkuiLink)
    self.__index = self
    -- Creating a universal function for the PehkuiLib
    local PehkuiLib, Queue
    for _, path in ipairs(listFiles("/", true)) do
        if string.find(path, "Pehkui") then PehkuiLib = require(path) end
        if string.find(path, "Queue") then Queue = require(path) end

        if PehkuiLib and Queue then break end
    end

    assert(PehkuiLib, "Missing a supported Pehkui library! BwBEX.PehkuiLink won't work without it!")
    assert(Queue, "You also need Queue.lua from the same repository for BwBEX.PehkuiLink to work!!")

    if client:isModLoaded("pehkui") then
        local SentAttributes = {}
        local function SendPehkuiData(dict)
            if player:isLoaded() then
                for attrib, value in pairs(dict) do
                    if string.find(attrib, "attrib_") and player:getPermissionLevel() >= 4 then
                        -- send it as an ATTRIBUTE
                        if not FindValueInTable(SentAttributes, attrib) then
                            local ModifiedCommand = string.format("attribute @s %s base set %s", string.sub(attrib, 8, -1), value)
                            host:sendChatCommand(ModifiedCommand)
                            table.insert(SentAttributes, attrib)
                        end
                    else
                        PehkuiLib.setScale(string.format("pehkui:%s", attrib), value, false) -- assume it's a pehkui value
                    end
                end
            end
        end

        assert(smoothInflate.targetTime, "smoothInflate provided is an invalid object! Make sure that you link your object to a VARIABLE!")
        self.object = smoothInflate
        self.details = details
        self.dead = false
        local LastTime

        function events.entity_init()
            -- Send default Pehkui data
            SendPehkuiData(self.details[0])
            function events.world_tick()
                local TargetTime = self.object.targetTime
                local Animation = self.object.anim
                local AnimLength = Animation:getLength()
                local StageCount = CountDict(details)-1
                local StageIncrement = AnimLength/StageCount
                
                local StageMath = math.lerp(0, StageCount, TargetTime/AnimLength)
                local CurrentStage = math.floor(StageMath % StageCount)
                local NextStage = math.clamp(CurrentStage + 1, 1, StageCount)
                local StageProgress = (TargetTime-(CurrentStage*StageIncrement))/StageIncrement
                if BwBEX.pressure == BwBEX.maxPressure then 
                    StageProgress = 1 
                    CurrentStage = StageCount - 1
                    NextStage = StageCount
                end

                -- Determines what a new Pehkui table of your pressure should contain
                local function TruncateDetails()
                    -- Return the new table
                    if TargetTime <= 0 then
                        return self.details[0]
                    end

                    local NewPehkuiAttribs = {}
                    -- the goal: construct a new table in NewPehkuiAttribs containing a mixture of the last and next stage
                    -- TODO figure out how to make it so that missing attributes are grabbed from the next valid table and are applied as a lerp between it and whatever the next stage needs
                    for attribute,value in pairs(self.details[NextStage]) do -- for each value in the details table...
                        local CurrentStageTable = self.details[CurrentStage]
                        -- if the value wasn't specified in the current stage table, fall back onto the base table
                        if not CurrentStageTable[attribute] then
                            CurrentStageTable = self.details[0]
                        end
                        -- Do a bunch of math to determine the inbetween position of this attribute
                        NewPehkuiAttribs[attribute] = math.lerp(CurrentStageTable[attribute], value, StageProgress)
                    end

                    return NewPehkuiAttribs -- return details
                end

                if LastTime ~= TargetTime then
                    SendPehkuiData(TruncateDetails())
                    LastTime = TargetTime
                end

                -- death case
                if not player:isAlive() and not self.dead then
                    -- player just died! oopsies!
                    self.dead = true
                end

                if player:isAlive() and self.dead then
                    -- reset pehkui
                    log("Your hitbox statistics are now reset!")
                    SendPehkuiData(self.details[0])
                    self.dead = false
                end
            end
        end
    end
    
    return self
end

return BwBEX
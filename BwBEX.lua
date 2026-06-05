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
local BwBEX = {
    paused = false,
    BwB = client:isModLoaded("better_with_blimps"),
    scraps = {},
    smoothInflate = {},
    pressureLink = {},
    linkAnimation = {},
    animateTexture = {},
    vibrate = {},
    float = {},
    pressure = 0,
    maxPressure = 20,
    floatEffectBlacklist = {
        "better_with_blimps.juiced",
        "better_with_blimps.waterlogged"
    }
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
    if player:isLoaded() and BwBEX.BwB then
        local NBTAttribs = player:getNbt().Attributes
        local AttributeName = "better_with_blimps:inflated_attribute"

        local function FetchNBTSlot()
            for i,v in pairs(NBTAttribs) do
                if NBTAttribs[i].Name == AttributeName then
                    BwBEX.pressureSlot = i -- this search should only be needed once
                    break
                end
            end
        end

        -- precaution
        if player:isAlive() then
            if not BwBEX.pressureSlot then
                FetchNBTSlot()
            end

            if NBTAttribs[BwBEX.pressureSlot] then -- throws an error without this
                if not NBTAttribs[BwBEX.pressureSlot].Name or NBTAttribs[BwBEX.pressureSlot].Name ~= AttributeName then
                    FetchNBTSlot()
                end
            end
        end

        local Value = NBTAttribs[BwBEX.pressureSlot].Base

        if not type(Value) == "number" or not Value then
            Value = 0
        end

        return Value
    end

    return nil
end

local function CountDict(dict)
    local count = 0
    for _,__ in pairs(dict) do
        count = count + 1
    end
    return count
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
        BwBEX.paused = client:isPaused() and #world:getPlayers() < 2 and host:isHost()

        if not BwBEX.paused then
            BwBEX.pressure = GetPressure()
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
    self.threshold = math.clamp(threshold, 0, 1) or 0.6
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
    local CurrentThreshold = BwBEX.pressure/BwBEX.maxPressure

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

    function events.render()
        local delta = GetDelta(LastStrainDelta) -- WHY DID YOU MAKE ME DO THIS.
        local PseudoRandomIntensity = RandomFloat(0.25, 2) -- Randomness

        if not BwBEX.paused then            
            if CurrentThreshold >= self.threshold then
                local deltaTime = (1/20 * (self.Speed/10)) / delta -- Modifying the speed of the effect. Divided by delta for frame time consistencies (otherwise it'll get slower the worse your frames are)

                -- computing 
                local Strength = math.lerp(0, 1, (CurrentThreshold-self.threshold)/(1-self.threshold)) -- Figuring out how strong the effect should be overall
                local arithmetic = (Strength * (PressureSize * (math.sin(math.pi * DeltaSum)))) * PseudoRandomIntensity -- The actual math in determining how much to add to the offset scale
                
                for tension, partTable in pairs(self.parts) do
                    for _,part in pairs(partTable) do
                        SetScaleOfPart(part, 1 + (arithmetic * (self.strainIntensity * tension)))
                        SetRotOfPart(part, (GoalRotations[part] or vec(0,0,0)) * ((arithmetic * 20) * (self.shakeIntensity * tension)))
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
    self.threshold = math.clamp(threshold, 0, 1) or (1/5)
    self.intensity = intensity or 1
    self.blacklist = blacklist or true
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

    function events.render(_, context)
        local delta = GetDelta(LastFloatDelta)

        if not BwBEX.paused and context ~= "FIRST_PERSON" then
            if BwBEX.pressure > (BwBEX.maxPressure*self.threshold) and not VerifyBlacklist() then
                local deltaTime = (1/20 * (self.speed/500)) / delta -- Modifying the speed of the effect. Divided by delta for frame time consistencies (otherwise it'll get slower the worse your frames are)
                local Strength = (math.lerp(0.15, 1, (BwBEX.pressure - (BwBEX.maxPressure*self.threshold))/(BwBEX.maxPressure - (BwBEX.maxPressure*self.threshold))) * self.intensity) * 10 -- Figuring out how strong the effect should be overall, multiplied by 10 for simplicity's sake

                local arithmetic = Strength * (math.sin(math.pi * DeltaFloatSum))

                -- uhhhhHhhh time management i think,
                DeltaFloatSum = DeltaFloatSum + deltaTime

                model:setPos(vec(0, arithmetic+offset, 0))
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
---@param smoothing number A smoothing value for the inflation animation. Default is 40.
function BwBEX.smoothInflate:new(anim, smoothing)
    if not BwBEX.BwB then return end
    self = setmetatable({}, BwBEX.smoothInflate)
    self.__index = self

    self.targetTime = 0
    self.anim = anim
    self.smoothing = math.max(1, smoothing) or 40

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
    self.threshold = math.clamp(threshold, 0, 1) or 0.5

    local Confetti
    for _, path in ipairs(listFiles("/", true)) do
        if string.find(path, "confetti") then Confetti = require(path) break end
    end

    if not Confetti then error("Confetti was not located in your model! Please add it before using this function") end
    
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
    
    function events.entity_init()
        local dead = false -- internal dead variable

        function events.world_tick()
            if not BwBEX.pressure then return end

            if BwBEX.pressure > (BwBEX.maxPressure * threshold) then
                if dead == false and not player:isAlive() then
                    -- we just died

                    -- make model invisible immediately
                    UpdateModelVisibility(false)
                    
                    -- create particle
                    for _,meshName in pairs(MeshTbl) do
                        for i=0, math.random(16, 64), 1 do
                            local Position = player:getPos():add(vec(math.random(-100, 100) / 75, math.random(0, 200) / 100, math.random(-100, 100) / 75))
                            local Velocity = vec((math.random(-100, 100) / 100)  * 1.5, (math.random(-25, 100) / 100) * 1.5, (math.random(-100, 100) / 100)  * 1.5)
                            
                            local ScrapOptions = {
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

            if dead == true and player:isAlive() then
                -- we just came back to life
                -- update model visibility
                UpdateModelVisibility(true)
                -- update variable
                dead = false
            end
        end
    end
end

--- A function dedicated to creating pressure links. At the specified threshold, run the specified function. Simple!
--- This function runs every WORLD tick! It may lag behind when the server you're playing on is struggling.
--- Recommended to send a ping function through this, especially in regards to player changes.
---@param threshold number The percent threshold on the inflation meter, in decimal form, to start the link
---@param linkFunc function The function you want to run at this threshold. Has an innate argument: the player's pressure.
function BwBEX.pressureLink:new(threshold, linkFunc)
    if not BwBEX.BwB then return end
    self = setmetatable({}, BwBEX.pressureLink)
    self.__index = self
    self.linkedFunction = linkFunc
    self.threshold = threshold
    self.active = nil -- nil because we want this to update once on first run

    function events.world_tick()
        local active = BwBEX.pressure > (BwBEX.maxPressure*threshold) -- check if the current pressure is past the specified threshold

        if active ~= self.active or not self.active then -- if it needs to be checked
            linkFunc(active) -- run the linked function
            self.active = active -- save this so we don't run this function twice
        end
    end

    return self
end

--- Credit to Sufferneer once again!
--- A function that will play a dedicated animation inbetween a specific period of time. 
--- Good for animations that will play when you reach a certain size (e.g. your butt suddenly inflating)
---@param anim Animation The animation you want to play at the specified size.
---@param threshold number? The percent threshold on the inflation meter, in decimal form, that you want the linked animation to play at. Default is 0.3 (30%).
---@param sound string|table? If you want to play a sound when you inflate, provide a string matching a sound OR a table containing a sound and its' attributes! Proper layout of a sound table is in the wiki.
function BwBEX.linkAnimation:new(anim, threshold, sound)
    if not BwBEX.BwB then return end
    if not anim then error("No animation provided to linkAnimation function!") end
    
    self = setmetatable({}, BwBEX.linkAnimation)
    self.__index = self
    self.animation = anim
    self.threshold = threshold or 0.3
    self.active = false
    self.sound = sound    

    function events.world_tick()
        if BwBEX.paused then return end
        local current = BwBEX.pressure / BwBEX.maxPressure

        if current >= self.threshold then
            if not self.active then
                self.animation:play()

                if self.sound then
                    -- we have a sound
                    if type(self.sound) == "string" then
                        -- this is a sound!
                        sounds:playSound(self.sound, player:getPos(), 2, 0.8)
                    else
                        -- this is a table of sound settings!
                        sounds:playSound(self.sound.Name, player:getPos(), self.sound.Volume or 2, self.sound.Pitch or 0.8)
                    end
                end

                self.active = true
            end
        else
            if self.active then
                self.animation:stop()
                self.active = false
            end
        end
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
--- A function that will attempt to create a texture transition effect to change your skin while under a status effect.
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

return BwBEX
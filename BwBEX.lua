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
---@return BwBEX
local BwBEX = {
    paused = false,
    BwB = client:isModLoaded("better_with_blimps"),
    scraps = {},
    smoothInflate = {},
    pressureLink = {},
    pressure = 0
}
BwBEX.__index = BwBEX

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
        if not BwBEX.pressureSlot or NBTAttribs[BwBEX.pressureSlot].Name ~= AttributeName then
            FetchNBTSlot()
        end

        local Value = NBTAttribs[BwBEX.pressureSlot].Base

        if not type(Value) == "number" or not Value then
            Value = 0
        end

        return Value
    end
end

local function CountDict(dict)
    local count = 0
    for _,__ in pairs(dict) do
        count = count + 1
    end
    return count
end

-- Loops
function events.tick()
    BwBEX.paused = client:isPaused() and #world:getPlayers() < 2 and host:isHost()

    if not BwBEX.paused then
        BwBEX.pressure = GetPressure()
    end
end


-- API functions

---Credit to sufferneer!! Provide a dictionary of model parts to cause them to vibrate when your pressure reaches a specific threshold.
---@param dict table A dictionary of contents describing the intensity of the vibration effect on the selected model parts. Example of a valid dictionary will be provided below this function.
---@param threshold number? A percentage of the meter that must be filled before this effect become noticable. 0 is no pressure, 1 is max pressure. If no number is provided, the default is 0.6 (60%).
function BwBEX:vibrate(dict, threshold)
    if not BwBEX.BwB then return end
    if not threshold then threshold = 0.6 end
    threshold = math.clamp(threshold, 0, 1)
    local MaxPressureSize = 0.01 -- Maximum part size
    local Speed = 1 -- Speed of the effect
    local Intensity = 4 -- How intense the effect is overall
    local Pressurized = false -- Determines if the parts should be reset to their original scales
    local LastStrainDelta = client.getSystemTime()

    local DeltaSum = 0
    local MaxSum = 1
    local PressureSize = RandomFloat(0.0025, MaxPressureSize)

    function events.render()
        local delta = GetDelta(LastStrainDelta) -- WHY DID YOU MAKE ME DO THIS.

        if not BwBEX.paused then            
            if (BwBEX.pressure / 20) > threshold then
                local deltaTime = (1/20 * (Speed/10)) / delta -- Modifying the speed of the effect. Divided by delta for frame time consistencies (otherwise it'll get slower the worse your frames are)
                local PseudoRandomIntensity = RandomFloat(0.25, 1.75) -- Randomness

                local Strength = (math.lerp(0, 1, (BwBEX.pressure - threshold)/(20 - threshold)) * Intensity) * PseudoRandomIntensity -- Figuring out how strong the effect should be overall
                local arithmetic = Strength * (PressureSize * (math.sin(math.pi * DeltaSum))) -- The actual math in determining how much to add to the offset scale
                
                for tension, partTable in pairs(dict) do
                    for _,part in pairs(partTable) do
                        part:setOffsetScale(1 + (arithmetic * tension))
                    end
                end

                DeltaSum = DeltaSum + deltaTime
                
                if not Pressurized then
                    Pressurized = true
                end
            else
                if Pressurized then
                    for _,partTable in pairs(dict) do
                        for _,part in pairs(partTable) do
                            part:setOffsetScale(1)
                        end
                    end
                    Pressurized = false
                end
            end

            if DeltaSum > MaxSum then
                DeltaSum = 0
                -- Make a new pseudo random part size for the next one
                PressureSize = RandomFloat(0.0025, MaxPressureSize)
            end
        end

        LastStrainDelta = client.getSystemTime()
    end
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
---@param threshold number? A percentage of the inflation in decimal form (a float from 0 to 1) that you want to begin floating at. Default is 0.2 (20%)
---@param intensity number? A value that determines how intense the effect is. It scales with your inflation linearly, so do keep that in mind! Default is 1.
---@param offset number? A value to determine the original offset of your model. This will help you keep the model from clipping into the floor when this module is active!
function BwBEX:float(model, threshold, intensity, offset)
    if not BwBEX.BwB then return end
    if not threshold then threshold = 1/5 end
    if not intensity then intensity = 1 end
    if not offset then offset = 0 end
    threshold = math.clamp(threshold, 0, 1)
    local FloatSpeed = 1 -- How fast the effect is
    local LastFloatDelta = client.getSystemTime()

    local DeltaFloatSum = 0
    local DeltaFloatMax = 2
    function events.render(_, context)
        local delta = GetDelta(LastFloatDelta)

        if not BwBEX.paused and context ~= "FIRST_PERSON" then
            if BwBEX.pressure > (20*threshold) then
                local deltaTime = (1/20 * (FloatSpeed/500)) / delta -- Modifying the speed of the effect. Divided by delta for frame time consistencies (otherwise it'll get slower the worse your frames are)
                local Strength = (math.lerp(0.15, 1, (BwBEX.pressure - (20*threshold))/(20 - (20*threshold))) * intensity) * 10 -- Figuring out how strong the effect should be overall, multiplied by 10 for simplicity's sake

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
end

---Credit to psq95!! Smooths out your inflation depending on the provided smoothing value. Designed to REPLACE the existing animinflate from the BwBAPI! Called as a variable, which returns the target time.
---@param anim Animation The inflation animation to link to this function
---@param smoothing number A smoothing value for the inflation animation.
function BwBEX.smoothInflate:new(anim, smoothing)
    if not BwBEX.BwB then return end
    self = setmetatable({}, BwBEX)
    smoothing = math.max(1, smoothing)

    self.targetTime = 0
    self.anim = anim

    -- setup animation
    self.anim:play()
    self.anim:pause()
    self.anim:setTime(0)

    function events.render()
        self.targetTime = (BwBEX.pressure / 20) * self.anim:getLength()

        if self.anim:getTime() == self.targetTime then return end -- This should not be running when the player is not inflating

        local mathz = self.anim:getTime() + (self.targetTime - self.anim:getTime()) / (smoothing)

        if mathz > self.anim:getLength() then
            error(string.format("Value 'mathz' tried to go above the maximum:\n%s vs %s", mathz, self.anim:getLength()))
        end

        mathz = math.clamp(mathz, 0, self.anim:getLength()) -- Clamp the value
        self.anim:setTime(mathz)
    end

    return self
end

---Adds scrap models to inflated death if Confetti is located
---@param model any The PRIMARY model. This may also be a table, incase you have multiple models to toggle.
---@param scraps ModelPart The scraps model. Proper format provided in wiki
---@param threshold number? A percentage of the inflation in decimal form (a float from 0 to 1) that you want the game to summon scraps at. Default is 0.5 (50%)
function BwBEX.scraps:new(model, scraps, threshold)
    if not threshold then threshold = 0.5 end

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
            model:setOpacity(value)
        else
            -- this is a table!
            for _,part in pairs(model) do
                part:setOpacity(value)
            end
        end
    end

    -- register meshes
    local MeshTbl = {}

    for index,child in pairs(scraps:getChildren()) do
        -- register mesh
        Confetti.registerMesh(child:getName(), child)
        table.insert(MeshTbl, index, child:getName())
    end
    
    function events.entity_init()
        local dead = false -- internal dead variable

        function events.world_tick()
            if not BwBEX.pressure then return end

            if BwBEX.pressure > (20 * threshold) then
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
---@param threshold number The percent threshold, in decimal form, to start the link
---@param linkFunc function The function you want to run at this threshold. Has an innate argument: the player's pressure.
function BwBEX.pressureLink:new(threshold, linkFunc)
    self.linkedFunction = linkFunc
    self.threshold = threshold

    function events.world_tick()
        if BwBEX.pressure > (20*threshold) then
            linkFunc(BwBEX.pressure)
        end
    end
end


return BwBEX
# 🎈Better with Blimps EXtension (BwBEX)
A **[Figura](https://github.com/FiguraMC/Figura)** library designed for use with the Better with Blimps mod alongside its' existing API!

Credits are located within the primary lua script, and is also spread throughout where necessary.
## ✔️ Highlights
* An implementation of **animation smoothing** for your model's inflation in an attempt to improve immersion
* A function to **vibrate parts** as your scale increases, to emulate creaking
* **Model floating!** When you get big enough, you'll start to hover up and down.
## Installation
1. Have a Figura model at the ready. Make sure it at least has some form of inflation animation.
2. Download this library to the root of your model and import it to your primary script by planting the following code:
```lua
local BwBEX = require("BwBEX")
```
3. Scroll down to see all of what this script has to offer!

Congratulations, you're ready to go!! Don't forget to have fun~

# 📜 Function Wiki
> I was advised to move this information from the Wiki to the front page. It's here now!
> 1. If it helps, you can also mess with some of the internal values inside of each function to help better tune the effect. All functions return themselves, which reveals a handful of internal values that are normally not meant to be messed with.
> 2. All arguments that end with a ❔ are **not required to be filled out**. They will be substituted with default values that I have tuned personally!
> 3. Before starting, I **highly** recommend the usage of a code editor like [VSCodium](https://vscodium.com/). Then, install [this](https://github.com/GrandpaScout/FiguraRewriteVSDocs/wiki) set of documents to the root of your model. It'll help you lots when coding!
> 4. The example model shown is my personal edit of a base that I made. **I will not be releasing this specific variant of the base.**

## `.vibrate:new(dictionary, threshold?, options?)`
Causes the parts in a specified dictionary to vibrate granularly, starting at the specified threshold. Higher inflation = more vibration.


Parameter | Description
-- | --
dictionary | `table` A dictionary of contents describing what parts to vibrate and how intensely they should be affected
threshold | `number` A percentage (number from 0 to 1) of the inflation meter that must be filled before this effect becomes noticable. Default is 0.6 (60%).
options❔ | `table` A table of values for further configuration. Accepts `Speed`, `strainIntensity`, `shakeIntensity`, and `rotationAngle` as valid values.

**Example of dictionary layout:**
```lua
local Parts = {
    [2] = { -- intensity = {parts}
        modelpaths.HighBelly,
        modelpaths.MidBelly,
        modelpaths.LowBelly,
    },
    [0.5] = {
        modelpaths.Butt
    },
    [1] = {
        modelpaths.Head.BloatFeatures.RightMawCheek,
        modelpaths.Head.BloatFeatures.LeftMawCheek,
    }
}
```

[Demonstration](https://github.com/user-attachments/assets/f51149d3-1f28-46d6-98f6-6dc4df056ab8)

## `.float:new(model, blacklist?, threshold?, intensity?, offset?)`
Causes your body to start floating at the specified threshold.

Parameter | Description
-- | --
model | `ModelPart` A model part on your model that should correspond to the root of the model, so that the entire model is rendered floating.
blacklist❔ | `boolean` A true/false statement that asks if the effect blacklist should be referenced. If you have the juiced or waterlogged effects, you won't float.
threshold❔ | `number` A percentage (number from 0 to 1) of the inflation meter that must be filled before this effect becomes noticable. Default is 0.2 (20%).
intensity❔ | `number` A value that determines how intense this effect appears. Default is 1.
offset❔ | `number` A value to determine the original offset of your model. This will help you keep the model from clipping into the floor when this module is active! Default is 0.

[Demonstration](https://github.com/user-attachments/assets/bfb45fc9-bbfd-405d-bc27-9d8e1d88f38c)

## `.smoothInflate:new(anim, smoothing?)`
Smooths out the inflation animation of your model using the specified smoothing value.

Parameter | Description
-- | --
anim | `Animation` The inflation animation of your model.
smoothing❔ | `number` A smoothing value for the inflation animation. Lower = more immediate effect.

[Demonstration](https://github.com/user-attachments/assets/7306866f-c419-49a3-887f-08c1456ce674)

## `.scraps:new(model, scraps, threshold?)`
**Requires [Confetti](https://github.com/Manuel-3/figura-scripts/tree/main/src/confetti) somewhere in your model!**
Particle logic cloned from the original Honest John model. Causes your body to explode into scraps on death. Scales with the provided threshold, if any.

Parameter | Description
-- | --
model | `table OR ModelPart` The path to the primary player model (or otherwise, all models that must be temporarily hidden) while dead. *If this is a TABLE, then all items inside will be hidden for scraps.*
scraps | `ModelPart` The path to your SCRAPS model. Check out Honest John for a proper format.
threshold❔ | `number` A percentage (number from 0 to 1) of the inflation meter that must be filled before death causes scraps to spawn. Default is 0.5 (50%).

## `.pressureLink:new(threshold, linkFunc)`
Runs the provided function every world tick so long as your inflation value is around or above the specified threshold of the meter.

Parameter | Description
-- | --
threshold | `number` A percentage (number from 0 to 1) of the inflation meter that must be filled before this function starts firing. **No default.**
linkFunc | `function` A function you want to run on every WORLD tick

No demonstration available.

## `.linkAnimation:new(anim, threshold?, sound?`)
Causes an animation to play at, or above, the specified threshold. You can also provide a sound.

Parameter | Description
-- | --
anim | `Animation` The animation you want to play at this specific threshold. It will be cancelled when you escape this threshold (e.g. deflate before its' threshold).
threshold❔ | `number` A percentage (number from 0 to 1) of the inflation meter that must be filled before this animation plays. Default value: 0.3 (30%)
sound❔ | `string OR table` Provide the name of a sound or a dictionary containing a sound and its' attributes that should fire when this animation plays.

No demonstration available

## `.overinflate:new(strain, overinflation?, points?, smoothing?, factor?)`
When you inflate past your limit, the game causes damage and plays a sound. This function enables you to play an animation *when the sound plays.* There is also an optional 'overinflation' feature that takes a specified animation and uses it as a *secondary* inflation layer each time you strain.

Parameter | Description
-- | --
strain | `Animation` The animation you want to play when you overinflate.
overinflation❔ | `Animation` The animation you want to link to your 'secondary' inflation layer.
points❔ | `number` If the overinflation animation you provided in the last argument is a second inflation layer, then this is its' maximum. Default: 5
smoothing❔ | `number` Functionally similar to .smoothInflate:new()'s variable of the same name. The overinflation layer is smoothed in the same manner. Default value: 20
factor❔ | `number` I attempted to create an effect that causes your body to suddenly bulge outward when you overinflate, then return to a specified target. Default value: 2. Set this value to 1 or lower to disable this effect.

No demonstration available

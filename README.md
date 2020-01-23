# CRAFTWORLD3
An incremental roguelike RPG sandbox addon for Garry's Mod, intended for use with Sandbox.
This is just a hobby project, don't take its programming too seriously! (Though you probably will anyway.)

# NOTICE
This is just the CODE that makes up CRAFTWORLD3. The sounds and materials/textures can be downloaded from MediaFire:

http://www.mediafire.com/file/aaryt4blhcg6spj/CRAFTWORLD3_CONTENT.rar/file

Last Updated: 23/01/2020 07:10 BST

# DEPENDENCIES (CONTENT)
- Team Fortress 2

# DEPENDENCIES (GMOD WORKSHOP)
[currently none]

# CONFLICTS WITH
- Any addon that handles the EntityTakeDamage hook in a special way

# COMPATIBILE WITH
- Most (if not all) TFA weapons

# NOT RECOMMENDED FOR USE WITH
- PAC3

# FEATURES
- Simplicity & Complexity; it functions in a complex way, but plays in a simplistic way!
- BigNumbers; really, really big numbers...!
- Freedom; keeps the original feel of Sandbox whilst spicing it up with progressive gameplay if you want to do something.
- Highly customisable; re-tune the game's rules and math calculations to your desire.
- Endless; there's always a next step to look forward to, whether it'd be an upgrade or more difficult enemies.
- Prefixes; Spawn AI that has special changes or abilities applied to them
- Progressive; the numbers continuously escalate!
- Optimisable; configure the game to be more easy on your server.
- Fancy; optional enhancements to make the game visually more appealing.
- Non-programmer friendly; the highly-customisable configuration file allows you retune CRAFTWORLD3 without the need of gLua knowledge.
- Error-correction; missing models or materials? The configuration file lets you substitute new models and materials!
- Failsafes; safely rolls back to built-in substitutes if something goes wrong (most of the time).
- Phrases; use the configuration file to have CRAFTWORLD3 speak in your native language! Or, y'know, make it spout drivel.
- Number-crunching; don't worry about having to read absurdly-big numbers - everything is conveinently shortened for you!
- Customisable number-crunching; don't want to use the Simplified notation? You can use Scientific or even ScientificNormalised notation!
- Permadeath; the proper way to play CRAFTWORLD3 is with this turned on! But if you are a saint, you can turn this off...
- Optional PvP; chig-chig boom! Kill other players in this optional mode!
- Developer Flare; let the developers be known! A special crown is rendered above official developers of the game (can be turned off).
- Punkbuster; punishes naughty players who try to exploit the game (for example disconnecting before they die)!
- Special administrator system; optionally use a special seperate admin system for managing CRAFTWORLD3.

# DRAWBACKS
CRAFTWORLD3, like many other things on the Garry's Mod workshop, have their own flaws and quirks.
- Only Multiplayer; CRAFTWORLD3 has been designed in mind to be played not in single player mode.
- Heavy; the game can stress your server easily given the correct circumstances! I'm still working on more ways to optimise.
- Messy; the game's code looks rather ugly to a more professional programmer than myself. Sorry! :(

# GAMEPLAY
CRAFTWORLD3 is an addon for Garry's Mod's Sandbox mode. You can try this on other modes if you want, but don't say I didn't warn you!
When a player connects, if they don't have a save file or if the save file is not valid, they will start off with an SMG, a Pistol, and
most importantly Mr. Red (the Crowbar) himself!
The game is composed of playing in Zones. The objective is to defeat all NPCs in a Zone to acquire a Zone Bomb which will
then move the server onto the next Zone. (Don't confuse "Zone" with "Map"!)
The player has health (featuring the mascot of this game; Bloodi, a cute organic heart!), a recharging shield and Pulses.
Pulses are the amount of chances a player has before their inevitable demise.
Pulses can only be recovered by defeating a Zone that has not yet been defeated before.
If you lose all of your health, you become unconscious and lose a pulse! You die instead if it's your last pulse.
Not only that, but teamwork matters! If even one player goes down (configurable), the entire Zone is failed and the server
must backtrack to the previous Zone. Backtracking will not happen if the previous Zone is a Boss Zone.

# ZONES
A Zone in CRAFTWORLD3 is essentially the level of the world around you. The strength of NPCs and the rewards are measured by Zone.
Each Zone requires a certain amount of enemies to kill in order to drop the Zone Bomb. You can collect the bomb or keep grinding
the enemies for more gold! Collecting the Zone Bomb completes the Zone, kills all NPCs and moves onto the next Zone.
The Zone Bomb can be configured to not spawn at all, meaning the zone will complete the moment the final kill happens!
Additionally, if the Zone is one that you haven't beaten before, you will recover a pulse! Already got full pulses? Free goodies!
Every 5th Zone (by default) is a BOSS ZONE, containing a formidable big robotified NPC! The NPC has formidable health and damage,
but also great amounts of cash for you to hoard. By default, the Boss will not drop a Zone Bomb, meaning that Boss Zones will
immediately clear once you destroy that behemoth of a robot!
As you climb Zones, the strength of the enemies and the spoils escalate endlessly! How far can your server get?

# PLAYER
The players are the most important aspect of CRAFTWORLD3! After all, what is CRAFTWORLD3 without the marvelous Craftlings?
Yes, the players are officially known as Craftlings in CRAFTWORLD3! The most important part about them is how they work!
Each player has a primary weapon, secondary weapon, and a melee weapon. The melee weapon can't be replaced (unless if changed
by an administrator or in the configuration file from the default Crowbar), but the secondary and primary can! (unless if also
changed in the configuration file)
Use gold you have acquired from killing NPCs to level up yourself and your gear!
All of your gear and yourself have TEN unique leveling systems, which ALL contribute to total strength!
That sounds complex, but you might actually find that this is linearly progressive upgrading!
In order to upgrade something other than your Level on yourself, you need to acquire a level milestone to get a point to spend on a new level type.
By default, you get:
- An upgrade point every 10th level
- A promotion point every 100th level
- A training point every 500th level
- A Spec Ops point every 1000th level
- A Reclassification point every 1500th level
- 2 Advancement points every 2000th level
- 3 Improvement points every 3000th level
- 3 Empowerment points every 5000th level
- 6 Ameliorate points every 10000th level

Your gear do not rely on points to upgrade levels. Instead, your gear can only be upgraded to the levels of your Craftling!
So for example, if you are Level 19 and Rank 1, then that means your gear can only go up to the same levels each.
But they do not need any special points to upgrade level types other than Level.
Higher-tier leveling systems impact your strength more dramatically than predecessing leveling systems!
How strong can you become?



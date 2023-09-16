# [GuthSCP] Base

GuthSCP Base is a framework coming with everything considered useful for making SCPs addons work together in harmony.
The base allows easy module creation with their own in-game configuration usable anywhere in the code.

Type `guthscp_menu` in your game's console to open the configuration panel.

## Steam Workshop
![Steam Views](https://img.shields.io/steam/views/3034737316?color=red&style=for-the-badge)
![Steam Downloads](https://img.shields.io/steam/downloads/3034737316?color=red&style=for-the-badge)
![Steam Favorites](https://img.shields.io/steam/favorites/3034737316?color=red&style=for-the-badge)

This addon is available on the Workshop [here](https://steamcommunity.com/sharedfiles/filedetails/?id=3034737316)!

## Content
+ Allow an easy in-game configuration system (`guthscp_menu` in your client console)
+ Base entity to derive from **\***
+ Its own spawnmenu category for referencing all SCPs Weapons, Entities, the Modules and their Configurations
+ **Workaround system** for fixing conflicts & issues with external addons
+ **Custom shared sound system** for easily playing looping and 3D-spatialized sounds **\***
+ **Entity breaking system**, useful for throwing doors and chairs at your victims while playing as SCP-096 **\***
+ Some useful functions for managing file data, getting a list of living NPCs, manipulating Lua tables.. **\***

**\*** These features are only effective on addons (mostly mine) using this base, this will do nothing if you don't have any.

## Commands
+ `guthscp_repair_entities`: *server*; repair all broken entities
+ `guthscp_debug_break_at_trace`: *client (`superadmin`)*; destroy the looked entities
+ `guthscp_stop_channel_sounds`: *client*; stop and remove all sound channels currently playing
+ `guthscp_print_channel_sounds`: *client*; print all the existing sound channels 
+ `guthscp_sync`: *client*; retrieve all configs from the server
+ `guthscp_menu`: *client (`superadmin`)*; the **must-have console command** of this addon! it shows the configuration panel and allow you to edit all available settings of installed compatible addons

## Modules
*Wanna see addons which use this one?* 

Here is a [collection](https://steamcommunity.com/workshop/filedetails/?id=3034749707) of them.

## Legal Terms
This addon is licensed under [Creative Commons Sharealike 3.0](https://creativecommons.org/licenses/by-sa/3.0/) and is based on content of [SCP Foundation](http://scp-wiki.wikidot.com/). Credits to [Destructible Doors for Gmod!](https://steamcommunity.com/sharedfiles/filedetails/?id=290961117) code from which I drew inspiration and extended to make my own entity breaking system.

If you create something derived from this, please credit me (you can also tell me about what you've done).
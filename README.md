# REF_Inspect
These scripts are REFramework-compatible (REF) scripts for listing important information for use in an Archipelago-compatible (AP) randomizer. There is an RE2R AP randomizer currently, and this script functions on RE2R, RE3R, RE7, RE8 (Village), and RE9 (Requiem).

Currently, RE4R is not supported, but hopefully someone contributes that support as well at some point. There are some notes at the top of the Inspect script on possible leads for adding this support.

## Scripts
### Inspect.lua
This is the main tool for establishing a REF randomizer in AP. The script lists important location information and player positions to allow creating locations, regions, and typewriter warps for an AP randomizer. For RE3R and RE7, the location information follows a similar approach to the RE2R randomizer. For RE8 (Village), the item location information is slightly different than the others because the previous location format wasn't unique enough for RE8 locations. For RE9 (Requiem), it's unclear what information would be unique enough for an item location structure, so Inspect just dumps everything it can find that might be identifiable for later.

Output from this script is listed in the debug console.

### ItemList.lua
This is a tool for listing the game's items and their IDs as the game sees them. This is in an early state, but can at least reduce the amount of time needed to dig for items.

Output from this script is shown in a REF window, which is only visible when you click the "Script Generated UI" tab at the bottom of the REFramework window.

## How to Use

1. Clone this repo or download it as a zip. If you downloaded as a zip, extract it somewhere.
2. Install [REFramework](https://github.com/praydog/REFramework) for your game of choice. 
3. Launch the game and at any time, in the REFramework window, go to the "ScriptRunner" tab and click the "Spawn Debug Console" button to open the debug console.
4. In that same "ScriptRunner" tab, click the "Run script" button and navigate to the location from step 1, then choose which script you want to load (scripts mentioned above).

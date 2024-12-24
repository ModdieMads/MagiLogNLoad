# Magi Log 'N Load
A logging-based save-load system that allows YOUR MAP to save-and-load at unbelievable speeds!
​
### Feature Overview:​

- Save units, items, destructables, terrain tiles, variables, hashtables and more with a single command!
- Save and load tricky stuff, like transports with units inside, unit groups, cosmetic changes and per-player table and hashtable entries!
- The fastest syncing of all available save-load systems, powered by LibDeflate and COBS streams!
- The fastest game state reconstruction of all available save-load systems, powered by Lua!

This resource was generously commissioned by @Adiniz / Imemi and the folks at Azeroth Roleplay!
If you want to check MagiLogNLoad's features and performance in the context of a large and complex map, please give Azeroth Roleplay a go!

Please, be gentle upon providing feedback and leave a like, if you found it helpful.
If you wish to use this system in your map, please remember to credit me and consider linking back to this page.

In case you want to chat about the system or need help in using it, message me(ModdieMads) on Hive's Discord server!

### Common Questions and Answers:​

<details>
  <summary><b>. How to install and use this system on my map?</b></summary>
 
1. Open the provided map (MagiLogNLoad1010.w3x) and copy-paste the Trigger Editor's MagiLogNLoad folder into your map. It's important to keep the top-down order of the scripts the same as in the provided map. You don't need to copy the GUI variables if you are not using GUI in your map, but make sure that you pass true	to the _skipInitGUI argument in MagiLogNLoad.Init(_debug, _skipInitGUI) when calling it.
2. Edit the MLNL Config script to fit your needs. Create the necessary Abilities in the Object Editor (MagiLogNLoad.FILEIO_ABIL, MagiLogNLoad.LOAD_GHOST_ID).
3. Call MagiLogNLoad.Init() JUST AFTER the map has been initialized. I recommend using a trigger with a "Elapsed game time is 0.10 seconds" event. Please note that ALL Hashtables must be created AFTER calling MagiLogNLoad.Init()!
4. Use "-save FILENAME" and "-load FILENAME" to save/load files.
5. Give credit and a shoutout if you can! I promise to also shoutout your map when given the chance!
6. For more advanced uses, check the provided map and read the script files.

Make sure to check the provided map for a hands-on demonstration.
</details>


<details>
  <summary><b>. How does MagiLogNLoad work?</b></summary>
The system uses a series of logs of what each player does while playing the map.
When a player issues the -save command, the logs of that specific player are serialized into instructions and written into the save-file.
When a player issues the -load command, the save-file is read and the instructions in it are carried out to re-construct the game state.
</details>

<details>
  <summary><b>. Can MagiLogNLoad handle saving and loading in multiplayer maps? Is it desync proof?</b></summary>
Yes! Extensive tests with the Azeroth Roleplay map did not result in any desyncs.
If you encounter one caused by this system, please let me know as soon as you can.
</details>

<details>
  <summary><b>. Do the logs created by MagiLogNLoad create leaks or slow down my map?</b></summary>
No, the system indexes all logs using crossed-hashmaps and direct references. No naive searches are performed.
Multiple log entries of the same object cannot happen.
Also, the system automatically cleans hashmaps in tandem with Lua's garbage collector.
</details>

<details>
  <summary><b>. Can I use MagiLogNLoad in a GUI-only map?</b></summary>
Yes! The system is GUI-friendly and even uses GUI variables to guide its operations in order to minimize Custom Script actions.
Check the provided map for how it's done.
</details>

<details>
  <summary><b>. Can MagiLogNLoad save pre-placed units, items and trees/destructables?</b></summary>
Yes! Pre-placed widgets are indexed by their properties.
When loading pre-placed widgets, the system edits them to be the same as when they were saved.
Use the Modes GUI-variable or the MagiLogNLoad.DefineModes() function to configure the system to save pre-placed widgets.
The system defaults to saving pre-placed trees/destructables, and NOT saving pre-placed units and pre-placed items.
</details>

<details>
  <summary><b>. Can MagiLogNLoad save units/items/destructables created at runtime?</b></summary>
Yes! Widgets created at runtime can be re-created when loading. Items created at runtime are only saved when held/dropped by a player unit, or referenced by a saved variable/hashtable/table. Saving/loading summoned units is not supported due to the TimedLife API bugs.
A complementary work-around for them can be developed. Hit me up if you need it, you can always find me on Hive's Discord server.
</details>

<details>
  <summary><b>. Can MagiLogNLoad save just one specific unit, like my RPG's hero, including runtime changes to its base stats?</b></summary>
Yes! The system can save almost all properties of a unit, with the notable exception of skins and temporary buffs. Make sure to NOT use the SAVE_ALL_UNITS_OF_PLAYER mode if the player owns other units. If something about your hero cannot be saved/loaded properly, let me know.
</details>

<details>
  <summary><b>. Can MagiLogNLoad save cosmetic changes to units? Like orientation, flying height, vertex coloring and animation?</b></summary>
Yes!
</details>

<details>
  <summary><b>. Can MagiLogNLoad save and load boats/zeppelins with units inside?</b></summary>
Yes, and any other transports too! Do note that units inside the transport must be saveable, otherwise the transport will be loaded empty. On the upside, this means you can easily save specific units only inside transports.
</details>

<details>
  <summary><b>. Can MagiLogNLoad save and load unit groups together with the units in it?</b></summary>
Yes! Do note that units in a unit group must be saveable, otherwise the group will be loaded empty. On the upside, this means you can easily save partial unit groups.
</details>

<details>
  <summary><b>. Can MagiLogNLoad save global variables? Even if they contain widgets, integers, strings or reals?</b></summary>
Yes! All you need is to use the WillSaveThis function/GUI-variable. Any public/global variable can be save-loaded by name as long as they have the currently supported types.
</details>


<details>
  <summary><b>. How much is MagiLogNLoad compatible with GUI Hashtables?</b></summary>
The system is fully compatible, BUT ALL Hashtables must be created AFTER calling MagiLogNLoad.Init().
Hashtables created before MagiLogNLoad.Init() will break!
This is due to MagiLogNLoad use of Bribe and Tasyen's Hashtable-to-Lua-table converter.
Despite the inconvenience, this makes GUI Hashtables much faster, more robust, and saveable.
</details>


<details>
  <summary><b>. What types are currently saveable and loadable by MagiLogNLoad?</b></summary>
The system can save: integers, reals, strings, units (and their abilities), items, and destructables.
The system can also load values directly into variables/hashtables/tables.
This allows for triggers and timers to become operational automatically after loading if set up properly.
Consider checking the provided map for more examples.
If you wish something to be made saveable (Quests? Temporary Buffs? TextTags?), hit me up!
You can always find me on Hive's Discord server.
</details>

<details>
  <summary><b>. How does MagiLogNLoad find out which player is doing something, like creating a tree or setting a variable?</b></summary>
The system needs the map to tell it which player is responsible for something when that cannot be inferred from the action alone.
This is done by using the SetLoggingPlayer GUI-variable and MagiLogNLoad.SetLoggingPlayer() function.
If your map is single-player, you just need to use the SetLoggingPlayer variable and MagiLogNLoad.SetLoggingPlayer(player) once at the beginning.
Additionally, you can reset the logging player to make something NOT be saved.
</details>

<details>
  <summary><b>. Can multiple players save and load simultaneously?</b></summary>
Saving is a local operation that can be done anytime by anyone.
Loading commands are managed by a jam-free, automatic concurrency queue.
All -load commands issued are queued and executed one after another to make it desync-proof.
</details>

<details>
  <summary><b>. Does MagiLogNLoad log EVERYTHING that happens in a map?</b></summary>
No, the system only logs the minimum amount necessary according to its current scope.
That scope was defined by the Azeroth Roleplay map, and should work out-of-the-box with most roleplay maps.
On that note, the system at this moment cannot save quests, temporary buffs, text-tags, sounds, among other things.
However, since the system can save integers/reals/strings, it can perform the same as other available save-load systems in this area.
</details>


<details>
  <summary><b>. How compatible is MagiLogNLoad with other systems I might have in my map?</b></summary>
This system makes heavy use of proxying tables and hooking API functions.
Since the main requisite for this system was speed, the hooking and proxying are done directly.
This makes it incompatible with other systems that hook the same API functions, or edit the same metatables.
Since this system uses Bribe and Tasyen's Hashtable-to-Lua-table converter, GetHandleId/BJ and StringHash/BJ are proxied to return the argument passed instead of its handle.
Despite the inconvenience, this is a good practice in Lua maps that cannot trust handles and string hashes anyway.
</details>

<details>
  <summary><b>. What is LibDeflate?</b></summary>
LibDeflate is a library used to compress strings using the Deflate algorithm (kinda like ZIP files).
This greatly reduced the amount of data saved, loaded and synced.
This system uses an adaptation of Haoqian He's LibDeflate to WC3's Lua.
The adaptation is a port of the code to Lua 5.3 (making full use of bin-ops for the 16x speed increase), and includes work-arounds for the lack of unsigned integers in WC3.
</details>

<details>
  <summary><b>. What is Constant Overhead Byte Stuffing (COBS)?</b></summary>
COBS is an old-school technique that allows for minimal overhead when encoding byte streams in Base255.
Minimizing the time spent syncing is how I achieved the fast speeds of this system, since the Sync API is the strictest bottleneck.
</details>

<details>
  <summary><b>. Why is the save-file written in ideograms?</b></summary>
Doing it this way achieves maximum throughput in File IO by leveraging Lua's utf8 capabilities.
</details>

<details>
  <summary><b>. MagiLogNLoad is in Lua, but my map is in JASS. Can you port this system to JASS?</b></summary>
No, this system depends too much on Lua's features. 
It's impossible to achieve both the speed and flexibility of MagiLogNLoad with JASS.
On another note, it is my strong recommendation that all maps in development should be ported to Lua, just for DebugUtils alone if nothing else.
</details>

<details>
  <summary><b>. Ok then. Can you help me port my map to Lua?</b></summary>
Hit me up! You can always find me(ModdieMads) on Hive's Discord server.
</details>

<details>
  <summary><b>. I would like MagiLogNLoad to be incorporated in my map, but I need it adapted to my specific needs. Can you do it?</b></summary>
Hit me up! You can always find me(ModdieMads) on Hive's Discord server.
</details>

### Credits

- @Adiniz/Imemi, for the opportunity!
- @Wrda, for the pioneering work in Lua save-load systems!
- @Trokkin, for the FileIO code!
- @Bribe and @Tasyen, for the Hashtable to Lua table converter!
- @Eikonium, for the invaluable DebugUtils!
- Haoqian He, for the original LibDeflate!

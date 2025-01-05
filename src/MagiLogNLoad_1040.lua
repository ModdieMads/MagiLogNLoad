if Debug and Debug.beginFile then Debug.beginFile('MagiLogNLoad') end
--[[

Magi Log 'n Load v1.04

A preload-based save-load system for WC3!

(C) ModdieMads

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation and public
   profiles IS REQUIRED.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.

]]

--[[

Documentation has been kept to a minimum following feedback from @Wrda and @Antares.
Further explanation of the system will be provided by Discord messages.
Hit me up on HiveWorkshop's Discord server! @ModdieMads!

--------------------------------
 -- | Magi Log 'N Load v1.04 |--
 -------------------------------

 --> By ModdieMads @ https://www.hiveworkshop.com/members/moddiemads.310879/

 - Special thanks to:
    - @Adiniz/Imemi, for the opportunity! Check their map: https://www.hiveworkshop.com/threads/azeroth-roleplay.357579/
	- @Wrda, for the pioneering work in Lua save-load systems!
	- @Trokkin, for the FileIO code!
	- @Bribe and @Tasyen, for the Hashtable to Lua table converter!
	- @Eikonium, for the invaluable DebugUtils! And the template for this header...
	- Haoqian He, for the original LibDeflate!

-----------------------------------------------------------------------------------------------------------------------------
| Provides logging and save-loading functionalities.                                                                        |
|                                                                                                                           |
| Feature Overview:                                                                                                         |
|   1. Save units, items, destructables, terrain tiles, variables, hashtables and more with a single command!               |
|   2. The fastest syncing of all available save-load systems, powered by LibDeflate and COBS streams!                      |
|   3. The fastest game state reconstruction of all available save-load systems, powered by Lua!                            |
|   4. Save and load transports with units inside, cosmetic changes and per-player table and hashtable entries!             |
-----------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
| Installation:                                                                                                                                                             |
|                                                                                                                                                                           |
|   1. Open the provided map (MagiLogNLoad1010.w3x) and copy-paste the Trigger Editor's MagiLogNLoad folder into your map.                                                  |
|   2. Order the script files from top to bottom: MLNL Config, MLNL FileIO, MLNL LibDeflate, MagiLogNload                                                                   |
|   3. Adjust the settings in the MLNL Config script to fit your needs.                                                                                                     |
|   4. Call MagiLogNLoad.Init() JUST AFTER the map has been initialized.                                                                                                    |
|                                                                                                                                                                           |
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Documentation and API-Functions:
*
*       - All automatic functionality provided by MagiLogNLoad can be deactivated by disabling the script files.
*
* -------------------------
* |       Commands        |
* -------------------------
*       - "-save <FILE PATH>" creates a save-file at the provided file path. Folders will be created as necessary.
*         > Powered by MagiLogNLoad.UpdateSaveableVarsForPlayerId() and MagiLogNLoad.SaveLocalPlayer().
*
*       - "-load <FILE NAME>" loads a save-file located at the provided file path.
*         > Powered by MagiLogNLoad.QueuePlayerLoadCommand() and MagiLogNLoad.SyncLocalSaveFile().
*
* ----------------------------
* |      GUI Variables       |
* ----------------------------
*       - Check the provided map (MagiLogNLoad1010.w3x) for more information.
*
*       - udg_mlnl_Modes < String Array >
*         > Powered by MagiLogNLoad.DefineModes()
*
*       - udg_mlnl_MakeProxyTable < String Array >
*         > Powered by MakeProxyTable()
*
*       - udg_mlnl_WillSaveThis < String Array >
*         > Powered by MagiLogNLoad.WillSaveThis()
*
*       - udg_mlnl_LoggingPlayer < Player Array >
*         > Powered by MagiLogNLoad.SetLoggingPlayer()
*
* ------------------
* |      API       |
* ------------------
*
*    MagiLogNLoad.Init(_debug, _skipInitGUI)
*        - Initialization function. Required to make the system operational.
*        - Args ->
*             - _debug: Enables the system to initialize with the Debug mode enabled.
*             - _skipInitGUI: Skip initializing the GUI functions. Use this if your map doesn't use any GUI triggers.
*
*    MagiLogNLoad.SaveLocalPlayer(fileName) < ASYNC >
*        - Starts the process of saving a file for the local player. Only call this function inside a GetLocalPlayer() block.
*        - Step 1: Creates and serializes all necessary logs.
*        - Step 2: Compresses the serialized logs using LibDeflate.
*        - Step 3: The compressed byte-stream within the string is encoded with Constant Overhead Byte Stuffing.
*        - Step 4: The encoded string is converted to uft8's ideogram space.
*        - Step 5: The utf8 string is written to the save-file by FileIO.
*
*    MagiLogNLoad.SyncLocalSaveFile(fileName) < ASYNC >
*        - Begins the process of loading a file for the local player. Only call this function inside a GetLocalPlayer() block.
*        - Warning! Calling this while someone is syncing a file might lead to a system failure. Consider MagiLogNLoad.QueuePlayerLoadCommand(p, fileName).
*        - Step 1: Reads the save-file and parses it as a byte-stream within a string.byte
*        - Step 2: Creates the sync-stream struct to track the syncing process, then initiates it.
*        - Step 3: After all chunks are received by the players, calls MagiLogNLoad.LoadPlayerSaveFromString()
*
*    MagiLogNLoad.LoadPlayerSaveFromString(p, argStr, startTime)
*        - Reconstructs the game state according to the instructions encoded in the passed string.
*        - Step 1: Decodes the string using COBS
*        - Step 2: Decompresses the string using LibDeflate
*        - Step 3: Sanitizes the string to mitigate attacks (shoutouts to Ozzzymaniac)
*        - Step 4: Deserializes the string back into log tables.
*        - Step 5: Traverses the logs and reconstructs the game state along the way.
*        - Step 6: If there are commands in the loading queue, execute the next one on the queue.
*        - Args -> self explanatory
*
*    MagiLogNLoad.QueuePlayerLoadCommand(p, fileName)
*        - Queues a loading command. Use to prevent network jamming.
*        - The queue is processed automatically.
*        - Args -> self explanatory
*
*    MagiLogNLoad.UpdateSaveableVarsForPlayerId(pid)
*        - Updates the log entries concerning variables marked as saveable by MagiLogNLoad.WillSaveThis.
*        - When saving a file, call this first in a sync context (outside a GetLocalPlayer() block).
*
*    MagiLogNLoad.WillSaveThis(argName, willSave)
*        - Registers a global/public variable as saveable/non-saveable. This registry is used when executing a save command.
*        - Variables registered this way are saved regardless of the modes enabled. Great for exceptions and overrides!
*        - If the variable contains a (hash)table, they will use a proxy to record each change made to them as individual log entries.
*        - This means that properties in a (hash)table can be singled out (per player) and saved without needing to save the whole table.
*        - Args ->
*             - argName: Name of the variable. Must be the string that returns the intended variable when used in _G[argName].
*             - willSave: true means the variable will be saved, false means that it won't.
*        - Changing a (hash)table from unsaveable to saveable will still save the modifications made to the table when it was saveable.
*        - To erase all log entries about a (hash)table, change the value assigned to the variable to something else (nil).
*
*    MagiLogNLoad.HashtableSaveInto(value, childKey, parentKey, whichHashTable)
*        - Saves a value into a GUI hashtable. Necessary due to the usage of Bribe and Tasyen's Hashtable to Lua table converter.
*        - Args -> self explanatory
*
*    MagiLogNLoad.DefineModes(_modes)
*        - Define the modes used by the system.
*        - Available modes:
*            - debug
*               > Enable Debug prints. Very recommended.
*            - savePreplacedUnits
*               > Save pre-placed units. Might lead to conflicts in multiplayer.
*               > If the unit is destroyed or removed, its destruction will be recorded and reproduced when loaded.
*            - savePreplacedItems
*               > Save pre-placed items. Might lead to conflicts in multiplayer.
*               > If the item is destroyed or removed, its destruction will be recorded and reproduced when loaded.
*               > Due to the jank required to log item deaths, if the map has too many pre-placed items, its performance might suffer.
*            - savePreplacedDestrs
*               > Save pre-placed trees/destructables. Might lead to conflicts in multiplayer.
*               > For the sake of good performance, the destruction of destrs is only saved if caused by the use of Remove/KillDestructable().
*            - saveDestrsKilledByUnits
*               > Save trees/destructables that are killed by attacks or spells.
*               > If the map has too many trees/destrs, its performance might suffer.
*            - saveAllUnitsOfPlayer
*               > Recommended setting. If not enabled, you must use MagiLogNLoad.WillSaveThis() to have units saved at all.
*            - saveUnitsDisownedByPlayers
*               > Save units disowned by a player if the owner at the time of saving is one of the Neutral players.
*            - saveItemsDroppedManually
*               > Save items on the ground ONLY if a player's unit dropped them.
*               > Won't save items dropped by creeps or Neutral player's units.
*            - saveAllItemsOnGround
*               > Save all items on the ground.
*        - Args ->
*             - _modes: Table of the format { modeName1 = true, modeName2 = true, ...}
*                  - Example: { willSavePreplacedUnits = true, saveAllUnitsOfPlayer = true }
*
*    MagiLogNLoad.SetLoggingPlayer(p), MagiLogNLoad.ResetLoggingPlayer(), MagiLogNLoad.GetLoggingPlayerId()
*        - Defines, resets and returns the PlayerId that will be used by the system to determine in which player's logs the incoming changes will be entered.
*        - This only applies to changes that cannot be automatically attributed to a player, like Remove/CreateDestructable() or modifying a global variable.
*        - In single-player maps, it's recommended to just call MagiLogNLoad.SetLoggingPlayer(GetLocalPlayer()) at the beginning and forget about it.
*        - In multiplayer maps, you will need to manually set and reset the Logging Player when necessary to keep the logs accurate.
*
*    MagiLogNLoad.HashtableLoadFrom(childKey, parentKey, whichHashTable, default)
*        - Loads a value from a GUI hashtable. Necessary due to the usage of Bribe and Tasyen's Hashtable to Lua table converter.
*        - Args -> self explanatory
*
*    MagiLogNLoad.HashtableLoadFrom(childKey, parentKey, whichHashTable, default)
*        - Loads a value from a GUI hashtable. Necessary due to the usage of Bribe and Tasyen's Hashtable to Lua table converter.
*        - Args -> self explanatory

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------]]

do
	MagiLogNLoad = MagiLogNLoad or {version = 1010};

	local unpack = table.unpack;
	local concat = table.concat;
	local remove = table.remove;
	local string_byte = string.byte;
	local string_char = string.char;
	local math_floor = math.floor;
	
	local function TableToConsole(tab, indent) --
		indent = indent or 0;
		local toprint = '{\r\n';
		indent = indent + 2 ;
		for k, v in pairs(tab) do
			toprint = toprint .. string.rep(' ', indent);

			if (type(k) == 'number') then
				toprint = toprint .. '[' .. k .. '] = ';
			elseif (type(k) == 'string') then
				toprint = toprint	.. k ..	' = ';
			end

			if (type(v) == 'number') then
				toprint = toprint .. v .. ',\r\n';
			elseif (type(v) == 'string') then
				toprint = toprint .. '\'' .. v .. '\',\r\n';
			elseif (type(v) == 'table') then
				toprint = toprint .. TableToConsole(v, indent + 2) .. ',\r\n';
			else
				toprint = toprint .. '\'' .. tostring(v) .. '\',\r\n';
			end
		end

		toprint = toprint .. string.rep(' ', indent-2) .. '}';
		return toprint;
	end

	local function Nil()
		return nil;
	end

	local function B2I(val)
		return val and 1 or 0;
	end

	local function I2B(val)
		return val ~= 0;
	end

	local function NakedReturn(a) return a end

	local function Round(val)
		return math_floor(val + .5);
	end

	local function FourCC2Str(num)
		return string.pack('>I4', num);
	end

	local function Range(i0,i1)
		local ans = {};
		local n = 0;

		for i=i0,i1 do
			n = n + 1;
			ans[n] = i;
		end

		return ans;
	end

	local function Map(arr, f, ind0, ind1)
		ind0 = ind0 or 1;
		ind1 = ind1 and (ind1 <= 0 and #arr + ind1 or ind1) or #arr;
		ind1 = ind1 < ind0 and ind0 or ind1;

		local ans = {};

		for i=ind0,ind1 do
			ans[#ans+1] = f(arr[i], i);
		end

		return ans;
	end

	local function Concat7BitPair(a, b)
		return ((a-1) << 7) | (b-1);
	end

	local function Terp(v0, v1, v)
		return (v-v0)/(v1-v0);
	end

	local function Lerp(v0, v1, t)
		return v0 + t*(v1-v0);
	end

	local function Clamp(v, v0, v1)
		return v < v0 and v0 or (v > v1 and v1 or v);
	end

	local function Vec2Add_inPlace(v0, v1)
		v0[1] = v0[1]+v1[1];
		v0[2] = v0[2]+v1[2];
		return v0;
	end

	local function ArrayIndexOfPlucked(arr, val, pluckInd)
		for i,v in ipairs(arr) do
			if v[pluckInd] == val then return i end;
		end
		return -1;
	end

	local int2Function = {};

	local PERC = utf8.char(37);
	local Amrf_4CC = FourCC('Amrf');
	local umvc_4CC = FourCC('umvc');

	local LOAD_GHOST_ID = MagiLogNLoad.LOAD_GHOST_ID or FourCC('A001');

	local neutralPIds = {
		[PLAYER_NEUTRAL_AGGRESSIVE] = true,
		[PLAYER_NEUTRAL_PASSIVE] = true,
		[bj_PLAYER_NEUTRAL_VICTIM] = true,
		[bj_PLAYER_NEUTRAL_EXTRA] = true
	};

	local ENUM_RECT = {};
	local enumSingleX = 1.0;
	local enumSingleY = 1.0;
	local enumSingleMinDist = 1e20;
	local enumSingleId = 0;
	local enumSinglePId = 0;
	local enumSingle;

	local ORDER_LOAD = 852046;
	local ORDER_BOARD = 852043;

	local sanitizer = '';
	local fileNameSanitizer = '';

	local TICK_DUR = .035;
	local globalTimer = {};
	local globalTick = 1;
	local onLaterTickFuncs = {};

	local WORLD_BOUNDS = {};

	MagiLogNLoad.ALL_CARGO_ABILS = MagiLogNLoad.ALL_CARGO_ABILS or {
		FourCC('Aloa'), FourCC('Slo3'),FourCC('Sch3'), FourCC('Sch5'), FourCC('S008'), FourCC('S006'),FourCC('S005'), FourCC('S000'),
		FourCC('S001'), FourCC('A0EZ'),FourCC('A06W')
	};

	local word2CodeHash = {};
	local code2WordHash = {};
	local word2LoadLogFuncHash = {};
	local fCodes = {};
	local logEntry2ReferencedHash = {};

	local typeStr2TypeIdGetter;
	local typeStr2GetterFCode;
	local typeStr2ReferencedArraysHash;
	local fCodeFilters = {};

	local tempGroup = CreateGroup();

	local varName2ProxyTableHash = {};
	local saveables = {
		groups = {},
		vars = {},
		hashtables = {}
	};

	local typeId2BaseStats = {};

	local loggingPid = -1;
	local playerLoadInfo = {};

	local function GetHandleTypeStr(handle)
		local str = tostring(handle);
		return str:sub(1, (str:find(':', nil, true) or 0) - 1);
	end

	local function PluckArray(arr, propName)
		local ans = {};

		for i,v in ipairs(arr) do
			ans[i] = v[propName];
		end

		return ans;
	end

	local function PluckArrayIntoHash(arr, propName, valName)
		local ans = {};
		if valName == nil then
			for i,v in ipairs(arr) do
				ans[v[propName] ] = v;
			end
		else
			for i,v in ipairs(arr) do
				ans[v[propName] ] = v[valName];
			end
		end
		return ans;
	end


	local function Array2Hash(arr, fromInd, toInd, nilVal)
		fromInd = fromInd or 1;
		toInd = toInd or #arr;

		local ans = {};


		for i=fromInd,toInd do
			if arr[i] ~= nil and arr[i] ~= nilVal then
				ans[arr[i] ] = i;
			end
		end

		return ans;
	end

	local function TrySuffix(str, suff)
		return fileName:sub(-(#suff),-1) ~= suff  and str..suff or str;
	end

	local function TryPrefix(str, pref)
		return fileName:sub(1,#pref) ~= pref and pref..str or str;
	end

	local function GetUTF8Codes(str)
		local ans = {};
		local n = 0;
		for i, c in utf8.codes(str) do
			n = n+1;
			ans[n] = c;
		end
		return ans;
	end

	local function GetCharCodesFromUTF8(str)

		local ans = {};
		local ind = 0;
		for i, c in utf8.codes(str) do
			ind = ind + 1;
			ans[ind] = c >> 8;
			ind = ind + 1;
			ans[ind] = c&255;
		end
		ans[ind-ans[ind]] = nil;
		ans[ind-1] = nil;
		ans[ind] = nil;

		return ans;
	end

	local function String2SafeUTF8(str)
		local utf8_char = utf8.char;

		local strlen = #str;
		local arr = {string_byte(str, 1, strlen)};
		local len = #arr;


		local ans = {};
		for i=0,(strlen >> 1)+(strlen&1)-1 do
			ans[i+1] = utf8_char((arr[i+i+1] << 8) + (arr[i+i+2] or 255));
		end


		ans[#ans+1] = utf8_char((strlen&1)+1);

		return concat(ans);
	end

	local function COBSEscape(str)
		local STR0 = string_char(0);
		local STR255 = string_char(255);

		local len = #str;
		local ind0 = 1;
		local ans = {};
		local ansN = 0;

		while ind0 <= len do
			local ind1 = ind0+253 > len and len - ind0 + 1 or 254;

			local substr = str:sub(ind0, ind0 + ind1);

			ind0 = ind0 + ind1;


			local lastHit = 0;

			local hitInd = substr:find(STR0, lastHit + 1, true);
			while hitInd do

				ansN = ansN + 1;
				ans[ansN] = string_char(hitInd - lastHit);


				if hitInd - lastHit > 1 then


					ansN = ansN + 1;
					ans[ansN] = substr:sub(lastHit+1, hitInd-1);
				end

				lastHit = hitInd;

				hitInd = lastHit < ind1 and substr:find(STR0, lastHit + 1, true) or nil;
			end


			if lastHit <= ind1 then

				ansN = ansN + 1;
				ans[ansN] = STR255;

				ansN = ansN + 1;
				ans[ansN] = substr:sub(lastHit+1, ind1);
			end


		end

		return concat(ans);
	end

	local function COBSDescape(str)
		local STR0 = string_char(0);
		local len = #str;
		local ind = 1;
		local ans = {};
		local ansN = 0;

		while ind <= len do
			local substrLen = ind+254 > len and len - ind + 1 or 255;

			local substr = str:sub(ind, ind + substrLen);

			ind = ind + substrLen;


			local lastHit = 1;

			local hitInd = string_byte(substr, lastHit, lastHit);

			while lastHit + hitInd <= substrLen do

				ansN = ansN + 1;
				ans[ansN] = substr:sub(lastHit+1, lastHit+hitInd-1);

				lastHit = lastHit + hitInd;

				ansN = ansN + 1;
				ans[ansN] = STR0;

				hitInd = string_byte(substr, lastHit, lastHit);
			end

			if lastHit < substrLen then

				ansN = ansN + 1;
				ans[ansN] = substr:sub(lastHit+1, substrLen);
			end


		end

		return concat(ans);
	end

	local oriG = {};
	local function PrependFunction(funcName, prepend)
		local upfunc = _G[funcName];
		oriG[funcName] = upfunc;

		_G[funcName] = function(...)
			prepend(...);
			return upfunc(...);
		end
	end

	local function WrapFunction(funcName, wrapF)
		local upfunc = _G[funcName];
		oriG[funcName] = upfunc;

		_G[funcName] = function(...)
			return wrapF(upfunc(...), ...);
		end
	end

	local function ResetFunction(funcName)
		_G[funcName] = oriG[funcName];
		oriG[funcName] = nil;
	end

	local serializeIntTableFuncs = {};
	local function SerializeIntTable(x, stk)
		return serializeIntTableFuncs[type(x)](x, stk);
	end
	serializeIntTableFuncs = {
		['number'] = function(v)
			return tostring(v);
		end,
		['table'] = function(t, stk)
			local rtn = {};

			local rtnN = 0;

			for i,v in ipairs(t) do
				rtnN = rtnN + 1;
				rtn[rtnN] = SerializeIntTable(v);
			end

			return '{' .. concat(rtn, ',') .. '}';
		end
	};

	local function Deserialize(str)
		return load('return ' ..  str)();
	end

	local deconvertPlayerColorHash = {
		[PLAYER_COLOR_RED] = 0,
		[PLAYER_COLOR_BLUE] = 1,
		[PLAYER_COLOR_CYAN] = 2,
		[PLAYER_COLOR_PURPLE] = 3,
		[PLAYER_COLOR_YELLOW] = 4,
		[PLAYER_COLOR_ORANGE] = 5,
		[PLAYER_COLOR_GREEN ] = 6,
		[PLAYER_COLOR_PINK] = 7,
		[PLAYER_COLOR_LIGHT_GRAY] = 8,
		[PLAYER_COLOR_LIGHT_BLUE] = 9,
		[PLAYER_COLOR_AQUA] = 10,
		[PLAYER_COLOR_BROWN ] = 11,
		[PLAYER_COLOR_MAROON] = 12,
		[PLAYER_COLOR_NAVY] = 13,
		[PLAYER_COLOR_TURQUOISE ] = 14,
		[PLAYER_COLOR_VIOLET] = 15,
		[PLAYER_COLOR_WHEAT ] = 16,
		[PLAYER_COLOR_PEACH ] = 17,
		[PLAYER_COLOR_MINT] = 18,
		[PLAYER_COLOR_LAVENDER] = 19,
		[PLAYER_COLOR_COAL] = 20,
		[PLAYER_COLOR_SNOW] = 21,
		[PLAYER_COLOR_EMERALD] = 22,
		[PLAYER_COLOR_PEANUT] = 23
	};

	local deconvertUnitStateHash = {
		[UNIT_STATE_LIFE] = 0,
		[UNIT_STATE_MAX_LIFE] = 1,
		[UNIT_STATE_MANA] = 2,
		[UNIT_STATE_MAX_MANA] = 3
	};

	local deconvertRarityControlHash = {
		[RARITY_FREQUENT] = 0,
		[RARITY_RARE] = 1
	};

	local deconvertPlayerStateHash = {
		[PLAYER_STATE_RESOURCE_GOLD] = 1,
		[PLAYER_STATE_RESOURCE_LUMBER] = 2
	};

	local logGen = {
		terrain = 0,
		destrs = 0,
		units = 0,
		items = 0,
		res = 0,
		proxy = 0,
		groups = 0,
		extras = 256,
		vars = 0,
		hashtable = 0,
		streams = 1
	};

	local magiLog = {
		terrainOfPlayer = {},
		researchOfPlayer = {},
		proxyTablesOfPlayer = {},
		hashtablesOfPlayer = {},
		varsOfPlayer = {},

		destrsOfPlayer = {},
		referencedDestrsOfPlayer = {},

		items = {},
		itemsOfPlayer = {},
		referencedItemsOfPlayer = {},

		units = {},
		unitsOfPlayer = {},
		formerUnits = {},
		referencedUnitsOfPlayer = {},

		extrasOfPlayer = {}
	};

	local tabKeyCleaner, tabKeyCleanerSize, lastCleanedTab;

	local globalModes = {
		debug = true,

		savePreplacedUnits = false,
		savePreplacedDestrs = true,
		savePreplacedItems = false,

		saveAllUnitsOfPlayer = true,
		saveUnitsDisownedByPlayers = true,

		saveItemsDroppedManually = true,
		saveAllItemsOnGround = false,

		saveDestrsKilledByUnits = false
	};
	local guiModes = {};
	local guiModesSlots = 15;

	local modalTriggers = {};


	local function PrintDebug(...)
		if globalModes.debug then
			print(...);
		end
	end

	local tempPreplacedTranspWarningCheck = false;
	local signals = {
		abortLoop = nil
	};

	local preplacedWidgets = {};

	local unit2TransportHash = {};
	local tempIsGateHash = setmetatable({}, { __mode = 'k' });

	local magiStreams = {};
	local uploadingStream = nil;
	local downloadingStreamFrom;
	local loadingQueue = {};

	local logItems;
	local logItemsN = 0;
	local function GetLoggingItem(ind)
		return ind and logItems[ind] or logItems[logItemsN];
	end

	local logDestrs;
	local logDestrsN = 0;
	local function GetLoggingDestr(ind)
		return ind and logDestrs[ind] or logDestrs[logDestrsN];
	end

	local logUnits;
	local logUnitsN = 0;
	local function GetLoggingUnit(ind)
		return ind and logUnits[ind] or logUnits[logUnitsN];
	end

	local function GetLoggingUnitSafe0(ind)
		local u = ind and logUnits[ind] or logUnits[logUnitsN];
		return (u or 0);
	end

	local function GetLoggingUnitsSafe0(...)
		return Map({...}, GetLoggingUnitSafe0);
	end

	local function Div10000(val)
		return val*.0001;
	end

	local function XY2Index30(x, y)
		return 	(Clamp(math_floor(Terp(WORLD_BOUNDS.minX, WORLD_BOUNDS.maxX, x)*32767.), 0, 32767) << 15) |
				(Clamp(math_floor(Terp(WORLD_BOUNDS.minY, WORLD_BOUNDS.maxY, y)*32767.), 0, 32767));
	end

	local function XYZ2Index30(x, y, z)
		return 	(Clamp(math_floor(Terp(WORLD_BOUNDS.minX, WORLD_BOUNDS.maxX, x)*1023.), 0, 1023) << 20) |
				(Clamp(math_floor(Terp(WORLD_BOUNDS.minY, WORLD_BOUNDS.maxY, y)*1023.), 0, 1023) << 10) |
				(Clamp(math_floor(Terp(WORLD_BOUNDS.minX, WORLD_BOUNDS.maxX, z)*1023.), 0, 1023));
	end

	local function XYZW2Index32(x, y, z, w)
		return 	(Clamp(math_floor(Terp(WORLD_BOUNDS.minX, WORLD_BOUNDS.maxX, x)*255.), 0, 255) << 24) |
				(Clamp(math_floor(Terp(WORLD_BOUNDS.minY, WORLD_BOUNDS.maxY, y)*255.), 0, 255) << 16) |
				(Clamp(math_floor(Terp(WORLD_BOUNDS.minX, WORLD_BOUNDS.maxX, z)*255.), 0, 255) << 8) |
				(Clamp(math_floor(Terp(WORLD_BOUNDS.minY, WORLD_BOUNDS.maxY, w)*255.), 0, 255));
	end


	local function TableTrim(tab, maxLen)
		local len = #tab;
		if len < maxLen then return tab end;

		for i=len,maxLen+1,-1 do
			tab[i] = nil;
		end

		return tab;
	end

	local function InvertHash(hash)
		local ans = {};
		for k,v in pairs(hash) do
			if v ~= nil then
				ans[v] = k;
			end
		end
		return ans;
	end

	local function TableGetDeep(tab, map)
		local pt = tab;
		for _,v in ipairs(map) do
			pt = pt[v];
			if pt == nil then return nil end;
		end
		return pt;
	end

	local function TableSetDeep(tab, val, map)
		local pt = tab;
		local N = #map;
		for i=1,N-1 do
			local v = map[i];
			if not pt[v] then
				if val == nil then return end;
				pt[v] = {};
			end
			pt = pt[v];
		end
		pt[map[N]] = val;
	end

	local function TableSetManyPaired(keys, vals, tab)
		local ans = tab or {};

		for i, v in ipairs(keys) do
			ans[v] = vals[i];
		end

		return ans;
	end

	local function TableCloneDeep(ori, pts)
		pts = pts or {};

		local clone;
		if type(ori) == 'table' then
			if pts[ori] then
				clone = pts[ori];
			else
				clone = {};
				pts[ori] = clone;
				for ori_key, ori_value in next, ori, nil do
					clone[TableCloneDeep(ori_key, pts)] = TableCloneDeep(ori_value, pts);
				end
			end
		else
			clone = ori;
		end
		return clone;
	end

	local function SortLog(a, b)
		return a[1] < b[1] or (a[4] and b[4] and a[1] == b[1] and a[4] < b[4]); -- because of LoadGroupAddUnit entries
	end

	local function IsUnitGone(u)
		return GetUnitTypeId(u) == 0 or IsUnitType(u, UNIT_TYPE_DEAD);
	end

	local function ResetTransportAfterLoad(transp, oriCastRanges, cargoUnits, oriMoveSpeeds, oriFacing)
		local i = 0;
		for _,v in ipairs(MagiLogNLoad.ALL_CARGO_ABILS) do
			local lvl = GetUnitAbilityLevel(transp, v);
			if lvl > 0 then
				lvl = lvl -1;

				i = i + 1;
				BlzSetAbilityRealLevelField(BlzGetUnitAbility(transp, v), ABILITY_RLF_CAST_RANGE, lvl, oriCastRanges[i]);
			end
		end

		for i, v in ipairs(cargoUnits) do
			oriG.SetUnitMoveSpeed(v, typeId2BaseStats[GetUnitTypeId(v)][umvc_4CC] or oriMoveSpeeds[i]);
			if GetUnitAbilityLevel(v, LOAD_GHOST_ID) > 0 then
				oriG.UnitRemoveAbility(v, LOAD_GHOST_ID);
			end
		end

		BlzSetUnitFacingEx(transp, oriFacing);
	end

	local function ForceLoadUnits(transp, units)
		if transp == nil or IsUnitGone(transp) then
			PrintDebug('|cffff5500ERROR:ForceLoadUnits!', 'Invalid transport unit detected when trying to load!');
			return;
		end

		local p = GetOwningPlayer(transp);

		local oriCastRanges = {};
		for _,v in ipairs(MagiLogNLoad.ALL_CARGO_ABILS) do
			local lvl = GetUnitAbilityLevel(transp, v);
			if lvl > 0 then
				local abil = BlzGetUnitAbility(transp, v);

				lvl = lvl-1;
				oriCastRanges[#oriCastRanges+1] = BlzGetAbilityRealLevelField(abil, ABILITY_RLF_CAST_RANGE, lvl)

				BlzSetAbilityRealLevelField(abil, ABILITY_RLF_CAST_RANGE, lvl, 99999999.);
			end
		end

		local oriFacing = GetUnitFacing(transp);
		local transpX, transpY = GetUnitX(transp), GetUnitY(transp);

		local oriMoveSpeeds = {};
		local n = 0;
		for i,v in ipairs(units) do
			if v ~= 0 then
				oriMoveSpeeds[i] = GetUnitMoveSpeed(v);
				oriG.SetUnitMoveSpeed(v, 0);
				SetUnitX(v, transpX);
				SetUnitY(v, transpY);
				IssueTargetOrderById(v, ORDER_BOARD, transp);
				BlzQueueTargetOrderById(v, ORDER_BOARD, transp);
				BlzQueueTargetOrderById(v, ORDER_BOARD, transp);
				BlzQueueTargetOrderById(v, ORDER_BOARD, transp);
			end
		end

		onLaterTickFuncs[#onLaterTickFuncs+1] = {globalTick + 30, ResetTransportAfterLoad, {transp,  oriCastRanges, units, oriMoveSpeeds, oriFacing}};
	end

	local function UpdateHeroStats(hero, str, agi, int)
		local val = GetHeroStr(hero, false);

		if val ~= str then
			SetHeroStr(hero, str, true);
		end

		val = GetHeroAgi(hero, false);

		if val ~= agi then
			SetHeroAgi(hero, agi, true);
		end

		val = GetHeroInt(hero, false);

		if val ~= int then
			SetHeroInt(hero, int, true);
		end
	end

	local function UpdateUnitStats(u, maxhp, hp, maxMana, mana, baseDmg)
		if BlzGetUnitMaxHP(u) ~= maxhp then
			BlzSetUnitMaxHP(u, maxhp);
		end

		SetUnitState(u, UNIT_STATE_LIFE, hp);

		if maxMana > 0 then
			if BlzGetUnitMaxMana(u) ~= maxMana then
				BlzSetUnitMaxMana(u, maxMana);
			end

			SetUnitState(u, UNIT_STATE_MANA, mana);
		end

		if BlzGetUnitBaseDamage(u, 0) ~= baseDmg then
			BlzSetUnitBaseDamage(u, baseDmg, 0);
		end
	end

	local function LoadSetUnitFlyHeight(u, height, rate)
		if BlzGetUnitMovementType(u) ~= 2 and GetUnitAbilityLevel(u, Amrf_4CC) <= 0 then
			oriG.UnitAddAbility(u, Amrf_4CC);
			oriG.UnitRemoveAbility(u, Amrf_4CC);
		end

		local isBuilding = BlzGetUnitBooleanField(u, UNIT_BF_IS_A_BUILDING);
		if isBuilding then
			BlzSetUnitBooleanField(u, UNIT_BF_IS_A_BUILDING, false);
		end

		SetUnitFlyHeight(u, height, rate);
		SetUnitPosition(u, GetUnitX(u), GetUnitY(u));

		if isBuilding then
			BlzSetUnitBooleanField(u, UNIT_BF_IS_A_BUILDING, true);
		end
	end

	local function LoadSetUnitArmor(u, armorDif)
		BlzSetUnitArmor(u, (BlzGetUnitArmor(u)*10 + armorDif)*.1);
	end

	local function LoadSetUnitMoveSpeed(u, speedDif)
		SetUnitMoveSpeed(u, speedDif);
	end

	local function LoadSetWaygate(u, x, y, isActive)
		WaygateSetDestination(u, x, y);
		WaygateActivate(u, isActive);
	end

	local function LoadCreateItem(itemid, x, y, charges, pid)
		local item = CreateItem(itemid, x, y);

		if not item then
			PrintDebug('|cffff5500ERROR:LoadCreateItem!', 'Failed to create item with id:',FourCC2Str(itemid),'!|r');
			signals.abortLoop = LoadItem;
			return nil;
		end

		if GetItemCharges(item) ~= charges then
			SetItemCharges(item, charges);
		end

		magiLog.items[item] = {pid};
	end

	local function LoadSetPlayerState(p, goldVal, lumberVal)
		SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, goldVal);
		SetPlayerState(p, PLAYER_STATE_RESOURCE_LUMBER, lumberVal);
	end


	local function EnumGetSingleItem()
		local item = GetEnumItem();

		if GetItemTypeId(item) == enumSingleId then
			local x = GetItemX(item) - enumSingleX;
			local y = GetItemY(item) - enumSingleY;

			local dist = x*x + y*y;
			if dist < enumSingleMinDist then
				enumSingleMinDist = dist;

				enumSingle = item;
			end
		end
	end

	local function GetPreplacedItem(itemid, slot, x, y, unitid, unitOwnerId)
		if slot == -1 then
			return TableGetDeep(preplacedWidgets.itemMap, {itemid, slot, x, y});
		end

		local u = GetPreplacedUnit(x,y,unitid,unitOwnerId);
		if not u then return nil end;

		local item = UnitItemInSlot(u, slot);

		return itemid == GetItemTypeId(item) and item or nil;

	end

	local function EnumGetSingleDestr()
		local destr = GetEnumDestructable();
		local x = GetDestructableX(destr) - enumSingleX;
		local y = GetDestructableY(destr) - enumSingleY;

		local dist = x*x + y*y;
		if dist < enumSingleMinDist then
			enumSingleMinDist = dist;

			enumSingle = destr;
		end

		destr = nil;
	end

	local function GetDestructableByXY(x,y)

		MoveRectTo(ENUM_RECT, x, y);

		enumSingleMinDist = 1e20;
		enumSingleX = x;
		enumSingleY = y;
		enumSingle = nil;

		EnumDestructablesInRect(ENUM_RECT, nil, EnumGetSingleDestr);

		return enumSingle;
	end

	local function UnpackLogArg(tab)
		if #tab == 1 then
			return int2Function[tab[1]]();
		end

		return int2Function[tab[1]](unpack(tab[2]));
	end

	local function UnpackLogEntry(tab)
		local ans = {};
		local ansN = 0;
		for i,v in ipairs(tab) do
			if type(v) == 'table' then
				ansN = ansN + 1;
				ans[ansN] = UnpackLogArg(v);
			else
				ansN = ansN + 1;
				ans[ansN] = v;
			end
		end

		return unpack(ans);
	end
	
	local function LoadUnit(log)
		local entriesN = 0;
		local lastId = 0;
		for i,v in ipairs(log) do
			local curId = v[1];

			if lastId > curId then
				PrintDebug('|cffff5500ERROR:LoadUnit!', 'Bad save-file detected while loading UNIT #',i,'!|r');
				return false;
			end

			lastId = curId;

			int2Function[v[2]](UnpackLogEntry(v[3]));
			if signals.abortLoop == LoadUnit then
				signals.abortLoop = nil;
				break;
			end
			entriesN = entriesN + 1;
		end
		return entriesN;
	end
	
	local FilterEnumGetSingleUnit = Filter(function()
		local u = GetFilterUnit();

		if GetUnitTypeId(u) ~= enumSingleId or GetPlayerId(GetOwningPlayer(u)) ~= enumSinglePId then
			return false;
		end

		local x = GetUnitX(u) - enumSingleX;
		local y = GetUnitY(u) - enumSingleY;

		local dist = x*x + y*y;
		if dist < enumSingleMinDist then
			enumSingleMinDist = dist;
			enumSingle = u;
		end

		u = nil;
		return false;
	end);

	local function GetPreplacedUnit(...)
		return TableGetDeep(preplacedWidgets.unitMap, {...});
	end

	local function LoadCreateUnit(p, unitid, x, y, face)
		local u = CreateUnit(p, unitid, x, y, face);

		if not u then
			if p == GetLocalPlayer() then
				print('|cffff5500Error! Failed to create unit with id:',FourCC2Str(unitid),'!|r');
			end
			signals.abortLoop = LoadUnit;
			return nil;
		end

		logUnits[logUnitsN] = u;

		if not BlzGetUnitBooleanField(u, UNIT_BF_IS_A_BUILDING) then
			SetUnitX(u, x);
			SetUnitY(u, y);
		end

		if GetUnitMoveSpeed(u) <= 0. then
			ShowUnit(u, false);
			ShowUnit(u, true);
		end

		return u;
	end

	local function LoadPreplacedUnit(p, prepX, prepY, preplacedUId, preplacedPId, x, y, face)
		local u = GetPreplacedUnit(prepX, prepY, preplacedUId, preplacedPId);

		if not u then
			PrintDebug('|cffff5500ERROR:LoadPreplacedUnit!', 'Failed to find preplaced unit at (',prepX, prepY, '), id:', FourCC2Str(preplacedUId),
					'.|r|cffff9900Creating a new unit...|r');
			return LoadCreateUnit(p, preplacedUId, x, y, face);
		end
		if not u then return nil end;

		logUnits[logUnitsN] = u;

		SetUnitX(u, x);
		SetUnitY(u, y);
		BlzSetUnitFacingEx(u, face);

		if GetPlayerId(p) ~= preplacedPId then
			SetUnitOwner(u, p);
		end

		if GetUnitMoveSpeed(u) <= 0. then
			ShowUnit(u, false);
			ShowUnit(u, true);
		end

		return u;
	end

	local function LoadUnitAddItemToSlotById(u, itemid, slotid, charges)
		if not u then
			PrintDebug('|cffff5500ERROR:LoadUnitAddItemToSlotById!', 'Passed unit is nil!|r');
			return false;
		end

		local v = UnitAddItemToSlotById(u, itemid, slotid);
		if not v then
			return false;
		end

		local item = UnitItemInSlot(u, slotid);

		logItems[logItemsN] = item;

		if charges and GetItemCharges(item) ~= charges then
			SetItemCharges(item, charges);
		end

		return true;
	end

	local function LoadUnitAddPreplacedItem(u, item, itemid, slotid, charges)
		if not item then
			return LoadUnitAddItemToSlotById(u, itemid, slotid, charges);
		end

		logItems[logItemsN] = item;
		UnitAddItem(u, item);

		if charges and GetItemCharges(item) ~= charges then
			SetItemCharges(item, charges);
		end
	end

	local function LoadGroupAddUnit(gname, u)
		if not u then return end;
		if not _G[gname] then
			_G[gname] = CreateGroup();
		end
		return GroupAddUnit(_G[gname], u);
	end

	local function LogBaseStatsByType(u)
		local typeId = GetUnitTypeId(u);

		if typeId2BaseStats[typeId] then return end;

		typeId2BaseStats[typeId] = {
			[umvc_4CC] = GetUnitMoveSpeed(u)
		};
	end

	local function GetLoggingPlayer()
		return loggingPid > -1 and Player(loggingPid) or nil;
	end

	local function IsUnitSaveable(u, skipPreplacedCheck)
		--#PROD
		return (
			(skipPreplacedCheck or globalModes.savePreplacedUnits or
				(not preplacedWidgets.units[u] and not (preplacedWidgets.units[unit2TransportHash[u]] and IsUnitLoaded(u)))
			) and
			not IsUnitGone(u) and
			not IsUnitType(u, UNIT_TYPE_SUMMONED)
		);
	end
	
	local function LogUnit(u, forceSaving, ownerId)
		if not IsUnitSaveable(u, forceSaving) then
			if not globalModes.savePreplacedUnits and preplacedWidgets.units[unit2TransportHash[u]] and IsUnitLoaded(u) then
				tempPreplacedTranspWarningCheck = true;
			end

			return false;
		end

		local uid = GetUnitTypeId(u);
		local float = 1.0;
		local x = 1.0;
		local y = 1.0;
		local tab;
		local log = magiLog.units;

		if not log[u] then
			log[u] = {};
		end
		local logEntries = log[u];

		if preplacedWidgets.units[u] then
			tab = preplacedWidgets.units[u];
			logEntries[fCodes.LoadPreplacedUnit] = {
				1, fCodes.LoadPreplacedUnit, {
					ownerId and {fCodes.Player, {ownerId}} or {fCodes.GetLoggingPlayer},
					tab[1], tab[2], tab[3], tab[4], Round(GetUnitX(u)), Round(GetUnitY(u)), Round(GetUnitFacing(u))
				}
			};
		else
			logEntries[fCodes.LoadCreateUnit] = {
				1, fCodes.LoadCreateUnit, {
					ownerId and {fCodes.Player, {ownerId}} or {fCodes.GetLoggingPlayer},
					uid, Round(GetUnitX(u)), Round(GetUnitY(u)), Round(GetUnitFacing(u))
				}
			};
		end

		logEntries[fCodes.LogBaseStatsByType] = {2, fCodes.LogBaseStatsByType, {{fCodes.GetLoggingUnit}}};

		if IsUnitLoaded(u) and GetUnitAbilityLevel(u, LOAD_GHOST_ID) <= 0 then
			if logEntries[LOAD_GHOST_ID] == nil then
				logEntries[LOAD_GHOST_ID] = {};
			end

			logEntries[LOAD_GHOST_ID][fCodes.UnitAddAbility] = {3, fCodes.UnitAddAbility, {{fCodes.GetLoggingUnit}, LOAD_GHOST_ID}};
		end

		float = GetUnitFlyHeight(u);
		if float > 0.0 or float < 0 then
			logEntries[fCodes.LoadSetUnitFlyHeight] = {21, fCodes.LoadSetUnitFlyHeight, {{fCodes.GetLoggingUnit}, Round(float), 0}};

		end

		if UnitInventorySize(u) > 0 then
			for i=0,5 do
				local item = UnitItemInSlot(u, i);
				if item then
					if globalModes.savePreplacedItems and preplacedWidgets.items[item] then
						tab = preplacedWidgets.items[item];

						logEntries[(fCodes.LoadUnitAddPreplacedItem << 8) | i] = {30+2*i, fCodes.LoadUnitAddPreplacedItem, {
							{fCodes.GetLoggingUnit},
							{fCodes.GetPreplacedItem, {tab[1], tab[2], tab[3], tab[4], tab[5] or 0, tab[6] or 0}},
							GetItemTypeId(item),
							i,
							GetItemCharges(item)
						}};
					else
						logEntries[(fCodes.LoadUnitAddItemToSlotById << 8) | i] = {30+2*i, fCodes.LoadUnitAddItemToSlotById, {
							{fCodes.GetLoggingUnit}, GetItemTypeId(item), i, GetItemCharges(item)
						}};
					end


				end
				item = nil;
			end
		end

		if IsHeroUnitId(uid) then
			logEntries[fCodes.BlzSetHeroProperName] = {61, fCodes.BlzSetHeroProperName, {{fCodes.GetLoggingUnit}, {fCodes.utf8char, GetUTF8Codes(GetHeroProperName(u))}}};

			logEntries[fCodes.SetHeroXP] = {62, fCodes.SetHeroXP, {{fCodes.GetLoggingUnit}, GetHeroXP(u), {fCodes.I2B, {B2I(false)}}}};

			local skillCounter = 0;
			for i = 0,255 do
				local abil = BlzGetUnitAbilityByIndex(u, i);
				if not abil then break end;

				if BlzGetAbilityBooleanField(abil, ABILITY_BF_HERO_ABILITY) then
					local abilid = BlzGetAbilityId(abil);

					for j=1,GetUnitAbilityLevel(u, abilid) do
						skillCounter = skillCounter + 1;
						logEntries[(fCodes.SelectHeroSkill << 8) | skillCounter] = {63, fCodes.SelectHeroSkill, {{fCodes.GetLoggingUnit}, abilid}};
					end
				end
				abil = nil;
			end

			logEntries[fCodes.UpdateHeroStats] = {64, fCodes.UpdateHeroStats, {{fCodes.GetLoggingUnit}, GetHeroStr(u,false), GetHeroAgi(u,false), GetHeroInt(u,false)}};
		end

		logEntries[fCodes.UpdateUnitStats] = {100, fCodes.UpdateUnitStats, {{fCodes.GetLoggingUnit},
			BlzGetUnitMaxHP(u),								-- max hp
			math_floor(GetWidgetLife(u))+1, 				-- hp
			BlzGetUnitMaxMana(u),							-- max mana
			math_floor(GetUnitState(u, UNIT_STATE_MANA)),	-- mana
			BlzGetUnitBaseDamage(u, 0)						-- base dmg
		}};

		x = WaygateGetDestinationX(u);
		y = WaygateGetDestinationY(u);
		if x ~= 0. or y ~= 0. then
			logEntries[fCodes.LoadSetWaygate] = {120, fCodes.LoadSetWaygate, {{fCodes.GetLoggingUnit}, Round(x), Round(y), {fCodes.I2B, {B2I(WaygateIsActive(u))}}}};
		end

		magiLog.unitsOfPlayer[tempPlayerId][u] = logEntries;
	end

	local FilterEnumLogUnit = Filter(function()
		LogUnit(GetFilterUnit());
		return false;
	end);

	local function CreateUnitsOfPlayerLog(p)
		tempPlayerId = GetPlayerId(p);

		local createdLog = {};
		magiLog.unitsOfPlayer[tempPlayerId] = createdLog;

		tempPreplacedTranspWarningCheck = false;

		if globalModes.saveAllUnitsOfPlayer then
			GroupEnumUnitsOfPlayer(tempGroup, p, FilterEnumLogUnit);
			GroupClear(tempGroup);
		end

		if globalModes.saveUnitsDisownedByPlayers then
			for k,v in pairs(magiLog.formerUnits) do
				if v == tempPlayerId and IsUnitSaveable(k) and neutralPIds[GetPlayerId(GetOwningPlayer(k))] then
					LogUnit(k);
				end
			end
		end

		local tab = magiLog.referencedUnitsOfPlayer[tempPlayerId];
		if tab then
			for u,_ in pairs(tab) do
				if not createdLog[u] then
					local pid = GetPlayerId(GetOwningPlayer(u));
					LogUnit(u, true, pid ~= tempPlayerId and pid or nil);
				end
			end
		end
		
		if tempPreplacedTranspWarningCheck then
			--#AZZY
			--print('|cffff9900Warning! Some units are loaded into the Roleplaying Circle and cannot be saved!|r');
			print('|cffff9900Warning! Some units are loaded into an unsaved transport and will not be saved!|r');
		end
		tempPreplacedTranspWarningCheck = false;
	end

	local function LoadPreplacedItem(x, y, charges, pid, prepItemId, prepSlot, prepX, prepY, prepUnitId, prepUnitOwnerId)
		local item = GetPreplacedItem(prepItemId, prepSlot, prepX, prepY, prepUnitId, prepUnitOwnerId);

		if item == nil then
			PrintDebug('|cffff5500ERROR:LoadPreplacedItem!', 'Failed to find preplaced item at with id:', FourCC2Str(prepItemId), '!|r');
			return LoadCreateItem(prepItemId, x, y, charges, pid);
		end

		SetItemPosition(item, x, y);

		if GetItemCharges(item) ~= charges then
			SetItemCharges(item, charges);
		end

		magiLog.items[item] = {pid};
	end

	local function LogItemOnGround(item, pid, forceSaving)
		if not item or GetItemTypeId(item) == 0 or GetWidgetLife(item) <= 0. then return false end;
		local itemEntry = magiLog.items[item];

		if (forceSaving or globalModes.savePreplacedItems or globalModes.saveAllItemsOnGround) and preplacedWidgets.items[item] then

			local tab = preplacedWidgets.items[item];

			logGen.items = logGen.items + 1;
			magiLog.itemsOfPlayer[pid][item] = { [fCodes.LoadPreplacedItem] = {logGen.items, fCodes.LoadPreplacedItem, {
				Round(GetItemX(item)), Round(GetItemY(item)), GetItemCharges(item), pid,
				tab[1], tab[2], tab[3] or 0, tab[4] or 0, tab[5], tab[6] or 0
			}}};

			return true;
		elseif globalModes.saveAllItemsOnGround or (globalModes.saveItemsDroppedManually and itemEntry and itemEntry[1] == pid) then

			logGen.items = logGen.items + 1;
			magiLog.itemsOfPlayer[pid][item] = { [fCodes.LoadCreateItem] = {logGen.items, fCodes.LoadCreateItem, {
				GetItemTypeId(item), Round(GetItemX(item)), Round(GetItemY(item)), GetItemCharges(item), pid
			}}};

			return true;
		end
	end

	local function EnumLogItemOnGround()
		LogItemOnGround(GetEnumItem(), tempPlayerId);
	end

	local function CreateItemsOfPlayerLog(p)
		local pid = GetPlayerId(p);
		tempPlayerId = pid;

		local createdLog = {};
		magiLog.itemsOfPlayer[pid] = createdLog;
		EnumItemsInRect(WORLD_BOUNDS.rect, nil, EnumLogItemOnGround);

		local tab = magiLog.referencedItemsOfPlayer[pid];
		if tab then
			for item,_ in pairs(tab) do
				if not createdLog[item] then
					LogItemOnGround(item, pid, true);
				end
			end
		end

		if globalModes.savePreplacedItems then
			for item,v in pairs(magiLog.items) do
				if not createdLog[item] and v[1] == pid and v[2] and preplacedWidgets.items[item] then
					logGen.items = logGen.items + 1;
					createdLog[item] = v[2];
				end
			end
		end

		tempPlayerId = -1;
	end

	local function CreateExtrasOfPlayerLog(p)
		local pid = GetPlayerId(p);
		local log = magiLog.extrasOfPlayer[pid];

		if not log then
			log = {};
			magiLog.extrasOfPlayer[pid] = log;
		end

		log[fCodes.LoadSetPlayerState] = {[fCodes.LoadSetPlayerState] = {
			1, fCodes.LoadSetPlayerState, {
				{fCodes.GetLoggingPlayer},
				GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD),
				GetPlayerState(p, PLAYER_STATE_RESOURCE_LUMBER),
			}
		}};
	end


	local function CompileUnitsLog(log, fCodeFilter)
		if not log then return {{}, 'unit', {0,0}} end;

		local maxLen = MagiLogNLoad.MAX_UNITS_PER_FILE;
		local maxEntries = MagiLogNLoad.MAX_ENTRIES_PER_UNIT;
		local entriesN = 0;

		local limitedEntriesCheck = false;

		local ans = {};
		local ansN = 0;

		local u2i = {};
		local i2u = {};

		for u,v in pairs(log) do
			if ansN >= maxLen then
				print('|cffff9900WARNING!', 'Your save-file has too many UNIT entries! Not all will be saved!|r');
				break;
			end

			local curAns = {};
			local curAnsN = 0;

			for k2,v2 in pairs(v) do
				if k2 == fCodes.SetUnitAnimation then
					local entry = v2[GetUnitCurrentOrder(u)];
					if entry and (not fCodeFilter or fCodeFilter[entry[2]]) then
						curAnsN = curAnsN + 1;
						curAns[curAnsN] = entry;
					end
				else
					local check = true;
					if v2[1] == nil or type(v2[1]) == 'table' then
						for _,v3 in pairs(v2) do
							if type(v3) ~= 'table' then break end;
							check = false;

							if not fCodeFilter or fCodeFilter[v3[2]] then
								curAnsN = curAnsN + 1;
								curAns[curAnsN] = v3;
							end
						end
					end

					if check and (not fCodeFilter or fCodeFilter[v2[2]]) then
						curAnsN = curAnsN + 1;
						curAns[curAnsN] = v2;
					end
				end

				if curAnsN >= maxEntries then
					print('|cffff9900WARNING!', 'Some UNITS have too much data! Not all will be saved!|r');
					break;
				end
			end

			if curAnsN > 0 then
				if curAnsN > 1 then
					table.sort(curAns, SortLog);
				end

				entriesN = entriesN + curAnsN;

				ansN = ansN + 1;
				ans[ansN] = curAns;

				u2i[u] = ansN;
				i2u[ansN] = u;
			end
		end

		local transport2UnitsHash = setmetatable({}, {
			__index = function(t,k)
				if rawget(t,k) == nil then
					rawset(t, k, {});
				end
				return rawget(t,k);
			end
		});

		for u,_ in pairs(log) do
			local transp = unit2TransportHash[u];
			
			if IsUnitLoaded(u) and not IsUnitGone(transp) and (globalModes.savePreplacedUnits or not preplacedWidgets.units[transp]) then
				local hash = transport2UnitsHash[transp];
				hash[#hash+1] = u;
			else
				unit2TransportHash[u] = nil;
			end
		end

		local lastInd = #ans;
		for transp, units in pairs(transport2UnitsHash) do
			local ind = u2i[transp];
			if ind then
				ans[ind], ans[lastInd], u2i[transp], u2i[i2u[lastInd]], i2u[ind], i2u[lastInd] = ans[lastInd], ans[ind], lastInd, ind, i2u[lastInd], i2u[ind];

				lastInd = lastInd - 1;

				ind = u2i[transp];
				local curLog = ans[ind];

				curLog[#curLog+1] = {200, fCodes.ForceLoadUnits, {
					{fCodes.GetLoggingUnit, {ind}}, {fCodes.GetLoggingUnitsSafe0, Map(units, function(v) return u2i[v] end)}
				}};
			end
		end

		for i,v in ipairs(ans) do
			v[#v+1] = i2u[i];
		end

		u2i = nil;
		i2u = nil;

		return {ans, 'unit', {entriesN, ansN}};
	end

	local function CompileDestrsLog(log, fCodeFilter)
		if not log then return {{}, 'destructable', {0,0}} end;

		local maxLen = MagiLogNLoad.MAX_DESTRS_PER_FILE;
		local maxEntries = MagiLogNLoad.MAX_ENTRIES_PER_DESTR;
		local entriesN = 0;

		local ans = {};
		local ansN = 0;

		for destr, v in pairs(log) do
			if v[fCodes.LoadCreateDestructable] or globalModes.savePreplacedDestrs then
				local curAns = {};
				local curAnsN = 0;

				if ansN >= maxLen then
					print('|cffff9900WARNING!', 'Your save-file has too many DESTRUCTABLE entries! Not all will be saved!|r');
					break;
				end

				for _,v2 in pairs(v) do
					if not fCodeFilter or fCodeFilter[v2[2]] then
						curAnsN = curAnsN + 1;
						curAns[curAnsN] = v2;

						if curAnsN >= maxEntries then
							print('|cffff9900WARNING!', 'Some DESTRUCTABLES have too much data! Not all of it will be saved!|r');
							break;
						end
					end
				end

				if curAnsN > 0 then
					if curAnsN > 1 then
						table.sort(curAns, SortLog);
					end

					entriesN = entriesN + curAnsN;

					curAnsN = curAnsN+1;
					curAns[curAnsN] = destr;

					ansN = ansN + 1;
					ans[ansN] = curAns;

				end
			end
		end

		return {ans, 'destructable', {entriesN, ansN}};
	end

	local function CompileItemsLog(log, fCodeFilter)
		if not log then return {{}, 'item', {0,0}} end;

		local maxLen = MagiLogNLoad.MAX_ITEMS_PER_FILE;
		local maxEntries = MagiLogNLoad.MAX_ENTRIES_PER_ITEM;
		local entriesN = 0;

		local ans = {};
		local ansN = 0;

		for item, v in pairs(log) do
			local curAns = {};
			local curAnsN = 0;

			if ansN >= maxLen then
				print('|cffff9900WARNING!', 'Your save-file has too many ITEM entries! Not all will be saved!|r');
				break;
			end

			if fCodeFilter then
				for _,v2 in pairs(v) do
					if fCodeFilter[v2[2]] then
						curAnsN = curAnsN + 1;
						curAns[curAnsN] = v2;

						if curAnsN >= maxEntries then
							print('|cffff9900WARNING!', 'Some ITEMS have too much data! Not all of it will be saved!|r');
							break;
						end
					end
				end
			else
				for _,v2 in pairs(v) do
					curAnsN = curAnsN + 1;
					curAns[curAnsN] = v2;

					if curAnsN >= maxEntries then
						print('|cffff9900WARNING!', 'Some ITEMS have too much data! Not all of it will be saved!|r');
						break;
					end
				end
			end

			if curAnsN > 0 then
				if curAnsN > 1 then
					table.sort(curAns, SortLog);
				end
				entriesN = entriesN + curAnsN;

				curAnsN = curAnsN+1;
				curAns[curAnsN] = item;

				ansN = ansN + 1;
				ans[ansN] = curAns;
			end
		end

		return {ans, 'item', {entriesN, ansN}};
	end

	local function CompileTerrainLog(log, fCodeFilter)
		if not log then return {{}, 'terrain', {0,0}} end;

		local maxLen = MagiLogNLoad.MAX_TERRAIN_PER_FILE;

		local ans = {}
		local ansN = 0;

		for _,v in pairs(log) do
			if not fCodeFilter or fCodeFilter[v[2]] then
				ansN = ansN + 1;
				ans[ansN] = v;

				if ansN >= maxLen then
					print('|cffff9900WARNING!', 'Your save-file has too many TERRAIN entries! Not all will be saved!|r');
					break;
				end
			end
		end

		if ansN > 1 then
			table.sort(ans, SortLog);
		end

		return {ans, 'terrain', {ansN, 0}};
	end

	local function CompileResearchLog(log, fCodeFilter)
		if not log then return {{}, 'research', {0, 0}} end;

		local maxLen = MagiLogNLoad.MAX_RESEARCH_PER_FILE;

		local ans = {}
		local ansN = 0;

		for _,v in pairs(log) do
			if not fCodeFilter or fCodeFilter[v[2]] then
				ansN = ansN + 1;
				ans[ansN] = v;

				if ansN >= maxLen then
					print('|cffff9900WARNING!', 'Your save-file has too many RESEARCH entries! Not all will be saved!|r');
					break;
				end
			end
		end

		if ansN > 1 then
			table.sort(ans, SortLog);
		end

		return {ans, 'research', {ansN, 0}};
	end

	local function CompileExtrasLog(log, fCodeFilter)
		if not log then return {{}, 'extra', {0,0}} end;

		local maxLen = MagiLogNLoad.MAX_EXTRAS_PER_FILE;

		local ans = {}
		local ansN = 0;

		for _,entryCol in pairs(log) do
			for _,entry in pairs(entryCol) do
				if not fCodeFilter or fCodeFilter[entry[2]] then
					ansN = ansN + 1;
					ans[ansN] = entry;
					if ansN >= maxLen then
						print('|cffff9900WARNING!', 'Your save-file has too many EXTRA entries! Not all will be saved!|r');
						break;
					end
				end
			end
		end

		if ansN > 1 then
			table.sort(ans, SortLog);
		end

		return {ans, 'extra', {ansN,0}};
	end

	local function FindInLogsEnds(logs, val)
		local offset = 0;
		for _,log in ipairs(logs) do
			for i,elemLog in ipairs(log) do
				if elemLog[#elemLog] == val then
					return i+offset;
				end
			end
			offset = offset + #log;
		end

		return -1;
	end

	local function Handle2LogGetter(val, typeStr2LogHash)
		if val == nil then return nil end;

		local valType = type(val);

		if valType == 'number' then
			return (val == math_floor(val) and val) or
				((val > 2147483647*.0001 or val < -2147483647*.0001) and Round(val)) or
				{fCodes.Div10000, {Round(10000*val)}};
		end

		if valType == 'boolean' then return {fCodes.I2B, {B2I(val)}} end;

		if valType == 'string' then return {fCodes.utf8char, GetUTF8Codes(val)} end;

		valType = GetHandleTypeStr(val);
		local logs = typeStr2LogHash[valType];
		if logs then
			local ind = FindInLogsEnds(logs, val);
			if ind ~= -1 then
				return {typeStr2GetterFCode[valType], {ind}};
			end
		end

		PrintDebug('|cffff5500ERROR:Handle2LogGetter!', 'Cannot create getter for value of type',valType,'!|r');
		return nil;
	end

	local function CompileProxyTablesLog(log, fullLog)
		if not log then return {{}, 'proxy', {0,0}} end;

		local typeStr2LogHash = {};

		for _,v in ipairs(fullLog) do
			local typeName = v[2];
			if typeStr2LogHash[typeName] then
				local cur = typeStr2LogHash[typeName];
				cur[#cur+1] = v[1];
			else
				typeStr2LogHash[typeName] = {v[1]};
			end
		end

		local maxLen = MagiLogNLoad.MAX_PROXYTABLE_ENTRIES_PER_FILE;
		local breakCheck = false;
		local warningCheck = true;

		local ans = {};
		local ansN = 0;

		for varName,v in pairs(log) do
			for actualVar,v2 in pairs(v) do
				if _G[varName] == actualVar then
					for key,logEntry in pairs(v2) do
						local tkv = logEntry[3];

						local getterKey = Handle2LogGetter(tkv[2], typeStr2LogHash);
						if getterKey ~= nil then
							local getterVal = Handle2LogGetter(tkv[3], typeStr2LogHash);
							if getterVal ~= nil or tkv[3] == nil then

								ansN = ansN + 1;
								ans[ansN] = {logEntry[1], logEntry[2], { {fCodes.utf8char, GetUTF8Codes(tkv[1])}, getterKey, getterVal ~= nil and getterVal or {fCodes.Nil}}};

								if ansN >= maxLen then
									PrintDebug('|cffff9900WARNING:CompileProxyTablesLog!', 'Your save-file has too many PROXY TABLE entries! Not all will be saved!|r');
									breakCheck = true;
									break;
								end
							end

						elseif warningCheck then
							warningCheck = false;
							PrintDebug('|cffff5500ERROR:CompileProxyTablesLog!', 'Some key getters are nil and will be skipped!|r');
						end
					end
				end

				if breakCheck then break end;
			end

			if breakCheck then break end;
		end

		if ansN > 1 then
			table.sort(ans, SortLog);
		end

		return {ans, 'proxy', {ansN, 0}};
	end

	local function CompileHashtablesLog(log, fullLog)
		if not log then return {{}, 'hashtable', {0,0}} end;

		local typeStr2LogHash = {};

		for _,v in ipairs(fullLog) do
			local typeName = v[2];
			if typeStr2LogHash[typeName] then
				local cur = typeStr2LogHash[typeName];
				cur[#cur+1] = v[1];
			else
				typeStr2LogHash[typeName] = {v[1]};
			end
		end

		local maxLen = MagiLogNLoad.MAX_HASHTABLE_ENTRIES_PER_FILE;
		local breakCheck = false;
		local warningCheck = true;

		local ans = {};
		local ansN = 0;

		for name,v in pairs(log) do
			for actualHt,v2 in pairs(v) do
				if actualHt == _G[name] then
					for parentKey,v3 in pairs(v2) do
						for childKey,logEntry in pairs(v3) do
							local logArgs = logEntry[3]; --{hashtableName, value, childKey, parentKey}};

							local getterParentKey = Handle2LogGetter(logArgs[4], typeStr2LogHash);
							local getterChildKey = Handle2LogGetter(logArgs[3], typeStr2LogHash);

							if getterParentKey ~= nil and getterChildKey ~= nil then
								local getterVal = Handle2LogGetter(logArgs[2], typeStr2LogHash);

								if getterVal ~= nil or logArgs[2] == nil then
									getterVal = getterVal ~= nil and getterVal or {fCodes.Nil};

									ansN = ansN + 1;
									ans[ansN] = {logEntry[1], logEntry[2], { {fCodes.utf8char, GetUTF8Codes(logArgs[1])}, getterVal, getterChildKey, getterParentKey}};

									if ansN >= maxLen then
										PrintDebug('|cffff9900WARNING:CompileHashtablesLog!', 'Your save-file has too many PROXY TABLE entries! Not all will be saved!|r');
										breakCheck = true;
										break;
									end
								end

							elseif warningCheck then
								warningCheck = false;
								PrintDebug('|cffff5500ERROR:CompileHashtablesLog!', 'Some key getters are nil and will be skipped!|r');
							end
						end

						if breakCheck then break end;
					end

					if breakCheck then break end;
				end
			end

			if breakCheck then break end;
		end

		if ansN > 1 then
			table.sort(ans, SortLog);
		end

		return {ans, 'hashtable', {ansN,0}};
	end

	local function CompileVarsLog(log, fullLog)
		if not log then return {{}, 'var', {0,0}} end;

		local typeStr2LogHash = {};

		for _,v in ipairs(fullLog) do
			local typeName = v[2];
			if typeStr2LogHash[typeName] then
				local cur = typeStr2LogHash[typeName];
				cur[#cur+1] = v[1];
			else
				typeStr2LogHash[typeName] = {v[1]};
			end
		end

		local maxLen = MagiLogNLoad.MAX_VARIABLE_ENTRIES_PER_FILE;

		local ans = {};
		local ansN = 0;

		for name,entry in pairs(log) do
			local getterVal = Handle2LogGetter(entry[3][2], typeStr2LogHash);-- = {logGen.vars, fCodes.SaveIntoNamedVar, {{fCodes.utf8char, GetUTF8Codes(name)}, curVal}};

			if getterVal ~= nil or entry[3][2] == nil then
				ansN = ansN + 1;
				ans[ansN] = {entry[1], entry[2], {{fCodes.utf8char, GetUTF8Codes(entry[3][1])}, getterVal ~= nil and getterVal or {fCodes.Nil}}};

				if ansN >= maxLen then
					PrintDebug('|cffff9900WARNING:CompileVarsLog!', 'Your save-file has too many VARIABLE entries! Not all will be saved!|r');
					break;
				end
			end
		end

		if ansN > 1 then
			table.sort(ans, SortLog);
		end

		return {ans, 'var', {ansN,0}};
	end

	local function TrimLogs(logList)
		for _,log in ipairs(logList) do
			if type(log) == 'table' and type(log[1]) == 'table' then
				for _,v in ipairs(log) do
					if type(v[#v]) ~= 'table' then
						v[#v] = nil;
					end
				end
			end
		end
	end

	local function CreateSerialLogs(p)
		local pid = GetPlayerId(p);

		local n = 0;
		local fullLog = {};
		local tally = {};
		for k,_ in pairs(word2LoadLogFuncHash) do
			tally[k] = {0,0};
		end
		local log;

		n = n + 1;
		log = CompileTerrainLog(magiLog.terrainOfPlayer[pid]);
		fullLog[n] = log;
		Vec2Add_inPlace(tally[log[2]], log[3]);

		n = n + 1;
		log = CompileDestrsLog(magiLog.destrsOfPlayer[pid], fCodeFilters.destrs[1]);
		fullLog[n] = log;
		Vec2Add_inPlace(tally[log[2]], log[3]);

		n = n + 1;
		log = CompileUnitsLog(magiLog.unitsOfPlayer[pid]);
		fullLog[n] = log;
		Vec2Add_inPlace(tally[log[2]], log[3]);

		n = n + 1;
		log = CompileItemsLog(magiLog.itemsOfPlayer[pid]);
		fullLog[n] = log;
		Vec2Add_inPlace(tally[log[2]], log[3]);

		n = n + 1;
		log = CompileDestrsLog(magiLog.destrsOfPlayer[pid], fCodeFilters.destrs[2]);
		fullLog[n] = log;
		Vec2Add_inPlace(tally[log[2]], log[3]);

		n = n + 1;
		log = CompileResearchLog(magiLog.researchOfPlayer[pid]);
		fullLog[n] = log;
		Vec2Add_inPlace(tally[log[2]], log[3]);

		n = n + 1;
		log = CompileExtrasLog(magiLog.extrasOfPlayer[pid]);
		fullLog[n] = log;
		Vec2Add_inPlace(tally[log[2]], log[3]);

		n = n + 1;
		log = CompileHashtablesLog(magiLog.hashtablesOfPlayer[pid], fullLog);
		fullLog[n] = log;
		Vec2Add_inPlace(tally[log[2]], log[3]);

		n = n + 1;
		log = CompileProxyTablesLog(magiLog.proxyTablesOfPlayer[pid], fullLog);
		fullLog[n] = log;
		Vec2Add_inPlace(tally[log[2]], log[3]);

		n = n + 1;
		log = CompileVarsLog(magiLog.varsOfPlayer[pid], fullLog);
		fullLog[n] = log;
		Vec2Add_inPlace(tally[log[2]], log[3]);

		local manifest = {MagiLogNLoad.version, Map(PluckArray(fullLog, 2), function(v) return word2CodeHash[v] or 0 end)};

		fullLog = PluckArray(fullLog, 1);

		TrimLogs(fullLog);

		fullLog = {manifest, fullLog};

		local str = SerializeIntTable(fullLog);

		magiLog.unitsOfPlayer[pid] = nil;
		magiLog.itemsOfPlayer[pid] = nil;

		return str, tally;
	end

	


	local function TimerTick()
		globalTick = globalTick + 1;

		local len = #onLaterTickFuncs;

		if len > 0 then
			local i = 1;
			while i <= len do
				local fobj = onLaterTickFuncs[i];
				if globalTick >= fobj[1] then
					if fobj[3] then
						fobj[2](unpack(fobj[3]));
						fobj[3] = nil;
					else
						fobj[2]();
					end

					remove(onLaterTickFuncs,i);
					i = i-1;
					len = len-1;
				end
				i = i+1;
			end
		end

		if uploadingStream then
			local msgsN = uploadingStream.messagesN;
			local msgsSent = uploadingStream.messagesSent;
			if msgsSent < msgsN then
				local nextMsg = uploadingStream.messagesSent + 1;
				for n=1,50 do

					if not BlzSendSyncData('MLNL', uploadingStream.messages[nextMsg]) then
						break;
					end

					uploadingStream.messagesSent = nextMsg;
					nextMsg = nextMsg+1;

					if nextMsg > msgsSent then
						break;
					end
				end
			end
		end

		--#DEBUG
		if (globalTick&1023) == 0 then
			local tab = tabKeyCleaner[((globalTick >> 10)&tabKeyCleanerSize)+1];
			if tab then
				if tab.arr then
					local ind = (globalTick >> 10)&31;
					local innerTab = nil;
					repeat
						ind = ind + 1;
						innerTab = tab.arr[ind];
					until innerTab ~= nil or ind > 31;

					if innerTab and lastCleanedTab ~= innerTab and next(innerTab) then
						lastCleanedTab = innerTab;

						if tab.assertRef then
							for refName,v in pairs(innerTab) do
								for ref,v2 in pairs(v) do
									if _G[refName] ~= ref then
										v[ref] = nil;
									end
								end
							end
						else
							local typeIdFunc = typeStr2TypeIdGetter[GetHandleTypeStr(next(innerTab))];
							for k,v in pairs(innerTab) do
								if typeIdFunc(k) == 0 then
									innerTab[k] = nil;
								end
							end
						end
					end
				else
					local map = nil;
					if tab.key then
						tab = tab.key;
						map = tab.map;
					end
					if tab and tab ~= lastCleanedTab and next(tab) then
						lastCleanedTab = tab;
						local typeIdFunc = typeStr2TypeIdGetter[GetHandleTypeStr(next(tab))];
						for k,v in pairs(tab) do
							if typeIdFunc(k) == 0 then
								tab[k] = nil;
								if map then TableSetDeep(map, nil, v) end
							end
						end
					end
				end
			end
		end

		signals.abortLoop = nil;
	end

	local function LoadTerrainLog(log)
		local lastId = 0;
		local entriesN = 0;
		for i,v in ipairs(log) do
			local curId = v[1];

			if lastId > curId then
				PrintDebug('|cffff5500ERROR:LoadTerrainLog!', 'Bad save-file detected while loading TERRAIN entry #',i,'!|r');
				return false;
			end

			lastId = curId;

			entriesN = entriesN + 1;
			int2Function[v[2]](UnpackLogEntry(v[3]));
		end

		return {entriesN,0};
	end

	local function LoadResearchLog(log)
		local entriesN = 0;
		local lastId = 0;
		for i,v in ipairs(log) do
			local curId = v[1];

			if lastId > curId then
				PrintDebug('|cffff5500ERROR:LoadResearchLog!', 'Bad save-file detected while loading RESEARCH entry #',i,'!|r');
				return false;
			end

			lastId = curId;

			int2Function[v[2]](UnpackLogEntry(v[3]));
			entriesN = entriesN + 1;
		end

		return {entriesN,0};
	end

	local function LoadExtrasLog(log)
		local entriesN = 0;
		local lastId = 0;
		for i,v in ipairs(log) do
			local curId = v[1];

			if lastId > curId then
				PrintDebug('|cffff5500ERROR:LoadExtrasLog!', 'Bad save-file detected while loading EXTRAS entry #',i,'!|r');
				return false;
			end

			lastId = curId;

			int2Function[v[2]](UnpackLogEntry(v[3]));
			entriesN = entriesN + 1;
		end

		return {entriesN,0};
	end

	local function LoadDestr(log)
		local lastId = 0;
		local entriesN = 0;
		for i,v in ipairs(log) do
			local curId = v[1];

			if lastId > curId then
				PrintDebug('|cffff5500ERROR:LoadDestr!', 'Bad save-file detected while loading DESTRUCTABLE #',i,'!|r');
				return false;
			end

			lastId = curId;

			int2Function[v[2]](UnpackLogEntry(v[3]));
			if signals.abortLoop == LoadDestr then
				signals.abortLoop = nil;
				break;
			end
			entriesN = entriesN + 1;
		end

		return entriesN;
	end

	local function LoadDestrsLog(log)
		local destrsN, destrEntriesN = 0,0;
		for i,v in ipairs(log) do
			destrsN = destrsN + 1;
			logDestrsN = logDestrsN + 1;
			destrEntriesN = destrEntriesN + LoadDestr(v);
		end

		return {destrEntriesN, destrsN};
	end

	

	local function LoadUnitsLog(log)
		local unitsN, unitEntriesN = 0,0;
		for i,v in ipairs(log) do
			unitsN = unitsN + 1;
			logUnitsN = logUnitsN+1;
			unitEntriesN = unitEntriesN + LoadUnit(v);
		end

		return {unitEntriesN, unitsN};
	end


	local function LoadItem(log)
		local entriesN = 0;
		local lastId = 0;
		for i,v in ipairs(log) do
			local curId = v[1];

			if lastId > curId then
				PrintDebug('|cffff5500ERROR:LoadItem!', 'Bad save-file detected while loading ITEM #',i,'!|r');
				return false;
			end

			lastId = curId;

			int2Function[v[2]](UnpackLogEntry(v[3]));
			if signals.abortLoop == LoadItem then
				signals.abortLoop = nil;
				break;
			end
			entriesN = entriesN + 1;
		end

		return entriesN;
	end


	local function LoadItemsLog(log)
		local itemsN, itemEntriesN = 0,0;
		for i,v in ipairs(log) do
			logItemsN = logItemsN+1;
			itemEntriesN = itemEntriesN + LoadItem(v);
			itemsN = itemsN + 1;
		end

		return {itemEntriesN, itemsN};
	end

	local function LoadProxyTablesLog(log)
		local entriesN = 0;
		local lastId = 0;
		for i,v in ipairs(log) do
			local curId = v[1];

			if lastId > curId then
				PrintDebug('|cffff5500ERROR:LoadProxyTablesLog!', 'Bad save-file detected while loading PROXY TABLE entry #',i,'!|r');
				return false;
			end

			lastId = curId;

			int2Function[v[2]](UnpackLogEntry(v[3]));
			entriesN = entriesN + 1;
		end

		return {entriesN,0};
	end

	local function LoadHashtablesLog(log)
		local entriesN = 0;
		local lastId = 0;
		for i,v in ipairs(log) do
			local curId = v[1];

			if lastId > curId then
				PrintDebug('|cffff5500ERROR:LoadHashtablesLog!', 'Bad save-file detected while loading HASHTABLE entry #',i,'!|r');
				return false;
			end

			lastId = curId;

			int2Function[v[2]](UnpackLogEntry(v[3]));
			entriesN = entriesN + 1;
		end

		return {entriesN,0};
	end

	local function LoadVarsLog(log)
		local entriesN = 0;
		local lastId = 0;
		for i,v in ipairs(log) do
			local curId = v[1];

			if lastId > curId then
				PrintDebug('|cffff5500ERROR:LoadVarsLog!', 'Bad save-file detected while loading VARIABLE entry #',i,'!|r');
				return false;
			end

			lastId = curId;

			int2Function[v[2]](UnpackLogEntry(v[3]));
			entriesN = entriesN + 1;
		end

		return {entriesN,0};
	end

	local function PrintTally(totalTime, tally, prefix)
		print('Total '..prefix..'ing Time:', totalTime, 'seconds.');
		if tally['terrain'] and tally['terrain'][1] > 0 then
			print(prefix..'ed',tally['terrain'][1], 'terrain entries!')
		end
		if tally['destructable'] and tally['destructable'][1] > 0 then
			print(prefix..'ed',tally['destructable'][2], 'destructables with a total of', tally['destructable'][1], 'properties!');
		end
		if tally['unit'] and tally['unit'][1] > 0 then
			print(prefix..'ed',tally['unit'][2], 'units with a total of', tally['unit'][1], 'properties!')
		end
		if tally['item'] and tally['item'][1] > 0 then
			print(prefix..'ed',tally['item'][2], 'items with a total of', tally['item'][1], 'properties!')
		end
		if tally['research'] and tally['research'][1] > 0 then
			print(prefix..'ed',tally['research'][1], 'research entries!')
		end
		if tally['extra'] and tally['extra'][1] > 0 then
			print(prefix..'ed', tally['extra'][1], 'extras entries!')
		end
		if tally['hashtable'] and tally['hashtable'][1] > 0 then
			print(prefix..'ed', tally['hashtable'][1], 'hashtable entries!')
		end
		if tally['proxy'] and tally['proxy'][1] > 0 then
			print(prefix..'ed', tally['proxy'][1], 'proxy table entries!')
		end
		if tally['var'] and tally['var'][1] > 0 then
			print(prefix..'ed', tally['var'][1], 'variable entries!')
		end
	end

	local function LoadCreateDestructable(destrid, argX, argY, face, sca, vari)
		local destr = CreateDestructable(destrid, argX, argY, face, sca, vari);
		if not destr then
			PrintDebug('|cffff5500ERROR:LoadCreateDestructable!', 'Failed to create destructable with id:',FourCC2Str(destrid),'!|r');
			signals.abortLoop = LoadDestr;
			return nil;
		end

		logDestrs[logDestrsN] = destr;

		return destr;
	end
	
	--#AZZY2
	
	function MagiLogNLoad.LoadPlayerSaveFromString(p, argStr, startTime)
		downloadingStreamFrom = nil;

		--#PROD
		local str = LibDeflate.DecompressDeflate(COBSDescape(argStr));

		if not str then
			print('|cffff5500Error!', 'Bad save-file! Cannot decompress.|r');
			return false;
		end

		str = str:gsub(sanitizer, '');

		if not str then
			print('|cffff5500Error!', 'Bad save-file! Aborting loading...|r');
			return false;
		end
		
		if MagiLogNLoad.oldTypeId2NewTypeId and next(MagiLogNLoad.oldTypeId2NewTypeId) then
			PrintDebug('|cffff9900WARNING:MagiLogNLoad.LoadPlayerSaveFromString!', 'Replacing old type ids with new ones in MagiLogNLoad.oldTypeId2NewTypeId...|r');
			
			str = str:gsub(PERC..'-?'..PERC..'d+', MagiLogNLoad.oldTypeId2NewTypeId);
		end
		
		local logs = Deserialize(str);
		
		if not logs then
			print('|cffff5500Error!', 'Bad save-file! Cannot deserialize.|r');
			return false;
		end
		
		--#AZZY1

		local manifest = logs[1];
		if not manifest then
			print('|cffff5500Error!', 'Bad save-file! Manifest is missing.|r');
			return false;
		end

		if not manifest[1] or manifest[1] < MagiLogNLoad.version then
			PrintDebug('|cffff9900WARNING:MagiLogNLoad.LoadPlayerSaveFromString!', 'Unexpected save-file version detected! Trying to load it anyway...|r');
		end
		

		logs = logs[2];

		local tally = {};
		for k,_ in pairs(word2LoadLogFuncHash) do
			tally[k] = {0,0};
		end

		logUnits = {};
		logUnitsN = 0;

		logDestrs = {};
		logDestrsN = 0;

		logItems = {};
		logItemsN = 0;

		local oldLoggingPId = loggingPid;
		MagiLogNLoad.SetLoggingPlayer(p);

		for i,v in ipairs(manifest[2]) do
			if v ~= 0 then
				local word = code2WordHash[v];

				Vec2Add_inPlace(tally[word], word2LoadLogFuncHash[word](logs[i]));
			end
		end

		logUnits = nil;
		logUnitsN = 0;

		logDestrs = nil;
		logDestrsN = 0;

		logItems = nil;
		logItemsN = 0;

		print('|cffaaaaaaLoading is done! MagiLogNLoad is cooling down and collecting reports...|r');
		local totalTime = startTime and os.clock()- startTime or nil;
		onLaterTickFuncs[#onLaterTickFuncs+1] = {globalTick + 100,
			function()
				downloadingStreamFrom = nil;
				if #loadingQueue > 0 then

					local queued = loadingQueue[1];
					if queued then
						table.remove(loadingQueue, 1);
						if queued[1] == GetLocalPlayer() then
							MagiLogNLoad.SyncLocalSaveFile(queued[2]);
						end
					end
				end

				print('|cff00fa33', GetPlayerName(p), 'has loaded their save-file successfully!|r');
				if totalTime then
					PrintTally(totalTime, tally, 'Load');
				end
			end
		};

		playerLoadInfo[loggingPid].count = playerLoadInfo[loggingPid].count - 1;
		loggingPid = oldLoggingPId;

		downloadingStreamFrom = p;

		return true;
	end

	function MagiLogNLoad.SaveLocalPlayer(fileName)
		local t0 = os.clock();

		local p = GetLocalPlayer();
		CreateUnitsOfPlayerLog(p);
		CreateItemsOfPlayerLog(p);
		CreateExtrasOfPlayerLog(p);

		fileName = fileName:gsub(fileNameSanitizer, '');
		if fileName:sub(-4,-1) ~= '.pld' then
			fileName = fileName..'.pld';
		end
		fileName = MagiLogNLoad.SAVE_FOLDER_PATH .. fileName;

		local logs, tally = CreateSerialLogs(p);
		--#PROD
		FileIO.SaveFile(fileName, String2SafeUTF8(COBSEscape(LibDeflate.CompressDeflate(logs))));

		print('|cff00fa33File|r |cffffdd00', fileName, '|r |cff00fa33saved successfully!|r');
		PrintTally(os.clock() - t0, tally, 'Sav');
	end

	function MagiLogNLoad.SyncLocalSaveFile(fileName)
		fileName = fileName:gsub(fileNameSanitizer, '');
		if fileName:sub(-4,-1) ~= '.pld' then
			fileName = fileName..'.pld';
		end

		local filePath = MagiLogNLoad.SAVE_FOLDER_PATH .. fileName;

		local startTime = os.clock();

		local logStr = FileIO.LoadFile(filePath);

		if not logStr then
			print('|cffff5500Error!','Missing save-file or unable to read it! File Path:|r',filePath);
			return false;
		end

		local pid = GetPlayerId(GetLocalPlayer());

		--#PROD
		logStr = string_char(unpack(GetCharCodesFromUTF8(logStr)));

		local logStrLen = #logStr;

		local tally = magiStreams[pid];
		if not tally then
			tally = {};
			magiStreams[pid] = tally;
		end

		logGen.streams = logGen.streams + 1;
		uploadingStream = {
			localFileName = fileName,
			localChunkCount = 0,
			localChunks = {},
			checks = {},
			messages = {},
			messagesN = 0,
			messagesSent = 0,
			startTime = startTime
		};
		tally[logGen.streams] = uploadingStream;

		local arr = tally[logGen.streams].messages;
		local arrN = 0;
		local ind0 = 1;
		local ind1 = 1;

		local msgLen = 250-1;
		local totalChunks = 1+math_floor(logStrLen/250);

		local totalChunksB0 = (totalChunks>>7)+1;
		local totalChunksB1 = (totalChunks&127)+1;

		while ind0 < logStrLen do
			ind1 = ind0 + msgLen;
			ind1 = ind1 > logStrLen and logStrLen or ind1;

			arrN = arrN + 1;
			arr[arrN] = string_char(logGen.streams, (arrN >> 7)+1, (arrN&127)+1, totalChunksB0, totalChunksB1) .. logStr:sub(ind0, ind1);

			ind0 = ind1 + 1;
		end

		uploadingStream.localChunkCount = arrN;
		uploadingStream.messagesN = arrN;
		uploadingStream.messagesSent = 0;

		return true;
	end

	function MagiLogNLoad.QueuePlayerLoadCommand(p, fileName)
		if downloadingStreamFrom == p then
			if p == GetLocalPlayer() then
				print('|cffff5500Error! You are already loading a save-file!|r');
			end
		else
			local ind = ArrayIndexOfPlucked(loadingQueue, p, 1);
			loadingQueue[ind == -1 and (#loadingQueue+1) or ind] = {p, fileName};
			if p == GetLocalPlayer() then
				print('|cffffdd00Another player is currently loading a save-file!|r');
				print('|cffffdd00Please wait! Your save-file|r', fileName,'|cffffdd00will soon load automatically.|r');
			end
		end
	end

	local function TrySetReferencedLogging(val, pid, entry)
		if val == nil then return false end;

		local arr = typeStr2ReferencedArraysHash[GetHandleTypeStr(val)];

		if not arr then return false end;

		if not arr[pid] then
			arr[pid] = {};
		end

		arr = arr[pid];
		arr[val] = entry;
		if not logEntry2ReferencedHash[entry] then
			logEntry2ReferencedHash[entry] = {};
		end
		logEntry2ReferencedHash[entry][val] = arr;

		return true;
	end

	function MagiLogNLoad.UpdateSaveableVarsForPlayerId(pid)
		local log = magiLog.varsOfPlayer[pid];
		if not log then
			log = {};
			magiLog.varsOfPlayer[pid] = log;
		end

		for name,_ in pairs(saveables.vars) do
			local curVal = _G[name];
			if curVal == nil and name:sub(1,4) ~= 'udg_' and _G['udg_'..name] ~= nil then
				saveables.vars['udg_'..name] = saveables.vars[name];
				saveables.vars[name] = nil;
			end
		end

		for name,vals in pairs(saveables.vars) do
			local curVal = _G[name];
			if curVal and (type(curVal) == 'table' or GetHandleTypeStr(curVal) == 'group') then
				saveables.vars[name] = nil;
				MagiLogNLoad.WillSaveThis(name, true);
			elseif curVal ~= vals[1] then
				if log[name] then
					ResetReferencedLogging(log[name]);
				end
				if curVal ~= vals[2] then
					logGen.vars = logGen.vars+1;
					local entry = {logGen.vars, fCodes.SaveIntoNamedVar, {name, curVal}};

					log[name] = entry;

					TrySetReferencedLogging(curVal, pid, entry);
				else
					log[name] = nil;
				end
				
				vals[1] = curVal;
			end
		end
	end

	local function InitAllTriggers()
		local trig = CreateTrigger();

		TriggerRegisterAnyUnitEventBJ(trig, EVENT_PLAYER_UNIT_LOADED);
		TriggerAddAction(trig, (function()
			local u = GetTriggerUnit();
			local transp = GetTransportUnit();

			unit2TransportHash[u] = transp;

			transp = nil;
			u = nil;
		end));

		trig = CreateTrigger();

		TriggerRegisterAnyUnitEventBJ(trig, EVENT_PLAYER_UNIT_DROP_ITEM);
		TriggerAddAction(trig, (function()

			local item = GetManipulatedItem();

			local log = magiLog.items;

			log[item] = {GetPlayerId(GetOwningPlayer(GetManipulatingUnit()))};

			item = nil;
		end));



		trig = CreateTrigger();

		TriggerRegisterAnyUnitEventBJ(trig, EVENT_PLAYER_UNIT_RESEARCH_FINISH);
		TriggerAddAction(trig, (function()

			local pid = GetPlayerId(GetOwningPlayer(GetResearchingUnit()));
			local resId = GetResearched();
			local log = magiLog.researchOfPlayer[pid];

			if not log then
				log = {};
				magiLog.researchOfPlayer[pid] = log;
			end

			logGen.res = logGen.res + 1;
			log[logGen.res] = {logGen.res, fCodes.AddPlayerTechResearched, {{fCodes.GetLoggingPlayer}, resId, 1}};

		end));


		trig = CreateTrigger();

		for i=0,bj_MAX_PLAYER_SLOTS-1 do
			TriggerRegisterPlayerChatEvent(trig, Player(i), '-save ', false);
		end
		TriggerAddAction(trig, function()
			local fileName = GetEventPlayerChatString():sub(7, -1);

			if fileName == nil or #fileName < 1 or #fileName > 250 or (fileName:sub(1,1)):find(PERC..'a') == nil then
				if p == GetLocalPlayer() then
					print('|cffff5500Error! Invalid name for save-file!|r');
				end
				return;
			else
				local p = GetTriggerPlayer();

				MagiLogNLoad.UpdateSaveableVarsForPlayerId(GetPlayerId(p));

				if p == GetLocalPlayer() then
					MagiLogNLoad.SaveLocalPlayer(fileName);
				end
			end
		end);

		trig = CreateTrigger();

		for i=0,bj_MAX_PLAYER_SLOTS-1 do
			TriggerRegisterPlayerChatEvent(trig, Player(i), '-load ', false);
		end
		TriggerAddAction(trig, (function()
			local p = GetTriggerPlayer();
			local pid = GetPlayerId(p);
			local lp = GetLocalPlayer();

			if playerLoadInfo[pid].count <= 0 then
				if p == lp then
					print('|cffff5500Error! You have already loaded too many save-files this game!|r');
				end
				return;
			end

			local fileName = GetEventPlayerChatString():sub(7, -1);

			if p == lp and playerLoadInfo[pid].fileNameHash[fileName] then
				print('|cffff9900Warning! You have already loaded this save-file this game!|r')
				print('|cffff9900Any changes made might not load correctly until the map is restarted!|r');
			end

			if p == GetLocalPlayer() then
				if downloadingStreamFrom then
					MagiLogNLoad.QueuePlayerLoadCommand(p, fileName);
				else
					MagiLogNLoad.SyncLocalSaveFile(fileName);
				end
			end
		end));

		trig = CreateTrigger();
		for i=0,bj_MAX_PLAYER_SLOTS-1 do
			TriggerRegisterPlayerChatEvent(trig, Player(i), '-credits', true);
		end
		TriggerAddAction(trig, (function()
			if GetTriggerPlayer() == GetLocalPlayer() then
				print('|cffffdd00:: MagiLogNLoad v1.04 by ModdieMads @ HiveWorkshop.com|r');
				print('::>> Generously commissioned by the folks @ Azeroth Roleplay!');
			end
		end));

		trig = CreateTrigger()
        for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
            BlzTriggerRegisterPlayerSyncEvent(trig, Player(i), 'MLNL', false);
        end
        TriggerAddAction(trig, function()
			local p = GetTriggerPlayer();

			if not downloadingStreamFrom then
				print('|cffffdd00', GetPlayerName(p), 'has started loading a save-file. Please wait!|r');
			elseif downloadingStreamFrom ~= p then
				if p == GetLocalPlayer() and uploadingStream then
					PrintDebug('|cffff5500Error! You have jammed the network!|r');

					MagiLogNLoad.QueuePlayerLoadCommand(p, uploadingStream.localFileName);
					uploadingStream = nil;
				end
				return;
			end
			downloadingStreamFrom = p;

			local pid = GetPlayerId(p);

			local str = BlzGetTriggerSyncData();

			local streamId = string_byte(str, 1, 1);

			local chunkId = Concat7BitPair(string_byte(str, 2, 3));

			local chunkN = Concat7BitPair(string_byte(str, 4, 5));

			if streamId < logGen.streams then
				logGen.streams = streamId;
			end

			local tally = magiStreams[pid];
			if not tally then
				tally = {};
				magiStreams[pid] = tally;
			end

			if not tally[streamId] then
				tally[streamId] = {
					localChunkCount = chunkN,
					localChunks = {},
					checks = {}
				};
			end
			tally = tally[streamId];

			tally.localChunks[chunkId] = str:sub(6, #str);
			tally.localChunkCount = tally.localChunkCount - 1;


			if tally.localChunkCount <= 0 then
				str = concat(tally.localChunks);
				local startTime;
				if uploadingStream then
					startTime = uploadingStream.startTime;
					playerLoadInfo[pid].fileNameHash[uploadingStream.localFileName] = true;
					uploadingStream = nil;
				end

				MagiLogNLoad.LoadPlayerSaveFromString(p, str, startTime);
			end

        end);
	end

	local function MapPreplacedWidgets()
		preplacedWidgets = {
			units = {},
			unitMap = {},
			items = {},
			itemMap = {}
		};

		for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
            GroupEnumUnitsOfPlayer(tempGroup, Player(i), Filter(function()
				local u = GetFilterUnit();
				local params = {Round(GetUnitX(u)), Round(GetUnitY(u)), GetUnitTypeId(u), GetPlayerId(GetOwningPlayer(u))};
				preplacedWidgets.units[u] = params;
				TableSetDeep(preplacedWidgets.unitMap, u, params);

				if UnitInventorySize(u) > 0 then
					for i=0,5 do
						local item = UnitItemInSlot(u, i);
						if item then
							preplacedWidgets.items[item] = {GetItemTypeId(item), i, unpack(params)};
						end
					end
				end
			end));
			GroupClear(tempGroup);
        end

		EnumItemsInRect(WORLD_BOUNDS.rect, nil, function()
			local item = GetEnumItem();
			local params = {GetItemTypeId(item), -1, Round(GetItemX(item)), Round(GetItemY(item))};
			preplacedWidgets.items[item] = params;
			TableSetDeep(preplacedWidgets.itemMap, item, params);
		end);
	end

	local function ResetReferencedLogging(entry)
		if not logEntry2ReferencedHash[entry] then return end;

		for k,v in pairs(logEntry2ReferencedHash[entry]) do
			v[k] = nil;
		end

		logEntry2ReferencedHash[entry] = nil;
	end

	local function SaveIntoNamedVar(varName, val)
		if varName == nil then
			PrintDebug('|cffff5500ERROR:SaveIntoNamedVar!', 'Variable name is NIL!|r');
			return;
		end
		_G[varName] = val;
	end

	-- Proxy tables are expected to not have their metatables changed outside of this system.
	-- Proxy tables save changes made to them on an individual basis.
	-- This allows for only some changes to be saved, or for changes to be saved differently for each player.
	local function MakeProxyTable(argName, willSaveChanges)
		if argName == nil then
			PrintDebug('|cffff5500ERROR:MakeProxyTable!','Name passed to MakeProxyTable is NIL!|r');
			return false;
		end
		if type(argName) ~= 'string' then
			PrintDebug('|cffff5500ERROR:MakeProxyTable!','Name passed to MakeProxyTable must be a string! It is of type:', type(argName),'!|r');
			return false;
		end

		local varName = argName;
		local var = _G[varName];
		if var == nil then
			varName = 'udg_'..argName;
			var = _G[varName];
			if var == nil then
				PrintDebug('|cffff5500ERROR:MakeProxyTable!','Name passed must be the name of an initialized GUI Array or variable containing a Lua table!|r');
				return false;
			end
			if type(var) ~= 'table' then
				PrintDebug('|cffff5500ERROR:MakeProxyTable!','Name passed must be the name of a GUI Array or Table-type variable!|r');
				return false;
			end
		end

		if varName2ProxyTableHash[varName] == nil then
			local mt = getmetatable(var);
			if mt and (mt.__newindex or mt.__index) then
				PrintDebug('|cffff9900WARNING:MakeProxyTable!', 'Metatable of', varName, 'is being overwritten to make it saveable!|r');
			end

			varName2ProxyTableHash[varName] = {};
		end

		local tab = varName2ProxyTableHash[varName];
		if willSaveChanges then
			setmetatable(var, {
				__index = function(t, k)
					return tab[k];
				end,
				__newindex = function(t, k, v)
					if loggingPid >= 0 then
						local log = magiLog.proxyTablesOfPlayer;

						if not log[loggingPid] then
							log[loggingPid] = {};
						end
						log = log[loggingPid];

						if not log[varName] then
							log[varName] = {};
						end
						log = log[varName];

						if not log[var] then
							log[var] = {};
						end
						log = log[var];

						if v == nil then
							if log[k] ~= nil then
								ResetReferencedLogging(log[k]);
							end
							log[k] = nil;
						else
							logGen.proxy = logGen.proxy + 1;
							local entry = {logGen.proxy, fCodes.SaveIntoNamedTable, {varName, k, v}};

							if log[k] then
								ResetReferencedLogging(log[k]);
							end

							log[k] = entry;

							TrySetReferencedLogging(k, loggingPid, entry);
							TrySetReferencedLogging(v, loggingPid, entry);
						end
					end
					tab[k] = v;
				end
			});
		else
			setmetatable(var, {
				__index = function(t, k)
					return tab[k];
				end,
				__newindex = function(t, k, v)
					tab[k] = v;
				end
			});
		end
		rawset(var,0,nil);
		rawset(var,1,nil);

		return true;
	end

	local function SaveIntoNamedTable(varName, key, val)
		if key == nil or varName == nil or varName == '' then
			PrintDebug('|cffff5500ERROR:SaveIntoNamedTable!', 'Passed arguments are NIL!|r');
			return;
		end
		local var = _G[varName];
		if not var then
			PrintDebug('|cffff9900WARNING:SaveIntoNamedTable!', 'Table', varName, 'cannot be found! Creating a new table...|r');
			var = {};
			_G[varName] = var;
		end
		if not varName2ProxyTableHash[varName] then
			PrintDebug('|cffff9900WARNING:SaveIntoNamedTable!', 'Table', varName, 'is not proxied! Making a proxy table for it...|r');
			MakeProxyTable(varName, true);
		end

		var[key] = val;
	end

	function MagiLogNLoad.WillSaveThis(argName, willSave)
		if argName == nil or argName == '' then
			PrintDebug('|cffff5500ERROR:MagiLogNLoad.WillSaveThis!', 'Passed name of variable is NIL!|r');
			return;
		end

		local varName = argName;
		local obj = _G[varName];
		if obj == nil then
			varName = 'udg_'..argName;
			obj = _G[varName];
			if obj == nil then
				varName = argName;
			end
		end

		if obj == nil then
			PrintDebug('|cffff9900WARNING:MagiLogNLoad.WillSaveThis!', 'Variable:', varName, 'is NOT initialized.',
				'If that variable is supposed to hold a table, initialize it BEFORE making it saveable.|r');
		else
			if type(obj) == 'table' then
				local mt = getmetatable(obj);
				if mt and mt.isHashtable then
					if willSave then
						saveables.hashtables[obj] = varName;
					else
						saveables.hashtables[obj] = nil;
					end

					return true;
				else
					return MakeProxyTable(varName, willSave);
				end
			elseif GetHandleTypeStr(obj) == 'group' then
				if willSave then
					saveables.groups[obj] = varName;
				else
					saveables.groups[obj] = nil;
				end
				return true;
			end
		end

		if willSave then
			saveables.vars[varName] = {obj, obj};
		else
			saveables.vars[varName] = nil;
		end

		return true;
	end

	local function HashtableGet(whichHashTable, parentKey)
		if GetHandleTypeStr(whichHashTable) == 'hashtable' then
			PrintDebug('|cffff5500ERROR:HashtableGet', 'Non-proxied hashtable detected! ALL hashtables MUST be created/initialized after MagiLogNLoad.Init()!|r');
		end
		local index = whichHashTable[parentKey];
		if not index then
			local tab = {};
			index = setmetatable({},{
				__index = function(t,k)
					return tab[k];
				end,
				__newindex = function(t,k,v)
					if loggingPid >= 0 and saveables.hashtables[whichHashTable] then
						local hashtableName = saveables.hashtables[whichHashTable];

						local log = magiLog.hashtablesOfPlayer;

						if not log[loggingPid] then
							log[loggingPid] = {};
						end
						log = log[loggingPid];

						if not log[hashtableName] then
							log[hashtableName] = {};
						end
						log = log[hashtableName];

						if not log[whichHashTable] then
							log[whichHashTable] = {};
						end
						log = log[whichHashTable];

						if v == nil then
							if log[parentKey] then
								if log[parentKey][k] ~= nil then
									ResetReferencedLogging(log[parentKey][k]);
								end
								log[parentKey][k] = nil;
							end
						else
							if not log[parentKey] then
								log[parentKey] = {};
							end
							log = log[parentKey];

							logGen.hashtable = logGen.hashtable + 1;
							local entry = {logGen.hashtable, fCodes.SaveIntoNamedHashtable, {hashtableName, v, k, parentKey}};

							if log[k] then
								ResetReferencedLogging(log[k]);
							end

							log[k] = entry;
							TrySetReferencedLogging(parentKey, loggingPid, entry);
							TrySetReferencedLogging(k, loggingPid, entry);
							TrySetReferencedLogging(v, loggingPid, entry);
						end
					end
					tab[k] = v;
				end
			});
			whichHashTable[parentKey] = index;
		end
		return index;
	end

	function MagiLogNLoad.HashtableSaveInto(value, childKey, parentKey, whichHashTable)
		if whichHashTable == nil then
			PrintDebug('|cffff5500ERROR:MagiLogNLoad.HashtableSaveInto!', 'Passed hashtable argument is NIL!|r');
			return false;
		end
		if childKey == nil or parentKey == nil then
			PrintDebug('|cffff5500ERROR:MagiLogNLoad.HashtableSaveInto!', 'Passed key arguments are NIL!|r');
			return false;
		end

		HashtableGet(whichHashTable, parentKey)[childKey] = value;
	end

	function MagiLogNLoad.HashtableLoadFrom(childKey, parentKey, whichHashTable, default)
		if whichHashTable == nil then
			PrintDebug('|cffff9900WARNING:MagiLogNLoad.HashtableLoadFrom!', 'Passed hashtable argument is NIL! Returning default...|r');
			return default;
		end
		if childKey == nil or parentKey == nil then
			PrintDebug('|cffff9900WARNING:MagiLogNLoad.HashtableLoadFrom!', 'Passed key arguments is NIL!  Returning default...|r');
			return default;
		end

		local val = HashtableGet(whichHashTable, parentKey)[childKey];
		return val ~= nil and val or default;
	end


	local function SaveIntoNamedHashtable(hashtableName, value, childKey, parentKey)
		if not _G[hashtableName] then
			PrintDebug('|cffff9900WARNING:SaveIntoNamedHashtable!', 'Hashtable', hashtableName, 'cannot be found! Creating new hashtable...|r');
			_G[hashtableName] = InitHashtableBJ();
		end

		MagiLogNLoad.HashtableSaveInto(value, childKey, parentKey, _G[hashtableName]);
	end

	local function KillDestructable_log(destr)
		if loggingPid < 0 or destr == nil or tempIsGateHash[destr] then return end;
		local log = magiLog.destrsOfPlayer;
		local pid = loggingPid;
		if not log[pid] then
			log[pid] = {};
		end
		log = log[pid];
		if not log[destr] then
			log[destr] = {};
		end

		if log[destr][fCodes.LoadCreateDestructable] then
			log[destr] = nil;
		else
			log[destr][fCodes.KillDestructable] = {10, fCodes.KillDestructable, {
				{fCodes.GetDestructableByXY, {Round(GetDestructableX(destr)), Round(GetDestructableY(destr))}}
			}};
		end
	end

	function MagiLogNLoad.DefineModes(_modes)
		if _modes then
			globalModes = _modes;
		elseif guiModes then
			local guiModesHash = Array2Hash(guiModes, 0, guiModesSlots, '');

			globalModes.debug = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.DEBUG] ~= nil;
			globalModes.savePreplacedUnits = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.SAVE_PREPLACED_UNITS] ~= nil;
			globalModes.savePreplacedItems = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.SAVE_PREPLACED_ITEMS] ~= nil;
			globalModes.savePreplacedDestrs = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.SAVE_PREPLACED_DESTRS] ~= nil;

			globalModes.saveAllUnitsOfPlayer = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.SAVE_ALL_UNITS_OF_PLAYER] ~= nil;
			globalModes.saveUnitsDisownedByPlayers = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.SAVE_UNITS_DISOWNED_BY_PLAYERS] ~= nil;

			globalModes.saveItemsDroppedManually = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.SAVE_ITEMS_DROPPED_MANUALLY] ~= nil;
			globalModes.saveAllItemsOnGround = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.SAVE_ALL_ITEMS_ON_GROUND] ~= nil;

			globalModes.saveDestrsKilledByUnits = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.SAVE_DESTRS_KILLED_BY_UNITS] ~= nil;
		end

		if globalModes.saveDestrsKilledByUnits then
			PrintDebug('|cffff9900WARNING:MagiLogNLoad.DefineModes!','Enabling saveDestrsKilledByUnits might be heavy on performance if there are too many destructables!|r');

			if not modalTriggers.saveDestrsKilledByUnits then
				local trig = CreateTrigger();
				modalTriggers.saveDestrsKilledByUnits = trig;

				EnumDestructablesInRect(WORLD_BOUNDS.rect, nil, function()
					TriggerRegisterDeathEvent(trig, GetEnumDestructable());
				end);
				TriggerAddAction(trig, function()
					KillDestructable_log(GetTriggerDestructable());
				end);
			end

			if not IsTriggerEnabled(modalTriggers.saveDestrsKilledByUnits) then
				EnableTrigger(modalTriggers.saveDestrsKilledByUnits);
			end
		else
			if IsTriggerEnabled(modalTriggers.saveDestrsKilledByUnits) then
				DisableTrigger(modalTriggers.saveDestrsKilledByUnits);
			end
		end

		if globalModes.savePreplacedItems then
			PrintDebug('|cffff9900WARNING:MagiLogNLoad.DefineModes!','Enabling savePreplacedItems might be heavy on performance if there are too many items!|r');

			if not modalTriggers.savePreplacedItems then
				local trig = CreateTrigger();
				modalTriggers.savePreplacedItems = trig;

				EnumItemsInRect(WORLD_BOUNDS.rect, nil, function()
					TriggerRegisterDeathEvent(trig, GetEnumItem());
				end);

				TriggerAddAction(trig, function()

					local widget = GetTriggerWidget();
					local item = nil;

					for k,v in pairs(preplacedWidgets.items) do
						if k == widget then
							item = k;
							break;
						end
					end

					if loggingPid < 0 or item == nil then return end;

					logGen.items = logGen.items + 1;
					magiLog.items[item] = {loggingPid, {[fCodes.RemoveItem] = {logGen.items, fCodes.RemoveItem, {{fCodes.GetPreplacedItem, preplacedWidgets.items[item]}}}}};
				end);
			end

			if not IsTriggerEnabled(modalTriggers.savePreplacedItems) then
				EnableTrigger(modalTriggers.savePreplacedItems);
			end
		else
			if IsTriggerEnabled(modalTriggers.savePreplacedItems) then
				DisableTrigger(modalTriggers.savePreplacedItems);
			end
		end

		if globalModes.debug then
			print('--- MLNL MODES ---');
			for k,v in pairs(globalModes) do
				print(k, ':', v);
			end
		end
	end

	local function InitGUI()
		if udg_mlnl_MakeProxyTable then
			if type(udg_mlnl_MakeProxyTable) ~= 'table' then
				PrintDebug('|cffff9900WARNING:InitGui!','GUI variable mlnl_MakeProxyTable must be an array! Its functionality has been disabled.|r');
			else
				setmetatable(udg_mlnl_MakeProxyTable, {
					__index = function(t, k)
						return nil;
					end,
					__newindex = function(t, k, v)
						MakeProxyTable(v);
					end
				});
				rawset(udg_mlnl_MakeProxyTable,0,nil);
				rawset(udg_mlnl_MakeProxyTable,1,nil);
			end
		end

		if udg_mlnl_Modes then
			if type(udg_mlnl_Modes) ~= 'table' then
				PrintDebug('|cffff9900WARNING:InitGui!','GUI variable mlnl_Modes must be an array! Its functionality has been disabled.|r');
			else
				guiModes = {};

				setmetatable(udg_mlnl_Modes, {
					__index = function(t, k)
						return guiModes[k];
					end,
					__newindex = function(t, k, v)
						guiModes[k] = v;
						MagiLogNLoad.DefineModes();
					end
				});
				rawset(udg_mlnl_Modes,0,nil);
				rawset(udg_mlnl_Modes,1,nil);
			end
		end

		if udg_mlnl_WillSaveThis then
			if type(udg_mlnl_WillSaveThis) ~= 'table' then
				PrintDebug('|cffff9900WARNING:InitGui!','GUI variable mlnl_WillSaveThis must be an array! Its functionality has been disabled.|r');
			else
				local tab = {};
				setmetatable(udg_mlnl_WillSaveThis, {
					__index = function(t, k)
						return tab[k];
					end,
					__newindex = function(t, k, v)
						v = v ~= '' and v or nil;

						if tab[k] ~= nil and v ~= tab[k] then
							MagiLogNLoad.WillSaveThis(tab[k], false);
						end

						if v ~= nil then
							MagiLogNLoad.WillSaveThis(v, true);
						end

						tab[k] = v;
					end
				});
				rawset(udg_mlnl_WillSaveThis,0,nil);
				rawset(udg_mlnl_WillSaveThis,1,nil);
			end
		end

		if udg_mlnl_LoggingPlayer then
			if type(udg_mlnl_LoggingPlayer) ~= 'table' then
				PrintDebug('|cffff9900WARNING:InitGui!','GUI variable mlnl_LoggingPlayer must be an array! Its functionality has been disabled.|r');
			else
				setmetatable(udg_mlnl_LoggingPlayer, {
					__index = function(t, k)
						return loggingPid > -1 and Player(loggingPid) or nil;
					end,
					__newindex = function(t, k, v)
						MagiLogNLoad.SetLoggingPlayer(v);
					end
				});
				rawset(udg_mlnl_LoggingPlayer,0,nil);
				rawset(udg_mlnl_LoggingPlayer,1,nil);
			end
		end

		--[[
			Adaptation of "GUI hashtable converter by Tasyen and Bribe" by ModdieMads

			Converts GUI hashtables API into Lua Tables, overwrites StringHashBJ and GetHandleIdBJ to permit
			typecasting, bypasses the 256 hashtable limit by avoiding hashtables, provides the variable
			"HashTableArray", which automatically creates hashtables for you as needed (so you don't have to
			initialize them each time).
		]]

		_G.StringHashBJ = NakedReturn;
		_G.StringHash = NakedReturn;
		_G.GetHandleIdBJ = NakedReturn;
		_G.GetHandleId = NakedReturn;

		local last;
		_G.GetLastCreatedHashtableBJ = function() return last end;
		_G.InitHashtableBJ = function()
			last = setmetatable({}, {isHashtable=true});
			return last;
		end

		_G.SaveIntegerBJ = MagiLogNLoad.HashtableSaveInto;
		_G.SaveRealBJ = MagiLogNLoad.HashtableSaveInto;
		_G.SaveBooleanBJ = MagiLogNLoad.HashtableSaveInto;
		_G.SaveStringBJ = MagiLogNLoad.HashtableSaveInto;

		local function createDefault(default)
			return function(childKey, parentKey, whichHashTable)
				return MagiLogNLoad.HashtableLoadFrom(childKey, parentKey, whichHashTable, default)
			end
		end
		local loadNumber = createDefault(0)
		_G.LoadIntegerBJ = loadNumber
		_G.LoadRealBJ = loadNumber
		_G.LoadBooleanBJ = createDefault(false)
		_G.LoadStringBJ = createDefault("")

		local saveHandleFuncs = {
			'SavePlayerHandleBJ', 'SaveWidgetHandleBJ', 'SaveDestructableHandleBJ', 'SaveItemHandleBJ', 'SaveUnitHandleBJ', 'SaveAbilityHandleBJ',
			'SaveTimerHandleBJ', 'SaveTriggerHandleBJ', 'SaveTriggerConditionHandleBJ','SaveTriggerActionHandleBJ','SaveTriggerEventHandleBJ',
			'SaveForceHandleBJ','SaveGroupHandleBJ','SaveLocationHandleBJ','SaveRectHandleBJ','SaveBooleanExprHandleBJ','SaveSoundHandleBJ',
			'SaveEffectHandleBJ', 'SaveUnitPoolHandleBJ','SaveItemPoolHandleBJ','SaveQuestHandleBJ','SaveQuestItemHandleBJ','SaveDefeatConditionHandleBJ',
			'SaveTimerDialogHandleBJ','SaveLeaderboardHandleBJ','SaveMultiboardHandleBJ','SaveTrackableHandleBJ','SaveDialogHandleBJ','SaveButtonHandleBJ',
			'SaveTextTagHandleBJ','SaveLightningHandleBJ','SaveImageHandleBJ','SaveUbersplatHandleBJ','SaveRegionHandleBJ','SaveFogStateHandleBJ','SaveFogModifierHandleBJ',
			'SaveAgentHandleBJ','SaveHashtableHandleBJ'
		};
		local loadHandleFuncs = {
			'LoadPlayerHandleBJ', 'LoadWidgetHandleBJ', 'LoadDestructableHandleBJ', 'LoadItemHandleBJ', 'LoadUnitHandleBJ', 'LoadAbilityHandleBJ',
			'LoadTimerHandleBJ', 'LoadTriggerHandleBJ', 'LoadTriggerConditionHandleBJ','LoadTriggerActionHandleBJ','LoadTriggerEventHandleBJ',
			'LoadForceHandleBJ','LoadGroupHandleBJ','LoadLocationHandleBJ','LoadRectHandleBJ','LoadBooleanExprHandleBJ','LoadSoundHandleBJ',
			'LoadEffectHandleBJ', 'LoadUnitPoolHandleBJ','LoadItemPoolHandleBJ','LoadQuestHandleBJ','LoadQuestItemHandleBJ','LoadDefeatConditionHandleBJ',
			'LoadTimerDialogHandleBJ','LoadLeaderboardHandleBJ','LoadMultiboardHandleBJ','LoadTrackableHandleBJ','LoadDialogHandleBJ','LoadButtonHandleBJ',
			'LoadTextTagHandleBJ','LoadLightningHandleBJ','LoadImageHandleBJ','LoadUbersplatHandleBJ','LoadRegionHandleBJ','LoadFogStateHandleBJ','LoadFogModifierHandleBJ',
			'LoadAgentHandleBJ','LoadHashtableHandleBJ'
		};

		for _,v in ipairs(saveHandleFuncs) do
			_G[v] = MagiLogNLoad.HashtableSaveInto;
		end

		for _,v in ipairs(loadHandleFuncs) do
			_G[v] = MagiLogNLoad.HashtableLoadFrom;
		end

		saveHandleFuncs = nil;
		loadHandleFuncs = nil;

		_G.HaveSavedValue = function(childKey, _, parentKey, whichHashTable)
			return HashtableGet(whichHashTable, parentKey)[childKey] ~= nil;
		end

		local flushChildren = function(whichHashTable, parentKey)
			if GetHandleTypeStr(whichHashTable) == 'hashtable' then
				PrintDebug('|cffff5500ERROR:Flush__HashtableBJ', 'Non-proxied hashtable detected! All Hashtables must be created/initialized after MagiLogNLoad.Init()!|r');
			end
			if whichHashTable and parentKey ~= nil then
				local tab = whichHashTable[parentKey];
				if tab then
					for k,v in pairs(tab) do
						tab[k] = nil;
					end
					whichHashTable[parentKey] = nil;
				end
			end
		end

		_G.FlushChildHashtableBJ = flushChildren;
		_G.FlushParentHashtableBJ = function(whichHashTable)
			for key,_ in pairs(whichHashTable) do
				flushChildren(whichHashTable[key]);
				whichHashTable[key] = nil;
			end
		end
	end



	local function InitAllFunctions()

		-- -=-==-=  UNIT LOGGING HOOKS  -=-==-=

		PrependFunction('SetUnitColor', function(whichUnit, whichColor)
			if not whichUnit then return end;

			local log = magiLog.units;


			if not log[whichUnit] then
				log[whichUnit] = {};
			end
			local logEntries = log[whichUnit];

			logEntries[fCodes.SetUnitColor] = {50, fCodes.SetUnitColor, {{fCodes.GetLoggingUnit}, {fCodes.ConvertPlayerColor, {deconvertPlayerColorHash[whichColor]}}}};

		end);

		PrependFunction('SetUnitVertexColor', function(u, r, g, b, a)
			if not u then return end;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end

			log[u][fCodes.SetUnitVertexColor] = {51, fCodes.SetUnitVertexColor, {{fCodes.GetLoggingUnit}, r, g, b, a}};
		end);

		PrependFunction('SetUnitTimeScale', function(u, sca)
			if not u then return end;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end

			log[u][fCodes.SetUnitTimeScale] = {52, fCodes.SetUnitTimeScale, {{fCodes.GetLoggingUnit}, sca}};
		end);

		PrependFunction('SetUnitScale', function(u, sx, sy, sz)
			if not u then return end;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end

			log[u][fCodes.SetUnitScale] = {54, fCodes.SetUnitScale, {
				{fCodes.GetLoggingUnit}, {fCodes.Div10000, {Round(10000*sx)}}, {fCodes.Div10000, {Round(10000*sy)}}, {fCodes.Div10000, {Round(10000*sz)}}
			}};
		end);

		PrependFunction('SetUnitAnimation', function(u, str)
			if not u or not str then return end;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end
			log = log[u];

			log[fCodes.SetUnitAnimation] = {[GetUnitCurrentOrder(u)] = {53, fCodes.SetUnitAnimation, {{fCodes.GetLoggingUnit}, {fCodes.utf8char, GetUTF8Codes(str)}}}};
		end);

		PrependFunction('SetUnitAnimationByIndex', function(u, int)
			if not u then return end;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end
			log = log[u];

			log[fCodes.SetUnitAnimation] = {[GetUnitCurrentOrder(u)] = {53, fCodes.SetUnitAnimationByIndex, {{fCodes.GetLoggingUnit}, int}}};
		end);

		PrependFunction('SetUnitAnimationWithRarity', function(u, str, rarity)
			if not u then return end;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end
			log = log[u];

			log[fCodes.SetUnitAnimation] = {
				[GetUnitCurrentOrder(u)] = {
					53, fCodes.SetUnitAnimationWithRarity, {
						{fCodes.GetLoggingUnit}, {fCodes.utf8char, GetUTF8Codes(str)}, {fCodes.ConvertRarityControl, {deconvertRarityControlHash[rarity]}}
					}
				}
			};
		end);

		PrependFunction('UnitAddAbility', function(u, abilid)
			if not u then return end;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end

			log = log[u];
			if not log[abilid] then
				log[abilid] = {};
			end

			log[abilid][fCodes.UnitAddAbility] = {70, fCodes.UnitAddAbility, {{fCodes.GetLoggingUnit}, abilid}};
		end);

		PrependFunction('UnitMakeAbilityPermanent', function(u, permanent, abilid)
			if not u then return end;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end

			log = log[u];
			if not log[abilid] then
				log[abilid] = {};
			end

			log[abilid][fCodes.UnitMakeAbilityPermanent] = {71, fCodes.UnitMakeAbilityPermanent, {{fCodes.GetLoggingUnit}, permanent, abilid}};
		end);

		PrependFunction('SetUnitAbilityLevel', function(u, abilid, level)
			if not u then return end;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end

			log = log[u];
			if not log[abilid] then
				log[abilid] = {};
			end

			log[abilid][fCodes.SetUnitAbilityLevel] = {72, fCodes.SetUnitAbilityLevel, {{fCodes.GetLoggingUnit}, abilid, level}};
		end);

		PrependFunction('UnitRemoveAbility', function(u, abilid)
			if not u then return end;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end

			log = log[u];
			if not log[abilid] then
				log[abilid] = {};
			end

			if log[abilid][fCodes.UnitAddAbility] then
				log[abilid] = nil;
			else
				log[abilid] = {[fCodes.UnitRemoveAbility] = {73, fCodes.UnitRemoveAbility, {{fCodes.GetLoggingUnit}, abilid}}};
			end
		end);

		PrependFunction('BlzSetUnitArmor', function(u, armor)
			if not u then return end;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end

			log[u][fCodes.LoadSetUnitArmor] = {110, fCodes.LoadSetUnitArmor, {{fCodes.GetLoggingUnit}, math_floor((armor-BlzGetUnitArmor(u, armor)+.7)*10)}};
		end);

		PrependFunction('BlzSetUnitName', function(u, str)
			if not u then return end;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end

			log[u][fCodes.BlzSetUnitName] = {55, fCodes.BlzSetUnitName, {{fCodes.GetLoggingUnit}, {fCodes.utf8char, GetUTF8Codes(str)}}};
		end);

		PrependFunction('SetUnitMoveSpeed', function(u, speed)
			if not u then return end;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end


			log[u][fCodes.LoadSetUnitMoveSpeed] = {111, fCodes.LoadSetUnitMoveSpeed, {{fCodes.GetLoggingUnit}, math_floor(speed + .5)}};
		end);

		PrependFunction('GroupAddUnit', function (g, u)
			if not g or not u or not saveables.groups[g] then return end;
			local gname = saveables.groups[g];

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end
			log = log[u];

			if not log[fCodes.LoadGroupAddUnit] then
				log[fCodes.LoadGroupAddUnit] = {};
			end
			log = log[fCodes.LoadGroupAddUnit];

			logGen.groups = logGen.groups+1;
			log[gname] = {190, fCodes.LoadGroupAddUnit, {{fCodes.utf8char, GetUTF8Codes(gname)}, {fCodes.GetLoggingUnit}}, logGen.groups};
		end);

		PrependFunction('GroupRemoveUnit', function (g, u)
			if not g or not saveables.groups[g] or not u then return end;
			local gname = saveables.groups[g];

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end
			log = log[u];

			if log[fCodes.LoadGroupAddUnit] then
				log[fCodes.LoadGroupAddUnit][gname] = nil;
			end
		end);

		PrependFunction('SetUnitOwner', function(u, p, changeColor)
			if not u or not p then return end;

			local newPid = GetPlayerId(p);
			local oldPid = GetPlayerId(GetOwningPlayer(u));

			if not neutralPIds[newPid] then
				if neutralPIds[oldPid] then
					magiLog.formerUnits[u] = nil;
				end

				return;
			end

			magiLog.formerUnits[u] = oldPid;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end

			log[u][fCodes.SetUnitOwner] = {130, fCodes.SetUnitOwner, {{fCodes.GetLoggingUnit}, {fCodes.Player, {newPid}}, {fCodes.I2B, {B2I(changeColor)}}}};
		end);


		-- -=-==-=  DESTRUCTABLE LOGGING HOOKS  -=-==-=

		PrependFunction('RemoveDestructable', function(destr)
			if loggingPid < 0 or destr == nil then return end;

			local log = magiLog.destrsOfPlayer;
			local pid = loggingPid;
			if not log[pid] then
				log[pid] = {};
			end
			log = log[pid];
			if not log[destr] then
				log[destr] = {};
			end

			if log[destr][fCodes.LoadCreateDestructable] then
				log[destr] = nil;
			else
				log[destr][fCodes.RemoveDestructable] = {20, fCodes.RemoveDestructable, {
					{fCodes.GetDestructableByXY, {Round(GetDestructableX(destr)), Round(GetDestructableY(destr))}}
				}};
			end
		end);

		PrependFunction('KillDestructable', KillDestructable_log);

		PrependFunction('DestructableRestoreLife', function (destr, life, birth)
			if loggingPid < 0 or destr == nil or tempIsGateHash[destr] then return end;

			local log = magiLog.destrsOfPlayer;
			local pid = loggingPid;
			if not log[pid] then
				log[pid] = {};
			end
			log = log[pid];
			if not log[destr] then
				log[destr] = {};
			end

			if log[destr][fCodes.KillDestructable] then
				log[destr][fCodes.KillDestructable] = nil;
			else
				log[destr][fCodes.DestructableRestoreLife] = {15, fCodes.DestructableRestoreLife, {
					{fCodes.GetDestructableByXY, {Round(GetDestructableX(destr)), Round(GetDestructableY(destr))}}, Round(life), {fCodes.I2B, {B2I(birth)}}
				}};
			end
		end);

		WrapFunction('CreateDestructable', function(destr, destrid, argX, argY, face, sca, vari)
			if loggingPid < 0 or destr == nil then return end;

			local log = magiLog.destrsOfPlayer;
			local pid = loggingPid;
			if not log[pid] then
				log[pid] = {};
			end
			log = log[pid];

			local x = GetDestructableX(destr);
			local y = GetDestructableY(destr);

			if not log[destr] then
				log[destr] = {};
			end

			log[destr] = {[fCodes.LoadCreateDestructable] = {1, fCodes.LoadCreateDestructable, {
				destrid, Round(x), Round(y), Round(face), {fCodes.Div10000, {Round(10000*sca)}}, vari
			}}};

			return destr;
		end);

		PrependFunction('ModifyGateBJ', function (op, destr)
			if loggingPid < 0 or destr == nil then return end;

			tempIsGateHash[destr] = true;

			local log = magiLog.destrsOfPlayer;
			local pid = loggingPid;
			if not log[pid] then
				log[pid] = {};
			end
			log = log[pid];
			if not log[destr] then
				log[destr] = {};
			end


			if log[destr][fCodes.LoadCreateDestructable] then
				log[destr][fCodes.ModifyGateBJ] = {30, fCodes.ModifyGateBJ, {
					op, {fCodes.GetDestructableByXY, {Round(GetDestructableX(destr)), Round(GetDestructableY(destr))}}
				}};
			end
		end);

		-- -=-==-=  TERRAIN LOGGING HOOKS  -=-==-=

		PrependFunction('SetTerrainType', function(x, y, terrainType, variation, area, shape)
			if loggingPid < 0 then return end;

			local log = magiLog.terrainOfPlayer;
			if not log[loggingPid] then
				log[loggingPid] = {};
			end
			log = log[loggingPid];

			x = math_floor((.5 + x // 64.) * 64);
			y = math_floor((.5 + y // 64.) * 64);

			logGen.terrain = logGen.terrain + 1;
			log[XY2Index30(x,y)] = {logGen.terrain, fCodes.SetTerrainType, {x, y, terrainType, variation, area, shape}};
		end);


		-- -=-==-=  EXTRAS LOGGING HOOKS  -=-==-=

		PrependFunction('SetBlightRect', function (p, r, addBlight)
			if not r or not p then return end;

			local pid = GetPlayerId(p);

			local log = magiLog.extrasOfPlayer;
			if not log[pid] then
				log[pid] = {};
			end
			log = log[pid];
			if not log[fCodes.SetBlightRect] then
				log[fCodes.SetBlightRect] = {};
			end
			log = log[fCodes.SetBlightRect];

			local minx, miny, maxx, maxy = Round(GetRectMinX(r)), Round(GetRectMinY(r)), Round(GetRectMaxX(r)), Round(GetRectMaxY(r));
			logGen.extras = logGen.extras + 1;
			log[XYZW2Index32(minx, miny, maxx, maxy)] = {
				logGen.extras, fCodes.SetBlightRect, {
					{fCodes.GetLoggingPlayer},
					{fCodes.Rect, {minx, miny, maxx, maxy}},
					{fCodes.I2B, {B2I(addBlight)}}
				}
			};
		end);

		PrependFunction('SetBlightPoint', function (p, x, y, addBlight)
			if not p then return end;
			local pid = GetPlayerId(p);

			local log = magiLog.extrasOfPlayer;
			if not log[pid] then
				log[pid] = {};
			end
			log = log[pid];
			if not log[fCodes.SetBlightPoint] then
				log[fCodes.SetBlightPoint] = {};
			end
			log = log[fCodes.SetBlightPoint];

			x = Round(x);
			y = Round(y);
			logGen.extras = logGen.extras + 1
			log[XY2Index30(x,y)] = {
				logGen.extras, fCodes.SetBlightPoint, {
					{fCodes.GetLoggingPlayer}, x, y, {fCodes.I2B, {B2I(addBlight)}}
				}
			};
		end);

		local SetBlight = function(p, x, y, radius, addBlight)
			if not p then return end;
			local pid = GetPlayerId(p);

			local log = magiLog.extrasOfPlayer;
			if not log[pid] then
				log[pid] = {};
			end
			log = log[pid];
			if not log[fCodes.SetBlight] then
				log[fCodes.SetBlight] = {};
			end
			log = log[fCodes.SetBlight];

			logGen.extras = logGen.extras + 1
			log[XYZ2Index30(x, y, radius)] = {
				logGen.extras, fCodes.SetBlight, {
					{fCodes.GetLoggingPlayer},
					Round(x),
					Round(y),
					Round(radius),
					{fCodes.I2B, {B2I(addBlight)}}
				}
			};
		end;

		PrependFunction('SetBlight', SetBlight);
		PrependFunction('SetBlightLoc', function (p, loc, radius, addBlight)
			SetBlight(p, GetLocationX(loc), GetLocationY(loc), radius, addBlight);
		end);

		local words = {'terrain', 'unit', 'destructable', 'item', 'research', 'extra', 'hashtable', 'proxy', 'var'};
		word2CodeHash = TableSetManyPaired(words, Range(1, #words));
		code2WordHash = InvertHash(word2CodeHash);
		word2LoadLogFuncHash = {
			['terrain'] = LoadTerrainLog,
			['unit'] = LoadUnitsLog,
			['destructable'] = LoadDestrsLog,
			['item'] = LoadItemsLog,
			['research'] = LoadResearchLog,
			['extra'] = LoadExtrasLog,
			['hashtable'] = LoadHashtablesLog,
			['proxy'] = LoadProxyTablesLog,
			['var'] = LoadVarsLog
		};

		fCodes.BlzSetHeroProperName, fCodes.BlzSetUnitName, fCodes.ConvertPlayerColor, fCodes.ConvertUnitState, fCodes.LoadCreateUnit, fCodes.GetLoggingItem,
		fCodes.GetLoggingUnit, fCodes.GetLoggingPlayer, fCodes.SelectHeroSkill, fCodes.SetHeroXP, fCodes.SetItemCharges, fCodes.SetTerrainType, fCodes.SetUnitAnimation,
		fCodes.SetUnitColor, fCodes.LoadSetUnitFlyHeight, fCodes.SetUnitState, fCodes.SetUnitTimeScale, fCodes.SetUnitVertexColor, fCodes.SetWidgetLife, fCodes.BlzSetUnitMaxHP,
		fCodes.BlzSetUnitMaxMana, fCodes.UnitAddAbility, fCodes.LoadUnitAddItemToSlotById, fCodes.UnitRemoveAbility, fCodes.ForceLoadUnits, fCodes.GetLoggingUnitsSafe0,
		fCodes.SetUnitPathing, fCodes.UpdateHeroStats, fCodes.UpdateUnitStats, fCodes.LoadSetUnitArmor, fCodes.LoadSetUnitMoveSpeed, fCodes.LogBaseStatsByType,
		fCodes.LoadCreateDestructable, fCodes.GetDestructableByXY, fCodes.UnitMakeAbilityPermanent, fCodes.LoadCreateItem, fCodes.utf8char, fCodes.ModifyGateBJ,
		fCodes.RemoveDestructable, fCodes.AddPlayerTechResearched, fCodes.I2B, fCodes.GetLoggingDestr, fCodes.SaveIntoNamedTable, fCodes.SetUnitAnimationByIndex,
		fCodes.SetUnitAnimationWithRarity, fCodes.ConvertRarityControl, fCodes.LoadGroupAddUnit, fCodes.GroupRemoveUnit, fCodes.SetUnitPosition, fCodes.Player, fCodes.Rect,
		fCodes.LoadSetPlayerState, fCodes.ConvertPlayerState, fCodes.LoadSetWaygate, fCodes.SetUnitOwner, fCodes.SetUnitScale, fCodes.SaveIntoNamedHashtable,
		fCodes.SetBlightPoint, fCodes.SetBlight, fCodes.SetBlightRect, fCodes.SetUnitAbilityLevel, fCodes.LoadPreplacedUnit, fCodes.KillDestructable, fCodes.Div10000,
		fCodes.LoadUnitAddPreplacedItem, fCodes.GetPreplacedItem, fCodes.Nil, fCodes.SaveIntoNamedVar, fCodes.ShowUnit, fCodes.LoadPreplacedItem,
		fCodes.DestructableRestoreLife,fCodes.RemoveItem = unpack(Range(1,128));

		int2Function = TableSetManyPaired(
			{
				fCodes.BlzSetHeroProperName, fCodes.BlzSetUnitName, fCodes.ConvertPlayerColor, fCodes.ConvertUnitState, fCodes.LoadCreateUnit, fCodes.GetLoggingItem,
				fCodes.GetLoggingUnit, fCodes.GetLoggingPlayer, fCodes.SelectHeroSkill, fCodes.SetHeroXP, fCodes.SetItemCharges, fCodes.SetTerrainType, fCodes.SetUnitAnimation,
				fCodes.SetUnitColor, fCodes.LoadSetUnitFlyHeight, fCodes.SetUnitState, fCodes.SetUnitTimeScale, fCodes.SetUnitVertexColor, fCodes.SetWidgetLife, fCodes.BlzSetUnitMaxHP,
				fCodes.BlzSetUnitMaxMana, fCodes.UnitAddAbility, fCodes.LoadUnitAddItemToSlotById,fCodes.UnitRemoveAbility,fCodes.ForceLoadUnits, fCodes.GetLoggingUnitsSafe0,
				fCodes.SetUnitPathing, fCodes.UpdateHeroStats, fCodes.UpdateUnitStats, fCodes.LoadSetUnitArmor, fCodes.LoadSetUnitMoveSpeed, fCodes.LogBaseStatsByType,
				fCodes.LoadCreateDestructable, fCodes.GetDestructableByXY, fCodes.UnitMakeAbilityPermanent, fCodes.LoadCreateItem,fCodes.utf8char, fCodes.ModifyGateBJ,
				fCodes.RemoveDestructable, fCodes.AddPlayerTechResearched, fCodes.I2B, fCodes.GetLoggingDestr, fCodes.SaveIntoNamedTable, fCodes.SetUnitAnimationByIndex,
				fCodes.SetUnitAnimationWithRarity, fCodes.ConvertRarityControl, fCodes.LoadGroupAddUnit, fCodes.GroupRemoveUnit, fCodes.SetUnitPosition, fCodes.Player, fCodes.Rect,
				fCodes.LoadSetPlayerState, fCodes.ConvertPlayerState, fCodes.LoadSetWaygate, fCodes.SetUnitOwner, fCodes.SetUnitScale,fCodes.SaveIntoNamedHashtable,
				fCodes.SetBlightPoint, fCodes.SetBlight, fCodes.SetBlightRect, fCodes.SetUnitAbilityLevel, fCodes.LoadPreplacedUnit, fCodes.KillDestructable,fCodes.Div10000,
				fCodes.LoadUnitAddPreplacedItem, fCodes.GetPreplacedItem, fCodes.Nil, fCodes.SaveIntoNamedVar, fCodes.ShowUnit, fCodes.LoadPreplacedItem,
				fCodes.DestructableRestoreLife, fCodes.RemoveItem
			}
			,
			{
				BlzSetHeroProperName, BlzSetUnitName, ConvertPlayerColor, ConvertUnitState, LoadCreateUnit, GetLoggingItem,
				GetLoggingUnit,  GetLoggingPlayer, SelectHeroSkill, SetHeroXP, SetItemCharges, SetTerrainType, SetUnitAnimation,
				SetUnitColor, LoadSetUnitFlyHeight, SetUnitState, SetUnitTimeScale, SetUnitVertexColor, SetWidgetLife, BlzSetUnitMaxHP,
				BlzSetUnitMaxMana, UnitAddAbility, LoadUnitAddItemToSlotById, UnitRemoveAbility, ForceLoadUnits, GetLoggingUnitsSafe0,
				SetUnitPathing, UpdateHeroStats, UpdateUnitStats, LoadSetUnitArmor, LoadSetUnitMoveSpeed, LogBaseStatsByType,
				LoadCreateDestructable, GetDestructableByXY, UnitMakeAbilityPermanent, LoadCreateItem, utf8.char, ModifyGateBJ,
				RemoveDestructable, AddPlayerTechResearched, I2B, GetLoggingDestr, SaveIntoNamedTable, SetUnitAnimationByIndex,
				SetUnitAnimationWithRarity, ConvertRarityControl, LoadGroupAddUnit,  GroupRemoveUnit, SetUnitPosition, Player, Rect,
				LoadSetPlayerState, ConvertPlayerState, LoadSetWaygate, SetUnitOwner, SetUnitScale, SaveIntoNamedHashtable,
				SetBlightPoint, SetBlight, SetBlightRect, SetUnitAbilityLevel, LoadPreplacedUnit, KillDestructable, Div10000,
				LoadUnitAddPreplacedItem, GetPreplacedItem, Nil, SaveIntoNamedVar, ShowUnit, LoadPreplacedItem,
				DestructableRestoreLife, RemoveItem
			}
		);

		fCodeFilters.destrs = {
			{[fCodes.KillDestructable]=true, [fCodes.RemoveDestructable]=true},
			{[fCodes.LoadCreateDestructable]=true, [fCodes.ModifyGateBJ]=true, [fCodes.DestructableRestoreLife]=true}
		};

		typeStr2GetterFCode = {
			['unit'] = fCodes.GetLoggingUnit,
			['item'] = fCodes.GetLoggingItem,
			['destructable'] = fCodes.GetLoggingDestr
		};
		typeStr2TypeIdGetter = {
			['unit'] = GetUnitTypeId,
			['item'] = GetItemTypeId,
			['destructable'] = GetDestructableTypeId
		};
		typeStr2ReferencedArraysHash = {
			['unit'] = magiLog.referencedUnitsOfPlayer,
			['item'] = magiLog.referencedItemsOfPlayer,
			['destructable'] = magiLog.referencedDestrsOfPlayer
		};

		fileNameSanitizer = concat({'[^',PERC,'a',PERC,'d',PERC,'.',PERC,'_',PERC,'-]'});

		sanitizer = concat({'[^',PERC,'{',PERC,'}',PERC,'d',PERC,',',PERC,'-]'});

	end

	local function InitAllRects()
		WORLD_BOUNDS = GetWorldBounds();
		WORLD_BOUNDS = {
			rect = WORLD_BOUNDS,
			minX = GetRectMinX(WORLD_BOUNDS),
			minY = GetRectMinY(WORLD_BOUNDS),
			maxX = GetRectMaxX(WORLD_BOUNDS),
			maxY = GetRectMaxY(WORLD_BOUNDS)
		};

		ENUM_RECT = Rect(-64.0, -64.0, 64.0, 64.0);
	end

	local function InitAllTables()
		for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
			playerLoadInfo[i] = {
				count = MagiLogNLoad.MAX_LOADS_PER_PLAYER,
				fileNameHash = {}
			};
        end
		
		if MagiLogNLoad.oldTypeId2NewTypeId and next(MagiLogNLoad.oldTypeId2NewTypeId) then
			
			local temp = {};
			for k,v in pairs(MagiLogNLoad.oldTypeId2NewTypeId) do
				temp[tostring(type(k) == 'string' and FourCC(k) or k)] = tostring(type(v) == 'string' and FourCC(v) or v);
			end
			MagiLogNLoad.oldTypeId2NewTypeId = temp;
		end
	end

	function MagiLogNLoad.SetLoggingPlayer(p)
		local pid;
		if p == nil then
			pid = -1;
		elseif GetHandleTypeStr(p) == 'player' then
			pid = GetPlayerId(p);
		else
			PrintDebug('|cffff5500ERROR:SetLoggingPlayer!', 'Argument passed is NOT a player!|r');
			return;
		end

		if pid ~= loggingPid and loggingPid ~= -1 then
			MagiLogNLoad.UpdateSaveableVarsForPlayerId(loggingPid);
		end
		loggingPid = pid;
		return loggingPid;
	end

	function MagiLogNLoad.ResetLoggingPlayer()
		MagiLogNLoad.SetLoggingPlayer(nil)
	end

	function MagiLogNLoad.GetLoggingPlayerId()
		return loggingPid;
	end

	function MagiLogNLoad.Init(_debug, _skipInitGUI)
		if IngameConsole then IngameConsole.ForceStart() end;

		InitAllRects();
		InitAllFunctions();

		MagiLogNLoad.DefineModes({debug=_debug});

		InitAllTables();
		InitAllTriggers();

		MapPreplacedWidgets();

		LibDeflate.InitCompressor();

		if not _skipInitGUI then
			InitGUI();
		end

		tabKeyCleaner = {
			{key=preplacedWidgets.units, map=preplacedWidgets.unitMap},
			{key=preplacedWidgets.items, map=preplacedWidgets.itemMap},

			{arr=magiLog.proxyTablesOfPlayer, assertRef=true},
			{arr=magiLog.hashtablesOfPlayer, assertRef=true},

			unit2TransportHash,
			magiLog.units,
			magiLog.formerUnits,
			{arr=magiLog.unitsOfPlayer},
			{arr=magiLog.referencedUnitsOfPlayer},

			{arr=magiLog.destrsOfPlayer},
			{arr=magiLog.referencedDestrsOfPlayer},

			magiLog.items,
			{arr=magiLog.itemsOfPlayer},
			{arr=magiLog.referencedItemsOfPlayer}
		};
		tabKeyCleanerSize = 15;

		globalTimer = CreateTimer();
		TimerStart(globalTimer, TICK_DUR, true, TimerTick);
	end
end

if Debug and Debug.endFile then Debug.endFile() end

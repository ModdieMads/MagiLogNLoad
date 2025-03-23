if Debug and Debug.beginFile then Debug.beginFile('MagiLogNLoad') end
--[[

Magi Log 'n Load v1.1

A preload-based save-load system for WC3!

(C) ModdieMads

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Permission is granted to anyone to use this software for personal purposes,
excluding any commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1.  The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation and public
    profiles is required.
2.  The Software and any modifications made to it may not be used for the purpose
    of training or improving machine learning algorithms, including but not
    limited to artificial intelligence, natural language processing, or data
    mining. This condition applies to any derivatives, modifications, or updates
    based on the Software code. Any usage of the Software in an AI-training
    dataset is considered a breach of this License.
3.  The Software may not be included in any dataset used for training or improving
    machine learning algorithms, including but not limited to artificial
    intelligence, natural language processing, or data mining.
3.  Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.
4.  This notice may not be removed or altered from any source distribution.

]]
--[[
Documentation has been kept to a minimum following feedback from @Wrda and @Antares.
Further explanation of the system will be provided by Discord messages.
Hit me up on HiveWorkshop's Discord server! @ModdieMads!

--------------------------------
 -- | Magi Log 'N Load v1.1 |--
 -------------------------------

 --> By ModdieMads @ https://www.hiveworkshop.com/members/moddiemads.310879/

 - Special thanks to:
    - @Adiniz/Imemi, for the opportunity! Check their map: https://www.hiveworkshop.com/threads/azeroth-roleplay.357579/
    - @Wrda, for the pioneering work in Lua save-load systems!
    - @Trokkin, for the FileIO code!
    - @Bribe and @Tasyen, for the Hashtable to Lua table converter!
    - @Eikonium, for the invaluable DebugUtils! And the template for this header...
    - Haoqian He, for the original LibDeflate!

-------------------------------------------------------------------------------------------------------------------+
| Provides logging and save-loading functionalities.                                                               |
|                                                                                                                  |
| Feature Overview:                                                                                                |
|   1. Save units, items, destructables, terrain tiles, variables, hashtables and more with a single command!      |
|   2. The fastest syncing of all available save-load systems, powered by LibDeflate and COBS streams!             |
|   3. The fastest game state reconstruction of all available save-load systems, powered by Lua!                   |
|   4. Save and load transports with units inside, cosmetic changes and per-player table and hashtable entries!    |
-------------------------------------------------------------------------------------------------------------------+

--------------------------------------------------------------------------------------------------------------+
| Installation:                                                                                               |
|                                                                                                             |
|   1. Open the provided map, and copy-paste the Trigger Editor's MagiLogNLoad folder into your map.          |
|   2. Order the script files from top to bottom: MLNL Config, MLNL FileIO, MLNL LibDeflate, MagiLogNload     |
|   3. Adjust the settings in the MLNL Config script to fit your needs.                                       |
|   4. Call MagiLogNLoad.Init() JUST AFTER the map has been initialized.                                      |
|                                                                                                             |
--------------------------------------------------------------------------------------------------------------+

--------------------------------------------------------------------------------------------------------------------------------------------------------
* Documentation and API-Functions:
*
*       - All automatic functionality provided by MagiLogNLoad can be deactivated by disabling the script files.
*
* -------------------------
* |       Commands        |
* -------------------------
*       - "-save <FILE PATH>" creates a save-file at the provided file path. Folders will be created as necessary.
*         > Powered by MagiLogNLoad.UpdateSaveableVarsForPlayerId() and MagiLogNLoad.CreatePlayerSaveFile().
*         > Can be altered in the config file.
*
*       - "-load <FILE NAME>" loads a save-file located at the provided file path.
*         > Powered by MagiLogNLoad.QueuePlayerLoadCommand() and MagiLogNLoad.SyncLocalSaveFile().
*         > Can be altered in the config file.
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
*             > _debug: Enables the system to initialize with the Debug mode enabled.
*             > _skipInitGUI: Skip initializing the GUI functions. Use this if your map doesn't use any GUI triggers.
*        - [IMPORTANT] When initializing the GUI functions, the system overrides the following natives:
*            > _G.StringHashBJ, _G.StringHash
*            > _G.GetHandleIdBJ, _G.GetHandleId
*            > All Hashtable natives
*
*    MagiLogNLoad.CreatePlayerSaveFile(p, fileName) < SYNC + ASYNC >
*        - Updates all referenced values (sync) then starts the process of saving a file if <p> is the local player (async).
*        - Args ->
*             > fileName: name of the file that will be created.
*             > player: player whose data will be saved.
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
*            - saveNewUnitsOfPlayer
*               > Save units created at runtime if they are owned by the saving player.
*            - savePreplacedUnitsOfPlayer
*               > Save changes to pre-placed units owned by the saving player. Might lead to conflicts in multiplayer.
*            - saveUnitsDisownedByPlayers
*               > Save units disowned by a player if the owner at the time of saving is one of the Neutral players.
*            - saveStandingPreplacedDestrs
*               > Save pre-placed trees/destructables. Might lead to conflicts in multiplayer.
*               > For the sake of good performance, the destruction of destrs is only saved if caused by the use of Remove/KillDestructable().
*            - saveDestroyedPreplacedDestrs
*               > Save trees/destructables that are killed by attacks or spells.
*               > Needs to have a loggingPid set for the logging to occur. 
*               > If the map has too many trees/destrs, its performance might suffer.
*            - savePreplacedItems
*               > Save changes to pre-placed items. Might lead to conflicts in multiplayer.
*               > If the item is destroyed or removed, its destruction will be recorded and reproduced when loaded.
*            - saveItemsDroppedManually
*               > Save items on the ground ONLY if a player's unit dropped them.
*               > Won't save items dropped by creeps or Neutral player's units.
*            - saveAllItemsOnGround
*               > Adds all items on the ground to the saving player's save-file.
*        - Args ->
*             - _modes: Table of the format { modeName1 = true, modeName2 = true, ...}
*                  - Example: { savePreplacedUnitsOfPlayer = true, saveNewUnitsOfPlayer = true }
*
*    MagiLogNLoad.SetLoggingPlayer(p), MagiLogNLoad.ResetLoggingPlayer(), MagiLogNLoad.GetLoggingPlayerId()
*        - Defines, resets and returns the PlayerId that will be used by the system to determine in which player's logs the incoming changes will be entered.
*        - This only applies to changes that cannot be automatically attributed to a player. Examples:
*            - Remove/CreateDestructable(), destructable deaths
*            - Remove/CreateItem(), item deaths
*            - Modifying global variables.
*            - And many more...
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
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* CHANGELOG:
* 1.10
*    - [FEATURE] MagiLogNLoad can now unload units from transports seamlessly when loading a save-file.
*        > Maps using this system require the custom ability 'AUNL' (customized 'Adri').
*        > Please refer to the provided test map and the MLNL_Config file.
*
*    - [BREAKING] MagiLogNLoad.CreatePlayerSaveFile has replaced MagiLogNLoad.SaveLocalPlayer.
*        > YOU MUST UPDATE ALL YOUR <MagiLogNLoad.SaveLocalPlayer> FUNCTION CALLS.
*        > It's now sync while updating references, then it becomes async when saving the actual file.
*
*    - [BREAKING] Mode <savePreplacedUnits> has been renamed to <savePreplacedUnitsOfPlayer>
*        > GUI config string has been changed to SAVE_PREPLACED_UNITS_OF_PLAYER. Please update your triggers.
*        > Functionality unchanged.
*
*    - [BREAKING] Mode <saveAllUnitsOfPlayer> has been renamed to <saveNewUnitsOfPlayer>.
*        > GUI config string has been changed to SAVE_NEW_UNITS_OF_PLAYER. Please update your triggers.
*        > Enabling this will only saved units that have been created at runtime.
*
*    - [BREAKING] Mode <saveDestrsKilledByUnits> has been renamed to <saveDestroyedPreplacedDestrs>.
*        > GUI config string has been changed to SAVE_DESTROYED_PREPLACED_DESTRS. Please update your triggers.
*        > Functionality unchanged.
*
*    - [BREAKING] MagiLogNLoad.ALL_CARGO_ABILS has been replaced by MagiLogNLoad.ALL_TRANSP_ABILS
*        > It now contains 2 arrays: CARGO, with all <Cargo Hold> abils in the map; and LOAD, with all <Load> abils in the map.
*        > All units are assumed to have just one abil of each category.
*
*    - Added the mode <saveDestroyedPreplacedUnits>.
*        > Save ALL destroyed pre-placed units as long as a logging player is defined when the destruction happens.
*    - Added a way to change the commands "-save" and "-load" to arbitrary strings in the config file.
*    - At the request of @Antares, added the following callback functions to ease integration and message editing:
*        > MagiLogNLoad.onSaveStarted
*        > MagiLogNLoad.onSaveFinished
*        > MagiLogNLoad.onLoadStarted
*        > MagiLogNLoad.onLoadFinished
*        > MagiLogNLoad.onSyncProgressCheckpoint
*        > MagiLogNLoad.onAlreadyLoadedWarning
*        > MagiLogNLoad.onMaxLoadsError
*
* 1.09
*    - Fixed a bunch of linting bugs thanks to @Tomotz
*    - Fixed a bug preventing huge reals from being saved correctly. S2R and R2S are still unstable.
*
* 1.08
*    - Added parallel bursting sync streams. Load times can be up to 50x faster.
*    - Added filename validation to prevent users from shooting themselves in the foot.
*    - Added internal state monitoring capabilities to the system. Errors should be much easier to track.
*    - Added the option for the map-maker to set a time limit for loading and syncing. The loading will fail in case it's exceeded.
*    - Added progress prints for file loading. They should show up at 25, 50 and 75% loading progress.
*    - Changed the default behavior for MagiLogNLoad.WillSaveThis. Ommitting the second argument will default to <true>.
*    - Fixed a possible jamming desync when multiple players are syncing at the same time.
*    - Fixed a bug involving some weird Blizzard functions, like SetUnitColor.
*    - Fixed a bug involving unit groups that could cause saves to fail.
*    - Fixed a bug involving proxied tables that could cause saves to fail.
*    - Fixed a bug causing real variables to sometimes save as 10x their normal value.
*    - Fixed a bug causing research/upgrade entries to sometimes not load correctly.

----------------------------------------------------------------------------------------------------------------------------------------------
]]

do
	MagiLogNLoad = MagiLogNLoad or {};
	MagiLogNLoad.engineVersion = 1100;

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
	
	local function UTF8Codes2Real(...)
		return tonumber(utf8.char(...));
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
	
	local function Lerp(v0, v1, t)
		return v0 + t*(v1-v0);
	end

	local function Terp(v0, v1, v)
		return (v-v0)/(v1-v0);
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


	local function PluckArray(arr, propName)
		local ans = {};

		for i,v in ipairs(arr) do
			ans[i] = v[propName];
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

	local function TableInvert(tab)
		local ans = {};

		for k,v in pairs(tab) do
			ans[v] = k;
		end

		return ans;
	end

	local int2Function = {};

	local PERC = utf8.char(37);

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
	local enumSingle;

	local BOARD_ORDER_ID = 852043;
	local UNLOAD_INSTA_ORDER_ID = 852049;
	local MAX_FOURCC = 2139062143;
	local MIN_FOURCC = 16843009;

	local sanitizer = '';
	local fileNameSanitizer = '';

	local TICK_DUR = .035;
	local mainTimer = {};
	local mainTick = 1;
	local onLaterTickFuncs = {};

	local WORLD_BOUNDS = {};

	MagiLogNLoad.ALL_TRANSP_ABILS = MagiLogNLoad.ALL_TRANSP_ABILS or {
		LOAD = {FourCC('Aloa'), FourCC('Sloa'), FourCC('Slo2'), FourCC('Slo3'), FourCC('Aenc')},
		CARGO = {FourCC('Sch3'), FourCC('Sch4'), FourCC('Sch5'), FourCC('Achd'), FourCC('Abun'), FourCC('Achl')}
	};
	
	MagiLogNLoad.BASE_STATES = {
		OFF = 0,
		STANDBY = 1,
		CLEANING_TABLES = 2
	};

	MagiLogNLoad.SAVE_STATES = {
		SAVE_CMD_ENTERED = 100,
		UPDATE_SAVEABLE_VARS = 110,
		CREATE_PLAYER_SAVEFILE = 120,
		CREATE_UNITS_OF_PLAYER_LOG = 130,
		CREATE_ITEMS_OF_PLAYER_LOG = 140,
		CREATE_EXTRAS_OF_PLAYER_LOG = 150,
		CREATE_SERIAL_LOGS = 160,
		COMPRESSING_LOGS = 170,
		FILE_IO_SAVE_FILE = 180,
		PRINT_TALLY = 190
	};

	MagiLogNLoad.LOAD_STATES = {
		LOAD_CMD_ENTERED = 500,
		QUEUE_LOAD = 510,
		SYNC_LOCAL_SAVE_FILE = 520,
		SETTING_START_OSCLOCK = 530,
		FILE_IO_LOAD_FILE = 540,
		GET_LOG_STR = 550,
		CREATE_UPLOADING_STREAM = 560,
		CREATE_MESSAGES = 570,
		SEND_SYNC_DATA = 580,
		SYNC_EVENT = 590,
		GETTING_MANIFESTS = 600,
		LOADING_LOGS = 605,
		SUCCESFUL_LOADING = 610,
		PRINT_TALLY = 620
	};

	MagiLogNLoad.stateOfPlayer = {};

	local word2CodeHash = {};
	local code2WordHash = {};
	local word2LoadLogFuncHash = {};
	local fCodes = {};
	local logEntry2ReferencedHash = {};

	local typeStr2TypeIdGetter;
	local typeStr2GetterFCode;
	local typeStr2ReferencedArraysHash;
	local fCodeFilters = {};

	local tempGroup, tempPlayerId;

	local varName2ProxyTableHash = {};
	local saveables = {
		groups = {},
		vars = {},
		hashtables = {}
	};

	local loggingPid = -1;
	local playerLoadInfo = {};

	local function GetHandleTypeStr(handle)
		local str = tostring(handle);
		return str:sub(1, (str:find(':', nil, true) or 0) - 1);
	end

	local StringTrim_CONST0 = '^'..PERC..'s*(.-)'..PERC..'s*$';
	local StringTrim_CONST1 = PERC..'1';
	local function StringTrim(s)
		return s:gsub(StringTrim_CONST0, StringTrim_CONST1);
	end

	local function GetUTF8Codes(str)
		local ans = {};
		local n = 0;
		for _, c in utf8.codes(str) do
			n = n+1;
			ans[n] = c;
		end
		return ans;
	end

	local function GetCharCodesFromUTF8(str)

		local ans = {};
		local ind = 0;
		for _, c in utf8.codes(str) do
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


	local serializeIntTableFuncs = {};
	local function SerializeIntTable(x)
		return serializeIntTableFuncs[type(x)](x);
	end


	serializeIntTableFuncs = {
		['number'] = function(v)
			return tostring(v);
		end,
		['table'] = function(t)
			local rtn = {};

			local rtnN = 0;

			for _,v in ipairs(t) do
				rtnN = rtnN + 1;
				rtn[rtnN] = SerializeIntTable(v);
			end

			return '{' .. concat(rtn, ',') .. '}';
		end
	};

	local function Deserialize(str)
		return load('return ' ..  str)();
	end

	local deconvertHash = {
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
		[PLAYER_COLOR_PEANUT] = 23,

		[UNIT_STATE_LIFE] = 0,
		[UNIT_STATE_MAX_LIFE] = 1,
		[UNIT_STATE_MANA] = 2,
		[UNIT_STATE_MAX_MANA] = 3,

		[RARITY_FREQUENT] = 0,
		[RARITY_RARE] = 1,

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

	-- Example values. These must always be overriden during initialization. 
	MagiLogNLoad.modes = {
		debug = true,

		savePreplacedUnitsOfPlayer = false,
		saveDestroyedPreplacedUnits = false,
		saveStandingPreplacedDestrs = true,
		savePreplacedItems = false,

		saveNewUnitsOfPlayer = true,
		saveUnitsDisownedByPlayers = true,

		saveItemsDroppedManually = true,
		saveAllItemsOnGround = false,

		saveDestroyedPreplacedDestrs = false
	};

	local function PrintDebug(...)
		if MagiLogNLoad.modes.debug then
			print(...);
		end
	end

	local guiModes;

	local modalTriggers = {};
	local issuedWarningChecks = {
		saveInPreplacedTransp = false,
		saveTransformedPreplacedUnit = false,
		tabKeyCleanerPanic = false,
		initPanic = false,

		loadTimeWarning = false,
		syncProgressCheckpoints = {}
	};
	local signals = {
		abortLoop = nil
	};

	local preplacedWidgets;
	local unit2TransportHash = {};
	local unit2HiddenStat = {};
	
	local tempIsGateHash = setmetatable({}, { __mode = 'k' });

	local streamsOfPlayer = {};
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
		return val/10000.;
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

	local function SortLog(a, b)
		return a[1] < b[1] or (a[1] == b[1] and a[4] and b[4] and a[4] < b[4]); -- because of LoadGroupAddUnit entries
	end

	local function IsUnitGone(u)
		return GetUnitTypeId(u) == 0 or IsUnitType(u, UNIT_TYPE_DEAD);
	end
	
	local function LogBaseStatsByType(u)
		-- Legacy function. Only here to not break things.
	end

	local function ResetTransportAfterLoad(transp, oriCastRanges, cargoUnits, oriMoveSpeeds, oriFacing)
		local j = 0;
		for _,v in pairs(MagiLogNLoad.ALL_TRANSP_ABILS) do
			for _,abilid in ipairs(v) do
				local lvl = GetUnitAbilityLevel(transp, abilid);
				if lvl > 0 then
					lvl = lvl -1;

					j = j + 1;
					BlzSetAbilityRealLevelField(BlzGetUnitAbility(transp, abilid), ABILITY_RLF_CAST_RANGE, lvl, oriCastRanges[j]);
					break;
				end
			end
		end
		
		for i, v in ipairs(cargoUnits) do
			oriG.SetUnitMoveSpeed(v, oriMoveSpeeds[i] or 298);
			
			local s = unit2HiddenStat[v] and unit2HiddenStat[v].scale or BlzGetUnitRealField(v, UNIT_RF_SCALING_VALUE);
			oriG.SetUnitScale(v, s,s,s);
			
			if GetUnitAbilityLevel(v, MagiLogNLoad.LOAD_GHOST_ID) > 0 then
				oriG.UnitRemoveAbility(v, MagiLogNLoad.LOAD_GHOST_ID);
			end
		end

		BlzSetUnitFacingEx(transp, oriFacing or 0);
	end

	local function ForceLoadUnits(transp, units)
		if transp == nil or IsUnitGone(transp) then
			PrintDebug('|cffff5500MLNL Error:ForceLoadUnits!', 'Invalid transport unit detected when trying to load!');
			return;
		end

		local oriCastRanges = {};
		for _,v in pairs(MagiLogNLoad.ALL_TRANSP_ABILS) do
			for _,abilid in ipairs(v) do
				local lvl = GetUnitAbilityLevel(transp, abilid);
				if lvl > 0 then
					local abil = BlzGetUnitAbility(transp, abilid);

					lvl = lvl-1;
					oriCastRanges[#oriCastRanges+1] = BlzGetAbilityRealLevelField(abil, ABILITY_RLF_CAST_RANGE, lvl)

					BlzSetAbilityRealLevelField(abil, ABILITY_RLF_CAST_RANGE, lvl, 99999999.);
					break;
				end
			end
		end

		local oriFacing = GetUnitFacing(transp);
		
		local transpX, transpY = GetUnitX(transp), GetUnitY(transp);
		local oriMoveSpeeds = {};

		for i,v in ipairs(units) do
			if v ~= 0 then
				oriMoveSpeeds[i] = GetUnitMoveSpeed(v);				
				oriG.SetUnitMoveSpeed(v, 0);
				
				if not unit2HiddenStat[v] then
					unit2HiddenStat[v] = {};
				end
				
				if not unit2HiddenStat[v].scale then
					unit2HiddenStat[v].scale = BlzGetUnitRealField(v, UNIT_RF_SCALING_VALUE)
				end
				oriG.SetUnitScale(v, 0,0,0);
				
				SetUnitX(v, transpX);
				SetUnitY(v, transpY);
				IssueTargetOrderById(v, BOARD_ORDER_ID, transp);
				BlzQueueTargetOrderById(v, BOARD_ORDER_ID, transp);
				BlzQueueTargetOrderById(v, BOARD_ORDER_ID, transp);
				BlzQueueTargetOrderById(v, BOARD_ORDER_ID, transp);
			end
		end

		onLaterTickFuncs[#onLaterTickFuncs+1] = {mainTick + 30, ResetTransportAfterLoad, {transp,  oriCastRanges, units, oriMoveSpeeds, oriFacing}};
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
		local Amrf_4CC = FourCC('Amrf');
		
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
	
	local function UnpackLogEntry(tab)
		local ans = {};
		local ansN = 0;
		for _,v in ipairs(tab) do
			if type(v) == 'table' then
				ansN = ansN + 1;
				ans[ansN] = #v == 1 and int2Function[v[1]]() or int2Function[v[1]](unpack(v[2]));
			else
				ansN = ansN + 1;
				ans[ansN] = v;
			end
		end

		return unpack(ans);
	end

	local function LoadItem(log)
		local entriesN = 0;
		local lastId = 0;
		for i,v in ipairs(log) do
			local curId = v[1];

			if lastId > curId then
				PrintDebug('|cffff5500MLNL Error:LoadItem!', 'Bad save-file detected while loading ITEM #',i,'!|r');
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

	local function LoadCreateItem(itemid, x, y, charges, pid)
		local item = CreateItem(itemid, x, y);

		if not item then
			PrintDebug('|cffff5500MLNL Error:LoadCreateItem!', 'Failed to create item with id:',FourCC2Str(itemid),'!|r');
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

	local function GetPreplacedUnit(...)
		return TableGetDeep(preplacedWidgets.unitMap, {...});
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

	local function LoadUnit(log)
		local entriesN = 0;
		local lastId = 0;
		for i,v in ipairs(log) do
			local curId = v[1];

			if lastId > curId then
				PrintDebug('|cffff5500MLNL Error:LoadUnit!', 'Bad save-file detected while loading UNIT #',i,'!|r');
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
	
	local function GetLoggingPlayer()
		return loggingPid > -1 and Player(loggingPid) or nil;
	end
	
	local function LoadRemoveUnit(u)
		if not u then
			PrintDebug('|cffff5500MLNL Error:LoadRemoveUnit!', 'Passed unit is nil!|r');
			return;
		end
		
		ShowUnit(u, true);
		RemoveUnit(u);
	end

	local function LoadCreateUnit(p, unitid, x, y, face)
		local u = CreateUnit(p, unitid, x, y, face);

		if not u then
			if GetLoggingPlayer() == GetLocalPlayer() then
				print('|cffff5500MLNL Error! Failed to create unit with id:',FourCC2Str(unitid),'!|r');
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
			PrintDebug('|cffff5500MLNL Error:LoadPreplacedUnit!', 'Failed to find pre-placed unit at (',prepX, prepY,
					'), id:', FourCC2Str(preplacedUId),'.|r|cffff9900Creating a new unit...|r');
			return LoadCreateUnit(p, preplacedUId, x, y, face);
		end
		--if not u then return nil end;

		logUnits[logUnitsN] = u;

		if GetPlayerId(p) ~= preplacedPId then
			SetUnitOwner(u, p);
		end

		local transp = unit2TransportHash[u];
		
		if transp and IsUnitLoaded(u) and not IsUnitGone(transp) then
			local abils = {};
			local j = 0;
			
			for _,v in pairs(MagiLogNLoad.ALL_TRANSP_ABILS) do
				for _,abilid in ipairs(v) do
					local lvl = GetUnitAbilityLevel(transp, abilid);
					if lvl > 0 then
						lvl = lvl -1;
						
						local abil = BlzGetUnitAbility(transp, abilid);
						
						j = j + 1;
						abils[j] = {
							abil,
							lvl,
							BlzGetAbilityRealLevelField(abil, ABILITY_RLF_AREA_OF_EFFECT, lvl),
							BlzGetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_HERO, lvl),
							BlzGetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_NORMAL, lvl)
						};
						
						BlzSetAbilityRealLevelField(abil, ABILITY_RLF_AREA_OF_EFFECT, lvl, 99999);
						BlzSetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_HERO, lvl, 0);
						BlzSetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_NORMAL, lvl, 0);
						break;
					end
				end
			end
			
			local transpX,transpY = GetUnitX(transp), GetUnitY(transp);
			
			UnitAddAbility(transp, MagiLogNLoad.UNLOAD_INSTA_ID);
			SetUnitPosition(transp, x, y);
			IssueImmediateOrderById(transp,UNLOAD_INSTA_ORDER_ID);
			SetUnitPosition(transp, transpX, transpY);
			UnitRemoveAbility(transp, MagiLogNLoad.UNLOAD_INSTA_ID);
			
			for i,obj in ipairs(abils) do
				local abil = obj[1];
				local lvl = obj[2];
				BlzSetAbilityRealLevelField(abil, ABILITY_RLF_AREA_OF_EFFECT, lvl, obj[3]);
				BlzSetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_HERO, lvl, obj[4]);
				BlzSetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_NORMAL, lvl, obj[5]);
			end
		end
		
		SetUnitX(u, x);
		SetUnitY(u, y);
		BlzSetUnitFacingEx(u, face);
		if GetUnitMoveSpeed(u) <= 0. then
			ShowUnit(u, false);
			ShowUnit(u, true);
		end
		
		return u;
	end

	local function LoadUnitAddItemToSlotById(u, itemid, slotid, charges)
		if not u then
			PrintDebug('|cffff5500MLNL Error:LoadUnitAddItemToSlotById!', 'Passed unit is nil!|r');
			return false;
		end
		
		local item = UnitItemInSlot(u, slotid);
		
		if item then
			if preplacedWidgets.items[item] then
				UnitRemoveItem(u, item);
			else
				RemoveItem(item);
			end
		end
		
		local v = UnitAddItemToSlotById(u, itemid, slotid);
		if not v then
			return false;
		end

		item = UnitItemInSlot(u, slotid);

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

	local function IsUnitSaveable(u, skipPreplacedCheck)
		--#PROD
		return (
			(skipPreplacedCheck or
				(
					MagiLogNLoad.modes.savePreplacedUnitsOfPlayer and 
					preplacedWidgets.units[u] and 
					GetUnitTypeId(u) == preplacedWidgets.units[u][3] 
				) or (
					MagiLogNLoad.modes.saveNewUnitsOfPlayer and 
					not preplacedWidgets.units[u] and 
					not (preplacedWidgets.units[unit2TransportHash[u]] and IsUnitLoaded(u))
				)
			) and
			not IsUnitGone(u) and
			not IsUnitType(u, UNIT_TYPE_SUMMONED)
		);
	end

	local function LogUnit(u, forceSaving, ownerId)
		if not IsUnitSaveable(u, forceSaving) then
			issuedWarningChecks.saveInPreplacedTransp = issuedWarningChecks.saveInPreplacedTransp or
				(not MagiLogNLoad.modes.savePreplacedUnitsOfPlayer and preplacedWidgets.units[unit2TransportHash[u]] and IsUnitLoaded(u));
				
			issuedWarningChecks.saveTransformedPreplacedUnit = issuedWarningChecks.saveTransformedPreplacedUnit or
				(MagiLogNLoad.modes.savePreplacedUnitsOfPlayer and preplacedWidgets.units[u] and GetUnitTypeId(u) ~= preplacedWidgets.units[u][3]);
				
			return false;
		end

		local uid = GetUnitTypeId(u);
		local float, x, y, tab, str;
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

		--Legacy
		--logEntries[fCodes.LogBaseStatsByType] = {2, fCodes.LogBaseStatsByType, {{fCodes.GetLoggingUnit}}};
		
		if IsUnitLoaded(u) and GetUnitAbilityLevel(u, MagiLogNLoad.LOAD_GHOST_ID) <= 0 then
			if logEntries[MagiLogNLoad.LOAD_GHOST_ID] == nil then
				logEntries[MagiLogNLoad.LOAD_GHOST_ID] = {};
			end

			logEntries[MagiLogNLoad.LOAD_GHOST_ID][fCodes.UnitAddAbility] = {3, fCodes.UnitAddAbility, {{fCodes.GetLoggingUnit}, MagiLogNLoad.LOAD_GHOST_ID}};
		end

		float = GetUnitFlyHeight(u);
		if float > 0.0 or float < 0 then
			logEntries[fCodes.LoadSetUnitFlyHeight] = {21, fCodes.LoadSetUnitFlyHeight, {{fCodes.GetLoggingUnit}, Round(float), 0}};

		end

		if UnitInventorySize(u) > 0 then
			for i=0,5 do
				local item = UnitItemInSlot(u, i);
				if item then
					if MagiLogNLoad.modes.savePreplacedItems and preplacedWidgets.items[item] then
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
			end
		end
		
		if unit2HiddenStat[u] and unit2HiddenStat[u].name then
			str = GetUnitName(u);
			if str ~= unit2HiddenStat[u].name then
				logEntries[fCodes.BlzSetUnitName] = {55, fCodes.BlzSetUnitName, {{fCodes.GetLoggingUnit}, {fCodes.utf8char, GetUTF8Codes(str)}}};
			end
		end
		
		if IsHeroUnitId(uid) then
			str = GetHeroProperName(u);
			if str and str ~= '' then
				logEntries[fCodes.BlzSetHeroProperName] = {61, fCodes.BlzSetHeroProperName, {{fCodes.GetLoggingUnit}, {fCodes.utf8char, GetUTF8Codes(str)}}};
			end

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

		issuedWarningChecks.saveInPreplacedTransp = false;
		issuedWarningChecks.saveTransformedPreplacedUnit = false;

		if MagiLogNLoad.modes.saveNewUnitsOfPlayer or MagiLogNLoad.modes.savePreplacedUnitsOfPlayer then
			GroupEnumUnitsOfPlayer(tempGroup, p, FilterEnumLogUnit);
		end

		if MagiLogNLoad.modes.saveUnitsDisownedByPlayers then
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

		if issuedWarningChecks.saveInPreplacedTransp then
			--#AZZY
			--print('|cffff9900MLNL Warning! Some units are loaded into the Roleplaying Circle and cannot be saved!|r');
			print('|cffff9900MLNL Warning! Some units are loaded into an unsaved transport and will not be saved!|r');
		end
		if issuedWarningChecks.saveTransformedPreplacedUnit then
			print('|cffff9900MLNL Warning! Some pre-placed units have been transformed and will not be saved!|r');
		end
		issuedWarningChecks.saveInPreplacedTransp = false;
		issuedWarningChecks.saveTransformedPreplacedUnit = false;
	end

	local function LoadPreplacedItem(x, y, charges, pid, prepItemId, prepSlot, prepX, prepY, prepUnitId, prepUnitOwnerId)
		local item = GetPreplacedItem(prepItemId, prepSlot, prepX, prepY, prepUnitId, prepUnitOwnerId);

		if not item then
			PrintDebug(
				'|cffff5500MLNL Error:LoadPreplacedItem!', 'Failed to find pre-placed item at with id:', FourCC2Str(prepItemId), 
				'! Creating identical item...|r'
			);
			return LoadCreateItem(prepItemId, x, y, charges, pid);
		end

		SetItemPosition(item, x, y);

		if GetItemCharges(item) ~= charges then
			SetItemCharges(item, charges);
		end

		magiLog.items[item] = {pid};
	end

	local function LogItemOnGround(item, pid, forceSaving)
		if not item or GetItemTypeId(item) == 0 or GetWidgetLife(item) <= 0. then return end;
		local itemEntry = magiLog.items[item];

		if (forceSaving or MagiLogNLoad.modes.savePreplacedItems or MagiLogNLoad.modes.saveAllItemsOnGround) and preplacedWidgets.items[item] then

			local tab = preplacedWidgets.items[item];

			logGen.items = logGen.items + 1;
			magiLog.itemsOfPlayer[pid][item] = { [fCodes.LoadPreplacedItem] = {logGen.items, fCodes.LoadPreplacedItem, {
				Round(GetItemX(item)), Round(GetItemY(item)), GetItemCharges(item), pid,
				tab[1], tab[2], tab[3] or 0, tab[4] or 0, tab[5], tab[6] or 0
			}}};

		elseif MagiLogNLoad.modes.saveAllItemsOnGround or (MagiLogNLoad.modes.saveItemsDroppedManually and itemEntry and itemEntry[1] == pid) then

			logGen.items = logGen.items + 1;
			magiLog.itemsOfPlayer[pid][item] = { [fCodes.LoadCreateItem] = {logGen.items, fCodes.LoadCreateItem, {
				GetItemTypeId(item), Round(GetItemX(item)), Round(GetItemY(item)), GetItemCharges(item), pid
			}}};

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

		if MagiLogNLoad.modes.savePreplacedItems then
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

		local table_sort = table.sort;

		local maxLen = MagiLogNLoad.MAX_UNITS_PER_FILE;
		local maxEntries = MagiLogNLoad.MAX_ENTRIES_PER_UNIT;
		local entriesN = 0;

		local ans = {};
		local ansN = 0;

		local u2i = {};
		local i2u = {};

		for u,v in pairs(log) do
			if ansN >= maxLen then
				print('|cffff9900MLNL Warning!', 'Your save-file has too many UNIT entries! Not all will be saved!|r');
				break;
			end

			local curAns = {};
			local curAnsN = 0;

			for k2,v2 in pairs(v) do
				--[[
				if k2 == fCodes.KillUnit and (not fCodeFilter or fCodeFilter[k2]) then
					local entry = v2;
					if GetUnitTypeId(u) == 0 then
						curAnsN = curAnsN + 1;
						curAns[curAnsN] = {v2[1], fCodes.LoadRemoveUnit, v2[3]};
					elseif IsUnitType(u, UNIT_TYPE_DEAD) then
						curAnsN = curAnsN + 1;
						curAns[curAnsN] = v2;
					end
				else]]
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
							if type(v3) ~= 'table' or next(v3) == nil then break end;
							check = false;

							if not fCodeFilter or fCodeFilter[v3[2]] then
								curAnsN = curAnsN + 1;
								curAns[curAnsN] = v3;
							end
						end
					end

					if check and type(v2) == 'table' and next(v2) ~= nil and (not fCodeFilter or fCodeFilter[v2[2]]) then
						curAnsN = curAnsN + 1;
						curAns[curAnsN] = v2;
					end
				end

				if curAnsN >= maxEntries then
					print('|cffff9900MLNL Warning!', 'Some UNITS have too much data! Not all will be saved!|r');
					break;
				end
			end

			if curAnsN > 0 then
				if curAnsN > 1 then
					table_sort(curAns, SortLog);
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

			if IsUnitLoaded(u) and not IsUnitGone(transp) and (MagiLogNLoad.modes.savePreplacedUnitsOfPlayer or not preplacedWidgets.units[transp]) then
				local hash = transport2UnitsHash[transp];
				hash[#hash+1] = u;
			else
				unit2TransportHash[u] = nil;
			end
		end

		local lastInd = #ans;
		for transp, units in pairs(transport2UnitsHash) do
			local ind = u2i[transp];
			if ind and #units > 0 then
				ans[ind], ans[lastInd], u2i[transp], u2i[i2u[lastInd]], i2u[ind], i2u[lastInd] = ans[lastInd], ans[ind], lastInd, ind, i2u[lastInd], i2u[ind];

				lastInd = lastInd - 1;

				ind = u2i[transp];
				local curLog = ans[ind];

				curLog[#curLog+1] = {200, fCodes.ForceLoadUnits, {
					{fCodes.GetLoggingUnit, {ind}}, {fCodes.GetLoggingUnitsSafe0, Map(units, function(v) return u2i[v] or -1 end)}
				}};
				entriesN = entriesN + 1;
			end
		end

		for i,v in ipairs(ans) do
			v[#v+1] = i2u[i];
		end

		-- Maybe it helps untangle the GC?
		u2i = nil;
		i2u = nil;

		return {ans, 'unit', {entriesN, ansN}};
	end

	local function CompileDestrsLog(log, fCodeFilter)
		if not log then return {{}, 'destructable', {0,0}} end;
		local table_sort = table.sort;

		local maxLen = MagiLogNLoad.MAX_DESTRS_PER_FILE;
		local maxEntries = MagiLogNLoad.MAX_ENTRIES_PER_DESTR;
		local entriesN = 0;

		local ans = {};
		local ansN = 0;

		for destr, v in pairs(log) do
			if v[fCodes.LoadCreateDestructable] or MagiLogNLoad.modes.saveStandingPreplacedDestrs then
				local curAns = {};
				local curAnsN = 0;

				if ansN >= maxLen then
					print('|cffff9900MLNL Warning!', 'Your save-file has too many DESTRUCTABLE entries! Not all will be saved!|r');
					break;
				end

				for _,v2 in pairs(v) do
					if type(v2) == 'table' and next(v2) ~= nil and (not fCodeFilter or fCodeFilter[v2[2]]) then
						curAnsN = curAnsN + 1;
						curAns[curAnsN] = v2;

						if curAnsN >= maxEntries then
							print('|cffff9900MLNL Warning!', 'Some DESTRUCTABLES have too much data! Not all of it will be saved!|r');
							break;
						end
					end
				end

				if curAnsN > 0 then
					if curAnsN > 1 then
						table_sort(curAns, SortLog);
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

		local table_sort = table.sort;

		local maxLen = MagiLogNLoad.MAX_ITEMS_PER_FILE;
		local maxEntries = MagiLogNLoad.MAX_ENTRIES_PER_ITEM;
		local entriesN = 0;

		local ans = {};
		local ansN = 0;

		for item, v in pairs(log) do
			local curAns = {};
			local curAnsN = 0;

			if ansN >= maxLen then
				print('|cffff9900MLNL Warning!', 'Your save-file has too many ITEM entries! Not all will be saved!|r');
				break;
			end

			for _,v2 in pairs(v) do
				if type(v2) == 'table' and next(v2) ~= nil and (not fCodeFilter or fCodeFilter[v2[2]]) then
					curAnsN = curAnsN + 1;
					curAns[curAnsN] = v2;

					if curAnsN >= maxEntries then
						print('|cffff9900MLNL Warning!', 'Some ITEMS have too much data! Not all of it will be saved!|r');
						break;
					end
				end
			end


			if curAnsN > 0 then
				if curAnsN > 1 then
					table_sort(curAns, SortLog);
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
			if type(v) == 'table' and next(v) ~= nil and (not fCodeFilter or fCodeFilter[v[2]]) then
				ansN = ansN + 1;
				ans[ansN] = v;

				if ansN >= maxLen then
					print('|cffff9900MLNL Warning!', 'Your save-file has too many TERRAIN entries! Not all will be saved!|r');
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
			if type(v) == 'table' and next(v) ~= nil and (not fCodeFilter or fCodeFilter[v[2]]) then
				ansN = ansN + 1;
				ans[ansN] = v;

				if ansN >= maxLen then
					print('|cffff9900MLNL Warning!', 'Your save-file has too many RESEARCH entries! Not all will be saved!|r');
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
				if type(entry) == 'table' and next(entry) ~= nil and (not fCodeFilter or fCodeFilter[entry[2]]) then
					ansN = ansN + 1;
					ans[ansN] = entry;

					if ansN >= maxLen then
						print('|cffff9900MLNL Warning!', 'Your save-file has too many EXTRA entries! Not all will be saved!|r');
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
			return 	(val > 2147483647 or val < -2147483647) and {fCodes.UTF8Codes2Real, GetUTF8Codes(tostring(val))} or
					(val == math_floor(val) or val > 2147483647/10000. or val < -2147483647/10000.) and Round(val) or 
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

		PrintDebug('|cffff9900MLNL Warning:Handle2LogGetter!', 'Cannot create getter for value of type',valType,'!|r');
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
									PrintDebug('|cffff9900MLNL Warning:CompileProxyTablesLog!', 'Your save-file has too many PROXY TABLE entries! Not all will be saved!|r');
									breakCheck = true;
									break;
								end
							end

						elseif warningCheck then
							warningCheck = false;
							PrintDebug('|cffff9900MLNL Warning:CompileProxyTablesLog!', 'Some key getters are nil and will be skipped!|r');
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
										PrintDebug('|cffff9900MLNL Warning:CompileHashtablesLog!', 'Your save-file has too many PROXY TABLE entries! Not all will be saved!|r');
										breakCheck = true;
										break;
									end
								end

							elseif warningCheck then
								warningCheck = false;
								PrintDebug('|cffff5500MLNL Error:CompileHashtablesLog!', 'Some key getters are nil and will be skipped!|r');
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
					PrintDebug('|cffff9900MLNL Warning:CompileVarsLog!', 'Your save-file has too many VARIABLE entries! Not all will be saved!|r');
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

		local manifest = {MagiLogNLoad.engineVersion, Map(PluckArray(fullLog, 2), function(v) return word2CodeHash[v] or 0 end)};

		fullLog = PluckArray(fullLog, 1);

		TrimLogs(fullLog);

		fullLog = {manifest, fullLog};

		local str = SerializeIntTable(fullLog);

		magiLog.unitsOfPlayer[pid] = nil;
		magiLog.itemsOfPlayer[pid] = nil;

		return str, tally;
	end

	function MagiLogNLoad.TryLoadNextInQueue()
		if downloadingStreamFrom == nil and #loadingQueue > 0 then
			local queued = loadingQueue[1];
			if queued then
				remove(loadingQueue, 1);
				if queued[1] == GetLocalPlayer() then
					MagiLogNLoad.SyncLocalSaveFile(queued[2]);
				end
				return true;
			end
		end
		return false;
	end


	local function AbortCurrentLoading()
		if downloadingStreamFrom then
			local stream = streamsOfPlayer[GetPlayerId(downloadingStreamFrom)];
			stream = stream and stream[logGen.streams] or nil;
			if stream then
				stream.aborted = true;
			end
		end
		downloadingStreamFrom = nil;
		uploadingStream = nil;
	end

	local function CheckLoadingProg()
		if not downloadingStreamFrom then return end;

		local stream = streamsOfPlayer[GetPlayerId(downloadingStreamFrom)];
		stream = stream and stream[logGen.streams] or nil;

		if not stream or stream.aborted or not stream.streamStartTick then return end;

		local streamStartTick = stream.streamStartTick;

		local loadingTime = (mainTick - streamStartTick)*TICK_DUR;
		if not issuedWarningChecks.loadTimeWarning and
			MagiLogNLoad.LOADING_TIME_SECONDS_TO_WARNING > 0 and
			loadingTime > MagiLogNLoad.LOADING_TIME_SECONDS_TO_WARNING then

				issuedWarningChecks.loadTimeWarning = true;
				print('|cffff9900MLNL Warning! The current save-file loading has lasted for more than', MagiLogNLoad.LOADING_TIME_SECONDS_TO_WARNING, 'seconds!|r');
				if MagiLogNLoad.LOADING_TIME_SECONDS_TO_WARNING < MagiLogNLoad.LOADING_TIME_SECONDS_TO_ABORT then
					print(
						'|cffff9900It will be aborted in',
						MagiLogNLoad.LOADING_TIME_SECONDS_TO_ABORT - MagiLogNLoad.LOADING_TIME_SECONDS_TO_WARNING,
						'seconds from now!|r'
					);
				end

		elseif loadingTime > MagiLogNLoad.LOADING_TIME_SECONDS_TO_ABORT then

			AbortCurrentLoading();
			print('|cffff5500The current save-file loading has been aborted!|r');

		elseif mainTick - stream.streamLastTick > 250 then

			AbortCurrentLoading();
			print('|cffff5500The currently loading save-file appears to have stalled and has been aborted!|r');

		end
	end

	local function ResetReferencedLogging(entry)
		if not logEntry2ReferencedHash[entry] then return end;

		for k,v in pairs(logEntry2ReferencedHash[entry]) do
			v[k] = nil;
		end

		logEntry2ReferencedHash[entry] = nil;
	end

	local function TimerTick()
		mainTick = mainTick + 1;

		local localPid = GetPlayerId(GetLocalPlayer());
		if MagiLogNLoad.stateOfPlayer[localPid] ~= MagiLogNLoad.BASE_STATES.STANDBY then
			local state = MagiLogNLoad.stateOfPlayer[localPid];

			if state == MagiLogNLoad.BASE_STATES.OFF and not issuedWarningChecks.initPanic then

				print('|cffff5500MLNL Error! Something went horribly wrong while MagiLogNLoad was initializing!|r');
				print('|cffff5500Please find |r|cffaaff00@ModdieMads|r|cffff5500 and report this error code:|r|cffaaff00', 'BASE_STATES',state,'!|r');
				issuedWarningChecks.initPanic = true;

			elseif state == MagiLogNLoad.BASE_STATES.CLEANING_TABLES and not issuedWarningChecks.tabKeyCleanerPanic then

				print('|cffff9900MLNL Warning! Something went mildly wrong while cleaning up memory in MagiLogNLoad!|r');
				print('|cffff5500Please find |r|cffaaff00@ModdieMads|r|cffff5500 and report this error code:|r|cffaaff00', 'BASE_STATES',state,'!|r');
				issuedWarningChecks.tabKeyCleanerPanic = true;

			end

			MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;

			if MagiLogNLoad.SAVE_STATES.HASH[state] then
				print('|cffff5500MLNL Error! Something went horribly wrong while trying to create a save-file!|r');
				print('|cffff5500Please find |r|cffaaff00@ModdieMads|r|cffff5500 and report this error code:|r|cffaaff00', 'SAVE_STATES',state,'!|r');
				local dumpFileName = MagiLogNLoad.SAVE_FOLDER_PATH .. 'magilognload_dump.pld';
				print('|cffff9900Trying to dump data into', dumpFileName, '!|r');

				FileIO.SaveFile(dumpFileName, '--SAVE_STATES '..state..'..\r\n'..TableToConsole({
					['proxyTablesOfPlayer']=magiLog.proxyTablesOfPlayer[localPid],
					['hashtablesOfPlayer']=magiLog.hashtablesOfPlayer[localPid],
					['unitsOfPlayer']=magiLog.unitsOfPlayer[localPid],
					['referencedUnitsOfPlayer']=magiLog.referencedUnitsOfPlayer[localPid],
					['destrsOfPlayer']=magiLog.destrsOfPlayer[localPid],
					['referencedDestrsOfPlayer']=magiLog.referencedDestrsOfPlayer[localPid],
					['itemsOfPlayer']=magiLog.itemsOfPlayer[localPid],
					['referencedItemsOfPlayer']=magiLog.referencedItemsOfPlayer[localPid]
				}));

				print('|cffaaaaaaDid it work? I think it did... Done!|r');

			elseif MagiLogNLoad.LOAD_STATES.HASH[state] then

				print('|cffff5500MLNL Error! Something went horribly wrong while trying to load a save-file!|r');
				print('|cffff5500Please find |r|cffaaff00@ModdieMads|r|cffff5500 and report this error code:|r|cffaaff00', 'LOAD_STATES',state,'!|r');

			end
		end

		local len = #onLaterTickFuncs;

		if len > 0 then
			local i = 1;
			while i <= len do
				local fobj = onLaterTickFuncs[i];
				if mainTick >= fobj[1] then
					remove(onLaterTickFuncs,i);
					i = i-1;
					len = len-1;

					if fobj[3] then
						fobj[2](unpack(fobj[3]));
						fobj[3] = nil;
					else
						fobj[2]();
					end
				end
				i = i+1;
			end
		end

		CheckLoadingProg();

		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.LOAD_STATES.SEND_SYNC_DATA;
		if uploadingStream then
			local msgsN = uploadingStream.messagesN;
			local msgsSent = uploadingStream.messagesSent;
			if msgsSent < msgsN then
				local nextMsg = uploadingStream.messagesSent + 1;

				for n=1,(uploadingStream.chunksSynced > 2 and 50 or 1) do
					if not BlzSendSyncData('MLNL', uploadingStream.messages[nextMsg]) then
						break;
					end

					uploadingStream.messagesSent = nextMsg;
					nextMsg = nextMsg+1;

					if nextMsg > msgsN then
						break;
					end
				end
			end
		end

		MagiLogNLoad.TryLoadNextInQueue();

		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.CLEANING_TABLES;
		--#DEBUG
		if (mainTick&1023) == 0 then
			local tab = tabKeyCleaner[((mainTick >> 10)&tabKeyCleanerSize)+1];
			if tab then
				if tab.arr then
					local ind = (mainTick >> 10)&31;

					if ind == 31 then lastCleanedTab = nil end;

					local innerTab = nil;
					repeat
						ind = ind + 1;
						innerTab = tab.arr[ind];
					until innerTab ~= nil or ind >= 31;

					if innerTab and lastCleanedTab ~= innerTab and next(innerTab) then
						lastCleanedTab = innerTab;

						if tab.referenceLogger then
							for refName,v in pairs(innerTab) do
								for ref,v2 in pairs(v) do
									if _G[refName] ~= ref then
										ResetReferencedLogging(v2);
										v[ref] = nil;
									end
								end
							end
						else
							local typeIdFunc = typeStr2TypeIdGetter[GetHandleTypeStr(next(innerTab))];
							local chk = tab.chk;
							local willClean = true;
							for k,v in pairs(innerTab) do
								if typeIdFunc(k) == 0 then
									if chk then
										for _,code in ipairs(chk) do
											if v[code] then
												willClean = false;
												break;
											end
										end
									end
									if willClean then
										innerTab[k] = nil;
									end
								end
							end
						end
					end
				else
					local map;
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
								if map then
									TableSetDeep(map, nil, v);
								end
							end
						end
					end
				end
			end
		end

		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
		signals.abortLoop = nil;
	end

	local function LoadTerrainLog(log)
		local lastId = 0;
		local entriesN = 0;
		for i,v in ipairs(log) do
			local curId = v[1];

			if lastId > curId then
				PrintDebug('|cffff5500MLNL Error:LoadTerrainLog!', 'Bad save-file detected while loading TERRAIN entry #',i,'!|r');
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
				PrintDebug('|cffff5500MLNL Error:LoadResearchLog!', 'Bad save-file detected while loading RESEARCH entry #',i,'!|r');
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
				PrintDebug('|cffff5500MLNL Error:LoadExtrasLog!', 'Bad save-file detected while loading EXTRAS entry #',i,'!|r');
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
				PrintDebug('|cffff5500MLNL Error:LoadDestr!', 'Bad save-file detected while loading DESTRUCTABLE #',i,'!|r');
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
		local unitsN, unitEntriesN = 0, 0;

		for i,v in ipairs(log) do
			unitsN = unitsN + 1;
			logUnitsN = logUnitsN + 1;

			unitEntriesN = unitEntriesN + LoadUnit(v);
		end

		return {unitEntriesN, unitsN};
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
				PrintDebug('|cffff5500MLNL Error:LoadProxyTablesLog!', 'Bad save-file detected while loading PROXY TABLE entry #',i,'!|r');
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
				PrintDebug('|cffff5500MLNL Error:LoadHashtablesLog!', 'Bad save-file detected while loading HASHTABLE entry #',i,'!|r');
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
				PrintDebug('|cffff5500MLNL Error:LoadVarsLog!', 'Bad save-file detected while loading VARIABLE entry #',i,'!|r');
				return false;
			end

			lastId = curId;

			int2Function[v[2]](UnpackLogEntry(v[3]));
			entriesN = entriesN + 1;
		end

		return {entriesN,0};
	end

	local function PrintTally(totalTime, tally, prefix)
		if totalTime then
			print('Total '..prefix..'ing Time:', totalTime, 'seconds.');
		end
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
			PrintDebug('|cffff5500MLNL Error:LoadCreateDestructable!', 'Failed to create destructable with id:',FourCC2Str(destrid),'!|r');
			signals.abortLoop = LoadDestr;
			return nil;
		end

		logDestrs[logDestrsN] = destr;

		return destr;
	end

	--#AZZY2

	function MagiLogNLoad.LoadPlayerSaveFromString(p, argStr, startTime)
		local pid = GetPlayerId(p);
		local localPid = GetPlayerId(GetLocalPlayer());

		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.LOAD_STATES.LOAD_SAVE_FROM_STRING;

		downloadingStreamFrom = nil;

		--#PROD
		local str = LibDeflate.DecompressDeflate(COBSDescape(argStr));

		if not str then
			print('|cffff5500MLNL Error!', 'Bad save-file! Cannot decompress.|r');
			MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
			return false;
		end

		--#DEBUG
		if MagiLogNLoad.modes.debug then
			FileIO.SaveFile('mlnl_debug.pld', str);
		end

		str = str:gsub(sanitizer, '');

		if not str then
			print('|cffff5500MLNL Error!', 'Bad save-file! Aborting loading...|r');
			MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
			return false;
		end

		if MagiLogNLoad.oldTypeId2NewTypeId and next(MagiLogNLoad.oldTypeId2NewTypeId) then
			PrintDebug('|cffff9900MLNL Warning:MagiLogNLoad.LoadPlayerSaveFromString!', 'Replacing old type ids with new ones in MagiLogNLoad.oldTypeId2NewTypeId...|r');

			str = str:gsub(PERC..'-?'..PERC..'d+', MagiLogNLoad.oldTypeId2NewTypeId);
		end

		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.LOAD_STATES.DESERIALIZE;
		local logs = Deserialize(str);

		if not logs then
			print('|cffff5500MLNL Error!', 'Bad save-file! Cannot deserialize.|r');
			MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
			return false;
		end

		--#AZZY1

		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.LOAD_STATES.GETTING_MANIFESTS;
		local manifest = logs[1];
		if not manifest then
			print('|cffff5500MLNL Error!', 'Bad save-file! Manifest is missing.|r');
			MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
			return false;
		end

		if not manifest[1] or manifest[1] < MagiLogNLoad.engineVersion then
			PrintDebug('|cffff9900MLNL Warning:MagiLogNLoad.LoadPlayerSaveFromString!', 'Outdated save-file version detected! Trying to load it anyway...|r');
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

		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.LOAD_STATES.LOADING_LOGS;
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

		print('|cffffcc00Loading is done!|r |cffaaaaaaMagiLogNLoad is cooling down and collecting reports...|r');
		local totalTime = startTime and os.clock() - startTime or nil;
		onLaterTickFuncs[#onLaterTickFuncs+1] = {mainTick + 100,
			function()
				downloadingStreamFrom = nil;
				MagiLogNLoad.stateOfPlayer[pid] = MagiLogNLoad.LOAD_STATES.SUCCESFUL_LOADING;

				local localPid = GetPlayerId(GetLocalPlayer());

				if MagiLogNLoad.onLoadFinished then
					MagiLogNLoad.onLoadFinished(p);
				end
				
				if MagiLogNLoad.willPrintTallyNext then
					MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.LOAD_STATES.PRINT_TALLY;
					PrintTally(totalTime, tally, 'Load');
					MagiLogNLoad.willPrintTallyNext = false;
				end

				MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
			end
		};

		playerLoadInfo[loggingPid].count = playerLoadInfo[loggingPid].count - 1;
		loggingPid = oldLoggingPId;

		downloadingStreamFrom = p;

		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
		return true;
	end
	
	function MagiLogNLoad.SaveLocalPlayer()
		print(
			'|cffff5500MLNL Error! MagiLogNLoad.SaveLocalPlayer has been deprecated!',
			'Please use MagiLogNLoad.CreatePlayerSaveFile instead.|r'
		);
	end

	function MagiLogNLoad.CreatePlayerSaveFile(p, fileName)
		local lp = GetLocalPlayer();
		local localPid = GetPlayerId(lp);
		
		if not p then
			PrintDebug('|cffff5500MLNL Error:MagiLogNLoad.CreatePlayerSaveFile!', 'Passed player <p> argument is nil!|r');
			
			return false;
		end
		
		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.SAVE_STATES.CREATE_PLAYER_SAVEFILE;
		
		fileName = fileName:gsub(fileNameSanitizer, '');
		if fileName == nil or #fileName < 1 or #fileName > 250 or (fileName:sub(1,1)):find(PERC..'a') == nil then
			if p == lp then
				print('|cffff5500MLNL Error! <|r',fileName, '|cffff5500> is not a valid save-file name!|r');
			end
			
			MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
			return false;
		end
		if fileName:sub(-4,-1) ~= '.pld' then
			fileName = fileName..'.pld';
		end
		
		if MagiLogNLoad.onSaveStarted and MagiLogNLoad.onSaveStarted(p, fileName) == false then 
			MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
			return false;
		end
		
		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.SAVE_STATES.UPDATE_SAVEABLE_VARS;

		MagiLogNLoad.UpdateSaveableVarsForPlayerId(GetPlayerId(p));
		
		if lp == p then
			local t0 = os.clock();
			fileName = MagiLogNLoad.SAVE_FOLDER_PATH .. fileName;
			
			MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.SAVE_STATES.CREATE_UNITS_OF_PLAYER_LOG;
			CreateUnitsOfPlayerLog(p);

			MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.SAVE_STATES.CREATE_ITEMS_OF_PLAYER_LOG;
			CreateItemsOfPlayerLog(p);

			MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.SAVE_STATES.CREATE_EXTRAS_OF_PLAYER_LOG;
			CreateExtrasOfPlayerLog(p);

			MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.SAVE_STATES.CREATE_SERIAL_LOGS;
			local logs, tally = CreateSerialLogs(p);

			--#PROD
			MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.SAVE_STATES.COMPRESSING_LOGS;

			local str = String2SafeUTF8(COBSEscape(LibDeflate.CompressDeflate(logs)));

			MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.SAVE_STATES.FILE_IO_SAVE_FILE;
			FileIO.SaveFile(fileName, str);
			
			if MagiLogNLoad.onSaveFinished then
				MagiLogNLoad.onSaveFinished(p, fileName);
				if MagiLogNLoad.willPrintTallyNext then
					MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.SAVE_STATES.PRINT_TALLY;
					PrintTally(os.clock() - t0, tally, 'Sav');
					MagiLogNLoad.willPrintTallyNext = false;
				end
			end
		end
		
		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
		
		return true;
	end

	function MagiLogNLoad.SyncLocalSaveFile(fileName)
		local localPid = GetPlayerId(GetLocalPlayer());

		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.LOAD_STATES.SYNC_LOCAL_SAVE_FILE;

		fileName = fileName:gsub(fileNameSanitizer, '');
		if fileName:sub(-4,-1) ~= '.pld' then
			fileName = fileName..'.pld';
		end

		local filePath = MagiLogNLoad.SAVE_FOLDER_PATH .. fileName;

		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.LOAD_STATES.SETTING_START_OSCLOCK;
		local startTime = os.clock();
		issuedWarningChecks.loadTimeWarning = false;
		if MagiLogNLoad.onSyncProgressCheckpoint then
			issuedWarningChecks.syncProgressCheckpoints = {};
		end

		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.LOAD_STATES.FILE_IO_LOAD_FILE;
		local logStr = FileIO.LoadFile(filePath);

		if not logStr then
			print('|cffff5500MLNL Error!','Missing save-file or unable to read it! Path:|r',filePath);
			MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
			return false;
		end

		--#PROD
		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.LOAD_STATES.GET_LOG_STR;
		logStr = string_char(unpack(GetCharCodesFromUTF8(logStr)));

		local logStrLen = #logStr;

		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.LOAD_STATES.CREATE_UPLOADING_STREAM;
		local tally = streamsOfPlayer[localPid];
		if not tally then
			tally = {};
			streamsOfPlayer[localPid] = tally;
		end

		logGen.streams = logGen.streams + 1;
		uploadingStream = {
			localFileName = fileName,
			--chunksN = 0,
			--chunksSynced = 0,
			localChunks = {},
			messages = {},
			--messagesN = 0,
			--messagesSent = 0,

			startTime = startTime,
			streamStartTick = mainTick,
			streamLastTick = mainTick
		};
		tally[logGen.streams] = uploadingStream;

		local arr = tally[logGen.streams].messages;
		local arrN = 0;
		local ind0 = 1;
		local ind1 = 1;

		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.LOAD_STATES.CREATE_MESSAGES;
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

		uploadingStream.chunksN = arrN;
		uploadingStream.chunksSynced = 0;
		uploadingStream.messagesN = arrN;
		uploadingStream.messagesSent = 0;

		MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
		return true;
	end

	function MagiLogNLoad.QueuePlayerLoadCommand(p, fileName)
		if downloadingStreamFrom == p then
			if p == GetLocalPlayer() then
				print('|cffff5500MLNL Error! You are already loading a save-file!|r');
			end
			return;
		end

		local ind = ArrayIndexOfPlucked(loadingQueue, p, 1);
		loadingQueue[ind == -1 and (#loadingQueue+1) or ind] = {p, fileName};
		if p == GetLocalPlayer() then
			print('|cffffdd00Another player is currently loading a save-file!|r');
			print('|cffffdd00Please wait! Your save-file|r', fileName,'|cffffdd00will soon load automatically.|r');
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

				if log[name] then
					ResetReferencedLogging(log[name]);
				end
				log[name] = nil;
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
		end));

		trig = CreateTrigger();
		TriggerRegisterAnyUnitEventBJ(trig, EVENT_PLAYER_UNIT_DROP_ITEM);
		TriggerAddAction(trig, (function()

			local item = GetManipulatedItem();

			local log = magiLog.items;

			log[item] = {GetPlayerId(GetOwningPlayer(GetManipulatingUnit()))};
		end));

		trig = CreateTrigger();
		TriggerRegisterAnyUnitEventBJ(trig, EVENT_PLAYER_UNIT_RESEARCH_FINISH);
		TriggerAddAction(trig, (function()
			local resId = GetResearched();

			if resId == 0 then return end;

			local pid = GetPlayerId(GetOwningPlayer(GetResearchingUnit()));

			local log = magiLog.researchOfPlayer[pid];

			if not log then
				log = {};
				magiLog.researchOfPlayer[pid] = log;
			end

			logGen.res = logGen.res + 1;
			log[logGen.res] = {logGen.res, fCodes.AddPlayerTechResearched, {{fCodes.GetLoggingPlayer}, resId, 1}};

		end));


		if MagiLogNLoad.SAVE_CMD_PREFIX and MagiLogNLoad.SAVE_CMD_PREFIX ~= '' then
			trig = CreateTrigger();
			for i=0,bj_MAX_PLAYER_SLOTS-1 do
				TriggerRegisterPlayerChatEvent(trig, Player(i), MagiLogNLoad.SAVE_CMD_PREFIX..' ', false);
			end
			TriggerAddAction(trig, function()
				local p = GetTriggerPlayer();
				local pid = GetPlayerId(p);
				local localPid = GetPlayerId(GetLocalPlayer());

				MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.SAVE_STATES.SAVE_CMD_ENTERED;

				local fileName = GetEventPlayerChatString();
				
				MagiLogNLoad.CreatePlayerSaveFile(p, StringTrim(fileName:sub(fileName:find(' ')+1, -1)):gsub(fileNameSanitizer, ''));
				
				MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
			end);
		end
		
		if MagiLogNLoad.LOAD_CMD_PREFIX and MagiLogNLoad.LOAD_CMD_PREFIX ~= '' then
			trig = CreateTrigger();
			for i=0,bj_MAX_PLAYER_SLOTS-1 do
				TriggerRegisterPlayerChatEvent(trig, Player(i), MagiLogNLoad.LOAD_CMD_PREFIX..' ', false);
			end
			TriggerAddAction(trig, (function()
				local p = GetTriggerPlayer();
				local pid = GetPlayerId(p);
				local localPid = GetPlayerId(GetLocalPlayer());

				MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.LOAD_STATES.LOAD_CMD_ENTERED;

				if playerLoadInfo[pid].count <= 0 then
					if p == GetLocalPlayer() and MagiLogNLoad.onMaxLoadsError then
						MagiLogNLoad.onMaxLoadsError(p);
					end
					MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
					return;
				end
				
				local fileName = GetEventPlayerChatString();
				fileName = StringTrim(fileName:sub(fileName:find(' ')+1, -1));

				if p == GetLocalPlayer() and playerLoadInfo[pid].fileNameHash[fileName] and MagiLogNLoad.onAlreadyLoadedWarning then
					MagiLogNLoad.onAlreadyLoadedWarning(p, fileName);
				end

				if p == GetLocalPlayer() then
					if downloadingStreamFrom then
						MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.LOAD_STATES.QUEUE_LOAD;

						MagiLogNLoad.QueuePlayerLoadCommand(p, fileName);

						MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
						return;
					end

					MagiLogNLoad.SyncLocalSaveFile(fileName);
				end
				MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
			end));
		end
		
		trig = CreateTrigger();
		for i=0,bj_MAX_PLAYER_SLOTS-1 do
			TriggerRegisterPlayerChatEvent(trig, Player(i), '-credits', true);
		end
		TriggerAddAction(trig, (function()
			if GetTriggerPlayer() == GetLocalPlayer() then
				print('|cffffdd00:: MagiLogNLoad v1.1 by ModdieMads. Get it at HiveWorkshop.com!|r');
				print('::>> Generously commissioned by the folks @ AzerothRoleplay!');
			end
		end));

		trig = CreateTrigger()
        for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
            BlzTriggerRegisterPlayerSyncEvent(trig, Player(i), 'MLNL', false);
        end
        TriggerAddAction(trig, function()
			local p = GetTriggerPlayer();
			local pid = GetPlayerId(p);
			local localPid = GetPlayerId(GetLocalPlayer());

			MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.LOAD_STATES.SYNC_EVENT;

			local str = BlzGetTriggerSyncData();

			local streamId = string_byte(str, 1, 1);
			if streamId > logGen.streams then
				logGen.streams = streamId;
			end

			local stream = streamsOfPlayer[pid];

			if stream and stream[streamId] and stream[streamId].aborted then
				PrintDebug('|cffff9900MLNL Warning:PlayerSyncEvent!','Message received from aborted stream!|r');

				MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
				return;
			elseif not downloadingStreamFrom then
				
				if MagiLogNLoad.onLoadStarted and MagiLogNLoad.onLoadStarted(p) == false then
					MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
					return;
				end
			elseif downloadingStreamFrom ~= p then
				if p == GetLocalPlayer() and uploadingStream then
					print('|cffff5500MLNL Error! You have jammed the network!|r');

					MagiLogNLoad.QueuePlayerLoadCommand(p, uploadingStream.localFileName);
					uploadingStream = nil;
				end

				MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
				return;
			end

			downloadingStreamFrom = p;

			local chunkId = Concat7BitPair(string_byte(str, 2, 3));

			local chunksN = Concat7BitPair(string_byte(str, 4, 5));

			if not stream then
				stream = {};
				streamsOfPlayer[pid] = stream;
			end

			if not stream[streamId] then
				stream[streamId] = {
					chunksN = chunksN,
					chunksSynced = 0,
					localChunks = {},
					streamStartTick = mainTick
				};
			end
			stream = stream[streamId];
			stream.streamLastTick = mainTick;

			stream.localChunks[chunkId] = str:sub(6, #str);
			stream.chunksSynced = stream.chunksSynced + 1;
			--stream.chunksN = stream.chunksN - 1;

			if stream.chunksSynced >= stream.chunksN then
				str = concat(stream.localChunks);
				stream.localChunks = {};

				local startTime;
				if uploadingStream then
					startTime = uploadingStream.startTime;
					playerLoadInfo[pid].fileNameHash[uploadingStream.localFileName] = true;
					uploadingStream = nil;
				end

				MagiLogNLoad.LoadPlayerSaveFromString(p, str, startTime);
				return;
			elseif MagiLogNLoad.onSyncProgressCheckpoint then
				MagiLogNLoad.onSyncProgressCheckpoint(math_floor(100*stream.chunksSynced/stream.chunksN),issuedWarningChecks.syncProgressCheckpoints);
			end
			
			MagiLogNLoad.stateOfPlayer[localPid] = MagiLogNLoad.BASE_STATES.STANDBY;
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
					for i2=0,5 do
						local item = UnitItemInSlot(u, i2);
						if item then
							preplacedWidgets.items[item] = {GetItemTypeId(item), i2, unpack(params)};
						end
					end
				end
				return false;
			end));
        end

		EnumItemsInRect(WORLD_BOUNDS.rect, nil, function()
			local item = GetEnumItem();
			local params = {GetItemTypeId(item), -1, Round(GetItemX(item)), Round(GetItemY(item))};
			preplacedWidgets.items[item] = params;
			TableSetDeep(preplacedWidgets.itemMap, item, params);
		end);
	end



	local function SaveIntoNamedVar(varName, val)
		if varName == nil then
			PrintDebug('|cffff5500MLNL Error:SaveIntoNamedVar!', 'Variable name is NIL!|r');
			return;
		end
		_G[varName] = val;
	end

	-- Proxy tables are expected to NOT have their metatables changed outside of this system.
	-- Proxy tables save changes made to them on an individual basis.
	-- This allows for only some changes to be saved, or for changes to be saved differently for each player.
	local function MakeProxyTable(argName, willSaveChanges)
		if argName == nil then
			PrintDebug('|cffff5500MLNL Error:MakeProxyTable!','Name passed to MakeProxyTable is NIL!|r');
			return false;
		end
		if type(argName) ~= 'string' then
			PrintDebug('|cffff5500MLNL Error:MakeProxyTable!','Name passed to MakeProxyTable must be a string! It is of type:', type(argName),'!|r');
			return false;
		end

		local varName = argName;
		local var = _G[varName];
		if var == nil then
			varName = 'udg_'..argName;
			var = _G[varName];
			if var == nil or type(var) ~= 'table' then
				PrintDebug('|cffff5500MLNL Error:MakeProxyTable!','Name passed must be the name of a GUI Array or Table-type variable!|r');
				return false;
			end
		end

		if varName2ProxyTableHash[varName] == nil then
			local mt = getmetatable(var);
			if mt and (mt.__newindex or mt.__index) then
				PrintDebug('|cffff9900MLNL Warning:MakeProxyTable!', 'Metatable of', varName, 'is being overwritten to make it saveable!|r');
			end

			varName2ProxyTableHash[varName] = {};
		end
		
		if rawget(var,0) ~= nil or rawget(var,1) ~= nil then
			PrintDebug('|cffff9900MLNL Warning:MakeProxyTable!', 'Assuming passed variable is a <jarray>. Values at index 0 and 1 will be nilled!|r');
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
			PrintDebug('|cffff5500MLNL Error:SaveIntoNamedTable!', 'Passed arguments are NIL!|r');
			return;
		end
		local var = _G[varName];
		if not var then
			PrintDebug('|cffff9900MLNL Warning:SaveIntoNamedTable!', 'Table', varName, 'cannot be found! Creating a new table...|r');
			var = {};
			_G[varName] = var;
		end
		if not varName2ProxyTableHash[varName] then
			PrintDebug('|cffff9900MLNL Warning:SaveIntoNamedTable!', 'Table', varName, 'is not proxied! Making a proxy table for it...|r');
			MakeProxyTable(varName, true);
		end

		var[key] = val;
	end

	function MagiLogNLoad.WillSaveThis(argName, willSave)
		if argName == nil or argName == '' then
			PrintDebug('|cffff5500MLNL Error:MagiLogNLoad.WillSaveThis!', 'Passed name of variable is NIL! It must be a string.|r');
			return;
		end
		
		if type(argName) == 'table' then
			PrintDebug('|cffff5500MLNL Error:MagiLogNLoad.WillSaveThis!', 'Passed name of variable is a table! It must be a string.|r');
			return;
		end

		willSave = willSave == nil and true or willSave;

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
			PrintDebug('|cffff9900MLNL Warning:MagiLogNLoad.WillSaveThis!', 'Variable:', varName, 'is NOT initialized.',
				'If that variable is supposed to hold a table, initialize it BEFORE making it saveable.|r');
		else
			if type(obj) == 'table' then
				if next(obj) ~= nil then
					PrintDebug('|cffff9900MLNL Warning:MagiLogNLoad.WillSaveThis!', 'Variable', varName, 
						"is NOT an empty table. Only new key-value pairs will be saved!|r");
				end
				local mt = getmetatable(obj);
				if mt and mt.isHashtable then
					if willSave then
						saveables.hashtables[obj] = varName;
					else
						saveables.hashtables[obj] = nil;
					end

					return true;
				end
				
				return MakeProxyTable(varName, willSave);
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
			PrintDebug('|cffff5500MLNL Error:HashtableGet', 'Non-proxied hashtable detected! ALL hashtables MUST be created/initialized after MagiLogNLoad.Init()!|r');
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
							if log[parentKey] and log[parentKey][k] ~= nil then
								ResetReferencedLogging(log[parentKey][k]);
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
			PrintDebug('|cffff5500MLNL Error:MagiLogNLoad.HashtableSaveInto!', 'Passed hashtable argument is NIL!|r');
			return false;
		end
		if childKey == nil or parentKey == nil then
			PrintDebug('|cffff5500MLNL Error:MagiLogNLoad.HashtableSaveInto!', 'Passed key arguments are NIL!|r');
			return false;
		end

		HashtableGet(whichHashTable, parentKey)[childKey] = value;
	end

	function MagiLogNLoad.HashtableLoadFrom(childKey, parentKey, whichHashTable, default)
		if whichHashTable == nil then
			PrintDebug('|cffff9900MLNL Warning:MagiLogNLoad.HashtableLoadFrom!', 'Passed hashtable argument is NIL! Returning default...|r');
			return default;
		end
		if childKey == nil or parentKey == nil then
			PrintDebug('|cffff9900MLNL Warning:MagiLogNLoad.HashtableLoadFrom!', 'Passed key arguments is NIL!  Returning default...|r');
			return default;
		end

		local val = HashtableGet(whichHashTable, parentKey)[childKey];
		return val ~= nil and val or default;
	end


	local function SaveIntoNamedHashtable(hashtableName, value, childKey, parentKey)
		if not _G[hashtableName] then
			PrintDebug('|cffff9900MLNL Warning:SaveIntoNamedHashtable!', 'Hashtable', hashtableName, 'cannot be found! Creating new hashtable...|r');
			_G[hashtableName] = InitHashtableBJ();
		end

		MagiLogNLoad.HashtableSaveInto(value, childKey, parentKey, _G[hashtableName]);
	end

	local function LogKillDestructable(destr)
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
			MagiLogNLoad.modes = _modes;
		elseif guiModes then
			local guiModesHash = Array2Hash(guiModes, 0, 15, '');

			MagiLogNLoad.modes.debug = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.DEBUG] ~= nil;
			
			MagiLogNLoad.modes.savePreplacedUnitsOfPlayer = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.SAVE_PREPLACED_UNITS_OF_PLAYER] ~= nil;			
			MagiLogNLoad.modes.saveDestroyedPreplacedUnits = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.SAVE_DESTROYED_PREPLACED_UNITS] ~= nil;			
			MagiLogNLoad.modes.saveNewUnitsOfPlayer = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.SAVE_NEW_UNITS_OF_PLAYER] ~= nil;
			MagiLogNLoad.modes.saveUnitsDisownedByPlayers = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.SAVE_UNITS_DISOWNED_BY_PLAYERS] ~= nil;
			
			MagiLogNLoad.modes.saveStandingPreplacedDestrs = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.SAVE_STANDING_PREPLACED_DESTRS] ~= nil;
			MagiLogNLoad.modes.saveDestroyedPreplacedDestrs = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.SAVE_DESTROYED_PREPLACED_DESTRS] ~= nil;

			MagiLogNLoad.modes.savePreplacedItems = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.SAVE_PREPLACED_ITEMS] ~= nil;
			MagiLogNLoad.modes.saveItemsDroppedManually = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.SAVE_ITEMS_DROPPED_MANUALLY] ~= nil;
			MagiLogNLoad.modes.saveAllItemsOnGround = guiModesHash[MagiLogNLoad.MODE_GUI_STRS.SAVE_ALL_ITEMS_ON_GROUND] ~= nil;
		end
		
		if MagiLogNLoad.modes.saveDestroyedPreplacedUnits then
			if not modalTriggers.saveDestroyedPreplacedUnits then
				local trig = CreateTrigger();
				modalTriggers.saveDestroyedPreplacedUnits = trig;
				
				TriggerRegisterAnyUnitEventBJ(trig, EVENT_PLAYER_UNIT_DEATH);
				TriggerAddAction(trig, function()
					local u = GetTriggerUnit();
					local prepMap = preplacedWidgets.units[u];
					if loggingPid < 0 or not prepMap then return end;

					local log = magiLog.extrasOfPlayer;
					if not log[loggingPid] then
						log[loggingPid] = {};
					end
					log = log[loggingPid];
					
					if not log[fCodes.LoadRemoveUnit] then
						log[fCodes.LoadRemoveUnit] = {};
					end
					log = log[fCodes.LoadRemoveUnit];
					
					
					local index = XYZW2Index32(
						prepMap[1], 
						prepMap[2], 
						Lerp(WORLD_BOUNDS.minX, WORLD_BOUNDS.maxX, Terp(MIN_FOURCC, MAX_FOURCC, prepMap[3])), 
						Lerp(WORLD_BOUNDS.minX, WORLD_BOUNDS.maxX, prepMap[4]/31)
					);
					if not log[index] then
						log[index] = {logGen.extras, fCodes.LoadRemoveUnit, {{fCodes.GetPreplacedUnit, prepMap}}};
					end
				end);
			end

			if not IsTriggerEnabled(modalTriggers.saveDestroyedPreplacedUnits) then
				EnableTrigger(modalTriggers.saveDestroyedPreplacedUnits);
			end
		else
			if IsTriggerEnabled(modalTriggers.saveDestroyedPreplacedUnits) then
				DisableTrigger(modalTriggers.saveDestroyedPreplacedUnits);
			end
		end

		if MagiLogNLoad.modes.saveDestroyedPreplacedDestrs then
			if not modalTriggers.saveDestroyedPreplacedDestrs then
				local trig = CreateTrigger();
				modalTriggers.saveDestroyedPreplacedDestrs = trig;

				EnumDestructablesInRect(WORLD_BOUNDS.rect, nil, function()
					TriggerRegisterDeathEvent(trig, GetEnumDestructable());
				end);
				
				TriggerAddAction(trig, function()
					LogKillDestructable(GetTriggerDestructable());
				end);
			end

			if not IsTriggerEnabled(modalTriggers.saveDestroyedPreplacedDestrs) then
				EnableTrigger(modalTriggers.saveDestroyedPreplacedDestrs);
			end
		else
			if IsTriggerEnabled(modalTriggers.saveDestroyedPreplacedDestrs) then
				DisableTrigger(modalTriggers.saveDestroyedPreplacedDestrs);
			end
		end

		if MagiLogNLoad.modes.savePreplacedItems then
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
						if k == widget and type(v) == 'table' and next(v) ~= nil then
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

		if MagiLogNLoad.modes.debug then
			print('--- MLNL MODES ---');
			for k,v in pairs(MagiLogNLoad.modes) do
				print(k, ':', v);
			end
			print('--- ---------- ---');
		end
	end

	local function InitGUI()
		if udg_mlnl_MakeProxyTable then
			if type(udg_mlnl_MakeProxyTable) ~= 'table' then
				PrintDebug('|cffff9900MLNL Warning:InitGui!','GUI variable mlnl_MakeProxyTable must be an array! Its functionality has been disabled.|r');
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
				PrintDebug('|cffff9900MLNL Warning:InitGui!','GUI variable mlnl_Modes must be an array! Its functionality has been disabled.|r');
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
				PrintDebug('|cffff9900MLNL Warning:InitGui!','GUI variable mlnl_WillSaveThis must be an array! Its functionality has been disabled.|r');
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
				PrintDebug('|cffff9900MLNL Warning:InitGui!','GUI variable mlnl_LoggingPlayer must be an array! Its functionality has been disabled.|r');
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

			Converts GUI hashtables API into Lua Tables, overrides StringHashBJ and GetHandleIdBJ to permit
			typecasting, bypasses the 256 hashtable limit by avoiding hashtables.
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
				PrintDebug(
					'|cffff5500MLNL Error:Flush__HashtableBJ',
					'Non-proxied hashtable detected! All Hashtables must be created/init after MagiLogNLoad.Init()!|r'
				);
			end
			if whichHashTable and parentKey ~= nil then
				local tab = whichHashTable[parentKey];
				if tab then
					for k,_ in pairs(tab) do
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
		-- -=-==-=  QoL Overrides  -=-==-=
		oriG.ConvertPlayerColor = _G.ConvertPlayerColor;
		_G.ConvertPlayerColor = function(pid)
			return oriG.ConvertPlayerColor(pid or 0);
		end

		-- -=-==-=  UNIT LOGGING HOOKS  -=-==-=
		
		PrependFunction('SetUnitColor', function(whichUnit, whichColor)
			if not whichUnit or not whichColor or not deconvertHash[whichColor] then return end;

			local log = magiLog.units;

			if not log[whichUnit] then
				log[whichUnit] = {};
			end
			local logEntries = log[whichUnit];

			logEntries[fCodes.SetUnitColor] = {50, fCodes.SetUnitColor, {{fCodes.GetLoggingUnit}, {fCodes.ConvertPlayerColor, {deconvertHash[whichColor]}}}};

		end);

		PrependFunction('SetUnitVertexColor', function(u, r, g, b, a)
			if not u or not r or not g or not b then return end;

			a = a or 255;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end

			log[u][fCodes.SetUnitVertexColor] = {51, fCodes.SetUnitVertexColor, {{fCodes.GetLoggingUnit}, r, g, b, a}};
		end);

		PrependFunction('SetUnitTimeScale', function(u, sca)
			if not u then return end;

			sca = sca or 1;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end

			log[u][fCodes.SetUnitTimeScale] = {52, fCodes.SetUnitTimeScale, {{fCodes.GetLoggingUnit}, {fCodes.Div10000, {Round(10000*sca)}}}};
		end);

		PrependFunction('SetUnitScale', function(u, sx, sy, sz)
			if not u or not sx then return end;
			
			sy = sy or sx;
			sz = sz or sx;
			
			if not unit2HiddenStat[u] then
				unit2HiddenStat[u] = {};
			end
			unit2HiddenStat[u].scale = sx;
			
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
			if not u or not int then return end;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end
			log = log[u];

			log[fCodes.SetUnitAnimation] = {[GetUnitCurrentOrder(u)] = {53, fCodes.SetUnitAnimationByIndex, {{fCodes.GetLoggingUnit}, int}}};
		end);

		PrependFunction('SetUnitAnimationWithRarity', function(u, str, rarity)
			if not u or not str or not rarity then return end;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end
			log = log[u];

			log[fCodes.SetUnitAnimation] = {
				[GetUnitCurrentOrder(u)] = {
					53, fCodes.SetUnitAnimationWithRarity, {
						{fCodes.GetLoggingUnit}, {fCodes.utf8char, GetUTF8Codes(str)}, {fCodes.ConvertRarityControl, {deconvertHash[rarity] or deconvertHash[RARITY_RARE]}}
					}
				}
			};
		end);

		PrependFunction('UnitAddAbility', function(u, abilid)
			if not u or not abilid then return end;

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
			if not u or not abilid then return end;
			if permanent == nil then permanent = true end;

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
			if not u or not abilid or not level then return end;

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
			if not u or not abilid then return end;

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
			if not u or not armor then return end;

			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end

			log[u][fCodes.LoadSetUnitArmor] = {110, fCodes.LoadSetUnitArmor, {{fCodes.GetLoggingUnit}, math_floor((armor-BlzGetUnitArmor(u)+.7)*10)}};
		end);

		
		PrependFunction('BlzSetUnitName', function(u, str)
			if not u or not str then return end;

			if not unit2HiddenStat[u] then
				unit2HiddenStat[u] = {};
			end
			unit2HiddenStat[u].name = str;
			
			local log = magiLog.units;

			if not log[u] then
				log[u] = {};
			end

			log[u][fCodes.BlzSetUnitName] = {55, fCodes.BlzSetUnitName, {{fCodes.GetLoggingUnit}, {fCodes.utf8char, GetUTF8Codes(str)}}};
		end);
		

		PrependFunction('SetUnitMoveSpeed', function(u, speed)
			if not u or not speed then return end;

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

			if changeColor == nil then changeColor = true end;

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


		WrapFunction('CreateDestructable', function(destr, destrid, __x, __y, face, sca, vari)
			if loggingPid < 0 or destr == nil or not destrid or destrid == 0 then return end;

			face = face or 0;
			sca = sca or 1;
			vari = vari or -1;

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

		PrependFunction('RemoveDestructable', function(destr)
			if loggingPid < 0 or destr == nil then return end;

			local log = magiLog.destrsOfPlayer;
			local pid = loggingPid;
			if not log[pid] then
				log[pid] = {};
			end
			log = log[pid];
			if log[destr] and log[destr][fCodes.LoadCreateDestructable] then
				log[destr] = nil;
			else
				--[[
				log = magiLog.extrasOfPlayer;
				if not log[loggingPid] then
					log[loggingPid] = {};
				end
				log = log[loggingPid];
				
				if not log[fCodes.RemoveDestructable] then
					log[fCodes.RemoveDestructable] = {};
				end
				log = log[fCodes.RemoveDestructable];
				
				local x, y = Round(GetDestructableX(destr)), Round(GetDestructableY(destr));
				local index = XY2Index30(x, y);
				
				log[index] = {
					logGen.extras, fCodes.RemoveDestructable, {{fCodes.GetDestructableByXY, {x, y}}}
				};
				]]
				log[destr][fCodes.RemoveDestructable] = {90, fCodes.RemoveDestructable, {
					{fCodes.GetDestructableByXY, {Round(GetDestructableX(destr)), Round(GetDestructableY(destr))}}
				}};
			end
		end);

		PrependFunction('KillDestructable', LogKillDestructable);

		PrependFunction('DestructableRestoreLife', function (destr, life, birth)
			if loggingPid < 0 or destr == nil or GetDestructableTypeId(destr) == 0 or not life or tempIsGateHash[destr] then return end;

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


		PrependFunction('ModifyGateBJ', function (op, destr)
			if loggingPid < 0 or not destr or GetDestructableTypeId(destr) == 0 or not op then return end;

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

			log[destr][fCodes.ModifyGateBJ] = {30, fCodes.ModifyGateBJ, {
				op, {fCodes.GetDestructableByXY, {Round(GetDestructableX(destr)), Round(GetDestructableY(destr))}}
			}};
		end);

		PrependFunction('SetDestructableInvulnerable', function (destr, flag)
			if loggingPid < 0 or not destr or GetDestructableTypeId(destr) == 0 or flag == nil then return end;

			local log = magiLog.destrsOfPlayer;
			local pid = loggingPid;
			if not log[pid] then
				log[pid] = {};
			end
			log = log[pid];
			if not log[destr] then
				log[destr] = {};
			end

			log[destr][fCodes.SetDestructableInvulnerable] = {40, fCodes.SetDestructableInvulnerable, {
				{fCodes.GetDestructableByXY, {Round(GetDestructableX(destr)), Round(GetDestructableY(destr))}}, {fCodes.I2B, {B2I(flag)}}
			}};
		end);


		-- -=-==-=  TERRAIN LOGGING HOOKS  -=-==-=

		PrependFunction('SetTerrainType', function(x, y, terrainType, variation, area, shape)
			if loggingPid < 0 or not x or not y or not terrainType then return end;

			variation = variation or -1;
			shape = shape or 0;
			area = area or 1;

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

		-- -=-==-=  RESEARCH LOGGING HOOKS  -=-==-=

		PrependFunction('AddPlayerTechResearched', function(p, resId, levels)
			if not p or not resId or resId == 0 or not levels then return end;

			local pid = GetPlayerId(p);

			local log = magiLog.researchOfPlayer[pid];

			if not log then
				log = {};
				magiLog.researchOfPlayer[pid] = log;
			end

			logGen.res = logGen.res + 1;
			log[logGen.res] = {logGen.res, fCodes.AddPlayerTechResearched, {{fCodes.GetLoggingPlayer}, resId, levels}};
		end);

		PrependFunction('SetPlayerTechResearched', function(p, resId, levels)
			if not p or not resId or resId == 0 or not levels then return end;

			local pid = GetPlayerId(p);

			local log = magiLog.researchOfPlayer[pid];

			if not log then
				log = {};
				magiLog.researchOfPlayer[pid] = log;
			end

			logGen.res = logGen.res + 1;
			log[logGen.res] = {logGen.res, fCodes.SetPlayerTechResearched, {{fCodes.GetLoggingPlayer}, resId, levels}};
		end);


		-- -=-==-=  EXTRAS LOGGING HOOKS  -=-==-=
		
		PrependFunction('RemoveUnit', function(u)
			if loggingPid < 0 or not u or not preplacedWidgets.units[u] then return end;
			
			local log = magiLog.extrasOfPlayer;
			if not log[loggingPid] then
				log[loggingPid] = {};
			end
			log = log[loggingPid];
			
			if not log[fCodes.LoadRemoveUnit] then
				log[fCodes.LoadRemoveUnit] = {};
			end
			log = log[fCodes.LoadRemoveUnit];
			
			local tab = preplacedWidgets.units[u];
			local index = XYZW2Index32(
				tab[1], 
				tab[2], 
				Lerp(WORLD_BOUNDS.minX, WORLD_BOUNDS.maxX, Terp(MIN_FOURCC, MAX_FOURCC, tab[3])), 
				Lerp(WORLD_BOUNDS.minX, WORLD_BOUNDS.maxX, tab[4]/31)
			);
			log[index] = {
				logGen.extras, fCodes.LoadRemoveUnit, {{fCodes.GetPreplacedUnit, tab}}
			};
		end);
		
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
			if not p or not x or not y then return end;
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
			if not p or not x or not y or not radius then return end;
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
			if not p or not loc or not radius then return end;

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
		fCodes.DestructableRestoreLife,fCodes.RemoveItem, fCodes.SetPlayerTechResearched, fCodes.SetDestructableInvulnerable, fCodes.UTF8Codes2Real,
		fCodes.KillUnit, fCodes.LoadRemoveUnit, fCodes.GetPreplacedUnit = unpack(Range(1,128));

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
				fCodes.DestructableRestoreLife, fCodes.RemoveItem, fCodes.SetPlayerTechResearched, fCodes.SetDestructableInvulnerable, fCodes.UTF8Codes2Real,
				fCodes.KillUnit, fCodes.LoadRemoveUnit, fCodes.GetPreplacedUnit
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
				DestructableRestoreLife, RemoveItem, SetPlayerTechResearched, SetDestructableInvulnerable, UTF8Codes2Real,
				KillUnit, LoadRemoveUnit, GetPreplacedUnit
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
		MagiLogNLoad.BASE_STATES.HASH = TableInvert(MagiLogNLoad.BASE_STATES);
		MagiLogNLoad.SAVE_STATES.HASH = TableInvert(MagiLogNLoad.SAVE_STATES);
		MagiLogNLoad.LOAD_STATES.HASH = TableInvert(MagiLogNLoad.LOAD_STATES);

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

	function MagiLogNLoad.SetLoggingPlayer(pOrId)
		local pid;
		if not pOrId then
			pid = -1;
		elseif GetHandleTypeStr(pOrId) == 'player' then
			pid = GetPlayerId(pOrId);
		else
			local int = math.tointeger(pOrId);
			if int and Player(int) then
				pid = int;
			else
				PrintDebug('|cffff5500MLNL Error:SetLoggingPlayer!', 'Argument <pOrId> passed is NOT a player nor a player ID!|r');
				return;
			end
		end

		--[[
		if pid ~= loggingPid and loggingPid >= 0 then
			MagiLogNLoad.UpdateSaveableVarsForPlayerId(loggingPid);
		end
		]]

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
		if MagiLogNLoad.configVersion == nil then
			PrintDebug('|cffff5500MLNL Error:Init!', 'Missing config script!');
			return false;
		end
		
		
		for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
			MagiLogNLoad.stateOfPlayer[i] = MagiLogNLoad.BASE_STATES.OFF;
		end
		
		tempGroup = CreateGroup();
		
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

			{arr=magiLog.proxyTablesOfPlayer, referenceLogger=true},
			{arr=magiLog.hashtablesOfPlayer, referenceLogger=true},

			unit2TransportHash,
			unit2HiddenStat,
			magiLog.units,
			magiLog.formerUnits,
			{arr=magiLog.unitsOfPlayer},
			{arr=magiLog.referencedUnitsOfPlayer},

			{arr=magiLog.destrsOfPlayer, chk={fCodes.KillDestructable, fCodes.RemoveDestructable}},
			{arr=magiLog.referencedDestrsOfPlayer},

			magiLog.items,
			{arr=magiLog.itemsOfPlayer},
			{arr=magiLog.referencedItemsOfPlayer}
		};
		tabKeyCleanerSize = 31;

		mainTimer = CreateTimer();
		TimerStart(mainTimer, TICK_DUR, true, TimerTick);

		for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
			MagiLogNLoad.stateOfPlayer[i] = MagiLogNLoad.BASE_STATES.STANDBY;
		end
		
		
		PrintDebug(
			'|cffff9900MLNL Warning! This update (v1.1) contains [BREAKING] changes!',
			'Please refer to the CHANGELOG and adapt your map as needed.|r'
		);
		
		MagiLogNLoad.Init = DoNothing;
		
		return true;
	end
end

if Debug and Debug.endFile then Debug.endFile() end

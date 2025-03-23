if Debug and Debug.beginFile then Debug.beginFile('MLNL_Config') end
--[[
	Friendly configuration file used by the MagiLogNLoad system.
]]
do
	MagiLogNLoad = {configVersion = 1100};

	MagiLogNLoad.SAVE_FOLDER_PATH = 'MagiLogNLoad/';  -- needs to end with / if you want a folder

	-- Necessary abilities for the system to operate correctly.
	-- This can be any ability. Used by FileIO.
	MagiLogNLoad.FILEIO_ABIL = FourCC('AZIO');

	-- Needs to be a copy of the 'Agho' ability.
	-- Necessary for loading into transports.
	MagiLogNLoad.LOAD_GHOST_ID = FourCC('AFFZ');
	
	-- Needs to be a copy of the 'Adri' ability.
	-- Necessary for unloading units.
	MagiLogNLoad.UNLOAD_INSTA_ID = FourCC('AUNL');

	-- List all <Cargo Hold> and <Load> ability ids in your map so that transports can be saved and loaded properly.
	MagiLogNLoad.ALL_TRANSP_ABILS = {
		LOAD = {FourCC('Aloa'), FourCC('Sloa'), FourCC('Slo2'), FourCC('Slo3'), FourCC('Aenc')},
		CARGO = {FourCC('Sch3'), FourCC('Sch4'), FourCC('Sch5'), FourCC('Achd'), FourCC('Abun'), FourCC('Achl')}
	};
	
	-- Enforceable limits. Recommended for multiplayer maps without a tight-knit community.
	MagiLogNLoad.LOADING_TIME_SECONDS_TO_WARNING = 30;	-- use 0 or -1 to disable it.	
	MagiLogNLoad.LOADING_TIME_SECONDS_TO_ABORT = 120;	-- use 0 or -1 to disable it.
	
	MagiLogNLoad.MAX_LOADS_PER_PLAYER = 10; -- amount of times a player can load a file.	
	
	-- Save-files that exceed these parameters will be truncated.
	MagiLogNLoad.MAX_TERRAIN_PER_FILE = 10240;

	-- Read MAX_DESTRS_PER_FILE as: the max amount of destructables recorded in a save-file.
	MagiLogNLoad.MAX_DESTRS_PER_FILE = 5120;
	-- Read MAX_ENTRIES_PER_DESTR as: the max amount of properties each destr can record in a save-file.
	MagiLogNLoad.MAX_ENTRIES_PER_DESTR = 160;

	MagiLogNLoad.MAX_RESEARCH_PER_FILE = 5120;
	-- Most saved research contain only a couple of entries, so we dont need the extra config.

	-- Just extrapolate from the MAX_DESTRS_PER_FILE and MAX_ENTRIES_PER_DESTR explanations.
	MagiLogNLoad.MAX_UNITS_PER_FILE = 5120;
	MagiLogNLoad.MAX_ENTRIES_PER_UNIT = 1280;

	MagiLogNLoad.MAX_ITEMS_PER_FILE = 2560;
	MagiLogNLoad.MAX_ENTRIES_PER_ITEM = 80;

	-- Some data-types are not grouped by instance and instead spread out as sequences of entries across the save-file.
	MagiLogNLoad.MAX_HASHTABLE_ENTRIES_PER_FILE = 5120;

	MagiLogNLoad.MAX_VARIABLE_ENTRIES_PER_FILE = 5120;

	MagiLogNLoad.MAX_PROXYTABLE_ENTRIES_PER_FILE = 2560;

	MagiLogNLoad.MAX_EXTRAS_PER_FILE = 2560;

	-- Allows the system to replace type ids in the save-file with new ones.
	-- Use this to support save-files created in older versions of your map that might
	-- not have the same stuff as the new versions.
	MagiLogNLoad.oldTypeId2NewTypeId = {
		--['hpea'] = 'hkni',
		--['hfoo'] = 'hmkg',
		--['hsor'] = 'harc'
	};
	
	-- These strings are used to configure the modes when using GUI to initialize the system.
	-- Please refer to the provided test map GUI triggers for an example of how it works.
	MagiLogNLoad.MODE_GUI_STRS = {
		-- Enable Debug prints. Very recommended.
		DEBUG = 'DEBUG',

		-- Save units created at runtime if they are owned by the saving player.
		-- Units will be saved with their items, unless the items are pre-placed and SAVE_PREPLACED_ITEMS is disabled.
		-- Does not save summoned or dead units.
		SAVE_NEW_UNITS_OF_PLAYER = 'SAVE_NEW_UNITS_OF_PLAYER',
		
		-- Save changes to pre-placed units. Might lead to conflicts in multiplayer.
		-- Defining a logging player can be done through MagiLogNLoad.SetLoggingPlayer or mlnl_LoggingPlayer.
		SAVE_PREPLACED_UNITS_OF_PLAYER = 'SAVE_PREPLACED_UNITS_OF_PLAYER',
		
		-- Save destruction/removal of pre-placed units. Might lead to conflicts in multiplayer.
		-- [IMPORTANT] Destruction/removals are only saved if a logging player is defined when they happen.
		-- Defining a logging player can be done through MagiLogNLoad.SetLoggingPlayer or mlnl_LoggingPlayer.
		SAVE_DESTROYED_PREPLACED_UNITS = 'SAVE_DESTROYED_PREPLACED_UNITS',

		-- Save changes to pre-placed items, even if units are holding them. Might lead to conflicts in multiplayer.
		-- If the item is destroyed or removed, its destruction will be recorded and reproduced when loaded.
		-- [IMPORTANT] Changes are only saved if a logging player is defined when the change happens.
		-- Defining a logging player can be done through MagiLogNLoad.SetLoggingPlayer or mlnl_LoggingPlayer.
		SAVE_PREPLACED_ITEMS = 'SAVE_PREPLACED_ITEMS',

		-- Save changes to pre-placed trees/gates/destructables.
		-- [IMPORTANT] AS A SPECIAL CASE, this mode saves destructables destroyed or removed
			-- > by explicit calls to Kill/RemoveDestructable().
		-- Might lead to conflicts in multiplayer.
		-- [IMPORTANT] Changes are only saved if a logging player is defined when the change happens.
		-- Defining a logging player can be done through MagiLogNLoad.SetLoggingPlayer or mlnl_LoggingPlayer.
		SAVE_STANDING_PREPLACED_DESTRS = 'SAVE_STANDING_PREPLACED_DESTRS',

		-- Save the destruction/removal of pre-placed trees/gates/destructables.
		-- Might lead to conflicts in multiplayer.
		-- If the map has too many destructables, the performance will suffer.
		-- [IMPORTANT] Destruction/Removals are only saved if a logging player is defined when they happen.
		-- Defining a logging player can be done through MagiLogNLoad.SetLoggingPlayer or mlnl_LoggingPlayer.
		SAVE_DESTROYED_PREPLACED_DESTRS = 'SAVE_DESTROYED_PREPLACED_DESTRS',

		-- Save units disowned by a player if the owner at the time of saving is one of the Neutral players.
		SAVE_UNITS_DISOWNED_BY_PLAYERS = 'SAVE_UNITS_DISOWNED_BY_PLAYERS',

		-- Save items on the ground only if a player's unit dropped them.
		-- Won't save items dropped by creeps or Neutral player's units.
		SAVE_ITEMS_DROPPED_MANUALLY = 'SAVE_ITEMS_DROPPED_MANUALLY',

		-- Adds all items on the ground to the saving player's save-file.
		SAVE_ALL_ITEMS_ON_GROUND = 'SAVE_ALL_ITEMS_ON_GROUND',
	};
	
	MagiLogNLoad.SAVE_CMD_PREFIX = '-save'; -- use <nil> or an empty string to disable the command.
	MagiLogNLoad.LOAD_CMD_PREFIX = '-load'; -- use <nil> or an empty string to disable the command.
	
	-- Async. Doing cursed things here will curse your map.
	MagiLogNLoad.onMaxLoadsError = function(_player)
		print('|cffff5500MLNL Error! You have already loaded too many save-files this game!|r');
	end
	
	-- Async. Doing cursed things here will curse your map.
	MagiLogNLoad.onAlreadyLoadedWarning = function(_player, _fileName)
		print('|cffff9900MLNL Warning! You have already loaded this save-file this game!|r')
		print('|cffff9900Any changes made might not load correctly until the map is restarted!|r');
	end
	
	-- Sync.
	---@return boolean @if false then it interrupts the saving
	MagiLogNLoad.onSaveStarted = function(_player, _fileName)
		if _player == GetLocalPlayer() then
			print('|cff00fa33Saving file <|r', _fileName, '|cff00fa33>...|r');
		end
		
		return true;
	end
	
	-- Async. Doing cursed things here will curse your map.
	MagiLogNLoad.onSaveFinished = function(_player, _fileName)
		print('|cff00fa33File <|r', _fileName, '|cff00fa33> saved successfully!|r');
		MagiLogNLoad.willPrintTallyNext = true;
	end
	
	-- Sync.
	---@return boolean @if false then it interrupts the loading
	MagiLogNLoad.onLoadStarted = function(_player)
		print('|cffffdd00', GetPlayerName(_player), 'has started loading a save-file. Please wait!|r');
		return true;
	end
	
	-- Sync.
	MagiLogNLoad.onLoadFinished = function(_player, _fileName)
		print('|cff00fa33', GetPlayerName(_player), 'has loaded their save-file successfully!|r');
		MagiLogNLoad.willPrintTallyNext = true;
	end
	
	-- Sync.
	---@param _progress integer @value within [0,100]
	---@param _checkpointTracker table @Tracks if a checkpoint has been reached
	MagiLogNLoad.onSyncProgressCheckpoint = function(_progress, _checkpointTracker)
		if not _checkpointTracker[75] and _progress >= 75 then
			_checkpointTracker[75] = true;

			print('|cffffff33Loading is','75\x25','done. Please wait!|r');
		elseif not _checkpointTracker[50] and _progress >= 50 then
			_checkpointTracker[50] = true;

			print('|cffffff33Loading is','50\x25','done. Please wait!|r');

		elseif not _checkpointTracker[25] and _progress >= 25 then
			_checkpointTracker[25] = true;

			print('|cffffff33Loading is','25\x25','done. Please wait!|r');
		end
	end
	
	--[[
	MagiLogNLoad.onSaveStarted = nil;
	MagiLogNLoad.onSaveFinished =  nil;
	MagiLogNLoad.onLoadStarted =  nil;
	MagiLogNLoad.onLoadFinished =  nil;
	MagiLogNLoad.onSyncProgressCheckpoint =  nil;
	MagiLogNLoad.onAlreadyLoadedWarning =  nil;
	MagiLogNLoad.onMaxLoadsError = nil;
	]]
end

if Debug and Debug.endFile then Debug.endFile() end

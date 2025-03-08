if Debug and Debug.beginFile then Debug.beginFile('MLNL_Config') end
--[[
	Friendly configuration file used by the MagiLogNLoad system.
]]
do
	MagiLogNLoad = {configVersion = 1080};

	MagiLogNLoad.SAVE_FOLDER_PATH = 'MagiLogNLoad/';  -- needs to end with / if you want a folder

	-- Necessary abilities for the system to operate correctly.
	-- This can be any ability. Used by FileIO.
	MagiLogNLoad.FILEIO_ABIL = FourCC('AZIO');

	-- Needs to be a copy of the 'Agho' ability.
	-- Necessary for loading transports.
	MagiLogNLoad.LOAD_GHOST_ID = FourCC('AFFZ');

	-- List all cargo ability ids in your map so that transports can be saved and loaded properly.
	MagiLogNLoad.ALL_CARGO_ABILS = {
		FourCC('Aloa'), FourCC('Slo3'),FourCC('Sch3'), FourCC('Sch5'),
		FourCC('S008'), FourCC('S006'),FourCC('S005'), FourCC('S000'),
		FourCC('S001'), FourCC('A0EZ'),FourCC('A06W')
	};

	-- Enforceable limits. Recommended for multiplayer maps without a tight-knit community.
	MagiLogNLoad.LOADING_TIME_SECONDS_TO_WARNING = 30;	-- use 0 or -1 to disable it.	
	MagiLogNLoad.LOADING_TIME_SECONDS_TO_ABORT = 120;	-- use 0 or -1 to disable it.
	
	MagiLogNLoad.MAX_LOADS_PER_PLAYER = 10;

	MagiLogNLoad.MAX_TERRAIN_PER_FILE = 10240;

	MagiLogNLoad.MAX_DESTRS_PER_FILE = 5120;
	MagiLogNLoad.MAX_ENTRIES_PER_DESTR = 160;

	MagiLogNLoad.MAX_RESEARCH_PER_FILE = 5120;

	MagiLogNLoad.MAX_UNITS_PER_FILE = 5120;
	MagiLogNLoad.MAX_ENTRIES_PER_UNIT = 1280;

	MagiLogNLoad.MAX_ITEMS_PER_FILE = 2560;
	MagiLogNLoad.MAX_ENTRIES_PER_ITEM = 80;

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
	
	MagiLogNLoad.MODE_GUI_STRS = {
		-- Enable Debug prints. Very recommended.
		DEBUG = 'DEBUG',

		-- Save pre-placed units. Might lead to conflicts in multiplayer.
		-- If the unit is destroyed or removed, its destruction will be recorded and reproduced when loaded.
		SAVE_PREPLACED_UNITS = 'SAVE_PREPLACED_UNITS',

		-- Save pre-placed items. Might lead to conflicts in multiplayer.
		-- If the item is destroyed or removed, its destruction will be recorded and reproduced when loaded.
		-- Due to the jank required to log item deaths, if the map has too many
		-- pre-placed items, its performance will suffer.
		SAVE_PREPLACED_ITEMS = 'SAVE_PREPLACED_ITEMS',

		-- As a special case, the destruction of trees/destructables is only saved
		-- if caused by the use of Remove/KillDestructable().
		SAVE_PREPLACED_DESTRS = 'SAVE_PREPLACED_DESTRS',

		-- Save trees/destructables that are killed by attacks or spells.
		-- If the map has too many trees/destrs, its performance will suffer.
		SAVE_DESTRS_KILLED_BY_UNITS = 'SAVE_DESTRS_KILLED_BY_UNITS',

		-- Recommended setting. If you don't enable this, you must use the
		-- WillSaveThis function/variable to have units saved at all.
		SAVE_ALL_UNITS_OF_PLAYER = 'SAVE_ALL_UNITS_OF_PLAYER',

		-- Save units disowned by a player if the owner at the time of saving is one of the Neutral players.
		SAVE_UNITS_DISOWNED_BY_PLAYERS = 'SAVE_UNITS_DISOWNED_BY_PLAYERS',

		-- Save items on the ground only if a player's unit dropped them.
		-- Won't save items dropped by creeps or Neutral player's units.
		SAVE_ITEMS_DROPPED_MANUALLY = 'SAVE_ITEMS_DROPPED_MANUALLY',

		-- Save all items on the ground.
		SAVE_ALL_ITEMS_ON_GROUND = 'SAVE_ALL_ITEMS_ON_GROUND',
	};
end

if Debug and Debug.endFile then Debug.endFile() end

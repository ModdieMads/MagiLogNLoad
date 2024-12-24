if Debug and Debug.beginFile then Debug.beginFile('FileIO') end

-- Adaptation of Trokkin @ HiveWorkshop.com's FileIO, by ModdieMads @ HiveWorkshop.com

do
	FileIO = {};
	
	local RAW_PREFIX = ']]i([['
	local RAW_SUFFIX = ']])--[['
	local RAW_SIZE = 256 - #RAW_PREFIX - #RAW_SUFFIX
	local FILEIO_ABIL = MagiLogNLoad.FILEIO_ABIL or FourCC('ANdc');
	local LOAD_EMPTY_KEY = 'empty'
	local lastFileName = nil;

	local function OpenFile(fileName)
		lastFileName = fileName;
		PreloadGenClear();
		Preload('")\nendfunction\n//!beginusercode\nlocal p={} local i=function(s) table.insert(p,s) end--[[');
	end

	local function WriteFile(str)
		for i = 1, #str, RAW_SIZE do
			Preload(RAW_PREFIX .. str:sub(i, i + RAW_SIZE - 1) .. RAW_SUFFIX);
		end
	end

	local function CloseFile()
		Preload(']]BlzSetAbilityTooltip(' .. FILEIO_ABIL .. ', table.concat(p), 0)\n//!endusercode\nfunction a takes nothing returns nothing\n//');
		PreloadGenEnd(lastFileName);
		lastFileName = nil;
	end

	---@param fileName string
	---@return string?
	function FileIO.LoadFile(fileName)
		BlzSetAbilityTooltip(FILEIO_ABIL, LOAD_EMPTY_KEY, 0);
		Preloader(fileName);
		local loaded = BlzGetAbilityTooltip(FILEIO_ABIL, 0);

		if loaded == LOAD_EMPTY_KEY then
			return nil;
		end
		return loaded;
	end

	---@param fileName string
	---@param data string
	---@param onFail function?
	---@return boolean
	function FileIO.SaveFile(fileName, data, onFail)
		OpenFile(fileName);
		WriteFile(data);
		CloseFile();
		
	end
end

if Debug and Debug.endFile then Debug.endFile() end
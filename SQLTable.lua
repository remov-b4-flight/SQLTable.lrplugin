--[[
@file SQLTable.lua
@brief Main part of 'SQLTable.lrplugin'
@note This plugin outputs file that SQL Server specified.
@author @remov_b4_flight
]]

local PluginTitle = 'SQLTable'
local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrProgress = import 'LrProgressScope'
local LrErrors = import 'LrErrors'
local LrPathUtils = import 'LrPathUtils'
local LrDialogs = import 'LrDialogs'
--local LrLogger = import 'LrLogger'
--local Logger = LrLogger(PluginTitle)
--Logger:enable('logfile')
DELM = ';'
FORMATTED = 1
RAW = 2
-- Define matadata specs what you want to export to SQL script.
local metatypes = {
	dateTime = 'datetime' .. DELM .. 'f',
	caption = 'nvarchar(64)' .. DELM .. 'f',
	folderName = 'nvarchar(64)' .. DELM .. 'f',
	fileName = 'nvarchar(64)' .. DELM .. 'f',
	cameraModel = 'nvarchar(64)' .. DELM .. 'f',
	lens = 'nvarchar(64)' .. DELM .. 'f',
	rating = 'decimal(1)' .. DELM .. 'r', 
	subjectDistance = 'decimal(5,1)' .. DELM .. 'f',
	aperture = 'decimal(3,1)' .. DELM .. 'r',
	shutterSpeed = 'decimal(10,6)' .. DELM .. 'r',
	exposureBias = 'decimal(4,2)' .. DELM .. 'r',
	isoSpeedRating = 'decimal(6)' .. DELM .. 'r',
	focalLength35mm = 'decimal(5,1)' .. DELM .. 'r',
	flash = 'nvarchar(64)' .. DELM .. 'f',
	fileSize = 'decimal(10)' .. DELM .. 'r',
	collections = 'decimal(2)'
}
local metadefs = {
	dateTime = {type = 'datetime', source = FORMATTED},
	caption = {type = 'nvarchar(64)', source = FORMATTED},
	folderName = {type = 'nvarchar(64)', source = FORMATTED},
	fileName = {type = 'nvarchar(64)', source = FORMATTED},
	cameraModel = {type = 'nvarchar(64)', source = FORMATTED},
	lens = {type = 'nvarchar(64)', source = FORMATTED},
	rating = {type = 'decimal(1)', source = RAW}, 
	subjectDistance = {type = 'decimal(4,1)', source = FORMATTED},
	aperture = {type = 'decimal(3,1)', source = RAW},
	shutterSpeed = {type = 'decimal(10,6)', source = RAW},
	exposureBias = {type = 'decimal(4,2)', source = RAW},
	isoSpeedRating = {type = 'decimal(6)', source = RAW},
	focalLength35mm = {type = 'decimal(5,1)', source = RAW},
	flash = {type = 'nvarchar(64)', source = FORMATTED},
	fileSize = {type = 'decimal(10)', source = RAW},
	collections = {type = 'decimal(2)'},
}
-- Define path delimiter
if WIN_ENV then
	PATHDELM = '¥'
else
	PATHDELM = '/'
end

function split(str, ts)
	-- 引数がないときは空tableを返す
	if ts == nil then return {} end
  
	local t = {} ; 
	i = 1
	for s in string.gmatch(str, "([^"..ts.."]+)") do
	  t[i] = s
	  i = i + 1
	end  
	return t
end

function getTable(key)
	for k,v in pairs(metatypes) do
		if (k == key) then 
			return v
		end
	end
end	

function getMetadata(It,key)
	local t = getTable(key)
	local meta = split(t,DELM)
	local val
	if (key == 'collections') then
		local c = It:getContainedCollections()
		val = #c
	elseif (meta[2] == 'f' or #meta == 1) then
		val = It:getFormattedMetadata(key)
	elseif (meta[2] == 'r') then
		val = It:getRawMetadata(key)
	end

	if (val == nil or string.len(val) == 0) then
		val = 'NULL'
	end
	return val
end

function getMetadata2(It,key)
	local meta = metadefs[key].source
	local val
	if (key == 'collections') then
		local c = It:getContainedCollections()
		val = #c
	elseif (meta == FORMATTED) then
		val = It:getFormattedMetadata(key)
	elseif (meta == RAW) then
		val = It:getRawMetadata(key)
	end

	if (val == nil or string.len(val) == 0) then
		val = 'NULL'
	end
	return val
end

function chop(str)
	local strlen = string.len(str)
	return string.sub(str,1,strlen - 1)
end

-- Making up
local CurrentCatalog = LrApplication.activeCatalog()
local TABLE = 'photos'
--Open output SQL file
local OutputFile = LrPathUtils.getStandardFilePath('home') .. PATHDELM 
OutputFile = OutputFile .. PluginTitle .. '.sql'
fp = io.open(OutputFile,"w")
if fp == nil then 
	LrErrors.throwUserError(message)
end

-- Drop table
local SQL = 'use lightroom;\n'
SQL = SQL .. 'drop table if exists ' .. TABLE ..';\n'
fp:write(SQL)

-- Build 'create table' statement 
local SQLCOL =  '('
local SQLCOLTYP = '('
for key,val in pairs(metatypes) do
	local meta = split(val,DELM)
	if (key == 'fileName' or key == 'dateTime') then
		key = '[' .. key .. ']'
	end
	SQLCOLTYP = SQLCOLTYP .. key .. ' ' .. meta[1] .. ','
	SQLCOL = SQLCOL .. key .. ','
end
SQLCOLTYP = chop(SQLCOLTYP)
SQLCOL = chop(SQLCOL)
SQLCOL = SQLCOL ..')'
SQL = 'create table ' .. TABLE  .. SQLCOLTYP .. ');\n'
fp:write(SQL)

-- Build 'insert' statement
INSERT = 'insert into ' .. TABLE .. SQLCOL

-- Main part of this plugin.
LrTasks.startAsyncTask( function ()
	local ProgressBar = LrProgress(
		{title = 'Generating SQL..'}
	)

	local SelectedPhotos = CurrentCatalog:getTargetPhotos()
	local countPhotos = #SelectedPhotos
	--loops photos in selected
	for i,PhotoIt in ipairs(SelectedPhotos) do
		SQLVAL = ' values('
		for key,val in pairs(metadefs) do
			local metadata = getMetadata2(PhotoIt,key)
			if ((string.find(val.type,'varchar') ~= nil or string.find(val.type,'datetime') ~= nil) and metadata ~= 'NULL') then
--		for key,val in pairs(metatypes) do
--			local metadata = getMetadata(PhotoIt,key)
--			if ((string.find(val,'varchar') ~= nil or string.find(val,'datetime') ~= nil) and metadata ~= 'NULL') then
				metadata = string.gsub(metadata,'\'','\'\'')
				SQLVAL = SQLVAL .. '\'' .. metadata .. '\','
			elseif (key == 'shutterSpeed' and metadata ~= 'NULL') then
				SQLVAL = SQLVAL .. 'round(' .. metadata .. ',6),'
			elseif (key == 'exposureBias' and metadata ~= 'NULL') then
				SQLVAL = SQLVAL .. 'round(' .. metadata .. ',2),'
			else
				SQLVAL = SQLVAL .. metadata .. ','
			end
		end
		SQLVAL = chop(SQLVAL)
		SQL = INSERT .. SQLVAL .. ');\n'
		fp:write(SQL)
		if ((i % 15) == 0 ) then
			fp:write('go\n')
		end
		ProgressBar:setPortionComplete(i,countPhotos)
	end --end of for photos loop
ProgressBar:done()
fp:close()
end ) --end of startAsyncTask function()
return

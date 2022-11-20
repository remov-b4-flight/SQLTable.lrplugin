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

-- Constants
DELM = ';'
FORMATTED = 1
RAW = 2
VIRTUAL = 3

-- Start of customizable part.
-- Define table name of SQL
local TABLE = 'photos'
-- Define matadata specs what you want to export to SQL script.
local metadefs = {
	dateTime = {type = 'datetime', source = FORMATTED},
	caption = {type = 'nvarchar(64)', source = FORMATTED},
	folderName = {type = 'nvarchar(64)', source = FORMATTED},
	fileName = {type = 'nvarchar(64)', source = FORMATTED},
	cameraModel = {type = 'nvarchar(64)', source = FORMATTED},
	lens = {type = 'nvarchar(64)', source = FORMATTED},
	rating = {type = 'decimal(1)', source = RAW}, 
--	subjectDistance = {type = 'decimal(4,1)', source = FORMATTED},
	aperture = {type = 'decimal(3,1)', source = RAW},
	shutterSpeed = {type = 'decimal(10,6)', source = RAW},
	exposureBias = {type = 'decimal(4,2)', source = RAW},
	isoSpeedRating = {type = 'decimal(6)', source = RAW},
	focalLength35mm = {type = 'decimal(5,1)', source = RAW},
	flash = {type = 'nvarchar(32)', source = FORMATTED},
	fileSize = {type = 'decimal(10)', source = RAW},
	uuid = {type = 'varchar(64)', source = RAW},
	collections = {type = 'decimal(2)', source = VIRTUAL},
	collectionSet = {type = 'nvarchar(64)', source = VIRTUAL},
	collectionName = {type = 'nvarchar(64)', source = VIRTUAL},
}
-- END of cutomizable part

-- Define path delimiter
if WIN_ENV then
	PATHDELM = '¥'
else
	PATHDELM = '/'
end

function getMetadata(It,key)
	local meta = metadefs[key].source
	local val
	if (meta == VIRTUAL) then
		if (key == 'collections') then
			local c = It:getContainedCollections()
			if (c ~= nil) then
				val = #c
			end
		elseif(key == 'collectionSet') then
			local c = It:getContainedCollections()
			if (#c == 1) then
				local parent = c[1]:getParent()
				if (parent ~= nil) then 
					val = parent:getName() 
				end
			end
		elseif(key == 'collectionName') then
			local c = It:getContainedCollections()
			if (#c == 1) then
				val = c[1]:getName()
			end
		end
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

-- Start of Main part
-- Making up
local CurrentCatalog = LrApplication.activeCatalog()
-- Open output SQL file
local FileBaseName = PluginTitle .. '_' ..TABLE .. '.sql'
local OutputFile = LrPathUtils.getStandardFilePath('home') .. PATHDELM 
OutputFile = OutputFile .. FileBaseName
fp = io.open(OutputFile,"w")
if fp == nil then 
	LrErrors.throwUserError(message)
end

-- Drop table
local SQL = 'use lightroom;\n'
--SQL = SQL .. 'drop table ' .. TABLE .. ';\ngo\n'
SQL = SQL .. 'truncate table ' .. TABLE .. ';\ngo\n'
fp:write(SQL)

-- Build 'create table' statement 
local SQLCOL =  '('
local SQLCOLTYP = '('
for key,val in pairs(metadefs) do
	if (key == 'fileName' or key == 'dateTime' or key == 'fileSize') then
		key = '[' .. key .. ']'
	end
	SQLCOLTYP = SQLCOLTYP .. key .. ' ' .. val.type .. ','
	SQLCOL = SQLCOL .. key .. ','
end
SQLCOLTYP = chop(SQLCOLTYP)
SQLCOL = chop(SQLCOL)
SQLCOL = SQLCOL ..')'
SQL = 'create table ' .. TABLE  .. SQLCOLTYP .. ');\n'
fp:write(SQL)
-- create index statement
SQL = 'create index cap on ' .. TABLE .. "(caption);\n"
fp:write(SQL)

-- Build 'insert' statement
INSERT = 'insert into ' .. TABLE .. SQLCOL

-- Main part of this plugin.
LrTasks.startAsyncTask( function ()
	local ProgressBar = LrProgress(
		{title = 'making ' .. FileBaseName }
	)

	local SelectedPhotos = CurrentCatalog:getTargetPhotos()
	local countPhotos = #SelectedPhotos
	--loops photos in selected
	for i,PhotoIt in ipairs(SelectedPhotos) do
		SQLVAL = ' values('
		for key,val in pairs(metadefs) do
			local metadata = getMetadata(PhotoIt,key)
			if ((string.find(val.type,'varchar') ~= nil or string.find(val.type,'datetime') ~= nil) 
				and metadata ~= 'NULL') then

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
		if ((i % 80) == 0 ) then
			fp:write('go\n')
		end
		ProgressBar:setPortionComplete(i,countPhotos)
	end --end of for photos loop
ProgressBar:done()
fp:close()
end ) --end of startAsyncTask function()
return

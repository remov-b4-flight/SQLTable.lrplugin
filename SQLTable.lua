--[[
SQLTable.lua
SQLTable.lrplugin
Author:@remov_b4_result
]]

local PluginTitle = 'SQLTable'
local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrProgress = import 'LrProgressScope'
local LrErrors = import 'LrErrors'
local LrPathUtils = import 'LrPathUtils'
--local LrLogger = import 'LrLogger'
--local Logger = LrLogger(PluginTitle)
--Logger:enable('logfile')

-- Define path delimiter
if WIN_ENV then
	PATHDELM = '¥'
else
	PATHDELM = '/'
end
DELM = ';'

local metatypes = {
	dateTime = 'datetime' .. DELM .. 'f',
	caption = 'varchar(64)' .. DELM .. 'f',
	folderName = 'varchar(64)' .. DELM .. 'f',
	fileName = 'varchar(64)' .. DELM .. 'f',
	cameraModel = 'varchar(64)' .. DELM .. 'f',
	lens = 'varchar(64)' .. DELM .. 'f',
--	rating = 'int' .. DELM .. 'r', 
--	subjectDistance = 'decimal(4,1)' .. DELM .. 'f',
	aperture = 'decimal(2,1)' .. DELM .. 'r',
	shutterSpeed = 'decimal(7,6)' .. DELM .. 'r',
--	exposureBias = 'decimal(2,2)' .. DELM .. 'r',
	isoSpeedRating = 'decimal(6)' .. DELM .. 'r',
	focalLength35mm = 'decimal(4,1)' .. DELM .. 'r',
--	flash = 'string' .. DELM .. 'f',
}

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
	if (meta[2] == 'f' or #meta == 1) then
		val = It:getFormattedMetadata(key)
	elseif (meta[2] == 'r') then
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
SQL = SQL .. 'drop table if exists ' .. TABLE .. ';\n'
fp:write(SQL)

-- Build 'create table' statement 
local SQLCOL =  '('
local SQLCOLTYP = '('
for key,val in pairs(metatypes) do
	local meta = split(val,DELM)
	if (key == 'fileName' or key == 'dateTime') then
		key = '[' .. key .. ']'
		col = key
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
		for key,val in pairs(metatypes) do
			local metadata = getMetadata(PhotoIt,key)
--			local meta = split(val,',')
			if (string.find(val,'varchar') ~= nil or string.find(val,'datetime') ~= nil) then
				SQLVAL = SQLVAL .. '\'' .. metadata .. '\','
			else
				SQLVAL = SQLVAL .. metadata .. ','
			end
		end
		SQLVAL = chop(SQLVAL)
		SQL = INSERT .. SQLVAL .. ');\n'
		fp:write(SQL)
		ProgressBar:setPortionComplete(i,countPhotos)
	end --end of for photos loop
ProgressBar:done()
fp:close()
end ) --end of startAsyncTask function()
return

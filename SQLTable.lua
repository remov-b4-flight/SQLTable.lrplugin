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
local LrLogger = import 'LrLogger'
local Logger = LrLogger(PluginTitle)
Logger:enable('logfile')

if WIN_ENV then
	DELM = '¥'
else
	DELM = '/'
end

local metatypes = {
	uuid = 'string,r',
	folderName = 'string,f',
	fileName = 'string,f',
	rating = 'integer,r', 
	caption = 'string,f',
	cameraModel = 'string,f',
	lens = 'string,f',
	subjectDistance = 'string,f',
	dateTime = 'string,f',
	aperture = 'string,f',
	shutterSpeed = 'number,f',
	exposureBias = 'string,f',
	isoSpeedRating = 'integer,f',
	focalLength35mm = 'number,r',
	flash = 'string,f',
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
	local meta = split(t,',')
	local val
	if (meta[2] == 'f' or #meta == 1) then
		val = It:getFormattedMetadata(key)
	elseif (meta[2] == 'r') then
		val = It:getRawMetadata(key)
	end

	if (val == nil) then
		val = 'NULL'
	end
	return val
end
local CurrentCatalog = LrApplication.activeCatalog()
-- open output SQL file
local OutputFile = LrPathUtils.getStandardFilePath('home') .. DELM 
OutputFile = OutputFile .. PluginTitle .. '.txt'
fp = io.open(OutputFile,"w")
if fp == nil then 
	LrErrors.throwUserError(message)
end

--Drop
local SQL = 'DROP TABLE LIGHTROOM;\n'
fp:write(SQL)

--Build 'create table' statement 
SQL = 'CREATE TABLE LIGHTROOM ('
for key,val in pairs(metatypes) do
	local meta = split(val,',')
	local sqladd
	if (meta[1] == 'string') then
		sqladd = key .. ' CHAR(255)'
	elseif (meta[1] == 'number') then
		sqladd = key .. ' DECIMAL(8)'
	elseif (meta[1] == 'integer') then
		sqladd = key .. ' INT'
	elseif (meta[1] == 'boolean') then
		sqladd = key .. ' BIT'
	end
	if (key == 'uuid') then
		sqladd = sqladd .. ' PRIMARY KEY'
	end
	SQL = SQL .. sqladd ..','
end
SQL = SQL .. ');\n'
fp:write(SQL)

-- Build 'insert' statement
SQLCOL = 'INSERT INTO LIGHTROOM('
for key,val in pairs(metatypes) do
	local sqladd = key ..','
	SQLCOL = SQLCOL .. sqladd
end
SQLCOL = SQLCOL .. ') '

--Main part of this plugin.
LrTasks.startAsyncTask( function ()
	local ProgressBar = LrProgress(
		{title = 'Generating SQL..'}
	)

	local SelectedPhotos = CurrentCatalog:getTargetPhotos()
	local countPhotos = #SelectedPhotos
	--loops photos in selected
	for i,PhotoIt in ipairs(SelectedPhotos) do
		SQLVAL = 'VALUES('
		for key,val in pairs(metatypes) do
			local metadata = getMetadata(PhotoIt,key)
			local meta = split(val,',')
			if (meta[1] == 'number' or meta[1] == 'integer' ) then
				SQLVAL = SQLVAL .. metadata .. ','
			else
				SQLVAL = SQLVAL .. '\'' .. metadata .. '\','
			end
		end
		SQL = SQLCOL .. SQLVAL .. ');\n'
		fp:write(SQL)
		ProgressBar:setPortionComplete(i,countPhotos)
	end --end of for photos loop
ProgressBar:done()
fp:close()
end ) --end of startAsyncTask function()
return

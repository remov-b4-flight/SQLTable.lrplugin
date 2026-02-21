--[[-------------------------------------------------------
@file	PluginInit.lua
@brief	Initialize routines when SQLTable.lrplugin is loaded. 
@author	remov-b4-flight
---------------------------------------------------------]]
local prefs = import 'LrPrefs'.prefsForPlugin()

if prefs.isCreate == nil then
	prefs.isCreate = true
end

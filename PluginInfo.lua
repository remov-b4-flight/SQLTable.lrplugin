--[[-------------------------------------------------------
@file	PluginInfo.lua
@bried	Define plugin manager dialogs at SQLTable.lrplugin
@author	remov-b4-flight
---------------------------------------------------------]]
local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrView = import 'LrView'
local bind = LrView.bind -- a local shortcut for the binding function
local prefs = import 'LrPrefs'.prefsForPlugin()
local Info = require 'Info'

local PluginInfo = {}
local CurrentCatalog = LrApplication.activeCatalog()

function PluginInfo.startDialog( propertyTable )
	propertyTable.isCreate = prefs.isCreate
end

function PluginInfo.endDialog( propertyTable )
		prefs.isCreate = propertyTable.isCreate
end

function PluginInfo.sectionsForTopOfDialog( viewFactory, propertyTable )
	return {
		{
			title = Info.LrPluginName,
			synopsis = LOC '$$$/sqltable/description=Create SQL Table from Lightroom Metadata.',
			bind_to_object = propertyTable,
			viewFactory:row {
				viewFactory:checkbox {title = LOC '$$$/sqltable/create=Create Table', value = bind 'isCreate',},
			},
		},
	}
end

return PluginInfo

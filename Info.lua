--[[
@file Info.lua
@brief Plug-in definition of 'SQLTable.lrplugin'
@Author @remov_b4_flight
]]

return {

	LrSdkVersion = 6.0,

	LrToolkitIdentifier = 'cx.ath.remov-b4-flight.sqltable',
	LrPluginName = 'SQLTable',
	LrPluginInfoUrl='https://github.com/remov-b4-flight/SQLTable.lrplugin',
	LrExportMenuItems = { 
		{title = 'Export SQL Table',
		file = 'SQLTable.lua',
		enabledWhen = 'anythingSelected',},
	},
	VERSION = { major=0, minor=1, revision=0, build=5, },

}

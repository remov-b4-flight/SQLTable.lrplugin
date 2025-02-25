--[[
@file Info.lua
@brief Plug-in definition of 'SQLTable.lrplugin'
@Author @remov_b4_flight
]]

return {

	LrSdkVersion = 6.0,

	LrToolkitIdentifier = 'cx.ath.remov-b4-flight.sqltable',
	LrPluginName = 'SQL Table',
	LrPluginInfoUrl='https://twitter.com/remov_b4_flight',
	LrExportMenuItems = { 
		{title = 'SQLTable',
		file = 'SQLTable.lua',
		enabledWhen = 'photosSelected',},
	},
	VERSION = { major=0, minor=0, revision=1, build=0, },

}

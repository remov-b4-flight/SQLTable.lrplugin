--[[
Info.lua
SQLTable.lrplugin
Author:@remov_b4_result
]]

return {

	LrSdkVersion = 6.0,

	LrToolkitIdentifier = 'nu.mine.ruffles.sqltable',
	LrPluginName = 'SQL Table',
	LrPluginInfoUrl='https://twitter.com/remov_b4_flight',
	LrLibraryMenuItems = { 
		{title = 'SQLTable',
		file = 'SQLTable.lua',
		enabledWhen = 'photosAvailable',},
	},
	VERSION = { major=0, minor=0, revision=1, build=0, },

}

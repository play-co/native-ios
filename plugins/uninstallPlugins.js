/* @license
 * This file is part of the Game Closure SDK.
 *
 * The Game Closure SDK is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 
 * The Game Closure SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 
 * You should have received a copy of the GNU General Public License
 * along with the Game Closure SDK.  If not, see <http://www.gnu.org/licenses/>.
 */

var fs = require('fs');
var path = require('path');

var replaceTextBetween = function(text, startToken, endToken, replaceText) {
	var newText = "";
	var start = text.indexOf(startToken);
	var end = text.indexOf(endToken);
	if (start == -1 || end == -1) {
		return text;
	}
	var offset = text.substring(start).indexOf("\n") + 1;
	var afterStart = start + offset;
	newText += text.substring(0, afterStart);
	newText += replaceText;
	newText += text.substring(end);
	return newText;
}


var TEALEAF_DIR = path.join(__dirname, "../TeaLeaf");
var START_IMPORT = "//START_PLUGINS_IMPORT";
var END_IMPORT = "//END_PLUGINS_IMPORT";
var START_PLUGINS = "//START_PLUGINS";
var END_PLUGINS = "//END_PLUGINS";

//read config
var config = JSON.parse(fs.readFileSync(__dirname + "/config.json"));

var libraries = [];
var headerStrs = {
	"PLUGINS_IMPORT" : "", 
	"PLUGINS_FUNCS" : ""
};

var implStrs = {
	"PLUGINS_IMPORTS" : "",
	"init" : "",
	"sendEvent" : "",
	"initializeUsingJSON" : "",
	"didFailToRegisterForRemoteNotificationsWithError" : "",
	"didReceiveRemoteNotification" : "",
	"didRegisterForRemoteNotificationsWithDeviceToken" : "",
	"applicationDidBecomeActive" : "",
	"applicationWillTerminate" : "",
	"handleOpenURL" : "",
	"dealloc" : "",
	"PLUGINS_FUNCS" : ""
};

//inject and write all the collected plugin header code
var pluginManagerHeader = fs.readFileSync(path.join(__dirname, "../tealeaf/platform/PluginManager.h"), "utf-8");
for (var key in headerStrs) {
	var startKey = "//START_" + key;
	var endKey = "//END_" + key;
	pluginManagerHeader = replaceTextBetween(pluginManagerHeader, startKey, endKey, "");
}
pluginManagerHeader = replaceTextBetween(pluginManagerHeader, "//START_DEF_DELEGATES", "//END_DEF_DELEGATES", "");
fs.writeFileSync(path.join(__dirname, "../tealeaf/platform/PluginManager.h"), pluginManagerHeader, "utf-8");

//inject and write all the collected plugin header code
var pluginManagerImpl = fs.readFileSync(path.join(__dirname, "../tealeaf/platform/PluginManager.mm"), "utf-8");
for (var key in implStrs) {
	var startKey = "//START_" + key;
	var endKey = "//END_" + key;
	pluginManagerImpl = replaceTextBetween(pluginManagerImpl, startKey, endKey, "");
}
fs.writeFileSync(path.join(__dirname, "../tealeaf/platform/PluginManager.mm"), pluginManagerImpl, "utf-8");

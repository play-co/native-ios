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

//copy file func
var copyFileSync = function(srcFile, destFile, encoding) {
	var content = fs.readFileSync(srcFile, encoding);
	fs.writeFileSync(destFile, content, encoding);
}

var getTextBetween = function(text, startToken, endToken) {

	var start = text.indexOf(startToken);
	var end = text.indexOf(endToken);
	if (start == -1 || end == -1) {
		return "";
	}
	var offset = text.substring(start).indexOf("\n") + 1;
	var afterStart = start + offset;
	return text.substring(afterStart, end);
	
}

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
	"PLUGINS_FUNCS" : "",
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


var delegates = [];

for (var i in config) {

	var pluginDir = config[i];
	var pluginConfig = JSON.parse(fs.readFileSync(pluginDir + "/config.json"));
	var ios = pluginConfig.ios;

	for (var i = 0; i < ios.length; i++) {
		var obj = ios[i];
		if (!obj.name) {
			continue;
		} 

		if (obj.name.indexOf("_m") != -1) {
			//collect plugins xml text to replace and inject after going through all plugins
			var impl = fs.readFileSync(path.join(pluginDir, obj.srcPath, obj.name), "utf-8");
			for (var key in implStrs) {
				var startKey = "//START_" + key;
				var endKey = "//END_" + key;
				implStrs[key] += getTextBetween(impl, startKey, endKey);
			}

		} else if (obj.name.indexOf("_h") != -1) {
			//collect plugins xml text to replace and inject after going through all plugins
			var header = fs.readFileSync(path.join(pluginDir, obj.srcPath, obj.name), "utf-8");
			var startKey, endKey;
			for (var key in headerStrs) {
				startKey = "//START_" + key;
				endKey = "//END_" + key;
				headerStrs[key] += getTextBetween(header, startKey, endKey);
			}
			//check for any delegates
			startKey = "//START_DEF_DELEGATES";
			endKey = "//END_DEF_DELEGATES";
			var delegateStr = getTextBetween(header, startKey, endKey);
			delegateStr = delegateStr.replace(/(\r\n|\n|\r)/gm, "");
			if (delegateStr.length > 0) {
				delegates.push(delegateStr);
			}

		} else {
			//do nothing
		}
	}
	

}

//inject and write all the collected plugin header code
var pluginManagerHeader = fs.readFileSync(path.join(__dirname, "../tealeaf/platform/PluginManager.h"), "utf-8");
for (var key in headerStrs) {
	var startKey = "//START_" + key;
	var endKey = "//END_" + key;
	pluginManagerHeader = replaceTextBetween(pluginManagerHeader, startKey, endKey, headerStrs[key]);
}
//and delegates...
var fullDelegates = "";
if (delegates.length > 0) {
	fullDelegates = "<";
	fullDelegates += delegates.join(",");
	fullDelegates +=">\n";
	var startKey = "//START_DEF_DELEGATES";
	var endKey = "//END_DEF_DELEGATES";
	pluginManagerHeader = replaceTextBetween(pluginManagerHeader, startKey, endKey, fullDelegates);
}

fs.writeFileSync(path.join(__dirname, "../tealeaf/platform/PluginManager.h"), pluginManagerHeader, "utf-8");

//inject and write all the collected plugin header code
var pluginManagerImpl = fs.readFileSync(path.join(__dirname, "../tealeaf/platform/PluginManager.mm"), "utf-8");
for (var key in implStrs) {
	var startKey = "//START_" + key;
	var endKey = "//END_" + key;
	pluginManagerImpl = replaceTextBetween(pluginManagerImpl, startKey, endKey, implStrs[key]);
}
fs.writeFileSync(path.join(__dirname, "../tealeaf/platform/PluginManager.mm"), pluginManagerImpl, "utf-8");

/* @license
 * This file is part of the Game Closure SDK.
 *
 * The Game Closure SDK is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License v. 2.0 as published by Mozilla.
 
 * The Game Closure SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * Mozilla Public License v. 2.0 for more details.
 
 * You should have received a copy of the Mozilla Public License v. 2.0
 * along with the Game Closure SDK.  If not, see <http://mozilla.org/MPL/2.0/>.
 */

var path = require("path");
var ff = require("ff");
var clc = require("cli-color");
var wrench = require('wrench');
var async = require('async');
var fs = require('fs');
var plist = require('plist');

var logger;
var rsyncLogger;


//// Addons

var installAddons = function(builder, project, opts, addonConfig, next) {
	var paths = builder.common.paths;
	var addons = Object.keys(project.getAddonConfig());

	var f = ff(this, function() {

		var addonConfigMap = {};
		var next = f.slotPlain();
		var addonQueue = [];
		var checkedAddonMap = {};
		if (addons) {
			var missingAddons = [];
			for (var ii = 0; ii < addons.length; ++ii) {
				addonQueue.push(addons[ii]);
			}

			var processAddonQueue = function() {
				var addon = null;
				if (addonQueue.length > 0) {
					addon = addonQueue.shift();
				} else {
					if (missingAddons.length > 0) {
						logger.error("=========================================================================");
						logger.error("Missing addons =>", JSON.stringify(missingAddons));
						logger.error("=========================================================================");
						process.exit(1);
					}

					next(addonConfigMap);
					return;
				}
				var addonConfig = paths.addons(addon, 'ios', 'config.json');

				if (fs.existsSync(addonConfig)) {
					fs.readFile(addonConfig, 'utf8', function(err, data) {
						if (!err && data) {
							try {
								var config = JSON.parse(data);
								addonConfigMap[addon] = data;
								if (config.addonDependencies && config.addonDependencies.length > 0) {
									for (var a in config.addonDependencies) {
										var dep = config.addonDependencies[a];
										if (!checkedAddonMap[dep]) {
											checkedAddonMap[dep] = true;
											addonQueue.push(dep);
										}
									}
								}
							} catch (err) {
								throw new Error("Malformed ios config file (bad JSON?) for addon '" + addon + "'\r\n" + err + "\r\n" + err.stack);
							}
						}
						processAddonQueue();
					});
				} else {
					if (!checkedAddonMap[addon]) {
						checkedAddonMap[addon] = true;
					}
					if (missingAddons.indexOf(addon) == -1) {
						missingAddons.push(addon);
						logger.warn("Unable to find iOS addon config file", addonConfig);
					}
					processAddonQueue();
				}
			};

			processAddonQueue();

		} else {
			next({});
		}
	}, function(addonConfigMap) {
		if (addonConfigMap) {
			var configuredAddons = [];

            for (var addon in addonConfigMap) {
				try {
					addonConfig[addon] = JSON.parse(addonConfigMap[addon]);
					configuredAddons.push(addon);
				} catch (err) {
					throw new Error("Unable to parse addon configuration for: " + addon + "\r\nError: " + err + "\r\n" + err.stack);
				}
            }

			logger.log("Configured addons:", JSON.stringify(configuredAddons));
        }
	}).error(function(err) {
		logger.error("Error while installing addons:", err, err.stack);
	}).cb(next);
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

var installAddonsProject = function(builder, opts, next) {
	var addonConfig = opts.addonConfig;
	var contents = opts.contents;
	var destDir = opts.destDir;
	var paths = builder.common.paths;
	var manifest = opts.manifest;
	var userDefined = {};

	var f = ff(this, function () {
		var frameworks = {}, frameworkPaths = {};

		for (var key in addonConfig) {
			var config = addonConfig[key];

			if (config.frameworks) {
				for (var ii = 0; ii < config.frameworks.length; ++ii) {
					var framework = config.frameworks[ii];

					if (path.extname(framework) === "") {
						framework = path.basename(framework);
					} else {
						framework = paths.addons(key, 'ios', framework);

						//var frameworkRelPath = "$(SRCROOT)" + path.relative(path.join(destDir, "tealeaf"), path.dirname(framework));
						var frameworkRelPath = path.dirname(framework);
						frameworkPaths[frameworkRelPath] = 1;
					}

					frameworks[framework] = 1;
				}
			}

			if (config.userDefined) {
				for (var ii = 0; ii < config.userDefined.length; ++ii) {
					var ud = config.userDefined[ii];

					userDefined[ud] = 1;
				}
			}
		}

		var frameworkId = 1;

		for (var framework in frameworks) {
			var fileType, sourceTree, demoKey;
			var filename = path.basename(framework);
			var fileEncoding = "";

			// If extension is framework,
			if (path.extname(framework) === ".a") {
				logger.log("Installing library:", framework);
				fileType = "archive.ar";
				sourceTree = '"<group>"';
				framework = path.relative(path.join(destDir, "tealeaf"), framework);
				demoKey = "System/Library/Frameworks/UIKit.framework";
			} else if (path.extname(framework) === ".xib") {
				logger.log("Installing xib:", framework);
				fileType = 'file.xib'
				sourceTree = '"<group>"';
				framework = path.relative(path.join(destDir, "tealeaf"), framework);
				demoKey = "path = MainWindow.xib";
				fileEncoding = "fileEncoding = 4; ";
			} else if (path.extname(framework) === ".bundle") {
				logger.log("Installing resource bundle:", framework);
				fileType = '"wrapper.plug-in"'
				sourceTree = '"<group>"';
				framework = path.relative(path.join(destDir, "tealeaf/resources"), framework);
				demoKey = "path = resources.bundle";
			} else if (path.extname(framework) === ".framework") {
				logger.log("Installing framework:", framework);
				fileType = "wrapper.framework";
				sourceTree = '"<group>"';
				framework = path.relative(path.join(destDir, "tealeaf"), framework);
				demoKey = "System/Library/Frameworks/UIKit.framework";
			} else if (path.extname(framework) === ".dylib") {
				logger.log("Installing dynamic library:", framework);
				fileType = "compiled.mach-o.dylib";
				sourceTree = 'SDKROOT';
				framework = "usr/lib/" + path.basename(framework);
				demoKey = "System/Library/Frameworks/UIKit.framework";
			} else if (path.extname(framework) === "") {
				logger.log("Installing system framework:", framework);
				fileType = "wrapper.framework";
				sourceTree = 'SDKROOT';
				framework = "System/Library/Frameworks/" + path.basename(framework) + ".framework";
				demoKey = "System/Library/Frameworks/UIKit.framework";
			}

			var uuid1 = "BAADBEEF";
			uuid1 += String('00000000' + frameworkId.toString(16).toUpperCase()).slice(-8);
			uuid1 += "DEADDEED"; // Unique from TTF installer

			var uuid2 = "DEADD00D";
			uuid2 += String('00000000' + frameworkId.toString(16).toUpperCase()).slice(-8);
			uuid2 += "BAADFEED";

			++frameworkId;

			// Read out UUID for storekit
			var uuid1_storekit, uuid2_storekit;

			// Inject PBXFileReference
			for (var ii = 0; ii < contents.length; ++ii) {
				var line = contents[ii];

				if (line.indexOf(demoKey) > 0) {
					uuid1_storekit = line.match(/(?=[ \t]*)([A-F,0-9]+?)(?=[ \t].)/g)[0];

					contents.splice(++ii, 0, "\t\t" + uuid1 + " /* " + filename + " */ = {isa = PBXFileReference; " + fileEncoding + "lastKnownFileType = " + fileType + "; name = " + filename + "; path = " + framework + "; sourceTree = " + sourceTree + "; };");

					logger.log(" - Found PBXFileReference template on line", ii, "with uuid", uuid1_storekit);

					break;
				}
			}

			// Inject reference to PBXFileReference
			for (var ii = 0; ii < contents.length; ++ii) {
				var line = contents[ii];

				// If line has the storekit UUID,
				if (line.indexOf(uuid1_storekit) > 0 && line.indexOf("PBXFileReference") == -1 && line.indexOf("PBXBuildFile") == -1) {
					contents.splice(++ii, 0, "\t\t\t" + uuid1 + " /* " + filename + " */,");

					logger.log(" - Found PBXFileReference reference template on line", ii);

					break;
				}
			}

			// Inject PBXBuildFile
			for (var ii = 0; ii < contents.length; ++ii) {
				var line = contents[ii];

				// If line has the storekit UUID,
				if (line.indexOf("fileRef = " + uuid1_storekit) > 0) {
					uuid2_storekit = line.match(/(?=[ \t]*)([A-F,0-9]+?)(?=[ \t].)/g)[0];

					contents.splice(++ii, 0, "\t\t" + uuid2 + " /* " + filename + " in Frameworks */ = {isa = PBXBuildFile; fileRef = " + uuid1 + " /* " + filename + " */; settings = {ATTRIBUTES = (Weak, ); }; };");

					logger.log(" - Found PBXBuildFile template on line", ii, "with uuid", uuid2_storekit);

					break;
				}
			}

			var uuid2_match_regex = new RegExp("/^[ \\t]+" + uuid2_storekit + "/");

			// Inject reference to PBXBuildFile
			for (var ii = 0; ii < contents.length; ++ii) {
				var line = contents[ii];

				// If line has the storekit UUID,
				if (line.indexOf(uuid2_storekit) > 0 && line.indexOf("PBXFileReference") == -1 && line.indexOf("PBXBuildFile") == -1) {
					contents.splice(++ii, 0, "\t\t\t" + uuid2 + " /* " + filename + " in Frameworks */,");

					logger.log(" - Found PBXBuildFile reference template on line", ii);

					break;
				}
			}
		}

		var searchKeys = ["FRAMEWORK_SEARCH_PATHS", "LIBRARY_SEARCH_PATHS"];

		for (var searchKeyIndex = 0; searchKeyIndex < searchKeys.length; ++searchKeyIndex) {
			var searchKey = searchKeys[searchKeyIndex];

			// Set up framework search paths
			for (var ii = 0; ii < contents.length; ++ii) {
				var line = contents[ii];

				if (line.indexOf(searchKey) == -1) {
					continue;
				}
				logger.log("Found", searchKey, "property on line", ii);
				var iiFw = ii;

				var semiIdx = line.indexOf(";");
				if (semiIdx > 0) {
					// Convert single value field to multi-value field
					var startIdx = line.indexOf("= ");
					if (startIdx == -1) {
						logger.log(" - Invalid", searchKey, "found.");
					} else {
						contents.splice(ii, 1, line.substring(0, startIdx + 2) + "(");
						contents.splice(ii+1, 0, "\t\t\t\t)"+line.substring(semiIdx));
						var existingPath = line.substring(startIdx + 2, semiIdx);
						if (existingPath != '""') {
							contents.splice(ii+1, 0, "\t\t\t\t\t"+existingPath);
						}
					}
				}

				// Look for the end to append new paths
				for (++ii; ii < contents.length; ++ii) {
					line = contents[ii];
					if (line.indexOf(";") == -1) {
						continue;
					}

					for (var key in frameworkPaths) {
						// Only add the leading comma if there is a value before this line
						if (ii-1 != iiFw) {
							// If previous line does not already have a comma,
							var prevLine = contents[ii-1];
							if (prevLine.indexOf(",", prevLine.length - 1) === -1) {
								contents[ii-1] = prevLine + ",";
							}
						}
						contents.splice(++ii-1, 0, "\t\t\t\t\t" + '"' + key + '"')
						logger.log(" - Installing", key, "search path on line", ii);
					}
					break;
				}
			}
		}

		// Install user-defined keys:

		var injectOffset = 0;

		for (var ii = 0; ii < contents.length; ++ii) {
			var line = contents[ii];

			if (line.indexOf("INFOPLIST_FILE") != -1) {
				injectOffset = ii + 1;
				break;
			}
		}

		if (!injectOffset) {
			logger.error("Unable to find INFOPLIST_FILE injection line for user-defined keys for some reason.");
			process.exit(1);
		}

		for (var key in userDefined) {
			var value = manifest.ios && manifest.ios[key];
			if (!value) {
				logger.error("Installing user-defined key", key, "failed: Could not find value in game manifest under ios section.");
				process.exit(1);
			} else {
				var injectLine = '\t\t\t\t' + key + ' = "' + value + '";';

				contents.splice(injectOffset, 0, injectLine);

				logger.log("Installed user-defined key", key, "=", value);
			}
		}

		// groups will store one array per plugin containing the filenames for the plugin
		var groups = {};

		// codes will store a map between filenames and uuids that we should inject later
		var codes = {};

		// build the groups object from addonConfig
		for (var key in addonConfig) {
			var config = addonConfig[key];

			if (config.code) {
				var files = [];
				for (var ii = 0; ii < config.code.length; ++ii) {
					var code = config.code[ii];

					code = paths.addons(key, 'ios', code);

					var file = path.relative(path.join(destDir, "tealeaf/platform"), code);
					files.push(file);
				}

				if (files.length) {
					groups[key] = files;
				}
			}
		}

		// Find the UUID for plugin manager (it's in the plugins group, which
		// is where we want to inject our new groups)
		var pluginManagerUUID;
		for (var ii = 0; ii < contents.length; ++ii) {
			var line = contents[ii];

			if (line.indexOf("path = PluginManager.mm") > 0) {
				pluginManagerUUID = line.match(/(?=[ \t]*)([A-F,0-9]+?)(?=[ \t].)/g)[0];
				break;
			}
		}

		if (!pluginManagerUUID) { throw new Error("Couldn't find PluginManager.mm for injection: looking for string 'path = PluginManager.mm'"); }

		// find the group that contains PluginManager.mm UUID and create more groups above it
		for (var ii = 0; ii < contents.length; ++ii) {
			var line = contents[ii];
			if (line.indexOf(pluginManagerUUID) > 0 && line.indexOf("PBXFileReference") == -1 && line.indexOf("PBXBuildFile") == -1) {
				// we found the plugin group at line ii
				break;
			}
		}

		// line number where we insert the group ref in the parent group
		// (add one since we want to insert *after* the reference to PluginManager.mm)
		var insertGroupRefsAt = ii + 1;
		
		// search in reverse to get to the start of the plugins group
		while (--ii) {
			if (/(?=[ \t]*)([A-F,0-9]+?)\s+.*?=\s+\{/g.test(contents[ii])) {
				logger.log(" - Found PBXGroup for PluginManager.mm");
				break;
			}
		}

		if (!ii) { throw new Error("Couldn't find a group containing PluginManager.mm"); }

		// insert groups for each plugin
		var codeId = 1;
		Object.keys(groups).forEach(function (groupName, index) {
			var groupUUID = "BAAFBEFF"
							+ String('00000000' + index.toString(16).toUpperCase()).slice(-8)
							+ "DEAFDEED";

			// insert the group definition
			contents.splice(ii++, 0, "\t\t" + groupUUID + " /* " + groupName + " */ = {\n"
					+ "\t\t\tisa = PBXGroup;\n"
					+ "\t\t\tchildren = (\n"
						+ groups[groupName].map(function (filename) {
							var basename = path.basename(filename);

							// store UUIDs for insertion later
							codes[filename] = {
								uuid1: "BAAFBEEF"
										+ String('00000000' + codeId.toString(16).toUpperCase()).slice(-8)
										+ "DEAFDEED",
								uuid2: "DEAFD00D"
										+ String('00000000' + codeId.toString(16).toUpperCase()).slice(-8)
										+ "BAAFFEED"
							};

							++codeId; // each file must have a unique ID
							return "\t\t\t\t" + codes[filename].uuid1 + " /* " + basename + " */,";
						}).join("\n") + "\n"
					+ "\t\t\t);\n"
					+ "\t\t\tname = " + groupName + ";\n"
					+ "\t\t\tsourceTree = \"<group>\";\n"
					+ "\t\t};");

			// insert a reference to the group definition in the plugin group
			++insertGroupRefsAt; // we inserted the full group definition above, so add 1
			contents.splice(insertGroupRefsAt, 0, "\t\t\t\t" + groupUUID + " /* " + groupName + " */,");
			++insertGroupRefsAt; // next group ref should be inserted on the line below this one

			logger.log(" - Injected PBXGroup for " + groupName);
		});

		for (var code in codes) {
			logger.log("Installing code:", code);

			var ext = path.extname(code);
			var fileType;
			var skipBuild = false; // Do not add to build step?
			if (ext === ".m") {
				fileType = "sourcecode.c.objc";
			} else if (ext === ".mm") {
				fileType = "sourcecode.cpp.objcpp";
			} else if (ext === ".c") {
				fileType = "sourcecode.c.c";
			} else if (ext === ".cpp" || ext === ".cc") {
				fileType = "sourcecode.cpp.cpp";
			} else if (ext === ".h" || ext == ".hpp") {
				fileType = "sourcecode.c.h";
				skipBuild = true;
			} else {
				throw new Error("Unsupported file type: " + code);
			}

			var filename = path.basename(code);

			var uuid1 = codes[code].uuid1;
			var uuid2 = codes[code].uuid2;

			// Read out UUID for plugin manager
			var uuid1_pm, uuid2_pm;

			// Inject PBXFileReference
			for (var ii = 0; ii < contents.length; ++ii) {
				var line = contents[ii];

				if (line.indexOf("path = PluginManager.mm") > 0) {
					uuid1_pm = line.match(/(?=[ \t]*)([A-F,0-9]+?)(?=[ \t].)/g)[0];

					contents.splice(++ii, 0, "\t\t" + uuid1 + " /* " + filename + " */ = "
						+ "{"
							+ "isa = PBXFileReference;"
							+ " fileEncoding = 4;"
							+ " lastKnownFileType = " + fileType + ";"
							+ " path = \"" + code + "\";"
							+ " name = \"" + filename + "\";"
							+ " sourceTree = \"<group>\";"
						+ " };");

					logger.log(" - Found PBXFileReference template on line", ii, "with uuid", uuid1_pm);

					break;
				}
			}

			// If skipping build step injection,
			if (skipBuild) {
				logger.log(" - Skipping build step injection");
			} else {
				// Inject PBXBuildFile
				for (var ii = 0; ii < contents.length; ++ii) {
					var line = contents[ii];

					// If line has the storekit UUID,
					if (line.indexOf("fileRef = " + uuid1_pm) > 0) {
						uuid2_pm = line.match(/(?=[ \t]*)([A-F,0-9]+?)(?=[ \t].)/g)[0];

						contents.splice(++ii, 0, "\t\t" + uuid2 + " /* " + filename + " in Sources */ = {isa = PBXBuildFile; fileRef = " + uuid1 + " /* " + filename + " */; };");

						logger.log(" - Found PBXBuildFile template on line", ii, "with uuid", uuid2_pm);

						break;
					}
				}

				var uuid2_match_regex = new RegExp("/^[ \\t]+" + uuid2_pm + "/");

				// Inject reference to PBXBuildFile
				for (var ii = 0; ii < contents.length; ++ii) {
					var line = contents[ii];

					// If line has the storekit UUID,
					if (line.indexOf(uuid2_pm) > 0 && line.indexOf("PBXFileReference") == -1 && line.indexOf("PBXBuildFile") == -1) {
						contents.splice(++ii, 0, "\t\t\t" + uuid2 + " /* " + filename + " in Sources */,");

						logger.log(" - Found PBXBuildFile reference template on line", ii);

						break;
					}
				}
			}
		}
	}).error(function(err) {
		logger.error("Failure in installing addon project changes:", err, err.stack);
	}).cb(next);
}

function installAddonsFiles(builder, opts, next) {
	var destPath = opts.destPath;
	var addonConfig = opts.addonConfig;

	var f = ff(function () {
		for (var addon in addonConfig) {
			var config = addonConfig[addon];

			if (config.resources) {
				for (var ii = 0; ii < config.resources.length; ++ii) {
					var destFile = builder.common.paths.addons(addon, 'ios', config.resources[ii]);

					logger.log("Installing addon resource:", destFile, "for", addon);
					builder.common.copyFileSync(destFile, path.join(destPath, path.basename(config.resources[ii])));
				}
			}
		}
	}).error(function(err) {
		logger.error("Failure in installing addon files:", err, err.stack);
	}).cb(next);
}

function installAddonsPList(builder, opts, next) {
	var contents = opts.contents;

	var f = ff(function () {
		// For each addon,
		for (var addon in opts.addonConfig) {
			var config = opts.addonConfig[addon];

			// If addon specifies PList mods,
			if (config.plist) {
				// For each PList mod,
				for (var plistKey in config.plist) {
					// Read value to inject
					var manifestValue = config.plist[plistKey];

					// Find injection point by walking JS object tree
					var keys = plistKey.split('.');
					var obj = contents;
					var wrote = false;
					for (var ii = 0; ii < keys.length; ++ii) {
						var key = keys[ii];
						var subkey = obj[key];

						// If key DNE,
						if (!subkey) {
							if (ii != keys.length - 1) {
								throw new Error("Manifest parent key not found:", plistKey);
							}

							obj[key] = manifestValue;
							logger.log("Installing plist new key:", plistKey, "=", manifestValue);
							wrote = true;
							break;
						} else {
							var type = typeof subkey;

							if (type === "object") {
								if (subkey.length === undefined) {
									obj = subkey;
								} else {
									if (ii != keys.length - 1) {
										var foundSubKey = false;
										for (var jj = 0; jj < keys.length; ++jj) {
											if (subkey[jj][keys[ii + 1]]) {
												foundSubKey = true;
												obj = subkey[jj];
												break;
											}
										}
										if (!foundSubKey) {
											throw new Error("Manifest array subkey is not found:", plistKey);
										}
									} else {
										subkey.push(manifestValue);
										logger.log("Installing plist array key:", plistKey, "=", manifestValue);
										wrote = true;
										break;
									}
								}
							} else {
								if (ii != keys.length - 1) {
									throw new Error("Manifest parent key is value:", plistKey);
								}

								obj[key] = manifestValue;
								logger.log("Installing plist object key:", plistKey, "=", manifestValue);
								wrote = true;
								break;
							}
						}
					}

					if (!wrote) {
						throw new Error("Manifest key not found:", plistKey);
					}
				}
			}
		}

		// Push modified contents along
		f.pass(contents);
	}).error(function(err) {
		logger.error("Failure in installing PList keys:", err, err.stack);
	}).cb(next);
}


//// Build

function validateSubmodules(next) {
	var submodules = [
		"tealeaf/core/core.h"
	];

	// Verify that submodules have been populated
	var f = ff(function() {
		var group = f.group();

		for (var i = 0; i < submodules.length; ++i) {
			fs.exists(path.join(__dirname, submodules[i]), group.slotPlain());
		}
	}, function(results) {
		var allGood = results.every(function(element, index) {
			if (!element) {
				logger.error("Submodule " + path.dirname(submodules[index]) + " not found");
			}
			return element;
		});

		if (!allGood) {
			f.fail("One of the submodules was not found.  Make sure you have run submodule update --init on your clone of the iOS repo");
		}
	}).cb(next);
}

function removeKeysForObjects(parentObject, objects, keys) {
	for (var ii = 0; ii < objects.length; ++ii) {
		var objectName = objects[ii];
		var obj = parentObject[objectName];

		for (var jj = 0; jj < keys.length; ++jj) {
			var key = keys[jj];

			var index = obj.indexOf(key);

			if (index !== -1) {
				obj.splice(index, 1);
			}
		}
	}
}

// Updates the given TeaLeafIOS-Info.plist file
function updatePListFile(builder, opts, next) {
	var manifest = opts.manifest;
	var bundleID = manifest.ios.bundleID;
	if (!bundleID) {
		throw new Error("Manifest file does not specify a bundleID under the ios section");
	}

	var f = ff(this, function() {
		fs.readFile(opts.plistFilePath, 'utf8', f());
	}, function(data) {
		logger.log("Updating Info.plist file: ", opts.plistFilePath);

		var contents = plist.parseStringSync(data);

		// Remove unsupported modes
		var orient = manifest.supportedOrientations;
		if (orient.indexOf("landscape") == -1) {
			logger.log("Orientations: Removing landscape support");
			removeKeysForObjects(contents, ["UISupportedInterfaceOrientations", "UISupportedInterfaceOrientations~ipad"],
				["UIInterfaceOrientationLandscapeRight", "UIInterfaceOrientationLandscapeLeft"]);
		}
		if (orient.indexOf("portrait") == -1) {
			logger.log("Orientations: Removing portrait support");
			removeKeysForObjects(contents, ["UISupportedInterfaceOrientations", "UISupportedInterfaceOrientations~ipad"],
				["UIInterfaceOrientationPortrait", "UIInterfaceOrientationPortraitUpsideDown"]);
		}

		contents.CFBundleShortVersionString = manifest.ios.version;

		var ttf = manifest.ttf;
		if (!ttf || !ttf.length) {
			logger.log("Fonts: No fonts to install from ttf section in manifest");
		} else {
			for (var ii = 0; ii < ttf.length; ++ii) {
				var file = path.basename(ttf[ii]);

				contents.UIAppFonts.push(file);
				logger.log("Fonts: Installing", file);
			}
		}

		// If RenderGloss enabled,
		if (manifest.ios.icons && manifest.ios.icons.renderGloss) {
			// Note: Default is for Xcode to render it for you
			logger.log("RenderGloss: Removing pre-rendered icon flag");
			delete contents.UIPrerenderedIcon;
			delete contents.CFBundleIcons.CFBundlePrimaryIcon.UIPrerenderedIcon;
		}

		contents.CFBundleDisplayName = opts.title;
		contents.CFBundleIdentifier = bundleID;
		contents.CFBundleName = bundleID;

		// For each URLTypes array entry,
		var found = 0;
		for (var ii = 0; ii < contents.CFBundleURLTypes.length; ++ii) {
			var obj = contents.CFBundleURLTypes[ii];

			// If it's the URLName one,
			if (obj.CFBundleURLName) {
				obj.CFBundleURLName = bundleID;
				++found;
			}

			// If it's the URLSchemes one,
			if (obj.CFBundleURLSchemes) {
				// Note this blows away all the array entries
				obj.CFBundleURLSchemes = [bundleID];
				++found;
			}
		}
		if (found != 2) {
			throw new Error("Unable to update URLTypes");
		}

		installAddonsPList(builder, {
			contents: contents,
			addonConfig: opts.addonConfig,
			manifest: opts.manifest
		}, f());
	}, function(contents) {
		fs.writeFile(opts.plistFilePath, plist.build(contents).toString(), f());
	}).error(function(err) {
		logger.error("Failure while updating PList file:", err, err.stack);
		process.exit(1);
	}).cb(next);
}

// Create the iOS project
var DEFAULT_IOS_PRODUCT = 'TeaLeafIOS';
var NAMES_TO_REPLACE = /(PRODUCT_NAME)|(name = )|(productName = )/;

function updateIOSProjectFile(builder, opts, next) {
	fs.readFile(opts.projectFile, 'utf8', function(err, data) {
		if (err) {
			next(err);
		} else {
			logger.log("Updating iOS project file:", opts.projectFile);

			var contents = data.split('\n');
			var i = 0, j = 0; // counters

			// For each line,
			contents = contents.map(function(line) {
				// If it has 'PRODUCT_NAME' in it, replace the name
				if (line.match(NAMES_TO_REPLACE)) {
					line = line.replace(DEFAULT_IOS_PRODUCT, opts.bundleID);
				}
				return line;
			});

			if (!opts.ttf) {
				logger.warn("No \"ttf\" section found in the manifest.json, so no custom TTF fonts will be installed.  This does not affect bitmap fonts");
			} else if (opts.ttf.length <= 0) {
				logger.warn("No \"ttf\" fonts specified in manifest.json, so no custom TTF fonts will be built in.  This does not affect bitmap fonts");
			} else {
				var fonts = [];

				// For each font,
				for (i = 0, len = opts.ttf.length; i < len; ++i) {
					var uuid1 = "BAADBEEF";
					uuid1 += String('00000000' + i.toString(16).toUpperCase()).slice(-8);
					uuid1 += "DEADD00D";

					var uuid2 = "DEADD00D";
					uuid2 += String('00000000' + i.toString(16).toUpperCase()).slice(-8);
					uuid2 += "BAADF00D";

					fonts.push({
						path: opts.ttf[i],
						basename: path.basename(opts.ttf[i]),
						buildUUID: uuid1,
						refUUID: uuid2
					});
				}

				// For each line,
				var updateCount = 0;
				var inResourcesBuildPhase = false, inResourcesList = false, filesCount = 0;
				for (i = 0; i < contents.length; ++i) {
					var line = contents[i];

					if (line === "/* Begin PBXBuildFile section */") {
						logger.log("Updating project file: Injecting PBXBuildFile section members for " + fonts.length + " font(s)");

						for (j = 0, jlen = fonts.length; j < jlen; ++j) {
							contents.splice(++i, 0, "\t\t" + fonts[j].buildUUID + " /* " + fonts[j].basename + " in Resources */ = {isa = PBXBuildFile; fileRef = " + fonts[j].refUUID + " /* " + fonts[j].basename + " */; };");
						}

						++updateCount;
					} else if (line === "/* Begin PBXFileReference section */") {
						logger.log("Updating project file: Injecting PBXFileReference section members for " + fonts.length + " font(s)");

						for (j = 0, jlen = fonts.length; j < jlen; ++j) {
							contents.splice(++i, 0, "\t\t" + fonts[j].refUUID + " /* " + fonts[j].basename + " */ = {isa = PBXFileReference; lastKnownFileType = file; name = \"" + fonts[j].basename + "\"; path = \"fonts/" + fonts[j].basename + "\"; sourceTree = \"<group>\"; };");
						}

						++updateCount;
					} else if (line === "/* Begin PBXResourcesBuildPhase section */") {
						logger.log("Updating project file: Found PBXResourcesBuildPhase section");
						inResourcesBuildPhase = true;
						filesCount = 0;
					} else if (inResourcesBuildPhase && line.indexOf("files = (") >= 0) {
						if (++filesCount == 1) {
							logger.log("Updating project file: Injecting PBXResourcesBuildPhase section members for " + fonts.length + " font(s)");

							for (j = 0, jlen = fonts.length; j < jlen; ++j) {
								contents.splice(++i, 0, "\t\t\t\t" + fonts[j].buildUUID + " /* " + fonts[j].basename + " */,");
							}

							inResourcesBuildPhase = false;

							++updateCount;
						}
					} else if (line.indexOf("/* resources */ = {") >= 0) {
						logger.log("Updating project file: Found resources list section");
						inResourcesList = true;
					} else if (inResourcesList && line.indexOf("children = (") >= 0) {
						logger.log("Updating project file: Injecting resources children members for " + fonts.length + " font(s)");

						for (j = 0, jlen = fonts.length; j < jlen; ++j) {
							contents.splice(++i, 0, "\t\t\t\t" + fonts[j].refUUID + " /* " + fonts[j].basename + " */,");
						}

						inResourcesList = false;

						++updateCount;
					}
				}

				if (updateCount === 4) {
					logger.log("Updating project file: Success!");
				} else {
					logger.error("Updating project file: Unable to find one of the sections to patch.  index.js has a bug -- it may not work with your version of XCode yet!");
				}
			}

			// Run it through the plugin system before writing
			installAddonsProject(builder, {
				addonConfig: opts.addonConfig,
				contents: contents,
				destDir: opts.destDir,
				manifest: opts.manifest
			}, function() {
				contents = contents.join('\n');

				fs.writeFile(opts.projectFile, contents, 'utf8', function(err) {
					next(err);
				});
			});
		}
	});
}

function copyFonts(builder, ttf, destDir) {
	if (ttf) {
		var fontDir = path.join(destDir, 'tealeaf/resources/fonts');
		wrench.mkdirSyncRecursive(fontDir);

		for (var i = 0, ilen = ttf.length; i < ilen; ++i) {
			var filePath = ttf[i];

			builder.common.copyFileSync(filePath, path.join(fontDir, path.basename(filePath)));
		}
	}
}

function copyIcons(builder, icons, destPath) {
	if (icons) {
		['57', '72', '114', '144'].forEach(function(size) {
			var iconPath = icons[size];
			if (iconPath) {
				if (fs.existsSync(iconPath)) {
					var targetPath = path.join(destPath, 'tealeaf', 'icon' + size + '.png');
					logger.log("Icons: Copying ", path.resolve(iconPath), " to ", path.resolve(targetPath));
					builder.common.copyFileSync(iconPath, targetPath);
				} else {
					logger.warn('Icon', iconPath, 'does not exist.');
				}
			} else {
				logger.warn('Icon size', size, 'is not specified under manifest.json:ios:icons.');
			}
		});
	} else {
		logger.warn('No icons specified under "ios".');
	}
}

function copySplash(builder, manifest, destPath, next) {
	if (manifest.splash) {
		var universalSplash = manifest.splash["universal"];
		
		var splashes = [
			{ key: "portrait480", outFile: "Default.png", outSize: "320x480" },
			{ key: "portrait960", outFile: "Default@2x.png", outSize: "640x960"},
			{ key: "portrait1024", outFile: "Default-Portrait~ipad.png", outSize: "768x1024"},
			{ key: "portrait1136", outFile: "Default-568h@2x.png", outSize: "640x1136"},
			{ key: "portrait2048", outFile: "Default-Portrait@2x~ipad.png", outSize: "1536x2048"},
			{ key: "landscape768", outFile: "Default-Landscape~ipad.png", outSize: "1024x768"},
			{ key: "landscape1536", outFile: "Default-Landscape@2x~ipad.png", outSize: "2048x1536"}
		];

		var f = ff(function () {
			var sLeft = splashes.length;
			var fNext = f();
			function makeSplash(i) {
				if (i < 0) {
					fNext();
					return;
				}
				
				var splash = splashes[i];
				if (manifest.splash[splash.key]) {
					var splashFile = path.resolve(manifest.splash[splash.key]);
				} else if(universalSplash) {
					var splashFile = path.resolve(universalSplash);
				} else {
					logger.warn("No universal splash given and no splash provided for " + splash.key);
					makeSplash(i-1);
					return;
				}
				
				var splashOut = path.join(path.resolve(destPath), 'tealeaf',splash.outFile);
				logger.log("Creating splash: " + splashOut + " from: "  + splashFile);
				builder.jvmtools.exec('splasher', [
					"-i", splashFile,
					"-o", splashOut,
					"-resize", splash.outSize,
					"-rotate", "auto"
				], function (splasher) {
					var formatter = new builder.common.Formatter('splasher');

					splasher.on('out', formatter.out);
					splasher.on('err', formatter.err);
					splasher.on('end', function (data) {
						makeSplash(i-1);
					})
				});
			}
			makeSplash(splashes.length - 1);
		}, function() {
			next();	
		});
	} else {
		logger.warn("No splash section provided in the provided manifest");
		next();
	}
}

function copyIfChanged() {

}

function copyDir(srcPath, destPath, name, cb) {
	var exec = require('child_process').exec;

	// rsync requires trailing slashes
	var srcDir = path.join(srcPath, name) + path.sep;
	var destDir = path.join(destPath, name) + path.sep;

	// -r: recursive
	// -t: copy modified times (required for copying diff only)
	// -p: copy permissions
	// -l: copy symlinks rather than following them
	rsyncLogger.log('rsync -r --delete -t -p -l ' + srcDir + ' ' + destDir);
	exec('rsync -v -r --delete -t -p -l ' + srcDir + ' ' + destDir, function (err, stdout, stderr) {
		if (err) {
			rsyncLogger.log(stderr);
			wrench.copyDirSyncRecursive(srcDir, destDir);
			logger.log('(wrench) copied', name, 'to', destPath);
			cb();
		} else {
			rsyncLogger.log(stdout);
			logger.log('(rsync) copied', name, 'to', destPath);
			cb();
		}
	});
}

function copyIOSProjectDir(srcPath, destPath, cb) {
	logger.log('copying', srcPath, 'to', destPath);
	
	var parent = path.dirname(destPath);
	if (!fs.existsSync(parent)) {
		fs.mkdirSync(parent);
	}
	
	if (!fs.existsSync(destPath)) {
		fs.mkdirSync(destPath);
	}

	copyDir(srcPath, destPath, 'tealeaf', cb);
}

function getIOSHash(git, next) {
	git.currentTag(__dirname, function (hash) {
		next(hash || 'unknown');
	});
}

function validateIOSManifest(manifest) {
	if (!manifest.ios) {
		// NOTE: This is actually a WARNING since no keys are required for now.
		//return "ios section is missing";
		manifest.ios = {};
	}

	var schema = {
		"entryPoint": {
			res: "Should be set to the entry point.",
			def: "gc.native.launchClient",
			halt: false,
			silent: true
		},
		"bundleID": {
			res: "Should be set to the Bundle ID (a name) for your app from iTunes Connect. In-app purchases may not work!",
			def: manifest.shortName,
			halt: false
		},
		"appleID": {
			res: "Should be set to the Apple ID (a number) for your app from iTunes Connect. In-app purchases may not work!",
			def: "123456789",
			halt: false
		},
		"version": {
			res: "Should be set to the Current Version string (ie. 1.0.0) for your app from iTunes Connect. In-app purchases may not work!",
			def: "1.0.0",
			halt: false
		}
	};

	function checkSchema(loadingParent, schemaParent, desc) {
		// For each key at this level of the schema tree,
		for (var key in schemaParent) {
			// Grab the subkey
			var loadPath = loadingParent[key];
			var schemaData = schemaParent[key];
			var loadType = typeof loadPath;

			if (loadType !== "string") {
				// Load and schema do not agree: Report to user
				var msg = 'The manifest.json key ' + desc + ':' + key + ' is missing! ' + schemaData.res;
				if (schemaData.halt) {
					return msg;
				} else {
					if (!schemaData.silent) {
						logger.warn(msg + " Defaulting to '" + schemaData.def + "'");
					}
					loadingParent[key] = schemaData.def;
				}
			}
		}

		return false;
	}

	return checkSchema(manifest.ios, schema, "ios");
}

function makeIOSProject(builder, opts, next) {
	// Unpack options
	var debug = opts.debug;
	var servicesURL = opts.servicesURL;
	var manifest = opts.project.manifest;

	// Validate iOS section of the manifest.json file
	var validationError = validateIOSManifest(manifest);
	if (validationError) {
		logger.error("manifest.json file ios section is malformed. " + validationError);
		process.exit(2);
	}

	var projectFile = path.join(opts.destPath, 'tealeaf/TeaLeafIOS.xcodeproj/project.pbxproj');

	var gameHash, sdkHash, nativeHash;

	var f = ff(this, function(){
		builder.packager.getGameHash(opts.project, f.slotPlain());
		builder.packager.getSDKHash(f.slotPlain());
		getIOSHash(builder.git, f.slotPlain());
	}, function(game_hash, sdk_hash, native_hash) {
		gameHash = game_hash;
		sdkHash = sdk_hash;
		nativeHash = native_hash;

		copyIOSProjectDir(__dirname, opts.destPath, f.wait());
	}, function() {
		updateIOSProjectFile(builder, {
			projectFile: projectFile,
			ttf: manifest.ttf,
			bundleID: manifest.ios.bundleID,
			addonConfig: opts.addonConfig,
			destDir: opts.destPath,
			manifest: manifest
		}, f.wait());

		var plistFile = path.join(opts.destPath, 'tealeaf/TeaLeafIOS-Info.plist');
		updatePListFile(builder, {
			plistFilePath: plistFile,
			addonConfig: opts.addonConfig,
			manifest: manifest,
			title: opts.title
		}, f.wait());

		var configPath = path.join(opts.destPath, "tealeaf/resources/config.plist");

		fs.writeFile(configPath, plist.build({
			remote_loading: 'false',
			tcp_port: 4747,
			code_port: 9201,
			screen_width: 480,
			screen_height: 800,
			code_host: 'localhost',
			entry_point: 'gc.native.launchClient',
			app_id: manifest.appID || "example.appid",
			tcp_host: 'localhost',
			source_dir: '/',
			game_hash: gameHash || "ios",
			sdk_hash: sdkHash || "ios",
			native_hash: nativeHash || "ios",
			code_path: 'native.js.mp3',
			studio_name: (manifest.studio && manifest.studio.name) || "example.studio",

			apple_id: manifest.ios.appleID || "example.appleid",
			bundle_id: manifest.ios.bundleID || "example.bundle",
			version: manifest.ios.version || "1.0"
		}).toString(), f.wait());
	}).error(function(code) {
		logger.log("Error while making iOS project file changes: " + code, code.stack);
		process.exit(2);
	}).cb(next);
}

exports.build = function(builder, project, opts, next) {
	logger = new builder.common.Formatter("native-ios");
	rsyncLogger = new builder.common.Formatter("rsync");

	var manifest = project.manifest;
	var argv = opts.argv;

	// Parse manifest and essential strings
	if (manifest.appID == null || manifest.shortName == null) {
		throw new Error("Build aborted: No appID or shortName in the manifest.");
	}

	// If shortName is invalid,
	if (!/^[a-zA-Z0-9.-]+$/.test(manifest.shortName)) {
		throw new Error("Build aborted: shortName contains invalid characters.  Should be a-Z 0-9 . - only");
	}

	// If IPA mode,
	var developer, provision;
	if (argv.ipa) {
		developer = argv.name;
		if (typeof developer !== "string") {
			developer = manifest.ios && manifest.ios.developer;
		}
		if (typeof developer !== "string") {
			logger.error("IPA mode selected but developer name was not provided.  You can add it to your manifest.json under the ios:developer key, or with the --developer command-line option.");
			process.exit(2);
		}
		logger.log("Using developer name:", developer);

		provision = argv.provision;
		if (typeof provision !== "string") {
			provision = manifest.ios && manifest.ios.provision;
		}
		if (typeof provision !== "string") {
			logger.error("IPA mode selected but .mobileprovision file was not provided.  You can add it to your manifest.json under the ios:provision key, or with the --provision command-line option.");
			process.exit(2);
		}
		logger.log("Using provision file:", provision);
	}

	// Parse appID.
	var PUNCTUATION_REGEX = /[!"#$%&'()*+,\-.\/:;<=>?@\[\\\]^_`{|}~]/g;
	opts.appID = manifest.appID.replace(PUNCTUATION_REGEX, '');

	// Parse paths.
	var destPath = path.join(__dirname, 'build', manifest.shortName);
	opts.output = path.join(destPath, 'tealeaf/resources', 'resources.bundle');

	// If cleaning out old directory first,
	if (argv.clean) {
		logger.log("Clean: Deleting previous build files");
		wrench.rmdirSyncRecursive(destPath, function() {/* ignore errors */});
	}

	// Print out --open state
	if (argv.open) {
		if (argv.ipa) {
			logger.log("Open: Open ignored because --ipa was specified");
		} else {
			logger.log("Open: Will open XCode project when build completes");
		}
	}

	// Print out --debug state
	if (argv.debug) {
		logger.log("Debug: Debug mode enabled");
	} else {
		logger.log("Debug: Release mode enabled");
	}

	var title = manifest.title;
	if (!title) {
		title = manifest.shortName;
	}
	logger.log("App ID:", opts.appID);
	logger.log("App Title:", title);

	var addonConfig = {};

	var f = ff(this, function() {
		validateSubmodules(f());
	}, function() {
		installAddons(builder, project, opts, addonConfig, f());
	}, function() {
		if (!argv['js-only']) {
			makeIOSProject(builder, {
				project: project,
				destPath: destPath,
				debug: argv.debug,
				servicesURL: manifest.servicesURL,
				title: title,
				addonConfig: addonConfig
			}, f());
		}
	}, function() {
		require(builder.common.paths.nativeBuild('native')).writeNativeResources(project, opts, f());
	}, function() {
		copyIcons(builder, manifest.ios.icons, destPath);
		copyFonts(builder, manifest.ttf, destPath);
		copySplash(builder, manifest, destPath, f.wait());
		installAddonsFiles(builder, {
			destPath: opts.output,
			addonConfig: addonConfig
		}, f.wait());
	}, function() {
		// If IPA generation was requested,
		if (argv.ipa) {
			// TODO: Debug mode is currently turned off because it does not build
			require(path.join(__dirname, 'xcode.js')).buildIPA(builder, path.join(destPath, '/tealeaf'), manifest.shortName, false, provision, developer, manifest.shortName+'.ipa', f());
		}
	}, function() {
		if (argv.ipa) {
			logger.log('Done with compilation.  The output .ipa file has been placed at', manifest.shortName+'.ipa');
		} else {
			var projPath = path.join(destPath, 'tealeaf/TeaLeafIOS.xcodeproj');

			logger.log('Done with compilation.  The XCode project has been placed at', projPath);

			// Launch XCode if requested
			if (argv.open) {
				logger.log('Open: Launching XCode project...');

				require('child_process').exec('open "' + projPath + '"');
			}
		}
		process.exit(0);
	}).error(function(err) {
		logger.error("Error during build process:", err, err.stack);
		process.exit(2);
	});
}


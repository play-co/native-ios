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

var logger;


exports.init = function(common) {
	console.log("Running install.sh");
	common.child("sh", ["install.sh"], {
		cwd: __dirname
	}, function () {
		console.log("Install complete");
	});

	exports.load(common);
}

exports.load = function(common) {
	common.config.set("ios:root", path.resolve(__dirname))
	common.config.write();

	require(common.paths.root('src', 'testapp')).registerTarget("native-ios", __dirname);
}

exports.testapp = function(common, opts, next) {
	var f = ff(this, function () {
		common.child('open', [path.join(__dirname, './tealeaf/TeaLeafIOS.xcodeproj')], {}, f.wait());
	}, function() {
		require(common.paths.root('src', 'serve')).cli();
	}).error(function(err) {
		console.log(clc.red("ERROR"), err);
	}).cb(next);
}


//// Addons

var installAddons = function(builder, project, opts, addonConfig, next) {
	var paths = builder.common.paths;
	var addons = project && project.manifest && project.manifest.addons;

	var f = ff(this, function() {
		var group = f.group();

		// For each addon,
		if (addons) {
			for (var ii = 0; ii < addons.length; ++ii) {
				var addon = addons[ii];
				var addonConfig = paths.addons(addon, 'ios', 'config.json');

				if (fs.existsSync(addonConfig)) {
					fs.readFile(addonConfig, 'utf8', group.slot());
				} else {
					logger.warn("Unable to find iOS addon config file", addonConfig);
				}
			}
		}
	}, function(results) {
		if (results) {
			for (var ii = 0; ii < results.length; ++ii) {
				var addon = addons[ii];
				addonConfig[addon] = JSON.parse(results[ii]);

				logger.log("Configured addon:", addon);
			}
		}
	}).error(function(err) {
		logger.error(err);
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

	var f = ff(this, function () {
		var frameworks = {};

		for (var key in addonConfig) {
			var config = addonConfig[key];

			if (config.frameworks) {
				for (var ii = 0; ii < config.frameworks.length; ++ii) {
					var framework = config.frameworks[ii];

					if (path.extname(framework) === "") {
						framework = path.basename(framework);
					} else {
						framework = paths.addons(addon, 'ios', framework);
					}

					frameworks[framework] = 1;
				}
			}
		}

		var frameworkId = 1;

		for (var framework in frameworks) {
			var fileType;
			var sourceTree;
			var filename = "framework" + frameworkId + "_" + path.basename(framework);

			// If extension is framework,
			if (path.extname(framework) === ".a") {
				logger.log("Installing library:", framework);
				fileType = "archive.ar";
				sourceTree = '"<group>"';
				framework = path.relative(destDir, framework);
			} else if (path.extname(framework) === ".framework") {
				logger.log("Installing framework:", framework);
				fileType = "wrapper.framework";
				sourceTree = '"<group>"';
				framework = path.relative(destDir, framework);
			} else if (path.extname(framework) === "") {
				logger.log("Installing system framework:", framework);
				fileType = "wrapper.framework";
				sourceTree = 'SDKROOT';
				framework = "System/Library/Frameworks/" + path.basename(framework) + ".framework";
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

				if (line.indexOf("System/Library/Frameworks/UIKit.framework") > 0) {
					uuid1_storekit = line.match(/(?=[ \t]*)([A-F,0-9]+?)(?=[ \t].)/g)[0];

					contents.splice(++ii, 0, "\t\t" + uuid1 + " /* " + filename + " */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = " + filename + "; path = " + framework + "; sourceTree = SDKROOT; };");

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

					contents.splice(++ii, 0, "\t\t" + uuid2 + " /* " + filename + " in Frameworks */ = {isa = PBXBuildFile; fileRef = " + uuid1 + " /* " + filename + " */; };");

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

		var codes = {};

		for (var key in addonConfig) {
			var config = addonConfig[key];

			if (config.code) {
				for (var ii = 0; ii < config.code.length; ++ii) {
					var code = config.code[ii];

					code = paths.addons(key, 'ios', code);

					var file = path.relative(path.join(destDir, "tealeaf/platform"), code);

					codes[file] = 1;
				}
			}
		}

		var codeId = 1;

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

			var filename = "code" + codeId + "_" + path.basename(code);

			var uuid1 = "BAAFBEEF";
			uuid1 += String('00000000' + codeId.toString(16).toUpperCase()).slice(-8);
			uuid1 += "DEAFDEED"; // Unique from TTF installer

			var uuid2 = "DEAFD00D";
			uuid2 += String('00000000' + codeId.toString(16).toUpperCase()).slice(-8);
			uuid2 += "BAAFFEED";

			++codeId;

			// Read out UUID for plugin manager
			var uuid1_pm, uuid2_pm;

			// Inject PBXFileReference
			for (var ii = 0; ii < contents.length; ++ii) {
				var line = contents[ii];

				if (line.indexOf("path = PluginManager.mm") > 0) {
					uuid1_pm = line.match(/(?=[ \t]*)([A-F,0-9]+?)(?=[ \t].)/g)[0];

					contents.splice(++ii, 0, "\t\t" + uuid1 + " /* " + filename + " */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = " + fileType + "; path = \"" + code + "\"; sourceTree = \"<group>\"; };");

					logger.log(" - Found PBXFileReference template on line", ii, "with uuid", uuid1_pm);

					break;
				}
			}

			// Inject reference to PBXFileReference
			for (var ii = 0; ii < contents.length; ++ii) {
				var line = contents[ii];

				// If line has the storekit UUID,
				if (line.indexOf(uuid1_pm) > 0 && line.indexOf("PBXFileReference") == -1 && line.indexOf("PBXBuildFile") == -1) {
					contents.splice(++ii, 0, "\t\t\t" + uuid1 + " /* " + filename + " */,");

					logger.log(" - Found PBXFileReference reference template on line", ii);

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
		logger.error("Failure in installing addon project changes:", err);
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

function writeConfigList(opts, next) {
	var config = [];

	config.push('<?xml version="1.0" encoding="UTF-8"?>');
	config.push('<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">');
	config.push('<plist version="1.0">');
	config.push('<dict>');
	config.push('\t<key>remote_loading</key>');
	config.push('\t<' + opts.remote_loading + '/>');
	config.push('\t<key>tcp_port</key>');
	config.push('\t<integer>' + opts.tcp_port + '</integer>');
	config.push('\t<key>code_port</key>');
	config.push('\t<integer>' + opts.code_port + '</integer>');
	config.push('\t<key>screen_width</key>');
	config.push('\t<integer>' + opts.screen_width + '</integer>');
	config.push('\t<key>screen_height</key>');
	config.push('\t<integer>' + opts.screen_height + '</integer>');
	config.push('\t<key>code_host</key>');
	config.push('\t<string>' + opts.code_host + '</string>');
	config.push('\t<key>entry_point</key>');
	config.push('\t<string>' + opts.entry_point + '</string>');
	config.push('\t<key>app_id</key>');
	config.push('\t<string>' + opts.app_id + '</string>');
	config.push('\t<key>tapjoy_id</key>');
	config.push('\t<string>' + opts.tapjoy_id + '</string>');
	config.push('\t<key>tapjoy_key</key>');
	config.push('\t<string>' + opts.tapjoy_key + '</string>');
	config.push('\t<key>tcp_host</key>');
	config.push('\t<string>' + opts.tcp_host + '</string>');
	config.push('\t<key>source_dir</key>');
	config.push('\t<string>' + opts.source_dir + '</string>');
	config.push('\t<key>code_path</key>');
	config.push('\t<string>' + opts.code_path + '</string>');
	config.push('\t<key>game_hash</key>');
	config.push('\t<string>' + opts.game_hash + '</string>');
	config.push('\t<key>sdk_hash</key>');
	config.push('\t<string>' + opts.sdk_hash + '</string>');
	config.push('\t<key>native_hash</key>');
	config.push('\t<string>' + opts.native_hash + '</string>');
	config.push('\t<key>apple_id</key>');
	config.push('\t<string>' + opts.apple_id + '</string>');
	config.push('\t<key>bundle_id</key>');
	config.push('\t<string>' + opts.bundle_id + '</string>');
	config.push('\t<key>version</key>');
	config.push('\t<string>' + opts.version + '</string>');
	config.push('\t<key>userdata_url</key>');
	config.push('\t<string>' + opts.userdata_url + '</string>');
	config.push('\t<key>services_url</key>');
	config.push('\t<string>' + opts.services_url + '</string>');
	config.push('\t<key>push_url</key>');
	config.push('\t<string>' + opts.push_url + '</string>');
	config.push('\t<key>contacts_url</key>');
	config.push('\t<string>' + opts.contacts_url + '</string>');
	config.push('\t<key>studio_name</key>');
	config.push('\t<string>' + opts.studio_name + '</string>');
	config.push('</dict>');
	config.push('</plist>');

	var fileData = config.join('\n');

	fs.writeFile(opts.filePath, fileData, function(err) {
		next(err);
	});
}

var LANDSCAPE_ORIENTATIONS = /(UIInterfaceOrientationLandscapeRight)|(UIInterfaceOrientationLandscapeLeft)/;
var PORTRAIT_ORIENTATIONS = /(UIInterfaceOrientationPortraitUpsideDown)|(UIInterfaceOrientationPortrait)/;

// Updates the given TeaLeafIOS-Info.plist file to include fonts
function updatePListFile(opts, next) {
	var f = ff(this, function() {
		fs.readFile(opts.plistFilePath, 'utf8', function(err, data) {
			logger.log("Updating Info.plist file: ", opts.plistFilePath);

			var contents = data.split('\n');

			// For each line,
			contents = contents.map(function(line) {
				// If it has an orientation to remove,
				if (line.match(LANDSCAPE_ORIENTATIONS) && opts.orientations.indexOf("landscape") == -1) {
					line = "";
				} else if (line.match(PORTRAIT_ORIENTATIONS) && opts.orientations.indexOf("portrait") == -1) {
					line = "";
				} else if (line.indexOf("13375566") >= 0) {
					line = line.replace("13375566", opts.version);
				}
				return line;
			});

			if (!opts.fonts || !opts.fonts.length) {
				logger.log("Fonts: Skipping PList update step because no fonts are to be installed");
			} else {
				// For each line,
				for (var i = 0; i < contents.length; ++i) {
					var line = contents[i];

					if (line.indexOf("UIAppFonts") >= 0) {
						logger.log("Updating UIAppFonts section: Injecting section members for " + opts.fonts.length + " font(s)");

						var insertIndex = i + 2;

						// If empty array exists currently,
						if (contents[i + 1].indexOf("<array/>") >= 0) {
							// Eliminate empty array and insert <array> tags
							contents[i + 1] = "\t\t<array>"; // TODO: Guessing at indentation here
							contents.splice(i + 2, 0, "\t\t</array>");
						} else if (contents[i + 1].indexOf("<array>") >= 0) {
							// No changes needed!
						} else {
							logger.warn("Unable to find <array> tag right after UIAppFonts section, so failing!");
							break;
						}

						for (var j = 0, jlen = opts.fonts.length; j < jlen; ++j) {
							contents.splice(insertIndex++, 0, "\t\t\t<string>" + path.basename(opts.fonts[j]) + "</string>");
						}

						// Done searching
						break;
					}
				}
			}

			for (var i = 0; i < contents.length; ++i) {
				var line = contents[i];

				if (line.indexOf("UIPrerenderedIcon") >= 0) {
					logger.log("Updating UIPrerenderedIcon section: Set to", (opts.renderGloss ? "true" : "false"));

					// NOTE: By default, necessarily, UIPrerenderedIcon=true
					if (opts.renderGloss) {
						// Pull out this and next line
						contents[i] = "";
						contents[i+1] = "";
					}
				}
			}

			//Change Bundle Diplay Name to title
			for (var i = 0; i < contents.length; i++) {
				if (/CFBundleDisplayName/.test(contents[i])) {
					var titleLine = contents[i+1];
					contents[i+1] = '<string>' + opts.title + '</string>';
					break;
				}
			}

			contents = contents.join('\n');

			fs.writeFile(opts.plistFilePath, contents, function(err) {
				next(err);
			});
		});
	});
	
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
				destDir: opts.destDir
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

function copyDir(srcPath, destPath, name) {
	wrench.copyDirSyncRecursive(path.join(srcPath, name), path.join(destPath, name));
	logger.log('copied', name, 'to', destPath);
}

function copyIOSProjectDir(srcPath, destPath, next) {
	logger.log('copying', srcPath, 'to', destPath);
	var parent = path.dirname(destPath);
	if (!fs.existsSync(parent)) {
		fs.mkdirSync(parent);
	}
	if (!fs.existsSync(destPath)) {
		fs.mkdirSync(destPath);
	}
	copyDir(srcPath, destPath, 'tealeaf');

	next();
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
			destDir: opts.destPath
		}, f.wait());

		var plistFile = path.join(opts.destPath, 'tealeaf/TeaLeafIOS-Info.plist');
		updatePListFile({
			plistFilePath: plistFile,
			fonts: manifest.ttf,
			orientations: manifest.supportedOrientations,
			renderGloss: manifest.ios.icons && manifest.ios.icons.renderGloss,
			version: manifest.ios.version,
			title: opts.title
		}, f.wait());

		writeConfigList({
			filePath: path.join(opts.destPath, "tealeaf/resources/config.plist"),

			remote_loading: 'false',
			tcp_port: 4747,
			code_port: 9201,
			screen_width: 480,
			screen_height: 800,
			code_host: 'localhost',
			entry_point: 'gc.native.launchClient',
			app_id: manifest.appID,
			tapjoy_id: manifest.ios.tapjoyId,
			tapjoy_key: manifest.ios.tapjoyKey,
			tcp_host: 'localhost',
			source_dir: '/',
			game_hash: gameHash,
			sdk_hash: sdkHash,
			native_hash: nativeHash,
			code_path: 'native.js.mp3',

			apple_id: manifest.ios.appleID,
			bundle_id: manifest.ios.bundleID,
			version: manifest.ios.version,

			services_url: servicesURL,
			push_url: servicesURL + "/push/%s/?key=%s&amp;version=%s",
			contacts_url: servicesURL + "/users/me/contacts/?key=%s",
			userdata_url: "",
			studio_name: manifest.studio && manifest.studio.name
		}, f.wait());
	}).error(function(code) {
		logger.log("Error while making iOS project file changes: " + code);
		process.exit(2);
	}).cb(next);
}

exports.build = function(builder, project, opts, next) {
	logger = new builder.common.Formatter("native-ios");

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
			logger.error("IPA mode selected but developer name was not provided.  You can add it to your config.json under the ios:developer key, or with the --developer command-line option.");
			process.exit(2);
		}
		logger.log("Using developer name:", developer);

		provision = argv.provision;
		if (typeof provision !== "string") {
			provision = manifest.ios && manifest.ios.provision;
		}
		if (typeof provision !== "string") {
			logger.error("IPA mode selected but .mobileprovision file was not provided.  You can add it to your config.json under the ios:provision key, or with the --provision command-line option.");
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
		makeIOSProject(builder, {
			project: project,
			destPath: destPath,
			debug: argv.debug,
			servicesURL: manifest.servicesURL,
			title: title,
			addonConfig: addonConfig
		}, f());
	}, function() {
		require(builder.common.paths.nativeBuild('native')).writeNativeResources(project, opts, f());
	}, function() {
		copyIcons(builder, manifest.ios.icons, destPath);
		copyFonts(builder, manifest.ttf, destPath);
		copySplash(builder, manifest, destPath, f.wait());
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
		logger.error(err);
		process.exit(2);
	});
}


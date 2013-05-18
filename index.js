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

var path = require("path");
var ff = require("ff");
var clc = require("cli-color");

exports.init = function (common) {
	console.log("Running install.sh");
	common.child("sh", ["install.sh"], {
		cwd: __dirname
	}, function () {
		console.log("Install complete");
	});

	exports.load(common);
}

exports.load = function (common) {
	common.config.set("ios:root", path.resolve(__dirname))
	common.config.write();

	require(common.paths.root('testapp')).registerTarget("native-ios", __dirname);
}

exports.testapp = function (common, opts, next) {
	var f = ff(this, function () {
		common.child('open', [path.join(__dirname, './tealeaf/TeaLeafIOS.xcodeproj')], {}, f.wait());
	}, function() {
		require(common.paths.root('serve')).cli();
	}).error(function(err) {
		console.log(clc.red("ERROR"), err);
	}).cb(next);
}


//// Addons

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

var installAddons = function (builder, project, opts, next) {
	var logger = new builder.common.Formatter('iOS Addons');

	// TODO: Not written yet

	var f = ff(this, function () {
		// For each addon,
		var addons = project && project.manifest && project.manifest.addons;
		if (addons) {
			for (var ii = 0; ii < addons.length; ++ii) {
				var addon = addons[ii];

				logger.log("Installing addon: ", addon);
				var addon_path = path.join("../../", addon, "/ios");
			}
		}

	}, function() {
	}).error(function(err) {
		logger.error(err);
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
			fs.exists(path.join(iOSPath, submodules[i]), group.slotPlain());
		}
	}, function(results) {
		var allGood = results.every(function(element, index) {
			if (!element) {
				logger.error("ERROR: Submodule " + path.dirname(submodules[index]) + " not found");
			}
			return element;
		});

		if (!allGood) {
			f.fail("One of the submodules was not found.  Make sure you have run submodule update --init on your clone of the iOS repo");
		}
	}).cb(next);
}

exports.build = function (common, builder, project, opts, next) {
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
			logger.error("ERROR: IPA mode selected but developer name was not provided.  You can add it to your config.json under the ios:developer key, or with the --developer command-line option.");
			process.exit(2);
		}
		logger.log("Using developer name:", developer);

		provision = argv.provision;
		if (typeof provision !== "string") {
			provision = manifest.ios && manifest.ios.provision;
		}
		if (typeof provision !== "string") {
			logger.error("ERROR: IPA mode selected but .mobileprovision file was not provided.  You can add it to your config.json under the ios:provision key, or with the --provision command-line option.");
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

	var f = ff(this, function() {
		validateSubmodules(f());
	}, function() {
		makeIOSProject({
			builder: builder,
			project: project,
			destPath: destPath,
			debug: argv.debug,
			servicesURL: manifest.servicesURL,
			title: title
		}, f());
		require(common.paths.nativeBuild('native')).writeNativeResources(project, opts, f());
	}, function() {
		finishCopy(manifest, destPath, f());
	}, function() {
		// If IPA generation was requested,
		if (argv.ipa) {
			// TODO: Debug mode is currently turned off because it does not build
			require('./xcode.js').buildIPA(builder, path.join(destPath, '/tealeaf'), manifest.shortName, false, provision, developer, manifest.shortName+'.ipa', f());
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
		logger.error('ERROR:', err);
		process.exit(2);
	});
}


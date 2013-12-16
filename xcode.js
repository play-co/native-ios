var path = require('path');
var ff = require('ff');
var exec = require('child_process').exec;

var CONFIG_RELEASE = "Release";
var CONFIG_DEBUG = "Debug";

exports.buildApp = function (builder, appName, targetSDK, configurationName, projectPath, next) {
	var f = ff(function() {
		var args = [
			'-target',
			appName,
			'-sdk',
			targetSDK,
			'-configuration',
			configurationName,
			'-jobs',
			8,
		];

		console.log("Invoking xcodebuild with parameters:", JSON.stringify(args, undefined, 4));

		builder.common.spawn('xcodebuild', args, {
			cwd: path.resolve(projectPath)
		}, f.slotPlain());
	}, function(code) {
		console.log("xcodebuild exited with code", code);

		if (code != 0) {
			f.fail("Build failed.  Is the manifest.json file properly configured?");
		}
	}).cb(next);
};

exports.signApp = function (builder, projectPath, appName, outputIPAPath, configurationName, developerName, provisionPath, next) {
	var f = ff(function() {

		var args = [
			'-sdk',
			'iphoneos',
			'PackageApplication',
			'-v',
			path.resolve(path.join(projectPath, 'build/'+configurationName+'-iphoneos/'+appName+'.app')),
			'-o',
			path.resolve(outputIPAPath),
			'--sign',
			'iPhone Developer: ' + developerName,
			'--embed',
			path.resolve(provisionPath)
		];

		console.log("Invoking xcrun with parameters:", JSON.stringify(args, undefined, 4));

		builder.common.child('xcrun', args, {
			cwd: path.resolve(projectPath)
		}, f.slotPlain());
	}, function(code) {
		console.log("xcrun exited with code", code);

		if (code != 0) {
			f.fail("Unable to sign the app.  Are your provision profile and developer key active?");
		}
	}).cb(next);
};

// lifted (and edited) from: http://st-on-it.blogspot.com/2011/05/how-to-read-user-input-with-nodejs.html
var ask = function(question, condition, callback) {
	var stdin = process.stdin, stdout = process.stdout;
	stdin.resume();
	stdout.write(question + ": ");
	stdin.once('data', function(data) {
		data = data.toString().trim();
		if (condition(data)) {
			callback(data);
		} else {
			ask(question, condition, callback);
		}
	});
};

// This function produces an IPA file by calling buildApp and signApp
var buildIPA = function(targetSDK, builder, projectPath, appName, isDebug, provisionPath, developerName, outputIPAPath, next) {
	console.log("using sdk:", targetSDK);
	var configurationName = isDebug ? CONFIG_DEBUG : CONFIG_RELEASE;
	var f = ff(function() {
		exports.buildApp(builder, appName, targetSDK, configurationName, projectPath, f());
	}, function() {
		exports.signApp(builder, projectPath, appName, outputIPAPath, configurationName, developerName, provisionPath, f());
	}).error(function(err) {
		console.error('ERROR:', err);
		process.exit(2);
	}).cb(next);
};

// This command figures out which SDKs are available, selects one, and calls buildIPA
exports.buildIPA = function(builder, projectPath, appName, isDebug, provisionPath, developerName, outputIPAPath, chooseSDK, next) {
	exec('xcodebuild -version -sdk', function(error, data, stderror) {
		var SDKs = [];
		if (error) {
			console.log("Error building SDK list:", error, stderror);
		} else {
			var sdkstart = data.indexOf('iphoneos');
			while (sdkstart != -1) {
				var sdkend = data.indexOf(')', sdkstart);
				var sdkstr = data.slice(sdkstart, sdkend);
				SDKs.push(sdkstr);
				console.log("found sdk:", sdkstr);
				sdkstart = data.indexOf('iphoneos', sdkend);
			}
			SDKs.sort().reverse();
			if (chooseSDK && SDKs.length > 1) {
				return ask("choose sdk [default: " + SKDs[0] + "]", function(sdk) {
					if (sdk != "" && SDKs.indexOf(sdk) == -1) {
						console.log(sdk, "is not available");
						console.log("options:", SDKs);
						return false;
					}
					return true;
				}, function(sdk) {
					buildIPA(sdk || SDKS[0], builder, projectPath, appName, isDebug,
						provisionPath, developerName, outputIPAPath, next);
				});
			}
		}
		buildIPA(SDKs.length ? SDKs[0] : 'iphoneos6.0', builder, projectPath,
			appName, isDebug, provisionPath, developerName, outputIPAPath, next);
	});
};


var path = require('path');
var ff = require('ff');
var fs = require('fs');
var exec = require('child_process').exec;

var CONFIG_RELEASE = "Release";
var CONFIG_DEBUG = "Debug";

var HOME_PATH = process.env.HOME
			|| process.env.HOMEPATH
			|| process.env.USERPROFILE;

var SCRIPT_PATH = path.join(__dirname, 'scripts');
var PROFILES_PATH = path.join(HOME_PATH, 'Library', 'MobileDevice', 'Provisioning Profiles');

exports.buildApp = function (builder, appName, targetSDK, configurationName, projectPath, signingIdentity, mobileProvisionPath, outputIPAPath, next) {
	var f = ff(function() {
		var args = [
			'build',
			'-target', appName,
			'-sdk', targetSDK,
			'-configuration', configurationName,
			'-jobs', 8,
			'CODE_SIGN_IDENTITY=' + signingIdentity + '',
			'PROVISIONING_PROFILE=' + mobileProvisionPath + ''
		];

		console.log("Invoking xcodebuild with parameters:", args.map(function (arg) {
			return /["']|\s/.test(arg) ? '"' + arg + '"' : arg
		}).join(' '));

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

exports.createIPA = function (builder, projectPath, appName, outputIPAPath, configurationName, next) {
	var f = ff(function() {

		var args = [
			'-sdk',
			'iphoneos',
			'PackageApplication',
			'-v',
			path.resolve(path.join(projectPath, 'build/'+configurationName+'-iphoneos/'+appName+'.app')),
			'-o',
			path.resolve(outputIPAPath)
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

function installProvisioningProfile(mobileProvisionPath, cb) {
	if (/[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9a-f]{12}/.test(mobileProvisionPath.toUpperCase())) {
		// looks like a UUID already!
		return cb(null, mobileProvisionPath.toUpperCase());
	}

	if (!fs.existsSync(mobileProvisionPath)) {
		logger.warn('Specified provisioning profile not found');
		return cb(null, '');
	}

	if (!fs.existsSync(PROFILES_PATH)) {
		logger.warn("Couldn't locate provisioning profiles folder (looked in", PROFILES_PATH + ")");
		return cb(null, '');
	}

	exec('./extract-provisioning-profile-uuid.sh "' + mobileProvisionPath + '"', {cwd: SCRIPT_PATH}, function (error, uuid, stderror) {
		if (error || !uuid) {
			return cb(error || new Error("No UUID found in provisioning profile"), uuid);
		}

		uuid = uuid.trim();

		logger.info('extracted uuid', uuid, 'from', mobileProvisionPath);

		var destPath = path.join(PROFILES_PATH, uuid + '.mobileProvision');
		if (fs.existsSync(destPath)) {
			logger.info('Requested provisioning profile found at', destPath);
			return cb(null, uuid);
		}

		// install the .mobileProvision file
		fs.createReadStream(mobileProvisionPath)
			.pipe(fs.createWriteStream(destPath))
			.on('error', function (e) {
				cb && cb(e);
				cb = null;
			})
			.on('close', function () {
				logger.info('Installed provisioning profile at', destPath);
				cb && cb(null, uuid);
				cb = null;
			});
	});
}

// This function produces an IPA file by calling buildApp and createIPA
var buildIPA = function(targetSDK, builder, projectPath, appName, isDebug, mobileProvisionPath, signingIdentity, outputIPAPath, next) {
	console.log("using sdk:", targetSDK);
	var configurationName = isDebug ? CONFIG_DEBUG : CONFIG_RELEASE;
	var f = ff(function() {
		installProvisioningProfile(mobileProvisionPath, f());
	}, function (mobileProvisionUUID) {
		exports.buildApp(builder, appName, targetSDK, configurationName, projectPath, signingIdentity, mobileProvisionUUID, outputIPAPath, f());
	}, function() {
		exports.createIPA(builder, projectPath, appName, outputIPAPath, configurationName, f());
	}).error(function(err) {
		console.error('ERROR:', err);
		process.exit(2);
	}).cb(next);
};

// This command figures out which SDKs are available, selects one, and calls buildIPA
exports.buildIPA = function(builder, projectPath, appName, isDebug, mobileProvisionPath, signingIdentity, outputIPAPath, chooseSDK, next) {
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
						mobileProvisionPath, signingIdentity, outputIPAPath, next);
				});
			}
		}

		buildIPA(SDKs.length ? SDKs[0] : 'iphoneos6.0', builder, projectPath,
			appName, isDebug, mobileProvisionPath, signingIdentity, outputIPAPath, next);
	});
};


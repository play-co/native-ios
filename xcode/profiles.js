var path = require('path');
var ff = require('ff');
var fs = require('fs');
var exec = require('child_process').exec;

var HOME_PATH = process.env.HOME
		|| process.env.HOMEPATH
		|| process.env.USERPROFILE;

var SCRIPT_PATH = path.join(__dirname, '..', 'scripts');

var PROFILES_PATH = path.join(HOME_PATH, 'Library', 'MobileDevice', 'Provisioning Profiles');

exports.installProvisioningProfile = function (mobileProvisionPath, cb) {

	var f = ff(function () {
		console.error('Looking for', mobileProvisionPath);

		// 1. get the UUID
		if (/[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}/.test(mobileProvisionPath.toUpperCase())) {
			// looks like a UUID already!
			f(mobileProvisionPath.toUpperCase());
		} else {
			if (!fs.existsSync(mobileProvisionPath)) {
				console.error('Provisioning profile not found', mobileProvisionPath);
				return f.succeed();
			}

			if (!fs.existsSync(PROFILES_PATH)) {
				console.error("Couldn't locate provisioning profiles folder (looked in", PROFILES_PATH + ")");
				return f.succeed();
			}

			exports.getUUID(mobileProvisionPath, f());
		}
	}, function (uuid) {
		// 2. check if the UUID is installed
		var destPath = path.join(PROFILES_PATH, uuid + '.mobileProvision');
		if (fs.existsSync(destPath)) {
			console.error('Requested provisioning profile found at', destPath);
			return f({
				uuid: uuid,
				path: destPath,
				installed: true
			});
		}

		// 3. install the .mobileProvision file if not
		var next = f();
		fs.createReadStream(mobileProvisionPath)
			.pipe(fs.createWriteStream(destPath))
			.on('error', function (e) {
				next && next(e);
				next = null;
			})
			.on('close', function () {
				console.error('Installed provisioning profile at', destPath);
				next && next(null, {
					uuid: uuid,
					path: destPath,
					installed: true
				});
				next = null;
			});
	}).cb(cb);
}

exports.getUUID = function (mobileProvisionPath, cb) {
	exports.getProp(mobileProvisionPath, 'UUID', function (err, uuid) {
		if (err || !uuid) {
			return cb(err || new Error("No UUID found in provisioning profile"), uuid);
		}

		uuid = uuid.trim();
		console.error('extracted uuid', uuid, 'from', mobileProvisionPath);

		cb && cb(null, uuid);
	});
}

exports.getProp = function (mobileProvisionPath, prop, cb) {
	var cmd = path.join(SCRIPT_PATH, 'read-provisioning-profile.sh')
			+ ' "' + mobileProvisionPath + '"'
			+ ' "' + prop + '"';

	exec(cmd, function (err, res, stderror) {
		cb(err, res && res.trim());
	});
}

exports.getProvisioningProfileInfo = function (mobileProvision, cb) {
	var f = ff(function () {
		exports.installProvisioningProfile(mobileProvision, f());
	}, function (info) {
		if (!info) {
			return f.fail();
		}

		f(info);

		if (info.installed) {
			exports.getProp(info.path, 'Name', f());
		}
	}, function (info, name) {
		if (name) {
			info.name = name;
		}

		f(info);
	}).cb(cb);
}

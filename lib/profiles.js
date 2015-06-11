var path = require('path');
var Promise = require('bluebird');
var fs = require('fs-extra');
var exec = require('child_process').exec;

var copyFile = Promise.promisify(fs.copy);

var HOME_PATH = process.env.HOME
    || process.env.HOMEPATH
    || process.env.USERPROFILE;

var SCRIPT_PATH = path.join(__dirname, '..', 'scripts');

var PROFILES_PATH = path.join(HOME_PATH, 'Library', 'MobileDevice', 'Provisioning Profiles');

function ProfileDoesNotExistError(message) {
  this.message = message;
  this.name = 'ProfileDoesNotExistError';
  Error.captureStackTrace(this, ProfileDoesNotExistError);
}

ProfileDoesNotExistError.prototype = Object.create(Error.prototype);
ProfileDoesNotExistError.prototype.constructor = ProfileDoesNotExistError;

exports.ProfileDoesNotExistError = ProfileDoesNotExistError;


exports.installProvisioningProfile = function (mobileProvisionPath) {

  if (!mobileProvisionPath || typeof mobileProvisionPath !== 'string') {
    throw new ProfileDoesNotExistError('No provisioning profile specified, use --provision [filename|uuid]');
  }

  return Promise
    // 1. get the UUID
    .try(function () {
      console.error('Looking for', mobileProvisionPath);

      if (/[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}/.test(mobileProvisionPath.toUpperCase())) {
        // looks like a UUID already!
        return mobileProvisionPath.toUpperCase();
      } else {
        if (!fs.existsSync(mobileProvisionPath)) {
          throw new ProfileDoesNotExistError('Provisioning profile not found at ' + mobileProvisionPath);
        }

        if (!fs.existsSync(PROFILES_PATH)) {
          throw new ProfileDoesNotExistError("Couldn't locate provisioning profiles folder (looked in " + PROFILES_PATH + ")");
        }

        return exports.getUUID(mobileProvisionPath);
      }
    })
    // 2. check if the UUID is already installed
    .then(function (uuid) {
      var destPath = path.join(PROFILES_PATH, uuid + '.mobileProvision');
      if (fs.existsSync(destPath)) {
        console.error('Requested provisioning profile found at', destPath);
        return {
          uuid: uuid,
          path: destPath
        };
      }

      // 3. install the .mobileProvision file if not
      return copyFile(mobileProvisionPath, destPath)
        .then(function () {
          console.error('Installed provisioning profile at', destPath);
          return {
            uuid: uuid,
            path: destPath
          };
        });
    });
};

exports.getUUID = function (mobileProvisionPath) {
  return exports
    .getProp(mobileProvisionPath, 'UUID')
    .then(function (uuid) {
      if (!uuid) {
        throw new Error("No UUID found in provisioning profile");
      }

      uuid = uuid.trim();
      console.error('extracted uuid', uuid, 'from', mobileProvisionPath);
      return uuid;
    });
};

exports.getProp = function (mobileProvisionPath, prop) {
  var cmd = path.join(SCRIPT_PATH, 'read-provisioning-profile.sh')
      + ' "' + mobileProvisionPath + '"'
      + ' "' + prop + '"';

  return new Promise(function (resolve, reject) {
    exec(cmd, function (err, stdout, stderr) {
      if (err) {
        reject(err);
      } else {
        resolve(stdout && stdout.trim());
      }
    });
  });
};

exports.getProvisioningProfileInfo = function (mobileProvision) {
  return exports
    .installProvisioningProfile(mobileProvision)
    .then(function (info) {
      // extract profile name from file
      return exports.getProp(info.path, 'Name')
        .then(function (name) {
          info.name = name;
          return info;
        });
    });
};

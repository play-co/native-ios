var path = require('path');
var Promise = require('bluebird');

var exec = function (command) {
  var _exec = require('child_process').exec;
  return new Promise(function (resolve, reject) {
    _exec(command, function (code, stdout, stderr) {
      if (code) {
        reject([code, stdout, stderr]);
      } else {
        resolve([stdout, stderr]);
      }
    });
  });
};

var spawn = require('child_process').spawn;
var profiles = require('./profiles');

var CONFIG_RELEASE = "Release";
var CONFIG_DEBUG = "debug";


function spawnWithLogger(api, name, args, opts) {
  return new Promise(function (resolve, reject) {
    var logger = api.logging.get(name);
    logger.log(name, args.join(' '));
    var streams = logger.createStreams(['stdout'], {silent: true});
    var child = spawn(name, args, opts);
    child.stdout.pipe(streams.stdout);
    child.stderr.pipe(streams.stdout);
    child.on('close', function (err) {
      if (err) {
        logger.log(streams.get('stdout'));
        reject(err);
      } else {
        resolve();
      }
    });
  });
}

function buildApp (api, app, config, sdk, provisionUUID) {
  var args = [
    '-target', 'TeaLeafIOS',
    '-sdk', sdk,
    '-configuration', config.debug ? CONFIG_DEBUG : CONFIG_RELEASE,
    '-jobs', 8,
    'CODE_SIGN_IDENTITY=' + config.signingIdentity,
    'PROVISIONING_PROFILE=' + provisionUUID.toLowerCase()
  ];

  var opts = {
    cwd: path.resolve(config.xcodeProjectPath)
  };

  api.logging.get('ios-build').log('building xcode project...');
  return spawnWithLogger(api, 'xcodebuild', args, opts);
}

function createIPA(api, app, config) {
  var args = [
    '-sdk', 'iphoneos',
    'PackageApplication',
    '-v', path.resolve(path.join(config.xcodeProjectPath,
      'build',
      (config.debug ? CONFIG_DEBUG : CONFIG_RELEASE) + '-iphoneos',
      'TeaLeafIOS.app')),
    '-o', path.resolve(config.ipaPath)
  ];

  var opts = {
    cwd: path.resolve(config.xcodeProjectPath)
  };

  return spawnWithLogger(api, 'xcrun', args, opts);
}

exports.getSDKVersions = function () {
  return exec('xcodebuild -version -sdk')
    .spread(function(stdout, stderr) {
      return stdout
          .match(/\(iphoneos(.*?)\)/g)
          .map(function (version) { return version.substring(1, version.length - 1); })
          .sort()
          .reverse();
    }, function (err) {
      var code = err[0];
      var stderr = err[2];
      throw new Error("Error building SDK list: 'xcodebuild -version -sdk' exited with code " + code + ".\n" + stderr);
    });
};

// This command figures out which SDKs are available, selects one, and calls buildIPA
exports.buildIPA = function (api, app, config) {
  return exports
    .getSDKVersions()
    .then(function (versions) {
      var sdk = versions[0];
      if (config.sdk) {
        if (versions.indexOf(config.sdk) >= 0) {
          sdk = config.sdk;
        } else {
          logger.warn('iOS SDK version', config.sdk, 'not found. Valid options are:');
          versions.forEach(function (version) {
            logger.warn('  ', version);
          });
          logger.warn('Using version', sdk);
        }
      }

      if (!sdk) {
        throw new Error('No valid iOS SDKs found. Please ensure XCode is setup properly.');
      }

      return [
        sdk,
        profiles.installProvisioningProfile(config.provisionPath)
      ];
    })
    .all()
    .spread(function (sdk, provisioningProfile) {
      return buildApp(api, app, config, sdk, provisioningProfile.uuid);
    })
    .then(function () {
      return createIPA(api, app, config);
    });
};


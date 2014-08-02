var path = require('path');
var ff = require('ff');
var exec = require('child_process').exec;
var spawn = require('child_process').spawn;
var profiles = require('./profiles');

var CONFIG_RELEASE = "Release";
var CONFIG_DEBUG = "debug";


function spawnWithLogger(api, name, args, opts, cb) {
  var logger = api.logging.get(name);
  logger.log(name, args.join(' '));
  var child = spawn(name, args, opts);
  child.stdout.pipe(logger, {end: false});
  child.stderr.pipe(logger, {end: false});
  child.on('close', function (err) {
    cb(err);
  });
}

function buildApp (api, app, config, sdk, provisionUUID, cb) {
  var f = ff(function() {
    var args = [
      '-target', 'TeaLeafIOS',
      '-sdk', sdk,
      '-configuration', config.debug ? CONFIG_DEBUG : CONFIG_RELEASE,
      '-jobs', 8,
      'CODE_SIGN_IDENTITY=' + config.signingIdentity,
      'PROVISIONING_PROFILE=' + provisionUUID
    ];

    spawnWithLogger(api, 'xcodebuild', args, {
      cwd: path.resolve(config.xcodeProjectPath)
    }, f());
  }).cb(cb);
};

function createIPA(api, app, config, cb) {
  var f = ff(function() {

    var args = [
      '-sdk', 'iphoneos',
      'PackageApplication',
      '-v', path.resolve(path.join(config.xcodeProjectPath,
        'build',
        (config.debug ? CONFIG_DEBUG : CONFIG_RELEASE) + '-iphoneos',
        'TeaLeafIOS.app')),
      '-o', path.resolve(config.ipaPath)
    ];

    spawnWithLogger(api, 'xcrun', args, {
      cwd: path.resolve(config.xcodeProjectPath)
    }, f());
  }).cb(cb);
};

// This function produces an IPA file by calling buildApp and signApp
var buildIPA = function(api, app, config, sdk, cb) {
  var f = ff(function() {
    profiles.installProvisioningProfile(config.provisionPath, f());
  }, function (provisioningProfile) {
    buildApp(api, app, config, sdk, provisioningProfile.uuid, f());
  }, function() {
    createIPA(api, app, config, f());
  }).cb(cb);
};

exports.getSDKVersions = function (cb) {
  exec('xcodebuild -version -sdk', function(error, stdout, stderror) {
    var SDKs = [];
    if (error) { return cb(new Error("Error building SDK list: " + stderror)); }

    var matches = stdout.match(/\(iphoneos(.*?)\)/g);
    cb(null, matches
        .map(function (version) { return version.substring(1, version.length - 1); })
        .sort()
        .reverse());
  });
}

// This command figures out which SDKs are available, selects one, and calls buildIPA
exports.buildIPA = function (api, app, config, cb) {
  exports.getSDKVersions(function (err, versions) {
    if (err) { return cb(err); }

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
      return cb(new Error('No valid iOS SDKs found. Please ensure XCode is setup properly.'));
    }

    buildIPA(api, app, config, sdk, cb);
  });
};


var path = require('path');
var fs = require('fs-extra');
var clc = require('cli-color');
var updatePlist = require('./lib/updatePlist');
var xcodeUtil = require('./lib/xcodeUtil');
var copyResources = require('./lib/copyResources');
var exec = require('child_process').exec;
var Rsync = require('rsync');
var ff = require('ff');

var iosVersion = require('./package.json').version;

var logger;

var getModuleConfig = function(modulePath) {
  var config = null;
  var configPath = path.join(modulePath, 'config.json');
  if (fs.existsSync(configPath)) {
    try {
      var rawConfig = fs.readFileSync(configPath, 'utf-8');
      config = JSON.parse(rawConfig);
    } catch (e) {
      throw new Error('Error parsing config ' + configPath);
    }
  } else {
    throw new Error('No ios config found for', modulePath);
  }

  return config;
};

var copyFilesToProject = function(srcPath, destPath, files) {
  files.forEach(function(file) {
    var srcFile = path.join(srcPath, file);
    var destFile = path.join(destPath, file);
    fs.copySync(srcFile, destFile);
  });
};


var installModule = function (app, config, modulePath, xcodeProject, infoPlist, cb) {
  try {
    var moduleConfig = getModuleConfig(modulePath);
  } catch (e) {
    return cb(e);
  }

  xcodeProject.installModule(modulePath, moduleConfig, function (err, filesToCopy) {
    if (!err) {
      copyFilesToProject(modulePath, xcodeProject.path, filesToCopy);
      if (moduleConfig.plist) {
        infoPlist.add(app.manifest, moduleConfig.plist);
      }
      cb(null);
    } else {
      cb(err);
    }
  });
};

var copyIOSProjectDir = function(srcPath, destPath, cb) {
  var parent = path.dirname(destPath);
  if (!fs.existsSync(parent)) {
    fs.mkdirSync(parent);
  }

  if (!fs.existsSync(destPath)) {
    fs.mkdirSync(destPath);
  }

  var rsync = new Rsync()
    .flags('a')
    .source(srcPath)
    .destination(destPath)
    .execute(cb);
};

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

function updateInfoPlist(app, config, plist) {
  var manifest = app.manifest;

  var raw = plist.getRaw();

  // Remove unsupported modes
  var orient = manifest.supportedOrientations;
  if (orient.indexOf("landscape") == -1) {
    logger.log("Orientations: Removing landscape support");
    removeKeysForObjects(raw, ["UISupportedInterfaceOrientations", "UISupportedInterfaceOrientations~ipad"],
      ["UIInterfaceOrientationLandscapeRight", "UIInterfaceOrientationLandscapeLeft"]);
  }
  if (orient.indexOf("portrait") == -1) {
    logger.log("Orientations: Removing portrait support");
    removeKeysForObjects(raw, ["UISupportedInterfaceOrientations", "UISupportedInterfaceOrientations~ipad"],
      ["UIInterfaceOrientationPortrait", "UIInterfaceOrientationPortraitUpsideDown"]);
  }

  // Update the version numbers
  raw.CFBundleShortVersionString = manifest.ios.version;
  raw.CFBundleVersion = manifest.ios.version;

  // If RenderGloss enabled,
  if (manifest.ios.icons && manifest.ios.icons.renderGloss) {
    // Note: Default is for Xcode to render it for you
    logger.log("RenderGloss: Removing pre-rendered icon flag");
    delete raw.UIPrerenderedIcon;
    //delete raw.CFBundleIcons.CFBundlePrimaryIcon.UIPrerenderedIcon;
  }

  raw.CFBundleDisplayName = app.manifest.title;
  raw.CFBundleIdentifier = config.bundleID;
  raw.CFBundleName = config.bundleID;

  // For each URLTypes array entry,
  var found = 0;
  for (var ii = 0; ii < raw.CFBundleURLTypes.length; ++ii) {
    var obj = raw.CFBundleURLTypes[ii];

    // If it's the URLName one,
    if (obj.CFBundleURLName) {
      obj.CFBundleURLName = config.bundleID;
      ++found;
    }

    // If it's the URLSchemes one,
    if (obj.CFBundleURLSchemes) {
      // Note this blows away all the array entries
      obj.CFBundleURLSchemes = [config.bundleID];
      ++found;
    }
  }

  if (found != 2) {
    throw new Error("Unable to update URLTypes");
  }
}

function updateConfigPlist(app, config, plist) {

  var gameVersion = require(path.join(app.paths.root, 'manifest.json')).version;

  plist.add(app.manifest, {
      remote_loading: 'false',
      tcp_port: 4747,
      code_port: 9201,
      screen_width: 480,
      screen_height: 800,
      code_host: 'localhost',
      entry_point: 'devkit.native.launchClient',
      app_id: app.manifest.appID || "example.appid",
      tcp_host: 'localhost',
      source_dir: '/',
      game_hash: gameVersion,
      sdk_hash: config.sdkVersion,
      native_hash: iosVersion,
      code_path: 'native.js',
      studio_name: (app.manifest.studio && app.manifest.studio.name) || "example.studio",
      debug_build: config.debug,

      apple_id: app.manifest.ios && app.manifest.ios.appleID || "example.appleid",
      bundle_id: config.bundleID,
      version: config.version
    });
}

function buildXcodeProject(api, app, config, cb) {
  var f = ff(function() {
    var srcDir;
    if (config.srcXcodeProjectPath) {
      srcDir = config.srcXcodeProjectPath;
    } else {
      srcDir = __dirname + '/tealeaf/';
    }

    copyIOSProjectDir(srcDir, config.xcodeProjectPath, f());
  }, function() {
    xcodeUtil.getXcodeProject(config.xcodeProjectPath, f());
  }, function (_xcodeProject) {
    xcodeProject = _xcodeProject;

    infoPlist = updatePlist.getInfoPlist(config.xcodeProjectPath);
    configPlist = updatePlist.get(path.join(config.xcodeProjectPath, 'resources', 'config.plist'));
    updateInfoPlist(app, config, infoPlist);
    updateConfigPlist(app, config, configPlist);

    Object.keys(app.modules).map(function (moduleName) {
      return app.modules[moduleName].extensions.ios;
    }).filter(function (iosExtension) {
      return !!iosExtension;
    }).forEach(function(iosExtension) {
      installModule(app, config, iosExtension, xcodeProject, infoPlist, f());
    });

    copyResources.copyIcons(api, app, config, f());
    copyResources.copySplash(api, app, config, f());
  }, function() {
    xcodeProject.installModule(null, {
      frameworks: [
        'StoreKit',
        'AddressBook',
        'libresolv.dylib',
        'CoreTelephony',
        'Security',
        'MobileCoreServices',
        'SystemConfiguration',
        'MessageUI',
        'CFNetwork',
        'AudioToolbox',
        'OpenAL',
        'AVFoundation',
        'AdSupport',
        'CoreText'
      ]
    }, f());

    xcodeProject.addResourceFiles('resources.bundle', f());
  }, function () {
    xcodeProject.write(f());
    infoPlist.write(f());
    configPlist.write(f());
  }).cb(cb);
};

exports.build = function(api, app, config, cb) {
  logger = api.logging.get('ios-build');

  var infoPlist;
  var configPlist;

  if (!config.xcodeProjectPath) {
    config.xcodeProjectPath = path.join(config.outputPath, 'xcodeproject');
  }

  var f = ff(function () {


    if (!config.repack) {
      buildXcodeProject(api, app, config, f());
    }
  }, function () {
    if (config.ipaPath) {
      require('./lib/ipa')
        .buildIPA(api, app, config, f.wait());
    }
  }, function () {
    var projectDir = xcodeUtil.getXcodeProjectDir(config.xcodeProjectPath);

    logger.log("built", clc.yellowBright(config.bundleID));

    if (config.ipaPath) {
      logger.log("saved to " + clc.blueBright(config.ipaPath));
    } else {
      logger.log("xcode project file is at", clc.blueBright(projectDir));
      logger.log("build output at", clc.blueBright(config.xcodeProjectPath));
    }

    if (config.open) {
      // open the xcode project
      logger.log('opening xcode project...');
      exec('open "' + projectDir + '"');
    }

    if (config.reveal) {
      // show the ipaFile or the project in Finder
      if (config.ipaPath) {
        logger.log('revealing ipa file...');
        exec('open --reveal "' + config.ipaPath + '"');
      } else {
        logger.log('revealing xcode project...');
        exec('open --reveal "' + projectDir + '"');
      }
    }
  }).cb(cb);
}

//All of these (and the plist copying), should go into "externalProject"
//copy native resources
//update bundle id in plist
//update orientation in plist
//update version in plist
//update title
//copy urltypes from manifest.json
//add required frameworks to externalProject, add libweebyUnity.a, add weeby.h?
//rename installModule
//ios 5.0
//linker flag -ObjC
//use clang/libc++
//build the library project and copy it over
//put the deps in a file that we read?
//it would be nice to make all projects use this library project instead of
//copying the whole thing

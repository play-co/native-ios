var path = require('path');
var fs = require('fs-extra');
var Promise = require('bluebird');

var unlink = Promise.promisify(fs.unlink);
var copyFile = Promise.promisify(fs.copy);
var exists = function (filename) {
  return new Promise(function (resolve, reject) {
    fs.exists(filename, function (exists) {
      resolve(exists);
    });
  });
};

var unlinkIfExists = function (filename) {
  return unlink(filename)
    .catch(function (e) {
      if (e.code !== 'ENOENT') {
        throw e;
      }
    });
};

var IOS_ICON_SIZES = ['57', '72', '76', '114', '120', '144', '152'];
var IOS_7_ICON_SIZES = ['76', '120', '152'];
var SPLASHES = [
  { key: 'portrait480', outFile: 'Default.png', outSize: '320x480' },
  { key: 'portrait960', outFile: 'Default@2x.png', outSize: '640x960'},
  { key: 'portrait1024', outFile: 'Default-Portrait~ipad.png', outSize: '768x1024'},
  { key: 'portrait1136', outFile: 'Default-568h@2x.png', outSize: '640x1136'},
  { key: 'portrait1334', outFile: 'Default-375w-667h@2x~iphone.png', outSize: '750x1334'},
  { key: 'portrait2048', outFile: 'Default-Portrait@2x~ipad.png', outSize: '1536x2048'},
  { key: 'portrait2208', outFile: 'Default-414w-736h@3x~iphone.png', outSize: '1242x2208'},
  { key: 'landscape768', outFile: 'Default-Landscape~ipad.png', outSize: '1024x768'},
  { key: 'landscape1242', outFile: 'Default-Landscape@3x.png', outSize: '2208x1242'},
  { key: 'landscape1536', outFile: 'Default-Landscape@2x~ipad.png', outSize: '2048x1536'}
];


exports.copyIcons = function (api, app, config) {
  var logger = api.logging.get('ios-build');
  var icons = app.manifest.ios && app.manifest.ios.icons;
  var tasks = [];
  var appPathToString = function (appPath) {
    return path.relative(app.paths.root, path.resolve(appPath));
  };

  if (icons) {
    IOS_ICON_SIZES.forEach(function(size) {
      var isIOS7Icon = IOS_7_ICON_SIZES.indexOf(size) >= 0;
      var targetPath = path.join(config.xcodeProjectPath, 'Images.xcassets/AppIcon.appiconset', 'icon' + size + '.png');
      var targetOldPath = path.join(config.xcodeProjectPath, 'icon' + size + '.png');
      var iconPath = icons[size];
      if (iconPath) {
        iconPath = path.join(app.paths.root, iconPath);
        tasks.push(exists(iconPath)
          .then(function (exists) {
            if (!exists) {
              logger.warn('Icon', iconPath, 'does not exist.');
              return isIOS7Icon && unlinkIfExists(targetPath);
            }

            logger.log("Icons: Copying", appPathToString(iconPath), "to", appPathToString(targetPath));
            !isIOS7Icon && logger.log("Icons: Copying", appPathToString(iconPath), "to", appPathToString(targetOldPath));

            return Promise.all([
              copyFile(iconPath, targetPath),
              !isIOS7Icon && copyFile(iconPath, targetOldPath)
            ]);
          }));
      } else {
        logger.warn('Icon size', size, 'is not specified under manifest.json:ios:icons.');
      }
    });
  } else {
    logger.warn('No icons specified under "ios".');
  }

  return Promise.all(tasks);
};

exports.copySplash = function (api, app, config) {
  var manifest = app.manifest;
  var rootPath = app.paths.root;

  if (!manifest.splash) {
    logger.warn('No "splash" section provided in the manifest.json');
    return;
  }

  var universalSplash;
  if (manifest.splash.universal) {
    universalSplash = path.resolve(rootPath, manifest.splash.universal);
  }

  var appPathToString = function (appPath) {
    return path.relative(app.paths.root, path.resolve(appPath));
  };

  return Promise
    .resolve(SPLASHES)
    // create a reversed copy of the splashes array
    .call('slice', 0)
    .call('reverse')
    .each(function (splash) {
      var splashFile;
      if (manifest.splash[splash.key]) {
        splashFile = path.resolve(rootPath, manifest.splash[splash.key]);
      } else {
        splashFile = path.resolve(rootPath, "resources/splash/" + splash.key + ".png");

        if (!fs.existsSync(splashFile)) {
          if (universalSplash) {
            splashFile = path.resolve(universalSplash);
          } else {
            logger.warn("No universal splash given and no splash provided for " + splash.key);
            return;
          }
        }
      }

      var splashOut = path.join(path.resolve(config.xcodeProjectPath), 'Images.xcassets/LaunchImage.launchimage', splash.outFile);
      logger.log("Creating splash:", appPathToString(splashOut), "from:", appPathToString(splashFile));

      var jvmExec = api.jvmtools.exec;
      return Promise
        .fromNode(jvmExec.bind(api.jvmtools, {
          tool: 'splasher',
          args: [
            "-i", splashFile,
            "-o", splashOut,
            "-resize", splash.outSize,
            "-rotate", "auto"
          ]
        }))
        .then(function (splasher) {
          return new Promise(function (resolve, reject) {
            var logger = api.logging.get('splash');

            splasher.on('out', logger.out);
            splasher.on('err', logger.err);
            splasher.on('end', function (data) {
              resolve();
            });
          });
        });
    });
};

var path = require('path');
var fs = require('fs-extra');
var ff = require('ff');

function copyFileSync(from, to) {
  fs.writeFileSync(to, fs.readFileSync(from));
}

exports.copyIcons = function (api, app, config, cb) {
  var logger = api.logging.get('ios-build');
  var icons = app.manifest.ios && app.manifest.ios.icons;

  if (icons) {
    ['57', '72', '76', '114', '120', '144', '152'].forEach(function(size) {
      var iOS7 = ['76', '120', '152'].indexOf(size) >= 0;
      var mustUnlink = iOS7;

      var targetPath = path.join(config.xcodeProjectPath, 'Images.xcassets/AppIcon.appiconset', 'icon' + size + '.png');
      var targetOldPath = path.join(config.xcodeProjectPath, 'icon' + size + '.png');
      var iconPath = icons[size];
      if (iconPath) {
        iconPath = path.join(app.paths.root, iconPath);
        if (fs.existsSync(iconPath)) {
          logger.log("Icons: Copying ", path.resolve(iconPath), " to ", path.resolve(targetPath));
          copyFileSync(iconPath, targetPath);
          if (!iOS7) {
            logger.log("Icons: Copying ", path.resolve(iconPath), " to ", path.resolve(targetOldPath));
            copyFileSync(iconPath, targetOldPath);
          }
          mustUnlink = false;
        } else {
          logger.warn('Icon', iconPath, 'does not exist.');
        }
      } else {
        logger.warn('Icon size', size, 'is not specified under manifest.json:ios:icons.');
      }

      if (mustUnlink) {
        logger.warn('Removing iOS 7 icon that was not specified.');
        try {
          fs.unlinkSync(targetPath);
        } catch (e) {}
      }
    });
  } else {
    logger.warn('No icons specified under "ios".');
  }

  cb && cb();
};

exports.copySplash = function (api, app, config, cb) {
  var manifest = app.manifest;
  var rootPath = app.paths.root;

  if (manifest.splash) {

    var universalSplash;
    if (manifest.splash.universal) {
      universalSplash = path.resolve(rootPath, manifest.splash.universal);
    }

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
      var next = f();
      function makeSplash(i) {
        if (i < 0) {
          next();
          return;
        }

        var splash = splashes[i];
        if (manifest.splash[splash.key]) {
          splashFile = path.resolve(rootPath, manifest.splash[splash.key]);
        } else {
          splashFile = path.resolve(rootPath, "resources/splash/" + splash.key + ".png");

          if (!fs.existsSync(splashFile)) {
            if (universalSplash) {
              splashFile = path.resolve(universalSplash);
            } else {
              logger.warn("No universal splash given and no splash provided for " + splash.key);
              makeSplash(i - 1);
              return;
            }
          }
        }

        var splashOut = path.join(path.resolve(config.xcodeProjectPath), 'Images.xcassets/LaunchImage.launchimage', splash.outFile);
        logger.log("Creating splash:", splashOut, "from:", splashFile);
        api.jvmtools.exec({
          tool: 'splasher',
          args: [
            "-i", splashFile,
            "-o", splashOut,
            "-resize", splash.outSize,
            "-rotate", "auto"
          ]
        }, function (err, splasher) {
          var logger = api.logging.get('splash');

          splasher.on('out', logger.out);
          splasher.on('err', logger.err);
          splasher.on('end', function (data) {
            makeSplash(i - 1);
          });
        });
      }
      makeSplash(splashes.length - 1);
    }).cb(cb);
  } else {
    logger.warn('No "splash" section provided in the manifest.json');
    cb();
  }
};

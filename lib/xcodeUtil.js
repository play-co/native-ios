var xcode = require('xcode');
var fs = require('fs');
var path = require('path');

var isHeaderFile = function(filename) {
  return (/\.h(pp)?$/).test(filename);
};

var isSourceFile = function(filename) {
  return (/\.(c(pp)?)|mm?$/).test(filename);
};

var isFramework = function(filename) {
  return (/(^[^\.]*$)|(\.framework$)|(\.dylib$)/).test(filename);
};

var isStaticLibrary = function(filename) {
  return (/\.a$/).test(filename);
};

function findFile(dir, regex) {
  var file = null;
  var dirs = fs.readdirSync(dir).filter(function(d) {
    return regex.test(d);
  });
  if (!dirs.length) {
    logger.error('Error finding the xcode project to edit');
  } else {
    file = path.join(dir, dirs[0]);
  }
  return file;
}

exports.getXcodeProjectDir = function (basePath) {
  return findFile(basePath, /\.xcodeproj$/);
};

exports.getXcodeProject = function(projectPath, cb) {
  var projectDir = exports.getXcodeProjectDir(projectPath);
  if (projectDir) {
    var projectFile = path.join(projectDir, 'project.pbxproj');
    var project = xcode.project(projectFile);
    project.parse(function (err) {
      cb(err, new Project(projectFile, projectPath, project));
    });
  } else {
    cb(new Error('xcode project not found'));
  }
};

var Project = function (projectFile, projectPath, project) {
  this._project = project;
  this._projectFile = projectFile;

  this.path = projectPath;
};

Project.prototype.getXcodeProject = function () {
  return path.basename(this._projectFile);
};

Project.prototype.getRelativePath = function (modulePath, file) {
  return path.relative(this.path, path.join(modulePath, file));
};

Project.prototype.installModule = function (modulePath, config, cb) {
  var filesToCopy = [];

  if (modulePath) {
    // Attempt to add header include path for module
    try {
      logger.log('try add include');
      var includeStat = fs.statSync(path.join(modulePath, 'include'));
      if (includeStat.isDirectory()) {
        logger.log('include is a dir');
        var searchPath = this.getRelativePath(modulePath, 'include');
        logger.log('adding search path', searchPath);
        this._project.addToHeaderSearchPaths(searchPath);
      }
    } catch (e) {
      // include path does not exist
      logger.log(modulePath);
      if (e.code === 'ENOENT') {
        logger.debug('No `include` folder found in', modulePath);
      } else {
        throw e;
      }
    }

    // Attempt to add library search path for module
    try {
      var libStat = fs.statSync(path.join(modulePath, 'lib'));
      if (libStat.isDirectory()) {
        var libPath = this.getRelativePath(modulePath, 'lib');
        this._project.addToLibrarySearchPaths(libPath);
      }

      // Only add libs if the `lib` directory exists for a module. Adding
      // libraries to the `frameworks` sections still causes them to be copied
      // into the project.
      if (config.libs) {
        config.libs.forEach(function (lib) {
          this._project.addStaticLibrary(lib);
        }, this);
      }
    } catch (e) {
      // `lib` path does not exist
      logger.log(modulePath);
      if (e.code === 'ENOENT') {
        logger.debug('No `lib` folder found in', modulePath);
      } else {
        throw e;
      }
    }
  }

  if (config.code) {
    config.code.forEach(function(file) {
      var relPath = this.getRelativePath(modulePath, file);
      if (isHeaderFile(file)) {
        this._project.addHeaderFile(relPath);
      } else if (isSourceFile(file)) {
        this._project.addSourceFile(relPath);
      } else {
        console.warn('Skipping unknown code file type', file);
      }
    }, this);
  }

  if (config.arccode) {
    config.arccode.forEach(function(file) {
      if (isHeaderFile(file)) {
        this._project.addHeaderFile(this.getRelativePath(modulePath, file), {
          compilerFlags: '-fobjc-arc'
        });
      } else if (isSourceFile(file)) {
        this._project.addSourceFile(this.getRelativePath(modulePath, file), {
          compilerFlags: '-fobjc-arc'
        });
      } else {
        console.warn('Skipping unknown code file type', file);
      }
    }, this);
  }

  if (config.additionalLinkerFlags) {
    var linkerFlagKey = 'OTHER_LDFLAGS';
    logger.log(
      "Updating xcode project with additional linker flags",
     config.additionalLinkerFlags
    );

    // if one string flag, convert to array of flags
    if (typeof config.additionalLinkerFlags === 'string') {
      config.additionalLinkerFlags = [config.additionalLinkerFlags];
    }

    var projectConfig = this._project.pbxXCBuildConfigurationSection();
    var projectKeys = Object.keys(projectConfig);

    for (var i = 0; i < projectKeys.length; i++) {
      var projectKey = projectKeys[i];
      var buildSettings = projectConfig[projectKey].buildSettings;
      if (buildSettings) {
        var linkerFlags = buildSettings[linkerFlagKey] || [];

        // if linkerFlags is a string, make it a list
        if (typeof linkerFlags === 'string') {
          linkerFlags = [linkerFlags];
        }

        config.additionalLinkerFlags.forEach(function(flag) {
          linkerFlags.push('"' + flag + '"');
        });

        projectConfig[projectKey].buildSettings[linkerFlagKey] = linkerFlags;
      }
    }

  }

  var frameworks = config.frameworks || [];
  frameworks.forEach(function(framework) {
    if (isFramework(framework)) {
      if (!/\./.test(framework)) {
        framework += '.framework';
      }

      var opts = {};
      if (modulePath && fs.existsSync(path.join(modulePath, framework))) {
        opts.customFramework = true;
        filesToCopy.push(framework);
        // framework = path.relative(this.path, path.join(modulePath, framework));
      }

      this._project.addFramework(framework, opts);
    } else if (isStaticLibrary(framework)) {
      this._project.addStaticLibrary(framework);
      filesToCopy.push(framework);
    } else {
      console.warn('Skipping unknown framework file type', framework);
    }
  }, this);

  if (config.removeFrameworks) {
    config.removeFrameworks.forEach(function (remove) {
      this._project.removeFramework(remove);
    }, this);
  }

  cb(null, filesToCopy);
};

Project.prototype.addResourceFiles = function(resourcePath, cb) {
  this._project.addResourceFile(resourcePath);
  cb(null);
};

Project.prototype.write = function(cb) {
  fs.writeFile(this._projectFile, this._project.writeSync(), cb);
};

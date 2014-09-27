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
}

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

Project.prototype.installModule = function (modulePath, config, cb) {
  var filesToCopy = [];

  if (config.code) {
    config.code.forEach(function(file) {
      if (isHeaderFile(file)) {
        this._project.addHeaderFile(file);
        filesToCopy.push(file);
      } else if (isSourceFile(file)) {
        this._project.addSourceFile(file);
        filesToCopy.push(file);
      } else {
        console.warn('Skipping unknown code file type', file);
      }
    }, this);
  }

  if (config.arccode) {
    config.arccode.forEach(function(file) {
      if (isHeaderFile(file)) {
        this._project.addHeaderFile(file, {compilerFlags: "-fobjc-arc"});
        filesToCopy.push(file);
      } else if (isSourceFile(file)) {
        this._project.addSourceFile(file, {compilerFlags: "-fobjc-arc"});
        filesToCopy.push(file);
      } else {
        console.warn('Skipping unknown code file type', file);
      }
    }, this);
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

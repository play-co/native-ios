var fs = require('fs-extra');
var path = require('path');
var plist = require('plist');

var getUserDefinedValue = function(manifest, key) {
  if (/\./.test(key)) {
    //its a . separated key
    var keys = key.split('.');
    keys.unshift('addons');
    var obj = manifest;
    keys.forEach(function(k) {
      obj = obj[k];
    });
    return obj;
  }

  return undefined;
};

var findPlistFile = function(projectPath) {
  var files = fs.readdirSync(projectPath).filter(function(filename) {
    return /Info\.plist$/.test(filename);
  });
  if (!files.length) {
    console.error('Error finding plist file in project', projectPath);
  } else if (files.length > 1) {
    console.warn('More than one plist that matches found!');
  }
  return files[0];
};


var getPlistConfigValue = function(plistConfig, manifest, key) {
  //TODO handle those special $() vars
  var value = plistConfig[key];
  var match = /\$\(([^\)]+)\)/.exec(value);
  if (match) {
    var lookupKey = match[1];
    value = getUserDefinedValue(manifest, lookupKey);
  }
  return value;
};

var copyKeysToPlist = function(plistObj, manifest, plistConfig) {
  Object.keys(plistConfig).forEach(function(key) {
    var value = getPlistConfigValue(plistConfig, manifest, key);
    if (value === undefined) { return; }

    // TODO: this is not very robust, nor is it a good api
    if (key.indexOf('.') != -1) {
      if (key == 'CFBundleURLTypes.CFBundleURLSchemes') {
        console.log("CFBundleURLSchemes", key);

        var found = false;
        for (var i = 0, obj; obj = plistObj.CFBundleURLTypes[i]; ++i) {
          if (obj.CFBundleURLSchemes) {
            found = true;
            obj.CFBundleURLSchemes.push(value);
            break;
          }
        }

        if (!found) {
          throw new Error('Could not find CFBundleURLSchemes in Info.plist');
        }
      } else {
        throw new Error('Unsupported plist key: ' + key);
      }
    } else {
      plistObj[key] = value;
    }
  });
};

exports.get = function (plistFile) {
  return new Plist(plistFile);
}

exports.getInfoPlist = function (projectPath) {
  var plistFile = findPlistFile(projectPath);
  if (!plistFile) {
    throw new Error('Info.plist not found in ' + projectPath);
  }
  return new Plist(path.join(projectPath, plistFile));
}

function Plist(filename) {
  this._filename = filename;
  try {
    var rawPlist = fs.readFileSync(filename, 'utf-8');
    var plistObj = plist.parseStringSync(rawPlist);
    this._plist = plistObj;
  } catch (e) {
    console.error(e);
    throw new Error('Cannot read ' + this._filename);
  }
}

Plist.prototype.add = function (manifest, obj) {
  copyKeysToPlist(this._plist, manifest, obj);
}

Plist.prototype.getRaw = function () {
  return this._plist;
}

Plist.prototype.write = function (cb) {
  console.log(this._plist);
  fs.writeFile(this._filename, plist.build(this._plist).toString(), cb);
}

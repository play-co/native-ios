/**
 * Shallow clone
 */
var replaceObject = function (dest, src) {
  var key;

  // Clear destination
  for (key in dest) {
    if (!(key in src)) {
      delete dest[key];
    }
  }

  // Copy source into destination
  for (key in src) {
    dest[key] = src[key];
  }
};

var rArrayIndex = /^\s*\-?\d+\s*$/;
var rArrayFilterItem = /(\w+)\s*([<>=]=?)\s*(\w+)|has\((.*?)\)|\*/;
var rKeyParser = /^\s*(.*?)(\[\s*(.*?)\s*\])?\s*$/;

var LAST_ELEMENT = {};

function quote(str) { return JSON.stringify(str); }
function quoteIfString(str) { return isNaN(str) ? quote(str) : str; }

function setValueForKey(key, value) {
  var isArray = Array.isArray(this);
  if (isArray) {
    var n = this.length;
    if (key === LAST_ELEMENT) { key = n; }
    if (key < 0) { key += n; }
  }

  // Set value for element in array. Objects are cloned, arrays are spliced.
  // Undefined removes an element and reindexes.
  var existing = this[key];
  if (value === undefined) {
    // remove the element at the key
    isArray
      ? this.splice(key, 1)
      : delete this[key];
    return;
  } else if (Array.isArray(value)) {
    if (Array.isArray(existing)) {
      // Replace values in existing array with values in other array
      existing.splice.apply(existing, [0, existing.length].concat(value));
      return;
    }
  } else if (typeof value == 'object' && typeof existing == 'object') {
    replaceObject(existing, value);
    return;
  }

  this[key] = value;
}

/**
 * Parses a string key of the form "foo.bar[a=1, b=2].baz[alpha = beta].delta"
 */
function parseKey(key) {
  var pieces = [];
  key.split('.').forEach(function (piece) {

    var match = piece.match(rKeyParser);
    if (match && match[1]) {
      pieces.push(match[1]);
    }

    if (match && match[2]) {
      var index = match[3];
      if (index === '') {
        pieces.push(LAST_ELEMENT);
      } else if (rArrayIndex.test(index)) {
        pieces.push(parseInt(index));
      } else {
        pieces.push(new Function('item', 'return ' + index
          .split(',')
          .map(function (piece) {
            var match = piece.match(rArrayFilterItem);
            if (!match) {
              return 'true';
            } else if (match[0] === '*') {
              return 'true';
            } else if (match[4]) {
              return quote(match[4]) + ' in item';
            } else {
              var relation = match[2];
              if (relation == '=') { relation = '=='; }
              return 'item[' + quote(match[1]) + ']' + relation + quoteIfString(match[3]);
            }
          })
          .join('&&')));
      }
    }
  });

  return pieces;
}

/**
 * Retrieve a value from an object. Supports keys of the format 'foo.bar.baz[5]'
 */
exports.getVal = function (obj, key) {
  if (!obj) { return; }

  var pieces = parseKey(key);
  var index = 0;
  var n = pieces.length;
  while (obj && index < n) {
    var piece = pieces[index++];
    if (typeof piece === 'function') {
      obj = obj.filter(piece, this)[0];
    } else if (piece === LAST_ELEMENT) {
      obj = obj[obj.length - 1];
    } else {
      obj = obj[piece];
    }
  }

  return obj;
};

/**
 * Set value in an object. Supports keys of the format 'foo.bar.baz[5]'
 */
exports.setVal = function (obj, key, value) {
  _setVal(parseKey(key), value, 0, obj);
  return obj;
};

function _setVal(pieces, value, index, obj) {
  // iterate until one before the end (the last piece is the final key to set)
  var max = pieces.length - 1;
  while (index < max) {
    var piece = pieces[index++];
    if (typeof piece == 'function') {
      // filter an array based on a filter function, all matching array items
      // should be set to the proper value recursively
      return obj
        .filter(piece, this)
        .forEach(bind(this, _setVal, pieces, value, index));
    }

    // if the next value is not defined or of the wrong type, set it to an
    // empty object or array
    var nextType = typeof pieces[index];
    if ((nextType === 'number' || nextType === 'function') && typeof obj[piece] !== 'object'
        || pieces[index] === LAST_ELEMENT && !Array.isArray(obj[piece])) {
      // objects or arrays or ok for numeric or function-based indices
      obj[piece] = [];
    } else {
      if (typeof obj[piece] !== 'object' || !obj[piece]) {
        obj[piece] = {};
      }
    }

    obj = obj[piece];
  }

  if (typeof pieces[max] === 'function') {
    // if the last part of the path is a filter, we need to conditionally set
    // the elements in the array
    var filter = pieces[max];
    var i = obj.length;
    while (i) {
      // iterate backward in case we're deleting elements
      if (filter(obj[--i])) {
        setValueForKey.call(obj, i, value);
      }
    }
  } else {
    setValueForKey.call(obj, pieces[max], value);
  }
}

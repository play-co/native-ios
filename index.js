/* @license
 * This file is part of the Game Closure SDK.
 *
 * The Game Closure SDK is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License v. 2.0 as published by Mozilla.
 
 * The Game Closure SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * Mozilla Public License v. 2.0 for more details.
 
 * You should have received a copy of the Mozilla Public License v. 2.0
 * along with the Game Closure SDK.  If not, see <http://mozilla.org/MPL/2.0/>.
 */

var path = require("path");
var ff = require("ff");
var clc = require("cli-color");

exports.init = function(common) {
	console.log("Running install.sh");
	common.child("sh", ["install.sh"], {
		cwd: __dirname
	}, function () {
		console.log("Install complete");
	});

	exports.load(common);
}

exports.load = function(common) {
	common.config.set("ios:root", path.resolve(__dirname))

	require(common.paths.root('src', 'testapp')).registerTarget("native-ios", path.join(__dirname, "build"));
}

exports.testapp = function(common, opts, next) {
	var f = ff(this, function () {
		common.child('open', [path.join(__dirname, './tealeaf/TeaLeafIOS.xcodeproj')], {}, f.wait());
	}, function() {
		require(common.paths.root('src', 'serve')).cli();
	}).error(function(err) {
		console.log("Error during testapp:", err, err.stack);
	}).cb(next);
}

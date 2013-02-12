/* @license
 * This file is part of the Game Closure SDK.
 *
 * The Game Closure SDK is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 
 * The Game Closure SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 
 * You should have received a copy of the GNU General Public License
 * along with the Game Closure SDK.  If not, see <http://www.gnu.org/licenses/>.
 */

var path = require("path");
var ff = require("ff");
var clc = require("cli-color");
var common = require("../../src/common");

function registerTestApp() {
	require("../../src/testapp").registerTarget("native-ios", __dirname);
}

exports.init = function () {

	console.log("Running install.sh");
	common.child("sh", ["install.sh"], {
		cwd: __dirname
	}, function () {
		console.log("Install complete");
	});

	exports.load();
}

exports.load = function () {
	common.config.set("ios:root", path.resolve(__dirname))
	common.config.write();

	registerTestApp();
}

exports.testapp = function (opts, next) {
	var f = ff(this, function () {
		common.child('open', [path.join(__dirname, './tealeaf/TeaLeafIOS.xcodeproj')], {}, f.wait());
	}, function() {
		require("../../src/serve").cli();
	}).error(function(err) {
		console.log(clc.red("ERROR"), err);
	}).cb(next);
}


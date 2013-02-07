cd ../../barista/

npm install

cd ../tealeaf/gen

../../barista/bin/barista -e spidermonkey -o . ../core/templates/view.json
../../barista/bin/barista -e spidermonkey -o . ../core/templates/image_map.json
../../barista/bin/barista -e spidermonkey -o . ../core/templates/animate.json

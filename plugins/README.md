#Native Plugins

###config.json

Create a config.json in this directory which will serve  
as a way to tell the installer which plugins should be  
installed. The config.json should follow this format
  
{  
	"NAME_OF_PLUGIN_1": "PATH_TO_PLUGIN_1",  
	"NAME_OF_PLUGIN_2": "PATH_TO_PLUGIN_2",  
	....  
}  

Then simply run

node installPlugins.js

to install the plugin. If you stop using a plugin, simply
remove the reference of it from the config.json and run
the install plugins script again.

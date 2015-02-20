backbone = require 'backbone4000'
_ = require 'underscore'
helpers = require 'helpers'

plugin = exports.plugin = backbone.Model.extend4000 {}

loadPlugins = (options={}, callback) ->

    options = _.extend {
        dir: helpers.path(__dirname + 'node_modules')
        PluginClass: backbone.Model
    }, options

    fs.readdir options.dir, (err, files) ->
        if err then return helpers.cbc err
        plugins = {}
        
        _.each files, (fileName) ->
            [ fileName,
            (callback) ->
                if fileName.indexOf(prefix) isnt 0 then return callback()
                filePath = helpers.path(__dirname + settings.pluginDir + fileName)
                stats = fs.lstatSync filePath

                if stats.isDirectory() or stats.isSymbolicLink()
                    name = fileName.substr prefix.length
                    newPlugin = options.PluginClass.extend4000 { name: name, env: env }, require(filePath).plugin
                    newPlugin::settings = _.extend  {}, newPlugin::settings or {}, settings.plugin[name]

                    plugins[fileName] = newPlugin

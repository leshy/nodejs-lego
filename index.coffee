path = require 'path'
backbone = require 'backbone4000'
_ = require 'underscore'
helpers = h = require 'helpers'
fs = require 'fs'
async = require 'async'

lego = exports.lego = backbone.Model.extend4000
    initialize: (options) ->
        @env = options.env

exports.loadLegos = (options={}, callback) ->

    options = _.extend {
        dir: helpers.path(path.dirname(require.main.filename) + 'node_modules')
        LegoClass: backbone.Model
        prefix: 'lego_'
        env: {}
    }, options

    env = options.env

    fs.readdir options.dir, (err, files) ->
        if err then return helpers.cbc err
        env.legos = env.modules = legos = {}

        _.each files, (fileName) ->
            if fileName.indexOf(options.prefix) isnt 0 then return

            filePath = helpers.path(options.dir, fileName)
            stats = fs.lstatSync filePath
            if stats.isDirectory() or stats.isSymbolicLink()
                name = fileName.substr(options.prefix.length)
                newLego = options.LegoClass.extend4000 { name: name, env: env }, require(filePath).lego
                newLego::settings = _.extend {}, newLego::settings or {}, env.settings.module?[name] or {}
                legos[name] = new newLego env: env


        h.dictMap legos, (lego,name) ->
            h.map h.array(lego.after), (targetName) ->
                if legos[targetName]
                    lego.requires = h.push h.array(lego.requires), targetName

            h.map h.array(lego.before), (targetName) ->
                if targetLego = legos[targetName]
                    targetLego.requires = h.push h.array(targetLego.requires), name


        autoInit = h.dictMap legos, (lego,name) ->
            h.push h.array(lego.requires), (callback) ->
                lego.init (err,data) -> callback err,data

        async.auto autoInit, callback

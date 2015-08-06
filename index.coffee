path = require 'path'
backbone = require 'backbone4000'
_ = require 'underscore'
helpers = h = require 'helpers'
fs = require 'fs'
async = require 'async'

lego = exports.lego = backbone.Model.extend4000
    initialize: (options) ->
        @env = options.env
        @legos = options.legos

exports.loadLegos = (options={}, callback) ->

    options = _.extend {
        dir: helpers.path(path.dirname(require.main.filename) + 'node_modules')
        legoClass: backbone.Model
        prefix: 'lego_'
        env: {}
    }, options

    env = options.env

    if options.verboseInit then console.log 'reading dir',options.dir

    fs.readdir options.dir, (err, files) ->
        if err then return helpers.cbc callback, err
        legos = {}

        _.each files, (fileName) ->
            if options.prefix and fileName.indexOf(options.prefix) isnt 0 then return

            filePath = helpers.path(options.dir, fileName)
            stats = fs.lstatSync filePath
            if stats.isDirectory() or stats.isSymbolicLink()
                name = fileName.substr(options.prefix.length)
                if options.verbose then console.log 'loading module', fileName

                requireData = require(filePath)
                if requireData.lego then requireData = requireData.lego

                newLego = options.legoClass.extend4000 { name: name, env: env, legos: legos }, requireData
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
                lego.init (err,data) -> callback err, data

        async.auto autoInit, (err,data) ->
          callback err, legos

# autocompile
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

    rootCandidates = [
      path.join(path.dirname(require.main.filename), 'node_modules'),
      path.join(process.cwd(), 'node_modules')]

    rootDir = _.find rootCandidates, fs.existsSync

    options = _.extend {
        dir: rootDir
        legoClass: backbone.Model
        prefix: 'lego_'
        env: {}
    }, options

    env = options.env

    if options.verbose then console.log 'reading dir',options.dir

    files = fs.readdirSync options.dir
    legos = {}

    _.each files, (fileName) ->

        if options.prefix and fileName.indexOf(options.prefix) isnt 0 then return

        filePath = path.join options.dir, fileName
        stats = fs.lstatSync filePath

        if stats.isDirectory() or stats.isSymbolicLink()
            name = fileName.substr(options.prefix.length)
            if options.verbose then console.log 'loading module', fileName

            requireData = require(filePath)

            if requireData.lego then requireData = requireData.lego
            newLego = requireData.extend4000  { name: name, env: env, legos: legos }
            newLego::settings = _.extend {}, newLego::settings or {}, env.settings.module?[name] or {}

            env[name] = legos[name] = new newLego env: env

    h.dictMap legos, (lego,name) ->
        h.map h.array(lego.after), (targetName) ->
            if legos[targetName]
                lego.requires = h.push h.array(lego.requires), targetName

        h.map h.array(lego.before), (targetName) ->
            if targetLego = legos[targetName]
                targetLego.requires = h.push h.array(targetLego.requires), name

    autoInit = h.dictMap legos, (lego,name) ->
        h.push h.array(lego.requires), (results, callback) ->
            if not callback then callback = results
            lego.init (err,data) ->
              if options.verbose then console.log 'module ready', name
              callback err, data

    async.auto autoInit, (err,data) -> callback err, legos

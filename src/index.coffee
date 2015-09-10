_ = require 'lodash'
Promise = require 'when'

request = require 'request'

KerplunkPluginSchema = require './models/KerplunkPlugin'

module.exports = (System) ->
  KerplunkPlugin = System.registerModel 'KerplunkPlugin', KerplunkPluginSchema

  routes:
    admin:
      '/admin/plugins/moderate': 'moderate'
      '/admin/plugins/moderate/:id/:action': 'edit'
    public:
      '/plugins/search': 'search'
      '/plugins/recommended': 'recommended'
      '/plugins/submit/:name': 'submit'

  handlers:
    edit: (req, res, next) ->
      KerplunkPlugin
      .where
        _id: req.params.id
      .findOne (err, plugin) ->
        return next err if err
        return next() unless plugin

        plugin.moderated = req.params.action == 'approve'
        console.log 'moderated', plugin.moderated
        plugin.save (err) ->
          return next err if err
          if req.params.format == 'json'
            res.send
              plugin: plugin
          else
            res.redirect '/admin/plugins/moderate'
    moderate: (req, res, next) ->
      perPage = parseInt req.query.perPage
      perPage = 20 unless perPage > 0
      page = parseInt req.query.page
      page = 1 unless page > 1
      page -= 1
      KerplunkPlugin
      .where {}
      .sort moderated: 1
      .skip page * perPage
      .limit perPage
      .find (err, plugins) ->
        return next err if err
        res.render 'moderate',
          plugins: plugins
    search: (req, res, next) ->
      console.log 'search!', req.query?.q
      query = req.query.q
      res.header 'Pragma', 'no-cache'
      return next() unless query?.length > 0
      query = query
        .toLowerCase()
        .replace /[^a-z0-9-_]/g, ' '
      selectors = query.split(' ').map (word) -> "\\b(#{word})\\b"
      regex = new RegExp selectors.join '|'

      console.log 'search', query
      KerplunkPlugin
      .where
        '$or': [
          {name: regex}
          {displayName: regex}
          {tag: regex}
          {description: regex}
        ]
        moderated: true
      .find (err, plugins) ->
        return next err if err
        console.log 'found', plugins.length
        res.send
          plugins: plugins
    submit: (req, res, next) ->
      {name} = req.params
      KerplunkPlugin
      .where
        name: name
      .findOne (err, plugin) ->
        return next err if err
        console.log 'found plugin' if plugin
        return res.send plugin: plugin if plugin
        url = "https://registry.npmjs.org/#{name}"
        console.log 'fetching', url
        request url, (err, response, body) ->
          return next err if err
          return res.send response: response unless response.statusCode == 200
          try
            obj = JSON.parse body
          catch err
            return next err
          unless obj.name == name
            return res.send
              message: 'what'
              data: obj
          latest = obj.versions?[obj['dist-tags']?.latest]
          plugin = new KerplunkPlugin
            name: name
            displayName: latest?.displayName
            description: latest?.description
            data: body
            kerplunk: latest?.kerplunk
            moderated: false
            tag: _.map (obj.keywords ? []), (str) ->
              str.toLowerCase()
          plugin.save (err) ->
            return next err if err
            console.log 'saved, send'
            res.send
              plugin: plugin
    recommended: (req, res, next) ->
      res.header 'Pragma', 'no-cache'
      mpromise = KerplunkPlugin
      .where
        moderated: true
      .find()
      Promise(mpromise).done (plugins) ->
        res.send
          plugins: plugins
      , (err) -> next err

  globals:
    public:
      nav:
        Admin:
          Plugins:
            Manage: '/admin/plugins'
            Moderate: '/admin/plugins/moderate'

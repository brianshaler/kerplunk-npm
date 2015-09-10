_ = require 'lodash'
React = require 'react'

{DOM} = React

module.exports = React.createFactory React.createClass
  getInitialState: ->
    submitting: false
    submitted: false

  onSubmit: (e) ->
    e.preventDefault()
    el = React.findDOMNode(@refs.submission)
    pluginName = el.value
    url = "/plugins/submit/#{pluginName}.json"
    opt = {}
    @setState
      submitting: true
      submitted: false
    @props.request.post url, opt, (err, data) =>
      return unless @isMounted()
      console.log err if err
      console.log 'submitted', data
      if el.value == pluginName
        el.value = ''
      @setState
        submitting: false
        submitted: pluginName

  render: ->
    DOM.section
      className: 'content'
    ,
      DOM.div null,
        DOM.form
          onSubmit: @onSubmit
        ,
          DOM.input
            ref: 'submission'
            placeholder: 'plugin name'
          DOM.input
            type: 'submit'
            value: 'submit'
          if @state.submitting
            DOM.div null, 'submitting...'
          else if @state.submitted
            DOM.div null, "submitted #{@state.submitted}"
      DOM.h2 null, 'Moderate Plugins'
      _.map @props.plugins, (plugin) ->
        DOM.div
          key: "plugin-#{plugin.name}"
        ,
          DOM.h3 null,
            DOM.a
              href: "https://npmjs.com/package/#{plugin.name}"
              target: '_blank'
            , plugin.name
          if plugin.moderated
            DOM.a
              href: "/admin/plugins/moderate/#{plugin._id}/disprove"
              className: 'btn btn-danger'
            , 'disprove'
          else
            DOM.a
              href: "/admin/plugins/moderate/#{plugin._id}/approve"
              className: 'btn btn-success'
            , 'approve'

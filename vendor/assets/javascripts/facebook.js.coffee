#Code obtained from http://reed.github.io/turbolinks-compatibility/facebook.html
fb_root = null
fb_events_bound = false

$ ->
  loadFacebookSDK()
  bindFacebookEvents() unless fb_events_bound

window.bindFacebookEvents = ->
  $(document)
    .on('page:fetch', saveFacebookRoot)
    .on('page:change', restoreFacebookRoot)
    .on('page:load', ->
      FB?.XFBML.parse()
    )
  fb_events_bound = true

window.saveFacebookRoot = ->
  fb_root = $('#fb-root').detach()

window.restoreFacebookRoot = ->
  if $('#fb-root').length > 0
    $('#fb-root').replaceWith fb_root
  else
    $('body').append fb_root

window.loadFacebookSDK = ->
  window.fbAsyncInit = initializeFacebookSDK
  $.getScript("//connect.facebook.net/en_US/all.js#xfbml=1")

window.initializeFacebookSDK = ->
  FB.init
    appId      : '110148615779941' # App ID
    channelUrl : '//summitsearch.org/channel.html' # Channel File
    status    : false
    cookie    : true
    xfbml     : true

  FB.Event.subscribe 'edge.create',
    (response) ->
      socialUpdate("true", "")
  FB.Event.subscribe 'edge.remove',
    (response) ->
      socialUpdate("false", "")


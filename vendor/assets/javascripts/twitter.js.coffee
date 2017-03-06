#This code was obtained from http://reed.github.io/turbolinks-compatibility/twitter.html

twttr_events_bound = false

$ ->
  loadTwitterSDK()
  bindTwitterEventHandlers() unless twttr_events_bound

window.bindTwitterEventHandlers = ->
  $(document).on 'page:load', renderTweetButtons
  twttr_events_bound = true

window.renderTweetButtons = ->
  $('.twitter-share-button').each ->
    button = $(this)
    button.attr('data-url', document.location.href) unless button.data('url')?
    button.attr('data-text', document.title) unless button.data('text')?
  twttr.widgets.load()

window.loadTwitterSDK = ->
  $.getScript("//platform.twitter.com/widgets.js")

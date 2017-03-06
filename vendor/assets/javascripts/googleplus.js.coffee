#Loads Google Plus api. http://reed.github.io/turbolinks-compatibility/google_plus.html
$ ->
  gapi.plusone.go()
  $(document).on 'page:load', gapi.plusone.go
  #po = document.createElement('script'); po.type = 'text/javascript'; po.async = true
  #po.src = 'https://apis.google.com/js/plusone.js'
  #s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(po, s)

#googlePlusClicked is called when a google plus button is clicked.
#socialUpdate is defined for each article page.
window.googlePlusClicked = (response) ->
  socialUpdate("",(response.state == "on").toString())

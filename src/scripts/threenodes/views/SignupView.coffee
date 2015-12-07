
define [
  'Underscore',
  'Backbone',
  "text!templates/app_signup.tmpl.html",
  'jquery'
], (_, Backbone, _template) ->
  #"use strict"

  ### DialogView ###
  namespace "ThreeNodes",
    SignupView: class SignupView extends Backbone.View
      # append it later will give you time for preprocessing
      # el: "#dialog-form"
      template: _.template(_template)

      render: =>
        @$el.html(@template())

        # it is very possible that the following code will hide the dialog part,
        # causing you not being able to find it again using $()
        # should use @dialog.find() to find it again
        @dialog = this.$('#signup-form').dialog(
          autoOpen: false
          height: 220
          width: 350
          modal: true
          buttons:
            # TODO: Save user profile info in server
            'Sign up': @userSignup
            Cancel: =>
              @dialog.dialog 'close'
              return
            'Test' : @testButton
          close: ->
            form[0].reset()
            return
        )
        form = @dialog.find('form').on('submit', (event) ->
          event.preventDefault()
          @setContext()
          return
        )
        @

      openDialog: =>
        console.log @dialog
        @dialog.dialog "open"

      setContext: =>
        formData = {}
        $inputs = @.dialog.find("[name]")
        $inputs.each ->
        formData[@name] = @value
        @dialog.dialog 'close'
        @model.set formData
        console.log(@model)


      userSignup: =>
        formData = {}
        $inputs = @.dialog.find("[name]")
        $inputs.each ->
          formData[@name] = @value
        @dialog.dialog 'close'
#        @model.set formData
#        console.log(@model)
        nick_name = formData['nickname']
        alert "Hello " + nick_name + "!"

      testButton: =>
        window.location.href = "index"
      remove: ->
        super
        @off()
        @model.off null, null, @






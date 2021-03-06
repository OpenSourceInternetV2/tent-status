Marbles.Views.NewFollowingForm = class NewFollowingFormView extends Marbles.View
  @template_name: '_new_following_form'
  @view_name: 'new_following_form'

  constructor: (options = {}) ->
    super

    @elements = {}

    @on 'ready', @init

    @render()

  init: =>
    @elements.form = Marbles.DOM.querySelector('form', @el)
    @elements.input = Marbles.DOM.querySelector('input[name=entity]', @el)
    @elements.submit = Marbles.DOM.querySelector('input[type=submit]', @el)
    @elements.errors = Marbles.DOM.querySelector('.alert-error', @el)

    Marbles.DOM.on(@elements.form, 'submit', @submit)
    Marbles.DOM.on(@elements.submit, 'click', @submit)

  submit: (e) =>
    e?.preventDefault()
    return if @frozen

    entity = @buildEntity(@elements.input.value)

    @clearErrors()
    return unless @validate(entity)
    @disable()

    TentStatus.Models.Following.create entity,
      failure: (res, xhr) =>
        @enable()
        @showErrors([{ entity: "Error: #{res?.error}" }])
      success: (following) =>
        @reset()

  reset: =>
    @clearErrors()
    @enable()
    @elements.input.value = ""

  disable: =>
    @frozen = true
    @elements.submit.disabled = true
    @elements.form.disabled = true

  enable: =>
    @frozen = false
    @elements.submit.disabled = false
    @elements.form.disabled = false

  validate: (data, options = {}) =>
    return if @frozen
    errors = TentStatus.Models.Following.validate(data, options)
    @clearErrors()
    @showErrors(errors) if errors

    !errors

  clearErrors: =>
    for el in Marbles.DOM.querySelectorAll('.error', @el)
      Marbles.DOM.removeClass(el, 'error')
    Marbles.DOM.hide(@elements.errors)

  showErrors: (errors) =>
    error_messages = []
    for error in errors
      for name, msg of error
        input = Marbles.DOM.querySelector("[name=#{name}]", @el)
        Marbles.DOM.addClass(input, 'error')
        error_messages.push(msg)
    console.log(error_messages.join("\n"))
    @elements.errors.innerHTML = error_messages.join("<br/>")
    Marbles.DOM.show(@elements.errors)

  buildEntity: (entity) =>
    return unless (m = entity.match(/^(https?:\/\/)?([^\/]+)(.*?)$/))
    parts = {
      scheme: m[1]
      domain: m[2]
      rest: m[3] || ""
    }

    parts.scheme ?= 'http://'
    entity = parts.scheme + parts.domain + parts.rest

    entity


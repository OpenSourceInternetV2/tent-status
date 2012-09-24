class TentStatus.Views.NewFollowingForm extends Backbone.View
  initialize: (options = {}) ->
    @parentView = options.parentView

    @$el.off('submit.follow').on 'submit.follow', @submit
    @$fields = {
      entity: ($ '[name=entity]', @$el)
      error: ($ '.error', @$el)
      submit: ($ '[type=submit]', @$el)
    }

  disable: =>
    @$fields.submit.attr 'disabled', 'disabled'
    @$fields.entity.attr 'disabled', 'disabled'

  enable: =>
    @$fields.submit.removeAttr 'disabled'
    @$fields.entity.removeAttr 'disabled'

  reset: =>
    @enable()
    @$fields.entity.val ''

  showError: (msg) =>
    @enable()
    @$fields.error.show().text msg

  hideError: =>
    @$fields.error.hide().text ''

  buildEntity: =>
    entity = @$fields.entity.val()
    entity = if entity.match /^[^.]+$/ && TentStatus.config.tent_host_domain
      'https://' + entity + TentStatus.config.tent_host_domain
    else if entity.length && entity.match /^(?!http?s?)/
      'https://' + entity
    else
      entity
    entity

  submit: (e) =>
    e.preventDefault()
    @disable()
    entity = @buildEntity()
    return @showError('Invalid entity uri') unless entity.match(/^https?:\/\/[^\.]+\..*$/)
    @hideError()
    new HTTP 'POST', "#{TentStatus.config.current_tent_api_root}/followings", { entity: entity }, (following, xhr) =>
      return @showError("Unable to follow #{entity}") unless xhr.status == 200
      @reset()
      following = new TentStatus.Models.Following following
      TentStatus.Views.Following.create following, @parentView.container, @parentView
    false

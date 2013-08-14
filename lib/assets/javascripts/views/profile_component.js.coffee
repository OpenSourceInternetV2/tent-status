Marbles.Views.ProfileComponent = class ProfileComponentView extends Marbles.View
  constructor: ->
    super
    @entity = Marbles.DOM.attr(@el, 'data-entity')
    @css_class = Marbles.DOM.attr(@el, 'data-class')

  profileModel: =>
    TentStatus.Models.MetaProfile.find(entity: @entity, fetch: false)

  fetch: =>
    if model = @profileModel()
      @render(@context(model))
    else
      model = new TentStatus.Models.MetaProfile(entity: @entity)
      model.on 'change:avatar_url change:name', @render, null, args: false
      @render()

  context: (profile = @profileModel()) =>
    profile: profile
    has_name: !!(profile?.get('name'))
    entity: @entity
    profile_url: TentStatus.Helpers.entityProfileUrl(@entity)
    css_class: @css_class
    formatted:
      entity: TentStatus.Helpers.formatUrlWithPath(@entity)


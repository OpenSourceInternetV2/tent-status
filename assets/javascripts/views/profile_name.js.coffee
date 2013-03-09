Marbles.Views.ProfileName = class ProfileNameView extends Marbles.Views.ProfileView
  @template_name: '_profile_name'
  @view_name: 'profile_name'

  constructor: ->
    super

    @model_cid = Marbles.DOM.attr(@el, 'data-model_cid')
    entity = Marbles.DOM.attr(@el, 'data-entity') unless @model_cid

    context = {
      has_name: false
      formatted:
        entity: TentStatus.Helpers.minimalEntity(Marbles.Model.instances.all[@model_cid]?.entity || entity)
    }
    @render(context)

    @fetch({}, {
      error: =>
        TentStatus.trigger('loading:stop')
        @render()
      entity: entity unless @model_cid
    })

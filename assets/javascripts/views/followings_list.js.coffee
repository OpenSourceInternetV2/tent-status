class TentStatus.Views.FollowingsList extends TentStatus.View
  templateName: 'followings_list'
  partialNames: ['_following']

  dependentRenderAttributes: ['followings']

  initialize: ->
    super

    @on 'ready', @initFollowingViews
    @on 'ready', @initAutoPaginate

    @on 'change:followings', @render
    TentStatus.trigger 'loading:start'
    new HTTP 'GET', "#{TentStatus.config.current_tent_api_root}/followings", { limit: TentStatus.config.PER_PAGE }, (followings, xhr) =>
      TentStatus.trigger 'loading:complete'
      return unless xhr.status == 200
      followings = new TentStatus.Collections.Followings followings
      paginator = new TentStatus.Paginator followings, { sinceId: followings.last()?.get('id') }
      paginator.on 'fetch:success', @appendRender
      @set 'followings', paginator

  context: =>
    followings: _.map( @followings?.toArray() || [], (following) =>
      TentStatus.Views.Following::context(following)
    )

  appendRender: (new_followings) =>
    html = ""
    $el = $('table', @$el)
    $last_post = $('.following:last', $el)
    new_followings = for following in new_followings
      following = new TentStatus.Models.Following following
      html += TentStatus.Views.Following::renderHTML(TentStatus.Views.Following::context(following), @partials)
      following

    $el.append(html)
    _.each $last_post.nextAll('.following'), (el, index) =>
      view = new TentStatus.Views.Following el: el, following: new_followings[index], parentView: @
      view.trigger 'ready'

  render: =>
    return unless html = super
    @$el.html(html)

    @trigger 'ready'

  initFollowingViews: =>
    _.each ($ '.following', @$el), (el) =>
      following_id = ($ el).attr 'data-id'
      following = _.find @followings?.toArray() || [], (f) => f.get('id') == following_id
      view = new TentStatus.Views.Following el: el, following: following, parentView: @
      view.trigger 'ready'

  initAutoPaginate: =>
    ($ window).off('scroll.followings').on 'scroll.followings', @windowScrolled
    setTimeout @windowScrolled, 100

  windowScrolled: =>
    $last = ($ 'tr.following:last', @$el)
    last_offset_top = $last.offset()?.top || 0
    bottom_position = window.scrollY + $(window).height()

    if last_offset_top < (bottom_position + 300)
      clearTimeout @_auto_paginate_timeout
      @_auto_paginate_timeout = setTimeout @followings?.nextPage, 0 unless @followings?.onLastPage


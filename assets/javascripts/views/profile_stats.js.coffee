class TentStatus.Views.ProfileStats extends TentStatus.View
  templateName: '_profile_stats'

  initialize: (options) ->
    super

    @resources = ['posts', 'followers', 'followings']

    for r in @resources
      do (r) =>
        @on "change:#{r}Count", @render
        if r == 'posts'
          params = {
            post_types: TentStatus.config.post_types
          }
        else
          params = {}

        new HTTP 'GET', "#{TentStatus.config.current_tent_api_root}/#{r}/count", params, (count, xhr) =>
          return unless xhr.status == 200
          @set "#{r}Count", count

    params = {
      post_types: TentStatus.config.post_types
      mentioned_entity: TentStatus.config.domain_entity.toStringWithoutSchemePort()
    }
    @on "change:mentionsCount", @render
    new HTTP 'GET', "#{TentStatus.config.current_tent_api_root}/posts/count", params, (count, xhr) =>
      return unless xhr.status == 200
      @set "mentionsCount", count

    @render()

  context: =>
    postsCount: @postsCount
    followersCount: @followersCount
    followingsCount: @followingsCount
    mentionsCount: @mentionsCount

  render: =>
    for r in @resources
      return if @get("#{r}Count") == null or @get("#{r}Count") == undefined
    html = super
    @$el.html(html)

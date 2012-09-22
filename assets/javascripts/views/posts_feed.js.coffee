class TentStatus.Views.PostsFeed extends TentStatus.View
  templateName: 'posts_feed'
  partialNames: ['_reply_form', '_post', '_post_inner']

  initialize: (options) ->
    super
    @licenses = [{ url: "http://creativecommons.org/licenses/by-nc-sa/3.0/", name: "Creative Commons by-nc-sa 3.0" }]

    @on 'change:posts', @render
    @on 'render', @initPostViews

    params = {
      post_types: TentStatus.config.post_types
      limit: TentStatus.config.PER_PAGE
    }

    options.api_root ?= TentStatus.config.tent_api_root
    new HTTP 'GET', "#{options.api_root}/posts", params, (posts, xhr) =>
      return unless xhr.status == 200
      @set 'posts', new TentStatus.Collections.Posts posts # TODO wrap in paginator

  context: =>
    licenses: @licenses
    posts: (_.map @posts?.toArray() || [], (post) =>
      view = new TentStatus.Views.Post parentView: @
      view.context(post)
    )

  render: =>
    html = super
    @$el.html(html)

  initPostViews: =>
    _.each ($ 'li.post', @$el), (el) =>
      post_id = el.attr('data-id')
      post = _.find @posts?.toArray() || [], (p) => p.get('id') == post_id
      new TentStatus.Views.Post el: el, post: post, parentView: @


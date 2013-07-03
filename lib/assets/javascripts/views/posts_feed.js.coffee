Marbles.Views.PostsFeed = class PostsFeedView extends Marbles.View
  @template_name: 'posts_feed'
  @partial_names: ['_post_reply_form', '_post', '_post_inner', '_post_inner_actions']
  @view_name: 'posts_feed'

  showLoading: =>
    TentStatus.trigger 'loading:start'

  hideLoading: =>
    TentStatus.trigger 'loading:stop'

  initialize: (options = {}) =>
    @entity = options.entity || TentStatus.config.current_user.entity
    @post_types = options.post_types || TentStatus.config.feed_types
    @feed_params = options.feed_params || {}
    @collection_context = 'feed+' + sjcl.codec.base64.fromBits(sjcl.codec.utf8String.toBits(JSON.stringify(@post_types) + JSON.stringify(@feed_params)))

    # fire focus event for first post view in feed (caught by author info view)
    # TODO: find a better way to do this!
    @once 'ready', =>
      first_post_view = @childViews('Post')?[0]
      if first_post_view
        first_post_view.constructor.trigger('focus', first_post_view)

    @on 'ready', @initAutoPaginate

    @fetch()

    TentStatus.Models.StatusPost.on 'create:success', (post, xhr) =>
      return unless @shouldAddPostToFeed(post)
      collection = @postsCollection()
      return unless @shouldAddPostTypeToFeed(post.get('type'), collection.options.params.types)
      collection.unshift(post)
      @prependRender([post])

  shouldAddPostTypeToFeed: (prospect_type, types = @postsCollection().options.params.types) =>
    prospect_type = new TentClient.PostType prospect_type
    _.any types, (type) =>
      type = new TentClient.PostType type
      type.assertMatch(prospect_type)

  shouldAddPostToFeed: (post) =>
    true

  postsCollection: =>
    if @_posts_collection_cid
      TentStatus.Collections.Posts.find(cid: @_posts_collection_cid)
    else
      @initPostsCollection()

  initPostsCollection: =>
    collection = TentStatus.Collections.Posts.find(entity: @entity, context: @collection_context)
    collection ?= new TentStatus.Collections.Posts(entity: @entity, context: @collection_context)
    collection.options.params = _.extend {
      types: @post_types
    }, @feed_params
    @_posts_collection_cid = collection.cid
    collection

  fetch: (params = {}, options = {}) =>
    @pagination_frozen = true

    @showLoading()
    @postsCollection().fetch params, _.extend({}, options,
      success: @fetchSuccess
      failure: @fetchError
      complete: @hideLoading
    )

  fetchNext: =>
    @pagination_frozen = true

    @showLoading()
    @last_page = true if @postsCollection().fetchNext(
      append: true
      success: @fetchSuccess
      failure: @fetchError
      complete: @hideLoading
    ) is false

  fetchSuccess: (posts, res, xhr, params, options) =>
    if options.append
      @appendRender(posts)
    else
      @render(@context(posts))

    @pagination_frozen = false

  fetchError: (res, xhr) =>
    console?.warn?("#{@constructor.name}.prototype.fetchError", res, xhr)

  postContext: (post) =>
    Marbles.Views.Post::context(post)

  renderPostHTML: (post) =>
    @constructor.partials['_post'].render(@postContext(post), @constructor.partials)

  context: (posts = @postsCollection().models()) =>
    posts: _.map posts, ((post) => @postContext(post))

  appendRender: (posts) =>
    fragment = document.createDocumentFragment()
    for post in posts
      Marbles.DOM.appendHTML(fragment, @renderPostHTML(post))

    @bindViews(fragment)
    @el.appendChild(fragment)

  prependRender: (posts) =>
    fragment = document.createDocumentFragment()
    for post in posts
      Marbles.DOM.prependHTML(fragment, @renderPostHTML(post))

    @bindViews(fragment)
    Marbles.DOM.prependChild(@el, fragment)

  initAutoPaginate: =>
    TentStatus.on 'window:scroll', @windowScrolled
    setTimeout @windowScrolled, 100

  windowScrolled: =>
    return if @pagination_frozen || @last_page
    last_post = Marbles.DOM.querySelector('li.post:last-of-type', @el)
    return unless last_post
    last_post_offset_top = last_post.offsetTop || 0
    last_post_offset_top += last_post.offsetHeight || 0
    bottom_position = window.scrollY + Marbles.DOM.windowHeight()

    if last_post_offset_top <= bottom_position
      clearTimeout @_auto_paginate_timeout
      @_auto_paginate_timeout = setTimeout @fetchNext, 0 unless @last_page


TentStatus.Collection = class Collection extends Marbles.Collection
  pagination: {}

  constructor: (options = {}) ->
    super(_.extend(unique: true, options))

  @buildModel: (attrs, options = {}) ->
    switch attrs.type
      when TentStatus.config.POST_TYPES.STATUS
        options.model = TentStatus.Models.StatusPost
      when TentStatus.config.POST_TYPES.STATUS_REPLY
        options.model = TentStatus.Models.StatusReplyPost
      when TentStatus.config.POST_TYPES.STATUS_SUBSCRIPTION, TentStatus.config.POST_TYPES.REPOST_SUBSCRIPTION
        options.model = TentStatus.Models.Subscription

    super(attrs, options)

  postTypes: =>
    @options.params.types || []

  fetchPrev: (options = {}) =>
    return false unless @pagination.prev
    prev_params = Marbles.History::parseQueryParams(@pagination.prev)
    @fetch(prev_params, _.extend({ prepend: true }, options))

  fetchNext: (options = {}) =>
    return false unless @pagination.next
    next_params = Marbles.History::parseQueryParams(@pagination.next)
    @fetch(next_params, _.extend({ append: true }, options))

  fetch: (params = {}, options = {}) =>
    params = _.extend {
      entities: @options.entity || TentStatus.config.meta.entity
      types: [@constructor.model.post_type]
      limit: TentStatus.config.PER_PAGE
    }, @options.params, params

    delete params.entities if params.entities == false

    params.types = [params.types] unless _.isArray(params.types)
    params.types = _.map params.types, (type) => (new TentClient.PostType type).toURIString()

    headers = _.extend {}, @options.headers, options.headers

    TentStatus.tent_client.post.list(params: params, headers: headers, callback: ((res, xhr) => @fetchComplete(params, options, res, xhr)))

  fetchComplete: (params, options, res, xhr) =>
    models = null
    if xhr.status == 200
      # success
      models = @fetchSuccess(params, options, res, xhr)
      options.success?(models, res, xhr, params, options)
      @trigger('fetch:success', models, res, xhr, params, options)
    else
      options.failure?(res, xhr, params, options)
      @trigger('fetch:failure', res, xhr, params, options)
    options.complete?(models, res, xhr, params, options)
    @trigger('fetch:complete', models, res, xhr, params, options)

  fetchSuccess: (params, options, res, xhr) =>
    @pagination = _.extend({
      first: @pagination.first
      last: @pagination.last
    }, res.pages)

    data = res.posts
    profiles = res.profiles

    if profiles
      for entity, attrs of profiles
        if model = TentStatus.Models.MetaProfile.find(entity: entity, fetch: false)
          for k,v of attrs
            model.set(k, v)
        else
          model = new TentStatus.Models.MetaProfile(_.extend({entity: entity}, attrs))

    models = if options.append
      @appendJSON(data)
    else if options.prepend
      @prependJSON(data)
    else
      @resetJSON(data)

    models


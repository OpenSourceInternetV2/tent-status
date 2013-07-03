TentStatus.UnifiedCollection = class UnifiedCollection extends Marbles.UnifiedCollection
  pagination: {}

  sortModelsBy: (model) =>
    model.get('received_at') * -1

  fetchPrev: (options = {}) =>
    prev_params = null
    for cid, _pagination of @pagination
      continue unless _pagination.prev
      prev_params ?= {}
      prev_params[cid] = Marbles.History::parseQueryParams(_pagination.prev)
    return false unless prev_params
    @fetch(prev_params, _.extend({ prepend: true }, options))

  fetchNext: (options = {}) =>
    next_params = null
    for cid, _pagination of @pagination
      continue unless _pagination.next
      next_params ?= {}
      next_params[cid] = Marbles.History::parseQueryParams(_pagination.next)
    return false unless next_params
    @fetch(next_params, _.extend({ prepend: true }, options))

  postTypes: =>
    types = []
    for collection in @collections()
      types.push(collection.postTypes()...)
    _.uniq(types)

  fetch: (params = {}, options = {}) =>
    for cid in @collection_ids
      do (cid) =>
        _completeFn = options[cid]?.complete
        options[cid] ?= {}
        options[cid].complete = (models, res, xhr) =>
          _completeFn?.apply?(null, arguments)

          return unless xhr.status == 200
          @pagination[cid] = _.extend({
            first: @pagination[cid]?.first
            last: @pagination[cid]?.last
          }, res.pages)

          unless @pagination[cid].prev
            model = @constructor.collection.find(cid: cid)?.first()
            since = model?.get('received_at') || model?.get('published_at') || (new Date * 1)
            if version_id = model?.get('version.id')
              since = "#{since} #{version_id}"
            @pagination[cid].prev = "?since=#{since}"

    super(params, options)

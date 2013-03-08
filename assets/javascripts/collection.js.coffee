TentStatus.Collection = class Collection extends Marbles.Collection
  fetch: (params = {}, options = {}) =>
    options.client ?= @client || HTTP.TentClient.currentEntityClient()
    params = _.extend({}, (@params || @constructor.params), params)
    options.client.get @constructor.model.resource_path, params, (res, xhr) =>
      unless xhr.status == 200
        options.error?(res, xhr)
        @trigger('fetch:failed', res, xhr)
        return

      @parseLinkHeader(xhr.getResponseHeader('Link')) if res.length

      if options.append
        models = @append(res)
      else if options.prepend
        models = @prepend(res)
      else
        models = @reset(res)

      options.success?(models, xhr, params, options, @)
      @trigger('fetch:success', @)

  fetchPrev: (options = {}) =>
    unless @pagination_params?.prev
      options.error?([])
      return []
    @fetch(@pagination_params.prev, options)

  fetchNext: (options = {}) =>
    unless @pagination_params?.next
      options.error?([])
      return []
    @fetch(@pagination_params.next, options)

  parseLinkHeader: (link_header="") =>
    @pagination_params = {}
    parts = link_header.split(/,\s*/)
    for part in parts
      continue unless part.match(/<([^>]+)>;\s*rel=['"]([^'"]+)['"]/)
      continue unless RegExp.$2 in ['next', 'prev']
      path = RegExp.$1
      params = Marbles.History::deserializeParams(path.split('?')[1])
      @pagination_params[RegExp.$2] = params
    @pagination_params

  append: (resources_attribtues) =>
    return [] unless resources_attribtues?.length
    for attrs in resources_attribtues
      model = new @constructor.model(attrs)
      @model_ids.push(model.cid)
      model

  prepend: (resources_attribtues) =>
    return [] unless resources_attribtues?.length
    for i in [resources_attribtues.length-1..0]
      attrs = resources_attribtues[i]
      model = new @constructor.model(attrs)
      @model_ids.unshift(model.cid)
      model

  prependModels: (model_ids) =>
    @model_ids = model_ids.concat(@model_ids)

  empty: =>
    @model_ids = []


_.extend TentStatus.Helpers,
  formatRelativeTime: (timestamp_int) ->
    now = moment()
    time = moment(timestamp_int)

    formatted_time = time.fromNow()

    "#{formatted_time}"

  rawTime: (timestamp_int) ->
    moment(timestamp_int).format()

  formatCount: (count, options = {}) ->
    return count unless options.max && count > options.max
    "#{options.max}+"

  minimalEntity: (entity) ->
    @formatUrlWithPath(entity)

  formatUrlWithPath: (url = '') ->
    url.replace(/^\w+:\/\/(.*)$/, '$1')

  capitalize: (string) ->
    string.substr(0, 1).toUpperCase() + string.substr(1, string.length)

  pluralize: (word, count, plural) ->
    if count is 1 || count is -1
      word
    else
      plural

  # HTML escaping
  HTML_ENTITIES: {
    '&': '&amp;',
    '>': '&gt;',
    '<': '&lt;',
    '"': '&quot;',
    "'": '&#39;'
  }
  htmlEscapeText: (text) ->
    return unless text
    text.replace /[&"'><]/g, (character) -> TentStatus.Helpers.HTML_ENTITIES[character]

  extractTrailingHtmlEntitiesFromText: (text) ->
    trailing_text = ""
    for char, entities of TentStatus.Helpers.HTML_ENTITIES
      regex = new RegExp("(#{TentStatus.Helpers.escapeRegExChars(entities)}?)$")
      if regex.test(text)
        trailing_text = text.match(regex)[1] + trailing_text
        text = text.replace(regex, "")
    [text, trailing_text]

  truncate: (text, length, elipses='...', options = {}) ->
    return text unless text
    if text.length > length
      _truncated = text.substr(0, length-elipses.length)
      _truncated += elipses
    else
      _truncated = text
    _truncated

  formatTentMarkdown: (text = '', mentions = []) ->
    inline_mention_urls = _.map mentions, (m) => TentStatus.Helpers.entityProfileUrl(m.entity)

    parsePara = (para, callback) ->
      new_para = for item in para
        if _.isArray(item) && item[0] in ['para', 'strong', 'em', 'del']
          parsePara(item, callback)
        else if typeof item is 'string'
          callback(item)
        else
          item
      new_para

    autoLinkPreprocessor = (jsonml) ->
      return jsonml unless jsonml[0] is 'para'

      jsonml = parsePara jsonml, (item) ->
        return item if item is 'para'
        urls = TentStatus.Helpers.extractUrlsWithIndices(String(item))
        return item unless urls.length

        new_item = item.split('')
        index_offset = 0
        for u in urls
          before = new_item.slice(0, u.indices[0] - index_offset)
          after = new_item.slice(u.indices[1] - index_offset)

          link = ['link', { href: u.url }, TentStatus.Helpers.truncate(TentStatus.Helpers.formatUrlWithPath(item.slice(u.indices[0], u.indices[1])), TentStatus.config.URL_TRIM_LENGTH)]

          before.push(link)
          new_item = before.concat(after)

          index_offset += u.indices[1] - u.indices[0] - 1

        ['span'].concat(new_item)

      jsonml

    externalLinkPreprocessor = (jsonml) ->
      return jsonml unless jsonml[0] is 'link'
      return jsonml unless TentStatus.Helpers.isURLExternal(jsonml[1]?.href)
      jsonml[1].href = TentStatus.Helpers.ensureUrlHasScheme(jsonml[1].href)
      jsonml[1]['data-view'] = 'ExternalLink'
      jsonml

    markdown.toHTML(text, 'Tent', { footnotes: inline_mention_urls, preprocessors: [autoLinkPreprocessor, externalLinkPreprocessor] })


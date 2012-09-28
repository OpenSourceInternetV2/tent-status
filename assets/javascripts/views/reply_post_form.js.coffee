class TentStatus.Views.ReplyPostForm extends TentStatus.Views.NewPostForm
  templateName: '_reply_form'

  initialize: (options = {}) ->
    @postsFeedView = options.parentView.parentView

    super

    ## reply fields
    @replyToPostId = ($ '[name=mentions_post_id]', @$el).val()
    @replyToEntity = ($ '[name=mentions_post_entity]', @$el).val()

    @$form = @$el
    @$textarea = ($ 'textarea', @$form)
    @html = @$form.html()

    @$container = @$form.parent()
    @is_repost = @$container.hasClass('repost-reply-container')

    @is_hidden = @$container.hasClass('hide')
    @hide_text = 'Cancel'

    ## this references the wrong instance in render, TODO: debug and fix this issue
    $form = @$form
    html = @html
    @on 'ready', => $form.html(html)
    @on 'ready', => $form.parent().hide()

  getReplyButton: =>
    key = if @is_repost then 'reply_repost' else 'reply'
    @parentView.$buttons[key]

  toggle: =>
    if @is_hidden
      @show()
    else
      @hide()

  focusAfterText: =>
    pos = @$textarea.val().length
    input_selection = new TentStatus.Helpers.InputSelection @$textarea.get(0)
    input_selection.setSelectionRange(pos, pos)

  show: =>
    @is_hidden = false
    @$container.removeClass('hide')
    @once 'ready', @hide
    @focusAfterText()
    if $button = @getReplyButton()
      @show_text ?= $button.text()
      $button.text @hide_text

  hide: =>
    @is_hidden = true
    @$container.addClass('hide')
    if $button = @getReplyButton()
      $button.text @show_text

  buildMentions: (data) =>
    data = super
    if @replyToPostId and @replyToEntity
      data.mentions ||= []
      existing = false
      for m in data.mentions
        if m.entity == @replyToEntity && !m.post
          m.post = @replyToPostId
          existing = true
          break
      unless existing
        data.mentions.push { entity: @replyToEntity, post: @replyToPostId }
    data

  context: =>
    data = {
      max_chars: TentStatus.config.max_length
    }

    post = @parentView.post
    return data unless post

    post_data = if @is_repost
      repost = @parentView.post.get('repost')
      @parentView.repostContext(post, repost)
    else
      @parentView.context(post)

    _.extend({}, data, post_data)

  render: =>
    @trigger 'ready'


Marbles.Views.EditPost = class EditPostView extends TentStatus.View
  @template_name: '_edit_post'
  @view_name: 'edit_post'

  @is_edit_form: true

  constructor: (options = {}) ->
    super(_.extend(options, {render_method: 'replace'}))
    @el = document.createElement('li')
    Marbles.DOM.insertBefore(@el, @parent_view.el)

    @elements = {}
    @text = {}

    setImmediate =>
      @constructor.instances.all[@_child_views.EditPostMentionsAutoCompleteTextarea?[0]]?.textarea_view?.focus()

    # inherit specific methods from NewPostForm
    for method in ['initHotkeys', 'submitWithValidation', 'initCharCounter', 'updateCharCounter', 'initValidation', 'validate', 'showErrors', 'clearErrors', 'buildPostAttributes', 'buildPostMentionsAttributes', 'buildPostPermissionsAttributes']
      do (method) =>
        @[method] = => Marbles.Views.NewPostForm::[method].apply(@, arguments)

    @on 'ready', => Marbles.DOM.hide(@parent_view.el)
    @on 'ready', @init

    @render()

  init: =>
    @elements.form = Marbles.DOM.querySelector('form', @el)
    @elements.submit = Marbles.DOM.querySelector('input[type=submit]', @el)
    @elements.delete = Marbles.DOM.querySelector('input[type=button][data-action=delete]', @el)
    @elements.cancel = Marbles.DOM.querySelector('input[type=button][data-action=cancel]', @el)
    @elements.errors = Marbles.DOM.querySelector('[data-errors_container]', @el)
    @elements.textarea = Marbles.DOM.querySelector('textarea', @el)

    @text.submit = {
      disable_with: Marbles.DOM.attr(@elements.submit, 'data-disable_with')
    }
    @text.delete = {
      disable_with: Marbles.DOM.attr(@elements.delete, 'data-disable_with')
      confirm: Marbles.DOM.attr(@elements.delete, 'data-confirm')
    }

    @initCharCounter()
    @initValidation()
    @initHotkeys()

    Marbles.DOM.on(@elements.form, 'submit', @submitWithValidation)
    Marbles.DOM.on(@elements.delete, 'click', @confirmDelete)
    Marbles.DOM.on(@elements.cancel, 'click', @cancel)

  post: => @parent_view.post()

  submit: (data) =>
    @disableWith(@elements.submit, @text.submit.disable_with)
    data ?= @buildPostAttributes()
    post = @post()
    post.update(data,
      error: (res, xhr) =>
        @enable()
        @showErrors([{ text: "Error: #{JSON.parse(xhr.responseText)?.error}" }])

      success: (post, xhr) =>
        @renderPost()
    )

  disableWith: (el, text) =>
    @disable()
    el.enable_with = el.value
    el.value = text

  disable: =>
    @frozen = true
    for action in ['cancel', 'delete', 'submit']
      @elements[action]?.disabled = true
    null

  enable: (el = @elements.submit) =>
    @frozen = false
    for action in ['cancel', 'delete', 'submit']
      continue unless el = @elements[action]
      el.disabled = false
      if text = el.enable_with
        el.value = text
        delete el.enable_with
    null

  confirmDelete: =>
    return unless confirm(@text.delete.confirm)
    @delete()

  delete: =>
    @disableWith(@elements.delete, @text.delete.disable_with)
    post = @post()
    post.delete(
      error: (res, xhr) =>
        @enable()
        @showErrors([{ text: "Error: #{JSON.parse(xhr.responseText)?.error}" }])

      success: (post, xhr) =>
        @detachPost()
    )

  cancel: =>
    Marbles.DOM.removeNode(@el)
    @detach()
    Marbles.DOM.show(@parent_view.el)

  renderPost: =>
    @cancel()
    @parent_view.render()

  detachPost: =>
    Marbles.DOM.removeNode(@el)
    @detach()
    Marbles.DOM.removeNode(@parent_view.el)
    @parent_view.detach()

  context: (post = @post()) =>
    _.extend {}, super,
      max_chars: TentStatus.config.MAX_LENGTH
      has_parent: @parent_view.view_name == 'repost'
      post:
        cid: post.cid
        content: post.get('content.text')

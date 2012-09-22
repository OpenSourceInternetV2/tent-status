class TentStatus.Views.ProfileFollowButton extends Backbone.View
  initialize: (options = {}) ->
    @parentView = options.parentView

    @buttons = {}
    @buttons.submit = ($ '[type=submit]', @$el)

    new HTTP 'GET', "#{TentStatus.config.tent_api_root}/followings", {
      entity: TentStatus.config.domain_entity
    }, (followings, xhr) =>
      return unless xhr.status == 200
      if followings.length
        @following_id = followings[0].id
        @setFollowing()

    @$el.on 'submit', @submit

  submit: (e) =>
    e.preventDefault()
    if @is_following
      return unless confirm("Unfollow?")
      path = "/#{@following_id}"
    else
      path = ''
    entity = TentStatus.config.domain_entity.toString()
    @buttons.submit.attr 'disabled', 'disabled'
    method = if @is_following then 'DELETE' else 'POST'
    new HTTP method, "#{TentStatus.config.tent_api_root}/followings#{path}", { entity: entity }, (following, xhr) =>
      unless xhr.status == 200
        @buttons.submit.removeAttr 'disabled'
        return
      @following_id = following.id if !@is_following
      if @is_following then @unsetFollowing() else @setFollowing()

  setFollowing: =>
    @is_following = true
    @buttons.submit.val 'Unfollow'
    @buttons.submit.removeClass('btn-success').addClass('btn-danger')
    @buttons.submit.removeAttr 'disabled'

  unsetFollowing: =>
    @is_following = false
    @buttons.submit.val 'Follow'
    @buttons.submit.removeClass('btn-danger').addClass('btn-success')
    @buttons.submit.removeAttr 'disabled'

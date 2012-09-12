class StatusPro.Models.Follower extends Backbone.Model
  model: 'follower'
  url: => "#{StatusPro.api_root}/followers#{ if @id then "/#{@id}" else ''}"

  initialize: ->
    profile = @get('profile')
    core_profile = {}
    basic_profile = {}
    for type, content of profile
      basic_profile = content if type.match(/types\/info\/basic/)
      core_profile = content if type.match(/types\/info\/core/)
    @set 'core_profile', core_profile
    @set 'basic_profile', basic_profile

  name: =>
    @get('basic_profile')['name'] || @get('core_profile')['entity']

  avatar: =>
    @get('basic_profile')['avatar_url']


TentStatus.Models.MetaProfile = class  MetaProfileModel extends Marbles.Model
  @model_name: 'meta_profile'
  @id_mapping_scope: ['entity']

  @post_type: new TentClient.PostType(TentStatus.config.POST_TYPES.META)

  parseAttributes: =>
    super

    if @get('avatar_digest')
      @set('avatar_url', TentStatus.tent_client.getNamedUrl('attachment', entity: @get('entity'), digest: @get('avatar_digest')))
    else
      @set('avatar_url', TentStatus.config.DEFAULT_AVATAR_URL)

server_meta_post = TentStatus.config.current_user.server_meta_post
TentStatus.meta_profile = new MetaProfileModel(_.extend(
  {
    entity: server_meta_post.content.entity,
    avatar_digest: server_meta_post.attachments?[0]?.digest
  },
  server_meta_post.content.profile || {}
))

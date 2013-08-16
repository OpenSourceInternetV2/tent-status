Marbles.Views.Repost = class RepostView extends Marbles.Views.Post
  @template_name: '_repost'
  @partial_names: ['_post_inner', '_post_inner_actions']
  @view_name: 'repost'

  constructor: ->
    super

    @parent_post_cid = Marbles.DOM.attr(@el, 'data-parent_post_cid')

    @fetchPost()

  parentPost: =>
    TentStatus.Models.Post.instances.all[@parent_post_cid]

  conversationView: => @findParentView('conversation')

  fetchPost: (parent_post = @parentPost()) =>
    TentStatus.Models.Post.find { id: parent_post.get('content.post'), entity: parent_post.get('content.entity') }, {
      success: @fetchSuccess
      failure: @fetchFailure
    }

  fetchSuccess: (post) =>
    return (setImmediate => @fetchPost(post)) if post.get('is_repost')
    @post_cid = post.cid
    @render(@context(post))

  fetchFailure: =>
    @parentView().hide()

  post: =>
    TentStatus.Models.Post.find(cid: @post_cid)

  context: (post) =>
    parent_post = @parentPost()
    _.extend super, {
      has_parent: true
      is_conversation_view: !!@conversationView()
      parent:
        cid: parent_post.cid
        formatted:
          entity: TentStatus.Helpers.minimalEntity(parent_post.get('entity'))
    }

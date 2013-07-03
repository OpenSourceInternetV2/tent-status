TentStatus.Models.Following = class FollowingModel extends TentStatus.Models.Post
  @model_name: 'following'

  @validate: (entity) ->
    null

  @create: (entity, options) ->
    # TODO:
    # - show "pending" placeholder in list
    # - poll until relationship# post exists
    # - if delivery failure post exists for relationship, show warning/error

    num_pending = 0
    errors = []
    subscriptions = []
    completeFn = (subscription, res, xhr) =>
      num_pending -= 1

      if xhr.status == 200
        subscriptions.push(subscription)
      else
        errors.push(error: res?.error || "#{xhr.status}: #{JSON.stringify(res)}")

      if num_pending <= 0
        if errors.length
          options.failure?(errors)
        else
          options.success?(subscriptions)

    for type in TentStatus.config.subscription_types
      do (type) =>
        type = new TentClient.PostType(type)
        subscription_type = new TentClient.PostType(TentStatus.config.POST_TYPES.SUBSCRIPTION)
        subscription_type.setFragment(type.toStringWithoutFragment())

        num_pending += 1
        TentStatus.Models.Subscription.create({
          type: subscription_type.toString()
          content:
            type: type.toString()
          mentions: [{ entity: entity }]
          permissions:
            public: true
            entities: [entity]
        }, {
          complete: (subscription, res, xhr) =>
            completeFn(subscription, res, xhr)
        })


Marbles.Views.ProfileFollowersCount = class FollowersCountView extends Marbles.Views.ProfileResourceCount
  @view_name: 'profile/followers_count'
  @model: TentStatus.Models.Follower
  @resource_name: {singular: 'subscriber', plural: 'subscribers'}
  @path: '/subscribers'

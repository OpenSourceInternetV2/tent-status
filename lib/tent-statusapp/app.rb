require 'sinatra/base'
require 'data_mapper'
require 'sprockets'
require 'uglifier'
require 'tent-client'
require 'rack/csrf'
require 'hashie'
require 'uri'
require 'slim'
require 'hogan_assets'
require 'oj'

module Tent
  class StatusApp < Sinatra::Base
    require 'tent-statusapp/sprockets/environment'
    require 'tent-statusapp/models/user'

    configure do
      set :asset_manifest, Oj.load(File.read(ENV['STATUS_ASSET_MANIFEST'])) if ENV['STATUS_ASSET_MANIFEST']
      set :cdn_url, ENV['STATUS_CDN_URL']
      set :assets, SprocketsEnvironment.assets
    end

    use Rack::Csrf

    helpers do
      def path_prefix
        env['SCRIPT_NAME']
      end

      def asset_path(path)
        path = asset_manifest_path(path) || settings.assets.find_asset(path).digest_path
        if settings.cdn_url?
          "#{settings.cdn_url}/assets/#{path}"
        else
          full_path("/assets/#{path}")
        end
      end

      def asset_manifest_path(asset)
        if settings.respond_to?(:asset_manifest?) && settings.asset_manifest?
          settings.asset_manifest['files'].detect { |k,v| v['logical_path'] == asset }[0]
        end
      end

      def full_path(path)
        "#{path_prefix}/#{path}".gsub(%r{//}, '/')
      end

      def full_url(path)
        (self_url_root + full_path(path))
      end

      def self_url_root
        env['rack.url_scheme'] + "://" + env['HTTP_HOST']
      end

      def client
        env['tent.client']
      end

      def csrf_tag
        Rack::Csrf.tag(env)
      end

      def csrf_meta_tag(options = {})
        Rack::Csrf.metatag(env, options)
      end

      def basic_profile
        @basic_profile ||= (client.profile.get.body || {})['https://tent.io/types/info/basic/v0.1.0'] || {}
      end

      def current_user
        return unless defined?(TentD)
        current = TentD::Model::User.current
        current if session[:current_user_id] == current.id
      end

      def guest_user
        return unless defined?(TentD)
        return unless session[:current_user_id]
        user = TentD::Model::User.get(session[:current_user_id])
        current = TentD::Model::User.current
        return if session[:current_user_id] == current.id
        user if session[:current_user_id] == user.id
      end

      def domain_entity
        env['rack.url_scheme'] + '://' + env['HTTP_HOST']
      end

      def authenticate!
        halt 403 unless current_user
      end
    end

    def json(data)
      [200, { 'Content-Type' => 'application/json' }, [data.to_json]]
    end

    if ENV['RACK_ENV'] != 'production'
      get '/assets/*' do
        new_env = env.clone
        new_env["PATH_INFO"].gsub!("/assets", "")
        settings.assets.call(new_env)
      end
    end

    get '/' do
      slim :application
    end

    get '/api/profile' do
      res = client.profile.get
      json res.body
    end

    get '/api/posts/count' do
      res = client.post.count params.merge(
        :types => ["https://tent.io/types/post/status/v0.1.0", "https://tent.io/types/post/repost/v0.1.0"]
      )
      json res.body
    end

    get '/api/posts' do
      res = client.post.list params.merge(
        :types => ["https://tent.io/types/post/status/v0.1.0", "https://tent.io/types/post/repost/v0.1.0"]
      )

      if (400...500).include?(res.status)
        halt res.status
      end

      json res.body
    end

    get '/api/posts/:id' do
      res = client.post.get(params[:id])
      json res.body
    end

    post '/api/posts' do
      data = JSON.parse(env['rack.input'].read)
      env['rack.input'].rewind

      data = {
        :published_at => Time.now.to_i,
        :type => data['type'] || "https://tent.io/types/post/status/v0.1.0",
        :licenses => data['licenses'],
        :mentions => data['mentions'],
        :permissions => { public: true },
        :content => data['content'] || {
          :text => data['text'].to_s.slice(0...140)
        }
      }

      puts data.inspect

      res = client.post.create(data)

      json res.body
    end

    delete '/api/posts/:id' do
      res = client.post.delete(params[:id])
      json res.body
    end

    get '/api/groups/count' do
      res = client.group.count(params)
      json res.body
    end

    get '/api/groups' do
      res = client.group.list(params)
      json res.body
    end

    post '/api/groups' do
      data = JSON.parse(env['rack.input'].read)
      env['rack.input'].rewind

      res = client.group.create(data)
      json res.body
    end

    get '/api/followers/count' do
      res = client.follower.count(params)
      json res.body
    end

    get '/api/followers' do
      res = client.follower.list(params)
      json res.body
    end

    put '/api/followers/:id' do
      data = JSON.parse(env['rack.input'].read)
      env['rack.input'].rewind

      res = client.follower.update(params[:id], data)
      json res.body
    end

    delete '/api/followers/:id' do
      res = client.follower.delete(params[:id])
      json res.body
    end

    get '/api/followings/count' do
      res = client.following.count(params)
      json res.body
    end

    get '/api/followings' do
      res = client.following.list(params)
      json res.body
    end

    post '/api/followings' do
      data = JSON.parse(env['rack.input'].read)
      env['rack.input'].rewind

      res = client.following.create(data['entity'])
      json res.body
    end

    put '/api/followings/:id' do
      data = JSON.parse(env['rack.input'].read)
      env['rack.input'].rewind

      res = client.following.update(params[:id], data)
      json res.body
    end

    delete '/api/followings/:id' do
      res = client.following.delete(params[:id])
      json res.body
    end

    get '/signout' do
      session.clear
      redirect full_path('/')
    end

    # Catch all for pushState routes
    get '*' do
      slim :application
    end
  end
end

source 'https://rubygems.org'
ruby '1.9.3'

# Specify your gem's dependencies in tent-statusapp.gemspec
gemspec

gem 'tent-client', :git => 'git@github.com:tent/tent-client-ruby.git', :branch => 'master'

group :development do
  gem 'evergreen', :git => 'git://github.com/jvatic/evergreen.git', :branch => 'master', :submodules => true
  gem 'asset_sync', :git => 'git://github.com/titanous/asset_sync.git', :branch => 'fix-mime'
  gem 'mime-types'
end

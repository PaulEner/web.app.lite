set :deploy_to, '/home/deploy/main'

set :repo_url, 'git@github.com:i-docus/web.APP.git'

set :branch, 'staging'

set :rvm_ruby_version, '2.6.5'

server 'my-sandbox.idocus.com', user: 'deploy', roles: %w{app db web worker}
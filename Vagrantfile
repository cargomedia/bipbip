Vagrant.configure('2') do |config|
  config.vm.box = 'cargomedia/debian-7-amd64-default'

  config.vm.provision 'shell', inline: [
    'cd /vagrant',
    'sudo apt-get update',
    'sudo apt-get install -y g++ libsasl2-dev libmysqlclient-dev libxslt1-dev libxml2-dev',
    'sudo gem install bundle',
    'bundle install'
  ].join(' && ')
end

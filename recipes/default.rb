#
# Cookbook Name:: cassandra-multinode
# Recipe:: default
#
# Copyright 2016, Jagatveer Singh
#
# All rights reserved - Do Not Redistribute
#

to_install = true

if File.exist?('/var/lib/cassandra')
  to_install = false
else
  to_install = true
end

#apt_repository "datastax" do
#  uri          "http://debian.datastax.com/community"
#  distribution "stable"
#  components   ["main"]
#  key          "http://debian.datastax.com/debian/repo_key"
#  action :add
#end

user node['cassandra']['user'] do
  gid "nogroup"
  shell "/bin/false"
end

directory node['cassandra']['libdir'] do
  owner node['cassandra']['user']
  group "root"
  mode "0755"
  action :create
end

directory node['cassandra']['logdir'] do
  owner node['cassandra']['user']
  group "root"
  mode "0755"
  action :create
end

directory node['cassandra']['conf_dir'] do
  owner "root"
  group "root"
  mode "0755"
  action :create
  not_if "test -d /etc/cassandra"
end

execute 'ready_filesystem' do
  command "sudo mkfs -t ext4 #{node['cassandra']['mountdevice']}"
  action :run
  only_if { to_install == true }
end

mount node['cassandra']['libdir'] do
  device node['cassandra']['mountdevice']
  fstype 'ext4'
  action :mount
  only_if { to_install == true }
end

execute 'ready_repos' do
  command <<-EOF
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0x219BD9C9
  apt_source='deb http://repos.azulsystems.com/debian stable main'
  apt_list='/etc/apt/sources.list.d/zulu.list'
  echo "$apt_source" | sudo tee "$apt_list" > /dev/null
  echo "deb http://debian.datastax.com/community stable main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
  curl -L https://debian.datastax.com/debian/repo_key | sudo apt-key add -
  EOF
  action :run
  only_if { to_install == true }
end

%w(zulu-8 emacs python-pip).each do |pkg|
    package pkg do
      action :install
  end
end

execute 'cassandra-driver' do
  command 'sudo pip install cassandra-driver'
  action :run
end

node['cassandra']['src_deps'].each do |pkg|
  package pkg
end

execute 'cleanup_for_install' do
  command <<-EOF
  sudo service cassandra stop
  sleep 10
  sudo rm -rf /var/lib/cassandra/data/system/*
  EOF
  action :run
  only_if { to_install == true }
end

template node['cassandra']['conf_dir'] + '/cassandra.yaml' do
  source 'cassandra.yaml.erb'
  owner node['cassandra']['user']
  mode '0644'
  variables('cluster_name' => node['cassandra']['conf']['cluster_name'],
            'rpc_address' => node['cassandra']['conf']['rpc_address'],
            'nodeip' => node['cassandra']['conf']['nodeip'],
            'node1' => node['cassandra']['conf']['node1'],
            'node2' => node['cassandra']['conf']['node2']
           )
  notifies :start, 'service[cassandra]'
end

service 'cassandra' do
  action [ :enable, :start ]
end

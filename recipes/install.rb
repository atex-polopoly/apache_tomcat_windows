#
# Cookbook:: apache_tomcat_windows
# Recipe:: install
#
# Copyright:: 2017, The Authors, All Rights Reserved.

include_recipe 'jdk::install'

chef_gem 'win32-service'
chef_gem 'win32-dir'

require 'win32/dir'

tomcat_download = remote_file 'apache tomcat' do
  path "#{Chef::Config[:file_cache_path]}\\apache_tomcat.exe"
  source {"ftp://#{node[:ftp][:host]}#{node[:ftp][:path]}/apache_tomcat/apache-tomcat-#{node[:tomcat][:version]}.exe"}
  ftp_active_mode node['ftp_active_mode']
  action :create
  not_if {Dir::exist?("#{Dir::PROGRAM_FILES}\\#{node[:tomcat][:win_install_dir]}")}
end

# Install Tomcat (auto-searches for installed Java)
execute 'tomcat install' do
  command "#{Chef::Config[:file_cache_path]}\\apache_tomcat.exe /S"
  not_if { Dir::exist?(tomcat_folder) }
  only_if { File.exist?("#{Chef::Config[:file_cache_path]}\\apache_tomcat.exe") }
end

file "#{Chef::Config[:file_cache_path]}\\apache_tomcat.exe" do
  action :delete
  only_if {File.exist?("#{Chef::Config[:file_cache_path]}\\apache_tomcat.exe")}
end

# Start it up
service node[:tomcat][:svc_name] do
  action [:enable, :start]
end

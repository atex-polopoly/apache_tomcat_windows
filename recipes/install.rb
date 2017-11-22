#
# Cookbook:: apache_tomcat_windows
# Recipe:: install
#
# Copyright:: 2017, The Authors, All Rights Reserved.

chef_gem 'win32-service'
chef_gem 'win32-dir'

require 'win32/dir'

include_recipe 'jdk::install'

customer = node['customer']
tomcat_folder = "#{Dir::PROGRAM_FILES}\\Apache Software Foundation\\Tomcat 7.0"

tomcat_download = remote_file 'apache tomcat' do
  path "#{Chef::Config[:file_cache_path]}\\apache_tomcat.exe"
  source lazy {"ftp://10.10.10.10/mirror/apache_tomcat/apache-tomcat-#{get_attr(customer, 'tomcat', 'version')}.exe"}
  ftp_active_mode node['ftp_active_mode']
  action :create
  not_if {Dir::exist?(tomcat_folder)}
end

# Install Tomcat (auto-searches for installed Java)
execute 'tomcat install' do
  command "#{Chef::Config[:file_cache_path]}\\apache_tomcat.exe /S"
  only_if  {tomcat_download.updated_by_last_action? && File.exist?("#{Chef::Config[:file_cache_path]}\\apache_tomcat.exe")}
end

file "#{Chef::Config[:file_cache_path]}\\apache_tomcat.exe" do
  action :delete
  only_if {File.exist?("#{Chef::Config[:file_cache_path]}\\apache_tomcat.exe")}
end

# Start it up
service 'start tomcat service' do
  service_name 'tomcat7'
  action [:enable, :start]
end

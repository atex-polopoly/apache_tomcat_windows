#
# Cookbook:: apache_tomcat_windows
# Recipe:: install
#
# Copyright:: 2017, The Authors, All Rights Reserved.

include_recipe 'jdk::install'

chef_gem 'win32-service'
chef_gem 'win32-dir'

require 'win32/dir'

tomcat_folder = "#{Dir::PROGRAM_FILES}\\#{node[:tomcat][:win_install_dir]}"
tomcat_svc = node[:tomcat][:svc_name]
tomcat_installed = File.exist?("#{tomcat_folder}\\bin\\#{tomcat_svc}.exe")

remote_file 'apache tomcat' do
  path "#{Chef::Config[:file_cache_path]}\\apache_tomcat.exe"
  source "http://#{node[:mirror][:host]}#{node[:mirror][:path]}/apache_tomcat/apache-tomcat-#{node[:tomcat][:version]}.exe"
  action :create
  not_if { tomcat_installed }
end

execute 'tomcat install' do
  command "#{Chef::Config[:file_cache_path]}\\apache_tomcat.exe /S"
  not_if { tomcat_installed }
end

file "#{Chef::Config[:file_cache_path]}\\apache_tomcat.exe" do
  action :delete
end

service node[:tomcat][:svc_name] do
  action [:enable, :start]
end

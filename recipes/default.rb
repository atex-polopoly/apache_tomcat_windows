#
# Cookbook:: apache_tomcat_windows
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

chef_gem 'win32-service'
chef_gem 'win32-dir'

require 'win32/dir'

os_tmp = Dir::tmpdir()
jre_exe = 'jre-8u151-windows-x64.exe'
jre_cs = '4378d712c510930d066bfa256b24e07dfea5ed31aa514afb7c7dd72fcce9bb68'
jre_folder = "#{Dir::PROGRAM_FILES}\\Java"
tomcat_exe = 'apache-tomcat-7.0.82.exe'
tomcat_svc = 'tomcat7'
tomcat_folder = "#{Dir::PROGRAM_FILES}\\Apache Software Foundation\\Tomcat 7.0"

# Copy file to Windows "TEMP" folder
cookbook_file "#{os_tmp}\\#{jre_exe}" do
  source jre_exe
  checksum jre_cs
  action :create
end

# Copy file to Windows "TEMP" folder
cookbook_file "#{os_tmp}\\#{tomcat_exe}" do
  source tomcat_exe
  action :create
end

# Stop Tomcat
service 'stop tomcat service' do
  service_name tomcat_svc
  action :stop
  only_if {::Win32::Service.exists?(tomcat_svc)}
end

# Install Java
execute 'java install' do
  command "#{os_tmp}\\#{jre_exe} /s"
  not_if {Dir::exist?(jre_folder)}
end

# Install Tomcat (auto-searches for installed Java)
execute 'tomcat install' do
  command "#{os_tmp}\\#{tomcat_exe} /S"
  not_if {Dir::exist?(tomcat_folder)}
end

# Start it up
service 'start tomcat service' do
  service_name tomcat_svc
  action [:enable, :start]
end

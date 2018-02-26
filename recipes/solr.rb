#
# Cookbook:: apache_tomcat_windows
# Recipe:: solr
#
# Copyright:: 2017, The Authors, All Rights Reserved.

include_recipe 'apache_tomcat_windows::install'
include_recipe 'chef-vault'

chef_gem 'win32-dir'
chef_gem 'rubyzip'
chef_gem 'nokogiri'

require 'win32/dir'
require 'uri'

tomcat_folder = "#{Dir::PROGRAM_FILES}\\#{node[:tomcat][:win_install_dir]}"
tomcat_svc = node[:tomcat][:svc_name]
solr_install_dir = "#{node[:prestige][:solr][:unzip_destination]}\\prestige_solr_#{node[:prestige][:solr][:version]}"
solr_zip_file = "prestige_solr_#{node[:prestige][:solr][:version]}.zip"
solr_lang = node[:prestige][:solr][:lang]
ftp_pwd = chef_vault_item('ftp-servers', 'prestige-ms')['managedservices']

remote_file "#{Chef::Config[:file_cache_path]}\\#{solr_zip_file}" do
    source "ftp://managedservices:#{ftp_pwd}@#{node[:prestige][:ftp][:host]}#{node[:prestige][:ftp][:path]}#{solr_zip_file}"
    action :create
end

service tomcat_svc do
    action :stop
end

ruby_block 'unzip prestige software' do
    block do
        require 'rubygems'
        require 'zip'
        require 'fileutils'
        FileUtils.rm_r solr_install_dir, :force => true
        Zip::File.open("#{Chef::Config[:file_cache_path]}\\#{solr_zip_file}") do |zf|
            zf.each do |entry|
                path = File.join("#{node[:prestige][:solr][:unzip_destination]}\\", entry.name)
                FileUtils.mkdir_p(File.dirname(path))
                zf.extract(entry, path)
            end
        end
    end
    action :run
end

file "#{solr_install_dir}\\solr\\solr.xml" do
    content lazy {
        require 'nokogiri'
        doc  = Nokogiri::XML(File::read "#{solr_install_dir}\\solr\\solr.xml")
        xml_node = doc.at_xpath("/solr/cores/core[@name='production']")
        xml_node['instanceDir'] = "#{solr_install_dir}\\solr\\#{solr_lang}\\production"
        xml_node = doc.at_xpath("/solr/cores/core[@name='archive']")
        xml_node['instanceDir'] = "#{solr_install_dir}\\solr\\#{solr_lang}\\archive"
        doc.to_s()
    }
    action :create
end

file "#{solr_install_dir}\\solr\\#{solr_lang}\\production\\conf\\solrconfig.xml" do
    content lazy {
        require 'nokogiri'
        doc  = Nokogiri::XML(File::read "#{solr_install_dir}\\solr\\#{solr_lang}\\production\\conf\\solrconfig.xml")
        xml_node = doc.at_xpath("/config/dataDir")
        xml_node.content=("#{solr_install_dir}\\data\\solr\\#{solr_lang}\\production")
        doc.to_s()
    }
    action :create
end

file "#{solr_install_dir}\\solr\\#{solr_lang}\\archive\\conf\\solrconfig.xml" do
    content lazy {
        require 'nokogiri'
        doc  = Nokogiri::XML(File::read "#{solr_install_dir}\\solr\\#{solr_lang}\\archive\\conf\\solrconfig.xml")
        xml_node = doc.at_xpath("/config/dataDir")
        xml_node.content=("#{solr_install_dir}\\data\\solr\\#{solr_lang}\\archive")
        doc.to_s()
    }
    action :create
end

remote_file "#{tomcat_folder}\\webapps\\solr.war" do
    source 'file:///' + URI.escape("#{solr_install_dir}\\webapps\\solr.war")
    action :create
end

remote_file "#{tomcat_folder}\\lib\\jcl-over-slf4j-1.6.6.jar" do
    source 'file:///' + URI.escape("#{solr_install_dir}\\lib\\ext\\jcl-over-slf4j-1.6.6.jar")
    action :create
end

remote_file "#{tomcat_folder}\\lib\\jul-to-slf4j-1.6.6.jar" do
    source 'file:///' + URI.escape("#{solr_install_dir}\\lib\\ext\\jul-to-slf4j-1.6.6.jar")
    action :create
end

remote_file "#{tomcat_folder}\\lib\\log4j-1.2.16.jar" do
    source 'file:///' + URI.escape("#{solr_install_dir}\\lib\\ext\\log4j-1.2.16.jar")
    action :create
end

remote_file "#{tomcat_folder}\\lib\\slf4j-api-1.6.6.jar" do
    source 'file:///' + URI.escape("#{solr_install_dir}\\lib\\ext\\slf4j-api-1.6.6.jar")
    action :create
end

remote_file "#{tomcat_folder}\\lib\\slf4j-log4j12-1.6.6.jar" do
    source 'file:///' + URI.escape("#{solr_install_dir}\\lib\\ext\\slf4j-log4j12-1.6.6.jar")
    action :create
end

template "#{tomcat_folder}\\conf\\Catalina\\localhost\\solr.xml" do
    source 'tomcat-config.xml.erb'
    variables({
        'tomcat_solr_war' => "#{tomcat_folder}\\webapps\\solr.war",
        'solr_home_dir' => "#{solr_install_dir}\\solr",
        'log4j_properties_dir' => "#{solr_install_dir}\\resources"
    })
    action :create
end

file "#{tomcat_folder}\\conf\\server.xml" do
    content lazy {
        require 'nokogiri'
        doc  = Nokogiri::XML(File::read "#{tomcat_folder}\\conf\\server.xml")
        xml_node = doc.at_xpath("/Server/Service/Connector[@port='8080']")
        xml_node.set_attribute('URIEncoding', 'UTF-8')
        doc.to_s()
    }
    action :create
end

file "#{Chef::Config[:file_cache_path]}\\#{solr_zip_file}" do
    action :delete
    only_if {File::exists? "#{Chef::Config[:file_cache_path]}\\#{solr_zip_file}"}
end

service tomcat_svc do
    action :start
end

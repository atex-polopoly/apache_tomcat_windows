#
# Cookbook:: apache_tomcat_windows
# Recipe:: solr
#
# Copyright:: 2017, The Authors, All Rights Reserved.

include_recipe 'apache_tomcat_windows::install'

chef_gem 'win32-dir'
chef_gem 'rubyzip'
chef_gem 'nokogiri'

require 'win32/dir'

tomcat_folder = "#{Dir::PROGRAM_FILES}\\Apache Software Foundation\\Tomcat 7.0"
tomcat_svc = 'tomcat7'
base_folder = 'c:/'
prestige_solr = 'prestige_solr_3_4'
solr_lang = 'eng' #node['solr']['language'] || 'eng'
ftp_url = 'ftp-eu.atex.com/P6/P6.0/P6.0.10/Atex_Content_P-Series_6.0.10_B127_06Oct2017_x64'
ftp_user = 'managedservices'
ftp_pwd = 'M4n4g3d'

remote_file 'get prestige software' do
    path "#{Chef::Config[:file_cache_path]}/#{prestige_solr}.zip"
    source "ftp://#{ftp_user}:#{ftp_pwd}@#{ftp_url}/#{prestige_solr}.zip"
    action :create
    not_if {File::exists? "#{Chef::Config[:file_cache_path]}/#{prestige_solr}.zip"}
end

service 'tomcat stop' do 
    service_name tomcat_svc
    action :stop
end 

directory "#{base_folder}#{prestige_solr}" do
    action :delete
    recursive true
end

ruby_block 'unzip prestige software' do
    block do
        require 'rubygems'
        require 'zip'
         
        Zip::File.open("#{Chef::Config[:file_cache_path]}/#{prestige_solr}.zip") do |zf|
            zf.each do |entry|
                path = File.join(base_folder, entry.name)
                FileUtils.mkdir_p(File.dirname(path))
                zf.extract(entry, path) unless File.exist?(path)
            end
        end
    end
    action :run
end

file 'modify solr.xml' do
    path "#{base_folder}#{prestige_solr}/solr/solr.xml"
    content lazy {
        data = File::read "#{base_folder}#{prestige_solr}/solr/solr.xml"
        data = data.gsub(/<core name=\"production\" instanceDir=\"#{solr_lang}\/production" \/>/,
        "<core name=\"production\" instanceDir=\"#{base_folder}#{prestige_solr}/solr/#{solr_lang}/production\"/>")
        data = data.gsub(/<core name=\"archive\" instanceDir=\"#{solr_lang}\/archive" \/>/,
        "<core name=\"archive\" instanceDir=\"#{base_folder}#{prestige_solr}/solr/#{solr_lang}/archive\"/>")
        File::write "#{base_folder}#{prestige_solr}/solr/solr.xml", data
        data
    }
    action :create
end

file 'copy solr.war' do
    path lazy {"#{tomcat_folder}/webapps/solr.war"}
    content lazy {File::binread "#{base_folder}#{prestige_solr}/webapps/solr.war"}
    action :create
end

template 'tomcat config' do
    path "#{tomcat_folder}/conf/Catalina/localhost/solr.xml"
    source 'tomcat-config.xml.erb'
    variables({
        'tomcat_solr_war' => "#{tomcat_folder}/webapps/solr.war",
        'solr_home_dir' => "#{base_folder}#{prestige_solr}/solr"
    })
    action :create
end

file 'modify tomcat server.xml' do
    path "#{tomcat_folder}/conf/server.xml"
    content lazy {
        require 'nokogiri'
        doc  = Nokogiri::XML(File::read "#{tomcat_folder}/conf/server.xml")
        xml_node = doc.at_xpath("/Server/Service/Connector[@port='8080']")
        xml_node.set_attribute('URIEncoding', 'UTF-8')
        doc.to_s()
    }
    action :create
end

file 'remove download zip' do
    path "#{Chef::Config[:file_cache_path]}/#{prestige_solr}.zip"
    action :delete
    only_if {File::exists? "#{Chef::Config[:file_cache_path]}/#{prestige_solr}.zip"}
end

service 'tomcat start' do
    service_name tomcat_svc
    action :start
end


# # encoding: utf-8

# Inspec test for recipe apache_tomcat_windows::solr

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

# Check Solr folder copied
describe directory('c:\\prestige_solr_4_5_1') do
    it { should exist }
end

# Check core files updated
describe file('c:\\prestige_solr_4_5_1\\solr\\solr.xml') do
    its('content') { should match %r|<solr.*>.*<cores.*>.*<core.*instanceDir="c:\\prestige_solr_4_5_1\\solr\\eng\\production"|m }
    its('content') { should match %r|<solr.*>.*<cores.*>.*<core.+instanceDir="c:\\prestige_solr_4_5_1\\solr\\eng\\archive"|m }
end

# Check the WAR file is copied
describe file('c:\\Program Files\\Apache Software Foundation\\Tomcat 7.0\\webapps\\solr.war') do
    it { should exist }
end

# Check that the Solr sl4j libraries have been copied
describe file('c:\\Program Files\\Apache Software Foundation\\Tomcat 7.0\\lib\\jcl-over-slf4j-1.6.6.jar') do
    it { should exist }
end

describe file('c:\\Program Files\\Apache Software Foundation\\Tomcat 7.0\\lib\\jul-to-slf4j-1.6.6.jar') do
    it { should exist }
end

describe file('c:\\Program Files\\Apache Software Foundation\\Tomcat 7.0\\lib\\log4j-1.2.16.jar') do
    it { should exist }
end

describe file('c:\\Program Files\\Apache Software Foundation\\Tomcat 7.0\\lib\\slf4j-api-1.6.6.jar') do
    it { should exist }
end

describe file('c:\\Program Files\\Apache Software Foundation\\Tomcat 7.0\\lib\\slf4j-log4j12-1.6.6.jar') do
    it { should exist }
end

# Check the Solr runtime config has been created
describe file('c:\\Program Files\\Apache Software Foundation\\Tomcat 7.0\\conf\\Catalina\\localhost\\solr.xml') do
    it { should exist }
end

# Check the server XML is updated
describe file("c:\\Program Files\\Apache Software Foundation\\Tomcat 7.0\\conf\\server.xml") do
    its('content') { should match %r|<Server.*<Service.*<Connector.*port="8080".*URIEncoding="UTF-8"|m }
end 

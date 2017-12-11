# # encoding: utf-8

# Inspec test for recipe apache_tomcat_windows::install

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe service('tomcat7') do
  it { should be_installed }
  it { should be_running }
end

describe directory('C:\\program files\\Apache Software Foundation\\Tomcat 7.0') do
  it { should exist }
end

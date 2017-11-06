# # encoding: utf-8
#
# Inspec test for recipe trendmicro::default
#
# Copyright:: 2017, REAN Cloud LLC, All Rights Reserved.

# http://inspec.io/docs/reference/resources/file/
describe file('/tmp') do
  it { should exist }
end

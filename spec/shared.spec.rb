require 'rubygems'
require 'rspec/autorun'
require '../lib/shared.rb'
require 'fileutils'

# redefine it, to prevent confusion with "real" dirs
def base_storage_dir
    './temp_test'
end

describe 'stuff' do

  before do
    Dir.mkdir base_storage_dir
    @camera_dir = base_storage_dir + "/test_camera"
	Dir.mkdir @camera_dir
  end

  it 'should sort by alphabetical' do
    a= @camera_dir + '/2013-01-02'
    b= @camera_dir + '/2012-12-31'
    c= @camera_dir + '/2012-12-01'
	all = [a,b,c]
	for dir in all
	  Dir.mkdir dir
	end
    get_sorted_day_dirs.should == [a,b,c]
  end
  
  after do
    FileUtils.rm_rf base_storage_dir
  end

end
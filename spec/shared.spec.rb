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
    FileUtils.rm_rf base_storage_dir
    Dir.mkdir base_storage_dir
    @camera_dir = base_storage_dir + "/test_camera"
	Dir.mkdir @camera_dir
  end

  it 'should sort by alphabetical' do
    a= @camera_dir + '/2013-01-02'
    b= @camera_dir + '/2012-12-31'
    c= @camera_dir + '/2012-12-01'
    d= @camera_dir + '/2013-01-30'
	e = @camera_dir + '/2012-01-01'
	f = @camera_dir + '/2012-01-30'
	g = @camera_dir + '/2012-10-20'
	all = [a,b,c,d,e,f,g]
	for dir in all.shuffle
	  Dir.mkdir dir
	end
	# should be oldest first
    get_sorted_day_dirs.should == [e,f,g,c,b,a,d]
  end
  
  after do
    FileUtils.rm_rf base_storage_dir
  end

end
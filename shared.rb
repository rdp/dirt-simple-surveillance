
def get_sorted_day_dirs
			dirs = Dir['captured_video/*/*']
			dirs.sort_by{|name| name.split('/')[2]}
end

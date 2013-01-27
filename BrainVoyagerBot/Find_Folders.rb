require 'find'
paths = ARGV[0]

folders = paths.split("%%%")

bv_folders = []

dirs = []

folders.each do |a|
    Find.find(a) do |path|
        if FileTest.directory?(path) && !(File.basename(path)[0] == ".snapshot")
            dirs << path
        end
    end
end

dirs.each do |dir|
    if Dir.entries(dir).any? {|file| file =~ /.fmr/}
        bv_folders << dir
    end
end

if bv_folders.size > 0
    output = bv_folders.join("&&")
else
    output = ""
end

print output

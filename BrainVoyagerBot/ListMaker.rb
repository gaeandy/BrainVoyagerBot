path_list       = ARGV[0]
textfile_name   = ARGV[1]
run_number = ARGV[2]

regex = ".*[Rr]un#{run_number}.*fmr"

textfile_name = textfile_name.gsub(/'/, "")

path_list = path_list.split("%%%")

# Create empty array for "subjects" hash
subjects = []

# Copy the path of each subject's main directory to the "subjects" hash, with key :base_path
path_list.each do |dir|
    subjects << { :base_path => dir }
end

# Populate "subjects" hash with the path to each subject's _BV folder, and the path to all FMR files in each subject's _BV folder
subjects.each do |subject|
    # Search the contents of each _BV folder for files ending in "*.fmr,"
    # Copy the paths of matching files to "subjects" hash with key :fmr_files
    
    bv_dir_entries      = Dir.entries(subject[:base_path])
    subject[:fmr_files] = bv_dir_entries.grep(/^.+fmr/) { |match| File.join(subject[:base_path], match) }
    subject[:target_fmr] = bv_dir_entries.grep(/#{regex}/) {|match| File.join(subject[:base_path], match)}
end


# Make a single array with all FMR files (from all subjects)
all_fmr_files = subjects.map { |subject| subject[:fmr_files] }.flatten

text_file = File.new(textfile_name, "w")

text_file.puts(all_fmr_files.size)
text_file.puts(all_fmr_files)
text_file.puts("TARGETFMRs")

# Print the path to each subject's target FMR file as many times as the number of FMR files in that subject's _BV directory
# NOTE: this is the reason for indexing with hash/key above (in case each subject has a different
# number of FMR files, for example if you have two subjects from separate studies)
subjects.each do |subject|
    subject[:fmr_files].size.times do
        text_file.puts(subject[:target_fmr])
    end
end

text_file.close

send_path = textfile_name
print send_path
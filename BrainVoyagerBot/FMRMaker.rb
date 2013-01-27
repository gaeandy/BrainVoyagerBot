PATH = ARGV[0]

# This function gets all the files inside of the parent file and excludes dotfiles and extra stuff
# The function returns a list of paths to all folders inside the parent folder when run
# Parameters: parent folder, and an optional regular expression (items that match the regex will be excluded along with the dotfiles, etc.)
def all_children_except(parent_folder, extra_regex = '')
    # This matches dotfiles and extra stuff
    regex = '^\.'
    # This adds the user's extra regex unless the user didn't provide that parameter
    regex += '|' + extra_regex unless extra_regex.empty?
    
    Dir.entries(parent_folder).reject { |file| file =~ Regexp.new(regex) }.map { |file| File.expand_path(file, parent_folder) }
end

# Create empty array for "subjects" hash
subjects = []

# Determine whether this is a single subject by checking whether any folders within the parent folder contain "EPI"
if all_children_except(PATH).any? { |child_dir| child_dir =~ /EPI/ }
    # This is a single subject, so our subject_directories variable is the path of the folder dropped
    # NOTE: We are essentially saying PATH = PATH, but giving it a new name, subject_directories
    subject_directories = [PATH]
    else
    # There's more than one subject, so subject_directories will be the paths to the folders inside the dropped folder
    subject_directories = all_children_except(PATH)
end

# Copy each path in subject_directories to the "subjects" hash, with key :base_path
subject_directories.each do |dir|
    subjects << { :base_path => dir }
end

# The following do block goes through each subject folder (each folder in subject_directories) to get the following information:
# Path to dicom source file for each run (fmr_source_files)
# Name of each run (names)
# Full path to each run folder (run_folders)

subjects.each do |subject|
    # Set up arrays to contain the information for FMR source files, names, run folders
    subject[:fmr_source_files] = []
    subject[:names] = []
    subject[:run_folders] = []
    
    # Make _BV directory in the subject's folder
    # Set subj_id to the name of the subject's folder
    subj_id = File.basename(subject[:base_path])
    # Set bv_folder to the subject id plus _BV at the beginning
    bv_folder = "_BV-#{subj_id}"
    # Make a directory inside the subject's folder, and call it "_BV-subj_id" (bv_folder)
    Dir.mkdir(File.join(subject[:base_path], bv_folder)) unless File.exists?(File.join(subject[:base_path], bv_folder))
    
    # Set variable run_folders to all folders inside the subject's directory except ones
    # that match the regular expresssion "1_localizer|2_Trufi" (neither of those folders will be included)
    run_folders = all_children_except(subject[:base_path], '1_localizer|2_Trufi')
    
    # Go through each folder in run_folders
    run_folders.each do |run_folder|
        # Is the folder a functional run? Check by using a regular expression to match EPI in the folder name
        # If folder is a functional run...
        if run_folder =~ /EPI/
            # Get the folder name using a regular expression to grab all text after "EPI_"
            # Add it to subject's hash with key :names
            subject[:names] << run_folder.match(/EPI_(.*)/)[1]
            # Get the FMR source file - take path of first file inside the run folder
            subject[:fmr_source_files] << all_children_except(run_folder).first
            # Add the path of the current folder to :run_folders
            subject[:run_folders] << run_folder
        end
    end
end

# Make an empty array to contain the output information that we'll send back to the AppleScript
output = []

# Right now, the subjects hash contains the following for each subject:
# :base_path        => path
# :fmr_source_files => [filepath1, filepath2, etc.]
# :names            => [name1, name2, etc.]
# :run_folders      => [path1, path2, etc.]
# For the output, we want an array of lists which contain the information we need to make each individual FMR.
# For a single FMR file, this would be:
# :base_path
# :fmr_sourcefile[file1]
# :names[name1]
# :run_folders[path1]

# The following block goes through the subjects hash, and for every subject, for every run, adds the fmr source file,
# name, etc., to the output as a single string with commas separating each variable

subjects.each do |subject|
    subject[:names].each_with_index do |name, i|
        bv_path      = File.join(subject[:base_path], '_BV-')
        subj_id      = File.basename(subject[:base_path])
        bv_folder    = "#{bv_path}#{subj_id}"
        save_path    = "#{bv_folder}/#{subj_id}_#{name}.fmr"
        fmr_filename = "#{subj_id}_#{name}.fmr"
        output << [subject[:fmr_source_files][i], name, save_path, fmr_filename, bv_folder, subject[:run_folders][i]].join(',')
    end
end

# Finally, join all the items in output with && so that the AppleScript can parse them back into individual arrays
puts output.join("&&")
# Set variables for each of the items sent to the script from the AppleScript:

# Path to dropped folder
PATH = ARGV[0]
# Text file name
textfile_name = ARGV[1]
# Number of slices in data set
slice_number = ARGV[2]
# Row number
row_number = ARGV[3]
# Resolution
resolution = ARGV[4]

# Setupt a filename for the text file that will be created (whatever the user entered plus ".txt")
textfile_name = textfile_name + ".txt"

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
# Number of volumes (volumes_count)
# NOTE: In FMR Maker script for 2mm data, we don't need to store the number of volumes because it's obtained from the header. This isn't possible with JavaScript,
#  so we need to collect the information now in order to feed it into the BrainVoyager command when we run the JavaScript file
# Name of each run (names)
# Full path to each run folder (run_folders)

subjects.each do |subject|
    # Set up arrays to contain the information for FMR source files, number of volumes, names, run folders
    subject[:fmr_source_files] = []
    subject[:volumes_count] = []
    subject[:names] = []
    subject[:run_folders] = []
    
    # Make _BV directory in the subject's folder
    # Set subj_id to the name of the subject's folder
    subj_id = File.basename(subject[:base_path])
    # Set bv_folder to the subject id plus _BV at the beginning
    bv_folder = "_BV-#{subj_id}"
    # Make _BV directory
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
            # Get the number of volumes (use a regular expression to count the number of files ending in ".dcm" - just in case there are other files in the folder for some reason)
            subject[:volumes_count] << all_children_except(run_folder).grep(/\.dcm/).size
            # Add the path of the current folder to :run_folders
            subject[:run_folders] << run_folder
        end
    end
end

# Get all the fmr source files from the subjects hash and store them in the variable "all_source_files"
all_source_files = subjects.map { |subject| subject[:fmr_source_files] }.flatten

# Make an empty array to contain the output information that we'll send back to the AppleScript
output = []

# Right now, the subjects hash contains the following for each subject:
# :base_path        => path
# :fmr_source_files => [filepath1, filepath2, etc.]
# :volumes_count    => number
# :names            => [name1, name2, etc.]
# :run_folders      => [path1, path2, etc.]
# For the output, we want to print out the information needed to create one FMR file, line by line
# For a single FMR file, this would be:
# :base_path
# :fmr_sourcefile[file1]
# :volumes_count
# :names[name1]
# :run_folders[path1]

# The following block goes through the subjects hash, and for every subject, for every run, adds the fmr source file,
# name, etc., to the output array. This way, when we are writing the the text file, we can simply print the output array
# And it will list each array member on a new line

subjects.each do |subject|
    subject[:names].each_with_index do |name, i|
        bv_path      = File.join(subject[:base_path], '_BV-')
        subj_id      = File.basename(subject[:base_path])
        bv_folder    = "#{bv_path}#{subj_id}"
        save_path    = "#{bv_folder}/#{subj_id}_#{name}.fmr"
        fmr_filename = "#{subj_id}_#{name}.fmr"
        output << [subject[:fmr_source_files][i], subject[:volumes_count][i], name, bv_folder, fmr_filename]
    end
end

text_file = File.new(textfile_name, "w")
# Print total number of files to be processed (i.e. size of the variable all_source_files)
text_file.puts(all_source_files.size)
# Print slice number
text_file.puts(slice_number)
# Print row_number
text_file.puts(row_number)
# Print resolution
text_file.puts(resolution)
text_file.puts(output)
text_file.close

# Make an array with the path to the text file
send_path = []
# Store the textfile path in the send_path array
send_path << textfile_name

# Send the path back to the AppleScript
print send_path
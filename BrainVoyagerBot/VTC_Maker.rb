# Get the path sent from the AppleScript (this is the path to the folder that the user dropped on the application)
PATH = ARGV[0]
target_resolution = ARGV[1]
path_to_javaScript = ARGV[2]

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

# Create empty arrays for files and fmr_files
files = []
fmr_files = []

# Get the contents of the dropped folder and store it in the variable subject_directories
subject_directories = all_children_except(PATH)

# Set base_name to the full path of the dropped folder
base_name = PATH

# Check whether dropped folder follows "_BV" naming convention
if File.basename(PATH).include? "_BV"
    # It does, so set subject ID using regular expression to match folder name after "_BV-"
    subject_id = File.basename(PATH).match(/[^_BV-].*/)
    textfile_name = "#{base_name}#{subject_id}.txt"
    else
    # It doesn't, so set subject_id to an empty string
    subject_id = ""
    textfile_name = "#{base_name}VTC_Creator.txt"
end

# This block of code is necessary because BrainVoyager incorrectly writes coordinates to the .bbx Bounding Box file (it mixes up XYZ values)
# To deal with this, we'll read BrainVoyager's .bbx file and descramble it to set new X, Y, and Z variables that correspond to the actual values
# X coordinates should be what BrainVoyager thinks Z's coordinates are
# Y coordinates should be what BrainVoyager thinks X's coordinates are
# Z coordinates should be what BrainVoyager thinks Y's coordinates are

# Find the .bbx file in the subject's folder
coordinates_file = subject_directories.select {|file| file =~ /.bbx/}.first
# Store the content of the .bbx file in the variable content
content = File.open(coordinates_file)
# Read the content, storing each line in the variable text
text = content.readlines

# Set X, Y, and Z to the line of text in the .bbx file that corresponds to the listed coordinates
# Use a regular expression to parse out four match groups per line: "BVDim:", the first set of digits, a space, and the second set of digits
x = text[2].match(/(BV.*X\: )(\d+)( )(\d+)/)
y = text[3].match(/(BV.*Y\: )(\d+)( )(\d+)/)
z = text[4].match(/(BV.*Z\: )(\d+)( )(\d+)/)
# Make new variables for X, Y, Z
# Set new_x to the first matching group from x ("BVDimX: "), plus the 2nd and 4th match groups from Z, separated by a space
new_x = (x[1] + z[2] + ' ' + z[4])
# Set new_y to the first matching group from y ("BVDimY: "), plus the 2nd and 4th match groups from x, separated by a space
new_y = (y[1] + x[2] + ' ' + x[4])
# Set new_z to the first matching group from z ("BVDimZ: "), plus the 2nd and 4th match groups from y, separated by a space
new_z = (z[1] + y[2] + ' ' + y[4])

# Go through the files in the subject's folder, and get the path to the Anat.vmr, _IA, and _FA files using a regular expression
# Store the paths in the files array
subject_directories.each do |file|
    if file =~ /Anat-Framed.vmr/
        files << file
    end
    if file =~ /_IA/
        files << file
    end
    if file =~ /_FA.trf/
        files << file
    end
end

# Go through the files in the subject's folder, and get the path to the fully preprocessed .fmr files using a regular expression
# Store the paths in the fmr_files array
subject_directories.each do |file|
    if file =~ /_THPGLMF2c.fmr/
        fmr_files << file
    end
end

# Total number of lines in file
number = (fmr_files.count)+3

# Make a new text file
text_file = File.new(textfile_name, "w")

# Print the total number of lines in the file on the first line
text_file.puts(number)

# Print the paths to the Anat.vmr, _IA, and _FA files (stored in the files array)
files.each do |path|
    text_file.puts(path)
end

# Print the paths to each .fmr file (stored in the fmr_files array)
fmr_files.each do |path|
    text_file.puts(path)
end

# Print out the new X, Y, and Z coordinates
text_file.puts(new_x)
text_file.puts(new_y)
text_file.puts(new_z)

# Close the text file
text_file.close

line_67 = "make_VTC = VMR.CreateVTCInVMRSpace(fmr_files[i], IA_path, FA_path, vtc_names[i], 1, #{target_resolution}, 1, 100);"
line_74 = "filename = String(\"#{textfile_name}\");"

contents = File.read(path_to_javaScript).split("\n")

contents[67] = line_67
contents[74] = line_74
File.open(path_to_javaScript, "wb") do |file|
    file.write(contents.join("\n"))
end

# Store the textfile path in the send_path array
send_path = textfile_name

# Send the path back to the AppleScript
print send_path

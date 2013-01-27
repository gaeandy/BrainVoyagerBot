--
--  AppDelegate.applescript
--  BrainVoyagerBot
--
--  Created by Deb Johnson on 12/3/12.
--  Copyright (c) 2012 Deb. All rights reserved.
--
property NSMutableArray : class "NSMutableArray"
property NSImage : class "NSImage"
property NSWindow : class "NSWindow"

script AppDelegate
	property parent : class "NSObject"
    property aTableView : missing value
    property aWindow : missing value
    property processingWindow : missing value
    property thePath : ""
    property theDataSource : {}
    property displayPath: ""
    property displayListGeneratorOutput: missing value
    property runNumberField: missing value
    property selectedSubjectDirs: {}
    property subjectDirs: {}
    property newSubjectDirs: ""
    property listGeneratorTextFile: ""
    property runNumber: ""
    property theProgressBar: missing value
    property theFMRFolder: ""
    property displayFMRFolder: missing value
    property processingLabel: missing value
    property FMRCreationComplete: missing value
    property resetButton: missing value
    property returnedItems: ""
    property file_groups: ""
    property displayHelperFolder: missing value
    property helperFolder: ""
    property displayHelperOutput: missing value
    property helperTextFile: ""
    property sliceNumberField: missing value
    property rowNumberField: missing value
    property resolutionField: missing value
    property myNotification: missing value
    property vtcFolder: ""
    property vtcFolderField: missing value
    property subjectDirsTest: {}
    property generateButton: missing value
    property targetResolution: ""
    property targetResolutionPopup: missing value
    property pathToVTCJavaScript: ""
    property textFileError: "The text file was created successfully, but BrainVoyagerBot cannot communicate with BrainVoyager when the Welcome dialog is open. Click Accept, then click Scripts > Edit and Run Scripts from the BrainVoyager menu."
    property FMRMakerError: "BrainVoyagerBot cannot communicate with BrainVoyager when the Welcome pane is open. Click Accept in BrainVoyager to start FMR creation"
    
    on ClickSelectGeneratorFolders_(sender)
        set findFoldersScript to generatePathToScript("Find_Folders.rb")
        tell application "Finder"
            set _folders to choose folder with multiple selections allowed
            repeat with _folder in _folders
                set tempFolder to POSIX path of _folder as string
                set nextTemp to quoted form of tempFolder
                copy nextTemp to the end of selectedSubjectDirs
            end repeat
        end tell
        set sendSubjectDirs to arrayToString(selectedSubjectDirs, "%%%")
        set returned_subject_dirs to do shell script "ruby " & findFoldersScript & " " & sendSubjectDirs
        set AppleScript's text item delimiters to "&&"
        set the_dirs to text items of returned_subject_dirs
        if (count of the_dirs) > 0
            repeat with i from 1 to count of the_dirs
                set this_directory to item i of the_dirs
                set this_item to quoted form of (this_directory as string)
                copy this_item to the end of subjectDirs
                set folder_name to name of (info for this_directory)
                set newData to {thePath:folder_name}
                theDatasource's addObject_(newData)
                aTableView's reloadData()
            end repeat
        else
            tell application "Finder"
                display dialog("No FMR files found in selected folders or subdirectories of selected folders! Please select folders that contain FMR files, folders whose subdirectories contain FMR files.")
            end tell
        end if
        set selectedSubjectDirs to {}
        tell current application
            activate
            runNumberField's becomeFirstResponder()
        end tell
    end ClickSelectGeneratorFolders_

    on selectOutputLocation_(sender)
        set listGeneratorTextFile to setOutputFilePath(displayListGeneratorOutput)
        generateButton's becomeFirstResponder()
    end selectOutputLocation_

    on selectHelperOutput_(sender)
        set helperTextFile to setOutputFilePath(displayHelperOutput)
    end selectHelperOutput_
    
    on ClickSelectFolderFMRMaker_(sender)
        set theFMRFolder to setFolderPath(displayFMRFolder)
    end ClickSelectFolderFMRMaker_

    on ClickSelectHelperFolder_(sender)
        set helperFolder to setFolderPath(displayHelperFolder)
        sliceNumberField's becomeFirstResponder()
    end ClickSelectHelperFolder_

    on ClickSelectVTCFolder_(sender)
        tell application "Finder"
            set selectedVtcFolder to (choose folder with prompt "Select a folder to process.")
        end tell
        checkIfFileExists("_IA", selectedVtcFolder, "Initial Alignment (_IA.trf)", "VTC Creation")
        checkIfFileExists("_FA", selectedVtcFolder, "Fine-tuning Alignment (_FA.trf)", "VTC Creation")
        checkIfFileExists(".bbx", selectedVtcFolder, "bounding box (.bbx)", "VTC Creation")
        set tempvtcfolder to POSIX path of selectedVtcFolder
        set vtcFolder to quoted form of tempvtcfolder
        set vtcFolderName to name of (info for selectedVtcFolder)
        vtcFolderField's setStringValue_(vtcFolderName)
        tell current application to activate
    end ClickSelectVTCFolder_
        
    on ClickStartListGenerator_(sender)
        set theRunNumber to (runNumberField's intValue()) as string
        set subjectDirs to arrayToString(subjectDirs, "%%%")
        set theScript to generatePathToScript("ListMaker.rb")
        set returned_path to do shell script "ruby " & theScript & " " & subjectDirs & " \"" & listGeneratorTextFile & "\" \"" & theRunNumber & "\""
        set AppleScript's text item delimiters to ""
        set path_to_text_file to items of returned_path as string
        openTextFileLocation(path_to_text_file)
        displayListGeneratorOutput's setStringValue_("")
        theDataSource's removeAllObjects()
        set subjectDirs to {}
        aTableView's reloadData()
        runNumberField's setStringValue_("")
        sendNotificationWithTitle_AndMessage_("BrainVoyager Bot Notification","Text file creation complete!")
    end ClickStartListGenerator_

    on ClickStartFMRMaker_(sender)
        processingWindow's makeKeyAndOrderFront_(processingWindow)
        processingLabel's setStringValue_("Preparing BrainVoyager for FMR creation...")
        theProgressBar's startAnimation_(theProgressBar)
        delay 2
        BrainVoyagerRunningTest(FMRMakerError, 1, 0)
        set FMRMakerScript to generatePathToScript("FMRMaker.rb")
        set returned_items to do shell script "ruby " & FMRMakerScript & " " & theFMRFolder
        set AppleScript's text item delimiters to "&&"
        set file_groups to text items of returned_items
        set minimum to 1
        set maximum to (count of file_groups)
        set totalNumber to (maximum as string)
        theProgressBar's setIndeterminate_(false)
        theProgressBar's setMinValue_(minimum)
        theProgressBar's setMaxValue_(maximum)
        set incrementValue to (maximum/100)
        repeat with i from 1 to count of file_groups
            theProgressBar's setDoubleValue_(i)
            theProgressBar's incrementBy_(incrementValue)
            theProgressBar's displayIfNeeded()
            set currentFileNumber to (i as string)
            log "Current File Number is:" & currentFileNumber
            set displayMessage to "Creating " & currentFileNumber & " of " & totalNumber & " FMR files"
            log displayMessage
            processingLabel's setStringValue_(displayMessage)
            delay 2
            set variable to item i of file_groups
            set AppleScript's text item delimiters to ","
            set final_list to text items of variable
            set source_file to first item of final_list
            set file_name to second item of final_list
            set save_path to third item of final_list
            set fmr_filename to fourth item of final_list
            set save_folder to fifth item of final_list
            set run_folder to sixth item of final_list
            tell application "BrainVoyager QX"
                create fmr mosaic project from first source file source_file number to skip volumes 0 number of slice rows 64 number of slice columns 64
                save in document "untitled.fmr" file save_path
                close document fmr_filename saving no
            end tell
            tell application "Finder"
                set thePath to POSIX file run_folder as alias
                set thefiles to (every file of folder (thePath) whose name contains "untitled")
                repeat with theCurrentValue in thefiles
                    delete {theCurrentValue}
                end repeat
            end tell
        end repeat
        processingWindow's performClose_(processingWindow)
        displayFMRFolder's setStringValue_("")
        set theFMRFolder to ""
        sendNotificationWithTitle_AndMessage_("BrainVoyagerBot Notification","FMR Creation Complete!")
    end ClickStartFMRMaker_

    on ClickStartFMRHelper_(sender)
        set FMRHelperScript to generatePathToScript("FMR_Creation_Helper.rb")
        set sliceNumber to (sliceNumberField's intValue()) as string
        set rowNumber to (rowNumberField's intValue()) as string
        set resolution to (resolutionField's intValue()) as string
        set the_path to do shell script "ruby " & FMRHelperScript & " " & helperFolder & " " & helperTextFile & " " & sliceNumber & " " & rowNumber & " " & resolution & " "
        copyPathToClipBoard(the_path)
        sliceNumberField's setStringValue_("")
        rowNumberField's setStringValue_("")
        resolutionField's setStringValue_("")
        displayHelperFolder's setStringValue_("")
        displayHelperOutput's setStringValue_("")
        BrainVoyagerRunningTest(textFileError, 0, 1)
        sendNotificationWithTitle_AndMessage_("BrainVoyagerBot Notification","Text file creation complete, and the path has been copied to the clipboard!")
    end ClickStartFMRHelper_

    on copyPathToClipBoard(pathSent)
        set AppleScript's text item delimiters to ""
        set filePath to items of pathSent as string
        set the clipboard to filePath
        return filePath
    end copyPathToClipBoard

    on ClickStartVTCMaker_(sender)
        set pathToVTCJavaScript to POSIX path of (path to documents folder as text) & "BVQXExtensions/Scripts/VTC_Maker.js"
        set popupIndex to (targetResolutionPopup's indexOfSelectedItem()) as integer
        set targetResolution to ((popupIndex + 1) as string)
        set VTCMakerScript to generatePathToScript("VTC_Maker.rb")
        set the_path_returned to do shell script "ruby " & VTCMakerScript & " " & vtcFolder & " " & targetResolution & " " & pathToVTCJavaScript
        set text_file_path to copyPathToClipBoard(the_path_returned)
        BrainVoyagerRunningTest(textFileError, 0, 1)
        openTextFileLocation(text_file_path)
        sendNotificationWithTitle_AndMessage_("BrainVoyagerBot Notification","Text file creation complete! VTC_Maker.js has been updated with the selected target resolution and text file path.")
    end ClickStartVTCMaker_

    on clickClearAll_(sender)
        theDataSource's removeAllObjects()
        set subjectDirs to {}
        aTableView's reloadData()
    end clickClearAll_

    on clickDeleteRow_(sender)
        set theSelectedRow to aTableView's selectedRow
        set subjectDirs to deleteItem(subjectDirs, theSelectedRow)
        theDataSource's removeObjectAtIndex_(theSelectedRow)
        aTableView's reloadData()
    end clickDeleteRow_

    on openTextFileLocation(pathToTextFile)
        tell application "Finder"
            activate
            set open_folder to POSIX file pathToTextFile as alias
            set theContainer to (container of open_folder)
            open theContainer
        end tell
    end openTextFileLocation

    on arrayToString(theArray, theString)
        set AppleScript's text item delimiters to ""
        set defaultDelim to AppleScript's text item delimiters
        set AppleScript's text item delimiters to "%%%"
        set theNewArray to theArray as string
        set AppleScript's text item delimiters to defaultDelim
        return theNewArray
    end arrayToString

    on setFolderPath(displayField)
        tell application "Finder"
            set temporaryPath to POSIX path of (choose folder with prompt "Select a folder to process.")
        end tell
        set theFolderPath to quoted form of temporaryPath
        set displayName to name of (info for temporaryPath)
        displayField's setStringValue_(displayName)
        tell current application to activate
        return theFolderPath
    end setFolderPath

    on setOutputFilePath(fieldName)
        tell application "Finder"
            set selectedFileName to POSIX path of (choose file name with prompt "Select a name and location for the text file." default name "")
        end tell
        set pathToDisplay to selectedFileName as text
        fieldName's setStringValue_(pathToDisplay)
        tell current application to activate
        if selectedFileName contains ".txt"
            set pathToSend to selectedFileName
        else
            set pathToSend to selectedFileName & ".txt"
        end if
        return quoted form of pathToSend
    end setOutputFilePath

    on generatePathToScript(scriptName)
        set pathToScript to POSIX path of (current application's NSBundle's mainBundle()'s resourcePath() as text) & "/" & scriptName & ""
        set quotedPath to quoted form of pathToScript
        return quotedPath
    end generatePathToScript

    on checkIfFileExists(fileExtension, folderPath, errorDesc, requiringProcess)
        set errorPart1 to "The folder you dropped does not contain the necessary "
        set errorPart2 to " file that is required for " & requiringProcess & ". Please choose a folder that contains this file."
        tell application "Finder"
            if exists (some file in folderPath whose name contains fileExtension) then
                (* do nothing *)
            else
                display dialog (errorPart1 & errorDesc & errorPart2)
                error number -128
            end if
        end tell
    end checkIfFileExists

    on BrainVoyagerRunningTest(errorMessage, forceDelay, menuClick)
        tell application "System Events"
            if exists some process whose name is "BrainVoyager QX"
                if exists (some window of process "BrainVoyager QX" whose name is "Welcome")
                    set welcomeOpen to 1
                else
                    set welcomeOpen to 0
                end if
            else
                set welcomeOpen to 1
                tell application "BrainVoyager QX" to activate
                repeat until (exists some process whose name is "BrainVoyager QX")
                    (* do nothing *)
                end repeat
                repeat until (exists some window of process "BrainVoyager QX" whose name is "Welcome") is true
                   (* do nothing *)
                end repeat
            end if
        end tell
        if welcomeOpen = 1
            tell application "Finder"
                activate
                display dialog(errorMessage)
            end tell
        else
            if menuClick = 1
                menu_click({"BrainVoyager QX", "Scripts", "Edit and Run Scripts..."})
            end if
        end if
        if forceDelay = 1
            processingLabel's setStringValue_("Waiting for user to close Welcome pane...")
            tell application "System Events"
             repeat until (exists some window of process "BrainVoyager QX" whose name is "Welcome") is false
                    (* do nothing *)
               end repeat
            end tell
        end if
    end BrainVoyagerRunningTest

    on windowShouldClose_(sender)
        return true
    end windowShouldClose
    
    on tableView_objectValueForTableColumn_row_(aTableView, aColumn, aRow)
        if theDataSource's |count|() is equal to 0 then return end
        set ident to aColumn's identifier
        set theRecord to theDataSource's objectAtIndex_(aRow)
		set theValue to theRecord's objectForKey_(ident)
        return theValue
	end tableView_objectValueForTableColumn_row_
	
    on numberOfRowsInTableView_(aTableView)
        try
			if theDataSource's |count|() is equal to null then
				return 0
            else
                return theDataSource's |count|()
			end if
            on error
			return 0
		end try
	end numberOfRowsInTableView_
    
    on tableView_sortDescriptorsDidChange_(aTableView, oldDescriptors)
		set sortDesc to aTableView's sortDescriptors()
		theDataSource's sortUsingDescriptors_(sortDesc)
		aTableView's reloadData()
	end tableView_sortDescriptorsDidChange_
    
    on sendNotificationWithTitle_AndMessage_(aTitle, aMessage)
        set myNotification to current application's NSUserNotification's alloc()'s init()
        set myNotification's title to aTitle
        set myNotification's informativeText to aMessage
        tell application "Finder"
            activate
            current application's NSUserNotificationCenter's defaultUserNotificationCenter's deliverNotification_(myNotification)
        end tell
    end sendNotification
        
    on menu_click(mList)
        local appName, topMenu, r
        if mList's length < 3 then error "Menu list is not long enough"
        set {appName, topMenu} to (items 1 through 2 of mList)
        set r to (items 3 through (mList's length) of mList)
        tell application "System Events" to my menu_click_recurse(r, ((process appName)'s ¬
		(menu bar 1)'s (menu bar item topMenu)'s (menu topMenu)))
    end menu_click
    
    on menu_click_recurse(mList, parentObject)
        local f, r
        set f to item 1 of mList
        if mList's length > 1 then set r to (items 2 through (mList's length) of mList)
        tell application "System Events"
            if mList's length is 1 then
                click parentObject's menu item f
                else
                my menu_click_recurse(r, (parentObject's (menu item f)'s (menu f)))
            end if
        end tell
    end menu_click_recurse
    
    on deleteItem(lst, idx)
        local lst, idx, len, ndx, l
        try
            if lst's class is not list then error "not a list." number -1704
            script k
			property l : lst
		end script
		set len to count of k's l
		set ndx to ((idx as integer) + 1)
		if ndx is 0 then
			error "index 0 is out of range." number -1728
            else if ndx < 0 then
			set ndx to len + 1 + ndx
			if ndx < 1 then error "index " & idx & ¬
            " is out of range." number -1728
            else if ndx > len then
			error "index " & idx & " is out of range." number -1728
		end if
		if ndx is 1 then
			return rest of k's l
            else if ndx is len then
			return k's l's items 1 thru -2
            else
			return (k's l's items 1 thru (ndx - 1)) & ¬
            (k's l's items (ndx + 1) thru -1)
		end if
        on error eMsg number eNum
            error "Can't deleteItem: " & eMsg number eNum
        end try
    end deleteItem

    on applicationShouldHandleReopen_hasVisibleWindows_(sender, flag)
        if flag
            return false
        else
            aWindow's makeKeyAndOrderFront_(aWindow)
            return true
        end if
    end applicationShouldHandleReopen_hasVisibleWindows_

    on awakeFromNib()
        aWindow's setRestorable_(false)
        processingWindow's setRestorable_(false)
        set theDataSource to NSMutableArray's alloc()'s init()
        set theData to {}
        theDataSource's addObjectsFromArray_(theData)
		aTableView's reloadData()
	end awakeFromNib
    
    on applicationWillFinishLaunching_(aNotification)
		-- Insert code here to initialize your application before any files are opened
	end applicationWillFinishLaunching_
	
	on applicationShouldTerminate_(sender)
		-- Insert code here to do any housekeeping before your application quits
		return current application's NSTerminateNow
	end applicationShouldTerminate_
	
end script
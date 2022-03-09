$ThisVersion := "1.0.7_DopusDebug1"
;

/*
By		: NotNull
Info	: https://www.voidtools.com/forum/viewtopic.php?f=2&t=11194


v 1.0.6
- added support for FreeCommander
- Textual changes


Version history at the end.

*/



;_____________________________________________________________________________
;
;						SETTINGS
;_____________________________________________________________________________

#SingleInstance Force
#NoEnv
;#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input
SetBatchLines -1
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, RegEx


	$IniFile := "JumpToFolder.ini"

	
	
;	When settings not found in INI, use Out-Of-The-Box settings:
;	Also used for resetting settings
;	Icon: Use the same structure that PickIconDlg would return (for comparison).


	$OOB_everything_exe      := A_Space
	$OOB_also_search_files   := 1
	$OOB_sort_by             := "Run Count"
	$OOB_sort_ascending      := 0
	$OOB_contextmenu_text    := "Jump to Folder ..."
	$OOB_contextmenu_icon  	 := A_WinDir . "\system32\SHELL32.dll,23"

;	Non-GUI options
	$OOB_detected_everything_version	:= ""
	$OOB_everything_instance			:=	""""""
	$OOB_debug								:= 0	

;	DopusDebug
	$OOB_slowdown := 200
	


;	Read settings from INI file
	IniRead, $everything_exe,   	%$IniFile%, JumpToFolder, everything_exe,	%$OOB_everything_exe%
	IniRead, $also_search_files,	%$IniFile%, JumpToFolder, also_search_files,	%$OOB_also_search_files%
	IniRead, $sort_by,				%$IniFile%, JumpToFolder, sort_by,			%$OOB_sort_by%
	IniRead, $sort_ascending,		%$IniFile%, JumpToFolder, sort_ascending,	%$OOB_sort_ascending%
	IniRead, $contextmenu_text,	%$IniFile%, JumpToFolder, contextmenu_text,	%$OOB_contextMenu_text%
	IniRead, $contextmenu_icon,	%$IniFile%, JumpToFolder, contextmenu_icon,	%$OOB_contextMenu_icon%


;	Read non-GUI INI settings
	IniRead, $detected_everything_version,		%$IniFile%, JumpToFolder, detected_everything_version,	%$OOB_detected_everything_version%
	IniRead, $everything_instance,%$IniFile%, JumpToFolder, everything_instance,	%$OOB_everything_instance%
	IniRead, $debug,					%$IniFile%, JumpToFolder, debug,	%$OOB_debug%
	IniRead, $start_everything,	%$IniFile%, JumpToFolder, start_everything

;	DopusDebug
	IniRead, $slowdown,	%$IniFile%, JumpToFolder, slowdown, %$OOB_slowdown%


;	Expand environment variables in some ini entries
	$everything_exe 		:= ExpandEnvVars( $everything_exe )
	$contextmenu_icon		:= ExpandEnvVars( $contextmenu_icon )
	$everything_instance	:= ExpandEnvVars( $everything_instance )
	$start_everything		:= ExpandEnvVars( $start_everything )




	DebugMsg( "MAIN" , "Starting JumpToFolder version [" . $ThisVersion . "]" )


;_____________________________________________________________________________
;
;						CHECKS, PART 1
;_____________________________________________________________________________
;

;	Check if OS is 64-bit or 32-bit
;	OS and ahk.exe must have the same bitness. Else exit

	If (A_PtrSize = 8) AND ( A_Is64bitOS )			; Both 64-bit
	{
		$bitness := 64
	}
	Else If (A_PtrSize = 4) AND ( !A_Is64bitOS )	; Both 32-bit
	{
		$bitness := 32
	}
	Else If ( A_Is64bitOS )								; 64-bit Win vs 32-bit ahk
	{
		MsgBox You need the 64-bit version of JumpToFolder
		ExitApp
	}
	Else														; 32-bit Win vs 64-bit ahk
	{
		MsgBox You need the 32-bit version of JumpToFolder
		ExitApp
	}

;	Don't Check availability and bitness Everythingnn.dll
;	If not available, no incrementing runcount. No dealbreaker.
;	Bitness isn't relevant either as IPC communication is always 32-bit.
	


	$everything_instance := Trim($everything_instance," """"")

	
	
;	Parameter check.
;	4 possibilities:
;	- started through file association ("c:\path to\ahk.exe" "x:\path to script.ahk" [parms])
;	- started through renamed ahk.exe ("x:\path to\script.exe" ["x:\path to script.ahk"] [parms])
;	- started as compiled version ("X:\path to\ahk.exe" [parms])
;	- started by random ahk.exe (drag/drop script.ahk or command D:\ahk.exe "x:\path to script.ahk" [parms])
;
;	In all cases: parm1 =-jump (or nothing)


	If ( A_Args[1] != "-jump" )
	{
		Goto GUI
	}

;	We are here because parm -jump detected. Start Everything, etc ..
	
	
;_____________________________________________________________________________
;
;						CHECKS, PART 2
;_____________________________________________________________________________
;

;	Check most important (INI) settings

	IfNotExist, %$everything_exe%
	{
		MsgBox 	"%$everything_exe%" can not be found.`nCheck your JumpToFolder settings.
		; start JumpToFolder without parms to change settings
		ExitApp
	}


;	Check Everything version (1.4/1.5) if not specified in INI

	DebugMsg( "Checks" , "Everything version = [" . $detected_everything_version . "]" )

	If !( $detected_everything_version == "1.4" OR $detected_everything_version == "1.5" )
	{
		MsgBox This is not a supported Everything version.`r`n1.4 and 1.5 are supported.`r`n`r`nCheck and save your settings in the GUI.
		ExitApp
	}




;=============================================================================
;=============================================================================
;=============================================================================
;=============================================================================
;
;						MAIN PROGRAM
;
;=============================================================================
;=============================================================================
;=============================================================================
;=============================================================================

;_____________________________________________________________________________
;
;						INIT
;_____________________________________________________________________________



;	Read Doubleclick speed (system setting)

	$DoubleClickTime := DllCall("GetDoubleClickTime")



;	Define hotkeys to be used in Everything


	Hotkey, Escape,	HandleEscape, Off
	Hotkey, LButton,	HandleClickHotkey, Off
	Hotkey, Enter,		HandleEnterHotkey, Off


;	DopusDebug
	InputBox, $slowdown, Debug Mode, How far should the brake pedal be pushed (0-500)?,,,,,,,,%$slowdown%
	IniWrite, %$slowdown%, %$IniFile%, JumpToFolder, slowdown
	
;	MsgBox slowdown = [%$slowdown%]
	
	
	
;_____________________________________________________________________________
;
;   					REGULAR CODE
;_____________________________________________________________________________

;   MsgBox DEBUG: And we're off !!!


;	How and where is this started? Will return WindowType (Open/SaveAs dialog;explorer; ...)

	Gosub GetWindowType

	DebugMsg(  "MAIN" , "Detected WindowType = [" . $WindowType . "]")

;	WIP
;	If IsFunc( "PathFrom" . $WindowType )
;		MsgBox PathFrom%$WindowType% exists


;	Start Everything; select a file or folder there.

	$EverythingID := StartEverything($everything_exe)

	DebugMsg( "MAIN" , "EverythingID = [" . $EverythingID . "]" )




Loop	; Start of WinWaitActive/WinWaitNotActive loop.
{
	WinWaitActive, ahk_id %$EverythingID%

	;	Wait for Enter/Escape/ mouse double-click
	;	Read selected file/folder and ..
	;	Close Everything so we can continue with WinWaitNotActive

		DebugMsg( "Everything active" , "We are in Everything" )


	; The following hotkeys trigger getting the selected path in Everything.
	;	Returns $FolderPath and $FileName
		Hotkey, Escape,	On
		Hotkey, LButton,	On
		Hotkey, Enter,		On
		


	;	Listen for keyboard presses ESC and ENTER and respond to that.
	;	Also respond to double-click in result list.
	;	If any of those were used, Everything will be closed,
	;	so we can continue with: 


	WinWaitNotActive


		Hotkey, Escape,	Off
		Hotkey, LButton,	Off
		Hotkey, Enter,		Off

	;	DopusDebug
		Sleep %$slowdown%

	;	In case another window was activated before getting the path.
		WinClose, ahk_id %$EverythingID%

	;	DopusDebug
		Sleep %$slowdown%

	;	Prepare found path to be fed to the original application (file manager/ -dialog)
	;	using the Feed%$WindowType% routine.

	; check if found path empty. Do nothing (exit) in that case.
		If ( $FoundPath )
		{
			DebugMsg( A_ThisLabel . A_ThisFunc, "Valid Path: [" . $FoundPath . "]" )
			PathSplit($FoundPath, $FolderPath, $FileName)
			
		; Add a backslash th FolderPath
			$FolderPath := $FolderPath . "\"

			DebugMsg( A_ThisLabel . A_ThisFunc, "$FolderPath = [" .  $FolderPath .  "]`r`n$FileName = [" . $FileName . "]")

			Feed%$WindowType%( $WinID, $FolderPath, $FileName )
		}
		ExitApp


}	; End of WinWaitActive/WinWaitNotActive loop.


MsgBox We never get here (and that's how it should be)




;=============================================================================
;=============================================================================
;
;						SUBROUTINES
;
;=============================================================================
;=============================================================================


	
;_____________________________________________________________________________
;
						GetPathFromEverything(_EverythingID)
;_____________________________________________________________________________
;
{
	Global $DoubleClickTime
	Global $majorversion
	Global $detected_everything_version

	$EVERYTHING_IPC_ID_FILE_COPY_FULL_PATH_AND_NAME := 41007	

	If ( $detected_everything_version == "1.5")
	{
		ControlGetText, _FoundPath, EVERYTHING_RESULT_LIST_FOCUS1, A
		DebugMsg( A_ThisLabel . A_ThisFunc, "detected_everything_version = [" . $detected_everything_version . "]`r`nFound path = [" . _FoundPath . "]" )
	}		
	Else If ( $detected_everything_version == "1.4")
	{
	;	DopusDebug
		Sleep %$slowdown%

		_ClipOrg := ClipBoard

	;	DopusDebug
		Sleep %$slowdown%

		ClipBoard := ""

	;	DopusDebug
		Sleep %$slowdown%

		SendMessage, 0x111, %$EVERYTHING_IPC_ID_FILE_COPY_FULL_PATH_AND_NAME%,,, A
		ClipWait,1
		_FoundPath := Clipboard

	;	DopusDebug
;		MsgBox _FoundPath = %_FoundPath%

		
		DebugMsg( A_ThisLabel . A_ThisFunc, "detected_everything_version = [" . $detected_everything_version . "]" . "`r`n" . "Found path = [" . _FoundPath . "]" )

	;	DopusDebug
		Sleep %$slowdown%

		ClipBoard := _ClipOrg
	}
	else	; should never happen
	{
		MsgBox Somehow this is not really Everything 1.4 or 1.5. Check your settings.
	}

	Return _FoundPath
}



;_____________________________________________________________________________
;
						GetWindowType:
;_____________________________________________________________________________
;
;   Get handle ($WinID) of active windows
	$WinID := WinExist("A")

;   Get More info on this window

;	Get ahk_class
	WinGetClass, $ahk_class, ahk_id %$WinID%

;	Get ahk_exe
	WinGet, $ahk_exe, ProcessName, ahk_id %$WinID%

;	Get executable name including path.
;	We need this for some filemanagers that will be (re)started with parameters.

	WinGet, $Running_exe, ProcessPath, ahk_id %$WinID%

	
;	Define window type (for usage later on)
;	Detection preference order: 1. ahk_class 2. ahk_exe 

;	Ignore the Desktop

	If ( $ahk_class = "Progman" )											; Desktop
	{
		ExitApp
	}


	else If ($ahk_class = "TTOTAL_CMD")										; Total Commander
	{
		$WindowType = TotalCMD
	}

;	else If ($ahk_exe = "xplorer2_UC.exe" OR $ahk_exe = xplorer2.exe")		; XPlorer2
	else If ($ahk_class = "ATL:ExplorerFrame")								; XPlorer2
	{
		$WindowType = XPlorer2
	}


	else If ($ahk_class = "dopus.lister")									; Directory Opus
	{
		$WindowType = DirectoryOpus
	}

	else If ($ahk_class = "DClass")											; Double Commander
	{
		$WindowType = DoubleCommander
	}

;	Q-Dir has a semi-random ahk_class: class ATL:000000014018D720
;	Too risky. Fall back : ahk_exe
	else If ($ahk_exe = "Q-Dir_x64.exe" or $ahk_exe = "Q-Dir.exe")			; Q-Dir
	{
		$WindowType = QDirFileMan
	}

;	ahk_class Salamander 3 and 4 is SalamanderMainWindowVer25, but might vary.
	else If ( InStr($ahk_class, "SalamanderMainWindow") > 0)				; Altap Salamander
	{
		$WindowType = Salamander
	}

	else If ($ahk_exe = "XYplorer.exe")										; XYplorer
	{
		$WindowType = XYPlorer
	}


	else If ($ahk_exe = "explorer.exe")										; Windows File Manager
	{
	;	Win10: WorkerW = desktop  CabinetWClass = File Explorer
	;	Older: Progman = desktop  CabinetWClass = File Explorer

	;	Directory Opus intercept ShellExecute calls and will send them to Opus.
	;	That will fail with 'normal' Explorer routine.
	;	So check if shellhook is installed and use different routine.
	
		Loop, Reg, HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellExecuteHooks, V
		{
			RegRead, _shellHook, HKCR\CLSID\%A_LoopRegName%\InprocServer32
			If Instr(_shellHook, "dopus")
			{
				DopusInstalled := True
			}

		}
		If DopusInstalled
		{
			$WindowType := "ExplorerWithDopusHook"
		}
		Else
		{
			$WindowType := "ExplorerFileMan"
		}
	}

	else If ($ahk_exe = "FreeCommander.exe")	; HAs no easy entry point	; Free Commander
	{
		$WindowType = FreeCommander
	}

	else If ($ahk_class = "#32770")											; Open/Save dialog
	{

		$WindowType := SmellsLikeAFileDialog($WinID)

		If $WindowType											;	This is a supported dialog
		{
;			MsgBox WindowType = %$WindowType%
		}
		else
		{
			MsgBox Not a supported  WindowType
		}
	}

	else
	{
		MsgBox This is not (yet) supported in %$ahk_exe%  ..				; Rest
	ExitApp
	}

return




;_____________________________________________________________________________
;
				SmellsLikeAFileDialog(_thisID )
;_____________________________________________________________________________
;
{

;	Only consider this dialog a possible file-dialog when:
;	(SysListView321 AND ToolbarWindow321) OR (DirectUIHWND1 AND ToolbarWindow321) controls detected
;	First is for Notepad++; second for all other filedialogs
;	That is our rough detection of a File dialog.
;  Returns the detected dialogtype ("OpenSave"/"OpenSave_SYSLISTVIEW"/FALSE)

	WinGet, _controlList, ControlList, ahk_id %_thisID%

	Loop, Parse, _controlList, `n
	{
		If ( A_LoopField = "SysListView321"  )
			_SysListView321 := 1

		If ( A_LoopField = "ToolbarWindow321")
			_ToolbarWindow321 := 1

		If ( A_LoopField = "DirectUIHWND1"   ) 
			_DirectUIHWND1 := 1

		If ( A_LoopField = "Edit1"   ) 
			_Edit1 := 1
	}


	If ( _DirectUIHWND1 and _ToolbarWindow321 and _Edit1 ) 
	{
		Return "OpenSave"

	}
	Else If ( _SysListView321 and _ToolbarWindow321 and _Edit1 ) 
	{
		Return "OpenSave_SYSLISTVIEW"
	}
	else
	{
		Return FALSE
	}

}



;_____________________________________________________________________________
;
						StartEverything(_everything_exe)
;_____________________________________________________________________________
;
;   Start Everything (new window) withe specific settings from ini)
;	Returns the windowID
{
;	Global $everything_exe
	Global $sort_by
	Global $also_search_files
	Global $everything_instance
	Global $start_everything
	

	_folders := $also_search_files ? "" : "folder:   "


	If ( $start_everything = "ERROR" OR $start_everything = "" )
	{
	;	Get Working directory
		SplitPath, _everything_exe, , _everything_workdir
		_everything_workdir := Trim(_everything_workdir," """"")
	
		Run, "%_everything_exe%" -sort "%$sort_by%" -instance "%$everything_instance%" -details -filter "JumpToFolder" -newwindow  -search "%_folders%",%_everything_workdir%,, $EvPID
	}
	else	; special case
	{
	;	Get Working directory
		SplitPath, $start_everything, , _everything_workdir
		_everything_workdir := Trim(_everything_workdir," """"")
		
		Run, %$start_everything% -details -filter "JumpToFolder" -newwindow  -search "%_folders%",%_everything_workdir%,, $EvPID
	}

;   Wait until Everything is loaded
    WinWaitActive, ahk_class ^EVERYTHING


;	Get the ID of the window on top (assumption: that must be the freshly started Everything)
    WinGet, _thisID, ID, A


;	Remove menu bar of this Everything window (1.4)
   DllCall("SetMenu", "uint", _thisID, "uint", 0)
;	Everything 1.5 draws its own menu; disble it.
	Control Disable,, EVERYTHING_MENUBAR1, A
;	Control Hide,, EVERYTHING_MENUBAR1, A


;	OK, we started Everything;	we've got the ID of the Everything window, so we can talk to it later on.

Return _thisID
}	

	
;_____________________________________________________________________________
;
						ValidPath(_thisPath)
;_____________________________________________________________________________
;
;	Check if path exists; returns True/False
{

;		_thisPath := Trim( _thisFOLDER , "\")
;	_withoutQuotes := Trim(_thisPath," """"")
;	MsgBox  _thisPath = [%_withoutQuotes%]

;	IfNotExist, %_withoutQuotes%
	IfNotExist, %_thisPath%
	{
		return false
	}
	else
	{
		return true
	}
}
	
	
	
;_____________________________________________________________________________
;
						PathSplit(_thisPath, ByRef $FolderPath, ByRef $FileName)
;_____________________________________________________________________________
;
;   Splits path in folder- and filename part
{
	
;	Check if $Result is a file or a folder. Use this to define variables: 
;	If folder: create $FolderPath
;	If file: create $FolderPath AND $FileName
;	Those will be used in the "Feed" routines (if applicable)

		if InStr(FileExist(_thisPath), "D")
		{	; it's a folder
		;	DopusDebug
			Sleep %$slowdown%
			$FolderPath  := _thisPath
			$FileName := ""
		}
		else
		{	; it has to be a file
			SplitPath, _thisPath, $FileName, $FolderPath
			
		}
	;	DopusDebug
		Sleep %$slowdown%

		DebugMsg( A_ThisLabel . A_ThisFunc , "dir = [" . $FolderPath . "]`r`n  Name = [" . $FileName . "]" )

	
	Return
}



;_____________________________________________________________________________
;
						HandleEscape: 
;_____________________________________________________________________________
;
{
	WinClose, ahk_id %$EverythingID%
	
Return
}


;_____________________________________________________________________________
;
						HandleClickHotkey: 
;_____________________________________________________________________________
;
{

;	Detect if in Result list:
	MouseGetPos, , , , _focus

	If (_focus = "SysListView321") 
	{
		If !(A_ThisHotkey = A_PriorHotkey and A_TimeSincePriorHotkey < $DoubleClickTime)
		{ ; Single-click detected
			Send {%A_ThisHotkey%}
		return
		}

	;	Double-click in resultlist detected, grab file/foldername

	;	DopusDebug
		Sleep %$slowdown%

		$FoundPath := GetPathFromEverything($EverythingID)

	;	Strip double-quotes and spaces
		$FoundPath := Trim( $FoundPath, " """"" )
		
	;	Trim trailing backslash?
		$FoundPath := RTrim( $FoundPath, "\" )
	
		MsgBox $FoundPath = [%$FoundPath%]

		DebugMsg( A_ThisLabel . A_ThisFunc, "Found :`r`n[" . $FoundPath . "]" )

	;	DopusDebug
		Sleep %$slowdown%

		If ( $FoundPath )
		{
			DebugMsg( A_ThisLabel .  A_ThisFunc, "You selected path:`r`n" . "[" . $FoundPath . "]" )
		}

	;	DopusDebug
		Sleep %$slowdown%

		If ValidPath($FoundPath)
		{
		;	We got our path; close Everything
			WinClose, ahk_id %$EverythingID%

		;	DopusDebug
			Sleep %$slowdown%
		}
		else
		{
		;	DopusDebug
			Sleep %$slowdown%

			DebugMsg( A_ThisLabel . A_ThisFunc, "NOT a valid Path:`r`n[" . $FoundPath . "]" )
			MsgBox,,,Path could not be found. Maybe off-line?`r`n[%$FoundPath%], 3
			$FoundPath := ""
		}
	}

	else if (GetKeyState("LButton","P")) 		; drag event outside resultlist
	{
		sleep,20
		Send, {LButton Down} 
		while  (GetKeyState("LButton","P"))
		sleep,20
		Send, {LButton Up}
	}
	else		 ;simple click outside resultlist. Let it pass.
	{
	;	send,{LButton}
		Send {%A_ThisHotkey%}
	}
}
Return




;_____________________________________________________________________________
;
						HandleEnterHotkey: 
;_____________________________________________________________________________
;
{

;	Detect if in Result list:
	ControlGetFocus, _focus, ahk_id %$EverythingID%

	If (_focus = "SysListView321") 
	{

	;	ENTER in resultlist detected, grab file/foldername

		$FoundPath := GetPathFromEverything($EverythingID)
	;	DopusDebug
		Sleep %$slowdown%

		DebugMsg( A_ThisLabel . A_ThisFunc, "Found :`r`n[" . $FoundPath . "]" )


		If ( $FoundPath )
		{
			DebugMsg( A_ThisLabel .  A_ThisFunc, "You selected path:`r`n" . "[" . $FoundPath . "]" )
		}

		If (ValidPath($FoundPath))
		{
		;	We got our path; close Everything
			WinClose, ahk_id %$EverythingID%
		}
		Else
		{
			DebugMsg( A_ThisLabel . A_ThisFunc, "NOT a valid Path:`r`n[" . $FoundPath . "]" )
			MsgBox,,,Path could not be found. Maybe off-line?`r`n[%$FoundPath%], 3

		}
	}
	else	; ENTER outside result list; let it through
	{
		Send {%A_ThisHotkey%}
	}
}

Return




;_____________________________________________________________________________
;
						IsFocusedControl(_thiscontrol) 
;_____________________________________________________________________________
;
{
;	MouseGetPos, , , , _focus
	ControlGetFocus, _focus, A
	Return  _focus = _thiscontrol ? true : false
}


;_____________________________________________________________________________
;
						ExpandEnvVars(_thisstring) 
;_____________________________________________________________________________
;
{
;	https://www.autohotkey.com/board/topic/9516-function-expand-paths-with-environement-variables/
	VarSetCapacity( _expanded, 2000) 
	DllCall("ExpandEnvironmentStrings", "str", _thisstring, "str", _expanded, int, 1999) 
	return _expanded
}




;_____________________________________________________________________________
;
						DebugMsg(_routine, _message)
;_____________________________________________________________________________
;    
{
	Global $Debug
	
	If ($Debug)
	{
		MsgBox, ,%_routine%, %_message% 
	}
Return
}





;=============================================================================
;=============================================================================
;
;						FEEDER ROUTINES PER WINDOW TYPE
;
;=============================================================================
;=============================================================================

;; Start FEEDER ROUTINES PER WINDOW TYPE

;_____________________________________________________________________________
;
						FeedTotalCMD( _thisID, _thisFOLDER, _thisFILE )
;_____________________________________________________________________________
;    
{

	Global $Running_exe

    Run, "%$Running_exe%"  /O /A /S /L="%_thisFOLDER%%_thisFILE%",,, $DUMMY
return
}


;_____________________________________________________________________________
;
						FeedSalamander( _thisID, _thisFOLDER, _thisFILE )
;_____________________________________________________________________________
;    
{

	Global $Running_exe

	If !_thisFILE
		_thisFOLDER := RTrim( _thisFOLDER , "\")
	else
		_thisFOLDER=%_thisFOLDER%%_thisFILE%

	Run, "%$Running_exe%"  -O -A "%_thisFOLDER%",,, $DUMMY

return
}



;_____________________________________________________________________________
;
						FeedFreeCommander( _thisID, _thisFOLDER, _thisFILE )
;_____________________________________________________________________________
;    
{
;	Details on https://freecommander.com/fchelpxe/en/Commandlineparameters.html

	Global $Running_exe

	Run, "%$Running_exe%"  /C /Z /L="%_thisFOLDER%%_thisFILE%",,, $DUMMY

return
}



;_____________________________________________________________________________
;
						FeedXYPlorer( _thisID, _thisFOLDER, _thisFILE )
;_____________________________________________________________________________
;    
{

	Global $Running_exe

;	If ( _thisFILE = "" )
;	{
;		_thisFOLDER := RTrim( _thisFOLDER , "\")
;	}

		
		Run, "%$Running_exe%"  "%_thisFOLDER%%_thisFILE%",,, $DUMMY
;		Run, "%$Running_exe%"  "%_thisFOLDER%",,, $DUMMY

return
}



;_____________________________________________________________________________
;
						FeedDoubleCommander( _thisID, _thisFOLDER, _thisFILE )
;_____________________________________________________________________________
;    
{
;	Details on https://doublecmd.github.io/doc/en/commandline.html

	Global $Running_exe

	Run, "%$Running_exe%"  -C "%_thisFOLDER%%_thisFILE%",,, $DUMMY

return
}


;_____________________________________________________________________________
;
						FeedDirectoryOpus( _thisID, _thisFOLDER, _thisFILE )
;_____________________________________________________________________________
;    
{
;	Details on https://....

	Global $Running_exe

	Run, "%$Running_exe%\..\dopusrt.exe" /CMD GO "%_thisFOLDER%",,, $DUMMY

return
}


;_____________________________________________________________________________
;
						FeedExplorerFileMan( _thisID, _thisFOLDER, _thisFILE )
;_____________________________________________________________________________
;    
{
;	REmote Control through COM object
;	(Based on the research done here: https://autohotkey.com/boards/viewtopic.php?f=5&t=526)
;	Go through all opened Explorer windows
;	For the one that has the same ID as our Explorer window:
;	Navigate to $FolderPath
;	Doesn't like folderpaths with a # in it if it ends with a "\"
;	so trim that one from the end.

	_thisFOLDER := RTrim( _thisFOLDER , "\")


	For $Exp in ComObjCreate("Shell.Application").Windows
	{
		if ( $Exp.hwnd = _thisID )
		{
			$Exp.Navigate(_thisFOLDER)
			break
		}
	}

return
}



;_____________________________________________________________________________
;
						FeedExplorerWithDopusHook( _thisID, _thisFOLDER, _thisFILE )
;_____________________________________________________________________________
;    
{
MsgBox Start FeedExplorerWithDopusHook
;	Global $DialogType

;	WinActivate, ahk_id %_thisID%

	sleep 50

	WinGet, ActivecontrolList, ControlList, ahk_id %_thisID%


	Loop, Parse, ActivecontrolList, `n	; which addressbar and "Enter" controls to use 
	{
		If InStr(A_LoopField, "ToolbarWindow32")
		{
			ControlGet, _ctrlHandle, Hwnd,, %A_LoopField%, ahk_id %_thisID%

		;	Get handle of parent control
			_parentHandle := DllCall("GetParent", "Ptr", _ctrlHandle)

		;	Get class of parent control
			WinGetClass, _parentClass, ahk_id %_parentHandle%

			If InStr( _parentClass, "Breadcrumb Parent" )
			{
				_UseToolbar := A_LoopField
			}

			If Instr( _parentClass, "msctls_progress32" )
			{
				_EnterToolbar := A_LoopField
			}	
		}

	;	Start next round clean
		_ctrlHandle			:= ""
		_parentHandle		:= ""
		_parentClass		:= ""
	
	}

	If ( _UseToolbar AND _EnterToolbar )
	{
		Loop, 5
		{
			SendInput ^l
			sleep 100

		;	Check and insert folder
			ControlGetFocus, _ctrlFocus, ahk_id %_thisID%

			If InStr( _ctrlFocus, "Edit" )
			{
				Control, EditPaste, %_thisFOLDER%, %_ctrlFocus%, ahk_id %_thisID%
				ControlGetText, _editAddress, %_ctrlFocus%, ahk_id %_thisID%
				If (_editAddress = _thisFOLDER )
				{
					_FolderSet := TRUE
				}
			}
		;	else: 	Try it in the next round

		;	Start next round clean
			_ctrlFocus := ""
			_editAddress := ""

		}	Until _FolderSet


		
		If (_FolderSet)
		{
		;	Click control to "execute" new folder	
			ControlClick, %_EnterToolbar%, ahk_id %_thisID%
		}
		Else
		{
		;	What to do if folder is not set?
		}
	}
	Else ; unsupported dialog. At least one of the needed controls is missing
	{
		MsgBox This type of dialog can not be handled (yet).`nPlease report it!
	}



return
}



;_____________________________________________________________________________
;
				FeedOpenSave( _thisID, _thisFOLDER, _thisFILE )
;_____________________________________________________________________________
;    
{
	Global $DialogType

	WinActivate, ahk_id %_thisID%

	sleep 50

;	Focus Edit1
	ControlFocus Edit1, ahk_id %_thisID%

	WinGet, ActivecontrolList, ControlList, ahk_id %_thisID%


	Loop, Parse, ActivecontrolList, `n	; which addressbar and "Enter" controls to use 
	{
		If InStr(A_LoopField, "ToolbarWindow32")
		{
		;	ControlGetText _thisToolbarText , %A_LoopField%, ahk_id %_thisID%
			ControlGet, _ctrlHandle, Hwnd,, %A_LoopField%, ahk_id %_thisID%

		;	Get handle of parent control
			_parentHandle := DllCall("GetParent", "Ptr", _ctrlHandle)

		;	Get class of parent control
			WinGetClass, _parentClass, ahk_id %_parentHandle%

			If InStr( _parentClass, "Breadcrumb Parent" )
			{
				_UseToolbar := A_LoopField
			}

			If Instr( _parentClass, "msctls_progress32" )
			{
				_EnterToolbar := A_LoopField
			}	
		}

	;	Start next round clean
		_ctrlHandle			:= ""
		_parentHandle		:= ""
		_parentClass		:= ""
	
	}

	If ( _UseToolbar AND _EnterToolbar )
	{
		Loop, 5
		{
			SendInput ^l
			sleep 100

		;	Check and insert folder
			ControlGetFocus, _ctrlFocus,A

			If ( InStr( _ctrlFocus, "Edit" ) AND ( _ctrlFocus != "Edit1" ) )
			{
				Control, EditPaste, %_thisFOLDER%, %_ctrlFocus%, A
				ControlGetText, _editAddress, %_ctrlFocus%, ahk_id %_thisID%
				If (_editAddress = _thisFOLDER )
				{
					_FolderSet := TRUE
				}
			}
		;	else: 	Try it in the next round

		;	Start next round clean
			_ctrlFocus := ""
			_editAddress := ""

		}	Until _FolderSet


		
		If (_FolderSet)
		{
		;	Click control to "execute" new folder	
			ControlClick, %_EnterToolbar%, ahk_id %_thisID%

		;	Focus file name
			Sleep, 15
			ControlFocus Edit1, ahk_id %_thisID%
		}
		Else
		{
		;	What to do if folder is not set?
		}
	}
	Else ; unsupported dialog. At least one of the needed controls is missing
	{
		MsgBox This type of dialog can not be handled (yet).`nPlease report it!
	}

Return
}




;_____________________________________________________________________________
;
				FeedOpenSave_SYSLISTVIEW( _thisID, _thisFOLDER, _thisFILE )
;_____________________________________________________________________________
;    
{
	Global $DialogType


	DebugMsg( A_ThisLabel . A_ThisFunc, "ID = " . _thisID . " Folder =  " . _thisFOLDER )
	
	
	WinActivate, ahk_id %_thisID%
	Sleep, 20


;	Read the current text in the "File Name:" box (= $OldText)

	ControlGetText _oldText, Edit1, ahk_id %_thisID%
	Sleep, 20


;	Make sure there exactly 1 \ at the end.

	_thisFOLDER := RTrim( _thisFOLDER , "\")
	_thisFOLDER := _thisFOLDER . "\"

	Loop, 20
	{
		Sleep, 10
		ControlSetText, Edit1, %_thisFOLDER%, ahk_id %_thisID%
		ControlGetText, _Edit1, Edit1, ahk_id %_thisID%
		If ( _Edit1 = _thisFOLDER )
			_FolderSet := TRUE

	} Until _FolderSet

	If _FolderSet
	{
		Sleep, 20
		ControlFocus Edit1, ahk_id %_thisID%
		ControlSend Edit1, {Enter}, ahk_id %_thisID%



	;	Restore  original filename / make empty in case of previous folder

		Sleep, 15

		ControlFocus Edit1, ahk_id %_thisID%
		Sleep, 20

		Loop, 5
		{
			ControlSetText, Edit1, %_oldText%, ahk_id %_thisID%		; set
			Sleep, 15
			ControlGetText, _2thisCONTROLTEXT, Edit1, ahk_id %_thisID%		; check
			If ( _2thisCONTROLTEXT = _oldText )
				Break
		}
	}
Return
}




;_____________________________________________________________________________
;
						FeedXPlorer2( _thisID, _thisFOLDER, _thisFILE )
;_____________________________________________________________________________
;    
{
	WinActivate, ahk_id %_thisID%

	ControlFocus Edit1, A


;	Go to Folder
	Loop, 5
	{
		ControlSetText, Edit1, %_thisFOLDER%%_thisFILE%, A		; set
		Sleep, 50
		ControlGetText, $CurControlText, Edit1, A		; check
		if ($CurControlText = _thisFOLDER_thisFILE)
			break
	}

	ControlSend Edit1, {Enter}, A

return
}





;_____________________________________________________________________________
;
						FeedQDirFileMan( _thisID, _thisFOLDER, _thisFILE )
;_____________________________________________________________________________
;    
{

;	Q-Dir does not respond very well to simulated keypresses.
;	Only way to make it work is with: key down, followed by key up.


	WinActivate, ahk_id %_thisID%



;	Activate the address bar that belongs to the current pane (alt-s ; case-sensitive)
;	Q-Dir can have up to 4 address bars ..)

	Sleep, 50
	SendInput {Alt Down}
	sleep 15
	SendInput {s Down}
	sleep 15
	SendInput {s Up}
	Sleep 15
	SendInput {Alt Up}
	Sleep 15



;	Read the current ClassNN

	ControlGetFocus, $ActiveControl, A



;	Feed FolderPath to this ClassNN
;	2DO: (with some re-tries to be sure)

	ControlSetText,%$ActiveControl% , %_thisFOLDER%, A
	Sleep, 50


;	Send {Enter}

	SendInput {Enter Down}
	sleep 15
	SendInput {Enter Up}

return
}



MsgBox This should never be shown.
ExitApp




;_____________________________________________________________________________
;=============================================================================
;=============================================================================
;=============================================================================
;=============================================================================
;
				GUI:
;
;=============================================================================
;=============================================================================
;=============================================================================
;=============================================================================



;_____________________________________________________________________________
;
;------------ HANDLING SETTINGS ------------------------------
;_____________________________________________________________________________
;


	$onlyfolders := !$also_search_files
	$sort_descending := !$sort_ascending

;	There is a "love/hate triangle" between 3 controls:
;	Browse executable, executable text field and context menu icon.
;	define 2 separate variables to "mediate" between them.

	$current_exe := $everything_exe
	$current_icon := $contextmenu_icon



;	Make $sort_by the visible one in dropdownlist
;	Not included: ;	Extension|Date Created|Date Accessed|Attributes|File List Fileame|Type
	$SortList := "Name|Path|Size|Date Modified|Run Count|Date Recently Changed|Date Run"
	$SortList := StrReplace($SortList, $sort_by, $sort_by . "|")

;	$TabList only for hide/show tab routine.
	$TabList  := "JumpToFolder|Settings|Applications|About"


;	Keep track of changes in GUI. Used to check if Apply button should be shown.
	$changed_settings := ";"


;	Reminder
;	$ActionList := Save Settings|Save & Install Context menu||Uninstall|Restore Defaults	

;	How we are started decides wht to write in registry / TC button code / hotkey shortcut.
	If ( A_IsCompiled = 1 ) {

		$context_command := """" . A_ScriptFullPath . """" . " -jump"
		$TCcommand  := A_ScriptFullPath
		$TCparms    := "-jump"
	}
	else {

		$context_command := """" . A_AhkPath . """ """ . A_ScriptFullPath . """" . " -jump"
		$TCcommand  := A_AhkPath
		$TCparms    := """" . A_ScriptFullPath . """" . " -jump"
		
	}



;_____________________________________________________________________________
;
;------------ BUILD GUI -------------------------
;_____________________________________________________________________________
;

;	All Settings controls need a gLabel and a vVariable to
;	detect changes (disable Apply button or not)


;------------------------------------------------
;			TreeView
;------------------------------------------------
	Gui Add, TreeView, x6 y6 w122 h402 gGuiTreeView

	$TreeRoot    := TV_Add("JumpToFolder", ,"Expand")
	$TreeBranch1 := TV_Add("Settings", $TreeRoot)
	$TreeBranch2 := TV_Add("Applications", $TreeRoot)
;	$TreeBranch3 := TV_Add("About", $TreeRoot)


;------------------------------------------------
;			Tabs
;------------------------------------------------

;	Tabs are added individual; not as a group.
;	Reason: that way all separate tabs can be positioned on the
;	same spot to show only 1 tab at a time.
;	Not possible in a tabgroup.

	$TabSize := "x130 y9 w340 h402"

;------------------------------------------------
;				JumpToFolder Tab 
;------------------------------------------------

	Gui, Add, Tab, %$TabSize% vJumpToFolder, JumpToFolder
	$IntroText=
(
Current version: %$ThisVersion%

JumpToFolder is a little utility that brings the power of Everything to file dialogs and file managers.
No longer the need to browse through lots of folders, drives and network folders, but jump to that folder immediately.


How to use:
1. Right-click in an empty part of the file list and choose "Jump To Folder" from the context menu,
2. Type part of the filename in the appearing Everything window,
3. Choose a file or folder from the list,
4. JumpToFolder will change the current folder in the file manager / file dialog to the selected folder.
  


)

	Gui Font, s10
	Gui Add, Text, W320, %$IntroText%
	Gui, Add, Link,, For more information, see the <a href="https://www.voidtools.com/forum/viewtopic.php?f=2&t=11194">Everything forum</a>.
	Gui Font
	
;------------------------------------------------
;				Settings Tab
;------------------------------------------------
	
	Gui, Add, Tab, %$TabSize% vSettings, Settings

	;------------------------------------------------
	;					Search Settings
	;------------------------------------------------
		Gui, Font, Bold
		Gui Add, Text, 								x146 y40 w316 h15, Search settings
		Gui, Font
		Gui Add, Text, 								x146 y65 w316 h15, Location of Everything.exe
		Gui Add, Edit, v$gui_edit_exe gGuiEdit_exe			x146 y85 w265 h23, %$current_exe%
		Gui Add, Button, gGuiBrowse_exe				x415 y85 w50 h23 , &Browse
;2DO
		Gui Add, Text,								x146 y115 w61 h23 +0x200, Search In:
		Gui Add, Radio, v$gui_onlyfolders gGuiSearchItems	x215 y115 w83 h23 Checked%$onlyfolders%, Folders
		Gui Add, Radio, v$gui_also_search_files gGuiSearchItems		x310 y115 w120 h21 Checked%$also_search_files%, Folders and Files

		Gui Add, Text,								x146 y160 w61 h23 +0x200, Sort By:
		Gui Add, DropDownList, v$gui_sort_by gGuiSort_by		x215 y160 w195, %$SortList%
		Gui Add, Text,								x146 y195 w61 h23 +0x200, Sort Order:
		Gui Add, Radio, v$gui_sort_ascending gGuiSortOrder		x215 y195 w80 h23 Checked%$sort_ascending%, Ascending
		Gui Add, Radio, vDescending	gGuiSortOrder		x330 y195 w83 h23 Checked%$sort_descending%, Descending


	;------------------------------------------------
	;					Context Menu Entry Settings
	;------------------------------------------------

		Gui, Font, Bold
		Gui Add, Text, 							  	x146 y250 w316 h15, Context-menu entry (icon is clickable)
		Gui, Font
;		Gui Add, Text,                            	x146 y160 w61 h23 +0x200, Sort By:

;;		(Clickable) Image:
;		Placeholder vf_picIcon
;		Gui, Add, Picture, v$gui_contextmenu_icon gGuiChangeIcon x146 y270 w32 h32
		Gui, Add, Picture, v$gui_contextmenu_icon gGuiChangeIcon x146 y270 w32 h32


;		Fill (v$gui_contextmenu_icon)
		Gosub GuiShowIcon

;		Text for Context menu entry:
		Gui Add, Edit, v$gui_contextmenu_text gGuiContextText	x215 y270 w195 h32, %$contextmenu_text%

	;------------------------------------------------
	;					Action Settings
	;------------------------------------------------

		Gui, Font, Bold
		Gui Add, Text, 							  	x146 y337 w56 h24 +0x200, Action:
		Gui, Font
		Gui Add, DropDownList, vAction            	x215 y343 w195, Save Settings|Save & Install Context menu||Uninstall|Restore Defaults


	
;------------------------------------------------
;				Applications Tab 
;------------------------------------------------

Gui, Add, Tab, %$TabSize% vApplications, Applications

	$AppsText1=
(
In all applications:
- File Dialogs like Open and Save As dialogs

File managers:
- Windows File Explorer
- Altap Salamander
- Directory Opus
- Double Commander
- FreeCommander
- Q-Dir
- Total Commander
- XPlorer2
- XyPlorer

)

	$AppsText2=
(
Total Commander is supported through a button on it's button bar.
Press the "Generate" button to put the Button Code on the clipboard. 
Right-click the button bar to paste it.
)

	Gui Font, bold
	Gui Add, Text, ,Out of the box support for:
	Gui Font
    Gui Add, Text, W320, %$AppsText1%

	Gui Font, bold
    Gui Add, Text, , Total Commander
	Gui Font
    Gui Add, Text, W320, %$AppsText2%

	Gui Add, Button, gGUITotalCommander			  x290 y343 w165 , &Generate Button Bar code
;	Gui Font

	
	
;------------------------------------------------
;				About Tab 
;------------------------------------------------
	
	Gui, Add, Tab, %$TabSize% vAbout, About
    Gui Add, Text, x147 y126 w66 h23 +0x200, About page 
    Gui Add, Text, , (or just drop it ?)
	

	Gui Tab


;------------------------------------------------
;			Global buttons
;------------------------------------------------

	Gui Add, Button, gGuiButtonOK 						x237 y414 w75 h23, OK
	Gui Add, Button, gGuiButtonCancel 					x318 y414 w75 h23, Cancel
	Gui Add, Button, gGuiButtonApply +Disabled			x399 y414 w75 h23, Apply



;------------------------------------------------
	Gui Show, w480 h443, JumpToFolder settings (version %$ThisVersion%)
;------------------------------------------------

return


;_____________________________________________________________________________
;
;------------ HANDLE GUI CHANGES ------------------------------
;_____________________________________________________________________________
;



;_____________________________________________________________________________
;
					GuiTreeView:
;_____________________________________________________________________________
;
	Gui, submit, NoHide
	if (A_GuiEvent != "S")  ; i.e. an event other than "select new tree item".
		return  ; Do nothing.

;	Otherwise, populate the ListView with the contents of the selected folder.
;	First determine the full path of the selected folder:

	TV_GetText($TreeItem, A_EventInfo)


;	And show that one. Hide the other ones.

	Loop, Parse, $TabList, |
		{
			If ($TreeItem = A_LoopField) {
				GuiControl, Show, %A_LoopField%
			}
			else {
				GuiControl, Hide, %A_LoopField%
			}
		}
return

;------------------------------------------------
;				Tab Settings
;------------------------------------------------

;_____________________________________________________________________________
;
					GuiBrowse_exe:
;_____________________________________________________________________________
;


;	Browse for Everything.exe and possibly change the icon of the context menu.

    FileSelectFile, $SelectedFile, ,Everything.exe, Select Everything program, Everything executable (*.exe)
    If !$SelectedFile
		return

	$current_exe := $SelectedFile

;	Edit field
	GuiControl,,$gui_edit_exe, %$current_exe%
	
;	Icon field
	If ($OOB_contextmenu_icon = $current_icon) {
;		Still the OOB icon! Change it to the one of the chosen executable
;		And leave it alone from now on.
		$current_icon := $current_exe . ",0"
		gosub GuiShowIcon
	}

;	Apply button routine
	ApplyButton2($contextMenu_icon, $current_icon, "ChangeIcon", $changed_settings)

return



;_____________________________________________________________________________
;
					GuiChangeIcon:
;_____________________________________________________________________________
;
;	Based on: https://www.autohotkey.com/boards/viewtopic.php?f=76&t=72960&hilit=PickIconDlg


	hWnd := 0

;	Browse Icon	

	VarSetCapacity(strIconFile, 260 << !!A_IsUnicode)
	if !DllCall("shell32\PickIconDlg", "Ptr", hWnd, "Str", strIconFile, "UInt", 260, "IntP", intIconIndex)
		return ; No icon selected; don't change anything.
		
	$current_icon := strIconFile . "," . intIconIndex

	
;	Show Icon
	Gosub GuiShowIcon
	
;	Apply button routine
	ApplyButton2($contextMenu_icon, $current_icon, "ChangeIcon", $changed_settings)

return



;_____________________________________________________________________________
;
					GuiEdit_exe:
;_____________________________________________________________________________
;

;	Read current value
	GuiControlGet, $gui_edit_exe
	$current_exe := $gui_edit_exe


;	Apply button routine
	ApplyButton2($everything_exe, $current_exe, "EditExe", $changed_settings)


return


;_____________________________________________________________________________
;
					GuiSearchItems:
;_____________________________________________________________________________
;
;	Read current value
	GuiControlGet, $gui_also_search_files

;	Apply button routine
	ApplyButton2($also_search_files, $gui_also_search_files, "SearchFiles", $changed_settings)

return


;_____________________________________________________________________________
;
					GuiSort_by:
;_____________________________________________________________________________


;	Read current value
	GuiControlGet, $gui_sort_by


;	Apply button routine

	ApplyButton2($sort_by, $gui_sort_by, "SortBy", $changed_settings)

return


;_____________________________________________________________________________
;
					GuiSortOrder:
;_____________________________________________________________________________

;	Read current value
	GuiControlGet, $gui_sort_ascending

;	Apply button routine
	ApplyButton2($sort_ascending, $gui_sort_ascending, "SortOrder", $changed_settings)

return


;_____________________________________________________________________________
;
					GuiContextText:
;_____________________________________________________________________________
;

;	Read current value
	GuiControlGet, $gui_contextmenu_text

;	Apply button routine
	ApplyButton2($contextmenu_text, $gui_contextmenu_text, "MenuText", $changed_settings)

return


;------------------------------------------------
;				Tab Applications
;------------------------------------------------


;_____________________________________________________________________________
;
					GuiTotalCommander:
;_____________________________________________________________________________
;

;	Catch OOB and unsaved changed settings

	if !FileExist($current_exe) { 
		MsgBox	Please check settings
	return
	}

;	Are settings saved?
	If ($changed_settings != ";") {
		MsgBox Save settings first.
	return
	}
	


; Button code looks like this:

	;HEADER			:  TOTALCMD#BAR#DATA
	;COMMAND		:  C:\develop\JumpToFolder\JumpToFolder.exe
	;PARAMETERS		:  -jump
	;ICON			:  C:\develop\JumpToFolder\JumpToFolder.exe,4
	;TOOLTIP		:  JumpToFolder
	;WORKING DIR	:  C:\develop\JumpToFolder\
	;???			:
	;ALWAYS?		:  -1


;	When $ButtonCode was defined through (multiline), Enters fell off on clipboard. Plan B:

	$ButtonCode=TOTALCMD#BAR#DATA`r`n%$TCcommand%`r`n%$TCparms%`r`n%$contextMenu_icon%`r`n%$contextMenu_text%`r`n`r`n`r`n-1


	ClipBoard := $ButtonCode

	MsgBox,
	(

    The following code is now on the clipboard.
    Right-click one of Total Commander's 
    Button Bars and paste it.

    To start JumpToFolder, press that button.


	==================================

%$ButtonCode%

	==================================
	)

return


;------------------------------------------------
;				Global Buttons
;------------------------------------------------



;_____________________________________________________________________________
;
					GuiButtonCancel:
;_____________________________________________________________________________
;

	ExitApp
Return	; formality

;_____________________________________________________________________________
;
					GuiButtonApply:
					GuiButtonOK:
;_____________________________________________________________________________
;
	DebugMsg("Apply/OK", "Start Apply/OK" )
	GuiControlGet, $Action, , Action


;	Don't use the Switch command as it is too new.
;	Might give problems when .ahk is associated
;	with an older version of ahk.exe

	If ( $Action = "Save Settings" ) {						; Save
		gosub CheckSettings
		If ( !SettingsOK )
			return
		gosub WriteINI
	}

	Else If ( $Action = "Uninstall" ) {						; Uninstall
		gosub REmoveContextMenu
	}

	Else If ( $Action = "Restore Defaults" ) {				; Restore
		MsgBox Not yet implemented
	}

	Else If ( $Action = "Save & Install Context menu" ) {	; Install	
		gosub CheckSettings
		If ( !SettingsOK )
			return
		gosub WriteINI
		gosub InstallContextMenu
	}

	Else {													; Rest	
		MsgBox Something went wrong in the OK/Apply routine.
	}


	If ( A_ThisLabel = "GuiButtonOK" ) {
	
	ExitApp
	}
		
return



;_____________________________________________________________________________
;
					GuiEscape:
					GuiClose:
;_____________________________________________________________________________
;

  ExitApp

	

;_____________________________________________________________________________
;
;------------ SUBROUTINES ------------------------------
;_____________________________________________________________________________
;



;_____________________________________________________________________________
;
					GuiShowIcon:
;_____________________________________________________________________________
;
;MsgBox	GUUI showicon $current_icon = [%$current_icon%]

;	Needed:
;	- $ContextMenu_Icon (c:\path to\file.exe,index)
;	- replaced with: $current_icon
;	- controlname (where the icon should be put)

;	GuiControl uses a different numbering (Offset + 1 for index >0) so convert it.
;	also uses separate iconfile and iconindex.

;	Split $current_icon in filename and index
;	If no index: Index = 0


	If !InStr($current_icon, ",")
		$current_icon := $current_icon . ",0" ; use its first icon

;	Check context-menu icon.

	$IconTest := SubStr($current_icon, 1, InStr($current_icon, ",", false, -1, 1) -1)
;MsgBox $IconTest =%$IconTest%
	If !FileExist($IconTest)
	{
		$current_icon := $OOB_contextmenu_icon
;		MsgBox $IconTest - $current_icon does not exist
	}

	
;	Search from the end because filename could also include a comma (ex.: "file,name.ico,1")	

	intCommaPos := InStr($current_icon, ",", , 0) - 1 
	strIconFile := SubStr($current_icon, 1, intCommaPos)
	intIconIndex := StrReplace($current_icon, strIconFile . ",")





	if (intIconIndex > 0)
		intIconIndex := intIconIndex + 1
		

;	Finally show the icon

		GuiControl, , $gui_contextmenu_icon, *icon%intIconIndex% %strIconFile%

		
return



;_____________________________________________________________________________
;
					ApplyButton2(_item1,_item2,_listentry, byRef $changed_settings)
;_____________________________________________________________________________
;
;	If _item1 = _item2, remove _listentry from the list $changed_settings
;	If _item1 not _item2, add _listentry to the list $changed_settings
;	(remove entry first and then add it. To prevent double entries and $var from growing)
;
;	Wnen done: if $changed_settings is empty (= ";"), 
;	disable the Apply button as there are no more changes on the list.
;	(meaning that all settings are the same as when started)

;	Also: add /remove "* " from titlebar to indicate changes (like Notepad)

{
;	MsgBox, IN: %_item1% , %_item2% , %_listentry% , %$changed_settings%

	If ( _item1 != _item2 ) {
		; remove current and add current
		$changed_settings := StrReplace( $changed_settings, ";" . _listentry . ";", ";")
		$changed_settings := $changed_settings . _listentry . ";"

	;	show Apply button
		GuiControl, Enable, Apply
		
	}
	else {
		; remove current
		$changed_settings := StrReplace( $changed_settings, ";" . _listentry . ";", ";")

		If ( $changed_settings = ";" ) {
			GuiControl, Disable, Apply
		}

	}
;	MsgBox OUT: _%$changed_settings%_  
}




;_____________________________________________________________________________
;
					CheckSettings:
;_____________________________________________________________________________
;
	DebugMsg("CheckSettings", "Start CheckSettings")
	SettingsOK := True


	if !FileExist($current_exe) 
	{ 
		MsgBox	Location of Everything.exe is not correct:`r`n`r`n"%$current_exe%"
		SettingsOK := False
	}
	else
	{
		$EverythingVersion :=GetEverythingMajorVersion($current_exe)
		
		If !($EverythingVersion = "1.4" OR $EverythingVersion = "1.5")
		{
			MsgBox Everything 1.4 and 1.5 supported`r`nMake sure the location points to a valid Everything.exe.
			SettingsOK := False
			
		}
	}


	if ( $gui_contextmenu_text = "") 
	{ 
		MsgBox	Text for Context Menu is missing ..
		SettingsOK := False
	}


	If (SettingsOK)
	{
	


;		Fill all INI $vars with $gui... and $current.. values

		$everything_exe		:= $current_exe   
		$also_search_files	:= $gui_also_search_files
		$sort_by			:= $gui_sort_by
		$sort_ascending		:= $gui_sort_ascending
		$contextmenu_text	:= $gui_contextmenu_text
		$contextmenu_icon	:= $current_icon

		
	;	Empty $changed_settings ( = ";"), 
	;	Disable Apply button
	;	Anything else?

		$changed_settings	:=	";"
		GuiControl, Disable, Apply
	
	}


return 



;_____________________________________________________________________________
;
					GetEverythingMajorVersion(_everything_exe)
;_____________________________________________________________________________
;    
{

	FileGetVersion, _longversion, %_everything_exe%
	_version := StrSplit(_longversion, ".")
	_majorversion := _version[1] . "." . _version[2]

	DebugMsg( A_ThisLabel . A_ThisFunc, "long version = " . _longversion . "`r`nmajorversion = [" . _majorversion . "]")


Return _majorversion
}



;_____________________________________________________________________________
;
					InstallContextMenu:
;_____________________________________________________________________________
;

;	This also creates a shortcut to be put on desktop or in startmenu.
;	Pressing CTRL + ALT + J will activate JumpToFolder (alternative for using the context-menu)
;	Create it in app folder (it's optional).

;	writing to reg requires escaping , and % : `, `% 
;	RegWrite, ValueType, KeyName [, ValueName, Value]


;	split context_icon to put"" round filename (see GuiShowIcon:)

	intCommaPos := InStr($current_icon, ",", , 0) - 1 
	strIconFile := SubStr($current_icon, 1, intCommaPos)
	intIconIndex := StrReplace($current_icon, strIconFile . ",")



;	DIRECTORY contextmenu

;	Add contextmenu text
	RegWrite, REG_SZ, HKCU\Software\Classes\Directory\Background\Shell\JumpToFolder, MuiVerb, %$gui_contextmenu_text%

;	Add contextmenu icon
	RegWrite, REG_SZ, HKCU\Software\Classes\Directory\Background\Shell\JumpToFolder, Icon, "%strIconFile%"`,%intIconIndex%

;	Add command
	RegWrite, REG_SZ, HKCU\Software\Classes\Directory\Background\Shell\JumpToFolder\Command, , %$context_command%



;	FOLDERS contextmenu

;	Add contextmenu text
	RegWrite, REG_SZ, HKCU\Software\Classes\Folder\Background\Shell\JumpToFolder, MuiVerb, %$gui_contextmenu_text%

;	Add contextmenu icon
	RegWrite, REG_SZ, HKCU\Software\Classes\Folder\Background\Shell\JumpToFolder, Icon, "%strIconFile%"`,%intIconIndex%

;	Add command
	RegWrite, REG_SZ, HKCU\Software\Classes\Folder\Background\Shell\JumpToFolder\Command, , %$context_command%


;	SHORTCUT
;	2DO: FileCreateShortcut has icon offset. Compensate for that (again! Like GuiShowIcon)

	if (intIconIndex > 0)
		intIconIndex := intIconIndex + 1

;	FileCreateShortcut, Target, LinkFile [, WorkingDir, Args, Description, IconFile, ShortcutKey, IconNumber, RunState]
	FileCreateShortcut, "%$TCcommand%", JumpToFolder.lnk, , %$TCparms%, %$contextmenu_text%, %strIconFile%, J, intIconIndex, 1	
return



;_____________________________________________________________________________
;
					REmoveContextMenu:
;_____________________________________________________________________________
;


;	Synatx: RegDelete, KeyName [, ValueName]


;	Remove contextmenu for DIRECTORY

	RegDelete, HKCU\Software\Classes\Directory\Background\Shell\JumpToFolder


;	REmove contextmenu for (special) FOLDERS

	RegDelete, HKCU\Software\Classes\Folder\Background\Shell\JumpToFolder


return



;_____________________________________________________________________________
;
					WriteINI:
;_____________________________________________________________________________
;



;	Write to INI
	IniWrite, %$everything_exe%,   		%$IniFile%, JumpToFolder, everything_exe
	IniWrite, %$sort_by%,					%$IniFile%, JumpToFolder, sort_by
	IniWrite, %$sort_ascending%,			%$IniFile%, JumpToFolder, sort_ascending
	IniWrite, %$contextmenu_text%,		%$IniFile%, JumpToFolder, contextmenu_text
	IniWrite, %$contextmenu_icon%,		%$IniFile%, JumpToFolder, contextmenu_icon
	IniWrite, %$EverythingVersion%,		%$IniFile%, JumpToFolder, detected_everything_version
	IniWrite, "%$everything_instance%",	%$IniFile%, JumpToFolder, everything_instance
	IniWrite, %$debug%,	%$IniFile%, JumpToFolder, debug
;		IniRead, $debug,		%$IniFile%, JumpToFolder, debug,	%$OOB_debug%


return



;=============================================================================
;=============================================================================



/*

;_____________________________________________________________________________
;

2DO

- A better name. JumpToFolder sounds ..
	- Drive Warp? Everywhere? ;-) Everyway? WhereTo? Go Everywhere? WhereToGo?
	- WTF! (Warp To Folder! ;-)
	- Where do you want to go today? (Win95 slogan)
	- ..leap .. drive
	- drive dive, 
V SingleInstance Force closes an already running JumpToFolder.exe,
  but doesn't close it's Everything.exe child process.
  Leaving an unmanaged/ orphaned  Everything behind. Not a very common scenario, but still: Fix this.
  Solution: Close Everything when it loses focus.
- Add JumpToFolder to "This PC" background context menu
- Other places too?

- What should JumpToFolder do when right-click on desktop?
  - Start regular Everything?
  - Start Explorer in selected path? Or preferred filemgr?
  - do nothing? (disable)
  - Use it as a launcher?

- GUI: relative positioning of controls.

- Debug start: ahk path, version, size; startparms, user, elevated
- Write debug info to file too 
  (requires ShutDown()/similar routine instead of ExitApp to close open file handle.
? how to handle 1.5a instances with runcount?


- pre-populate the search with current path from file manager / -dialog if available); select/highlight it so it can be easily removed. 

- Adv advanced Tab for extra settings? Or keep those ini-only?

---------------------------------------


v 1.0.5
- Yet another mouse-click handling routine
  Now support for dragging and resizing Everything +window.
 (still no solid airtight solution for the resultlist scrollbar)
- reorganized code
- added "hidden" ini entry to overrule _exe and _instance
  for very special cases.
- Updated Settings page intro.
- Working directory for Everything is set to the folder of it's executable.


v 1.0.3
- Added support for %variables% in relevant INI entries.


v 1.0.2
- fixed a typo (removed extra space from path) that caused some filemanagers to be unable to open the selected folder.

v 1.0.1
- Different mouse-click handling.



*/

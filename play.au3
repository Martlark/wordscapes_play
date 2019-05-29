#Include <Clipboard.au3>
#Include <Array.au3>
#include <date.au3>
#include <ScreenCapture.au3>
#include <Constants.au3>
#include <WinAPI.au3>
#include <File.au3>
#include <Math.au3>
#include <MsgBoxConstants.au3>

AutoItSetOption("MustDeclareVars", 1)

dim $properties[1][3], $propertiesCount = 0
dim $locations[1][6], $locationsCount = 0
dim $hwnd
dim $title = "Phone screen"
dim $loopCount = 0
dim $paused = False
Opt( "MouseCoordMode", 0 )
Opt( "PixelCoordMode", 0 )
;Opt( "MouseClickDelay", 50 )
Opt( "MouseClickDragDelay", 500 )
Opt( "MouseClickDownDelay", 50 )

dim $reinforementsDelay = 11
dim $buildingCount = 15
dim $fireDelay = 61
dim $buildingDelay = 25
dim $sleepCount = 0
dim $lane = 0
dim $loops = 1
dim $captureCounter = 0
Dim $aWindowPos

dim $windowX = 651
dim $windowY = 437

AddLocation( "endlessvalley", 289, 216 )
AddLocation( "to battle",517, 341 )

AddLocation( "try again", 336, 307 )
AddLocation( "restart", 232, 268 )
AddLocation( "pause", 609, 60 )

AddLocation( "start wave 1", 185, 71 )
AddLocation( "start wave 2", 450, 69 )
AddLocation( "start wave 3", 580, 220 )

AddLocation( "reinforcements", 112, 373 )
AddLocation( "fire", 44, 380 )
AddLocation( "hero", 46, 113 )

AddLocation( "fire 1", 242, 259 )
AddLocation( "fire 2", 434, 230 )

AddLocation( "lane 1", 276, 291 )
AddLocation( "lane 2", 375, 254 )

AddLocation( "build 1",  330, 266, "bomb" )
AddLocation( "build 2",  362, 218, "mage" )
AddLocation( "build 3",  451, 274, "bomb" )
AddLocation( "build 4",  216, 217, "mage" )
AddLocation( "build 5",  523, 261, "bomb" )
AddLocation( "build 6",  245, 145, "mage" )
AddLocation( "build 7",  141, 152, "bomb" )
AddLocation( "build 8",  448, 178, "militia" )
AddLocation( "build 9",  383, 148, "bomb" )
AddLocation( "build 10",  88, 231, "militia" )
AddLocation( "build 11", 194, 178, "archer" )

dim $buildingLength = 11

func LocationMoved( $namesCommaSeparated, $delay = 500 )
	; return name index if any movement
	; 0 if none
	local $names = StringSplit($namesCommaSeparated, ",")
	local $pixels[$names[0]][1][1]

	for $nameIndex = 1 to $names[0]
		local $name = $names[$nameIndex]
		local $index = _ArraySearch( $locations, $name )

		if $index > -1 then
			local $x = $locations[$index][1]
			local $y = $locations[$index][2]
			local $width = $locations[$index][3]
			local $height = $locations[$index][4]
			local $xStep = $width / 10
			local $yStep = $height / 10

			redim $pixels[$nameIndex][$xStep][$yStep]

			for $xLoop = 1 to $xStep
				for $yLoop = 1 to $yStep
					$pixels[$nameIndex][$xLoop][$yLoop] = PixelGetColor( $x + ($xLoop*$xStep), $x + ($yLoop*$yStep) )
				Next
			Next

			sleep( $delay )

			for $xLoop = 1 to $xStep
				for $yLoop = 1 to $yStep
					if $pixels[$nameIndex][$xLoop][$yLoop] <> PixelGetColor( $x + ($xLoop*$xStep), $x + ($yLoop*$yStep) ) then
						return $nameIndex
					EndIf
				Next
			Next
		Else
			logMessage( "LocationMoved location " & $name & " not found"  )
			return 0
		endif
	Next
	return 0
endfunc

func hasColorInArea( $startX, $startY, $width, $height, $color1, $color2 = 0, $color3 = 0, $shadeRange = 10 )
	; return true if one of colors found in $colors
	; is in the search box
	local $array[4]

	$array[0] = 3

	$array[1] = $color1
	$array[2] = $color2
	$array[3] = $color3

	for $index = 0 to $array[0]
		if $array[$index] > 0 then
			PixelSearch( $startX, $startY, $startX+$width, $startY+$height, $array[$index], $shadeRange )
			If Not @error Then
				return true
			endif
		endif
	next
	return false
endfunc


func logMessage( $message )
	; log message to file log.txt
	;
	local $fileName = @MyDocumentsDir & "\kingdom_rush_play.log"
	local $file, $retryCount, $retryValue = 100

	for $retryCount = 0 to $retryValue
		$file = FileOpen( $fileName, 1)
		; Check if file opened for writing OK
		If $file = -1 Then
			sleep( 10 )
		else
			exitloop
		endif
	next
	If $file = -1 Then
		MsgBox(0, "Error", "Unable to open log file." & $fileName)
		Exit
	EndIf

	FileWrite($file, @HOUR & ":" & @MIN & " " ) ; time stamp
	FileWrite($file, $message & @CRLF)
	ConsoleWrite( $message & @CRLF )
	FileClose($file)
endFunc

Func SleepWinActive( $activeTitle, $milliseconds )
	;logMessage( "sleeping " & $milliseconds )
	sleep($milliseconds)
	if not WinActive($activeTitle) Then
		logMessage( $activeTitle & " no longer active" )
		Return false
	EndIf
	Return True
EndFunc

func AddLocation( $name, $x, $y, $width = 0, $height = 0, $color1 = 0 )
	redim $locations[$locationsCount+1][6]
	$locations[$locationsCount][0] = $name
	$locations[$locationsCount][1] = $x
	$locations[$locationsCount][2] = $y
	$locations[$locationsCount][3] = $width
	$locations[$locationsCount][4] = $height
	$locations[$locationsCount][5] = $color1
	$locationsCount += 1
EndFunc

func ResetMouse()
	MouseClick( "left", 333, 383 )
EndFunc

Func LocationClick( $name )
	if $paused Then
		Return
	EndIf
	if not WinActive( $title ) Then
		logMessage( $title & " not active"  )
		Exit
	EndIf
	local $index = _ArraySearch( $locations, $name )

	if $index > -1 then
		sleep( 200 )
		MouseClick( "left", $locations[$index][1], $locations[$index][2] )
		sleep( 500 )
	Else
		logMessage( "location " & $name & " not found"  )
	endif
	return $index
EndFunc

func FortBuild( $locationNumber )
	if $paused Then
		Return
	EndIf

	Local $name = "build " & $locationNumber
	Local $index = LocationClick( $name )
	Sleep( 400 )
	$buildingCount = 0

	if $index > -1 Then
		Local $type = $locations[$index][3]
		logMessage( "FortBuild: " & $name & ":" & $type  )

		if $type = "bomb" then
			MouseClick( "left", $locations[$index][1] + 40, $locations[$index][2] + 30, 2 )
			Sleep(200)
			MouseClick( "left", $locations[$index][1] + 40, $locations[$index][2] + 30, 2 )
		ElseIf $type = "mage" Then
			MouseClick( "left", $locations[$index][1] - 40, $locations[$index][2] + 30, 2 )
			Sleep(200)
			MouseClick( "left", $locations[$index][1] - 40, $locations[$index][2] + 30, 2 )
		ElseIf $type = "militia" Then
			MouseClick( "left", $locations[$index][1] + 40, $locations[$index][2] - 30, 2 )
			Sleep(200)
			MouseClick( "left", $locations[$index][1] + 40, $locations[$index][2] - 30, 2 )
		ElseIf $type = "archer" Then
			MouseClick( "left", $locations[$index][1] - 40, $locations[$index][2] - 30, 2 )
			Sleep(200)
			MouseClick( "left", $locations[$index][1] - 40, $locations[$index][2] - 30, 2 )
		Else
			logMessage( "unknown fort type " & $type )
		EndIf
	endIf
EndFunc

func FortUpgrade( $locationNumber )
	if $paused Then
		Return
	EndIf
	Local $name = "build " & $locationNumber
	$buildingCount = 0

	if LocationClick( $name ) Then
		Sleep( 700 )
		local $index = _ArraySearch( $locations, $name )
		MouseClick( "left", $locations[$index][1], $locations[$index][2] - 50, 2 )
		MouseClick( "left", $locations[$index][1], $locations[$index][2] - 50, 2 )
		MouseClick( "left", $locations[$index][1], $locations[$index][2] - 50, 2 )
	endIf
	Sleep( 250 )
	ResetMouse()
EndFunc

func ReinforcementsPlace($lane = 0)
	local $localLane = Random( 1, 3, 1)
	if $localLane == 3 then
		$localLane = 2
	EndIf
	if $lane > 0 Then
		$localLane = $lane
	EndIf

	logMessage( "ReinforcementsPlace:" & $localLane  )

	LocationClick( "reinforcements" )
	Sleep(400)
	LocationClick( "lane " & $localLane )
	Sleep(200)
	; safe guard extra click
	LocationClick( "fire 2" )
	ResetMouse()
EndFunc

func RainFire($lane = 0)
	if $paused Then
		Return
	EndIf
	local $localLane = Random( 1, 2, 1)
	if $lane > 0 Then
		$localLane = $lane
	EndIf

	logMessage( "RainFire:" & $localLane & ":" & $lane  )
	LocationClick( "fire" )
	LocationClick( "fire " & $localLane )
	ResetMouse()
EndFunc

func StartWave()
	; click each start wave location
	for $x = 1 to 3
		local $index = LocationClick( "start wave " & $x )
		Local $fireWindowChecksum = PixelChecksum( 36, 363, 57, 380 )

		if $index > -1 Then
			MouseClick( "left" )
			MouseClick( "left" )
			for $xPlus = 0 to 50 step 10
				MouseMove( $locations[$index][1]+$xPlus, $locations[$index][2] )
				MouseClick( "left" )
				MouseClick( "left" )
				$xPlus += 10
				MouseMove( $locations[$index][1]+$xPlus, $locations[$index][2]-15 )
				MouseClick( "left" )
				MouseClick( "left" )
			next
			; look for fire window to change
			;if $fireWindowChecksum <> PixelChecksum( 36, 363, 57, 380 ) Then
			;	return $x
			;EndIf
		EndIf
	next
	return $x
EndFunc

func Restart()
	logMessage( "Restart"  )
	LocationClick("try again")
	Sleep( 2000 )
EndFunc

func TryAgain()
	if $paused Then
		Return False
	EndIf
	if hasColorInArea( 331, 316, 10, 10, 0x574026 ) Then
		logMessage( "TryAgain due to dialog middle"  )
		CaptureScreen()
		Return true
	EndIf
	if hasColorInArea( 491, 262, 10, 10, 0xA7eaf9 ) Then
		logMessage( "TryAgain due to dialog right"  )
		CaptureScreen()
		Return true
	EndIf
	return False
EndFunc

func ScrollToStartPosition()
	if $paused Then
		Return
	EndIf

	MouseClickDrag( "left", 80, 300, 146, 67, 45 )
	sleep(500)
EndFunc

func ScrollToTopPosition()
	if $paused Then
		Return
	EndIf

	MouseClickDrag( "left", 346, 67, 375, 300, 45 )
	sleep(500)
EndFunc

func CaptureEsc()
	LocationClick("pause")
	Exit
EndFunc

func CapturePause()
	$paused = not $paused
	if $paused Then
		LocationClick("pause")
	EndIf
	logMessage( "paused: " & $paused );
EndFunc


Func CaptureScreen()
	Local $fileName = @MyDocumentsDir & "\kingdom_rush\kingdom_rush_capture_" & $captureCounter & ".jpg"
	_ScreenCapture_Capture( $fileName)
	$captureCounter += 1
	if $captureCounter > 300 Then
		$captureCounter = 0
	EndIf
EndFunc


Func Play()
	Sleep( 5000 )
	; scroll up

	if TryAgain() Then
		Return true
	EndIf

	ScrollToStartPosition()

	; initial builds

	FortBuild( 1 )
	FortBuild( 2 )
	FortBuild( 3 )
	;FortBuild( 4 )
	local $currentBuilding = 4

	if TryAgain() Then
		Return true
	EndIf

	LocationClick( "hero" )
	LocationClick( "lane 1" )

	ScrollToTopPosition()

	Sleep( 1000 )

	$lane = StartWave()
	if $lane == 3 Then
		$lane = 2
	EndIf

	ScrollToStartPosition()
	ReinforcementsPlace(2)
	ResetMouse()

	local $laneZeroCount = 0, $activeCount = 0
	local $upgradeBuildingAllowed = False
	local $buildingIncomeRate = 8
	local $buildingDelayMin = 6
	Local $hobgoblinPrepare = False
	Local $hobgoblinGone = False
	$buildingDelay = 25
	$buildingCount = 10

	Local $timerFire = TimerInit()
	Local $timerRein = TimerInit()
	Local $timerPlay = TimerInit()

	while WinActive( $title )
		while $paused
			Sleep(10000)
			logMessage( "paused" )
		WEnd

		if not SleepWinActive( $title, 1000 ) Then
			return false
		EndIf

		$activeCount+=1

		if TryAgain() Then
			Return true
		EndIf

		$buildingCount += 1

		; check lane usage
		Local $lane1Checksum = PixelChecksum(156, 256, 308, 290, 4)
		Local $lane2Checksum = PixelChecksum(300, 140, 336, 178, 4)
		Local $lane3Checksum = PixelChecksum(493, 202, 554, 230, 4)

		sleep(500)

		Local $lane1ChecksumChange = PixelChecksum(156, 256, 308, 290, 4)
		Local $lane2ChecksumChange = PixelChecksum(300, 140, 336, 178, 4)
		Local $lane3ChecksumChange = PixelChecksum(493, 202, 554, 230, 4)

;~ 		logMessage( $lane1Checksum & ":" & $lane1ChecksumChange & " " & $lane2Checksum & ":" & $lane2ChecksumChange & " " & $lane3Checksum & ":" & $lane3ChecksumChange  )

		if $lane3Checksum <> $lane3ChecksumChange then
			$lane = 2
			$laneZeroCount = 0
		Elseif $lane1Checksum <> $lane1ChecksumChange or $lane2Checksum <> $lane2ChecksumChange Then
			$lane = 1
			$laneZeroCount = 0
		Else
			$lane = 0
			$laneZeroCount += 1
		endif

		logMessage( StringFormat( "play:%u rein:%u fire:%u build:%d buildDelay:%d lane:%d activeCount:%d", TimerDiff($timerPlay)/1000, TimerDiff($timerRein)/1000, TimerDiff($timerFire)/1000, $buildingCount, $buildingDelay, $lane, $activeCount ) )

		if TryAgain() Then
			Return true
		EndIf

		if TimerDiff($timerRein) > ($reinforementsDelay*1000) Then
			ReinforcementsPlace($lane)
			$timerRein = TimerInit()
		EndIf

		if TryAgain() Then
			Return true
		EndIf

		if ( TimerDiff($timerFire) > ($fireDelay*1000) and $lane > 0 ) or $activeCount == 6 Then
			RainFire($lane)
			$timerFire = TimerInit()
		EndIf

		if TryAgain() Then
			Return true
		EndIf

		; cater for hobgoblin
		if ( TimerDiff($timerPlay) > (220*1000) ) and not $hobgoblinPrepare Then
			$buildingCount = $buildingDelay+1
			$hobgoblinPrepare = True
			logMessage("prepare for hobgoblin")
		EndIf

		; after hobgoblin
		if ( TimerDiff($timerPlay) > (280*1000) ) and not $hobgoblinGone Then
			$buildingCount = $buildingDelay+1
			$hobgoblinGone = True
			logMessage("hobgoblin GONE")
		EndIf

		if $buildingCount > $buildingDelay Then
			FortBuild( $currentBuilding )

			if $upgradeBuildingAllowed Then
				FortUpgrade($currentBuilding)
				; make sure play area has not moved about after building something
				ScrollToStartPosition()
			EndIf
			ResetMouse();
			$currentBuilding += 1

			if $currentBuilding > $buildingLength Then
				$currentBuilding = 1
				$upgradeBuildingAllowed = True
			EndIf

			; assume more income as game progresses
			$buildingDelay = _Max($buildingDelayMin, $buildingDelay-$buildingIncomeRate)
		EndIf

		if TryAgain() Then
			Return true
		EndIf

		if TimerDiff($timerPlay)/1000 > 700 or $laneZeroCount > 20 Then
			logMessage( "too long, restart" )
			LocationClick("pause")
			LocationClick("restart")
			return True
		EndIf

	WEnd
	logMessage( $title & " no longer active" )
	CaptureScreen()
	return False
EndFunc

logMessage("Set focus to Phone screen" )
$hwnd = WinWaitActive( $title )
; Retrieve the position as well as the height and width of the window
$aWindowPos = WinGetPos($hWnd)

WinMove($hWnd, "", $aWindowPos[0], $aWindowPos[1], $windowX, $windowY)
$aWindowPos = WinGetPos($hWnd)
HotKeySet ( "{ESC}", "CaptureEsc" )
HotKeySet ( "{PAUSE}", "CapturePause" )

while Play()
	Restart()
	$loops += 1
	logMessage( "loops:" & $loops  )
WEnd
logMessage( "finished:" & $loops  )


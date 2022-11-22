/*
-------------------------------------------------------
OrigName: FeedFinder-Spiceworks.ahk
Created: 2022-Nov-18 09:51:37
First Created \\PF0Y7SQH by user Bart.Strauss
-------------------------------------------------------
*/

InitializeScript: ; #Region Initialize Script

#SingleInstance force ;Loads only one instance of script.  If another instance is running, the new one terminates it.
#NoEnv ;Avoids checking empty variables to see if they are environment variables
#Warn ;Avoids pushing error messages.  Useful for scripts that don't initialize variables before trying to use them
SetBatchLines, -1 ; maximum speed of executing lines in the script
SendMode Input ; used to set up buffering of Keystrokes and mouse click.  Performace improvement over 'SendMode Event'
SetWorkingDir %A_ScriptDir%
; #EndRegion

main:
/*
Based off of articles:
https://community.spiceworks.com/blog/77-how-do-you-use-the-community-rss-feeds
*/
FeedBase =
(
https://community.spiceworks.com/feed/blog/
https://community.spiceworks.com/feed/forum/
	)

FileDelete,%A_ScriptName%.htm
cnt:=0
RemoveRefresh =

HTMLTop =
(
	<html>
	<head>
 <!-- Next line to help show progress.  May want to remove/comment out when done building. -->
	<meta id="refresh" http-equiv="refresh" content="5" />
	</head>
	<style>
		html {	font-family: 'Trebuchet MS', 'Lucida Sans', Arial, sans-serif;background:silver;	}
		table {	border:2px solid black; cell-spacing:0px;border-collapse:collapse;font-size:small; background:#ddd;	}
		th, td {	border:1px solid gray; padding-left:10px; padding-right:10px;	}
		td a:hover {	background: white;	}
		th {	background:black;color:orange;	}
		img {	float:left; heigh:14px; width:14px;	}
		.count {	font-size: large;	}
	</style>
	<body>
	<div class="Count">
[Statistics]
Number Of Feeds=
</div><hr>
	<table><tr>
<th>#</th><th> Title</th><th>Feed ID</th><th>Description</th>
</tr>

	)
FileAppend,%HTMLtop%,%A_ScriptName%.htm

Loop,parse,feedbase,`n,`r
	feedcnt := A_Index
FeedIDs := 10000 ; number of feeds to try.  URI will be like /feed/forum/[NUMBER].rss.  Feeds have been found where 'ID' has been 4 digits.F12

; #Region Build GUI for progress
FeedProgMax := FeedCnt * FeedIDs
FeedProgW := A_ScreenWidth *.75
Gui, add, Text,w%FeedProgW% vScanTXT, Scanning for feed
Gui, add, Progress, vFeedProg w%FeedProgW% Range0-%FeedProgMax% border y+5
Gui, add, Text, w%FeedProgW% vCountTXT y+5, Feeds Found: 0
Gui,Show
; #EndRegion Build GUI for progress

TotalProg := 0
Loop,parse,feedbase,`n,`r ; Loop thru site URLs
{
	ThisBase := A_LoopField
	Loop,%FeedIDs% ; Loop thru count of IDs to look for
	{
		value := ThisBase . A_Index . ".rss"
		GuiControl,,ScanTXT, Scanning for Feed at: %value%
		feed:=UrlDownloadToVar(value)

		title :=
		description :=
		img :=
		id := (StrSplit(ThisBase,"/"))[5] . " #" . A_Index

		TotalProg++
		GuiControl,,FeedProg,%TotalProg%
		GuiControl,,CountTXT, %TotalProg% of %FeedProgMax% URLs scanned.`t`tFeeds Found: %cnt%
		If (inStr(feed,"<description"))
		{
			GuiControl,,ScanTXT, Found a Feed: %value%
			Loop, Parse, Feed,`n,`r
			{
				If (InStr(A_LoopField,"<item")) ; in place to go thru only the top of the downloaded page and stop after it gets to the first article.  Less processing time and doesn't muddle up process results below.
					Break
				; Below probably could have been RegEx, but I'm still not that good at it, so...  yeh... deal with it :P
				If (InStr(A_LoopField,"<title"))
					Title := StrReplace(StrReplace(trim(strreplace(strreplace(A_LoopField,"`n"),"`r")),"<title>"),"</title>")
				If (InStr(A_LoopField,"<description"))
					Description :=  StrReplace(StrReplace(trim(strreplace(strreplace(A_LoopField,"`n"),"`r")),"<description>"),"</description>")
				If (InStr(A_LoopField,"<url"))
					img :=  StrReplace(StrReplace(trim(strreplace(strreplace(A_LoopField,"`n"),"`r")),"<url>"),"</url>")


			}
		}
		else
			continue

		if (title != "" AND title !="Page Not Found") ; error catching for page IDs that don't return anything or return a 404 page.  Usually matches to HTML HEAD <TITlE> tag as opposed to RSS XML <title> field.
		{
			cnt++
			HTMRow =
			(
				<tr><td style="text-align:right;">%cnt%</td><td><a href="%value%" target="_blank"><img src="%img%"/>%title%</a></td><td style="text-align:right;">%id%</td><td>%description%</td></tr>
				)
			fileappend,%HTMRow%`n,%A_ScriptName%.htm
			IniWrite, `t%cnt%,%A_ScriptName%.htm,Statistics,Number Of Feeds ; Writing to top of the HTML
			GuiControl,,CountTXT, %TotalProg% of %FeedProgMax% URLs scanned.`t`tFeeds Found: %cnt%
		}
	}
	HTMRow =`n	<tr><td colspan="4" style="background:orange;"></td></tr>`n
	fileappend,%HTMRow%`n,%A_ScriptName%.htm
} 

HTMLbottom =
(
	</table>
	</body></html>

	)

FileAppend,%HTMLbottom%,%A_ScriptName%.htm
MsgBox, end

ExitApp



UrlDownloadToVar(URL) {
	;Eddy: http://www.autohotkey.com/board/topic/9529-urldownloadtovar/page-6
	ComObjError(false)
	WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WebRequest.Open("GET", URL)
	WebRequest.Send()
	Return WebRequest.ResponseText
}
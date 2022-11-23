/*
-------------------------------------------------------
OrigName: FeedFinder-Spiceworks.ahk
Created: 2022-Nov-18 09:51:37
First Created  on \\PF0Y7SQH by user Bart.Strauss
-------------------------------------------------------
*/

InitializeScript: ; #Region Initialize Script

#SingleInstance force ;Loads only one instance of script.  If another instance is running, the new one terminates it.
#NoEnv ;Avoids checking empty variables to see if they are environment variables
#Warn ;Avoids pushing error messages.  Useful for scripts that don't initialize variables before trying to use them
SetBatchLines, -1 ; maximum speed of executing lines in the script
SendMode Input ; used to set up buffering of Keystrokes and mouse click.  Performace improvement over 'SendMode Event'
SetWorkingDir %A_ScriptDir%
; #EndRegion Initialize Script
;~ -----
/*
Based off of articles:
https://community.spiceworks.com/blog/77-how-do-you-use-the-community-rss-feeds
*/
FeedBase = ; URL to append followed by maximum iterations of it.
(
https://community.spiceworks.com/feed/blog/,100
https://community.spiceworks.com/feed/forum/,10000
	)

FileDelete,%A_ScriptName%.htm
cnt:=0
RemoveRefresh =
RefreshTag = <meta id="refresh" http-equiv="refresh" content="5" />
HTMLTop =
(
	<html>
	<head>
 <!-- Next line to help show progress.  May want to remove/comment out when done building. -->
	%RefreshTag%
	</head>
	<style>
		html {	font-family: 'Trebuchet MS', 'Lucida Sans', Arial, sans-serif;background:silver;	}
		table {	border:2px solid black; cell-spacing:0px;border-collapse:collapse;font-size:small; background:#ddd;	}
		th, td {	border:1px solid gray; padding-left:10px; padding-right:10px;	}
		td a:hover {	background: white;	}
		th {	background:black;color:orange;	}
		img {	float:left; heigh:14px; width:14px;	}
		.count {	font-size: large; 	}
		.pubDate {	font-family:Consolas, Courier, monospace; text-align:right;	}
		.HaveRSS {	background:darkgrey; color:white;	}
		.NoArticles {	background:yellow; color:darkgrey;	}
		.LastPubAge {	Text-Align:right;	}
	</style>
	<body>
	<div class="Count">
[Statistics]
Number Of Feeds=
</div><hr>
	<table><tr>
<th>#</th><th> Title</th><th># of Articles</th><th>Most Recent Post</th><th>Days Old</th><th>Feed ID</th><th>Description</th>
</tr>

	)
FileAppend,%HTMLtop%,%A_ScriptName%.htm

FeedIDs := 0 ; number of feeds to try.  URI will be like /feed/forum/[NUMBER].rss.  Feeds have been found where 'ID' has been 4 digits.F12
Loop,parse,feedbase,`n,`r
{
	ThisBase := (StrSplit(A_LoopField,"`,"))[1]
	feedcnt := A_Index
	FeedIDs += ThisBase := (StrSplit(A_LoopField,"`,"))[2]
}

; #Region Build GUI for progress
FeedProgMax := FeedIDs
FeedProgW := A_ScreenWidth *.75
Gui, add, Text,w%FeedProgW% vScanTXT, Scanning for feed
Gui, add, Progress, vFeedProg w%FeedProgW% Range0-%FeedProgMax% border y+5
Gui, add, Text, w%FeedProgW% vCountTXT y+5, Feeds Found: 0
Gui,Show
; #EndRegion Build GUI for progress

CSV =
TotalProg := 0
Loop,parse,feedbase,`n,`r ; Loop thru site URLs
{
	ThisBase := (StrSplit(A_LoopField,"`,"))[1]
	ThisBasesIDs:= (StrSplit(A_LoopField,"`,"))[2]
	Loop,%ThisBasesIDs% ; Loop thru count of IDs to look for
	{
		value := ThisBase . A_Index . ".rss"
		GuiControl,,ScanTXT, Scanning for Feed at: %value%
		feed:=UrlDownloadToVar(value)

		title :=
		description :=
		img :=
		LastPub :=
		NumOfArticles := 0
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

			Loop, Parse, Feed,`n,`r
			{
				If (InStr(A_LoopField,"<item")) ; in place to go thru only the top of the downloaded page and stop after it gets to the first article.  Less processing time and doesn't muddle up process results below.
					NumOfArticles++
			}

		}
		else
			continue

		if (title != "" AND title !="Page Not Found") ; error catching for page IDs that don't return anything or return a 404 page.  Usually matches to HTML HEAD <TITlE> tag as opposed to RSS XML <title> field.
		{
			Loop, Parse, Feed,`n,`r
			{
				If (InStr(A_LoopField,"<pubDate")) ; Looks to see when the last article was published.  Maybe to see if forum is dead.
				{
					LastPub := StrReplace(StrReplace(trim(strreplace(strreplace(A_LoopField,"`n"),"`r")),"<pubDate>"),"</pubDate>")
					Break
				}
			}

			RawLastPubDate := ParseRCF822Date(LastPub, 1)
			LastPubAge := a_Now
			EnvSub, LastPubAge, RawLastPubDate, Days

			AgeOpacity := LastPubAge-30
			If (AgeOpacity < 0)
				AgeOpacity := 0
			If (AgeOpacity > 255)
				AgeOpacity := 255

			AgeColor = 255,0,0
			if (LastPubAge < 61)
			{
				AgeOpacity  := 128
				AgeColor = 255,255,0
			}
			if (LastPubAge < 30)
				AgeColor = 128,255,0
			if (LastPubAge < 8)
				AgeColor = 0,255,0

			if (NumOfArticles = 0)
			{
				AgeOpacity := 0
				AgeColor = 0,0,0
			}


			FormatTime, LastPub, %RawLastPubDate%, yyyy-MM-dd HH:mm:ss
			CSV = %CSV%"%Title%",%LastPub%,%LastPubAge%,%NumOfArticles%,"%value%","%Description%"`n

			cnt++
			HTMRow =
				(
				<tr><td style="text-align:right;">%cnt%</td>
					<td><a href="%value%" target="_blank"><img src="%img%"/>%title%</a></td>
					<td style="text-align:right;">%NumOfArticles%</td>
					<td class="pubDate">%LastPub%</td>
					<td class="LastPubAge" style="background: rgba(%AgeColor%,%AgeOpacity%);">%LastPubAge%</td>
					<td style="text-align:right;">%id%</td>
					<td>%description%</td>
				</tr>
				)

			if (NumOfArticles = 0 )
			{
				InHTMRow = <tr><td style="text-align:right;">
				NoArticles = <tr Class="NoArticles"><td style="text-align:right;">
				HTMRow := StrReplace(HTMRow, InHTMRow,NoArticles)
			}
			; #Region This section is specific to my personal RSS aggregator.
			IniRead, myRSSFeeds, RSS Ticker_ (%A_Computername% %A_UserName%).ini, Sources
			if (InStr(myRSSFeeds,value))
			{
				InHTMRow = <tr><td style="text-align:right;">
				HaveRSS = <tr Class="HaveRSS"><td style="text-align:right;">
				HTMRow := StrReplace(HTMRow, InHTMRow,HaveRSS)
			}
			; #ENDRegion This section is specific to my personal RSS aggregator.

			fileappend,%HTMRow%`n,%A_ScriptName%.htm
			IniWrite, `t%cnt%,%A_ScriptName%.htm,Statistics,Number Of Feeds ; Writing to top of the HTML
			GuiControl,,CountTXT, %TotalProg% of %FeedProgMax% URLs scanned.`t`tFeeds Found: %cnt%
		}
	}
	HTMRow =`n	<tr><td colspan="7" height="5px" style="background:orange;"></td></tr>`n
	fileappend,%HTMRow%`n,%A_ScriptName%.htm

}

HTMLbottom =
(
	</table>
	</body></html>

	)

FileAppend,%HTMLbottom%,%A_ScriptName%.htm
FileRead,ALLHTM,%A_ScriptName%.htm
ALLHTM := StrReplace(ALLHTM, RefreshTag)
FileAppend %ALLHTM%, %A_ScriptName%.tmp
FileMove %A_ScriptName%.tmp, %A_ScriptName%.htm, 1
Sort CSV
Sort CSV, U
FileDelete, %A_ScriptName%.csv
CSV = "RSS Title","Last Article Pub'd","Days Old","# of Articles","URL of RSS","Description"`n%CSV%
FileAppend, %CSV%,%A_ScriptName%.csv
IniWrite, `t%cnt%  (final result),%A_ScriptName%.htm,Statistics,Number Of Feeds ; Writing to top of the HTML
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


ParseRCF822Date(datetime, UTC=0, centurythreshold=2010){
	;Returns YYYYMMDDHH24MISS from a RFC822 or RSS PubDate date-time.
	static Needle:="i)([a-z]{3}),{0,1} (\d{1,2}) ([a-z]{3}) (\d{2,4}) (\d{1,2}):(\d{2}):{0,1}(\d{0,2}) ?([a-z0-9+-]{0,5})"
		, months:="Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec"
	FormatFloat:=A_FormatFloat, c:=0
	If !RegExMatch(datetime,needle,dt)
		Return False
	If (dt7="")
		dt7=0
	If (dt8="")
		dt8=z

	If (UTC){
		If RegExMatch(dt8,"^(\+|-)(\d{2})(\d{2})$",dtc)
			c:=dtc2*60+dtc3*(dtc1="+" ? 1 : -1)
		Else If RegExMatch(dt8,"i)^([a-z]{2,3})$")
			; c:= (-4*!!RegExMatch(dt8,"i)EDT")-5*!!RegExMatch(dt8,"i)EST|CDT")-6*!!RegExMatch(dt8,"i)CST|MDT")-7*!!RegExMatch(dt8,"i)MST|PDT")-8*!!RegExMatch(dt8,"i)PST"))*60
		c:= (-4*!!RegExMatch(dt8,"i)EDT")-4*!!RegExMatch(dt8,"i)EST|CDT")-5*!!RegExMatch(dt8,"i)CST|MDT")-6*!!RegExMatch(dt8,"i)MST|PDT")-7*!!RegExMatch(dt8,"i)PST"))*60 ; Adjusted because it seemed ahead by an hour.
		Else If RegExMatch(dt8,"i)^([a-z]{1})$")
			c:=(InStr("MLKIHGFEDCBAZNOPQRSTUVWXY",dt8)-13)*60
	}

	SetFormat,Float,04.0
	YYYY:= (dt4<100 ? dt4<Mod(centurythreshold,100) ? dt4+(centurythreshold//100)*100-100 : dt4+(centurythreshold//100)*100 : dt4)+0.0
	SetFormat,Float,02.0
	MM:=(InStr(months, dt3)//4)+1.0
	DD:=dt2+0.0
	HH24:=dt5+0.0
	If (HH24>A_Hour)
	{
		difference:=a_now,difference+=-a_nowUTC
		difference:=difference/10000
		HH24:=Format("{:02}", HH24+difference)
	}
	MI:=dt6+0.0
	SS:=dt7+0.0

	SetFormat,Float,% FormatFloat

	Result:=YYYY . MM . DD . HH24 . MI . SS
	; TickerItemDateTime:=YYYY . "-" . MM . "-" . DD . " " . HH24 . ":" . MI . ":" . SS
	TickerItemDateTime:=YYYY . MM . DD . HH24 . MI . SS
	If (TickerItemDateTime > A_Now)
		TickerItemDateTime += -1, hours
	FormatTime, TickerItemDateTime, %TickerItemDateTime%, yyyy-MM-dd HH:mm:ss
	Result+=-c,Minutes
	Return Result
}
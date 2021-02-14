script "behavior_ListenSelectPlay"
# behavior_ListenSelectPlay
# Assigned to card "listen-Browse" of stack "Listen"

# DESCRIPTION: This script handles all interaction with a previously instantiated playlist
# user selections of audio, display of info etc are triggered here in this script.
#
#  PARAMS: We need the sCurrentPlayListA array
# which contains the necessary records
# use playlist_GetRecords() which is in the stack script
# theoretically the playlist/array is already instantiated
#
# CHANGES: 2017-06-22 created, Brahmanathaswami
#
---------------------------------------------------------------------
# Devtools: control click on the image to show devtools group  and hide it
# add more if you like.. there is a field  "localResult" you can use instead
# of the msg box... helpful at times...
---------------------------------------------------------------------
global sConfigA,sCardName
local sSelectedItemA,sSelectedURL,sRemoteURL,sSelectNum,sLastTarget,sLineNum
local sTimeStamp, sSelectionsA
local sDownloadedAudioA


-----------------------------------------------------------------------
# UI Interactions | card, group, list, detail display change ups
-----------------------------------------------------------------------

on mouseup
   local pTarget, tTarget, tHideDownload, detailVis, 
   -- answer "hello" with "OK"
   # there are no scripts at all ( or should not be unless really needed)
   #  in any objects of the UI.
   # all logic for user interaction with the GUI is handled here.
   # but please don't overload the case statements
   # this just a mouse/touch event router. 
   # encapsulate discreet actions that take more than a few lines
   # to separate handlers.
   
   put long id of the target into pTarget
   put the short name of the Target  into tTarget   
   --breakpoint
   
   
   switch tTarget
      # card navigaton
      case "collections-label"
         go to card "listen-collection"
         put "listen-collection" into sCardName
         break
      case "listen-browse"
         go to card "listen-browse"
         put "listen-browse" into sCardName
         break
      case "my-audio-label"
         go to card "listen-my-audio"
         put "listen-my-audio" into sCardName
         break
      case "deleteOn"
         show fld "Display" visual effect "dissolve" very slow
         wait 250 milliseconds
         hide fld "Display" visual effect "dissolve" very slow
         go to card "listen-delete-file"
         put empty into fld "currentFilePick"
         dispatch  "getSums" to grp "displayFilesSizes"
         dispatch  "displayTargetFiles" to grp "displayFilesSizes" with "audio"
         break
      case "listen-file"
         local tTrue
         go to card "listen-file"
         
         show grp "audioDetails"
         
         if  (the number of characters in field "audioDetails" < 20) then
            hide grp "audioDetails"
         end if
         
         if isMobile() then
            deleteMobileControl "audioPlayer" # in case one is open already and playing
         end if  
         
         show  widget "pauseAudio" 
         # which means he is listen because it is already running
         hide widget "playAudio" 
         # which means he is NOT playing. He is on PAUSE
         
      case "AudioList"
         local tTitle,localURL
         
         # sLineNum is the physical line number the user clicks on the field
         # sRecentNum is the numeric key value is the sSelectionsA play list array
         
         # clear the color of the last line before setting the  sLineNum
         
         # we needed to stop player
         
         if sLineNum <> empty then
            setAudioListColors sLineNum,"0,0,0"
         end if
         
         # now we register the user interaction: clicks on a line.
         
         put word 2 of clickline() into sLineNum
         
         # every 2 line is one entry; we just one to color the Title
         # though the use might click on the artist...
         
         if (sLineNum mod 2) = 0 then
            subtract 1 from sLineNum
         end if
         put line sLineNum of fld "audiolist" into tTitle
         set the backgroundcolor of line sLineNum of fld "audiolist" to "174,30,66"
         
         # the follow "trick" return the array key
         put round(sLineNum/2) into sSelectNum 
         
         # we have get sCardName to determine who to show download 
         put sCardName into tHideDownload
         
         go to card "listen-file"
         put sSelectNum into fld "theSelectNum"
         
         
         lock screen
         # but we have stopPlayer  
         # on by mobile
         stopPlayer  
         
         # if the use had downloaded audio it appears on my-audio card
         # we can start the player; get the audio locally
         
         if sCardName = "listen-my-audio" then
            direct_Play  sSelectNum,sCardName
         else
            select_Play sSelectNum  # will use either the line number or item id
         end if
         
         local tURL
         if  "audio/book" is not in tURL then # no display details
            select_ShowDetails "downloaded"
         end if 
         
         show grp "audioDetails"
         if  (the number of characters in field "audioDetails" < 20) then
            hide grp "audioDetails"
            show grp "noInformation"
         end if 
         if  (the number of characters in field "audioDetails" > 20) then
            show grp "audioDetails"
            hide grp "noInformation"
         end if
         
         if tHideDownload = "listen-my-audio" then
            hide grp "DownloadSelection"
         else
            show grp "DownloadSelection"
         end if
         
         unlock screen
         # this if for showing lyric, artist or transcript
         # add appears iinterrupt()
         # it have pass sTimeStamp before you touch the player
         break
         
         // we go to lib_MobileControls
         
      case "PlayPause" #  audio is playing; the icon to 2 vertical bars;
         local tPlayPause
         
         get the iconPresetName of widget "PlayPause"
         put it into tPlayPause
         
         if tPlayPause is "pause" then
            if not isMobile() then
               put  the currentTime of player "audioPlayer" into sTimeStamp
            else
               put mobileControlGet ( "audioPlayer", "currentTime" ) into sTimeStamp
            end if
            pausePlayer sTimeStamp
         else
            if not isMobile() then
               put  the currentTime of player "audioPlayer" into sTimeStamp
            end if
            playPausedAudio sTimeStamp
         end if
         
         break
         
      case "SeekForward"
         audioSeekForward
         break
         
      case "SeekBack"
         audioSeekBack
         break
         
      case "DownloadSelection"  
         put fld "theSelectNum" into sSelectNum
         if connectivity_PingServer() <> "true" then
            dialog_CustomMsg "Offline or Low Bandwidth"
            exit mouseup
         end if
         downloadSelection sSelectNum, pTarget
         break
      case "Loading"
         showBusyIndicator false
         stopPlayer
         break
   end switch
   
   
end mouseup


command switchAudioUi sAudioUI
   local pUI
   if sAudioUI is empty then
      put "hideUI" into sAudioUI
   end if
   # talks UI
   put empty into fld "searchString"
   put sAudioUI into pUI
   switch pUI
      case "hideUI"
         hide grp "titleDescription"
         hide grp "author"
         hide grp "songproperties"
         hide grp "searchControls"
         set the hilitedButton of group "collectionChoice" to empty
         break
      case  "Inspired Talks" 
         hide grp "songProperties"
         show grp "author" 
         show grp "titleDescription"   
         show grp "searchControls"
         break
         
         # song UI   
      case  "songs" 
         hide grp "author"
         show grp "titleDescription"
         show grp "songProperties"
         set the hilited of btn "Title" to true -- group "titleDescription" to empty
         set the hilited of btn "Artists" to false
         show grp "searchControls"
   end switch
end switchAudioUi

command playSingle pDataA
   local tSearchA,x,tItem_id
   local tURL,tSelectedItemA
   
   put empty into tSelectedItemA
   
   put pDataA["url"] into tURL
   put pDataA["item_id"] into tItem_id
   
   unlock screen
   
   startPlayer tURL,pDataA["title"]
   showBusyIndicator false
   if  "audio/book" is not in tURL then # no display details
      select_ShowDetails "downloaded"
   end if 
   
end playSingle

command share_Items 
   local tURL,  sShareItemsA
   if sRemoteURL is empty then
      put "https://www.himalayanacademy.com/view/sivasiva" into  tURL
   else
      put sRemoteURL into tURL
   end if
   put tURL into  sShareItemsA["url"]  
   put "Listen to This!" into sShareItemsA["subject"]
   put "Audio available in the SivaSiva app." into sShareItemsA["text"] 
   return sShareItemsA
end share_Items



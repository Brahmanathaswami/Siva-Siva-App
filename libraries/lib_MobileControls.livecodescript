﻿script "lib_MobileControls"
 --> MetaData
-
license: GPLv3
name: lib_MobileControls
type: library
version: 0.2

/*
This stack has been moved from a frontscript to a library.

The suggestion is to split this into general and more specific libraires - f
or instance lib_MobileScroller and lib_MobileAudio etc ?
*/

######### Mobile Player Controls ############
# libMobileAudioPlayer v1.0 beta
# Brahmanathaswami - copied from Gurudeva.app, code by Jacqueline Landman Gay
# Himalayan Academy 2016

---------------------------------------------------------------------------------------
global gPlayerIsRunning
# needed to allow audio to run freely as user moves to other cards

local sPlayerId, sPlayerRect, sDuration

---------------------------------------------------------------------------------------
-- createMobileAudioPlayer
-- DESCRIPTION
--        
-- PARAMETERS
--		pURL: the ath to the audio file, either http or local
--		pPlayerName: this could be called from any module and the player name will vary
-- Usage: Call this handler to instantiate the player and make it visible
-- If intent is to show when card opens, then call from preopencard handler.
-- if intent is to show dynamically (i.e. default is hidden until the User what to listen to something) then call from the button/or handler using:
-- if intent it is to let audio run while user does other things in the app then
-- set global: something like this  show grp "soundIsPlaying"
--      put 1 into gPlayerIsRunning # use this later when stopping the sound...
-- CHANGES
--         07/20/2016: Brahmanathaswami - updated
--         08/15/2019: BWM - add sPlayerRect, getMobileAudioPlayerRect for responsive use
-------------------------------------------------------------------------------------

-----------------------
# This handler 
-- create the player
-- set it filename: could be a remote/service URL
-- set a busy indicator an remote file
-- BR 2020-03-06 -deprecating the mobilebusy because user has no control

local sPlaying
local sCurrentTime, tHoursMinutes, sTimeStamp, tDuration,  tWidth,
local pDataA, tPausePlayAndroid

command createMobileAudioPlayer pURL, pPlayerName, pAudioRect
   
   --breakpoint
   
   log "createMobilePlayer"
   local tHeight,tPlayloc,
   
   if pPlayerName is among the lines of mobileControls() then
      mobileControlDelete pPlayerName -- init
   end if
   
   mobileControlCreate "player", pPlayerName
   put the result into sPlayerId
   
   if pAudioRect is empty then
      put the rect of player pPlayerName into pAudioRect
   end if
   
   put pAudioRect into sPlayerRect
   
   mobileControlSet pPlayerName, "visible", false
   mobileControlSet pPlayerName, "showcontroller", false
   mobileControlSet pPlayerName, "rect", sPlayerRect
   mobileControlSet pPlayerName, "filename", pURL 
   
   --   if the platform is "android" then
   --      androidStartAudioPlayingInBackground pURL
   --   end if
   
   log pURL
   
   
   if mobileIdleTimerLocked() is false then
      mobileLockIdleTimer --jg: disallow screen lock
   end if
end createMobileAudioPlayer 

function getMobileAudioPlayerRect
   return sPlayerRect
end getMobileAudioPlayerRect

-----------------------
# when the player has a property called "duration:
-- It means that we can start it
-- we toggle on our local widget to "pause" 

on playerPropertyAvailable theProperty -- msg sent when enough has content is loaded
   Log "duration available"
   
   
   if theProperty is "duration" then
      log "Should be setting closing the loading indicator"
      showBusyIndicator false -- Remove the "Loading..." indicator and start playing
      
      put mobileControlGet("audioPlayer","playableDuration") into sDuration
      
      if sDuration = 0 then
         put mobileControlGet("audioPlayer","Duration") into sDuration
      end if
      
      
      put sDuration  * 1000 into sDuration
      put convertTime(sDuration) into tDuration
      
      put true into sPlaying
      mobileControlDo sPlayerId, "play"
      
      send "updateTimer" to me in 20 milliseconds
   
   end if
   
   if there is a widget "PlayPause" then
      set the iconPresetName of widget "PlayPause" of stack "listen" to "pause"
   else
      togglePause true,false
   end if
   
end playerPropertyAvailable

# Desktop player gets thru
on getPlaying pBool
   put pBool into sPlaying
end getPlaying

function setDuration 
   return sDuration
end setDuration

---------------------------------
# here we get the player do play, pause or stop

command setMobileAudioPlayer pPlayerName, pState, pTimeStamp
   --showBusyIndicator false -- in case it's still showing
   log "setMobileAudioPlayer: " & pState
   --jg: control the state of the mobile player
   -- pState = "pause", "play", or "stop"
   
   mobileControlDo pPlayerName, pState
   
   if pState = "stop" then
      
      if the platform is "android" then
         androidStopAudioPlayingInBackground
      end if
      
      mobileControlSet pPlayerName, "showController", false
      mobileControlSet pPlayerName, "visible", false
      mobileControlDelete pPlayerName
      put false into sPlaying
      put empty into sPlayerRect
      if mobileIdleTimerLocked() is true then 
         mobileUnlockIdleTimer
      end if
      get runningAudioIndicatorVis("false")
      
      put false into sPlaying
      updateTimer 
      
      if there is a widget "PlayPause" then
         set the iconPresetName of widget "PlayPause" of stack "listen" to "play"
      end if
      
   end if
   
   if pState = "pause" then
      
      if the platform is "android" then
         androidPauseAudioPlayingInBackground
      end if
      
      # user hit pause
      put mobileControlGet ("currentTime")  into pTimeStamp
      mobileControlDo pPlayerName, "pause"
      put false into sPlaying
      get runningAudioIndicatorVis("true")
      
      put false into sPlaying
      updateTimer
      
      # icon switch to "play"
      if there is a widget "PlayPause" then
         set the iconPresetName of widget "PlayPause" of stack "listen" to "play"
         
         if the platform is "android" then
            androidResumeAudioPlayingInBackground 
         end if
         
      else
         togglePause true,false
      end if
      
   end if
   
   if pState = "play" then # could be start from scratch after pausing
      
      if pTimeStamp is empty then
         put 0 into pTimeStamp
      end if
      mobileControlSet pPlayerName, "currentTime", pTimeStamp
      mobileControlDo pPlayerName, "play"
      
      if the platform is "android" then
         androidResumeAudioPlayingInBackground
      end if
      
      put true into sPlaying
      send "updateTimer sPlaying" to me in 20 milliseconds
      
      if there is a widget "PlayPause" then
         set the iconPresetName of widget "PlayPause" of stack "listen" to "pause"
      end if
      
      get runningAudioIndicatorVis("true")
   end if
   
end setMobileAudioPlayer

--on audioSeekForward
--   // cause play to pause

--   --   if isMobile() then
--   --      setMobileAudioPlayer "audioPlayer", "pause"
--   --   else
--   --      set the paused of  player "audioPlayer" of stack "listen" to "true"
--   --   end if

--   put true into sPlaying
--   set the iconPresetName of widget "PlayPause" of stack "listen" to "play"

--   // auto timer he  allows the  user to forward 

--   put true into sSeek
--   updateTimer 

--   // then allow play

--end audioSeekForward

--on audioSeekBack
--   // cause play to pause

--   // auto timer he  allows the  user to back

--   // then allow play
--end audioSeekBack

Local sFastforward


command updateTimer
   // AAG: This function should not be running if we switch to development mode.
   if the tool is not "browse tool" and the environment is "development" then 
      exit updateTimer
   end if
   
   --   if "updateTimer" is in the pendingMessages then
   --      exit updateTimer
   --   end if
   
   // Update the time indicator
   if sPlaying is true then
      
      if there is no fld "currentTime" of stack "listen" then
         exit updateTimer 
      end if
      
      lock screen
      
      
      if isMobile() then
         put mobileControlGet("audioPlayer","currentTime") into sCurrentTime
         put mobileControlGet("audioPlayer","playableDuration") into sDuration
         
         if sDuration is 0 then  
            put mobileControlGet("audioPlayer","Duration") into sDuration
         end if
         
      else
         if the timeScale of player "audioPlayer" of stack "listen" is 0 then
            -- audio player thinks it is not playing any track...
            send "updateTimer" to me in 100 millisecs
            exit updateTimer
         end if
         put (the duration of player "audioPlayer" of stack "listen" / the timeScale of player "audioPlayer" of stack "listen") * 1000 into sDuration
         put (the currentTime of player "audioPlayer" of stack "listen" / the timeScale of player "audioPlayer" of stack "listen") * 1000 into sCurrentTime
      end if
      
      
      if sCurrentTime > 0 and sDuration > 0 then         
         // Update the time indicator
         put round((sCurrentTime/sDuration) * the width of graphic "durationBG" of stack "listen") into tWidth
         
         // Update time fields
         put convertTime(sCurrentTime) into tHoursMinutes
         put convertTime(sDuration) into tDuration
         
         put tHoursMinutes into fld "currentTime" of stack "listen"
         put tDuration into fld "endTime" of stack "listen"
         
         // Update the time indicator
         set the width of graphic "durationProgress" of stack "listen" to tWidth
         
         --         set the left of graphic "durationProgress" of stack "listen" to 20
         set the left of graphic "durationProgress" of stack "listen" to the left of graphic "durationBG" of stack "listen"
         set the left of graphic "durationMarker" of stack "listen" to (the right of graphic "durationProgress" of stack "listen"  - 7)
      end if
      
      unlock screen
      
      send "updateTimer" to me in 100 millisecs
   end if
end updateTimer  

function getCurrentTime 
   return sCurrentTime
end getCurrentTime

function getHoursMinsTime
   return tHoursMinutes
end getHoursMinsTime


local tMilliseconds, tHours, tMinutes, tSeconds

function convertTime pMilliseconds
   put ((pMilliseconds div 1000) mod 60) into tSeconds
   put ((pMilliseconds div (1000*60)) mod 60) into tMinutes
   put ((pMilliseconds div (1000*60*60)) mod 24) into tHours
   
   get format("%02s",tHours) & ":" & format("%02s",tMinutes) & ":" & format("%02s",tSeconds)
   return it
end convertTime


on playerFinished -- sent on mobile when audio is done
   if mobileIdleTimerLocked() is true then 
      mobileUnlockIdleTimer
   end if
   
   mobileControlDelete sPlayerId
   put false into sPlaying
   put empty into sPlayerRect
   
   put false into sPlaying
   
   if there is a widget "PlayPause" then
      set the iconPresetName of widget "PlayPause" of stack "listen" to "pause"
   else
      togglePause false,true
   end if
   
   get runningAudioIndicatorVis("false")
   
end playerFinished

-------------------------------

command showPlayer pBool, pPlayerName --jg: handles visibility of both mobile and desktop players
   -- if audio is playing, player is shown on audio card, hidden elsewhere;
   -- pBool = boolean
   if isMobile() then
      --hide player pPlayerName -- the LC one; never show it
      mobileControlSet pPlayerName, "showController", pBool
      mobileControlSet pPlayerName, "visible", pBool
   else
      set the vis of player pPlayerName to pBool
   end if
end showPlayer



on deleteMobileControl pName -- jg: deletes an existing mobile control
   -- native controls should be deleted if possible when no longer needed, as
   -- they are overlaid on the stack and will float over all cards
   if not isMobile() then exit deleteMobileControl
   repeat while pName is among the lines of mobileControls()
      mobileControlDelete pName
   end repeat
   
   put "" into sDuration
end deleteMobileControl

on deleteAllMobileControls -- jg: delete all mobile controls of any type in all stacks
   local tList
   if not isMobile() then exit deleteAllMobileControls
   put mobileControls() into tList
   if not (tList contains "audioPlayer") then # play we terminated
      get runningAudioIndicatorVis("false")
   end if
   repeat for each line l in tList
      # we are keeping the player running as per user requests.
      # you need to use an explicit stop/remove in the UI/UX context
      if l contains "audioPlayer" then
         next repeat
      end if  
      mobileControlDelete l
   end repeat
end deleteAllMobileControls

on __Utilities
end __Utilities

command setZeroDurationProgress
   // mobile durationProgress
   set the width of graphic "durationProgress" to 1
   set the left of graphic "durationProgress" to the left of graphic "durationBG"
   set the left of graphic "durationMarker" to (the right of graphic "durationProgress" - 7)
   put "0.00" into field "currentTime"
   put "0.00" into field "endTime"
end setZeroDurationProgress

--on pausePlayer sTimeStamp
--   if not isMobile() then
--      set the paused of  player "audioPlayer" to "true"
--      put false into sPlaying
--   else  
--      setMobileAudioPlayer "audioPlayer", "pause",sTimeStamp
--   end if

--   # we have to record the timestamp of a journal
--   put sTimeStamp into pDataA["timeStamp"]
--   setJournalData pDataA
--   set the iconPresetName of widget "PlayPause" to "play"

--end pausePlayer

--on playPausedAudio sTimeStamp

--   put sTimeStamp into pDataA["timeStamp"]
--   setJournalData pDataA

--   if not isMobile() then
--      set the currenttime  of player "audioPlayer" to sTimeStamp
--      start player "audioPlayer"
--      put true into sPlaying
--   else 
--      setMobileAudioPlayer "audioPlayer", "play", sTimeStamp
--      send "updateTimer" to stack "lib_MobileControls" in 20 milliseconds
--   end if
--   set the iconPresetName of widget "PlayPause" to "pause"
--end playPausedAudio

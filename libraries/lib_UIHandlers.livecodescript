script "lib_UIHandlers"
local sCardRect, sCardWidth, sCardHeight, sCardLoc, sHorizCenter, sVertCenter, sMargins
Local sCurrentGraphicRect,sStopRunningAudio
local sPhoneModel = "unknown"
local sPortraitMargins, sLandscapeMargins, sSafeRect
# Images
local sViewImageState

************************
on __RESPONSIVE
end __RESPONSIVE

# checks

command gotUILibrary
   answer "Got UIHandler Lib" with "OK"
end gotUILibrary

command returnAudioIsPlaying
   answer "Got message"
   put sStopRunningAudio
end returnAudioIsPlaying



# because of inconsistency  we cannot be sure that resizeStack is invoked
# so we are setting explicit setters and getters  for card geometry

########################
-- Get card geometry 





command setCardCoords pForceOrientation
   -- pForceOrientation - orientation to force, only considers first letter
   local tCard, tHeight
   
   put the long id of this card into tCard
   put the rect of tCard into sCardRect
   put item 3 of sCardRect into sCardWidth
   put item 4 of sCardRect into sCardHeight
   if pForceOrientation begins with "p" then
      if sCardWidth > sCardHeight then
         put sCardWidth into tHeight
         put sCardHeight into sCardWidth
         put tHeight into sCardHeight
         put (0,0,sCardWidth,sCardHeight) into sCardRect
      end if
   else if pForceOrientation begins with "l" then
      if sCardWidth < sCardHeight then
         put sCardWidth into tHeight
         put sCardHeight into sCardWidth
         put tHeight into sCardHeight
         put (0,0,sCardWidth,sCardHeight) into sCardRect
      end if
   end if
   put trunc(sCardWidth/2) into sHorizCenter
   put trunc(sCardHeight/2) into sVertCenter
   put (sHorizCenter,sVertCenter) into sCardLoc
   put safeMargins(pForceOrientation) into sMargins
   put (sMargins["side"], sMargins["top"], sCardWidth-sMargins["side"], \
         sCardHeight-sMargins["bottom"]) into sSafeRect
end setCardCoords


command setScreenRectCoords
   local tScreenRect
   local sScreenWidth, sScreenHeight, sScreenVertCenter, sScreenHorizCenter, sWidthDiff, sHeightDiff
   
   put the screenRect into tScreenRect
   put item 3 of tScreenRect into sScreenWidth
   put item 4 of tScreenRect into sScreenHeight
   put sScreenHeight/2 into sScreenVertCenter
   put sScreenwidth/2 into sScreenHorizCenter
   put sScreenWidth-sCardWidth into sWidthDiff
   put sScreenHeight-sCardHeight into sHeightDiff
   put  sHeightDiff into fld "notification"
end setScreenRectCoords


private command _setPhoneModel
   local tScreenRect, tW, tH
   put the screenRect into tScreenRect
   put item 3 of tScreenRect into tW
   put item 4 of tScreenRect into tH
   
   if not isMobile() then
      put "desktop" into sPhoneModel
   else if the platform is "iPhone" then
      if tH is 812 or tH is 896 then
         --iPhone with a notch, portrait
         put "iPhoneX" into sPhoneModel
      else if tW is 812 or tW is 896 then
         --iPhone with a notch, landscape
         put "iPhoneX" into sPhoneModel
      else if (tW is 1024 and tH is 1366) or \
            (tH is 1024 and tW is 1366) then
         --iPad Pro 12.9
         put "iPadPro12.9" into sPhoneModel
      else
         put "iPhone" into sPhoneModel
      end if
   else
      -- will add Android models here
      put "Android" into sPhoneModel
   end if
   
   switch sPhoneModel
      case "iPhoneX"
         put 44 into sPortraitMargins["top"]
         put 34 into sPortraitMargins["bottom"]
         put  0 into sPortraitMargins["side"]
         
         put 0 into sLandscapeMargins["top"] -- 32 if status bar visible
         put 23 into sLandscapeMargins["bottom"]
         put 44 into sLandscapeMargins["side"]
         break
      case "iPadPro12.9"
         put 0 into sPortraitMargins["top"]
         put 34 into sPortraitMargins["bottom"]
         put 0 into sPortraitMargins["side"]
         put 0 into sLandscapeMargins["top"]
         put 23 into sLandscapeMargins["bottom"]
         put 0 into sLandscapeMargins["side"]
         break
      default
         put 0 into sPortraitMargins["top"]
         put 0 into sPortraitMargins["bottom"]
         put 0 into sPortraitMargins["side"]
         
         put 0 into sLandscapeMargins["top"]
         put 0 into sLandscapeMargins["bottom"]
         put 0 into sLandscapeMargins["side"]
   end switch
end _setPhoneModel


function CardRect
   return sCardRect
end CardRect

function CardWidth
   return sCardWidth
end CardWidth

function CardHeight
   return sCardHeight
end CardHeight

function CardLoc
   return sCardLoc
end CardLoc

function horizCenter
   return sHorizCenter
end horizCenter

function vertCenter
   return sVertCenter
end vertCenter

function currentlyLandscape
   return (sCardWidth > sCardHeight)
end currentlyLandscape

-- To account for various device notch designs, make functions
-- available to return the amount of space to allow.
-- Values will be returned based on current orientation.

function safeMargins pForceOrientation
   local tOrientation
   
   if sPhoneModel is "unknown" then _setPhoneModel
   
   if pForceOrientation is not empty then
      put pForceOrientation into tOrientation
      --   else if isMobile() then
      --      --put mobileDeviceOrientation() into tOrientation
      --      put mobileOrientation() into tOrientation
   else
      --      put "u" into tOrientation
      --   end if
      --   if tOrientation begins with "u" or tOrientation begins with "f" then
      if the width of this card < the height of this card then
         put "portrait" into tOrientation
      else
         put "landscape" into tOrientation
      end if
   end if
   if tOrientation begins with "l" then
      return sLandscapeMargins
   else
      return sPortraitMargins
   end if
end safeMargins

function safeTopMargin
   return sMargins["top"]
end safeTopMargin

function safeBottomMargin
   return sMargins["bottom"]
end safeBottomMargin

function safeSideMargin
   return sMargins["side"]
end safeSideMargin

function safeRect
   return sSafeRect
end safeRect

function getPhoneModel
   if sPhoneModel is "unknown" then _setPhoneModel
   return sPhoneModel
end getPhoneModel


####################
-- positioning, various kinds
-- many of these methods would put the control it the same place
-- it is depend on whether you choose to "think" about it as 
-- relation to top of the card, of the bottom of the card

command centerMe pControl, pHeaderHeight, pFooterHeight
   local tYaxis
   # use to center on screen, if the is a foot and header
   # you send those params and pcontrol center in remaining space.
   # This only handles vertical space
   
   put (sCardHeight - pHeaderHeight - pFooterHeight) / 2 into tYaxis
   add pHeaderHeight to tYaxis
   set the loc of pControl to ( sHorizCenter, tYaxis )
   
end centerMe


command topCenterMe pControl, y
   # place a control at the top of the screen
   # can be any width, even beyond the width the card.
   # y is single integer which is from the top of card
   # It empty, defaults to center to screen
   
   set the loc of pControl to sCardLoc
   set the top of pControl to y + sMargins["top"]
   
end topCenterMe

command topRightMe pControl, x, y
   # for a control whose bounds are fully inside the card
   # use X to offset from the right of the card
   # and y is from the top 
   
   set topRight of pControl to (sCardWidth - x - sMargins["side"], \
         y + sMargins["top"])
   
end topRightMe

command topLeftMe pControl, x, y
   # for a control whose bounds are fully inside the card
   # use X to offset from the left of the card
   # and y is from the top 
   
   set topLeft of pControl to (x + sMargins["side"], y + sMargins["top"])
   
end topLeftMe

command bottomRightMe pControl, x, y
   # for a control whose bounds are fully inside the card
   # use X to offset from the right of the card
   # and y to from the bottom.
   
   set bottomright of pControl to (sCardWidth - x - sMargins["side"], \
         sCardHeight - y - sMargins["bottom"])
   
end bottomRightMe

command bottomLeftMe pControl, x, y
   # for a control whose bounds are fully inside the card
   # use X to offset from the left  of the card
   # and y to from the bottom.
   
   set  bottomleft of pControl to (0 + x + sMargins["side"], \
         sCardHeight - y - sMargins["bottom"])
   
end bottomLeftMe

command bottomCenterMe pControl, y
   # place a control at the bottom of the screen
   # can be any width, even beyond the width the card.
   # Y is offset from the bottom
   
   set the loc of pControl to sCardLoc
   set the bottom of pControl to sCardHeight - y - sMargins["bottom"]
end bottomCenterMe 

command adjustLoc pControl, pDeltaX, pDeltaY
   local tLoc
   put the loc of pControl into tLoc
   add pDeltaX to item 1 of tLoc
   add pDeltaY to item 2 of tLoc
   set the loc of pControl to tLoc
end adjustLoc

function checkIsLoading
   if there is a group "loadingGroup" then
      if the vis of group "loadingGroup" is true then
         return true
      end if
      return false
   end if
end checkIsLoading


####################
on ___FIELDManipulation
end ___FIELDManipulation

/*later we can investage Ralph DiMola library 
to add handles or parameters;
for now we just handle the height of the field
and add a scroller if the text is too long.
eventually I would add textSize and Lineheight etc.
*/

command optimizeField pControl,pTextSize,pTextAlign
   local tHeight, tLoc
   -- `the uRect of pControl` must be set to the max size
   
   if pTextsize is not empty then
      set the textSize of pControl to pTextSize
      set the textalign of pControl to pTextAlign
   end if
   
   set the rect of pControl to the uRect of pControl
   put the formattedheight of pControl into tHeight
   
   if tHeight > the height of pControl then
      dispatch "CreateScroller" to pControl with (the short name of pControl) 
   else
      put the loc of pControl into tLoc
      set the height of pControl to tHeight
      set the loc of pControl to tLoc
   end if
end optimizeField

####################
on ___IMAGEManipulation
end ___IMAGEManipulation


# we typically have the some requirement
# change image by height, width.
# we always need to know it original size

command insertImageDimensions pImage
   put ( (the formattedwidth of pImage) & "x" & (the formattedheight of pImage) ) into sCurrentGraphicRect
end insertImageDimensions

function getRectOfCurrentGrc
   return sCurrentGraphicRect
end getRectOfCurrentGrc

command setRectOfCurrentGrc pimage
   local tFWd, tFHt
   
   put the formattedWidth of  pImage into tFWd
   put the formattedHeight of  pImage into tFHt
   put (tFWd & "x" & tFHt) into sCurrentGraphicRect
end setRectOfCurrentGrc

## NOTE: for the following handlers to work you must pass
## the rect in the form of  width x height  this this form ("736x552")
## and the long ID of the target image to "pImage" 

on resizeToHeight pImage,pSize
   local tOrigImgWidth, tOrigImgHeight, tRatio, tNewWidth, tNewHeight
   set the itemdel to "x"
   put item 1 of sCurrentGraphicRect into tOrigImgWidth
   put item 2 of sCurrentGraphicRect into tOrigImgHeight
   
   if tOrigImgHeight is 0 then exit resizeToHeight
   
   put (pSize)/tOrigImgHeight  into tRatio
   put (tOrigImgWidth * tRatio) into tNewWidth
   put (tOrigImgHeight * tRatio) into  tNewHeight 
   
   set the rect of pImage to 0,0,tNewWidth,tNewHeight
   
end resizeToHeight

on resizeToWidth pImage,pSize 
   local tOrigImgWidth, tOrigImgHeight, tRatio, tNewWidth, tNewHeight
   set the itemdel to "x"
   put item 1 of sCurrentGraphicRect into tOrigImgWidth
   put item 2 of sCurrentGraphicRect into tOrigImgHeight
   
   if tOrigImgWidth is 0 then exit resizeToWidth
   
   put pSize/tOrigImgWidth into tRatio 
   put (tOrigImgHeight * tRatio) into tNewHeight
   put (tOrigImgWidth * tRatio) into  tNewWidth
   
   set the rect of  pImage to 0,0,tNewWidth,tNewHeight
   
end resizeToWidth

#  when we want a background in to fill the screen
# but leave room for footer we can this
#  You must pass  the long id of the image, pOrientation,otherwise fails
# you do have to pass footer, 

command setImageToFullCardLoc pImage, pOrientation, x,y
   # don't pass x,y if you want to full image
   # param x = if you to want a shorter image
   setRectOfCurrentGrc pImage
   if pOrientation="portrait" then
      --      if isMobile() then
      --         resizeToHeight pImage,(the height of this card + sHeightDiff -  x)
      --         else
      resizeToHeight pImage,(sCardHeight - x)
      --   end if
   else
      resizeTowidth pImage,(sCardHeight - x)
   end if
end setImageToFullCardLoc

on toggleImgSize pImage, pFullSize, pTargetSize, pLocation
   local tFWd, tFHt, tLocation
   
   # pImage is the long ID of the image
   # if second param is empty we toggle it; otherwise set it as specified;
   # called from main img script when tapped and when main cd closes to reset
   
   put the loc of pImage into tLocation
   put the formattedWidth of pImage into tFWd
   put the formattedHeight of pImage into tFHt
   
   if pFullSize = "" then --  assume if width is bigger than the card:, its fullSize
      put (the width of pImage > sCardWidth) into pFullSize
      # true for landscape (width is greater); false for portrait (height is greater)
   end if
   
   if pFullSize then -- reduce to fit
      resizeToWidth pImage,pTargetSize
   else -- return to full size
      resizeToHeight pImage,max(tFHt,sCardHeight)
   end if
   
   # set the location of image, 
   # it is empty, assume to card rect
   if tLocation = empty then
      set the loc of pImage to sCardLoc
   else
      set the loc of pImage to tLocation
   end if
end toggleImgSize

command switchViewImageState pImage
   if sViewImageState is empty then put 1 into sViewImageState
   switch sViewImageState   
      case 1  # quote is hidden but image is full size
         toggleImgSize pImage,,(the width of this card) 
         set the loc of pImage to sCardLoc
         put 2 into sViewImageState
         break
      case  2 #  image is full size, shrink to card
         toggleImgSize  pImage,,(the formattedwidth of pImage) 
         
         put 1 into sViewImageState     
   end switch
end switchViewImageState

--on toggleImgSize pImage, pFullSize, pTargetSize, pLocation
--   local tFWd, tFHt
--   # we may not always this rect of the images from  the metadata
--   # May as well just find out what it is right here.
--   # pImage is the long ID of the image
--   # you do not use "img ## to refer to it... just "pImage"

--   -- if second param is empty we toggle it; otherwise set it as specified;
--   -- called from main img script when tapped and when main cd closes to reset

--   if pFullSize = "" then -- calculate if it's already full size
--      put (the width of pImage > sCardWidth) into pFullSize
--      # true for landscape (width is greater); false for portrait (height is greater)
--   end if
--   put the formattedWidth of pImage into tFWd
--   put the formattedHeight of pImage into tFHt

--   if pFullSize then -- reduce to fit
--      resizeToWidth pImage,pTargetSize
--   else -- return to full size
--      resizeToHeight pImage,max(tFHt,sCardHeight)
--   end if

--   # set the location of image, 
--   # it is empty, assume to card rect
--   if pLocation = empty then
--      set the loc of pImage to sCardLoc
--   else
--      set the loc of pImage to pLocation
--   end if
--end toggleImgSize



on ___VISUALEFFECTS
END ___VISUALEFFECTS

##########################################################
## VISUAL EFFECTS
##########################################################

--> GRAPHIC EFFECTS

## OuterGlow

function OuterglowA pTint,pColor,pBlendMode,pOpacity,pFilter,pSize,pSpread
   local tOuterglow, pParams, pValues, pParam
   if pTint is empty then
      put pColor into tOuterglow["color"]
      put pBlendMode into  tOuterglow["blendMode"]
      put pOpacity into  tOuterglow["opacity"] 
      put pFilter into  tOuterglow["filter"]
      put pSize into  tOuterglow["size"]
      put pSpread into tOuterglow["spread"]
      return tOuterglow
      exit outerGlowA
   end if
   put "color|blendMode|opacity|filter|size|spread" into pParams
   switch pTint
      case "softBrown"
         put "255,255,0|normal|255|box3Pass|30|50" into pValues
         break
   end switch
   set itemDel to "|"
   repeat with x =1 to 6
      put item x of pParams into pParam
      put item x of pValues into tOuterglow[pParam]
   end repeat
   return tOuterglow
   
end OuterglowA

--> GRADIENT SETTINGS

command setGradient pObject
   # Param "pObject" works locally with simple object reference like  graphic "header"
   # otherwise you should  pass the long ID of the object
   
   local tNewGradientArray
   
   # be careful when cutting and paste to and from email
   # tabs may get replace by spaces:
   
   put "from	208,-201|mirror	false|quality	good|ramp	0.13000,255,255,255,0" & return into tNewGradientArray
   put "0.62001,60,11,9,212|repeat	1|to	208,-304|type	linear|via	536,-201|wrap	true" after tNewGradientArray
   
   split tNewGradientArray by "|" and tab
   set the fillGradient of pObject to tNewGradientArray
   
end setGradient

--> FADE WITH BLENDLEVEL
-- Better to use dissolve.

# BR note that hide and show with visual effect "dissolve" also works, 
# tends to run very fast on mobile

command object_FadeIn  pEffectsTarget, newBlendLevel, someIncrement, someDelay
   set the blendLevel of  pEffectsTarget  to newBlendLevel
   if newBlendLevel > 0 then
      subtract someIncrement from newBlendLevel
      send "object_FadeIn pEffectsTarget, newBlendLevel,someIncrement,someDelay" to me in someDelay milliseconds
   else
      set the blendLevel of pEffectsTarget to 0
   end if
end object_FadeIn

command object_FadeOut  pEffectsTarget, newBlendLevel, someIncrement, someDelay
   set the blendLevel of  pEffectsTarget  to newBlendLevel
   if newBlendLevel <100 then
      add someIncrement to newBlendLevel
      send "object_FadeOut pEffectsTarget, newBlendLevel,someIncrement,someDelay" to me in someDelay milliseconds
   else
      set the blendLevel of pEffectsTarget to 100
   end if
end object_FadeOut


#####################
on __MOTION
end __MOTION

on moveMe pControlName, pHorz, pVert, pSpeed -- use move instead of visual effect to prevent Android issues
   local tPt
   # "moveControl" is a reserve message in LC 
   # hence the name "move Me" 
   # pass 0 pHorz for vertical move and 0 to pVert to horizontal move
   put pHorz,pVert into tPt
   move control pControlName relative tPt in pSpeed milliseconds
end moveMe


######################
on _STATUS_INDICATORS
end _STATUS_INDICATORS

command visMessageToUser pBool
   if there is a fld "notification" then
      if pBool then
         show fld "notification"
         send "visMessageToUser false" to the topstack in 2 second
      else
         hide fld "notification" 
      end if
   end if
end visMessageToUser

command display_SetStatusBarVis visBoolean
   if isMobile() then
      if visBoolean then
         mobileShowStatusBar
      else
         mobileHideStatusBar
      end if 
   end if
end display_SetStatusBarVis

command showLoaderGIF pBool
   if exists (img "loader.gif") then
      if pBool is true then 
         show img "loader.gif"   
         set the repeatCount of img "loader.gif" to -1
      else 
         set the repeatCount of img "loader.gif" to 0    
         hide img "loader.gif"
      end if 
   end if 
end showLoaderGIF



on revealSearchControls pVis --jg: combined reveal/hide handlers
   -- pVis = boolean
   local cMoveSpeed
   
   if there is no grp "searchControls" then -- unplaced on current cd; just set vis & exit
      set the vis of bg "searchControls" to pVis
      exit revealSearchControls
   end if 
   if  pVis <> false  then -- show it
      --jg: horiz centering for mobile screens:
      set the loc of grp "searchControls" to the loc of this cd
      set the bottom of grp "searchControls" to 0
      put empty into fld "searchString" -- of card "Main-view"
      set the vis of group "searchControls" to true
      moveGrp "searchControls",0, the height of grp "searchControls", cMoveSpeed
      focus on fld "searchString" --jg: force mobile keyboard
      select after fld "searchString"
      -- highlightSelectedTab "search" # from gurudeva app, not implements
   else -- hide it
      focus on nothing
      moveGrp "searchControls",0, -(the height of grp "searchControls"), cMoveSpeed
      hide group "SearchControls"
      put empty into fld "searchString" 
      -- clearTabHighlights # from gurudeva app, not implements
   end if  
end revealSearchControls
command display_Log
   portal_GoStack "Log"
end display_Log

local sLoadingIndicator,sLoadingGroup,sLoadingFlag, sLabel, sLoadProgress
local sBusySemaphore

command setBusySemphore pBool
   put pbool into sBusySemaphore
end setBusySemphore

command showBusyIndicator pBool, sMsg --jg: for both desktop and mobile

   if there is a control "loadingGroup" then
      put sMsg into sLabel # stable string
      put sMsg into sLoadProgress # this string will change through the loop below.
      put the long id of control "loadingGroup" into sLoadingGroup
      put the long id of grc "loading" into sLoadingIndicator
      set the label of sLoadingIndicator to sLabel
      if there is a  sLoadingIndicator then
         set the vis of sLoadingGroup to pBool
         if pBool is true then
            put true into sLoadingFlag
            dispatch "loadingInProgress" to me 
         else
            set the vis of sLoadingGroup to pBool
            put empty into sLoadProgress
            set the label of sLoadingIndicator to ""
            put false into sLoadingFlag
         end if
      end if
   end if
end showBusyIndicator

command loadingInProgress
   if sLoadingFlag is true then
      
      if sLoadProgress contains ". . . . . . . . . . ." then
         if sLoadProgress contains "Loading" then
            put "Tap to Stop" into sLoadProgress
         else
            
            put sLabel into sLoadProgress
         end if
      end if
      put ". " after sLoadProgress
      set the label of sLoadingIndicator  to sLoadProgress
      send "loadingInProgress" to me in 300 milliseconds
   end if
end loadingInProgress

# Cover the screen with touchTrap graphic
# Control scripts discard mouseDown/mouseUp events
command lockTouches
   local tControl
   lock screen
   --
   if there is not a grc "touchTrap" then
      copy grc "touchTrap" of cd "curtain" of stack "lib_CustomControls" to this cd
   end if
   put the long id of grc "touchTrap" into tControl
   set the visible of tControl to true
   --
   if isMobile() then
      put line 1 of mobileControls() into tControl
      if tControl is not empty then
         mobileControlSet tControl, "visible", false
      end if
   end if
   --
   unlock screen
end lockTouches

# Delete touchTrap graphic to reenable touch input
command unlockTouches
   local tControl
   lock screen
   --
   if there is a grc "touchTrap" then
      delete grc "touchTrap"
   end if
   --
   if isMobile() then
      put line 1 of mobileControls() into tControl
      if tControl is not empty then
         mobileControlSet tControl, "visible", true
      end if
   end if
   --
   unlock screen
end unlockTouches

######################
-- Global Audio Controls

on  __AUDIO
end  __AUDIO

command audioIsRunning  
   # show global speaker when it installed  on a card
   # inside group audioGlobalControl 
   if runningAudioIndicatorVis() = "true" then
      if there is a widget "turnOffAudio"  then 
         show widget "turnOffAudio" 
      end if
   end if
  
end audioIsRunning

--command togglePause pVisible, pState
--   # this in lieu of, or additional to a controller
--   # generic for any context we have a pause and play scenario
--   # hide the grp, or toggle it
--   # take two boolean params: 
--   #    1) true to hide the group the group
--   #    2) true to show that pause icon:  II which means audio is on and playing
--   #         false: shows that the triangle button, saying that the audio is pause
--   #                  and that you can click to resume
--   ntInfo "about to hide/show pause-play"
--   -- if not isMobile() then 
--      if exists (group "pause-play") then
--         set the vis grp "pause-play" to pVisible

--         set the vis of widget "pauseAudio" to pState
--         # which means player is playing, giving user the  option to pause

--         set the vis of widget "playAudio" to not pState
--         # which means player is pause, giving user the re-start playback

--      end if
-- -- end if
--end togglePause


function runningAudioIndicatorVis visBool
   local tList
   if isMobile() then
      put mobileControls() into tList
      if tList contains "audioPlayer" then 
         put "true" into sStopRunningAudio
      else
         put "false" into sStopRunningAudio
      end if
   end if
   return sStopRunningAudio
end runningAudioIndicatorVis

command turnOffAudio 
   # called by the speaker "widget" if it is showing
   if  sStopRunningAudio is "true" then
      
      # the audioPlayer exists, it may be paused.
      # we will start is again.  
      
      mobileControlDo "audioPlayer", "play"
      put "pause" into sStopRunningAudio
      
   else
      # delete it
      
      deleteMobileControl "audioPlayer"
      put "false" into sStopRunningAudio
      if exists (widget "turnOffAudio") then
         hide widget "turnOffAudio"
      end if
   end if
end turnOffAudio

function isAudioPlay pName
   repeat while pName is among the lines of mobileControls()
      mobileControlDelete pName
   end repeat
   
end isAudioPlay

------------------------
on _TIME
end _TIME

--local tMilliseconds, tHours, tMinutes, tSeconds

--function convertTime pMilliseconds
--   put pMilliseconds into tMilliseconds

--   // Hours
--   put tMilliseconds div 3600000 into tHours
--   subtract (tHours * 3600000) from tMilliseconds

--   // Minutes
--   put tMilliseconds div 60000 into tMinutes
--   subtract (tMinutes * 60000) from tMilliseconds

--   // Seconds
--   put tMilliseconds div 1000 into tSeconds
--   subtract (tSeconds * 1000) from tMilliseconds

--   return format("%02s",tHours) & ":" & format("%02s",tMinutes) & ":" & format("%02s",tSeconds)
--end convertTime




--------------------
# from the Gem module: an method for toggling image 
# to let the user see the image, then expand to formatted rect
# then grab and drag
/*

local sImageLoc --jg: script local var handles this now

on mousedown
   insertImageDimensions me
  put the loc of me into sImageLoc
  grab me
end mousedown

on mouseup
   put the loc of me  into tCurrentLoc
   # On mobile the image if very sensitive and moves
   # we need to establish a delta that is acceptable a
   # if within that delta.. then get the next quote
   put (item 1 of sImageLoc) - (item 1 of tCurrentLoc) into tHShift
   put (item 2 of sImageLoc) - (item 2 of tCurrentLoc) into tVShift --jg: account for both horiz & vert shifts
   put abs(tHShift)  < 20 and abs(tVShift)  < 20 into tIsTap --jg: no significant movement either direction
   
   if tIsTap then --jg: tapping now toggles img size      
      switchViewState        
   else
      # if user moved it too far, we reset the location
      --jg: adjust to account for all sides:
      put the width of this cd into tRt
      put the height of this cd into tHt
      
      if (the left of me > 0 or the right of me < tRt) \
            or (the top of me > 0 or the bottom of me < tHt) then
         set the loc of img me to the loc of this cd --jg: only snap to center
      end if
      
      put tCurrentLoc into sImageLoc
   end if
end mouseup

command switchViewState
   switch sViewState
      case 0          # img is full size and quote is showing    
         hide group "quoteControl"
         put 1 into sViewState
         break          
      case 1  # quote is hidden but image is full size
         toggleImgSize (the long id of img "gems-image"),,(the width of this card) 
         put 2 into sViewState
         break
      case  2 # quote is hidden, image is small need to restore complete view
         toggleImgSize (the long id of img "gems-image"),,(the formattedwidth of img "gems-image") 
         show group "quoteControl"
         put 0 into sViewState     
   end switch
end switchViewState
*/

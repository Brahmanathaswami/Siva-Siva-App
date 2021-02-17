script "behavior_Listen"

-----------------------------------------------------
#  behavior_Listen
#
# DESCRIPTION
# this behavior is the /modules/listen/listen.livecode stack script
# It's primary function is to handle high level calls to get play lists
# UI consist of 3 main cards
# listen-collections - shows a catalog of songs built up on a 
# collection.json for: it in be built from a development stack tools
# listen-browse - Later for show in play list
# listen-my-music  # for music that is no loaded
#
# So as not to over load this script the handlers whose scope deals with
# user interaction with a single play list/ indivdtual songs are in a separate behavior 
#
# behavior_ListenSelectPlay
# assigned to the listen-browse card
#
# PARAMS: Main variable sent to this script is a string JSONl list 
#  which is the name/title of all the collections
#
# CHANGES: 2017-06-22 CREATED Brahmanathaswami
-----
global sConfigA, sCardName
local sCollectionA,sCollectionChoice,  sSelectedItemA, sSelectedURL, sDownloadedAudioA
local sCurrentPlayListA,sTargetPlayList,sListType,sPlaylistQueryA,sShareURL,sOnLIne
local sNowPlayingTitle, sNowPlayingArtist,sNowPlayingDetails,sStartTimer,sEndTimer
local sCached, sBrowseHeader, sTimeStamp, sRemoteURL
local sSelectionsA,sLastTarget,sSelectNum, pDataA
local sFastforward

.
   if isMobile() then    
      mobileSetAllowedOrientations "portrait,portrait upside down"
      set the fullscreenmode of this stack to empty
      iphoneSetAudioCategory "playback" 
   end if
   setCardCoords "portrait"
   updateUI
end preOpenStack

on openstack 
   #V2 April 8, 2018
   # 
   # and these are basically playlists like on Spotify, though
   # some might qualify as albums, but we don't have enough to 
   # make a differentiation. So treat all as playlists 
   # we get playlist from the json file, that is attached
   # to the mouse down one the group number
   #
   # first, load the json
   
   local tContainer
   
   set the acceleratedRendering of this stack to true
   
   put url ("binfile:" & path_Modules()& "listen/collection.json") into tContainer
   put JSONToArray(tContainer) into sCollectionA 
   
   portal_SetLastStack "Listen"   
   
   
   # must have net connection, otherwise take to My Audio
end openstack


# return JSON for other handlers as needed

function getCollectionsJson
   return sCollectionA
end getCollectionsJson

on preopencard
   updateUI  
end preopencard     

on openCard
   local tCardName
   local tLabelLoc, tLabelWidth, tBrowseHeader
   
   put the short name of this card into tCardName
   
   switch tCardName
      case "listen-collection"
         # we have turn as updateTime 
         # because it going to fld in card listen-file
         getPlaying false
         
         put empty into  fld "collections-label"
         put empty into  fld "my-audio-label"
         put "Listen" into fld "title-label"
         
         break
         
         
      case "listen-browse"
         getPlaying false
         
         clearSelection
         setAudioListcolors
         put playlist_GetCurrent() into  tBrowseHeader
         replace cr with " " in tBrowseHeader
         put tBrowseHeader into fld "title-label"
         put "Collections" into fld "collections-label"
         put "My Downloads" into fld "my-audio-label"
         break
         
      case "listen-my-audio"
         getPlaying false
         
         put "My Downloads" into fld "title-label"
         put "Collections" into fld "collections-label"
         put empty into fld "my-audio-label"
         put empty into fld "audioList"
         getDownloadedAudio 
         put the result into sDownloadedAudioA
         if (fld "audioList" is empty) then
            dialog_CustomMsg "You have not downloaded any audio"
         end if
         
         break
         
      case "listen-delete-file"
         getPlaying false
         
         put "Delete File" into fld "title-label"
         put empty into fld "collections-label"
         put empty into fld "my-audio-label"
         break
      case "listen-file"
         clearSelection
         
         put "Listen" into fld "title-label"
         put "Collections" into fld "collections-label"
         put "My Downloads" into fld "my-audio-label"
         
         // lib_MobileControls
         setZeroDurationProgress
         
         break
         
      case "listen-search"
         getPlaying false
         
         put "Collections" into fld "collections-label"
         put "My Downloads" into fld "my-audio-label"
         put "Search" into fld "title-label"
         
         break
   end switch
   
   playlist_Reset 
   audioIsRunning
   if the logMessage <> empty then
      copyLogControl
   end if
   
end openCard


on closeCard
   local tCardName
   put the short name of this card into tCardName
   
   switch tCardName
      case "listen-file"
         put "" into fld "audioDetails" 
         put "" into fld "currentTitleLabel" 
         deleteAllMobileControls
         break 
      case "listen-browse"
      case "listen-my-audio"
         clearAudioListColor
         deleteMobileControl "audioList"
         break
      case "listen-delete-file"
         put empty into  fld "FilesOnDisk"
         deleteMobileControl "FilesOnDosk"
         break
   end switch
end closeCard

--------------------

command __Geometry
end __Geometry

on resizeStack x,y,ox,oy
   lock screen
   setCardCoords "portrait"
   updateUI
   unlock screen
end resizeStack

command updateUI
   
   local tHeader, tFooter, tAudioGlobalControl
   local tSearchFilter, tPausePlay, tAudioPlayer
   local tTitleLabel, tCollectionsLabel, tMyAudioLabel
   local tCardRect, tAllCollections, tAudioList, tAudioDetailsGrc, tAudioDetailsFld
   local tFilterAudio, tCurrentTitle, tDownloadSelection, tNoInformation
   local tRect, tControl, tRight,tAudioRect
   
   
   put the long id of grp "footerNavigation" into tFooter
   send "UpdateUI" to tFooter
   
   put the long id of fld "title-label" into tTitleLabel
   put the long id of fld "collections-label" into tCollectionsLabel
   put the long id of fld "my-audio-label" into tMyAudioLabel 
   
   topCenterMe tTitleLabel, 5
   topLeftMe tCollectionsLabel, 10, 30
   topRightMe tMyAudioLabel, 10, 30
   
   switch (the short name of this card)
      
      case "listen-collection"
         put the long id of grp "all-collections" into tAllCollections
         set the top of tAllCollections to the bottom of tTitleLabel + 5
         set the rect of tAllCollections to (4, the bottom of tTitleLabel + 5, \
               CardWidth() - 3, the top of tFooter)
         put the long id of grp "search-filter" into tSearchFilter
         topRightMe tSearchFilter, 0, 0
         
         
         put CardWidth() - 4 into tRight
         repeat with i = 1 to 7 
            put the long id of grp ("playlist" & i) into tControl
            put the rect of tControl into tRect
            put tRight into item 3 of tRect
            set the rect of tControl to tRect
         end repeat
         
         put the long id of grp "audioGlobalControl" into tAudioGlobalControl
         topLeftMe tAudioGlobalControl, 10,0
         
         break
         
      case "listen-browse"
         put the long id of fld "audioList" into tAudioList
         set the rect of tAudioList to (10, the bottom of tCollectionsLabel + 18, \
               CardWidth() - 7, the top of tFooter - 17)
         centerMe tAudioList, 60,70
         
         put the long id of grp "search-filter" into tSearchFilter
         topRightMe tSearchFilter, 0, 0
         
         put the long id of grp "audioGlobalControl" into tAudioGlobalControl
         topLeftMe tAudioGlobalControl, 10,0
         
         break
      case "listen-my-audio"
         
         
         local tDeleteOn
         put the long id of grp "displayDelete" into tDeleteOn
         BottomRightMe tDeleteOn, 0,50
         
         break
         
      case "listen-delete-file"
         local tDisplayFilesSizes
         put the long id of grp "displayFilesSizes" into tDisplayFilesSizes
         set the width of tDisplayFilesSizes to  CardWidth()
         topLeftMe tDisplayFilesSizes, -3,30
         break
         
      case "listen-file"
         
         put the long id of player "audioPlayer" into tAudioPlayer
         topLeftMe tAudioPlayer, 20,-1111
         
         put the long id of graphic "audioRect" into tAudioRect
         topLeftMe tAudioRect, 20,-1111
         
         put the long id of fld "currentTitleLabel" into tCurrentTitle
         set the width of tCurrentTitle to  (CardWidth() - 35 )
         topLeftMe tCurrentTitle, 20,80
         
         put the long id of grc "audioDetailsBkg" into tAudioDetailsGrc
         set the width of tAudioDetailsGrc to  (CardWidth() - 20 )
         topLeftMe tAudioDetailsGrc, 10 ,150
         
         put the long id of fld "audioDetails" into tAudioDetailsFld
         set the width of tAudioDetailsFld to  (CardWidth() -30 )
         topLeftMe tAudioDetailsFld, 15,160
         
         put the long id of grp "noInformation" into tnoInformation
         centerMe tNoInformation, -100
         
         put the long id of grp "downloadSelection" into tDownloadSelection
         topRightMe tDownloadSelection, 0, 155
         
         put the long id of grp "pause-play" into tPausePlay
         bottomCenterMe tPausePlay, 60
         
         break
         
      case "listen-search"
         put the long id of grp "filterAudio" into tFilterAudio
         topLeftMe tFilterAudio, 30 ,80
         break
         
         
   end switch
   
end updateUI


--------------------------
on __GetACollection
end __GetACollection


command selectPlaylist pSelection
   local tPlayTarget,tColl,tPlay
   
   # use has  made choice from card 
   
   # get extract JSON from sCollectionA 
   # which is an array that contain all collections
   # it include the data we need to the title and path to img file.
   # but this pre-built for production
   # you can rebuild the UI from the SivaSivaDev Tool.livecode stacks
   
   put the short name of pSelection into tPlayTarget
   
   # first - card navigition
   
   if tPlaytarget contains "my-audio" then
      go to card "listen-my-audio"
      exit selectPlayList
   end if
   
   # other wise we are select a collection:
   
   if not (tPlayTarget contains "-playlist-") then
      exit to top
   else
      # we should put this a common library, but the are too many sceneros per moldule
      offLineGoMyAudio
   end if
   
   set the itemDelimiter to "-"
   put item 1 of tPlayTarget into tColl
   put item 2 of tPlayTarget into tPlay
   
   # Link each separate process to a 
   # specific handler
   playList_FetchData tColl,tPlay
end selectPlaylist

-----------------------------------------------------
# playlist_SetGetCurrent
# DESCRIPTION:  the primary known variable is a string 
# which taken from the json list on mouseup (see selectPlayList above
#
# PARAMS: pass the playlist string, which should also serve as it's title 
# See the JSON for more detail on what is on the aray
# see /models/model_SivaSiva/model_SivaSiva.json 
# CHANGES: Created 2017-06-22 Brahmanathaswami
------------------------------------------------------

# more need to set the playListLater
# and other playListClass
# what we have a setter/getter here
on playlist_GetClass
   return sCurrentPlayListA["playlistClass"]
end playlist_GetClass

on playlist_SetCurrent pList  
   put pList into sTargetPlayList
end playlist_SetCurrent

function playlist_GetCurrent
   return sCurrentPlayListA["playListTitle"]
end playlist_GetCurrent

# we may need to fetch files later
# so another function returns the key listen list to build everything
# includes the metadata from the date base, the lyrics and the URL
# use this to fetch data later for card behavior

function playlist_GetRecords  
   if sCurrentPlayListA["audioFiles"] is empty then     
      --       if isMobile() is false then
      --          put "No records Fetched!"
      --       end if   
   else
      return sCurrentPlaylistA
   end if
end playlist_GetRecords

-----------------------------------------------------------------------
# playList_FetchData
# DESCRIPTION: 
-- # all the dataquery data it in to json file under "data-query"
-- # we have three classes of lists based on data storage/CMS
-- # each requires a different query
-- # 1. Remote list: send JSON to server we send JSON for remote list
-- # 2.  Audiobook: build a path string and download index. json for audio books
-- # 3. query the local dbase for already cached metadata in the Local Jnanam dbase
-- # These are merged into a sPlaylistQueryA   array the we use pass date to the 
-- # dbase handlers
-- # we need max six criteria to search our metadata, not all playlists require all strings, 
-- # but our query array will still have all these keys; use elements as needed
-- # we will model that array into a json string or dbase query later
-- # media_type, author, artist, record-type [latest | cached | audiobook], num-of-records,year, file_id
-- # see /system/applications/ha/controllers/API3.lc  on the server for details on the remote call
-- #  structure of remote query, for reference:
-- # Note we use "recordType" here instead of "playlistClass" because the API  pon the server is agnostic about the type
-- # of records we are fetching... it could be artwork quotes, books anything... not only audio playLists.
-- #   put "{'data': {'media_type': 'inspiredtalk','author':'Bodhinatha'},'recordType':'latest','recordCount':'30'}" into tJSON
-- #
-- # We keep all the data in json file now.

-- # Audio books are simpler, all we need is a path to the remote server directory, fetch the audio JSON file therein.
-- # 
-- # Sorting differs by playlistClass: latest | descending by date, audiobook | per json index, cached | alpha by title or file_ID
-- # usually trigger on arrival to this stack-card

-- # PARAMS: pass numeric collection and the playlist from /modules/listen/collection.json file
-- # CHANGES: 2018-04-09 - BR Created

# secondary params"
#  from json file: this is a sample. Not all playlists require all params
--          put "playListClass" into sPlaylistQueryA["playlistClass"]  # gets metadata from remote server
--          put "inspiredtalk" into sPlaylistQueryA["media_type"]         
--          put "Satguru Bodhinatha Veylanswami" into sPlaylistQueryA["author"]
--          put "latest" into sPlaylistQueryA["recordType"]        
--          put 30 into sPlaylistQueryA["recordCount"] 
--          put "master-course" into sPlaylistQueryA["file_id"]
--          put "1970" into sPlaylistQueryA["date_created"]
--          put "YES" into sPlaylistQueryA["approved_for_public"]

-----------------------------------------------------------------------

on playList_FetchData tColl,tPlay,pFilterListQueryA,pBrowseHeader
   local tPlaylistClass, tRecordTypeCount, tDbaseColumns
   local  queryData, pJSON, tRecords, tSearchA, tFileID, tTocURL, tBookToc
   
   
   --showBusyIndicator true,"Loading Collection"
   put empty into fld "audioList" of card "listen-browse" of stack "listen"
   
   --  dispatch "cleanUpGui" to card "listen-browse"      
   
   put empty into sPlaylistQueryA 
   
   # if pFilterListQueryA is empty, it means we are coming in
   # the Search and Filter filter screen
   # if not, we coming of the main collection screen
   
   if pFilterListQueryA = empty then 
      
      put sCollectionA[tColl]["playlists"][tPlay]["playListClass"] into tPlaylistClass 
      put sCollectionA[tColl]["playlists"][tPlay]["playListTitle"]  into  sCurrentPlayListA["playListTitle"]
      
      
      put tPlaylistClass into sPlayListQueryA["PlaylistClass"]
      
      # decides if cached on device, or from server and audio book
      # this param is used here... not sent to the database. 
      # but use to determine how the query show go: the server, audio book, in the local mySQL jnanam (local dbase_
      # get type of playlistL audio book, etc
      
      # first we need action the array from the json able 
      # everything in needs to create a query
      
      put "recordType,recordCount" into tRecordTypeCount
      
      # remember: tColl and tPlay are drawn from the mouseups
      # see the nomenclature for what the mouseup calls for
      # in the IDE project browser
      
      repeat for each item RT in tRecordTypeCount
         if (sCollectionA[tColl]["playlists"][tPlay][RT] is not empty) then 
            put  sCollectionA[tColl]["playlists"][tPlay][RT] into sPlayListQueryA[RT]
         end if 
      end repeat
      # you must declare all columns you are searching in the data base.
      put "media_type,file_id,approved_for_public,author,genre,deity,tags" into tDbaseColumns
      
      repeat for each item DC in tDbaseColumns
         if ( sCollectionA[tColl]["playlists"][tPlay]["data_query"][DC] is not empty) then 
            put sCollectionA[tColl]["playlists"][tPlay]["data_query"][DC] into sPlayListQueryA[DC]
         end if
      end repeat
      put sCurrentPlayListA["playListTitle"] into sBrowseHeader
      replace cr with " " in sBrowseHeader
   else
      # use the queries from the Search Screen
      
      put "cached" into tPlayListClass
      put pFilterListQueryA into sPlaylistQueryA
      # the query is sent a param for the header
      put pBrowseHeader into sBrowseHeader
      
   end if
   
   
   # we get records now, from server, or local jnanam.
   # we get each one based the on class, on where they come from
   
   switch tPlaylistClass
      case "latest" 
         # we do a JSON Call  to the server
         # use the a function in lib_SivaSivaMedia to model this array sPlaylistQueryA into the pJSON
         # we need because we can then use for different play lists on demand..          
         # the sPlayListQueryA  has the values needed for the API... 
         # API requires taht we construct data: 
         # set the query;  recordtype/Count  
         # set up how many/limit the number of records to return which are 
         # different function in the API, SQL ; Note look at the API2.livecode ; getItemRecords handler
         # e.g. required format need single quotes to go thru the API
         #  "{'data': {'media_type': 'inspiredtalk','author':'Satguru Bodhinatha Veylanswami'},'recordType':'latest','recordCount':'30'}"
         #  API is agnostic about query strings... if you just pass media type "song" with author or artist you get all the latest songs.
         #  just sets the WHERE clause in the query with whatever you request. 
         # Then sorts on date sends back the request number of records.
         
         --breakpoint
         showBusyIndicator true,"Loading Collection"
         
         put "Contacting server... " into fld "audioList" of card "listen-browse"
         
         # Set up the WHERE clause
         put sPlayListQueryA["media_type"] into queryData["data"]["media_type"]
         put sPlayListQueryA["author"] into queryData["data"]["author"] 
         put sPlayListQueryA["recordType"] into queryData["recordType"]
         put sPlayListQueryA["recordCount"] into queryData["recordcount"]
         
         put arrayToJson(queryData) into pJSON # from server
         
         put the ticks into sStartTimer
         set the httpheaders to "content-type: application/json"
         
         ## TO DO:  NEEDED: TIME OUT REQUIREMENT!
         POST pJSON to URL "http://dev.himalayanacademy.com/api3/getItemRecordsAndFormats/json"
         
         # we need to check of back character in the dbase which breaks JSONtoARRAY
         # typically there CR in columns that shouldn't be there.
         --put it into  url ("file:///Users/brahmanathaswami/Desktop/checkJson.txt" ); exit to top
         
         if the result is not empty then 
            # we did not get anything. Turn  off loader, inform the users
            showBusyIndicator false
            put "Check your network connection." into  fld "audioList" of card "listen-browse" of stack "listen"
            dialog_CustomMsg "Offline or Low Bandwidth"
            portal_Link "Listen"
            exit to top
         else 
            put it into tRecords
            put jsonToArray(tRecords) into sCurrentPlayListA["audioFiles"]
         end if
         # add list type for other operations
         put tPlaylistClass into sCurrentPlayListA["playlistClass"]  #now we have our local array
         break
      case "cached"
         put sPlaylistQueryA into tSearchA
         delete variable tSearchA["playlistClass"]  # don't pass this to the query
         put fetchMediaItems(tSearchA) into sCurrentPlayListA["audioFiles"]
         put tPlaylistClass into sCurrentPlayListA["playlistClass"] 
         break
      case "audiobook"
         showBusyIndicator true,"Loading Collection"
         put "Contacting server... " into fld "audioList" of card "listen-browse"
         # a simple call to the server to get the TOC
         # can chose different books base on file_id
         put sPlaylistQueryA["file_id"] into tFileID
         
         # CMS is straightforward, path is consistent, no magic code required
         
         ## TO DO:  NEEDED: TIME OUT REQUIREMENT!
         put "https://www.himalayanacademy.com/media/audio/books/" & tfileID & "/audiobook.json"   into tTocURL
         put URL tTocURL into tBookToc
         if the result is not empty then 
            put "Check your network connection." into  fld "audioList" of card "listen-browse" of stack "listen"
            dialog_CustomMsg "Offline or Low Bandwidth"
            showBusyIndicator false
            exit to top
         else 
            put jsonToArray(tBookToc) into sCurrentPlayListA["audioFiles"]
         end if
         # this should come from the local dBase,
         # but as of June 29, the local dBase is obsolete
         
         # so we have to fetch info from the server 
         # this does not include a data base query other than the file id
         # which get the URL and pull to TOC.json for the audio book.
         
         put "{'data': {'media_type': 'audio/book','file_id':'" & tFileID&"'}}" into pJSON 
         set the httpheaders to "content-type: application/json"
         replace "'" with quote in pJSON
         
         ## TO DO:  NEEDED: TIME OUT REQUIREMENT!
         POST pJSON to URL "http://dev.himalayanacademy.com/api3/getItemRecordsAndFormats/json"         
         if the result is not empty then 
            put "Check your network Connections" into  fld "audioList" of card "listen-browse" of stack "listen"
            dialog_CustomMsg "Offline or Low Bandwidth"
            showBusyIndicator false
            exit to top
         else 
            put it into tRecords 
            # But the model is different for audio books. We now have metadata for the whole book
            # this is not a series of records for individual files
            # We need this later:
            put jsonToArray (tRecords) into sCurrentPlayListA["audioBookMetadata"]
            put tFileID into sCurrentPlayListA["audioBookMetadata"]["file_id"]
         end if
         
         break      
   end switch
   
   -- put (the ticks - sStartTimer)  early tests: as long as 3 minutes to get data from the server...
   # we have the data for our records in the array now.
   # need know two things from the beginning
   put tPlaylistClass into sCurrentPlaylistA["playlistClass"]
   
   if sCurrentPlayListA["audioFiles"] is empty then 
      doAnswer "No records for that search. Try again","Cancel"
      showBusyIndicator false
      put empty into fld "audioList" of card "listen-browse" of stack "listen"
      exit to top
   end if
   
   
   playlist_Instantiate sTargetPlayList
   
end playList_FetchData


-----------------------------------------------------------------------
# playlist_Instantiate
#
# DESCRIPTION: 
# card 1 of this stack must always be card "listen-playlist" 
# as such, object references here refer to controls on that card
# this is where we fill in the play list 
#
# PARAMS: everything is taken from the sCurrentPlaylistA array
#
# CHANGES: 2017-06-22 created Brahmanathswami
-----------------------------------------------------------------------


on  playlist_Instantiate sTargetPlayList    
   Local tKeys, tTitles, pData
   
   # we have data from local or the server: 
   # turn off loader...
   
   showBusyIndicator false
   
   # using: model_SivaSiva, which has functions to get json info we need:
   
   switch sPlaylistQueryA["playlistClass"] 
      case "audiobook"
         put the keys of sCurrentPlayListA["audioFiles"]["toc"] into tKeys
         sort lines of tKeys ascending numeric
         repeat for each line x in tKeys 
            put sCurrentPlayListA["audioFiles"]["toc"][x]["label"] & cr & cr after tTitles
            put sCurrentPlayListA["audioFiles"]["toc"][x]["label"] into sCurrentPlayListA["audioFiles"] [x]["Title"] 
         end repeat
         break
      default
         put the keys of sCurrentPlayListA["audioFiles"] into tKeys
         sort lines of tKeys ascending numeric
         repeat for each line x in tKeys
            put sCurrentPlayListA["audioFiles"] [x]["Title"] after tTitles
            
            if sCurrentPlayListA["audioFiles"] [x]["media_type"] ="audio/song" then
               put cr &sCurrentPlayListA["audioFiles"] [x]["artists"] after tTitles
            else
               put cr after tTitles
            end if
            put cr after tTitles
            
         end repeat
   end switch
   put empty into sCached
   
   getPlayListURLs tKeys
   
   --markCachedItems tKeys
   
   
   
   # Now we switch cards, 
   
   go to card "listen-browse"
   put "listen-browse" into sCardName
   show fld "collections-label"
   show fld "my-audio-label"
   
   hide fld "audioList"
   put tTitles into fld "audioList"  
   
   typesetAudioList
   
   repeat for each line x in sCached
      set the foregroundcolor line (x*2-1) of fld "audioList" to 245,200,190
   end repeat
   replace cr with " " in sBrowseHeader
   put sBrowseHeader into fld "title-label" of card "listen-browse"
   
   show fld "audioList"
   
   
   # here is where we have to check to see if any files are stored locally or not
   
   
   if the formattedHeight fld "audioList" > the height of fld "AudioList" then
      send "CreateScroller audioList" to fld "audioList" of card "listen-browse"
   end if
   put  sTargetPlayList into pData["audio_playlist"]
   tracking_RecordActivity "Listen", "navigation/playlist", pData
end playlist_Instantiate


------------- 
on __GoCardListenFile
end __GoCardListenFile

command setSelectNumber pNum
   put pNum into sSelectNum
end setSelectNumber

on playlist_Reset
   put playlist_GetRecords() into  sCurrentPlayListA
end playlist_Reset

command fetchSingleMetadata pItemID
   local tSearchA,tTargetRecordA
   put pItemID  into tSearchA["item_id"]
   put  fetchMediaItems(tSearchA) into tTargetRecordA # returns only 1 record
   put tTargetRecordA[1] into sSelectedItemA
   metadata_SetRecord sSelectedItemA
   get getSongLyrics(pItemID)    
   put getMediaMeta() into it
end fetchSingleMetadata

function checkPlayList
   return the keys of  sCurrentPlayListA
end checkPlayList



# we need to determine when that card is open that the user
# cannot have made a selection. Since the local var persists
# we have put empty into something
on clearSelection
   put empty into sSelectedItemA
end clearSelection

# this is for downloads. It gets the audio from 

on direct_Play sSelectNum,sCardName
   local pTitle,
   put sDownloadedAudioA[sSelectNum]["localURL"] into sRemoteURL
   put sDownloadedAudioA[sSelectNum]["metadata"]["1"]["title"]  into pTitle
   put pTitle into fld "currentTitleLabel" 
   startPlayer sRemoteURL,pTitle,sCardName,sSelectNum
   # skip the card name Parameter in this context.
   showBusyIndicator false
end direct_Play
-----------------------------------------------
--# Select, Play, Listen, Stop UI interactions
-----------------------------------------------
--#
--# DESCRIPTION: Only two jobs here
--#     - show the title
--#     - set the URL for the player
--#    -  do the necessary for the mobile player
--#     - start the player
--# we should move common handlers off to a global  lib (may have them already)
--# because we are going to be doing audio all over the app,
--# not just here.
--# 
--# PARAMS: The selected line get the array element
--# and away we go
--#
--# CHANGES: 2020-02-28, BR: explicit vars entered, moving up msg path to behavior_listen
--# CHANGES: 2017-06-22, BR: CREATED 
-----------------------------------------------

on select_Play  sSelectNum, pitemID
   # if item id is empty then defaults to the click line number
   
   local tSearchA, tTargetRecordA, tLocalStatus, pMsg, answerURLunavailable, pTrackdata
   local pTitle,audioFiles
   # if we are coming from a click on the card list then the pItemID will be empty
   # but we may be dropping in from the journal or another type of list that
   # simple passes the item_id for the record.. and there is no pSelectedLIne
   
   showBusyIndicator true,"Loading Audio"
   
   if pItemID is empty then # search from the click line
      put getItemURL(sSelectNum) into sRemoteURL
      Put "Connecting..." into fld "currentTitleLabel"
      --   playlist_Reset # needed during dev because we often lose the sSelectedItemA value
      put sCurrentPlayListA["audioFiles"][sSelectNum  ] into sSelectedItemA   
      metadata_SetRecord sSelectedItemA
      put sCurrentPlayListA["audioFiles"][sSelectNum]["myURL"]["filename"] into sSelectedURL
      log sSelectedURL
      log examineArray(sSelectedItemA)
   else
      put pitemID into tSearchA["item_id"]
      put  fetchMediaItems(tSearchA) into tTargetRecordA # returns only 1 record
      put tTargetRecordA[1] into sSelectedItemA
      log examineArray(sSelectedItemA)
      
      metadata_SetRecord sSelectedItemA
      put getMediaURL() into sSelectedURL
      log sSelectedURL
      put path_isFileOnDisk(sSelectedURL) into tLocalStatus
   end if
   
   
   if checkURLAvailable(sRemoteURL) is "false" then 
      clearPlayer
      showBusyIndicator false
      put "Sound file unavailable. Are you connected to the internet? If so, please send feedback with the name song and artist so that we can fix it." into pMsg
      doAnswer pMsg,"OK", answerURLunavailable
      exit to top
   end if
   
   
   # Lyrics fetch is a separate function, see lib_SivaSiva Media
   
   get getSongLyrics(sSelectedItemA["item_id"])
   
   if sRemoteURL = "" then -- jg: don't continue
      put "Media not found" into fld "audioDetails"
      set the height of fld "audioDetails" to the formattedHeight of fld "audioDetails"
      showBusyIndicator false
      exit to top
   end if
   
   startPlayer sRemoteURL, sSelectedItemA["title"],,sSelectNum
   # skip the card name Parameter in this context.
   showBusyIndicator false
   put "audiotitle="& sSelectedItemA["title"]   into pTrackdata["contentTarget"]
   tracking_RecordActivity "Surprise", "navigation/playaudio", pTrackdata
end select_Play


# V2 Link to transcript

command select_ShowDetails  pSelection, pRecord
   deleteMobileControl "audioList"
   
   switch
      --      case (fld "audioList" is empty)
      --         Put "You have not downloaded any audio yet." into  fld "audioDetails" 
      
      --         break
      
      # or its from a downloaded file in My Audio
      # this case must come for one after it.
      case (pSelection="downloaded")
         put  getMediaItemMetadata(pRecord) into  fld "audioDetails"   
         break   
         
      case (sCurrentPlayListA["playlistClass"] = "latest")  OR (sCurrentPlayListA["playlistClass"] ="cached")
         put getMediaItemMetadata() into fld "audioDetails"
         break
         
         # its an audio book, lib media doesn't know anything, we have to pass the record here   
      case sCurrentPlayListA["playlistClass"]= "audioBook"
         put "Transcripts for audio books are available here." &cr & cr &  "Read the original book." into fld "audioDetails"
         break        
         
         
   end switch
   set the textstyle of line 1 of fld "audioDetails" to "italic"
   set the textstyle of line 2 of fld "audioDetails" to "italic"
   set the textstyle of line 3 of fld "audioDetails" to "italic"
   
   show fld "audioDetails" with visual "effect wipe" up very fast
   send "CreateScroller audioDetails" to fld "audioDetails"
end select_ShowDetails

command typeSetAudioList
   local tX
   put 0 into tX
   repeat with x =1 to the number lines  in fld "audioList"
      add 1 to tX
      if (tX mod 2) = 0 then
         set the leftIndent of line x of fld "audioList" to 10
         if  line x of fld "audioList" <> empty then
            set the spaceBelow of line x of fld "audioList" to 10
         end if   
         set the textSize of line x of fld "audioList" to 15
      else
         set the textSize of line x of fld "audioList" to 17
      end if
   end repeat 
   
end typeSetAudioList

command getPlayListURLs pKeys
   repeat for each line x in pKeys
      put getItemURL(x) into sCurrentPlayListA["audioFiles"][x]["myURL"]
   end repeat   
end getPlayListURLs

function getItemURL pRecordNum
   local tURL
   # send of to lib_SivaSivaMedia, which knows all about our media CMS
   # but Audio books are completely different CMS: they have no item records for their audio files
   
   if ( sCurrentPlayListA["playlistClass"] = "latest")  OR ( sCurrentPlayListA["playlistClass"] ="cached") then
      # everything happens via Jnanam table structure record array
      put  sCurrentPlayListA["audioFiles"][pRecordNum] into sSelectedItemA
      metadata_SetRecord sSelectedItemA
      put getMediaURL (sSelectedItemA["item_id"]) into tURL
      
      if char -1 of tURL = "/" then
         put  sCurrentPlayListA["audioFiles"][pRecordNum]["filename"]  after tURL
         put tURL  into sSelectedURL
      end if       
   else
      # its an audio book
      put getMediaURL("audioBook") into tURL
      put  sCurrentPlayListA["audioBookMetadata"]["file_id"] & "/" after tURL
      put  sCurrentPlayListA["audioFiles"]["toc"][pRecordNum]["file"] after tURL
   end if
   return tURL
end getItemURL

command getDownloadedAudio
   local tList, tSearchA, tURL,pFolder,tTitle,tTitles
   
   put empty into sDownloadedAudioA
   # do directory walk of the media/audio folder
   
   put (path_Documents() & "media/audio") into pFolder
   put listFilesWithPaths(pFolder, "true")  into tList
   repeat with x = 1 to (the number of lines of  tList)
      put line x of tList into tURL
      put tURL into sDownloadedAudioA[x]["localURL"]
      set the itemdel to "/"
      put item -2 of tURL into sDownloadedAudioA[x]["file_id"]
      repeat for each  line tKey in the keys of sDownloadedAudioA
         put sDownloadedAudioA[tKey]["file_id"]   into tSearchA["file_id"]
         put  fetchMediaItems(tSearchA) into  sDownloadedAudioA[tKey][metadata]
      end repeat
   end repeat
   
   # first look in the dates base
   
   repeat with x = 1 to (the number lines of keys of sDownloadedAudioA)
      if  sDownloadedAudioA[x]["file_id"] contains "-audiobook" then
         # get in from file names
         set the itemdel to "/"
         put  item -1 of sDownloadedAudioA[x]["localURL"] into tTitle
         put normalizeFileToTitle(tTitle) after tTitles
         put cr & cr after tTitles
         next repeat
      end if
      put sDownloadedAudioA[x][metadata][1]["title"] into tTitle
      
      if tTitle is empty then
         put sDownloadedAudioA[x]["file_id"] into tTitle
         put normalizeFileToTitle(tTitle) after tTitles
      else
         put tTitle after tTitles
      end if
      put cr after tTitles
      if sDownloadedAudioA[x][metadata][1]["media_type"] ="audio/song" then
         put sDownloadedAudioA[x][metadata][1]["artists"] after tTitles
      end if
      put cr after tTitles
      
   end repeat
   
   # getting the final cr out
   delete char -1 of  tTitles
   
   loadTitles tTitles
   return sDownloadedAudioA
   
end getDownloadedAudio

command downloadSelection sSelectNum, pTarget
   setSelectNumber sSelectNum
   put the long id of pTarget into sLastTarget 
   # NOTE: we need this because the down stack will need to come back where
   # it and we pass this to pRequestBy
   if sSelectNum <> empty then  # we have a selection
      doAnswer "Download this audio file?", "Download,Cancel","downloadAffirmed"
   else
      put "Pick a Title to Download It." into fld "currentTitleLabel"
   end if
end downloadSelection

command downloadAffirmed   
   local pTitle
   if  sCurrentPlayListA["playListClass"] ="audiobook" then
      put  sCurrentPlayListA["audioFiles"]["toc"][sSelectNum]["label"] into pTitle
   else
      put   sCurrentPlayListA["audioFiles"][sSelectNum]["title"]  into pTitle
   end if
   show grp "downloadControls"
   wait 100 milliseconds with messages
   dispatch "downloadURL"  to group "downloadControls" with  pTitle,sRemoteURL,sSelectNum,sLastTarget
   # sLastTarget becomes params pRequest by to the download stack
end downloadAffirmed

command loadtitles pTitles   
   local pLineCount
   hide fld "audioList"
   put pTitles into fld "audioList"
   typeSetAudioList
   show fld "audioList"
   put the number of lines of pTitles into pLineCount
end loadtitles

command markCachedItems pKeys
   local pURL, tLocalStatus, tIsCached
   repeat for each line x in pKeys
      # this as good a place as any to check for the existence of files  
      # and get the URL for every one in the play list... so we only do this once.
      put getItemURL(x) into pURL
      # Check and create folders here
      put path_isFileOnDisk(pURL) into tLocalStatus
      put item 1 of tLocalStatus into tIsCached
      put tIsCached into sCurrentPlayListA["audioFiles"][x]["cached"]
      if tIsCached then  # need to colored cached files on theUI
         # store line numbers
         put x & cr after sCached
         put item 2 of tLocalStatus into  sCurrentPlayListA["audioFiles"][x]["myURL"]
      else
         put pURL into sCurrentPlayListA["audioFiles"][x]["myURL"]
      end if
   end repeat
end markCachedItems

command addJournalEntry -- save a bookmark to database
   local  tTitle, tURL, tNoSavingCards,tMsg, tCard,tHoursMinutes,tCurrentTime,x
   
   put the short name of this card into tCard
   
   put "listen-collection,listen-browse,listen-my-audio,listen-delete-file,listen-search " into tNoSavingCards
   
   if the short name of this card is among the items of tNoSavingCards then
      put "Nothing to save to Journal. Go an audio file." into tMsg
      exit addJournalEntry
   end if
   
   put getJournalData() into pDataA   
   
   put getCurrentTime() into sTimeStamp
   put getHoursMinsTime() into tHoursMinutes
   put sTimeStamp into pDataA["timeStamp"]
   put tHoursMinutes into pDataA["hoursMinutes"]
   
   
   put pDataA["title"] into tTitle
   put ", " & pDataA["hoursMinutes"] after tTitle
   
   Journal_RecordEntry "listen",tTitle,pDataA 
   
end addJournalEntry


on journalResume  pDataA, pEntryA
   local tCard
   
   lock screen
   
   
   put pDataA["card"] into tCard
   
   go to card tCard
   
   if tCard= "listen-file"  then
      # using has want to listen you one unique audio file
      # we have set to the card up....  in the the future
      # we can integrate is this listen behavior .
      
    playSingle pDataA
      
   end if
   
end journalResume


command playSingle pDataA
   local tSearchA,x,tItem_id
   local tURL,tSelectedItemA
   
   
   put empty into tSelectedItemA
   
   put pDataA["url"] into tURL
   put pDataA["item_id"] into tItem_id
   put pDataA["timeStamp"]  into sTimeStamp
   
   unlock screen
   
   startPlayer tURL,pDataA["title"]
   
   showBusyIndicator false
   if  "audio/book" is not in tURL then # no display details
      select_ShowDetails "downloaded"
   end if 
   
end playSingle

 
on __ListenUtilities
end __ListenUtilities

command setAudioListColors tLineNum,pColor
   set the backgroundcolor of line tLineNum of fld "audioList" to pColor
end setAudioListColors

command clearAudioListColor
   set the backgroundcolor of line 1 to -1 of fld "audioList" to empty
end clearAudioListColor

command __UXHandlers
end __UXHandlers

local sPlaying

command startPlayer  pURL,pTitle,sCardName,sSelectNum
   local tRect, pAudioRect, localURL,  pItemID,tLineNum, tLineValue
   
   put the rect of graphic "audioRect" into pAudioRect
   
   put pTitle into tLineValue
   
   if pTitle is empty then
      put sSelectNum*2 into tLineNum
      if (tLineNum mod 2) = 0 then
         subtract 1 from tLineNum
      end if
      put line tLineNum of fld "theSelectNum" into tLineValue
   end if
   
   put tLineValue into pDataA["title"]
   
   
   if sCardName = "listen-my-audio" then
      put sSelectNum into sSelectNum
      # we have to deal with downloaded files, and the local path/url
      # to get them in to journal....
      put sDownloadedAudioA[sSelectNum]["localURL"] into pURL
      put sDownloadedAudioA[sSelectNum][metadata][1]["item_id"] into pItemID
      put pItemID into pDataA["item_id"]
      put pTitle  into pDataA["title"]
      fetchSingleMetadata pItemID
   else
      # assume we have data 
      showBusyIndicator true, "Loading"
      put sSelectedItemA["item_id"] into pItemID
   end if
   
   put "listen-file" into pDataA["card"]  
   put pURL into pDataA["url"]
   put pItemID into pDataA["item_id"]
   
   # we used a getter/setter in lib_SivaSiva
   # because the timing is different than addJournalEntry          
   setJournalData pDataA
   
   if isMobile() then
      createMobileAudioPlayer pURL, "audioPlayer",pAudioRect
   else
      set the filename of player "audioPlayer" to pURL
   end if
   
   
   # 2019-10-23 BR we are not showing controller  because of iOS 13.0.3
   # instead we are using the icons of grp "pause-pay"
   
   if sTimeStamp is empty then
      put 0 into sTimeStamp
   end if
   --
   if not isMobile() then
      start player "audioPlayer"
      set the currenttime player "audioPlayer" to sTimeStamp
      --
      getPlaying true
      --
      get runningAudioIndicatorVis("true")
   else
      setMobileAudioPlayer "audioPlayer", "currentTime", sTimeStamp
   end if
   
   put  pTitle into fld "currentTitleLabel"
   send "updateTimer" -- in 100 milliseconds
   set the iconPresetName of widget "PlayPause" to "pause"
   
end startPlayer

on stopPlayer
   if not isMobile() then
      stop player "audioPlayer"
      set the filename of player "audioPlayer"  to empty
      put false into sPlaying
      
   else 
      setMobileAudioPlayer "audioPlayer", false
      deleteMobileControl "audioPlayer"
   end if
   
   set the iconPresetName of widget "PlayPause" to "pause"
 
   updateTimer sPlaying
   
end stopPlayer


on pausePlayer sTimeStamp
   if not isMobile() then
      set the paused of  player "audioPlayer" to "true"
      put false into sPlaying
   else  
      setMobileAudioPlayer "audioPlayer", "pause",sTimeStamp
   end if
   
   # we have to record the timestamp of a journal
   put sTimeStamp into pDataA["timeStamp"]
   setJournalData pDataA
   set the iconPresetName of widget "PlayPause" to "play"
   
end pausePlayer

on playPausedAudio sTimeStamp
   
   put sTimeStamp into pDataA["timeStamp"]
   setJournalData pDataA
   
   if not isMobile() then
      set the currenttime  of player "audioPlayer" to sTimeStamp
      start player "audioPlayer"
      put true into sPlaying
   else 
      setMobileAudioPlayer "audioPlayer", "play", sTimeStamp
      send "updateTimer" to stack "lib_MobileControls" in 20 milliseconds
   end if
   set the iconPresetName of widget "PlayPause" to "pause"
end playPausedAudio

on clearPlayer
  showPlayer false, "audioPlayer" 
end clearPlayer

command offLineGoMyAudio
   
   local pFolder, tList
   if not connectivity_PingServer() then
      put (path_Documents() & "media/audio") into pFolder
      put listFilesWithPaths(pFolder, "true")  into tList
      if tList is empty then
         dialog_CustomMsg "You have not downloaded any offline audio yet. Network required."
         go to card "listen-collection"
         exit to top
      else
         dialog_CustomMsg "Connection Required. You Can Play Off Line. Going to My Audio"
         go to card "listen-my-audio" 
      end if
      exit to top
   end if
end offLineGoMyAudio

on closeStack
   portal_SetLastStack "Listen"
end closeStack



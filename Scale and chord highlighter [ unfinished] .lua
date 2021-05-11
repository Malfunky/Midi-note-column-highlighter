-- changelog 
-- 5/11 - 2011 - Support for 13,9,7,6,altered fifths

key = 0  
transparency = 0.2
--- color settings
chordtones  = 0x0000FF
rootnotes    = 0xFF0000 
scalenotes = 0x00FF00 
leadingtones = 0xFFFF00

------------------------
min_X = 10000
max_X = 0 
limit = 100

-- Some bugs must be fixed before "release" :
-------------------------------------------
--     support yet for maj,sus,sub...aug 
--     support for added pedalnote with /
--     improve update condition 
--     draw the rightmost block 
--     color by property

scaletable = {["C"] = 0, ["D"] = 2, ["E"]= 4 , ["F"]=5,["G"] = 7, ["A"] = 9 , ["B"] = 11,["c"] = 0, ["d"] = 2, ["e"]= 4 , ["f"]=5,["g"] = 7, ["a"] = 9 , ["b"] = 11}
function getChord(chord)
    --chord = "F#7b5#9b13" 
    local s_degree = {} 
    local key = 0
    local str = {}
  
    local leftover = string.gsub(chord, "^[ABCDEFGabcdefg]","")
    _, _,root = string.find(chord, "^([ABCDEFGabcdefg])") 
    if root then str[1] = "1" end 
  
    key = scaletable[root]
  
    local leftover2 = string.gsub(leftover,"^[#b]", "")
    local _, _,sharp_flat = string.find(leftover,"^([#b])") 
  
    if sharp_flat=="b" then 
       key = key - 1 
    end 
    if sharp_flat=="#" then 
       key = key + 1 
    end
  
    leftover3=string.gsub(leftover2,"m","")
    local _, _,minor_or_major = string.find(leftover2,"^([m])") 
    if  minor_or_major == "m" then
      str[4] = 3
    else 
      str[5] = 3
    end
  
    local pos= 0 
    local altered_fifth = false
  
    while pos do 
      _,pos,sign,digit=string.find(leftover3,"^([#b]?)([56791])",pos+1)
      if digit =="1" then 
         _,pos2,digit2=string.find(leftover3,"^([13])",pos+1) 
         digit = digit..digit2 
      end 
  
      digit=tonumber(digit) 
      local fifth = false 
      if digit == 5 then idx = 8;fifth = true; end
      if digit == 7 then idx = 11 end 
      if digit == 6 then idx = 10 end 
      if digit == 9 then idx = 3;digit = 2; end 
      if digit == 11 then idx = 6;digit = 4; end 
      if digit == 13 then idx = 10;digit = 6; end 
      if sign == "#" then 
        idx = idx + 1 end 
      if sign == "b" then idx = idx -1 end 

      if (sign =="#" or sign =="b") and fifth then 
         altered_fifth = true 
      end
    
      if pos then 
         str[idx] = digit 
         s_degree[pos] = {}
         s_degree[pos].digit = digit 
         s_degree[pos].idx = idx  
      end 
    end 
  
    local retstr=""
    -- making a string 

    if altered_fifth==false then str[8] = "5" end
    for i=1,12 do 
      if str[i] then 
         retstr = retstr..tostring(str[i])
      else 
         retstr = retstr.."0"
      end 
    end 
    if key == 12 then key=0 end 

    return retstr,key
end 
  -- scaleprofile 

function ConvertCCTypeChunkToAPI(lane) --sader magic
    tLanes = {[ -1] = 0x200, -- Velocity
                  [128] = 0x201, -- Pitch
                  [129] = 0x202, -- Program select
                  [130] = 0x203, -- Channel pressure
                  [131] = 0x204, -- Bank/program
                  [132] = 0x205, -- Text
                  [133] = 0x206, -- Sysex
                  [167] = 0x207, -- Off velocity
                  [166] = 0x208, -- Notation
                  [ -2] = 0x210, -- Media Item lane
                 }    
    if type(lane) == "number" and 134 <= lane and lane <= 165 then 
      return (lane + 122) -- 14 bit CC range from 256-287 in API
    else 
      return (tLanes[lane] or lane) -- If 7bit CC, number remains the same
    end
end 

function idle() -- if you close the midi editor
   hwnd = reaper.MIDIEditor_GetActive()
   take = reaper.MIDIEditor_GetTake(hwnd) 
   if take then  
      readfromchunk() 
      if rectRight then 
        bitmap  = reaper.JS_LICE_CreateBitmap(true,rectRight-rectLeft, rectBottom-rectTop ) -- one bitmap 
      end
      return main() 
   else 
      return reaper.defer(idle)
   end
end 

chunkc = 0 -- counting number of executions
function readfromchunk()   
    chunkc = chunkc + 1
    -- This is mostly taken from Julian Saders midiscripts
    hwnd = reaper.MIDIEditor_GetActive()
    take = reaper.MIDIEditor_GetTake(hwnd)
    tME_Lanes = {}  
    midiview  = reaper.JS_Window_FindChildByID(hwnd, 1001) 

    -- pcall will bring the script into idle state if the item is rendered invalid.
    ret,msg = pcall( function() 
      item = reaper.GetMediaItemTake_Item(take )
    end) 
    if not ret then return reaper.defer(idle) end
    
    _, chunk = reaper.GetItemStateChunk( item,"",1)  
    ----------------------------------------------------------------- 
    takeNum = reaper.GetMediaItemTakeInfo_Value(take, "IP_TAKENUMBER")
    takeChunkStartPos = 1
    for t = 1, takeNum do
      takeChunkStartPos = chunk:find("\nTAKE[^\n]-\nNAME", takeChunkStartPos+1)
      if not takeChunkStartPos then 
          reaper.MB("Could not find the active take's part of the item state chunk.", "ERROR", 0) 
          return false
      end
    end 
    takeChunkEndPos = chunk:find("\nTAKE[^\n]-\nNAME", takeChunkStartPos+1)
    activeTakeChunk = chunk:sub(takeChunkStartPos, takeChunkEndPos) 
    ME_LeftmostTick, ME_HorzZoom, ME_TopPitch, ME_pixel_per_pitch = 
    activeTakeChunk:match("\nCFGEDITVIEW (%S+) (%S+) (%S+) (%S+)") 
    ME_LeftmostTick,  ME_HorzZoom , ME_TopPitch , ME_pixel_per_pitch = 
    tonumber(ME_LeftmostTick),tonumber(ME_HorzZoom),tonumber(ME_TopPitch),tonumber(ME_pixel_per_pitch)
    activeChannel, ME_Docked, ME_TimeBase = activeTakeChunk:match("\nCFGEDIT %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ (%S+) %S+ %S+ %S+ %S+ %S+ %S+ %S+ (%S+) %S+ (%S+)") 
    tbase= tonumber(ME_TimeBase) 
    topvisiblepitch = 127 - ME_TopPitch 

    laneID = -1 -- lane = -1 is the notes area
    tME_Lanes[-1] = {Type = -1, inlineHeight = 100} -- inlineHeight is not accurate, but will simply be used to indicate that this "lane" is large enough to be visible.
    for vellaneStr in activeTakeChunk:gmatch("\nVELLANE [^\n]+") do 
      laneType, ME_Height, inlineHeight = vellaneStr:match("VELLANE (%S+) (%d+) (%d+)")
      laneType, ME_Height, inlineHeight = ConvertCCTypeChunkToAPI(tonumber(laneType)), tonumber(ME_Height), tonumber(inlineHeight)
      if not (laneType and ME_Height and inlineHeight) then
          reaper.MB("Could not parse the VELLANE fields in the item state chunk.", "ERROR", 0)
          return(false)
      end    
      laneID = laneID + 1   
      tME_Lanes[laneID] = {VELLANE = vellaneStr, Type = laneType, ME_Height = ME_Height, inlineHeight = inlineHeight}
    end  
    
    if midiview then
       clientOK, rectLeft, rectTop, rectRight, rectBottom = reaper.JS_Window_GetClientRect(midiview) --takeChunk:match("CFGEDIT %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ (%S+) (%S+) (%S+) (%S+)") 
       if not clientOK then 
             reaper.MB("Could not determine the MIDI editor's client window pixel coordinates.", "ERROR", 0) 
             return(false) 
       end 
       ME_midiviewWidth  = ((rectRight-rectLeft) >= 0) and (rectRight-rectLeft) or (rectLeft-rectRight)--ME_midiviewRightPixel - ME_midiviewLeftPixel + 1
       ME_midiviewHeight = ((rectTop-rectBottom) >= 0) and (rectTop-rectBottom) or (rectBottom-rectTop)--ME_midiviewBottomPixel - ME_midiviewTopPixel + 1
       local laneBottomPixel = ME_midiviewHeight-1
       for i = #tME_Lanes, 0, -1 do
          tME_Lanes[i].ME_BottomPixel = laneBottomPixel
          tME_Lanes[i].ME_TopPixel    = laneBottomPixel - tME_Lanes[i].ME_Height + 10
          laneBottomPixel = laneBottomPixel - tME_Lanes[i].ME_Height
       end
       tME_Lanes[-1].ME_BottomPixel = laneBottomPixel
       tME_Lanes[-1].ME_TopPixel    = 62
       tME_Lanes[-1].ME_Height      = laneBottomPixel-61
       ME_BottomPitch = topvisiblepitch - math.floor(tME_Lanes[-1].ME_Height / ME_pixel_per_pitch) 
    end 
    ME_topmostPitch = topvisiblepitch
end 

resetcount = 0
function getzoominfo()  
  --[[ This functions job is to detect changes in zoom/scroll setting 
  and initiate a response. 
  It also detect the horizontal pixel/zoom settings.]]
  HORZ = {reaper.JS_Window_GetScrollInfo(midiview, "HORZ")}   
  VERT = {reaper.JS_Window_GetScrollInfo(midiview,"VERT")}  
  x, y = reaper.GetMousePosition()
  X, Y = reaper.JS_Window_ScreenToClient(midiview,  x,   y)  
  Y = Y - 63  
  segment_ = segment or 0  -- detect change in Getmousecursorcontext
  retval_BR_Getmousecursorcontext , segment, details = reaper.BR_GetMouseCursorContext() 
  timepos = reaper.BR_GetMouseCursorContext_Position() 

  ------ analysing zoom data
  -- The cursor must be in the midi editor client area to work.
  if  segment == "notes" then 
    QN = reaper.TimeMap2_timeToQN(0,timepos) 
    -- To avoid the timebase recalculation
    -- QnPerPixel is calculated by tracking the mouse movement.
    if QN >0 then 
      if X>max_X then 
        max_X = X 
        max_Qn = QN 
      end 

      if X<min_X then
        min_X = X 
        min_Qn = QN 
      end 
    end 
    local ratio = (max_X - min_X)/(max_Qn - min_Qn)
    -------------------------------------------
    ME_Leftmost_Qn =  max_Qn - max_X /ratio 
    ME_Rightmost_Qn =  min_Qn + ( HORZ[3]- min_X)/ratio 
    ME_QnPerPixel = (max_Qn - min_Qn)/(max_X - min_X) 
    H_zoom_ = H_zoom or 0
    H_zoom = HORZ[3] 
    H_zoom2_ = H_zoom2 or 0
    H_zoom2 = HORZ[5]
    H_scroll_ = H_scroll or 0
    H_scroll = HORZ[2]
    if  H_zoom~=H_zoom_ or H_scroll~=H_scroll_ or H_zoom2~=H_zoom2_ then 
      resetcount = resetcount +1
      min_X = 10000
      max_X = 0 
      update=true 
      deleteBitmap() 
    end 
    V_zoom_ = V_zoom or 0
    V_zoom = VERT[3] 
    V_scroll_ = V_scroll or 0
    V_scroll = VERT[2] 
    if V_zoom~=V_zoom_ or V_scroll ~= V_scroll_ then 
       resetcount = resetcount +1
       min_X = 10000
       max_X = 0 
       update=true    
       deleteBitmap() 
    end 
    ME_BottomPitch = ME_topmostPitch - VERT[3]/100 
    ME_pixels_per_Qn = ratio 
  else 
    deleteBitmap()
    update = false
  end 
  
  -- moving the cursor back into the midieditor from somewhere else? 
  if  ME_pixels_per_Qn then ok = true else ok=false end
  if segment_ ~= segment and segment == "notes" then update = true end 
end 

function giveSD(key,scale) 
  -- This function will sweep trough all 128 notes, and put those who fit within the scale ,into a table.
   -- This function will analyse the scale = "102034050607" string.
   -- Determining color of each scale degree 
   local t={} 
   local color
   for i = 1 ,128 do 
      local Cdegree = (i- key)%12 + 1
      local number = string.sub(scale,Cdegree,Cdegree) 
      number = tonumber(number) 
      if i<= ME_topmostPitch and i>= ME_BottomPitch then 
        if number ~= 0 then 
           local tb={} 
           if number == 3 or number==  5 then 
             color =  chordtones   
           end 
           if number == 1 then  -- rootnote
             color =  rootnotes 
           end 
           if  number== 2 or number ==4 or number==6   then  
               color = scalenotes   
           end 
           if  number== 7 then 
              color = leadingtones 
           end 
           tb = {pitch = i,color = color}
           table.insert(t, tb ) 
        end
      end 
   end
   return t
end 

-- This function is not in use
-- its supposed to detect scaledegrees based on wheater mouse move up or down. up = # , down = b
function scaledegree(pitch) -- 0 = C , 1 = C#
      Cdegree_ = Cdegree or 0
      Cdegree = (pitch- key)%12 + 1
      number_ = number or 0
      number = string.sub(scale,Cdegree,Cdegree) 
      number = tonumber(number)
      if number == 0 then
         if Cdegree_- Cdegree ==  1 then 
            movement = "down" 
            if number_==3 and Cdegree == 4 then 
              newsign ="b3" end 
            if number_==2 and Cdegree == 2 then 
              newsign ="b2" end 
            if number_==5 and Cdegree == 7 then 
               newsign ="b5" end    
            if number_==6 and Cdegree == 6 then 
                newsign ="b6" end 
            if number_==7 and Cdegree == 11 then 
                newsign ="b7" end 
            if number_==0 and Cdegree == 12 then 
                newsign ="#7" end 
         end 
         if Cdegree - Cdegree_ ==  1 then 
            movement = "up" 
            if number_==3 and Cdegree == 5 then 
              newsign ="#3" end 
            if number_==1 and Cdegree == 2 then 
              newsign="#1" end 
            if number_==4 and Cdegree == 7 then 
              newsign ="#4" end    
            if number_==5 and Cdegree == 9 then 
              newsign ="#5" end  
            if number_==6 and Cdegree == 11 then 
              newsign ="#6" end  
            if number_==7 and Cdegree == 12 then 
              newsign ="#7" end  
          end
     end
end   

-- This function is not in use 
function delay(t) -- this will delay any redrawing by t seconds
  local t = reaper.time_precise() + t
  return function() 
    if t< reaper.time_precise() then return false else return true end
  end
end

function createBitmap() 
   bitmap  = reaper.JS_LICE_CreateBitmap(true,rectRight-rectLeft, rectBottom-rectTop ) -- one bitmap 
end 

function deleteBitmap() 
  if bitmap then    
     reaper.JS_Composite_Unlink(midiview,bitmap )
     reaper.JS_LICE_DestroyBitmap(bitmap ) 
  end 
end 

-- this function is not in use.
-- it hightlights the entire row.
function hightlightRow(row,color_) 
   if row<= ME_topmostPitch and row>=  ME_BottomPitch then 
      local y1 = (ME_topmostPitch-row)*ME_pixel_per_pitch + 64
      reaper.JS_LICE_FillRect( bitmap,  pixel_x1,  y1,  pixel_x2 ,y1 + ME_pixel_per_pitch   ,color_, transparency,  "COPY" ) 
   end
end  

kk = 0
function hightlightArea(row, left_qn,right_qn,color_) 
  if row<= ME_topmostPitch and row>=  ME_BottomPitch then 
     local y1 = (ME_topmostPitch-row)*ME_pixel_per_pitch + 64    
     local pixel_x1 = ME_pixels_per_Qn*(left_qn - ME_Leftmost_Qn)
     local pixel_x2 = ME_pixels_per_Qn*(right_qn - ME_Leftmost_Qn) 
     pixel_x1, pixel_x2  = math.floor(pixel_x1) ,math.floor(pixel_x2)
     y1 = math.floor(y1)
     if pixel_x1<=HORZ[3] and pixel_x2<=HORZ[3]+100 then 
        kk = kk +1
        reaper.JS_LICE_FillRect( bitmap,  pixel_x1,  y1,  pixel_x2-pixel_x1 ,ME_pixel_per_pitch   ,color_,  transparency,  "COPY" ) 
     end
  end
end

-- this function is currently not in use 
-- it highlights the Quarter note block, regardless of gridsettings.
function getmouseQn() 
   local NN = QN -- division not added yet.  If you want to use other quanta then QN,  you must multiply/divide QN with a factor. Not tested yet.
   local pixel_pr_NN = ME_pixels_per_Qn 
   local leftover = NN - math.floor(NN) 
   local startQN = NN - leftover 
   local endQN = startQN + 1
   return startQN, endQN
end 

-- This function detects the markers,and its QN location, and the marker name that contains the name of the chord.
function find_markers() 
  local nm = ""  
  endQN, startQN = 0,0
  --CountProjectMarkers_retval, num_markers,  num_regions= reaper.CountProjectMarkers(0) 
  local pos = 0 
  local marker_QN = 0 
  local i=0
  while true do  
    markername = nm
    EnumProjectMarker_RETVAL, isrgn, pos, rgnend, nm, markrgnindexnumber = reaper.EnumProjectMarkers(i)
    i = i + 1
    marker_QN = reaper.TimeMap_timeToQN(pos)
    if EnumProjectMarker_RETVAL == 0 then 
       endQN = ME_Rightmost_Qn
       break
    else 
      if QN > marker_QN then 
        startQN = marker_QN
      else 
        endQN = marker_QN
        break 
      end
    end
  end 
end 

reaper.atexit(function() 
   deleteBitmap() 
   reaper.JS_LICE_DestroyBitmap(bitmap ) 
end)
teller= 0
-- minimize chunkreading further.
-- delay update
-- waterproofing

function main()
  getzoominfo()  
  if ok then -- "ok" makes sure there is enough info or good enough reason to draw.
    --update condition
    startQN_ = startQN or 0 
    --startQN and endQN is detected in find_markers() or in other functions.
    find_markers()   
    if startQN ~= startQN_ then deleteBitmap();update=true end 
    if endQN == nil then deleteBitmap();update = false end 

    scale ,key = getChord(markername) -- this function decides the "key" and "chordtype" value by parsing/analysing the "markername" string.
  
    if markername=="" or markername ==nil then deleteBitmap();ok= false end
  end
  if ok and update then 
    teller = teller +1 
    readfromchunk()
    deleteBitmap() 
    createBitmap()
    pitchT=giveSD(key,scale) -- pitchT contains all the pitchclasses that you want to be hightlighted
    for u,v in pairs(pitchT) do 
        if v.pitch then 
          hightlightArea(v.pitch,startQN, endQN,v.color) -- startQN and endQN is determined in the findmarkers function
        end
    end  
    ok_ = reaper.JS_Composite(midiview ,0, 0,-1, -1,bitmap, 0, 0, rectRight-rectLeft, rectBottom-rectTop, false)
    update = false
  end 
  reaper.defer(main)
end

ok = false 
readfromchunk() 
main()

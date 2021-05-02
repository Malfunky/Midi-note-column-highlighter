-- Want to add mouse jerk

scale = "102304056007"
key = 3 -- C major 

chordtones  = 0x0000FF
rootnotes    = 0xFF0000 
scalenotes = 0x00FF00 
leadingtones = 0xFFFF00

------------------------
min_X = 10000
max_X = 0 
height ={} 
limit = 100
count = 0 

function getextstate() 
   key = reaper.GetExtState("Scale hightligter","key")
end 

function GetInfo() 
  midiview = reaper.JS_Window_Find("midiview",false) 
  HORZ = {reaper.JS_Window_GetScrollInfo(midiview, "HORZ")}   
  VERT = {reaper.JS_Window_GetScrollInfo(midiview,"VERT")}  
  --boolean retval, number position, number pageSize, number min, number max, number trackPos = reaper.JS_Window_GetScrollInfo(identifier windowHWND, string scrollbar)
 
  x, y = reaper.GetMousePosition()
  X, Y = reaper.JS_Window_ScreenToClient(midiview,  x,   y)  
  Y = Y - 63  
  segment_ = segment or 0  -- detect change in Getmousecursorcontext
  retval_BR_Getmousecursorcontext , segment, details = reaper.BR_GetMouseCursorContext() 
  retval_BR_Getmousecursorcontext_MIDI,  inlineEditor,   noteRow,   ccLane, ccLaneVal,  ccLaneI = reaper.BR_GetMouseCursorContext_MIDI() 
  timepos = reaper.BR_GetMouseCursorContext_Position() 
  retval,  left,  top,  right,  bottom = reaper.JS_Window_GetClientRect(midiview)
  top_P= 127-VERT[2]/100 
  pixeltop = top + 63
end 

function playgod() 
   local a = x 
   local b = y 
   for g=1 , 10 do 
     ok = reaper.JS_Mouse_SetPosition(x, y + (11 - g) ) 
     GetInfo()
     y_analysis()  
   end 
   reaper.JS_Mouse_SetPosition(a,b)
end  

function y_analysis()
  local i = 4 
  local upper_limit =100
  local pd = top_P-noteRow 
  local lower_limit = Y/(pd +1) 
  if pd > 1 then 
     upper_limit = Y/(pd -1) end 
  if pd == 1 then 
     upper_limit = Y 
  end
  i = math.floor(lower_limit-1)
  while (i<upper_limit) do
      if Y>=i*pd and Y<=(i*pd + i)   then 
        if height[i] then 
          height[i] = height[i] + 1     
        else 
          height[i]=1 
        end
      end 
      i=i+1 
  end
  local m = 0
  for u,v in pairs(height) do 
    if v>m then
      m=v 
      hg=u
    end 
  end 
  ME_pixel_per_pitch =hg
end 


function composite() 
  ok_ = reaper.JS_Composite(midiview ,0, 0,-1, -1,bitmap, 0, 0, right-left, bottom-top, true)
end


function getzoominfo() 
  GetInfo()  
  if  segment == "notes" then 
    QN = reaper.TimeMap2_timeToQN(0,timepos) 
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
      ME_Leftmost_Qn =  nil 
      ME_Rightmost_Qn =  nil 
      ME_QnPerPixel = nil
      height={}
      min_X = 10000
      max_X = 0 
      update=true
    end 

    if count<limit  then 
       y_analysis() 
       count = count +1
     end 
 
    ME_pixel_per_pitch =hg
    ME_topmostPitch = top_P 
    ME_bottommostPitch = top_P - VERT[3]/100 
    ME_lowerPixelY = (ME_topmostPitch -ME_bottommostPitch +1 )*hg   
    ME_pixels_per_Qn = ratio
    
    V_zoom_ = V_zoom or 0
    V_zoom = VERT[3] 
    V_scroll_ = V_scroll or 0
    V_scroll = VERT[2] 

    if V_zoom~=V_zoom_ then 
       update=true 
       height={}
       removeBitmap()
       count = 0 
       ME_pixel_per_pitch = nil 
       ME_bottommostPitch = nil 
       ME_topmostPitch = nil 
    end 
  else 
    removeBitmap()
  end  
  -- moving the cursor back into the midieditor from somewhere else?
  if segment_ ~= segment and segment == "notes" then update = true end 

  -- Have these values been fully detected yet ?
  if ME_bottommostPitch then 
    if ME_pixel_per_pitch then 
      if  ME_Rightmost_Qn then 
        if  ME_pixels_per_Qn then 
          if QN then
            return true 
          end
        end
      end 
    end 
  end 
  return false 
end 

function giveSD(key,scale) 
   local t={} 
   local color
   for i = 1 ,128 do 
      local Cdegree = (i- key)%12 + 1
      local number = string.sub(scale,Cdegree,Cdegree) 
      number = tonumber(number) 
      if i<= ME_topmostPitch and i>=ME_bottommostPitch then 
        if number ~= 0 then 
          local tb={} 
          if number == 3 or number==  5 then 
            color =  chordtones    end 
          if number == 1 then  
            color =  rootnotes end 
          if  number== 2 or number ==4 or number==6   then  
             color = scalenotes   end 
          if  number== 7 then color = leadingtones end
          tb = {pitch = i,color = color}
          table.insert(t, tb )
        end
      end 
   end
   return t
end 

function scaledegree(pitch) -- 0 = C , 1 = C#
    --  test = pitch%12 
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

function delay(t) -- this will delay any redrawing by t seconds
  local t = reaper.time_precise() + t
  return function() 
    if t< reaper.time_precise() then return false else return true end
  end
end
 
-- Every bitmap that is generated will be counted and indexed by dcc

function createBitmap() 
   bitmap  = reaper.JS_LICE_CreateBitmap(true,right- left  , bottom - top  ) 
end 
 
function removeBitmap() 
   if bitmap then    
      reaper.JS_Composite_Unlink(midiview,bitmap )
       reaper.JS_LICE_DestroyBitmap(bitmap ) 
      
  end 
end 

function hightlightRow(row,colorf) 
   if row<= ME_topmostPitch and row>= ME_bottommostPitch then 
      local y1 = (ME_topmostPitch-row)*ME_pixel_per_pitch + 64
      reaper.JS_LICE_FillRect( bitmap,  pixel_x1,  y1,  pixel_x2 ,y1 + ME_pixel_per_pitch   ,colorf, 0.1,  "COPY" ) 
   end
end 

function hightlightArea(row, left_qn,right_qn,colorf) 
  if row<= ME_topmostPitch and row>= ME_bottommostPitch then 
     local y1 = (ME_topmostPitch-row)*ME_pixel_per_pitch + 64    
     local pixel_x1 = ME_pixels_per_Qn*(left_qn - ME_Leftmost_Qn)
     local pixel_x2 = ME_pixels_per_Qn*(right_qn - ME_Leftmost_Qn) 
     pixel_x1, pixel_x2  = math.floor(pixel_x1) ,math.floor(pixel_x2)
     y1 = math.floor(y1)
     if pixel_x1<HORZ[3] and pixel_x2<HORZ[3] then 
       reaper.JS_LICE_FillRect( bitmap,  pixel_x1,  y1,  pixel_x2-pixel_x1 ,ME_pixel_per_pitch   ,colorf, 0.1,  "COPY" ) 
     end
  end
end 

function getmouseQn() 
   local NN = QN -- division not added yet 
   local pixel_pr_NN = ME_pixels_per_Qn 
   local leftover = NN - math.floor(NN) 
   local startQN = NN - leftover 
   local endQN = startQN + 1
   return startQN, endQN
end 

function find_markers() 
  markers = {} 
  CountProjectMarkers_retval, CountProjectMarkers_num_markers, CountProjectMarkers_num_regions= reaper.CountProjectMarkers(0) 
  pos = 0
  local i = 0
  reaper.ShowConsoleMsg("") 
  while true do
    ret, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
   
    marker_QN = pos*4 
    if QN > marker_QN then 
       
    end
     
    if ret == 0 then
       break
    end
    reaper.ShowConsoleMsg("Pos: " .. pos .. "\n" .. "End: " .. rgnend.. "\n" .. "Name: " .. name .. "\n\n")
    i = i + 1
  end
end

function updatecondition() 
   startQN_ = startQN or 0 
   startQN, endQN =  getmouseQn()  
   if startQN ~= startQN_ then update=true end 
end 

function draw() 
  local pitchT=giveSD(key,scale) 
  for u,v in pairs(pitchT) do 
      if v.pitch then 
        hightlightArea(v.pitch,startQN, endQN,v.color) 
      end
  end 
end 

reaper.atexit(function() 
  removeBitmap()
   ret, listallbitmaps = reaper.JS_LICE_ListAllBitmaps()
end)
teller= 0

function main()
  local ok = getzoominfo()  
  if ok then 
    updatecondition() 
    find_markers() 
  end
  if ok and update then 
    teller = teller +1 
    removeBitmap()
    createBitmap() 
    draw() 
    composite()
    update = false
  end 
  reaper.defer(main)
end

main()

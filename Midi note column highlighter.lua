-- This script highlights the notecoloum of your notesize

-- Changelog
--4/24-21
--bitmap gets unlinked during zooming
--when changing grid/notelength settings, hightlighting changing instantly. 
--Smaller bitmaps 
--Softer highlighting 

--4/25-21
--Alot simpler algoritm. No table management. 
--New update condition. Scrip less wobbly. 

--5/1 -- BR_GetMouseCursorContext_MIDI removed. Cos it reads from midi chunk. Illegal!

-- USER SETTINGS 
Transparancy = 0.06
Color = 0x0099A3B2 -- 0x00RRGGBB
--------------------------------- 

sectionID = 32060 -- midi editor
local bs = reaper.SetToggleCommandState(sectionID ,({reaper.get_action_context()})[4],1)  

function round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

min_X = 10000
max_X = 0 
bitmap = reaper.JS_LICE_CreateBitmap(true, 1  ,1  ) 
box = reaper.JS_LICE_FillRect( bitmap,  0,  0,  1 , 1 , Color,Transparancy, "ADD") 

redr  = 0
function draw() 
  redr  = redr +1 
  boxx1, y_c = reaper.JS_Window_ScreenToClient(midiview,   box_x1,   y)
  retval = reaper.JS_Composite(midiview , boxx1, y_c,  note_length,-1, bitmap , 0, 0, 1 , 1 ,true) 
end 

function main() 
  midiview = reaper.JS_Window_Find("midiview",false) 
  _, segment, details = reaper.BR_GetMouseCursorContext() 
  timepos = reaper.BR_GetMouseCursorContext_Position() 
  HORZ = {reaper.JS_Window_GetScrollInfo(midiview, "HORZ") } 

  -- get som gridinfo
  hwnd = reaper.MIDIEditor_GetActive() 
  if hwnd then 
     take = reaper.MIDIEditor_GetTake(hwnd)
     noteLen_ = noteLen or 0
     gridvalue_ = gridvalue or 0
     swing_ = swing or 0
     gridvalue,  swing,   noteLen = reaper.MIDI_GetGrid(take) 
     snap = reaper.MIDIEditor_GetSetting_int(hwnd,"snap_enabled") 
  end

  if  segment=="notes" then 
    x, y = reaper.GetMousePosition() 
    X, Y = reaper.JS_Window_ScreenToClient(midiview,  x,   y) 
          -- update conditions
       if gridvalue_~=gridvalue then redraw=true end
       if noteLen_~=noteLen then redraw=true end
       if swing_~=swing then redraw=true end
         --------------------------------------------- 
       QN = reaper.TimeMap2_timeToQN(0,timepos) 
       if QN >0 then 
           if  X>max_X then 
             max_X = X 
             max_Qn = QN
           end 
     
           if X<min_X then
             min_X =  X 
             min_Qn = QN 
           end
       end 
       width = (max_X - min_X)/(max_Qn - min_Qn)
         -------------------------------------------
      -- ME_Leftmost_Qn =  max_Qn - max_X/width
      -- ME_QnPerPixel = (max_Qn - min_Qn)/(max_X - min_X) 
       -- converting quarternote to "something else" note
       NN=QN/gridvalue 
       NN_round_ = NN_round or 0
       NN_round = math.floor(NN) 
       if NN_round_~=NN_round then redraw = true end
       NN_leftover = NN-NN_round 
 

     -- some crazy special case   --  grid : 1  triplet
    if gridvalue == 8/3 and swing==0 then 
      swing = 0.64 -- rs = 0.66 
      gridvalue = 2  
      NN=QN/gridvalue 
      nutcase = true
    end  

    if swing~=0 then  
       mouse_pos = NN/2 
       rs = 2 - swing  -- 1--3
       rs = 1-rs/4 
       leftover = mouse_pos - math.floor(mouse_pos) 
       sone_ = sone or sone
       if leftover<rs then  
          sone = 1 
          position_in_swing = leftover/rs 
          NN_leftover = position_in_swing
       else 
          sone = 2 
          position_in_swing = (leftover-rs)/(1-rs) 
          NN_leftover = position_in_swing
        end 
        if sone_ ~= sone then redraw = true end  -- stop using update!!
    end   
  end 
    if gridvalue then 
      if width then 
         new_width = width*gridvalue
         if swing~=0 then  
            new_width = width*gridvalue*2 
            if sone == 1 then 
              new_width = new_width*rs end 
            if sone == 2 then
              new_width = new_width*(1-rs) 
            end
         end 
       end
    end 
  
  if gridvalue and timepos then 
    if gridvalue>=4 and swing~=0 then timepos = -1 end 
    if gridvalue == 16/3 or gridvalue == 32/3 then timepos = -1 end
    if  width then 
       box_x1 = x - NN_leftover*new_width
       if noteLen ~= 0 then 
          note_length=width*noteLen
       else note_length=new_width end
       if  segment ~= "notes" then redraw=false end 
       if nutcase then 
          if sone == 2 then 
            note_length = note_length*2 
              nutcase =false
          end 
       end 
       
       if snap==0 then box_x1=x end
       box_x1 = round(box_x1) 
       new_width = round(new_width)
       note_length = round(note_length)
       if redraw==true then 
         pcall( function() 
                  draw() 
         end )
         redraw = false
       end
    else
       reaper.JS_Composite_Unlink(midiview, bitmap) 
    end   
  end 
  if segment ~= "notes" then  reaper.JS_Composite_Unlink(midiview, bitmap) end 
  H_zoom_ = H_zoom or 0
  H_zoom = HORZ[3] 
   H_zoom2_ = H_zoom2 or 0
   H_zoom2 = HORZ[5]
   H_scroll_ = H_scroll or 0
   H_scroll = HORZ[2] 

  if  H_zoom~=H_zoom_ or H_zoom2~=H_zoom2_ then 
     reaper.JS_Composite_Unlink(midiview, bitmap) 
  end 

    if  H_zoom~=H_zoom_ or H_scroll~=H_scroll_ or H_zoom2~=H_zoom2_ then 
          min_X = 10000
          max_X = 0 
          min_Qn = 10000
          max_Qn = 0
        end 
        
  reaper.defer(main)
end 

function exit() 
     reaper.JS_Composite_Unlink(midiview, bitmap) 
     reaper.JS_LICE_DestroyBitmap(bitmap) 
     local bs = reaper.SetToggleCommandState(sectionID ,({reaper.get_action_context()})[4],0) 
end 

reaper.atexit(function() 
   exit()
end)

main()

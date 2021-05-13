-- This script highlights the notecoloum of your notesize

-- Changelog
--4/24-21
--bitmap gets unlinked during zooming
--when changing grid/notelength settings, hightlighting changing instantly.

Color = 0x0099A3B2 -- 0x00RRGGBB
--------------------------------- 

timepos,x,y = 0,0,0
count = 0 
est_table ={} 
max_entries = 10 
--number_of_redraws = 0 
sectionID = 32060 -- midi editor
local bs = reaper.SetToggleCommandState(sectionID ,({reaper.get_action_context()})[4],1)  

function keyLargest(map)
  local best = nil
     for key in pairs(map) do
       if best == nil then
             -- first key in the map
         best = key
        elseif map[best] < map[key] then
             -- `key` has a bigger value than `best`,
              -- so `key` is our new best
        best = key
      end
    end
  return best
end 

 function round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
 end

 bitmap = reaper.JS_LICE_CreateBitmap(true, 100 ,100 ) 
 box = reaper.JS_LICE_FillRect( bitmap,  0,  0,  100, 100, Color, 0.1, "ADD") 

function draw() 
  midiview = reaper.JS_Window_Find("midiview",false) 
  boxx1, y_c = reaper.JS_Window_ScreenToClient(midiview,   box_x1,   y)
  retval = reaper.JS_Composite(midiview , boxx1, y_c,  note_length,-1, bitmap , 0, 0, 100, 100,true) 
end 

function main()
  retval_BR_Getmousecursorcontext , segment, details = reaper.BR_GetMouseCursorContext() 
  noteRow_ = noteRow 
  retval_BR_Getmousecursorcontext_MIDI,  inlineEditor,   noteRow,   ccLane, ccLaneVal,  ccLaneI = reaper.BR_GetMouseCursorContext_MIDI() 
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

  if timepos~=-1 and gridvalue then 
    x_,y_ = x,y 
    x, y = reaper.GetMousePosition() 
    QN_ = QN
    QN = reaper.TimeMap2_timeToQN(0,timepos) 

    -- converting quarternote to "something else" note
    NN=QN/gridvalue 
    NN_round = math.floor(NN)
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
       if leftover<rs then  
          sone = 1 
          position_in_swing = leftover/rs 
          NN_leftover = position_in_swing
       else 
          sone = 2 
          position_in_swing = (leftover-rs)/(1-rs) 
          NN_leftover = position_in_swing
        end
    end   
  

    -- analysing mouse movement and estimating pixel/grid
    if x_ then 
      -- update conditions
      if x~=x_ then redraw=true end  
      if gridvalue_~=gridvalue then redraw=true end
      if noteLen_~=noteLen then redraw=true end
      if swing_~=swing then redraw=true end
     ---------------------------------------------

      if QN_ then 
        if x_ ~= x then 
          if QN ~= QN_ then 
            xd = x-x_ 
            QNd = QN - QN_ 
            if td~= 0 then 
              estimate = xd/QNd 
              if estimate > 0 then 
                 count = count +1
                 if count>max_entries then count = 1 end
                 est_table[count] = estimate
              end
            end 
          end
        end 
      end
    end
  end 

  -- calculating most popular
  
  local new_table = {}
  for i = 1, #est_table do 
     index = est_table[i] 
     index = round(index)
     if new_table[index]~=nil then 
       new_table[index]=new_table[index]+1 
     else 
       new_table[index] = 0
     end
  end 
  
  if gridvalue then 
    width = keyLargest(new_table) 
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
         if timepos==-1 then redraw=false end 
         if nutcase then 
           if sone == 2 then 
              note_length = note_length*2 
              nutcase =false
            end end 
       
         if snap==0 then box_x1=x end
         
         box_x1 = round(box_x1) 
         new_width = round(new_width)
         note_length = round(note_length)
         if redraw==true then 
            draw() 
            redraw = false
         end
       else
         reaper.JS_Composite_Unlink(midiview, bitmap) 
       end   
  end 
  if timepos == -1 or ccLane~=-1 then  reaper.JS_Composite_Unlink(midiview, bitmap) end 
   H_zoom_ = H_zoom or 0
   H_zoom = HORZ[3] 
   H_zoom2_ = H_zoom2 or 0
   H_zoom2 = HORZ[5]
   H_scroll_ = H_scroll or 0
   H_scroll = HORZ[2] 

    if  H_zoom~=H_zoom_ or H_scroll~=H_scroll_ or H_zoom2~=H_zoom2_ then 
        reaper.JS_Composite_Unlink(midiview, bitmap) 
        count = 0 
        est_table ={} 
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

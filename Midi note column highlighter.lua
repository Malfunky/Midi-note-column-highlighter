-- This script highlights the notecoloum of your notesize
-- it only works when Notesize is set to "grid"
-- only works with quarternotes or smaller 
-- I requested this feature on the forum.


Color = 0x0099A3B2 -- 0x00RRGGBB
--------------------------------- 

timepos,x,y = 0,0,0
count = 0 
est_table ={} 
max_entries = 10 
--number_of_redraws = 0 

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

function draw() 
  reaper.JS_LICE_DestroyBitmap(bitmap) 
  midiview = reaper.JS_Window_Find("midiview",false) 
  bitmap = reaper.JS_LICE_CreateBitmap(true, 100 ,100 ) 
  box = reaper.JS_LICE_FillRect( bitmap,  0,  0,  100, 100, Color, 0.1, "ADD")  
  boxx1, y_c = reaper.JS_Window_ScreenToClient(midiview,   box_x1,   y)
  retval = reaper.JS_Composite(midiview , boxx1, y_c, width,-1, bitmap , 0, 0, 100, 100,true) 

end 

function main()
  retval_BR_Getmousecursorcontext , segment, details = reaper.BR_GetMouseCursorContext() 
  noteRow_ = noteRow 
  retval_BR_Getmousecursorcontext_MIDI,  inlineEditor,   noteRow,   ccLane, ccLaneVal,  ccLaneI = reaper.BR_GetMouseCursorContext_MIDI() 
  timepos = reaper.BR_GetMouseCursorContext_Position() 
  -- get som gridinfo
  hwnd = reaper.MIDIEditor_GetActive() 
  if hwnd~=nil then 
     take = reaper.MIDIEditor_GetTake(hwnd)
     gridvalue,  swing,   noteLen = reaper.MIDI_GetGrid(take) 
  end

  if timepos~=-1 then 
    x_,y_ = x,y 
    x, y = reaper.GetMousePosition() 
    QN_ = QN
    QN = reaper.TimeMap2_timeToQN(0,timepos) 
    QN_round = math.floor(QN)
    QN_leftover = QN-QN_round
    if x_~= nil then 
      if x~=x_ then redraw=true end  
      if QN_~= nil then 
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
     index = math.floor(index)
     if new_table[index]~=nil then 
       new_table[index]=new_table[index]+1 
     else 
       new_table[index] = 0
     end
  end 
  
  local nm = 0 
  
  -- find the largest number 
  if gridvalue ~= nil then 
    width_ = width
    width = keyLargest(new_table) 
    if width ~= nil then 
       ratio =  QN_leftover/gridvalue 
       factor = math.floor(ratio)  
     end
  end
 
  -- caclulate the distance from the x,y position 
  if gridvalue~= nil then 
    if gridvalue<=1 then 
      if timepos~=-1 then 
       if  width~=nil then 
         pixeloffset =   width*QN_leftover
         box_x1_ = box_x1
         box_x1 = x - pixeloffset 
         box_x1  = box_x1 + factor*gridvalue*width
         box_x2 = box_x1  +  width*gridvalue 
         width = width*gridvalue 

         box_x1 = math.floor(box_x1)
         box_x2 = math.floor(box_x2)
         width = math.floor(width) 

         if timepos==-1 then redraw=false end
     
         if redraw==true then 
            draw() 
            redraw = false
         end
       end
      end 
    else 
        reaper.JS_LICE_DestroyBitmap(bitmap) 
    end
  end

  reaper.defer(main)
end

function exit() 
     reaper.JS_LICE_DestroyBitmap(bitmap) 
  --   reaper.JS_Composite_Unlink(midiview ,  bitmap)
end 

reaper.atexit( 
   exit()
)

main()

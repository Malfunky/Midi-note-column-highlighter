-- This script highlights the notecoloum of your notesize 
-- If you adjust gridsize relatively , this script will be very helpful.
-- The script doesnt highlight triplet settings larger than 1 correctly.. But it will at least show you that your grid setting is high...

-- Changelog
--4/24-21
--when changing grid/notelength settings, hightlighting changing instantly. 
--Smaller bitmaps 
--Softer highlighting 

-- 9/23 -- Improved way of getting midi window.  Checking takes. 
-- Highlighting now adjust to tempo changes
-- Supporting Dotted gridlines


-- USER SETTINGS 
Transparancy = 0.06
Color = 0x0099A3B2 -- 0x00RRGGBB
--------------------------------- 

sectionID = 32060 -- midi editor
local bs = reaper.SetToggleCommandState(sectionID ,({reaper.get_action_context()})[4],1)  

function round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

bitmap = reaper.JS_LICE_CreateBitmap(true, 1  ,1  ) 
box = reaper.JS_LICE_FillRect( bitmap,  0,  0,  1 , 1 , Color,Transparancy, "ADD") 

function draw() 
  boxx1, y_c = reaper.JS_Window_ScreenToClient(midiview,   box_x1,   y)
  retval = reaper.JS_Composite(midiview , boxx1, y_c,  note_length,-1, bitmap , 0, 0, 1 , 1 ,true) 
end 

function getWindow() -- taken from JS script 
    x, y = reaper.GetMousePosition()
    windowUnderMouse = reaper.JS_Window_FromPoint(x,y) 
    if windowUnderMouse then  
        parentWindow = reaper.JS_Window_GetParent(windowUnderMouse)
        if parentWindow then
            if reaper.MIDIEditor_GetMode(parentWindow) == 0 then 
               editor = parentWindow
               if windowUnderMouse == reaper.JS_Window_FindChildByID(parentWindow, 1001) then 
                  midiview = windowUnderMouse
                  activeTake = reaper.MIDIEditor_GetTake(editor)
                  activeTakeOK = activeTake and reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") and reaper.TakeIsMIDI(activeTake)
               end
            end
        end
    end
end 

function main() 
    getWindow()
  if activeTakeOK then 
    _, segment, details = reaper.BR_GetMouseCursorContext() 
     timepos = reaper.BR_GetMouseCursorContext_Position() 
    --HORZ = {reaper.JS_Window_GetScrollInfo(midiview, "HORZ") } 
    -- get som gridinfo
      hwnd = reaper.MIDIEditor_GetActive() 
      if hwnd then 
       noteLen_ = noteLen or 0
       gridvalue_ = gridvalue or 0
       swing_ = swing or 0 
       pcall(function() 
         gridvalue,  swing,   noteLen = reaper.MIDI_GetGrid( activeTake)  
       end )
       snap = reaper.MIDIEditor_GetSetting_int(hwnd,"snap_enabled") 
     end
  if  segment=="notes" or segment=="cc_lane" then 
    X_,Y_ = X,Y
    X, Y = reaper.JS_Window_ScreenToClient(midiview,  x,   y) 
          -- update conditions
       if gridvalue_~=gridvalue then redraw=true end
       if noteLen_~=noteLen then redraw=true end
       if swing_~=swing then redraw=true end 
       if snap == 0 then redraw=true end 
         ---------------------------------------------  
       QN_ = QN
       QN = reaper.TimeMap2_timeToQN(0,timepos) 
       measure = QN/4 
       measure_leftover = measure - math.floor(measure)
 
       if X_ and X and QN_ and QN and X_ ~= X and QN_ ~= QN then
            ratio = (X_ - X)/(QN_ - QN) 
       end 
      
       subdiv =  4/gridvalue
       
       subdiv_round = math.floor(subdiv) 
       subdiv_leftover = subdiv - subdiv_round 
       
       dotted_pos = subdiv*measure_leftover 

       if subdiv_leftover ~=0 then 
          dotted = true 
       else 
          dotted = false 
       end 

       if gridvalue == 32/3  then 
          gridvalue = 8
       end 

       if gridvalue == 64/3  then 
          gridvalue = 16
       end 

       if gridvalue == 128/3  then 
          gridvalue = 32
       end

       NN=QN/gridvalue 
       NN_round_ = NN_round or 0
       NN_round = math.floor(NN) 
       if NN_round_~=NN_round then  -- update condition
          redraw = true 
       end  
       NN_leftover = NN-NN_round  
     
      if dotted and gridvalue<=6 then 
        dotted_pos_round_  = dotted_pos_round or 0
        dotted_pos_round = math.floor(dotted_pos) 
        if dotted_pos_round_ ~= dotted_pos_round then -- update condition
           redraw = true 
        end  
        NN_leftover = dotted_pos -   dotted_pos_round 
      end
 
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
        if sone_ ~= sone then redraw = true end   
    end   
  end 
    if gridvalue then 
      if  ratio then 
         new_width =  ratio*gridvalue
         if swing~=0 then  
            new_width =  ratio*gridvalue*2 
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
    if  ratio then 
       box_x1 = x - NN_leftover*new_width
       if noteLen ~= 0 then 
          note_length= ratio*noteLen
       else note_length=new_width end 
       if  segment ~= "notes" and segment ~= "cc_lane" then redraw=false end  

       if nutcase then 
          if sone == 2 then 
            note_length = note_length*2 
            nutcase =false
          end 
       end 

       if dotted and gridvalue == 6 then 
         note_length = note_length/1.5
         redraw = true 
       end 
         
       if gridvalue == 16/3 then 
         note_length = note_length*0.75
         redraw = true 
       end
       
       if snap==0 then box_x1=x end
       box_x1 = round(box_x1)  
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
  if segment ~= "notes" and segment~="cc_lane"  then  reaper.JS_Composite_Unlink(midiview, bitmap) end 

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

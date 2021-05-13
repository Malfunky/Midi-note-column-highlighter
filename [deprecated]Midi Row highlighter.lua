--USER DATA 
-- WARNING THIS SCRIPT READS FROM MIDI CHUNK AND IS NOT REALLY USEFUL.
customcolor = 0xDD0033 -- red
transparancy = 0.1


------------------------------------
sectionID = 32060 -- midi editor
local bs = reaper.SetToggleCommandState(sectionID ,({reaper.get_action_context()})[4],1)  

function getzoominfo()
    midiview = reaper.JS_Window_Find("midiview",false) 
   -- HORZ = {reaper.JS_Window_GetScrollInfo(midiview, "HORZ") } 
    VERT = {reaper.JS_Window_GetScrollInfo(midiview,"VERT")}
    x, y = reaper.GetMousePosition()
    X, Y = reaper.JS_Window_ScreenToClient(midiview,  x,   y) 
    _ , segment, _ = reaper.BR_GetMouseCursorContext() 
    _,  _,   noteRow,   _, _, _ = reaper.BR_GetMouseCursorContext_MIDI() 
    timepos = reaper.BR_GetMouseCursorContext_Position() 
    retval,  left,  top,  right,  bottom = reaper.JS_Window_GetClientRect(midiview)
    top_P= 127-VERT[2]/100 
    pixeltop = top + 62
    Y =Y - 63 
    if  segment == "notes" then 
      if count<limit  then 
        i = 4 
        upper_limit =100
        pd = top_P-noteRow 
        lower_limit = Y/(pd +1) 
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
        m = 0
        for u,v in pairs(height) do 
          if v>m then
            m=v 
            hg=u
          end 
        end
      end
      if (top_P-noteRow)>4 then -- to ensure more precise gathering of data
        count = count +1  end
      ME_pixel_per_pitch =hg
      ME_topmostPitch = top_P 
      ME_bottommostPitch = top_P - VERT[3]/100
      
      V_zoom_ = V_zoom or 0
      V_zoom = VERT[3] 
      V_scroll_ = V_scroll or 0
      V_scroll = VERT[2] 
  
      if V_zoom~=V_zoom_     then 
        remove_hightlight()
        reset() 
        wait = delay(0.2)
      end 
    end 
      
    if ME_pixel_per_pitch then 
        if ME_topmostPitch then 
            if  ME_bottommostPitch  then 
                return true 
            end
        end
    end
    return false
end 

function delay(t) -- this will delay any redrawing by t seconds
    local t = reaper.time_precise() + t
    return function() 
      if t< reaper.time_precise() then return false else return true end
    end
end

bitmap = reaper.JS_LICE_CreateBitmap(true, 1  ,1  ) 
box = reaper.JS_LICE_FillRect( bitmap,  0,  0,  1 , 1   ,customcolor, transparancy , "ADD") 
 
function remove_hightlight()
   reaper.JS_Composite_Unlink(midiview,bitmap)
end 

function hightlightRow(row) 
   midiview = reaper.JS_Window_Find("midiview",false) 
   if row<= ME_topmostPitch and row>= ME_bottommostPitch then 
      y1 = (ME_topmostPitch-row)*ME_pixel_per_pitch + 64    
      retvalue = pcall(function()
        diditwork=  reaper.JS_Composite(midiview, 0, y1,-1, ME_pixel_per_pitch, bitmap, 0, 0, 1,1, true) 
      end) 
      if not retvalue then reset() end
   end
end 

function reset()
    count = 0 
    ME_pixel_per_pitch = nil 
    ME_bottommostPitch = nil 
    ME_topmostPitch = nil 
    height={}
 end 

height ={} 
limit = 100
count = 0
function main() 
    if wait then  -- can this be places inside the wait ?00
        wt = wait() 
        if wt then 
        else wait = nil end
     end 
   if getzoominfo() and segment=="notes" and wait==nil then 
       hightlightRow(noteRow)   
   else 
      remove_hightlight() 
   end 
   reaper.defer(main) 
end 

reaper.atexit(function() 
    remove_hightlight() 
    reaper.JS_LICE_DestroyBitmap(bitmap)
    local bs = reaper.SetToggleCommandState(sectionID ,({reaper.get_action_context()})[4],0) 
end)
  
main() 

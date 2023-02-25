 -- This script highlights the notecoloum of your notesize 
-- If you adjust gridsize relatively , this script will be very helpful.
-- The script doesnt highlight triplet settings larger than 1 correctly.. But it will at least show you that your grid setting is high...
-- Changelog
-- 4/24-21
-- when changing grid/notelength settings, hightlighting changing instantly. 
-- Smaller bitmaps 
-- Softer highlighting 
-- 9/23 -- Improved way of getting midi window.  Checking takes. 
-- Highlighting now adjust to tempo changes
-- Supporting Dotted gridlines
-- USER SETTINGS 
local r = reaper
local Transparancy = 0.06
local Color = 0x0099A3B2 -- 0x00RRGGBB 
-- red, green, blue, alpha = 255, 255, 127, 35
--------------------------------- 
local sectionID = 32060 -- midi editor
local bs = r.SetToggleCommandState(sectionID, ({r.get_action_context()})[4], 1)
local macOS = r.GetOS():match("OS")
local timeToQN = r.TimeMap2_timeToQN
local GetBpmAtTime = r.TimeMap2_GetDividedBpmAtTime
local GetMouseCursorContext = r.BR_GetMouseCursorContext
-- wa = alpha/255 -- Windows alpha
-- OSXcolor = ((blue&0xFF)|((green&0xFF)<<8)|((red&0xFF)<<16)|((alpha&0xFF)<<24)) 
-- WINcolor = (((math.floor(blue*wa))&0xFF)|(((math.floor(green*wa))&0xFF)<<8)|(((math.floor(red*wa))&0xFF)<<16)|(0x01<<24))

local ceil = math.ceil
local floor = math.floor
local midiview = nil
local GetMousePos = r.GetMousePosition
local ScreenToClient = r.JS_Window_ScreenToClient
local GetMouseCursorContext_Pos = r.BR_GetMouseCursorContext_Position
local GetTake = r.MIDIEditor_GetTake
local GetScrollInfo = r.JS_Window_GetScrollInfo
local GetSetting = r.MIDIEditor_GetSetting_int
local Composite = r.JS_Composite
local GetActive = r.MIDIEditor_GetActive
local GetGrid = r.MIDI_GetGrid
local Window_Find = r.JS_Window_Find
local Unlink = r.JS_Composite_Unlink
local x,y,X_, Y_, X, Y, snap ,note_length ,dotted_pos_round,dotted_pos_round_ ,bpm,bpm_,box_x1
local swing, swing_, gridvalue_, gridvalue ,noteLen ,noteLen_ ,timepos,new_width ,QN_
local take, measure,NN, QN, NN_round,NN_round_,snap,subdiv_round,subdiv,subdiv_leftover,dotted,measure_leftover ,dotted_pos, segment ,redraw 
local H_zoom2,H_zoom2_,HORZ,H_scroll,H_scroll_,H_zoom,H_zoom_,ratio,NN_leftover,suddiv_leftover
local bitmap = r.JS_LICE_CreateBitmap(true, 1, 1)
local box = r.JS_LICE_FillRect(bitmap, 0, 0, 1, 1, Color, Transparancy, "ADD") -- no alpha mode
 
 
local function round(n)
    return n % 1 >= 0.5 and ceil(n) or floor(n)
end

local re = 0
local function draw()
    re = re + 1
    local boxx1, y_c = ScreenToClient(midiview, box_x1, y)
    --  local  _, prevMinTime, prevMaxTime, prevBitmaps = r.JS_Composite_Delay(midiview, 0.01, 0.01, 100)

    Composite(midiview, boxx1, y_c, note_length, -1, bitmap, 0, 0, 1, 1, true)
end

local function main()
    midiview = Window_Find("midiview", false)

    x, y = GetMousePos()
    _, segment = GetMouseCursorContext()

    timepos = GetMouseCursorContext_Pos()
    -- get som gridinfo

    local hwnd = GetActive()
    if hwnd then
        noteLen_ = noteLen or 0
        gridvalue_ = gridvalue or 0
        swing_ = swing or 0
        take = GetTake(hwnd)

        --   pcall(function()

        gridvalue, swing, noteLen = GetGrid(take)
        --   end)

        snap = GetSetting(hwnd, "snap_enabled")
    end
    if segment == "notes" or segment == "cc_lane" then
        X_, Y_ = X, Y
        X, Y = ScreenToClient(midiview, x, y)
        -- update conditions
        if gridvalue_ ~= gridvalue then
            redraw = true
        end
        if noteLen_ ~= noteLen then
            redraw = true
        end
        if swing_ ~= swing then
            redraw = true
        end
        if snap == 0 then
            redraw = true
        end
        ---------------------------------------------  
        QN_ = QN
        QN = timeToQN(0, timepos)
        measure = QN / 4
        measure_leftover = measure - floor(measure)

        if X_ and X and QN_ and QN and X_ ~= X and QN_ ~= QN then
            ratio = (X_ - X) / (QN_ - QN)
        end

        subdiv = 4 / gridvalue

        subdiv_round = floor(subdiv)
        subdiv_leftover = subdiv - subdiv_round

        dotted_pos = subdiv * measure_leftover

        if subdiv_leftover ~= 0 then
            dotted = true
        else
            dotted = false
        end

        if gridvalue == 32 / 3 then
            gridvalue = 8
        end

        if gridvalue == 64 / 3 then
            gridvalue = 16
        end

        if gridvalue == 128 / 3 then
            gridvalue = 32
        end

        NN = QN / gridvalue
        NN_round_ = NN_round or 0
        NN_round = floor(NN)
        if NN_round_ ~= NN_round then -- update condition
            redraw = true
        end
        NN_leftover = NN - NN_round

        if dotted and gridvalue <= 6 then
            dotted_pos_round_ = dotted_pos_round or 0
            dotted_pos_round = floor(dotted_pos)
            if dotted_pos_round_ ~= dotted_pos_round then -- update condition
                redraw = true
            end
            NN_leftover = dotted_pos - dotted_pos_round
        end

        -- some crazy special case   --  grid : 1  triplet
        if gridvalue == 8 / 3 and swing == 0 then
            swing = 0.64 -- rs = 0.66 
            gridvalue = 2
            NN = QN / gridvalue
            nutcase = true
        end

        if swing ~= 0 then
            mouse_pos = NN / 2
            rs = 2 - swing -- 1--3
            rs = 1 - rs / 4
            leftover = mouse_pos - floor(mouse_pos)
            sone_ = sone or sone
            if leftover < rs then
                sone = 1
                position_in_swing = leftover / rs
                NN_leftover = position_in_swing
            else
                sone = 2
                position_in_swing = (leftover - rs) / (1 - rs)
                NN_leftover = position_in_swing
            end
            if sone_ ~= sone then
                redraw = true
            end
        end
    end
    if gridvalue then
        if ratio then
            new_width = ratio * gridvalue
            if swing ~= 0 then
                new_width = ratio * gridvalue * 2
                if sone == 1 then
                    new_width = new_width * rs
                end
                if sone == 2 then
                    new_width = new_width * (1 - rs)
                end
            end
        end
    end

    if gridvalue and timepos then
        if gridvalue >= 4 and swing ~= 0 then
            timepos = -1
        end
        if ratio then
            box_x1 = x - NN_leftover * new_width
            if noteLen ~= 0 then
                note_length = ratio * noteLen
            else
                note_length = new_width
            end
            if segment ~= "notes" and segment ~= "cc_lane" then
                redraw = false
            end

            if nutcase then
                if sone == 2 then
                    note_length = note_length * 2
                    nutcase = false
                end
            end

            if dotted and gridvalue == 6 then
                note_length = note_length / 1.5
                redraw = true
            end

            if gridvalue == 16 / 3 then
                note_length = note_length * 0.75
                redraw = true
            end

            if snap == 0 then
                box_x1 = x
            end
            box_x1 = round(box_x1)
            note_length = round(note_length)
            if redraw == true then
                --  pcall(function()
                draw()
                --   end)
                redraw = false
            end
        else
            -- unlink = unlink + 1
            Unlink(midiview, bitmap)
        end
    end
    if segment ~= "notes" and segment ~= "cc_lane" then
        Unlink(midiview, bitmap)
    end

    H_zoom_ = H_zoom or 0
    H_zoom2_ = H_zoom2 or 0
    H_scroll_ = H_scroll or 0

    HORZ = {GetScrollInfo(midiview, "HORZ")}

    H_zoom = HORZ[3]
    H_zoom2 = HORZ[5]
    H_scroll = HORZ[2]
    bpm_ = bpm or 0
    -- bpm = r.TimeMap2_GetDividedBpmAtTime(0, timepos)

    bpm = GetBpmAtTime(0, timepos)
    if H_zoom ~= H_zoom_ or H_scroll ~= H_scroll_ or H_zoom2 ~= H_zoom2_ or bpm ~= bpm_ then
        Unlink(midiview, bitmap)
        X_, X, QN, QN_ = nil, nil, nil, nil
        redraw = false
    end
    --    end
    r.defer(main)
end
 
function exit()
    Unlink(midiview, bitmap)
    r.JS_LICE_DestroyBitmap(bitmap)
    local bs = r.SetToggleCommandState(sectionID, ({r.get_action_context()})[4], 0)
end

r.atexit(function()
    exit()
end)

main()

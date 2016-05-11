_addon.name = 'Gaze_check'
_addon.author = 'smd111/Kenshi'
_addon.command = 'gazecheck'
_addon.commands = {'gzc'}
_addon.version = '1.01'

require 'luau'
require('vectors')
packets = require('packets')

defaults = {}
defaults.auto_point = false
defaults.gaze_watch = true
defaults.perm_gaze_watch = false

settings = config.load(defaults)

gaze_attacks = {[284]="Cold Stare",[292]="Blank Gaze",[370]="Baleful Gaze",[386]="Awful Eye",[411]="Baleful Gaze",[438]="Hex Eye",[439]="Petro Gaze",
[502]="Mortal Ray",[550]="Hypnosis",[551]="Mind Break",[577]="Jettatura",[586]="Blank Gaze",[589]="Mortal Ray",[648]="Petro Eyes",[653]="Chaotic Eye",
[785]="Light of Penance",[1111]="Numbing Glare",[1113]="Tormentful Glare",[1115]="Torpid Glare",[1138]="Hypnosis",[1139]="Mind Break",[1174]="Petro Eyes",
[1184]="Petro Eyes",[1322]="Gerjis' Grip",[1359]="Chthonian Ray",[1360]="Apocalyptic Ray",[1563]="Cold Stare",[1603]="Baleful Gaze",[1680]="Predatory Glare",
[1713]="Yawn",[1759]="Hypnotic Sway",[1762]="Belly Dance",[1862]="Awful Eye",[1883]="Mortal Ray",[1950]="Belly Dance",[2111]="Eternal Damnation",
[2155]="Torpefying Charge",[2209]="Blink of Peril",[2424]="Terror Eye",[2534]="Minax Glare",[2570]="Afflicting Gaze",[2768]="Deathly Glare",[2814]="Yawn",[2828]="Jettatura",
[3031]="Sylvan Slumber",[3032]="Crushing Gaze",[3358]="Blank Gaze",[3760]="Beguiling Gaze",[3898]="Chaotic Eye",[3916]="Jettatura",[4036]="Mortal Ray"}

perm_gaze_attacks = {[2156]="Grim Glower",[2392]="Oppressive Glare",[2776]="Shah Mat",}

gaze = false
perm_gaze = false
trigered_actor = 0
perm_trigered_actor = 0
mob_type = ""
function Print_Settings()
    print('Gaze_check - auto_point = '..(settings.auto_point and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255))..
        ' / auto_gaze = '..(settings.gaze_watch and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255))..
        ' / auto_perm_gaze = '..(settings.perm_gaze_watch and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255)))
end
windower.register_event('load',function ()
    Print_Settings()
end)
function pet_check(packet)
    local actor = windower.ffxi.get_mob_by_id(packet['Actor'])
    if actor.index > 1024 then
        return true
    end
    return false
end
function check_target_id(packet) --checks to see if player is one of the targets
    for i,v in pairs(packet) do
        if string.match(i, 'Target %d+ ID') then
            if windower.ffxi.get_player().id == v then
                return true
            end
        end
    end
    return false
end
function check_facing(packet)
    local actor = windower.ffxi.get_mob_by_id(packet['Actor'])
    local player = windower.ffxi.get_mob_by_target('me')
    local dir_actor = V{player.x, player.y} - V{actor.x, actor.y}
    local dir_player = V{actor.x, actor.y} - V{player.x, player.y}
    local player_heading = V{}.from_radian(player.facing)
    local actor_heading = V{}.from_radian(actor.facing)
    local player_angle = V{}.angle(dir_player, player_heading):degree():abs()
    local actor_angle = V{}.angle(dir_actor, actor_heading):degree():abs()
    if player_angle < 90 and actor_angle < 90 then
        return true
    end
    return false
end
function permGazeTrue()
    perm_gaze = true
end
function check_target_action(packet)
    for i,v in pairs(packet) do
        if string.match(i, 'Target %d+ Action %d+ Param') then
            if settings.gaze_watch and gaze_attacks[v] then
                return true
            elseif settings.perm_gaze_watch and perm_gaze_attacks[v] then
                if T{2156, 2392}:contains(v) then
                    mob_type = "Peiste"
                    coroutine.schedule(permGazeTrue, 3)
                elseif T{2776}:contains(v) then
                    mob_type = "Caturae"
                    coroutine.schedule(permGazeTrue, 6)
                end
                return true
            end
        end
    end
    return false
end
windower.register_event('incoming chunk', function(id, data, modified, injected, blocked)
    if id == 0x00E and settings.perm_gaze_watch and perm_gaze then
        local packet = packets.parse('incoming', data)
        if packet.Index == perm_trigered_actor then
            local effect = data:unpack('b8', 43)
            if mob_type == "Peiste" and (data:unpack('b8', 43) == 4 or packet['Mask'] == 0x20) then
                gaze = false
                perm_gaze = false
                perm_trigered_actor = 0
                mob_type = ""
                windower.ffxi.turn:schedule(1,windower.ffxi.get_mob_by_target('t').facing+math.pi)
            elseif mob_type == "Caturae" and (data:unpack('b8', 43) == 4 or data:unpack('b8', 43) == 6 or packet['Mask'] == 0x20) then
                gaze = false
                perm_gaze = false
                perm_trigered_actor = 0
                mob_type = ""
                windower.ffxi.turn:schedule(1,windower.ffxi.get_mob_by_target('t').facing+math.pi)
            end
        end
    end
    if id == 0x028 then
        local packet = packets.parse('incoming', data)
        if windower.ffxi.get_player().in_combat and windower.ffxi.get_mob_by_target('t') then
            if packet['Category'] == 7 and not pet_check(packet) and (check_target_id(packet) or check_facing(packet)) and check_target_action(packet) then
                gaze = true
                trigered_actor = packet['Actor']
                windower.ffxi.turn(windower.ffxi.get_mob_by_id(packet['Actor']).facing)
            elseif packet['Actor'] == trigered_actor and packet['Category'] == 11 and gaze then
                if settings.gaze_watch and gaze_attacks[packet['Param']] then
                    gaze = false
                    trigered_actor = 0
                    if not perm_gaze then
                        windower.ffxi.turn:schedule(1,windower.ffxi.get_mob_by_target('t').facing+math.pi)
                    end
                elseif settings.perm_gaze_watch and perm_gaze_attacks[packet['Param']] then
                    local actor_index = windower.ffxi.get_mob_by_id(packet['Actor']).index
                    trigered_actor = 0
                    perm_trigered_actor = actor_index
                end
            end
        end
    end
end)

function getAngle()
    local Px = windower.ffxi.get_mob_by_target('me').x --gets player x pos
    local Py = windower.ffxi.get_mob_by_target('me').y --gets player y pos
    local Mx = windower.ffxi.get_mob_by_target('t').x --gets target x pos
    local My = windower.ffxi.get_mob_by_target('t').y --gets target y pos
    local deltaY = Py - My --subtracts target y pos from player y pos
    local deltaX = Px - Mx --subtracts target x pos from player x pos
    local angleInDegrees = (math.atan2( deltaY, deltaX) * 180 / math.pi)*-1 
    local mult = 10^0
    return math.floor(angleInDegrees * mult + 0.5) / mult
end

windower.register_event('prerender', function()
    if not windower.ffxi.get_info().logged_in or not windower.ffxi.get_player() then -- stops prender if not loged in yet
        return
    end
    if (windower.ffxi.get_player().in_combat and settings.auto_point and windower.ffxi.get_mob_by_target('t')) and not gaze and not perm_gaze then
        windower.ffxi.turn((getAngle()+180):radian())--gets angle to the target
    end
end)

windower.register_event('addon command', function(command)
    if command == 'auto_point' then
        settings.auto_point = not settings.auto_point
    elseif command == 'auto_gaze' then
        settings.gaze_watch = not settings.gaze_watch
    elseif command == 'auto_perm_gaze' then
        settings.perm_gaze_watch = not settings.perm_gaze_watch
    end
    if command then
        Print_Settings()
        config.save(settings, 'all')
    end
end)
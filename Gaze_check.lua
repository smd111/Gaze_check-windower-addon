_addon.name = 'Gaze_check'
_addon.author = 'smd111/Kenshi'
_addon.command = 'gazecheck'
_addon.commands = {'gzc'}
_addon.version = '2.03'

require 'luau'
require('vectors')
packets = require('packets')

defaults = {auto_point = false,auto_gaze = true,auto_perm_gaze = false}

settings = config.load(defaults)

gaze_attacks = {[284]="Cold Stare",[292]="Blank Gaze",[370]="Baleful Gaze",[386]="Awful Eye",[411]="Baleful Gaze",[438]="Hex Eye",[439]="Petro Gaze",
[502]="Mortal Ray",[550]="Hypnosis",[551]="Mind Break",[577]="Jettatura",[586]="Blank Gaze",[589]="Mortal Ray",[648]="Petro Eyes",[653]="Chaotic Eye",
[785]="Light of Penance",[1111]="Numbing Glare",[1113]="Tormentful Glare",[1115]="Torpid Glare",[1138]="Hypnosis",[1139]="Mind Break",[1174]="Petro Eyes",
[1184]="Petro Eyes",[1322]="Gerjis' Grip",[1359]="Chthonian Ray",[1360]="Apocalyptic Ray",[1563]="Cold Stare",[1603]="Baleful Gaze",[1680]="Predatory Glare",
[1694]="Vile Belch",[1695]="Hypnic Lamp",[1713]="Yawn",[1716]="Frigid Shuffle",[1759]="Hypnotic Sway",[1762]="Belly Dance",[1862]="Awful Eye",[1883]="Mortal Ray",
[1950]="Belly Dance",[1978]="Abominable Belch",[2111]="Eternal Damnation",[2155]="Torpefying Charge",[2209]="Blink of Peril",[2424]="Terror Eye",[2466]="Washtub",
[2570]="Afflicting Gaze",[2534]="Minax Glare",[2610]="Vacant Gaze",[2768]="Deathly Glare",[2814]="Yawn",[2817]="Frigid Shuffle",[2828]="Jettatura",
[3031]="Sylvan Slumber",[3032]="Crushing Gaze",[3358]="Blank Gaze",[3760]="Beguiling Gaze",[3898]="Chaotic Eye",[3916]="Jettatura",}

perm_gaze_attacks = {[2156]="Grim Glower",[2392]="Oppressive Glare",[2776]="Shah Mat",}
perm_gaze_control = {["Peiste"]={skills=T{2156, 2392},delay=3,ender=T{4}},["Caturae"]={skills=T{2776},delay=6,ender=T{4,6}},}

gaze,perm_gaze,test_mode,trigered_actor,perm_trigered_actor,mob_type = false,false,false,0,0,""

function Print_Settings()
    print('Gaze_check: auto_gaze = '..(settings.auto_gaze and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255))..
        ' / auto_perm_gaze = '..(settings.auto_perm_gaze and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255))..
        '\n            auto_point = '..(settings.auto_point and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255))..
        ' / test_mode = '..(test_mode and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255)))
end
windower.register_event('load',function ()
    Print_Settings()
end)
function pet_check(index)
    local actor = windower.ffxi.get_mob_by_id(index)
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
    local key_indices = {'p0','p1','p2','p3','p4','p5','a10','a11','a12','a13','a14','a15','a20','a21','a22','a23','a24','a25'}
    local party = windower.ffxi.get_party()
    local actor = windower.ffxi.get_mob_by_id(packet['Actor'])
    local player = windower.ffxi.get_mob_by_target('me')
    local dir = {actor=(V{player.x, player.y} - V{actor.x, actor.y}),player=(V{actor.x, actor.y} - V{player.x, player.y})}
    local heading = {actor=(V{}.from_radian(actor.facing)),player=(V{}.from_radian(player.facing))}
    local angle = {actor=(V{}.angle(dir.actor, heading.actor):degree():abs()),player=(V{}.angle(dir.player, heading.player):degree():abs())}
    for i,v in pairs(packet) do
        if string.match(i, 'Target %d+ ID') then
            local index = windower.ffxi.get_mob_by_id(v).index
            for k = 1, 18 do
                local member = party[key_indices[k]]
                if member and member.mob and (member.mob.id == v or member.mob.pet_index == index) or actor.id == v then
                    for ind, val in pairs(packet) do  
                        if angle.player < 90 and angle.actor < 90 then
                            return true     
                        elseif string.match(ind, 'Target %d+ Action %d+ Param') then --Turn on gazes than don't need the mob to face you to apply
                            if T{1694, 1695, 1713, 1716, 1762, 1950, 1978, 2155, 2814, 2817}:contains(val) and angle.player < 90 then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end
function permGazeTrue()
    perm_gaze = true
end
function check_target_action(packet)
    for i,v in pairs(packet) do
        if string.match(i, 'Target %d+ Action %d+ Param') then
            if settings.auto_gaze and gaze_attacks[v] then
                return true
            elseif settings.auto_perm_gaze and perm_gaze_attacks[v] then
                for mob,tbl in pairs(perm_gaze_control) do
                    if tbl.skills:contains(v) then
                        mob_type = mob
                        coroutine.schedule(permGazeTrue, tbl.delay)
                        break
                    end
                end
                return true
            elseif test_mode then
                windower.add_to_chat(7,"Mob ability ID = "..tostring(v))
            end
        end
    end
    return false
end
windower.register_event('incoming chunk', function(id, data, modified, injected, blocked)
    if id == 0x00E and settings.auto_perm_gaze and perm_gaze then
        local packet = packets.parse('incoming', data)
        if packet.Index == perm_trigered_actor then
            local gaze_table = perm_gaze_control[mob_type]
            if gaze_table and (gaze_table.ender:contains(data:unpack('b8', 43)) or packet['Mask'] == 0x20) then
                gage,perm_gaze,perm_trigered_actor,mob_type = false,false,0,""
                windower.ffxi.turn:schedule(1,(getAngle()+180):radian())
            elseif test_mode then
                windower.add_to_chat(7,"Perm Gaze end data = "..tostring(data:unpack('b8', 43)))
            end
        end
    end
    if id == 0x028 then
        local packet = packets.parse('incoming', data)
        if windower.ffxi.get_player().in_combat and windower.ffxi.get_mob_by_target('t') then
            if packet['Category'] == 7 and not pet_check(packet['Actor']) and (check_target_id(packet) or check_facing(packet)) and check_target_action(packet) then
                gaze = true
                trigered_actor = packet['Actor']
                windower.ffxi.turn((getAngle(packet['Actor'])+180):radian()+math.pi)
            elseif packet['Category'] == 11 and packet['Actor'] == trigered_actor and gaze then
                if settings.auto_gaze and gaze_attacks[packet['Param']] and not perm_gaze then
                    gaze = false
                    windower.ffxi.turn:schedule(1,(getAngle()+180):radian())
                elseif settings.auto_perm_gaze and perm_gaze_attacks[packet['Param']] then
                    perm_trigered_actor = windower.ffxi.get_mob_by_id(packet['Actor']).index
                end
                trigered_actor = 0
            end
        end
    end
end)
function getAngle(index)
    local P = windower.ffxi.get_mob_by_target('me') --get player
    local M = index and windower.ffxi.get_mob_by_id(index) or windower.ffxi.get_mob_by_target('t') --get target
    local delta = {Y = (P.y - M.y),X = (P.x - M.x)} --subtracts target pos from player pos
    local angleInDegrees = (math.atan2( delta.Y, delta.X) * 180 / math.pi)*-1 
    local mult = 10^0
    return math.floor(angleInDegrees * mult + 0.5) / mult
end
windower.register_event('prerender', function()
    local player = windower.ffxi.get_player()
    if not windower.ffxi.get_info().logged_in or not player then -- stops prender if not loged in yet
        return
    end
    if (player.in_combat and settings.auto_point and windower.ffxi.get_mob_by_target('t')) and not gaze and not perm_gaze then
        windower.ffxi.turn((getAngle()+180):radian())--gets angle to the target
    end
end)
windower.register_event('addon command', function(command)
    if type(settings[command]) == 'boolean' then
        settings[command] = not settings[command]
    elseif command == 'test_mode' then
        test_mode = not test_mode
    end
    if command then
        Print_Settings()
        config.save(settings, 'all')
    end
end)
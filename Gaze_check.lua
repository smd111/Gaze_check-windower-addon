_addon.name = 'Gaze_check'
_addon.author = 'smd111'
_addon.command = 'gazecheck'
_addon.commands = {'gzc'}
_addon.version = '1.01'
require 'luau'
packets = require('packets')

defaults = {}
defaults.auto_point = false
defaults.gaze_watch = true

settings = config.load(defaults)_addon.name = 'Gaze_check'
_addon.author = 'smd111'
_addon.command = 'gazecheck'
_addon.commands = {'gzc'}
_addon.version = '1.01'

require 'luau'
packets = require('packets')

defaults = {}
defaults.auto_point = false
defaults.gaze_watch = true

settings = config.load(defaults)

gaze_attacks = {"Chaotic Eye","Blink of Peril","Cold Stare","Gerjis's Grip","Predatory Glare","Awful Eye","Baleful Gaze","Torpefying Charge","Blank Gaze",
"Hex Eye","Petrogaze","Yawn","Baleful Gaze","Jettatura","Eternal Damnation","Afflicting Gaze","Shah Mat","Hypnosis","Mind Break","Terror Eye",
"Mortal Ray","Chthonian Ray","Apocalyptic Ray","Petro Eyes","Belly Dance","Hypnotic Sway","Light of Penance","Numbing Glare","Tormentful Glare",
"Torpid Glare","Torpefying Charge",}

gaze = false
trigered_actor = 0
windower.register_event('load',function ()
    print('Gaze_check - auto_point = '..(settings.auto_point and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255))..
        ' / auto_gaze = '..(settings.gaze_watch and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255)))
end)

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
function check_target_action(packet)
    for i,v in pairs(packet) do
        if string.match(i, 'Target %d+ Action %d+ Param') and table.contains(gaze_attacks,res.monster_abilities[v].en) then
            return true
        end
    end
    return false
end
windower.register_event('incoming chunk', function(id, data, modified, injected, blocked)
    if id == 0x028 then
        local packet = packets.parse('incoming', data)
        if windower.ffxi.get_player().in_combat and windower.ffxi.get_mob_by_target('t')then
            if packet['Category'] == 7 and check_target_id(packet) and settings.gaze_watch then
                if check_target_action(packet) then
                    gaze = true
                    trigered_actor = packet['Actor']
                    windower.ffxi.turn(windower.ffxi.get_mob_by_id(packet['Actor']).facing)
                end
            elseif packet['Actor'] == trigered_actor and packet['Category'] == 11 and settings.gaze_watch then
                if table.contains(gaze_attacks,res.monster_abilities[packet['Param']].en) then
                    gaze = false
                    trigered_actor = 0
                    windower.ffxi.turn(windower.ffxi.get_mob_by_target('t').facing+math.pi)
                end
            end
        end
    end
end)

function getAngle(x1,y1,x2,y2)
    local deltaY = y2 - y1
    local deltaX = x2 - x1

    local angleInDegrees = (math.atan2( deltaY, deltaX) * 180 / math.pi)*-1

    local mult = 10^0

    return math.floor(angleInDegrees * mult + 0.5) / mult
end

windower.register_event('prerender', function()
    if not windower.ffxi.get_info().logged_in or not windower.ffxi.get_player() then
        return
    end
    if windower.ffxi.get_player().in_combat and settings.auto_point and windower.ffxi.get_mob_by_target('t') and not gaze then
        local Px = windower.ffxi.get_mob_by_target('me').x
        local Py = windower.ffxi.get_mob_by_target('me').y
        local Mx = windower.ffxi.get_mob_by_target('t').x
        local My = windower.ffxi.get_mob_by_target('t').y
        windower.ffxi.turn((getAngle(Mx,My,Px,Py)+180):radian())--gets angle to the target
    end
end)

windower.register_event('addon command', function(command)
    if command == 'auto_point' then
        settings.auto_point = not settings.auto_point
    elseif command == 'auto_gaze' then
        settings.auto_point = not settings.gaze_watch
    end
    print('Gaze_check - auto_point = '..(settings.auto_point and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255))..
        ' / auto_gaze = '..(settings.gaze_watch and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255)))
    config.save(settings, 'all')
end)


gaze_attacks = {"Chaotic Eye","Blink of Peril","Cold Stare","Gerjis's Grip","Predatory Glare","Awful Eye","Baleful Gaze","Torpefying Charge","Blank Gaze",
"Hex Eye","Petrogaze","Yawn","Baleful Gaze","Jettatura","Eternal Damnation","Afflicting Gaze","Shah Mat","Hypnosis","Mind Break","Terror Eye",
"Mortal Ray","Chthonian Ray","Apocalyptic Ray","Petro Eyes","Belly Dance","Hypnotic Sway","Light of Penance","Numbing Glare","Tormentful Glare",
"Torpid Glare",'Torpefying Charge',}

gaze = false
trigered_actor = 0
windower.register_event('load',function ()
    print('Gaze_check - auto_point = '..(settings.auto_point and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255))..
        ' / auto_gaze = '..(settings.gaze_watch and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255)))
end)

function check_target_id(packet)
    for i,v in pairs(packet) do
        if i:startswith('Target') and i:endswith('ID') then
            if windower.ffxi.get_player().id == v then
                return true
            end
        end
    end
    return false
end
windower.register_event('incoming chunk', function(id, data, modified, injected, blocked)
    if id == 0x028 then
        local packet = packets.parse('incoming', data)
        if windower.ffxi.get_player().in_combat and windower.ffxi.get_mob_by_target('t')then
            if packet['Category'] == 7 and check_target_id(packet) and settings.gaze_watch then
                if table.contains(gaze_attacks,res.monster_abilities[packet['Target 1 Action 1 Param']].en) then
                    gaze = true
                    trigered_actor = packet['Actor']
                    windower.ffxi.turn(windower.ffxi.get_mob_by_id(packet['Actor']).facing)
                end
            elseif packet['Actor'] == trigered_actor and packet['Category'] == 11 and settings.gaze_watch then
                if table.contains(gaze_attacks,res.monster_abilities[packet['Param']].en) then
                    gaze = false
                    windower.ffxi.turn(windower.ffxi.get_mob_by_target('t').facing+math.pi)
                end
            end
        end
    end
end)

function getAngle(x1,y1,x2,y2)
    local deltaY = y2 - y1
    local deltaX = x2 - x1

    local angleInDegrees = (math.atan2( deltaY, deltaX) * 180 / math.pi)*-1

    local mult = 10^0

    return math.floor(angleInDegrees * mult + 0.5) / mult
end
windower.register_event('prerender', function()
    if not windower.ffxi.get_info().logged_in or not windower.ffxi.get_player() then
        return
    end
    if windower.ffxi.get_player().in_combat and settings.auto_point and windower.ffxi.get_mob_by_target('t') and not gaze then
        local Px = windower.ffxi.get_mob_by_target('me').x
        local Py = windower.ffxi.get_mob_by_target('me').y
        local Mx = windower.ffxi.get_mob_by_target('t').x
        local My = windower.ffxi.get_mob_by_target('t').y
        windower.ffxi.turn((getAngle(Mx,My,Px,Py)+180):radian())
    end
end)

windower.register_event('addon command', function(command)
    if command == 'auto_point' then
        settings.auto_point = not settings.auto_point
    elseif command == 'auto_gaze' then
        settings.auto_point = not settings.gaze_watch
    end
    print('Gaze_check - auto_point = '..(settings.auto_point and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255))..
        ' / auto_gaze = '..(settings.gaze_watch and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255)))
    config.save(settings, 'all')
end)

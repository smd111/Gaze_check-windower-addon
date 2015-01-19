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

settings = config.load(defaults)

gaze_attacks = {"Chaotic Eye","Blink of Peril","Cold Stare","Gerjis's Grip","Predatory Glare","Awful Eye","Baleful Gaze","Torpefying Charge","Blank Gaze",
"Hex Eye","Petrogaze","Yawn","Baleful Gaze","Jettatura","Eternal Damnation","Afflicting Gaze","Shah Mat","Hypnosis","Mind Break","Terror Eye",
"Mortal Ray","Chthonian Ray","Apocalyptic Ray","Petro Eyes","Belly Dance","Hypnotic Sway","Light of Penance","Numbing Glare","Tormentful Glare",
"Torpid Glare"}

gaze = false

windower.register_event('load',function ()
    print('auto_point = '..(settings.auto_point and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255))..
        ' / auto_gaze = '..(settings.gaze_watch and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255)))
end)

windower.register_event('incoming chunk', function(id, data, modified, injected, blocked)
    if id == 0x028 then
        local packet = packets.parse('incoming', data)
        if windower.ffxi.get_player().in_combat and windower.ffxi.get_mob_by_target('t')then
            tid = windower.ffxi.get_mob_by_target('t').id
            dir = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().index).heading
            if packet['Actor'] == tid and packet['Category'] == 7 and windower.ffxi.get_player().id == packet['Target 1 ID'] and settings.gaze_watch then
                if table.contains(gaze_attacks,res.monster_abilities[packet['Target 1 Action 1 Param']].en) then
                    gaze = true
                    windower.ffxi.turn(windower.ffxi.get_mob_by_target('t').facing)
                end
            elseif packet['Actor'] == tid and packet['Category'] == 11 and windower.ffxi.get_player().id == packet['Target 1 ID'] and settings.gaze_watch then
                if table.contains(gaze_attacks,res.monster_abilities[packet['Param']].en) then
                    gaze = false
                    windower.ffxi.turn(windower.ffxi.get_mob_by_target('t').facing+math.pi)
                end
            end
        end
    end
end)

windower.register_event('prerender', function()
    if not windower.ffxi.get_info().logged_in or not windower.ffxi.get_player() then
        return
    end
    if windower.ffxi.get_player().in_combat and settings.auto_point and windower.ffxi.get_mob_by_target('t') 
    and windower.ffxi.get_mob_by_target('t').claim_id == windower.ffxi.get_player().id and not gaze then
        windower.ffxi.turn(windower.ffxi.get_mob_by_target('t').facing+math.pi)
    elseif windower.ffxi.get_player().in_combat and settings.auto_point and windower.ffxi.get_mob_by_target('t') 
    and windower.ffxi.get_mob_by_target('t').claim_id == windower.ffxi.get_player().id and gaze then
        windower.ffxi.turn(windower.ffxi.get_mob_by_target('t').facing)
    end
end)

windower.register_event('addon command', function(command)
    if command == 'auto_point' then
        settings.auto_point = not settings.auto_point
        print('Gaze_check will '..(settings.auto_point and '' or 'not ')..'automaticaly turn twards claimed mob.')
    elseif command == 'auto_gaze' then
        settings.auto_point = not settings.gaze_watch
        print('Gaze_check will '..(settings.gaze_watch and '' or 'not ')..'automaticaly turn away from mobs that use gaze attacks.')
    end
    print('auto_point = '..(settings.auto_point and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255))..
        ' / auto_gaze = '..(settings.gaze_watch and ('on'):text_color(0,255,0) or ('off'):text_color(255,255,255)))
    config.save(settings, 'all')
end)

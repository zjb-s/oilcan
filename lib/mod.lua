NUM_TIMBRES = 7

local mod = require 'core/mods'

if note_players == nil then
	note_players = {}
end

-- todo look into taking over grid temporarily to edit timbres
-- 

param_specs = {
	{
		id = 'freq'
	,	name = 'FREQ'
	,	min = 5
	,	max = 10000
	,	default = 115
	,	units = 'hz'
	},
	{
		id = 'sweep_time'
	,	name = 'SWEEP TIME'
	,	min = 0.001
	,	max = 100
	,	default = 0.10
	,	units = '%'
	},
	{
		id = 'sweep_ix'
	,	name = 'SWEEP INDEX'
	,	min = -1
	,	max = 1
	,	default = 0.04
	,	k = 0
	},
	{
		id = 'atk'
	,	name = 'ATTACK'
	,	min = 0
	,	max = 1
	,	default = 0
	,	units = 'sec'
	},
	{
		id = 'car_rel'
	,	name = 'RELEASE'
	,	min = 0.01
	,	max = 3
	,	default = 0.5
	,	units = 'sec'
	},
	{
		id = 'mod_rel'
	,	name = 'MODULATOR RELEASE'
	,	min = 0.1
	,	max = 200
	,	default = 100
	,	units = '%'
	},
	{
		id = 'mod_ix'
	,	name = 'MODULATOR LEVEL'
	,	min = 0
	,	max = 1
	,	default = 0
	},
	{
		id = 'mod_ratio'
	,	name = 'MODULATOR RATIO'
	,	min = 0.001
	,	max = 32
	,	default = 1
	},
	{
		id = 'fb'
	,	name = 'FEEDBACK'
	,	min = 0
	,	max = 10
	,	default = 0
	},
	{
		id = 'fold'
	,	name = 'FOLD'
	,	min = 0
	,	max = 100
	,	default = 0
	,	units = 'x'
	,	k = 6
	},
	{
		id = 'headroom'
	,	name = 'HEADROOM'
	,	min = 0.001
	,	max = 1
	,	default = 1
	},
	{
		id = 'gain'
	,	name = 'GAIN'
	,	min = 0
	,	max = 10
	,	default = 1
	,	units = 'x'
	},
	{
		id = 'routing'
	,	name = 'ROUTING'
	,	min = 0
	,	max = 1
	,	default = 0.1
	,	k = 0
	},	
	{
		id = 'level'
	,	name = 'LEVEL'
	,	min = 0
	,	max = 5
	,	default = 1
	,	units = 'x'
	}
}

oilcan_clipboard = {
	multipliers = {}
,	timbre = {}
}

function add_oilcan_player(player_num)
	local function n(s)
		return 'oilcan_'..s..'_'..player_num
	end

	local function oilcan_trig(timbre_num, velocity, mod)
		timbre_num = timbre_num and timbre_num or params:get(n('selected_timbre'))
		local msg = {}
		for k,v in ipairs(param_specs) do
			msg[k] = params:get(n(v.id..'_'..timbre_num))
			msg[k] = msg[k] * params:get(n(v.id..'_mult'))
			if v.id=='gain' then 
				msg[k] = msg[k] * velocity 
			elseif v.id=='mod_ix' and mod then
				-- print('mod is',mod)
				msg[k] = msg[k] + mod
			end
			msg[k] = util.clamp(msg[k],v.min,v.max)
			-- print(v.id, v.min, v.max, msg[k])
		end
		table.insert(msg,1,1)
		-- tab.print(msg)
		osc.send({'localhost',57120}, '/oilcan/trig', msg)
	end

	
	local function oilcan_save_kit(path)
		local r = {}
		local f = path and path or params:get(n('target_file'))
		if type(f) ~= 'string' then 
			print('oilcan: no file target selected!')
			return
		end
		for i=1,NUM_TIMBRES do
			table.insert(r,{})
			for _,v in ipairs(param_specs) do
				table.insert(r[i],params:get(n(v.id..'_'..i)))
			end
		end
		tab.save(r,f)
		print('saved kit to '..f)
	end

	local function oilcan_new_kit_file()
		local f
		for i=1,999 do
			f = '/home/we/dust/data/oilcan/oilkits/oilkit-'..i
			if not util.file_exists(f) then
				os.execute('touch '..f)
				params:set(n('target_file'), f)
				print('created '..f)
				break
			end
		end
	end

	local function oilcan_load_kit(path)
		local f = path and path or params:get(n('target_file'))
		if util.file_exists(f) then
			local r = tab.load(f)
			for i=1,NUM_TIMBRES do
				-- tab.print(r[i])
				for k,v in ipairs(param_specs) do
					-- print('setting',n(v.id..'_'..i),'to',r[i][k])
					params:set(n(v.id..'_'..i), r[i][k])
				end
			end
			print('loaded kit from '..f)
		else
			print('kit file '..f..' does not exist yet')
		end
	end

	local function add_oilcan_params()
		params:add_group(n('oilcan'), 'OILCAN #'..player_num, (NUM_TIMBRES+1)*#param_specs+12) -- keep an eye on this number
		params:add_number(n('selected_timbre'),'SELECTED TIMBRE',1,NUM_TIMBRES,1)
	
		for j=1,NUM_TIMBRES do
			for _,v in ipairs(param_specs) do
				params:add{
					id = n(v.id..'_'..j)
				,	name = string.upper(v.name)
				,	type = 'taper'
				,	min = v.min
				,	max = v.max
				,	default = v.default
				,	k = v.k and v.k or 4
				,	units = v.units and v.units or ''
				}
				params:hide(n(v.id..'_'..j))
			end
			-- params:hide('timbre '..i)
		end
	
		params:add_separator(n('MACROS'), 'MACROS')
		for _,v in ipairs(param_specs) do
			params:add{
				id = n(v.id..'_mult')
			,	name = string.upper('*'..v.name)
			,	type = 'taper'
			,	min = 0
			,	max = 10
			,	default = 1
			,	k = 5
			,	units = 'x'
			}
		end

		params:add_separator(n('OPTIONS'), 'OPTIONS')
		params:add_binary(n('trig'),'TRIG')
		params:set_action(n('trig'), function() 
			oilcan_trig(params:get(n('selected_timbre')), 1)
		end)
		params:add_binary(n('copy_multipliers'),'COPY MACROS')
		params:add_binary(n('paste_multipliers'),'PASTE MACROS')
		params:add_binary(n('copy_timbre'),'COPY TIMBRE')
		params:add_binary(n('paste_timbre'),'PASTE TIMBRE')
		params:add_file(n('target_file'),'OPEN', _path.data .. 'oilcan/default-1.oilkit')
		params:set_action(n('target_file'), oilcan_load_kit)
		params:add_binary(n('save_kit'),'SAVE')
		params:set_action(n('save_kit'), function() oilcan_save_kit() end)
		params:add_binary(n('load_kit'),'REVERT')
		params:set_action(n('load_kit'), function() oilcan_load_kit() end)
		params:add_binary(n('save_new'),'NEW')
		params:set_action(n('save_new'), function() oilcan_new_kit_file() end)
	
		params:set_action(n('copy_multipliers'),function()
			for _,v in ipairs(param_specs) do 
				oilcan_clipboard.multipliers[v.id] = params:get(n(v.id..'_mult')) 
			end
		end)
		params:set_action(n('paste_multipliers'),function()
			for _,v in ipairs(param_specs) do 
				params:set(n(v.id..'_mult'),oilcan_clipboard.multipliers[v.id]) 
			end
		end)
		params:set_action(n('copy_timbre'),function()
			for _,v in ipairs(param_specs) do 
				oilcan_clipboard.timbre[v.id] = params:get(n(v.id..'_'..params:get(n('selected_timbre'))))
			end
		end)
		params:set_action(n('paste_timbre'),function()
			for _,v in ipairs(param_specs) do 
				params:set(n(v.id..'_'..params:get(n('selected_timbre'))),oilcan_clipboard.timbre[v.id]) 
			end
		end)
		
		params:set_action(n("selected_timbre"), function()
			local t = params:get(n("selected_timbre"))
			for j=1,NUM_TIMBRES do
				for _,v in ipairs(param_specs) do
					if j == t then
						params:show(n(v.id..'_'..j))
					else
						params:hide(n(v.id..'_'..j))
					end
				end
			end
			_menu.rebuild_params()
		end)
		params:hide(n('oilcan'))
		params:lookup_param(n('load_kit')):bang()
		params:lookup_param(n('selected_timbre')):bang()
	end

	local player = {timbre_modulation = 0}

	function player:active()
        if self.name ~= nil then
            params:show(n('oilcan'))
            _menu.rebuild_params()
        end
    end

	function player:inactive()
        if self.name ~= nil then
            params:hide(n('oilcan'))
            _menu.rebuild_params()
        end
    end

	function player:modulate(v)
		self.timbre_modulation = v
	end

	function player:describe()
		return {
			name = 'Oilcan',
			supports_bend = false,
			supports_slew = false,
			modulate_description = 'modulator level',
			style = 'kit',
		}
	end

	function player:note_on(note, vel)
		-- print("note", note)
		local n = (note - 1) % 7 + 1
		local mod = self.timbre_modulation
		oilcan_trig(n,vel,mod)
	end

	function player:add_params()
        add_oilcan_params()
    end

	note_players['Oilcan '..player_num] = player
end

mod.hook.register('system_post_startup', 'oilcan setup', function()
	util.make_dir(_path.data .. 'oilcan')
	print("copying oilcan presets")
	os.execute('cp '.. _path.code .. 'oilcan/lib/*.oilkit '.. _path.data .. 'oilcan/')
end)

mod.hook.register('script_pre_init', 'oilcan pre init', function()
	for i=1,4 do add_oilcan_player(i) end
end)
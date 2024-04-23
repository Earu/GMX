local IGNORED_COMMANDS = {
	[0x80] = true, -- "NOTE_OFF",
	[0x90] = false, -- "NOTE_ON",
	[0xA0] = true, -- "AFTERTOUCH",
	[0xB0] = true, -- "CONTINUOUS_CONTROLLER",
	[0xC0] = false, -- "PATCH_CHANGE",
	[0xD0] = true, -- "CHANNEL_PRESSURE",
	[0xE0] = true, -- "PITCH_BEND",
	[0xF0] = true -- "SYSEX"
}

--
-->> https://en.wikipedia.org/wiki/General_MIDI
--
local INSTRUMENTS = {
	-- Piano
	[1] = "Acoustic Grand Piano",
	[2] = "Bright Acoustic Piano",
	[3] = "Electric Grand Piano",
	[4] = "Honky-tonk Piano",
	[5] = "Electric Piano 1",
	[6] = "Electric Piano 2",
	[7] = "Harpsichord",
	[8] = "Clavinet",
	-- Chromatic Percussion
	[9] = "Celesta",
	[10] = "Glockenspiel",
	[11] = "Music Box",
	[12] = "Vibraphone",
	[13] = "Marimba",
	[14] = "Xylophone",
	[15] = "Tubular Bells",
	[16] = "Dulcimer",
	-- Organ
	[17] = "Drawbar Organ",
	[18] = "Percussive Organ",
	[19] = "Rock Organ",
	[20] = "Church Organ",
	[21] = "Reed Organ",
	[22] = "Accordion",
	[23] = "Harmonica",
	[24] = "Bandoneon",
	-- Guitar -- In most synthesizer interpretations, guitar and bass sounds are set an octave lower than other INSTRUMENTS.
	[25] = "Acoustic Guitar (nylon)",
	[26] = "Acoustic Guitar (steel)",
	[27] = "Electric Guitar (jazz)",
	[28] = "Electric Guitar (clean)",
	[29] = "Electric Guitar (muted)",
	[30] = "Electric Guitar (overdrive)",
	[31] = "Electric Guitar (distortion)",
	[32] = "Electric Guitar (harmonics)",
	-- Bass
	[33] = "Acoustic Bass",
	[34] = "Electric Bass (finger)",
	[35] = "Electric Bass (picked)",
	[36] = "Electric Bass (fretless)",
	[37] = "Slap Bass 1",
	[38] = "Slap Bass 2",
	[39] = "Synth Bass 1",
	[40] = "Synth Bass 2",
	-- Strings
	[41] = "Violin",
	[42] = "Viola",
	[43] = "Cello",
	[44] = "Contrabass",
	[45] = "Tremolo Strings",
	[46] = "Pizzicato Strings",
	[47] = "Orchestral Harp",
	[48] = "Timpani",
	-- Ensemble
	[49] = "String Ensemble 1",
	[50] = "String Ensemble 2",
	[51] = "Synth Strings 1",
	[52] = "Synth Strings 2",
	[53] = "Choir Aahs",
	[54] = "Voice Oohs",
	[55] = "Synth Voice",
	[56] = "Orchestra Hit",
	-- Brass
	[57] = "Trumpet",
	[58] = "Trombone",
	[59] = "Tuba",
	[60] = "Muted Trumpet",
	[61] = "French Horn",
	[62] = "Brass Section",
	[63] = "Synth Brass 1",
	[64] = "Synth Brass 2",
	-- Reed
	[65] = "Soprano Sax",
	[66] = "Alto Sax",
	[67] = "Tenor Sax",
	[68] = "Baritone Sax",
	[69] = "Oboe",
	[70] = "English Horn",
	[71] = "Bassoon",
	[72] = "Clarinet",
	-- Pipe
	[73] = "Piccolo",
	[74] = "Flute",
	[75] = "Recorder",
	[76] = "Pan Flute",
	[77] = "Blown bottle",
	[78] = "Shakuhachi",
	[79] = "Whistle",
	[80] = "Ocarina",
	-- Synth Lead
	[81] = "Lead 1 (square)",
	[82] = "Lead 2 (sawtooth)",
	[83] = "Lead 3 (calliope)",
	[84] = "Lead 4 (chiff)",
	[85] = "Lead 5 (charang)",
	[86] = "Lead 6 (voice)",
	[87] = "Lead 7 (fifths)",
	[88] = "Lead 8 (bass + lead)",
	-- Synth Pad
	[89] = "Pad 1 (new age)",
	[90] = "Pad 2 (warm)",
	[91] = "Pad 3 (polysynth)",
	[92] = "Pad 4 (choir)",
	[93] = "Pad 5 (bowed glass)",
	[94] = "Pad 6 (metallic)",
	[95] = "Pad 7 (halo)",
	[96] = "Pad 8 (sweep)",
	-- Synth Effects
	[97] = "FX 1 (rain)",
	[98] = "FX 2 (soundtrack)",
	[99] = "FX 3 (crystal)",
	[100] = "FX 4 (atmosphere)",
	[101] = "FX 5 (brightness)",
	[102] = "FX 6 (goblins)",
	[103] = "FX 7 (echoes)",
	[104] = "FX 8 (sci-fi)",
	-- Ethnic
	[105] = "Sitar",
	[106] = "Banjo",
	[107] = "Shamisen",
	[108] = "Koto",
	[109] = "Kalimba",
	[110] = "Bag pipe",
	[111] = "Fiddle",
	[112] = "Shanai",
	-- Percussive
	[113] = "Tinkle Bell",
	[114] = "Agogo",
	[115] = "Steel Drums",
	[116] = "Woodblock",
	[117] = "Taiko Drum",
	[118] = "Melodic Tom",
	[119] = "Synth Drum",
	[120] = "Reverse Cymbal",
	-- Sound Effects
	[121] = "Guitar Fret Noise",
	[122] = "Breath Noise",
	[123] = "Seashore",
	[124] = "Bird Tweet",
	[125] = "Telephone Ring",
	[126] = "Helicopter",
	[127] = "Applause",
	[128] = "Gunshot",
}

--[[
local percussion = {
	[35] = "Acoustic Bass Drum",
	[36] = "Electric Bass Drum",
	[37] = "Side Stick",
	[38] = "Acoustic Snare",
	[39] = "Hand Clap",
	[40] = "Electric Snare",
	[41] = "Low Floor Tom",
	[42] = "Closed Hi-hat",
	[43] = "High Floor Tom",
	[44] = "Pedal Hi-hat",
	[45] = "Low Tom",
	[46] = "Open Hi-hat",
	[47] = "Low-Mid Tom",
	[48] = "High-Mid Tom",
	[49] = "Crash Cymbal 1",
	[50] = "High Tom",
	[51] = "Ride Cymbal 1",
	[52] = "Chinese Cymbal",
	[53] = "Ride Bell",
	[54] = "Tambourine",
	[55] = "Splash Cymbal",
	[56] = "Cowbell",
	[57] = "Crash Cymbal 2",
	[58] = "Vibraslap",
	[59] = "Ride Cymbal 2",
	[60] = "High Bongo",
	[61] = "Low Bongo",
	[62] = "Mute High Conga",
	[63] = "Open High Conga",
	[64] = "Low Conga",
	[65] = "High Timbale",
	[66] = "Low Timbale",
	[67] = "High Agogô",
	[68] = "Low Agogô",
	[69] = "Cabasa",
	[70] = "Maracas",
	[71] = "Short Whistle",
	[72] = "Long Whistle",
	[73] = "Short Guiro",
	[74] = "Long Guiro",
	[75] = "Claves",
	[76] = "High Woodblock",
	[77] = "Low Woodblock",
	[78] = "Mute Cuica",
	[79] = "Open Cuica",
	[80] = "Mute Triangle",
	[81] = "Open Triangle"
}
]]
--
-- https://drive.usercontent.google.com/download?id=1pdrxH7YZxiIZA_X-VfhjaC--vfDWAoRb&export=download&authuser=0
--
local Harp = "harp"
local Vibes = "iron xylophone"
local Vibes2 = "bell"
local Vibes3 = "xylobone"
local DoubleBass = "dbass"
local Guitar = "guitar"
local FluteAndVoice = "flute"
local Chimes = "icechime"
local SnareDrum = "sdrum"
local BassDrum = "bdrum"
local Synthesizer = "pling"
local Banjo = "banjo"
local Agogo = "cow bell"
local Bit = "bit"
local Didgeridoo = "didgeridoo"
local Sea = nil
local Blast = nil

local CHATSOUNDS_INSTRUMENTS = {
	-- Piano
	["Acoustic Grand Piano"] = Harp,
	["Bright Acoustic Piano"] = Harp,
	["Electric Grand Piano"] = Harp,
	["Honky-tonk Piano"] = Harp,
	["Electric Piano 1"] = Synthesizer,
	["Electric Piano 2"] = Synthesizer,
	["Harpsichord"] = Harp,
	["Clavinet"] = Harp,
	-- Chromatic Percussion
	["Celesta"] = Vibes2,
	["Glockenspiel"] = Vibes2,
	["Music Box"] = Chimes,
	["Vibraphone"] = Vibes,
	["Marimba"] = Vibes,
	["Xylophone"] = Vibes3,
	["Tubular Bells"] = Chimes,
	["Dulcimer"] = Guitar,
	-- Organ
	["Drawbar Organ"] = Harp,
	["Percussive Organ"] = Harp,
	["Rock Organ"] = Didgeridoo,
	["Church Organ"] = FluteAndVoice,
	["Reed Organ"] = FluteAndVoice,
	["Accordion"] = FluteAndVoice,
	["Harmonica"] = FluteAndVoice,
	["Bandoneon"] = FluteAndVoice,
	-- Guitar
	["Acoustic Guitar (nylon)"] = Guitar,
	["Acoustic Guitar (steel)"] = Guitar,
	["Electric Guitar (jazz)"] = Guitar,
	["Electric Guitar (clean)"] = Guitar,
	["Electric Guitar (muted)"] = Guitar,
	["Electric Guitar (overdrive)"] = Guitar,
	["Electric Guitar (distortion)"] = Guitar,
	["Electric Guitar (harmonics)"] = FluteAndVoice,
	-- Bass
	["Acoustic Bass"] = DoubleBass,
	["Electric Bass (finger)"] = DoubleBass,
	["Electric Bass (picked)"] = DoubleBass,
	["Electric Bass (fretless)"] = DoubleBass,
	["Slap Bass 1"] = DoubleBass,
	["Slap Bass 2"] = DoubleBass,
	["Synth Bass 1"] = DoubleBass,
	["Synth Bass 2"] = DoubleBass,
	-- Strings
	["Violin"] = FluteAndVoice,
	["Viola"] = FluteAndVoice,
	["Cello"] = FluteAndVoice,
	["Contrabass"] = FluteAndVoice,
	["Tremolo Strings"] = Harp,
	["Pizzicato Strings"] = Harp,
	["Orchestral Harp"] = Harp,
	["Timpani"] = BassDrum,
	-- Ensemble
	["String Ensemble 1"] = Harp,
	["String Ensemble 2"] = Harp,
	["Synth Strings 1"] = Synthesizer,
	["Synth Strings 2"] = Synthesizer,
	["Choir Aahs"] = FluteAndVoice,
	["Voice Oohs"] = FluteAndVoice,
	["Synth Voice"] = FluteAndVoice,
	["Orchestra Hit"] = Harp,
	-- Brass
	["Trumpet"] = Harp,
	["Trombone"] = Harp,
	["Tuba"] = Didgeridoo,
	["Muted Trumpet"] = Harp,
	["French Horn"] = Harp,
	["Brass Section"] = Harp,
	["Synth Brass 1"] = Synthesizer,
	["Synth Brass 2"] = Synthesizer,
	-- Reed
	["Soprano Sax"] = FluteAndVoice,
	["Alto Sax"] = FluteAndVoice,
	["Tenor Sax"] = FluteAndVoice,
	["Baritone Sax"] = Didgeridoo,
	["Oboe"] = FluteAndVoice,
	["English Horn"] = FluteAndVoice,
	["Bassoon"] = Didgeridoo,
	["Clarinet"] = FluteAndVoice,
	-- Pipe
	["Piccolo"] = FluteAndVoice,
	["Flute"] = FluteAndVoice,
	["Recorder"] = FluteAndVoice,
	["Pan Flute"] = FluteAndVoice,
	["Blown bottle"] = FluteAndVoice,
	["Shakuhachi"] = FluteAndVoice,
	["Whistle"] = FluteAndVoice,
	["Ocarina"] = FluteAndVoice,
	-- Synth Lead
	["Lead 1 (square)"] = Bit,
	["Lead 2 (sawtooth)"] = Bit,
	["Lead 3 (calliope)"] = FluteAndVoice,
	["Lead 4 (chiff)"] = Harp,
	["Lead 5 (charang)"] = Synthesizer,
	["Lead 6 (voice)"] = FluteAndVoice,
	["Lead 7 (fifths)"] = Harp,
	["Lead 8 (bass + lead)"] = DoubleBass,
	-- Synth Pad
	["Pad 1 (new age)"] = Synthesizer,
	["Pad 2 (warm)"] = Harp,
	["Pad 3 (polysynth)"] = Synthesizer,
	["Pad 4 (choir)"] = FluteAndVoice,
	["Pad 5 (bowed glass)"] = Harp,
	["Pad 6 (metallic)"] = Bit,
	["Pad 7 (halo)"] = FluteAndVoice,
	["Pad 8 (sweep)"] = Synthesizer,
	-- Synth Effects
	["FX 1 (rain)"] = Harp,
	["FX 2 (soundtrack)"] = Synthesizer,
	["FX 3 (crystal)"] = Chimes,
	["FX 4 (atmosphere)"] = Guitar,
	["FX 5 (brightness)"] = Synthesizer,
	["FX 6 (goblins)"] = Synthesizer,
	["FX 7 (echoes)"] = FluteAndVoice,
	["FX 8 (sci-fi)"] = Synthesizer,
	-- Ethnic
	["Sitar"] = Banjo,
	["Banjo"] = Banjo,
	["Shamisen"] = Banjo,
	["Koto"] = Guitar,
	["Kalimba"] = Vibes,
	["Bag pipe"] = FluteAndVoice,
	["Fiddle"] = FluteAndVoice,
	["Shanai"] = FluteAndVoice,
	-- Percussive
	["Tinkle Bell"] = Vibes2,
	["Agogo"] = Agogo,
	["Steel Drums"] = Vibes,
	["Woodblock"] = Agogo,
	["Taiko Drum"] = BassDrum,
	["Melodic Tom"] = SnareDrum,
	["Synth Drum"] = SnareDrum,
	["Reverse Cymbal"] = FluteAndVoice,
	-- Sound Effects
	["Guitar Fret Noise"] = Guitar,
	["Breath Noise"] = FluteAndVoice,
	["Seashore"] = Sea,
	["Bird Tweet"] = FluteAndVoice,
	["Telephone Ring"] = Chimes,
	["Helicopter"] = Didgeridoo,
	["Applause"] = FluteAndVoice,
	["Gunshot"] = Blast,
}

local Hat = "click"
local Snare = "sdrum"
local Cowbell = "cowbell"
local Sand = nil

local CHATSOUNDS_PERCUSSIONS = {
	[28] = Snare,
	[31] = Hat,
	[33] = Hat,
	[34] = Hat,
	[35] = BassDrum,
	[36] = BassDrum,
	[37] = Hat,
	[38] = Snare,
	[39] = Hat,
	[40] = Snare,
	[41] = BassDrum,
	[42] = Snare,
	[43] = BassDrum,
	[44] = Snare,
	[45] = BassDrum,
	[46] = Sand,
	[47] = BassDrum,
	[48] = BassDrum,
	[49] = Sand,
	[50] = BassDrum,
	[51] = Snare,
	[52] = Snare,
	[53] = Snare,
	[54] = Hat,
	[55] = Snare,
	[56] = Hat,
	[57] = Snare,
	[58] = Hat,
	[59] = Snare,
	[60] = Hat,
	[61] = Hat,
	[62] = Hat,
	[63] = BassDrum,
	[64] = BassDrum,
	[65] = Snare,
	[66] = Snare,
	[67] = Cowbell,
	[68] = Cowbell,
	[69] = Hat,
	[70] = Hat,
	[73] = Hat,
	[74] = Hat,
	[75] = Hat,
	[76] = Hat,
	[77] = Hat,
	[81] = Hat,
	[80] = Hat,
	[82] = Snare,
	[86] = BassDrum,
	[87] = BassDrum,
}

local cur_instruments = {}
local midi_thing = {}
for i = -36, 95 - 36 - 1 do
	local number = 1
	for j = 0, i, math.abs(i) / i do
		if j >= 0 then
			number = number * 1.0594631
		else
			number = number / 1.0594631
		end
	end

	midi_thing[36 + i] = math.Clamp(number, 0.3, 16)
end

hook.Add("MIDI", "midi_player", function(time, code, key, velocity, ...)
	if not _G.chatsounds then return end
	if not code then return print("Explain why", code, key, velocity, ...) end

	code = _G.midi.GetCommandCode(code)
	local name = _G.midi.GetCommandName(code)
	local channel = _G.midi.GetCommandChannel(code) + 1

	if IGNORED_COMMANDS[code] then return end

	if name == "PATCH_CHANGE" then
		cur_instruments[channel] = INSTRUMENTS[key + 1]
		print(channel, cur_instruments[channel], CHATSOUNDS_INSTRUMENTS[cur_instruments[channel]])

		return
	end

	local note = midi_thing[key - 12]
	if not note or velocity == 0 then return end
	local chatso = "harp"

	if channel == 10 then
		chatso = CHATSOUNDS_PERCUSSIONS[key] or "click"
	else
		chatso = CHATSOUNDS_INSTRUMENTS[cur_instruments[channel]] or "harp"
	end

	if chatso == "" or chatso == nil then
		print("Missing sound on channel ", channel, key, channel == 10 and CHATSOUNDS_PERCUSSIONS[key] or CHATSOUNDS_INSTRUMENTS[cur_instruments[channel]])
		return
	end

	local api = _G.chatsounds.Module("API")
	local nest = api.CreateScope()
	nest:PushSound(chatso)
	nest:PushModifier("realm", "minecraft")
	nest:PushModifier("pitch", math.floor(0.65 * note * 1000) / 1000)
	nest:PushModifier("volume", math.floor(velocity / 127 * 1000) / 1000 + 0.25)
	nest:PushModifier("overlap", 1)
	nest:PushModifier("duration", 0.001)
	api.PlayScope(nest)
	--print(nest:ToString())
end)

local required = false
hook.Add("Think", "midi_player", function()
	if util.IsBinaryModuleInstalled("midi") and not required then
		required = true
		require("midi")
	end

	if not _G.midi then return end
	if _G.midi.IsOpened() then return end

	_G.midi.Open(0)
end)
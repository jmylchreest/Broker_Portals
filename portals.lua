if not LibStub then return end

local dewdrop 		= LibStub("Dewdrop-2.0", true)
local icon 			= LibStub("LibDBIcon-1.0", true)
local defaultIcon 	= "Interface\\Icons\\INV_Misc_Rune_06"

obj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("Broker_Portals", {
	type = "data source",
	text = "Portals",
	icon = defaultIcon,
})
local obj 		= obj
local methods 	= {}
local portals	= nil
local frame 	= CreateFrame("frame")

frame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)


local function pairsByKeys(t)
	local a = {}
	for n in pairs(t) do
		table.insert(a, n)
	end
	table.sort(a)
	
	local i = 0
	local iter = function ()
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i], t[a[i]]
		end
	end
	return iter
end

local function findSpell(spellname)
	for i = 1,180 do
		local s = GetSpellName(i, BOOKTYPE_SPELL)
		if s == spellname then
			return i
		end
	end
end

local function SetupSpells()
	local spells = {
		Alliance = {
			3561,  --TP:Stormwind
			3562,  --TP:Ironforge
			3565,  --TP:Darnassus
			32271, --TP:Exodar
			49359, --TP:Theramore
			33690, --TP:Shattrath
			10059, --P:Stormwind
			11416, --P:Ironforge
			11419, --P:Darnassus
			32266, --P:Exodar
			49360, --P:Theramore
			33691, --P:Shattrath
		},
		Horde = {
			3563,  --TP:Undercity
			3566,  --TP:Thunder Bluff
			3567,  --TP:Orgrimmar
			32272, --TP:Silvermoon
			49358, --TP:Stonard
			35715, --TP:Shattrath
			11418, --P:Undercity
			11420, --P:Thunder Bluff
			11417, --P:Orgrimmar
			32267, --P:Silvermoon
			49361, --P:Stonard
			35717, --P:Shattrath
		}
	}
	
	local _, class = UnitClass("player")
	if class == "MAGE" then
		portals = spells[UnitFactionGroup("player")]
	end

	spells = nil
end

local function UpdateSpells()
	if not portals then
		SetupSpells()
	end
	
	if portals then
		for _,unTransSpell in ipairs(portals) do
			
			local spell = GetSpellInfo(unTransSpell)
			local spellid = findSpell(spell)
			
			if spellid then	
				methods[spell] = {
					spellid = spellid,
					text = spell,
					secure = {
						type = 'spell',
						spell = spell,
					}
				}
			end
		end
	end
end

local function UpdateMenu()
	dewdrop:AddLine(
		'text', "Portals:",
		'isTitle', true
	)
	dewdrop:AddLine()

	for k,v in pairsByKeys(methods) do
		if v.secure then
			dewdrop:AddLine(
				'text', v.text,
				'secure', v.secure,
				'func', function() return end,
				'disabled', false,
				'closeWhenClicked', true
			)
		end
	end
end

local function ShowHearthstone()
	local text, secure
	local bindLoc = GetBindLocation()
	if bindLoc then
		text = "Inn: "..bindLoc
		secure = {
			type = 'item',
			item = "Hearthstone",
		}
		return text, secure
	else
		return nil
	end
end

function frame:PLAYER_LOGIN()
	-- if not PortalsDB then
		-- PortalsDB = {}
		-- PortalsDB.minimap = true
	-- end
	-- if icon then
		-- icon:Register("Broker_Portals", obj, PortalsDB.minimap)
	-- end
		
	self:RegisterEvent("SKILL_LINES_CHANGED")
	self:Show()
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

function frame:SKILL_LINES_CHANGED()
	UpdateSpells()
end

function obj.OnClick(self, button)
	if button == "RightButton" then
		dewdrop:Open(self, "children", function() UpdateMenu() end)
	end
end

if IsLoggedIn() then 
	frame:PLAYER_LOGIN() 
else 
	frame:RegisterEvent("PLAYER_LOGIN") 
end

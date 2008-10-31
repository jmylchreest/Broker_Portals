if not LibStub then return end

local dewdrop = LibStub("Dewdrop-2.0", true)
local defaultIcon = "Interface\\Icons\\INV_Misc_Rune_06"

obj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("Broker_Portals", {
	type = "data source",
	text = "Portals",
	icon = defaultIcon,
})
local obj = obj
local icon = LibStub("LibDBIcon-1.0", true)
local menu = {
	type =	"group",
	args = {
		header1 = {
			type =	"header",
			name =	"Portals:",
			order =	01,
		},
		header2 = {
			type =	"header",
			name =	" ",
			order =	02,
		}
	}
}
local portals = {}
local methods = {}
local needsUpdate = true
local frame = CreateFrame("frame")
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

local function UpdateSpells()
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
	UpdateSpells()
	
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
	if not PortalsDB then
		PortalsDB = {}
		PortalsDB.minimap = true
	end
	if icon then
		icon:Register("Broker_Portals", obj, PortalsDB.minimap)
	end
	
	self:RegisterEvent("SPELLS_CHANGED")
	UpdateMenu()
	self:Show()
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

function frame:SPELLS_CHANGED()
	UpdateSpells()
end

function obj.OnClick(self, button)
	if (not menu) or needsUpdate then
		--UpdateMenu()
	end
	if button == "RightButton" then
		dewdrop:Register(self, "children", function() 	UpdateMenu() end)
	end
end

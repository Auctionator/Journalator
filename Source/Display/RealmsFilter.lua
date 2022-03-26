JournalatorRealmsFilterDropDownMixin = {}

local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
local function JournalatorRealmsFilterDropDownMenu_Initialize(self)
  local realmsButton = self:GetParent()

  local info = LibDD:UIDropDownMenu_CreateInfo()
  info.text = AUCTIONATOR_L_NONE
  info.value = nil
  info.isNotRadio = true
  info.checked = false
  info.func = function(button)
    realmsButton:ToggleNone()
    LibDD:ToggleDropDownMenu(1, nil, self, self:GetParent(), 9, 3)
  end
  LibDD:UIDropDownMenu_AddButton(info)

  for _, realm in ipairs(realmsButton:GetRealms()) do
    local info = LibDD:UIDropDownMenu_CreateInfo()
    info.text = realm
    info.value = nil
    info.isNotRadio = true
    info.checked = realmsButton:GetValue(realm)
    info.keepShownOnClick = 1
    info.func = function(button)
      realmsButton:ToggleFilter(realm)
    end
    LibDD:UIDropDownMenu_AddButton(info)
  end
end

-- When realm ~= nil returns a boolean indicating whether the realm is toggled
-- on.
-- If realm == nil returns true if the filter state has changed since the last
-- such call. Used to avoid refreshing DataProviders more than necessary.
function JournalatorRealmsFilterDropDownMixin:GetValue(realm)
  if realm ~= nil then
    return self.settings[realm]
  else
    local changed = self.hasChanged
    self.hasChanged = false
    return changed
  end
end

function JournalatorRealmsFilterDropDownMixin:SetRealms(allRealms, preserve)
  self.allRealms = allRealms

  local oldState = {}
  if preserve then
    for key, value in pairs(self.settings) do
      oldState[key] = value
    end
  end
  self:Reset()

  for key, value in pairs(oldState) do
    self.settings[key] = value
  end
  self.hasChanged = true
end

function JournalatorRealmsFilterDropDownMixin:GetRealms()
  return self.allRealms
end

function JournalatorRealmsFilterDropDownMixin:OnLoad()
  self.allRealms = {}
  self:Reset()
  LibDD:Create_UIDropDownMenu(self.DropDown)
  LibDD:UIDropDownMenu_SetInitializeFunction(self.DropDown, JournalatorRealmsFilterDropDownMenu_Initialize)
  LibDD:UIDropDownMenu_SetDisplayMode(self.DropDown, "MENU")
end

function JournalatorRealmsFilterDropDownMixin:SetTextForRealms()
  local allSet = true
  for _, realm in pairs(self.settings) do
    allSet = allSet and realm
  end

  if allSet then
    self:SetText(JOURNALATOR_L_ALL_REALMS)
  else
    self:SetText(JOURNALATOR_L_SOME_REALMS)
  end
end

function JournalatorRealmsFilterDropDownMixin:Reset()
  self.settings = {}
  for _, realm in ipairs(self.allRealms) do
    self.settings[realm] = true
  end
  self:SetTextForRealms()
  self.hasChanged = true
end

function JournalatorRealmsFilterDropDownMixin:ToggleNone()
  local anyTrue = false
  for realm, _ in pairs(self.settings) do
    anyTrue = anyTrue or self.settings[realm]
  end

  if anyTrue then
    for realm, _ in pairs(self.settings) do
      self.settings[realm] = false
    end
  else
    self:Reset()
  end
  self:SetTextForRealms()
  self.hasChanged = true
end

function JournalatorRealmsFilterDropDownMixin:ToggleFilter(name)
  self.settings[name] = not self.settings[name]
  self:SetTextForRealms()
  self.hasChanged = true
end

function JournalatorRealmsFilterDropDownMixin:OnClick()
	LibDD:ToggleDropDownMenu(1, nil, self.DropDown, self, 9, 3)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

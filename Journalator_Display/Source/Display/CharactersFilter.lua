JournalatorCharactersFilterDropDownMixin = {}

local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

local function JournalatorCharactersFilterDropDownMenu_Initialize(self)
  local charactersButton = self:GetParent()

  local info = LibDD:UIDropDownMenu_CreateInfo()
  info.text = AUCTIONATOR_L_NONE
  info.value = nil
  info.isNotRadio = true
  info.checked = false
  info.func = function(button)
    charactersButton:ToggleNone()
    LibDD:ToggleDropDownMenu(1, nil, self, self:GetParent(), 9, 3)
  end
  LibDD:UIDropDownMenu_AddButton(info)

  for _, character in ipairs(charactersButton:GetCharacters()) do
    local info = LibDD:UIDropDownMenu_CreateInfo()
    info.text = character
    info.value = nil
    info.isNotRadio = true
    info.checked = charactersButton:GetValue(character)
    info.keepShownOnClick = 1
    info.func = function(button)
      charactersButton:ToggleFilter(character)
    end
    LibDD:UIDropDownMenu_AddButton(info)
  end
end

-- When character ~= nil returns a boolean indicating whether the character is toggled
-- on.
function JournalatorCharactersFilterDropDownMixin:GetValue(character, realm)
  if realm ~= nil then
    realm = Journalator.Utilities.NormalizeRealmName(realm)
  end
  if realm == nil then
    character, realm = strsplit("-", character)
  end
  if realm == nil then
    realm = self.currentRealmName
  end
  return self.settings[realm] and self.settings[realm][character]
end

function JournalatorCharactersFilterDropDownMixin:HasChanged()
  local changed = self.hasChanged
  self.hasChanged = false
  return changed
end

function JournalatorCharactersFilterDropDownMixin:SetCharacters(realmsAndChars, preserve)
  self.defaultSettings = {}
  for realm, realmState in pairs(realmsAndChars) do
    self.defaultSettings[Journalator.Utilities.NormalizeRealmName(realm)] = CopyTable(realmState)
  end

  local realms = Journalator.Utilities.GetSortedKeys(self.defaultSettings)
  local characterList = {}
  for _, r in ipairs(realms) do
    local characters = Journalator.Utilities.GetSortedKeys(self.defaultSettings[r])
    if r == self.currentRealmName then
      for _, c in ipairs(characters) do
        table.insert(characterList, c)
      end
    else
      for _, c in ipairs(characters) do
        table.insert(characterList, c .. "-" .. r)
      end
    end
  end

  self.allCharacters = characterList

  local oldState = CopyTable(self.settings)

  self:Reset()

  if preserve then
    for realm, realmState in pairs(oldState) do
      self.settings[realm] = self.settings[realm] or {}
      for char, charState in pairs(realmState) do
        self.settings[realm][char] = charState
      end
    end
  end
  self.hasChanged = true
  self:SetTextForCharacters()
end

function JournalatorCharactersFilterDropDownMixin:GetCharacters()
  return self.allCharacters
end

function JournalatorCharactersFilterDropDownMixin:OnLoad()
  LibDD:Create_UIDropDownMenu(self.DropDown)
  LibDD:UIDropDownMenu_SetInitializeFunction(self.DropDown, JournalatorCharactersFilterDropDownMenu_Initialize)
  LibDD:UIDropDownMenu_SetDisplayMode(self.DropDown, "MENU")

  self.allCharacters = {}
  self.defaultSettings = self.defaultSettings or {}
  self.currentRealmName = Journalator.Utilities.NormalizeRealmName(Journalator.State.Source.realm)
  self:Reset()
end

function JournalatorCharactersFilterDropDownMixin:SetTextForCharacters()
  local allSet = true
  for realm, realmState in pairs(self.settings) do
    for char, charState in pairs(realmState) do
      allSet = allSet and charState
    end
  end

  if allSet then
    self:SetText(JOURNALATOR_L_ALL_CHARACTERS)
  else
    self:SetText(JOURNALATOR_L_SOME_CHARACTERS)
  end
end

function JournalatorCharactersFilterDropDownMixin:Reset()
  self.settings = CopyTable(self.defaultSettings)
  self:SetTextForCharacters()
  self.hasChanged = true
end

function JournalatorCharactersFilterDropDownMixin:ToggleNone()
  local anyTrue = false
  for realm, realmState in pairs(self.settings) do
    for char, charState in pairs(realmState) do
      anyTrue = anyTrue or charState
    end
  end

  if anyTrue then
    for realm, realmState in pairs(self.settings) do
      for char, charState in pairs(realmState) do
        realmState[char] = false
      end
    end
  else
    self:Reset()
  end
  self:SetTextForCharacters()
  self.hasChanged = true
end

function JournalatorCharactersFilterDropDownMixin:ToggleFilter(name)
  local char, realm = strsplit("-", name)
  realm = realm or self.currentRealmName
  self.settings[realm][char] = not self.settings[realm][char]
  self:SetTextForCharacters()
  self.hasChanged = true
end

function JournalatorCharactersFilterDropDownMixin:OnClick()
	LibDD:ToggleDropDownMenu(1, nil, self.DropDown, self, 9, 3)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

local HttpService = game:GetService("HttpService")

local SaveManager = {}
SaveManager.Folder = "StarlightSettings"
SaveManager.SubFolder = ""
SaveManager.Ignore = {}
SaveManager.Library = nil
SaveManager.Parser = {
    Toggle = {
        Save = function(idx, object) return { type = "Toggle", idx = idx, value = object.Values.CurrentValue } end,
        Load = function(idx, data)
            if SaveManager.Library.Toggles[idx] then
                SaveManager.Library.Toggles[idx]:SetValue(data.value)
            end
        end,
    },
    Slider = {
        Save = function(idx, object) return { type = "Slider", idx = idx, value = object.Values.CurrentValue } end,
        Load = function(idx, data)
            if SaveManager.Library.Options[idx] then
                SaveManager.Library.Options[idx]:SetValue(data.value)
            end
        end,
    },
    Dropdown = {
        Save = function(idx, object) return { type = "Dropdown", idx = idx, value = object.Values.CurrentOption } end,
        Load = function(idx, data)
            if SaveManager.Library.Options[idx] then
                SaveManager.Library.Options[idx]:SetValue(data.value)
            end
        end,
    },
    ColorPicker = {
        Save = function(idx, object) return { type = "ColorPicker", idx = idx, value = object.Values.CurrentValue:ToHex(), transparency = object.Values.Transparency or 0 } end,
        Load = function(idx, data)
            if SaveManager.Library.Options[idx] then
                SaveManager.Library.Options[idx]:SetValue(Color3.fromHex(data.value), data.transparency or 0)
            end
        end,
    },
    KeyPicker = {
        Save = function(idx, object) return { type = "KeyPicker", idx = idx, mode = object.Values.Mode, key = object.Values.CurrentValue } end,
        Load = function(idx, data)
            if SaveManager.Library.Options[idx] then
                SaveManager.Library.Options[idx]:SetValue({ data.key, data.mode })
            end
        end,
    },
    Input = {
        Save = function(idx, object) return { type = "Input", idx = idx, value = object.Values.CurrentValue } end,
        Load = function(idx, data)
            if SaveManager.Library.Options[idx] and type(data.value) == "string" then
                SaveManager.Library.Options[idx]:SetValue(data.value)
            end
        end,
    },
}
SaveManager.LoadOrder = { "Toggle", "Slider", "Dropdown", "ColorPicker", "KeyPicker", "Input" }

function SaveManager:SetLibrary(library)
    self.Library = library
end

function SaveManager:SetFolder(folder)
    self.Folder = folder
    if not isfolder(self.Folder) then makefolder(self.Folder) end
end

function SaveManager:SetSubFolder(subfolder)
    self.SubFolder = subfolder
    local fullPath = self.Folder .. "/" .. self.SubFolder
    if not isfolder(fullPath) then makefolder(fullPath) end
end

function SaveManager:SetIgnoreIndexes(list)
    for _, v in pairs(list) do
        self.Ignore[v] = true
    end
end

function SaveManager:IgnoreThemeSettings()
    self:SetIgnoreIndexes({
        "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor", "ThemeManager_ThemeList", "ThemeManager_CustomThemeList"
    })
end

function SaveManager:SetLoadingOrder(enabled, order)
    if enabled and type(order) == "table" then
        self.LoadOrder = order
    end
end

local function getPath()
    local path = SaveManager.Folder
    if SaveManager.SubFolder ~= "" then
        path = path .. "/" .. SaveManager.SubFolder
    end
    return path
end

function SaveManager:Save(name)
    if not self.Library then return false, "Library not set" end
    local fullPath = getPath() .. "/configs"
    if not isfolder(fullPath) then makefolder(fullPath) end

    local data = {}
    for idx, toggle in pairs(self.Library.Toggles) do
        if not self.Ignore[idx] then
            table.insert(data, self.Parser.Toggle.Save(idx, toggle))
        end
    end

    for idx, option in pairs(self.Library.Options) do
        if not self.Ignore[idx] then
            local p = self.Parser[option.Type]
            if p then
                table.insert(data, p.Save(idx, option))
            end
        end
    end

    local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if not success then return false, "Failed to encode config" end

    writefile(fullPath .. "/" .. name .. ".json", encoded)
    return true
end

function SaveManager:Load(name)
    if not self.Library then return false, "Library not set" end
    local filePath = getPath() .. "/configs/" .. name .. ".json"
    if not isfile(filePath) then return false, "File does not exist" end

    local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(filePath))
    if not success or type(decoded) ~= "table" then return false, "Failed to decode config" end

    local grouped = {}
    for _, item in pairs(decoded) do
        if type(item) == "table" and item.type and item.idx then
            grouped[item.type] = grouped[item.type] or {}
            table.insert(grouped[item.type], item)
        end
    end

    for _, eType in ipairs(self.LoadOrder) do
        if grouped[eType] then
            for _, item in ipairs(grouped[eType]) do
                local p = self.Parser[eType]
                if p then
                    pcall(p.Load, item.idx, item)
                end
            end
        end
    end

    return true
end

function SaveManager:Delete(name)
    local filePath = getPath() .. "/configs/" .. name .. ".json"
    if isfile(filePath) then
        delfile(filePath)
        return true
    end
    return false, "File not found"
end

function SaveManager:RefreshConfigList()
    local list = {}
    local fullPath = getPath() .. "/configs"
    if isfolder(fullPath) then
        for _, file in ipairs(listfiles(fullPath)) do
            if file:sub(-5) == ".json" then
                local name = file:match("([^/\\]+)%.json$")
                if name then table.insert(list, name) end
            end
        end
    end
    return list
end

function SaveManager:GetAutoloadConfig()
    local filePath = getPath() .. "/autoload.txt"
    if isfile(filePath) then
        local name = readfile(filePath):gsub("^%s*(.-)%s*$", "%1")
        return name ~= "" and name or "none"
    end
    return "none"
end

function SaveManager:SaveAutoloadConfig(name)
    local filePath = getPath() .. "/autoload.txt"
    writefile(filePath, name)
    return true
end

function SaveManager:DeleteAutoLoadConfig()
    local filePath = getPath() .. "/autoload.txt"
    if isfile(filePath) then
        delfile(filePath)
        return true
    end
    return false, "No autoload config set"
end

function SaveManager:LoadAutoloadConfig()
    local name = self:GetAutoloadConfig()
    if name ~= "none" then
        self:Load(name)
    end
end

function SaveManager:BuildConfigSection(tab)
    if not self.Library then return end
    
    local groupbox = tab:CreateGroupbox({ Name = "Configuration", Column = 2 }, "ConfigManager")
    
    local configs = self:RefreshConfigList()
    
    local dd = groupbox:CreateLabel({ Name = "Select Config" }, "SaveManager_ConfigListLbl"):AddDropdown({
        Options = configs,
        CurrentOption = { "none" },
        Callback = function() end
    }, "SaveManager_ConfigList")
    
    local input = groupbox:CreateInput({
        Name = "Config Name",
        PlaceholderText = "name here...",
        RemoveTextAfterFocusLost = false,
        Callback = function() end
    }, "SaveManager_ConfigName")
    
    groupbox:CreateButton({
        Name = "Create Config",
        Callback = function()
            local name = self.Library.Options.SaveManager_ConfigName.Value
            if name and name ~= "" then
                self:Save(name)
                dd:SetOptions(self:RefreshConfigList())
                dd:SetValue(name)
            end
        end
    }, "SaveManager_CreateBtn")
    
    groupbox:CreateButton({
        Name = "Save Config",
        Callback = function()
            local name = self.Library.Options.SaveManager_ConfigList.Value[1]
            if name and name ~= "none" then
                self:Save(name)
            end
        end
    }, "SaveManager_SaveBtn")
    
    groupbox:CreateButton({
        Name = "Load Config",
        Callback = function()
            local name = self.Library.Options.SaveManager_ConfigList.Value[1]
            if name and name ~= "none" then
                self:Load(name)
            end
        end
    }, "SaveManager_LoadBtn")
    
    groupbox:CreateButton({
        Name = "Delete Config",
        Callback = function()
            local name = self.Library.Options.SaveManager_ConfigList.Value[1]
            if name and name ~= "none" then
                self:Delete(name)
                dd:SetOptions(self:RefreshConfigList())
                dd:SetValue("none")
            end
        end
    }, "SaveManager_DeleteBtn")
    
    groupbox:CreateButton({
        Name = "Set Autoload",
        Callback = function()
            local name = self.Library.Options.SaveManager_ConfigList.Value[1]
            if name and name ~= "none" then
                self:SaveAutoloadConfig(name)
            end
        end
    }, "SaveManager_SetAutoloadBtn")
end

return SaveManager

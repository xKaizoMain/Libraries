local HttpService = game:GetService("HttpService")

local ThemeManager = {}
ThemeManager.Folder = "ObsidianLibSettings"
ThemeManager.Library = nil
ThemeManager.BuiltInThemes = {
    Default = {
        FontColor = Color3.fromRGB(205, 214, 244),
        MainColor = Color3.fromRGB(26, 27, 38),
        AccentColor = Color3.fromRGB(137, 180, 250),
        BackgroundColor = Color3.fromRGB(30, 30, 46),
        OutlineColor = Color3.fromRGB(49, 50, 68),
        FontFace = Enum.Font.SourceSans
    },
    BBot = {
        FontColor = Color3.fromRGB(255, 255, 255),
        MainColor = Color3.fromRGB(18, 18, 18),
        AccentColor = Color3.fromRGB(0, 150, 255),
        BackgroundColor = Color3.fromRGB(25, 25, 25),
        OutlineColor = Color3.fromRGB(35, 35, 35),
        FontFace = Enum.Font.Code
    },
    Fatality = {
        FontColor = Color3.fromRGB(255, 255, 255),
        MainColor = Color3.fromRGB(15, 15, 20),
        AccentColor = Color3.fromRGB(216, 13, 65),
        BackgroundColor = Color3.fromRGB(20, 20, 25),
        OutlineColor = Color3.fromRGB(40, 40, 50),
        FontFace = Enum.Font.Roboto
    },
    Nord = {
        FontColor = Color3.fromRGB(216, 222, 233),
        MainColor = Color3.fromRGB(46, 52, 64),
        AccentColor = Color3.fromRGB(136, 192, 208),
        BackgroundColor = Color3.fromRGB(59, 66, 82),
        OutlineColor = Color3.fromRGB(67, 76, 94),
        FontFace = Enum.Font.Gotham
    },
    Dracula = {
        FontColor = Color3.fromRGB(248, 248, 242),
        MainColor = Color3.fromRGB(40, 42, 54),
        AccentColor = Color3.fromRGB(189, 147, 249),
        BackgroundColor = Color3.fromRGB(68, 71, 90),
        OutlineColor = Color3.fromRGB(98, 114, 164),
        FontFace = Enum.Font.SourceSans
    },
    Catppuccin = {
        FontColor = Color3.fromRGB(205, 214, 244),
        MainColor = Color3.fromRGB(30, 30, 46),
        AccentColor = Color3.fromRGB(203, 166, 247),
        BackgroundColor = Color3.fromRGB(24, 24, 37),
        OutlineColor = Color3.fromRGB(49, 50, 68),
        FontFace = Enum.Font.SourceSans
    }
}

function ThemeManager:SetLibrary(library)
    self.Library = library
end

function ThemeManager:SetFolder(folder)
    self.Folder = folder
    if not isfolder(self.Folder) then makefolder(self.Folder) end
    if not isfolder(self.Folder .. "/themes") then makefolder(self.Folder .. "/themes") end
end

function ThemeManager:SetDefaultTheme(theme)
    self.BuiltInThemes.Default = theme
end

function ThemeManager:GetCustomTheme(name)
    local path = self.Folder .. "/themes/" .. name .. ".json"
    if isfile(path) then
        local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(path))
        if success and type(decoded) == "table" then
            local theme = {}
            for k, v in pairs(decoded) do
                if k ~= "FontFace" then
                    theme[k] = Color3.fromHex(v)
                else
                    theme[k] = Enum.Font[v] or Enum.Font.SourceSans
                end
            end
            return theme
        end
    end
    return nil
end

function ThemeManager:ApplyTheme(name)
    if not self.Library then return end
    
    local theme = self.BuiltInThemes[name] or self:GetCustomTheme(name)
    if not theme then return end
    
    for k, v in pairs(theme) do
        if self.Library.Options[k] and k ~= "FontFace" then
            self.Library.Options[k]:SetValueRGB(v, 0)
        end
    end
    
    self:ThemeUpdate()
end

function ThemeManager:ThemeUpdate()
    if not self.Library then return end
    
    local theme = {}
    if self.Library.Options.FontColor then theme.FontColor = self.Library.Options.FontColor.Value end
    if self.Library.Options.MainColor then theme.MainColor = self.Library.Options.MainColor.Value end
    if self.Library.Options.AccentColor then theme.AccentColor = self.Library.Options.AccentColor.Value end
    if self.Library.Options.BackgroundColor then theme.BackgroundColor = self.Library.Options.BackgroundColor.Value end
    if self.Library.Options.OutlineColor then theme.OutlineColor = self.Library.Options.OutlineColor.Value end
    
    if self.Library.SetTheme then
        self.Library:SetTheme(theme)
    end
end

function ThemeManager:LoadDefault()
    local path = self.Folder .. "/default_theme.txt"
    if isfile(path) then
        local name = readfile(path):gsub("^%s*(.-)%s*$", "%1")
        if name ~= "" then
            self:ApplyTheme(name)
            return
        end
    end
    self:ApplyTheme("Default")
end

function ThemeManager:SaveDefault(name)
    local path = self.Folder .. "/default_theme.txt"
    writefile(path, name)
end

function ThemeManager:SaveCustomTheme(name)
    if not self.Library then return end
    if not isfolder(self.Folder .. "/themes") then makefolder(self.Folder .. "/themes") end
    
    local theme = {}
    if self.Library.Options.FontColor then theme.FontColor = self.Library.Options.FontColor.Value:ToHex() end
    if self.Library.Options.MainColor then theme.MainColor = self.Library.Options.MainColor.Value:ToHex() end
    if self.Library.Options.AccentColor then theme.AccentColor = self.Library.Options.AccentColor.Value:ToHex() end
    if self.Library.Options.BackgroundColor then theme.BackgroundColor = self.Library.Options.BackgroundColor.Value:ToHex() end
    if self.Library.Options.OutlineColor then theme.OutlineColor = self.Library.Options.OutlineColor.Value:ToHex() end
    theme.FontFace = "SourceSans"
    
    local success, encoded = pcall(HttpService.JSONEncode, HttpService, theme)
    if success then
        writefile(self.Folder .. "/themes/" .. name .. ".json", encoded)
        return true
    end
    return false, "Encode failed"
end

function ThemeManager:Delete(name)
    local path = self.Folder .. "/themes/" .. name .. ".json"
    if isfile(path) then
        delfile(path)
        return true
    end
    return false, "File not found"
end

function ThemeManager:ReloadCustomThemes()
    local list = {}
    local path = self.Folder .. "/themes"
    if isfolder(path) then
        for _, file in ipairs(listfiles(path)) do
            if file:sub(-5) == ".json" then
                local name = file:match("([^/\\]+)%.json$")
                if name then table.insert(list, name) end
            end
        end
    end
    return list
end

function ThemeManager:CreateThemeManager(groupbox)
    if not self.Library then return end

    -- Since Starlight manages themes natively via Tab:BuildThemeGroupbox,
    -- we just display a label and button to maintain compatibility without duplicating UI.
    groupbox:CreateLabel({
        Name = "Starlight manages themes natively.",
        Icon = 129398364168201
    })
    
    groupbox:CreateButton({
        Name = "Use Starlight Themes",
        Callback = function()
            -- Do nothing, just a visual indicator for script devs porting their script.
        end
    })
end

function ThemeManager:CreateGroupBox(tab)
    return tab:CreateGroupbox({ Name = "Themes", Column = 1 }, "ThemeManager_Groupbox")
end

function ThemeManager:ApplyToTab(tab)
    local gb = self:CreateGroupBox(tab)
    self:CreateThemeManager(gb)
end

function ThemeManager:ApplyToGroupbox(groupbox)
    self:CreateThemeManager(groupbox)
end

return ThemeManager

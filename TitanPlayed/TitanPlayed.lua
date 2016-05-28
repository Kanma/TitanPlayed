-- ******************************** CONSTANTS *******************************

-- Setup the name we want in the global namespace
TitanPlayed = {};

-- Reduce the chance of functions and variables colliding with another addon.
local TP = TitanPlayed;
local LibQTip = LibStub('LibQTip-1.0');

TP.id    = "Played";
TP.addon = "TitanPlayed";

-- These strings will be used for display. Localized strings are outside the scope of this example.
TP.button_label   = TP.id .. ": ";
TP.menu_text      = TP.id;
TP.tooltip_header = TP.id .. " Info";
TP.tooltip_hint   = "Hint: Left-click to view your time played on each character";
TP.menu_hide      = "Hide";

--  Get data from the TOC file.
TP.version = tostring(GetAddOnMetadata(TP.addon, "Version")) or "Unknown";
TP.author  = GetAddOnMetadata(TP.addon, "Author") or "Unknown";

-- Currency ids
TP.CURRENCY_APEXIS_CRISTALS    = 823;
TP.CURRENCY_GARRISON_RESOURCES = 824;
TP.CURRENCY_CONQUEST_POINTS    = 390;
TP.CURRENCY_HONOR_POINTS       = 392;



-- ***************************** SAVED VARIABLES ****************************

TitanPlayedTimes = {};


-- ******************************** VARIABLES *******************************

local tooltip              = nil;
local must_display_tooltip = false
local reference_time       = nil;
local current_entry        = nil;


-- ******************************** FUNCTIONS *******************************

-- --------------------------------------------------------------------------
-- NAME : TitanPlayed.Button_OnLoad()
-- DESC : Registers the plugin upon it loading
-- --------------------------------------------------------------------------
function TP.Button_OnLoad(self)
-- SDK : "registry" is the data structure Titan uses to addon info it is displaying.
--       This is the critical structure!
-- SDK : This works because the button inherits from a Titan template. In this case
--       TitanPanelComboTemplate in the XML.
    self.registry = {
        id                  = TP.id,
        version             = TP.version,
        category            = "Information",        -- General, Combat, Information, Interface, Profession
        menuText            = TP.menu_text,         -- Text displayed when the user finds the addon by right clicking on the Titan bar
        buttonTextFunction  = "",
        tooltipTitle        = TP.tooltip_header,    -- First line in the tooltip.
        tooltipTextFunction = "",
        icon                = "Interface\\Icons\\Ability_Mage_Timewarp",
        iconWidth           = 16,
        savedVariables      = {
            -- SDK : Titan will handle the 3 variables below but the addon code must put it on the menu
            ShowIcon = 1,
            ShowLabelText = 0,
            ShowColoredText = 0,
        }
    };

    self.tooltip = nil;

    -- Tell Blizzard the events we need
    self:RegisterEvent("ADDON_LOADED");
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("PLAYER_LEAVING_WORLD");
    self:RegisterEvent("PLAYER_LEVEL_UP");
    self:RegisterEvent("PLAYER_MONEY");
    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE");
    self:RegisterEvent("EQUIPMENT_SETS_CHANGED");
    self:RegisterEvent("TIME_PLAYED_MSG");
end


-- --------------------------------------------------------------------------
-- NAME : TP.Button_OnEvent()
-- DESC : Parse events registered to plugin and act on them
-- USE  : _OnEvent handler from the XML file
-- --------------------------------------------------------------------------
function TP.Button_OnEvent(self, event, ...)
    local player_name = UnitName("player")
    local realm_name = GetRealmName()
    local name = player_name .. '/' .. realm_name;

    if (event == "ADDON_LOADED") then
        local current_time = time();
        current_entry = current_time - (current_time % (3600 * 24));
        reference_time = current_time;

        if (TitanPlayedTimes[name] == nil) then
            localizedClass, englishClass = UnitClass("player");
            TitanPlayedTimes[name] = {};
            TitanPlayedTimes[name].class = englishClass;
        end

        TitanPlayedTimes[name].level = UnitLevel("player");

        if (TitanPlayedTimes[name]['sessions'] == nil) then
            TitanPlayedTimes[name].sessions = {};
        end

        if (TitanPlayedTimes[name]['levels_history'] == nil) then
            TitanPlayedTimes[name].levels_history = {};
        end

        for i = table.getn(TitanPlayedTimes[name].levels_history) + 1, TitanPlayedTimes[name].level do
            TitanPlayedTimes[name].levels_history[i] = 0;
        end

        if (TitanPlayedTimes[name].sessions[current_entry] == nil) then
            if (TitanPlayedTimes[name].last == nil) then
                TitanPlayedTimes[name].sessions[current_entry] = { played   = 0;
                                                                   money    = 0;
                                                                   apexis   = 0;
                                                                   garrison = 0;
                                                                   conquest = 0;
                                                                   honor    = 0;
                                                                 };
            else
                TitanPlayedTimes[name].sessions[current_entry] = TP.CopySession(TitanPlayedTimes[name].sessions[TitanPlayedTimes[name].last])
            end
            TitanPlayedTimes[name].last = current_entry;
        end

    elseif (event == "PLAYER_ENTERING_WORLD") then
        TitanPlayedTimes[name].sessions[current_entry].money = GetMoney();
        RequestTimePlayed();

    elseif (event == "PLAYER_LEAVING_WORLD") then
        local current_time = time();
        local dest_entry = current_time - (current_time % (3600 * 24));

        if (dest_entry ~= current_entry) then
            local current_session = TitanPlayedTimes[name].sessions[current_entry];

            TitanPlayedTimes[name].sessions[dest_entry] = TP.CopySession(current_session);
            TitanPlayedTimes[name].sessions[dest_entry].played = current_session.played + (current_time - reference_time);

            current_session.played = current_session.played + (dest_entry - reference_time);

            current_entry = dest_entry;
            reference_time = current_time;
            TitanPlayedTimes[name].last = current_entry;
        elseif (reference_time ~= nil) then
            TitanPlayedTimes[name].sessions[current_entry].played = TitanPlayedTimes[name].sessions[current_entry].played + (current_time - reference_time);
            reference_time = current_time;
        end

    elseif (event == "PLAYER_LEVEL_UP") then
        local arg1 = ...;
        TitanPlayedTimes[name].level = arg1;
        TitanPlayedTimes[name].levels_history[arg1] = time();

    elseif (event == "PLAYER_MONEY") then
        TitanPlayedTimes[name].sessions[current_entry].money = GetMoney();

    elseif (event == "CURRENCY_DISPLAY_UPDATE") then
        local _, amount, _ = GetCurrencyInfo(TP.CURRENCY_APEXIS_CRISTALS)
        TitanPlayedTimes[name].sessions[current_entry].apexis = amount;

        _, amount, _ = GetCurrencyInfo(TP.CURRENCY_GARRISON_RESOURCES)
        TitanPlayedTimes[name].sessions[current_entry].garrison = amount;

        _, amount, _ = GetCurrencyInfo(TP.CURRENCY_CONQUEST_POINTS)
        TitanPlayedTimes[name].sessions[current_entry].conquest = amount;

        _, amount, _ = GetCurrencyInfo(TP.CURRENCY_HONOR_POINTS)
        TitanPlayedTimes[name].sessions[current_entry].honor = amount;

    elseif (event == "EQUIPMENT_SETS_CHANGED") then
        local count = GetNumEquipmentSets();
        for i=1, count do
            local equipment_set_name, equipment_set_icon, equipment_set_id, isEquipped = GetEquipmentSetInfo(i);
            if (isEquipped) then
                local overall, equipped = GetAverageItemLevel();

                if (TitanPlayedTimes[name].sessions[current_entry]['ilvl'] == nil) then
                    TitanPlayedTimes[name].sessions[current_entry].ilvl = {};
                end

                TitanPlayedTimes[name].sessions[current_entry].ilvl[equipment_set_name] = equipped;

                break;
            end
        end

    elseif (event == "TIME_PLAYED_MSG") then
        local arg1, arg2 = ...;

        if (arg1 < TitanPlayedTimes[name].sessions[current_entry].played) then
            return;
        end

        local current_time = time();
        local dest_entry = current_time - (current_time % (3600 * 24));

        reference_time = current_time;

        if (dest_entry ~= current_entry) then
            local current_session = TitanPlayedTimes[name].sessions[current_entry];

            TitanPlayedTimes[name].sessions[dest_entry] = TP.CopySession(current_session);
            TitanPlayedTimes[name].sessions[dest_entry].played = arg1;

            current_session.played = arg1 - (current_time - dest_entry);
            current_entry = dest_entry;
            TitanPlayedTimes[name].last = current_entry;
        else
            TitanPlayedTimes[name].sessions[current_entry].played = arg1;
        end

        if (must_display_tooltip) then
            self.tooltip = LibQTip:Acquire("TitanPlayed_Tooltip", 2, "LEFT", "LEFT");
            self.tooltip:Clear();

            local sorted_keys = {};
            for n, v in pairs(TitanPlayedTimes) do table.insert(sorted_keys, n) end

            table.sort(sorted_keys, function(a,b) return TitanPlayedTimes[a].sessions[TitanPlayedTimes[a].last].played > TitanPlayedTimes[b].sessions[TitanPlayedTimes[b].last].played end);

            local redFont = CreateFont("RedFont");
            redFont:CopyFontObject(GameTooltipText);
            redFont:SetTextColor(1,0.6,0);

            for index, name in ipairs(sorted_keys) do
                local y, x = self.tooltip:AddLine();

                local characterFont = CreateFont(name .. "Font");
                characterFont:CopyFontObject(GameTooltipText);

                if TitanPlayedTimes[name].class == 'DEATHKNIGHT' then characterFont:SetTextColor(0.77, 0.12, 0.23);
                elseif TitanPlayedTimes[name].class == 'DRUID' then characterFont:SetTextColor(1.00, 0.49, 0.04);
                elseif TitanPlayedTimes[name].class == 'HUNTER' then characterFont:SetTextColor(0.67, 0.83, 0.45);
                elseif TitanPlayedTimes[name].class == 'MAGE' then characterFont:SetTextColor(0.41, 0.80, 0.94);
                elseif TitanPlayedTimes[name].class == 'MONK' then characterFont:SetTextColor(0.33, 0.54, 0.52);
                elseif TitanPlayedTimes[name].class == 'PALADIN' then characterFont:SetTextColor(0.96, 0.55, 0.73);
                elseif TitanPlayedTimes[name].class == 'PRIEST' then characterFont:SetTextColor(1.00, 1.00, 1.00);
                elseif TitanPlayedTimes[name].class == 'ROGUE' then characterFont:SetTextColor(1.00, 0.96, 0.41);
                elseif TitanPlayedTimes[name].class == 'SHAMAN' then characterFont:SetTextColor(0.0, 0.44, 0.87);
                elseif TitanPlayedTimes[name].class == 'WARLOCK' then characterFont:SetTextColor(0.58, 0.51, 0.7);
                elseif TitanPlayedTimes[name].class == 'WARRIOR' then characterFont:SetTextColor(0.78, 0.61, 0.43);
                end

                self.tooltip:SetCell(y, 1, name, characterFont);

                local played = TitanPlayedTimes[name].sessions[TitanPlayedTimes[name].last].played;

                local modulo_days = played % (3600 * 24);
                local days = (played - modulo_days) / (3600 * 24);
                local modulo_hours = modulo_days % 3600;
                local hours = (modulo_days - modulo_hours) / 3600;
                local seconds = modulo_hours % 60;
                local minutes = (modulo_hours - seconds) / 60;

                local str = '';

                if (days < 10) then str = str .. '0' end
                str = str .. days .. 'd ';

                if (hours < 10) then str = str .. '0' end
                str = str .. hours .. 'h ';

                if (minutes < 10) then str = str .. '0' end
                str = str .. minutes .. 'm ';

                if (seconds < 10) then str = str .. '0' end
                str = str .. seconds .. 's';

                self.tooltip:SetCell(y, 2, str, redFont);
            end

            self.tooltip:SetAutoHideDelay(0.01, self);
            self.tooltip:SmartAnchorTo(self);
            self.tooltip:Show();

            must_display_tooltip = false;
        end
    end
end


-- --------------------------------------------------------------------------
-- NAME : TP.Button_OnClick(button)
-- DESC : Hides the list of food items
-- VARS : button = value of action
-- USE  : _OnClick handler from the XML file
-- --------------------------------------------------------------------------
function TP.Button_OnClick(self, button)
    if self.tooltip then
        LibQTip:Release(self.tooltip);
    end
end


-- --------------------------------------------------------------------------
-- NAME : TP.Button_OnEnter(button)
-- DESC : Displays the sorted list of food items
-- USE  : _OnEnter handler from the XML file
-- --------------------------------------------------------------------------
function TP.Button_OnEnter(self)
    if self.tooltip then
        LibQTip:Release(self.tooltip);
    end

    must_display_tooltip = true;
    RequestTimePlayed();
end


-- --------------------------------------------------------------------------
-- NAME : TitanPanelRightClickMenu_PreparePlayedMenu()
-- DESC : Display rightclick menu options
-- --------------------------------------------------------------------------
function TitanPanelRightClickMenu_PreparePlayedMenu()
    TitanPanelRightClickMenu_AddTitle(TitanPlugins[TP.id].menuText);
    TitanPanelRightClickMenu_AddCommand(TP.menu_hide, TP.id, TITAN_PANEL_MENU_FUNC_HIDE);
end



function TP.CopySession(session)
    return { played   = session.played;
             money    = session.money;
             apexis   = session.apexis;
             garrison = session.garrison;
             conquest = session.conquest;
             honor    = session.honor;
           };
end

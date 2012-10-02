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


-- ***************************** SAVED VARIABLES ****************************

TitanPlayedTimes = {};


-- ******************************** VARIABLES *******************************

local tooltip              = nil;
local must_display_tooltip = false
local reference_time       = nil;
local current_entry        = nil;


-- ******************************** FUNCTIONS *******************************

local chat_filter = function(frame, event, message, ...)
    if message:find("Temps de jeu total: ") then
        return true
    end
end


-- --------------------------------------------------------------------------
-- NAME : TitanPlayed.Button_OnLoad()
-- DESC : Registers the plugin upon it loading
-- --------------------------------------------------------------------------
function TP.Button_OnLoad(self)
-- SDK : "registry" is the data structure Titan uses to addon info it is displaying.
--       This is the critical structure!
-- SDK : This works because the button inherits from a Titan template. In this case
--       TitanPanelComboTemplate in the XML.
-- NOTE: LDB (LibDataBroker) type addons are NOT in the scope of this example.
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
    self:RegisterEvent("PLAYER_LEAVING_WORLD");
    self:RegisterEvent("TIME_PLAYED_MSG");

    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", chat_filter);
end


-- --------------------------------------------------------------------------
-- NAME : TP.Button_OnEvent()
-- DESC : Parse events registered to plugin and act on them
-- USE  : _OnEvent handler from the XML file
-- --------------------------------------------------------------------------
function TP.Button_OnEvent(self, event, ...)
    local name = UnitName("player")

    if (event == "ADDON_LOADED") then
        local current_time = time()
        current_entry = current_time - (current_time % (3600 * 24))

        if (TitanPlayedTimes[name] == nil) then
            localizedClass, englishClass = UnitClass("player");
            TitanPlayedTimes[name] = {};
            TitanPlayedTimes[name].class = englishClass;
        end

        if (TitanPlayedTimes[name][current_entry] == nil) then
            TitanPlayedTimes[name][current_entry] = 0;
            TitanPlayedTimes[name].last = current_entry;
        end

    elseif (event == "PLAYER_LEAVING_WORLD") then
        local current_time = time();
        local dest_entry = current_time - (current_time % (3600 * 24));

        if (dest_entry ~= current_entry) then
            TitanPlayedTimes[name][dest_entry] = TitanPlayedTimes[name][current_entry] + (current_time - reference_time);
            TitanPlayedTimes[name][current_entry] = TitanPlayedTimes[name][current_entry] + (dest_entry - reference_time);
            current_entry = dest_entry;
            reference_time = dest_entry;
            TitanPlayedTimes[name].last = current_entry;
        else
            TitanPlayedTimes[name][current_entry] = TitanPlayedTimes[name][current_entry] + (current_time - reference_time);
            reference_time = current_time;
        end

    elseif (event == "TIME_PLAYED_MSG") then
        local arg1, arg2 = ...;

        local current_time = time();
        local dest_entry = current_time - (current_time % (3600 * 24));

        if (dest_entry ~= current_entry) then
            TitanPlayedTimes[name][dest_entry] = arg1;
            TitanPlayedTimes[name][current_entry] = arg1 - (current_time - dest_entry);
            current_entry = dest_entry;
            TitanPlayedTimes[name].last = current_entry;
        else
            TitanPlayedTimes[name][current_entry] = arg1;
        end

        reference_time = current_time;

        if (must_display_tooltip) then
            self.tooltip = LibQTip:Acquire("TitanPlayed_Tooltip", 2, "LEFT", "LEFT");
            self.tooltip:Clear();

            local sorted_keys = {};
            for n, v in pairs(TitanPlayedTimes) do table.insert(sorted_keys, n) end

            table.sort(sorted_keys, function(a,b) return TitanPlayedTimes[a][TitanPlayedTimes[a].last] > TitanPlayedTimes[b][TitanPlayedTimes[b].last] end);

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

                local played = TitanPlayedTimes[name][TitanPlayedTimes[name].last];

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

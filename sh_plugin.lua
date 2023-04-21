PLUGIN.name = "Cyberpunk system"
PLUGIN.author = "Крыжовник#4511"
PLUGIN.desc = "Плагин вдохновленный схемой ReHost'а."

GM = GM or GAMEMODE

-- Вход в боевой режим
function PLUGIN:PlayerButtonDown(ply, button)
    if button == KEY_7 then
        ply:SetNWBool("InCombat", true)
    end

    if button == KEY_8 then
        ply:SetNWBool("CanMove", true)
    end
end

function PLUGIN:PlayerButtonUp(ply, button)
    if button == KEY_7 then
        ply:SetNWBool("InCombat", false)
    end

    if button == KEY_8 then
        ply:SetNWBool("CanMove", false)
    end
end
-- Начало хода
function GM:StartCommand(ply, cmd)
    if !ply:GetNWBool("CanMove") then
        cmd:ClearMovement()
        cmd:ClearButtons()
    end
end

-- Выбор цели
local function OpenMenu()
    local menu = vgui.Create("DFrame")
    menu:SetSize(ScrW() * 0.2, ScrH() * 0.2)
    menu:Center()
    menu:SetTitle("Выберите цель")
    menu:SetVisible(true)
    menu:SetDraggable(false)
    menu:ShowCloseButton(false)
    menu:MakePopup()

    local targetList = vgui.Create("DListView", menu)
    targetList:SetPos(10, 30)
    targetList:SetSize(menu:GetWide() - 20, menu:GetTall() - 60)
    targetList:AddColumn("Игрок")

    for _, ply in ipairs(player.GetAll()) do
        if ply != LocalPlayer() then
            targetList:AddLine(ply:Nick())
        end
    end

    local button = vgui.Create("DButton", menu)
    button:SetText("Нанести урон")
    button:SetPos(10, menu:GetTall() - 30)
    button:SetSize(menu:GetWide() - 20, 20)

    function button:DoClick()
        local selectedLine = targetList:GetSelectedLine()

        if selectedLine then
            local selectedPlayer = player.GetAll()[selectedLine]
            RunConsoleCommand("say", "/damage " .. selectedPlayer:SteamID64() .. " 10")
        end

        menu:Close()
    end
end

hook.Add("Think", "CheckForMouseClick", function()
    if input.IsMouseDown(MOUSE_LEFT) and input.IsKeyDown(KEY_C) then
        OpenMenu()
    end
end)

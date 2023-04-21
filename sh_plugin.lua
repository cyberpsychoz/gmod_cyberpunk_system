PLUGIN.name = "Cyberpunk system"
PLUGIN.author = "Крыжовник#4511"
PLUGIN.desc = "Плагин вдохновленный схемой ReHost'а."

function GM:PlayerButtonDown(ply, button)
    if button == KEY_H then
        ply:SetNWBool("CombatMode", !ply:GetNWBool("CombatMode"))
        if ply:GetNWBool("CombatMode") then
            ply:SetMoveType(MOVETYPE_NONE)
            timer.Simple(0.1, function()
                ply:ChatPrint(ply:Nick() .. " вошел в боевой режим!")
            end)
        else
            ply:SetMoveType(MOVETYPE_WALK)
            timer.Simple(0.1, function()
                ply:ChatPrint(ply:Nick() .. " вышел из боевого режима!")
            end)
        end
    end
end

hook.Add("OnContextMenuOpen", "AddTargetOption", function()
    local menu = DermaMenu()
    for _, ply in ipairs(player.GetAll()) do
        if ply ~= LocalPlayer() then
            menu:AddOption("Сделать целью", function()
                net.Start("SetTarget")
                net.WriteEntity(ply)
                net.SendToServer()
            end)
        end
    end
    menu:Open()
end)

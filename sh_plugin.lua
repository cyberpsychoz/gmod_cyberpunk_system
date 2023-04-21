PLUGIN.name = "Cyberpunk system"
PLUGIN.author = "Крыжовник#4511"
PLUGIN.desc = "Плагин вдохновленный схемой ReHost'а."

function GM:PlayerButtonDown(ply, button)
    if button == KEY_H then
        ply:SetNWBool("CombatMode", !ply:GetNWBool("CombatMode"))
        if ply:GetNWBool("CombatMode") then
            ply:SetMoveType(MOVETYPE_NONE)
            timer.Simple(0.1, function()
                ply:ChatPrint(ply:Nick() .. " включил боевой режим!")
            end)
        else
            ply:SetMoveType(MOVETYPE_WALK)
            timer.Simple(0.1, function()
                ply:ChatPrint(ply:Nick() .. " выключил боевой режим!")
            end)
        end
    end
end

PLUGIN.name = "Cyberpunk system"
PLUGIN.author = "Крыжовник#4511"
PLUGIN.desc = "Плагин вдохновленный схемой ReHost'а."

hook.Add("PlayerButtonDown", "CombatMode", function(ply, button)
    if button == KEY_7 then
        ply:SetNWBool("CombatMode", !ply:GetNWBool("CombatMode"))
        if ply:GetNWBool("CombatMode") then
            ply:SetMoveType(MOVETYPE_NONE)
            ply:ChatPrint("Вы включили боевой режим!")
        else
            ply:SetMoveType(MOVETYPE_WALK)
            ply:ChatPrint("Вы выключили боевой режим!")
        end
    end
end)

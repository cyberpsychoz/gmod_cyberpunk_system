PLUGIN.name = "Cyberpunk system"
PLUGIN.author = "Крыжовник#4511"
PLUGIN.desc = "Плагин вдохновленный схемой ReHost'а."

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

function GM:StartCommand(ply, cmd)
    if !ply:GetNWBool("CanMove") then
        cmd:ClearMovement()
        cmd:ClearButtons()
    end
end

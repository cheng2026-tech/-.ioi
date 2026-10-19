local function sendNotification(title, text)
    task.spawn(function()
        local success = false
        local retryTimes = 0
        while not success and retryTimes < 5 do
            retryTimes += 1
            success = pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification",{
                    Title = title,
                    Text = text,
                    Icon = "rbxthumb://type=Asset&id=5107182114&w=150&h=150",
                    Duration = 2
                })
            end)
            if not success then
                task.wait(0.2)
            end
        end
    end)
end

local function loadFlightScript()
    local success, err = pcall(function()
        do
            local main=Instance.new("ScreenGui")
            local Frame=Instance.new("Frame")
            local up=Instance.new("TextButton")
            local down=Instance.new("TextButton")
            local onof=Instance.new("TextButton")
            local TextLabel=Instance.new("TextLabel")
            local plus=Instance.new("TextButton")
            local speed=Instance.new("TextLabel")
            local mine=Instance.new("TextButton")
            local closebutton=Instance.new("TextButton")
            local mini=Instance.new("TextButton")
            local mini2=Instance.new("TextButton")
            main.Name="main"
            main.Parent=game.Players.LocalPlayer:WaitForChild("PlayerGui")
            main.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
            main.ResetOnSpawn=false
            Frame.Parent=main
            Frame.BackgroundColor3=Color3.fromRGB(163,255,137)
            Frame.BorderColor3=Color3.fromRGB(103,221,213)
            Frame.Position=UDim2.new(0.100320168,0,0.379746825,0)
            Frame.Size=UDim2.new(0,190,0,57)
            up.Name="up"
            up.Parent=Frame
            up.BackgroundColor3=Color3.fromRGB(79,255,152)
            up.Size=UDim2.new(0,44,0,28)
            up.Font=Enum.Font.SourceSans
            up.Text="上升"
            up.TextColor3=Color3.fromRGB(0,0,0)
            up.TextSize=14
            down.Name="down"
            down.Parent=Frame
            down.BackgroundColor3=Color3.fromRGB(215,255,121)
            down.Position=UDim2.new(0,0,0.491228074,0)
            down.Size=UDim2.new(0,44,0,28)
            down.Font=Enum.Font.SourceSans
            down.Text="下落"
            down.TextColor3=Color3.fromRGB(0,0,0)
            down.TextSize=14
            onof.Name="onof"
            onof.Parent=Frame
            onof.BackgroundColor3=Color3.fromRGB(255,249,74)
            onof.Position=UDim2.new(0.702823281,0,0.491228074,0)
            onof.Size=UDim2.new(0,56,0,28)
            onof.Font=Enum.Font.SourceSans
            onof.Text="飞"
            onof.TextColor3=Color3.fromRGB(0,0,0)
            onof.TextSize=14
            TextLabel.Parent=Frame
            TextLabel.BackgroundColor3=Color3.fromRGB(242,60,255)
            TextLabel.Position=UDim2.new(0.469327301,0,0,0)
            TextLabel.Size=UDim2.new(0,100,0,28)
            TextLabel.Font=Enum.Font.SourceSans
            TextLabel.Text="黑飞行"
            TextLabel.TextColor3=Color3.fromRGB(0,0,0)
            TextLabel.TextScaled=true
            TextLabel.TextSize=14
            TextLabel.TextWrapped=true
            plus.Name="plus"
            plus.Parent=Frame
            plus.BackgroundColor3=Color3.fromRGB(133,145,255)
            plus.Position=UDim2.new(0.231578946,0,0,0)
            plus.Size=UDim2.new(0,45,0,28)
            plus.Font=Enum.Font.SourceSans
            plus.Text="+"
            plus.TextColor3=Color3.fromRGB(0,0,0)
            plus.TextScaled=true
            plus.TextSize=14
            plus.TextWrapped=true
            speed.Name="speed"
            speed.Parent=Frame
            speed.BackgroundColor3=Color3.fromRGB(255,85,0)
            speed.Position=UDim2.new(0.468421042,0,0.491228074,0)
            speed.Size=UDim2.new(0,44,0,28)
            speed.Font=Enum.Font.SourceSans
            speed.Text="1"
            speed.TextColor3=Color3.fromRGB(0,0,0)
            speed.TextScaled=true
            speed.TextSize=14
            speed.TextWrapped=true
            mine.Name="mine"
            mine.Parent=Frame
            mine.BackgroundColor3=Color3.fromRGB(123,255,247)
            mine.Position=UDim2.new(0.231578946,0,0.491228074,0)
            mine.Size=UDim2.new(0,45,0,29)
            mine.Font=Enum.Font.SourceSans
            mine.Text="-"
            mine.TextColor3=Color3.fromRGB(0,0,0)
            mine.TextScaled=true
            mine.TextSize=14
            mine.TextWrapped=true
            closebutton.Name="Close"
            closebutton.Parent=Frame
            closebutton.BackgroundColor3=Color3.fromRGB(225,25,0)
            closebutton.Font=Enum.Font.SourceSans
            closebutton.Size=UDim2.new(0,45,0,28)
            closebutton.Text="X"
            closebutton.TextSize=30
            closebutton.Position=UDim2.new(0,0,-1,27)
            mini.Name="minimize"
            mini.Parent=Frame
            mini.BackgroundColor3=Color3.fromRGB(192,150,230)
            mini.Font=Enum.Font.SourceSans
            mini.Size=UDim2.new(0,45,0,28)
            mini.Text="-"
            mini.TextSize=40
            mini.Position=UDim2.new(0,44,-1,27)
            mini2.Name="minimize2"
            mini2.Parent=Frame
            mini2.BackgroundColor3=Color3.fromRGB(192,150,230)
            mini2.Font=Enum.Font.SourceSans
            mini2.Size=UDim2.new(0,45,0,28)
            mini2.Text="+"
            mini2.TextSize=40
            mini2.Position=UDim2.new(0,44,0,30)
            mini2.Visible=false
            speeds = 1
            local speaker=game:GetService("Players").LocalPlayer
            local chr=game.Players.LocalPlayer.Character
            local hum=chr and chr:FindFirstChildWhichIsA("Humanoid")
            nowe=false
            game:GetService("StarterGui"):SetCore("SendNotification",{
                Title="黑飞行",
                Text="创作者：c studio",
                Icon="rbxthumb://type=Asset&id=5107182114&w=150&h=150"
            })
            Frame.Active=true
            Frame.Draggable=true
            closebutton.MouseButton1Click:Connect(function()
                main:Destroy()
            end)
            up.MouseButton1Click:Connect(function()
                if chr and chr:FindFirstChild("HumanoidRootPart") then
                    chr.HumanoidRootPart.CFrame = chr.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                end
            end)
            down.MouseButton1Click:Connect(function()
                if chr and chr:FindFirstChild("HumanoidRootPart") then
                    chr.HumanoidRootPart.CFrame = chr.HumanoidRootPart.CFrame + Vector3.new(0, -3, 0)
                end
            end)
            mini.MouseButton1Click:Connect(function()
                up.Visible = false
                down.Visible = false
                onof.Visible = false
                plus.Visible = false
                speed.Visible = false
                mine.Visible = false
                closebutton.Visible = false
                mini.Visible = false
                mini2.Visible = true
                Frame.Size = UDim2.new(0, 100, 0, 28)
                TextLabel.Position = UDim2.new(0, 0, 0, 0)
            end)
            mini2.MouseButton1Click:Connect(function()
                up.Visible = true
                down.Visible = true
                onof.Visible = true
                plus.Visible = true
                speed.Visible = true
                mine.Visible = true
                closebutton.Visible = true
                mini.Visible = true
                mini2.Visible = false
                Frame.Size = UDim2.new(0, 190, 0, 57)
                TextLabel.Position = UDim2.new(0.469327301, 0, 0, 0)
            end)
            plus.MouseButton1Click:Connect(function()
                speeds = speeds + 1
                speed.Text = tostring(speeds)
            end)
            mine.MouseButton1Click:Connect(function()
                if speeds > 1 then
                    speeds = speeds - 1
                    speed.Text = tostring(speeds)
                else
                    speed.Text = "错误"
                    task.wait(0.2)
                    speed.Text = "1"
                end
            end)
            local moveConnection = nil
            local renderConnection = nil
            local currentBg = nil
            local currentBv = nil
            local function startFlight()
                if moveConnection then
                    moveConnection:Disconnect()
                    moveConnection = nil
                end
                if renderConnection then
                    renderConnection:Disconnect()
                    renderConnection = nil
                end
                if currentBg then
                    currentBg:Destroy()
                    currentBg = nil
                end
                if currentBv then
                    currentBv:Destroy()
                    currentBv = nil
                end
                if hum then
                    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Flying,false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Freefall,false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Landed,false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Physics,false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Running,false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Swimming,false)
                    hum:ChangeState(Enum.HumanoidStateType.Swimming)
                end
                if chr.Animate then
                    chr.Animate.Disabled=true
                end
                if hum then
                    for i,v in next,hum:GetPlayingAnimationTracks() do
                        v:AdjustSpeed(0)
                    end
                end
                local runService = game:GetService("RunService")
                moveConnection = runService.Heartbeat:Connect(function()
                    if not nowe or not chr or not hum then
                        moveConnection:Disconnect()
                        moveConnection = nil
                        return
                    end
                    if hum.MoveDirection.Magnitude > 0 then
                        chr:TranslateBy(hum.MoveDirection * speeds)
                    end
                end)
                if hum.RigType==Enum.HumanoidRigType.R6 then
                    local torso=chr:WaitForChild("Torso")
                    local bg=Instance.new("BodyGyro",torso)
                    bg.P=9e4
                    bg.maxTorque=Vector3.new(9e9,9e9,9e9)
                    bg.CFrame=torso.CFrame
                    local bv=Instance.new("BodyVelocity",torso)
                    bv.Velocity=Vector3.new(0,0,0)
                    bv.MaxForce=Vector3.new(9e9,9e9,9e9)
                    if nowe then
                        hum.PlatformStand=true
                    end
                    currentBg = bg
                    currentBv = bv
                    renderConnection = game:GetService("RunService").RenderStepped:Connect(function()
                        if not nowe or not chr or not hum or hum.Health<=0 or not bg.Parent then
                            renderConnection:Disconnect()
                            renderConnection = nil
                            bg:Destroy()
                            bv:Destroy()
                            currentBg = nil
                            currentBv = nil
                            if hum then
                                hum.PlatformStand=false
                            end
                            if chr and chr.Animate then
                                chr.Animate.Disabled=false
                            end
                            return
                        end
                        if chr:FindFirstChild("Torso") then
                            bg.CFrame=workspace.CurrentCamera.CoordinateFrame
                        end
                    end)
                else
                    local UpperTorso=chr:WaitForChild("UpperTorso")
                    local bg=Instance.new("BodyGyro",UpperTorso)
                    bg.P=9e4
                    bg.maxTorque=Vector3.new(9e9,9e9,9e9)
                    bg.CFrame=UpperTorso.CFrame
                    local bv=Instance.new("BodyVelocity",UpperTorso)
                    bv.Velocity=Vector3.new(0,0,0)
                    bv.MaxForce=Vector3.new(9e9,9e9,9e9)
                    if nowe then
                        hum.PlatformStand=true
                    end
                    currentBg = bg
                    currentBv = bv
                    renderConnection = game:GetService("RunService").RenderStepped:Connect(function()
                        if not nowe or not chr or not hum or hum.Health<=0 or not bg.Parent then
                            renderConnection:Disconnect()
                            renderConnection = nil
                            bg:Destroy()
                            bv:Destroy()
                            currentBg = nil
                            currentBv = nil
                            if hum then
                                hum.PlatformStand=false
                            end
                            if chr and chr.Animate then
                                chr.Animate.Disabled=false
                            end
                            return
                        end
                        if chr:FindFirstChild("UpperTorso") then
                            bg.CFrame=workspace.CurrentCamera.CoordinateFrame
                        end
                    end)
                end
            end
            local function stopFlight()
                if moveConnection then
                    moveConnection:Disconnect()
                    moveConnection = nil
                end
                if renderConnection then
                    renderConnection:Disconnect()
                    renderConnection = nil
                end
                if currentBg then
                    currentBg:Destroy()
                    currentBg = nil
                end
                if currentBv then
                    currentBv:Destroy()
                    currentBv = nil
                end
                if hum then
                    for _, state in pairs(Enum.HumanoidStateType:GetEnumItems()) do
                        hum:SetStateEnabled(state, true)
                    end
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                    hum.PlatformStand = false
                end
                if chr and chr.Animate then
                    chr.Animate.Disabled=false
                end
            end
            speaker.CharacterAdded:Connect(function(newChar)
                nowe = false
                onof.Text = "飞"
                stopFlight()
                chr = newChar
                hum = chr:WaitForChild("Humanoid")
            end)
            onof.MouseButton1Click:Connect(function()
                nowe = not nowe
                onof.Text = nowe and "飞" or "飞"
                if nowe then
                    startFlight()
                else
                    stopFlight()
                end
            end)
        end
    end)
    if success then
        sendNotification("功能召唤", "飞行脚本已成功加载")
    else
        sendNotification("加载失败", "飞行脚本出错："..tostring(err))
    end
end
loadFlightScript()
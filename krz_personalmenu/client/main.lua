--[[print("^0======================================================================^7")
print("^0[^4Author^0] ^7:^0 ^0Korioz^7")
print("^0[^3Version^0] ^7:^0 ^02.0^7")
print("^0[^2Download^0] ^7:^0 ^5https://github.com/korioz/krz_personalmenu/releases^7")
print("^0[^1Issues^0] ^7:^0 ^5https://github.com/korioz/krz_personalmenu/issues^7")
print("^0======================================================================^7")
]]
ESX = nil

local PersonalMenu = {
	ItemSelected = {},
	ItemIndex = {},
	WeaponData = {},
	WalletIndex = {},
	WalletList = {_U('wallet_option_give'), _U('wallet_option_drop')},
	BillData = {},
	ClothesButtons = {'torso', 'pants', 'shoes', 'bag', 'bproof', 'hat', 'ear', 'briller', 'maske'},
	DoorState = {
		FrontLeft = false,
		FrontRight = false,
		BackLeft = false,
		BackRight = false,
		Hood = false,
		Trunk = false
	},
	DoorIndex = 1,
	DoorList = {_U('vehicle_door_frontleft'), _U('vehicle_door_frontright'), _U('vehicle_door_backleft'), _U('vehicle_door_backright')},
	GPSIndex = 1,
	GPSList = {},
	VoiceIndex = 2,
	VoiceList = {}
}

Player = {
	isDead = true,
	inAnim = false,
	crouched = false,
	handsup = false,
	pointing = false,
	noclip = false,
	godmode = false,
	ghostmode = false,
	showCoords = false,
	showName = false,
	gamerTags = {},
	group = 'user'
}

local societymoney, societymoney2 = nil, nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(10)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	if Config.DoubleJob then
		while ESX.GetPlayerData().job2 == nil do
			Citizen.Wait(10)
		end
	end

	ESX.PlayerData = ESX.GetPlayerData()

	while actualSkin == nil do
		TriggerEvent('skinchanger:getSkin', function(skin)
			actualSkin = skin
		end)

		Citizen.Wait(10)
	end

	RefreshMoney()

	if Config.DoubleJob then
		RefreshMoney2()
	end

	PersonalMenu.WeaponData = ESX.GetWeaponList()

	for i = 1, #PersonalMenu.WeaponData, 1 do
		if PersonalMenu.WeaponData[i].name == 'WEAPON_UNARMED' then
			PersonalMenu.WeaponData[i] = nil
		else
			PersonalMenu.WeaponData[i].hash = GetHashKey(PersonalMenu.WeaponData[i].name)
		end
	end



	RMenu.Add('rageui', 'personal', RageUI.CreateMenu("Hovedmenu", "Personlig Menu", 0, 0, 'commonmenu', 'interaction_bgd', 255, 255, 255, 255))
	RMenu.Add('personal', 'wallet', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), _U('wallet_title')))
	RMenu.Add('personal', 'clothes', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), _U('clothes_title')))
--	RMenu.Add('personal', 'animation', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), _U('animation_title')))
	RMenu.Add('personal', 'vehicle', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), _U('vehicle_title')), function()
		if IsPedSittingInAnyVehicle(plyPed) then
			if (GetPedInVehicleSeat(GetVehiclePedIsIn(plyPed, false), -1) == plyPed) then
				return true
			end
		end

		return false
	end)

	RMenu.Add('personal', 'boss', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), _U('bossmanagement_title')), function()
		if ESX.PlayerData.job ~= nil and ESX.PlayerData.job.grade_name == 'boss' then
			return true
		end

		return false
	end)

	if Config.DoubleJob then
		RMenu.Add('personal', 'boss2', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), _U('bossmanagement2_title')), function()
			if Config.DoubleJob then
				if ESX.PlayerData.job2 ~= nil and ESX.PlayerData.job2.grade_name == 'boss' then
					return true
				end
			end

			return false
		end)
	end

	RMenu.Add('personal', 'admin', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), _U('admin_title')), function()
		if Player.group ~= nil and (Player.group == 'mod' or Player.group == 'admin' or Player.group == 'superadmin' or Player.group == 'owner' or Player.group == '_dev') then
			return true
		end

		return false
	end)

	for i = 1, #Config.Animations, 1 do
		RMenu.Add('animation', Config.Animations[i].name, RageUI.CreateSubMenu(RMenu.Get('personal', 'animation'), Config.Animations[i].label))
	end

	---------------------- PERSON FUNKTIONER START
	RMenu.Add('personal', 'pfunktioner', RageUI.CreateSubMenu(RMenu.Get('rageui', 'personal'), "Funktioner"))

	--RMenu.Add('pfunktioner', 'stripson', RageUI.CreateSubMenu(RMenu.Get('personal', 'pfunktioner'), "Giv strips på"))
	--RMenu.Add('pfunktioner', 'stripsoff', RageUI.CreateSubMenu(RMenu.Get('personal', 'pfunktioner'), "Tag strips af"))
	---------------------- PERSON FUNKTIONER SLUT
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
end)

AddEventHandler('esx:onPlayerDeath', function()
	Player.isDead = false
	RageUI.CloseAll()
	ESX.UI.Menu.CloseAll()
end)

AddEventHandler('playerSpawned', function()
	Player.isDead = false
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
	RefreshMoney()
end)

RegisterNetEvent('esx:setJob2')
AddEventHandler('esx:setJob2', function(job2)
	ESX.PlayerData.job2 = job2
	RefreshMoney2()
end)

RegisterNetEvent('esx_addonaccount:setMoney')
AddEventHandler('esx_addonaccount:setMoney', function(society, money)
	if ESX.PlayerData.job ~= nil and ESX.PlayerData.job.grade_name == 'boss' and 'society_' .. ESX.PlayerData.job.name == society then
		UpdateSocietyMoney(money)
	end
	if ESX.PlayerData.job2 ~= nil and ESX.PlayerData.job2.grade_name == 'boss' and 'society_' .. ESX.PlayerData.job2.name == society then
		UpdateSociety2Money(money)
	end
end)

-- Admin Menu --
RegisterNetEvent('KorioZ-PersonalMenu:Admin_BringC')
AddEventHandler('KorioZ-PersonalMenu:Admin_BringC', function(plyCoords)
	SetEntityCoords(plyPed, plyCoords)
end)

function RefreshMoney()
	if ESX.PlayerData.job ~= nil and ESX.PlayerData.job.grade_name == 'boss' then
		ESX.TriggerServerCallback('esx_society:getSocietyMoney', function(money)
			UpdateSocietyMoney(money)
		end, ESX.PlayerData.job.name)
	end
end

function RefreshMoney2()
	if ESX.PlayerData.job2 ~= nil and ESX.PlayerData.job2.grade_name == 'boss' then
		ESX.TriggerServerCallback('esx_society:getSocietyMoney', function(money)
			UpdateSociety2Money(money)
		end, ESX.PlayerData.job2.name)
	end
end

function UpdateSocietyMoney(money)
	societymoney = ESX.Math.GroupDigits(money)
end

function UpdateSociety2Money(money)
	societymoney2 = ESX.Math.GroupDigits(money)
end

--Message text joueur
function Text(text)
	SetTextColour(186, 186, 186, 255)
	SetTextFont(0)
	SetTextScale(0.378, 0.378)
	SetTextWrap(0.0, 1.0)
	SetTextCentre(false)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 205)
	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(0.017, 0.977)
end

function KeyboardInput(entryTitle, textEntry, inputText, maxLength)
	AddTextEntry(entryTitle, textEntry)
	DisplayOnscreenKeyboard(1, entryTitle, '', inputText, '', '', '', maxLength)
	blockinput = true

	while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
		Citizen.Wait(0)
	end

	if UpdateOnscreenKeyboard() ~= 2 then
		local result = GetOnscreenKeyboardResult()
		Citizen.Wait(500)
		blockinput = false
		return result
	else
		Citizen.Wait(500)
		blockinput = false
		return nil
	end
end

function getCamDirection()
	local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(plyPed)
	local pitch = GetGameplayCamRelativePitch()
	local coords = vector3(-math.sin(heading * math.pi / 180.0), math.cos(heading * math.pi / 180.0), math.sin(pitch * math.pi / 180.0))
	local len = math.sqrt((coords.x * coords.x) + (coords.y * coords.y) + (coords.z * coords.z))

	if len ~= 0 then
		coords = coords / len
	end

	return coords
end

function startAttitude(lib, anim)
	ESX.Streaming.RequestAnimSet(anim, function()
		SetPedMotionBlur(plyPed, false)
		SetPedMovementClipset(plyPed, anim, true)
		RemoveAnimSet(anim)
	end)
end

function startAnim(lib, anim)
	ESX.Streaming.RequestAnimDict(lib, function()
		TaskPlayAnim(plyPed, lib, anim, 8.0, -8.0, -1, 0, 0, false, false, false)
		RemoveAnimDict(lib)
	end)
end

function startAnimAction(lib, anim)
	ESX.Streaming.RequestAnimDict(lib, function()
		TaskPlayAnim(plyPed, lib, anim, 8.0, 1.0, -1, 49, 0, false, false, false)
		RemoveAnimDict(lib)
	end)
end

function setUniform(value, plyPed)
	ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
		TriggerEvent('skinchanger:getSkin', function(skina)
			if value == 'torso' then
				startAnimAction('clothingtie', 'try_tie_neutral_a')
				Citizen.Wait(3000)
				--Player.handsup, Player.pointing = false, false
				ClearPedTasks(plyPed)

				if skin.torso_1 ~= skina.torso_1 then
					TriggerEvent('skinchanger:loadClothes', skina, {['torso_1'] = skin.torso_1, ['torso_2'] = skin.torso_2, ['tshirt_1'] = skin.tshirt_1, ['tshirt_2'] = skin.tshirt_2, ['arms'] = skin.arms})
				else
					TriggerEvent('skinchanger:loadClothes', skina, {['torso_1'] = 91, ['torso_2'] = 0, ['tshirt_1'] = 15, ['tshirt_2'] = 0, ['arms'] = 15})
				end
			elseif value == 'pants' then
				startAnimAction('re@construction', 'out_of_breath')
				Citizen.Wait(1000)
				--Player.handsup, Player.pointing = false, false
				ClearPedTasks(plyPed)

				if skin.pants_1 ~= skina.pants_1 then
					TriggerEvent('skinchanger:loadClothes', skina, {['pants_1'] = skin.pants_1, ['pants_2'] = skin.pants_2})
				else
					if skin.sex == 0 then
						TriggerEvent('skinchanger:loadClothes', skina, {['pants_1'] = 61, ['pants_2'] = 1})
					else
						TriggerEvent('skinchanger:loadClothes', skina, {['pants_1'] = 15, ['pants_2'] = 0})
					end
				end
			elseif value == 'shoes' then
				startAnimAction('random@domestic', 'pickup_low')
				Citizen.Wait(3000)
				--Player.handsup, Player.pointing = false, false
				ClearPedTasks(plyPed)
				if skin.shoes_1 ~= skina.shoes_1 then
					TriggerEvent('skinchanger:loadClothes', skina, {['shoes_1'] = skin.shoes_1, ['shoes_2'] = skin.shoes_2})
				else
					if skin.sex == 0 then
						TriggerEvent('skinchanger:loadClothes', skina, {['shoes_1'] = 34, ['shoes_2'] = 0})
					else
						TriggerEvent('skinchanger:loadClothes', skina, {['shoes_1'] = 35, ['shoes_2'] = 0})
					end
				end
			elseif value == 'bag' then
				startAnimAction('anim@heists@ornate_bank@grab_cash', 'intro')
				Citizen.Wait(1000)
				Player.handsup, Player.pointing = false, false
				ClearPedTasks(plyPed)

				if skin.bags_1 ~= skina.bags_1 then
					TriggerEvent('skinchanger:loadClothes', skina, {['bags_1'] = skin.bags_1, ['bags_2'] = skin.bags_2})
				else
					TriggerEvent('skinchanger:loadClothes', skina, {['bags_1'] = 0, ['bags_2'] = 0})
				end
			elseif value == 'bproof' then
				startAnimAction('clothingtie', 'try_tie_neutral_a')
				Citizen.Wait(3000)
				Player.handsup, Player.pointing = false, false
				ClearPedTasks(plyPed)

				if skin.bproof_1 ~= skina.bproof_1 then
					TriggerEvent('skinchanger:loadClothes', skina, {['bproof_1'] = skin.bproof_1, ['bproof_2'] = skin.bproof_2})
				else
					TriggerEvent('skinchanger:loadClothes', skina, {['bproof_1'] = 0, ['bproof_2'] = 0})
				end
			elseif value == 'hat' then				
				if skin.helmet_1 ~= skina.helmet_1 then
					startAnimAction('mp_masks@standard_car@ds@', 'put_on_mask')
					Citizen.Wait(600)
					Player.handsup, Player.pointing = false, false
					ClearPedTasks(plyPed)
					TriggerEvent('skinchanger:loadClothes', skina, {['helmet_1'] = skin.helmet_1, ['helmet_2'] = skin.helmet_2})
				else
					startAnimAction('missheist_agency2ahelmet', 'take_off_helmet_stand')
					Citizen.Wait(1000)
					Player.handsup, Player.pointing = false, false
					ClearPedTasks(plyPed)
					if skin.sex == 0 then
						TriggerEvent('skinchanger:loadClothes', skina, {['helmet_1'] = -1, ['helmet_2'] = 0})
					else
						TriggerEvent('skinchanger:loadClothes', skina, {['helmet_1'] = -1, ['helmet_2'] = 0})
					end
				end
			elseif value == 'ear' then
				startAnimAction('mp_cp_stolen_tut', 'b_think')
				Citizen.Wait(1000)
				Player.handsup, Player.pointing = false, false
				ClearPedTasks(plyPed)		
				if skin.ears_1 ~= skina.ears_1 then
					TriggerEvent('skinchanger:loadClothes', skina, {['ears_1'] = skin.ears_1, ['ears_2'] = skin.ears_2})
				else
					if skin.sex == 0 then
						TriggerEvent('skinchanger:loadClothes', skina, {['ears_1'] = -1, ['ears_2'] = 0})
					else
						TriggerEvent('skinchanger:loadClothes', skina, {['ears_1'] = -1, ['ears_2'] = 0})
					end
				end
			elseif value == 'briller' then
				startAnimAction('clothingspecs', 'take_off')
				Citizen.Wait(1000)
				Player.handsup, Player.pointing = false, false
				ClearPedTasks(plyPed)		
				if skin.glasses_1 ~= skina.glasses_1 then
					TriggerEvent('skinchanger:loadClothes', skina, {['glasses_1'] = skin.glasses_1, ['glasses_2'] = skin.glasses_2})
				else
					if skin.sex == 0 then
						TriggerEvent('skinchanger:loadClothes', skina, {['glasses_1'] = -1, ['glasses_2'] = 0})
					else
						TriggerEvent('skinchanger:loadClothes', skina, {['glasses_1'] = -1, ['glasses_2'] = 0})
					end
				end
			elseif value == 'maske' then
				startAnimAction('mp_masks@standard_car@ds@', 'put_on_mask')
				Citizen.Wait(1000)
				Player.handsup, Player.pointing = false, false
				ClearPedTasks(plyPed)		
				if skin.mask_1 ~= skina.mask_1 then
					TriggerEvent('skinchanger:loadClothes', skina, {['mask_1'] = skin.mask_1, ['mask_2'] = skin.mask_2})
				else
					if skin.sex == 0 then
						TriggerEvent('skinchanger:loadClothes', skina, {['mask_1'] = -1, ['mask_2'] = 0})
					else
						TriggerEvent('skinchanger:loadClothes', skina, {['mask_1'] = -1, ['mask_2'] = 0})
					end
				end
			end
		end)
	end)
end

function setAccessory(accessory)
	ESX.TriggerServerCallback('esx_accessories:get', function(hasAccessory, accessorySkin)
		local _accessory = (accessory):lower()

		if hasAccessory then
			TriggerEvent('skinchanger:getSkin', function(skin)
				local mAccessory = -1
				local mColor = 0

				if _accessory == 'ears' then
					startAnimAction('mini@ears_defenders', 'takeoff_earsdefenders_idle')
					Citizen.Wait(250)
					Player.handsup, Player.pointing = false, false
					ClearPedTasks(plyPed)
				elseif _accessory == 'glasses' then
					mAccessory = 0
					startAnimAction('clothingspecs', 'try_glasses_positive_a')
					Citizen.Wait(1000)
					Player.handsup, Player.pointing = false, false
					ClearPedTasks(plyPed)
				elseif _accessory == 'helmet' then
					startAnimAction('missfbi4', 'takeoff_mask')
					Citizen.Wait(1000)
					Player.handsup, Player.pointing = false, false
					ClearPedTasks(plyPed)
				elseif _accessory == 'mask' then
					mAccessory = 0
					startAnimAction('missfbi4', 'takeoff_mask')
					Citizen.Wait(850)
					Player.handsup, Player.pointing = false, false
					ClearPedTasks(plyPed)
				end

				if skin[_accessory .. '_1'] == mAccessory then
					mAccessory = accessorySkin[_accessory .. '_1']
					mColor = accessorySkin[_accessory .. '_2']
				end

				local accessorySkin = {}
				accessorySkin[_accessory .. '_1'] = mAccessory
				accessorySkin[_accessory .. '_2'] = mColor
				TriggerEvent('skinchanger:loadClothes', skin, accessorySkin)
			end)
		else
			if _accessory == 'ears' then
				ESX.ShowNotification(_U('accessories_no_ears'))
			elseif _accessory == 'glasses' then
				ESX.ShowNotification(_U('accessories_no_glasses'))
			elseif _accessory == 'helmet' then
				ESX.ShowNotification(_U('accessories_no_helmet'))
			elseif _accessory == 'mask' then
				ESX.ShowNotification(_U('accessories_no_mask'))
			end
		end
	end, accessory)
end

function RenderPersonalMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		for i = 1, #RMenu['personal'], 1 do
			if type(RMenu['personal'][i].Restriction) == 'function' then
				if RMenu['personal'][i].Restriction() then
					RageUI.Button(RMenu['personal'][i].Menu.Title, nil, {RightLabel = ""}, true, function() end, RMenu['personal'][i].Menu)
				else
					RageUI.Button(RMenu['personal'][i].Menu.Title, nil, {RightBadge = RageUI.BadgeStyle.Lock}, false, function() end, RMenu['personal'][i].Menu)
				end
			else
				RageUI.Button(RMenu['personal'][i].Menu.Title, nil, {RightLabel = ""}, true, function() end, RMenu['personal'][i].Menu)
			end
		end
	end)
end

function RenderWalletMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()

		if Config.JSFourIDCard then
			RageUI.Button(_U('wallet_show_idcard_button'), nil, {}, true, function(Hovered, Active, Selected)
				if (Selected) then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestDistance ~= -1 and closestDistance <= 3.0 then
						TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer))
						TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()))
					else
						TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()))
					end
				end
			end)

			RageUI.Button(_U('wallet_show_driver_button'), nil, {}, true, function(Hovered, Active, Selected)
				if (Selected) then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestDistance ~= -1 and closestDistance <= 3.0 then
						TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer), 'driver')
						TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()), 'driver')
					else
						TriggerServerEvent('jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()), 'driver')
					end
				end				
			end)

			RageUI.Button(_U('wallet_show_business_card_button'), nil, {}, true, function(Hovered, Active, Selected)
				if (Selected) then
					TriggerEvent('businessCard:openMenu')
					RageUI.CloseAll()
				end
			end)
		end
	end)
end

function RenderClothesMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		for i = 1, #PersonalMenu.ClothesButtons, 1 do
			RageUI.Button(_U(('clothes_%s'):format(PersonalMenu.ClothesButtons[i])), nil, {RightBadge = RageUI.BadgeStyle.Clothes}, true, function(Hovered, Active, Selected)
				if (Selected) then
					setUniform(PersonalMenu.ClothesButtons[i], plyPed)
				end
			end)
		end
	end)
end

function RenderAccessoriesMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		for i = 1, #PersonalMenu.AccessoriesButtons, 1 do
			RageUI.Button(_U(('accessories_%s'):format((PersonalMenu.AccessoriesButtons[i]:lower()))), nil, {RightBadge = RageUI.BadgeStyle.Clothes}, true, function(Hovered, Active, Selected)
				if (Selected) then
					setAccessory(PersonalMenu.AccessoriesButtons[i])
				end
			end)
		end
	end)
end

function RenderAnimationMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		for i = 1, #RMenu['animation'], 1 do
			RageUI.Button(RMenu['animation'][i].Menu.Title, nil, {RightLabel = "→→→"}, true, function() end, RMenu['animation'][i].Menu)
		end
	end)
end

function RenderAnimationsSubMenu(menu)
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		for i = 1, #Config.Animations, 1 do
			if Config.Animations[i].name == menu then
				for j = 1, #Config.Animations[i].items, 1 do
					RageUI.Button(Config.Animations[i].items[j].label, nil, {}, true, function(Hovered, Active, Selected)
						if (Selected) then
							if Config.Animations[i].items[j].type == 'anim' then
								startAnim(Config.Animations[i].items[j].data.lib, Config.Animations[i].items[j].data.anim)
							elseif Config.Animations[i].items[j].type == 'scenario' then
								TaskStartScenarioInPlace(plyPed, Config.Animations[i].items[j].data.anim, 0, false)
							elseif Config.Animations[i].items[j].type == 'attitude' then
								startAttitude(Config.Animations[i].items[j].data.lib, Config.Animations[i].items[j].data.anim)
							end
						end
					end)
				end
			end
		end
	end)
end

function RenderVehicleMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		RageUI.Button(_U('vehicle_engine_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if not IsPedSittingInAnyVehicle(plyPed) then
					ESX.ShowNotification(_U('no_vehicle'))
				elseif IsPedSittingInAnyVehicle(plyPed) then
					local plyVeh = GetVehiclePedIsIn(plyPed, false)

					if GetIsVehicleEngineRunning(plyVeh) then
						SetVehicleEngineOn(plyVeh, false, false, true)
						SetVehicleUndriveable(plyVeh, true)
					elseif not GetIsVehicleEngineRunning(plyVeh) then
						SetVehicleEngineOn(plyVeh, true, false, true)
						SetVehicleUndriveable(plyVeh, false)
					end
				end
			end
		end)

		RageUI.List(_U('vehicle_door_button'), PersonalMenu.DoorList, PersonalMenu.DoorIndex, nil, {}, true, function(Hovered, Active, Selected, Index)
			if (Selected) then
				if not IsPedSittingInAnyVehicle(plyPed) then
					ESX.ShowNotification(_U('no_vehicle'))
				elseif IsPedSittingInAnyVehicle(plyPed) then
					local plyVeh = GetVehiclePedIsIn(plyPed, false)

					if Index == 1 then
						if not PersonalMenu.DoorState.FrontLeft then
							PersonalMenu.DoorState.FrontLeft = true
							SetVehicleDoorOpen(plyVeh, 0, false, false)
						elseif PersonalMenu.DoorState.FrontLeft then
							PersonalMenu.DoorState.FrontLeft = false
							SetVehicleDoorShut(plyVeh, 0, false, false)
						end
					elseif Index == 2 then
						if not PersonalMenu.DoorState.FrontRight then
							PersonalMenu.DoorState.FrontRight = true
							SetVehicleDoorOpen(plyVeh, 1, false, false)
						elseif PersonalMenu.DoorState.FrontRight then
							PersonalMenu.DoorState.FrontRight = false
							SetVehicleDoorShut(plyVeh, 1, false, false)
						end
					elseif Index == 3 then
						if not PersonalMenu.DoorState.BackLeft then
							PersonalMenu.DoorState.BackLeft = true
							SetVehicleDoorOpen(plyVeh, 2, false, false)
						elseif PersonalMenu.DoorState.BackLeft then
							PersonalMenu.DoorState.BackLeft = false
							SetVehicleDoorShut(plyVeh, 2, false, false)
						end
					elseif Index == 4 then
						if not PersonalMenu.DoorState.BackRight then
							PersonalMenu.DoorState.BackRight = true
							SetVehicleDoorOpen(plyVeh, 3, false, false)
						elseif PersonalMenu.DoorState.BackRight then
							PersonalMenu.DoorState.BackRight = false
							SetVehicleDoorShut(plyVeh, 3, false, false)
						end
					end
				end
			end

			PersonalMenu.DoorIndex = Index
		end)

		RageUI.Button(_U('vehicle_hood_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if not IsPedSittingInAnyVehicle(plyPed) then
					ESX.ShowNotification(_U('no_vehicle'))
				elseif IsPedSittingInAnyVehicle(plyPed) then
					local plyVeh = GetVehiclePedIsIn(plyPed, false)

					if not PersonalMenu.DoorState.Hood then
						PersonalMenu.DoorState.Hood = true
						SetVehicleDoorOpen(plyVeh, 4, false, false)
					elseif PersonalMenu.DoorState.Hood then
						PersonalMenu.DoorState.Hood = false
						SetVehicleDoorShut(plyVeh, 4, false, false)
					end
				end
			end
		end)

		RageUI.Button(_U('vehicle_trunk_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if not IsPedSittingInAnyVehicle(plyPed) then
					ESX.ShowNotification(_U('no_vehicle'))
				elseif IsPedSittingInAnyVehicle(plyPed) then
					local plyVeh = GetVehiclePedIsIn(plyPed, false)

					if not PersonalMenu.DoorState.Trunk then
						PersonalMenu.DoorState.Trunk = true
						SetVehicleDoorOpen(plyVeh, 5, false, false)
					elseif PersonalMenu.DoorState.Trunk then
						PersonalMenu.DoorState.Trunk = false
						SetVehicleDoorShut(plyVeh, 5, false, false)
					end
				end
			end
		end)
	end)
end

function RenderBossMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		if societymoney ~= nil then
			RageUI.Button(_U('bossmanagement_chest_button'), nil, {RightLabel = '$' .. societymoney}, true, function() end)
		end

		RageUI.Button(_U('bossmanagement_hire_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if ESX.PlayerData.job.grade_name == 'boss' then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('players_nearby'))
					else
						TriggerServerEvent('KorioZ-PersonalMenu:Boss_recruterplayer', GetPlayerServerId(closestPlayer), ESX.PlayerData.job.name, 0)
					end
				else
					ESX.ShowNotification(_U('missing_rights'))
				end
			end
		end)

		RageUI.Button(_U('bossmanagement_fire_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if ESX.PlayerData.job.grade_name == 'boss' then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('players_nearby'))
					else
						TriggerServerEvent('KorioZ-PersonalMenu:Boss_virerplayer', GetPlayerServerId(closestPlayer))
					end
				else
					ESX.ShowNotification(_U('missing_rights'))
				end
			end
		end)

		RageUI.Button(_U('bossmanagement_promote_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if ESX.PlayerData.job.grade_name == 'boss' then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('players_nearby'))
					else
						TriggerServerEvent('KorioZ-PersonalMenu:Boss_promouvoirplayer', GetPlayerServerId(closestPlayer))
					end
				else
					ESX.ShowNotification(_U('missing_rights'))
				end
			end
		end)

		RageUI.Button(_U('bossmanagement_demote_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if ESX.PlayerData.job.grade_name == 'boss' then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('players_nearby'))
					else
						TriggerServerEvent('KorioZ-PersonalMenu:Boss_destituerplayer', GetPlayerServerId(closestPlayer))
					end
				else
					ESX.ShowNotification(_U('missing_rights'))
				end
			end
		end)
	end)
end

function RenderBoss2Menu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		if societymoney ~= nil then
			RageUI.Button(_U('bossmanagement2_chest_button'), nil, {RightLabel = '$' .. societymoney2}, true, function() end)
		end

		RageUI.Button(_U('bossmanagement2_hire_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if ESX.PlayerData.job2.grade_name == 'boss' then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('players_nearby'))
					else
						TriggerServerEvent('KorioZ-PersonalMenu:Boss_recruterplayer2', GetPlayerServerId(closestPlayer), ESX.PlayerData.job2.name, 0)
					end
				else
					ESX.ShowNotification(_U('missing_rights'))
				end
			end
		end)

		RageUI.Button(_U('bossmanagement2_fire_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if ESX.PlayerData.job2.grade_name == 'boss' then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('players_nearby'))
					else
						TriggerServerEvent('KorioZ-PersonalMenu:Boss_virerplayer2', GetPlayerServerId(closestPlayer))
					end
				else
					ESX.ShowNotification(_U('missing_rights'))
				end
			end
		end)

		RageUI.Button(_U('bossmanagement2_promote_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if ESX.PlayerData.job2.grade_name == 'boss' then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('players_nearby'))
					else
						TriggerServerEvent('KorioZ-PersonalMenu:Boss_promouvoirplayer2', GetPlayerServerId(closestPlayer))
					end
				else
					ESX.ShowNotification(_U('missing_rights'))
				end
			end
		end)

		RageUI.Button(_U('bossmanagement2_demote_button'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				if ESX.PlayerData.job2.grade_name == 'boss' then
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification(_U('players_nearby'))
					else
						TriggerServerEvent('KorioZ-PersonalMenu:Boss_destituerplayer2', GetPlayerServerId(closestPlayer))
					end
				else
					ESX.ShowNotification(_U('missing_rights'))
				end
			end
		end)
	end)
end

function RenderStripsMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		RageUI.Button(_U('fu_strips_on'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				ZiptiePlayer()
			end
		end)
		
		RageUI.Button(_U('fu_strips_off'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				unZiptiePlayer()
			end
		end)

		RageUI.Button(_U('fu_move'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				local player = PlayerId()
				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
				if closestPlayer == -1 or closestDistance > 3.0 then
					
				else
					if IsEntityPlayingAnim(GetPlayerPed(closestPlayer), "mp_arresting", "idle", 3) then
						TriggerServerEvent('3ddo:shareDisplay', "Eskorterer person")
						TriggerServerEvent('esx_zipties:drag', GetPlayerServerId(closestPlayer))
					else
						ESX.ShowNotification("Spilleren er ~r~ikke ~y~i strips~s~")
					end
				end
			end
		end)

		RageUI.Button(_U('fu_visiter'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				local player = PlayerId()
				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
				if closestPlayer == -1 or closestDistance > 3.0 then
					
				else
					if IsEntityPlayingAnim(GetPlayerPed(closestPlayer), "mp_arresting", "idle", 3) or IsPlayerDead(closestPlayer) then
						RageUI.CloseAll()
						OpenBodySearchMenu(closestPlayer)
					else
						ESX.ShowNotification("Spilleren er ~r~ikke ~y~i strips eller død~s~")
					end
				end
			end
		end)

		RageUI.Button(_U('fu_putin'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				local player = PlayerId()
				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
				if closestPlayer == -1 or closestDistance > 3.0 then
					
				else
					if IsEntityPlayingAnim(GetPlayerPed(closestPlayer), "mp_arresting", "idle", 3) then
						TriggerServerEvent('esx_zipties:putInVehicle', GetPlayerServerId(closestPlayer))
					end
				end
			end
		end)

		RageUI.Button(_U('fu_takeout'), nil, {}, true, function(Hovered, Active, Selected)
			if (Selected) then
				local player = PlayerId()
				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
				if closestPlayer == -1 or closestDistance > 3.0 then
					
				else
					if IsEntityPlayingAnim(GetPlayerPed(closestPlayer), "mp_arresting", "idle", 3) then
						TriggerServerEvent('esx_zipties:OutVehicle', GetPlayerServerId(closestPlayer))
					end
				end
			end
		end)
		
		--RageUI.Button(_U('fu_skin'), nil, {}, true, function(Hovered, Active, Selected)
		--	if (Selected) then
		--		RageUI.CloseAll()
		--		Citizen.Wait(1000)
		--		TriggerEvent('esx_skin:openSaveableMenu')
		--	end
		--end
	end)
end

function RenderAdminMenu()
	RageUI.DrawContent({header = true, instructionalButton = true}, function()
		for i = 1, #Config.Admin, 1 do
			local authorized = false

			for j = 1, #Config.Admin[i].groups, 1 do
				if Config.Admin[i].groups[j] == Player.group then
					authorized = true
				end
			end

			if authorized then
				RageUI.Button(Config.Admin[i].label, nil, {}, true, function(Hovered, Active, Selected)
					if (Selected) then
						Config.Admin[i].command()
					end
				end)
			else
				RageUI.Button(Config.Admin[i].label, nil, {RightBadge = RageUI.BadgeStyle.Lock}, false, function() end)
			end
		end
	end)
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if IsControlJustReleased(0, Config.Controls.OpenMenu.keyboard) and not Player.isDead then
			if not RageUI.Visible() then
				ESX.TriggerServerCallback('KorioZ-PersonalMenu:Admin_getUsergroup', function(plyGroup)
					Player.group = plyGroup

					ESX.TriggerServerCallback('KorioZ-PersonalMenu:Bill_getBills', function(bills)
						PersonalMenu.BillData = bills
						ESX.PlayerData = ESX.GetPlayerData()
						RageUI.Visible(RMenu.Get('rageui', 'personal'), true)
					end)
				end)
			end
		end

		if RageUI.Visible(RMenu.Get('rageui', 'personal')) then
			RenderPersonalMenu()
		end

		if RageUI.Visible(RMenu.Get('personal', 'clothes')) then
			RenderClothesMenu()
		end

		if RageUI.Visible(RMenu.Get('personal', 'wallet')) then
			RenderWalletMenu()
		end

		

		if RageUI.Visible(RMenu.Get('personal', 'animation')) then
			RenderAnimationMenu()
		end

		if RageUI.Visible(RMenu.Get('personal', 'vehicle')) then
			if not RMenu.Settings('personal', 'vehicle', 'Restriction')() then
				RageUI.GoBack()
			end
			RenderVehicleMenu()
		end

		if RageUI.Visible(RMenu.Get('personal', 'boss')) then
			if not RMenu.Settings('personal', 'boss', 'Restriction')() then
				RageUI.GoBack()
			end
			RenderBossMenu()
		end

		if RageUI.Visible(RMenu.Get('personal', 'boss2')) then
			if not RMenu.Settings('personal', 'boss2', 'Restriction')() then
				RageUI.GoBack()
			end
			RenderBoss2Menu()
		end

		if RageUI.Visible(RMenu.Get('personal', 'admin')) then
			if not RMenu.Settings('personal', 'admin', 'Restriction')() then
				RageUI.GoBack()
			end
			RenderAdminMenu()
		end

		if RageUI.Visible(RMenu.Get('personal', 'pfunktioner')) then
			RenderStripsMenu()
		end

		for i = 1, #Config.Animations, 1 do
			if RageUI.Visible(RMenu.Get('animation', Config.Animations[i].name)) then
				RenderAnimationsSubMenu(Config.Animations[i].name)
			end
		end
	end
end)

function ZiptiePlayer()
	local dict = "missminuteman_1ig_2"
	RequestAnimDict(dict)
	local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
	if closestPlayer == -1 or closestDistance > 3.0 then
		ESX.ShowNotification("Der er ingen spillere i nærheden")
	else
		ESX.TriggerServerCallback('esx_zipties:getItemAmount', function(zipties)
			if zipties > 0 then
				local playerPed = GetPlayerPed(-1)
					Citizen.CreateThread(function()
					TriggerServerEvent('esx_zipties:setziptie', GetPlayerServerId(closestPlayer))
					TriggerServerEvent('esx_zipties:removeItem', 'ziptie')
					TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 4, "stripson", 0.8)
				end)
			else
				ESX.ShowNotification("Du har ~r~ingen ~y~strips~s~")
			end
		end, 'zipties')
	end
end

RegisterCommand('sound', function()
	TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 4, "stripsoff", 0.8)
end)

function unZiptiePlayer()
	local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
	if closestPlayer == -1 or closestDistance > 3.0 then
		ESX.ShowNotification("Der er ingen spillere i nærheden")
	else
		TriggerServerEvent('esx_zipties:unsetziptie', GetPlayerServerId(closestPlayer))
		TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 4, "stripsoff", 0.8)
		ESX.ShowNotification("Du tog stripsne af den nærmeste spiller")
	end
end

function OpenBodySearchMenu(player)

	TriggerServerEvent('3ddo:shareDisplay', "Røver person")
	
	ESX.TriggerServerCallback('esx_zipties:getTargetPlayerData', function(data)
	  local elements = {}
  
	  local blackMoney = 0
  
	  for i=1, #data.accounts, 1 do
		if data.accounts[i].name == 'black_money' then
		  blackMoney = data.accounts[i].money
		end
	  end
  
	  table.insert(elements, {
		label          = 'Stjæl ' .. blackMoney .. ' sorte penge',
		value          = 'black_money',
		itemType       = 'item_account',
		amount         = blackMoney
	  })
  
	  table.insert(elements, {label = '--- Våben ---', value = nil})
  
	  for i=1, #data.weapons, 1 do
		table.insert(elements, {
		  label          = 'Stjæl ' .. ESX.GetWeaponLabel(data.weapons[i].name),
		  value          = data.weapons[i].name,
		  itemType       = 'item_weapon',
		  amount         = data.ammo,
		})
	  end
  
	  table.insert(elements, {label = '--- Inventar ---', value = nil})
  
	  for i=1, #data.inventory, 1 do
		if data.inventory[i].count > 0 then
		  table.insert(elements, {
			label          = 'Stjæl ' .. data.inventory[i].count .. ' ' .. data.inventory[i].label,
			value          = data.inventory[i].name,
			itemType       = 'item_standard',
			amount         = data.inventory[i].count,
		  })
		end
	  end
	  
	  ESX.UI.Menu.Open(
		'default', GetCurrentResourceName(), 'body_search',
		{
		  title    = 'Stjæl',
		  align    = 'top-left',
		  elements = elements,
		},
		function(data, menu)
		  local itemType = data.current.itemType
		  local itemName = data.current.value
		  local amount   = data.current.amount
		  print("YES")
  
		  if data.current.value ~= nil then
			TriggerServerEvent('esx_zipties:stealPlayerItem', GetPlayerServerId(player), itemType, itemName, amount)
			OpenBodySearchMenu(player)
		  end
		end,
		function(data, menu)
		  menu.close()
		end)
  
	end, GetPlayerServerId(player))
end

Citizen.CreateThread(function()
	while true do
		plyPed = PlayerPedId()

		

		Citizen.Wait(0)
	end
end)
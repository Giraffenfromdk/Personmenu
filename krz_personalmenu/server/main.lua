print("^0======================================================================^7")
print("^0[^4Author^0] ^7:^0 ^0Korioz^7")
print("^0[^3Version^0] ^7:^0 ^02.0^7")
print("^0[^2Download^0] ^7:^0 ^5https://github.com/korioz/krz_personalmenu/releases^7")
print("^0[^1Issues^0] ^7:^0 ^5https://github.com/korioz/krz_personalmenu/issues^7")
print("^0======================================================================^7")

ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function getMaximumGrade(jobname)
	local queryDone, queryResult = false, nil

	MySQL.Async.fetchAll('SELECT * FROM job_grades WHERE job_name = @jobname ORDER BY `grade` DESC ;', {
		['@jobname'] = jobname
	}, function(result)
		queryDone, queryResult = true, result
	end)

	while not queryDone do
		Citizen.Wait(10)
	end

	if queryResult[1] then
		return queryResult[1].grade
	end

	return nil
end

function getAdminCommand(name)
	for i = 1, #Config.Admin, 1 do
		if Config.Admin[i].name == name then
			return i
		end
	end

	return false
end

function isAuthorized(index, group)
	for i = 1, #Config.Admin[index].groups, 1 do
		if Config.Admin[index].groups[i] == group then
			return true
		end
	end

	return false
end

ESX.RegisterServerCallback('KorioZ-PersonalMenu:Bill_getBills', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local bills = {}

	MySQL.Async.fetchAll('SELECT * FROM billing WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)
		for i = 1, #result, 1 do
			table.insert(bills, {
				id = result[i].id,
				label = result[i].label,
				amount = result[i].amount
			})
		end

		cb(bills)
	end)
end)

ESX.RegisterServerCallback('KorioZ-PersonalMenu:Admin_getUsergroup', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local plyGroup = xPlayer.getGroup()

	if plyGroup ~= nil then 
		cb(plyGroup)
	else
		cb('user')
	end
end)

function ZiptiePlayer()
	local dict = "missminuteman_1ig_2"
	RequestAnimDict(dict)
	local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
	if closestPlayer == -1 or closestDistance > 3.0 then
		ESX.ShowNotification("Der er ingen spillere i nærheden")
	else
		ESX.RegisterServerCallback('esx_zipties:getItemAmount', function(zipties)
			if zipties > 0 then
				if IsEntityPlayingAnim(GetPlayerPed(closestPlayer), "missminuteman_1ig_2", "handsup_enter", 3) then
					local playerPed = GetPlayerPed(-1)
						Citizen.CreateThread(function()
						TriggerServerEvent('esx_zipties:setziptie', GetPlayerServerId(closestPlayer))
						TriggerServerEvent('esx_zipties:removeItem', 'ziptie')

					end)
				else
					ESX.ShowNotification("Spilleren overgiver sig ikke")
				end
			else
				ESX.ShowNotification('Criminal', '', 'not enough ~r~zipties', 'CHAR_ARTHUR', 7)
			end
		end, 'zipties')
	end
end

-- Weapon Menu --
RegisterServerEvent('KorioZ-PersonalMenu:Weapon_addAmmoToPedS')
AddEventHandler('KorioZ-PersonalMenu:Weapon_addAmmoToPedS', function(plyId, value, quantity)
	if #(GetEntityCoords(source, false) - GetEntityCoords(plyId, false)) <= 3.0 then
		TriggerClientEvent('KorioZ-PersonalMenu:Weapon_addAmmoToPedC', plyId, value, quantity)
	end
end)

-- Admin Menu --
RegisterServerEvent('KorioZ-PersonalMenu:Admin_BringS')
AddEventHandler('KorioZ-PersonalMenu:Admin_BringS', function(plyId, targetId)
	local xPlayer = ESX.GetPlayerFromId(source)
	local plyGroup = xPlayer.getGroup()

	if isAuthorized(getAdminCommand('bring'), plyGroup) or isAuthorized(getAdminCommand('goto'), plyGroup) then
		local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
		TriggerClientEvent('KorioZ-PersonalMenu:Admin_BringC', plyId, targetCoords)
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Admin_giveCash')
AddEventHandler('KorioZ-PersonalMenu:Admin_giveCash', function(money)
	local xPlayer = ESX.GetPlayerFromId(source)
	local plyGroup = xPlayer.getGroup()

	if isAuthorized(getAdminCommand('givemoney'), plyGroup) then
		xPlayer.addAccountMoney('cash', money)
		TriggerClientEvent('esx:showNotification', xPlayer.source, 'Modtag ' .. money .. '$')
	end
end)

RegisterServerEvent('giveitem')
AddEventHandler('giveitem', function(item, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	local plyGroup = xPlayer.getGroup()

	if isAuthorized(getAdminCommand('giveitem'), plyGroup) then
		xPlayer.addInventoryItem(item, amount)
		TriggerClientEvent('esx:showNotification', xPlayer.source, 'Modtag ' .. item .. ' ' .. amount)
	end
end)

RegisterServerEvent('setjob')
AddEventHandler('setjob', function(target, job, grade)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)
	local plyGroup = sourceXPlayer.getGroup()

	if isAuthorized(getAdminCommand('setjob'), plyGroup) then
		if ESX.DoesJobExist(job, grade) then
			targetXPlayer.setJob(job, grade)
			TriggerClientEvent('esx:showNotification', targetXPlayer.source, 'Du modtag ranket ' .. job .. ' ' .. grade)
		end
	end
end)

RegisterServerEvent('setgroup')
AddEventHandler('setgroup', function(target, group)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)
	local plyGroup = sourceXPlayer.getGroup()

	if isAuthorized(getAdminCommand('setgroup'), plyGroup) then
		targetXPlayer.setGroup(group)
		TriggerClientEvent('esx:showNotification', targetXPlayer.source, 'Du modtag staff ranket ' .. group .. '')
	end
end)

RegisterNetEvent('revive')
AddEventHandler('revive', function(plyId)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local XPlayer = ESX.GetPlayerFromId(plyId)
	local plyGroup = sourceXPlayer.getGroup()

	if isAuthorized(getAdminCommand('revive'), plyGroup) then
		TriggerClientEvent('esx_ambulancejob:revive', XPlayer)
		TriggerClientEvent('mythic_hospital:client:ResetLimbs', XPlayer)
		TriggerClientEvent('mythic_hospital:client:RemoveBleed', XPlayer)
		TriggerClientEvent('esx:showNotification', XPlayer.source, 'Du blev genoplivet ')
	else
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Der er ingen spillere der passer til dette id' .. XPlayer)
	end
end)

RegisterNetEvent('noclip')
AddEventHandler('noclip', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	local plyGroup = xPlayer.getGroup()
	
	if isAuthorized(getAdminCommand('noclip'), plyGroup) then
		TriggerClientEvent("esx_admin:noclip", xPlayer.source)
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Admin_giveBank')
AddEventHandler('KorioZ-PersonalMenu:Admin_giveBank', function(money)
	local xPlayer = ESX.GetPlayerFromId(source)
	local plyGroup = xPlayer.getGroup()

	if isAuthorized(getAdminCommand('givebank'), plyGroup) then
		xPlayer.addAccountMoney('bank', money)
		TriggerClientEvent('esx:showNotification', xPlayer.source, 'Modtog ' .. money .. '$ bank')
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Admin_giveDirtyMoney')
AddEventHandler('KorioZ-PersonalMenu:Admin_giveDirtyMoney', function(money)
	local xPlayer = ESX.GetPlayerFromId(source)
	local plyGroup = xPlayer.getGroup()

	if isAuthorized(getAdminCommand('givedirtymoney'), plyGroup) then
		xPlayer.addAccountMoney('black_money', money)
		TriggerClientEvent('esx:showNotification', xPlayer.source, 'Modtog ' .. money .. '$ sorte')
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Admin_giveitem')
AddEventHandler('KorioZ-PersonalMenu:Admin_giveitem', function(item, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	local plyGroup = xPlayer.getGroup()

	if isAuthorized(getAdminCommand('giveitem'), plyGroup) then
		xPlayer.addInventoryItem(item, amount)
		TriggerClientEvent('esx:showNotification', xPlayer.source, 'Modtog ' .. amount .. ' ' .. item .. '')
	end
end)

-- Grade Menu --
RegisterServerEvent('KorioZ-PersonalMenu:Boss_promouvoirplayer')
AddEventHandler('KorioZ-PersonalMenu:Boss_promouvoirplayer', function(target)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if (targetXPlayer.job.grade == tonumber(getMaximumGrade(sourceXPlayer.job.name)) - 1) then
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Du skal anmode om tilladelse fra ~r~Regeringen~w~.')
	else
		if sourceXPlayer.job.grade_name == 'boss' and sourceXPlayer.job.name == targetXPlayer.job.name then
			targetXPlayer.setJob(targetXPlayer.job.name, tonumber(targetXPlayer.job.grade) + 1)

			TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Du har ~g~forfremmet ' .. targetXPlayer.name .. '~w~.')
			TriggerClientEvent('esx:showNotification', target, 'Du har været ~g~forfremmet af ' .. sourceXPlayer.name .. '~w~.')
		else
			TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Du har ikke ~r~tilladelse~w~.')
		end
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Boss_destituerplayer')
AddEventHandler('KorioZ-PersonalMenu:Boss_destituerplayer', function(target)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if (targetXPlayer.job.grade == 0) then
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous ne pouvez pas ~r~rétrograder~w~ davantage.')
	else
		if sourceXPlayer.job.grade_name == 'boss' and sourceXPlayer.job.name == targetXPlayer.job.name then
			targetXPlayer.setJob(targetXPlayer.job.name, tonumber(targetXPlayer.job.grade) - 1)

			TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Du har ~r~nedrangeret ' .. targetXPlayer.name .. '~w~.')
			TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~r~rétrogradé par ' .. sourceXPlayer.name .. '~w~.')
		else
			TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~r~l\'autorisation~w~.')
		end
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Boss_recruterplayer')
AddEventHandler('KorioZ-PersonalMenu:Boss_recruterplayer', function(target, job, grade)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if sourceXPlayer.job.grade_name == 'boss' then
		targetXPlayer.setJob(job, grade)
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Du har ~g~ansat ' .. targetXPlayer.name .. '~w~.')
		TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~g~embauché par ' .. sourceXPlayer.name .. '~w~.')
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Boss_virerplayer')
AddEventHandler('KorioZ-PersonalMenu:Boss_virerplayer', function(target)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if sourceXPlayer.job.grade_name == 'boss' and sourceXPlayer.job.name == targetXPlayer.job.name then
		targetXPlayer.setJob('unemployed', 0)
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Du har ~r~fyret ' .. targetXPlayer.name .. '~w~.')
		TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~g~viré par ' .. sourceXPlayer.name .. '~w~.')
	else
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~r~l\'autorisation~w~.')
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Boss_promouvoirplayer2')
AddEventHandler('KorioZ-PersonalMenu:Boss_promouvoirplayer2', function(target)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if (targetXPlayer.job2.grade == tonumber(getMaximumGrade(sourceXPlayer.job2.name)) - 1) then
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous devez demander une autorisation du ~r~Gouvernement~w~.')
	else
		if sourceXPlayer.job2.grade_name == 'boss' and sourceXPlayer.job2.name == targetXPlayer.job2.name then
			targetXPlayer.setJob2(targetXPlayer.job2.name, tonumber(targetXPlayer.job2.grade) + 1)

			TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~g~promu ' .. targetXPlayer.name .. '~w~.')
			TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~g~promu par ' .. sourceXPlayer.name .. '~w~.')
		else
			TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~r~l\'autorisation~w~.')
		end
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Boss_destituerplayer2')
AddEventHandler('KorioZ-PersonalMenu:Boss_destituerplayer2', function(target)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if (targetXPlayer.job2.grade == 0) then
		TriggerClientEvent('esx:showNotification', _source, 'Vous ne pouvez pas ~r~rétrograder~w~ davantage.')
	else
		if sourceXPlayer.job2.grade_name == 'boss' and sourceXPlayer.job2.name == targetXPlayer.job2.name then
			targetXPlayer.setJob2(targetXPlayer.job2.name, tonumber(targetXPlayer.job2.grade) - 1)

			TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~r~rétrogradé ' .. targetXPlayer.name .. '~w~.')
			TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~r~rétrogradé par ' .. sourceXPlayer.name .. '~w~.')
		else
			TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~r~l\'autorisation~w~.')
		end
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Boss_recruterplayer2')
AddEventHandler('KorioZ-PersonalMenu:Boss_recruterplayer2', function(target, job2, grade2)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if sourceXPlayer.job2.grade_name == 'boss' then
		targetXPlayer.setJob2(job2, grade2)
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~g~recruté ' .. targetXPlayer.name .. '~w~.')
		TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~g~embauché par ' .. sourceXPlayer.name .. '~w~.')
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Boss_virerplayer2')
AddEventHandler('KorioZ-PersonalMenu:Boss_virerplayer2', function(target)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if sourceXPlayer.job2.grade_name == 'boss' and sourceXPlayer.job2.name == targetXPlayer.job2.name then
		targetXPlayer.setJob2('unemployed2', 0)
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~r~viré ' .. targetXPlayer.name .. '~w~.')
		TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~g~viré par ' .. sourceXPlayer.name .. '~w~.')
	else
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~r~l\'autorisation~w~.')
	end
end)
RegisterNetEvent('esx_okradanie:handcuff')
AddEventHandler('esx_okradanie:handcuff', function(target)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeInventoryItem('strips', 1)
	TriggerClientEvent('esx_okradanie:handcuff', target)
end)

RegisterServerEvent('drp_thiefmenu:drag')
AddEventHandler('drp_thiefmenu:drag', function(target)
	TriggerClientEvent('drp_thiefmenu:drag', target, source)
end)

RegisterServerEvent('drp_thiefmenu:handcuff')
AddEventHandler('drp_thiefmenu:handcuff', function(target)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeInventoryItem('strips', 1)
	TriggerClientEvent('drp_thiefmenu:handcuff', target)
end)
RegisterServerEvent('drp_thiefmenu:handcuff2')
AddEventHandler('drp_thiefmenu:handcuff2', function(target)
	local xPlayer = ESX.GetPlayerFromId(source)
	TriggerClientEvent('drp_thiefmenu:handcuff', target)
end)

RegisterNetEvent('esx_okradanie:drag')
AddEventHandler('esx_okradanie:drag', function(target)
	local xPlayer = ESX.GetPlayerFromId(source)
	TriggerClientEvent('esx_okradanie:drag', target, source)
end)

RegisterServerEvent('esx_okradanie:putInVehicle')
AddEventHandler('esx_okradanie:putInVehicle', function(target)
	local xPlayer = ESX.GetPlayerFromId(source)
	TriggerClientEvent('esx_okradanie:putInVehicle', target)
end)

RegisterServerEvent('esx_okradanie:OutVehicle')
AddEventHandler('esx_okradanie:OutVehicle', function(target)
	local xPlayer = ESX.GetPlayerFromId(source)
		TriggerClientEvent('esx_okradanie:OutVehicle', target)
end)

RegisterServerEvent('esx_okradanie:message')
AddEventHandler('esx_okradanie:message', function(target, msg)
	TriggerClientEvent('esx:showNotification', target, msg)
end)

ESX.RegisterServerCallback('esx_okradanie:sitem', function(source, cb, item)
    local xPlayer = ESX.GetPlayerFromId(source)
    local quantity = xPlayer.getInventoryItem(item).count
    cb(quantity)
end)

RegisterServerEvent('drp_thiefmenu:confiscatePlayerItem')
AddEventHandler('drp_thiefmenu:confiscatePlayerItem', function(target, itemType, itemName, amount)
	local _source = source
	local sourceXPlayer = ESX.GetPlayerFromId(_source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if itemType == 'item_standard' then
		local targetItem = targetXPlayer.getInventoryItem(itemName)
		local sourceItem = sourceXPlayer.getInventoryItem(itemName)

		-- does the target player have enough in their inventory?
		if targetItem.count > 0 and targetItem.count <= amount then
		
			-- can the player carry the said amount of x item?
			if sourceItem.limit ~= -1 and (sourceItem.count + amount) > sourceItem.limit then
				TriggerClientEvent('esx:showNotification', _source, _U('quantity_invalid'))
			else
				targetXPlayer.removeInventoryItem(itemName, amount)
				sourceXPlayer.addInventoryItem(itemName, amount)
				TriggerClientEvent('esx:showNotification', _source, _U('you_confiscated', amount, sourceItem.label, targetXPlayer.name))
				TriggerClientEvent('esx:showNotification', target,  _U('got_confiscated', amount, sourceItem.label, sourceXPlayer.name))
			end
		else
			TriggerClientEvent('esx:showNotification', _source, _U('quantity_invalid'))
		end

	elseif itemType == 'item_account' then
		targetXPlayer.removeAccountMoney(itemName, amount)
		sourceXPlayer.addAccountMoney(itemName, amount)

		TriggerClientEvent('esx:showNotification', _source, _U('you_confiscated_account', amount, itemName, targetXPlayer.name))
		TriggerClientEvent('esx:showNotification', target,  _U('got_confiscated_account', amount, itemName, sourceXPlayer.name))

	elseif itemType == 'item_weapon' then
		if amount == nil then amount = 0 end
		targetXPlayer.removeWeapon(itemName, amount)
		sourceXPlayer.addWeapon(itemName, amount)

		TriggerClientEvent('esx:showNotification', _source, _U('you_confiscated_weapon', ESX.GetWeaponLabel(itemName), targetXPlayer.name, amount))
		TriggerClientEvent('esx:showNotification', target,  _U('got_confiscated_weapon', ESX.GetWeaponLabel(itemName), amount, sourceXPlayer.name))
	end
end)

ESX.RegisterServerCallback('drp_thiefmenu:getOtherPlayerData', function(source, cb, target)

	if Config.EnableESXIdentity then

		local xPlayer = ESX.GetPlayerFromId(target)

		local identifier = GetPlayerIdentifiers(target)[1]

		local result = MySQL.Sync.fetchAll("SELECT * FROM users WHERE identifier = @identifier", {
			['@identifier'] = identifier
		})

		local firstname = result[1].firstname
		local lastname  = result[1].lastname
		local sex       = result[1].sex
		local dob       = result[1].dateofbirth
		local height    = result[1].height

		local data = {
			name      = GetPlayerName(target),
			job       = xPlayer.job,
			inventory = xPlayer.inventory,
			accounts  = xPlayer.accounts,
			weapons   = xPlayer.loadout,
			firstname = firstname,
			lastname  = lastname,
			sex       = sex,
			dob       = dob,
			height    = height
		}

		TriggerEvent('esx_status:getStatus', target, 'drunk', function(status)
			if status ~= nil then
				data.drunk = math.floor(status.percent)
			end
		end)

		if Config.EnableLicenses then
			TriggerEvent('esx_license:getLicenses', target, function(licenses)
				data.licenses = licenses
				cb(data)
			end)
		else
			cb(data)
		end

	else

		local xPlayer = ESX.GetPlayerFromId(target)

		local data = {
			name       = GetPlayerName(target),
			job        = xPlayer.job,
			inventory  = xPlayer.inventory,
			accounts   = xPlayer.accounts,
			weapons    = xPlayer.loadout
		}

		TriggerEvent('esx_status:getStatus', target, 'drunk', function(status)
			if status ~= nil then
				data.drunk = math.floor(status.percent)
			end
		end)

		TriggerEvent('esx_license:getLicenses', target, function(licenses)
			data.licenses = licenses
		end)

		cb(data)

	end

end)

RegisterServerEvent('drp_thiefmenu:OutVehicle')
AddEventHandler('drp_thiefmenu:OutVehicle', function(target)
	local xPlayer = ESX.GetPlayerFromId(source)
		TriggerClientEvent('drp_thiefmenu:OutVehicle', target)
end)

RegisterServerEvent('drp_thiefmenu:putInVehicle')
AddEventHandler('drp_thiefmenu:putInVehicle', function(target)
	TriggerClientEvent('drp_thiefmenu:putInVehicle', target)
end)


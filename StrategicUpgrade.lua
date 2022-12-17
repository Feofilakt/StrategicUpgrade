local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function PlayerHasModifier(playerID, name :string)
	for _,instID in ipairs(GameEffects.GetModifiers()) do
		local instdef :table = GameEffects.GetModifierDefinition(instID);
		for key,value in pairs(instdef) do
			if (key == "Id" and value == name) then
				local tSubjects :table = GameEffects.GetModifierSubjects(instID);
				for _,subjectId in pairs(tSubjects) do
					print(GameEffects.GetObjectType(subjectId));
					if GameEffects.GetObjectType(subjectId) == "LOC_MODIFIER_OBJECT_PLAYER" then
						local sSubjectString = GameEffects.GetObjectString(subjectId);
						local subjectPlayerId = tonumber( string.match(sSubjectString, "Player: (%d+)") );			
						if (subjectPlayerId == playerID) then
							return true;
						end
					end
				end
			end
		end
	end
	return false;
end


local resources = {
	'RESOURCE_HORSES',
	'RESOURCE_IRON',
	'RESOURCE_NITER'
}
local resourceDebts = {};

local playerIds :table = PlayerManager.GetAliveMajorIDs();
for _, id in ipairs( playerIds ) do
	resourceDebts[id] = {}
	for _, resource in ipairs(resources) do
		resourceDebts[id][resource] = 0;
	end
end

function OnPlayerResourceChanged(ownerPlayerID, resourceTypeID)
	local resource = GameInfo.Resources[resourceTypeID].ResourceType
	if not has_value(resources, resource) then
		return;
	end

	local player :object = PlayerManager.GetPlayer(ownerPlayerID);
	local playerResources = player:GetResources();
	local amount = playerResources:GetResourceAmount(resource);
	local debt = resourceDebts[ownerPlayerID][resource];
	if amount == 0 or debt == 0 then
		return;
	end
	
	local pay = math.min(debt, amount);
	playerResources:ChangeResourceAmount(resourceTypeID, -pay);
	resourceDebts[ownerPlayerID][resource] = debt - pay;
end
Events.PlayerResourceChanged.Add(OnPlayerResourceChanged)


local unitResources = {};

unitResources['UNIT_COURSER'] = 'RESOURCE_HORSES';
unitResources['UNIT_HUNGARY_BLACK_ARMY'] = 'RESOURCE_HORSES';
unitResources['UNIT_ETHIOPIAN_OROMO_CAVALRY'] = 'RESOURCE_HORSES';

unitResources['UNIT_CAVALRY'] = 'RESOURCE_HORSES';
unitResources['UNIT_RUSSIAN_COSSACK'] = 'RESOURCE_HORSES';
unitResources['UNIT_HUNGARY_HUSZAR'] = 'RESOURCE_HORSES';
unitResources['UNIT_COLOMBIAN_LLANERO'] = 'RESOURCE_HORSES';

unitResources['UNIT_CUIRASSIER'] = 'RESOURCE_IRON';
unitResources['UNIT_POLISH_HUSSAR'] = 'RESOURCE_IRON';
unitResources['UNIT_AMERICAN_ROUGH_RIDER'] = 'RESOURCE_IRON';

unitResources['UNIT_MAN_AT_ARMS'] = 'RESOURCE_IRON';
unitResources['UNIT_NORWEGIAN_BERSERKER'] = 'RESOURCE_IRON';
unitResources['UNIT_GEORGIAN_KHEVSURETI'] = 'RESOURCE_IRON';
unitResources['UNIT_JAPANESE_SAMURAI'] = 'RESOURCE_IRON';

unitResources['UNIT_LINE_INFANTRY'] = 'RESOURCE_NITER';
unitResources['UNIT_FRENCH_GARDE_IMPERIALE'] = 'RESOURCE_NITER';
unitResources['UNIT_ENGLISH_REDCOAT'] = 'RESOURCE_NITER';


function OnUnitUpgraded(playerID, unitID)
	local unit :object = UnitManager.GetUnit(playerID, unitID);	
	local unitType = GameInfo.Units[unit:GetType()].UnitType;
	print(unitType);
	
	local resource = unitResources[unitType];
	if resource == nil then
		return;
	end
	
	local cost = GameInfo.Units_XP2[unitType].ResourceCost;
	if cost == 0 then
		return;
	end
	if PlayerHasModifier(playerID, "PROFESSIONAL_ARMY_UPGRADE_RESOURCE_DISCOUNT") then
		cost = cost * 0.7;
	end
	
	local player :object = PlayerManager.GetPlayer(playerID);
	local playerResources = player:GetResources();
	local amount = playerResources:GetResourceAmount(resourceType);
	local pay = math.min(cost, amount);
	local debt = cost - pay;
	
	playerResources:ChangeResourceAmount(GameInfo.Resources[resource].Index, -pay);
	if debt > 0 then
		resourceDebts[playerID][resource] = resourceDebts[playerID][resource] + debt;
	end
end
Events.UnitUpgraded.Add(OnUnitUpgraded)

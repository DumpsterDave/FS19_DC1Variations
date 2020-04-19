--[[
addConfig

Specialization for extended configurations and register new configurations.

Author:		Ifko[nator]
Datum:		24.08.2019

Version:	v5.3

History:	v1.0 @ 28.02.2017 - initial implementation in FS 17 - added possibility to change capacity via configuration --## FS17 (removed)
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v2.0 @ 25.03.2017 - added possibility to change rim and axis color via configuration --## FS17 and FS 19
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v3.0 @ 21.07.2017 - added possibility to change fillable fill types and cutable fruit types via configuration --## FS17 (removed)
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v3.1 @ 13.12.2017 - a little bit code optimation --## FS17
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v3.2 @ 31.12.2017 - increased the limit from 64 to 134.217.728 configurations, i hope thats enough now! --## FS17
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v3.3 @ 04.03.2018 - the capacity value from the fillUnit in the xml file will now set to the new capacity to avoid fill the fill volume too fast or too slow --## FS17 (removed)
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v3.4 @ 04.07.2018 - added possibility to change the mass and possiblity to deactivate the fillable Spezi of an vehicle via configuration --## FS17 (removed)
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v3.9 BETA @ 07.01.2019 - first conversion to FS 19, current only color configs working! --## FS19
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v4.0 @10.01.2019 - added support for 'design' configurations and finish the conversion but this is currentlly still an TEST Version! --## FS19
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v4.2 @23.01.2019 - added support for default configurations and possibility to change the honk sound via configuration --## FS19
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v4.5 @27.01.2019 - added possibility to change the external sound file for motor sounds (wish from Unguided) --## FS19
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v4.6 @08.02.2019 - added possibility to change the beacon lights (wish from juli7250) --## FS19
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v4.7 @10.02.2019 - added possibility to make any vehicle selectable (wish from Ahran Modding) --## FS19
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v4.8 @12.02.2019 - fixed register of an exists configuration, script will stop now --## FS19
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v4.9 @05.03.2019 - fixed issue that additonial wheels won't be colered with color changes and add the TAG 'getColorFromConfig' to get the color from given config --## FS19
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v5.0 @17.06.2019 - fixed issue that th connectors from the additonial wheels won't be colered with color changes --## FS19
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v5.1 @08.08.2019 - added compatibility with the FSIconGenerator from GIANTS, so it will not crash anymore. You can't select the new configurations in the generator --## FS19
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v5.2 @23.08.2019 - added possibility to change the material in a new color configuration (thanks for the hint Unguided :kannniLOVE: ) --##FS19
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			v5.3 @24.08.2019 - increased again the limit from 64 to 134.217.728 configurations -- FS19
]]

addConfig = {};

addConfig.currentModDirectory = g_currentModDirectory;
addConfig.debugPriority = 0;
addConfig.newConfgurations = {};

addConfig.defaultChangeObjectsConfigurations = {
	"design",
	"vehicleType",
	"attacherJoint",
	"motor",
	"frontloader",
	"powerTakeOff",
	"trailer",
	"tensionBelts",
	"wheel",
	"pipe",
	"inputAttacherJoint",
	"cover",
	"folding",
	"fillUnit",
	"buyableBaleAmount",
	"fillVolume",
	"consumer",
	"differential",
	"ackermannSteering"
};

addConfig.defaultColorConfigurations = {
	"baseColor",
	"designColor",
	"rimColor",
	"baseMaterial",
	"designMaterial",
	"wrappingColor"
};

local function printError(errorMessage, isWarning, isInfo)
	local prefix = "::ERROR:: ";

	if isWarning then
		prefix = "::WARNING:: ";
	elseif isInfo then
		prefix = "::INFO:: ";
	end;

	print(prefix .. "from the addConfig.lua: " .. tostring(errorMessage));
end;

local function printDebug(debugMessage, priority, addString)
	if addConfig.debugPriority >= priority then
		local prefix = "";

		if addString then
			prefix = "::DEBUG:: from the addConfig.lua: ";
		end;

		setFileLogPrefixTimestamp(false);
		print(prefix .. tostring(debugMessage));
		setFileLogPrefixTimestamp(true);
	end;
end;

if ConfigurationUtil.SEND_NUM_BITS < 27 then
	ConfigurationUtil.SEND_NUM_BITS = 27; --## = 134.217.728 possible configurations! I think, thats enough (2^27 = 134.217.728)!
	
	printError("Set max number of configurations to ".. g_i18n:formatNumber(2^ConfigurationUtil.SEND_NUM_BITS), false, true);
end;

function addConfig.prerequisitesPresent(specializations)
    return true;
end

function addConfig.registerEventListeners(vehicleType)
	local functionNames = {
		"onLoad",
		"onPreLoad",
		"onUpdate"
	};

	for _, functionName in ipairs(functionNames) do
		SpecializationUtil.registerEventListener(vehicleType, functionName, addConfig);
	end;
end;

function addConfig.registerFunctions(vehicleType)
	local functionNames = {
		"setColor",
		"changeObjects",
		"initExtraOptions",
		"getConfigKey",
		"getXMLPrefix",
		"loadExtraOptions"
	};

	for _, functionName in ipairs(functionNames) do
		SpecializationUtil.registerFunction(vehicleType, functionName, addConfig[functionName]);
	end;
end;


function addConfig.registerOverwrittenFunctions(vehicleType)
	local overwrittenFunctionNames = {
		"getCanBeSelected"
	};

	for _, overwrittenFunctionName in ipairs(overwrittenFunctionNames) do
		SpecializationUtil.registerOverwrittenFunction(vehicleType, overwrittenFunctionName, addConfig[overwrittenFunctionName]);
	end;
end;

function addConfig.initSpecialization()
    local modDesc = loadXMLFile("modDesc", addConfig.currentModDirectory .. "modDesc.xml");
	local configNumber = 0;

	while true do
		local configKey = "modDesc.newConfigurations.newConfiguration(" .. tostring(configNumber) .. ")";

		if not hasXMLProperty(modDesc, configKey) then
			break;
		end;
		
		local newConfguration = {};

		newConfguration.isColorConfig = Utils.getNoNil(getXMLBool(modDesc, configKey .. "#isColorConfig"), false);
		newConfguration.configName = Utils.getNoNil(getXMLString(modDesc, configKey .. "#configName"), "");

		if newConfguration.configName ~= "" then 
			if g_configurationManager.configurations[newConfguration.configName] == nil then	
				if newConfguration.isColorConfig then	
					--## config to change color on vehicle

					printDebug("(newConfigurations) :: Register color configuration '" .. newConfguration.configName .. "' successfully.", 1, true);

					g_configurationManager:addConfigurationType(newConfguration.configName, g_i18n:getText("configuration_" .. newConfguration.configName), nil, ConfigurationUtil.getConfigMaterialSingleItemLoad, ConfigurationUtil.getConfigColorSingleItemLoad, ConfigurationUtil.getConfigColorPostLoad, ConfigurationUtil.SELECTOR_COLOR);
				else
					--## config to change objects on vehicle

					printDebug("(newConfigurations) :: Register multi option configuration '" .. newConfguration.configName .. "' successfully.", 1, true);

					g_configurationManager:addConfigurationType(newConfguration.configName, g_i18n:getText("configuration_" .. newConfguration.configName), nil, nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION);
				end;
			end;

			table.insert(addConfig.newConfgurations, newConfguration);
		end;

		configNumber = configNumber + 1;
	end;

	delete(modDesc);
end;

function addConfig:onLoad(savegame)
	local modDesc = loadXMLFile("modDesc", addConfig.currentModDirectory .. "modDesc.xml");
	
	addConfig.debugPriority = Utils.getNoNil(getXMLFloat(modDesc, "modDesc.newConfigurations#debugPriority"), addConfig.debugPriority);
	
	delete(modDesc);
	
	for _, newConfguration in pairs(addConfig.newConfgurations) do
		if self.configurations[newConfguration.configName] ~= nil then	
			printDebug("(newConfigurations) :: Found configuration '" .. newConfguration.configName .. "' in vehicle '" .. self.configFileName .. "'.", 1, true);

			if newConfguration.isColorConfig then
				--## config to change color on vehicle
				
				self:setColor(newConfguration.configName, self.configurations[newConfguration.configName]);
				self:applyBaseMaterialConfiguration(self.xmlFile, newConfguration.configName, self.configurations[newConfguration.configName]);
				self:applyBaseMaterial();
			else
				--## config to change objects on vehicle
				
				self:changeObjects(newConfguration.configName, self.configurations[newConfguration.configName]);
			end;
		end;
	end;
	
	for _, defaultColorConfiguration in pairs(addConfig.defaultColorConfigurations) do
		if self.configurations[defaultColorConfiguration] ~= nil then	
			--## config to change color on vehicle
			
			self:setColor(defaultColorConfiguration, self.configurations[defaultColorConfiguration]);
		end;
	end;

	for _, defaultChangeObjectsConfiguration in pairs(addConfig.defaultChangeObjectsConfigurations) do
		if self.configurations[defaultChangeObjectsConfiguration] ~= nil then
			--## config to change objects on vehicle
			
			self:changeObjects(self:getXMLPrefix(defaultChangeObjectsConfiguration), self.configurations[defaultChangeObjectsConfiguration], defaultChangeObjectsConfiguration);
		end;
	end;

	self.hasFinishedFirstRun = false;
end;

function addConfig:onPreLoad(savegame)
	for _, newConfguration in pairs(addConfig.newConfgurations) do
		if self.configurations[newConfguration.configName] ~= nil then
			if not newConfguration.isColorConfig then	
				self:initExtraOptions(newConfguration.configName, self.configurations[newConfguration.configName], nil, false);
			end;
		end;
	end;

	for _, defaultChangeObjectsConfiguration in pairs(addConfig.defaultChangeObjectsConfigurations) do
		if self.configurations[defaultChangeObjectsConfiguration] ~= nil then
			self:initExtraOptions(self:getXMLPrefix(defaultChangeObjectsConfiguration), self.configurations[defaultChangeObjectsConfiguration], defaultChangeObjectsConfiguration, false);
		end;
	end;
end;

function addConfig:getCanBeSelected(superFunc)
	--## Make any Vehicle, wich has the script, selectable

	return true;
end

function addConfig:onUpdate(dt, isActiveForInput, isSelected)
	if not self.hasFinishedFirstRun then
		for _, newConfguration in pairs(addConfig.newConfgurations) do
			if self.configurations[newConfguration.configName] ~= nil then
				if not newConfguration.isColorConfig then	
					self:initExtraOptions(newConfguration.configName, self.configurations[newConfguration.configName], nil, true);
				end;
			end;
		end;

		for _, defaultChangeObjectsConfiguration in pairs(addConfig.defaultChangeObjectsConfigurations) do
			if self.configurations[defaultChangeObjectsConfiguration] ~= nil then
				self:initExtraOptions(self:getXMLPrefix(defaultChangeObjectsConfiguration), self.configurations[defaultChangeObjectsConfiguration], defaultChangeObjectsConfiguration, true);
			end;
		end;

		self.hasFinishedFirstRun = true;
	end;
end;

function addConfig:getXMLPrefix(configName)
	local prefix = "";
	
	if configName == "motor" or configName == "consumer" or configName == "differential" then
		prefix = "motorized.";
	elseif configName == "wheel" or configName == "ackermannSteering" then
		prefix =  "wheels.";
	elseif configName == "fillUnit" then
		prefix = "fillUnit.";
	elseif configName == "fillVolume" then
		prefix = "fillVolume.";
	elseif configName == "trailer" then
		prefix = "trailer.";
	elseif configName == "tensionBelts" then
		prefix = "tensionBelts.";
	elseif configName == "cover" then
		prefix = "cover.";
	elseif configName == "attacherJoint" then
		prefix = "attacherJoints.";
	elseif configName == "inputAttacherJoint" then
		prefix = "attachable.";
	end;
	
	return prefix .. configName;
end;

function addConfig:getConfigKey(configName, configId, secondConfigName)
	if secondConfigName == nil then
		secondConfigName = configName;
	end;

	local configKey = string.format("vehicle." .. configName .. "Configurations." .. secondConfigName .. "Configuration(%d)", configId - 1);

	if not hasXMLProperty(self.xmlFile, configKey) then
--[[ 
		printError("(getConfigKey) :: Invalid " .. configName .. " configuration " .. configId .. " (key = " .. configKey .. ")", true, false);
        ]]
		return "noKeyFound";
	end;

	return configKey;
end;

function addConfig:loadExtraOptions(configKey, extraOptionNeedUpdate)
	local extraOptionNumber = 0;

	while true do
		local extraOptionKey = string.format(configKey .. ".extraOption(%d)", extraOptionNumber);

	   	if not hasXMLProperty(self.xmlFile, extraOptionKey) then
		   break;
	   	end;

		if extraOptionNeedUpdate then   
			local coverFillUnit = Utils.getNoNil(getXMLInt(self.xmlFile, extraOptionKey .. "#fillUnit"), 1);
			local setCoverOpen = getXMLBool(self.xmlFile, extraOptionKey .. "#setCoverOpen");
			   
			if self.spec_cover ~= nil and setCoverOpen ~= nil then
				self:setCoverState(coverFillUnit, setCoverOpen);
 
				printDebug("(extraOptions) :: Open cover state is '" .. tostring(setCoverOpen) .. "'." , 1, true);
			end;
		else
	  		local honkSoundTemplate = string.upper(Utils.getNoNil(getXMLString(self.xmlFile, extraOptionKey .. "#honkSoundTemplate"), ""));
			local honkSoundFilename = Utils.getNoNil(getXMLString(self.xmlFile, extraOptionKey .. "#honkSoundFilename"), "");
			local honkSoundOuterRadius = Utils.getNoNil(getXMLFloat(self.xmlFile, extraOptionKey .. "#honkSoundOuterRadius"), "");
			local honkSoundInnerRadius = Utils.getNoNil(getXMLFloat(self.xmlFile, extraOptionKey .. "#honkSoundInnerRadius"), "");
			local externalMotorSoundFile = Utils.getNoNil(getXMLString(self.xmlFile, extraOptionKey .. "#externalMotorSoundFile"), "");
			local beaconlightsFilename = Utils.getNoNil(getXMLString(self.xmlFile, extraOptionKey .. "#beaconlightsFilename"), "");
			local supportAnimationName = Utils.getNoNil(getXMLString(self.xmlFile, extraOptionKey .. "#supportAnimationName"), "");
			local changeConfigurationName = Utils.getNoNil(getXMLString(self.xmlFile, extraOptionKey .. "#changeConfigurationName"), "");
			
			if supportAnimationName ~= "" then
				setXMLString(self.xmlFile, "vehicle.attachable.supportArm#animationName", "notDefined"); --## deactivate the manual support animation of my SupportArm Script
				setXMLString(self.xmlFile, "vehicle.attachable.support#animationName", supportAnimationName);

				printDebug("(extraOptions) :: Support animation name to '" .. supportAnimationName .. "'.", 1, true);
			end;

			if beaconlightsFilename ~= "" then
				local beaconLightNumber = 0;

				while true do
					local beaconLightKey = "vehicle.lights.beaconLights.beaconLight(" .. tostring(beaconLightNumber) .. ")";

					if not hasXMLProperty(self.xmlFile, beaconLightKey) then
						break;
					end;

					setXMLString(self.xmlFile, beaconLightKey .. "#filename", beaconlightsFilename);

					printDebug("(extraOptions) :: Set beacon light(" .. tostring(beaconLightNumber) + 1 .. ") file to '" .. beaconlightsFilename .. "'.", 1, true);

					beaconLightNumber = beaconLightNumber + 1;
				end;
			end;

			if externalMotorSoundFile ~= "" then
				setXMLString(self.xmlFile, "vehicle.motorized.sounds#externalSoundFile", externalMotorSoundFile);

				printDebug("(extraOptions) :: Set external motor sound file to '" .. externalMotorSoundFile .. "'.", 1, true);
			end;

			if self.spec_honk ~= nil then
				if honkSoundOuterRadius ~= "" then
					setXMLFloat(self.xmlFile, "vehicle.honk.sound#outerRadius", honkSoundOuterRadius);
				end;

				if honkSoundInnerRadius ~= "" then
					setXMLFloat(self.xmlFile, "vehicle.honk.sound#innerRadius", honkSoundInnerRadius);
				end;

				if honkSoundTemplate ~= "" then	
					if hasXMLProperty(self.xmlFile, "vehicle.honk.sound#file") then	
						removeXMLProperty(self.xmlFile, "vehicle.honk.sound#file");
					end;

					setXMLString(self.xmlFile, "vehicle.honk.sound#template", honkSoundTemplate);

					printDebug("(extraOptions) :: Set honk sound template to '" .. honkSoundTemplate .. "'.", 1, true);
				elseif honkSoundFilename ~= "" then
					if hasXMLProperty(self.xmlFile, "vehicle.honk.sound#template") then	
						removeXMLProperty(self.xmlFile, "vehicle.honk.sound#template");
					end;

					setXMLString(self.xmlFile, "vehicle.honk.sound#file", honkSoundFilename);

					printDebug("(extraOptions) :: Set honk sound filename to '" .. addConfig.currentModDirectory .. honkSoundFilename .. "'.", 1, true);
				end;
			end;

			if changeConfigurationName ~= "" then
				if self.configurations[changeConfigurationName] ~= nil then
					local configurationIndex = Utils.getNoNil(getXMLInt(self.xmlFile, extraOptionKey .. "#configurationIndex"), 1);
					
					local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName);
					local config = storeItem.configurations[changeConfigurationName][configurationIndex];

					configName = config.name;

					if configName == "" then
						configName = "index " .. configurationIndex;
					end;

					ConfigurationUtil.setConfiguration(self, changeConfigurationName, configurationIndex);
					
					printDebug("(extraOptions) :: Set '" .. changeConfigurationName .. "' configuration to '" .. configName .. "' for vehicle '" .. self.configFileName .. "'.", 1, true);
				else
					printError("(extraOptions) :: Invalid '" .. changeConfigurationName .. "' configuration for vehicle '" .. self.configFileName .. "'! Stop change this configuration!", true, false);
				end;
			end;
		end;

	   extraOptionNumber = extraOptionNumber + 1
   end;
end;

function addConfig:initExtraOptions(configName, configId, secondConfigName, extraOptionNeedUpdate)
	local configKey = self:getConfigKey(configName, configId, secondConfigName);

	if configKey ~= "noKeyFound" then
		self:loadExtraOptions(configKey, extraOptionNeedUpdate);
	end;
end;

function addConfig:setColor(configName, configId)
	local color = ConfigurationUtil.getColorByConfigId(self, configName, configId);

	printDebug("(" .. configName .. "Configurations) :: color = '" .. tostring(color) .. "'.", 1, true);

	if color ~= nil then
		local r, g, b = unpack(color);
		printDebug("(" .. configName .. "Configurations) :: r, g, b = " .. r .. ", " .. g .. ", " .. b, 1, true);

		local configNumber = 0;

		while true do
			local colorKey = string.format("vehicle.%sConfigurations.colorNode(%d)", configName, configNumber);

			if not hasXMLProperty(self.xmlFile, colorKey) then
				break;
			end;

			local node = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, colorKey .. "#node"), self.i3dMappings);

			if node ~= nil then
				local shaderParameter = Utils.getNoNil(getXMLString(self.xmlFile, colorKey .. "#shaderParameter"), "colorMat0");
				local materialId = getXMLInt(self.xmlFile, colorKey .. "#materialId");

				if getHasClassId(node, ClassIds.SHAPE) then
					if getHasShaderParameter(node, shaderParameter) then
						if materialId == nil then
							_, _, _, materialId = getShaderParameter(node, shaderParameter);
						end
		
						printDebug("(" .. configName .. "Configurations) :: shader parameter values (r, g, b, materialId) = " .. r .. ", " .. g .. ", " .. b .. ", " .. materialId, 1, true);
						
						if Utils.getNoNil(getXMLBool(self.xmlFile, colorKey .. "#recursive"), false) then				
							I3DUtil.setShaderParameterRec(node, shaderParameter, r, g, b, materialId);
						else
							setShaderParameter(node, shaderParameter, r, g, b, materialId, true);
						end;
					else
						printError("(" .. configName .. "Configurations) :: Could not set vehicle color to '" .. getName(node) .. "' because the node has not the shader parameter '" .. shaderParameter .. "'! Stop try to coloring!", true, false);
					end;
				else
					printError("(" .. configName .. "Configurations) :: Could not set vehicle color to '" .. getName(node) .. "' because the node is not a shape! Stop try to coloring!", true, false);
				end;
			else
				printError("(" .. configName .. "Configurations) :: Could not find node! Stop try to coloring!", true, false);
			end;

			configNumber = configNumber + 1;
		end;

		configNumber = 0;

		while true do
			local materialKey = string.format("vehicle.%sConfigurations.material(%d)", configName, configNumber);

			if not hasXMLProperty(self.xmlFile, materialKey) then
				break;
			end;

			local materialName = getXMLString(self.xmlFile, materialKey .. "#name");

			if materialName ~= nil then
				local shaderParameterName = getXMLString(self.xmlFile, materialKey .. "#shaderParameter");

				if shaderParameterName ~= nil then
					local colorStr = getXMLString(self.xmlFile, materialKey .. "#color");
					local color;

					if colorStr ~= nil then
						color = g_brandColorManager:getBrandColorByName(colorStr);
					end;

					if color == nil then
						color = ConfigurationUtil.getColorByConfigId(self, configName, configId);
					end;

					if color ~= nil then
						local materialId = getXMLInt(self.xmlFile, materialKey .. "#materialId");

						if self.setBaseMaterialColor ~= nil then
							self:setBaseMaterialColor(materialName, shaderParameterName, color, materialId);
						else
							printError("(" .. configName .. "Configurations) :: Missing function 'setBaseMaterialColor'!", true, false);
						end;
					else
						printError("(" .. configName .. "Configurations) :: Failed to load color '" .. tostring(colorStr) .. "' in '" .. self.configFileName .. "'! Stop coloring '" .. materialName .. "'!", false, false);
					end;
				else
					printError("(" .. configName .. "Configurations) :: Missing shader parameter in '" .. self.configFileName .. "'! Stop coloring '" .. materialName .. "'!", true, false);
				end;
			end;

			configNumber = configNumber + 1;
		end;
	end;
end;

function addConfig:changeObjects(configName, configId, secondConfigName)
	secondConfigName = Utils.getNoNil(secondConfigName, configName);

	local configKey = self:getConfigKey(configName, configId, secondConfigName);

	if configKey ~= "noKeyFound" then
    	local configNumber = 0;

   		while true do
     		local materialKey = string.format(configKey .. ".material(%d)", configNumber);

			if not hasXMLProperty(self.xmlFile, materialKey) then
            	break;
        	end;

			local baseMaterialNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, materialKey .. "#node"), self.i3dMappings);
        	local refMaterialNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, materialKey .. "#refNode"), self.i3dMappings);

			if baseMaterialNode ~= nil and refMaterialNode ~= nil then
            	local oldMaterial = getMaterial(baseMaterialNode, 0);
            	local newMaterial = getMaterial(refMaterialNode, 0);

				for _, component in pairs(self.components) do
               		ConfigurationUtil.replaceMaterialRec(self, component.node, oldMaterial, newMaterial);
            	end;
        	end;

			configNumber = configNumber + 1;
   	 	end;

		
		--## change body color

		local colorNumber = 0;

		while true do
			local colorKey = configKey .. ".colorChanges.colorChange(" .. tostring(colorNumber) .. ")";

			if not hasXMLProperty(self.xmlFile, colorKey) then
				break;
			end;

			local color = getXMLString(self.xmlFile, colorKey .. "#color");
			local getColorFromConfig = getXMLString(self.xmlFile, colorKey .. "#getColorFromConfig");
			local shaderParameterName = Utils.getNoNil(getXMLString(self.xmlFile, colorKey .. "#shaderParameterName"), "colorMat0");
			local materialName = getXMLString(self.xmlFile, colorKey .. "#materialName");
			local materialId = getXMLInt(self.xmlFile, colorKey .. "#materialId");
			local colorName;
			local isColorConfig = false;
			
			if materialName ~= nil then
				if materialId == nil then
					local specBaseMaterial = self.spec_baseMaterial;
					local material = specBaseMaterial.nameToMaterial[materialName];

					if material ~= nil then	
						local shaderParameter = material.nameToShaderParameter[shaderParameterName];
					
						materialId = shaderParameter.value[4];
					else
						materialId = 0;
					end;
				end;

				if getColorFromConfig ~= nil then
					if self.configurations[getColorFromConfig] ~= nil then	
						for _, newConfguration in pairs(addConfig.newConfgurations) do
							if getColorFromConfig == newConfguration.configName then
								isColorConfig = newConfguration.isColorConfig;

								break;
							end;
						end;

						for _, defaultChangeObjectsConfiguration in pairs(addConfig.defaultChangeObjectsConfigurations) do
							if getColorFromConfig == defaultChangeObjectsConfiguration then
								isColorConfig = true;

								break;
							end;
						end;	


						if isColorConfig then
							colorName = ConfigurationUtil.getColorByConfigId(self, getColorFromConfig, self.configurations[getColorFromConfig]);
						else
							printError("(colorChanges) :: The configuration '" .. getColorFromConfig .. "' is not an color configuration! Stop coloring part '" .. materialName .. "'!", false, true);
						end;
					else
						printError("(colorChanges) :: Can't find configuration '" .. getColorFromConfig .. "' in vehicle '" .. self.configFileName .. "'! Stop coloring part '" .. materialName .. "'!", false, true);
					end;
				else
					colorName = g_brandColorManager:getBrandColorByName(color);
				end;

				if colorName == nil then
					colorName = ConfigurationUtil.getColorFromString(color);
				end;

				if colorName ~= nil then
					self:setBaseMaterialColor(materialName, shaderParameterName, colorName, materialId);
				
					printDebug("(colorChanges) :: Change color successfully in '" .. self.configFileName .. "' for '" .. materialName .. "'.", 1, true);
				else
					printError("(colorChanges) :: Failed to load color '" .. tostring(color) .. "' in '" .. self.configFileName .. "'! Stop coloring '" .. materialName .. "'!", false, false);
				end;
			else
				printError("(colorChanges) :: Missing materialName in '" .. self.configFileName .. "'! Stop coloring this vehicle body!", false, false);
			end;

			colorNumber = colorNumber + 1;
		end;

		--## change rim and axis color
		if self.spec_wheels ~= nil then
			local hubColor = getXMLString(self.xmlFile, configKey .. ".colorChanges.hub#color");
			local rimColor = getXMLString(self.xmlFile, configKey .. ".colorChanges.rim#color");
			local additionalColor = getXMLString(self.xmlFile, configKey .. ".colorChanges.additional#color");

			if hubColor ~= nil then
				local materialId = getXMLInt(self.xmlFile, configKey .. ".colorChanges.hub#materialId");
				local shaderParameterName = Utils.getNoNil(getXMLString(self.xmlFile, configKey .. ".colorChanges.rim#shaderParameterName"), "colorMat0");

				for _, hub in pairs(self.spec_wheels.hubs) do
					local hubColorName = g_brandColorManager:getBrandColorByName(hubColor);

					if hubColorName == nil then
						hubColorName = ConfigurationUtil.getColorFromString(hubColor);
					end;

					if hubColorName ~= nil then
						if hub.node ~= nil then
							local r, g, b, _ = unpack(hubColorName);

							if materialId == nil then
            					_, _, _, materialId = getShaderParameter(hub.node, shaderParameterName);
							end;

							setShaderParameter(hub.node, shaderParameterName, r, g, b, materialId, false);

							printDebug("(colorChanges) :: Change hub color successfully in '" .. self.configFileName .. "'.", 1, true);
						end;
					else
						printError("(colorChanges) :: Failed to load color '" .. tostring(hubColor) .. "' in '" .. self.configFileName .. "'! Stop coloring hubs!", false, false);
					end;
				end;
			end;

			if additionalColor ~= nil then
				local materialId = getXMLInt(self.xmlFile, configKey .. ".colorChanges.additional#materialId");
				local shaderParameterName = Utils.getNoNil(getXMLString(self.xmlFile, configKey .. ".colorChanges.additional#shaderParameterName"), "colorMat0");
				local additionalColorName = g_brandColorManager:getBrandColorByName(additionalColor);

				if additionalColorName == nil then
					additionalColorName = ConfigurationUtil.getColorFromString(additionalColor);
				end;
				
				if additionalColorName ~= nil then
					local r, g, b, _ = unpack(additionalColorName);

					for _, wheel in pairs(self.spec_wheels.wheels) do
						if wheel.wheelAdditional ~= nil then
							if materialId == nil then
								_, _, _, materialId = getShaderParameter(wheel.wheelAdditional, shaderParameterName);
							end;

							setShaderParameter(wheel.wheelAdditional, shaderParameterName, r, g, b, materialId, false);

							printDebug("(colorChanges) :: Change additional wheel color successfully in '" .. self.configFileName .. "'.", 1, true)
						end;
					end;
				else
					printError("(colorChanges) :: Failed to load color '" .. tostring(additionalColor) .. "' in '" .. self.configFileName .. "'! Stop coloring additional wheels!", false, false);
				end;
			end;

			if rimColor ~= nil then			
				local materialId = getXMLInt(self.xmlFile, configKey .. ".colorChanges.rim#materialId");
				local shaderParameterName = Utils.getNoNil(getXMLString(self.xmlFile, configKey .. ".colorChanges.hub#shaderParameterName"), "colorMat0");

				local rimColorName = g_brandColorManager:getBrandColorByName(rimColor);

				if rimColorName == nil then
					rimColorName = ConfigurationUtil.getColorFromString(rimColor);
				end;

				if rimColorName ~= nil then
					local r, g, b, _ = unpack(rimColorName);
					
					for _, wheel in pairs(self.spec_wheels.wheels) do
						if wheel.wheelOuterRim ~= nil then
							if materialId == nil then
								_, _, _, materialId = getShaderParameter(wheel.wheelOuterRim, shaderParameterName);
							end;
						
							setShaderParameter(wheel.wheelOuterRim, shaderParameterName, r, g, b, materialId, false);
			
							printDebug("(colorChanges) :: Change outer rim color successfully in '" .. self.configFileName .. "'.", 1, true);
						end;
						
						if wheel.wheelInnerRim ~= nil then
							if materialId == nil then
								_, _, _, materialId = getShaderParameter(wheel.wheelInnerRim, shaderParameterName);
							end;
						
							setShaderParameter(wheel.wheelInnerRim, shaderParameterName, r, g, b, materialId, false);
						
							printDebug("(colorChanges) :: Change inner rim color successfully in '" .. self.configFileName .. "'.", 1, true);
						end;

						if wheel.additionalWheels ~= nil then
							for _, additionalWheel in pairs(wheel.additionalWheels) do	
								if additionalWheel.wheelOuterRim ~= nil then	
									if materialId == nil then
										_, _, _, materialId = getShaderParameter(additionalWheel.wheelOuterRim, shaderParameterName);
									end;
								
									setShaderParameter(additionalWheel.wheelOuterRim, shaderParameterName, r, g, b, materialId, false);

									printDebug("(colorChanges) :: Change additional outer rim color successfully in '" .. self.configFileName .. "'.", 1, true);
								end;

								if additionalWheel.wheelInnerRim ~= nil then
									if materialId == nil then
										_, _, _, materialId = getShaderParameter(additionalWheel.wheelInnerRim, shaderParameterName);
									end;
								
									setShaderParameter(additionalWheel.wheelInnerRim, shaderParameterName, r, g, b, materialId, false);

									printDebug("(colorChanges) :: Change inner rim color successfully in '" .. self.configFileName .. "'.", 1, true);
								end;

								if additionalWheel.connector ~= nil and additionalWheel.connector.node ~= nil then	
									if materialId == nil then
										_, _, _, materialId = getShaderParameter(additionalWheel.connector.node, shaderParameterName);
									end;
								
									setShaderParameter(additionalWheel.connector.node, shaderParameterName, r, g, b, materialId, false);

									printDebug("(colorChanges) :: Change additional connector color successfully in '" .. self.configFileName .. "'.", 1, true);
								end;
							end;
						end;
					end;
				else
					printError("(colorChanges) :: Failed to load color '" .. tostring(rimColor) .. "' in '" .. self.configFileName .. "'! Stop coloring rims!", false, false);
				end;
			end;
		end;

		ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle." .. configName .. "Configurations." .. secondConfigName .. "Configuration", configId, self.components, self);
	end;
end;
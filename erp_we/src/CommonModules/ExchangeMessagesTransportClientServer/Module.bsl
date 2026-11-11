///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Function StructureOfConnectionSettings() Export

	Settings = New Structure;
	
	Settings.Insert("NodeCode", "");
	Settings.Insert("CorrespondentNodeCode", "");
	Settings.Insert("SettingID", "");
	Settings.Insert("ExchangePlanName", "");
	Settings.Insert("CorrespondentExchangePlanName", "");
	Settings.Insert("ExchangeSetupOption", "");
	Settings.Insert("ExchangeFormat", Undefined);
	Settings.Insert("InfobaseNode", Undefined);
	Settings.Insert("WizardRunOption", "");
	Settings.Insert("RefToNew", Undefined);
	Settings.Insert("PredefinedNodeCode", "");
	Settings.Insert("SecondInfobaseNewNodeCode", "");
	Settings.Insert("ThisInfobaseDescription", "");
	Settings.Insert("SecondInfobaseDescription", "");
	Settings.Insert("SourceInfobasePrefix", "");
	Settings.Insert("DestinationInfobasePrefix", "");
	Settings.Insert("InfobaseNode", Undefined);
	Settings.Insert("UsePrefixesForExchangeSettings", False);
	Settings.Insert("UsePrefixesForCorrespondentExchangeSettings", False);
	Settings.Insert("SourceInfobaseID", "");
	Settings.Insert("DestinationInfobaseID", "");
	Settings.Insert("ExchangeDataSettingsFileFormatVersion", "");
	Settings.Insert("ExchangeFormatVersion", "");
	Settings.Insert("ExchangeFormatVersions", New Array);
	Settings.Insert("SupportedObjectsInFormat", Undefined);
	Settings.Insert("SupportedPeerInfobaseFormatObjects", Undefined);
	Settings.Insert("TransportID", "");
	Settings.Insert("TransportSettings", New Structure);
	Settings.Insert("AuthenticationData", New Structure);
	Settings.Insert("WSCorrespondentEndpoint", "");
	Settings.Insert("WSPeerDataArea", 0);
	Settings.Insert("RestoreExchangeSettings", "");
	Settings.Insert("SentNo", 0);
	Settings.Insert("ReceivedNo", 0);
	Settings.Insert("FixDuplicateSynchronizationSettings");
	Settings.Insert("ThisInfobaseHasPeerInfobaseNode");
	Settings.Insert("ThisNodeExistsInPeerInfobase");
	
	Return Settings;
	
EndFunction

Function ConnectionSettingsForProcessing(ExchangeCreationWizard) Export

	Settings = StructureOfConnectionSettings();
	
	FillPropertyValues(Settings, ExchangeCreationWizard);
	
	If Settings.UsePrefixesForExchangeSettings
		Or Settings.UsePrefixesForCorrespondentExchangeSettings Then
		
		Settings.NodeCode = Settings.SourceInfobasePrefix;
			
	Else
		
		Settings.NodeCode = Settings.SourceInfobaseID;
		
	EndIf;
	
	If Settings.UsePrefixesForExchangeSettings
		Or Settings.UsePrefixesForCorrespondentExchangeSettings Then
		
		Settings.CorrespondentNodeCode = Settings.DestinationInfobasePrefix;
			
	Else
		
		Settings.CorrespondentNodeCode = Settings.DestinationInfobaseID;
		
	EndIf;
	
	Settings.SupportedObjectsInFormat = ExchangeCreationWizard.SupportedPeerInfobaseFormatObjects;
	Settings.ExchangeSetupOption = ExchangeCreationWizard.SettingID;
		
	Return Settings;
	
EndFunction

#EndRegion




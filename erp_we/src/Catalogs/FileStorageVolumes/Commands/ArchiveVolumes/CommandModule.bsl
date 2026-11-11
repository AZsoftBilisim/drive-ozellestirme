///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	ValueForFilter = CommonClient.PredefinedItem("Enum.StorageKinds.ArchivalStorage");

	Filter = New Structure("StorageVolumeType", ValueForFilter);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("FilterValueByFilesStorageVolumeKind", ValueForFilter);	

	OpenForm("Catalog.FileStorageVolumes.ListForm", 
		FormParameters,
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window);

EndProcedure

#EndRegion
///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.BatchEditObjects

// Returns object attributes that can be edited using the bulk attribute modification data processor.
// 
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export
	
	AttributesToEdit = New Array;
	AttributesToEdit.Add("Comment");
	
	Return AttributesToEdit;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.ReportsOptions

// Defines the list of report commands.
//
// Parameters:
//  ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//  Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	If Not AccessRight("View", Metadata.Reports.VolumeIntegrityCheck) Then
		Return;
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.VariantKey       = "Main";
	Command.Presentation      = NStr("vi = 'Kiểm tra tính toàn vẹn của quyển';
									|ru = 'Проверка целостности тома';
									|en = 'Volume integrity check'; fa = 'بررسی یکپارچگی حجم';
									|it = 'Проверка целостности тома';
									|pl = 'Weryfikacja integralności woluminu';
									|tr = 'Birim bütünlüğünün kontrolü'");
	Command.Id      = "VolumeIntegrityCheck";
	Command.Manager           = "Report.VolumeIntegrityCheck";
	Command.MultipleChoice = False;
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region Private

// For internal use only.
// 
// Parameters:
//   Queries - Array
//   StorageVolumeType - EnumRef.StorageKinds, Undefined - The default value is Undefined.
//
Procedure AddRequestsToUseExternalResourcesForAllVolumes(Queries, Val StorageVolumeType = Undefined) Export
	
	If Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	If StorageVolumeType = Undefined Then
		StorageVolumeType = Enums.StorageKinds.OperationalStorage;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	FileStorageVolumes.Ref AS Ref,
	|	FileStorageVolumes.FullPathLinux AS FullPathLinux,
	|	FileStorageVolumes.FullPathWindows AS FullPathWindows,
	|	FileStorageVolumes.DeletionMark AS DeletionMark
	|FROM
	|	Catalog.FileStorageVolumes AS FileStorageVolumes
	|WHERE
	|	FileStorageVolumes.DeletionMark = FALSE
	|	AND FileStorageVolumes.StorageVolumeType = &StorageVolumeType
	|	AND FileStorageVolumes.FilesStorageMethod = VALUE(Enum.FileStorageOption.NetworkDirectories)";

	Query.SetParameter("StorageVolumeType", StorageVolumeType);

	Selection = Query.Execute().Select();

	While Selection.Next() Do
		Queries.Add(RequestToUseExternalResourcesForVolume(
			Selection.Ref, Selection.FullPathWindows, Selection.FullPathLinux));
	EndDo;

EndProcedure

// For internal use only.
//
// Parameters:
//   Queries - Array
//   StorageVolumeType - EnumRef.StorageKinds, Undefined - The default value is Undefined.
//
Procedure AddRequestsToStopUsingExternalResourcesForAllVolumes(Queries, Val StorageVolumeType = Undefined) Export

	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");

		If StorageVolumeType = Undefined Then
			StorageVolumeType = Enums.StorageKinds.OperationalStorage;
		EndIf;

		Query = New Query;
		Query.Text =
		"SELECT
		|	FileStorageVolumes.Ref AS Ref,
		|	FileStorageVolumes.FullPathLinux AS FullPathLinux,
		|	FileStorageVolumes.FullPathWindows AS FullPathWindows,
		|	FileStorageVolumes.DeletionMark AS DeletionMark
		|FROM
		|	Catalog.FileStorageVolumes AS FileStorageVolumes
		|WHERE
		|	FileStorageVolumes.StorageVolumeType = &StorageVolumeType
		|	AND FileStorageVolumes.FilesStorageMethod = VALUE(Enum.FileStorageOption.NetworkDirectories)";

		Query.SetParameter("StorageVolumeType", StorageVolumeType);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			Queries.Add(ModuleSafeModeManager.RequestToClearPermissionsToUseExternalResources(
				Selection.Ref));
		EndDo;
	EndIf;
	
EndProcedure

// For internal use only.
Function RequestToUseExternalResourcesForVolume(Volume, FullPathWindows, FullPathLinux) Export
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
		Permissions = New Array;
		
		If ValueIsFilled(FullPathWindows) Then
			Permissions.Add(ModuleSafeModeManager.PermissionToUseFileSystemDirectory(
				FullPathWindows, True, True));
		EndIf;
		
		If ValueIsFilled(FullPathLinux) Then
			Permissions.Add(ModuleSafeModeManager.PermissionToUseFileSystemDirectory(
				FullPathLinux, True, True));
		EndIf;
		
		Return ModuleSafeModeManager.RequestToUseExternalResources(Permissions, Volume);
	EndIf;
	
EndFunction

// Verifies that the volume's storage method is InNetworkDirectories.
//
// Parameters:
//  StorageVolumeLink - CatalogRef.FileStorageVolumes
//
// Returns:
//  Boolean
//
Function IsStorageVolumeOnDisks(StorageVolumeLink) Export

	FilesStorageMethod = Common.ObjectAttributeValue(StorageVolumeLink, "FilesStorageMethod");

	Return FilesStorageMethod = Enums.FileStorageOption.NetworkDirectories;

EndFunction

#Region UpdateHandlers

// Version update handler:
// - Populates attributes FileStorageVolumeKind and FilesStorageMethod in catalog FileStorageVolumes.
//
Procedure ProcessDataForMigrationToNewVersion() Export

	Query = New Query;
	Query.Text =
	"SELECT
	|	FileStorageVolumes.Ref AS Ref
	|FROM
	|	Catalog.FileStorageVolumes AS FileStorageVolumes
	|WHERE
	|	FileStorageVolumes.FilesStorageMethod = VALUE(Enum.FileStorageOption.EmptyRef)";

	FileStorageVolumes = Query.Execute().Select();	
	
	While FileStorageVolumes.Next() Do

		Block = New DataLock;
		LockItem = Block.Add("Catalog.FileStorageVolumes");
		LockItem.SetValue("Ref", FileStorageVolumes.Ref);

		RepresentationOfTheReference = String(FileStorageVolumes.Ref);

		BeginTransaction();
		Try
			Block.Lock();
			CatalogObject = FileStorageVolumes.Ref.GetObject();

			If CatalogObject = Undefined Then
				CommitTransaction();
				Continue;
			EndIf;

			CatalogObject.StorageVolumeType	= Enums.StorageKinds.OperationalStorage;
			CatalogObject.FilesStorageMethod	= Enums.FileStorageOption.NetworkDirectories;

			InfobaseUpdate.WriteData(CatalogObject);
			CommitTransaction();

		Except
			RollbackTransaction();
			
			InfobaseUpdate.WriteErrorToEventLog(FileStorageVolumes.Ref,
				RepresentationOfTheReference, ErrorInfo());

			Raise;
		EndTry;
	EndDo;
	
EndProcedure

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("ProcessDataForMigrationToNewVersion");
	
EndProcedure

#EndRegion

#EndIf

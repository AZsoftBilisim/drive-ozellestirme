///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns a value table containing settings for managing the file archive.
// Used by scheduled job TransferFilesBetweenOperationalStorageAndFileArchive.
//
// Returns:
//  ValueTable
//
Function GetFileArchiveOperationsSettingsToTransferFiles() Export

	Query = New Query;
	Query.Text = GetQueryTextFileArchiveOperationsCurrentSettings(True);

	Return Query.Execute().Unload();

EndFunction

// Returns the default retention period in days.
//
// Returns:
//  Number
//
Function GetStorageDaysCountFromDefaultSetting() Export

	Result = 0;

	Query = New Query;
	Query.Text =
       "SELECT
       |	FileArchiveSettings.ArchiveAfterDays AS ArchiveAfterDays
       |FROM
       |	InformationRegister.FileArchiveSettings AS FileArchiveSettings
       |WHERE
       |	FileArchiveSettings.FileOwner = UNDEFINED
       |	AND FileArchiveSettings.FileOwnerType = UNDEFINED";

	DataSelection = Query.Execute().Select();
	If DataSelection.Next() Then
		Result = DataSelection.ArchiveAfterDays;
	EndIf;

	If Result = 0 Then
		Result = GetDefaultValueToTransferToFileArchiveInDays();
	EndIf;

	Return Result;

EndFunction

#EndRegion

#Region Private

// Adds an entry to the information register.
// 
Procedure AddRecord(RecordStructure) Export

	RecordSet = CreateRecordSet();
	RecordSet.Filter.FileOwner.Set(RecordStructure["FileOwner"]);
	RecordSet.Filter.FileOwnerType.Set(RecordStructure["FileOwnerType"]);

	Record = RecordSet.Add();
	FillPropertyValues(Record, RecordStructure);

	RecordSet.Write(True);

EndProcedure

// Deletes an entry from the information register.
//
Procedure DeleteRecord(FileOwner, FileOwnerType) Export
	
	Set = CreateRecordSet();
	Set.Filter.FileOwner.Set(FileOwner);
	Set.Filter.FileOwnerType.Set(FileOwnerType);
	Set.Write();	
	
EndProcedure 

Function StructureOfRecord() Export
	
	Result = New Structure;
	Result.Insert("FileOwner");
	Result.Insert("FileOwnerType");
	Result.Insert("Action");
	Result.Insert("ArchiveAfterDays");
	Result.Insert("IsFile");
	
	Return Result;
	
EndFunction

Procedure RefreshFileArchiveOperationsSettings()
	
	MetadataCatalogs = Metadata.Catalogs;
	
	FilesOwnersTable = New ValueTable;
	FilesOwnersTable.Columns.Add("FileOwner",     New TypeDescription("CatalogRef.MetadataObjectIDs"));
	FilesOwnersTable.Columns.Add("FileOwnerType", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	FilesOwnersTable.Columns.Add("IsFile",           New TypeDescription("Boolean"));
	
	For Each Catalog In MetadataCatalogs Do
		
		If Catalog.Attributes.Find("FileOwner") = Undefined Then
			Continue;
		EndIf;
		
		FilesOwnersTypes = Catalog.Attributes.FileOwner.Type.Types();
		For Each OwnerType In FilesOwnersTypes Do
			
			NewRow = FilesOwnersTable.Add();
			NewRow.FileOwner = Common.MetadataObjectID(OwnerType);
			NewRow.FileOwnerType = Common.MetadataObjectID(Catalog);
			If Not StrEndsWith(Catalog.Name, FilesOperationsInternal.CatalogSuffixAttachedFiles()) Then
				NewRow.IsFile = True;
			EndIf;
			
		EndDo;
		
	EndDo;

	Query = New Query; Query.TempTablesManager = New TempTablesManager;
	Query.Text =
		"SELECT
		|	FilesOwnersTable.FileOwner AS FileOwner,
		|	FilesOwnersTable.FileOwnerType AS FileOwnerType,
		|	FilesOwnersTable.IsFile AS IsFile
		|INTO FilesOwnersTable
		|FROM
		|	&FilesOwnersTable AS FilesOwnersTable
		|
		|INDEX BY
		|	FileOwner,
		|	IsFile
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FileArchiveSettings.FileOwner AS FileOwner,
		|	FileArchiveSettings.FileOwnerType AS FileOwnerType,
		|	FileArchiveSettings.IsFile AS IsFile,
		|	MetadataObjectIDs.Ref AS ObjectID
		|INTO SubordinateSettings
		|FROM
		|	InformationRegister.FileArchiveSettings AS FileArchiveSettings
		|		LEFT JOIN Catalog.MetadataObjectIDs AS MetadataObjectIDs
		|		ON FileArchiveSettings.FileOwner <> UNDEFINED
		|			AND FileArchiveSettings.FileOwnerType <> UNDEFINED
		|			AND (VALUETYPE(FileArchiveSettings.FileOwner) = VALUETYPE(MetadataObjectIDs.EmptyRefValue))
		|WHERE
		|	FileArchiveSettings.FileOwner <> UNDEFINED
		|		AND FileArchiveSettings.FileOwnerType <> UNDEFINED		
		|		AND VALUETYPE(FileArchiveSettings.FileOwner) <> TYPE(Catalog.MetadataObjectIDs)
		|
		|INDEX BY
		|	ObjectID,
		|	IsFile,
		|	FileOwnerType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FileArchiveSettings.FileOwner AS FileOwner,
		|	FileArchiveSettings.FileOwnerType AS FileOwnerType,
		|	FileArchiveSettings.IsFile AS IsFile,
		|	FALSE AS NewSetting
		|FROM
		|	InformationRegister.FileArchiveSettings AS FileArchiveSettings
		|		LEFT JOIN FilesOwnersTable AS FilesOwnersTable
		|		ON FileArchiveSettings.FileOwner = FilesOwnersTable.FileOwner
		|			AND FileArchiveSettings.IsFile = FilesOwnersTable.IsFile
		|			AND FileArchiveSettings.FileOwnerType = FilesOwnersTable.FileOwnerType
		|WHERE
		|	FilesOwnersTable.FileOwner IS NULL
		|	AND VALUETYPE(FileArchiveSettings.FileOwner) = TYPE(Catalog.MetadataObjectIDs)
		|
		|UNION ALL
		|
		|SELECT
		|	SubordinateSettings.FileOwner,
		|	SubordinateSettings.FileOwnerType,
		|	SubordinateSettings.IsFile,
		|	FALSE
		|FROM
		|	SubordinateSettings AS SubordinateSettings
		|		LEFT JOIN FilesOwnersTable AS FilesOwnersTable
		|		ON SubordinateSettings.FileOwnerType = FilesOwnersTable.FileOwnerType
		|			AND SubordinateSettings.IsFile = FilesOwnersTable.IsFile
		|			AND SubordinateSettings.ObjectID = FilesOwnersTable.FileOwner
		|WHERE
		|	FilesOwnersTable.FileOwner IS NULL";
	
	Query.Parameters.Insert("FilesOwnersTable", FilesOwnersTable);
	CommonSettingsTable = Query.Execute().Unload();
	
	SettingsForDelete = CommonSettingsTable.FindRows(New Structure("NewSetting", False));
	For Each Setting In SettingsForDelete Do

		DeleteRecord(Setting.FileOwner, Setting.FileOwnerType);

	EndDo;
	
EndProcedure

Function GetDefaultValueToTransferToFileArchiveInDays()

	Return 365;

EndFunction

// Returns:
//   ValueTable:
//   * FileOwner						- AnyRef
//   * OwnerID				- CatalogRef.MetadataObjectIDs
//   * IsFilesTransferDetailedSetting	- Boolean
//   * FileOwnerType					- CatalogRef.MetadataObjectIDs
//   * ArchiveAfterDays		- Number
//   * Action								- EnumRef.FileArchivingBehavior
//   * IsFile								- Boolean
//
Function FileArchiveOperationsCurrentSettings() Export

	SetPrivilegedMode(True);

	RefreshFileArchiveOperationsSettings();

	Query = New Query;
	Query.Text = GetQueryTextFileArchiveOperationsCurrentSettings();

	Return Query.Execute().Unload();

EndFunction

Function GetQueryTextFileArchiveOperationsCurrentSettings(QueryForScheduledJob = False)

	Result = 
		"SELECT
		|	FileArchiveSettings.FileOwner AS FileOwner,
		|	MetadataObjectIDs.Ref AS OwnerID,
		|	CASE
		|		WHEN VALUETYPE(MetadataObjectIDs.Ref) <> VALUETYPE(FileArchiveSettings.FileOwner)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS IsFilesTransferDetailedSetting,
		|	FileArchiveSettings.FileOwnerType AS FileOwnerType,
		|	FileArchiveSettings.ArchiveAfterDays AS ArchiveAfterDays,
		|	FileArchiveSettings.Action AS Action,
		|	&AdditionalField,
		|	FileArchiveSettings.IsFile AS IsFile
		|FROM
		|	InformationRegister.FileArchiveSettings AS FileArchiveSettings
		|		LEFT JOIN Catalog.MetadataObjectIDs AS MetadataObjectIDs
		|		ON FileArchiveSettings.FileOwner <> UNDEFINED
		|		AND FileArchiveSettings.FileOwnerType <> UNDEFINED
		|		AND (VALUETYPE(FileArchiveSettings.FileOwner) = VALUETYPE(MetadataObjectIDs.EmptyRefValue))";

	If Not QueryForScheduledJob Then
		Result = StrReplace(Result, "&AdditionalField,", "");
	EndIf;

	If QueryForScheduledJob Then

		Result = StrReplace(Result, "&AdditionalField,", 
		"	CASE
		|		WHEN VALUETYPE(MetadataObjectIDs.Ref) <> VALUETYPE(FileArchiveSettings.FileOwner)
		|			THEN MetadataObjectIDs.Ref
		|		ELSE FileArchiveSettings.FileOwner
		|	END AS OwnerCommonID,");

		Result = Result + "
		|WHERE
		|	FileArchiveSettings.FileOwner <> UNDEFINED
		|	AND FileArchiveSettings.FileOwnerType <> UNDEFINED"
	EndIf;

	Return Result;

EndFunction

#EndRegion

#EndIf
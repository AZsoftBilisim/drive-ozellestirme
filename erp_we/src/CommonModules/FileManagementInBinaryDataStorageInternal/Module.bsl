///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// It is called before the transaction start.
// All these files must be filled in for new files.
// 
// Parameters:
//  Context - See FilesOperationsInternal.FileUpdateContext
//
Procedure BeforeUpdatingTheFileData(Context) Export
	FilesOperationsInVolumesInternal.BeforeUpdatingTheFileData(Context);
EndProcedure

// It is called in a modification transaction.
//
// Parameters:
//  Context - See FilesOperationsInternal.FileUpdateContext
//  AttachedFile - DefinedType.AttachedFileObject
//
Procedure BeforeWritingFileData(Context, AttachedFile) Export
	FilesOperationsInVolumesInternal.BeforeWritingFileData(Context, AttachedFile);
EndProcedure

// Called in a modification transaction after saving an attachment.
// 
// Parameters:
//  Context - See FilesOperationsInternal.FileUpdateContext
//  AttachedFile - DefinedType.AttachedFile
//
Procedure WhenUpdatingFileData(Context, AttachedFile) Export
	If AttachedFile.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
		FilesOperationsInVolumesInternal.WhenUpdatingFileData(Context, AttachedFile);
	Else
		FilesOperationsInternal.WhenUpdatingFileData(Context, AttachedFile);
	EndIf;
EndProcedure

// Parameters:
//  Context - See FilesOperationsInternal.FileUpdateContext
//  Success - Boolean - True if the transaction is successfully committed.
//
Procedure AfterUpdatingTheFileData(Context, Success) Export
	FilesOperationsInternal.AfterUpdatingTheFileData(Context, Success);
EndProcedure

// Determines the binary data storage attribute corresponding to the specified file storage type.
//
// Parameters:
//  FilesStorageTyoe - EnumRef.FileStorageTypes
//  GettingFileFromArchive - Boolean
//
// Returns:
//  String
//
Function DefineBinaryDataStorageAttributeByFileStorageType(FilesStorageTyoe, GettingFileFromArchive = False) Export

	If FilesStorageTyoe = Enums.FileStorageTypes.InInfobase Then
		Result = "BinaryData";
	ElsIf FilesStorageTyoe = Enums.FileStorageTypes.ExternalBinaryDataStorage Then
		If GettingFileFromArchive Then
 			Result = "BinaryDataInArchive";			
		Else
 			Result = "BinaryDataInExternalOperationalStorage";
		EndIf;
	ElsIf FilesStorageTyoe = Enums.FileStorageTypes.InternalBinaryDataStorage Then
		Result = "BinaryDataInInternalOperationalStorage";
	Else
		Result = "";
	EndIf;

	Return Result;

EndFunction

// Checks whether the file storage option uses disk volumes.
//
// Parameters:
//  FileStorageType - EnumRef.FileStorageTypes
//
// Returns:
//  Boolean
//
Function StorageTypeDoesNotUseDisks(FileStorageType) Export
	
	If FileStorageType = Enums.FileStorageTypes.InInfobase
			Or FileStorageType = Enums.FileStorageTypes.ExternalBinaryDataStorage
			Or FileStorageType = Enums.FileStorageTypes.InternalBinaryDataStorage Then
		Result = True;
	Else
		Result= False;
	EndIf;

	Return Result;

EndFunction

#EndRegion
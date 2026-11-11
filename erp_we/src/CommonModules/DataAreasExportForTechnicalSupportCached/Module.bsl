
#Region Internal

// Metadata excluded from uploading in technical support mode.
// 
// Returns: 
//  FixedArray of MetadataObject
Function MetadataExcludedFromUploadingInTechnicalSupportMode() Export
	
	MetadataExcludedFromUploading = New Array;
	
	ExportImportDataOverridable.WhenFillingInMetadataExcludedFromUploadingInTechnicalSupportMode(MetadataExcludedFromUploading);
	
	MetadataOfDefinedAttachedFileType = Metadata.DefinedTypes.Find("AttachedFile");
	If MetadataOfDefinedAttachedFileType <> Undefined Then
		AttachedFilesTypes = MetadataOfDefinedAttachedFileType.Type.Types(); // Array of Type
		For Each AttachedFileType In AttachedFilesTypes Do
			AttachedFileMetadata = Metadata.FindByType(AttachedFileType);
			MetadataExcludedFromUploading.Add(AttachedFileMetadata);
		EndDo;		
	EndIf;

	ObjectVersionRegisterMetadata = Metadata.InformationRegisters.Find("ObjectsVersions");
	If ObjectVersionRegisterMetadata <> Undefined Then	
		MetadataExcludedFromUploading.Add(ObjectVersionRegisterMetadata);		
	EndIf;
	
	RegisterMetadataBinaryFileData = Metadata.InformationRegisters.Find("BinaryFilesData");
	If RegisterMetadataBinaryFileData <> Undefined Then	
		MetadataExcludedFromUploading.Add(RegisterMetadataBinaryFileData);		
	EndIf;
	
	MetadataInformationRegisterFiles = Metadata.InformationRegisters.Find("FilesInfo");
	If MetadataInformationRegisterFiles <> Undefined Then	
		MetadataExcludedFromUploading.Add(MetadataInformationRegisterFiles);		
	EndIf;

	MetadataExcludedFromUploading = CommonClientServer.CollapseArray(MetadataExcludedFromUploading);
	
	Return New FixedArray(MetadataExcludedFromUploading);
	
EndFunction

// Metadata that has links to those excluded from uploading in the technical support mode.
// 
// Returns: 
//	FixedMap - See ExportImportDataInternal.ReferencesToTypes
//
Function MetadataThatHasLinksToThoseExcludedFromUploadingInTechnicalSupportMode() Export
	
	MetadataExcludedFromUploading = DataAreasExportForTechnicalSupportCached.MetadataExcludedFromUploadingInTechnicalSupportMode();
	Return ExportImportDataInternal.ReferencesToMetadataObjects(MetadataExcludedFromUploading);
	
EndFunction

#EndRegion


#Region Internal

// Returns: 
//	FixedMap of KeyAndValue:
//	 * Key - MetadataObject
//	 * Action - String
Function ActionsWhenFindingReferencesToTypesExcludedFromUnloading() Export

 	ActionsWhenLinksAreDetected = New Map();
	TypeDescriptions = ExportImportDataInternalEvents.DescriptionsOfTypesExcludedFromUploadingDownloads();
	
	TypeFixedStructure = Type("FixedStructure");
	StructureType = Type("Structure");	
		
	For Each LongDesc In TypeDescriptions Do
		DescriptionType = TypeOf(LongDesc);
		If Not (DescriptionType = TypeFixedStructure Or DescriptionType = StructureType) Then
			Continue;
		EndIf;

		ActionsWhenLinksAreDetected.Insert(LongDesc.Type, LongDesc.Action);		
	EndDo;
	
	Return New FixedMap(ActionsWhenLinksAreDetected);
	
EndFunction

// Returns: 
//	See ExportImportDataInternal.ReferencesToTypes
//
Function MetadataThatHasReferencesToTypesThatAreExcludedFromUnloadingAndNeedToBeProcessed() Export
	
	ActionsWhenLinksAreDetected = ProcessingTypesExcludedFromUploadCached.ActionsWhenFindingReferencesToTypesExcludedFromUnloading();
	
	MetadataObjectsToBeProcessed = New Array();
	
	For Each KeyValue In ActionsWhenLinksAreDetected Do
		
		If KeyValue.Value = ExportImportData.ActionWithLinksDoNotChange() Then
			Continue;
		EndIf;
		
		MetadataObjectsToBeProcessed.Add(KeyValue.Key);
			
	EndDo;
					
	TypesExcludedFromUnloadingLoading =	ExportImportDataInternalEvents.GetTypesExcludedFromUploadUpload();
	FullNamesOfTypesExcludedFromUploadUpload = New Map();
	For Each TypeExcludedFromUploadUpload In TypesExcludedFromUnloadingLoading Do
		FullNamesOfTypesExcludedFromUploadUpload.Insert(
			TypeExcludedFromUploadUpload.FullName(),
			True);
	EndDo;
	
	ReferencesToMetadataObjects = ExportImportDataInternal.ReferencesToMetadataObjects(MetadataObjectsToBeProcessed);		
	ReferencesToMetadataObjectsRequiringProcessing = New Map();
		
	For Each KeyValue In ReferencesToMetadataObjects Do
		
		FullMetadataObjectName = KeyValue.Key;
				
		If FullNamesOfTypesExcludedFromUploadUpload.Get(FullMetadataObjectName) = True Then
			Continue;
		EndIf;
		
		ReferencesToMetadataObjectsRequiringProcessing.Insert(
			FullMetadataObjectName,
			KeyValue.Value);
			
	EndDo;
	
	Return New FixedMap(ReferencesToMetadataObjectsRequiringProcessing);
	
EndFunction

#EndRegion

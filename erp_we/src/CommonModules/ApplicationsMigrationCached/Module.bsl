
#Region Internal

// Returns the types of shared data links that are matched by search fields.
//
// Returns:
//   Map of KeyAndValue - collection of link types:
//    * Key - Type
//    * Value - Boolean
//
Function TypesOfSharedDataToBeMatchedBySearchFields() Export
	
	Types = New Map;
	For Each MetadataObject In ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading() Do
		Types.Insert(TypeOfMetadataReferenceObject(MetadataObject), True);
	EndDo;
	
	Return Types;
	
EndFunction

// Returns the types of shared data links that are mapped by a predefined name.
// 
// Returns: 
//	Map of KeyAndValue - collection of link types:
//	 * Key - Type
//	 * Value - Boolean
Function TypesOfMappedSharedDataByPredefinedName() Export
	
	Types = New Map;
	
	SeparatedMetadataObjects = ApplicationsMigrationCached.AreaDataModel();
	PermittedSharedData = ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading();
	
	For Each MetadataKind In TypesOfMetadataWithPredefined() Do
		For Each MetadataObject In MetadataKind Do
			If SeparatedMetadataObjects.Get(MetadataObject) <> Undefined Then
				Continue;
			EndIf;
			If PermittedSharedData.Find(MetadataObject) <> Undefined Then
				Continue;
			EndIf;
			If MetadataObject.GetPredefinedNames().Count() <> 0 Then
				Types.Insert(TypeOfMetadataReferenceObject(MetadataObject), True);
			EndIf;
		EndDo;
	EndDo;
	
	Return Types;
	
EndFunction

// Returns a collection of separated metadata that is data.
//
// Returns:
//   Map of KeyAndValue - collection of objects:
//   * Key - MetadataObject
//   * Value - Boolean
//
Function AreaDataModel() Export
	
	AreaDataModel = New Map;
	
	DontUse  = Metadata.ObjectProperties.CommonAttributeUse.DontUse;
	For Each Content In Metadata.CommonAttributes.DataAreaMainData.Content Do
		MetadataObject = Content.Metadata;
		
		// If an object is added by an extension, then regardless of the settings it is included in the data model of the area
		// , this code is needed to correctly upload data from an undivided database.
		//
		// The scheme of entry of objects added by the extension into the separators is as follows:
		// If the database is not shared:
		//	then
		//	the Non-use exception will be set for extension objects when the Auto-Use property of the shared Attribute is in the Non-use position
		//	, then Auto will be set for extension objects
		// If the base is split and the extension is set to the area:
		//	then for extension objects, the setting will be set to the same position as the property
		//	Separation of configuration extensions of common Attributes.
		If Content.Use = DontUse 
			And MetadataObject.ConfigurationExtension() = Undefined Then
			Continue;
		EndIf;
		
		If Metadata.ScheduledJobs.Contains(MetadataObject)
			Or Metadata.ExternalDataSources.Contains(MetadataObject)
			Or Metadata.IntegrationServices.Contains(MetadataObject)
			Or Metadata.ExchangePlans.Contains(MetadataObject) Then
			Continue;
		EndIf;
		
		AreaDataModel.Insert(MetadataObject, True);
		
		If Metadata.CalculationRegisters.Contains(MetadataObject) Then
			For Each Recalculation In MetadataObject.Recalculations Do
				AreaDataModel.Insert(Recalculation, True);
			EndDo; 
		EndIf;
		
	EndDo;
	
	Use  = Metadata.ObjectProperties.CommonAttributeUse.Use;
	For Each Content In Metadata.CommonAttributes.DataAreaAuxiliaryData.Content Do
		MetadataObject = Content.Metadata;
		If Content.Use = Use 
			And Not Metadata.ScheduledJobs.Contains(MetadataObject)
			And Not Metadata.ExternalDataSources.Contains(MetadataObject)
			And Not Metadata.IntegrationServices.Contains(MetadataObject)
			And Not Metadata.ExchangePlans.Contains(MetadataObject) Then
			AreaDataModel.Insert(MetadataObject, True);
			If Metadata.CalculationRegisters.Contains(MetadataObject) Then
				For Each Recalculation In MetadataObject.Recalculations Do
					AreaDataModel.Insert(Recalculation, True);
				EndDo; 
			EndIf;
		EndIf;
	EndDo;
	
	For Each Sequence In Metadata.Sequences Do
		For Each MetadataObject In Sequence.Documents Do
			If AreaDataModel.Get(MetadataObject) <> Undefined Then
				AreaDataModel.Insert(Sequence, True);
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	Return New FixedMap(AreaDataModel);
	
EndFunction

// Returns the loaded metadata objects that are used in the upload.
//
// Returns:
//   Map of KeyAndValue - collection of objects:
//   * Key - MetadataObject
//   * Value - Boolean
//
Function UnloadedObjects() Export
	
	UnloadedObjects = New Map(ApplicationsMigrationCached.AreaDataModel());
	
	For Each MetadataObject In ExportImportDataInternalEvents.GetTypesExcludedFromUploadUpload() Do
		UnloadedObjects.Delete(MetadataObject);
	EndDo;
	
	Return UnloadedObjects;
	
EndFunction

// Returns a collection of forbidden link types.
//
// Returns:
//  Map of KeyAndValue - collection of link types:
//   * Key - Type
//   * Value - Boolean
//
Function ProhibitedTypesOfSharedData() Export
	
	Types = New Map;
	
	SeparatedMetadataObjects = ApplicationsMigrationCached.AreaDataModel();
	PermittedSharedData = ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading();
	TypesOfMetadataWithPredefined = TypesOfMetadataWithPredefined();
	
	MetadataKinds = New Array;
	MetadataKinds.Add(Metadata.Catalogs);
	MetadataKinds.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataKinds.Add(Metadata.ChartsOfAccounts);
	MetadataKinds.Add(Metadata.ChartsOfCalculationTypes);
	MetadataKinds.Add(Metadata.Documents);
	MetadataKinds.Add(Metadata.BusinessProcesses);
	MetadataKinds.Add(Metadata.Tasks);
	
	For Each MetadataKind In MetadataKinds Do
		HavePredefined = TypesOfMetadataWithPredefined.Find(MetadataKind) <> Undefined;
		For Each MetadataObject In MetadataKind Do
			If SeparatedMetadataObjects.Get(MetadataObject) <> Undefined Then
				Continue;
			EndIf;
			If PermittedSharedData.Find(MetadataObject) <> Undefined Then
				Continue;
			EndIf;
			If Not HavePredefined Or MetadataObject.GetPredefinedNames().Count() = 0 Then
				Types.Insert(TypeOfMetadataReferenceObject(MetadataObject), True);
			EndIf;
		EndDo;
	EndDo;
	
	Return Types;
	
EndFunction

// Returns a collection of object reference types that are separated independently and jointly.
//
// Returns:
//	Map of KeyAndValue - collection of link types:
//	 * Key - Type
//	 * Value - Boolean	
Function TypesOfLinksToBeRecreated() Export
	
	Types = New Map;
	
	For Each CompositionItem In Metadata.CommonAttributes.DataAreaAuxiliaryData.Content Do
		If CompositionItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Use Then
			
			If Metadata.Catalogs.Contains(CompositionItem.Metadata)
				Or Metadata.ChartsOfCharacteristicTypes.Contains(CompositionItem.Metadata)
				Or Metadata.ExchangePlans.Contains(CompositionItem.Metadata)
				Or Metadata.Documents.Contains(CompositionItem.Metadata)
				Or Metadata.ChartsOfAccounts.Contains(CompositionItem.Metadata)
				Or Metadata.ChartsOfCalculationTypes.Contains(CompositionItem.Metadata)
				Or Metadata.BusinessProcesses.Contains(CompositionItem.Metadata)
				Or Metadata.Tasks.Contains(CompositionItem.Metadata) Then
				
				Types.Insert(TypeOfMetadataReferenceObject(CompositionItem.Metadata), True);
				
			EndIf;
		EndIf;
	EndDo;
	
	Return Types;
	
EndFunction

// Returns a collection of shared metadata objects.
//
// Returns:
//   Map of KeyAndValue - collection of metadata objects:
//   * Key - MetadataObject
//   * Value - Boolean
//
Function SharedMetadataObjects() Export
	
	Objects = New Map;
	
	For Each CompositionItem In Metadata.CommonAttributes.DataAreaAuxiliaryData.Content Do
		If CompositionItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Use Then
			Objects.Insert(CompositionItem.Metadata, True);
		EndIf;
	EndDo;
	
	Return Objects;
	
EndFunction

// Returns the types of metadata that can have predefined elements.
//
// Returns:
//   Array of MetadataObject - array of object types.
//
Function TypesOfMetadataWithPredefined() Export
	
	MetadataKinds = New Array;
	MetadataKinds.Add(Metadata.Catalogs);
	MetadataKinds.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataKinds.Add(Metadata.ChartsOfAccounts);
	MetadataKinds.Add(Metadata.ChartsOfCalculationTypes);
	
	Return MetadataKinds;
	
EndFunction

#EndRegion

#Region Private

// Returns the type of the metadata reference object.
// 
// Parameters:
// 	MetadataObject - MetadataObjectCatalog, MetadataObjectDocument, MetadataObjectChartOfCharacteristicTypes -
// 					 - MetadataObjectChartOfAccounts, MetadataObjectChartOfCalculationTypes, MetadataObjectExchangePlan - 
// 					 - MetadataObjectBusinessProcess, MetadataObjectTask - metadata object.
// Returns:
// 	TypeDescription - description of the reference type.
Function TypeOfMetadataReferenceObject(MetadataObject) 
	
	Return MetadataObject.StandardAttributes.Ref.Type.Types()[0];
	
EndFunction

#EndRegion

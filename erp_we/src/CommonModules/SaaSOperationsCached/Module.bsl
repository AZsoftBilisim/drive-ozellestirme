///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2018, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns the sign of the presence in the General configuration details-separators.
//
// Returns:
//   Boolean - True if it is a split configuration.
//
Function IsSeparatedConfiguration() Export
	
	HasSeparators = False;
	For Each CommonAttribute In Metadata.CommonAttributes Do
		If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
			HasSeparators = True;
			Break;
		EndIf;
	EndDo;
	
	Return HasSeparators;
	
EndFunction

// Returns an indication that the metadata object is used in shared delimiter details.
//
// Parameters:
//   FullMetadataObjectName - String - the name of the metadata object.
//   Separator - String - name of the shared delimiter that the metadata object is checked for.
//
// Returns:
//   Boolean - True if it is a split object.
//
Function IsSeparatedMetadataObject(Val FullMetadataObjectName, Val Separator = Undefined) Export
	
	If Separator = Undefined Then
		SeparationByMainProps = SaaSOperations.SeparatedMetadataObjects(SaaSOperations.MainDataSeparator());
		SeparationByAuxiliaryProps = SaaSOperations.SeparatedMetadataObjects(SaaSOperations.AuxiliaryDataSeparator());
		Result = SeparationByMainProps.Get(FullMetadataObjectName) <> Undefined
			Or SeparationByAuxiliaryProps.Get(FullMetadataObjectName) <> Undefined;
		Return Result;
	Else
		SeparatedMetadataObjects = SaaSOperations.SeparatedMetadataObjects(Separator);
		Return SeparatedMetadataObjects.Get(FullMetadataObjectName) <> Undefined;
	EndIf;
	
EndFunction

// Returns a flag for working in the data division mode by area
// (technically, this is a sign of conditional division).
// 
// Returns False if the configuration can't work in data separation mode
// (it doesn't contain General details intended for data separation).
//
// Returns:
//  Boolean - True if separation is enabled.
//  Boolean - False if partitioning is disabled or not supported.
//
Function DataSeparationEnabled() Export
	
	If Not IsSeparatedConfiguration() Then
		Return False;
	EndIf;
	
	If Not GetFunctionalOption("SaaSOperations") Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Returns an array of currently supported serializable structure types.
//
// Returns:
//   FixedArray of Type - Type elements.
//
Function SerializableStructuralTypes() Export
	
	TypesArray = New Array;
	
	TypesArray.Add(Type("Structure"));
	TypesArray.Add(Type("FixedStructure"));
	TypesArray.Add(Type("Array"));
	TypesArray.Add(Type("FixedArray"));
	TypesArray.Add(Type("Map"));
	TypesArray.Add(Type("FixedMap"));
	TypesArray.Add(Type("KeyAndValue"));
	TypesArray.Add(Type("ValueTable"));
	
	Return New FixedArray(TypesArray);
	
EndFunction

// Returns the endpoint for sending messages to the service Manager.
//
// Returns:
//  ExchangePlanRef.MessagesExchange - the node corresponding to the service manager.
//
Function ServiceManagerEndpoint() Export
	
	Return SaaSOperationsCTL.ServiceManagerEndpoint();
	
EndFunction

// Returns whether the user's contact information types match the types.
// CI of the service model used in the XDTO.
//
// Returns:
//  FixedMap of KeyAndValue - compliance of types of CI:
//  * Key - CatalogRef.ContactInformationKinds
//  * Value - String
//
Function MatchingUserSAITypesToXDTO() Export
	
	Map = New Map;
	Map.Insert(Catalogs.ContactInformationKinds.UserEmail, "UserEMail");
	Map.Insert(Catalogs.ContactInformationKinds.UserPhone, "UserPhone");
	
	Return New FixedMap(Map);
	
EndFunction

// Returns whether the contact information types match THE xdto types.
// User's KEY.
//
// Returns:
//  FixedMap of KeyAndValue - compliance of types of CI:
//  * Key - String
//  * Value - CatalogRef.ContactInformationKinds
//
Function ComplianceOfKixdtoTypesWithUserKiTypes() Export
	
	Map = New Map;
	For Each KeyAndValue In MatchingUserSAITypesToXDTO() Do
		Map.Insert(KeyAndValue.Value, KeyAndValue.Key);
	EndDo;
	
	Return New FixedMap(Map);
	
EndFunction

// Returns whether the XDTO rights correspond to possible
// actions with the service user used in the service model.
// 
// Returns:
//  FixedMap of KeyAndValue - compliance of rights with actions:
//  * Key - String
//  * Value - String
//
Function ComplianceOfXDTORightsWithActionsWithServiceUser() Export
	
	Map = New Map;
	Map.Insert("ChangePassword", "EditPassword");
	Map.Insert("ChangeName", "ChangeName");
	Map.Insert("ChangeFullName", "ChangeFullName");
	Map.Insert("ChangeAccess", "ChangeAccess");
	Map.Insert("ChangeAdmininstrativeAccess", "ChangeAdministrativeAccess");
	
	Return New FixedMap(Map);
	
EndFunction

// Returns a description of the data model that belongs to the data area.
//
// Returns:
//  FixedMap of KeyAndValue - Area Data Model:
//    * Key - MetadataObject - metadata object.
//    * Value - String - the name of the shared separator prop.
//
Function GetAreaDataModel() Export
	
	Result = New Map();
	
	MainDataSeparator = SaaSOperations.MainDataSeparator();
	CoreAreaData = SeparatedMetadataObjects(
		MainDataSeparator);
	For Each AreaMasterDataElement In CoreAreaData Do
		Result.Insert(AreaMasterDataElement.Key, AreaMasterDataElement.Value);
	EndDo;
	
	AuxiliaryDataSeparator = SaaSOperations.AuxiliaryDataSeparator();
	SupportingAreaData = SaaSOperations.SeparatedMetadataObjects(
		AuxiliaryDataSeparator);
	For Each AreaAuxiliaryDataElement In SupportingAreaData Do
		Result.Insert(AreaAuxiliaryDataElement.Key, AreaAuxiliaryDataElement.Value);
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

// Returns an array of existing delimiters in the configuration.
//
// Returns:
//   FixedArray of String - an array of names of common requisites that
//     are separators.
//
Function ConfigurationSeparators() Export
	
	SeparatorArray = New Array;
	
	For Each CommonAttribute In Metadata.CommonAttributes Do
		If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
			SeparatorArray.Add(CommonAttribute.Name);
		EndIf;
	EndDo;
	
	Return New FixedArray(SeparatorArray);
	
EndFunction

// Returns the composition of the shared props with the specified name.
//
// Parameters:
//   Name - String - name of the shared property.
//
// Returns:
//   CommonAttributeContent - a list of metadata objects that include common props.
//
Function CommonAttributeContent(Val Name) Export
	
	Return Metadata.CommonAttributes[Name].Content;
	
EndFunction

// Returns a list of the full names of all metadata objects that are used in the common delimiter attribute,
//  the name of which is passed as the value of the Delimiter parameter, and the values of the metadata object properties
//  that may be required for further processing in universal algorithms.
// For document sequences and logs, defines the separation by incoming documents: any of them.
//
// Parameters:
//  Separator - String - name of the shared property.
//
// Returns:
// FixedMap of KeyAndValue:
//  * Key - String - full name of the metadata object,
//  * Value - FixedStructure - With Fields:
//    ** Name - String - name of the metadata object,
//    ** Separator - String - name of the separator that separates the metadata object,
//    ** ConditionalSeparation - String - the full name of the metadata object that serves as a condition for using
//      this separator to separate the metadata object.
//
Function SeparatedMetadataObjects(Val Separator) Export
	
	Result = New Map;
	
	// I. Sort through the composition of all common details.
	
	MetadataOfCommonProps = Metadata.CommonAttributes.Find(Separator);
	If MetadataOfCommonProps = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không tìm thấy mục tin chung %1 trong cấu hình.';
																			|ru = 'Общий реквизит %1 не обнаружен в конфигурации.';
																			|en = 'Common attribute %1 is not found in the configuration.'; fa = 'Common attribute %1 is not found in the configuration.';
																			|it = 'Il requisito generale %1 non è stato rilevato all''interno della configurazione.';
																			|pl = 'Wspólny rekwizyt %1 nie wykryto w konfiguracji.';
																			|tr = 'Ortak öznitelik %1 yapılandırmada bulunamadı.'"), Separator);
	EndIf;
	
	If MetadataOfCommonProps.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
		
		CommonAttributeContent = CommonAttributeContent(MetadataOfCommonProps.Name);
		
		DataSeparationEnabled = SaaSOperations.DataSeparationEnabled();
		NotUseCommonAttribute = (MetadataOfCommonProps.AutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse.DontUse);
		Auto = Metadata.ObjectProperties.CommonAttributeUse.Auto;
		DontUse = Metadata.ObjectProperties.CommonAttributeUse.DontUse;
		
		For Each CompositionItem In CommonAttributeContent Do
			
			Use = CompositionItem.Use;
			
			// When separation is disabled for all extension objects, the use of common Attributes is automatic
			If Not DataSeparationEnabled
				And CompositionItem.Metadata.ConfigurationExtension() <> Undefined Then
				
				Use = Auto;
				
			EndIf;
			
			If NotUseCommonAttribute And Use = Auto Or Use = DontUse Then
				
				Continue;
				
			EndIf;
			
			AdditionalData = NewAdditionalData(CompositionItem.Metadata.Name, Separator, Undefined);
			If CompositionItem.ConditionalSeparation <> Undefined Then
				AdditionalData.ConditionalSeparation = CompositionItem.ConditionalSeparation.FullName();
			EndIf;
			
			Result.Insert(CompositionItem.Metadata.FullName(), New FixedStructure(AdditionalData));
			
			// According to the calculation registers, the separation of the recalculations subordinate to them is additionally determined.
			If Common.IsCalculationRegister(CompositionItem.Metadata) Then
				
				Recalculations = CompositionItem.Metadata.Recalculations;
				For Each Recalculation In Recalculations Do
					
					AdditionalData.Name = Recalculation.Name;
					Result.Insert(Recalculation.FullName(), New FixedStructure(AdditionalData));
					
				EndDo;
				
			EndIf;
				
		EndDo;
		
	Else
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đối với mục tin chung %1, không sử dụng phân chia dữ liệu.';
																			|ru = 'Для общего реквизита %1 не используется разделение данных.';
																			|en = 'Data separation is not used for the %1 common attribute.'; fa = 'Data separation is not used for the %1 common attribute.';
																			|it = 'Per il requisito generale %1 non viene utilizzata alcuna separazione dei dati.';
																			|pl = 'Dla wspólnego rekwizytu %1 nie stosuje się podział danych.';
																			|tr = '%1 ortak özelliği için veri ayırma kullanılmıyor.'"), Separator);
		
	EndIf;
	
	// II. For sequences and logs, determine the separation by incoming documents.
	
	// 1) Sequences. Brute force with checking the first incoming document. If there are no documents, we consider it divided.
	For Each MetadataSequences In Metadata.Sequences Do
		
		AdditionalData = NewAdditionalData(MetadataSequences.Name, Separator, Undefined);
		
		If MetadataSequences.Documents.Count() = 0 Then
			
			MessageTemplate = NStr("vi = 'Chuỗi nối tiếp %1 không có bất kỳ văn bản nào.';
									|ru = 'В последовательность %1 не включено ни одного документа.';
									|en = 'Sequence %1 does not include any documents.'; fa = 'Sequence %1 does not include any documents.';
									|it = 'Nessun documento è incluso nella sequenza %1.';
									|pl = 'Sekwencja %1 nie zawiera ani jednego dokumentu.';
									|tr = '%1 sıra herhangi bir belge içermez.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, MetadataSequences.Name);
			WriteLogEvent(NStr("vi = 'Nhận đối tượng metadata chia tách';
								|ru = 'Получение разделенных объектов метаданных';
								|en = 'Getting separated metadata objects'; fa = 'Getting separated metadata objects';
								|it = 'Ricezione di oggetti di metadati separati';
								|pl = 'Uzyskanie rozdzielonych elementów metadanych';
								|tr = 'Ayrı meta veri nesneleri al'", 
				Common.DefaultLanguageCode()), EventLogLevel.Error, 
				MetadataSequences, , MessageText);
			
			Result.Insert(MetadataSequences.FullName(), New FixedStructure(AdditionalData));
			
		Else
			
			For Each MetadataOfDocument In MetadataSequences.Documents Do
				
				AdditionalDataFromDocument = Result.Get(MetadataOfDocument.FullName());
				
				If AdditionalDataFromDocument <> Undefined Then
					FillPropertyValues(AdditionalData, AdditionalDataFromDocument, "Separator,ConditionalSeparation");
					Result.Insert(MetadataSequences.FullName(), New FixedStructure(AdditionalData));
				EndIf;
				
				Break;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	// 2) Magazines. Brute force with checking the first incoming document. If there are no documents, we consider it divided.
	For Each DocumentLogMetadata In Metadata.DocumentJournals Do
		
		AdditionalData = NewAdditionalData(DocumentLogMetadata.Name, Separator, Undefined);
		
		If DocumentLogMetadata.RegisteredDocuments.Count() = 0 Then
			
			MessageTemplate = NStr("vi = 'Nhật ký %1 không có bất kỳ chứng từ nào.';
									|ru = 'В журнал %1 не включено ни одного документа.';
									|en = 'Journal %1 does not contain any documents.'; fa = 'Journal %1 does not contain any documents.';
									|it = 'Nel registro %1 non è incluso nessun documento.';
									|pl = 'Dziennik %1 nie zawiera ani jednego dokumentu.';
									|tr = '%1 günlük herhangi bir belge içermiyor.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, DocumentLogMetadata.Name);
			WriteLogEvent(NStr("vi = 'Nhận đối tượng metadata chia tách';
								|ru = 'Получение разделенных объектов метаданных';
								|en = 'Getting separated metadata objects'; fa = 'Getting separated metadata objects';
								|it = 'Ricezione di oggetti di metadati separati';
								|pl = 'Uzyskanie rozdzielonych elementów metadanych';
								|tr = 'Ayrı meta veri nesneleri al'", 
				Common.DefaultLanguageCode()), EventLogLevel.Error, 
				DocumentLogMetadata, , MessageText);
			
			Result.Insert(DocumentLogMetadata.FullName(), New FixedStructure(AdditionalData));
			
		Else
			
			For Each MetadataOfDocument In DocumentLogMetadata.RegisteredDocuments Do
				
				AdditionalDataFromDocument = Result.Get(MetadataOfDocument.FullName());
				
				If AdditionalDataFromDocument <> Undefined Then
					FillPropertyValues(AdditionalData, AdditionalDataFromDocument, "Separator,ConditionalSeparation");
					Result.Insert(DocumentLogMetadata.FullName(), New FixedStructure(AdditionalData));
				EndIf;
				
				Break;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

// Returns an indication of whether there is a service manager endpoint setup
//
// Returns:
//  Boolean - True if the endpoint of the service manager is installed and the user name is filled in in the transport settings.
//
Function ServiceManagerEndpointConfigured() Export
	
	Return SaaSOperations.ServiceManagerEndpointConfigured()
	
EndFunction

// Returns an indication that the data area is being used by users.
// The areas used by users are determined by the installed application type for the area
//
// Parameters:
//  DataArea -  Number - the value of the separator for the data area 
//   that users want to use to get.
//
// Returns:
//  Boolean
//
Function DataAreaIsUsedByUsers(DataArea) Export

	Return SaaSOperations.DataAreaIsUsedByUsers(DataArea);
	
EndFunction

#EndRegion

#Region Private

// New additional data.
// 
// Parameters:
//  Name - String
//  Separator - Number
//  ConditionalSeparation - String
// 
// Returns:
//  Structure:
// * Name - String
// * Separator - Number
// * ConditionalSeparation - String
Function NewAdditionalData(Name, Separator, ConditionalSeparation = Undefined)
	
	AdditionalData = New Structure;
	AdditionalData.Insert("Name", Name);
	AdditionalData.Insert("Separator", Separator);
	AdditionalData.Insert("ConditionalSeparation", ConditionalSeparation);
	
	Return AdditionalData;
	
EndFunction

#EndRegion

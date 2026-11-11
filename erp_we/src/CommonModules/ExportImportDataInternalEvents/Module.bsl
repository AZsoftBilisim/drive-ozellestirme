////////////////////////////////////////////////////////////////////////////////
// The subsystem "Unloading loading of data".
//
// The procedures and functions of this module contain service events that
// an application developer can subscribe to for enhanced data upload and download capabilities.
////////////////////////////////////////////////////////////////////////////////
// @strict-types

#Region Internal

// Returns the version of the interface for data upload / download handlers 1.0.0.0.
// Returns:
//	String - version.
//
Function HandlerVersion1_0_0_0() Export
	
	Return "1.0.0.0";
	
EndFunction

// Returns the version of the interface for data upload / download handlers 1.0.0.1.
// Returns:
//	String - version.
//
Function HandlerVersion1_0_0_1() Export
	
	Return "1.0.0.1";
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Initialization of events during data upload

// Generates an array of metadata that requires annotation of links when uploading.
//
// Returns:
//	FixedArray of MetadataObjectCatalog - array of metadata.
//
Function GetTypesThatRequireAnnotationOfLinksWhenUnloading() Export
	
	Types = New Array();
	
	// Library Event Handlers
	CTLSubsystemsIntegration.OnFillTypesThatRequireRefAnnotationOnImport(Types);
	
	// Integrated handlers
	ExportImportSharedData.OnFillTypesThatRequireRefAnnotationOnImport(Types);
	ExportImportCommonSeparatedData.OnFillTypesThatRequireRefAnnotationOnImport(Types);
	ExportImportPredefinedData.OnFillTypesThatRequireRefAnnotationOnImport(Types);
	ExportImportExchangePlansNodes.OnFillTypesThatRequireRefAnnotationOnImport(Types);
	
	// Redefined procedure
	ExportImportDataOverridable.OnFillTypesThatRequireRefAnnotationOnImport(Types);
	
	Return New FixedArray(Types);
	
EndFunction

// Generates an array of metadata that support a mapping of the links in the download.
//
// Returns:
//	FixedArray of MetadataObject - metadata array:
//	* StandardAttributes - StandardAttributeDescriptions - Standard banking details:
//		** Ref - MetadataObject - metadata of the props.
Function GetSharedDataTypesThatSupportLinkMappingWhenLoading() Export
	
	Types = New Array();
	
	// Library Event Handlers
	CTLSubsystemsIntegration.OnFillCommonDataTypesSupportingRefMappingOnExport(Types);
	
	// Redefined procedure
	ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefMappingOnExport(Types);
	
	Return New FixedArray(Types);
	
EndFunction

// Generates an array of metadata that does not require link matching when loading.
//
// Returns:
//	FixedArray of MetadataObject - array of metadata.
//
Function GetSharedDataTypesThatDoNotRequireLinkMappingWhenLoading() Export
	
	Types = New Array();
	
	// Library Event Handlers
	CTLSubsystemsIntegration.OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport(Types);
	
	// Redefined procedure
	ExportImportDataOverridable.OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport(Types);
	
	Return New FixedArray(Types);
	
EndFunction

// Generates an array of metadata that is excluded from loading/unloading.
//
// Returns:
//	FixedArray of MetadataObject - array of metadata.
//
Function GetTypesExcludedFromUploadUpload() Export
	
	Types = TypesFromTypeDescriptions(
		DescriptionsOfTypesExcludedFromUploadingDownloads());

	Return New FixedArray(Types);
	
EndFunction

// Returns:
//	FixedArray of MetadataObject, FixedStructure: 
//		* Type - MetadataObject
//		* Action - String - 
//		To add a structure, it is recommended to use Data offloading.Add a type of exclusionary upload to the upload
//
Function DescriptionsOfTypesExcludedFromUploadingDownloads() Export 
	
	Types = New Array();
	
	SafeModeManagerInternalSaaS.OnFillTypesExcludedFromExportImport(Types);
	
	If Common.SubsystemExists("CloudTechnology.InformationCenter") Then
		ModuleInformationCenterInternal = Common.CommonModule("InformationCenterInternal");
		ModuleInformationCenterInternal.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		ModuleDataExchangeSaaS.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.ExtensionsSaaS") Then
		ModuleExtensionsSaaS = Common.CommonModule("ExtensionsSaaS");
		ModuleExtensionsSaaS.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If SaaSOperations.DataSeparationEnabled()
		And Common.SubsystemExists("CloudTechnology.QualityControlCenter") Then
		ModuleQCCIncidentsServer = Common.CommonModule("QCCIncidentsServer");
		ModuleQCCIncidentsServer.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.TariffsManagement") Then
		ModuleTariffication = Common.CommonModule("Tariffication");
		ModuleTariffication.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.CheckingAndCorrectingData") Then
		ModuleCheckingAndCorrectingData = Common.CommonModule("CheckingAndCorrectingData");
		ModuleCheckingAndCorrectingData.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.ApplicationsMigration") Then
		ApplicationMigrationModule = Common.CommonModule("ApplicationsMigration");
		ApplicationMigrationModule.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.JobsQueueExternalInterface") Then
		TaskQueueModuleExternalInterface = Common.CommonModule("JobsQueueExternalInterface");
		TaskQueueModuleExternalInterface.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.DataAreasFiles") Then
		ModuleSuppliedSubscriberData = Common.CommonModule("DataAreasFiles");
		ModuleSuppliedSubscriberData.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.DataAreasObjectsIntegration") Then
		ModuleIntegrationOfDataDomainObjects = Common.CommonModule("DataAreasObjectsIntegration");
		ModuleIntegrationOfDataDomainObjects.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.SuppliedData") Then
		ModuleSuppliedData = Common.CommonModule("SuppliedData");
		ModuleSuppliedData.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.SummaryApplications") Then
		ModuleSummaryApplications = Common.CommonModule("SummaryApplications");
		ModuleSummaryApplications.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.AppTypes") Then
		ModuleAppTypesInternal = Common.CommonModule("AppTypesInternal");
		ModuleAppTypesInternal.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.PersonalArea") Then
		PersonalAreaOfServiceModule = Common.CommonModule("PersonalAreaOfService");
		PersonalAreaOfServiceModule.OnFillTypesExcludedFromExportImport(Types);
	EndIf;
	
	// Library Event Handlers
	CTLSubsystemsIntegration.OnFillTypesExcludedFromExportImport(Types);
	
	// Redefined procedure
	ExportImportDataOverridable.OnFillTypesExcludedFromExportImport(Types);
	
	Return New FixedArray(Types);
	
EndFunction

// Converts an array of descriptions of types excluded from loading/unloading into an array of types
//
// Parameters:
//  TypeDescriptions - Array of MetadataObject, FixedStructure: 
//		* Type - MetadataObject
//		* Action - String
//		
// Returns:
//	Array of Type
//
Function TypesFromTypeDescriptions(TypeDescriptions) Export
	
	Types = New Array; // Array of Type
	
	TypeFixedStructure = Type("FixedStructure");
	StructureType = Type("Structure");
	
	For Each LongDesc In TypeDescriptions Do
		DescriptionType = TypeOf(LongDesc);
		If DescriptionType = TypeFixedStructure Or DescriptionType = StructureType Then
			Type = LongDesc.Type;
		Else
			Type = LongDesc;
		EndIf;
		
		Types.Add(Type);
	EndDo;
		
	Return Types;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Initializing events when loading data


// Returns the dependencies of the types when you replace links.
//
// Returns:
//  FixedMap of KeyAndValue:
//	 * Key - String - the full name of the dependent object metadata,
//	 * Value - Array of String - full names of the metadata objects that this metadata object depends on.
//
Function GetTypeDependenciesWhenReplacingReferences() Export
	
	// Integrated handlers
	Return ExportImportSharedData.TypeDependenciesWhenReplacingReferences();
	
EndFunction

// Performs a series of actions after loading data
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - 
//    the container manager used in the data loading process. For more information, see the comment
//    on the software interface for processing the unloading of the data of the Manager container.
//  Serialization - XDTODataObject - XDTO object {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1} InfoBaseUser,
//    serialization of the user of the information base.
//  IBUser - InfoBaseUser -  deserialized from the discharge,
//  Cancel - Boolean -  if you set the value of this parameter inside this procedure to
//    False, the user's loading of the information database will be skipped.
//
Procedure PerformActionsWhenLoadingUserOfInformationBase(Container, Serialization, IBUser, Cancel) Export
	
	// Library Event Handlers
	CTLSubsystemsIntegration.OnImportInfobaseUser(Container, Serialization, IBUser, Cancel);
	
	// Redefined procedure
	ExportImportDataOverridable.OnImportInfobaseUser(Container, Serialization, IBUser, Cancel);
	
EndProcedure

// Performs a number of actions after the user loads the database.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - 
//    the container manager used in the data loading process. For more information, see the comment
//    on the software interface for processing the unloading of the data of the Manager container.
//  Serialization - XDTODataObject - XDTO object {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1} InfoBaseUser,
//    serialization of the user of the information base.
//  IBUser - InfoBaseUser - deserialized from an upload.
//
Procedure PerformActionsAfterLoadingUserInformationBase(Container, Serialization, IBUser) Export
	
	// Library Event Handlers
	CTLSubsystemsIntegration.AfterImportInfobaseUser(Container, Serialization, IBUser);
	
	// Redefined procedure
	ExportImportDataOverridable.AfterImportInfobaseUser(Container, Serialization, IBUser);
	
EndProcedure

// Performs a number of actions after loading the database users.
//
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - 
//    the container manager used in the data loading process. For more information, see the comment
//    on the software interface for processing the unloading of the data of the Manager container.
//
Procedure PerformActionsAfterLoadingInformationBaseUsers(Container) Export
	
	// Library Event Handlers
	CTLSubsystemsIntegration.AfterImportInfobaseUsers(Container);
	
	// Redefined procedure
	ExportImportDataOverridable.AfterImportInfobaseUsers(Container);
	
EndProcedure

#EndRegion

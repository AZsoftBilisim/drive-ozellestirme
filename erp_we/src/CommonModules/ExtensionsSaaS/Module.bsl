
#Region Public

// Outdated, there are no calls in the configuration. It is recommended to abandon the use in the application code.
// Returns the supplied extension corresponding to the extension being used.
//
// Parameters:
//	UsedExtensionID - UUID - the ID of the extension.
//
// Returns:
//	CatalogRef.SuppliedExtensions - link to the supplied extension
//
Function SuppliedExtension(UsedExtensionID) Export
	
	Return Undefined;
	
EndFunction

// Fills the array with a list of names of metadata objects whose data may contain references to various metadata objects,
// but these references should not be taken into account in the application's business logic.
//
// Parameters:
//  Array - Array of String - for example, " data Register.Versions of objects".
//
Procedure OnAddReferenceSearchExceptions(Array) Export
	
	Array.Add(Metadata.InformationRegisters.UseSuppliedExtensionsInDataAreas.FullName());
	
EndProcedure

// See SaaSOperationsOverridable.OnFillIIBParametersTable
// 
// Parameters:
//	ParametersTable - See SaaSOperations.IBParameters
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "UseExtensionCatalogInSaaS");
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "UseSecurityProfilesForExtensions");
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "IndependentUsageOfExtensionsSaaS");
	
EndProcedure

// See SaaSOperationsOverridable.OnSetIBParametersValues.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure OnSetIBParametersValues(Val ParameterValues) Export
EndProcedure

// See MessageInterfacesSaaSOverridable.FillInReceivedMessageHandlers.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
// 	HandlersArray - Array of CommonModule - handlers.
//
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
EndProcedure

// See MessageInterfacesSaaSOverridable.FillInHandlersForSendingMessages.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
// 	HandlersArray - Array of CommonModule - handlers.
//
Procedure RecordingOutgoingMessageInterfaces(HandlersArray) Export	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export	
EndProcedure

// See SuppliedDataOverridable.GetHandlersForSuppliedData.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
// 	Handlers - See SuppliedDataOverridable.GetHandlersForSuppliedData.Handlers
//
Procedure OnDefineSuppliedDataHandlers(Handlers) Export
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.UseSuppliedExtensionsInDataAreas);
	Types.Add(Metadata.InformationRegisters.SuppliedExtensionInstallationQueueInDataArea);
	Types.Add(Metadata.InformationRegisters.ExtensionsForNotificationsQueue);
	Types.Add(Metadata.InformationRegisters.SuppliedExtensionsToUpdateQueueInDataAreas);
	Types.Add(Metadata.InformationRegisters.ExtensionsThatChangeDataStructureExpectedByUser);
	Types.Add(Metadata.InformationRegisters.ExtensionsDirectorySettingsInDataAreas);
	
EndProcedure

#EndRegion

#Region Internal

// Returns information about extensions registered in the usage register of the supplied extensions of the Free data
// for the current data area.
//
// Returns:
//	Undefined, ValueTable - Fields:
//		* SuppliedExtension - CatalogRef.SuppliedExtensions
//		* ExtensionToUse - UUID
//		* Installation - UUID
//		* Disabled - Boolean - See Catalog.SuppliedExtensions
//		* TurnedOffReason - EnumRef.ReasonsForDisablingExtensionsSaaS - See Catalog.SuppliedExtensions
//		* Description - String - See Catalog.SuppliedExtensions
//		* VersionID - UUID - See InformationRegister.UseSuppliedExtensionsInDataAreas.
//
Function CurDataAreaExtensions() Export

	Return Undefined;

EndFunction // Extensions of the current Plastidane()

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export
EndProcedure

// There are installed extensions that change the data structure.
// 
// Returns:
// 	Boolean - The fact that there are installed extensions that change the data structure
Function ThereAreInstalledExtensionsModifyingDataStructure() Export 
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	ThereAreExtensionsInstalled = False;
	
	ScopeExtensions = ConfigurationExtensions.Get();
	For Each AreaExpansion In ScopeExtensions Do
		
		If DataSeparationEnabled 
			And AreaExpansion.Scope <> ConfigurationExtensionScope.DataSeparation Then
			Continue;
		EndIf;
		
		ThereAreExtensionsInstalled = Max(
			ThereAreExtensionsInstalled, 
			AreaExpansion.ModifiesDataStructure());
		
	EndDo;
	
	Return ThereAreExtensionsInstalled;
	
EndFunction

Procedure ScheduleExtensionUpdatesInAreas(CompleteSessions = False, 
	ScheduledStartTime = Undefined, User = Undefined) Export
	
	Return;
	
EndProcedure

#EndRegion
#Region Public

// Checks whether the object passed in metadata object ObjectDataSource.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a configuration.
//
Function IsConfigurationMetadataObject(Val MetadataObject) Export
	
	Return TypeOf(MetadataObject) = Type("ConfigurationMetadataObject");
	
EndFunction

// Checks whether the passed metadata object is a subsystem.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a subsystem.
//
Function IsSubsystem(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllSubsystems.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a session parameter.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a session parameter.
//
Function IsSessionParameter(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllSessionParameters.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a shared property.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a common prop.
//
Function IsCommonAttribute(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllGeneralDetails.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is constant.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a constant.
//
Function IsConstant(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllConstants.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a reference.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a reference.
//
Function IsCatalog(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllCatalogs.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a document.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a document.
//
Function IsDocument(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllDocuments.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is an enumeration.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is an enumeration.
//
Function IsEnum(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllEnumerations.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a business process.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a business process.
//
Function IsBusinessProcess(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllBusinessProcesses.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a task.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a task.
//
Function IsTask(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllTasks.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a chart of accounts.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a chart of accounts.
//
Function IsChartOfAccounts(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllAccountPlans.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is an exchange plan.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is an exchange plan.
//
Function IsExchangePlan(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllExchangePlans.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a plan for calculation types.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a plan of calculation types.
//
Function IsChartOfCalculationTypes(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllPlansTypesOfCalculation.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a plan for calculation types.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a plan of types of characteristics.
//
Function IsChartOfCharacteristicTypes(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllChartsOfCharacteristicTypes.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a reference object.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a reference.
//
Function IsRefData(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllReferenceData.Get(MetadataObject) = True;
		
EndFunction

// Checks whether the passed metadata object is a reference object with support for predefined elements.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object supports predefined elements.
//
Function IsRefDataSupportingPredefinedItems(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllReferenceDataSupportingPredefinedElements.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a data register.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a register of information.
//
Function IsInformationRegister(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllInformationRegisters.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is an accumulation register.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is an accumulation register.
//
Function IsAccumulationRegister(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllAccumulationRegisters.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is an accounting register.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is an accounting register.
//
Function IsAccountingRegister(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllAccountingRegisters.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a calculation register.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a calculation register.
//
Function IsCalculationRegister(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllCalculationRegisters.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is recalculated.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a recalculation.
//
Function IsRecalculationRecordSet(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllRecordSetsAreRecalculated.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a sequence.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a sequence.
//
Function IsSequenceRecordSet(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllSetsOfSequenceRecords.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a set of records.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a set of records.
//
Function IsRecordSet(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllRecordSets.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is an independent set of records.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is an independent set of records.
//
Function IsIndependentRecordSet(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllIndependentRecordSets.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a set of records that supports totals.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object supports totals.
//
Function IsRecordSetSupportingTotals(Val MetadataObject) Export
	
	If IsInformationRegister(MetadataObject) Then
		
		If TypeOf(MetadataObject) = Type("String") Then
			MetadataObject = Metadata.FindByFullName(MetadataObject);
		EndIf;
		
		Return (MetadataObject.EnableTotalsSliceFirst Or MetadataObject.EnableTotalsSliceLast);
		
	ElsIf IsAccumulationRegister(MetadataObject) Then
		
		Return True;
		
	ElsIf IsAccountingRegister(MetadataObject) Then
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

// Checks whether the passed metadata object is a document log.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a document log.
//
Function IsDocumentJournal(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllDocumentLogs.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is a routine task.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is a routine task.
//
Function IsScheduledJob(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllRoutineTasks.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is an external data source.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is an external data source.
//
Function ThisIsExternalDataSource(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllExternalDataSources.Get(MetadataObject) = True;
	
EndFunction

// Checks whether the passed metadata object is an integration service.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is an integration service.
//
Function ThisIsIntegrationService(Val MetadataObject) Export
	
	Return CommonCTLCached.ConfigurationModel().AllIntegrationServices.Get(MetadataObject) = True;
	
EndFunction

// Returns: whether it is a primitive type or not.
//
// Parameters:
//  TypeToCheck - Type - the type being checked.
//
// Returns:
//   Boolean - True if the type is primitive.
//
Function IsPrimitiveType(Val TypeToCheck) Export
	
	Return CommonCTLCached.DescriptionOfPrimitiveTypes().ContainsType(TypeToCheck);
	
EndFunction

// Returns: whether it is a reference type or not.
//
// Parameters:
//  TypeToCheck - Type - the type being checked.
//
// Returns:
//   Boolean - True if the type is primitive.
//
Function IsReferenceType(Val TypeToCheck) Export
	
	Return CommonCTLCached.RefTypesDetails().ContainsType(TypeToCheck);
	
EndFunction

// Checks that the type contains a set of reference types.
//
// Parameters:
//  TypeDescription - TypeDescription - a set of reference types.
//
// Returns:
//   Boolean - True if the type contains a set of reference types.
//
Function IsRefsTypesSet(Val TypeDescription) Export
	
	If TypeDescription.Types().Count() < 2 Then
		Return False;
	EndIf;
	
	TypesDetailsSerialization = XDTOSerializer.WriteXDTO(TypeDescription);
	
	If TypesDetailsSerialization.TypeSet.Count() > 0 Then
		
		ContainsRefsSets = False;
		
		For Each TypesSet In TypesDetailsSerialization.TypeSet Do
			
			If TypesSet.NamespaceURI = "http://v8.1c.ru/8.1/data/enterprise/current-config" Then
				
				If TypesSet.LocalName = "AnyRef"
						Or TypesSet.LocalName = "CatalogRef"
						Or TypesSet.LocalName = "DocumentRef"
						Or TypesSet.LocalName = "BusinessProcessRef"
						Or TypesSet.LocalName = "TaskRef"
						Or TypesSet.LocalName = "ChartOfAccountsRef"
						Or TypesSet.LocalName = "ExchangePlanRef"
						Or TypesSet.LocalName = "ChartOfCharacteristicTypesRef"
						Or TypesSet.LocalName = "ChartOfCalculationTypesRef" Then
					
					ContainsRefsSets = True;
					Break;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		Return ContainsRefsSets;
		
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns a metadata object by reference type
//
// Parameters:
//  RefType - Type - link type.
//
// Returns: 
//	MetadataObject - metadata object
//
Function MetadataObjectByRefType(Val RefType) Export
	
	BusinessProcess = CommonCTLCached.BusinessProcessesRoutePointsRefs().Get(RefType);
	If BusinessProcess = Undefined Then
		Ref = New(RefType);
		RefMetadata = Ref.Metadata();
	Else
		RefMetadata = Metadata.BusinessProcesses[BusinessProcess];
	EndIf;
	
	Return RefMetadata;
	
EndFunction

// Checks whether the metadata object is included in the separator in the mode that enables data separation.
//
// Parameters:
//  MetadataObject - MetadataObject - metadata object being checked,
//  SeparatorName - String - name of the shared separator item.
//
// Returns:
//   Boolean - True if the object is split.
//
Function IsSeparatedMetadataObject(Val MetadataObject, Val SeparatorName) Export
	
	Properties = ConfigurationModelObjectProperties(CommonCTLCached.ConfigurationDataModelDetails(), MetadataObject);
	Return Properties.DataSeparation.Property(SeparatorName);
	
EndFunction

// Returns a list of objects referenced in the source metadata object.
// Reference sets and storage of references in the value store are ignored.
//
// Parameters:
//  MetadataObject - MetadataObject - the source metadata object,
//
// Returns: 
//	Array of String - array of full names of metadata objects.
//
Function MetadataObjectDependencies(Val MetadataObject) Export
	
	Properties = ConfigurationModelObjectProperties(CommonCTLCached.ConfigurationDataModelDetails(), MetadataObject);
	Return Properties.Dependencies;
	
EndFunction

// Checks the availability of metadata objects based on the current values of functional options.
//
// Parameters:
//  MetadataObject - MetadataObject - the metadata object to check.
//
// Returns:
//   Boolean - True if the object is available by the current functional options.
//
Function MetadataObjectAvailableByFunctionalOptions(Val MetadataObject) Export
	
	Properties = ConfigurationModelObjectProperties(CommonCTLCached.ConfigurationDataModelDetails(), MetadataObject);
	
	If Properties.FunctionalOptions.Count() = 0 Then
		Return True;
	Else
		Result = False;
		For Each FunctionalOption In Properties.FunctionalOptions Do
			If GetFunctionalOption(FunctionalOption) Then
				Result = True;
			EndIf;
		EndDo;
		Return Result;
	EndIf;
	
EndFunction

// Returns a representation of the metadata object.
//
// Parameters:
//  MetadataObject - MetadataObject - metadata object.
//
// Returns: 
//	String - representation of the metadata object.
//
Function MetadataObjectPresentation(Val MetadataObject) Export
	
	Properties = ConfigurationModelObjectProperties(CommonCTLCached.ConfigurationDataModelDetails(), MetadataObject);
	Return Properties.Presentation;
	
EndFunction

// Returns a list (with classification) of rights allowed for the metadata object.
//
// Parameters:
//  MetadataObject - MetadataObject - metadata object.
//
// Returns: 
//	ValueTable - table of acceptable rights:
//	 * Name - String - name of the type of right that can be used for the Access rights function(),
//	 * Interactive - Boolean - flag that the right restricts the ability to perform interactive operations,
//	 * Read - Boolean - flag that the permission grants or implies
//		the ability to read data from the specified metadata object.
//	 * Update - Boolean - flag that the right grants or implies
//		the ability to change the data of the specified metadata object.
//	 * InfobaseAdministration - Boolean - flag that the right
//		provides or assumes the possibility of administration (global for the information base).
//	 * DataAreaAdministration - Boolean - flag indicating that the right provides
//		or assumes the ability to administer (global for
//		the current data area).
//
Function AllowedRightsForMetadataObject(Val MetadataObject) Export
	
	RightsKinds = New ValueTable();
	RightsKinds.Columns.Add("Name", New TypeDescription("String"));
	RightsKinds.Columns.Add("Interactive", New TypeDescription("Boolean"));
	RightsKinds.Columns.Add("Read", New TypeDescription("Boolean"));
	RightsKinds.Columns.Add("Update", New TypeDescription("Boolean"));
	RightsKinds.Columns.Add("InfobaseAdministration", New TypeDescription("Boolean"));
	RightsKinds.Columns.Add("DataAreaAdministration", New TypeDescription("Boolean"));
	
	If IsConfigurationMetadataObject(MetadataObject) Then
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Administration";
		RightKind.InfobaseAdministration = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "DataAdministration";
		RightKind.DataAreaAdministration = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "UpdateDataBaseConfiguration";
		RightKind.InfobaseAdministration = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "ExclusiveMode";
		RightKind.DataAreaAdministration = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "ActiveUsers";
		RightKind.DataAreaAdministration = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "EventLog";
		RightKind.DataAreaAdministration = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "ThinClient";
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "WebClient";
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "ThickClient";
		RightKind.InfobaseAdministration = True;
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "ExternalConnection";
		RightKind.InfobaseAdministration = True;
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Automation";
		RightKind.InfobaseAdministration = True;
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "AllFunctionsMode";
		RightKind.InfobaseAdministration = True;
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "SaveUserData";
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "InteractiveOpenExtDataProcessors";
		RightKind.InfobaseAdministration = True;
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "InteractiveOpenExtReports";
		RightKind.InfobaseAdministration = True;
		RightKind.Interactive = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Output";
		RightKind.Interactive = True;
		
	ElsIf IsSessionParameter(MetadataObject) Then
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Receive";
		RightKind.Read = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Set";
		RightKind.Update = True;
		
	ElsIf IsCommonAttribute(MetadataObject) Then
		
		RightKind = RightsKinds.Add();
		RightKind = "View";
		RightKind.Interactive = True;
		RightKind.Read = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Edit";
		RightKind.Interactive = True;
		RightKind.Update = True;
		
	ElsIf IsConstant(MetadataObject) Then
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Read";
		RightKind.Read = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Update";
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "View";
		RightKind.Interactive = True;
		RightKind.Read = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Edit";
		RightKind.Interactive = True;
		RightKind.Update = True;
		
	ElsIf IsRefData(MetadataObject) Then
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Read";
		RightKind.Read = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Create";
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Update";
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Delete";
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "View";
		RightKind.Interactive = True;
		RightKind.Read = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "InteractiveInsert";
		RightKind.Interactive = True;
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Edit";
		RightKind.Interactive = True;
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "InteractiveDelete";
		RightKind.Interactive = True;
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "InteractiveDeletionMark";
		RightKind.Interactive = True;
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "InteractiveClearDeletionMark";
		RightKind.Interactive = True;
		RightKind.Update = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "InteractiveDeleteMarked";
		RightKind.Interactive = True;
		RightKind.Update = True;
		
		If IsDocument(MetadataObject) Then
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "Posting";
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "UndoPosting";
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractivePosting";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractivePostingRegular";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveUndoPosting";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveChangeOfPosted";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
		EndIf;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "InputByString";
		RightKind.Interactive = True;
		RightKind.Read = True;
		
		If IsBusinessProcess(MetadataObject) Then
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveActivate";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "Start";
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveStart";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
		EndIf;
		
		If IsTask(MetadataObject) Then
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveActivate";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "Perform";
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveExecute";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
		EndIf;
		
		If IsRefDataSupportingPredefinedItems(MetadataObject) Then
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveDeletePredefinedData";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveSetDeletionMarkPredefinedData";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveClearDeletionMarkPredefinedData";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "InteractiveDeleteMarkedPredefinedData";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
		EndIf;
		
	ElsIf IsRecordSet(MetadataObject) Then
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Read";
		RightKind.Read = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Update";
		RightKind.Update = True;
		
		If Not IsSequenceRecordSet(MetadataObject) And Not IsRecalculationRecordSet(MetadataObject) Then
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "View";
			RightKind.Interactive = True;
			RightKind.Read = True;
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "Edit";
			RightKind.Interactive = True;
			RightKind.Update = True;
			
		EndIf;
		
		If IsRecordSetSupportingTotals(MetadataObject) Then
			
			RightKind = RightsKinds.Add();
			RightKind.Name = "TotalsControl";
			RightKind.DataAreaAdministration = True;
			
		EndIf;
		
	ElsIf IsDocumentJournal(MetadataObject) Then
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "Read";
		RightKind.Read = True;
		
		RightKind = RightsKinds.Add();
		RightKind.Name = "View";
		RightKind.Interactive = True;
		RightKind.Read = True;
		
	EndIf;
	
	Return RightsKinds;
	
EndFunction

// Returns an empty unique ID.
//
// Returns:
//  UUID - unique identifier.
//
Function BlankUUID() Export
	
	Return New UUID("00000000-0000-0000-0000-000000000000");
	
EndFunction

// Stops code execution for a specified time.
// It can only be used in a background task.
//
// Parameters:
//  Seconds - Number - waiting time in seconds.
//
Procedure Pause(Seconds) Export
	
	CurrentInfobaseSession1 = GetCurrentInfoBaseSession();
	BackgroundJob = CurrentInfobaseSession1.GetBackgroundJob();
	
	If BackgroundJob = Undefined Then
		WriteLogEvent(
			NStr("vi = 'Lỗi thực hiện';
				|ru = 'Ошибка выполнения';
				|en = 'Runtime error'; fa = 'خطای زمان اجرا';
				|it = 'Errore nell''esecuzione';
				|pl = 'Błąd wykonania';
				|tr = 'Uygulama hatası'"), 
			EventLogLevel.Error, 
			, 
			, 
			NStr("vi = 'ОбщегоНазначенияБТС.Пауза() chỉ cho phép sử dụng trong nhiệm vụ nền.';
				|ru = 'ОбщегоНазначенияБТС.Пауза() разрешается использовать только в фоновом задании.';
				|en = 'You can use CommonCTL.Pause() only in the background job.'; fa = 'You can use CommonCTL.Pause() only in the background job.';
				|it = 'ОбщегоНазначенияБТС.Pausa() consentita solo nel processo in background';
				|pl = 'ОбщегоНазначенияБТС.Пауза() zezwolone jest użycie tylko w zadaniu w tle.';
				|tr = 'ОбщегоНазначенияБТС.Пауза() yalnızca arka plan işinde kullanılabilir.'"));
		Parameters = New Array;
		Parameters.Add(Seconds);
		BackgroundJob = BackgroundJobs.Execute("CommonCTL.Pause", Parameters);
	EndIf;
		
	BackgroundJob.WaitForExecutionCompletion(Seconds);
	
EndProcedure

// Writes an event to the technology log.
//
// Parameters:
//  Event	 - String - the name of the event to filter the records of the technological log using the settings logcfg.xml.
//  Context - Structure - Custom data to write to the process log.
//		It is recommended to put data of primitive types in values. This will increase the recording speed.
//
Procedure TechnologyLogEntry(Event, Context) Export
	
	Try
		
		Record = New JSONWriter;
		Record.SetString();
		
		Try
			
			WriteJSON(Record, Context);
			
		Except
		
			XDTOSerializer.WriteJSON(Record, Context);
			
		EndTry;
		
		Query = New Query(
		"SELECT
		|	&Event AS Event,
		|	&Context AS Context");
		
		Query.SetParameter("Event", "TJEvent." + Event);
		Query.SetParameter("Context", Record.Close());
		
		Query.Execute();
		
	Except
		
		WriteLogEvent("TechnologyLogEntry", EventLogLevel.Error,,, 
			CloudTechnology.DetailedErrorText(ErrorInfo()));
		
	EndTry;
	
EndProcedure

// Converts the date from the original time zone to the session time zone
// Parameters:
//  Date - Date - the date in the original time zone.
//  OriginalTimeZone - String - date time zone.
Function DateInSessionTimeZone(Date, OriginalTimeZone) Export
	Return ToLocalTime(ToUniversalTime(Date, OriginalTimeZone), SessionTimeZone());
EndFunction

#EndRegion

#Region Internal

// Active extensions that change the data structure.
// 
// Returns:
//  Array of ConfigurationExtension
Function ActiveExtensionsThatChangeDataStructure() Export
	
	ActiveExtensionsThatChangeDataStructure = New Array;
	
	For Each ConfigurationExtension In ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionApplied) Do	
		If ConfigurationExtension.Active
			And ConfigurationExtension.ModifiesDataStructure() Then
			ActiveExtensionsThatChangeDataStructure.Add(ConfigurationExtension)
		EndIf;
	EndDo;
	
	Return ActiveExtensionsThatChangeDataStructure;
EndFunction

// Parameters: 
//  String - String - original string.
// 
// Returns: 
//  String - only numbers from the string
Function NumbersOnly(Val String) Export
	
	ProcessedString_ = "";

	For CharacterNumber = 1 To StrLen(String) Do
		Char = Mid(String, CharacterNumber, 1);
		If Char >= "0" And Char <= "9" Then
			ProcessedString_ = ProcessedString_ + Char;
		EndIf;
	EndDo;
	
	Return ProcessedString_;
	
EndFunction

// Outdated. You should use a general-purpose Client Server.HEADINGNTTR
// Gets the header value regardless of case.
//
// Parameters: 
//  RequestResponse - HTTPRequest, HTTPResponse, HTTPServiceRequest, HTTPServiceResponse - request or response.
//  Title - String - title name.
//
// Returns:
//  String, Undefined - the value of the header.
//
Function HTTPHeader(RequestResponse, Val Title) Export
	
	Title = Lower(Title);
	For Each KeyAndValue In RequestResponse.Headers Do
		If Lower(KeyAndValue.Key) = Title Then
			Return KeyAndValue.Value;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Returns:
//  Array of String -
//
Function InteractiveApplicationNames() Export
	ApplicationNames = New Array();
	ApplicationNames.Add("1CV8");
	ApplicationNames.Add("1CV8C");
	ApplicationNames.Add("WebClient");
	ApplicationNames.Add("MobileClient");
	Return ApplicationNames;
EndFunction

// Converts an XDTO object into a structure, taking into account the nesting of properties.
// XDTO lists are converted to an array of structures as part of a structure.
//
// Parameters:
//  XDTODataObject - XDTODataObject - source object.
//
// Returns:
//  Structure - the result of the conversion.
//
Function StructureFromXDTOObject(XDTODataObject) Export
	
	Result = New Structure;
	For Each Property In XDTODataObject.Properties() Do
		Result.Insert(Property.Name, XDTOPropertyValue(XDTODataObject[Property.Name]));
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// Checks whether the configuration contains a BSP.
//
// Returns:
//   Boolean - result.
//
Function ConfigurationContainsSSL()
	
	Return (Metadata.Subsystems.Find("StandardSubsystems") <> Undefined);
	
EndFunction

// Checks whether BSP program events are supported in the current configuration.
//
// Returns:
//   Boolean - support for BTS events. 
//
Function SoftwareEventsAreSupported()
	
	If Not ConfigurationContainsSSL() Then
		Return False;
	EndIf;
	
	Try
		
		SetSafeMode(True);
		
		Execute("StandardSubsystemsCached.ProgramEventsParameters()");
		Return True;
		
	Except
		Return False;
	EndTry;
	
EndFunction

// (Deprecated) Returns the BSP program event handlers.
//
// Parameters:
//  Event - String - event name.
// Returns:
//	Array of Arbitrary - handlers.
Function GetProgramEventHandlersSSL(Val Event) Export
	
	If SoftwareEventsAreSupported() Then
		
		SetSafeMode(True);
		Return Eval("Common.ServiceEventHandlers(Event)");
		
	Else
		Return New Array();
	EndIf;
	
EndFunction

// Properties of the configuration model object
// 
// Parameters: 
//  Model - FixedArray of Structure:
//  * Value - Map of KeyAndValue:
//  		   - FixedMap of KeyAndValue:
//  			  * Key - String
//  			  * Value - See CommonCTLCached.NewObjectDescription
//  MetadataObject - MetadataObject - metadata object
// 
// Returns:  See CommonCTLCached.NewObjectDescription
//
Function ConfigurationModelObjectProperties(Val Model, Val MetadataObject) Export
	
	If TypeOf(MetadataObject) = Type("MetadataObject") Then
		Name = MetadataObject.Name;
		FullName = MetadataObject.FullName();
	Else
		FullName = MetadataObject;
		Name = StrSplit(FullName, ".").Get(1);
	EndIf;
	
	For Each ModelClass In Model Do
		Value = ModelClass.Value;
		If TypeOf(Value) = Type("Map")  Or TypeOf(Value) = Type("FixedMap") Then
			ObjectDetails = Value.Get(Name); // See CommonCTLCached.NewObjectDescription
		Else
			ObjectDetails = Undefined;
		EndIf;
		If ObjectDetails <> Undefined Then
			If FullName = ObjectDetails.FullName Then
				Return ObjectDetails;
			EndIf;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

Function XDTOPropertyValue(XDTOProperty)
	
	If TypeOf(XDTOProperty) = Type("XDTODataObject") Then
		Result = New Structure;
		For Each Property In XDTOProperty.Properties() Do
			Result.Insert(Property.Name, XDTOPropertyValue(XDTOProperty[Property.Name]));
		EndDo; 
	ElsIf TypeOf(XDTOProperty) = Type("XDTOList") Then
		Result = New Array;
		For Each Item In XDTOProperty Do
			Result.Add(XDTOPropertyValue(Item));
		EndDo; 
	Else
		Result = XDTOProperty;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion
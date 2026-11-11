
#Region Public

// Returns the types of Analytics values.
//
// Parameters:
//  BudgetFlowItemsDimension - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Article Analytics. 
//  
// Returns:
//  Map of KeyAndValue - available types of budget item analytics:
//   *Key - Type -  Type of the Analytics value.
//   *Value - String - full name of the metadata object.
//
Function AvailableTypesOfBudgetItemAnalytics(BudgetFlowItemsDimension) Export
	
	Return ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.AvailableTypesOfBudgetItemAnalytics(BudgetFlowItemsDimension);
	
EndFunction

// Returns the decryption parameters and the main action for the" special " report decryption.
//
// Parameters:
// 	Details - Number - Decryption ID
// 	DetailsDataAddress - String - Address of the temporary storage with decryption data.
//
// Returns:
// 	Structure - contains decryption parameters and the main action:
// 	 *DecryptionFields - Structure
// 	 *DecryptionFieldsParents - Structure
// 	 *DataParameters - Structure
// 	 *Filter - Structure
// 	 *MainAction - DataCompositionDetailsProcessingAction -
//
Function ReportDetailsData(Details, DetailsDataAddress) Export
	
	DetailsData = GetFromTempStorage(DetailsDataAddress);
	DetailsItem = DetailsData.Items[Details];
	MainAction = DetailsItem.MainAction; // DataCompositionDetailsProcessingAction
	
	DecryptionFields = New Structure;
	For Each Simple In DetailsItem.GetFields() Do
		DecryptionFields.Insert(Simple.Field, Simple.Value);
	EndDo;
	
	ParentDecryptionFields = New Structure;
	For Each Parent In DetailsItem.GetParents() Do
		FillInFieldsOfParentDecryptionElements(Parent, ParentDecryptionFields);
	EndDo;
	
	DataParameters = New Structure;
	ConfigurationDecryptionData = DetailsData.Settings; // DataCompositionSettings - 
	For Each Parameter In ConfigurationDecryptionData.DataParameters.Items Do
		If Not Parameter.Use Then
			Continue;
		EndIf;
		DataParameters.Insert(Parameter.Parameter, Parameter.Value);
	EndDo; 
	
	Filter = New Structure;
	For Each FilterElement In ConfigurationDecryptionData.Filter.Items Do
		If Not FilterElement.Use Or FilterElement.ComparisonType <> DataCompositionComparisonType.Equal Then
			Continue;
		EndIf;
		Field = String(FilterElement.LeftValue);
		Filter.Insert(Field, FilterElement.RightValue);
	EndDo;
	
	ReportDetailsData = New Structure;
	ReportDetailsData.Insert("DecryptionFields", DecryptionFields);
	ReportDetailsData.Insert("DecryptionFieldsParents", ParentDecryptionFields);
	ReportDetailsData.Insert("DataParameters", DataParameters);
	ReportDetailsData.Insert("Filter", Filter);
	ReportDetailsData.Insert("MainAction", MainAction);
	
	Return ReportDetailsData;
	
EndFunction

#Region ConvertingAnalyticsTypes

// Returns an array of empty links for the plan of types of characteristics of Analyticstatebudget.
//
// Returns:
// 	Array of Arbitrary - An array of empty links.
//
Function ReplacedEmptyValues() Export
	Array = New Array;
	
	Types = BudgetingServer.AllTypesOfAnalytics().Types();
	
	For Each Type In Types Do
		EmptyRef = New (Type);
		Array.Add(EmptyRef);
	EndDo; 
	
	Return Array;
EndFunction

// Bypasses the object / record of the register by the search details, and if the Replaced values are found, changes the value to the value of the Substitution.
//
// Parameters:
// 	Object - CatalogObject - object of any reference list
// 				- DocumentObject   - the object of any document
// 				- AccountingRegisterRecordAccountingRegisterName - recording of any register.
// 				- AccumulationRegisterRecordAccumulationRegisterName - recording of any register.
// 				- InformationRegisterRecordInformationRegisterName - recording of any register.
// 	SearchAttributes - String - Strings are comma-separated paths to replacement fields, for example, "Requesite1, Table part name.ReqUisitname" or "Table partname.ReqUisitname, Table part name2.ReqUisitname"
// 				- Array of String - Array of string paths to replacement fields, for example "ReqUesitname" or "Table partname.ReqUisitname"
// 	ReplacementValues - Array of Arbitrary - Array of values that the value in the field will be checked for before replacing.
// 	ReplacementValue - Arbitrary - Undefined, Any Link.
// 	ObjectModified - Boolean - Indicates whether the object has changed.
//
Procedure ReplaceValuesInObject(Object, SearchAttributes, ReplacementValues, ReplacementValue, ObjectModified = False) Export
	
	If TypeOf(SearchAttributes) = Type("String") Then
		SearchAttributes = StringFunctionsClientServer.SplitStringIntoSubstringsArray(SearchAttributes, ",",, True);
	EndIf;
	
	FieldPlacements = GetPlacementOfAnalyticsFieldsInTables(SearchAttributes);
	
	For Each KeyAndValue In FieldPlacements Do
		
		TabularSectionName = KeyAndValue.Key;
		AttributesPlacement = KeyAndValue.Value;
		
		If TabularSectionName = "" Then
			
			For Each FieldName In AttributesPlacement Do
				
				For Each ValueToReplace In ReplacementValues Do
					
					If Object[FieldName] = ValueToReplace Then
						Object[FieldName] = ReplacementValue;
						ObjectModified = True;
						Break;
					EndIf;
					
				EndDo;
				
			EndDo;
			
		Else
			
			For Each TSRow In Object[TabularSectionName] Do
				
				For Each FieldName In AttributesPlacement Do
					
					For Each ValueToReplace In ReplacementValues Do
						
						If TSRow[FieldName] = ValueToReplace Then
							TSRow[FieldName] = ReplacementValue;
							ObjectModified = True;
							Break;
						EndIf;
						
					EndDo;
					
				EndDo;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure FillInFieldsOfParentDecryptionElements(DetailsItem, ParentDecryptionFields)
	
	If TypeOf(DetailsItem) = Type("DataCompositionFieldDetailsItem") Then
		For Each Simple In DetailsItem.GetFields() Do
			ParentDecryptionFields.Insert(Simple.Field, Simple.Value);
		EndDo;
	EndIf;
	
	For Each Parent In DetailsItem.GetParents() Do
		FillInFieldsOfParentDecryptionElements(Parent, ParentDecryptionFields);
	EndDo;
	
EndProcedure

Function GetXML(Value)
	
	Record = New XMLWriter();
	Record.SetString();
	XDTOSerializer.WriteXML(Record, Value);
	Return Record.Close();
	
EndFunction

Function ApplyChangesToDataLayoutScheme(Val DataCompositionSchema, 
					Val AddressOfDataLayoutSchemaInStorage, Val AddressOfDataCompositionSettings, 
					InVault = False, UUID = Undefined) Export
	
	If ValueIsFilled(DataCompositionSchema) Then
		
		Schema = Catalogs.NonFinancialItemsOfBudgets.PredefinedDataAcquisitionScheme(DataCompositionSchema);
		
		// If the data layout scheme from the layout <> is obtained from the data layout scheme editor.
		If GetXML(Schema) <> GetXML(GetFromTempStorage(AddressOfDataLayoutSchemaInStorage)) Then
			DataCompositionSchema   = "";
			StorageOfDataCompositionSchema = New ValueStorage(GetFromTempStorage(AddressOfDataLayoutSchemaInStorage));
		EndIf;
		
		// The resulting settings can be equal to the default settings of the scheme.
		SettingsComposer = BudgetingServer.DefaultInitializedComposer(Schema);
		SettingsComposer.Refresh();
		If GetXML(SettingsComposer.GetSettings()) <> GetXML(GetFromTempStorage(AddressOfDataCompositionSettings)) Then
			StorageOfDataCompositionSettings = New ValueStorage(GetFromTempStorage(AddressOfDataCompositionSettings));
		Else
			StorageOfDataCompositionSettings = Undefined;
		EndIf;
		
	Else
		
		Schema = GetFromTempStorage(AddressOfDataLayoutSchemaInStorage);
		StorageOfDataCompositionSchema = New ValueStorage(Schema);
		
		SettingsComposer = BudgetingServer.DefaultInitializedComposer(Schema);
		SettingsComposer.Refresh();
		If GetXML(SettingsComposer.GetSettings()) <> GetXML(GetFromTempStorage(AddressOfDataCompositionSettings)) Then
			StorageOfDataCompositionSettings = New ValueStorage(GetFromTempStorage(AddressOfDataCompositionSettings));
		Else
			StorageOfDataCompositionSettings = Undefined;
		EndIf;
	EndIf;
	
	If InVault Then
		StorageOfDataCompositionSchema = PutToTempStorage(StorageOfDataCompositionSchema, UUID);
		StorageOfDataCompositionSettings = PutToTempStorage(StorageOfDataCompositionSettings, UUID);
	Else
		StorageOfDataCompositionSchema    = StorageOfDataCompositionSchema;
		StorageOfDataCompositionSettings = StorageOfDataCompositionSettings;
	EndIf;
	
	Return New Structure("DataCompositionSchema, StorageOfDataCompositionSchema, StorageOfDataCompositionSettings", 
							DataCompositionSchema, StorageOfDataCompositionSchema, StorageOfDataCompositionSettings);
	
EndFunction

// Returns the addresses of the data layout scheme in the temporary storage.
// 
// Parameters:
//  NameOfDataLayoutScheme - String - Name of the data layout scheme
//  StorageOfDataCompositionSchema - Undefined, ValueStorage - parameter for storing the value of the schema type of the data
//  StorageOfDataCompositionSettings - Undefined, ValueStorage - a parameter for storing the value of the settings address
//                                      in temporary storage.
//  UUID - UUID - unique form ID.
// 
// Returns:
//  Structure:
//   * DataCompositionSchema - String - the address of the value in the temporary storage.
//   * DataCompositionSettings - String - the address of the value in the temporary storage.
//
Function GetAddressesOfDataLayoutSchemeInTemporaryStorage(Val NameOfDataLayoutScheme, Val StorageOfDataCompositionSchema,
																Val StorageOfDataCompositionSettings, Val UUID) Export
																
	If TypeOf(StorageOfDataCompositionSchema) = Type("String") Then
		If IsBlankString(StorageOfDataCompositionSchema) Then
			StorageOfDataCompositionSchema = Undefined;
		Else
			StorageOfDataCompositionSchema = GetFromTempStorage(StorageOfDataCompositionSchema);
		EndIf;
	EndIf;
	
	If TypeOf(StorageOfDataCompositionSettings) = Type("String") Then
		If IsBlankString(StorageOfDataCompositionSettings) Then
			StorageOfDataCompositionSettings = Undefined;
		Else
			StorageOfDataCompositionSettings = GetFromTempStorage(StorageOfDataCompositionSettings);
		EndIf;
	EndIf;
	
	Addresses = New Structure("DataCompositionSchema, DataCompositionSettings");
	
	// Schema
	DataCompositionSchema = Undefined;
	If ValueIsFilled(NameOfDataLayoutScheme) Then
		DataCompositionSchema = Catalogs.NonFinancialItemsOfBudgets.PredefinedDataAcquisitionScheme(NameOfDataLayoutScheme);
	ElsIf TypeOf(StorageOfDataCompositionSchema) = Type("DataCompositionSchema") Then
		DataCompositionSchema = StorageOfDataCompositionSchema;
	ElsIf StorageOfDataCompositionSchema <> Undefined Then
		DataCompositionSchema = StorageOfDataCompositionSchema.Get();
	EndIf;
	
	If DataCompositionSchema = Undefined Then
		DataCompositionSchema = New DataCompositionSchema;
	EndIf;
	
	Addresses.DataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	
	// Settings
	Settings = Undefined;
	If TypeOf(StorageOfDataCompositionSettings) = Type("DataCompositionSettings") Then
		Settings = StorageOfDataCompositionSettings;
	ElsIf StorageOfDataCompositionSettings <> Undefined Then
		Settings = StorageOfDataCompositionSettings.Get();
	EndIf;
	
	If Settings = Undefined Then
		Settings = New DataCompositionSettings;
	EndIf;
	
	Addresses.DataCompositionSettings = PutToTempStorage(Settings, UUID);
	
	Return Addresses;
	
EndFunction

Function GetPlacementOfAnalyticsFieldsInTables(SearchAttributes)
	FieldPlacements = New Map;
	
	// We are preparing an alternate bypass of the details and the details of the tabular parts
	
	For Each FullAttributeName In SearchAttributes Do
		
		ItemNumber = StrFind(FullAttributeName, ".");
		If ItemNumber = 0 Then
			TabularSection = ""; // the object's details or the record field
			FieldName = FullAttributeName;
		Else
			TabularSection = Mid(FullAttributeName, 1, ItemNumber - 1);
			FieldName = Mid(FullAttributeName, ItemNumber + 1);
		EndIf;
		
		AttributesPlacement = FieldPlacements.Get(TabularSection);
		If AttributesPlacement = Undefined Then
			AttributesPlacement = New Array;
		EndIf;
		
		AttributesPlacement.Add(FieldName);
		
		FieldPlacements.Insert(TabularSection, AttributesPlacement);
		
	EndDo;
	
	Return FieldPlacements
EndFunction

#EndRegion
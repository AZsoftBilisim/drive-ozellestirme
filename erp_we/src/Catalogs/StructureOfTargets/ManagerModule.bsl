#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Puts the data layout schema
// and data layout settings in temporary storage and returns their addresses.
//
// Parameters:
//	GoalStructureElement - CatalogRef.StructureOfTargets, FormDataStructure - form object:
//			*Ref - CatalogRef.StructureOfTargets - 
//
// Returns:
//	Structure - structure containing addresses:
//		*DataCompositionSchema - String - address of the data layout scheme
//		*DataCompositionSettings - String - address of data layout settings.
//
Function AddressesOfDataLayoutSchemeAndSettingsInTemporaryStorage(GoalStructureElement) Export
	
	Addresses = New Structure("DataCompositionSchema, DataCompositionSettings");
	
	If TypeOf(GoalStructureElement) = Type("CatalogRef.StructureOfTargets") Then
		GoalStructureElementLink = GoalStructureElement;
	Else
		GoalStructureElementLink = GoalStructureElement.Ref;
	EndIf;
	
	TargetData = Common.ObjectAttributesValues(GoalStructureElementLink,
		"StorageOfDataCompositionSchema, StorageOfDataCompositionSettings");
	
	// We get the data layout scheme
	If ValueIsFilled(GoalStructureElement.DataCompositionSchema)
		Or TargetData.StorageOfDataCompositionSchema = Undefined
		Or TargetData.StorageOfDataCompositionSchema.Get() = Undefined Then
		
		SchemeAndSettings = DescriptionAndLayoutDiagramOfTargetDataByTemplateName(GoalStructureElementLink,
				GoalStructureElement.DataCompositionSchema);
		DataCompositionSchema = SchemeAndSettings.DataCompositionSchema;
	Else
		DataCompositionSchema = TargetData.StorageOfDataCompositionSchema.Get();
	EndIf;
	
	If DataCompositionSchema = Undefined And IsBlankString(GoalStructureElement.DataCompositionSchema) Then
		DataCompositionSchema = Catalogs.StructureOfTargets.GetTemplate("DataCompositionTemplateScheme");
	ElsIf DataCompositionSchema = Undefined
		And Not IsBlankString(GoalStructureElement.DataCompositionSchema) Then
		
		DataCompositionSchema = Catalogs.StructureOfTargets.GetTemplate(GoalStructureElement.DataCompositionSchema);
	EndIf;
	
	DisableSelectionsBasedOnFunctionalOptions(DataCompositionSchema.SettingVariants.Main.Settings);
	Addresses.DataCompositionSchema = PutToTempStorage(DataCompositionSchema, New UUID());
	
	If TargetData.StorageOfDataCompositionSettings = Undefined Then
		Settings = Undefined
	Else
		Settings = TargetData.StorageOfDataCompositionSettings.Get();
	EndIf;
	
	If ValueIsFilled(Settings) Then
		DisableSelectionsBasedOnFunctionalOptions(Settings);
		Addresses.DataCompositionSettings = PutToTempStorage(Settings, New UUID());
	EndIf;
	
	Return Addresses;
	
EndFunction

// Returns the fields-the resources available for selection by the user
//
// Parameters:
//	TargetLink - CatalogRef.StructureOfTargets - the goal to get the resource fields for.
//
// Returns:
//	ValueList - a list of resource fields available to the user (name and synonym).
//
Function AvailableAnalysisValues(TargetLink) Export
	
	SetPrivilegedMode(True);
	
	ListOfAvailableValues = New ValueList;
	
	TargetData = Common.ObjectAttributesValues(TargetLink,
		"DataCompositionSchema, StorageOfDataCompositionSchema, StorageOfDataCompositionSettings");
	
	If ValueIsFilled(TargetData.DataCompositionSchema)
		Or TargetData.StorageOfDataCompositionSchema.Get() = Undefined Then
		SchemeAndSettings = DescriptionAndLayoutDiagramOfTargetDataByTemplateName(TargetLink, TargetData.DataCompositionSchema);
		DataCompositionSchema = SchemeAndSettings.DataCompositionSchema;
	Else
		DataCompositionSchema = TargetData.StorageOfDataCompositionSchema.Get();
	EndIf;
	
	Settings = TargetData.StorageOfDataCompositionSettings.Get();
	
	DCSAddress = PutToTempStorage(DataCompositionSchema, New UUID());
	AvailableSettingsSource = New DataCompositionAvailableSettingsSource(DCSAddress);
	
	SettingsComposer = New DataCompositionSettingsComposer;
	
	SettingsComposer.Initialize(AvailableSettingsSource);
	If Not Settings = Undefined Then
		SettingsComposer.LoadSettings(Settings);
	Else
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	
	AvailableFields = SettingsComposer.Settings.SelectionAvailableFields.Items;
	
	ServiceFields = ServiceFieldsAnalysisValues();
	
	For Each AvailableField In AvailableFields Do 
		If Not AvailableField.Resource
			Or Not ServiceFields.Find(String(AvailableField.Field)) = Undefined Then
			Continue;
		EndIf;
		
		ListOfAvailableValues.Add(AvailableField.Field, AvailableField.Title);
		
	EndDo;
	
	SetPrivilegedMode(False);
	
	Return ListOfAvailableValues;
	
EndFunction

// Returns the dimension fields that are available for the user to select
//
// Parameters:
//	TargetLink - CatalogRef.StructureOfTargets - the goal for which you want to get the dimension fields.
//
// Returns:
//	ValueList - a list of measurement fields available to the user (name and synonym).
//
Function AvailableAnalysisObjects(TargetLink) Export 
	
	SetPrivilegedMode(True);
	
	ListOfAvailableObjects = New ValueList;
	
	TargetData = Common.ObjectAttributesValues(TargetLink,
		"DataCompositionSchema, StorageOfDataCompositionSchema, StorageOfDataCompositionSettings");
	
	If ValueIsFilled(TargetData.DataCompositionSchema)
		Or TargetData.StorageOfDataCompositionSchema.Get() = Undefined Then
		
		SchemeAndSettings = DescriptionAndLayoutDiagramOfTargetDataByTemplateName(TargetLink,
				TargetData.DataCompositionSchema);
		DataCompositionSchema = SchemeAndSettings.DataCompositionSchema;
	Else
		DataCompositionSchema = TargetData.StorageOfDataCompositionSchema.Get();
	EndIf;
	
	Settings = TargetData.StorageOfDataCompositionSettings.Get();
	
	DCSAddress = PutToTempStorage(DataCompositionSchema, New UUID());
	AvailableSettingsSource = New DataCompositionAvailableSettingsSource(DCSAddress);
	
	SettingsComposer = New DataCompositionSettingsComposer;
	
	SettingsComposer.Initialize(AvailableSettingsSource);
	If Not Settings = Undefined Then
		SettingsComposer.LoadSettings(Settings);
	Else
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	
	AvailableFields = SettingsComposer.Settings.GroupAvailableFields.Items;
	
	ServiceFields = ServiceFieldsOfAnalysisObject();
	
	For Each AvailableField In AvailableFields Do 
		If Not ServiceFields.Find(String(AvailableField.Field)) = Undefined Then
			Continue;
		EndIf;
		
		ListOfAvailableObjects.Add(AvailableField.Field, AvailableField.Title);
		
	EndDo;
	
	SetPrivilegedMode(False);
	
	Return ListOfAvailableObjects;
	
EndFunction

// The function returns a structure with a synonym and data layout scheme by the layout name.
//
// Parameters:
//	TargetLink - CatalogRef.StructureOfTargets - the purpose for which you want to obtain the schema
//	TemplateName - String, Undefined - name of the resulting layout of the data layout scheme.
//
// Returns:
//	Structure - structure with properties:
//		*LongDesc - String - synonym for the resulting layout.
//		*DataCompositionSchema - DataCompositionSchema, Undefined - the found data layout scheme.
//		*DataCompositionSettings - DataCompositionSettings, Undefined - found data layout settings.
//
Function DescriptionAndLayoutDiagramOfTargetDataByTemplateName(TargetLink, TemplateName = Undefined) Export
	
	ReturnValue = New Structure;
	ReturnValue.Insert("LongDesc", "");
	ReturnValue.Insert("DataCompositionSchema", Undefined);
	ReturnValue.Insert("DataCompositionSettings", Undefined);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	StructureOfTargets.StorageOfDataCompositionSchema AS StorageOfDataCompositionSchema,
	|	StructureOfTargets.StorageOfDataCompositionSettings AS StorageOfDataCompositionSettings 
	|FROM
	|	Catalog.StructureOfTargets AS StructureOfTargets
	|WHERE
	|	StructureOfTargets.Ref = &TargetLink";
	
	Query.SetParameter("TargetLink", TargetLink);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Not ValueIsFilled(TemplateName) Then
		
		ReturnValue.LongDesc = TemplateName;
		If Selection.Next() Then
			StorageOfDataCompositionSchema = Selection.StorageOfDataCompositionSchema; // ValueStorage
			StorageOfDataCompositionSettings = Selection.StorageOfDataCompositionSettings; // ValueStorage
			ReturnValue.DataCompositionSchema = StorageOfDataCompositionSchema.Get();
			ReturnValue.DataCompositionSettings = StorageOfDataCompositionSettings.Get();
		EndIf;
		
	Else
		
		Template = Metadata.FindByType(TypeOf(TargetLink)).Templates.Find(TemplateName);
		If Not Template = Undefined Then
			ReturnValue.LongDesc = Template.Synonym;
			ReturnValue.DataCompositionSchema = Catalogs.StructureOfTargets.GetTemplate(TemplateName);
			If Selection.Next() Then
				StorageOfDataCompositionSettings = Selection.StorageOfDataCompositionSettings; // ValueStorage
				ReturnValue.DataCompositionSettings = StorageOfDataCompositionSettings.Get();
			EndIf;
		EndIf;
	EndIf;
	
	Return ReturnValue;
	
EndFunction

// Returns the default user settings for targets 
//
// Parameters:
//	TargetLink - CatalogRef.StructureOfTargets - the purpose for which you want to configure.
//
// Returns:
//	DataCompositionUserSettings - default user settings.
//
Function DefaultUserSettings_(TargetLink) Export
	
	SettingsComposer = New DataCompositionSettingsComposer;
	
	TargetData = Common.ObjectAttributesValues(TargetLink,
		"DataCompositionSchema, StorageOfDataCompositionSchema, StorageOfDataCompositionSettings");
	
	// We get the data layout scheme
	If ValueIsFilled(TargetData.DataCompositionSchema)
		Or TargetData.StorageOfDataCompositionSchema.Get() = Undefined Then
		
		SchemeAndSettings = Catalogs.StructureOfTargets.DescriptionAndLayoutDiagramOfTargetDataByTemplateName(
			TargetLink,
			TargetData.DataCompositionSchema);
		DataCompositionSchema = SchemeAndSettings.DataCompositionSchema;
	Else
		DataCompositionSchema = TargetData.StorageOfDataCompositionSchema.Get();
	EndIf;
	
	Settings = TargetData.StorageOfDataCompositionSettings.Get();
	
	DCSAddress = PutToTempStorage(DataCompositionSchema, New UUID());
	AvailableSettingsSource = New DataCompositionAvailableSettingsSource(DCSAddress);
		
	SettingsComposer.Initialize(AvailableSettingsSource);
	If Not Settings = Undefined Then
		SettingsComposer.LoadSettings(Settings);
	Else
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	
	// Fill in the required parameter of the currency calculation for the SKD where it is and is not filled in
	CalculationCurrencyParameter = DataCompositionClientServer.GetParameter(
		SettingsComposer.UserSettings, "SettlementCurrency");
	If Not CalculationCurrencyParameter = Undefined
		And CalculationCurrencyParameter.Value = Catalogs.Currencies.EmptyRef() Then
		
		DataCompositionClientServer.SetParameter(SettingsComposer.UserSettings,
				"SettlementCurrency",
				TargetValueMonitoring.GetDefaultCurrency(),
				True);
	EndIf;
	
	Return SettingsComposer.UserSettings;
	
EndFunction

// Returns service fields-resources that are not available for the user to select
//
// Returns:
//	Array of String - array of service resource fields.
//
Function ServiceFieldsAnalysisValues() Export
	
	ServiceFields = New Array;
	
	ServiceFields.Add("TargetValue_");
	ServiceFields.Add("MaximumTargetRange");
	ServiceFields.Add("MinimumTargetRange");
	ServiceFields.Add("NegativeBorderVariance");
	ServiceFields.Add("PositiveBorderVariance");
	ServiceFields.Add("AdjustedNegativeBorderVariance");
	ServiceFields.Add("AdjustedPositiveBorderVariance");
	
	Return ServiceFields;
	
EndFunction

// Returns service fields-dimensions that are not available for user selection
//
// Returns:
//	Array of String - array of service fields-dimensions.
//
Function ServiceFieldsOfAnalysisObject() Export
	
	ServiceFields = New Array;
	
	ServiceFields.Add("KindOfVarianceFromTargetValue");
	ServiceFields.Add("TargetValueKind");
	ServiceFields.Add("DateOfTargetValues");
	ServiceFields.Add("Period");
	ServiceFields.Add("SystemFields");
	ServiceFields.Add("DataParameters");
	
	// Period fields are not objects of analysis
	ServiceFields.Add("DayPeriod");
	ServiceFields.Add("WeekPeriod");
	ServiceFields.Add("TenDaysPeriod");
	ServiceFields.Add("MonthPeriod");
	ServiceFields.Add("QuarterPeriod");
	ServiceFields.Add("HalfYearPeriod");
	ServiceFields.Add("YearPeriod");
	
	Return ServiceFields;
	
EndFunction

// Returns an array of names available for selecting layouts
//
// Returns:
//	Array of Structure - array of names of Templates available for selection:
//		*Name - String - name of the layout.
//		*Synonym - String - Synonym for the layout.
//
Function DataLayoutSchemaTemplates() Export
	Templates = New Array;
	
	UseProduction21 = False;

	For Each Template In Metadata.Catalogs.StructureOfTargets.Templates Do
		If Template.TemplateType <> Metadata.ObjectProperties.TemplateType.DataCompositionSchema
			Or Template.Name = "DataCompositionTemplateScheme" Then
			Continue;
		EndIf;
		
		If Not UseProduction21
			And (Template.Name = "ProductionPlanFulfillmentPredefined" 
				Or Template.Name = "OverdueProductionOrdersPredefined") Then
			Continue;
		EndIf;
		
		Templates.Add(New Structure("Name, Synonym", Template.Name, Template.Synonym));
	EndDo;
	
	Return Templates;
EndFunction

#EndRegion

#Region Private

#Region Other


// Disables selections if the corresponding functional options are disabled.
// 
// Parameters:
// 	Settings - DataCompositionSettings - customization.
Procedure DisableSelectionsBasedOnFunctionalOptions(Settings)
	UsePartnersAsCounterparties		= GetFunctionalOption("UsePartnersAsCounterparties");
	UseMultipleCompanies			= GetFunctionalOption("UseMultipleCompanies");
	UseMultipleCashAccounts					= GetFunctionalOption("UseMultipleCashAccounts");
	UseMultipleBankAccounts		= GetFunctionalOption("UseMultipleBankAccounts");
	UseItemVariants		= GetFunctionalOption("UseItemVariants");
	UseCustomerClassification			= GetFunctionalOption("UseABCXYZClassificationOfPartnersByGrossProfit")
		Or GetFunctionalOption("UseABCXYZClassificationOfPartnersByRevenue")
		Or GetFunctionalOption("UseABCXYZClassificationOfPartnersByNumberOfSales");
	
	Filters = Settings.Filter.Items;
	VariableSelections = New Map;
	For Each Filter In Filters Do
		If TypeOf(Filter) = Type("DataCompositionFilterItem") Then
			VariableSelections.Insert(Filter.LeftValue, Filter);
		EndIf;
	EndDo;
	
	If UsePartnersAsCounterparties Then
		ClearFilter(Settings, VariableSelections, "Counterparty");
	EndIf;
	
	If Not UseMultipleCompanies Then
		ClearFilter(Settings, VariableSelections, "Organization");
	EndIf;
	
	If Not UseMultipleCashAccounts Then
		ClearFilter(Settings, VariableSelections, "CashAccount");
	EndIf;
	
	If Not UseMultipleBankAccounts Then
		ClearFilter(Settings, VariableSelections, "BankAccount");
	EndIf;
	
	If Not UseItemVariants Then
		ClearFilter(Settings, VariableSelections, "Characteristic");
	EndIf;
	
	If Not UseCustomerClassification Then
		ClearFilter(Settings, VariableSelections, "Class");
	EndIf;
EndProcedure

Procedure ClearFilter(Settings, VariableSelections, FieldName)
	FieldToCheck = New DataCompositionField(FieldName);
	RemovableSelection = VariableSelections.Get(FieldToCheck);
	If Not RemovableSelection = Undefined Then
		Settings.Filter.Items.Delete(RemovableSelection);
	EndIf;
EndProcedure

#Region InfobaseUpdate

Procedure AfterImportData(Container) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	StructureOfTargets.Ref,
	|	StructureOfTargets.DataCompositionSchema
	|FROM
	|	Catalog.StructureOfTargets AS StructureOfTargets";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If IsBlankString(Selection.DataCompositionSchema) Then
			CatalogObject = Selection.Ref.GetObject(); // CatalogObject.StructureOfTargets -
			CatalogObject.StorageOfDataCompositionSchema = New ValueStorage("");
			CatalogObject.StorageOfDataCompositionSettings = New ValueStorage("");
			
			CatalogObject.Write();
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#EndIf

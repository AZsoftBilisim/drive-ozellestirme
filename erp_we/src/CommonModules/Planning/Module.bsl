////////////////////////////////////////////////////////////////////////////////
// General planning procedures and functions
//  
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.PurchasePlans);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.CashFlowPlansVendors);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.PlansOfGoodsStock);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.SalesPlans);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.CashFlowPlansCustomers);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.SalesPlansByCategories);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.AssemblyDisassemblyPlans);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.ComponentsConsumptionPlans);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.StandardsOfSalesPlanAllocationByCategories);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.InventoryConsumptionPlans);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.AdjustmentsToPlannedDemands);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.ReleasePlansProducts_);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.ProductionPlans);
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	QueriesTexts = New Map();
	
	Return QueriesTexts;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of replenishment.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "PurchasePlans");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "CashFlowPlansVendors");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "PlansOfGoodsStock");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "SalesPlans");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "CashFlowPlansCustomers");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "SalesPlansByCategories");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "AssemblyDisassemblyPlans");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "InventoryConsumptionPlans");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "AdjustmentsToPlannedDemands");
	
	#Region ComponentsConsumptionPlans
	
	TableName = "Table" + "AssemblyDisassemblyPlansForUncoupling";
	
	If TablesForRegisteredRecords.Property(TableName)
		And ValueIsFilled(TablesForRegisteredRecords[TableName]) Then
		
		TableOfComponents = TablesForRegisteredRecords[TableName].CopyColumns(); // ValueTable -
		
		Query = New Query("
			|SELECT
			|	Kits.ProductKit AS ProductKit,
			|	Kits.Purpose AS Purpose,
			|	Kits.Warehouse AS Warehouse,
			|	Kits.DateOfProduction AS DateOfProduction,
			|	CASE
			|		WHEN Kits.Count >= Kits.ToOrder
			|			THEN Kits.Count
			|		ELSE Kits.ToOrder
			|	END AS Count
			|INTO TTKits
			|FROM
			|	&Kits AS Kits
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Goods.Ref AS ProductKit,
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Package AS Package,
			|	Kits.Purpose AS Purpose,
			|	Kits.Warehouse AS Warehouse,
			|	Kits.DateOfProduction AS DateOfProduction,
			|	Kits.Count * Goods.NumberOfPackages / Goods.Ref.Count AS NumberOfPackages,
			|	Kits.Count * Goods.Count / Goods.Ref.Count AS Count,
			|	Goods.CostShare AS CostShare
			|FROM
			|	Catalog.ProductKitConfigurations.Goods AS Goods
			|		INNER JOIN TTKits AS Kits
			|		ON Kits.ProductKit = Goods.Ref
			|
			|ORDER BY
			|	Goods.LineNumber");
		
		Query.SetParameter("Kits", TablesForRegisteredRecords[TableName]);
		
		DataOfConfigurationOptions = Query.Execute().Unload();
		
		Filter = New Structure();
		Filter.Insert("ProductKit");
		Filter.Insert("Purpose");
		Filter.Insert("Warehouse");
		Filter.Insert("DateOfProduction");
		
		For Each ItemKit In TablesForRegisteredRecords[TableName] Do
			
			FillPropertyValues(Filter, ItemKit);
			
			Components = DataOfConfigurationOptions.FindRows(Filter);
			
			For Each ComponentElement In Components Do
				
				NewRow = TableOfComponents.Add();
				FillPropertyValues(NewRow, ComponentElement,"Products,Characteristic");
				FillPropertyValues(NewRow, ItemKit, "Period, Status, Scenario, PlanProfile, BusinessOperation,ProductKit,AssemblyDisassemblyPlan,Warehouse,Purpose,DateOfProduction");
				
				If ItemKit.Count>0 Then
					NewRow.Count = ComponentElement.Count;
				EndIf;
				If ItemKit.ToOrder>0 Then
					NewRow.ToOrder = ComponentElement.Count;
				EndIf;
				
			EndDo;
			
		EndDo;
		
		RegisterRecords.ComponentsConsumptionPlans.Write = True;
		RegisterRecords.ComponentsConsumptionPlans.Load(TableOfComponents);
		
	EndIf;
	
	#EndRegion
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "StandardsOfSalesPlanAllocationByCategories");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ReleasePlansProducts_");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ProductionPlans");
EndProcedure

#EndRegion

#Region ObjectFillingProcedures

// The function returns the default planning Script for the plan type
//
// Parameters:
//  PlanType - EnumRef.TypesOfPlans - Type of plan, such as purchase Plan, sales Plan, etc.
//
// Returns:
//   CatalogRef.SalesOperationsPlanningScenarios - a link to the default planning script.
//
Function GetDefaultScript(Val PlanType) Export 

	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED DISTINCT TOP 2
	|	PlanProfiles.Owner AS Scenario
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	NOT PlanProfiles.Owner.DeletionMark
	|	AND NOT PlanProfiles.DeletionMark
	|	AND &PlanType = PlanProfiles.PlanType";
	
	Query.SetParameter("PlanType", PlanType);
	
	Result = Query.Execute();
	
	SelectionDetailRecords = Result.Select();
	
	If SelectionDetailRecords.Count() = 1 And SelectionDetailRecords.Next() Then
		
		Return SelectionDetailRecords.Scenario;
		
	Else
		
		Return Catalogs.SalesOperationsPlanningScenarios.EmptyRef();
		
	EndIf;
	
EndFunction 

// This function returns the default plan view for the scenario
//
// Parameters:
//  PlanType - EnumRef.TypesOfPlans - Type of plan, such as purchase Plan, sales Plan, etc.
//  Scenario - CatalogRef.SalesOperationsPlanningScenarios - The scenario that results in the default plan view.
//
// Returns:
//   CatalogRef.PlanProfiles - link to the default plan view.
//
Function GetDefaultPlanView(Val PlanType, Val Scenario) Export 

	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED DISTINCT TOP 2
	|	PlanProfiles.Ref AS PlanProfile
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.PlanType = &PlanType
	|	AND PlanProfiles.Owner = &Scenario
	|	AND NOT PlanProfiles.DeletionMark";
	
	Query.SetParameter("Scenario", Scenario);
	Query.SetParameter("PlanType", PlanType);
	
	Result = Query.Execute();
	
	SelectionDetailRecords = Result.Select();
	
	If SelectionDetailRecords.Count() = 1 And SelectionDetailRecords.Next() Then
		
		Return SelectionDetailRecords.PlanProfile;
		
	Else
		
		Return Catalogs.PlanProfiles.EmptyRef();
		
	EndIf;
	
EndFunction 

// The function gets a schema for converting data to be filled in to a document
//
// Parameters:
//  PlanType - EnumRef.TypesOfPlans - Type of plan, such as purchase Plan, sales Plan, etc.
//  FillInUsingFormula - Boolean
//  FillInAssignmentInTabularForm - Boolean
//
// Returns:
//   DataCompositionSchema - a scheme for converting data to be filled into a document.
//
Function GetDataConversionScheme(Val PlanType, Val FillInUsingFormula = False, FillInAssignmentInTabularForm = False) Export 
	
	DataCompositionSchemaConversion = Undefined;
	
	ExcludeCharacteristics = False;
	ExcludeWarehouses = False;
	
	If PlanType = Enums.TypesOfPlans.PurchasePlan Then
		DataCompositionSchemaConversion = Documents.PurchasePlan.GetTemplate("DataCompositionSchemaConversion");
		ExcludeCharacteristics = Not GetFunctionalOption("UseItemVariants");
		ExcludeWarehouses = Not GetFunctionalOption("UseSeveralWarehouses");
	EndIf; 
	
	If PlanType = Enums.TypesOfPlans.PlanOfGoodsStock Then
		DataCompositionSchemaConversion = Documents.PlanOfGoodsStock.GetTemplate("DataCompositionSchemaConversion");
		ExcludeCharacteristics = Not GetFunctionalOption("UseItemVariants");
		ExcludeWarehouses = Not GetFunctionalOption("UseSeveralWarehouses");
	EndIf;
	
	If PlanType = Enums.TypesOfPlans.SalesPlan Then
		DataCompositionSchemaConversion = Documents.SalesPlan.GetTemplate("DataCompositionSchemaConversion");
		ExcludeCharacteristics = Not GetFunctionalOption("UseItemVariants");
		ExcludeWarehouses = Not GetFunctionalOption("UseSeveralWarehouses");
	EndIf;
	
	If PlanType = Enums.TypesOfPlans.SalesPlanByCategories Then
		DataCompositionSchemaConversion = Documents.SalesPlanByCategories.GetTemplate("DataCompositionSchemaConversion");
		ExcludeWarehouses = Not GetFunctionalOption("UseSeveralWarehouses");
	EndIf;
	
	If PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan Then
		DataCompositionSchemaConversion = Documents.AssemblyDisassemblyPlan.GetTemplate("DataCompositionSchemaConversion");
		ExcludeCharacteristics = Not GetFunctionalOption("UseItemVariants");
		ExcludeWarehouses = Not GetFunctionalOption("UseSeveralWarehouses");
	EndIf; 
	
	If PlanType = Enums.TypesOfPlans.InventoryConsumptionPlan Then
		DataCompositionSchemaConversion = Documents.InventoryConsumptionPlan.GetTemplate("DataCompositionSchemaConversion");
		ExcludeCharacteristics = Not GetFunctionalOption("UseItemVariants");
		ExcludeWarehouses = Not GetFunctionalOption("UseSeveralWarehouses");
	EndIf;
	If PlanType = Enums.TypesOfPlans.ProductionPlan Then
		DataCompositionSchemaConversion = Documents.ProductionPlan.GetTemplate("DataCompositionSchemaConversion");
		ExcludeCharacteristics = Not GetFunctionalOption("UseItemVariants");
	EndIf;
	ExcludeAssignment = Not FillInAssignmentInTabularForm Or Not GetFunctionalOption("UseOrderSupplyWithAssignment");
	
	If FillInUsingFormula Then
		ExcludeWarehouses = True;
	EndIf; 
	
	If ExcludeCharacteristics Or ExcludeWarehouses Or ExcludeAssignment Then
		
		CharacteristicField = New DataCompositionField("Characteristic");
		WarehouseField = New DataCompositionField("Warehouse");
		DestinationField_ = New DataCompositionField("Purpose");
		
		Filters = DataCompositionSchemaConversion.SettingVariants[0].Settings.Filter.Items;
		IndexOf = Filters.Count() - 1;
		While  IndexOf >= 0 Do
			Filter = Filters[IndexOf];
			IndexOf = IndexOf - 1;
			
			If ExcludeCharacteristics And Filter.LeftValue = CharacteristicField Then
				
				Filters.Delete(Filter);
				Field = DataCompositionSchemaConversion.DataSets.Union.Fields.Find("Characteristic"); // DataCompositionSchemaDataSetField -
				Field.UseRestriction.Condition = True;
				Field.AttributeUseRestriction.Condition = True;
				Continue;
				
			EndIf; 
			
			If ExcludeWarehouses And Filter.LeftValue = WarehouseField Then
				
				Filters.Delete(Filter);
				Field = DataCompositionSchemaConversion.DataSets.Union.Fields.Find("Warehouse"); // DataCompositionSchemaDataSetField -
				Field.UseRestriction.Condition = True;
				Field.AttributeUseRestriction.Condition = True;
				Continue;
				
			EndIf;
			
			If ExcludeAssignment And Filter.LeftValue = DestinationField_ Then
				
				Filters.Delete(Filter);
				Field = DataCompositionSchemaConversion.DataSets.Union.Fields.Find("Purpose"); // DataCompositionSchemaDataSetField -
				Field.UseRestriction.Condition = True;
				Field.AttributeUseRestriction.Condition = True;
				Continue;
				
			EndIf;
			
		EndDo; 
		
		IndexOf = DataCompositionSchemaConversion.DataSetLinks.Count() - 1;
		While  IndexOf >= 0 Do
			Link = DataCompositionSchemaConversion.DataSetLinks[IndexOf];
			IndexOf = IndexOf - 1;
			
			If ExcludeCharacteristics 
				And (Link.SourceExpression = "Characteristic" 
				Or Link.DestinationExpression = "Characteristic") Then
			
				DataCompositionSchemaConversion.DataSetLinks.Delete(Link);
			
			EndIf; 
			
			If ExcludeWarehouses 
				And (Link.SourceExpression = "Warehouse" 
				Or Link.DestinationExpression = "Warehouse") Then
			
				DataCompositionSchemaConversion.DataSetLinks.Delete(Link);
			
			EndIf; 
			
			If ExcludeAssignment 
				And (Link.SourceExpression = "Purpose" 
				Or Link.DestinationExpression = "Purpose") Then
			
				DataCompositionSchemaConversion.DataSetLinks.Delete(Link);
			
			EndIf;
			
		EndDo; 
	EndIf; 
	
	GroupFields = DataCompositionSchemaConversion.SettingVariants[0].Settings.Structure[0].GroupFields.Items;
	IndexOf = GroupFields.Count() - 1;
	
	If FillInUsingFormula Then
	
		PeriodField = New DataCompositionField("Period");
		
		While  IndexOf >= 0 Do
			GroupingField = GroupFields[IndexOf];
		
			If GroupingField.Field = PeriodField Then
				GroupFields.Delete(GroupingField);
			EndIf;
			
			IndexOf = IndexOf - 1;
		EndDo;
		
	Else
		
		FieldLIneNumber = New DataCompositionField("LineNumber");
		CompositionPeriodField = New DataCompositionField("CompositionPeriod");
		
		While  IndexOf >= 0 Do
			GroupingField = GroupFields[IndexOf];
		
			If GroupingField.Field = FieldLIneNumber Then
				GroupFields.Delete(GroupingField);
			EndIf;
			
			If GroupingField.Field = CompositionPeriodField Then
				GroupFields.Delete(GroupingField);
			EndIf;
			
			IndexOf = IndexOf - 1;
		EndDo;
		
		CompositionTable = DataCompositionSchemaConversion.DataSets.Find("CompositionTable");
		If CompositionTable <> Undefined Then
			
			IndexOf = DataCompositionSchemaConversion.DataSetLinks.Count() - 1;
			
			While  IndexOf >= 0 Do
				
				Link = DataCompositionSchemaConversion.DataSetLinks[IndexOf];
				If Link.SourceDataSet = "CompositionTable" Then
					DataCompositionSchemaConversion.DataSetLinks.Delete(Link);
				EndIf; 
				
				IndexOf = IndexOf - 1;
				
			EndDo; 
			DataCompositionSchemaConversion.DataSets.Delete(CompositionTable);
		EndIf; 
		
	EndIf; 
	
	Return DataCompositionSchemaConversion;
	
EndFunction

// The function gets the default user settings from the plan view
//
// Parameters:
//  PlanType - EnumRef.TypesOfPlans - Type of plan, such as purchase Plan, sales Plan, etc.
//  PlanProfile - CatalogRef.PlanProfiles, CatalogObject.PlanProfiles - The type of plan that the settings are derived from.
//
// Returns:
//   Structure - document filling settings.
//
Function GetDefaultSettings(Val PlanType, Val PlanProfile) Export 

	If Not ValueIsFilled(PlanProfile) Then
		Return New Structure;
	EndIf;
	
	If TypeOf(PlanProfile) = Type("CatalogObject.PlanProfiles") Then
		If PlanType = PlanProfile.PlanType Then
			SettingsStructure = PlanProfile.SettingsStructure.Get();
		Else
			SettingsStructure = Undefined;
		EndIf;
	Else
		Attributes = Common.ObjectAttributesValues(PlanProfile, "SettingsStructure, PlanType");
		If PlanType = Attributes.PlanType Then
			StructureOfSettingsStorage = Attributes.SettingsStructure;
			SettingsStructure = StructureOfSettingsStorage.Get();
		Else
			SettingsStructure = Undefined;
		EndIf;
	EndIf;
	
	If TypeOf(SettingsStructure) = Type("Structure") Then
		SettingsStructure.Insert("UserSettings", Undefined);
	Else
		SettingsStructure = New Structure;
	EndIf;
	
	Return SettingsStructure;

EndFunction

// The function gets the default rule for the plan view, puts it in temporary storage, and returns the address.
//
// Parameters:
//  PlanType                - EnumRef.TypesOfPlans - Type of plan, such as purchase Plan, sales Plan, etc.
//  PlanProfile                - CatalogRef.PlanProfiles, CatalogObject.PlanProfiles - The type of plan
//                                                                                       that the fill rule is derived from
//  UUID - UUID - a unique identifier that returns the address of the rule.
//
// Returns:
//   String - the address of the temporary value store.
//
Function GetAddressOfDefaultFillInRule(Val PlanType, Val PlanProfile, Val UUID) Export 
	
	If Not ValueIsFilled(PlanProfile) Then
		If IsTempStorageURL(UUID) Then
			Return UUID;
		Else
			Return "";
		EndIf;
	EndIf; 
	
	If TypeOf(PlanProfile) = Type("CatalogObject.PlanProfiles") Then
		FillingRule = PlanProfile.FillingRule.Unload();
		If PlanType <> PlanProfile.PlanType Then
			FillingRule.Clear();
		EndIf;
	Else
		Query = New Query("SELECT
		|	PlanProfiles.PlanType AS PlanType
		|FROM
		|	Catalog.PlanProfiles AS PlanProfiles
		|WHERE
		|	PlanProfiles.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|*
		|FROM
		|	Catalog.PlanProfiles.FillingRule AS FillingRule
		|WHERE
		|	FillingRule.Ref = &Ref
		|
		|ORDER BY
		|	FillingRule.LineNumber");
		
		Query.SetParameter("Ref", PlanProfile);
		
		Result = Query.ExecuteBatch();
		
		ResultPlanType = Result[0].Unload();
		FillingRule = Result[1].Unload();
		If ResultPlanType.Count() > 0 And ResultPlanType[0].PlanType <> PlanType Then
			FillingRule.Clear();
		EndIf;
	EndIf;
	
	FillingRuleAddress = PutToTempStorage(FillingRule, UUID);
	
	Return FillingRuleAddress;

EndFunction 

// The function gets the default user settings from the plan view and returns the address of the temporary storage.
//
// Parameters:
//  PlanType                - EnumRef.TypesOfPlans - Type of plan, such as purchase Plan, sales Plan, etc.
//  PlanProfile                - CatalogRef.PlanProfiles, CatalogObject.PlanProfiles - The type of plan that
//                                                                                       the settings are derived from
//  UUID - UUID - a unique identifier that returns the address of the settings.
//
// Returns:
//   String - the address of the temporary value store.
//
Function GetAddressOfUserDefaultSettings(Val PlanType, Val PlanProfile, Val UUID) Export 

	If Not ValueIsFilled(PlanProfile) Then
		If IsTempStorageURL(UUID) Then
			Return UUID;
		Else
			Return "";
		EndIf;
	EndIf;
	
	If TypeOf(PlanProfile) = Type("CatalogObject.PlanProfiles") Then
		If PlanType = PlanProfile.PlanType Then
			SettingsStructure = PlanProfile.SettingsStructure.Get();
		Else
			SettingsStructure = Undefined;
		EndIf;
	Else
		Attributes = Common.ObjectAttributesValues(PlanProfile, "SettingsStructure, PlanType");
		If PlanType = Attributes.PlanType Then
			StructureOfSettingsStorage = Attributes.SettingsStructure;
			SettingsStructure = StructureOfSettingsStorage.Get();
		Else
			SettingsStructure = Undefined;
		EndIf;
	EndIf;
	
	If TypeOf(SettingsStructure) = Type("Structure") And SettingsStructure.Property("UserSettings") Then
		CustomSettingsAddress = PutToTempStorage(SettingsStructure.UserSettings, UUID);
	Else
		CustomSettingsAddress = PutToTempStorage(Undefined, UUID);
	EndIf;
	
	Return CustomSettingsAddress;

EndFunction

#EndRegion

#Region CrossTableProcedures

// The procedure creates a "table of values" form with the columns required for processing periods.
//
// Parameters:
//  Form  				- ClientApplicationForm - form to create a period table in
//  PeriodTableName  - String - Name to use for creating the table form details.
//
Procedure CreatePeriodTable(Form, Val PeriodTableName) Export 
	
	TopLevelDetails = Form.GetAttributes();
	
	DescriptionOfVTTypes = New TypeDescription("ValueTable");
	DescriptionOfHTypes = TMCommonUse.GetDescriptionOfNumberTypes(10, 0); 
	TypesDetailsBoolean = New TypeDescription("Boolean");
	TypesDetailsString = New TypeDescription("String");
	TypesDetailsDate = TMCommonUse.GetDescriptionOfDateTypes(DateFractions.DateTime);
	
	// Creating table details
	AttributesToBeAdded = New Array();
	PropsExist = False;
	For Each Attribute In TopLevelDetails Do
		
		If Attribute.Name = PeriodTableName Then
			PropsExist = True;
			Break;
		EndIf;
	EndDo;
	If Not PropsExist Then
		Attribute = New FormAttribute(PeriodTableName, DescriptionOfVTTypes);
		AttributesToBeAdded.Add(Attribute);
		
		Attribute = New FormAttribute("ColumnNumber", DescriptionOfHTypes, PeriodTableName);
		AttributesToBeAdded.Add(Attribute);
		
		Attribute = New FormAttribute("ColumnName", TypesDetailsString, PeriodTableName);
		AttributesToBeAdded.Add(Attribute);
		
		Attribute = New FormAttribute("Active_", TypesDetailsBoolean, PeriodTableName);
		AttributesToBeAdded.Add(Attribute);
		
		Attribute = New FormAttribute("StartDate", TypesDetailsDate, PeriodTableName);
		AttributesToBeAdded.Add(Attribute);
		
		Attribute = New FormAttribute("EndDate", TypesDetailsDate, PeriodTableName);
		AttributesToBeAdded.Add(Attribute);
		
		Attribute = New FormAttribute("Title", TypesDetailsString, PeriodTableName);
		AttributesToBeAdded.Add(Attribute);
		
		Attribute = New FormAttribute("Substituted", TypesDetailsBoolean, PeriodTableName);
		AttributesToBeAdded.Add(Attribute);
		
		Attribute = New FormAttribute("SubstitutedToOrder", TypesDetailsBoolean, PeriodTableName);
		AttributesToBeAdded.Add(Attribute);
		
	EndIf;;
	
	If AttributesToBeAdded.Count() > 0 Then
		Form.ChangeAttributes(AttributesToBeAdded);
	EndIf;

EndProcedure

// The function returns the periods of the remaining balance plans
//
// Parameters:
//  Parameters - Structure - the parameters of the calculation periods of the plan.
//
// Returns:
//  Structure - contains:
//   Datanachalanakopleniyaostatka - Date - the date of the beginning of the accumulation of planned Balances
//   The period of the planning period is the largest period of the period - An array is an array of periods of Balance plans, more than the beginning of the period.
//
Function GetPeriodsOfBalancePlans(Parameters) Export 
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PlanOfGoodsStock.BeginOfPeriod AS Period
	|INTO AllPlansRemain
	|FROM
	|	Document.PlanOfGoodsStock AS PlanOfGoodsStock
	|WHERE
	|	PlanOfGoodsStock.Ref <> &Ref
	|	AND PlanOfGoodsStock.BeginOfPeriod <= &EndOfPeriod
	|	AND PlanOfGoodsStock.Scenario = &Scenario
	|	AND PlanOfGoodsStock.Status IN(&ScenarioStatuses)
	|	AND NOT PlanOfGoodsStock.DeletionMark
	|	AND PlanOfGoodsStock.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(AllPlansRemain.Period) AS Period
	|FROM
	|	AllPlansRemain AS AllPlansRemain
	|WHERE
	|	AllPlansRemain.Period <= &BeginOfPeriod
	|
	|HAVING
	|	MAX(AllPlansRemain.Period) > DATETIME(1, 1, 1, 0, 0, 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PeriodProcurementPlans.Period AS Period
	|FROM
	|	(SELECT TOP 1
	|		PurchasePlan.BeginOfPeriod AS Period
	|	FROM
	|		Document.PurchasePlan AS PurchasePlan
	|	WHERE
	|		PurchasePlan.BeginOfPeriod <= &EndOfPeriod
	|		AND PurchasePlan.Ref <> &Ref
	|		AND PurchasePlan.Scenario = &Scenario
	|		AND PurchasePlan.Status IN(&ScenarioStatuses)
	|	
	|	ORDER BY
	|		Period) AS PeriodProcurementPlans
	|
	|UNION ALL
	|
	|SELECT
	|	PeriodSalesPlans.Period
	|FROM
	|	(SELECT TOP 1
	|		SalesPlan.BeginOfPeriod AS Period
	|	FROM
	|		Document.SalesPlan AS SalesPlan
	|	WHERE
	|		SalesPlan.BeginOfPeriod <= &EndOfPeriod
	|		AND SalesPlan.Ref <> &Ref
	|		AND SalesPlan.Scenario = &Scenario
	|		AND SalesPlan.Status IN(&ScenarioStatuses)
	|	
	|	ORDER BY
	|		Period) AS PeriodSalesPlans
	|
	|UNION ALL
	|
	|SELECT
	|	PeriodicityOfDomesticConsumption.Period
	|FROM
	|	(SELECT TOP 1
	|		InventoryConsumptionPlan.BeginOfPeriod AS Period
	|	FROM
	|		Document.InventoryConsumptionPlan AS InventoryConsumptionPlan
	|	WHERE
	|		InventoryConsumptionPlan.BeginOfPeriod <= &EndOfPeriod
	|		AND InventoryConsumptionPlan.Ref <> &Ref
	|		AND InventoryConsumptionPlan.Scenario = &Scenario
	|		AND InventoryConsumptionPlan.Status IN(&ScenarioStatuses)
	|	
	|	ORDER BY
	|		Period) AS PeriodicityOfDomesticConsumption
	|
	|
	|UNION ALL
	|
	|SELECT
	|	PeriodProductionPlans.Period
	|FROM
	|	(SELECT TOP 1
	|		ProductionPlan.BeginOfPeriod AS Period
	|	FROM
	|		Document.ProductionPlan AS ProductionPlan
	|	WHERE
	|		ProductionPlan.BeginOfPeriod <= &EndOfPeriod
	|		AND ProductionPlan.Ref <> &Ref
	|		AND ProductionPlan.Scenario = &Scenario
	|		AND ProductionPlan.Status IN(&ScenarioStatuses)
	|	
	|	ORDER BY
	|		Period) AS PeriodProductionPlans
	|
	|UNION ALL
	|
	|SELECT
	|	PeriodPlansOfConsumptionOfMaterialsTurnover.Period
	|FROM
	|	(SELECT TOP 1
	|		MaterialConsumptionPlansTurnovers.Period AS Period
	|	FROM
	|		AccumulationRegister.MaterialConsumptionPlans.Turnovers(
	|				,
	|				&EndOfPeriod,
	|				Record,
	|				Scenario = &Scenario
	|					AND Status IN (&ScenarioStatuses)
	|					AND ProductionPlan <> &Ref) AS MaterialConsumptionPlansTurnovers
	|	
	|	ORDER BY
	|		MaterialConsumptionPlansTurnovers.Period) AS PeriodPlansOfConsumptionOfMaterialsTurnover
	|
	|UNION ALL
	|
	|SELECT
	|	PeriodicAssemblyDisassembly.Period
	|FROM
	|	(SELECT TOP 1
	|		AssemblyDisassemblyPlan.BeginOfPeriod AS Period
	|	FROM
	|		Document.AssemblyDisassemblyPlan AS AssemblyDisassemblyPlan
	|	WHERE
	|		AssemblyDisassemblyPlan.BeginOfPeriod <= &EndOfPeriod
	|		AND AssemblyDisassemblyPlan.Ref <> &Ref
	|		AND AssemblyDisassemblyPlan.Scenario = &Scenario
	|		AND AssemblyDisassemblyPlan.Status IN(&ScenarioStatuses)
	|	
	|	ORDER BY
	|		Period) AS PeriodicAssemblyDisassembly
	|
	|UNION ALL
	|
	|SELECT
	|	PeriodPlansOfConsumptionOfComponentsRevolutions.Period
	|FROM
	|	(SELECT TOP 1
	|		PlansForConsumptionOfComponentsTurnover.Period AS Period
	|	FROM
	|		AccumulationRegister.ComponentsConsumptionPlans.Turnovers(
	|				,
	|				&EndOfPeriod,
	|				Record,
	|				Scenario = &Scenario
	|					AND Status IN (&ScenarioStatuses)
	|					AND AssemblyDisassemblyPlan <> &Ref) AS PlansForConsumptionOfComponentsTurnover
	|	
	|	ORDER BY
	|		PlansForConsumptionOfComponentsTurnover.Period) AS PeriodPlansOfConsumptionOfComponentsRevolutions
	|
	|ORDER BY
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllPlansRemain.Period AS Period
	|FROM
	|	AllPlansRemain AS AllPlansRemain
	|WHERE
	|	AllPlansRemain.Period > &BeginOfPeriod";
	
	Query.SetParameter("Scenario", Parameters.Scenario);
	Query.SetParameter("Periodicity", Parameters.Periodicity);
	Query.SetParameter("ScenarioStatuses", Parameters.ScenarioStatuses);
	Query.SetParameter("Ref", Parameters.Ref);
	Query.SetParameter("EndOfPeriod", Parameters.EndOfPeriod);
	Query.SetParameter("BeginOfPeriod", Parameters.BeginOfPeriod);
	
	QueryResult = Query.ExecuteBatch();  
	SelectingPeriodicBalancePlan = QueryResult[1].Select();
	
	BalanceAccumulationStartDate = Parameters.BeginOfPeriod;
	
	If SelectingPeriodicBalancePlan.Next() Then
		BalanceAccumulationStartDate = SelectingPeriodicBalancePlan.Period;
	Else
		SamplingPeriodsOfOtherPlans = QueryResult[2].Select();
		If SamplingPeriodsOfOtherPlans.Next() Then
			BalanceAccumulationStartDate = Min(SamplingPeriodsOfOtherPlans.Period, BalanceAccumulationStartDate);
		EndIf;
	EndIf;
	
	BalancePlanPeriodsForPeriodGreaterThanBeginningOfPeriod = New Array;
	SamplingPeriodsOfBalancePlans = QueryResult[3].Select();
	If SamplingPeriodsOfBalancePlans.Next() Then
		BalancePlanPeriodsForPeriodGreaterThanBeginningOfPeriod.Add(SamplingPeriodsOfBalancePlans.Period);
	EndIf;
	
	Result = New Structure;
	Result.Insert("BalanceAccumulationStartDate", BalanceAccumulationStartDate);
	Result.Insert("BalancePlanPeriodsForPeriodGreaterThanBeginningOfPeriod", BalancePlanPeriodsForPeriodGreaterThanBeginningOfPeriod);
	
	SetPrivilegedMode(False);
	
	Return Result
EndFunction

// The procedure prepares a table of periods for filling in using formulas
//
// Parameters:
//  Parameters - Structure - Fill-in parameters.
//
Procedure PrepareTableOfPeriodsBeforeFillingIn(Parameters) Export 
	
	ScriptParameters_ = ScriptParameters_(Parameters.Scenario);
	UseInBalancePlanning = ScriptParameters_.UseInBalancePlanning;
	
	// If the schemes of "Planned initial dates" are used, or
	// then the beginning of the period is set to the last actual plan of the balances, and the period offset is not used.
	If UseInBalancePlanning And Parameters.PeriodOffset = 0
		And StrFind(Parameters.Formula, "PlannedStartBalance") > 0 Then
		
		If Parameters.Property("Scenario") 
			And Not Parameters.Property("ScenarioStatuses") Then
			StatusesList = New ValueList;
			StatusesList.Add(Enums.PlanStatuses.AwaitingConfirmation);
			StatusesList.Add(Enums.PlanStatuses.Upholded);
			
			Parameters.Insert("ScenarioStatuses",StatusesList);
		EndIf;
		
		ParametersForCalculatingBeginningOfBalanceAccumulation = New Structure();
		ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("Scenario", Parameters.Scenario);
		ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("Periodicity", Parameters.Periodicity);
		ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("ScenarioStatuses", Parameters.ScenarioStatuses);
		ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("Ref", Parameters.Ref);
		ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("BeginOfPeriod", Parameters.OffsetPeriodStart);
		ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("EndOfPeriod", Parameters.OffsetPeriodEnd);
		
		Result = GetPeriodsOfBalancePlans(ParametersForCalculatingBeginningOfBalanceAccumulation);
		Parameters.OffsetPeriodStart = Result.BalanceAccumulationStartDate;
		
	EndIf;
	
EndProcedure

// The procedure fills in a table of periods corresponding to dates with the specified frequency to get fields and their headers.
//
// Parameters:
//  TablePeriods - See TablePeriods
//  Periodicity  - EnumRef.Periodicity - Frequency with which to fill in the table
//  StartDate     - Date - start date of the period
//  EndDate  - Date - Period end date
//  ShowNumberOfPeriod  - Boolean - Flag for displaying the title by period number within a year
//  SubstitutedPeriods - ValueTable - Where:
//   *SubstitutedPeriod - Date
//   *SubstitutedToOrder - Boolean
//   *Substituted - Boolean
//  StartDateOfActivePeriods - Date
//
Procedure FillInPeriodTable(TablePeriods, Val Periodicity, Val StartDate, Val EndDate, Val ShowNumberOfPeriod = False, SubstitutedPeriods = Undefined, StartDateOfActivePeriods = Undefined) Export 
	
	For Each PeriodString_ In TablePeriods Do
		PeriodString_.Active_ = False;
		PeriodString_.ColumnNumber = -1;
	EndDo; 
	
	If Not ValueIsFilled(Periodicity)
		Or Not ValueIsFilled(StartDate) 
		And Not ValueIsFilled(EndDate) Then
		Return;
	EndIf;
	
	AddingStartDate = PlanningClientServerCached.CalculateStartDateOfPeriod(StartDate, Periodicity);
	AddingEndDate = PlanningClientServerCached.CalculatePeriodEndDate(AddingStartDate, Periodicity);
	If StartDateOfActivePeriods = Undefined Then
		StartDateOfActivePeriods = Date('00010101');
	EndIf;
	
	CurrentPeriod = 1;
	
	While AddingStartDate < EndOfDay(EndDate) Do
		
		FoundRows = TablePeriods.FindRows(New Structure("StartDate, EndDate", AddingStartDate, AddingEndDate));
		If FoundRows.Count() = 0 Then
			NewRow = TablePeriods.Add();
			NewRow.ColumnName = StrReplace(String(New UUID),"-","_");
		Else
			NewRow = FoundRows[0];
		EndIf;
		NewRow.Active_ =AddingStartDate>=StartDateOfActivePeriods;
		If NewRow.Active_ Then
			NewRow.ColumnNumber = CurrentPeriod;
			CurrentPeriod = CurrentPeriod + 1;
		Else
			NewRow.ColumnNumber = 0;
		EndIf;
		NewRow.StartDate = AddingStartDate;
		NewRow.EndDate = AddingEndDate;
		
		NewRow.Substituted = False;
		NewRow.SubstitutedToOrder = False;
		
		If SubstitutedPeriods <> Undefined Then
			SubstitutedStringPeriods = SubstitutedPeriods.FindRows(New Structure("SubstitutedPeriod", AddingStartDate)); 
			If SubstitutedStringPeriods.Count()>0 Then
				NewRow.Substituted = True;
				If SubstitutedStringPeriods[0].Property("SubstitutedToOrder") Then
					NewRow.SubstitutedToOrder = SubstitutedStringPeriods[0].SubstitutedToOrder;
				EndIf;
			EndIf;
		EndIf;
		
		NewRow.Title = PlanningClientServer.GeneratePeriodHeader(Periodicity, AddingStartDate, AddingEndDate, ShowNumberOfPeriod, NewRow.Substituted);
		
		AddingStartDate = PlanningClientServerCached.CalculateStartDateOfPeriod(AddingEndDate+1 , Periodicity);
		AddingEndDate = PlanningClientServerCached.CalculatePeriodEndDate(AddingEndDate+1, Periodicity);
		
	EndDo;
	
	LinesToDelete = TablePeriods.FindRows(New Structure("ColumnNumber",-1));
	For Each RowToDelete In LinesToDelete Do
		TablePeriods.Delete(RowToDelete);
	EndDo;
	
	TablePeriods.Sort("StartDate");
	
EndProcedure

// The procedure updates the data structure of the plan's cross-table
//
// Parameters:
//  Form  				- ClientApplicationForm - form to create a period table in
//  Parameters  			- Structure - cross-table formation parameters:
//  * NameOfCrossTableProps - String - 
//  * CrossTableFormElement - String - 
//  * PeriodsTable - See TablePeriods
//  * DisplayPreviousPeriod - Boolean - 
//  * Periodicity - EnumRef.Periodicity - 
//  * Fields - Array of See FieldStructure -
//
Procedure UpdateCrosstabOutputStructure(Form, Parameters) Export
	
	NameOfCrossTableProps = Parameters.NameOfCrossTableProps;
	CrossTableFormElement = Parameters.CrossTableFormElement;
	PeriodsTable = Parameters.PeriodsTable;
	Fields = Parameters.Fields;
	
	If Parameters.Property("DisplayPreviousPeriod") Then
		DisplayPreviousPeriod = Parameters.DisplayPreviousPeriod;
	Else
		DisplayPreviousPeriod = False;
	EndIf;
	
	If Parameters.Property("CreatePeriodGroup") Then
		CreatePeriodGroup = Parameters.CreatePeriodGroup;
	Else
		CreatePeriodGroup = False;
	EndIf;
	
	AttributesToBeAdded = New Array();
	AttributesToBeDeleted = New Array();
	DetailsOfPlanTable = Form.GetAttributes(NameOfCrossTableProps);
	TopLevelDetails = Form.GetAttributes();
	
	For Each Attribute In DetailsOfPlanTable Do
		If StrFind(Attribute.Name, "_") <> 0 Then
			AttributesToBeDeleted.Add(NameOfCrossTableProps+"." + Attribute.Name);
		EndIf;
	EndDo;
	
	MatchingPlanTableDetails = New Map;
	For Each Attribute In DetailsOfPlanTable Do
		MatchingPlanTableDetails.Insert(Attribute.Name, True);
	EndDo;
	
	MatchingTopLevelDetails = New Map;
	For Each Attribute In TopLevelDetails Do
		MatchingTopLevelDetails.Insert(Attribute.Name, True);
	EndDo;
	
	For Each FieldStructure In Fields Do
		
		If FieldStructure.Property("CreateProps") Then
			CreateProps = FieldStructure.CreateProps;
		Else
			CreateProps = True;
		EndIf;
		
		ColumnAttributePrefix = FieldStructure.ColumnAttributePrefix;
		If FieldStructure.Property("DeleteTableDetails") Then
			DeleteTableDetails = FieldStructure.DeleteTableDetails;
		Else
			DeleteTableDetails = False;
		EndIf;
		
		// Details that cannot be deleted
		If CreateProps Then
			
			For Each PeriodString_ In PeriodsTable Do
				
				IndexOfElementToDelete = AttributesToBeDeleted.Find(NameOfCrossTableProps+"." + ColumnAttributePrefix + PeriodString_.ColumnName);
				If IndexOfElementToDelete <> Undefined Then
					AttributesToBeDeleted.Delete(IndexOfElementToDelete);
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If Not CreateProps Then
			Continue;
		EndIf;
		
		If FieldStructure.Property("ElementType") Then
			ElementType = FieldStructure.ElementType;
		Else
			ElementType = "Number";
		EndIf;
		If FieldStructure.Property("CreateSummaryDetails") Then
			CreateSummaryDetails = FieldStructure.CreateSummaryDetails;
		Else
			CreateSummaryDetails = False;
		EndIf;
		If FieldStructure.Property("ExtendedDateNumberFormat") Then
			ExtendedDateNumberFormat = FieldStructure.ExtendedDateNumberFormat;
		Else
			ExtendedDateNumberFormat = False;
		EndIf;
				
		If CreateSummaryDetails And ElementType <> "Number" And TypeOf(ElementType) <> Type("TypeDescription") Then
			CreateSummaryDetails = False;
		EndIf;
		
		If TypeOf(ElementType) = Type("TypeDescription") Then
			TypeDescription = ElementType;
		ElsIf ElementType = "Boolean" Then
			TypeDescription = New TypeDescription("Boolean");
		ElsIf ElementType = "Date" Then
			
			If ExtendedDateNumberFormat Then
				TypeDescription = TMCommonUse.GetDescriptionOfDateTypes(DateFractions.DateTime);
			Else
				TypeDescription = TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date);
			EndIf;
		Else
			
			If ExtendedDateNumberFormat Then
				TypeDescription = TMCommonUse.GetDescriptionOfNumberTypes(15, 5);
			Else
				TypeDescription = TMCommonUse.GetDescriptionOfNumberTypes(15, 3); 
			EndIf; 
			
		EndIf;
		
		// Creating table details
		For Each PeriodString_ In PeriodsTable Do
		
			AttributeName = ColumnAttributePrefix + PeriodString_.ColumnName;
			If MatchingPlanTableDetails[AttributeName] = True Then
				Attribute.Title = PeriodString_.Title;
				
				Continue;
			EndIf; 
			
			Attribute = New FormAttribute(AttributeName, TypeDescription, NameOfCrossTableProps,
				PeriodString_.Title);
			AttributesToBeAdded.Add(Attribute);
			
		EndDo;
		
		// Creating the final details 
		If CreateSummaryDetails Then
			For Each PeriodString_ In PeriodsTable Do
				If Not PeriodString_.Active_ Then
					Continue;
				EndIf; 
				
				AttributeName = StrReplace(NameOfCrossTableProps + ColumnAttributePrefix + PeriodString_.ColumnName,".","_");
				If MatchingTopLevelDetails[AttributeName] = True Then
					Continue;
				EndIf; 
				
				PropsPrefix = NStr("vi = 'Tổng số';
									|ru = 'Итого';
									|en = 'Total'; fa = 'جمع کل';
									|it = 'Totale';
									|pl = 'Łącznie';
									|tr = 'Toplam'");
				
				Attribute = New FormAttribute(AttributeName, TypeDescription,
					, PropsPrefix + " " + PeriodString_.Title);
				AttributesToBeAdded.Add(Attribute);
				
			EndDo;
		EndIf;
		
	EndDo;
	
	Form.ChangeAttributes(AttributesToBeAdded, AttributesToBeDeleted);
	
	If Not ValueIsFilled(CrossTableFormElement) Then
		Return;
	EndIf;
	
	// Deleting Form elements
	ItemsToRemove = New Array();
	CrossTable = Form.Items[CrossTableFormElement]; // FormTable - 
	For Each CurItem In CrossTable.ChildItems Do
		If StrFind(CurItem.Name, CrossTableFormElement + "AttributeGroup") Then
			ItemsToRemove.Add(CurItem);
			Continue;
		EndIf;
		ElementFound_ = False;
		For Each PeriodString_ In PeriodsTable Do
			If  StrFind(CurItem.Name, CrossTableFormElement + "Group"+PeriodString_.ColumnName) Then
				ItemsToRemove.Add(CurItem);
				ElementFound_ = True;
				Break;
			EndIf;
		EndDo;
		If ElementFound_ Then
			Continue;
		EndIf; 
		For Each FieldStructure In Fields Do
			ColumnAttributePrefix = FieldStructure.ColumnAttributePrefix;
			If StrFind(CurItem.Name, ColumnAttributePrefix) > 0  Then
				ItemsToRemove.Add(CurItem);
				Break;
			EndIf;
		EndDo;
	EndDo;
	For Each ItemToRemove In ItemsToRemove Do
		Form.Items.Delete(ItemToRemove);
	EndDo;
	
	FieldOwner = Form.Items[CrossTableFormElement];
	
	For Each PeriodString_ In PeriodsTable Do
		If Not PeriodString_.Active_ Then
			Continue;
		EndIf; 
		
		ElementForBasement = Undefined;
		
		If CreatePeriodGroup Then
			FoundRows = PeriodsTable.FindRows(New Structure("Active_", True));
			If FoundRows.Count() > 1 Then
				FormItem = Form.Items.Add(CrossTableFormElement + "Group"+PeriodString_.ColumnName, Type("FormGroup"), 
					Form.Items[CrossTableFormElement]);
				FormItem.Group      = ColumnsGroup.Horizontal;
				FormItem.ShowInHeader = True;
				FormItem.Title        = PeriodString_.Title;
				
				FieldOwner = FormItem;
			Else
				FieldOwner = Form.Items[CrossTableFormElement];
			EndIf;
		EndIf;
		
		For Each FieldStructure In Fields Do
			ColumnAttributePrefix = FieldStructure.ColumnAttributePrefix;
			If FieldStructure.Property("CreateElement_") Then
				CreateElement_ = FieldStructure.CreateElement_;
			Else
				CreateElement_ = True;
			EndIf;
			If FieldStructure.Property("CreateSummaryDetails") Then
				CreateSummaryDetails = FieldStructure.CreateSummaryDetails;
			Else
				CreateSummaryDetails = False;
			EndIf;
			If FieldStructure.Property("ShowSummaryDetailsInPreviousElement") Then
				ShowSummaryDetailsInPreviousElement = FieldStructure.ShowSummaryDetailsInPreviousElement;
			Else
				ShowSummaryDetailsInPreviousElement = False;
			EndIf;
			If FieldStructure.Property("ShowSummaryDetailsInGroup") Then
				ShowSummaryDetailsInGroup = FieldStructure.ShowSummaryDetailsInGroup;
			Else
				ShowSummaryDetailsInGroup = False;
			EndIf;
			If FieldStructure.Property("ItemWidth") Then
				ItemWidth = FieldStructure.ItemWidth;
			Else
				ItemWidth = 6;
			EndIf;
			If FieldStructure.Property("StructureOfActions") Then
				StructureOfActions = FieldStructure.StructureOfActions;
			Else
				StructureOfActions = New Structure();
			EndIf;
			If FieldStructure.Property("TypeOfFormElement") Then
				TypeOfFormElement = FieldStructure.TypeOfFormElement;
			Else
				TypeOfFormElement = Type("FormField");
			EndIf;
			If FieldStructure.Property("FieldKind") Then
				FieldKind = FieldStructure.FieldKind;
			Else
				FieldKind = FormFieldType.InputField;
			EndIf;
			If FieldStructure.Property("GroupPrefix") Then
				ItemParent = Form.Items[CrossTableFormElement + FieldStructure.GroupPrefix + PeriodString_.ColumnName];
			Else
				ItemParent = FieldOwner;
			EndIf;
			
			If CreateElement_ Then
				// Re-linking the data
				// Creating Form elements
				Item = Form.Items.Add(CrossTableFormElement + ColumnAttributePrefix + PeriodString_.ColumnName, 
					TypeOfFormElement, ItemParent);
				Item.Type = FieldKind;
				If TypeOfFormElement = Type("FormField") Or TypeOfFormElement = Type("FormTable") Then
					Item.DataPath = NameOfCrossTableProps+"."+ColumnAttributePrefix + PeriodString_.ColumnName;
				EndIf;
				
				If Item.Type <> FormFieldType.CheckBoxField Then
					Item.Width = ItemWidth;
				EndIf; 
				If FieldStructure.Property("Title") Then
					If ValueIsFilled(FieldStructure.Title) Then
						Item.Title = FieldStructure.Title;
					Else
						Item.Title = PeriodString_.Title;
					EndIf;
				ElsIf FieldStructure.ColumnAttributePrefix = "Count_" Then
					Item.Title = PeriodString_.Title;
				Else
					Item.Title = StrReplace(FieldStructure.ColumnAttributePrefix, "_", " ") + PeriodString_.Title;
				EndIf;
				If FieldStructure.Property("ItemProperties") And TypeOf(FieldStructure.ItemProperties) = Type("Structure") Then
					FillPropertyValues(Item, FieldStructure.ItemProperties);
				EndIf; 
				For Each Action In StructureOfActions Do
					Item.SetAction(Action.Key, Action.Value);
				EndDo;
				
				ElementForBasement = Item;
			EndIf;
			
			If CreateSummaryDetails 
				And (CreateElement_ 
					Or ShowSummaryDetailsInPreviousElement 
					Or ShowSummaryDetailsInGroup) Then
				If (CreateElement_ Or ShowSummaryDetailsInPreviousElement) And ElementForBasement <> Undefined Then
					ElementForBasement.FooterDataPath = StrReplace(NameOfCrossTableProps + ColumnAttributePrefix + PeriodString_.ColumnName, ".","_");
				EndIf;
				
				If ShowSummaryDetailsInGroup 
					// And create a period group 
					And FieldOwner <> Undefined 
					And TypeOf(FieldOwner) = Type("FormGroup") 
					And FieldOwner.ShowInHeader Then
					If Not IsBlankString(FieldOwner.Title) Then
						FieldOwner.Title = FieldOwner.Title + ": ";
					EndIf; 
					FieldOwner.HeaderDataPath = StrReplace(NameOfCrossTableProps + ColumnAttributePrefix + PeriodString_.ColumnName, ".","_");
					FieldOwner.HeaderFormat = "NFD=2; NZ=0,00";
				EndIf;
			EndIf;
		EndDo;
		
	EndDo;
	
EndProcedure

// The procedure creates a detail in which the structure is saved with the values of the saved details.
//
// Parameters:
//  Form                  - ClientApplicationForm - form where you need to create a Bank account
//  NameOfVerificationDetails   - String - Name of the verification detail, an arbitrary name that is not used by other details of the form
//  ObjectAttributesNames - String - Names of object details whose values are stored in the verification details.
//
Procedure CreateChangeVerificationDetails(Form, Val NameOfVerificationDetails, Val ObjectAttributesNames) Export 

	TopLevelDetails = Form.GetAttributes();
	
	TypeDescriptionsAreUndefined = New TypeDescription();
	
	AttributesToBeAdded = New Array();
	
	PropsExist = False;
	For Each Attribute In TopLevelDetails Do
		If Attribute.Name = NameOfVerificationDetails Then
			PropsExist = True;
			Break;
		EndIf;
	EndDo;
	
	If Not PropsExist Then
		Attribute = New FormAttribute(NameOfVerificationDetails, TypeDescriptionsAreUndefined);
		AttributesToBeAdded.Add(Attribute);
		Form.ChangeAttributes(AttributesToBeAdded);
	EndIf;
	
	If TypeOf(Form[NameOfVerificationDetails]) <> Type("Structure") Then
	
		Form[NameOfVerificationDetails] = New Structure(ObjectAttributesNames);
	
	EndIf; 
	
EndProcedure

// The procedure checks whether the cross-table in the form is filled in
//
// Parameters:
//  Table              - ValueTable - cross-table where you need to check your Bank details
//  StructureOfActions    - Structure - Parameters, settings, and actions for checking the fill
//  Cancel                - Boolean - True if there are fill-in errors
//  CheckedAttributes - Array - check the details of the object
//  CrossTable         - Boolean - The sign of the cross table.
//
Procedure ProcessingFormFillVerification(Table, StructureOfActions, Cancel, CheckedAttributes, Val CrossTable = True) Export 
	
	If Not CrossTable Then
		Return;
	EndIf; 
	
	TablePresentation 	= StructureOfActions.TablePresentation;
	TablePath 			= StructureOfActions.TablePath;
	
	If Table.Count() = 0 Then
	
		MessageText = NStr("vi = 'Chưa điền danh sách ""%TablePresentation%""';
							|ru = 'Не заполнен список ""%TablePresentation%""';
							|en = 'List ""%TablePresentation%"" is not filled in'; fa = 'List ""%TablePresentation%"" is not filled in';
							|it = 'Elenco ""%TablePresentation%"" non è compilato';
							|pl = 'Nie jest wypełniona lista ""%TablePresentation%""';
							|tr = '""%TablePresentation%"" listesi doldurulmamış'");
		MessageText = StrReplace(MessageText, "%TablePresentation%",TablePresentation);
		
		CommonClientServer.MessageToUser(
			MessageText,
			,
			TablePath,
			,
			Cancel);
		Return;
	
	EndIf;
	
	FillInProducts_1        = False;
	FillInProductCategory   = False;
	FillInPartnerInTabularForm         = False;
	FillInAgreementInTabularForm       = False;
	FillInWarehouseInTabularForm            = False;
	FillInWHCharacteristic   = False;
	FillInConfigurationOption = False;
	FillInTheSpecification        = False;
	ProductErrorText 	= NStr("vi = 'Chưa điền cột ""Sản phẩm""';
								|ru = 'Не заполнена колонка ""Номенклатура""';
								|en = 'Column ""Items"" is not filled in'; fa = 'Column ""Items"" is not filled in';
								|it = 'La colonna ""articolo"" non è compilata';
								|pl = 'Nie wypełniono kolumny ""Номенклатура""';
								|tr = '""Ürün"" sütunu doldurulmadı'");
	ErrorTextProductCategory= NStr("vi = 'Chưa điền cột ""Danh mục sản phẩm""';
									|ru = 'Не заполнена колонка ""Товарная категория""';
									|en = 'Column ""Product category"" is not filled in'; fa = 'Column ""Product category"" is not filled in';
									|it = 'La colonna ""Categoria merceologica"" non è compilata';
									|pl = 'Nie wypełniono kolumny ""Товарная категория""';
									|tr = '""Ürün kategorisi"" sütunu doldurulmamış'");
	ErrorTextPartner 			= NStr("vi = 'Chưa điền cột ""%Partner%""';
										|ru = 'Не заполнена колонка ""%Partner%""';
										|en = 'Column ""%Partner%"" is not filled in'; fa = 'Column ""%Partner%"" is not filled in';
										|it = 'La colonna ""%Partner%"" non è compilata';
										|pl = 'Nie wypełniono kolumny ""%Partner%""';
										|tr = '""%Partner%"" sütunu doldurulmamış'");
	ErrorTextAgreement 		= NStr("vi = 'Chưa điền cột ""Thỏa thuận""';
										|ru = 'Не заполнена колонка ""Соглашение""';
										|en = 'Column ""Agreement"" is not filled in'; fa = 'Column ""Agreement"" is not filled in';
										|it = 'La colonna ""Accordo"" non è compilata';
										|pl = 'Nie wypełniono kolumny ""Соглашение""';
										|tr = '""Anlaşma"" sütunu doldurulmamış'");
	ErrorTextWarehouse 			= NStr("vi = 'Chưa điền cột ""Kho bãi"".';
											|ru = 'Не заполнена колонка ""Склад""';
											|en = 'Column ""Warehouse"" is not filled in'; fa = 'Column ""Warehouse"" is not filled in';
											|it = 'La colonna ""Magazzino"" non è compilata';
											|pl = 'Nie wypełniono kolumny ""Magazyn""';
											|tr = '""Ambar"" sütunu doldurulmadı'");
	ErrorTextCharacteristic	= NStr("vi = 'Chưa điền cột ""Đặc tính""';
										|ru = 'Не заполнена колонка ""Характеристика""';
										|en = 'Column ""Variant"" is not filled in'; fa = 'Column ""Variant"" is not filled in';
										|it = 'La colonna ""Caratteristica"" non è compilata';
										|pl = 'Nie wypełniono kolumny ""Характеристика""';
										|tr = '""Varyant"" sütunu doldurulmadı'");
	ErrorTextConfiguration     = NStr("vi = 'Chưa điền cột  ""Bộ sản phẩm""';
										|ru = 'Не заполнена колонка ""Комплектация""';
										|en = 'Column ""Product kit"" is not filled in'; fa = 'Column ""Product kit"" is not filled in';
										|it = 'La colonna ""Componentistica"" non è compilata';
										|pl = 'Nie wypełniono kolumny ""Комплектация""';
										|tr = '""Ürün Seti"" sütunu doldurulmamış'");
	ErrorTextSpecification 	= NStr("vi = 'Chưa điền cột ""Bảng chi tiết nguyên vật liệu""';
										|ru = 'Не заполнена колонка ""Спецификация""';
										|en = 'Column ""BOM"" is not filled in'; fa = 'Column ""BOM"" is not filled in';
										|it = 'La colonna ""Specifica"" non è compilata';
										|pl = 'Nie wypełniono kolumny ""Спецификация""';
										|tr = '""Ürün Reçetesi"" sütunu doldurulmadı'");
	ErrorAddressTemplate = " " + NStr("vi = 'trong dòng %LineNumber% danh sách ""%Goods%""';
										|ru = 'в строке %LineNumber% списка ""%Goods%""';
										|en = 'in line %LineNumber% of the ""%Goods%"" list'; fa = 'in line %LineNumber% of the ""%Goods%"" list';
										|it = 'nella riga %LineNumber% dell''elenco ""%Goods%""';
										|pl = 'w wierszu %LineNumber% listy ""%Goods%""';
										|tr = '""%Goods%"" listesinin %LineNumber% satırında'");
	
	If Not IsBlankString(TablePresentation) Then
		ErrorAddressTemplate = StrReplace(ErrorAddressTemplate, "%Goods%",TablePresentation);
	Else
		ErrorAddressTemplate = StrReplace(ErrorAddressTemplate, "%Goods%",NStr("vi = 'Hàng hóa';
																				|ru = 'Товары';
																				|en = 'Goods'; fa = 'کالاها';
																				|it = 'Merci';
																				|pl = 'Towary';
																				|tr = 'Ürünler'"));
	EndIf;
		
	ColumnName = "";
	If StructureOfActions.Property("FillInPartnerInTabularForm", ColumnName) Then
		If Not IsBlankString(ColumnName) Then
			ErrorTextPartner = StrReplace(ErrorTextPartner, "%Partner%",ColumnName);
		Else
			ErrorTextPartner = StrReplace(ErrorTextPartner, "%Partner%",NStr("vi = 'Bạn hàng';
																			|ru = 'Партнер';
																			|en = 'Partner'; fa = 'شریک تجاری';
																			|it = 'Partner';
																			|pl = 'Partner';
																			|tr = 'İş ortağı'"));
		EndIf; 
		FillInPartnerInTabularForm = True;
	EndIf; 
	
	If StructureOfActions.Property("FillInProducts_1") Then 
		FillInProducts_1 = True;
	EndIf;
	If StructureOfActions.Property("FillInProductCategory") Then 
		FillInProductCategory = True;
	EndIf;
	If StructureOfActions.Property("FillInAgreementInTabularForm") Then 
		FillInAgreementInTabularForm = True;
	EndIf; 
	If StructureOfActions.Property("FillInWarehouseInTabularForm") Then 
		FillInWarehouseInTabularForm = True;
	EndIf; 
	If StructureOfActions.Property("FillInWHCharacteristic") Then 
		FillInWHCharacteristic = True;
	EndIf; 
	If StructureOfActions.Property("FillInConfigurationOption") Then 
		FillInConfigurationOption = True;
	EndIf; 
	If StructureOfActions.Property("FillInTheSpecification") Then 
		FillInTheSpecification = StructureOfActions.FillInTheSpecification;
	EndIf; 
	QuantityVerificationParameters = Undefined;
	If StructureOfActions.Property("CheckingQuantityByPeriod", QuantityVerificationParameters) Then
		If QuantityVerificationParameters.TimeIntervals.Count() = 1 Then
			QuantityVerificationParameters.Insert("FieldName", QuantityVerificationParameters.FieldPrefix + QuantityVerificationParameters.TimeIntervals[0].ColumnName);
		EndIf; 
	EndIf;
	
	For Each TSRow In Table Do
		
		ErrorAddress = StrReplace(ErrorAddressTemplate,"%LineNumber%", TSRow.LineNumber);
		
		If FillInProducts_1 And Not ValueIsFilled(TSRow.Products) Then
			
			CommonClientServer.MessageToUser(
				ProductErrorText + ErrorAddress,
				,
				CommonClientServer.PathToTabularSection(TablePath, TSRow.LineNumber, "Products"),
				,
				Cancel);
			
		EndIf;
		If FillInProductCategory And Not ValueIsFilled(TSRow.ProductCategory) Then
			
			CommonClientServer.MessageToUser(
				ErrorTextProductCategory + ErrorAddress,
				,
				CommonClientServer.PathToTabularSection(TablePath, TSRow.LineNumber, "ProductCategory"),
				,
				Cancel);
			
		EndIf;
		If FillInPartnerInTabularForm And Not ValueIsFilled(TSRow.Partner) Then
			
			CommonClientServer.MessageToUser(
				ErrorTextPartner + ErrorAddress,
				,
				CommonClientServer.PathToTabularSection(TablePath, TSRow.LineNumber, "Partner"),
				,
				Cancel);
			
		EndIf;
		If FillInAgreementInTabularForm And Not ValueIsFilled(TSRow.Terms) Then
			
			CommonClientServer.MessageToUser(
				ErrorTextAgreement + ErrorAddress,
				,
				CommonClientServer.PathToTabularSection(TablePath, TSRow.LineNumber, "Terms"),
				,
				Cancel);
			
		EndIf;
		If FillInWarehouseInTabularForm 
			And Not ValueIsFilled(TSRow.Warehouse) 
			And (Not TSRow.Property("ItemsType") 
				Or TSRow.Property("ItemsType") 
				And (TSRow.ItemsType = Enums.ItemsTypes.OwnGoods 
					Or TSRow.ItemsType = Enums.ItemsTypes.ReusablePackage)) Then
			
			CommonClientServer.MessageToUser(
				ErrorTextWarehouse + ErrorAddress,
				,
				CommonClientServer.PathToTabularSection(TablePath, TSRow.LineNumber, "Warehouse"),
				,
				Cancel);
			
		EndIf;
		
		If FillInConfigurationOption And Not ValueIsFilled(TSRow.ProductKit) Then
			
			CommonClientServer.MessageToUser(
				ErrorTextConfiguration + ErrorAddress,
				,
				CommonClientServer.PathToTabularSection(TablePath, TSRow.LineNumber, "ProductKit"),
				,
				Cancel);
			
		EndIf;
		If FillInTheSpecification And Not ValueIsFilled(TSRow.BillOfMaterials) Then
			
			CommonClientServer.MessageToUser(
				ErrorTextSpecification + ErrorAddress,
				,
				CommonClientServer.PathToTabularSection(TablePath, TSRow.LineNumber, "BillOfMaterials"),
				,
				Cancel);
			
		EndIf;
		If StructureOfActions.Property("CheckingQuantityByPeriod") Then 
			
			ThereAreFilledLines = False;
			For Each Period In QuantityVerificationParameters.TimeIntervals Do
				ThereAreFilledLines = ValueIsFilled(TSRow[QuantityVerificationParameters.FieldPrefix + Period.ColumnName]);
				If ThereAreFilledLines Then
					Break;
				EndIf; 
			EndDo; 
			
			If Not ThereAreFilledLines Then
				
				TextOfQuantityError = NStr("vi = 'Chưa điền số lượng';
											|ru = 'Не заполнено количество';
											|en = 'Quantity is not filled in'; fa = 'Quantity is not filled in';
											|it = 'Quantità non compilata';
											|pl = 'Nie wypełniono ilości';
											|tr = 'Miktar doldurulmadı'");
				
				CommonClientServer.MessageToUser(
					TextOfQuantityError + ErrorAddress,
					,
					CommonClientServer.PathToTabularSection(TablePath, TSRow.LineNumber, QuantityVerificationParameters.FieldName),
					,
					Cancel);
			
			EndIf; 
		
		EndIf; 
	EndDo;
	
	UseCharacteristics = GetFunctionalOption("UseItemVariants");
	
	If FillInWHCharacteristic And UseCharacteristics Then
		
		Query = New Query;
		QueryText =
		"SELECT
		|	Goods.LineNumber AS LineNumber,
		|	CAST(Goods.Products AS Catalog.Products) AS Products,
		|	Goods.Characteristic AS Characteristic
		|INTO Errors
		|FROM
		|	&Table AS Goods
		|WHERE
		|	Goods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Errors.LineNumber,
		|	Errors.Products
		|FROM
		|	Errors AS Errors
		|WHERE
		|	Errors.Products.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems), VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))";
		
		Query.Text = QueryText;
		Query.SetParameter("Table",  Table.Unload(, "LineNumber, Products, Characteristic"));
				
		Result = Query.Execute();
		
		Selection = Result.Select();
		
		While Selection.Next() Do
			
			ErrorAddress = StrReplace(ErrorAddressTemplate,"%LineNumber%", Selection.LineNumber);
			
			CommonClientServer.MessageToUser(
				ErrorTextCharacteristic + ErrorAddress,
				,
				CommonClientServer.PathToTabularSection(TablePath, Selection.LineNumber, "Characteristic"),
				,
				Cancel);
		EndDo;
		
	EndIf; 

	HandlingStringDuplicationChecking(Table, TablePath, StructureOfActions.GroupFields, Cancel);
	
EndProcedure

// The procedure checks whether the table contains duplicates of rows by grouping fields
//
// Parameters:
//  Table              - FormDataCollection, TabularSection - cross-table or main table in which you need to check the Attributes:
//  TablePath         - String - The path to the table being checked
//  GroupFields      - String - grouping fields in the table
//  Cancel                - Boolean - True if there are fill-in errors
Procedure HandlingStringDuplicationChecking(Table, TablePath, GroupFields, Cancel) Export
	
	DuplicateRowValidationTable = Table.Unload(,GroupFields);
	DuplicateRowValidationTable.Columns.Add("NumberOfDuplicateRows", New TypeDescription("Number"));
	DuplicateRowValidationTable.FillValues(1,"NumberOfDuplicateRows");
	DuplicateRowValidationTable.GroupBy(GroupFields, "NumberOfDuplicateRows");
	For Each DuplicatesRow In DuplicateRowValidationTable Do
		If DuplicatesRow.NumberOfDuplicateRows > 1 Then
			TextOfQuantityError = NStr("vi = 'Đã tìm thấy các dòng trùng lặp theo các trường chính:';
										|ru = 'Найдены дублирующиеся по ключевым полям строки:';
										|en = 'Duplicate lines are found by key fields:'; fa = 'Duplicate lines are found by key fields:';
										|it = 'Righe trovate duplicate nei campi chiave:';
										|pl = 'Są znalezione dublowane wg pól kluczowych wierszy:';
										|tr = 'Anahtar satır alanlarına göre bulunan tekrarlananlar:'");
			                            
			Filter = New Structure(GroupFields);
			FillPropertyValues(Filter, DuplicatesRow);
						
			For Each String In Table.FindRows(Filter) Do
				TextOfQuantityError = TextOfQuantityError + " " + NStr("vi = 'dòng';
																		|ru = 'строка';
																		|en = 'string'; fa = 'string';
																		|it = 'riga';
																		|pl = 'wiersz';
																		|tr = 'satır'") + " " + String.LineNumber + ";";
			EndDo;
			
			ColumnName = Left(GroupFields,StrFind(GroupFields,",")-1);
				 
			CommonClientServer.MessageToUser(
				TextOfQuantityError,
				,
				CommonClientServer.PathToTabularSection(TablePath, String.LineNumber, ColumnName),
				,
				Cancel);
		EndIf;	
	EndDo;
	
EndProcedure	

// The procedure checks whether the document is filled in according to the scenario and type of plan
//
// Parameters:
//  Object               - DocumentObject - a document where you need to check the details for the scenario and type of plan
//  Cancel                - Boolean - True if there are fill-in errors
//  CheckedAttributes - Array - check the details of the object.
//
Procedure ProcessingFillVerificationByScenarioPlanType(Object, Cancel, CheckedAttributes) Export 

	If Not ValueIsFilled(Object.Scenario) Then
		Return;
	EndIf; 
	
	NotCheckedAttributeArray = New Array;
	
	ScriptDetails = "Periodicity, Currency, CreatePurchasePlanByAmount,
		|CreateSalesPlanByAmount, UseForMaterialsPlanning";
	ScriptParameters_ = Common.ObjectAttributesValues(Object.Scenario, ScriptDetails);
	
	If Object.Periodicity <> ScriptParameters_.Periodicity Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Định kỳ chứng từ không tương ứng với định kỳ kịch bản.';
				|ru = 'Периодичность документа не соответствует периодичности сценария.';
				|en = 'Document frequency does not correspond to the scenario frequency.'; fa = 'Document frequency does not correspond to the scenario frequency.';
				|it = 'La periodicità del documento non corrisponde alla periodicità di scenario.';
				|pl = 'Okresowość dokumentu nie odpowiada okresowości scenariusza.';
				|tr = 'Belgenin sıklığı senaryonun sıklığı ile eşleşmiyor.'"), Object, "Scenario",,Cancel);
	EndIf; 
	
	If TypeOf(Object) = Type("DocumentObject.PurchasePlan") Then
		
		If Object.PlanByAmount <> ScriptParameters_.CreatePurchasePlanByAmount Then
			CommonClientServer.MessageToUser(
				NStr("vi = 'Cài đặt lập kế hoạch cho số lượng và số tiền trong tài liệu không khớp với cài đặt kịch bản.';
					|ru = 'Настройка планирования по количеству и сумме в документе не соответствует настройке сценария.';
					|en = 'Setting of planning according to the quantity and document amount does not correspond to the script setting.'; fa = 'Setting of planning according to the quantity and document amount does not correspond to the script setting.';
					|it = 'Impostazione della pianificazione per quantità e importo nel documento non corrisponde all''impostazione di scenario.';
					|pl = 'Ustawienia planowania wg ilości i kwoty w dokumencie nie odpowiadają ustawieniu scenariusza.';
					|tr = 'Belgedeki sayının ve tutarın zamanlama ayarı senaryo ayarıyla eşleşmiyor.'"), Object, "Scenario",,Cancel);
		EndIf;
			
		If ScriptParameters_.CreatePurchasePlanByAmount And Object.Currency <> ScriptParameters_.Currency Then
			CommonClientServer.MessageToUser(
				NStr("vi = 'Tiền tệ trong chứng từ không khớp với tiền tệ kịch bản.';
					|ru = 'Валюта в документе не соответствует валюте сценария.';
					|en = 'The currency in the document does not match the scenario currency.'; fa = 'The currency in the document does not match the scenario currency.';
					|it = 'La valuta nel documento non corrisponde alla valuta di scenario.';
					|pl = 'Waluta w dokumencie nie odpowiada walucie scenariusza.';
					|tr = 'Belgedeki para birimi, senaryo para birimiyle uyuşmuyor.'"), Object, "Scenario",,Cancel);
		EndIf;
		
	ElsIf TypeOf(Object) = Type("DocumentObject.SalesPlan") Then
		
		If Object.PlanByAmount <> ScriptParameters_.CreateSalesPlanByAmount Then
			CommonClientServer.MessageToUser(
				NStr("vi = 'Cài đặt lập kế hoạch cho số lượng và số tiền trong tài liệu không khớp với cài đặt kịch bản.';
					|ru = 'Настройки планирования по количеству и сумме в документе не соответствует настройкам сценария.';
					|en = 'Settings of planning by quantity and amount in the document do not correspond to the script settings.'; fa = 'Settings of planning by quantity and amount in the document do not correspond to the script settings.';
					|it = 'Impostazioni della pianificazione per quantità e importo nel documento non corrispondono alle impostazioni di scenario.';
					|pl = 'Ustawienia planowania wg ilości i kwoty w dokumencie nie odpowiadają ustawieniom scenariusza.';
					|tr = 'Belgedeki sayının ve tutarın zamanlama ayarı senaryo ayarıyla eşleşmiyor.'"), Object, "Scenario",,Cancel);
		EndIf;
			
		If ScriptParameters_.CreateSalesPlanByAmount And Object.Currency <> ScriptParameters_.Currency Then
			CommonClientServer.MessageToUser(
				NStr("vi = 'Tiền tệ trong chứng từ không khớp với tiền tệ kịch bản.';
					|ru = 'Валюта в документе не соответствует валюте сценария.';
					|en = 'The currency in the document does not match the scenario currency.'; fa = 'The currency in the document does not match the scenario currency.';
					|it = 'La valuta nel documento non corrisponde alla valuta di scenario.';
					|pl = 'Waluta w dokumencie nie odpowiada walucie scenariusza.';
					|tr = 'Belgedeki para birimi, senaryo para birimiyle uyuşmuyor.'"), Object, "Scenario",,Cancel);
		EndIf;
	ElsIf TypeOf(Object) = Type("DocumentObject.ProductionPlan") Then
		
		If Not ScriptParameters_.UseForMaterialsPlanning Then
			NotCheckedAttributeArray.Add("ManufacturedProduct.BillOfMaterials");
		EndIf;
	EndIf; 
	
	If Not GetFunctionalOption("UseBusinessUnits") Then
		NotCheckedAttributeArray.Add("Department");
	EndIf;
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		NotCheckedAttributeArray.Add("Organization");
	EndIf;
	
	If ValueIsFilled(Object.PlanProfile) Then
		DetailsOfPlanType = "FillInBusinessUnit, FillInCompany, FillInPartner, FillInPartnerInTabularForm,
			|FillInTermsOfSales, FillInAgreementInTabularForm, FillInWarehouse,FillInWarehouseInTabularForm, FillInPaymentPlan,
			|FillInManager, FillInStoreFormat, FillInByShortage";
		PopulationSettings = Common.ObjectAttributesValues(Object.PlanProfile, DetailsOfPlanType);
			
		If TypeOf(Object) = Type("DocumentObject.PurchasePlan") Then
			If Not PopulationSettings.FillInBusinessUnit Then
				NotCheckedAttributeArray.Add("Department");
			EndIf;
			If Not PopulationSettings.FillInCompany Then
				NotCheckedAttributeArray.Add("Organization");
			EndIf;
			If Not PopulationSettings.FillInPartner Then
				NotCheckedAttributeArray.Add("Partner");
			EndIf;
			If Not PopulationSettings.FillInTermsOfSales Then
				NotCheckedAttributeArray.Add("Terms");
			EndIf;
			If Not PopulationSettings.FillInWarehouse Then
				NotCheckedAttributeArray.Add("Warehouse");
			EndIf;
			If Not PopulationSettings.FillInPartnerInTabularForm Or Object.CrossTable Then
				NotCheckedAttributeArray.Add("Goods.Partner");
			EndIf;
			If Not PopulationSettings.FillInAgreementInTabularForm Or Object.CrossTable Then
				NotCheckedAttributeArray.Add("Goods.Terms");
			EndIf;
			
			If PopulationSettings.FillInWarehouseInTabularForm And Not Object.CrossTable Then
				CheckParameters = New Structure("TSName, PresentationOfTS", "Goods", NStr("vi = 'Hàng hóa';
																							|ru = 'Товары';
																							|en = 'Goods'; fa = 'کالاها';
																							|it = 'Merci';
																							|pl = 'Towary';
																							|tr = 'Ürünler'"));
				CheckWhetherWarehouseIsFull(Object, Cancel, CheckParameters);
			EndIf;
			If Object.PlanByAmount And Object.FillInPaymentPlan <> PopulationSettings.FillInPaymentPlan Then
				CommonClientServer.MessageToUser(
					NStr("vi = 'Các cài đặt điền kế hoạch thanh toán trong chứng từ không khớp với tùy chỉnh dạng kế hoạch.';
						|ru = 'Настройки заполнения плана оплат в документе не соответствует настройкам вида плана.';
						|en = 'Settings of payment plan population in the document do not correspond to the plan profile settings.'; fa = 'Settings of payment plan population in the document do not correspond to the plan profile settings.';
						|it = 'Le impostazioni per la compilazione del piano di pagamenti nel documento non corrispondono alle impostazioni del tipo di piano.';
						|pl = 'Ustawienia wypełnienia planu płatności w dokumencie nie odpowiada ustawieniom rodzaju planu.';
						|tr = 'Belgedeki ödeme planı doldurma ayarları, plan profili ayarlarıyla uyuşmuyor.'"), 
					Object, 
					"PlanProfile",
					,
					Cancel);
			EndIf;
			
		ElsIf TypeOf(Object) = Type("DocumentObject.PlanOfGoodsStock") Then
			
			If Not PopulationSettings.FillInWarehouse Then
				NotCheckedAttributeArray.Add("Warehouse");
			EndIf;
			If PopulationSettings.FillInWarehouseInTabularForm And Not Object.CrossTable Then
				CheckParameters = New Structure("TSName, PresentationOfTS", "Goods", NStr("vi = 'Hàng hóa';
																							|ru = 'Товары';
																							|en = 'Goods'; fa = 'کالاها';
																							|it = 'Merci';
																							|pl = 'Towary';
																							|tr = 'Ürünler'"));
				CheckWhetherWarehouseIsFull(Object, Cancel, CheckParameters);
			EndIf;
			
		ElsIf TypeOf(Object) = Type("DocumentObject.SalesPlan") Then
			
			If Not PopulationSettings.FillInBusinessUnit Then
				NotCheckedAttributeArray.Add("Department");
			EndIf;
			If Not PopulationSettings.FillInCompany Then
				NotCheckedAttributeArray.Add("Organization");
			EndIf;
			If Not PopulationSettings.FillInPartner Then
				NotCheckedAttributeArray.Add("Partner");
			EndIf;
			If Not PopulationSettings.FillInTermsOfSales Then
				NotCheckedAttributeArray.Add("Terms");
			EndIf;
			If Not PopulationSettings.FillInWarehouse Then
				NotCheckedAttributeArray.Add("Warehouse");
			EndIf;
			If Not PopulationSettings.FillInManager Then
				NotCheckedAttributeArray.Add("Manager");
			EndIf;
			If Not PopulationSettings.FillInStoreFormat Then
				NotCheckedAttributeArray.Add("StoreFormat");
			EndIf;
			If Not PopulationSettings.FillInPartnerInTabularForm Or Object.CrossTable Then
				NotCheckedAttributeArray.Add("Goods.Partner");
			EndIf;
			If Not PopulationSettings.FillInAgreementInTabularForm Or Object.CrossTable Then
				NotCheckedAttributeArray.Add("Goods.Terms");
			EndIf;
			If PopulationSettings.FillInWarehouseInTabularForm And Not Object.CrossTable And Not Object.FillInByServiceData Then
				CheckParameters = New Structure("TSName, PresentationOfTS", "Goods", NStr("vi = 'Hàng hóa';
																							|ru = 'Товары';
																							|en = 'Goods'; fa = 'کالاها';
																							|it = 'Merci';
																							|pl = 'Towary';
																							|tr = 'Ürünler'"));
				CheckWhetherWarehouseIsFull(Object, Cancel, CheckParameters);
			EndIf;
			If Object.PlanByAmount And Object.FillInPaymentPlan <> PopulationSettings.FillInPaymentPlan Then
				CommonClientServer.MessageToUser(
					NStr("vi = 'Các cài đặt điền kế hoạch thanh toán trong chứng từ không khớp với tùy chỉnh dạng kế hoạch.';
						|ru = 'Настройки заполнения плана оплат в документе не соответствует настройкам вида плана.';
						|en = 'Settings of payment plan population in the document do not correspond to the plan profile settings.'; fa = 'Settings of payment plan population in the document do not correspond to the plan profile settings.';
						|it = 'Le impostazioni per la compilazione del piano di pagamenti nel documento non corrispondono alle impostazioni del tipo di piano.';
						|pl = 'Ustawienia wypełnienia planu płatności w dokumencie nie odpowiada ustawieniom rodzaju planu.';
						|tr = 'Belgedeki ödeme planı doldurma ayarları, plan profili ayarlarıyla uyuşmuyor.'"), 
					Object, 
					"PlanProfile",
					,
					Cancel);
			EndIf;
			
		ElsIf TypeOf(Object) = Type("DocumentObject.SalesPlanByCategories") Then
			If Not PopulationSettings.FillInBusinessUnit Then
				NotCheckedAttributeArray.Add("Department");
			EndIf;
			If Not PopulationSettings.FillInWarehouse Then
				NotCheckedAttributeArray.Add("Warehouse");
			EndIf;
			If Not PopulationSettings.FillInStoreFormat Then
				NotCheckedAttributeArray.Add("StoreFormat");
			EndIf;
			
		ElsIf TypeOf(Object) = Type("DocumentObject.AssemblyDisassemblyPlan") Then
			
			If Not PopulationSettings.FillInBusinessUnit Then
				NotCheckedAttributeArray.Add("Department");
			EndIf;
			If Not PopulationSettings.FillInWarehouse Then
				NotCheckedAttributeArray.Add("Warehouse");
			EndIf;
			If Not PopulationSettings.FillInWarehouseInTabularForm Or Object.CrossTable Then
				NotCheckedAttributeArray.Add("Goods.Warehouse");
			EndIf;
			
		ElsIf TypeOf(Object) = Type("DocumentObject.InventoryConsumptionPlan") Then
			
			If Not PopulationSettings.FillInBusinessUnit Then
				NotCheckedAttributeArray.Add("Department");
			EndIf;
			If Not PopulationSettings.FillInWarehouse Then
				NotCheckedAttributeArray.Add("Warehouse");
			EndIf;
			If PopulationSettings.FillInWarehouseInTabularForm And Not Object.CrossTable Then
				CheckParameters = New Structure("TSName, PresentationOfTS", "Goods", NStr("vi = 'Hàng hóa';
																							|ru = 'Товары';
																							|en = 'Goods'; fa = 'کالاها';
																							|it = 'Merci';
																							|pl = 'Towary';
																							|tr = 'Ürünler'"));
				CheckWhetherWarehouseIsFull(Object, Cancel, CheckParameters);
			EndIf;
			
			
		ElsIf TypeOf(Object) = Type("DocumentObject.ProductionPlan") Then
			
			If Not PopulationSettings.FillInBusinessUnit Then
				NotCheckedAttributeArray.Add("Department");
			EndIf;
			
		EndIf; 
		
		If PopulationSettings.FillInByShortage Then
			Query = New Query();
			Query.Text = 
			"SELECT TOP 1
			|	PurchasePlan.Ref AS Ref
			|FROM
			|	Document.PurchasePlan AS PurchasePlan
			|WHERE
			|	PurchasePlan.Ref <> &Ref
			|	AND PurchasePlan.PlanProfile = &PlanProfile
			|	AND PurchasePlan.BeginOfPeriod = &BeginOfPeriod
			|	AND PurchasePlan.PeriodEnding = &PeriodEnding
			|	AND PurchasePlan.Posted";
			Query.SetParameter("Ref", Object.Ref);
			Query.SetParameter("PlanProfile", Object.PlanProfile);
			Query.SetParameter("BeginOfPeriod", Object.BeginOfPeriod);
			Query.SetParameter("PeriodEnding", Object.PeriodEnding);
			
			If TypeOf(Object) = Type("DocumentObject.AssemblyDisassemblyPlan") Then
				Query.Text = StrReplace(Query.Text, "PurchasePlan", "AssemblyDisassemblyPlan");
			ElsIf TypeOf(Object) = Type("DocumentObject.ProductionPlan") Then
				Query.Text = StrReplace(Query.Text, "PurchasePlan", "ProductionPlan");
			EndIf;
			
			If Query.Execute().Unload().Count()>0 Then
				
				CommonClientServer.MessageToUser(
				NStr("vi = 'Trong dạng kế hoạch được điền theo thâm hụt, chỉ có thể tạo một kế hoạch cho mỗi giai đoạn.';
					|ru = 'В рамках вида плана, заполняемого по дефицитам, может быть создан только один план в периоде.';
					|en = 'Only one plan in the period can be created within the plan type filled in by shortages'; fa = 'Only one plan in the period can be created within the plan type filled in by shortages';
					|it = 'All''interno di un tipo di piano riempito per mancanze, è possibile creare un solo piano per periodo.';
					|pl = 'W ramach rodzaju planu, wypełnianego według niedoborów, może być utworzony tylko jeden plan w okresie.';
					|tr = 'Plan profili kapsamında mali açığa göre doldurulmasında bir dönem içerisinde sadece bir plan oluşturulabilir.'"),
				Object,
				,
				, 
				Cancel);
				
			EndIf;
			
		EndIf;
	EndIf; 
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);

EndProcedure

// Adds the "Quantity" cross-table field to the output parameters settings"
// 
// Parameters:
//  OutputParameters				 - Structure	 - The output parameters fields of the cross table
//  CreateElement_			 - Boolean		 - This flag determines whether to create a form element
//  ThereIsCommentGroupPrefix - Boolean		 - This flag determines whether to group comments with the images field
//  ThereIsTitle				 - Boolean		 - This flag determines whether the field has a header
//  StructureOfActions			 - Structure	 - The structure of the action item, the Key is the event name, value is the name of the procedure event handler.
Procedure AddQuantityCrossTableField(OutputParameters, CreateElement_ = True, 
	ThereIsCommentGroupPrefix = False, ThereIsTitle = True, StructureOfActions = Undefined) Export 

	If Not OutputParameters.Property("Fields") Then
		OutputParameters.Insert("Fields", New Array());
	EndIf;
	
	FieldStructure = New Structure;
	FieldStructure.Insert("ColumnAttributePrefix", "Count_");
	FieldStructure.Insert("DeleteTableDetails", True);
	If ThereIsCommentGroupPrefix Then
		FieldStructure.Insert("GroupPrefix", "GroupComment_");
	EndIf; 
	FieldStructure.Insert("CreateElement_", CreateElement_);
	FieldStructure.Insert("ElementType", "Number");
	If ThereIsTitle Then
		FieldStructure.Insert("Title", NStr("vi = 'Số lượng';
											|ru = 'Количество';
											|en = 'Quantity'; fa = 'مقدار';
											|it = 'Quantità';
											|pl = 'Ilość';
											|tr = 'Miktar'"));
	EndIf;
	FieldStructure.Insert("CreateSummaryDetails", True);
	FieldStructure.Insert("ItemWidth", 6);
	FieldStructure.Insert("ItemProperties", New Structure());
	FieldStructure.ItemProperties.Insert("MarkNegatives", True);
	
	If StructureOfActions <> Undefined Then
		FieldStructure.Insert("StructureOfActions", StructureOfActions);
	EndIf; 
	
	OutputParameters.Fields.Add(FieldStructure);

EndProcedure

// Adds the "Price" cross-table field to the output parameters settings"
//
// Parameters:
//  OutputParameters				 - Structure	 - The output parameters fields of the cross table
//  CreateElement_			 - Boolean		 - This flag determines whether to create a form element
//  ThereIsCommentGroupPrefix - Boolean		 - This flag determines whether to group comments with the images field
//  StructureOfActions			 - Structure	 - The structure of the action item, the Key is the event name, value is the name of the procedure event handler.
Procedure AddPriceCrossTableField(OutputParameters, CreateElement_ = True, ThereIsCommentGroupPrefix = False, StructureOfActions = Undefined) Export 

	If Not OutputParameters.Property("Fields") Then
		OutputParameters.Insert("Fields", New Array());
	EndIf;
	
	FieldStructure = New Structure;
	FieldStructure.Insert("ColumnAttributePrefix", "Price_");
	FieldStructure.Insert("DeleteTableDetails", True);
	If ThereIsCommentGroupPrefix Then
		FieldStructure.Insert("GroupPrefix", "GroupComment_");
	EndIf; 
	FieldStructure.Insert("CreateElement_", CreateElement_);
	FieldStructure.Insert("ElementType", TMCommonUse.MoneyFieldTypeDescription());
	FieldStructure.Insert("Title", NStr("vi = 'Đơn giá';
										|ru = 'Цена';
										|en = 'Price'; fa = 'قیمت';
										|it = 'Prezzo';
										|pl = 'Cena';
										|tr = 'Fiyat'"));
	FieldStructure.Insert("CreateSummaryDetails", False);
	FieldStructure.Insert("ItemWidth", 6);
	FieldStructure.Insert("ItemProperties", New Structure());
	FieldStructure.ItemProperties.Insert("MarkNegatives", True);
	
	If StructureOfActions <> Undefined Then
		FieldStructure.Insert("StructureOfActions", StructureOfActions);
	EndIf; 
	
	OutputParameters.Fields.Add(FieldStructure);

EndProcedure

// Adds the "Amount" cross-table field to the output parameters settings"
//
// Parameters:
//  OutputParameters				 - Structure	 - The output parameters fields of the cross table
//  CreateElement_			 - Boolean		 - This flag determines whether to create a form element
//  StructureOfActions			 - Structure	 - The structure of the action item, the Key is the event name, value is the name of the procedure event handler.
Procedure AddAmountCrossTableField(OutputParameters, CreateElement_ = True, ParametersOfAmountField, StructureOfActions = Undefined) Export 

	If Not OutputParameters.Property("Fields") Then
		OutputParameters.Insert("Fields", New Array());
	EndIf;
	
	FieldStructure = New Structure;
	FieldStructure.Insert("ColumnAttributePrefix", ParametersOfAmountField.Prefix);
	FieldStructure.Insert("DeleteTableDetails", True);
	FieldStructure.Insert("CreateElement_", CreateElement_);
	FieldStructure.Insert("ElementType", TMCommonUse.MoneyFieldTypeDescription());
	FieldStructure.Insert("Title", ParametersOfAmountField.Title);
	FieldStructure.Insert("CreateSummaryDetails", True);
	FieldStructure.Insert("ItemWidth", 6);
	FieldStructure.Insert("ItemProperties", New Structure());
	FieldStructure.ItemProperties.Insert("MarkNegatives", True);
	
	If StructureOfActions <> Undefined Then
		FieldStructure.Insert("StructureOfActions", StructureOfActions);
	EndIf; 
	
	OutputParameters.Fields.Add(FieldStructure);

EndProcedure

// Adds the "Comment" cross-table field to the output parameters settings"
//
// Parameters:
//  OutputParameters				 - Structure	 - The output parameters fields of the cross table
//  CreateElement_			 - Boolean		 - This flag determines whether to create a form element
//  StructureOfActions			 - Structure	 - The structure of the action item, the Key is the event name, value is the name of the procedure event handler.
Procedure AddCrossTableCommentField(OutputParameters, CreateElement_ = True, StructureOfActions = Undefined) Export 

	If Not OutputParameters.Property("Fields") Then
		OutputParameters.Insert("Fields", New Array());
	EndIf;
	
	FieldStructure = New Structure;
	FieldStructure.Insert("ColumnAttributePrefix", "Comment_");
	FieldStructure.Insert("GroupPrefix", "GroupComment_");
	FieldStructure.Insert("DeleteTableDetails", True);
	FieldStructure.Insert("CreateElement_", CreateElement_);
	FieldStructure.Insert("ElementType", New TypeDescription("String"));
	FieldStructure.Insert("Title", NStr("vi = 'Diễn giải';
										|ru = 'Комментарий';
										|en = 'Comment'; fa = 'توضیحات';
										|it = 'Commento';
										|pl = 'Komentarz';
										|tr = 'Yorum'"));
	FieldStructure.Insert("CreateSummaryDetails", False);
	FieldStructure.Insert("ItemWidth", 6);
	FieldStructure.Insert("ItemProperties", New Structure());
	FieldStructure.ItemProperties.Insert("ChoiceButton", True);
	FieldStructure.ItemProperties.Insert("MultiLine", True);
	FieldStructure.ItemProperties.Insert("Height", 1);
	
	If StructureOfActions <> Undefined Then
		FieldStructure.Insert("StructureOfActions", StructureOfActions);
	EndIf; 
	
	OutputParameters.Fields.Add(FieldStructure);

EndProcedure

// Adds the "Canceled" cross-table field to the output parameters settings"
//
// Parameters:
//  OutputParameters				 - Structure	 - The output parameters fields of the cross table
//  CreateElement_			 - Boolean		 - This flag determines whether to create a form element
//  StructureOfActions			 - Structure	 - The structure of the action item, the Key is the event name, value is the name of the procedure event handler.
Procedure AddCrossTableFieldCanceled(OutputParameters, CreateElement_ = True, StructureOfActions = Undefined) Export 

	If Not OutputParameters.Property("Fields") Then
		OutputParameters.Insert("Fields", New Array());
	EndIf;
	
	FieldStructure = New Structure;
	FieldStructure.Insert("ColumnAttributePrefix", "Canceled_");
	FieldStructure.Insert("DeleteTableDetails", True);
	FieldStructure.Insert("CreateElement_", CreateElement_);
	FieldStructure.Insert("ElementType", "Boolean");
	FieldStructure.Insert("FieldKind", FormFieldType.CheckBoxField);
	FieldStructure.Insert("Title", NStr("vi = 'Đã hủy bỏ';
										|ru = 'Отменено';
										|en = 'Canceled'; fa = 'لغوشده';
										|it = 'Annullato';
										|pl = 'Canceled';
										|tr = 'İptal edildi'"));
	FieldStructure.Insert("CreateSummaryDetails", False);
	
	If StructureOfActions <> Undefined Then
		FieldStructure.Insert("StructureOfActions", StructureOfActions);
	EndIf; 
	
	OutputParameters.Fields.Add(FieldStructure);

EndProcedure

// Adds the "Replaced" cross-table field to the output parameters settings"
//
// Parameters:
//  OutputParameters				 - Structure	 - The output parameters fields of the cross table
//  CreateElement_			 - Boolean		 - This flag determines whether to create a form element
//  StructureOfActions			 - Structure	 - The structure of the action item, the Key is the event name, value is the name of the procedure event handler.
Procedure AddReplacedCrossTableField(OutputParameters, CreateElement_ = True, StructureOfActions = Undefined) Export 

	If Not OutputParameters.Property("Fields") Then
		OutputParameters.Insert("Fields", New Array());
	EndIf;
	
	FieldStructure = New Structure;
	FieldStructure.Insert("ColumnAttributePrefix", "Substituted_");
	FieldStructure.Insert("DeleteTableDetails", True);
	FieldStructure.Insert("CreateElement_", CreateElement_);
	FieldStructure.Insert("ElementType", "Boolean");
	FieldStructure.Insert("FieldKind", FormFieldType.CheckBoxField);
	FieldStructure.Insert("Title", NStr("vi = 'Thay thế bởi';
										|ru = 'Замещен';
										|en = 'Substituted'; fa = 'جایگزین‌شده';
										|it = 'Sostituito';
										|pl = 'Zastąpiony';
										|tr = 'İkame edildi'"));
	FieldStructure.Insert("CreateSummaryDetails", False);
	FieldStructure.Insert("ItemProperties", New Structure());
	FieldStructure.ItemProperties.Insert("ReadOnly", True);
	
	If StructureOfActions <> Undefined Then
		FieldStructure.Insert("StructureOfActions", StructureOfActions);
	EndIf; 
	
	OutputParameters.Fields.Add(FieldStructure);

EndProcedure

// Adds the "replaced order" cross-table field to the output parameters settings"
//
// Parameters:
//  OutputParameters				 - Structure	 - The output parameters fields of the cross table
//  CreateElement_			 - Boolean		 - This flag determines whether to create a form element
//  StructureOfActions			 - Structure	 - The structure of the action item, the Key is the event name, value is the name of the procedure event handler.
Procedure AddReplacedToOrderCrossTableField(OutputParameters, CreateElement_ = True, StructureOfActions = Undefined) Export 

	If Not OutputParameters.Property("Fields") Then
		OutputParameters.Insert("Fields", New Array());
	EndIf;
	
	FieldStructure = New Structure;
	FieldStructure.Insert("ColumnAttributePrefix", "SubstitutedToOrder_");
	FieldStructure.Insert("DeleteTableDetails", True);
	FieldStructure.Insert("CreateElement_", CreateElement_);
	FieldStructure.Insert("ElementType", "Boolean");
	FieldStructure.Insert("FieldKind", FormFieldType.CheckBoxField);
	FieldStructure.Insert("Title", NStr("vi = 'Thay thế để đặt hàng';
										|ru = 'Замещен к заказу';
										|en = 'Substituted to order'; fa = 'جایگزین‌شده برای سفارش';
										|it = 'Sostituito all''ordine';
										|pl = 'Zastąpiony do zamówienia';
										|tr = 'Siparişe ikame edildi'"));
	FieldStructure.Insert("CreateSummaryDetails", False);
	FieldStructure.Insert("ItemProperties", New Structure());
	FieldStructure.ItemProperties.Insert("ReadOnly", True);
	
	If StructureOfActions <> Undefined Then
		FieldStructure.Insert("StructureOfActions", StructureOfActions);
	EndIf; 
	
	OutputParameters.Fields.Add(FieldStructure);

EndProcedure

// Adds the "comment group with picture" cross-table field to the output parameters settings.
//
// Parameters:
//  OutputParameters				 - Structure	 - The output parameters fields of the cross table
//  StructureOfActions			 - Structure	 - The structure of the action item, the Key is the event name, value is the name of the procedure event handler.
Procedure AddCrossTableFieldInCommentWithImage(OutputParameters, StructureOfActions = Undefined) Export 

	If Not OutputParameters.Property("Fields") Then
		OutputParameters.Insert("Fields", New Array());
	EndIf;
	
	FieldStructure = New Structure;
	FieldStructure.Insert("ColumnAttributePrefix", "GroupComment_");
	FieldStructure.Insert("CreateProps", False);
	FieldStructure.Insert("CreateElement_", True);
	FieldStructure.Insert("TypeOfFormElement", Type("FormGroup"));
	FieldStructure.Insert("FieldKind", FormGroupType.ColumnGroup);
	FieldStructure.Insert("ItemWidth", 8);
	FieldStructure.Insert("Title", "");
	FieldStructure.Insert("ItemProperties", New Structure());
	FieldStructure.ItemProperties.Insert("ShowInHeader", False);
	FieldStructure.ItemProperties.Insert("Group", ColumnsGroup.InCell);
	
	OutputParameters.Fields.Add(FieldStructure);
	
	FieldStructure = New Structure;
	FieldStructure.Insert("ColumnAttributePrefix", "PictureComment_");
	FieldStructure.Insert("DeleteTableDetails", True);
	FieldStructure.Insert("GroupPrefix", "GroupComment_");
	FieldStructure.Insert("CreateElement_", True);
	FieldStructure.Insert("FieldKind", FormFieldType.PictureField);
	FieldStructure.Insert("ElementType", TMCommonUse.GetDescriptionOfNumberTypes(1, 0));
	FieldStructure.Insert("Title", "");
	FieldStructure.Insert("CreateSummaryDetails", False);
	FieldStructure.Insert("ItemWidth", 1);
	FieldStructure.Insert("ItemProperties", New Structure());
	FieldStructure.ItemProperties.Insert("ReadOnly", True);
	FieldStructure.ItemProperties.Insert("ValuesPicture", PictureLib.CollectionComment);
	FieldStructure.ItemProperties.Insert("SkipOnInput", True);
	FieldStructure.ItemProperties.Insert("ShowInHeader", False);
	FieldStructure.ItemProperties.Insert("ShowInFooter", False);
	FieldStructure.ItemProperties.Insert("HorizontalStretch", False);
	FieldStructure.ItemProperties.Insert("VerticalStretch", False);
	FieldStructure.ItemProperties.Insert("Border", New Border(ControlBorderType.WithoutBorder));
	
	If StructureOfActions <> Undefined Then
		FieldStructure.Insert("StructureOfActions", StructureOfActions);
	EndIf; 
	
	OutputParameters.Fields.Add(FieldStructure);

EndProcedure

// Adds the "decryption" cross-table field to the output parameter settings.
//
// Parameters:
//  OutputParameters				 - Structure	 - The output parameters fields of the cross table
//  StructureOfActions			 - Structure	 - The structure of the action item, the Key is the event name, value is the name of the procedure event handler.
Procedure AddTranscriptCrossTableField(OutputParameters, StructureOfActions = Undefined) Export 

	If Not OutputParameters.Property("Fields") Then
		OutputParameters.Insert("Fields", New Array());
	EndIf;
	
	FieldStructure = New Structure;
	FieldStructure.Insert("ColumnAttributePrefix", "Details_");
	FieldStructure.Insert("CreateProps", True);
	FieldStructure.Insert("CreateElement_", False);
	FieldStructure.Insert("DeleteTableDetails", True);
	FieldStructure.Insert("ElementType", New TypeDescription("String"));
	FieldStructure.Insert("FieldKind", FormFieldType.LabelField);
	FieldStructure.Insert("ItemWidth", 1);
	FieldStructure.Insert("Title", "");
	FieldStructure.Insert("CreateSummaryDetails", False);
	FieldStructure.Insert("ItemProperties", New Structure());
	
	OutputParameters.Fields.Add(FieldStructure);
	
EndProcedure

// Fill in the table from the cross-table and transfer values from the cross-table columns to the table details.
//
// Parameters:
//  ThisObjectIsTable    - TabularSection, FormDataCollection - 
//  TableObject_        - TabularSection, FormDataCollection - Table part of the object
//  CrossTable         - TabularSection - Cross-table in the form
//  Parameters            - Structure - Additional settings passed to the procedure:
//                                     * TablePeriods See TablePeriods
//                                     * StructureOfPeriodDetails - Structure -
//                                     * AttributesStructure1 - Structure -
//  StructureOfActions    - Structure - Structure of actions performed with PM strings
//  CachedValues - Structure - Cached value.
//  SemiFinishedProductsByDate - TabularSection - table part of semi-finished products
//
Procedure FillInTableFromCrossTable(ThisObjectIsTable, TableObject_, CrossTable, Parameters, StructureOfActions = Undefined, 
	CachedValues = Undefined, SemiFinishedProductsByDate = Undefined) Export
	
	TablePeriods             = Parameters.TablePeriods;
	StructureOfPeriodDetails = Parameters.StructureOfPeriodDetails;
	AttributesStructure1        = Parameters.AttributesStructure1;
	
	If StructureOfActions = Undefined Then
		StructureOfActions = New Structure;
	EndIf;
	
	ArrayOfRowsThisObjectIsTable = New Array;
	ArrayOfRowsTableObject     = New Array;
	
	NewRowStructureThisObjectIsTable = New Structure();
	For Each Column In ThisObjectIsTable.Unload().Columns Do
		NewRowStructureThisObjectIsTable.Insert(Column.Name);
	EndDo;
	NewRowStructureObjectTable = New Structure();
	For Each Column In TableObject_.Unload().Columns Do
		NewRowStructureObjectTable.Insert(Column.Name);
	EndDo;
		
	For Each CrossTableRow In CrossTable Do
		
		If SemiFinishedProductsByDate <> Undefined 
			And CrossTableRow.SemiFinishedProduct Then
			Continue;
		EndIf;
		
		For Each StringPeriod In TablePeriods Do
			
			If Not StringPeriod.Active_
				Or StringPeriod.ColumnNumber = 0 Then
				Continue 
			EndIf;
			
			NewRowObjectTable = Common.CopyRecursive(NewRowStructureObjectTable);
			FillPropertyValues(NewRowObjectTable,CrossTableRow);
			
			If TableObject_ <> ThisObjectIsTable Then
				NewRowThisObjectIsTable = Common.CopyRecursive(NewRowStructureThisObjectIsTable);
				FillPropertyValues(NewRowThisObjectIsTable,CrossTableRow);
			EndIf;
			
			For Each Item In StructureOfPeriodDetails Do
				
				NewRowObjectTable[Item.Value] = StringPeriod[Item.Key];
				If TableObject_ <> ThisObjectIsTable Then
					NewRowThisObjectIsTable[Item.Value] = StringPeriod[Item.Key];
				EndIf;
			EndDo;
			
			For Each Item In AttributesStructure1 Do
				If NewRowStructureObjectTable.Property(Item.Value) Then
					NewRowObjectTable[Item.Value] = CrossTableRow[Item.Key + StringPeriod.ColumnName];
				EndIf;
				If TableObject_ <> ThisObjectIsTable
					And NewRowStructureThisObjectIsTable.Property(Item.Value) Then
					NewRowThisObjectIsTable[Item.Value] = CrossTableRow[Item.Key + StringPeriod.ColumnName];
				EndIf;
			EndDo;
			
			If Not AttributesStructure1.Property("Formula_")
				And AttributesStructure1.Property("Count_") And NewRowObjectTable[AttributesStructure1["Count_"]] = 0 Then
				Continue;
			EndIf;
			
			ArrayOfRowsTableObject.Add(NewRowObjectTable);
			If TableObject_ <> ThisObjectIsTable Then
				ArrayOfRowsThisObjectIsTable.Add(NewRowThisObjectIsTable);
			EndIf;
		
		EndDo;
		
	EndDo;
	
	If SemiFinishedProductsByDate <> Undefined Then
		
		For Each CrossTableRow In SemiFinishedProductsByDate Do
			
			For Each StringPeriod In TablePeriods Do
				
				If Not StringPeriod.Active_
					Or StringPeriod.ColumnNumber = 0 Then
					Continue 
				EndIf;
				
				FillPropertyValues(NewRowStructureThisObjectIsTable,CrossTableRow);
				FillPropertyValues(NewRowStructureObjectTable,CrossTableRow);
				
				For Each Item In StructureOfPeriodDetails Do
						NewRowStructureThisObjectIsTable[Item.Value] = StringPeriod[Item.Key];
						NewRowStructureObjectTable[Item.Value] = StringPeriod[Item.Key];
					
				EndDo;
				
				For Each Item In AttributesStructure1 Do
					If NewRowStructureThisObjectIsTable.Property(Item.Value) Then
						NewRowStructureThisObjectIsTable[Item.Value] = CrossTableRow[Item.Key + StringPeriod.ColumnName];
					EndIf;
					If NewRowStructureObjectTable.Property(Item.Value) Then
						NewRowStructureObjectTable[Item.Value] = CrossTableRow[Item.Key + StringPeriod.ColumnName];
					EndIf;
				EndDo;
				
				If NewRowStructureObjectTable.NumberOfPackages <> 0 Then
					NewRowObjectTable = Common.CopyRecursive(NewRowStructureObjectTable);
					FillPropertyValues(NewRowObjectTable, NewRowStructureObjectTable);
					If TableObject_ <> ThisObjectIsTable Then
						NewRowThisObjectIsTable = Common.CopyRecursive(NewRowStructureThisObjectIsTable);
						FillPropertyValues(NewRowThisObjectIsTable, NewRowStructureThisObjectIsTable);
						ArrayOfRowsThisObjectIsTable.Add(NewRowThisObjectIsTable);
					EndIf;
					ArrayOfRowsTableObject.Add(NewRowObjectTable);
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	ThisObjectIsTable.Clear();
	For Each String In ArrayOfRowsThisObjectIsTable Do
		FillPropertyValues(ThisObjectIsTable.Add(), String);
	EndDo;
	TableObject_.Clear();
	For Each String In ArrayOfRowsTableObject Do
		FillPropertyValues(TableObject_.Add(), String);
	EndDo;
	
	BatchProcessingOfTablePartServer.TreatTS(
		ThisObjectIsTable, StructureOfActions, CachedValues);
	
	BatchProcessingOfTablePartServer.TreatTS(
		TableObject_, StructureOfActions, CachedValues);
	
EndProcedure 

#EndRegion

#Region ObjectEventProcedures

// Procedure called from the event handler of the same name for the plan object form.
//
// Parameters:
//  Form - ClientApplicationForm - The Form from whose event handler the procedure is called:
//	 * Object - DocumentObject.PurchasePlan - 
// 	          - DocumentObject.PlanOfGoodsStock -
// 	          - DocumentObject.SalesPlan -
// 	          - DocumentObject.SalesPlanByCategories -
// 	          - DocumentObject.ProductionPlan -
// 	          - DocumentObject.AssemblyDisassemblyPlan -
//  see the reference information on managed form events.
//  Cancel - Boolean
//  StandardProcessing - Boolean
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	// The fill rules were not received when reading on the server.
	If Not IsTempStorageURL(Form.FillingRuleAddress) Then
		
		If ValueIsFilled(Form.Parameters.CopyingValue) Then
			Form.FillingRuleAddress = PutToTempStorage(
				Form.Parameters.CopyingValue.FillingRule.Unload(),
				Form.UUID);
		Else
			DocumentObject = Form.FormAttributeToValue("Object");
			Form.FillingRuleAddress = PutToTempStorage(
				DocumentObject.FillingRule.Unload(),
				Form.UUID);
		EndIf;
		
	EndIf;
	
	// User settings were not received when reading on the server.
	If Not IsTempStorageURL(Form.CustomSettingsAddress) Then
		
		If ValueIsFilled(Form.Parameters.CopyingValue) Then
			UserSettingsStorage = Form.Parameters.CopyingValue.UserSettings;// ValueStorage
			
			Form.CustomSettingsAddress = PutToTempStorage(
				UserSettingsStorage.Get(),
				Form.UUID);
		Else
			If DocumentObject = Undefined Then
			
				DocumentObject = Form.FormAttributeToValue("Object");
			
			EndIf;
			
			UserSettingsStorage = DocumentObject.UserSettings;// ValueStorage
			
			Form.CustomSettingsAddress = PutToTempStorage(
				UserSettingsStorage.Get(),
				Form.UUID);
		EndIf;
		
	EndIf;
	
	If TypeOf(Form.Object.Ref) = Type("DocumentRef.PurchasePlan") Then
		Form.PlanType = Enums.TypesOfPlans.PurchasePlan;
	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.PlanOfGoodsStock") Then
		Form.PlanType = Enums.TypesOfPlans.PlanOfGoodsStock;
	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.SalesPlan") Then
		Form.PlanType = Enums.TypesOfPlans.SalesPlan;
	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.InventoryConsumptionPlan") Then
		Form.PlanType = Enums.TypesOfPlans.InventoryConsumptionPlan;
	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.SalesPlanByCategories") Then
		Form.PlanType = Enums.TypesOfPlans.SalesPlanByCategories;
	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.AssemblyDisassemblyPlan") Then
		Form.PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan;
	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.ProductionPlan") Then
		Form.PlanType = Enums.TypesOfPlans.ProductionPlan;
	EndIf;
	
	If Not ValueIsFilled(Form.Object.Ref) Then
		OnReadCreateAtServer(Form);
	EndIf;
	
EndProcedure

// Procedure called from the event handler of the same name for the plan object form.
//
// Parameters:
//  Form         - ClientApplicationForm - The Form from whose event handler the procedure is called,
//                                               see the background information on events of the managed Form.
//  CurrentObject - DocumentObject - 
//
Procedure OnReadAtServer(Form, CurrentObject) Export 
	
	// Getting the fill rule and user settings from the object
	Form.FillingRuleAddress = PutToTempStorage(
		CurrentObject.FillingRule.Unload(),
		Form.UUID);
	Form.CustomSettingsAddress = PutToTempStorage(
		CurrentObject.UserSettings.Get(),
		Form.UUID);
	
	OnReadCreateAtServer(Form);
	
EndProcedure

// An overridable procedure called from the form event handler of the same name.
//
// Parameters:
//  Form           - ClientApplicationForm - THE Form from whose event handler the procedure is called.
//                                                 see the background information on events of the managed Form.
//  Cancel           - Boolean - 
//  CurrentObject   - DocumentObject - 
//  WriteParameters - Structure - 
//
Procedure BeforeWriteAtServer(Form, Cancel, CurrentObject, WriteParameters) Export
	
	If IsTempStorageURL(Form.FillingRuleAddress) Then
		CurrentObject.FillingRule.Load(GetFromTempStorage(Form.FillingRuleAddress));
	EndIf;
	If IsTempStorageURL(Form.CustomSettingsAddress) Then
		CurrentObject.UserSettings = New ValueStorage(GetFromTempStorage(Form.CustomSettingsAddress));
	EndIf;
	
	If TypeOf(Form.SettingsStructure) = Type("Structure") Then
		CurrentObject.SettingsStructure = New ValueStorage(Form.SettingsStructure);
	EndIf;
	
EndProcedure

#EndRegion

#Region SourcePlanningProcedures

// The function processes all sources of the fill rule and returns the final result.
//
// Parameters:
//  PlanType                  - EnumRef.TypesOfPlans - Type of plan, such as purchase Plan, sales Plan, etc.
//  FillInRuleObject   - ValueTable - The TS of an object containing a fill-in rule:
//                                  * Source - CatalogRef.PlanningDataSources - 
//  UserSettings - DataCompositionUserSettings - user settings for the plan document
//  AdditionalParameters   - Structure - Additional parameters used when retrieving data from sources.
//
// Returns:
//   ValueTable   - A table of summary data converted according to the rules from various sources.
//
Function SelectDataByRules(Val PlanType, Val FillInRuleObject, UserSettings, AdditionalParameters = Undefined) Export 
	
	Var Result;
	
	SetPrivilegedMode(True);
	
	If TypeOf(FillInRuleObject) <> Type("ValueTable") Then
		FillingRule = FillInRuleObject.Unload();
	Else
		FillingRule = FillInRuleObject; 
	EndIf;
	
	FillingRule.Columns.Add("DataSelected", New TypeDescription("Boolean"));
	FillingRule.Columns.Add("DataSet");
	FillingRule.Columns.Add("DataCompositionSettingsComposer");
	
	NewLineFillRule = FillingRule.Add();
	NewLineFillRule.DataSelected = False;
	NewLineFillRule.DataSet = Undefined;
	NewLineFillRule.LineNumber = 0;
	NewLineFillRule.RowNumberParent = 99999;
	NewLineFillRule.TransformationOption = Enums.ConversionOptions.Addition;
	NewLineFillRule.Source = Catalogs.PlanningDataSources.EmptyRef();
	NewLineFillRule.ElementType = 1;
	NewLineFillRule.Use = True;
	NewLineFillRule.Exclude = False;
	NewLineFillRule.UserSettings = Undefined;
	NewLineFillRule.Period = Undefined;
	NewLineFillRule.Date = Undefined;
	NewLineFillRule.Attach = False;
	
	FillingRule.Sort("ElementType, RowNumberParent, LineNumber");
	
	// Setting the usage attribute.
	AllRulesAreProcessed = False;
	
	While Not AllRulesAreProcessed Do
		
		AllRulesAreProcessed = True;
		
		For Each FillRuleElement In FillingRule Do
			
			If FillRuleElement.ElementType = 1 Then
				
				// Disabling the use of subordinates hosted in a disabled parent.
				FoundRows = FillingRule.FindRows(New Structure("RowNumberParent, Use", FillRuleElement.LineNumber, True));
				
				If Not FillRuleElement.Use Then
					
					For Each FoundRow In FoundRows Do
						
						FoundRow.Use = False;
						AllRulesAreProcessed = False;
						
					EndDo;
					
				Else
					
					If FoundRows.Count() = 0 Then
						
						FillRuleElement.Use = False;
						AllRulesAreProcessed = False;
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	FillInAssignmentInTabularForm = Common.ObjectAttributeValue(AdditionalParameters.DataParameters.PlanProfile, "FillInAssignmentInTabularForm");
	
	// Processing conversion rules
	AllRulesAreProcessed = False;
	
	While Not AllRulesAreProcessed Do
		
		AllRulesAreProcessed = True;
		
		For Each FillRuleElement In FillingRule Do
			
			If Not FillRuleElement.DataSelected And FillRuleElement.Use Then
				
				AllRulesAreProcessed = False;
				
				If FillRuleElement.ElementType = 0 Then
					
					DataSourceParameters = New Structure;
					DataSourceParameters.Insert("PlanningDataSource", 	FillRuleElement.Source);
					DataSourceParameters.Insert("Exclude", 						FillRuleElement.Exclude);
					DataSourceParameters.Insert("ChangeResultTo", 			FillRuleElement.ChangeResultTo);
					
					PeriodStorage = FillRuleElement.Period;// ValueStorage
					DateStorage = FillRuleElement.Date;// ValueStorage
					AdditionalSourceParameters = New Structure("Period, Date", PeriodStorage.Get(), DateStorage.Get());
					If AdditionalParameters <> Undefined Then
						If  AdditionalParameters.Property("DataParameters") Then
							AdditionalSourceParameters.Insert("DataParameters", AdditionalParameters.DataParameters);
						EndIf;
						If AdditionalParameters.Property("Filter") Then
							AdditionalSourceParameters.Insert("Filter", AdditionalParameters.Filter);
						EndIf;
						If AdditionalParameters.Property("Top25") Then
							AdditionalSourceParameters.Insert("Top25", AdditionalParameters.Top25);
						EndIf;
					EndIf;
					
					UserSettingsStorage = FillRuleElement.UserSettings;// ValueStorage
					
					DataCompositionSettingsComposer = Undefined;
					FillRuleElement.DataSet = Catalogs.PlanningDataSources.SubstringData(
						DataSourceParameters, 
						UserSettingsStorage.Get(), 
						AdditionalSourceParameters, 
						DataCompositionSettingsComposer);
					FillRuleElement.DataSelected = True;
					FillRuleElement.DataCompositionSettingsComposer = DataCompositionSettingsComposer;
					
				Else
					Filter = New Structure;
					Filter.Insert("RowNumberParent", FillRuleElement.LineNumber);
					Filter.Insert("Use",       True);
					Filter.Insert("DataSelected",       False);
					Filter.Insert("Attach",        False);
					FoundRows = FillingRule.FindRows(Filter);
					If FoundRows.Count() = 0 Then
						
						FoundRows = FillingRule.FindRows(New Structure("RowNumberParent, Use, DataSelected", 
							FillRuleElement.LineNumber, True, True));
						
						ConversionRule_ = New Structure;
						ConversionRule_.Insert("TransformationOption", FillRuleElement.TransformationOption); 
						ConversionRule_.Insert("Exclude",             FillRuleElement.Exclude);
						ConversionRule_.Insert("Attach",          FillRuleElement.Attach);
						ConversionRule_.Insert("TopLevel",        FillRuleElement.RowNumberParent = 99999);
						
						If FillRuleElement.RowNumberParent = 99999 Then
							
							FillRuleElement.DataSet = ConvertData_(PlanType, FoundRows, ConversionRule_, 
								UserSettings, AdditionalParameters, FillInAssignmentInTabularForm);
							Result = FillRuleElement.DataSet;
							
						Else
							
							FillRuleElement.DataSet = ConvertData_(PlanType, FoundRows, ConversionRule_,,,FillInAssignmentInTabularForm);
							FillRuleElement.DataCompositionSettingsComposer = FoundRows[0].DataCompositionSettingsComposer;
							
						EndIf;
						
						FillRuleElement.DataSelected = True;
					EndIf;
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

// The function gets the values of script details
//
// Parameters:
//  Scenario  - CatalogRef.SalesOperationsPlanningScenarios - Link to the planning scenario
//  Parameters - Structure - the variable to which values are returned for the details of the scenario.
//
// Returns:
//   Structure   - Values of script parameters.
//
Function GetScriptParameters(Scenario, Parameters = Undefined) Export 

	Attributes = Common.ObjectAttributesValues(Scenario, "Currency, Periodicity");
	If Parameters = Undefined Then
		Parameters = New Structure;
	EndIf;
	Parameters.Insert("Scenario", Scenario);
	For Each Attribute In Attributes Do
		Parameters.Insert(Attribute.Key, Attribute.Value);
	EndDo;
	
	Return Parameters;

EndFunction

// The function returns all parameters of the plan document as a structure
//
// Parameters:
//  Object                - DocumentObject - Plan document
//  Parameters - Structure - the variable to which values are returned for the details of the scenario.
//
// Returns:
//   Structure   - Values of script parameters.
//
Function GetPlanParameters(Object, Parameters = Undefined) Export 
	
	If Parameters = Undefined Then
		Parameters = New Structure();
		Parameters.Insert("Ref");
		Parameters.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
		Parameters.Insert("Organization", Catalogs.Companies.EmptyRef());
		Parameters.Insert("StoreFormat", Catalogs.StoreFormats.EmptyRef());
		Parameters.Insert("Warehouse", Catalogs.Warehouses.EmptyRef());
		Parameters.Insert("Partner", Catalogs.Partners.EmptyRef());
		Parameters.Insert("Terms");
		Parameters.Insert("Status");
		Parameters.Insert("Periodicity");
		Parameters.Insert("BeginOfPeriod");
		Parameters.Insert("PeriodEnding");
		Parameters.Insert("EmployeeResponsible", Catalogs.Users.EmptyRef());
		Parameters.Insert("Manager", Catalogs.Users.EmptyRef());
		Parameters.Insert("PlanProfile", Catalogs.PlanProfiles.EmptyRef());
		Parameters.Insert("Purpose", Catalogs.Assignments.EmptyRef());
	EndIf;
	FillPropertyValues(Parameters, Object);
	GetScriptParameters(Object.Scenario, Parameters);
	
	Return Parameters;

EndFunction

// The function puts the data transformation schema in the value store and returns the address.
//
// Parameters:
//  PlanType                  - EnumRef.TypesOfPlans - Type of plan, such as purchase Plan, sales Plan, etc.
//  UUID   - UUID - a unique identifier that the schema address is returned to.
//  FillInAssignmentInTabularForm - Boolean
//
// Returns:
//   String - the address of the temporary value store.
//
Function GetAddressOfDataConversionScheme(Val PlanType, Val UUID, FillInAssignmentInTabularForm = False) Export 

	AddressOfDataConversionScheme = "";
	DataLayoutSchemeTransformation = GetDataConversionScheme(PlanType,,FillInAssignmentInTabularForm);
	
	AddressOfDataConversionScheme = PutToTempStorage(DataLayoutSchemeTransformation, UUID);
	
	Return AddressOfDataConversionScheme;
	
EndFunction

#EndRegion

#Region ProceduresForFillingThemInUsingFormulas

// Forms the structure of additional banking details
//
// Parameters:
//  Parameters	 - Structure - Values of additional details.
// 
// Returns:
//  Structure - The structure of additional details.
//
Function AdditionalParametersForFormulaCalculation(Parameters) Export
	
	TableFormElement_ 		= Parameters.TableFormElement_;
	Scenario					= Parameters.ScenarioDetails;
	PlanProfile					= Parameters.TypeOfPlanDetails;
	CreateFormElements		= Parameters.CreateFormElements;
	AttributePath1				= Parameters.AttributePath1;
	ThisIsASalesPlanByCategory	= PlanProfile.PlanType = Enums.TypesOfPlans.SalesPlanByCategories;
	ThisIsTheRemainderPlan 			= PlanProfile.PlanType = Enums.TypesOfPlans.PlanOfGoodsStock;
	FillInAssignmentInTabularForm		= PlanProfile.FillInAssignmentInTabularForm;
	
	UseSalesPlans_ 	= GetFunctionalOption("UseSalesPlans")
								  And Scenario.UseInSalesPlanning;
	UseProcurementPlans 	= GetFunctionalOption("UsePurchasePlanning")
								  And Scenario.UseInPurchasePlanning;
	UseProductionPlanning 	= GetFunctionalOption("UseProductionPlanning")
											  And Scenario.UseInProductionPlanning;
	UseForMaterialsPlanning 	= GetFunctionalOption("UseProductionPlanning")
											  And Scenario.UseForMaterialsPlanning;
	UseBuildPlans 				= GetFunctionalOption("UseAssemblyDisassemblyPlanning")
											  And Scenario.UseInAssemblyDisassemblyPlanning;
	UseInternalConsumptionPlans 	= GetFunctionalOption("UsePlanningOfInventoryConsumption")
											  And Scenario.UseInPlanningOfInternalConsumption;
	
	UseExpensePlans = UseSalesPlans_
							Or UseForMaterialsPlanning
							Or UseBuildPlans
	
							Or UseInternalConsumptionPlans;
	
	UseParishPlans = UseProcurementPlans 
							Or UseProductionPlanning
							Or UseBuildPlans;
	
	CreatePropsWithSelection = PlanProfile.FillInPartner 
		Or PlanProfile.FillInStoreFormat 
		Or PlanProfile.FillInWarehouse 
		Or PlanProfile.FillInBusinessUnit
		Or PlanProfile.FillInCompany
		Or (Scenario.PlanningByAssignments And Not PlanProfile.FillInAssignmentInTabularForm);
	
	If CreateFormElements Then
		FormGroupAdditionalParametersFormula	 = Parameters.FormGroupAdditionalParametersFormula;
		GroupOfAdmissionFormParametersDeviation= Parameters.GroupOfAdmissionFormParametersDeviation;
		FormGroupAdditionalParameters			 = Parameters.FormGroupAdditionalParameters; // See StructureGroupFormsAdditionalParameters
	EndIf;
	
	AddlParameters 		= New Structure();
	
#Region ExpensePlans
	// Properties of the form's props
	AddnlParameter_ 		= New Structure();
	AddnlParameter_.Insert("Name", 				"ExpensePlans");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Tất cả khoản chi dự tính';
													|ru = 'Весь планируемый расход';
													|en = 'All planned expenses'; fa = 'All planned expenses';
													|it = 'Tutta la spesa programmata';
													|pl = 'Całe planowane rozchody';
													|tr = 'Planlanan giderin tümü'"));
	AddnlParameter_.Insert("CreateProps", 	UseExpensePlans);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// Properties of the operand
	AddnlParameter_.Insert("CreateOperand", 	UseExpensePlans);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Tất cả khoản chi dự tính';
													|ru = 'Весь планируемый расход';
													|en = 'All planned expenses'; fa = 'All planned expenses';
													|it = 'Tutta la spesa programmata';
													|pl = 'Całe planowane rozchody';
													|tr = 'Planlanan giderin tümü'"));
	AddnlParameter_.Insert("IncludedInOperand",		"MainOperands");
	
	AddlParameters.Insert("ExpensePlans",AddnlParameter_);
#EndRegion
	
#Region ExpensePlansWithSelection
	// Properties of the form's props
	AddnlParameter_ 		= New Structure();
	AddnlParameter_.Insert("Name", 				"ExpensePlansWithSelection");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Tất cả khoản chi dự tính*';
													|ru = 'Весь планируемый расход*';
													|en = 'All planned expenses*'; fa = 'All planned expenses*';
													|it = 'Tutta la spesa programmata*';
													|pl = 'Całe planowane rozchody*';
													|tr = 'Planlanan giderin tümü*'"));
	AddnlParameter_.Insert("CreateProps", 	CreatePropsWithSelection And UseExpensePlans);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// Properties of the operand
	AddnlParameter_.Insert("CreateOperand", 	CreatePropsWithSelection And UseExpensePlans);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Tất cả khoản chi dự tính*';
													|ru = 'Весь планируемый расход*';
													|en = 'All planned expenses*'; fa = 'All planned expenses*';
													|it = 'Tutta la spesa programmata*';
													|pl = 'Całe planowane rozchody*';
													|tr = 'Planlanan giderin tümü*'"));
	AddnlParameter_.Insert("IncludedInOperand",		"BasicOperandsWithSelection");
	
	AddlParameters.Insert("ExpensePlansWithSelection",AddnlParameter_);
#EndRegion
	
#Region ParishPlans
	// Properties of the form's props
	AddnlParameter_ 		= New Structure();
	AddnlParameter_.Insert("Name", 				"ParishPlans");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Tất cả khoản thu dự tính';
													|ru = 'Весь планируемый приход';
													|en = 'All planned receipt'; fa = 'All planned receipt';
													|it = 'Tutti gli introiti programmati';
													|pl = 'Całe planowane przychody';
													|tr = 'Planlanan gelirin tümü'"));
	AddnlParameter_.Insert("CreateProps",	UseParishPlans);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// Properties of the operand
	AddnlParameter_.Insert("CreateOperand", 	UseParishPlans);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Tất cả khoản thu dự tính';
													|ru = 'Весь планируемый приход';
													|en = 'All planned receipt'; fa = 'All planned receipt';
													|it = 'Tutti gli introiti programmati';
													|pl = 'Całe planowane przychody';
													|tr = 'Planlanan gelirin tümü'"));
	AddnlParameter_.Insert("IncludedInOperand",		"MainOperands");
	
	AddlParameters.Insert("ParishPlans",AddnlParameter_);
#EndRegion
	
#Region ParishPlansWithSelection
	// Properties of the form's props
	AddnlParameter_ 		= New Structure();
	AddnlParameter_.Insert("Name", 				"ParishPlansWithSelection");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Tất cả khoản thu dự tính*';
													|ru = 'Весь планируемый приход*';
													|en = 'All planned receipt*'; fa = 'All planned receipt*';
													|it = 'Tutti gli introiti programmati*';
													|pl = 'Całe planowane przychody*';
													|tr = 'Planlanan gelirin tümü*'"));
	AddnlParameter_.Insert("CreateProps", 	CreatePropsWithSelection And UseParishPlans);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// Properties of the operand
	AddnlParameter_.Insert("CreateOperand", 	CreatePropsWithSelection And UseParishPlans);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Tất cả khoản thu dự tính*';
													|ru = 'Весь планируемый приход*';
													|en = 'All planned receipt*'; fa = 'All planned receipt*';
													|it = 'Tutti gli introiti programmati*';
													|pl = 'Całe planowane przychody*';
													|tr = 'Planlanan gelirin tümü*'"));
	AddnlParameter_.Insert("IncludedInOperand",		"BasicOperandsWithSelection");
	
	AddlParameters.Insert("ParishPlansWithSelection",AddnlParameter_);
#EndRegion

#Region AdjustmentsToPlannedDemands
	// Properties of the form's props
	AddnlParameter_ 		= New Structure();
	AddnlParameter_.Insert("Name", 				"AdjustmentsToPlannedDemands");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Điều chỉnh nhu cầu nội bộ dự tính';
													|ru = 'Корректировки плановых потребностей';
													|en = 'Planned demand adjustments'; fa = 'اصلاحات تقاضای برنامه‌ریزی‌شده';
													|it = 'Rettifiche dei fabbisogni pianificati';
													|pl = 'Korekty planowanych potrzeb';
													|tr = 'Planlanan gereksinimlerde yapılan düzeltilmeler'"));
	AddnlParameter_.Insert("CreateProps", 	UseExpensePlans);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// Properties of the operand
	AddnlParameter_.Insert("CreateOperand", 	UseExpensePlans);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Điều chỉnh nhu cầu nội bộ dự tính';
													|ru = 'Корректировки плановых потребностей';
													|en = 'Planned demand adjustments'; fa = 'اصلاحات تقاضای برنامه‌ریزی‌شده';
													|it = 'Rettifiche dei fabbisogni pianificati';
													|pl = 'Korekty planowanych potrzeb';
													|tr = 'Planlanan gereksinimlerde yapılan düzeltilmeler'"));
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsPlans");
	
	AddlParameters.Insert("AdjustmentsToPlannedDemands", AddnlParameter_);
#EndRegion
	
#Region AdjustmentsToPlannedDemandsWithSelection
	// Properties of the form's props
	AddnlParameter_ 		= New Structure();
	AddnlParameter_.Insert("Name", 				"AdjustmentsToPlannedDemandsWithSelection");
	AddnlParameter_.Insert("Type", 				New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 				AttributePath1);
	AddnlParameter_.Insert("Title", 			NStr("vi = 'Điều chỉnh kế hoạch nhu cầu*';
													|ru = 'Корректировки плановых потребностей*';
													|en = 'Planned demand adjustments*'; fa = 'Planned demand adjustments*';
													|it = 'Correzioni dei fabbisogni pianificati*';
													|pl = 'Korekty planowanych potrzeb*';
													|tr = 'Planlanan gereksinimlerde yapılan düzeltilmeler*'"));
	AddnlParameter_.Insert("CreateProps", 	CreatePropsWithSelection And UseExpensePlans);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// Properties of the operand
	AddnlParameter_.Insert("CreateOperand", 	CreatePropsWithSelection And UseExpensePlans);
	AddnlParameter_.Insert("OperandHeader", 	NStr("vi = 'Điều chỉnh kế hoạch nhu cầu*';
													|ru = 'Корректировки плановых потребностей*';
													|en = 'Planned demand adjustments*'; fa = 'Planned demand adjustments*';
													|it = 'Correzioni dei fabbisogni pianificati*';
													|pl = 'Korekty planowanych potrzeb*';
													|tr = 'Planlanan gereksinimlerde yapılan düzeltilmeler*'"));
	AddnlParameter_.Insert("IncludedInOperand",		"AdditionalOperandsAreAssociatedWithSelection");
	
	AddlParameters.Insert("AdjustmentsToPlannedDemandsWithSelection", AddnlParameter_);
#EndRegion

	Documents.SalesPlanByCategories.AdditionalParametersForFormulaCalculation(Parameters, AddlParameters);
	Documents.SalesPlan.AdditionalParametersForFormulaCalculation(Parameters, AddlParameters);
	Documents.InventoryConsumptionPlan.AdditionalParametersForFormulaCalculation(Parameters, AddlParameters);
	If GetFunctionalOption("UseProduction") Then
		Documents.ProductionPlan.AdditionalParametersForFormulaCalculation(Parameters, AddlParameters);
	EndIf;
	If GetFunctionalOption("UseAssemblyDisassembly") Then
		Documents.AssemblyDisassemblyPlan.AdditionalParametersForFormulaCalculation(Parameters, AddlParameters);
	EndIf;
	Documents.PurchasePlan.AdditionalParametersForFormulaCalculation(Parameters, AddlParameters);
	Documents.PlanOfGoodsStock.AdditionalParametersForFormulaCalculation(Parameters, AddlParameters);
	
#Region Formula
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 			"Formula");
	AddnlParameter_.Insert("Type", 			New TypeDescription("String"));
	AddnlParameter_.Insert("Path", 			AttributePath1);
	AddnlParameter_.Insert("Title", 		NStr("vi = 'Công thức';
												|ru = 'Формула';
												|en = 'Formula'; fa = 'فرمول';
												|it = 'Formula';
												|pl = 'Formula';
												|tr = 'Formül'"));
	AddnlParameter_.Insert("CreateProps", True);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	// General property
	AddnlParameter_.Insert("CreateOperand", False);
	AddnlParameter_.Insert("OperandHeader", NStr("vi = 'Công thức';
												|ru = 'Формула';
												|en = 'Formula'; fa = 'فرمول';
												|it = 'Formula';
												|pl = 'Formula';
												|tr = 'Formül'"));
	
	AddlParameters.Insert("Formula", AddnlParameter_);
#EndRegion
	
#Region FormulaCalculation
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 			"FormulaCalculation");
	AddnlParameter_.Insert("Type", 			New TypeDescription("String"));
	AddnlParameter_.Insert("Path", 			AttributePath1);
	AddnlParameter_.Insert("Title", 		NStr("vi = 'Công thức';
												|ru = 'Формула';
												|en = 'Formula'; fa = 'فرمول';
												|it = 'Formula';
												|pl = 'Formula';
												|tr = 'Formül'"));
	AddnlParameter_.Insert("CreateProps", True);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	If CreateFormElements Then
		// Form Element Properties
		AddnlParameter_.Insert("TagName", 			TableFormElement_ + AddnlParameter_.Name);
		AddnlParameter_.Insert("ElementType", 			Type("FormField"));
		AddnlParameter_.Insert("Parent", 				FormGroupAdditionalParameters.Name);
		AddnlParameter_.Insert("Kind", 					"LabelField");
		AddnlParameter_.Insert("DataPath", 			?(IsBlankString(AttributePath1), "", AttributePath1 + ".") + AddnlParameter_.Name);
		AddnlParameter_.Insert("CreateElement_", 		True);
		
		//Action
		StructureOfActions = New Structure();
		StructureOfActions.Insert("Click", 		"Attachable_SetArbitraryFormula");
		AddnlParameter_.Insert("StructureOfActions", StructureOfActions);
	EndIf;
	
	// General property
	AddnlParameter_.Insert("CreateOperand", False);
	AddnlParameter_.Insert("OperandHeader", NStr("vi = 'Tính toán';
												|ru = 'Вычисление';
												|en = 'Calculation'; fa = 'محاسبه';
												|it = 'Calcolo';
												|pl = 'Calculation';
												|tr = 'Hesaplama'"));
	
	AddlParameters.Insert("FormulaCalculation", AddnlParameter_);
#EndRegion

#Region FormulaPresentation
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 			"FormulaPresentation");
	AddnlParameter_.Insert("Type", 			New TypeDescription("String"));
	AddnlParameter_.Insert("Path", 			AttributePath1);
	AddnlParameter_.Insert("Title", 		NStr("vi = 'Công thức';
												|ru = 'Формула';
												|en = 'Formula'; fa = 'فرمول';
												|it = 'Formula';
												|pl = 'Formula';
												|tr = 'Formül'"));
	AddnlParameter_.Insert("CreateProps", True);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	If CreateFormElements Then
		// Form Element Properties
		AddnlParameter_.Insert("TagName", 		TableFormElement_ + AddnlParameter_.Name);
		AddnlParameter_.Insert("ElementType", 		Type("FormField"));
		AddnlParameter_.Insert("Parent", 			FormGroupAdditionalParametersFormula.Name);
		AddnlParameter_.Insert("Kind", 				"InputField");
		AddnlParameter_.Insert("DataPath", 		?(IsBlankString(AttributePath1), "", AttributePath1 + ".") + AddnlParameter_.Name);
		AddnlParameter_.Insert("HeaderPicture", 		PictureLib.Change);
		AddnlParameter_.Insert("TextEdit",False);
		AddnlParameter_.Insert("ReadOnly", 		False);
		AddnlParameter_.Insert("CreateElement_", 	FormGroupAdditionalParametersFormula.Kind = FormGroupType.ColumnGroup);
		AddnlParameter_.Insert("Width", 				10);
		AddnlParameter_.Insert("OpenButton", 		True);
		AddnlParameter_.Insert("ChoiceButton", 		False);
		
		//Action
		StructureOfActions = New Structure();
		StructureOfActions.Insert("Opening", 		"Attachable_SetArbitraryFormula");
		AddnlParameter_.Insert("StructureOfActions", StructureOfActions);
	EndIf;
	
	// General property
	AddnlParameter_.Insert("CreateOperand", False);
	AddnlParameter_.Insert("OperandHeader", NStr("vi = 'Công thức';
												|ru = 'Формула';
												|en = 'Formula'; fa = 'فرمول';
												|it = 'Formula';
												|pl = 'Formula';
												|tr = 'Formül'"));
	
	AddlParameters.Insert("FormulaPresentation", AddnlParameter_);
#EndRegion
	
#Region Deviation	
	// Properties of the form's props
	AddnlParameter_ = New Structure();
	AddnlParameter_.Insert("Name", 			"Deviation");
	AddnlParameter_.Insert("Type", 			New TypeDescription("Number", New NumberQualifiers(15, 3)));
	AddnlParameter_.Insert("Path", 			AttributePath1);
	AddnlParameter_.Insert("Title", 		NStr("vi = 'Phương sai từ công thức';
												|ru = 'Отклонение от формулы';
												|en = 'Variance from formula'; fa = 'Variance from formula';
												|it = 'Scostamento dalla formula';
												|pl = 'Odchylenie od formuły';
												|tr = 'Formüllerden fark'"));
	AddnlParameter_.Insert("CreateProps", True);
	AddnlParameter_.Insert("DeleteTableDetails", True);
	
	If CreateFormElements Then
		// Form Element Properties
		AddnlParameter_.Insert("TagName", 		TableFormElement_ + AddnlParameter_.Name);
		AddnlParameter_.Insert("ElementType", 		Type("FormField"));
		AddnlParameter_.Insert("Parent", 			GroupOfAdmissionFormParametersDeviation.Name);
		AddnlParameter_.Insert("Kind", 				"InputField");
		AddnlParameter_.Insert("DataPath", 		?(IsBlankString(AttributePath1), "", AttributePath1 + ".") + AddnlParameter_.Name);
		AddnlParameter_.Insert("HeaderPicture", 		New Picture());
		AddnlParameter_.Insert("TextEdit",False);
		AddnlParameter_.Insert("ReadOnly", 		GroupOfAdmissionFormParametersDeviation.Kind = FormGroupType.UsualGroup);
		AddnlParameter_.Insert("CreateElement_",	True);
		AddnlParameter_.Insert("Width", 				10);
		AddnlParameter_.Insert("OpenButton", 		False);
		AddnlParameter_.Insert("ChoiceButton", 		False);
	EndIf;
	
	// General property
	AddnlParameter_.Insert("CreateOperand", False);
	AddnlParameter_.Insert("OperandHeader", NStr("vi = 'Phương sai từ công thức';
												|ru = 'Отклонение от формулы';
												|en = 'Variance from formula'; fa = 'Variance from formula';
												|it = 'Scostamento dalla formula';
												|pl = 'Odchylenie od formuły';
												|tr = 'Formüllerden fark'"));
	
	AddlParameters.Insert("Deviation", AddnlParameter_);
#EndRegion
	
	Return AddlParameters;
	
EndFunction

// Creates an additional details form
//
// Parameters:
// Form             - ClientApplicationForm - the form of the document
// Parameters         - Structure - Values of additional details.
//
Procedure UpdateTableOutputStructure(Form, Parameters) Export

	AttributesToBeAdded = New Array();
	AttributesToBeDeleted 	 = New Array();
	
	For Each FieldStructure In Parameters.Fields Do
		
		FieldStructure = FieldStructure.Value; // See FieldStructure
		
		DetailsOfPlanTable = Form.GetAttributes(FieldStructure.Path);
		
		// Deleting bank details
		For Each Attribute In DetailsOfPlanTable Do
			If Attribute.Name = FieldStructure.Name Then
				AttributesToBeDeleted.Add(?(IsBlankString(FieldStructure.Path), "" ,FieldStructure.Path + ".") + FieldStructure.Name);
			EndIf;
		EndDo;
		
		// Adding details
		If FieldStructure.CreateProps Then
			Attribute = New FormAttribute(FieldStructure.Name, FieldStructure.Type, FieldStructure.Path, FieldStructure.Title);
			AttributesToBeAdded.Add(Attribute);
		EndIf;
		
		// Deleting Elements
		If FieldStructure.Property("TagName") Then
			ItemToRemove = Form.Items.Find(FieldStructure.TagName);
		Else
			ItemToRemove = Undefined;
		EndIf;
		
		If ItemToRemove <> Undefined Then
			Form.Items.Delete(ItemToRemove);
		EndIf;
		
	EndDo;
	
	Form.ChangeAttributes(AttributesToBeAdded, AttributesToBeDeleted);
	
	// Creating Elements
	For Each FieldStructure In Parameters.Fields Do
		
		FieldStructure = FieldStructure.Value; // See FieldStructure
		If FieldStructure.Property("CreateElement_") And FieldStructure.CreateElement_ Then
			
			Parent = Form.Items[FieldStructure.Parent];
			FormItem = Form.Items.Add(FieldStructure.TagName, FieldStructure.ElementType, Parent); // FormField, FormFieldExtensionForALabelField - 
			If FieldStructure.Kind = "LabelField" Then
				FormItem.Type = FormFieldType.LabelField;
				FormItem.Hyperlink = True;
				FillPropertyValues(FormItem, FieldStructure, "Title,DataPath");
			Else
				FormItem.Type = FormFieldType.InputField;
				FillPropertyValues(FormItem, FieldStructure, "Title,DataPath,HeaderPicture,Width,OpenButton,ChoiceButton,TextEdit,ReadOnly");
			EndIf;
			
			If FieldStructure.Property("StructureOfActions") Then
				For Each Action In FieldStructure.StructureOfActions Do
					FormItem.SetAction(Action.Key, Action.Value);
				EndDo; 
			EndIf;
			
		EndIf;
		
	EndDo; 
	
EndProcedure

// Returns:
// 	Structure - LongDesc:
// * ElementType - Type - 
// * IncludedInOperand - Boolean - 
// * OperandHeader - String -
// * CreateOperand - Boolean -
// * DeleteTableDetails - Boolean -
// * CreateProps - Boolean -
// * Title - String -
// * Path - String -
// * Kind - String -
// * Type - TypeDescription - 
// * Name - String -
Function FieldStructure() Export
	
	FieldStructure = New Structure();
	FieldStructure.Insert("Name");
	FieldStructure.Insert("Type");
	FieldStructure.Insert("Kind");
	FieldStructure.Insert("Path");
	FieldStructure.Insert("Title");
	FieldStructure.Insert("CreateProps");
	FieldStructure.Insert("DeleteTableDetails");
	FieldStructure.Insert("CreateOperand");
	FieldStructure.Insert("OperandHeader");
	FieldStructure.Insert("IncludedInOperand");
	FieldStructure.Insert("ElementType");
	
	Return FieldStructure
	
EndFunction

// Returns:
// 	Structure - LongDesc:
// * Title - String -
// * ValueColumn_ - String -
Function StructureOfAdditionalField() Export
	
	StructureOfAdditionalField = New Structure();
	StructureOfAdditionalField.Insert("Title");
	StructureOfAdditionalField.Insert("ValueColumn_");
	
	Return StructureOfAdditionalField
	
EndFunction

// Returns:
// 	Structure - LongDesc:
// * Kind - FormGroupType - 
// * Name - String -
Function StructureGroupFormsAdditionalParameters(Name, Kind)
	
	FieldStructure = New Structure();
	FieldStructure.Insert("Name", Name);
	FieldStructure.Insert("Kind", Kind);
	
	Return FieldStructure
	
EndFunction

// Initializing the operator tree
//
// Parameters:
// Tree             - ValueTree - the value tree.
//
Procedure InitializeOperatorTrees(Tree) Export
	
	GroupPresentation = NStr("vi = 'Toán tử';
							|ru = 'Операторы';
							|en = 'Operators'; fa = 'عملگرها';
							|it = 'Operatori';
							|pl = 'Operatory';
							|tr = 'Operatörler'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "Operators", GroupPresentation);
	
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "+", " + ", "+");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "-", " - ", "-");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "*", " * ", "*");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "/", " / ", "/");
	
	GroupPresentation = NStr("vi = 'Toán tử lo-gic và hằng';
							|ru = 'Логические операторы и константы';
							|en = 'Logical operators and constants'; fa = 'Logical operators and constants';
							|it = 'Operatori logici e costanti';
							|pl = 'Operatory logiczne i konstanty';
							|tr = 'Mantıksal operatörler ve sabitler'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "LogicalOperatorsAndConstants", GroupPresentation);
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "<",  " < ",  "<");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, ">",  " > ",  ">");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "<=", " <= ", "<=");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, ">=", " >= ", ">=");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "=",  " = ",  "=");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, "<>", " <> ", "<>");
	
	Id = "And";
	StructureToInsert = " " + "And" + " ";
	Presentation = NStr("vi = 'VÀ';
						|ru = 'И';
						|en = 'AND'; fa = 'و';
						|it = 'E';
						|pl = 'ORAZ';
						|tr = 'AND'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	Id = "OR";
	StructureToInsert = " " + "OR" + " ";
	Presentation = NStr("vi = 'HOẶC';
						|ru = 'ИЛИ';
						|en = 'OR'; fa = 'یا';
						|it = 'OPPURE';
						|pl = 'LUB';
						|tr = 'OR'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	Id = "NOT";
	StructureToInsert = " " + "NOT" + " ";
	Presentation = NStr("vi = 'KHÔNG';
						|ru = 'НЕ';
						|en = 'NOT'; fa = 'NOT';
						|it = 'NON';
						|pl = 'NIE';
						|tr = 'NOT'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	Id = "TRUE";
	StructureToInsert = " " + "TRUE" + " ";
	Presentation = NStr("vi = 'ĐÚNG';
						|ru = 'ИСТИНА';
						|en = 'TRUE'; fa = 'TRUE';
						|it = 'VERO';
						|pl = 'PRAWDA';
						|tr = 'TRUE'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	Id = "FALSE";
	StructureToInsert = " " + "FALSE" + " ";
	Presentation = NStr("vi = 'SAI';
						|ru = 'ЛОЖЬ';
						|en = 'FALSE'; fa = 'FALSE';
						|it = 'FALSO';
						|pl = 'FAŁSZ';
						|tr = 'FALSE'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
	GroupPresentation = NStr("vi = 'Chức năng';
							|ru = 'Функции';
							|en = 'Functions'; fa = 'توابع';
							|it = 'Funzioni';
							|pl = 'Funkcje';
							|tr = 'İşlevler'");
	OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(Tree, "Functions", GroupPresentation);
	
	Id = "Max";
	ParameterPresentation1 = NStr("vi = '<Giá trị 1>';
									|ru = '<Значение 1>';
									|en = '<Value 1>'; fa = '<Value 1>';
									|it = '<Valore 1>';
									|pl = '<Wartość 1>';
									|tr = '<Değer 1>'");
	ParameterPresentation2 = NStr("vi = '<Giá trị 2>';
									|ru = '<Значение 2>';
									|en = '<Value 2>'; fa = '<Value 2>';
									|it = '<Valore 2>';
									|pl = '<Wartość 2>';
									|tr = '<Değer 2>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"Max(%1, %2)",
		ParameterPresentation1,
		ParameterPresentation2);
	Presentation = NStr("vi = 'Tối đa';
						|ru = 'Максимум';
						|en = 'Maximum'; fa = 'حداکثر';
						|it = 'Massimo';
						|pl = 'Maksimum';
						|tr = 'Maksimum'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 2);
	
	Id = "Min";
	ParameterPresentation1 = NStr("vi = '<Giá trị 1>';
									|ru = '<Значение 1>';
									|en = '<Value 1>'; fa = '<Value 1>';
									|it = '<Valore 1>';
									|pl = '<Wartość 1>';
									|tr = '<Değer 1>'");
	ParameterPresentation2 = NStr("vi = '<Giá trị 2>';
									|ru = '<Значение 2>';
									|en = '<Value 2>'; fa = '<Value 2>';
									|it = '<Valore 2>';
									|pl = '<Wartość 2>';
									|tr = '<Değer 2>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"Min(%1, %2)",
		ParameterPresentation1,
		ParameterPresentation2);
	Presentation = NStr("vi = 'Tối thiểu';
						|ru = 'Минимум';
						|en = 'Minimum'; fa = 'حداقل';
						|it = 'Minimo';
						|pl = 'Minimum';
						|tr = 'Minimum'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 2);
	
	Id = "Round";
	ParameterPresentation1 = NStr("vi = '<Giá trị làm tròn>';
									|ru = '<Округляемое значение>';
									|en = '<Round value>'; fa = '<Round value>';
									|it = '<Valore da arrotondare>';
									|pl = '<Wartość zaokrąglana>';
									|tr = '<Yuvarlanmış değer>'");
	ParameterPresentation2 = NStr("vi = '<Số lượng ký tự sau dấu phẩy>';
									|ru = '<Количество знаков после запятой>';
									|en = '<Decimal places>'; fa = '<Decimal places>';
									|it = '<Numero di caratteri dopo la virgola>';
									|pl = '<Liczba znaków po przecinku>';
									|tr = '<Virgülden sonraki işaretlerin sayısı>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"Round(%1, %2)",
		ParameterPresentation1,
		ParameterPresentation2);
	Presentation = NStr("vi = 'Làm tròn';
						|ru = 'Округление';
						|en = 'Rounding'; fa = 'Rounding';
						|it = 'Arrotondamento';
						|pl = 'Zaokrąglenie';
						|tr = 'Yuvarlama'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 2);
	
	Id = "Int";
	StructureToInsert = "Int()";
	Presentation = NStr("vi = 'Phần nguyên';
						|ru = 'Целая часть';
						|en = 'Integral part'; fa = 'بخش صحیح';
						|it = 'Parte intera';
						|pl = 'Cała część';
						|tr = 'Tam sayı kısmı'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "?";
	ParameterPresentation1 = NStr("vi = '<Biểu thức lô-gic>';
									|ru = '<Логическое выражение>';
									|en = '<Logical expression>'; fa = '<Logical expression>';
									|it = '<Espressione logica>';
									|pl = '<Wyrażenie logiczne>';
									|tr = '<Mantıksal ifade>'");
	ParameterPresentation2 = NStr("vi = '<Giá trị nếu kết quả điều kiện là đúng>';
									|ru = '<Значение если результат условия истина>';
									|en = '<Value if the condition result is true>'; fa = '<Value if the condition result is true>';
									|it = '<Valore se il risultato della condizione è vero>';
									|pl = '<Wartość, jeśli wynik warunku prawda>';
									|tr = '<Koşul sonucu doğru ise değer>'");
	ParameterPresentation3 = NStr("vi = '<Giá trị nếu kết quả điều kiện là sai>';
									|ru = '<Значение если результат условия ложь>';
									|en = '<Value if the condition result is false>'; fa = '<Value if the condition result is false>';
									|it = '<Valore se il risultato della condizione è falso>';
									|pl = '<Wartość, jeśli wynik warunku fałsz>';
									|tr = '<Koşul sonucu yanlış ise değer>'");
	StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"?(%1, %2, %3)",
		ParameterPresentation1,
		ParameterPresentation2,
		ParameterPresentation3);
	Presentation = NStr("vi = 'Điều kiện';
						|ru = 'Условие';
						|en = 'Condition'; fa = 'شرط';
						|it = 'Condizione';
						|pl = 'Warunek';
						|tr = 'Koşul'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 3);
	
	Id = "ColumnValue";
	StructureToInsert = "ColumnValue()";
	Presentation = NStr("vi = 'Giá trị cột';
						|ru = 'Значение колонки';
						|en = 'Column value'; fa = 'Column value';
						|it = 'Valore della colonna';
						|pl = 'Wartość kolumny';
						|tr = 'Sütun değeri'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation,, 1);
	
	Id = "CurrentColumnNumber";
	StructureToInsert = "CurrentColumnNumber()";
	Presentation = NStr("vi = 'Số cột hiện tại';
						|ru = 'Номер текущей колонки';
						|en = 'Current column number'; fa = 'Current column number';
						|it = 'Numero della colonna corrente';
						|pl = 'Numer bieżącej kolumny';
						|tr = 'Mevcut sütunun numarası'");
	ProcessingOfFormulas.AddOperator(OperatorsGroup, Id, StructureToInsert, Presentation);
	
EndProcedure

Function ScriptParameters_(Scenario) Export
	
	ScriptParameters_ = "UseInSalesPlanning, UseInProductionPlanning, UseInPurchasePlanning, 
		|UseInBalancePlanning, UseInAssemblyDisassemblyPlanning, UseForMaterialsPlanning, 
		|UseItInPlanningSalesByCategory, UseInPlanningOfInternalConsumption, 
		|UseCalculationBySalesSpeed, PlanningByAssignments, Periodicity";
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	MAX(CASE
	|			WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.SalesPlan)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS UseInSalesPlanning,
	|	MAX(CASE
	|			WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.PurchasePlan)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS UseInPurchasePlanning,
	|	MAX(CASE
	|			WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.AssemblyDisassemblyPlan)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS UseInAssemblyDisassemblyPlanning,
	|	MAX(CASE
	|			WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.InventoryConsumptionPlan)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS UseInPlanningOfInternalConsumption,
	|	MAX(CASE
	|			WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.ProductionPlan)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS UseInProductionPlanning,
	|	SalesOperationsPlanningScenarios.UseForMaterialsPlanning AS UseForMaterialsPlanning,
	|	MAX(CASE
	|			WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.SalesPlanByCategories)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS UseItInPlanningSalesByCategory,
	|	MAX(CASE
	|			WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.PlanOfGoodsStock)
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS UseInBalancePlanning,
	|	SalesOperationsPlanningScenarios.UseCalculationBySalesSpeed AS UseCalculationBySalesSpeed,
	|	SalesOperationsPlanningScenarios.PlanningByAssignments AS PlanningByAssignments,
	|	SalesOperationsPlanningScenarios.Periodicity AS Periodicity
	|FROM
	|	Catalog.SalesOperationsPlanningScenarios AS SalesOperationsPlanningScenarios
	|		LEFT JOIN Catalog.PlanProfiles AS PlanProfiles
	|		ON PlanProfiles.Owner = SalesOperationsPlanningScenarios.Ref
	|WHERE
	|	SalesOperationsPlanningScenarios.Ref = &Scenario
	|
	|GROUP BY
	|	SalesOperationsPlanningScenarios.UseForMaterialsPlanning,
	|	SalesOperationsPlanningScenarios.UseCalculationBySalesSpeed,
	|	SalesOperationsPlanningScenarios.Periodicity,
	|	SalesOperationsPlanningScenarios.PlanningByAssignments";
	
	Query.SetParameter("Scenario", Scenario);
	Selection = Query.Execute().Select();
	Selection.Next();
	ScenarioDetails = New Structure(ScriptParameters_);
	For Each ScriptParameter In ScenarioDetails Do
		ScenarioDetails.Insert(ScriptParameter.Key, Selection[ScriptParameter.Key]);
	EndDo;
	Return ScenarioDetails;
	
EndFunction

// Initializing additional parameters
//
// Parameters:
// AdditionalGoodsParameters             - Structure - structure of additional parameters
// AdditionalParametersGoodsByPeriods   - Structure - The structure of additional parameters for the periods
// Parameters             - Structure - parameter structure:
//  * Form - ClientApplicationForm - 
//  * TimeIntervals - ValueTable - 
//    * Period - StandardPeriod - 
Procedure InitializeAdditionalParameters(AdditionalGoodsParameters, AdditionalParametersGoodsByPeriods, Parameters) Export

	AdditionalParametersByPeriod 	= Parameters.Form.Items.ProductsByPeriodAdditionalParameters;
	AdditionalParametersFormula 		= Parameters.Form.Items.GoodsAdditionalParametersFormula;
	AdditionalParametersDeviation 	= Parameters.Form.Items.ProductsAdditionalParametersDeviation;
	AdditionalParameters 			= Parameters.Form.Items.GoodsAdditionalParameters;
	
	ScenarioDetails = ScriptParameters_(Parameters.Form.Object.Scenario);
	
	TypeOfPlanDetails = Common.ObjectAttributesValues(Parameters.Form.Object.PlanProfile, 
		"PlanType, FillInPartner, FillInTermsOfSales, FillInWarehouse, FillInBusinessUnit, FillInCompany,
		|FillInManager, FillInStoreFormat, FillInAssignmentInTabularForm");
	
	FieldParameters_ = New Structure();
	FieldParameters_.Insert("AttributePath1", 					Parameters.AttributePath1);
	FieldParameters_.Insert("TableFormElement_", 				Parameters.TableFormElement_);
	FieldParameters_.Insert("ScenarioDetails", 				ScenarioDetails);
	FieldParameters_.Insert("TypeOfPlanDetails", 				TypeOfPlanDetails);
	FieldParameters_.Insert("CreateFormElements", 			True);
	FieldParameters_.Insert("FormGroupAdditionalParametersFormula", 	StructureGroupFormsAdditionalParameters(AdditionalParametersFormula.Name, AdditionalParametersFormula.Type));
	FieldParameters_.Insert("GroupOfAdmissionFormParametersDeviation",StructureGroupFormsAdditionalParameters(AdditionalParametersDeviation.Name, AdditionalParametersDeviation.Type));
	FieldParameters_.Insert("FormGroupAdditionalParameters", 			StructureGroupFormsAdditionalParameters(AdditionalParameters.Name, AdditionalParameters.Type));
	If Parameters.Property("BusinessOperation") Then
		FieldParameters_.Insert("BusinessOperation", Parameters.BusinessOperation);
	EndIf;
	If Parameters.Property("ProductionProcessType") Then
		FieldParameters_.Insert("ProductionProcessType", Parameters.ProductionProcessType);
	EndIf;
	
	AdditionalGoodsParameters = Planning.AdditionalParametersForFormulaCalculation(FieldParameters_);

	
	FieldParameters_ = New Structure();
	FieldParameters_.Insert("AttributePath1", 					"");
	FieldParameters_.Insert("TableFormElement_", 				Parameters.PeriodTableFormElement);
	FieldParameters_.Insert("ScenarioDetails", 				ScenarioDetails);
	FieldParameters_.Insert("TypeOfPlanDetails", 				TypeOfPlanDetails);
	FieldParameters_.Insert("CreateFormElements", 			True);
	FieldParameters_.Insert("FormGroupAdditionalParametersFormula", 	StructureGroupFormsAdditionalParameters(AdditionalParametersByPeriod.Name, AdditionalParametersByPeriod.Type));
	FieldParameters_.Insert("GroupOfAdmissionFormParametersDeviation",StructureGroupFormsAdditionalParameters(AdditionalParametersByPeriod.Name, AdditionalParametersByPeriod.Type));
	FieldParameters_.Insert("FormGroupAdditionalParameters", 			StructureGroupFormsAdditionalParameters(AdditionalParametersByPeriod.Name, AdditionalParametersByPeriod.Type));
	If Parameters.Property("BusinessOperation") Then
		FieldParameters_.Insert("BusinessOperation", Parameters.BusinessOperation);
	EndIf;
	If Parameters.Property("ProductionProcessType") Then
		FieldParameters_.Insert("ProductionProcessType", Parameters.ProductionProcessType);
	EndIf;
	
	AdditionalParametersGoodsByPeriods = Planning.AdditionalParametersForFormulaCalculation(FieldParameters_);
	
EndProcedure

#EndRegion 

#Region ProceduresForFillingInFormulas

// Returns a table of data calculated using the formula
//
// Parameters:
//  Parameters  - Structure - Calculation settings:
//  * PlanType - EnumRef.TypesOfPlans - 
//  * PlanProfile - CatalogRef.PlanProfiles - 
//  * TimeIntervals - See TablePeriods
//
// Returns:
//   ValueTable   - A table with data calculated by the formula.
//
Function FillInFormula(Parameters) Export 
	
	SetPrivilegedMode(True);
	
	Array_SetNames = Parameters.Array_SetNames;
	
	PlanType = Parameters.PlanType;
	PlanProfile = Parameters.PlanProfile;
	FillInAssignmentInTabularForm = Common.ObjectAttributeValue(PlanProfile, "FillInAssignmentInTabularForm");
	
	DatasetsObjects = Undefined;
	If Not Parameters.Property("DatasetsObjects", DatasetsObjects) Or TypeOf(DatasetsObjects) <> Type("Structure") Then
		DatasetsObjects = New Structure;
	EndIf; 
	If Parameters.Property("NameOfResultColumn") Then
		NameOfResultColumn = Parameters.NameOfResultColumn;
	Else
		NameOfResultColumn = "Count";
	EndIf;
	
	OperandTemplates = PlanOperandTemplates();
	
	DataCompositionSchemaConversion = GetDataConversionScheme(PlanType, True, FillInAssignmentInTabularForm);
	
	OperandNames = "";
	
	// Filling in operands
	DataSetAssociation = DataCompositionSchemaConversion.DataSets.Union;
	
	For Each OperandName In Array_SetNames Do
	
		SKD_Operand = OperandTemplates.Get(OperandName);
		
		If SKD_Operand = Undefined 
			Or SKD_Operand.DataSets.Count() <> 1 
			Or TypeOf(SKD_Operand.DataSets[0]) = Type("DataCompositionSchemaDataSetUnion") Then
			Continue;
		EndIf; 
		
		If OperandName = "ProductionPlansNeedForSemiFinishedProducts"
			Or OperandName = "ProductionPlansNeedForSemiFinishedProductsWithSelection" 
			Or OperandName = "ProductionPlansMaterials" 
			Or OperandName = "ProductionPlansMaterialsWithSelection" Then
			SKD_Operand.DataSets[0].Query = Catalogs.StoreFormats.QueryTextTTWarehouseFormats(False) +
				InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(
					SKD_Operand.DataSets[0].Query,
					"PlansForConsumptionOfMaterialsTurnoverSubstitutionOfMainMethodOfProvision",
					"MaterialConsumptionPlansTurnovers.Products,MaterialConsumptionPlansTurnovers.Characteristic,MaterialConsumptionPlansTurnovers.Warehouse");
			
		ElsIf OperandName = "AvailableStock" Then
			
			TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
			TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
			TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
			ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(
				SKD_Operand.DataSets[0].Query,
				TablesNames);
			
		ElsIf OperandName = "ShareOfStockAvailabilityDays" Then
			
			PercentageOfProductAvailabilityDaysRemainingRequestTextRedefinition(
				SKD_Operand.DataSets[OperandName], Parameters);
			
		EndIf;
		
		QueryText = SKD_Operand.DataSets[0].Query;
		QueryText = StrReplace(QueryText, "&PeriodString", GetPeriodicityByText(Parameters.Periodicity));
		QueryText = StrReplace(QueryText, "DayPeriod", GetFrequencyOfRegisterByText(Parameters.Periodicity));
		SKD_Operand.DataSets[0].Query = QueryText;
		
		AddSetOfOperandsToConversionScheme(DataCompositionSchemaConversion, DataSetAssociation, SKD_Operand, OperandNames);
		
	EndDo;
	
	PopulatedTS = Parameters.PopulatedTS;
	
	If Parameters.Property("Scenario")
		And Not Parameters.Property("ScenarioStatuses") Then
		
		StatusesList = New ValueList;
		StatusesList.Add(Enums.PlanStatuses.AwaitingConfirmation);
		StatusesList.Add(Enums.PlanStatuses.Upholded);
		
		Parameters.Insert("ScenarioStatuses", StatusesList);
	
	EndIf; 
		
	Parameters.Insert("BeginOfPeriodZero", Date("00010101"));
	
	If Parameters.Property("FillingComposition") Then
	
		PopulatedTS.Clear();
		// Filling out the composition
		
		ArrayOfFillsetNames = Parameters.ArrayOfFillsetNames;
		
		SKD_Filling = GetDataConversionScheme(PlanType, False, FillInAssignmentInTabularForm);
		DataSetAssociation = SKD_Filling.DataSets.Union;
		
		
		For Each OperandName In ArrayOfFillsetNames Do
			
			SKD_Operand = OperandTemplates.Get(OperandName);
			
			If SKD_Operand = Undefined 
				Or SKD_Operand.DataSets.Count() <> 1 
				Or TypeOf(SKD_Operand.DataSets[0]) = Type("DataCompositionSchemaDataSetUnion")
				Or (Parameters.ContentFillingVariant = "Formula"
				And Array_SetNames.Find(OperandName) = Undefined) Then
				Continue;
			EndIf; 
			
			If OperandName = "ItemsPrices" Then
				QueryText = SKD_Operand.DataSets.ItemsPrices.Query;
				QueryText = StrReplace(QueryText,
					"&QueryTextPackagingFactor",
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"ItemPricesCrossSectionOfTheLatest.Package",
					"ItemPricesCrossSectionOfTheLatest.Products"));
					SKD_Operand.DataSets.ItemsPrices.Query = QueryText;
			ElsIf OperandName = "ItemsPricesOfVendor" Then
				QueryText = SKD_Operand.DataSets.ItemsPricesOfVendor.Query;
				QueryText = StrReplace(QueryText,
					"&QueryTextPackagingFactor",
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package",
					"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
					SKD_Operand.DataSets.ItemsPricesOfVendor.Query = QueryText;
			ElsIf OperandName = "MinimumSupplierPrice" Then
				QueryText = SKD_Operand.DataSets.MinimumSupplierPrice.Query;
				QueryText = StrReplace(QueryText,
					"&QueryTextPackagingFactor",
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package",
					"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
					SKD_Operand.DataSets.MinimumSupplierPrice.Query = QueryText;
			EndIf;
			
			QueryText = SKD_Operand.DataSets[0].Query;
			QueryText = StrReplace(QueryText, "&PeriodString", GetPeriodicityByText(Parameters.Periodicity));
			QueryText = StrReplace(QueryText, "DayPeriod", GetFrequencyOfRegisterByText(Parameters.Periodicity));
			SKD_Operand.DataSets[0].Query = QueryText;
			
			AddSetOfOperandsToConversionScheme(SKD_Filling, DataSetAssociation, SKD_Operand);
			
		EndDo;
		
		SKD_Filling.CalculatedFields.Clear(); // we delete it, because it is not known whether there are expression fields in the sources
		DeleteSetsNotUsedForFormulas(SKD_Filling);
		DisableUnusedConversionSchemeFields(SKD_Filling, PlanProfile);
		
		PopulatedTS = ResultTable2();
		
		PerformConversionScheme(SKD_Filling, Parameters, PopulatedTS);
		
	EndIf;
	
	// We supplement the composition table with all periods
	If PopulatedTS.Columns.Find("CompositionPeriod") = Undefined
		And PopulatedTS.Columns.Find("Period") = Undefined Then
		PopulatedTS.Columns.Add("CompositionPeriod", TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date));
		PopulatedTS.FillValues(Parameters.OffsetPeriodStart, "CompositionPeriod");
		
		// We copy the lines in each period of the plan
		If Parameters.TimeIntervals.Count() > 1 Then
			
			OnePeriod = PopulatedTS.Copy();
			
			For Each TSRow In OnePeriod Do
				For Each Period In Parameters.TimeIntervals Do
					If Period.StartDate = Parameters.OffsetPeriodStart Then
						Continue;
					EndIf; 
					NewRow = PopulatedTS.Add();
					FillPropertyValues(NewRow, TSRow);
					NewRow.CompositionPeriod = Period.StartDate;
				EndDo; 
			EndDo; 
		
		EndIf;
		
	Else
		
		If PopulatedTS.Columns.Find("Period") <> Undefined And PopulatedTS.Columns.Find("CompositionPeriod") = Undefined Then
			PopulatedTS.Columns["Period"].Name = "CompositionPeriod";
		EndIf;
		
		If Parameters.PlanType = Enums.TypesOfPlans.SalesPlanByCategories Then
			SearchColumns = "ProductCategory, CompositionPeriod";
		Else
			SearchColumns = "Products, CompositionPeriod";
		EndIf;
		ItemVariantsAreUsed = PopulatedTS.Columns.Find("Characteristic") <> Undefined;
		If ItemVariantsAreUsed Then
			SearchColumns = SearchColumns + ", Characteristic";
		EndIf;
		TheStructureOfTheSearch = New Structure(SearchColumns);
		PopulatedTS.Indexes.Add(SearchColumns);
		TSCopyToBeFilledIn = PopulatedTS.Copy();
		
		For Each TSRow In TSCopyToBeFilledIn Do
			For Each Period In Parameters.TimeIntervals Do
				
				FillPropertyValues(TheStructureOfTheSearch, TSRow);
				TheStructureOfTheSearch.CompositionPeriod = Period.StartDate;
				
				If TSCopyToBeFilledIn.FindRows(TheStructureOfTheSearch).Count()>0
					Or PopulatedTS.FindRows(TheStructureOfTheSearch).Count()>0 Then
					Continue;
				EndIf;
				
				NewRow = PopulatedTS.Add();
				FillPropertyValues(NewRow, TheStructureOfTheSearch);
				
			EndDo; 
		EndDo;
		
	EndIf;
	
	If PopulatedTS.Columns.Find("LineNumber") <> Undefined Then
		PopulatedTS.Columns.LineNumber.Name = "LineNumber";
	EndIf;
	If PopulatedTS.Columns.Find("LineNumber") = Undefined Then
		PopulatedTS.Columns.Add("LineNumber", TMCommonUse.GetDescriptionOfNumberTypes(5,0));
		
		LineNumber = 0;
		For Each TSRow In PopulatedTS Do
			
			LineNumber = LineNumber + 1;
			TSRow.LineNumber = LineNumber;
			
		EndDo; 
		
	EndIf; 
	
	SupplementLinksForPricing25 = False;
	
	DataSetJoining = DataCompositionSchemaConversion.DataSets.Find("Joining");
	If Parameters.Property("UpdateMetrics") 
		And Parameters.Property("ArrayOfSetConnectionNames")
		And DataSetJoining <> Undefined Then
		
		ArrayOfSetConnectionNames = Parameters.ArrayOfSetConnectionNames;
		
		For Each OperandName In ArrayOfSetConnectionNames Do
			
			SKD_Operand = OperandTemplates.Get(OperandName);
			
			If SKD_Operand = Undefined 
				Or SKD_Operand.DataSets.Count() <> 1 
				Or TypeOf(SKD_Operand.DataSets[0]) = Type("DataCompositionSchemaDataSetUnion") Then
				Continue;
			EndIf; 
			
			If OperandName = "ItemsPrices" Then
				QueryText = SKD_Operand.DataSets.ItemsPrices.Query;
				QueryText = StrReplace(QueryText,
					"&QueryTextPackagingFactor",
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"ItemPricesCrossSectionOfTheLatest.Package",
					"ItemPricesCrossSectionOfTheLatest.Products"));
					SKD_Operand.DataSets.ItemsPrices.Query = QueryText;
					If StrFind(QueryText, Metadata.InformationRegisters.ItemsPrices25.Name) <> 0 Then
						SupplementLinksForPricing25 = True;
					EndIf;
			ElsIf OperandName = "ItemsPricesOfVendor" Then
				QueryText = SKD_Operand.DataSets.ItemsPricesOfVendor.Query;
				QueryText = StrReplace(QueryText,
					"&QueryTextPackagingFactor",
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package",
					"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
					SKD_Operand.DataSets.ItemsPricesOfVendor.Query = QueryText;
			ElsIf OperandName = "MinimumSupplierPrice" Then
				QueryText = SKD_Operand.DataSets.MinimumSupplierPrice.Query;
				QueryText = StrReplace(QueryText,
					"&QueryTextPackagingFactor",
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package",
					"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
					SKD_Operand.DataSets.MinimumSupplierPrice.Query = QueryText;
			EndIf;
				
			AddSetOfOperandsToConversionScheme(DataCompositionSchemaConversion, DataSetJoining, SKD_Operand, OperandNames);
			
		EndDo; 
	EndIf;
	
	If SupplementLinksForPricing25 And ArrayOfSetConnectionNames.Count() = 1 Then
		AddSettingsForPricing25(DataCompositionSchemaConversion, PopulatedTS);
	EndIf;
	
	DeleteSetsNotUsedForFormulas(DataCompositionSchemaConversion);
	DisableUnusedConversionSchemeFields(DataCompositionSchemaConversion, PlanProfile);
	
	For Each Field In DataCompositionSchemaConversion.DataSets.CompositionTable.Fields Do
	
		If PopulatedTS.Columns.Find(Field.Field) = Undefined Then
			PopulatedTS.Columns.Add(Field.Field, Field.ValueType);
		EndIf; 
	
	EndDo; 
	DatasetsObjects.Insert("CompositionTable", PopulatedTS);
	
	ResultTable2 = ResultTable2();
	
	PerformConversionScheme(DataCompositionSchemaConversion, Parameters, ResultTable2, DatasetsObjects);
	
	// Processing the calculation of special fields
	If ResultTable2.Columns.Find("Products") <> Undefined
		And (ResultTable2.Columns.Find("SalesPlansByCategories") <> Undefined
		Or ResultTable2.Columns.Find("SalesPlansByCategoriesWithFilter") <> Undefined) Then
		
		MetricFieldNames = New Array;
		If ResultTable2.Columns.Find("SalesPlansByCategories") <> Undefined Then 
			MetricFieldNames.Add("SalesPlansByCategories");
		EndIf;
		If ResultTable2.Columns.Find("SalesPlansByCategoriesWithFilter") <> Undefined Then 
			MetricFieldNames.Add("SalesPlansByCategoriesWithFilter");
		EndIf;
		
		ResultTable2.Columns.CompositionPeriod.Name = "Period";
		
		Documents.SalesPlansAllocationBaseByCategories.RecalculateIndicatorsByDistributionStandards(ResultTable2, MetricFieldNames);
		
		If ResultTable2.Columns.Find("LineNumber") <> Undefined Then 
			ResultTable2.Sort("LineNumber");
		EndIf;
		
		ResultTable2.Columns.Period.Name = "CompositionPeriod";
		
	ElsIf ResultTable2.Columns.Find("Products") <> Undefined
		And (ResultTable2.Columns.Find("SalesPlansByCategoriesBySalesSpeed") <> Undefined
		Or ResultTable2.Columns.Find("SalesPlansByCategoriesBySalesSpeedWithFilter") <> Undefined) Then
		
		MetricFieldNames = New Array;
		If ResultTable2.Columns.Find("SalesPlansByCategoriesBySalesSpeed") <> Undefined Then 
			MetricFieldNames.Add("SalesPlansByCategoriesBySalesSpeed");
		EndIf;
		If ResultTable2.Columns.Find("SalesPlansByCategoriesBySalesSpeedWithFilter") <> Undefined Then 
			MetricFieldNames.Add("SalesPlansByCategoriesBySalesSpeedWithFilter");
		EndIf;
		
		ResultTable2.Columns.CompositionPeriod.Name = "Period";
		
		Documents.SalesPlansAllocationBaseByCategories.RecalculateIndicatorsByDistributionStandards(ResultTable2, MetricFieldNames, False);
		
		If ResultTable2.Columns.Find("LineNumber") <> Undefined Then 
			ResultTable2.Sort("LineNumber");
		EndIf;
		
		ResultTable2.Columns.Period.Name = "CompositionPeriod";
		
	EndIf;
	
	If ResultTable2.Columns.Find("SalesPlans") <> Undefined
		Or ResultTable2.Columns.Find("ProductionPlansMaterials") <> Undefined
		Or ResultTable2.Columns.Find("InventoryConsumptionPlans") <> Undefined
		Or ResultTable2.Columns.Find("DisassemblyPlansKits") <> Undefined
		Or ResultTable2.Columns.Find("BuildPlansComponents") <> Undefined Then
		
		ResultTable2.Columns.Add("ExpensePlans", New TypeDescription("Number",New NumberQualifiers(15,3,AllowedSign.Any)));
		OperandNames = OperandNames + ", ExpensePlans";
		
	EndIf;
	
	If ResultTable2.Columns.Find("SalesPlansWithSelection") <> Undefined
		Or ResultTable2.Columns.Find("ProductionPlansMaterialsWithSelection") <> Undefined
		Or ResultTable2.Columns.Find("InventoryConsumptionPlansWithSelection") <> Undefined
		Or ResultTable2.Columns.Find("DisassemblyPlansKitsWithSelection") <> Undefined
		Or ResultTable2.Columns.Find("BuildPlansComponentsWithSelection") <> Undefined Then
		
		ResultTable2.Columns.Add("ExpensePlansWithSelection", New TypeDescription("Number",New NumberQualifiers(15,3,AllowedSign.Any)));
		OperandNames = OperandNames + ", ExpensePlansWithSelection";
		
	EndIf;
	
	If ResultTable2.Columns.Find("PurchasePlans") <> Undefined
		Or ResultTable2.Columns.Find("ReleasePlans") <> Undefined
		Or ResultTable2.Columns.Find("AssemblyPlansKits") <> Undefined
		Or ResultTable2.Columns.Find("DisassemblyPlansComponents") <> Undefined Then
		
		ResultTable2.Columns.Add("ParishPlans", New TypeDescription("Number",New NumberQualifiers(15,3,AllowedSign.Any)));
		OperandNames = OperandNames + ", ParishPlans";
		
	EndIf;
	
	If ResultTable2.Columns.Find("PurchasePlansWithSelection") <> Undefined
		Or ResultTable2.Columns.Find("ReleasePlansWithSelection") <> Undefined
		Or ResultTable2.Columns.Find("AssemblyPlansKitsWithSelection") <> Undefined
		Or ResultTable2.Columns.Find("DisassemblyPlansComponentsWithSelection") <> Undefined Then
		
		ResultTable2.Columns.Add("ParishPlansWithSelection", New TypeDescription("Number",New NumberQualifiers(15,3,AllowedSign.Any)));
		OperandNames = OperandNames + ", ParishPlansWithSelection";
		
	EndIf;
	
	// We calculate the quantity by the formula
	If ResultTable2.Columns.Find("Formula") = Undefined Then
		ResultTable2.Columns.Add("Formula", New TypeDescription("String"));
	EndIf;
	If ResultTable2.Columns.Find("FormulaPresentation") = Undefined Then
		ResultTable2.Columns.Add("FormulaPresentation", New TypeDescription("String"));
	EndIf;
	If ResultTable2.Columns.Find("FormulaCalculation") = Undefined Then
		ResultTable2.Columns.Add("FormulaCalculation", New TypeDescription("String"));
	EndIf;
	
	If ResultTable2.Columns.Find(NameOfResultColumn) = Undefined Then
		ResultTable2.Columns.Add(NameOfResultColumn, TMCommonUse.GetDescriptionOfNumberTypes(15,3));
	EndIf;
	
	If Not Parameters.Property("FillingComposition") And Not Parameters.Property("PopulateOperands") And Parameters.Property("UpdateMetrics") Then
		
		// Updating prices
		For Each TSRow In PopulatedTS Do
			
			FoundRows = ResultTable2.FindRows(New Structure("LineNumber", TSRow.LineNumber));
			CurrentData = New Structure(OperandNames);
			
			If FoundRows.Count() > 0 Then
				
				FoundRow = FoundRows[0];
				
				FillPropertyValues(CurrentData, FoundRow);
				
			EndIf; 
			
			FillPropertyValues(TSRow, CurrentData);
			
		EndDo;
		
		Return PopulatedTS;
	
	Else
		
		For Each TSRow In ResultTable2 Do
			
			CurrentData = New Structure(OperandNames);
			FillPropertyValues(CurrentData, TSRow);
			
			CalculateArrivalPlansExpensePlans(CurrentData, "");
			CalculateArrivalPlansExpensePlans(CurrentData, "WithSelection");
			FillPropertyValues(TSRow, CurrentData);
			
			CalculationResult = CalculateByFormula(Parameters.Formula, CurrentData, 
				Undefined, Undefined,Parameters.FormulaPresentation);
			
			TSRow[NameOfResultColumn] = CalculationResult.Result;
			TSRow.Formula               = Parameters.Formula;
			TSRow.FormulaPresentation  = CalculationResult.Presentation;
			TSRow.FormulaCalculation     = CalculationResult.Calculation;
			
		EndDo;
		
		Return ResultTable2;
	
	EndIf; 
	
EndFunction

Procedure AddSettingsForPricing25(DataCompositionSchemaConversion, PopulatedTS)

	ByItemVariant = False;
	ByPackage = False;

	If PopulatedTS.Columns.Find("PricingVariant") = Undefined 
		And GetFunctionalOption("UseProductsVariantsForPricing") Then
		PopulatedTS.Columns.Add("PricingVariant", New TypeDescription("CatalogRef.ItemsCharacteristicsForPricing"));
		ByItemVariant = True;
	EndIf; 

	If PopulatedTS.Columns.Find("PricingPackage") = Undefined And 
		GetFunctionalOption("UseItemPackagesForPricing") Then
		PopulatedTS.Columns.Add("PricingPackage", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		ByPackage = True;
	EndIf; 
	
	If ByItemVariant Or ByPackage Then
		TableForSelection = PopulatedTS.Copy(, "Products");
		TableForSelection.GroupBy("Products");
		SelectionList_ = TableForSelection.UnloadColumn("Products");
			
		PricingSettingsTable = DataProcessors.GoodsSelectionByPicking.GetPricingSettingsTable(SelectionList_);
		For Each Setting In PricingSettingsTable Do
			FoundRows = PopulatedTS.FindRows(New Structure("Products", Setting.Products));
			
			For Each FoundRow In FoundRows Do
				If ByItemVariant And Setting.ByItemVariant Then
					FoundRow.PricingVariant = FoundRow.Characteristic.ItemsCharacteristicForPricing;
				EndIf;
				If ByPackage And Setting.ByPackage Then
					FoundRow.PricingPackage = FoundRow.Package;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	// add connections of sets. delete a link by character (if there is one)
	IndexOf = DataCompositionSchemaConversion.DataSetLinks.Count() - 1;
	While IndexOf >= 0 Do
		Link = DataCompositionSchemaConversion.DataSetLinks[IndexOf];
		IndexOf = IndexOf - 1;
		
		If ByItemVariant 
			And (Link.SourceExpression = "Characteristic" 
			Or Link.DestinationExpression = "Characteristic") Then
		
			DataCompositionSchemaConversion.DataSetLinks.Delete(Link);
		
		EndIf; 
		
	EndDo; 

	If ByItemVariant Then
	
		DataProcessors.GoodsSelectionByPicking.AddDCSDataSetField(
												DataCompositionSchemaConversion.DataSets.CompositionTable, 
												"PricingVariant", 
												"CatalogRef.ItemsCharacteristicsForPricing");
		DataProcessors.GoodsSelectionByPicking.AddRelationshipOfDCSDataSets(
												DataCompositionSchemaConversion,
												DataCompositionSchemaConversion.DataSets.CompositionTable, 
												DataCompositionSchemaConversion.DataSets.Joining, 
												"PricingVariant");
	EndIf; 

	If ByPackage Then
		
		DataProcessors.GoodsSelectionByPicking.AddDCSDataSetField(
												DataCompositionSchemaConversion.DataSets.CompositionTable, 
												"PricingPackage", 
												"CatalogRef.PackagesAndUnitsOfMeasure");
		DataProcessors.GoodsSelectionByPicking.AddRelationshipOfDCSDataSets(
												DataCompositionSchemaConversion,
												DataCompositionSchemaConversion.DataSets.CompositionTable, 
												DataCompositionSchemaConversion.DataSets.Joining, 
												"PricingPackage");
	EndIf;
EndProcedure
// Returns:
// 	ValueTable - LongDesc:
//    * Period - Date -
//    * CompositionPeriod - Date -
//    * LineNumber - Number
//
Function ResultTable2()
	
	ResultTable2 = New ValueTable;

	Return ResultTable2
	
EndFunction

Procedure CalculateArrivalPlansExpensePlans(CurrentData, Separator)
	
	If CurrentData.Property("ExpensePlans"+Separator) Then
		ExpensePlans = ?(CurrentData.Property("SalesPlans"+Separator),
		CurrentData["SalesPlans"+Separator],0)
		+ ?(CurrentData.Property("InventoryConsumptionPlans"+Separator),
		CurrentData["InventoryConsumptionPlans"+Separator],0)
		+ ?(CurrentData.Property("ProductionPlansMaterials"+Separator),
		CurrentData["ProductionPlansMaterials"+Separator],0)
		+ ?(CurrentData.Property("ProductionPlansNeedForSemiFinishedProducts"+Separator),
		CurrentData["ProductionPlansNeedForSemiFinishedProducts"+Separator],0)
		+ ?(CurrentData.Property("DisassemblyPlansKits"+Separator),
		CurrentData["DisassemblyPlansKits"+Separator],0)
		+ ?(CurrentData.Property("BuildPlansComponents"+Separator),
		CurrentData["BuildPlansComponents"+Separator],0)
		+ ?(CurrentData.Property("AdjustmentsToPlannedDemands"+Separator),
		CurrentData["AdjustmentsToPlannedDemands"+Separator],0);
		
		CurrentData["ExpensePlans"+Separator] = ExpensePlans;
	EndIf;

	If CurrentData.Property("ParishPlans"+Separator) Then
		ParishPlans = ?(CurrentData.Property("PurchasePlans"+Separator),
		CurrentData["PurchasePlans"+Separator],0)
		+ ?(CurrentData.Property("ReleasePlans"+Separator),
		CurrentData["ReleasePlans"+Separator],0)
		+ ?(CurrentData.Property("AssemblyPlansKits"+Separator),
		CurrentData["AssemblyPlansKits"+Separator],0)
		+ ?(CurrentData.Property("DisassemblyPlansComponents"+Separator),
		CurrentData["DisassemblyPlansComponents"+Separator],0);
		
		CurrentData["ParishPlans"+Separator] = ParishPlans;
	EndIf;
	
EndProcedure

// Returns the operand layouts for this plan
//
// Returns:
//   Map   - Layouts for operands.
//
Function PlanOperandTemplates() Export 

	Templates = New Map;
	
	Documents.SalesPlanByCategories.PlanOperandTemplates(Templates);
	Documents.SalesPlan.PlanOperandTemplates(Templates);
	Documents.PurchasePlan.PlanOperandTemplates(Templates);
	Documents.PlanOfGoodsStock.PlanOperandTemplates(Templates);
	Documents.AssemblyDisassemblyPlan.PlanOperandTemplates(Templates);
	Documents.InventoryConsumptionPlan.PlanOperandTemplates(Templates);
	Documents.ProductionPlan.PlanOperandTemplates(Templates);
	Templates.Insert("AdjustmentsToPlannedDemands", Documents.AdjustmentOfPlannedDemand.GetTemplate("DCS_AdjustmentsToPlannedDemands"));
	Templates.Insert("AdjustmentsToPlannedDemandsWithSelection", Documents.AdjustmentOfPlannedDemand.GetTemplate("DCS_AdjustmentsToPlannedDemandsWithSelection"));

	Return Templates;

EndFunction

// Selects the data of decoding
//
// Parameters:
//  Array_SetNames	 - Array	 - Array of data sets (sources for filling in indicators)
//  Parameters			 - Structure - request parameters.
// 
// Returns:
//  Array - Decryption data (Document, Document date, Document Number).
//
Function GetDecryption(Array_SetNames, Parameters) Export

	SetPrivilegedMode(True);
	
	FieldArray = New Array();
	FieldArray.Add("Document");
	FieldArray.Add("DocumentDate");
	FieldArray.Add("DocumentNumber");
	For Each Item In Array_SetNames Do
		FieldArray.Add(Item);
	EndDo; 
	
	DecryptionDataArray = New Array();
	
	Details = New ValueTable();
	
	PlanType = PlanningClientServer.GetPlanTypeFromLink(Parameters.Ref);
	
	OperandTemplates = PlanOperandTemplates();
	
	DataCompositionSchemaConversion = GetDataConversionScheme(PlanType);
	DataSetAssociation = DataCompositionSchemaConversion.DataSets.Union;
	
	OperandNames = "";
	
	For Each OperandName In Array_SetNames Do
		
		SKD_Operand = OperandTemplates.Get(OperandName);
		
		If SKD_Operand = Undefined 
			Or SKD_Operand.DataSets.Count() <> 1 
			Or TypeOf(SKD_Operand.DataSets[0]) = Type("DataCompositionSchemaDataSetUnion") Then
			Continue;
		EndIf; 
		
		AddSetOfOperandsToConversionScheme(DataCompositionSchemaConversion, DataSetAssociation, SKD_Operand, OperandNames);
		
	EndDo; 
	
	DeleteSetsNotUsedForFormulas(DataCompositionSchemaConversion);
	
	// Adding fields for decryption
	ConfigureSchemeForDecryption(DataCompositionSchemaConversion, DataSetAssociation, FieldArray);
	
	PerformConversionScheme(DataCompositionSchemaConversion, Parameters, Details);
	
	If Details.Count() > 0
		And Parameters.Property("Filter")
		And Parameters.Filter.Property("Products")
		And (Array_SetNames.Find("SalesPlansByCategories") <> Undefined
		Or Array_SetNames.Find("SalesPlansByCategoriesWithFilter") <> Undefined
		Or Array_SetNames.Find("SalesPlansByCategoriesBySalesSpeed") <> Undefined
		Or Array_SetNames.Find("SalesPlansByCategoriesBySalesSpeedWithFilter") <> Undefined)Then
		
		Products = Parameters.Filter.Products;
		If Parameters.Filter.Property("Characteristic") Then
			Characteristic = Parameters.Filter.Characteristic;
		Else
			Characteristic = Catalogs.ItemsCharacteristics.EmptyRef();
		EndIf; 
		
		StandardsForProducts = True;
		
		If Array_SetNames.Find("SalesPlansByCategories") <> Undefined Then
			NameOfStandardColumn = "SalesPlansByCategories";
		ElsIf Array_SetNames.Find("SalesPlansByCategoriesWithFilter") <> Undefined Then
			NameOfStandardColumn = "SalesPlansByCategoriesWithFilter";
		ElsIf Array_SetNames.Find("SalesPlansByCategoriesBySalesSpeed") <> Undefined Then
			NameOfStandardColumn = "SalesPlansByCategoriesBySalesSpeed";
			StandardsForProducts = False;
		Else
			NameOfStandardColumn = "SalesPlansByCategoriesBySalesSpeedWithFilter";
			StandardsForProducts = False;
		EndIf; 
		
		Standards = Documents.SalesPlansAllocationBaseByCategories.GetDistributionStandards(
			Parameters.OffsetPeriodStart,
			Products, 
			Characteristic,
			StandardsForProducts);
		
		If Standards <> Undefined And Standards.Count() > 0 Then
			// Replacing column types
			Types = Details.Columns.Document.ValueType.Types(); // Array of Type
			Types.Add(Type("DocumentRef.SalesPlansAllocationBaseByCategories"));
			Details.Columns.Document.Name = "DocumentOld_";
			Details.Columns.Add("Document", New TypeDescription(Types));
			For Each DecryptionString In Details Do
				DecryptionString.Document = DecryptionString.DocumentOld_;
			EndDo; 
			Details.Columns.Delete(Details.Columns.DocumentOld_);
			
			For Each NormativeStandard In Standards Do
				
				NewRow = Details.Add();
				FillPropertyValues(NewRow, NormativeStandard);
				
				NewRow[NameOfStandardColumn] = NormativeStandard.AllocationPercentage
				
			EndDo;
			
		EndIf; 
		
	EndIf; 
	
	For Each DecryptionString In Details Do
		DecryptionDataStructure = New Structure();
		For Each Column In Details.Columns Do
			DecryptionDataStructure.Insert(Column.Name);
		EndDo;
		FillPropertyValues(DecryptionDataStructure, DecryptionString);
		DecryptionDataArray.Add(DecryptionDataStructure);
	EndDo; 
	
	Return DecryptionDataArray;
	
EndFunction

// The procedure calculates the values of the planned start / end balance / deficit in the line.
//
// Parameters:
//  RowOfGoods		 - Structure - the row structure
//  Period				 - String - Description of the current period in the Periods table
//  PreviousPeriod_	 - String - Description of the previous period in the Periods table
//  NewPlanOfRemnants    - Boolean - indicates that there is a balance plan for the specified period
//  Separator - String - "_" or "Sambora" shares the name operand and the ID of the period
//  MainOperandOfPlan - String - main operand of the plan
//  AdjustmentSign    - Number - Adjustment sign.
//
Procedure CalculateCalculatedOperands(RowOfGoods, Period, PreviousPeriod_, NewPlanOfRemnants, Separator, MainOperandOfPlan, AdjustmentSign) Export
	
	If Not RowOfGoods.Property("PlannedStartBalance"+Separator+Period.ColumnName) Then
		Return;
	EndIf;
	
	If Not NewPlanOfRemnants
		And PreviousPeriod_ <> Undefined Then
		AccumulatedPlannedClosingShortage = RowOfGoods["AccumulatedPlannedClosingShortage"+Separator+PreviousPeriod_.ColumnName];
	Else
		AccumulatedPlannedClosingShortage = -RowOfGoods["PlannedStartBalance"+Separator+Period.ColumnName];
	EndIf;
	
	RowOfGoods["PlannedStartBalance"+Separator+Period.ColumnName] = Max(0,-AccumulatedPlannedClosingShortage);
	
	AccumulatedPlannedClosingShortage = AccumulatedPlannedClosingShortage
											+?(RowOfGoods.Property("ExpensePlans"+Separator+Period.ColumnName),
											RowOfGoods["ExpensePlans"+Separator+Period.ColumnName],
											0)
											- ?(RowOfGoods.Property("ParishPlans"+Separator+Period.ColumnName),
											RowOfGoods["ParishPlans"+Separator+Period.ColumnName],
											0)
											- ?(MainOperandOfPlan="" Or Not Period.Active_, 0, AdjustmentSign*RowOfGoods[MainOperandOfPlan+"_"+Period.ColumnName]);
	
	RowOfGoods["AccumulatedPlannedClosingShortage"+Separator+Period.ColumnName] = AccumulatedPlannedClosingShortage;
	
	If RowOfGoods.Property("PlannedFinalDeficit"+Separator+Period.ColumnName) Then
		RowOfGoods["PlannedFinalDeficit"+Separator+Period.ColumnName] = Max(0, AccumulatedPlannedClosingShortage);
	EndIf;
	
	If RowOfGoods.Property("PlannedFinalBalances"+Separator+Period.ColumnName) Then
		RowOfGoods["PlannedFinalBalances"+Separator+Period.ColumnName] = Max(0, -AccumulatedPlannedClosingShortage);
	EndIf;
	
EndProcedure

// Returns +1, -1, or 0-the sign of the planned deficit adjustment that the current plan will make.
//
// Parameters:
// Form             - ManagedFormExtensionForDocuments - The form of the document plan:
// * Object - DocumentObject - 
//
// Returns:
//  Number - +1,0-1
Function GetAdjustmentSign(Form) Export
	
	If TypeOf(Form.Object.Ref) = Type("DocumentRef.PlanOfGoodsStock") Then
		Character = 0;
	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.SalesPlan")
		Or TypeOf(Form.Object.Ref) = Type("DocumentRef.SalesPlanByCategories")
		Or TypeOf(Form.Object.Ref) = Type("DocumentRef.InventoryConsumptionPlan")
		Or (TypeOf(Form.Object.Ref) = Type("DocumentRef.ProductionPlan")
		And Form.Object.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly)
		Or (TypeOf(Form.Object.Ref) = Type("DocumentRef.AssemblyDisassemblyPlan")
		And Form.Object.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents) Then
		// The entire planned expenditure increases the deficit
		Character = 1;
	Else
		// The entire planned parish deficit is reduced
		Character = -1;
	EndIf;
	
	Return Character
	
EndFunction

// Returns the main operand of the plan
//
// Parameters:
// Form             - ManagedFormExtensionForDocuments - The form of the document plan:
// * Object - DocumentObject - 
// WithSelection - Boolean
//
// Returns:
//  String - name of the plan operand
Function MainOperandOfPlan(Form, WithSelection = False) Export
	
	If TypeOf(Form.Object.Ref) = Type("DocumentRef.PlanOfGoodsStock") Then
		Return ?(WithSelection,"BalancePlansWithFilter","PlansOfGoodsStock");
	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.PurchasePlan") Then
		Return ?(WithSelection,"PurchasePlansWithSelection","PurchasePlans");
	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.SalesPlan") Then
		Return ?(WithSelection,"SalesPlansWithSelection","SalesPlans");
	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.SalesPlanByCategories") Then
		Return ?(WithSelection,"SalesPlansByCategoriesWithFilter","SalesPlansByCategories");
	ElsIf (TypeOf(Form.Object.Ref) = Type("DocumentRef.AssemblyDisassemblyPlan")
		And Form.Object.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents) Then
		Return ?(WithSelection,"DisassemblyPlansKitsWithSelection","DisassemblyPlansKits");
	ElsIf (TypeOf(Form.Object.Ref) = Type("DocumentRef.AssemblyDisassemblyPlan")
		And Form.Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents) Then
		Return ?(WithSelection,"AssemblyPlansKitsWithSelection","AssemblyPlansKits");
	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.InventoryConsumptionPlan") Then
		Return ?(WithSelection,"InventoryConsumptionPlansWithSelection","InventoryConsumptionPlans");
	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.ProductionPlan") Then
		If Form.Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
			Or Form.Object.ProductionProcessType = Enums.ProductionProcessTypes.Repair Then
			Return ?(WithSelection,"ProductionPlansRepairWithSelection","ProductionRepairPlans");
		ElsIf Form.Object.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
			Return ?(WithSelection,"ProductionPlansDisassemblyWithFilter","ProductionPlansDisassembly");
		Else
			Return ?(WithSelection,"ProductionPlansWithPicking","ProductionPlans");
		EndIf;
	EndIf;
	
EndFunction

// Creates a tree of operands and places them in temporary storage
//
// Parameters:
// Form             - ClientApplicationForm - Form of the plan document.
// Offset - Number
//
// Returns:
//  String - the address of the storage with the operand tree.
Function PlaceAdditionalFieldsInStorage(Form, Offset) Export
	
	OperandsTable = Form.AdditionalFields.Unload();// See OperandsTable
	OperandsTree = ProcessingOfFormulas.GetEmptyOperandTree();
	
	GroupNamePresentation = New Array;
	GroupNamePresentation.Add(New Structure("Id, Presentation", "MainOperands", NStr("vi = 'Tham số chính';
																					|ru = 'Основные операнды';
																					|en = 'Main operands'; fa = 'Main operands';
																					|it = 'Operandi principali';
																					|pl = 'Podstawowe operandy';
																					|tr = 'Ana işlenenler'")));
	GroupNamePresentation.Add(New Structure("Id, Presentation", "BasicOperandsWithSelection",  NStr("vi = 'Tham số chính*';
																									|ru = 'Основные операнды*';
																									|en = 'Main operands*'; fa = 'Main operands*';
																									|it = 'Operandi principali*';
																									|pl = 'Podstawowe operandy*';
																									|tr = 'Ana işlenenler*'")));
	GroupNamePresentation.Add(New Structure("Id, Presentation", "AdditionalOperandsPlans",  NStr("vi = 'Tham số bổ sung (kế hoạch)';
																								|ru = 'Дополнительные операнды (планы)';
																								|en = 'Additional operands (plans)'; fa = 'Additional operands (plans)';
																								|it = 'Operandi aggiuntivi (piani)';
																								|pl = 'Dodatkowe operandy (plany)';
																								|tr = 'Ek işlenenler (planlar)'")));
	GroupNamePresentation.Add(New Structure("Id, Presentation", "AdditionalOperandsAreAssociatedWithSelection",  NStr("vi = 'Tham số bổ sung (kế hoạch) *';
																														|ru = 'Дополнительные операнды (планы)*';
																														|en = 'Additional operands (plans)*'; fa = 'Additional operands (plans)*';
																														|it = 'Operandi aggiuntivi (piani)*';
																														|pl = 'Dodatkowe operandy (plany)*';
																														|tr = 'Ek işlenenler (planlar)*'")));
	GroupNamePresentation.Add(New Structure("Id, Presentation", "AdditionalOperandsFacts",  NStr("vi = 'Tham số bổ sung (thực tế)';
																								|ru = 'Дополнительные операнды (факты)';
																								|en = 'Additional operands (actual data)'; fa = 'Additional operands (actual data)';
																								|it = 'Operandi aggiuntivi (fatti)';
																								|pl = 'Operandy dodatkowe (fakty)';
																								|tr = 'Ek işlenenler (bilgiler)'")));
	GroupNamePresentation.Add(New Structure("Id, Presentation", "AuxiliaryOperands",  NStr("vi = 'Tham số phụ';
																							|ru = 'Вспомогательные операнды';
																							|en = 'Auxiliary operands'; fa = 'Auxiliary operands';
																							|it = 'Operandi ausiliari';
																							|pl = 'Operandy pomocnicze';
																							|tr = 'Yardımcı işlenenler'")));
	
	TypesOfTreeElements = ProcessingOfFormulas.TypesOfOperandTreeElements();
	
	OperandGroup_ = Undefined;
	For Each OperandGroup In GroupNamePresentation Do // See OperandGroup
		
		For Each Operand In OperandsTable.FindRows(New Structure("IncludedInOperand", OperandGroup.Id)) Do
			If OperandGroup_ = Undefined Then
				OperandGroup_ = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
				OperandGroup_.Id = OperandGroup.Id;
				OperandGroup_.Presentation = OperandGroup.Presentation;
				OperandGroup_.TreeItemType = TypesOfTreeElements.TopLevelRowGroup;
				
				OperandGroup_.OperandSelectionAllowed = False;
				OperandGroup_.IncludedInID = False;
			EndIf;
			
			OperandString = ProcessingOfFormulas.NewLineOfOperandTree(OperandGroup_);
			OperandString.Id = Operand.Id;
			OperandString.Presentation = Operand.Presentation;
			OperandString.OperandSelectionAllowed = True;
			OperandString.IncludedInID = True;
			OperandString.ValueType = New TypeDescription("Number");
			
			OperandString.Value = Operand.Value;
			OperandString.ContainsValue = ValueIsFilled(OperandString.Value);
			
		EndDo;
		
		OperandGroup_ = Undefined;
		
	EndDo;
	
	AddressInStorage = PutToTempStorage(OperandsTree, Form.UUID);
	
	Return AddressInStorage;
	
EndFunction

// A group of operands.
// 
// Returns:
//  Structure - Operand Group:
// * Id - String - 
// * Presentation - String - 
Function OperandGroup() Export
	OperandGroup = New Structure;
	OperandGroup.Insert("Id");
	OperandGroup.Insert("Presentation");
	Return OperandGroup;
EndFunction

// Table of operands.
// 
// Returns:
//  ValueTable - Table of additional fields of the plan form:
//   *IncludedInOperand - String
//   *Value - Number
//   *Id - String
//   *DeletionMark - Boolean
//   *Presentation - String
//   *Ref - String
Function OperandsTable() Export
	OperandsTable = New ValueTable();
	OperandsTable.Columns.Insert("IncludedInOperand");
	OperandsTable.Columns.Insert("Value");
	OperandsTable.Columns.Insert("Id");
	OperandsTable.Columns.Insert("DeletionMark");
	OperandsTable.Columns.Insert("Presentation");
	OperandsTable.Columns.Insert("Ref");
	Return OperandsTable;
EndFunction

// Calculation using the formula
//
// Parameters:
//  SourceFormula	 - String					 - Value of the original formula
//  CurrentData	 - FormDataCollectionItem	 - Value of the current data in the table part
//  TimeIntervals			 - FormDataCollection			 - Period values
//  Period			 - FormDataCollectionItem	 - Current period value from the period table
//  Presentation	 - String						 - The value of a custom representation of the formula.
//  ServerCall_	 - Boolean
// 
// Returns:
//  Structure - Returns a structure with new formula representation parameters.
//
Function CalculateByFormula(Val SourceFormula, Val CurrentData, Val TimeIntervals, Val Period, Val Presentation = Undefined, ServerCall_ = False) Export
	
	Calculation_Formula = SourceFormula;
	OutputIntermediateCalculations = False;
	Postfix = Undefined;
	
	Parameters = New Structure();
	Parameters.Insert("Period", Period);
	Parameters.Insert("TimeIntervals", TimeIntervals);
	Parameters.Insert("CurrentData", CurrentData);
	
	If Period <> Undefined Then
		Postfix = Period.ColumnName;
	EndIf;
	
	ArrayOfOperands = PlanningClientServer.OperandsOfTextFormula(Calculation_Formula);
	
	For Each Operand In ArrayOfOperands Do
		
		If Postfix <> Undefined Then
			OperandName = Operand + "_" + Postfix;
		Else
			OperandName = Operand;
		EndIf;
		
		If Not CurrentData.Property(OperandName) Then
			Continue;
		EndIf;
		
		OperandValue = CurrentData[OperandName];
		If Not OutputIntermediateCalculations Then
			OutputIntermediateCalculations = Not IsBlankString(StrReplace(Calculation_Formula, "["+Operand+"]", ""));
		EndIf; 
		Calculation_Formula = StrReplace(Calculation_Formula, "["+Operand+"]", Format(OperandValue, "NDS=.; NZ=0; NG=0"));
		
	EndDo;
	
	Calculation_Formula = PlanningClientServer.AddParametersToFunctions(Calculation_Formula, "Parameters");
	
	Try
		CalculationResult = Format(Common.CalculateInSafeMode(Calculation_Formula, Parameters),"ND=15; NFD=3; NZ=0");
	Except
		CalculationResult = 0;
	EndTry;
	
	Calculation_Formula = PlanningClientServer.RemoveParametersInFunctions(Calculation_Formula, "Parameters");
	
	If ValueIsFilled(SourceFormula) And SourceFormula <> PlanningClientServer.TextForSettingNewFormula() Then
		Calculation = SourceFormula + ?(OutputIntermediateCalculations, " = " + Calculation_Formula, "") + " = " + CalculationResult;
	Else
		Calculation = PlanningClientServer.TextForSettingNewFormula();
	EndIf;
	
	If SourceFormula <> PlanningClientServer.TextForSettingNewFormula() Then
		Presentation = ?(ValueIsFilled(Presentation),Presentation,SourceFormula);
	Else
		Presentation = "";
	EndIf;
	
	Return New Structure("Calculation,Result,Presentation", Calculation,CalculationResult,Presentation);
	
EndFunction

#EndRegion

#Region OtherItems

// Returns:
// 	ValueTable - LongDesc:
// * ColumnNumber - Number -
// * ColumnName - String -
// * Active_ - Boolean -
// * StartDate - Date - 
// * EndDate - Date - 
// * Title - String -
// * Substituted - Boolean -
// * SubstitutedToOrder - Boolean -
Function TablePeriods() Export
	
	TablePeriods = New ValueTable();
	TablePeriods.Columns.Add("ColumnNumber",Common.TypeDescriptionNumber(10, 0));
	TablePeriods.Columns.Add("ColumnName",New TypeDescription("String"));
	TablePeriods.Columns.Add("Active_",New TypeDescription("Boolean"));
	TablePeriods.Columns.Add("StartDate",TMCommonUse.GetDescriptionOfDateTypes(DateFractions.DateTime));
	TablePeriods.Columns.Add("EndDate",TMCommonUse.GetDescriptionOfDateTypes(DateFractions.DateTime));
	TablePeriods.Columns.Add("Title",New TypeDescription("String"));
	TablePeriods.Columns.Add("Substituted",New TypeDescription("Boolean"));
	TablePeriods.Columns.Add("SubstitutedToOrder",New TypeDescription("Boolean"));
	
	Return TablePeriods
	
EndFunction

// Copied from the General purpose Clientserver, differs in that it also rounds data in the last period.
// Performs proportional distribution of the amount according
// to the specified distribution coefficients.
//
// Parameters:
//  AmountToDistribute - Number - the amount to be distributed;
//  Coefficients - Array - distribution coefficients;
//  Accuracy - Number - rounding precision in the distribution. Optional.
//
// Returns:
//  Array - an array of dimension equal to the array of coefficients contains
//           sums in accordance with the weight of the coefficient (from the array of coefficients).
//           If the distribution failed (sum = 0, number of coefficients = 0,
//           or total weight of coefficients = 0), then the value is returned Undefined.
//
Function DistributeAmountInProportionToCoefficients(Val AmountToDistribute, Coefficients, Val Accuracy = 2) Export
	
	If Coefficients.Count() = 0 Or Not ValueIsFilled(AmountToDistribute) Then
		Return Undefined;
	EndIf;
	
	MaxCoefficientIndex = 0;
	MaxCoefficient = 0;
	DistributedAmount = 0;
	CoefficientsSum  = 0;
	
	For IndexOf = 0 To Coefficients.Count() - 1 Do
		ZoomRatio = Coefficients[IndexOf];
		
		AbsoluteValueOfCoefficient = ?(ZoomRatio > 0, ZoomRatio, -ZoomRatio);
		If MaxCoefficient < AbsoluteValueOfCoefficient Then
			MaxCoefficient = AbsoluteValueOfCoefficient;
			MaxCoefficientIndex = IndexOf;
		EndIf;
		
		CoefficientsSum = CoefficientsSum + ZoomRatio;
	EndDo;
	
	If CoefficientsSum = 0 Then
		Return Undefined;
	EndIf;
	
	Result = New Array(Coefficients.Count());
	
	For IndexOf = 0 To Coefficients.Count() - 1 Do
		Result[IndexOf] = Round(AmountToDistribute * Coefficients[IndexOf] / CoefficientsSum, Accuracy, 1);
		DistributedAmount = DistributedAmount + Result[IndexOf];
	EndDo;
	
	// The rounding errors are attributed to the coefficient with the maximum weight.
	If Not DistributedAmount = AmountToDistribute Then
		Result[MaxCoefficientIndex] = Round(Result[MaxCoefficientIndex] + AmountToDistribute - DistributedAmount, Accuracy, 1);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a table of data calculated for substitution
//
// Parameters:
//  Parameters  - Structure - Calculation settings.
//
// Returns:
//   ValueTable   - A table with data calculated by the formula.
//
Function FillInForReplacement(Parameters) Export

	SetPrivilegedMode(True);
	
	ManagerName = StrReplace(Parameters.GeneralSettingsKey, "Document.", "");
	
	Query = New Query;
	Query = Documents[ManagerName].ReplacementRequest(Parameters);
	
	QueryResult = Query.Execute();
	
	Return QueryResult.Unload();
	
EndFunction

// Gets the currency of the planning scenario.
//
// Parameters:
//	PlanningScenario - CatalogRef.SalesOperationsPlanningScenarios - planning scenario
// Returns:
//  CatalogRef.Currencies - the currency of the planning scenario.
Function ScenarioCurrency(PlanningScenario) Export
	Return Common.ObjectAttributeValue(PlanningScenario, "Currency");
EndFunction

// The budgeting and Planning subsystem in UT is named Planning.
// The function returns the subsystem depending on the current solution.
// 
// Returns:
//  MetadataObjectSubsystem - subsystem planning.
//
Function SubsystemPlanning() Export
	If GetFunctionalOption("TradeManagement") Then
		Result = Metadata.Subsystems.Find("Planning");
	Else
	
		Result = Metadata.Subsystems.BudgetingAndPlanning;
		
	EndIf;
	Return Result;
	
EndFunction


// Checks for an outstanding budget task
// 
// Parameters:
// 	Cancel - Boolean - indicates that the recording failed
// 	Ref - DocumentRef.PurchasePlan, DocumentRef.PlanOfGoodsStock, DocumentRef.SalesPlan, DocumentRef.SalesPlanByCategories, DocumentRef.AssemblyDisassemblyPlan, DocumentRef.ProductionPlan - link to the document being checked
// 	Var_ThisObject - DocumentObject - the document that the check was called for
Procedure CheckIfBudgetIssueExists(Cancel, Ref, Var_ThisObject) Export
	
	If Not ValueIsFilled(Var_ThisObject.BudgetingScenario) Then
		Return;
	EndIf;
	
	UseBudgetProcess = GetFunctionalOption("UseBudgetProcess");

	If UseBudgetProcess And Not Users.RolesAvailable("EditingBudgetingDataOutsideProcesses")
		And Not Users.IsFullUser(, , True) Then
		
		If Not ValueIsFilled(Ref) Then
			ErrorText = NStr("vi = 'Tạo chứng từ chỉ có thể từ nhiệm vụ ngân sách.';
							|ru = 'Создание документа возможно только из бюджетной задачи.';
							|en = 'Document can be created only from the budget task.'; fa = 'Document can be created only from the budget task.';
							|it = 'È possibile creare un documento solo dal task del budget.';
							|pl = 'Utworzenie dokumentu jest możliwe tylko z zadania budżetowego.';
							|tr = 'Sadece bütçe görevinden belge oluşturulabilir.'");
			CommonClientServer.MessageToUser(
				ErrorText,
				Var_ThisObject,
				, // Field
				, // DataPath
				Cancel);
		Else	
			Query = New Query;
			Query.Text =
			"SELECT
				|	BudgetTaskDocumentsList.Ref
				|FROM
				|	Task.BudgetTask.DocumentsList AS BudgetTaskDocumentsList
				|WHERE
				|	BudgetTaskDocumentsList.Document = &Document
				|	AND NOT BudgetTaskDocumentsList.Ref.Executed
				|	AND BudgetTaskDocumentsList.Ref.Performer = &Performer";
			
			Query.SetParameter("Document", Ref);
			Query.SetParameter("Performer", Users.CurrentUser());
			
			SetPrivilegedMode(True);
			If Query.Execute().IsEmpty() Then
				ErrorText = NStr("vi = 'Thay đổi bị cấm vì Không có nhiệm vụ ngân sách hoạt động.';
								|ru = 'Изменения запрещены, т.к. нет активной бюджетной задачи.';
								|en = 'Changes are prohibited as there is no active budget task.'; fa = 'Changes are prohibited as there is no active budget task.';
								|it = 'La modifica è vietata perché non esiste un task di budget attivo.';
								|pl = 'Zmiany są zakazane, ponieważ brak aktywnego zadania budżetowego.';
								|tr = 'Değişiklikler yasak, çünkü bütçe görevi aktif değil.'");
				CommonClientServer.MessageToUser(
					ErrorText,
					Var_ThisObject,
					, // Field
					, // DataPath
					Cancel);
				
			EndIf;
		EndIf;
	EndIf;

EndProcedure
#EndRegion

#Region InterfaceImplementation

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Planning.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.68";
	Handler.ExecutionMode = "Exclusively";
	Handler.Id = New UUID("37d37b7b-990a-4cf5-81c7-79e32dbc7554");
	Handler.Comment = NStr("vi = 'Đồng bộ các giá trị của các hằng số mới liên quan đến việc tạo chứng từ theo kế hoạch với các hằng số chính, bao gồm việc sử dụng chứng từ và các dạng tương ứng.';
							|ru = 'Синхронизирует значения новых констант использования обработок формирования документов по планам с их ведущими константами: использование документов и соответствующих планов.';
							|en = 'Synchronizes values of new constants for using data processors for converting plans into documents with their leading constants: using documents and corresponding plans.'; fa = 'Synchronizes values of new constants for using data processors for converting plans into documents with their leading constants: using documents and corresponding plans.';
							|it = 'Synchronizes values of new constants for using data processors for converting plans into documents with their leading constants: using documents and corresponding plans.';
							|pl = 'Synchronizes values of new constants for using data processors for converting plans into documents with their leading constants: using documents and corresponding plans.';
							|tr = 'Planlara göre belge oluşturma veri işlemcilerinin kullanımına ilişkin yeni sabitlerin değerlerini, ana sabitleriyle senkronize eder: belgelerin ve ilgili planların kullanımı.'");
	
	ItemsToRead = New Array;
	Editable1 = New Array;
	ConstantMetadata = Metadata.Constants;
	For Each ConstantDetails In DescriptionOfConstantsOfFormationOfDocumentsAccordingToPlans() Do
		ItemsToRead.Add(ConstantMetadata[ConstantDetails.UsingPlans].FullName());
		ItemsToRead.Add(ConstantMetadata[ConstantDetails.UseOfDocuments].FullName());
		Editable1.Add(ConstantMetadata[ConstantDetails.UseOfProcessing].FullName());
	EndDo; 
	
	ItemsToRead = CommonClientServer.CollapseArray(ItemsToRead);
	Editable1 = CommonClientServer.CollapseArray(Editable1);
	
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion() Export
	
	LeadingConstants = New Structure; // To initialize the recalculation of all dependent constants 1 time.
	For Each ConstantDetails In DescriptionOfConstantsOfFormationOfDocumentsAccordingToPlans() Do
		LeadingConstants.Insert(ConstantDetails.UseOfProcessing, ConstantDetails.UseOfDocuments);
	EndDo;
	
	For Each KeyAndValue In LeadingConstants Do
		SynchronizeFormationConstantsAccordingToPlans(KeyAndValue.Value);
	EndDo;
	
EndProcedure

#EndRegion

// Extends the method "System setups.Synchronize the values of subordinate constants."
//
// Parameters:
//   ConstantName - String - The name of the constant that was changed.
//   ConstantValue - Arbitrary - The value of the changed constant.
//   Cancel - Boolean - Indicates that the constant entry failed.
Procedure SynchronizeValuesOfSubordinateConstants(ConstantName, ConstantValue, Cancel) Export
	
	SynchronizeFormationConstantsAccordingToPlans(ConstantName);

EndProcedure

#EndRegion

#EndRegion

#Region ReplacementPlanProcedures

// This procedure starts the background execution of the replaced plans
//
Procedure StartingBackgroundExecutionOfPlan() Export
	
	Var_Key = "PlanSubstitution";
		
	Filter = New Structure();
	Filter.Insert("Key", Var_Key);
	Filter.Insert("State", BackgroundJobState.Active);
	
	SetPrivilegedMode(True);
	
	ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	
	SetPrivilegedMode(False);
	
	If ActiveTasks.Count() > 0 Then
		Return;
	EndIf;
	
	JobDescription = NStr("vi = 'Thay thế / Hủy bỏ kế hoạch thay thế';
							|ru = 'Замещение/отмена замещения планов';
							|en = 'Plan substitution/substitution cancellation'; fa = 'Plan substitution/substitution cancellation';
							|it = 'Sostituzione/cancellazione di sostituzione piani';
							|pl = 'Zastąpienie/anulowanie zastąpienia planów';
							|tr = 'Plan ikamelerinin ikamesi/iptali'");
	
	ExportProcedureName = "Planning.PerformBackgroundPlanning";
	
	ExportProcedureParameters = New Array();
	ExportProcedureParameters.Add(New Structure("ErrorsCount", 0));
	
	JobParameters = New Array();
	JobParameters.Add(ExportProcedureName);
	JobParameters.Add(ExportProcedureParameters);
	
	BackgroundJobs.Execute("Common.ExecuteConfigurationMethod", JobParameters, Var_Key, JobDescription);
	
EndProcedure

// The procedure performs background execution of substituted plans
//
// Parameters:
//  JobParameters  - Structure - the structure stores the number of errors if error is larger than a certain limit,
//                                  the job will be completed.
//
Procedure PerformBackgroundPlanning(JobParameters) Export
	
	If JobParameters.Property("ErrorsCount") Then
		
		MaximumNumberOfErrors = 3;
		
		If JobParameters.ErrorsCount >= MaximumNumberOfErrors Then
			
			DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
			
			MessageText = NStr("vi = 'Bối cảnh thay thế/dừng lại hủy bỏ thay thế. Số lượng lần thử không thành công: %ErrorsCount%';
								|ru = 'Фоновое замещение/отмена замещения планов остановлена. Количество неудачных попыток: %ErrorsCount%';
								|en = 'Background plan substitution/substitution cancellation is stopped. Number of failed attempts: %ErrorsCount%'; fa = 'Background plan substitution/substitution cancellation is stopped. Number of failed attempts: %ErrorsCount%';
								|it = 'Sostituzione in background/cancellazione di sostituzione è interrotta. Numero di tentativi falliti: %ErrorsCount%';
								|pl = 'Zastąpienie w tle/anulowanie zastąpienia planów jest wstrzymane. Ilość nieudanych prób: %ErrorsCount%';
								|tr = 'Arka plan işi ikamesi/plan ikamesinin iptali durduruldu. Başarısız deneme sayısı: %ErrorsCount%'");
			MessageText = StrReplace(MessageText, "%ErrorsCount%", JobParameters.ErrorsCount);
			
			WriteLogEvent(NStr("vi = 'Bối cảnh thay thế / hủy bỏ thay thế';
								|ru = 'Фоновое замещение/отмена замещения плана';
								|en = 'Background plan substitution/substitution cancellation'; fa = 'Background plan substitution/substitution cancellation';
								|it = 'Sostituzione in background/cancellazione di sostituzione del piano';
								|pl = 'Zastąpienie w tle/anulowanie zastąpienia planu';
								|tr = 'Plan arka plan işi ikamesi/ikamesinin iptali'", DefaultLanguageCode),
				EventLogLevel.Error, , ,
				MessageText);
			
			Return;
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	
	Try
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.PlanSubstitution");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		Query = New Query();
		Query.Text = 
		"SELECT DISTINCT
		|	PlanSubstitution.SubstitutedPlan
		|FROM
		|	InformationRegister.PlanSubstitution AS PlanSubstitution
		|WHERE
		|	(PlanSubstitution.ForSubstitution
		|			OR PlanSubstitution.ForSubstitutionCancellation)";
		Selection = Query.Execute().Select();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
		JobParameters.ErrorsCount = JobParameters.ErrorsCount + 1;
		
		MessageText = NStr("vi = 'Không thể khóa biểu ghi ""Thay thế kế hoạch"" bằng nhiệm vụ nền. Số lần thử: %ErrorsCount%';
							|ru = 'Не удалось выполнить блокировку регистра ""Замещение планов"" фоновым заданием. Количество попыток: %ErrorsCount%';
							|en = 'Cannot lock the ""Plan substitution"" register with the background job. Number of attempts: %ErrorsCount%'; fa = 'Cannot lock the ""Plan substitution"" register with the background job. Number of attempts: %ErrorsCount%';
							|it = 'Impossibile eseguire il blocco del registro ""Sostituzione piani"" con un task in background. Numero di tentativi: %ErrorsCount%';
							|pl = 'Nie udało się wykonać blokowanie rejestru ""Замещение планов"" przez zadanie w tle. Ilość prób: %ErrorsCount%';
							|tr = 'Arka plan işlerindeki ""Plan ikamesi"" kaydının kilitlenmesi işlemi gerçekleştirilmedi. Deneme sayısı: %ErrorsCount%'");
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
			MessageText = StrReplace(MessageText, "%ErrorsCount%", JobParameters.ErrorsCount);
		
			WriteLogEvent(NStr("vi = 'Thay thế kế hoạch nền';
								|ru = 'Фоновое замещение плана';
								|en = 'Background plan substitution'; fa = 'Background plan substitution';
								|it = 'Sostituzione del piano in background';
								|pl = 'Zastąpienie w tle planu';
								|tr = 'Arka plan işi plan ikamesi'", DefaultLanguageCode),
				EventLogLevel.Error,
				,
				,
				MessageText);
				
		PerformBackgroundPlanning(JobParameters);
		Return;
	EndTry;
	
	SubstitutionPerformed = True;
	
	While Selection.Next() Do
		JobParameters.Insert("SubstitutedPlan", Selection.SubstitutedPlan);
		PlanImplementation(JobParameters);
		SubstitutionPerformed = False;
	EndDo;
	
	If Not SubstitutionPerformed Then
		PerformBackgroundPlanning(JobParameters);
	EndIf;
	
EndProcedure

Function PlanImplementation(JobParameters)
	
	SubstitutedPlan = JobParameters.SubstitutedPlan;
	
	Try
		SubstitutedObjectPlan = SubstitutedPlan.GetObject();
		SubstitutedObjectPlan.Lock();
		
		If SubstitutedObjectPlan.Posted Then
			SubstitutedObjectPlan.AdditionalProperties.Insert("SkipPeriodClosingCheck");
			SubstitutedObjectPlan.Write(DocumentWriteMode.Posting);
		EndIf;
		Return True;
	Except
		
		DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
		JobParameters.ErrorsCount = JobParameters.ErrorsCount + 1;
		
		MessageText = NStr("vi = 'Không thể thay tế/hủy thay thế kế hoạch %SubstitutedPlan% theo nguyên nhân: %Cause%. Số lần thử: %ErrorsCount%';
							|ru = 'Не удалось выполнить замещение/отмену замещения плана %SubstitutedPlan% фоновым заданием по причине: %Cause%. Количество попыток: %ErrorsCount%';
							|en = 'Cannot perform/cancel substitution for the %SubstitutedPlan% plan with the background job. Reason: %Cause%. Number of attempts: %ErrorsCount%'; fa = 'Cannot perform/cancel substitution for the %SubstitutedPlan% plan with the background job. Reason: %Cause%. Number of attempts: %ErrorsCount%';
							|it = 'Impossibile eseguire la sostituzione/cancellazione di sostituzione del piano %SubstitutedPlan% con un task in background: %Cause%. Numero di tentativi: %ErrorsCount%';
							|pl = 'Nie udało się wykonać zastąpienie/anulowanie zastąpienia planu %SubstitutedPlan% przez zadanie w tle z powodu: %Cause%. Ilość prób: %ErrorsCount%';
							|tr = '%SubstitutedPlan% arka plan işi planının ikamesi/ikamesinin iptali şu sebeple yerine getirilemedi: %Cause%. Deneme sayısı: %ErrorsCount%'");
			MessageText = StrReplace(MessageText, "%SubstitutedPlan%", SubstitutedPlan);
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
			MessageText = StrReplace(MessageText, "%ErrorsCount%", JobParameters.ErrorsCount);
		
			WriteLogEvent(NStr("vi = 'Thay thế kế hoạch nền';
								|ru = 'Фоновое замещение плана';
								|en = 'Background plan substitution'; fa = 'Background plan substitution';
								|it = 'Sostituzione del piano in background';
								|pl = 'Zastąpienie w tle planu';
								|tr = 'Arka plan işi plan ikamesi'", DefaultLanguageCode),
				EventLogLevel.Error,
				SubstitutedPlan.Metadata(),
				SubstitutedPlan,
				MessageText);
		Return False;
	EndTry;
	
EndFunction


// LongDesc
// 
// Parameters:
// 	Parameters - Structure - Content:
// 	 * Ref - DocumentRef.PurchasePlan - 
// 	          - DocumentRef.PlanOfGoodsStock -
// 	          - DocumentRef.SalesPlan -
// 	          - DocumentRef.SalesPlanByCategories -
// 	          - DocumentRef.ProductionPlan -
// 	          - DocumentRef.AssemblyDisassemblyPlan -
// 	DocumentName - String - 
// 	PropsNameStartOfPeriod - String - LongDesc
// Returns:
// 	ValueTable - LongDesc
Function GetSubstitutedPeriods(Parameters, DocumentName , PropsNameStartOfPeriod = "BeginOfPeriod") Export
	
	PlanPeriods = New ValueTable();
	PlanPeriods.Columns.Add("Period", New TypeDescription("Date"));
	
	AddingStartDate = Parameters[PropsNameStartOfPeriod];
	While AddingStartDate < EndOfDay(Parameters.PeriodEnding) Do
		NewRow = PlanPeriods.Add();
		NewRow.Period = AddingStartDate;
		
		EndDateOfPeriod = PlanningClientServerCached.CalculatePeriodEndDate(AddingStartDate, Parameters.Periodicity);
		AddingStartDate = EndDateOfPeriod+1;
	EndDo;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PlanPeriods.Period AS Period
	|INTO PlanPeriods
	|FROM
	|	&PlanPeriods AS PlanPeriods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReplacementPlan.Ref AS Ref,
	|	ReplacementPlan.PlanProfile AS PlanProfile,
	|	CASE
	|		WHEN &BeginOfPeriod > ReplacementPlan.BeginOfPeriod
	|			THEN &BeginOfPeriod
	|		ELSE ReplacementPlan.BeginOfPeriod
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN &PeriodEnding < ReplacementPlan.PeriodEnding
	|			THEN &PeriodEnding
	|		ELSE ReplacementPlan.PeriodEnding
	|	END AS PeriodEnding,
	|	ReplacementPlan.Status AS Status,
	|	ReplacementPlan.Status = VALUE(Enum.PlanStatuses.Upholded)
	|		AND &Status = VALUE(Enum.PlanStatuses.Upholded) AS SubstitutedToOrder,
	|	ReplacementPlan.Status.Order >= &StatusIndex
	|	OR (ReplacementPlan.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|		AND &Status = VALUE(Enum.PlanStatuses.Upholded)) AS Substituted
	|INTO ReplacementPlans
	|FROM
	|	Document.SalesPlan AS ReplacementPlan
	|WHERE
	|	ReplacementPlan.PeriodEnding >= &BeginOfPeriod
	|	AND ReplacementPlan.BeginOfPeriod <= &PeriodEnding
	|	AND ReplacementPlan.Ref <> &Ref
	|	AND ReplacementPlan.Posted
	|	AND ReplacementPlan.PlanProfile = &PlanProfile
	|	AND (ReplacementPlan.Status.Order >= &StatusIndex
	|			OR ReplacementPlan.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|				AND &Status = VALUE(Enum.PlanStatuses.Upholded))
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND ReplacementPlan.Date > &Date
	|	AND &QueryTextFilterDepartment
	|	AND &QueryTextFilterOrganization
	|	AND &QueryTextFilterPartner
	|	AND &QueryTextFilterTerms
	|	AND &QueryTextFilterWarehouse
	|	AND &QueryTextFilterStoreFormat
	|	AND &QueryTextFilterManager
	|	AND &QueryTextFilterBusinessOperation
	|	AND &QueryTextFilterPurpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	PlanPeriods.Period AS SubstitutedPeriod,
	|	MAX(ReplacementPlans.Substituted) AS Substituted,
	|	MAX(ReplacementPlans.SubstitutedToOrder) AS SubstitutedToOrder
	|FROM
	|	ReplacementPlans AS ReplacementPlans
	|		LEFT JOIN PlanPeriods AS PlanPeriods
	|		ON ReplacementPlans.BeginOfPeriod <= PlanPeriods.Period
	|			AND ReplacementPlans.PeriodEnding >= PlanPeriods.Period
	|
	|GROUP BY
	|	PlanPeriods.Period";
	
	Query.Text = StrReplace(Query.Text,
		".SalesPlan",
		"."+DocumentName);
	
	Query.Text = StrReplace(Query.Text,
		"BeginOfPeriod",
		""+PropsNameStartOfPeriod);
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterDepartment",
		?(Parameters.Property("Department"),"ReplacementPlan.Department = &Department","True"));
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterOrganization",
		?(Parameters.Property("Organization"),"ReplacementPlan.Organization = &Organization","True"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterPartner",
		?(Parameters.Property("Partner"),"ReplacementPlan.Partner = &Partner","True"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterTerms",
		?(Parameters.Property("Terms"),"ReplacementPlan.Terms = &Terms","True"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterWarehouse",
		?(Parameters.Property("Warehouse"),"ReplacementPlan.Warehouse = &Warehouse","True"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterStoreFormat",
		?(Parameters.Property("StoreFormat"),"ReplacementPlan.StoreFormat = &StoreFormat","True"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterManager",
		?(Parameters.Property("Manager"),"ReplacementPlan.Manager = &Manager","True"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterPurpose",
		?(Parameters.Property("Purpose"),"ReplacementPlan.Purpose = &Purpose","True"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextFilterBusinessOperation",
		?(Parameters.Property("BusinessOperation"),"ReplacementPlan.BusinessOperation = &BusinessOperation","True"));
		
	Query.SetParameter("Ref", Parameters.Ref);
	Query.SetParameter("PlanProfile", Parameters.PlanProfile);
	Query.SetParameter("StatusIndex", Enums.PlanStatuses.IndexOf(Parameters.Status));
	Query.SetParameter("Status", Parameters.Status);
	Query.SetParameter("Date", Parameters.Date);
	Query.SetParameter(PropsNameStartOfPeriod, Parameters[PropsNameStartOfPeriod]);
	Query.SetParameter("PeriodEnding", Parameters.PeriodEnding);
	Query.SetParameter("Periodicity", Parameters.Periodicity);
	Query.SetParameter("PlanPeriods", PlanPeriods);
	
	If Parameters.Property("Department") Then
		Query.SetParameter("Department", Parameters.Department);
	EndIf;
	If Parameters.Property("Organization") Then
		Query.SetParameter("Organization", Parameters.Organization);
	EndIf;
	If Parameters.Property("Partner") Then
		Query.SetParameter("Partner", Parameters.Partner);
	EndIf;
	If Parameters.Property("Terms") Then
		Query.SetParameter("Terms", Parameters.Terms);
	EndIf;
	If Parameters.Property("Warehouse") Then
		Query.SetParameter("Warehouse", Parameters.Warehouse);
	EndIf;
	If Parameters.Property("StoreFormat") Then
		Query.SetParameter("StoreFormat", Parameters.StoreFormat);
	EndIf;
	If Parameters.Property("Manager") Then
		Query.SetParameter("Manager", Parameters.Manager);
	EndIf;
	If Parameters.Property("Purpose") Then
		Query.SetParameter("Purpose", Parameters.Purpose);
	EndIf;
	If Parameters.Property("BusinessOperation") Then
		Query.SetParameter("BusinessOperation", Parameters.BusinessOperation);
	EndIf;
	
	Return Query.Execute().Unload();

EndFunction

// The procedure updates the hyperlink to go to substituted and replacement plans
//	
// Parameters:
//	Form - ManagedFormExtensionForDocuments - The form of the document plan:
// * Object - DocumentObject - 
//
Procedure UpdateReplacementHyperlink(Form) Export
	
	Object = Form.Object;
	Query = Common.ObjectManagerByRef(Object.Ref).RequestReplacementAndReplacementPlans(Object);
	
	RequestPackage = Query.ExecuteBatch();
	VTReplacementPlans = RequestPackage[0].Unload();
	VTReplacementPlans_ = RequestPackage[1].Unload();
	
	RowArray = New Array;
	If VTReplacementPlans_.Count() > 0 Then
		RowArray.Add(New FormattedString(NStr("vi = 'Thay thế (';
												|ru = 'Замещенные (';
												|en = 'Substituted ('; fa = 'Substituted (';
												|it = 'Sostituiti (';
												|pl = 'Zastąpione (';
												|tr = 'İkame ('") + VTReplacementPlans_.Count() + ")",,StyleColors.TextColorSuccess,,"Replaced_"));
	EndIf;
	If VTReplacementPlans.Count() > 0 Then
		If RowArray.Count()>0 Then
			RowArray.Add(", ");
		EndIf;
		RowArray.Add(New FormattedString(NStr("vi = 'Thay thế (';
												|ru = 'Замещающие (';
												|en = 'Substitute ('; fa = 'Substitute (';
												|it = 'Sostitutivi (';
												|pl = 'Zastępujące (';
												|tr = 'İkame ('") + VTReplacementPlans.Count() + ")",,StyleColors.TextColorIssue,,"Substitutes_1"));
	EndIf;
	If RowArray.Count()= 0 Then
		RowArray.Add(New FormattedString(NStr("vi = 'Không thay thế';
												|ru = 'Без замещения';
												|en = 'Without substitution'; fa = 'Without substitution';
												|it = 'Senza sostituzione';
												|pl = 'Bez zastąpienia';
												|tr = 'İkamesiz'"),,StyleColors.HyperlinkColor));
	EndIf;
	Form.SubstitutionFormattedLine = New FormattedString(RowArray);
	
EndProcedure

// Returns an indication whether the plan is to do the substitution/cancellation substitution.
//
// Parameters:
//	Ref - DocumentRef.SalesPlan, DocumentRef.SalesPlanByCategories, DocumentRef.ProductionPlan, DocumentRef.PurchasePlan, DocumentRef.PlanOfGoodsStock, DocumentRef.AssemblyDisassemblyPlan - link to the plan being checked.
//
// Returns:
//	Boolean - returns True if the replacement/cancellation of the replacement is required for the plan.
//
Function PlanReplacementControl(Ref) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	PlanSubstitution.SubstitutePlan
	|FROM
	|	InformationRegister.PlanSubstitution AS PlanSubstitution
	|WHERE
	|	PlanSubstitution.SubstitutedPlan = &Ref
	|	AND (PlanSubstitution.ForSubstitution
	|			OR PlanSubstitution.ForSubstitutionCancellation)
	|	AND NOT(PlanSubstitution.ForSubstitution
	|				AND PlanSubstitution.ForSubstitutionCancellation)";
	
	Query.SetParameter("Ref", Ref);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Returns the flag for whether to replace/cancel the replacement of plans.
//
Procedure PlanReplacementControl_() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	PlanSubstitution.SubstitutedPlan AS SubstitutedPlan
	|FROM
	|	InformationRegister.PlanSubstitution AS PlanSubstitution
	|WHERE
	|	(PlanSubstitution.ForSubstitution
	|			OR PlanSubstitution.ForSubstitutionCancellation)
	|	AND NOT(PlanSubstitution.ForSubstitution
	|				AND PlanSubstitution.ForSubstitutionCancellation)";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Planning.StartingBackgroundExecutionOfPlan();
	EndIf;
		
EndProcedure

// Returns whether there are entries in the "plan Substitution" register for the plan.
//
// Parameters:
//	Ref - DocumentRef.SalesPlan, DocumentRef.SalesPlanByCategories, DocumentRef.ProductionPlan, DocumentRef.PurchasePlan, DocumentRef.PlanOfGoodsStock, DocumentRef.AssemblyDisassemblyPlan - link to the plan being checked.
//
// Returns:
//	Boolean - returns True if there are records for the plan.
//
Function ThereIsSubstitutionPlan(Ref) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	PlanSubstitution.SubstitutedPlan AS SubstitutedPlan
	|FROM
	|	InformationRegister.PlanSubstitution AS PlanSubstitution
	|WHERE
	|	PlanSubstitution.SubstitutedPlan = &Ref
	|			OR PlanSubstitution.SubstitutePlan = &Ref";
	
	Query.SetParameter("Ref", Ref);
	Return Not Query.Execute().IsEmpty();
		
EndFunction

// For transmitted links, cancellation is made in the order of their date.
//
// Parameters:
//  ReferencesArrray - 	Array, DocumentRef.SalesPlan, DocumentRef.SalesPlanByCategories, DocumentRef.ProductionPlan, DocumentRef.PurchasePlan, DocumentRef.PlanOfGoodsStock, DocumentRef.AssemblyDisassemblyPlan - array of links to plans
//  DocumentName - String - name of the plan document.
// 
Procedure CancelPlans(ReferencesArrray, DocumentName) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SalesPlan.Ref,
	|	SalesPlan.PlanProfile AS PlanProfile,
	|	PRESENTATION(SalesPlan.Ref) AS Presentation,
	|	SalesPlan.Date AS Date
	|FROM
	|	Document.SalesPlan AS SalesPlan
	|WHERE
	|	SalesPlan.Ref IN(&ReferencesArrray)
	|
	|ORDER BY
	|	PlanProfile,
	|	Date";
	
	Query.Text = StrReplace(Query.Text,
		".SalesPlan",
		"."+DocumentName);
	
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	Selection = Query.Execute().Select();
	ErrorTemplate = NStr("vi = 'Không thể hoãn kết chuyển chứng từ %Document%. %ErrorDescription%';
						|ru = 'Не удалось выполнить отмену проведения документа %Document%. %ErrorDescription%';
						|en = 'Cannot cancel the %Document% document posting. %ErrorDescription%'; fa = 'Cannot cancel the %Document% document posting. %ErrorDescription%';
						|it = 'Impossibile eseguire la cancellazione della registrazione del documento %Document%. %ErrorDescription%';
						|pl = 'Nie udało się wykonać anulowanie zaksięgowania dokumentu %Document%. %ErrorDescription%';
						|tr = '%Document% belgesinin yayınlan kaldırılması işlemi gerçekleştirilemedi. %ErrorDescription%'");
	
	While Selection.Next() Do
		
		Try
			DocumentObject = Selection.Ref.GetObject();
			DocumentObject.Lock();
			
			DocumentObject.Write(DocumentWriteMode.UndoPosting);
		Except
			ErrorText = StrReplace(ErrorTemplate, "%Document%", Selection.Presentation);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			CommonClientServer.MessageToUser(ErrorText, Selection.Ref);
		EndTry;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

#Region FormProceduresConfigurationRules

// This function checks whether the settings in the fill rule are correct
//
// Parameters:
//  FillingRule               - ValueTable - Table with sources and rule settings:
//                                    * Source - CatalogRef.PlanningDataSources - 
//  AddressOfDataConversionScheme  - String - Address of the temporary data storage with the data transformation scheme
//  PlanProfile                        - CatalogRef.PlanProfiles - Link to the plan view to define the schema fields
//  RuleDetailsName             - String - The name of the props for which to set the error message
//  SelectionByResources - Structure - Where:
//   *Count - Boolean
//   *Price - Boolean
//   *Sum - Boolean
// Returns:
//  Boolean
//
Function CheckFillingRule(Val FillingRule, Val AddressOfDataConversionScheme, Val PlanProfile = Undefined, Val RuleDetailsName = "", SelectionByResources) Export 
	
	RuleIsCorrect = True;
	
	SchemaFields = GetDataConversionSchemeFields(AddressOfDataConversionScheme, PlanProfile);
	
	AvailabilityOfRequiredFields = True;
	RequiredPeriodField = True;
	MatchingDocumentFields = True;
	
	// Checking string sources (joins)
	MatchingSourceFields = True;
	ReferenceSourceFields = New Structure;
	ThereAreReferenceSourceFields = False;
	ThereIsQuantityField = True;
		
	FoundRows = FillingRule.FindRows(New Structure("Attach, ElementType", False, 0));
	
	RequiredFields = New Array;
	For Each Field In SchemaFields Do
		If Field = "Products"
			Or Field = "ProductCategory" Then
			RequiredFields.Add(Field);
		EndIf;
	EndDo;
	
	ThereAreRulesForFillingIn = False;
	LineNumbersAreRequiredFields = New Array;
	LineNumbersOfDocumentField = New Array;
	LineNumbersRequiredFieldPeriod = New Array;
	LineNumbersWithoutQuantityField = New Array;
	For Each ElementOfRule In FoundRows Do
		
		If Not ElementOfRule.Use Then
			Continue;
		EndIf;
		
		Attributes = Common.ObjectAttributesValues(ElementOfRule.Source, 
			"DCSTemplateName, DataCompositionSchema");
		
		If Attributes.DataCompositionSchema = Undefined Then
			RuleIsCorrect = False;
			ErrorText = NStr("vi = 'Chưa điền nguồn cần điền.';
							|ru = 'Источник заполнения не заполнен.';
							|en = 'Filling source is empty.'; fa = 'Filling source is empty.';
							|it = 'La fonte di compilazione non è compilata.';
							|pl = 'Żródło wypełnienia nie jest wypełnione.';
							|tr = 'Kaynağın doldurulması tamamlanmadı.'");
			Common.MessageToUser(ErrorText,,RuleDetailsName);
			Continue;
		EndIf;
		
		If ValueIsFilled(Attributes.DCSTemplateName) Then
			DataCompositionSchema = Catalogs.PlanningDataSources.LayoutSchemeByTemplateName(Attributes.DCSTemplateName);
			If DataCompositionSchema = Undefined Then
				DataCompositionSchema = Attributes.DataCompositionSchema.Get();
			EndIf; 
		Else
			DataCompositionSchema = Attributes.DataCompositionSchema.Get();
		EndIf;
		
		UserSettingsStorage = ElementOfRule.UserSettings;// ValueStorage
		UserSettings = UserSettingsStorage.Get();
		
		// Loading Settings
		SettingsComposer = New DataCompositionSettingsComposer;
		SetPrivilegedMode(True);
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
		SetPrivilegedMode(False);
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
		
		If UserSettings <> Undefined Then
			
			SettingsComposer.LoadUserSettings(UserSettings);
			
		EndIf;
		
		ChangeToTheSeasonalIndex = False;
		Parameter = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings, "ChangeToTheSeasonalIndex");
		If Parameter <> Undefined Then
			ChangeToTheSeasonalIndex = Parameter.Value;
		EndIf;
		
		DimensionFieldComposer = PlanningClientServer.GetDimensionFields(SettingsComposer);
		
		SelectionFieldComposer = PlanningClientServer.GetSelectionFields(SettingsComposer);
		
		If DimensionFieldComposer.Count() = 0 And SelectionFieldComposer.Count() = 0 Then
			MatchingDocumentFields = False;
			LineNumbersOfDocumentField.Add(ElementOfRule.LineNumber);
		EndIf;
		
		SourceFields = New Array;
		For Each Group In DimensionFieldComposer Do
			If Not Group.Use Then
				Continue;
			EndIf;
			If SourceFields.Find(String(Group.Field)) = Undefined Then
				SourceFields.Add(String(Group.Field));
			EndIf;
			If SchemaFields.Find(String(Group.Field)) = Undefined Then
				MatchingDocumentFields = False;
				LineNumbersOfDocumentField.Add(ElementOfRule.LineNumber);
			EndIf;
			If ThereAreReferenceSourceFields Then
				If Not ReferenceSourceFields.Property(String(Group.Field)) Then
					MatchingSourceFields = False;
					Break;
				EndIf;
			Else
				ReferenceSourceFields.Insert(String(Group.Field));
			EndIf; 
		EndDo;
		
		ThereIsQuantityField = False;
		FieldOfQuantity = New DataCompositionField("Count");
		For Each SelectedField In SelectionFieldComposer Do
			If Not SelectedField.Use Then
				Continue;
			EndIf;
			If SourceFields.Find(String(SelectedField.Field)) = Undefined Then
				SourceFields.Add(String(SelectedField.Field));
			EndIf;
			If SchemaFields.Find(String(SelectedField.Field)) = Undefined Then
				MatchingDocumentFields = False;
				LineNumbersOfDocumentField.Add(ElementOfRule.LineNumber);
			EndIf;
			If SelectedField.Field = FieldOfQuantity Then
				ThereIsQuantityField = True;
			EndIf;
			If ThereAreReferenceSourceFields Then
				If Not ReferenceSourceFields.Property(String(SelectedField.Field)) Then
					MatchingSourceFields = False;
				EndIf;
			Else
				ReferenceSourceFields.Insert(String(SelectedField.Field));
			EndIf;
		EndDo;
		
		If Not ThereIsQuantityField Then
			LineNumbersWithoutQuantityField.Add(ElementOfRule.LineNumber);
		EndIf;
		
		If ThereAreReferenceSourceFields And SourceFields.Count() <> ReferenceSourceFields.Count() Then
			MatchingSourceFields = False;
		EndIf; 
		
		ThereAreRequiredFields = False;
		ThereIsRequiredFieldPeriod = False;
		For Each SourceField In SourceFields Do
			If RequiredFields.Find(SourceField) <> Undefined Then
				ThereAreRequiredFields = True;
			EndIf;
			If ChangeToTheSeasonalIndex And SourceField = "Period" Then
				ThereIsRequiredFieldPeriod = True;
			EndIf;
			If ThereAreRequiredFields And (ThereIsRequiredFieldPeriod Or Not ChangeToTheSeasonalIndex) Then
				Break;
			EndIf;
		EndDo;
		
		If Not ThereAreRequiredFields Then
			AvailabilityOfRequiredFields = False;
			LineNumbersAreRequiredFields.Add(ElementOfRule.LineNumber);
		EndIf;
		
		If ChangeToTheSeasonalIndex And Not ThereIsRequiredFieldPeriod Then
			RequiredPeriodField = False;
			LineNumbersRequiredFieldPeriod.Add(ElementOfRule.LineNumber);
		EndIf;
		
		ThereAreReferenceSourceFields = True;
		
		ThereAreRulesForFillingIn = True;
		
		If Not MatchingDocumentFields And Not MatchingSourceFields And Not AvailabilityOfRequiredFields Then
			Break;
		EndIf;
		
	EndDo; 
	
	If Not ThereAreRulesForFillingIn Then
		RuleIsCorrect = False;
		ErrorText = NStr("vi = 'Chưa điền nguồn điền số lượng.';
						|ru = 'Не заполнены источники заполнения количества.';
						|en = 'Quantity filling sources are empty.'; fa = 'Quantity filling sources are empty.';
						|it = 'Le fonti di compilazione quantità non sono compilate.';
						|pl = 'Nie są wypełnione źródła wypełnienia ilości.';
						|tr = 'Miktar doldurma kaynakları doldurulmadı.'");
		Common.MessageToUser(ErrorText,,RuleDetailsName);
	EndIf;
	
	If Not MatchingDocumentFields Or Not MatchingSourceFields Or Not AvailabilityOfRequiredFields Or Not RequiredPeriodField Or Not ThereIsQuantityField Then
		RuleIsCorrect = False;
	EndIf;
		
	ErrorText = NStr("vi = 'Danh sách các trường nguồn điền số lượng là khác nhau. Chỉnh sửa các nhóm và các lĩnh vực được chọn.';
					|ru = 'Список полей источников заполнения количества различается. Отредактируйте группировки и выбранные поля.';
					|en = 'The list of quantity filling source fields is different. Edit groupings and the selected fields.'; fa = 'The list of quantity filling source fields is different. Edit groupings and the selected fields.';
					|it = 'L''elenco dei campi delle fonti di compilazione quantità differisce. Modificare raggruppamenti e campi selezionati.';
					|pl = 'Lista pól źródeł wypełnienia ilości różni się. Edytuj grupowania i wybrane pola.';
					|tr = 'Kaynak alan listelerinin doldurulma sayıları farklılık gösteriyor. Gruplamaları ve seçili alanları düzenleyiniz.'");
	If Not MatchingSourceFields Then
		Common.MessageToUser(ErrorText,,RuleDetailsName);
	EndIf; 
	
	ErrorText = NStr("vi = 'Nội dung của các trường được trả về bởi các nguồn khác với dữ liệu của chứng từ. Hãy chỉnh sửa ""Gom nhóm"" và ""Trường đã chọn"" bằng cách xóa các trường không cần thiết %1.';
					|ru = 'Состав полей, возвращаемых источниками заполнения количества, не совпадает с данными документа. Отредактируйте ""Группировки"" и ""Выбранные поля"", исключив ненужные поля %1.';
					|en = 'Fields returned by the quantity filling sources are different from the document data. Edit ""Groups"" and ""Selected fields"" by removing unnecessary fields%1.'; fa = 'Fields returned by the quantity filling sources are different from the document data. Edit ""Groups"" and ""Selected fields"" by removing unnecessary fields%1.';
					|it = 'Состав полей, возвращаемых источниками заполнения количества, не совпадает с данными документа. Отредактируйте ""Группировки"" и ""Выбранные поля"", исключив ненужные поля %1.';
					|pl = 'Fields returned by the quantity filling sources are different from the document data. Edit ""Groups"" and ""Selected fields"" by removing unnecessary fields%1.';
					|tr = 'Alan derlemesi ve geri getirilen sayı doldurulma kaynakları belge verileriyle eşleşmiyor. %1 gereksiz alanını hariç tutarak ""Gruplamalar"" ve ""Seçili alanlar"" kısımlarını düzenleyiniz.'");
	If Not MatchingDocumentFields Then
		
		LineNumbersOfDocumentField = CommonClientServer.CollapseArray(LineNumbersOfDocumentField);
		If LineNumbersOfDocumentField.Count() > 1 Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'trong dòng:';
																								|ru = 'в строках:';
																								|en = 'in lines:'; fa = 'in lines:';
																								|it = 'в строках:';
																								|pl = 'in lines:';
																								|tr = 'satırlarda:'") + " " + StrConcat(LineNumbersOfDocumentField, ", "));
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'trong dòng';
																								|ru = 'в строке';
																								|en = 'in line'; fa = 'in line';
																								|it = 'в строке';
																								|pl = 'in line';
																								|tr = 'satırda'") + " " + StrConcat(LineNumbersOfDocumentField, ", "));
		EndIf;
		Common.MessageToUser(ErrorText,,RuleDetailsName);
		
	EndIf;
	
	ErrorText = NStr("vi = 'Trong danh sách các trường của nguồn, không có trường bắt buộc ""%1"". Hãy soạn gom nhóm và các trường đã chọn %2.';
					|ru = 'В списке полей источника отсутствует обязательное поле ""%1"". Отредактируйте группировки и выбранные поля %2.';
					|en = 'The source field list does not contain the required ""%1"" field. Edit groupings and selected fields %2.'; fa = 'The source field list does not contain the required ""%1"" field. Edit groupings and selected fields %2.';
					|it = 'В списке полей источника отсутствует обязательное поле ""%1"". Отредактируйте группировки и выбранные поля %2.';
					|pl = 'The source field list does not contain the required ""%1"" field. Edit groupings and selected fields %2.';
					|tr = 'Kaynak alanları listesinde ""%1"" gerekli alanı eksik. Gruplamaları ve %2 seçili alanlarını düzenleyiniz.'");
	
	If Not AvailabilityOfRequiredFields Then
		If LineNumbersAreRequiredFields.Count() > 1 Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, RequiredFields[0], NStr("vi = 'trong dòng:';
																													|ru = 'в строках:';
																													|en = 'in lines:'; fa = 'in lines:';
																													|it = 'в строках:';
																													|pl = 'in lines:';
																													|tr = 'satırlarda:'") + " " + StrConcat(LineNumbersAreRequiredFields, ", "));
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, RequiredFields[0], NStr("vi = 'trong dòng';
																													|ru = 'в строке';
																													|en = 'in line'; fa = 'in line';
																													|it = 'в строке';
																													|pl = 'in line';
																													|tr = 'satırda'") + " " + StrConcat(LineNumbersAreRequiredFields, ", "));
		EndIf;
		
		Common.MessageToUser(ErrorText,,RuleDetailsName);
	EndIf;
	
	ErrorText = NStr("vi = 'Trong thành phần các trường do nguồn điền số lượng trả lại, không có trường ""Số lượng"" %1. Hãy chỉnh sửa ""Trường được chọn"" hoặc sử dụng nguồn khác';
					|ru = 'В составе полей, возвращаемых источниками заполнения количества, отсутствует поле ""Количество"" %1. Отредактируйте ""Выбранные поля"" или используйте другой источник';
					|en = 'Fields returned by the quantity population sources do not contain the ""Quantity"" field %1. Edit ""Selected fields"" or use another source'; fa = 'Fields returned by the quantity population sources do not contain the ""Quantity"" field %1. Edit ""Selected fields"" or use another source';
					|it = 'В составе полей, возвращаемых источниками заполнения количества, отсутствует поле ""Количество"" %1. Отредактируйте ""Выбранные поля"" или используйте другой источник';
					|pl = 'Fields returned by the quantity population sources do not contain the ""Quantity"" field %1. Edit ""Selected fields"" or use another source';
					|tr = 'Miktar doldurma kaynakları tarafından döndürülen alanların içeriğinde ""Miktar"" alanı %1 yoktur. ""Seçili alanları"" düzenleyin veya başka kaynak kullanın'");
	If Not ThereIsQuantityField Then
		
		If LineNumbersWithoutQuantityField.Count() > 1 Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'trong dòng:';
																								|ru = 'в строках:';
																								|en = 'in lines:'; fa = 'in lines:';
																								|it = 'в строках:';
																								|pl = 'in lines:';
																								|tr = 'satırlarda:'") + " " + StrConcat(LineNumbersWithoutQuantityField, ", "));
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'trong dòng';
																								|ru = 'в строке';
																								|en = 'in line'; fa = 'in line';
																								|it = 'в строке';
																								|pl = 'in line';
																								|tr = 'satırda'") + " " + StrConcat(LineNumbersWithoutQuantityField, ", "));
		EndIf;
		
		Common.MessageToUser(ErrorText,,RuleDetailsName);
	EndIf;
	
	ErrorText = NStr("vi = 'Khi sử dụng hệ số theo mùa, cần chỉ ra trường ""Kỳ"" trong danh sách các trường của nguồn. Hãy soạn gom nhóm và trường được chọn %1.';
					|ru = 'При использовании сезонных коэффициентов необходимо в списке полей источника указать поле ""Период"". Отредактируйте группировки и выбранные поля %1.';
					|en = 'When using seasonal indexes, specify the Period field in the list of source fields. Edit groupings and selected fields %1.'; fa = 'When using seasonal indexes, specify the Period field in the list of source fields. Edit groupings and selected fields %1.';
					|it = 'При использовании сезонных коэффициентов необходимо в списке полей источника указать поле ""Период"". Отредактируйте группировки и выбранные поля %1.';
					|pl = 'When using seasonal indexes, specify the Period field in the list of source fields. Edit groupings and selected fields %1.';
					|tr = 'Mevsimsel katsayının kullanılması için listede ""Dönem"" alanının kaynak alanında belirt. Gruplamaları ve %1 seçili alanlarını düzenleyiniz.'");
	
	If Not RequiredPeriodField Then
		If LineNumbersRequiredFieldPeriod.Count() > 1 Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'trong dòng:';
																								|ru = 'в строках:';
																								|en = 'in lines:'; fa = 'in lines:';
																								|it = 'в строках:';
																								|pl = 'in lines:';
																								|tr = 'satırlarda:'") + " " + StrConcat(LineNumbersRequiredFieldPeriod, ", "));
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'trong dòng';
																								|ru = 'в строке';
																								|en = 'in line'; fa = 'in line';
																								|it = 'в строке';
																								|pl = 'in line';
																								|tr = 'satırda'") + " " + StrConcat(LineNumbersRequiredFieldPeriod, ", "));
		EndIf;
		
		Common.MessageToUser(ErrorText,,RuleDetailsName);
	EndIf;
	
	// Checking column sources (connections)
	MatchingSourceFields = True;
	MatchingDocumentFields = True;
	ReferenceSourceFields = New Structure;
	ThereAreReferenceSourceFields = False;
	ThereIsPriceField = True;
	RequiredPeriodField = True;
	
	LineNumbersAreRequiredFields = New Array;
	LineNumbersOfDocumentField = New Array;
	LineNumbersWithoutPriceField = New Array;
	LineNumbersRequiredFieldPeriod = New Array;
	
	FoundRows = FillingRule.FindRows(New Structure("Attach, ElementType", True, 0));
	For Each ElementOfRule In FoundRows Do
		
		If Not ElementOfRule.Use Then
			Continue;
		EndIf;
		
		Attributes = Common.ObjectAttributesValues(ElementOfRule.Source, 
			"DCSTemplateName, DataCompositionSchema");
		
		If Attributes.DataCompositionSchema = Undefined Then
			RuleIsCorrect = False;
			ErrorText = NStr("vi = 'Chưa điền nguồn cần điền.';
							|ru = 'Источник заполнения не заполнен.';
							|en = 'Filling source is empty.'; fa = 'Filling source is empty.';
							|it = 'La fonte di compilazione non è compilata.';
							|pl = 'Żródło wypełnienia nie jest wypełnione.';
							|tr = 'Kaynağın doldurulması tamamlanmadı.'");
			Common.MessageToUser(ErrorText,,RuleDetailsName);
			Continue;
		EndIf;
		
		If ValueIsFilled(Attributes.DCSTemplateName) Then
			DataCompositionSchema = Catalogs.PlanningDataSources.LayoutSchemeByTemplateName(Attributes.DCSTemplateName);
			If DataCompositionSchema = Undefined Then
				DataCompositionSchema = Attributes.DataCompositionSchema.Get();
			EndIf; 
		Else
			DataCompositionSchema = Attributes.DataCompositionSchema.Get();
		EndIf;
		UserSettingsStorage = ElementOfRule.UserSettings;// ValueStorage
		UserSettings = UserSettingsStorage.Get();
		
		// Loading Settings
		SettingsComposer = New DataCompositionSettingsComposer;
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
		
		If UserSettings <> Undefined Then
			
			SettingsComposer.LoadUserSettings(UserSettings);
			
		EndIf;
		
		ChangeToTheSeasonalIndex = False;
		Parameter = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings, "ChangeToTheSeasonalIndex");
		If Parameter <> Undefined Then
			ChangeToTheSeasonalIndex = Parameter.Value;
		EndIf;
		
		DimensionFieldComposer = PlanningClientServer.GetDimensionFields(SettingsComposer);
		
		SelectionFieldComposer = PlanningClientServer.GetSelectionFields(SettingsComposer);
		
		If DimensionFieldComposer.Count() = 0 And SelectionFieldComposer.Count() = 0 Then
			MatchingDocumentFields = False;
			LineNumbersOfDocumentField.Add(ElementOfRule.LineNumber);
		EndIf;
		
		ThereIsMandatoryPeriodField = False;
		SourceFields = New Array;
		For Each Group In DimensionFieldComposer Do
			If Not Group.Use Then
				Continue;
			EndIf;
			If ChangeToTheSeasonalIndex And String(Group.Field) = "Period" Then
				ThereIsMandatoryPeriodField = True;
			EndIf;
			If SourceFields.Find(String(Group.Field)) = Undefined Then
				SourceFields.Add(String(Group.Field));
			EndIf;
			If SchemaFields.Find(String(Group.Field)) = Undefined Then
				MatchingDocumentFields = False;
				LineNumbersOfDocumentField.Add(ElementOfRule.LineNumber);
			EndIf;
			If ThereAreReferenceSourceFields Then
				If Not ReferenceSourceFields.Property(String(Group.Field)) Then
					MatchingSourceFields = False;
					Break;
				EndIf;
			Else
				ReferenceSourceFields.Insert(String(Group.Field));
			EndIf; 
		EndDo;
		
		ThereIsPriceField = False;
		FieldOfPrice = New DataCompositionField("Price");
		For Each SelectedField In SelectionFieldComposer Do
			If Not SelectedField.Use Then
				Continue;
			EndIf;
			If SourceFields.Find(String(SelectedField.Field)) = Undefined Then
				SourceFields.Add(String(SelectedField.Field));
			EndIf;
			If SchemaFields.Find(String(SelectedField.Field)) = Undefined Then
				MatchingDocumentFields = False;
				LineNumbersOfDocumentField.Add(ElementOfRule.LineNumber);
			EndIf;
			If SelectedField.Field = FieldOfPrice Then
				ThereIsPriceField = True;
			EndIf;
			If ThereAreReferenceSourceFields Then
				If Not ReferenceSourceFields.Property(String(SelectedField.Field)) Then
					MatchingSourceFields = False;
				EndIf;
			Else
				ReferenceSourceFields.Insert(String(SelectedField.Field));
			EndIf;
		EndDo;
		
		If Not ThereIsPriceField Then
			LineNumbersWithoutPriceField.Add(ElementOfRule.LineNumber);
		EndIf;
		
		If ChangeToTheSeasonalIndex And Not ThereIsMandatoryPeriodField Then
			RequiredPeriodField = False;
			LineNumbersRequiredFieldPeriod.Add(ElementOfRule.LineNumber);
		EndIf;
		
		If ThereAreReferenceSourceFields And SourceFields.Count() <> ReferenceSourceFields.Count() Then
			MatchingSourceFields = False;
		EndIf; 
		
		ThereAreReferenceSourceFields = True;
		
		If Not MatchingDocumentFields And Not MatchingSourceFields Then
			Break;
		EndIf;
	
	EndDo;
	
	If Not MatchingDocumentFields Or Not MatchingSourceFields Or Not ThereIsPriceField Or Not RequiredPeriodField Then
		RuleIsCorrect = False;
	EndIf;
		
	ErrorText = NStr("vi = 'Nội dung của các lĩnh vực được trả về bởi các nguồn dân số giá là khác nhau. Chỉnh sửa ""Gom nhóm"" và ""Các trường được chọn"" để mọi nguồn đều trả về cùng một nội dung trường.';
					|ru = 'Состав полей, возвращаемых источниками заполнения цены, различается. Отредактируйте ""Группировки"" и ""Выбранные поля"", чтобы каждый источник возвращал одинаковый состав полей.';
					|en = 'Content of fields returned by the price population sources is different. Edit ""Groupings"" and ""Selected fields"" for every source to return the same field content.'; fa = 'Content of fields returned by the price population sources is different. Edit ""Groupings"" and ""Selected fields"" for every source to return the same field content.';
					|it = 'La composizione dei campi restituiti dalle fonti di compilazione prezzo differisce. Modificare ""Raggruppamenti"" e ""Campi selezionati"" in modo che ciascuna fonte restituisca la stessa composizione di campi.';
					|pl = 'Zestaw pól, zwracanych przez źródła wypełnienia ceny, różni się. Edytuj ""Группировки"" i ""Выбранные поля"", aby każde źródło zwracało jednakowy zestal pól.';
					|tr = 'Alan derlemesi ve geri getirilen sayı doldurulma kaynakları belge verileriyle eşleşmiyor. Her kaynağın aynı alanın bileşimine döndürülmesi için ""Gruplamalar"" ve ""Seçili alanlar"" kısımlarını düzenleyiniz.'");
	If Not MatchingSourceFields Then
		Common.MessageToUser(ErrorText,,RuleDetailsName);
	EndIf;
	
	ErrorText = NStr("vi = 'Nội dung của các trường được trả về bởi các nguồn điền giá khác với dữ liệu của chứng từ. Hãy chỉnh sửa ""Gom nhóm"" và ""Trường đã chọn"" bằng cách xóa các trường không cần thiết %1.';
					|ru = 'Состав полей, возвращаемых источниками заполнения цены, не совпадает с данными документа. Отредактируйте ""Группировки"" и ""Выбранные поля"", исключив ненужные поля %1.';
					|en = 'Fields returned by the price population sources are different from the document data. Edit ""Groups"" and ""Selected fields"" by removing unnecessary fields%1.'; fa = 'Fields returned by the price population sources are different from the document data. Edit ""Groups"" and ""Selected fields"" by removing unnecessary fields%1.';
					|it = 'Состав полей, возвращаемых источниками заполнения цены, не совпадает с данными документа. Отредактируйте ""Группировки"" и ""Выбранные поля"", исключив ненужные поля %1.';
					|pl = 'Fields returned by the price population sources are different from the document data. Edit ""Groups"" and ""Selected fields"" by removing unnecessary fields%1.';
					|tr = 'Alan derlemesi ve geri getirilen fiyat doldurulma sayısı kaynakları belge verileriyle eşleşmiyor. %1 gereksiz alanını hariç tutarak ""Gruplamalar"" ve ""Seçili alanlar"" kısımlarını düzenleyiniz.'");
	If Not MatchingDocumentFields Then
		
		LineNumbersOfDocumentField = CommonClientServer.CollapseArray(LineNumbersOfDocumentField);
		If LineNumbersOfDocumentField.Count() > 1 Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'trong dòng:';
																								|ru = 'в строках:';
																								|en = 'in lines:'; fa = 'in lines:';
																								|it = 'в строках:';
																								|pl = 'in lines:';
																								|tr = 'satırlarda:'") + " " + StrConcat(LineNumbersOfDocumentField, ", "));
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'trong dòng';
																								|ru = 'в строке';
																								|en = 'in line'; fa = 'in line';
																								|it = 'в строке';
																								|pl = 'in line';
																								|tr = 'satırda'") + " " + StrConcat(LineNumbersOfDocumentField, ", "));
		EndIf;
		
		Common.MessageToUser(ErrorText,,RuleDetailsName);
		
	EndIf; 
	
	ErrorText = NStr("vi = 'Trong thành phần các trường do nguồn điền đơn giá trả lại, không có trường ""Đơn giá"" %1. Hãy chỉnh sửa ""Trường được chọn"" hoặc sử dụng nguồn khác';
					|ru = 'В составе полей, возвращаемых источниками заполнения цены, отсутствует поле ""Цена"" %1. Отредактируйте ""Выбранные поля"" или используйте другой источник';
					|en = 'Fields returned by the price population sources do not contain the ""Price"" field %1. Edit ""Selected fields"" or use another source'; fa = 'Fields returned by the price population sources do not contain the ""Price"" field %1. Edit ""Selected fields"" or use another source';
					|it = 'В составе полей, возвращаемых источниками заполнения цены, отсутствует поле ""Цена"" %1. Отредактируйте ""Выбранные поля"" или используйте другой источник';
					|pl = 'Fields returned by the price population sources do not contain the ""Price"" field %1. Edit ""Selected fields"" or use another source';
					|tr = 'Alan derlemesi alanındaki geri getirilen fiyat doldurulma sayısı kaynakları belge verileriyle eşleşmiyor. %1 gereksiz alanını hariç tutarak ""Gruplamalar"" ve ""Seçili alanlar"" kısımlarını düzenleyiniz veya başka bir kaynak kullanınız'");
	If Not ThereIsPriceField Then
		
		If LineNumbersWithoutPriceField.Count() > 1 Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'trong dòng:';
																								|ru = 'в строках:';
																								|en = 'in lines:'; fa = 'in lines:';
																								|it = 'в строках:';
																								|pl = 'in lines:';
																								|tr = 'satırlarda:'") + " " + StrConcat(LineNumbersWithoutPriceField, ", "));
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'trong dòng';
																								|ru = 'в строке';
																								|en = 'in line'; fa = 'in line';
																								|it = 'в строке';
																								|pl = 'in line';
																								|tr = 'satırda'") + " " + StrConcat(LineNumbersWithoutPriceField, ", "));
		EndIf;
		
		Common.MessageToUser(ErrorText,,RuleDetailsName);
	EndIf;
	
	ErrorText = NStr("vi = 'Khi sử dụng hệ số theo mùa, cần chỉ ra trường ""Kỳ"" trong danh sách các trường của nguồn. Hãy soạn gom nhóm và trường được chọn %1.';
					|ru = 'При использовании сезонных коэффициентов необходимо в списке полей источника указать поле ""Период"". Отредактируйте группировки и выбранные поля %1.';
					|en = 'When using seasonal indexes, specify the Period field in the list of source fields. Edit groupings and selected fields %1.'; fa = 'When using seasonal indexes, specify the Period field in the list of source fields. Edit groupings and selected fields %1.';
					|it = 'При использовании сезонных коэффициентов необходимо в списке полей источника указать поле ""Период"". Отредактируйте группировки и выбранные поля %1.';
					|pl = 'When using seasonal indexes, specify the Period field in the list of source fields. Edit groupings and selected fields %1.';
					|tr = 'Mevsimsel katsayının kullanılması için listede ""Dönem"" alanının kaynak alanında belirt. Gruplamaları ve %1 seçili alanlarını düzenleyiniz.'");
	
	If Not RequiredPeriodField Then
		If LineNumbersRequiredFieldPeriod.Count() > 1 Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'trong dòng:';
																								|ru = 'в строках:';
																								|en = 'in lines:'; fa = 'in lines:';
																								|it = 'в строках:';
																								|pl = 'in lines:';
																								|tr = 'satırlarda:'") + " " + StrConcat(LineNumbersRequiredFieldPeriod, ", "));
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'trong dòng';
																								|ru = 'в строке';
																								|en = 'in line'; fa = 'in line';
																								|it = 'в строке';
																								|pl = 'in line';
																								|tr = 'satırda'") + " " + StrConcat(LineNumbersRequiredFieldPeriod, ", "));
		EndIf;
		
		Common.MessageToUser(ErrorText,,RuleDetailsName);
	EndIf;
	
	NumberOfSourcesFillingNumberOfFirstLevel = FillingRule.FindRows(New Structure("Attach, RowNumberParent", False, 0)).Count();
	NumberOfSourcesOfFillingPriceOfFirstLevel = FillingRule.FindRows(New Structure("Attach, RowNumberParent", True, 0)).Count();
	
	If NumberOfSourcesFillingNumberOfFirstLevel > 1 
		And SelectionByResources.Count Then
		RuleIsCorrect = False;
		ErrorText = NStr("vi = 'Đã thiết lập bộ lọc tại trường nguồn ""Số lượng"", để áp dụng chính xác, cần gom nhóm các nguồn ở lớp đầu tiên.';
						|ru = 'Установлен отбор на поле ресурса ""Количество"", для корректного применения отбора источники должны быть сгруппированы на первом уровне.';
						|en = 'Filter is set in the field of the Amount resource. Sources should be grouped on the first level for the filter to be applied correctly.'; fa = 'Filter is set in the field of the Amount resource. Sources should be grouped on the first level for the filter to be applied correctly.';
						|it = 'La selezione è impostata nel campo della risorsa ""Quantità"", per la corretta applicazione della selezione le fonti devono essere raggruppati al primo livello.';
						|pl = 'Jest ustanowiony wybór w polu zasobu ""Количество"", dla poprawnego stosowania selekcji źródła powinny być zgrupowane na pierwszym poziomie.';
						|tr = '""Sayı"" kaynağının alanında seçimi doğru bir şekilde uygulamak için kaynakların ilk seviyede gruplandırılması için filtre ayarlandı.'");
		Common.MessageToUser(ErrorText,,RuleDetailsName);
	EndIf;
	
	If NumberOfSourcesOfFillingPriceOfFirstLevel > 1 
		And SelectionByResources.Price Then
		RuleIsCorrect = False;
		ErrorText = NStr("vi = 'Đã thiết lập bộ lọc tại trường nguồn ""Đơn giá"", để bộ lọc được áp dụng chính xác, cần gom nhóm các nguồn ở lớp đầu tiên.';
						|ru = 'Установлен отбор на поле ресурса ""Цена"", для корректного применения отбора источники должны быть сгруппированы на первом уровне.';
						|en = 'Filter is selected for the Price field. For the filter to be applied correctly, sources must be grouped at the first level.'; fa = 'Filter is selected for the Price field. For the filter to be applied correctly, sources must be grouped at the first level.';
						|it = 'La selezione è impostata nel campo della risorsa ""Prezzo"", per la corretta applicazione della selezione le fonti devono essere raggruppati al primo livello.';
						|pl = 'Jest ustanowiony wybór w polu zasobu ""Цена"", dla poprawnego stosowania selekcji źródła powinny być zgrupowane na pierwszym poziomie.';
						|tr = 'Filtre, ""Fiyat"" kaynak alanında yapılandırıldı, filtrenin doğru uygulanması için kaynaklar ilk seviyede gruplanmalıdır.'");
		Common.MessageToUser(ErrorText,,RuleDetailsName);
	EndIf;
	
	If (NumberOfSourcesOfFillingPriceOfFirstLevel > 1
		Or NumberOfSourcesFillingNumberOfFirstLevel > 1)
		And SelectionByResources.Sum Then
		RuleIsCorrect = False;
		ErrorText = NStr("vi = 'Đã thiết lập bộ lọc tại trường nguồn ""Số tiền"", để áp dụng chính xác bộ lọc, cần gom nhóm các nguồn ở lớp đầu tiên.';
						|ru = 'Установлен отбор на поле ресурса ""Сумма"", для корректного применения отбора источники должны быть сгруппированы на первом уровне.';
						|en = 'Filter is set for the Amount resource field. For the filter to be applied correctly, sources must be grouped on the first level.'; fa = 'Filter is set for the Amount resource field. For the filter to be applied correctly, sources must be grouped on the first level.';
						|it = 'La selezione è impostata nel campo della risorsa ""Importo"", per la corretta applicazione della selezione le fonti devono essere raggruppati al primo livello.';
						|pl = 'Jest ustanowiony wybór w polu zasobu ""Сумма"", dla poprawnego stosowania selekcji źródła powinny być zgrupowane na pierwszym poziomie.';
						|tr = 'Filtre, ""Tutar"" kaynak alanında yapılandırıldı, filtrenin doğru uygulanması için kaynaklar ilk seviyede gruplanmalıdır.'");
		Common.MessageToUser(ErrorText,,RuleDetailsName);
	EndIf;
	
	Return RuleIsCorrect;

EndFunction 

// Caches the current values of the settings, planning forms, and information notices.
//
// Parameters:
//  Form  - ClientApplicationForm - the form for which actions are performed.
//
Procedure SaveNewPeriod(Form) Export
	
	Object = Form.Object;
	
	// Saving values from period fields
	Form.ScenarioBeforeChange           = Object.Scenario;
	Form.ViewOfThePlanBeforeTheChange           = Object.PlanProfile;
	Form.FrequencyBeforeChange      = Object.Periodicity;
	Form.PeriodStartBeforeChanging      = Object.BeginOfPeriod;
	Form.PeriodEndBeforeChange   = Object.PeriodEnding;
	Form.PlanByAmountBeforeChange = Object.PlanByAmount;
	
	Form.CaptionFrequencyCurrency = "";
	
	If Not Object.Periodicity.IsEmpty() Then
		Form.CaptionFrequencyCurrency = Form.CaptionFrequencyCurrency +NStr("vi = 'Tính định kỳ';
																			|ru = 'Периодичность';
																			|en = 'Frequency'; fa = 'تناوب';
																			|it = 'Periodicità';
																			|pl = 'Frequency';
																			|tr = 'Sıklık'") + ": " + String(Object.Periodicity);
	EndIf;
	If Object.PlanByAmount Then
		Form.CaptionFrequencyCurrency = Form.CaptionFrequencyCurrency + ", " + NStr("vi = 'Tiền tệ';
																					|ru = 'Валюта';
																					|en = 'Currency'; fa = 'ارز';
																					|it = 'Valuta';
																					|pl = 'Currency';
																					|tr = 'Para birimi'") + ": " + String(Object.Currency);
	EndIf; 
	
EndProcedure

// The function retrieves an array of data conversion schema fields in the plan document
//
// Parameters:
//  AddressOfDataConversionScheme  - String - Address of the temporary storage where 
//                 the data-to-document conversion scheme is stored
//  PlanProfile  - CatalogRef.PlanProfiles - Link to the type of plan that the document is filled in for.
//
// Returns:
//   Array   - A list of fields that can be used to fill in the document.
//
Function GetDataConversionSchemeFields(Val AddressOfDataConversionScheme, Val PlanProfile = Undefined) Export 

	CompositionSchema = GetFromTempStorage(AddressOfDataConversionScheme); // DataCompositionSchema - 
	
	DisableUnusedConversionSchemeFields(CompositionSchema, PlanProfile);
	
	SchemaFields = New Array;
	If CompositionSchema.SettingVariants[0].Settings.Structure.Count() > 0 Then
		GroupFields = CompositionSchema.SettingVariants[0].Settings.Structure[0].GroupFields.Items;
	Else
		GroupFields = CompositionSchema.SettingVariants[0].Settings.GroupAvailableFields.Items;
	EndIf; 
	
	For Each Group In GroupFields Do
		
		If Group.Use And SchemaFields.Find(String(Group.Field)) = Undefined Then
			SchemaFields.Add(String(Group.Field));
		EndIf; 
	
	EndDo; 
	
	For Each SelectedField In CompositionSchema.SettingVariants[0].Settings.Selection.Items Do
		
		If SelectedField.Use And SchemaFields.Find(String(SelectedField.Field)) = Undefined Then
			SchemaFields.Add(String(SelectedField.Field));
		EndIf;
	
	EndDo;
	
	Return SchemaFields;
	
EndFunction 

// This procedure disables unused fields by plan type
//
// Parameters:
//  Skompresowane - Shemalesasian Diagram in which you want to disable fields
//  PlanProfile  - CatalogRef.PlanProfiles - The type of plan that the document is filled in for.
//
Procedure DisableUnusedConversionSchemeFields(DataCompositionSchemaConversion, Val PlanProfile) 

	If Not ValueIsFilled(PlanProfile) Then
		Return;
	EndIf;
	
	FieldsToDelete__ = New Array;
	
	If Not GetFunctionalOption("UseItemVariants") Then
		FieldsToDelete__.Add(New DataCompositionField("Characteristic"));
	EndIf;
	
	AttributesValues = Common.ObjectAttributesValues(PlanProfile, "Owner, PlanType, FillInPartnerInTabularForm, FillInTermsOfSales, FillInAgreementInTabularForm, FillInWarehouseInTabularForm, FillInAssignmentInTabularForm");
	If AttributesValues.PlanType = Enums.TypesOfPlans.ProductionPlan
		And ValueIsFilled(AttributesValues.Owner) Then
		UseForMaterialsPlanning = Common.ObjectAttributeValue(AttributesValues.Owner, "UseForMaterialsPlanning");
		If Not UseForMaterialsPlanning = True Then
			FieldsToDelete__.Add(New DataCompositionField("BillOfMaterials"));
		EndIf; 
	EndIf; 
	If AttributesValues.PlanType = Enums.TypesOfPlans.SalesPlanByCategories
		And ValueIsFilled(AttributesValues.Owner) Then
		UseCalculationBySalesSpeed = Common.ObjectAttributeValue(AttributesValues.Owner, "UseCalculationBySalesSpeed");
		If Not UseCalculationBySalesSpeed = True Then
			FieldsToDelete__.Add(New DataCompositionField("SalesRank"));
		EndIf; 
	EndIf;
	If Not AttributesValues.FillInPartnerInTabularForm Then
		FieldsToDelete__.Add(New DataCompositionField("Partner"));
	EndIf; 
	
	If Not AttributesValues.FillInAgreementInTabularForm Then
		FieldsToDelete__.Add(New DataCompositionField("Terms"));
	EndIf;
	If Not AttributesValues.FillInAgreementInTabularForm And Not AttributesValues.FillInTermsOfSales Then
		FieldsToDelete__.Add(New DataCompositionField("VendorPriceKind"));
	EndIf;
	
	If Not AttributesValues.FillInAssignmentInTabularForm 
		Or Not GetFunctionalOption("UseOrderSupplyWithAssignment") Then
		FieldsToDelete__.Add(New DataCompositionField("Purpose"));
	EndIf;
	
	If Not AttributesValues.FillInWarehouseInTabularForm Then
		FieldsToDelete__.Add(New DataCompositionField("Warehouse"));
		FieldsToDelete__.Add(New DataCompositionField("Warehouse.Calendar"));
	EndIf;
	
	If FieldsToDelete__.Count() = 0 Then
		Return;
	EndIf; 
	
	If DataCompositionSchemaConversion.SettingVariants[0].Settings.Structure.Count() > 0 Then
		GroupFields = DataCompositionSchemaConversion.SettingVariants[0].Settings.Structure[0].GroupFields.Items;
	Else
		GroupFields = DataCompositionSchemaConversion.SettingVariants[0].Settings.GroupAvailableFields.Items;
	EndIf; 
	
	For Each Group In GroupFields Do
		
		If FieldsToDelete__.Find(Group.Field) <> Undefined Then
			Group.Use = False;
		EndIf; 
		
	EndDo; 
	
	For Each SelectedField In DataCompositionSchemaConversion.SettingVariants[0].Settings.Selection.Items Do
		
		If FieldsToDelete__.Find(SelectedField.Field) <> Undefined Then
			SelectedField.Use = False;
		EndIf;
		
	EndDo;
	
	SetCompositionTable = DataCompositionSchemaConversion.DataSets.Find("CompositionTable");
	If SetCompositionTable <> Undefined Then
	
		For Each Field In FieldsToDelete__ Do
		
			FoundField = SetCompositionTable.Fields.Find(String(Field));
			If FoundField <> Undefined Then
			
				SetCompositionTable.Fields.Delete(FoundField);
			
			EndIf; 
		
		EndDo; 
	
	EndIf; 
	
	IndexOf = DataCompositionSchemaConversion.DataSetLinks.Count() - 1;
	While  IndexOf >= 0 Do
		Link = DataCompositionSchemaConversion.DataSetLinks[IndexOf];
		IndexOf = IndexOf - 1;
		
		If FieldsToDelete__.Find(New DataCompositionField(Link.SourceExpression))  <> Undefined
			Or FieldsToDelete__.Find(New DataCompositionField(Link.DestinationExpression))  <> Undefined Then
			
			DataCompositionSchemaConversion.DataSetLinks.Delete(Link);
			
		EndIf; 
		
	EndDo;
	
EndProcedure
 
#EndRegion

#Region Report_BalanceOfPlans

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BalancePlansBeforeUploadingOptionToServer(ThisForm, NewDCSettings) Export

	Report = ThisForm.Report;
	SettingsComposer = Report.SettingsComposer;
	
	SettingsComposer.Settings.AdditionalProperties.Insert("CurrentVariantKey", ThisForm.CurrentVariantKey);
	
	// Changing settings by functional options
	If Not GetFunctionalOption("UsePurchasePlanning") Then
		RemoveSelectionByPresentation(SettingsComposer, SettingsComposer, "PlanType", "ProcurementPlans");
	EndIf;
	
	If Not GetFunctionalOption("UseSalesPlans") Then
		RemoveSelectionByPresentation(SettingsComposer, SettingsComposer, "PlanType", "SalesPlans");
	EndIf;
	
	If Not GetFunctionalOption("UseProduction")
		Or Not GetFunctionalOption("UseProductionPlanning")
		Then
		RemoveSelectionByPresentation(SettingsComposer, SettingsComposer, "PlanType", "ProductionPlans");
	EndIf;
	
	If Not GetFunctionalOption("UseAssemblyDisassemblyPlanning") Then
		RemoveSelectionByPresentation(SettingsComposer, SettingsComposer, "PlanType", "BuildPlans");
		RemoveSelectionByPresentation(SettingsComposer, SettingsComposer, "PlanType", "ComponentPlans");
	EndIf;
	
	If Not GetFunctionalOption("UsePlanningOfInventoryConsumption") Then
		RemoveSelectionByPresentation(SettingsComposer, SettingsComposer, "PlanType", "InventoryConsumptionPlans");
	EndIf;
	
	NewDCSettings = SettingsComposer.Settings;
	
EndProcedure

// Called in the "pre-load Userconfigurationserver" handler of
//   the report form before executing the form code.
//
// Parameters:
// 	ThisForm - ClientApplicationForm - 
// 	NewDCUserSettings - DataCompositionUserSettings - 
Procedure BalancePlansBeforeUploadingCustomSettingsToServer(ThisForm, NewDCUserSettings) Export
	
	Report = ThisForm.Report;
	SettingsComposer = Report.SettingsComposer; // DataCompositionSettingsComposer - 
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		ContextualSettings = GetCustomSettingsWithDocumentSelection(Parameters.CommandParameter);
		
		If ContextualSettings.Property("Products") Then
			
			ItemArray = CommonClientServer.FindFilterItemsAndGroups(SettingsComposer.Settings.Filter, "Products");
			If ItemArray.Count() = 0 Then
				DataCompositionClientServer.AddFilter(
					SettingsComposer,
					"Products",
					ContextualSettings.Products,
					DataCompositionComparisonType.InListByHierarchy, 
					True, 
					New Structure("ToUserSettings", True));
			Else
				
				FilterElement = ItemArray[0];
				UserSettingID = FilterElement.UserSettingID;
				ItemTheCustomSettings = SettingsComposer.UserSettings.Items.Find(UserSettingID);
				If ItemTheCustomSettings = Undefined Then
					DataCompositionClientServer.AddFilter(
						SettingsComposer,
						"Products",
						ContextualSettings.Products,
						DataCompositionComparisonType.InListByHierarchy, 
						True, 
						New Structure("ToUserSettings", True));
				Else
					ItemTheCustomSettings.ComparisonType = DataCompositionComparisonType.InListByHierarchy;
					ItemTheCustomSettings.RightValue = New ValueList;
					ItemTheCustomSettings.RightValue.LoadValues(ContextualSettings.Products);
					ItemTheCustomSettings.Use = True;
				EndIf;
				
			EndIf; 
		
		EndIf; 
		
		If ContextualSettings.Property("Period") Then
			DataCompositionClientServer.SetParameter(SettingsComposer.UserSettings,"Period",ContextualSettings.Period);
		EndIf; 
		If ContextualSettings.Property("Scenario") Then
			DataCompositionClientServer.SetParameter(SettingsComposer.UserSettings,"Scenario",ContextualSettings.Scenario);
		EndIf;
		If ContextualSettings.Property("ComparisonScenarios") Then
			DataCompositionClientServer.SetParameter(SettingsComposer.UserSettings,
				"ComparisonScenarios",ContextualSettings.ComparisonScenarios);
		EndIf;
		
	EndIf; 
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
	
		GroupByWarehousesParameter = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings, "GroupByWarehouses");
		If GroupByWarehousesParameter <> Undefined Then
			GroupByWarehousesParameter.Value = False;
		EndIf;
	EndIf;
	
	// Changing settings by functional options
	If Not GetFunctionalOption("UsePurchasePlanning") Then
		RemoveSelectionByPresentation(SettingsComposer, SettingsComposer, "PlanType", "ProcurementPlans");
	EndIf;
	
	If Not GetFunctionalOption("UseSalesPlans") Then
		RemoveSelectionByPresentation(SettingsComposer, SettingsComposer, "PlanType", "SalesPlans");
	EndIf;
	
	If Not GetFunctionalOption("UseProduction")
		Or Not GetFunctionalOption("UseProductionPlanning")
		Then
		RemoveSelectionByPresentation(SettingsComposer, SettingsComposer, "PlanType", "ProductionPlans");
	EndIf;
	
	If Not GetFunctionalOption("UseAssemblyDisassemblyPlanning") Then
		RemoveSelectionByPresentation(SettingsComposer, SettingsComposer, "PlanType", "BuildPlans");
		RemoveSelectionByPresentation(SettingsComposer, SettingsComposer, "PlanType", "ComponentPlans");
	EndIf;
	
	If Not GetFunctionalOption("UsePlanningOfInventoryConsumption") Then
		RemoveSelectionByPresentation(SettingsComposer, SettingsComposer, "PlanType", "InventoryConsumptionPlans");
	EndIf;
	
	NewDCUserSettings = SettingsComposer.UserSettings;
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	SettingsComposer - DataCompositionSettingsComposer - 
// 	Cancel - Boolean -
Procedure BalancingPlansHandlingFillChecks(SettingsComposer, Cancel) Export 

	PlansOfGoodsStock   = GetSelection(SettingsComposer, "PlanType", 7);
	Status          = GetSelection(SettingsComposer, "Status");
	ScenarioStatuses = New Array;
	
	ResiduePlansUse = (PlansOfGoodsStock <> Undefined And PlansOfGoodsStock.Use);
	
	For Each SettingItem In SettingsComposer.UserSettings.Items Do
		If PlansOfGoodsStock <> Undefined And SettingItem.UserSettingID = PlansOfGoodsStock.UserSettingID Then
			ResiduePlansUse = SettingItem.Use;
		EndIf;
		If Status <> Undefined And SettingItem.UserSettingID = Status.UserSettingID Then
			If SettingItem.Use Then
				For Each Item In SettingItem.RightValue Do
					ScenarioStatuses.Add(Item.Value);
				EndDo;
			Else
				ScenarioStatuses.Add(Enums.PlanStatuses.Upholded);
				ScenarioStatuses.Add(Enums.PlanStatuses.AwaitingConfirmation);
				ScenarioStatuses.Add(Enums.PlanStatuses.UnderPreparation);
			EndIf;
		EndIf;
	EndDo; 
	
	Scenario = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings, "Scenario");

	ComparisonScenarios = DataCompositionClientServer.GetParameter(
		SettingsComposer.UserSettings, "ComparisonScenarios");
	
	If ComparisonScenarios <> Undefined Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "ScenarioComparison", True);
		MeaningOfComparisonScenarios = ComparisonScenarios.Value;
	Else
		DataCompositionClientServer.SetParameter(SettingsComposer, "ScenarioComparison", False);
	EndIf;

	If Scenario <> Undefined And ValueIsFilled(Scenario.Value) Then
		ScriptParameters_ = ScriptParameters_(Scenario.Value);
		For Each KeyAndValue In ScriptParameters_ Do
			DataCompositionClientServer.SetParameter(SettingsComposer, KeyAndValue.Key,KeyAndValue.Value);
		EndDo;
		
		UseRemainderPlans = GetFunctionalOption("UsePlanningOfGoodsStock");
		
		UseCalculationOfBalancePlans = UseRemainderPlans
			And ScriptParameters_.UseInBalancePlanning
			And ResiduePlansUse
			And (SettingsComposer.Settings.AdditionalProperties.DescriptionOption = NStr("vi = 'Cân đối kế hoạch cho kỳ';
																						|ru = 'Сбалансированность планов за период';
																						|en = 'Plan balance for the period'; fa = 'مانده برنامه برای دوره';
																						|it = 'Pareggio dei piani per il periodo';
																						|pl = 'Równowaga planów za okres';
																						|tr = 'Dönem planları dengesi'")
			Or SettingsComposer.Settings.AdditionalProperties.DescriptionOption = NStr("vi = 'So sánh kịch bản cho kỳ';
																						|ru = 'Сравнение сценариев за период';
																						|en = 'Comparison of scenarios for the period'; fa = 'مقایسه سناریوها برای دوره';
																						|it = 'Comparazione degli scenari per il periodo';
																						|pl = 'Porównanie scenariuszy za okres';
																						|tr = 'Dönemler göre senaryoların karşılaştırılması'"));
		
		Period = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings, "Period");
		PeriodValue_ = Period.Value; // StandardPeriod -
		
		If UseCalculationOfBalancePlans Then
			ParametersForCalculatingBeginningOfBalanceAccumulation = New Structure();
			ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("Scenario", Scenario.Value);
			ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("Periodicity", ScriptParameters_.Periodicity);
			ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("ScenarioStatuses", ScenarioStatuses);
			ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("Ref", Undefined); 
			ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("BeginOfPeriod", PeriodValue_.StartDate);
			ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("EndOfPeriod", PeriodValue_.EndDate);
			
			Result = GetPeriodsOfBalancePlans(ParametersForCalculatingBeginningOfBalanceAccumulation);
			BalancePlanPeriodsForPeriodGreaterThanBeginningOfPeriod = Result.BalancePlanPeriodsForPeriodGreaterThanBeginningOfPeriod;
			
		EndIf;
		
		UseCalculationOfScenarioResidualPlans = False;
		If SettingsComposer.Settings.AdditionalProperties.DescriptionOption = NStr("vi = 'So sánh kịch bản cho kỳ';
																					|ru = 'Сравнение сценариев за период';
																					|en = 'Comparison of scenarios for the period'; fa = 'مقایسه سناریوها برای دوره';
																					|it = 'Comparazione degli scenari per il periodo';
																					|pl = 'Porównanie scenariuszy za okres';
																					|tr = 'Dönemler göre senaryoların karşılaştırılması'")
		   And UseRemainderPlans And ComparisonScenarios <> Undefined And ValueIsFilled(MeaningOfComparisonScenarios) Then
			
			ArrayOfPlanPeriodsScenarioBalancesForPeriodGreaterThanBeginningOfPeriod = New Array;
			ArrayOfScenarios                                                  = New Array;
			
			If TypeOf(MeaningOfComparisonScenarios) <> Type("ValueList") Then
				ArrayOfScenarios.Add(MeaningOfComparisonScenarios);
			Else
				For Each AdditionalScenario_ In MeaningOfComparisonScenarios Do
					ArrayOfScenarios.Add(AdditionalScenario_.Value);
				EndDo;
			EndIf;
			
			For Each AdditionalScenario In ArrayOfScenarios Do
				
				ScriptOptions = ScriptParameters_(AdditionalScenario);
				If ScriptOptions.UseInBalancePlanning And ResiduePlansUse Then
					
					UseCalculationOfScenarioResidualPlans = True;
					
					ParametersForCalculatingBeginningOfAccumulationOfResiduesOfComparisonScenarios = New Structure();
					ParametersForCalculatingBeginningOfAccumulationOfResiduesOfComparisonScenarios.Insert("Scenario", AdditionalScenario);
					ParametersForCalculatingBeginningOfAccumulationOfResiduesOfComparisonScenarios.Insert("Periodicity", ScriptParameters_.Periodicity);
					ParametersForCalculatingBeginningOfAccumulationOfResiduesOfComparisonScenarios.Insert("ScenarioStatuses", ScenarioStatuses);
					ParametersForCalculatingBeginningOfAccumulationOfResiduesOfComparisonScenarios.Insert("Ref", Undefined);
					ParametersForCalculatingBeginningOfAccumulationOfResiduesOfComparisonScenarios.Insert("BeginOfPeriod", PeriodValue_.StartDate);
					ParametersForCalculatingBeginningOfAccumulationOfResiduesOfComparisonScenarios.Insert("EndOfPeriod", PeriodValue_.EndDate);
					
					ResultOfScripts = GetPeriodsOfBalancePlans(ParametersForCalculatingBeginningOfAccumulationOfResiduesOfComparisonScenarios);
					
					For Each BalancePlanPeriod In ResultOfScripts.BalancePlanPeriodsForPeriodGreaterThanBeginningOfPeriod Do
						ArrayOfPlanPeriodsScenarioBalancesForPeriodGreaterThanBeginningOfPeriod.Add(BalancePlanPeriod);
					EndDo;
					
				EndIf;
				
			EndDo;
			
			If UseCalculationOfScenarioResidualPlans Then
				
				If UseCalculationOfBalancePlans Then
					
					CombiningArraysOfPeriodsAndBalances = CombineArrays(
						BalancePlanPeriodsForPeriodGreaterThanBeginningOfPeriod,
						ArrayOfPlanPeriodsScenarioBalancesForPeriodGreaterThanBeginningOfPeriod);
					
					BalancePlanPeriodsForPeriodGreaterThanBeginningOfPeriod = CombiningArraysOfPeriodsAndBalances;
				Else
					BalancePlanPeriodsForPeriodGreaterThanBeginningOfPeriod = ArrayOfPlanPeriodsScenarioBalancesForPeriodGreaterThanBeginningOfPeriod;
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If BalancePlanPeriodsForPeriodGreaterThanBeginningOfPeriod <> Undefined Then
			If BalancePlanPeriodsForPeriodGreaterThanBeginningOfPeriod.Count() > 0 Then
				LinePeriodsOfBalancePlan = "";
				For Each BalancePlanPeriod In BalancePlanPeriodsForPeriodGreaterThanBeginningOfPeriod Do
					If LinePeriodsOfBalancePlan <> "" Then
						LinePeriodsOfBalancePlan = LinePeriodsOfBalancePlan + ";";
					EndIf;
					LinePeriodsOfBalancePlan = LinePeriodsOfBalancePlan + " " + Format(BalancePlanPeriod, "DLF=D");
				EndDo;
				
				MessageText = NStr("vi = 'Trong kỳ báo cáo, đã tìm thấy kế hoạch số dư trong các kỳ tiếp theo: ""%LinePeriodsOfBalancePlan%"". Số dư có thể được hiển thị nếu kế hoạch số dư không phá vỡ kỳ báo cáo.. ';
									|ru = 'В пределах периода отчета найдены планы остатков в следующих периодах: ""%LinePeriodsOfBalancePlan%"". Сбалансированность можно отобразить, если планы остатков не разрывают период отчета.';
									|en = 'Goods stock plans are found within the report period limits in the following periods: ""%LinePeriodsOfBalancePlan%"". Balance can be displayed if the plans of goods stock do not break the report plan.'; fa = 'Goods stock plans are found within the report period limits in the following periods: ""%LinePeriodsOfBalancePlan%"". Balance can be displayed if the plans of goods stock do not break the report plan.';
									|it = 'Durante il periodo contabile, i piani di saldi sono stati trovati nei seguenti periodi: ""%LinePeriodsOfBalancePlan%"". Equilibrio può essere visualizzato se i piani di saldi non interrompono il periodo di rendicontazione.';
									|pl = 'W granicach okresu raportu są znalezione plany pozostałości w następujących okresach: ""%LinePeriodsOfBalancePlan%"". Zrównoważenie można odzwierciedlić, jeśli plany pozostałości nie przerywają okres raportu.';
									|tr = 'Rapor dönemi içerisinde sonraki dönemlerin mal stok planları için planlar mevcut: ""%LinePeriodsOfBalancePlan%"". Bakiye, mal stok planları rapor dönemini aşmıyorsa görüntülenebilir.'");
				MessageText = StrReplace(MessageText, "%LinePeriodsOfBalancePlan%", LinePeriodsOfBalancePlan);
				CommonClientServer.MessageToUser(MessageText, , , , Cancel);
			EndIf;
		EndIf;
		
	Else
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường bắt buộc ""Kịch bản"".';
												|ru = 'Не заполнено обязательное поле ""Сценарий"".';
												|en = '""Scenario"" is required.'; fa = '""Scenario"" is required.';
												|it = 'Il campo obbligatorio ""Scenario"" non è stato compilato.';
												|pl = 'Pole obowiązkowe ""Scenariusz"" nie jest wypełnione.';
												|tr = '""Senaryo"" gerekli alanı doldurulmamış.'"), , , , Cancel);
	EndIf;
	
EndProcedure

// Called in the "append Result" handler when generating a report
// 
// Parameters:
// 	DataCompositionSchema - DataCompositionSchema - 
// 	SettingsComposer - DataCompositionSettingsComposer - 
// 	ResultDocument - SpreadsheetDocument - 
// 	DetailsData - DataCompositionDetailsData - 
// 	StandardProcessing - Boolean
Procedure BalanceOfPlansInLayoutOfResult(DataCompositionSchema, SettingsComposer, ResultDocument, DetailsData, StandardProcessing) Export
	
	PurchasePlans               = GetSelection(SettingsComposer, "PlanType", 1);
	PlansOfGoodsStock              = GetSelection(SettingsComposer, "PlanType", 7);
	SalesPlans                = GetSelection(SettingsComposer, "PlanType", 2);
	ProductionPlans          = GetSelection(SettingsComposer, "PlanType", 3);
	AssemblyPlansKits       = GetSelection(SettingsComposer, "PlanType", 4);
	DisassemblyPlansKits     = GetSelection(SettingsComposer, "PlanType", 5);
	BuildPlansComponents   = GetSelection(SettingsComposer, "PlanType", 8);
	DisassemblyPlansComponents = GetSelection(SettingsComposer, "PlanType", 9);
	MaterialPlans            = GetSelection(SettingsComposer, "PlanType", 6);
	InventoryConsumptionPlans = GetSelection(SettingsComposer, "PlanType", 11);
	DemandAdjustments  = GetSelection(SettingsComposer, "PlanType", 10);
	Status                     = GetSelection(SettingsComposer, "Status", "");
	ScenarioStatuses            = New Array;

	UsingPlans = New Structure();
	UsingPlans.Insert("PurchasePlans");
	UsingPlans.Insert("PlansOfGoodsStock");
	UsingPlans.Insert("SalesPlans");
	UsingPlans.Insert("ProductionPlans");
	UsingPlans.Insert("AssemblyPlansKits");
	UsingPlans.Insert("DisassemblyPlansKits");
	UsingPlans.Insert("BuildPlansComponents");
	UsingPlans.Insert("DisassemblyPlansComponents");
	UsingPlans.Insert("MaterialPlans");
	UsingPlans.Insert("InventoryConsumptionPlans");
	UsingPlans.Insert("DemandAdjustments");

	SelectedFields                                  = Undefined;
	UsingPlans.PurchasePlans               = False Or (PurchasePlans <> Undefined
															   And PurchasePlans.Use);
	UsingPlans.PlansOfGoodsStock              = False Or (PlansOfGoodsStock <> Undefined
															   And PlansOfGoodsStock.Use);
	UsingPlans.SalesPlans                = False Or (SalesPlans <> Undefined
															   And SalesPlans.Use);
	UsingPlans.ProductionPlans          = False Or (ProductionPlans <> Undefined
															   And ProductionPlans.Use);
	UsingPlans.AssemblyPlansKits       = False Or (AssemblyPlansKits <> Undefined
															   And AssemblyPlansKits.Use);
	UsingPlans.DisassemblyPlansKits     = False Or (DisassemblyPlansKits <> Undefined
															   And DisassemblyPlansKits.Use);
	UsingPlans.BuildPlansComponents   = False Or (BuildPlansComponents <> Undefined
															   And BuildPlansComponents.Use);
	UsingPlans.DisassemblyPlansComponents = False Or (DisassemblyPlansComponents <> Undefined
															   And DisassemblyPlansComponents.Use);
	UsingPlans.MaterialPlans            = False Or (MaterialPlans <> Undefined
															   And MaterialPlans.Use);
	UsingPlans.InventoryConsumptionPlans = False Or (InventoryConsumptionPlans <> Undefined
															   And InventoryConsumptionPlans.Use);
	UsingPlans.DemandAdjustments  = False Or (DemandAdjustments <> Undefined 
															   And DemandAdjustments.Use);

	IDOfSettingsForSelectedFields = SettingsComposer.Settings.Selection.UserSettingID;
	For Each SettingItem In SettingsComposer.UserSettings.Items Do
		If SettingItem.UserSettingID = IDOfSettingsForSelectedFields Then
			SelectedFields = SettingItem;
		EndIf;
		If PurchasePlans <> Undefined
		   And SettingItem.UserSettingID = PurchasePlans.UserSettingID Then
			UsingPlans.PurchasePlans = SettingItem.Use;
		EndIf;
		If PlansOfGoodsStock <> Undefined
		   And SettingItem.UserSettingID = PlansOfGoodsStock.UserSettingID Then
			UsingPlans.PlansOfGoodsStock = SettingItem.Use;
		EndIf;
		If SalesPlans <> Undefined
		   And SettingItem.UserSettingID = SalesPlans.UserSettingID Then
			UsingPlans.SalesPlans = SettingItem.Use;
		EndIf;
		If ProductionPlans <> Undefined
		   And SettingItem.UserSettingID = ProductionPlans.UserSettingID Then
			UsingPlans.ProductionPlans = SettingItem.Use;
		EndIf;
		If AssemblyPlansKits <> Undefined
		   And SettingItem.UserSettingID = AssemblyPlansKits.UserSettingID Then
			UsingPlans.AssemblyPlansKits = SettingItem.Use;
		EndIf;
		If DisassemblyPlansKits <> Undefined
		   And SettingItem.UserSettingID = DisassemblyPlansKits.UserSettingID Then
			UsingPlans.DisassemblyPlansKits = SettingItem.Use;
		EndIf;
		If BuildPlansComponents <> Undefined
		   And SettingItem.UserSettingID = BuildPlansComponents.UserSettingID Then
			UsingPlans.BuildPlansComponents = SettingItem.Use;
		EndIf;
		If DisassemblyPlansComponents <> Undefined
		   And SettingItem.UserSettingID = DisassemblyPlansComponents.UserSettingID Then
			UsingPlans.DisassemblyPlansComponents = SettingItem.Use;
		EndIf;
		If MaterialPlans <> Undefined
		   And SettingItem.UserSettingID = MaterialPlans.UserSettingID Then
			UsingPlans.MaterialPlans = SettingItem.Use;
		EndIf;
		If InventoryConsumptionPlans <> Undefined
		   And SettingItem.UserSettingID = InventoryConsumptionPlans.UserSettingID Then
			UsingPlans.InventoryConsumptionPlans = SettingItem.Use;
		EndIf;
		If DemandAdjustments <> Undefined
		   And SettingItem.UserSettingID = DemandAdjustments.UserSettingID Then
			UsingPlans.DemandAdjustments = SettingItem.Use;
		EndIf;
		If Status <> Undefined
		   And SettingItem.UserSettingID = Status.UserSettingID Then
			If SettingItem.Use Then
				For Each Item In SettingItem.RightValue Do
					ScenarioStatuses.Add(Item.Value);
				EndDo;
			Else
				ScenarioStatuses.Add(Enums.PlanStatuses.Upholded);
				ScenarioStatuses.Add(Enums.PlanStatuses.AwaitingConfirmation);
				ScenarioStatuses.Add(Enums.PlanStatuses.UnderPreparation);
			EndIf;
		EndIf;
	EndDo; 
	If SelectedFields = Undefined Then
		SelectedFields = SettingsComposer.Settings.Selection;
	EndIf;

	NumberOfSelectionsByPlan = New Structure();
	NumberOfSelectionsByPlan.Insert("DemandPlans", 0);
	NumberOfSelectionsByPlan.Insert("FulfillmentPlans", 0);
	
	For Each KeyAndValue In UsingPlans Do
		
		// The selection of the remaining plan is excluded, since the resource is displayed outside the group of selected plan fields
		If KeyAndValue.Value And KeyAndValue.Key <> "PlansOfGoodsStock" Then
			
			If KeyAndValue.Key = "ProductionPlans"
			 Or KeyAndValue.Key = "AssemblyPlansKits"
			 Or KeyAndValue.Key = "DisassemblyPlansComponents"
			 Or KeyAndValue.Key = "PurchasePlans" Then
				
				NumberOfSelectionsByPlan.FulfillmentPlans = NumberOfSelectionsByPlan.FulfillmentPlans + 1;
			Else
				NumberOfSelectionsByPlan.DemandPlans = NumberOfSelectionsByPlan.DemandPlans + 1;
			EndIf;
			
		EndIf;
		
	EndDo;

	OptionByPeriod = DataCompositionClientServer.GetParameter(SettingsComposer, "ByPeriods");
	If OptionByPeriod <> Undefined And Not OptionByPeriod.Value Then
		
		OnlyExcessOfDeviation = DataCompositionClientServer.GetParameter(SettingsComposer, "OnlyExcessOfDeviation");
		OnlyLessThanDeviation     = DataCompositionClientServer.GetParameter(SettingsComposer, "OnlyLessThanDeviation");
		
		If SettingsComposer.Settings.Structure.Count() > 0 Then
			
			For Each StructureItem In SettingsComposer.Settings.Structure Do
				
				If StructureItem.Name = "UpperGrouping" And TypeOf(StructureItem) = Type("DataCompositionGroup") Then
					If StructureItem.Structure.Count() > 0 Then
						
						SelectedFieldsInUpperDimension = StructureItem.Selection;
						SelectionBasedOnResults = StructureItem.Structure[0].Filter;
						OverallResultsOfSelection = StructureItem.Structure[0].OutputParameters.Items.Find("VerticalOverallPlacement");
						
						ItemArray = CommonClientServer.FindFilterItemsAndGroups(SelectionBasedOnResults, ,"OnlyExcessOfDeviation");
						If ItemArray.Count() > 0 And OnlyExcessOfDeviation <> Undefined Then
							ItemArray[0].Use = OnlyExcessOfDeviation.Use;
						EndIf;
						
						ItemArray = CommonClientServer.FindFilterItemsAndGroups(SelectionBasedOnResults, ,"OnlyLessThanDeviation");
						If ItemArray.Count() > 0 And OnlyLessThanDeviation <> Undefined Then
							ItemArray[0].Use = OnlyLessThanDeviation.Use;
						EndIf;
						
						If OnlyExcessOfDeviation <> Undefined And OnlyExcessOfDeviation.Use
						 Or OnlyLessThanDeviation <> Undefined And OnlyLessThanDeviation.Use Then
							
							If OverallResultsOfSelection <> Undefined Then
								OverallResultsOfSelection.Use = True;
								OverallResultsOfSelection.Value = DataCompositionTotalPlacement.Begin;
							EndIf;
							
							For Each SelectedField In SelectedFieldsInUpperDimension.Items Do
								If TypeOf(SelectedField) = Type("DataCompositionAutoSelectedField") Then
									SelectedField.Use = False;
								EndIf;
							EndDo;
							
						Else
							
							If OverallResultsOfSelection <> Undefined Then
								OverallResultsOfSelection.Use = False;
							EndIf;
							
							For Each SelectedField In SelectedFieldsInUpperDimension.Items Do
								If TypeOf(SelectedField) = Type("DataCompositionAutoSelectedField") Then
									SelectedField.Use = True;
								EndIf;
							EndDo;
							
						EndIf;
						
					EndIf;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;

	Scenario = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings, "Scenario");

	ComparisonScenarios = DataCompositionClientServer.GetParameter(
		SettingsComposer.UserSettings, "ComparisonScenarios");
	
	If ComparisonScenarios <> Undefined Then
		
		ScenarioComparison = True;
		DataCompositionClientServer.SetParameter(SettingsComposer, "ScenarioComparison", ScenarioComparison);
		MeaningOfComparisonScenarios = ComparisonScenarios.Value;
		
	Else
		
		ScenarioComparison = False;
		DataCompositionClientServer.SetParameter(SettingsComposer, "ScenarioComparison", ScenarioComparison);
		
	EndIf;

	If Scenario <> Undefined And ValueIsFilled(Scenario.Value) Then
		ScriptParameters_ = ScriptParameters_(Scenario.Value);
		For Each KeyAndValue In ScriptParameters_ Do
			DataCompositionClientServer.SetParameter(SettingsComposer, KeyAndValue.Key,KeyAndValue.Value);
		EndDo;
		
		UseRemainderPlans = GetFunctionalOption("UsePlanningOfGoodsStock");
		
		UseCalculationOfBalancePlans = UseRemainderPlans
								And ScriptParameters_.UseInBalancePlanning
								And UsingPlans.PlansOfGoodsStock;
		
		Period = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings, "Period"); // DataCompositionSchemaParameter - 
		PeriodValue_ = Period.Value; // StandardPeriod - 
		If UseCalculationOfBalancePlans Then
			ParametersForCalculatingBeginningOfBalanceAccumulation = New Structure();
			ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("Scenario", Scenario.Value);
			ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("Periodicity", ScriptParameters_.Periodicity);
			ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("ScenarioStatuses", ScenarioStatuses);
			ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("Ref", Undefined);
			ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("BeginOfPeriod", PeriodValue_.StartDate);
			ParametersForCalculatingBeginningOfBalanceAccumulation.Insert("EndOfPeriod", PeriodValue_.EndDate);
			
			Result = GetPeriodsOfBalancePlans(ParametersForCalculatingBeginningOfBalanceAccumulation);
			
			DataCompositionClientServer.SetParameter(SettingsComposer, "BalanceAccumulationStartDate",
															Result.BalanceAccumulationStartDate);
		Else
			DataCompositionClientServer.SetParameter(SettingsComposer, "BalanceAccumulationStartDate",
															PeriodValue_.StartDate);
		EndIf;
		
		UseCalculationOfScenarioResidualPlans = False;
		If UseRemainderPlans And ComparisonScenarios <> Undefined And ValueIsFilled(MeaningOfComparisonScenarios) Then
			
			ArrayOfDatesForInitialAccumulationsOfScriptBalances = New Array;
			ArrayOfScenarios                               = New Array;
			
			If TypeOf(MeaningOfComparisonScenarios) <> Type("ValueList") Then
				ArrayOfScenarios.Add(MeaningOfComparisonScenarios);
			Else
				For Each AdditionalScenario_ In MeaningOfComparisonScenarios Do
					ArrayOfScenarios.Add(AdditionalScenario_.Value);
				EndDo;
			EndIf;
			
			For Each AdditionalScenario In ArrayOfScenarios Do
				
				ScriptOptions = ScriptParameters_(AdditionalScenario);
				If ScriptOptions.UseInBalancePlanning And UsingPlans.PlansOfGoodsStock Then
					
					UseCalculationOfScenarioResidualPlans = True;
					
					ParametersForCalculatingBeginningOfAccumulationOfResiduesOfComparisonScenarios = New Structure();
					ParametersForCalculatingBeginningOfAccumulationOfResiduesOfComparisonScenarios.Insert("Scenario", AdditionalScenario);
					ParametersForCalculatingBeginningOfAccumulationOfResiduesOfComparisonScenarios.Insert("Periodicity", ScriptParameters_.Periodicity);
					ParametersForCalculatingBeginningOfAccumulationOfResiduesOfComparisonScenarios.Insert("ScenarioStatuses", ScenarioStatuses);
					ParametersForCalculatingBeginningOfAccumulationOfResiduesOfComparisonScenarios.Insert("Ref", Undefined);
					ParametersForCalculatingBeginningOfAccumulationOfResiduesOfComparisonScenarios.Insert("BeginOfPeriod", PeriodValue_.StartDate);
					ParametersForCalculatingBeginningOfAccumulationOfResiduesOfComparisonScenarios.Insert("EndOfPeriod", PeriodValue_.EndDate);
					
					ResultOfScripts = GetPeriodsOfBalancePlans(ParametersForCalculatingBeginningOfAccumulationOfResiduesOfComparisonScenarios);
					
					ArrayOfDatesForInitialAccumulationsOfScriptBalances.Add(ResultOfScripts.BalanceAccumulationStartDate);
					
				EndIf;
			EndDo;
			
			If UseCalculationOfScenarioResidualPlans Then
				
				MinimumStartDateForBalanceAccumulation = PeriodValue_.StartDate;
				
				For Each DateOfInitialBalances In ArrayOfDatesForInitialAccumulationsOfScriptBalances Do
					If DateOfInitialBalances < MinimumStartDateForBalanceAccumulation Then
						MinimumStartDateForBalanceAccumulation = DateOfInitialBalances;
					EndIf;
				EndDo;
				
				DataCompositionClientServer.SetParameter(SettingsComposer, 
					"StartDateOfBalanceAccumulation", MinimumStartDateForBalanceAccumulation);
				
			Else
				
				DataCompositionClientServer.SetParameter(SettingsComposer,
					"StartDateOfBalanceAccumulation", PeriodValue_.StartDate);
				
			EndIf;
		EndIf;
		
		ConfigurePeriodExtension(SettingsComposer.Settings, ScriptParameters_.Periodicity,
			PeriodValue_.StartDate, PeriodValue_.EndDate);

		If TypeOf(DataCompositionSchema.DataSets[0]) = Type("DataCompositionSchemaDataSetQuery") Then
			
			DataCompositionSchema.DataSets[0].Query = StrReplace(DataCompositionSchema.DataSets[0].Query,
				"MONTH", Common.EnumerationValueName(ScriptParameters_.Periodicity));
			
		ElsIf TypeOf(DataCompositionSchema.DataSets[0]) = Type("DataCompositionSchemaDataSetUnion") Then
			
			DataSetAssociation = DataCompositionSchema.DataSets[0];
			
			For Each DataSet In DataSetAssociation.Items Do // DataCompositionSchemaDataSetQuery -
				
				DataSet.Query = StrReplace(DataSet.Query, "MONTH", Common.EnumerationValueName(ScriptParameters_.Periodicity));
				
			EndDo;
			
		EndIf;
		
	Else
		UseCalculationOfBalancePlans = False;
	EndIf;
	
	UsingPlans.PlansOfGoodsStock = UseCalculationOfBalancePlans;
	
	ConfiguringDetailByPlans = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings, "DetailByPlans");
		
	If ConfiguringDetailByPlans <> Undefined Then
		DetailByPlans = ConfiguringDetailByPlans.Value;
	Else
		DetailByPlans = False;
	EndIf;

	SetSelectedFieldsBySelections(SelectedFields, 
		UsingPlans,
		NumberOfSelectionsByPlan, 
		DetailByPlans,
		ScenarioComparison);

	For Each SelectionElement In SelectedFields.Items Do
		If TypeOf(SelectionElement) = Type("DataCompositionSelectedFieldGroup") Then
			SelectionElement.Use = True;
		EndIf;
	EndDo;
	
	If ComparisonScenarios <> Undefined
	And ValueIsFilled(MeaningOfComparisonScenarios) Then
		
		SettingToDisplayOnlyScriptRejections = DataCompositionClientServer.GetParameter(
			SettingsComposer.UserSettings, "DisplayOnlyScriptDeviations");
		
		UsingPlans.PlansOfGoodsStock = UseCalculationOfScenarioResidualPlans;
		
		If SettingToDisplayOnlyScriptRejections <> Undefined Then
			DisplayOnlyScriptDeviations = SettingToDisplayOnlyScriptRejections.Value;
		Else
			DisplayOnlyScriptDeviations = False;
		EndIf;
		
		For Each StructureItem In SettingsComposer.Settings.Structure Do
			Groups = DataCompositionClientServer.GetGroupings(StructureItem);
			For Each Group In Groups Do
				If Group.Value.Name = "AdditionalScenarios"
				 Or Group.Value.Name = "ScenarioDeviations" Then
					
					SelectedDimensionFields = Group.Value.Selection;
					
					SetSelectedFieldsForScenarioComparisonDimensions(Group.Value,
						SelectedDimensionFields,
						UsingPlans,
						NumberOfSelectionsByPlan,
						DetailByPlans,
						DisplayOnlyScriptDeviations,
						MeaningOfComparisonScenarios)
					
				EndIf;
			EndDo;
		EndDo;
	EndIf;

	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
EndProcedure

#Region Private

Procedure ConfigurePeriodExtension(ReportSettings, Periodicity, InitialPeriod, EndPeriod_1)
	
	StringPeriodicity = Common.EnumerationValueName(Periodicity);
	AdditionType = DataCompositionPeriodAdditionType[StringPeriodicity];
	
	InitialPeriod = PlanningClientServer.CalculateStartDateOfPeriod(
		InitialPeriod, Periodicity);
	EndPeriod_1 = PlanningClientServer.CalculatePeriodEndDate(
		EndPeriod_1, Periodicity);
	
	PeriodField = New DataCompositionField("Period");
	
	For Each StructureItem In ReportSettings.Structure Do
		Groups = DataCompositionClientServer.GetGroupings(StructureItem); // DataCompositionGroup -
		For Each Group In Groups Do
			GroupFields = Group.Value.GroupFields; // DataCompositionGroupFields - 
			GroupItems = GroupFields.Items;
			If GroupItems.Count() = 1 And GroupItems[0].Field = PeriodField Then
				GroupingPeriod = GroupItems[0];
				GroupingPeriod.AdditionType = AdditionType;
				GroupingPeriod.BeginOfPeriod = InitialPeriod;
				GroupingPeriod.EndOfPeriod  = EndPeriod_1;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Function GetCustomSettingsWithDocumentSelection(FilterByDocuments)
	
	ContextualSettings = New Structure;
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	MIN(NestedQuery.BeginOfPeriod) AS BeginOfPeriod,
	|	MAX(NestedQuery.PeriodEnding) AS PeriodEnding,
	|	MAX(NestedQuery.Scenario) AS Scenario
	|FROM
	|	(SELECT
	|		DocumentPlan_.BeginOfPeriod AS BeginOfPeriod,
	|		DocumentPlan_.PeriodEnding AS PeriodEnding,
	|		DocumentPlan_.Scenario AS Scenario
	|	FROM
	|		Document.PurchasePlan AS DocumentPlan_
	|	WHERE
	|		DocumentPlan_.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentPlan_.BeginOfPeriod,
	|		DocumentPlan_.PeriodEnding,
	|		DocumentPlan_.Scenario
	|	FROM
	|		Document.PlanOfGoodsStock AS DocumentPlan_
	|	WHERE
	|		DocumentPlan_.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentPlan_.BeginOfPeriod,
	|		DocumentPlan_.PeriodEnding,
	|		DocumentPlan_.Scenario
	|	FROM
	|		Document.SalesPlan AS DocumentPlan_
	|	WHERE
	|		DocumentPlan_.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentPlan_.BeginOfPeriod,
	|		DocumentPlan_.PeriodEnding,
	|		DocumentPlan_.Scenario
	|	FROM
	|		Document.InventoryConsumptionPlan AS DocumentPlan_
	|	WHERE
	|		DocumentPlan_.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentPlan_.BeginOfPeriod,
	|		DocumentPlan_.PeriodEnding,
	|		DocumentPlan_.Scenario
	|	FROM
	|		Document.ProductionPlan AS DocumentPlan_
	|	WHERE
	|		DocumentPlan_.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		RegisteredRecordsAndGoods.Period,
	|		RegisteredRecordsAndGoods.Period,
	|		RegisteredRecordsAndGoods.Scenario
	|	FROM
	|		AccumulationRegister.ReleasePlansProducts_.Turnovers(,,Record,ProductionPlan IN (&ReferencesArrray)) AS RegisteredRecordsAndGoods
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		RegisteredRecordsAndGoods.Period,
	|		RegisteredRecordsAndGoods.Period,
	|		RegisteredRecordsAndGoods.Scenario
	|	FROM
	|		AccumulationRegister.MaterialConsumptionPlans.Turnovers(,,Record,ProductionPlan IN (&ReferencesArrray)) AS RegisteredRecordsAndGoods
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentPlan_.BeginOfPeriod,
	|		DocumentPlan_.PeriodEnding,
	|		DocumentPlan_.Scenario
	|	FROM
	|		Document.AssemblyDisassemblyPlan AS DocumentPlan_
	|	WHERE
	|		DocumentPlan_.Ref IN(&ReferencesArrray)) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	NestedQuery.Products
	|FROM
	|	(SELECT DISTINCT
	|		ProductPlanDocument.Products AS Products
	|	FROM
	|		Document.PurchasePlan.Goods AS ProductPlanDocument
	|	WHERE
	|		ProductPlanDocument.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		ProductPlanDocument.Products
	|	FROM
	|		Document.PlanOfGoodsStock.Goods AS ProductPlanDocument
	|	WHERE
	|		ProductPlanDocument.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		ProductPlanDocument.Products
	|	FROM
	|		Document.SalesPlan.Goods AS ProductPlanDocument
	|	WHERE
	|		ProductPlanDocument.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		ProductPlanDocument.Products
	|	FROM
	|		Document.InventoryConsumptionPlan.Goods AS ProductPlanDocument
	|	WHERE
	|		ProductPlanDocument.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		ProductPlanDocument.Products
	|	FROM
	|		Document.ProductionPlan.ManufacturedProduct AS ProductPlanDocument
	|	WHERE
	|		ProductPlanDocument.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		RegisteredRecordsAndGoods.Products
	|	FROM
	|		AccumulationRegister.ReleasePlansProducts_.Turnovers(,,Record,ProductionPlan IN (&ReferencesArrray)) AS RegisteredRecordsAndGoods
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		RegisteredRecordsAndGoods.Products
	|	FROM
	|		AccumulationRegister.MaterialConsumptionPlans.Turnovers(,,Record,ProductionPlan IN (&ReferencesArrray)) AS RegisteredRecordsAndGoods
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		ProductPlanDocument.Products
	|	FROM
	|		Document.AssemblyDisassemblyPlan.Goods AS ProductPlanDocument
	|	WHERE
	|		ProductPlanDocument.Ref IN(&ReferencesArrray)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		ConfigurationOptionsProducts.Products
	|	FROM
	|		Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsProducts 
	|		
	|		INNER JOIN Document.AssemblyDisassemblyPlan.Goods AS ProductPlanDocument
	|			ON ProductPlanDocument.Ref IN(&ReferencesArrray)
	|			AND ProductPlanDocument.ProductKit = ConfigurationOptionsProducts.Ref) AS NestedQuery";
	
	Query.SetParameter("ReferencesArrray", FilterByDocuments);
	
	SetPrivilegedMode(True);
	
	QueryResults = Query.ExecuteBatch();
	
	SetPrivilegedMode(False);
	
	SelectionDetailRecords = QueryResults[0].Select();

	If SelectionDetailRecords.Next() Then
		ContextualSettings.Insert("Scenario",SelectionDetailRecords.Scenario);
		Period = New StandardPeriod;
		Period.StartDate = SelectionDetailRecords.BeginOfPeriod;
		Period.EndDate = SelectionDetailRecords.PeriodEnding;
		ContextualSettings.Insert("Period", Period);
	EndIf;

	ProductsTable = QueryResults[1].Unload();
	If ProductsTable.Count() > 0 Then
	
		ProductsArray = ProductsTable.UnloadColumn("Products");
		ContextualSettings.Insert("Products",ProductsArray);
	
	EndIf; 
	
	Return ContextualSettings;

EndFunction

// Parameters:
// 	SettingsComposer - DataCompositionSettingsComposer -
// 	StructureItem - DataCompositionFilterItemCollection - LongDesc
// 	FieldName - DataCompositionField, String - LongDesc
// 	Presentation - String - LongDesc
// Returns:
// 	Boolean - LongDesc
Function RemoveSelectionByPresentation(SettingsComposer, StructureItem, FieldName, Presentation = "")
	
	If TypeOf(FieldName) = Type("String") Then
		Field = New DataCompositionField(FieldName);
	Else
		Field = FieldName;
	EndIf; 
	
	If TypeOf(StructureItem) = Type("DataCompositionSettingsComposer") Then
		Filters = StructureItem.Settings.Filter.Items;
	Else
		Filters = StructureItem;
	EndIf;
	Result = False;
	For Each Item In Filters Do
		If TypeOf(Item) = Type("DataCompositionFilterItemGroup") Then
			Result = RemoveSelectionByPresentation(SettingsComposer, Item.Items, Field, Presentation);
			If Result Then
				Break;
			EndIf; 
		Else
			If Item.LeftValue = Field 
				And (Not ValueIsFilled(Presentation) 
					Or ValueIsFilled(Presentation) 
					And Item.Presentation = Presentation) Then
					
				UserSettingID = Item.UserSettingID;
				Filters.Delete(Item);
				Result = True;
				ItemTheCustomSettings = SettingsComposer.UserSettings.Items.Find(UserSettingID);
				If ItemTheCustomSettings <> Undefined Then
					SettingsComposer.UserSettings.Items.Delete(UserSettingID);
				EndIf;
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Procedure SetSelectedFieldsBySelections(SelectedFields, 
		UsingPlans,
		NumberOfSelectionsByPlan, 
		DetailByPlans,
		ScenarioComparison)
	
	PurchasePlanField               = New DataCompositionField("PurchasePlan");
	RemainderPlanField              = New DataCompositionField("PlanOfGoodsStock");
	SalesPlanField                = New DataCompositionField("SalesPlan");
	ProductionPlanField          = New DataCompositionField("ProductionPlan");
	BuildPlanKitsField       = New DataCompositionField("AssemblyScheduleKits");
	DisassemblyPlanFieldKits     = New DataCompositionField("DisassemblyScheduleKits");
	AssemblyPlanComponentsField   = New DataCompositionField("AssemblyScheduleComponents");
	DisassemblyPlanFieldComponents = New DataCompositionField("DisassemblyScheduleComponents");
	MaterialPlanField            = New DataCompositionField("MaterialPlan");
	InternalConsumptionPlanField = New DataCompositionField("InventoryConsumptionPlan");
	NeedsAdjustmentField = New DataCompositionField("DemandAdjustment");
	NeedsPlanField          = New DataCompositionField("DemandPlans");
	ProvisionPlanField           = New DataCompositionField("FulfillmentPlans");
	
	// The difference in the number and index of user fields depending on the report variant
	If ScenarioComparison Then
		FieldClosingBalance             = New DataCompositionField("UserFields.Field1");
		IncreasingOpeningBalanceField = New DataCompositionField("UserFields.Field7");
	Else
		DeviationField                  = New DataCompositionField("UserFields.Field1");
		FieldDeviationPercentage           = New DataCompositionField("UserFields.Field2");
		FieldClosingBalance             = New DataCompositionField("UserFields.Field3");
	EndIf;
	
	For Each ComboBox In SelectedFields.Items Do
		
		If TypeOf(ComboBox) = Type("DataCompositionSelectedFieldGroup") Then
			
			If NumberOfSelectionsByPlan.DemandPlans <= 1 And NumberOfSelectionsByPlan.FulfillmentPlans <= 1 Then
				ComboBox.Title = "";
			EndIf;
			
			SetSelectedFieldsBySelections(ComboBox, 
				UsingPlans,
				NumberOfSelectionsByPlan, 
				DetailByPlans,
				ScenarioComparison);
			
		EndIf;
		
		If ComboBox.Field = PurchasePlanField Then
			ComboBox.Use = UsingPlans.PurchasePlans;
		EndIf;
		If ComboBox.Field = RemainderPlanField Then
			ComboBox.Use = UsingPlans.PlansOfGoodsStock;
		EndIf;
		If ComboBox.Field = IncreasingOpeningBalanceField Then
			ComboBox.Use = UsingPlans.PlansOfGoodsStock;
		EndIf;
		If ComboBox.Field = FieldClosingBalance Then
			ComboBox.Use = UsingPlans.PlansOfGoodsStock;
		EndIf;
		If ComboBox.Field = DeviationField Then
			ComboBox.Use = Not UsingPlans.PlansOfGoodsStock;
		EndIf;
		If ComboBox.Field = FieldDeviationPercentage Then
			ComboBox.Use = Not UsingPlans.PlansOfGoodsStock;
		EndIf;
		If ComboBox.Field = SalesPlanField Then
			ComboBox.Use = UsingPlans.SalesPlans;
		EndIf;
		If ComboBox.Field = ProductionPlanField Then
			ComboBox.Use = UsingPlans.ProductionPlans;
		EndIf;
		If ComboBox.Field = BuildPlanKitsField Then
			ComboBox.Use = UsingPlans.AssemblyPlansKits;
		EndIf;
		If ComboBox.Field = DisassemblyPlanFieldKits Then
			ComboBox.Use = UsingPlans.DisassemblyPlansKits;
		EndIf;
		If ComboBox.Field = AssemblyPlanComponentsField Then
			ComboBox.Use = UsingPlans.BuildPlansComponents;
		EndIf;
		If ComboBox.Field = DisassemblyPlanFieldComponents Then
			ComboBox.Use = UsingPlans.DisassemblyPlansComponents;
		EndIf;
		If ComboBox.Field = MaterialPlanField Then
			ComboBox.Use = UsingPlans.MaterialPlans;
		EndIf;
		If ComboBox.Field = InternalConsumptionPlanField Then
			ComboBox.Use = UsingPlans.InventoryConsumptionPlans;
		EndIf;
		If ComboBox.Field = NeedsAdjustmentField Then
			ComboBox.Use = UsingPlans.DemandAdjustments;
		EndIf;
		If ComboBox.Field = NeedsPlanField And Not ValueIsFilled(ComboBox.Title) Then
			ComboBox.Use = Not DetailByPlans;
		EndIf;
		If ComboBox.Field = ProvisionPlanField And Not ValueIsFilled(ComboBox.Title) Then
			ComboBox.Use = Not DetailByPlans;
		EndIf;
		If ComboBox.Field = NeedsPlanField And ValueIsFilled(ComboBox.Title) Then
			If NumberOfSelectionsByPlan.DemandPlans <= 1 Then
				ComboBox.Use = False;
			Else
				ComboBox.Use = DetailByPlans;
			EndIf;
		EndIf;
		If ComboBox.Field = ProvisionPlanField And ValueIsFilled(ComboBox.Title) Then
			If NumberOfSelectionsByPlan.FulfillmentPlans <= 1 Then
				ComboBox.Use = False;
			Else
				ComboBox.Use = DetailByPlans;
			EndIf;
		EndIf;
	
	EndDo;
	
EndProcedure

Procedure SetSelectedFieldsForScenarioComparisonDimensions(Group,
		SelectedDimensionFields,
		UsingPlans,
		NumberOfSelectionsByPlan,
		DetailByPlans,
		DisplayOnlyScriptDeviations,
		MeaningOfComparisonScenarios)
	
	// Selected fields of the additional scenario(s)
	ScenarioPurchasePlanField                 = New DataCompositionField("ScenarioProcurementPlan");
	ScenarioRemainderPlanField                = New DataCompositionField("ScenarioRemainderPlan");
	ScenarioSalesPlanField                  = New DataCompositionField("ScenarioSalesPlan");
	ScenarioProductionPlanField            = New DataCompositionField("ScriptProductionPlan");
	BuildPlanScenarioKitsField         = New DataCompositionField("BuildPlanScenarioKits");
	DisassemblyPlanScenarioKitsField       = New DataCompositionField("DisassemblyPlanScenarioSets");
	BuildPlanForScenariosField     = New DataCompositionField("BuildPlanForScenarios");
	DisassemblyPlanFieldForScenarios   = New DataCompositionField("DisassemblyPlanForAllScenarios");
	ScenarioMaterialPlanField              = New DataCompositionField("ScenarioMaterialPlan");
	InternalScenarioConsumptionPlanField   = New DataCompositionField("PlanInternalConsumptionScenarios");
	AdjustingScenarioNeedsField   = New DataCompositionField("AdjustingScenarioNeeds");
	ScenarioNeedsPlanField            = New DataCompositionField("ScenarioNeedsPlans");
	ScenarioAssurancePlanField             = New DataCompositionField("ScenarioAssurancePlans");
	IncreasingOpeningBalanceFieldScenarios = New DataCompositionField("IncreasingInitialRemainder");
	FinalRemainderField             = New DataCompositionField("UserFields.Field2");
	
	// Selected fields of deviations of the main scenario relative to the additional scenario(s)
	ProcurementPlanFieldDeviation                = New DataCompositionField("ProcurementPlanDeviation");
	SalesPlanDeviationField                 = New DataCompositionField("SalesPlanDeviation");
	ProductionPlanDeviationField           = New DataCompositionField("ProductionPlanDeviation");
	BuildPlanFieldSetsDeviation        = New DataCompositionField("BuildPlanKitsRejection");
	DisassemblyPlanFieldSetsDeviation      = New DataCompositionField("DisassemblyPlanSetsDeviation");
	BuildPlanComponentsDeviationField    = New DataCompositionField("AssemblyPlanComponentsDeviation");
	DisassemblyPlanFieldComponentsDeviation  = New DataCompositionField("DisassemblyPlanComponentsDeviation");
	MaterialPlanFieldDeviation             = New DataCompositionField("MaterialPlanDeviation");
	FieldInternalConsumptionPlanDeviation  = New DataCompositionField("DomesticConsumptionPlanDeviation");
	AdjustmentAndDeviationField  = New DataCompositionField("AdjustmentAndDeviation");
	NeedPlansRejectionField          = New DataCompositionField("UserFields.Field3");
	SecurityPlanRejectionField          = New DataCompositionField("UserFields.Field4");
	InitialRemainderDeviationField          = New DataCompositionField("UserFields.Field5");
	FiniteRemainderDeviationField           = New DataCompositionField("UserFields.Field6");
	
	// Grouping fields of the additional scenario(s)
	DeviationHeaderField = New DataCompositionField("RejectionHeader");
	
	If Group.Name = "AdditionalScenarios" And ValueIsFilled(MeaningOfComparisonScenarios) Then
		
		For Each ComboBox In SelectedDimensionFields.Items Do
			
			If TypeOf(ComboBox) = Type("DataCompositionSelectedFieldGroup") Then
				
				If NumberOfSelectionsByPlan.DemandPlans <= 1 And NumberOfSelectionsByPlan.FulfillmentPlans <= 1 Then
					ComboBox.Title = "";
				EndIf;
				
				SetSelectedFieldsForScenarioComparisonDimensions(Group,
					ComboBox,
					UsingPlans,
					NumberOfSelectionsByPlan,
					DetailByPlans,
					DisplayOnlyScriptDeviations,
					MeaningOfComparisonScenarios);
				
			EndIf;
			
			If Not DisplayOnlyScriptDeviations And ValueIsFilled(MeaningOfComparisonScenarios) Then
				
				GroupFields = Group.GroupFields; // DataCompositionGroupFields - 
				For Each Item In GroupFields.Items Do
					
					If Item.Field = DeviationHeaderField Then
						Item.Use = False;
					EndIf;
					
				EndDo;
				
				If DetailByPlans Then
					
					If ComboBox.Field = ScenarioPurchasePlanField Then
						ComboBox.Use = UsingPlans.PurchasePlans;
					EndIf;
					If ComboBox.Field = ScenarioSalesPlanField Then
						ComboBox.Use = UsingPlans.SalesPlans;
					EndIf;
					If ComboBox.Field = ScenarioProductionPlanField Then
						ComboBox.Use = UsingPlans.ProductionPlans;
					EndIf;
					If ComboBox.Field = BuildPlanScenarioKitsField Then
						ComboBox.Use = UsingPlans.AssemblyPlansKits;
					EndIf;
					If ComboBox.Field = DisassemblyPlanScenarioKitsField Then
						ComboBox.Use = UsingPlans.DisassemblyPlansKits;
					EndIf;
					If ComboBox.Field = BuildPlanForScenariosField Then
						ComboBox.Use = UsingPlans.BuildPlansComponents;
					EndIf;
					If ComboBox.Field = DisassemblyPlanFieldForScenarios Then
						ComboBox.Use = UsingPlans.DisassemblyPlansComponents;
					EndIf;
					If ComboBox.Field = ScenarioMaterialPlanField Then
						ComboBox.Use = UsingPlans.MaterialPlans;
					EndIf;
					If ComboBox.Field = InternalScenarioConsumptionPlanField Then
						ComboBox.Use = UsingPlans.InventoryConsumptionPlans;
					EndIf;
					If ComboBox.Field = AdjustingScenarioNeedsField Then
						ComboBox.Use = UsingPlans.DemandAdjustments;
					EndIf;
					
				Else
					
					If ComboBox.Field = ScenarioPurchasePlanField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = ScenarioSalesPlanField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = ScenarioProductionPlanField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = BuildPlanScenarioKitsField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = DisassemblyPlanScenarioKitsField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = BuildPlanForScenariosField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = DisassemblyPlanFieldForScenarios Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = ScenarioMaterialPlanField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = InternalScenarioConsumptionPlanField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = AdjustingScenarioNeedsField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
				EndIf;
				
				If ComboBox.Field = DeviationHeaderField Then
					ComboBox.Use = False;
				EndIf;
				If ComboBox.Field = ScenarioRemainderPlanField Then
					ComboBox.Use = UsingPlans.PlansOfGoodsStock;
				EndIf;
				If ComboBox.Field = IncreasingOpeningBalanceFieldScenarios Then
					ComboBox.Use = UsingPlans.PlansOfGoodsStock;
				EndIf;
				If ComboBox.Field = FinalRemainderField Then
					ComboBox.Use = UsingPlans.PlansOfGoodsStock;
				EndIf;
				If ComboBox.Field = ScenarioNeedsPlanField And ComboBox.Title = "InTotal" Then
					If NumberOfSelectionsByPlan.DemandPlans <= 1 Then
						ComboBox.Use = False;
					Else
						ComboBox.Use = DetailByPlans;
					EndIf;
				EndIf;
				If ComboBox.Field = ScenarioAssurancePlanField And ComboBox.Title = "InTotal" Then
					If NumberOfSelectionsByPlan.FulfillmentPlans <= 1 Then
						ComboBox.Use = False;
					Else
						ComboBox.Use = DetailByPlans;
					EndIf;
				EndIf;
				If ComboBox.Field = ScenarioNeedsPlanField And ComboBox.Title <> "InTotal" Then
					ComboBox.Use = Not DetailByPlans;
				EndIf;
				If ComboBox.Field = ScenarioAssurancePlanField And ComboBox.Title <> "InTotal" Then
					ComboBox.Use = Not DetailByPlans;
				EndIf;
			EndIf;
			
			If DisplayOnlyScriptDeviations And ValueIsFilled(MeaningOfComparisonScenarios) Then
				
				GroupFields = Group.GroupFields; // DataCompositionGroupFields - 
				For Each Item In GroupFields.Items Do
					
					If Item.Field = DeviationHeaderField Then
						Item.Use = True;
					EndIf;
					
				EndDo;
				
				If DetailByPlans Then
					
					If ComboBox.Field = ProcurementPlanFieldDeviation Then
						ComboBox.Use = UsingPlans.PurchasePlans;
					EndIf;
					If ComboBox.Field = ScenarioPurchasePlanField Then
						ComboBox.Use = Not DetailByPlans;
					EndIf;
					If ComboBox.Field = SalesPlanDeviationField Then
						ComboBox.Use = UsingPlans.SalesPlans;
					EndIf;
					If ComboBox.Field = ScenarioSalesPlanField Then
						ComboBox.Use = Not DetailByPlans;
					EndIf;
					If ComboBox.Field = ProductionPlanDeviationField Then
						ComboBox.Use = UsingPlans.ProductionPlans;
					EndIf;
					If ComboBox.Field = ScenarioProductionPlanField Then
						ComboBox.Use = Not DetailByPlans;
					EndIf;
					If ComboBox.Field = BuildPlanFieldSetsDeviation Then
						ComboBox.Use = UsingPlans.AssemblyPlansKits;
					EndIf;
					If ComboBox.Field = BuildPlanScenarioKitsField Then
						ComboBox.Use = Not DetailByPlans;
					EndIf;
					If ComboBox.Field = DisassemblyPlanFieldSetsDeviation Then
						ComboBox.Use = UsingPlans.DisassemblyPlansKits;
					EndIf;
					If ComboBox.Field = DisassemblyPlanScenarioKitsField Then
						ComboBox.Use = Not DetailByPlans;
					EndIf;
					If ComboBox.Field = BuildPlanComponentsDeviationField Then
						ComboBox.Use = UsingPlans.BuildPlansComponents;
					EndIf;
					If ComboBox.Field = BuildPlanForScenariosField Then
						ComboBox.Use = Not DetailByPlans;
					EndIf;
					If ComboBox.Field = DisassemblyPlanFieldComponentsDeviation Then
						ComboBox.Use = UsingPlans.DisassemblyPlansComponents;
					EndIf;
					If ComboBox.Field = DisassemblyPlanFieldForScenarios Then
						ComboBox.Use = Not DetailByPlans;
					EndIf;
					If ComboBox.Field = MaterialPlanFieldDeviation Then
						ComboBox.Use = UsingPlans.MaterialPlans;
					EndIf;
					If ComboBox.Field = ScenarioMaterialPlanField Then
						ComboBox.Use = Not DetailByPlans;
					EndIf;
					If ComboBox.Field = FieldInternalConsumptionPlanDeviation Then
						ComboBox.Use = UsingPlans.InventoryConsumptionPlans;
					EndIf;
					If ComboBox.Field = InternalScenarioConsumptionPlanField Then
						ComboBox.Use = Not DetailByPlans;
					EndIf;
					If ComboBox.Field = AdjustmentAndDeviationField Then
						ComboBox.Use = UsingPlans.DemandAdjustments;
					EndIf;
					If ComboBox.Field = AdjustingScenarioNeedsField Then
						ComboBox.Use = Not DetailByPlans;
					EndIf;
					
				Else
					
					If ComboBox.Field = ScenarioPurchasePlanField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = ScenarioSalesPlanField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = ScenarioProductionPlanField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = BuildPlanScenarioKitsField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = DisassemblyPlanScenarioKitsField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = BuildPlanForScenariosField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = DisassemblyPlanFieldForScenarios Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = ScenarioMaterialPlanField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = InternalScenarioConsumptionPlanField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = AdjustingScenarioNeedsField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					
				EndIf;
				
				If ComboBox.Field = DeviationHeaderField Then
					ComboBox.Use = True;
				EndIf;
				If ComboBox.Field = InitialRemainderDeviationField Then
					ComboBox.Use = UsingPlans.PlansOfGoodsStock;
				EndIf;
				If ComboBox.Field = FiniteRemainderDeviationField Then
					ComboBox.Use = UsingPlans.PlansOfGoodsStock;
				EndIf;
				If ComboBox.Field = NeedPlansRejectionField And ComboBox.Title = "InTotal" Then
					
					If NumberOfSelectionsByPlan.DemandPlans <= 1 Then
						ComboBox.Use = False;
					Else
						ComboBox.Use = DetailByPlans;
					EndIf;
					
				EndIf;
				If ComboBox.Field = SecurityPlanRejectionField And ComboBox.Title = "InTotal" Then
					If NumberOfSelectionsByPlan.FulfillmentPlans <= 1 Then
						ComboBox.Use = False;
					Else
						ComboBox.Use = DetailByPlans;
					EndIf;
				EndIf;
				If ComboBox.Field = NeedPlansRejectionField And ComboBox.Title <> "InTotal" Then
					ComboBox.Use = Not DetailByPlans;
				EndIf;
				If ComboBox.Field = SecurityPlanRejectionField And ComboBox.Title <> "InTotal" Then
					ComboBox.Use = Not DetailByPlans;
				EndIf;
				
				If ComboBox.Field = ScenarioRemainderPlanField Then
					ComboBox.Use = False;
				EndIf;
				If ComboBox.Field = IncreasingOpeningBalanceFieldScenarios Then
					ComboBox.Use = False;
				EndIf;
				If ComboBox.Field = FinalRemainderField Then
					ComboBox.Use = False;
				EndIf;
				If ComboBox.Field = ScenarioNeedsPlanField Then
					ComboBox.Use = False;
				EndIf;
				If ComboBox.Field = ScenarioAssurancePlanField Then
					ComboBox.Use = False;
				EndIf;
				
			EndIf;
		EndDo;
	EndIf;
	
	If Group.Name = "ScenarioDeviations" And ValueIsFilled(MeaningOfComparisonScenarios) Then
		
		If Not DisplayOnlyScriptDeviations And ValueIsFilled(MeaningOfComparisonScenarios) Then
			
			Group.Use = True;
			
			For Each ComboBox In SelectedDimensionFields.Items Do
				
				If TypeOf(ComboBox) = Type("DataCompositionSelectedFieldGroup") Then
					
					If NumberOfSelectionsByPlan.DemandPlans <= 1 And NumberOfSelectionsByPlan.FulfillmentPlans <= 1 Then
						ComboBox.Title = "";
					EndIf;
					
					SetSelectedFieldsForScenarioComparisonDimensions(Group,
						ComboBox,
						UsingPlans,
						NumberOfSelectionsByPlan,
						DetailByPlans,
						DisplayOnlyScriptDeviations,
						MeaningOfComparisonScenarios);
					
				EndIf;
				
				If DetailByPlans Then
					
					If ComboBox.Field = ProcurementPlanFieldDeviation Then
						ComboBox.Use = UsingPlans.PurchasePlans;
					EndIf;
					If ComboBox.Field = SalesPlanDeviationField Then
						ComboBox.Use = UsingPlans.SalesPlans;
					EndIf;
					If ComboBox.Field = ProductionPlanDeviationField Then
						ComboBox.Use = UsingPlans.ProductionPlans;
					EndIf;
					If ComboBox.Field = BuildPlanFieldSetsDeviation Then
						ComboBox.Use = UsingPlans.AssemblyPlansKits;
					EndIf;
					If ComboBox.Field = DisassemblyPlanFieldSetsDeviation Then
						ComboBox.Use = UsingPlans.DisassemblyPlansKits;
					EndIf;
					If ComboBox.Field = BuildPlanComponentsDeviationField Then
						ComboBox.Use = UsingPlans.BuildPlansComponents;
					EndIf;
					If ComboBox.Field = DisassemblyPlanFieldComponentsDeviation Then
						ComboBox.Use = UsingPlans.DisassemblyPlansComponents;
					EndIf;
					If ComboBox.Field = MaterialPlanFieldDeviation Then
						ComboBox.Use = UsingPlans.MaterialPlans;
					EndIf;
					If ComboBox.Field = FieldInternalConsumptionPlanDeviation Then
						ComboBox.Use = UsingPlans.InventoryConsumptionPlans;
					EndIf;
					If ComboBox.Field = AdjustmentAndDeviationField Then
						ComboBox.Use = UsingPlans.DemandAdjustments;
					EndIf;
					
				Else
					
					If ComboBox.Field = ProcurementPlanFieldDeviation Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = SalesPlanDeviationField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = ProductionPlanDeviationField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = BuildPlanFieldSetsDeviation Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = DisassemblyPlanFieldSetsDeviation Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = BuildPlanComponentsDeviationField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = DisassemblyPlanFieldComponentsDeviation Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = MaterialPlanFieldDeviation Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = FieldInternalConsumptionPlanDeviation Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					If ComboBox.Field = AdjustmentAndDeviationField Then
						ComboBox.Use = DetailByPlans;
					EndIf;
					
				EndIf;
				
				If ComboBox.Field = InitialRemainderDeviationField Then
					ComboBox.Use = UsingPlans.PlansOfGoodsStock;
				EndIf;
				If ComboBox.Field = FiniteRemainderDeviationField Then
					ComboBox.Use = UsingPlans.PlansOfGoodsStock;
				EndIf;
				
				If ComboBox.Field = NeedPlansRejectionField And ComboBox.Title = "InTotal" Then
					If NumberOfSelectionsByPlan.DemandPlans <= 1 Then
						ComboBox.Use = False;
					Else
						ComboBox.Use = DetailByPlans;
					EndIf;
				EndIf;
				If ComboBox.Field = SecurityPlanRejectionField And ComboBox.Title = "InTotal" Then
					If NumberOfSelectionsByPlan.FulfillmentPlans <= 1 Then
						ComboBox.Use = False;
					Else
						ComboBox.Use = DetailByPlans;
					EndIf;
				EndIf;
				If ComboBox.Field = NeedPlansRejectionField And ComboBox.Title <> "InTotal" Then
					ComboBox.Use = Not DetailByPlans;
				EndIf;
				If ComboBox.Field = SecurityPlanRejectionField And ComboBox.Title <> "InTotal" Then
					ComboBox.Use = Not DetailByPlans;
				EndIf;
				
			EndDo;
			
		Else
			Group.Use = False;
		EndIf;
	EndIf;
	
EndProcedure

Function GetSelection(StructureItem, FieldName, RightValue = 0)
	
	If TypeOf(FieldName) = Type("String") Then
		Field = New DataCompositionField(FieldName);
	Else
		Field = FieldName;
	EndIf; 
	
	Filter = Undefined;
	If TypeOf(StructureItem) = Type("DataCompositionSettingsComposer") Then
		Filters = StructureItem.Settings.Filter.Items;
	Else
		Filters = StructureItem;
	EndIf;
	
	For Each Item In Filters Do
		If TypeOf(Item) = Type("DataCompositionFilterItemGroup") Then
			Filter = GetSelection(Item.Items, Field, RightValue);
			If Filter <> Undefined Then
				Break;
			EndIf; 
		Else
			If Item.LeftValue = Field 
				And (Not ValueIsFilled(RightValue) 
					Or ValueIsFilled(RightValue) 
					And Item.RightValue = RightValue) Then
				Filter = Item;
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	Return Filter;
	
EndFunction

// Parameters:
// 	Object - DocumentObject.PurchasePlan - 
// 	       - DocumentObject.PlanOfGoodsStock -
// 	       - DocumentObject.SalesPlan -
// 	       - DocumentObject.SalesPlanByCategories -
// 	       - DocumentObject.ProductionPlan -
// 	       - DocumentObject.AssemblyDisassemblyPlan -
// 	Cancel - Boolean -
// 	WriteMode - DocumentWriteMode -
// 	PlanType - EnumRef.TypesOfPlans - 
Procedure CheckApprovedStatus(Object, Cancel, WriteMode, PlanType) Export 
	
	If Users.IsFullUser() Then
		Return;
	EndIf;
	
	If PlanType = Enums.TypesOfPlans.PurchasePlan And Users.RolesAvailable("ApprovalOfPurchasePlans") Then
		Return;
	ElsIf PlanType = Enums.TypesOfPlans.PlanOfGoodsStock And Users.RolesAvailable("ApprovalOfPlansOfGoodsStock") Then
		Return;
	ElsIf PlanType = Enums.TypesOfPlans.SalesPlan And Users.RolesAvailable("ApprovalOfSalesPlans") Then
		Return;
	ElsIf PlanType = Enums.TypesOfPlans.SalesPlanByCategories And Users.RolesAvailable("ApprovalOfSalesPlansByCategories") Then
		Return;
	ElsIf PlanType = Enums.TypesOfPlans.InventoryConsumptionPlan And Users.RolesAvailable("ApprovalOfInventoryConsumptionPlan") Then
		Return;
	ElsIf PlanType = Enums.TypesOfPlans.ProductionPlan And Users.RolesAvailable("ApprovalOfProductionPlans") Then
		Return;
	ElsIf PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan And Users.RolesAvailable("ApprovalOfAssemblyDisassemblyPlans") Then
		Return;
	EndIf;
	
	If Not PrivilegedMode() 
		And (WriteMode = DocumentWriteMode.Posting 
		Or WriteMode = DocumentWriteMode.UndoPosting) Then
		
		If Object.Status = Enums.PlanStatuses.Upholded 
			Or ValueIsFilled(Object.Ref) 
			And Common.ObjectAttributeValue(Object.Ref, "Status") = Enums.PlanStatuses.Upholded Then
			
			If WriteMode = DocumentWriteMode.Posting Then
				MessageText = NStr("vi = 'Không đủ quyền để kết chuyển chứng từ với trạng thái ""Đã duyệt"".';
									|ru = 'Недостаточно прав для проведения документа в статусе ""Утвержден"".';
									|en = 'Insufficient rights to post the document with the Confirmed status.'; fa = 'Insufficient rights to post the document with the Confirmed status.';
									|it = 'Non abbastanza diritti per registrare il documento nello stato ""Approvato"".';
									|pl = 'Nie wystarczające uprawnienia do zaksięgowania dokumentu w statusie ""Утвержден"".';
									|tr = 'Erişim yetkisi, belgenin ""Onaylandı"" durumunda kaydedilmesi için yetersiz.'")
			Else
				MessageText = NStr("vi = 'Không đủ quyền để hủy kết chuyển chứng từ với trạng thái ""Đã duyệt"".';
									|ru = 'Недостаточно прав для отмены проведения документа в статусе ""Утвержден"".';
									|en = 'Insufficient rights to cancel posting the document with the Confirmed status.'; fa = 'Insufficient rights to cancel posting the document with the Confirmed status.';
									|it = 'Non abbastanza diritti per annullare la registrazione del documento nello stato ""Approvato"".';
									|pl = 'Nie wystarczające uprawnienia do anulowania zaksięgowania dokumentu w statusie ""Утвержден"".';
									|tr = 'Erişim yetkisi, belgenin ""Onaylandı"" durumunda iptali için yetersiz.'")
			EndIf;
			
			CommonClientServer.MessageToUser(
				MessageText,
				Object.Ref,
				,
				,
				Cancel);
		
		EndIf; 
	EndIf;

EndProcedure

Function GetFillInStatuses(Scenario) Export
	
	FillingStatuses = New Array;
	FillingStatuses.Add(Enums.PlanStatuses.AwaitingConfirmation);
	FillingStatuses.Add(Enums.PlanStatuses.Upholded);
	
	Return FillingStatuses
	
EndFunction

// Parameters:
// 	FormData1 - DocumentObject.PurchasePlan - 
// 	            - DocumentObject.PlanOfGoodsStock -
// 	            - DocumentObject.SalesPlan -
// 	            - DocumentObject.SalesPlanByCategories -
// 	            - DocumentObject.ProductionPlan -
// 	            - DocumentObject.AssemblyDisassemblyPlan -
// 	DocumentTypeName - String -
// Returns:
// 	Undefined - LongDesc
Function CheckExistenceOfAlreadyCreatedPlans(FormData1, DocumentTypeName) Export
	
	If Not ValueIsFilled(FormData1.Ref) Or Not ValueIsFilled(FormData1.Scenario) Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Ref",   FormData1.Ref);
	Query.SetParameter("Scenario", FormData1.Scenario);
	Query.SetParameter("BeginOfPeriod",   FormData1.BeginOfPeriod);
	Query.SetParameter("PeriodEnding", FormData1.PeriodEnding);
	
	If DocumentTypeName = "PurchasePlan" Then
		
		Query.SetParameter("Warehouse",      FormData1.Warehouse);
		Query.SetParameter("Partner",    FormData1.Partner);
		Query.SetParameter("Terms", FormData1.Terms);
		Query.SetParameter("Organization", FormData1.Organization);
		
		Query.Text = 
		"SELECT ALLOWED TOP 1
		|	Plan.Ref,
		|	Plan.Status
		|FROM
		|	Document.PurchasePlan AS Plan
		|WHERE
		|	Plan.Posted
		|	AND Plan.Scenario = &Scenario
		|	AND Plan.Organization = &Organization
		|	AND Plan.Warehouse = &Warehouse
		|	AND Plan.Partner = &Partner
		|	AND Plan.Terms = &Terms
		|	AND Plan.Substitutional
		|	AND Plan.Status <> VALUE(Enum.PlanStatuses.Upholded)
		|	AND Plan.Status.Order >= 2
		|	AND Plan.Ref <> &Ref
		|	AND (Plan.BeginOfPeriod >= &BeginOfPeriod
		|				AND Plan.BeginOfPeriod <= &PeriodEnding
		|			OR Plan.PeriodEnding <= &PeriodEnding
		|				AND Plan.PeriodEnding >= &BeginOfPeriod)
		|
		|ORDER BY
		|	Plan.Date DESC";
		
	ElsIf DocumentTypeName = "PlanOfGoodsStock" Then
		
		Query.SetParameter("Warehouse",      FormData1.Warehouse);
		
		Query.Text = 
		"SELECT ALLOWED TOP 1
		|	Plan.Ref,
		|	Plan.Status
		|FROM
		|	Document.PlanOfGoodsStock AS Plan
		|WHERE
		|	Plan.Posted
		|	AND Plan.Scenario = &Scenario
		|	AND Plan.Warehouse = &Warehouse
		|	AND Plan.Substitutional
		|	AND Plan.Status <> VALUE(Enum.PlanStatuses.Upholded)
		|	AND Plan.Status.Order >= 2
		|	AND Plan.Ref <> &Ref
		|	AND (Plan.BeginOfPeriod >= &BeginOfPeriod
		|				AND Plan.BeginOfPeriod <= &PeriodEnding
		|			OR Plan.PeriodEnding <= &PeriodEnding
		|				AND Plan.PeriodEnding >= &BeginOfPeriod)
		|
		|ORDER BY
		|	Plan.Date DESC";
		
	ElsIf DocumentTypeName = "SalesPlan" Then
		
		Query.SetParameter("Warehouse",      FormData1.Warehouse);
		Query.SetParameter("Partner",    FormData1.Partner);
		Query.SetParameter("Terms", FormData1.Terms);
		Query.SetParameter("Department", FormData1.Department);
		Query.SetParameter("Organization", FormData1.Organization);
		Query.SetParameter("Manager",   FormData1.Manager);
		Query.SetParameter("StoreFormat", FormData1.StoreFormat);
		
		Query.Text = 
		"SELECT ALLOWED TOP 1
		|	Plan.Ref,
		|	Plan.Status
		|FROM
		|	Document.SalesPlan AS Plan
		|WHERE
		|	Plan.Posted
		|	AND Plan.Scenario = &Scenario
		|	AND Plan.Warehouse = &Warehouse
		|	AND Plan.Partner = &Partner
		|	AND Plan.Terms = &Terms
		|	AND Plan.Department = &Department
		|	AND Plan.Organization = &Organization
		|	AND Plan.Substitutional
		|	AND Plan.Status <> VALUE(Enum.PlanStatuses.Upholded)
		|	AND Plan.Status.Order >= 2
		|	AND Plan.Ref <> &Ref
		|	AND Plan.StoreFormat = &StoreFormat
		|	AND Plan.Manager = &Manager
		|	AND (Plan.BeginOfPeriod >= &BeginOfPeriod
		|				AND Plan.BeginOfPeriod <= &PeriodEnding
		|			OR Plan.PeriodEnding <= &PeriodEnding
		|				AND Plan.PeriodEnding >= &BeginOfPeriod)
		|
		|ORDER BY
		|	Plan.Date DESC"
		
	ElsIf DocumentTypeName = "SalesPlanByCategories" Then
		
		Query.SetParameter("Warehouse",      FormData1.Warehouse);
		Query.SetParameter("StoreFormat", FormData1.StoreFormat);
		
		Query.Text = 
		"SELECT ALLOWED TOP 1
		|	Plan.Ref,
		|	Plan.Status
		|FROM
		|	Document.SalesPlanByCategories AS Plan
		|WHERE
		|	Plan.Posted
		|	AND Plan.Scenario = &Scenario
		|	AND Plan.Warehouse = &Warehouse
		|	AND Plan.Substitutional
		|	AND Plan.Status <> VALUE(Enum.PlanStatuses.Upholded)
		|	AND Plan.Status.Order >= 2
		|	AND Plan.Ref <> &Ref
		|	AND Plan.StoreFormat = &StoreFormat
		|	AND (Plan.BeginOfPeriod >= &BeginOfPeriod
		|				AND Plan.BeginOfPeriod <= &PeriodEnding
		|			OR Plan.PeriodEnding <= &PeriodEnding
		|				AND Plan.PeriodEnding >= &BeginOfPeriod)
		|
		|ORDER BY
		|	Plan.Date DESC"
		
	ElsIf DocumentTypeName = "InventoryConsumptionPlan" Then
		
		Query.SetParameter("Warehouse",      FormData1.Warehouse);
		Query.SetParameter("Department",FormData1.Department);
		
		Query.Text = 
		"SELECT ALLOWED TOP 1
		|	Plan.Ref,
		|	Plan.Status
		|FROM
		|	Document.InventoryConsumptionPlan AS Plan
		|WHERE
		|	Plan.Posted
		|	AND Plan.Scenario = &Scenario
		|	AND Plan.Warehouse = &Warehouse
		|	AND Plan.Department = &Department
		|	AND Plan.Substitutional
		|	AND Plan.Status <> VALUE(Enum.PlanStatuses.Upholded)
		|	AND Plan.Status.Order >= 2
		|	AND Plan.Ref <> &Ref
		|	AND (Plan.BeginOfPeriod >= &BeginOfPeriod
		|				AND Plan.BeginOfPeriod <= &PeriodEnding
		|			OR Plan.PeriodEnding <= &PeriodEnding
		|				AND Plan.PeriodEnding >= &BeginOfPeriod)
		|
		|ORDER BY
		|	Plan.Date DESC"
	ElsIf DocumentTypeName = "ProductionPlan" Then
		
		Query.SetParameter("Department",FormData1.Department);
		
		Query.Text = 
		"SELECT ALLOWED TOP 1
		|	Plan.Ref,
		|	Plan.Status
		|FROM
		|	Document.ProductionPlan AS Plan
		|WHERE
		|	Plan.Posted
		|	AND Plan.Scenario = &Scenario
		|	AND Plan.Substitutional
		|	AND Plan.Status <> VALUE(Enum.PlanStatuses.Upholded)
		|	AND Plan.Status.Order >= 2
		|	AND Plan.Ref <> &Ref
		|	AND Plan.Department = &Department
		|	AND (Plan.BeginOfPeriod >= &BeginOfPeriod
		|				AND Plan.BeginOfPeriod <= &PeriodEnding
		|			OR Plan.PeriodEnding <= &PeriodEnding
		|				AND Plan.PeriodEnding >= &BeginOfPeriod)
		|
		|ORDER BY
		|	Plan.Date DESC"
	ElsIf DocumentTypeName = "AssemblyDisassemblyPlan" Then
		
		Query.SetParameter("Warehouse",      FormData1.Warehouse);
		
		Query.Text = 
		"SELECT ALLOWED TOP 1
		|	Plan.Ref,
		|	Plan.Status
		|FROM
		|	Document.AssemblyDisassemblyPlan AS Plan
		|WHERE
		|	Plan.Posted
		|	AND Plan.Scenario = &Scenario
		|	AND Plan.Warehouse = &Warehouse
		|	AND Plan.Substitutional
		|	AND Plan.Status <> VALUE(Enum.PlanStatuses.Upholded)
		|	AND Plan.Status.Order >= 2
		|	AND Plan.Ref <> &Ref
		|	AND (Plan.BeginOfPeriod >= &BeginOfPeriod
		|				AND Plan.BeginOfPeriod <= &PeriodEnding
		|			OR Plan.PeriodEnding <= &PeriodEnding
		|				AND Plan.PeriodEnding >= &BeginOfPeriod)
		|
		|ORDER BY
		|	Plan.Date DESC"
		
	EndIf;
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Trong cơ sở dữ liệu đã tạo chứng từ trong kỳ hiện tại: %1 có trạng thái %2 mà cần được phê duyệt.';
																					|ru = 'В базе уже создан документ за текущий период: %1 в статусе %2, который необходимо утвердить.';
																					|en = 'Document for the current period is already created in the infobase: %1 in the %2 status which should be approved.'; fa = 'Document for the current period is already created in the infobase: %1 in the %2 status which should be approved.';
																					|it = 'Un documento è già stato creato nel database per il periodo corrente: %1 nello stato %2 che deve essere approvato.';
																					|pl = 'W bazie już jest utworzony dokument za bieżący okres: %1 w statusie %2, który należy zatwierdzić.';
																					|tr = 'Tabanda cari dönem için halihazırda oluşturulmuş bir belge mevcut: %2 durumunda %1, onaylanması gerekiyor.'"), 
																					SelectionDetailRecords.Ref, SelectionDetailRecords.Status);
		
		CommonClientServer.MessageToUser(ErrorText, SelectionDetailRecords.Ref, "PlanProfile");
		
		Return SelectionDetailRecords.Ref;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

// Concatenates arrays, returning the result of the concatenation
// Returns:
//  Array - a combined array of values.
Function CombineArrays(Array1, Array2) Export
	
	CombinedArray = New Array;
	
	For Each ArrayElement In Array1 Do
	
		If CombinedArray.Find(ArrayElement) = Undefined Then
			CombinedArray.Add(ArrayElement);
		EndIf; 
	
	EndDo;
	
	For Each ArrayElement In Array2 Do
	
		If CombinedArray.Find(ArrayElement) = Undefined Then
			CombinedArray.Add(ArrayElement);
		EndIf; 
	
	EndDo;
	
	Return CombinedArray;
	
EndFunction

#EndRegion

#EndRegion

#Region Report_PlannedDemandForTypesOfRC

// The function returns the earliest and latest date of employment plans for work center types
//  in production plans for the specified product planning scenario.
//
// Parameters:
//  Parameters - Structure - contains:
//   Script - Reference link.Product Planning Scenarios - the specified report scenario.
//   Screenplay statusreferenceslink.Plan Statuses - Statuses of production plans.
//   Production Plan - Documentlink.Production plan - a list of production plans that meet the conditions.
//   SELECTIONPOSTATUSU is used - Boolean - check for the use of selection by Status of plans.
//   The selection plan is used - Boolean - check for the use of selection according to the production plan.
//
// Returns:
//  Structure - dates of the deadline periods of employment plans types of work centers
//   Perioddatanachala - Date - date of the first period of the employment plans of the types of RC.
//   Perioddate - Date - the date of the last period of the employment plans of the types of RC.
//
Function GetDeadlinePeriodsOfEmploymentPlansForRCTypes(Parameters) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MIN(OccupancyPlansForWorkCenterTypesTurnovers.Period) AS PeriodStartDate_,
	|	MAX(OccupancyPlansForWorkCenterTypesTurnovers.Period) AS PeriodEndDate_1
	|FROM
	|	AccumulationRegister.OccupancyPlansForWorkCenterTypes.Turnovers(
	|			,
	|			,
	|			Record,
	|			Scenario = &Scenario
	|				AND (Status IN (&ScenarioStatuses)
	|					OR NOT &StatusSelectionIsUsed)
	|				AND (ProductionPlan = &ProductionPlan
	|					OR NOT &PlanSelectionIsUsed)) AS OccupancyPlansForWorkCenterTypesTurnovers";
	
	Query.SetParameter("Scenario", Parameters.Scenario);
	Query.SetParameter("ScenarioStatuses", Parameters.ScenarioStatuses);
	Query.SetParameter("StatusSelectionIsUsed", Parameters.StatusSelectionIsUsed <> False);
	Query.SetParameter("ProductionPlan", Parameters.ProductionPlan);
	Query.SetParameter("PlanSelectionIsUsed", Parameters.PlanSelectionIsUsed <> False);
	
	SelectionOfPeriodStartAndEndDates = Query.Execute().Select();
	
	If SelectionOfPeriodStartAndEndDates.Next() Then
		PeriodStartDate_ = SelectionOfPeriodStartAndEndDates.PeriodStartDate_;
		PeriodEndDate_1 = SelectionOfPeriodStartAndEndDates.PeriodEndDate_1;
	EndIf;
	
	If TypeOf(PeriodStartDate_) <> Type("Date") And TypeOf(PeriodEndDate_1) <> Type("Date") Then
		PeriodStartDate_ = '00010101';
		PeriodEndDate_1 = '00010101';
	EndIf;
	
	Result = New Structure;
	Result.Insert("PeriodStartDate_", PeriodStartDate_);
	Result.Insert("PeriodEndDate_1", PeriodEndDate_1);
	
	Return Result
	
EndFunction

// Called in the "append Result" handler when generating a report
// 
// Parameters:
// 	SettingsComposer - DataCompositionSettingsComposer -
// 	ResultDocument - SpreadsheetDocument - 
// 	StandardProcessing - Boolean -
Procedure PlannedNeedForTypesOfRCInLayoutOfResult(SettingsComposer, ResultDocument, StandardProcessing) Export
	
	FilterStatus                = GetSelection(SettingsComposer, "Status");
	FilterProductionPlan      = GetSelection(SettingsComposer, "ProductionPlan");
	ScenarioStatuses            = Undefined;
	ProductionPlan           = Undefined;
	StatusSelectionIsUsed = False;
	PlanSelectionIsUsed   = False;
	
	For Each SettingItem In SettingsComposer.UserSettings.Items Do
		If FilterStatus <> Undefined And SettingItem.UserSettingID = FilterStatus.UserSettingID Then
			If SettingItem.Use Then
				ScenarioStatuses = New Array;
				If SettingItem.ComparisonType = DataCompositionComparisonType.InList
					Or SettingItem.ComparisonType = DataCompositionComparisonType.InListByHierarchy Then
					For Each Item In SettingItem.RightValue Do
						ScenarioStatuses.Add(Item.Value);
					EndDo;
				ElsIf SettingItem.ComparisonType = DataCompositionComparisonType.Equal Then
					ScenarioStatuses.Add(SettingItem.RightValue);
				EndIf;
				
				If ValueIsFilled(ScenarioStatuses) Then
					StatusSelectionIsUsed = True;
				EndIf;
			EndIf;
		EndIf;
		If FilterProductionPlan <> Undefined And SettingItem.UserSettingID = FilterProductionPlan.UserSettingID Then
			If SettingItem.Use Then
				If SettingItem.ComparisonType = DataCompositionComparisonType.Equal Then
					PlanSelectionIsUsed = True;
					ProductionPlan = SettingItem.RightValue;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	Scenario = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings, "Scenario");
	Period = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings, "Period");
	
	If Period <> Undefined
	   And TypeOf(Period) = Type("DataCompositionSettingsParameterValue")
	   And Period.Use Then
		
		PeriodValue_ = Period.Value; // StandardPeriod - 
		ConfigurePeriodExtension(SettingsComposer.Settings, Scenario.Value.Periodicity, PeriodValue_.StartDate, PeriodValue_.EndDate);
		
	Else
		
		ParametersForCalculatingDeadlinePeriodsOfEmploymentPlansForRCTypes = New Structure();
		ParametersForCalculatingDeadlinePeriodsOfEmploymentPlansForRCTypes.Insert("Scenario", Scenario.Value);
		ParametersForCalculatingDeadlinePeriodsOfEmploymentPlansForRCTypes.Insert("ScenarioStatuses", ScenarioStatuses);
		ParametersForCalculatingDeadlinePeriodsOfEmploymentPlansForRCTypes.Insert("StatusSelectionIsUsed", StatusSelectionIsUsed);
		ParametersForCalculatingDeadlinePeriodsOfEmploymentPlansForRCTypes.Insert("ProductionPlan", ProductionPlan);
		ParametersForCalculatingDeadlinePeriodsOfEmploymentPlansForRCTypes.Insert("PlanSelectionIsUsed", PlanSelectionIsUsed);
		
		Result = GetDeadlinePeriodsOfEmploymentPlansForRCTypes(ParametersForCalculatingDeadlinePeriodsOfEmploymentPlansForRCTypes);
		
		InitialPeriod = Result.PeriodStartDate_;
		EndPeriod_1 = Result.PeriodEndDate_1;
		
		ConfigurePeriodExtension(SettingsComposer.Settings, Scenario.Value.Periodicity, InitialPeriod, EndPeriod_1);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Reports_ExecutionOfPlans

// LongDesc
// 
// Parameters:
// 	SettingsComposer - DataCompositionSettingsComposer - 
// 	Cancel - Boolean -
Procedure ExecutionOfPlansProcessingFillInChecks(SettingsComposer, Cancel) Export 
	
	Scenario = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings, "Scenario");
	If Scenario = Undefined
		Or Not ValueIsFilled(Scenario.Value) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường bắt buộc ""Kịch bản"".';
												|ru = 'Не заполнено обязательное поле ""Сценарий"".';
												|en = '""Scenario"" is required.'; fa = '""Scenario"" is required.';
												|it = 'Il campo obbligatorio ""Scenario"" non è stato compilato.';
												|pl = 'Pole obowiązkowe ""Scenariusz"" nie jest wypełnione.';
												|tr = '""Senaryo"" gerekli alanı doldurulmamış.'"), , , , Cancel);
	EndIf;
	
EndProcedure

// Called in the "append Result" handler when generating a report
//
Procedure ExecutionOfPlansInLayoutOfResult(DataCompositionSchema, SettingsComposer, ResultDocument, DetailsData, StandardProcessing) Export
	
	PermissibleDeviationsQuantity = DataCompositionClientServer.GetParameter(SettingsComposer, "AcceptableDeviationsPercentage");
	AcceptableDeviationsAmount = DataCompositionClientServer.GetParameter(SettingsComposer, "AcceptableDeviationsAmountPercentage");
	
	UserSettings = SettingsComposer.UserSettings; // DataCompositionUserSettings - 
	
	If TypeOf(SettingsComposer.Settings.Structure[0]) = Type("DataCompositionNestedObjectSettings") Then
		
		Filter = SettingsComposer.Settings.Structure[0].Settings.Filter;
		
	Else
		
		Filter = SettingsComposer.Settings.Filter;
		
	EndIf;
	
	ItemTheCustomSettings = UserSettings.Items.Find(Filter.UserSettingID);
	
	ItemArray = CommonClientServer.FindFilterItemsAndGroups(Filter, ,"Only acceptables variances quantities");
	If PermissibleDeviationsQuantity <> Undefined And ItemArray.Count() > 0 Then
		
		ItemArray[0].Use = PermissibleDeviationsQuantity.Use;
		
		ArrayOfCustomElements = CommonClientServer.FindFilterItemsAndGroups(
			ItemTheCustomSettings, ,"Only acceptables variances quantities");
		
		If ArrayOfCustomElements.Count() > 0 Then
			ArrayOfCustomElements[0].Use = PermissibleDeviationsQuantity.Use;
		EndIf;
		
	EndIf;
	
	If AcceptableDeviationsAmount <> Undefined Then
		
		AmountPlanningParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "PlanByAmount");
		
		If Not AmountPlanningParameter.Value Then
			
			AcceptableDeviationsAmount.Use = False;
			
		EndIf;
		
		ItemArray = CommonClientServer.FindFilterItemsAndGroups(
			Filter, ,"Only acceptables variances amounts");
		
		If ItemArray.Count() > 0 Then
			
			ItemArray[0].Use = AcceptableDeviationsAmount.Use;
			
			ArrayOfCustomElements = CommonClientServer.FindFilterItemsAndGroups(
				ItemTheCustomSettings, ,"Only acceptables variances amounts");
			
			If ArrayOfCustomElements.Count() > 0 Then
				ArrayOfCustomElements[0].Use = AcceptableDeviationsAmount.Use;
			EndIf;
			
		EndIf;
		
		ItemArray = CommonClientServer.FindFilterItemsAndGroups(
			Filter, ,"Only acceptables variances payments_1");
		
		If ItemArray.Count() > 0 Then
			
			ItemArray[0].Use = AcceptableDeviationsAmount.Use;
			
			ArrayOfCustomElements = CommonClientServer.FindFilterItemsAndGroups(
				ItemTheCustomSettings, ,"Only acceptables variances payments_1");
			
			If ArrayOfCustomElements.Count() > 0 Then
				ArrayOfCustomElements[0].Use = AcceptableDeviationsAmount.Use;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// This procedure overrides the data layout settings when generating the report transcript
//
Procedure OverrideReportDecryptionSettings(DataCompositionSchema, SettingsComposer, DetailsData) Export
	DispatcherDivisionField = New DataCompositionField("ProductionDispatcherBusinessUnit");
	DivisionField      = New DataCompositionField("Department");
	WarehouseField              = New DataCompositionField("Warehouse");
	PartnerField            = New DataCompositionField("Partner");
	ManagerField           = New DataCompositionField("Manager");
	DynamicPeriodField = New DataCompositionField("DynamicPeriod");
	
	DecryptionSettings = DetailsData.Settings; // DataCompositionSettings -
	
	If TypeOf(DecryptionSettings.Structure[0]) = Type("DataCompositionNestedObjectSettings") Then
		
		CollectionOfStructureElements = DetailsData.Settings.Structure[0].Settings.Structure;
		ReportSelections = DetailsData.Settings.Structure[0].Settings.Filter; // DataCompositionFilter
		
		ReportVariant = DataCompositionClientServer.GetParameter(
			DecryptionSettings.Structure[0].Settings, "ReportVariant");
		If ReportVariant <> Undefined Then
			IDOfReportVariant = ReportVariant.Value;
		Else
			IDOfReportVariant = DecryptionSettings.Structure[0].ObjectID;
		EndIf;
		
	Else
		
		CollectionOfStructureElements = DetailsData.Settings.Structure;
		ReportSelections = DetailsData.Settings.Filter; // DataCompositionFilter - 
		
		ReportVariant = DataCompositionClientServer.GetParameter(DecryptionSettings, "ReportVariant");
		If ReportVariant <> Undefined Then 
			IDOfReportVariant = ReportVariant.Value;
		Else
			Return;
		EndIf;
		
	EndIf;
	
	// Collectionelementsreferences -
	For Each ElementSelection In ReportSelections.Items Do
		
		If IDOfReportVariant = "ByBusinessUnits" Then
			If TypeOf(ElementSelection) = Type("DataCompositionFilterItem") Then
				If ElementSelection.LeftValue = DivisionField Then
					ElementSelectionDetail = ElementSelection; // DataCompositionFilterItem - 
					DetailField = DivisionField;
				EndIf;
			EndIf;
		ElsIf IDOfReportVariant = "ByDivisionDispatcher" Then
			If TypeOf(ElementSelection) = Type("DataCompositionFilterItem") Then
				If ElementSelection.LeftValue = DispatcherDivisionField Then
					ElementSelectionDetail = ElementSelection; // DataCompositionFilterItem - 
					DetailField = DispatcherDivisionField;
				EndIf;
			EndIf;
		ElsIf IDOfReportVariant = "ByWarehouses" Then // By storage locations
			If TypeOf(ElementSelection) = Type("DataCompositionFilterItem") Then
				If ElementSelection.LeftValue = WarehouseField Then
					ElementSelectionDetail = ElementSelection; // DataCompositionFilterItem - 
					DetailField = WarehouseField;
				EndIf;
			EndIf;
		ElsIf IDOfReportVariant = "ByCustomers" // By partners
		Or IDOfReportVariant = "BySuppliers"
		Or IDOfReportVariant = "ByPayments" Then
			If TypeOf(ElementSelection) = Type("DataCompositionFilterItem") Then
				If ElementSelection.LeftValue = PartnerField Then
					ElementSelectionDetail = ElementSelection; // DataCompositionFilterItem - 
					DetailField = PartnerField;
				EndIf;
			EndIf;
		ElsIf IDOfReportVariant = "ByManagers" Then
			If TypeOf(ElementSelection) = Type("DataCompositionFilterItem") Then
				If ElementSelection.LeftValue = ManagerField Then
					ElementSelectionDetail = ElementSelection; // DataCompositionFilterItem - 
					DetailField = ManagerField;
				EndIf;
			EndIf;
		EndIf;
		If TypeOf(ElementSelection) = Type("DataCompositionFilterItem") Then
			If ElementSelection.LeftValue = DynamicPeriodField Then
				SelectionElementDynamicPeriod = ElementSelection;
			EndIf;
		EndIf;
	EndDo;
	
	If IDOfReportVariant = "ByPayments" Then
		
		If SelectionElementDynamicPeriod <> Undefined And SelectionElementDynamicPeriod.Use Then
			
			OutputParameters = DetailsData.Settings.Structure[0].Settings.OutputParameters; //  DataCompositionOutputParameterValues - 
			SelectedFields   = DetailsData.Settings.Structure[0].Settings.Selection; // DataCompositionSelectedFields - 
			
			Parameter = New DataCompositionParameter("ResourcePlacement");
			ResourcePlacementParameter = OutputParameters.Items.Find(Parameter);
			ResourcePlacementParameter.Value = DataCompositionResourcesPlacement.Horizontally;
			
			Parameter = New DataCompositionParameter("VerticalOverallPlacement");
			VerticalLocationParameter = OutputParameters.Items.Find(Parameter);
			VerticalLocationParameter.Value = DataCompositionTotalPlacement.Begin;
			
			ShippingPlanField           = New DataCompositionField("Plans.Shipment");
			ShipmentFactField           = New DataCompositionField("Real.Shipment");
			ShipmentExecutionField     = New DataCompositionField("PlanExecution.Shipment");
			PaymentPlanField             = New DataCompositionField("Plans.Payment");
			PaymentFactField             = New DataCompositionField("Real.Payment");
			PaymentExecutionField       = New DataCompositionField("PlanExecution.Payment");
			
			ShippingPlanTotalField       = New DataCompositionField("Plans.ShippingTotal");
			ShipmentFactTotalField       = New DataCompositionField("Real.ShippingTotal");
			FieldShipmentExecutionTotal = New DataCompositionField("PlanExecution.ShippingTotal");
			PaymentPlanTotalField         = New DataCompositionField("Plans.PaymentTotal");
			PaymentFactTotalField         = New DataCompositionField("Real.PaymentTotal");
			PaymentExecutionTotalField   = New DataCompositionField("PlanExecution.PaymentTotal");
			
			For Each GroupOfSelectionFields In SelectedFields.Items Do
				
				If TypeOf(GroupOfSelectionFields) = Type("DataCompositionSelectedFieldGroup") Then
					
					For Each ComboBox In GroupOfSelectionFields.Items Do
						
						If TypeOf(ComboBox) = Type("DataCompositionSelectedField") Then
							If ComboBox.Field = ShippingPlanField Then
								ComboBox.Use = True;
							EndIf;
							If ComboBox.Field = ShipmentFactField Then
								ComboBox.Use = True;
							EndIf;
							If ComboBox.Field = ShipmentExecutionField Then
								ComboBox.Use = True;
							EndIf;
							If ComboBox.Field = PaymentPlanField Then
								ComboBox.Use = True;
							EndIf;
							If ComboBox.Field = PaymentFactField Then
								ComboBox.Use = True;
							EndIf;
							If ComboBox.Field = PaymentExecutionField Then
								ComboBox.Use = True;
							EndIf;
							If ComboBox.Field = ShippingPlanTotalField Then
								ComboBox.Use = False;
							EndIf;
							If ComboBox.Field = ShipmentFactTotalField Then
								ComboBox.Use = False;
							EndIf;
							If ComboBox.Field = FieldShipmentExecutionTotal Then
								ComboBox.Use = False;
							EndIf;
							If ComboBox.Field = PaymentPlanTotalField Then
								ComboBox.Use = False;
							EndIf;
							If ComboBox.Field = PaymentFactTotalField Then
								ComboBox.Use = False;
							EndIf;
							If ComboBox.Field = PaymentExecutionTotalField Then
								ComboBox.Use = False;
							EndIf;
						EndIf;
						
					EndDo;
				EndIf;
			EndDo;
			
		EndIf;
		
	EndIf;
	
	// The elements of the collection of the given -
	If ElementSelectionDetail <> Undefined
	And ElementSelectionDetail.Use Then
		
		// Deleting a standard grouping to replace it with a subordinate one by detail
		If TypeOf(CollectionOfStructureElements[0]) = Type("DataCompositionTable") Then
			
			CollectionOfStructureElements[0].Rows.Clear();
			GroupingDetails_ = CollectionOfStructureElements[0].Rows.Add(); // DataCompositionGroup - 
			
		Else
			
			CollectionOfStructureElements.Clear();
			GroupingDetails_ = CollectionOfStructureElements.Add(
				Type("DataCompositionGroup")); // Grouping of the compositionsreferences - 
			
		EndIf;
		
		RightFilterValue = ElementSelectionDetail.RightValue; // CatalogRef - 
		If RightFilterValue <> Undefined Then
			
			If TypeOf(RightFilterValue) = Type("ValueList") Then
				
				If RightFilterValue.Count() > 0 Then
					
					If RightFilterValue.Count() = 1
					And RightFilterValue[0].Value["Description"] = "" Then
						
						ReportSelections.Items.Delete(ElementSelectionDetail);
					Else
						
						// Redefining selection to the level of detail grouping
						ReplacingSelectionByDetail = GroupingDetails_.Filter.Items.Add(
							Type("DataCompositionFilterItem"));
						ReplacingSelectionByDetail.Use = True;
						ReplacingSelectionByDetail.ComparisonType = ElementSelectionDetail.ComparisonType;
						ReplacingSelectionByDetail.LeftValue = DetailField;
						ReplacingSelectionByDetail.RightValue = ElementSelectionDetail.RightValue;
						
						DimensionParameter = New DataCompositionParameter("FilterOutput");
						OutputDimensionParameter = GroupingDetails_.OutputParameters.Items.Find(DimensionParameter);
						OutputDimensionParameter.Value = DataCompositionTextOutputType.DontOutput;
						OutputDimensionParameter.Use = True;
						
						ReportSelections.Items.Delete(ElementSelectionDetail);
					EndIf;
					
				Else
					ReportSelections.Items.Delete(ElementSelectionDetail);
				EndIf;
				
			Else
				
				If Common.ObjectAttributeValue(RightFilterValue, "Description") <> "" Then
					
					// Redefining selection to the level of detail grouping
					ReplacingSelectionByDetail = GroupingDetails_.Filter.Items.Add(
						Type("DataCompositionFilterItem"));
					ReplacingSelectionByDetail.Use = True;
					ReplacingSelectionByDetail.ComparisonType = ElementSelectionDetail.ComparisonType;
					ReplacingSelectionByDetail.LeftValue = DetailField;
					ReplacingSelectionByDetail.RightValue = ElementSelectionDetail.RightValue;
					
					DimensionParameter = New DataCompositionParameter("FilterOutput");
					OutputDimensionParameter = GroupingDetails_.OutputParameters.Items.Find(DimensionParameter);
					OutputDimensionParameter.Value = DataCompositionTextOutputType.DontOutput;
					OutputDimensionParameter.Use = True;
					
					ReportSelections.Items.Delete(ElementSelectionDetail);
					
				Else
					ReportSelections.Items.Delete(ElementSelectionDetail);
				EndIf;
				
			EndIf;
			
		EndIf;
		
		GroupingDetails_.Use = True;
		GroupingDetails_.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
		
		DetailDimensionField = GroupingDetails_.GroupFields.Items.Add(
			Type("DataCompositionGroupField"));
		DetailDimensionField.Use = True;
		DetailDimensionField.Field = DetailField;
		
		If TypeOf(GroupingDetails_) = Type("DataCompositionTableGroup") Then
			LoggerGrouping = GroupingDetails_.Structure.Add();
		Else
			LoggerGrouping = GroupingDetails_.Structure.Add(
				Type("DataCompositionGroup"));
		EndIf;
		LoggerGrouping.Name = "Details";
		LoggerGrouping.Use = True;
		LoggerGrouping.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
		
		LoggerDimensionField = LoggerGrouping.GroupFields.Items.Add(
			Type("DataCompositionGroupField"));
		LoggerDimensionField.Use = True;
		LoggerDimensionField.Field = New DataCompositionField("Recorder");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormationOfOrdersAccordingToPlans

// Performs a proportional distribution of the amount according
// to the specified distribution coefficients.
//
// Parameters:
//  AmountToDistribute - Number - the amount to be distributed;
//  Array of coefficients-Array-distribution coefficients;
//  MultiplicityOfGoods - Number - multiplicity of the distributed quantity.
//
// Returns:
//  Array - an array of dimension equal to the array of coefficients contains
//           sums in accordance with the weight of the coefficient (from the array of coefficients).
//           If the distribution failed (sum = 0, number of coefficients = 0,
//           or total weight of coefficients = 0), then the value is returned Undefined.
//
Function DistributeQuantityProportionallyToCoefficientsAndMultiplicityOfString(Val AmountToDistribute, PackagingFactor, Coefficients, MultiplicityOfGoods)
	
	If Coefficients.Count() = 0 Or Not ValueIsFilled(AmountToDistribute) Or MultiplicityOfGoods = 0 Then
		Return Undefined;
	EndIf;
	
	MaxCoefficientIndex = 0;
	MaxCoefficient = 0;
	DistributedAmount = 0;
	CoefficientsSum  = 0;
	
	For IndexOf = 0 To Coefficients.Count() - 1 Do
		ZoomRatio = Coefficients[IndexOf];
		
		AbsoluteValueOfCoefficient = ?(ZoomRatio > 0, ZoomRatio, -ZoomRatio);
		If MaxCoefficient < AbsoluteValueOfCoefficient Then
			MaxCoefficient = AbsoluteValueOfCoefficient;
			MaxCoefficientIndex = IndexOf;
		EndIf;
		
		CoefficientsSum = CoefficientsSum + ZoomRatio;
	EndDo;
	
	If CoefficientsSum = 0 Then
		Return Undefined;
	EndIf;
	
	Result = New Array(Coefficients.Count());
	
	For IndexOf = 0 To Coefficients.Count() - 2 Do
		If DistributedAmount>= AmountToDistribute Then
			Break;
		EndIf;
		Result[IndexOf] = Round((AmountToDistribute-DistributedAmount) * Coefficients[IndexOf] / CoefficientsSum, 3, 1);
		NumberOfMultiplePackages = Result[IndexOf] * PackagingFactor / MultiplicityOfGoods;
		If NumberOfMultiplePackages - Int(NumberOfMultiplePackages) > 0 Then
			Result[IndexOf] = (Int(NumberOfMultiplePackages) + 1) * MultiplicityOfGoods / PackagingFactor;
		EndIf;
		DistributedAmount = DistributedAmount + Result[IndexOf];
		CoefficientsSum = CoefficientsSum - Coefficients[IndexOf];
	EndDo;
	
	// The last coefficient is calculated taking into account the previously calculated ones.
	IndexOfLastCoefficient = Coefficients.Count() -1;
	Result[IndexOfLastCoefficient] = AmountToDistribute - DistributedAmount;
	
	Return Result;
	
EndFunction

Procedure MigrateOrDistributeOnServer(DistributionParameters, Val SelectedRows, GenerationOfOrders) Export
	
	If DistributionParameters = Undefined Then
		Return;
	EndIf;
	
	DistributionParameters.Insert("WeekDayNumber", PlanningClientServer.WeekDayNumber(DistributionParameters.WeekDay));
	Periodicity = DistributionParameters.Periodicity;
	
	If DistributionParameters.PlanningType = "AssemblyProductionPlanning" Then
		PeriodColumnName = "DateOfProduction";
		ColumnNameOrderDate = "";
	ElsIf DistributionParameters.PlanningType = "DisassemblyProductionPlanning" Then
		PeriodColumnName = "OrderDate";
		ColumnNameOrderDate = "";
	ElsIf DistributionParameters.PlanningType = "PurchasePlanning" Then
		PeriodColumnName = "DateOfReceipt";
		ColumnNameOrderDate = "";
	ElsIf DistributionParameters.PlanningType = "PlanningAssemblyDisassembly" Then
		PeriodColumnName = "AssemblyPeriodStart";
		ColumnNameOrderDate = "OrderDate";
	ElsIf DistributionParameters.PlanningType = "PlanningTransferOfMaterialsToProduction" Then
		PeriodColumnName = "DemandPeriodStart";
		ColumnNameOrderDate = "OrderDate";
	EndIf;
	
	CachedSettings = New Map;
	
	If DistributionParameters.Operation = "Allocation" Then
		DistributionShares = New ValueTable;
		DistributionShares.Columns.Add("Period", New TypeDescription("Number"));
		DistributionShares.Columns.Add("Share", New TypeDescription("Number"));
		DistributionShares.Indexes.Add("Period");
		
		CurrentPeriod = 1;
		For Each Share In DistributionParameters.Shares Do
		
			NewRow = DistributionShares.Add();
			NewRow.Period = CurrentPeriod;
			NewRow.Share = Share;
			
			CurrentPeriod = CurrentPeriod + 1;
		EndDo;
		
		AmountOfShares = DistributionShares.Total("Share");
		
		Coefficients = DistributionShares.UnloadColumn("Share");
		
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	If DistributionParameters.PlanningType = "PurchasePlanning" Then
		StructureOfRecalculationOfAmount = New Structure;
		StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
		
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	LinesForBatchProcessing = New Array;
	
	For Each CurrentRow In SelectedRows Do
		TSRow = GenerationOfOrders.FindByID(CurrentRow);
		
		If DistributionParameters.SelectToOrder Then
			TSRow.SelectToOrder = True;
		EndIf; 
		
		If DistributionParameters.Operation = "Transfer" Then
		
			If DistributionParameters.TransferOption = "ToNumber" Then
			
				If Periodicity = Enums.Periodicity.Month And DistributionParameters.DayNumber = 31 Then
				
					TSRow[PeriodColumnName] =  EndOfMonth(TSRow[PeriodColumnName]);
				
				Else
					PeriodEnding = PlanningClientServerCached.CalculatePeriodEndDate(TSRow[PeriodColumnName], Periodicity);
					ReplacementDate = BegOfDay(PlanningClientServerCached.CalculateStartDateOfPeriod(TSRow[PeriodColumnName], 
						Periodicity))-1 + DistributionParameters.DayNumber * 86400;
					If PeriodEnding <= ReplacementDate Then
					
						TSRow[PeriodColumnName] =  PeriodEnding;
					
					Else
					
						TSRow[PeriodColumnName] =  ReplacementDate;
					
					EndIf;
				EndIf;
			
			ElsIf DistributionParameters.TransferOption = "OnFirstDayOfWeek" Then
				
				BeginOfPeriod = PlanningClientServerCached.CalculateStartDateOfPeriod(TSRow[PeriodColumnName], Periodicity);
				CurDayOfWeek = WeekDay(BeginOfPeriod);
				
				If CurDayOfWeek <= DistributionParameters.WeekDayNumber Then
					TSRow[PeriodColumnName] =  BegOfWeek(BeginOfPeriod) + (DistributionParameters.WeekDayNumber -1) * 86400;
				Else
					TSRow[PeriodColumnName] =  BegOfDay(EndOfWeek(BeginOfPeriod)) + DistributionParameters.WeekDayNumber * 86400;
				EndIf;
				
			ElsIf DistributionParameters.TransferOption = "OnLastDayOfWeek" Then
				
				PeriodEnding = PlanningClientServerCached.CalculatePeriodEndDate(TSRow[PeriodColumnName], Periodicity);
				CurDayOfWeek = WeekDay(PeriodEnding);
				
				If CurDayOfWeek >= DistributionParameters.WeekDayNumber Then
					TSRow[PeriodColumnName] =  BegOfWeek(PeriodEnding) + (DistributionParameters.WeekDayNumber -1) * 86400;
				Else
					TSRow[PeriodColumnName] =  BegOfDay(PeriodEnding) - (7 - DistributionParameters.WeekDayNumber + CurDayOfWeek) * 86400;
				EndIf;
			EndIf; 
			
			If ValueIsFilled(ColumnNameOrderDate) Then
				TSRow[ColumnNameOrderDate] = TSRow[PeriodColumnName] - TSRow.DaysBeforeOrdering*86400;
			EndIf;
			
		ElsIf DistributionParameters.Operation = "Allocation" Then
			
			If TSRow.Count = 0 Then
				Continue;
			EndIf;
			
			BeginOfPeriod = PlanningClientServerCached.CalculateStartDateOfPeriod(TSRow[PeriodColumnName], Periodicity);
			Settings = CachedSettings.Get(BeginOfPeriod);
			If Settings = Undefined Then
				
				PeriodEnding = PlanningClientServerCached.CalculatePeriodEndDate(TSRow[PeriodColumnName], Periodicity);
				Number_DaysInPeriod = Int((PeriodEnding + 1 - BeginOfPeriod)/86400);
				
				If Number_DaysInPeriod >= DistributionParameters.NumberOfPeriods Then
					NumberOfPeriods = DistributionParameters.NumberOfPeriods;
				Else
					NumberOfPeriods = Number_DaysInPeriod;
				EndIf;
				
				If DistributionParameters.DateAllocationOption = "ByWeeks" Then
					CurDayOfWeek = WeekDay(BeginOfPeriod);
					If CurDayOfWeek <= DistributionParameters.WeekDayNumber Then
						FirstPeriod = BeginOfPeriod  + (DistributionParameters.WeekDayNumber - CurDayOfWeek) * 86400;
					Else
						FirstPeriod = EndOfWeek(BeginOfPeriod) + 1 + (DistributionParameters.WeekDayNumber -1) * 86400;
					EndIf;
				Else
					FirstPeriod = BeginOfPeriod;
				EndIf;
				
				If DistributionParameters.DateAllocationOption = "ByWeeks" Then
					
					CurDayOfWeek = WeekDay(PeriodEnding);
					If CurDayOfWeek >= DistributionParameters.WeekDayNumber Then
						LastPeriod = BegOfWeek(PeriodEnding) + (DistributionParameters.WeekDayNumber -1) * 86400;
					Else
						LastPeriod = BegOfWeek(PeriodEnding)- (8 - DistributionParameters.WeekDayNumber) * 86400;
					EndIf;
					
					NumberOfPeriods = Int((LastPeriod - FirstPeriod) / 604800) + 1;
					
				EndIf;
				
				AmountOfShares = 0;
				Coefficients = New Array;
				For Each ShareLine In DistributionShares Do
					
					If ShareLine.Period > NumberOfPeriods Then
						Continue;
					EndIf; 
					
					Coefficients.Add(ShareLine.Share);
					AmountOfShares = AmountOfShares + ShareLine.Share;
					
				EndDo;
				
				SettingsStructure = New Structure();
				SettingsStructure.Insert("NumberOfPeriods", NumberOfPeriods);
				SettingsStructure.Insert("Coefficients", Coefficients);
				SettingsStructure.Insert("FirstPeriod", FirstPeriod);
				SettingsStructure.Insert("Number_DaysInPeriod", Number_DaysInPeriod);
				SettingsStructure.Insert("AmountOfShares", AmountOfShares);
				
				CachedSettings.Insert(BeginOfPeriod, SettingsStructure);
				
			Else
				
				NumberOfPeriods     = Settings.NumberOfPeriods;
				Coefficients           = Settings.Coefficients;
				FirstPeriod           = Settings.FirstPeriod;
				Number_DaysInPeriod = Settings.Number_DaysInPeriod;
				AmountOfShares             = Settings.AmountOfShares;
			
			EndIf; 
			
			If NumberOfPeriods = 1 Or AmountOfShares = 0 Then
				TSRow[PeriodColumnName] = FirstPeriod;
				Continue;
			EndIf;
			
			If DistributionParameters.PlanningType = "AssemblyProductionPlanning"
				Or DistributionParameters.PlanningType = "DisassemblyProductionPlanning" Then
				PackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(TSRow.Package, TSRow.Products);
				NumberOfPackages = DistributeQuantityProportionallyToCoefficientsAndMultiplicityOfString(
					TSRow.NumberOfPackages,
					PackagingFactor,
					Coefficients,
					TSRow.ProductsQuantityInBOM);
			ElsIf DistributionParameters.PlanningType = "PlanningAssemblyDisassembly" Then
				PackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(TSRow.Package, TSRow.Products);
				NumberOfPackages = DistributeQuantityProportionallyToCoefficientsAndMultiplicityOfString(
					TSRow.NumberOfPackages,
					PackagingFactor,
					Coefficients,
					TSRow.NumberOfKitsInProductKitConfiguration);
				ElsIf DistributionParameters.PlanningType = "PlanningTransferOfMaterialsToProduction"
					Or DistributionParameters.PlanningType = "PurchasePlanning" Then
				NumberOfPackages = CommonClientServer.DistributeAmountInProportionToCoefficients(
					TSRow.NumberOfPackages, 
					Coefficients,
					3 + DistributionParameters.RoundingPrecision);
			EndIf;
			
			If DistributionParameters.PlanningType = "AssemblyProductionPlanning"
				And Not DistributionParameters.DateAllocationOption = "ByWeeks" Then
				TSRow[PeriodColumnName] = PeriodEnding;
				LastPeriod = NumberOfPackages.Count()-1;
				NumberOfPackages.Insert(0, NumberOfPackages[LastPeriod]);
				NumberOfPackages.Delete(LastPeriod + 1);
			Else
				TSRow[PeriodColumnName] = FirstPeriod;
			EndIf;
			
			StringTSPeriod = TSRow.Period; // StandardPeriod -
			If DistributionParameters.PlanningType = "AssemblyProductionPlanning" Then
				StringTSPeriod.StartDate = BeginOfPeriod;
				StringTSPeriod.EndDate = TSRow[PeriodColumnName];
			ElsIf DistributionParameters.PlanningType = "DisassemblyProductionPlanning" Then
				StringTSPeriod.StartDate = BeginOfPeriod;
				StringTSPeriod.EndDate = PeriodEnding;
			Else
				StringTSPeriod.StartDate = TSRow[PeriodColumnName];
				StringTSPeriod.EndDate = PeriodEnding;
			EndIf;
			
			If NumberOfPackages = Undefined Then
				Continue;
			EndIf;

			TSRow.NumberOfPackages = NumberOfPackages[0];
			
			// Calculation of the order date and start of assembly 
			If ValueIsFilled(ColumnNameOrderDate) Then
				TSRow[ColumnNameOrderDate] = TSRow[PeriodColumnName] - TSRow.DaysBeforeOrdering*86400;
			EndIf;
			If DistributionParameters.PlanningType = "PlanningAssemblyDisassembly" Then
				TSRow.AssemblyStartDate = TSRow.AssemblyPeriodStart - TSRow.AssemblyDisassemblyDurationDays*86400;
			EndIf;
			
			LinesForBatchProcessing.Add(TSRow);
			
			For PeriodNumber = 2 To NumberOfPeriods Do
				
				If NumberOfPackages[PeriodNumber-1] = Undefined
					Or NumberOfPackages[PeriodNumber-1] <= 0 Then
					Continue;
				EndIf;
				
				NewRow = GenerationOfOrders.Add();
				FillPropertyValues(NewRow, TSRow);
				NewRow.Period = New StandardPeriod;
				NewRow.NumberOfPackages = NumberOfPackages[PeriodNumber-1];
				
				If DistributionParameters.DateAllocationOption = "ByHalfYearPeriods" Then
					NewRow[PeriodColumnName] = AddMonth(BeginOfPeriod, 6 * (PeriodNumber-1));
				ElsIf DistributionParameters.DateAllocationOption = "ByQuarters" Then
					NewRow[PeriodColumnName] = AddMonth(BeginOfPeriod, 3 * (PeriodNumber-1));
				ElsIf DistributionParameters.DateAllocationOption = "ByMonths" Then
					NewRow[PeriodColumnName] = AddMonth(BeginOfPeriod, PeriodNumber-1);
				ElsIf DistributionParameters.DateAllocationOption = "ByWeeks" Then
					NewRow[PeriodColumnName] = FirstPeriod + 604800 * (PeriodNumber-1);
				ElsIf DistributionParameters.DateAllocationOption = "ByTenDayPeriods" Then
					BeginningOfCurMonth = AddMonth(BeginOfPeriod, Int((PeriodNumber-1)/3));
					NewRow[PeriodColumnName] = BeginningOfCurMonth + 864000 * ((PeriodNumber-1)%3);
				ElsIf DistributionParameters.DateAllocationOption = "ByPeriods" Then
					NewRow[PeriodColumnName] = BeginOfPeriod + 86400 * Int(Number_DaysInPeriod / NumberOfPeriods * (PeriodNumber-1));
				EndIf;
				
				NewRow[PeriodColumnName] = Min(NewRow[PeriodColumnName], PeriodEnding);
				NewLinePeriod = NewRow.Period; // StandardPeriod -
				If DistributionParameters.PlanningType = "AssemblyProductionPlanning" Then
					NewLinePeriod.StartDate = BeginOfPeriod;
					NewLinePeriod.EndDate = NewRow[PeriodColumnName];
				ElsIf DistributionParameters.PlanningType = "DisassemblyProductionPlanning" Then
					NewLinePeriod.StartDate = BeginOfPeriod;
					NewLinePeriod.EndDate = PeriodEnding;
				Else
					NewLinePeriod.StartDate = NewRow[PeriodColumnName];
					NewLinePeriod.EndDate = PeriodEnding;
				EndIf;
				
				// Calculation of the order date and start of assembly 
				If ValueIsFilled(ColumnNameOrderDate) Then
					NewRow[ColumnNameOrderDate] = NewRow[PeriodColumnName] - NewRow.DaysBeforeOrdering*86400;
				EndIf;
				If DistributionParameters.PlanningType = "PlanningAssemblyDisassembly" Then
					NewRow.AssemblyStartDate = NewRow.AssemblyPeriodStart - NewRow.AssemblyDisassemblyDurationDays*86400;
				EndIf;
			
				LinesForBatchProcessing.Add(NewRow);
				
			EndDo; 
		EndIf;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		LinesForBatchProcessing,
		StructureOfActions,
		GenerationOfOrders,
		CachedValues);
		
	For Each String In LinesForBatchProcessing Do
			
		If DistributionParameters.PlanningType = "PurchasePlanning" Then
			String.TotalWeight = String.Count * String.Weight;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region CrossTableProcedures

// The procedure checks whether the warehouse is filled in in the document
//
// Parameters:
//  Object            - DocumentObject - document to check whether the warehouse is filled in
//  Cancel             - Boolean - True if there are fill-in errors
//  CheckParameters - Structure - Check parameters: Imatch and Predstavlenie.
//
Procedure CheckWhetherWarehouseIsFull(Object, Cancel, CheckParameters)

	TSName           = CheckParameters.TSName;
	PresentationOfTS = CheckParameters.PresentationOfTS;
	MessageTemplate = NStr("vi = 'Chưa điền cột ""Kho bãi"" vào dòng %1 trong danh sách ""%2""';
							|ru = 'Не заполнена колонка ""Склад"" в строке %1 списка ""%2""';
							|en = 'Column ""Warehouse"" in line %1 of list ""%2"" is not filled in'; fa = 'Column ""Warehouse"" in line %1 of list ""%2"" is not filled in';
							|it = 'Colonna ""Magazzino"" nella riga %1 dell''elenco ""%2 non compilata';
							|pl = 'Nie wypełniono kolumny ""Magazyn"" w wierszu %1 listy ""%2""';
							|tr = '""%2"" listesinin %1 satırında ""Ambar"" sütunu doldurulmadı'");
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TS.LineNumber,
	|	TS.Products,
	|	TS.Warehouse
	|INTO TS
	|FROM
	|	&TS AS TS
	|WHERE
	|	TS.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TS.LineNumber
	|FROM
	|	TS AS TS
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON TS.Products = CatProducts.Ref
	|WHERE
	|	CatProducts.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))";
	
	Query.SetParameter("TS", Object[TSName].Unload(, "LineNumber, Products, Warehouse"));
	
	QueryResult = Query.Execute();

	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate, 
			SelectionDetailRecords.LineNumber, 
			PresentationOfTS);
		CommonClientServer.MessageToUser(
			MessageText,
			Object,
			CommonClientServer.PathToTabularSection(TSName, SelectionDetailRecords.LineNumber, "Warehouse"),
			,
			Cancel);
	EndDo;

EndProcedure

#EndRegion

#Region ObjectEventProcedures

Procedure OnReadCreateAtServer(Form)
	
	Form.ShowNumberOfPeriod = Common.ObjectAttributeValue(Form.Object.Scenario, "ShowNumberOfPeriod");
	
	CreatePeriodTable(Form, "TimeIntervals");
	
	CreateChangeVerificationDetails(
		Form, 
		"DetailsBeforeChange", 
		"Scenario, Currency, PlanProfile, Periodicity, BeginOfPeriod, PeriodEnding");
	
	
EndProcedure

#EndRegion

#Region SourcePlanningProcedures

// The function converts data by rule and returns the result by source or group of sources.
//
// Parameters:
//  PlanType                         - EnumRef.TypesOfPlans - Type of plan, such as purchase Plan, sales Plan, etc.
//  RulesForFillingInFoundRows - Array of ValueTableRow - Content:
//                                      * DataCompositionSettingsComposer - DataCompositionSettingsComposer -
//                                      * LineNumber - Number - 
//  ConversionParameters          - Structure - conversion parameters
//  UserSettings        - DataCompositionUserSettings - user settings for the plan document
//  AdditionalParameters          - Structure - Additional parameters used when retrieving data from sources.
//
// Returns:
//   ValueTable   - A table of summary data converted according to the rules from a source or a group of sources.
//
Function ConvertData_(Val PlanType, RulesForFillingInFoundRows, ConversionParameters, 
	UserSettings = Undefined, AdditionalParameters = Undefined, FillInAssignmentInTabularForm = True)
	
	DataCompositionSchema = GetDataConversionScheme(PlanType,,FillInAssignmentInTabularForm);
	
	// Adding predefined parameters and setting values.
	NewParameter1 = DataCompositionSchema.Parameters.Add();
	NewParameter1.Name = "ZoomRatio";
	NewParameter1.ValueType = New TypeDescription("Number");
	NewParameter1.Value = 1;
	NewParameter1.UseRestriction = False;
	
	// Adding parameters from additional parameters and setting values.
	If AdditionalParameters <> Undefined And AdditionalParameters.Property("DataParameters") Then
		
		For Each Parameter In AdditionalParameters.DataParameters Do
			
			NewParameter1 = DataCompositionSchema.Parameters.Find(Parameter.Key);
			
			If NewParameter1 = Undefined Then
				
				NewParameter1 = DataCompositionSchema.Parameters.Add();
				NewParameter1.Name = Parameter.Key;
				NewParameter1.UseRestriction = False;

			EndIf;
			
			NewParameter1.Value = Parameter.Value;
			
		EndDo;
		
	EndIf;
	
	DataSetAssociation = DataCompositionSchema.DataSets.Union; // DataCompositionSchemaDataSetUnion - 
	DataSetJoining = DataCompositionSchema.DataSets.Find("Joining");
	ConnectionsOfSets = New Structure;
	
	If ConversionParameters.Attach = True Then
		RowCoefficient_ = "";
	Else
		RowCoefficient_ = " * &ZoomRatio";
	EndIf; 
	For Each TotalField In DataCompositionSchema.TotalFields Do
		
		If TotalField.DataPath <> "Count" Then
			Continue;
		EndIf; 
		
		If ConversionParameters.TransformationOption = Enums.ConversionOptions.Addition Then
			
			TotalField.Expression = "Sum("+TotalField.DataPath+")" + RowCoefficient_;
			
		ElsIf ConversionParameters.TransformationOption = Enums.ConversionOptions.Max Then
			
			TotalField.Expression = "Max("+TotalField.DataPath+")" + RowCoefficient_;
			
		ElsIf ConversionParameters.TransformationOption = Enums.ConversionOptions.AVG Then
			
			TotalField.Expression = "AVG("+TotalField.DataPath+")" + RowCoefficient_;
			
		ElsIf ConversionParameters.TransformationOption = Enums.ConversionOptions.Min Then
			
			TotalField.Expression = "Min("+TotalField.DataPath+")" + RowCoefficient_;
			
		EndIf;
	EndDo; 
	
	DataSets = New Structure;
	JoiningFields = New Array; // Fields of the join set to be removed from the join set
	
	NumberOfDataSetsJoining = 0;
	For Each FoundRow In RulesForFillingInFoundRows Do
		// Defining attachment sets only for the top level of the rule tree
		If FoundRow.Attach = True And FoundRow.RowNumberParent = 0 Then
			NumberOfDataSetsJoining = NumberOfDataSetsJoining + 1;
			
			// Redefining the fields to be taken from the set
			If FoundRow.DataCompositionSettingsComposer.Settings.Structure.Count() = 0 Then
				SelectionAvailableFields = FoundRow.DataCompositionSettingsComposer.Settings.SelectionAvailableFields.Items;
			Else
				SelectionAvailableFields = FoundRow.DataCompositionSettingsComposer.Settings.Structure[0].Selection.SelectionAvailableFields.Items;
			EndIf;
			For Each SettingItem In FoundRow.DataCompositionSettingsComposer.UserSettings.Items Do 
				If TypeOf(SettingItem) = Type("DataCompositionSelectedFields") Then
					SelectionAvailableFields = SettingItem.Items;
					Break;
				EndIf;
			EndDo;
			For Each Field In SelectionAvailableFields Do
				If TypeOf(Field) = Type("DataCompositionSelectedField") And Not Field.Use Then
					Continue;
				EndIf; 
				If JoiningFields.Find(String(Field.Field)) = Undefined Then
					JoiningFields.Add(String(Field.Field));
				EndIf;
			EndDo;
		Else
			FoundRow.Attach = False;
		EndIf;
	EndDo;
	If NumberOfDataSetsJoining = 0 And DataSetJoining <> Undefined Then
		
		// We add fields from the attachment set so that it is possible to select all with one set.
		For Each Field In DataSetJoining.Items.DataSet.Fields Do
			If DataSetAssociation.Items.DataSet.Fields.Find(Field.DataPath) = Undefined Then
				DataSetField = DataSetAssociation.Items.DataSet.Fields.Add(TypeOf(Field));
				FillPropertyValues(DataSetField, Field);
			EndIf; 
		EndDo;
		
		DataSetJoining.Items.Delete(DataSetJoining.Items.DataSet);
		DataCompositionSchema.DataSets.Delete(DataSetJoining);
		
	Else
		// Removing fields from the union set - to take them from joining
		For Each Field In JoiningFields Do
			
			If StrFind(Field, "Count") Then
				Continue;
			EndIf;
			
			FoundField = DataSetAssociation.Items.DataSet.Fields.Find(Field);
			If FoundField <> Undefined Then
				DataSetAssociation.Items.DataSet.Fields.Delete(FoundField);
			EndIf;
			
		EndDo;
	EndIf; 
		
	// Adding datasets for each source dataset.
	For Each FoundRow In RulesForFillingInFoundRows Do
		
		DataSetKey = "DataSet" + Format(FoundRow.LineNumber, "NG=0");
		DataSets.Insert(DataSetKey, FoundRow.DataSet);
		
		// Adding a dataset.
		If FoundRow.Attach = True And DataSetJoining <> Undefined Then
			DatasetObject = DataSetJoining.Items.Add(Type("DataCompositionSchemaDataSetObject"));
			DatasetObject.Name = DataSetKey;
			DatasetObject.ObjectName = DataSetKey;
			DatasetObject.DataSource = "DataSource";
			
			// Adding a grouping
			If FoundRow.DataCompositionSettingsComposer.Settings.Structure.Count() = 0 Then
				GroupFieldsCollection = FoundRow.DataCompositionSettingsComposer.Settings.GroupAvailableFields.Items;
			Else
				GroupFieldsCollection = FoundRow.DataCompositionSettingsComposer.Settings.Structure[0].GroupFields.Items;
			EndIf;
			
			For Each GroupingField In GroupFieldsCollection Do
			
				If TypeOf(GroupingField) = Type("DataCompositionGroupField") And Not GroupingField.Use
					Or DataSetAssociation.Items.DataSet.Fields.Find(GroupingField.Field) = Undefined Then
					Continue;
				EndIf;
				ConnectionsOfSets.Insert(String(GroupingField.Field), String(GroupingField.Field));
				
			EndDo;
			
			If FoundRow.DataCompositionSettingsComposer.Settings.Structure.Count() = 0 Then
				SelectionAvailableFields = FoundRow.DataCompositionSettingsComposer.Settings.SelectionAvailableFields.Items;
			Else
				SelectionAvailableFields = FoundRow.DataCompositionSettingsComposer.Settings.Structure[0].Selection.SelectionAvailableFields.Items;
			EndIf;
			For Each Field In SelectionAvailableFields Do
				If Field.Folder Then
					Continue;
				EndIf; 
				DataSetField = DatasetObject.Fields.Add(Type("DataCompositionSchemaDataSetField"));
				DataSetField.ValueType = Field.ValueType;
				DataSetField.Field = String(Field.Field);
				DataSetField.Title = String(Field.Field);
				DataSetField.DataPath = String(Field.Field);
				
				If DataSetJoining.Fields.Find(Field.Field) = Undefined Then
					DataSetField = DataSetJoining.Fields.Add(Type("DataCompositionSchemaDataSetField"));
					DataSetField.ValueType = Field.ValueType;
					DataSetField.Field = String(Field.Field);
					DataSetField.Title = String(Field.Field);
					DataSetField.DataPath = String(Field.Field);
				EndIf;
			EndDo;
			 
		Else
			DatasetObject = DataSetAssociation.Items.Add(Type("DataCompositionSchemaDataSetObject"));
			DatasetObject.Name = DataSetKey;
			DatasetObject.ObjectName = DataSetKey;
			DatasetObject.DataSource = "DataSource";
			
			For Each Field In DataSetAssociation.Items.DataSet.Fields Do
				DataSetField = DatasetObject.Fields.Add(TypeOf(Field));
				FillPropertyValues(DataSetField, Field);
			EndDo;
		EndIf;
				
	EndDo;
	
	If NumberOfDataSetsJoining > 0 And DataSetJoining <> Undefined Then
		For Each LinkItem In ConnectionsOfSets Do
			If DataSetAssociation.Items.DataSet.Fields.Find(LinkItem.Value) = Undefined Then
				Continue;
			EndIf;
			NewDataLink = DataCompositionSchema.DataSetLinks.Add();
			NewDataLink.SourceDataSet = "Union";
			NewDataLink.DestinationDataSet = "Joining";
			NewDataLink.SourceExpression = LinkItem.Value;
			NewDataLink.DestinationExpression = LinkItem.Key;
						
		EndDo;
				
		DataSetJoining.Items.Delete(DataSetJoining.Items.DataSet);
	EndIf;
	
	DataSetAssociation.Items.Delete(DataSetAssociation.Items.DataSet);
	
	// Loading Settings
	DataCompositionSettingsComposer = New DataCompositionSettingsComposer;
	DataCompositionSettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	DataCompositionSettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	// Loading settings from additional parameters
	If UserSettings <> Undefined Then
		
		DataCompositionSettingsComposer.LoadUserSettings(UserSettings);
		
	EndIf;
	
	// Enabling the use of data parameters
	For Each DataParameter In DataCompositionSettingsComposer.Settings.DataParameters.Items Do
		
		DataParameter.Use = True;
		
	EndDo;
	
	// Disabling the output of total totals
	DataCompositionSettingsComposer.Settings.OutputParameters.SetParameterValue("HorizontalOverallPlacement", DataCompositionTotalPlacement.None);
	DataCompositionSettingsComposer.Settings.OutputParameters.SetParameterValue("VerticalOverallPlacement", DataCompositionTotalPlacement.None);
	
	// Adding a resource
	If DataCompositionSettingsComposer.Settings.Selection.Items.Count() = 0 Then
		For Each Item In DataCompositionSettingsComposer.Settings.SelectionAvailableFields.Items Do
			
			If Item.Resource And Not Item.Folder Then
				ElementFound = False;
				For Each ChoiceItem In DataCompositionSettingsComposer.Settings.Selection.Items Do
					If ChoiceItem.Field = Item.Field Then
						ElementFound = True;
						Break;
					EndIf; 
				EndDo;
				If ElementFound Then
					Continue;
				EndIf; 
				SelectedField = DataCompositionSettingsComposer.Settings.Selection.Items.Add(Type("DataCompositionSelectedField"));
				SelectedField.Use = True;
				SelectedField.Field = Item.Field;
				
			EndIf;
			
		EndDo;
	EndIf; 
	
	// Adding a grouping
	If DataCompositionSettingsComposer.Settings.Structure.Count() = 0 Then
		DataCompositionGroup = DataCompositionSettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
		DataCompositionGroup.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
		// Adding Grouping fields
		For Each Item In DataCompositionSettingsComposer.Settings.GroupAvailableFields.Items Do
			
			If Not Item.Resource Then
								
				SelectedField = DataCompositionGroup.GroupFields.Items.Add(Type("DataCompositionGroupField"));
				SelectedField.Use = True;
				SelectedField.Field = Item.Field;
				
			EndIf;
			
		EndDo;
	EndIf;
	
	// The table of values in which the result will be received
	Result = New ValueTable;
	SKDDataSetsAssociation = DataCompositionSchema.DataSets.Union; // DataCompositionTemplateDataSetUnion
	If SKDDataSetsAssociation.Items.Count() = 0 Then
		Return Result;
	EndIf; 
	
	// Layout layout
	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(DataCompositionSchema, DataCompositionSettingsComposer.GetSettings(),,, Type("DataCompositionValueCollectionTemplateGenerator"));
	
	// Initializing the layout processor
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate, DataSets);
		
	// Getting the result
	DataCompositionResultValueCollectionOutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	DataCompositionResultValueCollectionOutputProcessor.SetObject(Result);
	DataCompositionResultValueCollectionOutputProcessor.Output(DataCompositionProcessor);
	
	
	Exclude = ConversionParameters.Exclude And Result.Columns.Find("Count") <> Undefined;
	NumberOfRules = RulesForFillingInFoundRows.Count();
	
	FunctionName = "";
	If ConversionParameters.TransformationOption = Enums.ConversionOptions.Max Then
		
		FunctionName = NStr("vi = 'Tối đa(%1)';
							|ru = 'Макс(%1)';
							|en = 'Max(%1)'; fa = 'Max(%1)';
							|it = 'Макс(%1)';
							|pl = 'Max(%1)';
							|tr = 'Maksimum(%1)'");
		
	ElsIf ConversionParameters.TransformationOption = Enums.ConversionOptions.AVG Then
		
		FunctionName = NStr("vi = 'Trung bình(%1)';
							|ru = 'Сред(%1)';
							|en = 'Average(%1)'; fa = 'Average(%1)';
							|it = 'Сред(%1)';
							|pl = 'Average(%1)';
							|tr = 'Ortalama(%1)'");
		
	ElsIf ConversionParameters.TransformationOption = Enums.ConversionOptions.Min Then
		
		FunctionName = NStr("vi = 'Tối thiểu(%1)';
							|ru = 'Мин(%1)';
							|en = 'Min(%1)'; fa = 'Min(%1)';
							|it = 'Мин(%1)';
							|pl = 'Min(%1)';
							|tr = 'Minimum(%1)'");
		
	EndIf;
	
	ZoomRatio = 1;
	If ConversionParameters.TopLevel And AdditionalParameters.Property("DataParameters")
		And AdditionalParameters.DataParameters.Property("ZoomRatio")Then
		ZoomRatio = AdditionalParameters.DataParameters.ZoomRatio;
	EndIf;
	
	For Each ResultString1 In Result Do
		
		If Exclude Then
			ResultString1.Count = - ResultString1.Count;
		EndIf;
		
		If ValueIsFilled(FunctionName) Then
			ResultString1.Details = ?(Exclude, "-","") + StringFunctionsClientServer.SubstituteParametersToString(FunctionName, StrReplace(ResultString1.Details,"|", "; "));
			
			ResultString1.NumericalRepresentation = ?(Exclude, "-","") + StringFunctionsClientServer.SubstituteParametersToString(FunctionName,
				StrReplace(ResultString1.NumericalRepresentation, "|", "; "));
		Else
			ResultString1.Details = StrReplace(ResultString1.Details, "|", " + ");
			ResultString1.NumericalRepresentation = StrReplace(ResultString1.NumericalRepresentation, "|", " + ");
			
			If Not ConversionParameters.TopLevel Or Not ZoomRatio = 1 Or Exclude Then
				ResultString1.Details           = ?(Exclude, "-","") + "(" + ResultString1.Details + ")";
				ResultString1.NumericalRepresentation = ?(Exclude, "-","") + "(" + ResultString1.NumericalRepresentation + ")";
			EndIf;
			
		EndIf;
		
		If ZoomRatio <> 1 Then
			ResultString1.Details = ResultString1.Details + " * Coefficient";
			ResultString1.NumericalRepresentation = ResultString1.NumericalRepresentation + " * " + String(ZoomRatio);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region ProceduresForFillingInFormulas

// Adds the first set of data from the operand's SKD to the conversion scheme and all the operand settings.
//
// Parameters:
//  DataCompositionSchemaConversion  - DataCompositionSchema - document conversion scheme to which the operand set is added
//  CollectionOfSets  - DataCompositionTemplateDataSets - Collection of combining data sets in a transformation schema
//  SKD_Operand  - DataCompositionSchema - operand schema with settings from which sets will be added 
//                 to the conversion schema
//  OperandNames  - String - The names of the operands, separated by commas, used to fill PM.
//
Procedure AddSetOfOperandsToConversionScheme(DataCompositionSchemaConversion, CollectionOfSets, SKD_Operand, OperandNames = "")
	
	ConversionSettings = DataCompositionSchemaConversion.SettingVariants[0].Settings; // DataCompositionSettings - 
	
	DatasetObject = CollectionOfSets.Items.Add(TypeOf(SKD_Operand.DataSets[0]));
	DatasetObject.Name = SKD_Operand.DataSets[0].Name;
	DatasetObject.DataSource = DataCompositionSchemaConversion.DataSources[0].Name;
	
	If TypeOf(SKD_Operand.DataSets[0]) <> Type("DataCompositionTemplateDataSetQuery") Then
		DatasetObject.Query = SKD_Operand.DataSets[0].Query;
		DatasetObject.AutoFillAvailableFields = SKD_Operand.DataSets[0].AutoFillAvailableFields;
	Else
		DatasetObject.ObjectName  = SKD_Operand.DataSets[0].ObjectName ;
	EndIf; 
	
	// Set fields
	For Each Field In SKD_Operand.DataSets[0].Fields Do
		DataSetField = DatasetObject.Fields.Add(TypeOf(Field));
		FillPropertyValues(DataSetField, Field);
		
		DataSetField = CollectionOfSets.Fields.Find(Field.Field);
		If DataSetField = Undefined Then
			DataSetField = CollectionOfSets.Fields.Add(TypeOf(Field));
			FillPropertyValues(DataSetField, Field);
		EndIf; 
	EndDo;
	
	// Resources
	For Each Field In SKD_Operand.TotalFields Do
		
		NewField = DataCompositionSchemaConversion.TotalFields.Find(Field.DataPath);
		
		If NewField = Undefined Then
			NewField = DataCompositionSchemaConversion.TotalFields.Add();
		EndIf; 
		
		FillPropertyValues(NewField, Field, "Expression, DataPath");
		
		ComboBox = ConversionSettings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		ComboBox.Field = New DataCompositionField(NewField.DataPath);
		ComboBox.Title = NewField.DataPath;
		ComboBox.Use = True;
		
		OperandNames = OperandNames + ?(IsBlankString(OperandNames), "", ", ") + NewField.DataPath;
	EndDo; 
	
	For Each Parameter In SKD_Operand.Parameters Do
		
		FoundParameter = DataCompositionSchemaConversion.Parameters.Find(Parameter.Name);
		If FoundParameter = Undefined Then
			
			NewParameter1 = DataCompositionSchemaConversion.Parameters.Add();
			FillPropertyValues(NewParameter1, 
			Parameter, 
			"IncludeInAvailableFields, Use, Expression, ValueListAllowed, Title, DenyIncompleteValues,
			|Value, Name, UseRestriction, FunctionalOptionsParameter, ValueType");
			
		EndIf; 
	EndDo; 
	

EndProcedure

// Performs the conversion SCD, supplemented with sets of operands and other settings, and outputs the result to a table.
//
// Parameters:
//  DataCompositionSchemaConversion   - DataCompositionSchema - document conversion scheme with added sets of operands
//  Parameters  - Structure - parameters required to execute the schema
//  ResultTable2  - ValueTable - the table where the result of the schema execution will be displayed
//  DatasetsObjects  - Structure - Structure with external sets-objects for the layout scheme.
//
Procedure PerformConversionScheme(DataCompositionSchemaConversion, Parameters, ResultTable2, DatasetsObjects = Undefined)
	
	// SKD loading
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchemaConversion));
	SettingsComposer.LoadSettings(DataCompositionSchemaConversion.DefaultSettings);
	SettingsComposer.Refresh();
	
	// Adding parameters
	For Each Parameter In DataCompositionSchemaConversion.Parameters Do
		
		If Parameters.Property(Parameter.Name) Then
			DataCompositionClientServer.SetParameter(SettingsComposer, Parameter.Name, Parameters[Parameter.Name]);
		EndIf; 
		
	EndDo; 
	
	// Setting selections
	If Parameters.Property("Filter") Then
		For Each FilterElement In Parameters.Filter Do
			DataCompositionClientServer.SetParameter(SettingsComposer, FilterElement.Key, FilterElement.Value);
			Field = New DataCompositionField(FilterElement.Key);
			If SettingsComposer.Settings.FilterAvailableFields.FindField(Field) <> Undefined Then
				DataCompositionClientServer.AddFilter(SettingsComposer, Field, FilterElement.Value,,, New Structure("ToUserSettings", True));
			EndIf; 
		EndDo; 
	EndIf; 
	
	If Parameters.Property("Ref") Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "Ref", Parameters.Ref);
	EndIf; 
	If Parameters.Property("ProductionProcessType") And Parameters.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
		DataCompositionClientServer.AddFilter(
			SettingsComposer,
			"Products.ItemsType",
			Enums.ItemsTypes.Work_5,
			DataCompositionComparisonType.Equal);
	EndIf;
	// Setting selection by item segments
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
	// Setting up selection by partner segments
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer); 
	
	// Disabling the output of total totals
	SettingsComposer.Settings.OutputParameters.SetParameterValue("HorizontalOverallPlacement", DataCompositionTotalPlacement.None);
	SettingsComposer.Settings.OutputParameters.SetParameterValue("VerticalOverallPlacement", DataCompositionTotalPlacement.None);
	
	// Layout layout
	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(DataCompositionSchemaConversion, SettingsComposer.GetSettings(),,, Type("DataCompositionValueCollectionTemplateGenerator"));
	
	// Initializing the layout processor
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate, DatasetsObjects, , True);
	
	// Getting the result
	DataCompositionResultValueCollectionOutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	DataCompositionResultValueCollectionOutputProcessor.SetObject(ResultTable2);
	DataCompositionResultValueCollectionOutputProcessor.Output(DataCompositionProcessor);

EndProcedure

// Deletes unused sets for filling in formulas
//
// Parameters:
//  DataCompositionSchemaConversion   - DataCompositionSchema - document conversion scheme.
//
Procedure DeleteSetsNotUsedForFormulas(DataCompositionSchemaConversion)

	DataSetAssociation = DataCompositionSchemaConversion.DataSets.Union; // DataCompositionSchemaDataSetUnion - 
	DataSetJoining = DataCompositionSchemaConversion.DataSets.Find("Joining");
	If DataSetJoining <> Undefined Then
		
		// Check if the attachment sets have been added
		If DataSetJoining.Items.Count() = 1 Then
			
			// We add fields from the attachment set so that it is possible to select all with one set.
			For Each Field In DataSetJoining.Items.DataSet.Fields Do
				DataSet = DataSetAssociation.Items.DataSet; // DataCompositionSchemaDataSetQuery - 
				DataSetField = DataSet.Fields.Add(TypeOf(Field));
				FillPropertyValues(DataSetField, Field);
			EndDo;
			
			IndexOf = DataCompositionSchemaConversion.DataSetLinks.Count() - 1;
			
			While  IndexOf >= 0 Do
				
				Link = DataCompositionSchemaConversion.DataSetLinks[IndexOf];
				If Link.SourceDataSet = "Joining" Or Link.DestinationDataSet  = "Joining" Then
					DataCompositionSchemaConversion.DataSetLinks.Delete(Link);
				EndIf; 
				
				IndexOf = IndexOf - 1;
				
			EndDo;
			
			DataSetJoining.Items.Delete(DataSetJoining.Items.DataSet);
			DataCompositionSchemaConversion.DataSets.Delete(DataSetJoining);
			
		Else
			DataSetJoining.Items.Delete(DataSetJoining.Items.DataSet);
		EndIf; 
		
	EndIf;
	
	If DataSetAssociation.Items.Count() = 1 Then
		
		IndexOf = DataCompositionSchemaConversion.DataSetLinks.Count() - 1;
		
		While  IndexOf >= 0 Do
			
			Link = DataCompositionSchemaConversion.DataSetLinks[IndexOf];
			If Link.SourceDataSet = "Union" Or Link.DestinationDataSet = "Union" Then
				DataCompositionSchemaConversion.DataSetLinks.Delete(Link);
			EndIf; 
			
			IndexOf = IndexOf - 1;
			
		EndDo;
		
		DataSetAssociation.Items.Delete(DataSetAssociation.Items.DataSet);
		DataCompositionSchemaConversion.DataSets.Delete(DataSetAssociation);
		
	Else
		DataSetAssociation.Items.Delete(DataSetAssociation.Items.DataSet);
	EndIf;
	
	// Deleting the totals fields that are not found in the datasets
	IndexOf = DataCompositionSchemaConversion.TotalFields.Count() - 1;
	While IndexOf >= 0 Do
		
		FieldFound = False;
		TotalField = DataCompositionSchemaConversion.TotalFields[IndexOf];
		For Each Set In DataCompositionSchemaConversion.DataSets Do
			
			If Set.Fields.Find(TotalField.DataPath) <> Undefined Then
				FieldFound = True;
				Break;
			EndIf;
		
		EndDo; 
		
		If Not FieldFound Then
			DataCompositionSchemaConversion.TotalFields.Delete(TotalField);
		EndIf; 
		
		IndexOf = IndexOf - 1;
		
	EndDo; 
	
	
EndProcedure

// Configures the conversion SCD to output the decryption of the value of a single operand
//
// Parameters:
//  DataCompositionSchemaConversion   - DataCompositionSchema - document conversion scheme
//  CollectionOfSets  - DataCompositionTemplateDataSets - a collection of sets from which you want to remove the field
//  FieldArray  - Array - Fields that should remain in the schema.
//
Procedure ConfigureSchemeForDecryption(DataCompositionSchemaConversion, CollectionOfSets, FieldArray)

	// Removing unnecessary fields
	DeleteFields(CollectionOfSets.Fields, FieldArray);
	For Each Set In CollectionOfSets.Items Do
		DeleteFields(Set.Fields, FieldArray);
	EndDo;
	
	Settings = DataCompositionSchemaConversion.DefaultSettings;
	
	// Removing unnecessary links
	DataCompositionSchemaConversion.DataSetLinks.Clear();
	DataCompositionSchemaConversion.TotalFields.Clear();
	Settings.Structure.Clear();
	
	LoggerGrouping = Settings.Structure.Add(Type("DataCompositionGroup"));
	
	For Each Field In FieldArray Do
	
		LoggerField_ = LoggerGrouping.GroupFields.Items.Add(Type("DataCompositionGroupField"));
		LoggerField_.Use = True;
		LoggerField_.Field = New DataCompositionField(Field);
	
	EndDo; 
	
	SelectedFieldsForLogger = LoggerGrouping.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	SelectedFieldsForLogger.Use = True;

EndProcedure 

// Deleting layout fields
//
// Parameters:
// Fields             - DataCompositionSchemaDataSetFields - Collection of fields from which we remove unnecessary ones
// FieldArray        - Array - An array of the fields that you want to keep.
//
Procedure DeleteFields(Fields, FieldArray)
	
	ArrayOfFieldsToDelete = New Array();
	
	For Each Field In Fields Do
		If FieldArray.Find(Field.Field) = Undefined Then
			ArrayOfFieldsToDelete.Add(Field);
		EndIf;
	EndDo;
	
	For Each Field In ArrayOfFieldsToDelete Do
		Fields.Delete(Field);
	EndDo; 

EndProcedure

// This function creates a table of values to fill in with plan periods
//
// Returns:
//   See TablePeriods
//
Function PeriodTableTemplate() Export
	
	DescriptionOfHTypes = Common.TypeDescriptionNumber(10, 0); 
	TypesDetailsBoolean = New TypeDescription("Boolean");
	TypesDetailsString = New TypeDescription("String");
	TypesDetailsDate = TMCommonUse.GetDescriptionOfDateTypes(DateFractions.DateTime);
	
	PeriodsTable = New ValueTable;
	PeriodsTable.Columns.Add("ColumnNumber",  DescriptionOfHTypes);
	PeriodsTable.Columns.Add("ColumnName",    TypesDetailsString);
	PeriodsTable.Columns.Add("Active_",      TypesDetailsBoolean);
	PeriodsTable.Columns.Add("StartDate",    TypesDetailsDate);
	PeriodsTable.Columns.Add("EndDate", TypesDetailsDate);
	PeriodsTable.Columns.Add("Title",     TypesDetailsString);
	PeriodsTable.Columns.Add("Substituted",       TypesDetailsBoolean);
	PeriodsTable.Columns.Add("SubstitutedToOrder",TypesDetailsBoolean);
	
	Return PeriodsTable;

EndFunction 


// The percentage of days of product availability on the remainder of the redefinition request text.
// 
// Parameters:
//  DCSRequestDataSet - DataCompositionSchemaDataSetQuery -
//  Parameters            - Structure - composition of keys:
//   * PeriodOffset - Number -
//   * Periodicity   - EnumRef.Periodicity -
//   * TimeIntervals         - ValueTable - Period table:
//      ** StartDate    - Date -
//      ** EndDate - Date -
//   * NotOverridden  - Boolean - flag for redefining the request text
// 
Procedure PercentageOfProductAvailabilityDaysRemainingRequestTextRedefinition(DCSRequestDataSet, Parameters)
	
	Offset        = Parameters.PeriodOffset;
	Periodicity   = Parameters.Periodicity;
	PeriodsTable = Parameters.TimeIntervals;
	
	QueriesTexts = New Array;
	QueriesTexts.Add("&NotOverridden");
	
	For Each TableRow In PeriodsTable Do
		
		BeginOfPeriod = PlanningClientServer.CalculateStartDateOfPeriod(
							TMCommonUseClientServer.CalculatePeriodEndDate(
								TableRow.StartDate, Periodicity, Offset) + 1,
							Periodicity);
		
		EndOfPeriod = PlanningClientServer.CalculatePeriodEndDate(
							TMCommonUseClientServer.CalculatePeriodEndDate(
								TableRow.EndDate, Periodicity, Offset) + 1,
							Periodicity);
		
		QueryText =
		"SELECT
		|	&OffsetPeriodStart AS OffsetPeriodStart,
		|	&BeginOfPeriod         AS BeginOfPeriod,
		|	&EndOfPeriod          AS EndOfPeriod";
		
		QueryText = StrReplace(QueryText, "&OffsetPeriodStart", DateInRequest(TableRow.StartDate));
		QueryText = StrReplace(QueryText, "&BeginOfPeriod",		   DateInRequest(BeginOfPeriod));
		QueryText = StrReplace(QueryText, "&EndOfPeriod",		   DateInRequest(EndOfPeriod));
		
		QueriesTexts.Add(QueryText);
		
	EndDo;
	
	DCSRequestDataSet.Query = StrReplace(
									DCSRequestDataSet.Query,
									"&NotOverridden",
									StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin()));
	
	Parameters.NotOverridden = False;
	
EndProcedure

Function DateInRequest(Date)
	
	Return StrTemplate(
				"DATETIME(%1, %2, %3, %4, %5, %6)",
				Format(Year(Date), "NG=;"), Month(Date), Day(Date), Hour(Date), Minute(Date), Second(Date));
	
EndFunction

#EndRegion

#Region ProductionPlans

Procedure GetDurationSpecificationsAndFillDatesOnSchedule(RowsCollection, CountdownDateName, DateOnScheduleName, PlanningScenario, SearchForward, MethodOfCalculationOfMaterials) Export
	
	BOMList = New Array();
	ReferenceDates = New ValueTable;
	ReferenceDates.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
	ReferenceDates.Columns.Add(CountdownDateName, New TypeDescription("Date",,, New DateQualifiers));
	ReferenceDates.Columns.Add("NumberOfDays", New TypeDescription("Number", New NumberQualifiers));
	ReferenceDates.Columns.Add("IndexOf", New TypeDescription("Number", New NumberQualifiers));
	
	For IndexOf = 0 To RowsCollection.Count()-1 Do
		
		String = RowsCollection[IndexOf];
		
		If ValueIsFilled(String.BillOfMaterials)
			And ValueIsFilled(String[CountdownDateName]) Then
			
			BOMList.Add(String.BillOfMaterials);
			NewRow = ReferenceDates.Add();
			NewRow.IndexOf = IndexOf;
			FillPropertyValues(NewRow, String, "BillOfMaterials," + CountdownDateName);
			
		EndIf;
		
	EndDo;
	
	If ReferenceDates.Count() = 0 Then
		Return;
	EndIf;
	
	NormativeDuration = InformationRegisters.StandardProductionDuration.GetDuration(BOMList);
	DurationField = ?(MethodOfCalculationOfMaterials = Enums.MaterialCalculationMethods.MinimumConsumption,
		"PlannedProductionDurationDays",
		"MaximumProductionDurationDays");
	For Each String In ReferenceDates Do
		String.NumberOfDays = NormativeDuration.Get(String.BillOfMaterials)[DurationField];
	EndDo;
	
	Query = New Query(
		"SELECT DISTINCT
		|	ReferenceDates." + CountdownDateName + " AS StartingDate,
		|	ReferenceDates.NumberOfDays AS NumberOfDays
		|INTO TTCountdownDates
		|FROM
		|	&ReferenceDates AS ReferenceDates");
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("ReferenceDates", ReferenceDates);
	Query.Execute();
	
	LaunchDates = GetDatesBySchedule(Query.TempTablesManager, PlanningScenario, SearchForward);
	LaunchDates.Columns.StartingDate.Name = CountdownDateName;
	
	ReferenceDates.Indexes.Add("NumberOfDays," + CountdownDateName);
	TheStructureOfTheSearch = New Structure("NumberOfDays," + CountdownDateName);
	
	For Each LineLaunch In LaunchDates Do
		
		FillPropertyValues(TheStructureOfTheSearch, LineLaunch);
		FoundRows = ReferenceDates.FindRows(TheStructureOfTheSearch);
		
		For Each ReleaseString In FoundRows Do
			
			CollectionRow = RowsCollection[ReleaseString.IndexOf];
			CollectionRow[DateOnScheduleName] = LineLaunch.DateAccordingToSchedule;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Calculates launch dates by subtracting the specified number of days from the transmitted release dates based on
// the script calendar (or the main calendar). If you can't calculate the date from the calendar,
// the result will be determined by simple subtraction.
//
// Parameters:
//  Source	 - ValueTable, TempTablesManager - a table or manager with a table of account datesreferences, columns:
//			* StartingDate - Date - the date from which the calculation should be performed.
//			* NumberOfDays - Number - the number of days to set aside to the left of the release date.
//  Scenario - CatalogRef.SalesOperationsPlanningScenarios - a script whose calendar is
//		used to calculate launch dates.
//  SearchForward - Boolean               - if true, then search forward, otherwise search backward.
// 
// Returns:
//  ValueTable - Content:
//    * StartingDate - Date -
//    * NumberOfDays - Number -
//    * DateAccordingToSchedule - Date -
//
Function GetDatesBySchedule(Source, Scenario, SearchForward) Export
	
	Calendar = Catalogs.SalesOperationsPlanningScenarios.Calendar(Scenario);
	
	Query = New Query(
		"SELECT
		|	Table.StartingDate AS StartingDate,
		|	Table.NumberOfDays   AS NumberOfDays
		|INTO TTSource
		|FROM
		|	#Table AS Table
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&Calendar          AS Calendar,
		|	Table.StartingDate AS StartingDate,
		|	Table.NumberOfDays   AS NumberOfDays
		|INTO TTSearchParameters
		|FROM
		|	TTSource AS Table
		|WHERE
		|	Table.NumberOfDays <> 0
		|
		|INDEX BY
		|	Calendar,
		|	StartingDate
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|"
		+ ProductionServer.QueryTextForDatesByCalendar(SearchForward)
		+ "
		|SELECT
		|	Table.StartingDate AS StartingDate,
		|	Table.NumberOfDays   AS NumberOfDays,
		|	ISNULL(ScheduleDates.Date, DATEADD(Table.StartingDate, DAY, Table.NumberOfDays * &Direction)) AS DateAccordingToSchedule
		|FROM
		|	TTSearchParameters AS Table
		|		LEFT JOIN TTScheduleDates AS ScheduleDates
		|		ON Table.StartingDate = ScheduleDates.StartingDate
		|			AND Table.NumberOfDays = ScheduleDates.NumberOfDays
		|
		|UNION ALL
		|
		|SELECT
		|	Table.StartingDate,
		|	Table.NumberOfDays,
		|	Table.StartingDate
		|FROM
		|	TTSource AS Table
		|WHERE
		|	Table.NumberOfDays = 0");
	Query.SetParameter("Calendar", Calendar);
	Query.SetParameter("Direction", ?(SearchForward, 1, -1));
	
	If TypeOf(Source) = Type("TempTablesManager") Then
		Query.Text = StrReplace(Query.Text, "#Table", "TTCountdownDates");
		Query.TempTablesManager = Source;
	Else
		Query.Text = StrReplace(Query.Text, "#Table", "&ReferenceDates");
		Query.SetParameter("ReferenceDates", Source);
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

Function CalculateLaunchDate(Scenario, DateOfProduction, BillOfMaterials, MethodOfCalculationOfMaterials) Export
	
	Table = New ValueTable;
	Table.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
	Table.Columns.Add("DateOfProduction", New TypeDescription("Date",,, New DateQualifiers));
	Table.Columns.Add("StartDate2", New TypeDescription("Date",,, New DateQualifiers));
	
	NewRow = Table.Add();
	NewRow.BillOfMaterials = BillOfMaterials;
	NewRow.DateOfProduction = DateOfProduction;
	
	GetDurationSpecificationsAndFillDatesOnSchedule(
		Table,
		"DateOfProduction",
		"StartDate2",
		Scenario,
		False,
		MethodOfCalculationOfMaterials);
	
	Return Table[0].StartDate2;
	
EndFunction

#EndRegion

#Region PlanningProcessManagement

// The procedure starts a background check for calculating deficits by stage
//
// Parameters:
//  Scenario - CatalogRef.SalesOperationsPlanningScenarios - the scenario for which the calculation is performed.
//  PlanProfile - CatalogRef.PlanProfiles - type of plan for which the calculation is made.
//
Procedure RunningBackgroundCheckForCalculatingDeficitInStages(Scenario, PlanProfile) Export
	
	Var_Key = "VerificationCalculationOfDeficitsOfPlansByStages" + PlanProfile.UUID();
	Filter = New Structure();
	Filter.Insert("Key", Var_Key);
	Filter.Insert("State", BackgroundJobState.Active);
	
	SetPrivilegedMode(True);
	
	ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	
	SetPrivilegedMode(False);
	
	If ActiveTasks.Count() > 0 Then
		Return;
	EndIf;
	
	JobDescription = NStr("vi = 'Kiểm tra tính toán thâm hụt kế hoạch theo các kỳ cho loại kế hoạch';
							|ru = 'Проверка расчета дефицитов планов по этапам для вида плана';
							|en = 'Verification of plan shortages calculation by stages for plan profile'; fa = 'Verification of plan shortages calculation by stages for plan profile';
							|it = 'Verifica del calcolo delle carenze dei piani per fasi per un tipo di piano';
							|pl = 'Weryfikacja obliczenia niedoborów planów według etapów dola rodzaju planu';
							|tr = 'Plan türü için aşamalara göre planların mali açıklarının hesaplanmasının kontrolü'") + String(PlanProfile);
	
	ExportProcedureName = "Planning.PerformBackgroundCheckOnCalculationOfDeficitsByStages";
	
	ExportProcedureParameters = New Array();
	ParametersStructure = New Structure("ErrorsCount, PlanProfile, Scenario");
	ParametersStructure.ErrorsCount = 0;
	ParametersStructure.Scenario = Scenario;
	ParametersStructure.PlanProfile = PlanProfile;
	ExportProcedureParameters.Add(ParametersStructure);
	
	JobParameters = New Array();
	JobParameters.Add(ExportProcedureName);
	JobParameters.Add(ExportProcedureParameters);
	
	BackgroundJobs.Execute("Common.ExecuteConfigurationMethod", JobParameters, Var_Key, JobDescription);
	
EndProcedure

// The procedure performs a background check for calculating deficits in stages and starts a background task for calculating deficits
//
// Parameters:
//  JobParameters  - Structure - the structure stores the number of errors if error is larger than a certain limit,
//                                  the job will be completed.
//
Procedure PerformBackgroundCheckOnCalculationOfDeficitsByStages(JobParameters) Export
	
	If JobParameters.Property("ErrorsCount") Then
		
		MaximumNumberOfErrors = 3;
		
		If JobParameters.ErrorsCount >= MaximumNumberOfErrors Then
			
			DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
			
			MessageText = NStr("vi = 'Việc kiểm tra lý lịch để tính toán thâm hụt kế hoạch theo các kỳ đã bị dừng lại. Số lần thử thất bại: %ErrorsCount%';
								|ru = 'Фоновая проверка расчета дефицитов планов по этапам остановлена. Количество неудачных попыток: %ErrorsCount%';
								|en = 'Background verification of plan shortages calculation by stages was stopped. Number of unsuccessful attempts: %ErrorsCount%'; fa = 'Background verification of plan shortages calculation by stages was stopped. Number of unsuccessful attempts: %ErrorsCount%';
								|it = 'Verifica in background del calcolo dei deficit dei piani per le fasi fermate. Numero di tentativi non riusciti: %ErrorsCount%';
								|pl = 'Weryfikacja w tle obliczenia niedoborów planów według etapów została zatrzymana. Liczba nieudanych prób: %ErrorsCount%';
								|tr = 'Arka planda plan mali açığının hesaplanmasının kontrolü durduruldu. Başarısız deneme sayısı: %ErrorsCount%'");
			MessageText = StrReplace(MessageText, "%ErrorsCount%", JobParameters.ErrorsCount);
			
			WriteLogEvent(NStr("vi = 'Xác minh lý lịch tính toán thâm hụt theo các kỳ';
								|ru = 'Фоновая проверка расчета дефицитов по этапам';
								|en = 'Background verification of shortages calculation by stages'; fa = 'Background verification of shortages calculation by stages';
								|it = 'Verifica in background di calcolo dei deficit per le fasi';
								|pl = 'Weryfikacja w tle obliczenia niedoborów według etapów';
								|tr = 'Aşamalara göre mali açıkların hesaplanmalarının arka planda kontrolü'", DefaultLanguageCode),
				EventLogLevel.Error, , ,
				MessageText);
			
			Return;
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	
	CheckingCompletionOfCalculationOfProductionPlansAndReplacementPlans(JobParameters.Scenario);
	
	ItIsRequiredToRecalculateDeficits = False;
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.ShortagesCalculationQueueInStages");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("Scenario", JobParameters.Scenario);
		LockItem.SetValue("PlanProfile", JobParameters.PlanProfile);
		
		LockItem = Block.Add("InformationRegister.CalculationOfPlanShortagesByStages");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("Scenario", JobParameters.Scenario);
		LockItem.SetValue("PlanProfile", JobParameters.PlanProfile);
		Block.Lock();
		
		ItIsRequiredToRecalculateDeficits = ItIsRequiredToRecalculateDeficits(JobParameters.Scenario, JobParameters.PlanProfile);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
		JobParameters.ErrorsCount = JobParameters.ErrorsCount + 1;
		
		MessageText = NStr("vi = 'Không thể khóa đăng ký ""Hàng đợi để tính toán thâm hụt theo các kỳ"" bởi tác vụ nền. Số lần thử: %ErrorsCount%';
							|ru = 'Не удалось выполнить блокировку регистра ""Очередь расчета дефицитов по этапам"" фоновым заданием. Количество попыток: %ErrorsCount%';
							|en = 'Failed to lock the register ""Queue for calculation of shortages by plans"" with background job. Number of attempts: %ErrorsCount%'; fa = 'Failed to lock the register ""Queue for calculation of shortages by plans"" with background job. Number of attempts: %ErrorsCount%';
							|it = 'Non è stato possibile eseguire il blocco del registro ""Coda di calcolo dei deficit in base alle fasi"" con il task in background.La quantità dei tentativi:%ErrorsCount%';
							|pl = 'Nie udało się wykonać blokadę rejestru ""Kolejka obliczenia niedoborów według etapów"" zadaniem w tle. Ilość prób: %ErrorsCount%';
							|tr = 'Arka plan işlerindeki ""Aşamalara göre mali açık hesaplamalarının sırası"" kaydının kilitlenmesi işlemi gerçekleştirilemedi. Deneme sayısı: %ErrorsCount%'");
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
			MessageText = StrReplace(MessageText, "%ErrorsCount%", JobParameters.ErrorsCount);
		
			WriteLogEvent(NStr("vi = 'Xác minh lý lịch tính toán thâm hụt theo các kỳ';
								|ru = 'Фоновая проверка расчета дефицитов по этапам';
								|en = 'Background verification of shortages calculation by stages'; fa = 'Background verification of shortages calculation by stages';
								|it = 'Verifica in background di calcolo dei deficit per le fasi';
								|pl = 'Weryfikacja w tle obliczenia niedoborów według etapów';
								|tr = 'Aşamalara göre mali açıkların hesaplanmalarının arka planda kontrolü'", DefaultLanguageCode),
				EventLogLevel.Error,
				,
				,
				MessageText);
				
		PerformBackgroundCheckOnCalculationOfDeficitsByStages(JobParameters);
		Return;
	EndTry;
	
	If ItIsRequiredToRecalculateDeficits Then
		StartingBackgroundCalculationOfDeficitInStages(JobParameters.Scenario);
	EndIf;
	
EndProcedure

// The function checks for discrepancies in plan movements and
// the "calculating deficits by Stages" register. the result is recorded in the "queue calculating deficits by Stages" register"
//
// Parameters:
//  Scenario  - CatalogRef.SalesOperationsPlanningScenarios - the scenario for which the calculation is performed.
//  PlanProfile  - CatalogRef.PlanProfiles - type of plan for which the calculation is made.
// Returns:
//  Boolean
Function ItIsRequiredToRecalculateDeficits(Scenario, PlanProfile) Export
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	SalesPlansTurnovers.Products AS Products,
	|	SalesPlansTurnovers.Characteristic AS Characteristic,
	|	SalesPlansTurnovers.Purpose AS Purpose,
	|	SalesPlansTurnovers.Scenario AS Scenario,
	|	SalesPlansTurnovers.PlanProfile AS PlanProfile,
	|	SalesPlansTurnovers.Period AS PlanningPeriod,
	|	0 AS OpeningBalance,
	|	0 AS Receipt,
	|	0 AS ToSupply,
	|	SalesPlansTurnovers.CountTurnover AS Expense,
	|	0 AS ExpenseAdjustment,
	|	0 AS DemandRangeIsSpecified,
	|	0 AS RangeOfDemandFrom,
	|	0 AS RangeOfDemandTo,
	|	FALSE AS ShouldRecalculate
	|INTO Plans
	|FROM
	|	AccumulationRegister.SalesPlans.Turnovers(
	|			,
	|			,
	|			Month,
	|			&PlanType = VALUE(Enum.TypesOfPlans.SalesPlan)
	|				AND Scenario = &Scenario
	|				AND PlanProfile = &PlanProfile
	|				AND Status IN (&ScenarioStatuses)) AS SalesPlansTurnovers
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryConsumptionPlansTurnovers.Products,
	|	InventoryConsumptionPlansTurnovers.Characteristic,
	|	InventoryConsumptionPlansTurnovers.Purpose,
	|	InventoryConsumptionPlansTurnovers.Scenario,
	|	InventoryConsumptionPlansTurnovers.PlanProfile,
	|	InventoryConsumptionPlansTurnovers.Period,
	|	0,
	|	0,
	|	0,
	|	InventoryConsumptionPlansTurnovers.CountTurnover,
	|	0,
	|	0,
	|	0,
	|	0,
	|	FALSE
	|FROM
	|	AccumulationRegister.InventoryConsumptionPlans.Turnovers(
	|			,
	|			,
	|			Month,
	|			&PlanType = VALUE(Enum.TypesOfPlans.InventoryConsumptionPlan)
	|				AND Scenario = &Scenario
	|				AND PlanProfile = &PlanProfile
	|				AND Status IN (&ScenarioStatuses)) AS InventoryConsumptionPlansTurnovers
	|
	|UNION ALL
	|
	|SELECT
	|	PurchasePlansTurnovers.Products,
	|	PurchasePlansTurnovers.Characteristic,
	|	PurchasePlansTurnovers.Purpose,
	|	PurchasePlansTurnovers.Scenario,
	|	PurchasePlansTurnovers.PlanProfile,
	|	PurchasePlansTurnovers.Period,
	|	0,
	|	PurchasePlansTurnovers.CountTurnover,
	|	PurchasePlansTurnovers.CountTurnover,
	|	0,
	|	0,
	|	PurchasePlansTurnovers.DemandRangeIsSpecifiedTurnover,
	|	PurchasePlansTurnovers.RangeOfDemandFromTurnover,
	|	PurchasePlansTurnovers.RangeOfDemandToTurnover,
	|	FALSE
	|FROM
	|	AccumulationRegister.PurchasePlans.Turnovers(
	|			,
	|			,
	|			Month,
	|			&PlanType = VALUE(Enum.TypesOfPlans.PurchasePlan)
	|				AND Scenario = &Scenario
	|				AND PlanProfile = &PlanProfile
	|				AND Status IN (&ScenarioStatuses)) AS PurchasePlansTurnovers
	|
	|UNION ALL
	|
	|SELECT
	|	TurnoverBalancePlans.Products,
	|	TurnoverBalancePlans.Characteristic,
	|	TurnoverBalancePlans.Purpose,
	|	TurnoverBalancePlans.Scenario,
	|	TurnoverBalancePlans.PlanProfile,
	|	TurnoverBalancePlans.Period,
	|	TurnoverBalancePlans.CountTurnover,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	FALSE
	|FROM
	|	AccumulationRegister.PlansOfGoodsStock.Turnovers(
	|			,
	|			,
	|			Month,
	|			&PlanType = VALUE(Enum.TypesOfPlans.PlanOfGoodsStock)
	|				AND Scenario = &Scenario
	|				AND PlanProfile = &PlanProfile
	|				AND Status IN (&ScenarioStatuses)) AS TurnoverBalancePlans
	|
	|UNION ALL
	|
	|SELECT
	|	AssemblyPlansDisassemblyRevolutions.Products,
	|	AssemblyPlansDisassemblyRevolutions.Characteristic,
	|	AssemblyPlansDisassemblyRevolutions.Purpose,
	|	AssemblyPlansDisassemblyRevolutions.Scenario,
	|	AssemblyPlansDisassemblyRevolutions.PlanProfile,
	|	AssemblyPlansDisassemblyRevolutions.Period,
	|	0,
	|	CASE
	|		WHEN AssemblyPlansDisassemblyRevolutions.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|			THEN AssemblyPlansDisassemblyRevolutions.CountTurnover
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN AssemblyPlansDisassemblyRevolutions.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|			THEN AssemblyPlansDisassemblyRevolutions.CountTurnover
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN AssemblyPlansDisassemblyRevolutions.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
	|			THEN AssemblyPlansDisassemblyRevolutions.CountTurnover
	|		ELSE 0
	|	END,
	|	0,
	|	AssemblyPlansDisassemblyRevolutions.DemandRangeIsSpecifiedTurnover,
	|	AssemblyPlansDisassemblyRevolutions.RangeOfDemandFromTurnover,
	|	AssemblyPlansDisassemblyRevolutions.RangeOfDemandToTurnover,
	|	FALSE
	|FROM
	|	AccumulationRegister.AssemblyDisassemblyPlans.Turnovers(
	|			,
	|			,
	|			Month,
	|			&PlanType = VALUE(Enum.TypesOfPlans.AssemblyDisassemblyPlan)
	|				AND Scenario = &Scenario
	|				AND PlanProfile = &PlanProfile
	|				AND Status IN (&ScenarioStatuses)) AS AssemblyPlansDisassemblyRevolutions
	|
	|UNION ALL
	|
	|SELECT
	|	PlansForConsumptionOfComponentsTurnover.Products,
	|	PlansForConsumptionOfComponentsTurnover.Characteristic,
	|	PlansForConsumptionOfComponentsTurnover.Purpose,
	|	PlansForConsumptionOfComponentsTurnover.Scenario,
	|	PlansForConsumptionOfComponentsTurnover.PlanProfile,
	|	PlansForConsumptionOfComponentsTurnover.Period,
	|	0,
	|	CASE
	|		WHEN PlansForConsumptionOfComponentsTurnover.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
	|			THEN PlansForConsumptionOfComponentsTurnover.CountTurnover
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN PlansForConsumptionOfComponentsTurnover.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
	|			THEN PlansForConsumptionOfComponentsTurnover.CountTurnover
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN PlansForConsumptionOfComponentsTurnover.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|			THEN PlansForConsumptionOfComponentsTurnover.CountTurnover
	|		ELSE 0
	|	END,
	|	0,
	|	0,
	|	0,
	|	0,
	|	FALSE
	|FROM
	|	AccumulationRegister.ComponentsConsumptionPlans.Turnovers(
	|			,
	|			,
	|			Month,
	|			&PlanType = VALUE(Enum.TypesOfPlans.AssemblyDisassemblyPlan)
	|				AND Scenario = &Scenario
	|				AND PlanProfile = &PlanProfile
	|				AND Status IN (&ScenarioStatuses)) AS PlansForConsumptionOfComponentsTurnover
	|
	|UNION ALL
	|
	|SELECT
	|	ReleasePlansProducts_Turnovers.Products,
	|	ReleasePlansProducts_Turnovers.Characteristic,
	|	ReleasePlansProducts_Turnovers.Purpose,
	|	ReleasePlansProducts_Turnovers.Scenario,
	|	ReleasePlansProducts_Turnovers.PlanProfile,
	|	ReleasePlansProducts_Turnovers.Period,
	|	0,
	|	ReleasePlansProducts_Turnovers.CountTurnover,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	FALSE
	|FROM
	|	AccumulationRegister.ReleasePlansProducts_.Turnovers(
	|			,
	|			,
	|			Month,
	|			&PlanType = VALUE(Enum.TypesOfPlans.ProductionPlan)
	|				AND Scenario = &Scenario
	|				AND PlanProfile = &PlanProfile
	|				AND Status IN (&ScenarioStatuses)) AS ReleasePlansProducts_Turnovers
	|
	|UNION ALL
	|
	|SELECT
	|	ProductionPlansTurnovers.Products,
	|	ProductionPlansTurnovers.Characteristic,
	|	ProductionPlansTurnovers.Purpose,
	|	ProductionPlansTurnovers.Scenario,
	|	ProductionPlansTurnovers.PlanProfile,
	|	ProductionPlansTurnovers.Period,
	|	0,
	|	0,
	|	ProductionPlansTurnovers.CountTurnover,
	|	0,
	|	0,
	|	ProductionPlansTurnovers.DemandRangeIsSpecifiedTurnover,
	|	ProductionPlansTurnovers.RangeOfDemandFromTurnover,
	|	ProductionPlansTurnovers.RangeOfDemandToTurnover,
	|	FALSE
	|FROM
	|	AccumulationRegister.ProductionPlans.Turnovers(
	|			,
	|			,
	|			Month,
	|			&PlanType = VALUE(Enum.TypesOfPlans.ProductionPlan)
	|				AND Scenario = &Scenario
	|				AND PlanProfile = &PlanProfile
	|				AND Status IN (&ScenarioStatuses)) AS ProductionPlansTurnovers
	|
	|UNION ALL
	|
	|SELECT
	|	MaterialConsumptionPlansTurnovers.Products,
	|	MaterialConsumptionPlansTurnovers.Characteristic,
	|	MaterialConsumptionPlansTurnovers.Purpose,
	|	MaterialConsumptionPlansTurnovers.Scenario,
	|	MaterialConsumptionPlansTurnovers.PlanProfile,
	|	MaterialConsumptionPlansTurnovers.Period,
	|	0,
	|	0,
	|	0,
	|	MaterialConsumptionPlansTurnovers.CountTurnover,
	|	0,
	|	0,
	|	0,
	|	0,
	|	FALSE
	|FROM
	|	AccumulationRegister.MaterialConsumptionPlans.Turnovers(
	|			,
	|			,
	|			Month,
	|			&PlanType = VALUE(Enum.TypesOfPlans.ProductionPlan)
	|				AND Scenario = &Scenario
	|				AND PlanProfile = &PlanProfile
	|				AND Status IN (&ScenarioStatuses)) AS MaterialConsumptionPlansTurnovers
	|
	|UNION ALL
	|
	|SELECT
	|	AdjustmentsToPlannedDemandsTurnovers.Products,
	|	AdjustmentsToPlannedDemandsTurnovers.Characteristic,
	|	AdjustmentsToPlannedDemandsTurnovers.Purpose,
	|	AdjustmentsToPlannedDemandsTurnovers.Scenario,
	|	AdjustmentsToPlannedDemandsTurnovers.PlanProfile,
	|	AdjustmentsToPlannedDemandsTurnovers.Period,
	|	0,
	|	0,
	|	0,
	|	0,
	|	AdjustmentsToPlannedDemandsTurnovers.CountTurnover,
	|	0,
	|	0,
	|	0,
	|	FALSE
	|FROM
	|	AccumulationRegister.AdjustmentsToPlannedDemands.Turnovers(, , Month, Scenario = &Scenario AND PlanProfile = &PlanProfile) AS AdjustmentsToPlannedDemandsTurnovers
	|
	|UNION ALL
	|
	|SELECT
	|	CalculationOfPlanShortagesByStages.Products,
	|	CalculationOfPlanShortagesByStages.Characteristic,
	|	CalculationOfPlanShortagesByStages.Purpose,
	|	CalculationOfPlanShortagesByStages.Scenario,
	|	CalculationOfPlanShortagesByStages.PlanProfile,
	|	CalculationOfPlanShortagesByStages.PlanningPeriod,
	|	CASE
	|		WHEN &PlanType = VALUE(Enum.TypesOfPlans.PlanOfGoodsStock)
	|			THEN -CalculationOfPlanShortagesByStages.OpeningBalance
	|		ELSE 0
	|	END,
	|	-CalculationOfPlanShortagesByStages.Receipt,
	|	-CalculationOfPlanShortagesByStages.ToSupply,
	|	-CalculationOfPlanShortagesByStages.Expense,
	|	-CalculationOfPlanShortagesByStages.ExpenseAdjustment,
	|	-CASE
	|		WHEN CalculationOfPlanShortagesByStages.DemandRangeIsSpecified
	|			THEN 1
	|		ELSE 0
	|	END,
	|	-CalculationOfPlanShortagesByStages.RangeOfDemandFrom,
	|	-CalculationOfPlanShortagesByStages.RangeOfDemandTo,
	|	CalculationOfPlanShortagesByStages.ShouldRecalculate
	|FROM
	|	InformationRegister.CalculationOfPlanShortagesByStages AS CalculationOfPlanShortagesByStages
	|WHERE
	|	CalculationOfPlanShortagesByStages.Scenario = &Scenario
	|	AND CalculationOfPlanShortagesByStages.PlanProfile = &PlanProfile
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Plans.Products AS Products,
	|	Plans.Characteristic AS Characteristic,
	|	Plans.Purpose AS Purpose,
	|	SUM(Plans.Expense) AS Expense,
	|	Plans.Scenario AS Scenario,
	|	Plans.PlanProfile AS PlanProfile,
	|	SUM(Plans.Receipt) AS Receipt,
	|	SUM(Plans.ToSupply) AS ToSupply,
	|	SUM(Plans.OpeningBalance) AS OpeningBalance,
	|	Plans.PlanningPeriod AS PlanningPeriod,
	|	SUM(Plans.ExpenseAdjustment) AS ExpenseAdjustment,
	|	SUM(Plans.DemandRangeIsSpecified) AS DemandRangeIsSpecified,
	|	SUM(Plans.RangeOfDemandFrom) AS RangeOfDemandFrom,
	|	SUM(Plans.RangeOfDemandTo) AS RangeOfDemandTo,
	|	MAX(Plans.ShouldRecalculate) AS ShouldRecalculate
	|INTO PlansAndCalculationOfTurnover
	|FROM
	|	Plans AS Plans
	|
	|GROUP BY
	|	Plans.Products,
	|	Plans.Characteristic,
	|	Plans.Purpose,
	|	Plans.Scenario,
	|	Plans.PlanProfile,
	|	Plans.PlanningPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlansAndCalculationOfTurnover.Scenario AS Scenario,
	|	PlansAndCalculationOfTurnover.PlanProfile AS PlanProfile,
	|	PlansAndCalculationOfTurnover.PlanningPeriod AS PlanningPeriod,
	|	PlansAndCalculationOfTurnover.Products AS Products,
	|	PlansAndCalculationOfTurnover.Characteristic AS Characteristic,
	|	PlansAndCalculationOfTurnover.Purpose AS Purpose
	|FROM
	|	PlansAndCalculationOfTurnover AS PlansAndCalculationOfTurnover
	|WHERE
	|	(PlansAndCalculationOfTurnover.Expense <> 0
	|			OR PlansAndCalculationOfTurnover.Receipt <> 0
	|			OR PlansAndCalculationOfTurnover.ToSupply <> 0
	|			OR PlansAndCalculationOfTurnover.OpeningBalance <> 0
	|			OR PlansAndCalculationOfTurnover.ExpenseAdjustment <> 0
	|			OR PlansAndCalculationOfTurnover.DemandRangeIsSpecified <> 0
	|			OR PlansAndCalculationOfTurnover.RangeOfDemandFrom <> 0
	|			OR PlansAndCalculationOfTurnover.RangeOfDemandTo <> 0)";
	
	ScenarioStatuses = New Array;
	ScenarioStatuses.Add(Enums.PlanStatuses.Upholded);
	ScenarioStatuses.Add(Enums.PlanStatuses.AwaitingConfirmation);
	
	PlanType = Common.ObjectAttributeValue(PlanProfile, "PlanType");
	Periodicity = Common.ObjectAttributeValue(Scenario,"Periodicity");
	
	Query.SetParameter("ScenarioStatuses", ScenarioStatuses);
	Query.SetParameter("Scenario", Scenario);
	Query.SetParameter("PlanProfile", PlanProfile);
	Query.SetParameter("PlanType", PlanType);
	Query.Text = StrReplace(Query.Text, "MONTH", GetPeriodicityByText(Periodicity));

	SetPrivilegedMode(True);
	Result = Query.Execute().Unload();
	
	RecordSet = InformationRegisters.ShortagesCalculationQueueInStages.CreateRecordSet();
	RecordSet.Filter.Scenario.Set(Scenario);
	RecordSet.Filter.PlanProfile.Set(PlanProfile);
	
	RecordSet.Load(Result);
	RecordSet.Write();
	
	SetPrivilegedMode(False);
		
	Return Result.Count()>0;
	
EndFunction

// The procedure starts the background calculation of deficits by stages
// Parameters:
//  Scenario - CatalogRef.SalesOperationsPlanningScenarios - the scenario for which the calculation is performed.
//
Procedure StartingBackgroundCalculationOfDeficitInStages(Scenario) Export
	
	Var_Key = "CalculationOfPlanShortagesByStages" + Scenario.UUID();
	Filter = New Structure();
	Filter.Insert("Key", Var_Key);
	Filter.Insert("State", BackgroundJobState.Active);
	
	SetPrivilegedMode(True);
	
	ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	
	SetPrivilegedMode(False);
	
	If ActiveTasks.Count() > 0 Then
		Return;
	EndIf;
	
	JobDescription = NStr("vi = 'Tính toán thâm hụt kế hoạch theo các kỳ';
							|ru = 'Расчет дефицитов планов по этапам';
							|en = 'Calculation of plan shortages by stages'; fa = 'محاسبه کسری‌های برنامه بر اساس مراحل';
							|it = 'Calcolo dei deficit dei piani per le fasi';
							|pl = 'Obliczenie niedoborów planów według etapów';
							|tr = 'Aşamalara göre açık hesaplaması'");
	
	ExportProcedureName = "Planning.PerformBackgroundCalculationOfDeficitsByStages";
	
	ExportProcedureParameters = New Array();
	ParametersStructure = New Structure("ErrorsCount,Scenario");
	ParametersStructure.ErrorsCount = 0;
	ParametersStructure.Scenario = Scenario;
	ExportProcedureParameters.Add(ParametersStructure);
	
	JobParameters = New Array();
	JobParameters.Add(ExportProcedureName);
	JobParameters.Add(ExportProcedureParameters);
	
	BackgroundJobs.Execute("Common.ExecuteConfigurationMethod", JobParameters, Var_Key, JobDescription);
	
EndProcedure

// The procedure performs background calculation of deficits by stages
//
// Parameters:
//  JobParameters  - Structure - the structure stores the number of errors if error is larger than a certain limit,
//                                  the job will be completed.
//
Procedure PerformBackgroundCalculationOfDeficitsByStages(JobParameters) Export
	
	If JobParameters.Property("ErrorsCount") Then
		
		MaximumNumberOfErrors = 3;
		
		If JobParameters.ErrorsCount >= MaximumNumberOfErrors Then
			
			DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
			
			MessageText = NStr("vi = 'Nhiệm vụ nền tính toán thâm hụt kế hoạch theo các kỳ được dừng lại. Số lần thử thất bại: %ErrorsCount%';
								|ru = 'Фоновый расчет дефицитов планов по этапам остановлен. Количество неудачных попыток: %ErrorsCount%';
								|en = 'Background calculation of plan shortages by stages was stopped. Number of unsuccessful attempts: %ErrorsCount%'; fa = 'Background calculation of plan shortages by stages was stopped. Number of unsuccessful attempts: %ErrorsCount%';
								|it = 'Calcolo in background dei deficit per le fasi è fermato.La quantità di tentativi falliti:%ErrorsCount%';
								|pl = 'Obliczenia w tle niedoborów planów według etapów zostały zatrzymane. Liczba nieudanych prób: %ErrorsCount%';
								|tr = 'Aşamalara göre plan mali açıklarının arka planda hesaplanması durduruldu. Başarısız deneme sayısı: %ErrorsCount%'");
			MessageText = StrReplace(MessageText, "%ErrorsCount%", JobParameters.ErrorsCount);
			
			WriteLogEvent(NStr("vi = 'Nhiệm vụ nền tính toán thâm hụt kế hoạch theo các kỳ';
								|ru = 'Фоновый расчет дефицитов планов по этапам';
								|en = 'Background calculation of plan shortages by stages'; fa = 'Background calculation of plan shortages by stages';
								|it = 'Calcolo in background dei deficit dei piani per le fasi';
								|pl = 'Obliczenia w tle niedoborów planów według etapów';
								|tr = 'Aşamalara göre plan mali açıklarının arka planda hesaplanması'", DefaultLanguageCode),
				EventLogLevel.Error, , ,
				MessageText);
			
			Return;
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	
	CheckingCompletionOfCalculationOfProductionPlansAndReplacementPlans(JobParameters.Scenario);
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.ShortagesCalculationQueueInStages");
		LockItem.SetValue("Scenario", JobParameters.Scenario);
		LockItem.Mode = DataLockMode.Exclusive;
		
		Block.Lock();
		
		Query = New Query();
		Query.Text = 
		"SELECT TOP 1
		|	ShortagesCalculationQueueInStages.PlanningPeriod AS PlanningPeriod
		|FROM
		|	InformationRegister.ShortagesCalculationQueueInStages AS ShortagesCalculationQueueInStages
		|WHERE
		|	ShortagesCalculationQueueInStages.Scenario = &Scenario
		|
		|ORDER BY
		|	ShortagesCalculationQueueInStages.PlanningPeriod";
		Query.SetParameter("Scenario", JobParameters.Scenario);
		Selection = Query.Execute().Select();
		
		ThereIsDataForRecalculation = False;
		
		While Selection.Next() Do
			ThereIsDataForRecalculation = True;
			
			Block = New DataLock;
			
			LockItem = Block.Add("InformationRegister.CalculationOfPlanShortagesByStages");
			LockItem.SetValue("Scenario", JobParameters.Scenario);
			LockItem.SetValue("PlanningPeriod", Selection.PlanningPeriod);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			JobParameters.Insert("Period", Selection.PlanningPeriod);
			CalculationResults = CalculateDeficitsByStages(JobParameters.Scenario, Selection.PlanningPeriod);
			
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
		JobParameters.ErrorsCount = JobParameters.ErrorsCount + 1;
		
		MessageText = NStr("vi = 'Không thể phong tỏa biểu ghi ""Hàng đợi để tính toán thâm hụt theo kế hoạch"" bởi nhiệm vụ nền. Số lần thử: %ErrorsCount%';
							|ru = 'Не удалось выполнить блокировку регистра ""Очередь расчета дефицитов по планам"" фоновым заданием. Количество попыток: %ErrorsCount%';
							|en = 'Failed to lock registers ""Queue for calculation of shortages by plans"" with background job. Number of attempts: %ErrorsCount%'; fa = 'Failed to lock registers ""Queue for calculation of shortages by plans"" with background job. Number of attempts: %ErrorsCount%';
							|it = 'Non è stato possibile eseguire il blocco del registro ""Coda di calcolo dei deficit in base ai piani"" con il task in background.La quantità dei tentativi:%ErrorsCount%';
							|pl = 'Nie udało się wykonać blokadę rejestru ""Kolejka obliczenia niedoborów według planów"" zadaniem w tle. Ilość prób: %ErrorsCount%';
							|tr = 'Arka plan işlerindeki ""Aşamalara göre mali açık hesaplamalarının sırası"" kaydının kilitlenmesi işlemi gerçekleştirilemedi. Deneme sayısı: %ErrorsCount%'");
			MessageText = StrReplace(MessageText, "%ErrorsCount%", JobParameters.ErrorsCount);
		
			WriteLogEvent(NStr("vi = 'Nhiệm vụ nền tính toán thâm hụt kế hoạch theo các kỳ';
								|ru = 'Фоновый расчет дефицитов планов по этапам';
								|en = 'Background calculation of plan shortages by stages'; fa = 'Background calculation of plan shortages by stages';
								|it = 'Calcolo in background dei deficit dei piani per le fasi';
								|pl = 'Obliczenia w tle niedoborów planów według etapów';
								|tr = 'Aşamalara göre plan mali açıklarının arka planda hesaplanması'", DefaultLanguageCode),
				EventLogLevel.Error,
				,
				,
				MessageText);
				
		PerformBackgroundCalculationOfDeficitsByStages(JobParameters);
		Return;
	EndTry;
	
	If ValueIsFilled(CalculationResults)
		And CalculationResults.SetAdjustmentsForVerificationRequirements Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	DemandAdjustmentsQueueToRecalculate.Scenario AS Scenario,
		|	DemandAdjustmentsQueueToRecalculate.DemandPeriod AS DemandPeriod,
		|	DemandAdjustmentsQueueToRecalculate.AdjustmentOfPlannedDemand AS AdjustmentOfPlannedDemand
		|FROM
		|	InformationRegister.DemandAdjustmentsQueueToRecalculate AS DemandAdjustmentsQueueToRecalculate
		|WHERE
		|	DemandAdjustmentsQueueToRecalculate.Scenario = &Scenario
		|	AND DemandAdjustmentsQueueToRecalculate.AdjustmentOfPlannedDemand.Posted";
		
		Query.SetParameter("Scenario", JobParameters.Scenario);
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			BeginTransaction();
			
			Try
				
				If ValueIsFilled(Selection.AdjustmentOfPlannedDemand) Then
					
					AdjustmentOfPlannedNeeds = Selection.AdjustmentOfPlannedDemand.GetObject(); // DocumentObject.AdjustmentOfPlannedDemand -
					
				Else
					
					RollbackTransaction();
					Continue;
					
				EndIf;
				
				Block = New DataLock;
				LockItem = Block.Add("InformationRegister.DemandAdjustmentsQueueToRecalculate");
				LockItem.Mode = DataLockMode.Exclusive;
				LockItem.SetValue("AdjustmentOfPlannedDemand", Selection.AdjustmentOfPlannedDemand);
				Block.Lock();
				
				AdjustmentOfPlannedNeeds.Status = Enums.StatusesOfPlanAdjustments.ForChecking;
				AdjustmentOfPlannedNeeds.Write(DocumentWriteMode.Write);
				
				RecordSet = InformationRegisters.DemandAdjustmentsQueueToRecalculate.CreateRecordSet();
				RecordSet.Filter.AdjustmentOfPlannedDemand.Set(Selection.AdjustmentOfPlannedDemand);
				RecordSet.Write();
				
				CommitTransaction();
			Except
				RollbackTransaction();
				
				DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
				
				MessageText = NStr("vi = 'Không thể hoàn thành các kế hoạch thâm hụt do %Cause%';
									|ru = 'Не удалось выполнить формирование планов по дефициту по причине %Cause%';
									|en = 'Cannot form plans by shortage. Reason: %Cause%'; fa = 'Cannot form plans by shortage. Reason: %Cause%';
									|it = 'Non è stato possibile effettuare la generazione dei piani relativi al budget a causa di %Cause%';
									|pl = 'Nie udało się wykonać tworzenie planów według niedoboru z powodu %Cause%';
									|tr = '%Cause% sebebiyle mali açığa göre planının oluşturulması işlemi yerine getirilemedi'");
				MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
				
				WriteLogEvent(NStr("vi = 'Kế hoạch thiếu hụt';
									|ru = 'Формирование планов по дефициту';
									|en = 'Form plans by shortage'; fa = 'Form plans by shortage';
									|it = 'Generazione dei piani relativi al budget';
									|pl = 'Tworzenie planów według niedoboru';
									|tr = 'Mali açığa göre plan oluşturma'", DefaultLanguageCode),
				EventLogLevel.Error,
				,
				,
				MessageText);
				Raise;
			EndTry;
			
			
			
		EndDo;
		
	EndIf;
	
	If ThereIsDataForRecalculation Then
		PerformBackgroundCalculationOfDeficitsByStages(JobParameters);
	Else
		CalculateAndFillDeficitPlansAutomatically(JobParameters.Scenario);
	EndIf;
	
EndProcedure

Function CalculateDeficitsByStages(Scenario, Period) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("InventoryPlanning.CalculationOfShortagesInStages");
	
	BeginOfPeriod = Period;
	Periodicity = Common.ObjectAttributeValue(Scenario,"Periodicity");
	EndOfPeriod = TMCommonUseClientServer.CalculatePeriodEndDate(BeginOfPeriod, Periodicity, 1);
	
	CalculationStructure = New Structure("SetAdjustmentsForVerificationRequirements");
	CalculationStructure.Insert("SetAdjustmentsForVerificationRequirements", False);
	
	//Calculation of the period of the last record of balances
	Query = New Query();
	Query.Text = 
	"SELECT TOP 1
	|	PlansOfGoodsStock.Period AS Period
	|FROM
	|	AccumulationRegister.PlansOfGoodsStock.Turnovers(&BeginOfPeriod, &EndOfPeriod, Month, Scenario = &Scenario AND Status IN(&ScenarioStatuses)) AS PlansOfGoodsStock
	|WHERE
	|	PlansOfGoodsStock.Period = &BeginOfPeriod";
	
	ScenarioStatuses = New Array;
	ScenarioStatuses.Add(Enums.PlanStatuses.Upholded);
	ScenarioStatuses.Add(Enums.PlanStatuses.AwaitingConfirmation);
	
	Query.SetParameter("ScenarioStatuses", ScenarioStatuses);
	Query.SetParameter("Scenario", Scenario);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	
	Query.Text = StrReplace(Query.Text, "MONTH", GetPeriodicityByText(Periodicity));
	
	Selection = Query.Execute().Select();
	ThereArePlannedRemnants =  Selection.Next();
	
	Query = New Query();
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	PlanProfiles.Ref AS PlanProfile,
	|	PlanProfiles.PlanningProcedure AS PlanningProcedure,
	|	ISNULL(PlanProfiles.Parent.PlanningProcedure, PlanProfiles.PlanningProcedure) AS StagePlanningOrder,
	|	CASE
	|		WHEN PlanProfiles.Parent.PlanningProcedure IS NULL
	|			THEN PlanProfiles.Ref
	|		ELSE PlanProfiles.Parent
	|	END AS PlanningStage,
	|	PlanProfiles.IsFolder AS IsFolder,
	|	ISNULL(PlanProfiles.FillInByShortage, FALSE) AS FillInByShortage,
	|	ISNULL(PlanProfiles.ContentFillingVariant, """") AS ContentFillingVariant,
	|	PlanProfiles.DemandPlanning AS DemandPlanning,
	|	PlanProfiles.PlanningOfGoodsStock AS PlanningOfGoodsStock
	|INTO PlansStructure
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.Owner = &Scenario
	|	AND NOT PlanProfiles.DeletionMark
	|	AND NOT(PlanProfiles.PlanType <> VALUE(Enum.TypesOfPlans.PlanOfGoodsStock)
	|				AND PlanProfiles.Parent = VALUE(Catalog.PlanProfiles.EmptyRef)
	|				AND NOT PlanProfiles.IsFolder)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Catalog.PlanProfiles.EmptyRef),
	|	999,
	|	999,
	|	VALUE(Catalog.PlanProfiles.EmptyRef),
	|	TRUE,
	|	FALSE,
	|	"""",
	|	FALSE,
	|	FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ShortagesCalculationQueueInStages.Scenario AS Scenario,
	|	ShortagesCalculationQueueInStages.PlanningPeriod AS PlanningPeriod,
	|	VALUE(Catalog.PlanProfiles.EmptyRef) AS PlanProfile,
	|	ShortagesCalculationQueueInStages.Products AS Products,
	|	ShortagesCalculationQueueInStages.Characteristic AS Characteristic,
	|	ShortagesCalculationQueueInStages.Purpose AS Purpose
	|INTO ShortagesCalculationQueueInStages
	|FROM
	|	InformationRegister.ShortagesCalculationQueueInStages AS ShortagesCalculationQueueInStages
	|WHERE
	|	ShortagesCalculationQueueInStages.PlanningPeriod BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND ShortagesCalculationQueueInStages.Scenario = &Scenario
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	ResourceSpecificationsOutputProducts.Products AS Products,
	|	ISNULL(ResourceSpecificationsOutputProducts.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS Characteristic,
	|	""ProductsAndSemiFinishedProducts"" AS TypeOfProduct,
	|	ResourceSpecificationsOutputProducts.Products.UseVariants AS UseVariants,
	|	ResourceSpecificationsOutputProducts.ProductKind AS ProductKind,
	|	ResourceSpecificationsOutputProducts.Products.ItemVariantsOwner AS ItemVariantsOwner
	|INTO BillsOfMaterials
	|FROM
	|Catalog.BillsOfMaterials AS BillsOfMaterials
	|	LEFT JOIN Catalog.BillsOfMaterials.ManufacturedProducts AS ResourceSpecificationsOutputProducts
	|	ON (ResourceSpecificationsOutputProducts.Ref = BillsOfMaterials.Ref)
	|WHERE
	|	NOT BillsOfMaterials.DeletionMark
	|	AND BillsOfMaterials.Status = VALUE(Enum.BOMStatuses.Valid)
	|	AND BillsOfMaterials.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Assembly)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CatProducts.ProductKind AS ProductKind,
	|	ProductKitConfigurations.Owner AS Products,
	|	ISNULL(ProductKitConfigurations.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS Characteristic,
	|	""Kits"" AS TypeOfProduct
	|INTO TTKitsAndSpecifications
	|FROM
	|	Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|	LEFT JOIN Catalog.Products AS CatProducts
	|	ON CatProducts.Ref = ProductKitConfigurations.Owner
	|WHERE
	|	NOT ProductKitConfigurations.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	BillsOfMaterials.ProductKind AS ProductKind,
	|	BillsOfMaterials.Products AS Products,
	|	ItemsCharacteristics.Ref AS Characteristic,
	|	BillsOfMaterials.TypeOfProduct AS TypeOfProduct
	|FROM
	|	BillsOfMaterials AS BillsOfMaterials
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON (CASE
	|				WHEN BillsOfMaterials.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|					THEN BillsOfMaterials.Products
	|				WHEN BillsOfMaterials.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|					THEN BillsOfMaterials.ProductKind
	|				WHEN BillsOfMaterials.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|					THEN BillsOfMaterials.ItemVariantsOwner
	|				ELSE UNDEFINED
	|			END = ItemsCharacteristics.Owner)
	|WHERE
	|	BillsOfMaterials.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|	AND (BillsOfMaterials.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|		OR BillsOfMaterials.UseVariants IS NULL)
	|
	|UNION ALL
	|
	|SELECT
	|	BillsOfMaterials.ProductKind AS ProductKind,
	|	BillsOfMaterials.Products,
	|	BillsOfMaterials.Characteristic,
	|	BillsOfMaterials.TypeOfProduct
	|FROM
	|	BillsOfMaterials AS BillsOfMaterials
	|WHERE
	|	BillsOfMaterials.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|	OR BillsOfMaterials.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|;
	|
	|SELECT DISTINCT
	|	PlansStructure.PlanProfile AS PlanProfile,
	|	PlansStructure.ContentFillingVariant AS ContentFillingVariant,
	|	ShortagesCalculationQueueInStages.Products AS Products, 
	|	ShortagesCalculationQueueInStages.Products.ProductKind AS ProductKind,
	|	ShortagesCalculationQueueInStages.Characteristic AS Characteristic 
	|INTO TableOfProductsByTypeOfPlans
	|FROM
	|	PlansStructure AS PlansStructure,
	|	ShortagesCalculationQueueInStages AS ShortagesCalculationQueueInStages
	|WHERE
	|	NOT PlansStructure.IsFolder
	|	AND PlansStructure.FillInByShortage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfProductsByTypeOfPlans.PlanProfile AS PlanProfile,
	|	TableOfProductsByTypeOfPlans.ContentFillingVariant AS ContentFillingVariant,
	|	TableOfProductsByTypeOfPlans.Products AS Products,
	|	TableOfProductsByTypeOfPlans.Characteristic AS Characteristic,
	|	KitsAndSpecifications.ProductKind AS ProductKind,
	|	KitsAndSpecifications.TypeOfProduct AS TypeOfProduct
	|FROM
	|	TableOfProductsByTypeOfPlans AS TableOfProductsByTypeOfPlans
	|	LEFT JOIN TTKitsAndSpecifications AS KitsAndSpecifications
	|	ON CASE
	|		WHEN KitsAndSpecifications.Products = VALUE(Catalog.Products.EmptyRef)
	|			THEN TableOfProductsByTypeOfPlans.ProductKind = KitsAndSpecifications.ProductKind
	|		ELSE TableOfProductsByTypeOfPlans.Products = KitsAndSpecifications.Products
	|	END
	|	AND CASE
	|		WHEN KitsAndSpecifications.Products = VALUE(Catalog.Products.EmptyRef)
	|			THEN TRUE
	|		ELSE TableOfProductsByTypeOfPlans.Characteristic = KitsAndSpecifications.Characteristic
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlanProfiles.Ref AS Ref,
	|	PlanProfiles.SettingsStructure AS SettingsStructure
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles
	|WHERE
	|	PlanProfiles.Owner = &Scenario
	|	AND PlanProfiles.ContentFillingVariant LIKE ""Filter""";
	
	Query.SetParameter("Scenario",Scenario);
	Query.SetParameter("BeginOfPeriod",BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",EndOfPeriod);
	
	RequestPackage = Query.ExecuteBatch();
	TableOfProductsByTypeOfPlans = RequestPackage[RequestPackage.UBound() - 1].Unload();
	DatasetsObjects = New Structure;
	DatasetsObjects.Insert("TableOfProductsByTypeOfPlans", TableOfProductsByTypeOfPlans);
	DCS_PlanItemsFilterByShortages = Catalogs.PlanProfiles.GetTemplate("PlanItemsFilterByShortages"); 
	CollectionOfSets = DCS_PlanItemsFilterByShortages.DataSets.DataSetAndDerivativeSelections; // DataCompositionTemplateDataSetUnion -
	
	SelectionTypesOfPlansWithSelection = RequestPackage[RequestPackage.UBound()].Select();
	Counter = 0;
	While SelectionTypesOfPlansWithSelection.Next() Do
		
		Counter = Counter + 1;
		
		StorageOfSettingsStructure = SelectionTypesOfPlansWithSelection.SettingsStructure;// ValueStorage
		SettingsStructure = StorageOfSettingsStructure.Get();
		
		SelectingProductsForTypeOfPlans = New ValueTable;
		
		// scheme of the layout.
		DataCompositionSchema = DataProcessors.GoodsSelectionByPicking.GetTemplate("Template");
		
		// Preparing the data layout layout builder.
		Composer = New DataCompositionSettingsComposer;
		Composer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
		Composer.LoadSettings(DataCompositionSchema.DefaultSettings);
		Composer.Settings.Filter.Items.Clear();
		Composer.Refresh(DataCompositionSettingsRefreshMethod.Full);
		
		// Selection and sorting of the settings linker.
		If SettingsStructure.SelectionOfProductsSettings <> Undefined Then
			
			DataCompositionClientServer.CopyElements(
				Composer.Settings.Filter,
				SettingsStructure.SelectionOfProductsSettings.Filter);
			
		EndIf;
		
		RequiredFields = New Array;
		RequiredFields.Add("Products");
		RequiredFields.Add("Characteristic");
		RequiredFields.Add("PlanProfile");
		RequiredFields.Add("ArbitraryFilter");
		
		// Selected fields of the settings builder.
		For Each RequiredField In RequiredFields Do
			DCSField = DataCompositionServer.FindDCSFieldByFullName(Composer.Settings.Selection.SelectionAvailableFields.Items, RequiredField);
			If DCSField <> Undefined Then
				SelectedField = Composer.Settings.Selection.Items.Add(Type("DataCompositionSelectedField"));
				SelectedField.Field = DCSField.Field;
			EndIf;
		EndDo;
		
		// A subquery.
		RequestTextQueueSourceData = 
		"SELECT DISTINCT
		|	ShortagesCalculationQueueInStages.Products AS Products,
		|	ShortagesCalculationQueueInStages.Characteristic AS Characteristic,
		|	&PlanProfile AS PlanProfile,
		|	0 AS InStockBalance
		|INTO RawData
		|FROM
		|	InformationRegister.ShortagesCalculationQueueInStages AS ShortagesCalculationQueueInStages
		|WHERE
		|	ShortagesCalculationQueueInStages.PlanningPeriod BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND ShortagesCalculationQueueInStages.Scenario = &Scenario
		|
		|INDEX BY
		|	Products,
		|	Characteristic";
		
		InitialQuery = DataCompositionSchema.DataSets.DataSet.Query;
		
		PositionTTRawData = StrFind(InitialQuery, "INTO RawData");
		StartTTRawData = StrFind(InitialQuery, "/", SearchDirection.FromEnd, PositionTTRawData)+1;
		EndTTSourceData = StrFind(InitialQuery, ";", SearchDirection.FromBegin, PositionTTRawData)-1;
		NewQuery = Left(InitialQuery, StartTTRawData) + RequestTextQueueSourceData + Right(InitialQuery, StrLen(InitialQuery) - EndTTSourceData);
		
		DataCompositionSchema.DataSets.DataSet.Query = NewQuery;
		
		// Layout layout of the data layout.
		TemplateComposer = New DataCompositionTemplateComposer;
		DataCompositionTemplate = TemplateComposer.Execute(
			DataCompositionSchema,
			Composer.GetSettings(),,,
			Type("DataCompositionValueCollectionTemplateGenerator"));
			
		QueryText = DataCompositionTemplate.DataSets.DataSet.Query;
		OrderItems = Composer.GetSettings().Order.Items;
		
		OrderText_ = "";
		For Each OrderItem In OrderItems Do
			If OrderItem.Use And ValueIsFilled(OrderItem.Field) Then
				OrderString = String(OrderItem.Field) +
				?(OrderItem.OrderType = DataCompositionSortDirection.Asc," ASC", " DESC") + ", ";
				OrderText_ = OrderText_ + OrderString;
			EndIf;
		EndDo;
		
		If ValueIsFilled(OrderText_) Then
			OrderText_ = Left(OrderText_, StrLen(OrderText_)-2);
		Else
			OrderText_ = "SourceDataLastRequest.Products.Description ASC"
		EndIf;
		
		QueryText = QueryText + " ORDER BY " + OrderText_;
		
		QueryText = StrReplace(QueryText, "VALUE(Catalog.PlanProfiles.EmptyRef)", "&PlanProfile");
		
		ProductSelectionRequest = New Query(QueryText);
		
		// Filling in parameters from the selection fields of the processing form settings linker.
		For Each Parameter In DataCompositionTemplate.ParameterValues Do
			ProductSelectionRequest.Parameters.Insert(Parameter.Name, Parameter.Value);
		EndDo;
		
		ProductSelectionRequest.Parameters.Insert("Scenario", Scenario);
		ProductSelectionRequest.Parameters.Insert("PlanProfile", SelectionTypesOfPlansWithSelection.Ref);
		ProductSelectionRequest.Parameters.Insert("BeginOfPeriod", BeginOfPeriod);
		ProductSelectionRequest.Parameters.Insert("EndOfPeriod", EndOfPeriod);
		
		SelectingProductsForTypeOfPlans = ProductSelectionRequest.Execute().Unload();
		
		// Adding a data set to the scd
		DatasetObject = CollectionOfSets.Items.Add(Type("DataCompositionSchemaDataSetObject")); // DataCompositionSchemaDataSetObject - 
		DatasetObject.Name = "DataSet"+Counter;
		DatasetObject.DataSource = DCS_PlanItemsFilterByShortages.DataSources[0].Name;
		DatasetObject.ObjectName  = "DataSet"+Counter;
		For Each Field In CollectionOfSets.Items[0].Fields Do
			DataSetField = DatasetObject.Fields.Add(TypeOf(Field));
			FillPropertyValues(DataSetField, Field);
		EndDo;
		
		DatasetsObjects.Insert("DataSet"+Counter, SelectingProductsForTypeOfPlans);
		
	EndDo;
	
	If CollectionOfSets.Items.Count() > 1 Then
		CollectionOfSets.Items.Delete(CollectionOfSets.Items[0]);
	Else
		DatasetsObjects.Insert("DataSet0", New ValueTable);
	EndIf;
	
	// SKD loading
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DCS_PlanItemsFilterByShortages));
	SettingsComposer.LoadSettings(DCS_PlanItemsFilterByShortages.DefaultSettings);
	SettingsComposer.Refresh();
	
	// Layout layout
	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(DCS_PlanItemsFilterByShortages, SettingsComposer.GetSettings(),,, Type("DataCompositionValueCollectionTemplateGenerator"));
	
	// Initializing the layout processor
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate, DatasetsObjects);
	
	// Getting the result
	DataCompositionResultValueCollectionOutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	SelectionOfProductsByTypeOfPlans = New ValueTable;
	DataCompositionResultValueCollectionOutputProcessor.SetObject(SelectionOfProductsByTypeOfPlans);
	DataCompositionResultValueCollectionOutputProcessor.Output(DataCompositionProcessor);
	
	Query.Text =
	"SELECT
	|	CAST(SelectionOfProductsByTypeOfPlans.PlanProfile AS Catalog.PlanProfiles) AS PlanProfile,
	|	SelectionOfProductsByTypeOfPlans.ProductKind AS ProductKind,
	|	SelectionOfProductsByTypeOfPlans.Products AS Products,
	|	SelectionOfProductsByTypeOfPlans.Characteristic AS Characteristic
	|INTO SelectionOfProductsByTypeOfPlans
	|FROM
	|	&SelectionOfProductsByTypeOfPlans AS SelectionOfProductsByTypeOfPlans
	|WHERE
	|	(SelectionOfProductsByTypeOfPlans.HasFilter
	|			OR SelectionOfProductsByTypeOfPlans.ArbitraryFilter)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SelectionOfProductsByTypeOfPlans.PlanProfile.Parent AS PlanProfile,
	|	SelectionOfProductsByTypeOfPlans.Products AS Products,
	|	SelectionOfProductsByTypeOfPlans.Characteristic AS Characteristic
	|INTO SelectionOfProductsByTypesOfPlansAndStages
	|FROM
	|	SelectionOfProductsByTypeOfPlans AS SelectionOfProductsByTypeOfPlans
	|
	|UNION ALL
	|
	|SELECT
	|	SelectionOfProductsByTypeOfPlans.PlanProfile,
	|	SelectionOfProductsByTypeOfPlans.Products,
	|	SelectionOfProductsByTypeOfPlans.Characteristic
	|FROM
	|	SelectionOfProductsByTypeOfPlans AS SelectionOfProductsByTypeOfPlans
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationOfPlanShortagesByStages.Products AS Products,
	|	CalculationOfPlanShortagesByStages.Characteristic AS Characteristic,
	|	CalculationOfPlanShortagesByStages.Purpose AS Purpose,
	|	CalculationOfPlanShortagesByStages.PlanningPeriod AS PlanningPeriod,
	|	CalculationOfPlanShortagesByStages.Deficit AS Deficit
	|INTO CalculationOfPlanShortagesByStages
	|FROM
	|	InformationRegister.CalculationOfPlanShortagesByStages AS CalculationOfPlanShortagesByStages
	|		INNER JOIN ShortagesCalculationQueueInStages AS ShortagesCalculationQueueInStages
	|		ON (CalculationOfPlanShortagesByStages.Scenario = &Scenario)
	|			AND (CalculationOfPlanShortagesByStages.PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef))
	|			AND CalculationOfPlanShortagesByStages.Products = ShortagesCalculationQueueInStages.Products
	|			AND CalculationOfPlanShortagesByStages.Characteristic = ShortagesCalculationQueueInStages.Characteristic
	|			AND CalculationOfPlanShortagesByStages.Purpose = ShortagesCalculationQueueInStages.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationOfPlanShortagesByStages.Products AS Products,
	|	CalculationOfPlanShortagesByStages.Characteristic AS Characteristic,
	|	CalculationOfPlanShortagesByStages.Purpose AS Purpose,
	|	MAX(CalculationOfPlanShortagesByStages.PlanningPeriod) AS PlanningPeriod
	|INTO LastCalculationOfDeficitsByStages
	|FROM
	|	CalculationOfPlanShortagesByStages AS CalculationOfPlanShortagesByStages
	|WHERE
	|	NOT &ThereArePlannedRemnants
	|	AND CalculationOfPlanShortagesByStages.PlanningPeriod < &BeginOfPeriod
	|
	|GROUP BY
	|	CalculationOfPlanShortagesByStages.Products,
	|	CalculationOfPlanShortagesByStages.Characteristic,
	|	CalculationOfPlanShortagesByStages.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LastCalculationOfDeficitsByStages.Products AS Products,
	|	LastCalculationOfDeficitsByStages.Characteristic AS Characteristic,
	|	LastCalculationOfDeficitsByStages.Purpose AS Purpose,
	|	CASE
	|		WHEN CalculationOfPlanShortagesByStages.Deficit > 0
	|			THEN 0
	|		ELSE -CalculationOfPlanShortagesByStages.Deficit
	|	END AS OpeningBalance
	|INTO InitialBalancesOnSettlementRegister
	|FROM
	|	LastCalculationOfDeficitsByStages AS LastCalculationOfDeficitsByStages
	|		INNER JOIN CalculationOfPlanShortagesByStages AS CalculationOfPlanShortagesByStages
	|		ON LastCalculationOfDeficitsByStages.PlanningPeriod = CalculationOfPlanShortagesByStages.PlanningPeriod
	|			AND LastCalculationOfDeficitsByStages.Products = CalculationOfPlanShortagesByStages.Products
	|			AND LastCalculationOfDeficitsByStages.Characteristic = CalculationOfPlanShortagesByStages.Characteristic
	|			AND LastCalculationOfDeficitsByStages.Purpose = CalculationOfPlanShortagesByStages.Purpose
	|WHERE
	|	NOT &ThereArePlannedRemnants
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TurnoverBalancePlans.Period AS Period,
	|	TurnoverBalancePlans.Scenario AS Scenario,
	|	TurnoverBalancePlans.PlanProfile AS PlanProfile,
	|	TurnoverBalancePlans.Products AS Products,
	|	TurnoverBalancePlans.Characteristic AS Characteristic,
	|	TurnoverBalancePlans.Purpose AS Purpose,
	|	TurnoverBalancePlans.CountTurnover AS OpeningBalance
	|INTO PlansOfGoodsStock
	|FROM
	|	AccumulationRegister.PlansOfGoodsStock.Turnovers(
	|			&BeginOfPeriod,
	|			&EndOfPeriod,
	|			Month,
	|			Scenario = &Scenario
	|				AND Status IN (&ScenarioStatuses)
	|				AND (Products, Characteristic, Purpose) IN
	|					(SELECT
	|						T.Products AS Products,
	|						T.Characteristic AS Characteristic,
	|						T.Purpose AS Purpose
	|					FROM
	|						ShortagesCalculationQueueInStages AS T)) AS TurnoverBalancePlans
	|WHERE
	|	&ThereArePlannedRemnants
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShortagesCalculationQueueInStages.Scenario AS Scenario,
	|	ISNULL(PlansOfGoodsStock.PlanProfile, VALUE(Catalog.PlanProfiles.EmptyRef)) AS PlanProfile,
	|	ISNULL(PlansOfGoodsStock.PlanProfile, VALUE(Catalog.PlanProfiles.EmptyRef)) AS PlanningStage,
	|	ShortagesCalculationQueueInStages.PlanningPeriod AS Period,
	|	ShortagesCalculationQueueInStages.Products AS Products,
	|	ShortagesCalculationQueueInStages.Characteristic AS Characteristic,
	|	ShortagesCalculationQueueInStages.Purpose AS Purpose,
	|	0 AS PlanningProcedure,
	|	0 AS StagePlanningOrder,
	|	CASE
	|		WHEN &ThereArePlannedRemnants
	|			THEN ISNULL(PlansOfGoodsStock.OpeningBalance, 0)
	|		ELSE CASE
	|				WHEN InitialBalancesOnSettlementRegister.OpeningBalance IS NULL
	|					THEN 0
	|				ELSE InitialBalancesOnSettlementRegister.OpeningBalance
	|			END
	|	END AS OpeningBalance
	|INTO InitialResiduals
	|FROM
	|	ShortagesCalculationQueueInStages AS ShortagesCalculationQueueInStages
	|		LEFT JOIN InitialBalancesOnSettlementRegister AS InitialBalancesOnSettlementRegister
	|		ON (InitialBalancesOnSettlementRegister.Products = ShortagesCalculationQueueInStages.Products)
	|			AND (InitialBalancesOnSettlementRegister.Characteristic = ShortagesCalculationQueueInStages.Characteristic)
	|			AND (InitialBalancesOnSettlementRegister.Purpose = ShortagesCalculationQueueInStages.Purpose)
	|		LEFT JOIN PlansOfGoodsStock AS PlansOfGoodsStock
	|		ON (PlansOfGoodsStock.Scenario = ShortagesCalculationQueueInStages.Scenario)
	|			AND (PlansOfGoodsStock.Products = ShortagesCalculationQueueInStages.Products)
	|			AND (PlansOfGoodsStock.Characteristic = ShortagesCalculationQueueInStages.Characteristic)
	|			AND (PlansOfGoodsStock.Purpose = ShortagesCalculationQueueInStages.Purpose)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesPlansTurnovers.Period AS Period,
	|	SalesPlansTurnovers.Scenario AS Scenario,
	|	SalesPlansTurnovers.Products AS Products,
	|	SalesPlansTurnovers.Characteristic AS Characteristic,
	|	SalesPlansTurnovers.Purpose AS Purpose,
	|	SalesPlansTurnovers.PlanProfile AS PlanProfile,
	|	SalesPlansTurnovers.CountTurnover AS Expense,
	|	0 AS ExpenseAdjustment,
	|	0 AS Receipt,
	|	0 AS OpeningBalance,
	|	0 AS DemandRangeIsSpecified,
	|	0 AS RangeOfDemandFrom,
	|	0 AS RangeOfDemandTo,
	|	0 AS ToSupply
	|INTO TurnoverByPlanTypeWithoutGrouping
	|FROM
	|	AccumulationRegister.SalesPlans.Turnovers(
	|			&BeginOfPeriod,
	|			&EndOfPeriod,
	|			Month,
	|			Scenario = &Scenario
	|				AND Status IN (&ScenarioStatuses)
	|				AND (Products, Characteristic, Purpose) IN
	|					(SELECT
	|						T.Products AS Products,
	|						T.Characteristic AS Characteristic,
	|						T.Purpose AS Purpose
	|					FROM
	|						ShortagesCalculationQueueInStages AS T)) AS SalesPlansTurnovers
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryConsumptionPlansTurnovers.Period,
	|	InventoryConsumptionPlansTurnovers.Scenario,
	|	InventoryConsumptionPlansTurnovers.Products,
	|	InventoryConsumptionPlansTurnovers.Characteristic,
	|	InventoryConsumptionPlansTurnovers.Purpose,
	|	InventoryConsumptionPlansTurnovers.PlanProfile,
	|	InventoryConsumptionPlansTurnovers.CountTurnover,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.InventoryConsumptionPlans.Turnovers(
	|			&BeginOfPeriod,
	|			&EndOfPeriod,
	|			Month,
	|			Scenario = &Scenario
	|				AND Status IN (&ScenarioStatuses)
	|				AND (Products, Characteristic, Purpose) IN
	|					(SELECT
	|						T.Products AS Products,
	|						T.Characteristic AS Characteristic,
	|						T.Purpose AS Purpose
	|					FROM
	|						ShortagesCalculationQueueInStages AS T)) AS InventoryConsumptionPlansTurnovers
	|
	|UNION ALL
	|
	|SELECT
	|	PurchasePlansTurnovers.Period,
	|	PurchasePlansTurnovers.Scenario,
	|	PurchasePlansTurnovers.Products,
	|	PurchasePlansTurnovers.Characteristic,
	|	PurchasePlansTurnovers.Purpose,
	|	PurchasePlansTurnovers.PlanProfile,
	|	0,
	|	0,
	|	PurchasePlansTurnovers.CountTurnover,
	|	0,
	|	PurchasePlansTurnovers.DemandRangeIsSpecifiedTurnover,
	|	PurchasePlansTurnovers.RangeOfDemandFromTurnover,
	|	PurchasePlansTurnovers.RangeOfDemandToTurnover,
	|	PurchasePlansTurnovers.CountTurnover
	|FROM
	|	AccumulationRegister.PurchasePlans.Turnovers(
	|			&BeginOfPeriod,
	|			&EndOfPeriod,
	|			Month,
	|			Scenario = &Scenario
	|				AND Status IN (&ScenarioStatuses)
	|				AND (Products, Characteristic, Purpose) IN
	|					(SELECT
	|						T.Products AS Products,
	|						T.Characteristic AS Characteristic,
	|						T.Purpose AS Purpose
	|					FROM
	|						ShortagesCalculationQueueInStages AS T)) AS PurchasePlansTurnovers
	|
	|UNION ALL
	|
	|SELECT
	|	ReleasePlansProducts_Turnovers.Period,
	|	ReleasePlansProducts_Turnovers.Scenario,
	|	ReleasePlansProducts_Turnovers.Products,
	|	ReleasePlansProducts_Turnovers.Characteristic,
	|	ReleasePlansProducts_Turnovers.Purpose,
	|	ReleasePlansProducts_Turnovers.PlanProfile,
	|	0,
	|	0,
	|	ReleasePlansProducts_Turnovers.CountTurnover,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.ReleasePlansProducts_.Turnovers(
	|			&BeginOfPeriod,
	|			&EndOfPeriod,
	|			Month,
	|			Scenario = &Scenario
	|				AND Status IN (&ScenarioStatuses)
	|				AND (Products, Characteristic, Purpose) IN
	|					(SELECT
	|						T.Products AS Products,
	|						T.Characteristic AS Characteristic,
	|						T.Purpose AS Purpose
	|					FROM
	|						ShortagesCalculationQueueInStages AS T)) AS ReleasePlansProducts_Turnovers
	|
	|UNION ALL
	|
	|SELECT
	|	ProductProductionPlansTurnover.Period,
	|	ProductProductionPlansTurnover.Scenario,
	|	ProductProductionPlansTurnover.Products,
	|	ProductProductionPlansTurnover.Characteristic,
	|	ProductProductionPlansTurnover.Purpose,
	|	ProductProductionPlansTurnover.PlanProfile,
	|	0,
	|	0,
	|	0,
	|	0,
	|	ProductProductionPlansTurnover.DemandRangeIsSpecifiedTurnover,
	|	ProductProductionPlansTurnover.RangeOfDemandFromTurnover,
	|	ProductProductionPlansTurnover.RangeOfDemandToTurnover,
	|	ProductProductionPlansTurnover.CountTurnover
	|FROM
	|	AccumulationRegister.ProductionPlans.Turnovers(
	|			&BeginOfPeriod,
	|			&EndOfPeriod,
	|			Month,
	|			Scenario = &Scenario
	|				AND Status IN (&ScenarioStatuses)
	|				AND (Products, Characteristic, Purpose) IN
	|					(SELECT
	|						T.Products AS Products,
	|						T.Characteristic AS Characteristic,
	|						T.Purpose AS Purpose
	|					FROM
	|						ShortagesCalculationQueueInStages AS T)) AS ProductProductionPlansTurnover
	|
	|UNION ALL
	|
	|SELECT
	|	MaterialConsumptionPlansTurnovers.Period,
	|	MaterialConsumptionPlansTurnovers.Scenario,
	|	MaterialConsumptionPlansTurnovers.Products,
	|	MaterialConsumptionPlansTurnovers.Characteristic,
	|	MaterialConsumptionPlansTurnovers.Purpose,
	|	MaterialConsumptionPlansTurnovers.PlanProfile,
	|	MaterialConsumptionPlansTurnovers.CountTurnover,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.MaterialConsumptionPlans.Turnovers(
	|			&BeginOfPeriod,
	|			&EndOfPeriod,
	|			Month,
	|			Scenario = &Scenario
	|				AND Status IN (&ScenarioStatuses)
	|				AND (Products, Characteristic, Purpose) IN
	|					(SELECT
	|						T.Products AS Products,
	|						T.Characteristic AS Characteristic,
	|						T.Purpose AS Purpose
	|					FROM
	|						ShortagesCalculationQueueInStages AS T)) AS MaterialConsumptionPlansTurnovers
	|
	|UNION ALL
	|
	|SELECT
	|	AssemblyPlansDisassemblyRevolutions.Period,
	|	AssemblyPlansDisassemblyRevolutions.Scenario,
	|	AssemblyPlansDisassemblyRevolutions.Products,
	|	AssemblyPlansDisassemblyRevolutions.Characteristic,
	|	AssemblyPlansDisassemblyRevolutions.Purpose,
	|	AssemblyPlansDisassemblyRevolutions.PlanProfile,
	|	0,
	|	0,
	|	AssemblyPlansDisassemblyRevolutions.CountTurnover,
	|	0,
	|	AssemblyPlansDisassemblyRevolutions.DemandRangeIsSpecifiedTurnover,
	|	AssemblyPlansDisassemblyRevolutions.RangeOfDemandFromTurnover,
	|	AssemblyPlansDisassemblyRevolutions.RangeOfDemandToTurnover,
	|	AssemblyPlansDisassemblyRevolutions.CountTurnover
	|FROM
	|	AccumulationRegister.AssemblyDisassemblyPlans.Turnovers(
	|			&BeginOfPeriod,
	|			&EndOfPeriod,
	|			Month,
	|			Scenario = &Scenario
	|				AND Status IN (&ScenarioStatuses)
	|				AND (Products, Characteristic, Purpose) IN
	|					(SELECT
	|						T.Products AS Products,
	|						T.Characteristic AS Characteristic,
	|						T.Purpose AS Purpose
	|					FROM
	|						ShortagesCalculationQueueInStages AS T)) AS AssemblyPlansDisassemblyRevolutions
	|
	|UNION ALL
	|
	|SELECT
	|	PlansForConsumptionOfComponentsTurnover.Period,
	|	PlansForConsumptionOfComponentsTurnover.Scenario,
	|	PlansForConsumptionOfComponentsTurnover.Products,
	|	PlansForConsumptionOfComponentsTurnover.Characteristic,
	|	PlansForConsumptionOfComponentsTurnover.Purpose,
	|	PlansForConsumptionOfComponentsTurnover.PlanProfile,
	|	PlansForConsumptionOfComponentsTurnover.CountTurnover,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.ComponentsConsumptionPlans.Turnovers(
	|			&BeginOfPeriod,
	|			&EndOfPeriod,
	|			Month,
	|			Scenario = &Scenario
	|				AND Status IN (&ScenarioStatuses)
	|				AND (Products, Characteristic, Purpose) IN
	|					(SELECT
	|						T.Products AS Products,
	|						T.Characteristic AS Characteristic,
	|						T.Purpose AS Purpose
	|					FROM
	|						ShortagesCalculationQueueInStages AS T)) AS PlansForConsumptionOfComponentsTurnover
	|
	|UNION ALL
	|
	|SELECT
	|	InitialResiduals.Period,
	|	InitialResiduals.Scenario,
	|	InitialResiduals.Products,
	|	InitialResiduals.Characteristic,
	|	InitialResiduals.Purpose,
	|	InitialResiduals.PlanProfile,
	|	0,
	|	0,
	|	0,
	|	InitialResiduals.OpeningBalance,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	InitialResiduals AS InitialResiduals
	|WHERE
	|	InitialResiduals.OpeningBalance > 0
	|
	|UNION ALL
	|
	|SELECT
	|	AdjustmentsToPlannedDemandsTurnovers.Period,
	|	AdjustmentsToPlannedDemandsTurnovers.Scenario,
	|	AdjustmentsToPlannedDemandsTurnovers.Products,
	|	AdjustmentsToPlannedDemandsTurnovers.Characteristic,
	|	AdjustmentsToPlannedDemandsTurnovers.Purpose,
	|	AdjustmentsToPlannedDemandsTurnovers.PlanProfile,
	|	0,
	|	AdjustmentsToPlannedDemandsTurnovers.CountTurnover,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0
	|FROM
	|	AccumulationRegister.AdjustmentsToPlannedDemands.Turnovers(
	|			&BeginOfPeriod,
	|			&EndOfPeriod,
	|			Month,
	|			Scenario = &Scenario
	|				AND (Products, Characteristic, Purpose) IN
	|					(SELECT
	|						T.Products AS Products,
	|						T.Characteristic AS Characteristic,
	|						T.Purpose AS Purpose
	|					FROM
	|						ShortagesCalculationQueueInStages AS T)) AS AdjustmentsToPlannedDemandsTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TurnoverByTypeOfPlans.Period AS Period,
	|	TurnoverByTypeOfPlans.Scenario AS Scenario,
	|	TurnoverByTypeOfPlans.Products AS Products,
	|	TurnoverByTypeOfPlans.Characteristic AS Characteristic,
	|	TurnoverByTypeOfPlans.Purpose AS Purpose,
	|	TurnoverByTypeOfPlans.PlanProfile AS PlanProfile,
	|	SUM(TurnoverByTypeOfPlans.Expense) AS Expense,
	|	SUM(TurnoverByTypeOfPlans.ExpenseAdjustment) AS ExpenseAdjustment,
	|	SUM(TurnoverByTypeOfPlans.Receipt) AS Receipt,
	|	SUM(TurnoverByTypeOfPlans.OpeningBalance) AS OpeningBalance,
	|	ISNULL(TurnoverByTypeOfPlans.PlanProfile.Parent, TurnoverByTypeOfPlans.PlanProfile) AS PlanningStage,
	|	ISNULL(TurnoverByTypeOfPlans.PlanProfile.Parent.PlanningProcedure, 0) AS StagePlanningOrder,
	|	ISNULL(TurnoverByTypeOfPlans.PlanProfile.PlanningProcedure, 0) AS PlanningProcedure,
	|	MAX(TurnoverByTypeOfPlans.DemandRangeIsSpecified) AS DemandRangeIsSpecified,
	|	MAX(TurnoverByTypeOfPlans.RangeOfDemandFrom) AS RangeOfDemandFrom,
	|	MAX(TurnoverByTypeOfPlans.RangeOfDemandTo) AS RangeOfDemandTo,
	|	SUM(TurnoverByTypeOfPlans.ToSupply) AS ToSupply
	|INTO TurnoverByTypeOfPlans
	|FROM
	|	TurnoverByPlanTypeWithoutGrouping AS TurnoverByTypeOfPlans
	|
	|GROUP BY
	|	TurnoverByTypeOfPlans.Period,
	|	TurnoverByTypeOfPlans.PlanProfile,
	|	TurnoverByTypeOfPlans.Scenario,
	|	TurnoverByTypeOfPlans.Purpose,
	|	TurnoverByTypeOfPlans.Products,
	|	TurnoverByTypeOfPlans.Characteristic,
	|	ISNULL(TurnoverByTypeOfPlans.PlanProfile.Parent, TurnoverByTypeOfPlans.PlanProfile),
	|	ISNULL(TurnoverByTypeOfPlans.PlanProfile.Parent.PlanningProcedure, 0),
	|	ISNULL(TurnoverByTypeOfPlans.PlanProfile.PlanningProcedure, 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlansStructure.PlanProfile AS PlanProfile,
	|	PlansStructure.PlanningStage AS PlanningStage,
	|	TurnoverByTypeOfPlans.Scenario AS Scenario,
	|	TurnoverByTypeOfPlans.Period AS Period,
	|	TurnoverByTypeOfPlans.Products AS Products,
	|	TurnoverByTypeOfPlans.Characteristic AS Characteristic,
	|	TurnoverByTypeOfPlans.Purpose AS Purpose,
	|	PlansStructure.FillInByShortage AS FillInByShortage,
	|	SUM(CASE
	|			WHEN PlansStructure.StagePlanningOrder = 999
	|				THEN TurnoverByTypeOfPlans.Expense
	|			WHEN TurnoverByTypeOfPlans.StagePlanningOrder = PlansStructure.StagePlanningOrder
	|				THEN TurnoverByTypeOfPlans.Expense
	|			ELSE 0
	|		END) AS Expense,
	|	SUM(CASE
	|			WHEN PlansStructure.StagePlanningOrder = 999
	|				THEN TurnoverByTypeOfPlans.ExpenseAdjustment
	|			WHEN TurnoverByTypeOfPlans.StagePlanningOrder = PlansStructure.StagePlanningOrder
	|				THEN TurnoverByTypeOfPlans.ExpenseAdjustment
	|			ELSE 0
	|		END) AS ExpenseAdjustment,
	|	SUM(CASE
	|			WHEN PlansStructure.StagePlanningOrder = 999
	|				THEN TurnoverByTypeOfPlans.Receipt
	|			WHEN TurnoverByTypeOfPlans.StagePlanningOrder = PlansStructure.StagePlanningOrder
	|				THEN TurnoverByTypeOfPlans.Receipt
	|			ELSE 0
	|		END) AS Receipt,
	|	SUM(CASE
	|			WHEN PlansStructure.StagePlanningOrder = 999
	|				THEN TurnoverByTypeOfPlans.ToSupply
	|			WHEN TurnoverByTypeOfPlans.StagePlanningOrder = PlansStructure.StagePlanningOrder
	|				THEN TurnoverByTypeOfPlans.ToSupply
	|			ELSE 0
	|		END) AS ToSupply,
	|	SUM(CASE
	|			WHEN TurnoverByTypeOfPlans.StagePlanningOrder < PlansStructure.StagePlanningOrder
	|				THEN -(TurnoverByTypeOfPlans.OpeningBalance + TurnoverByTypeOfPlans.Receipt - TurnoverByTypeOfPlans.Expense - TurnoverByTypeOfPlans.ExpenseAdjustment)
	|			WHEN TurnoverByTypeOfPlans.StagePlanningOrder = PlansStructure.StagePlanningOrder
	|				THEN -(TurnoverByTypeOfPlans.OpeningBalance + TurnoverByTypeOfPlans.Receipt - TurnoverByTypeOfPlans.ExpenseAdjustment)
	|			ELSE 0
	|		END) AS Deficit,
	|	SUM(CASE
	|			WHEN PlansStructure.StagePlanningOrder = 999
	|				THEN TurnoverByTypeOfPlans.OpeningBalance
	|			WHEN TurnoverByTypeOfPlans.StagePlanningOrder < PlansStructure.StagePlanningOrder
	|				THEN TurnoverByTypeOfPlans.OpeningBalance + TurnoverByTypeOfPlans.Receipt - TurnoverByTypeOfPlans.Expense - TurnoverByTypeOfPlans.ExpenseAdjustment
	|			WHEN TurnoverByTypeOfPlans.StagePlanningOrder = PlansStructure.StagePlanningOrder
	|				THEN TurnoverByTypeOfPlans.OpeningBalance
	|			ELSE 0
	|		END) AS OpeningBalance,
	|	MAX(CASE
	|			WHEN TurnoverByTypeOfPlans.StagePlanningOrder = PlansStructure.StagePlanningOrder
	|				THEN TurnoverByTypeOfPlans.RangeOfDemandFrom
	|			ELSE 0
	|		END) AS RangeOfDemandFrom,
	|	MAX(CASE
	|			WHEN TurnoverByTypeOfPlans.StagePlanningOrder = PlansStructure.StagePlanningOrder
	|				THEN TurnoverByTypeOfPlans.RangeOfDemandTo
	|			ELSE 0
	|		END) AS RangeOfDemandTo,
	|	MAX(CASE
	|			WHEN TurnoverByTypeOfPlans.StagePlanningOrder = PlansStructure.StagePlanningOrder
	|				THEN TurnoverByTypeOfPlans.DemandRangeIsSpecified
	|			ELSE 0
	|		END) AS DemandRangeIsSpecified
	|INTO CalculationsByStages
	|FROM
	|	PlansStructure AS PlansStructure
	|		LEFT JOIN TurnoverByTypeOfPlans AS TurnoverByTypeOfPlans
	|		ON (TurnoverByTypeOfPlans.StagePlanningOrder <= PlansStructure.StagePlanningOrder)
	|WHERE
	|	PlansStructure.IsFolder
	|	AND NOT TurnoverByTypeOfPlans.Scenario IS NULL
	|
	|GROUP BY
	|	PlansStructure.PlanProfile,
	|	PlansStructure.PlanningStage,
	|	PlansStructure.FillInByShortage,
	|	TurnoverByTypeOfPlans.Scenario,
	|	TurnoverByTypeOfPlans.Period,
	|	TurnoverByTypeOfPlans.Products,
	|	TurnoverByTypeOfPlans.Characteristic,
	|	TurnoverByTypeOfPlans.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlansStructure.PlanProfile AS PlanProfile,
	|	CalculationsByStages.PlanningStage AS PlanningStage,
	|	PlansStructure.FillInByShortage AS FillInByShortage,
	|	PlansStructure.IsFolder AS IsFolder,
	|	CalculationsByStages.Scenario AS Scenario,
	|	CalculationsByStages.Period AS Period,
	|	CalculationsByStages.Products AS Products,
	|	CalculationsByStages.Characteristic AS Characteristic,
	|	CalculationsByStages.Purpose AS Purpose,
	|	CalculationsByStages.Expense AS Expense,
	|	CalculationsByStages.ExpenseAdjustment AS ExpenseAdjustment,
	|	CalculationsByStages.Receipt AS Receipt,
	|	CalculationsByStages.ToSupply AS ToSupply,
	|	CalculationsByStages.Deficit AS Deficit,
	|	CalculationsByStages.OpeningBalance AS OpeningBalance,
	|	CalculationsByStages.RangeOfDemandFrom AS RangeOfDemandFrom,
	|	CalculationsByStages.RangeOfDemandTo AS RangeOfDemandTo,
	|	CalculationsByStages.DemandRangeIsSpecified AS DemandRangeIsSpecified
	|INTO CalculationByStagesAndTypesOfPlans
	|FROM
	|	CalculationsByStages AS CalculationsByStages
	|		LEFT JOIN PlansStructure AS PlansStructure
	|		ON CalculationsByStages.PlanningStage = PlansStructure.PlanningStage
	|WHERE
	|	NOT(CalculationsByStages.Receipt = 0
	|				AND CalculationsByStages.Expense = 0
	|				AND CalculationsByStages.Deficit = 0
	|				AND CalculationsByStages.OpeningBalance = 0
	|				AND CalculationsByStages.DemandRangeIsSpecified = 0)
	|
	|INDEX BY
	|	CalculationsByStages.Products,
	|	CalculationsByStages.Characteristic,
	|	CalculationsByStages.Purpose,
	|	CalculationsByStages.PlanningStage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationOfPlanShortagesByStages.Scenario AS Scenario,
	|	CalculationOfPlanShortagesByStages.PlanProfile AS PlanProfile,
	|	CalculationOfPlanShortagesByStages.PlanningPeriod AS PlanningPeriod,
	|	CalculationOfPlanShortagesByStages.Products AS Products,
	|	CalculationOfPlanShortagesByStages.Characteristic AS Characteristic,
	|	CalculationOfPlanShortagesByStages.Purpose AS Purpose,
	|	CalculationOfPlanShortagesByStages.OpeningBalance AS OpeningBalance,
	|	CalculationOfPlanShortagesByStages.Deficit AS Deficit,
	|	CalculationOfPlanShortagesByStages.ToChange AS ToChange,
	|	CalculationOfPlanShortagesByStages.ShouldRecalculate AS ShouldRecalculate,
	|	CalculationOfPlanShortagesByStages.Receipt AS Receipt,
	|	CalculationOfPlanShortagesByStages.ToSupply AS ToSupply,
	|	CalculationOfPlanShortagesByStages.Expense AS Expense,
	|	CalculationOfPlanShortagesByStages.ExpenseAdjustment AS ExpenseAdjustment,
	|	CalculationOfPlanShortagesByStages.RangeOfDemandFrom AS RangeOfDemandFrom,
	|	CalculationOfPlanShortagesByStages.RangeOfDemandTo AS RangeOfDemandTo,
	|	CalculationOfPlanShortagesByStages.DemandRangeIsSpecified AS DemandRangeIsSpecified
	|INTO PreviousCalculationOfDeficitsOfPlansByStages
	|FROM
	|	InformationRegister.CalculationOfPlanShortagesByStages AS CalculationOfPlanShortagesByStages
	|WHERE
	|	CalculationOfPlanShortagesByStages.Scenario = &Scenario
	|	AND CalculationOfPlanShortagesByStages.PlanningPeriod = &BeginOfPeriod
	|	AND CalculationOfPlanShortagesByStages.Products <> VALUE(Catalog.Products.EmptyRef)
	|
	|INDEX BY
	|	CalculationOfPlanShortagesByStages.Products,
	|	CalculationOfPlanShortagesByStages.Characteristic,
	|	CalculationOfPlanShortagesByStages.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationByStagesAndTypesOfPlans.PlanProfile AS PlanProfile,
	|	CalculationByStagesAndTypesOfPlans.Scenario AS Scenario,
	|	CalculationByStagesAndTypesOfPlans.Period AS PlanningPeriod,
	|	CalculationByStagesAndTypesOfPlans.Products AS Products,
	|	CalculationByStagesAndTypesOfPlans.Characteristic AS Characteristic,
	|	CalculationByStagesAndTypesOfPlans.Purpose AS Purpose,
	|	ISNULL(TurnoverByTypeOfPlans.Expense, 0) AS Expense,
	|	ISNULL(TurnoverByTypeOfPlans.ExpenseAdjustment, 0) AS ExpenseAdjustment,
	|	ISNULL(TurnoverByTypeOfPlans.Receipt, 0) AS Receipt,
	|	ISNULL(TurnoverByTypeOfPlans.ToSupply, 0) AS ToSupply,
	|	CASE
	|		WHEN CalculationByStagesAndTypesOfPlans.FillInByShortage
	|			THEN CASE
	|					WHEN TurnoverByTypeOfPlans.DemandRangeIsSpecified > 0
	|							AND (TurnoverByTypeOfPlans.RangeOfDemandFrom <= ISNULL(TurnoverByTypeOfPlans.Receipt, 0) + ISNULL(TurnoverByTypeOfPlans.ExpenseAdjustment, 0)
	|								OR TurnoverByTypeOfPlans.RangeOfDemandFrom = 0)
	|							AND (TurnoverByTypeOfPlans.RangeOfDemandTo >= ISNULL(TurnoverByTypeOfPlans.Receipt, 0)  + ISNULL(TurnoverByTypeOfPlans.ExpenseAdjustment, 0)
	|								OR TurnoverByTypeOfPlans.RangeOfDemandTo = 0)
	|						THEN 0
	|					ELSE CASE
	|							WHEN SelectionOfProductsByTypeOfPlans.PlanProfile IS NULL
	|									OR CalculationByStagesAndTypesOfPlans.Deficit + ISNULL(TurnoverByTypeOfPlans.Receipt, 0) - ISNULL(TurnoverByTypeOfPlans.ToSupply, 0) < -ISNULL(TurnoverByTypeOfPlans.ToSupply, 0)
	|								THEN -ISNULL(TurnoverByTypeOfPlans.ToSupply, 0)
	|							ELSE CalculationByStagesAndTypesOfPlans.Deficit + ISNULL(TurnoverByTypeOfPlans.Receipt, 0) - ISNULL(TurnoverByTypeOfPlans.ToSupply, 0)
	|						END
	|				END
	|		ELSE 0
	|	END AS ToChange,
	|	CalculationByStagesAndTypesOfPlans.OpeningBalance AS OpeningBalance,
	|	CASE
	|		WHEN CalculationByStagesAndTypesOfPlans.FillInByShortage
	|			THEN CASE
	|					WHEN TurnoverByTypeOfPlans.DemandRangeIsSpecified > 0 
	|							AND (TurnoverByTypeOfPlans.RangeOfDemandFrom <= ISNULL(TurnoverByTypeOfPlans.Receipt, 0) + ISNULL(TurnoverByTypeOfPlans.ExpenseAdjustment, 0)
	|								OR TurnoverByTypeOfPlans.RangeOfDemandFrom = 0)
	|							AND (TurnoverByTypeOfPlans.RangeOfDemandTo >= ISNULL(TurnoverByTypeOfPlans.Receipt, 0) + ISNULL(TurnoverByTypeOfPlans.ExpenseAdjustment, 0)
	|								OR TurnoverByTypeOfPlans.RangeOfDemandTo = 0)
	|						THEN 0
	|					ELSE CASE
	|							WHEN SelectionOfProductsByTypeOfPlans.PlanProfile IS NULL
	|									OR CalculationByStagesAndTypesOfPlans.Deficit + ISNULL(TurnoverByTypeOfPlans.Receipt, 0) - ISNULL(TurnoverByTypeOfPlans.ToSupply, 0) < -ISNULL(TurnoverByTypeOfPlans.ToSupply, 0)
	|								THEN -ISNULL(TurnoverByTypeOfPlans.ToSupply, 0)
	|							ELSE CalculationByStagesAndTypesOfPlans.Deficit + ISNULL(TurnoverByTypeOfPlans.Receipt, 0) - ISNULL(TurnoverByTypeOfPlans.ToSupply, 0)
	|						END
	|				END
	|		ELSE 0
	|	END <> 0 AS ShouldRecalculate,
	|	ISNULL(TurnoverByTypeOfPlans.RangeOfDemandFrom, 0) AS RangeOfDemandFrom,
	|	ISNULL(TurnoverByTypeOfPlans.RangeOfDemandTo, 0) AS RangeOfDemandTo,
	|	ISNULL(TurnoverByTypeOfPlans.DemandRangeIsSpecified, 0) AS DemandRangeIsSpecified,
	|	CalculationByStagesAndTypesOfPlans.PlanningStage AS PlanningStage,
	|	CalculationByStagesAndTypesOfPlans.Deficit AS Deficit
	|INTO CalculationOfChangeByTypesOfPlans
	|FROM
	|	CalculationByStagesAndTypesOfPlans AS CalculationByStagesAndTypesOfPlans
	|		LEFT JOIN TurnoverByTypeOfPlans AS TurnoverByTypeOfPlans
	|		ON (CalculationByStagesAndTypesOfPlans.PlanProfile <> VALUE(Catalog.PlanProfiles.EmptyRef))
	|			AND CalculationByStagesAndTypesOfPlans.PlanProfile = TurnoverByTypeOfPlans.PlanProfile
	|			AND CalculationByStagesAndTypesOfPlans.Products = TurnoverByTypeOfPlans.Products
	|			AND CalculationByStagesAndTypesOfPlans.Characteristic = TurnoverByTypeOfPlans.Characteristic
	|			AND CalculationByStagesAndTypesOfPlans.Purpose = TurnoverByTypeOfPlans.Purpose
	|		LEFT JOIN SelectionOfProductsByTypeOfPlans AS SelectionOfProductsByTypeOfPlans
	|		ON CalculationByStagesAndTypesOfPlans.PlanProfile = SelectionOfProductsByTypeOfPlans.PlanProfile
	|			AND CASE
	|				WHEN SelectionOfProductsByTypeOfPlans.PlanProfile.PlanType = VALUE(Enum.TypesOfPlans.ProductionPlan)
	|					AND SelectionOfProductsByTypeOfPlans.Products IS NULL AND NOT SelectionOfProductsByTypeOfPlans.ProductKind IS NULL
	|					THEN CalculationByStagesAndTypesOfPlans.Products.ProductKind = SelectionOfProductsByTypeOfPlans.ProductKind
	|				ELSE CalculationByStagesAndTypesOfPlans.Products = SelectionOfProductsByTypeOfPlans.Products
	|			END
	|			AND CASE
	|				WHEN NOT SelectionOfProductsByTypeOfPlans.Products IS NULL
	|					THEN CalculationByStagesAndTypesOfPlans.Characteristic = SelectionOfProductsByTypeOfPlans.Characteristic
	|				ELSE TRUE
	|			END
	|WHERE
	|	NOT CalculationByStagesAndTypesOfPlans.IsFolder
	|	AND NOT(ISNULL(TurnoverByTypeOfPlans.Expense, 0) = 0
	|				AND ISNULL(TurnoverByTypeOfPlans.Receipt, 0) = 0
	|				AND CASE
	|					WHEN CalculationByStagesAndTypesOfPlans.FillInByShortage
	|						THEN CASE
	|								WHEN SelectionOfProductsByTypeOfPlans.PlanProfile IS NULL
	|										OR CalculationByStagesAndTypesOfPlans.Deficit + ISNULL(TurnoverByTypeOfPlans.Receipt, 0) - ISNULL(TurnoverByTypeOfPlans.ToSupply, 0) < -ISNULL(TurnoverByTypeOfPlans.ToSupply, 0)
	|									THEN -ISNULL(TurnoverByTypeOfPlans.ToSupply, 0)
	|								ELSE CalculationByStagesAndTypesOfPlans.Deficit + ISNULL(TurnoverByTypeOfPlans.Receipt, 0) - ISNULL(TurnoverByTypeOfPlans.ToSupply, 0)
	|							END
	|					ELSE 0
	|				END = 0
	|				AND ISNULL(TurnoverByTypeOfPlans.OpeningBalance, 0) = 0
	|				AND ISNULL(TurnoverByTypeOfPlans.ExpenseAdjustment, 0) = 0)
	|
	|INDEX BY
	|	CalculationByStagesAndTypesOfPlans.Products,
	|	CalculationByStagesAndTypesOfPlans.Characteristic,
	|	CalculationByStagesAndTypesOfPlans.Purpose,
	|	CalculationByStagesAndTypesOfPlans.PlanProfile
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationByStagesAndTypesOfPlans.PlanProfile AS PlanProfile,
	|	CalculationByStagesAndTypesOfPlans.Scenario AS Scenario,
	|	CalculationByStagesAndTypesOfPlans.Products AS Products,
	|	CalculationByStagesAndTypesOfPlans.Characteristic AS Characteristic,
	|	CalculationByStagesAndTypesOfPlans.Purpose AS Purpose,
	|	CalculationByStagesAndTypesOfPlans.Expense AS Expense,
	|	CalculationByStagesAndTypesOfPlans.ExpenseAdjustment AS ExpenseAdjustment,
	|	CalculationByStagesAndTypesOfPlans.Receipt AS Receipt,
	|	CalculationByStagesAndTypesOfPlans.ToSupply AS ToSupply,
	|	CalculationByStagesAndTypesOfPlans.Deficit AS Deficit,
	|	MAX(ISNULL(CalculationOfChangeByTypesOfPlans.ToChange, 0)) AS ToChange,
	|	CalculationByStagesAndTypesOfPlans.OpeningBalance AS OpeningBalance,
	|	CalculationByStagesAndTypesOfPlans.Period AS PlanningPeriod,
	|	MAX(ISNULL(CalculationOfChangeByTypesOfPlans.ShouldRecalculate, FALSE)) AS ShouldRecalculate,
	|	MAX(CalculationOfChangeByTypesOfPlans.RangeOfDemandFrom) AS RangeOfDemandFrom,
	|	MAX(CalculationOfChangeByTypesOfPlans.RangeOfDemandTo) AS RangeOfDemandTo,
	|	MAX(CalculationOfChangeByTypesOfPlans.DemandRangeIsSpecified) AS DemandRangeIsSpecified
	|FROM
	|	CalculationByStagesAndTypesOfPlans AS CalculationByStagesAndTypesOfPlans
	|		LEFT JOIN CalculationOfChangeByTypesOfPlans AS CalculationOfChangeByTypesOfPlans
	|		ON (CalculationOfChangeByTypesOfPlans.PlanningStage = CalculationByStagesAndTypesOfPlans.PlanProfile)
	|			AND (CalculationOfChangeByTypesOfPlans.Products = CalculationByStagesAndTypesOfPlans.Products)
	|			AND (CalculationOfChangeByTypesOfPlans.Characteristic = CalculationByStagesAndTypesOfPlans.Characteristic)
	|			AND (CalculationOfChangeByTypesOfPlans.Purpose = CalculationByStagesAndTypesOfPlans.Purpose)
	|WHERE
	|	CalculationByStagesAndTypesOfPlans.IsFolder
	|
	|GROUP BY
	|	CalculationByStagesAndTypesOfPlans.PlanProfile,
	|	CalculationByStagesAndTypesOfPlans.PlanningStage,
	|	CalculationByStagesAndTypesOfPlans.Scenario,
	|	CalculationByStagesAndTypesOfPlans.Period,
	|	CalculationByStagesAndTypesOfPlans.Products,
	|	CalculationByStagesAndTypesOfPlans.Characteristic,
	|	CalculationByStagesAndTypesOfPlans.Purpose,
	|	CalculationByStagesAndTypesOfPlans.Expense,
	|	CalculationByStagesAndTypesOfPlans.ExpenseAdjustment,
	|	CalculationByStagesAndTypesOfPlans.Receipt,
	|	CalculationByStagesAndTypesOfPlans.ToSupply,
	|	CalculationByStagesAndTypesOfPlans.Deficit,
	|	CalculationByStagesAndTypesOfPlans.OpeningBalance
	|
	|UNION ALL
	|
	|SELECT
	|	CalculationOfChangeByTypesOfPlans.PlanProfile,
	|	CalculationOfChangeByTypesOfPlans.Scenario,
	|	CalculationOfChangeByTypesOfPlans.Products,
	|	CalculationOfChangeByTypesOfPlans.Characteristic,
	|	CalculationOfChangeByTypesOfPlans.Purpose,
	|	CalculationOfChangeByTypesOfPlans.Expense,
	|	CalculationOfChangeByTypesOfPlans.ExpenseAdjustment,
	|	CalculationOfChangeByTypesOfPlans.Receipt,
	|	CalculationOfChangeByTypesOfPlans.ToSupply,
	|	CalculationOfChangeByTypesOfPlans.Deficit,
	|	CalculationOfChangeByTypesOfPlans.ToChange,
	|	CalculationOfChangeByTypesOfPlans.OpeningBalance,
	|	CalculationOfChangeByTypesOfPlans.PlanningPeriod,
	|	CalculationOfChangeByTypesOfPlans.ShouldRecalculate,
	|	CalculationOfChangeByTypesOfPlans.RangeOfDemandFrom,
	|	CalculationOfChangeByTypesOfPlans.RangeOfDemandTo,
	|	CalculationOfChangeByTypesOfPlans.DemandRangeIsSpecified
	|FROM
	|	CalculationOfChangeByTypesOfPlans AS CalculationOfChangeByTypesOfPlans
	|
	|UNION ALL
	|
	|SELECT
	|	CalculationOfPlanShortagesByStages.PlanProfile,
	|	CalculationOfPlanShortagesByStages.Scenario,
	|	CalculationOfPlanShortagesByStages.Products,
	|	CalculationOfPlanShortagesByStages.Characteristic,
	|	CalculationOfPlanShortagesByStages.Purpose,
	|	CalculationOfPlanShortagesByStages.Expense,
	|	CalculationOfPlanShortagesByStages.ExpenseAdjustment,
	|	CalculationOfPlanShortagesByStages.Receipt,
	|	CalculationOfPlanShortagesByStages.ToSupply,
	|	CalculationOfPlanShortagesByStages.Deficit,
	|	CalculationOfPlanShortagesByStages.ToChange,
	|	CalculationOfPlanShortagesByStages.OpeningBalance,
	|	CalculationOfPlanShortagesByStages.PlanningPeriod,
	|	CalculationOfPlanShortagesByStages.ShouldRecalculate,
	|	CalculationOfPlanShortagesByStages.RangeOfDemandFrom,
	|	CalculationOfPlanShortagesByStages.RangeOfDemandTo,
	|	CalculationOfPlanShortagesByStages.DemandRangeIsSpecified
	|FROM
	|	PreviousCalculationOfDeficitsOfPlansByStages AS CalculationOfPlanShortagesByStages
	|		LEFT JOIN ShortagesCalculationQueueInStages AS ShortagesCalculationQueueInStages
	|		ON CalculationOfPlanShortagesByStages.Products = ShortagesCalculationQueueInStages.Products
	|			AND CalculationOfPlanShortagesByStages.Characteristic = ShortagesCalculationQueueInStages.Characteristic
	|			AND CalculationOfPlanShortagesByStages.Purpose = ShortagesCalculationQueueInStages.Purpose
	|WHERE
	|	ShortagesCalculationQueueInStages.Scenario IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlansStructure.PlanProfile AS PlanProfile,
	|	PlansStructure.PlanningProcedure AS PlanningProcedure,
	|	PlansStructure.StagePlanningOrder AS StagePlanningOrder,
	|	PlansStructure.PlanningStage AS PlanningStage,
	|	PlansStructure.IsFolder AS IsFolder,
	|	PlansStructure.FillInByShortage AS FillInByShortage,
	|	PlansStructure.DemandPlanning AS DemandPlanning,
	|	PlansStructure.PlanningOfGoodsStock AS PlanningOfGoodsStock
	|FROM
	|	PlansStructure AS PlansStructure
	|
	|ORDER BY
	|	StagePlanningOrder,
	|	NOT PlansStructure.IsFolder,
	|	PlanningProcedure
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationsByStages.Products AS Products,
	|	CalculationsByStages.Characteristic AS Characteristic,
	|	CalculationsByStages.Purpose AS Purpose,
	|	CalculationsByStages.PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
	|		AND PreviousCalculationOfDeficitsOfPlansByStages.PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
	|		AND NOT(PreviousCalculationOfDeficitsOfPlansByStages.Deficit >= 0
	|				AND CalculationsByStages.Deficit >= 0)
	|		AND PreviousCalculationOfDeficitsOfPlansByStages.Deficit <> CalculationsByStages.Deficit AS ItemsToBeRecalculatedInFollowingPeriods,
	|	CalculationsByStages.PlanProfile <> VALUE(Catalog.PlanProfiles.EmptyRef)
	|		AND PreviousCalculationOfDeficitsOfPlansByStages.PlanProfile <> VALUE(Catalog.PlanProfiles.EmptyRef)
	|		AND PreviousCalculationOfDeficitsOfPlansByStages.OpeningBalance <> CalculationsByStages.OpeningBalance
	|		AND CalculationsByStages.ExpenseAdjustment < 0 AS AdjustmentDemandToCheck,
	|	CalculationsByStages.PlanProfile AS PlanProfile
	|INTO GoodsToBeRecalculatedInFollowingPeriodsWhenAdjustingNeeds
	|FROM
	|	CalculationsByStages AS CalculationsByStages
	|		LEFT JOIN PreviousCalculationOfDeficitsOfPlansByStages AS PreviousCalculationOfDeficitsOfPlansByStages
	|		ON (PreviousCalculationOfDeficitsOfPlansByStages.Products = CalculationsByStages.Products)
	|			AND (PreviousCalculationOfDeficitsOfPlansByStages.Characteristic = CalculationsByStages.Characteristic)
	|			AND (PreviousCalculationOfDeficitsOfPlansByStages.Purpose = CalculationsByStages.Purpose)
	|			AND (PreviousCalculationOfDeficitsOfPlansByStages.PlanProfile = CalculationsByStages.PlanProfile)
	|WHERE
	|	(CalculationsByStages.PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
	|				AND PreviousCalculationOfDeficitsOfPlansByStages.PlanProfile = VALUE(Catalog.PlanProfiles.EmptyRef)
	|				AND NOT(PreviousCalculationOfDeficitsOfPlansByStages.Deficit >= 0
	|						AND CalculationsByStages.Deficit >= 0)
	|				AND PreviousCalculationOfDeficitsOfPlansByStages.Deficit <> CalculationsByStages.Deficit
	|			OR CalculationsByStages.PlanProfile <> VALUE(Catalog.PlanProfiles.EmptyRef)
	|				AND PreviousCalculationOfDeficitsOfPlansByStages.PlanProfile <> VALUE(Catalog.PlanProfiles.EmptyRef)
	|				AND PreviousCalculationOfDeficitsOfPlansByStages.OpeningBalance <> CalculationsByStages.OpeningBalance
	|				AND CalculationsByStages.ExpenseAdjustment < 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Scenario AS Scenario,
	|	CalculationOfPlanShortagesByStages.PlanningPeriod AS PlanningPeriod,
	|	CalculationOfPlanShortagesByStages.Products AS Products,
	|	CalculationOfPlanShortagesByStages.Characteristic AS Characteristic,
	|	CalculationOfPlanShortagesByStages.Purpose AS Purpose,
	|	VALUE(Catalog.PlanProfiles.EmptyRef) AS PlanProfile
	|FROM
	|	CalculationOfPlanShortagesByStages AS CalculationOfPlanShortagesByStages
	|		INNER JOIN GoodsToBeRecalculatedInFollowingPeriodsWhenAdjustingNeeds AS GoodsToBeRecalculatedInFollowingPeriodsWhenAdjustingNeeds
	|		ON CalculationOfPlanShortagesByStages.Products = GoodsToBeRecalculatedInFollowingPeriodsWhenAdjustingNeeds.Products
	|			AND CalculationOfPlanShortagesByStages.Characteristic = GoodsToBeRecalculatedInFollowingPeriodsWhenAdjustingNeeds.Characteristic
	|			AND CalculationOfPlanShortagesByStages.Purpose = GoodsToBeRecalculatedInFollowingPeriodsWhenAdjustingNeeds.Purpose
	|			AND (GoodsToBeRecalculatedInFollowingPeriodsWhenAdjustingNeeds.ItemsToBeRecalculatedInFollowingPeriods)
	|		LEFT JOIN InformationRegister.ShortagesCalculationQueueInStages AS ShortagesCalculationQueueInStages
	|		ON (&Scenario = ShortagesCalculationQueueInStages.Scenario)
	|			AND (VALUE(Catalog.PlanProfiles.EmptyRef) = ShortagesCalculationQueueInStages.PlanProfile)
	|			AND CalculationOfPlanShortagesByStages.PlanningPeriod = ShortagesCalculationQueueInStages.PlanningPeriod
	|			AND CalculationOfPlanShortagesByStages.Products = ShortagesCalculationQueueInStages.Products
	|			AND CalculationOfPlanShortagesByStages.Characteristic = ShortagesCalculationQueueInStages.Characteristic
	|			AND CalculationOfPlanShortagesByStages.Purpose = ShortagesCalculationQueueInStages.Purpose
	|WHERE
	|	ShortagesCalculationQueueInStages.Scenario IS NULL
	|	AND CalculationOfPlanShortagesByStages.PlanningPeriod > &EndOfPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AdjustmentsToPlannedDemands.AdjustmentOfPlannedDemand AS AdjustmentOfPlannedDemand,
	|	AdjustmentsToPlannedDemands.Scenario AS Scenario,
	|	AdjustmentsToPlannedDemands.Period AS DemandPeriod
	|FROM
	|	GoodsToBeRecalculatedInFollowingPeriodsWhenAdjustingNeeds AS GoodsToBeRecalculatedInFollowingPeriodsWhenAdjustingNeeds
	|		INNER JOIN AccumulationRegister.AdjustmentsToPlannedDemands.Turnovers(, , Recorder, ) AS AdjustmentsToPlannedDemands
	|		ON GoodsToBeRecalculatedInFollowingPeriodsWhenAdjustingNeeds.Products = AdjustmentsToPlannedDemands.Products
	|			AND GoodsToBeRecalculatedInFollowingPeriodsWhenAdjustingNeeds.Characteristic = AdjustmentsToPlannedDemands.Characteristic
	|			AND GoodsToBeRecalculatedInFollowingPeriodsWhenAdjustingNeeds.Purpose = AdjustmentsToPlannedDemands.Purpose
	|			AND GoodsToBeRecalculatedInFollowingPeriodsWhenAdjustingNeeds.PlanProfile = AdjustmentsToPlannedDemands.PlanProfileStage
	|			AND (&BeginOfPeriod = AdjustmentsToPlannedDemands.Period)
	|WHERE
	|	GoodsToBeRecalculatedInFollowingPeriodsWhenAdjustingNeeds.AdjustmentDemandToCheck";
	
	ScenarioStatuses = New Array;
	ScenarioStatuses.Add(Enums.PlanStatuses.Upholded);
	ScenarioStatuses.Add(Enums.PlanStatuses.AwaitingConfirmation);
	
	Query.SetParameter("ScenarioStatuses", ScenarioStatuses);
	Query.SetParameter("SelectionOfProductsByTypeOfPlans",SelectionOfProductsByTypeOfPlans);
	Query.SetParameter("ThereArePlannedRemnants",ThereArePlannedRemnants);
	
	Query.Text = StrReplace(Query.Text, "MONTH", GetPeriodicityByText(Periodicity));
	
	If Not GetFunctionalOption("UseItemVariants") Then
		Query.Text = StrReplace(Query.Text,
			"SelectionOfProductsByTypeOfPlans.Characteristic",
			"VALUE(Catalog.ItemsCharacteristics.EmptyRef)");
	EndIf;
	
	QueryResult = Query.ExecuteBatch();
	
	// Let's rewrite the calculation of deficits for the period
	TableOfCalculation = QueryResult[13].Unload(); // ValueTable
	TableOfCalculation.Indexes.Add("PlanProfile");
	
	//Bypassing the structure of plans and rewriting the calculation of deficits
	SelectionByPlanType = QueryResult[14].Select();
	
	While SelectionByPlanType.Next() Do
		CalculationTableByTypeOfPlan = TableOfCalculation.Copy(New Structure("PlanProfile",SelectionByPlanType.PlanProfile));
		RecordSet = InformationRegisters.CalculationOfPlanShortagesByStages.CreateRecordSet();
		RecordSet.Filter.Scenario.Set(Scenario);
		RecordSet.Filter.PlanProfile.Set(SelectionByPlanType.PlanProfile);
		RecordSet.Filter.PlanningPeriod.Set(BeginOfPeriod);
		RecordSet.Load(CalculationTableByTypeOfPlan);
		
		// General record for recalculation
		If SelectionByPlanType.FillInByShortage 
			Or (SelectionByPlanType.IsFolder
			And Not SelectionByPlanType.PlanningOfGoodsStock
			And Not SelectionByPlanType.DemandPlanning) Then
			NewRecord = RecordSet.Add();
			NewRecord.Scenario = Scenario;
			NewRecord.PlanProfile = SelectionByPlanType.PlanProfile;
			NewRecord.PlanningPeriod = BeginOfPeriod;
			NewRecord.ShouldRecalculate = CalculationTableByTypeOfPlan.FindRows(New Structure("ShouldRecalculate", True)).Count()>0;
		EndIf;
		RecordSet.Write();
		
	EndDo;
	
	// We will add products for recalculation in the following periods
	ConversionTable = QueryResult[16].Unload();
	If ConversionTable.Count()>0 Then
		RecordSet = InformationRegisters.ShortagesCalculationQueueInStages.CreateRecordSet();
		RecordSet.Filter.Scenario.Set(Scenario);
		RecordSet.Load(ConversionTable);
		RecordSet.Write(False);
	EndIf;
	
	//Clearing the calculation queue for the period
	RecordSet = InformationRegisters.ShortagesCalculationQueueInStages.CreateRecordSet();
	RecordSet.Filter.Scenario.Set(Scenario);
	RecordSet.Filter.PlanningPeriod.Set(BeginOfPeriod);
	RecordSet.Write();
	
	// We will put it in the queue to change the status of adjustments to needs
	Table = QueryResult[17].Unload();
	If Table.Count()>0 Then
		RecordSet = InformationRegisters.DemandAdjustmentsQueueToRecalculate.CreateRecordSet();
		RecordSet.Filter.Scenario.Set(Scenario);
		RecordSet.Filter.DemandPeriod.Set(BeginOfPeriod);
		RecordSet.Load(Table);
		RecordSet.Write();
		CalculationStructure.SetAdjustmentsForVerificationRequirements = True;
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, (TableOfCalculation.Count()+ConversionTable.Count()+Table.Count())/100);
	
	Return CalculationStructure
	
EndFunction

Procedure CheckingCompletionOfCalculationOfProductionPlansAndReplacementPlans(Scenario)
	
	If Common.FileInfobase() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query();
	Query.Text = 
		"SELECT TOP 1
		|	QueueOfProductionPlanCalculation.Scenario AS Scenario
		|FROM
		|	InformationRegister.QueueOfProductionPlanCalculation AS QueueOfProductionPlanCalculation
		|WHERE
		|	QueueOfProductionPlanCalculation.Scenario = &Scenario";
	
	Query.SetParameter("Scenario", Scenario);
	Selection = Query.Execute().Select();
	If Query.Execute().Select().Next() Then
		Var_Key = "QueueOfProductionPlanCalculation.QueueProcessing";
		
		Filter = New Structure();
		Filter.Insert("Key", Var_Key);
		Filter.Insert("State", BackgroundJobState.Active);
		
		ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
		
		If ActiveTasks.Count()>0 Then
			
			Try
				ActiveTasks[0].WaitForCompletion();
			Except
				// Special processing is not required, the exception may be caused by a timeout.
			EndTry;
			
		EndIf;
		
	EndIf;
	
	Query = New Query();
	Query.Text = 
	"SELECT TOP 1
	|	PlanSubstitution.PlanProfile AS PlanProfile
	|FROM
	|	InformationRegister.PlanSubstitution AS PlanSubstitution
	|WHERE
	|	PlanSubstitution.PlanProfile.Owner = &Scenario
	|	AND (PlanSubstitution.ForSubstitution OR PlanSubstitution.ForSubstitutionCancellation)";
	Query.SetParameter("Scenario", Scenario);
	If Query.Execute().Select().Next() Then
		Var_Key = "PlanSubstitution";
		
		Filter = New Structure();
		Filter.Insert("Key", Var_Key);
		Filter.Insert("State", BackgroundJobState.Active);
		
		ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
		
		If ActiveTasks.Count() > 0 Then
			Try
				ActiveTasks[0].WaitForCompletion();
			Except
				// Special processing is not required, the exception may be caused by a timeout.
			EndTry;
		EndIf;
		
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Procedure for creating and filling out a deficit plan
//
// Parameters:
//  Scenario  - CatalogRef.SalesOperationsPlanningScenarios - the scenario for which the calculation is performed.
//  PlanProfile  - CatalogRef.PlanProfiles - type of plan for which the calculation is made.
//  BeginOfPeriod  - Date - start of the plan period.
//  PeriodEnding  - Date - end of the plan period.
//  ObjectPlan  - DocumentObject.PurchasePlan, DocumentObject.AssemblyDisassemblyPlan, DocumentObject.ProductionPlan - the plan for which the deficit is recalculated.
//
Procedure FillOutDeficitPlans(Scenario, PlanProfile, BeginOfPeriod, PeriodEnding, ObjectPlan = Undefined) Export
	
	FillInDeficitsFromPlan = False;
	If ObjectPlan <> Undefined Then
		FillInDeficitsFromPlan = True;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	
	Try
		
		Attributes = "PlanType, NumberOfPeriods, FillInBusinessUnit, FillInCompany, FillInPartner, PriceKind,
		|FillInPartnerInTabularForm, FillInTermsOfSales, FillInAgreementInTabularForm, FillInWarehouse, FillInWarehouseInTabularForm, FillInAssignmentInTabularForm,
		|DisableEditingOfRule, FillInUsingFormula, FillInByShortage, AutoFill, Substitutional, FillInPaymentPlan,"+ 
		"PlanSemiFinishedProductsAutomatically, ProductionProcessType, FillInBOMByPeriods,"+
		"Parent";
		
		PlanViewParameters = Common.ObjectAttributesValues(PlanProfile, Attributes);
		
		Block = New DataLock;
		
		LockItem = Block.Add("InformationRegister.CalculationOfPlanShortagesByStages");
		LockItem.SetValue("Scenario", Scenario);
		LockItem.SetValue("PlanProfile", PlanProfile);
		LockItem.SetValue("PlanningPeriod", BeginOfPeriod);
		LockItem.Mode = DataLockMode.Exclusive;
		If Common.FileInfobase()
			And PlanViewParameters.PlanType = Enums.TypesOfPlans.ProductionPlan Then
			LockItem = Block.Add("Document.ProductionPlan");
			LockItem.SetValue("PlanProfile", PlanProfile);
			LockItem.Mode = DataLockMode.Exclusive;
		EndIf;
		Block.Lock();
		
		If ObjectPlan = Undefined Then
			Query = New Query;
			Query.Text = 
			"SELECT TOP 1
			|	PurchasePlan.Ref AS Ref
			|FROM
			|	Document.PurchasePlan AS PurchasePlan
			|WHERE
			|	PurchasePlan.BeginOfPeriod <= &PeriodEnding
			|	AND PurchasePlan.PeriodEnding >= &BeginOfPeriod
			|	AND PurchasePlan.PlanProfile = &PlanProfile
			|	AND PurchasePlan.Posted
			|
			|UNION ALL
			|
			|SELECT TOP 1
			|	ProductionPlan.Ref
			|FROM
			|	Document.ProductionPlan AS ProductionPlan
			|WHERE
			|	ProductionPlan.BeginOfPeriod <= &PeriodEnding
			|	AND ProductionPlan.PeriodEnding >= &BeginOfPeriod
			|	AND ProductionPlan.PlanProfile = &PlanProfile
			|	AND ProductionPlan.Posted
			|
			|UNION ALL
			|
			|SELECT TOP 1
			|	AssemblyDisassemblyPlan.Ref
			|FROM
			|	Document.AssemblyDisassemblyPlan AS AssemblyDisassemblyPlan
			|WHERE
			|	AssemblyDisassemblyPlan.BeginOfPeriod <= &PeriodEnding
			|	AND AssemblyDisassemblyPlan.PeriodEnding >= &BeginOfPeriod
			|	AND AssemblyDisassemblyPlan.PlanProfile = &PlanProfile
			|	AND AssemblyDisassemblyPlan.Posted";
			
			TablePeriods = Undefined;
			Query.SetParameter("PlanProfile", PlanProfile);
			Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
			Query.SetParameter("PeriodEnding", PeriodEnding);
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				ObjectPlan = Selection.Ref.GetObject();
				ObjectPlan.Lock();
			EndIf;
		EndIf;
		
		If ObjectPlan = Undefined Then
			
			PlanType = Common.ObjectAttributeValue(PlanProfile, "PlanType");
			
			If PlanType = Enums.TypesOfPlans.PurchasePlan Then
				ObjectPlan = Documents.PurchasePlan.CreateDocument();
			ElsIf PlanType = Enums.TypesOfPlans.ProductionPlan Then
				ObjectPlan = Documents.ProductionPlan.CreateDocument();
			ElsIf PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan Then
				ObjectPlan = Documents.AssemblyDisassemblyPlan.CreateDocument();
			EndIf;
			
			FillPropertyValues(ObjectPlan, PlanViewParameters);
			
		EndIf;
		
		If PlanViewParameters.PlanType = Enums.TypesOfPlans.PurchasePlan Then
			GoodsTable = ObjectPlan.Goods;
			PeriodColumnName = "DateOfReceipt";
			TabularSectionName = "Goods";
		ElsIf PlanViewParameters.PlanType = Enums.TypesOfPlans.ProductionPlan Then
			GoodsTable = ObjectPlan.ManufacturedProduct;
			PeriodColumnName = "DateOfProduction";
			TabularSectionName = "ManufacturedProduct";
		ElsIf PlanViewParameters.PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan Then
			GoodsTable = ObjectPlan.Goods;
			PeriodColumnName = "DateOfAssemblyDisassembly";
			TabularSectionName = "Goods";
		EndIf;
		
		QueryText = GenerateTextOfRequestToFillInDeficit(PlanViewParameters, ObjectPlan, FillInDeficitsFromPlan);
		
		Query = New Query;
		Query.Text = QueryText;
		
		Query.SetParameter("Scenario", Scenario);
		Query.SetParameter("PlanProfile", PlanProfile);
		Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
		Query.SetParameter("Ref", ObjectPlan.Ref);
		
		SetPrivilegedMode(True);
		RequestPackage = Query.ExecuteBatch();
		SetPrivilegedMode(False);
		
		// If there are no records in the table of changes, then there is no need to recalculate
		If RequestPackage[0].Unload()[0].Count = 0 Then
			RollbackTransaction();
			Return;
		EndIf;
		
		ModifiedGoods = RequestPackage[2].Unload();
		CanceledAdjustments = RequestPackage[3].Unload();
		
		If CanceledAdjustments.Count()>0 Then
			RecordSet = InformationRegisters.CancelAdjustmentsOfSupplyPlans.CreateRecordSet();
			RecordSet.Filter.Plan.Set(ObjectPlan.Ref);
			RecordSet.Load(CanceledAdjustments);
			RecordSet.Write();
		EndIf;
		
		If Not FillInDeficitsFromPlan Then
			If Not ValueIsFilled(ObjectPlan.Ref) Then
				FillingData = New Structure();
				FillingData.Insert("Scenario", Scenario);
				FillingData.Insert("PlanProfile", PlanProfile);
				FillingData.Insert("BeginOfPeriod", BeginOfPeriod);
				FillingData.Insert("PeriodEnding", PeriodEnding);
				FillingData.Insert("Status", Enums.PlanStatuses.AwaitingConfirmation);
				ObjectPlan.Fill(FillingData);
				ObjectPlan.CrossTable = False;
			EndIf;
			ObjectPlan.Status = Enums.PlanStatuses.AwaitingConfirmation;
		EndIf;
		
		ObjectPlan[TabularSectionName].Load(ModifiedGoods);
		If FillInDeficitsFromPlan Then
			CommitTransaction();
			Return;
		EndIf;
		
		// Fill in prices
		If PlanViewParameters.PlanType = Enums.TypesOfPlans.PurchasePlan
			And ObjectPlan.PlanByAmount
			And ValueIsFilled(PlanViewParameters.PriceKind) Then
			JobParameters = New Structure();
			ObjectPlan.PrepareParametersForFillingInPrices(JobParameters);
			TablePeriods = TablePeriods();
			Periodicity = Common.ObjectAttributeValue(Scenario, "Periodicity");
			Planning.FillInPeriodTable(TablePeriods, Periodicity, BeginOfPeriod, PeriodEnding);
			
			JobParameters.Insert("TimeIntervals", TablePeriods);
			Result = Planning.FillInFormula(JobParameters);
			ObjectPlan.Goods.Load(Result);
		EndIf;
		
		// Recalculate the number of packages and the amount
		StructureOfActions = New Structure;
		
		If PlanViewParameters.PlanType = Enums.TypesOfPlans.PurchasePlan Then
			StructureOfActions.Insert("RecalculateAmount");
			GoodsTable = ObjectPlan[TabularSectionName].Unload();
			BatchProcessingOfTablePartServer.TreatTS(GoodsTable, StructureOfActions, Undefined);
			ObjectPlan[TabularSectionName].Load(GoodsTable);
		EndIf;
		
		If PlanViewParameters.PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan Then
			ObjectPlan.DetermineConfigurationOption();
		EndIf;
		If PlanViewParameters.PlanType = Enums.TypesOfPlans.ProductionPlan Then
			
			BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(ObjectPlan, Documents.ProductionPlan);
			
			RowsArray = New Array;
			AssignmentsArray = New Array;
			For Each RowOfProduct In ObjectPlan.ManufacturedProduct Do
				RowsArray.Add(RowOfProduct);
				AssignmentsArray.Add(RowOfProduct.Purpose);
			EndDo;
			
			AttributesValues = Common.ObjectsAttributeValue(AssignmentsArray, "LineOfBusiness");
			
			For Each String In RowsArray Do
				String.LineOfBusiness = AttributesValues[String.Purpose];
			EndDo;
			
			TableDetails = New Structure("TS, TSName, DataPath");
			TableDetails.DataPath = "Object.ManufacturedProduct";
			TableDetails.TS          = ObjectPlan.ManufacturedProduct;
			TableDetails.TSName       = "ManufacturedProduct";
			
			ProductData_2 = New Array;
			
			For Each String In RowsArray Do
				
				ProductData = ProductDataManagementClientServer.CollectProductDataForSpecificationSelection(
					ObjectPlan, String, BOMSelectionParameters,, New Structure("KeyOfDataPaths", TableDetails.DataPath));
				ProductData_2.Add(ProductData);
				
			EndDo;
			
			ProductDataManagement.FillInSpecificationInLines(RowsArray, ProductData_2, BOMSelectionParameters);
			
			GetDurationSpecificationsAndFillDatesOnSchedule(
				ObjectPlan.ManufacturedProduct,
				"DateOfProduction",
				"StartDate2",
				ObjectPlan.Scenario,
				False,
				ObjectPlan.DemandForMaterials);
		
		EndIf;
		// Recalculate the amount of the document
		If PlanViewParameters.PlanType = Enums.TypesOfPlans.PurchasePlan
			And ObjectPlan.PlanByAmount Then
			ObjectPlan.DocumentAmount = 0;
			
			For Each TSRow In ObjectPlan.Goods Do
				
				ObjectPlan.DocumentAmount = ObjectPlan.DocumentAmount + TSRow.Sum;
				
			EndDo;
			
		EndIf;
		
		If ObjectPlan[TabularSectionName].Count() = 0 Then
			If ObjectPlan.Posted  Then
				ObjectPlan.Write(DocumentWriteMode.UndoPosting);
			EndIf;
		Else
			ObjectPlan.Write(DocumentWriteMode.Posting);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();

		DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
		
		MessageText = NStr("vi = 'Không thể hoàn thành các kế hoạch thâm hụt do %Cause%';
							|ru = 'Не удалось выполнить формирование планов по дефициту по причине %Cause%';
							|en = 'Cannot form plans by shortage. Reason: %Cause%'; fa = 'Cannot form plans by shortage. Reason: %Cause%';
							|it = 'Non è stato possibile effettuare la generazione dei piani relativi al budget a causa di %Cause%';
							|pl = 'Nie udało się wykonać tworzenie planów według niedoboru z powodu %Cause%';
							|tr = '%Cause% sebebiyle mali açığa göre planının oluşturulması işlemi yerine getirilemedi'");
		MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(NStr("vi = 'Tạo kế hoạch theo thâm hụt';
							|ru = 'Формирование планов по дефициту';
							|en = 'Form plans by shortage'; fa = 'Form plans by shortage';
							|it = 'Generazione dei piani relativi al budget';
							|pl = 'Tworzenie planów według niedoboru';
							|tr = 'Mali açığa göre plan oluşturma'", DefaultLanguageCode),
			EventLogLevel.Error,
			,
			,
			MessageText);
		Raise;
	EndTry;
	
EndProcedure

Function GenerateTextOfRequestToFillInDeficit(PlanViewParameters, ObjectPlan, FillInDeficitsFromPlan)
	
	If PlanViewParameters.PlanType = Enums.TypesOfPlans.PurchasePlan Then
		GoodsTable = ObjectPlan.Goods;
		PeriodColumnName = "DateOfReceipt";
		TabularSectionName = "Goods";
	ElsIf PlanViewParameters.PlanType = Enums.TypesOfPlans.ProductionPlan Then
		GoodsTable = ObjectPlan.ManufacturedProduct;
		PeriodColumnName = "DateOfProduction";
		TabularSectionName = "ManufacturedProduct";
	ElsIf PlanViewParameters.PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan Then
		GoodsTable = ObjectPlan.Goods;
		PeriodColumnName = "DateOfAssemblyDisassembly";
		TabularSectionName = "Goods";
	EndIf;
	
	If TypeOf(ObjectPlan) = Type("FormDataStructure") Then
		GoodsTable = GoodsTable.Unload();
	EndIf;
	
	QueryTextSampleFieldsOfCalculationTable = "&Ref AS Ref,"  + Chars.LF;
	QueryTextSelectionFieldsOfPlanTable = "PlanTable.Ref AS Ref," + Chars.LF;
	QueryTextSelectionFieldsOfChangeTable = "PlanTable.Ref AS Plan," + Chars.LF;
	
	For Each Column In GoodsTable.UnloadColumns().Columns Do
		
		If Column.Name = "Products"
			Or Column.Name = "Characteristic"
			Or Column.Name = "Purpose" Then
			QueryTextSampleFieldsOfCalculationTable = QueryTextSampleFieldsOfCalculationTable + "CalculationOfPlanShortagesByStages." + Column.Name + " AS " + Column.Name + "," + Chars.LF;
			QueryTextSelectionFieldsOfPlanTable = QueryTextSelectionFieldsOfPlanTable+ "ISNULL(RecalculateTable." + Column.Name + ",PlanTable." + Column.Name + ") AS " + Column.Name + "," + Chars.LF;
		ElsIf Column.Name = PeriodColumnName Then
			QueryTextSampleFieldsOfCalculationTable = QueryTextSampleFieldsOfCalculationTable + "CalculationOfPlanShortagesByStages.PlanningPeriod AS " + Column.Name + "," + Chars.LF;
			QueryTextSelectionFieldsOfPlanTable = QueryTextSelectionFieldsOfPlanTable+ "ISNULL(RecalculateTable." + Column.Name + ",PlanTable." + Column.Name + ") AS " + Column.Name + "," + Chars.LF;
		ElsIf Column.Name = "Count"
			Or Column.Name = "NumberOfPackages" Then
			QueryTextSampleFieldsOfCalculationTable = QueryTextSampleFieldsOfCalculationTable + "CalculationOfPlanShortagesByStages.ToSupply + CalculationOfPlanShortagesByStages.ToChange AS " + Column.Name + "," + Chars.LF;
			QueryTextSelectionFieldsOfPlanTable = QueryTextSelectionFieldsOfPlanTable + "ISNULL(RecalculateTable." + Column.Name + ",PlanTable." + Column.Name + ") AS " + Column.Name + "," + Chars.LF;
		ElsIf Column.Name = "Comment" Then
			QueryTextSampleFieldsOfCalculationTable = QueryTextSampleFieldsOfCalculationTable + "CAST("""" AS STRING(1024)) AS " + Column.Name + "," + Chars.LF;
			QueryTextSelectionFieldsOfPlanTable = QueryTextSelectionFieldsOfPlanTable + "CAST(" + "ISNULL(RecalculateTable." + Column.Name + ",PlanTable." + Column.Name + ") AS STRING(1024))" + " AS " + Column.Name + "," + Chars.LF;
		ElsIf Column.Name = "AdditionalParameters" Then
			Continue;
		ElsIf Column.Name = "RangeOfDemandFrom"
			Or Column.Name = "RangeOfDemandTo" Then
			QueryTextSampleFieldsOfCalculationTable = QueryTextSampleFieldsOfCalculationTable + "CalculationOfPlanShortagesByStages." + Column.Name + " AS " + Column.Name + "," + Chars.LF;
			
			QueryTextSelectionFieldsOfPlanTable = QueryTextSelectionFieldsOfPlanTable + "CASE
			|		WHEN ISNULL(RecalculateTable.DemandRangeIsSpecified, PlanTable.DemandRangeIsSpecified)
			|				AND ISNULL(RecalculateTable.RangeOfDemandFrom, PlanTable.RangeOfDemandFrom) <= ISNULL(RecalculateTable.Count, PlanTable.Count)
			|				AND ISNULL(RecalculateTable.RangeOfDemandTo, PlanTable.RangeOfDemandTo) >= ISNULL(RecalculateTable.Count, PlanTable.Count)
			|			THEN ISNULL(RecalculateTable." + Column.Name + ", PlanTable." + Column.Name + ")
			|		ELSE 0
			|	END AS " + Column.Name + "," + Chars.LF;
			
		ElsIf Column.Name = "DemandRangeIsSpecified" Then
			QueryTextSampleFieldsOfCalculationTable = QueryTextSampleFieldsOfCalculationTable + "CalculationOfPlanShortagesByStages." + Column.Name + " AS " + Column.Name + "," + Chars.LF;
			QueryTextSelectionFieldsOfPlanTable = QueryTextSelectionFieldsOfPlanTable + "CASE
			|		WHEN ISNULL(RecalculateTable.DemandRangeIsSpecified, PlanTable.DemandRangeIsSpecified)
			|				AND ISNULL(RecalculateTable.RangeOfDemandFrom, PlanTable.RangeOfDemandFrom) <= ISNULL(RecalculateTable.Count, PlanTable.Count)
			|				AND ISNULL(RecalculateTable.RangeOfDemandTo, PlanTable.RangeOfDemandTo) >= ISNULL(RecalculateTable.Count, PlanTable.Count)
			|			THEN ISNULL(RecalculateTable." + Column.Name + ", PlanTable." + Column.Name + ")
			|		ELSE FALSE
			|	END AS " + Column.Name + "," + Chars.LF;
		Else
			QueryTextSampleFieldsOfCalculationTable = QueryTextSampleFieldsOfCalculationTable + "NULL AS " + Column.Name + "," + Chars.LF;
			QueryTextSelectionFieldsOfPlanTable = QueryTextSelectionFieldsOfPlanTable + "PlanTable." + Column.Name + " AS " + Column.Name + "," + Chars.LF;
		EndIf;
		
	EndDo;
	
	RequestTextForRecalculationConditions = "";
	If Not FillInDeficitsFromPlan Then
		RequestTextForRecalculationConditions = "AND CalculationOfPlanShortagesByStages.ShouldRecalculate";
	EndIf;
	
	QueryText = 
	"SELECT
	|&QueryTextAndCalculationTableSelectionFields
	|INTO RecalculateTable
	|FROM
	|	InformationRegister.CalculationOfPlanShortagesByStages AS CalculationOfPlanShortagesByStages
	|WHERE
	|	CalculationOfPlanShortagesByStages.PlanProfile = &PlanProfile
	|	AND CalculationOfPlanShortagesByStages.Scenario = &Scenario
	|	AND CalculationOfPlanShortagesByStages.PlanningPeriod = &BeginOfPeriod
	|	AND &RequestTextForRecalculationConditions
	|	AND CalculationOfPlanShortagesByStages.Products <> VALUE(Catalog.Products.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	*
	|INTO PlanTable
	|FROM
	|	&QueryTextTablePlan_ AS PlanTable
	|WHERE
	|	PlanTable.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|&QueryTextAndSelectionFieldsOfPlanTable
	|FROM
	|	PlanTable AS PlanTable
	|	FULL JOIN RecalculateTable AS RecalculateTable
	|		ON PlanTable.Products = RecalculateTable.Products
	|		AND PlanTable.CHARACTERISTIC = RecalculateTable.CHARACTERISTIC
	|		AND PlanTable.Purpose = RecalculateTable.Purpose
	|WHERE
	|	ISNULL(RecalculateTable.Count, PlanTable.Count) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|PlanTable.Ref AS Plan,
	|ISNULL(PlanTable.Products,RecalculateTable.Products) AS Products,
	|ISNULL(PlanTable.CHARACTERISTIC,RecalculateTable.CHARACTERISTIC) AS Characteristic,
	|ISNULL(PlanTable.Count,RecalculateTable.Count) AS ToSupply_,
	|&QueryTextPlanningPeriod AS PlanningPeriod,
	|CAST(ISNULL(PlanTable.Comment,RecalculateTable.Comment) AS STRING(1024)) AS Comment,
	|ISNULL(PlanTable.Purpose,RecalculateTable.Purpose) AS Purpose,
	|ISNULL(PlanTable.RangeOfDemandFrom, RecalculateTable.RangeOfDemandFrom) AS RangeOfDemandFrom,
	|ISNULL(RecalculateTable.RangeOfDemandTo, RecalculateTable.RangeOfDemandTo) AS RangeOfDemandTo
	|FROM
	|PlanTable AS PlanTable
	|FULL JOIN RecalculateTable AS RecalculateTable
	|	ON PlanTable.Products = RecalculateTable.Products
	|	AND PlanTable.CHARACTERISTIC = RecalculateTable.CHARACTERISTIC
	|	AND PlanTable.Purpose = RecalculateTable.Purpose
	|WHERE
	|	ISNULL(PlanTable.DemandRangeIsSpecified, RecalculateTable.DemandRangeIsSpecified)
	|	AND NOT (ISNULL(PlanTable.RangeOfDemandFrom, RecalculateTable.RangeOfDemandFrom) <= ISNULL(RecalculateTable.Count, PlanTable.Count)
	|		AND ISNULL(PlanTable.RangeOfDemandTo, RecalculateTable.RangeOfDemandTo) >= ISNULL(RecalculateTable.Count, PlanTable.Count))";
	
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextAndCalculationTableSelectionFields", 
		Left(QueryTextSampleFieldsOfCalculationTable, StrLen(QueryTextSampleFieldsOfCalculationTable)-2));
	
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextAndSelectionFieldsOfPlanTable", 
		Left(QueryTextSelectionFieldsOfPlanTable, StrLen(QueryTextSelectionFieldsOfPlanTable)-2));
	
	QueryText = StrReplace(
		QueryText, 
		"AND &RequestTextForRecalculationConditions", 
		RequestTextForRecalculationConditions);
	
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextTablePlan_", 
		"Document."+ObjectPlan.Metadata().Name+"." + TabularSectionName + "");
	
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPlanningPeriod", 
		"ISNULL(PlanTable."+PeriodColumnName+",RecalculateTable."+PeriodColumnName+")");
	
	Return QueryText
	
EndFunction

// The procedure fills in the deficit plan if AutoFill is enabled
//
// Parameters:
//  Scenario - CatalogRef.SalesOperationsPlanningScenarios - scenario for which the need to fill in the plan is calculated
//
Procedure CalculateAndFillDeficitPlansAutomatically(Scenario) Export
	
	Query = New Query();
	Query.Text = 
	"SELECT DISTINCT
	|	CalculationOfPlanShortagesByStages.Scenario AS Scenario,
	|	CalculationOfPlanShortagesByStages.PlanProfile AS PlanProfile,
	|	CalculationOfPlanShortagesByStages.PlanningPeriod AS PlanningPeriod,
	|	CalculationOfPlanShortagesByStages.ShouldRecalculate AS ShouldRecalculate,
	|	CalculationOfPlanShortagesByStages.PlanProfile.AutoFill AS AutoFill,
	|	CalculationOfPlanShortagesByStages.PlanProfile.PlanType AS PlanType,
	|	CalculationOfPlanShortagesByStages.PlanProfile.PlanningProcedure AS PlanningProcedure,
	|	CalculationOfPlanShortagesByStages.PlanProfile.Parent.PlanningProcedure AS StagePlanningOrder
	|INTO TypesOfPlansForPeriodsToRecalculate
	|FROM
	|	InformationRegister.CalculationOfPlanShortagesByStages AS CalculationOfPlanShortagesByStages
	|WHERE
	|	CalculationOfPlanShortagesByStages.Scenario = &Scenario
	|	AND CalculationOfPlanShortagesByStages.ShouldRecalculate
	|	AND NOT CalculationOfPlanShortagesByStages.PlanProfile.IsFolder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	ISNULL(PurchasePlan.Ref, VALUE(Document.PurchasePlan.EmptyRef)) AS Ref,
	|	TypesOfPlansForPeriodsToRecalculate.PlanProfile AS PlanProfile,
	|	TypesOfPlansForPeriodsToRecalculate.PlanningPeriod AS PlanningPeriod,
	|	ISNULL(PurchasePlan.AutoFill, TypesOfPlansForPeriodsToRecalculate.AutoFill) AS AutoFill,
	|	TypesOfPlansForPeriodsToRecalculate.PlanningProcedure AS PlanningProcedure,
	|	TypesOfPlansForPeriodsToRecalculate.StagePlanningOrder AS StagePlanningOrder
	|FROM
	|	TypesOfPlansForPeriodsToRecalculate AS TypesOfPlansForPeriodsToRecalculate
	|		LEFT JOIN Document.PurchasePlan AS PurchasePlan
	|		ON TypesOfPlansForPeriodsToRecalculate.PlanProfile = PurchasePlan.PlanProfile
	|			AND TypesOfPlansForPeriodsToRecalculate.PlanningPeriod = PurchasePlan.BeginOfPeriod
	|			AND PurchasePlan.Posted
	|WHERE
	|	TypesOfPlansForPeriodsToRecalculate.PlanType = VALUE(Enum.TypesOfPlans.PurchasePlan)
	|	AND ISNULL(PurchasePlan.AutoFill, TypesOfPlansForPeriodsToRecalculate.AutoFill)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	ISNULL(ProductionPlan.Ref, VALUE(Document.ProductionPlan.EmptyRef)),
	|	TypesOfPlansForPeriodsToRecalculate.PlanProfile,
	|	TypesOfPlansForPeriodsToRecalculate.PlanningPeriod,
	|	ISNULL(ProductionPlan.AutoFill, TypesOfPlansForPeriodsToRecalculate.AutoFill),
	|	TypesOfPlansForPeriodsToRecalculate.PlanningProcedure,
	|	TypesOfPlansForPeriodsToRecalculate.StagePlanningOrder
	|FROM
	|	TypesOfPlansForPeriodsToRecalculate AS TypesOfPlansForPeriodsToRecalculate
	|		LEFT JOIN Document.ProductionPlan AS ProductionPlan
	|		ON TypesOfPlansForPeriodsToRecalculate.PlanProfile = ProductionPlan.PlanProfile
	|			AND TypesOfPlansForPeriodsToRecalculate.PlanningPeriod = ProductionPlan.BeginOfPeriod
	|			AND ProductionPlan.Posted
	|WHERE
	|	TypesOfPlansForPeriodsToRecalculate.PlanType = VALUE(Enum.TypesOfPlans.ProductionPlan)
	|	AND ISNULL(ProductionPlan.AutoFill, TypesOfPlansForPeriodsToRecalculate.AutoFill)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	ISNULL(AssemblyDisassemblyPlan.Ref, VALUE(Document.AssemblyDisassemblyPlan.EmptyRef)),
	|	TypesOfPlansForPeriodsToRecalculate.PlanProfile,
	|	TypesOfPlansForPeriodsToRecalculate.PlanningPeriod,
	|	ISNULL(AssemblyDisassemblyPlan.AutoFill, TypesOfPlansForPeriodsToRecalculate.AutoFill),
	|	TypesOfPlansForPeriodsToRecalculate.PlanningProcedure,
	|	TypesOfPlansForPeriodsToRecalculate.StagePlanningOrder
	|FROM
	|	TypesOfPlansForPeriodsToRecalculate AS TypesOfPlansForPeriodsToRecalculate
	|		LEFT JOIN Document.AssemblyDisassemblyPlan AS AssemblyDisassemblyPlan
	|		ON TypesOfPlansForPeriodsToRecalculate.PlanProfile = AssemblyDisassemblyPlan.PlanProfile
	|			AND TypesOfPlansForPeriodsToRecalculate.PlanningPeriod = AssemblyDisassemblyPlan.BeginOfPeriod
	|			AND AssemblyDisassemblyPlan.Posted
	|WHERE
	|	TypesOfPlansForPeriodsToRecalculate.PlanType = VALUE(Enum.TypesOfPlans.AssemblyDisassemblyPlan)
	|	AND ISNULL(AssemblyDisassemblyPlan.AutoFill, TypesOfPlansForPeriodsToRecalculate.AutoFill)
	|
	|ORDER BY
	|	StagePlanningOrder,PlanningProcedure,PlanningPeriod";
	
	Query.SetParameter("Scenario", Scenario);
	
	ScenarioStatuses = New Array;
	ScenarioStatuses.Add(Enums.PlanStatuses.Upholded);
	ScenarioStatuses.Add(Enums.PlanStatuses.AwaitingConfirmation);
	
	Query.SetParameter("Scenario", Scenario);
	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	
	Periodicity = Common.ObjectAttributeValue(Scenario, "Periodicity");
	If Selection.Next() Then
		
		PeriodEnding = TMCommonUseClientServer.CalculatePeriodEndDate(Selection.PlanningPeriod, Periodicity, 1);
		FillOutDeficitPlans(Scenario, Selection.PlanProfile, Selection.PlanningPeriod, PeriodEnding);
		
	EndIf;
	
EndProcedure

// The procedure fills the queue and starts a background recalculation recalculation of plans for the deficit 
//
// Parameters:
//  Scenario - CatalogRef.SalesOperationsPlanningScenarios - scenario for which a full recalculation is performed
//
Procedure StartingBackgroundRecalculationOfDeficitInStages(Scenario) Export
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.ShortagesCalculationQueueInStages");
		LockItem.SetValue("Scenario", Scenario);
		LockItem.Mode = DataLockMode.Exclusive;
		
		LockItem = Block.Add("InformationRegister.CalculationOfPlanShortagesByStages");
		LockItem.SetValue("Scenario", Scenario);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		Query = New Query();
		Query.Text = 
		"SELECT DISTINCT
		|	CalculationOfPlanShortagesByStages.Scenario AS Scenario,
		|	CalculationOfPlanShortagesByStages.PlanningPeriod AS PlanningPeriod,
		|	CalculationOfPlanShortagesByStages.Products AS Products,
		|	CalculationOfPlanShortagesByStages.Characteristic AS Characteristic,
		|	CalculationOfPlanShortagesByStages.Purpose AS Purpose
		|FROM
		|	InformationRegister.CalculationOfPlanShortagesByStages AS CalculationOfPlanShortagesByStages
		|WHERE
		|	CalculationOfPlanShortagesByStages.Scenario = &Scenario";
		Query.SetParameter("Scenario", Scenario);
		InventoryToRecount = Query.Execute().Unload();
		
		RecordSet = InformationRegisters.ShortagesCalculationQueueInStages.CreateRecordSet();
		RecordSet.Filter.Scenario.Set(Scenario);
		
		RecordSet.Load(InventoryToRecount);
		RecordSet.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
		
		MessageText = NStr("vi = 'Không thể phong tỏa các biểu ghi ""Hàng đợi để tính toán thâm hụt theo kế hoạch"" và ""Tính toán thâm hụt theo các kỳ""';
							|ru = 'Не удалось выполнить блокировку регистров ""Очередь расчета дефицитов по планам"" и ""Расчет дефицитов по этапам""';
							|en = 'Failed to lock registers ""Queue for calculation of shortages by plans"" and ""Calculation of shortages by stages""'; fa = 'Failed to lock registers ""Queue for calculation of shortages by plans"" and ""Calculation of shortages by stages""';
							|it = 'Non è stato possibile effettuare il blocco dei registri """"La coda per calcolare i deficit in base ai piani"" e ""Calcolo dei deficit per fasi""';
							|pl = 'Nie udało się wykonać blokadę rejestrów ""Kolejka obliczenia niedoborów według planów"" i ""Obliczanie niedoborów według etapów""';
							|tr = '""Aşamalara göre mali açık hesaplamalarının sırası"" ve ""Aşamalara göre mali açık hesaplaması"" kayıtlarının kilitlenmesi işlemi yerine getirilemedi.'");
		WriteLogEvent(NStr("vi = 'Bắt đầu tính toán lại toàn bộ thâm hụt';
							|ru = 'Запуск полного пересчета по дефицитам';
							|en = 'Run full shortages recalculation'; fa = 'Run full shortages recalculation';
							|it = 'Avvio del ricalcolo completo relativo ai deficit';
							|pl = 'Uruchomienie pełnego przeliczania według niedoborów';
							|tr = 'Mali açıklara göre alan yeniden hesaplamasının girişi'", DefaultLanguageCode),
			EventLogLevel.Error,
			,
			,
			MessageText);
				
		Return;
	EndTry;
	
	StartingBackgroundCalculationOfDeficitInStages(Scenario);
	
EndProcedure

Procedure GenerateAdjustmentsToPlannedNeeds(AddressInStorage, AdjustmentParameters) Export
	
	ReplacementTable = GetFromTempStorage(AddressInStorage);
	
	AdjustmentOfPlannedNeeds = Documents.AdjustmentOfPlannedDemand.CreateDocument();

	For Each ReplacementString In ReplacementTable Do
		
		If ReplacementString.ThisIsASubstitute Then
			NewRow = AdjustmentOfPlannedNeeds.IncreasedDemand.Add();
		Else
			NewRow = AdjustmentOfPlannedNeeds.DecreasedDemands.Add();
		EndIf;
			
		FillPropertyValues(NewRow, ReplacementString);
		NewRow.Purpose = AdjustmentParameters.AssigningAdjustment;
		
	EndDo;
	
	FillPropertyValues(AdjustmentOfPlannedNeeds, AdjustmentParameters);
	AdjustmentOfPlannedNeeds.AdjustmentInputModeMultiline = ReplacementTable.Count()>2;
	AdjustmentOfPlannedNeeds.Date = CurrentSessionDate();
	AdjustmentOfPlannedNeeds.Status = Enums.StatusesOfPlanAdjustments.Upholded_;
	AdjustmentOfPlannedNeeds.Write(DocumentWriteMode.Posting);
	
EndProcedure

#EndRegion

#Region ImportDataFromFile

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
// 
// Parameters:
// 	AddressOfUploadedData- String - address of the temporary storage with a table of values that
//                                   contains the downloaded data from the file.
// 	AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                                       which is a copy of the table part of the document 
//                                       that needs to be filled in from the addressable Data table.
// 	ConflictsList - ValueTable - consists of:
//  * Id - Number - Id
//  * Column - String - column name
// 	FullTabularSectionName - String - full name of the table part
// 	AdditionalParameters - See PlanningClient.AdditionalParametersForDownloadingFromFile
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	
	Goods = GetFromTempStorage(AddressOfMappingTable);// ValueTable
	DataToImport = GetFromTempStorage(AddressOfUploadedData);// ValueTable
	Goods.Columns.Delete("AdditionalParameters");
	
	QueryTexts = New Array;
	QueryTexts.Add(TextOfRequestTTUploadedDataProducts());
	QueryTexts.Add(QueryTextTTBarcodeData());
	QueryTexts.Add(QueryTextTTProductData());
	QueryTexts.Add(QueryTextTTCharacteristicsData());
	QueryTexts.Add(QueryTextTTPackingData());
	
	If AdditionalParameters.AssignmentsAreUsed Then
		QueryTexts.Add(QueryTextTTDestinationData());
	EndIf;
	If AdditionalParameters.SpecificationsAreUsed Then
		QueryTexts.Add(QueryTextTTSpecificationsData());
	EndIf;
	If AdditionalParameters.WarehousesAreUsed Then
		QueryTexts.Add(QueryTextTTWarehouseData());
	EndIf;
	If AdditionalParameters.PartnersAreUsed Then
		QueryTexts.Add(QueryTextTTPartnerData());
	EndIf;
	If AdditionalParameters.AgreementsAreUsed Then
		QueryTexts.Add(QueryTextTTDataAgreements(AdditionalParameters.PlanType));
	EndIf;
	If AdditionalParameters.TypesOfPricesAreUsed Then
		QueryTexts.Add(QueryTextTTTheseTypesOfPrices());
	EndIf;
	If AdditionalParameters.PlanType = "AssemblyDisassemblyPlan" Then
		QueryTexts.Add(QueryTextTTDataOfConfigurationOptions());
	EndIf;
	QueryTexts.Add(RequestTextUploadedProductData());
	
	If AdditionalParameters.CrossTable Then
		If AdditionalParameters.PlanType = "PurchasePlan" Then
			NameOfPlanPeriod = "DateOfReceipt";
		ElsIf AdditionalParameters.PlanType = "ProductionPlan" Then
			NameOfPlanPeriod = "DateOfProduction";
		ElsIf AdditionalParameters.PlanType = "InventoryConsumptionPlan"
			Or AdditionalParameters.PlanType = "SalesPlan" Then
			NameOfPlanPeriod = "DateOfShipment";
		ElsIf AdditionalParameters.PlanType = "AssemblyDisassemblyPlan" Then
			NameOfPlanPeriod = "DateOfAssemblyDisassembly";
		EndIf;
	EndIf;
	
	Query = CreateConfigureRequest(QueryTexts, DataToImport, AdditionalParameters);// Query
	Result = Query.Execute().Unload();
	
	Id = 1;
	For Each String In Result Do
		
		If AdditionalParameters.CrossTable Then
			
			StringOfDataToLoad = DataToImport.Find(String.Id, "Id");
			
			For Each Period In AdditionalParameters.TimeIntervals Do
				
				// Parallel replenishment of the downloaded data for the correct operation of the BSP mechanism
				StringOfDataToLoad.Id = Id;
				FillPropertyValues(DataToImport.Add(), StringOfDataToLoad);
				
				NewRow = Goods.Add();
				String.Id = Id;
				FillPropertyValues(NewRow, String);
				NewRow.Id = Id;
				NewRow.NumberOfPackages = String["NumberOfPackages_" + Period.ColumnName];
				NewRow[NameOfPlanPeriod] = Period.StartDate;
				
				If AdditionalParameters.PlanByAmount Then
					
					NewRow.Price = String["Price_" + Period.ColumnName];
					NewRow.Sum = String["Sum_" + Period.ColumnName];
					
					If NewRow.Sum = 0 And NewRow.NumberOfPackages = 0 Then
						NewRow.Sum = NewRow.Price;
					ElsIf NewRow.Sum = 0 And NewRow.NumberOfPackages <> 0 Then
						NewRow.Sum = NewRow.NumberOfPackages * NewRow.Price;
					EndIf;
				EndIf;
				
				CreateAmbiguityRecords(ConflictsList, String, AdditionalParameters);
				
				Id = Id + 1;
				
			EndDo;
			
		Else
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, String);
			
			If AdditionalParameters.PlanByAmount Then
				If NewRow.Sum = 0 And NewRow.NumberOfPackages = 0 Then
					NewRow.Sum = NewRow.Price;
				ElsIf NewRow.Sum = 0 And NewRow.NumberOfPackages <> 0 Then
					NewRow.Sum = NewRow.NumberOfPackages * NewRow.Price;
				EndIf;
			EndIf;
			
			CreateAmbiguityRecords(ConflictsList, String, AdditionalParameters);
			
		EndIf;
		
	EndDo;
	
	PutToTempStorage(Goods, AddressOfMappingTable);
	
EndProcedure

Procedure CreateAmbiguityRecords(ConflictsList, String, AdditionalParameters)
	
		If String.QuantityOfProducts > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = String.Id;
			WritingAboutAmbiguity.Column       = "Products";
		EndIf;
		
		If String.NumberOfCharacteristics > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = String.Id;
			WritingAboutAmbiguity.Column       = "Characteristic";
		EndIf;
		
		If AdditionalParameters.AssignmentsAreUsed And String.NumberOfAppointments > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = String.Id;
			WritingAboutAmbiguity.Column       = "Purpose";
		EndIf;
		
		If String.PackingQuantity > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = String.Id;
			WritingAboutAmbiguity.Column       = "Package";
		EndIf;
		If AdditionalParameters.SpecificationsAreUsed And String.NumberOfSpecifications > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = String.Id;
			WritingAboutAmbiguity.Column       = "BillOfMaterials";
		EndIf;
		If AdditionalParameters.WarehousesAreUsed And String.NumberOfWarehouses > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = String.Id;
			WritingAboutAmbiguity.Column       = "Warehouse";
		EndIf;
		
		If AdditionalParameters.PartnersAreUsed And String.NumberOfPartners > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = String.Id;
			WritingAboutAmbiguity.Column       = "Partner";
		EndIf;
		
		If AdditionalParameters.AgreementsAreUsed And String.NumberOfAgreements > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = String.Id;
			WritingAboutAmbiguity.Column       = "Terms";
		EndIf;
		
		If AdditionalParameters.TypesOfPricesAreUsed And String.NumberOfPriceTypes > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = String.Id;
			WritingAboutAmbiguity.Column       = "VendorPriceKind";
		EndIf;
		
		If AdditionalParameters.PlanType = "AssemblyDisassemblyPlan" And String.NumberOfConfigurationOptions > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = String.Id;
			WritingAboutAmbiguity.Column       = "ProductKit";
		EndIf;
EndProcedure
// Fill in the list of ambiguities.
// 
// Parameters:
//  ConflictsList - Array of ValueTableRow
//  ColumnName - String
//  LoadedValuesString - ValueTableRow
//  AdditionalParameters - See PlanningClient.AdditionalParametersForDownloadingFromFile
Procedure FillInListOfAmbiguities(ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export
	
	Query = New Query;
	
	If ColumnName = "Products" Then
		
		Query.Text =
		"SELECT DISTINCT
		|	Barcodes.Products   AS Products,
		|	Barcodes.Characteristic AS Characteristic,
		|	Barcodes.Package       AS Package
		|INTO TTBarcodeData
		|FROM
		|	InformationRegister.ItemsBarcodes AS Barcodes
		|
		|WHERE
		|	NOT &Barcode = """"
		|	AND Barcodes.Barcode = &Barcode
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CatProducts.Ref AS Ref
		|FROM
		|	(SELECT
		|		CatProducts.Ref AS Ref
		|	FROM
		|		Catalog.Products AS CatProducts
		|		
		|		LEFT JOIN TTBarcodeData AS BarcodeData_5
		|		ON TRUE
		|
		|	WHERE
		|		NOT &SKU = """"
		|		AND BarcodeData_5.Products IS NULL
		|		AND CatProducts.SKU = &SKU
		|
		|	UNION ALL
		|
		|	SELECT
		|		CatProducts.Ref AS Ref
		|	FROM
		|		Catalog.Products AS CatProducts
		|		
		|		LEFT JOIN TTBarcodeData AS BarcodeData_5
		|		ON TRUE
		|
		|	WHERE
		|		NOT &ProductsAndServicesCode = """"
		|		AND BarcodeData_5.Products IS NULL
		|		AND CatProducts.Code = &ProductsAndServicesCode
		|
		|	UNION ALL
		|
		|	SELECT
		|		CatProducts.Ref AS Ref
		|	FROM
		|		Catalog.Products AS CatProducts
		|		
		|		LEFT JOIN TTBarcodeData AS BarcodeData_5
		|		ON TRUE
		|
		|	WHERE
		|		NOT &Products = """"
		|		AND BarcodeData_5.Products IS NULL
		|		AND CatProducts.Description = &Products
		|
		|	UNION ALL
		|
		|	SELECT
		|		BarcodeData_5.Products AS Ref
		|	FROM
		|		TTBarcodeData AS BarcodeData_5
		|	) AS CatProducts
		|
		|GROUP BY
		|	CatProducts.Ref
		|";
		
		Query.SetParameter("Barcode",        LoadedValuesString.Barcode);
		Query.SetParameter("SKU",         LoadedValuesString.SKU);
		Query.SetParameter("ProductsAndServicesCode", LoadedValuesString.ProductsAndServicesCode);
		Query.SetParameter("Products",    LoadedValuesString.Products);
		
	EndIf;
	
	If ColumnName = "Characteristic" Then
		
		Query.Text =
		"SELECT
		|	Characteristics.Ref AS Ref
		|FROM
		|	Catalog.ItemsCharacteristics AS Characteristics
		|
		|WHERE
		|	NOT &Characteristic = """"
		|	AND Characteristics.Description = &Characteristic
		|";
		
		Query.SetParameter("Characteristic", LoadedValuesString.Characteristic);
		
	EndIf;
	
	If ColumnName = "Purpose" Then
		
		Query.Text =
		"SELECT
		|	Assignments.Ref AS Ref
		|FROM
		|	Catalog.Assignments AS Assignments
		|
		|WHERE
		|	NOT &Purpose = """"
		|	AND Assignments.Description = &Purpose
		|";
		
		Query.SetParameter("Purpose", LoadedValuesString.Purpose);
		
	EndIf;
	
	If ColumnName = "Package" Then
		
		Query.Text =
		"SELECT
		|	Packages.Ref AS Ref
		|FROM
		|	(SELECT
		|		Packages.Ref AS Ref
		|	FROM
		|		Catalog.PackagesAndUnitsOfMeasure AS Packages
		|
		|	WHERE
		|		NOT &PackageCode = """"
		|		AND Packages.Code = &PackageCode
		|
		|	UNION ALL
		|
		|	SELECT
		|		Packages.Ref AS Ref
		|	FROM
		|		Catalog.PackagesAndUnitsOfMeasure AS Packages
		|
		|	WHERE
		|		NOT &Package = """"
		|		AND Packages.Description = &Package
		|	) AS Packages
		|
		|GROUP BY
		|	Packages.Ref
		|";
		
		Query.SetParameter("PackageCode", LoadedValuesString.PackageCode);
		Query.SetParameter("Package",    LoadedValuesString.Package);
		
	EndIf;
	If ColumnName = "BillOfMaterials" Then
		
		Query.Text =
		"SELECT
		|	Specifications.Ref AS Ref
		|FROM
		|	Catalog.BillsOfMaterials AS Specifications
		|
		|WHERE
		|	NOT &BillOfMaterials = """"
		|	AND Specifications.Description = &BillOfMaterials
		|";
		
		Query.SetParameter("BillOfMaterials", LoadedValuesString.BillOfMaterials);
		
	EndIf;
	If ColumnName = "Warehouse" Then
		
		Query.Text =
		"SELECT
		|	Warehouses.Ref AS Ref
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|
		|WHERE
		|	NOT &Warehouse = """"
		|	AND Warehouses.Description = &Warehouse
		|";
		
		Query.SetParameter("Warehouse", LoadedValuesString.Warehouse);
		
	EndIf;
	
	If ColumnName = "Partner" Then
		
		Query.Text =
		"SELECT
		|	Partners.Ref AS Ref
		|FROM
		|	Catalog.Partners AS Partners
		|
		|WHERE
		|	NOT &Partner = """"
		|	AND Partners.Description = &Partner
		|";
		
		Query.SetParameter("Partner", LoadedValuesString.Partner);
		
	EndIf;
	
	If ColumnName = "Terms" Then
		
		Query.Text =
		"SELECT
		|	Terms1.Ref AS Ref
		|FROM
		|	Catalog.TermsOfPurchaseFromVendors AS Terms1
		|
		|WHERE
		|	NOT &Terms = """"
		|	AND Terms1.Description = &Terms
		|";
		
		Query.SetParameter("Terms", LoadedValuesString.Terms);
		
	EndIf;
	
	If ColumnName = "PriceKind" Then
		
		Query.Text =
		"SELECT
		|	TypesOfPrices.Ref AS Ref
		|FROM
		|	Catalog.VendorPriceTypes AS TypesOfPrices
		|
		|WHERE
		|	NOT &PriceKind = """"
		|	AND TypesOfPrices.Description = &PriceKind
		|";
		
		Query.SetParameter("PriceKind", LoadedValuesString.PriceKind);
		
	EndIf;
	
	If ColumnName = "ProductKit" Then
		
		Query.Text =
		"SELECT
		|	KitConfigurations.Ref AS Ref
		|FROM
		|	Catalog.ProductKitConfigurations AS KitConfigurations
		|
		|WHERE
		|	NOT &ProductKit = """"
		|	AND KitConfigurations.Description = &ProductKit
		|";
		
		Query.SetParameter("ProductKit", LoadedValuesString.ProductKit);
		
	EndIf;
	
	If ValueIsFilled(Query.Text) Then
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ConflictsList.Add(Selection.Ref);
		EndDo;
	EndIf;
	
EndProcedure

#Region RequestTextsForDownloadingDataFromFile

// Parameters:
//  QueryTexts - Array of String - Request texts
//  DataToImport - ValueTable - Uploaded data
//  AdditionalParameters - Structure - advanced setting:
// * PlanType - String -
// * AssignmentsAreUsed - Boolean -
// * PartnersAreUsed - Boolean -
// * TypesOfPricesAreUsed - Boolean -
// * WarehousesAreUsed - Boolean -
// * AgreementsAreUsed - Boolean -
// * Vendor - CatalogRef.Partners, Undefined -
// * SpecificationsAreUsed - Boolean -
// * ReleaseDatesAreUsed - Boolean -
// * ReleaseDatesOfSemiFinishedProductAreUsed - Boolean -
// * CalculationOfSalesRateIsUsed - Boolean -
// * AvailableProductTypes - Array of EnumRef.ItemsTypes -
// 
// Returns:
//  Query
Function CreateConfigureRequest(QueryTexts, DataToImport, AdditionalParameters)
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	CrossTable = AdditionalParameters.CrossTable;
	
	FieldsQuantity = "";
	FieldsPrice = "";
	FieldsAmount = "";
	If CrossTable Then
		
		For Each Period In AdditionalParameters.TimeIntervals Do
			FieldsQuantity = FieldsQuantity + "
			|DataToImport.NumberOfPackages_" + Period.ColumnName + " AS NumberOfPackages_" +  Period.ColumnName + ",";
			
			FieldsPrice = FieldsPrice + "
			|DataToImport.Price_" + Period.ColumnName + " AS Price_" +  Period.ColumnName + ",";
			
			FieldsAmount = FieldsAmount + "
			|DataToImport.Sum_" + Period.ColumnName + " AS Sum_" +  Period.ColumnName + ",";
		EndDo;
		
	Else
		FieldsQuantity = "DataToImport.NumberOfPackages AS NumberOfPackages,";
		FieldsPrice = "DataToImport.Price AS Price,";
		FieldsAmount = "DataToImport.Sum AS Sum,";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&DownloadableDataNumberOfPackages,", FieldsQuantity);
	
	QueryText = StrReplace(QueryText, "&UploadedDataPriceAmount,", 
		?(AdditionalParameters.PlanByAmount, FieldsPrice + FieldsAmount, ""));
			
	// Assignments are used
	QueryText = StrReplace(QueryText, "&DownloadableDataDestination,",
		?(AdditionalParameters.AssignmentsAreUsed, "DataToImport.Purpose AS Purpose,", ""));
	
	QueryText = StrReplace(QueryText, "&Purpose,", ?(AdditionalParameters.AssignmentsAreUsed, "
		|	CASE
		|		WHEN ISNULL(DestinationData.NumberOfAppointments, 0) = 1
		|			THEN DestinationData.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,", ""));
	
	QueryText = StrReplace(QueryText, "&NumberOfAppointments,", 
		?(AdditionalParameters.AssignmentsAreUsed, "ISNULL(DestinationData.NumberOfAppointments, 0) AS NumberOfAppointments,", ""));
	
	QueryText = QueryText + ?(AdditionalParameters.AssignmentsAreUsed, "
		|	LEFT JOIN TTDestinationData AS DestinationData
		|	ON DestinationData.Id = DataToImport.Id", "");
	
	// Specifications are used
	QueryText = StrReplace(QueryText, "&DownloadableDataSpecification,",
		?(AdditionalParameters.SpecificationsAreUsed, "DataToImport.BillOfMaterials AS BillOfMaterials,", ""));
	
	QueryText = StrReplace(QueryText, "&BillOfMaterials,", ?(AdditionalParameters.SpecificationsAreUsed, "
		|	CASE
		|		WHEN ISNULL(SpecificationsData.NumberOfSpecifications, 0) = 1
		|			THEN SpecificationsData.BillOfMaterials
		|		ELSE VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|	END AS BillOfMaterials,", ""));
	
	QueryText = StrReplace(QueryText, "&NumberOfSpecifications,", 
		?(AdditionalParameters.SpecificationsAreUsed, "ISNULL(SpecificationsData.NumberOfSpecifications, 0) AS NumberOfSpecifications,", ""));
	
	QueryText = QueryText + ?(AdditionalParameters.SpecificationsAreUsed, "
		|	LEFT JOIN TTSpecificationsData AS SpecificationsData
		|	ON SpecificationsData.Id = DataToImport.Id", "");
	// Partners Are Used
	QueryText = StrReplace(QueryText, "&UploadedPartnerData,",
		?(AdditionalParameters.PartnersAreUsed, "DataToImport.Partner AS Partner,", ""));
	
	QueryText = StrReplace(QueryText, "&Partner,", ?(AdditionalParameters.PartnersAreUsed, "
		|	CASE
		|		WHEN ISNULL(PartnerData_.NumberOfPartners, 0) = 1
		|			THEN PartnerData_.Partner
		|		ELSE VALUE(Catalog.Partners.EmptyRef)
		|	END AS Partner,", ""));
	
	QueryText = StrReplace(QueryText, "&NumberOfPartners,", 
		?(AdditionalParameters.PartnersAreUsed, "ISNULL(PartnerData_.NumberOfPartners, 0) AS NumberOfPartners,", ""));
	
	QueryText = QueryText + ?(AdditionalParameters.PartnersAreUsed, "
		|	LEFT JOIN TTPartnerData AS PartnerData_
		|	ON PartnerData_.Id = DataToImport.Id", "");
	
	// Warehouses are used
	QueryText = StrReplace(QueryText, "&UploadedDataWarehouse,",
		?(AdditionalParameters.WarehousesAreUsed, "DataToImport.Warehouse AS Warehouse,", ""));
	
	QueryText = StrReplace(QueryText, "&Warehouse,", ?(AdditionalParameters.WarehousesAreUsed, "
		|	CASE
		|		WHEN ISNULL(WarehouseData_2.NumberOfWarehouses, 0) = 1
		|			THEN WarehouseData_2.Warehouse
		|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|	END AS Warehouse,", ""));
	
	QueryText = StrReplace(QueryText, "&NumberOfWarehouses,", 
		?(AdditionalParameters.WarehousesAreUsed, "ISNULL(WarehouseData_2.NumberOfWarehouses, 0) AS NumberOfWarehouses,", ""));
	
	QueryText = QueryText + ?(AdditionalParameters.WarehousesAreUsed, "
		|	LEFT JOIN TTWarehouseData AS WarehouseData_2
		|	ON WarehouseData_2.Id = DataToImport.Id", "");
	
	// Conventions Are Used
	QueryText = StrReplace(QueryText, "&DownloadableDataAgreement,",
		?(AdditionalParameters.AgreementsAreUsed, "DataToImport.Terms AS Terms,", ""));
	
	QueryText = StrReplace(QueryText, "&Terms,", ?(AdditionalParameters.AgreementsAreUsed, "
		|	CASE
		|		WHEN ISNULL(AgreementData.NumberOfAgreements, 0) = 1
		|			THEN AgreementData.Terms
		|		ELSE VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
		|	END AS Terms,", ""));
	
	QueryText = StrReplace(QueryText, "&NumberOfAgreements,", 
		?(AdditionalParameters.AgreementsAreUsed, "ISNULL(AgreementData.NumberOfAgreements, 0) AS NumberOfAgreements,", ""));
	
	QueryText = QueryText + ?(AdditionalParameters.AgreementsAreUsed, "
		|	LEFT JOIN TTDataAgreements AS AgreementData
		|	ON AgreementData.Id = DataToImport.Id", "");
	
	// Types Of Prices Are Used
	QueryText = StrReplace(QueryText, "&DownloadableDataPriceType,",
		?(AdditionalParameters.TypesOfPricesAreUsed, "DataToImport.PriceKind AS PriceKind,", ""));
	
	TypesOfPricesAndVTCHPartners = AdditionalParameters.TypesOfPricesAreUsed And AdditionalParameters.PartnersAreUsed;
	QueryText = StrReplace(QueryText, "INNER JOIN &Vendor AS Vendors",
		?(TypesOfPricesAndVTCHPartners, "INNER JOIN TTPartnerData AS Vendors", ""));
	
	QueryText = StrReplace(QueryText, "On &ConnectionConditions",
		?(TypesOfPricesAndVTCHPartners, "On Vendors.Partner = TypesOfPrices.Owner", ""));
	
	QueryText = StrReplace(QueryText, "&PriceKind,", ?(AdditionalParameters.TypesOfPricesAreUsed, "
		|	CASE
		|		WHEN ISNULL(TheseTypesOfPrices.NumberOfPriceTypes, 0) = 1
		|			THEN TheseTypesOfPrices.PriceKind
		|		ELSE VALUE(Catalog.VendorPriceTypes.EmptyRef)
		|	END AS VendorPriceKind,", ""));
	
	QueryText = StrReplace(QueryText, "&NumberOfPriceTypes,", 
		?(AdditionalParameters.TypesOfPricesAreUsed, "ISNULL(TheseTypesOfPrices.NumberOfPriceTypes, 0) AS NumberOfPriceTypes,", ""));
	
	QueryText = QueryText + ?(AdditionalParameters.TypesOfPricesAreUsed, "
		|	LEFT JOIN TTTheseTypesOfPrices AS TheseTypesOfPrices
		|	ON TheseTypesOfPrices.Id = DataToImport.Id", "");
	
	// The assembly (disassembly) plan is used
	ThisIsAssemblyDisassembly = AdditionalParameters.PlanType = "AssemblyDisassemblyPlan";
	QueryText = StrReplace(QueryText, "&DownloadableDataConfigurationOption,",
		?(ThisIsAssemblyDisassembly, "DataToImport.ProductKit AS ProductKit,", ""));
	
	QueryText = StrReplace(QueryText, "&ProductKit,", ?(ThisIsAssemblyDisassembly, "
		|	CASE
		|		WHEN ISNULL(DataOfConfigurationOptions.NumberOfConfigurationOptions, 0) = 1
		|			THEN DataOfConfigurationOptions.ProductKit
		|		ELSE VALUE(Catalog.ProductKitConfigurations.EmptyRef)
		|	END AS ProductKit,", ""));
	
	QueryText = StrReplace(QueryText, "&NumberOfConfigurationOptions,", 
		?(ThisIsAssemblyDisassembly, "ISNULL(DataOfConfigurationOptions.NumberOfConfigurationOptions, 0) AS NumberOfConfigurationOptions,", ""));
	
	QueryText = QueryText + ?(ThisIsAssemblyDisassembly, "
		|	LEFT JOIN TTDataOfConfigurationOptions AS DataOfConfigurationOptions
		|	ON DataOfConfigurationOptions.Id = DataToImport.Id", "");
	
	QueryText = StrReplace(QueryText, "&UploadedDataOrderCompletionDate,", 
		?(Not CrossTable And AdditionalParameters.PlanType = "PurchasePlan", "DataToImport.OrderFulfillmentPeriod AS OrderFulfillmentPeriod,", ""));
	
	If CrossTable Then
		QueryText = StrReplace(QueryText, "&DownloadableDateData,", "");
	ElsIf AdditionalParameters.PlanType = "PurchasePlan" Then
		QueryText = StrReplace(QueryText, "&DownloadableDateData,", 
		"DataToImport.DateOfReceipt AS DateOfReceipt,
		|DataToImport.OrderDate AS OrderDate,");
	ElsIf AdditionalParameters.PlanType = "ProductionPlan" Then
		
		ReplacementText_1 = ?(AdditionalParameters.ReleaseDatesAreUsed,"DataToImport.DateOfProduction AS DateOfProduction," + Chars.LF,"")
			+ ?(AdditionalParameters.ReleaseDatesOfSemiFinishedProductAreUsed,"DataToImport.ReleaseDateOfProductsOrSemiFinishedProduct AS ReleaseDateOfProductsOrSemiFinishedProduct," + Chars.LF,"")
			+ "DataToImport.StartDate2 AS StartDate2,";
		
		QueryText = StrReplace(QueryText, "&DownloadableDateData,", ReplacementText_1);
	ElsIf AdditionalParameters.PlanType = "InventoryConsumptionPlan"
		Or AdditionalParameters.PlanType = "SalesPlan" Then
		QueryText = StrReplace(QueryText, "&DownloadableDateData,", 
		"DataToImport.DateOfShipment AS DateOfShipment,");
	ElsIf AdditionalParameters.PlanType = "AssemblyDisassemblyPlan" Then
		QueryText = StrReplace(QueryText, "&DownloadableDateData,", 
		"DataToImport.DateOfAssemblyDisassembly AS DateOfAssemblyDisassembly,");
	Else
		QueryText = StrReplace(QueryText, "&DownloadableDateData,", "");
	EndIf;
	
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DataToImport",         DataToImport);
	Query.SetParameter("AvailableProductTypes", AdditionalParameters.AvailableProductTypes);
	
	If AdditionalParameters.TypesOfPricesAreUsed Then
		Query.SetParameter("Partner", AdditionalParameters.Partner);
	EndIf;
	
	Return Query;
	
EndFunction

// Returns:
//  String
Function TextOfRequestTTUploadedDataProducts()
	
	QueryText =
	"SELECT
	|	DataToImport.Id       AS Id,
	|	DataToImport.Barcode            AS Barcode,
	|	DataToImport.SKU             AS SKU,
	|	DataToImport.ProductsAndServicesCode     AS ProductsAndServicesCode,
	|	DataToImport.Products        AS Products,
	|	DataToImport.Characteristic      AS Characteristic,
	|	&DownloadableDataDestination,
	|	DataToImport.PackageCode         AS PackageCode,
	|	DataToImport.Package            AS Package,
	|	&DownloadableDataNumberOfPackages,
	|	&UploadedPartnerData,
	|	&UploadedDataWarehouse,
	|	&DownloadableDataAgreement,
	|	&DownloadableDataPriceType,
	|	&DownloadableDataSpecification,
	|	&UploadedDataPriceAmount,
	|	&DownloadableDataConfigurationOption,
	|	&DownloadableDateData,
	|	&UploadedDataOrderCompletionDate,
	|	DataToImport.Comment         AS Comment
	|INTO TTDownloadableData
	|FROM
	|	&DataToImport AS DataToImport
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - Request Text TT Barcode Data
Function QueryTextTTBarcodeData()
	
	QueryText =
	"SELECT DISTINCT
	|	DataToImport.Id AS Id,
	|	Barcodes.Products          AS Products,
	|	Barcodes.Characteristic        AS Characteristic,
	|	Barcodes.Package              AS Package
	|INTO TTBarcodeData
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|	INNER JOIN InformationRegister.ItemsBarcodes AS Barcodes
	|	ON Barcodes.Barcode = DataToImport.Barcode
	|
	|WHERE
	|	NOT DataToImport.Barcode = """"
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - Request Text TT Product Data
Function QueryTextTTProductData()
	
	QueryText =
	"SELECT
	|	CatProducts.Id                      AS Id,
	|	MAX(CatProducts.Products)             AS Products,
	|	COUNT(DISTINCT CatProducts.Products) AS QuantityOfProducts
	|INTO TTProductData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		CatProducts.Ref          AS Products
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.SKU = DataToImport.SKU
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.SKU = """"
	|		AND CatProducts.ItemsType IN (&AvailableProductTypes)
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		CatProducts.Ref          AS Products
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Code = DataToImport.ProductsAndServicesCode
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.ProductsAndServicesCode = """"
	|		AND CatProducts.ItemsType IN (&AvailableProductTypes)
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		CatProducts.Ref          AS Products
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Description = DataToImport.Products
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.Products = """"
	|		AND CatProducts.ItemsType IN (&AvailableProductTypes)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		BarcodeData_5.Id AS Id,
	|		BarcodeData_5.Products  AS Products
	|	FROM
	|		TTBarcodeData AS BarcodeData_5
	|	) AS CatProducts
	|
	|GROUP BY
	|	CatProducts.Id
	|
	|INDEX BY
	|	Id,
	|	Products
	|";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - Request Text TT Characteristics Data
Function QueryTextTTCharacteristicsData()
	
	QueryText =
	"SELECT
	|	Characteristics.Id                        AS Id,
	|	MAX(Characteristics.Characteristic)             AS Characteristic,
	|	COUNT(DISTINCT Characteristics.Characteristic) AS NumberOfCharacteristics
	|INTO TTCharacteristicsData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Characteristics.Ref           AS Characteristic
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = ProductData_1.Products
	|		
	|		INNER JOIN Catalog.ItemsCharacteristics AS Characteristics
	|		ON Characteristics.Owner = CASE
	|			WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|				THEN CatProducts.ProductKind
	|			WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|				THEN CatProducts.Ref
	|			WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|				THEN CatProducts.ItemVariantsOwner
	|			ELSE UNDEFINED
	|		END
	|		AND Characteristics.Description = DataToImport.Characteristic
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.Characteristic = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Characteristics.Ref           AS Characteristic
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = ProductData_1.Products
	|
	|		INNER JOIN Catalog.ItemsCharacteristics AS Characteristics
	|		ON Characteristics.Owner = CASE
	|			WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|				THEN CatProducts.ProductKind
	|			WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|				THEN CatProducts.Ref
	|			WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|				THEN CatProducts.ItemVariantsOwner
	|			ELSE UNDEFINED
	|		END
	|		AND Characteristics.Description = DataToImport.Characteristic
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.Characteristic = """"
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		BarcodeData_5.Id AS Id,
	|		BarcodeData_5.Characteristic AS Characteristic
	|	FROM
	|		TTBarcodeData AS BarcodeData_5
	|	) AS Characteristics
	|
	|GROUP BY
	|	Characteristics.Id
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - Request Text TT Destination Data
Function QueryTextTTDestinationData() Export
	QueryText = "
	|SELECT
	|	Assignments.Id                    AS Id,
	|	MAX(Assignments.Purpose)             AS Purpose,
	|	COUNT(DISTINCT Assignments.Purpose) AS NumberOfAppointments
	|INTO TTDestinationData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Assignments.Ref               AS Purpose
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.Assignments AS Assignments
	|		ON Assignments.Description = DataToImport.Purpose
	|
	|	WHERE
	|		NOT DataToImport.Purpose = """"
	|	) AS Assignments
	|
	|GROUP BY
	|	Assignments.Id
	|
	|INDEX BY
	|	Id";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - Request Text TT Package Data
Function QueryTextTTPackingData()
	
	QueryText =
	"SELECT
	|	Packages.Id                  AS Id,
	|	MAX(Packages.Package)             AS Package,
	|	COUNT(DISTINCT Packages.Package) AS PackingQuantity
	|INTO TTPackingData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Packages.Ref                 AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products
	|		AND Packages.Description = DataToImport.Package
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.Package = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Packages.Ref                 AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products.PackagingGroup
	|		AND Packages.Description = DataToImport.Package
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.Package = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Packages.Ref                 AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products
	|		AND Packages.Code = DataToImport.PackageCode
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.PackageCode = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Packages.Ref                 AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products.PackagingGroup
	|		AND Packages.Code = DataToImport.PackageCode
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.PackageCode = """"
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		BarcodeData_5.Id AS Id,
	|		BarcodeData_5.Package      AS Package
	|	FROM
	|		TTBarcodeData AS BarcodeData_5
	|	) AS Packages
	|
	|GROUP BY
	|	Packages.Id
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - Request Text TT Specification Data
Function QueryTextTTSpecificationsData()
	QueryText = "
	|SELECT
	|	Specifications.Id                      AS Id,
	|	MAX(Specifications.BillOfMaterials)             AS BillOfMaterials,
	|	COUNT(DISTINCT Specifications.BillOfMaterials) AS NumberOfSpecifications
	|INTO TTSpecificationsData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Specifications.Ref             AS BillOfMaterials
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.BillsOfMaterials AS Specifications
	|		ON Specifications.Description = DataToImport.BillOfMaterials
	|
	|	WHERE
	|		NOT DataToImport.BillOfMaterials = """"
	|	) AS Specifications
	|
	|GROUP BY
	|	Specifications.Id
	|
	|INDEX BY
	|	Id";
	
	Return QueryText;
	
EndFunction
// Returns:
//  String - Request Text TT Warehouse Data
Function QueryTextTTWarehouseData() Export
	QueryText = "
	|SELECT
	|	Warehouses.Id               AS Id,
	|	MAX(Warehouses.Warehouse)             AS Warehouse,
	|	COUNT(DISTINCT Warehouses.Warehouse) AS NumberOfWarehouses
	|INTO TTWarehouseData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Warehouses.Ref                   AS Warehouse
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.Warehouses AS Warehouses
	|		ON Warehouses.Description = DataToImport.Warehouse
	|
	|	WHERE
	|		NOT DataToImport.Warehouse = """"
	|	) AS Warehouses
	|
	|GROUP BY
	|	Warehouses.Id
	|
	|INDEX BY
	|	Id";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String
Function QueryTextTTPartnerData()
	QueryText = "
	|SELECT
	|	Partners.Id                 AS Id,
	|	MAX(Partners.Partner)             AS Partner,
	|	COUNT(DISTINCT Partners.Partner) AS NumberOfPartners
	|INTO TTPartnerData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Partners.Ref                 AS Partner
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.Partners AS Partners
	|		ON Partners.Description = DataToImport.Partner
	|
	|	WHERE
	|		NOT DataToImport.Partner = """"
	|	) AS Partners
	|
	|GROUP BY
	|	Partners.Id
	|
	|INDEX BY
	|	Id";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - The Text Of The Request TT The Data Of The Agreements
Function QueryTextTTDataAgreements(PlanType)
	QueryText = "
	|SELECT
	|	Terms1.Id                    AS Id,
	|	MAX(Terms1.Terms)             AS Terms,
	|	COUNT(DISTINCT Terms1.Terms) AS NumberOfAgreements
	|INTO TTDataAgreements
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Terms1.Ref               AS Terms
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.TermsOfPurchaseFromVendors AS Terms1
	|		ON Terms1.Description = DataToImport.Terms
	|
	|	WHERE
	|		NOT DataToImport.Terms = """"
	|	) AS Terms1
	|
	|GROUP BY
	|	Terms1.Id
	|
	|INDEX BY
	|	Id";
	
	If PlanType = "SalesPlan" Then
		QueryText = StrReplace(QueryText, "TermsOfPurchaseFromVendors", "TermsOfSale")
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - The Text Of The Request TT These Types Of Prices
Function QueryTextTTTheseTypesOfPrices()
	QueryText = "
	|SELECT
	|	TypesOfPrices.Id                 AS Id,
	|	MAX(TypesOfPrices.PriceKind)             AS PriceKind,
	|	COUNT(DISTINCT TypesOfPrices.PriceKind) AS NumberOfPriceTypes
	|INTO TTTheseTypesOfPrices
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		TypesOfPrices.Ref               AS PriceKind
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.VendorPriceTypes AS TypesOfPrices
	|		ON TypesOfPrices.Description = DataToImport.PriceKind
	|		
	|		INNER JOIN &Vendor AS Vendors
	|		ON &ConnectionConditions
	|		
	|	WHERE
	|		NOT DataToImport.PriceKind = """"
	|		AND (&Partner = UNDEFINED OR TypesOfPrices.Owner = &Partner)
	|	) AS TypesOfPrices
	|
	|GROUP BY
	|	TypesOfPrices.Id
	|
	|INDEX BY
	|	Id";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - The Text Of The Request TT The Data Of The Configuration Options
Function QueryTextTTDataOfConfigurationOptions()
	QueryText = "
	|SELECT
	|	KitConfigurations.Id                             AS Id,
	|	MAX(KitConfigurations.ProductKit)             AS ProductKit,
	|	COUNT(DISTINCT KitConfigurations.ProductKit) AS NumberOfConfigurationOptions
	|INTO TTDataOfConfigurationOptions
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		KitConfigurations.Ref     AS ProductKit
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.ProductKitConfigurations AS KitConfigurations
	|		ON KitConfigurations.Description = DataToImport.ProductKit
	|
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON DataToImport.Id = ProductData_1.Id
	|		AND KitConfigurations.Owner = ProductData_1.Products
	|
	|	WHERE
	|		NOT DataToImport.ProductKit = """"
	|	) AS KitConfigurations
	|
	|GROUP BY
	|	KitConfigurations.Id
	|
	|INDEX BY
	|	Id";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - Request Text Uploaded Product Data
Function RequestTextUploadedProductData()
	
	QueryText =
	"SELECT
	|	DataToImport.Id                          AS Id,
	|	CASE
	|		WHEN ISNULL(ProductData_1.QuantityOfProducts, 0) = 1
	|			THEN ProductData_1.Products
	|		ELSE VALUE(Catalog.Products.EmptyRef)
	|	END                                                    AS Products,
	|	CASE
	|		WHEN ISNULL(CharacteristicsData.NumberOfCharacteristics, 0) = 1
	|			THEN CharacteristicsData.Characteristic
	|		ELSE VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|	END                                                    AS Characteristic,
	|	&Purpose,
	|	CASE
	|		WHEN ISNULL(PackageData_.PackingQuantity, 0) = 1
	|			THEN PackageData_.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END                                                    AS Package,
	|	&BillOfMaterials,
	|	&Warehouse,
	|	&Partner,
	|	&Terms,
	|	&PriceKind,
	|	&ProductKit,
	|	ISNULL(ProductData_1.QuantityOfProducts, 0)   AS QuantityOfProducts,
	|	ISNULL(CharacteristicsData.NumberOfCharacteristics, 0) AS NumberOfCharacteristics,
	|	&NumberOfAppointments,
	|	&NumberOfSpecifications,
	|	&NumberOfWarehouses,
	|	&NumberOfPartners,
	|	&NumberOfAgreements,
	|	&NumberOfPriceTypes,
	|	&NumberOfConfigurationOptions,
	|	ISNULL(PackageData_.PackingQuantity, 0)           AS PackingQuantity,
	|	&DownloadableDataNumberOfPackages,
	|	&UploadedDataPriceAmount,
	|	&DownloadableDateData,
	|	&UploadedDataOrderCompletionDate,
	|	DataToImport.Comment                            AS Comment
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|	LEFT JOIN TTProductData AS ProductData_1
	|	ON ProductData_1.Id = DataToImport.Id
	|	
	|	LEFT JOIN TTCharacteristicsData AS CharacteristicsData
	|	ON CharacteristicsData.Id = DataToImport.Id
	|	
	|	LEFT JOIN TTPackingData AS PackageData_
	|	ON PackageData_.Id = DataToImport.Id
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#Region Other

Function GetPeriodicityByText(Periodicity)
	
	PeriodicityText = "";
	
	If Periodicity = Enums.Periodicity.Year Then
		PeriodicityText = "YEAR";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.TenDays Then
		PeriodicityText = "TENDAYS";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.Day Then
		PeriodicityText = "DAY";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		PeriodicityText = "QUARTER";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.Month Then
		PeriodicityText = "MONTH";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.Week Then
		PeriodicityText = "WEEK";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		PeriodicityText = "HALFYEAR";//@Query-part
	EndIf;
	
	Return PeriodicityText;
	
EndFunction

Function GetFrequencyOfRegisterByText(Periodicity)
	
	PeriodicityText = "";
	
	If Periodicity = Enums.Periodicity.Year Then
		PeriodicityText = "YearPeriod";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.TenDays Then
		PeriodicityText = "TenDaysPeriod";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.Day Then
		PeriodicityText = "DayPeriod";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		PeriodicityText = "QuarterPeriod";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.Month Then
		PeriodicityText = "MonthPeriod";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.Week Then
		PeriodicityText = "WeekPeriod";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		PeriodicityText = "HalfYearPeriod";//@Query-part
	EndIf;
	
	Return PeriodicityText;
	
EndFunction

#Region ConstantsOfFormationAccordingToPlans

// Updates the values of constants for the use of processing processes for generating documents according to plans. 
//
// Parameters:
//   NameOfChangedConstant - String - The name of the changed constant that initiated synchronization.
Procedure SynchronizeFormationConstantsAccordingToPlans(NameOfChangedConstant)
	
	DescriptionOfConstants = DescriptionOfConstantsOfFormationOfDocumentsAccordingToPlans();
	
	DependentConstants = New Array;
	
	For Each ConstantDetails In DescriptionOfConstants Do
		
		If NameOfChangedConstant = ConstantDetails.UsingPlans Then
			DependentConstants.Add(ConstantDetails.UseOfProcessing);
			Continue;
		EndIf;
		
		If NameOfChangedConstant = ConstantDetails.UseOfDocuments Then
			DependentConstants.Add(ConstantDetails.UseOfProcessing);
			Continue;
		EndIf;
	
	EndDo;
	
	If Not ValueIsFilled(DependentConstants) Then
		Return;
	EndIf;
	
	For Each DependentConstant In DependentConstants Do
		
		Filter = New Structure("UseOfProcessing", DependentConstant);
		ConstantDescriptions = DescriptionOfConstants.FindRows(Filter);
		
		UseProcessing = False;
		For Each ConstantDetails In ConstantDescriptions Do
			
			UseProcessing = Constants[ConstantDetails.UseOfDocuments].Get()
				And Constants[ConstantDetails.UsingPlans].Get();
			
			If UseProcessing Then
				Break;
			EndIf;
			
		EndDo;
		
		If UseProcessing <> Constants[DependentConstant].Get() Then
			Constants[DependentConstant].Set(UseProcessing);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

// Functional options that include processing the formation of documents according to plans depend on two constants:
// 1. The use of plans for which documents will be entered.
// 2. The use of documents that will be entered according to plans.
//
// Returns:
//  ValueTable - Description of relationships:
//    * UseOfProcessing - String - The name of the constant on which the use of processing depends.
//    * UsingPlans - String - The name of the constant that includes the use of plans for which documents are generated in processing.
//    * UseOfDocuments - String - The name of the constant that includes the use of documents that are generated according to plans.
Function DescriptionOfConstantsOfFormationOfDocumentsAccordingToPlans()

	StringTypeDetails150 = Common.StringTypeDetails(150);

	ReturnValue = New ValueTable;
	ReturnValue.Columns.Add("UseOfProcessing",  StringTypeDetails150);
	ReturnValue.Columns.Add("UsingPlans",     StringTypeDetails150);
	ReturnValue.Columns.Add("UseOfDocuments", StringTypeDetails150);
	
	ConstantMetadata = Metadata.Constants;
	
	NewDescriptionOfConstantsOfFormationOfDocumentsAccordingToPlans(
		ReturnValue,
		ConstantMetadata.UsePurchaseRequests,
		ConstantMetadata.UsePurchasePlanning,
		ConstantMetadata.UseGeneratePurchaseRequestsByPlan);
	
	NewDescriptionOfConstantsOfFormationOfDocumentsAccordingToPlans(
		ReturnValue,
		ConstantMetadata.UsePurchaseOrders,
		ConstantMetadata.UsePurchasePlanning,
		ConstantMetadata.UseConvertPlanToPurchaseOrders);
	
	NewDescriptionOfConstantsOfFormationOfDocumentsAccordingToPlans(
		ReturnValue,
		ConstantMetadata.UseAssemblyDisassemblyOrders,
		ConstantMetadata.UseAssemblyDisassemblyPlanning,
		ConstantMetadata.UseConvertPlanToKittingOrders);
	
	Return ReturnValue;

EndFunction

Function NewDescriptionOfConstantsOfFormationOfDocumentsAccordingToPlans(DescriptionOfConstants,
	UseOfDocuments, UsingPlans, UseOfProcessing)
	
	ConstantDetails                         = DescriptionOfConstants.Add();
	ConstantDetails.UseOfDocuments = UseOfDocuments.Name;
	ConstantDetails.UsingPlans     = UsingPlans.Name;
	ConstantDetails.UseOfProcessing  = UseOfProcessing.Name;
	
	Return ConstantDetails;
	
EndFunction

#EndRegion

#EndRegion

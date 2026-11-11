
#Region Public

#Region ConvertingAnalyticsTypes

// Returns a table of types of Analytics with a column of types
// 
// Returns:
//	ValueTable - all available types of analytics. Contains columns:
//		*Ref - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
//		*ValueType - TypeDescription - type of the Analytics view.
// 
Function TypesOfViewsTypesOfAnalytics() Export
	
	Query = New Query("SELECT
	|	BudgetFlowItemDimensions.Ref,
	|	BudgetFlowItemDimensions.ValueType
	|FROM
	|	ChartOfCharacteristicTypes.BudgetFlowItemDimensions AS BudgetFlowItemDimensions");
	
	Return Query.Execute().Unload();
	
EndFunction

// Returns a table of types of Analytics with a column of types
// 
// Returns:
//	Array of ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - all available types of analytics.
// 
Function DimensionKinds() Export
	
	Return TypesOfViewsTypesOfAnalytics().UnloadColumn("Ref");
	
EndFunction

// Returns a table of types of Analytics with a column of types
// 
// Parameters:
// 	DimensionKind - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions, String - Link to PVC Analyticsintelligent or the name (identifier) of the form analysts.
//
// Returns:
//	Array of Type - An array of Type values consisting of the types used.
// 
Function TypesOfAnalyticsType(DimensionKind) Export
	TypesOfAnalyticsType = New Array;
	
	DesiredTypeOfAnalytics = Undefined;
	ParameterType = TypeOf(DimensionKind);
	// Let's clarify the empty view and type of analytics
	If ParameterType = Type("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions")
		And DimensionKind.IsEmpty() Then
		DimensionKind = Undefined;
		ParameterType = Type("Undefined");
	EndIf;
	
	If ParameterType = Type("String") Then
		Id_TypeOfAnalytics = TargetValueMonitoring.StringInUniqueIdentifier(DimensionKind);
		
		DesiredTypeOfAnalytics = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.GetRef(Id_TypeOfAnalytics);
		
		If Not ValueIsFilled(DesiredTypeOfAnalytics) Then
			DesiredTypeOfAnalytics = Undefined;
		EndIf;
	Else
		DesiredTypeOfAnalytics = DimensionKind;
	EndIf;
	
	// Undefined - the type of analytics is not used 
	If Not ParameterType = Type("Undefined") Then
		SetPrivilegedMode(True);
		ValueType = DesiredTypeOfAnalytics.ValueType;
		SetPrivilegedMode(False);
		TypesOfAnalyticsType = ValueType.Types();
	EndIf;
		
	Return TypesOfAnalyticsType;
EndFunction

// Returns an array of empty references plan of the types of characteristics of Analyticsintelligent and Undefined.
//
// Returns:
// 	Array of AnyRef - an array of empty references and undefined.
//
Function EmptyAnalyticsValues() Export
	Array = New Array;
	
	Types = BudgetingServer.AllTypesOfAnalytics().Types();
	
	For Each Type In Types Do
		EmptyRef = New (Type);
		Array.Add(EmptyRef);
	EndDo;
	
	Array.Add(Undefined);
	
	Return Array;
EndFunction

#EndRegion

#Region MassivelyUsedConstants

// Returns the value of the option of the same name and is used in massive, repeated algorithms. 
//
// Returns:
//   Boolean - the value of the functional option.
// 
Function UseMultipleCurrencies() Export
	Return GetFunctionalOption("UseMultipleCurrencies");
EndFunction

#EndRegion 

// Returns the number of the type of analytics article or indicator budgets
//
// Parameters:
//  ItemIndicator - CatalogRef.BudgetFlowItems,
//						CatalogRef.BudgetBalanceItems
//  DimensionKind - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - type of analytics of an article or indicator of budgets
//
// Returns:
//  Number
//
Function NumberOfTypeOfAnalyticsItemIndicatorBudgets(ItemIndicator, DimensionKind) Export
	
	DimensionKinds = BudgetingServer.DimensionKinds(ItemIndicator);
	
	DimensionNumber = 0;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For Counter = 1 To MaximumNumberOfAnalysts Do
		If DimensionKinds[StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1", Counter)]
			= DimensionKind Then
			DimensionNumber = Counter;
			Break;
		EndIf;
	EndDo;
	
	Return Format(DimensionNumber, "NG=0");
	
EndFunction

// Returns the correspondence of the analysts of an item or budget indicator with the analysts of a non-financial indicator
//
// Parameters:
//  ItemIndicator - CatalogRef.BudgetFlowItems
//						CatalogRef.BudgetBalanceItems
//  NFP - CatalogRef.NonFinancialItemsOfBudgets
//
// Returns:
//  Map of KeyAndValue:
//   *Key - Number - the number of analytics of the budget item (indicator)
//   *Value - String - number of non-financial indicator analytics
//  It is uncertain if the analysts of an item or indicator of budgets do not match the analysts of the NFP.
//
Function ComplianceOfAnalystWithItemIndicatorOfSNFPBudgets(ItemIndicator, NFP) Export
	
	TypesOfAnalyticsArticlesOfIndicator = BudgetingServer.DimensionKinds(ItemIndicator);
	TypesOfNFPAnalysts = BudgetingServer.DimensionKinds(NFP);
	
	ComplianceAnalyst = New Map;
	
	For Each TypeOfNFPAnalytics In TypesOfNFPAnalysts Do
		If Not ValueIsFilled(TypeOfNFPAnalytics.Value) Then
			Continue;
		EndIf;
		NFPAnalyticsNumber = NumberOfTypeOfAnalyticsItemIndicatorBudgets(NFP, TypeOfNFPAnalytics.Value);
		MapFound = False;
		For Each TypeOfAnalyticsOfIndicatorArticle In TypesOfAnalyticsArticlesOfIndicator Do
			If TypeOfNFPAnalytics.Value = TypeOfAnalyticsOfIndicatorArticle.Value Then
				NumberOfAnalyticsOfIndicatorArticle = NumberOfTypeOfAnalyticsItemIndicatorBudgets(ItemIndicator,
					TypeOfAnalyticsOfIndicatorArticle.Value);
				ComplianceAnalyst.Insert(NFPAnalyticsNumber, NumberOfAnalyticsOfIndicatorArticle);
				MapFound = True;
				Break;
			EndIf;
		EndDo;
		If Not MapFound Then
			ComplianceAnalyst = Undefined;
			Break;
		EndIf;
	EndDo;
	
	Return ComplianceAnalyst;
	
EndFunction

// Returns the structure of currency fields by type of analysis.
// 
// Parameters:
// 	DimensionKind - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Type of Analytics.
// Returns:
// 	Structure - LongDesc:
// * RecordByCurrency - Boolean - Flag for accounting for currency analysis.
// * CurrencyFilling - Boolean - Path to the currency field.
Function ParametersForFillingInCurrencyOfAnalyticsView(DimensionKind) Export
	
	If ValueIsFilled(DimensionKind) Then
		CurrencyFillingParameters = Common.ObjectAttributesValues(DimensionKind, "RecordByCurrency, CurrencyFilling");
	Else
		CurrencyFillingParameters = New Structure("RecordByCurrency, CurrencyFilling", False, False);
	EndIf;
	
	Return CurrencyFillingParameters;
EndFunction

// Returns an array of names of balance registers for the specified document type
//
// Parameters:
//  DocumentKind - CatalogRef.MetadataObjectIDs - type of document
//  TypeOfAccountingData - Undefined, EnumRef.AccountingDataTypes - selection by type of accounting data
//  ControlOfBudgetingLimits - Boolean - True if a list of registers is generated to control budgeting limits
//
// Returns:
//  Map of KeyAndValue - array of balance registers:
//   *Key - String - name of the balance register
//   *Value - Structure - the parameters of reflection of the Registered Records of the balance register:
//    **ParameterName - String - parameter name
//    **ParameterValue - Arbitrary
//
Function ResidualFinancialRegistersByTypeOfDocument(DocumentKind, TypeOfAccountingData = Undefined,
	ControlOfBudgetingLimits = False) Export
	
	ResidualFinancialRegisters = New Map;
	
	DocumentRegisteredRecordCollection = Common.MetadataObjectByID(DocumentKind).RegisterRecords; // MetadataObjectPropertyValueCollection
	AccumulationRegistersMetadata = Metadata.AccumulationRegisters;
	
	AccountingSettings = ActualBudgetingDataByAssetAndLiabilityItems.FinancialAccountingSettingsForBudgeting();
	ArticleSelectionSettings = ChartsOfCharacteristicTypes.AssetLiabilityItems.SettingsForSelectingItemsOfAssetsLiabilities();
	ArticleSelectionSettings.TypeOfAccountingData = TypeOfAccountingData;
	FinancialRegisters = ChartsOfCharacteristicTypes.AssetLiabilityItems.DataSourcesOfAccountingObjects(
		AccountingSettings, ArticleSelectionSettings);
	
	For Each RegisterMetadata In DocumentRegisteredRecordCollection Do
		
		If Not AccumulationRegistersMetadata.Contains(RegisterMetadata) Then
			Continue;
		EndIf;
		
		If RegisterMetadata = AccumulationRegistersMetadata.CustomersARAPAccounting Then
			AccumulationRegisterName = AccumulationRegistersMetadata.CustomersARAPAccountingByDueDates.Name;
		ElsIf RegisterMetadata = AccumulationRegistersMetadata.VendorsARAPAccounting Then
			AccumulationRegisterName = AccumulationRegistersMetadata.VendorsARAPAccountingByDueDates.Name;
		Else
			AccumulationRegisterName = RegisterMetadata.Name;
		EndIf;
		
		If FinancialRegisters.Find(AccumulationRegisterName) <> Undefined Then
			MotionReflectionParameters = AccumulationRegisters[AccumulationRegisterName].ParametersForReflectingRegisteredRecordsInFinancialAccounting(
				AccumulationRegistersMetadata[AccumulationRegisterName]);
			If ControlOfBudgetingLimits And TypeOfAccountingData <> Undefined
				And MotionReflectionParameters.TypeOfAccountingData <> TypeOfAccountingData Then
				Continue;
			EndIf;
			ResidualFinancialRegisters.Insert(AccumulationRegisterName, MotionReflectionParameters);
		EndIf;
		
	EndDo;
	
	ToSupplementResidualFinancialRegistersByTypeOfDocument(DocumentKind, ResidualFinancialRegisters);
	
	Return ResidualFinancialRegisters;
	
EndFunction

// Returns the XO settings that need to be replaced with the main XO setting from the fact rule
//
// Returns:
//  Array of CatalogRef.BusinessTransactionsSettings
//
Function BusinessTransactionsSettingsForReplacement() Export
	
	BusinessTransactionsSettings = New Array;
	
	BusinessTransactionsSettings.Add(Catalogs.BusinessTransactionsSettings.IncomingVATOnAcquisition);
	BusinessTransactionsSettings.Add(Catalogs.BusinessTransactionsSettings.EmptyRef());
	
	Return BusinessTransactionsSettings;
	
EndFunction

// Returns an indication of whether there are rules for getting actual data on budget items with storing the result of calculating the rules.
//
// Returns:
//  Boolean - True if there is at least one rule
//
Function StoredFactIsUsedForBudgetItems() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	ActualDataQueryRulesByBudgetFlowItems.Ref AS Ref
	|FROM
	|	Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
	|WHERE
	|	ActualDataQueryRulesByBudgetFlowItems.CachingOfRuleResults
	|	AND NOT ActualDataQueryRulesByBudgetFlowItems.DeletionMark";
	
	SetPrivilegedMode(True);
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction

// Returns an array of names of metadata objects associated with the analytics view that contain a table part with the specified name.
//
// Parameters:
//  DimensionKind - ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions - Dimension kind
//  TabularSectionName - String - name of the table part
//
// Returns:
//  Array of String - array of names of metadata objects with the specified table part
//
Function NamesOfTypesOfAnalyticsTypeThatContainTablePart(DimensionKind, TabularSectionName) Export
	
	NamesOfTypesOfAnalyticsType = New Array;
	
	For Each TypeOfAnalyticsType In TypesOfAnalyticsType(DimensionKind) Do
		ObjectMetadata = Metadata.FindByType(TypeOfAnalyticsType);
		If ObjectMetadata <> Undefined
			And Not Metadata.Enums.Contains(ObjectMetadata)
			And ObjectMetadata.TabularSections.Find(TabularSectionName) <> Undefined Then
			NamesOfTypesOfAnalyticsType.Add(ObjectMetadata.FullName());
		EndIf;
	EndDo;
	
	Return NamesOfTypesOfAnalyticsType;
	
EndFunction

// Returns the structure of measurements and resources of the Accumulation register, which is the data source for the calculation rule
//
// Parameters:
//  SourceType - EnumRef.DataSourceTypesForBudgeting - type of data source
//
// Returns:
//  Structure:
//   *RegisterName - String - Register name
//   *Dimensions - Structure - register measurement data:
//    **DimensionName - Array of Structure:
//     ***Description - String - synonym for measurement
//     ***ValueType - TypeDescription - Type Of Measurement Value
//   *Resources - Structure - data on register resources:
//    **ResourceName - Array of Structure:
//     ***Description - String - resource synonym
//     ***ValueType - TypeDescription - type of resource value
//
Function ParametersOfRegisterOfSourceOfReceivingDataForBudgeting(SourceType) Export
	
	RegisterParameters = New Structure("RegisterName, Dimensions, Resources", "", New Structure, New Structure);
	ExcludedDimensions = New Array;
	
	MetadataOfAccumulationRegisters = Metadata.AccumulationRegisters;
	
	If SourceType = Enums.DataSourceTypesForBudgeting.BudgetTurnovers Then
		
		RegisterMetadata = MetadataOfAccumulationRegisters.BudgetTurnovers;
		
		ExcludedDimensions.Add("BudgetFlowItem");
		ExcludedDimensions.Add("PlanningPeriod");
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			ExcludedDimensions.Add(StringFunctionsClientServer.SubstituteParametersToString("Dimension%1", DimensionNumber));
		EndDo;
		
	ElsIf SourceType = Enums.DataSourceTypesForBudgeting.SalesPlans Then
		
		RegisterMetadata = MetadataOfAccumulationRegisters.SalesPlans;
		
	ElsIf SourceType = Enums.DataSourceTypesForBudgeting.SalesPlansByCategories Then
		
		RegisterMetadata = MetadataOfAccumulationRegisters.SalesPlansByCategories;
		
	ElsIf SourceType = Enums.DataSourceTypesForBudgeting.PurchasePlans Then
		
		RegisterMetadata = MetadataOfAccumulationRegisters.PurchasePlans;
		
	ElsIf SourceType = Enums.DataSourceTypesForBudgeting.CashFlowPlansCustomers Then
		
		RegisterMetadata = MetadataOfAccumulationRegisters.CashFlowPlansCustomers;
		
	ElsIf SourceType = Enums.DataSourceTypesForBudgeting.CashFlowPlansVendors Then
		
		RegisterMetadata = MetadataOfAccumulationRegisters.CashFlowPlansVendors;
		
	ElsIf SourceType = Enums.DataSourceTypesForBudgeting.ProductionPlans Then
		
		RegisterMetadata = MetadataOfAccumulationRegisters.ProductionPlans;
		
	ElsIf SourceType = Enums.DataSourceTypesForBudgeting.InventoryConsumptionPlans Then
		
		RegisterMetadata = MetadataOfAccumulationRegisters.InventoryConsumptionPlans;
		
	ElsIf SourceType = Enums.DataSourceTypesForBudgeting.AssemblyDisassemblyPlans Then
		
		RegisterMetadata = MetadataOfAccumulationRegisters.AssemblyDisassemblyPlans;
		
	ElsIf SourceType = Enums.DataSourceTypesForBudgeting.PlansOfGoodsStock Then
		
		RegisterMetadata = MetadataOfAccumulationRegisters.PlansOfGoodsStock;
		
	Else
		
		MessageTemplate = NStr("ru = 'Не удалось определить регистр по переданному типу источника данных (%1)';
								|vi = 'Cannot identify the register based on the passed data source type (%1)';
								|en = 'Cannot identify the register based on the passed data source type (%1)'; fa = 'Cannot identify the register based on the passed data source type (%1)';
								|it = 'Cannot identify the register based on the passed data source type (%1)';
								|pl = 'Cannot identify the register based on the passed data source type (%1)';
								|tr = 'İletilen veri kaynağı tipine göre kayıt belirlenemedi (%1)'");
		Raise StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, SourceType);
		
	EndIf;
	
	RegisterParameters.RegisterName = RegisterMetadata.Name;
	
	For Each Dimension In RegisterMetadata.Dimensions Do
		If ExcludedDimensions.Find(Dimension.Name) <> Undefined Then
			Continue;
		EndIf;
		StructureOfData = New Structure("Description, ValueType", Dimension.Synonym, Dimension.Type);
		RegisterParameters.Dimensions.Insert(Dimension.Name, StructureOfData);
	EndDo;
	
	For Each Resource In RegisterMetadata.Resources Do
		StructureOfData = New Structure("Description, ValueType", Resource.Synonym, Resource.Type);
		RegisterParameters.Resources.Insert(Resource.Name, StructureOfData);
	EndDo;
	
	Return RegisterParameters;
	
EndFunction

// Returns the correspondence of the types of analytics and fill-in expressions for queries to the registers of the planning subsystem
// , depending on the type of data source for budgeting.
//
// Parameters:
//  SourceType - EnumRef.DataSourceTypesForBudgeting - type of data source
//
// Returns:
//  Map of KeyAndValue:
//   *Key - Type - Type Of Analytics Value
//   *Value - String - fill-in expressions for queries
//
Function AvailableTypesOfAnalyticsForPlanningSourceType(SourceType) Export
	
	AvailableTypesOfAnalytics = New Map;
	
	RegisterParameters = ParametersOfRegisterOfSourceOfReceivingDataForBudgeting(SourceType);
	RegisterDimensions = RegisterParameters.Dimensions;
	
	If RegisterDimensions.Property("Products") Then
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.Products"), "TableName.Products");
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.ItemKinds"), "TableName.Products.ProductKind");
		AvailableTypesOfAnalytics.Insert(Type("EnumRef.ItemsTypes"), "TableName.Products.ItemsType");
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.Brands"), "TableName.Products.Brand");
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.Manufacturers"), "TableName.Products.Manufacturer");
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.SeasonalGroups"), "TableName.Products.ItemsGroup");
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.PriceGroups"), "TableName.Products.PriceGroup");
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.ProductCategories"), "TableName.Products.ProductCategory");
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.AnalyticalInventoryGroups"), 
			"TableName.Products.AnalyticalGroup");
	ElsIf RegisterDimensions.Property("ProductCategory") Then
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.ProductCategories"), "TableName.ProductCategory");
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.ItemKinds"), "TableName.ProductCategory.Owner");
	EndIf;
	
	If RegisterDimensions.Property("Characteristic") Then
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.ItemsCharacteristics"), "TableName.Characteristic");
	EndIf;
	
	If RegisterDimensions.Property("Department") Then
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.BusinessStructure"), "TableName.Department");
	ElsIf RegisterDimensions.Property("Warehouse") Then
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.BusinessStructure"), "TableName.Warehouse.Department");
	ElsIf SourceType = Enums.DataSourceTypesForBudgeting.CashFlowPlansCustomers
		Or SourceType = Enums.DataSourceTypesForBudgeting.CashFlowPlansVendors Then
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.BusinessStructure"), "TableName.Plan.Department");
	EndIf;
	
	If RegisterDimensions.Property("Warehouse") Then
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.Warehouses"), "TableName.Warehouse");
	EndIf;
	
	If RegisterDimensions.Property("Purpose") Then
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.LinesOfBusiness"), "TableName.Purpose.LineOfBusiness");
		AvailableTypesOfAnalytics.Insert(Type("DocumentRef.SalesOrder"), "TableName.Purpose.OrderDocument");
	EndIf;
	
	If RegisterDimensions.Property("Organization") Then
		If SourceType = Enums.DataSourceTypesForBudgeting.SalesPlans
			Or SourceType = Enums.DataSourceTypesForBudgeting.PurchasePlans Then
			AvailableTypesOfAnalytics.Insert(Type("CatalogRef.Companies"),
				"CASE
				|	WHEN TableName.Organization = VALUE(Catalog.Companies.EmptyRef)
				|		THEN TableName.Terms.Organization
				|	ELSE TableName.Organization
				|END");
		ElsIf SourceType = Enums.DataSourceTypesForBudgeting.CashFlowPlansCustomers
			Or SourceType = Enums.DataSourceTypesForBudgeting.CashFlowPlansVendors Then
			AvailableTypesOfAnalytics.Insert(Type("CatalogRef.Companies"),
				"CASE
				|	WHEN TableName.Organization = VALUE(Catalog.Companies.EmptyRef)
				|		THEN TableName.Plan.Terms.Organization
				|	ELSE TableName.Organization
				|END");
		Else
			AvailableTypesOfAnalytics.Insert(Type("CatalogRef.Companies"), "TableName.Organization");
		EndIf;
	EndIf;
	
	If RegisterDimensions.Property("Partner") Then
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.Partners"), "TableName.Partner");
		If GetFunctionalOption("UsePartnersAndCounterparties") Then
			If SourceType = Enums.DataSourceTypesForBudgeting.SalesPlans Then
				AvailableTypesOfAnalytics.Insert(Type("CatalogRef.Counterparties"),
					"CASE
					|	WHEN TableName.SalesPlan.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
					|		THEN TableName.Terms.Counterparty
					|	ELSE TableName.SalesPlan.Contract.Counterparty
					|END");
				AvailableTypesOfAnalytics.Insert(Type("CatalogRef.CounterpartyContracts"), "TableName.SalesPlan.Contract");
			ElsIf SourceType = Enums.DataSourceTypesForBudgeting.CashFlowPlansCustomers Then
				AvailableTypesOfAnalytics.Insert(Type("CatalogRef.Counterparties"), "TableName.Contract.Counterparty");
				AvailableTypesOfAnalytics.Insert(Type("CatalogRef.CounterpartyContracts"), "TableName.Contract");
			ElsIf SourceType = Enums.DataSourceTypesForBudgeting.PurchasePlans Then
				AvailableTypesOfAnalytics.Insert(Type("CatalogRef.Counterparties"), "TableName.Terms.Counterparty");
			EndIf;
		Else
			AvailableTypesOfAnalytics.Insert(Type("CatalogRef.Counterparties"), "TTPartnersCounterparties.Counterparty");
		EndIf;
	EndIf;
	
	If RegisterDimensions.Property("Terms") Then
		If SourceType = Enums.DataSourceTypesForBudgeting.PurchasePlans Then
			AvailableTypesOfAnalytics.Insert(Type("CatalogRef.TermsOfPurchaseFromVendors"), "TableName.Terms");
			AvailableTypesOfAnalytics.Insert(Type("CatalogRef.CashFlowReportItems"), "TableName.Terms.CashFlowItem");
		Else
			AvailableTypesOfAnalytics.Insert(Type("CatalogRef.TermsOfSale"), "TableName.Terms");
			AvailableTypesOfAnalytics.Insert(Type("CatalogRef.CashFlowReportItems"),
				"CASE
				|	WHEN TableName.SalesPlan.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
				|		THEN TableName.Terms.CashFlowItem
				|	ELSE TableName.SalesPlan.Contract.CashFlowItem
				|END");
		EndIf;
	ElsIf RegisterDimensions.Property("Contract") Then
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.CashFlowReportItems"), "TableName.Contract.CashFlowItem");
	EndIf;
	
	If RegisterDimensions.Property("StoreFormat") Then
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.StoreFormats"), "TableName.StoreFormat");
	EndIf;
	
	If RegisterDimensions.Property("Manager") Then
		AvailableTypesOfAnalytics.Insert(Type("CatalogRef.Users"), "TableName.Manager");
	EndIf;
	
	RegisterDimensionName = NameOfDimensionOfPlanningDocumentBySourceType(SourceType);
	
	If ValueIsFilled(RegisterDimensionName) Then
	
		Query = New Query;
		Query.Text = 
		"SELECT DISTINCT
		|	AdditionalAttributes.Property.IDForFormulas AS Id,
		|	VALUETYPE(AdditionalAttributes.Value) AS Type
		|FROM
		|	Document.SalesPlan.AdditionalAttributes AS AdditionalAttributes
		|WHERE
		|	CASE
		|			WHEN VALUETYPE(AdditionalAttributes.Value) = TYPE(Catalog.ObjectsPropertiesValues)
		|				THEN TRUE IN
		|						(SELECT TOP 1
		|							TRUE
		|						FROM
		|							ChartOfCharacteristicTypes.BudgetFlowItemDimensions AS BudgetFlowItemDimensions
		|						WHERE
		|							AdditionalAttributes.Property = BudgetFlowItemDimensions.AdditionalProperty)
		|			ELSE TRUE
		|		END";
		If SourceType = Enums.DataSourceTypesForBudgeting.CashFlowPlansVendors Then
			Query.Text = StrReplace(Query.Text, "SalesPlan", "PurchasePlan");
		ElsIf SourceType <> Enums.DataSourceTypesForBudgeting.CashFlowPlansCustomers Then
			Query.Text = StrReplace(Query.Text, "SalesPlan", RegisterDimensionName);
		EndIf;
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			If AvailableTypesOfAnalytics.Get(Selection.Type) = Undefined Then
				AvailableTypesOfAnalytics.Insert(Selection.Type, StringFunctionsClientServer.SubstituteParametersToString(
					"%1_%2.Value", RegisterDimensionName, Selection.Id));
			EndIf;
		EndDo;
	
	EndIf;
	
	Return AvailableTypesOfAnalytics;
	
EndFunction

// Returns the dimension name of the planning document register of the planning subsystem by source type calculation rules
//
// Parameters:
//  SourceType - EnumRef.DataSourceTypesForBudgeting
//
// Returns:
//  String
//
Function NameOfDimensionOfPlanningDocumentBySourceType(SourceType) Export
	
	DimensionNamesOfRegisters = New Map;
	DimensionNamesOfRegisters.Insert(
		Enums.DataSourceTypesForBudgeting.InventoryConsumptionPlans, "InventoryConsumptionPlan");
	DimensionNamesOfRegisters.Insert(
		Enums.DataSourceTypesForBudgeting.PurchasePlans, "PurchasePlan");
	DimensionNamesOfRegisters.Insert(
		Enums.DataSourceTypesForBudgeting.CashFlowPlansCustomers, "Plan");
	DimensionNamesOfRegisters.Insert(
		Enums.DataSourceTypesForBudgeting.CashFlowPlansVendors, "Plan");
	DimensionNamesOfRegisters.Insert(
		Enums.DataSourceTypesForBudgeting.PlansOfGoodsStock, "PlanOfGoodsStock");
	DimensionNamesOfRegisters.Insert(
		Enums.DataSourceTypesForBudgeting.SalesPlans, "SalesPlan");
	DimensionNamesOfRegisters.Insert(
		Enums.DataSourceTypesForBudgeting.SalesPlansByCategories, "SalesPlanByCategories");
	DimensionNamesOfRegisters.Insert(
		Enums.DataSourceTypesForBudgeting.ProductionPlans, "ProductionPlan");
	DimensionNamesOfRegisters.Insert(
		Enums.DataSourceTypesForBudgeting.AssemblyDisassemblyPlans, "AssemblyDisassemblyPlan");
		
	Return DimensionNamesOfRegisters.Get(SourceType);
	
EndFunction

// Returns the correspondence of the article, indicator, or NFP analyst with the type of data source for the planning subsystem
//
// Parameters:
// 
//  SourceType - EnumRef.DataSourceTypesForBudgeting
//  ArticleNFPIndicator - CatalogRef.BudgetFlowItems,
//						Reference link.Indicators of budgets,
//						Reference link.Non-financial indicators of budgets - an article, indicator, or NFP.
//
// Returns:
//  Map of KeyAndValue:
//   *Key - String - string expression of the type of analysis of an article, indicator, or NFP
//   *Value - String - filling expressions from the data source of the planning subsystem
//  It is uncertain if the analysts of the budget item or indicator do not match the NFP analysts.
//
Function ComplianceOfArticleAnalystWithNFPSIndicatorWithTypeOfPlanningSource(SourceType, ArticleNFPIndicator) Export
	
	ComplianceAnalyst = New Map;
	
	TypesOfAnalyticsArticlesOfIndicator = BudgetingServer.DimensionKinds(ArticleNFPIndicator, True);
	AvailableTypesOfAnalytics = AvailableTypesOfAnalyticsForPlanningSourceType(SourceType);
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		
		ExpressionNameTypeOfAnalytics = StringFunctionsClientServer.SubstituteParametersToString("DimensionKind%1", DimensionNumber);
		If Not ValueIsFilled(TypesOfAnalyticsArticlesOfIndicator[ExpressionNameTypeOfAnalytics]) Then
			Continue;
		EndIf;
		ExpressionNameTypeOfAnalysisValueType = StringFunctionsClientServer.SubstituteParametersToString(
			"DimensionKind%1ValueType", DimensionNumber);
		TypesOfAnalyticsType = TypesOfAnalyticsArticlesOfIndicator[ExpressionNameTypeOfAnalysisValueType].Types();
		
		MapFound = False;
		
		For Each Type In TypesOfAnalyticsType Do
			If AvailableTypesOfAnalytics[Type] <> Undefined Then
				ComplianceAnalyst.Insert(DimensionNumber, AvailableTypesOfAnalytics[Type]);
				MapFound = True;
			EndIf;
			If MapFound Then
				Break;
			EndIf;
		EndDo;
		
		If Not MapFound Then
			ComplianceAnalyst = Undefined;
			Break;
		EndIf;
		
	EndDo;
	
	Return ComplianceAnalyst;
	
EndFunction

// Returns the correspondence between expressions and aliases of budgeting dimensions for queries by source type.
//
// Parameters:
//  SourceType - EnumRef.DataSourceTypesForBudgeting - Source type
//
// Returns:
//  Structure:
//   *Scenario - String - Measurement expression Scenario
//   *Organization - String - measurement expression Company
//   *Department - String - Measurement expression Subdivision
//   *StorageCurrency - String - expression of the currency storage measurement
//   *Status - String - Measurement expression Status
//
Function MatchingBudgetingDimensionsBySourceType(SourceType) Export
	
	BudgetingDimensions = "Scenario, Organization, Department, StorageCurrency, Status";
	DimensionsByTypeOfSource = New Structure(BudgetingDimensions);
	
	AvailableTypesOfAnalytics = AvailableTypesOfAnalyticsForPlanningSourceType(SourceType);
	
	For Each Dimension In DimensionsByTypeOfSource Do
		If SourceType = Enums.DataSourceTypesForBudgeting.BudgetTurnovers Then
			If Dimension.Key = "StorageCurrency" Then
				DimensionsByTypeOfSource[Dimension.Key] = "Currency";
			Else
				DimensionsByTypeOfSource[Dimension.Key] = Dimension.Key;
			EndIf;
		Else
			If Dimension.Key = "Scenario" Then
				DimensionsByTypeOfSource[Dimension.Key] = "Scenario.BudgetingScenario";
			ElsIf Dimension.Key = "Organization" Then
				DimensionsByTypeOfSource[Dimension.Key] = AvailableTypesOfAnalytics.Get(Type("CatalogRef.Companies"));
			ElsIf Dimension.Key = "Department" Then
				DimensionsByTypeOfSource[Dimension.Key] = AvailableTypesOfAnalytics.Get(Type("CatalogRef.BusinessStructure"));
			ElsIf Dimension.Key = "StorageCurrency" Then
				DimensionsByTypeOfSource[Dimension.Key] = "Scenario.Currency";
			Else
				DimensionsByTypeOfSource[Dimension.Key] = Dimension.Key;
			EndIf;
		EndIf;
	EndDo;
	
	Return DimensionsByTypeOfSource;
	
EndFunction

// Returns matching types of budgeting analytics related to the Company dimension
//
// Returns:
//  Map of KeyAndValue:
//   *Key - Type - Type Of Analytics Value
//   *Value - String - fill-in expressions for queries
//
Function TypesOfAnalyticsRelatedToOrganization() Export
	
	RelatedTypesOfAnalytics = New Map;
	
	RelatedTypesOfAnalytics.Insert(Type("CatalogRef.CounterpartyContracts"), "Organization");
	RelatedTypesOfAnalytics.Insert(Type("CatalogRef.LoanAndDepositContracts"), "Organization");
	RelatedTypesOfAnalytics.Insert(Type("CatalogRef.LeaseContract"), "Organization");
	RelatedTypesOfAnalytics.Insert(Type("CatalogRef.IntercompanyContracts"), "Organization");
	
	RelatedTypesOfAnalytics.Insert(Type("CatalogRef.CompaniesBankAccounts"), "Owner");
	RelatedTypesOfAnalytics.Insert(Type("CatalogRef.CashAccounts"), "Owner");
	RelatedTypesOfAnalytics.Insert(Type("CatalogRef.CashRegisters"), "Owner");
	
	RelatedTypesOfAnalytics.Insert(Type("CatalogRef.ARAPObjects"), "Organization");
	
	RelatedTypesOfAnalytics.Insert(Type("CatalogRef.EmployeesHR"), "ParentCompany");
	
	RelatedTypesOfAnalytics.Insert(Type("DocumentRef.PurchaseOrder"), "Organization");
	RelatedTypesOfAnalytics.Insert(Type("DocumentRef.SalesOrder"), "Organization");
	RelatedTypesOfAnalytics.Insert(Type("DocumentRef.OrderOfMaterialsForProduction"), "Organization");
	RelatedTypesOfAnalytics.Insert(Type("DocumentRef.InventoryConsumptionOrder"), "Organization");
	RelatedTypesOfAnalytics.Insert(Type("DocumentRef.TransferOrder"), "Organization");
	RelatedTypesOfAnalytics.Insert(Type("DocumentRef.ByAssemblyDisassemblyOrder"), "Organization");
	RelatedTypesOfAnalytics.Insert(Type("DocumentRef.SubcontractOrder2_5"), "Organization");
	RelatedTypesOfAnalytics.Insert(Type("DocumentRef.ProductionOrder2_2"), "Organization");
	RelatedTypesOfAnalytics.Insert(Type("DocumentRef.MaterialProviderOrder2_5"), "Organization");
	RelatedTypesOfAnalytics.Insert(Type("DocumentRef.RMOrder"), "Organization");
	Return RelatedTypesOfAnalytics;
	
EndFunction

#EndRegion

#Region Private

Procedure ToSupplementResidualFinancialRegistersByTypeOfDocument(DocumentKind, ResidualFinancialRegisters)
	
	AccountingSettings = ActualBudgetingDataByAssetAndLiabilityItems.FinancialAccountingSettingsForBudgeting();
	FinancialRegisters = ChartsOfCharacteristicTypes.AssetLiabilityItems.DataSourcesOfAccountingObjects(AccountingSettings);
	
	AccumulationRegistersMetadata = Metadata.AccumulationRegisters;
	DocumentRegisteredRecordCollection = New Array;
	
	If DocumentKind = Common.MetadataObjectID(Metadata.Documents.ExchangeDifferenceCalculation) Then
		DocumentRegisteredRecordCollection.Add(AccumulationRegistersMetadata.VendorsARAPAccountingByDueDates);
		DocumentRegisteredRecordCollection.Add(AccumulationRegistersMetadata.CustomersARAPAccountingByDueDates);
	EndIf;
	
	For Each RegisterMetadata In DocumentRegisteredRecordCollection Do // -MetadataObject-
		
		If FinancialRegisters.Find(RegisterMetadata.Name) <> Undefined Then
			ResidualFinancialRegisters.Insert(
				RegisterMetadata.Name,
				AccumulationRegisters[RegisterMetadata.Name].ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegisterMetadata));
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

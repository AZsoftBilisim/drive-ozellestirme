#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("Purchases");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("Production");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("ImportAccounting");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("WIPAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfWorks");
	DocumentMechanisms.Add("PricesAndDiscounts");
	DocumentMechanisms.Add("DocumentCorrection");
	
	SubcontractorReport2_5Localization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.SubcontractorReport2_5") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		QueryTextTableProductsRelease(Query, QueryTexts, Registers);
		QueryTextRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTablePurchaseOrders(Query, QueryTexts, Registers);
		QueryTextTablePurchases(Query, QueryTexts, Registers);
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableItemsPricesOfVendor(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
		SubcontractorReport2_5Localization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, SubcontractOrder, Manager";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CompanyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CounterpartyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1,
		"ExternalDocumentName",
		Parameters);
	
EndProcedure

#Region FillType

// Returns the structure required for further use when filling out the document.
//
// Returns:
//   Structure - structure of document filling parameters.
//
Function DocumentFillingParameters() Export
	
	FillParameters = New Structure();
	
	FillParameters.Insert("AnArrayOfOrders",         Undefined);
	FillParameters.Insert("ByOrders",             False);
	
	FillParameters.Insert("HeaderAttributes",        Undefined);
	
	FillParameters.Insert("DocumentName",          "SubcontractorReport2_5");
	FillParameters.Insert("RegisterNameOrder",      "ShipmentAndReturnReferences");
	FillParameters.Insert("FieldNameOrder",          "SubcontractOrder");
	
	FillParameters.Insert("KeyFields",          "Products, Characteristic, Series");
	
	Return FillParameters;
	
EndFunction

// Initializes the structure of filling parameters based on header details and orders.
//
// Parameters:
//  FillParameters	 - Structure - The default settings get in the method of Parametrization()
//  HeaderAttributes		 - Structure - Contains the keys that will be used for filling in
//  AnArrayOfOrders		 - Array - Links to orders that will be filled in.
//
Procedure InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders) Export
	
	FillParameters.AnArrayOfOrders	= AnArrayOfOrders;
	
	FillParameters.HeaderAttributes	= HeaderAttributes;
	FillParameters.ByOrders		= TypeOf(AnArrayOfOrders[0]) = Type("DocumentRef.SubcontractOrder2_5");
	
EndProcedure

// Creates a structure for creating an order document
//  If the header details differ in the submitted orders, an error message is displayed.
//
// Parameters:
//  ReferencesArrray - Array - domestic consumption orders for which you need to enter an invoice.
//  OrderProperties_ - Undefined
//  
// Returns:
//  Structure - the structure where the header details from the order array will be placed.
//
Function InvoiceFillingData(ReferencesArrray, OrderProperties_ = Undefined) Export
	
	Attributes = "Partner,Counterparty,Contract,Organization,
				|SalesOpportunity,LineOfBusiness,Department,
				|Currency,PurchaseForActivity";
	
	Return Common.ObjectAttributesValues(ReferencesArrray[0], Attributes);
	
EndFunction

// Returns a list of details that can be used to group orders within a single report.
//
// Returns:
//  String - the names of the details, separated by commas.
//
Function KeyFieldsOfHeader() Export
	
	Return "Partner,Counterparty,Contract,Organization,SalesOpportunity,Currency,LineOfBusiness,Department";
	
EndFunction

// Fills in by-products, materials and works according to product specifications
//
// Parameters:
//  Object			 - DocumentObject.SubcontractorReport2_5, FormDataStructure - object to fill in
//  ProductList_	 - Array, TabularSection - list of product lines
// 	ListOfTS - String - a list of names of table parts that need to be filled in.
//
Procedure FillInByProductsMaterialsServicesAccordingToSpecification(Object, ProductList_, ListOfTS = "") Export
	
	NamesOfTS = New Structure(ListOfTS);
	FillInAll_ = NamesOfTS.Count() = 0;
	
	CostGroups = New Array;
	ItemList = Catalogs.BillsOfMaterials.ItemList();
	// Grouping fields
	ItemList.Columns.Add("CostGroupNumber");
	
	For Each CurrentData In ProductList_ Do
		
		CostGroups.Add(CurrentData.CostGroupNumber);
		
		If Not ValueIsFilled(CurrentData.BillOfMaterials)
			Or CurrentData.Count = 0 Then
			Continue;
		EndIf;
		
		NewRow = ItemList.Add();
		FillPropertyValues(
			NewRow,
			CurrentData,
			"Products,Characteristic,BillOfMaterials,Count,CostGroupNumber");
		
		NewRow.ProductionStart      = Object.Date;
		NewRow.LineOfBusiness = Object.LineOfBusiness;
		
	EndDo;
	
	CommonClientServer.CollapseArray(CostGroups);
	
	#Region ProductActionStructure
	
	ProductActionStructure = New Structure;
	
	#Region FillInTheDefaultAccountSetting
	
	AccountingAccountParameters = Documents.SubcontractorReport2_5.AccountingAccountSettings_();
	GLAccountSettingsClientServer.InsertActionFillInDefaultAccountingAccountsSetting(
		ProductActionStructure,
		AccountingAccountParameters,
		"Object.SideAndIntermediateRelease");
	
	#EndRegion
	
	#Region FillInSalePrice
	
	ActionParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object, True);
	ActionParameters.Insert("PriceKind", Object.PriceKind);
	ProductActionStructure.Insert("FillInSalePrice", ActionParameters);
	
	#EndRegion
	
	#Region RecalculateAmount
	
	ProductActionStructure.Insert("RecalculateAmount");
	
	#EndRegion
	
	#EndRegion
	
	#Region StructureOfServiceActions
	
	If Object.ProcessingServices = Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder Then
		
		StructureOfServiceActions = New Structure;
		
		ActionParameters = New Structure;
		
		SelectingTypeOfPrices = New Structure("Owner, PriceIncludesVAT", Object.Partner, Object.PriceIncludesVAT);
		DefaultVendorPriceView = Catalogs.VendorPriceTypes.DefaultPriceType(Undefined, SelectingTypeOfPrices);
		
		ActionParameters.Insert("NameOfPriceTypeField", "VendorPriceKind");
		ActionParameters.Insert("PriceKind", DefaultVendorPriceView);
		StructureOfServiceActions.Insert("FillInPriceView", ActionParameters);
		
		ActionParameters = BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object);
		//Installing an empty link to the packaging, since there is no record of work on packaging
		ActionParameters.Insert("Package", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
		StructureOfServiceActions.Insert("FillInPurchasePrice", ActionParameters);
		
		ActionParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
		StructureOfServiceActions.Insert("FillInVATRate", ActionParameters);
		
		StructureOfServiceActions.Insert("RecalculateAmount", "Count");
		
		ActionParameters = New Structure;
		ActionParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
		ActionParameters.Insert("VATTaxation", Object.VATTaxation);
		StructureOfServiceActions.Insert("RecalculateVATAmount", ActionParameters);
		StructureOfServiceActions.Insert("RecalculateAmountWithVAT", ActionParameters);
		
	EndIf;
	
	#EndRegion
	
	ListOfData = New Array;
	ListOfData.Add("Stages");
	
	If FillInAll_
		Or NamesOfTS.Property("SideAndIntermediateRelease")
		Or NamesOfTS.Property("MaterialsAndWorks") Then
		ListOfData.Add("RecyclableWaste");
	EndIf;
	
	If FillInAll_
		Or NamesOfTS.Property("SideAndIntermediateRelease")
		Or NamesOfTS.Property("MaterialsAndWorks") Then
		ListOfData.Add("MaterialsAndServices");
	EndIf;
	
	SelectionParameters =
		Catalogs.BillsOfMaterials.DataSamplingParameters(
			ListOfData,,
			Enums.ProductionSupplyFillingVariants.BySupplySchemes);
	
	SelectionParameters.GetAutoSelectionInformation = False;
	SelectionParameters.GetPresentations      = False;
	SelectionParameters.OverridingReleasePartySetting.Use = True;
	SelectionParameters.OverridingReleasePartySetting.ProductionIssueByCustomPortions = True;
	
	SpecificationsData = Catalogs.BillsOfMaterials.SpecificationDataByProductsList(
		ItemList,
		SelectionParameters,
		True,
		"CostGroupNumber");
	
	For Each StructureOfData In SpecificationsData Do
		
		If StructureOfData = Undefined Then
			Continue;
		EndIf;
		
		If FillInAll_
			Or NamesOfTS.Property("SideAndIntermediateRelease")
			Or NamesOfTS.Property("MaterialsAndWorks") Then
			Catalogs.BillsOfMaterials.ExcludeIntermediateRelease(StructureOfData);
		EndIf;
		
		// SideAndIntermediateRelease
		If FillInAll_
			Or NamesOfTS.Property("SideAndIntermediateRelease") Then
			FillInStandards_(
				Object.SideAndIntermediateRelease,
				StructureOfData.RecyclableWaste,
				StructureOfData.CostGroupNumber,
				ProductActionStructure);
		EndIf;
		
		// SupplyWithMaterialsAndWorks
		If FillInAll_
			Or NamesOfTS.Property("MaterialsAndWorks") Then
			FillInStandards_(
				Object.MaterialsAndWorks,
				StructureOfData.MaterialsAndServices,
				StructureOfData.CostGroupNumber);
		EndIf;
		
		// Services
		If Object.ProcessingServices = Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder
			And (FillInAll_
				Or NamesOfTS.Property("Services")) Then
			
			For Each CurStage In StructureOfData.Stages Do
				
				If Not CurStage.ProductionByThirdParty
					Or CurStage.SubcontractorServices.Count() = 0 Then
					Continue;
				EndIf;
				
				FillInStandards_(
					Object.Services,
					CurStage.SubcontractorServices,
					StructureOfData.CostGroupNumber,
					StructureOfServiceActions);
				
			EndDo;
		EndIf;
		
	EndDo;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.SubcontractorReport2_5);
	If FillInAll_
		Or NamesOfTS.Property("SideAndIntermediateRelease") Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.SideAndIntermediateRelease);
		ProductsServer.ClearUnusedSeries(Object, SeriesSpecificationParameters.SideAndIntermediateRelease);
	EndIf;
	
	If FillInAll_
		Or NamesOfTS.Property("MaterialsAndWorks") Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.MaterialsAndWorks);
		ProductsServer.ClearUnusedSeries(Object, SeriesSpecificationParameters.MaterialsAndWorks);
	EndIf;
	
	If Object.ProcessingServices = Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder
		And (FillInAll_
			Or NamesOfTS.Property("Services")) Then
		
		StructureOfServiceActions = New Structure;
		ActionParameters = New Structure;
		
		ActionParameters.Insert("NameOfPriceTypeField", "VendorPriceKind");
		ActionParameters.Insert("PriceKind", DefaultVendorPriceView);
		StructureOfServiceActions.Insert("FillInPriceView", ActionParameters);
		
		RowsToProcess = New Array;
		
		Filter = New Structure("CostGroupNumber");
		For Each CurrentData In CostGroups Do
			
			Filter.CostGroupNumber = CurrentData;
			
			If Object.Services.FindRows(Filter).Count() = 0 Then
				NewRow = Object.Services.Add();
				NewRow.CostGroupNumber = CurrentData;
				RowsToProcess.Add(NewRow);
			EndIf;
			
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfServiceActions,
			Object.Services);
		
	EndIf;
	
EndProcedure

// Fill in based on the order.
// 
// Parameters:
//  Object - FormDataStructure, DocumentObject.SubcontractorReport2_5 - object to fill in
//  DocumentBasis - DocumentRef.SubcontractOrder2_5
//
Procedure FillInBasedOnOrder(Object, DocumentBasis) Export
	
	Object.ByOrders = True;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	SubcontractOrder.Status                    AS DocumentStatus,
	|	SubcontractOrder.Organization               AS Organization,
	|	SubcontractOrder.Department             AS Department,
	|	SubcontractOrder.SalesOpportunity                    AS SalesOpportunity,
	|	SubcontractOrder.Ref                    AS SubcontractOrder,
	|	SubcontractOrder.GroupCosts         AS GroupCosts,
	|	SubcontractOrder.ProcessingServices       AS ProcessingServices,
	|	SubcontractOrder.Partner                   AS Partner,
	|	SubcontractOrder.Counterparty                AS Counterparty,
	|	SubcontractOrder.Contract                   AS Contract,
	|	SubcontractOrder.MethodOfAllocatingFinishedProductCosts AS MethodOfAllocatingFinishedProductCosts,
	|	SubcontractOrder.LineOfBusiness   AS LineOfBusiness,
	|	SubcontractOrder.Contract.ARAPCurrency AS ARAPCurrency,
	|	SubcontractOrder.Currency                    AS Currency,
	|	SubcontractOrder.PriceIncludesVAT           AS PriceIncludesVAT,
	|	SubcontractOrder.VATTaxation        AS VATTaxation,
	|	SubcontractOrder.PurchaseForActivity    AS PurchaseForActivity,
	|	SubcontractOrder.PriceKind                   AS PriceKind,
	|	SubcontractOrder.RegisterVendorPrices AS RegisterVendorPrices,
	|	SubcontractOrder.PaymentMethod               AS PaymentMethod,
	|	SubcontractOrder.ARAPObjectSettings           AS ARAPObjectSettings,
	|	SubcontractOrder.ForeignCurrencyTransaction             AS ForeignCurrencyTransaction,
	|	SubcontractOrder.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	SubcontractOrder.BankAccount            AS CompanyBankAccount,
	|	NOT SubcontractOrder.Posted               AS ThereAreErrorsPosted,
	|	CASE SubcontractOrder.Status
	|		WHEN VALUE(Enum.TollingOrderStatuses.ForFulfillment)
	|			THEN FALSE
	|		WHEN VALUE(Enum.TollingOrderStatuses.Closed)
	|			THEN FALSE
	|		ELSE TRUE
	|	END                                        AS ThereAreErrorsStatus
	|FROM
	|	Document.SubcontractOrder2_5 AS SubcontractOrder
	|WHERE
	|	SubcontractOrder.Ref = &DocumentBasis";
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	OrderDetails = Query.Execute().Select();
	OrderDetails.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.TollingOrderStatuses.ForFulfillment);
	ArrayOfValidStatuses.Add(Enums.TollingOrderStatuses.Closed);
	
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.Status = OrderDetails.DocumentStatus;
	CheckParameters.ThereAreErrorsPosted = OrderDetails.ThereAreErrorsPosted;
	CheckParameters.ThereAreErrorsStatus = OrderDetails.ThereAreErrorsStatus;
	CheckParameters.ArrayOfValidStatuses = ArrayOfValidStatuses;
	
	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(OrderDetails.SubcontractOrder, CheckParameters);
	
	// Filling in the header.
	FillPropertyValues(Object, OrderDetails);
		
	PurchasesServerCall.FillInBankAccountsUnderAgreement(
		Object.Contract,
		Object.CompanyBankAccount,
		Object.CounterpartyBankAccount);
		
	FillInProductsMaterialsServicesOnRequest(Object);
	Object.DocumentAmount = Object.Services.Total("AmountIncludingVAT");
	
	If GetFunctionalOption("UseReceiptForMultipleOrders") Then
		Object.SalesOpportunity = Catalogs.SalesOpportunitiesToCustomer.EmptyRef();
	EndIf;
	
EndProcedure

// Fills in by-products, materials and works ordered by the processor
// 
// Parameters:
// 	Object - DocumentObject.SubcontractorReport2_5, FormDataStructure - object to fill in
// 	CostGroupNumbers - Array - the numbers of the cost groups for which the document needs to be refilled.
// 	ListOfTS - String - a list of names of table parts that need to be filled in.
//
Procedure FillInProductsMaterialsServicesOnRequest(Object, CostGroupNumbers = Undefined, ListOfTS = "") Export
	
	NamesOfTS = New Structure(ListOfTS);
	FillInAll_ = NamesOfTS.Count() = 0;
	
	QueryTexts = New Array;
	
	//Products to be placed on order
	Filter = New Structure;
	Filter.Insert("PurchaseOrder", "SubcontractOrder");
	QueryTexts.Add(
		AccumulationRegisters.PurchaseOrders.QueryTextBalance("ProductsToBeProcessedByOrder", Filter, "ToRegister > 0"));
	
	//Goods to be placed in excess of the order
	QueryTexts.Add(
		TextOfRequestProductsOverOrderToCheckout("ProductsToBePlacedInExcessOfOrder", Filter));
	
	Filter = New Map;
	If ValueIsFilled(CostGroupNumbers) Then
		TMCommonUse.AddSelectionItemToCollection(Filter, "CostGroupNumber", "&CostGroupNumbers");
	EndIf;
	
	QueryTexts.Add(Documents.SubcontractOrder2_5.RequestTextOutputDocumentItems(Filter));
	QueryTexts.Add(Documents.SubcontractOrder2_5.RequestTextAndDocumentItems(Filter));
	QueryTexts.Add(Documents.SubcontractOrder2_5.RequestTextProvisionOfMaterialsAndWorksOfDocument(Filter));
	
	Filter = New Map;
	If ValueIsFilled(CostGroupNumbers) Then
		TMCommonUse.AddSelectionItemToCollection(Filter, "Services.CostGroupNumber", "&CostGroupNumbers");
	EndIf;
	QueryTexts.Add(Documents.SubcontractOrder2_5.QueryTextDocumentServices(Filter));
	
	// If cost groups are transferred, then this is an interactive re-completion, we get the standards from the report
	If ValueIsFilled(CostGroupNumbers) Then
		AddRequestTextsProductStandardsForReport(QueryTexts);
	Else
		QueryTexts.Add(RequestTextProductStandardsByOrder());
	EndIf;
	
	If FillInAll_
		Or NamesOfTS.Property("ManufacturedProducts")
		Or NamesOfTS.Property("SideAndIntermediateRelease") Then
		AddRequestTextsForSeriesOfReceiptsForOrder(
			QueryTexts,
			FillInAll_ Or NamesOfTS.Property("ManufacturedProducts"),
			FillInAll_ Or NamesOfTS.Property("SideAndIntermediateRelease"));
		IndexOfSeriesQueryResult = QueryTexts.Count() - 1;
	EndIf;
	
	If FillInAll_
		Or NamesOfTS.Property("ManufacturedProducts") Then
		QueryTexts.Add(RequestTextOutputProductsForRegistration());
		NamesOfTS.Insert("ManufacturedProducts", QueryTexts.Count() - 1);
	EndIf;
	
	If FillInAll_
		Or NamesOfTS.Property("SideAndIntermediateRelease") Then
		QueryTexts.Add(RequestTextForProductsForRegistration());
		NamesOfTS.Insert("SideAndIntermediateRelease", QueryTexts.Count() - 1);
	EndIf;
	
	If FillInAll_
		Or NamesOfTS.Property("MaterialsAndWorks") Then
		QueryTexts.Add(QueryTextMaterialsAndWorksTransferred());
		QueryTexts.Add(RequestTextMaterialsAndDesignWork());
		NamesOfTS.Insert("MaterialsAndWorks", QueryTexts.Count() - 1);
	EndIf;
	
	If FillInAll_
		Or NamesOfTS.Property("Services") Then
		QueryTexts.Add(QueryTextServicesForRegistration());
		NamesOfTS.Insert("Services", QueryTexts.Count() - 1);
	EndIf;
	
	Query = New Query;
	If TMCommonUse.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("SubcontractOrder", Object.SubcontractOrder);
	Query.SetParameter("Recorder",        Object.Ref);
	Query.SetParameter("Organization",        Object.Organization);
	Query.SetParameter("ReportStandards",    False);
	If ValueIsFilled(CostGroupNumbers) Then
		Query.SetParameter("CostGroupNumbers",     CostGroupNumbers);
		Query.SetParameter("OutputProductsOfReport", Object.ManufacturedProducts.Unload());
		Query.SetParameter("ByProductsOfReport", Object.SideAndIntermediateRelease.Unload());
		Query.SetParameter("ReportStandards",       True);
	EndIf;
	
	Result = Query.ExecuteBatch();
	
	#Region StructureOfActionsProductsAndMaterials
	
	ActionStructureOutputProducts = New Structure;
	StructureAndByProducts = New Structure;
	StructureAndMaterials = New Structure;
	
	#Region RecalculateNumberOfPackages
	
	ActionStructureOutputProducts.Insert("RecalculateNumberOfPackages");
	StructureAndByProducts.Insert("RecalculateNumberOfPackages");
	StructureAndMaterials.Insert("RecalculateNumberOfPackages");
	
	#EndRegion
	
	#Region FillInSalePrice
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		"FinancialAccountingPolicy",
		Object.Organization,
		Object.Date);
	
	UseTargetCost = False;
	If Not AccountingPolicyParameters = Undefined Then
		UseTargetCost = AccountingPolicyParameters.ProductCostingByPlannedCost;
	EndIf;
	
	ActionParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object, True);
	ActionParameters.Insert("PriceKind", Object.PriceKind);
	
	If UseTargetCost Then
		ActionStructureOutputProducts.Insert("FillInSalePrice", ActionParameters);
	EndIf;
	StructureAndByProducts.Insert("FillInSalePrice", ActionParameters);
	
	#EndRegion
	
	#Region RecalculateAmount
	
	If UseTargetCost Then
		ActionStructureOutputProducts.Insert("RecalculateAmount");
	EndIf;
	StructureAndByProducts.Insert("RecalculateAmount");
	
	#EndRegion
	
	#Region FillInTheDefaultAccountSetting
	
	AccountingAccountParameters = Documents.SubcontractorReport2_5.AccountingAccountSettings_();
	
	GLAccountSettingsClientServer.InsertActionFillInDefaultAccountingAccountsSetting(
		ActionStructureOutputProducts,
		AccountingAccountParameters,
		"Object.ManufacturedProducts");
	
	GLAccountSettingsClientServer.InsertActionFillInDefaultAccountingAccountsSetting(
		StructureAndByProducts,
		AccountingAccountParameters,
		"Object.SideAndIntermediateRelease");
	
	#EndRegion
	
	#EndRegion
	
	#Region StructureOfServiceActions
	
	StructureOfServiceActions = New Structure;
	
	ActionParameters = New Structure;
	
	StructureOfServiceActions.Insert("RecalculateAmount", "Count");
	
	ActionParameters = New Structure;
	ActionParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	ActionParameters.Insert("VATTaxation", Object.VATTaxation);
	StructureOfServiceActions.Insert("RecalculateVATAmount", ActionParameters);
	StructureOfServiceActions.Insert("RecalculateAmountWithVAT", ActionParameters);
	
	#EndRegion
	
	DefaultCostGroupNumber = 0;
	If TypeOf(CostGroupNumbers) = Type("Array")
		And CostGroupNumbers.Count() = 1 Then
		DefaultCostGroupNumber = CostGroupNumbers[0];
	EndIf;
	
	If FillInAll_
		Or NamesOfTS.Property("ManufacturedProducts")
		Or NamesOfTS.Property("SideAndIntermediateRelease") Then
		SeriesTableByReceipts = Result[IndexOfSeriesQueryResult].Unload();
		Var_Key = "Products, Characteristic, Purpose, ToExpenseAs";
		SeriesTableByReceipts.Indexes.Add(Var_Key);
	EndIf;
	
	If FillInAll_
		Or NamesOfTS.Property("ManufacturedProducts") Then
		
		ManufacturedProducts = Result[NamesOfTS["ManufacturedProducts"]].Unload();
		FillInSeriesOfReceipts(ManufacturedProducts, SeriesTableByReceipts, Var_Key);
		
		FillInStandards_(
			Object.ManufacturedProducts,
			ManufacturedProducts,
			DefaultCostGroupNumber,
			ActionStructureOutputProducts);
		
	EndIf;
	
	If FillInAll_
		Or NamesOfTS.Property("SideAndIntermediateRelease") Then
		
		SideAndIntermediateRelease = Result[NamesOfTS["SideAndIntermediateRelease"]].Unload();
		FillInSeriesOfReceipts(SideAndIntermediateRelease, SeriesTableByReceipts, Var_Key);
		
		FillInStandards_(
			Object.SideAndIntermediateRelease,
			SideAndIntermediateRelease,
			DefaultCostGroupNumber,
			StructureAndByProducts);
		
	EndIf;
	
	If FillInAll_
		Or NamesOfTS.Property("MaterialsAndWorks") Then
		FillInStandards_(
			Object.MaterialsAndWorks,
			Result[NamesOfTS["MaterialsAndWorks"]].Unload(),
			DefaultCostGroupNumber,
			StructureAndMaterials);
	EndIf;
	
	If FillInAll_
		Or NamesOfTS.Property("Services") Then
		FillInStandards_(
			Object.Services,
			Result[NamesOfTS["Services"]].Unload(),
			DefaultCostGroupNumber,
			StructureOfServiceActions);
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.SubcontractorReport2_5);
	If FillInAll_
		Or NamesOfTS.Property("ManufacturedProducts") Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.ManufacturedProducts);
		ProductsServer.ClearUnusedSeries(Object, SeriesSpecificationParameters.ManufacturedProducts);
	EndIf;
	
	If FillInAll_
		Or NamesOfTS.Property("SideAndIntermediateRelease") Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.SideAndIntermediateRelease);
		ProductsServer.ClearUnusedSeries(Object, SeriesSpecificationParameters.SideAndIntermediateRelease);
	EndIf;
	
	If FillInAll_
		Or NamesOfTS.Property("MaterialsAndWorks") Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.MaterialsAndWorks);
		ProductsServer.ClearUnusedSeries(Object, SeriesSpecificationParameters.MaterialsAndWorks);
	EndIf;
	
EndProcedure

// Generates an array of acceptable statuses based on the program settings
//
// Parameters:
//	DocumentName - String - Name of the document to enter.
//
// Returns:
//  Array - array of valid statuses.
//
Function ValidInputStatusesBasedOn(DocumentName = "") Export
	
	ArrayOfValidStatuses = New Array;
	ArrayOfValidStatuses.Add(Undefined);
	
	Return ArrayOfValidStatuses;
	
EndFunction

#EndRegion

#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return SubcontractorReport2_5Localization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
// 		String - The text of the request for temporary tables required for reflection in the regulated accounting.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return SubcontractorReport2_5Localization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region Rounding

// Returns the parameters for rounding
// 
// Returns:
// 	Structure - the elements contain a structure of rounding parameters 
// 				See ProductsServer.ParametersForRoundingNumberOfUnitProducts
// 
Function TSParametersForRounding() Export
	
	TSParameters = New Structure;
	
	TSName = "ManufacturedProducts";
	TSParameters.Insert(TSName, ProductsServer.ParametersForCheckingFillingQuantity());
	TSParameters[TSName].TSName = TSName;
	TSParameters[TSName].CheckPossibilityOfRounding = False;
	
	TSName = "SideAndIntermediateRelease";
	TSParameters.Insert(TSName, ProductsServer.ParametersForCheckingFillingQuantity());
	TSParameters[TSName].TSName = TSName;
	TSParameters[TSName].CheckPossibilityOfRounding = False;
	
	TSName = "MaterialsAndWorks";
	TSParameters.Insert(TSName, ProductsServer.ParametersForCheckingFillingQuantity());
	TSParameters[TSName].TSName = TSName;
	TSParameters[TSName].CheckPossibilityOfRounding = False;
	
	Return TSParameters;

EndFunction

#EndRegion

#Region Other

// Initializes the status structure of the document
// 
// Returns:
// 	See Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	
	StructureState.Insert("DisplayCalculationsWithSuppliersTable", 1);
	
	StructureState.Insert("ThisIsAnInvoice",                        True);
	StructureState.Insert("NameOfInvoiceForOrdersField",           "ByOrders");
	
	Return StructureState;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.ReceiptOfGoodsFromCustodian.AddCreateCommandBasedOnReceiptFromProcessor(GenerationCommands);
	
	Command = Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"ProcessingServices",
			Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder);
	EndIf;
	
	Command = Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"ProcessingServices",
			Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder);
	EndIf;
	
	Command = Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"ProcessingServices",
			Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder);
	EndIf;
	
	Command = Documents.VendorInvoiceServicesAndAssets.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"ProcessingServices",
			Enums.OptionsOfRegisteringProcessingDocumentServices.RegisteredSeparately);
	EndIf;
	
	Command = Documents.VendorInvoice.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"ProcessingServices",
			Enums.OptionsOfRegisteringProcessingDocumentServices.RegisteredSeparately);
	EndIf;
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Command = Documents.PurchaseAdjustment.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.Presentation = NStr("vi = 'Điều chỉnh bảng kê của người nhận gia công';
									|ru = 'Корректировка отчета переработчика';
									|en = '""Adjust subcontracting services notification received""'; fa = '""Adjust subcontracting services notification received""';
									|it = 'Rettifica report elaboratore';
									|pl = 'Korekta raportu przetwórcy';
									|tr = 'Alınan fason üretici hizmetleri bildirimini düzeltme'");
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"ProcessingServices",
			Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder);
	EndIf;
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	SubcontractorReport2_5Localization.AddGenerationCommands(GenerationCommands, Parameters);
	
	Documents.ReverseVATAccrual.AddGenerateCommand(GenerationCommands);
	
	Command = Documents.ApplicationForImportationOfGoods.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"ProcessingServices",
			Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder);
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"BusinessOperation",
			Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5);
	EndIf;

EndProcedure

// Adds a command of creation of the document "Report processor".
// 
// Parameters:
// 	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
// 	ValueTableRow, Undefined - description of the command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.SubcontractorReport2_5) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager            = Metadata.Documents.SubcontractorReport2_5.FullName();
		CreateBasedOnCommand.Presentation       = TMCommonUse.ObjectPresentation(Metadata.Documents.SubcontractorReport2_5);
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseProductionByThirdParty2_5";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds a Command to create a document "Report of the processor" based on the "Report to the giver".
// 
// Parameters:
// 	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
// 	ValueTableRow, Undefined - description of the command
//
Function AddCreateCommandBasedOnGiverSReport(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.SubcontractorReport2_5) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager            = Metadata.Documents.SubcontractorReport2_5.FullName();
		CreateBasedOnCommand.Presentation       = TMCommonUse.ObjectPresentation(Metadata.Documents.SubcontractorReport2_5);
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions =
			"UseMultipleCompaniesAndProductionByThirdParty25";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Fills in the list of report commands.
// 
// Parameters:
// 	ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.DocumentFulfillmentStatus.AddStateOfExecutionDocumentCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm,DocumentsList";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithSupplier_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm,DocumentsList";
	EndIf;
	
	ReportCommand = ARAPAccountingServer.IndebtednessToSuppliers_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm,DocumentsList";
	EndIf;
	
	// Job
	ReportCommand = ARAPAccountingServer.IndebtednessToSuppliers_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "Workplace";
		ReportCommand.Importance = "Ordinary";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithSupplier_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "Workplace";
		ReportCommand.Importance = "Ordinary";
		ReportCommand.Order = 2;
	EndIf;
	
	Reports.ProductsCostTree.AddReportCommand(ReportsCommands);
	
	SubcontractorReport2_5Localization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// This function determines the details of the selected document
//
// Parameters:
//	DocumentRef - DocumentRef.SubcontractorReport2_5 - link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.SubcontractOrder AS SubcontractOrder,
	|	DocumentData.ByOrders AS ByOrders,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.CourseNumerator AS Rate,
	|	DocumentData.CourseDenominator AS Repetition
	|
	|FROM
	|	Document.SubcontractorReport2_5 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.Date;
		Organization = Selection.Organization;
		Partner = Selection.Partner;
		Counterparty = Selection.Counterparty;
		Contract = Selection.Contract;
		LineOfBusiness = Selection.LineOfBusiness;
		ARAPObjectSettings = Selection.ARAPObjectSettings;
		ARAPCurrency = Selection.ARAPCurrency;
		ByOrder = Selection.ByOrders;
		DocumentAmount = Selection.DocumentAmount;
		AmountARAP = ?(Selection.Posted, Selection.AmountARAP, 0);
		Rate = Selection.Rate;
		Repetition = Selection.Repetition;
		BusinessOperation = Selection.BusinessOperation;
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		Partner = Catalogs.Partners.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		ByOrder = False;
		DocumentAmount = 0;
		AmountARAP = 0;
		Rate = 1;
		Repetition = 1;
		BusinessOperation = Enums.BusinessTransactions.ProductionByToller2_5;
	EndIf;
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Date", Date); 
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Partner", Partner); 
	AttributesStructure1.Insert("Counterparty", Counterparty); 
	AttributesStructure1.Insert("Contract", Contract); 
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings); 
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency); 
	AttributesStructure1.Insert("BusinessOperation", BusinessOperation); 
	AttributesStructure1.Insert("ByOrder", ByOrder); 
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount); 
	AttributesStructure1.Insert("AmountARAP", AmountARAP);
	AttributesStructure1.Insert("Rate", Rate); 
	AttributesStructure1.Insert("Repetition", Repetition);

	Return AttributesStructure1;

EndFunction

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	DestinationPattern.VisibleSelectionsOnForm.Insert(
		"LineOfBusiness",
		NStr("vi = 'Chỉ ấn định lĩnh vực hoạt động ""%1""';
			|ru = 'Только назначения направления деятельности ""%1""';
			|en = 'The ""%1"" line of business assignments only'; fa = 'The ""%1"" line of business assignments only';
			|it = 'Solo assegnazioni del settore di attività ""%1""';
			|pl = 'Tylko przeznaczenia rodzaju działalności ""%1""';
			|tr = 'Sadece ""%1"" iş kolunun atamaları'"));
	
	#Region ManufacturedProducts
	
	// Needs for products in stock.
	DescriptionOfColumns =
		Catalogs.Assignments.AddColumnDescription_(
			FormTemplate,
			"SecuringOrdersAllWarehouses",
			True,
			"Object.ManufacturedProducts.Purpose");
	
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.TermsOfUse_         = "Object.ManufacturedProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	DescriptionOfColumns.DataPaths.Products     = "Object.ManufacturedProducts.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.ManufacturedProducts.Characteristic";
	
	// The need for work at the calculated cost.
	DescriptionOfColumns =
		Catalogs.Assignments.AddColumnDescription_(
			FormTemplate,
			"FulfillOrdersWithWorks",
			True,
			"Object.ManufacturedProducts.Purpose");
	
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.TermsOfUse_         = "Object.ManufacturedProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	DescriptionOfColumns.DataPaths.Products     = "Object.ManufacturedProducts.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.ManufacturedProducts.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.ManufacturedProducts.Recipient";
	
	#EndRegion
	
	#Region SideAndIntermediateRelease
	
	// The need for returnable waste in the warehouse.
	DescriptionOfColumns =
		Catalogs.Assignments.AddColumnDescription_(
			FormTemplate,
			"SecuringOrdersAllWarehouses",
			True,
			"Object.SideAndIntermediateRelease.Purpose");
	
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.TermsOfUse_         = "Object.SideAndIntermediateRelease.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	DescriptionOfColumns.DataPaths.Products     = "Object.SideAndIntermediateRelease.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.SideAndIntermediateRelease.Characteristic";
	
	// Needs for fixed-cost jobs.
	DescriptionOfColumns =
		Catalogs.Assignments.AddColumnDescription_(
			FormTemplate,
			"FulfillOrdersWithWorks",
			True,
			"Object.SideAndIntermediateRelease.Purpose");
	
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.TermsOfUse_         = "Object.SideAndIntermediateRelease.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	DescriptionOfColumns.DataPaths.Products     = "Object.SideAndIntermediateRelease.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.SideAndIntermediateRelease.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.SideAndIntermediateRelease.Recipient";
	
	#EndRegion
	
	#Region MaterialsAndWorks
	
	// The remnants of the transferred goods
	DescriptionOfColumns =
		Catalogs.Assignments.AddColumnDescription_(
			FormTemplate,
			"GoodsTransferredToCustodians",
			True,
			"Object.MaterialsAndWorks.Purpose");
	
	DescriptionOfColumns.Columns.FindByValue("Passed").Check = True;
	
	DescriptionOfColumns.TermsOfUse_       = "Object.MaterialsAndWorks.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	DescriptionOfColumns.DataPaths.Organization    = "Object.Organization";
	DescriptionOfColumns.DataPaths.Contract        = "Object.Contract";
	DescriptionOfColumns.DataPaths.Products   = "Object.MaterialsAndWorks.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.MaterialsAndWorks.Characteristic";
	
	// The remains of the works
	DescriptionOfColumns =
		Catalogs.Assignments.AddColumnDescription_(
			FormTemplate,
			"MaterialsAndWorksInProduction",
			True,
			"Object.MaterialsAndWorks.Purpose");
	
	DescriptionOfColumns.Columns.FindByValue("Count").Check = True;
	
	DescriptionOfColumns.TermsOfUse_       = "Object.MaterialsAndWorks.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	DescriptionOfColumns.DataPaths.Organization    = "Object.Organization";
	DescriptionOfColumns.DataPaths.Department  = "Object.Department";
	DescriptionOfColumns.DataPaths.Products   = "Object.MaterialsAndWorks.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.MaterialsAndWorks.Characteristic";
	
	#EndRegion
	
	Return FormTemplate;
	
EndFunction

// Returns parameters for selecting specifications for the items specified in the document.
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters of the choice specs.
//
// Returns:
//   Structure - A structure that overrides the defaults set in the management function of the Client Server's data items.Parameterselectionspecifications().
//
Function BOMSelectionParameters(Object) Export
	
	BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	BOMSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Assembly);
	BOMSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	ChoiceParameterLinks = New Structure(ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
	
	ChoiceParameterLinks.Products            = "Object.ManufacturedProducts.Products";
	ChoiceParameterLinks.Characteristic          = "Object.ManufacturedProducts.Characteristic";
	ChoiceParameterLinks.ProductionStart      = "Object.Date";
	ChoiceParameterLinks.LineOfBusiness = "Object.LineOfBusiness";
	
	BOMSelectionParameters.ChoiceParameterLinks.Insert("Object.ManufacturedProducts.BillOfMaterials", ChoiceParameterLinks);
	
	Return BOMSelectionParameters;
	
EndFunction

// The names of the details, the values of which depend on the selection parameters spec
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSelectingSpecifications() Export
	
	AttributesNames = "";
	Return AttributesNames;
	
EndFunction

// Returns the parameters of the distribution of the costs of the output product.
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters of cost allocation.
//
// Returns:
//  See ProductionClientServer.CostAllocationParametersForOutputProducts
//
Function CostAllocationParameters(Object) Export
	
	CostAllocationParameters = ProductionClientServer.CostAllocationParametersForOutputProducts(
		"ManufacturedProducts",
		Object.MethodOfAllocatingFinishedProductCosts);
	
	If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.NoGrouping
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOM
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments Then
		
		CostAllocationParameters.CalculateShareCostPercentageField = True;
		CostAllocationParameters.ThisFlagIndicatesThatThereAreFillInErrors = True;
		CostAllocationParameters.CalculateShareOfCostAttributeRequired = True;
		CostAllocationParameters.ParametersForFillingInCostShares.Date = 
									?(CommonClientServer.HasAttributeOrObjectProperty(Object, "Date"), 
									Object.Date, 
									Date("00010101"));
		CostAllocationParameters.ParametersForFillingInCostShares.Currency = 
									?(CommonClientServer.HasAttributeOrObjectProperty(Object, "Currency"), 
									Object.Currency, 
									Catalogs.Currencies.EmptyRef());
		
		CostAllocationParameters.CostGroupingField              = "CostGroupNumber";
		CostAllocationParameters.CostGroupingPresentationField = "ExpenseGroup";
		If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
			CostAllocationParameters.FieldNameMethodOfCostAllocationForOutputProducts = "MethodOfAllocatingFinishedProductCosts";
		EndIf;
	EndIf;
	
	Return CostAllocationParameters;
	
EndFunction

// Is product input available at the calculated cost
//
// Parameters:
//   Object - Structure - the structure of the values of the details object.
//
// Returns:
//  Boolean - is it possible to edit the tabular part of the "Output Products".
//
Function ProductionEditingIsAvailable(Object) Export
	
	EditProducts = True;
	
	If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	TableServices.ProductionStage AS ProductionStage
		|INTO TTServices
		|FROM
		|	&TableServices AS TableServices
		|
		|WHERE
		|	NOT TableServices.ProductionStage = VALUE(Document.ProductionStage2_2.EmptyRef)
		|
		|INDEX BY
		|	ProductionStage
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTServices.ProductionStage AS ProductionStage
		|FROM
		|	TTServices AS TTServices
		|
		|	INNER JOIN Document.ProductionStage2_2 AS ReleasingStages
		|	ON ReleasingStages.Ref = TTServices.ProductionStage
		|	AND ReleasingStages.NextStageNo = 0
		|";
		
		Query.SetParameter("TableServices", Object.Services.Unload());
		EditProducts = Not Query.Execute().IsEmpty();
		
	EndIf;
	
	Return EditProducts;
	
EndFunction
// Creates a representation of the metadata object in the main language.
// 
// Returns:
//	String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	ObjectPresentation = NStr(
		"vi = 'Bảng kê hàng hóa của người nhận gia công';
		|ru = 'Отчет переработчика';
		|en = 'Subcontracting services notification received'; fa = 'اعلامیه خدمات پیمانکاری فرعی دریافت‌شده';
		|it = 'Report subfornitore';
		|pl = 'Raport przetwórcy';
		|tr = 'Alınan fason üretici hizmetleri bildirimi'",
		DefaultLanguageCode);
		
	Return ObjectPresentation;
	
EndFunction

// Returns a structure with the name of the tabular parts of the document that store information about the goods.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* ManufacturedProducts - ValueTable, TabularSection, Undefined - data about the output items of the document.
//		* SideAndIntermediateRelease - ValueTable, TabularSection, Undefined - data on the by-products of the document.
//		* MaterialsAndWorks - ValueTable, TabularSection, Undefined - data about the materials of the document.
//		* Services - ValueTable, TabularSection, Undefined - data about the document's services.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure;
	DocumentTables.Insert("ManufacturedProducts");
	DocumentTables.Insert("SideAndIntermediateRelease");
	DocumentTables.Insert("MaterialsAndWorks");
	DocumentTables.Insert("Services");
	
	Return DocumentTables;
	
EndFunction

#EndRegion

#Region CostGroups

// Updates the cost group table
// 
// Parameters:
// 	Object - DocumentObject.SubcontractorReport2_5, Structure, FormDataStructure - description of the object
// 	CostGroups - See CostGroupTable
// 	NumberOfCostGroups - Number
Procedure UpdateCostGroups(Object, CostGroups, NumberOfCostGroups) Export
	
	If Object.ByOrders Then
		
		If ValueIsFilled(Object.SubcontractOrder) Then
			
			OrderDetailsForProcessor =
				Common.ObjectAttributesValues(
					Object.SubcontractOrder,
					"GroupCosts, References, ManufacturedProducts, SideAndIntermediateRelease,
					|MaximumNumberOfCostGroup, SeparationOfMaterialsByProductPurpose, Purpose");
			
			Documents.SubcontractOrder2_5.UpdateCostGroups(OrderDetailsForProcessor, CostGroups, NumberOfCostGroups);
			
		EndIf;
		
	Else
		
		FieldList =
			ProcessingByThirdPartiesClientServer.ListOfCostGroupFieldsInProcessorSReport(Object.GroupCosts);
		
		TextOfSelectionField = ProcessingByThirdPartiesClientServer.RequestTextByCostGroupFields("DataTable", FieldList);
		
		Query = New Query;
		Query.Text =
		"SELECT DISTINCT 
		|	DataTable.CostGroupNumber
		|	,&TextOfSelectionField
		|INTO TT_CostGroups
		|FROM
		|	&DataTable AS DataTable
		|;
		|
		|/////////////////////////////////////////////////////
		|SELECT
		|	DataTable.CostGroupNumber
		|	,&TextOfSelectionField
		|FROM
		|	TT_CostGroups AS DataTable
		|;
		|
		|/////////////////////////////////////////////////////
		|SELECT
		|	MAX(TT_CostGroups.CostGroupNumber) AS CostGroupNumber
		|FROM
		|	TT_CostGroups AS TT_CostGroups";
		
		Query.Text = StrReplace(Query.Text, ",&TextOfSelectionField", TextOfSelectionField);
		Query.SetParameter("DataTable", Object.ManufacturedProducts.Unload());
		
		Result = Query.ExecuteBatch();
		
		If TypeOf(CostGroups) = Type("ValueTable") Then
			For Each CurRow In Result[1].Unload() Do
				FillPropertyValues(CostGroups.Add(), CurRow);
			EndDo;
		Else
			CostGroups.Load(Result[1].Unload());
		EndIf;
		
		NumberOfCostGroups = CostGroups.Count();
		
		If Not Result[2].IsEmpty() Then
			Selection = Result[2].Select();
			Selection.Next();
			Object.MaximumNumberOfCostGroup = Selection.CostGroupNumber;
		EndIf;
		
		For Each CurGroup In CostGroups Do
			FillInServiceDetailsOfCostGroup(Object, CostGroups, CurGroup);
		EndDo;
		
	EndIf;
	
EndProcedure

// Fills in the service details
// 
// Parameters:
// 	Object - DocumentObject.SubcontractorReport2_5, Structure - object data
// 	CostGroups - ValueTable
// 	CostGroupDescription - Structure
//
Procedure FillInServiceDetailsOfCostGroup(Object, CostGroups, CostGroupDescription) Export
	DescriptionOfCostGroupBeforeChange = Common.CopyRecursive(CostGroupDescription);
	
	If TypeOf(CostGroupDescription) = Type("Structure")
		And Not TMCommonUseClientServer.StructuresAreEqual(DescriptionOfCostGroupBeforeChange, CostGroupDescription) Then
		UpdateCostGroup(CostGroups, CostGroupDescription);
	EndIf;
	Return;
	
EndProcedure

// Fills in the service details
// 
// Parameters:
// 	Object - Structure - object data
// 	CostGroups - ValueTable
// 	CostGroupDescription - Structure
//
Procedure FillInDependentServiceDetailsOfCostGroup(Object, CostGroups, CostGroupDescription) Export
	
	If CostGroupDescription.CostGroupNumber = 0 Then
		Return;
	EndIf;
	
	DescriptionOfCostGroupBeforeChange = Common.CopyRecursive(CostGroupDescription);
	CostGroupDescription.ThereIsImportedProduct = ThereIsImportedProduct(Object, CostGroupDescription.CostGroupNumber);
	
	If TypeOf(CostGroupDescription) = Type("Structure")
		And Not TMCommonUseClientServer.StructuresAreEqual(DescriptionOfCostGroupBeforeChange, CostGroupDescription) Then
		UpdateCostGroup(CostGroups, CostGroupDescription);
	EndIf;
	
EndProcedure

// Cost Group Table Constructor
// 
// Returns:
// 	ValueTable:
// * CostGroupNumber - Number
// * ExpenseGroup - String
// * BillOfMaterials - CatalogRef.BillsOfMaterials
// * Purpose - CatalogRef.Assignments
// * Products - CatalogRef.Products
// * Characteristic - CatalogRef.ItemsCharacteristics
// * ReferenceOrder - DocumentRef.ProductionStage2_2
// * MethodOfAllocatingFinishedProductCosts - EnumRef.MethodsOfCostAllocatingOnProductCosts
// * AssignmentSemiFinishedProducts - CatalogRef.Assignments
// * AssignmentMaterials - CatalogRef.Assignments
// * ProductTableName - String
// * AllProductLinesAreCancelled - Boolean
//
Function CostGroupTable() Export
	
	CostGroups = New ValueTable;
	CostGroups.Columns.Add("CostGroupNumber",                New TypeDescription("Number"));
	CostGroups.Columns.Add("ExpenseGroup",                     New TypeDescription("String"));
	CostGroups.Columns.Add("BillOfMaterials",                     New TypeDescription("CatalogRef.BillsOfMaterials"));
	CostGroups.Columns.Add("Purpose",                       New TypeDescription("CatalogRef.Assignments"));
	CostGroups.Columns.Add("Products",                     New TypeDescription("CatalogRef.Products"));
	CostGroups.Columns.Add("Characteristic",                   New TypeDescription("CatalogRef.ItemsCharacteristics"));
	CostGroups.Columns.Add("Series",                            New TypeDescription("CatalogRef.ItemsBatches"));
	CostGroups.Columns.Add("ReferenceOrder",                     New TypeDescription("DocumentRef.ProductionStage2_2"));
	CostGroups.Columns.Add("Stage",                             New TypeDescription("CatalogRef.ProductionStages"));
	CostGroups.Columns.Add("ParametersForFillingAssignments",    New TypeDescription("Structure"));
	CostGroups.Columns.Add("AppointmentSelectionList",           New TypeDescription("ValueList"));
	CostGroups.Columns.Add("TollManufacturing", New TypeDescription("Boolean"));
	CostGroups.Columns.Add(
		"MethodOfAllocatingFinishedProductCosts",
		New TypeDescription("EnumRef.MethodsOfCostAllocatingOnProductCosts"));
	
	CostGroups.Columns.Add("SupplyAssignment",    New TypeDescription("CatalogRef.Assignments"));
	CostGroups.Columns.Add("ProductTableName",        New TypeDescription("String"));
	CostGroups.Columns.Add("AllProductLinesAreCancelled", New TypeDescription("Boolean"));
	CostGroups.Columns.Add("ThereIsImportedProduct",     New TypeDescription("Boolean"));
	
	Return CostGroups;
	
EndFunction

#EndRegion

#Region SetOfSeries

//Names of the details that the parameters for specifying the series depend on.
//
// Returns:
//	String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Date";
	
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//	Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//	Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = New Structure;
	
	UseCostAccountingByBatches =
		GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure());
	UseItemsBatch  =
		GetFunctionalOption("UseItemsBatchWarehouse", New Structure());
	
	#Region ManufacturedProducts
	
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	ParametersForSpecifyingTSSeries.FullObjectName = "Document.SubcontractorReport2_5";
	
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches = UseCostAccountingByBatches;
	ParametersForSpecifyingTSSeries.UseItemsBatch  = UseItemsBatch;
	
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.ManufactureOfProducts);
	
	ParametersForSpecifyingTSSeries.Date         = Object.Date;
	ParametersForSpecifyingTSSeries.WarehouseFieldName = "Contract";
	ParametersForSpecifyingTSSeries.NameTSGoods  = "ManufacturedProducts";
	ParametersForSpecifyingTSSeries.TSSeriesName   = "ManufacturedProducts";
	ParametersForSpecifyingTSSeries.ThisIsAnInvoice = True;
	ParametersForSpecifyingTSSeries.RegisterSeries = True;
	
	ParametersForSpecifyingTSSeries.LinkFields.Add("Purpose");
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	
	SeriesSpecificationParameters.Insert("ManufacturedProducts", ParametersForSpecifyingTSSeries);
	
	#EndRegion
	
	#Region SideAndIntermediateRelease
	
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	ParametersForSpecifyingTSSeries.FullObjectName = "Document.SubcontractorReport2_5";
	
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches = UseCostAccountingByBatches;
	ParametersForSpecifyingTSSeries.UseItemsBatch  = UseItemsBatch;
	
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.ManufactureOfProducts);
	
	ParametersForSpecifyingTSSeries.Date         = Object.Date;
	ParametersForSpecifyingTSSeries.WarehouseFieldName = "Contract";
	ParametersForSpecifyingTSSeries.NameTSGoods  = "SideAndIntermediateRelease";
	ParametersForSpecifyingTSSeries.TSSeriesName   = "SideAndIntermediateRelease";
	ParametersForSpecifyingTSSeries.ThisIsAnInvoice = True;
	ParametersForSpecifyingTSSeries.RegisterSeries = True;
	
	ParametersForSpecifyingTSSeries.LinkFields.Add("Purpose");
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	
	SeriesSpecificationParameters.Insert("SideAndIntermediateRelease", ParametersForSpecifyingTSSeries);
	
	#EndRegion
	
	#Region MaterialsAndWorks
	
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	ParametersForSpecifyingTSSeries.FullObjectName = "Document.SubcontractorReport2_5";
	
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches = UseCostAccountingByBatches;
	ParametersForSpecifyingTSSeries.UseItemsBatch  = UseItemsBatch;
	
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.MovementInFinancialAccounting);
	
	ParametersForSpecifyingTSSeries.Date         = Object.Date;
	ParametersForSpecifyingTSSeries.WarehouseFieldName = "Contract";
	ParametersForSpecifyingTSSeries.NameTSGoods  = "MaterialsAndWorks";
	ParametersForSpecifyingTSSeries.TSSeriesName   = "MaterialsAndWorks";
	ParametersForSpecifyingTSSeries.ThisIsAnInvoice = True;
	
	ParametersForSpecifyingTSSeries.LinkFields.Add("Purpose");
	ParametersForSpecifyingTSSeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	
	SeriesSpecificationParameters.Insert("MaterialsAndWorks", ParametersForSpecifyingTSSeries);
	
	#EndRegion
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses of specifying series.
//
// Parameters:
//	SeriesSpecificationParameters - Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
// Returns:
//	String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.Products        AS Products,
	|	Goods.Characteristic      AS Characteristic,
	|	Goods.Purpose          AS Purpose,
	|	Goods.Series               AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Count          AS Count
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	Goods.Products      AS Products,
	|	Goods.Characteristic    AS Characteristic,
	|	Goods.Purpose        AS Purpose,
	|	Goods.Series             AS Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	SUM(Goods.Count) AS Count
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE
	|			CASE
	|				WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN
	|						CASE
	|							WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.SeriesAccountingOfGoodsTransferredToSubcontractor
	|								THEN
	|									CASE
	|										WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 18
	|										ELSE 17
	|									END
	|								ELSE 0
	|						END
	|					ELSE 0
	|			END
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	Statuses.LineNumber         AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

#EndRegion

#Region ArticleSelectionAndAnalytics

// Parameters for selecting articles and analytics.
// 
// Returns:
//  Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ArticleSelectionOptions = New Array;
	
	// ManufacturedProducts
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.DataPath					= "Object.ManufacturedProducts";
	ChoiceParameters.AssetRef						= "ExpenseItem";
	ChoiceParameters.ArticleType					= "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem			= True;
	ChoiceParameters.DimensionOfExpenses			= "DimensionOfExpenses";
	ChoiceParameters.SelectingItemOfAssetsLiabilities	= True;
	ChoiceParameters.AssetsLiabilitiesDimension	= "AssetsLiabilitiesDimension";
	
	FormItems = ChoiceParameters.FormItems;
	FormItems.AssetRef.Add("ManufacturedProductsExpenseItem");
	FormItems.DimensionOfExpenses.Add("ManufacturedProductsDimensionOfExpenses");
	FormItems.AssetsLiabilitiesDimension.Add("ManufacturedProductsAssetsLiabilitiesDimension");
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	
	ArticleSelectionOptions.Add(ChoiceParameters);
	
	// Returnable waste
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.DataPath					= "Object.SideAndIntermediateRelease";
	ChoiceParameters.AssetRef						= "ExpenseItem";
	ChoiceParameters.ArticleType					= "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem			= True;
	ChoiceParameters.DimensionOfExpenses			= "DimensionOfExpenses";
	ChoiceParameters.SelectingItemOfAssetsLiabilities	= True;
	ChoiceParameters.AssetsLiabilitiesDimension	= "AssetsLiabilitiesDimension";
	
	FormItems = ChoiceParameters.FormItems;
	FormItems.AssetRef.Add("SideAndIntermediateReleaseExpenseItem");
	FormItems.DimensionOfExpenses.Add("SideAndIntermediateReleaseDimensionOfExpenses");
	FormItems.AssetsLiabilitiesDimension.Add("SideAndIntermediateReleaseAssetsLiabilitiesDimension");
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	
	ArticleSelectionOptions.Add(ChoiceParameters);
	
	Return ArticleSelectionOptions;
	
EndFunction

#EndRegion

#Region GLAccountSettings

// Returns parameters for setting up accounting accounts in the document.
// 
// Returns:
// 	Array of See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_() Export
	
	SettingsParameters = New Array;
	
	#Region ManufacturedProducts
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.AvailabilityByOperation	= True;
	SetupParameters.ArticleType				= "ArticleType";
	SetupParameters.DataPath				= "Object.ManufacturedProducts";
	
	SetupParameters.FormItems.Add("ManufacturedProductsTransactionRecordingPresentation");
	
	SetupParameters.ConditionsForAvailabilityOfAccountingAccountInLines.Insert("ToExpenseAs", True);
	
	SettingsParameters.Add(SetupParameters);
	
	#EndRegion
	
	#Region SideAndIntermediateRelease
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.AvailabilityByOperation	= True;
	SetupParameters.ArticleType				= "ArticleType";
	SetupParameters.DataPath				= "Object.SideAndIntermediateRelease";
	
	SetupParameters.FormItems.Add("SideAndIntermediateReleaseTransactionRecordingPresentation");
	
	SetupParameters.ConditionsForAvailabilityOfAccountingAccountInLines.Insert("ToExpenseAs", True);
	
	SettingsParameters.Add(SetupParameters);
	
	#EndRegion
	
	Return SettingsParameters;
	
EndFunction

#EndRegion

#Region VATAccounting

// Initializes the parameters for filling in the VAT activity type
//
// Parameters:
//  Object		- DocumentObject.SubcontractorReport2_5, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization							= Object.Organization;
	FillParameters.Date								= Object.Date;
	FillParameters.Contract								= Object.Contract;
	FillParameters.LineOfBusiness				= Object.LineOfBusiness;
	FillParameters.OutputOfProductsAndWorks				= True;
	
	Return FillParameters;
	
EndFunction

// Returns the structure of parameters for filling in the purchase VAT tax.
//
// Parameters:
//  Object - DocumentObject.SubcontractorReport2_5, DocumentRef.SubcontractorReport2_5, FormDataStructure - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export

	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	
	If TypeOf(Object) = Type("DocumentObject.SubcontractorReport2_5")
		Or TypeOf(Object) = Type("FormDataStructure") Then
		ObjectData = Object;
	ElsIf TypeOf(Object) = Type("DocumentRef.SubcontractorReport2_5") Then
		ObjectData = Common.ObjectAttributesValues(Object, "Counterparty,Contract,BusinessOperation,Date");
	EndIf;
	
	FillParameters.Counterparty           = ObjectData.Counterparty;
	FillParameters.Contract              = ObjectData.Contract;
	FillParameters.Period               = ObjectData.Date;
	
	If ObjectData.BusinessOperation = Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5 Then
		FillParameters.ImportOfGoodsFromCustomsUnion = True;
	Else
		FillParameters.AcquisitionOfWorks    = True;
	EndIf;

	Return FillParameters;
	
EndFunction

// Initializes parameters for registering invoices (received)
//
// Parameters:
//  Object		- DocumentObject.SubcontractorReport2_5, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived
//
Function ParametersForRegisteringInvoicesReceived(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	
	RegistrationParameters.Ref				= Object.Ref;
	RegistrationParameters.Date				= Object.Date;
	RegistrationParameters.Organization		= Object.Organization;
	RegistrationParameters.Counterparty			= Object.Counterparty;
	RegistrationParameters.VATTaxation	= Object.VATTaxation;
	RegistrationParameters.PurchaseOfGoodsWorksServices = True;
	RegistrationParameters.ImportOfGoodsFromCustomsUnion = (Object.BusinessOperation = Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5
															And Object.ProcessingServices = Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder);
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

#Region NameOfIncomingDocuments

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'Bảng kê hàng hóa của người nhận gia công';
							|ru = 'Отчет переработчика';
							|en = 'Subcontracting services notification received'; fa = 'اعلامیه خدمات پیمانکاری فرعی دریافت‌شده';
							|it = 'Report subfornitore';
							|pl = 'Raport przetwórcy';
							|tr = 'Alınan fason üretici hizmetleri bildirimi'"));
	
	SubcontractorReport2_5Localization.AddNamesOfIncomingDocuments(ArrayOfNames);
	
	Return ArrayOfNames
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN Document.SubcontractorReport2_5.ManufacturedProducts AS ManufacturedProducts
	|	ON ManufacturedProducts.Ref = ThisList.Ref
	|
	|LEFT JOIN Document.SubcontractorReport2_5.SideAndIntermediateRelease AS SideAndIntermediateRelease
	|	ON SideAndIntermediateRelease.Ref = ThisList.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Department)
	|	AND ForAllRows(
	|			ValueAllowed(ManufacturedProducts.Recipient)
	|			OR ValueAllowed(ManufacturedProducts.Recipient, EmptyRef AS TRUE, Null AS TRUE))
	|	AND ForAllRows(
	|			ValueAllowed(SideAndIntermediateRelease.Recipient)
	|			OR ValueAllowed(SideAndIntermediateRelease.Recipient, EmptyRef AS TRUE, Null AS TRUE))";
	
EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region ARAPAccounting

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"ByOrders,
			|Ref");
		ByOrders         = StructureFillingData.ByOrders;
		ThereAreAdjustingEntries = False;
		PurchasesServer.CheckForAdjustmentsAndInvoices(StructureFillingData.Ref, StructureFillingData.Ref, ThereAreAdjustingEntries, False);
	ElsIf FillingData = Undefined Then
		ByOrders         = False;
		ThereAreAdjustingEntries = False;
	Else
		ByOrders         = FillingData.ByOrders;
		ThereAreAdjustingEntries = False;
		PurchasesServer.CheckForAdjustmentsAndInvoices(FillingData.Ref, FillingData.Ref, ThereAreAdjustingEntries, False);
	EndIf;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                    = True;
	ParametersStructure.PaymentType_                          = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	ParametersStructure.ChangesPaymentPlan                   = True;
	ParametersStructure.ChangesCalculationsByString               = True;
	ParametersStructure.ModifiesDeliveryShipmentPlan         = True;
	
	ParametersStructure.ARAPCurrency                 = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP                  = "Object.AmountARAP";
	
	ParametersStructure.CourseNumerator                        = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                      = "Object.CourseDenominator";
	
	ParametersStructure.PathToTSData                        = "Object.Services";
	ParametersStructure.PropsNameTSOrder                  = "SubcontractOrder";
	ParametersStructure.PathToTSDataPaymentDecryption      = "Object.ARAPDetails";
	
	ParametersStructure.Terms                           = "";
	ParametersStructure.CashAccount                                = "";
	ParametersStructure.Manager                             = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber              = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate               = "Object.IncomingDocumentDate";
	ParametersStructure.SourceDocumentName      = "Object.ExternalDocumentName";
	
	ParametersStructure.InvoiceForOrders                   = "Object.ByOrders";
	ParametersStructure.OrderBase                       = "Object.SubcontractOrder";
	
	ParametersStructure.FormItems.LabelCurrencies          = "LabelCurrencies";
	ParametersStructure.FormItems.InscriptionStages           = "DecorationPaymentSteps";
	ParametersStructure.FormItems.InscriptionCalculations         = "DecorationSettlementState";
	ParametersStructure.FormItems.PaymentSettlement            = "CreditPaymentForm";
	ParametersStructure.FormItems.AmountOfTSSettlements  = "ServicesAmountARAP";
	ParametersStructure.FormItems.FinancialAccountingGroup  = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	ParametersStructure.PathToTSDataPaymentSteps             = "Object.PaymentScheduleSteps";
	ParametersStructure.PaymentStepsText                   = "Form.PaymentStepsText";
	ParametersStructure.DocumentAmountForm                  = "Form.Object.DocumentAmount";
	ParametersStructure.InvoiceForSeveralOrdersIsPossible = False;
	ParametersStructure.SourceOfAmountsTabularPart           = True;
	
	ParametersStructure.CurrencyAndExchangeRateDocumentViewOnly   = ThereAreAdjustingEntries;
	ParametersStructure.DocumentCurrencyViewOnly        = ByOrders;
	ParametersStructure.MutualSettlementsCurrencyViewOnly   = ByOrders;
	
	ParametersStructure.ARAPObject                       = "Object.Services.ARAPObject";
	
	Return ParametersStructure;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Clear();
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("Date");
	Fields.Add("Number");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "SubcontractorReport2_5");
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Document processing parameters when changing the direction of activity
// 
// Parameters:
// 	Form - ClientApplicationForm
// Returns:
// 	See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
//
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "ManufacturedProducts,SideAndIntermediateRelease";
	
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType,RowCode");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("ManufacturedProducts", TableOfConditions);
	DocumentProcessingProcedure.StringProcessingConditions.Insert("SideAndIntermediateRelease", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

#Region Checks

// The request text of the document's cost group.
// 
// Returns:
//  String - Request Text For The Document's Cost Group
Function RequestTextForDocumentSCostGroup() Export
	
	QueryText =
	"SELECT DISTINCT
	|	TabularSection.CostGroupNumber AS CostGroupNumber
	|	,TabularSection.ProductionStage AS ProductionStage
	|INTO CostGroupNumbers
	|FROM
	|	(SELECT
	|		TabularSection.CostGroupNumber AS CostGroupNumber
	|		,TabularSection.ProductionStage AS ProductionStage
	|	FROM
	|		ManufacturedProducts AS TabularSection
	|	WHERE
	|		NOT TabularSection.CostGroupNumber = 0
	|		AND ISNULL(TabularSection.ProductionStage.NextStageNo, 0) = 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TabularSection.CostGroupNumber AS CostGroupNumber,
	|		TabularSection.ProductionStage AS ProductionStage
	|	FROM
	|		SideAndIntermediateRelease AS TabularSection
	|	WHERE
	|		NOT TabularSection.CostGroupNumber = 0
	|		AND NOT ISNULL(TabularSection.ProductionStage.NextStageNo, 0) = 0
	|	) AS TabularSection
	|
	|INDEX BY
	|	CostGroupNumber
	|";
	
	Return QueryText;
	
EndFunction

// The text of the request "Imported document materials".
// 
// Returns:
//  String - Request Text TT Imported Document Materials
Function QueryTextTTImportedDocumentMaterials() Export
	
	QueryText =
	"SELECT
	|	TabularSection.CostGroupNumber		AS CostGroupNumber,
	|	TabularSection.Products				AS Products,
	|	TabularSection.Characteristic			AS Characteristic,
	|	MAX(CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN FALSE
	|		ELSE ISNULL(Goods.TracedGoods, FALSE)
	|	END)									AS Traceable,
	|	MAX(TabularSection.Main)		AS Main
	|INTO TTImportedDocumentMaterials
	|FROM
	|	MaterialsAndWorks AS TabularSection
	|	
	|	LEFT JOIN Catalog.Products AS Goods
	|	ON TabularSection.Products = Goods.Ref
	|
	|WHERE
	|	ISNULL(Goods.KeepRecordsByCCD, FALSE)
	|	AND ISNULL(Goods.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) IN
	|			(VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.Work_5),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	TabularSection.CostGroupNumber,
	|	TabularSection.Products,
	|	TabularSection.Characteristic
	|
	|INDEX BY
	|	CostGroupNumber,
	|	Products,
	|	Characteristic
	|";
	
	Return QueryText;
	
EndFunction

// The text of the check is "Not the correct type of value".
// 
// Returns:
//  String - The Validation Text Is Not The Correct Value Type
Function ValidationTextIsNotCorrectValueType() Export
	
	QueryText = 
	"SELECT
	|	&TableNameOutputProducts       AS TableName,
	|	&SynonymForTSOutputProducts        AS TSSynonym,
	|	TabularSection.LineNumber       AS LineNumber,
	|	TabularSection.CostGroupNumber AS CostGroupNumber,
	|	""IncorrectCostType""     AS TypeOfVerification
	|FROM
	|	ManufacturedProducts AS TabularSection
	|WHERE
	|	NOT CAST(TabularSection.ProductionStage AS Document.ProductionStage2_2).NextStageNo = 0
	|";
	
	Return QueryText;
	
EndFunction

// The text of the check "No imported material specified".
// 
// Returns:
//  String - Verification Text Omitted Imported Material
Function VerificationTextOmittedImportedMaterial() Export
	
	QueryText =
	"SELECT DISTINCT
	|	&NameOfMaterialsAndWorksTable					AS TableName,
	|	&SynonymTSMaterialsAndWorks					AS TSSynonym,
	|	0											AS LineNumber,
	|	ImportedProductsOfDocument.CostGroupNumber	AS CostGroupNumber,
	|	""ImportedMaterialNotSpecified""				AS TypeOfVerification
	|FROM
	|	TTImportedProducts AS ImportedProductsOfDocument
	|
	|WHERE
	|	&UseImportedGoods
	|	AND NOT ImportedProductsOfDocument.Traceable
	|	AND NOT ImportedProductsOfDocument.CostGroupNumber IN
	|			(SELECT
	|				ImportedDocumentMaterials.CostGroupNumber
	|			FROM
	|				TTImportedDocumentMaterials AS ImportedDocumentMaterials
	|			WHERE
	|				ImportedDocumentMaterials.Main)
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//    * Name            - String - the unique name of the shared prop.
//    * Presentation  - String - representation of general props.
//    * Type            - Type    - Type of props. By default, a string.
//    * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//    * Name            - String - the unique name of the attachment.
//    * Presentation  - String - representation of the option.
//    * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map - list of details used in the template.
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map - list of common banking details used in the template.
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map - the values of the requisites
//      * Key     - String - name of the attachment in the template;
//      * Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", "Reverse Address".
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Posting

#Region InitializationOfEvent

// Additional data sources for movements.
// 
// Parameters:
//  RegisterName - String
// 
// Returns:
//  Map - Additional data sources for movements
Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	SubcontractorReport.Ref                  AS Ref,
	|	SubcontractorReport.Date                    AS Period,
	|	SubcontractorReport.Number                   AS Number,
	|	SubcontractorReport.Currency                  AS Currency,
	|	SubcontractorReport.Partner                 AS Partner,
	|	SubcontractorReport.Counterparty              AS Counterparty,
	|	SubcontractorReport.Organization             AS Organization,
	|	SubcontractorReport.Manager                AS Manager,
	|	SubcontractorReport.Author                   AS Author,
	|	SubcontractorReport.Comment             AS Comment,
	|	SubcontractorReport.Department           AS Department,
	|	SubcontractorReport.Department.OptionOfAssignedAccountingOfGoods 		  AS OptionOfAssignedAccountingOfGoods,
	|	SubcontractorReport.SalesOpportunity 				   AS SalesOpportunity,
	|	ISNULL(SubcontractorReport.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
	|	SubcontractorReport.BusinessOperation   AS BusinessOperation,
	|	SubcontractorReport.Contract                 AS Contract,
	|	PRESENTATION(SubcontractorReport.Contract)  AS ContractPresentation,
	|	SubcontractorReport.PaymentMethod             AS PaymentMethod,
	|	SubcontractorReport.ARAPCurrency    AS ARAPCurrency,
	|	SubcontractorReport.ByOrders               AS ByOrders,
	|	SubcontractorReport.SubcontractOrder      AS SubcontractOrder,
	|	SubcontractorReport.ExternalDocumentName AS ExternalDocumentName,
	|	SubcontractorReport.IncomingDocumentDate  AS IncomingDocumentDate,
	|	SubcontractorReport.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	SubcontractorReport.Posted                AS Posted,
	|	SubcontractorReport.DeletionMark         AS DeletionMark,
	|	DocSubcontractOrder.Currency               AS OrderCurrency,
	|
	|	VALUE(Enum.InventoryTypes.OperationService)  AS InventoryType,
	|
	|	SubcontractorReport.PurchaseForActivity  AS PurchaseForActivity,
	|	UNDEFINED                               AS Series,
	|	SubcontractorReport.Department           AS Warehouse,
	|	SubcontractorReport.GroupCosts       AS GroupCosts,
	|
	|	SubcontractorReport.DocumentAmount          AS DocumentAmount,
	|
	|	CASE WHEN SubcontractorReport.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END                                      AS ContractSettlements,
	|
	|	CASE WHEN SubcontractorReport.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END                                      AS CalculationsOnInvoices,
	|	SubcontractorReport.LineOfBusiness AS LineOfBusiness,
	|	ISNULL(SubcontractorReport.LineOfBusiness.CostAccounting, FALSE) AS AccountingForLBCosts,
	|	ISNULL(SubcontractorReport.LineOfBusiness.VendorARAP, FALSE) AS AccountingForSettlementsWithSuppliersUnderLB,
	|	ISNULL(SubcontractorReport.LineOfBusiness.Purpose,
	|		VALUE(Catalog.Assignments.EmptyRef)) AS Purpose,
	|	
	|	ISNULL(SubcontractorReport.Contract.ExecutionScheduleIsSpecified, FALSE) AS ExecutionScheduleInContract,
	|	
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
	|	UNDEFINED AS AdjustmentPeriod_
	|
	|FROM
	|	Document.SubcontractorReport2_5 AS SubcontractorReport
	|	
	|	LEFT JOIN Document.SubcontractOrder2_5 AS DocSubcontractOrder
	|	ON DocSubcontractOrder.Ref = SubcontractorReport.SubcontractOrder
	|	
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|	ON SubcontractorReport.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|
	|WHERE
	|	SubcontractorReport.Ref = &Ref
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("EmptyLinkArticle",                  Catalogs.ProductCostElements.EmptyRef());
	Query.SetParameter("EmptyLinkSeries",                   Catalogs.ItemsBatches.EmptyRef());
	Query.SetParameter("EmptyDestinationLink",              Catalogs.Assignments.EmptyRef());
	Query.SetParameter("AnalyticalAccountingByProductsGroups", GetFunctionalOption("AnalyticalAccountingByProductsGroups"));
	Query.SetParameter("MetadataIdentifier",             Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("IdApplicationForImportOfGoods", Common.MetadataObjectID("Document.ApplicationForImportationOfGoods"));
	Query.SetParameter("HouseholdOperationsProcessingInEAEUCountries",  Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5);
	Query.SetParameter("ManagementAccountingCurrency",          SettingsValueCached.ManagementAccountingCurrency());
	
	ContractInformation = Undefined;
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.ContractPresentation);
	EndIf;
	Query.SetParameter("ContractInformation", ContractInformation);
	
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
								GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure InitializeProductAnalysisKeys(Query)
	
	If Query = Undefined Or Query.Parameters.Property("ProductAnalysisKeysInitialized") Then
		Return;
	EndIf;
	
	AnalyticsRequest = New Query(
	"SELECT DISTINCT
	|	GoodsTable.Warehouse             AS Warehouse,
	|	GoodsTable.Products      AS Products,
	|	GoodsTable.Characteristic    AS Characteristic,
	|	GoodsTable.ProductCostElement AS ProductCostElement,
	|	GoodsTable.Purpose        AS Purpose,
	|	GoodsTable.Series             AS Series
	|FROM
	|	(
	|	SELECT DISTINCT
	|		&Contract                        AS Warehouse,
	|		GoodsTable.Products      AS Products,
	|		GoodsTable.Characteristic    AS Characteristic,
	|		GoodsTable.ProductCostElement AS ProductCostElement,
	|		CASE
	|			WHEN GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				THEN &EmptyAssignment
	|			WHEN GoodsTable.ProductionStage.ProductionLot.Purpose IS NOT NULL
	|				THEN GoodsTable.ProductionStage.ProductionLot.Purpose
	|			ELSE ISNULL(CatProductionLots.Purpose, &EmptyAssignment)
	|		END                           AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus IN (14, 18)
	|				THEN GoodsTable.Series
	|			ELSE &EmptyBatch_
	|		END                           AS Series
	|	FROM
	|		Document.SubcontractorReport2_5.MaterialsAndWorks AS GoodsTable
	|		
	|		LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Document = GoodsTable.Ref
	|		AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|		AND NOT CatProductionLots.DeletionMark
	|
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		&Contract                        AS Warehouse,
	|		GoodsTable.Products      AS Products,
	|		GoodsTable.Characteristic    AS Characteristic,
	|		GoodsTable.ProductCostElement AS ProductCostElement,
	|		&EmptyAssignment               AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus IN (14, 18)
	|				THEN GoodsTable.Series
	|			ELSE &EmptyBatch_
	|		END                           AS Series
	|	FROM
	|		Document.SubcontractorReport2_5.MaterialsAndWorks AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		&Contract                        AS Warehouse,
	|		GoodsTable.Products      AS Products,
	|		GoodsTable.Characteristic    AS Characteristic,
	|		GoodsTable.ProductCostElement AS ProductCostElement,
	|		CASE
	|			WHEN GoodsTable.ProductionStage.ProductionLot.Purpose IS NOT NULL
	|				THEN GoodsTable.ProductionStage.ProductionLot.Purpose
	|			WHEN TRUE
	|				THEN ISNULL(CatProductionLots.Purpose, &EmptyAssignment)
	|		END                           AS Purpose,
	|		&EmptyBatch_                    AS Series
	|	FROM
	|		Document.SubcontractorReport2_5.Services AS GoodsTable
	|
	|		LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Document = GoodsTable.Ref
	|		AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|		AND NOT CatProductionLots.DeletionMark
	|
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND GoodsTable.Products <> VALUE(Catalog.Products.EmptyRef)
	|	
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		&Contract                        AS Warehouse,
	|		GoodsTable.Products      AS Products,
	|		GoodsTable.Characteristic    AS Characteristic,
	|		GoodsTable.ProductCostElement AS ProductCostElement,
	|		&EmptyAssignment               AS Purpose,
	|		&EmptyBatch_                    AS Series
	|	FROM
	|		Document.SubcontractorReport2_5.Services AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND GoodsTable.Products <> VALUE(Catalog.Products.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		&Contract                        AS Warehouse,
	|		GoodsTable.Products      AS Products,
	|		GoodsTable.Characteristic    AS Characteristic,
	|		GoodsTable.ProductCostElement AS ProductCostElement,
	|		CASE
	|			WHEN GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				THEN &EmptyAssignment
	|			WHEN GoodsTable.ProductionStage.ProductionLot.Purpose IS NOT NULL
	|				THEN GoodsTable.ProductionStage.ProductionLot.Purpose
	|			ELSE ISNULL(CatProductionLots.Purpose, &EmptyAssignment)
	|		END                           AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus IN (14, 18)
	|				THEN GoodsTable.Series
	|			ELSE &EmptyBatch_
	|		END                           AS Series
	|	FROM
	|		Document.SubcontractorReport2_5.SideAndIntermediateRelease AS GoodsTable
	|
	|		LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Document = GoodsTable.Ref
	|		AND CatProductionLots.Code = GoodsTable.CostGroupNumber
	|		AND NOT CatProductionLots.DeletionMark
	|
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		&Contract                        AS Warehouse,
	|		GoodsTable.Products      AS Products,
	|		GoodsTable.Characteristic    AS Characteristic,
	|		GoodsTable.ProductCostElement AS ProductCostElement,
	|		&EmptyAssignment               AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus IN (14, 18)
	|				THEN GoodsTable.Series
	|			ELSE &EmptyBatch_
	|		END                           AS Series
	|	FROM
	|		Document.SubcontractorReport2_5.SideAndIntermediateRelease AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		&Contract                        AS Warehouse,
	|		GoodsTable.Products      AS Products,
	|		GoodsTable.Characteristic    AS Characteristic,
	|		&EmptyArticle                   AS ProductCostElement,
	|		&EmptyAssignment               AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus IN (14, 18)
	|				THEN GoodsTable.Series
	|			ELSE &EmptyBatch_
	|		END                           AS Series
	|	FROM
	|		Document.SubcontractorReport2_5.ManufacturedProducts AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		&Contract                        AS Warehouse,
	|		GoodsTable.Products      AS Products,
	|		GoodsTable.Characteristic    AS Characteristic,
	|		&EmptyArticle                   AS ProductCostElement,
	|		&EmptyAssignment               AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus IN (14, 18)
	|				THEN GoodsTable.Series
	|			ELSE &EmptyBatch_
	|		END                           AS Series
	|	FROM
	|		Document.SubcontractorReport2_5.MaterialsAndWorks AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		&Department                  AS Warehouse,
	|		GoodsTable.Products      AS Products,
	|		GoodsTable.Characteristic    AS Characteristic,
	|		&EmptyArticle                   AS ProductCostElement,
	|		&EmptyAssignment               AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus IN (14, 18)
	|				THEN GoodsTable.Series
	|			ELSE &EmptyBatch_
	|		END                           AS Series
	|	FROM
	|		Document.SubcontractorReport2_5.MaterialsAndWorks AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		&Contract                        AS Warehouse,
	|		GoodsTable.Products      AS Products,
	|		GoodsTable.Characteristic    AS Characteristic,
	|		&EmptyArticle                   AS ProductCostElement,
	|		&EmptyAssignment               AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus IN (14, 18)
	|				THEN GoodsTable.Series
	|			ELSE &EmptyBatch_
	|		END                           AS Series
	|	FROM
	|		Document.SubcontractorReport2_5.SideAndIntermediateRelease AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|	) AS GoodsTable
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON GoodsTable.Products = Dimension.Products
	|		AND GoodsTable.Characteristic = Dimension.Characteristic
	|		AND GoodsTable.Series = Dimension.Series
	|		AND GoodsTable.Warehouse = Dimension.StorageLocation
	|		AND GoodsTable.Purpose = Dimension.Purpose
	|		AND GoodsTable.ProductCostElement = Dimension.ProductCostElement
	|WHERE
	|	Dimension.Products IS NULL
	|
	|GROUP BY
	|	GoodsTable.Warehouse,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.ProductCostElement,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series");
	
	AnalyticsRequest.SetParameter("Ref",                 Query.Parameters.Ref);
	AnalyticsRequest.SetParameter("Department",          Query.Parameters.Department);
	AnalyticsRequest.SetParameter("Contract",                Query.Parameters.Contract);
	AnalyticsRequest.SetParameter("EmptyBatch_",            Catalogs.ItemsBatches.EmptyRef());
	AnalyticsRequest.SetParameter("EmptyArticle",           Catalogs.ProductCostElements.EmptyRef());
	AnalyticsRequest.SetParameter("EmptyAssignment",       Catalogs.Assignments.EmptyRef());
	
	Selection = AnalyticsRequest.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection)
	EndDo;
	
	Query.SetParameter("ProductAnalysisKeysInitialized", True);
	
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionFactorToOrderCurrency")
		And Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients =
		ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Query.Parameters.Currency,
			Query.Parameters.OrderCurrency,
			Query.Parameters.Period,
			Query.Parameters.Organization);
	
	Query.SetParameter("ConversionFactorToOrderCurrency", Coefficients.ConversionRateToSettlementCurrency);
	Query.SetParameter("ConversionRateToManCurrency",    Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul",   Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

// Adapted text of the request for movements by case.
// 
// Parameters:
//  RegisterName - String
// 
// Returns:
//  Structure - LongDesc:
// * QueryText - String
// * ParameterValues - Structure:
// 	**MetadataIdentifier - CatalogRef.MetadataObjectIDs
//
Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.SubcontractorReport2_5";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	RedefiningParameterCalculation.Insert("IncomingDocumentNumber", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		RequestHasSource = False;
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydına göre hareketlerin düzenlenmesi talebinin metin uyarlaması uygulanmadı.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", 	FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", 		RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
			RedefiningParameterCalculation);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#Region TextsOfRequestsForHolding

#Region QueryTextsTemporaryTables

Function QueryTextTTBatchProduction(Query, QueryTexts = Undefined) Export
	
	RegisterName = "TTBatchProduction";
	
	QueryText = "
	|SELECT DISTINCT
	|	DD.ReleaseParty                                                                  AS ReleaseParty,
	|	DD.ProductionLot                                                             AS ProductionLot,
	|	ISNULL(DD.Purpose, VALUE(Catalog.Assignments.EmptyRef))             AS Purpose,
	|	ISNULL(DD.LineOfBusiness, &LineOfBusiness)                    AS LineOfBusiness,
	|	ISNULL(DD.ProductsGroup,
	|			 VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)) AS ProductsGroup,
	|	ISNULL(DD.VATActivityType, &PurchaseForActivity)                          AS VATActivityType,
	|	DD.CostGroupNumber                                                              AS CostGroupNumber
	|INTO TTBatchProduction
	|FROM
	|	(SELECT
	|		&Ref                                       AS ReleaseParty,
	|		CatProductionLots.Ref                  AS ProductionLot,
	|		CatProductionLots.Purpose              AS Purpose,
	|		CatProductionLots.LineOfBusiness AS LineOfBusiness,
	|		CatProductionLots.ProductsGroup         AS ProductsGroup,
	|		CatProductionLots.VATActivityType      AS VATActivityType,
	|		GoodsTable.CostGroupNumber               AS CostGroupNumber
	|	FROM
	|		Document.SubcontractorReport2_5.ManufacturedProducts AS GoodsTable
	|
	|		INNER JOIN Document.SubcontractorReport2_5 AS Attributes
	|		ON Attributes.Ref = GoodsTable.Ref
	|
	|		LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Document = &Ref
	|		AND CatProductionLots.Code       = GoodsTable.CostGroupNumber
	|		AND NOT CatProductionLots.DeletionMark
	|
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND NOT Attributes.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|
	|	UNION ALL
	|
	|	SELECT
	|		&Ref                                       AS ReleaseParty,
	|		Data_Stage.ProductionLot                AS ProductionLot,
	|		CatProductionLots.Purpose              AS Purpose,
	|		CatProductionLots.LineOfBusiness AS LineOfBusiness,
	|		CatProductionLots.ProductsGroup         AS ProductsGroup,
	|		CatProductionLots.VATActivityType      AS VATActivityType,
	|		GoodsTable.CostGroupNumber               AS CostGroupNumber
	|	FROM
	|		Document.SubcontractorReport2_5.ManufacturedProducts AS GoodsTable
	|
	|		INNER JOIN Document.ProductionStage2_2 AS Data_Stage
	|		ON GoodsTable.ProductionStage = Data_Stage.Ref
	|
	|		LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = Data_Stage.ProductionLot
	|
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		&Ref                                       AS ReleaseParty,
	|		Data_Stage.ProductionLot                AS ProductionLot,
	|		CatProductionLots.Purpose              AS Purpose,
	|		CatProductionLots.LineOfBusiness AS LineOfBusiness,
	|		CatProductionLots.ProductsGroup         AS ProductsGroup,
	|		CatProductionLots.VATActivityType      AS VATActivityType,
	|		GoodsTable.CostGroupNumber               AS CostGroupNumber
	|	FROM
	|		Document.SubcontractorReport2_5.SideAndIntermediateRelease AS GoodsTable
	|
	|		INNER JOIN Document.ProductionStage2_2 AS Data_Stage
	|		ON GoodsTable.ProductionStage = Data_Stage.Ref
	|
	|		LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = Data_Stage.ProductionLot
	|
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|	) AS DD
	|";
	
	If QueryTexts <> Undefined Then
		QueryTexts.Add(QueryText, RegisterName);
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	TextSelectionOfAnalystField =
	"SELECT
	|	""Products_1""									AS TabularSectionName,
	|	DocumentTable.LineNumber				AS LineNumber,
	|	UNDEFINED								AS Vendor,
	|	UNDEFINED								AS Counterparty,
	|	UNDEFINED								AS VATRate,
	|	UNDEFINED								AS VATTaxation,
	|	VALUE(Enum.AssetKinds.Goods)	AS AssetTaxClass,
	|	CASE
	|		WHEN &FIFORollingValuation
	|			THEN DocumentTable.RowCodeProducts
	|		ELSE 0
	|	END								AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.SubcontractorReport2_5.InventoryOwnerAttributesProducts AS DocumentTable
	|	LEFT JOIN Document.SubcontractorReport2_5 AS Attributes
	|		ON DocumentTable.Ref = Attributes.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	""ManufacturedProducts""							AS TabularSectionName,
	|	DocumentTable.LineNumber				AS LineNumber,
	|	UNDEFINED								AS Vendor,
	|	UNDEFINED								AS Counterparty,
	|	UNDEFINED								AS VATRate,
	|	UNDEFINED								AS VATTaxation,
	|	VALUE(Enum.AssetKinds.Goods)	AS AssetTaxClass,
	|	CASE
	|		WHEN &FIFORollingValuation
	|			THEN DocumentTable.RowCodeProducts
	|		ELSE 0
	|	END								AS RowCode
	|FROM
	|	Document.SubcontractorReport2_5.ManufacturedProducts AS DocumentTable
	|
	|	LEFT JOIN Document.SubcontractorReport2_5 AS Attributes
	|	ON DocumentTable.Ref = Attributes.Ref
	|
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND DocumentTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND DocumentTable.ItemsLocationAttributes NOT IN
	|		(SELECT DISTINCT
	|			InventoryKinds.ItemsLocationAttributes
	|		FROM
	|			Document.SubcontractorReport2_5.InventoryOwnerAttributesProducts AS InventoryKinds
	|		WHERE
	|			InventoryKinds.Ref = &Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	""SideAndIntermediateRelease""							AS TabularSectionName,
	|	DocumentTable.LineNumber				AS LineNumber,
	|	UNDEFINED								AS Vendor,
	|	UNDEFINED								AS Counterparty,
	|	UNDEFINED								AS VATRate,
	|	UNDEFINED								AS VATTaxation,
	|	VALUE(Enum.AssetKinds.Goods)	AS AssetTaxClass,
	|	0									AS RowCode
	|FROM
	|	Document.SubcontractorReport2_5.SideAndIntermediateRelease AS DocumentTable
	|
	|	LEFT JOIN Document.SubcontractorReport2_5 AS Attributes
	|	ON DocumentTable.Ref = Attributes.Ref
	|
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND DocumentTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND DocumentTable.ItemsLocationAttributes NOT IN
	|		(SELECT DISTINCT
	|			InventoryKinds.ItemsLocationAttributes
	|		FROM
	|			Document.SubcontractorReport2_5.InventoryOwnerAttributesProducts AS InventoryKinds
	|		WHERE
	|			InventoryKinds.Ref = &Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	""Services""								AS TabularSectionName,
	|	TableServices.LineNumber				AS LineNumber,
	|	Attributes.Partner						AS Vendor,
	|	Attributes.Counterparty					AS Counterparty,
	|	TableServices.VATRate					AS VATRate,
	|	Attributes.PurchaseForActivity		AS VATTaxation,
	|	VALUE(Enum.AssetKinds.OtherWorksAndServices) AS AssetTaxClass,
	|	0										AS RowCode
	|FROM
	|	Document.SubcontractorReport2_5.Services AS TableServices
	|	
	|	LEFT JOIN Document.SubcontractorReport2_5 AS Attributes
	|	ON Attributes.Ref = TableServices.Ref
	|
	|WHERE
	|	Attributes.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts)
	
	RegisterName = "TemporaryTableCurrencyExchangeRates";
	
	QueryText = "
	|SELECT
	|	RelativeExchangeRatesSliceLast.Currency AS Currency,
	|	RelativeExchangeRatesSliceLast.CourseNumerator AS CourseNumerator,
	|	RelativeExchangeRatesSliceLast.CourseDenominator AS CourseDenominator
	|INTO TemporaryTableCurrencyExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(
	|			&Period,
	|			BaseCurrency IN
	|				(SELECT
	|					DefaultBaseCurrency.Value AS Value
	|				FROM
	|					Constant.DefaultBaseCurrency AS DefaultBaseCurrency)
	|		) AS RelativeExchangeRatesSliceLast
	|
	|INDEX BY
	|	Currency
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

// Distributed types of stocks.
// 
// Parameters:
//  MainQuery - Query - Query
// 
// Returns:
//  ValueTable - Distributed inventory types
Function DistributedTypesOfStocks(MainQuery)
	
	SetRequestParametersCurrencyCoefficients(MainQuery);
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager;
	
	For Each Parameter In MainQuery.Parameters Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	
	InitializeProductAnalysisKeys(Query);
	
	QueryTexts = New ValueList;
	ArrayOfTexts = New Array;
	ArrayOfTexts.Add(QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts));
	ArrayOfTexts.Add(QueryTextTTBatchProduction(Query, QueryTexts));
	ArrayOfTexts.Add(QueryTextTTTypesOfStocks(Query, QueryTexts));
	
	QueryText =
	// template of distributed types of stocks, VGRANITSA - 3
	"SELECT TOP 0
	|   DD.RowID                           AS RowID,
	|	DD.ItemsLocationAttributes                    AS ItemsLocationAttributes,
	|	DD.AnalysisOfAccountingForProductsWithoutAssignment       AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	DD.AccountingSection                                   AS AccountingSection,
	|	DD.InventoryOwnerAttribute                                    AS InventoryOwnerAttribute,
	|	DD.CCDNumber                                      AS CCDNumber,
	|	DD.ProductionLot                            AS ProductionLot,
	|	DD.ReleaseParty                                 AS ReleaseParty,
	|	DD.BusinessOperation                         AS BusinessOperation,
	|	DD.BusinessOperation                         AS BusinessOperationInitial,
	|	DD.CorItemsLocationAttributes                 AS CorItemsLocationAttributes,
	|	DD.CorAnalysisOfAccountingForProductsWithoutAssignment    AS CorAnalysisOfAccountingForProductsWithoutAssignment,
	|	DD.CorAccountingSection                                AS CorAccountingSection,
	|	DD.InventoryOwnerAttribute                                    AS CorInventoryOwnerAttribute,
	|	DD.VATActivityType                            AS CorVATActivityTypes,
	|	DD.ProductsGroup                               AS ProductsGroup,
	|	DD.CorGroupOfManufacturedProducts                            AS CorGroupOfManufacturedProducts,
	|	DD.LotVendorAttributes                          AS LotVendorAttributes,
	|	DD.LotVendorAttributes                          AS LotVendorAttributesCorr,
	|	DD.Count                                    AS Count,
	|	DD.Cost                                     AS Cost,
	|	DD.CostExcludingVAT                               AS CostExcludingVAT,
	|	DD.LocalCost                                 AS LocalCost,
	|	DD.VATAmount                                      AS VATAmount,
	|	DD.VATManag                                        AS VATManag,
	|	DD.CostMan                                  AS CostMan,
	// for production 2.1
	|	DD.CostGroupNumber                             AS CostGroupNumber,
	|	DD.ProductCostElement                             AS ProductCostElement,
	|	DD.BusinessTransactionSetting                AS BusinessTransactionSetting
	|FROM
	|	TTTypesOfStocks AS DD
	|;
	|
	// parties, abroad - 2
	|SELECT DISTINCT
	|	Lots.CostGroupNumber                       AS CostGroupNumber
	|FROM
	|	TTBatchProduction AS Lots
	|;
	|
	// products, abroad - 1
	|SELECT
	|	GoodsTable.RowID              AS RowID,
	|	GoodsTable.CostShare                    AS CostShare,
	|	GoodsTable.CostGroupNumber                AS CostGroupNumber,
	|	GoodsTable.LotVendorAttributes             AS LotVendorAttributesCorr,
	|	GoodsTable.ProductionStage                 AS ProductionStage,
	|	GoodsTable.ItemsLocationAttributes       AS CorItemsLocationAttributes,
	|	GoodsTable.AnalysisOfAccountingForProductsWithoutAssignment AS CorAnalysisOfAccountingForProductsWithoutAssignment,
	|	GoodsTable.CorGroupOfManufacturedProducts               AS CorGroupOfManufacturedProducts,
	|	GoodsTable.InventoryOwnerAttribute                       AS CorInventoryOwnerAttribute,
	|	GoodsTable.CCDNumber                         AS CCDNumber,
	|	GoodsTable.AccountingSection                      AS CorAccountingSection,
	|	GoodsTable.VATActivityType               AS CorVATActivityTypes,
	|	GoodsTable.ReleaseParty                    AS ReleaseParty,
	|	GoodsTable.BusinessOperation            AS BusinessOperation,
	// for production 2.1
	|	GoodsTable.BusinessTransactionSetting   AS BusinessTransactionSetting
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|WHERE
	|	GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|;
	|
	// materials, waste and services for distribution, abroad
	|SELECT
	|	GoodsTable.CostGroupNumber                AS CostGroupNumber,
	|	GoodsTable.ProductionStage                 AS ProductionStage,
	|	GoodsTable.LotVendorAttributes             AS LotVendorAttributes,
	|	GoodsTable.CorItemsLocationAttributes    AS ItemsLocationAttributes,
	|	GoodsTable.CorAnalysisOfAccountingForProductsWithoutAssignment AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	GoodsTable.ProductsGroup                  AS ProductsGroup,
	|	GoodsTable.InventoryOwnerAttribute                       AS InventoryOwnerAttribute,
	|	GoodsTable.ProductCostElement                AS ProductCostElement,
	|	GoodsTable.BusinessOperation            AS BusinessOperationInitial,
	|	GoodsTable.CorAccountingSection                   AS AccountingSection,
	|	GoodsTable.ProductionLot               AS ProductionLot,
	|	GoodsTable.Count                       AS Count,
	|	GoodsTable.Cost                        AS Cost,
	|	GoodsTable.CostExcludingVAT                  AS CostExcludingVAT,
	|	GoodsTable.LocalCost                    AS LocalCost,
	|	GoodsTable.VATAmount                         AS VATAmount,
	|	GoodsTable.VATManag                           AS VATManag,
	|	GoodsTable.CostMan                     AS CostMan,
	|	GoodsTable.BusinessTransactionSetting   AS BusinessTransactionSetting
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|WHERE
	|	GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.CostGroupNumber                AS CostGroupNumber,
	|	GoodsTable.ProductionStage                 AS ProductionStage,
	|	GoodsTable.LotVendorAttributes             AS LotVendorAttributes,
	|	GoodsTable.ItemsLocationAttributes       AS ItemsLocationAttributes,
	|	GoodsTable.AnalysisOfAccountingForProductsWithoutAssignment AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	GoodsTable.ProductsGroup                  AS ProductsGroup,
	|	GoodsTable.InventoryOwnerAttribute                       AS InventoryOwnerAttribute,
	|	GoodsTable.ProductCostElement                AS ProductCostElement,
	|	GoodsTable.BusinessOperation            AS BusinessOperationInitial,
	|	GoodsTable.AccountingSection                      AS AccountingSection,
	|	GoodsTable.ProductionLot               AS ProductionLot,
	|	GoodsTable.Count                       AS Count,
	|	GoodsTable.Cost                        AS Cost,
	|	GoodsTable.CostExcludingVAT                  AS CostExcludingVAT,
	|	GoodsTable.LocalCost                    AS LocalCost,
	|	GoodsTable.VATAmount                         AS VATAmount,
	|	GoodsTable.VATManag                           AS VATManag,
	|	GoodsTable.CostMan                     AS CostMan,
	|	GoodsTable.BusinessTransactionSetting   AS BusinessTransactionSetting
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|WHERE
	|	GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.CostGroupNumber                AS CostGroupNumber,
	|	GoodsTable.ProductionStage                 AS ProductionStage,
	|	GoodsTable.LotVendorAttributes             AS LotVendorAttributes,
	|	GoodsTable.CorItemsLocationAttributes    AS ItemsLocationAttributes,
	|	GoodsTable.CorAnalysisOfAccountingForProductsWithoutAssignment AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	GoodsTable.ProductsGroup                  AS ProductsGroup,
	|	GoodsTable.InventoryOwnerAttribute                       AS InventoryOwnerAttribute,
	|	GoodsTable.ProductCostElement                AS ProductCostElement,
	|	GoodsTable.BusinessOperation            AS BusinessOperationInitial,
	|	GoodsTable.CorAccountingSection                   AS AccountingSection,
	|	GoodsTable.ProductionLot               AS ProductionLot,
	|	- SUM(GoodsTable.Count)              AS Count,
	|	- SUM(GoodsTable.Cost)               AS Cost,
	|	- SUM(GoodsTable.CostExcludingVAT)         AS CostExcludingVAT,
	|	- SUM(GoodsTable.LocalCost)           AS LocalCost,
	|	- SUM(GoodsTable.VATAmount)                AS VATAmount,
	|	- SUM(GoodsTable.VATManag)                  AS VATManag,
	|	- SUM(GoodsTable.CostMan)            AS CostMan,
	|	GoodsTable.BusinessTransactionSetting   AS BusinessTransactionSetting
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|WHERE
	|	GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|
	|GROUP BY
	|	GoodsTable.CostGroupNumber,
	|	GoodsTable.ProductionStage,
	|	GoodsTable.LotVendorAttributes,
	|	GoodsTable.CorItemsLocationAttributes,
	|	GoodsTable.CorAnalysisOfAccountingForProductsWithoutAssignment,
	|	GoodsTable.ProductsGroup,
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.ProductCostElement,
	|	GoodsTable.BusinessOperation,
	|	GoodsTable.CorAccountingSection,
	|	GoodsTable.ProductionLot,
	|	GoodsTable.BusinessTransactionSetting
	|";
	
	ArrayOfTexts.Add(QueryText);
	Query.Text = StrConcat(ArrayOfTexts, Common.QueryBatchSeparator());
	
	ResultsPackage = Query.ExecuteBatch();
	
	Boundary = ResultsPackage.UBound();
	
	DistributedTypesOfStocks      = ResultsPackage[Boundary - 3].Unload();
	BatchTable_                  = ResultsPackage[Boundary - 2].Unload();
	ProductTable               = ResultsPackage[Boundary - 1].Unload();
	TableToDistribution          = ResultsPackage[Boundary].Unload();
	
	ByOrders = MainQuery.Parameters.ByOrders;
	GroupCosts = MainQuery.Parameters.GroupCosts;
	
	For Each Lot In BatchTable_ Do
		
		If ByOrders And GroupCosts = Enums.CostGroupingsInTollingOrder.NoGrouping Then
			ProductList_      = ProductTable;
			ListToDistribution = TableToDistribution;
		Else
			TheStructureOfTheSearch = New Structure("CostGroupNumber", Lot.CostGroupNumber);
			ProductList_      = ProductTable.FindRows(TheStructureOfTheSearch);
			ListToDistribution = TableToDistribution.FindRows(TheStructureOfTheSearch);
		EndIf;
		
		ProductLines   = ProductList_.Count();
		PrepareForDistribution = ListToDistribution.Count();
		
		ArrayOfCoefficients = New Array;
		For Each RowData In ProductList_ Do
			ArrayOfCoefficients.Add(?(RowData.CostShare <> 0, RowData.CostShare, 1));
		EndDo; 
		If ArrayOfCoefficients.Count() = 1 Then
			ArrayOfCoefficients[0] = 1;
		EndIf;
		
		// we will distribute it to the released products
		For RowIndex = 0 To PrepareForDistribution - 1 Do
			
			DistributableString = ListToDistribution[RowIndex];
			
			Count      = Common.DistributeAmountInProportionToCoefficients(DistributableString.Count, ArrayOfCoefficients, 3);
			Cost       = Common.DistributeAmountInProportionToCoefficients(DistributableString.Cost, ArrayOfCoefficients, 3);
			CostExcludingVAT = Common.DistributeAmountInProportionToCoefficients(DistributableString.CostExcludingVAT, ArrayOfCoefficients, 3);
			LocalCost   = Common.DistributeAmountInProportionToCoefficients(DistributableString.LocalCost, ArrayOfCoefficients, 3);
			VATAmount        = Common.DistributeAmountInProportionToCoefficients(DistributableString.VATAmount, ArrayOfCoefficients, 3);
			VATManag        	= Common.DistributeAmountInProportionToCoefficients(DistributableString.VATManag, ArrayOfCoefficients, 3);
			CostMan    = Common.DistributeAmountInProportionToCoefficients(DistributableString.CostMan, ArrayOfCoefficients, 3);
			
			For IndexProduct = 0 To ProductLines - 1 Do
				
				ProductionLine = ProductList_[IndexProduct];
				
				NewRow = DistributedTypesOfStocks.Add();
				
				// filling in the analysis of material, waste, services
				FillPropertyValues(NewRow, DistributableString);
				
				// filling out product analytics in the cor part
				FillPropertyValues(NewRow, ProductionLine);
				
				NewRow.Count      = ?(ValueIsFilled(Count), Count[IndexProduct], 0);
				NewRow.Cost       = ?(ValueIsFilled(Cost), Cost[IndexProduct], 0);
				NewRow.CostExcludingVAT = ?(ValueIsFilled(CostExcludingVAT), CostExcludingVAT[IndexProduct], 0);
				NewRow.LocalCost   = ?(ValueIsFilled(LocalCost), LocalCost[IndexProduct], 0);
				NewRow.VATAmount        = ?(ValueIsFilled(VATAmount), VATAmount[IndexProduct], 0);
				NewRow.VATManag        	= ?(ValueIsFilled(VATManag), VATManag[IndexProduct], 0);
				NewRow.CostMan    = ?(ValueIsFilled(CostMan), CostMan[IndexProduct], 0);
				
			EndDo;
			
		EndDo;
	
	EndDo;
	
	GroupingColumns = "";
	TotalingColumns = "Count,Cost,CostExcludingVAT,LocalCost,VATAmount,VATManag,CostMan";
	
	ArrayOfIndicators = StringFunctionsClientServer.SplitStringIntoSubstringsArray(TotalingColumns);
	For Each Column In DistributedTypesOfStocks.Columns Do
		ThisIsGroupingColumn = True;
		For Each Factor In ArrayOfIndicators Do
			If Column.Name = Factor > 0 Then
				ThisIsGroupingColumn = False;
				Break;
			EndIf;
		EndDo;
		If ThisIsGroupingColumn Then
			If ValueIsFilled(GroupingColumns) Then
				GroupingColumns = GroupingColumns + "," + Column.Name;
			Else
				GroupingColumns = Column.Name;
			EndIf;
		EndIf;
	EndDo;
	DistributedTypesOfStocks.GroupBy(GroupingColumns, TotalingColumns);
	
	Return DistributedTypesOfStocks;
	
EndFunction

// The text of the request to create a temporary table
// 
// Parameters:
//  Query - Query - Query
//  QueryTexts - ValueList - Request texts
// 
// Returns:
//  String - Query text
Function QueryTextTTDistributedInventoryTypes(Query, QueryTexts)
	
	RegisterName = "TTDistributedInventoryTypes";
	
	TableDistributedTypesOfStocks = DistributedTypesOfStocks(Query);
	Query.SetParameter("TableDistributedTypesOfStocks", TableDistributedTypesOfStocks);
	
	QueryText = 
	"SELECT
	|	*
	|INTO TTDistributedInventoryTypes
	|
	|FROM
	|	&TableDistributedTypesOfStocks AS DD
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// The text of the request to create a temporary table
// 
// Parameters:
//  Query - Query - Query
//  QueryTexts - ValueList - Request texts
// 
// Returns:
//  String - Query text
Function QueryTextTTTableReturnableWaste(Query, QueryTexts)
	
	RegisterName = "TTTableReturnableWaste";
	
	QueryText =
	"SELECT
	|	TableReturnableWaste.Ref                     AS Ref,
	|	TableReturnableWaste.LineNumber                AS LineNumber,
	|	TableReturnableWaste.RowID        AS RowID,
	|	TableReturnableWaste.ItemsLocationAttributes AS ItemsLocationAttributes,	
	|	TableReturnableWaste.RowCode                  AS RowCode,
	|	TableReturnableWaste.Products               AS Products,
	|	TableReturnableWaste.Characteristic             AS Characteristic,
	|	TableReturnableWaste.Purpose                 AS Purpose,
	|	TableReturnableWaste.ProductionStage           AS ProductionStage,
	|	TableReturnableWaste.SubcontractOrder         AS SubcontractOrder,
	|	TableReturnableWaste.Recipient                 AS Recipient,
	|	TableReturnableWaste.ProductCostElement          AS ProductCostElement,
	|	TableReturnableWaste.ToExpenseAs           AS ToExpenseAs,
	|	TableReturnableWaste.ExpenseItem             AS ExpenseItem,
	|	TableReturnableWaste.DimensionOfExpenses          AS DimensionOfExpenses,
	|	TableReturnableWaste.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
	|	TableReturnableWaste.GLAccountSettings       AS GLAccountSettings,
	|	TableReturnableWaste.Count				   AS Count,
	|	TableReturnableWaste.Price				       AS Price,
	|	TableReturnableWaste.Sum				       AS Sum,
	|	CASE
	|		WHEN ProductData_1.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                              AS Work_5
	|
	|INTO TTTableReturnableWaste
	|
	|FROM
	|	Document.SubcontractorReport2_5.SideAndIntermediateRelease AS TableReturnableWaste
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON TableReturnableWaste.Products = ProductData_1.Ref
	|WHERE
	|	TableReturnableWaste.Ref = &Ref
	|
	|INDEX BY
	|	ToExpenseAs,
	|	Work_5";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction	

// The text of the request to create a temporary table
// 
// Parameters:
//  Query - Query - Query
//  QueryTexts - ValueList - Request texts
// 
// Returns:
//  String - Query text
Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableReturnableWaste", QueryTexts) Then
		QueryTextTTTableReturnableWaste(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText = "
	|SELECT
	|	TabularSection.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	(CASE
	|		WHEN TabularSection.Recipient = VALUE(Catalog.BusinessStructure.EmptyRef)
	|		 OR NOT TabularSection.Work_5
	|			THEN &Department
	|		ELSE TabularSection.Recipient END) AS Department,
	|	&Ref AS ExpenseReceiptDocument,
	|	TabularSection.ExpenseItem AS ExpenseItem,
	|	TabularSection.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	(CASE
	|		WHEN &AccountingForLBCosts THEN &LineOfBusiness
	|		ELSE UNDEFINED END) AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	&PurchaseForActivity AS VATActivityType,
	|
	|	CAST(TabularSection.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))  AS Cost,
	|	CAST(TabularSection.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))  AS CostExcludingVAT,
	|	CAST(TabularSection.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS VATLocal,
	|	0 AS VATManag,
	|
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) AS BusinessOperation,
	|	TabularSection.RowID AS RowID,
	|	ISNULL(InventoryKinds.FinRecordID, TabularSection.RowID)   AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseFixCost) AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	TTTableReturnableWaste AS TabularSection
	|	LEFT JOIN TTTypesOfStocks AS InventoryKinds
	|		ON TabularSection.RowID = InventoryKinds.RowID
	|		AND TabularSection.RowID <> """"
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber 	   = TabularSection.LineNumber
	|		AND TableOfBatchAccountingAnalysts.TabularSectionName = ""RecyclableWaste""
	|WHERE
	|	TabularSection.ToExpenseAs
	|	AND VALUETYPE(TabularSection.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

// The text of the request to create a temporary table
// 
// Parameters:
//  Query - Query - Query
//  QueryTexts - ValueList - Request texts
// 
// Returns:
//  String - Query text
Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

// The text of the request to create a temporary table
// 
// Parameters:
//  Query - Query - Query
//  QueryTexts - ValueList - Request texts
// 
// Returns:
//  String - Query text
Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

// The text of the request to create a temporary table
// 
// Parameters:
//  Query - Query - Query
//  QueryTexts - ValueList - Request texts
// 
// Returns:
//  String - Query text
Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableReturnableWaste", QueryTexts) Then
		QueryTextTTTableReturnableWaste(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText =
	"SELECT
	|	TabularSection.LineNumber                                                         AS LineNumber,
	|	&Period                                                                            AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                             AS RecordType,
	|	&AdjustmentPeriod_                                                               AS VariancePeriod,
	|	&Organization                                                                       AS Organization,
	// The division must be filled in according to the function of the textquestiontablecareparticipation and other expenses and
	// the area #Write-off area#Expendactives_Products.
	|	CASE
	|		WHEN TabularSection.Recipient = VALUE(Catalog.BusinessStructure.EmptyRef)
	|		 OR NOT TabularSection.Work_5
	|			THEN &Department
	|		ELSE TabularSection.Recipient
	|	END                	                                                           AS Department,
	|	TabularSection.ExpenseItem                                                      AS ExpenseItem,
	|	TabularSection.DimensionOfExpenses                                                   AS DimensionOfExpenses,
	|	CASE
	|		WHEN &AccountingForLBCosts THEN
	|			&LineOfBusiness
	|	END AS LineOfBusiness,
	|	&PurchaseForActivity                                                           AS VATActivityType,
	|
	|	CAST(TabularSection.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))  AS AmountIncludingVAT,
	|	CAST(TabularSection.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))  AS AmountExcludingVAT,
	|	CAST(TabularSection.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))  AS AmountExcludingVATMan,
	|	CAST(TabularSection.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS AmountIncludingVATCompl,
	|	CAST(TabularSection.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS AmountExcludingVATCompl,
	|	0                                                                                  AS PermanentDifference,
	|	0                                                                                  AS CostTD,
	|	VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.GoodsConsumptionOnDemand) AS BusinessTransactionSetting,
	|	TabularSection.ItemsLocationAttributes                                          AS ItemsLocationAttributes,
	|	
	|	ISNULL(InventoryKinds.FinRecordID, TabularSection.RowID)   AS FinRecordID
	|	
	|INTO TTInitialOtherExpenses
	|FROM
	|	TTTableReturnableWaste AS TabularSection
	|	LEFT JOIN TTTypesOfStocks AS InventoryKinds
	|		ON TabularSection.RowID = InventoryKinds.RowID
	|		AND TabularSection.RowID <> """"
	|WHERE
	|	TabularSection.ToExpenseAs
	|	AND NOT TabularSection.Sum = 0
	|	AND VALUETYPE(TabularSection.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

// The text of the request to create a temporary table
// 
// Parameters:
//  Query - Query - Query
//  QueryTexts - ValueList - Request texts
// 
// Returns:
//  String - Query text
Function QueryTextTableTTOtherExpenses_(Query, QueryTexts)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

// The text of the request to create a temporary table
// 
// Parameters:
//  Query - Query - Query
//  QueryTexts - ValueList - Request texts
// 
// Returns:
//  String - Query text
Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TTDistributedInventoryTypes", QueryTexts) Then
		QueryTextTTDistributedInventoryTypes(Query, QueryTexts);
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period									AS Period,
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	&Organization							AS Organization,
	|	&Department							AS Department,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED                            AS DimensionOfExpenses,
	|	CASE
	|		WHEN &AccountingForLBCosts THEN
	|			&LineOfBusiness
	|	END                                   AS LineOfBusiness,
	|	GoodsTable.Cost					AS Sum,
	|	GoodsTable.CostExcludingVAT			AS AmountExcludingVAT,
	|	GoodsTable.CostMan				AS SumMan,
	|	GoodsTable.LocalCost				AS SumCompl,
	|	0                                       AS PermanentDifference,
	|	0                                       AS CostTD,
	|	&AITAmount                               AS AITAmount,
	|	&BusinessOperation					AS BusinessOperation,
	|	UNDEFINED                            AS ItemsLocationAttributes,
	|	
	|	GoodsTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting,
	|	&AdjustmentPeriod_					AS VariancePeriod
	|	
	|FROM
	|	TTDistributedInventoryTypes AS GoodsTable
	|	LEFT JOIN AITAccountingPolicyOtherExpenses AS AITAccountingPolicy
	|		ON &Organization = AITAccountingPolicy.Organization
	|WHERE
	|	GoodsTable.Cost <> 0
	|	AND GoodsTable.BusinessOperationInitial = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|	AND GoodsTable.ItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period									AS Period,
	|	VALUE(AccumulationRecordType.Expense)	AS RecordType,
	|	&Organization							AS Organization,
	|	&Department							AS Department,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED                            AS DimensionOfExpenses,
	|	CASE
	|		WHEN &AccountingForLBCosts THEN
	|			&LineOfBusiness
	|	END                                   AS LineOfBusiness,
	|	GoodsTable.Cost					AS Sum,
	|	GoodsTable.CostExcludingVAT			AS AmountExcludingVAT,
	|	GoodsTable.CostMan				AS SumMan,
	|	GoodsTable.LocalCost				AS SumCompl,
	|	0                                       AS PermanentDifference,
	|	0                                       AS CostTD,
	|	0                                       AS AITAmount,
	|	&BusinessOperation					AS BusinessOperation,
	|	UNDEFINED                            AS ItemsLocationAttributes,
	|	
	|	GoodsTable.RowID       AS FinRecordID,
	|	&BusinessTransactionSetting         AS BusinessTransactionSetting,
	|	&AdjustmentPeriod_					AS VariancePeriod
	|	
	|FROM
	|	TTDistributedInventoryTypes AS GoodsTable
	|WHERE
	|	GoodsTable.Cost <> 0
	|	AND GoodsTable.BusinessOperationInitial = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|	AND GoodsTable.ItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|";
	
	CalculationOfCostLocalization.SubstituteAmountOfPersonalIncomeTaxInRequest(QueryText, "GoodsTable", "Receipt", "LocalCost",,, "&Period", True);
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("VariancePeriod") 
				   + TMCommonUse.QuerySeparatorInJoin() 
				   + QueryText;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

// The text of the request to create a temporary table
// 
// Parameters:
//  Query - Query - Query
//  QueryTexts - ValueList - Request texts
// 
// Returns:
//  String - Query text
Function QueryTextTTGoodsImportApplications(Query, QueryTexts)
	
	RegisterName = "TTProductsStatements";
	
	QueryText = "
	|SELECT
	|	SUM(Amounts.AmountExcludingVAT) AS AmountExcludingVAT
	|INTO TTDocumentAmount
	|FROM
	|	TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|;
	|
	|/////////////////////////////////////////// 
	|SELECT
	|	SUM(TTDistributedInventoryTypes.LocalCost) AS LocalCost
	|INTO LocalTTAmounts
	|FROM
	|	TTDistributedInventoryTypes AS TTDistributedInventoryTypes
	|;
	|
	|///////////////////////////////////////////
	|SELECT
	|	TTTypesOfStocks.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTTypesOfStocks.CCDNumber 					 AS CCDNumber,
	|	TTTypesOfStocks.RowID 		 AS RowID,
	|	SUM(TTTypesOfStocks.Count)			 AS Count
	|INTO TTTypesOfStocksInSummary
	|FROM
	|	TTTypesOfStocks AS TTTypesOfStocks
	|
	|GROUP BY
	|	TTTypesOfStocks.ItemsLocationAttributes,
	|	TTTypesOfStocks.CCDNumber,
	|	TTTypesOfStocks.RowID
	|;
	|
	|///////////////////////////////////////////
	|SELECT
	|	&Ref AS Ref,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Partner AS Vendor,
	|	TableDistributedTypesOfStocks.CorItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableDistributedTypesOfStocks.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	&Ref AS DocumentAcquisitions,
	|	&IdApplicationForImportOfGoods AS ImportDocumentType,
	|	TableTypesOfStocks_.Count AS Count,
	|	SUM(TableDistributedTypesOfStocks.LocalCost * TTDocumentAmount.AmountExcludingVAT / LocalTTAmounts.LocalCost) AS Sum,
	|	TableDistributedTypesOfStocks.CCDNumber AS CCDNumber,
	|	TableDistributedTypesOfStocks.RowID AS RowID
	|INTO TTProductsStatements
	|FROM
	|	TTDistributedInventoryTypes AS TableDistributedTypesOfStocks
	|		INNER JOIN TTTypesOfStocksInSummary AS TableTypesOfStocks_
	|		ON TableDistributedTypesOfStocks.CorItemsLocationAttributes = TableTypesOfStocks_.ItemsLocationAttributes
	|			AND TableDistributedTypesOfStocks.RowID = TableTypesOfStocks_.RowID
	|			AND TableDistributedTypesOfStocks.CCDNumber = TableTypesOfStocks_.CCDNumber
	|		LEFT JOIN TTDocumentAmount AS TTDocumentAmount
	|		ON TRUE
	|		LEFT JOIN LocalTTAmounts AS LocalTTAmounts
	|		ON TRUE
	|WHERE
	|	&BusinessOperation = &HouseholdOperationsProcessingInEAEUCountries
	|	AND TableDistributedTypesOfStocks.BusinessOperationInitial = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|
	|GROUP BY
	|	TableDistributedTypesOfStocks.CorItemsLocationAttributes,
	|	TableDistributedTypesOfStocks.CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.Count,
	|	TableDistributedTypesOfStocks.CCDNumber,
	|	TableDistributedTypesOfStocks.RowID
	|";
	
	If QueryTexts <> Undefined Then
		QueryTexts.Add(QueryText, RegisterName);
	EndIf;
	
	Return QueryText;
	
EndFunction

#Region InventoryKinds

Function QueryTextTTTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTypesOfStocks";
	
	InitializeProductAnalysisKeys(Query);
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	SetRequestParametersCurrencyCoefficients(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBatchProduction", QueryTexts) Then
		QueryTextTTBatchProduction(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	TextsTTTypesOfStocks = New Array;
	TextsTTTypesOfStocks.Add(QueryTextTTStockTypesMaterials());
	TextsTTTypesOfStocks.Add(QueryTextTTTypesOfProductStocks());
	TextsTTTypesOfStocks.Add(RequestTextTTTypesOfInventoryWorkMaterials());
	TextsTTTypesOfStocks.Add(RequestTextTTTypesOfWorkStocksOutputProducts());
	TextsTTTypesOfStocks.Add(RequestTextTTTypesOfInventoryWorkByProducts());
	TextsTTTypesOfStocks.Add(RequestTextTTTypesOfInventoryServices());
	
	QueryText = StrConcat(TextsTTTypesOfStocks, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTStockTypesMaterials()
	
	Return
	"SELECT
	|	GoodsTable.ItemsLocationAttributes                        AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey                            AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	CASE
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners)
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingTransferredToPartners)
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		  OR GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|	END                                                           AS AccountingSection,
	|	GoodsTable.InventoryOwnerAttribute                                        AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber                                          AS CCDNumber,
	|	ProductionLots.ProductionLot                           AS ProductionLot,
	|	ProductionLots.ReleaseParty                                AS ReleaseParty,
	|	SUM(GoodsTable.Count)                                 AS Count,
	|	0                                                               AS Cost,
	|	0                                                               AS CostExcludingVAT,
	|	0                                                               AS LocalCost,
	|	0                                                               AS VATAmount,
	|	0                                                               AS VATManag,
	|	0                                                               AS CostMan,
	|	ProductionLots.VATActivityType                           AS VATActivityType,
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots) AS BusinessOperation,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress) AS CorAccountingSection,
	|	CASE
	|		WHEN Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN ISNULL(ProductionAnalyticsWithoutAssignment.DimensionKey, UNDEFINED)
	|		ELSE ISNULL(DimensionOfProduction.DimensionKey, UNDEFINED)
	|	END                                                           AS CorItemsLocationAttributes,
	|	ISNULL(ProductionAnalyticsWithoutAssignment.DimensionKey, UNDEFINED) AS CorAnalysisOfAccountingForProductsWithoutAssignment,
	|	GoodsTable.ProductCostElement                                 AS ProductCostElement,
	|	ProductionLots.ProductsGroup                              AS ProductsGroup,
	|	UNDEFINED                                                    AS CorGroupOfManufacturedProducts,
	|	UNDEFINED                                                    AS LotVendorAttributes,
	|	GoodsTable.ProductionStage                                  AS ProductionStage,
	|	0                                                               AS CostShare,
	|	&Department                                                  AS Department,
	|	FALSE                                                            AS ToExpenseAs,
	|	UNDEFINED                                                    AS ExpenseItem,
	|	UNDEFINED                                                    AS DimensionOfExpenses,
	|	UNDEFINED                                                    AS AssetsLiabilitiesDimension,
	|	UNDEFINED                                                    AS GLAccountSettings,
	|	GoodsTable.RowID                               AS RowID,
	|	GoodsTable.CostGroupNumber                                 AS CostGroupNumber,
	|	GoodsTable.FinRecordID                            AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ExpensingToProductionLots) AS BusinessTransactionSetting
	|INTO TTTypesOfStocks
	|FROM
	|	Document.SubcontractorReport2_5.InventoryOwnerAttributesMaterials AS GoodsTable
	|	
	|	INNER JOIN TTBatchProduction AS ProductionLots
	|	ON GoodsTable.Ref = ProductionLots.ReleaseParty
	|	AND GoodsTable.CostGroupNumber = ProductionLots.CostGroupNumber
	|	
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON GoodsTable.ItemsLocationAttributes = Dimension.Ref
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|	AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|	AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|	AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|	AND &EmptyDestinationLink = AnalyticsWithoutAssignment.Purpose
	|	AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionOfProduction
	|	ON Dimension.Products = DimensionOfProduction.Products
	|	AND Dimension.Characteristic = DimensionOfProduction.Characteristic
	|	AND Dimension.Series = DimensionOfProduction.Series
	|	AND &Contract = DimensionOfProduction.StorageLocation
	|	AND ProductionLots.Purpose = DimensionOfProduction.Purpose
	|	AND GoodsTable.ProductCostElement = DimensionOfProduction.ProductCostElement
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS ProductionAnalyticsWithoutAssignment
	|	ON Dimension.Products = ProductionAnalyticsWithoutAssignment.Products
	|	AND Dimension.Characteristic = ProductionAnalyticsWithoutAssignment.Characteristic
	|	AND Dimension.Series = ProductionAnalyticsWithoutAssignment.Series
	|	AND &Contract = ProductionAnalyticsWithoutAssignment.StorageLocation
	|	AND &EmptyDestinationLink = ProductionAnalyticsWithoutAssignment.Purpose
	|	AND GoodsTable.ProductCostElement = ProductionAnalyticsWithoutAssignment.ProductCostElement
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|GROUP BY
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.CostGroupNumber,
	|	AnalyticsWithoutAssignment.DimensionKey,
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber,
	|	CASE
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|	END,
	|	ProductionLots.ProductionLot,
	|	ProductionLots.ReleaseParty,
	|	ProductionLots.ProductsGroup,
	|	ProductionLots.VATActivityType,
	|	CASE
	|		WHEN Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN ISNULL(ProductionAnalyticsWithoutAssignment.DimensionKey, UNDEFINED)
	|		ELSE ISNULL(DimensionOfProduction.DimensionKey, UNDEFINED)
	|	END,
	|	ISNULL(ProductionAnalyticsWithoutAssignment.DimensionKey, UNDEFINED),
	|	GoodsTable.ProductCostElement,
	|	GoodsTable.ProductionStage,
	|	GoodsTable.FinRecordID,
	|	GoodsTable.RowID
	|";
	
EndFunction

Function QueryTextTTTypesOfProductStocks()
	
	Return
	"SELECT
	|	GoodsTable.ItemsLocationAttributes                        AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey                            AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	CASE
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners)
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingTransferredToPartners)
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		  OR GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|	END                                                           AS AccountingSection,
	|	GoodsTable.InventoryOwnerAttribute                                        AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber                                          AS CCDNumber,
	|	ProductionLots.ProductionLot                           AS ProductionLot,
	|	ProductionLots.ReleaseParty                                AS ReleaseParty,
	|	GoodsTable.Count                                        AS Count,
	|	CAST(GoodsTable.Sum * &ConversionRateToManCurrency  AS NUMBER(31,2)) AS Cost,
	|	CAST(GoodsTable.Sum * &ConversionRateToManCurrency  AS NUMBER(31,2)) AS CostExcludingVAT,
	|	CAST(GoodsTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalCost,
	|	0                                                               AS VATAmount,
	|	0                                                               AS VATManag,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN CAST(GoodsTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0
	|	END                                                           AS CostMan,
	|	CASE
	|		WHEN GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|			AND ISNULL(GoodsTable.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
	|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN GoodsTable.ItemsLocationAttributes.Purpose.VATActivityType
	|		WHEN GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|			THEN &PurchaseForActivity
	|		ELSE ProductionLots.VATActivityType
	|	END                                                           AS VATActivityType,
	|	GoodsTable.BusinessOperation                             AS BusinessOperation,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress) AS CorAccountingSection,
	|	CASE
	|		WHEN Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN ISNULL(ProductionAnalyticsWithoutAssignment.DimensionKey, UNDEFINED)
	|		ELSE ISNULL(DimensionOfProduction.DimensionKey, UNDEFINED)
	|	END                                                           AS CorItemsLocationAttributes,
	|	ISNULL(ProductionAnalyticsWithoutAssignment.DimensionKey, UNDEFINED) AS CorAnalysisOfAccountingForProductsWithoutAssignment,
	|	GoodsTable.ProductCostElement                                 AS ProductCostElement,
	|	ProductionLots.ProductsGroup                              AS ProductsGroup,
	|	CASE
	|		WHEN &AnalyticalAccountingByProductsGroups
	|			AND NOT Dimension.Products.AnalyticalGroup =
	|				VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN Dimension.Products.AnalyticalGroup
	|		ELSE UNDEFINED
	|	END                                                           AS CorGroupOfManufacturedProducts,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes                 AS LotVendorAttributes,
	|	GoodsTable.ProductionStage                                  AS ProductionStage,
	|	CASE
	|		WHEN GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|			AND GoodsTable.CostShare = 0
	|			THEN GoodsTable.Count
	|		ELSE GoodsTable.CostShare
	|	END                                                           AS CostShare,
	|	CASE
	|		WHEN GoodsTable.Recipient = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN &Department
	|		ELSE GoodsTable.Recipient
	|	END                                                           AS Department,
	|	GoodsTable.ToExpenseAs                                  AS ToExpenseAs,
	|	GoodsTable.ExpenseItem                                    AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses                                 AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension                          AS AssetsLiabilitiesDimension,
	|	GoodsTable.GLAccountSettings                              AS GLAccountSettings,
	|	GoodsTable.RowID                               AS RowID,
	|	GoodsTable.CostGroupNumber                                 AS CostGroupNumber,
	|	GoodsTable.FinRecordID                            AS FinRecordID,
	|	CASE
	|		WHEN GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ProductsRelease)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseFixCost)
	|	END AS BusinessTransactionSetting
	|FROM
	|	Document.SubcontractorReport2_5.InventoryOwnerAttributesProducts AS GoodsTable
	|	
	|	INNER JOIN TTBatchProduction AS ProductionLots
	|	ON GoodsTable.Ref = ProductionLots.ReleaseParty
	|	AND GoodsTable.CostGroupNumber = ProductionLots.CostGroupNumber
	|	
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON GoodsTable.ItemsLocationAttributes = Dimension.Ref
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|	AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|	AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|	AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|	AND &EmptyDestinationLink = AnalyticsWithoutAssignment.Purpose
	|	AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionOfProduction
	|	ON Dimension.Products = DimensionOfProduction.Products
	|	AND Dimension.Characteristic = DimensionOfProduction.Characteristic
	|	AND Dimension.Series = DimensionOfProduction.Series
	|	AND &Contract = DimensionOfProduction.StorageLocation
	|	AND ProductionLots.Purpose = DimensionOfProduction.Purpose
	|	AND GoodsTable.ProductCostElement = DimensionOfProduction.ProductCostElement
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS ProductionAnalyticsWithoutAssignment
	|	ON Dimension.Products = ProductionAnalyticsWithoutAssignment.Products
	|	AND Dimension.Characteristic = ProductionAnalyticsWithoutAssignment.Characteristic
	|	AND Dimension.Series = ProductionAnalyticsWithoutAssignment.Series
	|	AND &Contract = ProductionAnalyticsWithoutAssignment.StorageLocation
	|	AND &EmptyDestinationLink = ProductionAnalyticsWithoutAssignment.Purpose
	|	AND GoodsTable.ProductCostElement = ProductionAnalyticsWithoutAssignment.ProductCostElement
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= GoodsTable.LineNumber
	|	AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Products_1""
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|";
	
EndFunction

Function RequestTextTTTypesOfInventoryWorkMaterials()
	
	Return
	"SELECT
	|	GoodsTable.ItemsLocationAttributes                        AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey                            AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) AS AccountingSection,
	|	UNDEFINED                                                    AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)                     AS CCDNumber,
	|	ProductionLots.ProductionLot                           AS ProductionLot,
	|	ProductionLots.ReleaseParty                                AS ReleaseParty,
	|	SUM(GoodsTable.Count)                                 AS Count,
	|	0                                                               AS Cost,
	|	0                                                               AS CostExcludingVAT,
	|	0                                                               AS LocalCost,
	|	0                                                               AS VATAmount,
	|	0                                                               AS VATManag,
	|	0                                                               AS CostMan,
	|	ProductionLots.VATActivityType                           AS VATActivityType,
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots) AS BusinessOperation,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress) AS CorAccountingSection,
	|	ISNULL(DimensionOfProduction.DimensionKey, UNDEFINED)              AS CorItemsLocationAttributes,
	|	ISNULL(ProductionAnalyticsWithoutAssignment.DimensionKey, UNDEFINED) AS CorAnalysisOfAccountingForProductsWithoutAssignment,
	|	GoodsTable.ProductCostElement                                 AS ProductCostElement,
	|	ProductionLots.ProductsGroup                              AS ProductsGroup,
	|	UNDEFINED                                                    AS CorGroupOfManufacturedProducts,
	|	UNDEFINED                                                    AS LotVendorAttributes,
	|	GoodsTable.ProductionStage                                  AS ProductionStage,
	|	0                                                               AS CostShare,
	|	&Department                                                  AS Department,
	|	FALSE                                                            AS ToExpenseAs,
	|	UNDEFINED                                                    AS ExpenseItem,
	|	UNDEFINED                                                    AS DimensionOfExpenses,
	|	UNDEFINED                                                    AS AssetsLiabilitiesDimension,
	|	UNDEFINED                                                    AS GLAccountSettings,
	|	GoodsTable.RowID                               AS RowID,
	|	GoodsTable.CostGroupNumber                                 AS CostGroupNumber,
	|	GoodsTable.RowID                               AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ExpensingToProductionLots) AS BusinessTransactionSetting
	|FROM
	|	Document.SubcontractorReport2_5.MaterialsAndWorks AS GoodsTable
	|	
	|	INNER JOIN TTBatchProduction AS ProductionLots
	|	ON GoodsTable.Ref = ProductionLots.ReleaseParty
	|	AND GoodsTable.CostGroupNumber = ProductionLots.CostGroupNumber
	|	
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON GoodsTable.ItemsLocationAttributes = Dimension.Ref
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|	AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|	AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|	AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|	AND &EmptyDestinationLink = AnalyticsWithoutAssignment.Purpose
	|	AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionOfProduction
	|	ON Dimension.Products = DimensionOfProduction.Products
	|	AND Dimension.Characteristic = DimensionOfProduction.Characteristic
	|	AND Dimension.Series = DimensionOfProduction.Series
	|	AND &Contract = DimensionOfProduction.StorageLocation
	|	AND ProductionLots.Purpose = DimensionOfProduction.Purpose
	|	AND GoodsTable.ProductCostElement = DimensionOfProduction.ProductCostElement
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS ProductionAnalyticsWithoutAssignment
	|	ON Dimension.Products = ProductionAnalyticsWithoutAssignment.Products
	|	AND Dimension.Characteristic = ProductionAnalyticsWithoutAssignment.Characteristic
	|	AND Dimension.Series = ProductionAnalyticsWithoutAssignment.Series
	|	AND &Contract = ProductionAnalyticsWithoutAssignment.StorageLocation
	|	AND &EmptyDestinationLink = ProductionAnalyticsWithoutAssignment.Purpose
	|	AND GoodsTable.ProductCostElement = ProductionAnalyticsWithoutAssignment.ProductCostElement
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND GoodsTable.ItemsLocationAttributes NOT IN
	|		(SELECT DISTINCT
	|			InventoryKinds.ItemsLocationAttributes
	|		FROM
	|			Document.SubcontractorReport2_5.InventoryOwnerAttributesMaterials AS InventoryKinds
	|		WHERE
	|			InventoryKinds.Ref = &Ref)
	|
	|GROUP BY
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.CostGroupNumber,
	|	AnalyticsWithoutAssignment.DimensionKey,
	|	ProductionLots.ProductionLot,
	|	ProductionLots.ReleaseParty,
	|	ProductionLots.ProductsGroup,
	|	ProductionLots.VATActivityType,
	|	ISNULL(DimensionOfProduction.DimensionKey, UNDEFINED),
	|	ISNULL(ProductionAnalyticsWithoutAssignment.DimensionKey, UNDEFINED),
	|	GoodsTable.ProductCostElement,
	|	GoodsTable.ProductionStage,
	|	GoodsTable.RowID
	|";
	
EndFunction

Function RequestTextTTTypesOfWorkStocksOutputProducts()
	
	Return
	"SELECT
	|	GoodsTable.ItemsLocationAttributes                        AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey                            AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) AS AccountingSection,
	|	UNDEFINED                                                    AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)                     AS CCDNumber,
	|	ProductionLots.ProductionLot                           AS ProductionLot,
	|	ProductionLots.ReleaseParty                                AS ReleaseParty,
	|	GoodsTable.Count                                        AS Count,
	|	CAST(GoodsTable.Sum * &ConversionRateToManCurrency  AS NUMBER(31,2)) AS Cost,
	|	CAST(GoodsTable.Sum * &ConversionRateToManCurrency  AS NUMBER(31,2)) AS CostExcludingVAT,
	|	CAST(GoodsTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalCost,
	|	0                                                               AS VATAmount,
	|	0                                                               AS VATManag,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN CAST(GoodsTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0
	|	END                                                           AS CostMan,
	|	CASE
	|		WHEN ISNULL(GoodsTable.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
	|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN GoodsTable.ItemsLocationAttributes.Purpose.VATActivityType
	|		ELSE &PurchaseForActivity
	|	END                                                           AS VATActivityType,
	|	VALUE(Enum.BusinessTransactions.ProductsRelease)    AS BusinessOperation,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress) AS CorAccountingSection,
	|	UNDEFINED                                                    AS CorItemsLocationAttributes,
	|	UNDEFINED                                                    AS CorAnalysisOfAccountingForProductsWithoutAssignment,
	|	UNDEFINED                                                    AS ProductCostElement,
	|	ProductionLots.ProductsGroup                              AS ProductsGroup,
	|	CASE
	|		WHEN &AnalyticalAccountingByProductsGroups
	|			AND NOT GoodsTable.Products.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN GoodsTable.Products.AnalyticalGroup
	|		ELSE
	|			UNDEFINED
	|	END                                                           AS CorGroupOfManufacturedProducts,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes                 AS LotVendorAttributes,
	|	GoodsTable.ProductionStage                                  AS ProductionStage,
	|	CASE
	|		WHEN GoodsTable.CostShare = 0
	|			THEN GoodsTable.Count
	|		ELSE GoodsTable.CostShare
	|	END                                                           AS CostShare,
	|	CASE
	|		WHEN GoodsTable.Recipient = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN &Department
	|		ELSE GoodsTable.Recipient
	|	END                                                           AS Department,
	|	GoodsTable.ToExpenseAs                                  AS ToExpenseAs,
	|	GoodsTable.ExpenseItem                                    AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses                                 AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension                          AS AssetsLiabilitiesDimension,
	|	GoodsTable.GLAccountSettings                              AS GLAccountSettings,
	|	GoodsTable.RowID                               AS RowID,
	|	GoodsTable.CostGroupNumber                                 AS CostGroupNumber,
	|	GoodsTable.RowID                               AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsRelease) AS BusinessTransactionSetting
	|FROM
	|	Document.SubcontractorReport2_5.ManufacturedProducts AS GoodsTable
	|	
	|	INNER JOIN TTBatchProduction AS ProductionLots
	|	ON GoodsTable.Ref = ProductionLots.ReleaseParty
	|	AND GoodsTable.CostGroupNumber = ProductionLots.CostGroupNumber
	|
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON GoodsTable.ItemsLocationAttributes = Dimension.Ref
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|	AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|	AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|	AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|	AND &EmptyDestinationLink = AnalyticsWithoutAssignment.Purpose
	|	AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber      = GoodsTable.LineNumber
	|	AND TableOfBatchAccountingAnalysts.TabularSectionName = ""ManufacturedProducts""
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND GoodsTable.ItemsLocationAttributes NOT IN
	|		(SELECT DISTINCT
	|			InventoryKinds.ItemsLocationAttributes
	|		FROM
	|			Document.SubcontractorReport2_5.InventoryOwnerAttributesProducts AS InventoryKinds
	|		WHERE
	|			InventoryKinds.Ref = &Ref)
	|";
	
EndFunction

Function RequestTextTTTypesOfInventoryWorkByProducts()
	
	Return
	"SELECT
	|	GoodsTable.ItemsLocationAttributes                        AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey                            AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller) AS AccountingSection,
	|	UNDEFINED                                                    AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)                     AS CCDNumber,
	|	ProductionLots.ProductionLot                           AS ProductionLot,
	|	ProductionLots.ReleaseParty                                AS ReleaseParty,
	|	GoodsTable.Count                                        AS Count,
	|	CAST(GoodsTable.Sum * &ConversionRateToManCurrency  AS NUMBER(31,2)) AS Cost,
	|	CAST(GoodsTable.Sum * &ConversionRateToManCurrency  AS NUMBER(31,2)) AS CostExcludingVAT,
	|	CAST(GoodsTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalCost,
	|	0                                                               AS VATAmount,
	|	0                                                               AS VATManag,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN CAST(GoodsTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0
	|	END                                                           AS CostMan,
	|	ProductionLots.VATActivityType                           AS VATActivityType,
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) AS BusinessOperation,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress) AS CorAccountingSection,
	|	ISNULL(DimensionOfProduction.DimensionKey, UNDEFINED)              AS CorItemsLocationAttributes,
	|	ISNULL(ProductionAnalyticsWithoutAssignment.DimensionKey, UNDEFINED) AS CorAnalysisOfAccountingForProductsWithoutAssignment,
	|	GoodsTable.ProductCostElement                                 AS ProductCostElement,
	|	ProductionLots.ProductsGroup                              AS ProductsGroup,
	|	CASE
	|		WHEN &BatchAccountingVersion22
	|			AND &AnalyticalAccountingByProductsGroups
	|			AND NOT GoodsTable.Products.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN GoodsTable.Products.AnalyticalGroup
	|		ELSE
	|			UNDEFINED
	|	END                                                           AS CorGroupOfManufacturedProducts,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes                 AS LotVendorAttributes,
	|	GoodsTable.ProductionStage                                  AS ProductionStage,
	|	0                                                               AS CostShare,
	|	CASE 
	|		WHEN GoodsTable.Recipient = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN &Department
	|		ELSE GoodsTable.Recipient
	|	END                                                           AS Department,
	|	GoodsTable.ToExpenseAs                                  AS ToExpenseAs,
	|	GoodsTable.ExpenseItem                                    AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses                                 AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension                          AS AssetsLiabilitiesDimension,
	|	GoodsTable.GLAccountSettings                              AS GLAccountSettings,
	|	GoodsTable.RowID                               AS RowID,
	|	GoodsTable.CostGroupNumber                                 AS CostGroupNumber,
	|	GoodsTable.RowID                               AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseFixCost) AS BusinessTransactionSetting
	|FROM
	|	Document.SubcontractorReport2_5.SideAndIntermediateRelease AS GoodsTable
	|	
	|	INNER JOIN TTBatchProduction AS ProductionLots
	|	ON GoodsTable.Ref = ProductionLots.ReleaseParty
	|	AND GoodsTable.CostGroupNumber = ProductionLots.CostGroupNumber
	|	
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON GoodsTable.ItemsLocationAttributes = Dimension.Ref
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|	AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|	AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|	AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|	AND &EmptyDestinationLink = AnalyticsWithoutAssignment.Purpose
	|	AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionOfProduction
	|	ON Dimension.Products = DimensionOfProduction.Products
	|	AND Dimension.Characteristic = DimensionOfProduction.Characteristic
	|	AND Dimension.Series = DimensionOfProduction.Series
	|	AND &Contract = DimensionOfProduction.StorageLocation
	|	AND ProductionLots.Purpose = DimensionOfProduction.Purpose
	|	AND GoodsTable.ProductCostElement = DimensionOfProduction.ProductCostElement
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS ProductionAnalyticsWithoutAssignment
	|	ON Dimension.Products = ProductionAnalyticsWithoutAssignment.Products
	|	AND Dimension.Characteristic = ProductionAnalyticsWithoutAssignment.Characteristic
	|	AND Dimension.Series = ProductionAnalyticsWithoutAssignment.Series
	|	AND &Contract = ProductionAnalyticsWithoutAssignment.StorageLocation
	|	AND &EmptyDestinationLink = ProductionAnalyticsWithoutAssignment.Purpose
	|	AND GoodsTable.ProductCostElement = ProductionAnalyticsWithoutAssignment.ProductCostElement
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber      = GoodsTable.LineNumber
	|	AND TableOfBatchAccountingAnalysts.TabularSectionName = ""SideAndIntermediateRelease""
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND GoodsTable.ItemsLocationAttributes NOT IN
	|		(SELECT DISTINCT
	|			InventoryKinds.ItemsLocationAttributes
	|		FROM
	|			Document.SubcontractorReport2_5.InventoryOwnerAttributesProducts AS InventoryKinds
	|		WHERE
	|			InventoryKinds.Ref = &Ref)
	|";
	
EndFunction

Function RequestTextTTTypesOfInventoryServices()
	
	Return
	"SELECT
	|	DimensionOfProduction.Ref                                    AS ItemsLocationAttributes,
	|	ProductionAnalyticsWithoutAssignment.DimensionKey                AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress) AS AccountingSection,
	|	UNDEFINED                                                    AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)                     AS CCDNumber,
	|	ProductionLots.ProductionLot                           AS ProductionLot,
	|	ProductionLots.ReleaseParty                                AS ReleaseParty,
	|	SUM(GoodsTable.Count)                                 AS Count,
	|	SUM(ISNULL(Amounts.AmountIncludingVATMan, 0))                          AS Cost,
	|	SUM(ISNULL(Amounts.AmountExcludingVATMan, 0))                        AS CostExcludingVAT,
	|	SUM(ISNULL(Amounts.AmountExcludingVATCompl, 0))                       AS LocalCost,
	|	SUM(ISNULL(Amounts.VATAmountCompl, 0))                          AS VATAmount,
	|	SUM(ISNULL(Amounts.VATAmountMan, 0))                           AS VATManag,
	|	SUM(ISNULL(Amounts.AmountExcludingVATMan, 0))                        AS CostMan,
	|	ProductionLots.VATActivityType  AS VATActivityType,
	|	VALUE(Enum.BusinessTransactions.PurchaseFromSupplier) AS BusinessOperation,
	|	UNDEFINED                                                    AS CorAccountingSection,
	|	UNDEFINED                                                    AS CorItemsLocationAttributes,
	|	UNDEFINED                                                    AS CorAnalysisOfAccountingForProductsWithoutAssignment,
	|	GoodsTable.ProductCostElement                                 AS ProductCostElement,
	|	ProductionLots.ProductsGroup                              AS ProductsGroup,
	|	UNDEFINED                                                    AS CorGroupOfManufacturedProducts,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes                 AS LotVendorAttributes,
	|	GoodsTable.ProductionStage                                  AS ProductionStage,
	|	0                                                               AS CostShare,
	|	&Department                                                  AS Department,
	|	FALSE                                                            AS ToExpenseAs,
	|	UNDEFINED                                                    AS ExpenseItem,
	|	UNDEFINED                                                    AS DimensionOfExpenses,
	|	UNDEFINED                                                    AS AssetsLiabilitiesDimension,
	|	UNDEFINED                                                    AS GLAccountSettings,
	|	GoodsTable.RowID                               AS RowID,
	|	GoodsTable.CostGroupNumber                                 AS CostGroupNumber,
	|	GoodsTable.ARAPObject.UUID            AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier) AS BusinessTransactionSetting
	|FROM
	|	Document.SubcontractorReport2_5.Services AS GoodsTable
	|
	|	INNER JOIN TTBatchProduction AS ProductionLots
	|	ON GoodsTable.Ref = ProductionLots.ReleaseParty
	|	AND GoodsTable.CostGroupNumber = ProductionLots.CostGroupNumber
	|	
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfProduction
	|	ON GoodsTable.ItemsLocationAttributes = DimensionOfProduction.Ref
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS ProductionAnalyticsWithoutAssignment
	|	ON DimensionOfProduction.Products = ProductionAnalyticsWithoutAssignment.Products
	|	AND DimensionOfProduction.Characteristic = ProductionAnalyticsWithoutAssignment.Characteristic
	|	AND DimensionOfProduction.Series = ProductionAnalyticsWithoutAssignment.Series
	|	AND DimensionOfProduction.StorageLocation = ProductionAnalyticsWithoutAssignment.StorageLocation
	|	AND &EmptyDestinationLink = ProductionAnalyticsWithoutAssignment.Purpose
	|	AND GoodsTable.ProductCostElement = ProductionAnalyticsWithoutAssignment.ProductCostElement
	|	
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = GoodsTable.Ref
	|	AND Amounts.RowID = GoodsTable.RowID
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= GoodsTable.LineNumber
	|	AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Services""
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|GROUP BY
	|	GoodsTable.ItemsLocationAttributes,
	|	ProductionLots.ProductionLot,
	|	ProductionLots.ReleaseParty,
	|	ProductionLots.ProductsGroup,
	|	ProductionLots.VATActivityType,
	|	DimensionOfProduction.Ref,
	|	ProductionAnalyticsWithoutAssignment.DimensionKey,
	|	GoodsTable.ProductCostElement,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes,
	|	GoodsTable.ProductionStage,
	|	GoodsTable.CostGroupNumber,
	|	GoodsTable.RowID,
	|	GoodsTable.ARAPObject.UUID
	|";
	
EndFunction

#EndRegion

#EndRegion

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText =
	"SELECT
	|	&Period                     AS Period,
	|	SeriesTable.Products   AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                       AS Purpose,
	|	SeriesTable.Series          AS Series,
	|	&Ref                     AS Document,
	|	&Partner                    AS Sender,
	|	&Partner                    AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.ManufactureOfProducts) AS WarehouseOperation,
	|	FALSE                        AS ThisIsWarehouseRecord,
	|	SeriesTable.Count     AS Count
	|FROM
	|	Document.SubcontractorReport2_5.ManufacturedProducts AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                     AS Period,
	|	SeriesTable.Products   AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                       AS Purpose,
	|	SeriesTable.Series          AS Series,
	|	&Ref                     AS Document,
	|	&Partner                    AS Sender,
	|	&Partner                    AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.ManufactureOfProducts) AS WarehouseOperation,
	|	FALSE                        AS ThisIsWarehouseRecord,
	|	SeriesTable.Count     AS Count
	|FROM
	|	Document.SubcontractorReport2_5.SideAndIntermediateRelease AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                     AS Period,
	|	SeriesTable.Products   AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                       AS Purpose,
	|	SeriesTable.Series          AS Series,
	|	&Ref                     AS Document,
	|	&Partner                    AS Sender,
	|	&Partner                    AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.MovementInFinancialAccounting) AS WarehouseOperation,
	|	FALSE                        AS ThisIsWarehouseRecord,
	|	SeriesTable.Count     AS Count
	|FROM
	|	Document.SubcontractorReport2_5.MaterialsAndWorks AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsProductsProducts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                                              AS Period,
	|	InventoryKinds.BusinessOperation                    AS BusinessOperation,
	|	&Organization                                         AS Organization,
	|	&Department                                       AS Department,
	|	CASE
	|		WHEN NOT &KeepRecordsOfInventoryCostByAssignments
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.ItemsLocationAttributes.Purpose.LineOfBusiness
	|	END                                                AS LineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN InventoryKinds.ItemsLocationAttributes
	|		ELSE InventoryKinds.AnalysisOfAccountingForProductsWithoutAssignment
	|	END                                                AS ItemsLocationAttributes,
	|	InventoryKinds.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	CASE
	|		WHEN InventoryKinds.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN InventoryKinds.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType
	|		ELSE InventoryKinds.InventoryOwnerAttribute.InventoryType
	|	END                                                AS InventoryType,
	|	CASE
	|		WHEN InventoryKinds.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN InventoryKinds.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE InventoryKinds.InventoryOwnerAttribute
	|	END                                                AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN NOT &KeepRecordsOfInventoryCostByAssignments
	|			THEN UNDEFINED
	|		WHEN InventoryKinds.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|			THEN InventoryKinds.ItemsLocationAttributes.Purpose.LineOfBusiness
	|		ELSE InventoryKinds.CorItemsLocationAttributes.Purpose.LineOfBusiness
	|	END                                                AS CorLineOfBusiness,
	|	CASE
	|		WHEN InventoryKinds.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|			AND &KeepRecordsOfInventoryCostByAssignments
	|			THEN InventoryKinds.ItemsLocationAttributes
	|		WHEN InventoryKinds.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|			THEN InventoryKinds.AnalysisOfAccountingForProductsWithoutAssignment
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN InventoryKinds.CorItemsLocationAttributes
	|		ELSE InventoryKinds.CorAnalysisOfAccountingForProductsWithoutAssignment
	|	END                                                AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN InventoryKinds.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|			THEN InventoryKinds.ItemsLocationAttributes.StorageLocation
	|		ELSE InventoryKinds.CorItemsLocationAttributes.StorageLocation
	|	END                                                AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryType                    AS CorInventoryType,
	|	InventoryKinds.InventoryOwnerAttribute                               AS CorInventoryOwnerAttribute,
	|
	|	InventoryKinds.Count                               AS Count,
	|	InventoryKinds.Count                               AS CorQuantity,
	|
	|	InventoryKinds.Cost                                AS Cost,
	|	InventoryKinds.CostExcludingVAT                          AS CostExcludingVAT,
	|	InventoryKinds.LocalCost                            AS LocalCost,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN InventoryKinds.InventoryOwnerAttribute
	|		ELSE InventoryKinds.ItemsLocationAttributes.Products
	|	END                                                AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN InventoryKinds.InventoryOwnerAttribute
	|		ELSE InventoryKinds.ItemsLocationAttributes.Products
	|	END                                                AS CorSourceOfItemsFinancialAccountingGroup,
	|	UNDEFINED                                         AS DocumentRegisterRecords,
	|	UNDEFINED                                         AS CorCompany
	|FROM
	|	TTTypesOfStocks AS InventoryKinds
	|WHERE
	|	NOT InventoryKinds.ItemsLocationAttributes =
	|			InventoryKinds.CorItemsLocationAttributes
	|	AND NOT InventoryKinds.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTablePurchases(Query, QueryTexts, Registers)
	
	RegisterName = "Purchases";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	InitializeProductAnalysisKeys(Query);
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.PurchaseFromSupplier) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|
	|	TableServices.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CASE
	|		WHEN &AccountingForLBCosts
	|			THEN &LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS ProductLineOfBusiness,
	|	&Department AS Warehouse,
	|	UNDEFINED AS InventoryType,
	|	UNDEFINED AS InventoryOwnerAttribute,
	|
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB
	|			THEN &LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS CounterpartyLineOfBusiness,
	|	UNDEFINED AS Terms,
	|	&Contract AS Contract,
	|	CASE
	|		WHEN &ByOrders
	|			THEN TableServices.SubcontractOrder
	|		ELSE &Ref
	|	END AS OrderDocument,
	|	UNDEFINED AS AdvanceHolder,
	|
	|	SUM(TableServices.Count) AS Count,
	|
	|	SUM(ISNULL(Amounts.AmountIncludingVATMan, 0)) AS Sum,
	|	SUM(ISNULL(Amounts.AmountExcludingVATMan, 0)) AS AmountExcludingVAT,
	|	SUM(ISNULL(Amounts.AmountExcludingVATCompl, 0) + ISNULL(Amounts.VATAmountCompl, 0)) AS SumCompl,
	|	SUM(ISNULL(Amounts.AmountExcludingVATCompl, 0)) AS LocalAmountExcludingVAT,
	|	0 AS DiscountAmount,
	|
	|	SUM(ISNULL(Amounts.AmountIncludingVATMan, 0)) AS Cost,
	|	SUM(ISNULL(Amounts.AmountExcludingVATMan, 0)) AS CostExcludingVAT,
	|	SUM(CASE
	|		WHEN &PurchaseForActivity IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN ISNULL(Amounts.AmountIncludingVATCompl, 0)
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0)
	|	END) AS LocalCost,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|
	|	&Currency AS DocumentCurrency,
	|	SUM(TableServices.AmountIncludingVAT) AS AmountInDocumentCurrency,
	|	SUM(TableServices.AmountIncludingVAT - TableServices.VATAmount) AS AmountExcludingVATInDocumentCurrency,
	|
	|	&ARAPCurrency AS ARAPCurrency,
	|	SUM(TableServices.AmountARAP) AS AmountInARAPCurrency,
	|	SUM(TableServices.AmountARAP - TableServices.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	TableServices.Products AS SourceOfProductFinancialAccountingGroup,
	|	TableServices.ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	Document.SubcontractorReport2_5.Services AS TableServices
	|	
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = TableServices.Ref
	|	AND Amounts.RowID = TableServices.RowID
	|	
	|WHERE
	|	TableServices.Ref = &Ref
	|
	|GROUP BY
	|	TableServices.ItemsLocationAttributes,
	|	CASE
	|		WHEN &AccountingForLBCosts
	|			THEN &LineOfBusiness
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB
	|			THEN &LineOfBusiness
	|		ELSE UNDEFINED
	|	END,
	|	CASE
	|		WHEN &ByOrders
	|			THEN TableServices.SubcontractOrder
	|		ELSE &Ref
	|	END,
	|	TableServices.Products,
	|	TableServices.ARAPObject
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	GoodsTable.LineNumber                AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)   AS RecordType,
	|	&Period                                  AS Period,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&Organization                             AS Organization,
	|	GoodsTable.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber                   AS CCDNumber,
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots) AS BusinessOperation,
	|	GoodsTable.Count                 AS Count,
	|	GoodsTable.QuantityByGBRN           AS QuantityByGBRN,
	|	0                                        AS ToRegisterGoodsIssue,
	|	0                                        AS ToRegisterGoodsIssueByProductBatchID
	|FROM
	|	Document.SubcontractorReport2_5.InventoryOwnerAttributesMaterials AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber                AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)   AS RecordType,
	|	&Period                                  AS Period,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&Organization                             AS Organization,
	|	GoodsTable.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber                   AS CCDNumber,
	|	GoodsTable.BusinessOperation      AS BusinessOperation,
	|	GoodsTable.Count                 AS Count,
	|	GoodsTable.QuantityByGBRN           AS QuantityByGBRN,
	|	0                                        AS ToRegisterGoodsIssue,
	|	0                                        AS ToRegisterGoodsIssueByProductBatchID
	|FROM
	|	Document.SubcontractorReport2_5.InventoryOwnerAttributesProducts AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.ToExpenseAs
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.SubcontractorReport2_5.PaymentScheduleSteps AS Table
		|		LEFT JOIN Document.SubcontractorReport2_5 AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.SubcontractorReport2_5.ARAPDetails AS Table
		|		LEFT JOIN Document.SubcontractorReport2_5 AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	ARAPObjects.Ref AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.SubcontractorReport2_5.ARAPDetails AS Table
		|		LEFT JOIN Document.SubcontractorReport2_5 AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON ARAPObjects.Object = Table.Ref
		|		AND ARAPObjects.Organization = Table.Ref.Organization
		|		AND NOT ARAPObjects.DeletionMark
		|WHERE
		|	Table.Ref IN (&Ref)
		|	
		// Direction of activity
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.SubcontractorReport2_5.Services AS Table
		|		LEFT JOIN Document.SubcontractorReport2_5 AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	(CASE
		|		WHEN DocumentDataHeader.ByOrders
		|			THEN DocumentDataHeader.SubcontractOrder.ARAPObject
		|		WHEN DocumentDataHeader.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN Table.ARAPObject.Contract.ARAPObject
		|		ELSE Table.ARAPObject
		|	END) AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.SubcontractorReport2_5.Services AS Table
		|		LEFT JOIN Document.SubcontractorReport2_5 AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region Purchase
	
	TextPurchase =
	"SELECT
	|	Table.Ref                       AS Ref,
	|	Table.Ref.Organization           AS Organization,
	|	Table.Ref.Partner               AS Partner,
	|	Table.Ref.Date                  AS RecorderDate,
	|	Table.Ref.Number                 AS RecorderNumber,
	|
	|	Table.ARAPObject               AS ARAPObject,
	|	Table.PaymentDate                  AS PaymentDate,
	|	UNDEFINED                         AS PaymentOption,
	|	Table.OrderDocument                        AS PurchaseOrder_,
	|	Table.PaymentAmount                 AS Sum,
	|	Table.AmountARAP          AS AmountARAP,
	|	0                                    AS AmountARAPByPackage,
	|
	|	Table.Ref.ARAPObjectSettings       AS ARAPObjectSettings,
	|	Table.Ref.ByOrders             AS InvoiceForOrders,
	|	Table.Ref.ARAPCurrency  AS ARAPCurrency,
	|	Table.Ref.BusinessOperation AS BusinessOperation,
	|	Table.Ref.PaymentMethod           AS PaymentMethod,
	|	Table.Ref.Currency                AS DocumentCurrency,
	|	Table.Ref.Date                  AS DateOfCourse,
	|	UNDEFINED                         AS LinkedDocument
	|FROM
	|	Document.SubcontractorReport2_5.PaymentScheduleSteps AS Table
	|WHERE
	|	Table.Ref IN (&Ref)
	|";
	
	#EndRegion
	
	#Region IncreasePaymentPlan_
	
	TextPaymentPlan_ =
	"SELECT
	|	Table.Ref                       AS Ref,
	|	Table.Ref.Organization           AS Organization,
	|	Table.Ref.Partner               AS Partner,
	|	Table.Ref.Date                  AS RecorderDate,
	|	Table.Ref.Number                 AS RecorderNumber,
	|	Table.PaymentDate                  AS PaymentDate,
	|	
	|	Table.ARAPObject               AS ARAPObject,
	|	Table.Ref.ARAPObjectSettings       AS ARAPObjectSettings,
	|	Table.Ref.ByOrders             AS InvoiceForOrders,
	|	Table.ExceedingOrder                  AS ExceedingOrder,
	|	Table.OrderDocument                        AS PurchaseOrder_,
	|	Table.AmountARAP          AS AmountDue,
	|	Table.Ref.ARAPCurrency  AS ARAPCurrency,
	|	Table.Ref.BusinessOperation AS BusinessOperation,
	|	Table.Ref.PaymentMethod           AS PaymentMethod,
	|	Table.Ref.Currency                AS DocumentCurrency,
	|	UNDEFINED                         AS PaymentOption,
	|	UNDEFINED                         AS LinkedDocument
	|FROM
	|	Document.SubcontractorReport2_5.PaymentScheduleSteps AS Table
	|WHERE
	|	Table.Ref IN (&Ref)
	|";

	#EndRegion
	
	#Region TextProducts_1
	
	TextProducts_1 =
	"SELECT
	|	Table.Ref                       AS Ref,
	|	Table.Ref.Organization           AS Organization,
	|	Table.Ref.Partner               AS Partner,
	|	Table.Ref.Date                  AS RecorderDate,
	|	Table.Ref.Number                 AS RecorderNumber,
	|	
	|	Table.ARAPObject               AS ARAPObject,
	|	Table.Ref.ARAPObjectSettings       AS ARAPObjectSettings,
	|	Table.Ref.ByOrders             AS InvoiceForOrders,
	|	Table.RowCode = 0                AS ExceedingOrder,
	|	Table.SubcontractOrder           AS PurchaseOrder_,
	|	Table.AmountARAP          AS ReduceToAdmission,
	|	Table.AmountARAP          AS AmountARAP,
	|	Table.AmountARAP          AS IncreaseToAdmission,
	|	Table.Ref.ARAPCurrency  AS ARAPCurrency,
	|	Table.Ref.BusinessOperation AS BusinessOperation,
	|	Table.Ref.Currency                AS DocumentCurrency
	|FROM
	|	Document.SubcontractorReport2_5.Services AS Table
	|WHERE
	|	Table.Ref IN (&Ref)
	|";
	
	#EndRegion
	
	#Region PrepaymentsSettlement
	
	TextAdvancePaymentOffset =
	"SELECT
	|	Table.Ref                      AS Ref,
	|	Table.Ref.Organization          AS Organization,
	|	Table.Ref.Partner              AS Partner,
	|
	|	ARAPObjects.Ref              AS CalculationObjectReceiver,
	|	Table.ARAPObject              AS CalculationObjectSource,
	|
	|	Table.Ref.ARAPCurrency AS ARAPCurrency,
	|	Table.AmountARAP         AS AmountARAP,
	|	Table.Ref.Currency               AS DocumentCurrency,
	|	Table.Sum                       AS Sum,
	|
	|	Table.Ref.Date                 AS RecorderDate,
	|	Table.Ref.Date                 AS DateOfCourse,
	|	Table.Ref.Number                AS RecorderNumber,
	|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment) AS BusinessOperation
	|	
	|FROM
	|	Document.SubcontractorReport2_5.ARAPDetails AS Table
	|	
	|	LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|	ON ARAPObjects.Object = Table.Ref
	|	AND ARAPObjects.Organization = Table.Ref.Organization
	|	AND NOT ARAPObjects.DeletionMark
	|
	|WHERE
	|	Table.Ref IN (&Ref)
	|	AND Table.ARAPObject.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|";
	
	#EndRegion
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(
		Query,
		QueryTexts,
		Registers,
		TextPurchase,
		TextPaymentPlan_,
		TextAdvancePaymentOffset,
		TextProducts_1);
	
EndProcedure

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""Services"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.ARAPCurrency AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.AmountARAP AS AmountARAP,
	|	DocumentTable.AmountVATARAP AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.SubcontractorReport2_5.Services AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.Sum <> 0
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Recipient AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	NOT TabPart.SubcontractOrder = VALUE(Document.SubcontractOrder2_5.EmptyRef)
		|	AND NOT TabPart.RowCode = 0 AS OnSchedule,
		|	TabPart.SubcontractOrder AS OrderInSchedule
		|FROM
		|	Document.SubcontractorReport2_5.ManufacturedProducts AS TabPart
		|WHERE
		|	NOT TabPart.ToExpenseAs
		|	AND TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Recipient AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	NOT TabPart.SubcontractOrder = VALUE(Document.SubcontractOrder2_5.EmptyRef)
		|	AND NOT TabPart.RowCode = 0 AS OnSchedule,
		|	TabPart.SubcontractOrder AS OrderInSchedule
		|FROM
		|	Document.SubcontractorReport2_5.SideAndIntermediateRelease AS TabPart
		|WHERE
		|	NOT TabPart.ToExpenseAs
		|	AND TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, False);
	
EndProcedure

Function QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers)
	
	RegisterName = "MaterialsAndWorksInProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)              AS RecordType,
	|	&Period                                             AS Period,
	|	&Period                                             AS RecorderDate,
	|	ProductTable.RowID                AS RowID,
	|	&Organization                                        AS Organization,
	|	ProductTable.Products                       AS Products,
	|	ProductTable.Characteristic                     AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	ProductTable.Purpose                         AS Purpose,
	|	CASE
	|		WHEN ProductTable.Recipient = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN &Department
	|		ELSE ProductTable.Recipient
	|	END                                               AS Department,
	|	ProductTable.Count                         AS Count
	|FROM
	|	Document.SubcontractorReport2_5.ManufacturedProducts AS ProductTable
	|WHERE
	|	ProductTable.Ref = &Ref
	|	AND ProductTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT ProductTable.ToExpenseAs
	|	AND NOT ProductTable.Products.TracedGoods
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)              AS RecordType,
	|	&Period                                             AS Period,
	|	&Period                                             AS RecorderDate,
	|	TableOfReturnableWaste.RowID        AS RowID,
	|	&Organization                                        AS Organization,
	|	TableOfReturnableWaste.Products               AS Products,
	|	TableOfReturnableWaste.Characteristic             AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	TableOfReturnableWaste.Purpose                 AS Purpose,
	|	CASE
	|		WHEN TableOfReturnableWaste.Recipient = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN &Department
	|		ELSE TableOfReturnableWaste.Recipient
	|	END                                               AS Department,
	|	TableOfReturnableWaste.Count                 AS Count
	|FROM
	|	Document.SubcontractorReport2_5.SideAndIntermediateRelease AS TableOfReturnableWaste
	|WHERE
	|	TableOfReturnableWaste.Ref = &Ref
	|	AND TableOfReturnableWaste.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT TableOfReturnableWaste.ToExpenseAs
	|	AND NOT TableOfReturnableWaste.Products.TracedGoods
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period                                AS Period,
	|	&Period                                AS RecorderDate,
	|	TabularSection.RowID     AS RowID,
	|	&Organization                           AS Organization,
	|	TabularSection.Products            AS Products,
	|	TabularSection.Characteristic          AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	CASE
	|		WHEN &GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|			THEN TabularSection.ProductionStage.Purpose
	|		WHEN TRUE
	|			THEN TabularSection.Purpose
	|	END                                  AS Purpose,
	|	&Department                         AS Department,
	|	TabularSection.Count              AS Count
	|FROM
	|	Document.SubcontractorReport2_5.MaterialsAndWorks AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND TabularSection.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT TabularSection.Products.TracedGoods
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref                    AS Ref,
	|	&Period                    AS IBDocumentDate,
	|	&Number                     AS IBDocumentNumber,
	|	&MetadataIdentifier   AS RefType,
	|	&Organization               AS Organization,
	|	&BusinessOperation     AS BusinessOperation,
	|	&Partner                   AS Partner,
	|	&Counterparty                AS Counterparty,
	|	&Contract                   AS Contract,
	|	&LineOfBusiness   AS LineOfBusiness,
	|	UNDEFINED               AS StorageLocation,
	|	&Department             AS Department,
	|	&Manager                  AS EmployeeResponsible,
	|	&Author                     AS Author,
	|	&Comment               AS Comment,
	|	&Currency                    AS Currency,
	|	&DocumentAmount            AS Sum,
	|	UNDEFINED               AS Status,
	|	&Posted                  AS Posted,
	|	&DeletionMark           AS DeletionMark,
	|	FALSE                       AS AdditionalRecord,
	|	&ContractInformation      AS More,
	|	&ExternalDocumentName AS SourceDocumentName,
	|	&IncomingDocumentDate    AS SourceDocumentDate,
	|	&IncomingDocumentNumber   AS SourceDocumentNumber,
	|	&Period                    AS RecordingInAccountingDate,
	|	UNDEFINED               AS Priority
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableProductsRelease(Query, QueryTexts, Registers)
	
	RegisterName = "ProductsRelease"; 
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period														AS Period,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN GoodsTable.ItemsLocationAttributes
	|		ELSE AnalyticsWithoutAssignment.DimensionKey
	|	END														AS ItemsLocationAttributes,
	|	&Organization												AS Organization,
	|	&Department												AS Department,
	|	GoodsTable.Count                                    AS Count,
	|	GoodsTable.InventoryOwnerAttribute                                    AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN GoodsTable.ToExpenseAs 
	|			THEN GoodsTable.ExpenseItem
	|		ELSE UNDEFINED
	|	END                                                       AS ExpenseItem,
	|	CASE
	|		WHEN GoodsTable.ToExpenseAs 
	|			THEN GoodsTable.DimensionOfExpenses
	|		ELSE UNDEFINED
	|	END                                                       AS DimensionOfExpenses,
	|	CASE
	|		WHEN GoodsTable.ToExpenseAs 
	|			THEN GoodsTable.AssetsLiabilitiesDimension
	|		ELSE UNDEFINED
	|	END                                                       AS AssetsLiabilitiesDimension
	|FROM
	|	Document.SubcontractorReport2_5.InventoryOwnerAttributesProducts AS GoodsTable
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON GoodsTable.ItemsLocationAttributes = Dimension.Ref
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|		AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|		AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period														AS Period,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN GoodsTable.ItemsLocationAttributes
	|		ELSE AnalyticsWithoutAssignment.DimensionKey
	|	END														AS ItemsLocationAttributes,
	|	&Organization												AS Organization,
	|	&Department												AS Department,
	|	GoodsTable.Count                                    AS Count,
	|	UNDEFINED                                                AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN GoodsTable.ToExpenseAs
	|			THEN GoodsTable.ExpenseItem
	|		ELSE UNDEFINED
	|	END                                                       AS ExpenseItem,
	|	CASE
	|		WHEN GoodsTable.ToExpenseAs
	|			THEN GoodsTable.DimensionOfExpenses
	|		ELSE UNDEFINED
	|	END                                                       AS DimensionOfExpenses,
	|	CASE
	|		WHEN GoodsTable.ToExpenseAs
	|			THEN GoodsTable.AssetsLiabilitiesDimension
	|		ELSE UNDEFINED
	|	END                                                       AS AssetsLiabilitiesDimension
	|FROM
	|	Document.SubcontractorReport2_5.ManufacturedProducts AS GoodsTable
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON GoodsTable.ItemsLocationAttributes = Dimension.Ref
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|		AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|		AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period														AS Period,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN GoodsTable.ItemsLocationAttributes
	|		ELSE AnalyticsWithoutAssignment.DimensionKey
	|	END														AS ItemsLocationAttributes,
	|	&Organization												AS Organization,
	|	&Department												AS Department,
	|	GoodsTable.Count                                    AS Count,
	|	UNDEFINED                                                AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN GoodsTable.ToExpenseAs
	|			THEN GoodsTable.ExpenseItem
	|		ELSE UNDEFINED
	|	END                                                       AS ExpenseItem,
	|	CASE
	|		WHEN GoodsTable.ToExpenseAs
	|			THEN GoodsTable.DimensionOfExpenses
	|		ELSE UNDEFINED
	|	END                                                       AS DimensionOfExpenses,
	|	CASE
	|		WHEN GoodsTable.ToExpenseAs
	|			THEN GoodsTable.AssetsLiabilitiesDimension
	|		ELSE UNDEFINED
	|	END                                                       AS AssetsLiabilitiesDimension
	|FROM
	|	Document.SubcontractorReport2_5.SideAndIntermediateRelease AS GoodsTable
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON GoodsTable.ItemsLocationAttributes = Dimension.Ref
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|		AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|		AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

#Region VATReflection

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBatchProduction", QueryTexts) Then
		QueryTextTTBatchProduction(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	If DocumentsPosting.RequiresTableForRegisteredRecords("GoodsForRegistrationOfImportDocuments", Registers) Then
		
		If Not DocumentsPosting.ThereIsQueryTable("TTDistributedInventoryTypes", QueryTexts) Then
			QueryTextTTDistributedInventoryTypes(Query, QueryTexts);
		EndIf;
	
		QueryTextTTGoodsImportApplications(Query, QueryTexts);
		
		TextProducts_1 = 
		"SELECT
		|	ProductsOfApplication.Ref AS Ref, 
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	ProductsOfApplication.Period AS Period,
		|	ProductsOfApplication.Organization AS Organization,
		|	ProductsOfApplication.Vendor AS Vendor,
		|	ProductsOfApplication.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	ProductsOfApplication.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	ProductsOfApplication.DocumentAcquisitions AS DocumentAcquisitions,
		|	ProductsOfApplication.ImportDocumentType AS ImportDocumentType,
		|	ProductsOfApplication.Count AS Count,
		|	0 AS QuantityByGBRN,
		|	ProductsOfApplication.Sum AS Sum,
		|	ProductsOfApplication.CCDNumber AS CCDNumber,
		|	ProductsOfApplication.RowID AS RowID
		|FROM
		|	TTProductsStatements AS ProductsOfApplication";
	
		ImportAccounting.ReflectImportOfGoodsFromCustomsUnionNewMechanics(Query, QueryTexts, Registers, TextProducts_1);
		
	EndIf;
	
	ValueText_ =
	"SELECT
	|	Services.Ref.Date                              AS Period,
	|	Services.Ref                                   AS Ref,
	|	Services.Ref.Organization                       AS Organization,
	|	Services.Ref.Department                     AS Department,
	|	Services.Ref.Department                     AS AccountingDivision,
	|	Services.Ref.Counterparty                        AS Counterparty,
	|	Services.Ref.Contract                           AS Contract,
	|	VALUE(Catalog.Counterparties.EmptyRef)   AS Shipper,
	|	Services.Ref                                   AS DocumentAcquisitions,
	|	Services.Ref                                   AS OriginalTradeDocument,
	|	FALSE                                            AS ErrorCorrection,
	|	FALSE                                            AS AdjustmentUnderApprovalOfParties,
	|	FALSE                                            AS ReduceAmountVATDeduction,
	|	UNDEFINED                                    AS PurchaseAdjustmentDocument,
	|	Services.Ref.VATTaxation                AS VATTaxation,
	|	TTBatchProduction.VATActivityType         AS VATActivityType,
	|	Services.VATRate                                AS VATRate,
	|	Services.Products                             AS Products,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)   AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)     AS CCDNumber,
	|	TTBatchProduction.LineOfBusiness    AS LineOfBusiness,
	|	TRUE                                          AS PurchasePerBatchOfProduction,
	|	TTBatchProduction.LineOfBusiness    AS LineOfBusinessOfProductionParty,
	|	UNDEFINED 									AS ToExpenseAs,
	|	UNDEFINED                                    AS ExpenseItem,
	|	UNDEFINED                                    AS DimensionOfExpenses,
	|	UNDEFINED                                    AS ItemOfOtherAssets,
	|	UNDEFINED                                    AS AnalyticsOfOtherAssets,
	|	TTBatchProduction.Purpose                 AS Purpose,
	|	Services.RowID                      AS RowID,
	|	Services.ItemsLocationAttributes               AS ItemsLocationAttributes,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	Services.ARAPObject.UUID   AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|FROM
	|	Document.SubcontractorReport2_5.Services AS Services
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber = Services.LineNumber
	|	AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Services""
	|
	|	INNER JOIN TTBatchProduction AS TTBatchProduction
	|	ON Services.Ref = TTBatchProduction.ReleaseParty
	|	AND Services.CostGroupNumber = TTBatchProduction.CostGroupNumber
	|
	|WHERE
	|	Services.Ref IN (&Ref)
	|";
	
	VATAccountingERP.ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

#EndRegion

Function QueryTextTablePurchaseOrders(Query, QueryTexts, Registers)
	
	RegisterName = "PurchaseOrders";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"
	// Output products (on orders)
	|SELECT
	|	TabularSection.LineNumber             AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period                                AS Period,
	|	TabularSection.SubcontractOrder      AS PurchaseOrder,
	|	TabularSection.Products            AS Products,
	|	TabularSection.Characteristic          AS Characteristic,
	|	TabularSection.RowCode               AS RowCode,
	|	TabularSection.Count              AS Ordered,
	|	TabularSection.Count              AS ToRegister,
	|	0                                      AS Sum
	|FROM
	|	Document.SubcontractorReport2_5.ManufacturedProducts AS TabularSection
	|
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND &ByOrders
	|	AND TabularSection.RowCode <> 0
	|
	|UNION ALL
	|
	// Output products (over the order, arrival)
	|SELECT
	|	TabularSection.LineNumber             AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	TabularSection.SubcontractOrder      AS PurchaseOrder,
	|	TabularSection.Products            AS Products,
	|	TabularSection.Characteristic          AS Characteristic,
	|	TabularSection.RowCode               AS RowCode,
	|	0                                      AS Ordered,
	|	TabularSection.Count              AS ToRegister,
	|	0                                      AS Sum
	|FROM
	|	Document.SubcontractorReport2_5.ManufacturedProducts AS TabularSection
	|
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND &ByOrders
	|	AND TabularSection.RowCode = 0
	|
	|UNION ALL
	|
	// Output products (over the order, consumption)
	|SELECT
	|	TabularSection.LineNumber             AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period                                AS Period,
	|	TabularSection.SubcontractOrder      AS PurchaseOrder,
	|	TabularSection.Products            AS Products,
	|	TabularSection.Characteristic          AS Characteristic,
	|	TabularSection.RowCode               AS RowCode,
	|	0                                      AS Ordered,
	|	TabularSection.Count              AS ToRegister,
	|	0                                      AS Sum
	|FROM
	|	Document.SubcontractorReport2_5.ManufacturedProducts AS TabularSection
	|
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND &ByOrders
	|	AND TabularSection.RowCode = 0
	|
	|UNION ALL
	|
	// By-products (on request)
	|SELECT
	|	TabularSection.LineNumber             AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period                                AS Period,
	|	TabularSection.SubcontractOrder      AS PurchaseOrder,
	|	TabularSection.Products            AS Products,
	|	TabularSection.Characteristic          AS Characteristic,
	|	TabularSection.RowCode               AS RowCode,
	|	TabularSection.Count              AS Ordered,
	|	TabularSection.Count              AS ToRegister,
	|	0                                      AS Sum
	|FROM
	|	Document.SubcontractorReport2_5.SideAndIntermediateRelease AS TabularSection
	|
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND &ByOrders
	|	AND TabularSection.RowCode <> 0
	|
	|UNION ALL
	|
	// By-products (over the order, arrival)
	|SELECT
	|	TabularSection.LineNumber             AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	TabularSection.SubcontractOrder      AS PurchaseOrder,
	|	TabularSection.Products            AS Products,
	|	TabularSection.Characteristic          AS Characteristic,
	|	TabularSection.RowCode               AS RowCode,
	|	0                                      AS Ordered,
	|	TabularSection.Count              AS ToRegister,
	|	0                                      AS Sum
	|FROM
	|	Document.SubcontractorReport2_5.SideAndIntermediateRelease AS TabularSection
	|
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND &ByOrders
	|	AND TabularSection.RowCode = 0
	|
	|UNION ALL
	|
	// By-products (over the order, expense)
	|SELECT
	|	TabularSection.LineNumber             AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period                                AS Period,
	|	TabularSection.SubcontractOrder      AS PurchaseOrder,
	|	TabularSection.Products            AS Products,
	|	TabularSection.Characteristic          AS Characteristic,
	|	TabularSection.RowCode               AS RowCode,
	|	0                                      AS Ordered,
	|	TabularSection.Count              AS ToRegister,
	|	0                                      AS Sum
	|FROM
	|	Document.SubcontractorReport2_5.SideAndIntermediateRelease AS TabularSection
	|
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND &ByOrders
	|	AND TabularSection.RowCode = 0
	|
	|UNION ALL
	|
	// Services (on request)
	|SELECT
	|	TabularSection.LineNumber             AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period                                AS Period,
	|	TabularSection.SubcontractOrder      AS PurchaseOrder,
	|	TabularSection.Products            AS Products,
	|	TabularSection.Characteristic          AS Characteristic,
	|	TabularSection.RowCode               AS RowCode,
	|	0                                      AS Ordered,
	|	TabularSection.Count              AS ToRegister,
	|	TabularSection.Sum                   AS Sum
	|FROM
	|	Document.SubcontractorReport2_5.Services AS TabularSection
	|
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND &ByOrders
	|	AND TabularSection.RowCode <> 0
	|
	|UNION ALL
	|
	// Services (over the order, arrival)
	|SELECT
	|	TabularSection.LineNumber             AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	TabularSection.SubcontractOrder      AS PurchaseOrder,
	|	TabularSection.Products            AS Products,
	|	TabularSection.Characteristic          AS Characteristic,
	|	TabularSection.RowCode               AS RowCode,
	|	0                                      AS Ordered,
	|	TabularSection.Count              AS ToRegister,
	|	TabularSection.Sum                   AS Sum
	|FROM
	|	Document.SubcontractorReport2_5.Services AS TabularSection
	|
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND &ByOrders
	|	AND TabularSection.RowCode = 0
	|
	|UNION ALL
	|
	// Services (over the order, expense)
	|SELECT
	|	TabularSection.LineNumber             AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period                                AS Period,
	|	TabularSection.SubcontractOrder      AS PurchaseOrder,
	|	TabularSection.Products            AS Products,
	|	TabularSection.Characteristic          AS Characteristic,
	|	TabularSection.RowCode               AS RowCode,
	|	0                                      AS Ordered,
	|	TabularSection.Count              AS ToRegister,
	|	TabularSection.Sum                   AS Sum
	|FROM
	|	Document.SubcontractorReport2_5.Services AS TabularSection
	|
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND &ByOrders
	|	AND TabularSection.RowCode = 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText =
	"SELECT
	|	TabularSection.LineNumber                                                        AS LineNumber,
	|	&Period                                                                           AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                            AS RecordType,
	|	&Organization                                                                      AS Organization,
	|	CASE
	|		WHEN TabularSection.Recipient = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN &Department
	|		ELSE TabularSection.Recipient
	|	END                	                                                          AS Department,
	|	TabularSection.ExpenseItem                                                     AS AssetRef,
	|	CASE
	|		WHEN TabularSection.AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE TabularSection.AssetsLiabilitiesDimension
	|	END                                                                             AS Dimension,
	|	CAST(TabularSection.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))  AS Sum
	|FROM
	|	Document.SubcontractorReport2_5.SideAndIntermediateRelease AS TabularSection
	|
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND TabularSection.ToExpenseAs
	|	AND VALUETYPE(TabularSection.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RegisterRecordsProductsIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
		"SELECT
		|	&Period																				AS Period,
		|	CASE
		|		WHEN TTTypesOfStocks.ExpenseItem.CostAllocationOptionLocal =
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
		|			THEN CASE
		|					WHEN TTTypesOfStocks.ExpenseItem.VATAssetTaxClass IN
		|							(VALUE(Enum.AssetKinds.FA),
		|							VALUE(Enum.AssetKinds.ConstructionInProgressObjects))
		|						THEN VALUE(Enum.BusinessTransactions.TransferToFixedAssets)
		|					WHEN TTTypesOfStocks.ExpenseItem.VATAssetTaxClass = VALUE(Enum.AssetKinds.IA)
		|						THEN VALUE(Enum.BusinessTransactions.TransferToIntangibleAssetsAndRD)
		|				END
		|		ELSE VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
		|	END																				AS BusinessOperation,
		|	&Organization																		AS Organization,
		|	TTTypesOfStocks.Department										                    AS Department,
		|	TTTypesOfStocks.ItemsLocationAttributes    								        AS ItemsLocationAttributes,
		|	CASE
		|		WHEN RecipientProductKeys.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN &Department
		|		ELSE &Partner
		|	END AS Warehouse,
		|	TTTypesOfStocks.InventoryOwnerAttribute															AS InventoryOwnerAttribute,
		|	TTTypesOfStocks.InventoryOwnerAttribute.InventoryType													AS InventoryType,
		|	TTTypesOfStocks.ExpenseItem														AS IncomeAndExpenseItem,
		|	TTTypesOfStocks.DimensionOfExpenses														AS DimensionOfExpenses,
		|	TTTypesOfStocks.AssetsLiabilitiesDimension												AS AssetsLiabilitiesDimension,
		|	TTTypesOfStocks.Count															AS Count,
		|	TTTypesOfStocks.Cost																AS Cost,
		|	TTTypesOfStocks.CostExcludingVAT														AS CostExcludingVAT,
		|	TTTypesOfStocks.LocalCost															AS LocalCost,
		|	CASE
		|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
		|			THEN TTTypesOfStocks.InventoryOwnerAttribute
		|		ELSE RecipientProductKeys.Products
		|	END																				AS SourceOfProductFinancialAccountingGroup
		|FROM
		|	TTTypesOfStocks AS TTTypesOfStocks
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS RecipientProductKeys
		|		ON TTTypesOfStocks.ItemsLocationAttributes = RecipientProductKeys.Ref
		|
		|WHERE
		|	TTTypesOfStocks.ToExpenseAs";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableItemsPricesOfVendor(Query, QueryTexts, Registers)
	
	RegisterName = "ItemsPricesOfVendor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableCurrencyExchangeRates", QueryTexts) Then
		QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	&Period                         AS Period,
	|	Services.Products             AS Products,
	|	Services.Characteristic           AS Characteristic,
	|	Services.VendorPriceKind        AS VendorPriceKind,
	|	Services.VendorPriceKind.Currency AS Currency,
	|	&Partner                        AS Partner,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	CAST(
	|		AVG(
	|			Services.Price
	|				* CASE
	|					WHEN
	|						&Currency <> Services.VendorPriceKind.Currency
	|					THEN
	|						CASE
	|							WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|								AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|							THEN 
	|								(Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
	|								/ (CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|							ELSE
	|								0
	|						END
	|					ELSE 
	|						1
	|				END
	|		) AS NUMBER(31,2))          AS Price
	|FROM
	|	Document.SubcontractorReport2_5.Services AS Services
	|	
	|	LEFT JOIN TemporaryTableCurrencyExchangeRates AS Currency_Rates
	|	ON Currency_Rates.Currency = &Currency
	|	
	|	LEFT JOIN TemporaryTableCurrencyExchangeRates AS CurrencyRatesPrices
	|	ON CurrencyRatesPrices.Currency = Services.VendorPriceKind.Currency
	|
	|WHERE
	|	Services.Ref = &Ref
	|	AND NOT Services.VendorPriceKind = VALUE(Catalog.VendorPriceTypes.EmptyRef)
	|	AND Services.Ref.RegisterVendorPrices
	|
	|GROUP BY
	|	Services.Products,
	|	Services.Characteristic,
	|	Services.VendorPriceKind
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers)
	
	RegisterName = "DatesOfCompanyGoodsReceipt";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	&Period                                                 AS DateOfReceipt,
	|	GoodsTable.ItemsLocationAttributes.Products   AS Products,
	|	GoodsTable.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	GoodsTable.ItemsLocationAttributes.Series          AS Series,
	|	GoodsTable.ItemsLocationAttributes.Purpose     AS Purpose,
	|	GoodsTable.InventoryOwnerAttribute                                AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber                                  AS CCDNumber
	|FROM
	|	Document.SubcontractorReport2_5.InventoryOwnerAttributesProducts AS GoodsTable
	|
	|	LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|	ON GoodsTable.InventoryOwnerAttribute                               = UninvoicedReceipts.InventoryOwnerAttribute
	|	AND GoodsTable.ItemsLocationAttributes.Products   = UninvoicedReceipts.Products
	|	AND GoodsTable.ItemsLocationAttributes.Characteristic = UninvoicedReceipts.Characteristic
	|	AND GoodsTable.ItemsLocationAttributes.Series          = UninvoicedReceipts.Series
	|	AND GoodsTable.ItemsLocationAttributes.Purpose     = UninvoicedReceipts.Purpose
	|	AND GoodsTable.CCDNumber                                  = UninvoicedReceipts.CCDNumber
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.ToExpenseAs
	|	AND (UninvoicedReceipts.DateOfReceipt IS NULL
	|		OR UninvoicedReceipts.DateOfReceipt < BEGINOFPERIOD(&Period, DAY))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	AdditionalParameters.Add("ConversionFactorToOrderCurrency");
	AdditionalParameters.Add("ConversionRateToManCurrency");
	AdditionalParameters.Add("FactorOfConversionToCurrencyOfRegul");
	
	If Query <> Undefined Then
		InitializeProductAnalysisKeys(Query);
		SetRequestParametersCurrencyCoefficients(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTypesOfStocks");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTypesOfStocks(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region WriteOffToOtherLots_ProductWork
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					 	AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes    	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute			 		 	AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType		 		AS VATActivityType,
	|	DocumentTable.VATTaxation					AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED										AS CorCompany,
	|	TableTypesOfStocks_.ProductionLot            	AS CorLot,
	|	TableTypesOfStocks_.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity									AS SalesOpportunity,
	|	DocumentTable.Department             				AS Department,
	|	DocumentTable.Manager								AS Manager,
	|	TableTypesOfStocks_.ProductsGroup 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|
	// Other fields
	|	TableTypesOfStocks_.RowID										AS RowID,
	|	TableTypesOfStocks_.BusinessOperation									AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID									AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting							AS BusinessTransactionSetting
	|
	|FROM
	|	Document.SubcontractorReport2_5 AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExpensesToOtherProductionLots,
		QueryText);
		
	#EndRegion

	#Region WriteOffToOtherParties_ReleaseAtPlannedCost
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					 	AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes    	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute			 		 	AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType		 		AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED										AS CorCompany,
	|	DocumentTable.Ref            					AS CorLot,
	|	TableTypesOfStocks_.LotVendorAttributes				AS LotVendorAttributesCorr,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity									AS SalesOpportunity,
	|	DocumentTable.Department             				AS Department,
	|	DocumentTable.Manager								AS Manager,
	|	TableTypesOfStocks_.ProductsGroup 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 					AS Count,
	|	TableTypesOfStocks_.Cost                    AS Cost,
	|	TableTypesOfStocks_.CostExcludingVAT              AS CostExcludingVAT,
	|	TableTypesOfStocks_.LocalCost                AS LocalCost,
	|	TableTypesOfStocks_.CostMan                 AS CostMan,
	|
	// Additional field
	|	DocumentTable.Ref            					AS Lot,
	|	TableTypesOfStocks_.LotVendorAttributes				AS LotVendorAttributes,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease) AS AccountingSection,
	|
	// Other fields
	|	VALUE(Enum.LotRecordTypes.Supplement) 								AS EntryType,
	|	TableTypesOfStocks_.RowID												AS RowID,
	|	TableTypesOfStocks_.FinRecordID											AS FinRecordID,
	|	VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction) 		AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.TransferOfProductsFromProduction) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.SubcontractorReport2_5 AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND &ProductCostingByPlannedCost
	|	AND TableTypesOfStocks_.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExpensesToOtherProductionLots,
		QueryText);
		
	#EndRegion

	#Region WriteOffForExpensesAssets_Products
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED												AS CorCompany,
	|	UNDEFINED 												AS CorItemsLocationAttributes,
	|	UNDEFINED		    									AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.ExpenseItem 			    			AS ExpenseItemAssets,
	|	CASE WHEN TableTypesOfStocks_.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|		THEN TableTypesOfStocks_.DimensionOfExpenses                
	|		ELSE TableTypesOfStocks_.AssetsLiabilitiesDimension
	|	END    						  			    			AS AssetExpenseAnalytics,
	|	CASE WHEN &AccountingForLBCosts
	|		THEN &LineOfBusiness
	|		ELSE UNDEFINED
	|	END                                                       AS CorLineOfBusiness,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity									AS SalesOpportunity,
	// Filling in the division for the issue at a fixed cost must correspond to the function of the text query with the Text Input data().
	// The subdivision in the tabular part is indicated only for works, for products the subdivision is taken from the document header. 
	|	(CASE
	|		WHEN CAST(TableTypesOfStocks_.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN TableTypesOfStocks_.Department
	|		ELSE DocumentTable.Department END)			AS Department,
	|	DocumentTable.Manager								AS Manager,
	|	TableTypesOfStocks_.ProductsGroup                   	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 		AS Count,
	|	TableTypesOfStocks_.Cost		AS Cost,
	|	TableTypesOfStocks_.CostExcludingVAT	AS CostExcludingVAT,
	|	TableTypesOfStocks_.LocalCost	AS LocalCost,
	|	TableTypesOfStocks_.CostMan		AS CostMan,
	|
	// Additional field
	|	CASE WHEN &FIFORollingValuation
	|		THEN TableTypesOfStocks_.ReleaseParty
	|		ELSE UNDEFINED
	|	END								AS Lot,
	|	CASE WHEN &FIFORollingValuation
	|		THEN TableTypesOfStocks_.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END								AS LotVendorAttributes,
	|	CASE WHEN &ProductCostingByPlannedCost
	|	 AND TableTypesOfStocks_.BusinessOperation <> VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|		ELSE UNDEFINED
	|	END AS AccountingSection,
	|
	// Other fields
	|	VALUE(Enum.LotRecordTypes.Supplement)									 AS EntryType,
	|	TableTypesOfStocks_.RowID												 AS RowID,
	|	CASE WHEN TableTypesOfStocks_.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|		THEN VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost)
	|		ELSE VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|	END																				 AS BusinessOperation,
	|	TableTypesOfStocks_.GLAccountSettings 											 AS GLAccountSettings,
	|	TableTypesOfStocks_.FinRecordID											 AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.GoodsConsumptionOnDemand)		 AS BusinessTransactionSetting
	|FROM
	|	Document.SubcontractorReport2_5 AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ProductsRelease),
	|		VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|	AND TableTypesOfStocks_.ToExpenseAs
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.RecogniseAsExpensesAssets,
		QueryText);
	
	#EndRegion

	#Region ExternalEntry_Work
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_		AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	UNDEFINED										AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.ProductionLot				AS Lot,
	|	TableTypesOfStocks_.VATActivityType 				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	UNDEFINED					AS VATRate,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity					AS SalesOpportunity,
	|	DocumentTable.Department 			AS Department,
	|	DocumentTable.Manager 				AS Manager,
	|	TableTypesOfStocks_.ProductsGroup 		AS ProductsGroup,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.Cost                    AS Cost,
	|	TableTypesOfStocks_.CostExcludingVAT              AS CostExcludingVAT,
	|	TableTypesOfStocks_.LocalCost                AS LocalCost,
	|	CASE
	|		WHEN DocumentTable.PurchaseForActivity = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN 0
	|		ELSE TableTypesOfStocks_.VATAmount
	|	END                                           AS VATLocal,
	|	TableTypesOfStocks_.CostMan                 AS CostMan,
	|	CASE
	|		WHEN DocumentTable.PurchaseForActivity = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN 0
	|		ELSE TableTypesOfStocks_.VATManag
	|	END                                           AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	TableTypesOfStocks_.RowID 				AS RowID,
	|	TableTypesOfStocks_.BusinessOperation 			AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID			AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.SubcontractorReport2_5 AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion

	#Region InternalReceipt_Products
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED				AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_		AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.ReleaseParty					AS Lot,
	|	TableTypesOfStocks_.VATActivityType 				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	0 												AS RowCode,
	|
	// Corresponding fields
	|	UNDEFINED							AS CorItemsLocationAttributes,
	|	UNDEFINED							AS CorInventoryOwnerAttribute,
	|	UNDEFINED							AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity					AS SalesOpportunity,
	|	DocumentTable.Department 			AS Department,
	|	DocumentTable.Manager 				AS Manager,
	|	TableTypesOfStocks_.ProductsGroup 		AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	CASE
	|		WHEN TypesOfStocksExternal.Ref IS NULL
	|		THEN TableTypesOfStocks_.Cost
	|		ELSE 0
	|	END AS Cost,
	|	CASE
	|		WHEN TypesOfStocksExternal.Ref IS NULL
	|		THEN TableTypesOfStocks_.CostExcludingVAT
	|		ELSE 0
	|	END AS CostExcludingVAT,
	|	CASE
	|		WHEN TypesOfStocksExternal.Ref IS NULL
	|		THEN TableTypesOfStocks_.LocalCost
	|		ELSE 0
	|	END AS LocalCost,
	|	CASE
	|		WHEN DocumentTable.PurchaseForActivity = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			OR NOT TypesOfStocksExternal.Ref IS NULL
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmount
	|	END AS VATLocal,
	|	CASE
	|		WHEN TypesOfStocksExternal.Ref IS NULL
	|		THEN TableTypesOfStocks_.CostMan
	|		ELSE 0
	|	END AS CostMan,
	|	CASE
	|		WHEN DocumentTable.PurchaseForActivity = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			OR NOT TypesOfStocksExternal.Ref IS NULL
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATManag
	|	END AS VATManag,
	|	CASE
	|		WHEN TypesOfStocksExternal.Ref IS NULL
	|		THEN 0
	|		ELSE TableTypesOfStocks_.Cost
	|	END AS OffBalanceCost,
	|	CASE
	|		WHEN TypesOfStocksExternal.Ref IS NULL
	|		THEN 0
	|		ELSE TableTypesOfStocks_.LocalCost
	|	END AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	// When debiting for expenses, the batch should not be available for distribution, therefore it should have the record type "Supplement".
	// There is no explicit indication of an issue with a write-off for expenses in the Reflect operation procedure
	// . Therefore, the record type is set explicitly.
	|	(CASE
	|		WHEN TableTypesOfStocks_.ToExpenseAs
	|			THEN VALUE(Enum.LotRecordTypes.Supplement)
	|		ELSE VALUE(Enum.LotRecordTypes.Lot)
	|	END)												AS EntryType,
	|	TableTypesOfStocks_.RowID 				AS RowID,
	|	CASE WHEN &ProductCostingByPlannedCost
	|	 AND TableTypesOfStocks_.BusinessOperation <> VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|		THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
	|		ELSE TableTypesOfStocks_.BusinessOperation
	|	END												AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID			AS FinRecordID,
	|	CASE WHEN &ProductCostingByPlannedCost
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.TransferOfProductsFromProduction)
	|		ELSE TableTypesOfStocks_.BusinessTransactionSetting
	|	END												AS BusinessTransactionSetting
	|
	|FROM
	|	Document.SubcontractorReport2_5 AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|	LEFT JOIN Enum.InventoryTypes AS TypesOfStocksExternal
	|		ON TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = TypesOfStocksExternal.Ref
	|			AND NOT TypesOfStocksExternal.Ref IN (&InventoryTypesOwn)
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ProductsRelease),
	|		VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	// When products are released at the planned cost with a write-off for expenses, Registered Records are generated 
	// in the request Internal Access_Productionplanned cost.
	|	AND NOT (&ProductCostingByPlannedCost
	|		AND TableTypesOfStocks_.ToExpenseAs
	|		AND TableTypesOfStocks_.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease))";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);
	
	#EndRegion
	
	#Region InternalRevenue_ManufacturedProductsAtPlannedCost
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED				AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_		AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	TableTypesOfStocks_.VATActivityType 				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	0 												AS RowCode,
	|
	// Corresponding fields
	|	UNDEFINED							AS CorItemsLocationAttributes,
	|	UNDEFINED							AS CorInventoryOwnerAttribute,
	|	UNDEFINED							AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity					AS SalesOpportunity,
	|	DocumentTable.Department 			AS Department,
	|	DocumentTable.Manager 				AS Manager,
	|	TableTypesOfStocks_.ProductsGroup 		AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.Cost                    AS Cost,
	|	TableTypesOfStocks_.CostExcludingVAT              AS CostExcludingVAT,
	|	TableTypesOfStocks_.LocalCost                AS LocalCost,
	|	0                                          		AS VATLocal,
	|	TableTypesOfStocks_.CostMan                 AS CostMan,
	|	0                                          		AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Additional field
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease) AS AccountingSection,
	|	
	// Other fields
	|	VALUE(Enum.LotRecordTypes.Supplement) AS EntryType,
	|	TableTypesOfStocks_.RowID 				AS RowID,
	|	TableTypesOfStocks_.BusinessOperation			AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID			AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.SubcontractorReport2_5 AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|	AND &ProductCostingByPlannedCost
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);
	
	#EndRegion
	
	#Region ExternalRevenue_ReductionOfUnfinishedProductionAtFixedCostOfOutput
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_		AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.CorItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.ProductionLot				AS Lot,
	|	TableTypesOfStocks_.VATActivityType 				AS VATActivityType,
	|	DocumentTable.VATTaxation					AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	UNDEFINED									AS LotVendorAttributes,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	DocumentTable.Partner						AS Vendor,
	|	DocumentTable.Counterparty 					AS Counterparty,
	|	UNDEFINED									AS VATRate,
	|
	// Corresponding fields
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department 		AS Department,
	|	DocumentTable.Manager 			AS Manager,
	|	TableTypesOfStocks_.ProductsGroup 	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	-TableTypesOfStocks_.Count					AS Count,
	|	-CASE
	|		WHEN TypesOfStocksExternal.Ref IS NULL
	|		THEN TableTypesOfStocks_.Cost
	|		ELSE 0
	|	END AS Cost,
	|	-CASE
	|		WHEN TypesOfStocksExternal.Ref IS NULL
	|		THEN TableTypesOfStocks_.CostExcludingVAT
	|		ELSE 0
	|	END AS CostExcludingVAT,
	|	-CASE
	|		WHEN TypesOfStocksExternal.Ref IS NULL
	|		THEN TableTypesOfStocks_.LocalCost
	|		ELSE 0
	|	END AS LocalCost,
	|	CASE
	|		WHEN DocumentTable.PurchaseForActivity = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			OR NOT TypesOfStocksExternal.Ref IS NULL
	|		THEN 0
	|		ELSE -TableTypesOfStocks_.VATAmount
	|	END AS VATLocal,
	|	-CASE
	|		WHEN TypesOfStocksExternal.Ref IS NULL
	|		THEN TableTypesOfStocks_.CostMan
	|		ELSE 0
	|	END AS CostMan,
	|	CASE
	|		WHEN DocumentTable.PurchaseForActivity = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			OR NOT TypesOfStocksExternal.Ref IS NULL
	|		THEN 0
	|		ELSE -TableTypesOfStocks_.VATManag
	|	END AS VATManag,
	|	-CASE
	|		WHEN TypesOfStocksExternal.Ref IS NULL
	|		THEN 0
	|		ELSE TableTypesOfStocks_.Cost
	|	END AS OffBalanceCost,
	|	-CASE
	|		WHEN TypesOfStocksExternal.Ref IS NULL
	|		THEN 0
	|		ELSE TableTypesOfStocks_.LocalCost
	|	END AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	TableTypesOfStocks_.RowID 				AS RowID,
	|	TableTypesOfStocks_.BusinessOperation 			AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID			AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.SubcontractorReport2_5 AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|	LEFT JOIN Enum.InventoryTypes AS TypesOfStocksExternal
	|		ON TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = TypesOfStocksExternal.Ref
	|			AND NOT TypesOfStocksExternal.Ref IN (&InventoryTypesOwn)
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion

	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#Region FillType

Function TextOfRequestProductsOverOrderToCheckout(TempTableName = "", FilterByDimensions = Undefined) Export
	
	QueryText =
	"SELECT
	|	NestedQuery.PurchaseOrder    AS PurchaseOrder,
	|	NestedQuery.Products       AS Products,
	|	NestedQuery.Characteristic     AS Characteristic,
	|	NestedQuery.RowCode          AS RowCode,
	|	SUM(NestedQuery.ToRegister) AS ToRegister
	|FROM
	|	(SELECT
	|		Table.PurchaseOrder                                AS PurchaseOrder,
	|		Table.Products                                   AS Products,
	|		Table.Characteristic                                 AS Characteristic,
	|		Table.Warehouse                                          AS Warehouse,
	|		Table.RowCode                                      AS RowCode,
	|		Table.ToReceiveReceipt - Table.ToRegisterExpense AS ToRegister
	|	FROM
	|		AccumulationRegister.PurchaseOrders.Turnovers(,,, RowCode = 0 AND &FilterByDimensions) AS Table
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.PurchaseOrder                                AS PurchaseOrder,
	|		Table.Products                                   AS Products,
	|		Table.Characteristic                                 AS Characteristic,
	|		Table.Warehouse                                          AS Warehouse,
	|		Table.RowCode                                      AS RowCode,
	|		Table.ToRegister                                    AS ToRegister
	|	FROM
	|		AccumulationRegister.PurchaseOrders AS Table
	|	WHERE
	|		Table.Active
	|		AND Table.Recorder IN (&Recorder)
	|		AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND Table.RowCode = 0
	|		AND &FilterByDimensions
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.PurchaseOrder,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.RowCode
	|
	|HAVING
	|	SUM(NestedQuery.ToRegister) > 0
	|";
	
	If Not IsBlankString(TempTableName) Then
		QueryText = RequestSchemes.SetRoomToTemporaryTable(QueryText, TempTableName);
	EndIf;
	
	FilterText1 = TMCommonUse.SelectionTextBySelectionCollection(FilterByDimensions);
	QueryText = StrReplace(QueryText, "&FilterByDimensions", FilterText1);
	
	Return QueryText;
	
EndFunction

Function RequestTextProductsWithoutOrderForCheckout(Filters = Undefined) Export
	
	QueryText =
	"SELECT
	|	InventoryKinds.Ref AS InventoryOwnerAttribute
	|INTO InventoryKinds
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.Organization = &Organization
	|	AND InventoryKinds.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.SubcontractorProducts),
	|		VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider))
	|
	|INDEX BY
	|	InventoryOwnerAttribute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StockBalance.Products      AS Products,
	|	StockBalance.Characteristic    AS Characteristic,
	|	StockBalance.Purpose        AS Purpose,
	|	StockBalance.Series             AS Series,
	|	SUM(StockBalance.Count) AS Count,
	|	SUM(StockBalance.Count) AS NumberOfPackages
	|FROM
	|	(SELECT
	|		StockBalance.ItemsLocationAttributes.Products   AS Products,
	|		StockBalance.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		StockBalance.ItemsLocationAttributes.Purpose     AS Purpose,
	|		StockBalance.ItemsLocationAttributes.Series          AS Series,
	// The remaining goods that require confirmation of the release are always negative
	|		-StockBalance.CountBalance                        AS Count
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(,
	|			InventoryOwnerAttribute IN
	|				(SELECT
	|					InventoryOwnerAttribute
	|				FROM
	|					InventoryKinds)
	|		) AS StockBalance
	|	WHERE
	|		StockBalance.CountBalance < 0
	|		AND (ISNULL(StockBalance.ItemsLocationAttributes.Contract.ContractType, VALUE(Enum.ContractTypes.EmptyRef)) =
	|					VALUE(Enum.ContractTypes.TransferToTolling2_5)
	|			OR ISNULL(StockBalance.ItemsLocationAttributes.Contract.ContractType, VALUE(Enum.ContractTypes.EmptyRef)) =
	|					VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries))
	|		AND &FilterReservesOfGoods
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TurnoverOnOrders.Products   AS Products,
	|		TurnoverOnOrders.Characteristic AS Characteristic,
	|		GoodsReceipts.Purpose    AS Purpose,
	|		GoodsReceipts.Series         AS Series,
	|		-GoodsReceipts.Count   AS Count
	|	FROM
	|		AccumulationRegister.PurchaseOrders.Turnovers(,,
	|			Auto,
	|			&FilterPurchaseOrders
	|			AND VALUETYPE(PurchaseOrder) = TYPE(Document.SubcontractOrder2_5)) AS TurnoverOnOrders
	|		
	|		INNER JOIN Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsReceipts
	|		ON GoodsReceipts.ReferenceOrder = TurnoverOnOrders.PurchaseOrder
	|		AND GoodsReceipts.RowCode = TurnoverOnOrders.RowCode
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON DocumentsRegistry.Ref = TurnoverOnOrders.PurchaseOrder
	|		AND NOT DocumentsRegistry.AdditionalRecord
	|	
	|	WHERE
	|		DocumentsRegistry.Organization = &Organization
	|		AND DocumentsRegistry.Partner = &Partner
	|		AND DocumentsRegistry.Contract = &Contract
	|	) AS StockBalance
	|
	|GROUP BY
	|	StockBalance.Products,
	|	StockBalance.Characteristic,
	|	StockBalance.Purpose,
	|	StockBalance.Series
	|
	|HAVING
	|	SUM(StockBalance.Count) > 0
	|";
	
	FilterReservesOfGoods = "TRUE";
	FilterPurchaseOrders = "TRUE";
	
	If ValueIsFilled(Filters) Then
		
		For Each KeyValue In Filters Do
			
			FilterText1 = "";
			For Each Filter In KeyValue.Value Do
				
				LeftValue       = Filter.Key;
				TypeOfRequestComparison = Filter.Value.ComparisonType;
				RightValue      = Filter.Value.RightValue;
				
				FilterText1 =
					FilterText1
					+ " AND (" + LeftValue + ") " + TypeOfRequestComparison + " (" + RightValue + ")";
				
			EndDo;
			
			If KeyValue.Key = "FilterReservesOfGoods" Then
				FilterReservesOfGoods = FilterReservesOfGoods + FilterText1;
			Else
				FilterPurchaseOrders = FilterPurchaseOrders + FilterText1
			EndIf;
			
		EndDo;
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&FilterReservesOfGoods", FilterReservesOfGoods);
	QueryText = StrReplace(QueryText, "&FilterPurchaseOrders", FilterPurchaseOrders);
	
	Return QueryText;
	
EndFunction

Function RequestTextProductStandardsByOrder()
	
	QueryText =
	"SELECT
	|	Standards.CostGroupNumber     AS CostGroupNumber,
	|	MAX(Standards.ZoomRatio) AS ZoomRatio
	|INTO Standards
	|FROM
	|	(SELECT
	|		TabularSection.CostGroupNumber           AS CostGroupNumber,
	|		TabularSection.Products                AS Products,
	|		TabularSection.Characteristic              AS Characteristic,
	|		SUM(GoodsForRegistration.ToRegister)
	|				/ SUM(TabularSection.Count) AS ZoomRatio
	|	FROM
	|		ManufacturedProducts AS TabularSection
	|	
	|		INNER JOIN ProductsToBeProcessedByOrder AS GoodsForRegistration
	|		ON TabularSection.RowCode = GoodsForRegistration.RowCode
	|	
	|	WHERE
	|		TabularSection.ThisIsAProductionIssueStage
	|
	|	GROUP BY
	|		TabularSection.CostGroupNumber,
	|		TabularSection.Products,
	|		TabularSection.Characteristic
	|
	|	UNION ALL
	|
	|	SELECT
	|		TabularSection.CostGroupNumber           AS CostGroupNumber,
	|		TabularSection.Products                AS Products,
	|		TabularSection.Characteristic              AS Characteristic,
	|		SUM(GoodsForRegistration.ToRegister)
	|				/ SUM(TabularSection.Count) AS Count
	|	FROM
	|		SideAndIntermediateRelease AS TabularSection
	|
	|		INNER JOIN ProductsToBeProcessedByOrder AS GoodsForRegistration
	|		ON TabularSection.RowCode = GoodsForRegistration.RowCode
	|		
	|	WHERE
	|		NOT TabularSection.ThisIsAProductionIssueStage
	|
	|	GROUP BY
	|		TabularSection.CostGroupNumber,
	|		TabularSection.Products,
	|		TabularSection.Characteristic
	|	) AS Standards
	|
	|GROUP BY
	|	Standards.CostGroupNumber
	|
	|INDEX BY
	|	CostGroupNumber
	|";
	
	Return QueryText;
	
EndFunction

Procedure AddRequestTextsProductStandardsForReport(QueryTexts)
	
	QueryTexts.Add(
	"SELECT
	|	TabularSection.CostGroupNumber AS CostGroupNumber,
	|	TabularSection.Products      AS Products,
	|	TabularSection.Characteristic    AS Characteristic,
	|	TabularSection.RowCode         AS RowCode,
	|	TabularSection.Count        AS Count
	|INTO OutputProductsOfReport
	|FROM
	|	&OutputProductsOfReport AS TabularSection
	|WHERE
	|	TabularSection.CostGroupNumber IN (&CostGroupNumbers)
	|
	|INDEX BY
	|	RowCode
	|");
	
	QueryTexts.Add(
	"SELECT
	|	TabularSection.CostGroupNumber AS CostGroupNumber,
	|	TabularSection.Products      AS Products,
	|	TabularSection.Characteristic    AS Characteristic,
	|	TabularSection.RowCode         AS RowCode,
	|	TabularSection.Count        AS Count
	|INTO ByProductsOfReport
	|FROM
	|	&ByProductsOfReport AS TabularSection
	|WHERE
	|	TabularSection.CostGroupNumber IN (&CostGroupNumbers)
	|
	|INDEX BY
	|	RowCode
	|");
	
	QueryTexts.Add(
	"SELECT
	|	Standards.CostGroupNumber     AS CostGroupNumber,
	|	MAX(Standards.ZoomRatio) AS ZoomRatio
	|INTO Standards
	|FROM
	|	(SELECT
	|		TabularSection.CostGroupNumber              AS CostGroupNumber,
	|		TabularSection.Products                   AS Products,
	|		TabularSection.Characteristic                 AS Characteristic,
	|		SUM(TabularSection.Count)
	|				/ SUM(GoodsForRegistration.Count) AS ZoomRatio
	|	FROM
	|		OutputProductsOfReport AS TabularSection
	|	
	|		INNER JOIN ManufacturedProducts AS GoodsForRegistration
	|		ON TabularSection.RowCode = GoodsForRegistration.RowCode
	|	
	|	GROUP BY
	|		TabularSection.CostGroupNumber,
	|		TabularSection.Products,
	|		TabularSection.Characteristic
	|
	|	UNION ALL
	|
	|	SELECT
	|		TabularSection.CostGroupNumber              AS CostGroupNumber,
	|		TabularSection.Products                   AS Products,
	|		TabularSection.Characteristic                 AS Characteristic,
	|		SUM(TabularSection.Count)
	|				/ SUM(GoodsForRegistration.Count) AS ZoomRatio
	|	FROM
	|		ByProductsOfReport AS TabularSection
	|
	|		INNER JOIN SideAndIntermediateRelease AS GoodsForRegistration
	|		ON TabularSection.RowCode = GoodsForRegistration.RowCode
	|
	|	GROUP BY
	|		TabularSection.CostGroupNumber,
	|		TabularSection.Products,
	|		TabularSection.Characteristic
	|	) AS Standards
	|
	|GROUP BY
	|	Standards.CostGroupNumber
	|
	|INDEX BY
	|	CostGroupNumber
	|");
	
EndProcedure

Procedure AddRequestTextsForSeriesOfReceiptsForOrder(QueryTexts, ManufacturedProducts, SideAndIntermediateRelease)
	
	ProductOrderRequestTexts = New Array;
	
	ProductOrderRequestTexts.Add(
		"SELECT
		|	0 AS RowCode
		|");
	
	If ManufacturedProducts Then
		ProductOrderRequestTexts.Add(
			"SELECT
			|	TabularSection.RowCode          AS RowCode
			|FROM
			|	ManufacturedProducts AS TabularSection
			|");
	EndIf;
	
	If SideAndIntermediateRelease Then
		ProductOrderRequestTexts.Add(
			"SELECT
			|	TabularSection.RowCode          AS RowCode
			|FROM
			|	SideAndIntermediateRelease AS TabularSection
			|");
	EndIf;
	
	QueryText = StrConcat(ProductOrderRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	QueryText = RequestSchemes.SetRoomToTemporaryTable(QueryText, "WareFromOrder");
	QueryText = RequestSchemes.SetIndexingOfQueryFields(QueryText, "RowCode");
	
	QueryTexts.Add(QueryText);
	
	QueryTexts.Add(
	"SELECT
	|	DimensionKeys.DimensionKey AS ItemsLocationAttributes
	|INTO ProductsReceivedOnRequest
	|FROM
	|	WareFromOrder AS WareFromOrder
	|	
	|	INNER JOIN Document.ReceiptOfGoodsFromCustodian.Goods AS ReceiptsOfGoodsFromCustodian
	|	ON ReceiptsOfGoodsFromCustodian.ReferenceOrder = &SubcontractOrder
	|	AND ReceiptsOfGoodsFromCustodian.RowCode = WareFromOrder.RowCode
	|	
	|	INNER JOIN InformationRegister.ItemsLocationAttributes AS DimensionKeys
	|	ON DimensionKeys.Products = ReceiptsOfGoodsFromCustodian.Products
	|	AND DimensionKeys.Characteristic = ReceiptsOfGoodsFromCustodian.Characteristic
	|	AND DimensionKeys.Purpose = ReceiptsOfGoodsFromCustodian.Purpose
	|	AND DimensionKeys.Series = ReceiptsOfGoodsFromCustodian.Series
	|	AND DimensionKeys.StorageLocation = ReceiptsOfGoodsFromCustodian.Ref.Contract
	|	AND DimensionKeys.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
	|	
	|WHERE
	|	NOT DimensionKeys.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|GROUP BY
	|	DimensionKeys.DimensionKey
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|");
	
	QueryTexts.Add(
	"SELECT
	|	CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CompanyGoodsBalance.Products               AS Products,
	|	CompanyGoodsBalance.Characteristic             AS Characteristic,
	|	CompanyGoodsBalance.Purpose                 AS Purpose,
	|	CompanyGoodsBalance.Series                      AS Series,
	|	FALSE                                                AS ToExpenseAs,
	|	-SUM(CompanyGoodsBalance.Count)         AS Count
	|FROM
	|	(SELECT
	|		CompanyGoodsBalance.ItemsLocationAttributes                AS ItemsLocationAttributes,
	|		CompanyGoodsBalance.ItemsLocationAttributes.Products   AS Products,
	|		CompanyGoodsBalance.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		CompanyGoodsBalance.ItemsLocationAttributes.Purpose     AS Purpose,
	|		CompanyGoodsBalance.ItemsLocationAttributes.Series          AS Series,
	|		FALSE                                                               AS ToExpenseAs,
	|		CompanyGoodsBalance.CountBalance                         AS Count
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(,
	|			(Organization, ItemsLocationAttributes) IN
	|				(SELECT
	|					&Organization AS Organization,
	|					ProductsReceivedOnRequest.ItemsLocationAttributes
	|				FROM
	|					ProductsReceivedOnRequest AS ProductsReceivedOnRequest)) AS CompanyGoodsBalance
	|	WHERE
	|		CompanyGoodsBalance.CountBalance < 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CompanyGoodsBalance.ItemsLocationAttributes                AS ItemsLocationAttributes,
	|		CompanyGoodsBalance.ItemsLocationAttributes.Products   AS Products,
	|		CompanyGoodsBalance.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		CompanyGoodsBalance.ItemsLocationAttributes.Purpose     AS Purpose,
	|		CompanyGoodsBalance.ItemsLocationAttributes.Series          AS Series,
	|		FALSE                                                               AS ToExpenseAs,
	|		CompanyGoodsBalance.Count                                AS Count
	|	FROM
	|		AccumulationRegister.CompanyGoods AS CompanyGoodsBalance
	|	WHERE
	|		CompanyGoodsBalance.Recorder = &Recorder
	|		AND CompanyGoodsBalance.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND (CompanyGoodsBalance.Organization, CompanyGoodsBalance.ItemsLocationAttributes) IN
	|			(SELECT
	|				&Organization,
	|				ProductsReceivedOnRequest.ItemsLocationAttributes
	|			FROM
	|				ProductsReceivedOnRequest AS ProductsReceivedOnRequest)
	|	) AS CompanyGoodsBalance
	|
	|GROUP BY
	|	CompanyGoodsBalance.ItemsLocationAttributes,
	|	CompanyGoodsBalance.Products,
	|	CompanyGoodsBalance.Characteristic,
	|	CompanyGoodsBalance.Purpose,
	|	CompanyGoodsBalance.Series
	|
	|HAVING
	|	SUM(CompanyGoodsBalance.Count) < 0
	|");
	
EndProcedure

Function RequestTextOutputProductsForRegistration()
	
	QueryText =
	"SELECT
	|	&SubcontractOrder                     AS SubcontractOrder,
	|	TabularSection.CostGroupNumber        AS CostGroupNumber,
	|	TabularSection.ProductionStage         AS ProductionStage,
	|	TabularSection.RowCode                AS RowCode,
	|	TabularSection.Products             AS Products,
	|	TabularSection.Characteristic           AS Characteristic,
	|	TabularSection.Purpose               AS Purpose,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	TabularSection.Recipient               AS Recipient,
	|	TabularSection.ToExpenseAs         AS ToExpenseAs,
	|	TabularSection.ExpenseItem           AS ExpenseItem,
	|	TabularSection.DimensionOfExpenses        AS DimensionOfExpenses,
	|	TabularSection.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TabularSection.GLAccountSettings     AS GLAccountSettings,
	|	TabularSection.BillOfMaterials             AS BillOfMaterials,
	|	TabularSection.Package                 AS Package,
	|	TabularSection.CostShare            AS CostShare,
	|	TabularSection.CostSharePerUnit   AS CostSharePerUnit,
	|	GoodsForRegistration.ToRegister           AS Count
	|FROM
	|	ManufacturedProducts AS TabularSection
	|	
	|	INNER JOIN ProductsToBeProcessedByOrder AS GoodsForRegistration
	|	ON GoodsForRegistration.RowCode = TabularSection.RowCode
	|
	|ORDER BY
	|	RowCode
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextForProductsForRegistration()
	
	QueryText =
	"SELECT
	|	&SubcontractOrder                     AS SubcontractOrder,
	|	TabularSection.CostGroupNumber        AS CostGroupNumber,
	|	TabularSection.ProductionStage         AS ProductionStage,
	|	TabularSection.RowCode                AS RowCode,
	|	TabularSection.Products             AS Products,
	|	TabularSection.Characteristic           AS Characteristic,
	|	TabularSection.Purpose               AS Purpose,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	TabularSection.Recipient               AS Recipient,
	|	TabularSection.ToExpenseAs         AS ToExpenseAs,
	|	TabularSection.ExpenseItem           AS ExpenseItem,
	|	TabularSection.DimensionOfExpenses        AS DimensionOfExpenses,
	|	TabularSection.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TabularSection.GLAccountSettings     AS GLAccountSettings,
	|	TabularSection.Package                 AS Package,
	|	TabularSection.ProductCostElement        AS ProductCostElement,
	|	TabularSection.Price                     AS Price,
	|	CASE
	|		WHEN &ReportStandards
	|			AND TabularSection.Count * Standards.ZoomRatio < GoodsForRegistration.ToRegister
	|			THEN TabularSection.Count * Standards.ZoomRatio
	|		ELSE GoodsForRegistration.ToRegister
	|	END                                   AS Count
	|FROM
	|	SideAndIntermediateRelease AS TabularSection
	|	
	|	INNER JOIN ProductsToBeProcessedByOrder AS GoodsForRegistration
	|	ON GoodsForRegistration.RowCode = TabularSection.RowCode
	|	
	|	INNER JOIN Standards AS Standards
	|	ON TabularSection.CostGroupNumber = Standards.CostGroupNumber
	|
	|UNION ALL
	|
	|SELECT
	|	&SubcontractOrder                                 AS SubcontractOrder,
	|	0                                                   AS CostGroupNumber,
	|	VALUE(Document.ProductionStage2_2.EmptyRef) AS ProductionStage,
	|	GoodsForRegistration.RowCode                         AS RowCode,
	|	GoodsForRegistration.Products                      AS Products,
	|	GoodsForRegistration.Characteristic                    AS Characteristic,
	|	VALUE(Catalog.Assignments.EmptyRef)        AS Purpose,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Recipient,
	|	FALSE                                                AS ToExpenseAs,
	|	UNDEFINED                                        AS ExpenseItem,
	|	UNDEFINED                                        AS DimensionOfExpenses,
	|	UNDEFINED                                        AS AssetsLiabilitiesDimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	GoodsForRegistration.Products.UnitOfMeasure     AS Package,
	|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
	|	0                                                   AS Price,
	|	GoodsForRegistration.ToRegister                       AS Count
	|FROM
	|	ProductsToBePlacedInExcessOfOrder AS GoodsForRegistration
	|
	|ORDER BY
	|	RowCode
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextMaterialsAndWorksTransferred()
	
	QueryText =
	"SELECT
	|	TabularSection.CostGroupNumber   AS CostGroupNumber,
	|	TabularSection.ProductionStage    AS ProductionStage,
	|	TabularSection.Products        AS Products,
	|	TabularSection.Characteristic      AS Characteristic,
	|	TabularSection.Purpose          AS Purpose,
	|	TabularSection.Series               AS Series,
	|	TabularSection.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TabularSection.Package            AS Package,
	|	TabularSection.ProductCostElement   AS ProductCostElement,
	|	SUM(CASE
	|		WHEN TabularSection.SupplyOption IN
	|				(VALUE(Enum.SupplyOptions.Ship),
	|				VALUE(Enum.SupplyOptions.TransferedEarlier))
	|			THEN TabularSection.Count
	|		ELSE 0
	|	END)                             AS Passed,
	|	SUM(TabularSection.Count)   AS Count
	|INTO MaterialsAndWorksTransferred
	|FROM
	|	MaterialsAndWorks AS TabularSection
	|
	|GROUP BY
	|	TabularSection.CostGroupNumber,
	|	TabularSection.ProductionStage,
	|	TabularSection.Products,
	|	TabularSection.Characteristic,
	|	TabularSection.Purpose,
	|	TabularSection.Series,
	|	TabularSection.BatchesIndicationStatus,
	|	TabularSection.Package,
	|	TabularSection.ProductCostElement
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextMaterialsAndDesignWork()
	
	QueryText =
	"SELECT
	|	&SubcontractOrder                AS SubcontractOrder,
	|	TabularSection.CostGroupNumber   AS CostGroupNumber,
	|	TabularSection.ProductionStage    AS ProductionStage,
	|	TabularSection.Products        AS Products,
	|	TabularSection.Characteristic      AS Characteristic,
	|	TabularSection.Purpose          AS Purpose,
	|	TabularSection.Series               AS Series,
	|	TabularSection.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TabularSection.Package            AS Package,
	|	TabularSection.ProductCostElement   AS ProductCostElement,
	|	CASE
	|		WHEN TabularSection.Count * Standards.ZoomRatio <= TabularSection.Passed
	|			THEN TabularSection.Count * Standards.ZoomRatio
	|		ELSE TabularSection.Passed
	|	END                              AS Count
	|FROM
	|	MaterialsAndWorksTransferred AS TabularSection
	|
	|	INNER JOIN Standards AS Standards
	|	ON TabularSection.CostGroupNumber = Standards.CostGroupNumber
	|
	|WHERE
	|	CASE
	|		WHEN TabularSection.Count * Standards.ZoomRatio <= TabularSection.Passed
	|			THEN TabularSection.Count * Standards.ZoomRatio
	|		ELSE TabularSection.Passed
	|	END <> 0
	|
	|ORDER BY
	|	CostGroupNumber,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextServicesForRegistration()
	
	QueryText =
	"SELECT
	|	&SubcontractOrder              AS SubcontractOrder,
	|	TabularSection.CostGroupNumber AS CostGroupNumber,
	|	TabularSection.ProductionStage  AS ProductionStage,
	|	TabularSection.Products      AS Products,
	|	TabularSection.RowCode         AS RowCode,
	|	TabularSection.Characteristic    AS Characteristic,
	|	TabularSection.VendorPriceKind AS VendorPriceKind,
	|	TabularSection.VATRate         AS VATRate,
	|	TabularSection.ProductCostElement AS ProductCostElement,
	|	TabularSection.Price              AS Price,
	|	CASE
	|		WHEN &ReportStandards
	|			AND TabularSection.Count * Standards.ZoomRatio < GoodsForRegistration.ToRegister
	|			THEN TabularSection.Count * Standards.ZoomRatio
	|		ELSE GoodsForRegistration.ToRegister
	|	END                            AS Count,
	|	GoodsForRegistration.Sum          AS Sum
	|FROM
	|	OrderingServices AS TabularSection
	|	
	|	INNER JOIN ProductsToBeProcessedByOrder AS GoodsForRegistration
	|	ON GoodsForRegistration.RowCode = TabularSection.RowCode
	|	
	|	INNER JOIN Standards AS Standards
	|	ON TabularSection.CostGroupNumber = Standards.CostGroupNumber
	|
	|ORDER BY
	|	RowCode
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextBalancesForReceiptBasedOnProcessorReports() Export
	
	QueryText = 
	"SELECT ALLOWED
	|	GoodsTable.Ref                     AS Ref,
	|	GoodsTable.Organization                AS Organization,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	SUM(GoodsTable.Count)          AS Count,
	|	MAX(GoodsTable.Package)         AS Package
	|INTO ProductsFromSubcontractorReport
	|FROM
	|	(SELECT
	|		GoodsTable.Ref                     AS Ref,
	|		GoodsTable.Ref.Organization         AS Organization,
	|		GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		GoodsTable.Count                 AS Count,
	|		GoodsTable.Package                   AS Package
	|	FROM
	|		Document.SubcontractorReport2_5.ManufacturedProducts AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref IN (&References)
	|		AND NOT GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND NOT GoodsTable.ToExpenseAs
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsTable.Ref                     AS Ref,
	|		GoodsTable.Ref.Organization         AS Organization,
	|		GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		GoodsTable.Count                 AS Count,
	|		GoodsTable.Package                   AS Package
	|	FROM
	|		Document.SubcontractorReport2_5.SideAndIntermediateRelease AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref IN (&References)
	|		AND NOT GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND NOT GoodsTable.ToExpenseAs
	|	) AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.Organization,
	|	GoodsTable.ItemsLocationAttributes
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	BalancesDue.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	SUM(BalancesDue.ToReceive)        AS ToReceive
	|INTO BalancesDue
	|FROM
	|	(SELECT
	|		Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Table.CountBalance          AS ToReceive
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(,
	|			(ItemsLocationAttributes, Organization) IN
	|				(SELECT
	|					ProductsFromSubcontractorReport.ItemsLocationAttributes,
	|					ProductsFromSubcontractorReport.Organization
	|				FROM
	|					ProductsFromSubcontractorReport AS ProductsFromSubcontractorReport)
	|		) AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		-Table.Count                AS ToReceive
	|	FROM
	|		AccumulationRegister.CompanyGoods AS Table
	|	WHERE
	|		Table.Active
	|		AND Table.Recorder IN (&Recorder)
	|		AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	) AS BalancesDue
	|
	|GROUP BY
	|	BalancesDue.ItemsLocationAttributes
	|
	|HAVING
	|	SUM(BalancesDue.ToReceive) > 0
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsFromSubcontractorReport.Ref           AS Ref,
	|	ProductsFromSubcontractorReport.ItemsLocationAttributes.Products   AS Products,
	|	ProductsFromSubcontractorReport.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	ProductsFromSubcontractorReport.ItemsLocationAttributes.Purpose     AS Purpose,
	|	ProductsFromSubcontractorReport.ItemsLocationAttributes.Series          AS Series,
	|	ProductsFromSubcontractorReport.Package         AS Package,
	|	ProductsFromSubcontractorReport.Count       AS Count,
	|	MAX(BalancesDue.ToReceive) AS ToRegister
	|FROM
	|	ProductsFromSubcontractorReport AS ProductsFromSubcontractorReport
	|	
	|	INNER JOIN BalancesDue AS BalancesDue
	|	ON BalancesDue.ItemsLocationAttributes = ProductsFromSubcontractorReport.ItemsLocationAttributes
	|
	|GROUP BY
	|	ProductsFromSubcontractorReport.Ref,
	|	ProductsFromSubcontractorReport.ItemsLocationAttributes,
	|	ProductsFromSubcontractorReport.Package,
	|	ProductsFromSubcontractorReport.Count
	|
	|ORDER BY
	|	ProductsFromSubcontractorReport.ItemsLocationAttributes
	|";
	
	Return QueryText;
	
EndFunction

// Fills in the table of the object according to the standards
// 
// Parameters:
// 	DocumentTable - TabularSection
// 	Standards - ValueTable
// 	CostGroupNumber - Number
// 	StructureOfActions - Structure
//
Procedure FillInStandards_(DocumentTable, Standards, CostGroupNumber = Undefined, StructureOfActions = Undefined)
	
	PriceFillingParameters_ = Undefined;
	FillInSalePrice    = False;
	If Not StructureOfActions = Undefined Then
		FillInSalePrice = StructureOfActions.Property("FillInSalePrice", PriceFillingParameters_)
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array;
	ProcessedRowsWithPrice = New Array;
	
	For Each CurRow In Standards Do
		
		NewRow = DocumentTable.Add();
		FillPropertyValues(NewRow, CurRow);
		
		If ValueIsFilled(CostGroupNumber)
			And Not ValueIsFilled(NewRow.CostGroupNumber) Then
			NewRow.CostGroupNumber = CostGroupNumber;
		EndIf;
		
		If FillInSalePrice
			And Not ValueIsFilled(NewRow.Price) Then
			ProcessedRowsWithPrice.Add(NewRow);
		ElsIf Not StructureOfActions = Undefined Then
			RowsToProcess.Add(NewRow);
		EndIf;
		
	EndDo;

	If Not StructureOfActions = Undefined Then
		
		If FillInSalePrice Then
			StructureOfActions.Delete("FillInSalePrice");
		EndIf;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			DocumentTable,
			CachedValues);
		
		If FillInSalePrice Then
			StructureOfActions.Insert("FillInSalePrice", PriceFillingParameters_);
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				ProcessedRowsWithPrice,
				StructureOfActions,
				DocumentTable,
				CachedValues);
		EndIf;
		
	EndIf;

EndProcedure

Procedure FillInSeriesOfReceipts(ProductTable_, TableOfSeries, Var_Key)
	
	Filter = New Structure(Var_Key);
	For Each RowWithProductItem In ProductTable_ Do
		
		NumberOfProducts = RowWithProductItem.Count;
		FillPropertyValues(Filter, RowWithProductItem);
		
		For Each SeriesString In TableOfSeries.FindRows(Filter) Do
			
			If SeriesString.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(NumberOfProducts, SeriesString.Count);
			
			NewRow = ProductTable_.Add();
			FillPropertyValues(NewRow, RowWithProductItem);
			FillPropertyValues(NewRow, SeriesString, "Series");
			
			NewRow.Count = Count;
			
			SeriesString.Count   = SeriesString.Count - NewRow.Count;
			RowWithProductItem.Count = RowWithProductItem.Count - NewRow.Count;
			NumberOfProducts        = NumberOfProducts - NewRow.Count;
			
			If NumberOfProducts = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	RowFilter = New Structure("Count", 0);
	For Each TableRow In ProductTable_.FindRows(RowFilter) Do
		ProductTable_.Delete(TableRow);
	EndDo;
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	// Printed forms are not provided
	SubcontractorReport2_5Localization.AddPrintCommands(PrintCommands);

EndProcedure

#EndRegion

#Region CostGroups

Procedure UpdateCostGroup(CostGroups, CostGroupDescription)
	
	FilterStructure1 = New Structure("CostGroupNumber", CostGroupDescription.CostGroupNumber);
	FoundRows = CostGroups.FindRows(FilterStructure1);
	If Not FoundRows.Count() = 0 Then
		FillPropertyValues(FoundRows[0], CostGroupDescription);
	EndIf;
	
EndProcedure

Function ThereIsImportedProduct(Object, CostGroupNumber)
	
	Result = False;
	
	FilterStructure1 = New Structure("CostGroupNumber, TheRecordsAreKeptByCCD", CostGroupNumber, 1);
	
	Result = Not Object.ManufacturedProducts.FindRows(FilterStructure1).Count() = 0;
	If Result = True Then
		Return Result;
	EndIf;
	
	Result = Not Object.SideAndIntermediateRelease.FindRows(FilterStructure1).Count() = 0;
	Return Result;
	
EndFunction

#EndRegion

#Region ProductionLots

// Generates a batch production of the document.
// Parameters:
//  Object - DocumentObject.SubcontractorReport2_5, DocumentRef.SubcontractorReport2_5 - the object for which it is necessary to form the batch production.
//
Procedure FormProductionBatches(Object) Export
	
	Attributes = Object;
	
	If TypeOf(Object) = Type("DocumentRef.SubcontractorReport2_5") Then
		AttributesList =  "Ref, Date, Organization, GroupCosts, PurchaseForActivity,
							|LineOfBusiness";
		Attributes = Common.ObjectAttributesValues(Object, AttributesList);
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("Ref",						Attributes.Ref);
	Query.SetParameter("Date",						Attributes.Date);
	Query.SetParameter("Organization",				Attributes.Organization);
	Query.SetParameter("GroupCosts",			Attributes.GroupCosts);
	Query.SetParameter("PurchaseForActivity",		Attributes.PurchaseForActivity);
	Query.SetParameter("LineOfBusiness",	Attributes.LineOfBusiness);
	
	GenerateProductionTable(Object, Query);
	
	TextSelectionOfBatchFields = TextSelectionOfBatchFields();
	Catalogs.ProductionLots.FormProductionBatches(
		Query,
		TextSelectionOfBatchFields,
		True,
		True);
	
EndProcedure

Procedure GenerateProductionTable(Object, Query)
	
	QueryText = 
	"SELECT
	|	&Ref							AS Ref,
	|	&Organization					AS Organization,
	|	&GroupCosts				AS GroupCosts,
	|	GoodsTable.LineNumber		AS LineNumber,
	|	GoodsTable.CostGroupNumber	AS CostGroupNumber,
	|	FALSE							AS InternalSubcontracting,
	|	VALUE(Catalog.Companies.EmptyRef) AS MaterialProviderCompany,
	|	GoodsTable.Products		AS Products,
	|	GoodsTable.Characteristic	AS Characteristic,
	|	GoodsTable.Series				AS Series,
	|	GoodsTable.BillOfMaterials		AS BillOfMaterials,
	|	GoodsTable.Purpose		AS Purpose
	|INTO TableProduction
	|FROM
	|	&OutputProductTable AS GoodsTable
	|
	|WHERE
	|	&LinkCondition_
	|
	|INDEX BY
	|	CostGroupNumber
	|";
	
	If TypeOf(Object) = Type("DocumentRef.SubcontractorReport2_5") Then
		QueryText = StrReplace(QueryText, "&OutputProductTable", "Document.SubcontractorReport2_5.ManufacturedProducts");
		QueryText = StrReplace(QueryText, "&LinkCondition_", "GoodsTable.Ref = &Ref");
	Else
		QueryText = StrReplace(QueryText, "&LinkCondition_", "TRUE");
		Query.SetParameter("OutputProductTable", Object.ManufacturedProducts.Unload());
	EndIf;
	
	Query.Text = QueryText;
	Query.Execute();
	
EndProcedure

Function TextSelectionOfBatchFields()
	
	Return
	"SELECT
	|	&Ref													AS Document,
	|	TableProduction.GroupCosts						AS GroupCosts,
	|	TableProduction.CostGroupNumber						AS CostGroupNumber,
	|	TableProduction.Organization							AS Organization,
	|	FALSE													AS InternalSubcontracting,
	|	UNDEFINED											AS ProcessType,
	|	CASE
	|		WHEN &GroupCosts IN
	|				(VALUE(Enum.CostGroupingsInTollingOrder.NoGrouping),
	|				VALUE(Enum.CostGroupingsInTollingOrder.ByProductBOM))
	|			THEN &LineOfBusiness
	|		ELSE ISNULL(TableProduction.Purpose.LineOfBusiness, UNDEFINED)
	|	END													AS LineOfBusiness,
	|	&PurchaseForActivity									AS VATActivityType,
	|	MainProducts.Products							AS MainProductProducts,
	|	MainProducts.Characteristic							AS MainProductCharacteristic,
	|	CASE
	|		WHEN &GroupCosts IN
	|				(VALUE(Enum.CostGroupingsInTollingOrder.ByProducts),
	|				VALUE(Enum.CostGroupingsInTollingOrder.ByProductsAndAssignments))
	|			THEN TableProduction.Products
	|		ELSE UNDEFINED
	|	END													AS Products,
	|	CASE
	|		WHEN &GroupCosts IN
	|				(VALUE(Enum.CostGroupingsInTollingOrder.ByProducts),
	|				VALUE(Enum.CostGroupingsInTollingOrder.ByProductsAndAssignments))
	|			THEN TableProduction.Characteristic
	|		ELSE UNDEFINED
	|	END													AS Characteristic,
	|	CASE
	|		WHEN &GroupCosts IN
	|				(VALUE(Enum.CostGroupingsInTollingOrder.ByProducts),
	|				VALUE(Enum.CostGroupingsInTollingOrder.ByProductsAndAssignments))
	|			THEN TableProduction.Series
	|		ELSE UNDEFINED
	|	END													AS Series,
	|	MainProducts.Products.AnalyticalGroup	AS ProductsGroup,
	|	CASE
	|		WHEN &GroupCosts IN
	|				(VALUE(Enum.CostGroupingsInTollingOrder.ByProductBOM),
	|				VALUE(Enum.CostGroupingsInTollingOrder.ByProductBOMAndAssignments))
	|			THEN TableProduction.BillOfMaterials
	|		ELSE UNDEFINED
	|	END													AS BillOfMaterials,
	|	CASE
	|		WHEN &GroupCosts IN
	|				(VALUE(Enum.CostGroupingsInTollingOrder.ByProductsAndAssignments),
	|				VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages),
	|				VALUE(Enum.CostGroupingsInTollingOrder.ByProductBOMAndAssignments))
	|			THEN TableProduction.Purpose
	|		ELSE UNDEFINED
	|	END													AS Purpose
	|INTO TTProductionBatchFields
	|FROM
	|	TableProduction AS TableProduction
	|
	|	INNER JOIN LineNumbersOfMainProducts AS LineNumbersOfMainProducts
	|	ON LineNumbersOfMainProducts.CostGroupNumber = TableProduction.CostGroupNumber
	|	AND LineNumbersOfMainProducts.Ref = &Ref
	|
	|	INNER JOIN TableProduction AS MainProducts
	|	ON MainProducts.LineNumber = LineNumbersOfMainProducts.LineNumber
	|	AND MainProducts.Ref = &Ref
	|
	|WHERE
	|	VALUETYPE(&Ref) = TYPE(Document.SubcontractorReport2_5)
	|";
	
EndFunction

#EndRegion

#Region Other

// Returns a table of settlement amounts broken down by container/non-container and broken down by order.
// 
// Parameters:
//  ObjectReference_ - DocumentRef.SubcontractorReport2_5 - The document for which you want to get the data.
//  AttributesValues - Structure
// 
// Returns:
//  ValueTable - ValueTable:
// 		* OrderDocument - DocumentRef - OrderDocument
// 		* Date - Date - Document date
// 		* ApprovalDate - Date - Approval date (for orders)
// 		* DateOfShipment - Date - Scheduled shipment date
// 		* AmountARAP - Number - Amount Of Settlements By Line
// 		* AmountARAPByPackage - Number - The amount of settlements by container by line
Function OrderAmounts(ObjectReference_, AttributesValues = Undefined) Export
	
	Query = New Query;
	
	Query.Text = "
	|SELECT
	|	Services.SubcontractOrder		AS OrderDocument,
	|	Services.AmountIncludingVAT				AS Sum,
	|	Services.AmountARAP		AS AmountARAP,
	|	Services.Products				AS Products,
	|	&OrderingCaps				AS SubcontractOrder
	|INTO TTServices
	|FROM &ValueTable AS Services
	|WHERE &LinkCondition_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	CASE WHEN ISNULL(Services.OrderDocument.Number, """") = """"
	|				THEN Services.SubcontractOrder
	|			ELSE Services.OrderDocument
	|	END			AS OrderDocument,
	|	CASE WHEN ISNULL(Services.OrderDocument.Number, """") = """"
	|				THEN ISNULL(Services.SubcontractOrder.DATE, DATETIME(1,1,1))
	|			ELSE ISNULL(Services.OrderDocument.DATE, DATETIME(1,1,1))
	|	END			AS OrderDate,
	|	CASE WHEN ISNULL(Services.OrderDocument.Number, """") = """"
	|				THEN ISNULL(Services.SubcontractOrder.DATE, DATETIME(1,1,1))
	|			ELSE ISNULL(Services.OrderDocument.DATE, DATETIME(1,1,1))
	|	END			AS ApprovalDate,
	|	FALSE			AS ExceedingOrder,
	|	SUM(Services.Sum)					AS PaymentAmount,
	|	SUM(Services.AmountARAP)	AS AmountARAP,
	|	0				AS PackageDepositValue,
	|	0				AS AmountARAPByPackage
	|FROM
	|	TTServices AS Services
	|
	|GROUP BY
	|	CASE WHEN ISNULL(Services.OrderDocument.Number, """") = """"
	|				THEN Services.SubcontractOrder
	|			ELSE Services.OrderDocument
	|	END,
	|	CASE WHEN ISNULL(Services.OrderDocument.Number, """") = """"
	|				THEN ISNULL(Services.SubcontractOrder.DATE, DATETIME(1,1,1))
	|			ELSE ISNULL(Services.OrderDocument.DATE, DATETIME(1,1,1))
	|	END,
	|	CASE WHEN ISNULL(Services.OrderDocument.Number, """") = """"
	|				THEN ISNULL(Services.SubcontractOrder.DATE, DATETIME(1,1,1))
	|			ELSE ISNULL(Services.OrderDocument.DATE, DATETIME(1,1,1))
	|	END
	|";
	
	If AttributesValues = Undefined Then
		Query.Text = StrReplace(Query.Text, "&ValueTable", "Document.SubcontractorReport2_5.Services");
		Query.Text = StrReplace(Query.Text, "&OrderingCaps", "Services.Ref.SubcontractOrder");
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "Services.Ref = &Ref");
		Query.SetParameter("Ref",ObjectReference_);
	Else
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "TRUE");
		For Each KeyValue In AttributesValues Do
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// Parameters:
//  ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	CommonQueryParameters = ToDoListServer.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.SubcontractorReport2_5))
		And AccessRight("View", Metadata.Documents.SubcontractOrder2_5)
		And (AccessRight("Insert", Metadata.Documents.SubcontractorReport2_5)
			Or AccessRight("Update", Metadata.Documents.SubcontractorReport2_5))
		And GetFunctionalOption("UseProductionByThirdParty2_5");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	ProductionOperationsAtProcessor2_5 = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ProductionByToller2_5);
	
	FilterParameters =
		InvoicesServer.OrderSelectionParameters(,,,
			ProductionOperationsAtProcessor2_5,
			CommonQueryParameters.User);
	
	QueriesTexts =
		DataProcessors.DocumentsOfTransferToTollingAll2_5.QueriesTexts(
			FilterParameters,
			ProductionOperationsAtProcessor2_5);
	
	Query = New Query(QueriesTexts.StatusCalculationQueryText);
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("BusinessTransaction",       ProductionOperationsAtProcessor2_5);
	Query.SetParameter("Manager",          CommonQueryParameters.User);
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	
	Query.Execute();
	
	Query.Text = QueriesTexts.TextOfDirectiveListRequest;
	SubcontractorReportsForRegistration = Query.Execute().Select().Count();
	
	// Filling out cases.
	// Production outside
	UserTaskParent = ToDoList.Find("ProductionByThirdParty", "Id");
	If UserTaskParent = Undefined Then
		UserTaskParent = ToDoList.Add();
		UserTaskParent.Id  = "ProductionByThirdParty";
		UserTaskParent.Presentation  = NStr("vi = 'Sản xuất bên ngoài';
											|ru = 'Производство на стороне';
											|en = 'Production by third party'; fa = 'تولید توسط شخص ثالث';
											|it = 'Produzione esterna';
											|pl = 'Produkcja postronna';
											|tr = 'Fason üretim'");
		UserTaskParent.Owner       = Metadata.Subsystems.Production;
	EndIf;
	UserTaskParent.HasToDoItems = UserTaskParent.HasToDoItems Or SubcontractorReportsForRegistration > 0;
	
	// SubcontractorReportsForRegistration
	FilterParameters = New Structure;
	FilterParameters.Insert("Manager",     CommonQueryParameters.User);
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentPageName", "ReportsPage");
	FormParameters.Insert("QuickFilterStructure", FilterParameters);
	FormParameters.Insert("FormAssignmentKey", "ToDoList");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "SubcontractorReportsForRegistration2_5";
	ToDoItem.HasToDoItems       = SubcontractorReportsForRegistration > 0;
	ToDoItem.Presentation  = NStr("vi = 'Bảng kê của người nhận gia công cần lập chứng từ';
									|ru = 'Отчеты переработчиков к оформлению';
									|en = '""Subcontracting services notifications received"" for registration'; fa = '""Subcontracting services notifications received"" for registration';
									|it = 'I report dei prestatori per la formalizzazione';
									|pl = 'raporty przetwórców do wystawienia';
									|tr = 'Düzenlenecek fason üretici hizmetleri bildirimleri'");
	ToDoItem.Count     = SubcontractorReportsForRegistration;
	ToDoItem.Important         = False;
	ToDoItem.Form          = "DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices";
	ToDoItem.FormParameters = FormParameters;
	ToDoItem.Owner       = "ProductionByThirdParty";
	
EndProcedure

#EndRegion

#Region FormationOfHyperlinkInJournalOfProcessingDocuments

// Returns the hyperlink text for the transition from the document log to the design workspace.
// 
// Parameters:
// 	Parameters - Structure - parameters for forming the hyperlink text.
// Returns:
// 	FormattedString, Undefined - LongDesc
Function CreateHyperlinkToDesign(Parameters) Export
	
	HaveReadRights =
		AccessRight("Read", Metadata.AccumulationRegisters.PurchaseOrders)
		And AccessRight("Read", Metadata.AccumulationRegisters.CompanyGoods);
	
	If Not HaveReadRights Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Bảng kê';
						|ru = 'Отчеты';
						|en = 'Reports'; fa = 'گزارش‌ها';
						|it = 'Report';
						|pl = 'Raporty';
						|tr = 'Raporlar'");
	HyperlinkAnchorText = "DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices/ReportsPage";
	
	ThereAreDocumentsForRegistration =
		DataProcessors.DocumentsOfTransferToTollingAll2_5.ThereAreDocumentsForRegistration(
			Parameters,
			PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ProductionByToller2_5));
	
	ColorOfHyperlink = ?(ThereAreDocumentsForRegistration, Undefined, StyleColors.EmptyTableField);
	
	Return New FormattedString(HyperlinkText,, ColorOfHyperlink,, HyperlinkAnchorText);
	
EndFunction

#EndRegion

#EndRegion

#EndIf

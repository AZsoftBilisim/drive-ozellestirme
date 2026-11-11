#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
EndProcedure

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on.
//
// Returns:
//	String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Warehouse,Date";
	
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//	Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//	See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	UseWarehouseManagemantSystemForGoodsReceipt = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(
												Object.Warehouse,
												Object.Date);
	
	SeriesSpecificationParameters.UseItemsBatch	= (WarehouseSeriesParameters.UseItemsBatch
																	And Not UseWarehouseManagemantSystemForGoodsReceipt)
																Or WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseCostAccountingByBatches	= WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.SeriesOnlyForCostPrice		= True;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.MovementInFinancialAccounting);
	
	SeriesSpecificationParameters.Date			= Object.Date;
	SeriesSpecificationParameters.ThisIsAnInvoice	= True;
	SeriesSpecificationParameters.NameTSGoods	= "Discrepancies";
	SeriesSpecificationParameters.TSSeriesName	= "Discrepancies";
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.LinkFields.Add("DiscrepanciesKind");
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusInWarehouses");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusGoodsAtPartners");
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses of specifying series.
//
// Parameters:
//	SeriesSpecificationParameters - See ProductsClientServer.SeriesSpecificationParameters.
//
// Returns:
//	String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.LineNumber		AS LineNumber,
	|	Goods.DiscrepanciesKind	AS DiscrepanciesKind,
	|	Goods.Products		AS Products,
	|	Goods.Characteristic	AS Characteristic,
	|	Goods.Purpose		AS Purpose,
	|	Goods.Series			AS Series,
	|	Goods.Count		AS Count,
	// The Status fields for specifying documnet series.
	|	Goods.BatchesIndicationStatus					AS BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusInWarehouses			AS BatchesIndicationStatusInWarehouses,
	|	Goods.BatchesIndicationStatusGoodsAtPartners	AS BatchesIndicationStatusGoodsAtPartners
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	// Fields of old Statuses for specifying documnet series.
	|	Goods.BatchesIndicationStatus					AS OldStatusOfSpecifyingSeries,
	|	Goods.BatchesIndicationStatusInWarehouses 		AS OldStatusOfSpecifyingSeriesInWarehouses,
	|	Goods.BatchesIndicationStatusGoodsAtPartners	AS OldProductSeriesIndicationStatusFromPartners,
	// Fields for calculating the current Status of specifying documnet series.
	|	CASE
	|		WHEN SeriesAccountingPolicyData.BatchAccountingPolicy IS NULL
	|				OR Goods.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)
	|			THEN 0
	|		ELSE CASE
	|				WHEN SeriesAccountingPolicyData.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 14
	|							ELSE 13
	|						END
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatus,
	|	CASE
	|		WHEN ProductTypeData.BatchAccountingPolicy IS NULL
	|				OR Goods.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)
	|			THEN 0
	|		ELSE CASE
	|				WHEN ProductTypeData.BatchAccountingPolicy.UseCostAccountingByBatches
	|						AND (ProductTypeData.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor
	|							OR ProductTypeData.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries)
	|					THEN CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 18
	|							ELSE 17
	|						END
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatusGoodsAtPartners
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON Goods.Products = CatalogProducts.Ref
	|		
	|		INNER JOIN Catalog.ItemKinds AS ProductTypeData
	|		ON CatalogProducts.ProductKind = ProductTypeData.Ref
	|		
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS SeriesAccountingPolicyData
	|		ON CatalogProducts.ProductKind = SeriesAccountingPolicyData.Ref
	|			AND &Warehouse = SeriesAccountingPolicyData.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber							AS LineNumber,
	|	Statuses.BatchesIndicationStatus					AS BatchesIndicationStatusInWarehouses,
	|	Statuses.BatchesIndicationStatusGoodsAtPartners	AS BatchesIndicationStatusGoodsAtPartners,
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchesIndicationStatusGoodsAtPartners
	|		ELSE Statuses.BatchesIndicationStatus
	|	END										AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|
	|WHERE
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchesIndicationStatusGoodsAtPartners
	|		ELSE Statuses.BatchesIndicationStatus
	|	END <> Statuses.OldStatusOfSpecifyingSeries
	|	OR Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeriesInWarehouses
	|	OR Statuses.BatchesIndicationStatusGoodsAtPartners <> Statuses.BatchesIndicationStatusGoodsAtPartners
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("DocumentCorrection");
	
	WriteOffDiscrepanciesBetweenReceiptAndPurchaseLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  ValueList, Structure - Data of the document for conducting
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.WriteOffDiscrepanciesBetweenReceiptAndPurchase") Then
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

		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		WriteOffDiscrepanciesBetweenReceiptAndPurchaseLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
	EndIf;

	ReflectStockDistribution(Query, QueryTexts, Registers);
	IssueReceiptOfGoodsWriteOffOnTwoWayBasis(Query, QueryTexts, Registers);

	DocumentsPosting.AddRequestsStornow(
		Query, QueryTexts, Registers, Metadata.Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase);
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(
		DocumentRef, Query, QueryTexts, Registers);
	
	//
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);

EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export

	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	WriteOffDiscrepanciesBetweenReceiptAndPurchaseLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Populates the list of creation commands based on.
//
// Parameters:
//   CreateCommandsBasedOn - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//   ValueTable - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
Function AddGenerateCommand(CreateCommandsBasedOn) Export
	
	If AccessRight("Insert", Metadata.Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase) Then
		
		CreateBasedOnCommand = CreateCommandsBasedOn.Add();
		CreateBasedOnCommand.Id = Metadata.Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase);
		CreateBasedOnCommand.VerificationOfImplementationBeforeCreationBasedOn = True;
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#Region Print
// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// The act of receiving goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ActOfWritingOffDiscrepancies";
	PrintCommand.Presentation = NStr("vi = 'Biên bản ghi giảm chênh lệch';
									|ru = 'Акт списания расхождений';
									|en = 'Discrepancy write-off report'; fa = 'گزارش اسقاط مغایرت';
									|it = 'Акт списания расхождений';
									|pl = 'Discrepancy write-off report';
									|tr = 'Tutarsızlık gider yazılması tutanağı'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	PrintCommand.AdditionalParameters.Insert("NoExtraCharge");
	
	WriteOffDiscrepanciesBetweenReceiptAndPurchaseLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActOfWritingOffDiscrepancies") Then

		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "ActOfWritingOffDiscrepancies",
				NStr("vi = 'Biên bản ghi giảm chênh lệch';
					|ru = 'Акт списания расхождений';
					|en = 'Discrepancy write-off report'; fa = 'گزارش اسقاط مغایرت';
					|it = 'Акт списания расхождений';
					|pl = 'Discrepancy write-off report';
					|tr = 'Tutarsızlık gider yazılması tutanağı'"),
				PrintingCertificateOfWriteOffOfDiscrepancies(ObjectsArray, PrintObjects));

	EndIf;
	WriteOffDiscrepanciesBetweenReceiptAndPurchaseLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	If Not GetFunctionalOption("UseDeliveryManagement")
		And Not GoodsDeliveryClientServer.UsedDelivery25()  Then
		
		Return;
		
	EndIf;
	
	PrintObjectDataStructure.PrimaryRecipient = "CarrierPartner";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("CarrierPartner");
	
EndProcedure


#EndRegion

#Region InterfaceImplementation
// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Warehouse)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Department)";

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

#Region Other
// Returns a structure with the name of the tabular parts of the document that store information about the goods.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* Discrepancies - ValueTable, TabularSection, Undefined - data about the goods of the document.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure("Discrepancies");
	
	Return DocumentTables;
	
EndFunction
#EndRegion

#Region VATAccounting

// Returns parameters for filling in the VAT activity type.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.ReceiptOfGoodsToWarehouse, DocumentObject.ReceiptOfGoodsToWarehouse - 
//				document of receipt of goods to the warehouse.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.The parameters of the filling of the Activity Index().
//
Function ParametersForFillingInVATActivityType(Document) Export
	
	DocumentAttributes = New Structure("Date, Organization, Warehouse, Contract, LineOfBusiness, Department");
	
	If TypeOf(Document) = Type("DocumentRef.WriteOffDiscrepanciesBetweenReceiptAndPurchase") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillPropertyValues(FillParameters, DocumentAttributes);
	
	Return FillParameters;
	
EndFunction

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return WriteOffDiscrepanciesBetweenReceiptAndPurchaseLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//   String - the generated request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return WriteOffDiscrepanciesBetweenReceiptAndPurchaseLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion
#Region Other
// The procedure for processing the document when changing the direction of activity.
// 
// Parameters:
//  Form - ClientApplicationForm
// 
// Returns:
// See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Discrepancies";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Discrepancies", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
// Returns:
//	See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	// Needs for goods in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True,
																		"Object.Discrepancies.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products = "Object.Discrepancies.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Discrepancies.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Warehouse";
	
	Return FormTemplate;
	
EndFunction

// Fills in the parameters of a request that retrieves data about business operations used in the document.
//
// Parameters:
//	QueryOptions - Structure - request parameters to initialize:
//		* BusinessTransactionsPurchasingFromSupplier				 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsImportPurchase				 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsProcurementInEAEUCountries			 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsAdmissionToCommission				 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsGoodsInTransit					 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsUnfacturedDeliveries		 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsDoNotShareProcurementProcessing	 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//
Procedure FillInParametersOfBusinessOperations(QueryOptions) Export
	
	UseGoodsInTransitFromVendors = GetFunctionalOption("UseGoodsInTransitFromVendors");
	UseUninvoicedDeliveries = GetFunctionalOption("UseUninvoicedDeliveries");
	
	BusinessTransactionsPurchasingFromSupplier = New Array;
	
	If UseGoodsInTransitFromVendors Then
		BusinessTransactionsPurchasingFromSupplier.Add(
			Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit);
	EndIf;
	
	If UseUninvoicedDeliveries Then
		BusinessTransactionsPurchasingFromSupplier.Add(Enums.BusinessTransactions.
			PurchaseFromVendorUninvoicedDelivery);
	EndIf;
	
	BusinessTransactionsGoodsInTransit = New Array;
	If UseGoodsInTransitFromVendors Then
		BusinessTransactionsGoodsInTransit.Add(Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit);
	EndIf;
	
	BusinessTransactionsUnfacturedDeliveries = New Array;
	If UseUninvoicedDeliveries Then
		BusinessTransactionsUnfacturedDeliveries.Add(
			Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery);
		
	EndIf;
	
	QueryOptions.BusinessTransactionsGoodsInTransit                  = BusinessTransactionsGoodsInTransit;
	QueryOptions.BusinessTransactionsUnfacturedDeliveries    = BusinessTransactionsUnfacturedDeliveries;
	
EndProcedure

// Returns the parameters of the selection of articles and analyst.
//
// Parameters:
// 	Parameters - Structure - A structure whose properties contain values 
//            that affect the availability of the operation: There are over-deliveries, there are under-deliveries, and the processing of the fill check.
// 
// Returns:
//	Structure - Article and analyst selection options (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//             .
//
Function ItemsAndDimensionsSelectionParameters(Parameters) Export
	ChoiceParametersArray = New Array;
	
	#Region IncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef      = "IncomeItem";
	ChoiceParameters.ArticleType   = "IncomeItemItemType";
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;
	
	If Parameters.Property("ThereAreOverpayments") And
		Not Parameters.ThereAreOverpayments And
		Parameters.Property("FillCheckProcessing") And
		Parameters.FillCheckProcessing Then
		
		ChoiceParameters.AvailabilityByOperation = False;

	EndIf;

	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue   = "DimensionOfRevenue";

	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension   = "DimensionLiabilities_";
	
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionLiabilities_");

	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion	
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef      = "ExpenseItem";
	ChoiceParameters.ArticleType   = "ExpenseItemItemType";
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;
	
	If Parameters.Property("ThereAreShortDeliveries") And
		Not Parameters.ThereAreShortDeliveries And
		Parameters.Property("FillCheckProcessing") And
		Parameters.FillCheckProcessing Then
		
		ChoiceParameters.AvailabilityByOperation = False;

	EndIf;

	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses   = "DimensionOfExpenses";

	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension   = "DimensionOfAssets";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionOfAssets");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	Return ChoiceParametersArray;
	
EndFunction

// Returns parameters for setting up accounting accounts in the document.
// 
// Returns:
// 	Array of See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_() Export

	ParametersArray = New Array();
	
	#Region AssetAccountingAccount	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.GLAccountSettings = "AssetGLAccountsSettings";
	SetupParameters.Presentation = "TextSetUpRecordOfAssetsInComplAccounting";
	
	SetupParameters.ArticleType = "ExpenseItemItemType";
	
	
	SetupParameters.Organization = "Object.Organization";
	SetupParameters.AssetsLiabilitiesDimension = "DimensionOfAssets";

	SetupParameters.FormItems.Add("TextSetUpRecordOfAssetsInComplAccounting");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	#Region LiabilityAccount	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.GLAccountSettings = "LiabilitiesGLAccountsSettings";
	SetupParameters.Presentation = "TextSetUpRecordOfLiabilitiesInComplAccounting";
	
	SetupParameters.ArticleType = "IncomeItemItemType";
	SetupParameters.AssetAndLiabilityItem = "IncomeItem";
	
	SetupParameters.Organization = "Object.Organization";
	SetupParameters.AssetsLiabilitiesDimension = "DimensionLiabilities_";

	SetupParameters.FormItems.Add("TextSetUpRecordOfLiabilitiesInComplAccounting");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction


// Returns the value of the receipt or shipment order.
//
// Parameters:
//  FieldValuesToIdentifyReferences - Structure - the composition of the fields is determined by the value
//  of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//  DocumentRef - a link to an order for performing a warehouse operation.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	Return FieldValuesToIdentifyReferences.Ref;
EndFunction

#EndRegion

// Fills In The TS discrepancies between receipt and purchase.
//
// Parameters:
//	Discrepancies                            - ValueTable - document discrepancy table,
//	FillParameters                    - See the filling parametersofactical acceptance
//
// Returns:
//	Boolean - A flag by which it can be determined that the PM of the document has changed as a result of re-filling.
//
Function FillInDiscrepanciesBetweenAdmissionAndPurchase(Discrepancies, FillParameters) Export
	CurrentDocument                        = FillParameters.CurrentDocument;
	StructureOfActionsWithAddedStrings = FillParameters.StructureOfActionsWithAddedStrings;
	Warehouse                                  = FillParameters.Warehouse;
	Terms                             = FillParameters.Terms;
	Contract                                = FillParameters.Contract;
	ReferenceArray                     = FillParameters.ReferenceArray;
	
	If ReferenceArray.Count() = 0 Then
		Return False;
	EndIf;

	HasChanges = False;
	ReferenceOrder = ReferenceArray[0];
	
	SetPrivilegedMode(True);
	
	WorksServices = New Array;
	WorksServices.Add(Enums.ItemsTypes.Work_5);
	WorksServices.Add(Enums.ItemsTypes.OperationService);

	Query = New Query(RequestTextDiscrepanciesReceiptPurchase());
	Query.SetParameter("DocumentBasis", ReferenceOrder);
	Query.SetParameter("WarehouseSpecified", ValueIsFilled(Warehouse));
	Query.SetParameter("WarehouseForReceipt", Warehouse);
	Query.SetParameter("WorksServices", WorksServices);
	Query.SetParameter("CurrentDocument", CurrentDocument);     
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return HasChanges;
	EndIf; 
	Selection = Result.Select();

	UnloadedColumns = "Products, Characteristic, Series, Package, Count, Purpose";
	Discrepancies.Clear();
	HasChanges = True;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	While Selection.Next() Do
		NewRow = Discrepancies.Add();
		FillPropertyValues(NewRow, Selection);
		RowsToProcess.Add(NewRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActionsWithAddedStrings,
		Discrepancies,
		CachedValues);
	
	Return HasChanges;
	
EndFunction

#EndRegion

#Region Private

#Region Posting

Procedure IssueReceiptOfGoodsWriteOffOnTwoWayBasis(Query, QueryTexts, Registers)

	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref			AS Ref,
	|	CASE
	|		WHEN HeaderData_.ReferenceOrder IN
	|				(UNDEFINED,
	|				VALUE(Document.PurchaseOrder.EmptyRef),
	|				VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef),
	|				VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|				)
	|			THEN DataSource.Ref
	|		ELSE HeaderData_.ReferenceOrder
	|	END							AS Invoice,
	|	DataSource.DiscrepanciesKind	AS DiscrepanciesKind,
	|	UNDEFINED					AS GoodsReceiptOption,
	|	HeaderData_.ReferenceOrder		AS OrderDocument,
	|	HeaderData_.Contract				AS Contract,
	|	HeaderData_.Terms			AS Terms,
	|	HeaderData_.Date				AS Date,
	|	DataSource.Products		AS Products,
	|	DataSource.Characteristic	AS Characteristic,
	|	DataSource.Purpose		AS Purpose,
	// The Operation makes the Registered Records for the goods to be received. In procurement, this Operation is always with an empty Lot reference.
	|	FALSE							AS ToControlQuality,
	|	FALSE							AS RecordOfAPreviouslyReceivedLot,
	|	UNDEFINED					AS ControlledLotReference,
	|	DataSource.Series			AS Series,
	|	DataSource.BatchesIndicationStatusGoodsAtPartners AS BatchesIndicationStatus,
	|	FALSE							AS ExceedingOrder,
	|	CASE
	|		WHEN DataSource.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService),
	|															VALUE(Enum.ItemsTypes.Work_5))
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE HeaderData_.Warehouse
	|	END							AS Warehouse,
	|	HeaderData_.Partner				AS Sender,
	|	CASE
	|		WHEN VALUETYPE(HeaderData_.ReferenceOrder) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(HeaderData_.ReferenceOrder AS Catalog.CounterpartyContracts).BusinessOperation
	|		WHEN VALUETYPE(HeaderData_.ReferenceOrder) = TYPE(Document.PurchaseOrder)
	|			THEN CAST(HeaderData_.ReferenceOrder AS Document.PurchaseOrder).BusinessOperation
	|		WHEN VALUETYPE(HeaderData_.ReferenceOrder) = TYPE(Document.VendorInvoice)
	|			THEN CAST(HeaderData_.ReferenceOrder AS Document.VendorInvoice).BusinessOperation
	|		ELSE VALUE(Enum.BusinessTransactions.WriteOffDiscrepanciesBetweenReceiptAndPurchase)
	|	END							AS BusinessOperation,
	|	DataSource.Count		AS Count,
	|	FALSE							AS ThisIsAnInvoice,
	|	CASE
	|		WHEN HeaderData_.ReferenceOrder IN
	|				(UNDEFINED,
	|				VALUE(Document.PurchaseOrder.EmptyRef),
	|				VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef),
	|				VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|				)
	|			THEN FALSE
	|		ELSE TRUE
	|	END							AS ReceiptUnderOrders
	|FROM
	|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Discrepancies AS DataSource
	|		LEFT JOIN Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase AS HeaderData_
	|		ON DataSource.Ref = HeaderData_.Ref
	|WHERE
	|	DataSource.Ref IN (&Ref)
	|	AND DataSource.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
	|
	|UNION ALL
	|
	|SELECT
	|	DataSource.Ref			AS Ref,
	|	CASE
	|		WHEN HeaderData_.ReferenceOrder IN
	|				(UNDEFINED,
	|				VALUE(Document.PurchaseOrder.EmptyRef),
	|				VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef),
	|				VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|				)
	|			THEN DataSource.Ref
	|		ELSE HeaderData_.ReferenceOrder
	|	END							AS Invoice,
	|	DataSource.DiscrepanciesKind	AS DiscrepanciesKind,
	|	UNDEFINED					AS GoodsReceiptOption,
	|	HeaderData_.ReferenceOrder		AS OrderDocument,
	|	HeaderData_.Contract				AS Contract,
	|	HeaderData_.Terms			AS Terms,
	|	HeaderData_.Date				AS Date,
	|	DataSource.ItemsLocationAttributes.Products		AS Products,
	|	DataSource.ItemsLocationAttributes.Characteristic	AS Characteristic,
	|	DataSource.ItemsLocationAttributes.Purpose		AS Purpose,
	// The Operation makes the Registered Records for the goods to be received. In procurement, this Operation is always with an empty Lot reference.
	|	FALSE							AS ToControlQuality,
	|	FALSE							AS RecordOfAPreviouslyReceivedLot,
	|	UNDEFINED					AS ControlledLotReference,
	|	DataSource.ItemsLocationAttributes.Series				AS Series,
	|	CASE
	|		WHEN ISNULL(DataSource.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor, FALSE)
	|				OR ISNULL(DataSource.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries, FALSE)
	|			THEN 18
	|		ELSE 0
	|	END							AS BatchesIndicationStatus,
	|	FALSE							AS ExceedingOrder,
	|	CASE
	|		WHEN DataSource.ItemsLocationAttributes.Products.ItemsType IN
	|				(VALUE(Enum.ItemsTypes.OperationService),
	|				VALUE(Enum.ItemsTypes.Work_5))
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE HeaderData_.Warehouse
	|	END							AS Warehouse,
	|	HeaderData_.Partner				AS Sender,
	|	CASE
	|		WHEN VALUETYPE(HeaderData_.ReferenceOrder) = TYPE(Catalog.CounterpartyContracts)
	|			THEN CAST(HeaderData_.ReferenceOrder AS Catalog.CounterpartyContracts).BusinessOperation
	|		WHEN VALUETYPE(HeaderData_.ReferenceOrder) = TYPE(Document.PurchaseOrder)
	|			THEN CAST(HeaderData_.ReferenceOrder AS Document.PurchaseOrder).BusinessOperation
	|		WHEN VALUETYPE(HeaderData_.ReferenceOrder) = TYPE(Document.VendorInvoice)
	|			THEN CAST(HeaderData_.ReferenceOrder AS Document.VendorInvoice).BusinessOperation
	|		ELSE VALUE(Enum.BusinessTransactions.WriteOffDiscrepanciesBetweenReceiptAndPurchase)
	|	END							AS BusinessOperation,
	|	DataSource.Count		AS Count,
	|	FALSE							AS ThisIsAnInvoice,
	|	CASE
	|		WHEN HeaderData_.ReferenceOrder IN
	|				(UNDEFINED,
	|				VALUE(Document.PurchaseOrder.EmptyRef),
	|				VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef),
	|				VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|				)
	|			THEN FALSE
	|		ELSE TRUE
	|	END							AS ReceiptUnderOrders
	|FROM
	|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.InventoryKinds AS DataSource
	|		LEFT JOIN Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase AS HeaderData_
	|		ON DataSource.Ref = HeaderData_.Ref
	|WHERE
	|	DataSource.Ref IN (&Ref)
	|";
	
	CurrentMetadataObject1 = Metadata.Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase;
	
	WarehousesServer.IssueWriteOffOfDiscrepanciesInTwoWay(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		CurrentMetadataObject1);
	
EndProcedure

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	ReferenceOrder = Common.ObjectAttributeValue(DocumentRef, "ReferenceOrder");
	Query.Text = 
	"SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.ReferenceOrder AS ReferenceOrder,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Warehouse AS Warehouse,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.RegistrationCountry AS RegistrationCountry,
	|	DocumentData.Terms AS Terms,
	|	DocumentData.Terms.Currency AS AgreementCurrency,
	|	DocumentData.VATActivityType AS VATActivityType,
	|	DocumentData.Terms.PriceIncludesVAT AS PriceIncludesVATTerms,
	|	VALUE(Enum.BusinessTransactions.WriteOffDiscrepanciesBetweenReceiptAndPurchase) AS BusinessOperation,
	|	CASE 
	|		WHEN DocumentData.ReferenceOrder REFS Document.PurchaseOrder 
	|			THEN CAST(DocumentData.ReferenceOrder AS Document.PurchaseOrder).BusinessOperation
	|		WHEN DocumentData.ReferenceOrder REFS Document.VendorInvoice 
	|			THEN CAST(DocumentData.ReferenceOrder AS Document.VendorInvoice).BusinessOperation
	|		WHEN DocumentData.ReferenceOrder REFS Catalog.CounterpartyContracts
	|			THEN CAST(DocumentData.ReferenceOrder AS Catalog.CounterpartyContracts).BusinessOperation
	|	END AS BusinessTransactionOrders,
	|	DocumentData.Department AS Department,
	|	DocumentData.Department.OptionOfAssignedAccountingOfGoods AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Author AS Author,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Number AS Number,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Posted AS Posted,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
	|	DocumentData.Patch AS Patch,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.CorrectedDocument AS CorrectedDocument,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_
	|FROM
	|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON BusinessTransactionsSettings.BusinessOperation = &BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Query.SetParameter("BusinessOperation", Enums.BusinessTransactions.WriteOffDiscrepanciesBetweenReceiptAndPurchase);
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Attributes.Organization, Attributes.Period);
	
	Query.SetParameter("Period", 							Attributes.Period);
	Query.SetParameter("Ref", 							Attributes.Ref);
	
	Query.SetParameter("ReferenceOrder", 						Attributes.ReferenceOrder);
	Query.SetParameter("Organization", 						Attributes.Organization);
	Query.SetParameter("Partner", 							Attributes.Partner);
	Query.SetParameter("Counterparty", 						Attributes.Counterparty);
	Query.SetParameter("Warehouse",								Attributes.Warehouse);
	Query.SetParameter("RegistrationCountry", 					Attributes.RegistrationCountry);
	Query.SetParameter("Terms", 						Attributes.Terms);
	Query.SetParameter("VATActivityType", 				Attributes.VATActivityType);
	Query.SetParameter("BusinessOperation", 				Attributes.BusinessOperation);
	Query.SetParameter("BusinessTransactionOrders",	Attributes.BusinessTransactionOrders);
	Query.SetParameter("Department", 						Attributes.Department);
	Query.SetParameter("Contract", 							Attributes.Contract);
	Query.SetParameter("Author", 								Attributes.Author);
	Query.SetParameter("LineOfBusiness", 			Attributes.LineOfBusiness);
	Query.SetParameter("Number", 								Attributes.Number);
	Query.SetParameter("Comment", 						Attributes.Comment);
	Query.SetParameter("DeletionMark", 					Attributes.DeletionMark);
	Query.SetParameter("Posted", 							Attributes.Posted);
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
		GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("ControlCompanyStockBalanceForRegistrationByReceipts",
		GetFunctionalOption("ControlCompanyStockBalanceForRegistrationByReceipts"));
	Query.SetParameter("BusinessTransactionsImportPurchase",		PurchasesServer.BusinessOperationsOnMain(
																		Enums.BusinessTransactions.PurchaseByImport));
	Query.SetParameter("MetadataIdentifier",       		Common.MetadataObjectID(FullObjectName()));
	Query.SetParameter("TaxationOfOrganization",			AccountingParametersForOrganization.BasicTaxationVATSales);
	Query.SetParameter("BusinessTransactionSetting",     Attributes.BusinessTransactionSetting);
	
	Query.SetParameter("DocumentInflow", Attributes.ReferenceOrder);
	Query.SetParameter("Patch", 						Attributes.Patch);
	Query.SetParameter("ReversedDocument", 				Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument", 				Attributes.CorrectedDocument);
	Query.SetParameter("AdjustmentPeriod_", 				Attributes.AdjustmentPeriod_);
	
	PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations();
	BusinessTransactionForReceipt = PairsOfSeparatePurchaseOperations.Get(Attributes.BusinessOperation);
	BusinessTransactionForReceipt = ?(Not ValueIsFilled(BusinessTransactionForReceipt),
		Attributes.BusinessTransactionOrders,
		BusinessTransactionForReceipt);
	
	Query.SetParameter("BusinessTransactionForReceipt", BusinessTransactionForReceipt);
	
	ContractInformation = Undefined;
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	Query.SetParameter("ContractInformation", ContractInformation);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);

	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);

EndProcedure

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeProductAccountingAnalyticsKeys(Query);
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	&Period									AS Period,
	|	TableOfDiscrepancies.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributes,
	|	&Organization							AS Organization,
	|	TableOfDiscrepancies.InventoryOwnerAttribute			AS InventoryOwnerAttribute,
	|	UNDEFINED							AS CCDNumber,
	|	TableOfDiscrepancies.Count			AS Count,
	|	0										AS QuantityByGBRN,
	|	&BusinessOperation					AS BusinessOperation,
	|	UNDEFINED							AS ShipmentCompany,
	|	TRUE									AS Primary
	|FROM
	|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Discrepancies AS TableOfDiscrepancies
	|WHERE
	|	TableOfDiscrepancies.Ref = &Ref
	|	AND TableOfDiscrepancies.Products.ItemsType IN
	|			(VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND TableOfDiscrepancies.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)		AS RecordType,
	|	&Period										AS Period,
	|	PartnerAnalytics.DimensionKey			AS ItemsLocationAttributes,
	|	&Organization								AS Organization,
	|	InventoryKindTable.RecipientInventoryOwnerAttribute	AS InventoryOwnerAttribute,
	|	UNDEFINED								AS CCDNumber,
	|	InventoryKindTable.Count				AS Count,
	|	0											AS QuantityByGBRN,
	|	&BusinessOperation						AS BusinessOperation,
	|	UNDEFINED								AS ShipmentCompany,
	|	TRUE										AS Primary
	|FROM
	|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.InventoryKinds AS InventoryKindTable
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|		ON InventoryKindTable.ItemsLocationAttributes = Keys.Ref
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS PartnerAnalytics
	|		ON Keys.Products = PartnerAnalytics.Products
	|			AND Keys.Characteristic = PartnerAnalytics.Characteristic
	|			AND Keys.Series = PartnerAnalytics.Series
	|			AND Keys.Purpose = PartnerAnalytics.Purpose
	|			AND &Contract = PartnerAnalytics.StorageLocation
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = PartnerAnalytics.ProductCostElement
	|WHERE
	|	InventoryKindTable.Ref = &Ref
	|	AND Keys.Products.ItemsType IN
	|			(VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND &BusinessTransactionForReceipt IN
	|			(VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))	
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)			AS RecordType,
	|	&Period											AS Period,
	|	InventoryKindTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	&Organization									AS Organization,
	|	InventoryKindTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)		AS CCDNumber,
	|	InventoryKindTable.Count					AS Count,
	|	0												AS QuantityByGBRN,
	|	&BusinessOperation							AS BusinessOperation,
	|	UNDEFINED									AS ShipmentCompany,
	|	TRUE											AS Primary
	|FROM
	|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.InventoryKinds AS InventoryKindTable
	|WHERE
	|	InventoryKindTable.Ref = &Ref
	|	AND InventoryKindTable.ItemsLocationAttributes.Products.KeepRecordsByCCD
	|	AND InventoryKindTable.ItemsLocationAttributes.Products.ItemsType IN
	|			(VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND InventoryKindTable.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|	AND &BusinessTransactionForReceipt IN
	|			(VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)			AS RecordType,
	|	&Period											AS Period,
	|	InventoryKindTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	&Organization									AS Organization,
	|	InventoryKindTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	InventoryKindTable.CCDNumber					AS CCDNumber,
	|	InventoryKindTable.Count					AS Count,
	|	InventoryKindTable.QuantityByGBRN			AS QuantityByGBRN,
	|	&BusinessOperation							AS BusinessOperation,
	|	UNDEFINED									AS ShipmentCompany,
	|	TRUE											AS Primary
	|FROM
	|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.InventoryKinds AS InventoryKindTable
	|WHERE
	|	InventoryKindTable.Ref = &Ref
	|	AND InventoryKindTable.ItemsLocationAttributes.Products.KeepRecordsByCCD
	|	AND InventoryKindTable.ItemsLocationAttributes.Products.ItemsType IN 
	|			(VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND InventoryKindTable.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|	AND &BusinessTransactionForReceipt IN
	|			(VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
	|
	|UNION ALL
	|
	// Traceable Works
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)			AS RecordType,
	|	&Period											AS Period,
	|	InventoryKinds.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|	&Organization									AS Organization,
	|	InventoryKinds.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber							AS CCDNumber,
	|	InventoryKinds.Count							AS Count,
	|	InventoryKinds.QuantityByGBRN					AS QuantityByGBRN,
	|	&BusinessOperation							AS BusinessOperation,
	|	UNDEFINED									AS ShipmentCompany,
	|	TRUE											AS Primary
	|FROM
	|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|	AND InventoryKinds.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND InventoryKinds.ItemsLocationAttributes.Products.TracedGoods
	|	AND &UseTraceableImportedGoodsAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)			AS RecordType,
	|	&Period											AS Period,
	|	Discrepancies.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|	&Organization									AS Organization,
	|	Discrepancies.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
	|	UNDEFINED									AS CCDNumber,
	|	Discrepancies.Count							AS Count,
	|	0												AS QuantityByGBRN,
	|	&BusinessOperation							AS BusinessOperation,
	|	UNDEFINED									AS ShipmentCompany,
	|	TRUE											AS Primary
	|FROM
	|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Discrepancies AS Discrepancies
	|WHERE
	|	Discrepancies.Ref = &Ref
	|	AND Discrepancies.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND Discrepancies.ItemsLocationAttributes.Products.TracedGoods
	|	AND Discrepancies.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
	|	AND &UseTraceableImportedGoodsAccounting
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
	|	&Ref                  AS Ref,
	|	&Period                  AS IBDocumentDate,
	|	&Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization             AS Organization,
	|	VALUE(Enum.BusinessTransactions.WriteOffDiscrepanciesBetweenReceiptAndPurchase)   AS BusinessOperation,
	|	&Partner                 AS Partner,
	|	&Counterparty              AS Counterparty,
	|	&Contract                 AS Contract,        
	|	&LineOfBusiness AS LineOfBusiness,
	|	&Warehouse		             AS StorageLocation,
	|	&Department           AS Department,
	|	UNDEFINED             AS EmployeeResponsible,
	|	&Author                   AS Author,
	|	&Comment             AS Comment,
	|	UNDEFINED             AS Currency,
	|	UNDEFINED             AS Sum,
	|	UNDEFINED             AS Status,
	|	&Posted                AS Posted,
	|	&DeletionMark         AS DeletionMark,
	|	FALSE                     AS AdditionalRecord,
	|	&ContractInformation    AS More,
	|	UNDEFINED			 AS SourceDocumentDate,
	|	UNDEFINED			 AS SourceDocumentNumber,
	|	UNDEFINED	         AS SourceDocumentName,
	|	&Patch             AS ReverseTransactionCorrection,
	|	&ReversedDocument    AS ReversedDocument,
	|	&CorrectedDocument    AS CorrectedDocument,
	|	&Period                  AS RecordingInAccountingDate,
	|	UNDEFINED             AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text =
	"SELECT DISTINCT
	|	Table.Products	AS Products,
	|	Table.Characteristic	AS Characteristic,
	|	Table.Purpose		AS Purpose,
	|	Table.Series			AS Series,
	|	Table.Warehouse			AS Warehouse
	|FROM
	|	(SELECT
	|		Keys.Products		AS Products,
	|		Keys.Characteristic	AS Characteristic,
	|		&EmptyAssignment		AS Purpose,
	|		Keys.Series				AS Series,
	|		Keys.StorageLocation		AS Warehouse
	|	FROM
	|		Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.InventoryKinds AS Goods
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|			ON Goods.ItemsLocationAttributes = Keys.Ref
	|			
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Keys.Products = Dimension.Products
	|				AND Keys.Characteristic = Dimension.Characteristic
	|				AND Keys.Series = Dimension.Series
	|				AND Keys.StorageLocation = Dimension.StorageLocation
	|				AND &EmptyAssignment = Dimension.Purpose
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|	
	|	) AS Table";
	
	QueryAnalyst.SetParameter("Ref",				Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment",	Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("EmptyBatch_",		Catalogs.ItemsBatches.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments",
										Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	Selection = QueryAnalyst.Execute().Select();
	
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Function QueryTextTTTableOfComplianceOfHouseholdOperations()
	QueryText = 
	"SELECT
	|	CASE WHEN VALUETYPE(DocumentTable.ReferenceOrder) = TYPE(Document.PurchaseOrder)
	|		THEN
	|			CASE 
	|				WHEN CAST(DocumentTable.ReferenceOrder AS Document.PurchaseOrder).BusinessOperation = 
	|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt)
	|					THEN 
	|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery)
	|				WHEN CAST(DocumentTable.ReferenceOrder AS Document.PurchaseOrder).BusinessOperation = 
	|					VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery)
	|					THEN 
	|						VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery)
	|				WHEN CAST(DocumentTable.ReferenceOrder AS Document.PurchaseOrder).BusinessOperation = 
	|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit)
	|					THEN 
	|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit)
	|				WHEN CAST(DocumentTable.ReferenceOrder AS Document.PurchaseOrder).BusinessOperation = 
	|					VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit)
	|					THEN 
	|						VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit)
	|				WHEN CAST(DocumentTable.ReferenceOrder AS Document.PurchaseOrder).BusinessOperation = 
	|					VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
	|					THEN 
	|						VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit)
	|			END
	|	WHEN VALUETYPE(DocumentTable.ReferenceOrder) = TYPE(Catalog.CounterpartyContracts)
	|		THEN
	|			CASE 
	|				WHEN CAST(DocumentTable.ReferenceOrder AS Catalog.CounterpartyContracts).BusinessOperation = 
	|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery)
	|					THEN 
	|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt)
	|				WHEN CAST(DocumentTable.ReferenceOrder AS Catalog.CounterpartyContracts).BusinessOperation = 
	|					VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery)
	|					THEN 
	|						VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery)
	|				WHEN CAST(DocumentTable.ReferenceOrder AS Catalog.CounterpartyContracts).BusinessOperation = 
	|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit)
	|					THEN 
	|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit)
	|				WHEN CAST(DocumentTable.ReferenceOrder AS Catalog.CounterpartyContracts).BusinessOperation = 
	|					VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit)
	|					THEN 
	|						VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit)
	|				WHEN CAST(DocumentTable.ReferenceOrder AS Catalog.CounterpartyContracts).BusinessOperation = 
	|					VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
	|					THEN 
	|						VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit)
	|			END
	|	END AS HouseholdReceiptOperation
	|INTO TTTableOfComplianceOfHouseholdOperations
	|FROM
	|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase AS DocumentTable
	|WHERE
	|	DocumentTable.Ref = &Ref" + Common.QueryBatchSeparator()	;
	
	Return QueryText;
EndFunction

Function QueryTextTTTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTypesOfStocks";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	 
	InitializeProductAccountingAnalyticsKeys(Query);
	
	TextMatchingHouseholdOperations = QueryTextTTTableOfComplianceOfHouseholdOperations();
	
	QueryText = TextMatchingHouseholdOperations +
	"
	|SELECT
	|	TableOfDiscrepancies.Products AS Products,
	|	TableOfDiscrepancies.Characteristic AS Characteristic,
	|	TableOfDiscrepancies.Series AS Series,
	|	TableOfDiscrepancies.Ref.Warehouse AS Warehouse,
	|	TableOfDiscrepancies.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom AS ShopFloorStockroom,
	|	TableOfDiscrepancies.Purpose AS Purpose,
	|	TableOfDiscrepancies.DiscrepanciesKind AS DiscrepanciesKind,
	|	TableOfDiscrepancies.Ref.LineOfBusiness AS LineOfBusiness,
	|	BusinessTransactions.HouseholdReceiptOperation AS BusinessTransactionOrders,
	|	TableOfDiscrepancies.ItemsLocationAttributes AS DimensionOfProductItem,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfProductsWithoutAssignment,
	|	TableOfDiscrepancies.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributesGoodsAtPartners,
	|
	|	TableOfBatchAccountingAnalysts.VATTaxation AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|
	|	TableOfDiscrepancies.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableOfDiscrepancies.InventoryOwnerAttribute AS WarehouseInventoryAttributes,
	|	TableOfDiscrepancies.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	TableOfDiscrepancies.Count AS Count,
	|
	|	0 AS AmountIncludingVATMan,
	|	0 AS VATAmountMan,
	|	0 AS AmountExcludingVATMan,
	|	
	|	0 AS AmountExcludingVATCompl,
	|	0 AS VATAmountCompl,
	|
	|	TableOfDiscrepancies.RowID AS RowID
	|
	|INTO TTTypesOfStocks
	|FROM
	|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Discrepancies AS TableOfDiscrepancies
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON TableOfDiscrepancies.Products = AnalyticsWithoutAssignment.Products
	|			AND TableOfDiscrepancies.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND TableOfDiscrepancies.Series = AnalyticsWithoutAssignment.Series
	|			AND TableOfDiscrepancies.Ref.Warehouse = AnalyticsWithoutAssignment.StorageLocation
	|			AND (VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose)
	|			AND (VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement)
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber = TableOfDiscrepancies.LineNumber
	|		AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Discrepancies""
	|	LEFT JOIN TTTableOfComplianceOfHouseholdOperations AS BusinessTransactions
	|		ON (TRUE)
	|WHERE
	|	TableOfDiscrepancies.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName); 
	
	Return QueryText;
	
EndFunction	

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	LineNumberText = CostCalculationDocumentsPosting.RequestTextStringCodesForBatchAccountingAnalytics(
		Metadata.Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Name,
		"Discrepancies");
	
	TextSelectionOfAnalystField = LineNumberText + 
	"SELECT
	|	""Discrepancies"" AS TabularSectionName,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentData.Partner AS Vendor,
	|	DocumentData.Counterparty AS Counterparty,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	// the write-off of discrepancies on an unfactured postage or on goods in transit from suppliers always refers
	// to a type of activity that is not subject to vat. 
	|	VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) AS VATTaxation,
	|	ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	LineCodes.RowCode AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Discrepancies AS DocumentTable
	|		INNER JOIN Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = DocumentTable.ItemsLocationAttributes.Products
	|		INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""Discrepancies""
	|		LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON CatProducts.FinancialAccountingGroup = FAG.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure();
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	RedefiningParameterCalculation.Insert("ContractInformation",    """""");
	RedefiningParameterCalculation.Insert("CorrectionInformation", """""");
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		RequestHasSource = False;
		
	ElsIf RegisterName = "CompanyGoods" Then
		
		QueryText = QueryTextTableCompanyGoods(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In the %FullDocumentName% document, the adaptation of a request for generating the %RegisterName% register records is not implemented.'; fa = 'In the %FullDocumentName% document, the adaptation of a request for generating the %RegisterName% register records is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
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

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		// Write-off of discrepancies between receipt and acquisition closes the receipt schedule.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		// The Operation makes the Registered Records for the goods to be received. In procurement, this Operation is always with an empty Lot reference.
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	CASE 
		|		WHEN TabPart.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
		|			THEN -TabPart.Count
		|		ELSE TabPart.Count
		|	END AS Count,
		|	TabPart.Ref.ReferenceOrder AS OrderInSchedule
		|FROM
		|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Discrepancies AS TabPart
		|WHERE
		|	TabPart.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.Work_5),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))";
	
	StockAllocationRecords.CancelScheduledStockArrival(Query, QueryTexts, Registers, QueryTextTabPart);
	
EndProcedure

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	
	If Query <> Undefined Then
		// There are no additional parameters.
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
	
	#Region Description_DisposalAtFixedCost_OwnGoods
	
	// Discrepancies in case of unfactured delivery and goods in transit from suppliers.
	//
	// non-delivery (received less than the invoice)
	//	write-off of the positive Balance under the accounting section for the expense
	//	item in correspondence with the register "other expenses" or "assets and liabilities".
	//	the cost of the write-off is calculated at the stages of solving the platform_The cost of the enterprise and solve the platform_The cost of organizations,
	//	because for corrections and reverse it is impossible to determine the cost at the stage of selection of batches.
	//	The formation of movements by registers is performed in the procedure to adjust the cost of writing inventory (). 
	//
	//	Movements are formed "Expense" with a positive amount, if the type of discrepancies "Non-delivery" is specified.
	//	In movements, an expense item or asset item is filled in from the Expenditure Item field.
	//	when specifying an asset item in movements, the Attributes of the asset analytics and account settings are filled in from the asset analytics and asset account settings
	//	fields, respectively.
	//
	//	for an unfactured delivery, the record type must be a write-off of the non-party status, because the source will have 
	//	the record types consumption or Balance, and the batch will not be filled in the source.
	//	for goods in transit from suppliers, the record type must be consumption, because the source will have record types batch or Balance
	//
	//	in case of non-invoicing, the deductible positive Balance is formed by the documents of the acquirement of goods services with the type of record consumption.
	//	for such records, the calculation is not completed attribute must be true - this means that there are no Balances for invoicing for records.
	// 
	//	for goods in transit from suppliers, a positive Balance is formed by the documents of the purchase of goods services with the type of record batch.
	//
	// re-delivery (received more than by way of delivery)
	//	write-off of the negative Balance under the accounting section to the income 
	//	item in correspondence with the register "other income" or "assets and liabilities".
	//	the cost of the write-off is calculated at the stages of solving the platform_The cost of the enterprise and solve the platform_The cost of organizations,
	//	because for corrections and reverse it is impossible to determine the cost at the stage of selection of batches.
	//	The formation of movements by registers is performed in the procedure to adjust the cost of writing inventory ().
	//
	//	Movements are formed "Consumption" with the type of record "Consumption" and a negative amount
	//	if the type of discrepancies "Over-delivery" is specified.
	//	In movements, an income item or a liability item is filled in from the Income Item field.
	//	when specifying the article of liabilities in movements, the Attributes of the analytics of asset assets and account account settings are filled in
	//	from the analytics of assets and account account settings, respectively.
	//
	//	for an unfactured delivery, the record type must be consumption, because the source will have record types batch or Balance.
	//	for goods in transit from suppliers, the record type should be write-offsostat of the non-party, because the source will have the record types consumption or Balance
	//
	//	in case of non-invoicing, the negative Balance to be written off is formed by the documents receipt of the inventory and receipt of the service division
	//	with the batch record type.
	//
	//	for goods in transit from suppliers, a negative Balance is formed by the receipt documents of the goods with the type of record consumption.
	//	for such records, the calculation is not completed attribute must be true - this means that there are no Balances of purchases of goods for the record. 
	//
	// Movements are formed through a modular operation of retirement of fixed cost (this operation can attribute a negative cost to other income)
	// The accounting section is defined in the procedure of the module for the calculation of the highest value and verification of documents by type of inventory:
	// - Own Goods without Actual delivery - accounting section "Unfactuated deliveries"
	// - Own Goods way - separate accounting "Own goods way"
	
	#EndRegion
	
	#Region DisposalAtFixedCost_Item
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	DocumentTable.ReferenceOrder						AS Lot,
	// the write-off of discrepancies on an unfactured postage or on goods in transit from suppliers always refers
	// to a type of activity that is not subject to vat. 
	|	VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) AS VATActivityType,
	|	VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED										AS CorItemsLocationAttributes,
	|	UNDEFINED										AS CorInventoryOwnerAttribute,
	|	(CASE
	|		WHEN TableTypesOfStocks_.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
	|		 AND VALUETYPE(DocumentTable.IncomeItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN DocumentTable.IncomeItem
	|		WHEN TableTypesOfStocks_.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)
	|			THEN DocumentTable.ExpenseItem
	|		ELSE UNDEFINED END)						AS ExpenseItemAssets,
	|	(CASE
	|		WHEN TableTypesOfStocks_.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
	|		 AND VALUETYPE(DocumentTable.IncomeItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN DocumentTable.DimensionLiabilities_
	|		WHEN TableTypesOfStocks_.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)
	|		 AND VALUETYPE(DocumentTable.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN DocumentTable.DimensionOfAssets
	|		WHEN TableTypesOfStocks_.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)
	|			THEN DocumentTable.DimensionOfExpenses
	|		ELSE UNDEFINED END)						AS AssetExpenseAnalytics,
	|	(CASE
	|		WHEN TableTypesOfStocks_.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
	|		 AND VALUETYPE(DocumentTable.IncomeItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN DocumentTable.LiabilitiesGLAccountsSettings
	|		WHEN TableTypesOfStocks_.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)
	|		 AND VALUETYPE(DocumentTable.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN DocumentTable.AssetGLAccountsSettings
	|		ELSE UNDEFINED END)						AS GLAccountSettings,
	|	(CASE
	|		WHEN TableTypesOfStocks_.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
	|		 AND VALUETYPE(DocumentTable.IncomeItem) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|			THEN DocumentTable.IncomeItem
	|		ELSE UNDEFINED END)						AS IncomeItem,
	|	(CASE
	|		WHEN TableTypesOfStocks_.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
	|		 AND VALUETYPE(DocumentTable.IncomeItem) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|			THEN DocumentTable.DimensionOfRevenue
	|		ELSE UNDEFINED END)						AS DimensionOfRevenue,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED							AS SalesOpportunity,
	|	DocumentTable.Department			AS Department,
	|	UNDEFINED							AS Manager,
	|	UNDEFINED 							AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	(CASE
	|		WHEN TableTypesOfStocks_.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
	|			THEN -TableTypesOfStocks_.Count
	|		ELSE TableTypesOfStocks_.Count END) AS Count,
	|	TableTypesOfStocks_.RowID 	AS RowID,
	|	0							 			AS Cost,
	|	0							 			AS CostExcludingVAT,
	|	0							 			AS LocalCost,
	|	0							 			AS CostMan,
	|	0										AS CorGrossInitialCostENT,
	|
	// Other fields
	|	&BusinessOperation					AS BusinessOperation,
	|	TableTypesOfStocks_.RowID	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.DisposalAtFixedCost,
		QueryText);
		
	#EndRegion

	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

Function RequestTextDiscrepanciesReceiptPurchase()
	
	QueryText = 
	"SELECT
	|	GoodsToReceive.DocumentInflow AS DocumentInflow,
	|	GoodsToReceive.Warehouse AS Warehouse,
	|	GoodsToReceive.Products AS Products,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	GoodsToReceive.Purpose AS Purpose,
	|	GoodsToReceive.Series AS Series,
	|	GoodsToReceive.ToRegisterReceiptsByInvoicesBalance AS Count,
	|	GoodsToReceive.ToRegisterReceiptsByInvoicesBalance AS NumberOfPackages
	|INTO TTProducts_1
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			DocumentInflow = &DocumentBasis
	|				AND CASE
	|					WHEN &WarehouseSpecified
	|							AND NOT Products.ItemsType IN (&WorksServices)
	|						THEN Warehouse = &WarehouseForReceipt
	|					ELSE TRUE
	|				END) AS GoodsToReceive
	|WHERE
	|	GoodsToReceive.ToRegisterReceiptsByInvoicesBalance <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsToReceive.DocumentInflow,
	|	GoodsToReceive.Warehouse,
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	GoodsToReceive.Purpose,
	|	GoodsToReceive.Series,
	|	CASE
	|		WHEN GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN GoodsToReceive.ToRegisterReceiptsByInvoices
	|		ELSE -GoodsToReceive.ToRegisterReceiptsByInvoices
	|	END,
	|	CASE
	|		WHEN GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN GoodsToReceive.ToRegisterReceiptsByInvoices
	|		ELSE -GoodsToReceive.ToRegisterReceiptsByInvoices
	|	END
	|FROM
	|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
	|WHERE
	|	GoodsToReceive.Recorder = &CurrentDocument
	|	AND GoodsToReceive.ToRegisterReceiptsByInvoices <> 0
	|
	|INDEX BY
	|	DocumentInflow,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.DocumentInflow AS DocumentInflow,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Series AS Series,
	|	SUM(GoodsTable.Count) AS Count,
	|	SUM(GoodsTable.NumberOfPackages) AS NumberOfPackages
	|INTO GoodsTableWithGrouping
	|FROM
	|	TTProducts_1 AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.DocumentInflow,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.DocumentInflow AS DocumentInflow,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Series AS Series,
	|	SUM(CASE
	|			WHEN GoodsTable.Count < 0
	|				THEN -GoodsTable.Count
	|			ELSE GoodsTable.Count
	|		END) AS Count,
	|	SUM(CASE
	|			WHEN GoodsTable.NumberOfPackages < 0
	|				THEN -GoodsTable.NumberOfPackages
	|			ELSE GoodsTable.NumberOfPackages
	|		END) AS NumberOfPackages,
	|	CASE
	|		WHEN GoodsTable.Count < 0
	|			THEN VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
	|		ELSE VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)
	|	END AS DiscrepanciesKind
	|FROM
	|	GoodsTableWithGrouping AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.DocumentInflow,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series,
	|	CASE
	|		WHEN GoodsTable.Count < 0
	|			THEN VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
	|		ELSE VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)
	|	END";
	
	Return QueryText;
EndFunction

#EndRegion

#Region Print

Function PrintingCertificateOfWriteOffOfDiscrepancies(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputAdditionalColumn = ValueIsFilled(NameOfCodeColumn);

	Query = New Query;
	Query.Text =
	"SELECT
	|	Document.Ref AS Ref,
	|	Document.Number AS Number,
	|	Document.Date AS Date,
	|	Document.Department AS Department,
	|	Document.Organization AS Organization,
	|	PRESENTATION(Document.Partner) AS VendorPresentation,
	|	PRESENTATION(Document.Warehouse) AS WarehousePresentation,
	|	PRESENTATION(Document.Department) AS DepartmentPresentation,
	|	PRESENTATION(Document.ReferenceOrder) AS BasisPresentation,
	|	Document.Organization.Prefix AS Prefix,
	|	Document.Author.Individual AS EmployeeResponsible
	|FROM
	|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase AS Document
	|WHERE
	|	Document.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	| Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DivergenceTable.LineNumber AS LineNumber,
	|	DivergenceTable.Products AS Products,
	|	&NameOfCodeColumn AS AdditionalColumn,
	|	DivergenceTable.DiscrepanciesKind AS DiscrepancyKind,
	|	DivergenceTable.Products.DescriptionFull AS ProductsPresentation,
	|	DivergenceTable.Characteristic.DescriptionFull AS CharacteristicPresentation,
	|	PRESENTATION(DivergenceTable.Products.UnitOfMeasure) AS UnitOfMeasurePresentation,
	|	DivergenceTable.Count AS Count,
	|	DivergenceTable.Ref AS Ref
	|FROM
	|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Discrepancies AS DivergenceTable
	|WHERE
	|	DivergenceTable.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|TOTALS BY
	|	Ref";

	If OutputAdditionalColumn Then
		Query.Text = StrReplace(Query.Text, "&NameOfCodeColumn", "DivergenceTable.Products." +NameOfCodeColumn);
	Else
		Query.Text = StrReplace(Query.Text, "&NameOfCodeColumn AS AdditionalColumn,", "");
	EndIf;

	DocumentAttributes = New Structure("Number, Date, Prefix");
	DocumentSynonym = NStr("vi = 'Biên bản ghi giảm chênh lệch';
							|ru = 'Акт списания расхождений';
							|en = 'Discrepancy write-off report'; fa = 'گزارش اسقاط مغایرت';
							|it = 'Акт списания расхождений';
							|pl = 'Discrepancy write-off report';
							|tr = 'Tutarsızlık gider yazılması tutanağı'", Common.DefaultLanguageCode());

	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PRINT_OPTIONS_WriteOffDiscrepanciesBetweenReceiptAndPurchase_ActOfWritingOffDiscrepancies";
	
	Template = PrintManagement.PrintFormTemplate("Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.PF_MXL_ActOfWritingOffDiscrepancies");
	
	HeaderArea_ = Template.GetArea("Title");
	
	ScopeOfApplication_2  = Template.GetArea("Basis");

	AreaOfHeaderNumber = Template.GetArea("TableHeader|LineNumber");
	AreaTypeOfDiscrepanciesHeader = Template.GetArea("TableHeader|DiscrepanciesKind");
	AreaCodesHeader  = Template.GetArea("TableHeader|ColumnOfCodes");
	ProductAreaHeader  = Template.GetArea("TableHeader|OwnGoods");
	AreaDataHeader = Template.GetArea("TableHeader|Data");

	If Not OutputAdditionalColumn Then

		Template.Area("OwnGoods").ColumnWidth = Template.Area("OwnGoods").ColumnWidth
				+ Template.Area("ColumnOfCodes").ColumnWidth;

	EndIf;

	NumberAreaLine = Template.GetArea("String|LineNumber");
	AreaTypeOfDiscrepanciesLine = Template.GetArea("String|DiscrepanciesKind");
	NumberAreaLine = Template.GetArea("String|LineNumber");
	AreaCodesString  = Template.GetArea("String|ColumnOfCodes");
	ProductLineArea_  = Template.GetArea("String|OwnGoods");
	DataAreaRow = Template.GetArea("String|Data");

	RoomAreaBasementTable = Template.GetArea("TableFooter|LineNumber");
	AreaDiscrepanciesKindTableFooter = Template.GetArea("TableFooter|DiscrepanciesKind");
	AreaCodesBasementTables  = Template.GetArea("TableFooter|ColumnOfCodes");
	ProductAreaTableBasement  = Template.GetArea("TableFooter|OwnGoods");
	DataAreaTableBasement = Template.GetArea("TableFooter|Data");

	LabelArea       = Template.GetArea("Signatures");
	RegionAmountInWords = Template.GetArea("AmountInWords");
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	QueryResults = Query.ExecuteBatch(); 
	
	DocumentsSelection = QueryResults[0].Select();
	SelectionByTableParts = QueryResults[1].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	
	While DocumentsSelection.Next() Do
		
		If Not FirstDocument Then
			TabDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		
		RowNumberStart = TabDocument.TableHeight + 1;

		// We display the header of the invoice.
		FillPropertyValues(DocumentAttributes, DocumentsSelection);
		HeaderArea_.Parameters.Fill(DocumentsSelection);
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TitleText", 
								TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, DocumentSynonym));
		NamesAsOfDate = CompaniesCached.NamesAsOfDate(DocumentsSelection.Organization, DocumentsSelection.Date);
		HeaderDataStructure_1.Insert("OrganizationPresentation", NamesAsOfDate.AbbreviatedDescription);
		HeaderArea_.Parameters.Fill(HeaderDataStructure_1);
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(TabDocument, Template, HeaderArea_, DocumentsSelection.Ref);
		TabDocument.Put(HeaderArea_);

		ScopeOfApplication_2.Parameters.Fill(DocumentsSelection);
		TabDocument.Put(ScopeOfApplication_2);
		// Output of the header.
		TabDocument.Put(AreaOfHeaderNumber);
		TabDocument.Join(AreaTypeOfDiscrepanciesHeader);

		If OutputAdditionalColumn Then

			AreaCodesHeader.Parameters.AdditionalColumn = PresentationOfCodesColumn;
			TabDocument.Join(AreaCodesHeader);

		EndIf;
		TabDocument.Join(ProductAreaHeader);

		TabDocument.Join(AreaDataHeader);

		AmountTotal = 0;
		TotalItems_1 = 0;

		// Output of strings.
		SelectionByTableParts.FindNext(New Structure("Ref",DocumentsSelection.Ref));
		
		SelectionByLines = SelectionByTableParts.Select();
		
		While SelectionByLines.Next() Do

			NumberAreaLine.Parameters.Fill(SelectionByLines);
			TabDocument.Put(NumberAreaLine);
			AreaTypeOfDiscrepanciesLine.Parameters.DiscrepancyKind = SelectionByLines.DiscrepancyKind;
			TabDocument.Join(AreaTypeOfDiscrepanciesLine);

			If OutputAdditionalColumn Then

				AreaCodesString.Parameters.Fill(SelectionByLines);
				TabDocument.Join(AreaCodesString);

			EndIf;

			// Nomenclature.
			ProductLineArea_.Parameters.Products = SelectionByLines.Products;
			ProductLineArea_.Parameters.ProductsPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
				SelectionByLines.ProductsPresentation,
				SelectionByLines.CharacteristicPresentation,
				,
				,
				AdditionalParametersProductPresentation);
			
			TabDocument.Join(ProductLineArea_);
			
			// Data on prices, quantity.
			DataAreaRow.Parameters.Fill(SelectionByLines);
			
			TabDocument.Join(DataAreaRow);

			TotalItems_1 = TotalItems_1 + 1;

		EndDo;

		// Output of the basement.
		TabDocument.Put(RoomAreaBasementTable);
		TabDocument.Join(AreaDiscrepanciesKindTableFooter);
		If OutputAdditionalColumn Then
			TabDocument.Join(AreaCodesBasementTables);
		EndIf;
		TabDocument.Join(ProductAreaTableBasement);
		TabDocument.Join(DataAreaTableBasement);

		LabelArea.Parameters.EmployeeResponsible = PersonsTM.IndividualShortName(DocumentsSelection.EmployeeResponsible, DocumentsSelection.Date);
		TabDocument.Put(LabelArea);

		PrintManagement.SetDocumentPrintArea(TabDocument, RowNumberStart, PrintObjects, DocumentsSelection.Ref);

	EndDo;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return TabDocument;

EndFunction

#EndRegion

#Region Other

Function FullObjectName()
	Return "Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase";
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	#Region Documents_WriteOffOfDiscrepanciesReceiptPurchase_ProcessDataToUpgradeToNewVersion
	
	Handler = Handlers.Add();
	Handler.Procedure = "Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.25.22";
	Handler.ExecutionMode = "Deferred";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Id = New UUID("90f980b2-a05e-481a-858d-e83019d6042c");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật chứng từ ""Ghi giảm chênh lệch giữa tiếp nhận và mua hàng""';
								|ru = 'Обновление документов ""Списание расхождений между поступлением и приобретением"":';
								|en = 'Update the ""Write off discrepancies between receipt and purchase"" documents:'; fa = 'Update the ""Write off discrepancies between receipt and purchase"" documents:';
								|it = 'Обновление документов ""Списание расхождений между поступлением и приобретением"":';
								|pl = 'Update the ""Write off discrepancies between receipt and purchase"" documents:';
								|tr = '“Makbuz ve satın alma arasındaki tutarsızlıkların silinmesi” belgelerinin güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- điền mục tin ""Trạng thái chỉ định sê-ri hàng hóa của bạn hàng"" trong phần bảng ""Chênh lệch"".';
								|ru = '- заполнение реквизита ""Статус указания серий товары у партнеров"" в табличной части ""Расхождения"".';
								|en = '- Fill the ""Batch specification status goods at partners"" attribute in the ""Discrepancies"" table.'; fa = '- Fill the ""Batch specification status goods at partners"" attribute in the ""Discrepancies"" table.';
								|it = '- Fill the ""Batch specification status goods at partners"" attribute in the ""Discrepancies"" table.';
								|pl = '- Fill the ""Batch specification status goods at partners"" attribute in the ""Discrepancies"" table.';
								|tr = '- ""Tutarsızlıklar"" tablosundaki ""İş ortaklarındaki ürün partilerini belirtme durumu"" alanının doldurulması.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	#EndRegion
	
EndProcedure

// Registers documents for processing for modification.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export

	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	DiscrepancyData.Ref AS Ref
	|FROM
	|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Discrepancies AS DiscrepancyData
	|		INNER JOIN Catalog.Products AS ProductData_1
	|		ON DiscrepancyData.Products = ProductData_1.Ref
	|		
	|		INNER JOIN Catalog.ItemKinds AS ProductTypeData
	|		ON ProductData_1.ProductKind = ProductTypeData.Ref
	|		
	|		INNER JOIN Catalog.BatchAccountingPolicies AS SeriesAccountingPolicyData
	|		ON ProductTypeData.BatchAccountingPolicy = SeriesAccountingPolicyData.Ref
	|WHERE
	|	NOT SeriesAccountingPolicyData.Ref IS NULL
	|	AND DiscrepancyData.BatchesIndicationStatusGoodsAtPartners = 0
	|	AND SeriesAccountingPolicyData.UseCostAccountingByBatches
	|	AND (SeriesAccountingPolicyData.BatchesAccountingOfGoodsInTransitFromVendor
	|		OR SeriesAccountingPolicyData.BatchesAccountingInUninvoicedGoodsDeliveries)
	|	AND DiscrepancyData.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
//
// Parameters:
//	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName	= EmptyRef().Metadata().FullName();
	UpdatedData	= InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DiscrepancyData.LineNumber AS LineNumber
	|FROM
	|	Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Discrepancies AS DiscrepancyData
	|		INNER JOIN Catalog.Products AS ProductData_1
	|		ON DiscrepancyData.Products = ProductData_1.Ref
	|		
	|		INNER JOIN Catalog.ItemKinds AS ProductTypeData
	|		ON ProductData_1.ProductKind = ProductTypeData.Ref
	|		
	|		INNER JOIN Catalog.BatchAccountingPolicies AS SeriesAccountingPolicyData
	|		ON ProductTypeData.BatchAccountingPolicy = SeriesAccountingPolicyData.Ref
	|WHERE
	|	DiscrepancyData.Ref = &Ref
	|	AND NOT SeriesAccountingPolicyData.Ref IS NULL
	|	AND DiscrepancyData.BatchesIndicationStatusGoodsAtPartners = 0
	|	AND SeriesAccountingPolicyData.UseCostAccountingByBatches
	|	AND (SeriesAccountingPolicyData.BatchesAccountingOfGoodsInTransitFromVendor
	|		OR SeriesAccountingPolicyData.BatchesAccountingInUninvoicedGoodsDeliveries)
	|	AND DiscrepancyData.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)";
	
	For Each Document In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Document.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			DocumentObject = Document.Ref.GetObject(); // DocumentObject.WriteOffDiscrepanciesBetweenReceiptAndPurchase - 
			
			If DocumentObject <> Undefined Then
				Query.SetParameter("Ref", DocumentObject.Ref);
				
				QueryResult = Query.Execute();
				
				If Not QueryResult.IsEmpty() Then
					Selection = QueryResult.Select();
					
					While Selection.Next() Do
						DivergenceLine = DocumentObject.Discrepancies[Selection.LineNumber - 1];
						DivergenceLine.BatchesIndicationStatusGoodsAtPartners = ?(ValueIsFilled(DivergenceLine.Series),
																					18,
																					17);
					EndDo;
				EndIf;
			EndIf;
			
			If DocumentObject <> Undefined
				And DocumentObject.Modified() Then
				
				InfobaseUpdate.WriteData(DocumentObject);
				
			Else
				InfobaseUpdate.MarkProcessingCompletion(Document.Ref);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Document.Ref);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf

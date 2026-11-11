#If Not MobileStandaloneServer Then
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
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("Sales");
	DocumentMechanisms.Add("HandoverForSafekeeping");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfWorks");
	DocumentMechanisms.Add("PricesAndDiscounts");
	DocumentMechanisms.Add("DocumentCorrection");
	
	SaleAdjustmentLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.SaleAdjustment") Then
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
		
		QueryTextTableTransferredReturnablePackaging(Query, QueryTexts, Registers);
		QueryTextTableShipmentReferences(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableServicesForRegistrationOfReportsToPrincipal(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableBonusPoints(Query, QueryTexts, Registers, DocumentRef);
		QueryTextTableDocumentCorrections(Query, QueryTexts, Registers);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers, DocumentRef);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(
			DocumentRef, Query, QueryTexts, Registers);
		
		// Execution of the request and unloading of the received tables for movements.
		SaleAdjustmentLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers);
	ReflectOtherRevenue(Query, QueryTexts, Registers);
	
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
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	CreationCommand =
		Documents.GoodsReceiptFromCustomer.AddGenerateCommand(GenerationCommands);
	
	If CreationCommand <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			CreationCommand, 
			"AdjustingEntryType", 
			Enums.AdjustingEntryTypes.StandardAdjustment,
			DataCompositionComparisonType.Equal);
		
	EndIf;
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	SaleAdjustmentLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create a document "Adjusted implementation".
//
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.SaleAdjustment) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.SaleAdjustment.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.SaleAdjustment);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseCreditNotes";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ARAPAccountingServer.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
	ARAPAccountingServer.CustomerDebt_AddDocumentReportCommand(ReportsCommands);
	
	SaleAdjustmentLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "DocumentBasis,Warehouse,Date";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
// 	Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
// 	Structure - a collection containing the following properties:
// 		* Goods - See ProductsClientServer.SeriesSpecificationParameters.
// 		* Discrepancies - See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = New Structure;
	
	#Region Goods
	ParametersForSpecifyingSeriesOfItems = ProductsClientServer.SeriesSpecificationParameters();
	
	ParametersForSpecifyingSeriesOfItems.FullObjectName = "Document.SaleAdjustment";
	
	DocumentBasisBusinessOperation = EconomicOperationOfFoundationDocument(Object.DocumentBasis);
	SalesViaCommissionAgent = ConsignmentSalesServer.SalesViaCommissionAgent(DocumentBasisBusinessOperation);
	ImplementationOfTransferOfOwnership = DocumentBasisBusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods;
	
	If SalesViaCommissionAgent
		Or ImplementationOfTransferOfOwnership Then
		
		ParametersForSpecifyingSeriesOfItems.UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse",
																		New Structure());
		ParametersForSpecifyingSeriesOfItems.UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse",
																		New Structure());
		
	Else
		WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, True);
		ParametersForSpecifyingSeriesOfItems.UseItemsBatch  = WarehouseSeriesParameters.UseCostAccountingByBatches;
		ParametersForSpecifyingSeriesOfItems.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	EndIf;
	
	ParametersForSpecifyingSeriesOfItems.SeriesOnlyForCostPrice = True;
	
	ParametersForSpecifyingSeriesOfItems.TSSeriesName = ParametersForSpecifyingSeriesOfItems.NameTSGoods;
	
	ParametersForSpecifyingSeriesOfItems.WarehouseTransactions.Add(Enums.WarehouseTransactions.EmptyRef());
	
	ParametersForSpecifyingSeriesOfItems.AdditionalFieldNames.Add("Warehouse");
	
	ParametersForSpecifyingSeriesOfItems.ThisIsAnInvoice = True;
	ParametersForSpecifyingSeriesOfItems.Date = Object.Date;
	
	ParametersForSpecifyingSeriesOfItems.DocumentOperation_ = DocumentBasisBusinessOperation;
	
	SeriesSpecificationParameters.Insert("Goods", ParametersForSpecifyingSeriesOfItems);
	
	#EndRegion
	
	#Region Discrepancies
	ParametersForSpecifyingDiscrepancySeries = ProductsClientServer.SeriesSpecificationParameters();
	
	ParametersForSpecifyingDiscrepancySeries.FullObjectName = ParametersForSpecifyingSeriesOfItems.FullObjectName;
	
	ParametersForSpecifyingDiscrepancySeries.UseCostAccountingByBatches = ParametersForSpecifyingSeriesOfItems.UseCostAccountingByBatches;
	ParametersForSpecifyingDiscrepancySeries.UseItemsBatch  = ParametersForSpecifyingSeriesOfItems.UseItemsBatch;
	
	ParametersForSpecifyingDiscrepancySeries.SeriesOnlyForCostPrice = True;
	
	ParametersForSpecifyingDiscrepancySeries.NameTSGoods	= "Discrepancies";
	ParametersForSpecifyingDiscrepancySeries.TSSeriesName	= "Discrepancies";
	
	ParametersForSpecifyingDiscrepancySeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.EmptyRef());
	
	ParametersForSpecifyingDiscrepancySeries.AdditionalFieldNames.Add("Warehouse");
	ParametersForSpecifyingDiscrepancySeries.AdditionalFieldNames.Add("PostingOption");
	
	ParametersForSpecifyingDiscrepancySeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	ParametersForSpecifyingDiscrepancySeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusInWarehouses");
	ParametersForSpecifyingDiscrepancySeries.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusOfGoodsTransferred");
	
	ParametersForSpecifyingDiscrepancySeries.ThisIsAnInvoice = True;
	ParametersForSpecifyingDiscrepancySeries.Date = Object.Date;
	
	ParametersForSpecifyingDiscrepancySeries.DocumentOperation_ = DocumentBasisBusinessOperation;
	
	SeriesSpecificationParameters.Insert("Discrepancies", ParametersForSpecifyingDiscrepancySeries);
	
	#EndRegion
	
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
	
	If SeriesSpecificationParameters.NameTSGoods = "Discrepancies" Then
		QueryText = QueryTextForFillingInStatusesAndSpecifyingDiscrepancySeries();
	Else
		QueryText = QueryTextForFillingInStatusesForSpecifyingSeriesOfItems();
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region BasisForPrint

// Returns the base structure based on document data
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.SaleAdjustment - The object of the document that you need to get the base text from.
//
// Returns:
//	Structure - Structure with the name, date and number of the foundation.
//
Function StructureOfBaseForPrinting(Object) Export
	
	BaseStructure = BaseStructure(Object, Object.ARAPObjectSettings);
	
	Return BaseStructure;
	
EndFunction

// Returns a table of default values for the "Base" attribute"
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.SaleAdjustment - The document object to get the selection list from.
//
// Returns:
//	ValueTable - A table of values with the details of the bases.
//
Function PrintBasisTable(Object) Export
	
	TableOfBases_ = New ValueTable;
	TableOfBases_.Columns.Add("Basis",      New TypeDescription("String",,,,New StringQualifiers(300)));
	TableOfBases_.Columns.Add("ReferenceDocumentDateForPrintForms",  New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.Date))); 
	TableOfBases_.Columns.Add("BaseDocumentNumber", New TypeDescription("String",,,,New StringQualifiers(128)));
	
	BaseStructure = BaseStructure(Object, Enums.ARAPObjectSettings.ByCounterpartyContracts);
	If ValueIsFilled(BaseStructure.Basis) Then
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
	EndIf;
	
	BaseStructure = BaseStructure(Object, Enums.ARAPObjectSettings.ByOrders);
	If ValueIsFilled(BaseStructure.Basis) Then
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
	EndIf;
	
	Return TableOfBases_;
	
EndFunction

#EndRegion

#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return SaleAdjustmentLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return SaleAdjustmentLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

// Returns the request body for the get the available appointments
//	Parameters:
//		RequestFormationParameters - Structure - the parameters for the generation of text queries
//	Returns:
//		String - query text.
//
Function RequestTextForAvailableAssignments(RequestFormationParameters) Export
	
	Return Catalogs.Assignments.RequestTextForAllAppointments(RequestFormationParameters);
	
EndFunction

// Returns the structure of document processing order parameters
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	
// Returns:
// Structure - See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
//
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToFillInAssignment = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType,RowCode");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

#Region Print

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Structure - composition of properties See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand.
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.VHFWarehouses				= True;
	JobPrintingRules.AdjustmentOfGoods	= True;
	JobPrintingRules.NameTSGoods			= "Discrepancies";
	
	Return JobPrintingRules;
	
EndFunction

#EndRegion

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters - Array of parameters of the functions of the settlement mechanism
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	ThisIsDebtAdjustment = False;
	ConductARAPAccountingThroughEndCustomers = False;
	SalesViaCommissionAgent = False;
	ThisIsAdjustmentOfPrimaryDocument = False;
	DocumentBasis = Undefined;
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData,
			"AdjustmentKind,
			|DocumentBasis,
			|Contract,
			|AdjustingEntryType");
		ThisIsDebtAdjustment = 
			StructureFillingData.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated
			Or StructureFillingData.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated;
		SalesViaCommissionAgent = ConsignmentSalesServer.SalesViaCommissionAgent(
										EconomicOperationOfFoundationDocument(StructureFillingData.DocumentBasis));
		ConductARAPAccountingThroughEndCustomers = SalesViaCommissionAgent And StructureFillingData.Contract.ConductARAPAccountingThroughEndCustomers;
		ThisIsAdjustmentOfPrimaryDocument = StructureFillingData.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices
			Or StructureFillingData.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
		DocumentBasis = StructureFillingData.DocumentBasis;
	ElsIf FillingData <> Undefined Then
		ThisIsDebtAdjustment = 
			FillingData.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated
			Or FillingData.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated;
		SalesViaCommissionAgent = ConsignmentSalesServer.SalesViaCommissionAgent(
										EconomicOperationOfFoundationDocument(FillingData.DocumentBasis));
		ConductARAPAccountingThroughEndCustomers = SalesViaCommissionAgent 
			And Common.ObjectAttributeValue(FillingData.Contract, "ConductARAPAccountingThroughEndCustomers");
		ThisIsAdjustmentOfPrimaryDocument = FillingData.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices
			Or FillingData.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
		DocumentBasis = FillingData.DocumentBasis;
	EndIf;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	#Region RequiredParameters2
	
	// If all options are false, then this is a payment or a service document.
	ParametersStructure.ThisIsOrder                         = False;
	ParametersStructure.IsCatalog                    = False;
	ParametersStructure.ThisIsSalePurchase                = True;
	
	// Determines which register the parameters move, which common forms, enumerations and directories to use.
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	// The date the document was reflected in the system.
	// It is used to get overdue balances for the debt limitation function.
	// Used to get the document's currency rates. 
	// Used to fill in the payment stages and decrypt the default payment.
	ParametersStructure.Date                             = "Object.Date"; 
	
	// Currency and amount of the transaction. The path to the object's details is required.
	ParametersStructure.DocumentCurrency                  = "Object.Currency";
	ParametersStructure.DocumentAmount                   = "";
	
	// They are used to generate calculation and analytics objects.
	ParametersStructure.Organization                      = "Object.Organization";
	ParametersStructure.Partner                          = ?(ConductARAPAccountingThroughEndCustomers, "Object.CustomerPartner",    "Object.Partner");
	ParametersStructure.Counterparty                       = ?(ConductARAPAccountingThroughEndCustomers, "Object.CustomerCounterparty", "Object.Counterparty");
	ParametersStructure.ItCanBeARAPObject = False;
	#EndRegion
	
	#Region OptionalParameters
	
	// Details other than the currency and amount of the document. If it is not filled in, then the currency of the document will be taken for reading.
	ParametersStructure.ARAPCurrency             = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP              = "Object.AmountARAP";
	ParametersStructure.AmountARAPByPackage        = "";
	
	// It is used to generate analytics for the conduct and object of calculations, to determine the schedule for the execution of the contract.
	If ThisIsDebtAdjustment Then
		ParametersStructure.Contract                          = "";
	ElsIf SalesViaCommissionAgent Then
		ParametersStructure.Contract                          = "Object.CustomerContract";
	Else
		ParametersStructure.Contract                          = "Object.Contract";
	EndIf;
	// It is used to obtain the details of the HFC, the order of settlements, currency settlements, payments in the currency when accounting for sales to end customers.
	ParametersStructure.CommissionAgentSAgreement              = ?(SalesViaCommissionAgent, "Object.Contract", "");
	// It is used to generate the analysis of the conduct and object of calculations.
	ParametersStructure.LineOfBusiness          = "Object.LineOfBusiness";
	
	// The procedure for calculating the document.
	If ThisIsDebtAdjustment Then
		ParametersStructure.ARAPObjectSettings                  = "";
	Else
		ParametersStructure.ARAPObjectSettings                  = "Object.ARAPObjectSettings";
	EndIf;
	// The total amount with the collateral container. The path to the final indicator of the form (props).
	// It is used to display hyperlinks, edit and fill in the schedule of scheduled payments
	// , edit the payment transcript, etc.
	ParametersStructure.DocumentAmountForm              = "";
	
	// The details of the final indicators form containing the amount of the deposit for the container in the currency of the document.
	// It is used in filling out the stages of the payment schedule.
	ParametersStructure.AmountOfDepositForContainerForm            = ""; 

	// The tabular part, according to which the amount of mutual settlements is distributed, is the "order" field.
	// It is used to display hyperlinks, edit and fill in the schedule of scheduled payments
	// , edit the payment transcript if the Summadocumentform parameter is not filled in.
	// In PM, the objects of calculations for orders are filled in.
	If ThisIsDebtAdjustment Then
		ParametersStructure.PathToTSData                    = "Object.ARAPAdjustment";
		// The name of the details of the amount with VAT of the tabular part.
		ParametersStructure.PropsNameTSAmountWithVAT          = "AdjustmentSum";
	Else 
		ParametersStructure.PathToTSData                    = "Object.Discrepancies";
		// The name of the details of the amount with VAT of the tabular part.
		ParametersStructure.PropsNameTSAmountWithVAT          = "AmountIncludingVAT";
		// The name of the pm item containing the order.
		ParametersStructure.PropsNameTSOrder              = "SalesOrder";
	EndIf;
	
	// The path to the tabular part of the payment decryption.
	// It is used in the function of offsetting payments, distribution of mutual settlements, distribution of payments.
	ParametersStructure.PathToTSDataPaymentDecryption  = "";
	
	// It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	If ThisIsDebtAdjustment Then
		ParametersStructure.Terms                       = "";
	Else
		ParametersStructure.Terms                       = "Object.Terms";
	EndIf;
	
	// They are used to determine the value of payments in currency and in the form of editing payment rules.
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.PaymentMethod                      = "Object.PaymentMethod";
	ParametersStructure.ForeignCurrencyTransaction                    = "";
	// It is used in the form of payment rules and for the selection of settlement objects in the decryption of the payment.
	ParametersStructure.PaymentID             = "";
	
	// The details for the object of calculations are used in conducting.
	If ThisIsDebtAdjustment Then
		// Calculation objects are selected when filling out the document, and are not generated
		ParametersStructure.FinancialAccountingGroup       = "";
		ParametersStructure.Department                = "";
		ParametersStructure.Manager                     = "";
		ParametersStructure.IncomingDocumentNumber      = "";
		ParametersStructure.IncomingDocumentDate       = "";
		ParametersStructure.ARAPObject               = "";
		ParametersStructure.InvoiceForOrders           = "";
	Else
		ParametersStructure.FinancialAccountingGroup       = "";
		ParametersStructure.Department                = "Object.Department";
		ParametersStructure.Manager                     = "Object.Manager";
		ParametersStructure.IncomingDocumentNumber      = "";
		ParametersStructure.IncomingDocumentDate       = "";
		ParametersStructure.ARAPObject               = "Object.Discrepancies.ARAPObject";
		// Used to determine the object of calculations.
		ParametersStructure.InvoiceForOrders            = "Object.SaleByOrders";
	EndIf;
	
	// It is used when determining the default calculation order and the list of available orders to choose from.
	// Used to determine the object of calculations.
	ThereAreDocumentsWithoutCalculationObjects = False;
	
	If FillingData <> Undefined
		And CommonClientServer.HasAttributeOrObjectProperty(FillingData, "BusinessOperation")
		And FillingData.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
		And CommonClientServer.HasAttributeOrObjectProperty(FillingData, "Discrepancies") Then
		
		BasisDocuments = FillingData.Discrepancies.Unload(, "SalesOrder").UnloadColumn("SalesOrder");
		
		DocumentsByType = SalesServer.DocumentsBasedOnAvailabilityOfSettlementObjects(BasisDocuments);
		ThereAreDocumentsWithoutCalculationObjects = DocumentsByType.DocumentsWithoutCalculationObjects.Count() > 0;
		
	EndIf;
	
	If ThereAreDocumentsWithoutCalculationObjects Then
		
		ParametersStructure.PropsNameTSOrder = "";
		ParametersStructure.OrderBase = "Object.DocumentBasis";
		
	Else
		ParametersStructure.OrderBase = "";
	EndIf;
	
	// The name of the button that opens the Payment offset assistant for the current set of parameters.
	ParametersStructure.FormItems.PaymentSettlement                      = "";
	
	// The name of the table element of the form that displays the amount of settlements.
	// Used to set the conditional design.
	// It should be filled in if the document supports line-by-line manual editing of settlement amounts.
	If ThisIsDebtAdjustment Then
		ParametersStructure.FormItems.AmountOfTSSettlements = "ARAPAdjustmentAmountARAP";
	Else
		ParametersStructure.FormItems.AmountOfTSSettlements = "DiscrepanciesAmountARAP";
	EndIf;
	
	#EndRegion
	
	#Region EditingCurrenciesAndCurrencyAmountsOfDocument
	
	// The course and multiplicity of the document are one pair for the document.
	// They are used to calculate the amount of mutual settlements and in the form of editing the currencies and exchange rates of the document.
	ParametersStructure.CourseNumerator                          = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                        = "Object.CourseDenominator";
	
	// Editing and recalculation of the document amount in the form of currencies and exchange rates is not available,
	// since the amount in the document currency will change only when filled in due to discrepancies
	ParametersStructure.DocumentAmountViewOnly           = True;
	
	// The name of the hyperlink displaying the current exchange rate of the document and opening the corresponding form.
	ParametersStructure.FormItems.LabelCurrencies                    = "CurrencyDecoration";
	
	// Are used in the condition through OR with the right to deviate from the terms of sale/purchases.
	If ThisIsDebtAdjustment Then
		ParametersStructure.DocumentCurrencyViewOnly                  = False;
		ParametersStructure.MutualSettlementsCurrencyViewOnly             = False;
	ElsIf ThisIsAdjustmentOfPrimaryDocument Then
		ParametersStructure.DocumentCurrencyViewOnly                  = False;
		ParametersStructure.MutualSettlementsCurrencyViewOnly             = True;
	Else
		ParametersStructure.DocumentCurrencyViewOnly                  = True;
		ParametersStructure.MutualSettlementsCurrencyViewOnly             = True;
	EndIf;
	
	// If it is not necessary to show the amount and currency of mutual settlements based on the data of the document.
	ParametersStructure.DonTShowCalculations                            = False;
	// If it is not required to offer recalculation of the amount of the document.
	ParametersStructure.DoNotRecalculateTheAmountOfTheDocument                  = False;
	
	#EndRegion
	
	#Region ScheduledPaymentScheduleAndPaymentDate
	
	// Function Payment stages and payment date
	ParametersStructure.PathToTSDataPaymentSteps         = "";
	ParametersStructure.PaymentDate                      = "Object.PaymentDate";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStepsText";
	ParametersStructure.SourceOfAmountsTabularPart       = True;
	If ThisIsDebtAdjustment Then
		ParametersStructure.PaymentSchedule                 = "";
	Else
		ParametersStructure.PaymentSchedule                 = "Object.PaymentSchedule";
	EndIf;
	
	// The name of the hyperlink that displays the current payment rules of the document and opens the Payment Rules form.
	ParametersStructure.FormItems.InscriptionStages             = "DecorationPaymentSteps";
	
	// If you need to restrict the editing of payment melts.
	ParametersStructure.PaymentStagesViewOnly                      = False;
	// If the order invoice is also true, the extended form of the payment schedule will be displayed, despite the functional option "Simplified form of payment".
	ParametersStructure.InvoiceForSeveralOrdersIsPossible           = False;
	#EndRegion
	
	#Region MutualSettlementsStatus
	
	// The name of the hyperlink that displays the status of calculations and opens the corresponding report,
	ParametersStructure.FormItems.InscriptionCalculations                   = "";
	
	#EndRegion
	
	#Region LimitsOnDebtUnderAgreement
	
	// Hyperlink displaying the status of the debt limit
	ParametersStructure.FormItems.DebtLimitationText    = "";
	// A picture showing the shipment ban
	ParametersStructure.FormItems.DebtLimitation = ""; 
	
	#EndRegion
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
		ParametersStructure.ToReturnReusablePackage = "Object.DocumentBasis.ToReturnReusablePackage";
		ParametersStructure.PackageDepositIsRequired      = "Object.DocumentBasis.PackageDepositIsRequired";
	Else
		ParametersStructure.ToReturnReusablePackage = False;
		ParametersStructure.PackageDepositIsRequired      = False;
	EndIf;
	
	ParametersStructure.TSP = "Object.Warehouse";

	Return ParametersStructure;
EndFunction

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.SaleAdjustment, 
//  		 Document link.The
//  		 adjustment of the implementation, the given formstructure is a document for which it is necessary to form parameters.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	If TypeOf(Object) = Type("DocumentObject.SaleAdjustment")
		Or TypeOf(Object) = Type("FormDataStructure") Then
		ObjectData = Object;
	ElsIf TypeOf(Object) = Type("DocumentRef.SaleAdjustment") Then
		ObjectData = Common.ObjectAttributesValues(Object, "Organization, Contract, Warehouse, Date, LineOfBusiness, Department, BusinessOperation");
	EndIf;
	
	FillParameters.Organization = ObjectData.Organization;
	FillParameters.Date = ObjectData.Date;
	FillParameters.Contract = ObjectData.Contract;
	FillParameters.LineOfBusiness = ObjectData.LineOfBusiness;
	If Not ObjectData.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
		And Not ObjectData.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
		And Not ObjectData.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
		And Not ObjectData.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		And Not ObjectData.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
		FillParameters.Warehouse = ObjectData.Warehouse;
		FillParameters.Department = ObjectData.Department;
		
		FillParameters.GoodsSales       = True;
		FillParameters.ImplementationOfWorksServices    = True;
		FillParameters.OtherAssetSale = True;
	Else
		FillParameters.ReportToMaterialProvider           = True;
	EndIf;
	Return FillParameters;
	
EndFunction

// Returns a structure with the name of the tabular parts of the document that store information about the goods.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* Goods - ValueTable, TabularSection, Undefined - data about the goods of the document.
//		* Discrepancies - ValueTable, TabularSection, Undefined - data on discrepancies in the purchase of the document.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure;
	DocumentTables.Insert("Goods");
	DocumentTables.Insert("Discrepancies");
	
	Return DocumentTables;
	
EndFunction

// Returns a table with data before and after the adjustment.
//
// Parameters:
//  Object  - DocumentObject.SaleAdjustment,
//  		 Document link.Realisation correctionrealization,
//  		 dataformstructure - correction document.
//  NumberOfPackagesIsUsed - Boolean - calculation of the price for quantity or for the number of packages
//
// Returns:
//  ValueTable - the data of the table part, as they are displayed to the user.
//
Function AdjustmentDataBeforeEnteringBalances(Object, NumberOfPackagesIsUsed = False) Export

	Query = New Query;
	PartsOfQueryText = New Array;
	TextOfRequestPart =
	"SELECT
	|	T.Products AS Products,
	|	T.PartnerProducts AS PartnerProducts,
	|	T.Characteristic AS Characteristic,
	|	T.ProductsInSet AS ProductsInSet,
	|	T.ItemVariantOfSet AS ItemVariantOfSet,
	|	T.Content AS Content,
	|	T.Package AS Package,
	|	T.Series AS Series,
	|	T.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	T.Warehouse AS Warehouse,
	|	T.Department AS Department,
	|	T.IncomeItem AS IncomeItem,
	|	T.DimensionOfRevenue AS DimensionOfRevenue,
	|	T.CCDNumber AS CCDNumber,
	|	T.Price AS Price,
	|	T.VATRate AS VATRate,
	|	T.NumberOfPackages AS NumberOfPackages,
	|	T.Count AS Count,
	|	T.QuantityByGBRN AS QuantityByGBRN,
	|	T.Sum AS Sum,
	|	T.VATAmount AS VATAmount,
	|	T.AmountIncludingVAT AS AmountIncludingVAT,
	|	T.AmountARAP AS AmountARAP,
	|	T.LineNumber AS LineNumber,
	|	T.FEACNCode AS FEACNCode,
	|	T.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	T.AmountExcludingVATMan AS AmountExcludingVATMan
	|INTO TTProducts_1
	|FROM
	|	&Goods AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Products AS Products,
	|	T.PartnerProducts AS PartnerProducts,
	|	T.Characteristic AS Characteristic,
	|	T.ProductsInSet AS ProductsInSet,
	|	T.ItemVariantOfSet AS ItemVariantOfSet,
	|	T.Content AS Content,
	|	T.Package AS Package,
	|	T.Series AS Series,
	|	T.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	T.Warehouse AS Warehouse,
	|	T.Department AS Department,
	|	T.IncomeItem AS IncomeItem,
	|	T.DimensionOfRevenue AS DimensionOfRevenue,
	|	T.CCDNumber AS CCDNumber,
	|	T.VATRate AS VATRate,
	|	T.NumberOfPackages AS NumberOfPackages,
	|	T.Count AS Count,
	|	T.QuantityByGBRN AS QuantityByGBRN,
	|	T.Sum AS Sum,
	|	T.VATAmount AS VATAmount,
	|	T.AmountIncludingVAT AS AmountIncludingVAT,
	|	T.AmountARAP AS AmountARAP,
	|	T.PostingOption AS PostingOption,
	|	T.CostDefiningMethod AS CostDefiningMethod,
	|	T.Cost_ AS Cost_,
	|	T.CostExcludingVAT_ AS CostExcludingVAT_,
	|	T.CostLocal AS CostLocal,
	|	T.CDCost AS CDCost,
	|	T.TDCost AS TDCost,
	|	T.CostPriceKind AS CostPriceKind,
	|	T.DateOfCostFillingByPriceType AS DateOfCostFillingByPriceType,
	|	T.FEACNCode AS FEACNCode,
	|	T.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	T.AmountExcludingVATMan AS AmountExcludingVATMan	
	|INTO TTDiscrepancies
	|FROM
	|	&Discrepancies AS T";
	PartsOfQueryText.Add(TextOfRequestPart);
	Query.SetParameter("Date", Common.ObjectAttributeValue(Object.DocumentBasis, "Date"));
	Query.SetParameter("Country", SettingsValueClientServerCached.CountryOfOrganizationRegistration(Object.Organization));
	Query.SetParameter("SubjectToExcise", Object.SubjectToExcise);
	
	TextOfRequestPart = ExcisableGoodsAccounting.QueryTextTTExcisableItems("TTProducts_1");
	PartsOfQueryText.Add(TextOfRequestPart);
	TextOfRequestPart =
	"SELECT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.Content AS Content,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	Table.Package AS Package,
	|	Table.Series AS Series,
	|	Table.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Table.Warehouse AS Warehouse,
	|	Table.Department AS Department,
	|	Table.CCDNumber AS CCDNumber,
	|	Table.FEACNCode AS FEACNCode,
	|	Table.PartnerProducts AS PartnerProducts,
	|	Table.IncomeItem AS IncomeItem,
	|	Table.DimensionOfRevenue AS DimensionOfRevenue,
	|	MAX(Table.VATRate) AS VATRate,
	|	MAX(Table.Price) AS Price,
	|	SUM(Table.NumberOfPackages) AS NumberOfPackages,
	|	SUM(Table.Count) AS Count,
	|	SUM(Table.QuantityByGBRN) AS QuantityByGBRN,
	|	SUM(Table.Sum) AS Sum,
	|	SUM(Table.VATAmount) AS VATAmount,
	|	SUM(Table.AmountIncludingVAT) AS AmountIncludingVAT,
	|	SUM(Table.AmountARAP) AS AmountARAP,
	|	MAX(Table.VATRateAfter) AS VATRateAfter,
	|	MAX(Table.PriceAfter) AS PriceAfter,
	|	SUM(Table.NumberOfPackagesAfter) AS NumberOfPackagesAfter,
	|	SUM(Table.QuantityAfter) AS QuantityAfter,
	|	SUM(Table.QuantityAccordingToRNPTAfter) AS QuantityAccordingToRNPTAfter,
	|	SUM(Table.AmountAfter) AS AmountAfter,
	|	SUM(Table.VATAmountAfter) AS VATAmountAfter,
	|	SUM(Table.AmountWithVATAfter) AS AmountWithVATAfter,
	|	SUM(Table.AmountOfSettlementsAfter) AS AmountOfSettlementsAfter,
	|	ISNULL(MAX(Table.ReflectionOptionAfter),MAX(Table.ReflectionOptionUpTo)) AS PostingOption,
	|	MAX(Table.ReflectionOptionUpTo) AS OptionToReflectWriteOff,
	|	MAX(Table.CostDefiningMethod) AS CostDefiningMethod,
	|	MAX(Table.Cost_) AS Cost_,
	|	MAX(Table.CostExcludingVAT_) AS CostExcludingVAT_,
	|	MAX(Table.CostLocal) AS CostLocal,
	|	MAX(Table.CDCost) AS CDCost,
	|	MAX(Table.TDCost) AS TDCost,
	|	MAX(Table.CostPriceKind) AS CostPriceKind,
	|	MAX(Table.DateOfCostFillingByPriceType) AS DateOfCostFillingByPriceType,
	|	SUM(Table.Count - Table.QuantityAfter) < 0
	|		OR SUM(Table.NumberOfPackages - Table.NumberOfPackagesAfter) < 0 AS ThisIsWriteOffLine,
	|	MAX(Table.LineNumber) AS LineNumber,
	|	Table.SubjectToExcise AS SubjectToExcise,
	|	SUM(Table.AmountExcludingVATCompl) AS AmountExcludingVATCompl,
	|	SUM(Table.AmountExcludingVATMan) AS AmountExcludingVATMan,
	|	SUM(Table.VATExclusiveAmountLocalAfter) AS VATExclusiveAmountLocalAfter,
	|	SUM(Table.VATExclusiveAmountManAfter) AS VATExclusiveAmountManAfter		
	|FROM
	|	(SELECT
	|		T.Products AS Products,
	|		T.PartnerProducts AS PartnerProducts,
	|		T.FEACNCode AS FEACNCode,
	|		T.Characteristic AS Characteristic,
	|		T.ProductsInSet AS ProductsInSet,
	|		T.ItemVariantOfSet AS ItemVariantOfSet,
	|		T.Content AS Content,
	|		T.Package AS Package,
	|		T.Series AS Series,
	|		T.BatchesIndicationStatus AS BatchesIndicationStatus,
	|		T.Warehouse AS Warehouse,
	|		T.Department AS Department,
	|		T.CCDNumber AS CCDNumber,
	|		T.IncomeItem AS IncomeItem,
	|		T.DimensionOfRevenue AS DimensionOfRevenue,
	|		T.VATRate AS VATRate,
	|		SUM(T.Price) AS Price,
	|		SUM(T.NumberOfPackages) AS NumberOfPackages,
	|		SUM(T.Count) AS Count,
	|		SUM(T.QuantityByGBRN) AS QuantityByGBRN,
	|		SUM(T.Sum) AS Sum,
	|		SUM(T.VATAmount) AS VATAmount,
	|		SUM(T.AmountIncludingVAT) AS AmountIncludingVAT,
	|		SUM(T.AmountARAP) AS AmountARAP,
	|		T.SubjectToExcise AS SubjectToExcise,
	|		NULL AS VATRateAfter,
	|		NULL AS PriceAfter,
	|		SUM(T.NumberOfPackagesAfter) AS NumberOfPackagesAfter,
	|		SUM(T.QuantityAfter) AS QuantityAfter,
	|		SUM(T.QuantityAccordingToRNPTAfter) AS QuantityAccordingToRNPTAfter,
	|		SUM(T.AmountAfter) AS AmountAfter,
	|		SUM(T.VATAmountAfter) AS VATAmountAfter,
	|		SUM(T.AmountWithVATAfter) AS AmountWithVATAfter,
	|		SUM(T.AmountOfSettlementsAfter) AS AmountOfSettlementsAfter,
	|		MAX(DiscrepanciesBefore.PostingOption) AS ReflectionOptionUpTo,
	|		NULL AS ReflectionOptionAfter,
	|		MAX(T.CostDefiningMethod) AS CostDefiningMethod,
	|		MAX(T.Cost_) AS Cost_,
	|		MAX(T.CostExcludingVAT_) AS CostExcludingVAT_,
	|		MAX(T.CostLocal) AS CostLocal,
	|		MAX(T.CDCost) AS CDCost,
	|		MAX(T.TDCost) AS TDCost,
	|		MAX(T.CostPriceKind) AS CostPriceKind,
	|		MAX(T.DateOfCostFillingByPriceType) AS DateOfCostFillingByPriceType,
	|		MAX(T.LineNumber) AS LineNumber,
	|		SUM(T.AmountExcludingVATCompl) AS AmountExcludingVATCompl,
	|		SUM(T.AmountExcludingVATMan) AS AmountExcludingVATMan,
	|		SUM(T.VATExclusiveAmountLocalAfter) AS VATExclusiveAmountLocalAfter,
	|		SUM(T.VATExclusiveAmountManAfter) AS VATExclusiveAmountManAfter	
	|	FROM
	|		(SELECT
	|			Goods.Products AS Products,
	|			Goods.PartnerProducts AS PartnerProducts,
	|			Goods.FEACNCode AS FEACNCode,
	|			Goods.Characteristic AS Characteristic,
	|			Goods.ProductsInSet AS ProductsInSet,
	|			Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|			Goods.Content AS Content,
	|			Goods.Package AS Package,
	|			Goods.Series AS Series,
	|			Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|			Goods.Warehouse AS Warehouse,
	|			Goods.Department AS Department,
	|			Goods.CCDNumber AS CCDNumber,
	|			Goods.IncomeItem AS IncomeItem,
	|			Goods.DimensionOfRevenue AS DimensionOfRevenue,
	|			Goods.VATRate AS VATRate,
	|			Goods.Price AS Price,
	|			Goods.NumberOfPackages AS NumberOfPackages,
	|			Goods.Count AS Count,
	|			Goods.QuantityByGBRN AS QuantityByGBRN,
	|			Goods.Sum AS Sum,
	|			Goods.VATAmount AS VATAmount,
	|			Goods.AmountIncludingVAT AS AmountIncludingVAT,
	|			Goods.AmountARAP AS AmountARAP,
	|			0 AS NumberOfPackagesAfter,
	|			0 AS QuantityAfter,
	|			0 AS QuantityAccordingToRNPTAfter,
	|			0 AS AmountAfter,
	|			0 AS VATAmountAfter,
	|			0 AS AmountWithVATAfter,
	|			CASE
	|				WHEN ISNULL(TTExcisableItems.ExcisableGoods, FALSE)
	|					THEN &SubjectToExcise
	|				ELSE FALSE
	|			END AS SubjectToExcise,
	|			0 AS AmountOfSettlementsAfter,
	|			NULL AS CostDefiningMethod,
	|			NULL AS Cost_,
	|			NULL AS CostExcludingVAT_,
	|			NULL AS CostLocal,
	|			NULL AS CDCost,
	|			NULL AS TDCost,
	|			NULL AS CostPriceKind,
	|			NULL AS DateOfCostFillingByPriceType,
	|			Goods.LineNumber AS LineNumber,
	|			Goods.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|			Goods.AmountExcludingVATMan AS AmountExcludingVATMan,
	|			0 AS VATExclusiveAmountLocalAfter,
	|			0 AS VATExclusiveAmountManAfter
	|		FROM
	|			TTProducts_1 AS Goods
	|				LEFT JOIN TTExcisableItems
	|				ON Goods.Products = TTExcisableItems.Products
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Discrepancies.Products,
	|			Discrepancies.PartnerProducts AS PartnerProducts,
	|			Discrepancies.FEACNCode AS FEACNCode,
	|			Discrepancies.Characteristic,
	|			Discrepancies.ProductsInSet,
	|			Discrepancies.ItemVariantOfSet,
	|			Discrepancies.Content,
	|			Discrepancies.Package,
	|			Discrepancies.Series,
	|			Discrepancies.BatchesIndicationStatus,
	|			Discrepancies.Warehouse,
	|			Discrepancies.Department,
	|			Discrepancies.CCDNumber,
	|			Discrepancies.IncomeItem,
	|			Discrepancies.DimensionOfRevenue,
	|			Discrepancies.VATRate,
	|			0,
	|			-Discrepancies.NumberOfPackages,
	|			-Discrepancies.Count,
	|			-Discrepancies.QuantityByGBRN,
	|			-Discrepancies.Sum,
	|			-Discrepancies.VATAmount,
	|			-Discrepancies.AmountIncludingVAT,
	|			-Discrepancies.AmountARAP,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			CASE
	|				WHEN ISNULL(TTExcisableItems.ExcisableGoods, FALSE)
	|					THEN &SubjectToExcise
	|				ELSE FALSE
	|			END AS SubjectToExcise,
	|			0,
	|			Discrepancies.CostDefiningMethod,
	|			Discrepancies.Cost_ AS Cost_,
	|			Discrepancies.CostExcludingVAT_ AS CostExcludingVAT_,
	|			Discrepancies.CostLocal AS CostLocal,
	|			Discrepancies.CDCost AS CDCost,
	|			Discrepancies.TDCost AS TDCost,
	|			Discrepancies.CostPriceKind AS CostPriceKind,
	|			Discrepancies.DateOfCostFillingByPriceType AS DateOfCostFillingByPriceType,
	|			0 AS LineNumber,
	|			-Discrepancies.AmountExcludingVATCompl,
	|			-Discrepancies.AmountExcludingVATMan,
	|			0,
	|			0
	|
	|		FROM
	|			TTDiscrepancies AS Discrepancies
	|				LEFT JOIN TTExcisableItems AS TTExcisableItems
	|				ON Discrepancies.Products = TTExcisableItems.Products
	|		) AS T
	|			LEFT JOIN TTDiscrepancies AS DiscrepanciesBefore
	|			ON (DiscrepanciesBefore.Products = T.Products)
	|				AND (DiscrepanciesBefore.Products = T.Products)
	|				AND (DiscrepanciesBefore.Characteristic = T.Characteristic)
	|				AND (DiscrepanciesBefore.ProductsInSet = T.ProductsInSet)
	|				AND (DiscrepanciesBefore.ItemVariantOfSet = T.ItemVariantOfSet)
	|				AND (DiscrepanciesBefore.Content = T.Content)
	|				AND (DiscrepanciesBefore.Package = T.Package)
	|				AND (DiscrepanciesBefore.Series = T.Series)
	|				AND (DiscrepanciesBefore.BatchesIndicationStatus = T.BatchesIndicationStatus)
	|				AND (DiscrepanciesBefore.Warehouse = T.Warehouse)
	|				AND (DiscrepanciesBefore.Department = T.Department)
	|				AND (DiscrepanciesBefore.CCDNumber = T.CCDNumber)
	|				AND (DiscrepanciesBefore.IncomeItem = T.IncomeItem)
	|				AND (DiscrepanciesBefore.DimensionOfRevenue = T.DimensionOfRevenue)
	|				AND (DiscrepanciesBefore.VATRate = T.VATRate)
	|	
	|	GROUP BY
	|		T.Products,
	|		T.PartnerProducts,
	|		T.FEACNCode,
	|		T.Characteristic,
	|		T.ProductsInSet,
	|		T.ItemVariantOfSet,
	|		T.Content,
	|		T.Package,
	|		T.Series,
	|		T.BatchesIndicationStatus,
	|		T.Warehouse,
	|		T.Department,
	|		T.CCDNumber,
	|		T.IncomeItem,
	|		T.DimensionOfRevenue,
	|		T.SubjectToExcise,
	|		T.VATRate
	|	
	|	HAVING
	|		(SUM(T.NumberOfPackages) <> 0
	|			OR SUM(T.Count) <> 0
	|			OR SUM(T.QuantityByGBRN) <> 0
	|			OR SUM(T.Sum) <> 0
	|			OR SUM(T.VATAmount) <> 0
	|			OR SUM(T.AmountIncludingVAT) <> 0
	|			OR SUM(T.AmountARAP) <> 0)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Goods.Products,
	|		Goods.PartnerProducts AS PartnerProducts,
	|		Goods.FEACNCode AS FEACNCode,
	|		Goods.Characteristic,
	|		Goods.ProductsInSet,
	|		Goods.ItemVariantOfSet,
	|		Goods.Content,
	|		Goods.Package,
	|		Goods.Series,
	|		Goods.BatchesIndicationStatus,
	|		Goods.Warehouse,
	|		Goods.Department,
	|		Goods.CCDNumber,
	|		Goods.IncomeItem,
	|		Goods.DimensionOfRevenue,
	|		NULL,
	|		NULL,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		CASE
	|			WHEN ISNULL(TTExcisableItems.ExcisableGoods, FALSE)
	|				THEN &SubjectToExcise
	|			ELSE FALSE
	|		END AS SubjectToExcise,
	|		Goods.VATRate,
	|		Goods.Price,
	|		Goods.NumberOfPackages,
	|		Goods.Count,
	|		Goods.QuantityByGBRN,
	|		Goods.Sum,
	|		Goods.VATAmount,
	|		Goods.AmountIncludingVAT,
	|		Goods.AmountARAP,
	|		NULL,
	|		DiscrepanciesAfter.PostingOption,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,		 
	|		Goods.LineNumber AS LineNumber,
	|		0,
	|		0,
	|		Goods.AmountExcludingVATCompl,
	|		Goods.AmountExcludingVATMan
	|	FROM
	|		TTProducts_1 AS Goods
	|			LEFT JOIN TTExcisableItems AS TTExcisableItems
	|			ON TTExcisableItems.Products = Goods.Products
	|			LEFT JOIN TTDiscrepancies AS DiscrepanciesAfter
	|			ON (DiscrepanciesAfter.Products = Goods.Products)
	|				AND (DiscrepanciesAfter.Products = Goods.Products)
	|				AND (DiscrepanciesAfter.Characteristic = Goods.Characteristic)
	|				AND (DiscrepanciesAfter.ProductsInSet = Goods.ProductsInSet)
	|				AND (DiscrepanciesAfter.ItemVariantOfSet = Goods.ItemVariantOfSet)
	|				AND (DiscrepanciesAfter.Content = Goods.Content)
	|				AND (DiscrepanciesAfter.Package = Goods.Package)
	|				AND (DiscrepanciesAfter.Series = Goods.Series)
	|				AND (DiscrepanciesAfter.BatchesIndicationStatus = Goods.BatchesIndicationStatus)
	|				AND (DiscrepanciesAfter.Warehouse = Goods.Warehouse)
	|				AND (DiscrepanciesAfter.Department = Goods.Department)
	|				AND (DiscrepanciesAfter.CCDNumber = Goods.CCDNumber)
	|				AND (DiscrepanciesAfter.IncomeItem = Goods.IncomeItem)
	|				AND (DiscrepanciesAfter.DimensionOfRevenue = Goods.DimensionOfRevenue)
	|				AND (DiscrepanciesAfter.VATRate = Goods.VATRate)) AS Table
	|
	|GROUP BY
	|	Table.Products,
	|	Table.PartnerProducts,
	|	Table.FEACNCode,
	|	Table.Characteristic,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Content,
	|	Table.Package,
	|	Table.Series,
	|	Table.BatchesIndicationStatus,
	|	Table.Warehouse,
	|	Table.Department,
	|	Table.CCDNumber,
	|	Table.IncomeItem,
	|	Table.SubjectToExcise,
	|	Table.DimensionOfRevenue
	|
	|ORDER BY
	|	LineNumber";
	PartsOfQueryText.Add(TextOfRequestPart);
	
	Query.Text = StrConcat(PartsOfQueryText, Common.QueryBatchSeparator());
	
	Query.SetParameter("Goods", Object.Goods.Unload());
	Query.SetParameter("Discrepancies", Object.Discrepancies.Unload());
	
	ResultTable2 = Query.Execute().Unload();
	
	// Since the price is not stored in the "Discrepancies" tabular part, we will calculate the "Price to" separately
	QuantityName = ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count");
	For Each CurrentRow In ResultTable2 Do
		If CurrentRow[QuantityName] = 0 Then
			CurrentRow.Price = CurrentRow.Sum;
		Else
			CurrentRow.Price = Round(CurrentRow.Sum / CurrentRow[QuantityName], 2);
		EndIf;
		CurrentRow.LineNumber = ResultTable2.IndexOf(CurrentRow)+1;
	EndDo;
	
	Return ResultTable2;

EndFunction

// Returns a string with Attributes for linking the TS "Products" and TS "Discrepancies" lines
//
// Parameters:
//  OtherAssetServiceAdjustment - Boolean - adjustment of services and other assets
//
// Returns:
//  String - list of communication Attributes.
//
Function KeyAttributesOFRelationshipOfTableRows(OtherAssetServiceAdjustment) Export
	
	If OtherAssetServiceAdjustment Then
		KeyAttributes = "Content,Department,IncomeItem,DimensionOfRevenue";
	Else
		KeyAttributes = "Content,ProductsInSet,ItemVariantOfSet,Products,Characteristic,Series,Package,Warehouse,CCDNumber,IncomeItem,DimensionOfRevenue,Department";
	EndIf;
	
	Return KeyAttributes;

EndFunction

// Function constructor of procedure parameters correctabledocument
// 
// Returns:
// 	Structure - LongDesc:
// * CorrectedDocument - DocumentRef.CustomerInvoice
// * DocumentBasis - DocumentRef.CustomerInvoice
// * Date - Date
// * AdjustmentKind - EnumRef.BusinessTransactions
//
Function ParametersForGettingDocumentBeingCorrected() Export
	
	Parameters = New Structure;
	Parameters.Insert("CorrectedDocument", Documents.CustomerInvoice.EmptyRef());
	Parameters.Insert("DocumentBasis", Documents.CustomerInvoice.EmptyRef());
	Parameters.Insert("Date", Date(1, 1, 1));
	Parameters.Insert("AdjustmentKind", Enums.BusinessTransactions.EmptyRef());
	
	Return Parameters;	
	
EndFunction

// Returns the purchase adjustment document that is being corrected.
//
// Parameters:
//	DocumentAttributes - See ParametersForGettingDocumentBeingCorrected
//
// Returns:
//  DocumentRef - The document being corrected.
//
Function CorrectedDocument(Val DocumentAttributes) Export
	
	SetPrivilegedMode(True);

	CorrectedDocument = Undefined;
	
	Query = New Query;
	Query.SetParameter("CorrectedDocument", DocumentAttributes.CorrectedDocument);
	Query.SetParameter("DocumentBasis", DocumentAttributes.DocumentBasis);
	Query.SetParameter("Period", DocumentAttributes.Date);
	Query.SetParameter("AdjustmentKind", DocumentAttributes.AdjustmentKind);
	
	Query.Text = QueryTextTTCorrectionDocumentToBeCorrected(Query);
	
	Query.Text = Query.Text + 
	"SELECT
	|	TT_CorrectionDocumentBeingCorrected.CorrectedDocument
	|FROM
	|	TT_CorrectionDocumentBeingCorrected AS TT_CorrectionDocumentBeingCorrected";
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		CorrectedDocument = Selection.CorrectedDocument;	
	EndIf;
	
	Return CorrectedDocument;
	
EndFunction

// Creates a representation of the metadata object in the main language.
// 
// Returns:
//  String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	SynonymForInformationDatabaseEntry = NStr(
		"vi = 'Điều chỉnh bán hàng';
		|ru = 'Корректировка реализации';
		|en = 'Sales adjustment'; fa = 'تعدیل فروش';
		|it = 'Rettifica vendita';
		|pl = 'Korekta realizacji';
		|tr = 'Satış düzeltmesi'",
		DefaultLanguageCode);
		
	Return SynonymForInformationDatabaseEntry;
	
EndFunction

#Region CheckingDocumentFilling

// Performs a check of filling in the 'Correction table' of the correction document form before entering Balances.
//
// Parameters:
//	Form - Structure - a collection containing information about the document and including the following fields:
//		* Object - DocumentObject.PurchaseAdjustment - Document object.
//		* SeriesSpecificationParameters - See ProductsServer.SeriesSpecificationParameters.
//		* AdjustmentTable - ValueTable - a table containing information about the goods, works, and services being corrected.
//	CheckedAttributes - Array of String - description of the fields of the document object to be checked, separated by commas.
//	Cancel - Boolean - indicates that further actions with the document object were refused due to errors found when
//						checking the filling.
//
Procedure CheckAttributesFilling(Form, CheckedAttributes, Cancel) Export
	
	VTAdjustmentTable	= Form.AdjustmentTable;
	TSName					= "AdjustmentTable";
	PresentationOfTS			= NStr("vi = 'Dữ liệu điều chỉnh';
										|ru = 'Данные корректировки';
										|en = 'Correction data'; fa = 'داده‌های اصلاح';
										|it = 'Dati di correzione';
										|pl = 'Dane korekty';
										|tr = 'Düzeltme verileri'");
	
	If VTAdjustmentTable.Count() = 0 Then
		MessageText= NStr("vi = 'Chưa nhập dòng nào trong danh sách ""%1""';
							|ru = 'Не введено ни одной строки в список ""%1""';
							|en = 'The list ""%1"" is blank.'; fa = 'The list ""%1"" is blank.';
							|it = 'Non è immessa alcuna riga nell''elenco ""%1""';
							|pl = 'Nie wprowadzono żadnego wiersza do listy ""%1""';
							|tr = '""%1"" listesine herhangi satır girilmedi'");
		MessageText = StrTemplate(MessageText, PresentationOfTS);
		
		Common.MessageToUser(MessageText,
												Undefined,
												TSName,
												"",
												Cancel);
	EndIf;
	
	Object = Form.Object;
	
	VTOFIncomingGoods = TableOfProductsByReflectionOption(VTAdjustmentTable, False);
	
	UseVATAccounting = GetFunctionalOption("UseVATAccounting")
							And Object.VATTaxation <> Enums.VATTaxationTypes.EmptyRef()
							And Object.VATTaxation <> Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
	ThisIsTraceableDocument = AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(VTOFIncomingGoods,
																								Object.Date);
	UseBusinessUnits = GetFunctionalOption("UseBusinessUnits");
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES =
		Object.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices;
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	QueryTexts = New Array;
	QueryTexts.Add(QueryTextTTOfSalesDocument());
	QueryTexts.Add(QueryTextTTTablesOfProductsForRequest());
	QueryTexts.Add(QueryTextTTTablesSetsPreparation());
	QueryTexts.Add(QueryTextTTTableSetsOptional());
	QueryTexts.Add(QueryTextTTTableSets());
	QueryTexts.Add(QueryTextTTTablesGoods());
	QueryTexts.Add(QueryTextTTFoundationDocumentData());
	QueryTexts.Add(QueryTextTTPreviousAdjustmentData());
	QueryTexts.Add(QueryTextTTToCheckDataForLastAdjustment());
	
	RequestVerificationTexts = New Array;
	RequestVerificationTexts.Add(QueryTextCheckingFillingOfWarehouse());
	RequestVerificationTexts.Add(QueryTextChecksForFillingInProductListAndContent());
	RequestVerificationTexts.Add(QueryTextChecksForFillingInCharacteristics());
	RequestVerificationTexts.Add(QueryTextCheckingFillingInOfCCDNumbers());
	RequestVerificationTexts.Add(QueryTextCheckingFillingOfQuantity());
	RequestVerificationTexts.Add(QueryTextChecksForFillingInSummaryIndicators());
	RequestVerificationTexts.Add(QueryTextChecksForFillingInVATRates());
	RequestVerificationTexts.Add(QueryTextCheckingReflectionOptions());
	RequestVerificationTexts.Add(QueryTextCheckingFillingOfWarehouseInTabularPart());
	RequestVerificationTexts.Add(QueryTextCheckingFillingOfDivisionInTabularPart());
	RequestVerificationTexts.Add(QueryTextVerificationOfMethodsForDeterminingCost());
	RequestVerificationTexts.Add(QueryTextChecksTypeOfAdjustmentDoesNotMatchPreviousOne());
	
	RequestVerificationTexts.Add(QueryTextChecksVATTaxationCorrespondsToBasis());
	RequestVerificationTexts.Add(QueryTextChecksOrganizationCorrespondsToFoundation());
	RequestVerificationTexts.Add(QueryTextPartnerChecksMatchFoundation());
	RequestVerificationTexts.Add(QueryTextChecksCounterpartyCorrespondsToBasis());
	RequestVerificationTexts.Add(QueryTextVerificationContractCorrespondsToBasis());
	RequestVerificationTexts.Add(QueryTextChecksOrderOfCalculationsCorrespondsToBase());
	RequestVerificationTexts.Add(TextOfRequestForVerificationOfFillingInAmountOfMutualSettlements());
	
	QueryTextChecks = StrConcat(RequestVerificationTexts, TMCommonUse.QuerySeparatorInJoin());
	QueryTextChecks = QueryTextChecks + "
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryTextChecks);
	
	TextsOfVerificationRequestsBasedOnInitialCorrection = New Array;
	TextsOfVerificationRequestsBasedOnInitialCorrection.Add(QueryTextCheckingDataOnLastAdjustment());

	TextOfVerificationRequestsBasedOnInitialCorrection = StrConcat(TextsOfVerificationRequestsBasedOnInitialCorrection, TMCommonUse.QuerySeparatorInJoin());
	
	TextOfVerificationRequestsBasedOnInitialCorrection = TextOfVerificationRequestsBasedOnInitialCorrection + "
	|ORDER BY
	|	LineNumber";

	QueryTexts.Add(TextOfVerificationRequestsBasedOnInitialCorrection);
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	TempTablesManager = New TempTablesManager;
	
	CreateTemporaryTableOfSourceData(TempTablesManager, Object.DocumentBasis, Object.Ref);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryText;
	
	Query.SetParameter("Ref",				Object.Ref);
	Query.SetParameter("Date",				?(ValueIsFilled(Object.Ref), Object.Date, CurrentSessionDate()));
	Query.SetParameter("DocumentBasis",	Object.DocumentBasis);
	Query.SetParameter("Organization",		Object.Organization);
	Query.SetParameter("Partner",			Object.Partner);
	Query.SetParameter("Counterparty",			Object.Counterparty);
	Query.SetParameter("Contract",			Object.Contract);
	Query.SetParameter("ARAPObjectSettings",	Object.ARAPObjectSettings);
	Query.SetParameter("Warehouse",				Object.Warehouse);
	Query.SetParameter("VATTaxation",	Object.VATTaxation);
	Query.SetParameter("AdjustingEntryType",	Object.AdjustingEntryType);
	Query.SetParameter("PriceIncludesVAT",	Object.PriceIncludesVAT);
	Query.SetParameter("DifferentCurrencies"	,	Object.Currency <> Object.ARAPCurrency);
	Query.SetParameter("TableOfGoods",		VTAdjustmentTable);
	Query.SetParameter("UseVATAccounting",
								UseVATAccounting);
	Query.SetParameter("UseBusinessUnits",
								UseBusinessUnits);
	Query.SetParameter("UseSeveralWarehouses",
								UseSeveralWarehouses);
	Query.SetParameter("UseItemVariants",
								UseItemVariants);
	Query.SetParameter("RestrictGoodsReceiptWithoutCCDNumbers",
								RestrictGoodsReceiptWithoutCCDNumbers);
	Query.SetParameter("ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES",
								ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES);
	Query.SetParameter("UseTraceableImportedGoodsAccounting",
								UseTraceableImportedGoodsAccounting);
	
	ResultsPackage = Query.ExecuteBatch();
	
	SamplingOfLoggingErrors = ResultsPackage[ResultsPackage.Count()-2].Select();
	SelectionOfErrorsAlongCorrectionChain = ResultsPackage[ResultsPackage.Count()-1].Select();
	
	Report_FillingErrors(SamplingOfLoggingErrors, Cancel);
	ReportErrorsAlongCorrectionChain(SelectionOfErrorsAlongCorrectionChain, Cancel);
	
	CheckCorrectnessOfSelectionOfProductForVATTaxation(TempTablesManager, Cancel);
	
	CheckParameters = ProductsServer.SeriesFillCheckParameters();
	CheckParameters.PresentationOfTS			= PresentationOfTS;
	CheckParameters.PropsNameSeries			= "Series";
	CheckParameters.PathToFormTableData	= "";
	
	ProductsServer.CheckSeriesCompletion(Form,
												Form.SeriesSpecificationParameters,
												Cancel,
												Undefined,
												CheckParameters);
	
	If ThisIsTraceableDocument Then
		StringsList = Common.ValueTableToArray(VTOFIncomingGoods);
		
		AccountingForTraceableGoodsLocalization.CheckCorrectSettingsOfRNPTProducts(
			Form, VTAdjustmentTable, Object.Date, StringsList);
			
		AccountingForTraceableGoodsLocalization.CheckTraceabilityDataOfCCDNumbers(
			Form, VTAdjustmentTable, Object.Date, "AdjustmentTable");
			
	EndIf;
	
	If UseVATAccounting Then
		CheckIndicationOfAmountAndAmountOfVAT(Object, TempTablesManager, Cancel);
	EndIf;
	
	AdditionalVerifiableAttributes = New Array;
	
	If Object.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets Then
		AdditionalVerifiableAttributes.Add("AdjustmentTable.IncomeItem");
		AdditionalVerifiableAttributes.Add("AdjustmentTable.DimensionOfRevenue");
	EndIf;
	
	CommonClientServer.SupplementArray(CheckedAttributes, AdditionalVerifiableAttributes);
	
	CheckResult = ResultsOfDiscrepancyCheck(Object, VTAdjustmentTable);
	
	OptionsForSelection = New Structure;
	OptionsForSelection.Insert("DocumentDate",			Object.Date);
	OptionsForSelection.Insert("DocumentBasis",		Object.DocumentBasis);
	OptionsForSelection.Insert("BusinessOperation",	Object.AdjustmentKind);
	OptionsForSelection.Insert("AdjustingEntryType",			Object.AdjustingEntryType);
	OptionsForSelection.Insert("RecordInOtherIncome",	CheckResult.AmountForOtherIncome > 0);
	OptionsForSelection.Insert("ToExpenseAs",			CheckResult.AmountForOtherExpenses > 0);
	
	ItemsAndDimensionsSelectionParameters = OptionsForSelectingArticlesAndAnalyticsBeforeEnteringBalances(OptionsForSelection);
	IncomeAndExpensesServer.FillCheckProcessing(Form, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AdditionalVerifiableAttributes);
	
	If Not Cancel Then
		ArrayOfRowsToDelete_1 = New Array();
		
		For Each RowOfGoods In Object.Goods Do
			If RowOfGoods.Count = 0
				And RowOfGoods.NumberOfPackages = 0
				And RowOfGoods.AmountIncludingVAT = 0
				And RowOfGoods.VATAmount = 0 Then
				ArrayOfRowsToDelete_1.Add(RowOfGoods);
			EndIf;
		EndDo;
		
		For Each RowToDelete In ArrayOfRowsToDelete_1 Do
			Object.Goods.Delete(RowToDelete);
		EndDo;
	EndIf;
	
EndProcedure

// Checks the completeness of the verified details.
//
// Parameters:
//	 SaleAdjustment	- DocumentRef.SaleAdjustment - The document
//	 	on the basis of which the input is performed.
//	 Status					- EnumRef - The status of the document that is used for input.
//	 ThereAreErrorsPosted		- Boolean - If True-the document on the basis of which the input is made is not held.
//
Procedure CheckPossibilityOfEnteringBasedOn(SaleAdjustment, Status = Undefined,
	ThereAreErrorsPosted = False) Export
	
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.ThereAreErrorsPosted = ThereAreErrorsPosted;
	CheckParameters.ThereAreErrorsStatus = False;
	
	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(SaleAdjustment, CheckParameters);
	
EndProcedure

#EndRegion
#Region NonOperationalInterrogation

// We form a request to receive excise tax amounts for the document.
//
// Parameters:
//	DocumentRef - DocumentRef.SaleAdjustment - link to the document.
//
// Returns:
//	QueryResult - data on excise tax amounts.
//
Function GetExciseTaxData(DocumentRef) Export
		
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Organization AS Organization,
	|	ISNULL(DocumentData.DocumentBasis.Date, DocumentData.Date) AS ShipmentPeriod,
	|	CASE
	|		WHEN DocumentData.AdjustingEntryType IN
	|				(VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
	|				VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer)
	|		WHEN DocumentData.DocumentBasis.BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.SalesViaCommissionAgent)
	|		WHEN DocumentData.DocumentBasis.BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.SalesViaCommissionAgentGoodsInTransit)
	|		WHEN DocumentData.DocumentBasis.BusinessOperation = VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReportToMaterialProvider2_5)
	|		WHEN DocumentData.DocumentBasis.BusinessOperation = VALUE(Enum.BusinessTransactions.Subcontracting2_5)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.Subcontracting2_5)
	|		WHEN DocumentData.DocumentBasis.BusinessOperation = VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.RepairProductsFromProvidedMaterials2_5)
	|		WHEN DocumentData.DocumentBasis.BusinessOperation = VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.PerformWorksUsingProvidedMaterials2_5)
	|		WHEN DocumentData.DocumentBasis.BusinessOperation = VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.PerformRMUsingProvidedMaterials2_5)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer)
	|	END AS BusinessTransactionSetting,
	|	ISNULL(DocumentData.DocumentBasis.LineOfBusiness, DocumentData.LineOfBusiness) AS LineOfBusiness,
	|	CASE
	|		WHEN DocumentData.AdjustingEntryType IN
	|				(VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
	|				VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets))
	|			THEN ISNULL(DocumentData.DocumentBasis.Date, DocumentData.Date)
	|		ELSE ISNULL(DocumentData.DocumentBasis.DateOfTransferOfTitleToGoods,
	|						ISNULL(DocumentData.DocumentBasis.Date, DocumentData.Date))
	|	END AS DateOfTransferOfTitleToGoods
	|FROM
	|	Document.SaleAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;";
	
	Query = New Query;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = QueryText;
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	QueryText =
	"SELECT
	|	CategoryTable.Products AS Products,
	|	CategoryTable.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	CategoryTable.ConversionFactor_ AS ConversionFactor_
	|INTO TTCategoriesOfExcisableItems
	|FROM
	|	InformationRegister.ExcisableGoodsCategories.SliceLast(&ShipmentPeriod, (Products, Country) IN
	|		(SELECT
	|			T.Products AS Products,
	|			&RegistrationCountry AS Country
	|		FROM
	|			Document.SaleAdjustment.Discrepancies AS T
	|		WHERE
	|			T.Ref = &Ref)) AS CategoryTable
	|WHERE
	|	CategoryTable.ExcisableGoods
	|;
	|SELECT
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.InventoryOwnerAttribute.BusinessUnitProduction AS BusinessUnitProduction,
	|	InventoryKinds.ItemsLocationAttributes.Products AS Products,
	|	TableExciseCategories.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	InventoryKinds.Count AS Count,
	|	InventoryKinds.ExciseTaxAmount AS ExciseAmountInCurrencyLocal,
	|	CAST(InventoryKinds.ExciseTaxAmount * &ConversionRatioFromLocalToMan
	|		AS NUMBER(31,2)) AS ExciseAmountInCurrencyMgmt,
	|	CASE WHEN InventoryKinds.InventoryOwnerAttribute.SubjectToExcise
	|		THEN TableExciseCategories.ConversionFactor_ * InventoryKinds.Count
	|		ELSE 0
	|	END AS QuantityInExcisableCategoryUOM,
	|	InventoryKinds.RowID AS RowID
	|INTO TTTableTypesOfInventoryWriteOff
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS InventoryKinds
	|
	|	INNER JOIN TTCategoriesOfExcisableItems AS TableExciseCategories
	|		ON InventoryKinds.ItemsLocationAttributes.Products = TableExciseCategories.Products
	|
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|	AND TableExciseCategories.ExcisableGoodsCategory <> VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)
	|;
	|SELECT
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.InventoryOwnerAttribute.BusinessUnitProduction AS BusinessUnitProduction,
	|	InventoryKinds.ItemsLocationAttributes.Products AS Products,
	|	TableExciseCategories.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	InventoryKinds.Count AS Count,
	|	InventoryKinds.ExciseTaxAmount AS ExciseAmountInCurrencyLocal,
	|	CAST(InventoryKinds.ExciseTaxAmount * &ConversionRatioFromLocalToMan
	|		AS NUMBER(31,2)) AS ExciseAmountInCurrencyMgmt,
	|	CASE WHEN InventoryKinds.InventoryOwnerAttribute.SubjectToExcise
	|		THEN TableExciseCategories.ConversionFactor_ * InventoryKinds.Count
	|		ELSE 0
	|	END AS QuantityInExcisableCategoryUOM,
	|	InventoryKinds.CostDefiningMethod,
	|	InventoryKinds.RowID AS RowID
	|INTO TTTableTypesOfInventoryRegistration
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS InventoryKinds
	|
	|	INNER JOIN TTCategoriesOfExcisableItems AS TableExciseCategories
	|		ON InventoryKinds.ItemsLocationAttributes.Products = TableExciseCategories.Products
	|
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|	AND TableExciseCategories.ExcisableGoodsCategory <> VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)
	|;
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.BusinessUnitProduction AS ExcisePaymentBusinessUnit,
	|	&LineOfBusiness AS LineOfBusiness,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	VALUE(Enum.KindsOfTransactionsWithExcisableGoods.SaleOfGoodsAndServices) AS KindOfTransactionWithExcisableGoods,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityInExcisableCategoryUOM AS QuantityInExcisableCategoryUOM,
	|	TableTypesOfStocks_.ExciseAmountInCurrencyLocal AS ExciseAmountInCurrencyLocal,
	|	TableTypesOfStocks_.ExciseAmountInCurrencyMgmt AS ExciseAmountInCurrencyMgmt,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTTableTypesOfInventoryWriteOff AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.ExciseAmountInCurrencyLocal <> 0
	|		OR TableTypesOfStocks_.ExciseAmountInCurrencyMgmt <> 0
	|		OR TableTypesOfStocks_.QuantityInExcisableCategoryUOM <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.BusinessUnitProduction AS ExcisePaymentBusinessUnit,
	|	&LineOfBusiness AS LineOfBusiness,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	VALUE(Enum.KindsOfTransactionsWithExcisableGoods.SaleOfGoodsAndServices) AS KindOfTransactionWithExcisableGoods,
	|	-TableTypesOfStocks_.Count AS Count,
	|	-TableTypesOfStocks_.QuantityInExcisableCategoryUOM AS QuantityInExcisableCategoryUOM,
	|	-TableTypesOfStocks_.ExciseAmountInCurrencyLocal AS ExciseAmountInCurrencyLocal,
	|	-TableTypesOfStocks_.ExciseAmountInCurrencyMgmt AS ExciseAmountInCurrencyMgmt,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod IN (
	|				VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|				VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AdjustBeforeEnteringBalance)
	|		ELSE &BusinessTransactionSetting
	|	END AS BusinessTransactionSetting
	|FROM
	|	TTTableTypesOfInventoryRegistration AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.ExciseAmountInCurrencyLocal <> 0
	|		OR TableTypesOfStocks_.ExciseAmountInCurrencyMgmt <> 0
	|		OR TableTypesOfStocks_.QuantityInExcisableCategoryUOM <> 0
	|";
	
	If ValueIsFilled(Attributes.DateOfTransferOfTitleToGoods) Then
		Query.SetParameter("SalePeriod", Attributes.DateOfTransferOfTitleToGoods);
	Else
		Query.SetParameter("SalePeriod", Attributes.ShipmentPeriod);
	EndIf;
	
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Attributes.Organization);
	
	RatePeriod = Query.Parameters.SalePeriod;
	
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	LocalAccountingCurrency =
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Query.Parameters.Organization);
	
	ConversionRatioFromLocalToMan = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		LocalAccountingCurrency, ManagementAccountingCurrency, RatePeriod, LocalAccountingCurrency);
	
	Query.Text = QueryText;
	
	Query.SetParameter("RegistrationCountry", RegistrationCountry);
	Query.SetParameter("ConversionRatioFromLocalToMan", ConversionRatioFromLocalToMan);
	
	Return Query.Execute();
	
EndFunction

#EndRegion
#Region InterfaceImplementation

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

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Add("BusinessOperation");
	Fields.Add("Date");
	Fields.Add("Number");
	Fields.Add("AdjustingEntryType");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	DocumentNamePostfix = NStr("vi = 'Điều chỉnh bán hàng';
								|ru = 'Корректировка реализации';
								|en = 'Sales adjustment'; fa = 'تعدیل فروش';
								|it = 'Rettifica vendita';
								|pl = 'Korekta realizacji';
								|tr = 'Satış düzeltmesi'");
	
	If Data.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices
		Or Data.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets Then
		DocumentNamePostfix = NStr("vi = 'Điều chỉnh bán hàng trước khi nhập số dư';
									|ru = 'Корректировка реализации до ввода остатков';
									|en = 'Sales adjustment before balance entry'; fa = 'تعدیل فروش قبل از ورود مانده';
									|it = 'Correzione di vendita prima dell''inserimento dei saldi';
									|pl = 'Korekta sprzedaży przed wprowadzeniem sald';
									|tr = 'Bakiyeleri girmeden önce satış düzeltmesi'");
	ElsIf Data.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
		Or Data.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
		Or Data.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
		Or Data.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		Or Data.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
		DocumentNamePostfix = NStr("vi = 'Điều chỉnh bảng kê dành cho bên thuê gia công';
									|ru = 'Корректировка отчета давальцу';
									|en = 'Adjust ""Consumption report — Subcontracting services delivered""'; fa = 'Adjust ""Consumption report — Subcontracting services delivered""';
									|it = 'Rettifica del report al datore';
									|pl = 'Korekta raportu do właściciela surowców';
									|tr = 'Tüketim raporu-Verilen fason hizmetlerini düzeltme'");
	EndIf;
	
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 %2 ngày %3';
																				|ru = '%1 %2 от %3';
																				|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
																				|it = '%1 %2 del %3';
																				|pl = '%1 %2 z dnia %3';
																				|tr = '%3 tarihli %1 %2'"),
		DocumentNamePostfix,
		Data.Number,
		Data.Date);
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ObjectForm" Then
		If Parameters.Property("Key") And ValueIsFilled(Parameters.Key)
			And (Parameters.Key.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices
				Or Parameters.Key.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets) Then
			StandardProcessing = False;
			SelectedForm = "DocumentFormBeforeBalanceEntry";
		ElsIf Parameters.Property("FillingValues")
			And Parameters.FillingValues.BusinessOperation = Enums.BusinessTransactions.AdjustBeforeEnteringBalance Then
			StandardProcessing = False;
			SelectedForm = "DocumentFormBeforeBalanceEntry";
		ElsIf Parameters.Property("CopyingValue")
			And (Parameters.CopyingValue.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices
				Or Parameters.CopyingValue.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets) Then
			StandardProcessing = False;
			SelectedForm = "DocumentFormBeforeBalanceEntry";
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.SaleAdjustment";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",        """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	RedefiningParameterCalculation.Insert("BusinessTransactionGrounds",
		"	CASE
		|		WHEN DocumentData.AdjustingEntryType IN
		|				(VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
		|				VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets))
		|			THEN VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|		WHEN VALUETYPE(ISNULL(DocumentData.DocumentBasis, UNDEFINED)) = TYPE(Document.CustomerInvoiceServices)
		|			THEN VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|		ELSE
		|			ISNULL(DocumentData.DocumentBasis.BusinessOperation, VALUE(Enum.BusinessTransactions.EmptyRef))
		|	END");
	RedefiningParameterCalculation.Insert("ThisIsAdjustmentToSaleOfServicesOfOtherAssets",
		"	CASE
		|		WHEN DocumentData.DocumentBasis REFS Document.CustomerInvoiceServicesAndAssets
		|				OR DocumentData.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
		|			THEN TRUE
		|		ELSE FALSE
		|	END");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "GoodsBatchMovement" Then
		
		QueryText = QueryTextTableGoodsBatchMovement(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "SeriesTable";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
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

Function QueryTextDocumentDataHeader()
	
	Return "SELECT
		|	DocumentData.Ref                                      AS Ref,
		|	DocumentData.Date                                        AS Period,
		|	DocumentData.DocumentBasis                           AS DocumentBasis,
		|	ISNULL(DocumentData.DocumentBasis.FinancialAccountingGroup, DocumentData.FinancialAccountingGroup)AS FinancialAccountingGroup,
		|	ISNULL(DocumentData.DocumentBasis.Date, DocumentData.Date) AS ShipmentPeriod,
		|	ISNULL(DocumentData.DocumentBasis.Date, DocumentData.Date) AS AdjustmentPeriod_,
		|	ISNULL(DocumentData.DocumentBasis.Date, DocumentData.Date) AS VATBasePeriod,
		|	CASE
		|		WHEN DocumentData.AdjustingEntryType IN
		|				(VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
		|				VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets))
		|			THEN ISNULL(DocumentData.DocumentBasis.Date, DocumentData.Date)
		|		ELSE ISNULL(DocumentData.DocumentBasis.DateOfTransferOfTitleToGoods,
		|						ISNULL(DocumentData.DocumentBasis.Date, DocumentData.Date))
		|	END                                                       AS DateOfTransferOfTitleToGoods,
		|	DocumentData.Organization                                 AS Organization,
		|	DocumentData.Organization.LocalAccountingCurrency  AS LocalAccountingCurrency,
		|	DocumentData.Partner                                     AS Partner,
		|	DocumentData.Counterparty                                  AS Counterparty,
		|	DocumentData.CustomerPartner                               AS CustomerPartner,
		|	DocumentData.CustomerCounterparty                            AS CustomerCounterparty,
		|	DocumentData.CustomerContract                               AS CustomerContract,
		|	DocumentData.Department                               AS Department,
		|	DocumentData.BusinessUnit                         AS BusinessUnit,
		|	DocumentData.BusinessUnitExpenses                        AS BusinessUnitExpenses,
		|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods, VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
		|	DocumentData.ExpenseItem                              AS ExpenseItem,
		|	ISNULL(DocumentData.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) AS CostAllocationOptionLocal,
		|	ISNULL(DocumentData.ExpenseItem.SeparateVATAccountingOption, VALUE(Enum.SeparateVATAccountingOptions.EmptyRef)) AS SeparateVATAccountingOption,
		|	DocumentData.DimensionOfExpenses                           AS DimensionOfExpenses,
		|	DocumentData.IncomeItem                               AS IncomeItem,
		|	DocumentData.DimensionOfRevenue                            AS DimensionOfRevenue,
		|	DocumentData.ARAPCurrency                        AS ARAPCurrency,
		|	DocumentData.Currency                                      AS Currency,
		|	DocumentData.CorrectedDocument                        AS CorrectedDocument,
		|	DocumentData.SaleByOrders                            AS SaleByOrders,
		|	DocumentData.VATTaxation                          AS VATTaxation,
		|	ISNULL(DocumentData.DocumentBasis.VATTaxation, VALUE(Enum.VATTaxationTypes.EmptyRef)) AS BasisVATTaxation,
		|	DocumentData.PaymentDate                                 AS PaymentDate,
		|	DocumentData.PaymentMethod                                 AS PaymentMethod,
		|	DocumentData.Terms                                  AS Terms,
		|	DocumentData.Contract                                     AS Contract,
		|	ISNULL(DocumentData.Contract.ConductARAPAccountingThroughEndCustomers, FALSE) AS ConductARAPAccountingThroughEndCustomers,
		|	DocumentData.AdjustingEntryType                            AS AdjustingEntryType,
		|	DocumentData.AdjustmentKind                            AS AdjustmentKind,
		|	CASE
		|		WHEN DocumentData.DocumentBasis REFS Document.CustomerInvoiceServicesAndAssets
		|				OR DocumentData.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                                       AS ThisIsAdjustmentToSaleOfServicesOfOtherAssets,
		|	CASE
		|		WHEN DocumentData.AdjustingEntryType IN
		|				(VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
		|				VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets))
		|			THEN VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|		WHEN VALUETYPE(ISNULL(DocumentData.DocumentBasis, UNDEFINED)) = TYPE(Document.CustomerInvoiceServices)
		|			THEN VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|		ELSE
		|			ISNULL(DocumentData.DocumentBasis.BusinessOperation, VALUE(Enum.BusinessTransactions.EmptyRef))
		|	END                                                       AS BusinessTransactionGrounds,
		|	DocumentData.Manager                                    AS Manager,
		|	DocumentData.SalesOpportunity 										AS SalesOpportunity,
		|	ISNULL(DocumentData.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
		|	CASE
		|		WHEN DocumentData.AdjustingEntryType IN
		|				(VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
		|				VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets))
		|			THEN VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|		ELSE ISNULL(DocumentData.DocumentBasis.OrderSales, FALSE)
		|	END                                                       AS OrderSales,
		|	CASE
		|		WHEN DocumentData.DocumentBasis REFS Document.CustomerInvoice
		|			THEN DocumentData.DocumentBasis.ToReturnReusablePackage
		|		ELSE FALSE
		|	END                                                       AS ToReturnReusablePackage,
		|	CASE
		|		WHEN DocumentData.DocumentBasis REFS Document.CustomerInvoice
		|			THEN DocumentData.DocumentBasis.PackageDepositIsRequired
		|		ELSE FALSE
		|	END                                                       AS PackageDepositIsRequired,
		|	CASE
		|		WHEN DocumentData.AdjustingEntryType IN
		|				(VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
		|				VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets))
		|			THEN FALSE
		|		WHEN DocumentData.DocumentBasis.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS AdjustmentOfShipmentWithoutTransferOfOwnership,
		|	CASE
		|		WHEN DocumentData.AdjustingEntryType IN
		|				(VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
		|				VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets))
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer)
		|		WHEN DocumentData.DocumentBasis.BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.SalesViaCommissionAgent)
		|		WHEN DocumentData.DocumentBasis.BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.SalesViaCommissionAgentGoodsInTransit)
		|		WHEN DocumentData.DocumentBasis.BusinessOperation = VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReportToMaterialProvider2_5)
		|		WHEN DocumentData.DocumentBasis.BusinessOperation = VALUE(Enum.BusinessTransactions.Subcontracting2_5)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.Subcontracting2_5)
		|		WHEN DocumentData.DocumentBasis.BusinessOperation = VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.RepairProductsFromProvidedMaterials2_5)
		|		WHEN DocumentData.DocumentBasis.BusinessOperation = VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.PerformWorksUsingProvidedMaterials2_5)
		|		WHEN DocumentData.DocumentBasis.BusinessOperation = VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.PerformRMUsingProvidedMaterials2_5)
		|		ELSE VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer)
		|	END                                  AS BusinessTransactionSetting,
		|	ISNULL(DocumentData.DocumentBasis.LineOfBusiness, DocumentData.LineOfBusiness) AS LineOfBusiness,
		|	DocumentData.Number                  AS Number,
		|	DocumentData.Warehouse                  AS Warehouse,
		|	DocumentData.DocumentAmount         AS DocumentAmount,
		|	DocumentData.Comment            AS Comment,
		|	DocumentData.DeletionMark        AS DeletionMark,
		|	DocumentData.Author                  AS Author,
		|	DocumentData.BusinessOperation  AS BusinessOperation,
		|	DocumentData.Posted               AS Posted,
		|	CASE
		|		WHEN DocumentData.VATTaxation IN (&TaxationWithoutVAT)
		|			AND DocumentData.AdjustingEntryType IN (VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
		|													VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets))
		|			THEN TRUE
		|		ELSE FALSE
		|	END AdjustmentBeforeEnteringBalancesWithoutVAT,
		|	DocumentData.AdjustTaxBaseOfPreviousPeriod AS AdjustTaxBaseOfPreviousPeriod,
		|	DocumentData.RecordInProfitLossOfPreviousYears AS RecordInProfitLossOfPreviousYears,
		|	DocumentData.SaleAdjustment2_5 AS SaleAdjustment2_5
		|INTO DocumentDataHeader
		|FROM
		|	Document.SaleAdjustment AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref
		|";
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.SetParameter("TaxationWithoutVAT", VATAccountingERPClientServer.TypesOfTaxationThatHideVATDetails()); 
	Query.Text = StrReplace(QueryTextDocumentDataHeader(), "INTO DocumentDataHeader", "");
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	If ValueIsFilled(Attributes.DateOfTransferOfTitleToGoods) Then
		Query.SetParameter("SalePeriod", Attributes.DateOfTransferOfTitleToGoods);
	Else
		Query.SetParameter("SalePeriod", Attributes.ShipmentPeriod);
	EndIf;
	
	Query.SetParameter("UseAccountingOfOtherIncomeExpenses", GetFunctionalOption("UseAccountingOfOtherIncomeExpenses")); 
	Query.SetParameter("LocalAccountingCurrency", Attributes.LocalAccountingCurrency);
	Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("SalesViaCommissionAgent", ConsignmentSalesServer.SalesViaCommissionAgent(Attributes.BusinessTransactionGrounds));
	Query.SetParameter("ReturnOfGoodsViaCommissionAgent", ConsignmentSalesServer.SalesViaCommissionAgent(Attributes.BusinessTransactionGrounds));
	
	LastPeriodAdjustment = False;
	CurPeriodAdjustment = False;
	If ValueIsFilled(Attributes.ShipmentPeriod) Then
		If Attributes.ShipmentPeriod < BegOfMonth(Attributes.Period) Then
			LastPeriodAdjustment = True;
		Else
			CurPeriodAdjustment = True;
		EndIf;
	EndIf;
	Query.SetParameter("LastPeriodAdjustment", LastPeriodAdjustment);
	Query.SetParameter("CurPeriodAdjustment", CurPeriodAdjustment);

	AdjustmentOfPreviousPeriodYear = False;
	If ValueIsFilled(Attributes.AdjustmentPeriod_) Then 
		If BegOfYear(Attributes.AdjustmentPeriod_) < BegOfYear(Attributes.Period) Then
			AdjustmentOfPreviousPeriodYear = True;
		EndIf;
	EndIf;
	Query.SetParameter("AdjustmentOfPreviousPeriodYear", AdjustmentOfPreviousPeriodYear);
	Query.SetParameter("UseAgentServiceSale", GetFunctionalOption("UseAgentServiceSale"));
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	Query.SetParameter("ContractInformation",             ContractInformation);
	Query.SetParameter("MetadataIdentifier",          Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("NumberForPrinting",                    ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("DisplayBasicUnitsOfMeasureInPrintForms",  Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get());
	Query.SetParameter("ListOfTypesWithUnitAnalytics", SalesServer.TypesOfNomenclatureWithUnitAnalytics());
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	Query.SetParameter("CurrentDate",                      CurrentUniversalDate());
		
	DocumentTimePoint = DocumentRef.PointInTime(); 
	Query.SetParameter("DocumentTimePoint", DocumentTimePoint);
	Query.SetParameter("BorderExcludingDocument", New Boundary(DocumentTimePoint, BoundaryType.Excluding));	
	
	Query.SetParameter("TypesOfVATTaxationNonTaxable", VATAccountingERP.TypesOfVATTaxationNonTaxable());
	
	VATAccountingERP.SetParametersForVATRateRequest(Query.Parameters, Query.Parameters.Organization, Query.Parameters.Period);
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
	UseExcisableGoods = False;
	RegistrationCountry = Catalogs.WorldCountries.EmptyRef();
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Attributes.Organization);
	Query.SetParameter("UseExcisableGoods", UseExcisableGoods);
	Query.SetParameter("RegistrationCountry", RegistrationCountry);
	
EndProcedure

Procedure IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
	"SELECT
	|	DivergenceTable.Ref              AS Ref,
	|	DivergenceTable.Ref.Date         AS Date,
	|	DivergenceTable.Warehouse               AS Warehouse,
	|	DivergenceTable.Products        AS Products,
	|	DivergenceTable.Characteristic      AS Characteristic,
	|	DivergenceTable.Purpose          AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	CASE
	|		WHEN DivergenceTable.BatchesIndicationStatusInWarehouses = 0
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE DivergenceTable.Series
	|	END                                  AS Series,
	|	-DivergenceTable.Count         AS Count,
	|	DivergenceTable.BatchesIndicationStatusInWarehouses AS BatchesIndicationStatus
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS DivergenceTable
	|WHERE
	|	DivergenceTable.Ref IN(&Ref)
	|	AND DivergenceTable.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND DivergenceTable.PostingOption IN (
	|		VALUE(Enum.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount),
	|		VALUE(Enum.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount))
	|	";
	
	RegistersOfGoodsForRegistrationOfSurplusShortages = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("GoodsForRegistrationOfSurplusesAndShortages", Registers) Then
		RegistersOfGoodsForRegistrationOfSurplusShortages.Insert("GoodsForRegistrationOfSurplusesAndShortages");
	Else
		RegistersOfGoodsForRegistrationOfSurplusShortages.Insert("NoRegisteredRecordsRequired");
	EndIf;
	
	WarehousesServer.IssueSurplusShortagesInWarehouse(Query,
		QueryTexts,
		RegistersOfGoodsForRegistrationOfSurplusShortages,
		QueryTextDocument_);
	
	QueryTextDocument_ =
	"SELECT
	|	DivergenceTable.Ref              AS Ref,
	|	DivergenceTable.Ref.Date         AS Date,
	|	DivergenceTable.Warehouse               AS Warehouse,
	|	DivergenceTable.Products        AS Products,
	|	DivergenceTable.Characteristic      AS Characteristic,
	|	DivergenceTable.Purpose          AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DivergenceTable.Series               AS Series,
	|	-DivergenceTable.Count         AS Count,
	|	DivergenceTable.BatchesIndicationStatusInWarehouses AS BatchesIndicationStatus
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS DivergenceTable
	|WHERE
	|	DivergenceTable.Ref IN(&Ref)
	|	AND DivergenceTable.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND DivergenceTable.PostingOption IN (
	|		VALUE(Enum.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock),
	|		VALUE(Enum.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock))
	|	";
	
	RegistersOfGoodsInWarehouses = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("ProductStock", Registers) Then
		RegistersOfGoodsInWarehouses.Insert("ProductStock");
	Else
		RegistersOfGoodsInWarehouses.Insert("NoRegisteredRecordsRequired");
	EndIf;
	
	WarehousesServer.IssueSurplusShortagesInWarehouse(Query,
		QueryTexts,
		RegistersOfGoodsInWarehouses,
		QueryTextDocument_);
	
EndProcedure

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query("
	|SELECT DISTINCT
	|	Table.Products         AS Products,
	|	Table.Characteristic       AS Characteristic,
	|	Table.Purpose           AS Purpose,
	|	Table.Series                AS Series,
	|	Table.Warehouse                AS Warehouse
	|FROM
	|	(
	|		SELECT
	|			Goods.ItemsLocationAttributes.Products         AS Products,
	|			Goods.ItemsLocationAttributes.Characteristic       AS Characteristic,
	|			&EmptyAssignment          AS Purpose,
	|			Goods.ItemsLocationAttributes.Series                AS Series,
	|			CASE
	|				WHEN &SalesViaCommissionAgent
	|					THEN &Contract
	|					ELSE Goods.ItemsLocationAttributes.StorageLocation
	|			END                                                  AS Warehouse
	|		FROM
	|			Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS Goods
	|		WHERE
	|			Goods.Ref = &Ref
	|			AND NOT &KeepRecordsOfInventoryCostByAssignments
	|			AND NOT &ThisIsAdjustmentToSaleOfServicesOfOtherAssets
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Goods.ItemsLocationAttributes.Products         AS Products,
	|			Goods.ItemsLocationAttributes.Characteristic       AS Characteristic,
	|			&EmptyAssignment          AS Purpose,
	|			Goods.ItemsLocationAttributes.Series                AS Series,
	|			Goods.ItemsLocationAttributes.StorageLocation        AS Warehouse
	|		FROM
	|			Document.SaleAdjustment.Discrepancies AS Goods
	|
	|			INNER JOIN Catalog.Products AS ProductData_1
	|				ON Goods.Products = ProductData_1.Ref
	|
	|		WHERE
	|			Goods.Ref = &Ref
	|			AND Goods.Products.ItemsType IN(
	|				VALUE(Enum.ItemsTypes.OperationService),
	|				VALUE(Enum.ItemsTypes.Work_5))
	|			AND NOT (ProductData_1.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|				AND ProductData_1.TracedGoods
	|				AND &UseTraceableImportedGoodsAccounting)
	|			AND NOT &KeepRecordsOfInventoryCostByAssignments
	|			AND NOT &ThisIsAdjustmentToSaleOfServicesOfOtherAssets
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Goods.ItemsLocationAttributes.Products         AS Products,
	|			Goods.ItemsLocationAttributes.Characteristic       AS Characteristic,
	|			&EmptyAssignment          AS Purpose,
	|			Goods.ItemsLocationAttributes.Series                AS Series,
	|			CASE
	|				WHEN &SalesViaCommissionAgent
	|					THEN &Contract
	|					ELSE Goods.ItemsLocationAttributes.StorageLocation
	|			END                                                  AS Warehouse
	|		FROM
	|			Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS Goods
	|		WHERE
	|			Goods.Ref = &Ref
	|			AND NOT &KeepRecordsOfInventoryCostByAssignments
	|			AND NOT &ThisIsAdjustmentToSaleOfServicesOfOtherAssets
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Goods.ItemsLocationAttributes.Products         AS Products,
	|			Goods.ItemsLocationAttributes.Characteristic       AS Characteristic,
	|			&EmptyAssignment          AS Purpose,
	|			Goods.ItemsLocationAttributes.Series                AS Series,
	|			Goods.OriginWarehouse       AS Warehouse
	|		FROM
	|			Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS Goods
	|		WHERE
	|			Goods.Ref = &Ref
	|			AND NOT &KeepRecordsOfInventoryCostByAssignments
	|			AND NOT &ThisIsAdjustmentToSaleOfServicesOfOtherAssets
	|			AND NOT &SalesViaCommissionAgent
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Goods.ItemsLocationAttributes.Products         AS Products,
	|			Goods.ItemsLocationAttributes.Characteristic       AS Characteristic,
	|			Goods.ItemsLocationAttributes.Purpose           AS Purpose,
	|			VALUE(Catalog.ItemsBatches.EmptyRef)    AS Series,
	|			Goods.InventoryOwnerAttribute.GoodsOwner AS Warehouse
	|		FROM
	|			Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS Goods
	|		WHERE
	|			Goods.Ref = &Ref
	|			AND Goods.InventoryOwnerAttribute.GoodsOwner <> UNDEFINED
	|			AND NOT &ThisIsAdjustmentToSaleOfServicesOfOtherAssets
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Goods.ItemsLocationAttributes.Products         AS Products,
	|			Goods.ItemsLocationAttributes.Characteristic       AS Characteristic,
	|			&EmptyAssignment          AS Purpose,
	|			Goods.ItemsLocationAttributes.Series                AS Series,
	|			CASE
	|				WHEN &SalesViaCommissionAgent
	|					THEN &Contract
	|					ELSE Goods.ItemsLocationAttributes.StorageLocation
	|			END                                                  AS Warehouse
	|		FROM
	|			Document.SaleAdjustment.InventoryOwnerAttributesRevenueAdjustment AS Goods
	|		WHERE
	|			Goods.Ref = &Ref
	|			AND NOT &KeepRecordsOfInventoryCostByAssignments
	|			AND NOT &ThisIsAdjustmentToSaleOfServicesOfOtherAssets
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Keys.Products               AS Products,
	|			Keys.Characteristic             AS Characteristic,
	|			&EmptyAssignment                AS Purpose,
	|			&Series                           AS Series,
	|			Goods.InventoryOwnerAttribute.GoodsOwner AS Warehouse
	|		FROM
	|			Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS Goods
	|				LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|				ON Goods.ItemsLocationAttributes = Keys.Ref
	|			
	|				LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|				ON Keys.Products                  = Dimension.Products
	|					AND Keys.Characteristic             = Dimension.Characteristic
	|					AND &Series                           = Dimension.Series
	|					AND Goods.InventoryOwnerAttribute.GoodsOwner = Dimension.StorageLocation
	|					AND &EmptyAssignment                = Dimension.Purpose
	|					AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			Goods.Ref = &Ref
	|			AND Dimension.Products IS NULL
	|			AND Goods.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	
	|	) AS Table
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON Table.Products = Dimension.Products
	|			AND Table.Characteristic = Dimension.Characteristic
	|			AND Table.Series = Dimension.Series
	|			AND Table.Warehouse = Dimension.StorageLocation
	|			AND Table.Purpose = Dimension.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	Dimension.DimensionKey IS NULL
	|");
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Series", Catalogs.ItemsBatches.EmptyRef());
	QueryAnalyst.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments",
										Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	QueryAnalyst.SetParameter("ThisIsAdjustmentToSaleOfServicesOfOtherAssets",
										Query.Parameters.ThisIsAdjustmentToSaleOfServicesOfOtherAssets);
	QueryAnalyst.SetParameter("SalesViaCommissionAgent",
										Query.Parameters.SalesViaCommissionAgent);
	QueryAnalyst.SetParameter("Contract", Query.Parameters.Contract);
										
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(QueryAnalyst);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Procedure SetRequestParameterVATTaxTypesTaxable(Query) Export
	
	If Query.Parameters.Property("TypesOfVATTaxable") Then
		Return;
	EndIf;

	Query.SetParameter("TypesOfVATTaxable", VATAccountingERP.TypesOfActivitiesVATIsAcceptedForReimbursement());
	
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query) Export
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.Currency,
																				Query.Parameters.ARAPCurrency,
																				Query.Parameters.SalePeriod,
																				Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",           Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul",          Coefficients.FactorOfConversionToCurrencyOfRegul);
	RatePeriod = Query.Parameters.SalePeriod;
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	LocalAccountingCurrency =
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Query.Parameters.Organization);

	ConversionRatioFromLocalToMan = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		LocalAccountingCurrency, ManagementAccountingCurrency, RatePeriod, LocalAccountingCurrency);
	
	Query.SetParameter("ConversionRatioFromLocalToMan", ConversionRatioFromLocalToMan);
EndProcedure

Procedure SetParametersForPartnerAccountingAnalystRequest(Query)
	
	If Query.Parameters.Property("AccountingDimensionByPartners") Then
		Return;
	EndIf;
	
	If ConsignmentSalesServer.SalesViaCommissionAgent(Query.Parameters.BusinessTransactionGrounds) Then
		StructureOfAnalytics = New Structure();
		StructureOfAnalytics.Insert("Organization", Query.Parameters.Organization);
		StructureOfAnalytics.Insert("Contract", Query.Parameters.CustomerContract);
		StructureOfAnalytics.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);
		If Common.ObjectAttributeValue(Query.Parameters.Contract, "ConductARAPAccountingThroughEndCustomers") Then
			StructureOfAnalytics.Insert("Partner", Query.Parameters.CustomerPartner);
			StructureOfAnalytics.Insert("Counterparty", Query.Parameters.CustomerCounterparty);
		Else
			StructureOfAnalytics.Insert("Partner", Query.Parameters.Partner);
			StructureOfAnalytics.Insert("Counterparty", Query.Parameters.Counterparty);
		EndIf;
		AccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureOfAnalytics);
	Else
		AccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(Query.Parameters);
	EndIf;
	
	Query.SetParameter("AccountingDimensionByPartners", AccountingDimensionByPartners);

EndProcedure

Function QueryTextTTTableTypesOfInventoryWriteOff(Query, QueryTexts) Export
	
	RegisterName = "TTTableTypesOfInventoryWriteOff";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	InitializeProductAccountingAnalyticsKeys(Query);
	SetRequestParametersCurrencyCoefficients(Query);
	QueryText = " 
	|SELECT
	|	InventoryKinds.LineNumber                  AS LineNumber,
	|	InventoryKinds.ItemsLocationAttributes.Products                   AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Products.ItemsType   AS ItemsType,
	|	ISNULL(InventoryKinds.FEACNCode.Commodity,FALSE) AS Commodity,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic                 AS Characteristic,
	|	InventoryKinds.InventoryOwnerAttribute                   AS InventoryOwnerAttribute,
	|	InventoryKinds.CorInventoryOwnerAttribute                AS CorInventoryOwnerAttribute,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryType        AS InventoryType,
	|	InventoryKinds.InventoryOwnerAttribute.Currency            AS Currency,
	|	InventoryKinds.CCDNumber                     AS CCDNumber,
	|	InventoryKinds.Count                   AS Count,
	|	InventoryKinds.QuantityByGBRN             AS QuantityByGBRN,
	|	InventoryKinds.AmountIncludingVAT                    AS AmountIncludingVAT,
	|	InventoryKinds.VATAmount                     AS VATAmount,
	|	InventoryKinds.ExciseTaxAmount                  AS ExciseAmountInCurrencyLocal,
	|	CAST(InventoryKinds.ExciseTaxAmount * &ConversionRatioFromLocalToMan
	|		AS NUMBER(31,2))                     AS ExciseAmountInCurrencyMgmt,
	|	InventoryKinds.VATAmountCompl AS VATAmountCompl,
	|	InventoryKinds.VATAmountMan AS VATAmountMan,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)          AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)         AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)        AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)       AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)          AS VATLocal,
	|	ISNULL(Amounts.VATAmountMan, 0)           AS VATManag,
	|
	|	InventoryKinds.AmountARAP AS AmountARAP,
	|	CASE WHEN InventoryKinds.AmountIncludingVAT <> 0 THEN
	|		CAST(InventoryKinds.AmountARAP * InventoryKinds.VATAmount / InventoryKinds.AmountIncludingVAT AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END AS AmountVATARAP,
	|
	|	InventoryKinds.Warehouse                        AS Warehouse,
	|	InventoryKinds.Warehouse.ShopFloorStockroom        AS ShopFloorStockroom,
	|	InventoryKinds.SalesOrder                 AS SalesOrder,
	|	InventoryKinds.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey     AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	InventoryKinds.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	InventoryKinds.SetAccountingDimension        AS SetAccountingDimension,
	|	InventoryKinds.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner           AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization          AS OwnerSInventoryOwnersAttributesOfOwnerCompany,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType           AS OwnerSInventoryOwnersAttributeTypeOfInventory,
	|	CommitteeKeys.DimensionKey             AS CommitteeAnalytics,
	|	InventoryKinds.ToIncomeExpenses			 	 AS ToIncomeExpenses,
	|	InventoryKinds.ToExpenseAs             AS ToExpenseAs,
	|	InventoryKinds.ExpenseItem               AS ExpenseItemWriteOff,
	|	InventoryKinds.DimensionOfExpenses            AS ExpenseAnalyticsWriteOff,
	|	InventoryKinds.RowID          AS RowID,
	|	InventoryKinds.VATRate                    AS VATRate,
	|
	|	(CASE
	|		WHEN &GenerateInventoryOwnerAttributesBySalesOpportunities AND &EnabledGoodsAssignmentInSalesOpportunity
	|			THEN &SalesOpportunity
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|			THEN &Manager
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END) AS FinancialAccountingDimension,
	|	(CASE
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|			CASE InventoryKinds.VATRate
	|			WHEN &ExportVATRate THEN 
	|				CASE WHEN ISNULL(InventoryKinds.FEACNCode.Commodity,FALSE)
	|					THEN VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|					ELSE VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
	|				END
	|			WHEN VALUE(Catalog.VATRates.EXCLUDINGVAT) THEN
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			ELSE
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			END
	|		WHEN InventoryKinds.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		 AND &VATTaxation IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT), 
	|				VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle))
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END) AS VATActivityType,
	|	InventoryKinds.ARAPObject AS ARAPObject,
	|	InventoryKinds.Ref.Organization AS Organization,
	|	ISNULL(CCDNumbers.CCDNumberType, VALUE(Enum.CCDNumberTypes.EmptyRef)) AS CCDNumberType,
	|	CASE
	|		WHEN InventoryKinds.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND InventoryKinds.ItemsLocationAttributes.Products.TracedGoods 
	|			AND &UseTraceableImportedGoodsAccounting
	|			THEN TRUE
	|		ELSE FALSE
	|	END ThisIsTraceableWork	
	|
	|INTO TTTableTypesOfInventoryWriteOff
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS InventoryKinds
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON
	|		InventoryKinds.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND InventoryKinds.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND InventoryKinds.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND InventoryKinds.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|	
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS CommitteeKeys
	|	ON
	|		InventoryKinds.ItemsLocationAttributes.Products = CommitteeKeys.Products
	|		AND InventoryKinds.ItemsLocationAttributes.Characteristic = CommitteeKeys.Characteristic
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeKeys.Series
	|		AND VALUE(Catalog.Assignments.EmptyRef) = CommitteeKeys.Purpose
	|		AND InventoryKinds.InventoryOwnerAttribute.GoodsOwner = CommitteeKeys.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeKeys.ProductCostElement
	|
	|	LEFT JOIN
	|		Catalog.CCDNumbers AS CCDNumbers
	|	ON
	|		InventoryKinds.CCDNumber  = CCDNumbers.Ref
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		Amounts.Ref = InventoryKinds.Ref
	|		AND Amounts.RowID = InventoryKinds.RowID
	|
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|
	|INDEX BY
	|	CCDNumberType";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDivergenceTable(Query, QueryTexts)
	
	RegisterName = "TTDivergenceTable";
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 

	QueryText = " 
	|SELECT
	|	Discrepancies.LineNumber  AS LineNumber,
	|	Discrepancies.Products AS Products,
	|	Discrepancies.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)         AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)        AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)       AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)      AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)         AS VATLocal,
	|	ISNULL(Amounts.VATAmountMan, 0)          AS VATManag,
	|
	|	CASE WHEN Discrepancies.PostingOption = VALUE(Enum.CreditNoteRecordingOptions.ToExpenseAs)
	|			OR Discrepancies.PostingOption = VALUE(Enum.CreditNoteRecordingOptions.ReduceSaleWriteOffForExpenses)
	|			OR (&SaleAdjustment2_5 AND Discrepancies.AmountIncludingVAT < 0 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ToExpenses,
	|	CASE WHEN Discrepancies.PostingOption = VALUE(Enum.CreditNoteRecordingOptions.RecordInOtherIncome)
	|			OR &SaleAdjustment2_5 AND ((&ThisIsAdjustmentToSaleOfServicesOfOtherAssets AND NOT &RecordInProfitLossOfPreviousYears)
	|				OR(Discrepancies.AmountIncludingVAT > 0 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears))
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS OnIncome,
	|
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	Discrepancies.SalesOrder                 AS SalesOrder,
	|	Discrepancies.Count                   AS Count,
	|	Discrepancies.AmountIncludingVAT                    AS AmountIncludingVAT,
	|	Discrepancies.VATAmount                     AS VATAmount,
	|	Discrepancies.VATAmountCompl AS VATAmountCompl,
	|	Discrepancies.VATAmountMan AS VATAmountMan,
	|	Discrepancies.AmountARAP AS AmountARAP,
	|	CASE WHEN Discrepancies.AmountIncludingVAT <> 0 THEN
	|		CAST(Discrepancies.AmountARAP * Discrepancies.VATAmount / Discrepancies.AmountIncludingVAT AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END AS AmountVATARAP,
	|	Discrepancies.VATRate                    AS VATRate,
	|	Discrepancies.IncomeItem                AS IncomeItem,
	|	Discrepancies.DimensionOfRevenue             AS DimensionOfRevenue,
	|	Discrepancies.Ref                       AS Ref,
	|	Discrepancies.ARAPObject               AS ARAPObject,
	|	Discrepancies.RowID          AS RowID,
	|	CASE
	|		WHEN CatalogOfProductItem.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND CatalogOfProductItem.TracedGoods
	|			AND &UseTraceableImportedGoodsAccounting
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsTraceableWork
	|INTO TTDivergenceTable
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS Discrepancies
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber       = Discrepancies.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Discrepancies""
	|	
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		Amounts.Ref = Discrepancies.Ref
	|		AND Amounts.RowID = Discrepancies.RowID
	|
	|	LEFT JOIN
	|		Catalog.Products AS CatalogOfProductItem
	|		ON CatalogOfProductItem.Ref = Discrepancies.Products
	|
	|WHERE
	|	Discrepancies.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableDebtAdjustment(Query, QueryTexts)
	
	RegisterName = "TTTableDebtAdjustment";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	QueryText = " 
	|SELECT
	|	ARAPAdjustment.Ref AS Ref,
	|	ARAPAdjustment.LineNumber AS LineNumber,
	|	ARAPAdjustment.ARAPObject AS ARAPObject,
	|	ARAPAdjustment.VATRate AS VATRate,
	|	ARAPAdjustment.ARAPObject.Department AS SettlementDivision,
	|	ARAPAdjustment.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	ARAPAdjustment.ARAPObject.Contract AS Contract,
	|
	|	TRUE AS ToExpenses,
	|	FALSE AS OnIncome,
	|	
	|	ARAPAdjustment.Ref.Currency AS Currency,
	|	(ARAPAdjustment.AdjustmentSum - ARAPAdjustment.SumOfVATAdjustments) AS AmountExcludingVAT,
	|	(ARAPAdjustment.AdjustmentSum) AS AmountIncludingVAT,
	|	(ARAPAdjustment.SumOfVATAdjustments) AS VATAmount,
	|
	|	ARAPAdjustment.Ref.ARAPCurrency AS ARAPCurrency,
	|	ARAPAdjustment.AmountARAP  AS AmountARAP,
	|	CAST(ARAPAdjustment.AmountARAP 
	|		* ARAPAdjustment.SumOfVATAdjustments 
	|		/ ARAPAdjustment.AdjustmentSum AS NUMBER(31,2))  AS AmountVATARAP,
	|
	|	- ISNULL(Amounts.AmountIncludingVATMan, 0)       AS AmountIncludingVATMan,
	|	- ISNULL(Amounts.AmountExcludingVATMan, 0)     AS AmountExcludingVATMan,
	|	- ISNULL(Amounts.AmountIncludingVATCompl, 0)      AS AmountIncludingVATCompl,
	|	- ISNULL(Amounts.AmountExcludingVATCompl, 0)    AS AmountExcludingVATCompl,
	|	- ISNULL(Amounts.VATAmountCompl, 0)       AS VATLocal,
	|	- ISNULL(Amounts.VATAmountMan, 0)       AS VATManag,
	|
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	ARAPAdjustment.Ref.ExpenseItem AS ExpenseItem,
	|	ARAPAdjustment.Ref.DimensionOfExpenses AS DimensionOfExpenses,
	|	ARAPAdjustment.Ref.IncomeItem AS IncomeItem,
	|	ARAPAdjustment.Ref.DimensionOfRevenue AS DimensionOfRevenue,
	|	ARAPAdjustment.Ref.BusinessUnitExpenses AS Department,
	|	
	|	ARAPAdjustment.ARAPObject.UUID AS UniqueIDOfSettlementObject,
	|	ARAPAdjustment.RowID AS RowID
	|
	|INTO TTTableDebtAdjustment
	|FROM
	|	Document.SaleAdjustment.ARAPAdjustment AS ARAPAdjustment
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		Amounts.Ref = ARAPAdjustment.Ref
	|		AND Amounts.RowID = ARAPAdjustment.RowID
	|
	|	LEFT JOIN
	|		TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON 
	|		TableOfBatchAccountingAnalysts.LineNumber = ARAPAdjustment.LineNumber
	|		AND TableOfBatchAccountingAnalysts.TabularSectionName = ""ARAPAdjustment""
	|WHERE
	|	ARAPAdjustment.Ref = &Ref
	|	AND ARAPAdjustment.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated)
	|
	|UNION ALL
	|
	|SELECT
	|	ARAPAdjustment.Ref AS Ref,
	|	ARAPAdjustment.LineNumber AS LineNumber,
	|	ARAPAdjustment.ARAPObject AS ARAPObject,
	|	ARAPAdjustment.VATRate AS VATRate,
	|	ARAPAdjustment.ARAPObject.Department AS SettlementDivision,
	|	ARAPAdjustment.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	ARAPAdjustment.ARAPObject.Contract AS Contract,
	|
	|	FALSE AS ToExpenses,
	|	TRUE AS OnIncome,
	|	
	|	ARAPAdjustment.Ref.Currency AS Currency,
	|	ARAPAdjustment.AdjustmentSum - ARAPAdjustment.SumOfVATAdjustments AS AmountExcludingVAT,
	|	ARAPAdjustment.AdjustmentSum       AS AmountIncludingVAT,
	|	ARAPAdjustment.SumOfVATAdjustments    AS VATAmount,
	|
	|	ARAPAdjustment.Ref.ARAPCurrency AS ARAPCurrency,
	|	ARAPAdjustment.AmountARAP  AS AmountARAP,
	|	CAST(ARAPAdjustment.AmountARAP 
	|		* ARAPAdjustment.SumOfVATAdjustments 
	|		/ ARAPAdjustment.AdjustmentSum AS NUMBER(31,2))  AS AmountVATARAP,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0) AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0) AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0) AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0) AS VATLocal,
	|	ISNULL(Amounts.VATAmountMan, 0) AS VATManag,
	|
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	ARAPAdjustment.Ref.ExpenseItem AS ExpenseItem,
	|	ARAPAdjustment.Ref.DimensionOfExpenses AS DimensionOfExpenses,
	|	ARAPAdjustment.Ref.IncomeItem AS IncomeItem,
	|	ARAPAdjustment.Ref.DimensionOfRevenue AS DimensionOfRevenue,
	|	ARAPAdjustment.Ref.BusinessUnit AS Department,
	|	
	|	ARAPAdjustment.ARAPObject.UUID AS UniqueIdentifierOfCalculationObject,
	|	ARAPAdjustment.RowID AS RowID
	|
	|FROM
	|	Document.SaleAdjustment.ARAPAdjustment AS ARAPAdjustment
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		Amounts.Ref = ARAPAdjustment.Ref
	|		AND Amounts.RowID = ARAPAdjustment.RowID
	|
	|	LEFT JOIN
	|		TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON 
	|		TableOfBatchAccountingAnalysts.LineNumber 		= ARAPAdjustment.LineNumber
	|		AND TableOfBatchAccountingAnalysts.TabularSectionName = ""ARAPAdjustment""
	|WHERE
	|	ARAPAdjustment.Ref = &Ref
	|	AND ARAPAdjustment.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	LineNumberText = CostCalculationDocumentsPosting.RequestTextStringCodesForBatchAccountingAnalytics(
		Metadata.Documents.SaleAdjustment.Name,
		"InventoryOwnerAttributesGoodsReceipt, Discrepancies");
	
	TextSelectionOfAnalystField = LineNumberText + "
	|SELECT
	|	""InventoryOwnerAttributesGoodsReceipt""		AS TabularSectionName,
	|	DocumentTable.LineNumber		AS LineNumber,
	|	DocumentTable.Ref.Partner		AS Vendor,
	|	DocumentTable.Ref.Counterparty	AS Counterparty,
	|	DocumentTable.VATRate			AS VATRate,
	|	(CASE
	|		WHEN DocumentTable.Ref.DocumentBasis REFS Document.CustomerInvoice
	|			AND DocumentTable.Ref.DocumentBasis.ToReturnReusablePackage
	|			AND DocumentTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		THEN UNDEFINED
	|		WHEN DocumentTable.Ref.DocumentBasis REFS Document.CustomerInvoice
	|			AND DocumentTable.Ref.DocumentBasis.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|		THEN UNDEFINED
	|		WHEN DocumentTable.Ref.VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale)
	|		THEN CASE DocumentTable.VATRate
	|				WHEN &ExportVATRate
	|				THEN CASE
	|					WHEN ISNULL(DocumentTable.FEACNCode.Commodity, FALSE)
	|					THEN VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|					ELSE VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
	|					END
	|				WHEN VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|				THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				ELSE VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			END
	|		WHEN DocumentTable.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|			AND DocumentTable.Ref.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|		THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE DocumentTable.Ref.VATTaxation
	|	END)								AS VATTaxation,
	|	CASE
	|		WHEN DocumentTable.Ref.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer)
	|			THEN VALUE(Enum.AssetKinds.GoodsTaxAgent)
	|		WHEN DocumentTable.ItemsLocationAttributes.Products.ItemsType IN
	|				(VALUE(Enum.ItemsTypes.OwnGoods),
	|				VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN VALUE(Enum.AssetKinds.Goods)
	|		ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END								AS AssetTaxClass,
	|	LineCodes.RowCode					AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS DocumentTable
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""InventoryOwnerAttributesGoodsReceipt""
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	""Discrepancies""							AS TabularSectionName,
	|	DocumentTable.LineNumber			AS LineNumber,
	|	DocumentTable.Ref.Partner			AS Vendor,
	|	DocumentTable.Ref.Counterparty		AS Counterparty,
	|	DocumentTable.VATRate 				AS VATRate,
	|	DocumentTable.Ref.VATTaxation	AS VATTaxation,
	|	CASE
	|		WHEN DocumentTable.Ref.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer)
	|			THEN VALUE(Enum.AssetKinds.GoodsTaxAgent)
	|		WHEN DocumentTable.ItemsLocationAttributes.Products.ItemsType IN
	|				(VALUE(Enum.ItemsTypes.OwnGoods),
	|				VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN VALUE(Enum.AssetKinds.Goods)
	|		ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END									AS AssetTaxClass,
	|	LineCodes.RowCode						AS RowCode
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS DocumentTable
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""Discrepancies""
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	""ARAPAdjustment""		AS TabularSectionName,
	|	DocumentTable.LineNumber		AS LineNumber,
	|	DocumentTable.Ref.Partner		AS Vendor,
	|	DocumentTable.Ref.Counterparty	AS Counterparty,
	|	DocumentTable.VATRate			AS VATRate,
	|	DocumentTable.Ref.VATTaxation AS VATTaxation,
	|	VALUE(Enum.AssetKinds.OtherWorksAndServices) AS AssetTaxClass,
	|	0									AS RowCode
	|FROM
	|	Document.SaleAdjustment.ARAPAdjustment AS DocumentTable
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts) Export
	
	RegisterName = "TTTableTypesOfInventoryRegistration";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	InitializeProductAccountingAnalyticsKeys(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	SetRequestParametersCurrencyCoefficients(Query);
	QueryText = "
	|SELECT
	|	InventoryKinds.LineNumber                             AS LineNumber,
	|	InventoryKinds.ItemsLocationAttributes.Products                              AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Products.ItemsType              AS ItemsType,
	|	ISNULL(InventoryKinds.FEACNCode.Commodity,FALSE)   AS Commodity,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic                            AS Characteristic,
	|	InventoryKinds.ItemsLocationAttributes.Series                                     AS Series,
	|	InventoryKinds.ItemsLocationAttributes.Purpose                                AS Purpose,
	|	InventoryKinds.InventoryOwnerAttribute                              AS InventoryOwnerAttribute,
	|	InventoryKinds.CorInventoryOwnerAttribute                           AS CorInventoryOwnerAttribute,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass				AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation		AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes 	AS LotVendorAttributes,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryType                   AS InventoryType,
	|	InventoryKinds.InventoryOwnerAttribute.Currency                       AS Currency,
	|	InventoryKinds.CCDNumber                     			AS CCDNumber,
	|	InventoryKinds.Count                              AS Count,
	|	InventoryKinds.QuantityByGBRN                        AS QuantityByGBRN,
	|	InventoryKinds.AmountIncludingVAT					 			AS AmountIncludingVAT,
	|	InventoryKinds.VATAmount					 			AS VATAmount,
	|	InventoryKinds.ExciseTaxAmount								AS ExciseAmountInCurrencyLocal,
	|	CAST(InventoryKinds.ExciseTaxAmount * &ConversionRatioFromLocalToMan
	|		AS NUMBER(31,2))								AS ExciseAmountInCurrencyMgmt,
	|	InventoryKinds.VATAmountCompl				 			AS VATAmountCompl,
	|	InventoryKinds.VATAmountMan					 			AS VATAmountMan,
	|
	|	-ISNULL(Amounts.AmountIncludingVATMan, 0)					AS AmountIncludingVATMan,
	|	-ISNULL(Amounts.AmountExcludingVATMan, 0)					AS AmountExcludingVATMan,
	|	-ISNULL(Amounts.AmountIncludingVATCompl, 0)					AS AmountIncludingVATCompl,
	|	-ISNULL(Amounts.AmountExcludingVATCompl, 0)					AS AmountExcludingVATCompl,
	|	-ISNULL(Amounts.VATAmountCompl, 0)					AS VATLocal,
	|	-ISNULL(Amounts.VATAmountMan, 0)						AS VATManag,
	|
	|	InventoryKinds.Cost_							AS Cost_,
	|	InventoryKinds.CostExcludingVAT_						AS CostExcludingVAT_,
	|	InventoryKinds.CostLocal						AS CostLocal,
	|	InventoryKinds.CDCost							AS CDCost,
	|	InventoryKinds.TDCost							AS TDCost,
	|
	|	InventoryKinds.AmountARAP						AS AmountARAP,
	|	CASE
	|		WHEN InventoryKinds.AmountIncludingVAT <> 0
	|			THEN CAST(InventoryKinds.AmountARAP * InventoryKinds.VATAmount / InventoryKinds.AmountIncludingVAT AS NUMBER(31,2))
	|		ELSE 0
	|	END												AS AmountVATARAP,
	|
	|	InventoryKinds.CostDefiningMethod			AS CostDefiningMethod,
	|	CASE
	//		Implementation without transfer of ownership is of the Contract type - implementation, but the Contract is specified in the analytics
	|		WHEN InventoryKinds.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|		THEN InventoryKinds.ItemsLocationAttributes.StorageLocation
	|		WHEN InventoryKinds.Warehouse = VALUE(Catalog.Warehouses.EmptyRef) AND InventoryKinds.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|		THEN InventoryKinds.ItemsLocationAttributes.StorageLocation
	|		ELSE InventoryKinds.Warehouse
	|	END AS Warehouse,
	|	InventoryKinds.Warehouse.ShopFloorStockroom                    AS ShopFloorStockroom,
	|	CASE
	//		Implementation without transfer of ownership is of the Contract type - implementation, but the Contract is specified in the analytics
	|		WHEN InventoryKinds.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|		THEN ISNULL(InventoryKinds.CorItemsLocationAttributes.StorageLocation, InventoryKinds.ItemsLocationAttributes.StorageLocation)
	|		ELSE InventoryKinds.OriginWarehouse
	|	END AS OriginWarehouse,
	|	InventoryKinds.SalesOrder                             AS SalesOrder,
	|	InventoryKinds.InventoryOwnerAttributeShipment                       AS InventoryOwnerAttributeShipment,
	|	InventoryKinds.ItemsLocationAttributes               AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey                 AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	InventoryKinds.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	InventoryKinds.SetAccountingDimension                    AS SetAccountingDimension,
	|	CASE
	|		WHEN InventoryKinds.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|			THEN InventoryKinds.ItemsLocationAttributes
	|		ELSE InventoryKinds.CorItemsLocationAttributes
	|	END                                                AS DimensionSalesOfGoodsAndServices,
	|	CASE
	|		WHEN InventoryKinds.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|			THEN AnalyticsWithoutAssignment.DimensionKey
	|		ELSE AnalyticsForShipmentsWithoutDestination.DimensionKey
	|	END                                                AS UnassignedImplementationAnalytics,
	|	InventoryKinds.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory        AS SaleOfAnotherCompanyInventory,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner                       AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType            AS OwnerSInventoryOwnersAttributeTypeOfInventory,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization           AS OwnerSInventoryOwnersAttributesOfOwnerCompany,
	|	CommitteeKeys.DimensionKey                         AS CommitteeAnalytics,
	|	InventoryKinds.ToIncomeExpenses				 			 AS ToIncomeExpenses,
	|	InventoryKinds.ToExpenseAs               			 AS ToExpenseAs,
	|	InventoryKinds.ExpenseItem               			 AS ExpenseItemRegistration,
	|	InventoryKinds.DimensionOfExpenses            			 AS AnalyticsOfExpensesRegistration,
	|	InventoryKinds.RowID                      AS RowID,
	|	InventoryKinds.VATRate                                AS VATRate,
	|	InventoryKinds.Ref.ExpenseItem                              AS ExpenseItem,
	|	InventoryKinds.Ref.DimensionOfExpenses                           AS DimensionOfExpenses,
	|	InventoryKinds.Ref.Organization                                 AS Organization,
	|
	|	(CASE
	|		WHEN &GenerateInventoryOwnerAttributesBySalesOpportunities
	|				AND &EnabledGoodsAssignmentInSalesOpportunity
	|			THEN &SalesOpportunity
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|				AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|			THEN &Manager
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|				AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END)													AS FinancialAccountingDimension,
	|	InventoryKinds.ARAPObject								AS ARAPObject,
	|	ISNULL(CCDNumbers.CCDNumberType, VALUE(Enum.CCDNumberTypes.EmptyRef)) AS CCDNumberType,
	|	CASE
	|		WHEN InventoryKinds.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND InventoryKinds.ItemsLocationAttributes.Products.TracedGoods 
	|			AND &UseTraceableImportedGoodsAccounting
	|			THEN TRUE
	|		ELSE FALSE
	|	END ThisIsTraceableWork
	|	
	|INTO TTTableTypesOfInventoryRegistration
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS InventoryKinds
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON 
	|		InventoryKinds.ItemsLocationAttributes.Products		= AnalyticsWithoutAssignment.Products
	|		AND InventoryKinds.ItemsLocationAttributes.Characteristic	= AnalyticsWithoutAssignment.Characteristic
	|		AND InventoryKinds.ItemsLocationAttributes.Series			= AnalyticsWithoutAssignment.Series
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND InventoryKinds.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsForShipmentsWithoutDestination
	|	ON 
	|		InventoryKinds.CorItemsLocationAttributes.Products		= AnalyticsForShipmentsWithoutDestination.Products
	|		AND InventoryKinds.CorItemsLocationAttributes.Characteristic	= AnalyticsForShipmentsWithoutDestination.Characteristic
	|		AND InventoryKinds.CorItemsLocationAttributes.Series			= AnalyticsForShipmentsWithoutDestination.Series
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsForShipmentsWithoutDestination.Purpose
	|		AND InventoryKinds.CorItemsLocationAttributes.StorageLocation = AnalyticsForShipmentsWithoutDestination.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsForShipmentsWithoutDestination.ProductCostElement
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS CommitteeKeys
	|	ON
	|		InventoryKinds.ItemsLocationAttributes.Products				= CommitteeKeys.Products
	|		AND InventoryKinds.ItemsLocationAttributes.Characteristic			= CommitteeKeys.Characteristic
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeKeys.Series
	|		AND VALUE(Catalog.Assignments.EmptyRef) = CommitteeKeys.Purpose
	|		AND InventoryKinds.InventoryOwnerAttribute.GoodsOwner	= CommitteeKeys.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeKeys.ProductCostElement
	|
	|	LEFT JOIN
	|		TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON 
	|		TableOfBatchAccountingAnalysts.LineNumber 		= InventoryKinds.LineNumber
	|		AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryOwnerAttributesGoodsReceipt""
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		Amounts.Ref = InventoryKinds.Ref
	|		AND Amounts.RowID = InventoryKinds.RowID
	|
	|	LEFT JOIN
	|		Catalog.CCDNumbers AS CCDNumbers
	|	ON
	|		InventoryKinds.CCDNumber  = CCDNumbers.Ref
	|
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|
	|INDEX BY
	|	CCDNumberType";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTInventoryTypesRevenueAdjustment(Query, QueryTexts) Export
	
	RegisterName = "TTInventoryTypesRevenueAdjustment";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	InitializeProductAccountingAnalyticsKeys(Query);
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                                  AS LineNumber,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                                   AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType                                           AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner                                  AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType                       AS OwnerSInventoryOwnersAttributeTypeOfInventory,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization                      AS OwnerSInventoryOwnersAttributesOfOwnerCompany,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory                   AS SaleOfAnotherCompanyInventory,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Currency                                               AS Currency,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products                                          AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.ItemsType                          AS ItemsType,
	|	ISNULL(TableTypesOfStocks_.FEACNCode.Commodity,FALSE)        AS Commodity,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic                                        AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber                                     AS CCDNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes                   AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey                            AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	TableTypesOfStocks_.SetAccountingDimension                        AS SetAccountingDimension,
	|	TableTypesOfStocks_.SalesOrder                                 AS SalesOrder,
	|
	|	TableTypesOfStocks_.AmountIncludingVAT                                    AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount                                     AS VATAmount,
	|	TableTypesOfStocks_.VATAmountCompl AS VATAmountCompl,
	|	TableTypesOfStocks_.VATAmountMan AS VATAmountMan,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)                                 AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)                               AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)                                AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)                              AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)                                 AS VATLocal,
	|	ISNULL(Amounts.VATAmountMan, 0)                                  AS VATManag,
	|
	|	TableTypesOfStocks_.AmountARAP AS AmountARAP,
	|	CASE WHEN TableTypesOfStocks_.AmountIncludingVAT <> 0 THEN
	|		CAST(TableTypesOfStocks_.AmountARAP * TableTypesOfStocks_.VATAmount / TableTypesOfStocks_.AmountIncludingVAT AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END AS AmountVATARAP,
	|
	|	TableTypesOfStocks_.RowID                          AS RowID,
	|	TableTypesOfStocks_.VATRate                                    AS VATRate,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation											 AS Warehouse,
	|	TableTypesOfStocks_.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom                    AS ShopFloorStockroom,
	|	(CASE
	|		WHEN &GenerateInventoryOwnerAttributesBySalesOpportunities AND &EnabledGoodsAssignmentInSalesOpportunity
	|			THEN &SalesOpportunity
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|			THEN &Manager
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END) AS FinancialAccountingDimension,
	|	(CASE
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|			CASE TableTypesOfStocks_.VATRate
	|			WHEN &ExportVATRate THEN 
	|				CASE WHEN ISNULL(TableTypesOfStocks_.FEACNCode.Commodity,FALSE)
	|					THEN VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|					ELSE VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
	|				END
	|			WHEN VALUE(Catalog.VATRates.EXCLUDINGVAT) THEN
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			ELSE
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			END
	|		WHEN TableTypesOfStocks_.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		 AND &VATTaxation IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT), 
	|				VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle))
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END) AS VATActivityType,
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	TableTypesOfStocks_.Ref.Organization AS Organization,
	|	ISNULL(CCDNumbers.CCDNumberType, VALUE(Enum.CCDNumberTypes.EmptyRef)) AS CCDNumberType,
	|	CommitteeKeys.DimensionKey AS CommitteeAnalytics,
	|	CASE
	|		WHEN CatalogOfProductItem.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND CatalogOfProductItem.TracedGoods
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsWork
	|
	|INTO TTInventoryTypesRevenueAdjustment
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesRevenueAdjustment AS TableTypesOfStocks_
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS CommitteeKeys
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = CommitteeKeys.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = CommitteeKeys.Characteristic
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeKeys.Series
	|		AND VALUE(Catalog.Assignments.EmptyRef) = CommitteeKeys.Purpose
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner = CommitteeKeys.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeKeys.ProductCostElement
	|
	|	LEFT JOIN
	|		Catalog.CCDNumbers AS CCDNumbers
	|	ON
	|		TableTypesOfStocks_.CCDNumber  = CCDNumbers.Ref
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		Amounts.Ref = TableTypesOfStocks_.Ref
	|		AND Amounts.RowID = TableTypesOfStocks_.RowID
	|
	|	LEFT JOIN
	|		Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		ON InventoryLocationAttributeKeys.Ref = TableTypesOfStocks_.ItemsLocationAttributes
	|
	|	LEFT JOIN
	|		Catalog.Products AS CatalogOfProductItem
	|		ON CatalogOfProductItem.Ref = InventoryLocationAttributeKeys.Products
	|
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|
	|INDEX BY
	|	CCDNumberType";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTransferredReturnablePackaging(Query, QueryTexts, Registers)
	
	RegisterName = "TransferredReturnablePackaging";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryWriteOff", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryWriteOff(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryRegistration", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	0                                               AS Order,
	|	TTTableTypesOfInventoryWriteOff.LineNumber        AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	&Period                                         AS Period,
	|	TTTableTypesOfInventoryWriteOff.Products       AS Products,
	|	TTTableTypesOfInventoryWriteOff.Characteristic     AS Characteristic,
	|	TTTableTypesOfInventoryWriteOff.Count         AS Count,
	|	TTTableTypesOfInventoryWriteOff.QuantityByGBRN   AS QuantityByGBRN,
	|	TTTableTypesOfInventoryWriteOff.AmountIncludingVAT          AS Sum,
	|	TTTableTypesOfInventoryWriteOff.InventoryOwnerAttribute         AS InventoryOwnerAttribute,
	|	TTTableTypesOfInventoryWriteOff.CCDNumber           AS CCDNumber,
	|	&Partner                                        AS Partner,
	|	&DocumentBasis                              AS DocumentTransfers_,
	|	&PackageDepositIsRequired                           AS DepositIsRequired
	|FROM
	|	TTTableTypesOfInventoryWriteOff AS TTTableTypesOfInventoryWriteOff
	|WHERE
	|	NOT TTTableTypesOfInventoryWriteOff.ToIncomeExpenses
	|	AND TTTableTypesOfInventoryWriteOff.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND &ToReturnReusablePackage
	|
	|UNION ALL
	|
	|SELECT
	|	1                                                    AS Order,
	|	TTTableTypesOfInventoryRegistration.LineNumber        AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)               AS RecordType,
	|	&Period                                              AS Period,
	|	TTTableTypesOfInventoryRegistration.Products       AS Products,
	|	TTTableTypesOfInventoryRegistration.Characteristic     AS Characteristic,
	|	-TTTableTypesOfInventoryRegistration.Count        AS Count,
	|	-TTTableTypesOfInventoryRegistration.QuantityByGBRN  AS QuantityByGBRN,
	|	-TTTableTypesOfInventoryRegistration.AmountIncludingVAT         AS Sum,
	|	TTTableTypesOfInventoryRegistration.InventoryOwnerAttribute         AS InventoryOwnerAttribute,
	|	TTTableTypesOfInventoryRegistration.CCDNumber           AS CCDNumber,
	|	&Partner                                             AS Partner,
	|	&DocumentBasis                                   AS DocumentTransfers_,
	|	&PackageDepositIsRequired                                AS DepositIsRequired
	|FROM
	|	TTTableTypesOfInventoryRegistration AS TTTableTypesOfInventoryRegistration
	|
	|WHERE
	|	NOT TTTableTypesOfInventoryRegistration.ToIncomeExpenses
	|	AND TTTableTypesOfInventoryRegistration.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND &ToReturnReusablePackage
	|
	|UNION ALL
	|
	|SELECT
	|	2                                                           AS Order,
	|	TTTableInventoryTypesRevenueAdjustment.LineNumber        AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)                      AS RecordType,
	|	&Period                                                     AS Period,
	|	TTTableInventoryTypesRevenueAdjustment.ItemsLocationAttributes.Products                                      AS Products,
	|	TTTableInventoryTypesRevenueAdjustment.ItemsLocationAttributes.Characteristic                                    AS Characteristic,
	|	0                                                           AS Count,
	|	0                                                           AS QuantityByGBRN,
	|	TTTableInventoryTypesRevenueAdjustment.AmountIncludingVAT          AS Sum,
	|	TTTableInventoryTypesRevenueAdjustment.InventoryOwnerAttribute         AS InventoryOwnerAttribute,
	|	TTTableInventoryTypesRevenueAdjustment.CCDNumber           AS CCDNumber,
	|	&Partner                                                    AS Partner,
	|	&DocumentBasis                                          AS DocumentTransfers_,
	|	&PackageDepositIsRequired                                       AS DepositIsRequired
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesRevenueAdjustment AS TTTableInventoryTypesRevenueAdjustment
	|WHERE
	|	TTTableInventoryTypesRevenueAdjustment.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND &ToReturnReusablePackage
	|	AND TTTableInventoryTypesRevenueAdjustment.Ref = &Ref
	|
	|ORDER BY
	|	Order,
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";

	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryWriteOff", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryWriteOff(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryRegistration", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS ShipmentCompany,
	|	CASE WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory THEN
	|		TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|	ELSE
	|		&Organization
	|	END AS Organization,
	|	CASE WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory THEN
	|		TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner
	|	ELSE
	|		TableTypesOfStocks_.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	&DocumentBasis AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CASE
	|		WHEN NOT TableTypesOfStocks_.CorInventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|			THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE UNDEFINED
	|	END AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	&AdjustmentKind AS BusinessOperation,
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|	FALSE AS Primary
	|FROM
	|	TTTableTypesOfInventoryWriteOff AS TableTypesOfStocks_
	|
	|WHERE
	|	NOT TableTypesOfStocks_.ToIncomeExpenses
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS ShipmentCompany,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	&DocumentBasis AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	UNDEFINED AS CorItemsLocationAttributes,
	|	UNDEFINED AS CorInventoryOwnerAttribute,
	|	&AdjustmentKind AS BusinessOperation,
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|	FALSE AS Primary
	|FROM
	|	TTTableTypesOfInventoryWriteOff AS TableTypesOfStocks_
	|
	|WHERE
	|	NOT TableTypesOfStocks_.ToIncomeExpenses
	|	AND NOT TableTypesOfStocks_.CorInventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense),
	|	&Period,
	|	&Organization,
	|	CASE WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory THEN
	|		TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|	ELSE
	|		&Organization
	|	END,
	|	CASE WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory THEN
	|		TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner
	|	ELSE
	|		TableTypesOfStocks_.InventoryOwnerAttribute
	|	END,
	|	TableTypesOfStocks_.Products,
	|	TableTypesOfStocks_.Characteristic,
	|	TableTypesOfStocks_.CCDNumber,
	|	&DocumentBasis,
	|	-TableTypesOfStocks_.Count,
	|	-TableTypesOfStocks_.QuantityByGBRN,
	|	TableTypesOfStocks_.ItemsLocationAttributes,
	|	TableTypesOfStocks_.DimensionSalesOfGoodsAndServices AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN TableTypesOfStocks_.CorInventoryOwnerAttribute <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|			THEN TableTypesOfStocks_.CorInventoryOwnerAttribute
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|			THEN TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END AS CorInventoryOwnerAttribute,
	|	&AdjustmentKind,
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|	FALSE AS Primary
	|FROM
	|	TTTableTypesOfInventoryRegistration AS TableTypesOfStocks_
	|
	|WHERE
	|	NOT TableTypesOfStocks_.ToIncomeExpenses
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Period,
	|	&Organization,
	|	&Organization,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products,
	|	TableTypesOfStocks_.Characteristic,
	|	TableTypesOfStocks_.CCDNumber,
	|	&DocumentBasis,
	|	-TableTypesOfStocks_.Count,
	|	-TableTypesOfStocks_.QuantityByGBRN,
	|	TableTypesOfStocks_.ItemsLocationAttributes,
	|	UNDEFINED AS CorItemsLocationAttributes,
	|	UNDEFINED AS CorInventoryOwnerAttribute,
	|	&AdjustmentKind,
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|	FALSE AS Primary
	|FROM
	|	TTTableTypesOfInventoryRegistration AS TableTypesOfStocks_
	|
	|WHERE
	|	NOT TableTypesOfStocks_.ToIncomeExpenses
	|	AND NOT TableTypesOfStocks_.CorInventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoodsForTransfer";

	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryWriteOff", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryWriteOff(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryRegistration", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	// Types of inventory to be written off
	|SELECT
	|	TableTypesOfStocks_.LineNumber								  AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)						  AS RecordType,
	|	&Period														  AS Period,
	|	TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization			  AS CompanyOwner,
	|	TableTypesOfStocks_.ItemsLocationAttributes				  AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Products								  AS Products,
	|	TableTypesOfStocks_.Characteristic							  AS Characteristic,
	|	TableTypesOfStocks_.InventoryOwnerAttribute								  AS SellerInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber									  AS CCDNumber,
	|	TableTypesOfStocks_.Count								  AS Count
	|FROM
	|	TTTableTypesOfInventoryWriteOff AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.SaleOfAnotherCompanyInventory
	|	AND NOT TableTypesOfStocks_.ToIncomeExpenses
	|	AND NOT TableTypesOfStocks_.ThisIsTraceableWork
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTSuitableAgreements(QueryTexts)
	
	RegisterName = "TTSuitableAgreements";
	
	QueryText = "SELECT DISTINCT
	|	ToRegister.Products AS Products,
	|	ToRegister.Characteristic AS Characteristic,
	|	ISNULL(TermsOfPurchases.Ref, AgreementWithProviderWithoutServices.Ref) AS Ref,
	|	ISNULL(TermsOfPurchases.Ref.Status, AgreementWithProviderWithoutServices.Status) AS Status,
	|	ISNULL(TermsOfPurchases.Ref.ValidityEndDate,
	|		AgreementWithProviderWithoutServices.ValidityEndDate) AS ValidityEndDate
	|INTO TTSuitableAgreements_Services
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS ToRegister
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors.AgentServices AS TermsOfPurchases
	|		ON TermsOfPurchases.Ref.Partner = ISNULL(ToRegister.Characteristic.Principal,
	|			ToRegister.Products.Principal)
	|		AND TermsOfPurchases.Ref.Organization = &Organization
	|		AND TermsOfPurchases.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|		AND TermsOfPurchases.Ref.Status IN (VALUE(Enum.StatusesOfTermsOfPurchase.Valid),
	|				VALUE(Enum.StatusesOfTermsOfPurchase.Closed))
	|		AND &ShipmentPeriod >= TermsOfPurchases.Ref.ValidityStartDate
	|		AND (&ShipmentPeriod <= TermsOfPurchases.Ref.ValidityEndDate
	|			OR TermsOfPurchases.Ref.ValidityEndDate = DATETIME(1, 1, 1))
	|		AND ToRegister.Products = TermsOfPurchases.Products
	|		AND ToRegister.Characteristic = TermsOfPurchases.Characteristic
	|		AND TermsOfPurchases.Ref.UseSpecifiedAgentServices
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS AgreementWithProviderWithoutServices
	|		ON AgreementWithProviderWithoutServices.Partner = ISNULL(ToRegister.Characteristic.Principal,
	|			ToRegister.Products.Principal)
	|		AND AgreementWithProviderWithoutServices.Organization = &Organization
	|		AND AgreementWithProviderWithoutServices.BusinessOperation = VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|		AND AgreementWithProviderWithoutServices.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|		AND &ShipmentPeriod >= AgreementWithProviderWithoutServices.ValidityStartDate
	|		AND (&ShipmentPeriod <= AgreementWithProviderWithoutServices.ValidityEndDate
	|			OR AgreementWithProviderWithoutServices.ValidityEndDate = DATETIME(1, 1, 1))
	|		AND NOT AgreementWithProviderWithoutServices.UseSpecifiedAgentServices
	|
	|WHERE
	|	ToRegister.Ref = &Ref
	|	AND ToRegister.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|	AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) <> &Organization
	|	AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) <> UNDEFINED
	|	AND &UseAgentServiceSale
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SelectedAgreements.Products AS Products,
	|	SelectedAgreements.Characteristic AS Characteristic,
	|	SelectedAgreements.Ref AS Ref,
	|	TermsOfPurchases.Status AS Status,
	|	TermsOfPurchases.Currency AS Currency
	|	INTO TTSuitableAgreements
	|FROM
	|	(SELECT
	|		DataByServices.Products AS Products,
	|		DataByServices.Characteristic AS Characteristic,
	|		DataByServices.Ref AS Ref
	|	FROM
	|		TTSuitableAgreements_Services AS DataByServices
	|	WHERE
	|		DataByServices.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataByServices.Products,
	|		DataByServices.Characteristic,
	|		MAX(DataByServices.Ref)
	|	FROM
	|		TTSuitableAgreements_Services AS DataByServices
	|	WHERE
	|		DataByServices.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Closed)
	|		AND (DataByServices.Products, DataByServices.Characteristic, DataByServices.ValidityEndDate) IN
	|				(SELECT
	|					Products,
	|					Characteristic,
	|					MAX(ValidityEndDate)
	|				FROM
	|					TTSuitableAgreements_Services
	|				WHERE
	|					DataByServices.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Closed)
	|				GROUP BY
	|					Products,
	|					Characteristic)
	|
	|	GROUP BY
	|		DataByServices.Products,
	|		DataByServices.Characteristic) AS SelectedAgreements
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchases
	|		ON SelectedAgreements.Ref = TermsOfPurchases.Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTAgencyServices(QueryTexts)
	
	RegisterName = "TTAgencyServices";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTSuitableAgreements", QueryTexts) Then
		QueryTextTTSuitableAgreements(QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT DISTINCT
	|	CASE
	|		WHEN NOT ServiceAgreementInForce.Ref IS NULL
	|			THEN ServiceAgreementInForce.Ref
	|		ELSE ISNULL(ServiceAgreementClosed.Ref, UNDEFINED)
	|	END AS Terms,
	|	CASE
	|		WHEN NOT ServiceAgreementInForce.Ref IS NULL
	|			THEN ServiceAgreementInForce.Ref.Currency
	|		ELSE ISNULL(ServiceAgreementClosed.Ref.Currency, &Currency)
	|	END AS Currency,
	|	ToRegister.Products AS Products,
	|	ToRegister.Characteristic AS Characteristic,
	|	ToRegister.Ref.Organization AS Organization,
	|	ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) AS Principal
	|INTO TTAgencyServices
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS ToRegister
	|
	|	LEFT JOIN TTSuitableAgreements AS ServiceAgreementInForce
	|		ON ToRegister.Products = ServiceAgreementInForce.Products
	|		AND ToRegister.Characteristic = ServiceAgreementInForce.Characteristic
	|		AND ServiceAgreementInForce.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|
	|	LEFT JOIN TTSuitableAgreements AS ServiceAgreementClosed
	|		ON ToRegister.Products = ServiceAgreementClosed.Products
	|		AND ToRegister.Characteristic = ServiceAgreementClosed.Characteristic
	|		AND ServiceAgreementClosed.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Closed)
	|		AND ServiceAgreementInForce.Ref IS NULL
	|
	|WHERE
	|	ToRegister.Ref = &Ref
	|	AND ToRegister.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|	AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) <> &Organization
	|	AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) <> UNDEFINED
	|	AND &UseAgentServiceSale";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTExchangeRates(Query, QueryTexts)
	
	RegisterName = "ExchangeRates";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryWriteOff", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryWriteOff(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryRegistration", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryRegistration(Query,QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAgencyServices", QueryTexts) Then
		QueryTextTTAgencyServices(QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInventoryTypesRevenueAdjustment", QueryTexts) Then
		QueryTextTTInventoryTypesRevenueAdjustment(Query, QueryTexts);
	EndIf;
	
	QueryText = "
		|SELECT
		|	ExchangeRates.Currency AS Currency,
		|
		|	(DocumentExchangeRate.CourseNumerator * ExchangeRates.CourseDenominator)
		|   / (DocumentExchangeRate.CourseDenominator * ExchangeRates.CourseNumerator) AS ConversionFactor_
		|
		|INTO ExchangeRates
		|FROM
		|	InformationRegister.RelativeExchangeRates.SliceLast(&Period,
		|		(Currency, BaseCurrency) IN (
		|			SELECT DISTINCT
		|				CASE
		|					WHEN TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
		|						THEN TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Currency
		|					ELSE TableTypesOfStocks_.Currency
		|				END AS Currency,
		|				TableTypesOfStocks_.Organization.LocalAccountingCurrency AS BaseCurrency
		|			FROM
		|				TTTableTypesOfInventoryWriteOff AS TableTypesOfStocks_
		|			WHERE
		|				NOT TableTypesOfStocks_.ToIncomeExpenses
		|				AND (TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
		|					OR TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods))
		|				AND (TableTypesOfStocks_.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
		|					OR (TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage) AND NOT  &ToReturnReusablePackage)
		|					OR TableTypesOfStocks_.ItemsType IS NULL)
		|
		|			UNION
		|
		|			SELECT DISTINCT
		|				CASE
		|					WHEN TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
		|						THEN TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Currency
		|					ELSE TableTypesOfStocks_.Currency
		|				END AS Currency,
		|				TableTypesOfStocks_.Organization.LocalAccountingCurrency AS BaseCurrency
		|			FROM
		|				TTTableTypesOfInventoryRegistration AS TableTypesOfStocks_
		|			WHERE
		|				NOT TableTypesOfStocks_.ToIncomeExpenses
		|				AND (TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
		|					OR TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods))
		|				AND (TableTypesOfStocks_.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
		|					OR (TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage) AND NOT  &ToReturnReusablePackage)
		|					OR TableTypesOfStocks_.ItemsType IS NULL)
		|
		|			UNION
		|
		|			SELECT DISTINCT
		|				CASE
		|					WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
		|						THEN TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Currency
		|					ELSE TableTypesOfStocks_.Currency
		|				END AS Currency,
		|				TableTypesOfStocks_.Organization.LocalAccountingCurrency AS BaseCurrency
		|			FROM
		|				TTInventoryTypesRevenueAdjustment AS TableTypesOfStocks_
		|			WHERE
		|				(TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
		|					OR TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods))
		|				AND (TableTypesOfStocks_.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
		|					OR (TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage) AND NOT &ToReturnReusablePackage)
		|					OR TableTypesOfStocks_.ItemsType IS NULL)
		|
		|			UNION
		|
		|			SELECT DISTINCT
		|				Services.Currency AS Currency,
		|				Services.Organization.LocalAccountingCurrency AS BaseCurrency
		|			FROM
		|				TTAgencyServices AS Services
		|			)
		|	) AS ExchangeRates
		|
		|	INNER JOIN
		|		InformationRegister.RelativeExchangeRates.SliceLast(&SalePeriod, Currency = &Currency) AS DocumentExchangeRate
		|	ON
		|		ExchangeRates.BaseCurrency = DocumentExchangeRate.BaseCurrency
		|
		|WHERE
		|	DocumentExchangeRate.CourseDenominator <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryWriteOff", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryWriteOff(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryRegistration", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInventoryTypesRevenueAdjustment", QueryTexts) Then
		QueryTextTTInventoryTypesRevenueAdjustment(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("ExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	// Types of inventory to be written off
	|SELECT
	|	TableTypesOfStocks_.LineNumber			AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	&Period									AS Period,
	|	&Organization							AS Organization,
	|	TableTypesOfStocks_.Currency				AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute			AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products			AS Products,
	|	TableTypesOfStocks_.Characteristic		AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber				AS CCDNumber,
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer) AS BusinessOperation,
	|	&DocumentBasis						AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.Count			AS Count,
	|	CASE
	|		WHEN TableTypesOfStocks_.Currency = &Currency
	|			THEN TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END									AS RevenueAmount,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN TableTypesOfStocks_.AmountIncludingVATCompl
	|		ELSE 0
	|	END									AS RevenueAmountExclVATLocal,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END									AS RevenueAmountMan,
	|	0										AS QuantityConsumed,
	|	TableTypesOfStocks_.Count			AS QuantityToRegister,
	|	TableTypesOfStocks_.QuantityByGBRN		AS QuantityForRegistrationByProductBatchID,
	|	CASE
	|		WHEN TableTypesOfStocks_.Currency = &Currency
	|			THEN TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END									AS RevenueAmountToRegister,
	|	0										AS QuantityConsumedForIncoiceRegistration,
	|	0										AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	UNDEFINED							AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CommitteeAnalytics	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ARAPObject.UUID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID AS RowID
	|FROM
	|	TTTableTypesOfInventoryWriteOff AS TableTypesOfStocks_
	|		LEFT JOIN ExchangeRates AS ExchangeRates
	|		ON TableTypesOfStocks_.InventoryOwnerAttribute.Currency = ExchangeRates.Currency
	|
	|WHERE
	|	NOT TableTypesOfStocks_.ToIncomeExpenses
	|	AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND (TableTypesOfStocks_.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR (TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND NOT &ToReturnReusablePackage)
	|		OR TableTypesOfStocks_.ItemsType IS NULL)
	|
	|UNION ALL
	|
	// Types of inventory to be registered
	|SELECT
	|	TableTypesOfStocks_.LineNumber			AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	&Period									AS Period,
	|	&Organization							AS Organization,
	|	TableTypesOfStocks_.Currency				AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute			AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products			AS Products,
	|	TableTypesOfStocks_.Characteristic		AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber				AS CCDNumber,
	|	VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer) AS BusinessOperation,
	|	&DocumentBasis						AS DocumentSalesOfGoodsAndServices,
	|	-TableTypesOfStocks_.Count			AS Count,
	|	CASE
	|		WHEN TableTypesOfStocks_.Currency = &Currency
	|			THEN -TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE -TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END									AS RevenueAmount,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN -TableTypesOfStocks_.AmountIncludingVATCompl
	|		ELSE 0
	|	END									AS RevenueAmountExclVATLocal,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN -TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END									AS RevenueAmountMan,
	|	0										AS QuantityConsumed,
	|	-TableTypesOfStocks_.Count			AS QuantityToRegister,
	|	-TableTypesOfStocks_.QuantityByGBRN	AS QuantityForRegistrationByProductBatchID,
	|	CASE
	|		WHEN TableTypesOfStocks_.Currency = &Currency
	|			THEN -TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE -TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END									AS RevenueAmountToRegister,
	|	0										AS QuantityConsumedForIncoiceRegistration,
	|	0										AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	UNDEFINED							AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CommitteeAnalytics	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ARAPObject.UUID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID AS RowID 
	|FROM
	|	TTTableTypesOfInventoryRegistration AS TableTypesOfStocks_
	|		LEFT JOIN ExchangeRates AS ExchangeRates
	|		ON TableTypesOfStocks_.InventoryOwnerAttribute.Currency = ExchangeRates.Currency
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON TableTypesOfStocks_.Products = Dimension.Products
	|			AND TableTypesOfStocks_.Characteristic = Dimension.Characteristic
	|			AND TableTypesOfStocks_.Series = Dimension.Series
	|			AND TableTypesOfStocks_.Purpose = Dimension.Purpose
	|			AND TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner = Dimension.StorageLocation
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|
	|WHERE
	|	NOT TableTypesOfStocks_.ToIncomeExpenses
	|	AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND (TableTypesOfStocks_.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR (TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND NOT &ToReturnReusablePackage)
	|		OR TableTypesOfStocks_.ItemsType IS NULL)
	|
	|UNION ALL
	|
	// Types of inventory to adjust revenue
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)			AS RecordType,
	|	&Period											AS Period,
	|	&Organization									AS Organization,
	|	TableTypesOfStocks_.Currency						AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products					AS Products,
	|	TableTypesOfStocks_.Characteristic				AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer) AS BusinessOperation,
	|	&DocumentBasis								AS DocumentSalesOfGoodsAndServices,
	|	0												AS Count,
	|	CASE
	|		WHEN TableTypesOfStocks_.Currency = &Currency
	|			THEN TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END											AS RevenueAmount,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN TableTypesOfStocks_.AmountIncludingVATCompl
	|		ELSE 0
	|	END									AS RevenueAmountExclVATLocal,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END									AS RevenueAmountMan,
	|	0												AS QuantityConsumed,
	|	0												AS QuantityToRegister,
	|	0												AS QuantityForRegistrationByProductBatchID,
	|	CASE
	|		WHEN TableTypesOfStocks_.Currency = &Currency
	|			THEN TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END											AS RevenueAmountToRegister,
	|	0												AS QuantityConsumedForIncoiceRegistration,
	|	0												AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CommitteeAnalytics	AS ItemsLocationAttributes,
	|	
	|	TableTypesOfStocks_.ARAPObject.UUID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID AS RowID 
	|FROM
	|	TTInventoryTypesRevenueAdjustment AS TableTypesOfStocks_
	|		LEFT JOIN ExchangeRates AS ExchangeRates
	|		ON TableTypesOfStocks_.InventoryOwnerAttribute.Currency = ExchangeRates.Currency
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND (TableTypesOfStocks_.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR (TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND NOT &ToReturnReusablePackage)
	|		OR TableTypesOfStocks_.ItemsType IS NULL)
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDivergenceOfServiceOperation(Query, QueryTexts)
	
	RegisterName = "TTDivergenceOfServiceOperation";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAgencyServices", QueryTexts) Then
		QueryTextTTAgencyServices(QueryTexts);
	EndIf;
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	SetRequestParameterVATTaxTypesTaxable(Query);
	InitializeProductAccountingAnalyticsKeys(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	DivergenceTable.LineNumber AS LineNumber,
	|	DivergenceTable.Products AS Products,
	|	ISNULL(CatalogOfProductItem.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS ItemsType,
	|	ISNULL(CatalogOfProductItem.TracedGoods, FALSE) AS TracedGoods,
	|	DivergenceTable.Characteristic AS Characteristic,
	|	DivergenceTable.Count AS Count,
	|	DivergenceTable.AmountIncludingVAT AS AmountIncludingVAT,
	|
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes     AS LotVendorAttributes,
	|
	|	DivergenceTable.AmountARAP AS AmountARAP,
	|
	|	CASE WHEN DivergenceTable.AmountIncludingVAT <> 0 THEN
	|		CAST(DivergenceTable.AmountARAP * DivergenceTable.VATAmount / DivergenceTable.AmountIncludingVAT AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END AS AmountVATARAP,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)                     AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)                   AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)                    AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)                  AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)                     AS VATLocal,
	|	ISNULL(Amounts.VATAmountMan, 0)                      AS VATManag,
	|
	|	DivergenceTable.Cost_					AS Cost_,
	|	DivergenceTable.CostExcludingVAT_				AS CostExcludingVAT_,
	|	DivergenceTable.CostLocal				AS CostLocal,
	|	DivergenceTable.CDCost					AS CDCost,
	|	DivergenceTable.TDCost					AS TDCost,
	|
	|	DivergenceTable.CostDefiningMethod   AS CostDefiningMethod,
	|	DivergenceTable.SalesOrder                     AS SalesOrder,
	|	DivergenceTable.ItemsLocationAttributes       AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey                AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	DivergenceTable.SetAccountingDimension            AS SetAccountingDimension,
	|	DivergenceTable.VATAmount                         AS VATAmount,
	|	DivergenceTable.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	DivergenceTable.Purpose.LineOfBusiness AS LineOfBusiness,
	|	DivergenceTable.Purpose                       AS Purpose,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)       AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN DivergenceTable.PostingOption IN (VALUE(Enum.CreditNoteRecordingOptions.RecordInOtherIncome),
	|													VALUE(Enum.CreditNoteRecordingOptions.ToExpenseAs)) 
	|			OR (&SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND 
	|					(&RecordInProfitLossOfPreviousYears OR NOT &AdjustTaxBaseOfPreviousPeriod))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                               AS ToIncomeExpenses,
	|
	|	AgentServices.Terms AS Terms,
	|	AgentServices.Currency AS Currency,
	|	ISNULL(PrincipalKeys.DimensionKey, UNDEFINED) AS PrincipalProductAnalysis,
	|	ISNULL(AgentServices.Principal, UNDEFINED) AS Principal,
	|
	|	(CASE
	|		WHEN &GenerateInventoryOwnerAttributesBySalesOpportunities AND &EnabledGoodsAssignmentInSalesOpportunity
	|			THEN &SalesOpportunity
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|			THEN &Manager
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END) AS FinancialAccountingDimension,
	// Filling in the VAT type of activity must coincide with the document on Customer invoices for TT in the Service work.
	|	(CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN UNDEFINED
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|			CASE DivergenceTable.VATRate
	|			WHEN &ExportVATRate THEN 
	|				VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|			WHEN VALUE(Catalog.VATRates.EXCLUDINGVAT) THEN
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			ELSE
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			END
	|		WHEN DivergenceTable.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|				AND &VATTaxation IN (&TypesOfVATTaxable)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END) AS VATActivityType,
	|	DivergenceTable.ARAPObject AS ARAPObject,
	|	DivergenceTable.Department AS Department,
	|	DivergenceTable.ExpenseItem AS ExpenseItem,
	|	DivergenceTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	DivergenceTable.ToExpenseAs AS ToExpenseAs,
	|	DivergenceTable.RowID AS RowID,
	|	CASE
	|		WHEN CatalogOfProductItem.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND ISNULL(CatalogOfProductItem.TracedGoods, FALSE)
	|			AND &UseTraceableImportedGoodsAccounting
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsTraceableWork,
	|	DivergenceTable.VATRate AS VATRate
 	|	
	|INTO TTDivergenceOfServiceOperation
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS DivergenceTable
	|	LEFT JOIN TTAgencyServices AS AgentServices
	|	ON DivergenceTable.Products = AgentServices.Products
	|		AND DivergenceTable.Characteristic = AgentServices.Characteristic
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON DivergenceTable.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND DivergenceTable.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND DivergenceTable.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND DivergenceTable.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS PrincipalKeys
	|	ON PrincipalKeys.Products = DivergenceTable.Products
	|		AND PrincipalKeys.Characteristic = DivergenceTable.Characteristic
	|		AND PrincipalKeys.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND PrincipalKeys.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		AND PrincipalKeys.StorageLocation = AgentServices.Principal
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = PrincipalKeys.ProductCostElement
	|
	|	LEFT JOIN
	|		TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON 
	|		TableOfBatchAccountingAnalysts.LineNumber 		= DivergenceTable.LineNumber
	|		AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Discrepancies""
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		Amounts.Ref = DivergenceTable.Ref
	|		AND Amounts.RowID = DivergenceTable.RowID
	|
	|	LEFT JOIN
	|		Catalog.Products AS CatalogOfProductItem
	|		ON CatalogOfProductItem.Ref = DivergenceTable.Products
	|
	|WHERE
	|	DivergenceTable.Ref = &Ref
	|	AND (CatalogOfProductItem.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OperationService),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|		OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers)
	
	RegisterName = "RevenueAndCOGS";

	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryWriteOff", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryWriteOff(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryRegistration", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInventoryTypesRevenueAdjustment", QueryTexts) Then
		QueryTextTTInventoryTypesRevenueAdjustment(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDivergenceOfServiceOperation", QueryTexts) Then
		QueryTextTTDivergenceOfServiceOperation(Query, QueryTexts);
	EndIf;
	SetParametersForPartnerAccountingAnalystRequest(Query);
	QueryText = "
	// Types of inventory to be written off
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	CASE 
	|		WHEN &SaleAdjustment2_5 THEN
	|			CASE 
	|				WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|					&AdjustmentPeriod_
	|				ELSE
	|					DATETIME(1,1,1,0,0,0)
	|			END
	|	ELSE
	|		DATETIME(1,1,1,0,0,0) 
	|	END AS AdjustmentPeriod_,
	|	&Department AS Department,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.SetAccountingDimension AS SetAccountingDimension,
	|	&AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|
	|	CASE WHEN &SaleByOrders THEN
	|		TableTypesOfStocks_.SalesOrder
	|	ELSE
	|		&DocumentBasis
	|	END AS SalesOrder,
	|	(CASE
	|		WHEN &BusinessTransactionGrounds IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			THEN VALUE(Enum.InventoryTypes.OperationService)
	|		ELSE TableTypesOfStocks_.InventoryType END) AS InventoryType,
	|	(CASE
	|		WHEN &BusinessTransactionGrounds IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			THEN UNDEFINED
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute END) AS InventoryOwnerAttribute,
	|	CASE
	//		Implementation without transfer of ownership is of the Contract type - implementation, but the Contract is specified in the analytics
	|		WHEN ISNULL(TableTypesOfStocks_.ItemsLocationAttributes.Contract.ContractType, UNDEFINED) IN (VALUE(Enum.ContractTypes.WithCustomer),
	|				VALUE(Enum.ContractTypes.SalesViaCommissionAgent))
	|			AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent)
	|		WHEN ISNULL(TableTypesOfStocks_.ItemsLocationAttributes.Contract.ContractType, UNDEFINED) = VALUE(Enum.ContractTypes.SalesViaCommissionAgent)
	|			AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent)
	|		WHEN ISNULL(TableTypesOfStocks_.ItemsLocationAttributes.Contract.ContractType, UNDEFINED) = VALUE(Enum.ContractTypes.WithCustomer)
	|			AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit)
	|		WHEN TableTypesOfStocks_.InventoryType IN
	|		 (VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|		  VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN TableTypesOfStocks_.ShopFloorStockroom
	|		 OR TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN &BusinessTransactionGrounds IN (
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END AS AccountingSection,
	|	TableTypesOfStocks_.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	CASE
	|		WHEN &BatchAccountingVersion22
	|			AND &FIFORollingValuation
	|			THEN TableTypesOfStocks_.VATActivityType
	|		ELSE UNDEFINED
	|	END AS VATActivityType,
	|
	|	&Manager AS Manager,
	|
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS ProductLineOfBusiness,
	|
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0 END) AS Cost,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			TableTypesOfStocks_.AmountExcludingVATMan
	|		ELSE 0 END) AS CostExcludingVAT,
	|	(CASE
	|		WHEN NOT &CompanyManagementAccounting
	|			THEN 0
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	 		THEN TableTypesOfStocks_.AmountExcludingVATMan
	|		ELSE 0	END) AS CostMan,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			TableTypesOfStocks_.AmountExcludingVATCompl
	|		ELSE 0	END) AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END AS RevenueAmount,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|		THEN TableTypesOfStocks_.AmountExcludingVATMan
	|		ELSE 0
	|	END AS RevenueAmountExcludingVAT,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|		THEN TableTypesOfStocks_.AmountExcludingVATCompl
	|		ELSE 0
	|	END AS RevenueAmountExclVATLocal,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|		THEN TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATLocal
	|		ELSE 0
	|	END AS RevenueAmountIncludingVATLocal,
	|	CASE
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|		THEN - TableTypesOfStocks_.AmountExcludingVATCompl 
	|			+ TableTypesOfStocks_.ExciseAmountInCurrencyLocal
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|		THEN TableTypesOfStocks_.AmountExcludingVATCompl 
	|			- TableTypesOfStocks_.ExciseAmountInCurrencyLocal
	|		ELSE 0
	|	END AS RevenueAmountPD,
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	CASE WHEN &SalesViaCommissionAgent
	|		THEN &CustomerContract
	|		ELSE &Contract
	|	END AS Contract,
	|	&Terms AS Terms,
	|
	|	&ARAPCurrency AS ARAPCurrency,
	|	TableTypesOfStocks_.AmountARAP AS AmountInARAPCurrency,
	|	TableTypesOfStocks_.AmountARAP - TableTypesOfStocks_.AmountVATARAP AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|	CASE
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|		THEN 0
	|		ELSE TableTypesOfStocks_.ExciseAmountInCurrencyLocal
	|	END AS ExciseAmountInCurrencyLocal,
	|	CASE
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|		THEN 0
	|		ELSE TableTypesOfStocks_.ExciseAmountInCurrencyMgmt
	|	END AS ExciseAmountInCurrencyMgmt,
	|
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|	CASE
	|		WHEN &SalesViaCommissionAgent 
	|			THEN &BusinessTransactionGrounds
	|		WHEN &BusinessTransactionGrounds IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|		 AND NOT TableTypesOfStocks_.ToExpenseAs
	|			THEN &BusinessTransactionGrounds
	|		WHEN &BusinessTransactionGrounds IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|		 AND TableTypesOfStocks_.ToExpenseAs
	|			THEN VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses)
	|		ELSE VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|	END AS BusinessOperation,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		TableTypesOfStocks_.InventoryOwnerAttribute
	|	ELSE
	|		TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	TableTypesOfStocks_.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	UNDEFINED AS LotVendorAttributes,
	|	UNDEFINED AS Lot,
	|	TableTypesOfStocks_.VATRate AS VATRate
	|	
	|FROM
	|	TTTableTypesOfInventoryWriteOff AS TableTypesOfStocks_
	|WHERE
	|	(NOT TableTypesOfStocks_.ToIncomeExpenses AND NOT &SaleAdjustment2_5
	|	OR &SaleAdjustment2_5
	|		AND (NOT &RecordInProfitLossOfPreviousYears OR &AdjustTaxBaseOfPreviousPeriod))
	|	AND NOT (VALUETYPE(&DocumentBasis) = TYPE(Document.CustomerInvoiceServicesAndAssets)
	|		OR &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets))
	|	AND (ISNULL(TableTypesOfStocks_.ItemsType, UNDEFINED) <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR NOT &ToReturnReusablePackage)
	|
	|UNION ALL
	|
	// Discrepancies in services 
	|SELECT
	|	DivergenceTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	CASE 
	|		WHEN &SaleAdjustment2_5 THEN
	|			CASE 
	|				WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|					&AdjustmentPeriod_
	|				ELSE
	|					DATETIME(1,1,1,0,0,0)
	|			END
	|	ELSE
	|		DATETIME(1,1,1,0,0,0) 
	|	END AS AdjustmentPeriod_,
	|	&Department AS Department,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN DivergenceTable.ItemsLocationAttributes
	|		ELSE DivergenceTable.AnalysisOfAccountingForProductsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	DivergenceTable.SetAccountingDimension AS SetAccountingDimension,
	|	&AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|
	|	CASE WHEN &SaleByOrders THEN
	|		DivergenceTable.SalesOrder
	|	ELSE
	|		&DocumentBasis
	|	END AS SalesOrder,
	|
	|	CASE
	|		WHEN DivergenceTable.Principal <> UNDEFINED
	|		THEN VALUE(Enum.InventoryTypes.AgentService)
	|		ELSE VALUE(Enum.InventoryTypes.OperationService)
	|	END AS InventoryType,
	|	DivergenceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	(CASE
	|		WHEN DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END) AS AccountingSection,
	|	DivergenceTable.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	DivergenceTable.VATActivityType AS VATActivityType,
	|
	|	&Manager AS Manager,
	|
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN DivergenceTable.ItemsLocationAttributes.Purpose.LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS ProductLineOfBusiness,
	|
	|	(CASE
	|		WHEN DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN 0
	|		WHEN DivergenceTable.Principal <> UNDEFINED
	|			THEN DivergenceTable.AmountIncludingVATMan
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -DivergenceTable.Cost_
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN DivergenceTable.AmountIncludingVATMan
	|		ELSE 0 END) AS Cost,
	|	(CASE
	|		WHEN DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN 0
	|		WHEN DivergenceTable.Principal <> UNDEFINED
	|			THEN DivergenceTable.AmountExcludingVATMan
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -DivergenceTable.CostExcludingVAT_
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN DivergenceTable.AmountExcludingVATMan
	|		ELSE 0 END) AS CostExcludingVAT,
	|	(CASE
	|		WHEN NOT &CompanyManagementAccounting
	|			THEN 0
	|		WHEN DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN 0
	|		WHEN DivergenceTable.Principal <> UNDEFINED
	|	 		THEN DivergenceTable.AmountExcludingVATMan
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -DivergenceTable.CostExcludingVAT_
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument) 
	|		 AND DivergenceTable.VATActivityType IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN DivergenceTable.AmountIncludingVATMan
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN DivergenceTable.AmountExcludingVATMan
	|		ELSE 0	END) AS CostMan,
	|	(CASE
	|		WHEN DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN 0
	|		WHEN DivergenceTable.Principal <> UNDEFINED
	|			THEN DivergenceTable.AmountExcludingVATCompl
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -DivergenceTable.CostLocal
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument) 
	|		 AND DivergenceTable.VATActivityType IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN DivergenceTable.AmountIncludingVATCompl
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN DivergenceTable.AmountExcludingVATCompl
	|		ELSE 0	END) AS LocalCost,
	|	(CASE
	|		WHEN DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN 0
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -DivergenceTable.CDCost
	|		ELSE 0 END) AS PermanentDifference,
	|	(CASE
	|		WHEN DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN 0
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -DivergenceTable.TDCost
	|		ELSE 0 END) AS CostTD,
	|
	|	DivergenceTable.Count AS Count,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|		THEN DivergenceTable.AmountIncludingVATMan
	|		ELSE 0
	|	END AS RevenueAmount,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|		THEN DivergenceTable.AmountExcludingVATMan
	|		ELSE 0
	|	END AS RevenueAmountExcludingVAT,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|		THEN DivergenceTable.AmountExcludingVATCompl
	|		ELSE 0
	|	END AS RevenueAmountExclVATLocal,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|		THEN DivergenceTable.AmountExcludingVATCompl + DivergenceTable.VATLocal
	|		ELSE 0
	|	END AS RevenueAmountIncludingVATLocal,
	|	CASE
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|		THEN - DivergenceTable.AmountExcludingVATCompl
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|		THEN DivergenceTable.AmountExcludingVATCompl
	|		ELSE 0
	|	END AS RevenueAmountPD,
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|	DivergenceTable.Warehouse AS Warehouse,
	|	CASE WHEN &SalesViaCommissionAgent
	|		THEN &CustomerContract
	|		ELSE &Contract
	|	END AS Contract,
	|	&Terms AS Terms,
	|
	|	&ARAPCurrency AS ARAPCurrency,
	|	DivergenceTable.AmountARAP AS AmountInARAPCurrency,
	|	DivergenceTable.AmountARAP - DivergenceTable.AmountVATARAP AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	DivergenceTable.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	DivergenceTable.AmountIncludingVAT - DivergenceTable.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|	0 AS ExciseAmountInCurrencyLocal,
	|	0 AS ExciseAmountInCurrencyMgmt,
	|
	|	DivergenceTable.VATActivityType AS VATTaxation,
	|
	|	CASE
	|		WHEN &SalesViaCommissionAgent AND &LastPeriodAdjustment AND DivergenceTable.Count < 0
	|			THEN VALUE(Enum.BusinessTransactions.GoodsReturnViaCommissionAgentOfPreviousPeriods)
	|		WHEN &SalesViaCommissionAgent 
	|			THEN &BusinessTransactionGrounds
	|		WHEN &BusinessTransactionGrounds IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|		 AND NOT DivergenceTable.ToExpenseAs
	|			THEN &BusinessTransactionGrounds
	|		WHEN &BusinessTransactionGrounds IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|		 AND DivergenceTable.ToExpenseAs
	|			THEN VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses)
	|		WHEN DivergenceTable.CostDefiningMethod IN (
	|				VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|				VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN VALUE(Enum.BusinessTransactions.AdjustBeforeEnteringBalance)
	|		WHEN &LastPeriodAdjustment AND DivergenceTable.Count < 0
	|			THEN VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|		WHEN DivergenceTable.Count < 0
	|			THEN VALUE(Enum.BusinessTransactions.ReverseOfSale)
	|		ELSE VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|	END AS BusinessOperation,
	|
	|	DivergenceTable.Products AS SourceOfProductFinancialAccountingGroup,
	|	DivergenceTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	
	// The fields of the Record ID and the setting of the business operation must be filled
	// in the same way in the cost of goods and in revenue and cost of sales. The function of the Text query table for the value of goods().
	|	DivergenceTable.RowID AS FinRecordID,
	|	(CASE
	|		WHEN DivergenceTable.CostDefiningMethod IN (
	|				VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|				VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AdjustBeforeEnteringBalance)
	|		ELSE &BusinessTransactionSetting END) AS BusinessTransactionSetting,
	|	CASE
	|		WHEN &BatchAccountingVersion22
	|			AND DivergenceTable.CostDefiningMethod IN (
	|				VALUE(Enum.WaysToCalculateReturnCost.Manually), 
	|				VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN DivergenceTable.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END AS LotVendorAttributes,
	|	CASE
	|		WHEN &BatchAccountingVersion22
	|			AND DivergenceTable.CostDefiningMethod IN (
	|				VALUE(Enum.WaysToCalculateReturnCost.Manually), 
	|				VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END AS Lot,
	|	DivergenceTable.VATRate AS VATRate
	|FROM
	|	TTDivergenceOfServiceOperation AS DivergenceTable
	|WHERE
	|	(NOT DivergenceTable.ToIncomeExpenses AND NOT &SaleAdjustment2_5
	|	OR &SaleAdjustment2_5
	|		AND (NOT &RecordInProfitLossOfPreviousYears OR &AdjustTaxBaseOfPreviousPeriod))
	|	AND NOT (DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND DivergenceTable.TracedGoods)
	|	AND NOT (VALUETYPE(&DocumentBasis) = TYPE(Document.CustomerInvoiceServicesAndAssets)
	|		OR &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets))
	|
	|UNION ALL
	|
	// Types of inventory to be registered
	|SELECT
	|	InventoryKinds.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	CASE 
	|		WHEN &SaleAdjustment2_5 THEN
	|			CASE 
	|				WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|					&AdjustmentPeriod_
	|				ELSE
	|					DATETIME(1,1,1,0,0,0)
	|			END
	|	ELSE
	|		DATETIME(1,1,1,0,0,0) 
	|	END AS AdjustmentPeriod_,
	|	&Department AS Department,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.DimensionSalesOfGoodsAndServices
	|		ELSE InventoryKinds.UnassignedImplementationAnalytics
	|	END AS ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension AS SetAccountingDimension,
	|	&AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CASE WHEN &SaleByOrders THEN
	|		InventoryKinds.SalesOrder
	|	ELSE
	|		&DocumentBasis
	|	END AS SalesOrder,
	|
	|	(CASE
	|		WHEN &BusinessTransactionGrounds IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			THEN VALUE(Enum.InventoryTypes.OperationService)
	|		ELSE InventoryKinds.InventoryType END) AS InventoryType,
	|	(CASE
	|		WHEN &BusinessTransactionGrounds IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			THEN UNDEFINED
	|		WHEN InventoryKinds.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef) THEN
	|			InventoryKinds.InventoryOwnerAttributeShipment
	|		ELSE InventoryKinds.InventoryOwnerAttribute END) AS InventoryOwnerAttribute,
	|
	|	(CASE
	//		Implementation without transfer of ownership is of the Contract type - implementation, but the Contract is specified in the analytics
	|		WHEN ISNULL(InventoryKinds.ItemsLocationAttributes.Contract.ContractType, UNDEFINED) IN (VALUE(Enum.ContractTypes.WithCustomer),
	|				VALUE(Enum.ContractTypes.SalesViaCommissionAgent))
	|			AND InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent)
	|		WHEN ISNULL(InventoryKinds.ItemsLocationAttributes.Contract.ContractType, UNDEFINED) = VALUE(Enum.ContractTypes.SalesViaCommissionAgent)
	|			AND InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent)
	|		WHEN ISNULL(InventoryKinds.ItemsLocationAttributes.Contract.ContractType, UNDEFINED) = VALUE(Enum.ContractTypes.WithCustomer)
	|			AND InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit)
	|		WHEN InventoryKinds.InventoryType IN
	|		 (VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|		  VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN InventoryKinds.ShopFloorStockroom
	|		 OR InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN &BusinessTransactionGrounds IN (
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock) END) AS AccountingSection,
	|	InventoryKinds.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	InventoryKinds.VATActivityType AS VATActivityType,
	|
	|	&Manager AS Manager,
	|
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.DimensionSalesOfGoodsAndServices.Purpose.LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS ProductLineOfBusiness,
	|
	|	(CASE
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN -InventoryKinds.AmountIncludingVATMan
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -InventoryKinds.Cost_
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN -InventoryKinds.AmountIncludingVATMan
	|		ELSE 0 END) AS Cost,
	|	(CASE
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN -InventoryKinds.AmountExcludingVATMan
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -InventoryKinds.CostExcludingVAT_
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN -InventoryKinds.AmountExcludingVATMan
	|		ELSE 0 END) AS CostExcludingVAT,
	|	(CASE
	|		WHEN NOT &CompanyManagementAccounting
	|			THEN 0
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	 		THEN -InventoryKinds.AmountExcludingVATMan
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -InventoryKinds.CostExcludingVAT_
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument) 
	|		 AND InventoryKinds.VATActivityType IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN -InventoryKinds.AmountIncludingVATMan
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN -InventoryKinds.AmountExcludingVATMan
	|		ELSE 0	END) AS CostMan,
	|	(CASE
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN -InventoryKinds.AmountExcludingVATCompl
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -InventoryKinds.CostLocal
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument) 
	|		 AND InventoryKinds.VATActivityType IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN -InventoryKinds.AmountIncludingVATCompl
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN -InventoryKinds.AmountExcludingVATCompl
	|		ELSE 0	END) AS LocalCost,
	|	(CASE
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -InventoryKinds.CDCost
	|		ELSE 0 END) AS PermanentDifference,
	|	(CASE
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -InventoryKinds.TDCost
	|		ELSE 0 END) AS CostTD,
	|
	|	- InventoryKinds.Count      AS Count,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|		THEN - InventoryKinds.AmountIncludingVATMan
	|		ELSE 0
	|	END AS RevenueAmount,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|		THEN - InventoryKinds.AmountExcludingVATMan
	|		ELSE 0
	|	END AS RevenueAmountExcludingVAT,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|		THEN - InventoryKinds.AmountExcludingVATCompl
	|		ELSE 0
	|	END AS RevenueAmountExclVATLocal,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|		THEN - InventoryKinds.AmountIncludingVATCompl
	|		ELSE 0
	|	END AS RevenueAmountIncludingVATLocal,
	|	CASE
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|		THEN InventoryKinds.AmountExcludingVATCompl 
	|				- InventoryKinds.ExciseAmountInCurrencyLocal
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|		THEN - InventoryKinds.AmountExcludingVATCompl
	|				+ InventoryKinds.ExciseAmountInCurrencyLocal
	|		ELSE 0
	|	END AS RevenueAmountPD,
	|
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|	InventoryKinds.Warehouse AS Warehouse,
	|	CASE WHEN &SalesViaCommissionAgent
	|		THEN &CustomerContract
	|		ELSE &Contract
	|	END AS Contract,
	|	&Terms AS Terms,
	|
	|	&ARAPCurrency AS ARAPCurrency,
	|	-InventoryKinds.AmountARAP AS AmountInARAPCurrency,
	|	-(InventoryKinds.AmountARAP - InventoryKinds.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	-InventoryKinds.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	-(InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount) AS AmountExcludingVATInDocumentCurrency,
	|	CASE
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|		THEN 0
	|		ELSE -InventoryKinds.ExciseAmountInCurrencyLocal
	|	END AS ExciseAmountInCurrencyLocal,
	|	CASE
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|		THEN 0
	|		ELSE -InventoryKinds.ExciseAmountInCurrencyMgmt
	|	END AS ExciseAmountInCurrencyMgmt,
	|
	|	InventoryKinds.VATActivityType AS VATTaxation,
	|	CASE
	|		WHEN &SalesViaCommissionAgent AND &LastPeriodAdjustment
	|			THEN VALUE(Enum.BusinessTransactions.GoodsReturnViaCommissionAgentOfPreviousPeriods)
	|		WHEN &SalesViaCommissionAgent 
	|			THEN &BusinessTransactionGrounds
	|		WHEN InventoryKinds.CostDefiningMethod IN (
	|				VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|				VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN VALUE(Enum.BusinessTransactions.AdjustBeforeEnteringBalance)
	|		WHEN &LastPeriodAdjustment
	// When using the average sliding cost, the date of transfer of ownership should refer to the previous period.
	|		 AND (&DateOfTransferOfTitleToGoods < BEGINOFPERIOD(&Period, MONTH)
	|		 OR &DateOfTransferOfTitleToGoods = DATETIME(1,1,1)
	|		 OR NOT &MovingAverage)
	|			THEN VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|		WHEN &BusinessTransactionGrounds IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|		 AND NOT InventoryKinds.ToExpenseAs
	|			THEN &BusinessTransactionGrounds
	|		WHEN &BusinessTransactionGrounds IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|		 AND InventoryKinds.ToExpenseAs
	|			THEN VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses)
	|		ELSE VALUE(Enum.BusinessTransactions.ReverseOfSale)
	|	END AS BusinessOperation,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		InventoryKinds.InventoryOwnerAttribute
	|	ELSE
	|		InventoryKinds.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	InventoryKinds.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	
	// The fields of the Record ID and the setting of the business operation must be filled
	// in the same way in the cost of goods and in revenue and cost of sales. The function of the Text query table for the value of goods().
	|	InventoryKinds.RowID AS FinRecordID,
	|	(CASE
	|		WHEN InventoryKinds.CostDefiningMethod IN (
	|				VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|				VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AdjustBeforeEnteringBalance)
	|		WHEN &LastPeriodAdjustment
	|		THEN &BusinessTransactionSetting
	|		WHEN InventoryKinds.Warehouse <> InventoryKinds.OriginWarehouse
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSaleReturnToAnotherWarehouse)
	|		ELSE &BusinessTransactionSetting END) AS BusinessTransactionSetting,
	|	CASE
	|		WHEN &BatchAccountingVersion22
	|			AND InventoryKinds.CostDefiningMethod IN (
	|				VALUE(Enum.WaysToCalculateReturnCost.Manually), 
	|				VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN InventoryKinds.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END AS LotVendorAttributes,
	|	CASE
	|		WHEN &BatchAccountingVersion22
	|			AND InventoryKinds.CostDefiningMethod IN (
	|				VALUE(Enum.WaysToCalculateReturnCost.Manually), 
	|				VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END AS Lot,
	|	InventoryKinds.VATRate AS VATRate
	|FROM
	|	TTTableTypesOfInventoryRegistration AS InventoryKinds
	|
	|WHERE
	|	(NOT InventoryKinds.ToIncomeExpenses AND NOT &SaleAdjustment2_5
	|	OR &SaleAdjustment2_5
	|		AND (NOT &RecordInProfitLossOfPreviousYears OR &AdjustTaxBaseOfPreviousPeriod))
	|	AND (ISNULL(InventoryKinds.ItemsType, UNDEFINED) <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR NOT &ToReturnReusablePackage)
	|	AND NOT (VALUETYPE(&DocumentBasis) = TYPE(Document.CustomerInvoiceServicesAndAssets)
	|		OR &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets))
	|
	|UNION ALL
	|
	// Types of inventory to adjust revenue
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	CASE 
	|		WHEN &SaleAdjustment2_5 THEN
	|			CASE 
	|				WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|					&AdjustmentPeriod_
	|				ELSE
	|					DATETIME(1,1,1,0,0,0)
	|			END
	|	ELSE
	|		DATETIME(1,1,1,0,0,0) 
	|	END AS AdjustmentPeriod_,
	|	&Department AS Department,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.SetAccountingDimension AS SetAccountingDimension,
	|	&AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|
	|	CASE WHEN &SaleByOrders THEN
	|		TableTypesOfStocks_.SalesOrder
	|	ELSE
	|		&DocumentBasis
	|	END AS SalesOrder,
	|	(CASE
	|		WHEN &BusinessTransactionGrounds IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			THEN VALUE(Enum.InventoryTypes.OperationService)
	|		ELSE TableTypesOfStocks_.InventoryType END) AS InventoryType,
	|	(CASE
	|		WHEN &BusinessTransactionGrounds IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			THEN UNDEFINED
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute END) AS InventoryOwnerAttribute,
	|	(CASE
	//		Implementation without transfer of ownership is of the Contract type - implementation, but the Contract is specified in the analytics
	|		WHEN ISNULL(TableTypesOfStocks_.ItemsLocationAttributes.Contract.ContractType, UNDEFINED) IN (VALUE(Enum.ContractTypes.WithCustomer),
	|				VALUE(Enum.ContractTypes.SalesViaCommissionAgent))
	|			AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent)
	|		WHEN ISNULL(TableTypesOfStocks_.ItemsLocationAttributes.Contract.ContractType, UNDEFINED) = VALUE(Enum.ContractTypes.SalesViaCommissionAgent)
	|			AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent)
	|		WHEN ISNULL(TableTypesOfStocks_.ItemsLocationAttributes.Contract.ContractType, UNDEFINED) = VALUE(Enum.ContractTypes.WithCustomer)
	|			AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit)
	|		WHEN TableTypesOfStocks_.InventoryType IN
	|		 (VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|		  VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN TableTypesOfStocks_.ShopFloorStockroom
	|		 OR TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN &BusinessTransactionGrounds IN (
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock) END) AS AccountingSection,
	|	TableTypesOfStocks_.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	TableTypesOfStocks_.VATActivityType AS VATActivityType,
	|
	|	&Manager AS Manager,
	|
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS ProductLineOfBusiness,
	|
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|		TableTypesOfStocks_.AmountIncludingVATMan
	|	ELSE
	|		0
	|	END AS Cost,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|		TableTypesOfStocks_.AmountExcludingVATMan
	|	ELSE
	|		0
	|	END AS CostExcludingVAT,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	 AND &CompanyManagementAccounting THEN
	|		TableTypesOfStocks_.AmountExcludingVATMan
	|	ELSE
	|		0
	|	END AS CostMan,
	|
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|		TableTypesOfStocks_.AmountExcludingVATCompl
	|	ELSE
	|		0
	|	END AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	0	AS Count,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END AS RevenueAmount,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|		THEN TableTypesOfStocks_.AmountExcludingVATMan
	|		ELSE 0
	|	END AS RevenueAmountExcludingVAT,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|		THEN TableTypesOfStocks_.AmountExcludingVATCompl
	|		ELSE 0
	|	END AS RevenueAmountExclVATLocal,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|		THEN TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATLocal
	|		ELSE 0
	|	END AS RevenueAmountIncludingVATLocal,
	|	CASE
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|		THEN - TableTypesOfStocks_.AmountExcludingVATCompl
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|		THEN TableTypesOfStocks_.AmountExcludingVATCompl
	|		ELSE 0
	|	END AS RevenueAmountPD,
	|
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	CASE WHEN &SalesViaCommissionAgent
	|		THEN &CustomerContract
	|		ELSE &Contract
	|	END AS Contract,
	|	&Terms AS Terms,
	|
	|	&ARAPCurrency AS ARAPCurrency,
	|	TableTypesOfStocks_.AmountARAP AS AmountInARAPCurrency,
	|	TableTypesOfStocks_.AmountARAP - TableTypesOfStocks_.AmountVATARAP AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|	0 AS ExciseAmountInCurrencyLocal,
	|	0 AS ExciseAmountInCurrencyMgmt,
	|
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|	CASE
	|		WHEN &SalesViaCommissionAgent
	|			THEN &BusinessTransactionGrounds
	|		WHEN &BusinessTransactionGrounds IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			THEN &BusinessTransactionGrounds
	|		ELSE VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|	END AS BusinessOperation,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		TableTypesOfStocks_.InventoryOwnerAttribute
	|	ELSE
	|		TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	TableTypesOfStocks_.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	UNDEFINED AS LotVendorAttributes,
	|	UNDEFINED AS Lot,
	|	TableTypesOfStocks_.VATRate AS VATRate
	|	
	|FROM
	|	TTInventoryTypesRevenueAdjustment AS TableTypesOfStocks_
	|
	|WHERE
	|	(NOT &SaleAdjustment2_5
	|	OR &SaleAdjustment2_5
	|		AND (NOT &RecordInProfitLossOfPreviousYears OR &AdjustTaxBaseOfPreviousPeriod))
	|	AND (TableTypesOfStocks_.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|	OR (TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage) AND NOT &ToReturnReusablePackage)
	|	OR TableTypesOfStocks_.ItemsType IS NULL)
	|	AND NOT (VALUETYPE(&DocumentBasis) = TYPE(Document.CustomerInvoiceServicesAndAssets)
	|		OR &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets))
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region GroupingDiscrepancies
	
	If DocumentsPosting.RequiresTableForRegisteredRecords("CustomersARAPAccounting", Registers) Then
		
		TextGroupedDiscrepancies =
		"SELECT
		|	DocumentHeader.Ref AS Ref,
		|	DocumentHeader.Date AS RecorderDate,
		|	DocumentHeader.Number AS RecorderNumber,
		|	DocumentHeader.Organization AS Organization,
		|	DocumentHeader.DocumentBasis AS LinkedDocument,
		|	CASE
		|		WHEN &BusinessTransactionGrounds IN (VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|		AND &ConductARAPAccountingThroughEndCustomers
		|			THEN DocumentHeader.CustomerPartner
		|		ELSE DocumentHeader.Partner
		|	END AS Partner,
		|	DocumentHeader.PaymentDate AS PaymentDate,
		|	DocumentHeader.DocumentBasis.Date AS DateOfCourse,
		|	DocumentHeader.SaleByOrders AS InvoiceForOrders,
		|	DocumentHeader.ARAPObjectSettings AS ARAPObjectSettings,
		|	DocumentHeader.Currency AS DocumentCurrency,
		|	DocumentHeader.ARAPCurrency AS ARAPCurrency,
		|	DocumentHeader.PaymentMethod AS PaymentMethod,
		|	Table.ARAPObject AS ARAPObject,
		|	Table.SalesOrder AS SalesOrder_,
		|	Table.Products AS Products,
		|	SUM(Table.AmountARAP) AS AmountARAP,
		|	SUM(Table.AmountIncludingVAT) AS AmountIncludingVAT
		|INTO TTGroupedDiscrepancies
		|FROM
		|	Document.SaleAdjustment AS DocumentHeader
		|		INNER JOIN Document.SaleAdjustment.Discrepancies AS Table
		|		ON DocumentHeader.Ref = Table.Ref
		|WHERE
		|	DocumentHeader.Ref IN (&Ref)
		|	AND DocumentHeader.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|GROUP BY
		|	DocumentHeader.Ref,
		|	DocumentHeader.PaymentDate,
		|	DocumentHeader.Organization,
		|	CASE
		|		WHEN &BusinessTransactionGrounds IN (VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|		AND &ConductARAPAccountingThroughEndCustomers
		|			THEN DocumentHeader.CustomerPartner
		|		ELSE DocumentHeader.Partner
		|	END,
		|	DocumentHeader.SaleByOrders,
		|	DocumentHeader.ARAPObjectSettings,
		|	DocumentHeader.Date,
		|	DocumentHeader.Number,
		|	DocumentHeader.ARAPCurrency,
		|	DocumentHeader.DocumentBasis.Date,
		|	DocumentHeader.Currency,
		|	DocumentHeader.DocumentBasis,
		|	DocumentHeader.PaymentMethod,
		|	Table.ARAPObject,
		|	Table.SalesOrder,
		|	Table.Products
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentHeader.Ref AS Ref,
		|	DocumentHeader.Date AS RecorderDate,
		|	DocumentHeader.Number AS RecorderNumber,
		|	DocumentHeader.Organization AS Organization,
		|	DocumentHeader.DocumentBasis AS LinkedDocument,
		|	CASE
		|		WHEN &BusinessTransactionGrounds IN (VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|		AND &ConductARAPAccountingThroughEndCustomers
		|			THEN DocumentHeader.CustomerPartner
		|		ELSE DocumentHeader.Partner
		|	END AS Partner,
		|	DocumentHeader.PaymentDate AS PaymentDate,
		|	DocumentHeader.DocumentBasis.Date AS DateOfCourse,
		|	DocumentHeader.SaleByOrders AS InvoiceForOrders,
		|	DocumentHeader.ARAPObjectSettings AS ARAPObjectSettings,
		|	DocumentHeader.Currency AS DocumentCurrency,
		|	DocumentHeader.ARAPCurrency AS ARAPCurrency,
		|	DocumentHeader.PaymentMethod AS PaymentMethod,
		|	Table.ARAPObject AS ARAPObject,
		|	Table.SalesOrder AS SalesOrder_,
		|	Table.Products AS Products,
		|	Table.AmountARAP AS AmountARAP,
		|	Table.AmountIncludingVAT AS AmountIncludingVAT
		|FROM
		|	Document.SaleAdjustment AS DocumentHeader
		|		INNER JOIN Document.SaleAdjustment.Discrepancies AS Table
		|		ON DocumentHeader.Ref = Table.Ref
		|WHERE
		|	DocumentHeader.Ref IN (&Ref)
		|	AND DocumentHeader.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)";
		
		QueryTexts.Add(TextGroupedDiscrepancies);
		
	EndIf;
	
	#EndRegion
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT DISTINCT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.DocumentBasis.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.SaleAdjustment.Discrepancies AS Table
		|		LEFT JOIN Document.SaleAdjustment AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
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
		|	Document.SaleAdjustment.ARAPAdjustment AS Table
		|		LEFT JOIN Document.SaleAdjustment AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region DiscrepanciesInPlus
	
	#Region Sale
	
	TextSale =
	"SELECT
	|	Table.Ref AS Ref,
	|	Table.Organization AS Organization,
	|	Table.Partner AS Partner,
	|	Table.ARAPObject AS ARAPObject,
	|	Table.PaymentDate AS PaymentDate,
	|	Table.SalesOrder_ AS SalesOrder_,
	|	Table.InvoiceForOrders AS InvoiceForOrders,
	|	CASE WHEN ProductsTable.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR NOT CASE WHEN Table.LinkedDocument REFS Document.CustomerInvoice
	|					THEN Table.LinkedDocument.ToReturnReusablePackage
	|				ELSE TRUE
	|			END
	|		OR CASE WHEN Table.LinkedDocument REFS Document.CustomerInvoice
	|					THEN Table.LinkedDocument.PackageDepositIsRequired
	|				ELSE TRUE
	|			END
	|			THEN Table.AmountARAP
	|		ELSE 0
	|	END AS AmountARAP,
	|	CASE WHEN ProductsTable.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		AND CASE WHEN Table.LinkedDocument REFS Document.CustomerInvoice
	|					THEN Table.LinkedDocument.PackageDepositIsRequired
	|				ELSE FALSE
	|			END
	|			THEN Table.AmountARAP
	|		ELSE 0
	|	END AS AmountARAPByPackage,
	|	Table.AmountIncludingVAT AS Sum,
	|	Table.ARAPObjectSettings AS ARAPObjectSettings,
	|	Table.RecorderDate AS RecorderDate,
	|	Table.RecorderNumber AS RecorderNumber,
	|	Table.ARAPCurrency AS ARAPCurrency,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	Table.DateOfCourse AS DateOfCourse,
	|	Table.DocumentCurrency AS DocumentCurrency,
	|	UNDEFINED AS PaymentOption,
	|	TRUE AS ExceedingOrder,
	|	Table.LinkedDocument AS LinkedDocument
	|FROM
	|	TTGroupedDiscrepancies AS Table
	|		LEFT JOIN Catalog.Products AS ProductsTable
	|		ON Table.Products = ProductsTable.Ref
	|WHERE
	|	Table.AmountIncludingVAT > 0
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref                                                           AS Ref,
	|	Table.Ref.Organization                                               AS Organization,
	|	CASE WHEN &BusinessTransactionGrounds IN (
	|					VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|					VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|				AND &ConductARAPAccountingThroughEndCustomers
	|			THEN Table.Ref.CustomerPartner
	|		ELSE Table.Ref.Partner
	|	END                                                                    AS Partner,
	|	
	|	Table.ARAPObject                                                   AS ARAPObject,
	|	Table.Ref.PaymentDate                                               AS PaymentDate,
	|	UNDEFINED                                                             AS SalesOrder_,
	|	FALSE                                                                     AS InvoiceForOrders,
	|	Table.AmountARAP                                              AS AmountARAP,
	|	0                                                                        AS AmountARAPByPackage,
	|	Table.AdjustmentSum                                               AS Sum,
	|	
	|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
	|	Table.Ref.Date                                                      AS RecorderDate,
	|	Table.Ref.Number                                                     AS RecorderNumber,
	|	Table.Ref.ARAPCurrency                                      AS ARAPCurrency,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment)  AS BusinessOperation,
	|	Table.Ref.Date                                                      AS DateOfCourse,
	|	Table.Ref.Currency                                                    AS DocumentCurrency,
	|	UNDEFINED                                                             AS PaymentOption,
	|	FALSE                                                                     AS ExceedingOrder,
	|	UNDEFINED                                                             AS LinkedDocument
	|FROM
	|	Document.SaleAdjustment.ARAPAdjustment AS Table
	|WHERE
	|	Table.Ref IN (&Ref)
	|	AND Table.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated)";
	
	#EndRegion
	
	#Region IncreasePaymentPlan
	
	TextPaymentPlanning =
	"SELECT
	|	Table.Ref AS Ref,
	|	Table.Organization AS Organization,
	|	Table.Partner AS Partner,
	|	Table.ARAPObject AS ARAPObject,
	|	Table.RecorderDate AS RecorderDate,
	|	Table.RecorderNumber AS RecorderNumber,
	|	Table.ARAPObjectSettings AS ARAPObjectSettings,
	|	Table.ARAPCurrency AS ARAPCurrency,
	|	Table.DocumentCurrency AS DocumentCurrency,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	Table.PaymentMethod AS PaymentMethod,
	|	Table.PaymentDate AS PaymentDate,
	|	UNDEFINED AS PaymentOption,
	|	Table.AmountARAP AS AmountDue,
	|	TRUE AS ExcludeDuringControl,
	|	Table.InvoiceForOrders AS InvoiceForOrders,
	|	Table.SalesOrder_ AS SalesOrder_,
	|	TRUE AS ExceedingOrder,
	|	Table.LinkedDocument AS LinkedDocument
	|FROM
	|	TTGroupedDiscrepancies AS Table
	|		LEFT JOIN Catalog.Products AS ProductsTable
	|		ON Table.Products = ProductsTable.Ref
	|WHERE
	|	Table.AmountIncludingVAT > 0
	|	AND (ProductsTable.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR ProductsTable.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND CASE WHEN Table.LinkedDocument REFS Document.CustomerInvoice
	|						THEN Table.LinkedDocument.PackageDepositIsRequired
	|					ELSE FALSE
	|				END
	|		OR NOT CASE WHEN Table.LinkedDocument REFS Document.CustomerInvoice
	|					THEN Table.LinkedDocument.ToReturnReusablePackage
	|				ELSE FALSE
	|				END
	|		OR ProductsTable.ItemsType IS NULL)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref                                                           AS Ref,
	|	Table.Ref.Organization                                               AS Organization,
	|	CASE WHEN &BusinessTransactionGrounds IN (
	|					VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|					VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|				AND &ConductARAPAccountingThroughEndCustomers
	|			THEN Table.Ref.CustomerPartner
	|		ELSE Table.Ref.Partner
	|	END                                                                    AS Partner,
	|	
	|	Table.ARAPObject                                                   AS ARAPObject,
	|	Table.Ref.Date                                                      AS RecorderDate,
	|	Table.Ref.Number                                                     AS RecorderNumber,
	|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
	|	Table.Ref.ARAPCurrency                                      AS ARAPCurrency,
	|	Table.Ref.Currency                                                    AS DocumentCurrency,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment)  AS BusinessOperation,
	|	Table.Ref.PaymentMethod                                               AS PaymentMethod,
	|	
	|	Table.Ref.PaymentDate                                               AS PaymentDate,
	|	UNDEFINED                                                             AS PaymentOption,
	|	Table.AmountARAP                                              AS AmountDue,
	|		
	|	TRUE                                                                   AS ExcludeDuringControl,
	|	FALSE                                                                     AS InvoiceForOrders,
	|	UNDEFINED                                                             AS SalesOrder_,
	|	TRUE                                                                   AS ExceedingOrder,
	|	UNDEFINED                                                             AS LinkedDocument
	|	
	|FROM
	|	Document.SaleAdjustment.ARAPAdjustment AS Table
	|WHERE
	|	Table.Ref IN (&Ref)
	|	AND Table.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated)";
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, TextSale, TextPaymentPlanning);
	
	#EndRegion
	
	#Region DiscrepanciesInMinus
		
	TextPayment = 
	"SELECT
	|	Table.Ref AS Ref,
	|	Table.Organization AS Organization,
	|	Table.Partner AS Partner,
	|	Table.ARAPCurrency AS ARAPCurrency,
	|	Table.ARAPObject AS ARAPObject,
	|	-Table.AmountIncludingVAT AS Sum,
	|	-Table.AmountARAP AS AmountARAP,
	|	0 AS IncreaseIsPaid,
	|	0 AS ReductionIsPaid,
	|	Table.RecorderDate AS RecorderDate,
	|	Table.DateOfCourse AS DateOfCourse,
	|	DATETIME(1,1,1) AS MaturityDate,
	|	Table.RecorderNumber AS RecorderNumber,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	Table.PaymentMethod AS PaymentMethod,
	|	UNDEFINED AS CashFlowItem,
	|	UNDEFINED AS ProformaInvoice,
	|	Table.DocumentCurrency AS DocumentCurrency,
	|	Table.LinkedDocument AS LinkedDocument,
	|	Table.ARAPObject.UUID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting
	|FROM
	|	TTGroupedDiscrepancies AS Table
	|		LEFT JOIN Catalog.Products AS ProductsTable
	|		ON Table.Products = ProductsTable.Ref
	|WHERE
	|	Table.AmountIncludingVAT < 0
	|	AND (ProductsTable.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR ProductsTable.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND CASE WHEN Table.LinkedDocument REFS Document.CustomerInvoice
	|						THEN Table.LinkedDocument.PackageDepositIsRequired
	|					ELSE FALSE
	|				END
	|		OR NOT CASE WHEN Table.LinkedDocument REFS Document.CustomerInvoice
	|					THEN Table.LinkedDocument.ToReturnReusablePackage
	|				ELSE FALSE
	|				END
	|		OR ProductsTable.ItemsType IS NULL)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref                                                           AS Ref,
	|	Table.Ref.Organization                                               AS Organization,
	|	CASE WHEN &BusinessTransactionGrounds IN (
	|					VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|					VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|				AND &ConductARAPAccountingThroughEndCustomers
	|			THEN Table.Ref.CustomerPartner
	|		ELSE Table.Ref.Partner
	|	END                                                                    AS Partner,
	|	
	|	Table.Ref.ARAPCurrency                                      AS ARAPCurrency,
	|	Table.ARAPObject                                                   AS ARAPObject,
	|	
	|	Table.AdjustmentSum                                               AS Sum,
	|	Table.AmountARAP                                              AS AmountARAP,
	|	0                                                                        AS IncreaseIsPaid,
	|	0                                                                        AS ReductionIsPaid,
	|	
	|	Table.Ref.Date                                                      AS RecorderDate,
	|	Table.Ref.Date                                                      AS DateOfCourse,
	|	DATETIME(1,1,1)                                                         AS MaturityDate,
	|	Table.Ref.Number                                                     AS RecorderNumber,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment)  AS BusinessOperation,
	|	Table.Ref.PaymentMethod                                               AS PaymentMethod,
	|	UNDEFINED                                                             AS CashFlowItem,
	|	UNDEFINED                                                             AS ProformaInvoice,
	|	Table.Ref.Currency                                                    AS DocumentCurrency,
	|	UNDEFINED                                                             AS LinkedDocument,
	|	Table.ARAPObject.UUID                           AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)         AS BusinessTransactionSetting
	|FROM
	|	Document.SaleAdjustment.ARAPAdjustment AS Table
	|WHERE
	|	Table.Ref IN (&Ref)
	|	AND Table.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated)";
		
	ARAPAccountingPostingCustomers.CarryingOutPaymentFromClient(Query, QueryTexts, Registers, TextPayment, "3");
		
	#EndRegion
	
EndProcedure

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";

	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryWriteOff", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryWriteOff(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDivergenceTable", QueryTexts) Then
		QueryTextTTDivergenceTable(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableDebtAdjustment", QueryTexts) Then
		QueryTextTTTableDebtAdjustment(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryRegistration", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInventoryTypesRevenueAdjustment", QueryTexts) Then
		QueryTextTTInventoryTypesRevenueAdjustment(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber         AS LineNumber,
	|	&Period                                AS Period,
	|	CASE 
	|		WHEN &SaleAdjustment2_5 THEN
	|			CASE 
	|				WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|					&AdjustmentPeriod_
	|				ELSE
	|					DATETIME(1,1,1,0,0,0)
	|			END
	|	ELSE
	|		DATETIME(1,1,1,0,0,0) 
	|	END                                  AS AdjustmentPeriod_,
	|	&Organization                           AS Organization,
	|	CASE
	|		WHEN &SaleAdjustment2_5
	|			THEN &Department
	|		ELSE &BusinessUnit
	|	END                                  AS Department,
	|	CASE
	|		WHEN
	|			TableTypesOfStocks_.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|				VALUE(Enum.ItemsTypes.ReusablePackage))
	|		THEN
	|			TableTypesOfStocks_.LineOfBusiness
	|		ELSE
	|			&LineOfBusiness
	|	END                                  AS LineOfBusiness,
	|	CASE
	|		WHEN &AdjustmentOfPreviousPeriodYear 
	|			AND &SaleAdjustment2_5
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ProfitLossOfPreviousYears)
	|			ELSE &IncomeItem
	|	END                                  AS IncomeItem,
	|	&DimensionOfRevenue                      AS DimensionOfRevenue,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|			THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0 END AS Sum,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			AND (NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears)
	|			THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0 END AS SumMan,
	|	CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting 
	|			AND (NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears)
	|			THEN TableTypesOfStocks_.AmountIncludingVATCompl
	|		ELSE 0 END AS SumCompl,
	|	CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			OR NOT &SaleAdjustment2_5
	|			THEN 0
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|			THEN - TableTypesOfStocks_.AmountIncludingVATCompl
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN TableTypesOfStocks_.AmountIncludingVATCompl
	|		ELSE 0
	|	END AS PermanentDifference,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	
	|	TableTypesOfStocks_.ARAPObject.UUID AS FinRecordID,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ARAPAdjustment) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTTableTypesOfInventoryWriteOff AS TableTypesOfStocks_
	|WHERE
	|	(TableTypesOfStocks_.ToIncomeExpenses AND NOT &SaleAdjustment2_5
	|		OR &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear
	|			AND (&RecordInProfitLossOfPreviousYears
	|				OR NOT &AdjustTaxBaseOfPreviousPeriod))
	|	AND TableTypesOfStocks_.AmountIncludingVATMan > 0
	|	AND &UseAccountingOfOtherIncomeExpenses
	|	AND TableTypesOfStocks_.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber         AS LineNumber,
	|	&Period                                AS Period,
	|	CASE 
	|		WHEN &SaleAdjustment2_5 THEN
	|			CASE 
	|				WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|					&AdjustmentPeriod_
	|				ELSE
	|					DATETIME(1,1,1,0,0,0)
	|			END
	|	ELSE
	|		DATETIME(1,1,1,0,0,0) 
	|	END                                  AS AdjustmentPeriod_,
	|	&Organization                           AS Organization,
	|	CASE
	|		WHEN &SaleAdjustment2_5
	|			THEN &Department
	|		ELSE &BusinessUnit
	|	END                                  AS Department,
	|	CASE
	|		WHEN
	|			TableTypesOfStocks_.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|				VALUE(Enum.ItemsTypes.ReusablePackage))
	|		THEN
	|			TableTypesOfStocks_.LineOfBusiness
	|		ELSE
	|			&LineOfBusiness
	|	END                                  AS LineOfBusiness,
	|	CASE
	|		WHEN &AdjustmentOfPreviousPeriodYear
	|			AND &SaleAdjustment2_5
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ProfitLossOfPreviousYears)
	|			ELSE &IncomeItem
	|	END                                  AS IncomeItem,
	|	&DimensionOfRevenue                      AS DimensionOfRevenue,
	|	0                                      AS Sum,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			AND (NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears)
	|			THEN -TableTypesOfStocks_.VATManag 
	|				- TableTypesOfStocks_.ExciseAmountInCurrencyMgmt
	|		ELSE 0 END AS SumMan,
	|	CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			AND (NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears)
	|			THEN -TableTypesOfStocks_.VATLocal 
	|				- TableTypesOfStocks_.ExciseAmountInCurrencyLocal
	|		ELSE 0 END AS SumCompl,
	|	CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			OR NOT &SaleAdjustment2_5
	|			THEN 0
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|			THEN TableTypesOfStocks_.VATLocal 
	|			+ TableTypesOfStocks_.ExciseAmountInCurrencyLocal
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN - TableTypesOfStocks_.VATLocal 
	|				- TableTypesOfStocks_.ExciseAmountInCurrencyLocal
	|		ELSE 0
	|	END AS PermanentDifference,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTTableTypesOfInventoryWriteOff AS TableTypesOfStocks_
	|WHERE
	|	(TableTypesOfStocks_.ToIncomeExpenses AND NOT &SaleAdjustment2_5
	|		OR &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear
	|			AND (&RecordInProfitLossOfPreviousYears
	|				OR NOT &AdjustTaxBaseOfPreviousPeriod))
	|	AND TableTypesOfStocks_.AmountIncludingVATMan > 0
	|	AND &UseAccountingOfOtherIncomeExpenses
	|	AND TableTypesOfStocks_.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber         AS LineNumber,
	|	&Period                                AS Period,
	|	CASE
	|		WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|			&AdjustmentPeriod_
	|		ELSE
	|			DATETIME(1,1,1,0,0,0)
	|	END AS AdjustmentPeriod_,
	|	&Organization                           AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.ProfitLossOfPreviousYears) AS IncomeItem,
	|	&DimensionOfRevenue                      AS DimensionOfRevenue,
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|		THEN - TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0 END AS Sum,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			AND &RecordInProfitLossOfPreviousYears
	|			THEN - TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0 END AS SumMan,
	|	CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			AND &RecordInProfitLossOfPreviousYears
	|			THEN - TableTypesOfStocks_.AmountIncludingVATCompl
	|		ELSE 0 END AS SumCompl,
	|	CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN 0
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|			THEN TableTypesOfStocks_.AmountIncludingVATCompl
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN - TableTypesOfStocks_.AmountIncludingVATCompl
	|		ELSE 0
	|	END AS PermanentDifference,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	
	|	TableTypesOfStocks_.ARAPObject.UUID AS FinRecordID,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ARAPAdjustment) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTTableTypesOfInventoryRegistration AS TableTypesOfStocks_
	|WHERE
	|	&SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear
	|	AND TableTypesOfStocks_.AmountIncludingVATMan < 0 
	|	AND (&RecordInProfitLossOfPreviousYears OR NOT &AdjustTaxBaseOfPreviousPeriod)
	|	AND &UseAccountingOfOtherIncomeExpenses
	|	AND TableTypesOfStocks_.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber         AS LineNumber,
	|	&Period                                AS Period,
	|	CASE
	|		WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|			&AdjustmentPeriod_
	|		ELSE
	|			DATETIME(1,1,1,0,0,0)
	|	END AS AdjustmentPeriod_,
	|	&Organization                           AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.ProfitLossOfPreviousYears) AS IncomeItem,
	|	&DimensionOfRevenue                      AS DimensionOfRevenue,
	|	0                                      AS Sum,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			AND &RecordInProfitLossOfPreviousYears
	|			THEN TableTypesOfStocks_.VATManag 
	|				+ TableTypesOfStocks_.ExciseAmountInCurrencyMgmt
	|		ELSE 0 END AS SumMan,
	|	CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			AND &RecordInProfitLossOfPreviousYears
	|			THEN TableTypesOfStocks_.VATLocal 
	|				+ TableTypesOfStocks_.ExciseAmountInCurrencyLocal
	|		ELSE 0 END AS SumCompl, 
	|	CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN 0
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|			THEN - TableTypesOfStocks_.VATLocal 
	|					- TableTypesOfStocks_.ExciseAmountInCurrencyLocal
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN TableTypesOfStocks_.VATLocal 
	|				+ TableTypesOfStocks_.ExciseAmountInCurrencyLocal
	|		ELSE 0
	|	END AS PermanentDifference,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTTableTypesOfInventoryRegistration AS TableTypesOfStocks_
	|WHERE
	|	&SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear
	|	AND TableTypesOfStocks_.AmountIncludingVATMan < 0
	|	AND (&RecordInProfitLossOfPreviousYears OR NOT &AdjustTaxBaseOfPreviousPeriod)
	|	AND &UseAccountingOfOtherIncomeExpenses
	|	AND TableTypesOfStocks_.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|	
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber         AS LineNumber,
	|	&Period                                AS Period,
	|	CASE
	|		WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|			&AdjustmentPeriod_
	|		ELSE
	|			DATETIME(1,1,1,0,0,0)
	|	END AS AdjustmentPeriod_,
	|	&Organization                           AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.ProfitLossOfPreviousYears) AS IncomeItem,
	|	&DimensionOfRevenue                      AS DimensionOfRevenue,
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0 END AS Sum,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			AND &RecordInProfitLossOfPreviousYears
	|			THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0 END AS SumMan,
	|	CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			AND &RecordInProfitLossOfPreviousYears
	|			THEN TableTypesOfStocks_.AmountIncludingVATCompl
	|		ELSE 0 END AS SumCompl, 
	|	CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN 0
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|			THEN - TableTypesOfStocks_.AmountIncludingVATCompl
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN TableTypesOfStocks_.AmountIncludingVATCompl
	|		ELSE 0
	|	END AS PermanentDifference,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	
	|	TableTypesOfStocks_.ARAPObject.UUID AS FinRecordID,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ARAPAdjustment) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTInventoryTypesRevenueAdjustment AS TableTypesOfStocks_
	|WHERE
	|	&SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear
	|	AND TableTypesOfStocks_.AmountIncludingVATMan > 0 
	|	AND (&RecordInProfitLossOfPreviousYears OR NOT &AdjustTaxBaseOfPreviousPeriod)
	|	AND &UseAccountingOfOtherIncomeExpenses
	|	AND TableTypesOfStocks_.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber         AS LineNumber,
	|	&Period                                AS Period,
	|	CASE
	|		WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|			&AdjustmentPeriod_
	|		ELSE
	|			DATETIME(1,1,1,0,0,0)
	|	END AS AdjustmentPeriod_,
	|	&Organization                           AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.ProfitLossOfPreviousYears) AS IncomeItem,
	|	&DimensionOfRevenue                      AS DimensionOfRevenue,
	|	0                                      AS Sum,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			AND &RecordInProfitLossOfPreviousYears
	|			THEN - (TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.AmountExcludingVATMan)
	|		ELSE 0 END AS SumMan,
	|	CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			AND &RecordInProfitLossOfPreviousYears
	|			THEN - TableTypesOfStocks_.VATLocal
	|		ELSE 0 END AS SumCompl,
	|	CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN 0
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|			THEN TableTypesOfStocks_.VATLocal
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN - TableTypesOfStocks_.VATLocal
	|		ELSE 0
	|	END AS PermanentDifference,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTInventoryTypesRevenueAdjustment AS TableTypesOfStocks_
	|WHERE
	|	&SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear
	|	AND TableTypesOfStocks_.AmountIncludingVATMan > 0
	|	AND (&RecordInProfitLossOfPreviousYears OR NOT &AdjustTaxBaseOfPreviousPeriod)
	|	AND &UseAccountingOfOtherIncomeExpenses
	|	AND TableTypesOfStocks_.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|	
	|UNION ALL
	|
	|SELECT
	|	DivergenceTable.LineNumber         AS LineNumber,
	|	&Period                                AS Period,
	|	CASE 
	|		WHEN &SaleAdjustment2_5 THEN
	|			CASE 
	|				WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|					&AdjustmentPeriod_
	|				ELSE
	|					DATETIME(1,1,1,0,0,0)
	|			END
	|	ELSE
	|		DATETIME(1,1,1,0,0,0) 
	|	END                                  AS AdjustmentPeriod_,
	|	&Organization                           AS Organization,
	|	CASE
	|		WHEN &SaleAdjustment2_5
	|			THEN &Department
	|		ELSE &BusinessUnit
	|	END                                  AS Department,
	|	&LineOfBusiness               AS LineOfBusiness,
	|	CASE
	|		WHEN &AdjustmentOfPreviousPeriodYear 
	|			AND &SaleAdjustment2_5
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ProfitLossOfPreviousYears)
	|			ELSE &IncomeItem
	|	END                                  AS IncomeItem,
	|	&DimensionOfRevenue                      AS DimensionOfRevenue, 
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|		THEN DivergenceTable.AmountIncludingVATMan
	|		ELSE 0 END AS Sum,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			AND (NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears)
	|			THEN DivergenceTable.AmountIncludingVATMan
	|		ELSE 0 END AS SumMan,
	|	CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting 
	|			AND (NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears)
	|			THEN DivergenceTable.AmountIncludingVATCompl
	|		ELSE 0 END AS SumCompl,
	|	CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			OR NOT &SaleAdjustment2_5
	|			THEN 0
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|			THEN - DivergenceTable.AmountIncludingVATCompl
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN DivergenceTable.AmountIncludingVATCompl
	|		ELSE 0
	|	END AS PermanentDifference,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	
	|	DivergenceTable.ARAPObject.UUID AS FinRecordID,
	|	DivergenceTable.RowID AS RowID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ARAPAdjustment) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTDivergenceTable AS DivergenceTable
	|	INNER JOIN Document.SaleAdjustment AS DocumentData
	|		ON DocumentData.Ref = DivergenceTable.Ref
	|WHERE
	|	&UseAccountingOfOtherIncomeExpenses
	|	AND (DivergenceTable.OnIncome AND NOT &SaleAdjustment2_5
	|		AND (CASE 
	|			WHEN &ThisIsAdjustmentToSaleOfServicesOfOtherAssets THEN
	|				NOT &AdjustmentOfPreviousPeriodYear
	|			ELSE TRUE END)
	|		OR &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear
	|			AND (&RecordInProfitLossOfPreviousYears
	|				OR NOT &AdjustTaxBaseOfPreviousPeriod))
	|	AND DivergenceTable.AmountIncludingVATMan > 0
	|	AND NOT ISNULL(DivergenceTable.Products.ItemsType, UNDEFINED) IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND NOT DivergenceTable.ThisIsTraceableWork
	|
	|UNION ALL
	|
	|SELECT
	|	DivergenceTable.LineNumber         AS LineNumber,
	|	&Period                                AS Period,
	|	CASE 
	|		WHEN &SaleAdjustment2_5 THEN
	|			CASE 
	|				WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|					&AdjustmentPeriod_
	|				ELSE
	|					DATETIME(1,1,1,0,0,0)
	|			END
	|	ELSE
	|		DATETIME(1,1,1,0,0,0) 
	|	END                                  AS AdjustmentPeriod_,
	|	&Organization                           AS Organization,
	|	CASE
	|		WHEN &SaleAdjustment2_5
	|			THEN &Department
	|		ELSE &BusinessUnit
	|	END                                  AS Department,
	|	&LineOfBusiness               AS LineOfBusiness,
	|	CASE
	|		WHEN &AdjustmentOfPreviousPeriodYear 
	|			AND &SaleAdjustment2_5
	|			THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.ProfitLossOfPreviousYears)
	|			ELSE &IncomeItem
	|	END                                  AS IncomeItem,
	|	&DimensionOfRevenue                      AS DimensionOfRevenue,
	|	0                                      AS Sum,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			AND (NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears)
	|			THEN -DivergenceTable.VATManag
	|		ELSE 0 END AS SumMan,
	|	CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			AND (NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears)
	|			THEN -DivergenceTable.VATLocal
	|		ELSE 0 END AS SumCompl,
	|	CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			OR NOT &SaleAdjustment2_5
	|			THEN 0
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|			THEN DivergenceTable.VATLocal
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN -DivergenceTable.VATLocal
	|		ELSE 0
	|	END AS PermanentDifference,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	
	|	DivergenceTable.RowID AS FinRecordID,
	|	DivergenceTable.RowID AS RowID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTDivergenceTable AS DivergenceTable
	|	INNER JOIN Document.SaleAdjustment AS DocumentData
	|		ON DocumentData.Ref = DivergenceTable.Ref
	|WHERE
	|	&UseAccountingOfOtherIncomeExpenses
	|	AND (DivergenceTable.OnIncome AND NOT &SaleAdjustment2_5
	|		AND (CASE 
	|			WHEN &ThisIsAdjustmentToSaleOfServicesOfOtherAssets THEN
	|				NOT &AdjustmentOfPreviousPeriodYear
	|			ELSE TRUE END)
	|		OR &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear
	|			AND (&RecordInProfitLossOfPreviousYears
	|				OR NOT &AdjustTaxBaseOfPreviousPeriod))
	|	AND DivergenceTable.AmountIncludingVATMan > 0
	|	AND NOT ISNULL(DivergenceTable.Products.ItemsType, UNDEFINED) IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND NOT DivergenceTable.ThisIsTraceableWork
	|
	|UNION ALL
	|
	|SELECT
	|	ARAPAdjustment.LineNumber AS LineNumber,
	|	&Period                                AS Period,
	|	DATETIME(1,1,1,0,0,0) AS AdjustmentPeriod_,
	|	&Organization                           AS Organization,
	|	ARAPAdjustment.Department AS Department,
	|	ARAPAdjustment.LineOfBusiness AS LineOfBusiness,
	|	ARAPAdjustment.IncomeItem AS IncomeItem,
	|	ARAPAdjustment.DimensionOfRevenue AS DimensionOfRevenue,
	|	ARAPAdjustment.AmountIncludingVATMan AS Sum,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN ARAPAdjustment.AmountIncludingVATMan
	|		ELSE 0 END AS SumMan,
	|	CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN ARAPAdjustment.AmountIncludingVATCompl
	|		ELSE 0 END AS SumCompl,
	|	0 AS PermanentDifference,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	
	|	ARAPAdjustment.UniqueIDOfSettlementObject AS FinRecordID,
	|	ARAPAdjustment.RowID AS RowID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ARAPAdjustment) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTTableDebtAdjustment AS ARAPAdjustment
	|WHERE
	|	ARAPAdjustment.OnIncome
	|
	|UNION ALL
	|
	|SELECT
	|	ARAPAdjustment.LineNumber AS LineNumber,
	|	&Period                                AS Period,
	|	DATETIME(1,1,1,0,0,0) AS AdjustmentPeriod_,
	|	&Organization                           AS Organization,
	|	ARAPAdjustment.Department AS Department,
	|	ARAPAdjustment.LineOfBusiness AS LineOfBusiness,
	|	ARAPAdjustment.IncomeItem AS IncomeItem,
	|	ARAPAdjustment.DimensionOfRevenue AS DimensionOfRevenue,
	|	0 AS Sum,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN -ARAPAdjustment.VATManag
	|		ELSE 0 END AS SumMan,
	|	CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN -ARAPAdjustment.VATLocal
	|		ELSE 0 END AS SumCompl,
	|	0 AS PermanentDifference,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	
	|	ARAPAdjustment.RowID AS FinRecordID,
	|	ARAPAdjustment.RowID AS RowID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTTableDebtAdjustment AS ARAPAdjustment
	|WHERE
	|	ARAPAdjustment.OnIncome
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectOtherRevenue(Query, QueryTexts, Registers)
	
	RegisterName = "RevenueServicesAndAssets";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("TTDivergenceTable", QueryTexts) Then
		QueryTextTTDivergenceTable(Query, QueryTexts);
	EndIf;
	
	TextOtherRevenue =
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN &SaleAdjustment2_5 AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN &AdjustmentPeriod_
	|		ELSE DATETIME(1,1,1)
	|	END AS AdjustmentPeriod_,
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&Department AS Department,
	|	UNDEFINED AS Individual,
	|	&LineOfBusiness AS LineOfBusiness,
	|	CASE WHEN TableRevenue.Count < 0
	|			THEN VALUE(Enum.BusinessTransactions.ReverseOfSale)
	|		ELSE VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|	END AS BusinessOperation,
	|	TableRevenue.IncomeItem AS IncomeItem,
	|	TableRevenue.DimensionOfRevenue AS DimensionOfRevenue,
	|	TableRevenue.Count AS Count, 
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|			THEN TableRevenue.AmountExcludingVATMan
	|		ELSE 0 
	|	END AS RevenueExcludingVATManag,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|			THEN TableRevenue.AmountExcludingVATCompl
	|		ELSE 0 
	|	END AS RevenueExcludingVATLocal,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|			THEN TableRevenue.AmountIncludingVATMan - TableRevenue.AmountExcludingVATMan
	|		ELSE 0
	|	END AS VATManag,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR NOT &RecordInProfitLossOfPreviousYears
	|			THEN TableRevenue.VATLocal
	|		ELSE 0
	|	END AS VATLocal,
	|	CASE
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN - TableRevenue.AmountExcludingVATCompl
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|			THEN TableRevenue.AmountExcludingVATCompl
	|		ELSE 0
	|	END AS RevenueAmountPD,
	|	TableRevenue.VATRate AS VATRate,
	|	&VATTaxation AS VATTaxation,
	|	&ARAPCurrency AS ARAPCurrency,
	|	TableRevenue.AmountARAP AS AmountARAP,
	|	TableRevenue.ARAPObject AS ARAPObject,
	|	TableRevenue.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting
	|FROM
	|	TTDivergenceTable AS TableRevenue
	|	INNER JOIN Document.SaleAdjustment AS DocumentData
	|		ON DocumentData.Ref = TableRevenue.Ref
	|WHERE
	|	&ThisIsAdjustmentToSaleOfServicesOfOtherAssets
	|	AND (TableRevenue.OnIncome AND BEGINOFPERIOD(DocumentData.Date, YEAR) = BEGINOFPERIOD(DocumentData.DocumentBasis.Date, YEAR) AND NOT &SaleAdjustment2_5
	|		OR &SaleAdjustment2_5 AND (NOT &RecordInProfitLossOfPreviousYears OR &AdjustTaxBaseOfPreviousPeriod))
	|";
	
	IncomeAndExpensesServer.ReflectOtherRevenue(Query, QueryTexts, Registers, TextOtherRevenue);
	
EndProcedure

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers)
	
	RegisterName = "ItemisedExpensesLots";

	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryRegistration", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts);
	EndIf; 
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots();
	QueryText = QueryText + "UNION ALL" + "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Ref AS ExpenseReceiptDocument,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.LotVendorAttributes	AS LotVendorAttributes,
	|	TableTypesOfStocks_.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	CASE WHEN &BatchAccountingVersion22
	|		THEN &VATTaxation
	|		ELSE UNDEFINED
	|	END AS VATActivityType,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN TableTypesOfStocks_.VATManag
	|		ELSE 0 END AS VATManag,
	|	TableTypesOfStocks_.AmountExcludingVATCompl AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	TableTypesOfStocks_.VATLocal AS VATLocal,
	|
	|	UNDEFINED AS BusinessOperation,
	|	
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTTableTypesOfInventoryRegistration AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.ToIncomeExpenses
	|	AND &SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|	AND &CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|	AND &UseAccountingOfOtherIncomeExpenses
	|";
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers)
	
	RegisterName = "MaterialsAndWorksInProduction";

	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDivergenceOfServiceOperation", QueryTexts) Then
		QueryTextTTDivergenceOfServiceOperation(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	Works.LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Period AS RecorderDate,
	|	&Organization AS Organization,
	|	Works.Department AS Department,
	|	Works.Products,
	|	Works.Characteristic,
	|	Works.ItemsLocationAttributes,
	|	Works.Count,
	|	Works.Purpose,
	|	CASE 
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale)
	|		THEN VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|			ELSE &VATTaxation 
	|	END AS VATTaxation
	|FROM
	|	TTDivergenceOfServiceOperation AS Works
	|WHERE
	|	NOT Works.ToIncomeExpenses
	|	AND Works.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND Works.Count <> 0
	|	AND NOT Works.TracedGoods
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndFunction

Procedure GenerateTTAmountsOfDocumentInAccountingCurrencies(Query) Export
	
	If Query.TempTablesManager.Tables.Find("DocumentDataTable_") = Undefined Then
		GenerateEmptyTTOfDocumentAmountInAccountingCurrencies(Query);
		Return;
	EndIf;
	
	RequestForSelectionOfDocuments = New Query();
	RequestForSelectionOfDocuments.Text = 
	"SELECT TOP 1
	|	DocumentsTable.Ref AS Ref
	|FROM
	|	DocumentDataTable_ AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref REFS Document.SaleAdjustment
	|	AND CAST(DocumentsTable.Ref AS Document.SaleAdjustment).AdjustingEntryType IN (
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
	|	)
	|";
	RequestForSelectionOfDocuments.TempTablesManager = Query.TempTablesManager;
	
	Selection = RequestForSelectionOfDocuments.Execute().Select();
	If Selection.Next() Then
		RequestToReceiveTTAmountsOfDocuments = New Query();
		QueryTexts = New ValueList;
		FillInInitializationParameters(RequestToReceiveTTAmountsOfDocuments, Selection.Ref);
		
		RequestToReceiveTTAmountsOfDocuments.TempTablesManager = Query.TempTablesManager;
		
		GenerateDocumentAmountsInAccountingCurrencies(RequestToReceiveTTAmountsOfDocuments, QueryTexts, Undefined, True);
		
	Else
		// The connection will not be required, we form an empty temporary table, which is expected in the method of the textquery of the types of reserves.
		GenerateEmptyTTOfDocumentAmountInAccountingCurrencies(Query);
	EndIf;
	
EndProcedure

Procedure GenerateEmptyTTOfDocumentAmountInAccountingCurrencies(Query)
	RequestToGenerateEmptyTT = New Query();
	RequestToGenerateEmptyTT.TempTablesManager = Query.TempTablesManager;
	RequestToGenerateEmptyTT.Text = 
	"SELECT
	|	UNDEFINED AS Ref,
	|	UNDEFINED AS RowID,
	|	UNDEFINED AS Active,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS VATAmountCompl
	|INTO TTAmountsOfDocumentsInAccountingCurrencies";
	RequestToGenerateEmptyTT.Execute();
EndProcedure

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined, IncludingGoods = False) Export
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	DoNotRecalculateVATAmounts = False;
	
	QueryTextdata_ = "
	|SELECT
	|	""Discrepancies"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	&Ref AS Ref,
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&Currency AS DocumentCurrency,
	|	&ARAPCurrency AS ARAPCurrency,
	|	&VATBasePeriod AS VATBasePeriod,
	|	&Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.VATAmountCompl AS VATAmountCompl,
	|	DocumentTable.VATAmountMan AS VATAmountMan,
	|	DocumentTable.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	DocumentTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	DocumentTable.AmountExcludingVATMan AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObject AS ARAPObject,
	|	CASE 
	|		WHEN &AdjustmentBeforeEnteringBalancesWithoutVAT
	|				AND DocumentTable.AmountExcludingVATCompl <> 0
	|				AND DocumentTable.AmountExcludingVATMan <> 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecalculateBasedOnARAPData
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND (
	|		(DocumentTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService),
	|														 VALUE(Enum.ItemsTypes.Work_5))
	|		AND NOT (DocumentTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND DocumentTable.Products.TracedGoods
	|			AND &UseTraceableImportedGoodsAccounting))
	|		
	|		OR Products = VALUE(Catalog.Products.EmptyRef)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	""InventoryOwnerAttributesRevenueAdjustment"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	&Ref AS Ref,
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&Currency AS DocumentCurrency,
	|	&ARAPCurrency AS ARAPCurrency,
	|	&VATBasePeriod AS VATBasePeriod,
	|	&Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.VATAmountCompl AS VATAmountCompl,
	|	DocumentTable.VATAmountMan AS VATAmountMan,
	|	DocumentTable.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	DocumentTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	DocumentTable.AmountExcludingVATMan AS AmountExcludingVATMan,
	|
	|	CASE 
	|		WHEN DocumentTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND &ToReturnReusablePackage
	|			AND NOT &PackageDepositIsRequired
	|		THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObject AS ARAPObject,
	|	CASE 
	|		WHEN &AdjustmentBeforeEnteringBalancesWithoutVAT
	|				AND DocumentTable.AmountExcludingVATCompl <> 0
	|				AND DocumentTable.AmountExcludingVATMan <> 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecalculateBasedOnARAPData
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesRevenueAdjustment AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	""InventoryOwnerAttributesRevenueAdjustment"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	&Ref AS Ref,
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&Currency AS DocumentCurrency,
	|	&ARAPCurrency AS ARAPCurrency,
	|	&VATBasePeriod AS VATBasePeriod,
	|	&Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	-(DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount) AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	-DocumentTable.VATAmount AS VATAmount,
	|	-DocumentTable.VATAmountCompl AS VATAmountCompl,
	|	-DocumentTable.VATAmountMan AS VATAmountMan,
	|	-DocumentTable.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	-DocumentTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	-DocumentTable.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	
	|	CASE 
	|		WHEN DocumentTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND &ToReturnReusablePackage
	|			AND NOT &PackageDepositIsRequired
	|		THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObject AS ARAPObject,
	|	CASE 
	|		WHEN &AdjustmentBeforeEnteringBalancesWithoutVAT
	|				AND DocumentTable.AmountExcludingVATCompl <> 0
	|				AND DocumentTable.AmountExcludingVATMan <> 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecalculateBasedOnARAPData
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	""InventoryOwnerAttributesConsumption"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	&Ref AS Ref,
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&Currency AS DocumentCurrency,
	|	&ARAPCurrency AS ARAPCurrency,
	|	&VATBasePeriod AS VATBasePeriod,
	|	&Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.VATAmountCompl AS VATAmountCompl,
	|	DocumentTable.VATAmountMan AS VATAmountMan,
	|	DocumentTable.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	DocumentTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	DocumentTable.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	
	|	CASE 
	|		WHEN DocumentTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND &ToReturnReusablePackage
	|			AND NOT &PackageDepositIsRequired
	|		THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObject AS ARAPObject,
	|	CASE 
	|		WHEN &AdjustmentBeforeEnteringBalancesWithoutVAT
	|				AND DocumentTable.AmountExcludingVATCompl <> 0
	|				AND DocumentTable.AmountExcludingVATMan <> 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecalculateBasedOnARAPData
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	""DebtReduction_"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	&Ref AS Ref,
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&Currency AS DocumentCurrency,
	|	&ARAPCurrency AS ARAPCurrency,
	|	&Date AS VATBasePeriod,
	|	&Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	-(DocumentTable.AdjustmentSum - DocumentTable.SumOfVATAdjustments) AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	-DocumentTable.SumOfVATAdjustments AS VATAmount,
	|	0 AS VATAmountCompl,
	|	0 AS VATAmountMan,
	|	-DocumentTable.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.SaleAdjustment.ARAPAdjustment AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND &AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated)
	|
	|UNION ALL
	|
	|SELECT
	|	""IncreaseInDebt"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	&Ref AS Ref,
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&Currency AS DocumentCurrency,
	|	&ARAPCurrency AS ARAPCurrency,
	|	&Date AS VATBasePeriod,
	|	&Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	(DocumentTable.AdjustmentSum - DocumentTable.SumOfVATAdjustments) AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.SumOfVATAdjustments AS VATAmount,
	|	0 AS VATAmountCompl,
	|	0 AS VATAmountMan,
	|	DocumentTable.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.SaleAdjustment.ARAPAdjustment AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND &AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated)
	|";
	
	If IncludingGoods Then
		TextUnion = 
		"
		|UNION ALL
		|";
		
		QueryTextDataProducts = "SELECT
		|	""Goods"" AS DataSource,
		|	FALSE AS DistributeTotalAmount,
		|	&Ref AS Ref,
		|	&Date AS Date,
		|	&Organization AS Organization,
		|	&Currency AS DocumentCurrency,
		|	&ARAPCurrency AS ARAPCurrency,
		|	&VATBasePeriod AS VATBasePeriod,
		|	&Date AS DateOfCourse,
		|
		|	DocumentTable.LineNumber AS LineNumber,
		|	DocumentTable.RowID AS RowID,
		|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
		|	DocumentTable.VATRate AS VATRate,
		|	DocumentTable.VATAmount AS VATAmount,
		|	DocumentTable.VATAmountCompl AS VATAmountCompl,
		|	DocumentTable.VATAmountMan AS VATAmountMan,
		|	DocumentTable.AmountARAP AS AmountARAP,
		|	0 AS AmountVATARAP,
		|	DocumentTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
		|	DocumentTable.AmountExcludingVATMan AS AmountExcludingVATMan,
		|
		|	FALSE AS RecordedInARAPAccounting,
		|	UNDEFINED AS ARAPObject,
		|	FALSE AS RecalculateBasedOnARAPData
		|FROM
		|	Document.SaleAdjustment.Goods AS DocumentTable
		|
		|WHERE
		|	DocumentTable.Ref IN (&Ref)";
		
		QueryTextdata_ = 
			QueryTextdata_
			+ TextUnion
			+ QueryTextDataProducts;
	EndIf;
	
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_, DoNotRecalculateVATAmounts);
	
EndProcedure

Function QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers)

	RegisterName = "RecordsCounterpartyIncomeExpenses";

	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDivergenceTable", QueryTexts) Then
		QueryTextTTDivergenceTable(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryRegistration", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryWriteOff", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryWriteOff(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableDebtAdjustment", QueryTexts) Then
		QueryTextTTTableDebtAdjustment(Query, QueryTexts);
	EndIf;
		
	SetRequestParametersCurrencyCoefficients(Query);
#Region AccountsReceivableAdjustmentWithRecognionOfExpenses
	AccountsReceivableAdjustmentWithRecognionOfExpenses = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.AccountsReceivableAdjustmentWithRecognionOfExpenses) AS BusinessOperation,
	|	&Organization AS Organization,
	|	CASE 
	|		WHEN &AdjustmentKind IN (
	|				VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods),
	|				VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods))
	|			THEN &BusinessUnitExpenses 
	|		ELSE &Department
	|	END AS Department,
	|
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	CASE
	|		WHEN
	|			TableTypesOfStocks_.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|				VALUE(Enum.ItemsTypes.ReusablePackage))
	|		THEN
	|			TableTypesOfStocks_.LineOfBusiness
	|		ELSE
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|
	|	&LineOfBusiness AS LineOfBusinessItems,
	|	&ExpenseItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
	|	
	|	-TableTypesOfStocks_.AmountIncludingVATMan AS Sum,
	|	-TableTypesOfStocks_.AmountExcludingVATMan AS AmountExcludingVAT,
	|	-TableTypesOfStocks_.AmountExcludingVATCompl - TableTypesOfStocks_.VATLocal AS SumCompl,
	|	-TableTypesOfStocks_.AmountExcludingVATCompl AS LocalAmountExcludingVAT,
	|
	|	&Currency AS Currency,
	|	-TableTypesOfStocks_.AmountIncludingVAT AS AmountInCurrency,
	|	-TableTypesOfStocks_.AmountIncludingVAT + TableTypesOfStocks_.VATAmount AS AmountExcludingVATInCurrency,
	|		
	|	&ARAPCurrency AS ARAPCurrency,
	|	-TableTypesOfStocks_.AmountIncludingVAT AS AmountInARAPCurrency,
	|	-TableTypesOfStocks_.AmountIncludingVAT + TableTypesOfStocks_.VATAmount AS AmountExcludingVATInARAPCurrency,
	|
	|	TableTypesOfStocks_.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	TableTypesOfStocks_.RowID AS FinRecordID
	|FROM
	|	TTDivergenceTable AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.ToExpenses
	|	AND TableTypesOfStocks_.AmountIncludingVATMan <> 0
	|	AND NOT TableTypesOfStocks_.ThisIsTraceableWork
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.AccountsReceivableAdjustmentWithRecognionOfExpenses) AS BusinessOperation,
	|	&Organization AS Organization,
	|	CASE 
	|		WHEN &AdjustmentKind IN (
	|				VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods),
	|				VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods))
	|			THEN &BusinessUnitExpenses 
	|		ELSE &Department
	|	END AS Department,
	|
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	CASE
	|		WHEN
	|			TableTypesOfStocks_.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|				VALUE(Enum.ItemsTypes.ReusablePackage))
	|		THEN
	|			TableTypesOfStocks_.LineOfBusiness
	|		ELSE
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|
	|	&LineOfBusiness AS LineOfBusinessItems,
	|	&ExpenseItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
	|	
	|	TableTypesOfStocks_.AmountIncludingVATMan AS Sum,
	|	TableTypesOfStocks_.AmountExcludingVATMan AS AmountExcludingVAT,
	|	TableTypesOfStocks_.AmountExcludingVATCompl - TableTypesOfStocks_.VATLocal AS SumCompl,
	|	TableTypesOfStocks_.AmountExcludingVATCompl AS LocalAmountExcludingVAT,
	|
	|	&Currency AS Currency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT + TableTypesOfStocks_.VATAmount AS AmountExcludingVATInCurrency,
	|		
	|	&ARAPCurrency AS ARAPCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInARAPCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT + TableTypesOfStocks_.VATAmount AS AmountExcludingVATInARAPCurrency,
	|
	|	TableTypesOfStocks_.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	TableTypesOfStocks_.RowID AS FinRecordID
	|FROM
	|	TTTableTypesOfInventoryRegistration AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.ToIncomeExpenses
	|	AND TableTypesOfStocks_.AmountIncludingVATMan <> 0
	|";
#EndRegion

#Region AccountsReceivableAdjustmentWithRecognionOfOtherIncome
	AccountsReceivableAdjustmentWithRecognionOfOtherIncome = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.AccountsReceivableAdjustmentWithRecognionOfOtherIncome) AS BusinessOperation,
	|	&Organization AS Organization,
	|	CASE 
	|		WHEN &AdjustmentKind IN (
	|				VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods),
	|				VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods))
	|			THEN &BusinessUnit
	|		ELSE &Department
	|	END AS Department,
	|
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	CASE
	|		WHEN
	|			TableTypesOfStocks_.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|				VALUE(Enum.ItemsTypes.ReusablePackage))
	|		THEN
	|			TableTypesOfStocks_.LineOfBusiness
	|		ELSE
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|
	|	&LineOfBusiness AS LineOfBusinessItems,
	|	CASE
	|		WHEN
	|			&ThisIsAdjustmentToSaleOfServicesOfOtherAssets
	|			AND BEGINOFPERIOD(DocumentData.Date, YEAR) = BEGINOFPERIOD(DocumentData.DocumentBasis.Date, YEAR)
	|		THEN
	|			TableTypesOfStocks_.IncomeItem
	|		ELSE
	|			&IncomeItem
	|	END AS IncomeAndExpenseItem,
	|	CASE
	|		WHEN
	|			&ThisIsAdjustmentToSaleOfServicesOfOtherAssets
	|			AND BEGINOFPERIOD(DocumentData.Date, YEAR) = BEGINOFPERIOD(DocumentData.DocumentBasis.Date, YEAR)
	|		THEN
	|			TableTypesOfStocks_.DimensionOfRevenue
	|		ELSE
	|			&DimensionOfRevenue
	|	END AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	TableTypesOfStocks_.AmountIncludingVATMan AS Sum,
	|	TableTypesOfStocks_.AmountExcludingVATMan AS AmountExcludingVAT,
	|	TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATLocal AS SumCompl,
	|	TableTypesOfStocks_.AmountExcludingVATCompl AS LocalAmountExcludingVAT,
	|
	|	&Currency AS Currency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInCurrency,
	|		
	|	&ARAPCurrency AS ARAPCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInARAPCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInARAPCurrency,
	|
	|	TableTypesOfStocks_.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	TableTypesOfStocks_.RowID AS FinRecordID
	|FROM
	|	TTDivergenceTable AS TableTypesOfStocks_
	|	LEFT JOIN Document.SaleAdjustment AS DocumentData
	|		ON DocumentData.Ref = TableTypesOfStocks_.Ref
	|WHERE
	|	TableTypesOfStocks_.OnIncome
	|	AND TableTypesOfStocks_.AmountIncludingVATMan <> 0
	|	AND NOT TableTypesOfStocks_.ThisIsTraceableWork
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.AccountsReceivableAdjustmentWithRecognionOfOtherIncome) AS BusinessOperation,
	|	&Organization AS Organization,
	|	CASE 
	|		WHEN &AdjustmentKind IN (
	|				VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods),
	|				VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods))
	|			THEN &BusinessUnit
	|		ELSE &Department
	|	END AS Department,
	|
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	CASE
	|		WHEN
	|			TableTypesOfStocks_.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|				VALUE(Enum.ItemsTypes.ReusablePackage))
	|		THEN
	|			TableTypesOfStocks_.LineOfBusiness
	|		ELSE
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|
	|	&LineOfBusiness AS LineOfBusinessItems,
	|	&IncomeItem AS IncomeAndExpenseItem,
	|	&DimensionOfRevenue AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	TableTypesOfStocks_.AmountIncludingVATMan AS Sum,
	|	TableTypesOfStocks_.AmountExcludingVATMan AS AmountExcludingVAT,
	|	TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATLocal AS SumCompl,
	|	TableTypesOfStocks_.AmountExcludingVATCompl AS LocalAmountExcludingVAT,
	|
	|	&Currency AS Currency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInCurrency,
	|		
	|	&ARAPCurrency AS ARAPCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInARAPCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInARAPCurrency,
	|
	|	TableTypesOfStocks_.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	TableTypesOfStocks_.RowID AS FinRecordID
	|FROM
	|	TTTableTypesOfInventoryWriteOff AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.ToIncomeExpenses
	|	AND TableTypesOfStocks_.AmountIncludingVATMan <> 0";
#EndRegion

#Region ARAPAdjustment
	ARAPAdjustment = 
	"SELECT
	|	&Period AS Period,
	|	CASE 
	|		WHEN ARAPAdjustment.ToExpenses
	|			THEN VALUE(Enum.BusinessTransactions.AccountsReceivableAdjustmentWithRecognionOfExpenses)
	|		ELSE VALUE(Enum.BusinessTransactions.AccountsReceivableAdjustmentWithRecognionOfOtherIncome)
	|	END AS BusinessOperation,
	|	&Organization AS Organization,
	|	ARAPAdjustment.Department AS Department,
	|
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	ARAPAdjustment.Contract AS Contract,
	|	ARAPAdjustment.ARAPObject AS ARAPObject,
	|	ARAPAdjustment.LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	ARAPAdjustment.LineOfBusiness AS LineOfBusinessItems,
	|	CASE 
	|		WHEN ARAPAdjustment.ToExpenses
	|			THEN ARAPAdjustment.ExpenseItem
	|		ELSE ARAPAdjustment.IncomeItem
	|	END AS IncomeAndExpenseItem,
	|	CASE 
	|		WHEN ARAPAdjustment.OnIncome
	|			THEN ARAPAdjustment.DimensionOfRevenue
	|		ELSE UNDEFINED
	|	END AS DimensionOfRevenue,
	|	CASE 
	|		WHEN ARAPAdjustment.ToExpenses
	|			THEN ARAPAdjustment.DimensionOfExpenses
	|		ELSE UNDEFINED
	|	END AS DimensionOfExpenses,
	|	
	|	ARAPAdjustment.AmountIncludingVATMan AS Sum,
	|	ARAPAdjustment.AmountExcludingVATMan AS AmountExcludingVAT,
	|	ARAPAdjustment.AmountExcludingVATCompl + ARAPAdjustment.VATLocal AS SumCompl,
	|	ARAPAdjustment.AmountExcludingVATCompl AS LocalAmountExcludingVAT,
	|
	|	&Currency AS Currency,
	|	ARAPAdjustment.AmountIncludingVAT AS AmountInCurrency,
	|	ARAPAdjustment.AmountExcludingVAT AS AmountExcludingVATInCurrency,
	|		
	|	&ARAPCurrency AS ARAPCurrency,
	|	ARAPAdjustment.AmountARAP AS AmountInARAPCurrency,
	|	ARAPAdjustment.AmountARAP - ARAPAdjustment.AmountVATARAP AS AmountExcludingVATInARAPCurrency,
	|
	|	ARAPAdjustment.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	ARAPAdjustment.RowID AS FinRecordID
	|FROM
	|	TTTableDebtAdjustment AS ARAPAdjustment
	|";
#EndRegion
	
	ArrayOfTexts = New Array;
	ArrayOfTexts.Add(AccountsReceivableAdjustmentWithRecognionOfExpenses);
	ArrayOfTexts.Add(AccountsReceivableAdjustmentWithRecognionOfOtherIncome);
	ArrayOfTexts.Add(ARAPAdjustment);
	QueryText = StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableServicesForRegistrationOfReportsToPrincipal(Query, QueryTexts, Registers)
	
	RegisterName = "ServicesForRegistrationOfReportsToPrincipal";

	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("ExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDivergenceOfServiceOperation", QueryTexts) Then
		QueryTextTTDivergenceOfServiceOperation(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	ToRegister.LineNumber                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	&Period                                     AS Period,
	|	&Organization                                AS Organization,
	|	ToRegister.PrincipalProductAnalysis AS ItemsLocationAttributes,
	|	ToRegister.Terms                      AS Terms,
	|	ToRegister.Currency                          AS Currency,
	|	ToRegister.Count                      AS Count,
	|	ToRegister.AmountIncludingVAT 
	|		* ExchangeRates.ConversionFactor_       AS RevenueAmount,
	|	ToRegister.VATAmount 
	|		* ExchangeRates.ConversionFactor_       AS VATAmount,
	|	CASE
	|		WHEN ISNULL(ToRegister.Terms.RevalueServicesForConsignmentNotification, FALSE)
	|			THEN ToRegister.AmountIncludingVATCompl
	|		ELSE 0
	|	END AS RevenueAmountExclVATLocal,
	|	CASE
	|		WHEN ISNULL(ToRegister.Terms.RevalueServicesForConsignmentNotification, FALSE)
	|			THEN ToRegister.AmountIncludingVATMan
	|		ELSE 0
	|	END AS RevenueAmountMan,
	|	&Counterparty                                 AS Customer,
	|	&Ref                                     AS DocumentSalesOfGoodsAndServices,
	|	ToRegister.ARAPObject.UUID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting,
	|	ToRegister.RowID AS RowID
	|FROM
	|	TTDivergenceOfServiceOperation AS ToRegister
	|
	|	LEFT JOIN ExchangeRates AS ExchangeRates
	|	ON ToRegister.Currency = ExchangeRates.Currency
	|WHERE
	|	NOT ToRegister.ToIncomeExpenses
	|	AND ToRegister.PrincipalProductAnalysis <> UNDEFINED
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts) Export
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";

	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryRegistration", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts);
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TTInventoryTypesRevenueAdjustment", QueryTexts) Then
		QueryTextTTInventoryTypesRevenueAdjustment(Query, QueryTexts);
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TTDivergenceOfServiceOperation", QueryTexts) Then
		QueryTextTTDivergenceOfServiceOperation(Query, QueryTexts);
	EndIf; 
	If Not DocumentsPosting.ThereIsQueryTable("TTTableDebtAdjustment", QueryTexts) Then
		QueryTextTTTableDebtAdjustment(Query, QueryTexts);
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryWriteOff", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryWriteOff(Query, QueryTexts);
	EndIf; 
	
	QueryText = AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses("RowID,VariancePeriod");
	QueryText = QueryText + "UNION ALL" + " 
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN &SaleAdjustment2_5
	|			THEN &Department
	|		ELSE &BusinessUnitExpenses
	|	END                                  AS Department,
	|	CASE
	|		WHEN &AdjustmentOfPreviousPeriodYear 
	|			AND &SaleAdjustment2_5
	|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProfitLossOfPreviousYears)
	|			ELSE &ExpenseItem
	|	END                                  AS ExpenseItem,
	|	&DimensionOfExpenses                     AS DimensionOfExpenses,
	|	&LineOfBusiness               AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|		THEN InventoryKinds.AmountIncludingVATMan 
	|	ELSE 0 END AS AmountIncludingVAT,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|		THEN InventoryKinds.AmountExcludingVATMan 
	|	ELSE 0 END AS AmountExcludingVAT,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|		THEN InventoryKinds.AmountExcludingVATMan +InventoryKinds.VATManag
	|	ELSE 0 END AS AmountExcludingVATMan,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|		THEN InventoryKinds.AmountExcludingVATCompl + InventoryKinds.VATLocal
	|	ELSE 0 END AS AmountIncludingVATCompl,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|		THEN InventoryKinds.AmountExcludingVATCompl + InventoryKinds.VATLocal
	|	ELSE 0 END AS AmountExcludingVATCompl,
	|	CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			OR NOT &SaleAdjustment2_5
	|			THEN 0
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|			THEN - (InventoryKinds.AmountExcludingVATCompl + InventoryKinds.VATLocal)
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN InventoryKinds.AmountExcludingVATCompl + InventoryKinds.VATLocal
	|		ELSE 0
	|	END AS PermanentDifference,
	|	0 AS CostTD,
	|	UNDEFINED AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	InventoryKinds.ARAPObject.UUID AS FinRecordID,
	|	CASE
	|		WHEN InventoryKinds.CostDefiningMethod IN (
	|				VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|				VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AdjustBeforeEnteringBalance)
	|		ELSE &BusinessTransactionSetting
	|	END AS BusinessTransactionSetting,
	|	InventoryKinds.RowID AS RowID,
	|	CASE 
	|		WHEN &SaleAdjustment2_5 THEN
	|			CASE 
	|				WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|					&AdjustmentPeriod_
	|				ELSE
	|					DATETIME(1,1,1,0,0,0)
	|			END
	|	ELSE
	|		DATETIME(1,1,1,0,0,0) 
	|	END                                  AS VariancePeriod
	|	
	|FROM
	|	TTTableTypesOfInventoryRegistration AS InventoryKinds
	|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON ExpenseItems.Ref = &ExpenseItem
	|WHERE 
	|	(InventoryKinds.ToIncomeExpenses AND NOT &SaleAdjustment2_5
	|		OR &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear
	|			AND (&RecordInProfitLossOfPreviousYears
	|				OR NOT &AdjustTaxBaseOfPreviousPeriod))
	|	AND InventoryKinds.AmountIncludingVATMan > 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN &SaleAdjustment2_5
	|			THEN &Department
	|		ELSE &BusinessUnitExpenses
	|	END                                  AS Department,
	|	CASE
	|		WHEN &AdjustmentOfPreviousPeriodYear 
	|			AND &SaleAdjustment2_5
	|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProfitLossOfPreviousYears)
	|			ELSE &ExpenseItem
	|	END                                  AS ExpenseItem,
	|	&DimensionOfExpenses                     AS DimensionOfExpenses,
	|	&LineOfBusiness               AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|		THEN  - InventoryKinds.VATManag 
	|				- InventoryKinds.ExciseAmountInCurrencyMgmt
	|	ELSE 0 END AS AmountExcludingVATMan,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|		THEN  - InventoryKinds.VATLocal 
	|				- InventoryKinds.ExciseAmountInCurrencyLocal
	|	ELSE 0 END AS AmountIncludingVATCompl,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|		THEN  - InventoryKinds.VATLocal 
	|				- InventoryKinds.ExciseAmountInCurrencyLocal
	|	ELSE 0 END AS AmountExcludingVATCompl,
	|	CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			OR NOT &SaleAdjustment2_5
	|			THEN 0
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|			THEN InventoryKinds.VATLocal 
	|					+ InventoryKinds.ExciseAmountInCurrencyLocal
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN - InventoryKinds.VATLocal 
	|					- InventoryKinds.ExciseAmountInCurrencyLocal
	|		ELSE 0
	|	END AS PermanentDifference,
	|	0 AS CostTD,
	|	UNDEFINED AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	InventoryKinds.RowID AS FinRecordID,
	|	CASE
	|		WHEN InventoryKinds.CostDefiningMethod IN (
	|				VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|				VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AdjustBeforeEnteringBalance)
	|		ELSE &BusinessTransactionSetting
	|	END AS BusinessTransactionSetting,
	|	InventoryKinds.RowID AS RowID,
	|	CASE 
	|		WHEN &SaleAdjustment2_5 THEN
	|			CASE 
	|				WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|					&AdjustmentPeriod_
	|				ELSE
	|					DATETIME(1,1,1,0,0,0)
	|			END
	|	ELSE
	|		DATETIME(1,1,1,0,0,0) 
	|	END                                  AS VariancePeriod
	|	
	|FROM
	|	TTTableTypesOfInventoryRegistration AS InventoryKinds
	|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON ExpenseItems.Ref = &ExpenseItem
	|WHERE 
	|	(InventoryKinds.ToIncomeExpenses AND NOT &SaleAdjustment2_5
	|		OR &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear
	|			AND (&RecordInProfitLossOfPreviousYears
	|				OR NOT &AdjustTaxBaseOfPreviousPeriod))
	|	AND InventoryKinds.AmountIncludingVATMan > 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN &SaleAdjustment2_5
	|			THEN &Department
	|		ELSE &BusinessUnitExpenses
	|	END                                  AS Department,
	|	CASE
	|		WHEN &AdjustmentOfPreviousPeriodYear 
	|			AND &SaleAdjustment2_5
	|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProfitLossOfPreviousYears)
	|			ELSE &ExpenseItem
	|	END                                  AS ExpenseItem,
	|	&DimensionOfExpenses                     AS DimensionOfExpenses,
	|	&LineOfBusiness               AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|		THEN -WorksServices.AmountIncludingVATMan
	|	ELSE 0 END AS AmountIncludingVAT,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|		THEN -WorksServices.AmountExcludingVATMan
	|	ELSE 0 END AS AmountExcludingVAT,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|		THEN -(WorksServices.AmountExcludingVATMan + WorksServices.VATManag)
	|	ELSE 0 END AS AmountExcludingVATMan,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|		THEN - (WorksServices.AmountExcludingVATCompl + WorksServices.VATLocal)
	|	ELSE 0 END AS AmountIncludingVATCompl,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|		THEN - (WorksServices.AmountExcludingVATCompl + WorksServices.VATLocal)
	|	ELSE 0 END AS AmountExcludingVATCompl,
	|	CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			OR NOT &SaleAdjustment2_5
	|			THEN 0
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|			THEN WorksServices.AmountExcludingVATCompl + WorksServices.VATLocal
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN - (WorksServices.AmountExcludingVATCompl + WorksServices.VATLocal)
	|		ELSE 0
	|	END AS PermanentDifference,
	|	0 AS CostTD,
	|	UNDEFINED AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	WorksServices.ARAPObject.UUID AS FinRecordID,
	|	CASE
	|		WHEN WorksServices.CostDefiningMethod IN (
	|				VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|				VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AdjustBeforeEnteringBalance)
	|		ELSE &BusinessTransactionSetting
	|	END AS BusinessTransactionSetting,
	|	WorksServices.RowID AS RowID,
	|	CASE 
	|		WHEN &SaleAdjustment2_5 THEN
	|			CASE 
	|				WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|					&AdjustmentPeriod_
	|				ELSE
	|					DATETIME(1,1,1,0,0,0)
	|			END
	|	ELSE
	|		DATETIME(1,1,1,0,0,0) 
	|	END                                  AS VariancePeriod
	|	
	|FROM
	|	TTDivergenceOfServiceOperation AS WorksServices
	|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON ExpenseItems.Ref = &ExpenseItem
	|WHERE
	|	(WorksServices.ToIncomeExpenses AND NOT &SaleAdjustment2_5
	|		OR &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear
	|			AND (&RecordInProfitLossOfPreviousYears
	|				OR NOT &AdjustTaxBaseOfPreviousPeriod))
	|	AND WorksServices.AmountIncludingVATMan < 0
	|	AND NOT WorksServices.ThisIsTraceableWork
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN &SaleAdjustment2_5
	|			THEN &Department
	|		ELSE &BusinessUnitExpenses
	|	END                                  AS Department,
	|	CASE
	|		WHEN &AdjustmentOfPreviousPeriodYear 
	|			AND &SaleAdjustment2_5
	|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProfitLossOfPreviousYears)
	|			ELSE &ExpenseItem
	|	END                                  AS ExpenseItem,
	|	&DimensionOfExpenses                     AS DimensionOfExpenses,
	|	&LineOfBusiness               AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|		THEN WorksServices.VATManag
	|	ELSE 0 END AS AmountExcludingVATMan,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|		THEN WorksServices.VATLocal
	|	ELSE 0 END AS AmountIncludingVATCompl,
	|	CASE
	|		WHEN NOT &SaleAdjustment2_5 OR &RecordInProfitLossOfPreviousYears
	|		THEN WorksServices.VATLocal
	|	ELSE 0 END AS AmountExcludingVATCompl,
	|	CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			OR NOT &SaleAdjustment2_5
	|			THEN 0
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|			THEN - WorksServices.VATLocal
	|		WHEN &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear AND &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN WorksServices.VATLocal
	|		ELSE 0
	|	END AS PermanentDifference,
	|	0 AS CostTD,
	|	UNDEFINED AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	WorksServices.RowID AS FinRecordID,
	|	CASE
	|		WHEN WorksServices.CostDefiningMethod IN (
	|				VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|				VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AdjustBeforeEnteringBalance)
	|		ELSE &BusinessTransactionSetting
	|	END AS BusinessTransactionSetting,
	|	WorksServices.RowID AS RowID,
	|	CASE 
	|		WHEN &SaleAdjustment2_5 THEN
	|			CASE 
	|				WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|					&AdjustmentPeriod_
	|				ELSE
	|					DATETIME(1,1,1,0,0,0)
	|			END
	|	ELSE
	|		DATETIME(1,1,1,0,0,0) 
	|	END                                  AS VariancePeriod
	|	
	|FROM
	|	TTDivergenceOfServiceOperation AS WorksServices
	|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON ExpenseItems.Ref = &ExpenseItem
	|WHERE 
	|	(WorksServices.ToIncomeExpenses AND NOT &SaleAdjustment2_5
	|		OR &SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear
	|			AND (&RecordInProfitLossOfPreviousYears
	|				OR NOT &AdjustTaxBaseOfPreviousPeriod))
	|	AND WorksServices.AmountIncludingVATMan < 0
	|	AND NOT WorksServices.ThisIsTraceableWork
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization                           AS Organization,
	|	&Department                         AS Department, 
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProfitLossOfPreviousYears) AS ExpenseItem, 
	|	&DimensionOfExpenses                     AS DimensionOfExpenses,
	|	&LineOfBusiness               AS LineOfBusiness, 
	|	UNDEFINED AS VATActivityType,
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|			THEN -InventoryKinds.AmountIncludingVATMan
	|	ELSE 0 END AS AmountIncludingVAT,
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|			THEN -InventoryKinds.AmountExcludingVATMan
	|	ELSE 0 END AS AmountExcludingVAT,
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|			THEN -(InventoryKinds.AmountExcludingVATMan +InventoryKinds.VATManag)
	|	ELSE 0 END AS AmountExcludingVATMan, 
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|			THEN -(InventoryKinds.AmountExcludingVATCompl + InventoryKinds.VATLocal)
	|	ELSE 0 END  AS AmountIncludingVATCompl,
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|			THEN -(InventoryKinds.AmountExcludingVATCompl + InventoryKinds.VATLocal)
	|	ELSE 0 END AS AmountExcludingVATCompl,
	|	CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			OR NOT &SaleAdjustment2_5
	|			THEN 0
	|		WHEN NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|			THEN InventoryKinds.AmountExcludingVATCompl + InventoryKinds.VATLocal
	|		WHEN &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN -(InventoryKinds.AmountExcludingVATCompl + InventoryKinds.VATLocal)
	|		ELSE 0
	|	END AS PermanentDifference,
	|	0 AS CostTD,
	|	UNDEFINED AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	InventoryKinds.ARAPObject.UUID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting,
	|	InventoryKinds.RowID AS RowID,
	|	CASE
	|		WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|			&AdjustmentPeriod_
	|		ELSE DATETIME(1,1,1,0,0,0)
	|	END AS AdjustmentPeriod_
	|	
	|FROM
	|	TTTableTypesOfInventoryWriteOff AS InventoryKinds
	|WHERE
	|	&SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear
	|	AND (&RecordInProfitLossOfPreviousYears
	|		OR NOT &AdjustTaxBaseOfPreviousPeriod)
	|	AND InventoryKinds.AmountIncludingVATMan < 0
	|	AND InventoryKinds.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization                           AS Organization,
	|	&Department                         AS Department, 
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProfitLossOfPreviousYears) AS ExpenseItem,
	|	&DimensionOfExpenses                     AS DimensionOfExpenses,
	|	&LineOfBusiness               AS LineOfBusiness, 
	|	UNDEFINED AS VATActivityType,
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|			THEN InventoryKinds.VATManag 
	|					+ InventoryKinds.ExciseAmountInCurrencyMgmt
	|	ELSE 0 END AS AmountExcludingVATMan,
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|			THEN InventoryKinds.VATLocal 
	|				+ InventoryKinds.ExciseAmountInCurrencyLocal
	|	ELSE 0 END AS AmountIncludingVATCompl,
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|			THEN InventoryKinds.VATLocal 
	|			+ InventoryKinds.ExciseAmountInCurrencyLocal
	|	ELSE 0 END AS AmountExcludingVATCompl,
	|	CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			OR NOT &SaleAdjustment2_5
	|			THEN 0
	|		WHEN NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|			THEN - InventoryKinds.VATLocal 
	|					- InventoryKinds.ExciseAmountInCurrencyLocal
	|		WHEN &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN InventoryKinds.VATLocal 
	|			+ InventoryKinds.ExciseAmountInCurrencyLocal
	|		ELSE 0
	|	END AS PermanentDifference,
	|	0 AS CostTD,
	|	UNDEFINED AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	InventoryKinds.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting,
	|	InventoryKinds.RowID AS RowID,
	|	CASE
	|		WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|			&AdjustmentPeriod_
	|		ELSE DATETIME(1,1,1,0,0,0)
	|	END AS AdjustmentPeriod_
	|	
	|FROM
	|	TTTableTypesOfInventoryWriteOff AS InventoryKinds
	|WHERE
	|	&SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear
	|	AND (&RecordInProfitLossOfPreviousYears
	|		OR NOT &AdjustTaxBaseOfPreviousPeriod)
	|	AND InventoryKinds.AmountIncludingVATMan < 0
	|	AND InventoryKinds.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|	
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization                           AS Organization,
	|	&Department                         AS Department, 
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProfitLossOfPreviousYears) AS ExpenseItem, 
	|	&DimensionOfExpenses                     AS DimensionOfExpenses,
	|	&LineOfBusiness               AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|			THEN -InventoryKinds.AmountIncludingVATMan
	|	ELSE 0 END AS AmountIncludingVAT,
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|			THEN -InventoryKinds.AmountExcludingVATMan
	|	ELSE 0 END AS AmountExcludingVAT,
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|			THEN -(InventoryKinds.AmountExcludingVATMan +InventoryKinds.VATAmountMan)
	|	ELSE 0 END AS AmountExcludingVATMan, 
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|			THEN -(InventoryKinds.AmountExcludingVATCompl + InventoryKinds.VATLocal)
	|	ELSE 0 END  AS AmountIncludingVATCompl,
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|			THEN -(InventoryKinds.AmountExcludingVATCompl + InventoryKinds.VATLocal)
	|	ELSE 0 END AS AmountExcludingVATCompl,
	|	CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			OR NOT &SaleAdjustment2_5
	|			THEN 0
	|		WHEN &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN -(InventoryKinds.AmountExcludingVATCompl + InventoryKinds.VATLocal)
	|		WHEN NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|			THEN InventoryKinds.AmountExcludingVATCompl + InventoryKinds.VATLocal
	|		ELSE 0
	|	END AS PermanentDifference,
	|	0 AS CostTD,
	|	UNDEFINED AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	InventoryKinds.ARAPObject.UUID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting,
	|	InventoryKinds.RowID AS RowID,
	|	CASE
	|		WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|			&AdjustmentPeriod_
	|		ELSE DATETIME(1,1,1,0,0,0)
	|	END AS AdjustmentPeriod_
	|	
	|FROM
	|	TTInventoryTypesRevenueAdjustment AS InventoryKinds
	|WHERE
	|	&SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear
	|	AND (&RecordInProfitLossOfPreviousYears
	|		OR NOT &AdjustTaxBaseOfPreviousPeriod)
	|	AND InventoryKinds.AmountIncludingVATMan < 0
	|	AND InventoryKinds.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization                           AS Organization,
	|	&Department                         AS Department, 
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProfitLossOfPreviousYears) AS ExpenseItem,
	|	&DimensionOfExpenses                     AS DimensionOfExpenses,
	|	&LineOfBusiness               AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|			THEN InventoryKinds.AmountIncludingVATMan - InventoryKinds.AmountExcludingVATMan
	|	ELSE 0 END AS AmountExcludingVATMan,
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|			THEN InventoryKinds.VATLocal
	|	ELSE 0 END AS AmountIncludingVATCompl,
	|	CASE
	|		WHEN &RecordInProfitLossOfPreviousYears
	|			THEN InventoryKinds.VATLocal
	|	ELSE 0 END AS AmountExcludingVATCompl,
	|	CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			OR NOT &SaleAdjustment2_5
	|			THEN 0
	|		WHEN &RecordInProfitLossOfPreviousYears AND &AdjustTaxBaseOfPreviousPeriod
	|			THEN -InventoryKinds.VATLocal
	|		WHEN NOT &RecordInProfitLossOfPreviousYears AND NOT &AdjustTaxBaseOfPreviousPeriod
	|			THEN InventoryKinds.VATLocal
	|		ELSE 0
	|	END AS PermanentDifference,
	|	0 AS CostTD,
	|	UNDEFINED AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	InventoryKinds.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting,
	|	InventoryKinds.RowID AS RowID,
	|	CASE
	|		WHEN &AdjustTaxBaseOfPreviousPeriod THEN
	|			&AdjustmentPeriod_
	|		ELSE DATETIME(1,1,1,0,0,0)
	|	END AS AdjustmentPeriod_
	|	
	|FROM
	|	TTInventoryTypesRevenueAdjustment AS InventoryKinds
	|WHERE
	|	&SaleAdjustment2_5 AND &AdjustmentOfPreviousPeriodYear
	|	AND (&RecordInProfitLossOfPreviousYears
	|		OR NOT &AdjustTaxBaseOfPreviousPeriod)
	|	AND InventoryKinds.AmountIncludingVATMan < 0
	|	AND InventoryKinds.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	ARAPAdjustment.Department AS Department,
	|	ARAPAdjustment.ExpenseItem AS ExpenseItem,
	|	ARAPAdjustment.DimensionOfExpenses AS DimensionOfExpenses,
	|	ARAPAdjustment.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|
	|	ARAPAdjustment.AmountIncludingVATMan AS AmountIncludingVAT,
	|	ARAPAdjustment.AmountExcludingVATMan AS AmountExcludingVAT,
	|	ARAPAdjustment.AmountIncludingVATMan AS AmountExcludingVATMan,
	|
	|	ARAPAdjustment.AmountIncludingVATCompl AS AmountIncludingVATCompl,
	|	ARAPAdjustment.AmountIncludingVATCompl AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	UNDEFINED AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	ARAPAdjustment.UniqueIDOfSettlementObject AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ARAPAdjustment) AS BusinessTransactionSetting,
	|	ARAPAdjustment.RowID AS RowID,
	|	DATETIME(1,1,1,0,0,0) AS VariancePeriod
	|
	|FROM
	|	TTTableDebtAdjustment AS ARAPAdjustment
	|WHERE
	|	ARAPAdjustment.ToExpenses
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	ARAPAdjustment.Department AS Department,
	|	ARAPAdjustment.ExpenseItem AS ExpenseItem,
	|	ARAPAdjustment.DimensionOfExpenses AS DimensionOfExpenses,
	|	ARAPAdjustment.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	-ARAPAdjustment.VATManag AS AmountExcludingVATMan,
	|
	|	-ARAPAdjustment.VATLocal AS AmountIncludingVATCompl,
	|	-ARAPAdjustment.VATLocal AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	UNDEFINED AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	ARAPAdjustment.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting,
	|	ARAPAdjustment.RowID AS RowID,
	|	DATETIME(1,1,1,0,0,0) AS VariancePeriod
	|
	|FROM
	|	TTTableDebtAdjustment AS ARAPAdjustment
	|WHERE
	|	ARAPAdjustment.ToExpenses
	|
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";

	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryRegistration", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableDebtAdjustment", QueryTexts) Then
		QueryTextTTTableDebtAdjustment(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	&BusinessUnitExpenses                   AS Department,
	|	&Ref AS ExpenseReceiptDocument,
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.LotVendorAttributes AS LotVendorAttributes,
	|	CASE
	|		WHEN
	|			TableTypesOfStocks_.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|				VALUE(Enum.ItemsTypes.ReusablePackage))
	|		THEN
	|			TableTypesOfStocks_.LineOfBusiness
	|		ELSE
	|			&LineOfBusiness
	|	END                                   AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	&VATTaxation AS VATActivityType,
	|
	|	TableTypesOfStocks_.AmountIncludingVATMan AS Cost,
	|	TableTypesOfStocks_.AmountExcludingVATMan AS CostExcludingVAT,
	|	0 AS VATManag,
	|	TableTypesOfStocks_.AmountExcludingVATCompl AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS VATLocal,
	|	UNDEFINED AS BusinessOperation,
	|	
	|	TableTypesOfStocks_.ARAPObject.UUID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	TTTableTypesOfInventoryRegistration AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.ToIncomeExpenses
	|	AND NOT TableTypesOfStocks_.ThisIsTraceableWork
	|
	|UNION ALL
	|
	|SELECT
	|	ARAPAdjustment.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	ARAPAdjustment.Department AS Department,
	|	&Ref AS ExpenseReceiptDocument,
	|	ARAPAdjustment.ExpenseItem AS ExpenseItem,
	|	ARAPAdjustment.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	ARAPAdjustment.LotVendorAttributes AS LotVendorAttributes,
	|	ARAPAdjustment.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	&VATTaxation AS VATActivityType,
	|
	|	ARAPAdjustment.AmountIncludingVATMan AS Cost,
	|	ARAPAdjustment.AmountIncludingVATMan AS CostExcludingVAT,
	|	0 AS VATManag,
	|	ARAPAdjustment.AmountIncludingVATCompl  AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS VATLocal,
	|	UNDEFINED AS BusinessOperation,
	|	
	|	ARAPAdjustment.UniqueIDOfSettlementObject AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ARAPAdjustment) AS BusinessTransactionSetting
	|
	|FROM
	|	TTTableDebtAdjustment AS ARAPAdjustment
	|WHERE
	|	ARAPAdjustment.ToExpenses
	|
	|UNION ALL
	|
	|SELECT
	|	ARAPAdjustment.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	ARAPAdjustment.Department AS Department,
	|	&Ref AS ExpenseReceiptDocument,
	|	ARAPAdjustment.ExpenseItem AS ExpenseItem,
	|	ARAPAdjustment.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	ARAPAdjustment.LotVendorAttributes AS LotVendorAttributes,
	|	ARAPAdjustment.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	&VATTaxation AS VATActivityType,
	|
	|	0 AS Cost,
	|	-ARAPAdjustment.VATManag AS CostExcludingVAT,
	|	0 AS VATManag,
	|	-ARAPAdjustment.VATLocal AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS VATLocal,
	|	UNDEFINED AS BusinessOperation,
	|	
	|	ARAPAdjustment.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting
	|
	|FROM
	|	TTTableDebtAdjustment AS ARAPAdjustment
	|WHERE
	|	ARAPAdjustment.ToExpenses
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryWriteOff", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryWriteOff(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryRegistration", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInventoryTypesRevenueAdjustment", QueryTexts) Then
		QueryTextTTInventoryTypesRevenueAdjustment(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	CatAssignments.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VATForShipmentsWithDeferredTransferOfTitle) AS AssetRef,
	|	&Counterparty AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|	
	|	TableTypesOfStocks_.VATLocal AS SumCompl,
	|	TableTypesOfStocks_.VATManag AS SumMan,
	|	TableTypesOfStocks_.AmountIncludingVATMan AS AmountIncludingVAT,
	|	TableTypesOfStocks_.AmountExcludingVATMan AS AmountExcludingVAT,
	|
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTTableTypesOfInventoryWriteOff AS TableTypesOfStocks_
	|
	|	LEFT JOIN 
	|		Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|	LEFT JOIN 
	|		Catalog.Assignments AS CatAssignments
	|	ON 
	|		Dimension.Purpose = CatAssignments.Ref
	|WHERE
	|	VALUETYPE(&DocumentBasis) = TYPE(Document.CustomerInvoice)
	|	AND &BusinessTransactionGrounds = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|	AND TableTypesOfStocks_.InventoryType IN (&InventoryTypesOwn)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	CatAssignments.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VATForShipmentsWithDeferredTransferOfTitle) AS AssetRef,
	|	&Counterparty AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|	
	|	-TableTypesOfStocks_.VATLocal AS SumCompl,
	|	-TableTypesOfStocks_.VATManag AS SumMan,
	|	-TableTypesOfStocks_.AmountIncludingVATMan AS AmountIncludingVAT,
	|	-TableTypesOfStocks_.AmountExcludingVATMan AS AmountExcludingVAT,
	|
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	// The ID fields of the financial record and the setting of the business operation must be filled
	// in the same way in movements for other AP and in revenue and cost of sales. The function of the text query is a table with a handle and the value of sales().
	|	(CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod IN (
	|				VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|				VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AdjustBeforeEnteringBalance)
	|		WHEN &LastPeriodAdjustment
	|		THEN &BusinessTransactionSetting
	|		WHEN TableTypesOfStocks_.Warehouse <> TableTypesOfStocks_.OriginWarehouse
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSaleReturnToAnotherWarehouse)
	|		ELSE &BusinessTransactionSetting END) AS BusinessTransactionSetting
	|FROM
	|	TTTableTypesOfInventoryRegistration AS TableTypesOfStocks_
	|
	|	LEFT JOIN 
	|		Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|	LEFT JOIN 
	|		Catalog.Assignments AS CatAssignments
	|	ON 
	|		Dimension.Purpose = CatAssignments.Ref
	|WHERE
	|	VALUETYPE(&DocumentBasis) = TYPE(Document.CustomerInvoice)
	|	AND &BusinessTransactionGrounds = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|	AND TableTypesOfStocks_.InventoryType IN (&InventoryTypesOwn)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	CatAssignments.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VATForShipmentsWithDeferredTransferOfTitle) AS AssetRef,
	|	&Counterparty AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|	
	|	TableTypesOfStocks_.VATLocal AS SumCompl,
	|	TableTypesOfStocks_.VATManag AS SumMan,
	|	TableTypesOfStocks_.AmountIncludingVATMan AS AmountIncludingVAT,
	|	TableTypesOfStocks_.AmountExcludingVATMan AS AmountExcludingVAT,
	|
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTInventoryTypesRevenueAdjustment AS TableTypesOfStocks_
	|
	|	LEFT JOIN 
	|		Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|	LEFT JOIN 
	|		Catalog.Assignments AS CatAssignments
	|	ON 
	|		Dimension.Purpose = CatAssignments.Ref
	|WHERE
	|	VALUETYPE(&DocumentBasis) = TYPE(Document.CustomerInvoice)
	|	AND &BusinessTransactionGrounds = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|	AND TableTypesOfStocks_.InventoryType IN (&InventoryTypesOwn)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Procedure InitializeTTTypesOfDocumentStocks(Query, QueryTexts)
	
	If Query.Parameters.Property("TTTypesOfStocksAndBases") Then
		Return;
	EndIf;
	
	RequestTypesOfInventory = New Query;
	RequestTypesOfInventory.TempTablesManager = Query.TempTablesManager;
	
	RequestTypesOfInventory.SetParameter("Ref",				Query.Parameters.Ref);
	RequestTypesOfInventory.SetParameter("DocumentBasis",	Query.Parameters.DocumentBasis);
	RequestTypesOfInventory.SetParameter("AdjustingEntryType",	Query.Parameters.AdjustingEntryType);
	
	RequestTypesOfInventory.Text =
	"SELECT
	|	TypesOfStocksOfBases.Products			AS Products,
	|	TypesOfStocksOfBases.Characteristic			AS Characteristic,
	|	MAX(TypesOfStocksOfBases.InventoryOwnerAttribute)	AS InventoryOwnerAttribute,
	|	MAX(TypesOfStocksOfBases.CCDNumber)		AS CCDNumber
	|INTO TTTypesOfStocksAndBases
	|FROM
	|	(SELECT
	|		T.ItemsLocationAttributes.Products	AS Products,
	|		T.ItemsLocationAttributes.Characteristic	AS Characteristic,
	|		T.InventoryOwnerAttribute								AS InventoryOwnerAttribute,
	|		T.CCDNumber									AS CCDNumber
	|	FROM
	|		Document.CustomerInvoice.InventoryKinds AS T
	|	WHERE
	|		T.Ref = &DocumentBasis
	|		AND &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.StandardAdjustment)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		T.ItemsLocationAttributes.Products	AS Products,
	|		T.ItemsLocationAttributes.Characteristic	AS Characteristic,
	|		T.InventoryOwnerAttribute								AS InventoryOwnerAttribute,
	|		T.CCDNumber									AS CCDNumber
	|	FROM
	|		Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS T
	|	WHERE
	|		T.Ref IN (&Ref)
	|		AND &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		T.ItemsLocationAttributes.Products	AS Products,
	|		T.ItemsLocationAttributes.Characteristic	AS Characteristic,
	|		T.InventoryOwnerAttribute								AS InventoryOwnerAttribute,
	|		T.CCDNumber									AS CCDNumber
	|	FROM
	|		Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS T
	|	WHERE
	|		T.Ref IN (&Ref)
	|		AND &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|	
	|	) AS TypesOfStocksOfBases
	|
	|GROUP BY
	|	TypesOfStocksOfBases.Products,
	|	TypesOfStocksOfBases.Characteristic
	|
	|UNION ALL
	|
	|SELECT
	|	T.ItemsLocationAttributes.Products AS Products,
	|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	MAX(T.InventoryOwnerAttribute) AS InventoryOwnerAttribute,
	|	MAX(T.CCDNumber) AS CCDNumber
	|FROM
	|	Document.ReportToMaterialProvider2_5.InventoryKinds AS T
	|WHERE
	|	T.Ref = &DocumentBasis
	|
	|GROUP BY
	|	T.ItemsLocationAttributes.Products,
	|	T.ItemsLocationAttributes.Characteristic
	|";
	
	RequestTypesOfInventory.Execute();
	
	Query.SetParameter("TTTypesOfStocksAndBases", True);
	
EndProcedure

Procedure InitializeTTOfReturnGoods(Query, QueryTexts)
	
	If Query.Parameters.Property("TTReturnGoods") Then
		Return;
	EndIf;
	
	ReturnGoodsRequest = New Query;
	ReturnGoodsRequest.TempTablesManager = Query.TempTablesManager;
	
	ReturnGoodsRequest.SetParameter("Ref",						Query.Parameters.Ref);
	ReturnGoodsRequest.SetParameter("SalesViaCommissionAgent",	Query.Parameters.SalesViaCommissionAgent);
	ReturnGoodsRequest.SetParameter("ShipmentPeriod",				Query.Parameters.ShipmentPeriod);
	
	ReturnGoodsRequest.Text = 
	"SELECT
	|	Discrepancies.Ref.Date AS Period,
	|	&ShipmentPeriod AS SaleDate,
	|	Discrepancies.Ref AS Ref,
	|	Discrepancies.Ref.Counterparty AS Counterparty,
	|	Discrepancies.Ref.Organization AS Organization,
	|	Discrepancies.Ref.CustomerCounterparty AS ConsignedGoodsCustomer,
	|	&SalesViaCommissionAgent AS SalesViaCommissionAgent,
	|	CASE
	|		WHEN Discrepancies.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods)
	|			THEN Discrepancies.Ref
	|		ELSE Discrepancies.Ref.DocumentBasis
	|	END AS DocumentSalesOfGoodsAndServices,
	|	CASE
	|		WHEN Discrepancies.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ErrorCorrection,
	|	CASE
	|		WHEN Discrepancies.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdjustmentUnderApprovalOfParties,
	|	Discrepancies.Ref.VATTaxation AS VATTaxation,
	|	Discrepancies.VATRate AS VATRate
	|INTO TTReturnGoods
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS Discrepancies
	|		LEFT JOIN Document.SaleAdjustment.Goods AS Goods
	|		ON (Goods.Ref IN (&Ref))
	|			AND (Goods.LineNumber = 1)
	|WHERE
	|	Discrepancies.Ref IN (&Ref)
	|	AND Goods.Ref IS NULL";
	
	ReturnGoodsRequest.Execute();
	
	Query.SetParameter("TTReturnGoods", True);
	
EndProcedure

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers, DocumentRef)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	If Common.ObjectAttributeValue(DocumentRef, "BusinessOperation") = Enums.BusinessTransactions.TransferOfTitleToGoods Then 
		Return;
	EndIf;
	
	InitializeTTTypesOfDocumentStocks(Query, QueryTexts);
	
	InitializeTTOfReturnGoods(Query, QueryTexts);
	
	TextProducts_1 =
	"SELECT
	|	Goods.Ref.Date AS Period,
	|	Goods.Ref AS Ref,
	|	Goods.Ref.AdjustmentKind AS BusinessOperation,
	|	Goods.Ref.Counterparty AS Counterparty,
	|	Goods.Ref.Contract AS Contract,
	|	Goods.Ref.Shipper AS Shipper,
	|	Goods.Ref.GoodsRecipient AS GoodsRecipient,
	|	Goods.Ref.Organization AS Organization,
	|	Goods.Ref.Department AS Department,
	|	Goods.Ref.CustomerCounterparty AS ConsignedGoodsCustomer,
	|	&SalesViaCommissionAgent AS SalesViaCommissionAgent,
	|	Goods.Ref.DocumentBasis AS DocumentSalesOfGoodsAndServices,
	|	Goods.Ref AS ImplementationAdjustmentDocument,
	|	TRUE AS ErrorCorrection,
	|	FALSE AS AdjustmentUnderApprovalOfParties,
	|	FALSE AS RetailSaleOfGoods,
	|	UNDEFINED AS ARAPObject,
	|	Goods.Ref.VATTaxation AS VATTaxation,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.PartnerProducts AS PartnerProducts,	
	|	Goods.ProductsInSet AS ProductsInSet,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|	Goods.Content AS Content,
	|	0 AS Count,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN Goods.Products.UnitOfMeasure
	|		ELSE &RequestTextUnitOfMeasurementProducts
	|	END AS UnitOfMeasure,
	|	0 AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	Goods.VATRate AS VATRate,
	|	VALUE(Catalog.FEACN.EmptyRef) AS FEACNCode,
	|	CASE
	|		WHEN Goods.Ref.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		WHEN TRUE
	|			THEN InventoryKinds.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	0 AS LineNumber,
	|	"""" AS RowID,
	|	Discrepancies.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	Document.SaleAdjustment.Goods AS Goods
	|		LEFT JOIN Document.SaleAdjustment.Discrepancies AS Discrepancies
	|		ON (Discrepancies.Ref IN (&Ref))
	|			AND (Discrepancies.LineNumber = 1)
	|		
	|		LEFT JOIN TTTypesOfStocksAndBases AS InventoryKinds
	|		ON (InventoryKinds.Products = Goods.Products)
	|			AND (InventoryKinds.Characteristic = Goods.Characteristic)
	|WHERE
	|	Goods.Ref IN(&Ref)
	|	AND Discrepancies.Ref IS NULL
	|	AND (NOT Goods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5)))
	|	AND Goods.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|	AND Goods.Ref.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.StandardAdjustment)
	|
	|UNION ALL
	|
	|SELECT
	|	Discrepancies.Ref.Date AS Period,
	|	Discrepancies.Ref AS Ref,
	|	Discrepancies.Ref.AdjustmentKind AS BusinessOperation,
	|	Discrepancies.Ref.Counterparty AS Counterparty,
	|	Discrepancies.Ref.Contract AS Contract,
	|	Discrepancies.Ref.Shipper AS Shipper,
	|	Discrepancies.Ref.GoodsRecipient AS GoodsRecipient,
	|	Discrepancies.Ref.Organization AS Organization,
	|	Discrepancies.Ref.Department AS Department,
	|	Discrepancies.Ref.CustomerCounterparty AS ConsignedGoodsCustomer,
	|	&SalesViaCommissionAgent AS SalesViaCommissionAgent,
	|	CASE
	|		WHEN Discrepancies.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods)
	|			THEN Discrepancies.Ref
	|		ELSE Discrepancies.Ref.DocumentBasis
	|	END AS DocumentSalesOfGoodsAndServices,
	|	CASE
	|		WHEN Discrepancies.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods)
	|			THEN UNDEFINED
	|		ELSE Discrepancies.Ref
	|	END AS ImplementationAdjustmentDocument,
	|	CASE
	|		WHEN Discrepancies.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ErrorCorrection,
	|	CASE
	|		WHEN Discrepancies.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdjustmentUnderApprovalOfParties,
	|	FALSE AS RetailSaleOfGoods,
	|	CASE
	|		WHEN &ThisIsAdjustmentToSaleOfServicesOfOtherAssets
	|			THEN CASE
	|				WHEN BEGINOFPERIOD(&Period, YEAR) = BEGINOFPERIOD(&ShipmentPeriod, YEAR)
	|					THEN Discrepancies.ARAPObject
	|				ELSE UNDEFINED
	|			END
	|		WHEN Discrepancies.PostingOption IN 
	|			(VALUE(Enum.CreditNoteRecordingOptions.RecordInOtherIncome),
	|			 VALUE(Enum.CreditNoteRecordingOptions.ToExpenseAs))
	|			THEN UNDEFINED
	|		ELSE Discrepancies.ARAPObject
	|	END AS ARAPObject,
	|	Discrepancies.Ref.VATTaxation AS VATTaxation,
	|	Discrepancies.Products AS Products,
	|	Discrepancies.Characteristic AS Characteristic,
	|	Discrepancies.Series AS Series,
	|	Discrepancies.PartnerProducts AS PartnerProducts,	
	|	Discrepancies.ProductsInSet AS ProductsInSet,
	|	Discrepancies.ItemVariantOfSet AS ItemVariantOfSet,
	|	Discrepancies.Content AS Content,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms OR Discrepancies.NumberOfPackages = 0
	|			THEN Discrepancies.Count
	|		ELSE Discrepancies.NumberOfPackages
	|	END AS Count,
	|	CASE
	|		WHEN Discrepancies.Products = VALUE(Catalog.Products.EmptyRef)
	|			THEN Discrepancies.Package
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN Discrepancies.Products.UnitOfMeasure
	|		ELSE &RequestTextDiscrepancyUnit
	|	END AS UnitOfMeasure,
	|	0 AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	Discrepancies.VATRate AS VATRate,
	|	VALUE(Catalog.FEACN.EmptyRef) AS FEACNCode,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN Discrepancies.Products = VALUE(Catalog.Products.EmptyRef)
	|			THEN Discrepancies.LineNumber
	|		ELSE 0
	|	END AS LineNumber,
	|	Discrepancies.RowID AS RowID,
	|	Discrepancies.RowID AS FinRecordID,
	|	(CASE
	|		WHEN Discrepancies.CostDefiningMethod IN (
	|				VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|				VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AdjustBeforeEnteringBalance)
	|		ELSE &BusinessTransactionSetting END) AS BusinessTransactionSetting
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS Discrepancies
	|WHERE
	|	Discrepancies.Ref IN (&Ref)
	|	AND (Discrepancies.Products.ItemsType IN (
	|			VALUE(Enum.ItemsTypes.OperationService),
	|			VALUE(Enum.ItemsTypes.Work_5))
	|		OR Discrepancies.Products = VALUE(Catalog.Products.EmptyRef))
	|	AND NOT (ISNULL(Discrepancies.Products.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) = VALUE(Enum.ItemsTypes.Work_5)
	|			AND ISNULL(Discrepancies.Products.TracedGoods, FALSE)
	|			AND &UseTraceableImportedGoodsAccounting)
	|	AND (Discrepancies.Ref.AdjustmentKind IN (
	|			VALUE(Enum.BusinessTransactions.ErrorCorrection),
	|			VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties),
	|			VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods))
	|		OR (Discrepancies.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods)
	|			AND NOT Discrepancies.VATRate.PaymentVATRate = &ExportVATRate))
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryKinds.Ref.Date AS Period,
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.Ref.AdjustmentKind AS BusinessOperation,
	|	InventoryKinds.Ref.Counterparty AS Counterparty,
	|	InventoryKinds.Ref.Contract AS Contract,
	|	InventoryKinds.Ref.Shipper AS Shipper,
	|	InventoryKinds.Ref.GoodsRecipient AS GoodsRecipient,
	|	InventoryKinds.Ref.Organization AS Organization,
	|	InventoryKinds.Ref.Department AS Department,
	|	InventoryKinds.Ref.CustomerCounterparty AS ConsignedGoodsCustomer,
	|	&SalesViaCommissionAgent AS SalesViaCommissionAgent,
	|	CASE
	|		WHEN InventoryKinds.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods)
	|			THEN InventoryKinds.Ref
	|		ELSE InventoryKinds.Ref.DocumentBasis
	|	END AS DocumentSalesOfGoodsAndServices,
	|	CASE
	|		WHEN InventoryKinds.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.Ref
	|	END AS ImplementationAdjustmentDocument,
	|	CASE
	|		WHEN InventoryKinds.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ErrorCorrection,
	|	CASE
	|		WHEN InventoryKinds.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdjustmentUnderApprovalOfParties,
	|	FALSE AS RetailSaleOfGoods,
	|	InventoryKinds.ARAPObject AS ARAPObject,
	|	InventoryKinds.Ref.VATTaxation AS VATTaxation,
	|	InventoryKinds.ItemsLocationAttributes.Products AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	InventoryKinds.ItemsLocationAttributes.Series AS Series,
	|	InventoryKinds.PartnerProducts AS PartnerProducts,	
	|	InventoryKinds.SetAccountingDimension.ProductsInSet AS ProductsInSet,
	|	InventoryKinds.SetAccountingDimension.ItemVariantOfSet AS ItemVariantOfSet,
	|	"""" AS Content,
	|	0 AS Count,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN InventoryKinds.ItemsLocationAttributes.Products.UnitOfMeasure
	|		ELSE &QueryTextUnitOfMeasure
	|	END AS UnitOfMeasure,
	|	0 AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	InventoryKinds.VATRate AS VATRate,
	|	InventoryKinds.FEACNCode AS FEACNCode,
	|	CASE
	|		WHEN InventoryKinds.Ref.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		WHEN TRUE
	|			THEN InventoryKinds.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	0 AS LineNumber,
	|	InventoryKinds.RowID AS RowID,
	|	InventoryKinds.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesRevenueAdjustment AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref IN (&Ref)
	|	AND (InventoryKinds.Ref.AdjustmentKind IN (
	|			VALUE(Enum.BusinessTransactions.ErrorCorrection),
	|			VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties))
	|		OR (InventoryKinds.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods)
	|			AND NOT InventoryKinds.VATRate.PaymentVATRate = &ExportVATRate))
	|	AND (CASE
	|		WHEN &ToReturnReusablePackage
	|			THEN InventoryKinds.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		ELSE
	|			TRUE
	|		END)
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryKinds.Ref.Date AS Period,
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.Ref.AdjustmentKind AS BusinessOperation,
	|	InventoryKinds.Ref.Counterparty AS Counterparty,
	|	InventoryKinds.Ref.Contract AS Contract,
	|	InventoryKinds.Ref.Shipper AS Shipper,
	|	InventoryKinds.Ref.GoodsRecipient AS GoodsRecipient,
	|	InventoryKinds.Ref.Organization AS Organization,
	|	InventoryKinds.Ref.Department AS Department,
	|	InventoryKinds.Ref.CustomerCounterparty AS ConsignedGoodsCustomer,
	|	&SalesViaCommissionAgent AS SalesViaCommissionAgent,
	|	CASE
	|		WHEN InventoryKinds.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods)
	|			THEN InventoryKinds.Ref
	|		ELSE InventoryKinds.Ref.DocumentBasis
	|	END AS DocumentSalesOfGoodsAndServices,
	|	CASE
	|		WHEN InventoryKinds.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.Ref
	|	END AS ImplementationAdjustmentDocument,
	|	CASE
	|		WHEN InventoryKinds.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ErrorCorrection,
	|	CASE
	|		WHEN InventoryKinds.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdjustmentUnderApprovalOfParties,
	|	FALSE AS RetailSaleOfGoods,
	|	CASE
	|		WHEN InventoryKinds.ToIncomeExpenses 
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.ARAPObject
	|	END AS ARAPObject,
	|	InventoryKinds.Ref.VATTaxation AS VATTaxation,
	|	InventoryKinds.ItemsLocationAttributes.Products AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	InventoryKinds.ItemsLocationAttributes.Series AS Series,
	|	InventoryKinds.PartnerProducts AS PartnerProducts,	
	|	InventoryKinds.SetAccountingDimension.ProductsInSet AS ProductsInSet,
	|	InventoryKinds.SetAccountingDimension.ItemVariantOfSet AS ItemVariantOfSet,
	|	"""" AS Content,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms OR InventoryKinds.NumberOfPackages = 0
	|			THEN -InventoryKinds.Count
	|		ELSE -InventoryKinds.NumberOfPackages
	|	END AS Count,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN InventoryKinds.ItemsLocationAttributes.Products.UnitOfMeasure
	|		ELSE &QueryTextUnitOfMeasure
	|	END AS UnitOfMeasure,
	|	-InventoryKinds.QuantityByGBRN AS QuantityByGBRN,
	|	-InventoryKinds.ExciseTaxAmount AS ExciseTaxAmount,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	InventoryKinds.VATRate AS VATRate,
	|	InventoryKinds.FEACNCode AS FEACNCode,
	|	CASE
	|		WHEN InventoryKinds.Ref.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		WHEN TRUE
	|			THEN InventoryKinds.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	0 AS LineNumber,
	|	InventoryKinds.RowID AS RowID,
	|	InventoryKinds.RowID AS FinRecordID,
	|	(CASE
	|		WHEN InventoryKinds.CostDefiningMethod IN (
	|				VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|				VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AdjustBeforeEnteringBalance)
	|		ELSE &BusinessTransactionSetting END) AS BusinessTransactionSetting
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref IN (&Ref)
	|	AND (InventoryKinds.Ref.AdjustmentKind IN (
	|			VALUE(Enum.BusinessTransactions.ErrorCorrection),
	|			VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties))
	|		OR (InventoryKinds.Ref.AdjustmentKind IN (
	|			VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods),
	|			VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods))
	|			AND NOT InventoryKinds.VATRate.PaymentVATRate = &ExportVATRate))
	|	AND (CASE
	|		WHEN &ToReturnReusablePackage
	|			THEN InventoryKinds.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		ELSE
	|			TRUE
	|		END)
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryKinds.Ref.Date AS Period,
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.Ref.AdjustmentKind AS BusinessOperation,
	|	InventoryKinds.Ref.Counterparty AS Counterparty,
	|	InventoryKinds.Ref.Contract AS Contract,
	|	InventoryKinds.Ref.Shipper AS Shipper,
	|	InventoryKinds.Ref.GoodsRecipient AS GoodsRecipient,
	|	InventoryKinds.Ref.Organization AS Organization,
	|	InventoryKinds.Ref.Department AS Department,
	|	InventoryKinds.Ref.CustomerCounterparty AS ConsignedGoodsCustomer,
	|	&SalesViaCommissionAgent AS SalesViaCommissionAgent,
	|	CASE
	|		WHEN InventoryKinds.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods)
	|			THEN InventoryKinds.Ref
	|		ELSE InventoryKinds.Ref.DocumentBasis
	|	END AS DocumentSalesOfGoodsAndServices,
	|	CASE
	|		WHEN InventoryKinds.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.Ref
	|	END AS ImplementationAdjustmentDocument,
	|	CASE
	|		WHEN InventoryKinds.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ErrorCorrection,
	|	CASE
	|		WHEN InventoryKinds.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdjustmentUnderApprovalOfParties,
	|	FALSE AS RetailSaleOfGoods,
	|	CASE
	|		WHEN InventoryKinds.ToIncomeExpenses 
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.ARAPObject
	|	END AS ARAPObject,
	|	InventoryKinds.Ref.VATTaxation AS VATTaxation,
	|	InventoryKinds.ItemsLocationAttributes.Products AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	InventoryKinds.ItemsLocationAttributes.Series AS Series,
	|	InventoryKinds.PartnerProducts AS PartnerProducts,	
	|	InventoryKinds.SetAccountingDimension.ProductsInSet AS ProductsInSet,
	|	InventoryKinds.SetAccountingDimension.ItemVariantOfSet AS ItemVariantOfSet,
	|	"""" AS Content,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms OR InventoryKinds.NumberOfPackages = 0
	|			THEN InventoryKinds.Count
	|		ELSE InventoryKinds.NumberOfPackages
	|	END AS Count,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN InventoryKinds.ItemsLocationAttributes.Products.UnitOfMeasure
	|		ELSE &QueryTextUnitOfMeasure
	|	END AS UnitOfMeasure,
	|	InventoryKinds.QuantityByGBRN AS QuantityByGBRN,
	|	InventoryKinds.ExciseTaxAmount AS ExciseTaxAmount,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	InventoryKinds.VATRate AS VATRate,
	|	InventoryKinds.FEACNCode AS FEACNCode,
	|	CASE
	|		WHEN InventoryKinds.Ref.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		WHEN TRUE
	|			THEN InventoryKinds.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	0 AS LineNumber,
	|	InventoryKinds.RowID AS RowID,
	|	InventoryKinds.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref IN (&Ref)
	|	AND (InventoryKinds.Ref.AdjustmentKind IN (
	|			VALUE(Enum.BusinessTransactions.ErrorCorrection),
	|			VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties))
	|		OR (InventoryKinds.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods)
	|			AND NOT InventoryKinds.VATRate.PaymentVATRate = &ExportVATRate))
	|	AND (CASE
	|		WHEN &ToReturnReusablePackage
	|			THEN InventoryKinds.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		ELSE
	|			TRUE
	|		END)
	|
	|UNION ALL
	|
	|SELECT
	|	ARAPAdjustment.Ref.Date AS Period,
	|	ARAPAdjustment.Ref AS Ref,
	|	ARAPAdjustment.Ref.AdjustmentKind AS BusinessOperation,
	|	ARAPAdjustment.Ref.Counterparty AS Counterparty,
	|	ARAPAdjustment.Ref.Contract AS Contract,
	|	ARAPAdjustment.Ref.Shipper AS Shipper,
	|	ARAPAdjustment.Ref.GoodsRecipient AS GoodsRecipient,
	|	ARAPAdjustment.Ref.Organization AS Organization,
	|	ARAPAdjustment.Ref.Department AS Department,
	|	ARAPAdjustment.Ref.CustomerCounterparty AS ConsignedGoodsCustomer,
	|	&SalesViaCommissionAgent AS SalesViaCommissionAgent,
	|	ARAPAdjustment.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	ARAPAdjustment.Ref  AS ImplementationAdjustmentDocument,
	|	FALSE AS ErrorCorrection,
	|	TRUE AS AdjustmentUnderApprovalOfParties,
	|	FALSE AS RetailSaleOfGoods,
	|	UNDEFINED AS ARAPObject,
	|	ARAPAdjustment.Ref.VATTaxation AS VATTaxation,
	|	UNDEFINED AS Products,
	|	UNDEFINED AS Characteristic,
	|	UNDEFINED AS Series,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,	
	|	UNDEFINED AS ProductsInSet,
	|	UNDEFINED AS ItemVariantOfSet,
	|	ARAPAdjustment.ReasonForAdjustment AS Content,
	|	0 AS Count,
	|	UNDEFINED AS UnitOfMeasure,
	|	0 AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	UNDEFINED AS CCDNumber,
	|	ARAPAdjustment.VATRate AS VATRate,
	|	UNDEFINED AS FEACNCode,
	|	UNDEFINED AS InventoryOwnerAttribute,
	|	0 AS LineNumber,
	|	ARAPAdjustment.RowID AS RowID,
	|	ARAPAdjustment.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	Document.SaleAdjustment.ARAPAdjustment AS ARAPAdjustment
	|WHERE
	|	ARAPAdjustment.Ref IN (&Ref)
	|";
	
	TextProducts_1 = StrReplace(
		TextProducts_1,
		"&RequestTextUnitOfMeasurementProducts",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"Goods.Package",
			"Goods.Products"));
	TextProducts_1 = StrReplace(
		TextProducts_1,
		"&RequestTextDiscrepancyUnit",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"Discrepancies.Package",
			"Discrepancies.Products"));
	TextProducts_1 = StrReplace(
		TextProducts_1,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"InventoryKinds.Package",
			"InventoryKinds.ItemsLocationAttributes.Products"));
		
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	VATAccountingERP.ReflectImplementationToClient(Query, QueryTexts, Registers, TextProducts_1);
	
EndProcedure

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref                                 AS Ref,
	|	&Period                                 AS IBDocumentDate,
	|	&Number                                  AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	CASE
	|		WHEN &DocumentBasis <> UNDEFINED
	|			THEN &BusinessTransactionGrounds
	|		ELSE &AdjustmentKind
	|	END                                   AS BusinessOperation,
	|	&Partner                                AS Partner,
	|	&Counterparty                             AS Counterparty,
	|	&Contract                                AS Contract,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	&Warehouse                                  AS StorageLocation,
	|	&Department                          AS Department,
	|	&Manager                               AS EmployeeResponsible,
	|	&Author                                  AS Author,
	|	&Comment                            AS Comment,
	|	&Currency                                 AS Currency,
	|	&DocumentAmount                         AS Sum,
	|	UNDEFINED                            AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&ContractInformation                   AS More,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|FROM
	|	Document.SaleAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText
	
EndFunction

Function QueryTextTTCorrectionDocumentToBeCorrected(Query)

	DocumentBeingCorrectedIsEmptyLinks = New Array;
	
	For Each Type In Metadata.Documents.SaleAdjustment.Attributes.CorrectedDocument.Type.Types() Do
		DocumentBeingCorrectedIsEmptyLinks.Add(New (Type));
	EndDo;
	
	Query.SetParameter("DocumentBeingCorrectedIsEmptyLinks", DocumentBeingCorrectedIsEmptyLinks);
	
	QueryText =
	"SELECT
	|	&CorrectedDocument AS CorrectedDocument
	|
	|INTO TT_CorrectedDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	SaleAdjustment.Ref AS Adjusting,
	|	SaleAdjustment.DocumentBasis AS DocumentBasis
	|INTO TT_AdjustmentUnderApprovalOfParties
	|FROM
	|	Document.SaleAdjustment AS SaleAdjustment
	|		LEFT JOIN InformationRegister.DocumentCorrections AS DocumentCorrections
	|		ON DocumentCorrections.CorrectedDocument = SaleAdjustment.Ref
	|		AND DocumentCorrections.DocumentToCorrectIsReversed
	|WHERE
	|	SaleAdjustment.DocumentBasis = &DocumentBasis
	|	AND SaleAdjustment.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
	|	AND SaleAdjustment.Posted
	|	AND SaleAdjustment.Date < &Period
	|	AND DocumentCorrections.CorrectedDocument IS NULL
	|
	|ORDER BY
	|	SaleAdjustment.Date DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN TT_CorrectedDocument.CorrectedDocument = UNDEFINED
	|		OR TT_CorrectedDocument.CorrectedDocument IN (&DocumentBeingCorrectedIsEmptyLinks)
	|			THEN ISNULL(TT_AdjustmentUnderApprovalOfParties.Adjusting, &DocumentBasis)
	|		ELSE TT_CorrectedDocument.CorrectedDocument
	|	END AS CorrectedDocument
	|INTO TT_CorrectionDocumentBeingCorrected
	|FROM
	|	TT_CorrectedDocument AS TT_CorrectedDocument
	|		LEFT JOIN TT_AdjustmentUnderApprovalOfParties AS TT_AdjustmentUnderApprovalOfParties
	|		ON (TT_AdjustmentUnderApprovalOfParties.DocumentBasis = &DocumentBasis)
	|WHERE
	|	&AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_AdjustmentUnderApprovalOfParties
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_CorrectedDocument" + Common.QueryBatchSeparator();

	Return QueryText;
	
EndFunction

Function QueryTextTTDocumentCorrectionTable(Query, QueryTexts) Export
	
	RegisterName = "TTDocumentCorrectionTable";
	
	QueryTextTTDocumentToBeCorrected = QueryTextTTCorrectionDocumentToBeCorrected(Query);
		
	QueryText = QueryTextTTDocumentToBeCorrected +
	"SELECT
	|	DocumentCorrectionsSliceLast.CorrectedDocument AS CorrectedDocument,
	|	DocumentCorrectionsSliceLast.LastChainDocument AS LastChainDocument
	|INTO TT_Patch
	|FROM
	|	InformationRegister.DocumentCorrections.SliceLast(&BorderExcludingDocument, CorrectedDocument IN
	|		(SELECT
	|			TT_CorrectionDocumentBeingCorrected.CorrectedDocument
	|		FROM
	|			TT_CorrectionDocumentBeingCorrected)) AS DocumentCorrectionsSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Period AS Period,
	|	TT_CorrectionDocumentBeingCorrected.CorrectedDocument AS CorrectedDocument,
	|	ISNULL(TT_Patch.LastChainDocument, UNDEFINED) AS PreviousCorrection,
	|	&Ref AS LastChainDocument,
	|	FALSE AS DocumentToCorrectIsReversed,
	|	FALSE AS CorrectionMethodStorno
	|INTO TTDocumentCorrectionTable
	|FROM
	|	TT_CorrectionDocumentBeingCorrected AS TT_CorrectionDocumentBeingCorrected
	|		LEFT JOIN TT_Patch AS TT_Patch
	|		ON TT_CorrectionDocumentBeingCorrected.CorrectedDocument = TT_Patch.CorrectedDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_Patch";
				
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentCorrections(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentCorrections";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
		
	If Not DocumentsPosting.ThereIsQueryTable("TTDocumentCorrectionTable", QueryTexts) Then
		QueryTextTTDocumentCorrectionTable(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	TTDocumentCorrectionTable.Period,
	|	TTDocumentCorrectionTable.CorrectedDocument,
	|	TTDocumentCorrectionTable.PreviousCorrection,
	|	TTDocumentCorrectionTable.LastChainDocument,
	|	TTDocumentCorrectionTable.DocumentToCorrectIsReversed,
	|	TTDocumentCorrectionTable.CorrectionMethodStorno
	|FROM
	|	TTDocumentCorrectionTable AS TTDocumentCorrectionTable";
				
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                     AS Document,
	|	&Period                     AS Period,
	|	SeriesTable.Products   AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                       AS Purpose,
	|	SeriesTable.Series          AS Series,
	|	SeriesTable.Count     AS Count,
	|	SeriesTable.Warehouse          AS Sender,
	|	&Partner                    AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.ShipmentToCustomer) AS WarehouseOperation,
	|	TRUE                      AS ThisIsWarehouseRecord
	|FROM
	|	Document.SaleAdjustment.Goods AS SeriesTable
	|
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBonusPoints(Query, QueryTexts)
	
	RegisterName = "TTBonusPoints"; 
	
	QueryText = 
	"SELECT
	|	TabularSection.AccrualDate                            AS Period,
	|	CASE
	|		WHEN TabularSection.DateOfDeduction <> DATETIME(1, 1, 1)
	|			THEN TabularSection.AccrualDate
	|		ELSE DATETIME(1, 1, 1)
	|	END                                                     AS ValidityStartDate,
	|	CASE
	|		WHEN TabularSection.DateOfDeduction <> DATETIME(1, 1, 1)
	|			THEN &CurrentDate
	|		ELSE DATETIME(1, 1, 1)
	|	END                                                     AS DateToProcess,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END                                                     AS RecordType,
	|	TabularSection.LoyaltyProgram                AS LoyaltyProgram,
	|	&Partner                                                  AS Partner,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN -TabularSection.AmountOfBonusPoints
	|		ELSE TabularSection.AmountOfBonusPoints
	|	END AS Accrued,
	|	0                                                         AS ToWriteOff
	|INTO TTBonusPoints
	|FROM
	|	Document.SaleAdjustment.BonusPointAccrual AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND TabularSection.AccrualDate <> DATETIME(1,1,1)
	|
	|UNION ALL
	|
	|SELECT
	|	TabularSection.DateOfDeduction                              AS Period,
	|	TabularSection.AccrualDate                            AS ValidityStartDate,
	|	&CurrentDate                                             AS DateToProcess,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	TabularSection.LoyaltyProgram               AS LoyaltyProgram,
	|	&Partner                                                 AS Partner,
	|	0                                                        AS Accrued,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN -TabularSection.AmountOfBonusPoints
	|		ELSE TabularSection.AmountOfBonusPoints
	|	END AS ToWriteOff
	|FROM
	|	Document.SaleAdjustment.BonusPointAccrual AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND TabularSection.DateOfDeduction <> DATETIME(1,1,1)
	|
	|UNION ALL
	|
	|SELECT
	|	TabularSection.PayDate AS Period,
	|	DATETIME(1, 1, 1),
	|	&CurrentDate,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TabularSection.LoyaltyProgram               AS LoyaltyProgram,
	|	&Partner                                                 AS Partner,
	|	TabularSection.AmountOfBonusPoints AS Accrued,
	|	0 AS ToWriteOff
	|FROM
	|	Document.SaleAdjustment.PaymentWithBonusPoints AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableBonusPoints(Query, QueryTexts, Registers, Document)
	
	RegisterName = "BonusPoints";
	
	If Not BonusPointsServer.ItIsRequiredToAddRegisterRegisteredRecordsBonusPoints(Document) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBonusPoints", QueryTexts) Then
		QueryTextTTBonusPoints(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	BonusPoints.Period                      AS Period,
	|	BonusPoints.ValidityStartDate          AS ValidityStartDate,
	|	BonusPoints.DateToProcess              AS DateToProcess,
	|	BonusPoints.RecordType                 AS RecordType,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner                     AS Partner,
	|	SUM(BonusPoints.Accrued)            AS Accrued,
	|	SUM(BonusPoints.ToWriteOff)            AS ToWriteOff
	|FROM
	|	TTBonusPoints AS BonusPoints
	|
	|GROUP BY
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.Period,
	|	BonusPoints.ValidityStartDate,
	|	BonusPoints.DateToProcess,
	|	BonusPoints.RecordType
	|HAVING 
	|	SUM(BonusPoints.Accrued) <> 0 OR 
	|	SUM(BonusPoints.ToWriteOff) <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref               AS Ref,
		|	TabPart.Ref.Date          AS Period,
		|	TabPart.Products         AS Products,
		|	TabPart.Characteristic       AS Characteristic,
		|	CASE 
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Department
		|		ELSE
		|			TabPart.Warehouse
		|	END                         AS Warehouse,
		|	TabPart.Purpose           AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count           AS Count,
		|	UNDEFINED                  AS PlannedConsumptionOfDistributedStock,
		|	FALSE                          AS ControlOfFreeResidue
		|FROM
		|	Document.SaleAdjustment.Discrepancies AS TabPart
		|WHERE
		|	(TabPart.PostingOption IN(
		|		VALUE(Enum.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock),
		|		VALUE(Enum.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock),
		|		VALUE(Enum.CreditNoteRecordingOptions.IncreaseSale),
		|		VALUE(Enum.CreditNoteRecordingOptions.ReduceSale))
		|	OR TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|		AND NOT TabPart.PostingOption IN (
		|				VALUE(Enum.CreditNoteRecordingOptions.RecordInOtherIncome),
		|				VALUE(Enum.CreditNoteRecordingOptions.ToExpenseAs)))
		|	AND ISNULL(TabPart.Ref.DocumentBasis.BusinessOperation, VALUE(Enum.BusinessTransactions.EmptyRef)) <> VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent)
		|	AND ISNULL(TabPart.Ref.DocumentBasis.BusinessOperation, VALUE(Enum.BusinessTransactions.EmptyRef)) <> VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
		|";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
EndProcedure

Function QueryTextTableShipmentReferences(Query, QueryTexts, Registers)
	
	RegisterName = "ShipmentAndReturnReferences";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	DivergenceTable.LineNumber AS LineNumber,
	|	DivergenceTable.Ref.Date AS Period,
	|	DivergenceTable.Ref AS ReferenceOrder,
	|	DivergenceTable.Products AS Products,
	|	DivergenceTable.Characteristic AS Characteristic,
	|	DivergenceTable.RowCode AS RowCode,
	|	CASE
	|		WHEN TableOfIndicators.Ref = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving)
	|			THEN DivergenceTable.Warehouse
	|		ELSE
	|			VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	CASE
	|		WHEN TableOfIndicators.Ref = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving)
	|				AND DivergenceTable.BatchesIndicationStatus IN (10, 14)
	|			THEN DivergenceTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	-DivergenceTable.Count AS Count,
	|	CASE
	|		WHEN DivergenceTable.AmountARAP > 0
	|			THEN DivergenceTable.AmountARAP
	|		ELSE
	|			-DivergenceTable.AmountARAP
	|	END AS Sum,
	|	CASE
	|		WHEN DivergenceTable.VATAmountCompl > 0
	|			THEN DivergenceTable.VATAmountCompl
	|		ELSE
	|			-DivergenceTable.VATAmountCompl
	|	END AS VATAmountCompl,
	|	CASE
	|		WHEN DivergenceTable.VATAmountMan > 0
	|			THEN DivergenceTable.VATAmountMan
	|		ELSE
	|			-DivergenceTable.VATAmountMan
	|	END AS VATAmountMan
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS DivergenceTable
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.RequestedForReturn),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegisterForReturns),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.RegisteredOnReturns),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving))
	|WHERE
	|	DivergenceTable.Ref = &Ref
	|	AND DivergenceTable.PostingOption = VALUE(Enum.CreditNoteRecordingOptions.ReturnToTransit)
	|	AND VALUETYPE(DivergenceTable.Ref.DocumentBasis) = TYPE(Document.CustomerInvoice)
	|	AND DivergenceTable.Ref.BusinessOperation IN
	|	(VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods),
	|		VALUE(Enum.BusinessTransactions.SaleToCustomer))
	|
	|UNION ALL
	|
	|SELECT
	|	DivergenceTable.LineNumber AS LineNumber,
	|	DivergenceTable.Ref.Date AS Period,
	|	DivergenceTable.Ref AS ReferenceOrder,
	|	DivergenceTable.Products AS Products,
	|	DivergenceTable.Characteristic AS Characteristic,
	|	DivergenceTable.RowCode AS RowCode,
	|	CASE
	|		WHEN TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
	|			THEN DivergenceTable.Warehouse
	|		ELSE
	|			VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	CASE
	|		WHEN TableOfIndicators.Ref IN (
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered),
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
	|				)
	|			AND DivergenceTable.BatchesIndicationStatus IN (10, 14)
	|			THEN DivergenceTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	DivergenceTable.Count AS Count,
	|	DivergenceTable.AmountARAP AS Sum,
	|	DivergenceTable.VATAmountCompl AS VATAmountCompl,
	|	DivergenceTable.VATAmountMan AS VATAmountMan
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS DivergenceTable
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1))
	|WHERE
	|	DivergenceTable.Ref = &Ref
	|	AND DivergenceTable.PostingOption <> VALUE(Enum.CreditNoteRecordingOptions.ReturnToTransit)
	|	AND VALUETYPE(DivergenceTable.Ref.DocumentBasis) = TYPE(Document.CustomerInvoice)
	|	AND DivergenceTable.Ref.BusinessOperation IN
	|	(VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods),
	|		VALUE(Enum.BusinessTransactions.SaleToCustomer))
	|
	|UNION ALL
	|
	|SELECT
	|	DivergenceTable.LineNumber AS LineNumber,
	|	DivergenceTable.Ref.Date AS Period,
	|	DivergenceTable.SalesOrder AS ReferenceOrder,
	|	DivergenceTable.Products AS Products,
	|	DivergenceTable.Characteristic AS Characteristic,
	|	DivergenceTable.BaseDocumentLineCode AS RowCode,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	CASE
	|		WHEN DivergenceTable.BatchesIndicationStatus IN (10, 14)
	|			THEN DivergenceTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WasAdjusted) AS Factor,
	|	DivergenceTable.Count AS Count,
	|	DivergenceTable.AmountARAP AS Sum,
	|	DivergenceTable.VATAmountCompl AS VATAmountCompl,
	|	DivergenceTable.VATAmountMan AS VATAmountMan
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS DivergenceTable
	|WHERE
	|	DivergenceTable.Ref = &Ref
	|	AND VALUETYPE(DivergenceTable.Ref.DocumentBasis) = TYPE(Document.CustomerInvoice)
	|	AND DivergenceTable.Ref.BusinessOperation =
	|		VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|
	|ORDER BY
	|	LineNumber,
	|	Factor";
	
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
	
	If Query <> Undefined Then
		AdditionalParameters.Add("AccountingDimensionByPartners");
		SetParametersForPartnerAccountingAnalystRequest(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined,
	QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	
	If Query <> Undefined Then
		If QueryTexts = Undefined Then
			QueryTexts = New ValueList;
		EndIf;
		
		TableName = "DocumentDataHeader";
		If Not DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
			AdditionalTables.Add(TableName);
			QueryTexts.Add(QueryTextDocumentDataHeader(), TableName);
		EndIf;
		
		TableName = "TTTableTypesOfInventoryWriteOff";
		If Not DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
			AdditionalTables.Add(TableName);
			QueryTextTTTableTypesOfInventoryWriteOff(Query, QueryTexts);
		EndIf;
		
		TableName = "TTTableTypesOfInventoryRegistration";
		If Not DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
			AdditionalTables.Add(TableName);
			QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts);
		EndIf;
		
		TableName = "TTDivergenceOfServiceOperation";
		If Not DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
			AdditionalTables.Add(TableName);
			QueryTextTTDivergenceOfServiceOperation(Query, QueryTexts);
		EndIf;
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region SaleOfGoodsAndServices_OwnGoods_TraceableWork_N1
	// Types of inventory to be written off
	
	QueryText =
	"SELECT
	// Document description
	|	DocumentTable.Period AS Period,
	|	DocumentTable.Ref AS Ref,  
	|	UNDEFINED AS VariancePeriod,
	|	UNDEFINED AS DocumentSource,
	|	UNDEFINED AS SourceDocumentPeriod,
	|	UNDEFINED AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization					AS Organization,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.ItemsLocationAttributes
	|		ELSE InventoryKinds.AnalysisOfAccountingForProductsWithoutAssignment
	|	END											AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute 							AS InventoryOwnerAttribute,
	|	InventoryKinds.VATActivityType					AS VATActivityType,
	|	InventoryKinds.VATActivityType					AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED									AS CorCompany,
	|	CASE
	|		WHEN InventoryKinds.InventoryType IN
	|			(VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			THEN
	|				CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|					THEN InventoryKinds.ItemsLocationAttributes
	|					ELSE InventoryKinds.AnalysisOfAccountingForProductsWithoutAssignment
	|				END
	|		ELSE UNDEFINED
	|	END											AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN InventoryKinds.InventoryType IN
	|			(VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			THEN InventoryKinds.CorInventoryOwnerAttribute
	|		ELSE UNDEFINED
	|	END											AS CorInventoryOwnerAttribute,
	|	UNDEFINED									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	InventoryKinds.VATActivityType					AS CorVATActivityTypes,
	|	&AccountingDimensionByPartners 						AS AccountingDimensionByPartners,
	|	CASE WHEN DocumentTable.SaleByOrders THEN
	|		InventoryKinds.SalesOrder
	|	ELSE
	|		DocumentTable.DocumentBasis
	|	END											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department	AS Department,
	|	DocumentTable.Manager		AS Manager,
	|	UNDEFINED					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	InventoryKinds.Count			AS Count,
	|
	// Other fields
	|	UNDEFINED							AS RowID,
	|	InventoryKinds.RowID			AS FinRecordID,
	|	CASE WHEN &SalesViaCommissionAgent 
	|			THEN DocumentTable.BusinessTransactionGrounds
	|		WHEN InventoryKinds.InventoryType IN (
	|				VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|		THEN DocumentTable.BusinessOperation
	|		ELSE VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|	END									AS BusinessOperation,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableTypesOfInventoryWriteOff AS InventoryKinds
	|		ON TRUE
	|WHERE
	|	(NOT InventoryKinds.ToIncomeExpenses OR &SaleAdjustment2_5)
	|	AND InventoryKinds.InventoryType IN
	|		(VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.Work_5),
	|		VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|		VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|	AND (InventoryKinds.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR (InventoryKinds.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND NOT &ToReturnReusablePackage)
	|		OR InventoryKinds.ItemsType IS NULL)
	|	AND NOT InventoryKinds.ToExpenseAs
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
	#Region RecogniseAsExpensesAssets_OwnGoods_TraceableWork_N2
	// Types of inventory to be written off
	
	QueryText =
	"SELECT
	// Document description
	|	DocumentTable.Period AS Period,
	|	DocumentTable.Ref AS Ref,
	|	CASE
	|		WHEN &AdjustmentOfPreviousPeriodYear
	|			THEN &AdjustmentPeriod_ 
	|		ELSE UNDEFINED
	|	END        AS VariancePeriod,
	|	UNDEFINED AS DocumentRegisterRecords,
	|	UNDEFINED AS DocumentSource,
	|	UNDEFINED AS SourceDocumentPeriod,
	|	UNDEFINED AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization					AS Organization,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.ItemsLocationAttributes
	|		ELSE InventoryKinds.AnalysisOfAccountingForProductsWithoutAssignment
	|	END											AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute 							AS InventoryOwnerAttribute,
	|	InventoryKinds.VATActivityType					AS VATActivityType,
	|	InventoryKinds.VATActivityType					AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	UNDEFINED AS Lot,
	|	UNDEFINED AS LotVendorAttributes,
	|
	// Corresponding fields
	|	UNDEFINED									AS CorCompany,
	|	CASE
	|		WHEN InventoryKinds.InventoryType IN
	|			(VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			THEN
	|				CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|					THEN InventoryKinds.ItemsLocationAttributes
	|					ELSE InventoryKinds.AnalysisOfAccountingForProductsWithoutAssignment
	|				END
	|		ELSE UNDEFINED
	|	END											AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN InventoryKinds.InventoryType IN
	|			(VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			THEN InventoryKinds.CorInventoryOwnerAttribute
	|		ELSE UNDEFINED
	|	END											AS CorInventoryOwnerAttribute,
	|	UNDEFINED									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners 						AS AccountingDimensionByPartners,
	|	CASE WHEN DocumentTable.SaleByOrders THEN
	|		InventoryKinds.SalesOrder
	|	ELSE
	|		DocumentTable.DocumentBasis
	|	END											AS SalesOrder,
	|	InventoryKinds.ExpenseAnalyticsWriteOff			AS AssetExpenseAnalytics,
	|	InventoryKinds.ExpenseItemWriteOff				AS ExpenseItemAssets,
	|	InventoryKinds.LineOfBusiness				AS CorLineOfBusiness,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department	AS Department,
	|	DocumentTable.Manager		AS Manager,
	|	UNDEFINED					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	InventoryKinds.Count			AS Count,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|	0 AS CostMan,
	|
	// Other fields
	|	CASE WHEN &SalesViaCommissionAgent 
	|			THEN DocumentTable.BusinessTransactionGrounds
	|		WHEN InventoryKinds.InventoryType IN (
	|				VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|		THEN VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses)
	|		ELSE VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|	END									AS BusinessOperation,
	|	UNDEFINED							AS RowID,
	|	InventoryKinds.RowID			AS FinRecordID,
	|	CASE
	|		WHEN InventoryKinds.InventoryType IN (
	|				VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses)
	|		ELSE &BusinessTransactionSetting
	|	END									AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableTypesOfInventoryWriteOff AS InventoryKinds
	|		ON TRUE
	|WHERE
	|	(NOT InventoryKinds.ToIncomeExpenses OR &SaleAdjustment2_5)
	|	AND InventoryKinds.InventoryType IN
	|		(VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.Work_5),
	|		VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|		VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|	AND (InventoryKinds.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR (InventoryKinds.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage) AND NOT &ToReturnReusablePackage)
	|		OR InventoryKinds.ItemsType IS NULL)
	|	AND InventoryKinds.ToExpenseAs
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.RecogniseAsExpensesAssets,
		QueryText);
	
	#EndRegion

	#Region SaleOfGoodsAndServices_Work_5_N3
	//Works. Sale.
	
	QueryText =
	"SELECT
	// Document description
	|	DocumentTable.Period	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN DivergenceTable.ItemsLocationAttributes
	|		ELSE DivergenceTable.AnalysisOfAccountingForProductsWithoutAssignment
	|	END											AS ItemsLocationAttributes,
	|	DivergenceTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	DivergenceTable.VATActivityType			AS VATActivityType,
	|	DivergenceTable.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED									AS CorCompany,
	|	UNDEFINED									AS CorItemsLocationAttributes,
	|	UNDEFINED 									AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners 						AS AccountingDimensionByPartners,
	|	CASE WHEN DocumentTable.SaleByOrders THEN
	|		DivergenceTable.SalesOrder
	|	ELSE
	|		DocumentTable.DocumentBasis
	|	END											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	DivergenceTable.Count	AS Count,
	|
	// Other fields
	|	UNDEFINED							AS RowID,
	|	DivergenceTable.RowID	AS FinRecordID,
	|	DocumentTable.BusinessOperation	AS BusinessOperation,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting 
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTDivergenceOfServiceOperation AS DivergenceTable
	|		ON TRUE
	|WHERE
	|	NOT DivergenceTable.ToExpenseAs
	|	AND (NOT DivergenceTable.ToIncomeExpenses OR &SaleAdjustment2_5)
	|	AND (DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		OR &BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|	)
	|	AND DivergenceTable.Count > 0
	|	AND NOT DivergenceTable.TracedGoods
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
	#Region DisposalAtFixedCost_Packaging_N4
	// Write-off of multi-turn containers for return
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Period	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	CASE
	|		WHEN &AdjustmentOfPreviousPeriodYear
	|			THEN &AdjustmentPeriod_ 
	|		ELSE UNDEFINED
	|	END 					AS VariancePeriod,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.ItemsLocationAttributes
	|		ELSE InventoryKinds.AnalysisOfAccountingForProductsWithoutAssignment
	|	END											AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute 							AS InventoryOwnerAttribute,
	|	InventoryKinds.VATActivityType					AS VATActivityType,
	|	InventoryKinds.VATActivityType					AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 									AS CorItemsLocationAttributes,
	|	UNDEFINED 									AS CorInventoryOwnerAttribute,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.DifferencesInCostOfReturnAndActualCostOfGoods) AS ExpenseItemAssets,
	|	DocumentTable.Partner 						AS AssetExpenseAnalytics,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.DifferencesInCostOfReturnAndActualCostOfGoods)  AS IncomeItem,
	|	DocumentTable.Partner 						AS DimensionOfRevenue,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	InventoryKinds.Count			AS Count,
	|	InventoryKinds.AmountIncludingVATMan		AS Cost,
	|	InventoryKinds.AmountExcludingVATMan		AS CostExcludingVAT,
	|	InventoryKinds.AmountExcludingVATCompl		AS LocalCost,
	|	CASE
	|		WHEN NOT &CompanyManagementAccounting THEN 0
	|		ELSE InventoryKinds.AmountExcludingVATMan
	|	END							AS CostMan,
	|	0								AS CorGrossInitialCostENT,
	|
	// Other fields
	|	UNDEFINED																	AS RowID,
	|	InventoryKinds.RowID													AS FinRecordID,
	|	VALUE(Enum.BusinessTransactions.SaleOfTransferredReturnablePackaging)	AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer)			AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableTypesOfInventoryWriteOff AS InventoryKinds
	|		ON TRUE
	|WHERE
	|	(NOT InventoryKinds.ToIncomeExpenses OR &SaleAdjustment2_5)
	|	AND InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|	AND InventoryKinds.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND &ToReturnReusablePackage";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.DisposalAtFixedCost,
		QueryText);
		
	#EndRegion

	#Region SaleOfGoodsAndServices_ConsignedGoods_SaleWithDeferredTransferOfTitle_N5
	
	QueryText =
	"SELECT
	// Document description
	|	DocumentTable.Period	AS Period,
	|	DocumentTable.Ref	AS Ref,
	|	UNDEFINED			AS VariancePeriod,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization 						AS Organization,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.ItemsLocationAttributes
	|		ELSE InventoryKinds.AnalysisOfAccountingForProductsWithoutAssignment
	|	END												AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute 								AS InventoryOwnerAttribute,
	|	InventoryKinds.VATActivityType						AS VATActivityType,
	|	InventoryKinds.VATActivityType						AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 										AS CorCompany,
	|	CASE
	|		WHEN DocumentTable.AdjustmentOfShipmentWithoutTransferOfOwnership AND &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.ItemsLocationAttributes
	|		WHEN DocumentTable.AdjustmentOfShipmentWithoutTransferOfOwnership
	|		THEN InventoryKinds.AnalysisOfAccountingForProductsWithoutAssignment
	|		ELSE UNDEFINED
	|	END												AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN &AdjustmentOfShipmentWithoutTransferOfOwnership 
	|		THEN InventoryKinds.InventoryOwnerAttribute
	|		ELSE UNDEFINED
	|	END												AS CorInventoryOwnerAttribute,
	|	UNDEFINED										AS CorLot,
	|	UNDEFINED										AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners							AS AccountingDimensionByPartners,
	|	CASE WHEN DocumentTable.SaleByOrders THEN
	|		InventoryKinds.SalesOrder
	|	ELSE
	|		DocumentTable.DocumentBasis
	|	END												AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	InventoryKinds.Count 			AS Count,
	|	UNDEFINED					AS RowID,
	|
	// Other fields
	|	CASE
	|		WHEN &SalesViaCommissionAgent
	|		THEN DocumentTable.BusinessTransactionGrounds
	|		WHEN &AdjustmentOfShipmentWithoutTransferOfOwnership
	|		THEN VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|		ELSE VALUE(Enum.BusinessTransactions.SaleToCustomer) 
	|	END													AS BusinessOperation,
	|	InventoryKinds.RowID							AS FinRecordID,
	|	DocumentTable.BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableTypesOfInventoryWriteOff AS InventoryKinds
	|		ON TRUE
	|WHERE
	|	(NOT InventoryKinds.ToIncomeExpenses OR &SaleAdjustment2_5)
	|	AND InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
	#Region SaleOfGoodsAndServices_LastPeriodAdjustment_N6

	QueryText =
	"SELECT
	// Document description
	|	DocumentTable.Period 			AS Period,
	|	DocumentTable.Ref				AS Ref,
	|	CASE
	|		WHEN &AdjustmentOfPreviousPeriodYear
	|			THEN &AdjustmentPeriod_ 
	|		ELSE UNDEFINED
	|	END 								AS VariancePeriod,
	|	DocumentTable.DocumentBasis	AS DocumentSource,
	|	DocumentTable.ShipmentPeriod		AS SourceDocumentPeriod,
	|	UNDEFINED 						AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.ItemsLocationAttributes
	|		ELSE InventoryKinds.AnalysisOfAccountingForProductsWithoutAssignment
	|	END											AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute 							AS InventoryOwnerAttribute,
	|	InventoryKinds.VATActivityType					AS VATActivityType,
	|	InventoryKinds.VATActivityType					AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED									AS CorCompany,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.DimensionSalesOfGoodsAndServices
	|		ELSE InventoryKinds.UnassignedImplementationAnalytics
	|	END											AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN InventoryKinds.InventoryType IN (
	|			VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|			VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|		 AND InventoryKinds.CorInventoryOwnerAttribute <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|			THEN InventoryKinds.CorInventoryOwnerAttribute
	|		WHEN InventoryKinds.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|			THEN InventoryKinds.InventoryOwnerAttributeShipment
	|		ELSE InventoryKinds.InventoryOwnerAttribute
	|	END											AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	CASE WHEN DocumentTable.SaleByOrders THEN
	|		InventoryKinds.SalesOrder
	|	ELSE
	|		DocumentTable.DocumentBasis
	|	END											AS SalesOrder,
	|	InventoryKinds.VATActivityType					AS CorVATActivityTypes,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	InventoryKinds.Count				AS Count,
	|	UNDEFINED						AS RowID,
	|
	// Other fields
	|	CASE
	|		WHEN &SalesViaCommissionAgent AND &LastPeriodAdjustment
	|		THEN VALUE(Enum.BusinessTransactions.GoodsReturnViaCommissionAgentOfPreviousPeriods)
	|		WHEN NOT InventoryKinds.ToExpenseAs
	|		 AND InventoryKinds.InventoryType IN (
	|				VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			THEN VALUE(Enum.BusinessTransactions.ReportToMaterialProviderAdjustmentOfPastPeriod)
	|		WHEN &LastPeriodAdjustment
	|		THEN VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|		ELSE VALUE(Enum.BusinessTransactions.ReverseOfSaleReturnToAnotherWarehouse)
	|	END AS BusinessOperation,
	|	InventoryKinds.RowID AS FinRecordID,
	|	CASE
	|		WHEN &LastPeriodAdjustment
	|		THEN DocumentTable.BusinessTransactionSetting
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSaleReturnToAnotherWarehouse)
	|	END AS BusinessTransactionSetting,
	|	CASE
	|		WHEN &LastPeriodAdjustment
	|		THEN VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
	|		ELSE VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouse)
	|	END AS EntryType
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableTypesOfInventoryRegistration AS InventoryKinds
	|		ON TRUE
	|WHERE
	|	(NOT InventoryKinds.ToIncomeExpenses OR &SaleAdjustment2_5)
	|	AND (&LastPeriodAdjustment
	//Conditions of return to another storage location (BT cancellation of the return of another deposit), for this BT will use a Registered Record similar to the return in the previous period
	|		OR InventoryKinds.Warehouse <> InventoryKinds.OriginWarehouse)
	// When using the average sliding cost, the date of transfer of ownership should refer to the previous period.
	|	AND (&DateOfTransferOfTitleToGoods < BEGINOFPERIOD(DocumentTable.Period, MONTH)
	|		OR &DateOfTransferOfTitleToGoods = DATETIME(1,1,1)
	|		OR NOT &MovingAverage)
	|	AND InventoryKinds.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.Work_5),
	|		VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|		VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND (ISNULL(InventoryKinds.ItemsType, UNDEFINED) <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR NOT &ToReturnReusablePackage)
	|	AND NOT InventoryKinds.CostDefiningMethod IN (
	|		VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|		VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
	#Region SaleOfGoodsAndServices_ReversingEntry_CreditNotesOfCurPeriodHaveBeenAdjusted_N7
	// Sales analytics is used.

	QueryText =
	"SELECT
	// Document description
	|	DocumentTable.Period				AS Period,
	|	DocumentTable.Ref				AS Ref,
	|	CASE
	|		WHEN &AdjustmentOfPreviousPeriodYear
	|			THEN &AdjustmentPeriod_ 
	|		ELSE UNDEFINED
	|	END 								AS VariancePeriod,
	|	DocumentTable.DocumentBasis	AS DocumentSource,
	|	DocumentTable.ShipmentPeriod		AS SourceDocumentPeriod,
	|	UNDEFINED 						AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|	END											AS ItemsLocationAttributes,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef) THEN
	|			TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END											AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED									AS CorCompany,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.DimensionSalesOfGoodsAndServices
	|		ELSE TableTypesOfStocks_.UnassignedImplementationAnalytics
	|	END											AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType IN
	|			(VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			AND TableTypesOfStocks_.CorInventoryOwnerAttribute <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN TableTypesOfStocks_.CorInventoryOwnerAttribute
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END											AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	CASE WHEN DocumentTable.SaleByOrders THEN
	|		TableTypesOfStocks_.SalesOrder
	|	ELSE
	|		DocumentTable.DocumentBasis
	|	END											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity						AS SalesOpportunity,
	|	DocumentTable.Department				AS Department,
	|	DocumentTable.Manager					AS Manager,
	|	UNDEFINED 								AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	-TableTypesOfStocks_.Count 				AS Count,
	|	UNDEFINED								AS RowID,
	|
	// Other fields
	|	CASE
	|		WHEN NOT TableTypesOfStocks_.ToExpenseAs
	|			AND TableTypesOfStocks_.InventoryType IN (
	|				VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			AND TableTypesOfStocks_.CorInventoryOwnerAttribute <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN DocumentTable.BusinessOperation
	|		WHEN TableTypesOfStocks_.ToExpenseAs
	|			AND TableTypesOfStocks_.InventoryType IN (
	|				VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			AND TableTypesOfStocks_.CorInventoryOwnerAttribute <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses)
	|		ELSE VALUE(Enum.BusinessTransactions.ReverseOfSale)
	|	END									AS BusinessOperation,
	|	TableTypesOfStocks_.RowID	AS FinRecordID,
	|	CASE
	|		WHEN TableTypesOfStocks_.ToExpenseAs
	|			AND TableTypesOfStocks_.InventoryType IN (
	|				VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses)
	|		ELSE DocumentTable.BusinessTransactionSetting
	|	END									AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableTypesOfInventoryRegistration AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	(NOT TableTypesOfStocks_.ToIncomeExpenses OR &SaleAdjustment2_5)
	|	AND (&CurPeriodAdjustment
	// When using the average sliding cost, the date of transfer of ownership determines the adjustment of the current period.
	|		OR &DateOfTransferOfTitleToGoods >= BEGINOFPERIOD(DocumentTable.Period, MONTH)
	|		AND &MovingAverage)
	//Conditions for no return to another warehouse (BT cancellation of a refund to another warehouse). For this BT, a Registered Record will be used that is similar to the return in the previous period
	|	AND TableTypesOfStocks_.Warehouse = TableTypesOfStocks_.OriginWarehouse
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.Work_5),
	|		VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|		VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND (ISNULL(TableTypesOfStocks_.ItemsType, UNDEFINED) <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR NOT &ToReturnReusablePackage)
	|	AND NOT TableTypesOfStocks_.CostDefiningMethod IN (
	|		VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|		VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
	#Region ExternalReceipt_ItemWorkCommissionItem_AdjustingImplementationBeforeEnteringBalances_N8
	// The credit note for a decrease in the quantity in the cost of goods is reflected as the Receipt of a new batch.
	// The cost of the returned goods is determined by the "Cost determination method" field. 
		
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Period	AS Period,
	|	DocumentTable.Ref	AS Ref,
	|	UNDEFINED			AS VariancePeriod,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED			AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.ItemsLocationAttributes
	|		ELSE InventoryKinds.AnalysisOfAccountingForProductsWithoutAssignment
	|	END												AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute								AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	InventoryKinds.VATActivityType						AS VATActivityType,
	|	InventoryKinds.VATActivityType						AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	InventoryKinds.LotVendorAttributes					AS LotVendorAttributes,
	|	InventoryKinds.LotVendorAttributes					AS LotVendorAttributesCorr,
	|	&Partner											AS Vendor,
	|	&Counterparty											AS Counterparty,
	|	InventoryKinds.VATRate								AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	&Manager						AS Manager,
	|
	// Quantitative and summary indicators
	|	InventoryKinds.Count			AS Count,
	|	UNDEFINED					AS RowID,
	|	CASE
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN InventoryKinds.Cost_
	|		ELSE InventoryKinds.AmountIncludingVATMan
	|	END											AS Cost,
	|	CASE
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN InventoryKinds.CostExcludingVAT_
	|	ELSE InventoryKinds.AmountExcludingVATMan 
	|	END											AS CostExcludingVAT,
	|	CASE
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN InventoryKinds.CostLocal
	|		WHEN InventoryKinds.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|			THEN InventoryKinds.AmountIncludingVATCompl
	|		ELSE InventoryKinds.AmountExcludingVATCompl
	|	END											AS LocalCost,
	|	CASE
	|		WHEN InventoryKinds.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN 0
	|		ELSE InventoryKinds.VATLocal
	|	END AS VATLocal,
	|	CASE
	|		WHEN NOT &CompanyManagementAccounting THEN 0
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN InventoryKinds.CostExcludingVAT_
	|		WHEN InventoryKinds.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|			THEN InventoryKinds.AmountIncludingVATMan
	|		ELSE InventoryKinds.AmountExcludingVATMan
	|	END											AS CostMan,
	|	CASE
	|		WHEN &CompanyManagementAccounting AND NOT InventoryKinds.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN InventoryKinds.VATManag
	|		ELSE 0
	|	END											AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	CASE
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN InventoryKinds.CDCost
	|		ELSE 0
	|	END											AS PermanentDifference,
	|	CASE
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN InventoryKinds.TDCost
	|		ELSE 0
	|	END											AS CostTD,
	|	0 												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.AdjustBeforeEnteringBalance)			AS BusinessOperation,
	// The fields of the Record ID and the setting of the business operation must be filled
	// in the same way in the cost of goods and in revenue and cost of sales. The function of the text query is a table with a handle and the value of sales().
	|	InventoryKinds.RowID														AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AdjustBeforeEnteringBalance)	AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableTypesOfInventoryRegistration AS InventoryKinds
	|		ON TRUE
	|WHERE
	|	(NOT InventoryKinds.ToIncomeExpenses OR &SaleAdjustment2_5)
	|	AND InventoryKinds.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.Work_5),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND InventoryKinds.CostDefiningMethod IN (
	|		VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|		VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion
	
	#Region DisposalAtFixedCost_Tara_ReversingEntry_N9
	// Return of multi-turn containers. Transfer of the current period
	
	QueryText =
	"SELECT
	// Document description
	|	DocumentTable.Period				AS Period,
	|	DocumentTable.Ref 			AS Ref,
	|	DocumentTable.DocumentBasis	AS DocumentSource,
	|	UNDEFINED						AS SourceDocumentPeriod,
	|	UNDEFINED						AS VariancePeriod,
	|	UNDEFINED 						AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization					AS Organization,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.ItemsLocationAttributes
	|		ELSE InventoryKinds.AnalysisOfAccountingForProductsWithoutAssignment
	|	END											AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
	|	InventoryKinds.VATActivityType					AS VATActivityType,
	|	InventoryKinds.VATActivityType					AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.DimensionSalesOfGoodsAndServices
	|		ELSE InventoryKinds.UnassignedImplementationAnalytics
	|	END											AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN InventoryKinds.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN InventoryKinds.InventoryOwnerAttributeShipment
	|		ELSE InventoryKinds.InventoryOwnerAttribute
	|	END											AS CorInventoryOwnerAttribute,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.DifferencesInCostOfReturnAndActualCostOfGoods) AS ExpenseItemAssets,
	|	DocumentTable.Partner 						AS AssetExpenseAnalytics,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.DifferencesInCostOfReturnAndActualCostOfGoods) AS IncomeItem,
	|	DocumentTable.Partner						AS DimensionOfRevenue,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	-InventoryKinds.Count				AS Count,
	|	-InventoryKinds.AmountIncludingVATMan			AS Cost,
	|	-InventoryKinds.AmountExcludingVATMan			AS CostExcludingVAT,
	|	-InventoryKinds.AmountExcludingVATCompl		AS LocalCost,
	|	-CASE
	|		WHEN NOT &CompanyManagementAccounting THEN 0
	|		ELSE InventoryKinds.AmountExcludingVATMan
	|	END								AS CostMan,
	|	0 									AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.TransferredPackageReverseTransaction)			AS BusinessOperation,
	|	InventoryKinds.RowID												AS FinRecordID,
	|	UNDEFINED																AS RowID,
	|	VALUE(Catalog.BusinessTransactionsSettings.TransferredPackageReverseTransaction)	AS BusinessTransactionSetting,
	|	VALUE(Enum.LotRecordTypes.ReversingEntry) AS EntryType
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableTypesOfInventoryRegistration AS InventoryKinds
	|		ON TRUE
	|WHERE
	|	(NOT InventoryKinds.ToIncomeExpenses OR &SaleAdjustment2_5)
	|	AND &CurPeriodAdjustment
	//Conditions for no return to another warehouse (BT of a non-returned return card to another warehouse). For this BT, a Registered Record will be used that is similar to the return in the previous period
	|	AND InventoryKinds.Warehouse = InventoryKinds.OriginWarehouse
	|	AND InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|	AND InventoryKinds.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND &ToReturnReusablePackage
	|	AND NOT InventoryKinds.CostDefiningMethod IN (
	|		VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|		VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.DisposalAtFixedCost,
		QueryText);
		
	#EndRegion
	
	#Region DisposalAtFixedCost_Packaging_TransferOfPreviousPeriod_N10
	// Return of multi-turn containers. Transfer of the previous period
	
	QueryText =
	"SELECT
	// Document description
	|	DocumentTable.Period				AS Period,
	|	DocumentTable.Ref				AS Ref,
	|	UNDEFINED						AS VariancePeriod,
	|	DocumentTable.DocumentBasis	AS DocumentSource,
	|	UNDEFINED						AS SourceDocumentPeriod,
	|	UNDEFINED 						AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.ItemsLocationAttributes
	|		ELSE InventoryKinds.AnalysisOfAccountingForProductsWithoutAssignment
	|	END											AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute 							AS InventoryOwnerAttribute,
	|	InventoryKinds.VATActivityType					AS VATActivityType,
	|	InventoryKinds.VATActivityType					AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.DimensionSalesOfGoodsAndServices
	|		ELSE InventoryKinds.UnassignedImplementationAnalytics
	|	END											AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN InventoryKinds.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN InventoryKinds.InventoryOwnerAttributeShipment
	|		ELSE InventoryKinds.InventoryOwnerAttribute
	|	END											AS CorInventoryOwnerAttribute,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.DifferencesInCostOfReturnAndActualCostOfGoods) AS ExpenseItemAssets,
	|	DocumentTable.Partner						AS AssetExpenseAnalytics,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.DifferencesInCostOfReturnAndActualCostOfGoods) AS IncomeItem,
	|	DocumentTable.Partner 						AS DimensionOfRevenue,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	InventoryKinds.Count			AS Count,
	|	InventoryKinds.AmountIncludingVATMan		AS Cost,
	|	InventoryKinds.AmountExcludingVATMan		AS CostExcludingVAT,
	|	InventoryKinds.AmountExcludingVATCompl		AS LocalCost,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|		THEN InventoryKinds.AmountExcludingVATMan
	|		ELSE 0
	|	END							AS CostMan,
	|	0								AS CorGrossInitialCostENT,
	|
	// Other fields
	|	CASE
	|		WHEN NOT &CurPeriodAdjustment
	|		THEN VALUE(Enum.BusinessTransactions.ReturnPackageFromCustomerOfPreviousPeriods)
	|		ELSE VALUE(Enum.BusinessTransactions.TransferredPackageReverseTransactionReturnToAnotherWarehouse)
	|	END AS BusinessOperation,
	|	InventoryKinds.RowID														AS FinRecordID,
	|	UNDEFINED																		AS RowID,
	|	CASE
	|		WHEN NOT &CurPeriodAdjustment
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnPackageFromCustomerOfPreviousPeriods)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.TransferredPackageReverseTransactionReturnToAnotherWarehouse)
	|	END AS BusinessTransactionSetting,
	|	CASE
	|		WHEN NOT &CurPeriodAdjustment
	|		THEN VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
	|		ELSE VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouse)
	|	END AS EntryType
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableTypesOfInventoryRegistration AS InventoryKinds
	|		ON TRUE
	|WHERE
	|	(NOT InventoryKinds.ToIncomeExpenses OR &SaleAdjustment2_5)
	|	AND (NOT &CurPeriodAdjustment
	//Conditions of return to another storage location (BT cancellation of the return of another deposit), for this BT will use a Registered Record similar to the return in the previous period
	|		OR InventoryKinds.Warehouse <> InventoryKinds.OriginWarehouse)
	|	AND InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|	AND InventoryKinds.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND &ToReturnReusablePackage
	|	AND NOT InventoryKinds.CostDefiningMethod IN (
	|		VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|		VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.DisposalAtFixedCost,
		QueryText);
	
	#EndRegion
	
	#Region SaleOfGoodsAndServices_Work_5_AdjustmentToMinusOfPreviousPeriod_N11
	// Works. Correction in the negative of the previous period.
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Period				AS Period,
	|	DocumentTable.Ref				AS Ref,
	|	CASE
	|		WHEN &AdjustmentOfPreviousPeriodYear
	|			THEN &AdjustmentPeriod_ 
	|		ELSE UNDEFINED
	|	END 								AS VariancePeriod,
	|	DocumentTable.DocumentBasis	AS DocumentSource,
	|	DocumentTable.ShipmentPeriod		AS SourceDocumentPeriod,
	|	UNDEFINED 						AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN DivergenceTable.ItemsLocationAttributes
	|		ELSE DivergenceTable.AnalysisOfAccountingForProductsWithoutAssignment
	|	END											AS ItemsLocationAttributes,
	|	DivergenceTable.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	DivergenceTable.VATActivityType 			AS VATActivityType,
	|	DivergenceTable.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED									AS CorCompany,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN DivergenceTable.ItemsLocationAttributes
	|		ELSE DivergenceTable.AnalysisOfAccountingForProductsWithoutAssignment
	|	END											AS CorItemsLocationAttributes,
	|	DivergenceTable.InventoryOwnerAttribute					AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	CASE WHEN DocumentTable.SaleByOrders THEN
	|		DivergenceTable.SalesOrder
	|	ELSE
	|		DocumentTable.DocumentBasis
	|	END											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	-DivergenceTable.Count		AS Count,
	|
	// Other fields
	|	CASE WHEN &SalesViaCommissionAgent
	|			THEN VALUE(Enum.BusinessTransactions.GoodsReturnViaCommissionAgentOfPreviousPeriods)
	|		WHEN &BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			THEN VALUE(Enum.BusinessTransactions.ReportToMaterialProviderAdjustmentOfPastPeriod)
	|		ELSE
	|			VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|	END 											AS BusinessOperation,
	|	DivergenceTable.RowID			AS FinRecordID,
	|	UNDEFINED									AS RowID,
	|	DocumentTable.BusinessTransactionSetting	AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTDivergenceOfServiceOperation AS DivergenceTable
	|		ON TRUE
	|WHERE
	|	(NOT DivergenceTable.ToIncomeExpenses OR &SaleAdjustment2_5)
	|	AND (DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		OR &BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|	)
	|	AND DivergenceTable.Count < 0
	|	AND &LastPeriodAdjustment
	|	AND NOT DivergenceTable.CostDefiningMethod IN (
	|		VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|		VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|	AND NOT DivergenceTable.TracedGoods
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
		
	#EndRegion
	
	#Region ExternalReceipt_Work_5_BeforeEnteringBalance_N12
	// Jobs. Credit note adjustment before Balances are entered.
	// The credit note for a decrease in the quantity in the cost of goods is reflected as the Receipt of a new batch.
	// The cost of the returned goods is determined by the "Cost determination method" field. 
	// operation - external receipt, for work
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Period		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS VariancePeriod,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN DivergenceTable.ItemsLocationAttributes
	|		ELSE DivergenceTable.AnalysisOfAccountingForProductsWithoutAssignment
	|	END												AS ItemsLocationAttributes,
	|	DivergenceTable.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	DivergenceTable.VATActivityType				AS VATActivityType,
	|	DivergenceTable.VATActivityType					AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	DivergenceTable.LotVendorAttributes			AS LotVendorAttributes,
	|	DivergenceTable.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty		AS Counterparty,
	|	UNDEFINED					AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	&Manager	 					AS Manager,
	|
	// Quantitative and summary indicators
	|	-DivergenceTable.Count					AS Count,
	|	CASE
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN DivergenceTable.Cost_
	|		ELSE -DivergenceTable.AmountIncludingVATMan
	|	END											AS Cost,
	|	CASE
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN DivergenceTable.CostExcludingVAT_
	|		ELSE -DivergenceTable.AmountExcludingVATMan
	|	END											AS CostExcludingVAT,
	|	CASE
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN DivergenceTable.CostLocal
	|		WHEN DivergenceTable.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|			THEN -DivergenceTable.AmountIncludingVATCompl
	|		ELSE -DivergenceTable.AmountExcludingVATCompl
	|	END											AS LocalCost,
	|	CASE
	|		WHEN DivergenceTable.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN 0
	|		ELSE -DivergenceTable.VATLocal
	|	END AS VATLocal,
	|	CASE
	|		WHEN NOT &CompanyManagementAccounting THEN 0
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN DivergenceTable.CostExcludingVAT_
	|		WHEN DivergenceTable.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|			THEN -DivergenceTable.AmountIncludingVATMan
	|		ELSE -DivergenceTable.AmountExcludingVATMan
	|	END 											AS CostMan,
	|	-CASE
	|		WHEN &CompanyManagementAccounting AND NOT DivergenceTable.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		THEN DivergenceTable.VATManag
	|		ELSE 0
	|	END											AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	CASE
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN DivergenceTable.CDCost
	|		ELSE 0
	|	END											AS PermanentDifference,
	|	CASE
	|		WHEN DivergenceTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN DivergenceTable.TDCost
	|		ELSE 0
	|	END 											AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.AdjustBeforeEnteringBalance)	AS BusinessOperation,
	|	DivergenceTable.RowID										AS FinRecordID,
	|	UNDEFINED																AS RowID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AdjustBeforeEnteringBalance) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTDivergenceOfServiceOperation AS DivergenceTable
	|		ON TRUE
	|WHERE
	|	(NOT DivergenceTable.ToIncomeExpenses OR &SaleAdjustment2_5)
	|	AND DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND DivergenceTable.Count < 0
	|	AND DivergenceTable.CostDefiningMethod IN (
	|		VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|		VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|	AND NOT DivergenceTable.TracedGoods
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion
	
	#Region SaleOfGoodsAndServices_Work_5_AdjustmentToMinus_N13
	// Works. Adjustment to minus
	
	QueryText =
	"SELECT
	// Document description
	|	DocumentTable.Period	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	CASE
	|		WHEN &AdjustmentOfPreviousPeriodYear
	|			THEN &AdjustmentPeriod_ 
	|		ELSE UNDEFINED
	|	END 								AS VariancePeriod,
	|	DocumentTable.DocumentBasis	AS DocumentSource,
	|	DocumentTable.ShipmentPeriod		AS SourceDocumentPeriod,
	|	UNDEFINED 						AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN DivergenceTable.ItemsLocationAttributes
	|		ELSE DivergenceTable.AnalysisOfAccountingForProductsWithoutAssignment
	|	END											AS ItemsLocationAttributes,
	|	DivergenceTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	DivergenceTable.VATActivityType			AS VATActivityType,
	|	DivergenceTable.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED									AS CorCompany,
	|	DivergenceTable.ItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	DivergenceTable.InventoryOwnerAttribute					AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners 						AS AccountingDimensionByPartners,
	|	CASE WHEN DocumentTable.SaleByOrders THEN
	|		DivergenceTable.SalesOrder
	|	ELSE
	|		DocumentTable.DocumentBasis
	|	END											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	DivergenceTable.Count	AS Count,
	|
	// Other fields
	|	CASE
	|		WHEN &BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			THEN &BusinessOperation
	|		ELSE
	|	VALUE(Enum.BusinessTransactions.ReverseOfSale)
	|	END
	|		AS BusinessOperation,
	|	UNDEFINED											AS RowID,
	|	DivergenceTable.RowID					AS FinRecordID,
	|	DocumentTable.BusinessTransactionSetting			AS BusinessTransactionSetting 
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTDivergenceOfServiceOperation AS DivergenceTable
	|		ON TRUE
	|WHERE
	|	NOT DivergenceTable.ToExpenseAs
	|	AND (NOT DivergenceTable.ToIncomeExpenses OR &SaleAdjustment2_5)
	|	AND (DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		OR &BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|		)
	|	AND &CurPeriodAdjustment
	|	AND DivergenceTable.Count < 0
	|	AND NOT DivergenceTable.CostDefiningMethod IN (
	|		VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|		VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|	AND NOT DivergenceTable.TracedGoods
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
	#Region RecogniseAsExpensesAssets_Work_5_AdjustmentToMinus_N14
	// Jobs. Adjustment to minus, write-off for expenses
	
	QueryText =
	"SELECT
	// Document description
	|	DocumentTable.Period AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED	AS VariancePeriod,
	|	UNDEFINED AS DocumentRegisterRecords,
	|	DocumentTable.DocumentBasis	AS DocumentSource,
	|	UNDEFINED						AS SourceDocumentPeriod,
	|	UNDEFINED						AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization					AS Organization,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN DivergenceTable.ItemsLocationAttributes
	|		ELSE DivergenceTable.AnalysisOfAccountingForProductsWithoutAssignment
	|	END											AS ItemsLocationAttributes,
	|	DivergenceTable.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	DivergenceTable.VATActivityType			AS VATActivityType,
	|	DivergenceTable.VATActivityType			AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	UNDEFINED AS Lot,
	|	UNDEFINED AS LotVendorAttributes,
	|
	// Corresponding fields
	|	UNDEFINED									AS CorCompany,
	|	DivergenceTable.ItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	DivergenceTable.InventoryOwnerAttribute					AS CorInventoryOwnerAttribute,
	|	UNDEFINED									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners 						AS AccountingDimensionByPartners,
	|	CASE WHEN DocumentTable.SaleByOrders THEN
	|		DivergenceTable.SalesOrder
	|	ELSE
	|		DocumentTable.DocumentBasis
	|	END											AS SalesOrder,
	|	DivergenceTable.DimensionOfExpenses			AS AssetExpenseAnalytics,
	|	CASE
	|		WHEN VALUETYPE(DivergenceTable.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	// At the moment, the document does not support the reflection of assets and liabilities on the article, it is not possible to specify accounting accounts.
	|			THEN UNDEFINED
	|		ELSE DivergenceTable.ExpenseItem
	|	END											AS ExpenseItemAssets,
	|	DivergenceTable.LineOfBusiness		AS CorLineOfBusiness,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department	AS Department,
	|	DocumentTable.Manager		AS Manager,
	|	UNDEFINED					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	DivergenceTable.Count	AS Count,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|	0 AS CostMan,
	|
	// Other fields

	|	UNDEFINED									AS RowID,
	|	DivergenceTable.RowID			AS FinRecordID,
	|	VALUE(Enum.LotRecordTypes.ReversingEntry)	AS EntryType,
	|	CASE
	|		WHEN &BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			THEN VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses)
	|		ELSE
	|			VALUE(Enum.BusinessTransactions.ReverseOfSale)
	|	END
	|														AS BusinessOperation,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses)
	|		ELSE DocumentTable.BusinessTransactionSetting
	|	END												AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTDivergenceOfServiceOperation AS DivergenceTable
	|		ON TRUE
	|WHERE
	|	DivergenceTable.ToExpenseAs
	|	AND (NOT DivergenceTable.ToIncomeExpenses OR &SaleAdjustment2_5)
	|	AND (DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		OR &BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|		)
	|	AND &CurPeriodAdjustment
	|	AND DivergenceTable.Count < 0
	|	AND NOT DivergenceTable.CostDefiningMethod IN (
	|		VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|		VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|	AND NOT DivergenceTable.TracedGoods
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.RecogniseAsExpensesAssets,
		QueryText);
	
	#EndRegion

	#Region RecogniseAsExpensesAssets_Work_5_AdjustmentToPlus_N15
	// Works. Sale.
	
	QueryText =
	"SELECT
	// Document description
	|	DocumentTable.Period AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS VariancePeriod,
	|	UNDEFINED			AS DocumentRegisterRecords,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED			AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization					AS Organization,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN DivergenceTable.ItemsLocationAttributes
	|		ELSE DivergenceTable.AnalysisOfAccountingForProductsWithoutAssignment
	|	END											AS ItemsLocationAttributes,
	|	DivergenceTable.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	DivergenceTable.VATActivityType			AS VATActivityType,
	|	DivergenceTable.VATActivityType			AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	UNDEFINED AS Lot,
	|	UNDEFINED AS LotVendorAttributes,
	|
	// Corresponding fields
	|	UNDEFINED									AS CorCompany,
	|	UNDEFINED									AS CorItemsLocationAttributes,
	|	DivergenceTable.InventoryOwnerAttribute					AS CorInventoryOwnerAttribute,
	|	UNDEFINED									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners 						AS AccountingDimensionByPartners,
	|	CASE WHEN DocumentTable.SaleByOrders THEN
	|		DivergenceTable.SalesOrder
	|	ELSE
	|		DocumentTable.DocumentBasis
	|	END											AS SalesOrder,
	|	DivergenceTable.DimensionOfExpenses			AS AssetExpenseAnalytics,
	|	CASE
	|		WHEN VALUETYPE(DivergenceTable.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	// At the moment, the document does not support the reflection of assets and liabilities on the article, it is not possible to specify accounting accounts.
	|			THEN UNDEFINED
	|		ELSE DivergenceTable.ExpenseItem
	|	END											AS ExpenseItemAssets,
	|	DivergenceTable.LineOfBusiness		AS CorLineOfBusiness,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department	AS Department,
	|	DocumentTable.Manager		AS Manager,
	|	UNDEFINED					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	DivergenceTable.Count	AS Count,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|	0 AS CostMan,
	|
	// Other fields
	|	UNDEFINED							AS RowID,
	|	DivergenceTable.RowID	AS FinRecordID,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			THEN VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses)
	|		ELSE DocumentTable.BusinessOperation
	|	END									AS BusinessOperation,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses)
	|		ELSE DocumentTable.BusinessTransactionSetting
	|	END									AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTDivergenceOfServiceOperation AS DivergenceTable
	|		ON TRUE
	|WHERE
	|	DivergenceTable.ToExpenseAs
	|	AND (NOT DivergenceTable.ToIncomeExpenses OR &SaleAdjustment2_5)
	|	AND (DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		OR &BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|	)
	|	AND DivergenceTable.Count > 0
	|	AND NOT DivergenceTable.TracedGoods
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.RecogniseAsExpensesAssets,
		QueryText);
	
	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

Function DescriptionOfRevenueAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region SaleOfGoodsAndServices
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	UNDEFINED 									AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation 			AS VATActivityType,
	|	TableTypesOfStocks_.VATTaxation			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	UNDEFINED   									AS CorItemsLocationAttributes,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	CASE WHEN &InvoiceByOrders THEN
	|		TableTypesOfStocks_.SalesOrder
	|	ELSE
	|		DocumentTable.Ref
	|	END 											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 									AS Count,
	|	TableTypesOfStocks_.RowID							AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer)	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 							AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.SaleAdjustment AS DocumentTable
	|	INNER JOIN TTOperationServices AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
EndFunction

#EndRegion

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	ConditionForVisibilityOfPrintedFormsByProduct = New Structure;
	ConditionForVisibilityOfPrintedFormsByProduct.Insert("Attribute", Metadata.Documents.SaleAdjustment.Attributes.AdjustmentKind.Name);
	ConditionForVisibilityOfPrintedFormsByProduct.Insert("ComparisonType", ComparisonType.InList);
	OperationArray = New ValueList();
	OperationArray.Add(Enums.BusinessTransactions.ErrorCorrection);
	OperationArray.Add(Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties);
	OperationArray.Add(Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods);
	OperationArray.Add(Enums.BusinessTransactions.SaleOfOverdeliveredGoods);
	ConditionForVisibilityOfPrintedFormsByProduct.Insert("Value", OperationArray);
	
	ConditionOfVisibilityOfPrintedFormsTransferOfOwnership = New Structure;
	ConditionOfVisibilityOfPrintedFormsTransferOfOwnership.Insert("Attribute",
		Metadata.Documents.SaleAdjustment.Attributes.BusinessOperation.Name);
	ConditionOfVisibilityOfPrintedFormsTransferOfOwnership.Insert("ComparisonType", ComparisonType.NotEqual);
	ConditionOfVisibilityOfPrintedFormsTransferOfOwnership.Insert("Value",
		Enums.BusinessTransactions.TransferOfTitleToGoods);
	ListOfOperationsOfGiver = New ValueList;
	ListOfOperationsOfGiver.Add(Enums.BusinessTransactions.ReportToMaterialProvider2_5);
	ListOfOperationsOfGiver.Add(Enums.BusinessTransactions.Subcontracting2_5);
	ListOfOperationsOfGiver.Add(Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5);
	ListOfOperationsOfGiver.Add(Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5);
	ListOfOperationsOfGiver.Add(Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5);
	// Sale of goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "Invoice";
	PrintCommand.Presentation = NStr("vi = 'Giao hàng';
									|ru = 'Реализация товаров';
									|en = 'Goods sales'; fa = 'فروش کالا';
									|it = 'Vendita delle merci';
									|pl = 'Sprzedaż towarów';
									|tr = 'Malların satışı'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.VisibilityConditions.Add(ConditionForVisibilityOfPrintedFormsByProduct);
	AttachableCommands.AddCommandVisibilityCondition(
		PrintCommand,
		"BusinessOperation",
		ListOfOperationsOfGiver,
		DataCompositionComparisonType.NotInList);
	// Register of GTD numbers
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "CCDNumberRegistry";
	PrintCommand.Presentation = NStr("vi = 'Số đăng ký tờ khai hải quan';
									|ru = 'Реестр номеров ГТД';
									|en = 'CCD number registry'; fa = 'دفتر ثبت شماره‌های CCD';
									|it = 'Registro numeri delle dichiarazioni doganali di carico';
									|pl = 'Wykaz numerów towarowej deklaracji celnej';
									|tr = 'GB numaraları kaydı'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.FunctionalOptions = "UseImportedGoods";
	PrintCommand.VisibilityConditions.Add(ConditionForVisibilityOfPrintedFormsByProduct);
	PrintCommand.VisibilityConditions.Add(ConditionOfVisibilityOfPrintedFormsTransferOfOwnership);
	AttachableCommands.AddCommandVisibilityCondition(
		PrintCommand,
		"BusinessOperation",
		ListOfOperationsOfGiver,
		DataCompositionComparisonType.NotInList);
	If Not UserRightsCached.ThisIsPartner() Then
		
		// The act on the provision of services
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCertificateOfRenderedServices";
		PrintCommand.Id = "Act";
		PrintCommand.Presentation = NStr("vi = 'Biên bản cung cấp dịch vụ';
										|ru = 'Акт об оказании услуг';
										|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
										|it = 'Atto di prestazione dei servizi';
										|pl = 'Protokół świadczenia usług';
										|tr = 'Hizmet tutanağı'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 1;
		PrintCommand.VisibilityConditions.Add(ConditionForVisibilityOfPrintedFormsByProduct);
		PrintCommand.DefaultPrintForm = True;
		PrintCommand.PrintFormDescription = NStr("vi = 'Biên bản cung cấp dịch vụ';
												|ru = 'Акт об оказании услуг';
												|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
												|it = 'Atto di prestazione dei servizi';
												|pl = 'Protokół świadczenia usług';
												|tr = 'Hizmet tutanağı'");
		AttachableCommands.AddCommandVisibilityCondition(
			PrintCommand,
			"BusinessOperation",
			ListOfOperationsOfGiver,
			DataCompositionComparisonType.NotInList);
	EndIf;

	If AccessRight("Read", Metadata.Catalogs.QualityCertificates)
		And GetFunctionalOption("UseQualityCertificates") Then
		
		// Register of Nomenclature certificates
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificatesOfProductsRegister";
		PrintCommand.Presentation = NStr("vi = 'Giấy chứng nhận (đăng ký)';
										|ru = 'Сертификаты (реестр)';
										|en = 'Certificates (registry)'; fa = 'Certificates (registry)';
										|it = 'Certificati (registro)';
										|pl = 'Certyfikaty (rejestr)';
										|tr = 'Sertifikalar (kayıt)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 8;
		PrintCommand.VisibilityConditions.Add(ConditionForVisibilityOfPrintedFormsByProduct);
		PrintCommand.VisibilityConditions.Add(ConditionOfVisibilityOfPrintedFormsTransferOfOwnership);
		
		// Images of Nomenclature certificates
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificatesProductImagesFromDocuments";
		PrintCommand.Presentation = NStr("vi = 'Giấy chứng nhận (cho mỗi mục trong chứng từ)';
										|ru = 'Сертификаты (по каждой позиции документа)';
										|en = 'Certificates (by each document item)'; fa = 'Certificates (by each document item)';
										|it = 'Certificati (per ogni voce del documento)';
										|pl = 'Certyfikaty (dla każdej pozycji dokumentu)';
										|tr = 'Sertifikalar (belgedeki her kalem için)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 9;
		PrintCommand.VisibilityConditions.Add(ConditionForVisibilityOfPrintedFormsByProduct);
		PrintCommand.VisibilityConditions.Add(ConditionOfVisibilityOfPrintedFormsTransferOfOwnership);
		
		// Images of Nomenclature certificates
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificatesProductImagesFromDocumentsWithoutDuplicates";
		PrintCommand.Presentation = NStr("vi = 'Chứng chỉ (một cho mỗi chứng chỉ)';
										|ru = 'Сертификаты (по одному на сертификат)';
										|en = 'Certificates (one per certificate)'; fa = 'Certificates (one per certificate)';
										|it = 'Certificati (uno per certificato)';
										|pl = 'Certyfikaty (po jednym na certyfikat)';
										|tr = 'Sertifikalar (sertifika başına bir tane)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 10;
		PrintCommand.VisibilityConditions.Add(ConditionForVisibilityOfPrintedFormsByProduct);
		PrintCommand.VisibilityConditions.Add(ConditionOfVisibilityOfPrintedFormsTransferOfOwnership);
		
	EndIf;
	
	If Not UserRightsCached.ThisIsPartner() Then
		
		// Task for the selection of goods
		PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(
			PrintCommands, "SelectionTask", 11, ConditionForVisibilityOfPrintedFormsByProduct);
		PrintCommand.VisibilityConditions.Add(ConditionOfVisibilityOfPrintedFormsTransferOfOwnership);
		AttachableCommands.AddCommandVisibilityCondition(
			PrintCommand,
			"BusinessOperation",
			ListOfOperationsOfGiver,
			DataCompositionComparisonType.NotInList);
	EndIf;
	
	If Not UserRightsCached.ThisIsPartner() And Constants.UseInternationalPrintingForms.Get() Then
		// Invoice
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "InvoiceInt";
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Presentation = NStr("vi = 'Commercial invoice';
										|ru = 'Commercial invoice';
										|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
										|it = 'Commercial invoice';
										|pl = 'Commercial invoice';
										|tr = 'Commercial invoice'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 2;
		PrintCommand.VisibilityConditions.Add(ConditionForVisibilityOfPrintedFormsByProduct);
		
		// DebitNote
		VisibilityCondition = New Structure;
		VisibilityCondition.Insert("Attribute", Metadata.Documents.SaleAdjustment.Attributes.AdjustmentKind.Name);
		VisibilityCondition.Insert("ComparisonType", ComparisonType.InList);
		OperationArray = New ValueList();
		OperationArray.Add(Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated);
		OperationArray.Add(Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties);
		VisibilityCondition.Insert("Value", OperationArray);
		
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "DebitNote";
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Presentation = NStr("vi = 'Debit Note';
										|ru = 'Debit Note';
										|en = 'Debit Note'; fa = 'Debit Note';
										|it = 'Debit Note';
										|pl = 'Debit Note';
										|tr = 'Debit Note'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 3;
		PrintCommand.VisibilityConditions.Add(VisibilityCondition);
		
		// CreditNote
		VisibilityCondition = New Structure;
		VisibilityCondition.Insert("Attribute", Metadata.Documents.SaleAdjustment.Attributes.AdjustmentKind.Name);
		VisibilityCondition.Insert("ComparisonType", ComparisonType.InList);
		OperationArray = New ValueList();
		OperationArray.Add(Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated);
		OperationArray.Add(Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties);
		OperationArray.Add(Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods);
		VisibilityCondition.Insert("Value", OperationArray);
		
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CreditNote";
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Presentation = NStr("vi = 'Credit Note';
										|ru = 'Credit Note';
										|en = 'Credit Note'; fa = 'Credit Note';
										|it = 'Credit Note';
										|pl = 'Credit Note';
										|tr = 'Credit Note'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 3;
		PrintCommand.VisibilityConditions.Add(VisibilityCondition);
		
	EndIf;
	
	SaleAdjustmentLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "Invoice") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "Invoice", NStr("vi = 'Giao hàng';
																									|ru = 'Реализация товаров';
																									|en = 'Goods sales'; fa = 'فروش کالا';
																									|it = 'Vendita delle merci';
																									|pl = 'Sprzedaż towarów';
																									|tr = 'Malların satışı'"), FormPrintedFormInvoice(ObjectsArray, PrintObjects));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CCDNumberRegistry") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "CCDNumberRegistry", NStr("vi = 'Số đăng ký tờ khai hải quan';
																												|ru = 'Реестр номеров ГТД';
																												|en = 'CCD number registry'; fa = 'دفتر ثبت شماره‌های CCD';
																												|it = 'Registro numeri delle dichiarazioni doganali di carico';
																												|pl = 'Wykaz numerów towarowej deklaracji celnej';
																												|tr = 'GB numaraları kaydı'"), FormPrintedFormRegisterOfCCDNumbers(ObjectsArray, PrintObjects));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CertificatesOfProductsRegister") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CertificatesOfProductsRegister",
			NStr("vi = 'Giấy chứng nhận (đăng ký)';
				|ru = 'Сертификаты (реестр)';
				|en = 'Certificates (registry)'; fa = 'Certificates (registry)';
				|it = 'Certificati (registro)';
				|pl = 'Certyfikaty (rejestr)';
				|tr = 'Sertifikalar (kayıt)'"),
			Catalogs.QualityCertificates.CreatePrintedFormRegisterOfProductCertificates(ObjectsArray, PrintObjects),
			,
			"Catalog.QualityCertificates.PF_MXL_CertificateRegistry");
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CertificatesProductImagesFromDocuments") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CertificatesProductImagesFromDocuments",
			NStr("vi = 'Giấy chứng nhận (cho mỗi mục trong chứng từ)';
				|ru = 'Сертификаты (по каждой позиции документа)';
				|en = 'Certificates (by each document item)'; fa = 'Certificates (by each document item)';
				|it = 'Certificati (per ogni voce del documento)';
				|pl = 'Certyfikaty (dla każdej pozycji dokumentu)';
				|tr = 'Sertifikalar (belgedeki her kalem için)'"),
			Catalogs.QualityCertificates.GeneratePrintedFormImagesOfCertificatesFromDocuments(ObjectsArray, PrintObjects),
			,
			"Catalog.QualityCertificates.PF_MXL_CertificateImages");
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CertificatesProductImagesFromDocumentsWithoutDuplicates") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CertificatesProductImagesFromDocumentsWithoutDuplicates",
			NStr("vi = 'Chứng chỉ (một cho mỗi chứng chỉ)';
				|ru = 'Сертификаты (по одному на сертификат)';
				|en = 'Certificates (one per certificate)'; fa = 'Certificates (one per certificate)';
				|it = 'Certificati (uno per certificato)';
				|pl = 'Certyfikaty (po jednym na certyfikat)';
				|tr = 'Sertifikalar (sertifika başına bir tane)'"),
			Catalogs.QualityCertificates.GeneratePrintedFormImagesOfCertificatesFromDocumentsWithoutDuplicates(ObjectsArray, PrintObjects),
			,
			"Catalog.QualityCertificates.PF_MXL_CertificateImages");
	EndIf;
	
	SaleAdjustmentLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function QueryTextForAdjustmentDataBeforeEnteringBalances()
	
	QueryText = "SELECT
	|	T.Ref AS Ref, 
	|	T.RowID AS RowID,
	|	T.Products AS Products,
	|	T.PartnerProducts AS PartnerProducts,
	|	T.Characteristic AS Characteristic,
	|	T.ProductsInSet AS ProductsInSet,
	|	T.ItemVariantOfSet AS ItemVariantOfSet,
	|	T.Content AS Content,
	|	T.Package AS Package,
	|	T.Series AS Series,
	|	T.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	T.Warehouse AS Warehouse,
	|	T.Department AS Department,
	|	T.IncomeItem AS IncomeItem,
	|	T.DimensionOfRevenue AS DimensionOfRevenue,
	|	T.CCDNumber AS CCDNumber,
	|	T.Price AS Price,
	|	T.VATRate AS VATRate,
	|	T.NumberOfPackages AS NumberOfPackages,
	|	T.Count AS Count,
	|	T.QuantityByGBRN AS QuantityByGBRN,
	|	T.Sum AS Sum,
	|	T.VATAmount AS VATAmount,
	|	T.AmountIncludingVAT AS AmountIncludingVAT,
	|	T.AmountARAP AS AmountARAP,
	|	T.LineNumber AS LineNumber,
	|	T.FEACNCode AS FEACNCode,
	|	T.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	T.AmountExcludingVATMan AS AmountExcludingVATMan
	|INTO TTProducts_1
	|FROM
	|	Document.SaleAdjustment.Goods AS T
	|	INNER JOIN DocumentDataTable_ AS DocumentsData
	|		ON T.Ref = DocumentsData.Ref
	|WHERE
	|	T.Ref.AdjustingEntryType IN (
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Ref AS Ref,
	|	T.Products AS Products,
	|	T.PartnerProducts AS PartnerProducts,
	|	T.Characteristic AS Characteristic,
	|	T.ProductsInSet AS ProductsInSet,
	|	T.ItemVariantOfSet AS ItemVariantOfSet,
	|	T.Content AS Content,
	|	T.Package AS Package,
	|	T.Series AS Series,
	|	T.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	T.Warehouse AS Warehouse,
	|	T.Department AS Department,
	|	T.IncomeItem AS IncomeItem,
	|	T.DimensionOfRevenue AS DimensionOfRevenue,
	|	T.CCDNumber AS CCDNumber,
	|	T.VATRate AS VATRate,
	|	T.NumberOfPackages AS NumberOfPackages,
	|	T.Count AS Count,
	|	T.QuantityByGBRN AS QuantityByGBRN,
	|	T.Sum AS Sum,
	|	T.VATAmount AS VATAmount,
	|	T.AmountIncludingVAT AS AmountIncludingVAT,
	|	T.AmountARAP AS AmountARAP,
	|	T.PostingOption AS PostingOption,
	|	T.CostDefiningMethod AS CostDefiningMethod,
	|	T.Cost_ AS Cost_,
	|	T.CostExcludingVAT_ AS CostExcludingVAT_,
	|	T.CostLocal AS CostLocal,
	|	T.CDCost AS CDCost,
	|	T.TDCost AS TDCost,
	|	T.CostPriceKind AS CostPriceKind,
	|	T.DateOfCostFillingByPriceType AS DateOfCostFillingByPriceType,
	|	T.FEACNCode AS FEACNCode,
	|	T.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	T.AmountExcludingVATMan AS AmountExcludingVATMan	
	|INTO TTDiscrepancies
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS T
	|	INNER JOIN DocumentDataTable_ AS DocumentsData
	|		ON T.Ref = DocumentsData.Ref
	|
	|WHERE
	|	T.Ref.AdjustingEntryType IN (
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.Content AS Content,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	Table.Package AS Package,
	|	Table.Series AS Series,
	|	Table.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Table.Warehouse AS Warehouse,
	|	Table.Department AS Department,
	|	Table.CCDNumber AS CCDNumber,
	|	Table.FEACNCode AS FEACNCode,
	|	Table.PartnerProducts AS PartnerProducts,
	|	Table.IncomeItem AS IncomeItem,
	|	Table.DimensionOfRevenue AS DimensionOfRevenue,
	|	MAX(Table.VATRate) AS VATRate,
	|	MAX(Table.Price) AS Price,
	|	SUM(Table.NumberOfPackages) AS NumberOfPackages,
	|	SUM(Table.Count) AS Count,
	|	SUM(Table.QuantityByGBRN) AS QuantityByGBRN,
	|	SUM(Table.Sum) AS Sum,
	|	SUM(Table.VATAmount) AS VATAmount,
	|	SUM(Table.AmountIncludingVAT) AS AmountIncludingVAT,
	|	SUM(Table.AmountARAP) AS AmountARAP,
	|	MAX(Table.VATRateAfter) AS VATRateAfter,
	|	MAX(Table.PriceAfter) AS PriceAfter,
	|	SUM(Table.NumberOfPackagesAfter) AS NumberOfPackagesAfter,
	|	SUM(Table.QuantityAfter) AS QuantityAfter,
	|	SUM(Table.QuantityAccordingToRNPTAfter) AS QuantityAccordingToRNPTAfter,
	|	SUM(Table.AmountAfter) AS AmountAfter,
	|	SUM(Table.VATAmountAfter) AS VATAmountAfter,
	|	SUM(Table.AmountWithVATAfter) AS AmountWithVATAfter,
	|	SUM(Table.AmountOfSettlementsAfter) AS AmountOfSettlementsAfter,
	|	ISNULL(MAX(Table.ReflectionOptionAfter),MAX(Table.ReflectionOptionUpTo)) AS PostingOption,
	|	MAX(Table.ReflectionOptionUpTo) AS OptionToReflectWriteOff,
	|	MAX(Table.CostDefiningMethod) AS CostDefiningMethod,
	|	MAX(Table.Cost_) AS Cost_,
	|	MAX(Table.CostExcludingVAT_) AS CostExcludingVAT_,
	|	MAX(Table.CostLocal) AS CostLocal,
	|	MAX(Table.CDCost) AS CDCost,
	|	MAX(Table.TDCost) AS TDCost,
	|	MAX(Table.CostPriceKind) AS CostPriceKind,
	|	MAX(Table.DateOfCostFillingByPriceType) AS DateOfCostFillingByPriceType,
	|	SUM(Table.Count - Table.QuantityAfter) < 0
	|		OR SUM(Table.NumberOfPackages - Table.NumberOfPackagesAfter) < 0 AS ThisIsWriteOffLine,
	|	MAX(Table.LineNumber) AS LineNumber,
	|	SUM(Table.AmountExcludingVATCompl) AS AmountExcludingVATCompl,
	|	SUM(Table.AmountExcludingVATMan) AS AmountExcludingVATMan,
	|	SUM(Table.VATExclusiveAmountLocalAfter) AS VATExclusiveAmountLocalAfter,
	|	SUM(Table.VATExclusiveAmountManAfter) AS VATExclusiveAmountManAfter,
	|	MAX(Table.RowID) AS RowID
	|INTO TTAdjustmentDataBeforeEnteringBalances
	|FROM
	|	(SELECT
	|		T.Ref AS Ref,
	|		T.Products AS Products,
	|		T.PartnerProducts AS PartnerProducts,
	|		T.FEACNCode AS FEACNCode,
	|		T.Characteristic AS Characteristic,
	|		T.ProductsInSet AS ProductsInSet,
	|		T.ItemVariantOfSet AS ItemVariantOfSet,
	|		T.Content AS Content,
	|		T.Package AS Package,
	|		T.Series AS Series,
	|		T.BatchesIndicationStatus AS BatchesIndicationStatus,
	|		T.Warehouse AS Warehouse,
	|		T.Department AS Department,
	|		T.CCDNumber AS CCDNumber,
	|		T.IncomeItem AS IncomeItem,
	|		T.DimensionOfRevenue AS DimensionOfRevenue,
	|		T.VATRate AS VATRate,
	|		SUM(T.Price) AS Price,
	|		SUM(T.NumberOfPackages) AS NumberOfPackages,
	|		SUM(T.Count) AS Count,
	|		SUM(T.QuantityByGBRN) AS QuantityByGBRN,
	|		SUM(T.Sum) AS Sum,
	|		SUM(T.VATAmount) AS VATAmount,
	|		SUM(T.AmountIncludingVAT) AS AmountIncludingVAT,
	|		SUM(T.AmountARAP) AS AmountARAP,
	|		NULL AS VATRateAfter,
	|		NULL AS PriceAfter,
	|		SUM(T.NumberOfPackagesAfter) AS NumberOfPackagesAfter,
	|		SUM(T.QuantityAfter) AS QuantityAfter,
	|		SUM(T.QuantityAccordingToRNPTAfter) AS QuantityAccordingToRNPTAfter,
	|		SUM(T.AmountAfter) AS AmountAfter,
	|		SUM(T.VATAmountAfter) AS VATAmountAfter,
	|		SUM(T.AmountWithVATAfter) AS AmountWithVATAfter,
	|		SUM(T.AmountOfSettlementsAfter) AS AmountOfSettlementsAfter,
	|		MAX(DiscrepanciesBefore.PostingOption) AS ReflectionOptionUpTo,
	|		NULL AS ReflectionOptionAfter,
	|		MAX(T.CostDefiningMethod) AS CostDefiningMethod,
	|		MAX(T.Cost_) AS Cost_,
	|		MAX(T.CostExcludingVAT_) AS CostExcludingVAT_,
	|		MAX(T.CostLocal) AS CostLocal,
	|		MAX(T.CDCost) AS CDCost,
	|		MAX(T.TDCost) AS TDCost,
	|		MAX(T.CostPriceKind) AS CostPriceKind,
	|		MAX(T.DateOfCostFillingByPriceType) AS DateOfCostFillingByPriceType,
	|		MAX(T.LineNumber) AS LineNumber,
	|		MAX(T.RowID) AS RowID,
	|		SUM(T.AmountExcludingVATCompl) AS AmountExcludingVATCompl,
	|		SUM(T.AmountExcludingVATMan) AS AmountExcludingVATMan,
	|		SUM(T.VATExclusiveAmountLocalAfter) AS VATExclusiveAmountLocalAfter,
	|		SUM(T.VATExclusiveAmountManAfter) AS VATExclusiveAmountManAfter	
	|	FROM
	|		(SELECT
	|			Goods.Ref AS Ref,
	|			Goods.Products AS Products,
	|			Goods.PartnerProducts AS PartnerProducts,
	|			Goods.FEACNCode AS FEACNCode,
	|			Goods.Characteristic AS Characteristic,
	|			Goods.ProductsInSet AS ProductsInSet,
	|			Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|			Goods.Content AS Content,
	|			Goods.Package AS Package,
	|			Goods.Series AS Series,
	|			Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|			Goods.Warehouse AS Warehouse,
	|			Goods.Department AS Department,
	|			Goods.CCDNumber AS CCDNumber,
	|			Goods.IncomeItem AS IncomeItem,
	|			Goods.DimensionOfRevenue AS DimensionOfRevenue,
	|			Goods.VATRate AS VATRate,
	|			Goods.Price AS Price,
	|			Goods.NumberOfPackages AS NumberOfPackages,
	|			Goods.Count AS Count,
	|			Goods.QuantityByGBRN AS QuantityByGBRN,
	|			Goods.Sum AS Sum,
	|			Goods.VATAmount AS VATAmount,
	|			Goods.AmountIncludingVAT AS AmountIncludingVAT,
	|			Goods.AmountARAP AS AmountARAP,
	|			0 AS NumberOfPackagesAfter,
	|			0 AS QuantityAfter,
	|			0 AS QuantityAccordingToRNPTAfter,
	|			0 AS AmountAfter,
	|			0 AS VATAmountAfter,
	|			0 AS AmountWithVATAfter,
	|			0 AS AmountOfSettlementsAfter,
	|			NULL AS CostDefiningMethod,
	|			NULL AS Cost_,
	|			NULL AS CostExcludingVAT_,
	|			NULL AS CostLocal,
	|			NULL AS CDCost,
	|			NULL AS TDCost,
	|			NULL AS CostPriceKind,
	|			NULL AS DateOfCostFillingByPriceType,
	|			Goods.LineNumber AS LineNumber,
	|			Goods.RowID AS RowID,
	|			Goods.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|			Goods.AmountExcludingVATMan AS AmountExcludingVATMan,
	|			0 AS VATExclusiveAmountLocalAfter,
	|			0 AS VATExclusiveAmountManAfter
	|		FROM
	|			TTProducts_1 AS Goods
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Discrepancies.Ref,
	|			Discrepancies.Products,
	|			Discrepancies.PartnerProducts AS PartnerProducts,
	|			Discrepancies.FEACNCode AS FEACNCode,
	|			Discrepancies.Characteristic,
	|			Discrepancies.ProductsInSet,
	|			Discrepancies.ItemVariantOfSet,
	|			Discrepancies.Content,
	|			Discrepancies.Package,
	|			Discrepancies.Series,
	|			Discrepancies.BatchesIndicationStatus,
	|			Discrepancies.Warehouse,
	|			Discrepancies.Department,
	|			Discrepancies.CCDNumber,
	|			Discrepancies.IncomeItem,
	|			Discrepancies.DimensionOfRevenue,
	|			Discrepancies.VATRate,
	|			0,
	|			-Discrepancies.NumberOfPackages,
	|			-Discrepancies.Count,
	|			-Discrepancies.QuantityByGBRN,
	|			-Discrepancies.Sum,
	|			-Discrepancies.VATAmount,
	|			-Discrepancies.AmountIncludingVAT,
	|			-Discrepancies.AmountARAP,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			Discrepancies.CostDefiningMethod,
	|			Discrepancies.Cost_ AS Cost_,
	|			Discrepancies.CostExcludingVAT_ AS CostExcludingVAT_,
	|			Discrepancies.CostLocal AS CostLocal,
	|			Discrepancies.CDCost AS CDCost,
	|			Discrepancies.TDCost AS TDCost,
	|			Discrepancies.CostPriceKind AS CostPriceKind,
	|			Discrepancies.DateOfCostFillingByPriceType AS DateOfCostFillingByPriceType,
	|			0 AS LineNumber,
	|			NULL AS RowID,
	|			-Discrepancies.AmountExcludingVATCompl,
	|			-Discrepancies.AmountExcludingVATMan,
	|			0,
	|			0
	|
	|		FROM
	|			TTDiscrepancies AS Discrepancies) AS T
	|			LEFT JOIN TTDiscrepancies AS DiscrepanciesBefore
	|			ON DiscrepanciesBefore.Ref = T.Ref
	|				AND (DiscrepanciesBefore.Products = T.Products)
	|				AND (DiscrepanciesBefore.Products = T.Products)
	|				AND (DiscrepanciesBefore.Characteristic = T.Characteristic)
	|				AND (DiscrepanciesBefore.ProductsInSet = T.ProductsInSet)
	|				AND (DiscrepanciesBefore.ItemVariantOfSet = T.ItemVariantOfSet)
	|				AND (DiscrepanciesBefore.Content = T.Content)
	|				AND (DiscrepanciesBefore.Package = T.Package)
	|				AND (DiscrepanciesBefore.Series = T.Series)
	|				AND (DiscrepanciesBefore.BatchesIndicationStatus = T.BatchesIndicationStatus)
	|				AND (DiscrepanciesBefore.Warehouse = T.Warehouse)
	|				AND (DiscrepanciesBefore.Department = T.Department)
	|				AND (DiscrepanciesBefore.CCDNumber = T.CCDNumber)
	|				AND (DiscrepanciesBefore.IncomeItem = T.IncomeItem)
	|				AND (DiscrepanciesBefore.DimensionOfRevenue = T.DimensionOfRevenue)
	|				AND (DiscrepanciesBefore.VATRate = T.VATRate)
	|	
	|	GROUP BY
	|		T.Ref,
	|		T.Products,
	|		T.PartnerProducts,
	|		T.FEACNCode,
	|		T.Characteristic,
	|		T.ProductsInSet,
	|		T.ItemVariantOfSet,
	|		T.Content,
	|		T.Package,
	|		T.Series,
	|		T.BatchesIndicationStatus,
	|		T.Warehouse,
	|		T.Department,
	|		T.CCDNumber,
	|		T.IncomeItem,
	|		T.DimensionOfRevenue,
	|		T.VATRate
	|	
	|	HAVING
	|		(SUM(T.NumberOfPackages) <> 0
	|			OR SUM(T.Count) <> 0
	|			OR SUM(T.QuantityByGBRN) <> 0
	|			OR SUM(T.Sum) <> 0
	|			OR SUM(T.VATAmount) <> 0
	|			OR SUM(T.AmountIncludingVAT) <> 0
	|			OR SUM(T.AmountARAP) <> 0)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Goods.Ref,
	|		Goods.Products,
	|		Goods.PartnerProducts AS PartnerProducts,
	|		Goods.FEACNCode AS FEACNCode,
	|		Goods.Characteristic,
	|		Goods.ProductsInSet,
	|		Goods.ItemVariantOfSet,
	|		Goods.Content,
	|		Goods.Package,
	|		Goods.Series,
	|		Goods.BatchesIndicationStatus,
	|		Goods.Warehouse,
	|		Goods.Department,
	|		Goods.CCDNumber,
	|		Goods.IncomeItem,
	|		Goods.DimensionOfRevenue,
	|		NULL,
	|		NULL,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		Goods.VATRate,
	|		Goods.Price,
	|		Goods.NumberOfPackages,
	|		Goods.Count,
	|		Goods.QuantityByGBRN,
	|		Goods.Sum,
	|		Goods.VATAmount,
	|		Goods.AmountIncludingVAT,
	|		Goods.AmountARAP,
	|		NULL,
	|		DiscrepanciesAfter.PostingOption,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,
	|		NULL,		 
	|		Goods.LineNumber AS LineNumber,
	|		Goods.RowID AS RowID,
	|		0,
	|		0,
	|		Goods.AmountExcludingVATCompl,
	|		Goods.AmountExcludingVATMan
	|	FROM
	|		TTProducts_1 AS Goods
	|			LEFT JOIN TTDiscrepancies AS DiscrepanciesAfter
	|			ON DiscrepanciesAfter.Ref = Goods.Ref
	|				AND (DiscrepanciesAfter.Products = Goods.Products)
	|				AND (DiscrepanciesAfter.Products = Goods.Products)
	|				AND (DiscrepanciesAfter.Characteristic = Goods.Characteristic)
	|				AND (DiscrepanciesAfter.ProductsInSet = Goods.ProductsInSet)
	|				AND (DiscrepanciesAfter.ItemVariantOfSet = Goods.ItemVariantOfSet)
	|				AND (DiscrepanciesAfter.Content = Goods.Content)
	|				AND (DiscrepanciesAfter.Package = Goods.Package)
	|				AND (DiscrepanciesAfter.Series = Goods.Series)
	|				AND (DiscrepanciesAfter.BatchesIndicationStatus = Goods.BatchesIndicationStatus)
	|				AND (DiscrepanciesAfter.Warehouse = Goods.Warehouse)
	|				AND (DiscrepanciesAfter.Department = Goods.Department)
	|				AND (DiscrepanciesAfter.CCDNumber = Goods.CCDNumber)
	|				AND (DiscrepanciesAfter.IncomeItem = Goods.IncomeItem)
	|				AND (DiscrepanciesAfter.DimensionOfRevenue = Goods.DimensionOfRevenue)
	|				AND (DiscrepanciesAfter.VATRate = Goods.VATRate)) AS Table
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.Products,
	|	Table.PartnerProducts,
	|	Table.FEACNCode,
	|	Table.Characteristic,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Content,
	|	Table.Package,
	|	Table.Series,
	|	Table.BatchesIndicationStatus,
	|	Table.Warehouse,
	|	Table.Department,
	|	Table.CCDNumber,
	|	Table.IncomeItem,
	|	Table.DimensionOfRevenue
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTProducts_1
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTDiscrepancies
	|";

	Return QueryText;
	
EndFunction

Function QueryTextTTTypesOfStocks() Export
	
	QueryText = "
	|SELECT
	|	DocumentsData.Ref AS Main,
	|	DocumentsData.Ref AS Subordinated,
	|	DocumentsData.Ref.PointInTime AS PointInTime
	|INTO TTRelatedDocuments
	|FROM
	|	DocumentDataTable_ AS DocumentsData
	|WHERE
	|	DocumentsData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods),
	|		VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods))
	|
	|UNION ALL
	|
	|SELECT
	|	CurrentDocument.Ref AS Main,
	|	CurrentDocument.DocumentBasis AS Subordinated,
	|	CurrentDocument.DocumentBasis.PointInTime AS PointInTime
	|FROM
	|	Document.SaleAdjustment AS CurrentDocument
	|	INNER JOIN DocumentDataTable_ AS DocumentsData
	|		ON CurrentDocument.Ref = DocumentsData.Ref
	|WHERE
	|	NOT DocumentsData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods),
	|		VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods))
	|
	|UNION ALL
	|
	|SELECT
	|	CurrentDocument.Ref AS Main,
	|	PreviousDocuments.Ref AS Subordinated,
	|	PreviousDocuments.PointInTime AS PointInTime
	|FROM
	|	Document.SaleAdjustment AS CurrentDocument
	|	INNER JOIN DocumentDataTable_ AS DocumentsData
	|		ON CurrentDocument.Ref = DocumentsData.Ref
	|	INNER JOIN Document.SaleAdjustment AS PreviousDocuments
	|		ON CurrentDocument.DocumentBasis = PreviousDocuments.DocumentBasis
	|			AND (CurrentDocument.Date >= PreviousDocuments.Date
	|			OR (CurrentDocument.Date = PreviousDocuments.Date
	|			AND CurrentDocument.Ref >= PreviousDocuments.Ref))
	|WHERE
	|	PreviousDocuments.Posted
	|	AND NOT DocumentsData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods),
	|		VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods))
	|
	|UNION ALL
	|
	|SELECT
	|	UNDEFINED AS Main,
	|	AdjustingEntries.Ref AS Subordinated,
	|	AdjustingEntries.PointInTime AS PointInTime
	|FROM
	|	Document.SaleAdjustment AS AdjustingEntries
	|WHERE
	|	AdjustingEntries.DocumentBasis = &BasisOfUnrecordedDocument
	|	AND AdjustingEntries.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	UNDEFINED AS Main,
	|	TheseGrounds.Ref AS Subordinated,
	|	TheseGrounds.PointInTime AS PointInTime
	|FROM
	|	Document.CustomerInvoice AS TheseGrounds
	|WHERE
	|	TheseGrounds.Ref = &BasisOfUnrecordedDocument
	|
	|UNION ALL
	|
	|SELECT
	|	UNDEFINED AS Main,
	|	TheseGrounds.Ref AS Subordinated,
	|	TheseGrounds.PointInTime AS PointInTime
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS TheseGrounds
	|WHERE
	|	TheseGrounds.Ref = &BasisOfUnrecordedDocument	
	|
	|UNION ALL
	|
	|SELECT
	|	UNDEFINED AS Main,
	|	TheseGrounds.Ref AS Subordinated,
	|	TheseGrounds.PointInTime AS PointInTime
	|FROM
	|	Document.CustomerInvoiceServices AS TheseGrounds
	|WHERE
	|	TheseGrounds.Ref = &BasisOfUnrecordedDocument	
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RelatedDocuments.Main AS Main
	|INTO TTRelatedDocumentsAdjustmentForPrimaryDocuments
	|FROM
	|	TTRelatedDocuments AS RelatedDocuments
	|WHERE
	|	RelatedDocuments.Main REFS Document.SaleAdjustment
	|	AND CAST(RelatedDocuments.Subordinated AS Document.SaleAdjustment).AdjustingEntryType IN (
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
	|	)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CAST(Goods.Ref AS Document.SaleAdjustment) AS Ref,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	SUM(Goods.NumberOfPackagesAfter) AS NumberOfPackages,
	|	SUM(Goods.QuantityAfter) AS Count,
	|	SUM(CASE
	|		WHEN Goods.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|			THEN InventoryKinds.QuantityByGBRN
	|		ELSE Goods.QuantityAccordingToRNPTAfter
	|		END) AS QuantityByGBRN,
	|	SUM(Goods.VATAmountAfter) AS VATAmount,
	|	SUM(AmountsOfLocalGOODS.AmountExcludingVATCompl) AS AmountExcludingVATCompl,
	|	SUM(AmountsOfLocalGOODS.VATAmountCompl) AS VATAmountCompl,
	|	SUM(Goods.AmountAfter) AS Sum,
	|	SUM(InventoryKinds.ExciseTaxAmount) AS ExciseTaxAmount,
	|	CASE
	|		WHEN Goods.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|			THEN InventoryKinds.CCDNumber
	|		ELSE Goods.CCDNumber
	|	END AS CCDNumber,
	|	InventoryKinds.ToIncomeExpenses AS ToIncomeExpenses
	|
	|INTO TTAdjustmentDataAfter
	|
	|FROM
	|	TTAdjustmentDataBeforeEnteringBalances AS Goods
	|	INNER JOIN TTRelatedDocumentsAdjustmentForPrimaryDocuments AS RelatedDocuments
	|		ON Goods.Ref = RelatedDocuments.Main
	|	INNER JOIN Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS InventoryKinds
	|		ON Goods.Ref = InventoryKinds.Ref
	|		AND InventoryKinds.ItemsLocationAttributes.Products = Goods.Products
	|		AND InventoryKinds.ItemsLocationAttributes.Characteristic = Goods.Characteristic
	|		AND InventoryKinds.ItemsLocationAttributes.Series = Goods.Series
	|		AND InventoryKinds.ItemsLocationAttributes.StorageLocation = Goods.Ref.Warehouse
	|		AND ((InventoryKinds.CCDNumber = Goods.CCDNumber
	|			AND Goods.PostingOption IN (VALUE(Enum.CreditNoteRecordingOptions.EmptyRef),
	|										VALUE(Enum.CreditNoteRecordingOptions.RecordInOtherIncome)))
	|			OR (Goods.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|					AND Goods.PostingOption IN (VALUE(Enum.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount),
	|												VALUE(Enum.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock)))
	|			OR (Goods.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|					AND Goods.PostingOption = VALUE(Enum.CreditNoteRecordingOptions.IncreaseSale)
	|					AND Goods.QuantityAfter > Goods.Count))
    |
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS AmountsOfLocalGOODS
	|		ON Goods.Ref = AmountsOfLocalGOODS.Ref
	|			AND Goods.RowID = AmountsOfLocalGOODS.RowID
	|			AND &ConvertToLocalCurrency
	|
	|GROUP BY
	|	Goods.Ref,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	CASE
	|		WHEN Goods.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|			THEN InventoryKinds.CCDNumber
	|		ELSE Goods.CCDNumber
	|	END,
	|	InventoryKinds.ToIncomeExpenses
	|
	|;
	|SELECT
	|	RelatedDocuments.Main AS Ref,
	|	FALSE AS BeforeAdjustment,
	|	InventoryKinds.LineNumber AS LineNumber,
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension AS SetAccountingDimension,
	|	InventoryKinds.Package AS Package,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	InventoryKinds.FEACNCode AS FEACNCode,
	|	InventoryKinds.NumberOfPackages AS NumberOfPackages,
	|	InventoryKinds.Count AS Count,
	|	InventoryKinds.QuantityByGBRN AS QuantityByGBRN,
	|	InventoryKinds.ExciseTaxAmount AS ExciseTaxAmount,
	|	
	|	ISNULL(
	|		AmountsCompl.AmountExcludingVATCompl,
	|		InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount
	|	) AS AmountExcludingVAT,
	|	
	|	InventoryKinds.VATRate AS VATRate,
	|	
	|	ISNULL(
	|		AmountsCompl.VATAmountCompl,
	|		InventoryKinds.VATAmount
	|	) AS VATAmount,
	|	
	|	InventoryKinds.SalesOrder AS SalesOrder,
	|
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	FALSE 		 AS ToExpenseAs,
	|	UNDEFINED AS AssetsLiabilitiesDimension
	|
	|INTO AllKindsOfStocks
	|FROM
	|	Document.CustomerInvoice.InventoryKinds AS InventoryKinds
	|	INNER JOIN TTRelatedDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Subordinated
	|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS AmountsCompl
	|		ON InventoryKinds.Ref = AmountsCompl.Recorder
	|			AND InventoryKinds.RowID = AmountsCompl.RowID
	|			AND AmountsCompl.Active
	|			AND &ConvertToLocalCurrency
	|
	|UNION ALL
	|
	|SELECT
	|	RelatedDocuments.Main AS Ref,
	|	TRUE AS BeforeAdjustment,
	|	InventoryKinds.LineNumber AS LineNumber,
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension AS SetAccountingDimension,
	|	InventoryKinds.Package AS Package,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	InventoryKinds.FEACNCode AS FEACNCode,
	|	InventoryKinds.NumberOfPackages AS NumberOfPackages,
	|	InventoryKinds.Count AS Count,
	|	InventoryKinds.QuantityByGBRN AS QuantityByGBRN,
	|	InventoryKinds.ExciseTaxAmount AS ExciseTaxAmount,
	|	
	|	ISNULL(
	|		AmountsCompl.AmountExcludingVATCompl,
	|		InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount
	|	) AS AmountExcludingVAT,
	|	
	|	InventoryKinds.VATRate AS VATRate,
	|	
	|	ISNULL(
	|		AmountsCompl.VATAmountCompl,
	|		InventoryKinds.VATAmount
	|	) AS VATAmount,
	|	
	|	InventoryKinds.SalesOrder AS SalesOrder,
	|
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	FALSE 		 AS ToExpenseAs,
	|	UNDEFINED AS AssetsLiabilitiesDimension
	|
	|FROM
	|	Document.CustomerInvoice.InventoryKinds AS InventoryKinds
	|	INNER JOIN TTRelatedDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Subordinated
	|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS AmountsCompl
	|		ON InventoryKinds.Ref = AmountsCompl.Recorder
	|			AND InventoryKinds.RowID = AmountsCompl.RowID
	|			AND AmountsCompl.Active
	|			AND &ConvertToLocalCurrency
	|WHERE
	|	&IncludingBeforeAdjustment
	|
	|UNION ALL
	|
	|SELECT
	|	RelatedDocuments.Main,
	|	FALSE,
	|	InventoryKinds.LineNumber,
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension,
	|	InventoryKinds.Package,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber,
	|	InventoryKinds.FEACNCode,
	|	0,
	|	0,
	|	0 AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	
	|	ISNULL(
	|		AmountsCompl.AmountExcludingVATCompl,
	|		InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount
	|	),
	|	
	|	InventoryKinds.VATRate,
	|	
	|	ISNULL(
	|		AmountsCompl.VATAmountCompl,
	|		InventoryKinds.VATAmount
	|	),
	|	
	|	InventoryKinds.SalesOrder,
	|
	|	InventoryKinds.ExpenseItem AS ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses AS DimensionOfExpenses,
	|	InventoryKinds.ToExpenseAs AS ToExpenseAs,
	|	InventoryKinds.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension
	|
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesRevenueAdjustment AS InventoryKinds
	|	INNER JOIN TTRelatedDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Subordinated
	|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS AmountsCompl
	|		ON InventoryKinds.Ref = AmountsCompl.Recorder
	|			AND InventoryKinds.RowID = AmountsCompl.RowID
	|			AND AmountsCompl.Active
	|			AND &ConvertToLocalCurrency
	|WHERE
	|	InventoryKinds.Ref.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.StandardAdjustment)
	|
	|UNION ALL
	|
	|SELECT
	|	RelatedDocuments.Main,
	|	TRUE,
	|	InventoryKinds.LineNumber,
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension,
	|	InventoryKinds.Package,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber,
	|	InventoryKinds.FEACNCode,
	|	0,
	|	0,
	|	0 AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	
	|	ISNULL(
	|		AmountsCompl.AmountExcludingVATCompl,
	|		InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount
	|	),
	|	
	|	InventoryKinds.VATRate,
	|	
	|	ISNULL(
	|		AmountsCompl.VATAmountCompl,
	|		InventoryKinds.VATAmount
	|	),
	|	
	|	InventoryKinds.SalesOrder,
	|
	|	InventoryKinds.ExpenseItem AS ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses AS DimensionOfExpenses,
	|	InventoryKinds.ToExpenseAs AS ToExpenseAs,
	|	InventoryKinds.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension
	|
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesRevenueAdjustment AS InventoryKinds
	|	INNER JOIN TTRelatedDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Subordinated
	|			AND InventoryKinds.Ref <> RelatedDocuments.Main
	|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS AmountsCompl
	|		ON InventoryKinds.Ref = AmountsCompl.Recorder
	|			AND InventoryKinds.RowID = AmountsCompl.RowID
	|			AND AmountsCompl.Active
	|			AND &ConvertToLocalCurrency
	|WHERE
	|	&IncludingBeforeAdjustment
	|	AND InventoryKinds.Ref.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.StandardAdjustment)
	|
	|UNION ALL
	|
	|SELECT
	|	RelatedDocuments.Main,
	|	FALSE,
	|	InventoryKinds.LineNumber,
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension,
	|	InventoryKinds.Package,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber,
	|	InventoryKinds.FEACNCode,
	|	-InventoryKinds.NumberOfPackages,
	|	-InventoryKinds.Count,
	|	-InventoryKinds.QuantityByGBRN,
	|	-InventoryKinds.ExciseTaxAmount AS ExciseTaxAmount,
	|	
	|	-ISNULL(
	|		-AmountsCompl.AmountExcludingVATCompl,
	|		InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount
	|	),
	|	
	|	InventoryKinds.VATRate,
	|	
	|	-ISNULL(
	|		-AmountsCompl.VATAmountCompl,
	|		InventoryKinds.VATAmount
	|	),
	|	
	|	InventoryKinds.SalesOrder,
	|
	|	InventoryKinds.ExpenseItem AS ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses AS DimensionOfExpenses,
	|	InventoryKinds.ToExpenseAs AS ToExpenseAs,
	|	InventoryKinds.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension
	|
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS InventoryKinds
	|	INNER JOIN TTRelatedDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Subordinated
	|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS AmountsCompl
	|		ON InventoryKinds.Ref = AmountsCompl.Recorder
	|			AND InventoryKinds.RowID = AmountsCompl.RowID
	|			AND AmountsCompl.Active
	|			AND &ConvertToLocalCurrency
	|WHERE
	|	InventoryKinds.Ref.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.StandardAdjustment)
	|
	|UNION ALL
	|
	|SELECT
	|	RelatedDocuments.Main,
	|	TRUE,
	|	InventoryKinds.LineNumber,
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension,
	|	InventoryKinds.Package,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber,
	|	InventoryKinds.FEACNCode,
	|	-InventoryKinds.NumberOfPackages,
	|	-InventoryKinds.Count,
	|	-InventoryKinds.QuantityByGBRN,
	|	-InventoryKinds.ExciseTaxAmount AS ExciseTaxAmount,
	|	
	|	-ISNULL(
	|		-AmountsCompl.AmountExcludingVATCompl,
	|		InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount
	|	),
	|	
	|	InventoryKinds.VATRate,
	|	
	|	-ISNULL(
	|		-AmountsCompl.VATAmountCompl,
	|		InventoryKinds.VATAmount
	|	),
	|	
	|	InventoryKinds.SalesOrder,
	|
	|	InventoryKinds.ExpenseItem AS ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses AS DimensionOfExpenses,
	|	InventoryKinds.ToExpenseAs AS ToExpenseAs,
	|	InventoryKinds.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension
	|
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS InventoryKinds
	|	INNER JOIN TTRelatedDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Subordinated
	|			AND InventoryKinds.Ref <> RelatedDocuments.Main
	|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS AmountsCompl
	|		ON InventoryKinds.Ref = AmountsCompl.Recorder
	|			AND InventoryKinds.RowID = AmountsCompl.RowID
	|			AND AmountsCompl.Active
	|			AND &ConvertToLocalCurrency
	|WHERE
	|	&IncludingBeforeAdjustment
	|	AND InventoryKinds.Ref.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.StandardAdjustment)
	|
	|UNION ALL
	|
	|SELECT
	|	RelatedDocuments.Main,
	|	FALSE,
	|	InventoryKinds.LineNumber,
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension,
	|	InventoryKinds.Package,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber,
	|	InventoryKinds.FEACNCode,
	|	InventoryKinds.NumberOfPackages,
	|	InventoryKinds.Count,
	|	InventoryKinds.QuantityByGBRN,
	|	InventoryKinds.ExciseTaxAmount AS ExciseTaxAmount,
	|	
	|	ISNULL(
	|		AmountsCompl.AmountExcludingVATCompl,
	|		InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount
	|	),
	|	
	|	InventoryKinds.VATRate,
	|	
	|	ISNULL(
	|		AmountsCompl.VATAmountCompl,
	|		InventoryKinds.VATAmount
	|	),
	|	
	|	InventoryKinds.SalesOrder,
	|
	|	InventoryKinds.ExpenseItem AS ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses AS DimensionOfExpenses,
	|	InventoryKinds.ToExpenseAs AS ToExpenseAs,
	|	InventoryKinds.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension
	|
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS InventoryKinds
	|	INNER JOIN TTRelatedDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Subordinated
	|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS AmountsCompl
	|		ON InventoryKinds.Ref = AmountsCompl.Recorder
	|			AND InventoryKinds.RowID = AmountsCompl.RowID
	|			AND AmountsCompl.Active
	|			AND &ConvertToLocalCurrency
	|WHERE
	|	InventoryKinds.Ref.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.StandardAdjustment)
	|
	|UNION ALL
	|
	|SELECT
	|	RelatedDocuments.Main,
	|	TRUE,
	|	InventoryKinds.LineNumber,
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension,
	|	InventoryKinds.Package,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber,
	|	InventoryKinds.FEACNCode,
	|	InventoryKinds.NumberOfPackages,
	|	InventoryKinds.Count,
	|	InventoryKinds.QuantityByGBRN,
	|	InventoryKinds.ExciseTaxAmount AS ExciseTaxAmount,
	|	
	|	ISNULL(
	|		AmountsCompl.AmountExcludingVATCompl,
	|		InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount
	|	),
	|	
	|	InventoryKinds.VATRate,
	|	
	|	ISNULL(
	|		AmountsCompl.VATAmountCompl,
	|		InventoryKinds.VATAmount
	|	),
	|	
	|	InventoryKinds.SalesOrder,
	|
	|	InventoryKinds.ExpenseItem AS ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses AS DimensionOfExpenses,
	|	InventoryKinds.ToExpenseAs AS ToExpenseAs,
	|	InventoryKinds.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension
	|
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS InventoryKinds
	|	INNER JOIN TTRelatedDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Subordinated
	|			AND InventoryKinds.Ref <> RelatedDocuments.Main
	|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS AmountsCompl
	|		ON InventoryKinds.Ref = AmountsCompl.Recorder
	|			AND InventoryKinds.RowID = AmountsCompl.RowID
	|			AND AmountsCompl.Active
	|			AND &ConvertToLocalCurrency
	|WHERE
	|	&IncludingBeforeAdjustment
	|	AND InventoryKinds.Ref.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.StandardAdjustment)
	|
	|
	|UNION ALL
	|
	// According to the Primary document, no discrepancies.
	|SELECT
	|	RelatedDocuments.Main,
	|	FALSE,
	|	Goods.LineNumber,
	|	Dimension.DimensionKey,
	|	ISNULL(DimensionOfSets.DimensionKey, VALUE(Catalog.KeysOfSetAccountingDimension.EmptyRef)),
	|	Goods.Package,
	// The source document from where you can extract the type of reserves does not exist.
	|	UNDEFINED,
	|	Goods.CCDNumber,
	|	Goods.FEACNCode,
	|	Goods.NumberOfPackages,
	|	Goods.Count,
	|	Goods.QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	ISNULL(AmountsCompl.AmountExcludingVATCompl, Goods.Sum),
	|	Goods.VATRate,
	|	ISNULL(AmountsCompl.VATAmountCompl, Goods.VATAmount),
	|	Goods.SalesOrder,
	|
	|	Goods.ExpenseItem AS ExpenseItem,
	|	Goods.DimensionOfExpenses AS DimensionOfExpenses,
	|	Goods.ToExpenseAs AS ToExpenseAs,
	|	Goods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension
	|
	|FROM
	|	Document.SaleAdjustment.Goods AS Goods
	|	INNER JOIN TTRelatedDocumentsAdjustmentForPrimaryDocuments AS RelatedDocuments
	|		ON Goods.Ref = RelatedDocuments.Main
	|	LEFT JOIN Document.SaleAdjustment.Discrepancies AS Discrepancies
	|		ON Goods.Ref = Discrepancies.Ref
	|		AND Goods.Products = Discrepancies.ItemsLocationAttributes.Products
	|		AND Goods.Characteristic = Discrepancies.ItemsLocationAttributes.Characteristic
	|		AND Goods.Series = Discrepancies.ItemsLocationAttributes.Series
	|		AND Goods.Purpose = Discrepancies.ItemsLocationAttributes.Purpose
	|	INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON Dimension.Products = Goods.Products
	|		AND Dimension.Characteristic = Goods.Characteristic
	|		AND Dimension.Series = Goods.Series
	|		AND Dimension.StorageLocation = Goods.Ref.Warehouse
	|		AND Dimension.Purpose = Goods.Purpose
	|		AND Dimension.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
	|	LEFT JOIN InformationRegister.SetAccountingDimension AS DimensionOfSets
	|		ON DimensionOfSets.ProductsInSet = Goods.ProductsInSet
	|		AND DimensionOfSets.ItemVariantOfSet = Goods.ItemVariantOfSet
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS AmountsCompl
	|		ON Goods.Ref = AmountsCompl.Ref
	|			AND Goods.RowID = AmountsCompl.RowID
	|			AND &ConvertToLocalCurrency
	|
	|WHERE
	|	Goods.Ref.AdjustingEntryType IN (
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
	|	)
	|	AND Discrepancies.ItemsLocationAttributes IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	RelatedDocuments.Main,
	|	TRUE,
	|	Goods.LineNumber,
	|	Dimension.DimensionKey,
	|	ISNULL(DimensionOfSets.DimensionKey, VALUE(Catalog.KeysOfSetAccountingDimension.EmptyRef)),
	|	Goods.Package,
	// The source document from where you can extract the type of reserves does not exist.
	|	UNDEFINED,
	|	Goods.CCDNumber,
	|	Goods.FEACNCode,
	|	Goods.NumberOfPackages,
	|	Goods.Count,
	|	Goods.QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	ISNULL(AmountsCompl.AmountExcludingVATCompl, Goods.Sum),
	|	Goods.VATRate,
	|	ISNULL(AmountsCompl.VATAmountCompl, Goods.VATAmount),
	|	Goods.SalesOrder,
	|
	|	Goods.ExpenseItem AS ExpenseItem,
	|	Goods.DimensionOfExpenses AS DimensionOfExpenses,
	|	Goods.ToExpenseAs AS ToExpenseAs,
	|	Goods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension
	|
	|FROM
	|	Document.SaleAdjustment.Goods AS Goods
	|	INNER JOIN TTRelatedDocumentsAdjustmentForPrimaryDocuments AS RelatedDocuments
	|		ON Goods.Ref = RelatedDocuments.Main
	|	LEFT JOIN Document.SaleAdjustment.Discrepancies AS Discrepancies
	|		ON Goods.Ref = Discrepancies.Ref
	|		AND Goods.Products = Discrepancies.ItemsLocationAttributes.Products
	|		AND Goods.Characteristic = Discrepancies.ItemsLocationAttributes.Characteristic
	|		AND Goods.Series = Discrepancies.ItemsLocationAttributes.Series
	|		AND Goods.Purpose = Discrepancies.ItemsLocationAttributes.Purpose
	|	INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON Dimension.Products = Goods.Products
	|		AND Dimension.Characteristic = Goods.Characteristic
	|		AND Dimension.Series = Goods.Series
	|		AND Dimension.StorageLocation = Goods.Ref.Warehouse
	|		AND Dimension.Purpose = Goods.Purpose
	|		AND Dimension.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
	|	LEFT JOIN InformationRegister.SetAccountingDimension AS DimensionOfSets
	|		ON DimensionOfSets.ProductsInSet = Goods.ProductsInSet
	|		AND DimensionOfSets.ItemVariantOfSet = Goods.ItemVariantOfSet
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS AmountsCompl
	|		ON Goods.Ref = AmountsCompl.Ref
	|			AND Goods.RowID = AmountsCompl.RowID
	|			AND &ConvertToLocalCurrency
	|WHERE
	|	&IncludingBeforeAdjustment
	|	AND Goods.Ref.AdjustingEntryType IN (
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
	|	)
	|	AND Discrepancies.ItemsLocationAttributes IS NULL
	|
	|UNION ALL
	|
	// According to the Primary Document, only total discrepancies. The State IS "after" the changes.
	|SELECT
	|	RelatedDocuments.Main,
	|	FALSE,
	|	Goods.LineNumber,
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension,
	|	Goods.Package,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber,
	|	InventoryKinds.FEACNCode,
	|	Goods.NumberOfPackages,
	|	Goods.Count,
	|	Goods.QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	ISNULL(AmountsCompl.AmountExcludingVATCompl, Goods.Sum),
	|	Goods.VATRate,
	|	ISNULL(AmountsCompl.VATAmountCompl, Goods.VATAmount),
	|	Goods.SalesOrder,
	|
	|	InventoryKinds.ExpenseItem AS ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses AS DimensionOfExpenses,
	|	InventoryKinds.ToExpenseAs AS ToExpenseAs,
	|	InventoryKinds.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesRevenueAdjustment AS InventoryKinds
	|	INNER JOIN TTRelatedDocumentsAdjustmentForPrimaryDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Main
	|	INNER JOIN Document.SaleAdjustment.Goods AS Goods
	|		ON InventoryKinds.Ref = Goods.Ref
	|		AND InventoryKinds.ItemsLocationAttributes.Products = Goods.Products
	|		AND InventoryKinds.ItemsLocationAttributes.Characteristic = Goods.Characteristic
	|		AND InventoryKinds.ItemsLocationAttributes.Series = Goods.Series
	|		AND InventoryKinds.ItemsLocationAttributes.StorageLocation = Goods.Ref.Warehouse
	|		AND InventoryKinds.CCDNumber = Goods.CCDNumber
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS AmountsCompl
	|		ON Goods.Ref = AmountsCompl.Ref
	|			AND Goods.RowID = AmountsCompl.RowID
	|			AND &ConvertToLocalCurrency
	|WHERE
	|	Goods.Ref.AdjustingEntryType IN (
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
	|	)
	|
	|UNION ALL
	|
	// According to the Primary Document, only total discrepancies. The State "before" the changes.
	|SELECT
	|	RelatedDocuments.Main,
	|	TRUE,
	|	Goods.LineNumber,
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension,
	|	Goods.Package,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	Goods.CCDNumber,
	|	Goods.FEACNCode,
	|	Goods.NumberOfPackages,
	|	Goods.Count,
	|	Goods.QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	ISNULL(AmountsOfLocalGOODS.AmountExcludingVATCompl - AmountsCompl.AmountExcludingVATCompl,
	|		Goods.Sum - (InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount)),
	|	InventoryKinds.VATRate,
	|	ISNULL(AmountsOfLocalGOODS.VATAmountCompl - AmountsCompl.VATAmountCompl,
	|		Goods.VATAmount - InventoryKinds.VATAmount),
	|	InventoryKinds.SalesOrder,
	|
	|	InventoryKinds.ExpenseItem AS ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses AS DimensionOfExpenses,
	|	InventoryKinds.ToExpenseAs AS ToExpenseAs,
	|	InventoryKinds.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesRevenueAdjustment AS InventoryKinds
	|	INNER JOIN TTRelatedDocumentsAdjustmentForPrimaryDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Main
	|	INNER JOIN Document.SaleAdjustment.Goods AS Goods
	|		ON InventoryKinds.Ref = Goods.Ref
	|		AND InventoryKinds.ItemsLocationAttributes.Products = Goods.Products
	|		AND InventoryKinds.ItemsLocationAttributes.Characteristic = Goods.Characteristic
	|		AND InventoryKinds.ItemsLocationAttributes.Series = Goods.Series
	|		AND InventoryKinds.ItemsLocationAttributes.StorageLocation = Goods.Ref.Warehouse
	|		AND InventoryKinds.CCDNumber = Goods.CCDNumber
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS AmountsOfLocalGOODS
	|		ON Goods.Ref = AmountsOfLocalGOODS.Ref
	|			AND Goods.RowID = AmountsOfLocalGOODS.RowID
	|			AND &ConvertToLocalCurrency
	|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS AmountsCompl
	|		ON InventoryKinds.Ref = AmountsCompl.Recorder
	|			AND InventoryKinds.RowID = AmountsCompl.RowID
	|			AND AmountsCompl.Active
	|			AND &ConvertToLocalCurrency
	|WHERE
	|	&IncludingBeforeAdjustment
	|	AND Goods.Ref.AdjustingEntryType IN (
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
	|	)
	|
	|UNION ALL
	|
	// Adjustment (according to the primary document), decrease in sales, returns the State "after adjustment".
	|SELECT
	|	RelatedDocuments.Main,
	|	FALSE,
	|	InventoryKinds.LineNumber,
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension,
	|	InventoryKinds.Package,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber,
	|	InventoryKinds.FEACNCode,
	// A decrease in sales is possible to zero.
	|	ISNULL(Goods.NumberOfPackages, 0),
	|	ISNULL(Goods.Count, 0),
	|	ISNULL(Goods.QuantityByGBRN, 0),
	|	0 AS ExciseTaxAmount,
	|	ISNULL(AmountsCompl.AmountExcludingVATCompl, ISNULL(Goods.Sum, 0)),
	|	InventoryKinds.VATRate,
	|	ISNULL(AmountsCompl.VATAmountCompl, ISNULL(Goods.VATAmount, 0)),
	|	InventoryKinds.SalesOrder,
	|
	|	InventoryKinds.ExpenseItem AS ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses AS DimensionOfExpenses,
	|	InventoryKinds.ToExpenseAs AS ToExpenseAs,
	|	InventoryKinds.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension
	|
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS InventoryKinds
	|	INNER JOIN TTRelatedDocumentsAdjustmentForPrimaryDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Main
	|	LEFT JOIN Document.SaleAdjustment.Goods AS Goods
	|		ON InventoryKinds.Ref = Goods.Ref
	|		AND InventoryKinds.ItemsLocationAttributes.Products = Goods.Products
	|		AND InventoryKinds.ItemsLocationAttributes.Characteristic = Goods.Characteristic
	|		AND InventoryKinds.ItemsLocationAttributes.Series = Goods.Series
	|		AND InventoryKinds.ItemsLocationAttributes.StorageLocation = Goods.Ref.Warehouse
	|		AND InventoryKinds.CCDNumber = Goods.CCDNumber
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS AmountsCompl
	|		ON Goods.Ref = AmountsCompl.Ref
	|			AND Goods.RowID = AmountsCompl.RowID
	|			AND &ConvertToLocalCurrency
	|WHERE
	|	InventoryKinds.Ref.AdjustingEntryType IN (
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
	|	)
	|
	|UNION ALL
	|
	// Adjustment (according to the primary document), an increase in sales, returns the State "after adjustment".
	|SELECT
	|	RelatedDocuments.Main,
	|	FALSE,
	|	InventoryKinds.LineNumber,
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension,
	|	InventoryKinds.Package,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber,
	|	InventoryKinds.FEACNCode,
	|	Goods.NumberOfPackages,
	|	Goods.Count,
	|	Goods.QuantityByGBRN AS QuantityByGBRN,
	|	InventoryKinds.ExciseTaxAmount AS ExciseTaxAmount,
	|	ISNULL(Goods.AmountExcludingVATCompl, Goods.Sum),
	|	InventoryKinds.VATRate,
	|	ISNULL(Goods.VATAmountCompl, Goods.VATAmount),
	|	InventoryKinds.SalesOrder,
	|
	|	InventoryKinds.ExpenseItem AS ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses AS DimensionOfExpenses,
	|	InventoryKinds.ToExpenseAs AS ToExpenseAs,
	|	InventoryKinds.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension
	|
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS InventoryKinds
	|	INNER JOIN TTRelatedDocumentsAdjustmentForPrimaryDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Main
	|	INNER JOIN TTAdjustmentDataAfter AS Goods
	|		ON InventoryKinds.Ref = Goods.Ref
	|		AND InventoryKinds.ItemsLocationAttributes.Products = Goods.Products
	|		AND InventoryKinds.ItemsLocationAttributes.Characteristic = Goods.Characteristic
	|		AND InventoryKinds.ItemsLocationAttributes.Series = Goods.Series
	|		AND InventoryKinds.ItemsLocationAttributes.StorageLocation = Goods.Ref.Warehouse
	|		AND InventoryKinds.CCDNumber = Goods.CCDNumber 
	|		AND InventoryKinds.ToIncomeExpenses = Goods.ToIncomeExpenses
	|WHERE
	|	InventoryKinds.Ref.AdjustingEntryType IN (
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
	|	)
	|
	|UNION ALL
	|
	// Adjustment (according to the primary document), decrease in sales, returns the State "before adjustment".
	|SELECT
	|	RelatedDocuments.Main,
	|	TRUE,
	|	InventoryKinds.LineNumber,
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension,
	|	InventoryKinds.Package,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber,
	|	InventoryKinds.FEACNCode,
	|	ISNULL(Goods.NumberOfPackages, 0) + InventoryKinds.NumberOfPackages,
	|	ISNULL(Goods.Count, 0) + InventoryKinds.Count,
	|	ISNULL(Goods.QuantityByGBRN, 0) + InventoryKinds.QuantityByGBRN,
	|	InventoryKinds.ExciseTaxAmount AS ExciseTaxAmount,
	|	ISNULL(AmountsOfLocalGOODS.AmountExcludingVATCompl, ISNULL(Goods.Sum, 0))
	|		+ ISNULL(-AmountsCompl.AmountExcludingVATCompl, (InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount)),
	|	InventoryKinds.VATRate,
	|	ISNULL(AmountsOfLocalGOODS.VATAmountCompl, ISNULL(Goods.VATAmount, 0))
	|		+ ISNULL(-AmountsCompl.VATAmountCompl, InventoryKinds.VATAmount),
	|	InventoryKinds.SalesOrder,
	|
	|	InventoryKinds.ExpenseItem AS ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses AS DimensionOfExpenses,
	|	InventoryKinds.ToExpenseAs AS ToExpenseAs,
	|	InventoryKinds.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS InventoryKinds
	|	INNER JOIN TTRelatedDocumentsAdjustmentForPrimaryDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Main
	|	LEFT JOIN Document.SaleAdjustment.Goods AS Goods
	|		ON InventoryKinds.Ref = Goods.Ref
	|		AND InventoryKinds.ItemsLocationAttributes.Products = Goods.Products
	|		AND InventoryKinds.ItemsLocationAttributes.Characteristic = Goods.Characteristic
	|		AND InventoryKinds.ItemsLocationAttributes.Series = Goods.Series
	|		AND InventoryKinds.ItemsLocationAttributes.StorageLocation = Goods.Ref.Warehouse
	|		AND InventoryKinds.CCDNumber = Goods.CCDNumber
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS AmountsOfLocalGOODS
	|		ON Goods.Ref = AmountsOfLocalGOODS.Ref
	|			AND Goods.RowID = AmountsOfLocalGOODS.RowID
	|			AND &ConvertToLocalCurrency
	|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS AmountsCompl
	|		ON InventoryKinds.Ref = AmountsCompl.Recorder
	|			AND InventoryKinds.RowID = AmountsCompl.RowID
	|			AND AmountsCompl.Active
	|			AND &ConvertToLocalCurrency
	|WHERE
	|	&IncludingBeforeAdjustment
	|	AND InventoryKinds.Ref.AdjustingEntryType IN (
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
	|	)
	|
	|UNION ALL
	|
	// Adjustment (according to the primary document), an increase in sales, returns the State "before adjustment".
	|SELECT
	|	RelatedDocuments.Main,
	|	TRUE,
	|	InventoryKinds.LineNumber,
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension,
	|	InventoryKinds.Package,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber,
	|	InventoryKinds.FEACNCode,
	|	Goods.NumberOfPackages - InventoryKinds.NumberOfPackages,
	|	Goods.Count - InventoryKinds.Count,
	|	Goods.QuantityByGBRN - InventoryKinds.QuantityByGBRN,
	|	-InventoryKinds.ExciseTaxAmount AS ExciseTaxAmount,
	|	ISNULL(Goods.AmountExcludingVATCompl - AmountsCompl.AmountExcludingVATCompl,
	|		Goods.Sum - (InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount)),
	|	InventoryKinds.VATRate,
	|	ISNULL(Goods.VATAmountCompl - AmountsCompl.VATAmountCompl,
	|		Goods.VATAmount - InventoryKinds.VATAmount),
	|	InventoryKinds.SalesOrder,
	|
	|	InventoryKinds.ExpenseItem AS ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses AS DimensionOfExpenses,
	|	InventoryKinds.ToExpenseAs AS ToExpenseAs,
	|	InventoryKinds.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension
	|
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS InventoryKinds
	|	INNER JOIN TTRelatedDocumentsAdjustmentForPrimaryDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Main
	|	INNER JOIN TTAdjustmentDataAfter AS Goods
	|		ON InventoryKinds.Ref = Goods.Ref
	|		AND InventoryKinds.ItemsLocationAttributes.Products = Goods.Products
	|		AND InventoryKinds.ItemsLocationAttributes.Characteristic = Goods.Characteristic
	|		AND InventoryKinds.ItemsLocationAttributes.Series = Goods.Series
	|		AND InventoryKinds.ItemsLocationAttributes.StorageLocation = Goods.Ref.Warehouse
	|		AND InventoryKinds.CCDNumber = Goods.CCDNumber
	|		AND InventoryKinds.ToIncomeExpenses = Goods.ToIncomeExpenses
	|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS AmountsCompl
	|		ON InventoryKinds.Ref = AmountsCompl.Recorder
	|			AND InventoryKinds.RowID = AmountsCompl.RowID
	|			AND AmountsCompl.Active
	|			AND &ConvertToLocalCurrency
	|WHERE
	|	&IncludingBeforeAdjustment
	|	AND InventoryKinds.Ref.AdjustingEntryType IN (
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices),
	|		VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	RelatedDocuments.Main AS Ref,
	|	FALSE AS BeforeAdjustment,
	|	InventoryKinds.LineNumber AS LineNumber,
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	VALUE(Catalog.KeysOfSetAccountingDimension.EmptyRef) AS SetAccountingDimension,
	|	InventoryKinds.Package AS Package,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	VALUE(Catalog.FEACN.EmptyRef) AS FEACNCode,
	|	InventoryKinds.Count AS NumberOfPackages,
	|	InventoryKinds.Count AS Count,
	|	InventoryKinds.QuantityByGBRN AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	
	|	ISNULL(
	|		AmountsCompl.AmountExcludingVATCompl,
	|		InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount
	|	) AS AmountExcludingVAT,
	|	
	|	InventoryKinds.VATRate AS VATRate,
	|	
	|	ISNULL(
	|		AmountsCompl.VATAmountCompl,
	|		InventoryKinds.VATAmount
	|	) AS VATAmount,
	|	
	|	InventoryKinds.MaterialProviderOrder AS SalesOrder,
	|
	|	InventoryKinds.ExpenseItem AS ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses AS DimensionOfExpenses,
	|	InventoryKinds.ToExpenseAs AS ToExpenseAs,
	|	InventoryKinds.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension
	|
	|FROM
	|	Document.ReportToMaterialProvider2_5.InventoryKinds AS InventoryKinds
	|	INNER JOIN TTRelatedDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Subordinated
	|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS AmountsCompl
	|		ON InventoryKinds.Ref = AmountsCompl.Recorder
	|			AND InventoryKinds.RowID = AmountsCompl.RowID
	|			AND AmountsCompl.Active
	|			AND &ConvertToLocalCurrency
	|
	|UNION ALL
	|
	|SELECT
	|	RelatedDocuments.Main AS Ref,
	|	TRUE AS BeforeAdjustment,
	|	InventoryKinds.LineNumber AS LineNumber,
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	VALUE(Catalog.KeysOfSetAccountingDimension.EmptyRef) AS SetAccountingDimension,
	|	InventoryKinds.Package AS Package,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	VALUE(Catalog.FEACN.EmptyRef) AS FEACNCode,
	|	InventoryKinds.Count AS NumberOfPackages,
	|	InventoryKinds.Count AS Count,
	|	InventoryKinds.QuantityByGBRN AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	
	|	ISNULL(
	|		AmountsCompl.AmountExcludingVATCompl,
	|		InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount
	|	) AS AmountExcludingVAT,
	|	
	|	InventoryKinds.VATRate AS VATRate,
	|	
	|	ISNULL(
	|		AmountsCompl.VATAmountCompl,
	|		InventoryKinds.VATAmount
	|	) AS VATAmount,
	|	
	|	InventoryKinds.MaterialProviderOrder AS SalesOrder,
	|
	|	InventoryKinds.ExpenseItem AS ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses AS DimensionOfExpenses,
	|	InventoryKinds.ToExpenseAs AS ToExpenseAs,
	|	InventoryKinds.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension
	|
	|FROM
	|	Document.ReportToMaterialProvider2_5.InventoryKinds AS InventoryKinds
	|	INNER JOIN TTRelatedDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Subordinated
	|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS AmountsCompl
	|		ON InventoryKinds.Ref = AmountsCompl.Recorder
	|			AND InventoryKinds.RowID = AmountsCompl.RowID
	|			AND AmountsCompl.Active
	|			AND &ConvertToLocalCurrency
	|WHERE
	|	&IncludingBeforeAdjustment
	|
	|UNION ALL
	|
	|SELECT
	|	RelatedDocuments.Main AS Ref,
	|	FALSE AS BeforeAdjustment,
	|	InventoryKinds.LineNumber AS LineNumber,
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension AS SetAccountingDimension,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)  AS Package,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	VALUE(Catalog.FEACN.EmptyRef)        AS FEACNCode,
	|	InventoryKinds.Count AS NumberOfPackages,
	|	InventoryKinds.Count AS Count,
	|	InventoryKinds.QuantityByGBRN AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	
	|	ISNULL(
	|		AmountsCompl.AmountExcludingVATCompl,
	|		InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount
	|	) AS AmountExcludingVAT,
	|	
	|	InventoryKinds.VATRate AS VATRate,
	|	
	|	ISNULL(
	|		AmountsCompl.VATAmountCompl,
	|		InventoryKinds.VATAmount
	|	) AS VATAmount,
	|	
	|	InventoryKinds.SalesOrder AS SalesOrder,
	|
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	FALSE 		 AS ToExpenseAs,
	|	UNDEFINED AS AssetsLiabilitiesDimension
	|
	|FROM
	|	Document.CustomerInvoiceServices.InventoryKinds AS InventoryKinds
	|	INNER JOIN TTRelatedDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Subordinated
	|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS AmountsCompl
	|		ON InventoryKinds.Ref = AmountsCompl.Recorder
	|			AND InventoryKinds.RowID = AmountsCompl.RowID
	|			AND AmountsCompl.Active
	|			AND &ConvertToLocalCurrency
	|
	|UNION ALL
	|
	|SELECT
	|	RelatedDocuments.Main AS Ref,
	|	TRUE AS BeforeAdjustment,
	|	InventoryKinds.LineNumber AS LineNumber,
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension AS SetAccountingDimension,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)  AS Package,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	VALUE(Catalog.FEACN.EmptyRef)        AS FEACNCode,
	|	InventoryKinds.Count AS NumberOfPackages,
	|	InventoryKinds.Count AS Count,
	|	InventoryKinds.QuantityByGBRN AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	
	|	ISNULL(
	|		AmountsCompl.AmountExcludingVATCompl,
	|		InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount
	|	) AS AmountExcludingVAT,
	|	
	|	InventoryKinds.VATRate AS VATRate,
	|	
	|	ISNULL(
	|		AmountsCompl.VATAmountCompl,
	|		InventoryKinds.VATAmount
	|	) AS VATAmount,
	|	
	|	InventoryKinds.SalesOrder AS SalesOrder,
	|
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	FALSE 		 AS ToExpenseAs,
	|	UNDEFINED AS AssetsLiabilitiesDimension
	|
	|FROM
	|	Document.CustomerInvoiceServices.InventoryKinds AS InventoryKinds
	|	INNER JOIN TTRelatedDocuments AS RelatedDocuments
	|		ON InventoryKinds.Ref = RelatedDocuments.Subordinated
	|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS AmountsCompl
	|		ON InventoryKinds.Ref = AmountsCompl.Recorder
	|			AND InventoryKinds.RowID = AmountsCompl.RowID
	|			AND AmountsCompl.Active
	|			AND &ConvertToLocalCurrency
	|WHERE
	|	&IncludingBeforeAdjustment
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllKindsOfStocks.Ref                                        AS Ref,
	|	AllKindsOfStocks.Ref.DocumentBasis                      AS DocumentBasis,
	|	CASE
	|		WHEN AllKindsOfStocks.Ref.DocumentBasis REFS Document.SourceDocument
	|			THEN FALSE
	|		ELSE ISNULL(AllKindsOfStocks.Ref.DocumentBasis.ToReturnReusablePackage, FALSE)
	|	END                                                        AS ToReturnReusablePackage,
	|	AllKindsOfStocks.BeforeAdjustment                               AS BeforeAdjustment,
	|	MAX(AllKindsOfStocks.LineNumber)                         AS LineNumber,
	|	AllKindsOfStocks.ItemsLocationAttributes                    AS ItemsLocationAttributes,
	|	ISNULL(InventoryLocationAttributeKeys.Products,
	|		VALUE(Catalog.Products.EmptyRef)) 		 AS Products,
	|	AllKindsOfStocks.SetAccountingDimension                         AS SetAccountingDimension,
	|	AllKindsOfStocks.Package                                      AS Package,
	|	AllKindsOfStocks.CCDNumber                                      AS CCDNumber,
	|	AllKindsOfStocks.FEACNCode                                      AS FEACNCode,
	|	AllKindsOfStocks.InventoryOwnerAttribute                                    AS InventoryOwnerAttribute,
	|	SUM(AllKindsOfStocks.NumberOfPackages)                     AS NumberOfPackages,
	|	SUM(AllKindsOfStocks.Count)                             AS Count,
	|	SUM(AllKindsOfStocks.QuantityByGBRN)                       AS QuantityByGBRN,
	|	SUM(AllKindsOfStocks.AmountExcludingVAT)                            AS AmountExcludingVAT,
	|	AllKindsOfStocks.VATRate                                     AS VATRate,
	|	SUM(AllKindsOfStocks.VATAmount)                               AS VATAmount,
	|	SUM(AllKindsOfStocks.AmountExcludingVAT + AllKindsOfStocks.VATAmount)  AS AmountIncludingVAT,
	|	SUM(AllKindsOfStocks.ExciseTaxAmount)                            AS ExciseTaxAmount,
	|
	|	AllKindsOfStocks.ExpenseItem                                AS ExpenseItem,
	|	AllKindsOfStocks.DimensionOfExpenses                             AS DimensionOfExpenses,
	|	AllKindsOfStocks.ToExpenseAs 							 AS ToExpenseAs,
	|	AllKindsOfStocks.AssetsLiabilitiesDimension                      AS AssetsLiabilitiesDimension
	|
	|INTO TTTypesOfStocks
	|FROM
	|	AllKindsOfStocks AS AllKindsOfStocks
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		ON AllKindsOfStocks.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|
	|GROUP BY
	|	AllKindsOfStocks.Ref,
	|	AllKindsOfStocks.Ref.DocumentBasis,
	|	CASE
	|		WHEN AllKindsOfStocks.Ref.DocumentBasis REFS Document.SourceDocument
	|			THEN FALSE
	|		ELSE ISNULL(AllKindsOfStocks.Ref.DocumentBasis.ToReturnReusablePackage, FALSE)
	|	END,
	|	AllKindsOfStocks.BeforeAdjustment,
	|	AllKindsOfStocks.ItemsLocationAttributes,
	|	ISNULL(InventoryLocationAttributeKeys.Products, VALUE(Catalog.Products.EmptyRef)),
	|	AllKindsOfStocks.SetAccountingDimension,
	|	AllKindsOfStocks.Package,
	|	AllKindsOfStocks.CCDNumber,
	|	AllKindsOfStocks.FEACNCode,
	|	AllKindsOfStocks.InventoryOwnerAttribute,
	|	AllKindsOfStocks.VATRate,
	|	AllKindsOfStocks.ExpenseItem,
	|	AllKindsOfStocks.DimensionOfExpenses,
	|	AllKindsOfStocks.ToExpenseAs,
	|	AllKindsOfStocks.AssetsLiabilitiesDimension
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP AllKindsOfStocks
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTAdjustmentDataBeforeEnteringBalances
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	QueryText = QueryTextForAdjustmentDataBeforeEnteringBalances() + TMCommonUse.RequestSeparatorInPacket_() + QueryText;
	
	Return QueryText;
	
EndFunction

Procedure SetTTStockOptions(Query, ConvertToLocalCurrency, IncludingBeforeAdjustment, BasisOfUnrecordedDocument = Undefined) Export
	
	Query.SetParameter("ConvertToLocalCurrency",        ConvertToLocalCurrency);
	Query.SetParameter("IncludingBeforeAdjustment",          IncludingBeforeAdjustment);
	Query.SetParameter("BasisOfUnrecordedDocument", BasisOfUnrecordedDocument);
	
	GenerateTTAmountsOfDocumentInAccountingCurrencies(Query);
	
EndProcedure

// Returns the data required for the printed form "Act of rendering services".
// 
// Parameters:
// 	PrintParameters - Structure - advanced print settings
// 	ObjectsArray  - Array    - references to objects that should be printed
// 	
// Returns:
// 	Structure - Contains data on the header of the document, the tabular part:
// 	* HeaderResults          - QueryResult - 
// 	* ResultForTabularPart - QueryResult - 
//
Function GetDataForPrintedServiceDeliveryReportForm(PrintParameters, ObjectsArray) Export
	
	Query = New Query("SELECT
	|	SaleAdjustment.Ref AS Ref,
	|	CASE
	|		WHEN OtherImplementation.Ref IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS AdjustmentOfOtherSales
	|INTO AdjustmentData
	|FROM
	|	Document.SaleAdjustment AS SaleAdjustment
	|		LEFT JOIN Document.CustomerInvoiceServicesAndAssets AS OtherImplementation
	|		ON SaleAdjustment.DocumentBasis = OtherImplementation.Ref
	|WHERE
	|	SaleAdjustment.Ref IN(&DocumentsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SaleAdjustment.Ref AS Ref,
	|	SaleAdjustment.DocumentBasis.Number AS Number,
	|	SaleAdjustment.DocumentBasis.Date AS Date,
	|	SaleAdjustment.Partner AS Partner,
	|	SaleAdjustment.Counterparty AS Counterparty,
	|	SaleAdjustment.Organization AS Organization,
	|	SaleAdjustment.Organization.Prefix AS Prefix,
	|	SaleAdjustment.Currency AS Currency,
	|	SaleAdjustment.PriceIncludesVAT AS PriceIncludesVAT,
	|	CASE
	|		WHEN SaleAdjustment.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR SaleAdjustment.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	SaleAdjustment.Warehouse.CurrentEmployeeInChargeTypes.Description AS VacationProduced
	|FROM
	|	Document.SaleAdjustment AS SaleAdjustment
	|WHERE
	|	SaleAdjustment.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.Products AS Products,
	|	Table.Content AS Content,
	|	0 AS DiscountPercentage,
	|	Table.Characteristic AS Characteristic,
	|	Table.Package AS Package,
	|	Table.VATRate AS VATRate,
	|	Table.Price AS Price,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	Table.Sum AS Sum,
	|	0 AS DiscountAmount,
	|	Table.Sum AS AmountWithoutADiscount,
	|	Table.VATAmount AS VATAmount,
	|	Table.LineNumber AS LineNumber
	|INTO Goods
	|FROM
	|	Document.SaleAdjustment.Goods AS Table
	|		INNER JOIN AdjustmentData AS AdjustmentData
	|		ON Table.Ref = AdjustmentData.Ref
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON (ProductKitConfigurations.Owner = Table.ProductsInSet)
	|			AND (ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet)
	|			AND (ProductKitConfigurations.Main)
	|WHERE
	|	Table.Ref IN(&DocumentsArray)
	|	AND (Table.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|		OR (Table.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND NOT Table.Products.TracedGoods))
	|	AND NOT AdjustmentData.AdjustmentOfOtherSales
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	MIN(Table.LineNumber) AS LineNumber,
	|	SUM(Table.Sum) AS Sum,
	|	SUM(Table.VATAmount) AS VATAmount,
	|	SUM(Table.DiscountAmount) AS DiscountAmount,
	|	SUM(Table.AmountWithoutADiscount) AS AmountWithoutADiscount
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|WHERE
	|	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref
	|INTO VariousGoods_
	|FROM
	|	Goods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
	|	Goods.ItemKitConfiguration AS ItemKitConfiguration,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption AS SetPricingOption,
	|	Goods.ProductsInSet AS ProductsInSet,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	CASE
	|		WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|				AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS MainComponent,
	|	0 AS DefaultQuantity,
	|	Goods.Count AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	VariousGoods_.Ref,
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	FALSE,
	|	SUM(ConfigurationOptionsForProductRange.Count),
	|	0
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|		LEFT JOIN VariousGoods_ AS VariousGoods_
	|		ON (TRUE)
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN
	|			(SELECT
	|				T.ItemKitConfiguration
	|			FROM
	|				Goods AS T)
	|
	|GROUP BY
	|	VariousGoods_.Ref,
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	ConfigurationOptionsForProductRange.Package,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|	Table.ItemKitConfiguration AS ItemKitConfiguration,
	|	Table.SetPricingOption AS SetPricingOption,
	|	Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	MAX(Table.MainComponent) AS MainComponent,
	|	SUM(Table.DefaultQuantity) AS DefaultQuantity,
	|	SUM(Table.Count) AS Count
	|INTO TemporaryTableSetsOptionalPartTwo
	|FROM
	|	TemporaryTableSetsOptionalPartOne AS Table
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Result.Ref AS Ref,
	|	Result.ItemKitConfiguration AS ItemKitConfiguration,
	|	Result.SetPricingOption AS SetPricingOption,
	|	Result.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Result.ProductsInSet AS ProductsInSet,
	|	Result.ItemVariantOfSet AS ItemVariantOfSet,
	|	(CAST(MIN(CASE
	|				WHEN Result.DefaultQuantity <> 0
	|						AND Result.MainComponent
	|					THEN Result.Count / Result.DefaultQuantity
	|				ELSE NULL
	|			END) + 0.5 AS NUMBER(10, 0))) - 1 AS Count
	|INTO TemporaryTableSetsOptional
	|FROM
	|	TemporaryTableSetsOptionalPartTwo AS Result
	|
	|GROUP BY
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableSetsOptional.ItemKitConfiguration AS ItemKitConfiguration,
	|	TemporaryTableSetsOptional.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	TemporaryTableSetsOptional.SetPricingOption AS SetPricingOption,
	|	Table.Ref AS Ref,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.LineNumber AS LineNumber,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	Table.Sum AS Sum,
	|	Table.VATAmount AS VATAmount,
	|	Table.DiscountAmount AS DiscountAmount,
	|	Table.AmountWithoutADiscount AS AmountWithoutADiscount
	|INTO TemporaryTableSets
	|FROM
	|	TemporaryTableSetsPreparation AS Table
	|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	|		ON Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	|			AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	|			AND Table.Ref = TemporaryTableSetsOptional.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption AS SetPricingOption,
	|	Goods.ProductsInSet AS ProductsInSet,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|	Goods.IsRecordsSet AS IsRecordsSet,
	|	Goods.TheseAreComponents AS TheseAreComponents,
	|	Goods.Products AS Products,
	|	CASE
	|		WHEN
	|			Goods.Content = """"
	|		THEN
	|			Goods.Products.DescriptionFull
	|		ELSE
	|			Goods.Content
	|	END AS ServiceNameFull,
	|	Goods.Products.Code AS Code,
	|	Goods.Products.SKU AS SKU,
	|	&QueryTextUnitOfMeasurementName AS UnitPrice,
	|	&QueryTextUnitOfMeasureLink AS UnitOfMeasure,
	|	&QueryTextUnitOfMeasurementName AS UnitOfMeasurementName,
	|	&QueryTextUnitOfMeasureCode AS UnitOfMeasureCode,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Characteristic.DescriptionFull AS CharacteristicFullName,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE Goods.Package.Description
	|	END AS PackagingName_,
	|	Goods.VATRate AS VATRate,
	|	Goods.Price AS Price,
	|	Goods.NumberOfPackages AS Count,
	|	Goods.Sum AS Sum,
	|	Goods.VATAmount AS VATAmount,
	|	Goods.DiscountAmount AS DiscountAmount,
	|	Goods.AmountWithoutADiscount AS AmountWithoutADiscount,
	|	Goods.LineNumber AS LineNumber,
	|	FALSE AS ThisIsReusablePackage
	|FROM
	|	(SELECT
	|		Table.Ref AS Ref,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.PresentationOptionInPrintForms
	|			ELSE VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	|		END AS PresentationOptionInPrintForms,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.SetPricingOption
	|			ELSE VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		END AS SetPricingOption,
	|		Table.ProductsInSet AS ProductsInSet,
	|		Table.ItemVariantOfSet AS ItemVariantOfSet,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS TheseAreComponents,
	|		FALSE AS IsRecordsSet,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.LineNumber
	|			ELSE Table.LineNumber
	|		END AS LineNumber,
	|		Table.Products AS Products,
	|		Table.Content AS Content,
	|		Table.Count AS Count,
	|		Table.NumberOfPackages AS NumberOfPackages,
	|		Table.Price AS Price,
	|		Table.Sum AS Sum,
	|		Table.VATRate AS VATRate,
	|		Table.VATAmount AS VATAmount,
	|		Table.Characteristic AS Characteristic,
	|		Table.Package AS Package,
	|		Table.DiscountAmount AS DiscountAmount,
	|		Table.AmountWithoutADiscount AS AmountWithoutADiscount
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
	|			ON (TemporaryTableSets.ProductsInSet = Table.ProductsInSet)
	|				AND (TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet)
	|				AND (TemporaryTableSets.Ref = Table.Ref)
	|	WHERE
	|		(Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|				OR Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|					AND TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents), VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TemporaryTableSets.Ref,
	|		TemporaryTableSets.PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		FALSE,
	|		TRUE,
	|		TemporaryTableSets.LineNumber,
	|		TemporaryTableSets.ProductsInSet,
	|		"""" AS Content,
	|		TemporaryTableSets.Count,
	|		TemporaryTableSets.NumberOfPackages,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0
	|				THEN TemporaryTableSets.Sum / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|			ELSE 0
	|		END,
	|		TemporaryTableSets.Sum,
	|		TemporaryTableSets.ProductsInSet.VATRate,
	|		TemporaryTableSets.VATAmount,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
	|		TemporaryTableSets.DiscountAmount,
	|		TemporaryTableSets.AmountWithoutADiscount
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet), VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))) AS Goods
	|
	|UNION ALL
	|
	|SELECT
	|	SaleAdjustment.Ref,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	FALSE,
	|	FALSE,
	|	UNDEFINED,
	|	SaleAdjustment.Content,
	|	"""",
	|	"""",
	|	"""",
	|	UNDEFINED,
	|	"""",
	|	"""",
	|	UNDEFINED,
	|	"""",
	|	"""",
	|	SaleAdjustment.VATRate,
	|	SaleAdjustment.Price,
	|	SaleAdjustment.Count,
	|	SaleAdjustment.Sum,
	|	SaleAdjustment.VATAmount,
	|	0,
	|	SaleAdjustment.Sum,
	|	SaleAdjustment.LineNumber,
	|	FALSE
	|FROM
	|	Document.SaleAdjustment.Goods AS SaleAdjustment
	|		INNER JOIN AdjustmentData AS AdjustmentData
	|		ON SaleAdjustment.Ref = AdjustmentData.Ref
	|WHERE
	|	SaleAdjustment.Ref IN(&DocumentsArray)
	|	AND AdjustmentData.AdjustmentOfOtherSales
	|
	|ORDER BY
	|	LineNumber,
	|	IsRecordsSet DESC
	|TOTALS
	|	SUM(DiscountAmount)
	|BY
	|	Ref");
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
		
	Query.Text = StrReplace(
		Query.Text,
		"&QueryTextUnitOfMeasureLink",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"Goods.Package",
			"Goods.Products"));
		
	Query.Text = StrReplace(
		Query.Text,
		"&QueryTextUnitOfMeasurementName",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Description",
			"Goods.Package",
			"Goods.Products"));
		
	Query.Text = StrReplace(
		Query.Text,
		"&QueryTextUnitOfMeasureCode",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Code",
			"Goods.Package",
			"Goods.Products"));
		
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	ResultsArray = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", ResultsArray[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart", ResultsArray[ResultsArray.Count() - 1]);
	
	Return DataStructureForPrinting;
	
EndFunction

// The function receives data for generating the ED " agreement on cost changes"
//
// Parameters:
//	PrintParameters - Structure
//	ObjectsArray - Array - An array of references to documents, which is necessary to obtain the data.
//
// Returns:
// 	Structure:
// 		* HeaderResults - QueryResult
// 		* ResultForTabularPart - QueryResult
// 		* DocumentTitle - String
//
Function GetDataForPrintedFormChangeOfValueAgreement(PrintParameters, ObjectsArray) Export

	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms().ColumnName;
	If Not ValueIsFilled(ColumnOfCodes) Then
		ColumnOfCodes = "Code";
	EndIf;
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = "
	|SELECT
	|	DocumentsData.Ref AS Ref,
	|	DocumentsData.Currency AS Currency,
	|	DocumentsData.AdjustmentKind AS BusinessOperation,
	|	DocumentsData.AdjustingEntryType AS AdjustingEntryType,
	|	DocumentsData.Organization AS Organization
	|
	|INTO DocumentDataTable_
	|FROM
	|	Document.SaleAdjustment AS DocumentsData
	|
	|WHERE
	|	DocumentsData.Ref IN (&ObjectsArray)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsData.Ref AS DocumentBasis,
	|	FALSE AS Corrective
	|
	|INTO BasisInvoices
	|FROM
	|	DocumentDataTable_ AS DocumentsData
	|
	|INDEX BY
	|	Ref
	|;";
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	Query.Execute();
	
	FillParameters = SalesServer.ParametersForFillingInTemporaryProductTable();
	FillParameters.IncludingBeforeAdjustment = True;
	If PrintParameters.Property("WithdrawCCD") Then
		FillParameters.IncludingCCDNumbers = PrintParameters.WithdrawCCD;
	EndIf;
	PlaceTemporaryTableOfGoodsForValueChangeAgreements(TempTablesManager, FillParameters);
	
	Query.Text = 
	"SELECT DISTINCT
	|	TableOfGoods.Products,
	|	TableOfGoods.Package AS Package,
	|	MIN(CASE
	|			WHEN ProductPackages.Ref IS NULL 
	|				THEN 1
	|			ELSE &QueryTextPackagingFactor1
	|		END) AS ZoomRatio
	|INTO Packages
	|FROM
	|	AdjustmentOfSalesTableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON (ProductPackages.Parent = TableOfGoods.Package)
	|			AND (ProductPackages.Owner = TableOfGoods.Products)
	|WHERE
	|	NOT ProductPackages.DeletionMark
	|
	|GROUP BY
	|	TableOfGoods.Products,
	|	TableOfGoods.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Packages.Products,
	|	Packages.Package AS Package,
	|	&QueryTextPackagingFactor2 AS PackagingFactor,
	|	MIN(ProductPackages.Ref) AS NestedPackaging,
	|	MIN(&QueryTextPackagingFactor3) AS NestedPackingRatio
	|INTO NestedPackages
	|FROM
	|	Packages AS Packages
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON Packages.Products = ProductPackages.Owner
	|			AND Packages.ZoomRatio = &QueryTextPackagingFactor3
	|WHERE
	|	ProductPackages.Parent = Packages.Package
	|
	|GROUP BY
	|	Packages.Products,
	|	Packages.Package,
	|	&QueryTextPackagingFactor2
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Ref,
	|	TableOfGoods.LineNumber,
	|	TableOfGoods.Content,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Package,
	|	TableOfGoods.CCDNumber,
	|	TableOfGoods.Count,
	|	TableOfGoods.NumberOfPackages,
	|	TableOfGoods.AmountExcludingVAT,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.VATAmount,
	|	TableOfGoods.ThisIsAProduct,
	|	TableOfGoods.BeforeAdjustment,
	|	CASE
	|		WHEN NestedPackages.NestedPackaging IS NULL 
	|			THEN CASE
	|					WHEN TableOfGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|						THEN 1
	|					ELSE &QueryTextPackagingFactor4
	|				END
	|		ELSE NestedPackages.PackagingFactor
	|	END AS PackagingFactor,
	|	CASE
	|		WHEN NestedPackages.NestedPackaging IS NULL 
	|			THEN CASE
	|					WHEN TableOfGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|						THEN 1
	|					ELSE &QueryTextPackagingFactor4
	|				END
	|		ELSE NestedPackages.NestedPackingRatio
	|	END AS NestedPackingRatio,
	|	CASE
	|		WHEN NestedPackages.NestedPackaging IS NULL 
	|			THEN CASE
	|					WHEN TableOfGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|						THEN TableOfGoods.Products.UnitOfMeasure
	|					ELSE TableOfGoods.Package
	|				END
	|		ELSE NestedPackages.NestedPackaging
	|	END AS PackageKind,
	|	TableOfGoods.Ref AS Ref
	|INTO TableOfGoodsWithPackageCoefficients
	|FROM
	|	AdjustmentOfSalesTableOfGoods AS TableOfGoods
	|		LEFT JOIN NestedPackages AS NestedPackages
	|		ON TableOfGoods.Products = NestedPackages.Products
	|			AND TableOfGoods.Package = NestedPackages.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP Packages
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|DROP NestedPackages
	|;";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ProductPackages",
		"TableOfGoods.Products"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Packages.Package",
		"Packages.Products"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor3",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ProductPackages",
		"Packages.Products"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor4",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"TableOfGoods.Package",
		"TableOfGoods.Products"));
				
	Query.Execute();
	
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(ObjectsArray, TempTablesManager);
	
	Query.Text = "
	|////////////////////////////////////////////////////////////////////////////
	|// REQUEST BY HEADER
	|
	|SELECT
	|	SaleAdjustment.Ref                                                 AS Ref,
	|	SaleAdjustment.DocumentBasis                                      AS DocumentBasis,
	|	SaleAdjustment.Number                                                  AS Number,
	|	SaleAdjustment.Date                                                   AS Date,
	|	SaleAdjustment.Partner                                                AS Partner,
	|	SaleAdjustment.Counterparty                                             AS Counterparty,
	|	SaleAdjustment.Organization                                            AS Organization,
	|	TableResponsiblePersons.DirectorDescription                              AS Director,
	|	TableResponsiblePersons.DirectorJobTitle                                 AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription                          AS ChiefAccountant,
	|	SaleAdjustment.IssuiedBy.Description                                  AS Warehouseman,
	|	SaleAdjustment.IssuiedByJobTitle                                      AS StorekeeperPosition,
	|	SaleAdjustment.Organization.Prefix                                    AS Prefix,
	|	SaleAdjustment.Basis                                              AS Basis,
	|
	|	CASE WHEN SaleAdjustment.GoodsRecipient = VALUE(Catalog.Counterparties.EmptyRef) THEN
	|		SaleAdjustment.Counterparty
	|	ELSE
	|		SaleAdjustment.GoodsRecipient
	|	END AS GoodsRecipient,
	|
	|	CASE WHEN SaleAdjustment.Shipper = VALUE(Catalog.Counterparties.EmptyRef) THEN
	|		SaleAdjustment.Organization
	|	ELSE
	|		SaleAdjustment.Shipper
	|	END AS Shipper,
	|
	|	SaleAdjustment.CompanyBankAccount                             AS CompanyBankAccount,
	|	SaleAdjustment.CounterpartyBankAccount                             AS CounterpartyBankAccount,
	|	SaleAdjustment.ShipperBankAccount                        AS ShipperBankAccount,
	|	SaleAdjustment.GoodsRecipientBankAccount                         AS GoodsRecipientBankAccount,
	|	SaleAdjustment.DeliveryAddress                                         AS DeliveryAddress,
	|	UNDEFINED                                                                  AS Department,
	|	SaleAdjustment.Currency                                                AS Currency,
	|	SaleAdjustment.PowerOfAttorneyNumber                                     AS PowerOfAttorneyNumber,
	|	SaleAdjustment.PowerOfAttorneyDate                                      AS PowerOfAttorneyDate,
	|	SaleAdjustment.LetterOfAuthorityIssuedBy                                    AS LetterOfAuthorityIssuedBy,
	|	SaleAdjustment.PowerOfAttorneyPerson                                      AS PowerOfAttorneyPerson,
	|	&UnitOfMeasureForWeight                                                         AS UnitOfMeasureForWeight
	|
	|FROM
	|	Document.SaleAdjustment AS SaleAdjustment
	|
	|		INNER JOIN
	|			DocumentDataTable_ AS DocumentsData
	|		ON
	|			SaleAdjustment.Ref = DocumentsData.Ref
	|		
	|		LEFT JOIN 
	|			TableResponsiblePersons AS TableResponsiblePersons
	|		ON 
	|			SaleAdjustment.Ref = TableResponsiblePersons.Ref
	|	
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////
	|// QUERY BY TABLE PARTS
	|
	|SELECT
	|	NestedQuery.Ref,
	|	NestedQuery.Products,
	|	NestedQuery.ItemName,
	|	NestedQuery.ProductsCode,
	|	NestedQuery.UnitOfMeasure,
	|	NestedQuery.UnitOfMeasurementName,
	|	NestedQuery.UnitOfMeasureCode,
	|	NestedQuery.Characteristic,
	|	NestedQuery.ItemVariantName,
	|	NestedQuery.Package,
	|	NestedQuery.PackagingName_,
	|	NestedQuery.PackageKind,
	|	NestedQuery.VATRate,
	|	NestedQuery.CCDNumber,
	|	NestedQuery.OriginCountry,
	|	SUM(NestedQuery.Count)                           AS Count,
	|	SUM(NestedQuery.QuantityBeforeAdjustment)            AS QuantityBeforeAdjustment,
	|	SUM(NestedQuery.NumberOfSeats)                       AS NumberOfSeats,
	|	SUM(NestedQuery.NumberOfSeatsBeforeAdjustment)        AS NumberOfSeatsBeforeAdjustment,
	|	SUM(NestedQuery.QuantityInOnePlace)                AS QuantityInOnePlace,
	|	SUM(NestedQuery.QuantityInOnePlaceBeforeAdjustment) AS QuantityInOnePlaceBeforeAdjustment,
	|	SUM(NestedQuery.Price)                                 AS Price,
	|	SUM(NestedQuery.PriceBeforeAdjustment)                  AS PriceBeforeAdjustment,
	|	SUM(NestedQuery.AmountExcludingVAT)                          AS AmountExcludingVAT,
	|	SUM(NestedQuery.AmountExcludingVATBeforeAdjustment)           AS AmountExcludingVATBeforeAdjustment,
	|	SUM(NestedQuery.AmountIncludingVAT)                            AS AmountIncludingVAT,
	|	SUM(NestedQuery.AmountWithVATBeforeAdjustment)             AS AmountWithVATBeforeAdjustment,
	|	SUM(NestedQuery.VATAmount)                             AS VATAmount,
	|	SUM(NestedQuery.AmountOfVATBeforeAdjustment)              AS AmountOfVATBeforeAdjustment,
	|	SUM(NestedQuery.NetWeight)                           AS NetWeight,
	|	SUM(NestedQuery.NetWeightBeforeAdjustment)            AS NetWeightBeforeAdjustment,
	|	SUM(NestedQuery.GrossWeight)                          AS GrossWeight,
	|	SUM(NestedQuery.GrossWeightBeforeAdjustment)           AS GrossWeightBeforeAdjustment,
	|	MAX(NestedQuery.LineNumber)                       AS LineNumber,
	|	NestedQuery.ThisIsReusablePackage
	|
	|FROM
	|	(SELECT
	|		TableOfGoods.Ref                                       AS Ref,
	|		TableOfGoods.Products                                 AS Products,
	|		TableOfGoods.Products.DescriptionFull              AS ItemName,
	|		
	|		CASE WHEN &ColumnOfCodes = ""SKU"" THEN
	|			TableOfGoods.Products.SKU
	|		ELSE
	|			TableOfGoods.Products.Code
	|		END                                                       AS ProductsCode,
	|		
	|		CASE WHEN &DisplayBasicUnitsOfMeasureInPrintForms THEN
	|			TableOfGoods.Products.UnitOfMeasure
	|		ELSE
	|			&QueryTextUnitOfMeasure
	|		END                                                       AS UnitOfMeasure,
	|		
	|		CASE WHEN &DisplayBasicUnitsOfMeasureInPrintForms THEN
	|			TableOfGoods.Products.UnitOfMeasure.Description
	|		ELSE
	|			&QueryTextUnitOfMeasureDescription1
	|		END                                                       AS UnitOfMeasurementName,
	|		
	|		CASE WHEN &DisplayBasicUnitsOfMeasureInPrintForms THEN
	|			TableOfGoods.Products.UnitOfMeasure.Code
	|		ELSE
	|			&QueryTextUnitCode
	|		END                                                       AS UnitOfMeasureCode,
	|		
	|		TableOfGoods.Characteristic                               AS Characteristic,
	|		TableOfGoods.Characteristic.DescriptionFull            AS ItemVariantName,
	|		TableOfGoods.Package                                     AS Package,
	|		
	|		CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|			""""
	|		ELSE
	|			TableOfGoods.Package.Description
	|		END                                                       AS PackagingName_,
	|		
	|		CASE WHEN TableOfGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) THEN
	|			TableOfGoods.Products.UnitOfMeasure.Description
	|		ELSE
	|			CASE WHEN &DisplayBasicUnitsOfMeasureInPrintForms THEN
	|				&QueryTextUnitOfMeasureDescription1
	|			ELSE
	|				&QueryTextUnitOfMeasureDescription2
	|			END
	|		END                                                       AS PackageKind,
	|		
	|		TableOfGoods.VATRate                                    AS VATRate,
	|		TableOfGoods.CCDNumber                                     AS CCDNumber,
	|		TableOfGoods.CCDNumber.OriginCountry                 AS OriginCountry,
	|		
	|		CASE WHEN NOT &DisplayBasicUnitsOfMeasureInPrintForms THEN
	|			TableOfGoods.NumberOfPackages
	|		ELSE
	|			TableOfGoods.Count
	|		END                                                       AS Count,
	|		0                                                           AS QuantityBeforeAdjustment,
	|		CASE WHEN &DisplayBasicUnitsOfMeasureInPrintForms THEN
	|			TableOfGoods.NumberOfPackages
	|		ELSE
	|			TableOfGoods.Count / TableOfGoods.NestedPackingRatio
	|		END                                                       AS NumberOfSeats,
	|		0                                                           AS NumberOfSeatsBeforeAdjustment,
	|		CASE WHEN NOT &DisplayBasicUnitsOfMeasureInPrintForms THEN
	|			CASE WHEN TableOfGoods.Count < TableOfGoods.NestedPackingRatio THEN
	|				TableOfGoods.Count
	|			ELSE
	|				TableOfGoods.NestedPackingRatio
	|			END
	|		ELSE
	|			CASE WHEN TableOfGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) THEN
	|				1
	|			ELSE
	|				&QueryTextPackagingFactor
	|			END
	|		END                                                       AS QuantityInOnePlace,
	|		0                                                           AS QuantityInOnePlaceBeforeAdjustment,
	|		
	|		CASE WHEN NOT &DisplayBasicUnitsOfMeasureInPrintForms THEN
	|			TableOfGoods.AmountExcludingVAT / TableOfGoods.NumberOfPackages
	|		ELSE
	|			TableOfGoods.AmountExcludingVAT / TableOfGoods.Count
	|		END                                                       AS Price,
	|		0                                                           AS PriceBeforeAdjustment,
	|		
	|		TableOfGoods.AmountExcludingVAT                                  AS AmountExcludingVAT,
	|		0                                                           AS AmountExcludingVATBeforeAdjustment,
	|		
	|		TableOfGoods.VATAmount                                     AS VATAmount,
	|		0                                                           AS AmountOfVATBeforeAdjustment,
	|		
	|		TableOfGoods.AmountExcludingVAT + TableOfGoods.VATAmount        AS AmountIncludingVAT,
	|		0                                                           AS AmountWithVATBeforeAdjustment,
	|		
	|		TableOfGoods.Count * &QueryTextWeight AS NetWeight,
	|		0                                                           AS NetWeightBeforeAdjustment,
	|		
	|		CASE WHEN &WeightUnitFilledIn THEN
	|			CASE WHEN TableOfGoods.Package.Weight IS NULL THEN
	|				TableOfGoods.Count * &QueryTextWeight1
	|			ELSE
	|				TableOfGoods.NumberOfPackages * &QueryTextWeight1
	|			END
	|		ELSE
	|			0
	|		END                                                       AS GrossWeight,
	|		0                                                           AS GrossWeightBeforeAdjustment,
	|		TableOfGoods.LineNumber                                  AS LineNumber,
	|		FALSE                                                        AS ThisIsReusablePackage
	|	
	|	FROM
	|		TableOfGoodsWithPackageCoefficients AS TableOfGoods
	|		
	|	WHERE
	|		NOT TableOfGoods.BeforeAdjustment
	|		AND (TableOfGoods.ThisIsAProduct OR &WithdrawServices)
	|		
	|	UNION ALL
	|		
	|	SELECT
	|		TableOfGoods.Ref,
	|		TableOfGoods.Products,
	|		TableOfGoods.Products.DescriptionFull,
	|		
	|		CASE WHEN &ColumnOfCodes = ""SKU"" THEN
	|			TableOfGoods.Products.SKU
	|		ELSE
	|			TableOfGoods.Products.Code
	|		END,
	|		
	|		CASE WHEN &DisplayBasicUnitsOfMeasureInPrintForms THEN
	|			TableOfGoods.Products.UnitOfMeasure
	|		ELSE
	|			&QueryTextUnitOfMeasure
	|		END,
	|		
	|		CASE WHEN &DisplayBasicUnitsOfMeasureInPrintForms THEN
	|			TableOfGoods.Products.UnitOfMeasure.Description
	|		ELSE
	|			&QueryTextUnitOfMeasureDescription1
	|		END,
	|		
	|		CASE WHEN &DisplayBasicUnitsOfMeasureInPrintForms THEN
	|			TableOfGoods.Products.UnitOfMeasure.Code
	|		ELSE
	|			&QueryTextUnitCode
	|		END,
	|		
	|		TableOfGoods.Characteristic,
	|		TableOfGoods.Characteristic.DescriptionFull,
	|		TableOfGoods.Package,
	|		
	|		CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|			""""
	|		ELSE
	|			TableOfGoods.Package.Description
	|		END,
	|		
	|		CASE WHEN TableOfGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) THEN
	|			TableOfGoods.Products.UnitOfMeasure.Description
	|		ELSE
	|			CASE WHEN &DisplayBasicUnitsOfMeasureInPrintForms THEN
	|				&QueryTextUnitOfMeasureDescription1
	|			ELSE
	|				&QueryTextUnitOfMeasureDescription2
	|			END
	|		END,
	|		
	|		TableOfGoods.VATRate,
	|		TableOfGoods.CCDNumber,
	|		TableOfGoods.CCDNumber.OriginCountry,
	|		
	|		0,
	|		CASE WHEN NOT &DisplayBasicUnitsOfMeasureInPrintForms THEN
	|			TableOfGoods.NumberOfPackages
	|		ELSE
	|			TableOfGoods.Count
	|		END,
	|		
	|		0,
	|		CASE WHEN &DisplayBasicUnitsOfMeasureInPrintForms THEN
	|			TableOfGoods.NumberOfPackages
	|		ELSE
	|			TableOfGoods.Count / TableOfGoods.NestedPackingRatio
	|		END,
	|		
	|		0,
	|		CASE WHEN NOT &DisplayBasicUnitsOfMeasureInPrintForms THEN
	|			CASE WHEN TableOfGoods.Count < TableOfGoods.NestedPackingRatio THEN
	|				TableOfGoods.Count
	|			ELSE
	|				TableOfGoods.NestedPackingRatio
	|			END
	|		ELSE
	|			CASE WHEN TableOfGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) THEN
	|				1
	|			ELSE
	|				&QueryTextPackagingFactor
	|			END
	|		END,
	|		
	|		0,
	|		CASE WHEN NOT &DisplayBasicUnitsOfMeasureInPrintForms THEN
	|			TableOfGoods.AmountExcludingVAT / TableOfGoods.NumberOfPackages
	|		ELSE
	|			TableOfGoods.AmountExcludingVAT / TableOfGoods.Count
	|		END,
	|		
	|		0,
	|		TableOfGoods.AmountExcludingVAT,
	|		
	|		0,
	|		TableOfGoods.VATAmount,
	|		
	|		0,
	|		TableOfGoods.AmountExcludingVAT + TableOfGoods.VATAmount,
	|		
	|		0,
	|		TableOfGoods.Count * &QueryTextWeight AS NetWeightBeforeAdjustment,
	|		
	|		0,
	|		CASE WHEN &WeightUnitFilledIn THEN
	|			CASE WHEN TableOfGoods.Package.Weight IS NULL THEN
	|				TableOfGoods.Count * &QueryTextWeight1
	|			ELSE
	|				TableOfGoods.NumberOfPackages * &QueryTextWeight1
	|			END
	|		ELSE
	|			0
	|		END,
	|		NULL,
	|		FALSE
	|	
	|	FROM
	|		TableOfGoodsWithPackageCoefficients AS TableOfGoods
	|		
	|	WHERE
	|		TableOfGoods.BeforeAdjustment
	|		AND (TableOfGoods.ThisIsAProduct OR &WithdrawServices)) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Ref,
	|	NestedQuery.Products,
	|	NestedQuery.ItemName,
	|	NestedQuery.ProductsCode,
	|	NestedQuery.UnitOfMeasure,
	|	NestedQuery.UnitOfMeasurementName,
	|	NestedQuery.UnitOfMeasureCode,
	|	NestedQuery.Characteristic,
	|	NestedQuery.ItemVariantName,
	|	NestedQuery.Package,
	|	NestedQuery.PackagingName_,
	|	NestedQuery.PackageKind,
	|	NestedQuery.VATRate,
	|	NestedQuery.CCDNumber,
	|	NestedQuery.OriginCountry,
	|	NestedQuery.ThisIsReusablePackage
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|
	|TOTALS BY
	|	Ref
	|;";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TableOfGoods.Package",
			"TableOfGoods.Products"));
		
	Query.Text = StrReplace(
		Query.Text,
		"&QueryTextWeight1",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
			"TableOfGoods.Package",
			"TableOfGoods.Products"));
			
	Query.Text = StrReplace(
		Query.Text,
		"&QueryTextWeight",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
			"TableOfGoods.Products.UnitOfMeasure",
			"TableOfGoods.Products"));
		
	Query.Text = StrReplace(
		Query.Text,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"TableOfGoods.Package",
			"TableOfGoods.Products"));
			
	Query.Text = StrReplace(
		Query.Text,
		"&QueryTextUnitOfMeasureDescription1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Description",
			"TableOfGoods.Package",
			"TableOfGoods.Products"));
			
	Query.Text = StrReplace(
		Query.Text,
		"&QueryTextUnitOfMeasureDescription2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Description",
			"TableOfGoods.PackageKind",
			"TableOfGoods.Products"));
	
	Query.Text = StrReplace(
		Query.Text,
		"&QueryTextUnitCode",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Code",
			"TableOfGoods.Package",
			"TableOfGoods.Products"));
		
	Query.SetParameter("WithdrawServices",                  PrintParameters.WithdrawServices);
	Query.SetParameter("ColumnOfCodes",                    ColumnOfCodes);
	Query.SetParameter("UnitOfMeasureForWeight",            Constants.UnitOfMeasureForWeight.Get());
	Query.SetParameter("WeightUnitFilledIn",   ValueIsFilled(Constants.UnitOfMeasureForWeight.Get()));
	Query.SetParameter("DisplayBasicUnitsOfMeasureInPrintForms", Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get());
		
	ResultsArray         = Query.ExecuteBatch();
	HeaderResults          = ResultsArray[0];
	ResultForTabularPart = ResultsArray[1];
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", HeaderResults);
	DataStructureForPrinting.Insert("ResultForTabularPart", ResultForTabularPart);

	Return DataStructureForPrinting;
	
EndFunction

Function FormPrintedFormInvoice(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	Query = New Query(
	"SELECT
	|	SaleAdjustment.Ref AS Ref,
	|	SaleAdjustment.DocumentBasis.Number AS Number,
	|	SaleAdjustment.DocumentBasis.Date AS Date,
	|	SaleAdjustment.Partner AS Partner,
	|	SaleAdjustment.Counterparty AS Recipient,
	|	SaleAdjustment.Organization AS Organization,
	|	SaleAdjustment.Organization.Prefix AS Prefix,
	|	SaleAdjustment.Currency AS Currency,
	|	SaleAdjustment.PriceIncludesVAT AS PriceIncludesVAT,
	|	CASE
	|		WHEN SaleAdjustment.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR SaleAdjustment.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	SaleAdjustment.IssuiedBy AS VacationProduced
	|FROM
	|	Document.SaleAdjustment AS SaleAdjustment
	|WHERE
	|	SaleAdjustment.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Ref AS Ref,
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Products.DescriptionFull AS ProductNameFull_,
	|	NestedQuery.Products.Code AS Code,
	|	NestedQuery.Products.SKU AS SKU,
	|	NestedQuery.UnitOfMeasure.Description AS UnitPrice,
	|	NestedQuery.UnitOfMeasure AS UnitOfMeasure,
	|	NestedQuery.Characteristic.DescriptionFull AS Characteristic,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor1, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END AS Package,
	|	NestedQuery.VATRate AS VATRate,
	|	NestedQuery.Price AS Price,
	|	NestedQuery.Count AS Count,
	|	NestedQuery.Sum AS Sum,
	|	NestedQuery.VATAmount AS VATAmount,
	|	NestedQuery.LineNumber AS LineNumber,
	|	CASE
	|		WHEN NestedQuery.Ref.DocumentBasis REFS Document.CustomerInvoice
	|			THEN NestedQuery.Ref.DocumentBasis.ToReturnReusablePackage
	|					AND NestedQuery.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		ELSE FALSE
	|	END AS ThisIsReusablePackage
	|FROM
	|	(SELECT
	|		SaleAdjustment.Ref AS Ref,
	|		SaleAdjustment.Products AS Products,
	|		CASE
	|			WHEN SaleAdjustment.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN 1
	|			ELSE &QueryTextPackagingFactor2
	|		END AS ZoomRatio,
	|		&QueryTextUnitOfMeasure AS UnitOfMeasure,
	|		SaleAdjustment.Characteristic AS Characteristic,
	|		SaleAdjustment.Package AS Package,
	|		SaleAdjustment.VATRate AS VATRate,
	|		SaleAdjustment.Price AS Price,
	|		SaleAdjustment.NumberOfPackages AS Count,
	|		SaleAdjustment.Sum AS Sum,
	|		SaleAdjustment.VATAmount AS VATAmount,
	|		SaleAdjustment.LineNumber AS LineNumber
	|	FROM
	|		Document.SaleAdjustment.Goods AS SaleAdjustment
	|	WHERE
	|		SaleAdjustment.Ref IN(&DocumentsArray)
	|		AND SaleAdjustment.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))) AS NestedQuery
	|
	|ORDER BY
	|	NestedQuery.Ref,
	|	LineNumber
	|TOTALS BY
	|	Ref");
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"NestedQuery.Package",
			"NestedQuery.Products"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"SaleAdjustment.Package",
			"SaleAdjustment.Products"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"SaleAdjustment.Package",
			"SaleAdjustment.Products"));
			
	Query.SetParameter("DocumentsArray", ObjectsArray);

	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_SaleAdjustment_Invoice";
	
	ResultsArray 		= Query.ExecuteBatch();
	
	ResultPrintData			= ResultsArray[0]; // QueryResult
	ResultDocumentSelection	= ResultsArray[1]; // QueryResult
	
	PrintData					= ResultPrintData.Select();
	SelectionByDocuments 			= ResultDocumentSelection.Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	While PrintData.Next() Do
	
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		FollowingIsFound = SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		// If there are only services in the invoice, let's move on to the next document
		
		If FollowingIsFound Then
			ProductSelection_1 = SelectionByDocuments.Select();
			ThereIsVAT = PrintData.ConsiderVAT;
			ProductSelection_1.Reset();
		Else
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong chứng từ %1 không có hàng hóa. Không cần in hóa đơn';
					|ru = 'В документе %1 отсутствуют товары. Печать накладной не требуется';
					|en = 'Goods are missing in document %1. Printing of the invoice is not required'; fa = 'Goods are missing in document %1. Printing of the invoice is not required';
					|it = 'Il documento %1 non contiene le merci. La stampa della bolla non è richiesta';
					|pl = 'Brak towarów w dokumencie %1. Nie jest potrzebne drukowanie zlecenia.';
					|tr = '%1 belgesinde mal bulunmamaktadır. İrsaliyenin yazdırılmasına gerek yoktur'"),
				PrintData.Ref);
				
			CommonClientServer.MessageToUser(
				Text,
				PrintData.Ref);
			Continue;
		EndIf;
		
		// The layout must be obtained for each document, because the column sizes change dynamically.
		Template = PrintManagement.PrintFormTemplate("Document.SaleAdjustment.PF_MXL_GoodsSales");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice
		
		TemplateArea = Template.GetArea("Title");
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
		
		TitleText = TMCommonUseClientServer.GenerateDocumentTitle(
			PrintData,
			NStr("vi = 'Giao hàng';
				|ru = 'Реализация товаров';
				|en = 'Goods sales'; fa = 'فروش کالا';
				|it = 'Vendita delle merci';
				|pl = 'Sprzedaż towarów';
				|tr = 'Malların satışı'", Common.DefaultLanguageCode()));
		
		TemplateArea.Parameters.TitleText = TitleText;
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea                                   = Template.GetArea("Vendor");
		SupplierPresentation                         = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date), "FullDescr");
		TemplateArea.Parameters.SupplierPresentation = SupplierPresentation;
		TemplateArea.Parameters.Vendor               = PrintData.Organization;
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea                                   = Template.GetArea("Customer");
		RecipientPresentation1                         = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Recipient, PrintData.Date), "FullDescr");
		TemplateArea.Parameters.RecipientPresentation1 = RecipientPresentation1;
		TemplateArea.Parameters.Recipient              = PrintData.Recipient;
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output the title of the Products table
		
		TableHeader = ?(ThereIsVAT, "HeaderOfTableWithVAT", "TableHeader");
		TableRow = ?(ThereIsVAT, "TableRowWithVAT", "TableRow");
		OwnGoods = ?(ThereIsVAT, "GoodsWithVAT", "OwnGoods");
		Data = ?(ThereIsVAT, "WithVATData", "Data");
		
		ProductColumnArea = Template.Area("FirstColumnOfGoods");
		ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth
			+ ?(OutputCodes, 0, Template.Area("ColumnOfCodes").ColumnWidth)
		;
		
		RoomArea  = Template.GetArea(TableHeader + "|LineNumber");
		AreaCodes   = Template.GetArea(TableHeader + "|ColumnOfCodes");
		ProductArea   = Template.GetArea(TableHeader + "|" + OwnGoods);
		DataArea  = Template.GetArea(TableHeader + "|" + Data);
		
		SpreadsheetDocument.Put(RoomArea);
			
		If OutputCodes Then
			AreaCodes.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
			
		SpreadsheetDocument.Join(ProductArea);
		SpreadsheetDocument.Join(DataArea);
		
		RoomArea  = Template.GetArea(TableRow + "|LineNumber");
		AreaCodes   = Template.GetArea(TableRow + "|ColumnOfCodes");
		ProductArea   = Template.GetArea(TableRow + "|" + OwnGoods);
		DataArea  = Template.GetArea(TableRow + "|" + Data);
		
		Sum          = 0;
		VATAmount       = 0;
		LineNumber    = 0;
		
		// Output the rows of the Goods table
			
		While ProductSelection_1.Next() Do
			
			LineNumber = LineNumber + 1;
			
			RoomArea.Parameters.LineNumber = LineNumber;
			SpreadsheetDocument.Put(RoomArea);
			
			If OutputCodes Then
				
				AreaCodes.Parameters.SKU = ProductSelection_1[NameOfCodeColumn];
				SpreadsheetDocument.Join(AreaCodes);
				
			EndIf;
			
			ProductArea.Parameters.Fill(ProductSelection_1);
			
			AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersForGettingNameToPrint.ReturnContainers = ProductSelection_1.ThisIsReusablePackage;
			AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			ProductArea.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				ProductSelection_1.ProductNameFull_,
				ProductSelection_1.Characteristic,
				,
				,
				AdditionalParametersForGettingNameToPrint);
			
			SpreadsheetDocument.Join(ProductArea);
			
			DataArea.Parameters.Fill(ProductSelection_1);
			
			SpreadsheetDocument.Join(DataArea);
			
			Sum          = Sum          + ProductSelection_1.Sum;
			VATAmount       = VATAmount       + ProductSelection_1.VATAmount;
			
		EndDo;
		
		// We output the basement
		
		TableFooter = ?(ThereIsVAT, "BasementTableWithVAT", "TableFooter");
		RoomArea  = Template.GetArea(TableFooter + "|LineNumber");
		AreaCodes   = Template.GetArea(TableFooter + "|ColumnOfCodes");
		ProductArea   = Template.GetArea(TableFooter + "|" + OwnGoods);
		DataArea  = Template.GetArea(TableFooter + "|" + Data);
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		
		DataArea.Parameters.Total = PrintFormGeneration.SumFormat(Sum);
		SpreadsheetDocument.Join(DataArea);
		
		// We output the total of the ADS
		
		Area = Template.GetArea("VATBasement");
		
		Area.Parameters.TotalVAT = VATAmount;
		If ThereIsVAT Then
			Area.Parameters.VAT = ?(PrintData.PriceIncludesVAT, 
										NStr("vi = 'Trong đó thuế GTGT:';
											|ru = 'В том числе НДС:';
											|en = 'Including VAT:'; fa = 'Including VAT:';
											|it = 'IVA compresa:';
											|pl = 'W tym VAT';
											|tr = 'KDV dahil:'", Common.DefaultLanguageCode()),
										NStr("vi = 'Thuế GTGT:';
											|ru = 'Сумма НДС:';
											|en = 'VAT amount:'; fa = 'مبلغ مالیات بر ارزش افزوده:';
											|it = 'Importo IVA:';
											|pl = 'Wartość VAT';
											|tr = 'KDV tutarı:'", Common.DefaultLanguageCode()));
		Else
			Area.Parameters.VAT = NStr("vi = 'Không gồm thuế (GTGT)';
										|ru = 'Без налога (НДС)';
										|en = 'Without tax (VAT)'; fa = 'بدون مالیات (مالیات بر ارزش افزوده)';
										|it = 'senza imposta (IVA)';
										|pl = 'bez podatku (VAT)';
										|tr = 'Vergisiz (KDV)'", Common.DefaultLanguageCode());
		EndIf;
		SpreadsheetDocument.Join(Area);
		
		// We output the Amount in words
		
		TemplateArea = Template.GetArea("AmountInWords");
		AmountToBeRegistered = Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount);
		
		TotalString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tổng số %1, thành tiền %2';
				|ru = 'Всего наименований %1, на сумму %2';
				|en = 'Total items %1 in the amount of %2'; fa = 'Total items %1 in the amount of %2';
				|it = 'Totale articoli %1, per importo di %2';
				|pl = 'Razem pozycji %1, na kwotę %2';
				|tr = 'Toplam tanım %1, tutar %2'", Common.DefaultLanguageCode()),
			ProductSelection_1.Count(),
			PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));

		TemplateArea.Parameters.TotalString = TotalString;
		TemplateArea.Parameters.AmountInWords  = ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency);
		
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output signatures
		TemplateArea = Template.GetArea("Signatures");
		
		If ValueIsFilled(PrintData.VacationProduced) Then
			TemplateArea.Parameters.VacationProduced = PersonsTM.IndividualShortName(PrintData.VacationProduced, PrintData.Date);
		EndIf;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;

	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;

EndFunction

Function FormPrintedFormRegisterOfCCDNumbers(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_SaleAdjustment_CCDNumberRegistry";
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = "
	|SELECT
	|	DocumentsData.Ref AS Ref,
	|	DocumentsData.AdjustmentKind AS BusinessOperation,
	|	DocumentsData.AdjustingEntryType AS AdjustingEntryType
	|
	|INTO DocumentDataTable_
	|FROM
	|	Document.SaleAdjustment AS DocumentsData
	|
	|WHERE
	|	DocumentsData.Ref IN (&ObjectsArray)
	|;";
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.Execute();
	
	Query.Text = QueryTextTTTypesOfStocks() + "
	|SELECT DISTINCT
	|	TableTypesOfStocks_.Ref AS Ref
	|
	|INTO TTDocumentTable_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = DimensionKeys.Ref
	|		
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON DimensionKeys.Products = ProductData_1.Ref
	|
	|WHERE
	|	TableTypesOfStocks_.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|	AND NOT ProductData_1.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.DocumentBasis.Number AS Number,
	|	DocumentData.DocumentBasis.Date AS Date,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.Manager.Individual AS ManagerIndividual
	|FROM
	|	Document.SaleAdjustment AS DocumentData
	|
	|	INNER JOIN
	|		TTDocumentTable_ AS DocumentsTable
	|	ON
	|		DocumentData.Ref = DocumentsTable.Ref
	|
	|ORDER BY
	|	Ref
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.Ref AS Ref,
	|	PRESENTATION(TableTypesOfStocks_.ItemsLocationAttributes.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.Code AS Code,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.SKU AS SKU,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.DescriptionFull AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.CHARACTERISTIC.DescriptionFull AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumber.OriginCountry AS OriginCountry,
	|	CASE
	|		WHEN
	|			TableTypesOfStocks_.ToReturnReusablePackage
	|			AND TableTypesOfStocks_.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThisIsReusablePackage,
	|	SUM(TableTypesOfStocks_.Count) AS Count
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|	
	|	INNER JOIN TTDocumentTable_ AS DocumentsTable
	|		ON TableTypesOfStocks_.Ref = DocumentsTable.Ref
	|
	|WHERE
	|	TableTypesOfStocks_.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|	AND NOT TableTypesOfStocks_.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|
	|GROUP BY
	|	TableTypesOfStocks_.Ref,
	|	TableTypesOfStocks_.LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.CHARACTERISTIC,
	|   TableTypesOfStocks_.ItemsLocationAttributes.Products.UnitOfMeasure,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.Code,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.SKU,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.DescriptionFull,
	|	TableTypesOfStocks_.ItemsLocationAttributes.CHARACTERISTIC.DescriptionFull,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.ItemsType,
	|	TableTypesOfStocks_.CCDNumber,
	|	TableTypesOfStocks_.CCDNumber.OriginCountry,
	|	TableTypesOfStocks_.ToReturnReusablePackage
	|
	|HAVING
	|	SUM(TableTypesOfStocks_.Count) > 0
	|
	|ORDER BY
	|	Ref,
	|	TableTypesOfStocks_.LineNumber
	|
	|TOTALS BY
	|	Ref
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Ref
	|FROM
	|	Document.SaleAdjustment AS DocumentData
	|
	|	LEFT JOIN
	|		TTDocumentTable_ AS DocumentsTable
	|	ON
	|		DocumentData.Ref = DocumentsTable.Ref
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|	AND DocumentsTable.Ref IS NULL
	|
	|ORDER BY
	|	Ref
	|";
	
	SetTTStockOptions(
		Query,
		False, // ConvertToLocalCurrency
		False,); // IncludingBeforeAdjustment
	
	Template = PrintManagement.PrintFormTemplate("Document.SaleAdjustment.PF_MXL_CCDNumberRegistry");
	
	ResultsArray = Query.ExecuteBatch();
	// Array of results[0] - Products
	// Array of results[1] - Occurrences
	// Array of results[2] - vtdannypocorrectedovodaostatkov
	// Array of Results[3] - Destroy goods
	// Array of results[4] - Destroy the occurrences
	// Array of results[5] - Related documents
	// Array of results[6] - Related documentedcorrection to primary documents
	// Array of results[7] - Data corrects after
	// Array of results[8] - VseVidyZapasov
	// Array of results[9] - Types of reserves
	// Array of results[10] - Destroy all types of reserves
	// Array of results[11] - To destroy the data of the correction of the results of the results
	// The array of results[12] is a table of documents.
	ResultPrintData 		= ResultsArray[13]; // QueryResult
	ResultFromDocuments 		= ResultsArray[14]; // QueryResult
	ResultForDocumentsWithoutCCD	= ResultsArray[15]; // QueryResult
	
	PrintData				= ResultPrintData.Select();
	SelectionByDocuments			= ResultFromDocuments.Select(QueryResultIteration.ByGroups);
	SelectionOfDocumentsWithoutCCD	= ResultForDocumentsWithoutCCD.Select();
	
	FirstDocument = True;
	
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	
	While PrintData.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		Area = Template.GetArea("Header");
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, Area, PrintData.Ref);
		Area.Parameters.TitleText = TMCommonUseClientServer.GenerateDocumentTitle(
			PrintData, 
			NStr("vi = 'Bảng kê số tờ khai hải quan kèm hóa đơn';
				|ru = 'Реестр номеров ГТД к накладной';
				|en = 'CCD number registry to invoice'; fa = 'CCD number registry to invoice';
				|it = 'Registro numeri delle dichiarazioni doganali di carico per la bolla di accompagnamento';
				|pl = 'Wykaz numerów towarowej deklaracji celnej do zlecenia transportowego';
				|tr = 'GB numaralarının irsaliyeye kaydedilmesi'", Common.DefaultLanguageCode()));
		Area.Parameters.RepresentationOfTheOrganization = PrintFormGeneration.OrganizationDescription(
			PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date),
			"FullDescr");
		Area.Parameters.PartnerPresentation_ = PrintFormGeneration.OrganizationDescription(
			PrintFormGeneration.InformationAboutLegalEntity(PrintData.Counterparty, PrintData.Date),
			"FullDescr");
		SpreadsheetDocument.Put(Area);
				
		Area = Template.GetArea("TableHeader|BeginningOfTheLine");
		SpreadsheetDocument.Put(Area);
		If OutputCodes Then
			Area = Template.GetArea("TableHeader|ColumnOfCodes");
			Area.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
			SpreadsheetDocument.Join(Area);
		EndIf;
		Area = Template.GetArea("TableHeader|ProductColumn_");
		SpreadsheetDocument.Join(Area);
				
		LineNumber = 1;
		
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		ProductSelection_1 = SelectionByDocuments.Select();
		While ProductSelection_1.Next() Do
					
			Area = Template.GetArea("TableRow|BeginningOfTheLine");
			Area.Parameters.LineNumber = LineNumber;
			LineNumber = LineNumber + 1;
			SpreadsheetDocument.Put(Area);
			
			If OutputCodes Then
				Area = Template.GetArea("TableRow|ColumnOfCodes");
				Area.Parameters.CodeValue = ProductSelection_1[NameOfCodeColumn];
				SpreadsheetDocument.Join(Area);
			EndIf;
			
			Area = Template.GetArea("TableRow|ProductColumn_");
			Area.Parameters.Fill(ProductSelection_1);
			Area.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				ProductSelection_1.Products,
				ProductSelection_1.Characteristic,
				,
				,
				AdditionalParametersProductPresentation);
			
			SpreadsheetDocument.Join(Area);
			
		EndDo;
				
		Area = Template.GetArea("TableFooter|BeginningOfTheLine");
		SpreadsheetDocument.Put(Area);
		If OutputCodes Then
			Area = Template.GetArea("TableFooter|ColumnOfCodes");
			SpreadsheetDocument.Join(Area);
		EndIf;
		Area = Template.GetArea("TableFooter|ProductColumn_");
		SpreadsheetDocument.Join(Area);
		
		Area = Template.GetArea("Signatures");
		Area.Parameters.TotalString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tổng số mục %1';
				|ru = 'Всего наименований %1';
				|en = 'Total items %1'; fa = 'Total items %1';
				|it = 'Totale articoli %1';
				|pl = 'Razem pozycji %1';
				|tr = 'Toplam tanım %1'", Common.DefaultLanguageCode()), String(LineNumber - 1));
		If ValueIsFilled(PrintData.ManagerIndividual) Then
			Area.Parameters.Manager = PersonsTM.IndividualShortName(PrintData.ManagerIndividual, PrintData.Date);
		EndIf;
		SpreadsheetDocument.Put(Area);
	
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
	EndDo;
	
	// We will output messages about documents for which it is not required to print a register of GTD numbers.
	While SelectionOfDocumentsWithoutCCD.Next() Do
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong chứng từ %1 không có hàng hóa với số tờ khai hải quan. Không cần in Bảng kê số tờ khai hải quan.';
				|ru = 'В документе %1 отсутствуют товары с номерами ГТД. Печать реестра номеров ГТД не требуется.';
				|en = 'Goods with CCD numbers are missing in document %1. Printing of CCD number registry is not required.'; fa = 'Goods with CCD numbers are missing in document %1. Printing of CCD number registry is not required.';
				|it = 'Non ci sono merci con i numeri delle dichiarazioni doganali di carico nel documento %1. Non è necessario stampare il registro dei numeri delle dichiarazioni doganali di carico.';
				|pl = 'W dokumencie %1 nie ma towarów z numerami towarowej deklaracji celnej. Drukowanie rejestru numerów towarowej deklaracji celnej nie jest potrzebne.';
				|tr = '%1 belgesinde GB Numarası olan mal bulunmamaktadır. GB Numarası kaydının yazdırılmasına gerek yoktur.'"),
			String(SelectionOfDocumentsWithoutCCD.Ref));
		CommonClientServer.MessageToUser(
			Text,
			SelectionOfDocumentsWithoutCCD.Ref);
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Partner";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	EndIf;
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Shipper");
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("GoodsRecipient");
	
EndProcedure

Function GetDataForPrintedInvoiceForm(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	Return DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode);
	
EndFunction

Function DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	TempTablesManager = New TempTablesManager;
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(ObjectsArray, TempTablesManager);	
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	Documents.Ref AS Ref,
	|	Documents.DocumentBasis.Number AS Number,
	|	Documents.DocumentBasis.Date AS Date,
	|	UNDEFINED AS DocumentBasis,
	|	ISNULL(Documents.CompanyBankAccount.Owner, Documents.Organization) AS Organization,
	|	Documents.Organization AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription AS Director,
	|	TableResponsiblePersons.DirectorJobTitle AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription AS ChiefAccountant,
	|	CASE
	|		WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.Counterparty AS Counterparty,
	|	Documents.Counterparty.LegalEntityIndividual AS CounterpartyLegEntInd,
	|	Documents.CompanyBankAccount AS BankAccount,
	|	
	|	CASE WHEN Documents.CompanyBankAccount.ForeignBank
	|		OR Documents.CompanyBankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|		OR Documents.CounterpartyBankAccount.ForeignBank THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentAbroad,
	|	Documents.CompanyBankAccount.CashCurrency AS CashCurrency,
	|	Documents.CompanyBankAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN Documents.CompanyBankAccount.DigitalRoubleAccountID
	|		ELSE Documents.CompanyBankAccount.AccountNumber
	|	END AS BankAccountNumber,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BICBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END AS BankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END AS TransferBankBIC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END AS TransferBankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END AS TransferBankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END AS TransferBankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankNameInt
	|		ELSE BankClassifier.InternationalDescription
	|	END AS BankNameInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankSWIFTCode
	|		ELSE BankClassifier.SWIFTBIC
	|	END AS BankSWIFTCode,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END AS BankCityInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddress
	|		ELSE BankClassifier.Address
	|	END AS BankAddress,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddressInt
	|		ELSE BankClassifier.InternationalAddress
	|	END AS BankAddressInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBank
	|		ELSE BankCountries.Ref
	|	END AS CountryOfBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankNameForPaymentsInt
	|		ELSE CorrespondentBankClassifier.InternationalDescription
	|	END AS BankNameForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankSWIFTCodeForPayments
	|		ELSE CorrespondentBankClassifier.SWIFTBIC
	|	END AS BankSWIFTCodeForPayments,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityForPaymentsInt
	|		ELSE CorrespondentBankClassifier.CityInternationalFormat
	|	END AS BankCityForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddressForPaymentInt
	|		ELSE CorrespondentBankClassifier.InternationalAddress
	|	END AS BankAddressForPaymentInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankAddress
	|		ELSE CorrespondentBankClassifier.Address
	|	END AS TransferBankAddress,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBankForPayments
	|		ELSE CountriesOfCorrespondentBanksOfRussianFederation.Ref
	|	END AS CountryOfBankForPayments,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN """"
	|		ELSE ISNULL(BankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN """"
	|		ELSE ISNULL(CorrespondentBankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCCForSettlements,
	|	Documents.CompanyBankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT AS PriceIncludesVAT,
	|	Documents.Currency AS Currency,
	|	Documents.Manager.Individual AS Manager,
	|	Documents.DocumentAmount AS AmountToReturn,
	|	FALSE AS PartialPayment,
	|	"""" AS PaymentPurposes,
	|	100 AS PayPercentage,
	|	"""" AS AdditionalInformation,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	Documents.Shipper AS Shipper,
	|	Documents.GoodsRecipient AS GoodsRecipient,
	|	"""" AS PaymentID,
	|	FALSE AS InvoiceToBeRefunded
	|FROM
	|	Document.SaleAdjustment AS Documents
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON Documents.Ref = TableResponsiblePersons.Ref
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON Documents.CompanyBankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS BankCountries
	|		ON BankClassifier.CountryCode = BankCountries.Code
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON Documents.CompanyBankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS CountriesOfCorrespondentBanksOfRussianFederation
	|		ON CorrespondentBankClassifier.CountryCode = CountriesOfCorrespondentBanksOfRussianFederation.Code
	|		LEFT JOIN Constants
	|		ON TRUE
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Documents.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UNDEFINED AS Ref,
	|	0 AS LineNumber,
	|	UNDEFINED AS PaymentDate,
	|	0 AS PaymentPercentage,
	|	0 AS PaymentAmount,
	|	TRUE AS ThisIsDepositForPackage
	|WHERE
	|	FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	|	Table.ProductsInSet                              AS ProductsInSet,
	|	Table.ItemVariantOfSet                            AS ItemVariantOfSet,
	|
	|	Table.LineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Content AS Content,
	|	Table.Characteristic AS Characteristic,
	|	Table.Package AS Package,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	Table.Price AS Price,
	|	Table.Sum AS Sum,
	|	Table.VATRate AS VATRate,
	|	Table.VATAmount AS VATAmount,
	|	CASE
	|		WHEN Table.Ref.DocumentBasis REFS Document.CustomerInvoice
	|			THEN Table.Ref.DocumentBasis.ToReturnReusablePackage
	|					AND Table.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		ELSE FALSE
	|	END AS ThisIsReusablePackage,
	|	0 AS DiscountAmount,
	|	Table.Sum AS AmountWithoutADiscount
	|INTO Goods
	|FROM
	|	Document.SaleAdjustment.Goods AS Table
	|
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|
	|WHERE
	|	Table.Ref IN(&ObjectsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref                 AS Ref,
	|	Table.ProductsInSet     AS ProductsInSet,
	|	Table.ItemVariantOfSet   AS ItemVariantOfSet,
	|	MIN(Table.LineNumber)   AS LineNumber,
	|	SUM(Table.Sum)           AS Sum,
	|	SUM(Table.VATAmount)        AS VATAmount,
	|	SUM(Table.DiscountAmount)     AS DiscountAmount,
	|	SUM(Table.AmountWithoutADiscount)  AS AmountWithoutADiscount
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|WHERE
	|	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref
	|INTO VariousGoods_
	|FROM
	|	Goods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref                                    AS Ref,
	|	Goods.ItemKitConfiguration           AS ItemKitConfiguration,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CASE WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|		AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS MainComponent,
	|	0 AS DefaultQuantity,
	|	Goods.Count AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	VariousGoods_.Ref                                                                  AS Ref,
	|	ConfigurationOptionsForProductRange.Ref                                           AS ItemKitConfiguration,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption                  AS SetPricingOption,
	|	ConfigurationOptionsForProductRange.Ref.Owner                                  AS ProductsInSet,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic                            AS ItemVariantOfSet,
	|	ConfigurationOptionsForProductRange.Products   AS Products,
	|	ConfigurationOptionsForProductRange.Characteristic AS Characteristic,
	|	FALSE AS MainComponent,
	|	SUM(ConfigurationOptionsForProductRange.Count) AS DefaultQuantity,
	|	0 AS Count
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|		LEFT JOIN VariousGoods_ AS VariousGoods_
	|		ON TRUE
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN (SELECT T.ItemKitConfiguration FROM Goods AS T)
	|
	|GROUP BY
	|	VariousGoods_.Ref,
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	ConfigurationOptionsForProductRange.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	MAX(Table.MainComponent) AS MainComponent,
	|	SUM(Table.DefaultQuantity) AS DefaultQuantity,
	|	SUM(Table.Count) AS Count
	|INTO TemporaryTableSetsOptionalPartTwo
	|FROM
	|	TemporaryTableSetsOptionalPartOne AS Table
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultQuantity <> 0 AND Result.MainComponent
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE NULL
	|		END) + 0.5 AS NUMBER(10,0)) - 1 AS Count
	|INTO TemporaryTableSetsOptional
	|FROM
	|	TemporaryTableSetsOptionalPartTwo AS Result
	|GROUP BY
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableSetsOptional.ItemKitConfiguration,
	|	TemporaryTableSetsOptional.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	TemporaryTableSetsOptional.SetPricingOption AS SetPricingOption,
	|	Table.Ref                            AS Ref,
	|	Table.ProductsInSet                AS ProductsInSet,
	|	Table.ItemVariantOfSet              AS ItemVariantOfSet,
	|	Table.LineNumber                       AS LineNumber,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	Table.Sum                             AS Sum,
	|	Table.VATAmount                          AS VATAmount,
	|	Table.DiscountAmount                       AS DiscountAmount,
	|	Table.AmountWithoutADiscount                    AS AmountWithoutADiscount
	|INTO TemporaryTableSets
	|FROM
	|	TemporaryTableSetsPreparation AS Table
	|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	|		ON Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	|		AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	|		AND Table.Ref = TemporaryTableSetsOptional.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	
	|	Goods.Ref											AS Ref,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet								AS ProductsInSet,
	|	ISNULL(ProductsOfPresentationSet.DescriptionFull, Goods.ProductsInSet.DescriptionFull) AS ProductOfSetIsFullName,
	|	Goods.ItemVariantOfSet								AS ItemVariantOfSet,
	|	ISNULL(CharacteristicsOfProductOfPresentationSet.DescriptionFull, ISNULL(Goods.ItemVariantOfSet.DescriptionFull, """")) AS CharacteristicsOfSetFullName,
	|	Goods.IsRecordsSet AS IsRecordsSet,
	|	Goods.TheseAreComponents AS TheseAreComponents,
	|
	|	Goods.LineNumber										AS LineNumber,
	|	Goods.Products										AS Products,
	|	Goods.Products.Code									AS Code,
	|	Goods.Products.SKU								AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
	|	&QueryTextUnitOfMeasureDescription				AS UnitOfMeasure,
	|	Goods.NumberOfPackages                                AS Count,
	|	Goods.Price AS Price,
	|	Goods.Sum                                             AS Sum,
	|	Goods.VATRate                                         AS VATRate,
	|	Goods.VATAmount                                          AS VATAmount,
	|	UNDEFINED                                             AS TypeOfContractorSPrice,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END                                                    AS Package,
	|	Goods.DiscountAmount                                       AS DiscountAmount,
	|	Goods.AmountWithoutADiscount                                    AS AmountWithoutADiscount,
	|	Goods.ThisIsReusablePackage                                 AS ThisIsReusablePackage	
	|FROM (
	|	SELECT
	|		Table.Ref,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.PresentationOptionInPrintForms
	|		ELSE
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	|		END AS PresentationOptionInPrintForms,
	|
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.SetPricingOption
	|		ELSE
	|			VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		END AS SetPricingOption,
	|		Table.ProductsInSet,
	|		Table.ItemVariantOfSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|		END AS TheseAreComponents,
	|		FALSE AS IsRecordsSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.LineNumber
	|		ELSE
	|			Table.LineNumber
	|		END AS LineNumber,
	|		Table.Products,
	|		Table.Count,
	|		Table.NumberOfPackages,
	|		Table.Price,
	|		Table.Sum,
	|		Table.VATRate,
	|		Table.VATAmount,
	|		Table.Characteristic,
	|		Table.Package,
	|		Table.DiscountAmount,
	|		Table.AmountWithoutADiscount,
	|		Table.Content,
	|		Table.ThisIsReusablePackage
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
	|			ON TemporaryTableSets.ProductsInSet = Table.ProductsInSet
	|			 AND TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet
	|			 AND TemporaryTableSets.Ref = Table.Ref
	|
	|	WHERE
	|		Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|		OR (Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|	        AND TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents),
	|	                                                                              VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TemporaryTableSets.Ref,
	|		TemporaryTableSets.PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption AS SetPricingOption,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		FALSE AS TheseAreComponents,
	|		TRUE AS IsRecordsSet,
	|		TemporaryTableSets.LineNumber,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.Count,
	|		TemporaryTableSets.NumberOfPackages,
	|		CASE WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|				(TemporaryTableSets.Sum) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|			ELSE
	|				0
	|		END AS Price,
	|		TemporaryTableSets.Sum AS Sum,
	|		TemporaryTableSets.ProductsInSet.VATRate,
	|		TemporaryTableSets.VATAmount,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|		TemporaryTableSets.DiscountAmount,
	|		TemporaryTableSets.AmountWithoutADiscount,
	|		"""",
	|		FALSE
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|	                                                           VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
	|) AS Goods
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsOfPresentationSet
	|	ON (Goods.ProductsInSet = ProductsOfPresentationSet.Ref
	|			AND ProductsOfPresentationSet.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS CharacteristicsOfProductOfPresentationSet
	|	ON (Goods.ItemVariantOfSet = CharacteristicsOfProductOfPresentationSet.Ref
	|			AND CharacteristicsOfProductOfPresentationSet.LanguageCode = &LanguageCode)
	|
	|ORDER BY
	|	Goods.LineNumber,
	|	IsRecordsSet DESC
	|";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
	
	If ValueIsFilled(LanguageCode)
		And Not LanguageCode = Common.DefaultLanguageCode() Then
		
		PackageNameUnitsOfMeasurement = "InternationalAbbreviation";
		
	Else
		
		PackageNameUnitsOfMeasurement = "Description";
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&QueryTextUnitOfMeasureDescription",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			PackageNameUnitsOfMeasurement,
			"Goods.Package",
			"Goods.Products"));
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("LanguageCode", LanguageCode);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages", RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[RequestResultsPackage.Count() - 1]);
	
	Return DataStructureForPrinting;
	
EndFunction

Function PrintDataDebitCreditNote(PrintParameters, ObjectsArray, DebitCreditNote, LanguageCode) Export
	
	TempTablesManager = New TempTablesManager;
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(ObjectsArray, TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	Documents.Ref AS Ref,
	|	Documents.Number AS Number,
	|	Documents.Date AS Date,
	|	UNDEFINED AS DocumentBasis,
	|	ISNULL(Documents.CompanyBankAccount.Owner, Documents.Organization) AS Organization,
	|	Documents.Organization AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription AS Director,
	|	TableResponsiblePersons.DirectorJobTitle AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription AS ChiefAccountant,
	|	CASE
	|		WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.Counterparty AS Counterparty,
	|	Documents.Counterparty.LegalEntityIndividual AS CounterpartyLegEntInd,
	|	Documents.CompanyBankAccount AS BankAccount,
	|	
	|	CASE WHEN Documents.CompanyBankAccount.ForeignBank
	|		OR Documents.CompanyBankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|		OR Documents.CounterpartyBankAccount.ForeignBank THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentAbroad,
	|	Documents.CompanyBankAccount.CashCurrency AS CashCurrency,
	|	Documents.CompanyBankAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN Documents.CompanyBankAccount.DigitalRoubleAccountID
	|		ELSE Documents.CompanyBankAccount.AccountNumber
	|	END AS BankAccountNumber,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BICBank,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END AS BankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END AS TransferBankBIC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END AS TransferBankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END AS TransferBankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END AS TransferBankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankNameInt
	|		ELSE BankClassifier.InternationalDescription
	|	END AS BankNameInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankSWIFTCode
	|		ELSE BankClassifier.SWIFTBIC
	|	END AS BankSWIFTCode,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END AS BankCityInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddress
	|		ELSE BankClassifier.Address
	|	END AS BankAddress,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddressInt
	|		ELSE BankClassifier.InternationalAddress
	|	END AS BankAddressInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBank
	|		ELSE BankCountries.Ref
	|	END AS CountryOfBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankNameForPaymentsInt
	|		ELSE CorrespondentBankClassifier.InternationalDescription
	|	END AS BankNameForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankSWIFTCodeForPayments
	|		ELSE CorrespondentBankClassifier.SWIFTBIC
	|	END AS BankSWIFTCodeForPayments,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityForPaymentsInt
	|		ELSE CorrespondentBankClassifier.CityInternationalFormat
	|	END AS BankCityForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddressForPaymentInt
	|		ELSE CorrespondentBankClassifier.InternationalAddress
	|	END AS BankAddressForPaymentInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankAddress
	|		ELSE CorrespondentBankClassifier.Address
	|	END AS TransferBankAddress,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBankForPayments
	|		ELSE CountriesOfCorrespondentBanksOfRussianFederation.Ref
	|	END AS CountryOfBankForPayments,
	|	Documents.CompanyBankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT AS PriceIncludesVAT,
	|	Documents.Currency AS Currency,
	|	Documents.Manager.Individual AS Manager,
	|	Documents.DocumentAmount AS DocumentAmount
	|FROM
	|	Document.SaleAdjustment AS Documents
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON Documents.Ref = TableResponsiblePersons.Ref
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON Documents.CompanyBankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS BankCountries
	|		ON BankClassifier.CountryCode = BankCountries.Code
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON Documents.CompanyBankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS CountriesOfCorrespondentBanksOfRussianFederation
	|		ON CorrespondentBankClassifier.CountryCode = CountriesOfCorrespondentBanksOfRussianFederation.Code
	|		LEFT JOIN Constants
	|		ON TRUE
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Documents.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|
	|	Table.LineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Content AS Content,
	|	Table.Characteristic AS Characteristic,
	|	Table.Package AS Package,
	|	-Table.Count AS Count,
	|	-Table.NumberOfPackages AS NumberOfPackages,
	|	CASE
	|		WHEN NOT &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN CASE WHEN Table.NumberOfPackages <> 0 THEN Table.Sum / Table.NumberOfPackages ELSE 0 END
	|		ELSE CASE WHEN Table.Count <> 0 THEN Table.Sum / Table.Count ELSE 0 END
	|	END AS Price,
	|	-Table.Sum AS Sum,
	|	Table.VATRate AS VATRate,
	|	-Table.VATAmount AS VATAmount
	|
	|INTO Goods
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS Table
	|
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|
	|WHERE
	|	Table.Ref IN (&ObjectsArray)
	|	AND &CreditNote
	|	AND Table.Sum < 0
	|
	|UNION ALL
	|	
	|SELECT
	|	Table.Ref AS Ref,
	|
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|
	|	Table.LineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Content AS Content,
	|	Table.Characteristic AS Characteristic,
	|	Table.Package AS Package,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	CASE
	|		WHEN NOT &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN CASE WHEN Table.NumberOfPackages <> 0 THEN Table.Sum / Table.NumberOfPackages ELSE 0 END
	|		ELSE CASE WHEN Table.Count <> 0 THEN Table.Sum / Table.Count ELSE 0 END
	|	END AS Price,
	|	Table.Sum AS Sum,
	|	Table.VATRate AS VATRate,
	|	Table.VATAmount AS VATAmount
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS Table
	|
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|
	|WHERE
	|	Table.Ref IN (&ObjectsArray)
	|	AND &DebitNote
	|	AND Table.Sum > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref                 AS Ref,
	|	Table.ProductsInSet     AS ProductsInSet,
	|	Table.ItemVariantOfSet   AS ItemVariantOfSet,
	|	MIN(Table.LineNumber)   AS LineNumber,
	|	SUM(Table.Sum)           AS Sum,
	|	SUM(Table.VATAmount)        AS VATAmount
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|WHERE
	|	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref
	|INTO VariousGoods_
	|FROM
	|	Goods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref                                    AS Ref,
	|	Goods.ItemKitConfiguration           AS ItemKitConfiguration,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CASE WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|		AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS MainComponent,
	|	0 AS DefaultQuantity,
	|	Goods.Count AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	VariousGoods_.Ref                                                                  AS Ref,
	|	ConfigurationOptionsForProductRange.Ref                                           AS ItemKitConfiguration,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption                  AS SetPricingOption,
	|	ConfigurationOptionsForProductRange.Ref.Owner                                  AS ProductsInSet,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic                            AS ItemVariantOfSet,
	|	ConfigurationOptionsForProductRange.Products   AS Products,
	|	ConfigurationOptionsForProductRange.Characteristic AS Characteristic,
	|	FALSE AS MainComponent,
	|	SUM(ConfigurationOptionsForProductRange.Count) AS DefaultQuantity,
	|	0 AS Count
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|		LEFT JOIN VariousGoods_ AS VariousGoods_
	|		ON TRUE
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN (SELECT T.ItemKitConfiguration FROM Goods AS T)
	|
	|GROUP BY
	|	VariousGoods_.Ref,
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	ConfigurationOptionsForProductRange.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	MAX(Table.MainComponent) AS MainComponent,
	|	SUM(Table.DefaultQuantity) AS DefaultQuantity,
	|	SUM(Table.Count) AS Count
	|INTO TemporaryTableSetsOptionalPartTwo
	|FROM
	|	TemporaryTableSetsOptionalPartOne AS Table
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultQuantity <> 0 AND Result.MainComponent
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE NULL
	|		END) + 0.5 AS NUMBER(10,0)) - 1 AS Count
	|INTO TemporaryTableSetsOptional
	|FROM
	|	TemporaryTableSetsOptionalPartTwo AS Result
	|GROUP BY
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableSetsOptional.ItemKitConfiguration,
	|	TemporaryTableSetsOptional.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	TemporaryTableSetsOptional.SetPricingOption AS SetPricingOption,
	|	Table.Ref                            AS Ref,
	|	Table.ProductsInSet                AS ProductsInSet,
	|	Table.ItemVariantOfSet              AS ItemVariantOfSet,
	|	Table.LineNumber                       AS LineNumber,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	Table.Sum                             AS Sum,
	|	Table.VATAmount                          AS VATAmount
	|INTO TemporaryTableSets
	|FROM
	|	TemporaryTableSetsPreparation AS Table
	|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	|		ON Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	|		AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	|		AND Table.Ref = TemporaryTableSetsOptional.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	
	|	Goods.Ref AS Ref,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption AS SetPricingOption,
	|	Goods.ProductsInSet AS ProductsInSet,
	|	ISNULL(ProductsOfPresentationSet.DescriptionFull, Goods.ProductsInSet.DescriptionFull) AS ProductOfSetIsFullName,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|	ISNULL(CharacteristicsOfProductOfPresentationSet.DescriptionFull, ISNULL(Goods.ItemVariantOfSet.DescriptionFull, """")) AS CharacteristicsOfSetFullName,
	|	Goods.IsRecordsSet AS IsRecordsSet,
	|	Goods.TheseAreComponents AS TheseAreComponents,
	|
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.Products.Code AS Code,
	|	Goods.Products.SKU AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, ISNULL(Goods.Products.DescriptionFull, Goods.Content)) AS DescriptionFull,
	|	&QueryTextUnitOfMeasureDescription AS UnitOfMeasure,
	|	Goods.NumberOfPackages AS Count,
	|	Goods.Price AS Price,
	|	Goods.Sum AS Sum,
	|	Goods.VATRate AS VATRate,
	|	Goods.VATAmount AS VATAmount,
	|	UNDEFINED AS TypeOfContractorSPrice,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END AS Package,
	|	Goods.Content AS Content
	|FROM (
	|	SELECT
	|		Table.Ref AS Ref,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.PresentationOptionInPrintForms
	|		ELSE
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	|		END AS PresentationOptionInPrintForms,
	|
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.SetPricingOption
	|		ELSE
	|			VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		END AS SetPricingOption,
	|		Table.ProductsInSet AS ProductsInSet,
	|		Table.ItemVariantOfSet AS ItemVariantOfSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|		END AS TheseAreComponents,
	|		FALSE AS IsRecordsSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.LineNumber
	|		ELSE
	|			Table.LineNumber
	|		END AS LineNumber,
	|		Table.Products AS Products,
	|		Table.Count AS Count,
	|		Table.NumberOfPackages AS NumberOfPackages,
	|		Table.Price AS Price,
	|		Table.Sum AS Sum,
	|		Table.VATRate AS VATRate,
	|		Table.VATAmount AS VATAmount,
	|		Table.Characteristic AS Characteristic,
	|		Table.Package AS Package,
	|		Table.Content AS Content
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
	|			ON TemporaryTableSets.ProductsInSet = Table.ProductsInSet
	|			 AND TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet
	|			 AND TemporaryTableSets.Ref = Table.Ref
	|
	|	WHERE
	|		Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|		OR (Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|	        AND TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents),
	|	                                                                              VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TemporaryTableSets.Ref AS Ref,
	|		TemporaryTableSets.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption AS SetPricingOption,
	|		TemporaryTableSets.ProductsInSet AS ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet AS ItemVariantOfSet,
	|		FALSE AS TheseAreComponents,
	|		TRUE AS IsRecordsSet,
	|		TemporaryTableSets.LineNumber AS LineNumber,
	|		TemporaryTableSets.ProductsInSet AS Products,
	|		TemporaryTableSets.Count AS Count,
	|		TemporaryTableSets.NumberOfPackages AS NumberOfPackages,
	|		CASE WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|				(TemporaryTableSets.Sum) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|			ELSE
	|				0
	|		END AS Price,
	|		TemporaryTableSets.Sum AS Sum,
	|		TemporaryTableSets.ProductsInSet.VATRate AS VATRate,
	|		TemporaryTableSets.VATAmount AS VATAmount,
	|		TemporaryTableSets.ItemVariantOfSet AS Characteristic,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|		"""" AS Content
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|	                                                           VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
	|
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Ref AS Ref,
	|		VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef) AS PresentationOptionInPrintForms,
	|		VALUE(Enum.SetPriceCalculationOptions.EmptyRef) AS SetPricingOption,
	|		UNDEFINED AS ProductsInSet,
	|		UNDEFINED AS ItemVariantOfSet,
	|		FALSE AS TheseAreComponents,
	|		FALSE AS IsRecordsSet,
	|		Table.LineNumber AS LineNumber,
	|		UNDEFINED AS Products,
	|		0 AS Count,
	|		0 AS NumberOfPackages,
	|		0 AS Price,
	|		Table.AdjustmentSum AS Sum,
	|		Table.VATRate AS VATRate,
	|		Table.SumOfVATAdjustments AS VATAmount,
	|		UNDEFINED AS Characteristic,
	|		UNDEFINED AS Package,
	|		Table.ReasonForAdjustment AS Content
	|	FROM
	|		Document.SaleAdjustment.ARAPAdjustment AS Table
	|	WHERE
	|		Table.Ref IN(&ObjectsArray)
	|		
	|) AS Goods
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsOfPresentationSet
	|	ON (Goods.ProductsInSet = ProductsOfPresentationSet.Ref
	|			AND ProductsOfPresentationSet.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS CharacteristicsOfProductOfPresentationSet
	|	ON (Goods.ItemVariantOfSet = CharacteristicsOfProductOfPresentationSet.Ref
	|			AND CharacteristicsOfProductOfPresentationSet.LanguageCode = &LanguageCode)
	|
	|ORDER BY
	|	Goods.LineNumber,
	|	IsRecordsSet DESC
	|";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
	
	If ValueIsFilled(LanguageCode)
		And Not LanguageCode = Common.DefaultLanguageCode() Then
		
		PackageNameUnitsOfMeasurement = "InternationalAbbreviation";
		
	Else
		
		PackageNameUnitsOfMeasurement = "Description";
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&QueryTextUnitOfMeasureDescription",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			PackageNameUnitsOfMeasurement,
			"Goods.Package",
			"Goods.Products"));
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("DisplayBasicUnitsOfMeasureInPrintForms", Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get());
	Query.SetParameter("DebitNote", DebitCreditNote = "DebitNote");
	Query.SetParameter("CreditNote", DebitCreditNote = "CreditNote");
	Query.SetParameter("LanguageCode", LanguageCode);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[RequestResultsPackage.Count() - 1]);
	
	Return DataStructureForPrinting;
	
EndFunction

#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map of KeyAndValue- list of Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites
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
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", " Reverse Address";
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

#Region Other

#Region VATAccounting

Function ParametersForRegisteringInvoicesReceived(Document) Export
	
	Attributes = New Structure("Ref, Date, Counterparty, Organization, VATTaxation, AdjustmentKind");
	
	If TypeOf(Document) = Type("DocumentRef.SaleAdjustment") Then
		Attributes = Common.ObjectAttributesValues(Document, Attributes);
	Else
		FillPropertyValues(Attributes, Document);
	EndIf;
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	RegistrationParameters.Ref = Attributes.Ref;
	RegistrationParameters.Date = Attributes.Date;
	RegistrationParameters.Organization = Attributes.Organization;
	RegistrationParameters.Counterparty = Attributes.Counterparty;
	RegistrationParameters.VATTaxation = Attributes.VATTaxation;
	If Attributes.AdjustmentKind = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods Then
		RegistrationParameters.ReturnOfGoodsFromVATPayer = True;
	EndIf;
	
	Return RegistrationParameters;
	
EndFunction

Function ParametersForRegisteringInvoicesIssued(Document) Export
	
	Attributes = New Structure("Ref, Date, Counterparty, Organization, VATTaxation, AdjustmentKind, DocumentBasis, BusinessOperation");
	
	If TypeOf(Document) = Type("DocumentRef.SaleAdjustment") Then
		Attributes = Common.ObjectAttributesValues(Document, Attributes);
	Else
		FillPropertyValues(Attributes, Document);
	EndIf;
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	RegistrationParameters.Ref = Attributes.Ref;
	RegistrationParameters.Date = Attributes.Date;
	RegistrationParameters.Organization = Attributes.Organization;
	RegistrationParameters.Counterparty = Attributes.Counterparty;
	RegistrationParameters.VATTaxation = Attributes.VATTaxation;
	If Attributes.AdjustmentKind = Enums.BusinessTransactions.ErrorCorrection Then
		RegistrationParameters.ErrorCorrection = True;
	ElsIf Attributes.AdjustmentKind = Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties Then
		RegistrationParameters.AdjustmentUnderApprovalOfParties = True;
	ElsIf Attributes.AdjustmentKind = Enums.BusinessTransactions.SaleOfOverdeliveredGoods Then
		RegistrationParameters.GoodsSales = True;
	EndIf;
	RegistrationParameters.TransferOfTitleToGoods = (Attributes.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods);
	RegistrationParameters.SalesViaCommissionAgent = ConsignmentSalesServer.SalesViaCommissionAgent(
												EconomicOperationOfFoundationDocument(Attributes.DocumentBasis));
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

// Returns a collection of parameters for determining the availability of articles and analytics, filled with default values.
//
// Returns:
//	Structure - a collection containing the following properties:
//		* DocumentDate - Date - document date.
//		* BusinessOperation - EnumRef.BusinessTransactions - the business operation of the document
//																				or the type of adjustment.
//		* AdjustingEntryType - EnumRef.AdjustingEntryTypes - type of adjustment document.
//		* DocumentBasis - DocumentRef, Undefined - link to the document basis.
//		* RecordInOtherIncome - Boolean - a sign of the need to reflect information on other income.
//		* ToExpenseAs - Boolean - indicates whether information should be charged to expenses.
//		* SaleAdjustment2_5 - Boolean - the value of the document Attribute.
//		* RecordInProfitLossOfPreviousYears - Boolean - the value of the document Attribute.
//		* AdjustTaxBaseOfPreviousPeriod - Boolean - the value of the document Attribute.
//
Function ParametersForDeterminingAvailabilityOfSelectionOfArticlesAndAnalytics() Export
	
	ParametersForDeterminingAvailability = New Structure;
	ParametersForDeterminingAvailability.Insert("DocumentDate",			Date(1, 1, 1));
	ParametersForDeterminingAvailability.Insert("BusinessOperation",	Enums.BusinessTransactions.EmptyRef());
	ParametersForDeterminingAvailability.Insert("AdjustingEntryType",		Enums.AdjustingEntryTypes.EmptyRef());
	ParametersForDeterminingAvailability.Insert("DocumentBasis",		Undefined);
	ParametersForDeterminingAvailability.Insert("RecordInOtherIncome",	False);
	ParametersForDeterminingAvailability.Insert("ToExpenseAs",		False);
	ParametersForDeterminingAvailability.Insert("SaleAdjustment2_5", False);
	ParametersForDeterminingAvailability.Insert("RecordInProfitLossOfPreviousYears", False);
	ParametersForDeterminingAvailability.Insert("AdjustTaxBaseOfPreviousPeriod", False);
	
	Return ParametersForDeterminingAvailability;
	
EndFunction

// Returns parameters for selecting articles in the document.
//
// Parameters:
//	ParametersForDeterminingAvailability - Structure:
//	* BusinessOperation - EnumRef.BusinessTransactions - Business operation of the document (type of Correction)
//	* DocumentBasis - DocumentRef - The document Foundation
//	* DocumentDate - Date - Document date
//	* RecordInOtherIncome - Boolean
//	* ToExpenseAs - Boolean
//	* AdjustingEntryType - EnumRef.AdjustingEntryTypes - type of adjustment document.
//	* SaleAdjustment2_5 - Boolean - the value of the document Attribute.
//	* RecordInProfitLossOfPreviousYears - Boolean - the value of the document Attribute.
//	* AdjustTaxBaseOfPreviousPeriod - Boolean - the value of the document Attribute.
//
// Returns:
//	Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions - 
//
Function ItemsAndDimensionsSelectionParameters(ParametersForDeterminingAvailability) Export
	
	ArrayOfSelectionParameters = New Array;
	AdjustmentOfServicesOfOtherAssetsOfCurPeriod = False;
	
	OtherAssetServiceAdjustment = False;
	LastPeriodAdjustment = False;
	CurPeriodAdjustment = True;
	If ParametersForDeterminingAvailability.Property("DocumentBasis") And ValueIsFilled(ParametersForDeterminingAvailability.DocumentBasis) Then
		SetPrivilegedMode(True);
		ReferenceDocumentDateForCertificate = Common.ObjectAttributeValue(ParametersForDeterminingAvailability.DocumentBasis, "Date");
		SetPrivilegedMode(False);
		DocumentDate = ?(ValueIsFilled(ParametersForDeterminingAvailability.DocumentDate), ParametersForDeterminingAvailability.DocumentDate, CurrentSessionDate());
		LastPeriodAdjustment = BegOfYear(DocumentDate) > BegOfYear(ReferenceDocumentDateForCertificate);
		CurPeriodAdjustment = Not LastPeriodAdjustment;
		OtherAssetServiceAdjustment = TypeOf(ParametersForDeterminingAvailability.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServicesAndAssets")
											Or ParametersForDeterminingAvailability.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
		If OtherAssetServiceAdjustment
			And Not LastPeriodAdjustment Then
			AdjustmentOfServicesOfOtherAssetsOfCurPeriod = True;
		EndIf;
	EndIf;
	
	AdjustingGiverSReport = False;
	AdjustingGiverSReport = TypeOf(ParametersForDeterminingAvailability.DocumentBasis) = Type("DocumentRef.ReportToMaterialProvider2_5");
	
	CorrectionOrAgreementOfParties = ParametersForDeterminingAvailability.Property("BusinessOperation") And 
					Not (ParametersForDeterminingAvailability.BusinessOperation = Enums.BusinessTransactions.SaleOfOverdeliveredGoods
					Or ParametersForDeterminingAvailability.BusinessOperation = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods);
					
	AvailableItemsOfIncomeExpenses = (CorrectionOrAgreementOfParties And (LastPeriodAdjustment Or (CurPeriodAdjustment And Not OtherAssetServiceAdjustment))) Or Not (OtherAssetServiceAdjustment Or CorrectionOrAgreementOfParties);
	
	HideItemsOfIncomeExpenses = CorrectionOrAgreementOfParties And AdjustmentOfServicesOfOtherAssetsOfCurPeriod;
	
	RecordInOtherIncome = False;
	If ParametersForDeterminingAvailability.Property("RecordInOtherIncome") Then
		RecordInOtherIncome = ParametersForDeterminingAvailability.RecordInOtherIncome;
	EndIf;
	ToExpenseAs = False;
	If ParametersForDeterminingAvailability.Property("ToExpenseAs") Then
		ToExpenseAs = ParametersForDeterminingAvailability.ToExpenseAs;
	EndIf;
	
	#Region IncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object";
	ChoiceParameters.AssetRef = "IncomeItem";
	
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = HideItemsOfIncomeExpenses;
	
	If Not (AvailableItemsOfIncomeExpenses And RecordInOtherIncome) Then
		ChoiceParameters.AvailabilityByOperation = False;
	EndIf;
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.AssetRef.Add("SourceOfIncomeAdditionally");
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItemAdjustmentOfDebt");
		
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("AdditionalRevenueAnalytics");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("RevenueAnalyticsDebtAdjustment");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = HideItemsOfIncomeExpenses;
	
	If Not (AvailableItemsOfIncomeExpenses And ToExpenseAs) Then
		ChoiceParameters.AvailabilityByOperation = False;
	EndIf;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.AssetRef.Add("ItemOfExpenditureAdditional");
	ChoiceParameters.FormItems.AssetRef.Add("ItemOfExpenditureAdjustmentOfArrears");
	
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("AdditionalCostAnalysis");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("CostAnalysisDebtAdjustment");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region GoodsIncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object.Goods";
	ChoiceParameters.AssetRef = "IncomeItem";
	
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = True;
	ChoiceParameters.HideInaccessibleArticlesInRows = True;
	
	ChoiceParameters.AvailabilityByOperation =
		AdjustmentOfServicesOfOtherAssetsOfCurPeriod
			Or OtherAssetServiceAdjustment
				And ParametersForDeterminingAvailability.SaleAdjustment2_5
				And (Not ParametersForDeterminingAvailability.RecordInProfitLossOfPreviousYears
					Or ParametersForDeterminingAvailability.AdjustTaxBaseOfPreviousPeriod);
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	
	ChoiceParameters.FormItems.AssetRef.Add("GoodsIncomeItem");
	
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("GoodsDimensionOfRevenue");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region DiscrepanciesIncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object.Discrepancies";
	ChoiceParameters.AssetRef = "IncomeItem";
	
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = True;
	ChoiceParameters.HideInaccessibleArticlesInRows = True;	
	
	ChoiceParameters.AvailabilityByOperation =
		AdjustmentOfServicesOfOtherAssetsOfCurPeriod
			Or OtherAssetServiceAdjustment
				And ParametersForDeterminingAvailability.SaleAdjustment2_5
				And (Not ParametersForDeterminingAvailability.RecordInProfitLossOfPreviousYears
					Or ParametersForDeterminingAvailability.AdjustTaxBaseOfPreviousPeriod);
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	
	ChoiceParameters.FormItems.AssetRef.Add("DiscrepanciesIncomeItem");
	
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DiscrepanciesDimensionOfRevenue");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region GoodsExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object.Goods";
	ChoiceParameters.AssetRef      = "ExpenseItem";
	ChoiceParameters.ArticleType   = "ArticleType";
	
	ChoiceParameters.AvailabilityByOperation = AdjustingGiverSReport;
	ChoiceParameters.HideInaccessibleArticlesInRows = True;
	
	ChoiceParameters.ChoosingExpenseItem		   = AdjustingGiverSReport;
	ChoiceParameters.DimensionOfExpenses		   = "DimensionOfExpenses";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = AdjustingGiverSReport;
	ChoiceParameters.AssetsLiabilitiesDimension   = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	
	ChoiceParameters.FormItems.AssetRef.Add("GoodsExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("GoodsDimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("GoodsAssetsLiabilitiesDimension");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region DiscrepanciesExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object.Discrepancies";
	ChoiceParameters.AssetRef      = "ExpenseItem";
	ChoiceParameters.ArticleType   = "ArticleType";
	
	ChoiceParameters.AvailabilityByOperation = AdjustingGiverSReport;
	ChoiceParameters.HideInaccessibleArticlesInRows = True;
	
	ChoiceParameters.ChoosingExpenseItem		   = AdjustingGiverSReport;
	ChoiceParameters.DimensionOfExpenses		   = "DimensionOfExpenses";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = AdjustingGiverSReport;
	ChoiceParameters.AssetsLiabilitiesDimension   = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	
	ChoiceParameters.FormItems.AssetRef.Add("DiscrepanciesExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DiscrepanciesDimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DiscrepanciesAssetsLiabilitiesDimension");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	Return ArrayOfSelectionParameters;
	
EndFunction

// Returns parameters for selecting articles in the implementation adjustment document before entering Balances.
//
// Parameters:
//	ParametersForDeterminingAvailability - Structure:
//	* BusinessOperation - EnumRef.BusinessTransactions - Business operation of the document (type of Correction)
//	* DocumentBasis - DocumentRef - The document Foundation
//	* DocumentDate - Date - Document date
//	* RecordInOtherIncome - Boolean
//	* ToExpenseAs - Boolean
//	* AdjustingEntryType - EnumRef.AdjustingEntryTypes - type of adjustment document.
//
// Returns:
//	Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions - 
//
Function OptionsForSelectingArticlesAndAnalyticsBeforeEnteringBalances(ParametersForDeterminingAvailability) Export
	
	ArrayOfSelectionParameters = New Array;
	AdjustmentOfServicesOfOtherAssetsOfCurPeriod = False;
	
	OtherAssetServiceAdjustment = False;
	LastPeriodAdjustment = False;
	CurPeriodAdjustment = True;
	If ParametersForDeterminingAvailability.Property("DocumentBasis") And ValueIsFilled(ParametersForDeterminingAvailability.DocumentBasis) Then
		SetPrivilegedMode(True);
		ReferenceDocumentDateForCertificate = Common.ObjectAttributeValue(ParametersForDeterminingAvailability.DocumentBasis, "Date");
		SetPrivilegedMode(False);
		DocumentDate = ?(ValueIsFilled(ParametersForDeterminingAvailability.DocumentDate), ParametersForDeterminingAvailability.DocumentDate, CurrentSessionDate());
		LastPeriodAdjustment = BegOfYear(DocumentDate) > BegOfYear(ReferenceDocumentDateForCertificate);
		CurPeriodAdjustment = Not LastPeriodAdjustment;
		OtherAssetServiceAdjustment = ParametersForDeterminingAvailability.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
		If OtherAssetServiceAdjustment
			And Not LastPeriodAdjustment Then
			AdjustmentOfServicesOfOtherAssetsOfCurPeriod = True;
		EndIf;
	EndIf;
	
	CorrectionOrAgreementOfParties = ParametersForDeterminingAvailability.Property("BusinessOperation") And 
					Not (ParametersForDeterminingAvailability.BusinessOperation = Enums.BusinessTransactions.SaleOfOverdeliveredGoods
					Or ParametersForDeterminingAvailability.BusinessOperation = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods);
					
	AvailableItemsOfIncomeExpenses = (CorrectionOrAgreementOfParties And (LastPeriodAdjustment Or (CurPeriodAdjustment And Not OtherAssetServiceAdjustment))) Or Not (OtherAssetServiceAdjustment Or CorrectionOrAgreementOfParties);
	
	HideItemsOfIncomeExpenses = CorrectionOrAgreementOfParties And AdjustmentOfServicesOfOtherAssetsOfCurPeriod;
	
	RecordInOtherIncome = False;
	If ParametersForDeterminingAvailability.Property("RecordInOtherIncome") Then
		RecordInOtherIncome = ParametersForDeterminingAvailability.RecordInOtherIncome;
	EndIf;
	ToExpenseAs = False;
	If ParametersForDeterminingAvailability.Property("ToExpenseAs") Then
		ToExpenseAs = ParametersForDeterminingAvailability.ToExpenseAs;
	EndIf;
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("ThisIsObjectOnForm", True);
	
	#Region IncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object";
	ChoiceParameters.AssetRef = "IncomeItem";
	
	ChoiceParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = HideItemsOfIncomeExpenses;
	
	If Not (AvailableItemsOfIncomeExpenses And RecordInOtherIncome) Then
		ChoiceParameters.AvailabilityByOperation = False;
	EndIf;
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
		
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	
	ChoiceParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = HideItemsOfIncomeExpenses;
	
	If Not (AvailableItemsOfIncomeExpenses And ToExpenseAs) Then
		ChoiceParameters.AvailabilityByOperation = False;
	EndIf;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region AdjustmentTableIncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "AdjustmentTable";
	ChoiceParameters.AssetRef = "IncomeItem";
	
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = True;
	ChoiceParameters.HideInaccessibleArticlesInRows = True;
	
	If Not AdjustmentOfServicesOfOtherAssetsOfCurPeriod Then
		ChoiceParameters.AvailabilityByOperation = False;
	EndIf;
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	
	ChoiceParameters.FormItems.AssetRef.Add("AdjustmentTableIncomeItem");
	
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("AdjustmentTableDimensionOfRevenue");
	
	DetailsPresentations = New Structure;
	DetailsPresentations.Insert("IncomeItem",				NStr("vi = 'Dạng thu nhập';
																	|ru = 'Статья доходов';
																	|en = 'Income item'; fa = 'قلم درآمد';
																	|it = 'Voce dei ricavi';
																	|pl = 'Rodzaj przychodów';
																	|tr = 'Gelir kalemi'"));
	DetailsPresentations.Insert("DimensionOfRevenue",			NStr("vi = 'Đối tượng phân tích thu nhập';
																		|ru = 'Аналитика доходов';
																		|en = 'Income dimension'; fa = 'بُعد درآمد';
																		|it = 'Analitica dei ricavi';
																		|pl = 'Analityka dochodów';
																		|tr = 'Gelir boyutu'"));
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("PresentationOfTS",			NStr("vi = 'Dữ liệu điều chỉnh';
																	|ru = 'Данные корректировки';
																	|en = 'Correction data'; fa = 'داده‌های اصلاح';
																	|it = 'Dati di correzione';
																	|pl = 'Dane korekty';
																	|tr = 'Düzeltme verileri'"));
	AdditionalParameters.Insert("DetailsPresentations",	DetailsPresentations);
	
	ChoiceParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	Return ArrayOfSelectionParameters;
	
EndFunction

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
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Department)
	|	AND (VALUETYPE(DocumentBasis) = TYPE(Document.CustomerInvoiceServices)
	|		OR VALUETYPE(DocumentBasis) = TYPE(Document.CustomerInvoiceServicesAndAssets)
	|		OR AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
	|		OR ValueAllowed(Warehouse)
	|	)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = ThisList.Partner
	|
	|LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|	ON ContactPersonsForPartners.Owner = ThisList.Partner
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersContactPersons
	|	ON ExternalUsersContactPersons.AuthorizationObject = ContactPersonsForPartners.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)
	|	OR ValueAllowed(ExternalUsersContactPersons.Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

// Initializes the collection with the names of Attributes that depend on the document type-the basis and the type of document correction.
//
// Parameters:
//	DocumentBasis - DocumentRef - The document on the basis of which the correction was introduced.
//	ArrayOfAllProps - Array of String - names of Attributes that do not depend on the underlying document.
//	ArrayOfOperationDetails - Array of String - the names of the Attributes that depend on the underlying document.
//	AdjustingEntryType - EnumRef.AdjustingEntryTypes, Undefined - type of adjustment document.
//
Procedure FillInNamesOfDetailsOnBasis(DocumentBasis,
												ArrayOfAllProps,
												ArrayOfOperationDetails,
												AdjustingEntryType = Undefined) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("DocumentBasis");
	ArrayOfAllProps.Add("Warehouse");
	ArrayOfAllProps.Add("Terms");
	ArrayOfAllProps.Add("Contract");
	ArrayOfAllProps.Add("BusinessUnit");
	ArrayOfAllProps.Add("IncomeItem");
	ArrayOfAllProps.Add("DimensionOfRevenue");
	ArrayOfAllProps.Add("BusinessUnitExpenses");
	ArrayOfAllProps.Add("ExpenseItem");
	ArrayOfAllProps.Add("DimensionOfExpenses");
	ArrayOfAllProps.Add("IssuiedBy");
	ArrayOfAllProps.Add("IssuiedByJobTitle");
	ArrayOfAllProps.Add("GoodsRecipient");
	ArrayOfAllProps.Add("Shipper");
	ArrayOfAllProps.Add("CompanyBankAccount");
	ArrayOfAllProps.Add("CounterpartyBankAccount");
	ArrayOfAllProps.Add("ShipperBankAccount");
	ArrayOfAllProps.Add("GoodsRecipientBankAccount");
	ArrayOfAllProps.Add("DeliveryAddress");
	ArrayOfAllProps.Add("PowerOfAttorneyNumber");
	ArrayOfAllProps.Add("PowerOfAttorneyDate");
	ArrayOfAllProps.Add("LetterOfAuthorityIssuedBy");
	ArrayOfAllProps.Add("PowerOfAttorneyPerson");
	ArrayOfAllProps.Add("CustomerCounterparty");
	ArrayOfAllProps.Add("CustomerPartner");
	ArrayOfAllProps.Add("CustomerContract");
	ArrayOfAllProps.Add("Goods.Products");
	ArrayOfAllProps.Add("Goods.Characteristic");
	ArrayOfAllProps.Add("Goods.Purpose");
	ArrayOfAllProps.Add("Goods.Content");
	ArrayOfAllProps.Add("Goods.Package");
	ArrayOfAllProps.Add("Goods.NumberOfPackages");
	ArrayOfAllProps.Add("Goods.PriceKind");
	ArrayOfAllProps.Add("Goods.SalesOrder");
	ArrayOfAllProps.Add("Goods.RowCode");
	ArrayOfAllProps.Add("Goods.Warehouse");
	ArrayOfAllProps.Add("Goods.Series");
	ArrayOfAllProps.Add("Goods.BatchesIndicationStatus");
	ArrayOfAllProps.Add("Goods.IncomeItem");
	ArrayOfAllProps.Add("Goods.DimensionOfRevenue");
	ArrayOfAllProps.Add("Goods.ExpenseItem");
	ArrayOfAllProps.Add("Goods.DimensionOfExpenses");
	ArrayOfAllProps.Add("Goods.AssetsLiabilitiesDimension");
	ArrayOfAllProps.Add("Goods.ToExpenseAs");
	
	ArrayOfAllProps.Add("Discrepancies.Series");
	ArrayOfAllProps.Add("Discrepancies.Products");
	ArrayOfAllProps.Add("Discrepancies.Characteristic");
	ArrayOfAllProps.Add("Discrepancies.Purpose");
	ArrayOfAllProps.Add("Discrepancies.Content");
	ArrayOfAllProps.Add("Discrepancies.Package");
	ArrayOfAllProps.Add("Discrepancies.NumberOfPackages");
	ArrayOfAllProps.Add("Discrepancies.SalesOrder");
	ArrayOfAllProps.Add("Discrepancies.RowCode");
	ArrayOfAllProps.Add("Discrepancies.Warehouse");
	ArrayOfAllProps.Add("Discrepancies.IncomeItem");
	ArrayOfAllProps.Add("Discrepancies.DimensionOfRevenue");
	ArrayOfAllProps.Add("Discrepancies.ExpenseItem");
	ArrayOfAllProps.Add("Discrepancies.DimensionOfExpenses");
	ArrayOfAllProps.Add("Discrepancies.AssetsLiabilitiesDimension");
	ArrayOfAllProps.Add("Discrepancies.ToExpenseAs");
	
	ArrayOfOperationDetails = New Array;
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
		
		ArrayOfOperationDetails.Add("DocumentBasis");
		ArrayOfOperationDetails.Add("Warehouse");
		ArrayOfOperationDetails.Add("Terms");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("CustomerCounterparty");
		ArrayOfOperationDetails.Add("CustomerPartner");
		ArrayOfOperationDetails.Add("CustomerContract");
		ArrayOfOperationDetails.Add("BusinessUnit");
		ArrayOfOperationDetails.Add("IncomeItem");
		ArrayOfOperationDetails.Add("DimensionOfRevenue");
		ArrayOfOperationDetails.Add("BusinessUnitExpenses");
		ArrayOfOperationDetails.Add("ExpenseItem");
		ArrayOfOperationDetails.Add("DimensionOfExpenses");
		ArrayOfOperationDetails.Add("IssuiedBy");
		ArrayOfOperationDetails.Add("IssuiedByJobTitle");
		ArrayOfOperationDetails.Add("GoodsRecipient");
		ArrayOfOperationDetails.Add("Shipper");
		ArrayOfOperationDetails.Add("CompanyBankAccount");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("ShipperBankAccount");
		ArrayOfOperationDetails.Add("GoodsRecipientBankAccount");
		ArrayOfOperationDetails.Add("DeliveryAddress");
		ArrayOfOperationDetails.Add("PowerOfAttorneyNumber");
		ArrayOfOperationDetails.Add("PowerOfAttorneyDate");
		ArrayOfOperationDetails.Add("LetterOfAuthorityIssuedBy");
		ArrayOfOperationDetails.Add("PowerOfAttorneyPerson");
		
		ArrayOfOperationDetails.Add("Goods.Products");
		ArrayOfOperationDetails.Add("Goods.Characteristic");
		ArrayOfOperationDetails.Add("Goods.Purpose");
		ArrayOfOperationDetails.Add("Goods.Package");
		ArrayOfOperationDetails.Add("Goods.NumberOfPackages");
		ArrayOfOperationDetails.Add("Goods.PriceKind");
		ArrayOfOperationDetails.Add("Goods.SalesOrder");
		ArrayOfOperationDetails.Add("Goods.RowCode");
		ArrayOfOperationDetails.Add("Goods.Warehouse");
		ArrayOfOperationDetails.Add("Goods.Series");
		ArrayOfOperationDetails.Add("Goods.BatchesIndicationStatus");
		ArrayOfOperationDetails.Add("Discrepancies.Series");
		ArrayOfOperationDetails.Add("Discrepancies.Products");
		ArrayOfOperationDetails.Add("Discrepancies.Characteristic");
		ArrayOfOperationDetails.Add("Discrepancies.Purpose");
		ArrayOfOperationDetails.Add("Discrepancies.Package");
		ArrayOfOperationDetails.Add("Discrepancies.NumberOfPackages");
		ArrayOfOperationDetails.Add("Discrepancies.SalesOrder");
		ArrayOfOperationDetails.Add("Discrepancies.RowCode");
		ArrayOfOperationDetails.Add("Discrepancies.Warehouse");
		
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoiceServices") Then
		
		ArrayOfOperationDetails.Add("DocumentBasis");
		ArrayOfOperationDetails.Add("Terms");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("BusinessUnit");
		ArrayOfOperationDetails.Add("IncomeItem");
		ArrayOfOperationDetails.Add("DimensionOfRevenue");
		ArrayOfOperationDetails.Add("BusinessUnitExpenses");
		ArrayOfOperationDetails.Add("ExpenseItem");
		ArrayOfOperationDetails.Add("DimensionOfExpenses");
		ArrayOfOperationDetails.Add("Goods.Products");
		ArrayOfOperationDetails.Add("Goods.Characteristic");
		ArrayOfOperationDetails.Add("Goods.Purpose");
		ArrayOfOperationDetails.Add("Goods.NumberOfPackages");
		ArrayOfOperationDetails.Add("Goods.Content");
		ArrayOfOperationDetails.Add("Goods.PriceKind");
		ArrayOfOperationDetails.Add("Goods.SalesOrder");
		ArrayOfOperationDetails.Add("Goods.RowCode");
		ArrayOfOperationDetails.Add("Discrepancies.Products");
		ArrayOfOperationDetails.Add("Discrepancies.Characteristic");
		ArrayOfOperationDetails.Add("Discrepancies.Purpose");
		ArrayOfOperationDetails.Add("Discrepancies.Content");
		ArrayOfOperationDetails.Add("Discrepancies.SalesOrder");
		ArrayOfOperationDetails.Add("Discrepancies.RowCode");
		
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
		
		ArrayOfOperationDetails.Add("DocumentBasis");
		ArrayOfOperationDetails.Add("Terms");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("BusinessUnit");
		ArrayOfOperationDetails.Add("IncomeItem");
		ArrayOfOperationDetails.Add("DimensionOfRevenue");
		ArrayOfOperationDetails.Add("BusinessUnitExpenses");
		ArrayOfOperationDetails.Add("ExpenseItem");
		ArrayOfOperationDetails.Add("DimensionOfExpenses");
		ArrayOfOperationDetails.Add("Goods.Content");
		ArrayOfOperationDetails.Add("Goods.NumberOfPackages");
		ArrayOfOperationDetails.Add("Goods.Package");
		ArrayOfOperationDetails.Add("Discrepancies.Content");
		ArrayOfOperationDetails.Add("Discrepancies.Package");
		ArrayOfOperationDetails.Add("Discrepancies.NumberOfPackages");
		ArrayOfOperationDetails.Add("Goods.IncomeItem");
		ArrayOfOperationDetails.Add("Goods.DimensionOfRevenue");
		ArrayOfOperationDetails.Add("Discrepancies.IncomeItem");
		ArrayOfOperationDetails.Add("Discrepancies.DimensionOfRevenue");
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		
		ArrayOfOperationDetails.Add("DocumentBasis");
		ArrayOfOperationDetails.Add("Warehouse");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("Goods.Products");
		ArrayOfOperationDetails.Add("Goods.Characteristic");
		ArrayOfOperationDetails.Add("Goods.Purpose");
		ArrayOfOperationDetails.Add("Goods.Package");
		ArrayOfOperationDetails.Add("Goods.NumberOfPackages");
		ArrayOfOperationDetails.Add("Goods.PriceKind");
		ArrayOfOperationDetails.Add("Goods.SalesOrder");
		ArrayOfOperationDetails.Add("Goods.RowCode");
		ArrayOfOperationDetails.Add("Goods.Warehouse");
		ArrayOfOperationDetails.Add("Goods.Series");
		ArrayOfOperationDetails.Add("Goods.ExpenseItem");
		ArrayOfOperationDetails.Add("Goods.DimensionOfExpenses");
		ArrayOfOperationDetails.Add("Goods.AssetsLiabilitiesDimension");
		ArrayOfOperationDetails.Add("Goods.ToExpenseAs");

		ArrayOfOperationDetails.Add("Goods.BatchesIndicationStatus");
		ArrayOfOperationDetails.Add("Discrepancies.Products");
		ArrayOfOperationDetails.Add("Discrepancies.Characteristic");
		ArrayOfOperationDetails.Add("Discrepancies.Purpose");
		ArrayOfOperationDetails.Add("Discrepancies.Package");
		ArrayOfOperationDetails.Add("Discrepancies.Series");
		ArrayOfOperationDetails.Add("Discrepancies.SalesOrder");
		ArrayOfOperationDetails.Add("Discrepancies.NumberOfPackages");
		ArrayOfOperationDetails.Add("Discrepancies.SalesOrder");
		ArrayOfOperationDetails.Add("Discrepancies.RowCode");
		ArrayOfOperationDetails.Add("Discrepancies.Warehouse");
		ArrayOfOperationDetails.Add("Discrepancies.ExpenseItem");
		ArrayOfOperationDetails.Add("Discrepancies.DimensionOfExpenses");
		ArrayOfOperationDetails.Add("Discrepancies.AssetsLiabilitiesDimension");
		ArrayOfOperationDetails.Add("Discrepancies.ToExpenseAs");
		
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.SourceDocument") Then
		
		ArrayOfOperationDetails.Add("DocumentBasis");
		ArrayOfOperationDetails.Add("Terms");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("BusinessUnit");
		ArrayOfOperationDetails.Add("IncomeItem");
		ArrayOfOperationDetails.Add("DimensionOfRevenue");
		ArrayOfOperationDetails.Add("BusinessUnitExpenses");
		ArrayOfOperationDetails.Add("ExpenseItem");
		ArrayOfOperationDetails.Add("DimensionOfExpenses");
		
		ArrayOfOperationDetails.Add("Goods.Content");
		ArrayOfOperationDetails.Add("Goods.Package");
		ArrayOfOperationDetails.Add("Goods.NumberOfPackages");
		ArrayOfOperationDetails.Add("Goods.IncomeItem");
		ArrayOfOperationDetails.Add("Goods.DimensionOfRevenue");
		
		ArrayOfOperationDetails.Add("Discrepancies.Content");
		ArrayOfOperationDetails.Add("Discrepancies.Package");
		ArrayOfOperationDetails.Add("Discrepancies.NumberOfPackages");
		ArrayOfOperationDetails.Add("Discrepancies.IncomeItem");
		ArrayOfOperationDetails.Add("Discrepancies.DimensionOfRevenue");
		
		If AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices Then
			ArrayOfOperationDetails.Add("Warehouse");
			ArrayOfOperationDetails.Add("IssuiedBy");
			ArrayOfOperationDetails.Add("IssuiedByJobTitle");
			ArrayOfOperationDetails.Add("GoodsRecipient");
			ArrayOfOperationDetails.Add("Shipper");
			ArrayOfOperationDetails.Add("CompanyBankAccount");
			ArrayOfOperationDetails.Add("CounterpartyBankAccount");
			ArrayOfOperationDetails.Add("ShipperBankAccount");
			ArrayOfOperationDetails.Add("GoodsRecipientBankAccount");
			ArrayOfOperationDetails.Add("DeliveryAddress");
			ArrayOfOperationDetails.Add("PowerOfAttorneyNumber");
			ArrayOfOperationDetails.Add("PowerOfAttorneyDate");
			ArrayOfOperationDetails.Add("LetterOfAuthorityIssuedBy");
			ArrayOfOperationDetails.Add("PowerOfAttorneyPerson");
			
			ArrayOfOperationDetails.Add("Goods.Products");
			ArrayOfOperationDetails.Add("Goods.Characteristic");
			ArrayOfOperationDetails.Add("Goods.Purpose");
			ArrayOfOperationDetails.Add("Goods.Series");
			ArrayOfOperationDetails.Add("Goods.PriceKind");
			ArrayOfOperationDetails.Add("Goods.SalesOrder");
			ArrayOfOperationDetails.Add("Goods.RowCode");
			ArrayOfOperationDetails.Add("Goods.Warehouse");
			ArrayOfOperationDetails.Add("Goods.BatchesIndicationStatus");
			
			ArrayOfOperationDetails.Add("Goods.CCDNumber");
			ArrayOfOperationDetails.Add("Goods.QuantityByGBRN");
			
			ArrayOfOperationDetails.Add("Discrepancies.Products");
			ArrayOfOperationDetails.Add("Discrepancies.Characteristic");
			ArrayOfOperationDetails.Add("Discrepancies.Purpose");
			ArrayOfOperationDetails.Add("Discrepancies.Series");
			ArrayOfOperationDetails.Add("Discrepancies.SalesOrder");
			ArrayOfOperationDetails.Add("Discrepancies.RowCode");
			ArrayOfOperationDetails.Add("Discrepancies.Warehouse");
			
			ArrayOfOperationDetails.Add("Discrepancies.CCDNumber");
			ArrayOfOperationDetails.Add("Discrepancies.QuantityByGBRN");

		EndIf;
		
	Else
		ArrayOfOperationDetails.Add("BusinessUnit");
		ArrayOfOperationDetails.Add("IncomeItem");
		ArrayOfOperationDetails.Add("DimensionOfRevenue");
		ArrayOfOperationDetails.Add("BusinessUnitExpenses");
		ArrayOfOperationDetails.Add("ExpenseItem");
		ArrayOfOperationDetails.Add("DimensionOfExpenses");
		ArrayOfOperationDetails.Add("CompanyBankAccount");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		
	EndIf;
	
EndProcedure

Procedure FillInProductsBasedOnSourceData(DocumentBasis, Goods, Discrepancies, DocumentRef = Undefined) Export
	
	TempTablesManager = New TempTablesManager;
	
	CreateTemporaryTableOfSourceData(TempTablesManager, DocumentBasis, DocumentRef);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = "
	|SELECT
	|	*
	|FROM RawData AS RawData
	|
	|ORDER BY
	|	RawData.LineNumber
	|";
	
	ProductData_7 = Query.Execute().Unload();
	
	If Not TypeOf(DocumentBasis) = Type("DocumentRef.SourceDocument")
		Or ProductData_7.Count() > 0 Then
		Goods.Load(ProductData_7);
		Discrepancies.Clear();
	EndIf;
	
EndProcedure

Procedure FillInGoodsAccordingToAcceptanceCertificate(Object, ThisIsReturnToPath = False) Export
	
	Object.Goods.Clear();
	
	SearchParameters = New Structure();
	SearchParameters.Insert("Action", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
	FoundRows = Object.DiscrepancyReportFollowingShipmentBaseDocument.Goods.FindRows(SearchParameters);
	
	// Two adjustments are introduced when the method of reflection in the act of discrepancies is to make an adjustment,
	// and the surplus is worked out by the option "Issue and return". In this case, the first adjustment is made to
	// make a surplus (the amount increases in the adjustment), and the second adjustment is to return the surplus
	// issued in the first adjustment "on the way". 
	// If the conditions described above are met for the act, plus there is a shortage that must be returned "on the way"
	// (action with the "Return" item) then all the lines that require the reflection option "Return to the path" will
	// be decorated in the second(!) adjustment.
	
	TwoAdjustmentsAreRequired =
		GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5")
		And FoundRows.Count() > 0
		And Object.DiscrepancyReportFollowingShipmentBaseDocument.DiscrepanciesPostingMethod <>
			Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.LineNumber AS LineNumber,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package,
	|	
	|	CASE WHEN &SaleOfOverdeliveredGoods THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages - CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|	WHEN &ReturnOfUnderdeliveredGoods THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages
	|	WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Action IN (&OptionsDocumentData) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	// The return adjustment is on the way and two adjustments need to be made
	|	WHEN &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|	WHEN &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages
	|	WHEN &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages
	// The return adjustment is on the way and it is NOT necessary to enter two adjustments
	|	WHEN &ThisIsReturnToPath
	|			AND NOT &TwoAdjustmentsAreRequired
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|	WHEN &ThisIsReturnToPath
	|			AND NOT &TwoAdjustmentsAreRequired THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	// THERE is NO adjustment for returning to the path and it is required to enter two adjustments
	|	WHEN NOT &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|	WHEN NOT &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages
	// THERE is NO adjustment to return to the path and IT is NOT required to enter two adjustments
	|	WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages > CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|			AND NOT CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder = UNDEFINED
	|			AND NOT CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode = 0 THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|	ELSE
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages
	|	END AS NumberOfPackages,
	|	
	|	CASE WHEN &SaleOfOverdeliveredGoods THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Count - CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument
	|	WHEN &ReturnOfUnderdeliveredGoods THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.Count
	|	WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Action IN (&OptionsDocumentData) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument
	// The return adjustment is on the way and two adjustments need to be made
	|	WHEN &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument
	|	WHEN &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Count
	|	WHEN &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Count
	// The return adjustment is on the way and it is NOT necessary to enter two adjustments
	|	WHEN &ThisIsReturnToPath
	|			AND NOT &TwoAdjustmentsAreRequired
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument
	|	WHEN &ThisIsReturnToPath
	|			AND NOT &TwoAdjustmentsAreRequired THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument
	// THERE is NO adjustment for returning to the path and it is required to enter two adjustments
	|	WHEN NOT &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument
	|	WHEN NOT &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Count
	// THERE is NO adjustment to return to the path and IT is NOT required to enter two adjustments
	|	WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Count > CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument
	|			AND NOT CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder = UNDEFINED
	|			AND NOT CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode = 0 THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument
	|	ELSE
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Count
	|	END AS Count,
	|	
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.PriceKind,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Price,
	|	
	|	CASE WHEN &SaleOfOverdeliveredGoods THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Sum - CertificateOfDiscrepanciesAfterShipmentOfGoods.SumByDocument
	|	WHEN &ReturnOfUnderdeliveredGoods THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.SumByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.Sum
	|	WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Action IN (&OptionsDocumentData) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.SumByDocument
	|	WHEN &ThisIsReturnToPath
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.SumByDocument
	|	WHEN &ThisIsReturnToPath THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Sum
	|	ELSE
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Sum
	|	END AS Sum,
	|	
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate,
	|
	|	CASE WHEN &ExportSale THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Products.FEACNCode 
	|	ELSE
	|		VALUE(Catalog.FEACN.EmptyRef)
	|	END AS FEACNCode,
	|	
	|	CASE WHEN &SaleOfOverdeliveredGoods THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmount - CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmountByDocument
	|	WHEN &ReturnOfUnderdeliveredGoods THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmountByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmount
	|	WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Action IN (&OptionsDocumentData) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmountByDocument
	// The return adjustment is on the way and two adjustments need to be made
	|	WHEN &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmountByDocument
	|	WHEN &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmount
	|	WHEN &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmount
	// The return adjustment is on the way and it is NOT necessary to enter two adjustments
	|	WHEN &ThisIsReturnToPath
	|			AND NOT &TwoAdjustmentsAreRequired
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmountByDocument
	|	WHEN &ThisIsReturnToPath
	|			AND NOT &TwoAdjustmentsAreRequired THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmountByDocument
	// THERE is NO adjustment for returning to the path and it is required to enter two adjustments
	|	WHEN NOT &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmountByDocument
	|	WHEN NOT &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmount
	// THERE is NO adjustment to return to the path and IT is NOT required to enter two adjustments
	|	ELSE
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmount
	|	END AS VATAmount,
	|	
	|	CASE WHEN &SaleOfOverdeliveredGoods THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVAT - CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVATByDocument
	|	WHEN &ReturnOfUnderdeliveredGoods THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVATByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVAT
	|	WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Action IN (&OptionsDocumentData) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVATByDocument
	// The return adjustment is on the way and two adjustments need to be made
	|	WHEN &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVATByDocument
	|	WHEN &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVAT
	|	WHEN &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVAT
	// The return adjustment is on the way and it is NOT necessary to enter two adjustments
	|	WHEN &ThisIsReturnToPath
	|			AND NOT &TwoAdjustmentsAreRequired
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVATByDocument
	|	WHEN &ThisIsReturnToPath
	|			AND NOT &TwoAdjustmentsAreRequired THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVATByDocument
	// THERE is NO adjustment for returning to the path and it is required to enter two adjustments
	|	WHEN NOT &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_) THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVATByDocument
	|	WHEN NOT &ThisIsReturnToPath
	|			AND &TwoAdjustmentsAreRequired THEN
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVAT
	// THERE is NO adjustment to return to the path and IT is NOT required to enter two adjustments
	|	ELSE
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVAT
	|	END AS AmountIncludingVAT,
	|	
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder,
	|	
	|	CASE WHEN &SaleOfOverdeliveredGoods THEN
	|		0
	|	ELSE
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode
	|	END AS RowCode,
	|	
	|	CASE
	|		WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE 
	|			CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse
	|	END AS Warehouse,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Department,
	|	CASE WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.BatchesIndicationStatus = 14
	|		THEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	CASE WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.BatchesIndicationStatus = 14
	|		THEN CertificateOfDiscrepanciesAfterShipmentOfGoods.BatchesIndicationStatus
	|		ELSE 0
	|	END AS BatchesIndicationStatus,
	|	
	|	CASE
	|		WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages > CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|				AND NOT (CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration)
	|					OR CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage))
	|				AND NOT CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder = VALUE(Document.SalesOrder.EmptyRef)
	|				AND NOT CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode = 0
	|				AND NOT &SaleOfOverdeliveredGoods
	|				AND NOT &ReturnOfUnderdeliveredGoods
	|			THEN CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages - CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|		ELSE 0
	|	END AS NumberOfPackagesOverOrder,
	|	
	|	CASE
	|		WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Count > CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument
	|				AND NOT (CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration)
	|					OR CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage))
	|				AND NOT CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder = VALUE(Document.SalesOrder.EmptyRef)
	|				AND NOT CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode = 0
	|				AND NOT &SaleOfOverdeliveredGoods
	|				AND NOT &ReturnOfUnderdeliveredGoods
	|			THEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Count - CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument
	|		ELSE 0
	|	END AS QuantityOverOrder,
	|	
	|	CASE
	|		WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService),
	|																				VALUE(Enum.ItemsTypes.Work_5))
	|			THEN CASE
	|					WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.Count > CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument
	|						THEN VALUE(Enum.CreditNoteRecordingOptions.IncreaseSale)
	|					WHEN  CertificateOfDiscrepanciesAfterShipmentOfGoods.Count < CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument
	|						THEN VALUE(Enum.CreditNoteRecordingOptions.ReduceSale)
	|					ELSE VALUE(Enum.CreditNoteRecordingOptions.EmptyRef)
	|				END
	|		ELSE VALUE(Enum.CreditNoteRecordingOptions.EmptyRef)
	|	END AS PostingOption,
	|
	|	CASE
	|		WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages < CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_)
	|			THEN VALUE(Enum.CreditNoteRecordingOptions.ReturnToTransit)
	|		WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages > CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|			THEN VALUE(Enum.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount)
	|		WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages > CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|			THEN VALUE(Enum.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock)
	|		WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages < CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
	|			AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|			THEN VALUE(Enum.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount)
	|		WHEN CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages < CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|			THEN VALUE(Enum.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock)
	|	END AS VariantOfReflectionOfDiscrepancy,
	|
	|	CASE
	|		WHEN &ThisIsReturnToPath
	|			OR CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages < CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument
	|				AND CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_)
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE 
	|			CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse
	|	END AS WarehouseDiscrepancies
	|
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyReportFollowingShipmentBaseDocument
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices = &ImplementationBasis
	|	AND (CertificateOfDiscrepanciesAfterShipmentOfGoods.Action IN (&ActionsOptions)
	|		OR (NOT (&SaleOfOverdeliveredGoods OR &ReturnOfUnderdeliveredGoods)))
	|	AND (CertificateOfDiscrepanciesAfterShipmentOfGoods.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration) OR
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument <> 0)
	|
	|ORDER BY
	|	LineNumber";
	
	ActionsOptions = New Array;
	If Object.AdjustmentKind = Enums.BusinessTransactions.SaleOfOverdeliveredGoods Then
		ActionsOptions.Add(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered);
		ActionsOptions.Add(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery);
		SaleOfOverdeliveredGoods = True;
		ReturnOfUnderdeliveredGoods = False;
	ElsIf Object.AdjustmentKind = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods Then
		ActionsOptions.Add(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired);
		ActionsOptions.Add(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired);
		SaleOfOverdeliveredGoods = False;
		ReturnOfUnderdeliveredGoods = True;
	Else
		SaleOfOverdeliveredGoods = False;
		ReturnOfUnderdeliveredGoods = False;
		If TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
			CompleteQueryTextForImplementation(Query.Text);
			FilterByProductType = ProductsClientServer.SelectionByProductMultiTurnContainer();
			Query.SetParameter("ItemsTypes", FilterByProductType);
		EndIf;
	EndIf;
	
	OptionsDocumentData = New Array;
	OptionsDocumentData.Add(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage);
	OptionsDocumentData.Add(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial);
	OptionsDocumentData.Add(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow);
	OptionsDocumentData.Add(Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration);
	
	Query.SetParameter("DiscrepancyReportFollowingShipmentBaseDocument", Object.DiscrepancyReportFollowingShipmentBaseDocument);
	Query.SetParameter("ImplementationBasis", Object.DocumentBasis);
	Query.SetParameter("ActionsOptions", ActionsOptions);
	Query.SetParameter("SaleOfOverdeliveredGoods", SaleOfOverdeliveredGoods);
	Query.SetParameter("ReturnOfUnderdeliveredGoods", ReturnOfUnderdeliveredGoods);
	Query.SetParameter("OptionsDocumentData", OptionsDocumentData);
	Query.SetParameter("ExportSale", Object.VATTaxation = Enums.VATTaxationTypes.ExportSale);
	Query.SetParameter("ThisIsReturnToPath", ThisIsReturnToPath);
	Query.SetParameter("TwoAdjustmentsAreRequired", TwoAdjustmentsAreRequired);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	RowsToProcess = New Array();
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	
	ThisIsTransferOfOwnership =
		Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
			Or Object.AdditionalProperties.Property("EconomicOperationOfFoundation")
				And Object.AdditionalProperties.EconomicOperationOfFoundation =
					Enums.BusinessTransactions.TransferOfTitleToGoods;
				
	If ThisIsTransferOfOwnership Then
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.SaleAdjustment);
		
		CheckSeriesCalculateStatus = New Structure;
		CheckSeriesCalculateStatus.Insert("Warehouse", Undefined);
		CheckSeriesCalculateStatus.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters.Goods);
		
		StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
		
	EndIf;
	
	ProductResult = Query.Execute().Unload();
	For Each TableRow In ProductResult Do
		
		If TableRow.Count > 0 Then
			
			NewLineProducts = Object.Goods.Add();
			FillPropertyValues(NewLineProducts, TableRow);
			
			If ValueIsFilled(TableRow.NumberOfPackagesOverOrder) Then
				AdditionalLineProducts = Object.Goods.Add();
				FillPropertyValues(AdditionalLineProducts, TableRow);
				AdditionalLineProducts.NumberOfPackages = TableRow.NumberOfPackagesOverOrder;
				AdditionalLineProducts.Count = TableRow.QuantityOverOrder;
				AdditionalLineProducts.RowCode  = 0;
				
				RowsToProcess.Add(NewLineProducts);
				RowsToProcess.Add(AdditionalLineProducts);
			
			ElsIf ThisIsTransferOfOwnership Then
				RowsToProcess.Add(NewLineProducts);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	Object.FillInTheDiscrepancies();
	
	KeyFields =
		"Products,
		|Characteristic,
		|Purpose,
		|Package,
		|SalesOrder,
		|Warehouse,
		|Department,
		|VATRate,
		|FEACNCode";
		
	YouNeedToFillOutWarehouseInHeader = False;
	WarehouseInHeader = Object.Warehouse;
	For Each TSRow In Object.Discrepancies Do
		
		If ThisIsReturnToPath And TSRow.Count < 0 Then
			TSRow.PostingOption = Enums.CreditNoteRecordingOptions.ReturnToTransit;
		Else
			
			SearchParameters = New Structure(KeyFields);
			FillPropertyValues(SearchParameters, TSRow);
			FoundRows = ProductResult.FindRows(SearchParameters);
			
			// The variant of reflection and the warehouse in PM Discrepancies are filled only when it is possible to determine them unambiguously.
			// Otherwise, they will need to be filled in by the user.
			// By key fields, several lines can be found in the TK Result products with different warehouses and reflection options,
			// since the lines in the PM Goods of previous chain documents (implementation, act) may match
			// (differ only by the line code, which is lost when filling in PM Discrepancies in the adjustment of the implementation)
			
			If FoundRows.Count() > 1 Then
				
				ReflectionOptionNeedsToBeFilledIn = True;
				FillingInWarehouseIsRequired = True;
				
				VariantOfReflectionOfDiscrepancy = Undefined;
				WarehouseDiscrepancies = Undefined;
				
				For Each FoundRow In FoundRows Do
					
					If ValueIsFilled(VariantOfReflectionOfDiscrepancy)
						And VariantOfReflectionOfDiscrepancy <> FoundRow.VariantOfReflectionOfDiscrepancy Then
						ReflectionOptionNeedsToBeFilledIn = False;
						Break;
					EndIf;
					
					If ValueIsFilled(WarehouseDiscrepancies)
						And WarehouseDiscrepancies <> FoundRow.WarehouseDiscrepancies Then
						FillingInWarehouseIsRequired = False;
						Break;
					EndIf;
					
					If Not ValueIsFilled(VariantOfReflectionOfDiscrepancy) Then
						VariantOfReflectionOfDiscrepancy = FoundRow.VariantOfReflectionOfDiscrepancy;
					EndIf;
					
					If Not ValueIsFilled(WarehouseDiscrepancies) Then
						WarehouseDiscrepancies = FoundRow.WarehouseDiscrepancies;
					EndIf;
					
				EndDo;
				
			ElsIf FoundRows.Count() = 1 Then
				
				ReflectionOptionNeedsToBeFilledIn = True;
				FillingInWarehouseIsRequired = True;
				
				VariantOfReflectionOfDiscrepancy = FoundRows[0].VariantOfReflectionOfDiscrepancy;
				WarehouseDiscrepancies = FoundRows[0].WarehouseDiscrepancies;
				
			Else
				ReflectionOptionNeedsToBeFilledIn = False;
				FillingInWarehouseIsRequired = False;
			EndIf;
			
			If ReflectionOptionNeedsToBeFilledIn Then
				
				If TSRow.Count < 0
					And (VariantOfReflectionOfDiscrepancy = Enums.CreditNoteRecordingOptions.ReturnToTransit
						Or VariantOfReflectionOfDiscrepancy = Enums.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock
						Or VariantOfReflectionOfDiscrepancy = Enums.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount) Then
					
					TSRow.PostingOption = VariantOfReflectionOfDiscrepancy;
					
				ElsIf TSRow.Count > 0
					And (VariantOfReflectionOfDiscrepancy = Enums.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock
						Or VariantOfReflectionOfDiscrepancy = Enums.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount) Then
					
					TSRow.PostingOption = VariantOfReflectionOfDiscrepancy;
					
				EndIf;
				
			EndIf;
			
			If FillingInWarehouseIsRequired Then
				TSRow.Warehouse = WarehouseDiscrepancies;
			EndIf;
			
			If ValueIsFilled(TSRow.Warehouse)
				And Not YouNeedToFillOutWarehouseInHeader Then
				YouNeedToFillOutWarehouseInHeader = True;
			EndIf;
			
			If Not ValueIsFilled(WarehouseInHeader)
				And ValueIsFilled(TSRow.SalesOrder)
				And TypeOf(TSRow.SalesOrder) <> Type("DocumentRef.SourceDocument") Then
				
				WarehouseInHeader = Common.ObjectAttributeValue(TSRow.SalesOrder, "Warehouse");
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If YouNeedToFillOutWarehouseInHeader And Not ValueIsFilled(Object.Warehouse) Then
		Object.Warehouse = WarehouseInHeader;
	EndIf;
	
	If ValueIsFilled(Object.Warehouse)
		And Not Common.ObjectAttributeValue(Object.Warehouse, "IsFolder") Then
		
		For Each TSRow In Object.Discrepancies Do
			If ValueIsFilled(TSRow.Warehouse)
				Or TSRow.PostingOption = Enums.CreditNoteRecordingOptions.ReturnToTransit Then
				Continue;
			EndIf;
			TSRow.Warehouse = Object.Warehouse;
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CreateTemporaryTableOfSourceData(TempTablesManager, DocumentBasis, DocumentRef = Undefined) Export
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
		RequestTextByReason = RequestTextBasedOnSourceDataSalesOfGoodsAndServices();
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoiceServices") Then
		RequestTextByReason = RequestTextBasedOnSourceDataReportOfCompletedWorks();
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
		RequestTextByReason = RequestTextBasedOnSourceDataSalesOfServicesOtherAssets();
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		RequestTextByReason = RequestTextBasedOnSourceDataOfGiverReport();
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	If TypeOf(DocumentBasis) <> Type("DocumentRef.SourceDocument") Then
	QueryText = "
	|SELECT TOP 1
	|	SaleAdjustment.Ref AS Ref
	|INTO LastAdjustmentData
	|FROM
	|	Document.SaleAdjustment AS SaleAdjustment
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
	|	ON
	|		SaleAdjustment.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
	|		AND RegisterOfDocumentsStornoCorrection.Posted
	|		AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
	|WHERE
	|	SaleAdjustment.Posted
	|	AND SaleAdjustment.AdjustmentKind <> VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods)
	|	AND SaleAdjustment.AdjustmentKind <> VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods)
	|	AND SaleAdjustment.DocumentBasis = &DocumentBasis
	|	AND SaleAdjustment.Ref <> &DocumentRef
	|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
	|
	|ORDER BY
	|	SaleAdjustment.PointInTime DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LineNumber				   AS LineNumber,
	|	GoodsTable.ProductsInSet		   AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet		   AS ItemVariantOfSet,
	|	GoodsTable.Products		 		   AS Products,
	|	GoodsTable.Products.ItemsType AS ItemsType,
	|	GoodsTable.PartnerProducts         AS PartnerProducts,
	|	GoodsTable.Characteristic			   AS Characteristic,
	|	GoodsTable.Purpose				   AS Purpose,
	|	GoodsTable.Series						   AS Series,
	|	GoodsTable.BatchesIndicationStatus		   AS BatchesIndicationStatus,
	|	GoodsTable.Content				   AS Content,
	|	GoodsTable.Package					   AS Package,
	|	GoodsTable.NumberOfPackages		   AS NumberOfPackages,
	|	GoodsTable.Count				   AS Count,
	|	GoodsTable.Sum						   AS Sum,
	|	GoodsTable.VATRate					   AS VATRate,
	|	GoodsTable.IncomeItem				   AS IncomeItem,
	|	GoodsTable.DimensionOfRevenue			   AS DimensionOfRevenue,
	|	GoodsTable.VATAmount					   AS VATAmount,
	|	GoodsTable.VATAmountCompl				   AS VATAmountCompl,
	|	GoodsTable.VATAmountMan				   AS VATAmountMan,
	|	GoodsTable.AmountIncludingVAT					   AS AmountIncludingVAT,
	|	GoodsTable.RowCode					   AS RowCode,
	|	GoodsTable.Warehouse						   AS Warehouse,
	|	GoodsTable.Department				   AS Department,
	|	GoodsTable.SalesOrder				   AS SalesOrder,
	|	GoodsTable.FEACNCode					   AS FEACNCode,
	|	GoodsTable.Price						   AS Price,
	|	GoodsTable.PriceKind					   AS PriceKind,
	|
	|	GoodsTable.ExpenseItem               AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses            AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension     AS AssetsLiabilitiesDimension,
	|	GoodsTable.ToExpenseAs             AS ToExpenseAs
	|
	|INTO RawData
	|FROM
	|	Document.SaleAdjustment.Goods AS GoodsTable
	|		INNER JOIN LastAdjustmentData AS LastAdjustmentData
	|		ON GoodsTable.Ref = LastAdjustmentData.Ref
	|";
	
	RequestTextByReason = TMCommonUse.QuerySeparatorInJoin() + RequestTextByReason;

	QueryText = QueryText + RequestTextByReason
		+ Common.QueryBatchSeparator() + "DROP LastAdjustmentData";
		
	Else
		
		QueryText = QueryTextAccordingToInitialDataOfAdjustmentsOfPrimaryDocument();
		
		If ValueIsFilled(DocumentRef) Then
			CurPointInTime = DocumentRef.PointInTime();
		Else
			CurPointInTime = New PointInTime(CurrentSessionDate(), Documents.SaleAdjustment.EmptyRef());
		EndIf;
		Query.SetParameter("CurPointInTime", CurPointInTime);
		
	EndIf;
	
	Query.Text = QueryText;
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.SetParameter("DocumentRef", DocumentRef);
	If TypeOf(DocumentBasis) = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		Period = BegOfMonth(Common.ObjectAttributeValue(DocumentBasis, "Date"));
		Query.SetParameter("KeepRecordsOfInventoryCostByAssignments",
			CalculationOfCostCached.CostOfGoodsForPurposes(Period));
	EndIf;
	Query.Execute();
	
EndProcedure

Procedure CompleteQueryTextForImplementation(QueryText)
	
	SearchText = "
	|ORDER BY
	|	LineNumber";
	
	UnionAllText = Common.UnionAllText();
	
	ImplementationQueryText = UnionAllText + "SELECT
	|	SalesOfGoodsServicesGoods.LineNumber AS LineNumber,
	|	SalesOfGoodsServicesGoods.Products AS Products,
	|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
	|	SalesOfGoodsServicesGoods.Purpose AS Purpose,
	|	SalesOfGoodsServicesGoods.Package AS Package,
	|	SalesOfGoodsServicesGoods.NumberOfPackages AS NumberOfPackages,
	|	SalesOfGoodsServicesGoods.Count AS Count,
	|	SalesOfGoodsServicesGoods.PriceKind AS PriceKind,
	|	SalesOfGoodsServicesGoods.Price AS Price,
	|	SalesOfGoodsServicesGoods.Sum AS Sum,
	|	SalesOfGoodsServicesGoods.VATRate AS VATRate,
	|	CASE
	|		WHEN &ExportSale
	|			THEN SalesOfGoodsServicesGoods.Products.FEACNCode
	|		ELSE VALUE(Catalog.FEACN.EmptyRef)
	|	END AS FEACNCode,
	|	SalesOfGoodsServicesGoods.VATAmount AS VATAmount,
	|	SalesOfGoodsServicesGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
	|	SalesOfGoodsServicesGoods.RowCode AS RowCode,
	|	SalesOfGoodsServicesGoods.Warehouse AS Warehouse,
	|	SalesOfGoodsServicesGoods.Department AS Department,
	|	CASE
	|		WHEN SalesOfGoodsServicesGoods.BatchesIndicationStatus = 14
	|			THEN SalesOfGoodsServicesGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	CASE
	|		WHEN SalesOfGoodsServicesGoods.BatchesIndicationStatus = 14
	|			THEN SalesOfGoodsServicesGoods.BatchesIndicationStatus
	|		ELSE 0
	|	END AS BatchesIndicationStatus,
	|	0 AS NumberOfPackagesOverOrder,
	|	0 AS QuantityOverOrder,
	|	VALUE(Enum.CreditNoteRecordingOptions.EmptyRef) AS PostingOption,
	|	VALUE(Enum.CreditNoteRecordingOptions.EmptyRef) AS VariantOfReflectionOfDiscrepancy,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS WarehouseDiscrepancies
	|FROM
	|	Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	|WHERE
	|	SalesOfGoodsServicesGoods.Ref = &ImplementationBasis
	|	AND NOT &SaleOfOverdeliveredGoods
	|	AND NOT &ReturnOfUnderdeliveredGoods
	|	AND NOT SalesOfGoodsServicesGoods.Products.ItemsType IN(&ItemsTypes)
	|
	|ORDER BY
	|	LineNumber";
	
	QueryText = StrReplace(QueryText, SearchText, ImplementationQueryText);
	
EndProcedure

Function RequestTextBasedOnSourceDataSalesOfGoodsAndServices()
	
	QueryText = "
	|SELECT
	|	GoodsTable.LineNumber                                   AS LineNumber,
	|	GoodsTable.ProductsInSet                            AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet                          AS ItemVariantOfSet,
	|	GoodsTable.Products                                  AS Products,
	|	GoodsTable.Products.ItemsType                  AS ItemsType,
	|	GoodsTable.PartnerProducts                          AS PartnerProducts,
	|	GoodsTable.Characteristic                                AS Characteristic,
	|	GoodsTable.Purpose                                    AS Purpose,
	|	CASE WHEN GoodsTable.BatchesIndicationStatus IN (14,18)
	|		THEN GoodsTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END                                                       AS Series,
	|	CASE WHEN GoodsTable.BatchesIndicationStatus IN (14,18)
	|		THEN GoodsTable.BatchesIndicationStatus
	|		ELSE 0
	|	END                                                       AS BatchesIndicationStatus,
	|	""""                                                        AS Content,
	|	GoodsTable.Package                                      AS Package,
	|	GoodsTable.NumberOfPackages                            AS NumberOfPackages,
	|	GoodsTable.Count                                    AS Count,
	|	GoodsTable.Sum                                         AS Sum,
	|	GoodsTable.VATRate                                     AS VATRate,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) AS IncomeItem,
	|	UNDEFINED                                                AS DimensionOfRevenue,
	|	GoodsTable.VATAmount                                      AS VATAmount,
	|	GoodsTable.VATAmountCompl                                  AS VATAmountCompl,
	|	GoodsTable.VATAmountMan                                   AS VATAmountMan,
	|	GoodsTable.AmountIncludingVAT                                     AS AmountIncludingVAT,
	|	GoodsTable.RowCode                                     AS RowCode,
	|	GoodsTable.Warehouse                                         AS Warehouse,
	|	GoodsTable.Department                                 AS Department,
	|	GoodsTable.SalesOrder                                  AS SalesOrder,
	|	GoodsTable.FEACNCode                                      AS FEACNCode,
	|	
	|	CASE
	|		WHEN CAST(GoodsTable.Price * GoodsTable.NumberOfPackages AS NUMBER(31,2)) = GoodsTable.Sum
	|			THEN GoodsTable.Price
	|		ELSE CAST(GoodsTable.Sum / GoodsTable.NumberOfPackages AS NUMBER(31,2))
	|	END AS Price,
	|	
	|	CASE WHEN CAST(GoodsTable.Price * GoodsTable.NumberOfPackages AS NUMBER(31,2)) = GoodsTable.Sum THEN
	|		GoodsTable.PriceKind
	|	ELSE
	|		VALUE(Catalog.TypesOfPrices.EmptyRef)
	|	END AS PriceKind,
	|
	|	UNDEFINED                                               AS ExpenseItem,
	|	UNDEFINED                                               AS DimensionOfExpenses,
	|	UNDEFINED                                               AS AssetsLiabilitiesDimension,
	|	FALSE                                                       AS ToExpenseAs
	|
	|FROM
	|	Document.CustomerInvoice.Goods AS GoodsTable
	|		LEFT JOIN LastAdjustmentData AS LastAdjustmentData
	|		ON TRUE
	|WHERE
	|	LastAdjustmentData.Ref IS NULL 
	|	AND GoodsTable.Ref = &DocumentBasis
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextBasedOnSourceDataReportOfCompletedWorks()
	
	QueryText = "
	|SELECT
	|	TableServices.LineNumber                                   AS LineNumber,
	|	TableServices.ProductsInSet                            AS ProductsInSet,
	|	TableServices.ItemVariantOfSet                          AS ItemVariantOfSet,
	|	TableServices.Products                                  AS Products,
	|	TableServices.Products.ItemsType                  AS ItemsType,
	|	TableServices.PartnerProducts                          AS PartnerProducts,
	|	TableServices.Characteristic                                AS Characteristic,
	|	TableServices.Purpose                                    AS Purpose,
	|	VALUE(Catalog.ItemsBatches.EmptyRef)         AS Series,
	|	0                                                           AS BatchesIndicationStatus,
	|	TableServices.Content                                    AS Content,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)  AS Package,
	|	TableServices.Count                                    AS NumberOfPackages,
	|	TableServices.Count                                    AS Count,
	|	TableServices.Sum                                         AS Sum,
	|	TableServices.VATRate                                     AS VATRate,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) AS IncomeItem,
	|	UNDEFINED                                                AS DimensionOfRevenue,
	|	TableServices.VATAmount                                      AS VATAmount,
	|	0                                                           AS VATAmountCompl,
	|	0                                                           AS VATAmountMan,
	|	TableServices.AmountIncludingVAT                                     AS AmountIncludingVAT,
	|	TableServices.RowCode                                     AS RowCode,
	|	VALUE(Catalog.Warehouses.EmptyRef)                    AS Warehouse,
	|	TableServices.Department                                 AS Department,
	|	TableServices.SalesOrder                                  AS SalesOrder,
	|	VALUE(Catalog.FEACN.EmptyRef)        AS FEACNCode,
	|	
	|	CASE
	|		WHEN CAST(TableServices.Price * TableServices.Count AS NUMBER(31,2)) = TableServices.Sum
	|			THEN TableServices.Price
	|		ELSE CAST(TableServices.Sum / TableServices.Count AS NUMBER(31,2))
	|	END AS Price,
	|	
	|	CASE WHEN CAST(TableServices.Price * TableServices.Count AS NUMBER(31,2)) = TableServices.Sum THEN
	|		TableServices.PriceKind
	|	ELSE
	|		VALUE(Catalog.TypesOfPrices.EmptyRef)
	|	END AS PriceKind,
	|
	|	UNDEFINED                                               AS ExpenseItem,
	|	UNDEFINED                                               AS DimensionOfExpenses,
	|	UNDEFINED                                               AS AssetsLiabilitiesDimension,
	|	FALSE                                                       AS ToExpenseAs
	|
	|FROM
	|	Document.CustomerInvoiceServices.Services AS TableServices
	|		LEFT JOIN LastAdjustmentData AS LastAdjustmentData
	|		ON TRUE
	|
	|WHERE
	|	LastAdjustmentData.Ref IS NULL 
	|	AND TableServices.Ref = &DocumentBasis
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextBasedOnSourceDataSalesOfServicesOtherAssets()
	
	QueryText = "
	|SELECT
	|	TableRevenue.LineNumber                                    AS LineNumber,
	|	VALUE(Catalog.Products.EmptyRef)               AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	VALUE(Catalog.Products.EmptyRef)               AS Products,
	|	VALUE(Enum.ItemsTypes.EmptyRef)         AS ItemsType,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef)   AS PartnerProducts,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.Assignments.EmptyRef)                 AS Purpose,
	|	VALUE(Catalog.ItemsBatches.EmptyRef)          AS Series,
	|	0                                                            AS BatchesIndicationStatus,
	|	TableRevenue.Content                                     AS Content,
	|	TableRevenue.UnitOfMeasure                               AS Package,
	|	TableRevenue.Count                                     AS NumberOfPackages,
	|	TableRevenue.Count                                     AS Count,
	|	TableRevenue.Sum                                          AS Sum,
	|	TableRevenue.VATRate                                      AS VATRate,
	|	TableRevenue.IncomeItem                                  AS IncomeItem,
	|	TableRevenue.DimensionOfRevenue                               AS DimensionOfRevenue,
	|	TableRevenue.VATAmount                                       AS VATAmount,
	|	0                                                            AS VATAmountCompl,
	|	0                                                            AS VATAmountMan,
	|	TableRevenue.AmountIncludingVAT                                      AS AmountIncludingVAT,
	|	0                                                            AS RowCode,
	|	VALUE(Catalog.Warehouses.EmptyRef)                     AS Warehouse,
	|	VALUE(Catalog.BusinessStructure.EmptyRef)       AS Department,
	|	VALUE(Document.SalesOrder.EmptyRef)                 AS SalesOrder,
	|	VALUE(Catalog.FEACN.EmptyRef)         AS FEACNCode,
	|
	|	TableRevenue.Price AS Price,
	|	VALUE(Catalog.TypesOfPrices.EmptyRef) AS PriceKind,
	|
	|	UNDEFINED                                                 AS ExpenseItem,
	|	UNDEFINED                                                 AS DimensionOfExpenses,
	|	UNDEFINED                                                 AS AssetsLiabilitiesDimension,
	|	FALSE                                                         AS ToExpenseAs
	|
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets.Income AS TableRevenue
	|		LEFT JOIN LastAdjustmentData AS LastAdjustmentData
	|		ON TRUE
	|WHERE
	|	LastAdjustmentData.Ref IS NULL 
	|	AND TableRevenue.Ref = &DocumentBasis
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextAccordingToInitialDataOfAdjustmentsOfPrimaryDocument()
	
	QueryText = "
	|SELECT TOP 1
	|	SaleAdjustment.Ref AS Ref,
	|	SaleAdjustment.PointInTime AS PointInTime,
	|	SaleAdjustment.AdjustingEntryType AS AdjustingEntryType,
	|	SaleAdjustment.PriceIncludesVAT AS PriceIncludesVAT
	|INTO DataFromLastCorrectiveAdjustment
	|FROM
	|	Document.SaleAdjustment AS SaleAdjustment
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
	|		ON SaleAdjustment.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
	|			AND (RegisterOfDocumentsStornoCorrection.Posted)
	|			AND (NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord)
	|WHERE
	|	SaleAdjustment.Posted
	|	AND SaleAdjustment.AdjustmentKind <> VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods)
	|	AND SaleAdjustment.AdjustmentKind <> VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods)
	|	AND SaleAdjustment.DocumentBasis = &DocumentBasis
	|	AND SaleAdjustment.Ref <> &DocumentRef
	|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
	|	AND SaleAdjustment.PointInTime < &CurPointInTime
	|	AND SaleAdjustment.AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|
	|ORDER BY
	|	SaleAdjustment.PointInTime DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SaleAdjustment.Ref AS Ref,
	|	SaleAdjustment.PointInTime AS PointInTime,
	|	SaleAdjustment.AdjustingEntryType AS AdjustingEntryType,
	|	SaleAdjustment.PriceIncludesVAT AS PriceIncludesVAT
	|INTO PreviousAdjustmentData
	|FROM
	|	Document.SaleAdjustment AS SaleAdjustment
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
	|		ON SaleAdjustment.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
	|			AND (RegisterOfDocumentsStornoCorrection.Posted)
	|			AND (NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord)
	|		LEFT JOIN DataFromLastCorrectiveAdjustment AS DataFromLastCorrectiveAdjustment
	|		ON (TRUE)
	|WHERE
	|	SaleAdjustment.Posted
	|	AND SaleAdjustment.AdjustmentKind <> VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods)
	|	AND SaleAdjustment.AdjustmentKind <> VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods)
	|	AND SaleAdjustment.DocumentBasis = &DocumentBasis
	|	AND SaleAdjustment.Ref <> &DocumentRef
	|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
	|	AND SaleAdjustment.PointInTime < &CurPointInTime
	|	AND (DataFromLastCorrectiveAdjustment.PointInTime IS NULL
	|			OR SaleAdjustment.PointInTime > DataFromLastCorrectiveAdjustment.PointInTime)
	|	AND SaleAdjustment.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	SaleAdjustment.PointInTime AS PointInTime,
	|	SaleAdjustment.PriceIncludesVAT AS PriceIncludesVAT,
	|	SaleAdjustment.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.ProductsInSet AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Products.ItemsType AS ItemsType,
	|	GoodsTable.PartnerProducts AS PartnerProducts,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Content AS Content,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.IncomeItem AS IncomeItem,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.VATAmountCompl AS VATAmountCompl,
	|	GoodsTable.VATAmountMan AS VATAmountMan,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	GoodsTable.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.Price AS Price,
	|	GoodsTable.ExpenseItem AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.ToExpenseAs AS ToExpenseAs,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|	ISNULL(ProductData_1.KeepRecordsByCCD, FALSE) AS KeepRecordsByCCD
	|INTO TTGoodsOfPreviousAdjustment
	|FROM
	|	Document.SaleAdjustment.Goods AS GoodsTable
	|		INNER JOIN PreviousAdjustmentData AS SaleAdjustment
	|		ON GoodsTable.Ref = SaleAdjustment.Ref
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON GoodsTable.Products = ProductData_1.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	SaleAdjustment.PointInTime AS PointInTime,
	|	SaleAdjustment.PriceIncludesVAT AS PriceIncludesVAT,
	|	SaleAdjustment.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.ProductsInSet AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Products.ItemsType AS ItemsType,
	|	GoodsTable.PartnerProducts AS PartnerProducts,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Content AS Content,
	|	GoodsTable.Package AS Package,
	|	0 AS NumberOfPackages,
	|	0 AS Count,
	|	0 AS Sum,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.IncomeItem AS IncomeItem,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	0 AS VATAmount,
	|	0 AS VATAmountCompl,
	|	0 AS VATAmountMan,
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Department AS Department,
	|	0 AS Price,
	|	GoodsTable.ExpenseItem AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.ToExpenseAs AS ToExpenseAs,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	0 AS QuantityByGBRN,
	|	ISNULL(ProductData_1.KeepRecordsByCCD, FALSE) AS KeepRecordsByCCD
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS GoodsTable
	|		INNER JOIN PreviousAdjustmentData AS SaleAdjustment
	|		ON GoodsTable.Ref = SaleAdjustment.Ref
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON GoodsTable.Products = ProductData_1.Ref
	|WHERE
	|	NOT (GoodsTable.Content, GoodsTable.ProductsInSet, GoodsTable.ItemVariantOfSet, GoodsTable.Products, GoodsTable.Characteristic, GoodsTable.Series, GoodsTable.Package, GoodsTable.Warehouse, GoodsTable.IncomeItem, GoodsTable.DimensionOfRevenue, GoodsTable.Department, GoodsTable.CCDNumber) IN
	|				(SELECT
	|					GoodsOfPreviousAdjustment.Content,
	|					GoodsOfPreviousAdjustment.ProductsInSet,
	|					GoodsOfPreviousAdjustment.ItemVariantOfSet,
	|					GoodsOfPreviousAdjustment.Products,
	|					GoodsOfPreviousAdjustment.Characteristic,
	|					GoodsOfPreviousAdjustment.Series,
	|					GoodsOfPreviousAdjustment.Package,
	|					GoodsOfPreviousAdjustment.Warehouse,
	|					GoodsOfPreviousAdjustment.IncomeItem,
	|					GoodsOfPreviousAdjustment.DimensionOfRevenue,
	|					GoodsOfPreviousAdjustment.Department,
	|					GoodsOfPreviousAdjustment.CCDNumber
	|				FROM
	|					Document.SaleAdjustment.Goods AS GoodsOfPreviousAdjustment
	|				WHERE
	|					GoodsOfPreviousAdjustment.Ref = GoodsTable.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	SaleAdjustment.PointInTime AS PointInTime,
	|	SaleAdjustment.PriceIncludesVAT AS PriceIncludesVAT,
	|	SaleAdjustment.AdjustingEntryType AS AdjustingEntryType,
	|	SaleAdjustment.Ref.Date AS Date,
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.ProductsInSet AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Products.ItemsType AS ItemsType,
	|	GoodsTable.PartnerProducts AS PartnerProducts,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Content AS Content,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.IncomeItem AS IncomeItem,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.VATAmountCompl AS VATAmountCompl,
	|	GoodsTable.VATAmountMan AS VATAmountMan,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	GoodsTable.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.Price AS Price,
	|	GoodsTable.ExpenseItem AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.ToExpenseAs AS ToExpenseAs,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|	ISNULL(ProductData_1.KeepRecordsByCCD, FALSE) AS KeepRecordsByCCD
	|INTO TTGoodsOfLastCorrectiveAdjustment
	|FROM
	|	Document.SaleAdjustment.Goods AS GoodsTable
	|		INNER JOIN DataFromLastCorrectiveAdjustment AS SaleAdjustment
	|		ON GoodsTable.Ref = SaleAdjustment.Ref
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON GoodsTable.Products = ProductData_1.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	SaleAdjustment.PointInTime AS PointInTime,
	|	SaleAdjustment.PriceIncludesVAT AS PriceIncludesVAT,
	|	SaleAdjustment.AdjustingEntryType AS AdjustingEntryType,
	|	SaleAdjustment.Ref.Date AS Date,
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.ProductsInSet AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Products.ItemsType AS ItemsType,
	|	GoodsTable.PartnerProducts AS PartnerProducts,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Content AS Content,
	|	GoodsTable.Package AS Package,
	|	0 AS NumberOfPackages,
	|	0 AS Count,
	|	0 AS Sum,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.IncomeItem AS IncomeItem,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	0 AS VATAmount,
	|	0 AS VATAmountCompl,
	|	0 AS VATAmountMan,
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Department AS Department,
	|	0 AS Price,
	|	GoodsTable.ExpenseItem AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.ToExpenseAs AS ToExpenseAs,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	0 AS QuantityByGBRN,
	|	ISNULL(ProductData_1.KeepRecordsByCCD, FALSE) AS KeepRecordsByCCD
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS GoodsTable
	|		INNER JOIN DataFromLastCorrectiveAdjustment AS SaleAdjustment
	|		ON GoodsTable.Ref = SaleAdjustment.Ref
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON GoodsTable.Products = ProductData_1.Ref
	|WHERE
	|	NOT (GoodsTable.Content, GoodsTable.ProductsInSet, GoodsTable.ItemVariantOfSet, GoodsTable.Products, GoodsTable.Characteristic, GoodsTable.Series, GoodsTable.Package, GoodsTable.Warehouse, GoodsTable.IncomeItem, GoodsTable.DimensionOfRevenue, GoodsTable.Department, GoodsTable.CCDNumber) IN
	|				(SELECT
	|					GoodsOfPreviousAdjustment.Content,
	|					GoodsOfPreviousAdjustment.ProductsInSet,
	|					GoodsOfPreviousAdjustment.ItemVariantOfSet,
	|					GoodsOfPreviousAdjustment.Products,
	|					GoodsOfPreviousAdjustment.Characteristic,
	|					GoodsOfPreviousAdjustment.Series,
	|					GoodsOfPreviousAdjustment.Package,
	|					GoodsOfPreviousAdjustment.Warehouse,
	|					GoodsOfPreviousAdjustment.IncomeItem,
	|					GoodsOfPreviousAdjustment.DimensionOfRevenue,
	|					GoodsOfPreviousAdjustment.Department,
	|					GoodsOfPreviousAdjustment.CCDNumber
	|				FROM
	|					Document.SaleAdjustment.Goods AS GoodsOfPreviousAdjustment
	|				WHERE
	|					GoodsOfPreviousAdjustment.Ref = GoodsTable.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.PointInTime AS PointInTime,
	|	GoodsTable.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.PartnerProducts AS PartnerProducts,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.ProductsInSet AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	GoodsTable.Content AS Content,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.IncomeItem AS IncomeItem,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.Price AS Price,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.VATAmountCompl AS VATAmountCompl,
	|	GoodsTable.VATAmountMan AS VATAmountMan,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	GoodsTable.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	GoodsTable.ExpenseItem AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.ToExpenseAs AS ToExpenseAs
	|INTO TTGoodsOfPreviousSGTD_1Adjustment
	|FROM
	|	TTGoodsOfPreviousAdjustment AS GoodsTable
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON GoodsTable.Products = ProductData_1.Ref
	|WHERE
	|	(NOT ISNULL(ProductData_1.KeepRecordsByCCD, FALSE)
	|			OR GoodsTable.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.PointInTime AS PointInTime,
	|	GoodsTable.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.PartnerProducts AS PartnerProducts,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.ProductsInSet AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	GoodsTable.Content AS Content,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.IncomeItem AS IncomeItem,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.Price AS Price,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.VATAmountCompl AS VATAmountCompl,
	|	GoodsTable.VATAmountMan AS VATAmountMan,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	GoodsTable.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	GoodsTable.ExpenseItem AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.ToExpenseAs AS ToExpenseAs
	|INTO TTGoodsOfPreviousSGTD_3Adjustment
	|FROM
	|	TTGoodsOfPreviousSGTD_1Adjustment AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN
	|			(SELECT TOP 1
	|				GoodsOfPreviousAdjustment.Ref
	|			FROM
	|				TTGoodsOfPreviousSGTD_1Adjustment AS GoodsOfPreviousAdjustment
	|			WHERE
	|				GoodsOfPreviousAdjustment.Products = GoodsTable.Products
	|				AND GoodsOfPreviousAdjustment.Content = GoodsTable.Content
	|				AND GoodsOfPreviousAdjustment.ProductsInSet = GoodsTable.ProductsInSet
	|				AND GoodsOfPreviousAdjustment.ItemVariantOfSet = GoodsTable.ItemVariantOfSet
	|				AND GoodsOfPreviousAdjustment.Characteristic = GoodsTable.Characteristic
	|				AND GoodsOfPreviousAdjustment.Series = GoodsTable.Series
	|				AND GoodsOfPreviousAdjustment.Package = GoodsTable.Package
	|				AND GoodsOfPreviousAdjustment.Warehouse = GoodsTable.Warehouse
	|				AND GoodsOfPreviousAdjustment.IncomeItem = GoodsTable.IncomeItem
	|				AND GoodsOfPreviousAdjustment.DimensionOfRevenue = GoodsTable.DimensionOfRevenue
	|				AND GoodsOfPreviousAdjustment.Department = GoodsTable.Department
	|				AND GoodsOfPreviousAdjustment.CCDNumber = GoodsTable.CCDNumber
	|			ORDER BY
	|				GoodsOfPreviousAdjustment.PointInTime DESC)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.LineNumber AS LineNumber,
	|	SaleAdjustment.PointInTime AS PointInTime,
	|	SaleAdjustment.AdjustingEntryType AS AdjustingEntryType,
	|	ISNULL(GoodsTable.ItemsLocationAttributes.Products, VALUE(Catalog.Products.EmptyRef)) AS Products,
	|	GoodsTable.PartnerProducts AS PartnerProducts,
	|	GoodsTable.FEACNCode AS FEACNCode,
	|	ISNULL(GoodsTable.ItemsLocationAttributes.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS Characteristic,
	|	ISNULL(GoodsTable.SetAccountingDimension.ProductsInSet, VALUE(Catalog.Products.EmptyRef)) AS ProductsInSet,
	|	ISNULL(GoodsTable.SetAccountingDimension.ItemVariantOfSet, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS ItemVariantOfSet,
	|	SaleAdjustment.Content AS Content,
	|	GoodsTable.Package AS Package,
	|	SaleAdjustment.Series AS Series,
	|	GoodsTable.Warehouse AS Warehouse,
	|	SaleAdjustment.Department AS Department,
	|	GoodsTable.VATRate AS VATRate,
	|	SaleAdjustment.IncomeItem AS IncomeItem,
	|	SaleAdjustment.DimensionOfRevenue AS DimensionOfRevenue,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	CASE
	|		WHEN SaleAdjustment.PriceIncludesVAT
	|				AND GoodsTable.AmountIncludingVAT > 0
	|				AND GoodsTable.NumberOfPackages > 0
	|			THEN GoodsTable.AmountIncludingVAT / GoodsTable.NumberOfPackages
	|		WHEN NOT SaleAdjustment.PriceIncludesVAT
	|				AND GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount > 0
	|				AND GoodsTable.NumberOfPackages > 0
	|			THEN (GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) / GoodsTable.NumberOfPackages
	|		ELSE 0
	|	END AS Price,
	|	CASE
	|		WHEN SaleAdjustment.PriceIncludesVAT
	|			THEN GoodsTable.AmountIncludingVAT
	|		ELSE GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount
	|	END AS Sum,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.VATAmountCompl AS VATAmountCompl,
	|	GoodsTable.VATAmountMan AS VATAmountMan,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	GoodsTable.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	SaleAdjustment.ExpenseItem AS ExpenseItem,
	|	SaleAdjustment.DimensionOfExpenses AS DimensionOfExpenses,
	|	SaleAdjustment.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	SaleAdjustment.ToExpenseAs AS ToExpenseAs
	|INTO TTGoodsOfPreviousSGTD_2Adjustment
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS GoodsTable
	|		INNER JOIN TTGoodsOfPreviousAdjustment AS SaleAdjustment
	|		ON (SaleAdjustment.Ref = GoodsTable.Ref)
	|			AND (SaleAdjustment.Products = VALUE(Catalog.Products.EmptyRef)
	|				OR SaleAdjustment.Products = GoodsTable.ItemsLocationAttributes.Products)
	|			AND (SaleAdjustment.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|				OR SaleAdjustment.Characteristic = GoodsTable.ItemsLocationAttributes.Characteristic)
	|			AND (SaleAdjustment.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|				OR SaleAdjustment.Series = GoodsTable.ItemsLocationAttributes.Series)
	|			AND (SaleAdjustment.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|				OR SaleAdjustment.Department = GoodsTable.ItemsLocationAttributes.Department)
	|			AND (SaleAdjustment.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|				OR SaleAdjustment.ProductsInSet = GoodsTable.SetAccountingDimension.ProductsInSet)
	|			AND (SaleAdjustment.ItemVariantOfSet = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|				OR SaleAdjustment.ItemVariantOfSet = GoodsTable.SetAccountingDimension.ItemVariantOfSet)
	|			AND (SaleAdjustment.Warehouse = GoodsTable.Warehouse)
	|WHERE
	|	SaleAdjustment.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|	AND SaleAdjustment.KeepRecordsByCCD
	|	AND SaleAdjustment.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|	AND SaleAdjustment.Count > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.PointInTime AS PointInTime,
	|	GoodsTable.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.PartnerProducts AS PartnerProducts,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.ProductsInSet AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	GoodsTable.Content AS Content,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.IncomeItem AS IncomeItem,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.Price AS Price,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.VATAmountCompl AS VATAmountCompl,
	|	GoodsTable.VATAmountMan AS VATAmountMan,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	GoodsTable.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	GoodsTable.ExpenseItem AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.ToExpenseAs AS ToExpenseAs
	|INTO TTGoodsOfPreviousSGTD_4Adjustment
	|FROM
	|	TTGoodsOfPreviousSGTD_2Adjustment AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN
	|			(SELECT TOP 1
	|				GoodsOfPreviousAdjustment.Ref
	|			FROM
	|				TTGoodsOfPreviousSGTD_2Adjustment AS GoodsOfPreviousAdjustment
	|			WHERE
	|				GoodsOfPreviousAdjustment.Products = GoodsTable.Products
	|				AND GoodsOfPreviousAdjustment.Content = GoodsTable.Content
	|				AND GoodsOfPreviousAdjustment.ProductsInSet = GoodsTable.ProductsInSet
	|				AND GoodsOfPreviousAdjustment.ItemVariantOfSet = GoodsTable.ItemVariantOfSet
	|				AND GoodsOfPreviousAdjustment.Characteristic = GoodsTable.Characteristic
	|				AND GoodsOfPreviousAdjustment.Series = GoodsTable.Series
	|				AND GoodsOfPreviousAdjustment.Package = GoodsTable.Package
	|				AND GoodsOfPreviousAdjustment.Warehouse = GoodsTable.Warehouse
	|				AND GoodsOfPreviousAdjustment.IncomeItem = GoodsTable.IncomeItem
	|				AND GoodsOfPreviousAdjustment.DimensionOfRevenue = GoodsTable.DimensionOfRevenue
	|				AND GoodsOfPreviousAdjustment.Department = GoodsTable.Department
	|				AND GoodsOfPreviousAdjustment.CCDNumber = GoodsTable.CCDNumber
	|			ORDER BY
	|				GoodsOfPreviousAdjustment.PointInTime DESC)
	|	AND GoodsTable.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.ProductsInSet AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Products.ItemsType AS ProductsTypeOfProducts,
	|	GoodsTable.PartnerProducts AS PartnerProducts,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Content AS Content,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.IncomeItem AS IncomeItem,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.VATAmountCompl AS VATAmountCompl,
	|	GoodsTable.VATAmountMan AS VATAmountMan,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	GoodsTable.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.Price AS Price,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|	GoodsTable.ExpenseItem AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.ToExpenseAs AS ToExpenseAs
	|INTO TTGoodsOfPreviousAdjustmentTotal
	|FROM
	|	TTGoodsOfPreviousSGTD_3Adjustment AS GoodsTable
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.AdjustingEntryType,
	|	GoodsTable.LineNumber,
	|	GoodsTable.ProductsInSet,
	|	GoodsTable.ItemVariantOfSet,
	|	GoodsTable.Products,
	|	GoodsTable.Products.ItemsType,
	|	GoodsTable.PartnerProducts,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Content,
	|	GoodsTable.Package,
	|	GoodsTable.NumberOfPackages,
	|	GoodsTable.Count,
	|	GoodsTable.Sum,
	|	GoodsTable.VATRate,
	|	GoodsTable.IncomeItem,
	|	GoodsTable.DimensionOfRevenue,
	|	GoodsTable.VATAmount,
	|	GoodsTable.VATAmountCompl,
	|	GoodsTable.VATAmountMan,
	|	GoodsTable.AmountIncludingVAT,
	|	GoodsTable.AmountExcludingVATCompl,
	|	GoodsTable.AmountExcludingVATMan,
	|	GoodsTable.Warehouse,
	|	GoodsTable.Department,
	|	GoodsTable.Price,
	|	GoodsTable.CCDNumber,
	|	GoodsTable.QuantityByGBRN,
	|	GoodsTable.ExpenseItem,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension,
	|	GoodsTable.ToExpenseAs
	|FROM
	|	TTGoodsOfPreviousSGTD_4Adjustment AS GoodsTable
	|		INNER JOIN TTGoodsOfPreviousSGTD_3Adjustment AS GoodsOfPreviousAdjustment
	|		ON (GoodsOfPreviousAdjustment.Products = GoodsTable.Products)
	|			AND (GoodsOfPreviousAdjustment.Content = GoodsTable.Content)
	|			AND (GoodsOfPreviousAdjustment.ProductsInSet = GoodsTable.ProductsInSet)
	|			AND (GoodsOfPreviousAdjustment.ItemVariantOfSet = GoodsTable.ItemVariantOfSet)
	|			AND (GoodsOfPreviousAdjustment.Characteristic = GoodsTable.Characteristic)
	|			AND (GoodsOfPreviousAdjustment.Series = GoodsTable.Series)
	|			AND (GoodsOfPreviousAdjustment.Package = GoodsTable.Package)
	|			AND (GoodsOfPreviousAdjustment.Warehouse = GoodsTable.Warehouse)
	|			AND (GoodsOfPreviousAdjustment.IncomeItem = GoodsTable.IncomeItem)
	|			AND (GoodsOfPreviousAdjustment.DimensionOfRevenue = GoodsTable.DimensionOfRevenue)
	|			AND (GoodsOfPreviousAdjustment.Department = GoodsTable.Department)
	|			AND (GoodsOfPreviousAdjustment.CCDNumber = GoodsTable.CCDNumber)
	|			AND GoodsTable.PointInTime >= GoodsOfPreviousAdjustment.PointInTime
	|WHERE
	|	GoodsTable.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|	AND GoodsOfPreviousAdjustment.Count > 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.AdjustingEntryType,
	|	GoodsTable.LineNumber,
	|	GoodsTable.ProductsInSet,
	|	GoodsTable.ItemVariantOfSet,
	|	GoodsTable.Products,
	|	GoodsTable.Products.ItemsType,
	|	GoodsTable.PartnerProducts,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Content,
	|	GoodsTable.Package,
	|	GoodsTable.NumberOfPackages,
	|	GoodsTable.Count,
	|	GoodsTable.Sum,
	|	GoodsTable.VATRate,
	|	GoodsTable.IncomeItem,
	|	GoodsTable.DimensionOfRevenue,
	|	GoodsTable.VATAmount,
	|	GoodsTable.VATAmountCompl,
	|	GoodsTable.VATAmountMan,
	|	GoodsTable.AmountIncludingVAT,
	|	GoodsTable.AmountExcludingVATCompl,
	|	GoodsTable.AmountExcludingVATMan,
	|	GoodsTable.Warehouse,
	|	GoodsTable.Department,
	|	GoodsTable.Price,
	|	GoodsTable.CCDNumber,
	|	GoodsTable.QuantityByGBRN,
	|	GoodsTable.ExpenseItem,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension,
	|	GoodsTable.ToExpenseAs
	|FROM
	|	TTGoodsOfPreviousSGTD_4Adjustment AS GoodsTable
	|WHERE
	|	GoodsTable.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|	AND NOT (GoodsTable.Content, GoodsTable.ProductsInSet, GoodsTable.ItemVariantOfSet, GoodsTable.Products, GoodsTable.Characteristic, GoodsTable.Series, GoodsTable.Package, GoodsTable.Warehouse, GoodsTable.IncomeItem, GoodsTable.DimensionOfRevenue, GoodsTable.Department, GoodsTable.CCDNumber) IN
	|				(SELECT
	|					GoodsOfPreviousAdjustment.Content,
	|					GoodsOfPreviousAdjustment.ProductsInSet,
	|					GoodsOfPreviousAdjustment.ItemVariantOfSet,
	|					GoodsOfPreviousAdjustment.Products,
	|					GoodsOfPreviousAdjustment.Characteristic,
	|					GoodsOfPreviousAdjustment.Series,
	|					GoodsOfPreviousAdjustment.Package,
	|					GoodsOfPreviousAdjustment.Warehouse,
	|					GoodsOfPreviousAdjustment.IncomeItem,
	|					GoodsOfPreviousAdjustment.DimensionOfRevenue,
	|					GoodsOfPreviousAdjustment.Department,
	|					GoodsOfPreviousAdjustment.CCDNumber
	|				FROM
	|					TTGoodsOfPreviousSGTD_3Adjustment AS GoodsOfPreviousAdjustment)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.PointInTime AS PointInTime,
	|	GoodsTable.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.PartnerProducts AS PartnerProducts,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.ProductsInSet AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	GoodsTable.Content AS Content,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.IncomeItem AS IncomeItem,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.Price AS Price,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.VATAmountCompl AS VATAmountCompl,
	|	GoodsTable.VATAmountMan AS VATAmountMan,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	GoodsTable.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	GoodsTable.ExpenseItem AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.ToExpenseAs AS ToExpenseAs
	|INTO TTGoodsOfCorrectiveAdjustmentOfSGTD
	|FROM
	|	TTGoodsOfLastCorrectiveAdjustment AS GoodsTable
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON GoodsTable.Products = ProductData_1.Ref
	|WHERE
	|	(NOT ISNULL(ProductData_1.KeepRecordsByCCD, FALSE)
	|			OR GoodsTable.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef))
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Ref,
	|	GoodsTable.LineNumber AS LineNumber,
	|	SaleAdjustment.PointInTime,
	|	SaleAdjustment.AdjustingEntryType,
	|	SaleAdjustment.Products AS Products,
	|	GoodsTable.PartnerProducts AS PartnerProducts,
	|	SaleAdjustment.Characteristic AS Characteristic,
	|	SaleAdjustment.ProductsInSet AS ProductsInSet,
	|	SaleAdjustment.ItemVariantOfSet AS ItemVariantOfSet,
	|	SaleAdjustment.Content,
	|	GoodsTable.Package AS Package,
	|	SaleAdjustment.Series,
	|	GoodsTable.Warehouse AS Warehouse,
	|	SaleAdjustment.Department,
	|	GoodsTable.VATRate AS VATRate,
	|	SaleAdjustment.IncomeItem,
	|	SaleAdjustment.DimensionOfRevenue,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	CASE
	|		WHEN SaleAdjustment.PriceIncludesVAT
	|				AND GoodsTable.AmountIncludingVAT > 0
	|				AND GoodsTable.NumberOfPackages > 0
	|			THEN GoodsTable.AmountIncludingVAT / GoodsTable.NumberOfPackages
	|		WHEN NOT SaleAdjustment.PriceIncludesVAT
	|				AND GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount > 0
	|				AND GoodsTable.NumberOfPackages > 0
	|			THEN (GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) / GoodsTable.NumberOfPackages
	|		ELSE 0
	|	END AS Price,
	|	CASE
	|		WHEN SaleAdjustment.PriceIncludesVAT
	|			THEN GoodsTable.AmountIncludingVAT
	|		ELSE GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount
	|	END AS Sum,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.VATAmountCompl AS VATAmountCompl,
	|	GoodsTable.VATAmountMan AS VATAmountMan,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	GoodsTable.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	SaleAdjustment.ExpenseItem AS ExpenseItem,
	|	SaleAdjustment.DimensionOfExpenses AS DimensionOfExpenses,
	|	SaleAdjustment.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	SaleAdjustment.ToExpenseAs AS ToExpenseAs
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS GoodsTable
	|		INNER JOIN TTGoodsOfLastCorrectiveAdjustment AS SaleAdjustment
	|		ON (SaleAdjustment.Ref = GoodsTable.Ref)
	|			AND (SaleAdjustment.Products = VALUE(Catalog.Products.EmptyRef)
	|				OR SaleAdjustment.Products = GoodsTable.ItemsLocationAttributes.Products)
	|			AND (SaleAdjustment.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|				OR SaleAdjustment.Characteristic = GoodsTable.ItemsLocationAttributes.Characteristic)
	|			AND (SaleAdjustment.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|				OR SaleAdjustment.Series = GoodsTable.ItemsLocationAttributes.Series)
	|			AND (SaleAdjustment.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|				OR SaleAdjustment.Department = GoodsTable.ItemsLocationAttributes.Department)
	|			AND (SaleAdjustment.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|				OR SaleAdjustment.ProductsInSet = GoodsTable.SetAccountingDimension.ProductsInSet)
	|			AND (SaleAdjustment.ItemVariantOfSet = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|				OR SaleAdjustment.ItemVariantOfSet = GoodsTable.SetAccountingDimension.ItemVariantOfSet)
	|			AND (SaleAdjustment.Warehouse = GoodsTable.Warehouse)
	|WHERE
	|	SaleAdjustment.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|	AND SaleAdjustment.KeepRecordsByCCD
	|	AND SaleAdjustment.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.ProductsInSet AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Products.ItemsType AS ItemsType,
	|	GoodsTable.PartnerProducts AS PartnerProducts,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Content AS Content,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.IncomeItem AS IncomeItem,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.VATAmountCompl AS VATAmountCompl,
	|	GoodsTable.VATAmountMan AS VATAmountMan,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	GoodsTable.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.Price AS Price,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|	GoodsTable.ExpenseItem AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.ToExpenseAs AS ToExpenseAs
	|INTO RawData
	|FROM
	|	TTGoodsOfCorrectiveAdjustmentOfSGTD AS GoodsTable
	|WHERE
	|	CASE
	|			WHEN GoodsTable.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
	|				THEN NOT (GoodsTable.Content, GoodsTable.Department, GoodsTable.IncomeItem, GoodsTable.DimensionOfRevenue) IN
	|								(SELECT
	|									GoodsOfPreviousAdjustment.Content,
	|									GoodsOfPreviousAdjustment.Department,
	|									GoodsOfPreviousAdjustment.IncomeItem,
	|									GoodsOfPreviousAdjustment.DimensionOfRevenue
	|								FROM
	|									TTGoodsOfPreviousAdjustmentTotal AS GoodsOfPreviousAdjustment)
	|						AND GoodsTable.Sum > 0
	|			ELSE NOT (GoodsTable.Content, GoodsTable.ProductsInSet, GoodsTable.ItemVariantOfSet, GoodsTable.Products, GoodsTable.Characteristic, GoodsTable.Series, GoodsTable.Package, GoodsTable.Warehouse, GoodsTable.IncomeItem, GoodsTable.DimensionOfRevenue, GoodsTable.Department, GoodsTable.CCDNumber) IN
	|							(SELECT
	|								GoodsOfPreviousAdjustment.Content,
	|								GoodsOfPreviousAdjustment.ProductsInSet,
	|								GoodsOfPreviousAdjustment.ItemVariantOfSet,
	|								GoodsOfPreviousAdjustment.Products,
	|								GoodsOfPreviousAdjustment.Characteristic,
	|								GoodsOfPreviousAdjustment.Series,
	|								GoodsOfPreviousAdjustment.Package,
	|								GoodsOfPreviousAdjustment.Warehouse,
	|								GoodsOfPreviousAdjustment.IncomeItem,
	|								GoodsOfPreviousAdjustment.DimensionOfRevenue,
	|								GoodsOfPreviousAdjustment.Department,
	|								GoodsOfPreviousAdjustment.CCDNumber
	|							FROM
	|								TTGoodsOfPreviousAdjustmentTotal AS GoodsOfPreviousAdjustment)
	|					AND GoodsTable.Count > 0
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber,
	|	GoodsTable.ProductsInSet,
	|	GoodsTable.ItemVariantOfSet,
	|	GoodsTable.Products,
	|	GoodsTable.Products.ItemsType,
	|	GoodsTable.PartnerProducts,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Content,
	|	GoodsTable.Package,
	|	GoodsTable.NumberOfPackages,
	|	GoodsTable.Count,
	|	GoodsTable.Sum,
	|	GoodsTable.VATRate,
	|	GoodsTable.IncomeItem,
	|	GoodsTable.DimensionOfRevenue,
	|	GoodsTable.VATAmount,
	|	GoodsTable.VATAmountCompl,
	|	GoodsTable.VATAmountMan,
	|	GoodsTable.AmountIncludingVAT,
	|	GoodsTable.AmountExcludingVATCompl,
	|	GoodsTable.AmountExcludingVATMan,
	|	GoodsTable.Warehouse,
	|	GoodsTable.Department,
	|	GoodsTable.Price,
	|	GoodsTable.CCDNumber,
	|	GoodsTable.QuantityByGBRN,
	|	GoodsTable.ExpenseItem,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.AssetsLiabilitiesDimension,
	|	GoodsTable.ToExpenseAs
	|FROM
	|	TTGoodsOfPreviousAdjustmentTotal AS GoodsTable
	|WHERE
	|	(GoodsTable.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|				AND GoodsTable.Count > 0
	|			OR GoodsTable.AdjustingEntryType <> VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|				AND GoodsTable.Sum > 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP PreviousAdjustmentData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTGoodsOfPreviousAdjustment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTGoodsOfLastCorrectiveAdjustment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTGoodsOfPreviousSGTD_1Adjustment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTGoodsOfPreviousSGTD_3Adjustment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTGoodsOfPreviousSGTD_2Adjustment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTGoodsOfPreviousSGTD_4Adjustment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTGoodsOfPreviousAdjustmentTotal
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTGoodsOfCorrectiveAdjustmentOfSGTD";
	
	Return QueryText;
	
EndFunction

Function RequestTextBasedOnSourceDataOfGiverReport()
	
	QueryText = "
	|SELECT
	|	TableProduction.LineNumber                                 AS LineNumber,
	|	VALUE(Catalog.Products.EmptyRef)               AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	TableProduction.Products                                AS Products,
	|	TableProduction.Products.ItemsType                AS ItemsType,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef)   AS PartnerProducts,
	|	TableProduction.Characteristic                              AS Characteristic,
	|	TableProduction.Purpose                                  AS Purpose,
	|	TableProduction.Series                                       AS Series,
	|	TableProduction.BatchesIndicationStatus                         AS BatchesIndicationStatus,
	|	""""                                                         AS Content,
	|	TableProduction.Package                                    AS Package,
	|	TableProduction.NumberOfPackages                          AS NumberOfPackages,
	|	TableProduction.Count                                  AS Count,
	|	TableProduction.Sum                                       AS Sum,
	|	TableProduction.VATRate                                   AS VATRate,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)  AS IncomeItem,
	|	UNDEFINED                                                 AS DimensionOfRevenue,
	|	TableProduction.VATAmount                                    AS VATAmount,
	|	0                                                            AS VATAmountCompl,
	|	0                                                            AS VATAmountMan,
	|	TableProduction.AmountIncludingVAT                                   AS AmountIncludingVAT,
	|	TableProduction.RowCode                                   AS RowCode,
	|	TableProduction.Warehouse                                       AS Warehouse,
	|	CASE
	|		WHEN GiverSProductList.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN TableProduction.Ref.Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END                                                        AS Department,
	|	TableProduction.MaterialProviderOrder                               AS SalesOrder,
	|	VALUE(Catalog.FEACN.EmptyRef)         AS FEACNCode,
	|	TableProduction.Price                                        AS Price,
	|	TableProduction.PriceKind                                     AS PriceKind,
	|
	|	TableProduction.ExpenseItem                              AS ExpenseItem,
	|	TableProduction.DimensionOfExpenses                           AS DimensionOfExpenses,
	|	TableProduction.AssetsLiabilitiesDimension                    AS AssetsLiabilitiesDimension,
	|	TableProduction.ToExpenseAs                            AS ToExpenseAs
	|
	|FROM
	|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS TableProduction
	|	
	|	LEFT JOIN LastAdjustmentData AS LastAdjustmentData
	|	ON TRUE
	|	LEFT JOIN Catalog.Products AS GiverSProductList
	|	ON GiverSProductList.Ref = TableProduction.Products
	|
	|WHERE
	|	LastAdjustmentData.Ref IS NULL 
	|	AND TableProduction.Ref = &DocumentBasis
	|";
	
	Return QueryText;
	
EndFunction
// Generates a temporary table for printing the cost change Agreement, which contains the table part of
// the document data table.
//
// Parameters:
//	TempTablesManager - TempTablesManager - A temporary table manager containing a table of data document tables with fields:
//		Link,
//		Currency.
//
//	FillParameters - Structure - structure returned by the Salesserver function.Parameters for filling in the time table of products.
//
Procedure PlaceTemporaryTableOfGoodsForValueChangeAgreements(TempTablesManager, FillParameters = Undefined)
	
	If FillParameters = Undefined Then
		FillParameters = SalesServer.ParametersForFillingInTemporaryProductTable();
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ManagementAccountingCurrency",     Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("ConvertToLocalCurrency",       FillParameters.ConvertToLocalCurrency);
	Query.SetParameter("IncludingCCDNumbers",               FillParameters.IncludingCCDNumbers);
	Query.SetParameter("EmptyCCD",                      Catalogs.CCDNumbers.EmptyRef());
	
	// Update calculations to obtain amounts for the goods of the underlying document (for example, the sale of goods and services).
	If FillParameters.ConvertToLocalCurrency And FillParameters.UpdateCalculations Then
		If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		
			Query.Text = "
			|SELECT DISTINCT
			|	CustomersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners
			|FROM
			|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
			|
			|	INNER JOIN
			|		DocumentDataTable_ AS DocumentsData
			|	ON
			|		CustomersARAPAccounting.Recorder = DocumentsData.Ref
			|
			|WHERE
			|	DocumentsData.Currency <> DocumentsData.Organization.LocalAccountingCurrency
			|	AND CustomersARAPAccounting.Active
			|";
			AnalystTable = Query.Execute().Unload();
			ArrayOfAccountingAnalystsForPartners = AnalystTable.UnloadColumn("AccountingDimensionByPartners");
			
			If ArrayOfAccountingAnalystsForPartners.Count() > 0 Then 
				EndOfSettlementPeriod_ = EndOfMonth(ARAPAccountingServer.GetMaximumDateInDocumentCollection(TempTablesManager)) + 1;
				CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
				CalculationAnalysts.AccountingAnalyticsForPartners = ArrayOfAccountingAnalystsForPartners;
				Try
					ARAPAllocationServerCall.DistributeAllSettlementsWithCustomers(EndOfSettlementPeriod_, CalculationAnalysts);
				Except
					MessageText = NStr("vi = 'Mẫu in đã được lập theo dữ liệu không thực.
					|Cần cập nhật hạch toán công nợ một cách thủ công và lập lại mẫu in.';
					|ru = 'Печатная форма сформирована по неактуальным данным.
					|Необходимо актуализировать взаиморасчеты вручную и переформировать печатную форму.';
					|en = 'Print form is generated according to irrelevant data. 
					|Update AR/AP accounting manually, and then create the print form again.'; fa = 'Print form is generated according to irrelevant data. 
					|Update AR/AP accounting manually, and then create the print form again.';
					|it = 'La versione di stampa è stata creata in base ai dati obsoleti.
					| È necessario attualizzare manualmente le regolazioni reciproche dei conti e creare una nuova versione stampa.';
					|pl = 'Formularz wydruku jest tworzony na podstawie nieaktualnych danych.
					|Konieczna jest ręczna aktualizacja wzajemnych rozliczeń i ponowne drukowanie formularza wydruku.';
					|tr = 'Çıktı alakasız veriler kullanılarak oluşturulmuştur.
					| Hesapları manuel olarak güncellemeniz ve çıktıyı yeniden oluşturmanız gerekecektir.'");
					CommonClientServer.MessageToUser(MessageText);
				EndTry;
			EndIf;
		Else
			
			Query.Text = 
			"SELECT
			|	DocumentsData.Ref AS Ref
			|FROM
			|	DocumentDataTable_ AS DocumentsData
			|WHERE 
			|	DocumentsData.Currency <> DocumentsData.Organization.LocalAccountingCurrency
			|	OR DocumentsData.Currency <> &ManagementAccountingCurrency";
			DocumentsArray = Query.Execute().Unload().UnloadColumn("Ref");
			If ExchangePlans.MasterNode() = Undefined Then
				BackdateJobQueue.CompleteTasksInNonOperationalQueueBasedOnListOfDocuments(DocumentsArray,
					Catalogs.BackdateJobKinds.UpdateFinancialRegistersRecords);
			Else
				InformationRegisters.DocumentAmountsInAccountingCurrency.CalculateDocumentAmountsInAccountingCurrencies(DocumentsArray);
			EndIf;
			
		EndIf;
	EndIf;
	
	SetTTStockOptions(
		Query,
		FillParameters.ConvertToLocalCurrency,
		FillParameters.IncludingBeforeAdjustment);
	
	Query.Text = QueryTextTTTypesOfStocks() + "
	|SELECT
	|	RelatedDocuments.Main AS Main,
	|	RelatedDocuments.Subordinated AS Previous
	|FROM
	|	TTRelatedDocuments AS RelatedDocuments
	|
	|WHERE
	|	RelatedDocuments.Subordinated <> RelatedDocuments.Main
	|
	|ORDER BY
	|	RelatedDocuments.PointInTime DESC
	|
	|TOTALS BY
	|	RelatedDocuments.Main
	|";
	QueryResult = Query.Execute();
	
	TableOfPreviousDocuments = New ValueTable;
	TableOfPreviousDocuments.Columns.Add("Main",   New TypeDescription("DocumentRef.SaleAdjustment"));
	TableOfPreviousDocuments.Columns.Add("Previous", New TypeDescription("
		|DocumentRef.SaleAdjustment,
		|DocumentRef.CustomerInvoice,
		|DocumentRef.CustomerInvoiceServices,
		|DocumentRef.CustomerInvoiceServicesAndAssets"));
	
	SelectionByRefs = QueryResult.Select(QueryResultIteration.ByGroups);
	While SelectionByRefs.Next() Do
		Selection = SelectionByRefs.Select();
		If Selection.Next() Then
			FillPropertyValues(TableOfPreviousDocuments.Add(), Selection);
		EndIf;
	EndDo;
	
	Query.SetParameter("PreviousDocuments", TableOfPreviousDocuments);
	
	Query.Text = "
	|////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PreviousDocuments.Main   AS Main,
	|	PreviousDocuments.Previous AS Previous
	|
	|INTO PreviousDocuments
	|FROM
	|	&PreviousDocuments AS PreviousDocuments
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Ref                AS Ref,
	|	TableOfGoods.Content            AS Content,
	|	TableOfGoods.Products          AS Products,
	|	TableOfGoods.Characteristic        AS Characteristic,
	|	TableOfGoods.Package              AS Package,
	|	MAX(TableOfGoods.LineNumber) AS LineNumber
	|
	|INTO ProductLines_2
	|FROM
	|	Document.SaleAdjustment.Goods AS TableOfGoods
	|
	|	INNER JOIN
	|		DocumentDataTable_ AS DocumentsData
	|	ON
	|		TableOfGoods.Ref = DocumentsData.Ref
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	TableOfGoods.Products,
	|	TableOfGoods.Content,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Package
	|
	|INDEX BY
	|	TableOfGoods.Ref,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Package
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentTable.Ref                                 AS Ref,
	|	DocumentTable.ToReturnReusablePackage              AS ToReturnReusablePackage,
	|	ISNULL(ProductLines_2.LineNumber, 99999)              AS LineNumber,
	|	""""                                                    AS Content,
	|	DocumentTable.ItemsLocationAttributes.Products  AS Products,
	|	DocumentTable.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	DocumentTable.Package                               AS Package,
	|	
	|	CASE WHEN &IncludingCCDNumbers THEN
	|		DocumentTable.CCDNumber
	|	ELSE
	|		&EmptyCCD
	|	END AS CCDNumber,
	|	
	|	CASE WHEN SUM(DocumentTable.Count) > 0 THEN
	|		SUM(DocumentTable.Count)
	|	ELSE
	|		-SUM(DocumentTable.Count)
	|	END AS Count,
	|	
	|	CASE WHEN SUM(DocumentTable.NumberOfPackages) > 0 THEN
	|		SUM(DocumentTable.NumberOfPackages)
	|	ELSE
	|		-SUM(DocumentTable.NumberOfPackages)
	|	END AS NumberOfPackages,
	|	
	|	CASE WHEN SUM(DocumentTable.AmountExcludingVAT) > 0 THEN
	|		SUM(DocumentTable.AmountExcludingVAT)
	|	ELSE
	|		-SUM(DocumentTable.AmountExcludingVAT)
	|	END AS AmountExcludingVAT,
	|	
	|	DocumentTable.VATRate AS VATRate,
	|	
	|	CASE WHEN SUM(DocumentTable.VATAmount) > 0 THEN
	|		SUM(DocumentTable.VATAmount)
	|	ELSE
	|		-SUM(DocumentTable.VATAmount)
	|	END AS VATAmount,
	|	
	|	TRUE AS ThisIsAProduct,
	|	CASE
	|		WHEN
	|			DocumentTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND DocumentTable.ToReturnReusablePackage
	|		THEN
	|			FALSE
	|		ELSE
	|			TRUE
	|	END AS ThisIsNotReturnContainer,
	|	DocumentTable.BeforeAdjustment AS BeforeAdjustment
	|
	|INTO AdjustmentOfSalesTableOfGoods
	|FROM
	|	TTTypesOfStocks AS DocumentTable
	|
	|	INNER JOIN
	|		DocumentDataTable_ AS DocumentsData
	|	ON
	|		DocumentTable.Ref = DocumentsData.Ref
	|	
	|	LEFT JOIN
	|		ProductLines_2 AS ProductLines_2
	|	ON
	|		DocumentTable.Ref           = ProductLines_2.Ref
	|		AND DocumentTable.ItemsLocationAttributes.Products          = ProductLines_2.Products
	|		AND ProductLines_2.Content        = """"
	|		AND DocumentTable.ItemsLocationAttributes.CHARACTERISTIC        = ProductLines_2.Characteristic
	|		AND DocumentTable.Package       = ProductLines_2.Package
	|
	|	LEFT JOIN
	|		BasisInvoices AS Invoices_
	|	ON
	|		DocumentTable.Ref = Invoices_.DocumentBasis
	|
	|GROUP BY
	|	DocumentTable.Ref,
	|	DocumentTable.ToReturnReusablePackage,
	|	ProductLines_2.LineNumber,
	|	DocumentTable.ItemsLocationAttributes.Products,
	|	DocumentTable.ItemsLocationAttributes.Products.ItemsType,
	|	DocumentTable.ItemsLocationAttributes.CHARACTERISTIC,
	|	DocumentTable.Package,
	|	
	|	CASE WHEN &IncludingCCDNumbers THEN
	|		DocumentTable.CCDNumber
	|	ELSE
	|		&EmptyCCD
	|	END,
	|	
	|	DocumentTable.VATRate,
	|	DocumentTable.BeforeAdjustment,
	|	DocumentsData.BusinessOperation
	|
	|HAVING
	|	SUM(DocumentTable.Count) <> 0
	|	AND (SUM(DocumentTable.Count) > 0 
	|		OR DocumentsData.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods),
	|				VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods))
	|		)
	|
	|UNION ALL
	|
	|SELECT
	|	PreviousDocuments.Main AS Ref,
	|	FALSE AS ToReturnReusablePackage,
	|	ISNULL(ProductLines_2.LineNumber, 99999)             AS LineNumber,
	|	DocumentTable.Content AS Content,
	|	DocumentTable.Products AS Products,
	|	DocumentTable.Characteristic AS Characteristic,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	&EmptyCCD                                             AS CCDNumber,
	|	SUM(DocumentTable.Count) AS Count,
	|	SUM(DocumentTable.Count) AS NumberOfPackages,
	|	SUM(DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount) AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	SUM(DocumentTable.VATAmount) AS VATAmount,
	|	FALSE                                                  AS ThisIsAProduct,
	|	FALSE                                                  AS ThisIsNotReturnContainer,
	|	FALSE                        AS BeforeAdjustment
	|
	|FROM
	|	Document.SaleAdjustment.Goods AS DocumentTable
	|	
	|	INNER JOIN
	|		PreviousDocuments AS PreviousDocuments
	|	ON
	|		DocumentTable.Ref = PreviousDocuments.Main
	|	
	|	INNER JOIN
	|		Document.SaleAdjustment AS DocumentsData
	|	ON
	|		DocumentTable.Ref = DocumentsData.Ref
	|	
	|	LEFT JOIN
	|		ProductLines_2 AS ProductLines_2
	|	ON
	|		DocumentTable.Ref           = ProductLines_2.Ref
	|		AND DocumentTable.Products   = ProductLines_2.Products
	|		AND DocumentTable.Content     = ProductLines_2.Content
	|		AND DocumentTable.Characteristic = ProductLines_2.Characteristic
	|		AND DocumentTable.Package       = ProductLines_2.Package
	|
	|WHERE
	|	DocumentsData.AdjustmentKind <> VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods)
	|	AND DocumentsData.AdjustmentKind <> VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods)
	|	AND (DocumentTable.Products.ItemsType NOT IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|		OR DocumentTable.Products.ItemsType IS NULL)
	|
	|GROUP BY
	|	PreviousDocuments.Main,
	|	ISNULL(ProductLines_2.LineNumber, 99999),
	|	DocumentTable.Content,
	|	DocumentTable.Products,
	|	DocumentTable.Characteristic,
	|	DocumentTable.VATRate
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsData.Ref AS Ref,
	|	FALSE AS ToReturnReusablePackage,
	|	ISNULL(ProductLines_2.LineNumber, 99999) AS LineNumber,
	|	DocumentTable.Content AS Content,
	|	DocumentTable.Products AS Products,
	|	DocumentTable.Characteristic AS Characteristic,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	&EmptyCCD AS CCDNumber,
	|	
	|	CASE WHEN SUM(DocumentTable.Count) > 0 THEN
	|		SUM(DocumentTable.Count)
	|	ELSE
	|		-SUM(DocumentTable.Count)
	|	END AS Count,
	|	
	|	CASE WHEN SUM(DocumentTable.Count) > 0 THEN
	|		SUM(DocumentTable.Count)
	|	ELSE
	|		-SUM(DocumentTable.Count)
	|	END AS NumberOfPackages,
	|	
	|	CASE WHEN SUM(DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount) > 0 THEN
	|		SUM(DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount)
	|	ELSE
	|		-(SUM(DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount))
	|	END AS AmountExcludingVAT,
	|	
	|	DocumentTable.VATRate AS VATRate,
	|	
	|	CASE WHEN SUM(DocumentTable.VATAmount) > 0 THEN
	|		SUM(DocumentTable.VATAmount)
	|	ELSE
	|		-SUM(DocumentTable.VATAmount)
	|	END AS VATAmount,
	|	
	|	FALSE AS ThisIsAProduct,
	|	FALSE AS ThisIsNotReturnContainer,
	|	FALSE AS BeforeAdjustment
	|
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS DocumentTable
	|	
	|	INNER JOIN
	|		Document.SaleAdjustment AS DocumentsData
	|	ON
	|		DocumentTable.Ref = DocumentsData.Ref
	|	
	|	LEFT JOIN
	|		ProductLines_2 AS ProductLines_2
	|	ON
	|		DocumentTable.Ref           = ProductLines_2.Ref
	|		AND DocumentTable.Products   = ProductLines_2.Products
	|		AND DocumentTable.Content     = ProductLines_2.Content
	|		AND DocumentTable.Characteristic = ProductLines_2.Characteristic
	|		AND DocumentTable.Package       = ProductLines_2.Package
	|
	|WHERE
	|	DocumentsData.AdjustmentKind IN (
	|		VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods),
	|		VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods))
	|	AND (DocumentTable.Products.ItemsType NOT IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|	OR DocumentTable.Products.ItemsType IS NULL)
	|
	|GROUP BY
	|	DocumentsData.Ref,
	|	ISNULL(ProductLines_2.LineNumber, 99999),
	|	DocumentTable.Content,
	|	DocumentTable.Products,
	|	DocumentTable.Characteristic,
	|	DocumentTable.VATRate
	|
	|UNION ALL
	|
	|SELECT
	|	PreviousDocuments.Main AS Ref,
	|	FALSE AS ToReturnReusablePackage,
	|	ISNULL(ProductLines_2.LineNumber, 99999)              AS LineNumber,
	|	DocumentTable.Content AS Content,
	|	DocumentTable.Products AS Products,
	|	DocumentTable.Characteristic AS Characteristic,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	&EmptyCCD                                             AS CCDNumber,
	|	SUM(DocumentTable.Count) AS Count,
	|	SUM(DocumentTable.Count) AS NumberOfPackages,
	|	SUM(DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount) AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	SUM(DocumentTable.VATAmount) AS VATAmount,
	|	FALSE                                                  AS ThisIsAProduct,
	|	FALSE                                                  AS ThisIsNotReturnContainer,
	|	TRUE                        AS BeforeAdjustment
	|
	|FROM
	|	Document.SaleAdjustment.Goods AS DocumentTable
	|	
	|	INNER JOIN
	|		PreviousDocuments AS PreviousDocuments
	|	ON
	|		DocumentTable.Ref = PreviousDocuments.Previous
	|	
	|	LEFT JOIN
	|		ProductLines_2 AS ProductLines_2
	|	ON
	|		DocumentTable.Ref           = ProductLines_2.Ref
	|		AND DocumentTable.Products   = ProductLines_2.Products
	|		AND DocumentTable.Content     = ProductLines_2.Content
	|		AND DocumentTable.Characteristic = ProductLines_2.Characteristic
	|		AND DocumentTable.Package       = ProductLines_2.Package
	|
	|WHERE
	|	&IncludingBeforeAdjustment
	|	AND (DocumentTable.Products.ItemsType NOT IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|	OR DocumentTable.Products.ItemsType IS NULL)
	|
	|GROUP BY
	|	PreviousDocuments.Main,
	|	ISNULL(ProductLines_2.LineNumber, 99999),
	|	DocumentTable.Content,
	|	DocumentTable.Products,
	|	DocumentTable.Characteristic,
	|	DocumentTable.VATRate
	|
	|UNION ALL
	|
	|SELECT
	|	PreviousDocuments.Main AS Ref,
	|	FALSE AS ToReturnReusablePackage,
	|	ISNULL(ProductLines_2.LineNumber, 99999)              AS LineNumber,
	|	"""" AS Content,
	|	DocumentTable.Products AS Products,
	|	DocumentTable.Characteristic AS Characteristic,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	&EmptyCCD                                             AS CCDNumber,
	|	SUM(DocumentTable.Count) AS Count,
	|	SUM(DocumentTable.Count) AS NumberOfPackages,
	|	SUM(DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount) AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	SUM(DocumentTable.VATAmount) AS VATAmount,
	|	FALSE                                                  AS ThisIsAProduct,
	|	FALSE                                                  AS ThisIsNotReturnContainer,
	|	TRUE                        AS BeforeAdjustment
	|
	|FROM
	|	Document.CustomerInvoice.Goods AS DocumentTable
	|	
	|	INNER JOIN
	|		PreviousDocuments AS PreviousDocuments
	|	ON
	|		DocumentTable.Ref = PreviousDocuments.Previous
	|	
	|	LEFT JOIN
	|		ProductLines_2 AS ProductLines_2
	|	ON
	|		DocumentTable.Ref           = ProductLines_2.Ref
	|		AND DocumentTable.Products   = ProductLines_2.Products
	|		AND ProductLines_2.Content = """"
	|		AND DocumentTable.Characteristic = ProductLines_2.Characteristic
	|		AND DocumentTable.Package       = ProductLines_2.Package
	|
	|WHERE
	|	&IncludingBeforeAdjustment
	|	AND DocumentTable.Products.ItemsType NOT IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	PreviousDocuments.Main,
	|	ISNULL(ProductLines_2.LineNumber, 99999),
	|	DocumentTable.Products,
	|	DocumentTable.Characteristic,
	|	DocumentTable.VATRate
	|
	|UNION ALL
	|
	|SELECT
	|	PreviousDocuments.Main AS Ref,
	|	FALSE AS ToReturnReusablePackage,
	|	ISNULL(ProductLines_2.LineNumber, 99999)              AS LineNumber,
	|	DocumentTable.Content AS Content,
	|	DocumentTable.Products AS Products,
	|	DocumentTable.Characteristic AS Characteristic,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	&EmptyCCD                                             AS CCDNumber,
	|	SUM(DocumentTable.Count) AS Count,
	|	SUM(DocumentTable.Count) AS NumberOfPackages,
	|	SUM(DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount) AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	SUM(DocumentTable.VATAmount) AS VATAmount,
	|	FALSE                                                  AS ThisIsAProduct,
	|	FALSE                                                  AS ThisIsNotReturnContainer,
	|	TRUE                        AS BeforeAdjustment
	|
	|FROM
	|	Document.CustomerInvoiceServices.Services AS DocumentTable
	|	
	|	INNER JOIN
	|		PreviousDocuments AS PreviousDocuments
	|	ON
	|		DocumentTable.Ref = PreviousDocuments.Previous
	|	
	|	LEFT JOIN
	|		ProductLines_2 AS ProductLines_2
	|	ON
	|		DocumentTable.Ref           = ProductLines_2.Ref
	|		AND DocumentTable.Products   = ProductLines_2.Products
	|		AND DocumentTable.Content     = ProductLines_2.Content
	|		AND DocumentTable.Characteristic = ProductLines_2.Characteristic
	|		AND ProductLines_2.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|
	|WHERE
	|	&IncludingBeforeAdjustment
	|
	|GROUP BY
	|	PreviousDocuments.Main,
	|	ISNULL(ProductLines_2.LineNumber, 99999),
	|	DocumentTable.Content,
	|	DocumentTable.Products,
	|	DocumentTable.Characteristic,
	|	DocumentTable.VATRate
	|
	|UNION ALL
	|
	|SELECT
	|	PreviousDocuments.Main AS Ref,
	|	FALSE AS ToReturnReusablePackage,
	|	ISNULL(ProductLines_2.LineNumber, 99999)              AS LineNumber,
	|	DocumentTable.Content AS Content,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	&EmptyCCD                                             AS CCDNumber,
	|	SUM(DocumentTable.Count) AS Count,
	|	SUM(DocumentTable.Count) AS NumberOfPackages,
	|	SUM(DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount) AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	SUM(DocumentTable.VATAmount) AS VATAmount,
	|	FALSE                                                  AS ThisIsAProduct,
	|	FALSE                                                  AS ThisIsNotReturnContainer,
	|	TRUE                        AS BeforeAdjustment
	|
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets.Income AS DocumentTable
	|	
	|	INNER JOIN
	|		PreviousDocuments AS PreviousDocuments
	|	ON
	|		DocumentTable.Ref = PreviousDocuments.Previous
	|	
	|	LEFT JOIN
	|		ProductLines_2 AS ProductLines_2
	|	ON
	|		DocumentTable.Ref           = ProductLines_2.Ref
	|		AND ProductLines_2.Products = VALUE(Catalog.Products.EmptyRef)
	|		AND DocumentTable.Content     = ProductLines_2.Content
	|		AND ProductLines_2.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|		AND ProductLines_2.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|
	|WHERE
	|	&IncludingBeforeAdjustment
	|
	|GROUP BY
	|	PreviousDocuments.Main,
	|	ISNULL(ProductLines_2.LineNumber, 99999),
	|	DocumentTable.Content,
	|	DocumentTable.VATRate
	|
	|INDEX BY
	|	Ref,
	|	LineNumber
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|DROP TTRelatedDocuments
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|DROP PreviousDocuments
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|DROP ProductLines_2
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|DROP TTTypesOfStocks
	|";
	
	Query.Execute();
	
EndProcedure

// Returns the base text based on the document data and the specified calculation order
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.SaleAdjustment - Object of the document to get the base text from
//	ARAPObjectSettings - EnumRef.ARAPObjectSettings - Procedure of settlements.
//
// Returns:
//	Structure - Structure with the name, date and number of the foundation.
//
Function BaseStructure(Object, ARAPObjectSettings)
	
	StructureBase = New Structure;
	StructureBase.Insert("Basis");
	StructureBase.Insert("BaseDocumentNumber");
	StructureBase.Insert("ReferenceDocumentDateForPrintForms");
	
	If (ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		And ValueIsFilled(Object.Contract) Then
		
		Query = New Query(
			"SELECT ALLOWED
			|	CounterpartyContracts.NameForPrinting AS Basis,
			|	CounterpartyContracts.Date AS ReferenceDocumentDateForPrintForms,
			|	CounterpartyContracts.Number AS BaseDocumentNumber
			|FROM
			|	Catalog.CounterpartyContracts AS CounterpartyContracts
			|WHERE
			|	CounterpartyContracts.Ref = &Ref");
		Query.SetParameter("Ref", Object.Contract);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			StructureBase.Basis = TrimAll(Selection.Basis);
			StructureBase.ReferenceDocumentDateForPrintForms = Selection.ReferenceDocumentDateForPrintForms;
			StructureBase.BaseDocumentNumber = TrimAll(Selection.BaseDocumentNumber);
		EndIf;
		
	ElsIf (ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		And Object.SaleByOrders Then
		
		If Object.Goods.Count() <> 0 Then
		
			QueriesTexts = New Array;
			
			If AccessRight("Read", Metadata.Documents.SalesOrder) Then
				QueryTextDocument = 
					"SELECT ALLOWED
					|	CASE
					|		WHEN
					|			SalesOrders.NumberAccordingToCustomerData <> """" AND SalesOrders.DateAccordingToInformationFromCustomer <> DATETIME(1,1,1)
					|		THEN
					|			SalesOrders.NumberAccordingToCustomerData
					|		ELSE
					|			SalesOrders.Number
					|	END AS Number,
					|	CASE
					|		WHEN
					|			SalesOrders.NumberAccordingToCustomerData <> """" AND SalesOrders.DateAccordingToInformationFromCustomer <> DATETIME(1,1,1)
					|		THEN
					|			SalesOrders.DateAccordingToInformationFromCustomer
					|		ELSE
					|			SalesOrders.Date
					|	END AS Date,
					|	&SynonymForOrder AS Synonym
					|FROM
					|	Document.SalesOrder AS SalesOrders
					|WHERE
					|	SalesOrders.Ref IN(&AnArrayOfOrders)";
				QueriesTexts.Add(QueryTextDocument);
			EndIf;
			
			If AccessRight("Read", Metadata.Documents.RequestForReturnOfGoodsFromCustomer) Then
				QueryTextDocument = 
					"SELECT
					|	RequestsForReturn.Number AS Number,
					|	RequestsForReturn.Date AS Date,
					|	&ApplicationSynonym AS Synonym
					|FROM
					|	Document.RequestForReturnOfGoodsFromCustomer AS RequestsForReturn
					|WHERE
					|	RequestsForReturn.Ref IN(&AnArrayOfOrders)";
				If QueriesTexts.Count() = 0 Then
					QueryTextDocument = StrReplace(QueryTextDocument, "SELECT", "SELECT ALLOWED"); //@Query-part-1 @Query-part-2
				EndIf;
				QueriesTexts.Add(QueryTextDocument);
			EndIf;
			
			If QueriesTexts.Count() = 0 Then
				Return StructureBase; // Returning the default value
			EndIf;
			
			QueryText = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
			
			Query = New Query(QueryText);
			
			If TypeOf(Object) = Type("Structure") Then
				AnArrayOfOrders = Object.Goods.UnloadColumn("SalesOrder");
			Else
				AnArrayOfOrders = Object.Goods.Unload(,"SalesOrder").UnloadColumn("SalesOrder");
			EndIf;
			
			Query.SetParameter("AnArrayOfOrders", AnArrayOfOrders);
			Query.SetParameter("SynonymForOrder", NStr("vi = 'Đơn hàng của khách';
														|ru = 'Заказ клиента';
														|en = 'Sales order'; fa = 'سفارش فروش';
														|it = 'Ordine del cliente';
														|pl = 'Zamówienie klienta';
														|tr = 'Satış siparişi'"));
			Query.SetParameter("ApplicationSynonym", NStr("vi = 'Giấy đề nghị đổi hàng';
															|ru = 'Заявка на замену';
															|en = 'Request for replacement'; fa = 'Request for replacement';
															|it = 'Domanda di sostituzione';
															|pl = 'Wniosek o wymianę';
															|tr = 'Değiştirme talebi'"));
			Selection = Query.Execute().Select();
			
			StructureBase.Basis = "";
			OneFoundation = Selection.Count() = 1;
			While Selection.Next() Do
				StructureBase.Basis = StructureBase.Basis + ", " + TMCommonUseClientServer.GenerateDocumentTitle(Selection, Selection.Synonym);
				DateForOrders  = Selection.Date;
				OrderNumber_1 = Selection.Number;
			EndDo;
			StructureBase.Basis = TrimAll(Mid(StructureBase.Basis, 3));
			StructureBase.ReferenceDocumentDateForPrintForms = ?(OneFoundation, DateForOrders, "");
			StructureBase.BaseDocumentNumber = ?(OneFoundation,ObjectsPrefixesClientServer.NumberForPrinting(OrderNumber_1),"");
		EndIf;
		
	EndIf;
	
	Return StructureBase; // Returning the default value
	
EndFunction

// Returns a table of settlement amounts broken down by container/non-container and broken down by order.
// 
// Parameters:
//  ObjectReference_ - DocumentRef.SaleAdjustment - The document for which you want to get the data.
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
	|	Goods.SalesOrder        AS OrderDocument,
	|	Goods.AmountIncludingVAT           AS Sum,
	|	Goods.AmountARAP AS AmountARAP,
	|	CAST(Goods.Products AS Catalog.Products) AS Products,
	|	&ToReturnReusablePackage AS ToReturnReusablePackage,
	|	&PackageDepositIsRequired      AS PackageDepositIsRequired
	|INTO TTProducts_1
	|FROM &ValueTable AS Goods
	|WHERE &LinkCondition_
	|;
	|SELECT 
	|	NestedQuery.OrderDocument                            AS OrderDocument,
	|	ISNULL(NestedQuery.OrderDocument.DATE, DATETIME(1,1,1)) AS OrderDate,
	|	ISNULL(NestedQuery.OrderDocument.ApprovalDate, DATETIME(1,1,1)) AS ApprovalDate,
	|	FALSE                                             AS ExceedingOrder,
	|	SUM(NestedQuery.PaymentAmount)              AS PaymentAmount,
	|	SUM(NestedQuery.AmountARAP)       AS AmountARAP,
	|	SUM(NestedQuery.PackageDepositValue)         AS PackageDepositValue,
	|	SUM(NestedQuery.AmountARAPByPackage) AS AmountARAPByPackage
	|FROM (SELECT
	|		Goods.OrderDocument AS OrderDocument,
	|		CASE
	|			WHEN (Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|					OR NOT Goods.ToReturnReusablePackage)
	|					AND Goods.Sum > 0
	|				THEN Goods.Sum
	|			ELSE 0 
	|		END                             AS PaymentAmount,
	|		CASE
	|			WHEN (Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|					OR NOT Goods.ToReturnReusablePackage)
	|					AND Goods.AmountARAP > 0
	|				THEN Goods.AmountARAP
	|			ELSE 0 
	|		END                             AS AmountARAP,
	|		CASE 
	|			WHEN Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND Goods.PackageDepositIsRequired
	|				AND Goods.Sum > 0
	|				THEN Goods.Sum
	|			ELSE 0 
	|		END                            AS PackageDepositValue,
	|		CASE 
	|			WHEN Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND Goods.PackageDepositIsRequired
	|				AND Goods.AmountARAP > 0
	|				THEN Goods.AmountARAP
	|			ELSE 0 
	|		END                            AS AmountARAPByPackage
	|	FROM TTProducts_1 AS Goods) AS NestedQuery
	|GROUP BY
	|	NestedQuery.OrderDocument,
	|	ISNULL(NestedQuery.OrderDocument.DATE, DATETIME(1,1,1)),
	|	ISNULL(NestedQuery.OrderDocument.ApprovalDate, DATETIME(1,1,1))
	|;";
	
	If AttributesValues = Undefined Then
		
		AdjustmentKind = Common.ObjectAttributeValue(ObjectReference_, "AdjustmentKind");
		Query.SetParameter("Ref", ObjectReference_);
		
		If AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated
			Or AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated Then
				
			Query.Text = "
			|SELECT 
			|	UNDEFINED                                     AS OrderDocument,
			|	DATETIME(1,1,1)                                 AS OrderDate,
			|	DATETIME(1,1,1)                                 AS ApprovalDate,
			|	FALSE                                             AS ExceedingOrder,
			|	SUM(CASE 
			|		WHEN ARAPAdjustment.AmountIncludingVAT > 0
			|			THEN ARAPAdjustment.AmountIncludingVAT
			|		ELSE 0 
			|	END)                                           AS PaymentAmount,
			|	SUM(CASE 
			|		WHEN ARAPAdjustment.AmountARAP > 0
			|			THEN ARAPAdjustment.AmountARAP
			|		ELSE 0 
			|	END)                                           AS AmountARAP,
			|	0                                                AS PackageDepositValue,
			|	0                                                AS AmountARAPByPackage
			|FROM 
			|	Document.SaleAdjustment.ARAPAdjustment AS ARAPAdjustment
			|WHERE
			|	ARAPAdjustment.Ref = &Ref";
			
		Else
			
			ConditionToReturnMultiTurnContainer = "CASE
			|		WHEN Goods.Ref.DocumentBasis REFS Document.CustomerInvoice
			|			THEN ISNULL(Goods.Ref.DocumentBasis.ToReturnReusablePackage, FALSE)
			|		ELSE FALSE
			|	END";
			
			ConditionRequiresDepositForContainer = "CASE
			|		WHEN Goods.Ref.DocumentBasis REFS Document.CustomerInvoice
			|			THEN ISNULL(Goods.Ref.DocumentBasis.PackageDepositIsRequired, FALSE)
			|		ELSE FALSE
			|	END";
			
			Query.Text = StrReplace(Query.Text, "&ValueTable", "Document.SaleAdjustment.Discrepancies");
			Query.Text = StrReplace(Query.Text, "&TableDebtAdjustment", "Document.SaleAdjustment.ARAPAdjustment");
			Query.Text = StrReplace(Query.Text, "&ToReturnReusablePackage", ConditionToReturnMultiTurnContainer);
			Query.Text = StrReplace(Query.Text, "&PackageDepositIsRequired", ConditionRequiresDepositForContainer);
			Query.Text = StrReplace(Query.Text, "&LinkCondition_", "Goods.Ref = &Ref");
		EndIf;
		
	Else
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "TRUE");
		
		For Each KeyValue In AttributesValues Do
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
		EndDo;
		
		If AttributesValues.ValueTable.Count() = 0
			Or Not CommonClientServer.HasAttributeOrObjectProperty(AttributesValues.ValueTable[0],"Products") Then
			Query.Text = "
			|SELECT
			|	Goods.AmountIncludingVAT           AS Sum,
			|	Goods.AmountARAP AS AmountARAP
			|INTO TTProducts_1
			|FROM &ValueTable AS Goods
			|;
			|SELECT 
			|	UNDEFINED                                     AS OrderDocument,
			|	DATETIME(1,1,1)                                 AS OrderDate,
			|	DATETIME(1,1,1)                                 AS ApprovalDate,
			|	FALSE                                             AS ExceedingOrder,
			|	SUM(CASE 
			|		WHEN TTProducts_1.Sum > 0
			|			THEN TTProducts_1.Sum
			|		ELSE 0 
			|	END)                                           AS PaymentAmount,
			|	SUM(CASE 
			|		WHEN TTProducts_1.AmountARAP > 0
			|			THEN TTProducts_1.AmountARAP
			|		ELSE 0 
			|	END)                                           AS AmountARAP,
			|	0                                                AS PackageDepositValue,
			|	0                                                AS AmountARAPByPackage
			|FROM TTProducts_1 AS TTProducts_1";
		Else
			Query.Text = StrReplace(Query.Text, "&LinkCondition_", "TRUE");
		EndIf;
		
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

// Returns the "Business operation" details of the foundation document
//
// Parameters:
// 	DocumentBasis - DocumentRef
//
// Returns:
// 	EnumRef.BusinessTransactions
//
Function EconomicOperationOfFoundationDocument(DocumentBasis) Export
	
	Operation = Enums.BusinessTransactions.EmptyRef();
	BasisType = TypeOf(DocumentBasis);
	
	If ValueIsFilled(DocumentBasis) Then
		If BasisType = Type("DocumentRef.CustomerInvoiceServices")
			Or BasisType = Type("DocumentRef.SourceDocument") Then
			Operation = Enums.BusinessTransactions.SaleToCustomer;
		Else
			SetPrivilegedMode(True);
			Operation = Common.ObjectAttributeValue(DocumentBasis, "BusinessOperation");
		EndIf;
	EndIf;
	
	Return Operation;
	
EndFunction

// Returns a list of values with reflection options for which the warehouse must be filled
// in in the credit note.
//
// Returns:
//	ValueList of EnumRef.CreditNoteRecordingOptions
//	
Function ReflectionsOptionsWithMandatoryWarehouse() Export

	ReflectionOptionsWithMandatoryWarehouse = New ValueList();
	ReflectionOptionsWithMandatoryWarehouse.Add(
		Enums.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock);
	ReflectionOptionsWithMandatoryWarehouse.Add(
		Enums.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount);
	ReflectionOptionsWithMandatoryWarehouse.Add(
		Enums.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock);
	ReflectionOptionsWithMandatoryWarehouse.Add(
		Enums.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount);

	Return ReflectionOptionsWithMandatoryWarehouse;

EndFunction

#Region CheckingDocumentFilling

// Returns a table of products with selection by reflection option, according to the adjustment table.
//
// Parameters:
//	VTAdjustmentTable - ValueTable - adjustment table.
//	FilterWriteOffLines - Boolean - indicates whether rows are selected based on the reflection option.
//
// Returns:
//	ValueTable - table of items to be debited.
//
Function TableOfProductsByReflectionOption(VTAdjustmentTable, FilterWriteOffLines = True)
	
	VTOFGoodsToBeDebited	= VTAdjustmentTable.CopyColumns();
	ItemsTypes			= ProductsClientServer.SelectionByProductMultiTurnContainer(False);
	
	ItemsTypes.Add(Enums.ItemsTypes.Work_5);
	
	ComplianceOfProductWithType	= Common.ObjectsAttributeValue(
										VTAdjustmentTable.UnloadColumn("Products"),
										"ItemsType");
	
	For Each TSRow In VTAdjustmentTable Do
		ItemsType = ComplianceOfProductWithType.Get(TSRow.Products);
		
		If FilterWriteOffLines
			And ItemsTypes.Find(ItemsType) <> Undefined
			And Not (TSRow.Count - TSRow.QuantityAfter < 0
				Or TSRow.NumberOfPackages - TSRow.NumberOfPackagesAfter < 0) Then
			
			NewRow = VTOFGoodsToBeDebited.Add();
			FillPropertyValues(NewRow, TSRow,);
			
		ElsIf Not FilterWriteOffLines
			And ItemsTypes.Find(ItemsType) <> Undefined Then
			
			NewRow = VTOFGoodsToBeDebited.Add();
			FillPropertyValues(NewRow, TSRow);
			
		EndIf;
	EndDo;
	
	Return VTOFGoodsToBeDebited;
	
EndFunction

Function QueryTextTTOfSalesDocument()
	
	QueryText =
	"SELECT
	|	&VATTaxation AS VATTaxation
	|INTO TemporaryTableSalesDocument";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTablesOfProductsForRequest()
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber				AS LineNumber,
	|	TableOfGoods.Content				AS Content,
	|	CAST(TableOfGoods.ProductsInSet AS Catalog.Products) AS ProductsInSet,
	|	CAST(TableOfGoods.ItemVariantOfSet AS Catalog.ItemsCharacteristics) AS ItemVariantOfSet,
	|	CAST(TableOfGoods.Products AS Catalog.Products) AS Products,
	|	CAST(TableOfGoods.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	CAST(TableOfGoods.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	CAST(TableOfGoods.CCDNumber AS Catalog.CCDNumbers) AS CCDNumber,
	|	TableOfGoods.Count				AS Count,
	|	TableOfGoods.NumberOfPackages		AS NumberOfPackages,
	|	TableOfGoods.QuantityAfter			AS QuantityAfter,
	|	TableOfGoods.NumberOfPackagesAfter	AS NumberOfPackagesAfter,
	|	TableOfGoods.QuantityByGBRN			AS QuantityByGBRN,
	|	TableOfGoods.QuantityAccordingToRNPTAfter	AS QuantityAccordingToRNPTAfter,
	|	TableOfGoods.Price						AS Price,
	|	ISNULL(TableOfGoods.PriceAfter,0)	AS PriceAfter,
	|	TableOfGoods.Sum					AS Sum,
	|	ISNULL(TableOfGoods.AmountAfter,0)	AS AmountAfter,
	|	ISNULL(TableOfGoods.VATRate, VALUE(Catalog.VATRates.EmptyRef)) AS VATRate,
	|	ISNULL(TableOfGoods.VATRateAfter, VALUE(Catalog.VATRates.EmptyRef)) AS VATRateAfter,
	|	TableOfGoods.VATAmount					AS VATAmount,
	|	TableOfGoods.VATAmountAfter			AS VATAmountAfter,
	|	TableOfGoods.AmountIncludingVAT				AS AmountIncludingVAT,
	|	TableOfGoods.AmountWithVATAfter			AS AmountWithVATAfter,
	|	TableOfGoods.PostingOption			AS PostingOption,
	|	TableOfGoods.OptionToReflectWriteOff	AS OptionToReflectWriteOff,
	|	CAST(TableOfGoods.Warehouse AS Catalog.Warehouses) AS Warehouse,
	|	CAST(TableOfGoods.Department AS Catalog.BusinessStructure) AS Department,
	|	TableOfGoods.CostDefiningMethod AS CostDefiningMethod,
	|	TableOfGoods.IncomeItem			AS IncomeItem,
	|	TableOfGoods.DimensionOfRevenue			AS DimensionOfRevenue,
	|	TableOfGoods.Series					AS Series,
	|	TableOfGoods.AmountARAP		AS AmountARAP,
	|	TableOfGoods.AmountOfSettlementsAfter	AS AmountOfSettlementsAfter
	|
	|INTO TableOfProductsToRequest
	|FROM
	|	&TableOfGoods AS TableOfGoods";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTablesSetsPreparation()
	
	QueryText =
	"SELECT
	|	MIN(TableOfGoods.LineNumber)		AS LineNumber,
	|	TableOfGoods.ProductsInSet		AS ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet		AS ItemVariantOfSet,
	|	SUM(TableOfGoods.Sum)				AS Sum,
	|	SUM(TableOfGoods.VATAmount)			AS VATAmount,
	|	SUM(TableOfGoods.AmountAfter)		AS AmountAfter,
	|	SUM(TableOfGoods.VATAmountAfter)		AS VATAmountAfter,
	|	MAX(TableOfGoods.VATRate)		AS MaximumVATRate,
	|	MAX(TableOfGoods.VATRateAfter)	AS MaximumVATRateAfter,
	|	MIN(TableOfGoods.VATRate)		AS MinimumVATRate_,
	|	MIN(TableOfGoods.VATRateAfter)	AS MinimumVATRateAfter
	|INTO TableSetsPreparation
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON TableOfGoods.ProductsInSet = ProductKitConfigurations.Owner
	|			AND TableOfGoods.ItemVariantOfSet = ProductKitConfigurations.Characteristic
	|			AND ProductKitConfigurations.Main
	|WHERE
	|	ProductKitConfigurations.SetPricingOption IN
	|		(VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),
	|		VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares))
	|
	|GROUP BY
	|	TableOfGoods.ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableSetsOptional()
	
	QueryText =
	"SELECT
	|	TableOfGoods.ProductsInSet		AS ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet	AS ItemVariantOfSet,
	|	SUM(CASE
	|			WHEN ISNULL(Components.Count, 0) <> 0
	|				THEN TableOfGoods.Count / Components.Count
	|			ELSE 1
	|	END)							AS Count,
	|	SUM(CASE
	|			WHEN ISNULL(Components.Count, 0) <> 0
	|				THEN TableOfGoods.QuantityAfter / Components.Count
	|			ELSE 1
	|	END)							AS QuantityAfter
	|INTO TableSetsOptional
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON TableOfGoods.ProductsInSet = ProductKitConfigurations.Owner
	|			AND TableOfGoods.ItemVariantOfSet = ProductKitConfigurations.Characteristic
	|			AND ProductKitConfigurations.Main
	|		
	|		LEFT JOIN Catalog.ProductKitConfigurations.Goods AS Components
	|		ON Components.Ref = ProductKitConfigurations.Ref
	|			AND TableOfGoods.Products = Components.Ref.ProductsOfMainComponent
	|			AND TableOfGoods.Characteristic = Components.Ref.MainComponentCharacteristic
	|			AND TableOfGoods.Products = Components.Products
	|			AND TableOfGoods.Characteristic = Components.Characteristic
	|
	|WHERE
	|	NOT Components.Count IS NULL
	|	AND ProductKitConfigurations.SetPricingOption IN
	|		(VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),
	|		VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares))
	|	
	|GROUP BY
	|	TableOfGoods.ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableSets()
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber 			AS LineNumber,
	|	TableOfGoods.ProductsInSet	AS ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet	AS ItemVariantOfSet,
	|	CASE 
	|		WHEN ISNULL(TableSetsOptional.Count, 1) <> 0
	|			THEN TableOfGoods.Sum / ISNULL(TableSetsOptional.Count, 1)
	|		ELSE TableOfGoods.Sum 
	|	END AS Price,
	|	CASE
	|		WHEN ISNULL(TableSetsOptional.QuantityAfter, 1) <> 0
	|			THEN TableOfGoods.AmountAfter / ISNULL(TableSetsOptional.QuantityAfter, 1)
	|		ELSE TableOfGoods.AmountAfter
	|	END AS PriceAfter,
	|	TableOfGoods.Sum				AS Sum,
	|	TableOfGoods.AmountAfter			AS AmountAfter,
	|	CASE
	|		WHEN TableOfGoods.MaximumVATRate = TableOfGoods.MinimumVATRate_
	|			THEN TableOfGoods.MaximumVATRate
	|		ELSE VALUE(Catalog.VATRates.EmptyRef)
	|	END								AS VATRate,
	|	CASE
	|		WHEN TableOfGoods.MaximumVATRateAfter = TableOfGoods.MinimumVATRateAfter
	|			THEN TableOfGoods.MaximumVATRateAfter
	|		ELSE VALUE(Catalog.VATRates.EmptyRef)
	|	END								AS VATRateAfter,
	|	TableOfGoods.VATAmount				AS VATAmount,
	|	TableOfGoods.VATAmountAfter		AS VATAmountAfter
	|INTO TableSets
	|FROM
	|	TableSetsPreparation AS TableOfGoods
	|		LEFT JOIN TableSetsOptional AS TableSetsOptional
	|		ON TableOfGoods.ProductsInSet = TableSetsOptional.ProductsInSet
	|			AND TableOfGoods.ItemVariantOfSet = TableSetsOptional.ItemVariantOfSet";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTablesGoods()
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber			AS LineNumber,
	|	TableOfGoods.SourceLineNumber	AS SourceLineNumber,
	|	TableOfGoods.ProductsInSet	AS ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet	AS ItemVariantOfSet,
	|	TableOfGoods.TheseAreComponents		AS TheseAreComponents,
	|	TableOfGoods.IsRecordsSet				AS IsRecordsSet,
	|	TableOfGoods.Products			AS Products,
	|	TableOfGoods.Characteristic		AS Characteristic,
	|	TableOfGoods.Price					AS Price,
	|	TableOfGoods.PriceAfter			AS PriceAfter,
	|	TableOfGoods.Sum				AS Sum,
	|	TableOfGoods.AmountAfter			AS AmountAfter,
	|	TableOfGoods.VATRate			AS VATRate,
	|	TableOfGoods.VATRateAfter		AS VATRateAfter,
	|	TableOfGoods.VATAmount				AS VATAmount,
	|	TableOfGoods.VATAmountAfter		AS VATAmountAfter
	|INTO TemporaryTableOfGoods_
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN ISNULL(TableSets.LineNumber, 0) <> 0
	|				THEN TableSets.LineNumber
	|			ELSE Table.LineNumber
	|		END							AS LineNumber,
	|		Table.LineNumber				AS SourceLineNumber,
	|		Table.ProductsInSet		AS ProductsInSet,
	|		Table.ItemVariantOfSet	AS ItemVariantOfSet,
	|		CASE
	|			WHEN ISNULL(TableSets.LineNumber, 0) <> 0
	|				THEN TRUE
	|			ELSE FALSE
	|		END							AS TheseAreComponents,
	|		FALSE							AS IsRecordsSet,
	|		Table.Products			AS Products,
	|		Table.Characteristic			AS Characteristic,
	|		Table.Price					AS Price,
	|		Table.PriceAfter				AS PriceAfter,
	|		Table.Sum					AS Sum,
	|		Table.AmountAfter				AS AmountAfter,
	|		Table.VATRate				AS VATRate,
	|		Table.VATRateAfter			AS VATRateAfter,
	|		Table.VATAmount				AS VATAmount,
	|		Table.VATAmountAfter			AS VATAmountAfter
	|	FROM
	|		TableOfProductsToRequest AS Table
	|			LEFT JOIN TableSets AS TableSets
	|			ON Table.ProductsInSet = TableSets.ProductsInSet
	|				AND Table.ItemVariantOfSet = TableSets.ItemVariantOfSet
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.LineNumber				AS LineNumber,
	|		Table.LineNumber				AS SourceLineNumber,
	|		Table.ProductsInSet		AS ProductsInSet,
	|		Table.ItemVariantOfSet	AS ItemVariantOfSet,
	|		FALSE							AS TheseAreComponents,
	|		TRUE							AS IsRecordsSet,
	|		Table.ProductsInSet		AS Products,
	|		Table.ItemVariantOfSet	AS Characteristic,
	|		Table.Price					AS Price,
	|		Table.PriceAfter				AS PriceAfter,
	|		Table.Sum					AS Sum,
	|		Table.AmountAfter				AS AmountAfter,
	|		Table.VATRate				AS VATRate,
	|		Table.VATRateAfter			AS VATRateAfter,
	|		Table.VATAmount				AS VATAmount,
	|		Table.VATAmountAfter			AS VATAmountAfter
	|	FROM
	|		TableSets AS Table
	|	
	|	) AS TableOfGoods";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTFoundationDocumentData()
	
	QueryText =
	"SELECT
	|	DocumentBasis.Organization AS Organization,
	|	DocumentBasis.Counterparty AS Counterparty,
	|	DocumentBasis.Contract AS Contract,
	|	DocumentBasis.Partner AS Partner,
	|	DocumentBasis.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentBasis.VATTaxation AS VATTaxation
	|INTO FoundationDocumentData
	|FROM
	|	Document.SourceDocument AS DocumentBasis
	|WHERE
	|	DocumentBasis.Ref = &DocumentBasis";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTPreviousAdjustmentData() Export
	
	QueryText =
		"SELECT TOP 1
		|	SaleAdjustment.Ref AS Ref,
		|	SaleAdjustment.AdjustingEntryType AS AdjustingEntryType,
		|	SaleAdjustment.DocumentBasis AS DocumentBasis,
		|	SaleAdjustment.Date AS Date,
		|	SaleAdjustment.PriceIncludesVAT AS PriceIncludesVAT
		|INTO TTPreviousAdjustment
		|FROM
		|	Document.SaleAdjustment AS SaleAdjustment
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
		|		ON SaleAdjustment.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
		|		AND (RegisterOfDocumentsStornoCorrection.Posted)
		|		AND (NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord)
		|WHERE
		|	SaleAdjustment.Posted
		|	AND SaleAdjustment.Date < &Date
		|	AND SaleAdjustment.DocumentBasis = &DocumentBasis
		|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
		|
		|ORDER BY
		|	SaleAdjustment.PointInTime DESC
		|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTToCheckDataForLastAdjustment()
	
	QueryText = "SELECT
	|	MAX(AdjustmentTable.LineNumber) AS LineNumber,
	|	AdjustmentTable.Products AS Products,
	|	AdjustmentTable.Characteristic AS Characteristic,
	|	AdjustmentTable.Content AS Content,
	|	AdjustmentTable.Package AS Package,
	|	AdjustmentTable.ProductsInSet AS ProductsInSet,
	|	AdjustmentTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	AdjustmentTable.IncomeItem AS IncomeItem,
	|	AdjustmentTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	AdjustmentTable.Series AS Series,
	|	AdjustmentTable.Warehouse AS Warehouse,
	|	AdjustmentTable.Department AS Department,
	|	AdjustmentTable.VATRate AS VATRate,
	|	SUM(AdjustmentTable.Count) AS Count,
	|	SUM(AdjustmentTable.NumberOfPackages) AS NumberOfPackages,
	|	SUM(AdjustmentTable.Sum) AS Sum,
	|	SUM(AdjustmentTable.VATAmount) AS VATAmount,
	|	SUM(AdjustmentTable.AmountIncludingVAT) AS AmountIncludingVAT
	|INTO TTGoodsTableTotal
	|FROM
	|	TableOfProductsToRequest AS AdjustmentTable
	|WHERE
	|	AdjustmentTable.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|
	|GROUP BY
	|	AdjustmentTable.Products,
	|	AdjustmentTable.Characteristic,
	|	AdjustmentTable.Content,
	|	AdjustmentTable.Package,
	|	AdjustmentTable.ProductsInSet,
	|	AdjustmentTable.ItemVariantOfSet,
	|	AdjustmentTable.IncomeItem,
	|	AdjustmentTable.DimensionOfRevenue,
	|	AdjustmentTable.Series,
	|	AdjustmentTable.Warehouse,
	|	AdjustmentTable.Department,
	|	AdjustmentTable.VATRate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LastAdjustmentData.Products AS Products,
	|	LastAdjustmentData.Characteristic AS Characteristic,
	|	LastAdjustmentData.Content AS Content,
	|	LastAdjustmentData.Package AS Package,
	|	LastAdjustmentData.ProductsInSet AS ProductsInSet,
	|	LastAdjustmentData.ItemVariantOfSet AS ItemVariantOfSet,
	|	LastAdjustmentData.IncomeItem AS IncomeItem,
	|	LastAdjustmentData.DimensionOfRevenue AS DimensionOfRevenue,
	|	LastAdjustmentData.Series AS Series,
	|	LastAdjustmentData.Warehouse AS Warehouse,
	|	LastAdjustmentData.Department AS Department,
	|	SUM(LastAdjustmentData.Count) AS Count,
	|	SUM(LastAdjustmentData.NumberOfPackages) AS NumberOfPackages,
	|	SUM(LastAdjustmentData.Sum) AS Sum,
	|	SUM(LastAdjustmentData.VATAmount) AS VATAmount,
	|	SUM(LastAdjustmentData.AmountIncludingVAT) AS AmountIncludingVAT,
	|	MAX(LastAdjustmentData.VATRate) AS VATRate
	|INTO InitialDataWithoutCCD
	|FROM
	|	(SELECT
	|		LastAdjustmentData.Products AS Products,
	|		LastAdjustmentData.Characteristic AS Characteristic,
	|		LastAdjustmentData.Content AS Content,
	|		LastAdjustmentData.Package AS Package,
	|		LastAdjustmentData.ProductsInSet AS ProductsInSet,
	|		LastAdjustmentData.ItemVariantOfSet AS ItemVariantOfSet,
	|		LastAdjustmentData.IncomeItem AS IncomeItem,
	|		LastAdjustmentData.DimensionOfRevenue AS DimensionOfRevenue,
	|		LastAdjustmentData.Series AS Series,
	|		LastAdjustmentData.Warehouse AS Warehouse,
	|		LastAdjustmentData.Department AS Department,
	|		LastAdjustmentData.Count AS Count,
	|		LastAdjustmentData.NumberOfPackages AS NumberOfPackages,
	|		LastAdjustmentData.Sum AS Sum,
	|		LastAdjustmentData.VATAmount AS VATAmount,
	|		LastAdjustmentData.AmountIncludingVAT AS AmountIncludingVAT,
	|		LastAdjustmentData.VATRate AS VATRate
	|	FROM
	|		RawData AS LastAdjustmentData
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		LastAdjustmentData.Products,
	|		LastAdjustmentData.Characteristic,
	|		LastAdjustmentData.Content,
	|		LastAdjustmentData.Package,
	|		LastAdjustmentData.ProductsInSet,
	|		LastAdjustmentData.ItemVariantOfSet,
	|		LastAdjustmentData.IncomeItem,
	|		LastAdjustmentData.DimensionOfRevenue,
	|		LastAdjustmentData.Series,
	|		LastAdjustmentData.Warehouse,
	|		LastAdjustmentData.Department,
	|		-LastAdjustmentData.Count,
	|		-LastAdjustmentData.NumberOfPackages,
	|		-LastAdjustmentData.Sum,
	|		-LastAdjustmentData.VATAmount,
	|		-LastAdjustmentData.AmountIncludingVAT,
	|		LastAdjustmentData.VATRate
	|	FROM
	|		TableOfProductsToRequest AS LastAdjustmentData
	|	WHERE
	|		LastAdjustmentData.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|
	|	UNION ALL
	|	
	|	SELECT
	|		LastAdjustmentData.Products,
	|		LastAdjustmentData.Characteristic,
	|		LastAdjustmentData.Content,
	|		LastAdjustmentData.Package,
	|		LastAdjustmentData.ProductsInSet,
	|		LastAdjustmentData.ItemVariantOfSet,
	|		LastAdjustmentData.IncomeItem,
	|		LastAdjustmentData.DimensionOfRevenue,
	|		LastAdjustmentData.Series,
	|		LastAdjustmentData.Warehouse,
	|		LastAdjustmentData.Department,
	|		LastAdjustmentData.QuantityAfter,
	|		LastAdjustmentData.NumberOfPackagesAfter,
	|		LastAdjustmentData.AmountAfter,
	|		LastAdjustmentData.VATAmountAfter,
	|		LastAdjustmentData.AmountWithVATAfter,
	|		LastAdjustmentData.VATRateAfter
	|	FROM
	|		TableOfProductsToRequest AS LastAdjustmentData
	|	WHERE
	|		LastAdjustmentData.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)) AS LastAdjustmentData
	|
	|GROUP BY
	|	LastAdjustmentData.Products,
	|	LastAdjustmentData.Characteristic,
	|	LastAdjustmentData.Content,
	|	LastAdjustmentData.Package,
	|	LastAdjustmentData.ProductsInSet,
	|	LastAdjustmentData.ItemVariantOfSet,
	|	LastAdjustmentData.IncomeItem,
	|	LastAdjustmentData.DimensionOfRevenue,
	|	LastAdjustmentData.Series,
	|	LastAdjustmentData.Warehouse,
	|	LastAdjustmentData.Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LastAdjustmentData.Products AS Products,
	|	LastAdjustmentData.CCDNumber AS CCDNumber,
	|	LastAdjustmentData.Characteristic AS Characteristic,
	|	LastAdjustmentData.Content AS Content,
	|	LastAdjustmentData.Package AS Package,
	|	LastAdjustmentData.ProductsInSet AS ProductsInSet,
	|	LastAdjustmentData.ItemVariantOfSet AS ItemVariantOfSet,
	|	LastAdjustmentData.IncomeItem AS IncomeItem,
	|	LastAdjustmentData.DimensionOfRevenue AS DimensionOfRevenue,
	|	LastAdjustmentData.Series AS Series,
	|	LastAdjustmentData.Warehouse AS Warehouse,
	|	LastAdjustmentData.Department AS Department,
	|	SUM(LastAdjustmentData.Count) AS Count,
	|	SUM(LastAdjustmentData.NumberOfPackages) AS NumberOfPackages,
	|	SUM(LastAdjustmentData.Sum) AS Sum,
	|	SUM(LastAdjustmentData.VATAmount) AS VATAmount,
	|	SUM(LastAdjustmentData.AmountIncludingVAT) AS AmountIncludingVAT,
	|	LastAdjustmentData.VATRate AS VATRate
	|INTO InitialDataOnCCD
	|FROM
	|	RawData AS LastAdjustmentData
	|WHERE
	|	&ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES
	|	AND LastAdjustmentData.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|
	|GROUP BY
	|	LastAdjustmentData.Products,
	|	LastAdjustmentData.CCDNumber,
	|	LastAdjustmentData.Characteristic,
	|	LastAdjustmentData.Content,
	|	LastAdjustmentData.Package,
	|	LastAdjustmentData.ProductsInSet,
	|	LastAdjustmentData.ItemVariantOfSet,
	|	LastAdjustmentData.IncomeItem,
	|	LastAdjustmentData.DimensionOfRevenue,
	|	LastAdjustmentData.Series,
	|	LastAdjustmentData.Warehouse,
	|	LastAdjustmentData.Department,
	|	LastAdjustmentData.VATRate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDiscrepancies.LineNumber AS LineNumber,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.Count IS NULL
	|			THEN 0
	|		ELSE TTDiscrepancies.Count - ISNULL(LastAdjustmentData.Count, 0)
	|	END AS Count,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.NumberOfPackages IS NULL
	|			THEN 0
	|		ELSE TTDiscrepancies.NumberOfPackages - ISNULL(LastAdjustmentData.NumberOfPackages, 0)
	|	END AS NumberOfPackages,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.Sum IS NULL
	|			THEN 0
	|		ELSE TTDiscrepancies.Sum - ISNULL(LastAdjustmentData.Sum, 0)
	|	END AS Sum,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.VATAmount IS NULL
	|			THEN 0
	|		ELSE TTDiscrepancies.VATAmount - ISNULL(LastAdjustmentData.VATAmount, 0)
	|	END AS VATAmount,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.AmountIncludingVAT IS NULL
	|			THEN 0
	|		ELSE TTDiscrepancies.AmountIncludingVAT - ISNULL(LastAdjustmentData.AmountIncludingVAT, 0)
	|	END AS AmountIncludingVAT,
	|	CASE
	|		WHEN LastAdjustmentData.VATRate IS NULL
	|			THEN FALSE
	|		WHEN TTDiscrepancies.VATRate <> LastAdjustmentData.VATRate
	|				AND TTDiscrepancies.Count > 0
	|				AND TTDiscrepancies.NumberOfPackages > 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereIsVATError,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.Count IS NULL
	|			THEN TTDiscrepancies.Count
	|		ELSE ISNULL(LastAdjustmentData.Count, 0)
	|	END AS InitialQuantity_,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.NumberOfPackages IS NULL
	|			THEN TTDiscrepancies.NumberOfPackages
	|		ELSE ISNULL(LastAdjustmentData.NumberOfPackages, 0)
	|	END AS InitialNumberOfPackages,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.Sum IS NULL
	|			THEN TTDiscrepancies.Sum
	|		ELSE ISNULL(LastAdjustmentData.Sum, 0)
	|	END AS InitialAmount_,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.VATAmount IS NULL
	|			THEN TTDiscrepancies.VATAmount
	|		ELSE ISNULL(LastAdjustmentData.VATAmount, 0)
	|	END AS InitialAmountOfVAT,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.AmountIncludingVAT IS NULL
	|			THEN TTDiscrepancies.AmountIncludingVAT
	|		ELSE ISNULL(LastAdjustmentData.AmountIncludingVAT, 0)
	|	END AS InitialAmountWithVAT,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.VATRate IS NULL
	|			THEN TTDiscrepancies.VATRate
	|		ELSE ISNULL(LastAdjustmentData.VATRate, 0)
	|	END AS InitialVATRate
	|INTO TTToCheckDataForLastAdjustment
	|FROM
	|	TTGoodsTableTotal AS TTDiscrepancies
	|		LEFT JOIN Catalog.Products AS ProductData_8
	|		ON TTDiscrepancies.Products = ProductData_8.Ref
	|		LEFT JOIN InitialDataWithoutCCD AS LastAdjustmentData
	|		ON (CASE
	|				WHEN &ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES
	|					THEN LastAdjustmentData.Products = TTDiscrepancies.Products
	|							AND LastAdjustmentData.Characteristic = TTDiscrepancies.Characteristic
	|							AND LastAdjustmentData.Content = TTDiscrepancies.Content
	|							AND LastAdjustmentData.Package = TTDiscrepancies.Package
	|							AND LastAdjustmentData.ProductsInSet = TTDiscrepancies.ProductsInSet
	|							AND LastAdjustmentData.ItemVariantOfSet = TTDiscrepancies.ItemVariantOfSet
	|							AND LastAdjustmentData.IncomeItem = TTDiscrepancies.IncomeItem
	|							AND LastAdjustmentData.DimensionOfRevenue = TTDiscrepancies.DimensionOfRevenue
	|							AND LastAdjustmentData.Series = TTDiscrepancies.Series
	|							AND LastAdjustmentData.Warehouse = TTDiscrepancies.Warehouse
	|							AND LastAdjustmentData.Department = TTDiscrepancies.Department
	|				ELSE LastAdjustmentData.Content = TTDiscrepancies.Content
	|						AND LastAdjustmentData.Department = TTDiscrepancies.Department
	|						AND LastAdjustmentData.IncomeItem = TTDiscrepancies.IncomeItem
	|						AND LastAdjustmentData.DimensionOfRevenue = TTDiscrepancies.DimensionOfRevenue
	|			END)
	|		LEFT JOIN DataFromLastCorrectiveAdjustment AS DataFromLastCorrectiveAdjustment
	|		ON (TRUE)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDiscrepancies.LineNumber,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.Count IS NULL
	|			THEN 0
	|		ELSE TTDiscrepancies.Count - ISNULL(LastAdjustmentData.Count, 0)
	|	END,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.NumberOfPackages IS NULL
	|			THEN 0
	|		ELSE TTDiscrepancies.NumberOfPackages - ISNULL(LastAdjustmentData.NumberOfPackages, 0)
	|	END,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.Sum IS NULL
	|			THEN 0
	|		ELSE TTDiscrepancies.Sum - ISNULL(LastAdjustmentData.Sum, 0)
	|	END,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.VATAmount IS NULL
	|			THEN 0
	|		ELSE TTDiscrepancies.VATAmount - ISNULL(LastAdjustmentData.VATAmount, 0)
	|	END,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.AmountIncludingVAT IS NULL
	|			THEN 0
	|		ELSE TTDiscrepancies.AmountIncludingVAT - ISNULL(LastAdjustmentData.AmountIncludingVAT, 0)
	|	END,
	|	CASE
	|		WHEN LastAdjustmentData.VATRate IS NULL
	|			THEN FALSE
	|		WHEN TTDiscrepancies.VATRate <> LastAdjustmentData.VATRate
	|				AND TTDiscrepancies.Count > 0
	|				AND TTDiscrepancies.NumberOfPackages > 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.Count IS NULL
	|			THEN TTDiscrepancies.Count
	|		ELSE ISNULL(LastAdjustmentData.Count, 0)
	|	END,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.NumberOfPackages IS NULL
	|			THEN TTDiscrepancies.NumberOfPackages
	|		ELSE ISNULL(LastAdjustmentData.NumberOfPackages, 0)
	|	END,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.Sum IS NULL
	|			THEN TTDiscrepancies.Sum
	|		ELSE ISNULL(LastAdjustmentData.Sum, 0)
	|	END,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.VATAmount IS NULL
	|			THEN TTDiscrepancies.VATAmount
	|		ELSE ISNULL(LastAdjustmentData.VATAmount, 0)
	|	END,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.AmountIncludingVAT IS NULL
	|			THEN TTDiscrepancies.AmountIncludingVAT
	|		ELSE ISNULL(LastAdjustmentData.AmountIncludingVAT, 0)
	|	END,
	|	CASE
	|		WHEN DataFromLastCorrectiveAdjustment.Ref IS NULL
	|				AND LastAdjustmentData.VATRate IS NULL
	|			THEN TTDiscrepancies.VATRate
	|		ELSE ISNULL(LastAdjustmentData.VATRate, 0)
	|	END
	|FROM
	|	TableOfProductsToRequest AS TTDiscrepancies
	|		LEFT JOIN Catalog.Products AS ProductData_8
	|		ON TTDiscrepancies.Products = ProductData_8.Ref
	|		LEFT JOIN InitialDataOnCCD AS LastAdjustmentData
	|		ON (LastAdjustmentData.Products = TTDiscrepancies.Products)
	|			AND (LastAdjustmentData.Characteristic = TTDiscrepancies.Characteristic)
	|			AND (LastAdjustmentData.Content = TTDiscrepancies.Content)
	|			AND (LastAdjustmentData.Package = TTDiscrepancies.Package)
	|			AND (LastAdjustmentData.ProductsInSet = TTDiscrepancies.ProductsInSet)
	|			AND (LastAdjustmentData.ItemVariantOfSet = TTDiscrepancies.ItemVariantOfSet)
	|			AND (LastAdjustmentData.IncomeItem = TTDiscrepancies.IncomeItem)
	|			AND (LastAdjustmentData.DimensionOfRevenue = TTDiscrepancies.DimensionOfRevenue)
	|			AND (LastAdjustmentData.Series = TTDiscrepancies.Series)
	|			AND (LastAdjustmentData.Warehouse = TTDiscrepancies.Warehouse)
	|			AND (LastAdjustmentData.CCDNumber = TTDiscrepancies.CCDNumber)
	|			AND (LastAdjustmentData.Department = TTDiscrepancies.Department)
	|		LEFT JOIN DataFromLastCorrectiveAdjustment AS DataFromLastCorrectiveAdjustment
	|		ON (TRUE)
	|WHERE
	|	&ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES
	|	AND TTDiscrepancies.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)";
	
	Return QueryText;
	
EndFunction

Function QueryTextCheckingFillingOfWarehouse()
	
	QueryText =
	"SELECT TOP 1
	|	0					AS LineNumber,
	|	""NotSpecifiedWarehouse""	AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|WHERE
	|	&UseSeveralWarehouses
	|	AND &Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|	AND ISNULL(ProductData_1.ItemsType, UNDEFINED) IN
	|			(VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))";
	
	Return QueryText;
	
EndFunction

Function QueryTextChecksForFillingInProductListAndContent()
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	""NotProductRANGEIsSpecified""	AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|WHERE
	|	&ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES
	|	AND TableOfGoods.Products = VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	""NotContentIsSpecified""		AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|WHERE
	|	TableOfGoods.Content = """"
	|	AND &ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES
	|	AND TableOfGoods.Products <> VALUE(Catalog.Products.EmptyRef)
	|	AND ISNULL(ProductData_1.ItemsType, UNDEFINED) IN
	|			(VALUE(Enum.ItemsTypes.Work_5),
	|			VALUE(Enum.ItemsTypes.OperationService))
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	""NotContentIsSpecified""		AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|WHERE
	|	TableOfGoods.Content = """"
	|	AND NOT &ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES";
	
	Return QueryText;
	
EndFunction

Function QueryTextChecksForFillingInCharacteristics()
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	""NotCharacteristicIsSpecified""	AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|WHERE
	|	&UseItemVariants
	|	AND ISNULL(ProductData_1.UseVariants, UNDEFINED) IN
	|			(VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|			VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|			VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|	AND TableOfGoods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)";
	
	Return QueryText;
	
EndFunction

Function QueryTextCheckingFillingInOfCCDNumbers()
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	""NotCCDNumberIsSpecified""		AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|WHERE
	|	&ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES
	|	AND ISNULL(ProductData_1.KeepRecordsByCCD, FALSE)
	|	AND ISNULL(ProductData_1.ItemsType, UNDEFINED) IN
	|			(VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage),
	|			VALUE(Enum.ItemsTypes.Work_5))
	|	AND ((&RestrictGoodsReceiptWithoutCCDNumbers
	|			AND NOT ISNULL(ProductData_1.TracedGoods, FALSE))
	|		OR (&UseTraceableImportedGoodsAccounting
	|			AND ISNULL(ProductData_1.TracedGoods, FALSE)))
	|	AND TableOfGoods.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|	AND NOT ((TableOfGoods.Count - TableOfGoods.QuantityAfter < 0
	|		OR TableOfGoods.NumberOfPackages - TableOfGoods.NumberOfPackagesAfter < 0)
	|		AND (TableOfGoods.VATRate = TableOfGoods.VATRateAfter
	|		OR TableOfGoods.NumberOfPackages = 0 
	|		OR TableOfGoods.Count = 0))
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	""NotCCDNumberIsSpecified""		AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|WHERE
	|	&ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES
	|	AND ISNULL(ProductData_1.KeepRecordsByCCD, FALSE)
	|	AND ISNULL(ProductData_1.ItemsType, UNDEFINED) IN
	|			(VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage),
	|			VALUE(Enum.ItemsTypes.Work_5))
	|	AND ((&RestrictGoodsReceiptWithoutCCDNumbers
	|			AND NOT ISNULL(ProductData_1.TracedGoods, FALSE))
	|		OR (&UseTraceableImportedGoodsAccounting
	|			AND ISNULL(ProductData_1.TracedGoods, FALSE)))
	|	AND TableOfGoods.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|	AND TableOfGoods.PostingOption = VALUE(Enum.CreditNoteRecordingOptions.RecordInOtherIncome)
	|	AND ((TableOfGoods.Count - TableOfGoods.QuantityAfter < 0
	|		OR TableOfGoods.NumberOfPackages - TableOfGoods.NumberOfPackagesAfter < 0)
	|		AND (TableOfGoods.VATRate = TableOfGoods.VATRateAfter
	|		OR TableOfGoods.NumberOfPackages = 0 
	|		OR TableOfGoods.Count = 0))";
	
	Return QueryText;
	
EndFunction

Function QueryTextCheckingFillingOfQuantity()
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	CASE
	|		WHEN TableOfGoods.Count = 0
	|				AND TableOfGoods.NumberOfPackages <> 0
	|			THEN ""QuantityRecalculationError""
	|		ELSE ""NotNumberOfPackagesIsIndicated""
	|	END						AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|WHERE
	|	&ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES
	|	AND ((TableOfGoods.Count = 0
	|		AND TableOfGoods.NumberOfPackages <> 0)
	|	OR (NOT (TableOfGoods.QuantityAfter = 0
	|			AND TableOfGoods.NumberOfPackagesAfter <> 0)
	|		AND ((TableOfGoods.Count = 0
	|				AND TableOfGoods.QuantityAfter = 0)
	|			OR (TableOfGoods.NumberOfPackages = 0
	|				AND TableOfGoods.NumberOfPackagesAfter = 0))
	|		OR (TableOfGoods.NumberOfPackages = 0
	|			AND TableOfGoods.Price > 0)))
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	CASE
	|		WHEN TableOfGoods.QuantityAfter = 0
	|				AND TableOfGoods.NumberOfPackagesAfter <> 0
	|			THEN ""ErrorInRecalculatingQuantityAfter""
	|		ELSE ""NotNumberOfPackagesAfter""
	|	END						AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|WHERE
	|	&ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES
	|	AND ((TableOfGoods.QuantityAfter = 0
	|		AND TableOfGoods.NumberOfPackagesAfter <> 0)
	|	OR (NOT (TableOfGoods.Count = 0
	|			AND TableOfGoods.NumberOfPackages <> 0)
	|		AND ((TableOfGoods.Count = 0
	|				AND TableOfGoods.QuantityAfter = 0)
	|			OR (TableOfGoods.NumberOfPackages = 0
	|				AND TableOfGoods.NumberOfPackagesAfter = 0))
	|		OR (TableOfGoods.NumberOfPackagesAfter = 0
	|			AND TableOfGoods.PriceAfter > 0)))
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber		AS LineNumber,
	|	""NotQuantityIsIndicatedAccordingToRNPT""	AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|WHERE
	|	TableOfGoods.QuantityByGBRN = 0
	|	AND (TableOfGoods.Price > 0
	|		OR TableOfGoods.Count <> 0
	|		OR TableOfGoods.NumberOfPackages <> 0)
	|	AND &ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND ISNULL(ProductData_1.KeepRecordsByCCD, FALSE)
	|	AND ISNULL(ProductData_1.TracedGoods, FALSE)
	|	AND ISNULL(ProductData_1.ItemsType, UNDEFINED) IN
	|			(VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage),
	|			VALUE(Enum.ItemsTypes.Work_5))
	|	AND (NOT (TableOfGoods.Count - TableOfGoods.QuantityAfter < 0
	|		OR TableOfGoods.NumberOfPackages - TableOfGoods.NumberOfPackagesAfter < 0)
	|		OR TableOfGoods.PostingOption = VALUE(Enum.CreditNoteRecordingOptions.RecordInOtherIncome))
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber			AS LineNumber,
	|	""NotQuantityIndicatedByRNPTAfter""	AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|WHERE
	|	TableOfGoods.QuantityAccordingToRNPTAfter = 0
	|	AND (TableOfGoods.PriceAfter > 0
	|		OR TableOfGoods.QuantityAfter <> 0
	|		OR TableOfGoods.NumberOfPackagesAfter <> 0)
	|	AND &ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND ISNULL(ProductData_1.KeepRecordsByCCD, FALSE)
	|	AND ISNULL(ProductData_1.TracedGoods, FALSE)
	|	AND ISNULL(ProductData_1.ItemsType, UNDEFINED) IN
	|			(VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage),
	|			VALUE(Enum.ItemsTypes.Work_5))
	|	AND (NOT (TableOfGoods.Count - TableOfGoods.QuantityAfter < 0
	|		OR TableOfGoods.NumberOfPackages - TableOfGoods.NumberOfPackagesAfter < 0)
	|		OR TableOfGoods.PostingOption = VALUE(Enum.CreditNoteRecordingOptions.RecordInOtherIncome))
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber			AS LineNumber,
	|	""AmountOfCCDWithIncrease""	AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|WHERE
	|	&ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES
	|	AND ISNULL(ProductData_1.KeepRecordsByCCD, FALSE)
	|	AND TableOfGoods.NumberOfPackages > 0
	|	AND TableOfGoods.PostingOption <> VALUE(Enum.CreditNoteRecordingOptions.RecordInOtherIncome)
	|	AND TableOfGoods.NumberOfPackages < TableOfGoods.NumberOfPackagesAfter
	|	AND TableOfGoods.VATRate = TableOfGoods.VATRateAfter
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextChecksForFillingInSummaryIndicators()
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	""NotPriceShownIsUpTo""			AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|WHERE
	|	(TableOfGoods.Price = 0 AND TableOfGoods.Count > 0)
	|	OR (TableOfGoods.Price = 0 AND TableOfGoods.PriceAfter = 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	""NotPriceIsIndicatedAfter""			AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|WHERE
	|	(TableOfGoods.PriceAfter = 0 AND TableOfGoods.QuantityAfter > 0)
	|	OR (TableOfGoods.Price = 0 AND TableOfGoods.PriceAfter = 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	""NotSpecifiedAmountIsUpTo""			AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|WHERE
	|	(TableOfGoods.Sum = 0 AND TableOfGoods.Count > 0)
	|	OR (TableOfGoods.Sum = 0 AND TableOfGoods.AmountAfter = 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	""NotAmountSpecifiedAfter""			AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|WHERE
	|	(TableOfGoods.AmountAfter = 0 AND TableOfGoods.QuantityAfter > 0)
	|	OR (TableOfGoods.Sum = 0 AND TableOfGoods.AmountAfter = 0)";
	
	Return QueryText;
	
EndFunction

Function QueryTextChecksForFillingInVATRates()
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	""NotVATRateIsIndicated""		AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|WHERE
	|	&UseVATAccounting
	|	AND TableOfGoods.VATRate = VALUE(Catalog.VATRates.EmptyRef)
	|	AND ((TableOfGoods.Count > 0 AND &ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES)
	|		OR (TableOfGoods.Sum > 0 AND NOT &ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES))
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	""NotVATRateIsIndicatedAfter""	AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|WHERE
	|	&UseVATAccounting
	|	AND TableOfGoods.VATRateAfter = VALUE(Catalog.VATRates.EmptyRef)
	|	AND ((TableOfGoods.QuantityAfter > 0 AND &ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES)
	|		OR (TableOfGoods.AmountAfter > 0 AND NOT &ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES))";
	
	Return QueryText;
	
EndFunction

Function QueryTextCheckingReflectionOptions()
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber				AS LineNumber,
	|	""NotOptionForReflectingWriteOffIsSpecified""	AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|WHERE
	|	TableOfGoods.VATRate <> TableOfGoods.VATRateAfter
	|	AND TableOfGoods.VATRate <> VALUE(Catalog.VATRates.EmptyRef)
	|	AND TableOfGoods.VATRateAfter <> VALUE(Catalog.VATRates.EmptyRef)
	|	AND TableOfGoods.OptionToReflectWriteOff = VALUE(Enum.CreditNoteRecordingOptions.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	""NotVariantOfReflectionOfDiscrepancyIsIndicated""	AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|WHERE
	|	(TableOfGoods.VATAmount <> TableOfGoods.VATAmountAfter
	|		OR TableOfGoods.AmountIncludingVAT <> TableOfGoods.AmountWithVATAfter
	|		OR TableOfGoods.Count <> TableOfGoods.QuantityAfter)
	|	AND TableOfGoods.PostingOption = VALUE(Enum.CreditNoteRecordingOptions.EmptyRef)";
	
	Return QueryText;
	
EndFunction

Function QueryTextCheckingFillingOfWarehouseInTabularPart()
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber			AS LineNumber,
	|	""NotWarehouseIsListedInTablePart""	AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|WHERE
	|	&UseSeveralWarehouses
	|	AND CAST(&Warehouse AS Catalog.Warehouses).IsFolder
	|	AND &Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|	AND TableOfGoods.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|	AND ISNULL(ProductData_1.ItemsType, UNDEFINED) IN
	|			(VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))";
	
	Return QueryText;
	
EndFunction

Function QueryTextCheckingFillingOfDivisionInTabularPart()
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	""NotDivisionIsIndicatedInTabularPart""	AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|WHERE
	|	&UseBusinessUnits
	|	AND TableOfGoods.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|	AND ISNULL(ProductData_1.ItemsType, UNDEFINED) = VALUE(Enum.ItemsTypes.Work_5)";
	
	Return QueryText;
	
EndFunction

Function QueryTextVerificationOfMethodsForDeterminingCost()
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	""NotMethodOfDeterminingCostIsSpecified""	AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|WHERE
	|	((TableOfGoods.VATRate = TableOfGoods.VATRateAfter
	|			AND TableOfGoods.Count > TableOfGoods.QuantityAfter
	|			AND TableOfGoods.PostingOption <> VALUE(Enum.CreditNoteRecordingOptions.ToExpenseAs))
	|		OR (TableOfGoods.Count > 0
	|			AND TableOfGoods.VATRate <> TableOfGoods.VATRateAfter)
	|			AND TableOfGoods.OptionToReflectWriteOff <> VALUE(Enum.CreditNoteRecordingOptions.ToExpenseAs))
	|	AND ISNULL(ProductData_1.ItemsType, UNDEFINED) IN
	|			(VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage),
	|			VALUE(Enum.ItemsTypes.Work_5))
	|	AND TableOfGoods.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.EmptyRef)";
	
	Return QueryText;
	
EndFunction

Function QueryTextChecksVATTaxationCorrespondsToBasis()
	
	QueryText =
	"SELECT
	|	0 AS LineNumber,
	|	""VATTaxationDoesNotCorrespondToBasis"" AS TypeOfVerification
	|FROM
	|	FoundationDocumentData AS DocumentBasis
	|WHERE DocumentBasis.VATTaxation <> &VATTaxation";
	
	Return QueryText;
	
EndFunction

Function QueryTextChecksOrganizationCorrespondsToFoundation()
	
	QueryText =
	"SELECT
	|	0 AS LineNumber,
	|	""OrganizationDoesNotMatchFoundation"" AS TypeOfVerification
	|FROM
	|	FoundationDocumentData AS DocumentBasis
	|WHERE DocumentBasis.Organization <> &Organization";
	
	Return QueryText;
	
EndFunction

Function QueryTextVerificationContractCorrespondsToBasis()
	
	QueryText =
	"SELECT
	|	0 AS LineNumber,
	|	""ContractDoesNotCorrespondToBasis"" AS TypeOfVerification
	|FROM
	|	FoundationDocumentData AS DocumentBasis
	|WHERE DocumentBasis.Contract <> &Contract";
	
	Return QueryText;
	
EndFunction

Function QueryTextPartnerChecksMatchFoundation()
	
	QueryText =
	"SELECT
	|	0 AS LineNumber,
	|	""PartnerDoesNotMatchFoundation"" AS TypeOfVerification
	|FROM
	|	FoundationDocumentData AS DocumentBasis
	|WHERE DocumentBasis.Partner <> &Partner";
	
	Return QueryText;
	
EndFunction

Function QueryTextChecksCounterpartyCorrespondsToBasis()
	
	QueryText =
	"SELECT
	|	0 AS LineNumber,
	|	""CounterpartyDoesNotMatchBasis"" AS TypeOfVerification
	|FROM
	|	FoundationDocumentData AS DocumentBasis
	|WHERE DocumentBasis.Counterparty <> &Counterparty";
	
	Return QueryText;
	
EndFunction

Function QueryTextChecksOrderOfCalculationsCorrespondsToBase()
	
	QueryText =
	"SELECT
	|	0 AS LineNumber,
	|	""OrderOfCalculationsDoesNotCorrespondToBase"" AS TypeOfVerification
	|FROM
	|	FoundationDocumentData AS DocumentBasis
	|WHERE DocumentBasis.ARAPObjectSettings <> &ARAPObjectSettings";
	
	Return QueryText;
	
EndFunction

Function QueryTextChecksTypeOfAdjustmentDoesNotMatchPreviousOne()
	
	QueryText =
	"SELECT
	|	0 AS LineNumber,
	|	""TypeOfAdjustmentDoesNotMatchPreviousOne"" AS TypeOfVerification
	|FROM
	|	TTPreviousAdjustment AS PreviousAdjustment
	|WHERE PreviousAdjustment.AdjustingEntryType <> &AdjustingEntryType
	|
	|UNION ALL
	|
	|SELECT
	|	0 AS LineNumber,
	|	""PriceIncludesVATDoesNotCorrespondToPreviousOne"" AS TypeOfVerification
	|FROM
	|	TTPreviousAdjustment AS PreviousAdjustment
	|WHERE PreviousAdjustment.PriceIncludesVAT <> &PriceIncludesVAT
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextCheckingDataOnLastAdjustment()
	
QueryText = "SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	""ErrorQuantityByInitialAdjustment"" AS TypeOfVerification,
	|	TableOfGoods.InitialQuantity_ AS SourceValue
	|FROM
	|	TTToCheckDataForLastAdjustment AS TableOfGoods
	|WHERE
	|	TableOfGoods.Count <> 0
	|	AND TableOfGoods.NumberOfPackages = 0
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber,
	|	""ErrorNumberOfPackagesByInitialCorrection"",
	|	TableOfGoods.InitialNumberOfPackages
	|FROM
	|	TTToCheckDataForLastAdjustment AS TableOfGoods
	|WHERE
	|	TableOfGoods.NumberOfPackages <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber,
	|	""AmountErrorBasedOnInitialAdjustment"",
	|	TableOfGoods.InitialAmount_
	|FROM
	|	TTToCheckDataForLastAdjustment AS TableOfGoods
	|WHERE
	|	TableOfGoods.Sum <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber,
	|	""ErrorInVATAmountBasedOnInitialAdjustment"",
	|	TableOfGoods.InitialAmountOfVAT
	|FROM
	|	TTToCheckDataForLastAdjustment AS TableOfGoods
	|WHERE
	|	TableOfGoods.VATAmount <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber,
	|	""ErrorInAmountWithVATForInitialAdjustment"",
	|	TableOfGoods.InitialAmountWithVAT
	|FROM
	|	TTToCheckDataForLastAdjustment AS TableOfGoods
	|WHERE
	|	TableOfGoods.AmountIncludingVAT <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber,
	|	""VATRateError"",
	|	TableOfGoods.InitialVATRate
	|FROM
	|	TTToCheckDataForLastAdjustment AS TableOfGoods
	|WHERE
	|	TableOfGoods.ThereIsVATError ";

	Return QueryText;
	
EndFunction

Function TextOfRequestForVerificationOfFillingInAmountOfMutualSettlements()
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	""AmountOfMutualSettlementsIsNotSpecified""			AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|WHERE 
	|	&DifferentCurrencies
	|	AND TableOfGoods.AmountARAP = 0
	|	AND TableOfGoods.AmountOfSettlementsAfter <> 0
	|	AND TableOfGoods.Sum > 0
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	""AmountOfSettlementsAfterIsNotSpecified""			AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|WHERE 
	|	&DifferentCurrencies
	|	AND TableOfGoods.AmountOfSettlementsAfter = 0
	|	AND TableOfGoods.AmountARAP <> 0
	|	AND TableOfGoods.AmountAfter > 0";
	
	Return QueryText;
	
EndFunction

Procedure Report_FillingErrors(Selection, Cancel)
	
	TSName			= "AdjustmentTable";
	PresentationOfTS	= NStr("vi = 'Dữ liệu điều chỉnh';
								|ru = 'Данные корректировки';
								|en = 'Correction data'; fa = 'داده‌های اصلاح';
								|it = 'Dati di correzione';
								|pl = 'Dane korekty';
								|tr = 'Düzeltme verileri'");
	
	MessageTemplateFieldNotFilledIn							= NStr("vi = 'Chưa điền trường ""%1""';
																		|ru = 'Поле ""%1"" не заполнено';
																		|en = '""%1"" is required'; fa = '""%1"" is required';
																		|it = 'Il campo ""%1"" non è compilato';
																		|pl = 'Pole ""%1"" nie jest wypełnione';
																		|tr = '""%1"" alanı doldurulmamış'");
	MessageTemplateColumnNotFilledIn						= NStr("vi = 'Chưa điền cột ""%1"" tại dòng %2 trong danh sách ""%3""';
																	|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3""';
																	|en = 'Column ""%1"" in line #%2, list ""%3"" cannot be empty.'; fa = 'Column ""%1"" in line #%2, list ""%3"" cannot be empty.';
																	|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""%3"" non è compilata';
																	|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""%3""';
																	|tr = 'Sütun ""%1"", ""%3"" listesinin %2 satırında doldurulmamış'");
	MessageTemplateQuantityRecalculationError				= NStr("vi = 'Đã tìm thấy giá trị bằng 0 %1 khi tính lại theo đơn vị lưu kho tại dòng %2 danh sách ""%3""';
																	|ru = 'Обнаружено нулевое %1 при пересчете в единицу хранения в строке %2 списка ""%3""';
																	|en = 'Zero %1 is detected when converting to stock UOM in line %2 of the %3 list'; fa = 'Zero %1 is detected when converting to stock UOM in line %2 of the %3 list';
																	|it = 'È stato rilevato un %1 nullo durante il ricalcolo nell''unità di stoccaggio nella stringa %2 dell''elenco ""%3""';
																	|pl = 'Ujawniona jest zerowa %1 podczas przeliczenia do jednostki przechowywania w wierszu %2 listy ""%3""';
																	|tr = '""%3"" listesinin %2 satırındaki depolama birimine yeniden hesaplama yapılırken %1 sıfır algılandı'");
	MessageTemplateNotSpecifiedOptionForDebitingReflection		= NStr("vi = 'Chưa chỉ ra phương án ghi giảm các mặt hàng đã tiếp nhận tại dòng %1 danh sách ""%2""';
																		|ru = 'Не указан вариант списания принятых позиций в строке %1 списка ""%2""';
																		|en = 'Received item write-off option is not specified in line %1 of the %2 list'; fa = 'Received item write-off option is not specified in line %1 of the %2 list';
																		|it = 'Non è indicata la variante di storno delle posizioni accettate nella stringa %1 dell''elenco ""%2""';
																		|pl = 'Nie podano wariantu rozchodu przyjętych pozycji w wierszu %1 listy ""%2""';
																		|tr = '""%2"" listesinin %1 satırında kabul edilen kalemlerin silinmesi için bir seçenek belirtilmemiştir'");
	MessageTemplateNotSpecifiedOptionToReflectDiscrepancy		= NStr("vi = 'Chưa chỉ ra phương án phản ánh chênh lệch theo dòng %1 danh sách ""%2""';
																		|ru = 'Не указан вариант отражения расхождений по строке %1 списка ""%2""';
																		|en = 'Discrepancy recording option is not specified for line %1 of the %2 list'; fa = 'Discrepancy recording option is not specified for line %1 of the %2 list';
																		|it = 'Non è indicata la variante di riflessione delle discrepanze in base alla stringa %1 dell''elenco ""%2""';
																		|pl = 'Nie podano wariantu odzwierciedlenia odchylenia wg wiersza %1 listy ""%2""';
																		|tr = '""%2"" listesinin %1 satırındaki tutarsızlıkları bildirmek için bir seçenek belirtilmemiştir'");
	MessageTemplateDoesNotSpecifyMethodForDeterminingCost	= NStr("vi = 'Chưa chỉ ra phương thức xác định giá vốn theo dòng %1 danh sách ""%2""';
																	|ru = 'Не указан способ определения себестоимости по строке %1 списка ""%2""';
																	|en = 'Cost defining method is not specified for line %1 of the %2 list'; fa = 'Cost defining method is not specified for line %1 of the %2 list';
																	|it = 'Non è indicato il metodo di definizione del prezzo di costo in base alla stringa %1 dell''elenco ""%2""';
																	|pl = 'Nie podano sposobu określenia kosztu własnego wg wiersza %1 listy ""%2""';
																	|tr = '""%2"" listesinin %1 satırında üretim maliyetlerini belirlemek için bir yöntem belirtilmemiştir'");
	MessageTemplateDoesNotMatchBase					= NStr("vi = 'Trường ""%1"" không tương ứng với trường tương tự của chứng từ cơ sở';
																|ru = 'Поле ""%1"" не соответствует аналогичному полю документа основания';
																|en = 'The %1 field does not match the respective base document field'; fa = 'The %1 field does not match the respective base document field';
																|it = 'Il campo ""%1"" non corrisponde al campo analogo del documento di base';
																|pl = 'Pole ""%1"" nie jest zgodne z analogicznym polem dokumentu źródłowego';
																|tr = '""%1"" alanı temel belgedeki aynı alana karşılık gelmiyor'");
	MessageTemplateDoesNotMatchPreviousCorrection	= NStr("vi = 'Trường ""%1"" không tương ứng với trường tương tự của lần điều chỉnh trước';
															|ru = 'Поле ""%1"" не соответствует аналогичному полю предыдущей корректировки';
															|en = 'The %1 field does not match the respective field of the previous adjustment'; fa = 'The %1 field does not match the respective field of the previous adjustment';
															|it = 'Il campo ""%1"" non corrisponde al campo analogo della correzione precedente';
															|pl = 'Pole ""%1"" nie jest zgodne z analogicznym polem poprzedniej korekty';
															|tr = '""%1"" alanı önceki düzeltmedeki aynı alana karşılık gelmiyor'");
	MessageTemplateRewardAmountColumnIsNotFilledIn	= NStr("vi = 'Chưa điền cột ""%1"" trong dòng %2 của danh sách ""%3"". %4';
															|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3"". %4';
															|en = 'Column %1 in line %2 of the %3 list is not filled. %4'; fa = 'Column %1 in line %2 of the %3 list is not filled. %4';
															|it = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3"". %4';
															|pl = 'Column %1 in line %2 of the %3 list is not filled. %4';
															|tr = '""%3"" listesinin %2 satırındaki ""%1"" sütunu doldurulmadı. %4'");
	MessageTemplateNumberOfCCDIncreases                  = NStr("vi = 'Đối với hàng hóa có %1, cần chỉ ra dữ liệu %1 của hàng hóa đã bán bằng cách thêm dòng có dữ liệu trước và sau khi điều chỉnh.
			|Nếu chưa thay đổi chúng thì dữ liệu trước và sau khi điều chỉnh phải trùng nhau.
			|Về số lượng cần tăng, cần chỉ ra số lượng ban đầu là 0 trong dòng %2 của danh sách ""%3"", còn số lượng sau điều chỉnh là số lượng đã bán.';
			|ru = 'Для товаров с %1 необходимо указать данные %1 уже реализованных товаров, добавив строки с данными до и после корректировки.
			|Если они не менялись, то данные до корректировки и после должны совпадать.
			|По количеству на увеличение необходимо в строке %2 списка ""%3"" указать исходное количество 0, а количество после - количество, на которое увеличена реализация.';
			|en = 'For items with %1, specify the %1 data of already sold items by adding rows with data before and after the adjustment.
			|If it did not change, the data before and after the adjustment must be the same.
			|Set the initial quantity to 0 in line %2 of the %3 list, and the new quantity to the amount the invoice is increased to.'; fa = 'For items with %1, specify the %1 data of already sold items by adding rows with data before and after the adjustment.
			|If it did not change, the data before and after the adjustment must be the same.
			|Set the initial quantity to 0 in line %2 of the %3 list, and the new quantity to the amount the invoice is increased to.';
			|it = 'Для товаров с %1 необходимо указать данные %1 уже реализованных товаров, добавив строки с данными до и после корректировки.
			|Если они не менялись, то данные до корректировки и после должны совпадать.
			|По количеству на увеличение необходимо в строке %2 списка ""%3"" указать исходное количество 0, а количество после - количество, на которое увеличена реализация.';
			|pl = 'For items with %1, specify the %1 data of already sold items by adding rows with data before and after the adjustment.
			|If it did not change, the data before and after the adjustment must be the same.
			|Set the initial quantity to 0 in line %2 of the %3 list, and the new quantity to the amount the invoice is increased to.';
			|tr = '%1 olan ürünler için halihazırda satılan ürünlerin %1 verilerini, düzeltme öncesi ve sonrası verileri içeren satırlar ekleyerek belirtmeniz gerekmektedir.
			|Değişmediler ise düzeltmeden önceki ve sonraki veriler eşleşmelidir.
			|Artış miktarına göre, ""%3"" listesinin %2 satırında başlangıçtaki 0 miktarını ve sonraki; satışın artırıldığı miktarı belirtmeniz gerekmektedir.'");
		
	TextOfGTDRNPT = NStr("vi = 'Tờ khai hải quan';
						|ru = 'ГТД';
						|en = 'CCD'; fa = 'اظهارنامه گمرکی (CCD)';
						|it = 'ГТД';
						|pl = 'CCD';
						|tr = 'GKB'");

	MessageTemplateNumberOfCCDIncreases = StrTemplate(MessageTemplateNumberOfCCDIncreases, TextOfGTDRNPT, "%1", "%2");
	
	While Selection.Next() Do
		
		If Selection.TypeOfVerification = "NotSpecifiedWarehouse" Then
			MessageText = StrTemplate(MessageTemplateFieldNotFilledIn, NStr("vi = 'Kho bãi';
																			|ru = 'Склад';
																			|en = 'Warehouse'; fa = 'Warehouse';
																			|it = 'Magazzino';
																			|pl = 'Magazyn';
																			|tr = 'Ambar'"));
			
			Common.MessageToUser(MessageText,
													Undefined,
													"Warehouse",
													"Object",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotProductRANGEIsSpecified" Then
			MessageText = StrTemplate(MessageTemplateColumnNotFilledIn,
										NStr("vi = 'Mặt hàng';
											|ru = 'Номенклатура';
											|en = 'Item'; fa = 'قلم';
											|it = 'Nomenclatura';
											|pl = 'Produkt';
											|tr = 'Öğe'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"Products");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotContentIsSpecified" Then
			MessageText = StrTemplate(MessageTemplateColumnNotFilledIn,
										NStr("vi = 'Nội dung';
											|ru = 'Содержание';
											|en = 'Content'; fa = 'محتوا';
											|it = 'Contenuto';
											|pl = 'Treść';
											|tr = 'İçerik'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"Content");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotCharacteristicIsSpecified" Then
			MessageText = StrTemplate(MessageTemplateColumnNotFilledIn,
										NStr("vi = 'Đặc tính';
											|ru = 'Характеристика';
											|en = 'Variant'; fa = 'گونه';
											|it = 'Caratteristica';
											|pl = 'Charakterystyka';
											|tr = 'Varyant'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"Characteristic");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotCCDNumberIsSpecified" Then
			MessageText = StrTemplate(MessageTemplateColumnNotFilledIn,
										NStr("vi = 'Số TKHQ';
											|ru = 'Номер ГТД';
											|en = 'CCD number'; fa = 'شماره اظهارنامه گمرکی (CCD)';
											|it = 'Numero della polizza doganale di carico';
											|pl = 'Numer ŁDC (ładunkowej deklaracji celnej)';
											|tr = 'Gümrük kargo beyannamesi numarası'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"CCDNumber");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "QuantityRecalculationError" Then
			MessageText = StrTemplate(MessageTemplateQuantityRecalculationError,
										NStr("vi = 'số lượng trước khi điều chỉnh';
											|ru = 'количество до корректировки';
											|en = 'quantity before adjustment'; fa = 'quantity before adjustment';
											|it = 'quantità prima della correzione';
											|pl = 'ilość przed korektą';
											|tr = 'düzeltmeden önceki miktar'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"NumberOfPackages");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotNumberOfPackagesIsIndicated" Then
			MessageText = StrTemplate(MessageTemplateColumnNotFilledIn,
										NStr("vi = 'Số lượng đóng gói trước khi điều chỉnh';
											|ru = 'Количество упаковок до корректировки';
											|en = 'Packaging unit quantity before adjustment'; fa = 'Packaging unit quantity before adjustment';
											|it = 'Quantità di imballaggi prima della correzione';
											|pl = 'Liczba opakowań przed korektą';
											|tr = 'Düzeltmeden önceki paket miktarı'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"NumberOfPackages");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "ErrorInRecalculatingQuantityAfter" Then
			MessageText = StrTemplate(MessageTemplateQuantityRecalculationError,
										NStr("vi = 'số lượng sau khi điều chỉnh';
											|ru = 'количество после корректировки';
											|en = 'quantity after adjustment'; fa = 'quantity after adjustment';
											|it = 'quantità dopo la correzione';
											|pl = 'ilość po korekcie';
											|tr = 'düzeltmeden sonraki miktar'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"NumberOfPackagesAfter");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotNumberOfPackagesAfter" Then
			MessageText = StrTemplate(MessageTemplateColumnNotFilledIn,
										NStr("vi = 'Số lượng bộ đóng gói sau khi điều chỉnh';
											|ru = 'Количество упаковок после корректировки';
											|en = 'Packaging unit quantity after adjustment'; fa = 'Packaging unit quantity after adjustment';
											|it = 'Quantità di imballaggi dopo la correzione';
											|pl = 'Liczba opakowań po korekcie';
											|tr = 'Düzeltmeden sonraki paket miktarı'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"NumberOfPackagesAfter");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotQuantityIsIndicatedAccordingToRNPT" Then
			MessageText = StrTemplate(MessageTemplateColumnNotFilledIn,
										NStr("vi = 'Số lượng theo số đăng ký lô hàng trước khi điều chỉnh';
											|ru = 'Количество по РНПТ до корректировки';
											|en = 'Quantity by RNPT before adjustment'; fa = 'Quantity by RNPT before adjustment';
											|it = 'Quantità per numero di registrazione lotti prodotti prima della correzione';
											|pl = 'Ilość wg numeru rejestracyjnego partii towaru przed korektą';
											|tr = 'RNPT''ye göre miktar düzeltme öncesi'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"QuantityByGBRN");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotQuantityIndicatedByRNPTAfter" Then
			MessageText = StrTemplate(MessageTemplateColumnNotFilledIn,
										NStr("vi = 'Số lượng theo số đăng ký lô hàng sau khi điều chỉnh';
											|ru = 'Количество по РНПТ после корректировки';
											|en = 'Quantity by RNPT after adjustment'; fa = 'Quantity by RNPT after adjustment';
											|it = 'Quantità per numero di registrazione lotti prodotti dopo la correzione';
											|pl = 'Ilość wg numeru rejestracyjnego partii towaru po korekcie';
											|tr = 'RNPT''ye göre miktar düzeltme sonrası'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"QuantityAccordingToRNPTAfter");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "AmountOfCCDWithIncrease" Then
			MessageText = StrTemplate(MessageTemplateNumberOfCCDIncreases,
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"NumberOfPackages");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
			
		If Selection.TypeOfVerification = "NotPriceShownIsUpTo" Then
			MessageText = StrTemplate(MessageTemplateColumnNotFilledIn,
										NStr("vi = 'Đơn giá trước khi điều chỉnh';
											|ru = 'Цена до корректировки';
											|en = 'Price before adjustment'; fa = 'Price before adjustment';
											|it = 'Prezzo prima della correzione';
											|pl = 'Cena przed korektą';
											|tr = 'Düzeltmeden önceki fiyat'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"Price");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotPriceIsIndicatedAfter" Then
			MessageText = StrTemplate(MessageTemplateColumnNotFilledIn,
										NStr("vi = 'Đơn giá sau khi điều chỉnh';
											|ru = 'Цена после корректировки';
											|en = 'Price after adjustment'; fa = 'Price after adjustment';
											|it = 'Prezzo dopo la correzione';
											|pl = 'Cena po korekcie';
											|tr = 'Düzeltmeden sonraki fiyat'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"PriceAfter");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotSpecifiedAmountIsUpTo" Then
			MessageText = StrTemplate(MessageTemplateColumnNotFilledIn,
										NStr("vi = 'Số tiền trước khi điều chỉnh';
											|ru = 'Сумма до корректировки';
											|en = 'Amount before adjustment'; fa = 'Amount before adjustment';
											|it = 'Importo prima della correzione';
											|pl = 'Wartość przed korektą';
											|tr = 'Düzeltmeden önceki tutar'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"Sum");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotAmountSpecifiedAfter" Then
			MessageText = StrTemplate(MessageTemplateColumnNotFilledIn,
										NStr("vi = 'Số tiền sau khi điều chỉnh';
											|ru = 'Сумма после корректировки';
											|en = 'Amount after adjustment'; fa = 'Amount after adjustment';
											|it = 'Importo dopo la correzione';
											|pl = 'Wartość po korekcie';
											|tr = 'Düzeltmeden sonraki tutar'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"AmountAfter");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotVATRateIsIndicated" Then
			MessageText = StrTemplate(MessageTemplateColumnNotFilledIn,
										NStr("vi = 'Thuế suất GTGT trước khi điều chỉnh';
											|ru = 'Ставка НДС до корректировки';
											|en = 'VAT rate before adjustment'; fa = 'VAT rate before adjustment';
											|it = 'Aliquota IVA prima della correzione';
											|pl = 'Stawka VAT przed korektą';
											|tr = 'Düzeltmeden önceki KDV oranı'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"VATRate");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotVATRateIsIndicatedAfter" Then
			MessageText = StrTemplate(MessageTemplateColumnNotFilledIn,
										NStr("vi = 'Thuế suất GTGT sau khi điều chỉnh';
											|ru = 'Ставка НДС после корректировки';
											|en = 'VAT rate after adjustment'; fa = 'VAT rate after adjustment';
											|it = 'Aliquota IVA dopo la correzione';
											|pl = 'Stawka VAT po korekcie';
											|tr = 'Düzeltmeden sonraki KDV oranı'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"VATRateAfter");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotOptionForReflectingWriteOffIsSpecified" Then
			MessageText = StrTemplate(MessageTemplateNotSpecifiedOptionForDebitingReflection,
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"OptionToReflectWriteOff");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotVariantOfReflectionOfDiscrepancyIsIndicated" Then
			MessageText = StrTemplate(MessageTemplateNotSpecifiedOptionToReflectDiscrepancy,
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"PostingOption");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotWarehouseIsListedInTablePart" Then
			MessageText = StrTemplate(MessageTemplateColumnNotFilledIn,
										NStr("vi = 'Kho bãi';
											|ru = 'Склад';
											|en = 'Warehouse'; fa = 'Warehouse';
											|it = 'Magazzino';
											|pl = 'Magazyn';
											|tr = 'Ambar'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"Warehouse");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotDivisionIsIndicatedInTabularPart" Then
			MessageText = StrTemplate(MessageTemplateColumnNotFilledIn,
										NStr("vi = 'Bộ phận gửi';
											|ru = 'Подразделение-отправитель';
											|en = 'Shipping business unit'; fa = 'واحد تجاری ارسال‌کننده';
											|it = 'Reparto-mittente';
											|pl = 'Dział-nadawca';
											|tr = 'Gönderen departman'"),
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"Department");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "NotMethodOfDeterminingCostIsSpecified" Then
			MessageText = StrTemplate(MessageTemplateDoesNotSpecifyMethodForDeterminingCost,
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"MethodForDeterminingTheCostOfALine");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "VATTaxationDoesNotCorrespondToBasis" Then
			
			MessageText = StrTemplate(MessageTemplateDoesNotMatchBase, NStr("vi = 'Hệ thống thuế';
																			|ru = 'Налогообложение';
																			|en = 'Taxation'; fa = 'مالیات‌ستانی';
																			|it = 'Налогообложение';
																			|pl = 'Opodatkowanie';
																			|tr = 'Vergilendirme'"));
			
			Common.MessageToUser(MessageText,
													Undefined,
													"Object.VATTaxation",
													"",
													Cancel);
			
		EndIf;
		
		If Selection.TypeOfVerification = "OrganizationDoesNotMatchFoundation" Then
			
			MessageText = StrTemplate(MessageTemplateDoesNotMatchBase, NStr("vi = 'Doanh nghiệp';
																			|ru = 'Организация';
																			|en = 'Company'; fa = 'Company';
																			|it = 'Организация';
																			|pl = 'Firma';
																			|tr = 'İş yeri'"));
			
			Common.MessageToUser(MessageText,
													Undefined,
													"Object.Organization",
													"",
													Cancel);
			
		EndIf;
		
		If Selection.TypeOfVerification = "PartnerDoesNotMatchFoundation" Then
			
			MessageText = StrTemplate(MessageTemplateDoesNotMatchBase, NStr("vi = 'Khách hàng';
																			|ru = 'Клиент';
																			|en = 'Customer'; fa = 'مشتری';
																			|it = 'Клиент';
																			|pl = 'Klient';
																			|tr = 'Müşteri'"));
			
			Common.MessageToUser(MessageText,
													Undefined,
													"Object.Partner",
													"",
													Cancel);
			
		EndIf;
		
		If Selection.TypeOfVerification = "CounterpartyDoesNotMatchBasis" Then
			
			MessageText = StrTemplate(MessageTemplateDoesNotMatchBase, NStr("vi = 'Đối tác';
																			|ru = 'Контрагент';
																			|en = 'Counterparty'; fa = 'طرف حساب';
																			|it = 'Контрагент';
																			|pl = 'Kontrahent';
																			|tr = 'Cari hesap'"));
			
			Common.MessageToUser(MessageText,
													Undefined,
													"Object.Counterparty",
													"",
													Cancel);
			
		EndIf;
		
		If Selection.TypeOfVerification = "ContractDoesNotCorrespondToBasis" Then
			
			MessageText = StrTemplate(MessageTemplateDoesNotMatchBase, NStr("vi = 'Hợp đồng';
																			|ru = 'Договор';
																			|en = 'Contract'; fa = 'قرارداد';
																			|it = 'Договор';
																			|pl = 'Umowa';
																			|tr = 'Sözleşme'"));
			
			Common.MessageToUser(MessageText,
													Undefined,
													"Object.Contract",
													"",
													Cancel);
			
		EndIf;
		
		If Selection.TypeOfVerification = "OrderOfCalculationsDoesNotCorrespondToBase" Then
			
			MessageText = StrTemplate(MessageTemplateDoesNotMatchBase, NStr("vi = 'Trình tự hạch toán';
																			|ru = 'Порядок расчетов';
																			|en = 'Payment terms'; fa = 'شرایط پرداخت';
																			|it = 'Modalità di regolamenti';
																			|pl = 'Sposób rozliczeń';
																			|tr = 'Uzlaşma prosedürü'"));
			
			Common.MessageToUser(MessageText,
													Undefined,
													"Object.ARAPObjectSettings",
													"",
													Cancel);
			
		EndIf;
		
		If Selection.TypeOfVerification = "TypeOfAdjustmentDoesNotMatchPreviousOne" Then
			
			MessageText = StrTemplate(MessageTemplateDoesNotMatchPreviousCorrection, NStr("vi = 'Kiểu điều chỉnh';
																							|ru = 'Тип корректировки';
																							|en = 'Adjusting entry type'; fa = 'نوع ثبت تعدیلی';
																							|it = 'Tipo di rettifica';
																							|pl = 'Typ korekty';
																							|tr = 'Düzeltme türü'"));
			
			Common.MessageToUser(MessageText,
													Undefined,
													"Object.AdjustingEntryType",
													"",
													Cancel);
			
		EndIf;
		
		If Selection.TypeOfVerification = "PriceIncludesVATDoesNotCorrespondToPreviousOne" Then
			
			MessageText = StrTemplate(MessageTemplateDoesNotMatchPreviousCorrection, NStr("vi = 'Đơn giá gồm thuế GTGT';
																							|ru = 'Цена включает НДС';
																							|en = 'Price includes VAT'; fa = 'قیمت شامل مالیات بر ارزش افزوده است';
																							|it = 'Il prezzo include l''IVA';
																							|pl = 'Cena zawiera VAT';
																							|tr = 'Fiyata KDV dahildir'"));
			
			Common.MessageToUser(MessageText,
													Undefined,
													"Object.PriceIncludesVAT",
													"",
													Cancel);
			
		EndIf;
		
		If Selection.TypeOfVerification = "AmountOfMutualSettlementsIsNotSpecified" Then
			MessageText = StrTemplate(MessageTemplateRewardAmountColumnIsNotFilledIn,
										NStr("vi = 'Số tiền hạch toán trước khi điều chỉnh.';
											|ru = 'Сумма взаиморасчетов до корректировки.';
											|en = 'AR/AP amount before adjustment.'; fa = 'AR/AP amount before adjustment.';
											|it = 'Сумма взаиморасчетов до корректировки.';
											|pl = 'AR/AP amount before adjustment.';
											|tr = 'Düzeltme öncesi Alacak/Borç muhasebesi tutarı.'"),
										Selection.LineNumber,
										PresentationOfTS,
										NStr("vi = 'Để hạch toán tự động, cần xóa số tiền hạch toán sau điều chỉnh.';
											|ru = 'Для автоматического расчета необходимо очистить сумму взаиморасчета после корректировки.';
											|en = 'To calculate the amount automatically, clear the AR/AP amount after adjustment.'; fa = 'To calculate the amount automatically, clear the AR/AP amount after adjustment.';
											|it = 'Для автоматического расчета необходимо очистить сумму взаиморасчета после корректировки.';
											|pl = 'To calculate the amount automatically, clear the AR/AP amount after adjustment.';
											|tr = 'Otomatik hesaplama için düzeltme sonrası Alacak/Borç muhasebesi tutarını silmeniz gerekmektedir.'"));
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"AmountARAP");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "AmountOfSettlementsAfterIsNotSpecified" Then
			MessageText = StrTemplate(MessageTemplateRewardAmountColumnIsNotFilledIn,
										NStr("vi = 'Số tiền hạch toán sau điều chỉnh.';
											|ru = 'Сумма взаиморасчетов после корректировки.';
											|en = 'AR/AP amount after adjustment.'; fa = 'AR/AP amount after adjustment.';
											|it = 'Сумма взаиморасчетов после корректировки.';
											|pl = 'AR/AP amount after adjustment.';
											|tr = 'Düzeltme sonrası Alacak/Borç muhasebesi tutarı.'"),
										Selection.LineNumber,
										PresentationOfTS,
										NStr("vi = 'Để hạch toán tự động, cần xóa số tiền hạch toán trước điều chỉnh.';
											|ru = 'Для автоматического расчета необходимо очистить сумму взаиморасчета до корректировки.';
											|en = 'To calculate the amount automatically, clear the AR/AP amount before adjustment.'; fa = 'To calculate the amount automatically, clear the AR/AP amount before adjustment.';
											|it = 'Для автоматического расчета необходимо очистить сумму взаиморасчета до корректировки.';
											|pl = 'To calculate the amount automatically, clear the AR/AP amount before adjustment.';
											|tr = 'Otomatik hesaplama için düzeltme öncesi Alacak/Borç muhasebesi tutarını silmeniz gerekmektedir.'"));
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"AmountOfSettlementsAfter");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ReportErrorsAlongCorrectionChain(Selection, Cancel)
	
	TSName			= "AdjustmentTable";
	PresentationOfTS	= NStr("vi = 'Dữ liệu điều chỉnh';
								|ru = 'Данные корректировки';
								|en = 'Adjustment data'; fa = 'Adjustment data';
								|it = 'Dati di correzione';
								|pl = 'Dane korekty';
								|tr = 'Düzeltme verileri'");
	
	MessageTemplateDivergesValueQuantity	= NStr("vi = 'Cảnh báo: trong trường ""%1"", trong dòng %2 đã chỉ ra số lượng khác  với số lượng %3 sau điều chỉnh gần nhất';
													|ru = 'Предупреждение: в поле ""%1"" в строке %2 указано количество отличное от количества %3 после последней корректировки';
													|en = 'Warning: in line %2 of the %1 field, the quantity different from the quantity %3 after the last adjustment is specified'; fa = 'Warning: in line %2 of the %1 field, the quantity different from the quantity %3 after the last adjustment is specified';
													|it = 'Предупреждение: в поле ""%1"" в строке %2 указано количество отличное от количества %3 после последней корректировки';
													|pl = 'Warning: in line %2 of the %1 field, the quantity different from the quantity %3 after the last adjustment is specified';
													|tr = 'Uyarı: %2 satırdaki ""%1"" alanında, son düzeltmeden sonraki %3miktarından farklı bir miktar belirtildi'");
	MessageTemplateDivergesValueAmount		= NStr("vi = 'Cảnh báo: trong trường ""%1"" dòng %2 đã chỉ ra số tiền khác với số tiền %3 sau khi điều chỉnh gần nhất';
													|ru = 'Предупреждение: в поле ""%1"" в строке %2 указана сумма отличная от суммы %3 после последней корректировки';
													|en = 'Warning: in line %2 of the %1 field, the amount different from the amount %3 after the last adjustment is specified'; fa = 'Warning: in line %2 of the %1 field, the amount different from the amount %3 after the last adjustment is specified';
													|it = 'Предупреждение: в поле ""%1"" в строке %2 указана сумма отличная от суммы %3 после последней корректировки';
													|pl = 'Warning: in line %2 of the %1 field, the amount different from the amount %3 after the last adjustment is specified';
													|tr = 'Uyarı: %2 satırdaki ""%1"" alanında, son düzeltmeden sonraki %3 tutarından farklı bir tutar belirtildi'");
	MessageTemplateDivergesVATRate			= NStr("vi = 'Cảnh báo: thuế suất GTGT tại dòng %1 khác với thuế suất GTGT %2 sau khi điều chỉnh gần nhất';
													|ru = 'Предупреждение: ставка НДС в строке %1 отличается от ставки НДС %2 после последней корректировки';
													|en = 'Warning: VAT rate in line %1 is different from the VAT rate %2 after the last adjustment'; fa = 'Warning: VAT rate in line %1 is different from the VAT rate %2 after the last adjustment';
													|it = 'Предупреждение: ставка НДС в строке %1 отличается от ставки НДС %2 после последней корректировки';
													|pl = 'Warning: VAT rate in line %1 is different from the VAT rate %2 after the last adjustment';
													|tr = 'Uyarı: %1 satırdaki KDV oranı, son düzeltmeden sonraki %2 KDV oranından farklıdır'");
	
	While Selection.Next() Do
	
		If Selection.TypeOfVerification = "ErrorQuantityByInitialAdjustment" Then
			
			MessageText = StrTemplate(MessageTemplateDivergesValueQuantity,
										NStr("vi = 'Số lượng đóng gói';
											|ru = 'Количество упаковок';
											|en = 'Quantity'; fa = 'مقدار';
											|it = 'Numero di imballaggi';
											|pl = 'Liczba opakowań';
											|tr = 'Paket miktarı'"),
										Selection.LineNumber,
										Selection.SourceValue);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"Count");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													);
		EndIf;
		
		If Selection.TypeOfVerification = "ErrorNumberOfPackagesByInitialCorrection" Then
			
			MessageText = StrTemplate(MessageTemplateDivergesValueQuantity,
										NStr("vi = 'Số lượng đóng gói';
											|ru = 'Количество упаковок';
											|en = 'Quantity'; fa = 'مقدار';
											|it = 'Numero di imballaggi';
											|pl = 'Liczba opakowań';
											|tr = 'Paket miktarı'"),
										Selection.LineNumber,
										Selection.SourceValue);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"NumberOfPackages");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													);
		EndIf;
		
		If Selection.TypeOfVerification = "AmountErrorBasedOnInitialAdjustment" Then
			
			MessageText = StrTemplate(MessageTemplateDivergesValueAmount,
										NStr("vi = 'Số tiền';
											|ru = 'Сумма';
											|en = 'Amount'; fa = 'مبلغ';
											|it = 'Сумма';
											|pl = 'Wartość';
											|tr = 'Tutar'"),
										Selection.LineNumber,
										Selection.SourceValue);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"Sum");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													);
		EndIf;

		If Selection.TypeOfVerification = "ErrorInVATAmountBasedOnInitialAdjustment" Then
			
			MessageText = StrTemplate(MessageTemplateDivergesValueAmount,
										NStr("vi = 'Thuế GTGT';
											|ru = 'Сумма НДС';
											|en = 'VAT amount'; fa = 'مبلغ مالیات بر ارزش افزوده';
											|it = 'Importo IVA';
											|pl = 'Wartość VAT';
											|tr = 'KDV tutarı'"),
										Selection.LineNumber,
										Selection.SourceValue);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"VATAmount");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													);
		EndIf;

		If Selection.TypeOfVerification = "ErrorInAmountWithVATForInitialAdjustment" Then
			
			MessageText = StrTemplate(MessageTemplateDivergesValueAmount,
										NStr("vi = 'Số tiền gồm thuế GTGT';
											|ru = 'Сумма с НДС';
											|en = 'Amount including VAT'; fa = 'مبلغ با احتساب مالیات بر ارزش افزوده';
											|it = 'Importo IVA inclusa';
											|pl = 'Wartość z VAT';
											|tr = 'KDV dahil tutar'"),
										Selection.LineNumber,
										Selection.SourceValue);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"AmountIncludingVAT");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													);
		EndIf;

		If Selection.TypeOfVerification = "VATRateError" Then
			
			MessageText = StrTemplate(MessageTemplateDivergesVATRate,
										Selection.LineNumber,
										Selection.SourceValue);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"BidWithVAT");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													);
		EndIf;
		
	EndDo;

EndProcedure

Procedure CheckIndicationOfAmountAndAmountOfVAT(Object, TempTablesManager, Cancel)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryTextChecksForSpecifyingAmountAndAmountOfVAT();
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	TSName			= "AdjustmentTable";
	PresentationOfTS	= NStr("vi = 'Dữ liệu điều chỉnh';
								|ru = 'Данные корректировки';
								|en = 'Correction data'; fa = 'داده‌های اصلاح';
								|it = 'Dati di correzione';
								|pl = 'Dane korekty';
								|tr = 'Düzeltme verileri'");
	
	MessageTemplateErrorSpecifyingAmount		= NStr("vi = 'Số tiền thuế GTGT trước khi điều chỉnh %1 %2 với thuế suất ""%3"" nhiều hơn tổng số tiền trước khi điều chỉnh theo dòng %4 %5 tại dòng %6 danh sách ""%7""';
														|ru = 'Сумма НДС до корректировки %1 %2 при ставке ""%3"" больше общей суммы до корректировки по строке %4 %5 в строке %6 списка ""%7""';
														|en = 'VAT rate before adjustment %1 %2 at rate %3 is greater than the total amount before the adjustment for line %4 %5 in line %6 of the %7 list'; fa = 'VAT rate before adjustment %1 %2 at rate %3 is greater than the total amount before the adjustment for line %4 %5 in line %6 of the %7 list';
														|it = 'Importo IVA prima della correzione %1%2 all''aliquota ""%3"" è maggiore dell''importo comune prima della correzione in base alla stringa %4 %5 nella stringa %6 dell''elenco ""%7""';
														|pl = 'Kwota VAT przed korektą %1 %2 przy stawce ""%3"" jest większa niż łączna wartość przed korektą wg wiersza %4 %5 w wierszu %6 listy ""%7""';
														|tr = '""%3"" oranındaki %1%2düzeltmesi öncesi KDV tutarı, ""%7"" listesinin %6 satırındaki %4%5düzeltmesi öncesi toplam tutardan yüksektir'");
	MessageTemplateErrorSpecifyingAmountAfter	= NStr("vi = 'Số tiền thuế GTGT sau khi điều chỉnh %1 %2 với thuế suất ""%3"" nhiều hơn tổng số tiền sau khi điều chỉnh theo dòng %4 %5 tại dòng %6 danh sách ""%7""';
														|ru = 'Сумма НДС после корректировки %1 %2 при ставке ""%3"" больше общей суммы после корректировки по строке %4 %5 в строке %6 списка ""%7""';
														|en = 'VAT rate after the adjustment %1 %2 at rate %3 is greater than the total amount after the adjustment for line %4 %5 in line %6 of the %7 list'; fa = 'VAT rate after the adjustment %1 %2 at rate %3 is greater than the total amount after the adjustment for line %4 %5 in line %6 of the %7 list';
														|it = 'L''importo IVA dopo la correzione %1%2 all''aliquota ""%3"" è maggiore dell''importo comune dopo la correzione in base alla stringa %4 %5 nella stringa %6 dell''elenco ""%7""';
														|pl = 'Kwota VAT po korekcie %1 %2 przy stawce ""%3"" jest większa niż łączna wartość po korekcie wg wiersza %4 %5 w wierszu %6 listy ""%7""';
														|tr = '""%3"" oranındaki %1%2düzeltmesi sonrası KDV tutarı, ""%7"" listesinin %6 satırındaki %4%5düzeltmesi sonrası toplam tutardan yüksektir'");
	
	While Selection.Next() Do
		
		CheckVATAmount = True;
		
		If ValueIsFilled(Selection.ProductsInSet) Then
			If Selection.SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares
				Or Selection.SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices Then
				
				CheckVATAmount = False;
				
			EndIf;
		EndIf;
		
		If Not CheckVATAmount Then
			Continue;
		EndIf;
		
		If Selection.TypeOfVerification = "ErrorSpecifyingAmount" Then
			MessageText = StrTemplate(MessageTemplateErrorSpecifyingAmount,
										Selection.VATAmount,
										Object.Currency,
										Selection.VATRate,
										Selection.Sum,
										Object.Currency,
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"VATAmount");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
		If Selection.TypeOfVerification = "ErrorSpecifyingAmountAfter" Then
			MessageText = StrTemplate(MessageTemplateErrorSpecifyingAmount,
										Selection.VATAmount,
										Object.Currency,
										Selection.VATRate,
										Selection.Sum,
										Object.Currency,
										Selection.LineNumber,
										PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(TSName,
																	Selection.LineNumber,
																	"VATAmountAfter");
			
			Common.MessageToUser(MessageText,
													Undefined,
													Field,
													"",
													Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

Function QueryTextChecksForSpecifyingAmountAndAmountOfVAT()
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber			AS LineNumber,
	|	""ErrorSpecifyingAmount""				AS TypeOfVerification,
	|	TableOfGoods.ProductsInSet	AS ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet	AS ItemVariantOfSet,
	|	ISNULL(KitConfigurations.SetPricingOption, UNDEFINED) AS SetPricingOption,
	|	TableOfGoods.Sum				AS Sum,
	|	TableOfGoods.VATAmount				AS VATAmount,
	|	TableOfGoods.VATRate			AS VATRate,
	|	CASE
	|		WHEN TableOfGoods.Sum < 0
	|				AND TableOfGoods.Sum - TableOfGoods.VATAmount <= 0
	|			THEN FALSE
	|		WHEN TableOfGoods.Sum >= 0
	|				AND TableOfGoods.Sum - TableOfGoods.VATAmount >= 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END								AS ThereAreErrorsInVATAmount
	|FROM
	|	TemporaryTableOfGoods_ AS TableOfGoods
	|		LEFT JOIN Catalog.ProductKitConfigurations AS KitConfigurations
	|		ON TableOfGoods.ProductsInSet = KitConfigurations.Owner
	|			AND TableOfGoods.ItemVariantOfSet = KitConfigurations.Characteristic
	|
	|WHERE
	|	CASE
	|		WHEN TableOfGoods.Sum < 0
	|				AND TableOfGoods.Sum - TableOfGoods.VATAmount <= 0
	|			THEN FALSE
	|		WHEN TableOfGoods.Sum >= 0
	|				AND TableOfGoods.Sum - TableOfGoods.VATAmount >= 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber			AS LineNumber,
	|	""ErrorSpecifyingAmountAfter""		AS TypeOfVerification,
	|	TableOfGoods.ProductsInSet	AS ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet	AS ItemVariantOfSet,
	|	ISNULL(KitConfigurations.SetPricingOption, UNDEFINED) AS SetPricingOption,
	|	TableOfGoods.AmountAfter			AS Sum,
	|	TableOfGoods.VATAmountAfter		AS VATAmount,
	|	TableOfGoods.VATRateAfter		AS VATRate,
	|	CASE
	|		WHEN TableOfGoods.AmountAfter < 0
	|				AND TableOfGoods.AmountAfter - TableOfGoods.VATAmountAfter <= 0
	|			THEN FALSE
	|		WHEN TableOfGoods.AmountAfter >= 0
	|				AND TableOfGoods.AmountAfter - TableOfGoods.VATAmountAfter >= 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END								AS ThereAreErrorsInVATAmount
	|FROM
	|	TemporaryTableOfGoods_ AS TableOfGoods
	|		LEFT JOIN Catalog.ProductKitConfigurations AS KitConfigurations
	|		ON TableOfGoods.ProductsInSet = KitConfigurations.Owner
	|			AND TableOfGoods.ItemVariantOfSet = KitConfigurations.Characteristic
	|
	|WHERE
	|	CASE
	|		WHEN TableOfGoods.AmountAfter < 0
	|				AND TableOfGoods.AmountAfter - TableOfGoods.VATAmountAfter <= 0
	|			THEN FALSE
	|		WHEN TableOfGoods.AmountAfter >= 0
	|				AND TableOfGoods.AmountAfter - TableOfGoods.VATAmountAfter >= 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

Procedure CheckCorrectnessOfSelectionOfProductForVATTaxation(TempTablesManager, Cancel)
	
	QueryOptions = New Structure;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = VATAccountingERP.TextOfRequestCorrectnessOfSelectionOfProductsForTaxationOfVATSales(QueryOptions);
	
	For Each QueryParameter In QueryOptions Do
		Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
	EndDo;
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	TSName			= "AdjustmentTable";
	PresentationOfTS	= NStr("vi = 'Dữ liệu điều chỉnh';
								|ru = 'Данные корректировки';
								|en = 'Correction data'; fa = 'داده‌های اصلاح';
								|it = 'Dati di correzione';
								|pl = 'Dane korekty';
								|tr = 'Düzeltme verileri'");
	
	VATAccountingERP.ReportErrorsCorrectSelectionOfProductsForVATSales(
		Selection,
		Undefined,
		TSName,
		PresentationOfTS,
		Cancel);
	
EndProcedure

Function ResultsOfDiscrepancyCheck(Object, VTAdjustmentTable)
	
	CheckResult = New Structure;
	CheckResult.Insert("AmountForOtherIncome",	0);
	CheckResult.Insert("AmountForOtherExpenses",	0);
	
	OtherAssetServiceAdjustment	= Object.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
	LastPeriodAdjustment	= False;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		SetPrivilegedMode(True);
		ReferenceDocumentDateForCertificate = Common.ObjectAttributeValue(Object.DocumentBasis, "Date");
		SetPrivilegedMode(False);
		
		DocumentDate					= ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
		LastPeriodAdjustment	= BegOfYear(DocumentDate) > BegOfYear(ReferenceDocumentDateForCertificate);
	EndIf;
	
	For Each LineOfDiscrepancies In VTAdjustmentTable Do
		If LineOfDiscrepancies.VATRate = LineOfDiscrepancies.VATRateAfter
			Or (LineOfDiscrepancies.QuantityAfter = 0
				And LineOfDiscrepancies.VATAmountAfter = 0
				And LineOfDiscrepancies.VATAmountAfter = 0) Then
			
			DiscrepancySumWithVAT	= LineOfDiscrepancies.AmountWithVATAfter - LineOfDiscrepancies.AmountIncludingVAT;
			DiscrepancyInAmountOfVAT		= LineOfDiscrepancies.VATAmountAfter - LineOfDiscrepancies.VATAmount;
			
			CalculateAmountsOfExpensesAndIncome(CheckResult, DiscrepancySumWithVAT, DiscrepancyInAmountOfVAT,
				LineOfDiscrepancies.PostingOption, OtherAssetServiceAdjustment, LastPeriodAdjustment);
			
		Else
			DiscrepancySumWithVAT	= -LineOfDiscrepancies.AmountIncludingVAT;
			DiscrepancyInAmountOfVAT		= -LineOfDiscrepancies.VATAmount;
			
			CalculateAmountsOfExpensesAndIncome(CheckResult, DiscrepancySumWithVAT, DiscrepancyInAmountOfVAT,
				LineOfDiscrepancies.OptionToReflectWriteOff, OtherAssetServiceAdjustment, LastPeriodAdjustment);
			
			DiscrepancySumWithVAT	= LineOfDiscrepancies.AmountWithVATAfter;
			DiscrepancyInAmountOfVAT		= LineOfDiscrepancies.VATAmountAfter;
			
			CalculateAmountsOfExpensesAndIncome(CheckResult, DiscrepancySumWithVAT, DiscrepancyInAmountOfVAT,
				LineOfDiscrepancies.PostingOption, OtherAssetServiceAdjustment, LastPeriodAdjustment);
		EndIf;
	EndDo;
	
	Return CheckResult;
	
EndFunction

Procedure CalculateAmountsOfExpensesAndIncome(SumData,
													DiscrepancySumWithVAT,
													DiscrepancyInAmountOfVAT,
													PostingOption,
													OtherAssetServiceAdjustment,
													LastPeriodAdjustment)
	
	If PostingOption = Enums.CreditNoteRecordingOptions.RecordInOtherIncome Then
		If OtherAssetServiceAdjustment
			And Not LastPeriodAdjustment Then
			
			SumData.AmountForOtherIncome = SumData.AmountForOtherIncome + DiscrepancySumWithVAT;
			
		Else
			SumData.AmountForOtherIncome = SumData.AmountForOtherIncome + ?(DiscrepancySumWithVAT < 0,
																				-DiscrepancySumWithVAT,
																				DiscrepancySumWithVAT);
		EndIf;
	ElsIf PostingOption = Enums.CreditNoteRecordingOptions.ToExpenseAs
		Or PostingOption = Enums.CreditNoteRecordingOptions.ReduceSaleWriteOffForExpenses Then
		
		SumData.AmountForOtherExpenses = SumData.AmountForOtherExpenses + ?(DiscrepancySumWithVAT < 0,
																				-DiscrepancySumWithVAT,
																				DiscrepancySumWithVAT);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region SetOfSeries

Function QueryTextForFillingInStatusesForSpecifyingSeriesOfItems()
	
	QueryText = 
	"SELECT
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Products AS Products,
	|	Goods.Series AS Series,
	|	Goods.Count AS Count,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.LineNumber AS LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Products AS Products,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE CASE
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 14
	|							ELSE 13
	|						END
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatus,
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE
	|			CASE
	|				WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN
	|						CASE
	|							WHEN &DocumentOperation_ IN (VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|														VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|										AND ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|									OR &DocumentOperation_ = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|										AND ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingForGoodsBatchesShippedToCustomer
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
	|	END AS BatchesIndicationStatusOfGoodsTransferred
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|				INNER JOIN Catalog.Warehouses AS Warehouses
	|				ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|			ON (BatchAccountingPolicies.Warehouse = ProductsToRequest.Warehouse)
	|				AND (ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref)
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Warehouse = ProductsToRequest.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber                          AS LineNumber,
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchesIndicationStatusOfGoodsTransferred
	|		ELSE Statuses.BatchesIndicationStatus
	|	END                                        AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchesIndicationStatusOfGoodsTransferred
	|		ELSE Statuses.BatchesIndicationStatus
	|	END <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

Function QueryTextForFillingInStatusesAndSpecifyingDiscrepancySeries()
	
	QueryText = 
	"SELECT
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Products AS Products,
	|	Goods.Series AS Series,
	|	Goods.Count AS Count,
	|	Goods.PostingOption AS PostingOption,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusInWarehouses AS BatchesIndicationStatusInWarehouses,
	|	Goods.BatchesIndicationStatusOfGoodsTransferred AS BatchesIndicationStatusOfGoodsTransferred,
	|	Goods.LineNumber AS LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Products AS Products,
	|	Goods.PostingOption AS PostingOption,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	Goods.BatchesIndicationStatusInWarehouses AS OldStatusOfSpecifyingSeriesInWarehouses,
	|	Goods.BatchesIndicationStatusOfGoodsTransferred AS OldStatusOfSpecifyingSeriesOfTransferredGoods,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN &DocumentOperation_ = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|				AND NOT Goods.PostingOption IN (
	|						VALUE(Enum.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount),
	|						VALUE(Enum.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock),
	|						VALUE(Enum.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount),
	|						VALUE(Enum.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock)
	|						)
	|			THEN 0
	|		ELSE CASE
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 14
	|							ELSE 13
	|						END
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatus,
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE
	|			CASE
	|				WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN
	|						CASE
	|							WHEN &DocumentOperation_ IN (VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|														VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|										AND ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|									OR &DocumentOperation_ = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|										AND ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingForGoodsBatchesShippedToCustomer
	|									OR &DocumentOperation_ = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|										AND ProductsToRequest.PostingOption = VALUE(Enum.CreditNoteRecordingOptions.ReturnToTransit)
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
	|	END AS BatchesIndicationStatusOfGoodsTransferred
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|				INNER JOIN Catalog.Warehouses AS Warehouses
	|				ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|			ON BatchAccountingPolicies.Warehouse = ProductsToRequest.Warehouse
	|				AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Warehouse = ProductsToRequest.Warehouse
	|			AND Goods.PostingOption = ProductsToRequest.PostingOption
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchesIndicationStatusOfGoodsTransferred
	|		ELSE Statuses.BatchesIndicationStatus
	|	END AS BatchesIndicationStatus,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatusInWarehouses,
	|	Statuses.BatchesIndicationStatusOfGoodsTransferred AS BatchesIndicationStatusOfGoodsTransferred
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchesIndicationStatusOfGoodsTransferred
	|		ELSE Statuses.BatchesIndicationStatus
	|	END <> Statuses.OldStatusOfSpecifyingSeries
	|	OR Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeriesInWarehouses
	|	OR Statuses.BatchesIndicationStatusOfGoodsTransferred <> Statuses.OldStatusOfSpecifyingSeriesOfTransferredGoods
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	#Region Documents_CreditNotes_ProcessDataToUpgradeToNewVersion
	
	Handler = Handlers.Add();
	Handler.Procedure = "Documents.SaleAdjustment.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.25.22";
	Handler.ExecutionMode = "Deferred";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.Id = New UUID("d307c19a-eb0b-4bc4-830d-3e2270e401b6");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.SaleAdjustment.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật chứng từ ""Điều chỉnh bán hàng"":';
								|ru = 'Обновление документов ""Корректировка реализации"":';
								|en = 'Update the ""Sales adjustment"" documents:'; fa = 'Update the ""Sales adjustment"" documents:';
								|it = 'Обновление документов ""Корректировка реализации"":';
								|pl = 'Update the ""Sales adjustment"" documents:';
								|tr = '""Satış düzeltmesi"" belgelerinin yenilenmesi'"));
	ListOfDescriptions.Add(NStr("vi = '- điền mục tin ""Trạng thái chỉ định sê-ri trong kho"" và ""Trạng thái chỉ định sê-ri của hàng hóa đã chuyển giao"" trong phần bảng ""Chênh lệch"".';
								|ru = '- заполнение реквизитов ""Статус указания серий на складах"" и ""Статус указания серий, переданных товаров"" в табличной части ""Расхождения"".';
								|en = '- Fill the ""Batch specification status in warehouses"" and ""Batch indication status of goods transferred"" attributes in the ""Discrepancies"" table.'; fa = '- Fill the ""Batch specification status in warehouses"" and ""Batch indication status of goods transferred"" attributes in the ""Discrepancies"" table.';
								|it = '- Fill the ""Batch specification status in warehouses"" and ""Batch indication status of goods transferred"" attributes in the ""Discrepancies"" table.';
								|pl = '- Fill the ""Batch specification status in warehouses"" and ""Batch indication status of goods transferred"" attributes in the ""Discrepancies"" table.';
								|tr = '- ""Ambarlarda seri numaralarının durumu"" ve ""Teslim edilen ürünlerin seri numaralarının durumu"" bilgilerinin ""Tutarsızlıklar"" tablosuna girilmesi.'"));
	ListOfDescriptions.Add(NStr("vi = '- điền mục tin ""Đối tượng phân tích của kế toán mặt hàng"" trong phần bảng ""Chênh lệch"", ""Dạng vật tư ghi tăng"" đối với các chứng từ có cơ sở ""Giao hàng và cung cấp dịch vụ"" với giao dịch ""Bán hàng"".';
								|ru = '- заполнение реквизита ""Кор. аналитика учета номенклатуры"" в табличных частях ""Расхождения"", ""Виды запасов оприходование"" для документов с основанием ""Реализация товаров и услуг"" с операцией ""Реализация"".';
								|en = '- Fill in the ""Cor. inventory location attributes"" attribute in the ""Discrepancies"" and ""Inventory owner attributes goods receipt"" tables for documents generated based on the ""Customer invoice"" document with the ""Sales"" transaction.'; fa = '- Fill in the ""Cor. inventory location attributes"" attribute in the ""Discrepancies"" and ""Inventory owner attributes goods receipt"" tables for documents generated based on the ""Customer invoice"" document with the ""Sales"" transaction.';
								|it = '- Fill in the ""Cor. inventory location attributes"" attribute in the ""Discrepancies"" and ""Inventory owner attributes goods receipt"" tables for documents generated based on the ""Customer invoice"" document with the ""Sales"" transaction.';
								|pl = '- Fill in the ""Cor. inventory location attributes"" attribute in the ""Discrepancies"" and ""Inventory owner attributes goods receipt"" tables for documents generated based on the ""Customer invoice"" document with the ""Sales"" transaction.';
								|tr = '- ""Öğe muhasebesi analizi"" bilgisinin ""Tutarsızlıklar"", ""Ürün kabulünün türleri"" tablolarında, ""Ürün ve hizmet satışı"" kısmındaki ""Satış"" işlemiyle ilgili belgeler için doldurulması.'"));
	ListOfDescriptions.Add(NStr("vi = '- điền mục tin ""Đối tượng phân tích đối ứng kế toán mặt hàng"" trong phần bảng ""Chênh lệch"", ""Dạng vật tư ghi giảm"" đối với chứng từ có cơ sở ""Giao hàng hóa và dịch vụ"" với giao dịch ""Giao hàng"" và ""Chuyển giao quyền sở hữu"".';
								|ru = '- заполнение реквизита ""Кор. аналитика учета номенклатуры"" в табличной части ""Виды запасов списание"" для документов с основанием ""Реализация товаров и услуг"" с операциями ""Реализация"" и ""Переход права собственности"".';
								|en = '- Fill in the ""Cor. inventory location attributes"" attribute in the ""Inventory owner attributes write-off"" table for documents generated based on the ""Customer invoice"" document with the ""Sales"" and ""Transfer of title to goods"" transactions.'; fa = '- Fill in the ""Cor. inventory location attributes"" attribute in the ""Inventory owner attributes write-off"" table for documents generated based on the ""Customer invoice"" document with the ""Sales"" and ""Transfer of title to goods"" transactions.';
								|it = '- Fill in the ""Cor. inventory location attributes"" attribute in the ""Inventory owner attributes write-off"" table for documents generated based on the ""Customer invoice"" document with the ""Sales"" and ""Transfer of title to goods"" transactions.';
								|pl = '- Fill in the ""Cor. inventory location attributes"" attribute in the ""Inventory owner attributes write-off"" table for documents generated based on the ""Customer invoice"" document with the ""Sales"" and ""Transfer of title to goods"" transactions.';
								|tr = '- ""Ürün ve hizmet satışı"" esasına sahip belgeler ile ""Satış"" ve ""Mülkiyet hakkı devri"" işlemleri için ""Stok gider yazma türleri"" tablo bölümündeki ""Öğe muhasebesi analizi"" özniteliğinin doldurulması.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.SaleAdjustment.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
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
	|	HeaderAttributes.Ref AS Ref
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS DiscrepancyData
	|		INNER JOIN Document.SaleAdjustment AS HeaderAttributes
	|		ON DiscrepancyData.Ref = HeaderAttributes.Ref
	|WHERE
	|	NOT HeaderAttributes.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|												VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|	AND DiscrepancyData.BatchesIndicationStatus > 0
	|	AND DiscrepancyData.BatchesIndicationStatus <> DiscrepancyData.BatchesIndicationStatusInWarehouses
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	HeaderAttributes.Ref AS Ref
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS DiscrepancyData
	|		INNER JOIN Document.SaleAdjustment AS HeaderAttributes
	|		ON DiscrepancyData.Ref = HeaderAttributes.Ref
	|WHERE
	|	HeaderAttributes.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|											VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|	AND DiscrepancyData.BatchesIndicationStatus > 0
	|	AND DiscrepancyData.BatchesIndicationStatus <> DiscrepancyData.BatchesIndicationStatusOfGoodsTransferred
	|
	|UNION
	|
	|SELECT DISTINCT
	|	HeaderAttributes.Ref AS Ref
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS DiscrepancyData
	|		INNER JOIN Document.SaleAdjustment AS HeaderAttributes
	|		ON DiscrepancyData.Ref = HeaderAttributes.Ref
	|WHERE
	|	HeaderAttributes.Posted
	|	AND HeaderAttributes.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|	AND HeaderAttributes.DocumentBasis REFS Document.CustomerInvoice
	|	AND DiscrepancyData.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	HeaderAttributes.Ref AS Ref
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesConsumption AS DiscrepancyData
	|		INNER JOIN Document.SaleAdjustment AS HeaderAttributes
	|		ON DiscrepancyData.Ref = HeaderAttributes.Ref
	|WHERE
	|	HeaderAttributes.Posted
	|	AND HeaderAttributes.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleToCustomer),
	|												VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods))
	|	AND HeaderAttributes.DocumentBasis REFS Document.CustomerInvoice
	|	AND DiscrepancyData.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)";
	
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
	
	SelectionOfEmptyAnalytics = New Structure("CorItemsLocationAttributes",
											Catalogs.InventoryLocationAttributeKeys.EmptyRef());
	
	SalesOfOperationsThroughCommissionAgent = New Array;
	SalesOfOperationsThroughCommissionAgent.Add(Enums.BusinessTransactions.SalesViaCommissionAgent);
	SalesOfOperationsThroughCommissionAgent.Add(Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DiscrepancyData.LineNumber AS LineNumber
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS DiscrepancyData
	|		INNER JOIN Document.SaleAdjustment AS HeaderAttributes
	|		ON DiscrepancyData.Ref = HeaderAttributes.Ref
	|
	|WHERE
	|	DiscrepancyData.Ref = &Ref
	|	AND DiscrepancyData.BatchesIndicationStatus > 0
	|	AND DiscrepancyData.BatchesIndicationStatus <> DiscrepancyData.BatchesIndicationStatusInWarehouses
	|	AND NOT HeaderAttributes.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|												VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|
	|UNION ALL
	|
	|SELECT
	|	DiscrepancyData.LineNumber AS LineNumber
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS DiscrepancyData
	|		INNER JOIN Document.SaleAdjustment AS HeaderAttributes
	|		ON DiscrepancyData.Ref = HeaderAttributes.Ref
	|
	|WHERE
	|	DiscrepancyData.Ref = &Ref
	|	AND DiscrepancyData.BatchesIndicationStatus > 0
	|	AND DiscrepancyData.BatchesIndicationStatus <> DiscrepancyData.BatchesIndicationStatusOfGoodsTransferred
	|	AND HeaderAttributes.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|												VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))";
	
	For Each Document In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Document.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			DocumentObject = Document.Ref.GetObject(); // DocumentObject.SaleAdjustment - 
			
			If DocumentObject <> Undefined Then
				If DocumentObject.Posted
					And TypeOf(DocumentObject.DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
					
					If DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer Then
						LinesOfDivergence = DocumentObject.Discrepancies.FindRows(SelectionOfEmptyAnalytics);
						
						For Each TSRow In LinesOfDivergence Do
							TSRow.CorItemsLocationAttributes = TSRow.ItemsLocationAttributes;
						EndDo;
						
						InventoryLines = DocumentObject.InventoryOwnerAttributesGoodsReceipt.FindRows(SelectionOfEmptyAnalytics);
						
						For Each TSRow In InventoryLines Do
							TSRow.CorItemsLocationAttributes = TSRow.ItemsLocationAttributes;
						EndDo;
					EndIf;
					
					FillInCorOfInventoryLocationAttributeInInventoryTypesWriteOff(DocumentObject);
					
				EndIf;
				
				Query.SetParameter("Ref", DocumentObject.Ref);
				
				QueryResult = Query.Execute();
				
				If Not QueryResult.IsEmpty() Then
					NameStatusField = ?(SalesOfOperationsThroughCommissionAgent.Find(DocumentObject.BusinessOperation) = Undefined,
										"BatchesIndicationStatusInWarehouses",
										"BatchesIndicationStatusOfGoodsTransferred");
					
					Selection = QueryResult.Select();
					
					While Selection.Next() Do
						DivergenceLine = DocumentObject.Discrepancies[Selection.LineNumber - 1];
						DivergenceLine[NameStatusField] = DivergenceLine.BatchesIndicationStatus;
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

Procedure FillInCorOfInventoryLocationAttributeInInventoryTypesWriteOff(DocumentObject)
	
	InventoryKinds = DocumentObject.InventoryOwnerAttributesConsumption;
	
	If InventoryKinds.Count() = 0
		Or Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods) Then
		
		Return;
		
	EndIf;
	
	Discrepancies = DocumentObject.Discrepancies;
	
	SelectionOfEmptyAnalytics	= New Structure("CorItemsLocationAttributes",
											Catalogs.InventoryLocationAttributeKeys.EmptyRef());
	LinesOfDivergence	= Discrepancies.FindRows(SelectionOfEmptyAnalytics);
	
	If LinesOfDivergence.Count() = Discrepancies.Count() Then
		Return;
	EndIf;
	
	NamesOfGroupingColumns		= "ItemsLocationAttributes, SetAccountingDimension, Warehouse, Package, SalesOrder,
									|FEACNCode, ARAPObject, CorItemsLocationAttributes,
									|ExpenseItem, DimensionOfExpenses, AssetsLiabilitiesDimension, ToExpenseAs";
	NamesOfSummationColumns	= "Count, NumberOfPackages, AmountIncludingVAT, VATAmount, AmountARAP,
									|AmountExcludingVATCompl, AmountExcludingVATMan, VATAmountCompl, VATAmountMan";
	UnloadedColumns			= NamesOfGroupingColumns + ", " + NamesOfSummationColumns;

	GoodsTable = Discrepancies.UnloadColumns(UnloadedColumns);
	GoodsTable.Columns.Add("ToIncomeExpenses");
	
	ArrayOfReflectionOptions = New Array;
	ArrayOfReflectionOptions.Add(Enums.CreditNoteRecordingOptions.IncreaseSale);
	ArrayOfReflectionOptions.Add(Enums.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount);
	ArrayOfReflectionOptions.Add(Enums.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock);
	ArrayOfReflectionOptions.Add(Enums.CreditNoteRecordingOptions.RecordInOtherIncome);
	
	For Each LineOfDiscrepancies In Discrepancies Do
		ConsiderLine = False;
		
		For Each PostingOption In ArrayOfReflectionOptions Do
			If LineOfDiscrepancies.PostingOption = PostingOption Then
				ConsiderLine = True;
				
				Break;
			EndIf;
		EndDo;
		
		If ConsiderLine Then
			RowOfGoods = GoodsTable.Add();
			FillPropertyValues(RowOfGoods, LineOfDiscrepancies);
			
			If LineOfDiscrepancies.Count < 0 Then
				RowOfGoods.Count			= -LineOfDiscrepancies.Count;
				RowOfGoods.NumberOfPackages	= -LineOfDiscrepancies.NumberOfPackages;
				RowOfGoods.AmountARAP	= -LineOfDiscrepancies.AmountARAP;
				RowOfGoods.AmountExcludingVATCompl		= -LineOfDiscrepancies.AmountExcludingVATCompl;
				RowOfGoods.AmountExcludingVATMan		= -LineOfDiscrepancies.AmountExcludingVATMan;
				RowOfGoods.VATAmountCompl			= -LineOfDiscrepancies.VATAmountCompl;
				RowOfGoods.VATAmountMan			= -LineOfDiscrepancies.VATAmountMan;
			EndIf;
			
			RowOfGoods.ToIncomeExpenses =
				LineOfDiscrepancies.PostingOption = Enums.CreditNoteRecordingOptions.RecordInOtherIncome;
		EndIf;
		
	EndDo;
	
	NamesOfGroupingColumns = NamesOfGroupingColumns + ", " + "ToIncomeExpenses";
	
	GoodsTable.GroupBy(NamesOfGroupingColumns , NamesOfSummationColumns);
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	AnalyticsPropertiesToFillIn = "ItemsLocationAttributes, CorItemsLocationAttributes";
	
	For Each RowOfGoods In GoodsTable Do
		GoodsQuantity			= RowOfGoods.Count;
		NumberOfPackages			= RowOfGoods.NumberOfPackages;
		AmountOfMutualSettlementsOfGoods	= RowOfGoods.AmountARAP;
		AmountExcludingVATCompl				= RowOfGoods.AmountExcludingVATCompl;
		AmountExcludingVATMan				= RowOfGoods.AmountExcludingVATMan;
		
		TheStructureOfTheSearch.ItemsLocationAttributes = RowOfGoods.ItemsLocationAttributes;
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			FillPropertyValues(NewRow, RowOfGoods, AnalyticsPropertiesToFillIn);
			
			NewRow.Package				= RowOfGoods.Package;
			NewRow.SalesOrder			= RowOfGoods.SalesOrder;
			NewRow.ARAPObject			= RowOfGoods.ARAPObject;
			NewRow.FEACNCode				= RowOfGoods.FEACNCode;
			NewRow.ToIncomeExpenses			= RowOfGoods.ToIncomeExpenses;
			NewRow.SetAccountingDimension	= RowOfGoods.SetAccountingDimension;
			
			NewRow.ExpenseItem				= RowOfGoods.ExpenseItem;
			NewRow.DimensionOfExpenses			= RowOfGoods.DimensionOfExpenses;
			NewRow.AssetsLiabilitiesDimension	= RowOfGoods.AssetsLiabilitiesDimension;
			NewRow.ToExpenseAs			= RowOfGoods.ToExpenseAs;
			
			NewRow.NumberOfPackages		= ?(GoodsQuantity <> 0,
													NumberOfPackages * Count / GoodsQuantity,
													0);
			NewRow.Count				= Count;
			NewRow.QuantityByGBRN		= Count * InventoryLine.QuantityByGBRN
													/ InventoryLine.Count;
			NewRow.AmountIncludingVAT				= ?(InventoryLine.Count <> 0,
													Count * InventoryLine.AmountIncludingVAT / InventoryLine.Count,
													0);
			NewRow.VATAmount				= ?(InventoryLine.Count <> 0,
													Count * InventoryLine.VATAmount / InventoryLine.Count,
													0);
			NewRow.VATAmountCompl			= ?(InventoryLine.Count <> 0,
													Count * RowOfGoods.VATAmountCompl / InventoryLine.Count,
													0);
			NewRow.VATAmountMan				= ?(InventoryLine.Count <> 0,
													Count * RowOfGoods.VATAmountMan / InventoryLine.Count,
													0);
			NewRow.AmountARAP		= ?(GoodsQuantity <> 0,
													Count * AmountOfMutualSettlementsOfGoods / GoodsQuantity,
													0);
			NewRow.AmountExcludingVATCompl			= ?(GoodsQuantity <> 0,
													Count * AmountExcludingVATCompl / GoodsQuantity,
													0);
			NewRow.AmountExcludingVATMan			= ?(GoodsQuantity <> 0,
													Count * AmountExcludingVATMan / GoodsQuantity,
													0);
			
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.AmountIncludingVAT			= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			InventoryLine.VATAmount			= InventoryLine.VATAmount - NewRow.VATAmount;
			InventoryLine.VATAmountCompl		= InventoryLine.VATAmountCompl - NewRow.VATAmountCompl;
			InventoryLine.VATAmountMan		= InventoryLine.VATAmountMan - NewRow.VATAmountMan;
			
			GoodsQuantity			= GoodsQuantity - NewRow.Count;
			NumberOfPackages			= NumberOfPackages - NewRow.NumberOfPackages;
			AmountOfMutualSettlementsOfGoods	= AmountOfMutualSettlementsOfGoods - NewRow.AmountARAP;
			AmountExcludingVATCompl				= AmountExcludingVATCompl - NewRow.AmountExcludingVATCompl;
			AmountExcludingVATMan				= AmountExcludingVATMan - NewRow.AmountExcludingVATMan;
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	SearchParameters = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(SearchParameters);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf

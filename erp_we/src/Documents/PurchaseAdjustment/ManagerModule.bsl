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
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("ImportAccounting");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfWorks");
	DocumentMechanisms.Add("PreparationOfReportsToPurchasingCommittee");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("TransferToRecycling");
	PurchaseAdjustmentLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.PurchaseAdjustment") Then
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
		
		QueryTextTableReceivedReturnablePackaging(Query, QueryTexts, Registers);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers);
		QueryTextTableExpenseBatchesToGoodsCost(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers);
		QueryTextBatchesOfProductionCosts(Query, QueryTexts, Registers);
		QueryTextTablePurchases(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableGoodsAndServicesToRegisterPurchasingReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableDocumentCorrections(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
		PurchaseAdjustmentLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers);
	MakeAdjustmentsToGoodsOnTwoWayBasis(Query, QueryTexts, Registers);
	
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
	
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	PurchaseAdjustmentLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
	Documents.ReverseVATAccrual.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds the "receipt Adjustment" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.PurchaseAdjustment) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.PurchaseAdjustment.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.PurchaseAdjustment);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseDebitNotes";

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
	
	ReportCommand = Reports.DetailedCalculationOfDiscountingInterestExpenseAccrual.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm,DocumentsList";
	EndIf;
	
	ARAPAccountingServer.PaymentCardWithSupplier_AddDocumentReportCommand(ReportsCommands);
	ARAPAccountingServer.IndebtednessToSuppliers_AddDocumentReportCommand(ReportsCommands);
	
	PurchaseAdjustmentLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	PurchaseAdjustmentLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	Return ArrayOfNames
EndFunction

#Region FillType

// Fills in the table of details that depend on the type of base document.
//
// Parameters:
//	DocumentBasis - DocumentRef - The document on the basis of which the adjustment was made;
//	ArrayOfAllProps - Array of String - Bank details that do not depend on the base document;
//	ArrayOfOperationDetails - Array of String - Bank details that depend on the document-basis.
//	AdjustingEntryType - Undefined, EnumRef.AdjustingEntryTypes - type of adjustment before entering Balances.
//
Procedure FillInNamesOfDetailsOnBasis(DocumentBasis, ArrayOfAllProps, ArrayOfOperationDetails, AdjustingEntryType = Undefined) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("Warehouse");
	ArrayOfAllProps.Add("Terms");
	ArrayOfAllProps.Add("Contract");
	ArrayOfAllProps.Add("Goods.PartnerProducts");
	ArrayOfAllProps.Add("Goods.Products");
	ArrayOfAllProps.Add("Goods.Characteristic");
	ArrayOfAllProps.Add("Goods.Purpose");
	ArrayOfAllProps.Add("Goods.Content");
	ArrayOfAllProps.Add("Goods.Package");
	ArrayOfAllProps.Add("Goods.NumberOfPackages");
	ArrayOfAllProps.Add("Goods.Count");
	ArrayOfAllProps.Add("Goods.Price");
	ArrayOfAllProps.Add("Goods.Warehouse");
	ArrayOfAllProps.Add("Goods.PurchaseOrder");
	ArrayOfAllProps.Add("Goods.RowCode");
	ArrayOfAllProps.Add("Goods.CCDNumber");
	ArrayOfAllProps.Add("Goods.FEACNCode");
	ArrayOfAllProps.Add("Goods.SalesOpportunity");
	ArrayOfAllProps.Add("Goods.Series");
	ArrayOfAllProps.Add("Goods.BatchesIndicationStatus");
	ArrayOfAllProps.Add("Goods.ToExpenseAs");
	ArrayOfAllProps.Add("Goods.LineOfBusiness");
	ArrayOfAllProps.Add("Goods.CostGroupNumber");
	ArrayOfAllProps.Add("Goods.ProductCostElement");
	
	ArrayOfAllProps.Add("Discrepancies.Series");
	ArrayOfAllProps.Add("Discrepancies.Products");
	ArrayOfAllProps.Add("Discrepancies.Characteristic");
	ArrayOfAllProps.Add("Discrepancies.Purpose");
	ArrayOfAllProps.Add("Discrepancies.Content");
	ArrayOfAllProps.Add("Discrepancies.Package");
	ArrayOfAllProps.Add("Discrepancies.NumberOfPackages");
	ArrayOfAllProps.Add("Discrepancies.Warehouse");
	ArrayOfAllProps.Add("Discrepancies.PurchaseOrder");
	ArrayOfAllProps.Add("Discrepancies.RowCode");
	ArrayOfAllProps.Add("Discrepancies.CCDNumber");
	ArrayOfAllProps.Add("Discrepancies.FEACNCode");
	ArrayOfAllProps.Add("Discrepancies.SalesOpportunity");
	ArrayOfAllProps.Add("Discrepancies.ToExpenseAs");
	ArrayOfAllProps.Add("Discrepancies.LineOfBusiness");
	ArrayOfAllProps.Add("Discrepancies.CostGroupNumber");
	ArrayOfAllProps.Add("Discrepancies.ProductCostElement");
	
	ArrayOfOperationDetails = New Array;
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.VendorInvoice") Then
		
		ArrayOfOperationDetails.Add("Warehouse");
		ArrayOfOperationDetails.Add("Terms");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("Goods.PartnerProducts");
		ArrayOfOperationDetails.Add("Goods.Products");
		ArrayOfOperationDetails.Add("Goods.Characteristic");
		ArrayOfOperationDetails.Add("Goods.Purpose");
		ArrayOfOperationDetails.Add("Goods.Package");
		ArrayOfOperationDetails.Add("Goods.NumberOfPackages");
		ArrayOfOperationDetails.Add("Goods.Count");
		ArrayOfOperationDetails.Add("Goods.Warehouse");
		ArrayOfOperationDetails.Add("Goods.Price");
		ArrayOfOperationDetails.Add("Goods.PurchaseOrder");
		ArrayOfOperationDetails.Add("Goods.RowCode");
		ArrayOfOperationDetails.Add("Goods.CCDNumber");
		ArrayOfOperationDetails.Add("Goods.SalesOpportunity");
		ArrayOfOperationDetails.Add("Goods.Series");
		ArrayOfOperationDetails.Add("Goods.BatchesIndicationStatus");
		ArrayOfOperationDetails.Add("Goods.ToExpenseAs");
		ArrayOfOperationDetails.Add("Discrepancies.Series");
		ArrayOfOperationDetails.Add("Discrepancies.Products");
		ArrayOfOperationDetails.Add("Discrepancies.Characteristic");
		ArrayOfOperationDetails.Add("Discrepancies.Purpose");
		ArrayOfOperationDetails.Add("Discrepancies.Package");
		ArrayOfOperationDetails.Add("Discrepancies.NumberOfPackages");
		ArrayOfOperationDetails.Add("Discrepancies.Warehouse");
		ArrayOfOperationDetails.Add("Discrepancies.PurchaseOrder");
		ArrayOfOperationDetails.Add("Discrepancies.RowCode");
		ArrayOfOperationDetails.Add("Discrepancies.CCDNumber");
		ArrayOfOperationDetails.Add("Discrepancies.SalesOpportunity");
		ArrayOfOperationDetails.Add("Discrepancies.ToExpenseAs");
		
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		
		ArrayOfOperationDetails.Add("Terms");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("Goods.Content");
		ArrayOfOperationDetails.Add("Goods.LineOfBusiness");
		ArrayOfOperationDetails.Add("Goods.ToExpenseAs");
		ArrayOfOperationDetails.Add("Goods.Count");
		ArrayOfOperationDetails.Add("Goods.Price");
		ArrayOfOperationDetails.Add("Goods.CCDNumber");
		ArrayOfOperationDetails.Add("Goods.FEACNCode");
		ArrayOfOperationDetails.Add("Discrepancies.Content");
		ArrayOfOperationDetails.Add("Discrepancies.LineOfBusiness");
		ArrayOfOperationDetails.Add("Discrepancies.ToExpenseAs");
		ArrayOfOperationDetails.Add("Discrepancies.CCDNumber");
		ArrayOfOperationDetails.Add("Discrepancies.FEACNCode");
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.SubcontractorReport2_5") Then
		
		ArrayOfOperationDetails.Add("Contract");
		
		ArrayOfOperationDetails.Add("Goods.Products");
		ArrayOfOperationDetails.Add("Goods.Characteristic");
		ArrayOfOperationDetails.Add("Goods.Purpose");
		ArrayOfOperationDetails.Add("Goods.Count");
		ArrayOfOperationDetails.Add("Goods.Price");
		ArrayOfOperationDetails.Add("Goods.PurchaseOrder");
		ArrayOfOperationDetails.Add("Goods.RowCode");
		ArrayOfOperationDetails.Add("Goods.SalesOpportunity");
		ArrayOfOperationDetails.Add("Goods.ToExpenseAs");
		ArrayOfOperationDetails.Add("Goods.LineOfBusiness");
		ArrayOfOperationDetails.Add("Goods.CostGroupNumber");
		ArrayOfOperationDetails.Add("Goods.ProductCostElement");
		
		ArrayOfOperationDetails.Add("Discrepancies.Products");
		ArrayOfOperationDetails.Add("Discrepancies.Characteristic");
		ArrayOfOperationDetails.Add("Discrepancies.Purpose");
		ArrayOfOperationDetails.Add("Discrepancies.PurchaseOrder");
		ArrayOfOperationDetails.Add("Discrepancies.RowCode");
		ArrayOfOperationDetails.Add("Discrepancies.SalesOpportunity");
		ArrayOfOperationDetails.Add("Discrepancies.ToExpenseAs");
		ArrayOfOperationDetails.Add("Discrepancies.LineOfBusiness");
		ArrayOfOperationDetails.Add("Discrepancies.CostGroupNumber");
		ArrayOfOperationDetails.Add("Discrepancies.ProductCostElement");
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.SourceDocument") Then
		
		ArrayOfOperationDetails.Add("Terms");
		ArrayOfOperationDetails.Add("Contract");
		
		ArrayOfOperationDetails.Add("Goods.Count");
		ArrayOfOperationDetails.Add("Goods.Price");
		ArrayOfOperationDetails.Add("Goods.ToExpenseAs");
		
		ArrayOfOperationDetails.Add("Discrepancies.ToExpenseAs");
		
		If AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices Then
			ArrayOfOperationDetails.Add("Warehouse");
			
			ArrayOfOperationDetails.Add("Goods.PartnerProducts");
			ArrayOfOperationDetails.Add("Goods.Products");
			ArrayOfOperationDetails.Add("Goods.Characteristic");
			ArrayOfOperationDetails.Add("Goods.Purpose");
			ArrayOfOperationDetails.Add("Goods.Series");
			ArrayOfOperationDetails.Add("Goods.BatchesIndicationStatus");
			ArrayOfOperationDetails.Add("Goods.Package");
			ArrayOfOperationDetails.Add("Goods.NumberOfPackages");
			ArrayOfOperationDetails.Add("Goods.CCDNumber");
			ArrayOfOperationDetails.Add("Goods.Warehouse");
			
			ArrayOfOperationDetails.Add("Discrepancies.Products");
			ArrayOfOperationDetails.Add("Discrepancies.Characteristic");
			ArrayOfOperationDetails.Add("Discrepancies.Purpose");
			ArrayOfOperationDetails.Add("Discrepancies.Series");
			ArrayOfOperationDetails.Add("Discrepancies.Package");
			ArrayOfOperationDetails.Add("Discrepancies.NumberOfPackages");
			ArrayOfOperationDetails.Add("Discrepancies.CCDNumber");
			ArrayOfOperationDetails.Add("Discrepancies.Warehouse");
		Else
			ArrayOfOperationDetails.Add("Goods.Content");
			ArrayOfOperationDetails.Add("Goods.LineOfBusiness");
			ArrayOfOperationDetails.Add("Goods.CCDNumber");
			ArrayOfOperationDetails.Add("Goods.FEACNCode");
			
			ArrayOfOperationDetails.Add("Discrepancies.Content");
			ArrayOfOperationDetails.Add("Discrepancies.LineOfBusiness");
			ArrayOfOperationDetails.Add("Discrepancies.CCDNumber");
			ArrayOfOperationDetails.Add("Discrepancies.FEACNCode");
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the table part Products under the act of discrepancies
//
// Parameters:
// 	Object - DocumentObject.PurchaseAdjustment - The document to fill out.
//
Procedure FillInGoodsAccordingToCertificateOfDiscrepancies(Object) Export
	
	Object.Goods.Clear();
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	AcquisitionGoods.Ref                      AS Ref,
	|	AcquisitionGoods.LineNumber                 AS LineNumber,
	|	AcquisitionGoods.PartnerProducts        AS PartnerProducts,
	|	AcquisitionGoods.ItemsLocationAttributes  AS ItemsLocationAttributes,
	|	AcquisitionGoods.Purpose                  AS Purpose, 
	|	AcquisitionGoods.Package                    AS Package,
	|	AcquisitionGoods.Price                        AS Price,
	|	AcquisitionGoods.VATRate                   AS VATRate,
	|	AcquisitionGoods.PurchaseOrder             AS PurchaseOrder,
	|	AcquisitionGoods.RowCode                   AS RowCode,
	|	AcquisitionGoods.Warehouse                       AS Warehouse,
	|	AcquisitionGoods.Series                       AS Series,
	|	AcquisitionGoods.BatchesIndicationStatus         AS BatchesIndicationStatus,
	|	AcquisitionGoods.ToExpenseAs            AS ToExpenseAs,
	|	AcquisitionGoods.ExpenseItem              AS ExpenseItem,
	|	AcquisitionGoods.DimensionOfExpenses           AS DimensionOfExpenses,
	|	AcquisitionGoods.SalesOpportunity                      AS SalesOpportunity,
	|	AcquisitionGoods.Department               AS Department,
	|	AcquisitionGoods.CCDNumber                    AS CCDNumber,
	|
	|	SUM(AcquisitionGoods.Sum)                AS Sum,
	|	SUM(AcquisitionGoods.VATAmount)             AS VATAmount,
	|	SUM(AcquisitionGoods.AmountIncludingVAT)            AS AmountIncludingVAT,
	|	SUM(AcquisitionGoods.NumberOfPackages)   AS NumberOfPackages,
	|	SUM(AcquisitionGoods.Count)           AS Count,
	|	SUM(AcquisitionGoods.QuantityByGBRN)     AS QuantityByGBRN
	|INTO TTGoodsFull
	|FROM
	|	Document.VendorInvoice.Goods AS AcquisitionGoods
	|WHERE
	|	AcquisitionGoods.Ref = &DocumentBasis
	|GROUP BY
	|	AcquisitionGoods.Ref,
	|	AcquisitionGoods.LineNumber,
	|	AcquisitionGoods.PartnerProducts,
	|	AcquisitionGoods.ItemsLocationAttributes,
	|	AcquisitionGoods.Purpose,
	|	AcquisitionGoods.Package,
	|	AcquisitionGoods.Price,
	|	AcquisitionGoods.VATRate,
	|	AcquisitionGoods.PurchaseOrder,
	|	AcquisitionGoods.RowCode,
	|	AcquisitionGoods.Warehouse,
	|	AcquisitionGoods.Series,
	|	AcquisitionGoods.BatchesIndicationStatus,
	|	AcquisitionGoods.ToExpenseAs,
	|	AcquisitionGoods.ExpenseItem,
	|	AcquisitionGoods.DimensionOfExpenses,
	|	AcquisitionGoods.SalesOpportunity,
	|	AcquisitionGoods.Department,
	|	AcquisitionGoods.CCDNumber
	|
	|INDEX BY
	|	AcquisitionGoods.Ref,
	|	AcquisitionGoods.CCDNumber,
	|	AcquisitionGoods.Purpose,
	|	AcquisitionGoods.Series,
	|	AcquisitionGoods.PurchaseOrder,
	|	AcquisitionGoods.Warehouse,
	|	AcquisitionGoods.RowCode,
	|	AcquisitionGoods.ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref                     AS Ref,
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Goods.CCDNumber                   AS CCDNumber,
	|	Goods.Purpose                 AS Purpose,
	|	Goods.Series                      AS Series,
	|	Goods.PurchaseOrder            AS PurchaseOrder,
	|	Goods.Warehouse                      AS Warehouse,
	|	Goods.RowCode                  AS RowCode,
	|	SUM(Goods.Count)          AS Count,
	|	SUM(Goods.QuantityByGBRN)    AS QuantityByGBRN
	|INTO TTProducts_1
	|FROM
	|	TTGoodsFull AS Goods
	|GROUP BY
	|	Goods.Ref,
	|	Goods.ItemsLocationAttributes,
	|	Goods.CCDNumber,
	|	Goods.Purpose,
	|	Goods.Series,
	|	Goods.PurchaseOrder,
	|	Goods.Warehouse,
	|	Goods.RowCode
	|
	|INDEX BY
	|	Goods.Ref,
	|	Goods.CCDNumber,
	|	Goods.Purpose,
	|	Goods.Series,
	|	Goods.PurchaseOrder,
	|	Goods.Warehouse,
	|	Goods.RowCode,
	|	Goods.ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis             AS DocumentBasis,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.LineNumber                   AS LineNumber,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PartnerProducts          AS PartnerProducts,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products                  AS Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic                AS Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose                    AS Purpose, 
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Package                      AS Package,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Price                          AS Price,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VATRate                     AS VATRate,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder               AS PurchaseOrder,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.RowCode                     AS RowCode,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse                         AS Warehouse,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series                         AS Series,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatus           AS BatchesIndicationStatus,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.ToExpenseAs              AS ToExpenseAs,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.ExpenseItem                AS ExpenseItem,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DimensionOfExpenses             AS DimensionOfExpenses,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.SalesOpportunity                        AS SalesOpportunity,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Department                 AS Department,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CCDNumber                      AS CCDNumber,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action                      AS Action,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Sum                         AS Sum,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.SumByDocument              AS SumByDocument,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VATAmount                      AS VATAmount,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VATAmountByDocument           AS VATAmountByDocument,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.AmountIncludingVAT                     AS AmountIncludingVAT,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.AmountIncludingVATByDocument          AS AmountIncludingVATByDocument,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackages            AS NumberOfPackages,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument AS NumberOfPackagesByDocument,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count                    AS Count,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument         AS CountByDocument,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.FilledUsingBaseDocument          AS FilledUsingBaseDocument
	|INTO ReceiptDiscrepancyReportOfGoodsIsTTOut
	|	
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &DiscrepancyReportFollowingReceiptBaseDocument
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis = &DocumentBasis
	|
	|INDEX BY
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CCDNumber,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.RowCode,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.FilledUsingBaseDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.LineNumber            AS LineNumber,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PartnerProducts   AS PartnerProducts,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products           AS Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic         AS Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose             AS Purpose, 
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Package               AS Package,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Price                   AS Price,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VATRate              AS VATRate,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder        AS PurchaseOrder,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.RowCode              AS RowCode,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse                  AS Warehouse,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series                  AS Series,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatus    AS BatchesIndicationStatus,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.ToExpenseAs       AS ToExpenseAs,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.ExpenseItem         AS ExpenseItem,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DimensionOfExpenses      AS DimensionOfExpenses,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.SalesOpportunity                 AS SalesOpportunity,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Department          AS Department,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CCDNumber               AS CCDNumber,
	|
	|	CASE
	|		WHEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_))
	|			THEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Sum
	|		ELSE CertificateOfDiscrepanciesAfterAcceptanceOfGoods.SumByDocument
	|	END AS Sum,
	|
	|	CASE
	|		WHEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_))
	|			THEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VATAmount
	|		ELSE CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VATAmountByDocument
	|	END AS VATAmount,
	|
	|	CASE
	|		WHEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_))
	|			THEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.AmountIncludingVAT
	|		ELSE CertificateOfDiscrepanciesAfterAcceptanceOfGoods.AmountIncludingVATByDocument
	|	END AS AmountIncludingVAT,
	|
	|	CASE 
	|		WHEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses),VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.WaitForGoodsReceiptWithoutInvoices))
	|			THEN  CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument
	|		ELSE  CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackages
	|	END AS NumberOfPackages,
	|
	|	CASE 
	|		WHEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses),VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.WaitForGoodsReceiptWithoutInvoices))
	|			THEN  CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument
	|		ELSE  CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count
	|	END AS Count,
	|
	|	CASE 
	|		WHEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses),VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.WaitForGoodsReceiptWithoutInvoices))
	|			THEN ISNULL(AcquisitionGoods.QuantityByGBRN, 0)
	// Since it is impossible to take from the Purchase the amount of PST as it is,
	// then a call will be made to fill in this field by coefficients.
	|		ELSE 0
	|	END AS QuantityByGBRN,
	|
	|	CASE
	|		WHEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_))
	|				AND (CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackages > CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument
	|					OR CertificateOfDiscrepanciesAfterAcceptanceOfGoods.RowCode <> 0
	|						AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder IN (UNDEFINED, VALUE(Document.PurchaseOrder.EmptyRef)))
	|			THEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackages - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument
	|		ELSE 0
	|	END AS NumberOfPackagesOverOrder,
	|
	|	CASE
	|		WHEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices), VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_))
	|				AND (CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count > CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument
	|					OR CertificateOfDiscrepanciesAfterAcceptanceOfGoods.RowCode <> 0
	|						AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder IN (UNDEFINED, VALUE(Document.PurchaseOrder.EmptyRef)))
	|			THEN CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument
	|		ELSE 0
	|	END AS QuantityOverOrder
	|
	|FROM
	|	ReceiptDiscrepancyReportOfGoodsIsTTOut AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
	|	LEFT JOIN TTProducts_1 AS AcquisitionGoods
	|	ON CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis = AcquisitionGoods.Ref
	|		AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CCDNumber = AcquisitionGoods.CCDNumber
	|		AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose = AcquisitionGoods.Purpose
	|		AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series = AcquisitionGoods.Series
	|		AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder = AcquisitionGoods.PurchaseOrder
	|		AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse = AcquisitionGoods.Warehouse
	|		AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.RowCode = AcquisitionGoods.RowCode
	|		AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products = AcquisitionGoods.ItemsLocationAttributes.Products
	|		AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic = AcquisitionGoods.ItemsLocationAttributes.Characteristic
	|		AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose = AcquisitionGoods.ItemsLocationAttributes.Purpose
	|		AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.FilledUsingBaseDocument
	|
	|UNION ALL
	|
	|SELECT
	|	AcquisitionGoods.LineNumber                               AS LineNumber,
	|	AcquisitionGoods.PartnerProducts                      AS PartnerProducts,
	|	AcquisitionGoods.ItemsLocationAttributes.Products   AS Products,
	|	AcquisitionGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	AcquisitionGoods.ItemsLocationAttributes.Purpose     AS Purpose, 
	|	AcquisitionGoods.Package                                  AS Package,
	|	AcquisitionGoods.Price                                      AS Price,
	|	AcquisitionGoods.VATRate                                 AS VATRate,
	|	AcquisitionGoods.PurchaseOrder                           AS PurchaseOrder,
	|	AcquisitionGoods.RowCode                                 AS RowCode,
	|	AcquisitionGoods.Warehouse                                     AS Warehouse,
	|	AcquisitionGoods.Series                                     AS Series,
	|	AcquisitionGoods.BatchesIndicationStatus                       AS BatchesIndicationStatus,
	|	AcquisitionGoods.ToExpenseAs                          AS ToExpenseAs,
	|	AcquisitionGoods.ExpenseItem                            AS ExpenseItem,
	|	AcquisitionGoods.DimensionOfExpenses                         AS DimensionOfExpenses,
	|	AcquisitionGoods.SalesOpportunity                                    AS SalesOpportunity,
	|	AcquisitionGoods.Department                             AS Department,
	|	AcquisitionGoods.CCDNumber                                  AS CCDNumber,
	|	AcquisitionGoods.Sum                                     AS Sum,
	|	AcquisitionGoods.VATAmount                                  AS VATAmount,
	|	AcquisitionGoods.AmountIncludingVAT                                 AS AmountIncludingVAT,
	|	AcquisitionGoods.NumberOfPackages                        AS NumberOfPackages,
	|	AcquisitionGoods.Count                                AS Count,
	|	AcquisitionGoods.QuantityByGBRN                          AS QuantityByGBRN,
	|
	|	CASE
	|		WHEN AcquisitionGoods.RowCode = 0
	|			THEN AcquisitionGoods.NumberOfPackages
	|		ELSE 0
	|	END AS NumberOfPackagesOverOrder,
	|
	|	CASE
	|		WHEN AcquisitionGoods.RowCode = 0
	|			THEN AcquisitionGoods.Count
	|		ELSE 0
	|	END AS QuantityOverOrder
	|
	|FROM
	|	TTGoodsFull AS AcquisitionGoods
	|
	|WHERE
	| (AcquisitionGoods.Ref, AcquisitionGoods.ItemsLocationAttributes.Products, AcquisitionGoods.ItemsLocationAttributes.Characteristic,
	|	AcquisitionGoods.ItemsLocationAttributes.Purpose, AcquisitionGoods.Series, AcquisitionGoods.PurchaseOrder, AcquisitionGoods.RowCode)
	|	NOT IN (SELECT
	|			CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis,
	|			CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products,
	|			CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic,
	|			CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose,
	|			CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series,
	|			CertificateOfDiscrepanciesAfterAcceptanceOfGoods.PurchaseOrder,
	|			CertificateOfDiscrepanciesAfterAcceptanceOfGoods.RowCode
	|		FROM 
	|			ReceiptDiscrepancyReportOfGoodsIsTTOut AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods)
	|
	|ORDER BY
	|	LineNumber";
	
	Query.SetParameter("DiscrepancyReportFollowingReceiptBaseDocument", Object.DiscrepancyReportFollowingReceiptBaseDocument);
	Query.SetParameter("DocumentBasis", Object.DocumentBasis);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");

	RowsToProcess = New Array;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If (Selection.Count - Selection.QuantityOverOrder) > 0 Then
			
			NewLineProducts = Object.Goods.Add();
			FillPropertyValues(NewLineProducts, Selection);
			If Selection.QuantityOverOrder > 0 Then
				NewLineProducts.NumberOfPackages = Selection.NumberOfPackages - Selection.NumberOfPackagesOverOrder;
				NewLineProducts.Count         = Selection.Count - Selection.QuantityOverOrder;
				RowsToProcess.Add(NewLineProducts);
			EndIf;
			
		EndIf;
			
		If Selection.QuantityOverOrder > 0 Then
			
			AdditionalLineProducts = Object.Goods.Add();
			FillPropertyValues(AdditionalLineProducts, Selection);
			AdditionalLineProducts.NumberOfPackages = Selection.NumberOfPackagesOverOrder;
			AdditionalLineProducts.Count         = Selection.QuantityOverOrder;
			AdditionalLineProducts.RowCode          = 0;
			RowsToProcess.Add(AdditionalLineProducts);
			
		EndIf;
		
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(RowsToProcess, StructureOfActions, Object.Goods, CachedValues);

	If ValueIsFilled(Object.DocumentBasis)
		And TypeOf(Object.DocumentBasis) <> Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		
		// It is required to fill in the number of PRNPT only in those lines for which it was not possible to extract
		// The quantity of the certificate from the document of the acquirement of the services.
		FilterParameters = New Structure("QuantityByGBRN", 0);
		LinesToFillIn = Object.Goods.FindRows(FilterParameters);
		
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object,
												"Warehouse",
												True);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.Goods,
																						LinesToFillIn);
	EndIf;
	
	SeparatePurchaseOperations	= New Array;
	SeparatePurchaseOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	SeparatePurchaseOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	SeparatePurchaseOperations.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
	SeparatePurchaseOperations.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	SeparatePurchaseOperations.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
	
	BaseOperation = ?(ValueIsFilled(Object.DocumentBasis)
								And TypeOf(Object.DocumentBasis) = Type("DocumentRef.VendorInvoice"),
							Common.ObjectAttributeValue(Object.DocumentBasis, "BusinessOperation"),
							Enums.BusinessTransactions.EmptyRef());
	
	UninvoicedReceiptDocumentIsUsed = SeparatePurchaseOperations.Find(BaseOperation) <> Undefined;
	
	Object.FillInTheDiscrepancies(UninvoicedReceiptDocumentIsUsed);
	
EndProcedure

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,Date,DocumentBasis";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.PurchaseAdjustment";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, True);
	
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.EmptyRef());
	SeriesSpecificationParameters.LinkFields.Add("Warehouse");
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.Date = Object.Date;
	
	TheseAreGoodsInTransit = False;
	BusinessTransactionGoodsInTransitAndNonInvoicing = False;
	
	If ValueIsFilled(Object.DocumentBasis)
		And TypeOf(Object.DocumentBasis) <> Type("DocumentRef.SourceDocument") Then
		BusinessTransactionDocumentBasis = Common.ObjectAttributeValue(Object.DocumentBasis, "BusinessOperation");
		
		OperationsInTransit = New Array();
		OperationsInTransit.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
		OperationsInTransit.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
		OperationsInTransit.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
		
		NonInvoicingOperations = New Array();
		NonInvoicingOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
		NonInvoicingOperations.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
		
		BusinessTransactionGoodsInTransitAndNonInvoicing = OperationsInTransit.Find(BusinessTransactionDocumentBasis) <> Undefined
			Or NonInvoicingOperations.Find(BusinessTransactionDocumentBasis) <> Undefined;
		TheseAreGoodsInTransit = OperationsInTransit.Find(BusinessTransactionDocumentBasis) <> Undefined;
	EndIf;
	
	SeriesSpecificationParameters.QueryOptions.Insert("TheseAreGoodsInTransit", TheseAreGoodsInTransit);
	SeriesSpecificationParameters.QueryOptions.Insert("UninvoicedReceiptDocumentIsUsed", BusinessTransactionGoodsInTransitAndNonInvoicing);
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	Goods.Count,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL
	|			OR &UninvoicedReceiptDocumentIsUsed
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
	|		ELSE CASE
	|				WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|					AND &UninvoicedReceiptDocumentIsUsed
	|					THEN
	|						CASE
	|							WHEN ((ProductsToRequest.ProductKind.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries
	|										AND NOT &TheseAreGoodsInTransit)
	|									OR (ProductsToRequest.ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor)
	|										AND &TheseAreGoodsInTransit)
	|								THEN CASE
	|										WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 18
	|										ELSE 17
	|									END
	|								ELSE 0
	|						END
	|					ELSE 0
	|			END
	|	END AS BatchesIndicationStatusGoodsAtPartners
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|				INNER JOIN Catalog.Warehouses AS Warehouses
	|				ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|			ON (BatchAccountingPolicies.Warehouse = ProductsToRequest.Warehouse)
	|				AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.Warehouse = ProductsToRequest.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchesIndicationStatusGoodsAtPartners
	|		ELSE Statuses.BatchesIndicationStatus
	|	END AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	CASE
	|		WHEN &UninvoicedReceiptDocumentIsUsed
	|			THEN Statuses.BatchesIndicationStatusGoodsAtPartners
	|		ELSE Statuses.BatchesIndicationStatus
	|	END <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

Function ParametersForRegisteringInvoicesReceived(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	RegistrationParameters.Ref = Object.Ref;
	RegistrationParameters.Date = Object.Date;
	RegistrationParameters.Organization = Object.Organization;
	RegistrationParameters.Counterparty = Object.Counterparty;
	RegistrationParameters.VATTaxation = Object.VATTaxation;
	If Object.AdjustmentKind = Enums.BusinessTransactions.ErrorCorrection Then
		RegistrationParameters.ErrorCorrection = True;
	ElsIf Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties Then
		RegistrationParameters.AdjustmentUnderApprovalOfParties = True;
	EndIf;
	
	PurchaseEAEU = False;
	If ValueIsFilled(Object.DocumentBasis)
		And TypeOf(Object.DocumentBasis) <> Type("DocumentRef.SourceDocument") Then
		BusinessTransactionDocumentBasis = Common.ObjectAttributeValue(Object.DocumentBasis, "BusinessOperation");
		
		BusinessTransactionsProcurementInEAEUCountries = PurchasesServerCall.BusinessOperationsOnMain(
				PredefinedValue("Enum.BusinessTransactions.ImportFromEAEU"));
				
		BusinessTransactionsProcurementInEAEUCountries.Add(Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5);
				
		If BusinessTransactionsProcurementInEAEUCountries.Find(BusinessTransactionDocumentBasis) <> Undefined Then 
			PurchaseEAEU = True;
		EndIf;
		
	EndIf;
	
	RegistrationParameters.ImportOfGoodsFromCustomsUnion   = PurchaseEAEU;
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return PurchaseAdjustmentLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return PurchaseAdjustmentLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion
// Returns the structure of document processing order parameters
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	
// Returns:
// Structure - See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
//
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	If Form.Object.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices Then
		DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
		DocumentProcessingProcedure.NamesOfValueTablesForClearingIncorrectAssignments = "AdjustmentTable";
		TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType,LineNumber");
		DocumentProcessingProcedure.StringProcessingConditions.Insert("AdjustmentTable", TableOfConditions);
	Else
		DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
		DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Goods";
		TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType,RowCode");
		DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	EndIf;
	
	Return DocumentProcessingProcedure;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	// The Form of the formadocumentadocumentareferences
	
	// Needs for goods in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "AdjustmentTable.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "&AdjustmentTable.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "AdjustmentTable.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "AdjustmentTable.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "AdjustmentTable.Warehouse";
	DescriptionOfColumns.DataPaths.Recorder      = "RegistrarForSelectingAppointment";
	
	DescriptionOfColumns.PathToTabularSection = "AdjustmentTable";
	
	// The needs for work in the recipient department.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "AdjustmentTable.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "&AdjustmentTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "AdjustmentTable.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "AdjustmentTable.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "AdjustmentTable.Department";
	DescriptionOfColumns.DataPaths.Recorder      = "RegistrarForSelectingAppointment";
	
	DescriptionOfColumns.PathToTabularSection = "AdjustmentTable";
	
	// Form of the formadocument
	
	// Needs for goods in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.Goods.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Goods.Warehouse";
	
	// The needs for work in the recipient department.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.Goods.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.Goods.Department";
	
	Return FormTemplate;
	
EndFunction

// Returns parameters for setting up accounting accounts in the document.
// 
// Parameters:
// 		ParametersForAccessibility - Structure:
//		* BusinessOperation - EnumRef.BusinessTransactions - Business operation of the document
//		* DocumentBasis - DocumentRef - document Foundation.
// 	
// Returns:
// 	Array of See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_(ParametersForAccessibility) Export
	
	ParametersArray = New Array();
	
	AdjustingEntryType = Undefined;
	ParametersForAccessibility.Property("AdjustingEntryType", AdjustingEntryType);
	
	AdjustmentOfPurchaseOfOtherAssetServices = (TypeOf(ParametersForAccessibility.DocumentBasis) = Type("DocumentRef.VendorInvoiceServicesAndAssets"))
		Or AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
	
	#Region AssetAccountingAccount	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.GLAccountSettings = "AssetGLAccountsSettings";
	SetupParameters.Presentation = "TextSetUpRecordOfAssetsInComplAccounting";
	
	SetupParameters.ArticleType = "ExpenseItemItemType";
	
	SetupParameters.AvailabilityByOperation = True;
	
	SetupParameters.Organization = "Object.Organization";
	SetupParameters.AssetsLiabilitiesDimension = "DimensionOfAssets";

	SetupParameters.FormItems.Add("TextSetUpRecordOfAssetsInComplAccounting");
	SetupParameters.FormItems.Add("TextSetUpReflectionInReglAssetAccountingDebtAdjustment");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	#Region LiabilityAccount	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.GLAccountSettings = "LiabilitiesGLAccountsSettings";
	SetupParameters.Presentation = "TextSetUpRecordOfLiabilitiesInComplAccounting";
	
	SetupParameters.ArticleType = "IncomeItemItemType";
	SetupParameters.AssetAndLiabilityItem = "IncomeItem";
	
	SetupParameters.AvailabilityByOperation = True;
	
	SetupParameters.Organization = "Object.Organization";
	SetupParameters.AssetsLiabilitiesDimension = "DimensionLiabilities_";

	SetupParameters.FormItems.Add("TextSetUpRecordOfLiabilitiesInComplAccounting");
	SetupParameters.FormItems.Add("TextSetUpReflectionInReglAccountingOfLiabilitiesDebtAdjustment");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion

	#Region ProductsAccountingAccount	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object.Goods";
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	SetupParameters.ArticleType     = "ArticleType";
	
	SetupParameters.AvailabilityByOperation = AdjustmentOfPurchaseOfOtherAssetServices;
	SetupParameters.HideUnavailableInvoiceInRows = True;
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("GoodsAccountReglAccountingForAssetsLiabilities");

	ParametersArray.Add(SetupParameters);
	#EndRegion

	#Region AccountingDiscrepancies	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object.Discrepancies";
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	SetupParameters.ArticleType     = "ArticleType";
	
	SetupParameters.AvailabilityByOperation = AdjustmentOfPurchaseOfOtherAssetServices;
	SetupParameters.HideUnavailableInvoiceInRows = True;
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("DiscrepanciesInTheReglAccountForAssetsAndLiabilities");
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction

// Returns the account settings in the Purchase adjustment document before Balances are entered.
// 
// Parameters:
// 		ParametersForAccessibility - Structure:
//		* BusinessOperation - EnumRef.BusinessTransactions - Business operation of the document
//		* DocumentBasis - DocumentRef - document Foundation.
// 	
// Returns:
// 	Array of See GLAccountSettingsServer.SetupParameters
//
Function AccountSettingsAdjustmentBeforeEnteringBalances(ParametersForAccessibility) Export
	
	ParametersArray = New Array();
	
	AdjustmentOfPurchaseOfOtherAssetServices = ParametersForAccessibility.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
	
	#Region AssetAccountingAccount
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.GLAccountSettings = "AssetGLAccountsSettings";
	SetupParameters.Presentation = "TextSetUpRecordOfAssetsInComplAccounting";
	
	SetupParameters.ArticleType = "ExpenseItemItemType";
	
	SetupParameters.AvailabilityByOperation = True;
	
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
	
	SetupParameters.AvailabilityByOperation = True;
	
	SetupParameters.Organization = "Object.Organization";
	SetupParameters.AssetsLiabilitiesDimension = "DimensionLiabilities_";

	SetupParameters.FormItems.Add("TextSetUpRecordOfLiabilitiesInComplAccounting");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	#Region InvoiceAdjustmentTable	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "AdjustmentTable";
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	SetupParameters.ArticleType     = "ArticleType";
	
	SetupParameters.AvailabilityByOperation = AdjustmentOfPurchaseOfOtherAssetServices;
	SetupParameters.HideUnavailableInvoiceInRows = True;
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("TableOfAdjustmentsToLocalAccountOfAssetsLiabilities");
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction
// Returns parameters for selecting articles in the document.
//
// Parameters:
//	ParametersForDeterminingAvailability - Structure:
//		* BusinessOperation - EnumRef.BusinessTransactions - Business operation of the document (type of Correction)
//		* DocumentBasis - DocumentRef- The document Foundation
//		* DocumentDate - Date - Document date
//		* RecordInOtherIncome - Boolean
//		* ToExpenseAs - Boolean
//
// Returns:
//	Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions.
//
Function ItemsAndDimensionsSelectionParameters(ParametersForDeterminingAvailability) Export
	
	CheckArticlesAndDimension = True;
	ParametersForDeterminingAvailability.Property("CheckArticlesAndDimension", CheckArticlesAndDimension);
	
	AdjustingEntryType = Undefined;
	ParametersForDeterminingAvailability.Property("AdjustingEntryType", AdjustingEntryType);
	
	AdjustmentOfPurchaseOfOtherAssetServices = (TypeOf(ParametersForDeterminingAvailability.DocumentBasis) = Type("DocumentRef.VendorInvoiceServicesAndAssets"))
		Or AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
	ArrayOfSelectionParameters = New Array;
	
	#Region IncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object";
	ChoiceParameters.AssetRef = "IncomeItem";
	
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;	
	ChoiceParameters.AvailabilityByOperation = True;
	If (ParametersForDeterminingAvailability.Property("RecordInOtherIncome")
			And Not ParametersForDeterminingAvailability.RecordInOtherIncome) Then
		ChoiceParameters.AvailabilityByOperation = False;
	EndIf;
	ChoiceParameters.ArticleType = "IncomeItemItemType";

	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItemAdjustmentOfDebt");
		
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("RevenueAnalyticsDebtAdjustment");
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "DimensionLiabilities_";
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionLiabilities_");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AnalysisOfLiabilitiesAdjustmentOfDebt");
		
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;
	ChoiceParameters.AvailabilityByOperation = True;
	
	If (ParametersForDeterminingAvailability.Property("ToExpenseAs")
			And Not ParametersForDeterminingAvailability.ToExpenseAs) Then
		ChoiceParameters.AvailabilityByOperation = False;
	EndIf;
	ChoiceParameters.ArticleType = "ExpenseItemItemType";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.AssetRef.Add("ItemOfExpenditureAdjustmentOfArrears");
	
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("CostAnalysisDebtAdjustment");
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "DimensionOfAssets";
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionOfAssets");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetAnalyticsDebtAdjustment");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region GoodsIncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object.Goods";
	ChoiceParameters.AssetRef = "ExpenseItem";
	
	ChoiceParameters.ArticleType = "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.AssetRef.Add("GoodsExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("GoodsDimensionOfExpenses");
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = AdjustmentOfPurchaseOfOtherAssetServices;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("GoodsAssetsLiabilitiesDimension");
	
	ChoiceParameters.ChoosingIncomeItem = AdjustmentOfPurchaseOfOtherAssetServices;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("GoodsDimensionOfRevenue");
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	
	ChoiceParameters.AvailabilityByOperation = CheckArticlesAndDimension;
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region DiscrepanciesExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object.Discrepancies";
	ChoiceParameters.AssetRef = "ExpenseItem";
	
	ChoiceParameters.ArticleType = "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.AssetRef.Add("DiscrepanciesExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DiscrepanciesDimensionOfExpenses");
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = AdjustmentOfPurchaseOfOtherAssetServices;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DiscrepanciesAssetsLiabilitiesDimension");
	
	ChoiceParameters.ChoosingIncomeItem = AdjustmentOfPurchaseOfOtherAssetServices;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DiscrepanciesDimensionOfRevenue");
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	
	ChoiceParameters.AvailabilityByOperation = CheckArticlesAndDimension;
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	PurchaseAdjustmentLocalization.AddOptionsForSelectingArticlesAndAnalytics(ArrayOfSelectionParameters, ParametersForDeterminingAvailability);
	
	Return ArrayOfSelectionParameters;
	
EndFunction

// Returns parameters for selecting articles in the document for the adjustment form before entering Balances.
// 
// Parameters:
//	ParametersForDeterminingAvailability - Structure:
//		* BusinessOperation - EnumRef.BusinessTransactions - Business operation of the document (type of Correction)
//		* DocumentBasis - DocumentRef- document Foundation.
//		* DocumentDate - Date - document date.
//		* RecordInOtherIncome - Boolean - a sign of reflection on income.
//		* ToExpenseAs - Boolean - indicates whether it has been charged to expenses.
//		* AdjustingEntryType - EnumRef.AdjustingEntryTypes - type of document correction.
//
// Returns:
//	Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions.
//
Function ArticleAndAnalystSelectionParametersAdjustmentBeforeEnteringBalances(ParametersForDeterminingAvailability) Export
	
	AdjustmentOfPurchaseOfOtherAssetServices = ParametersForDeterminingAvailability.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
	
	ArrayOfSelectionParameters = New Array;
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("ThisIsObjectOnForm", True);
	
	#Region IncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object";
	ChoiceParameters.AssetRef = "IncomeItem";
	
	ChoiceParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;	
	ChoiceParameters.AvailabilityByOperation = True;
	If (ParametersForDeterminingAvailability.Property("RecordInOtherIncome")
			And Not ParametersForDeterminingAvailability.RecordInOtherIncome) Then
		ChoiceParameters.AvailabilityByOperation = False;
	EndIf;
	ChoiceParameters.ArticleType = "IncomeItemItemType";

	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
		
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "DimensionLiabilities_";
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionLiabilities_");
		
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	
	ChoiceParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;
	ChoiceParameters.AvailabilityByOperation = True;
	
	If (ParametersForDeterminingAvailability.Property("ToExpenseAs")
			And Not ParametersForDeterminingAvailability.ToExpenseAs) Then
		ChoiceParameters.AvailabilityByOperation = False;
	EndIf;
	ChoiceParameters.ArticleType = "ExpenseItemItemType";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "DimensionOfAssets";
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("DimensionOfAssets");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region AdjustmentTable
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "AdjustmentTable";
	ChoiceParameters.AssetRef = "ExpenseItem";
	
	ChoiceParameters.ArticleType = "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.AssetRef.Add("AdjustmentTableExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("AdjustmentTableDimensionOfExpenses");
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = AdjustmentOfPurchaseOfOtherAssetServices;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AdjustmentTableAssetsLiabilitiesDimension");
	
	ChoiceParameters.ChoosingIncomeItem = AdjustmentOfPurchaseOfOtherAssetServices;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("AdjustmentTableDimensionOfRevenue");
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	
	DetailsPresentations = New Structure;
	DetailsPresentations.Insert("ExpenseItem",				NStr("vi = 'Ghi giảm vào chi phí/tài sản';
																	|ru = 'Списать на расходы/активы';
																	|en = 'Incur as expenses/assets'; fa = 'منظور به‌عنوان هزینه/دارایی';
																	|it = 'Storna alla voce di spese/ alla voce di attività';
																	|pl = 'Rozchodować w rozchody/aktywa';
																	|tr = 'Gider/varlıklar olarak kaydet'"));
	DetailsPresentations.Insert("DimensionOfExpenses",			NStr("vi = 'Đối tượng phân tích chi phí';
																		|ru = 'Аналитика расходов';
																		|en = 'Expense dimension'; fa = 'بُعد هزینه';
																		|it = 'Analitica delle uscite';
																		|pl = 'Analityka kosztów';
																		|tr = 'Gider boyutu'"));
	DetailsPresentations.Insert("AssetsLiabilitiesDimension",	NStr("vi = 'Đối tượng phân tích';
																		|ru = 'Аналитика';
																		|en = 'Dimension'; fa = 'بُعد';
																		|it = 'Analitica';
																		|pl = 'Analityka';
																		|tr = 'Boyut'"));
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
	
	PurchaseAdjustmentLocalization.AddOptionsForSelectingArticlesAndAnalytics(ArrayOfSelectionParameters, ParametersForDeterminingAvailability);
	
	Return ArrayOfSelectionParameters;
	
EndFunction

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
	ThisIsAdjustmentOfPrimaryDocument = False;
	DocumentBasis = Undefined;
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"AdjustmentKind, AdjustingEntryType, DocumentBasis");
		ThisIsDebtAdjustment = 
			StructureFillingData.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated
			Or StructureFillingData.AdjustmentKind = Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated;
		ThisIsAdjustmentOfPrimaryDocument = StructureFillingData.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices
			Or StructureFillingData.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
		DocumentBasis = StructureFillingData.DocumentBasis;
	ElsIf FillingData <> Undefined Then
		ThisIsDebtAdjustment = 
			FillingData.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated
			Or FillingData.AdjustmentKind = Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated;
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
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	
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
	ParametersStructure.Partner                          = "Object.Partner";
	ParametersStructure.Counterparty                       = "Object.Counterparty";
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
	Else
		ParametersStructure.Contract                          = "Object.Contract";
	EndIf;
	// It is used to generate the analysis of the conduct and object of calculations.
	If ThisIsDebtAdjustment Then
		ParametersStructure.LineOfBusiness          = "";
	Else
		ParametersStructure.LineOfBusiness          = "Object.LineOfBusiness";
	EndIf;
	// The procedure for calculating the document.
	If ThisIsDebtAdjustment Then
		ParametersStructure.ARAPObjectSettings              = "";
	Else
		ParametersStructure.ARAPObjectSettings              = "Object.ARAPObjectSettings";
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
		// The name of the pm item containing the order.
		ParametersStructure.PropsNameTSOrder              = "";
	Else
		ParametersStructure.PathToTSData                    = "Object.Discrepancies";
		// The name of the details of the amount with VAT of the tabular part.
		ParametersStructure.PropsNameTSAmountWithVAT          = "AmountIncludingVAT";
		// The name of the pm item containing the order.
		ParametersStructure.PropsNameTSOrder              = "PurchaseOrder";
	EndIf;
	
	// The path to the tabular part of the payment decryption.
	// It is used in the function of offsetting payments, distribution of mutual settlements, distribution of payments.
	ParametersStructure.PathToTSDataPaymentDecryption  = "";
	
	// It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	If ThisIsDebtAdjustment Then
		ParametersStructure.Terms                   = "";
	Else
		ParametersStructure.Terms                   = "Object.Terms";
	EndIf;
	// They are used to determine the value of payments in currency and in the form of editing payment rules.
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.PaymentMethod                      = "Object.PaymentMethod";
	ParametersStructure.ForeignCurrencyTransaction                    = "";
	// It is used in the form of payment rules and for the selection of settlement objects in the decryption of the payment.
	ParametersStructure.PaymentID             = "";
	
	// The details for the object of calculations are used in conducting.
	If ThisIsDebtAdjustment Then
		// In this case, there is no need to generate a calculation object, it is selected in the tabular part of the document from the previously created ones.
		ParametersStructure.FinancialAccountingGroup           = "";
		ParametersStructure.ARAPObject                   = "";
		ParametersStructure.Department                    = "";
		ParametersStructure.Manager                         = "";
		ParametersStructure.IncomingDocumentNumber          = "";
		ParametersStructure.IncomingDocumentDate           = "";
		ParametersStructure.SourceDocumentName  = "";
	Else
		ParametersStructure.FinancialAccountingGroup           = "";
		ParametersStructure.ARAPObject                   = "Object.Discrepancies.ARAPObject";
		ParametersStructure.Department                    = "Object.Department";
		ParametersStructure.Manager                         = "Object.Manager";
		ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
		ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
		ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
	EndIf;
	
	// Used to determine the object of calculations.
	If ThisIsDebtAdjustment Then
		ParametersStructure.InvoiceForOrders               = "";
	Else
		ParametersStructure.InvoiceForOrders               = "Object.ReceiptUnderOrders";
	EndIf;
	
	// It is used when determining the default calculation order and the list of available orders to choose from.
	// Used to determine the object of calculations.
	ParametersStructure.OrderBase                   = ""; 
	
	// The name of the button that opens the Payment offset assistant for the current set of parameters.
	ParametersStructure.FormItems.PaymentSettlement                      = "";
	// The name of the table element of the form that displays the amount of settlements.
	// Used to set the conditional design.
	// It should be filled in if the document supports line-by-line manual editing of settlement amounts.
	If ThisIsDebtAdjustment Then
		ParametersStructure.FormItems.AmountOfTSSettlements      = "ARAPAdjustmentAmountARAP";
	Else
		ParametersStructure.FormItems.AmountOfTSSettlements      = "DiscrepanciesAmountARAP";
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
	ParametersStructure.PaymentSchedule                 = "";
	
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
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.VendorInvoice") Then
		ParametersStructure.ToReturnReusablePackage = "Object.DocumentBasis.ToReturnReusablePackage";
		ParametersStructure.PackageDepositIsRequired      = "Object.DocumentBasis.PackageDepositIsRequired";
	Else
		ParametersStructure.ToReturnReusablePackage = False;
		ParametersStructure.PackageDepositIsRequired = False;
	EndIf;
	
	ParametersStructure.TSP                          = "Object.Warehouse";

	
	Return ParametersStructure;
EndFunction

// Returns the structure of parameters for filling in the purchase VAT tax.
//
// Parameters:
//  Object - DocumentObject.PurchaseAdjustment,
//  		 Document link.The
//  		 adjustment of the acquisition, the given formstructure is the document according to which it is necessary to form parameters.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export

	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	
	If TypeOf(Object) = Type("DocumentObject.PurchaseAdjustment")
		Or TypeOf(Object) = Type("FormDataStructure") Then
		ObjectData = Object;
	ElsIf TypeOf(Object) = Type("DocumentRef.PurchaseAdjustment") Then
		ObjectData = Common.ObjectAttributesValues(Object, "Counterparty,Contract,BusinessOperation,Date");
	EndIf;
	
	FillParameters.Counterparty = ObjectData.Counterparty;
	FillParameters.Contract = ObjectData.Contract;
	FillParameters.Period  = ObjectData.Date;
	If Not ObjectData.BusinessOperation = Enums.BusinessTransactions.SubcontractorReportAdjustment Then
		FillParameters.PurchaseOfGoods = True;
		FillParameters.AcquisitionOfWorks   = True;
	EndIf;
	FillParameters.PurchaseOnArticles = True;
	
	Return FillParameters;
	
EndFunction

// Returns the structure of parameters for filling in the VAT activity type.
//
// Parameters:
//  Object  - DocumentObject.PurchaseAdjustment,
//  		 Document link.The
//  		 adjustment of the acquisition, the given formstructure is the document according to which it is necessary to form parameters.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export

	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.PurchaseOnArticles = True;
	
	Return FillParameters;

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
	|	AND((VALUETYPE(DocumentBasis) = TYPE(Document.VendorInvoiceServicesAndAssets)
	|		OR AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets))
	|	OR BusinessOperation = VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment)
	|	OR ValueAllowed(Warehouse)
	|	) ";

EndProcedure

// End StandardSubsystems.AccessManagement

// Returns a table with data before and after the adjustment.
//
// Parameters:
//  Object  - DocumentObject.PurchaseAdjustment,
//  		 Document link.Adjustment of acquisition,
//  		 dataformstructure - document of adjustment.
//  NumberOfPackagesIsUsed - Boolean - calculation of the price for quantity or for the number of packages
//
// Returns:
//  ValueTable - the data of the table part, as they are displayed to the user.
//
Function AdjustmentDataBeforeEnteringBalances(Object, NumberOfPackagesIsUsed = False) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	T.Products AS Products,
	|	T.PartnerProducts AS PartnerProducts,
	|	T.Purpose AS Purpose,
	|	T.Characteristic AS Characteristic,
	|	T.Content AS Content,
	|	T.Package AS Package,
	|	T.Series AS Series,
	|	T.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	T.Warehouse AS Warehouse,
	|	T.Department AS Department,
	|	T.ToExpenseAs AS ToExpenseAs,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.GLAccountSettings AS GLAccountSettings,
	|	T.CCDNumber AS CCDNumber,
	|	T.FEACNCode AS FEACNCode,
	|	T.Price AS Price,
	|	T.VATRate AS VATRate,
	|	T.NumberOfPackages AS NumberOfPackages,
	|	T.Count AS Count,
	|	T.QuantityByGBRN AS QuantityByGBRN,
	|	T.Sum AS Sum,
	|	T.VATAmount AS VATAmount,
	|	T.AmountIncludingVAT AS AmountIncludingVAT,
	|	T.AmountARAP AS AmountARAP,
	|	T.LineNumber AS LineNumber
	|INTO TTProducts_1
	|FROM
	|	&Goods AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Products AS Products,
	|	T.Purpose AS Purpose,
	|	T.Characteristic AS Characteristic,
	|	T.Content AS Content,
	|	T.Package AS Package,
	|	T.Series AS Series,
	|	T.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	T.Warehouse AS Warehouse,
	|	T.Department AS Department,
	|	T.ToExpenseAs AS ToExpenseAs,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.LineOfBusiness AS LineOfBusiness,
	|	T.GLAccountSettings AS GLAccountSettings,
	|	T.CCDNumber AS CCDNumber,
	|	T.FEACNCode AS FEACNCode,
	|	T.Price AS Price,
	|	T.VATRate AS VATRate,
	|	T.NumberOfPackages AS NumberOfPackages,
	|	T.Count AS Count,
	|	T.QuantityByGBRN AS QuantityByGBRN,
	|	T.Sum AS Sum,
	|	T.VATAmount AS VATAmount,
	|	T.AmountIncludingVAT AS AmountIncludingVAT,
	|	T.AmountARAP AS AmountARAP,
	|	T.LineNumber,
	|	T.PostingOption AS PostingOption
	|INTO TTDiscrepancies
	|FROM
	|	&Discrepancies AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Products AS Products,
	|	MAX(Table.PartnerProducts) AS PartnerProducts,
	|	Table.Characteristic AS Characteristic,
	|	Table.Content AS Content,
	|	Table.Purpose AS Purpose,
	|	Table.Package AS Package,
	|	Table.Series AS Series,
	|	Table.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Table.Warehouse AS Warehouse,
	|	Table.Department AS Department,
	|	Table.ToExpenseAs AS ToExpenseAs,
	|	Table.ExpenseItem AS ExpenseItem,
	|	Table.DimensionOfExpenses AS DimensionOfExpenses,
	|	Table.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	Table.LineOfBusiness AS LineOfBusiness,
	|	MAX(Table.InventoryOwnerAttribute) AS InventoryOwnerAttribute,
	|	MIN(Table.GLAccountSettings) AS GLAccountSettings,
	|	Table.CCDNumber AS CCDNumber,
	|	Table.FEACNCode AS FEACNCode,
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
	|	MAX(Table.LineNumber) AS LineNumber,
	|	MAX(Table.ReflectionOptionUpTo) AS OptionToReflectWriteOff,
	|	ISNULL(MAX(Table.ReflectionOptionAfter),MAX(Table.ReflectionOptionUpTo)) AS PostingOption
	|FROM
	|	(SELECT
	|		T.Products AS Products,
	|		MAX(T.PartnerProducts) AS PartnerProducts,
	|		T.Purpose AS Purpose,
	|		T.Characteristic AS Characteristic,
	|		T.Content AS Content,
	|		T.Package AS Package,
	|		T.Series AS Series,
	|		T.BatchesIndicationStatus AS BatchesIndicationStatus,
	|		T.Warehouse AS Warehouse,
	|		T.Department AS Department,
	|		T.ToExpenseAs AS ToExpenseAs,
	|		T.ExpenseItem AS ExpenseItem,
	|		T.DimensionOfExpenses AS DimensionOfExpenses,
	|		T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|		MAX(T.InventoryOwnerAttribute) AS InventoryOwnerAttribute,
	|		T.LineOfBusiness AS LineOfBusiness,
	|		MIN(T.GLAccountSettings) AS GLAccountSettings,
	|		T.CCDNumber AS CCDNumber,
	|		T.FEACNCode AS FEACNCode,
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
	|		MAX(T.LineNumber) AS LineNumber,
	|		MAX(DiscrepanciesBefore.PostingOption) AS ReflectionOptionUpTo,
	|		NULL AS ReflectionOptionAfter
	|	FROM
	|		(SELECT
	|			Goods.Products AS Products,
	|			Goods.PartnerProducts AS PartnerProducts,
	|			Goods.Purpose AS Purpose,
	|			Goods.Characteristic AS Characteristic,
	|			Goods.Content AS Content,
	|			Goods.Package AS Package,
	|			Goods.Series AS Series,
	|			Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|			Goods.Warehouse AS Warehouse,
	|			Goods.Department AS Department,
	|			Goods.ToExpenseAs AS ToExpenseAs,
	|			Goods.ExpenseItem AS ExpenseItem,
	|			Goods.DimensionOfExpenses AS DimensionOfExpenses,
	|			Goods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|			UNDEFINED AS InventoryOwnerAttribute,
	|			Goods.LineOfBusiness AS LineOfBusiness,
	|			Goods.GLAccountSettings AS GLAccountSettings,
	|			Goods.CCDNumber AS CCDNumber,
	|			Goods.FEACNCode AS FEACNCode,
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
	|			Goods.LineNumber AS LineNumber
	|		FROM
	|			TTProducts_1 AS Goods
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Discrepancies.Products,
	|			NULL,
	|			Discrepancies.Purpose,
	|			Discrepancies.Characteristic,
	|			Discrepancies.Content,
	|			Discrepancies.Package,
	|			Discrepancies.Series,
	|			Discrepancies.BatchesIndicationStatus,
	|			Discrepancies.Warehouse,
	|			Discrepancies.Department,
	|			Discrepancies.ToExpenseAs,
	|			Discrepancies.ExpenseItem,
	|			Discrepancies.DimensionOfExpenses,
	|			Discrepancies.AssetsLiabilitiesDimension,
	|			Discrepancies.InventoryOwnerAttribute,
	|			Discrepancies.LineOfBusiness,
	|			Discrepancies.GLAccountSettings,
	|			Discrepancies.CCDNumber,
	|			Discrepancies.FEACNCode,
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
	|			0
	|		FROM
	|			TTDiscrepancies AS Discrepancies) AS T
	|		LEFT JOIN TTDiscrepancies AS DiscrepanciesBefore
	|			ON DiscrepanciesBefore.Products = T.Products
	|			AND DiscrepanciesBefore.Purpose = T.Purpose
	|			AND DiscrepanciesBefore.Characteristic = T.Characteristic
	|			AND DiscrepanciesBefore.Content = T.Content
	|			AND DiscrepanciesBefore.Package = T.Package
	|			AND DiscrepanciesBefore.Series = T.Series
	|			AND DiscrepanciesBefore.BatchesIndicationStatus = T.BatchesIndicationStatus
	|			AND DiscrepanciesBefore.Warehouse = T.Warehouse
	|			AND DiscrepanciesBefore.Department = T.Department
	|			AND DiscrepanciesBefore.ToExpenseAs = T.ToExpenseAs
	|			AND DiscrepanciesBefore.ExpenseItem = T.ExpenseItem
	|			AND DiscrepanciesBefore.DimensionOfExpenses = T.DimensionOfExpenses
	|			AND DiscrepanciesBefore.AssetsLiabilitiesDimension = T.AssetsLiabilitiesDimension
	|			AND DiscrepanciesBefore.LineOfBusiness = T.LineOfBusiness
	|			AND DiscrepanciesBefore.CCDNumber = T.CCDNumber
	|			AND DiscrepanciesBefore.FEACNCode = T.FEACNCode
	|			AND DiscrepanciesBefore.VATRate = T.VATRate
	|
	|	GROUP BY
	|		T.Products,
	|		T.Purpose,
	|		T.Characteristic,
	|		T.Content,
	|		T.Package,
	|		T.Series,
	|		T.BatchesIndicationStatus,
	|		T.Warehouse,
	|		T.Department,
	|		T.ToExpenseAs,
	|		T.ExpenseItem,
	|		T.DimensionOfExpenses,
	|		T.AssetsLiabilitiesDimension,
	|		T.LineOfBusiness,
	|		T.GLAccountSettings,
	|		T.CCDNumber,
	|		T.FEACNCode,
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
	|		Goods.PartnerProducts,
	|		Goods.Purpose,
	|		Goods.Characteristic,
	|		Goods.Content,
	|		Goods.Package,
	|		Goods.Series,
	|		Goods.BatchesIndicationStatus,
	|		Goods.Warehouse,
	|		Goods.Department,
	|		Goods.ToExpenseAs,
	|		Goods.ExpenseItem,
	|		Goods.DimensionOfExpenses,
	|		Goods.AssetsLiabilitiesDimension,
	|		UNDEFINED,
	|		Goods.LineOfBusiness,
	|		Goods.GLAccountSettings,
	|		Goods.CCDNumber,
	|		Goods.FEACNCode,
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
	|		Goods.LineNumber,
	|		NULL AS ReflectionOptionUpTo,
	|		DiscrepanciesAfter.PostingOption AS ReflectionOptionAfter
	|	FROM
	|		TTProducts_1 AS Goods
	|		LEFT JOIN TTDiscrepancies AS DiscrepanciesAfter
	|			ON DiscrepanciesAfter.Products = Goods.Products
	|			AND DiscrepanciesAfter.Purpose = Goods.Purpose
	|			AND DiscrepanciesAfter.Characteristic = Goods.Characteristic
	|			AND DiscrepanciesAfter.Content = Goods.Content
	|			AND DiscrepanciesAfter.Package = Goods.Package
	|			AND DiscrepanciesAfter.Series = Goods.Series
	|			AND DiscrepanciesAfter.BatchesIndicationStatus = Goods.BatchesIndicationStatus
	|			AND DiscrepanciesAfter.Warehouse = Goods.Warehouse
	|			AND DiscrepanciesAfter.Department = Goods.Department
	|			AND DiscrepanciesAfter.ToExpenseAs = Goods.ToExpenseAs
	|			AND DiscrepanciesAfter.ExpenseItem = Goods.ExpenseItem
	|			AND DiscrepanciesAfter.DimensionOfExpenses = Goods.DimensionOfExpenses
	|			AND DiscrepanciesAfter.AssetsLiabilitiesDimension = Goods.AssetsLiabilitiesDimension
	|			AND DiscrepanciesAfter.LineOfBusiness = Goods.LineOfBusiness
	|			AND DiscrepanciesAfter.CCDNumber = Goods.CCDNumber
	|			AND DiscrepanciesAfter.FEACNCode = Goods.FEACNCode
	|			AND DiscrepanciesAfter.VATRate = Goods.VATRate
	|		) AS Table
	|
	|GROUP BY
	|	Table.Products,
	|	Table.Purpose,
	|	Table.Characteristic,
	|	Table.Content,
	|	Table.Package,
	|	Table.Series,
	|	Table.BatchesIndicationStatus,
	|	Table.Warehouse,
	|	Table.Department,
	|	Table.ToExpenseAs,
	|	Table.ExpenseItem,
	|	Table.DimensionOfExpenses,
	|	Table.AssetsLiabilitiesDimension,
	|	Table.LineOfBusiness,
	|	Table.CCDNumber,
	|	Table.FEACNCode
	|
	|ORDER BY
	|	LineNumber";
	
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
//  AdjustmentOfPurchaseOfOtherAssetServices - Boolean - adjustment of services and other assets
//
// Returns:
//  String - list of communication Attributes.
//
Function KeyAttributesOFRelationshipOfTableRows(AdjustmentOfPurchaseOfOtherAssetServices) Export
	
	If AdjustmentOfPurchaseOfOtherAssetServices Then
		KeyAttributes = "Content,Department,ExpenseItem,DimensionOfExpenses";
	Else
		KeyAttributes = "Products,Characteristic,Purpose,Series,Package,Warehouse,CCDNumber,ExpenseItem,DimensionOfExpenses,Department";
	EndIf;
	
	Return KeyAttributes;

EndFunction

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

#Region Print

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Structure - composition of properties See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand.
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.ReceiptOperation	= True;
	JobPrintingRules.AdjustmentOfGoods	= True;
	JobPrintingRules.VHFWarehouses				= True;
	JobPrintingRules.NameTSGoods			= "Discrepancies";
	
	Return JobPrintingRules;
	
EndFunction

#EndRegion

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

// Function constructor of procedure parameters correctabledocument
// 
// Returns:
// 	Structure - LongDesc:
// * CorrectedDocument - DocumentRef.VendorInvoice
// * DocumentBasis - DocumentRef.VendorInvoice
// * Date - Date
// * AdjustmentKind - EnumRef.BusinessTransactions
//
Function ParametersForGettingDocumentBeingCorrected() Export
	
	Parameters = New Structure;
	Parameters.Insert("CorrectedDocument", Documents.VendorInvoice.EmptyRef());
	Parameters.Insert("DocumentBasis", Documents.VendorInvoice.EmptyRef());
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
	Query.SetParameter("BusinessOperation", DocumentAttributes.AdjustmentKind);
	
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

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.GoodsReceiptNote, DocumentRef.GoodsReceiptNote - Document.
//  FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	ObjectAttributes = QualityControl.AttributesOfItemOrLink(ObjectOrRef,
		"DocumentBasis");
	
	ManagerOfDocument = Common.ObjectManagerByRef(ObjectAttributes.DocumentBasis);
		Attributes = ManagerOfDocument.AttributesOfControlledLotReference(
			ObjectAttributes.DocumentBasis,
			FieldNameControlledLotReference);
	
	Return Attributes;
	
EndFunction

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.PurchaseAdjustment - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	DateOfReceipt = InvoicesServer.DateOfReceipt(Undefined, Object.Date, True);
	ContractRequired = QualityControl.ControlMayBeDeterminedByContract(Object.BusinessOperation);
	QualityControlReset = Object.AdjustingEntryType <> Enums.AdjustingEntryTypes.StandardAdjustment
			Or Object.BusinessOperation = Enums.BusinessTransactions.SubcontractorReportAdjustment;
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	
	ActionParameters.ReadableFields = "Products,Warehouse,ToExpenseAs,PostingOption";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.QueryOptions.QualityControlContract = ?(ContractRequired, Object.Contract, Undefined);
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = DateOfReceipt;
	ActionParameters.QueryOptions.Insert("QualityControlReset", QualityControlReset);
	
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	Table.Warehouse AS Warehouse,
		|	&QualityControlContract AS Contract,
		|	&QualityControlDateOfReceipt AS DateOfReceipt,
		|	FALSE AS Set,
		|	Table.ToExpenseAs
		|	OR Table.PostingOption IN(
		|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome),
		|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs),
		|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost),
		|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost)) AS Reset
		|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products,Warehouse,Contract";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
EndFunction


#Region CheckingCompletionOfDocumentBeforeEnteringBalance

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
	
	UseVATAccounting = GetFunctionalOption("UseVATAccounting")
							And Object.VATTaxation <> Enums.VATTaxationTypes.EmptyRef()
							And Object.VATTaxation <> Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES =
		Object.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices;
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	QueryTexts = New Array;
	QueryTexts.Add(QueryTextTTTablesOfGoods());
	QueryTexts.Add(QueryTextTTFoundationDocumentData());
	QueryTexts.Add(QueryTextTTPreviousAdjustmentData());
	QueryTexts.Add(QueryTextTTToCheckDataForLastAdjustment());
	
	RequestVerificationTexts = New Array;
	RequestVerificationTexts.Add(QueryTextCheckingFillingOfWarehouse());
	RequestVerificationTexts.Add(QueryTextChecksForFillingInProductListAndContent());
	RequestVerificationTexts.Add(QueryTextChecksForFillingInCharacteristics());
	RequestVerificationTexts.Add(QueryTextCheckingFillingOfQuantity());
	RequestVerificationTexts.Add(QueryTextChecksForFillingInSummaryIndicators());
	RequestVerificationTexts.Add(QueryTextChecksForFillingInVATRates());
	RequestVerificationTexts.Add(QueryTextCheckingReflectionOptions());
	RequestVerificationTexts.Add(QueryTextCheckingFillingOfWarehouseInTabularPart());
	RequestVerificationTexts.Add(QueryTextChecksTypeOfAdjustmentDoesNotMatchPreviousOne());
	
	RequestVerificationTexts.Add(QueryTextChecksVATTaxationCorrespondsToBasis());
	RequestVerificationTexts.Add(QueryTextChecksOrganizationCorrespondsToFoundation());
	RequestVerificationTexts.Add(QueryTextPartnerChecksMatchFoundation());
	RequestVerificationTexts.Add(QueryTextChecksCounterpartyCorrespondsToBasis());
	RequestVerificationTexts.Add(QueryTextVerificationContractCorrespondsToBasis());
	RequestVerificationTexts.Add(QueryTextChecksOrderOfCalculationsCorrespondsToBase());
	
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
	
	Query.SetParameter("Ref",					 Object.Ref);
	Query.SetParameter("Date",					 ?(ValueIsFilled(Object.Ref), Object.Date, CurrentSessionDate()));
	Query.SetParameter("DocumentBasis",		 Object.DocumentBasis);
	Query.SetParameter("VATTaxation",		 Object.VATTaxation);
	Query.SetParameter("Organization",			 Object.Organization);
	Query.SetParameter("Partner",				 Object.Partner);
	Query.SetParameter("Counterparty",				 Object.Counterparty);
	Query.SetParameter("Contract",				 Object.Contract);
	Query.SetParameter("ARAPObjectSettings",		 Object.ARAPObjectSettings);
	Query.SetParameter("Warehouse",					 Object.Warehouse);
	Query.SetParameter("AdjustingEntryType",		 Object.AdjustingEntryType);
	Query.SetParameter("TableOfGoods",			 VTAdjustmentTable);
	Query.SetParameter("UseVATAccounting",	 UseVATAccounting);
	Query.SetParameter("UseSeveralWarehouses",
								UseSeveralWarehouses);
	Query.SetParameter("UseItemVariants",
								UseItemVariants);
	Query.SetParameter("ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES",
								ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES);
	Query.SetParameter("UseTraceableImportedGoodsAccounting",
								UseTraceableImportedGoodsAccounting);
	
	ResultsPackage = Query.ExecuteBatch();
	
	SamplingOfLoggingErrors = ResultsPackage[ResultsPackage.Count()-2].Select();
	SelectionOfErrorsAlongCorrectionChain = ResultsPackage[ResultsPackage.Count()-1].Select();
	
	Report_FillingErrors(SamplingOfLoggingErrors, Cancel);
	ReportErrorsAlongCorrectionChain(SelectionOfErrorsAlongCorrectionChain, Cancel);
	
	CheckParameters = ProductsServer.SeriesFillCheckParameters();
	CheckParameters.PresentationOfTS			= PresentationOfTS;
	CheckParameters.PropsNameSeries			= "Series";
	CheckParameters.PathToFormTableData	= "";
	
	ProductsServer.CheckSeriesCompletion(Form,
												Form.SeriesSpecificationParameters,
												Cancel,
												Undefined,
												CheckParameters);
	
	ThisIsTraceableDocument = AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(
									VTAdjustmentTable, Object.Date);
	
	If (ThisIsTraceableDocument
			Or GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers"))
		And Object.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices Then
		
		CheckParameters = InventoriesServer.ParametersForCheckingFillingInOfCCDNumbers();
		CheckParameters.TSName				= TSName;
		CheckParameters.PresentationOfTS	= PresentationOfTS;
		CheckParameters.CheckWorks	= True;
		
		InventoriesServer.CheckFillingOfCCDNumbers(Form, Cancel, CheckParameters);
		
		AccountingForTraceableGoodsLocalization.CheckTraceabilityDataOfCCDNumbers(
			Form, VTAdjustmentTable, Object.Date, "AdjustmentTable");
		
	EndIf;
	
	If ThisIsTraceableDocument Then
		AccountingForTraceableGoodsLocalization.CheckCorrectSettingsOfRNPTProducts(
			Form, VTAdjustmentTable, Object.Date);
	EndIf;
	
	If UseVATAccounting Then
		CheckIndicationOfAmountAndAmountOfVAT(Object, TempTablesManager, Cancel);
	EndIf;
	
	ItemsTypes = New Array;
	ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
	ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
	ItemsTypes.Add(Enums.ItemsTypes.OperationService);
	ItemsTypes.Add(Enums.ItemsTypes.Work_5);
	
	MessageText = NStr("vi = 'Chưa chỉ ra người nhận hàng hóa/công việc/dịch vụ trong dòng %1 danh sách ""%2""';
						|ru = 'Не указан получатель товаров/работ/услуг в строке %1 списка ""%2""';
						|en = 'Recipient of goods/works/services is not specified in line %1 of the %2 list'; fa = 'Recipient of goods/works/services is not specified in line %1 of the %2 list';
						|it = 'Non è indicato il destinatario di merci/lavori/servizi nella riga %1 dell''elenco ""%2""';
						|pl = 'Nie jest podany odbiorca towarów/prac/usług w wierszu %1 listy ""%2""';
						|tr = 'Malların/işlerin/hizmetlerin alıcısı ""%2"" listesinin %1satırında belirtilmemiştir '");
	MessageText = StrReplace(MessageText, "%2", PresentationOfTS);
	
	InventoriesServer.CheckFillingOfDivisionInTablePart(Form,
																ItemsTypes,
																MessageText,
																Cancel,
																"AdjustmentTable");
	
	AdditionalVerifiableAttributes = New Array;
	AdditionalVerifiableAttributes.Add("AdjustmentTable.DimensionOfExpenses");
	
	CommonClientServer.SupplementArray(CheckedAttributes, AdditionalVerifiableAttributes);
	
	CheckResult = ResultsOfDiscrepancyCheck(VTAdjustmentTable);
	
	OptionsForSelection = New Structure;
	OptionsForSelection.Insert("DocumentDate",			Object.Date);
	OptionsForSelection.Insert("DocumentBasis",		Object.DocumentBasis);
	OptionsForSelection.Insert("BusinessOperation",	Object.AdjustmentKind);
	OptionsForSelection.Insert("AdjustingEntryType",			Object.AdjustingEntryType);
	OptionsForSelection.Insert("RecordInOtherIncome",	CheckResult.AmountForOtherIncome > 0);
	OptionsForSelection.Insert("ToExpenseAs",			CheckResult.AmountForOtherExpenses > 0);
	
	ItemsAndDimensionsSelectionParameters = ArticleAndAnalystSelectionParametersAdjustmentBeforeEnteringBalances(OptionsForSelection);
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

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	If Data.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices
		Or Data.AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets Then
		DocumentNamePostfix = NStr("vi = 'Điều chỉnh mua hàng trước khi nhập số dư';
									|ru = 'Корректировка приобретения до ввода остатков';
									|en = 'Purchase adjustment before balance entry'; fa = 'تعدیل خرید قبل از ورود مانده';
									|it = 'Correzione di acquisizione prima dell''inserimento dei saldi';
									|pl = 'Korekta nabycia przed wprowadzeniem sald';
									|tr = 'Bakiyeleri girmeden önce satın alma düzeltmesi'");
	ElsIf Data.BusinessOperation = Enums.BusinessTransactions.SubcontractorReportAdjustment Then
		DocumentNamePostfix = NStr("vi = 'Điều chỉnh bảng kê của bên nhận gia công';
									|ru = 'Корректировка отчета переработчика';
									|en = 'Adjust subcontracting services notification received'; fa = 'Adjust subcontracting services notification received';
									|it = 'Rettifica report elaboratore';
									|pl = 'Korekta raportu przetwórcy';
									|tr = 'Fason üretici raporunun düzenlenmesi'");
	Else
		DocumentNamePostfix = NStr("vi = 'Điều chỉnh mua hàng';
									|ru = 'Корректировка приобретения';
									|en = 'Purchase adjustment'; fa = 'تعدیل خرید';
									|it = 'Rettifica acquisizione';
									|pl = 'Korekta zakupu';
									|tr = 'Satın alma düzeltmesi'");
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
	
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "PurchaseAdjustment");
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Clear();
	Fields.Add("BusinessOperation");
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("Date");
	Fields.Add("Number");
	Fields.Add("AdjustingEntryType");
	
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

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.SetParameter("SeparatePurchaseOperations", PurchasesServer.EconomicOperationsOfSeparatePurchaseWithoutSelections());
	Query.Text =
	"SELECT
	|	DocumentData.Ref                                                              AS Ref,
	|	DocumentData.Date                                                                AS Period,
	|	DocumentData.IncomingDocumentDate                                              AS IncomingDocumentDate,
	|	DocumentData.Number                                                               AS Number,
	|	DocumentData.IncomingDocumentNumber                                             AS IncomingDocumentNumber,
	|	DocumentData.ExternalDocumentName                                      AS ExternalDocumentName,
	|	DocumentData.DocumentBasis                                                   AS DocumentBasis,
	|	ISNULL(DocumentData.DocumentBasis.Date, DATETIME(1,1,1))                  AS ReceiptPeriod,
	|	ISNULL(DocumentData.DocumentBasis.Date, DATETIME(1,1,1))                  AS AdjustmentPeriod_,
	|	DocumentData.PurchaseForActivity                                              AS PurchaseForActivity,
	|	DocumentData.Organization                                                         AS Organization,
	|	DocumentData.Organization.ParentCompany                                     AS ParentCompany,
	|	DocumentData.VATTaxation                                                  AS VATTaxation,
	|	DocumentData.Partner                                                             AS Partner,
	|	DocumentData.Counterparty                                                          AS Counterparty,
	|	DocumentData.Department                                                       AS Department,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods, VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.SalesOpportunity                                                              AS SalesOpportunity,
	|	ISNULL(DocumentData.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE)              AS EnabledGoodsAssignmentInSalesOpportunity,
	|	CASE
	|		WHEN DocumentData.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|		THEN DocumentData.ExpenseItem
	|		ELSE UNDEFINED
	|	END AS ExpenseItem,
	|	ISNULL(DocumentData.ExpenseItem.CostAllocationOptionLocal, UNDEFINED) AS CostAllocationOptionLocal,
	|	ISNULL(DocumentData.ExpenseItem.SeparateVATAccountingOption, UNDEFINED)   AS SeparateVATAccountingOption,
	|	DocumentData.DimensionOfExpenses                                                   AS DimensionOfExpenses,
	|	CASE
	|		WHEN DocumentData.IncomeItem REFS ChartOfCharacteristicTypes.IncomeItems
	|		THEN DocumentData.IncomeItem
	|		ELSE UNDEFINED
	|	END AS IncomeItem,
	|	DocumentData.DimensionOfRevenue                                                    AS DimensionOfRevenue,
	|	CASE
	|		WHEN DocumentData.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|		THEN DocumentData.ExpenseItem
	|		ELSE UNDEFINED
	|	END AS AssetItem,
	|	CASE
	|		WHEN DocumentData.IncomeItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|		THEN DocumentData.IncomeItem
	|		ELSE UNDEFINED
	|	END AS LiabilityItem,
	|	CASE
	|		WHEN DocumentData.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|		THEN DocumentData.ExpenseItem.AssetLiability
	|		ELSE UNDEFINED
	|	END AS AssetItemAssetLiability,
	|	CASE
	|		WHEN DocumentData.IncomeItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|		THEN DocumentData.IncomeItem.AssetLiability
	|		ELSE UNDEFINED
	|	END AS ArticleOfLiabilitiesAssetLiability,
	|	DocumentData.DimensionOfAssets                                                    AS DimensionOfAssets,
	|	DocumentData.DimensionLiabilities_                                                   AS DimensionLiabilities_,
	|	DocumentData.ARAPCurrency                                                AS ARAPCurrency,
	|	DocumentData.Currency                                                              AS Currency,
	|	DocumentData.AdjustingEntryType                                                    AS AdjustingEntryType,
	|	DocumentData.CorrectedDocument                                                AS CorrectedDocument,
	|	DocumentData.ReceiptUnderOrders                                                AS ReceiptUnderOrders,
	|	DocumentData.PaymentDate                                                         AS PaymentDate,
	|	DocumentData.PaymentMethod                                                         AS PaymentMethod,
	|	DocumentData.Contract                                                             AS Contract,
	|	CASE
	|		WHEN DocumentData.DocumentBasis REFS Document.VendorInvoice
	|			THEN CASE
	|				WHEN ISNULL(DocumentData.DocumentBasis.BusinessOperation, UNDEFINED) IN
	|						(VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|						VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|						VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|						VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|		ELSE FALSE
	|	END                                                                               AS UninvoicedReceiptDocumentIsUsed,
	|	DocumentData.DocumentBasis REFS Document.VendorInvoiceServicesAndAssets	AS DocumentPurchaseOfServicesOtherAssetsIsUsed,
	|	DocumentData.Terms                                                          AS Terms,
	|	ISNULL(DocumentData.Terms.GoodsReceiptOption, VALUE(Enum.GoodsReceiptOptions.EmptyRef)) AS GoodsReceiptOption,
	|	DocumentData.AdjustmentKind                                                    AS BusinessOperation,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment)
	|			THEN VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment)
	|		WHEN DocumentData.DocumentBasis REFS Document.SourceDocument
	|			THEN VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|		ELSE ISNULL(DocumentData.DocumentBasis.BusinessOperation, VALUE(Enum.BusinessTransactions.PurchaseFromSupplier))
	|	END                                                                               AS BusinessTransactionGrounds,
	|	FALSE 																				AS ProductionAtProcessorInEAEUCountries,
	|	CASE
	|		WHEN DocumentData.DocumentBasis REFS Document.VendorInvoice
	|       	THEN CAST(DocumentData.DocumentBasis AS Document.VendorInvoice).NewWayToCreateApplicationForGoodsImportFromEAEU
	|       ELSE
	|   		FALSE
	|	END                                                                               AS NewWayToCreateApplicationForGoodsImportFromEAEU,
	|	CASE
	|		WHEN
	|			DocumentData.DocumentBasis REFS Document.VendorInvoice
	|		THEN
	|			DocumentData.DocumentBasis.ToReturnReusablePackage
	|		ELSE
	|			FALSE
	|	END AS ToReturnReusablePackage,
	|	CASE
	|		WHEN
	|			DocumentData.DocumentBasis REFS Document.VendorInvoice
	|		THEN
	|			DocumentData.DocumentBasis.PackageDepositIsRequired
	|		ELSE
	|			FALSE
	|	END AS PackageDepositIsRequired,
	|	
	|	DocumentData.Manager AS Manager,
	|	ISNULL(DocumentData.DocumentBasis.FinancialAccountingGroup, VALUE(Catalog.FinancialAccountingGroupsOfARAP.EmptyRef)) AS FinancialAccountingGroup,
	|	ISNULL(DocumentData.Contract.FinancialAccountingGroup, VALUE(Catalog.FinancialAccountingGroupsOfARAP.EmptyRef)) AS ContractFinancialAccountingGroup,
	|	LinesOfBusiness.Ref AS LineOfBusiness,
	|	FALSE 								   AS ByOrders,
	|	FALSE								   AS GroupCosts,
	|	ISNULL(LinesOfBusiness.CostAccounting, FALSE) AS AccountingForLBCosts,
	|	DocumentData.Warehouse                  AS Warehouse,
	|	DocumentData.DocumentAmount         AS DocumentAmount,
	|	DocumentData.Comment            AS Comment,
	|	DocumentData.DeletionMark        AS DeletionMark,
	|	DocumentData.Posted               AS Posted,
	|	DocumentData.Author                  AS Author,
	|	CASE
	|		WHEN DocumentData.DocumentBasis REFS Document.VendorInvoice
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS DocumentIsNotAcquisition,
	|	CASE
	|		WHEN DocumentData.DocumentBasis REFS Document.SourceDocument
	|			THEN FALSE
	|		WHEN DocumentData.DocumentBasis.BusinessOperation IN (&SeparatePurchaseOperations)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                        AS SeparatePurchase,
	|	DocumentData.AssetGLAccountsSettings  AS AssetGLAccountsSettings,
	|	DocumentData.LiabilitiesGLAccountsSettings AS LiabilitiesGLAccountsSettings,
	|	BusinessTransactionsSettings.Ref        AS BusinessTransactionSetting,
	|	DocumentData.DocumentBasis.BusinessOperation AS EconomicOperationOfFoundation,
	|	VALUE(Catalog.Assignments.EmptyRef) AS EmptyAssignment
	|FROM
	|	Document.PurchaseAdjustment AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.AdjustmentKind = BusinessTransactionsSettings.BusinessOperation
	|		LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
	|		ON LinesOfBusiness.Ref = DocumentData.DocumentBasis.LineOfBusiness
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("ReflectRevenuesInCurrentPeriod", Query.Parameters.IncomeItem = ChartsOfCharacteristicTypes.IncomeItems.ProfitLossOfPreviousYears);
	Query.SetParameter("ReflectExpensesInCurrentPeriod", Query.Parameters.ExpenseItem = ChartsOfCharacteristicTypes.ExpenseItems.ProfitLossOfPreviousYears);
	
	Query.SetParameter("UseAccountingOfOtherIncomeExpenses", GetFunctionalOption("UseAccountingOfOtherIncomeExpenses")); 
	Query.SetParameter("UseAccountingOfOtherAssetsAndLiabilities", GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities"));
	Query.SetParameter("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(
			Common.ObjectAttributeValue(DocumentRef, "Organization")));
	Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("MetadataIdentifier",          Common.MetadataObjectID("Document.PurchaseAdjustment"));
	Query.SetParameter("BusinessTransactionsImportPurchase",      PurchasesServer.BusinessOperationsOnMain(
																	Enums.BusinessTransactions.PurchaseByImport));
	Query.SetParameter("TypesOfTaxationVATIsIncludedInCost",
		VATAccountingERP.ActivitiesVATIsIncludedInCost());
	Query.SetParameter("TaxationOfOrganization",
		VATAccountingERP.AccountingParametersForOrganization(Attributes.Organization, Attributes.Period).BasicTaxationVATSales);
	Query.SetParameter("ControlCompanyStockBalanceForRegistrationByReceipts",
		GetFunctionalOption("ControlCompanyStockBalanceForRegistrationByReceipts"));

	If ValueIsFilled(Attributes.Contract) Then
		ContractInformation = NStr("vi = 'Theo hợp đồng ""%Contract%""';
									|ru = 'По договору ""%Contract%""';
									|en = 'Under the ""%Contract%"" contract'; fa = 'Under the ""%Contract%"" contract';
									|it = 'In base al contratto ""%Contract%""';
									|pl = 'Według umowy ""%Contract%""';
									|tr = '""%Contract%"" Sözleşmesi kapsamında'", CommonClientServer.DefaultLanguageCode());
		ContractInformation = StrReplace(ContractInformation, "%Contract%", Attributes.Contract);
	EndIf;
	Query.SetParameter("ContractInformation", ContractInformation);
	
	Query.SetParameter("BusinessTransactionsDeliveryUnderPrincipal",       PurchasesServer.BusinessOperationsForAgencyProcurementUnderPrincipal());
	Query.SetParameter("DocumentIsNotAcquisition", Attributes.DocumentIsNotAcquisition);
	
	Query.SetParameter("IdApplicationForImportOfGoods", Common.MetadataObjectID("Document.ApplicationForImportationOfGoods"));
	Query.SetParameter("BusinessTransactionsProcurementInEAEUCountries", PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU));
	If TypeOf(Attributes.DocumentBasis) = Type("DocumentRef.SubcontractorReport2_5") Then
		DetailsOfFoundationDocument = Common.ObjectAttributesValues(Attributes.DocumentBasis, "BusinessOperation, ByOrders, GroupCosts");
		Query.SetParameter("ProductionAtProcessorInEAEUCountries", DetailsOfFoundationDocument.BusinessOperation = Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5);
		Query.SetParameter("ByOrders", DetailsOfFoundationDocument.ByOrders);
		Query.SetParameter("GroupCosts", DetailsOfFoundationDocument.GroupCosts);
	EndIf;
	InvoicingOperations = New Array;
	InvoicingOperations.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	InvoicingOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	InvoicingOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	InvoicingOperations.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
	InvoicingOperations.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
	
	ObjectData = Common.ObjectAttributesValues(Attributes.Contract, 
		"PurchaseRegistrationOption, OptionForRegisteringServiceReceiptDocuments");
	UnfacturedDeliveriesOfServicesWorks = InvoicingOperations.Find(Attributes.EconomicOperationOfFoundation) <> Undefined
		And (ObjectData.PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices
		Or ObjectData.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced);
	
	Query.SetParameter("UnfacturedDeliveriesOfServicesWorks", UnfacturedDeliveriesOfServicesWorks);
	
	DocumentTimePoint = DocumentRef.PointInTime(); 
	Query.SetParameter("DocumentTimePoint", DocumentTimePoint);
	Query.SetParameter("BorderExcludingDocument", New Boundary(DocumentTimePoint, BoundaryType.Excluding));	
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
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
	|	CASE
	|		WHEN DivergenceTable.ToControlQuality
	|			THEN DivergenceTable.ControlledLotReference
	|		ELSE
	|			VALUE(Catalog.ControlledLots.EmptyRef)
	|	END AS ControlledLotReference,
	|	DivergenceTable.Series               AS Series,
	|	DivergenceTable.Count          AS Count,
	|	DivergenceTable.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
	|WHERE
	|	DivergenceTable.Ref IN(&Ref)
	|	AND DivergenceTable.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND DivergenceTable.PostingOption IN (
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncludeDuringPhysicalInventoryCount),
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseIncludeDuringPhysicalInventoryCount),
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners),
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners),
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncreaseWarehouseStock),
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseReduceWarehouseStock)
	|	)
	|	AND (DivergenceTable.Ref.DocumentBasis REFS Document.SourceDocument
	|		OR NOT DivergenceTable.Ref.DocumentBasis.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit),
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery),
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|				VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|				VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit)
	|			)
	|		)";
	
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
	|	CASE
	|		WHEN DivergenceTable.ToControlQuality
	|			THEN DivergenceTable.ControlledLotReference
	|		ELSE
	|			VALUE(Catalog.ControlledLots.EmptyRef)
	|	END AS ControlledLotReference,
	|	DivergenceTable.Series               AS Series,
	|	DivergenceTable.Count          AS Count,
	|	DivergenceTable.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
	|WHERE
	|	DivergenceTable.Ref IN(&Ref)
	|	AND DivergenceTable.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND DivergenceTable.PostingOption IN (
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncreaseWarehouseStock),
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseReduceWarehouseStock))
	|	AND (DivergenceTable.Ref.DocumentBasis REFS Document.SourceDocument
	|		OR NOT DivergenceTable.Ref.DocumentBasis.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit),
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery),
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|				VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|				VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit)
	|			)
	|		)";
	
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

Procedure InitializeProductAccountingAnalyticsKeys(Query) Export
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query("
	|SELECT
	|	Keys.Products         AS Products,
	|	Keys.Characteristic       AS Characteristic,
	|	Keys.Purpose           AS Purpose,
	|	Keys.Series                AS Series,
	|	Keys.ProductCostElement    AS ProductCostElement,
	|	Keys.Warehouse                AS Warehouse,
	|	Keys.Warehouse                AS StorageLocation
	|FROM
	// Discrepancy keys without assignments
	|	(SELECT DISTINCT
	|		DivergenceTable.ItemsLocationAttributes.Products         AS Products,
	|		DivergenceTable.ItemsLocationAttributes.Characteristic       AS Characteristic,
	|		&EmptyAssignment          AS Purpose,
	|		DivergenceTable.ItemsLocationAttributes.Series                AS Series,
	|		DivergenceTable.ItemsLocationAttributes.StorageLocation        AS Warehouse,
	|		DivergenceTable.ItemsLocationAttributes.ProductCostElement    AS ProductCostElement
	|	FROM
	|		Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
	|	WHERE
	|		DivergenceTable.Ref = &Ref
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|		AND NOT DivergenceTable.Ref.DocumentBasis REFS Document.VendorInvoiceServicesAndAssets
	|		AND NOT DivergenceTable.Ref.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
	|
	|	UNION ALL
	|
	// Partners have the keys
	|	SELECT DISTINCT
	|		DivergenceTable.ItemsLocationAttributes.Products         AS Products,
	|		DivergenceTable.ItemsLocationAttributes.Characteristic       AS Characteristic,
	|		DivergenceTable.ItemsLocationAttributes.Purpose           AS Purpose,
	|		DivergenceTable.ItemsLocationAttributes.Series                AS Series,
	|		DivergenceTable.ItemsLocationAttributes.StorageLocation        AS Warehouse,
	|		CASE
	|			WHEN TRUE
	|				THEN VALUE(Catalog.ProductCostElements.EmptyRef)
	|			WHEN TRUE
	|				THEN DivergenceTable.ItemsLocationAttributes.ProductCostElement
	|		END                                                              AS ProductCostElement
	|	FROM
	|		Document.PurchaseAdjustment.InventoryKinds AS DivergenceTable
	|	WHERE
	|		DivergenceTable.Ref = &Ref
	|		AND &KeepRecordsOfInventoryCostByAssignments
	|		AND NOT DivergenceTable.Ref.DocumentBasis REFS Document.VendorInvoiceServicesAndAssets
	|		AND NOT DivergenceTable.Ref.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
	|
	|	UNION ALL
	|
	// Partners have keys without appointments
	|	SELECT DISTINCT
	|		DivergenceTable.ItemsLocationAttributes.Products         AS Products,
	|		DivergenceTable.ItemsLocationAttributes.Characteristic       AS Characteristic,
	|		&EmptyAssignment          AS Purpose,
	|		DivergenceTable.ItemsLocationAttributes.Series                AS Series,
	|		DivergenceTable.ItemsLocationAttributes.StorageLocation        AS Warehouse,
	|		CASE
	|			WHEN TRUE
	|				THEN VALUE(Catalog.ProductCostElements.EmptyRef)
	|			WHEN TRUE
	|				THEN DivergenceTable.ItemsLocationAttributes.ProductCostElement
	|		END                                                              AS ProductCostElement
	|	FROM
	|		Document.PurchaseAdjustment.InventoryKinds AS DivergenceTable
	|	WHERE
	|		DivergenceTable.Ref = &Ref
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|		AND NOT DivergenceTable.Ref.DocumentBasis REFS Document.VendorInvoiceServicesAndAssets
	|		AND NOT DivergenceTable.Ref.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
	|
	|	UNION ALL
	|
	// Warehouse keys
	|	SELECT DISTINCT
	|		DivergenceTable.ItemsLocationAttributes.Products         AS Products,
	|		DivergenceTable.ItemsLocationAttributes.Characteristic       AS Characteristic,
	|		DivergenceTable.ItemsLocationAttributes.Purpose           AS Purpose,
	|		DivergenceTable.ItemsLocationAttributes.Series                AS Series,
	|		CASE
	|			WHEN DivergenceTable.ToExpenseAs
	|				THEN DivergenceTable.Department
	|			ELSE DivergenceTable.Warehouse
	|		END                                                              AS Warehouse,
	|		CASE
	|			WHEN TRUE
	|				THEN VALUE(Catalog.ProductCostElements.EmptyRef)
	|			WHEN TRUE
	|				THEN DivergenceTable.ItemsLocationAttributes.ProductCostElement
	|		END                                                              AS ProductCostElement
	|	FROM
	|		Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
	|	WHERE
	|		DivergenceTable.Ref = &Ref
	|		AND &UninvoicedReceiptDocumentIsUsed
	|		AND DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners)
	|
	|	UNION ALL
	|
	// Keys to warehouses without appointments
	|	SELECT DISTINCT
	|		DivergenceTable.ItemsLocationAttributes.Products         AS Products,
	|		DivergenceTable.ItemsLocationAttributes.Characteristic       AS Characteristic,
	|		&EmptyAssignment           AS Purpose,
	|		DivergenceTable.ItemsLocationAttributes.Series                AS Series,
	|		CASE
	|			WHEN DivergenceTable.ToExpenseAs
	|				THEN DivergenceTable.Department
	|			ELSE DivergenceTable.Warehouse
	|		END                                                              AS Warehouse,
	|		CASE
	|			WHEN TRUE
	|				THEN VALUE(Catalog.ProductCostElements.EmptyRef)
	|			WHEN TRUE
	|				THEN DivergenceTable.ItemsLocationAttributes.ProductCostElement
	|		END                                                              AS ProductCostElement
	|	FROM
	|		Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
	|	WHERE
	|		DivergenceTable.Ref = &Ref
	|		AND &UninvoicedReceiptDocumentIsUsed
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|		AND DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners)
	|
	|	UNION ALL
	|
	|
	|	SELECT
	|		TraceableGoods.Products         AS Products,
	|		TraceableGoods.Characteristic       AS Characteristic,
	|		CASE 
	|			WHEN &KeepRecordsOfInventoryCostByAssignments THEN 
	|				TraceableGoods.Purpose 
	|			ELSE
	|				&EmptyAssignment 
	|		END AS Purpose,
	|		TraceableGoods.Series                AS Series,
	|		CASE
	|			WHEN TraceableGoods.ToExpenseAs
	|				THEN TraceableGoods.Department
	|			ELSE TraceableGoods.Warehouse
	|		END AS Warehouse,
	|		CASE
	|			WHEN TRUE
	|				THEN VALUE(Catalog.ProductCostElements.EmptyRef)
	|			WHEN TRUE
	|				THEN TraceableGoods.ProductCostElement
	|		END AS ProductCostElement	
	|	FROM
	|		Document.PurchaseAdjustment.Goods AS TraceableGoods
	|			INNER JOIN Catalog.CCDNumbers AS CCDNumbers
	|			ON TraceableGoods.CCDNumber = CCDNumbers.Ref
	|				AND (CCDNumbers.CCDNumberType = VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber)
	|				OR CCDNumbers.CCDNumberType = VALUE(Enum.CCDNumberTypes.KitRNPT))
	|	WHERE
	|		TraceableGoods.Ref = &Ref
	|		AND NOT &DocumentPurchaseOfServicesOtherAssetsIsUsed
	|		AND NOT &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
	|		AND &BusinessOperation = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|
	|) AS Keys
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON Keys.Products                  = Dimension.Products
	|		AND Keys.Characteristic             = Dimension.Characteristic
	|		AND Keys.ProductCostElement          = Dimension.ProductCostElement
	|		AND Keys.Series                      = Dimension.Series
	|		AND Keys.Warehouse                      = Dimension.StorageLocation
	|		AND Keys.Purpose                 = Dimension.Purpose
	|WHERE
	|	Dimension.DimensionKey IS NULL
	|	AND NOT Keys.Products IS NULL
	|
	|GROUP BY
	|	Keys.Products,
	|	Keys.Characteristic,
	|	Keys.Purpose,
	|	Keys.ProductCostElement,
	|	Keys.Series,
	|	Keys.Warehouse
	|
	|UNION ALL
	|
	// Traceable Works
	|SELECT
	|	TraceableWorks.Products         AS Products,
	|	TraceableWorks.Characteristic       AS Characteristic,
	|	CASE 
	|		WHEN &KeepRecordsOfInventoryCostByAssignments THEN 
	|			TraceableWorks.Purpose 
	|		ELSE
	|			&EmptyAssignment 
	|	END AS Purpose,
	|	TraceableWorks.Series                AS Series,
	|	CASE
	|		WHEN TRUE
	|			THEN VALUE(Catalog.ProductCostElements.EmptyRef)
	|		WHEN TRUE
	|			THEN TraceableWorks.ProductCostElement
	|	END                                     AS ProductCostElement,
	|	CASE
	|		WHEN &UnfacturedDeliveriesOfServicesWorks
	|			THEN
	|				TraceableWorks.Ref.Department
	|			ELSE
	|				TraceableWorks.Department
	|	END                                     AS Warehouse,
	|	CASE
	|		WHEN &UnfacturedDeliveriesOfServicesWorks
	|			THEN
	|				TraceableWorks.Ref.Department
	|			ELSE
	|				TraceableWorks.Department
	|	END                                     AS StorageLocation
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS TraceableWorks
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionByBusinessUnits
	|	ON DimensionByBusinessUnits.Products = TraceableWorks.Products
	|		AND DimensionByBusinessUnits.Characteristic = TraceableWorks.Characteristic
	|		AND DimensionByBusinessUnits.Series = TraceableWorks.Series
	|		AND DimensionByBusinessUnits.Purpose = TraceableWorks.Purpose
	|		AND DimensionByBusinessUnits.ProductCostElement = 
	|			CASE
	|				WHEN TRUE
	|					THEN VALUE(Catalog.ProductCostElements.EmptyRef)
	|				WHEN TRUE
	|					THEN TraceableWorks.ProductCostElement
	|			END
	|		AND DimensionByBusinessUnits.StorageLocation = 
	|			CASE
	|				WHEN &UnfacturedDeliveriesOfServicesWorks
	|					THEN
	|						TraceableWorks.Ref.Department
	|					ELSE
	|						TraceableWorks.Department
	|			END
	|WHERE
	|	TraceableWorks.Ref = &Ref
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND TraceableWorks.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND TraceableWorks.Products.TracedGoods
	|	AND DimensionByBusinessUnits.Products IS NULL
	|");
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Partner", Query.Parameters.Partner);
	QueryAnalyst.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments",
										Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	QueryAnalyst.SetParameter("UninvoicedReceiptDocumentIsUsed",
										Query.Parameters.UninvoicedReceiptDocumentIsUsed);
	QueryAnalyst.SetParameter("AdjustingEntryType", Query.Parameters.AdjustingEntryType);
	QueryAnalyst.SetParameter("BusinessOperation", Query.Parameters.BusinessOperation);
	QueryAnalyst.SetParameter("DocumentPurchaseOfServicesOtherAssetsIsUsed", 
		Query.Parameters.DocumentPurchaseOfServicesOtherAssetsIsUsed);
	QueryAnalyst.SetParameter("UseTraceableImportedGoodsAccounting",
		Query.Parameters.UseTraceableImportedGoodsAccounting);
	QueryAnalyst.SetParameter("UnfacturedDeliveriesOfServicesWorks",
		Query.Parameters.UnfacturedDeliveriesOfServicesWorks);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.Currency,
		Query.Parameters.ARAPCurrency,
		Query.Parameters.ReceiptPeriod,
		Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",           Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul",          Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Procedure SetRequestParameterVATReceiptDocument(Query) Export
	
	If Query.Parameters.Property("VATReceiptDocument") Then
		Return;
	EndIf;
	
	If Query.Parameters.BusinessOperation = Enums.BusinessTransactions.ErrorCorrection Then
	    RequestingParameter = New Query;
		RequestingParameter.Text = 
		"SELECT
		|	PurchaseAdjustment.Ref AS VATReceiptDocument
		|FROM
		|	Document.PurchaseAdjustment AS PurchaseAdjustment
		|WHERE
		|	PurchaseAdjustment.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
		|	AND PurchaseAdjustment.Date < &Date
		|	AND PurchaseAdjustment.DocumentBasis = &DocumentBasis
		|	AND PurchaseAdjustment.Posted
		|ORDER BY
		|	PurchaseAdjustment.Date DESC
		|";
		RequestingParameter.SetParameter("Date",              Query.Parameters.Period);
		RequestingParameter.SetParameter("DocumentBasis", Query.Parameters.DocumentBasis);
		
		Selection = RequestingParameter.Execute().Select();
		If Selection.Next() Then
			VATReceiptDocument = Selection.VATReceiptDocument;
		Else
			VATReceiptDocument = Query.Parameters.DocumentBasis;
		EndIf;
	Else
		VATReceiptDocument = Query.Parameters.Ref;
	EndIf; 
	
	Query.SetParameter("VATReceiptDocument", VATReceiptDocument);
	
EndProcedure

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	// The definition of taxation and type of value is similar to Procurement()
	LineNumberText = CostCalculationDocumentsPosting.RequestTextStringCodesForBatchAccountingAnalytics(
		Metadata.Documents.PurchaseAdjustment.Name,
		"Discrepancies, InventoryKinds");
	
	TextSelectionOfAnalystField = LineNumberText + "
	|SELECT
	|	""Discrepancies"" 						AS TabularSectionName,
	|	DocumentTable.LineNumber 			AS LineNumber,
	|	DocumentData.Partner					AS Vendor,
	|	DocumentData.Counterparty				AS Counterparty,
	|	DocumentTable.VATRate 				AS VATRate,
	|	CASE
	|		WHEN ISNULL(ARTICLES__.VATAssetTaxClass, UNDEFINED) IN
	|		  (VALUE(Enum.AssetKinds.FA), VALUE(Enum.AssetKinds.IA))
	|		  AND ISNULL(ARTICLES__.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		  AND ISNULL(ARTICLES__.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|			THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|		WHEN ISNULL(ARTICLES__.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|		 AND NOT &SimplifiedTaxationSystem 
	|			THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		ELSE CASE WHEN ISNULL(DocumentTable.Purpose.VATActivityType,VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		 AND NOT DocumentTable.ToExpenseAs
	|			THEN DocumentTable.Purpose.VATActivityType
	|			WHEN DocumentData.DocumentBasis REFS Document.SourceDocument
	|				THEN DocumentData.PurchaseForActivity
	|			ELSE DocumentData.DocumentBasis.PurchaseForActivity
	|		END
	|	END                               	AS VATTaxation,
	|	CASE
	|		WHEN DocumentData.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer)
	|			THEN VALUE(Enum.AssetKinds.GoodsTaxAgent)
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN
	|		  (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods))
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) = VALUE(Enum.ItemsTypes.Work_5)
	|		  AND NOT DocumentTable.ToExpenseAs
	|			THEN VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|		WHEN ISNULL(ARTICLES__.VATAssetTaxClass, VALUE(Enum.AssetKinds.EmptyRef)) <>
	|		  VALUE(Enum.AssetKinds.EmptyRef)
	|			THEN ARTICLES__.VATAssetTaxClass
	|		WHEN DocumentTable.AssetsLiabilitiesDimension REFS Catalog.Assets
	|		  AND DocumentTable.AssetsLiabilitiesDimension <> VALUE(Catalog.Assets.EmptyRef)
	|			THEN VALUE(Enum.AssetKinds.FA)
	|		WHEN DocumentTable.AssetsLiabilitiesDimension REFS Catalog.IntangibleAssets
	|		  AND DocumentTable.AssetsLiabilitiesDimension <> VALUE(Catalog.IntangibleAssets.EmptyRef)
	|			THEN VALUE(Enum.AssetKinds.IA)
	|		ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END                               	AS AssetTaxClass,
	|	(CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment)
	|			THEN 0
	|		ELSE ISNULL(LineCodes.RowCode, 0) END)	AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS DocumentTable
	|	INNER JOIN Document.PurchaseAdjustment AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	LEFT JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""Discrepancies""
	|	LEFT JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = DocumentTable.Products
	|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
	|		ON DocumentTable.ExpenseItem = ARTICLES__.Ref
	|	LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON CatProducts.FinancialAccountingGroup = FAG.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	""InventoryKinds"" 						AS TabularSectionName,
	|	DocumentTable.LineNumber 			AS LineNumber,
	|	DocumentTable.Ref.Partner					AS Vendor,
	|	DocumentTable.Ref.Counterparty				AS Counterparty,
	|	DocumentTable.VATRate 				AS VATRate,
	|	CASE
	|		WHEN DocumentTable.Ref.DocumentBasis REFS Document.SourceDocument
	|			THEN DocumentTable.Ref.PurchaseForActivity
	|		ELSE
	|		DocumentTable.Ref.DocumentBasis.PurchaseForActivity
	|	END AS VATTaxation,
	|	CASE
	|		WHEN DocumentTable.Ref.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer)
	|			THEN VALUE(Enum.AssetKinds.GoodsTaxAgent)
	|		WHEN ISNULL(DocumentTable.ItemsLocationAttributes.Products.ItemsType, UNDEFINED) IN
	|		  (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN ISNULL(DocumentTable.ItemsLocationAttributes.Products.FinancialAccountingGroup.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods))
	|		ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END                               	AS AssetTaxClass,
	|	LineCodes.RowCode						AS RowCode
	|FROM
	|	Document.PurchaseAdjustment.InventoryKinds AS DocumentTable
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""InventoryKinds""
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	""ARAPAdjustment"" AS TabularSectionName,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.Ref.Partner AS Vendor,
	|	DocumentTable.Ref.Counterparty AS Counterparty,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.Ref.PurchaseForActivity AS VATTaxation,
	|	VALUE(Enum.AssetKinds.OtherWorksAndServices) AS AssetTaxClass,
	|	0 AS RowCode
	|FROM
	|	Document.PurchaseAdjustment.ARAPAdjustment AS DocumentTable
	|WHERE
	|	DocumentTable.Ref = &Ref";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTProductDiscrepancyTable(Query, QueryTexts) Export
	
	RegisterName = "TTProductDiscrepancyTable";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	InitializeProductAccountingAnalyticsKeys(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	DivergenceTable.Ref AS Ref,
	|	DivergenceTable.LineNumber AS LineNumber,
	|	DivergenceTable.Products AS Products,
	|	DivergenceTable.Products.ItemsType AS ItemsType,
	|	DivergenceTable.Characteristic AS Characteristic,
	|	DivergenceTable.Purpose AS Purpose,
	|	DivergenceTable.Purpose.AssignmentType AS AssignmentTypeOfAssignment,
	|	DivergenceTable.Series AS Series,
	|	DivergenceTable.Warehouse AS Warehouse,
	|	DivergenceTable.CCDNumber AS CCDNumber,
	|	DivergenceTable.CCDNumber.CCDNumberType AS CCDNumberCCDNumberType,
	|	DivergenceTable.Warehouse.ShopFloorStockroom AS ShopFloorStockroom,
	|	DivergenceTable.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	DivergenceTable.PurchaseOrder AS PurchaseOrder,
	|	DivergenceTable.RowCode AS RowCode,
	|	DivergenceTable.PostingOption AS PostingOption,
	|	DivergenceTable.Department AS Department,
	|	DivergenceTable.CostGroupNumber AS CostGroupNumber, 
	|	ISNULL(DivergenceTable.Products.TracedGoods, FALSE) AS TracedGoods,
	|
	|	DivergenceTable.ProductCostElement AS ProductCostElement,
	|	DivergenceTable.ProductionStage AS ProductionStage,
	|
	|
	|	DivergenceTable.ToExpenseAs AS ToExpenseAs,
	|	CASE 
	|		WHEN DivergenceTable.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|			THEN DivergenceTable.ExpenseItem 
	|		ELSE UNDEFINED
	|	END AS ExpenseItem,
	|	CASE 
	|		WHEN DivergenceTable.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|			THEN DivergenceTable.ExpenseItem 
	|		ELSE UNDEFINED
	|	END AS AssetAndLiabilityItem,
	|	CASE 
	|		WHEN DivergenceTable.ExpenseItem REFS ChartOfCharacteristicTypes.IncomeItems
	|			THEN DivergenceTable.ExpenseItem 
	|		ELSE UNDEFINED
	|	END AS IncomeItem,
	|	DivergenceTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	DivergenceTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	DivergenceTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	DivergenceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	DivergenceTable.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE DivergenceTable.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	DivergenceTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	DivergenceTable.VATAmount AS VATAmount,
	|	DivergenceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	DivergenceTable.RowID AS RowID,
	|	DivergenceTable.VATRate AS VATRate,
	|	CASE
	|		WHEN &DocumentPurchaseOfServicesOtherAssetsIsUsed
	|			THEN DivergenceTable.LineOfBusiness
	|		WHEN DivergenceTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|		 OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef)
	|			OR (DivergenceTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|				AND ISNULL(DivergenceTable.ItemsLocationAttributes.Purpose.LineOfBusiness,
	|					VALUE(Catalog.LinesOfBusiness.EmptyRef)) = VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|			THEN
	|				CASE
	|					WHEN NOT DivergenceTable.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|						AND DivergenceTable.LineOfBusiness.CostAccounting THEN
	|					DivergenceTable.LineOfBusiness
	|					WHEN DivergenceTable.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|						AND &AccountingForLBCosts  THEN
	|					&LineOfBusiness
	|				ELSE
	|					UNDEFINED
	|				END
	|		ELSE ISNULL(DivergenceTable.ItemsLocationAttributes.Purpose.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|	END AS LineOfBusiness,
	|	CASE
	|		WHEN DivergenceTable.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND &Period >= DivergenceTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseWarehouseManagemantSystemForGoodsReceipt,
	|
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan + Amounts.VATAmountMan
	|		ELSE ISNULL(Amounts.AmountIncludingVATMan, 0) END) AS AmountIncludingVATMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan
	|		ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) END) AS AmountExcludingVATMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) END) AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATBaseLocal, 0) AS VATBaseLocal,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)  AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0) AS VATAmountCompl,
	|	ISNULL(Amounts.VATAmountMan, 0) AS VATAmountMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl - Amounts.AmountExcludingVATCompl
	|		ELSE 0 END) AS CostTD,
	|	CASE
	|		WHEN DivergenceTable.Count = 0 AND &MovingAverage
	|		 AND DivergenceTable.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|			THEN 0
	|		WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|		AND (&BatchAccountingVersion22 AND DivergenceTable.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|			OR DivergenceTable.Count = 0 AND DivergenceTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5))
	|			THEN 0
	|		  ELSE CASE
	|				WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|					THEN Amounts.AmountGivenCompl
	|				ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) END
	|	END AS LocalCost,
	|	CASE
	|		WHEN DivergenceTable.Count = 0 AND &MovingAverage
	|		 AND DivergenceTable.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|			THEN 0
	|		WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|		AND CASE WHEN DivergenceTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|				THEN DivergenceTable.Count = 0 ELSE TRUE END
	|			THEN 0
	|		  ELSE CASE
	|				WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|					THEN Amounts.AmountGivenMan
	|					ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) END
	|	END AS CostMan,
	|	CASE
	// With a sliding average, the total adjustments of any period are reflected in the register "Deviations in the cost of goods" through the additional expense fields,
	// except for the cost adjustment of the delivery invoice.
	|		WHEN &MovingAverage AND DivergenceTable.Count = 0
	|		 AND DivergenceTable.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|			THEN CASE
	|				WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|					THEN Amounts.AmountGivenCompl
	|				ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) END
	|		WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|		OR NOT &BatchAccountingVersion22 AND DivergenceTable.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|		OR DivergenceTable.Count <> 0 AND DivergenceTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN 0
	|		  ELSE CASE
	|				WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|					THEN Amounts.AmountGivenCompl
	|				ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) END
	|	END AS AddExpensesLocal,
	|	CASE
	// With a sliding average, the total adjustments of any period are reflected in the register "Deviations in the cost of goods" through the additional expense fields,
	// except for the cost adjustment of the delivery invoice.
	|		WHEN &MovingAverage AND DivergenceTable.Count = 0
	|		 AND DivergenceTable.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|			THEN CASE
	|				WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|					THEN Amounts.AmountGivenMan
	|				ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) END
	|		WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|		OR DivergenceTable.Count <> 0 AND DivergenceTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN 0
	|		  ELSE CASE
	|				WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|					THEN Amounts.AmountGivenMan
	|					ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) END
	|	END AS AddExpensesMan,
	|
	|	DivergenceTable.AmountARAP AS AmountOfSettlementsWithVAT,
	|	DivergenceTable.AmountVATARAP AS AmountVATARAP,
	|	DivergenceTable.ARAPObject AS ARAPObject,
	|	DivergenceTable.GLAccountSettings AS GLAccountSettings,
	|	
	|	CASE 
	|		WHEN DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome)
	|			OR (DivergenceTable.ToExpenseAs 
	|					AND DivergenceTable.ExpenseItem REFS ChartOfCharacteristicTypes.IncomeItems)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.DebitNoteWithRecordingAsOtherIncome) 
	|		WHEN (DivergenceTable.ToExpenseAs
	|				OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef)
	|				AND DivergenceTable.PostingOption IN (
	|					VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs),
	|					VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost),
	|					VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost)))
	|				OR
	|					DivergenceTable.PostingOption IN (
	|					VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.DebitNoteWithWritingOffAsExpenses)
	|		WHEN DivergenceTable.PostingOption IN
	|					(VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncreaseWarehouseStock),
	|					VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncludeDuringPhysicalInventoryCount),
	|					VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners),
	|					VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier) 
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier)
	|	END AS BusinessTransactionSetting,
	|	DivergenceTable.ARAPObject.UUID AS FinRecordID
	|	
	|INTO TTProductDiscrepancyTable
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON DivergenceTable.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|	AND DivergenceTable.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|	AND DivergenceTable.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|	AND DivergenceTable.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|	AND DivergenceTable.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|	AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = DivergenceTable.Ref
	|	AND Amounts.RowID = DivergenceTable.RowID
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber      = DivergenceTable.LineNumber
	|	AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Discrepancies""
	|
	|WHERE
	|	DivergenceTable.Ref = &Ref
	|	AND (NOT &SeparatePurchase
	|		OR DivergenceTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.Work_5), VALUE(Enum.ItemsTypes.OperationService)))
	|
	|UNION ALL
	|
	|SELECT
	|	DivergenceTable.Ref AS Ref,
	|	DivergenceTable.LineNumber AS LineNumber,
	|	DivergenceTable.ItemsLocationAttributes.Products AS Products,
	|	DivergenceTable.ItemsLocationAttributes.Products.ItemsType AS ItemsType,
	|	DivergenceTable.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	DivergenceTable.ItemsLocationAttributes.Purpose AS Purpose,
	|	DivergenceTable.ItemsLocationAttributes.Purpose.AssignmentType AS AssignmentTypeOfAssignment,
	|	DivergenceTable.ItemsLocationAttributes.Series AS Series,
	|	DivergenceTable.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	DivergenceTable.CCDNumber AS CCDNumber,
	|	DivergenceTable.CCDNumber.CCDNumberType AS CCDNumberCCDNumberType,
	|	DivergenceTable.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom AS ShopFloorStockroom,
	|	DivergenceTable.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	DivergenceTable.PurchaseOrder AS PurchaseOrder,
	|	DivergenceTable.RowCode AS RowCode,
	|	DivergenceTable.PostingOption AS PostingOption,
	|	DivergenceTable.Department AS Department,
	|	0 AS CostGroupNumber,
	|	ISNULL(DivergenceTable.ItemsLocationAttributes.Products.TracedGoods, FALSE) AS TracedGoods,
	|
	|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
	|	VALUE(Document.ProductionStage2_2.EmptyRef) AS ProductionStage,
	|
	|
	|	DivergenceTable.ToExpenseAs AS ToExpenseAs,
	|	CASE 
	|		WHEN DivergenceTable.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|			THEN DivergenceTable.ExpenseItem 
	|		ELSE UNDEFINED
	|	END AS ExpenseItem,
	|	CASE 
	|		WHEN DivergenceTable.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|			THEN DivergenceTable.ExpenseItem 
	|		ELSE UNDEFINED
	|	END AS AssetAndLiabilityItem,
	|	CASE 
	|		WHEN DivergenceTable.ExpenseItem REFS ChartOfCharacteristicTypes.IncomeItems
	|			THEN DivergenceTable.ExpenseItem 
	|		ELSE UNDEFINED
	|	END AS IncomeItem,
	|	DivergenceTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	DivergenceTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	DivergenceTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	DivergenceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	DivergenceTable.Count AS Count,
	|	DivergenceTable.QuantityByGBRN AS QuantityByGBRN,
	|	DivergenceTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	DivergenceTable.VATAmount AS VATAmount,
	|	DivergenceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	DivergenceTable.RowID AS RowID,
	|	DivergenceTable.VATRate AS VATRate,
	|	DivergenceTable.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN DivergenceTable.ItemsLocationAttributes.WarehouseArea.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND &Period >= DivergenceTable.ItemsLocationAttributes.WarehouseArea.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseWarehouseManagemantSystemForGoodsReceipt,
	|
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan + Amounts.VATAmountMan
	|		ELSE ISNULL(Amounts.AmountIncludingVATMan, 0) END) AS AmountIncludingVATMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan
	|		ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) END) AS AmountExcludingVATMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) END) AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATBaseLocal, 0) AS VATBaseLocal,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)  AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0) AS VATAmountCompl,
	|	ISNULL(Amounts.VATAmountMan, 0) AS VATAmountMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl - Amounts.AmountExcludingVATCompl
	|		ELSE 0 END) AS CostTD,
	|	CASE
	|		WHEN DivergenceTable.Count = 0 AND &MovingAverage
	|			THEN 0
	|		WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|		AND (&BatchAccountingVersion22 AND DivergenceTable.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|			OR DivergenceTable.Count = 0
	|				AND DivergenceTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5))
	|			THEN 0
	|		  ELSE CASE
	|				WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|					THEN Amounts.AmountGivenCompl
	|				ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) END
	|	END AS LocalCost,
	|	CASE
	|		WHEN DivergenceTable.Count = 0 AND &MovingAverage
	|			THEN 0
	|		WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|		AND CASE WHEN DivergenceTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|				THEN DivergenceTable.Count = 0 ELSE TRUE END
	|			THEN 0
	|		  ELSE CASE
	|				WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|					THEN Amounts.AmountGivenMan
	|					ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) END
	|	END AS CostMan,
	|	CASE WHEN (BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|		OR NOT &BatchAccountingVersion22
	|		 AND DivergenceTable.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|		OR DivergenceTable.Count <> 0
	|		 AND DivergenceTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5))
	|		AND NOT &MovingAverage
	|			THEN 0
	|			ELSE CASE
	|				WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|					THEN Amounts.AmountGivenCompl
	|				ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) END
	|	END AS AddExpensesLocal,
	|	CASE WHEN (BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|		OR DivergenceTable.Count <> 0
	|		 AND DivergenceTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5))
	|		AND NOT &MovingAverage
	|			THEN 0
	|		  ELSE CASE
	|				WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|					THEN Amounts.AmountGivenMan
	|					ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) END
	|	END AS AddExpensesMan,
	|	
	|	DivergenceTable.AmountARAP AS AmountOfSettlementsWithVAT,
	|	DivergenceTable.AmountVATARAP AS AmountVATARAP,
	|	DivergenceTable.ARAPObject AS ARAPObject,
	|	UNDEFINED AS GLAccountSettings,
	|	
	|	CASE 
	|		WHEN DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome) 
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.DebitNoteWithRecordingAsOtherIncome) 
	|		WHEN DivergenceTable.ToExpenseAs AND
	|				DivergenceTable.PostingOption IN (
	|					VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs),
	|					VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost),
	|					VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost))
	|				OR DivergenceTable.PostingOption IN (
	|					VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.DebitNoteWithWritingOffAsExpenses)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier)
	|	END AS BusinessTransactionSetting,
	|	DivergenceTable.ARAPObject.UUID AS FinRecordID
	|	
	|FROM
	|	Document.PurchaseAdjustment.InventoryKinds AS DivergenceTable
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON DivergenceTable.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND DivergenceTable.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|		AND DivergenceTable.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND DivergenceTable.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = DivergenceTable.Ref
	|	AND Amounts.RowID = DivergenceTable.RowID
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber      = DivergenceTable.LineNumber
	|	AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|
	|WHERE
	|	DivergenceTable.Ref = &Ref
	|	AND &SeparatePurchase
	|
	|INDEX BY
	|	CCDNumberCCDNumberType";
	
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
	|	ARAPAdjustment.ARAPObject.LineOfBusiness AS DirectionOfActivityOfCalculations,
	|	ARAPAdjustment.ARAPObject.Contract AS Contract,
	|	ARAPAdjustment.VATRate AS VATRate,
	|
	|	FALSE AS ToExpenses,
	|	FALSE AS OnOtherAssets,
	|	CASE 
	|		WHEN &IncomeItem <> UNDEFINED
	|			THEN TRUE
	|			ELSE FALSE
	|	END AS OnIncome,
	|	CASE 
	|		WHEN &LiabilityItem <> UNDEFINED 
	|			THEN TRUE
	|			ELSE FALSE
	|	END AS OtherLiabilities_,
	|
	|	(ARAPAdjustment.AdjustmentSum - ARAPAdjustment.SumOfVATAdjustments) AS AmountExcludingVAT,
	|	(ARAPAdjustment.AdjustmentSum) AS AmountIncludingVAT,
	|	(ARAPAdjustment.SumOfVATAdjustments) AS VATAmount,
	|
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
	|	
	|	ARAPAdjustment.RowID AS RowID,
	|	ARAPAdjustment.ARAPObject.UUID AS UniqueIDOfSettlementObject
	|
	|INTO TTTableDebtAdjustment
	|FROM
	|	Document.PurchaseAdjustment.ARAPAdjustment AS ARAPAdjustment
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
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated)
	|
	|UNION ALL
	|
	|SELECT
	|	ARAPAdjustment.Ref AS Ref,
	|	ARAPAdjustment.LineNumber AS LineNumber,
	|	ARAPAdjustment.ARAPObject AS ARAPObject,
	|	ARAPAdjustment.ARAPObject.LineOfBusiness AS DirectionOfActivityOfCalculations,
	|	ARAPAdjustment.ARAPObject.Contract AS Contract,
	|	ARAPAdjustment.VATRate AS VATRate,
	|
	|	CASE 
	|		WHEN &ExpenseItem <> UNDEFINED
	|			THEN TRUE
	|			ELSE FALSE
	|	END AS ToExpenses,
	|	CASE 
	|		WHEN &AssetItem <> UNDEFINED
	|			THEN TRUE
	|			ELSE FALSE
	|	END AS OnOtherAssets,
	|	FALSE AS OnIncome,
	|	FALSE AS OtherLiabilities_,
	|	
	|	ARAPAdjustment.AdjustmentSum - ARAPAdjustment.SumOfVATAdjustments AS AmountExcludingVAT,
	|	ARAPAdjustment.AdjustmentSum       AS AmountIncludingVAT,
	|	ARAPAdjustment.SumOfVATAdjustments    AS VATAmount,
	|
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
	|	
	|	ARAPAdjustment.RowID AS RowID,
	|	ARAPAdjustment.ARAPObject.UUID AS UniqueIDOfSettlementObject
	|FROM
	|	Document.PurchaseAdjustment.ARAPAdjustment AS ARAPAdjustment
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
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts)
	
	RegisterName = "TTTableTypesOfInventoryRegistration";
	
	InitializeProductAccountingAnalyticsKeys(Query);
	SetRequestParametersCurrencyCoefficients(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	DivergenceTable.LineNumber AS LineNumber,
	|	DivergenceTable.Products AS Products,
	|	DivergenceTable.Characteristic AS Characteristic,
	|	DivergenceTable.Series AS Series,
	|	DivergenceTable.Purpose AS Purpose,
	|	DivergenceTable.Department AS Department,
	|	DivergenceTable.Ref.Department AS CapDivision,
	|	DivergenceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	DivergenceTable.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	DivergenceTable.CCDNumber AS CCDNumber,
	|	DivergenceTable.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE DivergenceTable.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	DivergenceTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	DivergenceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DivergenceTable.RowID AS RowID,
	|	AnalyticsWithoutAssignment.DimensionKey  AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	DivergenceTable.VATRate AS VATRate,
	|
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN (Amounts.AmountGivenMan + Amounts.VATAmountMan)
	|		ELSE ISNULL(Amounts.AmountIncludingVATMan, 0) END) AS AmountIncludingVATMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan
	|		ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) END) AS AmountExcludingVATMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) END) AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0) AS VATAmountCompl,
	|
	|	DivergenceTable.Warehouse AS Warehouse,
	|	DivergenceTable.Warehouse.ShopFloorStockroom AS ShopFloorStockroom,
	|	DivergenceTable.SalesOpportunity AS SalesOpportunity,
	|	DivergenceTable.VATAmount AS VATAmount,
	|	DivergenceTable.AmountARAP AS AmountARAP,
	|	DivergenceTable.AmountVATARAP AS AmountVATARAP,
	|	DivergenceTable.PurchaseOrder AS PurchaseOrder,
	|	
	|	VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier) AS BusinessTransactionSetting,
	|	DivergenceTable.ARAPObject.UUID AS FinRecordID,
	|	FALSE AS ThisIsTraceableWork
	|
	|INTO TTTableTypesOfInventoryRegistration
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON DivergenceTable.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND DivergenceTable.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|		AND DivergenceTable.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND DivergenceTable.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= DivergenceTable.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Discrepancies""
	|
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = DivergenceTable.Ref
	|		AND Amounts.RowID = DivergenceTable.RowID
	|WHERE
	|	DivergenceTable.Ref = &Ref
	|	AND NOT &SeparatePurchase
	|	AND DivergenceTable.PostingOption IN
	|		(VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncreaseWarehouseStock),
	|		 VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncludeDuringPhysicalInventoryCount))
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryKinds.LineNumber AS LineNumber,
	|	InventoryKinds.ItemsLocationAttributes.Products AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	InventoryKinds.ItemsLocationAttributes.Series AS Series,
	|	InventoryKinds.ItemsLocationAttributes.Purpose AS Purpose,
	|	InventoryKinds.Department AS Department,
	|	InventoryKinds.Ref.Department AS CapDivision,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	InventoryKinds.Count AS Count,
	|	InventoryKinds.QuantityByGBRN AS QuantityByGBRN,
	|	InventoryKinds.AmountIncludingVAT AS AmountIncludingVAT,
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InventoryKinds.RowID AS RowID,
	|	AnalyticsWithoutAssignment.DimensionKey  AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	InventoryKinds.VATRate AS VATRate,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency AND &Currency <> &ARAPCurrency THEN
	|			InventoryKinds.AmountARAP
	|		ELSE
	|			CAST((InventoryKinds.AmountIncludingVAT * &ConversionRateToManCurrency) AS NUMBER(31,2))
	|	END AS AmountIncludingVATMan,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency AND &Currency <> &ARAPCurrency THEN
	|			InventoryKinds.AmountARAP - InventoryKinds.AmountVATARAP
	|	ELSE
	|		CAST(((InventoryKinds.AmountIncludingVAT-InventoryKinds.VATAmount) * &ConversionRateToManCurrency) AS NUMBER(31,2))
	|	END AS AmountExcludingVATMan,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency AND &Currency <> &ARAPCurrency THEN
	|			InventoryKinds.AmountARAP - InventoryKinds.AmountVATARAP
	|		ELSE
	|			CAST(((InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount) * &FactorOfConversionToCurrencyOfRegul) AS NUMBER(31,2))
	|	END AS AmountExcludingVATCompl,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency AND &Currency <> &ARAPCurrency THEN
	|			InventoryKinds.AmountARAP
	|		ELSE
	|			CAST((InventoryKinds.VATAmount * &FactorOfConversionToCurrencyOfRegul) AS NUMBER(31,2))
	|	END AS VATAmountCompl,
	|
	|	InventoryKinds.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	InventoryKinds.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom AS ShopFloorStockroom,
	|	InventoryKinds.SalesOpportunity AS SalesOpportunity,
	|	InventoryKinds.VATAmount AS VATAmount,
	|	InventoryKinds.AmountARAP AS AmountARAP,
	|	InventoryKinds.AmountVATARAP AS AmountVATARAP,
	|	InventoryKinds.PurchaseOrder AS PurchaseOrder,
	|	
	|	VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier) AS BusinessTransactionSetting,
	|	InventoryKinds.ARAPObject.UUID AS FinRecordID,
	|	FALSE AS ThisIsTraceableWork
	|
	|FROM
	|	Document.PurchaseAdjustment.InventoryKinds AS InventoryKinds
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON InventoryKinds.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND InventoryKinds.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|		AND InventoryKinds.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND InventoryKinds.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= InventoryKinds.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|	AND &SeparatePurchase
	|	AND InventoryKinds.PostingOption =
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners)
	|
	|UNION ALL
	|
	|SELECT
	|	DivergenceTable.LineNumber AS LineNumber,
	|	DivergenceTable.Products AS Products,
	|	DivergenceTable.Characteristic AS Characteristic,
	|	DivergenceTable.Series AS Series,
	|	DivergenceTable.Purpose AS Purpose,
	|	DivergenceTable.Department AS Department,
	|	DivergenceTable.Ref.Department AS CapDivision,
	|	DivergenceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	DivergenceTable.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	DivergenceTable.CCDNumber AS CCDNumber,
	|	DivergenceTable.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE DivergenceTable.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	DivergenceTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	DivergenceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DivergenceTable.RowID AS RowID,
	|	AnalyticsWithoutAssignment.DimensionKey  AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	DivergenceTable.VATRate AS VATRate,
	|
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN (Amounts.AmountGivenMan + Amounts.VATAmountMan)
	|		ELSE ISNULL(Amounts.AmountIncludingVATMan, 0) END) AS AmountIncludingVATMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan
	|		ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) END) AS AmountExcludingVATMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) END) AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0) AS VATAmountCompl,
	|
	|	DivergenceTable.Warehouse AS Warehouse,
	|	DivergenceTable.Warehouse.ShopFloorStockroom AS ShopFloorStockroom,
	|	DivergenceTable.SalesOpportunity AS SalesOpportunity,
	|	DivergenceTable.VATAmount AS VATAmount,
	|	DivergenceTable.AmountARAP AS AmountARAP,
	|	DivergenceTable.AmountVATARAP AS AmountVATARAP,
	|	DivergenceTable.PurchaseOrder AS PurchaseOrder,
	|	
	|	VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier) AS BusinessTransactionSetting,
	|	DivergenceTable.ARAPObject.UUID AS FinRecordID,
	|	TRUE AS ThisIsTraceableWork
	|
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON DivergenceTable.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND DivergenceTable.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|		AND DivergenceTable.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND DivergenceTable.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= DivergenceTable.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Discrepancies""
	|
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = DivergenceTable.Ref
	|		AND Amounts.RowID = DivergenceTable.RowID
	|WHERE
	|	DivergenceTable.Ref = &Ref
	// Traceable works.
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND DivergenceTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND DivergenceTable.Products.TracedGoods
	|	AND DivergenceTable.PostingOption =
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost)
	|	AND NOT DivergenceTable.ToExpenseAs
	|	AND NOT &BusinessTransactionGrounds = VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment)
	|	AND DivergenceTable.Count <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTRefundsToSuppliers(Query, QueryTexts)
	
	RegisterName = "TTAcquisitionAdjustments";
	
	// The conditions of the checks correspond to the area of acquisition adjustment in the general module "Calculation of the cost of data preparation".
	QueryText = "
	|SELECT
	|	DivergenceTable.Ref.Organization AS Organization,
	|	DivergenceTable.ItemsLocationAttributes,
	|	(CASE
	|		WHEN NOT &KeepRecordsOfInventoryCostByAssignments THEN AnalyticsWithoutAssignment.DimensionKey
	|		ELSE DivergenceTable.ItemsLocationAttributes END) AS CostAccountingAnalytics,
	|	DivergenceTable.InventoryOwnerAttribute,
	|	SUM(DivergenceTable.Count) AS Count
	|INTO TTAcquisitionAdjustments
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON Dimension.Ref = DivergenceTable.ItemsLocationAttributes
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON AnalyticsWithoutAssignment.Products = Dimension.Products
	|		AND AnalyticsWithoutAssignment.Characteristic = Dimension.Characteristic
	|		AND AnalyticsWithoutAssignment.Series = Dimension.Series
	|		AND AnalyticsWithoutAssignment.StorageLocation = Dimension.StorageLocation
	|		AND AnalyticsWithoutAssignment.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		AND AnalyticsWithoutAssignment.ProductCostElement = Dimension.ProductCostElement
	|WHERE
	|	DivergenceTable.Ref = &Ref
	|	AND BEGINOFPERIOD(&ReceiptPeriod, MONTH) < BEGINOFPERIOD(&Period, MONTH)
	|	AND DivergenceTable.PostingOption IN (
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseReduceWarehouseStock),
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseIncludeDuringPhysicalInventoryCount))
	|GROUP BY
	|	DivergenceTable.Ref.Organization,
	|	DivergenceTable.ItemsLocationAttributes,
	|	(CASE
	|		WHEN NOT &KeepRecordsOfInventoryCostByAssignments THEN AnalyticsWithoutAssignment.DimensionKey
	|		ELSE DivergenceTable.ItemsLocationAttributes END),
	|	DivergenceTable.InventoryOwnerAttribute
	|";
	QueryTexts.Add(QueryText, RegisterName);
	
	RegisterName = "TTNonZeroProductBalances";
	
	// We get a table of non-zero product balances at the beginning of the month.
	// For the evaluation method "Average for the month", we take the remnants of goods from the register "Goods of organizations".
	// For the "FIFO" estimation method for batch accounting 2.2, we take the balances from the "Cost of Goods" register for the adjusted batch.
	QueryText = "
	|SELECT
	|	StockBalance.ItemsLocationAttributes,
	|	StockBalance.InventoryOwnerAttribute,
	|	StockBalance.CountBalance AS Count
	|INTO TTNonZeroProductBalances
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(BEGINOFPERIOD(&Period, MONTH),
	|		NOT (&BatchAccountingVersion22 AND &FIFORollingValuation)
	|		AND (ItemsLocationAttributes, Organization, InventoryOwnerAttribute) IN (
	|			SELECT
	|				AdjustingEntries.ItemsLocationAttributes,
	|				AdjustingEntries.Organization,
	|               AdjustingEntries.InventoryOwnerAttribute
	|			FROM
	|				TTAcquisitionAdjustments AS AdjustingEntries
	|		)
	|	) AS StockBalance
	|";
	QueryTexts.Add(QueryText, RegisterName);
	
	RegisterName = "TTNonZeroCostBalances";
	
	QueryText = "
	|SELECT
	|	StockBalance.ItemsLocationAttributes,
	|	StockBalance.InventoryOwnerAttribute,
	|	StockBalance.CountBalance AS Count
	|INTO TTNonZeroCostBalances
	|FROM
	|	AccumulationRegister.InventoryCost.Balance(BEGINOFPERIOD(&Period, MONTH),
	|		(&BatchAccountingVersion22 AND &FIFORollingValuation)
	|		AND (ItemsLocationAttributes, InventoryOwnerAttribute, Organization, Lot) IN (
	|			SELECT
	|				AdjustingEntries.CostAccountingAnalytics,
	|               AdjustingEntries.InventoryOwnerAttribute,
	|				AdjustingEntries.Organization,
	|				&DocumentBasis AS Lot
	|			FROM
	|				TTAcquisitionAdjustments AS AdjustingEntries
	|		)
	|	) AS StockBalance
	|";
	QueryTexts.Add(QueryText, RegisterName);
	
	RegisterName = "TTPastAdjustments";
	
	QueryText = "
	|SELECT
	|	RegisterRecords.ItemsLocationAttributes,
	|	RegisterRecords.InventoryOwnerAttribute,
	|	SUM(RegisterRecords.Count) AS Count
	|INTO TTPastAdjustments
	|FROM
	|	AccumulationRegister.InventoryCost AS RegisterRecords
	|	INNER JOIN Document.PurchaseAdjustment AS PurchaseAdjustment
	|		ON PurchaseAdjustment.Ref = RegisterRecords.Recorder
	|		AND PurchaseAdjustment.DocumentBasis = &DocumentBasis
	|WHERE
	|	RegisterRecords.Period BETWEEN BEGINOFPERIOD(&Period, MONTH) AND &Period
	|	AND RegisterRecords.Recorder <> &Ref
	|	AND RegisterRecords.Active
	|	AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND (RegisterRecords.ItemsLocationAttributes, RegisterRecords.InventoryOwnerAttribute, RegisterRecords.Organization) IN (
	|			SELECT
	|				AdjustingEntries.CostAccountingAnalytics,
	|				AdjustingEntries.InventoryOwnerAttribute,
	|				AdjustingEntries.Organization
	|			FROM
	|				TTAcquisitionAdjustments AS AdjustingEntries
	|		)
	|GROUP BY
	|	RegisterRecords.ItemsLocationAttributes,
	|	RegisterRecords.InventoryOwnerAttribute
	|";
	QueryTexts.Add(QueryText, RegisterName);
	
	RegisterName = "TTRefundsToSuppliers";
	
 	// We form a table of product analysts for which the purchase adjustment should work out as a return of goods to the supplier.
	QueryText = "
	|SELECT DISTINCT
	|	AdjustingEntries.ItemsLocationAttributes,
	|	TRUE AS ThisIsRefundToSupplier
	|INTO TTRefundsToSuppliers
	|FROM
	|	TTAcquisitionAdjustments AS AdjustingEntries
	|	LEFT JOIN TTNonZeroProductBalances AS StockBalance
	|		ON StockBalance.ItemsLocationAttributes = AdjustingEntries.ItemsLocationAttributes
	|		AND StockBalance.InventoryOwnerAttribute = AdjustingEntries.InventoryOwnerAttribute
	|	LEFT JOIN TTNonZeroCostBalances AS CostBalances
	|		ON CostBalances.ItemsLocationAttributes = AdjustingEntries.CostAccountingAnalytics
	|		AND CostBalances.InventoryOwnerAttribute = AdjustingEntries.InventoryOwnerAttribute
	|	LEFT JOIN TTPastAdjustments AS PastAdjustments
	|		ON PastAdjustments.ItemsLocationAttributes = AdjustingEntries.CostAccountingAnalytics
	|		AND PastAdjustments.InventoryOwnerAttribute = AdjustingEntries.InventoryOwnerAttribute
	|WHERE
	|	NOT (&BatchAccountingVersion22 AND &FIFORollingValuation)
	|		AND ISNULL(StockBalance.Count, 0) <= (-AdjustingEntries.Count - ISNULL(PastAdjustments.Count, 0))
	|	OR (&BatchAccountingVersion22 AND &FIFORollingValuation)
	|		AND ISNULL(CostBalances.Count, 0) <= (-AdjustingEntries.Count - ISNULL(PastAdjustments.Count, 0))
	|";
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTNomenclatureParameters(Query, QueryTexts)
	
	RegisterName = "TTNomenclatureParameters";
	
	QueryText = 
	"SELECT
	|	Goods.Ref AS Ref,
	// In two-way operation, the Status of the series indications in the Acquisition and Adjustment of the Acquisition may be zero when accounting for the series at cost.
	// Such series are explicitly indicated in the document Receipt of goods. Here it is required to find out the very fact of such a series accounting setting.
	|	MAX(Goods.BatchesIndicationStatus = 14 OR ISNULL(Policies.BatchAccountingPolicy.UseCostAccountingByBatches, FALSE)) AS AccountingOfSeriesAtCost,
	|	MAX(ISNULL(Goods.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries, FALSE)) AS BatchesAccountingInUninvoicedGoodsDeliveries,
	|	MAX(ISNULL(Goods.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor, FALSE)) AS BatchesAccountingOfGoodsInTransitFromVendor,
	|	Goods.ItemsLocationAttributes.Products AS Products
	|INTO TTNomenclatureParameters
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS Goods
	|	LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS Policies
	|		ON Policies.Ref = Goods.ItemsLocationAttributes.Products.ProductKind
	|		AND Policies.Warehouse = Goods.Warehouse
	|WHERE
	|	Goods.Ref = &Ref
	|
	|GROUP BY
	|	Goods.Ref,
	|	Goods.ItemsLocationAttributes.Products
	|
	|INDEX BY
	|	Ref,
	|	Products
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTTableTypesOfInventoryWriteOff(Query, QueryTexts)
	
	RegisterName = "TTTableTypesOfInventoryWriteOff";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTRefundsToSuppliers", QueryTexts) Then
		QueryTextTTRefundsToSuppliers(Query, QueryTexts);
	EndIf;
	
	InitializeProductAccountingAnalyticsKeys(Query);
	SetRequestParametersCurrencyCoefficients(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	DivergenceTable.LineNumber AS LineNumber,
	|	DivergenceTable.Products AS Products,
	|	DivergenceTable.Characteristic AS Characteristic,
	|	DivergenceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DivergenceTable.Purpose AS Purpose,
	|	DivergenceTable.Department AS Department,
	|	DivergenceTable.Ref.Department AS CapDivision,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	DivergenceTable.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	DivergenceTable.CCDNumber AS CCDNumber,
	|	-DivergenceTable.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE -DivergenceTable.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	-DivergenceTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	DivergenceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DivergenceTable.RowID AS RowID,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	DivergenceTable.VATRate AS VATRate,
	|
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN -(Amounts.AmountGivenMan + Amounts.VATAmountMan)
	|		ELSE ISNULL(-Amounts.AmountIncludingVATMan, 0) END) AS AmountIncludingVATMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN -Amounts.AmountGivenMan
	|		ELSE ISNULL(-Amounts.AmountExcludingVATMan, 0) END) AS AmountExcludingVATMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN -Amounts.AmountGivenCompl
	|		ELSE ISNULL(-Amounts.AmountExcludingVATCompl, 0) END) AS AmountExcludingVATCompl,
	|	ISNULL(-Amounts.VATAmountCompl, 0) AS VATAmountCompl,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl - Amounts.AmountExcludingVATCompl
	|		ELSE 0 END) AS CostTD,
	|
	|	CASE
	|		WHEN DivergenceTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		ELSE CASE
	|			WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|				THEN -Amounts.AmountGivenCompl
	|			ELSE ISNULL(-Amounts.AmountExcludingVATCompl, 0) END
	|	END AS LocalCost,
	|	CASE
	|		WHEN DivergenceTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		ELSE CASE
	|			WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|				THEN -Amounts.AmountGivenMan
	|			ELSE ISNULL(-Amounts.AmountExcludingVATMan, 0) END
	|	END AS CostMan,
	|	CASE
	|		WHEN DivergenceTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		ELSE CASE
	|				WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|					THEN -Amounts.AmountGivenCompl
	|				ELSE ISNULL(-Amounts.AmountExcludingVATCompl, 0) END
	|	END AS AddExpensesLocal,
	|	CASE
	|		WHEN DivergenceTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		ELSE CASE
	|			WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|				THEN -Amounts.AmountGivenMan
	|			ELSE ISNULL(-Amounts.AmountExcludingVATMan, 0) END
	|	END AS AddExpensesMan,
	|
	|	DivergenceTable.Warehouse AS Warehouse,
	|	DivergenceTable.Warehouse.ShopFloorStockroom AS ShopFloorStockroom,
	|	DivergenceTable.SalesOpportunity AS SalesOpportunity,
	|	DivergenceTable.VATAmount AS VATAmount,
	|	DivergenceTable.AmountARAP AS AmountARAP,
	|	DivergenceTable.AmountVATARAP AS AmountVATARAP,
	|	DivergenceTable.PurchaseOrder AS PurchaseOrder,
	|	CASE
	|		WHEN (BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|				OR DivergenceTable.AmountIncludingVAT <> 0)
	|			OR (BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|				AND DivergenceTable.Count <> 0)
	|			THEN ISNULL(RefundsToSuppliers.ThisIsRefundToSupplier, FALSE)
	|		ELSE TRUE
	|	END AS ThisIsRefundToSupplier,
	|
	|	VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier) AS BusinessTransactionSetting,
	|	DivergenceTable.ARAPObject.UUID AS FinRecordID,
	|	FALSE AS ThisIsTraceableWork
	|
	|INTO TTTableTypesOfInventoryWriteOff
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
	|	LEFT JOIN TTRefundsToSuppliers AS RefundsToSuppliers
	|		ON RefundsToSuppliers.ItemsLocationAttributes = DivergenceTable.ItemsLocationAttributes
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON DivergenceTable.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND DivergenceTable.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND DivergenceTable.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND DivergenceTable.ItemsLocationAttributes.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|		AND DivergenceTable.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= DivergenceTable.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Discrepancies""
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		Amounts.Ref = DivergenceTable.Ref
	|		AND Amounts.RowID = DivergenceTable.RowID
	|
	|WHERE
	|	DivergenceTable.Ref = &Ref
	|	AND NOT &SeparatePurchase
	|	AND DivergenceTable.PostingOption IN
	|		(VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseReduceWarehouseStock),
	|		 VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners),
	|		 VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseIncludeDuringPhysicalInventoryCount))
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryKinds.LineNumber AS LineNumber,
	|	InventoryKinds.ItemsLocationAttributes.Products AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.ItemsLocationAttributes.Purpose AS Purpose,
	|	InventoryKinds.Department AS Department,
	|	InventoryKinds.Ref.Department AS CapDivision,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	-InventoryKinds.Count AS Count,
	|	-InventoryKinds.QuantityByGBRN AS QuantityByGBRN,
	|	-InventoryKinds.AmountIncludingVAT AS AmountIncludingVAT,
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InventoryKinds.RowID AS RowID,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	InventoryKinds.VATRate AS VATRate,
	|
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN -(Amounts.AmountGivenMan + Amounts.VATAmountMan)
	|		ELSE ISNULL(-Amounts.AmountIncludingVATMan, 0) END) AS AmountIncludingVATMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN -Amounts.AmountGivenMan
	|		ELSE ISNULL(-Amounts.AmountExcludingVATMan, 0) END) AS AmountExcludingVATMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN -Amounts.AmountGivenCompl
	|		ELSE ISNULL(-Amounts.AmountExcludingVATCompl, 0) END) AS AmountExcludingVATCompl,
	|	ISNULL(-Amounts.VATAmountCompl, 0) AS VATAmountCompl,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl - Amounts.AmountExcludingVATCompl
	|		ELSE 0 END) AS CostTD,
	|
	|	CASE
	|		WHEN InventoryKinds.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		ELSE CASE
	|			WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|				THEN -Amounts.AmountGivenCompl
	|			ELSE ISNULL(-Amounts.AmountExcludingVATCompl, 0) END
	|	END AS LocalCost,
	|	CASE
	|		WHEN InventoryKinds.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		ELSE CASE
	|			WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|				THEN -Amounts.AmountGivenMan
	|			ELSE ISNULL(-Amounts.AmountExcludingVATMan, 0) END
	|	END AS CostMan,
	|	CASE
	|		WHEN InventoryKinds.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		ELSE CASE
	|			WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|				THEN -Amounts.AmountGivenCompl
	|			ELSE ISNULL(-Amounts.AmountExcludingVATCompl, 0) END
	|	END AS AddExpensesLocal,
	|	CASE
	|		WHEN InventoryKinds.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		ELSE CASE
	|			WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|				THEN -Amounts.AmountGivenMan
	|			ELSE ISNULL(-Amounts.AmountExcludingVATMan, 0) END
	|	END AS AddExpensesMan,
	|
	|	InventoryKinds.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	InventoryKinds.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom AS ShopFloorStockroom,
	|	InventoryKinds.SalesOpportunity AS SalesOpportunity,
	|	InventoryKinds.VATAmount AS VATAmount,
	|	InventoryKinds.AmountARAP AS AmountARAP,
	|	InventoryKinds.AmountVATARAP AS AmountVATARAP,
	|	InventoryKinds.PurchaseOrder AS PurchaseOrder,
	|	CASE
	|		WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|		 OR InventoryKinds.AmountIncludingVAT <> 0
	|	THEN
	|		ISNULL(RefundsToSuppliers.ThisIsRefundToSupplier, FALSE)
	|	ELSE
	|		TRUE
	|	END AS ThisIsRefundToSupplier,
	|
	|	VALUE(Catalog.BusinessTransactionsSettings.ReverseOfReceipt) AS BusinessTransactionSetting,
	|	InventoryKinds.ARAPObject.UUID AS FinRecordID,
	|	FALSE AS ThisIsTraceableWork
	|
	|FROM
	|	Document.PurchaseAdjustment.InventoryKinds AS InventoryKinds
	|
	|	LEFT JOIN TTRefundsToSuppliers AS RefundsToSuppliers
	|		ON RefundsToSuppliers.ItemsLocationAttributes = InventoryKinds.ItemsLocationAttributes
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON InventoryKinds.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND InventoryKinds.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND InventoryKinds.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND InventoryKinds.ItemsLocationAttributes.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|		AND InventoryKinds.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= InventoryKinds.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		Amounts.Ref = InventoryKinds.Ref
	|		AND Amounts.RowID = InventoryKinds.RowID
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|	AND &SeparatePurchase
	|	AND InventoryKinds.PostingOption =
	|		 VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners)
	|
	|UNION ALL
	|
	|SELECT
	|	DivergenceTable.LineNumber AS LineNumber,
	|	DivergenceTable.Products AS Products,
	|	DivergenceTable.Characteristic AS Characteristic,
	|	DivergenceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DivergenceTable.Purpose AS Purpose,
	|	DivergenceTable.Department AS Department,
	|	DivergenceTable.Ref.Department AS CapDivision,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	DivergenceTable.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	DivergenceTable.CCDNumber AS CCDNumber,
	|	-DivergenceTable.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE -DivergenceTable.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	-DivergenceTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	DivergenceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DivergenceTable.RowID AS RowID,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	DivergenceTable.VATRate AS VATRate,
	|
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN -(Amounts.AmountGivenMan + Amounts.VATAmountMan)
	|		ELSE ISNULL(-Amounts.AmountIncludingVATMan, 0) END) AS AmountIncludingVATMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN -Amounts.AmountGivenMan
	|		ELSE ISNULL(-Amounts.AmountExcludingVATMan, 0) END) AS AmountExcludingVATMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN -Amounts.AmountGivenCompl
	|		ELSE ISNULL(-Amounts.AmountExcludingVATCompl, 0) END) AS AmountExcludingVATCompl,
	|	ISNULL(-Amounts.VATAmountCompl, 0) AS VATAmountCompl,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl - Amounts.AmountExcludingVATCompl
	|		ELSE 0 END) AS CostTD,
	|
	|	CASE
	|		WHEN DivergenceTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		ELSE CASE
	|			WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|				THEN -Amounts.AmountGivenCompl
	|			ELSE ISNULL(-Amounts.AmountExcludingVATCompl, 0) END
	|	END AS LocalCost,
	|	CASE
	|		WHEN DivergenceTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		ELSE CASE
	|			WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|				THEN -Amounts.AmountGivenMan
	|			ELSE ISNULL(-Amounts.AmountExcludingVATMan, 0) END
	|	END AS CostMan,
	|	CASE
	|		WHEN DivergenceTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		ELSE CASE
	|			WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|				THEN -Amounts.AmountGivenCompl
	|			ELSE ISNULL(-Amounts.AmountExcludingVATCompl, 0) END
	|	END AS AddExpensesLocal,
	|	CASE
	|		WHEN DivergenceTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		ELSE CASE
	|			WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|				THEN -Amounts.AmountGivenMan
	|			ELSE ISNULL(-Amounts.AmountExcludingVATMan, 0) END
	|	END AS AddExpensesMan,
	|
	|	DivergenceTable.Warehouse AS Warehouse,
	|	DivergenceTable.Warehouse.ShopFloorStockroom AS ShopFloorStockroom,
	|	DivergenceTable.SalesOpportunity AS SalesOpportunity,
	|	DivergenceTable.VATAmount AS VATAmount,
	|	DivergenceTable.AmountARAP AS AmountARAP,
	|	DivergenceTable.AmountVATARAP AS AmountVATARAP,
	|	DivergenceTable.PurchaseOrder AS PurchaseOrder,
	|	CASE
	|		WHEN (BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|				OR DivergenceTable.AmountIncludingVAT <> 0)
	|			OR (BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|				AND DivergenceTable.Count <> 0)
	|			THEN ISNULL(RefundsToSuppliers.ThisIsRefundToSupplier, FALSE)
	|		ELSE TRUE
	|	END AS ThisIsRefundToSupplier,
	|
	|	VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier) AS BusinessTransactionSetting,
	|	DivergenceTable.ARAPObject.UUID AS FinRecordID,
	|	TRUE AS ThisIsTraceableWork
	|
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
	|	LEFT JOIN TTRefundsToSuppliers AS RefundsToSuppliers
	|		ON RefundsToSuppliers.ItemsLocationAttributes = DivergenceTable.ItemsLocationAttributes
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON DivergenceTable.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND DivergenceTable.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND DivergenceTable.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND DivergenceTable.ItemsLocationAttributes.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|		AND DivergenceTable.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= DivergenceTable.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Discrepancies""
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		Amounts.Ref = DivergenceTable.Ref
	|		AND Amounts.RowID = DivergenceTable.RowID
	|
	|WHERE
	|	DivergenceTable.Ref = &Ref
	// Traceable works.
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND DivergenceTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND DivergenceTable.Products.TracedGoods
	|	AND DivergenceTable.PostingOption =
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost)
	|	AND NOT DivergenceTable.ToExpenseAs
	|	AND NOT &BusinessTransactionGrounds = VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment)
	|	AND DivergenceTable.Count <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableReceivedReturnablePackaging(Query, QueryTexts, Registers)
	RegisterName = "ReceivedReturnablePackaging";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	If Not DocumentsPosting.ThereIsQueryTable("TTProductDiscrepancyTable", QueryTexts) Then
		QueryTextTTProductDiscrepancyTable(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	GoodsTable.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Count               AS Count,
	|	GoodsTable.AmountIncludingVAT                AS Sum,
	|	&Partner                               AS Partner,
	|	&DocumentBasis                     AS DocumentInflow,
	|	&PackageDepositIsRequired                  AS DepositIsRequired,
	|
	|	CASE
	|		WHEN &PackageDepositIsRequired
	|			THEN &IDOfUnusedFinRecord
	|		ELSE GoodsTable.FinRecordID
	|	END AS FinRecordID,
	|	GoodsTable.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	TTProductDiscrepancyTable AS GoodsTable
	|WHERE
	|	GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND GoodsTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|	AND &ToReturnReusablePackage
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers)
	
	RegisterName = "DatesOfCompanyGoodsReceipt";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryRegistration", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT DISTINCT
	|	&Period							  AS DateOfReceipt,
	|	TableTypesOfStocks_.Products   AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.Series          AS Series,
	|	TableTypesOfStocks_.Purpose     AS Purpose,
	|	TableTypesOfStocks_.InventoryOwnerAttribute     AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber       AS CCDNumber
	|FROM
	|	TTTableTypesOfInventoryRegistration AS TableTypesOfStocks_
	|
	|	LEFT JOIN
	|		InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|	ON
	|		TableTypesOfStocks_.InventoryOwnerAttribute		= UninvoicedReceipts.InventoryOwnerAttribute 
	|		AND TableTypesOfStocks_.Products	= UninvoicedReceipts.Products
	|		AND TableTypesOfStocks_.Characteristic = UninvoicedReceipts.Characteristic
	|		AND TableTypesOfStocks_.Series          = UninvoicedReceipts.Series
	|		AND TableTypesOfStocks_.Purpose     = UninvoicedReceipts.Purpose
	|		AND TableTypesOfStocks_.CCDNumber		= UninvoicedReceipts.CCDNumber 
	|
	|WHERE
	|	(UninvoicedReceipts.DateOfReceipt IS NULL
	|		OR UninvoicedReceipts.DateOfReceipt < &Period)
	// This is a traceable work regardless of the acceptance scheme, or the item (container) according to the one-way scheme.
	|	AND (
	|		(NOT &UninvoicedReceiptDocumentIsUsed
	|			AND TableTypesOfStocks_.Products.ItemsType IN (VALUE(Enum.ItemsTypes.ReusablePackage),
	|																 VALUE(Enum.ItemsTypes.OwnGoods)))
	|		OR TableTypesOfStocks_.ThisIsTraceableWork)
	|
	|ORDER BY
	|	TableTypesOfStocks_.InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products,
	|	TableTypesOfStocks_.Characteristic,
	|	TableTypesOfStocks_.Series,
	|	TableTypesOfStocks_.Purpose,
	|	TableTypesOfStocks_.CCDNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTProductsOfOrganizations(Query, QueryTexts) Export
	
	TableName = "TTProductsOfOrganizations";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryRegistration", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts);
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryWriteOff", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryWriteOff(Query, QueryTexts);
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TTNomenclatureParameters", QueryTexts) Then
		QueryTextTTNomenclatureParameters(Query, QueryTexts);
	EndIf;

	QueryText =
	"SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	UNDEFINED AS ShipmentCompany,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumber.CCDNumberType AS CCDNumberCCDNumberType,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&BusinessOperation AS BusinessOperation,
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|	TRUE AS Primary,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	TableTypesOfStocks_.VATRate
	|INTO TTProductsOfOrganizations
	|FROM
	|	TTTableTypesOfInventoryRegistration AS TableTypesOfStocks_
	|WHERE
	|	NOT &UninvoicedReceiptDocumentIsUsed
	|	AND NOT TableTypesOfStocks_.ThisIsTraceableWork
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber,
	|	VALUE(AccumulationRecordType.Expense),
	|	&Period,
	|	&Organization,
	|	&Organization,
	|	TableTypesOfStocks_.Products,
	|	TableTypesOfStocks_.Characteristic,
	|	TableTypesOfStocks_.InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber,
	|	TableTypesOfStocks_.CCDNumber.CCDNumberType,
	|	TableTypesOfStocks_.Count,
	|	TableTypesOfStocks_.QuantityByGBRN,
	|	TableTypesOfStocks_.ItemsLocationAttributes,
	|	&BusinessOperation,
	|	TableTypesOfStocks_.VATActivityType,
	|	FALSE,
	|	TableTypesOfStocks_.RowID,
	|	TableTypesOfStocks_.VATRate
	|FROM
	|	TTTableTypesOfInventoryWriteOff AS TableTypesOfStocks_
	|WHERE
	|	NOT &UninvoicedReceiptDocumentIsUsed
	|	AND NOT TableTypesOfStocks_.ThisIsTraceableWork
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	UNDEFINED AS ShipmentCompany,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumber.CCDNumberType,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	DimensionByBusinessUnits.DimensionKey AS ItemsLocationAttributes,
	|	&BusinessOperation AS BusinessOperation,
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|	TRUE AS Primary,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	TableTypesOfStocks_.VATRate
	|FROM
	|	TTTableTypesOfInventoryRegistration AS TableTypesOfStocks_
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionByBusinessUnits
	|	ON DimensionByBusinessUnits.Products = TableTypesOfStocks_.Products
	|		AND DimensionByBusinessUnits.Characteristic = TableTypesOfStocks_.Characteristic
	|		AND DimensionByBusinessUnits.Series = TableTypesOfStocks_.ItemsLocationAttributes.Series
	|		AND DimensionByBusinessUnits.Purpose = TableTypesOfStocks_.Purpose
	|		AND DimensionByBusinessUnits.ProductCostElement = TableTypesOfStocks_.ItemsLocationAttributes.ProductCostElement
	|		AND DimensionByBusinessUnits.StorageLocation = 
	|			CASE
	|				WHEN &UnfacturedDeliveriesOfServicesWorks
	|					THEN
	|						TableTypesOfStocks_.CapDivision
	|					ELSE
	|						TableTypesOfStocks_.Department
	|			END
	|WHERE
	|	TableTypesOfStocks_.ThisIsTraceableWork
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber,
	|	VALUE(AccumulationRecordType.Expense),
	|	&Period,
	|	&Organization,
	|	&Organization,
	|	TableTypesOfStocks_.Products,
	|	TableTypesOfStocks_.Characteristic,
	|	TableTypesOfStocks_.InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber,
	|	TableTypesOfStocks_.CCDNumber.CCDNumberType,
	|	TableTypesOfStocks_.Count,
	|	TableTypesOfStocks_.QuantityByGBRN,
	|	DimensionByBusinessUnits.DimensionKey,
	|	&BusinessOperation,
	|	TableTypesOfStocks_.VATActivityType,
	|	FALSE,
	|	TableTypesOfStocks_.RowID,
	|	TableTypesOfStocks_.VATRate
	|FROM
	|	TTTableTypesOfInventoryWriteOff AS TableTypesOfStocks_
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionByBusinessUnits
	|	ON DimensionByBusinessUnits.Products = TableTypesOfStocks_.Products
	|		AND DimensionByBusinessUnits.Characteristic = TableTypesOfStocks_.Characteristic
	|		AND DimensionByBusinessUnits.Series = TableTypesOfStocks_.ItemsLocationAttributes.Series
	|		AND DimensionByBusinessUnits.Purpose = TableTypesOfStocks_.Purpose
	|		AND DimensionByBusinessUnits.ProductCostElement = TableTypesOfStocks_.ItemsLocationAttributes.ProductCostElement
	|		AND DimensionByBusinessUnits.StorageLocation = 
	|			CASE
	|				WHEN &UnfacturedDeliveriesOfServicesWorks
	|					THEN
	|						TableTypesOfStocks_.CapDivision
	|					ELSE
	|						TableTypesOfStocks_.Department
	|			END
	|WHERE
	|	TableTypesOfStocks_.ThisIsTraceableWork
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentTable.LineNumber,
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Period,
	|	&Organization,
	|	UNDEFINED,
	|	DocumentTable.ItemsLocationAttributes.Products,
	|	DocumentTable.ItemsLocationAttributes.Characteristic,
	|	DocumentTable.InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	VALUE(Enum.CCDNumberTypes.EmptyRef),
	|	DocumentTable.Count,
	|	0 AS QuantityByGBRN,
	|	AnalysisOfProductAccountingByPartners.DimensionKey,
	|	&BusinessOperation,
	|	UNDEFINED,
	|	FALSE,
	|	DocumentTable.RowID,
	|	DocumentTable.VATRate
	|FROM
	|	Document.PurchaseAdjustment.InventoryKinds AS DocumentTable
	|		INNER JOIN Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
	|		ON DocumentTable.Ref = DivergenceTable.Ref
	|			AND DocumentTable.RowCode = DivergenceTable.RowCode
	|			AND DocumentTable.PurchaseOrder = DivergenceTable.PurchaseOrder
	|			AND DocumentTable.ItemsLocationAttributes.Products = DivergenceTable.Products
	|			AND DocumentTable.ItemsLocationAttributes.Characteristic = DivergenceTable.Characteristic
	|			AND DocumentTable.ItemsLocationAttributes.Purpose = DivergenceTable.Purpose
	|			AND (DocumentTable.ItemsLocationAttributes.Series = DivergenceTable.Series
	|				OR DivergenceTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND DocumentTable.PostingOption = DivergenceTable.PostingOption
	|			AND DocumentTable.CCDNumber = DivergenceTable.CCDNumber
	|		INNER JOIN Document.VendorInvoice AS ReceiptData
	|		ON DocumentTable.Ref.DocumentBasis = ReceiptData.Ref
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalysisOfProductAccountingByPartners
	|		ON DocumentTable.ItemsLocationAttributes.Products = AnalysisOfProductAccountingByPartners.Products
	|			AND DocumentTable.ItemsLocationAttributes.Characteristic = AnalysisOfProductAccountingByPartners.Characteristic
	|			AND DocumentTable.ItemsLocationAttributes.Purpose = AnalysisOfProductAccountingByPartners.Purpose
	|			AND DocumentTable.ItemsLocationAttributes.Series = AnalysisOfProductAccountingByPartners.Series
	|			AND (ReceiptData.Contract = AnalysisOfProductAccountingByPartners.StorageLocation)
	|			AND DocumentTable.ItemsLocationAttributes.ProductCostElement = AnalysisOfProductAccountingByPartners.ProductCostElement
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND &UninvoicedReceiptDocumentIsUsed
	|	AND DocumentTable.PostingOption IN (VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners), VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners))
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentTable.LineNumber,
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Period,
	|	&Organization,
	|	UNDEFINED,
	|	DocumentTable.ItemsLocationAttributes.Products,
	|	DocumentTable.ItemsLocationAttributes.Characteristic,
	|	TypesOfStocksWarehouse.Ref,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	VALUE(Enum.CCDNumberTypes.EmptyRef),
	|	-DocumentTable.Count AS Count,
	|	0 AS QuantityByGBRN,
	|	InventoryInventoryLocationAttributeByWarehouse.DimensionKey,
	|	&BusinessOperation,
	|	UNDEFINED,
	|	FALSE,
	|	DocumentTable.RowID,
	|	DocumentTable.VATRate
	|FROM
	|	Document.PurchaseAdjustment.InventoryKinds AS DocumentTable
	|		INNER JOIN Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
	|		ON DocumentTable.Ref = DivergenceTable.Ref
	|			AND DocumentTable.RowCode = DivergenceTable.RowCode
	|			AND DocumentTable.PurchaseOrder = DivergenceTable.PurchaseOrder
	|			AND DocumentTable.ItemsLocationAttributes.Products = DivergenceTable.Products
	|			AND DocumentTable.ItemsLocationAttributes.Characteristic = DivergenceTable.Characteristic
	|			AND DocumentTable.ItemsLocationAttributes.Purpose = DivergenceTable.Purpose
	|			AND (DocumentTable.ItemsLocationAttributes.Series = DivergenceTable.Series
	|				OR DivergenceTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND DocumentTable.CCDNumber = DivergenceTable.CCDNumber
	|		INNER JOIN Document.VendorInvoice AS ReceiptData
	|		ON DocumentTable.Ref.DocumentBasis = ReceiptData.Ref
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS InventoryInventoryLocationAttributeByWarehouse
	|		ON DocumentTable.ItemsLocationAttributes.Products = InventoryInventoryLocationAttributeByWarehouse.Products
	|			AND DocumentTable.ItemsLocationAttributes.Characteristic = InventoryInventoryLocationAttributeByWarehouse.Characteristic
	|			AND DocumentTable.ItemsLocationAttributes.Purpose = InventoryInventoryLocationAttributeByWarehouse.Purpose
	|			AND DocumentTable.ItemsLocationAttributes.Series = InventoryInventoryLocationAttributeByWarehouse.Series
	|			AND (DivergenceTable.Warehouse = InventoryInventoryLocationAttributeByWarehouse.StorageLocation)
	|			AND DocumentTable.ItemsLocationAttributes.ProductCostElement = InventoryInventoryLocationAttributeByWarehouse.ProductCostElement
	|		LEFT JOIN Catalog.InventoryKinds AS TypesOfStocksWarehouse
	|		ON TypesOfStocksWarehouse.Organization = DocumentTable.InventoryOwnerAttribute.Organization
	|			AND TypesOfStocksWarehouse.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|			AND TypesOfStocksWarehouse.GoodsOwner = DocumentTable.InventoryOwnerAttribute.GoodsOwner
	|			AND TypesOfStocksWarehouse.VATTaxation = DocumentTable.InventoryOwnerAttribute.VATTaxation
	|			AND TypesOfStocksWarehouse.FinancialAccountingGroup = DocumentTable.InventoryOwnerAttribute.FinancialAccountingGroup
	|			AND TypesOfStocksWarehouse.ProductsGroup = DocumentTable.InventoryOwnerAttribute.ProductsGroup
	|			AND TypesOfStocksWarehouse.PriceKind = DocumentTable.InventoryOwnerAttribute.PriceKind
	|			AND TypesOfStocksWarehouse.SubjectToExcise = DocumentTable.InventoryOwnerAttribute.SubjectToExcise
	|			AND NOT TypesOfStocksWarehouse.IsDuplicate
	|			AND NOT TypesOfStocksWarehouse.Obsolete1
	|			AND NOT TypesOfStocksWarehouse.DeletionMark
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND &UninvoicedReceiptDocumentIsUsed
	|	AND DocumentTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentTable.LineNumber,
	|	VALUE(AccumulationRecordType.Expense),
	|	&Period,
	|	&Organization,
	|	UNDEFINED,
	|	DocumentTable.ItemsLocationAttributes.Products,
	|	DocumentTable.ItemsLocationAttributes.Characteristic,
	|	TypesOfStocksWarehouse.Ref,
	|	DocumentTable.CCDNumber AS CCDNumber,
	|	DocumentTable.CCDNumber.CCDNumberType,
	|	-DocumentTable.Count AS Count,
	|	-DocumentTable.QuantityByGBRN AS QuantityByGBRN,
	|	InventoryInventoryLocationAttributeByWarehouse.DimensionKey,
	|	&BusinessOperation,
	|	UNDEFINED,
	|	FALSE,
	|	DocumentTable.RowID,
	|	DocumentTable.VATRate
	|FROM
	|	Document.PurchaseAdjustment.InventoryKinds AS DocumentTable
	|		INNER JOIN Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
	|		ON DocumentTable.Ref = DivergenceTable.Ref
	|			AND DocumentTable.RowCode = DivergenceTable.RowCode
	|			AND DocumentTable.PurchaseOrder = DivergenceTable.PurchaseOrder
	|			AND DocumentTable.ItemsLocationAttributes.Products = DivergenceTable.Products
	|			AND DocumentTable.ItemsLocationAttributes.Characteristic = DivergenceTable.Characteristic
	|			AND DocumentTable.ItemsLocationAttributes.Purpose = DivergenceTable.Purpose
	|			AND (DocumentTable.ItemsLocationAttributes.Series = DivergenceTable.Series
	|				OR DivergenceTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND DocumentTable.CCDNumber = DivergenceTable.CCDNumber
	|		INNER JOIN Document.VendorInvoice AS ReceiptData
	|		ON DocumentTable.Ref.DocumentBasis = ReceiptData.Ref
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS InventoryInventoryLocationAttributeByWarehouse
	|		ON DocumentTable.ItemsLocationAttributes.Products = InventoryInventoryLocationAttributeByWarehouse.Products
	|			AND DocumentTable.ItemsLocationAttributes.Characteristic = InventoryInventoryLocationAttributeByWarehouse.Characteristic
	|			AND DocumentTable.ItemsLocationAttributes.Purpose = InventoryInventoryLocationAttributeByWarehouse.Purpose
	|			AND DocumentTable.ItemsLocationAttributes.Series = InventoryInventoryLocationAttributeByWarehouse.Series
	|			AND (DivergenceTable.Warehouse = InventoryInventoryLocationAttributeByWarehouse.StorageLocation)
	|			AND DocumentTable.ItemsLocationAttributes.ProductCostElement = InventoryInventoryLocationAttributeByWarehouse.ProductCostElement
	|		LEFT JOIN Catalog.InventoryKinds AS TypesOfStocksWarehouse
	|		ON TypesOfStocksWarehouse.Organization = DocumentTable.InventoryOwnerAttribute.Organization
	|			AND TypesOfStocksWarehouse.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|			AND TypesOfStocksWarehouse.GoodsOwner = DocumentTable.InventoryOwnerAttribute.GoodsOwner
	|			AND TypesOfStocksWarehouse.VATTaxation = DocumentTable.InventoryOwnerAttribute.VATTaxation
	|			AND TypesOfStocksWarehouse.FinancialAccountingGroup = DocumentTable.InventoryOwnerAttribute.FinancialAccountingGroup
	|			AND TypesOfStocksWarehouse.ProductsGroup = DocumentTable.InventoryOwnerAttribute.ProductsGroup
	|			AND TypesOfStocksWarehouse.PriceKind = DocumentTable.InventoryOwnerAttribute.PriceKind
	|			AND TypesOfStocksWarehouse.SubjectToExcise = DocumentTable.InventoryOwnerAttribute.SubjectToExcise
	|			AND NOT TypesOfStocksWarehouse.IsDuplicate
	|			AND NOT TypesOfStocksWarehouse.Obsolete1
	|			AND NOT TypesOfStocksWarehouse.DeletionMark
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND &UninvoicedReceiptDocumentIsUsed
	|	AND DocumentTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentTable.LineNumber,
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Period,
	|	&Organization,
	|	UNDEFINED,
	|	DocumentTable.ItemsLocationAttributes.Products,
	|	DocumentTable.ItemsLocationAttributes.Characteristic,
	|	TypesOfStocksWarehouse.Ref,
	|	DocumentTable.CCDNumber AS CCDNumber,
	|	DocumentTable.CCDNumber.CCDNumberType,
	|	DocumentTable.Count AS Count,
	|	DocumentTable.QuantityByGBRN AS QuantityByGBRN,
	|	InventoryInventoryLocationAttributeByWarehouse.DimensionKey,
	|	&BusinessOperation,
	|	UNDEFINED,
	|	FALSE,
	|	DocumentTable.RowID,
	|	DocumentTable.VATRate
	|FROM
	|	Document.PurchaseAdjustment.InventoryKinds AS DocumentTable
	|		INNER JOIN Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
	|		ON DocumentTable.Ref = DivergenceTable.Ref
	|			AND DocumentTable.RowCode = DivergenceTable.RowCode
	|			AND DocumentTable.PurchaseOrder = DivergenceTable.PurchaseOrder
	|			AND DocumentTable.ItemsLocationAttributes.Products = DivergenceTable.Products
	|			AND DocumentTable.ItemsLocationAttributes.Characteristic = DivergenceTable.Characteristic
	|			AND DocumentTable.ItemsLocationAttributes.Purpose = DivergenceTable.Purpose
	|			AND (DocumentTable.ItemsLocationAttributes.Series = DivergenceTable.Series
	|				OR DivergenceTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND DocumentTable.CCDNumber = DivergenceTable.CCDNumber
	|		INNER JOIN Document.VendorInvoice AS ReceiptData
	|		ON DocumentTable.Ref.DocumentBasis = ReceiptData.Ref
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS InventoryInventoryLocationAttributeByWarehouse
	|		ON DocumentTable.ItemsLocationAttributes.Products = InventoryInventoryLocationAttributeByWarehouse.Products
	|			AND DocumentTable.ItemsLocationAttributes.Characteristic = InventoryInventoryLocationAttributeByWarehouse.Characteristic
	|			AND DocumentTable.ItemsLocationAttributes.Purpose = InventoryInventoryLocationAttributeByWarehouse.Purpose
	|			AND DocumentTable.ItemsLocationAttributes.Series = InventoryInventoryLocationAttributeByWarehouse.Series
	|			AND (DivergenceTable.Warehouse = InventoryInventoryLocationAttributeByWarehouse.StorageLocation)
	|			AND DocumentTable.ItemsLocationAttributes.ProductCostElement = InventoryInventoryLocationAttributeByWarehouse.ProductCostElement
	|		LEFT JOIN Catalog.InventoryKinds AS TypesOfStocksWarehouse
	|		ON TypesOfStocksWarehouse.Organization = DocumentTable.InventoryOwnerAttribute.Organization
	|			AND TypesOfStocksWarehouse.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|			AND TypesOfStocksWarehouse.GoodsOwner = DocumentTable.InventoryOwnerAttribute.GoodsOwner
	|			AND TypesOfStocksWarehouse.VATTaxation = DocumentTable.InventoryOwnerAttribute.VATTaxation
	|			AND TypesOfStocksWarehouse.FinancialAccountingGroup = DocumentTable.InventoryOwnerAttribute.FinancialAccountingGroup
	|			AND TypesOfStocksWarehouse.ProductsGroup = DocumentTable.InventoryOwnerAttribute.ProductsGroup
	|			AND TypesOfStocksWarehouse.PriceKind = DocumentTable.InventoryOwnerAttribute.PriceKind
	|			AND TypesOfStocksWarehouse.SubjectToExcise = DocumentTable.InventoryOwnerAttribute.SubjectToExcise
	|			AND NOT TypesOfStocksWarehouse.IsDuplicate
	|			AND NOT TypesOfStocksWarehouse.Obsolete1
	|			AND NOT TypesOfStocksWarehouse.DeletionMark
	|		INNER JOIN TTNomenclatureParameters AS SeriesStatusData
	|		ON DocumentTable.Ref = SeriesStatusData.Ref
	|			AND DocumentTable.ItemsLocationAttributes.Products = SeriesStatusData.Products
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND &UninvoicedReceiptDocumentIsUsed
	|	AND DocumentTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners)
	// There is no surplus on goods in transit with batches at cost price.
	|	AND NOT (
	|			DocumentTable.Ref.Contract <> VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DocumentTable.Ref.Contract.PurchaseRegistrationOption = VALUE(Enum.PurchaseRegistrationOptions.GoodsInTransit)
	|			AND (SeriesStatusData.AccountingOfSeriesAtCost
	|				AND NOT (SeriesStatusData.BatchesAccountingInUninvoicedGoodsDeliveries
	|				OR SeriesStatusData.BatchesAccountingOfGoodsInTransitFromVendor))
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentTable.LineNumber,
	|	VALUE(AccumulationRecordType.Expense),
	|	&Period,
	|	&Organization,
	|	UNDEFINED,
	|	DocumentTable.ItemsLocationAttributes.Products,
	|	DocumentTable.ItemsLocationAttributes.Characteristic,
	|	TypesOfStocksWarehouse.Ref,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	VALUE(Enum.CCDNumberTypes.EmptyRef),
	|	DocumentTable.Count AS Count,
	|	0 AS QuantityByGBRN,
	|	InventoryInventoryLocationAttributeByWarehouse.DimensionKey,
	|	&BusinessOperation,
	|	UNDEFINED,
	|	FALSE,
	|	DocumentTable.RowID,
	|	DocumentTable.VATRate
	|FROM
	|	Document.PurchaseAdjustment.InventoryKinds AS DocumentTable
	|		INNER JOIN Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
	|		ON DocumentTable.Ref = DivergenceTable.Ref
	|			AND DocumentTable.RowCode = DivergenceTable.RowCode
	|			AND DocumentTable.PurchaseOrder = DivergenceTable.PurchaseOrder
	|			AND DocumentTable.ItemsLocationAttributes.Products = DivergenceTable.Products
	|			AND DocumentTable.ItemsLocationAttributes.Characteristic = DivergenceTable.Characteristic
	|			AND DocumentTable.ItemsLocationAttributes.Purpose = DivergenceTable.Purpose
	|			AND (DocumentTable.ItemsLocationAttributes.Series = DivergenceTable.Series
	|				OR DivergenceTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND DocumentTable.CCDNumber = DivergenceTable.CCDNumber
	|		INNER JOIN Document.VendorInvoice AS ReceiptData
	|		ON DocumentTable.Ref.DocumentBasis = ReceiptData.Ref
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS InventoryInventoryLocationAttributeByWarehouse
	|		ON DocumentTable.ItemsLocationAttributes.Products = InventoryInventoryLocationAttributeByWarehouse.Products
	|			AND DocumentTable.ItemsLocationAttributes.Characteristic = InventoryInventoryLocationAttributeByWarehouse.Characteristic
	|			AND DocumentTable.ItemsLocationAttributes.Purpose = InventoryInventoryLocationAttributeByWarehouse.Purpose
	|			AND DocumentTable.ItemsLocationAttributes.Series = InventoryInventoryLocationAttributeByWarehouse.Series
	|			AND (DivergenceTable.Warehouse = InventoryInventoryLocationAttributeByWarehouse.StorageLocation)
	|			AND DocumentTable.ItemsLocationAttributes.ProductCostElement = InventoryInventoryLocationAttributeByWarehouse.ProductCostElement
	|		LEFT JOIN Catalog.InventoryKinds AS TypesOfStocksWarehouse
	|		ON TypesOfStocksWarehouse.Organization = DocumentTable.InventoryOwnerAttribute.Organization
	|			AND TypesOfStocksWarehouse.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|			AND TypesOfStocksWarehouse.GoodsOwner = DocumentTable.InventoryOwnerAttribute.GoodsOwner
	|			AND TypesOfStocksWarehouse.VATTaxation = DocumentTable.InventoryOwnerAttribute.VATTaxation
	|			AND TypesOfStocksWarehouse.FinancialAccountingGroup = DocumentTable.InventoryOwnerAttribute.FinancialAccountingGroup
	|			AND TypesOfStocksWarehouse.ProductsGroup = DocumentTable.InventoryOwnerAttribute.ProductsGroup
	|			AND TypesOfStocksWarehouse.PriceKind = DocumentTable.InventoryOwnerAttribute.PriceKind
	|			AND TypesOfStocksWarehouse.SubjectToExcise = DocumentTable.InventoryOwnerAttribute.SubjectToExcise
	|			AND NOT TypesOfStocksWarehouse.IsDuplicate
	|			AND NOT TypesOfStocksWarehouse.Obsolete1
	|			AND NOT TypesOfStocksWarehouse.DeletionMark
	|		INNER JOIN TTNomenclatureParameters AS SeriesStatusData
	|		ON DocumentTable.Ref = SeriesStatusData.Ref
	|			AND DocumentTable.ItemsLocationAttributes.Products = SeriesStatusData.Products
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND &UninvoicedReceiptDocumentIsUsed
	|	AND DocumentTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners)
	// There is no surplus on goods in transit with batches at cost price.
	|	AND NOT (
	|			DocumentTable.Ref.Contract <> VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DocumentTable.Ref.Contract.PurchaseRegistrationOption = VALUE(Enum.PurchaseRegistrationOptions.GoodsInTransit)
	|			AND (SeriesStatusData.AccountingOfSeriesAtCost
	|				AND NOT (SeriesStatusData.BatchesAccountingInUninvoicedGoodsDeliveries
	|				OR SeriesStatusData.BatchesAccountingOfGoodsInTransitFromVendor))
	|	)
	|
	|INDEX BY
	|	CCDNumberCCDNumberType";
	
	QueryTexts.Add(QueryText, TableName);
	
	Return QueryText;
		
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers) Export
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("TTProductsOfOrganizations", QueryTexts) Then
		QueryTextTTProductsOfOrganizations(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	TTProductsOfOrganizations.LineNumber AS LineNumber,
	|	TTProductsOfOrganizations.RecordType AS RecordType,
	|	TTProductsOfOrganizations.Period AS Period,
	|	TTProductsOfOrganizations.Organization AS Organization,
	|	TTProductsOfOrganizations.ShipmentCompany AS ShipmentCompany,
	|	TTProductsOfOrganizations.Products AS Products,
	|	TTProductsOfOrganizations.Characteristic AS Characteristic,
	|	TTProductsOfOrganizations.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTProductsOfOrganizations.CCDNumber AS CCDNumber,
	|	SUM(TTProductsOfOrganizations.Count) AS Count,
	|	SUM(TTProductsOfOrganizations.QuantityByGBRN) AS QuantityByGBRN,
	|	TTProductsOfOrganizations.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTProductsOfOrganizations.BusinessOperation AS BusinessOperation,
	|	TTProductsOfOrganizations.VATTaxation AS VATTaxation,
	|	TTProductsOfOrganizations.Primary AS Primary
	|FROM
	|	TTProductsOfOrganizations AS TTProductsOfOrganizations
	|              
	|GROUP BY
	|	TTProductsOfOrganizations.LineNumber,
	|	TTProductsOfOrganizations.RecordType,
	|	TTProductsOfOrganizations.Period,
	|	TTProductsOfOrganizations.Organization,
	|	TTProductsOfOrganizations.ShipmentCompany,
	|	TTProductsOfOrganizations.Products,
	|	TTProductsOfOrganizations.Characteristic,
	|	TTProductsOfOrganizations.InventoryOwnerAttribute,
	|	TTProductsOfOrganizations.CCDNumber,
	|	TTProductsOfOrganizations.ItemsLocationAttributes,
	|	TTProductsOfOrganizations.BusinessOperation,
	|	TTProductsOfOrganizations.VATTaxation,
	|	TTProductsOfOrganizations.Primary
	|
	|HAVING
	|	SUM(TTProductsOfOrganizations.Count) <> 0
	|	OR SUM(TTProductsOfOrganizations.QuantityByGBRN) <> 0
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	If Not DocumentsPosting.ThereIsQueryTable("TTProductDiscrepancyTable", QueryTexts) Then
		QueryTextTTProductDiscrepancyTable(Query, QueryTexts);
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TTTableDebtAdjustment", QueryTexts) Then
		QueryTextTTTableDebtAdjustment(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN
	|			(CASE
	|				WHEN DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome)
	|				THEN &IncomeItem
	|				WHEN DivergenceTable.ToExpenseAs
	|				THEN DivergenceTable.IncomeItem
	|				ELSE &IncomeItem
	|			END) = VALUE(ChartOfCharacteristicTypes.IncomeItems.ProfitLossOfPreviousYears)
	|		THEN DATETIME(1,1,1)
	|		ELSE &AdjustmentPeriod_
	|	END AS AdjustmentPeriod_,
	|	CASE
	|		WHEN DivergenceTable.ToExpenseAs 
	|			THEN DivergenceTable.Department
	|		ELSE &Department
	|	END AS Department,
	|	CASE
	|		WHEN DivergenceTable.ToExpenseAs 
	|			THEN DivergenceTable.LineOfBusiness
	|		ELSE &LineOfBusiness
	|	END AS LineOfBusiness,
	|	CASE
	|		WHEN DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome)
	|			THEN &IncomeItem
	|		WHEN DivergenceTable.ToExpenseAs 
	|			THEN DivergenceTable.IncomeItem
	|		ELSE &IncomeItem
	|	END AS IncomeItem,
	|	CASE
	|		WHEN DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome)
	|			THEN &DimensionOfRevenue
	|		WHEN DivergenceTable.ToExpenseAs 
	|			THEN DivergenceTable.DimensionOfRevenue
	|		ELSE &DimensionOfRevenue
	|	END AS DimensionOfRevenue,
	|
	|	-DivergenceTable.AmountIncludingVATMan AS Sum,
	|	(CASE
	|		WHEN NOT &CompanyManagementAccounting
	|			THEN 0
	|		WHEN DivergenceTable.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				AND NOT &GenerateVATChargedWhenIncludingInCost
	|			THEN -AmountIncludingVATMan
	|		ELSE -DivergenceTable.AmountExcludingVATMan END) AS SumMan,
	|	(CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN 0
	|		WHEN DivergenceTable.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				AND NOT &GenerateVATChargedWhenIncludingInCost
	|			THEN -DivergenceTable.AmountIncludingVATCompl
	|		ELSE -DivergenceTable.AmountExcludingVATCompl END) AS SumCompl,
	|
	|	VALUE(Enum.BusinessTransactions.DebitNoteWithRecordingAsOtherIncome) AS BusinessOperation,
	|	
	|	DivergenceTable.RowID AS RowID,
	|	DivergenceTable.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.DebitNoteWithRecordingAsOtherIncome) AS BusinessTransactionSetting
	|
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|
	|WHERE
	|	&UseAccountingOfOtherIncomeExpenses
	|	AND DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|	AND (DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome)
	|			AND &IncomeItem <> UNDEFINED)
	|		OR (DivergenceTable.ToExpenseAs
	|			AND DivergenceTable.IncomeItem <> UNDEFINED)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN
	|			(CASE
	|				WHEN DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome)
	|				THEN &IncomeItem
	|				WHEN DivergenceTable.ToExpenseAs
	|				THEN DivergenceTable.IncomeItem
	|				ELSE &IncomeItem
	|			END) = VALUE(ChartOfCharacteristicTypes.IncomeItems.ProfitLossOfPreviousYears)
	|		THEN DATETIME(1,1,1)
	|		ELSE &AdjustmentPeriod_
	|	END AS AdjustmentPeriod_,
	|	CASE
	|		WHEN DivergenceTable.ToExpenseAs 
	|			THEN DivergenceTable.Department
	|		ELSE &Department
	|	END AS Department,
	|	CASE
	|		WHEN DivergenceTable.ToExpenseAs 
	|			THEN DivergenceTable.LineOfBusiness
	|		ELSE &LineOfBusiness
	|	END AS LineOfBusiness,
	|	CASE
	|		WHEN DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome)
	|			THEN &IncomeItem
	|		WHEN DivergenceTable.ToExpenseAs 
	|			THEN DivergenceTable.IncomeItem
	|		ELSE &IncomeItem
	|	END AS IncomeItem,
	|	CASE
	|		WHEN DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome)
	|			THEN &DimensionOfRevenue
	|		WHEN DivergenceTable.ToExpenseAs 
	|			THEN DivergenceTable.DimensionOfRevenue
	|		ELSE &DimensionOfRevenue
	|	END AS DimensionOfRevenue,
	|
	|	0 AS Sum,
	|	(CASE
	|		WHEN NOT &CompanyManagementAccounting
	|			THEN 0
	|		ELSE DivergenceTable.AmountExcludingVATMan - DivergenceTable.AmountIncludingVATMan END) AS SumMan,
	|	(CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN 0
	|		ELSE DivergenceTable.AmountExcludingVATCompl - DivergenceTable.AmountIncludingVATCompl END) AS SumCompl,
	|
	|	VALUE(Enum.BusinessTransactions.DebitNoteWithRecordingAsOtherIncome) AS BusinessOperation,
	|	
	|	DivergenceTable.RowID AS RowID,
	|	DivergenceTable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses) AS BusinessTransactionSetting
	|
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|
	|WHERE
	|	&UseAccountingOfOtherIncomeExpenses
	|	AND DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|	AND &GenerateVATChargedWhenIncludingInCost
	|	AND DivergenceTable.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|	AND (DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome)
	|			AND &IncomeItem <> UNDEFINED)
	|		OR (DivergenceTable.ToExpenseAs
	|			AND DivergenceTable.IncomeItem <> UNDEFINED)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN &ReflectRevenuesInCurrentPeriod
	|		THEN DATETIME(1,1,1)
	|		ELSE &AdjustmentPeriod_
	|	END AS AdjustmentPeriod_,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&IncomeItem AS IncomeItem,
	|	&DimensionOfRevenue AS DimensionOfRevenue,
	|
	|	ARAPAdjustment.AmountIncludingVATMan AS Sum,
	|	(CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN ARAPAdjustment.AmountIncludingVATMan
	|		ELSE 0 END) AS SumMan,
	|	(CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN ARAPAdjustment.AmountIncludingVATCompl
	|		ELSE 0 END) AS SumCompl,
	|
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	
	|	ARAPAdjustment.RowID AS RowID,
	|	ARAPAdjustment.UniqueIDOfSettlementObject AS FinRecordID,
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
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN &ReflectRevenuesInCurrentPeriod
	|		THEN DATETIME(1,1,1)
	|		ELSE &AdjustmentPeriod_
	|	END AS AdjustmentPeriod_,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&IncomeItem AS IncomeItem,
	|	&DimensionOfRevenue AS DimensionOfRevenue,
	|
	|	0 AS Sum,
	|	(CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN ARAPAdjustment.VATManag
	|		ELSE 0 END) AS SumMan,
	|	(CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN ARAPAdjustment.VATLocal
	|		ELSE 0 END) AS SumCompl,
	|
	|	VALUE(Enum.BusinessTransactions.IncomingVATOnAcquisition) AS BusinessOperation,
	|	
	|	ARAPAdjustment.RowID AS RowID,
	|	ARAPAdjustment.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|
	|FROM
	|	TTTableDebtAdjustment AS ARAPAdjustment
	|WHERE
	|	ARAPAdjustment.OnIncome
	|	AND &PurchaseForActivity NOT IN (&TypesOfTaxationVATIsIncludedInCost)
	|	AND (ARAPAdjustment.VATLocal <> 0
	|		OR ARAPAdjustment.VATManag <> 0)
	|
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductDiscrepancyTable", QueryTexts) Then
		QueryTextTTProductDiscrepancyTable(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableDebtAdjustment", QueryTexts) Then
		QueryTextTTTableDebtAdjustment(Query, QueryTexts);
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TTBatchProduction", QueryTexts) Then
		QueryTextTTBatchProduction(Query, QueryTexts);
	EndIf;
	QueryText = "
	|SELECT
	|	&Period											AS Period,
	|	VALUE(AccumulationRecordType.Receipt)			AS RecordType,
	|	CASE
	|		WHEN ExpenseItems.Ref = VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProfitLossOfPreviousYears)
	|		THEN DATETIME(1,1,1)
	|		ELSE &AdjustmentPeriod_
	|	END AS VariancePeriod,
	|	&Organization									AS Organization,
	// Filling in the Division, Expenditure articles, expenditure analytics, and activity
	// areas fields should be similar to the function of the Text Query table for the Expenditure items and other expenses().
	|	CASE WHEN DivergenceTable.ToExpenseAs
	|		OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|		DivergenceTable.Department
	|	ELSE
	|		&Department
	|	END											AS Department,
	|	ExpenseItems.Ref							AS ExpenseItem,
	|	CASE WHEN DivergenceTable.ToExpenseAs
	|		OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|		DivergenceTable.DimensionOfExpenses
	|	ELSE
	|		&DimensionOfExpenses
	|	END											AS DimensionOfExpenses,
	|	CASE WHEN DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|		DivergenceTable.LineOfBusiness
	|	ELSE
	|		&LineOfBusiness
	|	END											AS LineOfBusiness,
	|	DivergenceTable.VATActivityType 			AS VATActivityType,
	|	
	|	DivergenceTable.AmountIncludingVATMan					AS AmountIncludingVAT,
	|	DivergenceTable.AmountExcludingVATMan				AS AmountExcludingVAT,
	|	DivergenceTable.AmountExcludingVATMan				AS AmountExcludingVATMan,
	|
	|	DivergenceTable.AmountIncludingVATCompl 				AS AmountIncludingVATCompl,
	|	DivergenceTable.AmountExcludingVATCompl 				AS AmountExcludingVATCompl,
	|	0 												AS PermanentDifference,
	|	DivergenceTable.CostTD				AS CostTD,
	|
	|	&BusinessOperation 							AS BusinessOperation,
	|	DivergenceTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|
	|	DivergenceTable.RowID          AS RowID,
	|	DivergenceTable.FinRecordID       AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.DebitNoteWithWritingOffAsExpenses) AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|	
	|	INNER JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		CASE WHEN DivergenceTable.ToExpenseAs
	|			OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|			DivergenceTable.ExpenseItem
	|		ELSE
	|			&ExpenseItem
	|		END = ExpenseItems.Ref
	|	
	|WHERE
	|	DivergenceTable.ExpenseItem <> UNDEFINED
	|	AND DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)	
	|	AND CASE WHEN DivergenceTable.ToExpenseAs
	|		OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|		
	|		NOT &UnfacturedDeliveriesOfServicesWorks
	|		AND DivergenceTable.PostingOption IN (
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs),
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners),
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners),
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost),
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost))
	|	ELSE
	|		DivergenceTable.PostingOption IN (
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs))
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	CASE
	|		WHEN &ReflectExpensesInCurrentPeriod
	|		THEN DATETIME(1,1,1)
	|		ELSE &AdjustmentPeriod_
	|	END AS VariancePeriod,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&ExpenseItem AS ExpenseItem,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&PurchaseForActivity AS VATActivityType,
	|	
	|	ARAPAdjustment.AmountIncludingVATMan AS AmountIncludingVAT,
	|	ARAPAdjustment.AmountExcludingVATMan AS AmountExcludingVAT,
	|	ARAPAdjustment.AmountIncludingVATMan AS AmountExcludingVATMan,
	|
	|	ARAPAdjustment.AmountIncludingVATCompl AS AmountIncludingVATCompl,
	|	ARAPAdjustment.AmountIncludingVATCompl AS AmountExcludingVATCompl,
	|
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment)  AS BusinessOperation,
	|	UNDEFINED	AS ItemsLocationAttributes,
	|
	|	ARAPAdjustment.RowID AS RowID,
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
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	CASE
	|		WHEN &ReflectExpensesInCurrentPeriod
	|		THEN DATETIME(1,1,1)
	|		ELSE &AdjustmentPeriod_
	|	END AS VariancePeriod,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&ExpenseItem AS ExpenseItem,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&PurchaseForActivity AS VATActivityType,
	|	
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	ARAPAdjustment.VATManag AS AmountExcludingVATMan,
	|
	|	0 AS AmountIncludingVATCompl,
	|	ARAPAdjustment.VATLocal AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	VALUE(Enum.BusinessTransactions.IncomingVATOnAcquisition) AS BusinessOperation,
	|	UNDEFINED	AS ItemsLocationAttributes,
	|
	|	ARAPAdjustment.RowID AS RowID,
	|	ARAPAdjustment.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|
	|FROM
	|	TTTableDebtAdjustment AS ARAPAdjustment
	|WHERE
	|	ARAPAdjustment.ToExpenses
	|	AND &PurchaseForActivity NOT IN (&TypesOfTaxationVATIsIncludedInCost)
	|	AND (ARAPAdjustment.VATLocal <> 0
	|		OR ARAPAdjustment.VATManag <> 0)
	|
	// When adjusting the report of the processor of the previous period, the amount of the adjustment is attributed to the article ""Disposals of goods in previous periods"".
	|UNION ALL
	|
	|SELECT
	|	&Period											AS Period,
	|	VALUE(AccumulationRecordType.Receipt)			AS RecordType,
	|	&AdjustmentPeriod_							AS VariancePeriod,
	|	&Organization									AS Organization,
	|	&Department									AS Department,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.OutflowsOfGoodsInPastPeriods) AS ExpenseItem,
	|	DivergenceTable.Products					AS DimensionOfExpenses,
	|	ProductionLots.LineOfBusiness		AS LineOfBusiness,
	|	DivergenceTable.VATActivityType 			AS VATActivityType,
	|	
	|	DivergenceTable.AmountIncludingVATMan					AS AmountIncludingVAT,
	|	DivergenceTable.AmountExcludingVATMan				AS AmountExcludingVAT,
	|	DivergenceTable.AmountExcludingVATMan				AS AmountExcludingVATMan,
	|
	|	DivergenceTable.AmountIncludingVATCompl 				AS AmountIncludingVATCompl,
	|	DivergenceTable.AmountExcludingVATCompl 				AS AmountExcludingVATCompl,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|
	|	&BusinessOperation 							AS BusinessOperation,
	|	DivergenceTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|
	|	DivergenceTable.RowID          AS RowID,
	|	DivergenceTable.FinRecordID       AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.DebitNoteWithWritingOffAsExpenses) AS BusinessTransactionSetting
	|FROM
	|	Document.PurchaseAdjustment AS DocumentTable
	|
	|	INNER JOIN TTProductDiscrepancyTable AS DivergenceTable
	|	ON TRUE
	|
	|	LEFT JOIN TTBatchProduction AS ProductionLots
	|	ON ProductionLots.ReleaseParty = &DocumentBasis
	|	AND ProductionLots.CostGroupNumber = DivergenceTable.CostGroupNumber
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT DivergenceTable.ToExpenseAs
	|	AND NOT DivergenceTable.PostingOption IN (
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs),
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome))
	|	AND DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment)
	|	AND BEGINOFPERIOD(&ReceiptPeriod, MONTH) < BEGINOFPERIOD(&Period, MONTH)
	|	AND DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|";
	
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

Function QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers)
	
	RegisterName = "LotsOfGoodsOfOrganizations";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductDiscrepancyTable", QueryTexts) Then
		QueryTextTTProductDiscrepancyTable(Query, QueryTexts);
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryRegistration", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts);
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfInventoryWriteOff", QueryTexts) Then
		QueryTextTTTableTypesOfInventoryWriteOff(Query, QueryTexts);
	EndIf;
	
	SetRequestParameterVATReceiptDocument(Query);
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.LotVendorAttributes AS LotVendorAttributes,
	|	&VATReceiptDocument AS DocumentInflow,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.AmountIncludingVATMan AS Cost,
	|	TableTypesOfStocks_.AmountExcludingVATMan AS CostExcludingVAT,
	|	TableTypesOfStocks_.AmountExcludingVATCompl AS LocalCost,
	|	CASE 
	|		WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN 0
	|			ELSE TableTypesOfStocks_.VATAmountCompl
	|	END AS VATLocal,
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	&BusinessOperation AS BusinessOperation,
	|	TRUE AS Primary,
	|	UNDEFINED AS DocumentSource
	|FROM
	|	TTTableTypesOfInventoryRegistration AS TableTypesOfStocks_
	|WHERE
	|	&BatchAccountingVersion21
	|
	|UNION ALL
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.LotVendorAttributes AS LotVendorAttributes,
	|	&DocumentBasis AS DocumentInflow,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.AmountIncludingVATMan AS Cost,
	|	TableTypesOfStocks_.AmountExcludingVATMan AS CostExcludingVAT,
	|	TableTypesOfStocks_.AmountExcludingVATCompl AS LocalCost,
	|	CASE 
	|		WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN 0
	|			ELSE TableTypesOfStocks_.VATAmountCompl
	|	END AS VATLocal,
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	&BusinessOperation AS BusinessOperation,
	|	TRUE AS Primary,
	|	&DocumentBasis AS DocumentSource
	|FROM
	|	TTTableTypesOfInventoryWriteOff AS TableTypesOfStocks_
	|WHERE
	|	&BatchAccountingVersion21
	|	AND TableTypesOfStocks_.ThisIsRefundToSupplier
	|
	|UNION ALL
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.LotVendorAttributes AS LotVendorAttributes,
	|	&DocumentBasis AS DocumentInflow,
	|	-TableTypesOfStocks_.Count AS Count,
	|	-TableTypesOfStocks_.AmountIncludingVATMan AS Cost,
	|	-TableTypesOfStocks_.AmountExcludingVATMan AS CostExcludingVAT,
	|	-TableTypesOfStocks_.AmountExcludingVATCompl AS LocalCost,
	|	-TableTypesOfStocks_.VATAmountCompl AS VATLocal,
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	&BusinessOperation AS BusinessOperation,
	|	TRUE AS Primary,
	|	&DocumentBasis AS DocumentSource
	|FROM
	|	TTTableTypesOfInventoryWriteOff AS TableTypesOfStocks_
	|WHERE
	|	&BatchAccountingVersion21
	|	AND NOT TableTypesOfStocks_.ThisIsRefundToSupplier
	|
	|UNION ALL
	|SELECT
	|	DivergenceTable.LineNumber,
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Period,
	|	&Organization,
	|	DivergenceTable.ItemsLocationAttributes,
	|	DivergenceTable.InventoryOwnerAttribute,
	|	DivergenceTable.LotVendorAttributes,
	|	&DocumentBasis,
	|	DivergenceTable.Count,
	|	DivergenceTable.AmountIncludingVATMan,
	|	DivergenceTable.AmountExcludingVATMan,
	|	DivergenceTable.AmountExcludingVATCompl,
	|	CASE 
	|		WHEN DivergenceTable.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN 0
	|			ELSE DivergenceTable.VATAmountCompl
	|	END AS VATLocal,
	|	DivergenceTable.VATActivityType,
	|	DivergenceTable.Products,
	|	DivergenceTable.Characteristic,
	|	&BusinessOperation,
	|	TRUE AS Primary,
	|	UNDEFINED AS DocumentSource
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|WHERE
	|	&BatchAccountingVersion21
	|	AND DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost)
	|	AND DivergenceTable.Products.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction 

Function QueryTextTableExpenseBatchesToGoodsCost(Query, QueryTexts, Registers)
	
	RegisterName = "ExpenseBatchesToGoodsCost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductDiscrepancyTable", QueryTexts) Then
		QueryTextTTProductDiscrepancyTable(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	DivergenceTable.LineNumber,
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Period,
	|	&Organization,
	|	DivergenceTable.ItemsLocationAttributes,
	|	&DocumentBasis AS DocumentInflow,
	|	DivergenceTable.InventoryOwnerAttribute,
	|	DivergenceTable.LotVendorAttributes,
	|	&Ref AS ExpenseReceiptDocument,
	|	UNDEFINED AS ExpenseItem,
	|	DivergenceTable.AmountIncludingVATMan AS Cost,
	|	DivergenceTable.AmountExcludingVATMan AS CostExcludingVAT,
	|	DivergenceTable.AmountExcludingVATCompl AS LocalCost,
	|	CASE 
	|		WHEN DivergenceTable.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN 0
	|		ELSE DivergenceTable.VATAmountCompl
	|	END AS VATLocal,
	|	DivergenceTable.VATActivityType AS VATTaxation,
	|	&BusinessOperation AS BusinessOperation
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|WHERE
	|	&BatchAccountingVersion21
	|	AND DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost)
	|	AND DivergenceTable.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction 

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export

	QueryTextdata_ =
	"SELECT
	|	""Discrepancies"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.ARAPCurrency AS ARAPCurrency,
	|	DocumentTable.Ref.DocumentBasis.Date AS VATBasePeriod,
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
	|	CASE 
	|		WHEN DocumentTable.Ref.DocumentBasis REFS Document.SourceDocument
	|		THEN TRUE
	|		WHEN DocumentTable.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND DocumentTable.Ref.DocumentBasis.ToReturnReusablePackage
	|				AND NOT DocumentTable.Ref.DocumentBasis.PackageDepositIsRequired
	|		THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND (NOT &SeparatePurchase
	|		OR DocumentTable.Products.ItemsType IN (
	|				VALUE(Enum.ItemsTypes.OperationService), 
	|				VALUE(Enum.ItemsTypes.Work_5)))
	|
	|UNION ALL
	|
	|SELECT
	|	""InventoryKinds"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.ARAPCurrency AS ARAPCurrency,
	|	DocumentTable.Ref.DocumentBasis.Date AS VATBasePeriod,
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
	|	CASE 
	|		WHEN DocumentTable.Ref.DocumentBasis REFS Document.SourceDocument
	|		THEN TRUE
	|		WHEN DocumentTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND DocumentTable.Ref.DocumentBasis.ToReturnReusablePackage
	|				AND NOT DocumentTable.Ref.DocumentBasis.PackageDepositIsRequired
	|		THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.PurchaseAdjustment.InventoryKinds AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND &SeparatePurchase
	|
	|UNION ALL
	|
	|SELECT
	|	""DebtReduction_"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	ARAPAdjustment.Ref AS Ref,
	|	ARAPAdjustment.Ref.Date AS Date,
	|	ARAPAdjustment.Ref.Organization AS Organization,
	|	ARAPAdjustment.Ref.Currency AS DocumentCurrency,
	|	ARAPAdjustment.Ref.ARAPCurrency AS ARAPCurrency,
	|	ARAPAdjustment.Ref.Date AS VATBasePeriod,
	|	ARAPAdjustment.Ref.Date AS DateOfCourse,
	|
	|	ARAPAdjustment.LineNumber AS LineNumber,
	|	ARAPAdjustment.RowID AS RowID,
	|	-(ARAPAdjustment.AdjustmentSum - ARAPAdjustment.SumOfVATAdjustments) AS AmountExcludingVAT,
	|	ARAPAdjustment.VATRate AS VATRate,
	|	-(ARAPAdjustment.SumOfVATAdjustments) AS VATAmount,
	|	-(ARAPAdjustment.AmountARAP) AS AmountARAP,
	|	-(ARAPAdjustment.AmountVATARAP) AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	ARAPAdjustment.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.PurchaseAdjustment.ARAPAdjustment AS ARAPAdjustment
	|
	|WHERE
	|	ARAPAdjustment.Ref IN (&Ref)
	|	AND ARAPAdjustment.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated)
	|
	|UNION ALL
	|
	|SELECT
	|	""IncreaseInDebt"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	ARAPAdjustment.Ref AS Ref,
	|	ARAPAdjustment.Ref.Date AS Date,
	|	ARAPAdjustment.Ref.Organization AS Organization,
	|	ARAPAdjustment.Ref.Currency AS DocumentCurrency,
	|	ARAPAdjustment.Ref.ARAPCurrency AS ARAPCurrency,
	|	ARAPAdjustment.Ref.Date AS VATBasePeriod,
	|	ARAPAdjustment.Ref.Date AS DateOfCourse,
	|
	|	ARAPAdjustment.LineNumber AS LineNumber,
	|	ARAPAdjustment.RowID AS RowID,
	|	ARAPAdjustment.AdjustmentSum - ARAPAdjustment.SumOfVATAdjustments AS AmountExcludingVAT,
	|	ARAPAdjustment.VATRate AS VATRate,
	|	ARAPAdjustment.SumOfVATAdjustments AS VATAmount,
	|	ARAPAdjustment.AmountARAP AS AmountARAP,
	|	ARAPAdjustment.AmountVATARAP AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	ARAPAdjustment.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.PurchaseAdjustment.ARAPAdjustment AS ARAPAdjustment
	|
	|WHERE
	|	ARAPAdjustment.Ref IN (&Ref)
	|	AND ARAPAdjustment.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductDiscrepancyTable", QueryTexts) Then
		QueryTextTTProductDiscrepancyTable(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableDebtAdjustment", QueryTexts) Then
		QueryTextTTTableDebtAdjustment(Query, QueryTexts);
	EndIf;
	
	SetRequestParameterVATReceiptDocument(Query);
	
	QueryText = "
	// Cost of production costs
	|SELECT
	|	DivergenceTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	&Organization AS Organization,
	// Filling in the Division, Expenditure articles, expenditure analytics, and activity areas fields
	// should be similar to the function textquestiontablereferences().
	|	CASE WHEN DivergenceTable.ToExpenseAs
	|		OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|		DivergenceTable.Department
	|	ELSE
	|		&Department
	|	END											AS Department,
	|	&VATReceiptDocument AS ExpenseReceiptDocument,
	|	ExpenseItems.Ref AS ExpenseItem,
	|	CASE WHEN DivergenceTable.ToExpenseAs
	|	 OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|		DivergenceTable.DimensionOfExpenses
	|	ELSE
	|		&DimensionOfExpenses
	|	END AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	DivergenceTable.LotVendorAttributes AS LotVendorAttributes,
	|	CASE WHEN DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|		DivergenceTable.LineOfBusiness
	|	ELSE
	|		&LineOfBusiness
	|	END AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	DivergenceTable.VATActivityType AS VATActivityType,
	|
	|	DivergenceTable.AmountIncludingVATMan AS Cost,
	|	DivergenceTable.AmountExcludingVATMan AS CostExcludingVAT,
	|	DivergenceTable.VATAmountMan AS VATManag,
	|	DivergenceTable.AmountExcludingVATCompl AS LocalCost,
	|	0 AS PermanentDifference,
	|	DivergenceTable.CostTD AS CostTD,
	|	DivergenceTable.VATAmountCompl AS VATLocal,
	|	&BusinessOperation AS BusinessOperation,
	|
	|	DivergenceTable.RowID AS RowID,
	|	DivergenceTable.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.DebitNoteWithWritingOffAsExpenses) AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|	
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		CASE WHEN DivergenceTable.ToExpenseAs
	|			OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|			DivergenceTable.ExpenseItem
	|		ELSE
	|			&ExpenseItem
	|		END = ExpenseItems.Ref
	|WHERE
	|	DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|	AND CASE WHEN DivergenceTable.ToExpenseAs
	|		OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|		DivergenceTable.PostingOption IN (
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs),
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners),
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners),
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost),
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost))
	|	ELSE
	|		DivergenceTable.PostingOption IN (
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs))
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	ARAPAdjustment.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Ref AS ExpenseReceiptDocument,
	|	&ExpenseItem AS ExpenseItem,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	ARAPAdjustment.LotVendorAttributes AS LotVendorAttributes,
	|	&LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	&PurchaseForActivity AS VATActivityType,
	|
	|	ARAPAdjustment.AmountIncludingVATMan AS Cost,
	|	ARAPAdjustment.AmountIncludingVATMan AS CostExcludingVAT,
	|	0 AS VATManag,
	|	ARAPAdjustment.AmountIncludingVATCompl  AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS VATLocal,
	|	&BusinessOperation AS BusinessOperation,
	|
	|	ARAPAdjustment.RowID AS RowID,
	|	ARAPAdjustment.UniqueIDOfSettlementObject AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.DebitNoteWithWritingOffAsExpenses) AS BusinessTransactionSetting
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
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Ref AS ExpenseReceiptDocument,
	|	&ExpenseItem AS ExpenseItem,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	ARAPAdjustment.LotVendorAttributes AS LotVendorAttributes,
	|	&LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	&PurchaseForActivity AS VATActivityType,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS VATManag,
	|	ARAPAdjustment.VATLocal  AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS VATLocal,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|
	|	ARAPAdjustment.RowID AS RowID,
	|	ARAPAdjustment.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ARAPAdjustment) AS BusinessTransactionSetting
	|
	|FROM
	|	TTTableDebtAdjustment AS ARAPAdjustment
	|WHERE
	|	ARAPAdjustment.ToExpenses
	|	AND &PurchaseForActivity NOT IN (&TypesOfTaxationVATIsIncludedInCost)
	|	AND (ARAPAdjustment.VATLocal <> 0
	|		OR ARAPAdjustment.VATManag <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts) Export
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses("RowID,VariancePeriod");
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
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductDiscrepancyTable", QueryTexts) Then
		QueryTextTTProductDiscrepancyTable(Query, QueryTexts);
	EndIf;
	
	SetRequestParameterVATReceiptDocument(Query);
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots("RowID,VariancePeriod");
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers)
	RegisterName = "MaterialsAndWorksInProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	If Not DocumentsPosting.ThereIsQueryTable("TTProductDiscrepancyTable", QueryTexts) Then
		QueryTextTTProductDiscrepancyTable(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	DivergenceTable.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Period AS RecorderDate,
	|	&Organization AS Organization,
	|	DivergenceTable.Products,
	|	DivergenceTable.Characteristic,
	|	DivergenceTable.Purpose,
	|	DivergenceTable.Series,
	|	DivergenceTable.Department,
	|	DivergenceTable.ItemsLocationAttributes,
	|	DivergenceTable.Count
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|WHERE
	|	DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT DivergenceTable.ToExpenseAs
	|	AND DivergenceTable.Count <> 0
	|	AND NOT &BusinessTransactionGrounds = VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment)
	|	AND NOT &UnfacturedDeliveriesOfServicesWorks
	|	AND (DivergenceTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		OR DivergenceTable.Purpose.AssignmentType <> VALUE(Enum.AssignmentTypes.DeliveryForPrincipal))
	|	AND NOT DivergenceTable.PostingOption IN (
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs),
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome))
	|	AND NOT DivergenceTable.Products.TracedGoods
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextBatchesOfProductionCosts(Query, QueryTexts, Registers)
	RegisterName = "BatchesOfProductionCosts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductDiscrepancyTable", QueryTexts) Then
		QueryTextTTProductDiscrepancyTable(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	DivergenceTable.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	DivergenceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DivergenceTable.InventoryOwnerAttribute,
	|	DivergenceTable.LotVendorAttributes AS LotVendorAttributes,
	|	&DocumentBasis AS DocumentInflow,
	|
	|	DivergenceTable.Count AS Count,
	|	DivergenceTable.AmountIncludingVATMan AS Cost,
	|	DivergenceTable.AmountExcludingVATMan AS CostExcludingVAT,
	|	DivergenceTable.AmountExcludingVATCompl AS LocalCost,
	|	CASE 
	|		WHEN DivergenceTable.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN 0
	|		ELSE DivergenceTable.VATAmountCompl
	|	END AS VATLocal
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|WHERE
	|	DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND DivergenceTable.Count >= 0
	|	AND NOT DivergenceTable.ToExpenseAs
	|	AND NOT &BatchAccountingVersion22
	|	AND NOT DivergenceTable.PostingOption IN (
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs),
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome))
	|	AND DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	DivergenceTable.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	DivergenceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DivergenceTable.InventoryOwnerAttribute,
	|	DivergenceTable.LotVendorAttributes AS LotVendorAttributes,
	|	&DocumentBasis AS DocumentInflow,
	|
	|	-DivergenceTable.Count AS Count,
	|	-DivergenceTable.AmountIncludingVATMan AS Cost,
	|	-DivergenceTable.AmountExcludingVATMan AS CostExcludingVAT,
	|	-DivergenceTable.AmountExcludingVATCompl AS LocalCost,
	|	CASE 
	|		WHEN DivergenceTable.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN 0
	|		ELSE -DivergenceTable.VATAmountCompl
	|	END AS VATLocal
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|WHERE
	|	DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND DivergenceTable.Count < 0
	|	AND NOT DivergenceTable.ToExpenseAs
	|	AND NOT &BatchAccountingVersion22
	|	AND NOT DivergenceTable.PostingOption IN (
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs),
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome))
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTablePurchases(Query, QueryTexts, Registers)
	RegisterName = "Purchases";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductDiscrepancyTable", QueryTexts) Then
		QueryTextTTProductDiscrepancyTable(Query, QueryTexts);
	EndIf;
	
#Region IncreasedProcurement
	IncreasedProcurement = 
	"SELECT
	|	&Period AS Period,
	|	CASE
	|		WHEN TableTypesOfStocks_.ItemsLocationAttributes.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			THEN VALUE(Enum.BusinessTransactions.ReceivingForPrincipal)
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|			THEN VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit)
	|		ELSE 
	|			VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|	END AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|   TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Terms AS Terms,
	|	&Contract AS Contract,
	|	CASE 
	|		WHEN &ReceiptUnderOrders
	|			THEN TableTypesOfStocks_.PurchaseOrder
	|		ELSE &DocumentBasis
	|	END AS OrderDocument,
	|
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS ProductLineOfBusiness,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	TableTypesOfStocks_.Count AS Count,
	|
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN (Amounts.AmountGivenMan + Amounts.VATAmountMan)
	|		ELSE ISNULL(Amounts.AmountIncludingVATMan, 0) 
	|	END AS Sum,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan
	|		ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) 
	|	END AS AmountExcludingVAT,
	
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) 
	|	END + ISNULL(Amounts.VATAmountCompl, 0) AS SumCompl,
	
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) 
	|	END AS LocalAmountExcludingVAT,
	|	0 AS DiscountAmount,
	|
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN (Amounts.AmountGivenMan + Amounts.VATAmountMan)
	|		ELSE ISNULL(Amounts.AmountIncludingVATMan, 0) 
	|	END AS Cost,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan
	|		ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) 
	|	END AS CostExcludingVAT,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) 
	|	END AS LocalCost,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|
	|	&Currency AS DocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|
	|	&ARAPCurrency AS ARAPCurrency,
	|	TableTypesOfStocks_.AmountARAP 					AS AmountInARAPCurrency,
	|	TableTypesOfStocks_.AmountARAP - TableTypesOfStocks_.AmountVATARAP	AS AmountExcludingVATInARAPCurrency,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	TableTypesOfStocks_.ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS TableTypesOfStocks_
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = TableTypesOfStocks_.Ref
	|		AND Amounts.RowID = TableTypesOfStocks_.RowID
	|
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND TableTypesOfStocks_.PostingOption IN
	|		(VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncreaseWarehouseStock),
	|		 VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncludeDuringPhysicalInventoryCount))
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|			THEN VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit)
	|		ELSE 
	|			VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|	END AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Terms AS Terms,
	|	&Contract AS Contract,
	|	CASE 
	|		WHEN &ReceiptUnderOrders
	|   		THEN TableTypesOfStocks_.PurchaseOrder
	|		ELSE &DocumentBasis
	|	END AS OrderDocument,
	|
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS ProductLineOfBusiness,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	TableTypesOfStocks_.Count AS Count,
	|
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN (Amounts.AmountGivenMan + Amounts.VATAmountMan)
	|		ELSE ISNULL(Amounts.AmountIncludingVATMan, 0) 
	|	END AS Sum,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan
	|		ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) 
	|	END AS AmountExcludingVAT,
	
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) 
	|	END + ISNULL(Amounts.VATAmountCompl, 0) AS SumCompl,
	
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) 
	|	END AS LocalAmountExcludingVAT,
	|	0 AS DiscountAmount,
	|
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN (Amounts.AmountGivenMan + Amounts.VATAmountMan)
	|		ELSE ISNULL(Amounts.AmountIncludingVATMan, 0) 
	|	END AS Cost,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan
	|		ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) 
	|	END AS CostExcludingVAT,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) 
	|	END AS LocalCost,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|
	|	&Currency AS DocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|
	|	&ARAPCurrency AS ARAPCurrency,
	|	TableTypesOfStocks_.AmountARAP 					AS AmountInARAPCurrency,
	|	TableTypesOfStocks_.AmountARAP - TableTypesOfStocks_.AmountVATARAP	AS AmountExcludingVATInARAPCurrency,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.ItemsLocationAttributes.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	TableTypesOfStocks_.ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	Document.PurchaseAdjustment.InventoryKinds AS TableTypesOfStocks_
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = TableTypesOfStocks_.Ref
	|		AND Amounts.RowID = TableTypesOfStocks_.RowID
	|
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND TableTypesOfStocks_.PostingOption =
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners)
	|";
#EndRegion

#Region DecreaseInPurchase
	DecreaseInPurchase =
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.ReverseOfReceipt) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Terms AS Terms,
	|	&Contract AS Contract,
	|	CASE 
	|		WHEN &ReceiptUnderOrders
	|			THEN TableTypesOfStocks_.PurchaseOrder
	|		ELSE &DocumentBasis
	|	END AS OrderDocument,
	|
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS ProductLineOfBusiness,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	TableTypesOfStocks_.Count AS Count,
	|
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN (Amounts.AmountGivenMan + Amounts.VATAmountMan)
	|		ELSE ISNULL(Amounts.AmountIncludingVATMan, 0) 
	|	END AS Sum,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan
	|		ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) 
	|	END AS AmountExcludingVAT,
	
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) 
	|	END + ISNULL(Amounts.VATAmountCompl, 0) AS SumCompl,
	
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) 
	|	END AS LocalAmountExcludingVAT,
	|	0 AS DiscountAmount,
	|
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN (Amounts.AmountGivenMan + Amounts.VATAmountMan)
	|		ELSE ISNULL(Amounts.AmountIncludingVATMan, 0) 
	|	END AS Cost,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan
	|		ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) 
	|	END AS CostExcludingVAT,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) 
	|	END AS LocalCost,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|
	|	&Currency AS DocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|	
	|	&ARAPCurrency AS ARAPCurrency,
	|	TableTypesOfStocks_.AmountARAP AS AmountInARAPCurrency,
	|	(TableTypesOfStocks_.AmountARAP - TableTypesOfStocks_.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	TableTypesOfStocks_.ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS TableTypesOfStocks_
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = TableTypesOfStocks_.Ref
	|		AND Amounts.RowID = TableTypesOfStocks_.RowID
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|	AND TableTypesOfStocks_.PostingOption IN
	|		(VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseReduceWarehouseStock),
	|		 VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseIncludeDuringPhysicalInventoryCount))
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.ReverseOfReceipt) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Terms AS Terms,
	|	&Contract AS Contract,
	|	CASE 
	|		WHEN &ReceiptUnderOrders
	|			THEN TableTypesOfStocks_.PurchaseOrder
	|		ELSE &DocumentBasis
	|	END AS OrderDocument,
	|
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS ProductLineOfBusiness,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	TableTypesOfStocks_.Count AS Count,
	|
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN (Amounts.AmountGivenMan + Amounts.VATAmountMan)
	|		ELSE ISNULL(Amounts.AmountIncludingVATMan, 0) 
	|	END AS Sum,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan
	|		ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) 
	|	END AS AmountExcludingVAT,
	
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) 
	|	END + ISNULL(Amounts.VATAmountCompl, 0) AS SumCompl,
	
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) 
	|	END AS LocalAmountExcludingVAT,
	|	0 AS DiscountAmount,
	|
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN (Amounts.AmountGivenMan + Amounts.VATAmountMan)
	|		ELSE ISNULL(Amounts.AmountIncludingVATMan, 0) 
	|	END AS Cost,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan
	|		ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) 
	|	END AS CostExcludingVAT,
	
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) 
	|	END AS LocalCost,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|
	|	&Currency AS DocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|	
	|	&ARAPCurrency AS ARAPCurrency,
	|	TableTypesOfStocks_.AmountARAP AS AmountInARAPCurrency,
	|	(TableTypesOfStocks_.AmountARAP - TableTypesOfStocks_.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.ItemsLocationAttributes.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	TableTypesOfStocks_.ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	Document.PurchaseAdjustment.InventoryKinds AS TableTypesOfStocks_
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = TableTypesOfStocks_.Ref
	|		AND Amounts.RowID = TableTypesOfStocks_.RowID
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND TableTypesOfStocks_.PostingOption =
	|		 VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners)
	|";
#EndRegion

#Region ChangeInValue
	ChangeInValue = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.PurchaseFromSupplier) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|
	|	DivergenceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DivergenceTable.Warehouse AS Warehouse,
	|	DivergenceTable.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|   DivergenceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Terms AS Terms,
	|	&Contract AS Contract,
	|	CASE 
	|		WHEN &ReceiptUnderOrders
	|   		THEN DivergenceTable.PurchaseOrder
	|		ELSE &DocumentBasis
	|	END AS OrderDocument,
	|
	|	DivergenceTable.ItemsLocationAttributes.Purpose.LineOfBusiness AS ProductLineOfBusiness,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	0 AS Count,
	|
	|	DivergenceTable.AmountIncludingVATMan AS Sum,
	|	DivergenceTable.AmountExcludingVATMan AS AmountExcludingVAT,
	|	DivergenceTable.AmountIncludingVATCompl AS SumCompl,
	|	DivergenceTable.AmountExcludingVATCompl AS LocalAmountExcludingVAT,
	|	0 AS DiscountAmount,
	|
	|	DivergenceTable.AmountIncludingVATMan AS Cost,
	|	DivergenceTable.AmountExcludingVATMan AS CostExcludingVAT,
	|	DivergenceTable.AmountExcludingVATCompl AS LocalCost,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|
	|	&Currency AS DocumentCurrency,
	|	DivergenceTable.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	DivergenceTable.AmountIncludingVAT - DivergenceTable.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|
	|	&ARAPCurrency AS ARAPCurrency,
	|	DivergenceTable.AmountOfSettlementsWithVAT AS AmountInARAPCurrency,
	|	DivergenceTable.AmountOfSettlementsWithVAT - DivergenceTable.AmountVATARAP AS AmountExcludingVATInARAPCurrency,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN DivergenceTable.InventoryOwnerAttribute
	|		ELSE DivergenceTable.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	DivergenceTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|WHERE
	|	(DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost)
	|	OR DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost))
	|	AND NOT DivergenceTable.ToExpenseAs
	|	AND (DivergenceTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|		OR (DivergenceTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND NOT &UninvoicedReceiptDocumentIsUsed
	|		AND (DivergenceTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		OR NOT DivergenceTable.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal))))
	|	AND DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|";
#EndRegion

	QueryText = IncreasedProcurement
		+ " UNION ALL " + DecreaseInPurchase
		+ " UNION ALL " + ChangeInValue;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	If Not DocumentsPosting.ThereIsQueryTable("TTProductDiscrepancyTable", QueryTexts) Then
		QueryTextTTProductDiscrepancyTable(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableDebtAdjustment", QueryTexts) Then
		QueryTextTTTableDebtAdjustment(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period											AS Period,
	|	VALUE(AccumulationRecordType.Receipt)			AS RecordType,
	|	&Organization									AS Organization,
	|	CASE WHEN DivergenceTable.ToExpenseAs
	|		OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|		DivergenceTable.Department
	|	ELSE
	|		&Department
	|	END											AS Department,
	|	CASE WHEN DivergenceTable.ToExpenseAs
	|		OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|		DivergenceTable.LineOfBusiness
	|	ELSE
	|		&LineOfBusiness
	|	END AS LineOfBusiness,
	|	DivergenceTable.AssetAndLiabilityItem		AS AssetRef,
	|	CASE
	|		WHEN DivergenceTable.AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE DivergenceTable.AssetsLiabilitiesDimension
	|	END 											AS Dimension,
	|	
	|	DivergenceTable.AmountIncludingVATMan					AS Sum
	|	
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|	
	|WHERE
	|	DivergenceTable.AssetAndLiabilityItem <> UNDEFINED
	|	AND DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	CASE WHEN DivergenceTable.AmountIncludingVATMan < 0 THEN
	|		VALUE(AccumulationRecordType.Expense)
	|	ELSE
	|		VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	&Organization AS Organization,
	|	CASE WHEN DivergenceTable.ToExpenseAs
	|		OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|		DivergenceTable.Department
	|	ELSE
	|		&Department
	|	END											AS Department,
	|	CASE WHEN DivergenceTable.ToExpenseAs
	|		OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|		DivergenceTable.LineOfBusiness
	|	ELSE
	|		&LineOfBusiness
	|	END AS LineOfBusiness,
	|	&AssetItem AS AssetRef,
	|	CASE
	|		WHEN &DimensionOfAssets = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE &DimensionOfAssets
	|	END AS Dimension,
	|
	|	DivergenceTable.AmountIncludingVATMan AS Sum
	|
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|WHERE
	|	CASE WHEN DivergenceTable.ToExpenseAs
	|		OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|		DivergenceTable.PostingOption IN (
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs),
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost),
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost))
	|	ELSE
	|		DivergenceTable.PostingOption IN (
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs))
	|	END
	|	AND &UseAccountingOfOtherAssetsAndLiabilities
	|	AND &AssetItem <> UNDEFINED
	|	AND DivergenceTable.ExpenseItem <> UNDEFINED
	|	AND DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	CASE WHEN DivergenceTable.AmountIncludingVATMan < 0 THEN
	|		VALUE(AccumulationRecordType.Receipt)
	|	ELSE
	|		VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	&Organization AS Organization,
	|	CASE WHEN DivergenceTable.ToExpenseAs
	|		OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|		DivergenceTable.Department
	|	ELSE
	|		&Department
	|	END											AS Department,
	|	CASE WHEN DivergenceTable.ToExpenseAs
	|		OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|		DivergenceTable.LineOfBusiness
	|	ELSE
	|		&LineOfBusiness
	|	END AS LineOfBusiness,
	|	&LiabilityItem AS AssetRef,
	|	CASE
	|		WHEN &DimensionLiabilities_ = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE &DimensionLiabilities_
	|	END AS Dimension,
	|
	|	DivergenceTable.AmountIncludingVATMan AS Sum
	|
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|WHERE
	|	DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome)
	|	AND &UseAccountingOfOtherAssetsAndLiabilities
	|	AND &LiabilityItem <> UNDEFINED
	|	AND DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	CASE 
	|		WHEN ARAPAdjustment.OnOtherAssets
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	CASE 
	|		WHEN ARAPAdjustment.OnOtherAssets
	|		THEN &AssetItem
	|		ELSE &LiabilityItem
	|	END AS AssetRef,
	|	CASE 
	|		WHEN ARAPAdjustment.OnOtherAssets
	|			THEN CASE
	|				WHEN &DimensionOfAssets = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|					THEN UNDEFINED
	|				ELSE &DimensionOfAssets
	|			END
	|		ELSE CASE
	|				WHEN &DimensionLiabilities_ = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|					THEN UNDEFINED
	|				ELSE &DimensionLiabilities_
	|			END
	|	END AS Dimension,
	|	
	|	ARAPAdjustment.AmountIncludingVATMan AS Sum
	|	
	|FROM
	|	TTTableDebtAdjustment AS ARAPAdjustment
	|WHERE
	|	(ARAPAdjustment.OnOtherAssets
	|		OR ARAPAdjustment.OtherLiabilities_)
	|	AND &UseAccountingOfOtherAssetsAndLiabilities
	|";
	QueryText = QueryText + "UNION ALL"
		+ AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities();
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTRegisteredRecordsInOtherAssetsLiabilities(Query, QueryTexts)
	
	RegisterName = "TTRegisteredRecordsInOtherAssetsLiabilities";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialRegisteredRecordsOnOtherAssetsLiabilities", QueryTexts) Then
		QueryTextTableTTInitialRegisteredRecordsOnOtherAssetsLiabilities(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.QueryTextTableTTRegisteredRecordsInOtherAssetsLiabilities("RowID");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTRegisteredRecordsInOtherAssetsLiabilities", QueryTexts) Then
		QueryTextTableTTRegisteredRecordsInOtherAssetsLiabilities(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.QueryTextTableOtherAssetsAndLiabilitiesRecords();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialRegisteredRecordsOnOtherAssetsLiabilities(Query, QueryTexts)
	
	RegisterName = "TTInitialRegisteredRecordsOnOtherAssetsLiabilities";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductDiscrepancyTable", QueryTexts) Then
		QueryTextTTProductDiscrepancyTable(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableDebtAdjustment", QueryTexts) Then
		QueryTextTTTableDebtAdjustment(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN DivergenceTable.ToExpenseAs
	|			OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef)
	|			THEN DivergenceTable.Department
	|		ELSE
	|			&Department
	|	END AS Department,
	|	CASE
	|		WHEN DivergenceTable.ToExpenseAs
	|			OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef)
	|			THEN DivergenceTable.LineOfBusiness
	|		ELSE
	|			&LineOfBusiness
	|	END AS LineOfBusiness,
	|	DivergenceTable.AssetAndLiabilityItem AS AssetRef,
	|	DivergenceTable.AssetsLiabilitiesDimension AS Dimension,
	|	DivergenceTable.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|	DivergenceTable.VATActivityType AS VATActivityType,
	|	
	|	DivergenceTable.AmountIncludingVATCompl AS SumCompl,
	|	DivergenceTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	DivergenceTable.AmountIncludingVATMan AS SumMan,
	|	DivergenceTable.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	DivergenceTable.AmountIncludingVATMan AS AmountIncludingVAT,
	|	DivergenceTable.AmountExcludingVATMan AS AmountExcludingVAT,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	
	|	DivergenceTable.RowID AS RowID,
	|	DivergenceTable.FinRecordID AS FinRecordID,
	|	DivergenceTable.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TTInitialRegisteredRecordsOnOtherAssetsLiabilities
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|	
	|WHERE
	|	DivergenceTable.AssetAndLiabilityItem <> UNDEFINED
	|	AND DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN DivergenceTable.ToExpenseAs
	|			OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef)
	|			THEN DivergenceTable.Department
	|		ELSE
	|			&Department
	|	END AS Department,
	|	CASE
	|		WHEN DivergenceTable.ToExpenseAs
	|			OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef)
	|			THEN DivergenceTable.LineOfBusiness
	|		ELSE
	|			&LineOfBusiness
	|	END AS LineOfBusiness,
	|	&AssetItem AS AssetRef,
	|	&DimensionOfAssets AS Dimension,
	|	&AssetGLAccountsSettings AS GLAccountSettings,
	|	CASE
	|		WHEN DivergenceTable.AmountIncludingVATMan < 0
	|			THEN VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit)
	|		ELSE VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit)
	|	END AS DebitCredit,
	|	DivergenceTable.VATActivityType AS VATActivityType,
	|	DivergenceTable.AmountIncludingVATCompl AS SumCompl,
	|	DivergenceTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	DivergenceTable.AmountIncludingVATMan AS SumMan,
	|	DivergenceTable.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	DivergenceTable.AmountIncludingVATMan AS AmountIncludingVAT,
	|	DivergenceTable.AmountExcludingVATMan AS AmountExcludingVAT,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	
	|	DivergenceTable.RowID AS RowID,
	|	DivergenceTable.FinRecordID AS FinRecordID,
	|	DivergenceTable.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|WHERE
	|	DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs)
	|	AND &UseAccountingOfOtherAssetsAndLiabilities
	|	AND &AssetItem <> UNDEFINED
	|	AND DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN DivergenceTable.ToExpenseAs
	|			OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef)
	|			THEN DivergenceTable.Department
	|		ELSE
	|			&Department
	|	END AS Department,
	|	CASE
	|		WHEN DivergenceTable.ToExpenseAs
	|			OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef)
	|			THEN DivergenceTable.LineOfBusiness
	|		ELSE
	|			&LineOfBusiness
	|	END AS LineOfBusiness,
	|	&LiabilityItem AS AssetRef,
	|	&DimensionLiabilities_ AS Dimension,
	|	&LiabilitiesGLAccountsSettings AS GLAccountSettings,
	|	CASE
	|		WHEN DivergenceTable.AmountIncludingVATMan < 0
	|			THEN VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit)
	|		ELSE VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit)
	|	END AS DebitCredit,
	|	DivergenceTable.VATActivityType AS VATActivityType,
	|	
	|	DivergenceTable.AmountIncludingVATCompl AS SumCompl,
	|	DivergenceTable.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	DivergenceTable.AmountIncludingVATMan AS SumMan,
	|	DivergenceTable.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	DivergenceTable.AmountIncludingVATMan AS AmountIncludingVAT,
	|	DivergenceTable.AmountExcludingVATMan AS AmountExcludingVAT,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	
	|	DivergenceTable.RowID AS RowID,
	|	DivergenceTable.FinRecordID AS FinRecordID,
	|	DivergenceTable.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|WHERE
	|	DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome)
	|	AND &UseAccountingOfOtherAssetsAndLiabilities
	|	AND &LiabilityItem <> UNDEFINED
	|	AND DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	CASE 
	|		WHEN ARAPAdjustment.OnOtherAssets
	|			THEN &AssetItem
	|		ELSE &LiabilityItem
	|	END AS AssetRef,
	|	CASE 
	|		WHEN ARAPAdjustment.OnOtherAssets
	|			THEN &DimensionOfAssets
	|		ELSE &DimensionLiabilities_
	|	END AS Dimension,
	|	CASE 
	|		WHEN ARAPAdjustment.OnOtherAssets
	|			THEN &AssetGLAccountsSettings
	|		ELSE &LiabilitiesGLAccountsSettings
	|	END AS GLAccountSettings,
	|	CASE
	|		WHEN ARAPAdjustment.OnOtherAssets
	|			THEN VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit)
	|		ELSE VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit)
	|	END AS DebitCredit,
	|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) AS VATActivityType,
	|	
	|	ARAPAdjustment.AmountIncludingVATCompl AS SumCompl,
	|	ARAPAdjustment.AmountIncludingVATCompl AS AmountExcludingVATCompl,
	|	ARAPAdjustment.AmountIncludingVATMan AS SumMan,
	|	ARAPAdjustment.AmountIncludingVATMan AS AmountExcludingVATMan,
	|	ARAPAdjustment.AmountIncludingVATMan AS AmountIncludingVAT,
	|	ARAPAdjustment.AmountExcludingVATMan AS AmountExcludingVAT,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	
	|	ARAPAdjustment.RowID AS RowID,
	|	ARAPAdjustment.UniqueIDOfSettlementObject AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ARAPAdjustment) AS BusinessTransactionSetting
	|FROM
	|	TTTableDebtAdjustment AS ARAPAdjustment
	|WHERE
	|	(ARAPAdjustment.OnOtherAssets
	|		OR ARAPAdjustment.OtherLiabilities_) 
	|	AND &UseAccountingOfOtherAssetsAndLiabilities
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	CASE 
	|		WHEN ARAPAdjustment.OnOtherAssets
	|			THEN &AssetItem
	|		ELSE &LiabilityItem
	|	END AS AssetRef,
	|	CASE 
	|		WHEN ARAPAdjustment.OnOtherAssets
	|			THEN &DimensionOfAssets
	|		ELSE &DimensionLiabilities_
	|	END AS Dimension,
	|	CASE 
	|		WHEN ARAPAdjustment.OnOtherAssets
	|			THEN &AssetGLAccountsSettings
	|		ELSE &LiabilitiesGLAccountsSettings
	|	END AS GLAccountSettings,
	|	CASE
	|		WHEN ARAPAdjustment.OnOtherAssets
	|			THEN VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit)
	|		ELSE VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit)
	|	END AS DebitCredit,
	|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) AS VATActivityType,
	|	
	|	ARAPAdjustment.VATLocal AS SumCompl,
	|	ARAPAdjustment.VATLocal AS AmountExcludingVATCompl,
	|	ARAPAdjustment.VATManag AS SumMan,
	|	ARAPAdjustment.VATManag AS AmountExcludingVATMan,
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	
	|	ARAPAdjustment.RowID AS RowID,
	|	ARAPAdjustment.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|FROM
	|	TTTableDebtAdjustment AS ARAPAdjustment
	|WHERE
	|	(ARAPAdjustment.OnOtherAssets
	|		OR ARAPAdjustment.OtherLiabilities_) 
	|	AND &UseAccountingOfOtherAssetsAndLiabilities
	|	AND &PurchaseForActivity NOT IN (&TypesOfTaxationVATIsIncludedInCost)
	|	AND (ARAPAdjustment.VATLocal <> 0
	|		OR ARAPAdjustment.VATManag <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers)
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	If Not DocumentsPosting.ThereIsQueryTable("TTProductDiscrepancyTable", QueryTexts) Then
		QueryTextTTProductDiscrepancyTable(Query, QueryTexts);
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TTTableDebtAdjustment", QueryTexts) Then
		QueryTextTTTableDebtAdjustment(Query, QueryTexts);
	EndIf;
		
#Region DebitNoteWithWritingOffAsExpenses
	DebitNoteWithWritingOffAsExpenses = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.DebitNoteWithWritingOffAsExpenses) AS BusinessOperation,
	|	&Organization AS Organization,
	|	DivergenceTable.Department AS Department,
	|
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	DivergenceTable.ARAPObject AS ARAPObject,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	DivergenceTable.LineOfBusiness AS LineOfBusinessItems,
	|	CASE 
	|		WHEN DivergenceTable.AssetAndLiabilityItem <> UNDEFINED
	|			THEN DivergenceTable.AssetAndLiabilityItem
	|		WHEN DivergenceTable.ToExpenseAs
	|				OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef)
	|			THEN DivergenceTable.ExpenseItem
	|		ELSE 
	|			CASE
	|				WHEN &ExpenseItem <> UNDEFINED
	|				THEN &ExpenseItem
	|				ELSE &AssetItem
	|			END
	|	END AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	
	|	CASE
	|		WHEN DivergenceTable.ToExpenseAs
	|				OR DivergenceTable.Products = VALUE(Catalog.Products.EmptyRef)
	|			THEN DivergenceTable.DimensionOfExpenses
	|		ELSE &DimensionOfExpenses
	|	END AS DimensionOfExpenses,
	|	CASE
	|		WHEN DivergenceTable.AssetAndLiabilityItem <> UNDEFINED
	|		THEN DivergenceTable.AssetsLiabilitiesDimension
	|		ELSE &DimensionOfAssets
	|	END AS AssetsLiabilitiesDimension,
	|	
	|	DivergenceTable.AmountIncludingVATMan AS Sum,
	|	DivergenceTable.AmountExcludingVATMan AS AmountExcludingVAT,
	|	DivergenceTable.AmountIncludingVATCompl AS SumCompl,
	|	DivergenceTable.AmountExcludingVATCompl AS LocalAmountExcludingVAT,
	|
	|	&Currency AS Currency,
	|	DivergenceTable.AmountIncludingVAT AS AmountInCurrency,
	|	DivergenceTable.AmountIncludingVAT - DivergenceTable.VATAmount AS AmountExcludingVATInCurrency,
	|		
	|	&ARAPCurrency AS ARAPCurrency,
	|	DivergenceTable.AmountOfSettlementsWithVAT AS AmountInARAPCurrency,
	|	DivergenceTable.AmountOfSettlementsWithVAT - DivergenceTable.AmountVATARAP AS AmountExcludingVATInARAPCurrency,
	|
	|	DivergenceTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	DivergenceTable.RowID AS FinRecordID
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|WHERE
	|	(DivergenceTable.AmountIncludingVAT <> 0
	|		OR DivergenceTable.VATAmount <> 0
	|		OR DivergenceTable.AmountIncludingVATMan <> 0
	|		OR DivergenceTable.AmountExcludingVATMan <> 0
	|		OR DivergenceTable.AmountIncludingVATCompl <> 0
	|		OR DivergenceTable.AmountExcludingVATCompl <> 0)
	|	AND CASE 
	|		WHEN DivergenceTable.ToExpenseAs
	|			AND (DivergenceTable.ExpenseItem <> UNDEFINED 
	|					OR DivergenceTable.AssetAndLiabilityItem <> UNDEFINED)
	|			THEN
	|				DivergenceTable.PostingOption IN (
	|					VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs),
	|					VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost),
	|					VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost))
	|	ELSE
	|		DivergenceTable.PostingOption IN (
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs))
	|	END
	|	AND DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|";
#EndRegion

#Region DebitNoteWithRecordingAsOtherIncome
	DebitNoteWithRecordingAsOtherIncome = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.DebitNoteWithRecordingAsOtherIncome) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	DivergenceTable.ARAPObject AS ARAPObject,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	DivergenceTable.LineOfBusiness AS LineOfBusinessItems,
	|	CASE
	|		WHEN DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome)
	|			THEN &IncomeItem
	|		WHEN DivergenceTable.ToExpenseAs
	|			THEN DivergenceTable.IncomeItem
	|		ELSE 
	|			CASE
	|				WHEN &IncomeItem <> UNDEFINED
	|					THEN &IncomeItem
	|				ELSE &LiabilityItem
	|			END 
	|	END AS IncomeAndExpenseItem,
	|	CASE
	|		WHEN DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome)
	|			THEN &DimensionOfRevenue
	|		WHEN DivergenceTable.ToExpenseAs
	|			THEN DivergenceTable.DimensionOfRevenue
	|		ELSE &DimensionOfRevenue 
	|	END AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	&DimensionLiabilities_ AS AssetsLiabilitiesDimension,
	|	
	|	-DivergenceTable.AmountIncludingVATMan AS Sum,
	|	-DivergenceTable.AmountExcludingVATMan AS AmountExcludingVAT,
	|	-DivergenceTable.AmountIncludingVATCompl AS SumCompl,
	|	-DivergenceTable.AmountExcludingVATCompl AS LocalAmountExcludingVAT,
	|
	|	&Currency AS Currency,
	|	-DivergenceTable.AmountIncludingVAT AS AmountInCurrency,
	|	-(DivergenceTable.AmountIncludingVAT - DivergenceTable.VATAmount) AS AmountExcludingVATInCurrency,
	|		
	|	&ARAPCurrency AS ARAPCurrency,
	|	-DivergenceTable.AmountOfSettlementsWithVAT AS AmountInARAPCurrency,
	|	-(DivergenceTable.AmountOfSettlementsWithVAT - DivergenceTable.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	DivergenceTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	DivergenceTable.RowID AS FinRecordID
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|WHERE
	|	(DivergenceTable.AmountIncludingVAT <> 0
	|		OR DivergenceTable.VATAmount <> 0
	|		OR DivergenceTable.AmountIncludingVATMan <> 0
	|		OR DivergenceTable.AmountExcludingVATMan <> 0
	|		OR DivergenceTable.AmountIncludingVATCompl <> 0
	|		OR DivergenceTable.AmountExcludingVATCompl <> 0)
	|	AND DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|	AND (DivergenceTable.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome)
	|		OR 
	|		(DivergenceTable.ToExpenseAs
	|			AND DivergenceTable.IncomeItem <> UNDEFINED))
	|";
#EndRegion

#Region AdjustmentOfAcquisitionIncreaseInDebtConsolidated
	AdjustmentOfAcquisitionIncreaseInDebtConsolidated = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.DebitNoteWithWritingOffAsExpenses) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	ARAPAdjustment.Contract AS Contract,
	|	ARAPAdjustment.ARAPObject AS ARAPObject,
	|	ARAPAdjustment.DirectionOfActivityOfCalculations AS CounterpartyLineOfBusiness,
	|
	|	&LineOfBusiness AS LineOfBusinessItems,
	|	CASE
	|		WHEN ARAPAdjustment.ToExpenses
	|			THEN &ExpenseItem
	|		WHEN ARAPAdjustment.OnOtherAssets
	|			THEN &AssetItem
	|	END AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	CASE 
	|		WHEN ARAPAdjustment.ToExpenses
	|			THEN &DimensionOfExpenses
	|		ELSE UNDEFINED
	|	END AS DimensionOfExpenses,
	|	CASE 
	|		WHEN ARAPAdjustment.OnOtherAssets
	|			THEN &DimensionOfAssets
	|		ELSE UNDEFINED
	|	END AS AssetsLiabilitiesDimension,
	|	
	|	ARAPAdjustment.AmountIncludingVATMan AS Sum,
	|	ARAPAdjustment.AmountExcludingVATMan AS AmountExcludingVAT,
	|	ARAPAdjustment.AmountIncludingVATCompl AS SumCompl,
	|	ARAPAdjustment.AmountExcludingVATCompl AS LocalAmountExcludingVAT,
	|
	|	&Currency AS Currency,
	|	ARAPAdjustment.AmountIncludingVAT AS AmountInCurrency,
	|	(ARAPAdjustment.AmountIncludingVAT - ARAPAdjustment.VATAmount) AS AmountExcludingVATInCurrency,
	|		
	|	&ARAPCurrency AS ARAPCurrency,
	|	ARAPAdjustment.AmountARAP AS AmountInARAPCurrency,
	|	(ARAPAdjustment.AmountARAP - ARAPAdjustment.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	ARAPAdjustment.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	ARAPAdjustment.RowID AS FinRecordID
	|FROM
	|	TTTableDebtAdjustment AS ARAPAdjustment
	|WHERE
	|	ARAPAdjustment.ToExpenses OR ARAPAdjustment.OnOtherAssets
	|";
#EndRegion

#Region AcquisitionAdjustmentDebtReductionConsolidated
	AcquisitionAdjustmentDebtReductionConsolidated = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.DebitNoteWithRecordingAsOtherIncome) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	ARAPAdjustment.Contract AS Contract,
	|	ARAPAdjustment.ARAPObject AS ARAPObject,
	|	ARAPAdjustment.DirectionOfActivityOfCalculations AS CounterpartyLineOfBusiness,
	|
	|	&LineOfBusiness AS LineOfBusinessItems,
	|	CASE
	|		WHEN ARAPAdjustment.OnIncome
	|			THEN &IncomeItem
	|		WHEN ARAPAdjustment.OtherLiabilities_
	|			THEN &LiabilityItem
	|	END AS IncomeAndExpenseItem,
	|	CASE 
	|		WHEN ARAPAdjustment.OnIncome
	|			THEN &DimensionOfRevenue
	|		ELSE UNDEFINED
	|	END AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	CASE 
	|		WHEN ARAPAdjustment.OtherLiabilities_
	|			THEN &DimensionLiabilities_
	|		ELSE UNDEFINED
	|	END AS AssetsLiabilitiesDimension,
	|	
	|	ARAPAdjustment.AmountIncludingVATMan AS Sum,
	|	ARAPAdjustment.AmountExcludingVATMan AS AmountExcludingVAT,
	|	ARAPAdjustment.AmountIncludingVATCompl AS SumCompl,
	|	ARAPAdjustment.AmountExcludingVATCompl AS LocalAmountExcludingVAT,
	|
	|	&Currency AS Currency,
	|	ARAPAdjustment.AmountIncludingVAT AS AmountInCurrency,
	|	(ARAPAdjustment.AmountIncludingVAT - ARAPAdjustment.VATAmount) AS AmountExcludingVATInCurrency,
	|		
	|	&ARAPCurrency AS ARAPCurrency,
	|	ARAPAdjustment.AmountARAP AS AmountInARAPCurrency,
	|	(ARAPAdjustment.AmountARAP - ARAPAdjustment.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	ARAPAdjustment.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	ARAPAdjustment.RowID AS FinRecordID
	|FROM
	|	TTTableDebtAdjustment AS ARAPAdjustment
	|WHERE
	|	ARAPAdjustment.OnIncome OR ARAPAdjustment.OtherLiabilities_
	|";
#EndRegion
	QueryText = DebitNoteWithWritingOffAsExpenses
		+ " UNION ALL " + DebitNoteWithRecordingAsOtherIncome
		+ " UNION ALL " + AdjustmentOfAcquisitionIncreaseInDebtConsolidated
		+ " UNION ALL " + AcquisitionAdjustmentDebtReductionConsolidated;
	
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
	|	&Ref                                 AS Ref,
	|	&Period                                 AS IBDocumentDate,
	|	&Number                                  AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	CASE
	|		WHEN &DocumentBasis <> UNDEFINED
	|			THEN &BusinessTransactionGrounds
	|		ELSE &BusinessOperation
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
	|	&IncomingDocumentDate                 AS SourceDocumentDate,
	|	&IncomingDocumentNumber                AS SourceDocumentNumber,
	|	&ExternalDocumentName         AS SourceDocumentName,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|FROM
	|	Document.PurchaseAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTCorrectionDocumentToBeCorrected(Query)

	DocumentBeingCorrectedIsEmptyLinks = New Array;
	
	For Each Type In Metadata.Documents.PurchaseAdjustment.Attributes.CorrectedDocument.Type.Types() Do
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
	|	PurchaseAdjustment.Ref AS Adjusting,
	|	PurchaseAdjustment.DocumentBasis AS DocumentBasis
	|INTO TT_AdjustmentUnderApprovalOfParties
	|FROM
	|	Document.PurchaseAdjustment AS PurchaseAdjustment
	|		LEFT JOIN InformationRegister.DocumentCorrections AS DocumentCorrections
	|		ON DocumentCorrections.CorrectedDocument = PurchaseAdjustment.Ref
	|		AND DocumentCorrections.DocumentToCorrectIsReversed
	|WHERE
	|	PurchaseAdjustment.DocumentBasis = &DocumentBasis
	|	AND PurchaseAdjustment.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
	|	AND PurchaseAdjustment.Posted
	|	AND PurchaseAdjustment.Date < &Period
	|	AND DocumentCorrections.CorrectedDocument IS NULL
	|
	|ORDER BY
	|	PurchaseAdjustment.Date DESC
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
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ErrorCorrection)
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

Function QueryTextTableDocumentCorrections(Query, QueryTexts, Registers) Export
	
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
	|	&Ref						AS Document,
	|	&Period						AS Period,
	|	SeriesTable.Products	AS Products,
	|	SeriesTable.Characteristic	AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END						AS Purpose,
	|	SeriesTable.Series			AS Series,
	|	SeriesTable.Count		AS Count,
	|	&Partner					AS Sender,
	|	SeriesTable.Warehouse			AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.ReceiptFromVendor) AS WarehouseOperation,
	|	TRUE						AS ThisIsWarehouseRecord
	|FROM
	|	Document.PurchaseAdjustment.Goods AS SeriesTable
	|
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
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
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager;
	
	For Each Parameter In MainQuery.Parameters Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	
	QueryTexts = New ValueList;
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBatchProduction", QueryTexts) Then
		QueryTextTTBatchProduction(Query, QueryTexts);
	EndIf;
	
	QueryText =
	// template of distributed sums, border - 3
	"SELECT TOP 0
	|   Discrepancies.RowID           AS RowID,
	|	Discrepancies.ItemsLocationAttributes    AS ItemsLocationAttributes,
	|	Discrepancies.CostGroupNumber             AS CostGroupNumber,
	|	Discrepancies.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
	|	Discrepancies.CCDNumber                      AS CCDNumber,
	|	Discrepancies.Sum                         AS Sum
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS Discrepancies  
	|WHERE
	|	Discrepancies.Ref = &Ref	
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
	|	InventoryKinds.RowID              AS RowID,
	|	InventoryKinds.CostShare                    AS CostShare,
	|	InventoryKinds.CostGroupNumber                AS CostGroupNumber,
	|	InventoryKinds.ItemsLocationAttributes       AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute                       AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber                         AS CCDNumber
	|FROM
	|	Document.SubcontractorReport2_5.InventoryOwnerAttributesProducts AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref = &DocumentBasis
	|	AND InventoryKinds.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|;
	|
	// processing services for distribution, abroad
	|SELECT
	|	Discrepancies.CostGroupNumber           AS CostGroupNumber,
	|	Discrepancies.ItemsLocationAttributes  AS ItemsLocationAttributes,
	|	Discrepancies.InventoryOwnerAttribute                  AS InventoryOwnerAttribute,
	|	Discrepancies.CCDNumber                    AS CCDNumber,
	|	Discrepancies.Count                  AS Count,
	|	ISNULL(Amounts.AmountExcludingVAT, 0)          AS Sum
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS Discrepancies
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON Discrepancies.Ref = Amounts.Ref
	|			AND Discrepancies.RowID = Amounts.RowID
	|WHERE
	|	Discrepancies.Ref = &Ref";
	
	QueryTexts.Add(QueryText);
	Query.Text = StrConcat(QueryTexts.UnloadValues(), Common.QueryBatchSeparator());
	
	ResultsPackage = Query.ExecuteBatch();
	
	Boundary = ResultsPackage.UBound();
	
	DistributedTypesOfStocks      = ResultsPackage[Boundary - 3].Unload();
	BatchTable_                  = ResultsPackage[Boundary - 2].Unload();
	ProductTable               = ResultsPackage[Boundary - 1].Unload();
	TableToDistribution          = ResultsPackage[Boundary].Unload();
	
	ByOrders = Query.Parameters.ByOrders;
	GroupCosts = Query.Parameters.GroupCosts;
	
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
			
			Sum      = Common.DistributeAmountInProportionToCoefficients(DistributableString.Sum, ArrayOfCoefficients, 3);
			
			For IndexProduct = 0 To ProductLines - 1 Do
				
				ProductionLine = ProductList_[IndexProduct];
				
				NewRow = DistributedTypesOfStocks.Add();
				
				// filling in the analysis of material, waste, services
				FillPropertyValues(NewRow, DistributableString);
				
				// filling out product analytics in the cor part
				FillPropertyValues(NewRow, ProductionLine);
				
				NewRow.Sum       = ?(ValueIsFilled(Sum), Sum[IndexProduct], 0);				
			EndDo;
			
		EndDo;
	
	EndDo;
	
	GroupingColumns = "";
	TotalingColumns = "Sum";
	
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

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.PurchaseAdjustment";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("ContractInformation",    """""");
	RedefiningParameterCalculation.Insert("IncomingDocumentNumber", """""");
	RedefiningParameterCalculation.Insert(
		"BusinessTransactionGrounds",
		"DocumentData.BusinessOperation");
	RedefiningParameterCalculation.Insert("BusinessOperation", "DocumentData.AdjustmentKind");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));  
	ParameterValues.Insert("ControlCompanyStockBalanceForRegistrationByReceipts",
		GetFunctionalOption("ControlCompanyStockBalanceForRegistrationByReceipts"));
	ParameterValues.Insert("UseTraceableImportedGoodsAccounting",
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Date(1,1,1)));
	ParameterValues.Insert("DateOfTraceableImportedGoodsAccountingStart",
		AccountingForTraceableGoodsLocalization.DateOfTraceableImportedGoodsAccountingStart());
	
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
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductDiscrepancyTable", QueryTexts) Then
		QueryTextTTProductDiscrepancyTable(Query, QueryTexts);
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TTBatchProduction", QueryTexts) Then
		QueryTextTTBatchProduction(Query, QueryTexts);
	EndIf;
	SetRequestParameterVATReceiptDocument(Query);
	
	ValueText_ =
	"SELECT
	|	Discrepancies.Ref.Date AS Period,
	|	Discrepancies.Ref AS Ref,
	|	Discrepancies.Ref.Organization AS Organization,
	|	Discrepancies.Ref.Department AS Department,
	|	Discrepancies.Ref.Counterparty AS Counterparty,
	|	Discrepancies.Ref.Contract AS Contract,
	|	CASE
	|		WHEN Discrepancies.Ref.DocumentBasis REFS Document.SourceDocument
	|			THEN UNDEFINED
	|		ELSE
	|			Discrepancies.Ref.DocumentBasis.Shipper
	|	END AS Shipper,
	|	&VATReceiptDocument AS DocumentAcquisitions,
	|	Discrepancies.Ref.DocumentBasis AS OriginalTradeDocument,
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
	|	Discrepancies.Ref.ReduceAmountVATDeduction AS ReduceAmountVATDeduction,
	|	Discrepancies.Ref AS PurchaseAdjustmentDocument,
	|	Discrepancies.Ref.VATTaxation AS VATTaxation,
	|	CASE
	|		WHEN Discrepancies.Ref.DocumentBasis REFS Document.SourceDocument
	|			THEN Discrepancies.Ref.PurchaseForActivity
	|		ELSE
	|			Discrepancies.Ref.DocumentBasis.PurchaseForActivity
	|	END AS VATActivityType,
	|
	|	Discrepancies.VATRate AS VATRate,
	|	CASE WHEN Discrepancies.ToExpenseAs
	|		THEN UNDEFINED
	|		ELSE Discrepancies.Products
	|	END AS Products,
	|	Discrepancies.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Discrepancies.CCDNumber AS CCDNumber,
	|	Discrepancies.Department AS AccountingDivision,
	|	CASE
	|		WHEN &DocumentPurchaseOfServicesOtherAssetsIsUsed
	|			THEN DivergenceTable.LineOfBusiness
	|		WHEN DivergenceTable.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef) THEN
	|			&LineOfBusiness
	|		ELSE DivergenceTable.LineOfBusiness
	|	END AS LineOfBusiness,
	|	CASE
	|		WHEN FALSE
	|			THEN FALSE
	|		WHEN NOT ProductionLots.LineOfBusiness IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS PurchasePerBatchOfProduction,
	|	CASE
	|		WHEN FALSE
	|			THEN UNDEFINED
	|		WHEN NOT ProductionLots.LineOfBusiness IS NULL
	|			THEN ProductionLots.LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS LineOfBusinessOfProductionParty,
	|	Discrepancies.ToExpenseAs AS ToExpenseAs,
	|	CASE WHEN Discrepancies.ToExpenseAs
	|			OR Discrepancies.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|			Discrepancies.ExpenseItem
	|		ELSE
	|			&ExpenseItem
	|	END AS ExpenseItem,
	|	CASE WHEN Discrepancies.ToExpenseAs
	|		OR Discrepancies.Products = VALUE(Catalog.Products.EmptyRef) THEN
	|		Discrepancies.DimensionOfExpenses
	|	ELSE
	|		&DimensionOfExpenses
	|	END AS DimensionOfExpenses,
	|	Discrepancies.AssetAndLiabilityItem AS ItemOfOtherAssets,
	|	Discrepancies.AssetsLiabilitiesDimension AS AnalyticsOfOtherAssets,
	|	Discrepancies.Purpose AS Purpose,
	|	Discrepancies.RowID AS RowID,
	|	Discrepancies.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|FROM
	|	TTProductDiscrepancyTable AS Discrepancies
	|	LEFT JOIN
	|		Document.PurchaseAdjustment.Discrepancies AS DivergenceTable
	|		ON Discrepancies.Ref = DivergenceTable.Ref
	|		AND Discrepancies.LineNumber = DivergenceTable.LineNumber
	|	LEFT JOIN
	|		TTBatchProduction AS ProductionLots
	|		ON ProductionLots.ReleaseParty = &DocumentBasis
	|		AND ProductionLots.CostGroupNumber = DivergenceTable.CostGroupNumber
	|WHERE
	|	Discrepancies.Ref = &Ref
	|	AND (CASE
	|		WHEN NOT Discrepancies.Ref.DocumentBasis REFS Document.SourceDocument
	|			AND ISNULL(Discrepancies.Ref.DocumentBasis.ToReturnReusablePackage, FALSE)
	|			THEN Discrepancies.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		ELSE
	|			TRUE
	|		END)
	|	AND Discrepancies.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	ARAPAdjustment.Ref.Date AS Period,
	|	ARAPAdjustment.Ref AS Ref,
	|	ARAPAdjustment.Ref.Organization AS Organization,
	|	ARAPAdjustment.Ref.Department AS Department,
	|	ARAPAdjustment.Ref.Counterparty AS Counterparty,
	|	ARAPAdjustment.Ref.Contract AS Contract,
	|	UNDEFINED AS Shipper,
	|	ARAPAdjustment.DocumentAcquisitions AS DocumentAcquisitions,
	|	ARAPAdjustment.DocumentAcquisitions AS OriginalTradeDocument,
	|	FALSE AS ErrorCorrection,
	|	TRUE AS AdjustmentUnderApprovalOfParties,
	|	ARAPAdjustment.Ref.ReduceAmountVATDeduction AS ReduceAmountVATDeduction,
	|	ARAPAdjustment.Ref AS PurchaseAdjustmentDocument,
	|	ARAPAdjustment.Ref.VATTaxation AS VATTaxation,
	|	ARAPAdjustment.Ref.PurchaseForActivity AS VATActivityType,
	|	ARAPAdjustment.VATRate AS VATRate,
	|	UNDEFINED AS Products,
	|	UNDEFINED AS InventoryOwnerAttribute,
	|	UNDEFINED AS CCDNumber,
	|	ARAPAdjustment.Ref.Department AS AccountingDivision,
	|	ARAPAdjustment.Ref.LineOfBusiness AS LineOfBusiness,
	|	FALSE AS PurchasePerBatchOfProduction,
	|	UNDEFINED AS LineOfBusinessOfProductionParty,
	|	FALSE AS ToExpenseAs,
	|	ARAPAdjustment.Ref.ExpenseItem AS ExpenseItem,
	|	ARAPAdjustment.Ref.DimensionOfExpenses AS DimensionOfExpenses,
	|	ARAPAdjustment.Ref.ExpenseItem AS ItemOfOtherAssets,
	|	ARAPAdjustment.Ref.DimensionOfAssets AS AnalyticsOfOtherAssets,
	|	UNDEFINED AS Purpose,
	|	ARAPAdjustment.RowID AS RowID,
	|	ARAPAdjustment.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|FROM
	|	Document.PurchaseAdjustment.ARAPAdjustment AS ARAPAdjustment
	|WHERE
	|	ARAPAdjustment.Ref IN (&Ref)
	|";
	
	VATAccountingERP.ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, ValueText_);
	
	ReflectImportOfGoodsFromCustomsUnion(Query, QueryTexts, Registers);
	
EndProcedure

Procedure ReflectImportOfGoodsFromCustomsUnion(Query, QueryTexts, Registers)
	
	If DocumentsPosting.RequiresTableForRegisteredRecords("GoodsForRegistrationOfImportDocuments", Registers) Then 
		If Query.Parameters.BusinessTransactionGrounds = Enums.BusinessTransactions.SubcontractorReportAdjustment
			And Query.Parameters.ProductionAtProcessorInEAEUCountries Then 
		
			If Not DocumentsPosting.ThereIsQueryTable("TTDistributedInventoryTypes", QueryTexts) Then
				QueryTextTTDistributedInventoryTypes(Query, QueryTexts);
			EndIf;
		
			TextProducts_1 = 
			"SELECT
			|	&Ref AS Ref,
			|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
			|	&Period AS Period,
			|	&Organization AS Organization,
			|	&Partner AS Vendor,
			|	ProductsOfApplication.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	ProductsOfApplication.InventoryOwnerAttribute AS InventoryOwnerAttribute,
			|	ProductsOfApplication.CCDNumber AS CCDNumber,
			|	&DocumentBasis AS DocumentAcquisitions,
			|	&IdApplicationForImportOfGoods AS ImportDocumentType,
			|	0 AS Count,
			|	ProductsOfApplication.Sum AS Sum,
			|	ProductsOfApplication.RowID AS RowID
			|FROM
			|	TTDistributedInventoryTypes AS ProductsOfApplication";
	
			ImportAccounting.ReflectImportOfGoodsFromCustomsUnionNewMechanics(Query, QueryTexts, Registers, TextProducts_1);
			
		EndIf;
		If Query.Parameters.BusinessTransactionsProcurementInEAEUCountries.Find(Query.Parameters.BusinessTransactionGrounds) <> Undefined Then 
			
			If Not DocumentsPosting.ThereIsQueryTable("TTProductDiscrepancyTable", QueryTexts) Then
				QueryTextTTProductDiscrepancyTable(Query, QueryTexts);
			EndIf;
			
			TextProducts_1 = 
			"SELECT
			|	&Ref AS Ref,
			|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
			|	&Period AS Period,
			|	&Organization AS Organization,
			|	&Partner AS Vendor,
			|	TableOfProductDiscrepancies.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	TableOfProductDiscrepancies.InventoryOwnerAttribute AS InventoryOwnerAttribute,
			|	&DocumentBasis AS DocumentAcquisitions,
			|
			|	&IdApplicationForImportOfGoods AS ImportDocumentType,
			|	TableOfProductDiscrepancies.CCDNumber AS CCDNumber,
			|	0 AS QuantityByGBRN,
			|
			|	TableOfProductDiscrepancies.Count AS Count,
			|	ISNULL(DocumentAmounts_.AmountExcludingVAT, 0) AS Sum,
			|	TRUE AS Primary,
			|	TableOfProductDiscrepancies.RowID AS RowID
			|FROM
			|	TTProductDiscrepancyTable AS TableOfProductDiscrepancies
			|	LEFT JOIN
			|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
			|	ON
			|		TableOfProductDiscrepancies.Ref = DocumentAmounts_.Ref
			|		AND TableOfProductDiscrepancies.RowID = DocumentAmounts_.RowID
			|WHERE
			|	TableOfProductDiscrepancies.Ref = &Ref
			|	AND TableOfProductDiscrepancies.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
			|	AND &NewWayToCreateApplicationForGoodsImportFromEAEU";
			
			PurchaseAdjustmentLocalization.AddRequestTextTableProductsForImportDocuments(TextProducts_1);

			ImportAccounting.ReflectImportOfGoodsFromCustomsUnionNewMechanics(Query, QueryTexts, Registers, TextProducts_1);	
		
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.DocumentBasis.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.PurchaseAdjustment.Discrepancies AS Table
		|		LEFT JOIN Document.PurchaseAdjustment AS DocumentDataHeader
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
		|	Document.PurchaseAdjustment.ARAPAdjustment AS Table
		|		LEFT JOIN Document.PurchaseAdjustment AS DocumentDataHeader
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
		|	Document.PurchaseAdjustment.Discrepancies AS Table
		|		LEFT JOIN Document.PurchaseAdjustment AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region Purchase
	
	TextPurchase = "
		|SELECT
		|	Table.Ref                                                                      AS Ref,
		|	Table.Ref.Organization                                                          AS Organization,
		|	Table.Ref.Partner                                                              AS Partner,
		|	Table.Ref.Date                                                                 AS RecorderDate,
		|	Table.Ref.Number                                                                AS RecorderNumber,
		|	
		|	Table.ARAPObject                                                              AS ARAPObject,
		|	Table.Ref.PaymentDate                                                          AS PaymentDate,
		|	UNDEFINED                                                                        AS PaymentOption,
		|	Table.PurchaseOrder                                                             AS PurchaseOrder_,
		|	Table.AmountIncludingVAT                                                                   AS Sum,
		|	CASE WHEN Table.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
		|		OR NOT CASE WHEN Table.Ref.DocumentBasis REFS Document.VendorInvoice
		|					THEN Table.Ref.DocumentBasis.ToReturnReusablePackage
		|				ELSE TRUE
		|			END
		|		OR CASE WHEN Table.Ref.DocumentBasis REFS Document.VendorInvoice
		|					THEN Table.Ref.DocumentBasis.PackageDepositIsRequired
		|				ELSE TRUE
		|			END
		|			THEN Table.AmountARAP
		|		ELSE 0
		|	END                                                                               AS AmountARAP,
		|	CASE WHEN Table.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
		|		AND CASE WHEN Table.Ref.DocumentBasis REFS Document.VendorInvoice
		|					THEN Table.Ref.DocumentBasis.PackageDepositIsRequired
		|				ELSE FALSE
		|			END
		|			THEN Table.AmountARAP
		|		ELSE 0
		|	END                                                                               AS AmountARAPByPackage,
		|
		|	Table.Ref.ARAPObjectSettings                                                      AS ARAPObjectSettings,
		|	Table.Ref.ReceiptUnderOrders                                                 AS InvoiceForOrders,
		|	Table.Ref.ARAPCurrency                                                 AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.ARAPAdjustment)             AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                                          AS PaymentMethod,
		|	Table.Ref.Currency                                                               AS DocumentCurrency,
		|	Table.Ref.DocumentBasis.Date                                               AS DateOfCourse,
		|	Table.Ref.DocumentBasis                                                    AS LinkedDocument	
		|FROM
		|	Document.PurchaseAdjustment.Discrepancies AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.AmountIncludingVAT > 0
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref                                                                      AS Ref,
		|	Table.Ref.Organization                                                          AS Organization,
		|	Table.Ref.Partner                                                              AS Partner,
		|	Table.Ref.Date                                                                 AS RecorderDate,
		|	Table.Ref.Number                                                                AS RecorderNumber,
		|	
		|	Table.ARAPObject                                                              AS ARAPObject,
		|	Table.Ref.PaymentDate                                                          AS PaymentDate,
		|	UNDEFINED                                                                        AS PaymentOption,
		|	UNDEFINED                                                                        AS PurchaseOrder_,
		|	Table.AdjustmentSum                                                          AS Sum,
		|	Table.AmountARAP                                                         AS AmountARAP,
		|	0 AS AmountARAPByPackage,
		|
		|	UNDEFINED                                                                        AS ARAPObjectSettings,
		|	FALSE                                                                                AS InvoiceForOrders,
		|	Table.Ref.ARAPCurrency                                                 AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.ARAPAdjustment)             AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                                          AS PaymentMethod,
		|	Table.Ref.Currency                                                               AS DocumentCurrency,
		|	Table.Ref.Date                                                                 AS DateOfCourse,
		|	Table.DocumentAcquisitions                                                        AS LinkedDocument	
		|FROM
		|	Document.PurchaseAdjustment.ARAPAdjustment AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated)
		|";
	
	#EndRegion
	
	#Region IncreasePaymentPlan_
	
	TextPaymentPlan_ = "
		|SELECT
		|	Table.Ref                                                                      AS Ref,
		|	Table.Ref.Organization                                                          AS Organization,
		|	Table.Ref.Partner                                                              AS Partner,
		|	Table.Ref.Date                                                                 AS RecorderDate,
		|	Table.Ref.Number                                                                AS RecorderNumber,
		|	Table.Ref.PaymentDate                                                          AS PaymentDate,
		|	
		|	Table.ARAPObject                                                              AS ARAPObject,
		|	Table.Ref.ARAPObjectSettings                                                      AS ARAPObjectSettings,
		|	Table.Ref.ReceiptUnderOrders                                                 AS InvoiceForOrders,
		|	TRUE                                                                              AS ExceedingOrder,
		|	Table.PurchaseOrder                                                             AS PurchaseOrder_,
		|	Table.AmountARAP                                                         AS AmountDue,
		|	Table.Ref.ARAPCurrency                                                 AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.ARAPAdjustment)             AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                                          AS PaymentMethod,
		|	Table.Ref.Currency                                                               AS DocumentCurrency,
		|	Table.Ref.Date                                                                 AS DateOfCourse,
		|	UNDEFINED                                                                        AS PaymentOption,
		|	Table.Ref.DocumentBasis             	                                    AS LinkedDocument
		|FROM
		|	Document.PurchaseAdjustment.Discrepancies AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.AmountIncludingVAT > 0
		|	AND (Table.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
		|		OR Table.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
		|				AND CASE WHEN Table.Ref.DocumentBasis REFS Document.VendorInvoice
		|						THEN Table.Ref.DocumentBasis.PackageDepositIsRequired
		|					ELSE FALSE
		|				END
		|		OR NOT CASE WHEN Table.Ref.DocumentBasis REFS Document.VendorInvoice
		|					THEN Table.Ref.DocumentBasis.ToReturnReusablePackage
		|				ELSE FALSE
		|				END
		|		OR Table.Products.ItemsType IS NULL)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref                                                                      AS Ref,
		|	Table.Ref.Organization                                                          AS Organization,
		|	Table.Ref.Partner                                                              AS Partner,
		|	Table.Ref.Date                                                                 AS RecorderDate,
		|	Table.Ref.Number                                                                AS RecorderNumber,
		|	Table.Ref.PaymentDate                                                          AS PaymentDate,
		|	
		|	Table.ARAPObject                                                              AS ARAPObject,
		|	UNDEFINED                                                                        AS ARAPObjectSettings,
		|	FALSE                                                                                AS InvoiceForOrders,
		|	TRUE                                                                              AS ExceedingOrder,
		|	UNDEFINED                                                                        AS PurchaseOrder_,
		|	Table.AmountARAP                                                         AS AmountDue,
		|	Table.Ref.ARAPCurrency                                                 AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.ARAPAdjustment)             AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                                          AS PaymentMethod,
		|	Table.Ref.Currency                                                               AS DocumentCurrency,
		|	Table.Ref.Date                                                                 AS DateOfCourse,
		|	UNDEFINED                                                                        AS PaymentOption,
		|	Table.DocumentAcquisitions                                                        AS LinkedDocument
		|FROM
		|	Document.PurchaseAdjustment.ARAPAdjustment AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated)
		|";

	#EndRegion
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan_);
	
		TextPayment = "
		|SELECT
		|	Table.Ref                                                                      AS Ref,
		|	Table.Ref.Organization                                                          AS Organization,
		|	Table.Ref.Partner                                                              AS Partner,
		|	Table.Ref.Date                                                                 AS RecorderDate,
		|	Table.Ref.Number                                                                AS RecorderNumber,
		|	
		|	Table.Ref.ARAPCurrency                                                 AS ARAPCurrency,
		|	Table.ARAPObject                                                              AS ARAPObject,
		|	-Table.AmountIncludingVAT                                                                  AS Sum,
		|	-Table.AmountARAP                                                        AS AmountARAP,
		|	0                                                                                   AS IncreaseIsPaid,
		|	0                                                                                   AS ReductionIsPaid,
		|	0                                                                                   AS SumMan,
		|	0                                                                                   AS SumCompl,
		|
		|	VALUE(Enum.BusinessTransactions.ARAPAdjustment)             AS BusinessOperation,
		|	UNDEFINED                                                                        AS CashFlowItem,
		|	UNDEFINED                                                                        AS PaymentRequest,
		|	Table.Ref.PaymentMethod                                                          AS PaymentMethod,
		|	Table.Ref.Currency                                                               AS DocumentCurrency,
		|	Table.Ref.DocumentBasis.Date                                               AS DateOfCourse,
		|	DATETIME(1,1,1)                                                                    AS MaturityDate,
		|	Table.Ref.DocumentBasis                                                    AS LinkedDocument,
		|	Table.ARAPObject.UUID                                      AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)                    AS BusinessTransactionSetting
		|	
		|FROM
		|	Document.PurchaseAdjustment.Discrepancies AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.AmountIncludingVAT < 0
		|	AND (Table.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
		|		OR Table.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
		|				AND CASE WHEN Table.Ref.DocumentBasis REFS Document.VendorInvoice
		|						THEN Table.Ref.DocumentBasis.PackageDepositIsRequired
		|					ELSE FALSE
		|				END
		|		OR NOT CASE WHEN Table.Ref.DocumentBasis REFS Document.VendorInvoice
		|					THEN Table.Ref.DocumentBasis.ToReturnReusablePackage
		|				ELSE FALSE
		|				END
		|		OR Table.Products.ItemsType IS NULL)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref                                                                      AS Ref,
		|	Table.Ref.Organization                                                          AS Organization,
		|	Table.Ref.Partner                                                              AS Partner,
		|	Table.Ref.Date                                                                 AS RecorderDate,
		|	Table.Ref.Number                                                                AS RecorderNumber,
		|	
		|	Table.Ref.ARAPCurrency                                                 AS ARAPCurrency,
		|	Table.ARAPObject                                                              AS ARAPObject,
		|	Table.AdjustmentSum                                                          AS Sum,
		|	Table.AmountARAP                                                         AS AmountARAP,
		|	0                                                                                   AS IncreaseIsPaid,
		|	0                                                                                   AS ReductionIsPaid,
		|	0                                                                                   AS SumMan,
		|	0                                                                                   AS SumCompl,
		|
		|	VALUE(Enum.BusinessTransactions.ARAPAdjustment)             AS BusinessOperation,
		|	UNDEFINED                                                                        AS CashFlowItem,
		|	UNDEFINED                                                                        AS PaymentRequest,
		|	Table.Ref.PaymentMethod                                                          AS PaymentMethod,
		|	Table.Ref.Currency                                                               AS DocumentCurrency,
		|	Table.Ref.Date                                                                 AS DateOfCourse,
		|	DATETIME(1,1,1)                                                                    AS MaturityDate,
		|	Table.Ref.DocumentBasis                                                    AS LinkedDocument,
		|	Table.ARAPObject.UUID                                      AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)                    AS BusinessTransactionSetting
		|	
		|FROM
		|	Document.PurchaseAdjustment.ARAPAdjustment AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated)
		|";
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.MakingPaymentToSupplier(Query, QueryTexts, Registers, TextPayment,"3");
	
EndProcedure

Function QueryTextTableGoodsAndServicesToRegisterPurchasingReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsAndServicesToRegisterPurchasingReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductDiscrepancyTable", QueryTexts) Then
		QueryTextTTProductDiscrepancyTable(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|  DivergenceTable.Products AS Products,
	|  DivergenceTable.Characteristic AS Characteristic,
	|	&Ref AS DocumentAcquisitions,
	|	DivergenceTable.Purpose AS Purpose,
	|	DivergenceTable.Count AS Count,
	|	DivergenceTable.QuantityByGBRN AS QuantityByGBRN,
	|	&ARAPCurrency AS Currency,
	|	DivergenceTable.CCDNumber AS CCDNumber,
	|	DivergenceTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	DivergenceTable.VATAmount AS VATAmount,
	|	CASE
	|		WHEN ISNULL(Assignments.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|			THEN DivergenceTable.AmountExcludingVATCompl + DivergenceTable.VATAmountCompl
	|		ELSE 0
	|	END AS SumCompl,
	|	CASE
	|		WHEN ISNULL(Assignments.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|			THEN DivergenceTable.AmountExcludingVATMan + DivergenceTable.VATAmountMan
	|		ELSE 0
	|	END AS SumMan,
	|	FALSE AS Primary,
	|	DivergenceTable.FinRecordID AS FinRecordID,
	|	DivergenceTable.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	DivergenceTable.RowID AS RowID,
	|	CASE
	|		WHEN ISNULL(Assignments.ConsiderVATRates, FALSE)
	|			THEN DivergenceTable.VATRate
	|		ELSE VALUE(Catalog.VATRates.EmptyRef)
	|	END AS VATRate
	|FROM
	|	TTProductDiscrepancyTable AS DivergenceTable
	|LEFT JOIN
	|	Catalog.Assignments AS Assignments
	|ON
	|	DivergenceTable.Purpose = Assignments.Ref
	|WHERE
	|	&DocumentIsNotAcquisition
	|	AND &BusinessTransactionGrounds IN (&BusinessTransactionsDeliveryUnderPrincipal)
	|	AND DivergenceTable.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|	AND (CASE DivergenceTable.ItemsType 
	|			WHEN VALUE(Enum.ItemsTypes.OwnGoods) THEN TRUE
	|			WHEN VALUE(Enum.ItemsTypes.Work_5) THEN TRUE
	|			WHEN VALUE(Enum.ItemsTypes.ReusablePackage) THEN NOT &ToReturnReusablePackage
	|			ELSE FALSE
	|		END)	
	|	AND NOT &UninvoicedReceiptDocumentIsUsed
	|	AND DivergenceTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref         AS Ref,
		|	TabPart.Ref.Date    AS Period,
		|	TabPart.Products   AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	
		|	CASE WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN
		|				TabPart.Department
		|			ELSE
		|				TabPart.Warehouse
		|		END AS Warehouse,
		|	
		|	TabPart.Purpose     AS Purpose,
		|	CASE
		|		WHEN TabPart.ToControlQuality
		|			THEN TabPart.ControlledLotReference
		|		ELSE
		|			VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotReference,
		|	-TabPart.Count    AS Count,
		|	UNDEFINED            AS PlannedConsumptionOfDistributedStock,
		|	FALSE                    AS ControlOfFreeResidue
		|FROM
		|	Document.PurchaseAdjustment.Discrepancies AS TabPart
		|WHERE
		|	TabPart.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseReduceWarehouseStock)
		|		OR TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			AND TabPart.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost)
		|			AND NOT (TabPart.Ref.BusinessOperation IN(
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|					VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|				AND ISNULL(TabPart.Ref.Contract.PurchaseRegistrationOption = VALUE(Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices),
		|					FALSE))
		|			AND NOT TabPart.Ref.BusinessOperation IN(
		|				VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment))
		|			AND NOT TabPart.ToExpenseAs
		|";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref         AS Ref,
		|	TabPart.Ref.Date    AS Period,
		|	TabPart.Products   AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	
		|	CASE WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN
		|				TabPart.Department
		|			ELSE
		|				TabPart.Warehouse
		|		END AS Warehouse,
		|	
		|	TabPart.Purpose     AS Purpose,
		|	TabPart.ControlledLotReference AS ControlledLotReference,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	ISNULL(TabPart.ControlledLotReference.ScheduleGoodsUnlock, TRUE) AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count     AS Count,
		|	FALSE                    AS OnSchedule,
		|	UNDEFINED            AS OrderInSchedule
		|FROM
		|	Document.PurchaseAdjustment.Discrepancies AS TabPart
		|WHERE
		|	TabPart.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncreaseWarehouseStock)
		|		OR TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			AND TabPart.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost)
		|			AND NOT (TabPart.Ref.BusinessOperation IN(
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|					VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|				AND (ISNULL(TabPart.Ref.Contract.PurchaseRegistrationOption = VALUE(Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices),
		|					FALSE)
		|					OR ISNULL(TabPart.Ref.Contract.OptionForRegisteringServiceReceiptDocuments = VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced),
		|						FALSE)))
		|			AND NOT TabPart.Ref.BusinessOperation IN(
		|				VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment))
		|			AND NOT TabPart.ToExpenseAs
		|";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	-TabPart.Count AS Count,
		|	CASE
		|		WHEN
		|			TabPart.Ref.GoodsReceiptOption IN(
		|				VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
		|				VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed),
		|				VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
		|			THEN TabPart.Ref.Terms
		|		WHEN TabPart.Ref.GoodsReceiptOption IN(
		|				VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
		|				VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
		|				VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|			THEN TabPart.Ref.Contract
		|		WHEN TabPart.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|				OR NOT TabPart.Ref.ReceiptUnderOrders
		|			THEN TabPart.Ref.DocumentBasis
		|		ELSE TabPart.PurchaseOrder
		|	END AS OrderInSchedule
		|FROM
		|	Document.PurchaseAdjustment.Discrepancies AS TabPart
		|WHERE
		|	TabPart.PostingOption IN(
		|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost),
		|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost),
		|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners),
		|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners))
		|	AND (TabPart.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND TabPart.Ref.BusinessOperation IN(
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|				VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|		OR TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			AND TabPart.Ref.BusinessOperation IN(
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|			AND (ISNULL(TabPart.Ref.Contract.PurchaseRegistrationOption = VALUE(Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices),
		|				FALSE)
		|				OR ISNULL(TabPart.Ref.Contract.OptionForRegisteringServiceReceiptDocuments = VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced),
		|					FALSE)))
		|";
	
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
	AdditionalParameters.Add("VATReceiptDocument");
	
	If Query <> Undefined Then
		SetRequestParameterVATReceiptDocument(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTableTypesOfInventoryRegistration");
	AdditionalTables.Add("TTTableTypesOfInventoryWriteOff");
	AdditionalTables.Add("TTProductDiscrepancyTable");
	AdditionalTables.Add("TTBatchProduction");
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTableTypesOfInventoryRegistration(Query, QueryTexts);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[1], QueryTexts) Then
			QueryTextTTTableTypesOfInventoryWriteOff(Query, QueryTexts);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[2], QueryTexts) Then
			QueryTextTTProductDiscrepancyTable(Query, QueryTexts);
		EndIf;
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[3], QueryTexts) Then
			QueryTextTTBatchProduction(Query, QueryTexts);
		EndIf;
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	// Adjustment of the delivery invoice.
	// When adjusting, there may be the following options:
	// - increase in quantity in the Cur period and in the next period
	//		The movements "Arrival" are formed according to the register "Cost of goods" with the type of record "Consumption" and positive quantity and cost.
	//		The business transaction should be "Purchase from a supplier (delivery invoice)" or "Import from the EAEU (delivery invoice)".
	//		Corresponds to the movements of the invoice for the delivery of documents "Purchase of goods and services". 
	// - decrease in quantity in the Cur period and in the next period
	//		Movements "Arrival" are formed according to the register "Cost of goods" with the type of record "Reverse consumption" and negative quantity and cost.
	//		the Attribute "source document" indicates the corrected document "purchase of goods and services" for the invoice of delivery.
	// - increase or decrease in value in the Cur or in the next period
	//		The movements "Arrival" are formed according to the register "Cost of goods" with the entry type "Additional expenses (batch specified)".
	//		the Attribute "source document" indicates the corrected document "purchase of goods and services" for the invoice of delivery.
	
	#Region ExternalReceipt_Item_Registration
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|			THEN &DocumentBasis
	|		WHEN TableTypesOfStocks_.Count = 0
	|			THEN &DocumentBasis
	|		ELSE UNDEFINED
	|	END 						AS DocumentSource,
	|	(CASE
	// When using a medium-slip adjustment before entering the Balance is reflected by the document period, because
	// there will be no Registered Recorded movements in the "Cost of Goods" register during the base document period and deviations
	// in the cost will not be distributed.
	|		WHEN &MovingAverage
	|		 AND DocumentTable.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|			THEN DocumentTable.Date
	|		ELSE &ReceiptPeriod
	|	END)						AS SourceDocumentPeriod,
	|	UNDEFINED				AS VariancePeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	&VATReceiptDocument								AS Lot,
	|	CASE WHEN &BatchAccountingVersion22
	|		THEN TableTypesOfStocks_.VATActivityType
	|		ELSE UNDEFINED
	|	END 												AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes 			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes				AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID			AS RowID,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.Count = 0
	|		 AND BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|			THEN 0 
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan
	|	END 											AS Cost,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.Count = 0
	|		 AND BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|			THEN 0 
	|		ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS CostExcludingVAT,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.Count = 0
	|		 AND BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|			THEN 0
	|			ELSE TableTypesOfStocks_.AmountExcludingVATCompl
	|	END 											AS LocalCost,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0 
	|		WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN 0
	|			ELSE TableTypesOfStocks_.VATAmountCompl
	|	END								 			AS VATLocal,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.Count = 0
	|		 AND BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|			THEN 0
	|			ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS CostMan,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0 
	|		WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN 0
	|			ELSE TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.AmountExcludingVATMan
	|	END AS VATManag,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END 											AS OffBalanceCost,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|		THEN TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl
	|		ELSE 0
	|	END 											AS OffBalanceCostLocal,
	|	(CASE
	|		WHEN TableTypesOfStocks_.Count = 0
	|		 AND BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|			THEN TableTypesOfStocks_.AmountIncludingVATMan
	|	ELSE 0 END) AS AddExpensesForGoods,
	|	(CASE
	|		WHEN TableTypesOfStocks_.Count = 0
	|		 AND BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|			THEN TableTypesOfStocks_.AmountExcludingVATMan
	|	ELSE 0 END) AS AdditionalExpensesExcludingVAT,
	|	(CASE
	|		WHEN TableTypesOfStocks_.Count = 0
	|		 AND BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|			THEN TableTypesOfStocks_.AmountExcludingVATCompl
	|	ELSE 0 END) AS AddExpensesLocal,
	|	(CASE
	|		WHEN TableTypesOfStocks_.Count = 0
	|		 AND BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|			THEN TableTypesOfStocks_.AmountExcludingVATMan
	|	ELSE 0 END) AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Additional field
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		WHEN TableTypesOfStocks_.ShopFloorStockroom
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.Work_5)
	|		 AND TableTypesOfStocks_.Products.TracedGoods
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END 											AS AccountingSection,
	|
	// Other fields
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|			THEN VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt)
	|		WHEN TableTypesOfStocks_.Count = 0
	|		 AND BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|			THEN VALUE(Enum.BusinessTransactions.DebitNoteForPreviousPeriod)
	|		WHEN TableTypesOfStocks_.ItemsLocationAttributes.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			THEN VALUE(Enum.BusinessTransactions.ReceivingForPrincipal)
	|			ELSE VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|	END 												AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID			AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.PurchaseAdjustment AS DocumentTable
	|	INNER JOIN TTTableTypesOfInventoryRegistration AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT (BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|		AND TableTypesOfStocks_.Count = 0)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion

	#Region ExternalReceipt_Item_WriteOff
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	&DocumentBasis 			AS DocumentSource,
	|	(CASE
	// When using a medium-slip adjustment before entering the Balance is reflected by the document period, because
	// there will be no Registered Recorded movements in the "Cost of Goods" register during the base document period and deviations
	// in the cost will not be distributed.
	|		WHEN &MovingAverage
	|		 AND DocumentTable.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|			THEN DocumentTable.Date
	|		ELSE &ReceiptPeriod
	|	END)						AS SourceDocumentPeriod,
	|	UNDEFINED				AS VariancePeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	&DocumentBasis									AS Lot,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 								  		AS CorItemsLocationAttributes,
	|	UNDEFINED 								  		AS CorInventoryOwnerAttribute,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate	AS VATRate,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	-TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID			AS RowID,
	|	-CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.Count = 0
	|		 AND NOT (&MovingAverage
	|				AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery))
	|			THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan
	|	END											AS Cost,
	|	-CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.Count = 0
	|		 AND NOT (&MovingAverage
	|				AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery))
	|			THEN 0
	|		ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END											AS CostExcludingVAT,
	|	-CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.Count = 0
	|		 AND TableTypesOfStocks_.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|		 AND NOT (&MovingAverage
	|				AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery))
	|			THEN 0
	|		ELSE TableTypesOfStocks_.LocalCost
	|	END 											AS LocalCost,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN 0
	|		ELSE -TableTypesOfStocks_.VATAmountCompl
	|	END								 			AS VATLocal,
	|	-CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.Count = 0
	|		 AND TableTypesOfStocks_.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|		 AND NOT (&MovingAverage
	|				AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery))
	|			THEN 0
	|		ELSE TableTypesOfStocks_.CostMan
	|	END											AS CostMan,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN 0
	|		ELSE -(TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.AmountExcludingVATMan)
	|	END								 			AS VATManag,
	|	-(CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0 END)								AS OffBalanceCost,
	|	-(CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl
	|		ELSE 0 END)								AS OffBalanceCostLocal,
	|	-CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		WHEN NOT TableTypesOfStocks_.Count = 0
	|		 OR &MovingAverage
	|				AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|			THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan
	|	END											AS AddExpensesForGoods,
	|	-CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|		 OR &MovingAverage
	|				AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|			THEN 0
	|		WHEN NOT TableTypesOfStocks_.Count = 0
	|			THEN 0
	|		ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END											AS AdditionalExpensesExcludingVAT,
	|	-CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.Count <> 0
	|		 OR TableTypesOfStocks_.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|		 OR &MovingAverage
	|				AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|			THEN 0
	|		ELSE TableTypesOfStocks_.AddExpensesLocal
	|	END 											AS AddExpensesLocal,
	|	-CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.Count <> 0
	|		 OR TableTypesOfStocks_.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|		 OR &MovingAverage
	|				AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|			THEN 0
	|		ELSE TableTypesOfStocks_.AddExpensesMan
	|	END											AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	TableTypesOfStocks_.CostTD 			AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|			THEN VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt)
	|		WHEN TableTypesOfStocks_.Count = 0
	|			THEN VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|		WHEN TableTypesOfStocks_.Count = 0
	|		 AND BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|			THEN VALUE(Enum.BusinessTransactions.DebitNoteForPreviousPeriod)
	|		ELSE VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor) END) AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID							  AS FinRecordID,
	// Setting up an economic operation of operations in Registered Recording with a decrease in quantity should be different from setting up an economic of operation
	// in Registered Recording with an increase in quantity for the correct operation of the MFPs.
	|	VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsToVendor) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.PurchaseAdjustment AS DocumentTable
	|	INNER JOIN TTTableTypesOfInventoryWriteOff AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell),
	|		VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery),
	|		VALUE(Enum.InventoryTypes.OwnGoodsInTransit))
	|	AND (TableTypesOfStocks_.ThisIsRefundToSupplier
	|		OR NOT (BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|			AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|			AND TableTypesOfStocks_.Count = 0))
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion

	#Region ExternalInput_Adjustment
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	&DocumentBasis			AS DocumentSource,
	|	(CASE
	// When using a medium-slip adjustment before entering the Balance is reflected by the document period, because
	// there will be no Registered Recorded movements in the "Cost of Goods" register during the base document period and deviations
	// in the cost will not be distributed.
	|		WHEN &MovingAverage
	|		 AND DocumentTable.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|			THEN DocumentTable.Date
	|		ELSE &ReceiptPeriod
	|	END)						AS SourceDocumentPeriod,
	|	&AdjustmentPeriod_ 		AS VariancePeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	&DocumentBasis									AS Lot,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 								  		AS CorItemsLocationAttributes,
	|	UNDEFINED 								  		AS CorInventoryOwnerAttribute,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate	AS VATRate,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	0												AS Count,
	|	TableTypesOfStocks_.RowID			AS RowID,
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	// With a sliding average, the total adjustments of any period are reflected in the register "Deviations in the cost of goods" through the additional expense fields,
	// except for the cost adjustment of the delivery invoice.
	|	 AND (NOT &MovingAverage
	|		OR TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery))
	|	 OR NOT &BatchAccountingVersion22
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END 											AS Cost,
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|	 AND (NOT &MovingAverage
	|		OR TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery))
	|	  OR NOT &BatchAccountingVersion22
	|		THEN TableTypesOfStocks_.AmountExcludingVATMan
	|		ELSE 0
	|	END 											AS CostExcludingVAT,
	|	TableTypesOfStocks_.LocalCost 				AS LocalCost,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmountCompl
	|	END								 			AS VATLocal,
	|	TableTypesOfStocks_.CostMan 				AS CostMan,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|	  AND (NOT &MovingAverage
	|		OR TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery))
	|	  OR NOT &BatchAccountingVersion22
	|		THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan
	|	END 											AS AddExpensesForGoods,
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|	  AND (NOT &MovingAverage
	|		OR TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery))
	|	  OR NOT &BatchAccountingVersion22
	|		THEN 0
	|		ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS AdditionalExpensesExcludingVAT,
	|	TableTypesOfStocks_.AddExpensesLocal 				AS AddExpensesLocal,
	|	TableTypesOfStocks_.AddExpensesMan 				AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	TableTypesOfStocks_.CostTD 			AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|	 OR &MovingAverage
	|	  AND DocumentTable.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|		THEN VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|		ELSE VALUE(Enum.BusinessTransactions.DebitNoteForPreviousPeriod)
	|	END 												AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID			AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.PurchaseAdjustment AS DocumentTable
	|	INNER JOIN TTProductDiscrepancyTable AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND (TableTypesOfStocks_.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost)
	|		OR (TableTypesOfStocks_.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost)
	|			AND &BatchAccountingVersion22)
	|		OR (BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|			AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|			AND TableTypesOfStocks_.Count = 0
	|			AND TableTypesOfStocks_.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier)
	|			)
	|		)
	|	AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery),
	|		VALUE(Enum.InventoryTypes.OwnGoodsInTransit))
	|	AND NOT TableTypesOfStocks_.ToExpenseAs";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion

	#Region ExternalInput_Adjustment__21
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED				AS VariancePeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	&DocumentBasis 									AS Lot,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	DocumentTable.VATTaxation					AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 								  		AS CorItemsLocationAttributes,
	|	UNDEFINED 								  		AS CorInventoryOwnerAttribute,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate	AS VATRate,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	0												AS Count,
	|	TableTypesOfStocks_.RowID			AS RowID,
	|	0 												AS Cost,
	|	0 												AS CostExcludingVAT,
	|	TableTypesOfStocks_.LocalCost 				AS LocalCost,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmountCompl
	|	END								 			AS VATLocal,
	|	0 												AS CostMan,
	|	0 												AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	TableTypesOfStocks_.AmountIncludingVATMan					AS AddExpensesForGoods,
	|	TableTypesOfStocks_.AmountExcludingVATMan				AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	TableTypesOfStocks_.CostTD 			AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)	AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID						AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting				AS BusinessTransactionSetting
	|
	|FROM
	|	Document.PurchaseAdjustment AS DocumentTable
	|	INNER JOIN TTProductDiscrepancyTable AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost)
	|	AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND NOT &BatchAccountingVersion22";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion

	#Region ExternalInput_Adjustment_Work
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	&DocumentBasis			AS DocumentSource,
	|	&ReceiptPeriod			AS SourceDocumentPeriod,
	|	&AdjustmentPeriod_		AS VariancePeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	&DocumentBasis  								AS Lot,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 								  		AS CorItemsLocationAttributes,
	|	UNDEFINED 								  		AS CorInventoryOwnerAttribute,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate	AS VATRate,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID			AS RowID,
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	// With a sliding average, the total adjustments of any period are reflected in the register "Deviations in the cost of goods" through the additional expense fields.
	|	 AND NOT &MovingAverage
	|	  OR TableTypesOfStocks_.Count > 0
	|			THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		WHEN TableTypesOfStocks_.Count < 0
	|			THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END 											AS Cost,
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|	 AND NOT &MovingAverage
	|	  OR TableTypesOfStocks_.Count > 0
	|			THEN TableTypesOfStocks_.AmountExcludingVATMan
	|		WHEN TableTypesOfStocks_.Count < 0
	|			THEN TableTypesOfStocks_.AmountExcludingVATMan
	|		ELSE 0
	|	END 											AS CostExcludingVAT,
	|	TableTypesOfStocks_.LocalCost				AS LocalCost,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmountCompl
	|	END								 			AS VATLocal,
	|	TableTypesOfStocks_.CostMan					AS CostMan,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|	 AND NOT &MovingAverage
	|			THEN 0
	|		WHEN TableTypesOfStocks_.Count <> 0
	|			THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan
	|	END 											AS AddExpensesForGoods,
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|	 AND NOT &MovingAverage
	|			THEN 0
	|		WHEN TableTypesOfStocks_.Count <> 0
	|			THEN 0
	|		ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS AdditionalExpensesExcludingVAT,
	|	TableTypesOfStocks_.AddExpensesLocal				AS AddExpensesLocal,
	|	TableTypesOfStocks_.AddExpensesMan				AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Additional field
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) AS AccountingSection,
	|
	// Other fields
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|	  OR TableTypesOfStocks_.Count >= 0
	|			THEN VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|		WHEN TableTypesOfStocks_.Count < 0
	|			THEN VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
	|		ELSE VALUE(Enum.BusinessTransactions.DebitNoteForPreviousPeriod)
	|	END 												AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID			AS FinRecordID,
	// Setting up an economic operation of operations in Registered Recording with a decrease in quantity should be different from setting up an economic of operation
	// in Registered Recording with an increase in quantity for the correct operation of the MFPs.
	|	CASE
	|		WHEN TableTypesOfStocks_.Count >= 0
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsToVendor)
	|	END 												AS BusinessTransactionSetting
	|
	|FROM
	|	Document.PurchaseAdjustment AS DocumentTable
	|
	|	INNER JOIN TTProductDiscrepancyTable AS TableTypesOfStocks_
	|	ON TRUE
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT TableTypesOfStocks_.Products.TracedGoods
	|	AND NOT &UnfacturedDeliveriesOfServicesWorks
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND (TableTypesOfStocks_.Purpose = VALUE(Catalog.Assignments.EmptyRef) OR
	|		TableTypesOfStocks_.Purpose.AssignmentType <> VALUE(Enum.AssignmentTypes.DeliveryForPrincipal))
	|	AND NOT DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment)
	|	AND NOT TableTypesOfStocks_.PostingOption IN (
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs),
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome))
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion
	
	#Region ExternalReceipt_Correction_NonProcessing_OfWorksAndServices
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	&DocumentBasis			AS DocumentSource,
	|	&ReceiptPeriod			AS SourceDocumentPeriod,
	|	&AdjustmentPeriod_		AS VariancePeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	DocumentTable.Ref 							AS Lot,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	DocumentTable.VATTaxation					AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 								  		AS CorItemsLocationAttributes,
	|	UNDEFINED 								  		AS CorInventoryOwnerAttribute,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes				AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes				AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate	AS VATRate,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID			AS RowID,
	|	CASE
	|		WHEN &MovingAverage
	|			THEN 0
	|		WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|	  	OR TableTypesOfStocks_.Count > 0
	|			THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		WHEN TableTypesOfStocks_.Count < 0
	|			THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END 											AS Cost,
	|	CASE
	|		WHEN &MovingAverage
	|			THEN 0
	|		WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|		  OR TableTypesOfStocks_.Count > 0
	|			THEN TableTypesOfStocks_.AmountExcludingVATMan
	|		WHEN TableTypesOfStocks_.Count < 0
	|			THEN TableTypesOfStocks_.AmountExcludingVATMan
	|		ELSE 0
	|	END 											AS CostExcludingVAT,
	|	CASE
	|		WHEN &MovingAverage
	|			THEN 0
	|		WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|		 AND NOT &MovingAverage
	|		  AND TableTypesOfStocks_.Count = 0
	|			THEN 0
	|		WHEN TableTypesOfStocks_.VATActivityType IN (
	|		  VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|		  VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl
	|		ELSE TableTypesOfStocks_.AmountExcludingVATCompl
	|	END 											AS LocalCost,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmountCompl
	|	END								 			AS VATLocal,
	|	CASE
	|		WHEN &MovingAverage
	|			THEN 0
	|		WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) <> BEGINOFPERIOD(&Period, MONTH)
	|		  AND TableTypesOfStocks_.Count = 0
	|			THEN 0
	|		WHEN TableTypesOfStocks_.VATActivityType IN (
	|		  VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|		  VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS CostMan,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|	 AND NOT &MovingAverage
	|			THEN 0
	|		WHEN TableTypesOfStocks_.Count <> 0
	|			THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan
	|	END 											AS AddExpensesForGoods,
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|	 AND NOT &MovingAverage
	|			THEN 0
	|		WHEN TableTypesOfStocks_.Count <> 0
	|			THEN 0
	|		ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS AdditionalExpensesExcludingVAT,
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|	 AND NOT &MovingAverage
	|	  OR TableTypesOfStocks_.Count <> 0
	|			THEN 0
	|		WHEN TableTypesOfStocks_.VATActivityType IN (
	|		  VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|		  VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl
	|		ELSE TableTypesOfStocks_.AmountExcludingVATCompl
	|	END 											AS AddExpensesLocal,
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|	 AND NOT &MovingAverage
	|	  OR TableTypesOfStocks_.Count <> 0
	|			THEN 0
	|		WHEN TableTypesOfStocks_.VATActivityType IN (
	|		  VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|		  VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Additional field
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries) AS AccountingSection,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt) AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID			AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.PurchaseAdjustment AS DocumentTable
	|
	|	INNER JOIN TTProductDiscrepancyTable AS TableTypesOfStocks_
	|	ON TRUE
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.ItemsType IN (VALUE(Enum.ItemsTypes.Work_5),
	|											VALUE(Enum.ItemsTypes.OperationService))
	|	AND &UnfacturedDeliveriesOfServicesWorks
	|	AND NOT TableTypesOfStocks_.PostingOption IN (
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs),
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome))
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion
	#Region ExternalReceipt_Adjusting_Work_5_SubcontractorReport
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	&DocumentBasis			AS DocumentSource,
	|	&ReceiptPeriod			AS SourceDocumentPeriod,
	|	&AdjustmentPeriod_		AS VariancePeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	ProductionLots.ProductionLot               AS Lot,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 								  		AS CorItemsLocationAttributes,
	|	UNDEFINED 								  		AS CorInventoryOwnerAttribute,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner						AS Vendor,
	|	DocumentTable.Counterparty 					AS Counterparty,
	|	TableTypesOfStocks_.VATRate					AS VATRate,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department 		AS Department,
	|	DocumentTable.Manager 			AS Manager,
	|	ProductionLots.ProductsGroup  AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID			AS RowID,
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|	  OR TableTypesOfStocks_.Count > 0
	|			THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		WHEN TableTypesOfStocks_.Count < 0
	|			THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END 											AS Cost,
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|	  OR TableTypesOfStocks_.Count > 0
	|			THEN TableTypesOfStocks_.AmountExcludingVATMan
	|		WHEN TableTypesOfStocks_.Count < 0
	|			THEN TableTypesOfStocks_.AmountExcludingVATMan
	|		ELSE 0
	|	END 											AS CostExcludingVAT,
	|	TableTypesOfStocks_.LocalCost				AS LocalCost,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmountCompl
	|	END								 			AS VATLocal,
	|	TableTypesOfStocks_.CostMan					AS CostMan,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.Count <> 0
	|			THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan
	|	END 											AS AddExpensesForGoods,
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.Count <> 0
	|			THEN 0
	|		ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS AdditionalExpensesExcludingVAT,
	|	TableTypesOfStocks_.AddExpensesLocal				AS AddExpensesLocal,
	|	TableTypesOfStocks_.AddExpensesMan				AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Additional field
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress) AS AccountingSection,
	|
	// Other fields
	|	CASE WHEN BEGINOFPERIOD(&ReceiptPeriod, MONTH) = BEGINOFPERIOD(&Period, MONTH)
	|	  OR TableTypesOfStocks_.Count > 0
	|			THEN VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|		WHEN TableTypesOfStocks_.Count < 0
	|			THEN VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
	|		ELSE VALUE(Enum.BusinessTransactions.DebitNoteForPreviousPeriod)
	|	END 												AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID			AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.PurchaseAdjustment AS DocumentTable
	|
	|	INNER JOIN TTProductDiscrepancyTable AS TableTypesOfStocks_
	|	ON TRUE
	|
	|	LEFT JOIN TTBatchProduction AS ProductionLots
	|	ON ProductionLots.ReleaseParty = DocumentTable.DocumentBasis
	|	AND ProductionLots.CostGroupNumber = TableTypesOfStocks_.CostGroupNumber
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND (TableTypesOfStocks_.Purpose = VALUE(Catalog.Assignments.EmptyRef) OR
	|		TableTypesOfStocks_.Purpose.AssignmentType <> VALUE(Enum.AssignmentTypes.DeliveryForPrincipal))
	|	AND NOT TableTypesOfStocks_.PostingOption IN (
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs),
	|			VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome))
	// When adjusting the report of the processor of the previous period, the amount of the adjustment is attributed to the article ""Disposals of goods in previous periods"". 
	|	AND DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment)
	|	AND NOT BEGINOFPERIOD(&ReceiptPeriod, MONTH) < BEGINOFPERIOD(&Period, MONTH)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion
	Return DescriptionOfOperations;
	
EndFunction
Function QueryTextTTBatchProduction(Query, QueryTexts)
	
	RegisterName = "TTBatchProduction";
	
	QueryText = Documents.SubcontractorReport2_5.QueryTextTTBatchProduction(Query);
	QueryText = StrReplace(QueryText, "&Ref", "&DocumentBasis");
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
#EndRegion

Procedure MakeAdjustmentsToGoodsOnTwoWayBasis(Query, QueryTexts, Registers)

	QueryTextDocument_ = "
	|SELECT
	|	DataSource.Ref                        AS Ref,
	|	DataSource.Ref.DocumentBasis      AS Invoice,
	|	FALSE                                         AS Patch,
	|	UNDEFINED                                 AS CorrectedDocument,
	|	DataSource.PurchaseOrder               AS OrderDocument,
	|	DataSource.Ref.Contract                AS Contract,
	|	DataSource.Ref.Terms             AS Terms,
	|	ISNULL(DataBasis.GoodsReceiptOption, UNDEFINED) AS GoodsReceiptOption,
	|	ISNULL(DataBasis.ServiceReceiptOption, UNDEFINED) AS ServiceReceiptOption,
	|	DataSource.Ref.Date                   AS Date,
	|	
	|	CASE WHEN ISNULL(DataBasis.DateOfReceipt, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1) THEN
	|				ISNULL(DataBasis.DateOfReceipt, DATETIME(1, 1, 1))
	|			ELSE
	|				DataSource.Ref.Date
	|		END AS DateOfPlannedReceipt,
	|	
	|	DataSource.Products                  AS Products,
	|	DataSource.Characteristic                AS Characteristic,
	|	DataSource.Purpose                    AS Purpose,
	|	DataSource.ToControlQuality     AS ToControlQuality,
	|	FALSE                                         AS RecordOfAPreviouslyReceivedLot,
	|	DataSource.ControlledLotReference          AS ControlledLotReference,
	|	DataSource.Series                         AS Series,
	|	DataSource.BatchesIndicationStatus           AS BatchesIndicationStatus,
	|	TRUE								         AS ExceedingOrder,
	|	DataSource.Warehouse                         AS Warehouse,
	|	CASE
	|		WHEN DataSource.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|			THEN ISNULL(DataBasis.AdvanceHolder, DataSource.Ref.Partner)
	|		ELSE DataSource.Ref.Partner
	|	END                                        AS Sender,
	|	DataSource.Ref.BusinessOperation  AS BusinessOperation,
	|	DataSource.Count                    AS Count,
	|	TRUE                                       AS ThisIsAnInvoice,
	|	DataSource.Ref.ReceiptUnderOrders   AS ReceiptUnderOrders
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS DataSource
	|	LEFT JOIN
	|		Document.VendorInvoice AS DataBasis
	|		ON DataSource.Ref.DocumentBasis = DataBasis.Ref
	|	LEFT JOIN
	|		Catalog.Products AS CatProducts
	|		ON DataSource.Products = CatProducts.Ref
	|WHERE
	|	DataSource.Ref IN (&Ref)
	|	AND DataSource.PostingOption IN (
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners),
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners),
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost),
	|		VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.ReduceCost))
	|	AND (CASE
	|		WHEN DataSource.Ref.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			THEN FALSE
	|		WHEN (NOT DataSource.Ref.Contract.PurchaseRegistrationOption IS NULL
	|				AND DataSource.Ref.Contract.PurchaseRegistrationOption <> VALUE(Enum.PurchaseRegistrationOptions.NotSeparate))
	|				OR (NOT DataSource.Ref.Contract.OptionForRegisteringServiceReceiptDocuments IS NULL
	|				AND DataSource.Ref.Contract.OptionForRegisteringServiceReceiptDocuments <> VALUE(Enum.OptionsForRegisteringServiceDocuments.EmptyRef))
	|			THEN TRUE
	|		ELSE FALSE
	|	END)
	// Two-way.
	|	AND CASE
	|		WHEN DataSource.Ref.DocumentBasis REFS Document.VendorInvoice
	|			THEN CASE
	|				WHEN ISNULL(DataBasis.BusinessOperation, UNDEFINED) IN
	|						(VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|						VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|						VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|						VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|		ELSE FALSE
	|	END
	|";
	
	WarehousesServer.ToIssuePurchaseOfGoodsOnDvukhodovka(Query, QueryTexts, Registers, QueryTextDocument_);

	WarehousesServer.ScheduleGoodsReceipt(Query, QueryTexts, Registers, QueryTextDocument_,
		"DataSource", True);

EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// Assignment for the placement of goods
	DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "PlacementJob");
	
	PurchaseAdjustmentLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInProductsBasedOnSourceData(DocumentBasis, Goods, DocumentRef = Undefined) Export
	
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
	EndIf;
	
EndProcedure

Procedure CreateTemporaryTableOfSourceData(TempTablesManager, DocumentBasis, DocumentRef = Undefined) Export
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.VendorInvoice") Then
		RequestTextByReason = RequestTextBasedOnSourceDataPurchaseOfGoodsAndServices();
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		RequestTextByReason = RequestTextBasedOnSourceDataPurchaseOfServicesOtherAssets();
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.SubcontractorReport2_5") Then
		RequestTextByReason = RequestTextBasedOnSourceDataOfProcessorReport();
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.SourceDocument") Then
		
		QueryText = QueryTextAccordingToInitialDataOfAdjustmentsOfPrimaryDocument();
		
		If ValueIsFilled(DocumentRef) Then
			CurPointInTime = DocumentRef.PointInTime();
		Else
			CurPointInTime =
				New PointInTime(CurrentSessionDate(), Documents.PurchaseAdjustment.EmptyRef());
		EndIf;
		Query.SetParameter("CurPointInTime", CurPointInTime);
		
	Else
		
		QueryText = "
		|SELECT TOP 1
		|	PurchaseAdjustment.Ref AS Ref
		|INTO LastAdjustmentData
		|FROM
		|	Document.PurchaseAdjustment AS PurchaseAdjustment
		|	LEFT JOIN
		|		InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
		|	ON
		|		PurchaseAdjustment.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
		|		AND RegisterOfDocumentsStornoCorrection.Posted
		|		AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
		|WHERE
		|	PurchaseAdjustment.Posted
		|	AND PurchaseAdjustment.Ref <> &DocumentRef
		|	AND PurchaseAdjustment.DocumentBasis = &DocumentBasis
		|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
		|
		|ORDER BY
		|	PurchaseAdjustment.PointInTime DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsTable.LineNumber		 	 AS LineNumber,
		|	GoodsTable.PartnerProducts AS PartnerProducts,
		|	GoodsTable.Products		 	 AS Products,
		|	GoodsTable.Purpose			 AS Purpose,
		|	GoodsTable.Characteristic	 	 AS Characteristic,
		|	GoodsTable.Series				 	 AS Series,
		|	GoodsTable.BatchesIndicationStatus	 AS BatchesIndicationStatus,
		|	GoodsTable.Content		 	 AS Content,
		|	CASE
		|		WHEN GoodsTable.Package = GoodsTable.Products.UnitOfMeasure
		|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		ELSE GoodsTable.Package
		|	END								 AS Package,
		|	CASE
		|		WHEN GoodsTable.NumberOfPackages = 0
		|			THEN GoodsTable.Count
		|		ELSE
		|			GoodsTable.NumberOfPackages
		|	END							 	 AS NumberOfPackages,
		|	GoodsTable.Count		 	 AS Count,
		|	GoodsTable.QuantityByGBRN	 	 AS QuantityByGBRN,
		|	GoodsTable.Price				 	 AS Price,
		|	GoodsTable.Sum				 	 AS Sum,
		|	GoodsTable.VATRate			 	 AS VATRate,
		|	GoodsTable.VATAmount			 	 AS VATAmount,
		|	GoodsTable.AmountIncludingVAT			 	 AS AmountIncludingVAT,
		|	GoodsTable.PurchaseOrder	 	 AS PurchaseOrder,
		|	GoodsTable.RowCode			 	 AS RowCode,
		|	GoodsTable.Warehouse				 	 AS Warehouse,
		|	GoodsTable.CCDNumber			 	 AS CCDNumber,
		|	GoodsTable.FEACNCode			 	 AS FEACNCode,
		|	GoodsTable.SalesOpportunity			 	 AS SalesOpportunity,
		|	GoodsTable.Department			 AS Department,
		|	GoodsTable.CostGroupNumber      AS CostGroupNumber,
		|	GoodsTable.ProductCostElement      AS ProductCostElement,
		|	GoodsTable.ProductionStage       AS ProductionStage,
		|	GoodsTable.ToExpenseAs		 AS ToExpenseAs,
		|	GoodsTable.ExpenseItem		 AS ExpenseItem,
		|	GoodsTable.DimensionOfExpenses		 AS DimensionOfExpenses,
		|	GoodsTable.LineOfBusiness AS LineOfBusiness,
		|	GoodsTable.GLAccountSettings	 AS GLAccountSettings,
		|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue
		|	
		|INTO RawData
		|FROM
		|	Document.PurchaseAdjustment.Goods AS GoodsTable
		|	
		|	INNER JOIN LastAdjustmentData AS LastAdjustmentData
		|	ON GoodsTable.Ref = LastAdjustmentData.Ref
		|";
		
		RequestTextByReason = TMCommonUse.QuerySeparatorInJoin() + RequestTextByReason;
		
		QueryText = QueryText + RequestTextByReason
			+ Common.QueryBatchSeparator() + "DROP LastAdjustmentData";
		
	EndIf;
	
	Query.Text = QueryText;
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.SetParameter("DocumentRef", DocumentRef);
	Query.Execute();
	
EndProcedure

Function RequestTextBasedOnSourceDataPurchaseOfGoodsAndServices()
	
	QueryText = "
	|SELECT
	|	GoodsTable.LineNumber			 AS LineNumber,
	|	GoodsTable.PartnerProducts AS PartnerProducts,
	|	GoodsTable.Products		 	 AS Products,
	|	GoodsTable.Purpose		 	 AS Purpose,
	|	GoodsTable.Characteristic	 	 AS Characteristic,
	|	GoodsTable.Series				 	 AS Series,
	|	CASE WHEN GoodsTable.BatchesIndicationStatus = 14
	|		THEN 14
	|		ELSE 0
	|	END							 	 AS BatchesIndicationStatus,
	|	""""							 	 AS Content,
	|	CASE
	|		WHEN GoodsTable.Package = GoodsTable.Products.UnitOfMeasure
	|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		ELSE GoodsTable.Package
	|	END								 AS Package,
	|	GoodsTable.NumberOfPackages 	 AS NumberOfPackages,
	|	GoodsTable.Count		 	 AS Count,
	|	GoodsTable.QuantityByGBRN	 	 AS QuantityByGBRN,
	|	
	|	CASE
	|		WHEN CAST(GoodsTable.Price * GoodsTable.NumberOfPackages AS NUMBER(31,2)) = GoodsTable.Sum
	|			THEN GoodsTable.Price
	|		WHEN CAST(GoodsTable.NumberOfPackages AS NUMBER(31,3)) > 0
	|			THEN CAST(GoodsTable.Sum / GoodsTable.NumberOfPackages AS NUMBER(31,2))
	|		ELSE 0
	|	END AS Price,
	|	
	|	GoodsTable.Sum				 	 AS Sum,
	|	GoodsTable.VATRate			 	 AS VATRate,
	|	GoodsTable.VATAmount			 	 AS VATAmount,
	|	GoodsTable.AmountIncludingVAT			 	 AS AmountIncludingVAT,
	|	GoodsTable.PurchaseOrder	 	 AS PurchaseOrder,
	|	GoodsTable.RowCode			 	 AS RowCode,
	|	GoodsTable.Warehouse				 	 AS Warehouse,
	|	GoodsTable.CCDNumber			 	 AS CCDNumber,
	|	VALUE(Catalog.FEACN.EmptyRef) AS FEACNCode,
	|	GoodsTable.SalesOpportunity			 	 AS SalesOpportunity,
	|	GoodsTable.Department			 AS Department,
	|	0                                    AS CostGroupNumber,
	|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
	|	VALUE(Document.ProductionStage2_2.EmptyRef) AS ProductionStage,
	|	GoodsTable.ToExpenseAs		 AS ToExpenseAs,
	|	GoodsTable.ExpenseItem		 AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses		 AS DimensionOfExpenses,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	UNDEFINED AS DimensionOfRevenue
	|FROM
	|	Document.VendorInvoice.Goods AS GoodsTable
	|		LEFT JOIN LastAdjustmentData AS LastAdjustmentData
	|		ON TRUE
	|WHERE
	|	LastAdjustmentData.Ref IS NULL 
	|	AND GoodsTable.Ref = &DocumentBasis
	|";
	Return QueryText;
	
EndFunction

Function RequestTextBasedOnSourceDataPurchaseOfServicesOtherAssets()
	
	QueryText = "	
	|SELECT
	|	TableExpenses.LineNumber                                   AS LineNumber,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef)    AS PartnerProducts,
	|	VALUE(Catalog.Products.EmptyRef)               AS Products,
	|	VALUE(Catalog.Assignments.EmptyRef)                 AS Purpose,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef)          AS Series,
	|	0                                                            AS BatchesIndicationStatus,
	|	TableExpenses.Content                                    AS Content,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)   AS Package,
	|	TableExpenses.Count                                    AS NumberOfPackages,
	|	TableExpenses.Count                                    AS Count,
	|	TableExpenses.QuantityByGBRN                              AS QuantityByGBRN,
	|	TableExpenses.Price                                          AS Price,
	|	TableExpenses.Sum                                         AS Sum,
	|	TableExpenses.VATRate                                     AS VATRate,
	|	TableExpenses.VATAmount                                      AS VATAmount,
	|	TableExpenses.AmountIncludingVAT                                     AS AmountIncludingVAT,
	|	VALUE(Document.PurchaseOrder.EmptyRef)              AS PurchaseOrder,
	|	0                                                            AS RowCode,
	|	VALUE(Catalog.Warehouses.EmptyRef)                     AS Warehouse,
	|	TableExpenses.CCDNumber                                      AS CCDNumber,
	|	TableExpenses.FEACNCode                                      AS FEACNCode,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)           AS SalesOpportunity,
	|	TableExpenses.Department                                 AS Department,
	|	0                                                            AS CostGroupNumber,
	|	VALUE(Catalog.ProductCostElements.EmptyRef)          AS ProductCostElement,
	|	VALUE(Document.ProductionStage2_2.EmptyRef)          AS ProductionStage,
	|	TRUE                                                       AS ToExpenseAs,
	|	TableExpenses.ExpenseItem                                AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses                             AS DimensionOfExpenses,
	|	TableExpenses.LineOfBusiness                       AS LineOfBusiness,
	|	TableExpenses.GLAccountSettings                          AS GLAccountSettings,
	|	TableExpenses.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableExpenses.DimensionOfRevenue AS DimensionOfRevenue
	|FROM
	|	Document.VendorInvoiceServicesAndAssets.Expenses AS TableExpenses
	|		LEFT JOIN LastAdjustmentData AS LastAdjustmentData
	|		ON TRUE
	|WHERE
	|	LastAdjustmentData.Ref IS NULL 
	|	AND TableExpenses.Ref = &DocumentBasis
	|";
	Return QueryText;
	
EndFunction

Function RequestTextBasedOnSourceDataOfProcessorReport()
	
	QueryText = "
	|SELECT
	|	TableServices.LineNumber                                    AS LineNumber,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef)   AS PartnerProducts,
	|	TableServices.Products                                   AS Products,
	|	DimensionOfProductItem.Purpose                             AS Purpose,
	|	DimensionOfProductItem.Characteristic                         AS Characteristic,
	|	DimensionOfProductItem.Series                                  AS Series,
	|	0                                                            AS BatchesIndicationStatus,
	|	""""                                                         AS Content,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)   AS Package,
	|	TableServices.Count                                     AS NumberOfPackages,
	|	TableServices.Count                                     AS Count,
	|	0                                                            AS QuantityByGBRN,
	|	TableServices.Price                                           AS Price,
	|	TableServices.Sum                                          AS Sum,
	|	TableServices.VATRate                                      AS VATRate,
	|	TableServices.VATAmount                                       AS VATAmount,
	|	TableServices.AmountIncludingVAT                                      AS AmountIncludingVAT,
	|	SubcontractorReport2_5.SubcontractOrder                     AS PurchaseOrder,
	|	TableServices.RowCode                                      AS RowCode,
	|	VALUE(Catalog.Warehouses.EmptyRef)                     AS Warehouse,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)                  AS CCDNumber,
	|	VALUE(Catalog.FEACN.EmptyRef)         AS FEACNCode,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)           AS SalesOpportunity,
	|	SubcontractorReport2_5.Department                          AS Department,
	|	TableServices.CostGroupNumber                              AS CostGroupNumber,
	|	TableServices.ProductCostElement                              AS ProductCostElement,
	|	TableServices.ProductionStage                               AS ProductionStage,
	|	FALSE                                                         AS ToExpenseAs,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED                                                 AS DimensionOfExpenses,
	|	SubcontractorReport2_5.LineOfBusiness                AS LineOfBusiness,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	UNDEFINED                                                 AS AssetsLiabilitiesDimension,
	|	UNDEFINED                                                 AS DimensionOfRevenue
	|FROM
	|	Document.SubcontractorReport2_5.Services AS TableServices
	|	
	|	LEFT JOIN LastAdjustmentData AS LastAdjustmentData
	|	ON TRUE
	|	
	|	LEFT JOIN Document.SubcontractorReport2_5 AS SubcontractorReport2_5
	|	ON SubcontractorReport2_5.Ref = TableServices.Ref
	|	
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
	|	ON DimensionOfProductItem.Ref = TableServices.ItemsLocationAttributes
	|
	|WHERE
	|	LastAdjustmentData.Ref IS NULL 
	|	AND TableServices.Ref = &DocumentBasis
	|";
	Return QueryText;
	
EndFunction

Function QueryTextAccordingToInitialDataOfAdjustmentsOfPrimaryDocument()
	
	QueryText = "
	|SELECT TOP 1
	|	PurchaseAdjustment.Ref AS Ref,
	|	PurchaseAdjustment.PointInTime AS PointInTime,
	|	PurchaseAdjustment.AdjustingEntryType AS AdjustingEntryType,
	|	PurchaseAdjustment.PriceIncludesVAT AS PriceIncludesVAT
	|INTO DataFromLastCorrectiveAdjustment
	|FROM
	|	Document.PurchaseAdjustment AS PurchaseAdjustment
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
	|	ON
	|		PurchaseAdjustment.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
	|		AND RegisterOfDocumentsStornoCorrection.Posted
	|		AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
	|WHERE
	|	PurchaseAdjustment.Posted
	|	AND PurchaseAdjustment.Ref <> &DocumentRef
	|	AND PurchaseAdjustment.DocumentBasis = &DocumentBasis
	|	AND PurchaseAdjustment.PointInTime < &CurPointInTime
	|	AND PurchaseAdjustment.AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection)
	|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
	|
	|ORDER BY
	|	PurchaseAdjustment.PointInTime DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchaseAdjustment.Ref AS Ref,
	|	PurchaseAdjustment.PointInTime AS PointInTime,
	|	PurchaseAdjustment.AdjustingEntryType AS AdjustingEntryType,
	|	PurchaseAdjustment.PriceIncludesVAT AS PriceIncludesVAT
	|INTO PreviousAdjustmentData
	|FROM
	|	Document.PurchaseAdjustment AS PurchaseAdjustment
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
	|		ON PurchaseAdjustment.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
	|			AND RegisterOfDocumentsStornoCorrection.Posted
	|			AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
	|		LEFT JOIN DataFromLastCorrectiveAdjustment AS DataFromLastCorrectiveAdjustment
	|		ON (TRUE)
	|WHERE
	|	PurchaseAdjustment.Posted
	|	AND PurchaseAdjustment.Ref <> &DocumentRef
	|	AND PurchaseAdjustment.DocumentBasis = &DocumentBasis
	|	AND PurchaseAdjustment.PointInTime < &CurPointInTime
	|	AND (DataFromLastCorrectiveAdjustment.PointInTime IS NULL
	|			OR PurchaseAdjustment.PointInTime > DataFromLastCorrectiveAdjustment.PointInTime)
	|	AND PurchaseAdjustment.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
	|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	PurchaseAdjustment.PointInTime AS PointInTime,
	|	PurchaseAdjustment.PriceIncludesVAT AS PriceIncludesVAT,
	|	PurchaseAdjustment.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.LineNumber		 	 AS LineNumber,
	|	GoodsTable.PartnerProducts	 AS PartnerProducts,
	|	GoodsTable.Products		 	 AS Products,
	|	GoodsTable.Purpose			 AS Purpose,
	|	GoodsTable.Characteristic	 	 AS Characteristic,
	|	GoodsTable.Series				 	 AS Series,
	|	GoodsTable.BatchesIndicationStatus	 AS BatchesIndicationStatus,
	|	GoodsTable.Content		 	 AS Content,
	|	GoodsTable.Package			 	 AS Package,
	|	GoodsTable.NumberOfPackages 	 AS NumberOfPackages,
	|	GoodsTable.Count		 	 AS Count,
	|	GoodsTable.QuantityByGBRN	 	 AS QuantityByGBRN,
	|	GoodsTable.Price				 	 AS Price,
	|	GoodsTable.Sum				 	 AS Sum,
	|	GoodsTable.VATRate			 	 AS VATRate,
	|	GoodsTable.VATAmount			 	 AS VATAmount,
	|	GoodsTable.AmountIncludingVAT			 	 AS AmountIncludingVAT,
	|	GoodsTable.PurchaseOrder	 	 AS PurchaseOrder,
	|	GoodsTable.RowCode			 	 AS RowCode,
	|	GoodsTable.Warehouse				 	 AS Warehouse,
	|	GoodsTable.CCDNumber			 	 AS CCDNumber,
	|	GoodsTable.FEACNCode			 	 AS FEACNCode,
	|	GoodsTable.SalesOpportunity			 	 AS SalesOpportunity,
	|	GoodsTable.Department			 AS Department,
	|	GoodsTable.CostGroupNumber      AS CostGroupNumber,
	|	GoodsTable.ProductCostElement      AS ProductCostElement,
	|	GoodsTable.ProductionStage       AS ProductionStage,
	|	GoodsTable.ToExpenseAs		 AS ToExpenseAs,
	|	GoodsTable.ExpenseItem		 AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses		 AS DimensionOfExpenses,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.GLAccountSettings	 AS GLAccountSettings,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	ISNULL(ProductData_1.KeepRecordsByCCD, FALSE) AS KeepRecordsByCCD
	|	
	|INTO TTGoodsOfPreviousAdjustment
	|FROM
	|	Document.PurchaseAdjustment.Goods AS GoodsTable
	|	
	|	INNER JOIN PreviousAdjustmentData AS PurchaseAdjustment
	|	ON GoodsTable.Ref = PurchaseAdjustment.Ref
	|	
	|	LEFT JOIN Catalog.Products AS ProductData_1
	|	ON GoodsTable.Products = ProductData_1.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	PurchaseAdjustment.PointInTime AS PointInTime,
	|	PurchaseAdjustment.PriceIncludesVAT AS PriceIncludesVAT,
	|	PurchaseAdjustment.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.LineNumber		 	 AS LineNumber,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
	|	GoodsTable.Products		 	 AS Products,
	|	GoodsTable.Purpose			 AS Purpose,
	|	GoodsTable.Characteristic	 	 AS Characteristic,
	|	GoodsTable.Series				 	 AS Series,
	|	GoodsTable.BatchesIndicationStatus	 AS BatchesIndicationStatus,
	|	GoodsTable.Content		 	 AS Content,
	|	GoodsTable.Package			 	 AS Package,
	|	0									 AS NumberOfPackages,
	|	0									 AS Count,
	|	0									 AS QuantityByGBRN,
	|	0									 AS Price,
	|	0									 AS Sum,
	|	GoodsTable.VATRate				 AS VATRate,
	|	0									 AS VATAmount,
	|	0									 AS AmountIncludingVAT,
	|	GoodsTable.PurchaseOrder	 	 AS PurchaseOrder,
	|	GoodsTable.RowCode			 	 AS RowCode,
	|	GoodsTable.Warehouse				 	 AS Warehouse,
	|	GoodsTable.CCDNumber			 	 AS CCDNumber,
	|	GoodsTable.FEACNCode			 	 AS FEACNCode,
	|	GoodsTable.SalesOpportunity			 	 AS SalesOpportunity,
	|	GoodsTable.Department			 AS Department,
	|	GoodsTable.CostGroupNumber      AS CostGroupNumber,
	|	GoodsTable.ProductCostElement      AS ProductCostElement,
	|	GoodsTable.ProductionStage       AS ProductionStage,
	|	GoodsTable.ToExpenseAs		 AS ToExpenseAs,
	|	GoodsTable.ExpenseItem		 AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses		 AS DimensionOfExpenses,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.GLAccountSettings	 AS GLAccountSettings,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	ISNULL(ProductData_1.KeepRecordsByCCD, FALSE) AS KeepRecordsByCCD
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS GoodsTable
	|		INNER JOIN PreviousAdjustmentData AS PurchaseAdjustment
	|		ON GoodsTable.Ref = PurchaseAdjustment.Ref
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON GoodsTable.Products = ProductData_1.Ref
	|WHERE
	|	NOT (GoodsTable.Products, GoodsTable.Characteristic, GoodsTable.Content, GoodsTable.Series, GoodsTable.Package, GoodsTable.Warehouse, GoodsTable.CCDNumber, GoodsTable.FEACNCode, GoodsTable.Department, GoodsTable.ExpenseItem, GoodsTable.DimensionOfExpenses) IN
	|				(SELECT
	|					GoodsOfPreviousAdjustment.Products,
	|					GoodsOfPreviousAdjustment.Characteristic,
	|					GoodsOfPreviousAdjustment.Content,
	|					GoodsOfPreviousAdjustment.Series,
	|					GoodsOfPreviousAdjustment.Package,
	|					GoodsOfPreviousAdjustment.Warehouse,
	|					GoodsOfPreviousAdjustment.CCDNumber,
	|					GoodsOfPreviousAdjustment.FEACNCode,
	|					GoodsOfPreviousAdjustment.Department,
	|					GoodsOfPreviousAdjustment.ExpenseItem,
	|					GoodsOfPreviousAdjustment.DimensionOfExpenses
	|				FROM
	|					Document.PurchaseAdjustment.Goods AS GoodsOfPreviousAdjustment
	|				WHERE
	|					GoodsOfPreviousAdjustment.Ref = GoodsTable.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	PurchaseAdjustment.PointInTime AS PointInTime,
	|	PurchaseAdjustment.PriceIncludesVAT AS PriceIncludesVAT,
	|	PurchaseAdjustment.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.LineNumber		 	 AS LineNumber,
	|	GoodsTable.PartnerProducts	 AS PartnerProducts,
	|	GoodsTable.Products		 	 AS Products,
	|	GoodsTable.Purpose			 AS Purpose,
	|	GoodsTable.Characteristic	 	 AS Characteristic,
	|	GoodsTable.Series				 	 AS Series,
	|	GoodsTable.BatchesIndicationStatus	 AS BatchesIndicationStatus,
	|	GoodsTable.Content		 	 AS Content,
	|	GoodsTable.Package			 	 AS Package,
	|	GoodsTable.NumberOfPackages 	 AS NumberOfPackages,
	|	GoodsTable.Count		 	 AS Count,
	|	GoodsTable.QuantityByGBRN	 	 AS QuantityByGBRN,
	|	GoodsTable.Price				 	 AS Price,
	|	GoodsTable.Sum				 	 AS Sum,
	|	GoodsTable.VATRate			 	 AS VATRate,
	|	GoodsTable.VATAmount			 	 AS VATAmount,
	|	GoodsTable.AmountIncludingVAT			 	 AS AmountIncludingVAT,
	|	GoodsTable.PurchaseOrder	 	 AS PurchaseOrder,
	|	GoodsTable.RowCode			 	 AS RowCode,
	|	GoodsTable.Warehouse				 	 AS Warehouse,
	|	GoodsTable.CCDNumber			 	 AS CCDNumber,
	|	GoodsTable.FEACNCode			 	 AS FEACNCode,
	|	GoodsTable.SalesOpportunity			 	 AS SalesOpportunity,
	|	GoodsTable.Department			 AS Department,
	|	GoodsTable.CostGroupNumber      AS CostGroupNumber,
	|	GoodsTable.ProductCostElement      AS ProductCostElement,
	|	GoodsTable.ProductionStage       AS ProductionStage,
	|	GoodsTable.ToExpenseAs		 AS ToExpenseAs,
	|	GoodsTable.ExpenseItem		 AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses		 AS DimensionOfExpenses,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.GLAccountSettings	 AS GLAccountSettings,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	ISNULL(ProductData_1.KeepRecordsByCCD, FALSE) AS KeepRecordsByCCD
	|	
	|INTO TTGoodsOfLastCorrectiveAdjustment
	|FROM
	|	Document.PurchaseAdjustment.Goods AS GoodsTable
	|		INNER JOIN DataFromLastCorrectiveAdjustment AS PurchaseAdjustment
	|		ON GoodsTable.Ref = PurchaseAdjustment.Ref
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON GoodsTable.Products = ProductData_1.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	PurchaseAdjustment.PointInTime AS PointInTime,
	|	PurchaseAdjustment.PriceIncludesVAT AS PriceIncludesVAT,
	|	PurchaseAdjustment.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.LineNumber		 	 AS LineNumber,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
	|	GoodsTable.Products		 	 AS Products,
	|	GoodsTable.Purpose			 AS Purpose,
	|	GoodsTable.Characteristic	 	 AS Characteristic,
	|	GoodsTable.Series				 	 AS Series,
	|	GoodsTable.BatchesIndicationStatus	 AS BatchesIndicationStatus,
	|	GoodsTable.Content		 	 AS Content,
	|	GoodsTable.Package			 	 AS Package,
	|	0									 AS NumberOfPackages,
	|	0									 AS Count,
	|	0									 AS QuantityByGBRN,
	|	0									 AS Price,
	|	0									 AS Sum,
	|	GoodsTable.VATRate				 AS VATRate,
	|	0									 AS VATAmount,
	|	0									 AS AmountIncludingVAT,
	|	GoodsTable.PurchaseOrder	 	 AS PurchaseOrder,
	|	GoodsTable.RowCode			 	 AS RowCode,
	|	GoodsTable.Warehouse				 	 AS Warehouse,
	|	GoodsTable.CCDNumber			 	 AS CCDNumber,
	|	GoodsTable.FEACNCode			 	 AS FEACNCode,
	|	GoodsTable.SalesOpportunity			 	 AS SalesOpportunity,
	|	GoodsTable.Department			 AS Department,
	|	GoodsTable.CostGroupNumber      AS CostGroupNumber,
	|	GoodsTable.ProductCostElement      AS ProductCostElement,
	|	GoodsTable.ProductionStage       AS ProductionStage,
	|	GoodsTable.ToExpenseAs		 AS ToExpenseAs,
	|	GoodsTable.ExpenseItem		 AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses		 AS DimensionOfExpenses,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.GLAccountSettings	 AS GLAccountSettings,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	ISNULL(ProductData_1.KeepRecordsByCCD, FALSE) AS KeepRecordsByCCD
	|FROM
	|	Document.PurchaseAdjustment.Discrepancies AS GoodsTable
	|		INNER JOIN DataFromLastCorrectiveAdjustment AS PurchaseAdjustment
	|		ON GoodsTable.Ref = PurchaseAdjustment.Ref
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON GoodsTable.Products = ProductData_1.Ref
	|WHERE
	|	NOT (GoodsTable.Products, GoodsTable.Characteristic, GoodsTable.Content, GoodsTable.Series, GoodsTable.Package, GoodsTable.Warehouse, GoodsTable.CCDNumber, GoodsTable.FEACNCode, GoodsTable.Department, GoodsTable.ExpenseItem, GoodsTable.DimensionOfExpenses) IN
	|				(SELECT
	|					GoodsOfPreviousAdjustment.Products,
	|					GoodsOfPreviousAdjustment.Characteristic,
	|					GoodsOfPreviousAdjustment.Content,
	|					GoodsOfPreviousAdjustment.Series,
	|					GoodsOfPreviousAdjustment.Package,
	|					GoodsOfPreviousAdjustment.Warehouse,
	|					GoodsOfPreviousAdjustment.CCDNumber,
	|					GoodsOfPreviousAdjustment.FEACNCode,
	|					GoodsOfPreviousAdjustment.Department,
	|					GoodsOfPreviousAdjustment.ExpenseItem,
	|					GoodsOfPreviousAdjustment.DimensionOfExpenses
	|				FROM
	|					Document.PurchaseAdjustment.Goods AS GoodsOfPreviousAdjustment
	|				WHERE
	|					GoodsOfPreviousAdjustment.Ref = GoodsTable.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.PointInTime AS PointInTime,
	|	GoodsTable.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.LineNumber		 	 AS LineNumber,
	|	GoodsTable.PartnerProducts	 AS PartnerProducts,
	|	GoodsTable.Products		 	 AS Products,
	|	GoodsTable.Purpose			 AS Purpose,
	|	GoodsTable.Characteristic	 	 AS Characteristic,
	|	GoodsTable.Series				 	 AS Series,
	|	GoodsTable.BatchesIndicationStatus	 AS BatchesIndicationStatus,
	|	GoodsTable.Content		 	 AS Content,
	|	GoodsTable.Package			 	 AS Package,
	|	GoodsTable.NumberOfPackages 	 AS NumberOfPackages,
	|	GoodsTable.Count		 	 AS Count,
	|	GoodsTable.QuantityByGBRN	 	 AS QuantityByGBRN,
	|	GoodsTable.Price				 	 AS Price,
	|	GoodsTable.Sum				 	 AS Sum,
	|	GoodsTable.VATRate			 	 AS VATRate,
	|	GoodsTable.VATAmount			 	 AS VATAmount,
	|	GoodsTable.AmountIncludingVAT			 	 AS AmountIncludingVAT,
	|	GoodsTable.PurchaseOrder	 	 AS PurchaseOrder,
	|	GoodsTable.RowCode			 	 AS RowCode,
	|	GoodsTable.Warehouse				 	 AS Warehouse,
	|	GoodsTable.CCDNumber			 	 AS CCDNumber,
	|	GoodsTable.FEACNCode			 	 AS FEACNCode,
	|	GoodsTable.SalesOpportunity			 	 AS SalesOpportunity,
	|	GoodsTable.Department			 AS Department,
	|	GoodsTable.CostGroupNumber      AS CostGroupNumber,
	|	GoodsTable.ProductCostElement      AS ProductCostElement,
	|	GoodsTable.ProductionStage       AS ProductionStage,
	|	GoodsTable.ToExpenseAs		 AS ToExpenseAs,
	|	GoodsTable.ExpenseItem		 AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses		 AS DimensionOfExpenses,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.GLAccountSettings	 AS GLAccountSettings,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue
	|INTO TTGoodsOfPreviousSGTD_1Adjustment
	|FROM
	|	TTGoodsOfPreviousAdjustment AS GoodsTable
	|WHERE
	|	(NOT GoodsTable.KeepRecordsByCCD
	|			OR GoodsTable.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.PointInTime AS PointInTime,
	|	GoodsTable.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.LineNumber		 	 AS LineNumber,
	|	GoodsTable.PartnerProducts	 AS PartnerProducts,
	|	GoodsTable.Products		 	 AS Products,
	|	GoodsTable.Purpose			 AS Purpose,
	|	GoodsTable.Characteristic	 	 AS Characteristic,
	|	GoodsTable.Series				 	 AS Series,
	|	GoodsTable.BatchesIndicationStatus	 AS BatchesIndicationStatus,
	|	GoodsTable.Content		 	 AS Content,
	|	GoodsTable.Package			 	 AS Package,
	|	GoodsTable.NumberOfPackages 	 AS NumberOfPackages,
	|	GoodsTable.Count		 	 AS Count,
	|	GoodsTable.QuantityByGBRN	 	 AS QuantityByGBRN,
	|	GoodsTable.Price				 	 AS Price,
	|	GoodsTable.Sum				 	 AS Sum,
	|	GoodsTable.VATRate			 	 AS VATRate,
	|	GoodsTable.VATAmount			 	 AS VATAmount,
	|	GoodsTable.AmountIncludingVAT			 	 AS AmountIncludingVAT,
	|	GoodsTable.PurchaseOrder	 	 AS PurchaseOrder,
	|	GoodsTable.RowCode			 	 AS RowCode,
	|	GoodsTable.Warehouse				 	 AS Warehouse,
	|	GoodsTable.CCDNumber			 	 AS CCDNumber,
	|	GoodsTable.FEACNCode			 	 AS FEACNCode,
	|	GoodsTable.SalesOpportunity			 	 AS SalesOpportunity,
	|	GoodsTable.Department			 AS Department,
	|	GoodsTable.CostGroupNumber      AS CostGroupNumber,
	|	GoodsTable.ProductCostElement      AS ProductCostElement,
	|	GoodsTable.ProductionStage       AS ProductionStage,
	|	GoodsTable.ToExpenseAs		 AS ToExpenseAs,
	|	GoodsTable.ExpenseItem		 AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses		 AS DimensionOfExpenses,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.GLAccountSettings	 AS GLAccountSettings,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue
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
	|				AND GoodsOfPreviousAdjustment.Characteristic = GoodsTable.Characteristic
	|				AND GoodsOfPreviousAdjustment.Content = GoodsTable.Content
	|				AND GoodsOfPreviousAdjustment.Series = GoodsTable.Series
	|				AND GoodsOfPreviousAdjustment.Package = GoodsTable.Package
	|				AND GoodsOfPreviousAdjustment.Warehouse = GoodsTable.Warehouse
	|				AND GoodsOfPreviousAdjustment.CCDNumber = GoodsTable.CCDNumber
	|				AND GoodsOfPreviousAdjustment.FEACNCode = GoodsTable.FEACNCode
	|				AND GoodsOfPreviousAdjustment.Department = GoodsTable.Department
	|				AND GoodsOfPreviousAdjustment.ExpenseItem = GoodsTable.ExpenseItem
	|				AND GoodsOfPreviousAdjustment.DimensionOfExpenses = GoodsTable.DimensionOfExpenses
	|			ORDER BY
	|				GoodsOfPreviousAdjustment.PointInTime DESC)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	PurchaseAdjustment.PointInTime AS PointInTime,
	|	PurchaseAdjustment.AdjustingEntryType		 AS AdjustingEntryType,
	|	GoodsTable.LineNumber						 AS LineNumber,
	|	PurchaseAdjustment.PartnerProducts	 AS PartnerProducts,
	|	ISNULL(GoodsTable.ItemsLocationAttributes.Products, VALUE(Catalog.Products.EmptyRef)) AS Products,
	|	PurchaseAdjustment.Purpose			 AS Purpose,
	|	ISNULL(GoodsTable.ItemsLocationAttributes.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS Characteristic,
	|	PurchaseAdjustment.Series				 	 AS Series,
	|	PurchaseAdjustment.BatchesIndicationStatus	 AS BatchesIndicationStatus,
	|	PurchaseAdjustment.Content		 	 AS Content,
	|	PurchaseAdjustment.Package			 	 AS Package,
	|	PurchaseAdjustment.NumberOfPackages 	 AS NumberOfPackages,
	|	GoodsTable.Count						 AS Count,
	|	GoodsTable.QuantityByGBRN					 AS QuantityByGBRN,
	|	CASE
	|		WHEN PurchaseAdjustment.PriceIncludesVAT
	|				AND GoodsTable.AmountIncludingVAT > 0
	|				AND GoodsTable.Count > 0
	|			THEN GoodsTable.AmountIncludingVAT / GoodsTable.Count
	|		WHEN NOT PurchaseAdjustment.PriceIncludesVAT
	|				AND GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount > 0
	|				AND GoodsTable.Count > 0
	|			THEN (GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) / GoodsTable.Count
	|		ELSE 0
	|	END AS Price,
	|	CASE
	|		WHEN PurchaseAdjustment.PriceIncludesVAT
	|			THEN GoodsTable.AmountIncludingVAT
	|		ELSE GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount
	|	END AS Sum,
	|	GoodsTable.VATRate							 AS VATRate,
	|	GoodsTable.VATAmount							 AS VATAmount,
	|	GoodsTable.AmountIncludingVAT							 AS AmountIncludingVAT,
	|	GoodsTable.PurchaseOrder					 AS PurchaseOrder,
	|	GoodsTable.RowCode							 AS RowCode,
	|	PurchaseAdjustment.Warehouse					 AS Warehouse,
	|	GoodsTable.CCDNumber							 AS CCDNumber,
	|	PurchaseAdjustment.FEACNCode				 AS FEACNCode,
	|	GoodsTable.SalesOpportunity							 AS SalesOpportunity,
	|	PurchaseAdjustment.Department			 AS Department,
	|	PurchaseAdjustment.CostGroupNumber      AS CostGroupNumber,
	|	PurchaseAdjustment.ProductCostElement      AS ProductCostElement,
	|	PurchaseAdjustment.ProductionStage       AS ProductionStage,
	|	GoodsTable.ToExpenseAs		 AS ToExpenseAs,
	|	GoodsTable.ExpenseItem		 AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses		 AS DimensionOfExpenses,
	|	PurchaseAdjustment.LineOfBusiness AS LineOfBusiness,
	|	PurchaseAdjustment.GLAccountSettings	 AS GLAccountSettings,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue
	|INTO TTGoodsOfPreviousSGTD_2Adjustment
	|FROM
	|	Document.PurchaseAdjustment.InventoryKinds AS GoodsTable
	|		INNER JOIN TTGoodsOfPreviousAdjustment AS PurchaseAdjustment
	|		ON (PurchaseAdjustment.Ref = GoodsTable.Ref)
	|			AND (PurchaseAdjustment.Products = VALUE(Catalog.Products.EmptyRef)
	|				OR PurchaseAdjustment.Products = GoodsTable.ItemsLocationAttributes.Products)
	|			AND (PurchaseAdjustment.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|				OR PurchaseAdjustment.Characteristic = GoodsTable.ItemsLocationAttributes.Characteristic)
	|			AND (PurchaseAdjustment.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|				OR PurchaseAdjustment.Series = GoodsTable.ItemsLocationAttributes.Series)
	|			AND (PurchaseAdjustment.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|				OR PurchaseAdjustment.Department = GoodsTable.ItemsLocationAttributes.Department)
	|			AND (PurchaseAdjustment.PurchaseOrder = GoodsTable.PurchaseOrder)
	|			AND (PurchaseAdjustment.SalesOpportunity = GoodsTable.SalesOpportunity)
	|WHERE
	|	PurchaseAdjustment.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|	AND PurchaseAdjustment.KeepRecordsByCCD
	|	AND PurchaseAdjustment.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|	AND PurchaseAdjustment.Count > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.PointInTime AS PointInTime,
	|	GoodsTable.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.LineNumber		 	 AS LineNumber,
	|	GoodsTable.PartnerProducts	 AS PartnerProducts,
	|	GoodsTable.Products		 	 AS Products,
	|	GoodsTable.Purpose			 AS Purpose,
	|	GoodsTable.Characteristic	 	 AS Characteristic,
	|	GoodsTable.Series				 	 AS Series,
	|	GoodsTable.BatchesIndicationStatus	 AS BatchesIndicationStatus,
	|	GoodsTable.Content		 	 AS Content,
	|	GoodsTable.Package			 	 AS Package,
	|	GoodsTable.NumberOfPackages 	 AS NumberOfPackages,
	|	GoodsTable.Count		 	 AS Count,
	|	GoodsTable.QuantityByGBRN	 	 AS QuantityByGBRN,
	|	GoodsTable.Price				 	 AS Price,
	|	GoodsTable.Sum				 	 AS Sum,
	|	GoodsTable.VATRate			 	 AS VATRate,
	|	GoodsTable.VATAmount			 	 AS VATAmount,
	|	GoodsTable.AmountIncludingVAT			 	 AS AmountIncludingVAT,
	|	GoodsTable.PurchaseOrder	 	 AS PurchaseOrder,
	|	GoodsTable.RowCode			 	 AS RowCode,
	|	GoodsTable.Warehouse				 	 AS Warehouse,
	|	GoodsTable.CCDNumber			 	 AS CCDNumber,
	|	GoodsTable.FEACNCode			 	 AS FEACNCode,
	|	GoodsTable.SalesOpportunity			 	 AS SalesOpportunity,
	|	GoodsTable.Department			 AS Department,
	|	GoodsTable.CostGroupNumber      AS CostGroupNumber,
	|	GoodsTable.ProductCostElement      AS ProductCostElement,
	|	GoodsTable.ProductionStage       AS ProductionStage,
	|	GoodsTable.ToExpenseAs		 AS ToExpenseAs,
	|	GoodsTable.ExpenseItem		 AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses		 AS DimensionOfExpenses,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.GLAccountSettings	 AS GLAccountSettings,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue
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
	|				AND GoodsOfPreviousAdjustment.Characteristic = GoodsTable.Characteristic
	|				AND GoodsOfPreviousAdjustment.Content = GoodsTable.Content
	|				AND GoodsOfPreviousAdjustment.Series = GoodsTable.Series
	|				AND GoodsOfPreviousAdjustment.Package = GoodsTable.Package
	|				AND GoodsOfPreviousAdjustment.Warehouse = GoodsTable.Warehouse
	|				AND GoodsOfPreviousAdjustment.CCDNumber = GoodsTable.CCDNumber
	|				AND GoodsOfPreviousAdjustment.FEACNCode = GoodsTable.FEACNCode
	|				AND GoodsOfPreviousAdjustment.Department = GoodsTable.Department
	|				AND GoodsOfPreviousAdjustment.ExpenseItem = GoodsTable.ExpenseItem
	|				AND GoodsOfPreviousAdjustment.DimensionOfExpenses = GoodsTable.DimensionOfExpenses
	|			ORDER BY
	|				GoodsOfPreviousAdjustment.PointInTime DESC)
	|	AND GoodsTable.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.LineNumber		 	 AS LineNumber,
	|	GoodsTable.PartnerProducts	 AS PartnerProducts,
	|	GoodsTable.Products		 	 AS Products,
	|	GoodsTable.Purpose			 AS Purpose,
	|	GoodsTable.Characteristic	 	 AS Characteristic,
	|	GoodsTable.Series				 	 AS Series,
	|	GoodsTable.BatchesIndicationStatus	 AS BatchesIndicationStatus,
	|	GoodsTable.Content		 	 AS Content,
	|	GoodsTable.Package			 	 AS Package,
	|	GoodsTable.NumberOfPackages 	 AS NumberOfPackages,
	|	GoodsTable.Count		 	 AS Count,
	|	GoodsTable.QuantityByGBRN	 	 AS QuantityByGBRN,
	|	GoodsTable.Price				 	 AS Price,
	|	GoodsTable.Sum				 	 AS Sum,
	|	GoodsTable.VATRate			 	 AS VATRate,
	|	GoodsTable.VATAmount			 	 AS VATAmount,
	|	GoodsTable.AmountIncludingVAT			 	 AS AmountIncludingVAT,
	|	GoodsTable.PurchaseOrder	 	 AS PurchaseOrder,
	|	GoodsTable.RowCode			 	 AS RowCode,
	|	GoodsTable.Warehouse				 	 AS Warehouse,
	|	GoodsTable.CCDNumber			 	 AS CCDNumber,
	|	GoodsTable.FEACNCode			 	 AS FEACNCode,
	|	GoodsTable.SalesOpportunity			 	 AS SalesOpportunity,
	|	GoodsTable.Department			 AS Department,
	|	GoodsTable.CostGroupNumber      AS CostGroupNumber,
	|	GoodsTable.ProductCostElement      AS ProductCostElement,
	|	GoodsTable.ProductionStage       AS ProductionStage,
	|	GoodsTable.ToExpenseAs		 AS ToExpenseAs,
	|	GoodsTable.ExpenseItem		 AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses		 AS DimensionOfExpenses,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.GLAccountSettings	 AS GLAccountSettings,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue
	|INTO TTGoodsOfPreviousAdjustmentTotal
	|FROM
	|	TTGoodsOfPreviousSGTD_3Adjustment AS GoodsTable
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.LineNumber		 	 AS LineNumber,
	|	GoodsTable.PartnerProducts	 AS PartnerProducts,
	|	GoodsTable.Products		 	 AS Products,
	|	GoodsTable.Purpose			 AS Purpose,
	|	GoodsTable.Characteristic	 	 AS Characteristic,
	|	GoodsTable.Series				 	 AS Series,
	|	GoodsTable.BatchesIndicationStatus	 AS BatchesIndicationStatus,
	|	GoodsTable.Content		 	 AS Content,
	|	GoodsTable.Package			 	 AS Package,
	|	GoodsTable.NumberOfPackages 	 AS NumberOfPackages,
	|	GoodsTable.Count		 	 AS Count,
	|	GoodsTable.QuantityByGBRN	 	 AS QuantityByGBRN,
	|	GoodsTable.Price				 	 AS Price,
	|	GoodsTable.Sum				 	 AS Sum,
	|	GoodsTable.VATRate			 	 AS VATRate,
	|	GoodsTable.VATAmount			 	 AS VATAmount,
	|	GoodsTable.AmountIncludingVAT			 	 AS AmountIncludingVAT,
	|	GoodsTable.PurchaseOrder	 	 AS PurchaseOrder,
	|	GoodsTable.RowCode			 	 AS RowCode,
	|	GoodsTable.Warehouse				 	 AS Warehouse,
	|	GoodsTable.CCDNumber			 	 AS CCDNumber,
	|	GoodsTable.FEACNCode			 	 AS FEACNCode,
	|	GoodsTable.SalesOpportunity			 	 AS SalesOpportunity,
	|	GoodsTable.Department			 AS Department,
	|	GoodsTable.CostGroupNumber      AS CostGroupNumber,
	|	GoodsTable.ProductCostElement      AS ProductCostElement,
	|	GoodsTable.ProductionStage       AS ProductionStage,
	|	GoodsTable.ToExpenseAs		 AS ToExpenseAs,
	|	GoodsTable.ExpenseItem		 AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses		 AS DimensionOfExpenses,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.GLAccountSettings	 AS GLAccountSettings,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue
	|FROM
	|	TTGoodsOfPreviousSGTD_4Adjustment AS GoodsTable
	|		INNER JOIN TTGoodsOfPreviousSGTD_3Adjustment AS GoodsOfPreviousAdjustment
	|		ON GoodsOfPreviousAdjustment.Products = GoodsTable.Products
	|			AND GoodsOfPreviousAdjustment.Characteristic = GoodsTable.Characteristic
	|			AND GoodsOfPreviousAdjustment.Content = GoodsTable.Content
	|			AND GoodsOfPreviousAdjustment.Series = GoodsTable.Series
	|			AND GoodsOfPreviousAdjustment.Package = GoodsTable.Package
	|			AND GoodsOfPreviousAdjustment.Warehouse = GoodsTable.Warehouse
	|			AND GoodsOfPreviousAdjustment.CCDNumber = GoodsTable.CCDNumber
	|			AND GoodsOfPreviousAdjustment.FEACNCode = GoodsTable.FEACNCode
	|			AND GoodsOfPreviousAdjustment.Department = GoodsTable.Department
	|			AND GoodsOfPreviousAdjustment.ExpenseItem = GoodsTable.ExpenseItem
	|			AND GoodsOfPreviousAdjustment.DimensionOfExpenses = GoodsTable.DimensionOfExpenses
	|			AND GoodsTable.PointInTime >= GoodsOfPreviousAdjustment.PointInTime
	|WHERE
	|	GoodsTable.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|	AND GoodsOfPreviousAdjustment.Count > 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.LineNumber		 	 AS LineNumber,
	|	GoodsTable.PartnerProducts	 AS PartnerProducts,
	|	GoodsTable.Products		 	 AS Products,
	|	GoodsTable.Purpose			 AS Purpose,
	|	GoodsTable.Characteristic	 	 AS Characteristic,
	|	GoodsTable.Series				 	 AS Series,
	|	GoodsTable.BatchesIndicationStatus	 AS BatchesIndicationStatus,
	|	GoodsTable.Content		 	 AS Content,
	|	GoodsTable.Package			 	 AS Package,
	|	GoodsTable.NumberOfPackages 	 AS NumberOfPackages,
	|	GoodsTable.Count		 	 AS Count,
	|	GoodsTable.QuantityByGBRN	 	 AS QuantityByGBRN,
	|	GoodsTable.Price				 	 AS Price,
	|	GoodsTable.Sum				 	 AS Sum,
	|	GoodsTable.VATRate			 	 AS VATRate,
	|	GoodsTable.VATAmount			 	 AS VATAmount,
	|	GoodsTable.AmountIncludingVAT			 	 AS AmountIncludingVAT,
	|	GoodsTable.PurchaseOrder	 	 AS PurchaseOrder,
	|	GoodsTable.RowCode			 	 AS RowCode,
	|	GoodsTable.Warehouse				 	 AS Warehouse,
	|	GoodsTable.CCDNumber			 	 AS CCDNumber,
	|	GoodsTable.FEACNCode			 	 AS FEACNCode,
	|	GoodsTable.SalesOpportunity			 	 AS SalesOpportunity,
	|	GoodsTable.Department			 AS Department,
	|	GoodsTable.CostGroupNumber      AS CostGroupNumber,
	|	GoodsTable.ProductCostElement      AS ProductCostElement,
	|	GoodsTable.ProductionStage       AS ProductionStage,
	|	GoodsTable.ToExpenseAs		 AS ToExpenseAs,
	|	GoodsTable.ExpenseItem		 AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses		 AS DimensionOfExpenses,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.GLAccountSettings	 AS GLAccountSettings,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue
	|FROM
	|	TTGoodsOfPreviousSGTD_4Adjustment AS GoodsTable
	|WHERE
	|	GoodsTable.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|	AND NOT (GoodsTable.Products, GoodsTable.Characteristic, GoodsTable.Content, GoodsTable.Series, GoodsTable.Package, GoodsTable.Warehouse, GoodsTable.CCDNumber, GoodsTable.FEACNCode, GoodsTable.Department, GoodsTable.ExpenseItem, GoodsTable.DimensionOfExpenses) IN
	|				(SELECT
	|					GoodsOfPreviousAdjustment.Products,
	|					GoodsOfPreviousAdjustment.Characteristic,
	|					GoodsOfPreviousAdjustment.Content,
	|					GoodsOfPreviousAdjustment.Series,
	|					GoodsOfPreviousAdjustment.Package,
	|					GoodsOfPreviousAdjustment.Warehouse,
	|					GoodsOfPreviousAdjustment.CCDNumber,
	|					GoodsOfPreviousAdjustment.FEACNCode,
	|					GoodsOfPreviousAdjustment.Department,
	|					GoodsOfPreviousAdjustment.ExpenseItem,
	|					GoodsOfPreviousAdjustment.DimensionOfExpenses
	|				FROM
	|					TTGoodsOfPreviousSGTD_3Adjustment AS GoodsOfPreviousAdjustment)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.PointInTime AS PointInTime,
	|	GoodsTable.AdjustingEntryType AS AdjustingEntryType,
	|	GoodsTable.LineNumber		 	 AS LineNumber,
	|	GoodsTable.PartnerProducts	 AS PartnerProducts,
	|	GoodsTable.Products		 	 AS Products,
	|	GoodsTable.Purpose			 AS Purpose,
	|	GoodsTable.Characteristic	 	 AS Characteristic,
	|	GoodsTable.Series				 	 AS Series,
	|	GoodsTable.BatchesIndicationStatus	 AS BatchesIndicationStatus,
	|	GoodsTable.Content		 	 AS Content,
	|	GoodsTable.Package			 	 AS Package,
	|	GoodsTable.NumberOfPackages 	 AS NumberOfPackages,
	|	GoodsTable.Count		 	 AS Count,
	|	GoodsTable.QuantityByGBRN	 	 AS QuantityByGBRN,
	|	GoodsTable.Price				 	 AS Price,
	|	GoodsTable.Sum				 	 AS Sum,
	|	GoodsTable.VATRate			 	 AS VATRate,
	|	GoodsTable.VATAmount			 	 AS VATAmount,
	|	GoodsTable.AmountIncludingVAT			 	 AS AmountIncludingVAT,
	|	GoodsTable.PurchaseOrder	 	 AS PurchaseOrder,
	|	GoodsTable.RowCode			 	 AS RowCode,
	|	GoodsTable.Warehouse				 	 AS Warehouse,
	|	GoodsTable.CCDNumber			 	 AS CCDNumber,
	|	GoodsTable.FEACNCode			 	 AS FEACNCode,
	|	GoodsTable.SalesOpportunity			 	 AS SalesOpportunity,
	|	GoodsTable.Department			 AS Department,
	|	GoodsTable.CostGroupNumber      AS CostGroupNumber,
	|	GoodsTable.ProductCostElement      AS ProductCostElement,
	|	GoodsTable.ProductionStage       AS ProductionStage,
	|	GoodsTable.ToExpenseAs		 AS ToExpenseAs,
	|	GoodsTable.ExpenseItem		 AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses		 AS DimensionOfExpenses,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.GLAccountSettings	 AS GLAccountSettings,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue
	|INTO TTGoodsOfCorrectiveAdjustmentOfSGTD
	|FROM
	|	TTGoodsOfLastCorrectiveAdjustment AS GoodsTable
	|WHERE
	|	(NOT GoodsTable.KeepRecordsByCCD
	|			OR GoodsTable.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef))
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	PurchaseAdjustment.PointInTime AS PointInTime,
	|	PurchaseAdjustment.AdjustingEntryType		 AS AdjustingEntryType,
	|	GoodsTable.LineNumber						 AS LineNumber,
	|	PurchaseAdjustment.PartnerProducts	 AS PartnerProducts,
	|	PurchaseAdjustment.Products			 AS Products,
	|	PurchaseAdjustment.Purpose			 AS Purpose,
	|	PurchaseAdjustment.Characteristic		 AS Characteristic,
	|	PurchaseAdjustment.Series				 	 AS Series,
	|	PurchaseAdjustment.BatchesIndicationStatus	 AS BatchesIndicationStatus,
	|	PurchaseAdjustment.Content		 	 AS Content,
	|	PurchaseAdjustment.Package			 	 AS Package,
	|	PurchaseAdjustment.NumberOfPackages 	 AS NumberOfPackages,
	|	GoodsTable.Count						 AS Count,
	|	GoodsTable.QuantityByGBRN					 AS QuantityByGBRN,
	|	CASE
	|		WHEN PurchaseAdjustment.PriceIncludesVAT
	|				AND GoodsTable.AmountIncludingVAT > 0
	|				AND GoodsTable.Count > 0
	|			THEN GoodsTable.AmountIncludingVAT / GoodsTable.Count
	|		WHEN NOT PurchaseAdjustment.PriceIncludesVAT
	|				AND GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount > 0
	|				AND GoodsTable.Count > 0
	|			THEN (GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) / GoodsTable.Count
	|		ELSE 0
	|	END AS Price,
	|	CASE
	|		WHEN PurchaseAdjustment.PriceIncludesVAT
	|			THEN GoodsTable.AmountIncludingVAT
	|		ELSE GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount
	|	END AS Sum,
	|	GoodsTable.VATRate							 AS VATRate,
	|	GoodsTable.VATAmount							 AS VATAmount,
	|	GoodsTable.AmountIncludingVAT							 AS AmountIncludingVAT,
	|	GoodsTable.PurchaseOrder					 AS PurchaseOrder,
	|	GoodsTable.RowCode							 AS RowCode,
	|	PurchaseAdjustment.Warehouse					 AS Warehouse,
	|	GoodsTable.CCDNumber							 AS CCDNumber,
	|	PurchaseAdjustment.FEACNCode				 AS FEACNCode,
	|	GoodsTable.SalesOpportunity							 AS SalesOpportunity,
	|	PurchaseAdjustment.Department			 AS Department,
	|	PurchaseAdjustment.CostGroupNumber      AS CostGroupNumber,
	|	PurchaseAdjustment.ProductCostElement      AS ProductCostElement,
	|	PurchaseAdjustment.ProductionStage       AS ProductionStage,
	|	GoodsTable.ToExpenseAs		 AS ToExpenseAs,
	|	GoodsTable.ExpenseItem		 AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses		 AS DimensionOfExpenses,
	|	PurchaseAdjustment.LineOfBusiness AS LineOfBusiness,
	|	PurchaseAdjustment.GLAccountSettings	 AS GLAccountSettings,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue
	|FROM
	|	Document.PurchaseAdjustment.InventoryKinds AS GoodsTable
	|		INNER JOIN TTGoodsOfLastCorrectiveAdjustment AS PurchaseAdjustment
	|		ON (PurchaseAdjustment.Ref = GoodsTable.Ref)
	|			AND (PurchaseAdjustment.Products = VALUE(Catalog.Products.EmptyRef)
	|				OR PurchaseAdjustment.Products = GoodsTable.ItemsLocationAttributes.Products)
	|			AND (PurchaseAdjustment.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|				OR PurchaseAdjustment.Characteristic = GoodsTable.ItemsLocationAttributes.Characteristic)
	|			AND (PurchaseAdjustment.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|				OR PurchaseAdjustment.Series = GoodsTable.ItemsLocationAttributes.Series)
	|			AND (PurchaseAdjustment.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|				OR PurchaseAdjustment.Department = GoodsTable.ItemsLocationAttributes.Department)
	|			AND (PurchaseAdjustment.PurchaseOrder = GoodsTable.PurchaseOrder)
	|			AND (PurchaseAdjustment.SalesOpportunity = GoodsTable.SalesOpportunity)
	|WHERE
	|	PurchaseAdjustment.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|	AND PurchaseAdjustment.KeepRecordsByCCD
	|	AND PurchaseAdjustment.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LineNumber		 	 AS LineNumber,
	|	GoodsTable.PartnerProducts	 AS PartnerProducts,
	|	GoodsTable.Products		 	 AS Products,
	|	GoodsTable.Purpose			 AS Purpose,
	|	GoodsTable.Characteristic	 	 AS Characteristic,
	|	GoodsTable.Series				 	 AS Series,
	|	GoodsTable.BatchesIndicationStatus	 AS BatchesIndicationStatus,
	|	GoodsTable.Content		 	 AS Content,
	|	GoodsTable.Package			 	 AS Package,
	|	GoodsTable.NumberOfPackages 	 AS NumberOfPackages,
	|	GoodsTable.Count		 	 AS Count,
	|	GoodsTable.QuantityByGBRN	 	 AS QuantityByGBRN,
	|	GoodsTable.Price				 	 AS Price,
	|	GoodsTable.Sum				 	 AS Sum,
	|	GoodsTable.VATRate			 	 AS VATRate,
	|	GoodsTable.VATAmount			 	 AS VATAmount,
	|	GoodsTable.AmountIncludingVAT			 	 AS AmountIncludingVAT,
	|	GoodsTable.PurchaseOrder	 	 AS PurchaseOrder,
	|	GoodsTable.RowCode			 	 AS RowCode,
	|	GoodsTable.Warehouse				 	 AS Warehouse,
	|	GoodsTable.CCDNumber			 	 AS CCDNumber,
	|	GoodsTable.FEACNCode			 	 AS FEACNCode,
	|	GoodsTable.SalesOpportunity			 	 AS SalesOpportunity,
	|	GoodsTable.Department			 AS Department,
	|	GoodsTable.CostGroupNumber      AS CostGroupNumber,
	|	GoodsTable.ProductCostElement      AS ProductCostElement,
	|	GoodsTable.ProductionStage       AS ProductionStage,
	|	GoodsTable.ToExpenseAs		 AS ToExpenseAs,
	|	GoodsTable.ExpenseItem		 AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses		 AS DimensionOfExpenses,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.GLAccountSettings	 AS GLAccountSettings,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue
	|INTO RawData
	|FROM
	|	TTGoodsOfCorrectiveAdjustmentOfSGTD AS GoodsTable
	|WHERE
	|	CASE
	|			WHEN GoodsTable.AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets)
	|				THEN NOT (GoodsTable.Content, GoodsTable.Department, GoodsTable.ExpenseItem, GoodsTable.DimensionOfExpenses) IN
	|								(SELECT
	|									GoodsOfPreviousAdjustment.Content,
	|									GoodsOfPreviousAdjustment.Department,
	|									GoodsOfPreviousAdjustment.ExpenseItem,
	|									GoodsOfPreviousAdjustment.DimensionOfExpenses
	|								FROM
	|									TTGoodsOfPreviousAdjustmentTotal AS GoodsOfPreviousAdjustment)
	|						AND GoodsTable.Sum > 0
	|			ELSE NOT (GoodsTable.Products, GoodsTable.Characteristic, GoodsTable.Content, GoodsTable.Series, GoodsTable.Package, GoodsTable.Warehouse, GoodsTable.CCDNumber, GoodsTable.FEACNCode, GoodsTable.Department, GoodsTable.ExpenseItem, GoodsTable.DimensionOfExpenses) IN
	|							(SELECT
	|								GoodsOfPreviousAdjustment.Products,
	|								GoodsOfPreviousAdjustment.Characteristic,
	|								GoodsOfPreviousAdjustment.Content,
	|								GoodsOfPreviousAdjustment.Series,
	|								GoodsOfPreviousAdjustment.Package,
	|								GoodsOfPreviousAdjustment.Warehouse,
	|								GoodsOfPreviousAdjustment.CCDNumber,
	|								GoodsOfPreviousAdjustment.FEACNCode,
	|								GoodsOfPreviousAdjustment.Department,
	|								GoodsOfPreviousAdjustment.ExpenseItem,
	|								GoodsOfPreviousAdjustment.DimensionOfExpenses
	|							FROM
	|								TTGoodsOfPreviousAdjustmentTotal AS GoodsOfPreviousAdjustment)
	|					AND GoodsTable.Count > 0
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber		 	 AS LineNumber,
	|	GoodsTable.PartnerProducts	 AS PartnerProducts,
	|	GoodsTable.Products		 	 AS Products,
	|	GoodsTable.Purpose			 AS Purpose,
	|	GoodsTable.Characteristic	 	 AS Characteristic,
	|	GoodsTable.Series				 	 AS Series,
	|	GoodsTable.BatchesIndicationStatus	 AS BatchesIndicationStatus,
	|	GoodsTable.Content		 	 AS Content,
	|	GoodsTable.Package			 	 AS Package,
	|	GoodsTable.NumberOfPackages 	 AS NumberOfPackages,
	|	GoodsTable.Count		 	 AS Count,
	|	GoodsTable.QuantityByGBRN	 	 AS QuantityByGBRN,
	|	GoodsTable.Price				 	 AS Price,
	|	GoodsTable.Sum				 	 AS Sum,
	|	GoodsTable.VATRate			 	 AS VATRate,
	|	GoodsTable.VATAmount			 	 AS VATAmount,
	|	GoodsTable.AmountIncludingVAT			 	 AS AmountIncludingVAT,
	|	GoodsTable.PurchaseOrder	 	 AS PurchaseOrder,
	|	GoodsTable.RowCode			 	 AS RowCode,
	|	GoodsTable.Warehouse				 	 AS Warehouse,
	|	GoodsTable.CCDNumber			 	 AS CCDNumber,
	|	GoodsTable.FEACNCode			 	 AS FEACNCode,
	|	GoodsTable.SalesOpportunity			 	 AS SalesOpportunity,
	|	GoodsTable.Department			 AS Department,
	|	GoodsTable.CostGroupNumber      AS CostGroupNumber,
	|	GoodsTable.ProductCostElement      AS ProductCostElement,
	|	GoodsTable.ProductionStage       AS ProductionStage,
	|	GoodsTable.ToExpenseAs		 AS ToExpenseAs,
	|	GoodsTable.ExpenseItem		 AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses		 AS DimensionOfExpenses,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.GLAccountSettings	 AS GLAccountSettings,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue
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

// Returns a table of settlement amounts broken down by container/non-container and broken down by order.
// 
// Parameters:
//  ObjectReference_ - DocumentRef.PurchaseAdjustment - The document for which you want to get the data.
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
	|	Goods.PurchaseOrder        AS OrderDocument,
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
	|";
	
	If AttributesValues = Undefined Then
		AdjustmentKind = Common.ObjectAttributeValue(ObjectReference_, "AdjustmentKind");
		Query.SetParameter("Ref", ObjectReference_);
		
		If AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated
			Or AdjustmentKind = Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated Then
				
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
			|	Document.PurchaseAdjustment.ARAPAdjustment AS ARAPAdjustment
			|WHERE
			|	ARAPAdjustment.Ref = &Ref";
			
		Else
			
			Query.Text = StrReplace(Query.Text, "&ValueTable", "Document.PurchaseAdjustment.Discrepancies");
			Query.Text = StrReplace(Query.Text, "&ToReturnReusablePackage", "CASE
			|WHEN Goods.Ref.DocumentBasis REFS Document.SourceDocument
			|	THEN FALSE
			|ELSE
			|	ISNULL(Goods.Ref.DocumentBasis.ToReturnReusablePackage,FALSE)");
			Query.Text = StrReplace(Query.Text, "&PackageDepositIsRequired", "CASE
			|WHEN Goods.Ref.DocumentBasis REFS Document.SourceDocument
			|	THEN FALSE
			|ELSE
			|	ISNULL(Goods.Ref.DocumentBasis.PackageDepositIsRequired,FALSE)");
			Query.Text = StrReplace(Query.Text, "&LinkCondition_", "Goods.Ref = &Ref");
		EndIf;
	Else
		
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

#Region CheckingCompletionOfDocumentBeforeEnteringBalance

Function QueryTextTTTablesOfGoods()
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber				AS LineNumber,
	|	TableOfGoods.Content				AS Content,
	|	CAST(TableOfGoods.Products AS Catalog.Products) AS Products,
	|	CAST(TableOfGoods.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	CAST(TableOfGoods.CCDNumber AS Catalog.CCDNumbers) AS CCDNumber,
	|	CAST(TableOfGoods.FEACNCode AS Catalog.FEACN) AS FEACNCode,
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
	|	TableOfGoods.ToExpenseAs			AS ToExpenseAs,
	|	TableOfGoods.Warehouse					AS Warehouse,
	|	TableOfGoods.Department			AS Department,
	|	TableOfGoods.ExpenseItem			AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses		AS DimensionOfExpenses,
	|	TableOfGoods.Series					AS Series,
	|	TableOfGoods.Package					AS Package
	|INTO TableOfProductsToRequest
	|FROM
	|	&TableOfGoods AS TableOfGoods";
	
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
		|	PurchaseAdjustment.Ref AS Ref,
		|	PurchaseAdjustment.AdjustingEntryType AS AdjustingEntryType,
		|	PurchaseAdjustment.DocumentBasis AS DocumentBasis,
		|	PurchaseAdjustment.Date AS Date
		|INTO TTPreviousAdjustment
		|FROM
		|	Document.PurchaseAdjustment AS PurchaseAdjustment
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
		|		ON PurchaseAdjustment.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
		|			AND (RegisterOfDocumentsStornoCorrection.Posted)
		|			AND (NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord)
		|WHERE
		|	PurchaseAdjustment.Posted
		|	AND PurchaseAdjustment.Date < &Date
		|	AND PurchaseAdjustment.DocumentBasis = &DocumentBasis
		|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
		|
		|ORDER BY
		|	PurchaseAdjustment.PointInTime DESC
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
	|	AdjustmentTable.ExpenseItem AS ExpenseItem,
	|	AdjustmentTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	AdjustmentTable.Series AS Series,
	|	AdjustmentTable.Warehouse AS Warehouse,
	|	AdjustmentTable.FEACNCode AS FEACNCode,
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
	|	AdjustmentTable.ExpenseItem,
	|	AdjustmentTable.DimensionOfExpenses,
	|	AdjustmentTable.Series,
	|	AdjustmentTable.Warehouse,
	|	AdjustmentTable.FEACNCode,
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
	|	LastAdjustmentData.Series AS Series,
	|	LastAdjustmentData.Warehouse AS Warehouse,
	|	LastAdjustmentData.Department AS Department,
	|	LastAdjustmentData.ExpenseItem AS ExpenseItem,
	|	LastAdjustmentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	LastAdjustmentData.FEACNCode AS FEACNCode,
	|	MAX(LastAdjustmentData.VATRate) AS VATRate,
	|	SUM(LastAdjustmentData.Count) AS Count,
	|	SUM(LastAdjustmentData.NumberOfPackages) AS NumberOfPackages,
	|	SUM(LastAdjustmentData.Sum) AS Sum,
	|	SUM(LastAdjustmentData.VATAmount) AS VATAmount,
	|	SUM(LastAdjustmentData.AmountIncludingVAT) AS AmountIncludingVAT
	|INTO InitialDataWithoutCCD
	|FROM
	|	(SELECT
	|		LastAdjustmentData.Products AS Products,
	|		LastAdjustmentData.Characteristic AS Characteristic,
	|		LastAdjustmentData.Content AS Content,
	|		LastAdjustmentData.Package AS Package,
	|		LastAdjustmentData.Series AS Series,
	|		LastAdjustmentData.Warehouse AS Warehouse,
	|		LastAdjustmentData.Department AS Department,
	|		LastAdjustmentData.ExpenseItem AS ExpenseItem,
	|		LastAdjustmentData.DimensionOfExpenses AS DimensionOfExpenses,
	|		LastAdjustmentData.FEACNCode AS FEACNCode,
	|		LastAdjustmentData.VATRate AS VATRate,
	|		LastAdjustmentData.NumberOfPackages AS NumberOfPackages,
	|		LastAdjustmentData.Count AS Count,
	|		LastAdjustmentData.Sum AS Sum,
	|		LastAdjustmentData.VATAmount AS VATAmount,
	|		LastAdjustmentData.AmountIncludingVAT AS AmountIncludingVAT
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
	|		LastAdjustmentData.Series,
	|		LastAdjustmentData.Warehouse,
	|		LastAdjustmentData.Department,
	|		LastAdjustmentData.ExpenseItem,
	|		LastAdjustmentData.DimensionOfExpenses,
	|		LastAdjustmentData.FEACNCode,
	|		LastAdjustmentData.VATRate,
	|		-LastAdjustmentData.NumberOfPackages,
	|		-LastAdjustmentData.Count,
	|		-LastAdjustmentData.Sum,
	|		-LastAdjustmentData.VATAmount,
	|		-LastAdjustmentData.AmountIncludingVAT
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
	|		LastAdjustmentData.Series,
	|		LastAdjustmentData.Warehouse,
	|		LastAdjustmentData.Department,
	|		LastAdjustmentData.ExpenseItem,
	|		LastAdjustmentData.DimensionOfExpenses,
	|		LastAdjustmentData.FEACNCode,
	|		LastAdjustmentData.VATRateAfter,
	|		LastAdjustmentData.NumberOfPackagesAfter,
	|		LastAdjustmentData.QuantityAfter,
	|		LastAdjustmentData.AmountAfter,
	|		LastAdjustmentData.VATAmountAfter,
	|		LastAdjustmentData.AmountWithVATAfter
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
	|	LastAdjustmentData.Series,
	|	LastAdjustmentData.Warehouse,
	|	LastAdjustmentData.Department,
	|	LastAdjustmentData.ExpenseItem,
	|	LastAdjustmentData.DimensionOfExpenses,
	|	LastAdjustmentData.FEACNCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LastAdjustmentData.Products AS Products,
	|	LastAdjustmentData.Characteristic AS Characteristic,
	|	LastAdjustmentData.Content AS Content,
	|	LastAdjustmentData.Package AS Package,
	|	LastAdjustmentData.Series AS Series,
	|	LastAdjustmentData.Warehouse AS Warehouse,
	|	LastAdjustmentData.Department AS Department,
	|	LastAdjustmentData.ExpenseItem AS ExpenseItem,
	|	LastAdjustmentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	LastAdjustmentData.CCDNumber AS CCDNumber,
	|	LastAdjustmentData.FEACNCode AS FEACNCode,
	|	LastAdjustmentData.VATRate AS VATRate,
	|	SUM(LastAdjustmentData.NumberOfPackages) AS NumberOfPackages,
	|	SUM(LastAdjustmentData.Count) AS Count,
	|	SUM(LastAdjustmentData.QuantityByGBRN) AS QuantityByGBRN,
	|	SUM(LastAdjustmentData.Sum) AS Sum,
	|	SUM(LastAdjustmentData.VATAmount) AS VATAmount,
	|	SUM(LastAdjustmentData.AmountIncludingVAT) AS AmountIncludingVAT
	|INTO InitialDataOnCCD
	|FROM
	|	RawData AS LastAdjustmentData
	|WHERE
	|	&ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES
	|	AND LastAdjustmentData.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|
	|GROUP BY
	|	LastAdjustmentData.Products,
	|	LastAdjustmentData.Characteristic,
	|	LastAdjustmentData.Content,
	|	LastAdjustmentData.Package,
	|	LastAdjustmentData.Series,
	|	LastAdjustmentData.Warehouse,
	|	LastAdjustmentData.Department,
	|	LastAdjustmentData.ExpenseItem,
	|	LastAdjustmentData.DimensionOfExpenses,
	|	LastAdjustmentData.CCDNumber,
	|	LastAdjustmentData.FEACNCode,
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
	|							AND LastAdjustmentData.Series = TTDiscrepancies.Series
	|							AND LastAdjustmentData.Package = TTDiscrepancies.Package
	|							AND LastAdjustmentData.Warehouse = TTDiscrepancies.Warehouse
	|							AND LastAdjustmentData.FEACNCode = TTDiscrepancies.FEACNCode
	|							AND LastAdjustmentData.ExpenseItem = TTDiscrepancies.ExpenseItem
	|							AND LastAdjustmentData.DimensionOfExpenses = TTDiscrepancies.DimensionOfExpenses
	|							AND LastAdjustmentData.Department = TTDiscrepancies.Department
	|				ELSE LastAdjustmentData.Content = TTDiscrepancies.Content
	|						AND LastAdjustmentData.Department = TTDiscrepancies.Department
	|						AND LastAdjustmentData.ExpenseItem = TTDiscrepancies.ExpenseItem
	|						AND LastAdjustmentData.DimensionOfExpenses = TTDiscrepancies.DimensionOfExpenses
	|						AND LastAdjustmentData.FEACNCode = TTDiscrepancies.FEACNCode
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
	|		ON LastAdjustmentData.Products = TTDiscrepancies.Products
	|			AND LastAdjustmentData.Characteristic = TTDiscrepancies.Characteristic
	|			AND LastAdjustmentData.Series = TTDiscrepancies.Series
	|			AND LastAdjustmentData.Package = TTDiscrepancies.Package
	|			AND LastAdjustmentData.Warehouse = TTDiscrepancies.Warehouse
	|			AND LastAdjustmentData.CCDNumber = TTDiscrepancies.CCDNumber
	|			AND LastAdjustmentData.FEACNCode = TTDiscrepancies.FEACNCode
	|			AND LastAdjustmentData.ExpenseItem = TTDiscrepancies.ExpenseItem
	|			AND LastAdjustmentData.DimensionOfExpenses = TTDiscrepancies.DimensionOfExpenses
	|			AND LastAdjustmentData.Department = TTDiscrepancies.Department
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
	|	AND NOT TableOfGoods.ToExpenseAs
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
	|		INNER JOIN Catalog.Products AS ProductData_1
	|		ON TableOfGoods.Products = ProductData_1.Ref
	|WHERE
	|	&UseItemVariants
	|	AND ProductData_1.UseVariants IN
	|			(VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|			VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|			VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|	AND TableOfGoods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)";
	
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
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber		AS LineNumber,
	|	""NotQuantityIsIndicatedAccordingToRNPT""	AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		LEFT JOIN Catalog.FEACN AS FEACN
	|		ON TableOfGoods.FEACNCode = FEACN.Ref
	|WHERE
	|	TableOfGoods.QuantityByGBRN = 0
	|	AND (TableOfGoods.Price > 0
	|		OR TableOfGoods.Count <> 0
	|		OR TableOfGoods.NumberOfPackages <> 0)
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND NOT &ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES
	|	AND ISNULL(FEACN.TracedGoods, FALSE)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber			AS LineNumber,
	|	""NotQuantityIndicatedByRNPTAfter""	AS TypeOfVerification
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		LEFT JOIN Catalog.FEACN AS FEACN
	|		ON TableOfGoods.FEACNCode = FEACN.Ref
	|WHERE
	|	TableOfGoods.QuantityAccordingToRNPTAfter = 0
	|	AND (TableOfGoods.PriceAfter > 0
	|		OR TableOfGoods.QuantityAfter <> 0
	|		OR TableOfGoods.NumberOfPackagesAfter <> 0)
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND NOT &ThisIsAdjustmentBeforeEnteringBalanceOFGoodsANDSERVICES
	|	AND ISNULL(FEACN.TracedGoods, FALSE)";
	
	Return QueryText;
	
EndFunction

Function QueryTextChecksForFillingInSummaryIndicators()
	
	QueryText =
	"SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	""PriceNotSpecified_""			AS TypeOfVerification
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
	|	""NotAmountSpecified""			AS TypeOfVerification
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
	|	TableOfGoods.VATAmount <> 0
	|	AND TableOfGoods.AmountIncludingVAT <> 0
	|	AND TableOfGoods.Count <> 0
	|	AND TableOfGoods.VATRate <> TableOfGoods.VATRateAfter
	|	AND TableOfGoods.VATRate <> VALUE(Catalog.VATRates.EmptyRef)
	|	AND TableOfGoods.VATRateAfter <> VALUE(Catalog.VATRates.EmptyRef)
	|	AND TableOfGoods.OptionToReflectWriteOff = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.EmptyRef)
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
	|	AND TableOfGoods.PostingOption = VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.EmptyRef)";
	
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
	|	AND NOT TableOfGoods.ToExpenseAs
	|	AND CAST(&Warehouse AS Catalog.Warehouses).IsFolder
	|	AND &Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|	AND TableOfGoods.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|	AND ISNULL(ProductData_1.ItemsType, UNDEFINED) IN
	|			(VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))";
	
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
	|WHERE PreviousAdjustment.AdjustingEntryType <> &AdjustingEntryType";
	
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

Procedure Report_FillingErrors(Selection, Cancel)
	
	TSName			= "AdjustmentTable";
	PresentationOfTS	= NStr("vi = 'Dữ liệu điều chỉnh';
								|ru = 'Данные корректировки';
								|en = 'Correction data'; fa = 'داده‌های اصلاح';
								|it = 'Dati di correzione';
								|pl = 'Dane korekty';
								|tr = 'Düzeltme verileri'");
	
	MessageTemplateFieldNotFilledIn						= NStr("vi = 'Chưa điền trường ""%1""';
																	|ru = 'Поле ""%1"" не заполнено';
																	|en = '""%1"" is required'; fa = '""%1"" is required';
																	|it = 'Il campo ""%1"" non è compilato';
																	|pl = 'Pole ""%1"" nie jest wypełnione';
																	|tr = '""%1"" alanı doldurulmamış'");
	MessageTemplateColumnNotFilledIn					= NStr("vi = 'Chưa điền cột ""%1"" tại dòng %2 trong danh sách ""%3""';
																|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""%3""';
																|en = 'Column ""%1"" in line #%2, list ""%3"" cannot be empty.'; fa = 'Column ""%1"" in line #%2, list ""%3"" cannot be empty.';
																|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""%3"" non è compilata';
																|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""%3""';
																|tr = 'Sütun ""%1"", ""%3"" listesinin %2satırında doldurulmamış'");
	MessageTemplateQuantityRecalculationError			= NStr("vi = 'Đã tìm thấy giá trị bằng 0 %1 khi tính lại theo đơn vị tính tại dòng %2 danh sách ""%3""';
																|ru = 'Обнаружено нулевое %1 при пересчете в единицу хранения в строке %2 списка ""%3""';
																|en = 'Zero %1 is detected when converted to stock UOM in line %2 of the %3 list'; fa = 'Zero %1 is detected when converted to stock UOM in line %2 of the %3 list';
																|it = 'È stato rilevato un %1 nullo durante il ricalcolo nell''unità di stoccaggio nella stringa %2 dell''elenco ""%3""';
																|pl = 'Ujawniona jest zerowa %1 podczas przeliczenia do jednostki przechowywania w wierszu %2 listy ""%3""';
																|tr = '""%3"" listesinin %2 satırındaki depolama birimine yeniden hesaplama yapılırken %1 sıfır algılandı'");
	MessageTemplateNotSpecifiedOptionForDebitingReflection	= NStr("vi = 'Chưa chỉ ra phương án ghi giảm các mặt hàng đã tiếp nhận tại dòng %1 danh sách ""%2""';
																	|ru = 'Не указан вариант списания принятых позиций в строке %1 списка ""%2""';
																	|en = 'Received item write-off option is not specified in line %1 of the %2 list'; fa = 'Received item write-off option is not specified in line %1 of the %2 list';
																	|it = 'Non è indicata la variante di storno delle posizioni accettate nella stringa %1 dell''elenco ""%2""';
																	|pl = 'Nie podano wariantu rozchodu przyjętych pozycji w wierszu %1 listy ""%2""';
																	|tr = '""%2"" listesinin %1 satırında kabul edilen kalemlerin gider yazılması için bir seçenek belirtilmemiştir'");
	MessageTemplateNotSpecifiedOptionToReflectDiscrepancy = NStr("vi = 'Chưa chỉ ra phương án phản ánh chênh lệch theo dòng %1 danh sách ""%2""';
																|ru = 'Не указан вариант отражения расхождений по строке %1 списка ""%2""';
																|en = 'Discrepancy recording option is not specified for line %1 of the %2 list'; fa = 'Discrepancy recording option is not specified for line %1 of the %2 list';
																|it = 'Non è indicata la variante di riflessione delle discrepanze in base alla stringa %1 dell''elenco ""%2""';
																|pl = 'Nie podano wariantu odzwierciedlenia odchylenia wg wiersza %1 listy ""%2""';
																|tr = '""%2"" listesinin %1 satırındaki tutarsızlıkları bildirmek için bir seçenek belirtilmemiştir'");
	MessageTemplateDoesNotMatchBase				= NStr("vi = 'Trường ""%1"" không tương ứng với trường tương tự của chứng từ cơ sở';
															|ru = 'Поле ""%1"" не соответствует аналогичному полю документа основания';
															|en = 'The %1 field does not match the respective base document field'; fa = 'The %1 field does not match the respective base document field';
															|it = 'Il campo ""%1"" non corrisponde al campo analogo del documento di base';
															|pl = 'Pole ""%1"" nie jest zgodne z analogicznym polem dokumentu źródłowego';
															|tr = '""%1"" alanı temel belgedeki aynı alana karşılık gelmiyor'");
	MessageTemplateDoesNotMatchPreviousCorrection= NStr("vi = 'Trường ""%1"" không tương ứng với trường tương tự của lần điều chỉnh trước';
														|ru = 'Поле ""%1"" не соответствует аналогичному полю предыдущей корректировки';
														|en = 'The %1 field does not match the respective field of the previous adjustment'; fa = 'The %1 field does not match the respective field of the previous adjustment';
														|it = 'Il campo ""%1"" non corrisponde al campo analogo della correzione precedente';
														|pl = 'Pole ""%1"" nie jest zgodne z analogicznym polem poprzedniej korekty';
														|tr = '""%1"" alanı önceki düzeltmedeki aynı alana karşılık gelmiyor'");
	
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
											|en = 'Items'; fa = 'اقلام';
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
		
		If Selection.TypeOfVerification = "PriceNotSpecified_" Then
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
		
		If Selection.TypeOfVerification = "NotAmountSpecified" Then
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
			
			MessageText = StrTemplate(MessageTemplateDoesNotMatchBase, NStr("vi = 'Nhà cung cấp';
																			|ru = 'Поставщик';
																			|en = 'Vendor'; fa = 'تأمین‌کننده';
																			|it = 'Поставщик';
																			|pl = 'Dostawca';
																			|tr = 'Tedarikçi'"));
			
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
	
	MessageTemplateDivergesValueQuantity	= NStr("vi = 'Cảnh báo: trong trường ""%1"", tại dòng %2 đã chỉ định số lượng khác với số lượng %3 sau điều chỉnh gần nhất';
													|ru = 'Предупреждение: в поле ""%1"" в строке %2 указано количество отличное от количества %3 после последней корректировки';
													|en = 'Warning: in line %2 of the %1 field, the quantity different from the quantity %3 after the last adjustment is specified'; fa = 'Warning: in line %2 of the %1 field, the quantity different from the quantity %3 after the last adjustment is specified';
													|it = 'Предупреждение: в поле ""%1"" в строке %2 указано количество отличное от количества %3 после последней корректировки';
													|pl = 'Warning: in line %2 of the %1 field, the quantity different from the quantity %3 after the last adjustment is specified';
													|tr = 'Uyarı: %2 satırdaki ""%1"" alanında, son düzeltmeden sonraki %3miktarından farklı bir miktar belirtildi'");
	MessageTemplateDivergesValueAmount		= NStr("vi = 'Cảnh báo: trong trường ""%1"", tại dòng %2 đã chỉ định số tiền khác với số tiền %3 sau khi điều chỉnh gần nhất';
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
	MessageTemplateErrorSpecifyingAmountAfter	= NStr("vi = 'Số tiền thuế GTGT sau khi điều chỉnh %1%2 với thuế suất ""%3"" nhiều hơn tổng số tiền sau khi điều chỉnh theo dòng %4%5 tại dòng %6 danh sách ""%7""';
														|ru = 'Сумма НДС после корректировки %1 %2 при ставке ""%3"" больше общей суммы после корректировки по строке %4 %5 в строке %6 списка ""%7""';
														|en = 'VAT rate after the adjustment %1 %2 at rate %3 is greater than the total amount after the adjustment for line %4 %5 in line %6 of the %7 list'; fa = 'VAT rate after the adjustment %1 %2 at rate %3 is greater than the total amount after the adjustment for line %4 %5 in line %6 of the %7 list';
														|it = 'L''importo IVA dopo la correzione %1%2 all''aliquota ""%3"" è maggiore dell''importo comune dopo la correzione in base alla stringa %4 %5 nella stringa %6 dell''elenco ""%7""';
														|pl = 'Kwota VAT po korekcie %1 %2 przy stawce ""%3"" jest większa niż łączna wartość po korekcie wg wiersza %4 %5 w wierszu %6 listy ""%7""';
														|tr = '""%3"" oranındaki %1%2düzeltmesi sonrası KDV tutarı, ""%7"" listesinin %6 satırındaki %4%5düzeltmesi sonrası toplam tutardan yüksektir'");
	
	While Selection.Next() Do
		
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
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	""ErrorSpecifyingAmount""		AS TypeOfVerification,
	|	TableOfGoods.Sum		AS Sum,
	|	TableOfGoods.VATAmount		AS VATAmount,
	|	TableOfGoods.VATRate	AS VATRate,
	|	CASE
	|		WHEN TableOfGoods.Sum < 0
	|				AND TableOfGoods.Sum - TableOfGoods.VATAmount <= 0
	|			THEN FALSE
	|		WHEN TableOfGoods.Sum >= 0
	|				AND TableOfGoods.Sum - TableOfGoods.VATAmount >= 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END						AS ThereAreErrorsInVATAmount
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
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
	|	TableOfGoods.LineNumber		AS LineNumber,
	|	""ErrorSpecifyingAmountAfter""	AS TypeOfVerification,
	|	TableOfGoods.AmountAfter		AS Sum,
	|	TableOfGoods.VATAmountAfter	AS VATAmount,
	|	TableOfGoods.VATRateAfter	AS VATRate,
	|	CASE
	|		WHEN TableOfGoods.AmountAfter < 0
	|				AND TableOfGoods.AmountAfter - TableOfGoods.VATAmountAfter <= 0
	|			THEN FALSE
	|		WHEN TableOfGoods.AmountAfter >= 0
	|				AND TableOfGoods.AmountAfter - TableOfGoods.VATAmountAfter >= 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END							AS ThereAreErrorsInVATAmount
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
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

Function ResultsOfDiscrepancyCheck(VTAdjustmentTable)
	
	CheckResult = New Structure;
	CheckResult.Insert("AmountForOtherIncome",	0);
	CheckResult.Insert("AmountForOtherExpenses",	0);
	
	For Each LineOfDiscrepancies In VTAdjustmentTable Do
		If LineOfDiscrepancies.VATRate = LineOfDiscrepancies.VATRateAfter
			Or (LineOfDiscrepancies.QuantityAfter = 0
				And LineOfDiscrepancies.VATAmountAfter = 0
				And LineOfDiscrepancies.VATAmountAfter = 0) Then
			
			DiscrepancySumWithVAT	= LineOfDiscrepancies.AmountWithVATAfter - LineOfDiscrepancies.AmountIncludingVAT;
			DiscrepancyInAmountOfVAT		= LineOfDiscrepancies.VATAmountAfter - LineOfDiscrepancies.VATAmount;
			
			CalculateAmountsOfExpensesAndIncome(CheckResult, DiscrepancySumWithVAT, DiscrepancyInAmountOfVAT,
				LineOfDiscrepancies.PostingOption, LineOfDiscrepancies.ToExpenseAs);
			
		Else
			
			DiscrepancySumWithVAT	= LineOfDiscrepancies.AmountWithVATAfter;
			DiscrepancyInAmountOfVAT		= LineOfDiscrepancies.VATAmountAfter;
			
			CalculateAmountsOfExpensesAndIncome(CheckResult, DiscrepancySumWithVAT, DiscrepancyInAmountOfVAT,
				LineOfDiscrepancies.PostingOption, LineOfDiscrepancies.ToExpenseAs);
		EndIf;
		
		DiscrepancySumWithVAT	= -LineOfDiscrepancies.AmountIncludingVAT;
		DiscrepancyInAmountOfVAT		= -LineOfDiscrepancies.VATAmount;
		
		CalculateAmountsOfExpensesAndIncome(CheckResult, DiscrepancySumWithVAT, DiscrepancyInAmountOfVAT,
			LineOfDiscrepancies.OptionToReflectWriteOff, LineOfDiscrepancies.ToExpenseAs);
		
	EndDo;
	
	Return CheckResult;
	
EndFunction

Procedure CalculateAmountsOfExpensesAndIncome(SumData,
													DiscrepancySumWithVAT,
													DiscrepancyInAmountOfVAT,
													PostingOption,
													ToExpenseAs)
	
	If PostingOption = Enums.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome Then
		SumData.AmountForOtherIncome = SumData.AmountForOtherIncome + ?(DiscrepancySumWithVAT < 0,
																			-DiscrepancySumWithVAT,
																			DiscrepancySumWithVAT);
	ElsIf Not ToExpenseAs
		And PostingOption = Enums.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs Then
		
		SumData.AmountForOtherExpenses = SumData.AmountForOtherExpenses + ?(DiscrepancySumWithVAT < 0,
																				-DiscrepancySumWithVAT,
																				DiscrepancySumWithVAT);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

 #Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Documents.PurchaseAdjustment.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.62";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("7144821c-a835-4238-a7d5-52a2ec41bcee");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.PurchaseAdjustment.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật chứng từ ""Điều chỉnh mua"":';
								|ru = 'Обновление документов ""Корректировка приобретения"":';
								|en = 'Update the ""Purchase adjustment"" documents:'; fa = 'Update the ""Purchase adjustment"" documents:';
								|it = 'Обновление документов ""Корректировка приобретения"":';
								|pl = 'Update the ""Purchase adjustment"" documents:';
								|tr = '""Satın alma düzeltmesi"" belgelerinin yenilenmesi'"));
	ListOfDescriptions.Add(NStr("vi = '- điền mục tin ""Phương án tiếp nhận dịch vụ"" bằng giá trị của mục tin ""Phương án tiếp nhận hàng hóa"".';
								|ru = '- заполняет реквизит ""Вариант приемки услуг"" значением реквизита ""Вариант приемки товаров"".';
								|en = '- Fills the ""Service receipt option"" attribute with the ""Goods receipt option"" attribute value.'; fa = '- Fills the ""Service receipt option"" attribute with the ""Goods receipt option"" attribute value.';
								|it = '- Fills the ""Service receipt option"" attribute with the ""Goods receipt option"" attribute value.';
								|pl = '- Fills the ""Service receipt option"" attribute with the ""Goods receipt option"" attribute value.';
								|tr = '""Hizmet kabulü seçeneği"" özniteliğini ""Mal kabulü seçeneği"" özniteliğinin değeriyle doldurur.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.PurchaseAdjustment.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.PurchaseAdjustment.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.PurchaseAdjustment";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	DocumentAttributes.Ref AS Ref
	|FROM
	|	Document.PurchaseAdjustment AS DocumentAttributes
	|		INNER JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON DocumentAttributes.Contract = CounterpartyContracts.Ref
	|WHERE
	|	DocumentAttributes.ServiceReceiptOption = VALUE(Enum.GoodsReceiptOptions.EmptyRef)";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Document.PurchaseAdjustment";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	UpdatedData.Ref AS Ref
	|INTO UpdatedData
	|FROM
	|	&UpdatedData AS UpdatedData
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UpdatedData.Ref AS Ref,
	|	DocumentAttributes.DataVersion AS DataVersion,
	|	DocumentAttributes.GoodsReceiptOption AS GoodsReceiptOption
	|FROM
	|	UpdatedData AS UpdatedData
	|		LEFT JOIN Document.PurchaseAdjustment AS DocumentAttributes
	|		ON UpdatedData.Ref = DocumentAttributes.Ref";
	
	Query.SetParameter("UpdatedData", UpdatedData);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		ExceptionReason = 0;
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			Block.Add(FullObjectName).SetValue("Ref", Selection.Ref);
			Block.Lock();
			
			DocumentObject = InfobaseUpdateTM.CheckGetObject(Selection.Ref, Selection.DataVersion, Parameters.Queue);
			
			ObjectModified = False;
			
			If DocumentObject <> Undefined Then
				If Not ValueIsFilled(DocumentObject.ServiceReceiptOption) Then
					DocumentObject.ServiceReceiptOption = Selection.GoodsReceiptOption;
					ObjectModified = True;
				EndIf;
			EndIf;
			
			ExceptionReason = 2; // Record
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
			If ExceptionReason = 2 Then
				Raise NStr("vi = 'Không thể xử lý cập nhật chứng từ ""Điều chỉnh mua hàng"".';
							|ru = 'Не удалось обработать обновление документов ""Корректировка приобретения"".';
							|en = 'Cannot process the update of the ""Purchase adjustment"" documents.'; fa = 'Cannot process the update of the ""Purchase adjustment"" documents.';
							|it = 'Cannot process the update of the ""Purchase adjustment"" documents.';
							|pl = 'Cannot process the update of the ""Purchase adjustment"" documents.';
							|tr = '""Satın alma düzeltmesi"" belgelerinin güncellenmesi işlenemedi.'");
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf

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
	
	DocumentMechanisms.Add("Purchases");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");	
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("CashManagement");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfWorks");
	DocumentMechanisms.Add("PricesAndDiscounts");
	
	RetailReturnsReportLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * RegisterName - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.RetailReturnsReport") Then
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
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers);
		QueryTextTableAcquiringContractARAP(Query, QueryTexts, Registers);
		QueryTextTableCashInCashRegistersCR(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers);
		QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers);
		QueryTextBonusPoints(Query, QueryTexts, Registers);
		QueryTextTableServicesForRegistrationOfReportsToPrincipal(Query, QueryTexts, Registers);
		QueryTextTableCashInTransit(Query, QueryTexts, Registers);

		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
				
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
	
		RetailReturnsReportLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ArrangeShipmentAtRetail(Query, QueryTexts, Registers);
	
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
	
	RetailReturnsReportLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the "retail sales Report" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
//	Returns:
//		ValueTableRow - Added a row to the table of values of the Creation command Base, describing the method of creation based on.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	CreateBasedOnCommand = Undefined;
	If AccessRight("Insert", Metadata.Documents.RetailReturnsReport) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.RetailReturnsReport.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.RetailReturnsReport);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseRetailSales";
	EndIf;

	Return CreateBasedOnCommand;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.CompanyStockBalance.AddReportCommand(ReportsCommands);
	
	RetailReturnsReportLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,Date";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.RetailReturnsReport";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, True);
	
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceivingByReturnFromACustomer);
	SeriesSpecificationParameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	
	If WarehousesServer.UseWarerooms(Object.Warehouse) Then
		SeriesSpecificationParameters.LinkFields.Add("Premise");
	EndIf;
	
	SeriesSpecificationParameters.LinkFields.Add("ByCorrectionReceipt");
	SeriesSpecificationParameters.LinkFields.Add("CostDefiningMethod");
	SeriesSpecificationParameters.LinkFields.Add("DocumentSalesOfGoodsAndServices");
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.SelectionPlanning = True;	
	SeriesSpecificationParameters.FactOfSelection = True;
	SeriesSpecificationParameters.Date = Object.Date;
	
	SeriesSpecificationParameters.DocumentOperation_ = Enums.BusinessTransactions.ReturnOnSameDayBasis;

	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	ThereArePremises = (SeriesSpecificationParameters.LinkFields.Find("Premise") <> Undefined);
	If ThereArePremises Then
		Return RequestTextForFillingInStatusesForSpecifyingSeriesWithPremises();
	Else
		Return TextOfRequestToFillInStatusesForSpecifyingSeriesWithoutRooms();
	EndIf;
	
EndFunction

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return RetailReturnsReportLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//  String - query text.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return RetailReturnsReportLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

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
	|	AND ValueAllowed(CashRegister)
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(Warehouse)";

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

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.RetailReturnsReport - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Warehouse = Object.Warehouse;
	FillParameters.Department = Object.Department;
	
	FillParameters.Retail_ = True;
	
	Return FillParameters;
	
EndFunction

// Returns a structure with the name of the tabular parts of the document that store information about the goods.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* Goods - ValueTable, TabularSection, Undefined - data about the goods of the document.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure("Goods");
	
	Return DocumentTables;
	
EndFunction

#Region Other

// Creates a representation of the metadata object in the main language.
// 
// Returns:
//  String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	SynonymForInformationDatabaseEntry = NStr(
		"vi = 'Bảng kê hàng hóa bán lẻ trả lại';
		|ru = 'Отчет о розничных возвратах';
		|en = 'Retail return report'; fa = 'گزارش برگشت خرده‌فروشی';
		|it = 'Report sui resi al dettaglio';
		|pl = 'Raport o zwrotach detalicznych';
		|tr = 'Perakende i̇ade raporu'",
		DefaultLanguageCode);
		
	Return SynonymForInformationDatabaseEntry;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Posting

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	SynonymForDocumentTable = "";
	FullDocumentName = "Document.RetailReturnsReport";
	RedefiningParameterCalculation = New Structure;

	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));

	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("Partner",                 "VALUE(Catalog.Partners.RetailCustomer)");
	RedefiningParameterCalculation.Insert("Counterparty",              "VALUE(Catalog.Counterparties.EmptyRef)");
	RedefiningParameterCalculation.Insert("Contract",                 "VALUE(Catalog.CounterpartyContracts.EmptyRef)");
	RedefiningParameterCalculation.Insert("LineOfBusiness", "VALUE(Catalog.LinesOfBusiness.EmptyRef)");
	RedefiningParameterCalculation.Insert("NumberForPrinting",           """""");
	RedefiningParameterCalculation.Insert("ContractInformation",    """""");
		
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		RequestHasSource = False;
		
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

	QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
		QueryText,
		FullDocumentName,
		SynonymForDocumentTable,
		RequestHasSource,
		RedefiningParameterCalculation);
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;	
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref                            AS Ref,
	|	DocumentData.Number                             AS Number,
	|	DocumentData.Organization                       AS Organization,
	|	DocumentData.CashRegister.CashRegisterType                 AS CashRegisterType,
	|	VALUE(Catalog.Partners.RetailCustomer) AS Partner,
	|	VALUE(Catalog.Counterparties.EmptyRef)     AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	DocumentData.Date                              AS Period,
	|	DocumentData.Currency                            AS Currency,
	|	VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer) AS BusinessOperation,
	|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods) AS BusinessOperationRetailSales,	
	|	VALUE(Catalog.CashFlowReportItems.CashReceiptFromCustomer) AS CashFlowItem,
	|	VALUE(Catalog.CashFlowReportItems.RefundToCustomer) AS CashFlowItemRefundToCustomer,	
	|	DocumentData.Department                     AS Department,
	|	DocumentData.Department.OptionOfAssignedAccountingOfGoods AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.EmployeeResponsible                     AS Manager,
	|	DocumentData.EmployeeResponsible                     AS EmployeeResponsible,
	|	DocumentData.Warehouse                             AS Warehouse,
	|	DocumentData.PriceIncludesVAT                   AS PriceIncludesVAT,
	|	DocumentData.CashRegisterShift                     AS CashRegisterShift,
	|	DocumentData.CashRegisterShift.Status                     AS CashRegisterShiftStatus,
	|	DocumentData.CashRegisterShift.PeriodEndTransactionsStatus AS PeriodEndTransactionsStatus,
	|	DocumentData.CompanyUSAIS                  AS CompanyUSAIS,
	|	DocumentData.VATTaxation                AS VATTaxation,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReturnFromRetailCustomer) AS BusinessTransactionSetting,
	|	VALUE(Catalog.BusinessTransactionsSettings.RetailSaleOfGoods) AS SettingUpBusinessOperationRetailSales,
	|	DocumentData.Comment 					  AS Comment,
	|	DocumentData.DocumentAmount 					  AS DocumentAmount,
	|	DocumentData.Posted 						  AS Posted,
	|	DocumentData.DeletionMark 				  AS DeletionMark,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|FROM
	|	Document.RetailReturnsReport AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Attributes.Organization, Attributes.Period);
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.Text = "SELECT
	|	SUM(TableForCalculatingAmountOfPaymentInCash.Sum) AS CashPaymentAmount,
	|	SUM(TableForCalculatingAmountOfPaymentInCash.VATAmount) AS VATAmount
	|FROM
	|	(SELECT
	|		&DocumentAmount AS Sum,
	|		0 AS VATAmount
	|
	|	UNION ALL
	|
	|	SELECT
	|		-TabularSection.Sum,
	|		0
	|	FROM
	|		Document.RetailReturnsReport.PaymentWithPaymentCards AS TabularSection
	|	WHERE
	|		TabularSection.Ref = &Ref
	|
	|	UNION ALL
	|
	|	SELECT
	|		0,
	|		TabularSection.VATAmount
	|	FROM
	|		Document.RetailReturnsReport.Goods AS TabularSection
	|	WHERE
	|		TabularSection.Ref = &Ref) AS TableForCalculatingAmountOfPaymentInCash";
	
	ResultTable2 = Query.Execute().Unload();	
	Query.SetParameter("CashPaymentAmount", ResultTable2[0].CashPaymentAmount);
	Query.SetParameter("VATAmount", ResultTable2[0].VATAmount);
	
	If Attributes.CashRegisterType = Enums.CashRegisterTypes.FiscalCashRegisters
		And ValueIsFilled(Attributes.CashRegisterShift) Then
		FullImplementation = (Attributes.CashRegisterShiftStatus = Enums.CashRegisterShiftStatuses.Closed_
		                    And Attributes.PeriodEndTransactionsStatus = Enums.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreatedReceiptsAreArchived);
	Else
		FullImplementation = True;
	EndIf;
	
	Query.SetParameter("BeginningOfMonthOfPeriod",                      BegOfMonth(Attributes.Period));
	
	Query.SetParameter("Ref",                                   DocumentRef);
	Query.SetParameter("FullImplementation",                         FullImplementation);
	Query.SetParameter("PriceIncludesVAT",                          ?(Attributes.PriceIncludesVAT, 0, 1));
	Query.SetParameter("PriceDoesNotIncludeVAT",                        ?(Attributes.PriceIncludesVAT, -1, 0));
	Query.SetParameter("ManagementAccountingCurrency",               Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("UseAgentServiceSale",               GetFunctionalOption("UseAgentServiceSale"));
	
	Query.SetParameter("CurrentDate",                              CurrentUniversalDate());
	
	Query.SetParameter("TaxationOfOrganization",                  AccountingParametersForOrganization.BasicTaxationVATSales);	
	
	Query.SetParameter("LineOfBusiness",                  Catalogs.LinesOfBusiness.EmptyRef());
	Query.SetParameter("DisplayBasicUnitsOfMeasureInPrintForms",          Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get());
	
	Query.SetParameter("MetadataIdentifier",           Common.MetadataObjectID(TypeOf(DocumentRef)));
	
	ContractInformation = Undefined;
	Query.SetParameter("ContractInformation",             ContractInformation);
	Query.SetParameter("NumberForPrinting",		   			  Attributes.Number);
	
	Query.SetParameter("StartDateOfBonusPointsMechanism_2_5", Constants.StartDateOfBonusPointsMechanism_2_5.Get());
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextTableAcquiringContractARAP(Query, QueryTexts, Registers)
	
	RegisterName = "AcquiringContractARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCashFlowArticles", QueryTexts) Then
		QueryTextTTCashFlowArticles(QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	PaymentTable_3.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	VALUE(Enum.AcquiringCashTypes.CashIssueByPaymentCard) AS CashType,
	|	&Organization                                   AS Organization,
	|	&Currency                                        AS Currency,
	|	PaymentTable_3.POSTerminal          AS POSTerminal,
	|	CASE
	|		WHEN NOT PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract
	|		ELSE PaymentTable_3.POSTerminal.Owner
	|	END AS Contract,
	|	PaymentTable_3.AuthorizationCode                 AS AuthorizationCode,
	|	PaymentTable_3.PaymentCardNumber            AS PaymentCardNumber,
	|	VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard) AS BusinessOperation,
	|	&Period                                        AS PaymentDate,
	|	PaymentTable_3.Sum                         AS Sum,
	|	CFItems.CashFlowItem       AS CashFlowItem
	|FROM
	|	Document.RetailReturnsReport.PaymentWithPaymentCards AS PaymentTable_3
	|		LEFT JOIN TTCashFlowArticles AS CFItems
	|		ON PaymentTable_3.LineNumber = CFItems.LineNumber
	|		AND CFItems.Return
	|
	|WHERE
	|	&FullImplementation
	|	AND PaymentTable_3.Ref = &Ref
	|	AND CASE
	|		WHEN PaymentTable_3.ConnectionContract <> VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract.DetailedTransactionReconciliation
	|		ELSE ISNULL(PaymentTable_3.POSTerminal.Owner.DetailedTransactionReconciliation, TRUE)
	|	END
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber 			AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) 	AS RecordType,
	|	&Period 								AS Period,
	|	&Warehouse 									AS Warehouse,
	|	&Organization 							AS ShipmentCompany,
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
	|	-TableTypesOfStocks_.Count AS Count,
	|	-TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|		ELSE UNDEFINED
	|	END AS DocumentSalesOfGoodsAndServices,	
	|	&BusinessOperation AS BusinessOperation,	
	|
	|	CASE WHEN TableTypesOfStocks_.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		AND &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	THEN
	|		VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|	ELSE
	|		&VATTaxation 
	|	END AS VATTaxation,
	|	TableTypesOfStocks_.DimensionSalesOfGoodsAndServices AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Primary
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	NOT TableTypesOfStocks_.ByCorrectionReceipt
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber 			AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) 	AS RecordType,
	|	&Period 								AS Period,
	|	&Warehouse 									AS Warehouse,
	|	&Organization 							AS ShipmentCompany,
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
	|	-TableTypesOfStocks_.Count AS Count,
	|	-TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,	
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	&BusinessOperationRetailSales AS BusinessOperation,
	|
	|	CASE WHEN TableTypesOfStocks_.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		AND &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	THEN
	|		VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|	ELSE
	|		&VATTaxation 
	|	END AS VATTaxation,
	|	UNDEFINED AS CorItemsLocationAttributes,
	|	FALSE AS Primary
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.ByCorrectionReceipt
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoodsForTransfer";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Warehouse AS Warehouse,
	|	TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization AS CompanyOwner,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS SellerInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	-TableTypesOfStocks_.Count AS Count
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.SaleOfAnotherCompanyInventory
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(Query, QueryTexts);
	EndIf; 
	
	InitializeProductAccountingAnalyticsKeys(Query);
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.Currency AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.CommitteeProductAnalysis AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	&BusinessOperation AS BusinessOperation,
	|	-TableTypesOfStocks_.Count AS Count,
	|
	|	CASE WHEN TableTypesOfStocks_.Currency = &Currency THEN
	|		-TableTypesOfStocks_.AmountIncludingVAT
	|	ELSE
	|		-TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END AS RevenueAmount,
	|
	|	(-TableTypesOfStocks_.Count) AS QuantityToRegister,
	|	(-TableTypesOfStocks_.QuantityByGBRN) AS QuantityForRegistrationByProductBatchID,
	|
	|	CASE WHEN TableTypesOfStocks_.Currency = &Currency THEN
	|		-TableTypesOfStocks_.AmountIncludingVAT
	|	ELSE
	|		-TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END AS RevenueAmountToRegister,
	|	
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID AS RowID
	|	
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|	LEFT JOIN
	|		TTExchangeRates AS ExchangeRates
	|	ON
	|		TableTypesOfStocks_.InventoryOwnerAttribute.Currency = ExchangeRates.Currency
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|   AND NOT TableTypesOfStocks_.ByCorrectionReceipt
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.Currency AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.CommitteeProductAnalysis AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	&BusinessOperationRetailSales AS BusinessOperation,
	|	-TableTypesOfStocks_.Count AS Count,
	|
	|	CASE WHEN TableTypesOfStocks_.Currency = &Currency THEN
	|		-TableTypesOfStocks_.AmountIncludingVAT
	|	ELSE
	|		-TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END AS RevenueAmount,
	|
	|	-TableTypesOfStocks_.Count AS QuantityToRegister,
	|	-TableTypesOfStocks_.QuantityByGBRN AS QuantityForRegistrationByProductBatchID,
	|
	|	CASE WHEN TableTypesOfStocks_.Currency = &Currency THEN
	|		-TableTypesOfStocks_.AmountIncludingVAT
	|	ELSE
	|		-TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END AS RevenueAmountToRegister,
	|	
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&SettingUpBusinessOperationRetailSales AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID AS RowID
	|	
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|	LEFT JOIN
	|		TTExchangeRates AS ExchangeRates
	|	ON
	|		TableTypesOfStocks_.InventoryOwnerAttribute.Currency = ExchangeRates.Currency
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|   AND TableTypesOfStocks_.ByCorrectionReceipt
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers)
	
	RegisterName = "RevenueAndCOGS";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	SetRequestParametersCurrencyCoefficients(Query);
	InitializeTrackingAnalyticsKeysForPartners(Query);
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		THEN TableTypesOfStocks_.ImplementationDivision
	|		ELSE &Department 
	|		END AS Department,
	|	TableTypesOfStocks_.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS CounterpartyLineOfBusiness,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.LineOfBusiness AS ProductLineOfBusiness,
	|	TableTypesOfStocks_.SetAccountingDimension AS SetAccountingDimension,
	|	TableTypesOfStocks_.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN TableTypesOfStocks_.ShopFloorStockroom
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END AS AccountingSection,
	|	TableTypesOfStocks_.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	TableTypesOfStocks_.VATTaxation AS VATActivityType,
	|
	|	TableTypesOfStocks_.Seller AS Manager,
	|
	|	-TableTypesOfStocks_.Count AS Count,
	|	-CAST(TableTypesOfStocks_.AmountIncludingVAT
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS RevenueAmount,
	|
	|	-CAST((TableTypesOfStocks_.AmountIncludingVAT
	|			-TableTypesOfStocks_.VATAmount)
	|			* &ConversionRateToManCurrency AS NUMBER(31,2)) AS RevenueAmountExcludingVAT,
	|
	|	-CAST((TableTypesOfStocks_.AmountIncludingVAT
	|			-TableTypesOfStocks_.VATAmount)
	|			* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS RevenueAmountExclVATLocal,
	|
	|	-CAST(TableTypesOfStocks_.AmountIncludingVAT
	|			* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS RevenueAmountIncludingVATLocal,
	|
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			OR TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument) 
	|	THEN -CAST(TableTypesOfStocks_.AmountIncludingVAT * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	ELSE 0
	|	END AS Cost,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			OR TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)	
	|	THEN -CAST((TableTypesOfStocks_.AmountIncludingVAT
	|					-TableTypesOfStocks_.VATAmount)
	|					* &ConversionRateToManCurrency AS NUMBER(31,2))
	|	ELSE 0
	|	END AS CostExcludingVAT,
	|	CASE WHEN (TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) 
	|			OR TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|	 AND &CompanyManagementAccounting
	|	THEN -CAST((TableTypesOfStocks_.AmountIncludingVAT
	|					-TableTypesOfStocks_.VATAmount)
	|					* &ConversionRateToManCurrency AS NUMBER(31,2))
	|	ELSE 0
	|	END AS CostMan,
	|
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		 OR TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)	
	|	THEN -CAST((TableTypesOfStocks_.AmountIncludingVAT
	|					-TableTypesOfStocks_.VATAmount)
	|					* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	ELSE 0
	|	END AS LocalCost,
	|
	|	-CAST(TableTypesOfStocks_.ManualDiscount
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS ManualDiscount,
	|
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS Terms,
	|
	|	&Currency AS ARAPCurrency,
	|	-TableTypesOfStocks_.AmountIncludingVAT AS AmountInARAPCurrency,
	|	-(TableTypesOfStocks_.AmountIncludingVAT + TableTypesOfStocks_.VATAmount) AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	-TableTypesOfStocks_.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	-(TableTypesOfStocks_.AmountIncludingVAT + TableTypesOfStocks_.VATAmount) AS AmountExcludingVATInDocumentCurrency,
	|
	|	&VATTaxation    AS VATTaxation,	
	|	CASE
	|	WHEN TableTypesOfStocks_.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		THEN VALUE(Enum.BusinessTransactions.GoodsReceiptByGoodsReturn)
	|	WHEN TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|	ELSE
	|		VALUE(Enum.BusinessTransactions.ReverseOfSale)
	|	END AS BusinessOperation,
	|
	|	TableTypesOfStocks_.Products AS SourceOfProductFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)
	|		WHEN TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|		WHEN TableTypesOfStocks_.DimensionSalesOfGoodsAndServices <> TableTypesOfStocks_.ItemsLocationAttributes
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSaleReturnToAnotherWarehouse)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
	|	END AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.VATRate AS VATRate
	|	
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.Count <> 0
	|	AND NOT TableTypesOfStocks_.TraceableWork
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber                      AS LineNumber,
	|	&Period                                        AS Period,
	|	CASE
	|		WHEN GoodsTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		THEN GoodsTable.ImplementationDivision
	|		ELSE &Department 
	|		END AS Department,	
	|	GoodsTable.AccountingDimensionByPartners        AS AccountingDimensionByPartners,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS CounterpartyLineOfBusiness,
	|	GoodsTable.ItemsLocationAttributes       AS ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness		   AS ProductLineOfBusiness,
	|	GoodsTable.SetAccountingDimension            AS SetAccountingDimension,
	|	CASE
	|		WHEN GoodsTable.Products.Principal <> UNDEFINED
	|		THEN VALUE(Enum.InventoryTypes.AgentService)
	|		ELSE VALUE(Enum.InventoryTypes.OperationService)
	|	END                                          AS InventoryType,
	|	GoodsTable.InventoryOwnerAttribute					   AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END) AS AccountingSection,
	|	GoodsTable.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	GoodsTable.VATTaxation AS VATActivityType,
	|
	|	GoodsTable.Seller                         AS Manager,
	|
	|	-GoodsTable.Count AS Count,
	|	-CAST(
	|		(GoodsTable.Sum
	|		+ &PriceIncludesVAT * GoodsTable.VATAmount)
	|	 	* &ConversionRateToManCurrency
	|		AS NUMBER(31,2)
	|	) AS RevenueAmount,
	|
	|	-CAST(
	|		(GoodsTable.Sum
	|			+ &PriceIncludesVAT * GoodsTable.VATAmount - GoodsTable.VATAmount)
	|	 		* &ConversionRateToManCurrency
	|		AS NUMBER(31,2)
	|	) AS RevenueAmountExcludingVAT,
	|
	|	-CAST(
	|		(GoodsTable.Sum
	|			+ &PriceIncludesVAT * GoodsTable.VATAmount - GoodsTable.VATAmount)
	|	 		* &FactorOfConversionToCurrencyOfRegul
	|		AS NUMBER(31,2)) AS RevenueAmountExclVATLocal,
	|
	|	-CAST(
	|		(GoodsTable.Sum + &PriceIncludesVAT * GoodsTable.VATAmount)
	|	 		* &FactorOfConversionToCurrencyOfRegul
	|		AS NUMBER(31,2)) AS RevenueAmountIncludingVATLocal,
	|
	|	CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|			OR GoodsTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument) 	
	|		THEN -CAST(
	|				(GoodsTable.Sum + &PriceIncludesVAT * GoodsTable.VATAmount)
	|					* &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0
	|	END AS Cost,
	|	CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|			OR GoodsTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)	
	|		THEN -CAST((GoodsTable.Sum + &PriceIncludesVAT * GoodsTable.VATAmount - GoodsTable.VATAmount)
	|			* &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0
	|	END AS CostExcludingVAT,
	|	CASE
	|		WHEN (GoodsTable.Principal <> UNDEFINED
	|			OR GoodsTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))	
	|	 	 AND &CompanyManagementAccounting
	|		THEN -CAST((GoodsTable.Sum + &PriceIncludesVAT * GoodsTable.VATAmount - GoodsTable.VATAmount)
	|			* &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0
	|	END AS CostMan,
	|
	|	CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|			OR GoodsTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)	
	|		THEN -CAST((GoodsTable.Sum + &PriceIncludesVAT * GoodsTable.VATAmount - GoodsTable.VATAmount)
	|					* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		ELSE 0
	|	END AS LocalCost,
	|
	|	-CAST(GoodsTable.ManualDiscount
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS ManualDiscount,
	|
	|	&Warehouse AS Warehouse,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS Terms,
	|
	|	&Currency AS ARAPCurrency,
	|	-(GoodsTable.Sum + &PriceIncludesVAT * GoodsTable.VATAmount) AS AmountInARAPCurrency,
	|	-((GoodsTable.Sum + &PriceIncludesVAT * GoodsTable.VATAmount) - GoodsTable.VATAmount) AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	-(GoodsTable.Sum + &PriceIncludesVAT * GoodsTable.VATAmount) AS AmountInDocumentCurrency,
	|	-((GoodsTable.Sum + &PriceIncludesVAT * GoodsTable.VATAmount) - GoodsTable.VATAmount) AS AmountExcludingVATInDocumentCurrency,
	|
	|	&VATTaxation    AS VATTaxation,
	|	CASE
	|	WHEN GoodsTable.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		THEN VALUE(Enum.BusinessTransactions.GoodsReceiptByGoodsReturn)
	|	WHEN GoodsTable.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|	ELSE
	|		VALUE(Enum.BusinessTransactions.ReverseOfSale)
	|	END AS BusinessOperation,	
	|	GoodsTable.Products AS SourceOfProductFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	GoodsTable.RowID AS FinRecordID,
	|	CASE WHEN GoodsTable.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)
	|	WHEN GoodsTable.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|	ELSE
	|		VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
	|	END AS BusinessTransactionSetting,
	|	GoodsTable.VATRate AS VATRate
	|	
	|FROM
	|	TTOperationServices AS GoodsTable
	|WHERE
	|	GoodsTable.Count <> 0
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashInCashRegistersCR(Query, QueryTexts, Registers)
	
	RegisterName = "CashInCashRegistersCR";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAmountByPaymentCards", QueryTexts) Then
		QueryTextTTAmountByPaymentCards(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAmountBonusPoints", QueryTexts) Then
		QueryTextTTAmountBonusPoints(Query, QueryTexts);
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.CashRegister.Owner AS Organization,
	|	DocumentData.CashRegister AS CashRegister,
	|	(DocumentData.DocumentAmount
	|	- ISNULL(TTAmountByPaymentCards.Sum, 0)) AS Sum,
	|	(CAST((DocumentData.DocumentAmount
	|	- ISNULL(TTAmountByPaymentCards.Sum, 0)) * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS SumCompl,
	|	(CAST((DocumentData.DocumentAmount
	|	- ISNULL(TTAmountByPaymentCards.Sum, 0)) * &ConversionRateToManCurrency AS NUMBER(31,2))) AS SumMan,
	|	VALUE(Enum.BusinessTransactions.RefundToCustomer) AS BusinessOperation,
	|	&CashFlowItemRefundToCustomer AS CashFlowItem,
	|	
	|	DocumentData.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RefundToCustomer) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RetailReturnsReport AS DocumentData
	|		LEFT JOIN TTAmountByPaymentCards AS TTAmountByPaymentCards
	|		ON (TRUE)
	|WHERE
	|	DocumentData.DocumentAmount - ISNULL(TTAmountByPaymentCards.Sum, 0) <> 0
	|	AND DocumentData.Ref = &Ref
	|	AND &FullImplementation
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = "
	|SELECT
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	SeriesTable.Series AS Series,
	|	SeriesTable.Count AS Count,
	|	&Ref AS Document,
	|	&Warehouse AS Sender,
	|	SeriesTable.Premise AS WareroomOfSender,
	|	VALUE(Enum.WarehouseTransactions.ReceivingByReturnFromACustomer) AS WarehouseOperation,	
	|	&Period AS Period,
	|	&Ref AS Recorder,
	|	TRUE AS ThisIsWarehouseRecord
	|FROM
	|	Document.RetailReturnsReport.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|	AND NOT SeriesTable.ByCorrectionReceipt	
	|	AND &FullImplementation
	|
	|UNION ALL
	|
	|SELECT
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Series,
	|	SeriesTable.Count,
	|	&Ref,
	|	&Warehouse,
	|	SeriesTable.Premise,
	|	VALUE(Enum.WarehouseTransactions.ReceivingByReturnFromACustomer),	
	|	&Period,
	|	&Ref,
	|	TRUE
	|FROM
	|	Document.RetailReturnsReport.Goods AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND NOT SeriesTable.ByCorrectionReceipt	
	|	AND &FullImplementation
	|
	|UNION ALL
	|	
	|SELECT
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	SeriesTable.Series AS Series,
	|	-SeriesTable.Count AS Count,
	|	&Ref AS Document,
	|	&Warehouse AS Sender,
	|	SeriesTable.Premise AS WareroomOfSender,
	|	VALUE(Enum.WarehouseTransactions.RetailShipment) AS WarehouseOperation,
	|	&Period AS Period,
	|	&Ref AS Recorder,
	|	TRUE AS ThisIsWarehouseRecord
	|FROM
	|	Document.RetailReturnsReport.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|	AND SeriesTable.ByCorrectionReceipt	
	|	AND &FullImplementation
	|
	|UNION ALL
	|
	|SELECT
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Series,
	|	-SeriesTable.Count,
	|	&Ref,
	|	&Warehouse,
	|	SeriesTable.Premise,
	|	VALUE(Enum.WarehouseTransactions.RetailShipment),
	|	&Period,
	|	&Ref,
	|	TRUE
	|FROM
	|	Document.RetailReturnsReport.Goods AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND SeriesTable.ByCorrectionReceipt	
	|	AND &FullImplementation
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""PaymentWithPaymentCards"" AS DataSource,
	|	FALSE   AS DistributeTotalAmount,
	|
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	
	|	DocumentTable.Sum AS AmountExcludingVAT,
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	FALSE AS RecordedInARAPAccounting,
	|	UNDEFINED AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.RetailReturnsReport.PaymentWithPaymentCards AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|
	|UNION ALL
	|
	// return of inventory types
	|SELECT
	|	""Merchandise workslugivo return"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	
	|	CASE WHEN DocumentTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		THEN -(DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount)
	|		ELSE (DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount)
	|		END AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	CASE WHEN DocumentTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)	
	|		THEN -DocumentTable.VATAmount 
	|		ELSE DocumentTable.VATAmount
	|		END AS VATAmount,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	FALSE AS RecordedInARAPAccounting,
	|	UNDEFINED AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|
	|FROM
	|	Document.RetailReturnsReport.InventoryKinds AS DocumentTable
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT DocumentTable.ByCorrectionReceipt
	|
	|UNION ALL
	|
	// return of services
	|SELECT
	|	""Merchandise workslugivo return"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	
	|	CASE WHEN DocumentTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		THEN -(DocumentTable.Sum 
	|				- CASE 
	|					WHEN DocumentTable.Ref.PriceIncludesVAT 
	|					THEN DocumentTable.VATAmount 
	|					ELSE 0 
	|				END)
	|		ELSE (DocumentTable.Sum 
	|				- CASE 
	|					WHEN DocumentTable.Ref.PriceIncludesVAT 
	|					THEN DocumentTable.VATAmount 
	|					ELSE 0 
	|				END)
	|		END AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	CASE WHEN DocumentTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)	
	|		THEN -DocumentTable.VATAmount 
	|		ELSE DocumentTable.VATAmount
	|		END AS VATAmount,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	FALSE AS RecordedInARAPAccounting,
	|	UNDEFINED AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|
	|FROM
	|	Document.RetailReturnsReport.Goods AS DocumentTable
	|		LEFT JOIN Document.RetailReturnsReport.InventoryKinds AS InventoryKinds
	|		ON DocumentTable.Ref = InventoryKinds.Ref
	|			AND DocumentTable.ItemsLocationAttributes = InventoryKinds.ItemsLocationAttributes
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.Products.ItemsType IN
	|		(VALUE(Enum.ItemsTypes.Work_5),
	|		 VALUE(Enum.ItemsTypes.OperationService))
	|	AND NOT DocumentTable.ByCorrectionReceipt
	|	AND InventoryKinds.Ref IS NULL
	|
	|UNION ALL
	|
	// storno types of stocks
	|SELECT
	|	""Product workslugistory"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	
	|	-(DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount) AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	-DocumentTable.VATAmount AS VATAmount,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	FALSE AS RecordedInARAPAccounting,
	|	UNDEFINED AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|
	|FROM
	|	Document.RetailReturnsReport.InventoryKinds AS DocumentTable
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.ByCorrectionReceipt 
	|
	|UNION ALL
	|	
	// storno services
	|SELECT
	|	""Product workslugistory"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	
	|	-(DocumentTable.Sum 
	|		- CASE 
	|			WHEN DocumentTable.Ref.PriceIncludesVAT 
	|				THEN DocumentTable.VATAmount 
	|			ELSE 0 
	|		END) AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	-DocumentTable.VATAmount AS VATAmount,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	FALSE AS RecordedInARAPAccounting,
	|	UNDEFINED AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|
	|FROM
	|	Document.RetailReturnsReport.Goods AS DocumentTable
	|		LEFT JOIN Document.RetailReturnsReport.InventoryKinds AS InventoryKinds
	|		ON DocumentTable.Ref = InventoryKinds.Ref
	|			AND DocumentTable.ItemsLocationAttributes = InventoryKinds.ItemsLocationAttributes
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.Products.ItemsType IN
	|		(VALUE(Enum.ItemsTypes.Work_5),
	|		 VALUE(Enum.ItemsTypes.OperationService))
	|	AND DocumentTable.ByCorrectionReceipt
	|	AND InventoryKinds.Ref IS NULL
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
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
	|	VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer) AS BusinessOperation,
	|	&Partner                                AS Partner,
	|	&Counterparty                             AS Counterparty,
	|	&Contract                                AS Contract,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	&Warehouse									AS StorageLocation,
	|	&Department                          AS Department,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	&EmployeeResponsible                          AS Author,
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
	|	&Period                                 AS RecordingInAccountingDate";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers)
	
	RegisterName = "MaterialsAndWorksInProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Period AS RecorderDate,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	-GoodsTable.Count AS Count,
	|	&VATTaxation AS VATTaxation
	|FROM
	|	TTOperationServices AS GoodsTable
	|WHERE
	|	GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.TraceableWork
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextBonusPoints(Query, QueryTexts, Registers)
	
	RegisterName = "BonusPoints";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBonusPoints", QueryTexts) Then
		QueryTextTTBonusPoints(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	BonusPoints.Period AS Period,
	|	BonusPoints.ValidityStartDate          AS ValidityStartDate,
	|	BonusPoints.DateToProcess              AS DateToProcess,
	|	BonusPoints.RecordType AS RecordType,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(BonusPoints.Accrued) AS Accrued,
	|	SUM(BonusPoints.ToWriteOff) AS ToWriteOff
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

Function QueryTextTableServicesForRegistrationOfReportsToPrincipal(Query, QueryTexts, Registers)
	
	RegisterName = "ServicesForRegistrationOfReportsToPrincipal";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
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
	|	-ToRegister.Count                      AS Count,
	|	-ToRegister.AmountIncludingVAT 
	|		* ExchangeRates.ConversionFactor_       AS RevenueAmount,
	|	-ToRegister.VATAmount 
	|		* ExchangeRates.ConversionFactor_       AS VATAmount,
	|	CASE
	|		WHEN ISNULL(ToRegister.Terms.RevalueServicesForConsignmentNotification, FALSE)
	|			THEN -ToRegister.AmountIncludingVATCompl
	|		ELSE 0
	|	END AS RevenueAmountExclVATLocal,
	|	CASE
	|		WHEN ISNULL(ToRegister.Terms.RevalueServicesForConsignmentNotification, FALSE)
	|			THEN -ToRegister.AmountIncludingVATMan
	|		ELSE 0
	|	END AS RevenueAmountMan,
	|
	|	ToRegister.DocumentSalesOfGoodsAndServices              AS DocumentSalesOfGoodsAndServices,	
	|	
	|	ToRegister.RowID            AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	ToRegister.RowID AS RowID
	|FROM
	|	TTOperationServices AS ToRegister
	|
	|	LEFT JOIN TTExchangeRates AS ExchangeRates
	|	ON ToRegister.Currency = ExchangeRates.Currency
	|WHERE
	|	ToRegister.PrincipalProductAnalysis <> UNDEFINED
	|	AND NOT ToRegister.ByCorrectionReceipt	
	|
	|UNION ALL
	|
	|SELECT
	|	ToRegister.LineNumber                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	&Period                                     AS Period,
	|	&Organization                                AS Organization,
	|	ToRegister.PrincipalProductAnalysis AS ItemsLocationAttributes,
	|	ToRegister.Terms                      AS Terms,
	|	ToRegister.Currency                          AS Currency,
	|	-ToRegister.Count                      AS Count,
	|	-ToRegister.AmountIncludingVAT 
	|		* ExchangeRates.ConversionFactor_       AS RevenueAmount,
	|	-ToRegister.VATAmount 
	|		* ExchangeRates.ConversionFactor_       AS VATAmount,
	|	CASE
	|		WHEN ISNULL(ToRegister.Terms.RevalueServicesForConsignmentNotification, FALSE)
	|			THEN -ToRegister.AmountIncludingVATCompl
	|		ELSE 0
	|	END AS RevenueAmountExclVATLocal,
	|	CASE
	|		WHEN ISNULL(ToRegister.Terms.RevalueServicesForConsignmentNotification, FALSE)
	|			THEN -ToRegister.AmountIncludingVATMan
	|		ELSE 0
	|	END AS RevenueAmountMan,
	|
	|	ToRegister.DocumentSalesOfGoodsAndServices              AS DocumentSalesOfGoodsAndServices,	
	|	
	|	ToRegister.RowID            AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale) AS BusinessTransactionSetting,
	|	ToRegister.RowID AS RowID
	|FROM
	|	TTOperationServices AS ToRegister
	|
	|	LEFT JOIN TTExchangeRates AS ExchangeRates
	|	ON ToRegister.Currency = ExchangeRates.Currency
	|WHERE
	|	ToRegister.PrincipalProductAnalysis <> UNDEFINED
	|	AND ToRegister.ByCorrectionReceipt
	|	
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCashCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAmountByPaymentCardsByCashFlowArticles",
		                                            QueryTexts,
		                                            Query.TempTablesManager) Then
		CreateTTAmountByPaymentCardsInContextOfCashFlowArticles(Query);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAmountByPaymentCards", QueryTexts) Then
		QueryTextTTAmountByPaymentCards(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCashFlowArticles", QueryTexts) Then
		QueryTextTTCashFlowArticles(QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTVATAmountsByCashFlowArticles",
		                                            QueryTexts,
		                                            Query.TempTablesManager) Then
		CreateTTVATAmountsByCashFlowArticles(Query);
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);

	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|
	|	DocumentData.CashRegister AS Cash,
	|	VALUE(Enum.CashTypes.CashPayment) AS CashType,
	|	CASE
	|		WHEN ISNULL(TTAmountByPaymentCards.CashFlowItem, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|			THEN VALUE(Catalog.CashFlowReportItems.CashReceiptFromCustomer)
	|		ELSE TTAmountByPaymentCards.CashFlowItem
	|	END AS CashFlowItem,
	|	DocumentData.Currency AS PaymentCurrency,
	|
	|	VALUE(Catalog.Partners.RetailCustomer) AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|	
	|	-CAST((DocumentData.DocumentAmount 
	|			- ISNULL(TTAmountByPaymentCards.Sum, 0))
	|			 * &ConversionRateToManCurrency AS NUMBER(31,2)) AS PayAmount,
	|	-CAST((DocumentData.DocumentAmount
	|			- ISNULL(TTAmountByPaymentCards.Sum, 0))
	|			 * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS PaymentAmountLocal,
	|	-(DocumentData.DocumentAmount
	|		- ISNULL(TTAmountByPaymentCards.Sum, 0)) AS PaymentAmountPaymentCurrency,
	|
	|	0 AS PostpaymentAmount,
	|	0 AS PostpaymentAmountLocal,
	|	0 AS PaymentAmountInPaymentCurrency,
	|	
	|	0 AS PrepaymentAmountMan,
	|	0 AS PrepaymentAmountLocal,
	|	0 AS PrepaymentAmount,
	|
	|	0 AS VATAmount,
	|	0 AS VATAmountCompl,
	|	0 AS AmountVATCurrencyPayment,
	|
	|	DocumentData.Currency AS ARAPCurrency,
	|
	|	-(DocumentData.DocumentAmount
	|		- ISNULL(TTAmountByPaymentCards.Sum, 0)) AS PaymentAmountInTheSettlementCurrency,
	|	0 AS PostPaymentAmountInARAPCurrency,
	|	0 AS PrepaymentAmountInARAPCurrency,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	UNDEFINED AS VATRate
	|FROM
	|	Document.RetailReturnsReport AS DocumentData
	|		LEFT JOIN TTAmountByPaymentCardsByCashFlowArticles AS TTAmountByPaymentCards
	|		ON (TRUE)
	|		LEFT JOIN TTAmountByPaymentCards AS TTAmountByPaymentCardsControl
	|		ON (TRUE)
	|WHERE
	|	DocumentData.DocumentAmount 
	|		- ISNULL(TTAmountByPaymentCardsControl.Sum, 0) <> 0
	|	AND DocumentData.Ref = &Ref
	|	AND &FullImplementation
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|
	|	CASE
	|		WHEN TablePaymentByPaymentCards.PaymentKind_ = VALUE(Enum.TypesOfCashRegisterPaymentSystem.InstantPayments)
	|			THEN TablePaymentByPaymentCards.ConnectionContract
	|		ELSE TablePaymentByPaymentCards.POSTerminal.Owner
	|	END AS Cash,
	|
	|	VALUE(Enum.CashTypes.BankAcquirerCash) AS CashType,
	|	CFItems.CashFlowItem                              AS CashFlowItem,
	|	DocumentData.Currency AS PaymentCurrency,
	|
	|	VALUE(Catalog.Partners.RetailCustomer) AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|	
	|	CAST(TablePaymentByPaymentCards.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS PayAmount,
	|	CAST(TablePaymentByPaymentCards.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS PaymentAmountLocal,
	|	TablePaymentByPaymentCards.Sum AS PaymentAmountPaymentCurrency,
	|
	|	0 AS PostpaymentAmount,
	|	0 AS PostpaymentAmountLocal,
	|	0 AS PaymentAmountInPaymentCurrency,
	|	
	|	0 AS PrepaymentAmountMan,
	|	0 AS PrepaymentAmountLocal,
	|	0 AS PrepaymentAmount,
	|
	|	0 AS VATAmount,
	|	0 AS VATAmountCompl,
	|	0 AS AmountVATCurrencyPayment,
	|
	|	DocumentData.Currency AS ARAPCurrency,
	|
	|	TablePaymentByPaymentCards.Sum AS PaymentAmountInTheSettlementCurrency,
	|	0 AS PostPaymentAmountInARAPCurrency,
	|	0 AS PrepaymentAmountInARAPCurrency,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	UNDEFINED AS VATRate
	|FROM
	|	Document.RetailReturnsReport AS DocumentData
	|	INNER JOIN
	|	Document.RetailReturnsReport.PaymentWithPaymentCards AS TablePaymentByPaymentCards
	|	ON	DocumentData.Ref = TablePaymentByPaymentCards.Ref
	|	LEFT JOIN TTCashFlowArticles AS CFItems
	|	ON TablePaymentByPaymentCards.LineNumber = CFItems.LineNumber
	|	AND CFItems.Return
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &FullImplementation
	|
	|UNION ALL
	|
	|SELECT // VAT
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|
	|	DocumentData.CashRegister AS Cash,
	|	ISNULL(GoodsTable.CashType, VALUE(Enum.CashTypes.CashPayment)) AS CashType,
	|	GoodsTable.CashFlowItem         AS CashFlowItem,
	|	DocumentData.Currency AS PaymentCurrency,
	|
	|	VALUE(Catalog.Partners.RetailCustomer) AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|	
	|	0 AS PayAmount,
	|	0 AS PaymentAmountLocal,
	|	0 AS PaymentAmountPaymentCurrency,
	|
	|	0 AS PostpaymentAmount,
	|	0 AS PostpaymentAmountLocal,
	|	0 AS PaymentAmountInPaymentCurrency,
	|	
	|	0 AS PrepaymentAmountMan,
	|	0 AS PrepaymentAmountLocal,
	|	0 AS PrepaymentAmount,
	|
	|	-SUM(GoodsTable.VATAmount * &ConversionRateToManCurrency) AS VATAmount,
	|	-SUM(GoodsTable.VATAmount * &FactorOfConversionToCurrencyOfRegul) AS VATAmountCompl,
	|	-SUM(GoodsTable.VATAmount) AS AmountVATCurrencyPayment,
	|
	|	DocumentData.Currency AS ARAPCurrency,
	|
	|	0 AS PaymentAmountInTheSettlementCurrency,
	|	0 AS PostPaymentAmountInARAPCurrency,
	|	0 AS PrepaymentAmountInARAPCurrency,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	GoodsTable.VATRate
	|FROM
	|	Document.RetailReturnsReport AS DocumentData
	|		LEFT JOIN TTVATAmountsByCashFlowArticles AS GoodsTable
	|		ON TRUE
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &FullImplementation
	|	AND NOT GoodsTable.VATRate IS NULL
	|GROUP BY
	|	DocumentData.Date,
	|	DocumentData.Organization,
	|	DocumentData.Department,
	|	DocumentData.CashRegister,
	|	DocumentData.Currency,
	|	GoodsTable.VATRate,
	|	GoodsTable.CashFlowItem,
	|	ISNULL(GoodsTable.CashType, VALUE(Enum.CashTypes.CashPayment))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashInTransit(Query, QueryTexts, Registers)
	
	RegisterName = "CashInTransit";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCashFlowArticles", QueryTexts) Then
		QueryTextTTCashFlowArticles(QueryTexts);
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText = "
	|SELECT
	|	PaymentTable_3.LineNumber                                                          AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)                                               AS RecordType,
	|	&Period                                                                              AS Period,
	|
	|	&Organization                                                                         AS Organization,
	|	CASE
	|		WHEN NOT PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract.BankAccount
	|		ELSE PaymentTable_3.POSTerminal.Owner.BankAccount
	|	END                                                                                AS Recipient,
	|	VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)   AS CashTransferKind,
	|	CASE
	|		WHEN NOT PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract.Counterparty
	|		ELSE PaymentTable_3.POSTerminal.Owner.Counterparty
	|	END                                                                                AS Counterparty,
	|	CASE
	|		WHEN NOT PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract
	|		ELSE PaymentTable_3.POSTerminal.Owner
	|	END                                                                                AS Contract,
	|	UNDEFINED                                                                         AS PaymentDocument,
	|	&Currency                                                                              AS Currency,
	|
	|	PaymentTable_3.Sum                                                               AS Sum,
	|	PaymentTable_3.Sum * &ConversionRateToManCurrency                             AS SumMan,
	|	PaymentTable_3.Sum * &FactorOfConversionToCurrencyOfRegul                            AS SumCompl,
	|
	|	VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard)    AS BusinessOperation,
	|	CFItems.CashFlowItem                                              AS CashFlowItem,
	|	
	|	PaymentTable_3.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RefundToCustomerSPaymentCard) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RetailReturnsReport.PaymentWithPaymentCards AS PaymentTable_3
	|		LEFT JOIN TTCashFlowArticles AS CFItems
	|		ON PaymentTable_3.LineNumber = CFItems.LineNumber
	|		AND CFItems.Return
	|
	|WHERE
	|	&FullImplementation
	|	AND PaymentTable_3.Ref = &Ref
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTCashFlowArticles(QueryTexts)
	
	RegisterName = "TTCashFlowArticles";
	
	QueryText = 
	"SELECT
	|	TRUE AS Return,
	|	PaymentTable_3.LineNumber AS LineNumber,
	|	CASE
	|		WHEN NOT ISNULL(InformationAboutContract.CashFlowItemReturn,
	|						  VALUE(Catalog.CashFlowReportItems.EmptyRef))
	|							= VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|	
	|			THEN InformationAboutContract.CashFlowItemReturn
	|
	|		WHEN NOT ISNULL(InformationAboutContractForTerminal.CashFlowItemReturn,
	|						  VALUE(Catalog.CashFlowReportItems.EmptyRef))
	|							= VALUE(Catalog.CashFlowReportItems.EmptyRef)
	
	|			THEN InformationAboutContractForTerminal.CashFlowItemReturn
	|
	|		ELSE VALUE(Catalog.CashFlowReportItems.RefundToCustomer)
	|	END AS CashFlowItem
	|INTO TTCashFlowArticles
	|FROM
	|	Document.RetailReturnsReport.PaymentWithPaymentCards AS PaymentTable_3
	|		LEFT JOIN Catalog.AcquiringContracts AS InformationAboutContract
	|		ON PaymentTable_3.ConnectionContract = InformationAboutContract.Ref
	|		LEFT JOIN Catalog.AcquiringContracts AS InformationAboutContractForTerminal
	|		ON PaymentTable_3.POSTerminal.Owner = InformationAboutContractForTerminal.Ref
	|WHERE
	|	PaymentTable_3.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	FALSE,
	|	PaymentTable_3.LineNumber,
	|	CASE
	|		WHEN NOT ISNULL(InformationAboutContract.CashFlowItemCashReceipt,
	|						  VALUE(Catalog.CashFlowReportItems.EmptyRef))
	|							= VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|
	|			THEN InformationAboutContract.CashFlowItemCashReceipt
	|
	|		WHEN NOT ISNULL(InformationAboutContractForTerminal.CashFlowItemCashReceipt,
	|						  VALUE(Catalog.CashFlowReportItems.EmptyRef))
	|							= VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|
	|			THEN InformationAboutContractForTerminal.CashFlowItemCashReceipt
	|
	|		ELSE VALUE(Catalog.CashFlowReportItems.RefundToCustomer)
	|	END
	|FROM
	|	Document.RetailReturnsReport.PaymentWithPaymentCards AS PaymentTable_3
	|		LEFT JOIN Catalog.AcquiringContracts AS InformationAboutContract
	|		ON PaymentTable_3.ConnectionContract = InformationAboutContract.Ref
	|		LEFT JOIN Catalog.AcquiringContracts AS InformationAboutContractForTerminal
	|		ON PaymentTable_3.POSTerminal.Owner = InformationAboutContractForTerminal.Ref
	|WHERE
	|	PaymentTable_3.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryTexts;
	
EndFunction

Procedure CreateTTAmountByPaymentCardsInContextOfCashFlowArticles(Query)
	
	Query.Text = 
	"SELECT
	|	CASE
	|		WHEN ISNULL(AcquiringContracts.CashFlowItemCashReceipt,
	|					   VALUE(Catalog.CashFlowReportItems.EmptyRef))
	|						= VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|
	|			THEN ISNULL(InformationAboutContractForTerminal.CashFlowItemCashReceipt,
	|						   VALUE(Catalog.CashFlowReportItems.CashReceiptFromCustomer))
	|
	|		ELSE AcquiringContracts.CashFlowItemCashReceipt
	|	END AS CashFlowItem,
	|	SUM(TabularSection.Sum) AS Sum
	|INTO TTAmountByPaymentCardsByCashFlowArticles
	|FROM
	|	Document.RetailReturnsReport.PaymentWithPaymentCards AS TabularSection
	|		LEFT JOIN Catalog.AcquiringContracts AS AcquiringContracts
	|		ON TabularSection.ConnectionContract = AcquiringContracts.Ref
	|		LEFT JOIN Catalog.AcquiringContracts AS InformationAboutContractForTerminal
	|		ON TabularSection.POSTerminal.Owner = InformationAboutContractForTerminal.Ref
	|WHERE
	|	TabularSection.Ref = &Ref
	|
	|GROUP BY
	|	CASE
	|		WHEN ISNULL(AcquiringContracts.CashFlowItemCashReceipt,
	|					   VALUE(Catalog.CashFlowReportItems.EmptyRef))
	|						= VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|			
	|			THEN ISNULL(InformationAboutContractForTerminal.CashFlowItemCashReceipt,
	|						   VALUE(Catalog.CashFlowReportItems.CashReceiptFromCustomer))
	|
	|		ELSE AcquiringContracts.CashFlowItemCashReceipt
	|	END";
	
	Query.Execute();
	
EndProcedure

Procedure CreateTTVATAmountsByCashFlowArticles(Query)
	
	QueryTexts = New ValueList;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAmountByPaymentCardsByCashFlowArticles",
		                                            QueryTexts,
		                                            Query.TempTablesManager) Then
		CreateTTAmountByPaymentCardsInContextOfCashFlowArticles(Query);
	EndIf;
	
	QueryTextVATRates = 
	"SELECT
	|	CASE
	|		WHEN SUM(DocumentAmounts.TotalAmount_1) = 0
	|			THEN 0
	|		ELSE SUM(DocumentAmounts.AmountOfNonCash) / SUM(DocumentAmounts.TotalAmount_1)
	|	END AS NonCashPaymentRatio,
	|	SUM(DocumentAmounts.AmountOfNonCash) AS AmountOfNonCash
	|FROM
	|	(SELECT
	|		PaymentWithPaymentCards.Sum AS AmountOfNonCash,
	|		0 AS TotalAmount_1
	|	FROM
	|		Document.RetailReturnsReport.PaymentWithPaymentCards AS PaymentWithPaymentCards
	|	WHERE
	|		PaymentWithPaymentCards.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		0,
	|		ReportOnRetailSalesOfGoods.Sum
	|	FROM
	|		Document.RetailReturnsReport.Goods AS ReportOnRetailSalesOfGoods
	|	WHERE
	|		ReportOnRetailSalesOfGoods.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		0,
	|		ISNULL(ReportOnRetailSalesOfGoods.VATAmount, 0)
	|	FROM
	|		Document.RetailReturnsReport AS DocumentData
	|			LEFT JOIN Document.RetailReturnsReport.Goods AS ReportOnRetailSalesOfGoods
	|			ON DocumentData.Ref = ReportOnRetailSalesOfGoods.Ref
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND NOT DocumentData.PriceIncludesVAT) AS DocumentAmounts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN GoodsTable.VATRate.Rate1 > 0
	|				AND GoodsTable.VATRate.CalculatedRate = TRUE
	|			THEN GoodsTable.VATRate.RelevantBaseRate
	|		ELSE GoodsTable.VATRate
	|	END AS VATRate,
	|	SUM(GoodsTable.VATAmount) AS VATAmount
	|FROM
	|	Document.RetailReturnsReport.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.VATRate.Rate1 > 0
	|
	|GROUP BY
	|	CASE
	|		WHEN GoodsTable.VATRate.Rate1 > 0
	|				AND GoodsTable.VATRate.CalculatedRate = TRUE
	|			THEN GoodsTable.VATRate.RelevantBaseRate
	|		ELSE GoodsTable.VATRate
	|	END";
	
	ArrayOfTexts = New Array;
	ArrayOfTexts.Add(QueryTextVATRates);
	Query.Text = StrConcat(ArrayOfTexts, Common.QueryBatchSeparator());
	
	DataForDistribution = Query.ExecuteBatch();
	SelectionBankAccountPayments = DataForDistribution[0].Select();
	DescriptionOfNonCashCashCoefficient = New Structure("NonCashPaymentRatio,AmountOfNonCash",0,0);
	If SelectionBankAccountPayments.Next() Then
		FillPropertyValues(DescriptionOfNonCashCashCoefficient, SelectionBankAccountPayments);
	EndIf;
	
	VATAmounts  = DataForDistribution[1].Unload();
	CFItems =
		Query.TempTablesManager.Tables.Find("TTAmountByPaymentCardsByCashFlowArticles").GetData().Unload();
	
	TableForAllocation = CFItems.CopyColumns();
	TableForAllocation.Columns.Add("VATRate", VATAmounts.Columns.VATRate.ValueType);
	TableForAllocation.Columns.Add("CashType",
		                                     New TypeDescription("EnumRef.CashTypes"));
	
	// The error falls on cash, and if there is none, then a non-cash line is added, which will take into account the error.
	// In the absence of cash shows the coefficient of payment by cashless = 1
	For Each LineOfVATAmounts In VATAmounts Do
		
		DistributableVATAmount = LineOfVATAmounts.VATAmount;
		If DescriptionOfNonCashCashCoefficient.AmountOfNonCash <> 0 Then
			
			For Each CFItemsRow In CFItems Do
				
				AllocationResult = LineOfVATAmounts.VATAmount *
				                            DescriptionOfNonCashCashCoefficient.NonCashPaymentRatio *
				                            (CFItemsRow.Sum / DescriptionOfNonCashCashCoefficient.AmountOfNonCash);
				
				If AllocationResult = 0 Then
					Continue;
				EndIf;
				
				LineOfNonCashPayments           = TableForAllocation.Add();
				LineOfNonCashPayments.VATRate = LineOfVATAmounts.VATRate;
				LineOfNonCashPayments.CashFlowItem = CFItemsRow.CashFlowItem;
				LineOfNonCashPayments.CashType =
					PredefinedValue("Enum.CashTypes.BankAcquirerCash");
				
				LineOfNonCashPayments.Sum = AllocationResult;
				DistributableVATAmount = DistributableVATAmount - AllocationResult;
				
			EndDo;
		
		EndIf;
		
		If DistributableVATAmount <> 0 Then
		
			If DescriptionOfNonCashCashCoefficient.NonCashPaymentRatio = 1 Then
				
				LineOfNonCashPayments = TableForAllocation.Add();
				LineOfNonCashPayments.VATRate   = LineOfVATAmounts.VATRate;
				LineOfNonCashPayments.Sum       = DistributableVATAmount;
				LineOfNonCashPayments.CashFlowItem = CFItemsRow.CashFlowItem;
				LineOfNonCashPayments.CashType =
					PredefinedValue("Enum.CashTypes.BankAcquirerCash");
				
			Else
				
				CashLine           = TableForAllocation.Add();
				CashLine.VATRate = LineOfVATAmounts.VATRate;
				CashLine.Sum     = DistributableVATAmount;
				CashLine.CashFlowItem = 
					PredefinedValue("Catalog.CashFlowReportItems.CashReceiptFromCustomer");
				CashLine.CashType = 
					PredefinedValue("Enum.CashTypes.CashPayment");
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	TableForAllocation.GroupBy("VATRate,CashFlowItem,CashType", "Sum");
	Query.SetParameter("TableForAllocation", TableForAllocation);
	
	Query.Text = 
	"SELECT
	|	DistributedData.CashFlowItem AS CashFlowItem,
	|	DistributedData.CashType AS CashType,
	|	DistributedData.VATRate AS VATRate,
	|	DistributedData.Sum AS VATAmount
	|INTO TTVATAmountsByCashFlowArticles
	|FROM
	|	&TableForAllocation AS DistributedData";
	
	Query.Execute();
	
EndProcedure

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	LineNumberText = CostCalculationDocumentsPosting.RequestTextStringCodesForBatchAccountingAnalytics(
		Metadata.Documents.RetailReturnsReport.Name,
		"Goods, InventoryKinds");
	
	TextSelectionOfAnalystField = LineNumberText + "
	|SELECT
	|	""InventoryKinds"" 							AS TabularSectionName,
	|	DocumentTable.LineNumber 				AS LineNumber,
	|	VALUE(Catalog.Partners.RetailCustomer)		AS Vendor,
	|	VALUE(Catalog.Counterparties.RetailCustomer)	AS Counterparty,
	|	DocumentTable.VATRate 					AS VATRate,
	|	CASE
	|		WHEN DocumentTable.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		 AND DocumentData.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE DocumentData.VATTaxation
	|	END AS VATTaxation,
	|	ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	LineCodes.RowCode							AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.RetailReturnsReport.InventoryKinds AS DocumentTable
	|	INNER JOIN Document.RetailReturnsReport AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""InventoryKinds""
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
	|		ON DocumentTable.ItemsLocationAttributes = DimensionOfProductItem.Ref
	|	INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = DimensionOfProductItem.Products
	|	LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON CatProducts.FinancialAccountingGroup = FAG.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	""Goods"" 									AS TabularSectionName,
	|	DocumentTable.LineNumber 				AS LineNumber,
	|	VALUE(Catalog.Partners.RetailCustomer)		AS Vendor,
	|	VALUE(Catalog.Counterparties.RetailCustomer)	AS Counterparty,
	|	DocumentTable.VATRate 					AS VATRate,
	|	CASE
	|		WHEN DocumentTable.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		 AND DocumentData.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE DocumentData.VATTaxation
	|	END AS VATTaxation,
	|	ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	LineCodes.RowCode							AS RowCode
	|FROM
	|	Document.RetailReturnsReport.Goods AS DocumentTable
	|	INNER JOIN Document.RetailReturnsReport AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""Goods""
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
	|		ON DocumentTable.ItemsLocationAttributes = DimensionOfProductItem.Ref
	|	INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = DimensionOfProductItem.Products
	|	LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON CatProducts.FinancialAccountingGroup = FAG.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND DocumentTable.ItemsLocationAttributes NOT IN
	|		(SELECT DISTINCT
	|			InventoryKinds.ItemsLocationAttributes
	|		FROM
	|			Document.RetailReturnsReport.InventoryKinds AS InventoryKinds
	|		WHERE
	|			InventoryKinds.Ref = &Ref)
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTypesOfStocks(Query, QueryTexts) Export
	
	RegisterName = "TTTypesOfStocks";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	InitializeProductAccountingAnalyticsKeys(Query);
		
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                                   AS LineNumber,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                                    AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner                AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Currency                             AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType                         AS InventoryType,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products                                           AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic                                         AS Characteristic,
	|	TableTypesOfStocks_.ItemsLocationAttributes                    AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness               		 AS LineOfBusiness,
	|	TableTypesOfStocks_.SetAccountingDimension                         AS SetAccountingDimension,
	|	CommitteeAnalytics.DimensionKey                                 AS CommitteeProductAnalysis,
	|	TableTypesOfStocks_.ItemsLocationAttributesShipment            AS DimensionSalesOfGoodsAndServices,
	|	RegisterAccountingAnalyticsForPartners.DimensionKey                   AS AccountingDimensionByPartners,
	
	|	TableOfBatchAccountingAnalysts.AssetTaxClass								AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation						AS VATTaxation,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes 					AS LotVendorAttributes,
	
	|	ISNULL(TableTypesOfStocks_.DocumentSalesOfGoodsAndServices.Department, &Department) AS ImplementationDivision,
	|	ISNULL(TableTypesOfStocks_.DocumentSalesOfGoodsAndServices.VATTaxation, &VATTaxation) AS VATTaxationOfSales,
	|	TableTypesOfStocks_.CCDNumber                                      AS CCDNumber,
	|	TableTypesOfStocks_.Count                                    AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN                              AS QuantityByGBRN,
	
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)                                  AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)                                AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)                               AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)                                 AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.VATBaseLocal, 0)                                   AS VATBaseLocal,
	|	ISNULL(Amounts.VATAmountCompl, 0)                                  AS VATAmountCompl,
	
	|	TableTypesOfStocks_.AmountIncludingVAT                                     AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount                                      AS VATAmount,
	|	TableTypesOfStocks_.ManualDiscount                             AS ManualDiscount,
	|	TableTypesOfStocks_.VATRate                                     AS VATRate,
	|	TableTypesOfStocks_.Seller                                      AS Seller,
	|	TableTypesOfStocks_.Partner                                       AS Partner,
	|	TableTypesOfStocks_.RowID                           AS RowID,
	|	TableTypesOfStocks_.ByCorrectionReceipt                            	 AS ByCorrectionReceipt,
	|	TableTypesOfStocks_.CostDefiningMethod                AS CostDefiningMethod,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation                        AS Warehouse,
	|	TableTypesOfStocks_.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom  AS ShopFloorStockroom,
	|	TableTypesOfStocks_.InventoryOwnerAttributeShipment                            AS InventoryOwnerAttributeShipment,
	|	(CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|		ELSE UNDEFINED END)                   AS DocumentSalesOfGoodsAndServices,
	|	(CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN TableTypesOfStocks_.DocumentSalesOfGoodsAndServices.Date
	|		ELSE DATETIME(1,1,1) END)                AS SalePeriod,	
	|	(CASE
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|			THEN &EmployeeResponsible
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END) AS FinancialAccountingDimension,
	|	CASE
	// we do not support the return of past periods in retail
	|		WHEN TableTypesOfStocks_.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
	|	END AS BusinessTransactionSetting,
	|	CASE
	|		WHEN TableTypesOfStocks_.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS TraceableWork
	|
	|INTO TTTypesOfStocks
	|FROM
	|	Document.RetailReturnsReport.InventoryKinds AS TableTypesOfStocks_
	|	LEFT JOIN
	|		Catalog.InventoryKinds AS TypesOfCommitteesReserves
	|	ON
	|		TableTypesOfStocks_.InventoryOwnerAttribute = TypesOfCommitteesReserves.Ref
	|		AND TypesOfCommitteesReserves.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|	LEFT JOIN
	|		Catalog.InventoryKinds AS TypesOfOwnersStocks
	|	ON
	|		TypesOfCommitteesReserves.InventoryOwnerAttributeOfCompanyGoodsOwner = TypesOfOwnersStocks.Ref
	|		AND TypesOfOwnersStocks.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS CommitteeAnalytics
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = CommitteeAnalytics.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = CommitteeAnalytics.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = CommitteeAnalytics.Purpose
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeAnalytics.Series
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner = CommitteeAnalytics.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeAnalytics.ProductCostElement
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= TableTypesOfStocks_.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	
	|	LEFT JOIN 
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		TableTypesOfStocks_.Ref = Amounts.Ref
	|		AND TableTypesOfStocks_.RowID = Amounts.RowID
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|	ON
	|		RegisterAccountingAnalyticsForPartners.Organization = &Organization
	|		AND RegisterAccountingAnalyticsForPartners.Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|		AND TableTypesOfStocks_.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|		AND RegisterAccountingAnalyticsForPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		AND RegisterAccountingAnalyticsForPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)	
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTAgencyServices(Query, QueryTexts)
	
	RegisterName = "TTAgencyServices";
	
	QueryText = "
	|SELECT DISTINCT
	|	CASE WHEN NOT Services.Ref IS NULL
	|			THEN Services.Ref
	|		WHEN NOT Terms.Ref IS NULL
	|			THEN Terms.Ref
	|		WHEN NOT ServicesAgreementClosed.Ref IS NULL
	|			THEN ServicesAgreementClosed.Ref
	|		ELSE ISNULL(AgreementClosed.Ref, UNDEFINED)
	|	END AS Terms,
	|	CASE WHEN NOT Services.Ref IS NULL
	|				THEN Services.Ref.Currency
	|		WHEN NOT Terms.Ref IS NULL
	|				THEN Terms.Currency
	|		WHEN NOT ServicesAgreementClosed.Ref IS NULL
	|				THEN ServicesAgreementClosed.Ref.Currency
	|		ELSE ISNULL(AgreementClosed.Currency, &Currency)
	|	END AS Currency,
	|	ToRegister.Products AS Products,
	|	ToRegister.Characteristic AS Characteristic,
	|	ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) AS Principal
	|INTO TTAgencyServices
	|FROM
	|	Document.RetailReturnsReport.Goods AS ToRegister
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS Terms
	|	ON Terms.Partner = ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal)
	|		AND Terms.Organization = &Organization
	|		AND Terms.BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|		AND Terms.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|		AND (&Period >= Terms.ValidityStartDate
	|			AND (&Period <= Terms.ValidityEndDate
	|			OR Terms.ValidityEndDate = DATETIME(1,1,1))
	|		)
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors.AgentServices AS Services
	|	ON Terms.Ref = Services.Ref
	|		AND ToRegister.Products = Services.Products
	|		AND ToRegister.Characteristic = Services.Characteristic
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS AgreementClosed
	|	ON AgreementClosed.Partner = ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal)
	|		AND AgreementClosed.Organization = &Organization
	|		AND AgreementClosed.BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|		AND AgreementClosed.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Closed)
	|		AND (&Period >= AgreementClosed.ValidityStartDate
	|			AND (&Period <= AgreementClosed.ValidityEndDate
	|			OR AgreementClosed.ValidityEndDate = DATETIME(1,1,1))
	|		)
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors.AgentServices AS ServicesAgreementClosed
	|	ON AgreementClosed.Ref = ServicesAgreementClosed.Ref
	|		AND ToRegister.Products = ServicesAgreementClosed.Products
	|		AND ToRegister.Characteristic = ServicesAgreementClosed.Characteristic
	|WHERE
	|	ToRegister.Ref = &Ref
	|	AND ToRegister.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|	AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) <> &Organization
	|	AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) <> UNDEFINED
	|	AND &UseAgentServiceSale
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTOperationServices(Query, QueryTexts) Export
	
	RegisterName = "TTOperationServices";
			
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);	
	InitializeProductAccountingAnalyticsKeys(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAgencyServices", QueryTexts) Then
		QueryTextTTAgencyServices(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 

	QueryText = "
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.SetAccountingDimension AS SetAccountingDimension,
	|	GoodsTable.Seller AS Seller,
	|	GoodsTable.Products.ItemsType AS ItemsType,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Partner AS Partner,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|	RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)                                  AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)                                AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)                               AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)                                 AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.VATBaseLocal, 0)                                   AS VATBaseLocal,
	|	ISNULL(Amounts.VATAmountCompl, 0)                                  AS VATAmountCompl,
	
	|	(GoodsTable.Sum
	|		+ &PriceIncludesVAT * GoodsTable.VATAmount) AS AmountIncludingVAT,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.ManualDiscount AS ManualDiscount,
	|	GoodsTable.VATRate         AS VATRate,

	|	AgentServices.Terms AS Terms,
	|	AgentServices.Currency AS Currency,
	|	ISNULL(PrincipalKeys.DimensionKey, UNDEFINED) AS PrincipalProductAnalysis,
	|	ISNULL(AgentServices.Principal, UNDEFINED) AS Principal,
	|	UNDEFINED AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|			THEN &EmployeeResponsible
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END) AS FinancialAccountingDimension,
	|	
	|	GoodsTable.RowID AS RowID,
	|	(CASE
	|		WHEN GoodsTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN GoodsTable.DocumentSalesOfGoodsAndServices
	|		ELSE UNDEFINED END)                   AS DocumentSalesOfGoodsAndServices,
	|	(CASE
	|		WHEN GoodsTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN GoodsTable.DocumentSalesOfGoodsAndServices.Date
	|		ELSE DATETIME(1,1,1) END)                AS SalePeriod,	
	|	GoodsTable.CostDefiningMethod AS CostDefiningMethod,
	|	ISNULL(GoodsTable.DocumentSalesOfGoodsAndServices.Department,	&Department) AS ImplementationDivision,
	|	ISNULL(GoodsTable.DocumentSalesOfGoodsAndServices.VATTaxation, &VATTaxation) AS VATTaxationOfSales,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass								AS AssetTaxClass,
	|	(CASE
	|		WHEN GoodsTable.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		 AND &VATTaxation IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT), 
	|				VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle))
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END) AS VATTaxation,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes 					AS LotVendorAttributes,	
	|	GoodsTable.ItemsLocationAttributes           			AS DimensionSalesOfGoodsAndServices,
	|	UNDEFINED					                            AS InventoryOwnerAttributeShipment,
	|	GoodsTable.ByCorrectionReceipt                            	AS ByCorrectionReceipt,
	|	CASE
	|		WHEN GoodsTable.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
	|	END AS BusinessTransactionSetting,
	|	CASE
	|		WHEN GoodsTable.Products.TracedGoods
	|				AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                       AS TraceableWork
	|
	|INTO TTOperationServices
	|FROM
	|	Document.RetailReturnsReport.Goods AS GoodsTable
	|	LEFT JOIN TTAgencyServices AS AgentServices
	|	ON GoodsTable.Products = AgentServices.Products
	|		AND GoodsTable.Characteristic = AgentServices.Characteristic
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS PrincipalKeys
	|	ON PrincipalKeys.Products = AgentServices.Products
	|		AND PrincipalKeys.Characteristic = AgentServices.Characteristic
	|		AND PrincipalKeys.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		AND PrincipalKeys.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND PrincipalKeys.StorageLocation = AgentServices.Principal
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = PrincipalKeys.ProductCostElement
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= GoodsTable.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	
	|	LEFT JOIN 
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		GoodsTable.Ref = Amounts.Ref
	|		AND GoodsTable.RowID = Amounts.RowID
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|	ON
	|		RegisterAccountingAnalyticsForPartners.Organization = &Organization
	|		AND RegisterAccountingAnalyticsForPartners.Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|		AND GoodsTable.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|		AND RegisterAccountingAnalyticsForPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		AND RegisterAccountingAnalyticsForPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)	
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OperationService),
	|		VALUE(Enum.ItemsTypes.Work_5)
	|	)
	|	AND GoodsTable.ItemsLocationAttributes NOT IN
	|		(SELECT DISTINCT
	|			InventoryKinds.ItemsLocationAttributes
	|		FROM
	|			Document.RetailReturnsReport.InventoryKinds AS InventoryKinds
	|		WHERE
	|			InventoryKinds.Ref = &Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	TableTypesOfStocks_.SetAccountingDimension AS SetAccountingDimension,
	|	TableTypesOfStocks_.Seller AS Seller,
	|	Dimension.Products.ItemsType AS ItemsType,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.Partner AS Partner,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)                                                 AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)                                               AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)                                              AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)                                                AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.VATBaseLocal, 0)                                                  AS VATBaseLocal,
	|	ISNULL(Amounts.VATAmountCompl, 0)                                                 AS VATAmountCompl,
	|
	|	TableTypesOfStocks_.AmountIncludingVAT                                                    AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount                                                     AS VATAmount,
	|	(TableTypesOfStocks_.AmountIncludingVAT - &PriceIncludesVAT * TableTypesOfStocks_.VATAmount) AS Sum,
	|	TableTypesOfStocks_.ManualDiscount                                            AS ManualDiscount,
	|	TableTypesOfStocks_.VATRate                                                    AS VATRate,
	|
	|	UNDEFINED                  AS Terms,
	|	UNDEFINED                  AS Currency,
	|	UNDEFINED                  AS PrincipalProductAnalysis,
	|	UNDEFINED                  AS Principal,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|			THEN &EmployeeResponsible
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END)                        AS FinancialAccountingDimension,
	|
	|	TableTypesOfStocks_.RowID                        AS RowID,
	|	(CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|		ELSE UNDEFINED END)                                 AS DocumentSalesOfGoodsAndServices,
	|	(CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN TableTypesOfStocks_.DocumentSalesOfGoodsAndServices.Date
	|		ELSE DATETIME(1,1,1) END)                             AS SalePeriod,
	|	TableTypesOfStocks_.CostDefiningMethod             AS CostDefiningMethod,
	|	ISNULL(
	|		TableTypesOfStocks_.DocumentSalesOfGoodsAndServices.Department,
	|		&Department)                                           AS ImplementationDivision,
	|	ISNULL(
	|		TableTypesOfStocks_.DocumentSalesOfGoodsAndServices.VATTaxation,
	|		&VATTaxation)                                      AS VATTaxationOfSales,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass                        AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation                 AS VATTaxation,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes               AS LotVendorAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributes                 AS DimensionSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.InventoryOwnerAttributeShipment                         AS InventoryOwnerAttributeShipment,
	|	TableTypesOfStocks_.ByCorrectionReceipt                            AS ByCorrectionReceipt,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
	|	END                                                         AS BusinessTransactionSetting,
	|	TRUE                                                        AS TraceableWork
	|
	|FROM
	|	Document.RetailReturnsReport.InventoryKinds AS TableTypesOfStocks_
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= TableTypesOfStocks_.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		TableTypesOfStocks_.Ref = Amounts.Ref
	|		AND TableTypesOfStocks_.RowID = Amounts.RowID
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|	ON
	|		RegisterAccountingAnalyticsForPartners.Organization = &Organization
	|		AND RegisterAccountingAnalyticsForPartners.Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|		AND TableTypesOfStocks_.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|		AND RegisterAccountingAnalyticsForPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		AND RegisterAccountingAnalyticsForPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTAmountByPaymentCards(Query, QueryTexts) Export
	
	RegisterName = "TTAmountByPaymentCards";
	
	QueryText = "
	|SELECT
	|	SUM(TabularSection.Sum) AS Sum
	|INTO TTAmountByPaymentCards
	|FROM
	|	Document.RetailReturnsReport.PaymentWithPaymentCards AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBonusPoints(Query, QueryTexts)
	
	RegisterName = "TTBonusPoints";
	
	QueryText = "SELECT
	|	TabularSection.AccrualDate AS Period,
	|	CASE
	|		WHEN BEGINOFPERIOD(TabularSection.DateOfDeduction,
	|			DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN TabularSection.AccrualDate
	|		ELSE DATETIME(1, 1, 1)
	|	END AS ValidityStartDate,
	|	CASE
	|		WHEN BEGINOFPERIOD(TabularSection.DateOfDeduction,
	|			DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN &CurrentDate
	|		ELSE DATETIME(1, 1, 1)
	|	END AS DateToProcess,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	TabularSection.Partner AS Partner,
	|	TabularSection.LoyaltyProgram AS LoyaltyProgram,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN -TabularSection.AmountOfBonusPoints
	|		ELSE TabularSection.AmountOfBonusPoints
	|	END AS Accrued,
	|	0 AS ToWriteOff
	|INTO TTBonusPoints
	|FROM
	|	Document.RetailReturnsReport.BonusPointAccrual AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND &FullImplementation
	|	AND TabularSection.AccrualDate <> DATETIME(1, 1, 1)
	|
	|UNION ALL
	|
	|SELECT
	|	TabularSection.DateOfDeduction,
	|	CASE
	|		WHEN BEGINOFPERIOD(TabularSection.DateOfDeduction,
	|			DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN TabularSection.AccrualDate
	|		ELSE DATETIME(1, 1, 1)
	|	END,
	|	CASE
	|		WHEN BEGINOFPERIOD(TabularSection.DateOfDeduction,
	|			DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN &CurrentDate
	|		ELSE DATETIME(1, 1, 1)
	|	END,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END,
	|	TabularSection.Partner,
	|	TabularSection.LoyaltyProgram,
	|	0,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN -TabularSection.AmountOfBonusPoints
	|		ELSE TabularSection.AmountOfBonusPoints
	|	END
	|FROM
	|	Document.RetailReturnsReport.BonusPointAccrual AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND &FullImplementation
	|	AND TabularSection.DateOfDeduction <> DATETIME(1, 1, 1)
	|
	|UNION ALL
	|
	|SELECT
	|	TabularSection.PayDate,
	|	DATETIME(1, 1, 1),
	|	CASE
	|		WHEN BEGINOFPERIOD(TabularSection.PayDate, DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5,
	|			DAY)
	|			THEN &CurrentDate
	|		ELSE DATETIME(1, 1, 1)
	|	END,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TabularSection.Partner,
	|	TabularSection.LoyaltyProgram,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN -TabularSection.AmountOfBonusPoints
	|		ELSE TabularSection.AmountOfBonusPoints
	|	END,
	|	CASE
	|		WHEN BEGINOFPERIOD(TabularSection.PayDate, DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5,
	|			DAY)
	|			THEN 0
	|		ELSE CASE
	|			WHEN TabularSection.AmountOfBonusPoints > 0
	|				THEN -TabularSection.AmountOfBonusPoints
	|			ELSE TabularSection.AmountOfBonusPoints
	|		END
	|	END
	|FROM
	|	Document.RetailReturnsReport.PaymentWithBonusPoints AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND &FullImplementation";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTAmountBonusPoints(Query, QueryTexts) Export
	
	RegisterName = "TTAmountBonusPoints";
	
	QueryText = "
	|SELECT
	|	SUM(TabularSection.AmountOfBonusPoints) AS Sum
	|INTO TTAmountBonusPoints
	|FROM
	|	Document.RetailReturnsReport.PaymentWithBonusPoints AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// Parameters:
//  Query - Query - 
//  QueryTexts - See RetailReturnsReportLocalization.AddRequestTexts.QueryTexts
//
// Returns:
//  String - query text.
//
Function QueryTextTTAmountOfCommissionsForAgencyServices(Query, QueryTexts) Export
	
	RegisterName = "TTAmountOfCommissionsForAgencyServices";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	SUM(NestedQuery.AmountIncludingVAT) AS Sum,
	|	SUM(NestedQuery.VATAmount) AS VATAmount
	|INTO TTAmountOfCommissionsForAgencyServices
	|FROM
	|	(
	|	SELECT
	|		SUM(TTOperationServices.AmountIncludingVAT) AS AmountIncludingVAT,
	|		SUM(TTOperationServices.VATAmount) AS VATAmount
	|	FROM TTOperationServices AS TTOperationServices
	|	WHERE TTOperationServices.Principal <> UNDEFINED
	|
	|	UNION ALL
	|
	|	SELECT
	|		SUM(TTTypesOfStocks.AmountIncludingVAT) AS AmountIncludingVAT,
	|		SUM(TTTypesOfStocks.VATAmountCompl) AS VATAmount
	|	FROM TTTypesOfStocks AS TTTypesOfStocks
	|	WHERE TTTypesOfStocks.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	) AS NestedQuery
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTExchangeRates(Query, QueryTexts)
	
	RegisterName = "TTExchangeRates";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAgencyServices", QueryTexts) Then
		QueryTextTTAgencyServices(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	ExchangeRates.Currency AS Currency,
	|
	|	(DocumentExchangeRate.CourseNumerator * ExchangeRates.CourseDenominator)
	|   / (DocumentExchangeRate.CourseDenominator * ExchangeRates.CourseNumerator) AS ConversionFactor_
	|
	|INTO TTExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Period,
	|		Currency IN (
	|			SELECT DISTINCT
	|				TableTypesOfStocks_.InventoryOwnerAttribute.Currency AS Currency
	|			FROM
	|				Document.RetailReturnsReport.InventoryKinds AS TableTypesOfStocks_
	|
	|			WHERE
	|				TableTypesOfStocks_.Ref = &Ref
	|				AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|			UNION
	|
	|			SELECT DISTINCT
	|				TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.Currency AS Currency
	|			FROM
	|				Document.RetailReturnsReport.InventoryKinds AS TableTypesOfStocks_
	|
	|			WHERE
	|				TableTypesOfStocks_.Ref = &Ref
	|				AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|			UNION
	|
	|			SELECT DISTINCT
	|				AgentServices.Currency AS Currency
	|			FROM
	|				TTAgencyServices AS AgentServices
	|			) AND BaseCurrency = &LocalAccountingCurrency
	|	) AS ExchangeRates
	|
	|	INNER JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Period, Currency = &Currency AND BaseCurrency = &LocalAccountingCurrency) AS DocumentExchangeRate
	|	ON
	|		TRUE
	|
	|WHERE
	|	DocumentExchangeRate.CourseDenominator <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.Currency,
	                                                                         Query.Parameters.Currency,
	                                                                         Query.Parameters.Period,
	                                                                         Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Procedure SetRequestParameterCorInventoryView(Query)
	
	If Query.Parameters.Property("CorInventoryOwnerAttribute") Then
		Return;
	EndIf;
	
	Query.SetParameter("CorInventoryOwnerAttribute",
		Catalogs.InventoryKinds.DocumentInventoryView(Query.Parameters.Organization, Query.Parameters.BusinessOperation,
			Undefined));
	
EndProcedure

Procedure InitializeTrackingAnalyticsKeysForPartners(Query)

	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized_") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query("
	|SELECT DISTINCT
	|	&Organization AS Organization,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	GoodsTable.Partner AS Partner,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
	|FROM (
	|	SELECT DISTINCT
	|		TableTypesOfStocks_.Partner AS Partner
	|	FROM
	|		Document.RetailReturnsReport.InventoryKinds AS TableTypesOfStocks_
	|	WHERE
	|		TableTypesOfStocks_.Ref = &Ref
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		GoodsTable.Partner AS Partner
	|	FROM
	|		Document.RetailReturnsReport.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))
	|
	|	) AS GoodsTable
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		Dimension.Organization = &Organization
	|		AND Dimension.Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|		AND GoodsTable.Partner = Dimension.Partner
	|		AND Dimension.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		AND Dimension.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	Dimension.DimensionKey IS NULL
	|");
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Organization", Query.Parameters.Organization);

	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("PartnerAccountingAnalyticsKeysInitialized_", True);
	
EndProcedure

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query("
	|SELECT DISTINCT
	|	GoodsTable.Products		AS Products,
	|	GoodsTable.Characteristic	AS Characteristic,
	|	GoodsTable.Purpose		AS Purpose,
	|	GoodsTable.Series				AS Series,
	|	GoodsTable.Warehouse				AS Warehouse
	|FROM
	|	(
	|		SELECT
	|			TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|			TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|			VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|			VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|			TypesOfCommitteesReserves.GoodsOwner AS Warehouse
	|		FROM
	|			Document.RetailReturnsReport.InventoryKinds AS TableTypesOfStocks_
	|			LEFT JOIN Catalog.InventoryKinds AS TypesOfCommitteesReserves
	|			ON TableTypesOfStocks_.InventoryOwnerAttribute = TypesOfCommitteesReserves.Ref
	|				AND TypesOfCommitteesReserves.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|			LEFT JOIN Catalog.InventoryKinds AS TypesOfOwnersStocks
	|			ON TypesOfCommitteesReserves.InventoryOwnerAttributeOfCompanyGoodsOwner = TypesOfOwnersStocks.Ref
	|				AND TypesOfOwnersStocks.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		WHERE
	|			TableTypesOfStocks_.Ref = &Ref
	|			AND TypesOfCommitteesReserves.GoodsOwner IS NOT NULL
	|
	|		UNION ALL
	|
	|		SELECT
	|			TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|			TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|			VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|			VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|			TypesOfOwnersStocks.GoodsOwner AS Warehouse
	|		FROM
	|			Document.RetailReturnsReport.InventoryKinds AS TableTypesOfStocks_
	|			LEFT JOIN Catalog.InventoryKinds AS TypesOfCommitteesReserves
	|			ON TableTypesOfStocks_.InventoryOwnerAttribute = TypesOfCommitteesReserves.Ref
	|				AND TypesOfCommitteesReserves.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|			LEFT JOIN Catalog.InventoryKinds AS TypesOfOwnersStocks
	|			ON TypesOfCommitteesReserves.InventoryOwnerAttributeOfCompanyGoodsOwner = TypesOfOwnersStocks.Ref
	|				AND TypesOfOwnersStocks.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		WHERE
	|			TableTypesOfStocks_.Ref = &Ref
	|			AND TypesOfOwnersStocks.GoodsOwner IS NOT NULL
	|
	|		UNION ALL
	|
	|		SELECT
	|			Services.Products AS Products,
	|			Services.Characteristic AS Characteristic,
	|			VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|			VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|			ISNULL(Services.Characteristic.Principal, Services.Products.Principal) AS Warehouse
	|		FROM
	|			Document.RetailReturnsReport.Goods AS Services
	|		WHERE
	|			Services.Ref = &Ref
	|			AND ISNULL(Services.Characteristic.Principal, Services.Products.Principal) <> UNDEFINED
	|			AND ISNULL(Services.Characteristic.Principal, Services.Products.Principal) <> &Organization
	|			AND Services.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|	) AS GoodsTable
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS CommitteeAnalytics
	|	ON GoodsTable.Products = CommitteeAnalytics.Products
	|		AND GoodsTable.Characteristic	= CommitteeAnalytics.Characteristic
	|		AND GoodsTable.Purpose = CommitteeAnalytics.Purpose
	|		AND GoodsTable.Series = CommitteeAnalytics.Series
	|		AND GoodsTable.Warehouse = CommitteeAnalytics.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeAnalytics.ProductCostElement
	|WHERE
	|	CommitteeAnalytics.DimensionKey IS NULL
	|");
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Organization", Query.Parameters.Organization);

	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	// Sets
	QueryAnalyst = New Query("
	|SELECT DISTINCT
	|	GoodsTable.ProductsInSet   AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet
	|
	|FROM
	|	(
	|	SELECT DISTINCT
	|		Dimension.ProductsInSet   AS ProductsInSet,
	|		Dimension.ItemVariantOfSet AS ItemVariantOfSet
	|	FROM
	|		Document.RetailReturnsReport.InventoryKinds AS TableTypesOfStocks_
	|
	|		LEFT JOIN
	|			InformationRegister.SetAccountingDimension AS Dimension
	|		ON
	|			TableTypesOfStocks_.SetAccountingDimension = Dimension.DimensionKey
	|
	|	WHERE
	|		TableTypesOfStocks_.Ref = &Ref
	|
	|	) AS GoodsTable
	|
	|	LEFT JOIN
	|		InformationRegister.SetAccountingDimension AS CommitteeAnalytics
	|	ON
	|		GoodsTable.ProductsInSet     = CommitteeAnalytics.ProductsInSet
	|		AND GoodsTable.ItemVariantOfSet = CommitteeAnalytics.ItemVariantOfSet
	|
	|WHERE
	|	CommitteeAnalytics.DimensionKey IS NULL
	|");
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);

	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.SetAccountingDimension.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	ValueText_ =
	"SELECT
	|	Services.Ref.Date AS Period,
	|	Services.Ref AS Ref,
	|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods) AS BusinessOperation,
	|	VALUE(Catalog.Counterparties.RetailCustomer) AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS Shipper,
	|	UNDEFINED AS GoodsRecipient,
	|	Services.Ref.Organization AS Organization,
	|	Services.Ref.Department AS Department,
	|	UNDEFINED AS ConsignedGoodsCustomer,
	|	FALSE AS SalesViaCommissionAgent,
	|	Services.Ref AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED AS ImplementationAdjustmentDocument,
	|	FALSE AS ErrorCorrection,
	|	FALSE AS AdjustmentUnderApprovalOfParties,
	|	TRUE AS RetailSaleOfGoods,
	|	UNDEFINED AS ARAPObject,
	|	Services.Ref.VATTaxation AS VATTaxation,
	|	Services.VATRate AS VATRate,
	|	Services.Products AS Products,
	|	Services.Characteristic AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,	
	|	Services.ProductsInSet AS ProductsInSet,
	|	Services.ItemVariantOfSet AS ItemVariantOfSet,
	|	"""" AS Content,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms OR Services.NumberOfPackages = 0
	|			THEN -Services.Count
	|		ELSE -Services.NumberOfPackages
	|	END AS Count,
	|	-Services.QuantityByGBRN AS QuantityByGBRN,	
	|	0 AS ExciseTaxAmount,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN Services.Products.UnitOfMeasure
	|		ELSE &QueryTextUnitOfMeasure
	|	END AS UnitOfMeasure,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	UNDEFINED AS FEACNCode,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	0 AS LineNumber,
	|	Services.RowID AS RowID,
	|	Services.RowID AS FinRecordID,
	|	CASE
	|		WHEN Services.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)
	|		WHEN Services.DocumentSalesOfGoodsAndServices.Date < &BeginningOfMonthOfPeriod
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
	|	END AS BusinessTransactionSetting
	|FROM
	|	Document.RetailReturnsReport.Goods AS Services
	|		LEFT JOIN Document.RetailReturnsReport.InventoryKinds AS InventoryKinds
	|		ON Services.Ref = InventoryKinds.Ref
	|			AND Services.ItemsLocationAttributes = InventoryKinds.ItemsLocationAttributes
	|WHERE
	|	Services.Ref IN (&Ref)
	|	AND Services.DocumentSalesOfGoodsAndServices <> VALUE(Document.RetailSalesReport.EmptyRef)
	|	AND Services.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OperationService),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|	AND InventoryKinds.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryKinds.Ref.Date AS Period,
	|	InventoryKinds.Ref AS Ref,
	|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods) AS BusinessOperation,
	|	VALUE(Catalog.Counterparties.RetailCustomer) AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS Shipper,
	|	UNDEFINED AS GoodsRecipient,
	|	InventoryKinds.Ref.Organization AS Organization,
	|	InventoryKinds.Ref.Department AS Department,
	|	UNDEFINED AS ConsignedGoodsCustomer,
	|	FALSE AS ReturnOfGoodsViaCommissionAgent,
	|	InventoryKinds.Ref AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED AS ImplementationAdjustmentDocument,
	|	FALSE AS ErrorCorrection,
	|	FALSE AS AdjustmentUnderApprovalOfParties,
	|	TRUE AS RetailSaleOfGoods,
	|	UNDEFINED AS ARAPObject,
	|	InventoryKinds.Ref.VATTaxation AS VATTaxation,
	|	InventoryKinds.VATRate AS VATRate,
	|	InventoryKinds.ItemsLocationAttributes.Products AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	InventoryKinds.ItemsLocationAttributes.Series AS Series,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
	|	InventoryKinds.SetAccountingDimension.ProductsInSet AS ProductsInSet,
	|	InventoryKinds.SetAccountingDimension.ItemVariantOfSet AS ItemVariantOfSet,
	|	"""" AS Content,
	|	-InventoryKinds.Count AS Count,
	|	-InventoryKinds.QuantityByGBRN AS QuantityByGBRN,	
	|	0 AS ExciseTaxAmount,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS UnitOfMeasure,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	UNDEFINED AS FEACNCode,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	0 AS LineNumber,
	|	InventoryKinds.RowID AS RowID,
	|	InventoryKinds.RowID AS FinRecordID,
	|	CASE
	|		WHEN InventoryKinds.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)
	|		WHEN InventoryKinds.DocumentSalesOfGoodsAndServices.Date < &BeginningOfMonthOfPeriod
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
	|	END AS BusinessTransactionSetting
	|FROM
	|	Document.RetailReturnsReport.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref IN (&Ref)
	|	AND InventoryKinds.DocumentSalesOfGoodsAndServices <> VALUE(Document.RetailSalesReport.EmptyRef)
	|";
	ValueText_ = StrReplace(
		ValueText_,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"Services.Package",
			"Services.Products"));
		
	VATAccountingERP.ReflectImplementationToClient(Query, QueryTexts, Registers, ValueText_);
	
	TextReturnValues =
	"SELECT
	|	Services.Ref.Date AS Period,
	|	Services.Ref AS Ref,
	|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods) AS BusinessOperation,
	|	VALUE(Catalog.Counterparties.RetailCustomer) AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS Shipper,
	|	Services.Ref.Organization AS Organization,
	|	Services.Ref.Department AS Department,
	|	UNDEFINED AS ConsignedGoodsCustomer,
	|	FALSE AS ReturnOfGoodsViaCommissionAgent,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	Services.Ref AS DocumentReturnPolicy,
	|	TRUE AS RetailCustomer,
	|	TRUE CustomerVATExempt,
	|	FALSE AS FundsReturnedToRetailBuyer,
	|	UNDEFINED AS CashReturnDocumentNumberToRetailBuyer,
	|	UNDEFINED AS DateOfDocumentOfReturnOfCashToRetailBuyer,
	|	UNDEFINED AS ARAPObject,
	|	Services.Ref.VATTaxation AS VATTaxation,
	|	Services.Ref.VATTaxation AS VATActivityType,
	|	Services.VATRate AS VATRate,
	|	Services.Products AS Products,
	|	Services.Characteristic AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	Services.ProductsInSet AS ProductsInSet,
	|	Services.ItemVariantOfSet AS ItemVariantOfSet,
	|	"""" AS Content,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms OR Services.NumberOfPackages = 0
	|			THEN -Services.Count
	|		ELSE -Services.NumberOfPackages
	|	END AS Count,
	|	-Services.QuantityByGBRN AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN Services.Products.UnitOfMeasure
	|		ELSE &QueryTextUnitOfMeasure
	|	END AS UnitOfMeasure,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	UNDEFINED AS FEACNCode,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	0 AS LineNumber,
	|	Services.RowID AS RowID,
	|	Services.RowID AS FinRecordID,
	|	Services.ItemsLocationAttributes.Purpose AS Purpose,
	|	UNDEFINED AS LineOfBusiness,
	|	CASE
	|		WHEN Services.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)
	|		WHEN Services.DocumentSalesOfGoodsAndServices.Date < &BeginningOfMonthOfPeriod
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
	|	END AS BusinessTransactionSetting
	|FROM
	|	Document.RetailReturnsReport.Goods AS Services
	|		LEFT JOIN Document.RetailReturnsReport.InventoryKinds AS InventoryKinds
	|		ON Services.Ref = InventoryKinds.Ref
	|			AND Services.ItemsLocationAttributes = InventoryKinds.ItemsLocationAttributes
	|WHERE
	|	Services.Ref IN (&Ref)
	|	AND Services.DocumentSalesOfGoodsAndServices = VALUE(Document.RetailSalesReport.EmptyRef)
	|	AND Services.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OperationService),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|	AND InventoryKinds.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryKinds.Ref.Date AS Period,
	|	InventoryKinds.Ref AS Ref,
	|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods) AS BusinessOperation,
	|	VALUE(Catalog.Counterparties.RetailCustomer) AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS Shipper,
	|	InventoryKinds.Ref.Organization AS Organization,
	|	InventoryKinds.Ref.Department AS Department,
	|	UNDEFINED AS ConsignedGoodsCustomer,
	|	FALSE AS ReturnOfGoodsViaCommissionAgent,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	InventoryKinds.Ref AS DocumentReturnPolicy,
	|	TRUE AS RetailCustomer,
	|	TRUE CustomerVATExempt,
	|	FALSE AS FundsReturnedToRetailBuyer,
	|	UNDEFINED AS CashReturnDocumentNumberToRetailBuyer,
	|	UNDEFINED AS DateOfDocumentOfReturnOfCashToRetailBuyer,
	|	UNDEFINED AS ARAPObject,
	|	InventoryKinds.Ref.VATTaxation AS VATTaxation,
	|	InventoryKinds.Ref.VATTaxation AS VATActivityType,
	|	InventoryKinds.VATRate AS VATRate,
	|	InventoryKinds.ItemsLocationAttributes.Products AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	InventoryKinds.ItemsLocationAttributes.Series AS Series,
	|	InventoryKinds.SetAccountingDimension.ProductsInSet AS ProductsInSet,
	|	InventoryKinds.SetAccountingDimension.ItemVariantOfSet AS ItemVariantOfSet,
	|	"""" AS Content,
	|	-InventoryKinds.Count AS Count,
	|	-InventoryKinds.QuantityByGBRN AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS UnitOfMeasure,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	UNDEFINED AS FEACNCode,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	0 AS LineNumber,
	|	InventoryKinds.RowID AS RowID,
	|	InventoryKinds.RowID AS FinRecordID,
	|	InventoryKinds.ItemsLocationAttributes.Purpose AS Purpose,
	|	UNDEFINED AS LineOfBusiness,
	|	CASE
	|		WHEN InventoryKinds.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)
	|		WHEN InventoryKinds.DocumentSalesOfGoodsAndServices.Date < &BeginningOfMonthOfPeriod
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
	|	END AS BusinessTransactionSetting
	|FROM
	|	Document.RetailReturnsReport.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref IN (&Ref)
	|	AND InventoryKinds.DocumentSalesOfGoodsAndServices = VALUE(Document.RetailSalesReport.EmptyRef)
	|";
	TextReturnValues = StrReplace(
		TextReturnValues,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"Services.Package",
			"Services.Products"));
		
	VATAccountingERP.ReflectReturnOfGoodsFromBuyer(Query, QueryTexts, Registers, TextReturnValues);
	
EndProcedure

Procedure ArrangeShipmentAtRetail(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest =
	// Return 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	DocumentGoods.Ref.Date			AS Period,
	|	DocumentGoods.Ref.Warehouse		AS Warehouse,
	|	DocumentGoods.Premise			AS Premise,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count AS Count,
	|	TRUE	AS GoodsReturn,
	|	DocumentGoods.ByCorrectionReceipt	AS ByCorrectionReceipt,
	|	DocumentGoods.CostDefiningMethod	AS CostDefiningMethod,
	|	DocumentGoods.DocumentSalesOfGoodsAndServices	AS DocumentSalesOfGoodsAndServices
	|FROM
	|	Document.RetailReturnsReport.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.Count <> 0	
	|	AND NOT DocumentGoods.ByCorrectionReceipt	
	|	AND (NOT (ISNULL(DocumentGoods.Ref.CashRegister.CashRegisterType, UNDEFINED) = VALUE(Enum.CashRegisterTypes.FiscalCashRegisters)
	|			AND DocumentGoods.Ref.CashRegisterShift <> VALUE(Document.CashRegisterShift.EmptyRef))
	|		OR (ISNULL(DocumentGoods.Ref.CashRegisterShift.Status, UNDEFINED) = VALUE(Enum.CashRegisterShiftStatuses.Closed_)
	|			AND ISNULL(DocumentGoods.Ref.CashRegisterShift.PeriodEndTransactionsStatus, UNDEFINED) = VALUE(Enum.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreatedReceiptsAreArchived)))
	|
	|UNION ALL
	|
	// reverse correction
	|SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	DocumentGoods.Ref.Date			AS Period,
	|	DocumentGoods.Ref.Warehouse		AS Warehouse,
	|	DocumentGoods.Premise			AS Premise,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	-DocumentGoods.Count AS Count,
	|	FALSE	AS GoodsReturn,
	|	DocumentGoods.ByCorrectionReceipt	AS ByCorrectionReceipt,
	|	DocumentGoods.CostDefiningMethod	AS CostDefiningMethod,
	|	DocumentGoods.DocumentSalesOfGoodsAndServices	AS DocumentSalesOfGoodsAndServices	
	|FROM
	|	Document.RetailReturnsReport.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.Count <> 0
	|	AND DocumentGoods.ByCorrectionReceipt
	|	AND (NOT (ISNULL(DocumentGoods.Ref.CashRegister.CashRegisterType, UNDEFINED) = VALUE(Enum.CashRegisterTypes.FiscalCashRegisters)
	|			AND DocumentGoods.Ref.CashRegisterShift <> VALUE(Document.CashRegisterShift.EmptyRef))
	|		OR (ISNULL(DocumentGoods.Ref.CashRegisterShift.Status, UNDEFINED) = VALUE(Enum.CashRegisterShiftStatuses.Closed_)
	|			AND ISNULL(DocumentGoods.Ref.CashRegisterShift.PeriodEndTransactionsStatus, UNDEFINED) = VALUE(Enum.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreatedReceiptsAreArchived)))
	|";
	
	MetadataObject	= Metadata.Documents.RetailReturnsReport;

	MethodParameters = WarehousesServer.ParametersOfModularHolding();
	MethodParameters.TSSeriesName = "SetOfSeries";
	MethodParameters.SynonymForDocumentTable = "DocumentGoods";	
	MethodParameters.AdditionalSeriesConnectionFields.Add("ByCorrectionReceipt");
	MethodParameters.AdditionalSeriesConnectionFields.Add("CostDefiningMethod");
	MethodParameters.AdditionalSeriesConnectionFields.Add("DocumentSalesOfGoodsAndServices");
		
	WarehousesServer.ArrangeShipmentAtRetail(Query,
										QueryTexts,
										Registers,
										TextOfDocumentDataRequest,
										MetadataObject,
										MethodParameters);
	
EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref                              AS Ref,
		|	TabPart.Ref.Date                         AS Period,
		|	TabPart.Products                        AS Products,
		|	TabPart.Characteristic                      AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Ref.Department
		|		ELSE TabPart.Ref.Warehouse
		|	END AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.RetailReturnsReport.Goods AS TabPart
		|WHERE
		|	NOT TabPart.ByCorrectionReceipt
		|	AND (NOT (ISNULL(TabPart.Ref.CashRegister.CashRegisterType,
		|		UNDEFINED) = VALUE(Enum.CashRegisterTypes.FiscalCashRegisters)
		|	AND TabPart.Ref.CashRegisterShift <> VALUE(Document.CashRegisterShift.EmptyRef))
		|	OR (ISNULL(TabPart.Ref.CashRegisterShift.Status,
		|		UNDEFINED) = VALUE(Enum.CashRegisterShiftStatuses.Closed_)
		|	AND ISNULL(TabPart.Ref.CashRegisterShift.PeriodEndTransactionsStatus,
		|		UNDEFINED) = VALUE(Enum.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreatedReceiptsAreArchived)))";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Ref.Department
		|		ELSE TabPart.Ref.Warehouse
		|	END AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	-TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.RetailReturnsReport.Goods AS TabPart
		|WHERE
		|	TabPart.ByCorrectionReceipt
		|		AND (NOT (ISNULL(TabPart.Ref.CashRegister.CashRegisterType, UNDEFINED) = VALUE(Enum.CashRegisterTypes.FiscalCashRegisters)
		|				AND TabPart.Ref.CashRegisterShift <> VALUE(Document.CashRegisterShift.EmptyRef))
		|			OR (ISNULL(TabPart.Ref.CashRegisterShift.Status, UNDEFINED) = VALUE(Enum.CashRegisterShiftStatuses.Closed_)
		|				AND ISNULL(TabPart.Ref.CashRegisterShift.PeriodEndTransactionsStatus, UNDEFINED) = VALUE(Enum.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreatedReceiptsAreArchived)))";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
		
EndProcedure

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	AdditionalParameters.Add("CorInventoryOwnerAttribute");
	
	If Query <> Undefined Then
		SetRequestParameterCorInventoryView(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTOperationServices");
	AdditionalTables.Add("TTTypesOfStocks");
	
	If Query <> Undefined Then
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTOperationServices(Query, QueryTexts);
		EndIf; 	
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[1], QueryTexts) Then
			QueryTextTTTypesOfStocks(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region ExternalReceipt_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	&Period 					AS Period,
	|	&Ref 					AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	&Organization										AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	&Ref												AS Lot,
	|	&TaxationOfOrganization							AS VATActivityType,
	|	&VATTaxation									AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	&Partner						AS Vendor,
	|	&Counterparty 					AS Counterparty,
	|	TableTypesOfStocks_.VATRate	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED					AS SalesOpportunity,
	|	UNDEFINED				 	AS Department,
	|	UNDEFINED 					AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID 			AS RowID,
	|	TableTypesOfStocks_.AmountIncludingVATMan 				AS Cost,
	|	TableTypesOfStocks_.AmountExcludingVATMan 				AS CostExcludingVAT,
	|	CASE
	|		WHEN TableTypesOfStocks_.VATTaxation IN (
	|			VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|			VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|		THEN
	|			TableTypesOfStocks_.AmountIncludingVATCompl
	|		ELSE
	|			TableTypesOfStocks_.AmountExcludingVATCompl
	|	END 											AS LocalCost,
	|	TableTypesOfStocks_.VATAmountCompl 				AS VATLocal,
	|	CASE
	|		WHEN NOT &CompanyManagementAccounting
	|			THEN 0
	|		ELSE CASE
	|			WHEN TableTypesOfStocks_.VATTaxation IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN
	|				TableTypesOfStocks_.AmountIncludingVATMan
	|			ELSE
	|				TableTypesOfStocks_.AmountExcludingVATMan
	|			END
	|	END 											AS CostMan,
	|	0 												AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0	 											AS PermanentDifference,
	|	0 												AS CostTD,
	|	0 												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.GoodsReceiptByGoodsReturn) 		AS BusinessOperation,
	|	TableTypesOfStocks_.RowID			 							AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RetailReturnsReport AS DocumentTable	
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)	
	|	AND TableTypesOfStocks_.Products.ItemsType IN
	|		(VALUE(Enum.ItemsTypes.OwnGoods),
	|		 VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND TableTypesOfStocks_.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion
	
	#Region ExternalAdmission_Work
	
	QueryText = 
	"SELECT
	// Document description
	|	&Period 					AS Period,
	|	&Ref 					AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	&Organization										AS Organization,
	|	GoodsTable.ItemsLocationAttributes 			AS ItemsLocationAttributes,
	|	GoodsTable.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
	|	&Ref												AS Lot,
	|	&TaxationOfOrganization							AS VATActivityType,
	|	&VATTaxation									AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	GoodsTable.LotVendorAttributes			AS LotVendorAttributes,
	|	GoodsTable.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	&Partner									AS Vendor,
	|	&Counterparty 								AS Counterparty,
	|	GoodsTable.VATRate						AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED					AS SalesOpportunity,
	|	UNDEFINED				 	AS Department,
	|	UNDEFINED 					AS Manager,
	|
	// Quantitative and summary indicators
	|	GoodsTable.Count					AS Count,
	|	GoodsTable.RowID 			AS RowID,
	|	GoodsTable.AmountIncludingVATMan 					AS Cost,
	|	GoodsTable.AmountExcludingVATMan 				AS CostExcludingVAT,
	|	CASE
	|		WHEN GoodsTable.VATTaxation IN (
	|			VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|			VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|		THEN
	|			GoodsTable.AmountIncludingVATCompl
	|		ELSE
	|			GoodsTable.AmountExcludingVATCompl
	|	END 											AS LocalCost,
	|	GoodsTable.VATAmountCompl 						AS VATLocal,
	|	CASE
	|		WHEN NOT &CompanyManagementAccounting
	|			THEN 0
	|		ELSE CASE
	|			WHEN GoodsTable.VATTaxation IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN
	|				GoodsTable.AmountIncludingVATMan
	|			ELSE
	|				GoodsTable.AmountExcludingVATMan
	|			END
	|	END 											AS CostMan,
	|	0 												AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0	 											AS PermanentDifference,
	|	0 												AS CostTD,
	|	0 												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.GoodsReceiptByGoodsReturn) 		AS BusinessOperation,
	|	GoodsTable.RowID			 								AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RetailReturnsReport AS DocumentTable	
	|	INNER JOIN TTOperationServices AS GoodsTable
	|		ON TRUE
	|WHERE	
	|	DocumentTable.Ref IN (&Ref)	
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND GoodsTable.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion
	
	#Region Sales_Goods_Storno
	
	QueryText = 
	"SELECT
	// Document description
	|	&Period				 			 				AS Period,
	|	&Ref 		 								AS Ref,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices			AS DocumentSource,
	|	TableTypesOfStocks_.SalePeriod 				AS SourceDocumentPeriod,
	|	UNDEFINED 					 				AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	&Organization 									AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	CASE WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END 											AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation 			AS VATActivityType,
	|	&VATTaxation								AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	TableTypesOfStocks_.DimensionSalesOfGoodsAndServices   		AS CorItemsLocationAttributes,
	|	CASE WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END 											AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	TableTypesOfStocks_.AccountingDimensionByPartners	AS AccountingDimensionByPartners,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices           AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED								AS SalesOpportunity,
	|	CASE
	|		WHEN TableTypesOfStocks_.DimensionSalesOfGoodsAndServices <> TableTypesOfStocks_.ItemsLocationAttributes
	|		THEN DocumentTable.Department
	|		ELSE TableTypesOfStocks_.ImplementationDivision
	|	END AS Department,
	|	DocumentTable.EmployeeResponsible				AS Manager,
	|	UNDEFINED 								AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	CASE
	|		WHEN TableTypesOfStocks_.DimensionSalesOfGoodsAndServices <> TableTypesOfStocks_.ItemsLocationAttributes
	|			OR TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN TableTypesOfStocks_.Count
	|		ELSE -TableTypesOfStocks_.Count
	|	END AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|
	// Other fields
	|	CASE
	|		WHEN TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|		WHEN TableTypesOfStocks_.DimensionSalesOfGoodsAndServices <> TableTypesOfStocks_.ItemsLocationAttributes
	|		THEN VALUE(Enum.BusinessTransactions.ReverseOfSaleReturnToAnotherWarehouse)
	|		ELSE VALUE(Enum.BusinessTransactions.ReverseOfSale)
	|	END AS BusinessOperation,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	CASE
	|		WHEN TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|		WHEN TableTypesOfStocks_.DimensionSalesOfGoodsAndServices <> TableTypesOfStocks_.ItemsLocationAttributes
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSaleReturnToAnotherWarehouse)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
	|	END AS BusinessTransactionSetting,
	|	CASE
	|		WHEN TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
	|		WHEN TableTypesOfStocks_.DimensionSalesOfGoodsAndServices <> TableTypesOfStocks_.ItemsLocationAttributes
	|		THEN VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouse)
	|		ELSE VALUE(Enum.LotRecordTypes.ReversingEntry)
	|	END AS EntryType
	|
	|FROM
	|	Document.RetailReturnsReport AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE	
	|	DocumentTable.Ref IN (&Ref)	
	|	AND TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|	AND (TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		)
	|		OR TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.Work_5)
	|			AND TableTypesOfStocks_.TraceableWork)
	|	";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
	#Region Implementation_Work_Storno
	
	QueryText = 
	"SELECT
	// Document description
	|	&Period				 			 				AS Period,
	|	&Ref 		 								AS Ref,
	|	GoodsTable.DocumentSalesOfGoodsAndServices				AS DocumentSource,
	|	GoodsTable.SalePeriod 					AS SourceDocumentPeriod,
	|	UNDEFINED 					 				AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	&Organization 									AS Organization,
	|	GoodsTable.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	CASE WHEN GoodsTable.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN GoodsTable.InventoryOwnerAttributeShipment
	|		ELSE GoodsTable.InventoryOwnerAttribute
	|	END 											AS InventoryOwnerAttribute,
	|	GoodsTable.VATTaxation 				AS VATActivityType,
	|	&VATTaxation								AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	GoodsTable.DimensionSalesOfGoodsAndServices   			AS CorItemsLocationAttributes,
	|	CASE WHEN GoodsTable.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN GoodsTable.InventoryOwnerAttributeShipment
	|		ELSE GoodsTable.InventoryOwnerAttribute
	|	END 											AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	GoodsTable.AccountingDimensionByPartners			AS AccountingDimensionByPartners,
	|	GoodsTable.DocumentSalesOfGoodsAndServices           		AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED								AS SalesOpportunity,
	|	GoodsTable.ImplementationDivision		AS Department,
	|	&EmployeeResponsible								AS Manager,
	|	UNDEFINED 								AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	-GoodsTable.Count 			AS Count,
	|	GoodsTable.RowID	AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ReverseOfSale)	AS BusinessOperation,
	|	GoodsTable.RowID 								AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)	AS BusinessTransactionSetting,
	|	VALUE(Enum.LotRecordTypes.ReversingEntry) AS EntryType
	|
	|FROM	
	|	Document.RetailReturnsReport AS DocumentTable	
	|	INNER JOIN TTOperationServices AS GoodsTable
	|		ON TRUE
	|WHERE	
	|	DocumentTable.Ref IN (&Ref)	
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.TraceableWork
	|	AND GoodsTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

Function DescriptionOfRevenueAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	Return DescriptionOfOperations;
	
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

	// Retail sales report
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "DataProcessor.PrintSalesReceipt";
	PrintCommand.Id = "ProductReceipt_";
	PrintCommand.Presentation = NStr("vi = 'Bảng kê hàng hóa bán lẻ trả lại';
									|ru = 'Отчет о розничных возвратах';
									|en = 'Retail return report'; fa = 'گزارش برگشت خرده‌فروشی';
									|it = 'Report sui resi al dettaglio';
									|pl = 'Raport o zwrotach detalicznych';
									|tr = 'Perakende i̇ade raporu'");
	PrintCommand.CheckPostingBeforePrint = True;

	RetailReturnsReportLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Procedure for printing a document.
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	RetailReturnsReportLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

// The function receives data for generating the printed form of the Product receipt.
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
Function GetDataForPrintedFormProductReceipt(PrintParameters, ObjectsArray) Export
	
	SetPrivilegedMode(True);

	Query = New Query(
	"SELECT
	|	DocReceipt.Number                        AS Number,
	|	DocReceipt.Date                         AS Date,
	|	DocReceipt.Ref                       AS Ref,
	|	DocReceipt.CashRegister                     AS CashRegister,
	|	DocReceipt.Currency                       AS Currency,
	|	DocReceipt.PriceIncludesVAT              AS PriceIncludesVAT,
	|	DocReceipt.CashRegister.Presentation       AS Customer,
	|	DocReceipt.EmployeeResponsible.Individual AS EmployeeResponsible,
	|	DocReceipt.Organization                  AS Organization,
	|	DocReceipt.Organization.Prefix       AS Prefix,
	|	DocReceipt.Organization.Presentation AS Vendor,
	|	DocReceipt.DocumentAmount            AS DocumentAmount,
	|	CASE 
	|		WHEN 
	|			DocReceipt.Department.CompliesWithLegalEntityStructure 
	|		THEN
	|			DocReceipt.Department
	|		ELSE
	|			UNDEFINED
	|	END AS Department
	|FROM
	|	Document.RetailReturnsReport AS DocReceipt
	|WHERE
	|	DocReceipt.Ref IN (&DocumentsArray)
	|ORDER BY
	|	DocReceipt.PointInTime
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.LineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,	
	|	Table.Package AS Package,
	|	Table.Price AS Price,
	|	Table.NumberOfPackages * Table.Price - Table.Sum AS DiscountAmount,
	|	Table.NumberOfPackages * Table.Price AS AmountWithoutADiscount,
	|	Table.Sum AS Sum,
	|	Table.VATAmount AS VATAmount,
	|	Table.Premise AS Premise
	|INTO Goods
	|FROM
	|	Document.RetailReturnsReport.Goods AS Table
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON (ProductKitConfigurations.Owner = Table.ProductsInSet)
	|			AND (ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet)
	|			AND (ProductKitConfigurations.Main)
	|WHERE
	|	Table.Ref IN(&DocumentsArray)
	|;
	|
	|SELECT
	|	Table.Ref                 AS Ref,
	|	Table.ProductsInSet     AS ProductsInSet,
	|	Table.ItemVariantOfSet   AS ItemVariantOfSet,
	|	MIN(Table.LineNumber)   AS LineNumber,
	|	SUM(Table.Sum)                       AS Sum,
	|	SUM(Table.VATAmount)                    AS VATAmount,
	|	SUM(Table.DiscountAmount)                 AS DiscountAmount,
	|	SUM(Table.Sum - Table.DiscountAmount) AS AmountWithoutADiscount
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|
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
	|
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	RetailReturnsReport.Ref                                                          AS Ref,
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
	|	LEFT JOIN Document.RetailReturnsReport AS RetailReturnsReport ON TRUE
	|WHERE
	|	RetailReturnsReport.Ref IN (&DocumentsArray) AND ConfigurationOptionsForProductRange.Ref IN (SELECT DISTINCT T.ItemKitConfiguration FROM Goods AS T)
	|GROUP BY
	|	RetailReturnsReport.Ref,
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
	|	TemporaryTableSetsOptional.PresentationOptionInPrintForms,
	|	TemporaryTableSetsOptional.SetPricingOption,
	
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
	|
	|
	|
	|SELECT
	|	Table.Ref                            AS Ref,
	|
	|	Table.Ref                                    AS ItemKitConfiguration,
	|	Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Table.SetPricingOption                  AS SetPricingOption,
	|	Table.ProductsInSet                        AS ProductsInSet,
	|	Table.ItemVariantOfSet                      AS ItemVariantOfSet,
	|	Table.TheseAreComponents                          AS TheseAreComponents,
	|	Table.IsRecordsSet                                  AS IsRecordsSet,
	|
	|	Table.LineNumber                       AS LineNumber,
	|	Table.Products.DescriptionFull   AS FullNameOfProduct_,
	|	Table.Products.Code                  AS Code,
	|	Table.Products.SKU              AS SKU,
	|	Table.Characteristic.DescriptionFull AS FullNameOfCharacteristic,
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE Table.Package.Description
	|	END                      AS PackageName,
	|	Table.NumberOfPackages AS Count,
	|	CASE
	|		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN PRESENTATION(Table.Products.UnitOfMeasure)
	|		ELSE PRESENTATION(Table.Package)
	|	END                                     AS UnitOfMeasure,
	|	Table.Package                          AS Package,
	|	Table.Price                              AS Price,
	|	Table.NumberOfPackages * Table.Price - Table.Sum AS DiscountAmount,
	|	Table.Sum                                             AS Sum,
	|	Table.VATAmount                                          AS VATAmount,
	|	Table.Premise                                         AS Premise
	|FROM
	|(
	|	SELECT
	|		Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|		Table.SetPricingOption AS SetPricingOption,
	|		Table.Ref,
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
	|		Table.VATAmount,
	|		Table.Characteristic,
	|		Table.Package,
	|		Table.DiscountAmount,
	|		Table.AmountWithoutADiscount,
	|		Table.Premise
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
	|	        AND Table.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents),
	|	                                                                VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TemporaryTableSets.PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption AS SetPricingOption,
	|		TemporaryTableSets.Ref,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		FALSE AS TheseAreComponents,
	|		TRUE AS IsRecordsSet,
	|		TemporaryTableSets.LineNumber,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.Count,
	|		TemporaryTableSets.NumberOfPackages,
	|		CASE WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|			TemporaryTableSets.AmountWithoutADiscount / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|		ELSE
	|			0
	|		END AS Price,
	|		TemporaryTableSets.Sum AS Sum,
	|		TemporaryTableSets.VATAmount,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|		TemporaryTableSets.DiscountAmount,
	|		TemporaryTableSets.AmountWithoutADiscount,
	|		UNDEFINED AS Premise
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|	                                                           VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
	|) AS Table
	|
	|ORDER BY
	|	Table.LineNumber,
	|	IsRecordsSet DESC
	|");
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Table.Package",
			"Table.Products"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	Query.SetParameter("PresentationOfDocument", NStr("vi = 'bảng kê hàng hóa bán lẻ trả lại';
														|ru = 'отчета о розничных возвратах';
														|en = 'Retail return report'; fa = 'گزارش برگشت خرده‌فروشی';
														|it = 'report su resi al dettaglio';
														|pl = 'raportu o zwrotach detalicznych';
														|tr = 'perakende i̇ade raporu'", Common.DefaultLanguageCode()));
	Query.SetParameter("PresentationInError",   NStr("vi = 'bảng kê hàng hóa bán lẻ trả lại';
													|ru = 'отчета о розничных возвратах';
													|en = 'retail return report'; fa = 'retail return report';
													|it = 'report su resi al dettaglio';
													|pl = 'raportu o zwrotach detalicznych';
													|tr = 'perakende i̇ade raporu'", Common.DefaultLanguageCode()));
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure(
		"HeaderResults, ResultForTabularPart, DocumentTitle",
		RequestResultsPackage[0],
		RequestResultsPackage[RequestResultsPackage.Count() - 1],
		NStr("vi = 'Bảng kê hàng hóa bán lẻ trả lại';
			|ru = 'Отчет о розничных возвратах';
			|en = 'Retail return report'; fa = 'گزارش برگشت خرده‌فروشی';
			|it = 'Report sui resi al dettaglio';
			|pl = 'Raport o zwrotach detalicznych';
			|tr = 'Perakende i̇ade raporu'", Common.DefaultLanguageCode()));
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return DataStructureForPrinting;
	
EndFunction


#EndRegion

// Returns the text of the query to calculate the status of the guidance series (With premises)
//	Returns:
//		String - query text.
//
Function RequestTextForFillingInStatusesForSpecifyingSeriesWithPremises()

	QueryText = 
	"SELECT
	|	Goods.Premise,
	|	Goods.Products,
	|	Goods.Characteristic,
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
	|	Goods.Premise,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Premise,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Premise,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Premise,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Premise,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|		BatchAccountingPolicies.Ref AS Ref,
	|		BatchAccountingPolicies.BatchAccountingPolicy AS BatchAccountingPolicy,
	|		BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches AS UseCostAccountingByBatches,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment AS SpecifyWhenPlanningShipment,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking AS SpecifyWhenPlanningPicking,
	|		BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO AS BatchesAccountingByFEFO,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult AS SpecifyByPickingResult,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnRetailShipment AS SpecifyOnRetailShipment,
	|		BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries AS AccountForRemainingSeries
	|INTO SeriesAccountingPoliciesForRequest
	|FROM
	|	Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|	INNER JOIN ProductsToRequest AS ProductsToRequest
	|		ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|WHERE 
	|	(BatchAccountingPolicies.Warehouse = &Warehouse)	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN &SeriesOnlyForCostPrice
	|			THEN 0
	|		WHEN BatchAccountingPolicies.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|							AND ProductsToRequest.Count > 0
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN BatchAccountingPolicies.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchesAccountingByFEFO
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 6
	|								ELSE 5
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 8
	|							ELSE 7
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.SpecifyByPickingResult
	|				AND BatchAccountingPolicies.SpecifyOnRetailShipment
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Premise = ProductsToRequest.Premise
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON Goods.Products = SeriesToRequest.Products
	|			AND Goods.Characteristic = SeriesToRequest.Characteristic
	|			AND Goods.Premise = SeriesToRequest.Premise
	|		LEFT JOIN SeriesAccountingPoliciesForRequest AS BatchAccountingPolicies
	|			ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
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

// Returns the text of the query to calculate the status of the guidance series (Without spaces)
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeriesWithoutRooms()
	
	QueryText = 
	"SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
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
	|	Goods.Products,
	|	Goods.Characteristic,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|		BatchAccountingPolicies.Ref AS Ref,
	|		BatchAccountingPolicies.BatchAccountingPolicy AS BatchAccountingPolicy,
	|		BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches AS UseCostAccountingByBatches,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment AS SpecifyWhenPlanningShipment,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking AS SpecifyWhenPlanningPicking,
	|		BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO AS BatchesAccountingByFEFO,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult AS SpecifyByPickingResult,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnRetailShipment AS SpecifyOnRetailShipment,
	|		BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries AS AccountForRemainingSeries
	|INTO SeriesAccountingPoliciesForRequest
	|FROM
	|	Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|	INNER JOIN ProductsToRequest AS ProductsToRequest
	|		ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|WHERE 
	|	(BatchAccountingPolicies.Warehouse = &Warehouse)	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN &SeriesOnlyForCostPrice
	|			THEN 0
	|		WHEN BatchAccountingPolicies.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|							AND ProductsToRequest.Count > 0
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN BatchAccountingPolicies.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchesAccountingByFEFO
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 6
	|								ELSE 5
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 8
	|							ELSE 7
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.SpecifyByPickingResult
	|				AND BatchAccountingPolicies.SpecifyOnRetailShipment
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			ON Goods.Products = ProductsToRequest.Products
	|				AND Goods.Characteristic = ProductsToRequest.Characteristic
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON Goods.Products = SeriesToRequest.Products
	|				AND Goods.Characteristic = SeriesToRequest.Characteristic
	|		LEFT JOIN SeriesAccountingPoliciesForRequest AS BatchAccountingPolicies
	|			ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
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

#EndIf

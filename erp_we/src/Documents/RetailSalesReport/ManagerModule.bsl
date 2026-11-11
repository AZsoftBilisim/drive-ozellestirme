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
	DocumentMechanisms.Add("GiftCertificates");
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
	
	RetailSalesReportLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of value table elements with data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.RetailSalesReport") Then
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
		QueryTextRecordsCounterpartyCounterparty(Query, QueryTexts, Registers);
		QueryTextGiftCardHistory(Query, QueryTexts, Registers);
		QueryTextGiftCertificates(Query, QueryTexts, Registers);
		QueryTextBonusPoints(Query, QueryTexts, Registers);
		QueryTextTableServicesForRegistrationOfReportsToPrincipal(Query, QueryTexts, Registers);
		QueryTextTableCashInTransit(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
		RetailSalesReportLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ArrangeShipmentAtRetail(Query, QueryTexts, Registers);
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
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
	
	Return;
	
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
	
	RetailSalesReportLocalization.AddGenerationCommands(GenerationCommands, Parameters);

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
	If AccessRight("Insert", Metadata.Documents.RetailSalesReport) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.RetailSalesReport.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.RetailSalesReport);
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
	
	RetailSalesReportLocalization.AddReportCommands(ReportsCommands, Parameters);

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
//  See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, True);

	SeriesSpecificationParameters.FullObjectName = "Document.RetailSalesReport";
	
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.RetailShipment);
	
	If WarehousesServer.UseWarerooms(Object.Warehouse) Then
		SeriesSpecificationParameters.LinkFields.Add("Premise");
	EndIf;
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.SelectionPlanning = True;	
	SeriesSpecificationParameters.FactOfSelection = True;
	SeriesSpecificationParameters.Date = Object.Date;
	
	SeriesSpecificationParameters.DocumentOperation_ = Enums.BusinessTransactions.RetailSaleOfGoods;
	
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

	Return RetailSalesReportLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in the regulated accounting.
//
// Returns:
//  String - query text.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return RetailSalesReportLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion
#Region Other

// Creates a representation of the metadata object in the main language.
// 
// Returns:
//  String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	SynonymForInformationDatabaseEntry = NStr(
		"vi = 'Bảng kê bán lẻ hàng hóa';
		|ru = 'Отчет о розничных продажах';
		|en = 'Retail sales report'; fa = 'گزارش فروش خرده';
		|it = 'Report sulle vendite al dettaglio';
		|pl = 'Raport o sprzedażach detalicznych';
		|tr = 'Perakende satış raporu'",
		DefaultLanguageCode);
		
	Return SynonymForInformationDatabaseEntry;
	
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
//  Object - DocumentObject.RetailSalesReport - the document to generate parameters for.
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

#EndRegion

#Region Private

#Region Posting

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	SynonymForDocumentTable = "";
	FullDocumentName = "Document.RetailSalesReport";
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

	Query.Text = "SELECT
			   |	SUM(TableForCalculatingAmountOfPaymentInCash.Sum) AS CashPaymentAmount,
			   |	SUM(TableForCalculatingAmountOfPaymentInCash.VATAmount) AS VATAmount
			   |FROM
			   |	(SELECT
			   |		DocumentTable.DocumentAmount AS Sum,
			   |		0 AS VATAmount
			   |	FROM
			   |		Document.RetailSalesReport AS DocumentTable
			   |	WHERE
			   |		DocumentTable.Ref = &Ref
			   |	
			   |	UNION ALL
			   |	
			   |	SELECT
			   |		-TabularSection.Sum,
			   |		0
			   |	FROM
			   |		Document.RetailSalesReport.PaymentWithPaymentCards AS TabularSection
			   |	WHERE
			   |		TabularSection.Ref = &Ref
			   |
			   |	UNION ALL
			   |	
			   |	SELECT
			   |		0,
			   |		TabularSection.VATAmount
			   |	FROM
			   |		Document.RetailSalesReport.Goods AS TabularSection
			   |	WHERE
			   |		TabularSection.Ref = &Ref
			   |	
			   |	UNION ALL
			   |	
			   |	SELECT
			   |		-TabularSection.Sum,
			   |		0
			   |	FROM
			   |		Document.RetailSalesReport.GiftCertificates AS TabularSection
			   |	WHERE
			   |		TabularSection.Ref = &Ref) AS TableForCalculatingAmountOfPaymentInCash";
	
	ResultTable2 = Query.Execute().Unload();	
	Query.SetParameter("CashPaymentAmount", ResultTable2[0].CashPaymentAmount);
	Query.SetParameter("VATAmount", ResultTable2[0].VATAmount);

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
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods) AS BusinessOperation,
	|	VALUE(Catalog.CashFlowReportItems.CashReceiptFromCustomer) AS CashFlowItem,
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
	|	VALUE(Catalog.BusinessTransactionsSettings.RetailSaleOfGoods) AS BusinessTransactionSetting,
	|	DocumentData.Comment 					  AS Comment,
	|	DocumentData.DocumentAmount 					  AS DocumentAmount,
	|	DocumentData.Posted 						  AS Posted,
	|	DocumentData.DeletionMark 				  AS DeletionMark
	|FROM
	|	Document.RetailSalesReport AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	If Attributes.CashRegisterType = Enums.CashRegisterTypes.FiscalCashRegisters
		And ValueIsFilled(Attributes.CashRegisterShift) Then
		FullImplementation = (Attributes.CashRegisterShiftStatus = Enums.CashRegisterShiftStatuses.Closed_
		                    And Attributes.PeriodEndTransactionsStatus = Enums.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreatedReceiptsAreArchived);
	Else
		FullImplementation = True;
	EndIf;
	
	Query.SetParameter("Ref",                                   DocumentRef);
	Query.SetParameter("FullImplementation",                         FullImplementation);
	Query.SetParameter("PriceIncludesVAT",                          ?(Attributes.PriceIncludesVAT, 0, 1));
	Query.SetParameter("PriceDoesNotIncludeVAT",                        ?(Attributes.PriceIncludesVAT, -1, 0));
	Query.SetParameter("LocalAccountingCurrency",           Attributes.LocalAccountingCurrency);
	Query.SetParameter("ManagementAccountingCurrency",               Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("UseAgentServiceSale",               GetFunctionalOption("UseAgentServiceSale"));
	Query.SetParameter("CurrentDate",                              CurrentUniversalDate());
	
	Query.SetParameter("LineOfBusiness",                  Catalogs.LinesOfBusiness.EmptyRef());
	Query.SetParameter("DisplayBasicUnitsOfMeasureInPrintForms",          Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get());
	
	Query.SetParameter("MetadataIdentifier",           Common.MetadataObjectID(TypeOf(DocumentRef)));
	
	ContractInformation = Undefined;
	Query.SetParameter("ContractInformation",             ContractInformation);
	Query.SetParameter("NumberForPrinting",		   			  Attributes.Number);
	Query.SetParameter("DateOfFullRepaymentOfReusablePS", CurrentSessionDate());
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
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	VALUE(Enum.AcquiringCashTypes.CashRecieptByAcquiringTransactions) AS CashType,
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
	|	VALUE(Enum.BusinessTransactions.CashRecieptFromCustomerByAcquiringTransactions) AS BusinessOperation,
	|	&Period                                        AS PaymentDate,
	|	PaymentTable_3.Sum                          AS Sum,
	|	CFItems.CashFlowItem        AS CashFlowItem
	|FROM
	|	Document.RetailSalesReport.PaymentWithPaymentCards AS PaymentTable_3
	|		LEFT JOIN TTCashFlowArticles AS CFItems
	|		ON PaymentTable_3.LineNumber = CFItems.LineNumber
	|
	|WHERE
	|	&FullImplementation
	|	AND PaymentTable_3.Ref = &Ref
	|	AND PaymentTable_3.Sum > 0
	|	AND CASE
	|		WHEN PaymentTable_3.ConnectionContract <> VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract.DetailedTransactionReconciliation
	|		ELSE ISNULL(PaymentTable_3.POSTerminal.Owner.DetailedTransactionReconciliation, TRUE)
	|	END
	|
	|UNION ALL
	|
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
	|	-PaymentTable_3.Sum                         AS Sum,
	|	CFItems.CashFlowItem        AS CashFlowItem
	|FROM
	|	Document.RetailSalesReport.PaymentWithPaymentCards AS PaymentTable_3
	|		LEFT JOIN TTCashFlowArticles AS CFItems
	|		ON PaymentTable_3.LineNumber = CFItems.LineNumber
	|
	|WHERE
	|	&FullImplementation
	|	AND PaymentTable_3.Ref = &Ref
	|	AND PaymentTable_3.Sum < 0
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
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Warehouse AS Warehouse,
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
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&BusinessOperation AS BusinessOperation,
	|
	|	CASE WHEN TableTypesOfStocks_.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		AND &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	THEN
	|		VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|	ELSE
	|		&VATTaxation 
	|	END AS VATTaxation
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|ORDER BY
	|	TableTypesOfStocks_.LineNumber
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
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Warehouse AS Warehouse,
	|	TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization AS CompanyOwner,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS SellerInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.SaleOfAnotherCompanyInventory
	|ORDER BY
	|	TableTypesOfStocks_.LineNumber
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
	|	TableTypesOfStocks_.LineNumber						AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)				AS RecordType,
	|	&Period												AS Period,
	|	&Organization										AS Organization,
	|	TableTypesOfStocks_.Currency							AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products						AS Products,
	|	TableTypesOfStocks_.Characteristic					AS Characteristic,
	|	TableTypesOfStocks_.CommitteeProductAnalysis	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.CCDNumber							AS CCDNumber,
	|	&Ref												AS DocumentSalesOfGoodsAndServices,
	|	&BusinessOperation								AS BusinessOperation,
	|	TableTypesOfStocks_.Count						AS Count,
	|	CASE
	|		WHEN TableTypesOfStocks_.Currency = &Currency
	|			THEN TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END												AS RevenueAmount,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN TableTypesOfStocks_.AmountIncludingVATCompl
	|		ELSE 0
	|	END												AS RevenueAmountExclVATLocal,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END												AS RevenueAmountMan,
	|	TableTypesOfStocks_.Count						AS QuantityToRegister,
	|	TableTypesOfStocks_.QuantityByGBRN					AS QuantityForRegistrationByProductBatchID,
	|	CASE
	|		WHEN TableTypesOfStocks_.Currency = &Currency
	|			THEN TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END												AS RevenueAmountToRegister,
	|	TableTypesOfStocks_.RowID				AS FinRecordID,
	|	&BusinessTransactionSetting						AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID AS RowID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN TTExchangeRates AS ExchangeRates
	|		ON TableTypesOfStocks_.InventoryOwnerAttribute.Currency = ExchangeRates.Currency
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|ORDER BY
	|	LineNumber";
	
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
	|	&Department AS Department,
	|	RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|	RegisterAccountingAnalyticsForPartners.LineOfBusiness AS CounterpartyLineOfBusiness,
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
	|	TableTypesOfStocks_.VATActivityType AS VATActivityType,
	|
	|	TableTypesOfStocks_.Seller AS Manager,
	|
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.AmountIncludingVATMan AS RevenueAmount,
	|
	|	TableTypesOfStocks_.AmountExcludingVATMan AS RevenueAmountExcludingVAT,
	|
	|	TableTypesOfStocks_.AmountExcludingVATCompl AS RevenueAmountExclVATLocal,
	|
	|	TableTypesOfStocks_.AmountIncludingVATCompl AS RevenueAmountIncludingVATLocal,
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
	|
	|	CAST(TableTypesOfStocks_.ManualDiscount
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS ManualDiscount,
	|
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS Terms,
	|
	|	&Currency AS ARAPCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInARAPCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.BusinessTransactions.ConsignmentSale)
	|		ELSE &BusinessOperation END) AS BusinessOperation,
	|
	|	TableTypesOfStocks_.Products AS SourceOfProductFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.VATRate           AS VATRate
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|	ON
	|		RegisterAccountingAnalyticsForPartners.Organization = &Organization
	|		AND RegisterAccountingAnalyticsForPartners.Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|		AND TableTypesOfStocks_.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|		AND RegisterAccountingAnalyticsForPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		AND RegisterAccountingAnalyticsForPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|
	|WHERE
	|	TableTypesOfStocks_.Count <> 0
	|	AND NOT TableTypesOfStocks_.TraceableWork
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber                      AS LineNumber,
	|	&Period                                        AS Period,
	|	&Department                                 AS Department,
	|	RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|	RegisterAccountingAnalyticsForPartners.LineOfBusiness AS CounterpartyLineOfBusiness,
	|	GoodsTable.ItemsLocationAttributes       AS ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness	   AS ProductLineOfBusiness,
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
	|	GoodsTable.VATActivityType AS VATActivityType,
	|
	|	GoodsTable.Seller                         AS Manager,
	|
	|	GoodsTable.Count AS Count,
	|	GoodsTable.AmountIncludingVATMan AS RevenueAmount,
	|
	|	GoodsTable.AmountExcludingVATMan AS RevenueAmountExcludingVAT,
	|
	|	GoodsTable.AmountExcludingVATCompl AS RevenueAmountExclVATLocal,
	|
	|	GoodsTable.AmountIncludingVATCompl AS RevenueAmountIncludingVATLocal,
	|
	|	CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|		THEN
	|			GoodsTable.AmountIncludingVATMan
	|		ELSE 0
	|	END AS Cost,
	|	CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|		THEN
	|			GoodsTable.AmountExcludingVATMan
	|		ELSE 0
	|	END AS CostExcludingVAT,
	|	CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|	 	 AND &CompanyManagementAccounting
	|		THEN
	|			GoodsTable.AmountExcludingVATMan
	|		ELSE 0
	|	END AS CostMan,
	|
	|	CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|		THEN
	|			GoodsTable.AmountExcludingVATCompl
	|		ELSE 0
	|	END AS LocalCost,
	|
	|	CAST(GoodsTable.ManualDiscount
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS ManualDiscount,
	|
	|	&Warehouse AS Warehouse,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS Terms,
	|
	|	&Currency AS ARAPCurrency,
	|	(GoodsTable.Sum + &PriceIncludesVAT * GoodsTable.VATAmount) AS AmountInARAPCurrency,
	|	(GoodsTable.Sum + &PriceIncludesVAT * GoodsTable.VATAmount) - GoodsTable.VATAmount AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	(GoodsTable.Sum + &PriceIncludesVAT * GoodsTable.VATAmount) AS AmountInDocumentCurrency,
	|	(GoodsTable.Sum + &PriceIncludesVAT * GoodsTable.VATAmount) - GoodsTable.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|
	|	GoodsTable.VATActivityType AS VATTaxation,
	|	&BusinessOperation AS BusinessOperation,
	|	GoodsTable.Products AS SourceOfProductFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	GoodsTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	GoodsTable.VATRate AS VATRate
	|	
	|FROM
	|	TTOperationServices AS GoodsTable
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
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.CashRegister.Owner AS Organization,
	|	DocumentData.CashRegister AS CashRegister,
	|	ISNULL(Amounts.AmountIncludingVAT, 0) AS Sum,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0) AS SumCompl,
	|	ISNULL(Amounts.AmountIncludingVATMan, 0) AS SumMan,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	&CashFlowItem AS CashFlowItem,
	|	
	|	DocumentData.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromCustomer) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RetailSalesReport AS DocumentData
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON Amounts.Ref = &Ref 
	|		AND Amounts.RowID = DocumentData.DocumentID
	|WHERE
	|	ISNULL(Amounts.AmountIncludingVAT, 0) <> 0
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
	|	VALUE(Enum.WarehouseTransactions.RetailShipment) AS WarehouseOperation,
	|	&Period AS Period,
	|	&Ref AS Recorder,
	|	TRUE AS ThisIsWarehouseRecord
	|FROM
	|	Document.RetailSalesReport.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|	AND &FullImplementation
	|
	|UNION ALL
	|
	|SELECT
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Series,
	|	SUM(SeriesTable.Count),
	|	&Ref,
	|	&Warehouse,
	|	SeriesTable.Premise,
	|	VALUE(Enum.WarehouseTransactions.RetailShipment),
	|	&Period,
	|	&Ref,
	|	TRUE
	|FROM
	|	Document.RetailSalesReport.Goods AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND &FullImplementation
	|GROUP BY
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Series,
	|	SeriesTable.Premise
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
	|	&Ref                                 AS Ref,
	|	&Period                                 AS IBDocumentDate,
	|	&Number                                  AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods) AS BusinessOperation,
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

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""Payment"" AS DataSource,
	|	TRUE   AS DistributeTotalAmount,
	|
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Date AS Date,
	|	DocumentTable.Currency AS DocumentCurrency,
	|	DocumentTable.Organization AS Organization,
	|	UNDEFINED AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	DocumentTable.Date AS DateOfCourse,
	|
	|	0 AS LineNumber,
	|	DocumentTable.DocumentID AS RowID,
	|	
	|	&CashPaymentAmount AS AmountExcludingVAT,
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
	|	Document.RetailSalesReport AS DocumentTable
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	""Payment"" AS DataSource,
	|	TRUE   AS DistributeTotalAmount,
	|
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.Organization AS Organization,
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
	|	Document.RetailSalesReport.PaymentWithPaymentCards AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	""Covariability"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.Organization AS Organization,
	|	UNDEFINED AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
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
	|	Document.RetailSalesReport.InventoryKinds AS DocumentTable
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	""Covariability"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.Organization AS Organization,
	|	UNDEFINED AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	
	|	DocumentTable.Sum 
	|		- CASE 
	|			WHEN DocumentTable.Ref.PriceIncludesVAT 
	|				THEN DocumentTable.VATAmount 
	|			ELSE 0 
	|		END AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
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
	|	Document.RetailSalesReport.Goods AS DocumentTable
	|		LEFT JOIN Document.RetailSalesReport.InventoryKinds AS InventoryTable
	|		ON DocumentTable.Ref = InventoryTable.Ref
	|			AND DocumentTable.ItemsLocationAttributes = InventoryTable.ItemsLocationAttributes
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND InventoryTable.Ref IS NULL
	|	AND DocumentTable.Products.ItemsType IN
	|		(VALUE(Enum.ItemsTypes.Work_5),
	|		VALUE(Enum.ItemsTypes.OperationService))
	|
	|UNION ALL
	|
	|SELECT
	|	""Payment"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.Organization AS Organization,
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
	|
	|FROM
	|	Document.RetailSalesReport.GiftCertificates AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure 

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
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Period AS RecorderDate,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.Count AS Count,
	|	&VATTaxation AS VATTaxation
	|FROM
	|	TTOperationServices AS GoodsTable
	|WHERE
	|	GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.Products.TracedGoods
	|
	|ORDER BY
	|	GoodsTable.LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTGiftCertificatesWithoutPaymentObject(Query, QueryTexts)
	
	RegisterName = "TTGiftCertificatesWithoutPaymentObject";
	
	If Not Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Query.Parameters.Currency, Query.Parameters.Currency, Query.Parameters.Period, Query.Parameters.Organization);
	
		Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
		
	EndIf;
	
	QueryText = 
	"SELECT
	|	GiftCertificates.GiftCertificate                                          AS GiftCertificate,
	|	ISNULL(ARAPObjects.Ref, VALUE(Catalog.ARAPObjects.EmptyRef)) AS ARAPObject,
	|   CatalogGiftCertificates.Owner.GiftCardAccounting25              AS GiftCardAccounting25,
	|   CatalogGiftCertificates.Owner.PartialPayment                            AS PartialPayment,
	|	GiftCertificates.AmountInCertificateCurrency                                       AS Sum,
	|	GiftCertificates.Sum * &FactorOfConversionToCurrencyOfRegul                      AS SumCompl,
	|	GiftCertificates.RowID                                           AS RowID
	|INTO TTGiftCertificatesWithoutPaymentObject
	|FROM
	|	Document.RetailSalesReport.GiftCertificates AS GiftCertificates
	|	LEFT JOIN Catalog.GiftCertificates AS CatalogGiftCertificates
	|		ON CatalogGiftCertificates.Ref = GiftCertificates.GiftCertificate
	|	LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON (ARAPObjects.Object = GiftCertificates.GiftCertificate)
	|
	|WHERE
	|	GiftCertificates.Ref = &Ref
	|	AND CatalogGiftCertificates.Owner.GiftCardAccounting25 = FALSE
	|	AND &FullImplementation
	|
	|INDEX BY
	|	GiftCertificate
	|";

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTGiftCertificatesBalances(Query, QueryTexts)
	
	RegisterName = "TTGiftCertificatesBalances";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTGiftCertificatesWithoutPaymentObject", QueryTexts) Then
		QueryTextTTGiftCertificatesWithoutPaymentObject(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	GiftCertificatesBalance.GiftCertificate AS GiftCertificate,
	|	SUM(GiftCertificatesBalance.Sum) AS Sum
	|INTO TTGiftCertificatesBalances
	|FROM
	|	(SELECT
	|		GiftCertificatesBalance.GiftCertificate AS GiftCertificate,
	|		GiftCertificatesBalance.SumBalance AS Sum
	|	FROM
	|		AccumulationRegister.GiftCertificates.Balance(
	|				,
	|				GiftCertificate IN
	|					(SELECT
	|						GiftCertificates.GiftCertificate
	|					FROM
	|						TTGiftCertificatesWithoutPaymentObject AS GiftCertificates)) AS GiftCertificatesBalance
	|	WHERE
	|		&FullImplementation
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GiftCertificatesOfRegisteredRecording.GiftCertificate,
	|		-GiftCertificatesOfRegisteredRecording.Sum
	|	FROM
	|		AccumulationRegister.GiftCertificates AS GiftCertificatesOfRegisteredRecording
	|			INNER JOIN TTGiftCertificatesWithoutPaymentObject AS GiftCertificates
	|			ON GiftCertificatesOfRegisteredRecording.GiftCertificate = GiftCertificates.GiftCertificate
	|	WHERE
	|		GiftCertificatesOfRegisteredRecording.Recorder = &Ref
	|		AND &FullImplementation) AS GiftCertificatesBalance
	|
	|GROUP BY
	|	GiftCertificatesBalance.GiftCertificate
	|
	|INDEX BY
	|	GiftCertificate";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextGiftCardHistory(Query, QueryTexts, Registers)
	
	RegisterName = "GiftCardHistory";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTGiftCertificatesBalances", QueryTexts) Then
		QueryTextTTGiftCertificatesBalances(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	CASE
	|		WHEN TabularSection.PartialPayment
	|				AND CASE
	|					WHEN ISNULL(Balance.Sum, 0) < 0
	|						THEN -ISNULL(Balance.Sum, 0)
	|					ELSE ISNULL(Balance.Sum, 0)
	|				END - TabularSection.Sum = 0
	|			THEN &DateOfFullRepaymentOfReusablePS
	|		ELSE &Period
	|	END AS Period,
	|	TabularSection.GiftCertificate AS GiftCertificate,
	|	CASE
	|		WHEN TabularSection.PartialPayment
	|				AND CASE
	|					WHEN ISNULL(Balance.Sum, 0) < 0
	|						THEN -ISNULL(Balance.Sum, 0)
	|					ELSE ISNULL(Balance.Sum, 0)
	|				END - TabularSection.Sum <> 0
	|			THEN VALUE(Enum.GiftCertificateStatuses.PartiallyRepaid)
	|		ELSE VALUE(Enum.GiftCertificateStatuses.FullyRepaid)
	|	END AS Status
	|FROM
	|	TTGiftCertificatesWithoutPaymentObject AS TabularSection
	|		LEFT JOIN TTGiftCertificatesBalances AS Balance
	|		ON (Balance.GiftCertificate = TabularSection.GiftCertificate)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextGiftCertificates(Query, QueryTexts, Registers)
	
	RegisterName = "GiftCertificates";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTGiftCertificatesWithoutPaymentObject", QueryTexts) Then
		QueryTextTTGiftCertificatesWithoutPaymentObject(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TabularSection.GiftCertificate    AS GiftCertificate,
	|	TabularSection.Sum                   AS Sum,
	|	TabularSection.SumCompl 			   AS SumCompl,
	|	TabularSection.RowID     AS RowID,
	|	
	|	TabularSection.RowID     AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting
	|FROM
	|	TTGiftCertificatesWithoutPaymentObject AS TabularSection
	|WHERE
	|	&FullImplementation
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
	|	BonusPoints.ValidityStartDate,
	|	BonusPoints.DateToProcess,
	|	BonusPoints.Period,
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
	|	ToRegister.Count                      AS Count,
	|	ToRegister.AmountIncludingVAT 
	|		* ExchangeRates.ConversionFactor_       AS RevenueAmount,
	|	ToRegister.VATAmount 
	|		* ExchangeRates.ConversionFactor_       AS VATAmount,
	|
	|	CASE
	|		WHEN ISNULL(ToRegister.Terms.RevalueServicesForConsignmentNotification, FALSE)
	|			THEN ToRegister.AmountIncludingVATCompl
	|		ELSE 0
	|	END                                       AS RevenueAmountExclVATLocal,
	|	CASE
	|		WHEN ISNULL(ToRegister.Terms.RevalueServicesForConsignmentNotification, FALSE)
	|			THEN ToRegister.AmountIncludingVATMan
	|		ELSE 0
	|	END                                       AS RevenueAmountMan,
	|
	|	&Ref                                    AS DocumentSalesOfGoodsAndServices,
	|	ToRegister.RowID            AS FinRecordID,
	|	&BusinessTransactionSetting            AS BusinessTransactionSetting,
	|	ToRegister.RowID            AS RowID
	|FROM
	|	TTOperationServices AS ToRegister
	|
	|	LEFT JOIN TTExchangeRates AS ExchangeRates
	|	ON ToRegister.Currency = ExchangeRates.Currency
	|WHERE
	|	ToRegister.PrincipalProductAnalysis <> UNDEFINED
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
	|	VALUE(Catalog.CashFlowReportItems.CashReceiptFromCustomer) AS CashFlowItem,
	|	DocumentData.Currency AS PaymentCurrency,
	|
	|	VALUE(Catalog.Partners.RetailCustomer) AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|	
	|	ISNULL(Amounts.AmountIncludingVATMan, 0) AS PayAmount,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0) AS PaymentAmountLocal,
	|	ISNULL(Amounts.AmountIncludingVAT, 0) AS PaymentAmountPaymentCurrency,
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
	|	ISNULL(Amounts.AmountIncludingVAT, 0) AS PaymentAmountInTheSettlementCurrency,
	|	0 AS PostPaymentAmountInARAPCurrency,
	|	0 AS PrepaymentAmountInARAPCurrency,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	UNDEFINED AS VATRate
	|FROM
	|	Document.RetailSalesReport AS DocumentData
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON Amounts.Ref = &Ref 
	|		AND Amounts.RowID = DocumentData.DocumentID
	|WHERE
	|	ISNULL(Amounts.AmountIncludingVAT, 0) <> 0
	|	AND DocumentData.Ref = &Ref
	|	AND &FullImplementation
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.CashRecieptFromCustomerByAcquiringTransactions) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|
	|	TablePaymentByPaymentCards.POSTerminal.Owner AS Cash,
	|	VALUE(Enum.CashTypes.BankAcquirerCash) AS CashType,
	|	CFItems.CashFlowItem AS CashFlowItem,
	|	DocumentData.Currency AS PaymentCurrency,
	|
	|	VALUE(Catalog.Partners.RetailCustomer) AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|	
	|	ISNULL(Amounts.AmountIncludingVATMan, 0) AS PayAmount,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0) AS PaymentAmountLocal,
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
	|	Document.RetailSalesReport AS DocumentData
	|	INNER JOIN
	|		Document.RetailSalesReport.PaymentWithPaymentCards AS TablePaymentByPaymentCards
	|	ON
	|		DocumentData.Ref = TablePaymentByPaymentCards.Ref
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = &Ref 
	|		AND Amounts.RowID = TablePaymentByPaymentCards.RowID
	|	LEFT JOIN TTCashFlowArticles AS CFItems
	|	ON TablePaymentByPaymentCards.LineNumber = CFItems.LineNumber
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &FullImplementation
	|	AND TablePaymentByPaymentCards.Sum > 0
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|
	|	TablePaymentByPaymentCards.POSTerminal.Owner AS Cash,
	|	VALUE(Enum.CashTypes.BankAcquirerCash) AS CashType,
	|	CFItems.CashFlowItem AS CashFlowItem,
	|	DocumentData.Currency AS PaymentCurrency,
	|
	|	VALUE(Catalog.Partners.RetailCustomer) AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|	
	|	ISNULL(-Amounts.AmountIncludingVATMan, 0) AS PayAmount,
	|	ISNULL(-Amounts.AmountIncludingVATCompl, 0) AS PaymentAmountLocal,
	|	-TablePaymentByPaymentCards.Sum AS PaymentAmountPaymentCurrency,
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
	|	-TablePaymentByPaymentCards.Sum AS PaymentAmountInTheSettlementCurrency,
	|	0 AS PostPaymentAmountInARAPCurrency,
	|	0 AS PrepaymentAmountInARAPCurrency,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	UNDEFINED AS VATRate
	|FROM
	|	Document.RetailSalesReport AS DocumentData
	|	INNER JOIN
	|		Document.RetailSalesReport.PaymentWithPaymentCards AS TablePaymentByPaymentCards
	|	ON
	|		DocumentData.Ref = TablePaymentByPaymentCards.Ref
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = &Ref 
	|		AND Amounts.RowID = TablePaymentByPaymentCards.RowID
	|	LEFT JOIN TTCashFlowArticles AS CFItems
	|	ON TablePaymentByPaymentCards.LineNumber = CFItems.LineNumber
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &FullImplementation
	|	AND TablePaymentByPaymentCards.Sum < 0
	|
	|UNION ALL
	|
	|SELECT // VAT by type of inventory
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|
	|	DocumentData.CashRegister AS Cash,
	|	ISNULL(GoodsTable.CashType, VALUE(Enum.CashTypes.CashPayment)) AS CashType,
	|	GoodsTable.CashFlowItem AS CashFlowItem,
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
	|	SUM(GoodsTable.VATAmountMan) AS VATAmount,
	|	SUM(GoodsTable.VATAmountCompl) AS VATAmountCompl,
	|	SUM(GoodsTable.VATAmount) AS AmountVATCurrencyPayment,
	|
	|	DocumentData.Currency AS ARAPCurrency,
	|
	|	0 AS PaymentAmountInTheSettlementCurrency,
	|	0 AS PostPaymentAmountInARAPCurrency,
	|	0 AS PrepaymentAmountInARAPCurrency,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	GoodsTable.VATRate AS VATRate
	|FROM
	|	Document.RetailSalesReport AS DocumentData
	|		LEFT JOIN TTVATAmountsByCashFlowArticles AS GoodsTable
	|		ON GoodsTable.InventoryKinds
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &FullImplementation
	|	AND NOT GoodsTable.VATRate IS NULL
	|
	|GROUP BY
	|	DocumentData.Date,
	|	DocumentData.Organization,
	|	DocumentData.Department,
	|	DocumentData.CashRegister,
	|	DocumentData.Currency,
	|	GoodsTable.VATRate,
	|	GoodsTable.CashFlowItem,
	|	ISNULL(GoodsTable.CashType, VALUE(Enum.CashTypes.CashPayment)) 
	|
	|UNION ALL
	|
	|SELECT // VAT on services, works
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|
	|	DocumentData.CashRegister AS Cash,
	|	ISNULL(GoodsTable.CashType, VALUE(Enum.CashTypes.CashPayment)) AS CashType,
	|	GoodsTable.CashFlowItem AS CashFlowItem,
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
	|	SUM(GoodsTable.VATAmountMan) AS VATAmount,
	|	SUM(GoodsTable.VATAmountCompl) AS VATAmountCompl,
	|	SUM(GoodsTable.VATAmount) AS AmountVATCurrencyPayment,
	|
	|	DocumentData.Currency AS ARAPCurrency,
	|
	|	0 AS PaymentAmountInTheSettlementCurrency,
	|	0 AS PostPaymentAmountInARAPCurrency,
	|	0 AS PrepaymentAmountInARAPCurrency,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	GoodsTable.VATRate AS VATRate
	|FROM
	|	Document.RetailSalesReport AS DocumentData
	|		LEFT JOIN TTVATAmountsByCashFlowArticles AS GoodsTable
	|		ON NOT GoodsTable.InventoryKinds
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &FullImplementation
	|	AND NOT GoodsTable.VATRate IS NULL
	|
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

Function QueryTextRecordsCounterpartyCounterparty(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref.Date AS Period,
	|
	|	VALUE(Enum.BusinessTransactions.PaymentByGiftCard) AS BusinessOperation,
	|	DocumentData.Ref.Organization                                               AS Organization,
	|	DocumentData.Ref.Department                                             AS Department,
	|
	|	VALUE(Catalog.Partners.RetailCustomer) AS Partner,
	|	UNDEFINED                                      AS Counterparty,
	|	UNDEFINED                                      AS Contract,
	|	UNDEFINED                                      AS LineOfBusiness,
	|	GiftCertificate                              AS ARAPObject,
	|
	|	VALUE(Catalog.Partners.RetailCustomer) AS CorPartner,
	|	UNDEFINED                                      AS CorCounterparty,
	|	UNDEFINED                                      AS CorContract,
	|	UNDEFINED                                      AS CorLineOfBusiness,
	|	GiftCertificate                              AS CorARAPObject,
	|
	|	VALUE(Enum.TypesOfDebtAmounts.CustomerAccountsReceivable)     AS AmountType,
	|	VALUE(Enum.TypesOfDebtAmounts.PrepaymentFromCustomer) AS CorAmountType,
	|
	|	DocumentData.Sum AS Sum,
	|	0                     AS AmountExcludingVAT,
	|	DocumentData.Sum AS SumCompl,
	|	0                     AS LocalAmountExcludingVAT,
	|
	|	DocumentData.Ref.Currency AS Currency,
	|	DocumentData.Sum         AS AmountInCurrency,
	|	0                             AS AmountExcludingVATInCurrency,
	|
	|	DocumentData.Ref.Currency AS ARAPCurrency,
	|	DocumentData.Sum         AS AmountInARAPCurrency,
	|	0                             AS AmountExcludingVATInARAPCurrency,
	|
	|	DocumentData.Ref.Currency AS CorCurrencyOfARAPAccounting,
	|	DocumentData.Sum         AS AdjAmountInARAPCurrency,
	|	0                             AS AdjAmountExcludingVATInARAPCurrency,
	|
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
	|	UNDEFINED AS CorSourceOfARAPFinancialAccountingGroup
	|FROM
	|	Document.RetailSalesReport.GiftCertificates AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
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
	
	QueryText = "
	|SELECT
	|	PaymentTable_3.LineNumber                                                          AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)                                               AS RecordType,
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
	|	ISNULL(Amounts.AmountIncludingVAT, 0)                                                         AS Sum,
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)                                                      AS SumMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)                                                     AS SumCompl,
	|
	|	VALUE(Enum.BusinessTransactions.CashRecieptFromCustomerByAcquiringTransactions) AS BusinessOperation,
	|	CFItems.CashFlowItem                                                 AS CashFlowItem,
	|	
	|	PaymentTable_3.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.CashRecieptFromCustomerByAcquiringTransactions) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RetailSalesReport.PaymentWithPaymentCards AS PaymentTable_3
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = &Ref 
	|		AND Amounts.RowID = PaymentTable_3.RowID
	|	LEFT JOIN TTCashFlowArticles AS CFItems
	|	ON PaymentTable_3.LineNumber = CFItems.LineNumber
	|
	|WHERE
	|	&FullImplementation
	|	AND PaymentTable_3.Ref = &Ref
	|	AND PaymentTable_3.Sum > 0
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentTable_3.LineNumber                                                          AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)                                               AS RecordType,
	|	&Period                                                                              AS Period,
	|
	|	&Organization                                                                         AS Organization,
	|	PaymentTable_3.POSTerminal.Owner.BankAccount                        AS Recipient,
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
	|	ISNULL(-Amounts.AmountIncludingVAT, 0)                                                         AS Sum,
	|	ISNULL(-Amounts.AmountIncludingVATMan, 0)                                                      AS SumMan,
	|	ISNULL(-Amounts.AmountIncludingVATCompl, 0)                                                     AS SumCompl,
	|
	|	VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard)    AS BusinessOperation,
	|	CFItems.CashFlowItem                                              AS CashFlowItem,
	|	
	|	PaymentTable_3.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RefundToCustomerSPaymentCard) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RetailSalesReport.PaymentWithPaymentCards AS PaymentTable_3
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = &Ref 
	|		AND Amounts.RowID = PaymentTable_3.RowID
	|		LEFT JOIN TTCashFlowArticles AS CFItems
	|		ON PaymentTable_3.LineNumber = CFItems.LineNumber
	|
	|WHERE
	|	&FullImplementation
	|	AND PaymentTable_3.Ref = &Ref
	|	AND PaymentTable_3.Sum < 0
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
	|	PaymentTable_3.LineNumber AS LineNumber,
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
	|		ELSE &CashFlowItem
	|	END AS CashFlowItem
	|INTO TTCashFlowArticles
	|FROM
	|	Document.RetailSalesReport.PaymentWithPaymentCards AS PaymentTable_3
	|		LEFT JOIN Catalog.AcquiringContracts AS InformationAboutContract
	|		ON PaymentTable_3.ConnectionContract = InformationAboutContract.Ref
	|		LEFT JOIN Catalog.AcquiringContracts AS InformationAboutContractForTerminal
	|		ON PaymentTable_3.POSTerminal.Owner = InformationAboutContractForTerminal.Ref
	|WHERE
	|	PaymentTable_3.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryTexts;
	
EndFunction

Function QueryTextAmountByPaymentCardsInContextOfCashFlowArticles()
	
	QueryText = 
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
	|FROM
	|	Document.RetailSalesReport.PaymentWithPaymentCards AS TabularSection
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
	
	Return QueryText;
	
EndFunction

Function QueryTextInformationAboutNonCashPayment()
	
	QueryText = 
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
	|		Document.RetailSalesReport.PaymentWithPaymentCards AS PaymentWithPaymentCards
	|	WHERE
	|		PaymentWithPaymentCards.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		0,
	|		ReportOnRetailSalesOfGoods.Sum
	|	FROM
	|		Document.RetailSalesReport.Goods AS ReportOnRetailSalesOfGoods
	|	WHERE
	|		ReportOnRetailSalesOfGoods.Ref = &Ref
	|
	|	UNION ALL
	|	
	|	SELECT
	|		0,
	|		ISNULL(ReportOnRetailSalesOfGoods.VATAmount,0)
	|	FROM
	|		Document.RetailSalesReport AS DocumentData
	|		LEFT JOIN Document.RetailSalesReport.Goods AS ReportOnRetailSalesOfGoods
	|		ON DocumentData.Ref = ReportOnRetailSalesOfGoods.Ref
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND NOT DocumentData.PriceIncludesVAT) AS DocumentAmounts";
	
	Return QueryText;

EndFunction

Procedure CreateTTVATAmountsByCashFlowArticles(Query)
		
	QueryTextVATRates =
	"SELECT
	|	CASE
	|		WHEN GoodsTable.VATRate.Rate1 > 0
	|				AND GoodsTable.VATRate.CalculatedRate = TRUE
	|			THEN GoodsTable.VATRate.RelevantBaseRate
	|		ELSE GoodsTable.VATRate
	|	END AS VATRate,
	|	SUM(GoodsTable.VATAmount) AS VATAmount,
	|	SUM(ISNULL(Amounts.AmountIncludingVATMan, 0)) - SUM(ISNULL(Amounts.AmountExcludingVATMan, 0)) AS VATAmountMan,
	|	SUM(ISNULL(Amounts.VATAmountCompl, 0)) AS VATAmountCompl,
	|	FALSE AS InventoryKinds
	|FROM
	|	Document.RetailSalesReport.Goods AS GoodsTable
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON GoodsTable.Ref = Amounts.Ref
	|			AND GoodsTable.RowID = Amounts.RowID
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.VATRate.Rate1 > 0
	|	AND GoodsTable.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OperationService),
	|		VALUE(Enum.ItemsTypes.Work_5)
	|	)
	|
	|GROUP BY
	|	CASE
	|		WHEN GoodsTable.VATRate.Rate1 > 0
	|				AND GoodsTable.VATRate.CalculatedRate = TRUE
	|			THEN GoodsTable.VATRate.RelevantBaseRate
	|		ELSE GoodsTable.VATRate
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN GoodsTable.VATRate.Rate1 > 0
	|				AND GoodsTable.VATRate.CalculatedRate = TRUE
	|			THEN GoodsTable.VATRate.RelevantBaseRate
	|		ELSE GoodsTable.VATRate
	|	END,
	|	SUM(GoodsTable.VATAmount),
	|	SUM(ISNULL(Amounts.AmountIncludingVATMan, 0)) - SUM(ISNULL(Amounts.AmountExcludingVATMan, 0)),
	|	SUM(ISNULL(Amounts.VATAmountCompl, 0)),
	|	TRUE
	|FROM
	|	Document.RetailSalesReport.InventoryKinds AS GoodsTable
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON GoodsTable.Ref = Amounts.Ref
	|			AND GoodsTable.RowID = Amounts.RowID
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.VATRate.Rate1 > 0
	|	AND NOT GoodsTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|GROUP BY
	|	CASE
	|		WHEN GoodsTable.VATRate.Rate1 > 0
	|				AND GoodsTable.VATRate.CalculatedRate = TRUE
	|			THEN GoodsTable.VATRate.RelevantBaseRate
	|		ELSE GoodsTable.VATRate
	|	END";
	
	QueriesTexts = New Array;
	QueriesTexts.Add(QueryTextInformationAboutNonCashPayment());
	QueriesTexts.Add(QueryTextVATRates);
	QueriesTexts.Add(QueryTextAmountByPaymentCardsInContextOfCashFlowArticles());
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	DataForDistribution = Query.ExecuteBatch();
	SelectionBankAccountPayments = DataForDistribution[0].Select();
	DescriptionOfNonCashCashCoefficient = New Structure("NonCashPaymentRatio,AmountOfNonCash",0,0);
	If SelectionBankAccountPayments.Next() Then
		FillPropertyValues(DescriptionOfNonCashCashCoefficient, SelectionBankAccountPayments);
	EndIf;
	
	VATAmounts  = DataForDistribution[1].Unload();
	CFItems = DataForDistribution[2].Unload();
	
	TableForAllocation = CFItems.CopyColumns();
	TableForAllocation.Columns.Add("VATRate",   VATAmounts.Columns.VATRate.ValueType);
	TableForAllocation.Columns.Add("SumMan",    VATAmounts.Columns.VATAmount.ValueType);
	TableForAllocation.Columns.Add("SumCompl",   VATAmounts.Columns.VATAmount.ValueType);
	TableForAllocation.Columns.Add("InventoryKinds", VATAmounts.Columns.InventoryKinds.ValueType);
	TableForAllocation.Columns.Add("CashType",
	                                         New TypeDescription("EnumRef.CashTypes"));
	LinesToDelete = New Array;
	
	// The error falls on cash, and if there is none, then a non-cash line is added, which will take into account the error.
	// In the absence of cash shows the coefficient of payment by cashless = 1
	For Each LineOfVATAmounts In VATAmounts Do
		
		AmountOfNonCashPaymentsToBeDistributed     = LineOfVATAmounts.VATAmount;
		AmountOfNonCashPaymentsToBeDistributedMng  = LineOfVATAmounts.VATAmountMan;
		AmountOfNonCashLocalPaymentsToBeDistributed = LineOfVATAmounts.VATAmountCompl;
		
		For Each CFItemsRow In CFItems Do
			
			If DescriptionOfNonCashCashCoefficient.AmountOfNonCash <> 0 Then
					
				LineOfNonCashPayments = TableForAllocation.Add();
				LineOfNonCashPayments.VATRate   = LineOfVATAmounts.VATRate;
				LineOfNonCashPayments.InventoryKinds = LineOfVATAmounts.InventoryKinds;
				LineOfNonCashPayments.CashFlowItem = CFItemsRow.CashFlowItem;
				LineOfNonCashPayments.CashType =
					PredefinedValue("Enum.CashTypes.BankAcquirerCash");
				
				LineOfNonCashPayments.Sum = LineOfVATAmounts.VATAmount *
				                            DescriptionOfNonCashCashCoefficient.NonCashPaymentRatio *
				                            (CFItemsRow.Sum / DescriptionOfNonCashCashCoefficient.AmountOfNonCash);
				AmountOfNonCashPaymentsToBeDistributed = AmountOfNonCashPaymentsToBeDistributed - LineOfNonCashPayments.Sum;
				
				LineOfNonCashPayments.SumMan = LineOfVATAmounts.VATAmountMan *
				                            DescriptionOfNonCashCashCoefficient.NonCashPaymentRatio *
				                            (CFItemsRow.Sum / DescriptionOfNonCashCashCoefficient.AmountOfNonCash);
				AmountOfNonCashPaymentsToBeDistributedMng = AmountOfNonCashPaymentsToBeDistributedMng - LineOfNonCashPayments.SumMan;
				
				LineOfNonCashPayments.SumCompl = LineOfVATAmounts.VATAmountCompl *
				                            DescriptionOfNonCashCashCoefficient.NonCashPaymentRatio *
				                            (CFItemsRow.Sum / DescriptionOfNonCashCashCoefficient.AmountOfNonCash);
				AmountOfNonCashLocalPaymentsToBeDistributed = AmountOfNonCashLocalPaymentsToBeDistributed - LineOfNonCashPayments.SumCompl;
				
				If LineOfNonCashPayments.Sum     = 0 And 
					 LineOfNonCashPayments.SumMan  = 0 And 
					 LineOfNonCashPayments.SumCompl = 0 Then
					LinesToDelete.Add(LineOfNonCashPayments);
				EndIf;
			
			EndIf;
			
		EndDo;
		
		If AmountOfNonCashPaymentsToBeDistributed <> 0 Or
			 AmountOfNonCashPaymentsToBeDistributedMng <> 0 Or
			 AmountOfNonCashLocalPaymentsToBeDistributed <> 0 Then
		
			If DescriptionOfNonCashCashCoefficient.NonCashPaymentRatio = 1 Then
				
				LineOfNonCashPayments             = TableForAllocation.Add();
				LineOfNonCashPayments.VATRate   = LineOfVATAmounts.VATRate;
				LineOfNonCashPayments.InventoryKinds = LineOfVATAmounts.InventoryKinds;
				LineOfNonCashPayments.CashFlowItem = CFItemsRow.CashFlowItem;
				LineOfNonCashPayments.CashType =
					PredefinedValue("Enum.CashTypes.BankAcquirerCash");
				LineOfNonCashPayments.Sum     = AmountOfNonCashPaymentsToBeDistributed;
				LineOfNonCashPayments.SumMan  = AmountOfNonCashPaymentsToBeDistributedMng;
				LineOfNonCashPayments.SumCompl = AmountOfNonCashLocalPaymentsToBeDistributed;
				
				If LineOfNonCashPayments.Sum     = 0 And 
					 LineOfNonCashPayments.SumMan  = 0 And 
					 LineOfNonCashPayments.SumCompl = 0 Then
					LinesToDelete.Add(LineOfNonCashPayments);
				EndIf;
				
			Else
				
				CashLine = TableForAllocation.Add();
				CashLine.VATRate   = LineOfVATAmounts.VATRate;
				CashLine.InventoryKinds = LineOfVATAmounts.InventoryKinds;
				CashLine.CashFlowItem =
					PredefinedValue("Catalog.CashFlowReportItems.CashReceiptFromCustomer");
				CashLine.CashType =
					PredefinedValue("Enum.CashTypes.CashPayment");
			
				CashLine.Sum     = AmountOfNonCashPaymentsToBeDistributed;
				CashLine.SumMan  = AmountOfNonCashPaymentsToBeDistributedMng;
				CashLine.SumCompl = AmountOfNonCashLocalPaymentsToBeDistributed;
					
				If CashLine.Sum     = 0 And 
					 CashLine.SumMan  = 0 And 
					 CashLine.SumCompl = 0 Then
					LinesToDelete.Add(CashLine);
				EndIf;
				
			EndIf;
		
		EndIf;
		
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		TableForAllocation.Delete(RowToDelete);
	EndDo;
	
	TableForAllocation.GroupBy("VATRate,CashFlowItem,InventoryKinds,CashType",
	                                 "Sum,SumMan,SumCompl");
	Query.SetParameter("TableForAllocation", TableForAllocation);
	
	Query.Text = 
	"SELECT
	|	DistributedData.InventoryKinds AS InventoryKinds,
	|	DistributedData.CashFlowItem AS CashFlowItem,
	|	DistributedData.CashType AS CashType,
	|	DistributedData.VATRate AS VATRate,
	|	DistributedData.Sum AS VATAmount,
	|	DistributedData.SumMan AS VATAmountMan,
	|	DistributedData.SumCompl AS VATAmountCompl
	|INTO TTVATAmountsByCashFlowArticles
	|FROM
	|	&TableForAllocation AS DistributedData";
	
	Query.Execute();
	
EndProcedure

Function QueryTextTTTypesOfStocks(Query, QueryTexts) Export
	
	RegisterName = "TTTypesOfStocks";
	
	SetRequestParameterVATTaxTypesTaxable(Query);
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                                   AS LineNumber,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                                    AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner                AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Currency                             AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType                         AS InventoryType,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products       AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic     AS Characteristic,
	|	TableTypesOfStocks_.ItemsLocationAttributes                    AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	TableTypesOfStocks_.SetAccountingDimension                         AS SetAccountingDimension,
	|	CommitteeAnalytics.DimensionKey                                 AS CommitteeProductAnalysis,
	|	TableTypesOfStocks_.CCDNumber                                      AS CCDNumber,
	|	TableTypesOfStocks_.Count                                    AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN                              AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT                                     AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount                                      AS VATAmount,
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)                                  AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)                                AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)                                 AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)                               AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)                                  AS VATAmountCompl,
	|	TableTypesOfStocks_.ManualDiscount                             AS ManualDiscount,
	|	TableTypesOfStocks_.VATRate                                     AS VATRate,
	|	TableTypesOfStocks_.Seller                                      AS Seller,
	|	TableTypesOfStocks_.Partner                                       AS Partner,
	|	TableTypesOfStocks_.RowID                           AS RowID,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation      AS Warehouse,
	|	TableTypesOfStocks_.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom AS ShopFloorStockroom,
	|	(CASE
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|			THEN &EmployeeResponsible
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END) AS FinancialAccountingDimension,
	|	(CASE
	|		WHEN TableTypesOfStocks_.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		 AND &VATTaxation IN (&TypesOfVATTaxable)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END) AS VATActivityType,
	|	CASE
	|		WHEN TableTypesOfStocks_.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                            AS TraceableWork
	|
	|INTO TTTypesOfStocks
	|FROM
	|	Document.RetailSalesReport.InventoryKinds AS TableTypesOfStocks_
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
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON TableTypesOfStocks_.Ref = Amounts.Ref
	|		AND TableTypesOfStocks_.RowID = Amounts.RowID
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
	|	Document.RetailSalesReport.Goods AS ToRegister
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
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAgencyServices", QueryTexts) Then
		QueryTextTTAgencyServices(Query, QueryTexts);
	EndIf; 
	
	InitializeProductAccountingAnalyticsKeys(Query);
	SetRequestParameterVATTaxTypesTaxable(Query);
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
		
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
	|	(GoodsTable.Sum
	|		+ &PriceIncludesVAT * GoodsTable.VATAmount) AS AmountIncludingVAT,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.ManualDiscount AS ManualDiscount,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0) AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0) AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0) AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0) AS VATAmountCompl,
	|
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
	|	(CASE
	|		WHEN GoodsTable.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		 AND &VATTaxation IN (&TypesOfVATTaxable)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END) AS VATActivityType,
	|	GoodsTable.VATRate AS VATRate,
	|	
	|	GoodsTable.RowID AS RowID
	|
	|INTO TTOperationServices
	|FROM
	|	Document.RetailSalesReport.Goods AS GoodsTable
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
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON GoodsTable.Ref = Amounts.Ref
	|		AND GoodsTable.RowID = Amounts.RowID
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
	|			Document.RetailSalesReport.InventoryKinds AS InventoryKinds
	|		WHERE
	|			InventoryKinds.Ref = &Ref)
	|	
	|UNION ALL
	|	
	|SELECT
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DocumentTable.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	DocumentTable.SetAccountingDimension AS SetAccountingDimension,
	|	DocumentTable.Seller AS Seller,
	|	Dimension.Products.ItemsType AS ItemsType,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	DocumentTable.Partner AS Partner,
	|	
	|	DocumentTable.Count AS Count,
	|	DocumentTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	DocumentTable.VATAmount AS VATAmount,
	|	(DocumentTable.AmountIncludingVAT - &PriceIncludesVAT * DocumentTable.VATAmount) AS Sum,
	|	DocumentTable.ManualDiscount AS ManualDiscount,
	|	
	|	ISNULL(Amounts.AmountIncludingVATMan, 0) AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0) AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0) AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0) AS VATAmountCompl,
	|	
	|	UNDEFINED AS Terms,
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS PrincipalProductAnalysis,
	|	UNDEFINED AS Principal,
	|	DocumentTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|			THEN &EmployeeResponsible
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END) AS FinancialAccountingDimension,
	|	(CASE
	|		WHEN DocumentTable.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		 AND &VATTaxation IN (&TypesOfVATTaxable)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END) AS VATActivityType,
	|	DocumentTable.VATRate AS VATRate,
	|	
	|	DocumentTable.RowID AS RowID
	|	
	|FROM
	|	Document.RetailSalesReport.InventoryKinds AS DocumentTable
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON DocumentTable.ItemsLocationAttributes = Dimension.Ref
	|	
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON DocumentTable.Ref = Amounts.Ref
	|		AND DocumentTable.RowID = Amounts.RowID
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetRequestParameterVATTaxTypesTaxable(Query) Export
	
	If Query.Parameters.Property("TypesOfVATTaxable") Then
		Return;
	EndIf;

	Query.SetParameter("TypesOfVATTaxable", VATAccountingERP.TypesOfActivitiesVATIsAcceptedForReimbursement());
	
EndProcedure

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
	|			THEN TabularSection.AmountOfBonusPoints
	|		ELSE -TabularSection.AmountOfBonusPoints
	|	END AS Accrued,
	|	0 AS ToWriteOff
	|INTO TTBonusPoints
	|FROM
	|	Document.RetailSalesReport.BonusPointAccrual AS TabularSection
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
	|			THEN TabularSection.AmountOfBonusPoints
	|		ELSE -TabularSection.AmountOfBonusPoints
	|	END
	|FROM
	|	Document.RetailSalesReport.BonusPointAccrual AS TabularSection
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
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END,
	|	TabularSection.Partner,
	|	TabularSection.LoyaltyProgram,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN TabularSection.AmountOfBonusPoints
	|		ELSE -TabularSection.AmountOfBonusPoints
	|	END,
	|	CASE
	|		WHEN BEGINOFPERIOD(TabularSection.PayDate, DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5,
	|			DAY)
	|			THEN 0
	|		ELSE CASE
	|			WHEN TabularSection.AmountOfBonusPoints > 0
	|				THEN TabularSection.AmountOfBonusPoints
	|			ELSE -TabularSection.AmountOfBonusPoints
	|		END
	|	END
	|FROM
	|	Document.RetailSalesReport.PaymentWithBonusPoints AS TabularSection
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
	|	Document.RetailSalesReport.PaymentWithBonusPoints AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
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
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.RetailSalesReport.GiftCertificates AS Table
		|		LEFT JOIN Document.RetailSalesReport AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region Sale
	
	TextSale = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.ARAPObject.Partner                                           AS Partner,
		|	
		|	Table.ARAPObject                                                   AS ARAPObject,
		|	Table.Ref.Date                                                      AS PaymentDate,
		|	UNDEFINED                                                             AS SalesOrder_,
		|	FALSE                                                                     AS InvoiceForOrders,
		|
		|	Table.Sum                                                            AS AmountARAP,
		|	0                                                                        AS AmountARAPByPackage,
		|	Table.Sum                                                            AS Sum,
		|	
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	
		|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods)          AS BusinessOperation,
		|	&BusinessTransactionSetting                                          AS BusinessTransactionSetting,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned) AS PaymentOption,
		|	FALSE                                                                     AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument
		|FROM
		|	Document.RetailSalesReport.GiftCertificates AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.ARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)
		|	AND &FullImplementation";
	
	#EndRegion
	
	#Region IncreasePaymentPlan
	
	TextPaymentPlanning = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.ARAPObject.Partner                                           AS Partner,
		|	
		|	Table.ARAPObject                                                   AS ARAPObject,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	
		|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods)          AS BusinessOperation,
		|	&BusinessTransactionSetting                                          AS BusinessTransactionSetting,
		|	Table.Ref.PaymentMethod                                               AS PaymentMethod,
		|	
		|	Table.Ref.Date                                                      AS PaymentDate,
		|	VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned) AS PaymentOption,
		|	Table.Sum                                                            AS AmountDue,
		|	
		|	TRUE                                                                   AS ExcludeDuringControl,
		|	FALSE                                                                     AS InvoiceForOrders,
		|	VALUE(Document.SalesOrder.EmptyRef)                             AS SalesOrder_,
		|	FALSE                                                                     AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument
		|	
		|FROM
		|	Document.RetailSalesReport.GiftCertificates AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.ARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)
		|	AND &FullImplementation";
	
	#EndRegion
	
	#Region ApplyingPrepayment
	
	TextAdvancePaymentOffset = "";
	
	#EndRegion
		
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, TextSale, TextPaymentPlanning, TextAdvancePaymentOffset);
	
EndProcedure

// Parameters:
//  Query - String - 
//  QueryTexts - See RetailSalesReportLocalization.AddRequestTexts.QueryTexts
//
// Returns:
//  String - Query text
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
	|				Document.RetailSalesReport.InventoryKinds AS TableTypesOfStocks_
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
	|				Document.RetailSalesReport.InventoryKinds AS TableTypesOfStocks_
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

Procedure SetParameterForPartnerAccountingAnalyticsRequest(Query)
	
	If Query.Parameters.Property("AccountingDimensionByPartners") Then
		Return;
	EndIf;
	
	Query.SetParameter("AccountingDimensionByPartners", InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(Query.Parameters));
	
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
	|		Document.RetailSalesReport.InventoryKinds AS TableTypesOfStocks_
	|	WHERE
	|		TableTypesOfStocks_.Ref = &Ref
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		GoodsTable.Partner AS Partner
	|	FROM
	|		Document.RetailSalesReport.Goods AS GoodsTable
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
	|			Document.RetailSalesReport.InventoryKinds AS TableTypesOfStocks_
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
	|			Document.RetailSalesReport.InventoryKinds AS TableTypesOfStocks_
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
	|			Document.RetailSalesReport.Goods AS Services
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
	|		Document.RetailSalesReport.InventoryKinds AS TableTypesOfStocks_
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
	|	Services.Series AS Series,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
	|	Services.ProductsInSet AS ProductsInSet,
	|	Services.ItemVariantOfSet AS ItemVariantOfSet,
	|	"""" AS Content,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms OR Services.NumberOfPackages = 0
	|			THEN Services.Count
	|		ELSE Services.NumberOfPackages
	|	END AS Count,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN Services.Products.UnitOfMeasure
	|		ELSE &QueryTextUnitOfMeasure
	|	END AS UnitOfMeasure,
	|	0 AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	UNDEFINED AS FEACNCode,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	0 AS LineNumber,
	|	Services.RowID AS RowID,
	|	Services.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RetailSaleOfGoods) AS BusinessTransactionSetting
	|FROM
	|	Document.RetailSalesReport.Goods AS Services
	|		LEFT JOIN Document.RetailSalesReport.InventoryKinds AS InventoryKinds
	|		ON Services.Ref = InventoryKinds.Ref
	|			AND Services.ItemsLocationAttributes = InventoryKinds.ItemsLocationAttributes
	|WHERE
	|	Services.Ref IN (&Ref)
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
	|	FALSE AS SalesViaCommissionAgent,
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
	|	InventoryKinds.Count AS Count,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS UnitOfMeasure,
	|	InventoryKinds.QuantityByGBRN AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	UNDEFINED AS FEACNCode,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	0 AS LineNumber,
	|	InventoryKinds.RowID AS RowID,
	|	InventoryKinds.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RetailSaleOfGoods) AS BusinessTransactionSetting
	|FROM
	|	Document.RetailSalesReport.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref IN (&Ref)
	|";
	ValueText_ = StrReplace(
		ValueText_,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"Services.Package",
			"Services.Products"));
	VATAccountingERP.ReflectImplementationToClient(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

Procedure ArrangeShipmentAtRetail(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	DocumentGoods.Ref.Date			AS Period,
	|	DocumentGoods.Ref.Warehouse		AS Warehouse,
	|	DocumentGoods.Premise			AS Premise,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	CASE
	|		WHEN DocumentGoods.Count < 0
	|			THEN -DocumentGoods.Count
	|		ELSE DocumentGoods.Count
	|	END								AS Count,
	|	(DocumentGoods.Count < 0)	AS GoodsReturn
    |FROM
    |	Document.RetailSalesReport.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)					
	|	AND DocumentGoods.Count <> 0
	|	AND (NOT (ISNULL(DocumentGoods.Ref.CashRegister.CashRegisterType, UNDEFINED) = VALUE(Enum.CashRegisterTypes.FiscalCashRegisters)
	|			AND DocumentGoods.Ref.CashRegisterShift <> VALUE(Document.CashRegisterShift.EmptyRef))
	|		OR (ISNULL(DocumentGoods.Ref.CashRegisterShift.Status, UNDEFINED) = VALUE(Enum.CashRegisterShiftStatuses.Closed_)
	|			AND ISNULL(DocumentGoods.Ref.CashRegisterShift.PeriodEndTransactionsStatus, UNDEFINED) = VALUE(Enum.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreatedReceiptsAreArchived)))";
	
	MetadataObject	= Metadata.Documents.RetailSalesReport;
	
	MethodParameters = WarehousesServer.ParametersOfModularHolding();
	MethodParameters.TSSeriesName = "SetOfSeries";
	MethodParameters.SynonymForDocumentTable = "DocumentGoods";
	
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
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	Document.RetailSalesReport.Goods AS TabPart
		|WHERE
		|	NOT (ISNULL(TabPart.Ref.CashRegister.CashRegisterType, UNDEFINED) = VALUE(Enum.CashRegisterTypes.FiscalCashRegisters)
		|			AND TabPart.Ref.CashRegisterShift <> VALUE(Document.CashRegisterShift.EmptyRef))
		|		OR (ISNULL(TabPart.Ref.CashRegisterShift.Status, UNDEFINED) = VALUE(Enum.CashRegisterShiftStatuses.Closed_)
		|				AND ISNULL(TabPart.Ref.CashRegisterShift.PeriodEndTransactionsStatus, UNDEFINED) = VALUE(Enum.StatusesOfPeriodEndTransactionsOfCashRegisterShift.ReportIsCreatedReceiptsAreArchived))";
	
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
	AdditionalParameters.Add("AccountingDimensionByPartners");
	
	If Query <> Undefined Then
		InitializeTrackingAnalyticsKeysForPartners(Query);
		SetParameterForPartnerAccountingAnalyticsRequest(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTypesOfStocks");
	AdditionalTables.Add("TTOperationServices");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTypesOfStocks(Query, QueryTexts);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[1], QueryTexts) Then
			QueryTextTTOperationServices(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region Sales_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	UNDEFINED   									AS CorItemsLocationAttributes,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	RegisterAccountingAnalyticsForPartners.DimensionKey	AS AccountingDimensionByPartners,
	|	UNDEFINED 									AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED						AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.EmployeeResponsible		AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods)	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 							AS FinRecordID,
	|	&BusinessTransactionSetting									AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RetailSalesReport AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|	ON &Organization = RegisterAccountingAnalyticsForPartners.Organization
	|		AND VALUE(Catalog.Counterparties.EmptyRef) = RegisterAccountingAnalyticsForPartners.Counterparty
	|		AND TableTypesOfStocks_.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|		AND RegisterAccountingAnalyticsForPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		AND RegisterAccountingAnalyticsForPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.Products.ItemsType IN
	|		(VALUE(Enum.ItemsTypes.OwnGoods),
	|		 VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND TableTypesOfStocks_.InventoryType IN
	|		(VALUE(Enum.InventoryTypes.OwnGoods),
	|		 VALUE(Enum.InventoryTypes.ConsignedGoods))";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion

	#Region Implementation_Work
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	UNDEFINED   									AS CorItemsLocationAttributes,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	UNDEFINED 									AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED						AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.EmployeeResponsible		AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods)	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 							AS FinRecordID,
	|	&BusinessTransactionSetting									AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RetailSalesReport AS DocumentTable
	|	INNER JOIN TTOperationServices AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
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
	|	TableTypesOfStocks_.VATActivityType 			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
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
	|	&BusinessTransactionSetting									AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RetailSalesReport AS DocumentTable
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
	PrintCommand.Presentation = NStr("vi = 'Bảng kê bán lẻ hàng hóa';
									|ru = 'Отчет о розничных продажах';
									|en = 'Retail sales report'; fa = 'گزارش فروش خرده';
									|it = 'Report sulle vendite al dettaglio';
									|pl = 'Raport o sprzedażach detalicznych';
									|tr = 'Perakende satış raporu'");
	PrintCommand.CheckPostingBeforePrint = True;

	RetailSalesReportLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Procedure for printing a document.
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	RetailSalesReportLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
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
	|	Document.RetailSalesReport AS DocReceipt
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
	|	Document.RetailSalesReport.Goods AS Table
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
	|	RetailSalesReport.Ref                                                          AS Ref,
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
	|	LEFT JOIN Document.RetailSalesReport AS RetailSalesReport ON TRUE
	|WHERE
	|	RetailSalesReport.Ref IN (&DocumentsArray) AND ConfigurationOptionsForProductRange.Ref IN (SELECT DISTINCT T.ItemKitConfiguration FROM Goods AS T)
	|GROUP BY
	|	RetailSalesReport.Ref,
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
	|			ELSE null
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
	Query.SetParameter("PresentationOfDocument", NStr("vi = 'bảng kê hàng hóa bán lẻ';
														|ru = 'отчета о розничных продажах';
														|en = 'Retail sales report'; fa = 'گزارش فروش خرده';
														|it = 'del report sulle vendite al dettaglio';
														|pl = 'raportu sprzedaży detalicznej';
														|tr = 'perakende satış raporu'", Common.DefaultLanguageCode()));
	Query.SetParameter("PresentationInError",   NStr("vi = 'bảng kê hàng hóa bán lẻ';
													|ru = 'отчета о розничных продажах';
													|en = 'retail sales report'; fa = 'retail sales report';
													|it = 'del report sulle vendite al dettaglio';
													|pl = 'raportu sprzedaży detalicznej';
													|tr = 'perakende satış raporu'", Common.DefaultLanguageCode()));
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure(
		"HeaderResults, ResultForTabularPart, DocumentTitle",
		RequestResultsPackage[0],
		RequestResultsPackage[RequestResultsPackage.Count() - 1],
		NStr("vi = 'Bảng kê bán lẻ hàng hóa';
			|ru = 'Отчет о розничных продажах';
			|en = 'Retail sales report'; fa = 'گزارش فروش خرده';
			|it = 'Report sulle vendite al dettaglio';
			|pl = 'Raport o sprzedażach detalicznych';
			|tr = 'Perakende satış raporu'", Common.DefaultLanguageCode()));
	
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
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
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
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
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

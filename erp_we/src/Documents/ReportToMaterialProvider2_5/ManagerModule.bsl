#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn.DescriptionOfBankingDetailsToFillIn
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways            = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner";
	Parameters.FillInIf.ObjectFieldsFilledIn             = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, MaterialProviderOrder, Manager";
	Parameters.FillInIf.ObjectFieldsFilledIn  = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways            = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn             = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "CompanyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways            = "Author, Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn             = "Author, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CashAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways            = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn             = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "CounterpartyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Contract, BusinessOperation";
	Parameters.FillInIf.ObjectFieldsFilledIn  = "Contract";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "ProcessingService, VATRate", Parameters);
	
EndProcedure

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
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("Sales");
	DocumentMechanisms.Add("AcceptanceForProcessing");
	DocumentMechanisms.Add("Production");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfWorks");
	DocumentMechanisms.Add("DocumentCorrection");
	
	ReportToMaterialProvider2_5Localization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.ReportToMaterialProvider2_5") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query		  = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers);
		QueryTextTableShipmentReferences(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
		ReportToMaterialProvider2_5Localization.AddRequestTexts(Query, QueryTexts, Registers);
		
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
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

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	CreationCommand = Documents.GoodsShipmentFromStorage.AddGenerateCommand(GenerationCommands);
	If CreationCommand <> Undefined Then
		
		CreationCommand.Presentation =
			TollingSchemeClientServer.SynonymOfDocumentShipmentOfGoodsFromStorageTransferToGiver();
		
		ListOfBusinessTransactions = New Array;
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.ReportToMaterialProvider2_5);
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.Subcontracting2_5);
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5);
		AttachableCommands.AddCommandVisibilityCondition(CreationCommand, "BusinessOperation", ListOfBusinessTransactions, DataCompositionComparisonType.InList);
		
	EndIf;
	
	Documents.IssuedLetterOfAuthority.AddGenerateCommand(GenerationCommands);
	
	Documents.PaymentCardTransaction.AddGenerateCommand(GenerationCommands);
	
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CustomerCommercialInvoice.AddCommandCreateReportToGiverBasedOnInvoice2_5(
		GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	CreationCommand = Documents.SaleAdjustment.AddGenerateCommand(GenerationCommands);
	If CreationCommand <> Undefined Then
		CreationCommand.Presentation = NStr("vi = 'Điều chỉnh bảng kê dành cho bên thuê gia công';
											|ru = 'Корректировка отчета давальцу';
											|en = 'Adjust ""Consumption report — Subcontracting services delivered""'; fa = 'Adjust ""Consumption report — Subcontracting services delivered""';
											|it = 'Rettifica del report al datore';
											|pl = 'Korekta raportu do właściciela surowców';
											|tr = 'Tüketim raporu-Verilen fason hizmetlerini düzeltme '");
	EndIf;
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	ReportToMaterialProvider2_5Localization.AddGenerationCommands(GenerationCommands, Parameters);
	Documents.SubcontractorReport2_5.AddCreateCommandBasedOnGiverSReport(GenerationCommands);
EndProcedure

// Adds the command to create the document "report to the giver".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
//  ValueTableRow
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ReportToMaterialProvider2_5) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager            = Metadata.Documents.ReportToMaterialProvider2_5.FullName();
		CreateBasedOnCommand.Presentation       =
			TMCommonUse.ObjectPresentation(Metadata.Documents.ReportToMaterialProvider2_5);
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseTollManufacturing2_5";
		
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
	
	ReportCommand = Reports.DocumentFulfillmentStatus.AddStateOfActImplementationCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm";
		ReportCommand.Order          = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm";
	EndIf;
	
	ReportCommand = ARAPAccountingServer.CustomerDebt_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm";
	EndIf;
	
	// DocumentsListForm
	ReportCommand = Reports.DocumentFulfillmentStatus.AddStateOfActImplementationCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Order          = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.CustomerDebt_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Importance         = "Ordinary";
		ReportCommand.Order          = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Importance         = "Ordinary";
		ReportCommand.Order          = 2;
	EndIf;
	
	If AccessRight("View", Metadata.Reports.ActualProductCost) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager			= Metadata.Reports.ActualProductCost.FullName();
		ReportCommand.Presentation		= NStr("vi = 'Giá vốn thực tế của sản phẩm';
												|ru = 'Фактическая себестоимость продукции';
												|en = 'Actual product cost'; fa = 'بهای واقعی محصول';
												|it = 'Costo di produzione effettivo';
												|pl = 'Faktyczne koszty własne produkcji';
												|tr = 'İmal edilen ürünlerin gerçek maliyeti'");
		ReportCommand.VariantKey		= "ActualCostOfProductionReportToGiver";
		ReportCommand.Order			= 50;
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance			= "Important";
				
	EndIf;
	
	ReportToMaterialProvider2_5Localization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#Region FillType

// Returns the structure required for further use when filling out the document.
//
// Returns:
//   Structure - structure of document filling parameters.
//
Function DocumentFillingParameters() Export
	
	FillParameters = New Structure();
	
	FillParameters.Insert("AnArrayOfOrders",    Undefined);
	
	FillParameters.Insert("HeaderAttributes",   Undefined);
	
	FillParameters.Insert("DocumentName",     "ReportToMaterialProvider2_5");
	FillParameters.Insert("RegisterNameOrder", "ShipmentAndReturnReferences");
	FillParameters.Insert("FieldNameOrder",     "MaterialProviderOrder");
	
	FillParameters.Insert("KeyFields",     "Products, Characteristic");
	
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
	
	FillParameters.AnArrayOfOrders  = AnArrayOfOrders;
	FillParameters.HeaderAttributes = HeaderAttributes;
	
EndProcedure

// Creates a structure for creating an order document
//  If the header details differ in the submitted orders, an error message is displayed.
//
// Parameters:
//  ReferencesArrray    - Array - domestic consumption orders for which you need to enter an invoice.
//  OrderProperties_ - Structure, Undefined - 
//
// Returns:
//  Structure, Undefined - the structure where the header details from the order array will be placed.
//
Function InvoiceFillingData(ReferencesArrray, OrderProperties_ = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MIN(MaterialProviderOrder2_5.BusinessOperation)   AS BusinessOperation,
	|	MIN(MaterialProviderOrder2_5.Partner)                 AS Partner,
	|	MIN(MaterialProviderOrder2_5.Counterparty)              AS Counterparty,
	|	MIN(MaterialProviderOrder2_5.Contract)                 AS Contract,
	|	MIN(MaterialProviderOrder2_5.SalesOpportunity)                  AS SalesOpportunity,
	|	MIN(MaterialProviderOrder2_5.Organization)             AS Organization,
	|	MIN(MaterialProviderOrder2_5.Warehouse)                   AS Warehouse,
	|	MIN(MaterialProviderOrder2_5.Department)           AS Department,
	|	MIN(MaterialProviderOrder2_5.ARAPCurrency)    AS ARAPCurrency,
	|	MIN(MaterialProviderOrder2_5.VATTaxation)      AS VATTaxation,
	|	MIN(MaterialProviderOrder2_5.LineOfBusiness) AS LineOfBusiness,
	|	MIN(MaterialProviderOrder2_5.PriceIncludesVAT)         AS PriceIncludesVAT,
	|	MIN(MaterialProviderOrder2_5.VATRate)               AS VATRate,
	|	MAX(MaterialProviderOrder2_5.ProcessingService)    AS ProcessingService,
	|	CASE
	|		WHEN COUNT(DISTINCT
	|				CASE
	|					WHEN MaterialProviderOrder2_5.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|						THEN MaterialProviderOrder2_5.BankAccount
	|					ELSE NULL
	|				END) = 1
	|			AND COUNT(DISTINCT MaterialProviderOrder2_5.Organization) = 1
	|				THEN MAX(MaterialProviderOrder2_5.BankAccount)
	|		ELSE VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|	END                                             AS CompanyBankAccount,
	|	CASE
	|		WHEN COUNT(DISTINCT
	|				CASE
	|					WHEN MaterialProviderOrder2_5.CounterpartyBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|						THEN MaterialProviderOrder2_5.CounterpartyBankAccount
	|					ELSE NULL
	|				END) = 1
	|			AND COUNT(DISTINCT MaterialProviderOrder2_5.Counterparty) = 1
	|				THEN MAX(MaterialProviderOrder2_5.CounterpartyBankAccount)
	|		ELSE VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|	END                                             AS CounterpartyBankAccount,
	|	CASE
	|		WHEN COUNT(DISTINCT MaterialProviderOrder2_5.BusinessOperation) > 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                             AS ThereAreDifferencesEconomicOperation,
	|	CASE
	|		WHEN COUNT(DISTINCT MaterialProviderOrder2_5.Partner) > 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                             AS ThereAreDifferencesPartner,
	|	CASE
	|		WHEN COUNT(DISTINCT MaterialProviderOrder2_5.Counterparty) > 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                             AS ThereAreDifferencesCounterparty,
	|	CASE
	|		WHEN COUNT(DISTINCT MaterialProviderOrder2_5.Contract) > 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                             AS ThereAreDifferencesContract,
	|	CASE
	|		WHEN COUNT(DISTINCT MaterialProviderOrder2_5.Organization) > 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                             AS ThereAreDifferencesCompany,
	|	CASE
	|		WHEN COUNT(DISTINCT MaterialProviderOrder2_5.Warehouse) > 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                             AS ThereAreDifferencesWarehouse,
	|	CASE
	|		WHEN COUNT(DISTINCT MaterialProviderOrder2_5.Department) > 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                             AS ThereAreDifferencesDepartment,
	|	CASE
	|		WHEN COUNT(DISTINCT MaterialProviderOrder2_5.ARAPCurrency) > 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                             AS ThereAreDifferencesInCurrencyOfMutualSettlements,
	|	CASE
	|		WHEN COUNT(DISTINCT MaterialProviderOrder2_5.VATTaxation) > 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                             AS ThereAreDifferencesVATTaxation,
	|	CASE
	|		WHEN COUNT(DISTINCT MaterialProviderOrder2_5.LineOfBusiness) > 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                             AS ThereAreDifferencesInDirectionOfActivity,
	|	CASE
	|		WHEN COUNT(DISTINCT MaterialProviderOrder2_5.PriceIncludesVAT) > 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                             AS ThereAreDifferencesPriceIncludesVAT,
	|	CASE
	|		WHEN COUNT(DISTINCT MaterialProviderOrder2_5.VATRate) > 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                             AS ThereAreDifferencesInVATRate,
	|	CASE
	|		WHEN COUNT(DISTINCT MaterialProviderOrder2_5.SalesOpportunity) > 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                             AS ThereAreDifferencesSalesOpportunity
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN MaterialProviderOrder2_5.BusinessOperation = VALUE(Enum.BusinessTransactions.TollManufacturing2_5)
	|				THEN VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5)
	|			ELSE MaterialProviderOrder2_5.BusinessOperation
	|		END                                               AS BusinessOperation,
	|		MaterialProviderOrder2_5.Partner                            AS Partner,
	|		MaterialProviderOrder2_5.Counterparty                         AS Counterparty,
	|		MaterialProviderOrder2_5.Contract                            AS Contract,
	|		MaterialProviderOrder2_5.SalesOpportunity                             AS SalesOpportunity,
	|		MaterialProviderOrder2_5.Organization                        AS Organization,
	|		MaterialProviderOrder2_5.Warehouse                              AS Warehouse,
	|		MaterialProviderOrder2_5.Department                      AS Department,
	|		MaterialProviderOrder2_5.Currency                             AS ARAPCurrency,
	|		MaterialProviderOrder2_5.VATTaxation                 AS VATTaxation,
	|		MaterialProviderOrder2_5.LineOfBusiness            AS LineOfBusiness,
	|		MaterialProviderOrder2_5.VATRate                          AS VATRate,
	|		MaterialProviderOrder2_5.PriceIncludesVAT                    AS PriceIncludesVAT,
	|		MaterialProviderOrder2_5.BankAccount                     AS BankAccount,
	|		MaterialProviderOrder2_5.CounterpartyBankAccount          AS CounterpartyBankAccount,
	|		MaterialProviderOrder2_5.ProcessingService                AS ProcessingService
	|	FROM
	|		Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
	|	WHERE
	|		MaterialProviderOrder2_5.Ref IN (&ReferencesArrray)
	|
	|	UNION ALL
	|
	|	SELECT
	|		VALUE(Enum.BusinessTransactions.Subcontracting2_5) AS BusinessOperation,
	|		Contracts.Partner                                             AS Partner,
	|		Contracts.Counterparty                                          AS Counterparty,
	|		Contracts.Ref                                              AS Contract,
	|		VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)           AS SalesOpportunity,
	|		Contracts.Organization                                         AS Organization,
	|		&Warehouse                                                       AS Warehouse,
	|		Contracts.Department                                       AS Department,
	|		Contracts.ARAPCurrency                                AS ARAPCurrency,
	|		Contracts.VATTaxation                                  AS VATTaxation,
	|		Contracts.LineOfBusiness                             AS LineOfBusiness,
	|		Contracts.VATRate                                           AS VATRate,
	|		UNDEFINED                                                 AS PriceIncludesVAT,
	|		Contracts.BankAccount                                      AS BankAccount,
	|		Contracts.CounterpartyBankAccount                           AS CounterpartyBankAccount,
	|		""""                                                         AS ProcessingService
	|	FROM
	|		Catalog.CounterpartyContracts AS Contracts
	|	WHERE
	|		Contracts.Ref IN (&ReferencesArrray)
	|	) AS MaterialProviderOrder2_5
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MaterialProviderOrder2_5.Ref                           AS OrderDocument,
	|	MaterialProviderOrder2_5.Status                           AS Status,
	|	NOT MaterialProviderOrder2_5.Posted                      AS ThereAreErrorsPosted,
	|	NOT MaterialProviderOrder2_5.Status IN (&AcceptableStatuses) AS ThereAreErrorsStatus,
	|	TRUE                                            AS OrderOrder,
	|	MaterialProviderOrder2_5.BusinessOperation            AS BusinessOperation
	|FROM
	|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
	|WHERE
	|	MaterialProviderOrder2_5.Ref IN (&ReferencesArrray)
	|	AND (NOT MaterialProviderOrder2_5.Posted OR NOT MaterialProviderOrder2_5.Status IN (&AcceptableStatuses))";
	
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	
	Query.SetParameter(
		"AcceptableStatuses",
		Documents.MaterialProviderOrder2_5.ValidInputStatusesBasedOn(Metadata.Documents.ReportToMaterialProvider2_5.Name));
		
	Query.SetParameter(
		"Warehouse",
		?(ValueIsFilled(OrderProperties_) And OrderProperties_.Property("Warehouse"),
			OrderProperties_.Warehouse,
			Catalogs.Warehouses.EmptyRef()));
	
	ResultsArray = Query.ExecuteBatch();
	
	HeaderSelection = ResultsArray[0].Select();
	HeaderSelection.Next();
	
	Cancel = False;
	
	If ReferencesArrray.Count() > 1 Then
	
		VerificationFields = New Structure;
		VerificationFields.Insert("ThereAreDifferencesEconomicOperation",   NStr("ru = 'Хозяйственная операция';
																				|vi = 'Business transaction';
																				|en = 'Business transaction'; fa = 'عملیات تجاری';
																				|it = 'Operazione economica';
																				|pl = 'Operacja gospodarcza';
																				|tr = 'Ticari işlem'"));
		VerificationFields.Insert("ThereAreDifferencesPartner",                 NStr("vi = 'Bạn hàng';
																					|ru = 'Партнер';
																					|en = 'Partner'; fa = 'شریک تجاری';
																					|it = 'Partner';
																					|pl = 'Partner';
																					|tr = 'İş ortağı'"));
		VerificationFields.Insert("ThereAreDifferencesCounterparty",              NStr("vi = 'Đối tác';
																						|ru = 'Контрагент';
																						|en = 'Counterparty'; fa = 'طرف حساب';
																						|it = 'Controparte';
																						|pl = 'Kontrahent';
																						|tr = 'Cari hesap'"));
		VerificationFields.Insert("ThereAreDifferencesCompany",             NStr("vi = 'Doanh nghiệp';
																				|ru = 'Организация';
																				|en = 'Company'; fa = 'Company';
																				|it = 'Azienda';
																				|pl = 'Firma';
																				|tr = 'İş yeri'"));
		VerificationFields.Insert("ThereAreDifferencesWarehouse",                   NStr("vi = 'Kho bãi';
																						|ru = 'Склад';
																						|en = 'Warehouse'; fa = 'Warehouse';
																						|it = 'Magazzino';
																						|pl = 'Magazyn';
																						|tr = 'Ambar'"));
		VerificationFields.Insert("ThereAreDifferencesDepartment",           NStr("vi = 'Bộ phận';
																					|ru = 'Подразделение';
																					|en = 'Business unit'; fa = 'Business unit';
																					|it = 'Reparto';
																					|pl = 'Business unit';
																					|tr = 'Departmanlar'"));
		VerificationFields.Insert("ThereAreDifferencesContract",                 NStr("vi = 'Hợp đồng';
																						|ru = 'Договор';
																						|en = 'Contract'; fa = 'قرارداد';
																						|it = 'Contratto';
																						|pl = 'Umowa';
																						|tr = 'Sözleşme'"));
		VerificationFields.Insert("ThereAreDifferencesInCurrencyOfMutualSettlements",    NStr("vi = 'Tiền tệ hạch toán công nợ';
																								|ru = 'Валюта взаиморасчетов';
																								|en = 'AR/AP currency'; fa = 'ارز دریافتنی/پرداختنی';
																								|it = 'Valuta di regolamento dei conti';
																								|pl = 'Waluta rozliczeń wzajemnych';
																								|tr = 'Alacak/Borç muhasebesi para birimi'"));
		VerificationFields.Insert("ThereAreDifferencesVATTaxation",      NStr("vi = 'Chịu thuế GTGT';
																				|ru = 'Налогообложение НДС';
																				|en = 'VAT taxation'; fa = 'مشمولیت مالیات بر ارزش افزوده';
																				|it = 'Tassazione IVA';
																				|pl = 'Opodatkowanie VAT';
																				|tr = 'KDV vergilendirmesi'"));
		VerificationFields.Insert("ThereAreDifferencesInDirectionOfActivity", NStr("vi = 'Lĩnh vực hoạt động';
																					|ru = 'Направление деятельности';
																					|en = 'Line of business'; fa = 'خط کسب‌وکار';
																					|it = 'Направление деятельности';
																					|pl = 'Rodzaj działalności';
																					|tr = 'İş kolu'"));
		VerificationFields.Insert("ThereAreDifferencesPriceIncludesVAT",         NStr("vi = 'Đơn giá gồm thuế GTGT';
																						|ru = 'Цена включает НДС';
																						|en = 'Price includes VAT'; fa = 'قیمت شامل مالیات بر ارزش افزوده است';
																						|it = 'Il prezzo include l''IVA';
																						|pl = 'Cena zawiera VAT';
																						|tr = 'KDV dahil fiyat'"));
		VerificationFields.Insert("ThereAreDifferencesInVATRate",               NStr("vi = 'Thuế suất GTGT';
																					|ru = 'Ставка НДС';
																					|en = 'VAT rate'; fa = 'نرخ مالیات بر ارزش افزوده';
																					|it = 'Aliquota IVA';
																					|pl = 'Stawka VAT';
																					|tr = 'KDV oranı'"));
		VerificationFields.Insert("ThereAreDifferencesSalesOpportunity",                  NStr("vi = 'Vụ việc';
																								|ru = 'Сделка';
																								|en = 'Sales opportunity'; fa = 'فرصت فروش';
																								|it = 'Transazione';
																								|pl = 'Sales opportunity';
																								|tr = 'Satış fırsatı'"));
		
		For Each Field In VerificationFields Do
			
			If Not HeaderSelection[Field.Key] Then
				Continue;
			EndIf;
			
			Common.MessageToUser(
				StrTemplate(NStr("vi = 'Trong các lệnh đã chọn có khác biệt tại trường ""%1""';
								|ru = 'У выделенных распоряжений отличается поле ""%1""';
								|en = 'The ""%1"" field of selected references differs.'; fa = 'The ""%1"" field of selected references differs.';
								|it = 'Nelle disposizioni selezionate differisce il campo ""%1""';
								|pl = 'W zaznaczonych zamówieniach różni się pole ""%1""';
								|tr = 'Seçili emirlerin farklı bir ""%1"" alanı vardır'"), Field.Value),,,, Cancel);
			
		EndDo;
		
		If Cancel Then
			
			Common.MessageToUser(
				NStr("vi = 'Không thể nhập một chứng từ dựa trên các đơn đặt hàng được phân bổ';
					|ru = 'Ввод одного отчета давальцу на основании выделенных распоряжений невозможен';
					|en = 'Cannot generate one ""Consumption report — Subcontracting services delivered"" based on the selected references'; fa = 'Cannot generate one ""Consumption report — Subcontracting services delivered"" based on the selected references';
					|it = 'Non è possibile l''inserimento di un report al fornitore sulla base delle disposizioni selezionate';
					|pl = 'Wprowadzanie jednego raportu właścicielowi surowców na podstawie zaznaczonych zamówień jest niemożliwe';
					|tr = 'Seçili emirleri temel alarak bir ""Tüketim raporu-Verilen fason hizmetleri""ni yeni belgeye aktaramazsınız'"),,,,
				Cancel);
			
		EndIf;
	
	EndIf;
	
	ResultErrors = ResultsArray[1];
	If Not Cancel And Not ResultErrors.IsEmpty() Then
		
		Selection_Errors = ResultErrors.Select();
		While Selection_Errors.Next() Do
			
			If Selection_Errors.ThereAreErrorsPosted Then
				
				ErrorText = NStr("vi = 'Không kết chuyển chứng từ %1.
										 |Cấm nhập trên cơ sở chứng từ chưa kết chuyển.';
										 |ru = 'Документ %1 не проведен.
										 |Ввод на основании непроведенного документа запрещен.';
										 |en = 'The %1 document is not posted.
										 |Cannot generate from an unposted document.'; fa = 'The %1 document is not posted.
										 |Cannot generate from an unposted document.';
										 |it = 'Documento %1 non pubblicato.
										 |Vietato inserire sulla base di un documento non pubblicato.';
										 |pl = 'Dokument %1 nie jest zatwierdzony.
										 | Wprowadzanie na podstawie niezatwierdzonego dokumentu jest zakazane.';
										 |tr = 'Belge %1 kaydedilmemiştir.
										 | Kaydedilmemiş bir belgeye dayanarak giriş yapılmasına izin verilmez.'");
				ErrorText = StrTemplate(ErrorText, Selection_Errors.OrderDocument);
				
				Common.MessageToUser(ErrorText,,,, Cancel);
				
			EndIf;
			
			If Selection_Errors.ThereAreErrorsStatus Then
				
				ErrorText = NStr("vi = 'Chứng từ %1 ở trạng thái ""%2"".
										 |Cho phép nhập trên cơ sở chỉ ở trạng thái ""Cần sản xuất"", ""Cần giao"", ""Đã đóng"".';
										 |ru = 'Документ %1 находится в статусе ""%2"".
										 |Ввод на основании разрешен только в статусах ""К производству"", ""К отгрузке"", ""Закрыт"".';
										 |en = 'The %1 document has the ""%2"" status.
										 |Generation is allowed only for the ""For production"", ""To ship"", and ""Closed"" statuses.'; fa = 'The %1 document has the ""%2"" status.
										 |Generation is allowed only for the ""For production"", ""To ship"", and ""Closed"" statuses.';
										 |it = 'Il documento %1 si trova nello stato ""%2"".
										 |L''inserimento nella base è consentito solo negli stati ""In produzione"", ""In spedizione"", ""Chiuso"".';
										 |pl = 'Dokument %1 ma status ""%2"". 
										 |Wprowadzanie na podstawie jest dozwolone tylko w statusie ""Do wysyłki"", ""Zamknięty"".';
										 |tr = '%1belgesi ""%2"" durumundadır.
										 | Temelde girişe yalnızca ""Üretime"", ""Sevk edilecek"", ""Kapalı"" durumlarında izin verilir.'");
				ErrorText = StrTemplate(ErrorText, Selection_Errors.OrderDocument, Selection_Errors.Status);
				
				Common.MessageToUser(ErrorText,,,, Cancel);
				
			EndIf;
			
		EndDo;
			
	EndIf;
	
	HeaderAttributes = Undefined;
	
	If Not Cancel Then
		
		HeaderAttributes = New Structure;
		HeaderAttributes.Insert("BusinessOperation",	 HeaderSelection.BusinessOperation);
		HeaderAttributes.Insert("Partner",					 HeaderSelection.Partner);
		HeaderAttributes.Insert("Counterparty",				 HeaderSelection.Counterparty);
		HeaderAttributes.Insert("Contract",					 HeaderSelection.Contract);
		HeaderAttributes.Insert("SalesOpportunity",					 HeaderSelection.SalesOpportunity);
		HeaderAttributes.Insert("Organization",				 HeaderSelection.Organization);
		HeaderAttributes.Insert("Warehouse",					 HeaderSelection.Warehouse);
		HeaderAttributes.Insert("Department",			 HeaderSelection.Department);
		HeaderAttributes.Insert("ARAPCurrency",		 HeaderSelection.ARAPCurrency);
		HeaderAttributes.Insert("VATTaxation",		 HeaderSelection.VATTaxation);
		HeaderAttributes.Insert("LineOfBusiness",	 HeaderSelection.LineOfBusiness);
		HeaderAttributes.Insert("PriceIncludesVAT",			 HeaderSelection.PriceIncludesVAT);
		HeaderAttributes.Insert("CounterpartyBankAccount", HeaderSelection.CounterpartyBankAccount);
		HeaderAttributes.Insert("CompanyBankAccount", HeaderSelection.CompanyBankAccount);
		HeaderAttributes.Insert("VATRate",				 HeaderSelection.VATRate);
		HeaderAttributes.Insert("ProcessingService",		 HeaderSelection.ProcessingService);
		
	EndIf;
	
	Return HeaderAttributes;
	
EndFunction

// Fills in the table for the Balance of orders
//
// Parameters:
//  SelectionData_        - Structure - fields that will be used to select the Balance of orders to fill in
//  Table             - FormDataCollection - table of products which is set as the remains of orders
//  AnArrayOfOrders       - Array - orders for which balances will be selected
//	FillParameters - Structure - Fill-in parameters.
//
Procedure FillByOrderBalances(SelectionData_, Table, AnArrayOfOrders, FillParameters) Export
	
	DisplayMessage_1 = False;
	
	If FillParameters.Property("DisplayMessage_1") Then 
		DisplayMessage_1 = FillParameters.DisplayMessage_1;
	EndIf;
	
	CheckOrderOfCalculations = True;
	
	If FillParameters.Property("CheckOrderOfCalculations") Then 
		CheckOrderOfCalculations = FillParameters.CheckOrderOfCalculations;
	EndIf;
	
	RequestResultForOrderBalances = GetQueryResultsForOrderBalances(SelectionData_, AnArrayOfOrders);
	UBound = RequestResultForOrderBalances.Count() - 1;
	
	If RequestResultForOrderBalances[UBound].IsEmpty() Then
		
		If DisplayMessage_1
			And Not RequestResultForOrderBalances[UBound - 1].IsEmpty() Then
			Raise NStr("vi = 'Không có hàng hóa mà được phép để tạo.
										|Cần đặt thao tác ""Giao hàng"" đối với các dòng đảm bảo.';
										|ru = 'Нет товаров, доступных для оформления.
										|Необходимо установить действие ""Отгрузить"" для обеспеченных строк.';
										|en = 'There are no available goods to register.
										|Specify the ""Ship"" action for supplied lines.'; fa = 'There are no available goods to register.
										|Specify the ""Ship"" action for supplied lines.';
										|it = 'Нет товаров, доступных для оформления.
										|Необходимо установить действие ""Отгрузить"" для обеспеченных строк.';
										|pl = 'There are no available goods to register.
										|Specify the ""Ship"" action for supplied lines.';
										|tr = 'Düzenlenecek hiçbir ürün mevcut değildir.
										|Tedarik satırları için ""Sevk et"" eylemini yapılandırmanız gerekmektedir.'");
		ElsIf DisplayMessage_1 Then
			Raise NStr("vi = 'Không có hàng hóa khả dụng để điền.';
						|ru = 'Нет товаров, доступных для оформления.';
						|en = 'There are no available goods to register.'; fa = 'There are no available goods to register.';
						|it = 'Non vi sono merci disponibili per la formalizzazione.';
						|pl = 'Brak towarów, dostępnych do rejestracji.';
						|tr = 'Düzenlenecek mal bulunmamaktadır.'");
		Else
			Return;
		EndIf;
		
	EndIf;
	
	ArrayOfGiversOrders = New Array;
	ArrayOfARAPObjectsSettings = New Array;
	
	SamplingByBalance = RequestResultForOrderBalances[UBound].Select();
	While SamplingByBalance.NextByFieldValue("MaterialProviderOrder") Do
		ArrayOfGiversOrders.Add(SamplingByBalance.MaterialProviderOrder);
		If CheckOrderOfCalculations
			And ValueIsFilled(SamplingByBalance.ARAPObjectSettings)
			And ArrayOfARAPObjectsSettings.Find(SamplingByBalance.ARAPObjectSettings) = Undefined Then
			ArrayOfARAPObjectsSettings.Add(SamplingByBalance.ARAPObjectSettings);
		EndIf;
	EndDo;
	
	If AnArrayOfOrders = Undefined
		And CheckOrderOfCalculations 
		And ArrayOfARAPObjectsSettings.Count() > 1 Then
		Common.MessageToUser(NStr("vi = 'Trong các đơn hàng đã tìm thấy, khác trường ""Trình tự hạch toán""';
									|ru = 'У найденных заказов отличается поле ""Порядок расчетов""';
									|en = 'The ""Payment terms"" field data is different for the found orders'; fa = 'The ""Payment terms"" field data is different for the found orders';
									|it = 'У найденных заказов отличается поле ""Порядок расчетов""';
									|pl = 'The ""Payment terms"" field data is different for the found orders';
									|tr = 'Bulunan siparişlerin farklı bir ""Alacak/Borç muhasebesi prosedürü"" alanı mevcut'"));
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ArrayOfGiversOrders", ArrayOfGiversOrders);
	Query.SetParameter("DocumentCurrency",        SelectionData_.Currency);
	
	Query.Text =
	"SELECT ALLOWED
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY)                  AS Date,
	|	TheOrdersTable.Currency                                     AS Currency,
	|	TheOrdersTable.PriceIncludesVAT                            AS PriceIncludesVAT,
	|	TheOrdersTable.VATRate                                  AS VATRate,
	|	TheOrdersTable.Organization.LocalAccountingCurrency AS BaseCurrency,
	|	TheOrdersTable.Ref                                     AS MaterialProviderOrder,
	|	TheOrdersTable.Currency <> &DocumentCurrency                 AS ConvertToDocumentCurrency
	|FROM
	|	Document.MaterialProviderOrder2_5 AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN(&ArrayOfGiversOrders)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY)                  AS Date,
	|	TheOrdersTable.Currency                                     AS Currency,
	|	TheOrdersTable.Organization.LocalAccountingCurrency AS BaseCurrency
	|FROM
	|	Document.MaterialProviderOrder2_5 AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN(&ArrayOfGiversOrders)
	|	AND TheOrdersTable.Currency <> &DocumentCurrency";
	
	ResultsArray = Query.ExecuteBatch();
	
	ResultOrderDetails = ResultsArray[0];
	OrderDetails_          = ResultOrderDetails.Select();
	
	ResultSelection          = ResultsArray[1];
		
	TableOfExchangeRates = New ValueTable;
	TableOfExchangeRates.Columns.Add("Currency",          New TypeDescription("CatalogRef.Currencies"));
	TableOfExchangeRates.Columns.Add("BaseCurrency",   New TypeDescription("CatalogRef.Currencies"));
	TableOfExchangeRates.Columns.Add("Date",            New TypeDescription("Date"));
	TableOfExchangeRates.Columns.Add("CourseNumerator",   New TypeDescription("Number"));
	TableOfExchangeRates.Columns.Add("CourseDenominator", New TypeDescription("Number"));
	TableOfExchangeRates.Indexes.Add("Currency, BaseCurrency, Date");
	
	CurrentDate = CurrentSessionDate();
	Currencies      = New Array;
	
	Selection = ResultSelection.Select();
	While Selection.Next() Do
		
		NewRow = TableOfExchangeRates.Add();
		FillPropertyValues(NewRow, Selection);
		
		FillPropertyValues(
			NewRow,
			ProcessingOfExchangeRatesTM.GetCurrencyRate(Selection.Currency, Selection.Date, Selection.BaseCurrency));
		
		If Currencies.Find(Selection.BaseCurrency) = Undefined Then
			
			NewRow = TableOfExchangeRates.Add();
			FillPropertyValues(NewRow, Selection);
			
			FillPropertyValues(
				NewRow,
				ProcessingOfExchangeRatesTM.GetCurrencyRate(SelectionData_.Currency, CurrentDate, Selection.BaseCurrency));
			
			Currencies.Add(Selection.BaseCurrency);
			
		EndIf;
		
	EndDo;
	
	SamplingByBalance.Reset();
	While SamplingByBalance.Next() Do
		
		RecalculateAmounts = Not SamplingByBalance.Count = SamplingByBalance.QuantityInOrder;
		
		ExcludeProperties_ = Undefined;
		If RecalculateAmounts Then
			// If it is necessary to recalculate the amounts, the listed details will be recalculated based on the amount of mutual settlements.
			ExcludeProperties_ = "Sum, VATAmount";
		EndIf;
		
		TableRow = Table.Add();
		FillPropertyValues(TableRow, SamplingByBalance,, ExcludeProperties_);
		
		If RecalculateAmounts Then
			TableRow.AmountIncludingVAT = SamplingByBalance.SumBalance;
		EndIf;
		
		OrderDetails_.Reset();
		OrderFound = OrderDetails_.FindNext(TableRow.MaterialProviderOrder, "MaterialProviderOrder");
		
		If OrderFound
			And OrderDetails_.ConvertToDocumentCurrency Then
			
			FilterParameters = New Structure("Currency, BaseCurrency, Date");
			FillPropertyValues(FilterParameters, OrderDetails_);
			
			CurrencyExchangeRate = TableOfExchangeRates.FindRows(FilterParameters);
			
			FilterParameters.Currency = SelectionData_.Currency;
			FilterParameters.Date   = CurrentDate;
			NewCurrencyRate = TableOfExchangeRates.FindRows(FilterParameters);
			
			If CurrencyExchangeRate.Count() = 1
				And NewCurrencyRate.Count() = 1 Then
				
				TableRow.Price =
					ProcessingOfExchangeRatesTM.ConvertAtRate(TableRow.Price, CurrencyExchangeRate[0], NewCurrencyRate[0]);
				
				TableRow.AmountIncludingVAT =
					ProcessingOfExchangeRatesTM.ConvertAtRate(TableRow.AmountIncludingVAT, CurrencyExchangeRate[0], NewCurrencyRate[0]);
				
				RecalculateAmounts = True;
				
			EndIf;
			
		EndIf;
		
		If OrderFound And RecalculateAmounts Then
			
			PriceManagementSystem.RecalculateAmountsInRowWithVAT(
				TableRow,
				OrderDetails_.PriceIncludesVAT,
				False,
				False,
				OrderDetails_.ConvertToDocumentCurrency);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns a list of details that can be used to group orders within a single report.
//
// Returns:
//  String - the names of the details, separated by commas.
//
Function KeyFieldsOfHeader() Export
	
	If GetFunctionalOption("UseReportToMaterialProviderBySeveralOrders2_5") Then
		
		Return
			"BusinessOperation,
			|Organization,
			|Partner,
			|Counterparty,
			|Contract,
			|Warehouse,
			|Currency,
			|SalesOpportunity,
			|VATRate,
			|VATTaxation,
			|ARAPObjectSettings,
			|LineOfBusiness";
		
	Else
		
		Return "Ref, Contract";
		
	EndIf;
	
EndFunction

#EndRegion

#Region Purpose

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	// Template for output products
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness      = "Object.LineOfBusiness";
	DestinationPattern.Partner                      = "Object.Partner";
	DestinationPattern.Contract                      = "Object.Contract";
	DestinationPattern.RecordsInWarehouseRegisters = "TRUE";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	
	// Remnants of goods in the warehouse.
	DescriptionOfColumns =
		Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.ManufacturedProduct.Purpose");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	DescriptionOfColumns.DefaultColumns.Add("InStock");
	
	DescriptionOfColumns.DataPaths.Products   = "Object.ManufacturedProduct.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.ManufacturedProduct.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse          = "Object.ManufacturedProduct.Warehouse";
	
	Return FormTemplate;
	
EndFunction

// Returns the structure of document processing order parameters
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	
// Returns:
//  See AssignmentsServer.ProcedureForFillingOutAssignmentsInDocument
//
Function ProcedureForFillingOutAssignmentsInDocument(Form) Export
	
	DocumentProcessingProcedure = AssignmentsServer.ProcedureForFillingOutAssignmentsInDocument();
	DocumentProcessingProcedure.DocumentDefinesFunctionAssignmentTemplate = True;
	DocumentProcessingProcedure.OrderDetailsName = "ReportOnOrders";
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "ManufacturedProduct";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType, RowCode");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("ManufacturedProduct", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

// Returns the destination template
// 
// Parameters:
//  Object        - DocumentObject.ReportToMaterialProvider2_5, FormDataStructure - 
//  MaterialProviderOrder - DocumentRef.MaterialProviderOrder2_5, Undefined - 
// 
// Returns:
//  Structure - See Catalogs.Assignments.NewSubmenuTemplate
//
Function DestinationPattern(Object, MaterialProviderOrder = Undefined) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	
	If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
		DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	DestinationPattern.Partner       = Object.Partner;
	DestinationPattern.Contract       = Object.Contract;
	DestinationPattern.AssignmentType = Enums.AssignmentTypes.Giveaway2_5;
	
	If ValueIsFilled(MaterialProviderOrder)
		And Constants.OptionOfManufacturedProductAssignmentUponSubcontractingServicesDelivered.Get() = Enums.AssignmentAtSubcontractingServicesDelivered.MaterialProviderOrder Then
		DestinationPattern.OrderDocument     = MaterialProviderOrder;
	ElsIf Not ValueIsFilled(Object.LineOfBusiness) Then
		ContractLB = Common.ObjectAttributeValue(Object.Contract, "LineOfBusiness");
		If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(ContractLB) Then
			DestinationPattern.LineOfBusiness = ContractLB;
		EndIf;
	EndIf;
	
	Return DestinationPattern;
	
EndFunction

#EndRegion

#Region LineOfBusiness

// Returns the order in which the document is processed when the direction of activity changes
// Parameters:
//  Form - ClientApplicationForm - 
//
// Returns:
// 	Structure - See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
//
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	ProcessingProcedure_ = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	ProcessingProcedure_.NamesOfTablePartsToFillInAssignment = "ManufacturedProduct";
	ProcessingProcedure_.StringProcessingConditions.Insert(
		"ManufacturedProduct",
		LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType,RowCode"));
	
	Return ProcessingProcedure_;
	
EndFunction

#EndRegion

#Region TransactionsForLocalAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return ReportToMaterialProvider2_5Localization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the temporary table query.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return ReportToMaterialProvider2_5Localization.RequestTextTTReflectedInLocalAccounting();

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
	|	AND ValueAllowed(Warehouse)
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(Partner)";

EndProcedure

// End StandardSubsystems.AccessManagement

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

#EndRegion

#Region Rounding

// Returns the parameters for rounding
// 
// Returns:
//  See ProductsServer.ParametersForCheckingFillingQuantity
// 
Function RoundingParameters() Export
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.TSName                          = "ManufacturedProduct";
	CheckParameters.CheckPossibilityOfRounding = False;
	
	Return CheckParameters;

EndFunction

#EndRegion

#Region Other

// This function determines the details of the selected document
//
// Parameters:
//	DocumentRef - DocumentRef.ReportToMaterialProvider2_5 - Link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	AttributesData = New Structure;
	AttributesData.Insert("Date",                    Date(1, 1, 1));
	AttributesData.Insert("ByOrder",                False);
	AttributesData.Insert("Organization",             Catalogs.Companies.EmptyRef());
	AttributesData.Insert("Partner",                 Catalogs.Partners.EmptyRef());
	AttributesData.Insert("Counterparty",              Catalogs.Counterparties.EmptyRef());
	AttributesData.Insert("Contract",                 Catalogs.CounterpartyContracts.EmptyRef());
	AttributesData.Insert("ARAPCurrency",    Catalogs.Currencies.EmptyRef());
	AttributesData.Insert("Rate",                    1);
	AttributesData.Insert("Repetition",               1);
	AttributesData.Insert("DocumentAmount",          0);
	AttributesData.Insert("AmountARAP",     0);
	AttributesData.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
	AttributesData.Insert("ARAPObjectSettings",         Enums.ARAPObjectSettings.EmptyRef());
	AttributesData.Insert("BusinessOperation",   Enums.BusinessTransactions.EmptyRef());
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentData.Date                    AS Date,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	DocumentData.ReportOnOrders          AS ByOrder,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Partner                 AS Partner,
	|	DocumentData.Counterparty              AS Counterparty,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.ARAPCurrency    AS ARAPCurrency,
	|	DocumentData.CourseNumerator           AS Rate,
	|	DocumentData.CourseDenominator         AS Repetition,
	|	DocumentData.DocumentAmount          AS DocumentAmount,
	|	CASE
	|		WHEN DocumentData.Posted
	|			THEN DocumentData.AmountARAP
	|		ELSE 0
	|	END                                   AS AmountARAP,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ARAPObjectSettings         AS ARAPObjectSettings
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef";
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		
		Selection = Result.Select();
		Selection.Next();
		
		FillPropertyValues(AttributesData, Selection);
		
	EndIf;
	
	Return AttributesData;

EndFunction

// Initializes the status structure of the document
//
// Returns:
//	Structure - The structure of the report parameters.
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	
	StructureState.Insert("DisplayCalculationsWithCustomersTable",        1);
	StructureState.Insert("DisplayTableOfServicesToGiverForRegistration", 2);
	StructureState.Insert("ThisIsAnInvoice",                            True);
	StructureState.Insert("ThereAreSummaryShipmentIndicators",          False);
	StructureState.Insert("NameTSGoodsShipment",                     "ManufacturedProduct");
	StructureState.Insert("RegisterNameShipmentOfServices",                "ShipmentAndReturnReferences");
	StructureState.Insert(
		"StructureOfAdditionalRequests",
		New Structure("TableScheduleOfPaymentByInvoice", RequestTextTableSettlementsWithCustomersDocumentState()));
	
	Return StructureState
	
EndFunction

#EndRegion

#Region VATAccounting

// Initializes the parameters for filling in VAT taxation
//
// Parameters:
//  Object		- DocumentObject.ReportToMaterialProvider2_5, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInVATTaxation_(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	FillParameters.Organization				= Object.Organization;
	FillParameters.Date					= Object.Date;
	FillParameters.Contract					= Object.Contract;
	FillParameters.LineOfBusiness	= Object.LineOfBusiness;
	FillParameters.ReportToMaterialProvider			= True;
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for registering invoices (issued)
//
// Parameters:
//  Object		- DocumentObject.ReportToMaterialProvider2_5, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived
//
Function ParametersForRegisteringInvoicesIssued(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	RegistrationParameters.Ref				  = Object.Ref;
	RegistrationParameters.Date				  = Object.Date;
	RegistrationParameters.Organization		  = Object.Organization;
	RegistrationParameters.Counterparty			  = Object.Counterparty;
	RegistrationParameters.VATTaxation   = Object.VATTaxation;
	RegistrationParameters.ImplementationOfWorksServices = True;
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

#Region ARAPAccounting

// Settlement parameters.
// 
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters - Array of parameters of the functions of the settlement mechanism
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase               = True;
	ParametersStructure.PaymentType_                     = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	ParametersStructure.ARAPCurrency            = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP             = "Object.AmountARAP";
	ParametersStructure.AmountARAPByPackage       = "";
	
	ParametersStructure.CourseNumerator                   = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                 = "Object.CourseDenominator";
	
	ParametersStructure.PathToTSData                   = "Object.ManufacturedProduct";
	ParametersStructure.PropsNameTSOrder             = "MaterialProviderOrder";
	ParametersStructure.PathToTSDataPaymentDecryption = "Object.ARAPDetails";
	ParametersStructure.PathToTSDataPaymentSteps        = "Object.PaymentScheduleSteps";
	ParametersStructure.PaymentStepsText              = "Form.PaymentStepsText";
	ParametersStructure.SourceOfAmountsTabularPart      = True;
	
	ParametersStructure.Terms                      = "";
	ParametersStructure.Manager                        = "Object.Manager";
	ParametersStructure.InvoiceForOrders              = "Object.ReportOnOrders";
	ParametersStructure.OrderBase                  = "Object.MaterialProviderOrder";
	ParametersStructure.PaymentID            = "";
	ParametersStructure.PaymentSchedule                    = "Object.PaymentSchedule";
	
	ParametersStructure.FormItems.LabelCurrencies                    = "LabelCurrencies";
	ParametersStructure.FormItems.InscriptionStages                     = "DecorationPaymentSteps";
	ParametersStructure.FormItems.InscriptionCalculations                   = "Calculations";
	ParametersStructure.FormItems.PaymentSettlement                      = "PaymentSettlement";
	ParametersStructure.FormItems.AmountOfTSSettlements            = "ManufacturedProductAmountARAP";
	ParametersStructure.FormItems.DebtLimitationText    = "TextAllowedCreditBalance";
	ParametersStructure.FormItems.DebtLimitation = "ImageShipmentProhibited";
	ParametersStructure.FormItems.FinancialAccountingGroup           = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness          = "LineOfBusiness";
	
	ParametersStructure.DocumentAmountForm                            = "Form.AmountTotal";
	
	ParametersStructure.InvoiceForSeveralOrdersIsPossible =
		GetFunctionalOption("UseReportToMaterialProviderBySeveralOrders2_5");
	
	ParametersStructure.ARAPObject                       = "Object.ManufacturedProduct.ARAPObject";
	
	ParametersStructure.TSP                                  = "Object.Warehouse";
	
	Return ParametersStructure;
	
EndFunction

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	Return "Warehouse";
	
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  Structure - See ProductsClientServer.SeriesSpecificationParameters
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	
	SeriesSpecificationParameters.FullObjectName = "Document.ReportToMaterialProvider2_5";
	SeriesSpecificationParameters.NameTSGoods      = "ManufacturedProduct";
	SeriesSpecificationParameters.TSSeriesName       = "ManufacturedProduct";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, True);
	
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.AdditionalFieldNames.Add("Warehouse");
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentToCustomer);
		
	SeriesSpecificationParameters.ThisIsAnInvoice         = True;
	SeriesSpecificationParameters.ShipmentPlanning = True;
	
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Goods_MaterialProviderOrder");
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Goods_RowCode");

	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the value of the receipt or shipment order.
//
// Parameters:
//  FieldValuesToIdentifyReferences - Structure - the composition of the fields is determined by the value
//  of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//  DocumentRef, Undefined - a link to an order for performing a warehouse operation.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	If FieldValuesToIdentifyReferences.Goods_RowCode <> 0 Then 
		Return FieldValuesToIdentifyReferences.Goods_MaterialProviderOrder;
	Else
		Return Undefined;
	EndIf;
EndFunction

// Returns the request text for calculating the statuses for specifying series
//
// Parameters:
//  SeriesSpecificationParameters - See ProductsClientServer.SeriesSpecificationParameters
//
//  Returns:
//   String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.Warehouse               AS Warehouse,
	|	Goods.Products        AS Products,
	|	Goods.Series               AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Count          AS Count
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		ELSE 0
	|	END                      AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON BatchAccountingPolicies.Warehouse = Goods.Warehouse
	|		 AND CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
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

// Returns the parameters of the selection of articles and analyst.
// 
// Returns:
// 	Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ArticleSelectionOptions = New Array;
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.DataPath				   = "Object.ManufacturedProduct";
	ChoiceParameters.AssetRef					   = "ExpenseItem";
	ChoiceParameters.ArticleType				   = "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem		   = True;
	ChoiceParameters.DimensionOfExpenses		   = "DimensionOfExpenses";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension   = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	
	ChoiceParameters.FormItems.AssetRef.Add("ManufacturedProductExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ManufacturedProductDimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("ManufacturedProductAssetsLiabilitiesDimension");
	
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
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	
	SetupParameters.AvailabilityByOperation = True;
	SetupParameters.ArticleType   = "ArticleType";
	SetupParameters.DataPath = "Object.ManufacturedProduct";
	
	SetupParameters.ConditionsForAvailabilityOfAccountingAccountInLines.Insert("ToExpenseAs", True);
	
	SetupParameters.FormItems.Add("ManufacturedProductTransactionRecordingPresentation");
	
	SettingsParameters.Add(SetupParameters);
	
	Return SettingsParameters;
	
EndFunction

#EndRegion

#Region BasisForPrint

// Returns the base structure based on document data
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.ReportToMaterialProvider2_5 - The object of the document for which you want to get the text of the base.
//
// Returns:
//	Structure - Structure with the name, date and number of the foundation.
//
Function StructureOfBaseForPrinting(Object) Export
	
	Return BaseStructure(Object);
	
EndFunction

// Returns a table of default values for the "Base" attribute"
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.ReportToMaterialProvider2_5 - The document object for which you want to get the selection list.
//
// Returns:
//	ValueTable - A table of values with the details of the bases.
//
Function PrintBasisTable(Object) Export
	
	TableOfBases_ = New ValueTable;
	TableOfBases_.Columns.Add("Basis",      New TypeDescription("String",,,,New StringQualifiers(300)));
	TableOfBases_.Columns.Add("ReferenceDocumentDateForPrintForms",  New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.Date))); 
	TableOfBases_.Columns.Add("BaseDocumentNumber", New TypeDescription("String",,,,New StringQualifiers(128)));
	
	BaseStructure = BaseStructure(Object);
	If ValueIsFilled(BaseStructure.Basis) Then
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
		
		If ValueIsFilled(BaseStructure.ReferenceDocumentDateForPrintForms) And ValueIsFilled(BaseStructure.BaseDocumentNumber) Then
			ExtendedText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 số %2 ngày %3';
						|ru = '%1 № %2 от %3';
						|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
						|it = '%1 № %2 dal %3';
						|pl = '%1 nr %2 z dnia %3.';
						|tr = '%3 itibarıyla %2 numaralı %1'"),
					BaseStructure.Basis, BaseStructure.BaseDocumentNumber, Format(BaseStructure.ReferenceDocumentDateForPrintForms, "DLF=DD"));
			AddedRow = TableOfBases_.Add();
			FillPropertyValues(AddedRow, BaseStructure);
			AddedRow.Basis = ExtendedText;
		EndIf;
		
	EndIf;
	
	Return TableOfBases_;
	
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
		"ru = 'Отчет давальцу';
		|vi = 'Consumption report — Subcontracting services delivered';
		|en = 'Consumption report — Subcontracting services delivered'; fa = 'گزارش مصرف — خدمات پیمانکاری فرعی ارائه‌شده';
		|it = 'Report al committente di materie prime';
		|pl = 'Raport dla właściciela surowców';
		|tr = 'Tüketim raporu-Verilen fason hizmetleri'",
		DefaultLanguageCode);
		
	Return SynonymForInformationDatabaseEntry;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.Text =
	"SELECT
	|	DocumentData.Ref                                                 AS Ref,
	|	DocumentData.BusinessOperation                                  AS BusinessOperation,
	|	DocumentData.Organization                                            AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency             AS LocalAccountingCurrency,
	|	DocumentData.Partner                                                AS Partner,
	|	DocumentData.Counterparty                                             AS Counterparty,
	|	DocumentData.Date                                                   AS Period,
	|	DocumentData.Number                                                  AS Number,
	|	DocumentData.MaterialProviderOrder                                          AS MaterialProviderOrder,
	|	DocumentData.Currency                                                 AS Currency,
	|	DocumentData.Department                                          AS Department,
	|	DocumentData.Department.OptionOfAssignedAccountingOfGoods         AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.SalesOpportunity                                                 AS SalesOpportunity,
	|	ISNULL(DocumentData.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
	|	DocumentData.PriceIncludesVAT                                        AS PriceIncludesVAT,
	|	DocumentData.ARAPCurrency                                   AS ARAPCurrency,
	|	DocumentData.ReportOnOrders                                         AS ReportOnOrders,
	|	DocumentData.PaymentMethod                                            AS PaymentMethod,
	|	DocumentData.Contract                                                AS Contract,
	|	PRESENTATION(DocumentData.Contract)                                 AS ContractPresentation,
	|	DocumentData.Manager                                               AS Manager,
	|	DocumentData.Author                                                  AS Author,
	|	DocumentData.Comment                                            AS Comment,
	|	DocumentData.VATTaxation                                     AS VATTaxation,
	|	DocumentData.FinancialAccountingGroup                                 AS FinancialAccountingGroup,
	|	DocumentData.ProcessingService                                    AS Content,
	|	DocumentData.DocumentAmount                                         AS DocumentAmount,
	|	DocumentData.Posted                                               AS Posted,
	|	DocumentData.DeletionMark                                        AS DeletionMark,
	|	UNDEFINED                                                           AS AdjustmentPeriod_,
	|	
	|	CASE
	|		WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                                  AS ContractSettlements,
	|	
	|	CASE
	|		WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                                  AS CalculationsOnInvoices,
	|	
	|	DocumentData.Contract.AllowableAmountPayable                   AS AllowableAmountPayable,
	|	DocumentData.LineOfBusiness                                AS LineOfBusiness,
	|	
	|	CASE
	|		WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|			AND ISNULL(DocumentData.Contract.ExecutionScheduleIsSpecified, FALSE)
	|				THEN TRUE
	|		ELSE FALSE
	|	END                                                                  AS ExecutionScheduleInContract
	|	
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Query.SetParameter("Ref", DocumentRef);
	
	Result = Query.Execute();
	
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
						Attributes.Currency, Attributes.ARAPCurrency, Attributes.Period, Attributes.Organization);
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	Query.SetParameter("ManagementAccountingCurrency",      Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("DisplayBasicUnitsOfMeasureInPrintForms", Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get());
	
	Query.SetParameter(
		"AccountingDimensionByPartners",
		InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(Attributes));
		
	Query.SetParameter(
		"BusinessTransactionSetting",
		Catalogs.BusinessTransactionsSettings.ReportToMaterialProvider2_5);
	
	Query.SetParameter(
		"MetadataIdentifier",
		Common.MetadataObjectID(TypeOf(DocumentRef)));
		
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	
	ContractInformation = Undefined;
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation =
			StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.ContractPresentation);
	EndIf;
	Query.SetParameter("ContractInformation", ContractInformation);
	
	Query.SetParameter(
		"AppointmentWithoutOrder",
		Catalogs.Assignments.FindByTemplate(DestinationPattern(Query.Parameters)));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure InitializeProductAnalysisKeys(Attributes)

	Query = New Query(
	"SELECT DISTINCT
	|	DimensionsData.StorageLocation     AS StorageLocation,
	|	DimensionsData.Products      AS Products,
	|	DimensionsData.Characteristic    AS Characteristic,
	|	DimensionsData.Series             AS Series,
	|	DimensionsData.Purpose        AS Purpose,
	|	DimensionsData.ProductCostElement AS ProductCostElement
	|FROM
	|	(
	// Analytics without appointments
	|	SELECT
	|		TableServices.ItemsLocationAttributes.StorageLocation     AS StorageLocation,
	|		TableServices.ItemsLocationAttributes.Products      AS Products,
	|		TableServices.ItemsLocationAttributes.Characteristic    AS Characteristic,
	|		TableServices.ItemsLocationAttributes.Series             AS Series,
	|		VALUE(Catalog.Assignments.EmptyRef)               AS Purpose,
	|		TableServices.ItemsLocationAttributes.ProductCostElement AS ProductCostElement
	|	FROM
	|		Document.ReportToMaterialProvider2_5.ManufacturedProduct AS TableServices
	|	WHERE
	|		TableServices.Ref = &Ref
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|	) AS DimensionsData
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON DimensionsData.StorageLocation    = Dimension.StorageLocation
	|	AND DimensionsData.Products      = Dimension.Products
	|	AND DimensionsData.Characteristic    = Dimension.Characteristic
	|	AND DimensionsData.Series             = Dimension.Series
	|	AND DimensionsData.Purpose        = Dimension.Purpose
	|	AND DimensionsData.ProductCostElement = Dimension.ProductCostElement
	|
	|WHERE
	|	Dimension.DimensionKey IS NULL
	|");
	
	Query.SetParameter("Ref", Attributes.Ref);
	Query.SetParameter("KeepRecordsOfInventoryCostByAssignments", Attributes.KeepRecordsOfInventoryCostByAssignments);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection)
	EndDo;

EndProcedure

Function QueryTextTTManufacturedProduct(Query, QueryTexts) Export
	
	RegisterName = "TTManufacturedProduct";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	InitializeProductAnalysisKeys(Query.Parameters);
	
	QueryText =
	"SELECT
	|	ProductTable.Ref                 AS Ref,
	|	ProductTable.LineNumber            AS LineNumber,
	|	UNDEFINED                            AS InventoryOwnerAttribute,
	|	ProductTable.MaterialProviderOrder          AS MaterialProviderOrder,
	|	ProductTable.Products           AS Products,
	|	ProductTable.Characteristic         AS Characteristic,
	|	ProductTable.Purpose             AS Purpose,
	|	ProductTable.RowCode              AS RowCode,
	|	ProductTable.GLAccountSettings   AS GLAccountSettings,
	|	ProductTable.RowID    AS RowID,
	|	ProductTable.RowID    AS FinRecordID,
	|	ProductTable.Count             AS Count,
	|	ProductTable.Sum                  AS Sum,
	|	ProductTable.VATAmount               AS VATAmount,
	|	ProductTable.AmountIncludingVAT              AS AmountIncludingVAT,
	|	
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)         AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)        AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)       AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)      AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)         AS VATAmountCompl,
	|	
	|	ProductTable.VATRate              AS VATRate,
	|	ProductTable.AmountARAP    AS AmountARAP,
	|	0                                       AS ManualDiscount,
	|	0                                       AS DiscountMarkupAmount,
	|	ProductTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment_.DimensionKey    AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	Analysts.StorageLocation                 AS Warehouse,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesBySalesOpportunities
	|			AND &EnabledGoodsAssignmentInSalesOpportunity
	|				THEN &SalesOpportunity
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			AND &OptionOfAssignedAccountingOfGoods =
	|						VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|				THEN &Manager
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			AND &OptionOfAssignedAccountingOfGoods =
	|						VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END                                   AS FinancialAccountingDimension,
	|	ProductTable.ToExpenseAs       AS ToExpenseAs,
	|	ProductTable.ARAPObject         AS ARAPObject
	|INTO TTManufacturedProduct
	|FROM
	|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS ProductTable
	|	
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Analysts
	|		ON Analysts.Ref = ProductTable.ItemsLocationAttributes
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment_
	|	ON Analysts.Series            = AnalyticsWithoutAssignment_.Series
	|	AND Analysts.StorageLocation     = AnalyticsWithoutAssignment_.StorageLocation
	|	AND Analysts.Products      = AnalyticsWithoutAssignment_.Products
	|	AND Analysts.Characteristic    = AnalyticsWithoutAssignment_.Characteristic
	|	AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment_.Purpose
	|	AND Analysts.ProductCostElement = AnalyticsWithoutAssignment_.ProductCostElement
	|	
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref              = ProductTable.Ref
	|	 AND Amounts.RowID = ProductTable.RowID
	|WHERE
	|	ProductTable.Ref = &Ref
	|	AND ProductTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND ProductTable.ItemsLocationAttributes NOT IN
	|		(SELECT DISTINCT
	|			InventoryKinds.ItemsLocationAttributes
	|		FROM
	|			Document.ReportToMaterialProvider2_5.InventoryKinds AS InventoryKinds
	|		WHERE
	|			InventoryKinds.Ref = &Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	ProductTable.Ref                 AS Ref,
	|	ProductTable.LineNumber            AS LineNumber,
	|	ProductTable.InventoryOwnerAttribute             AS InventoryOwnerAttribute,
	|	ProductTable.MaterialProviderOrder          AS MaterialProviderOrder,
	|	Analysts.Products                  AS Products,
	|	Analysts.Characteristic                AS Characteristic,
	|	Analysts.Purpose                    AS Purpose,
	|	0                                       AS RowCode,
	|	ProductTable.GLAccountSettings   AS GLAccountSettings,
	|	ProductTable.RowID    AS RowID,
	|	ProductTable.FinRecordID AS FinRecordID,
	|	ProductTable.Count             AS Count,
	|	ProductTable.Sum                  AS Sum,
	|	ProductTable.VATAmount               AS VATAmount,
	|	ProductTable.AmountIncludingVAT              AS AmountIncludingVAT,
	|	
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)         AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)        AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)       AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)      AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)         AS VATAmountCompl,
	|	
	|	ProductTable.VATRate              AS VATRate,
	|	ProductTable.AmountARAP    AS AmountARAP,
	|	0                                       AS ManualDiscount,
	|	0                                       AS DiscountMarkupAmount,
	|	ProductTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment_.DimensionKey    AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	Analysts.StorageLocation                 AS Warehouse,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesBySalesOpportunities
	|			AND &EnabledGoodsAssignmentInSalesOpportunity
	|				THEN &SalesOpportunity
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			AND &OptionOfAssignedAccountingOfGoods =
	|						VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|				THEN &Manager
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			AND &OptionOfAssignedAccountingOfGoods =
	|						VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END                                   AS FinancialAccountingDimension,
	|	ProductTable.ToExpenseAs       AS ToExpenseAs,
	|	ProductTable.ARAPObject         AS ARAPObject
	|FROM
	|	Document.ReportToMaterialProvider2_5.InventoryKinds AS ProductTable
	|
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Analysts
	|		ON Analysts.Ref = ProductTable.ItemsLocationAttributes
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment_
	|	ON Analysts.Series            = AnalyticsWithoutAssignment_.Series
	|	AND Analysts.StorageLocation     = AnalyticsWithoutAssignment_.StorageLocation
	|	AND Analysts.Products      = AnalyticsWithoutAssignment_.Products
	|	AND Analysts.Characteristic    = AnalyticsWithoutAssignment_.Characteristic
	|	AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment_.Purpose
	|	AND Analysts.ProductCostElement = AnalyticsWithoutAssignment_.ProductCostElement
	|	
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref              = ProductTable.Ref
	|	 AND Amounts.RowID = ProductTable.FinRecordID
	|WHERE
	|	ProductTable.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers)
	
	RegisterName = "RevenueAndCOGS";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTManufacturedProduct", QueryTexts) Then
		QueryTextTTManufacturedProduct(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	ProductTable.LineNumber                           AS LineNumber,
	|	&Period                                                AS Period,
	|	&AdjustmentPeriod_                                   AS AdjustmentPeriod_,
	|	&Department                                         AS Department,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN ProductTable.ItemsLocationAttributes
	|		ELSE ProductTable.AnalysisOfAccountingForProductsWithoutAssignment
	|	END                                                  AS ItemsLocationAttributes,
	|	&AccountingDimensionByPartners                             AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN ProductTable.ToExpenseAs
	|			THEN VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses)
	|		ELSE &BusinessOperation END                 AS BusinessOperation,
	|	CASE
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale)
	|			THEN VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|		ELSE &VATTaxation
	|	END                                                  AS VATTaxation,
	|	VALUE(Enum.InventoryTypes.OperationService)              AS InventoryType,
	|	UNDEFINED                                           AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN ProductTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|	END AS AccountingSection,
	|	ProductTable.FinancialAccountingDimension             AS FinancialAccountingDimension,
	|	&VATTaxation                                    AS VATActivityType,
	|
	|	&Manager                                              AS Manager,
	|	0                                                      AS Cost,
	|	ProductTable.Count                            AS Count,
	|
	|	CASE WHEN &ReportOnOrders  AND ProductTable.MaterialProviderOrder <> VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|		THEN ProductTable.MaterialProviderOrder
	|		ELSE &Ref
	|	END 												   AS SalesOrder,
	|
	|	ProductTable.AmountIncludingVATMan                          AS RevenueAmount,
	|	ProductTable.AmountExcludingVATMan                        AS RevenueAmountExcludingVAT,
	|	ProductTable.AmountExcludingVATCompl                       AS RevenueAmountExclVATLocal,
	|	ProductTable.AmountIncludingVATCompl                         AS RevenueAmountIncludingVATLocal,
	|	0                                                      AS ManualDiscount,
	|	0                                                      AS DiscountMarkupAmount,
	|
	|	ProductTable.Warehouse                                 AS Warehouse,
	|	&Contract                                               AS Contract,
	|	UNDEFINED                                           AS Terms,
	|
	|	&LineOfBusiness                               AS CounterpartyLineOfBusiness,
	|	ProductTable.Purpose.LineOfBusiness AS ProductLineOfBusiness,
	|
	|	&ARAPCurrency                                  AS ARAPCurrency,
	|	ProductTable.AmountARAP                   AS AmountInARAPCurrency,
	|
	|	ProductTable.AmountARAP
	|	- CASE
	|		WHEN ProductTable.AmountIncludingVAT <> 0
	|			THEN CAST(ProductTable.AmountARAP
	|						   * ProductTable.VATAmount
	|						   / ProductTable.AmountIncludingVAT AS NUMBER(31,2))
	|		ELSE 0
	|	END                                                  AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency                                                AS DocumentCurrency,
	|	ProductTable.AmountIncludingVAT                             AS AmountInDocumentCurrency,
	|	ProductTable.AmountIncludingVAT - ProductTable.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|
	|	ProductTable.Products                          AS SourceOfProductFinancialAccountingGroup,
	|	ProductTable.ARAPObject                        AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	ProductTable.FinRecordID                AS FinRecordID,
	|	&BusinessTransactionSetting                        AS BusinessTransactionSetting,
	|	ProductTable.VATRate                             AS VATRate
	|	
	|FROM
	|	TTManufacturedProduct AS ProductTable
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableShipmentReferences(Query, QueryTexts, Registers)
	
	RegisterName = "ShipmentAndReturnReferences";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	ProductTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	ProductTable.MaterialProviderOrder AS ReferenceOrder,
	|	ProductTable.Products AS Products,
	|	ProductTable.Characteristic AS Characteristic,
	|	ProductTable.Series AS Series,
	|	ProductTable.RowCode AS RowCode,
	|	CASE
	|		WHEN ProductTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN ProductTable.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1) AS Factor,
	|	ProductTable.Count AS Count,
	|	ProductTable.AmountIncludingVAT AS Sum
	|FROM
	|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS ProductTable
	|WHERE
	|	ProductTable.Ref = &Ref
	|	AND &ReportOnOrders
	|
	|UNION ALL
	|
	|SELECT
	|	ProductTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	ProductTable.MaterialProviderOrder AS ReferenceOrder,
	|	ProductTable.Products AS Products,
	|	ProductTable.Characteristic AS Characteristic,
	|	ProductTable.Series AS Series,
	|	ProductTable.RowCode AS RowCode,
	|	CASE
	|		WHEN ProductTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN ProductTable.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	TableOfIndicators.Ref AS Factor,
	|	ProductTable.Count AS Count,
	|	ProductTable.AmountIncludingVAT AS Sum
	|FROM
	|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS ProductTable
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister))
	|WHERE
	|	ProductTable.Ref = &Ref
	|	AND &ReportOnOrders
	|	AND ProductTable.RowCode = 0
	|
	|ORDER BY
	|	LineNumber,
	|	Factor";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                                        AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)                                AS RecordType,
	|	&Period                                                               AS Period,
	|	TableTypesOfStocks_.ItemsLocationAttributes                         AS ItemsLocationAttributes,
	|	&Organization                                                          AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                                         AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                                           AS CCDNumber,
	|	TableTypesOfStocks_.Count                                         AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN                                   AS QuantityByGBRN,
	|	&BusinessOperation                                                AS BusinessOperation,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products            AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic          AS Characteristic,
	|	VALUE (Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) AS VATTaxation
	|FROM
	|	Document.ReportToMaterialProvider2_5.InventoryKinds AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber                                        AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)                                AS RecordType,
	|	&Period                                                               AS Period,
	|	TableTypesOfStocks_.ItemsLocationAttributes                         AS ItemsLocationAttributes,
	|	&Organization                                                          AS Organization,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute                                      AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                                           AS CCDNumber,
	|	TableTypesOfStocks_.Count                                         AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN                                   AS QuantityByGBRN,
	|	&BusinessOperation                                                AS BusinessOperation,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products            AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic          AS Characteristic,
	|	VALUE (Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) AS VATTaxation
	|FROM
	|	Document.ReportToMaterialProvider2_5.InventoryKinds AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON Dimension.Products = CatalogProducts.Ref
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND CatalogProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers)
	
	RegisterName = "MaterialsAndWorksInProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentTable.Date      				AS Period,
	|	VALUE(AccumulationRecordType.Expense) 	AS RecordType,
	|	DocumentTable.Organization            AS Organization,
	|	TabularSection.Department            AS Department,
	|	TabularSection.Products           	AS Products,
	|	TabularSection.Characteristic         	AS Characteristic,
	|	TabularSection.Purpose             	AS Purpose,
	|	TabularSection.Count             	AS Count
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS DocumentTable
	|	
	|	INNER JOIN Document.ReportToMaterialProvider2_5.ManufacturedProduct AS TabularSection
	|	ON TabularSection.Ref = DocumentTable.Ref
	|
	|WHERE
	|	DocumentTable.Ref = &Ref
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
	|	&Ref                  AS Ref,
	|	&Period                  AS IBDocumentDate,
	|	&Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization             AS Organization,
	|	&BusinessOperation   AS BusinessOperation,
	|	&Partner                 AS Partner,
	|	&Counterparty              AS Counterparty,
	|	&Contract                 AS Contract,
	|	&LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED             AS StorageLocation,
	|	&Department           AS Department,
	|	&Manager                AS EmployeeResponsible,
	|	&Author                   AS Author,
	|	&Comment             AS Comment,
	|	&Currency                  AS Currency,
	|	&DocumentAmount          AS Sum,
	|	UNDEFINED             AS Status,
	|	&Posted                AS Posted,
	|	&DeletionMark         AS DeletionMark,
	|	FALSE                     AS AdditionalRecord,
	|	&ContractInformation    AS More,
	|	&Period                  AS SourceDocumentDate,
	|	&NumberForPrinting           AS SourceDocumentNumber,
	|	&Period                  AS RecordingInAccountingDate,
	|	UNDEFINED             AS Priority
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
	"SELECT
	|	TabPart.Ref AS Ref,
	|	TabPart.Ref.Date AS Period,
	|	TabPart.Products AS Products,
	|	TabPart.Characteristic AS Characteristic,
	|	TabPart.Department AS Warehouse,
	|	TabPart.Purpose AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	TabPart.Count AS Count,
	|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
	|	TRUE AS ControlOfFreeResidue
	|FROM
	|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS TabPart
	|WHERE
	|	TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND (TabPart.RowCode = 0
	|		OR NOT TabPart.Ref.ReportOnOrders)
	|";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
EndProcedure

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
		|	Document.ReportToMaterialProvider2_5.PaymentScheduleSteps AS Table
		|		LEFT JOIN Document.ReportToMaterialProvider2_5 AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.ReportToMaterialProvider2_5.ARAPDetails AS Table
		|		LEFT JOIN Document.ReportToMaterialProvider2_5 AS DocumentDataHeader
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
		|	Document.ReportToMaterialProvider2_5 AS DocumentDataHeader
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON ARAPObjects.Object = DocumentDataHeader.Ref
		|		AND NOT ARAPObjects.DeletionMark
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
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
		|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS Table
		|		LEFT JOIN Document.ReportToMaterialProvider2_5 AS DocumentDataHeader
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
		|		WHEN DocumentDataHeader.ReportOnOrders
		|			THEN Table.MaterialProviderOrder.ARAPObject
		|		WHEN DocumentDataHeader.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN Table.ARAPObject.Contract.ARAPObject
		|		ELSE Table.ARAPObject
		|	END) AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS Table
		|		LEFT JOIN Document.ReportToMaterialProvider2_5 AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region Sale
	
	TextSale = "
	|SELECT
	|	Table.Ref                                                 AS Ref,
	|	Table.Ref.Organization                                     AS Organization,
	|	Table.Ref.Partner                                         AS Partner,
	|	
	|	Table.ARAPObject                                         AS ARAPObject,
	|	Table.PaymentDate                                            AS PaymentDate,
	|	Table.OrderDocument                                                  AS SalesOrder_,
	|	Table.Ref.ReportOnOrders                                  AS InvoiceForOrders,
	|	Table.AmountARAP                                    AS AmountARAP,
	|	0                                                              AS AmountARAPByPackage,
	|	Table.PaymentAmount                                           AS Sum,
	|	
	|	Table.Ref.ARAPObjectSettings                                 AS ARAPObjectSettings,
	|	Table.Ref.Date                                            AS RecorderDate,
	|	Table.Ref.Number                                           AS RecorderNumber,
	|	Table.Ref.ARAPCurrency                            AS ARAPCurrency,
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer) AS BusinessOperation,
	|	Table.Ref.Date                                            AS DateOfCourse,
	|	Table.Ref.Currency                                          AS DocumentCurrency,
	|	Table.PaymentOption                                          AS PaymentOption,
	|	Table.ExceedingOrder                                            AS ExceedingOrder,
	|	UNDEFINED                                                   AS LinkedDocument
	|FROM
	|	Document.ReportToMaterialProvider2_5.PaymentScheduleSteps AS Table
	|WHERE
	|	Table.Ref IN (&Ref)
	|";
	
	#EndRegion
	
	#Region IncreasePaymentPlan
	
	TextPaymentPlanning = "
	|SELECT
	|	Table.Ref                                                 AS Ref,
	|	Table.Ref.Organization                                     AS Organization,
	|	Table.Ref.Partner                                         AS Partner,
	|	
	|	Table.ARAPObject                                         AS ARAPObject,
	|	Table.Ref.Date                                            AS RecorderDate,
	|	Table.Ref.Number                                           AS RecorderNumber,
	|	Table.Ref.ARAPObjectSettings                                 AS ARAPObjectSettings,
	|	Table.Ref.ARAPCurrency                            AS ARAPCurrency,
	|	Table.Ref.Currency                                          AS DocumentCurrency,
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer) AS BusinessOperation,
	|	Table.Ref.PaymentMethod                                     AS PaymentMethod,
	|	
	|	Table.PaymentDate                                            AS PaymentDate,
	|	Table.PaymentOption                                          AS PaymentOption,
	|	Table.AmountARAP                                    AS AmountDue,
	|		
	|	CASE
	|		WHEN Table.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment)
	|			THEN FALSE
	|		ELSE TRUE
	|	END                                                          AS ExcludeDuringControl,
	|	Table.Ref.ReportOnOrders                                  AS InvoiceForOrders,
	|	Table.OrderDocument                                                  AS SalesOrder_,
	|	Table.ExceedingOrder                                            AS ExceedingOrder,
	|	UNDEFINED                                                   AS LinkedDocument
	|FROM
	|	Document.ReportToMaterialProvider2_5.PaymentScheduleSteps AS Table
	|WHERE
	|	Table.Ref IN (&Ref)
	|";
	
	#EndRegion
	
	#Region TextProducts_1
	
	TextProducts_1 = "
	|SELECT
	|	Table.Ref                                                 AS Ref,
	|	Table.Ref.Organization                                     AS Organization,
	|	Table.Ref.Partner                                         AS Partner,
	|	
	|	Table.ARAPObject                                         AS ARAPObject,
	|	Table.Ref.Date                                            AS DateOfShipment,
	|	Table.AmountARAP                                    AS AmountARAP,
	|	0                                                              AS IncreaseShipping,
	|	Table.AmountARAP                                    AS ReduceShipping,
	|	Table.AmountARAP                                    AS IncreaseToBeSHIPPED,
	|	Table.AmountARAP                                    AS ReduceToBESHIPPED,
	|
	|	Table.MaterialProviderOrder                                          AS SalesOrder_,
	|	0                                                              AS DepositForPackage,
	|	CASE
	|		WHEN Table.MaterialProviderOrder <> VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|			AND Table.RowCode = 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                          AS ExceedingOrder,
	|	Table.Ref.ReportOnOrders                                  AS InvoiceForOrders,
	|	
	|	Table.Ref.ARAPObjectSettings                                 AS ARAPObjectSettings,
	|	Table.Ref.Date                                            AS RecorderDate,
	|	Table.Ref.Number                                           AS RecorderNumber,
	|	Table.Ref.ARAPCurrency                            AS ARAPCurrency,
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer) AS BusinessOperation,
	|	Table.Ref.Currency                                          AS DocumentCurrency
	|FROM
	|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS Table
	|WHERE
	|	Table.Ref IN (&Ref)
	|	AND NOT Table.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|";
		
	#EndRegion
	
	#Region ApplyingPrepayment
	
	TextAdvancePaymentOffset = "
	|SELECT
	|	Table.Ref                                             AS Ref,
	|	Table.Ref.Organization                                 AS Organization,
	|	Table.Ref.Partner                                     AS Partner,
	|	
	|	ARAPObjects.Ref                                     AS CalculationObjectReceiver,
	|	Table.ARAPObject                                     AS CalculationObjectSource,
	|
	|	Table.Ref.ARAPCurrency                        AS ARAPCurrency,
	|	Table.AmountARAP                                AS AmountARAP,
	|	Table.Ref.Currency                                      AS DocumentCurrency,
	|	Table.Sum                                              AS Sum,
	|
	|	Table.Ref.Date                                        AS DateOfCourse,
	|	Table.Ref.Date                                        AS RecorderDate,
	|	Table.Ref.Number                                       AS RecorderNumber,
	|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment) AS BusinessOperation
	|FROM
	|	Document.ReportToMaterialProvider2_5.ARAPDetails AS Table
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON ARAPObjects.Object = Table.Ref
	|		AND NOT ARAPObjects.DeletionMark
	|WHERE
	|	Table.Ref IN (&Ref)
	|";
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSale(
		Query,
		QueryTexts,
		Registers,
		TextSale,
		TextPaymentPlanning,
		TextAdvancePaymentOffset,
		TextProducts_1);
	
EndProcedure

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""ManufacturedProduct""                                          AS DataSource,
	|	FALSE                                                   AS DistributeTotalAmount,
	|	DocumentTable.Ref                                AS Ref,
	|	DocumentTable.Ref.Date                           AS Date,
	|	DocumentTable.Ref.Organization                    AS Organization,
	|	DocumentTable.Ref.Currency                         AS DocumentCurrency,
	|	DocumentTable.Ref.ARAPCurrency           AS ARAPCurrency,
	|	DocumentTable.Ref.Date                           AS VATBasePeriod,
	|	DocumentTable.Ref.Date                           AS DateOfCourse,
	|	
	|	DocumentTable.LineNumber                           AS LineNumber,
	|	DocumentTable.RowID                   AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate                             AS VATRate,
	|	DocumentTable.VATAmount                              AS VATAmount,
	|	DocumentTable.AmountARAP                   AS AmountARAP,
	|	0                                                      AS AmountVATARAP,
	|	0                                                      AS AmountExcludingVATCompl,
	|	0                                                      AS AmountExcludingVATMan,
	|	
	|	TRUE                                                 AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObject                        AS ARAPObject,
	|	TRUE                                                 AS RecalculateBasedOnARAPData
	|FROM
	|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS DocumentTable
	|		LEFT JOIN Document.ReportToMaterialProvider2_5.InventoryKinds AS InventoryKinds
	|		ON DocumentTable.Ref = InventoryKinds.Ref
	|			AND DocumentTable.ItemsLocationAttributes = InventoryKinds.ItemsLocationAttributes
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND InventoryKinds.Ref IS NULL
	|	AND DocumentTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|UNION ALL
	|
	|SELECT
	|	""InventoryKinds""                                        AS DataSource,
	|	FALSE                                                   AS DistributeTotalAmount,
	|	DocumentTable.Ref                                AS Ref,
	|	DocumentTable.Ref.Date                           AS Date,
	|	DocumentTable.Ref.Organization                    AS Organization,
	|	DocumentTable.Ref.Currency                         AS DocumentCurrency,
	|	DocumentTable.Ref.ARAPCurrency           AS ARAPCurrency,
	|	DocumentTable.Ref.Date                           AS VATBasePeriod,
	|	DocumentTable.Ref.Date                           AS DateOfCourse,
	|	
	|	DocumentTable.LineNumber                           AS LineNumber,
	|	DocumentTable.FinRecordID                AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate                             AS VATRate,
	|	DocumentTable.VATAmount                              AS VATAmount,
	|	DocumentTable.AmountARAP                   AS AmountARAP,
	|	0                                                      AS AmountVATARAP,
	|	0                                                      AS AmountExcludingVATCompl,
	|	0                                                      AS AmountExcludingVATMan,
	|
	|	TRUE                                                 AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObject                        AS ARAPObject,
	|	TRUE                                                 AS RecalculateBasedOnARAPData
	|FROM
	|	Document.ReportToMaterialProvider2_5.InventoryKinds AS DocumentTable
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";

	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.ReportToMaterialProvider2_5";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",        """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		RequestHasSource = False;
		
	Else
		
		ExceptionText = StrTemplate(
			NStr("vi = 'Trong chứng từ %1 chưa thực thi đáp ứng nội dung truy vấn tạo bản ghi kết chuyển theo biểu ghi %2.';
				|ru = 'В документе %1 не реализована адаптация текста запроса формирования движений по регистру %2.';
				|en = 'In the %1 document, adaptation of request for generating records of the %2 register is not implemented.'; fa = 'In the %1 document, adaptation of request for generating records of the %2 register is not implemented.';
				|it = 'Nel documento %1 non è stato effettuato l''adattamento del testo di richiesta di generazione dei movimenti sul registro %2.';
				|pl = 'W dokumencie %1 nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %2.';
				|tr = '%1 belgesinde, %2 kaydına göre hareketlerin düzenlenmesi isteğinin metin uyarlaması uygulanmadı.'"),
			FullDocumentName,
			RegisterName);
		
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
	Result.QueryText       = QueryText;
	
	Return Result;
	
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
		// There are no additional parameters.
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTManufacturedProduct");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTManufacturedProduct(Query, QueryTexts);
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
	|	&AdjustmentPeriod_    AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	CASE WHEN DocumentTable.VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|		VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|	ELSE
	|		DocumentTable.VATTaxation
	|	END											AS VATActivityType,
	|	CASE WHEN DocumentTable.VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|		VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|	ELSE
	|		DocumentTable.VATTaxation
	|	END											AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute				AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	CASE WHEN TableTypesOfStocks_.MaterialProviderOrder = VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|		THEN &Ref
	|		ELSE TableTypesOfStocks_.MaterialProviderOrder
	|	END                                  			AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity						AS SalesOpportunity,
	|	DocumentTable.Department				AS Department,
	|	DocumentTable.Manager					AS Manager,
	|	UNDEFINED 								AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 				AS Count,
	|	UNDEFINED 								AS RowID,
	|
	// Other fields
	|	&BusinessOperation						AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID	AS FinRecordID,
	|	&BusinessTransactionSetting				AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS DocumentTable
	|		INNER JOIN Document.ReportToMaterialProvider2_5.InventoryKinds AS TableTypesOfStocks_
	|		ON TableTypesOfStocks_.Ref = DocumentTable.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON Dimension.Products = CatalogProducts.Ref
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND CatalogProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|";
	
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
	|	&AdjustmentPeriod_    AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	UNDEFINED 									AS InventoryOwnerAttribute,
	|	CASE WHEN DocumentTable.VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|		VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|	ELSE
	|		DocumentTable.VATTaxation
	|	END											AS VATActivityType,
	|	CASE WHEN DocumentTable.VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|		VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|	ELSE
	|		DocumentTable.VATTaxation
	|	END											AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	UNDEFINED									AS CorItemsLocationAttributes,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	CASE WHEN TableTypesOfStocks_.MaterialProviderOrder = VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|		THEN &Ref
	|		ELSE TableTypesOfStocks_.MaterialProviderOrder
	|	END                                  			AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity						AS SalesOpportunity,
	|	DocumentTable.Department				AS Department,
	|	DocumentTable.Manager					AS Manager,
	|	UNDEFINED 								AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 				AS Count,
	|	UNDEFINED 								AS RowID,
	|
	// Other fields
	|	&BusinessOperation						AS BusinessOperation,
	|	TableTypesOfStocks_.RowID		AS FinRecordID,
	|	&BusinessTransactionSetting				AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS DocumentTable
	|		INNER JOIN Document.ReportToMaterialProvider2_5.ManufacturedProduct AS TableTypesOfStocks_
	|		ON TableTypesOfStocks_.Ref = DocumentTable.Ref
	|		
	|		LEFT JOIN Document.ReportToMaterialProvider2_5.InventoryKinds AS DocumentStocks
	|		ON TableTypesOfStocks_.Ref = DocumentStocks.Ref
	|			AND TableTypesOfStocks_.ItemsLocationAttributes = DocumentStocks.ItemsLocationAttributes
	|		
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON TableTypesOfStocks_.Products = CatalogProducts.Ref
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentStocks.Ref IS NULL
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|
	|UNION ALL
	|
	|SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_    AS VariancePeriod,
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	UNDEFINED 									AS InventoryOwnerAttribute,
	|	CASE WHEN DocumentTable.VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|		VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|	ELSE
	|		DocumentTable.VATTaxation
	|	END											AS VATActivityType,
	|	CASE WHEN DocumentTable.VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|		VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|	ELSE
	|		DocumentTable.VATTaxation
	|	END											AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	UNDEFINED									AS CorItemsLocationAttributes,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	CASE WHEN TableTypesOfStocks_.MaterialProviderOrder = VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|		THEN &Ref
	|		ELSE TableTypesOfStocks_.MaterialProviderOrder
	|	END                                  			AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity						AS SalesOpportunity,
	|	DocumentTable.Department				AS Department,
	|	DocumentTable.Manager					AS Manager,
	|	UNDEFINED 								AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 				AS Count,
	|	UNDEFINED 								AS RowID,
	|
	// Other fields
	|	&BusinessOperation						AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID	AS FinRecordID,
	|	&BusinessTransactionSetting				AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS DocumentTable
	|		INNER JOIN Document.ReportToMaterialProvider2_5.InventoryKinds AS TableTypesOfStocks_
	|		ON TableTypesOfStocks_.Ref = DocumentTable.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON Dimension.Products = CatalogProducts.Ref
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
	#Region WriteOffForExpensesAssets_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_    AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	CASE WHEN DocumentTable.VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|		VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|	ELSE
	|		DocumentTable.VATTaxation
	|	END											AS VATActivityType,
	|	CASE WHEN DocumentTable.VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|		VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|	ELSE
	|		DocumentTable.VATTaxation
	|	END											AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 									AS CorCompany,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute				AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.ExpenseItem 			    AS ExpenseItemAssets,
	|	TableTypesOfStocks_.DimensionOfExpenses    		AS AssetExpenseAnalytics,
	|	DocumentTable.LineOfBusiness		AS CorLineOfBusiness,
	|	UNDEFINED									AS CorLot,
	|	UNDEFINED 									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners 						AS AccountingDimensionByPartners,
	|	CASE WHEN TableTypesOfStocks_.MaterialProviderOrder = VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|		THEN &Ref
	|		ELSE TableTypesOfStocks_.MaterialProviderOrder
	|	END                                  			AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity							AS SalesOpportunity,
	|	DocumentTable.Department					AS Department,
	|	DocumentTable.Manager						AS Manager,
	|	UNDEFINED 									AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 					AS Count,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses) AS BusinessOperation,
	|	TableTypesOfStocks_.GLAccountSettings		AS GLAccountSettings,
	|	TableTypesOfStocks_.RowID	 	AS RowID,
	|	TableTypesOfStocks_.FinRecordID	AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS DocumentTable
	|	INNER JOIN Document.ReportToMaterialProvider2_5.InventoryKinds AS TableTypesOfStocks_
	|		ON TableTypesOfStocks_.Ref = DocumentTable.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON Dimension.Products = CatalogProducts.Ref
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.ToExpenseAs
	|	AND CatalogProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.RecogniseAsExpensesAssets,
		QueryText);
	
	#EndRegion
	
	#Region ExpenseAsAssets_Work
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_    AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	UNDEFINED 									AS InventoryOwnerAttribute,
	|	CASE WHEN DocumentTable.VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|		VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|	ELSE
	|		DocumentTable.VATTaxation
	|	END											AS VATActivityType,
	|	CASE WHEN DocumentTable.VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|		VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|	ELSE
	|		DocumentTable.VATTaxation
	|	END											AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 									AS CorCompany,
	|	UNDEFINED									AS CorItemsLocationAttributes,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.ExpenseItem 			    AS ExpenseItemAssets,
	|	TableTypesOfStocks_.DimensionOfExpenses    		AS AssetExpenseAnalytics,
	|	DocumentTable.LineOfBusiness		AS CorLineOfBusiness,
	|	UNDEFINED									AS CorLot,
	|	UNDEFINED 									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners 						AS AccountingDimensionByPartners,
	|	CASE WHEN TableTypesOfStocks_.MaterialProviderOrder = VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|		THEN &Ref
	|		ELSE TableTypesOfStocks_.MaterialProviderOrder
	|	END                                  			AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity							AS SalesOpportunity,
	|	DocumentTable.Department					AS Department,
	|	DocumentTable.Manager						AS Manager,
	|	UNDEFINED 									AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 					AS Count,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses) AS BusinessOperation,
	|	TableTypesOfStocks_.GLAccountSettings		AS GLAccountSettings,
	|	TableTypesOfStocks_.RowID	 	AS RowID,
	|	TableTypesOfStocks_.RowID		AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS DocumentTable
	|		INNER JOIN Document.ReportToMaterialProvider2_5.ManufacturedProduct AS TableTypesOfStocks_
	|		ON TableTypesOfStocks_.Ref = DocumentTable.Ref
	|		
	|		LEFT JOIN Document.ReportToMaterialProvider2_5.InventoryKinds AS DocumentStocks
	|		ON TableTypesOfStocks_.Ref = DocumentStocks.Ref
	|			AND TableTypesOfStocks_.ItemsLocationAttributes = DocumentStocks.ItemsLocationAttributes
	|		
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON TableTypesOfStocks_.Products = CatalogProducts.Ref
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentStocks.Ref IS NULL
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND TableTypesOfStocks_.ToExpenseAs
	|
	|UNION ALL
	|
	|SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_    AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	UNDEFINED 									AS InventoryOwnerAttribute,
	|	CASE WHEN DocumentTable.VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|		VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|	ELSE
	|		DocumentTable.VATTaxation
	|	END											AS VATActivityType,
	|	CASE WHEN DocumentTable.VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|		VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|	ELSE
	|		DocumentTable.VATTaxation
	|	END											AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 									AS CorCompany,
	|	UNDEFINED									AS CorItemsLocationAttributes,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.ExpenseItem 			    AS ExpenseItemAssets,
	|	TableTypesOfStocks_.DimensionOfExpenses    		AS AssetExpenseAnalytics,
	|	UNDEFINED									AS CorLineOfBusiness,
	|	UNDEFINED									AS CorLot,
	|	UNDEFINED 									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners 						AS AccountingDimensionByPartners,
	|	CASE WHEN TableTypesOfStocks_.MaterialProviderOrder = VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|		THEN &Ref
	|		ELSE TableTypesOfStocks_.MaterialProviderOrder
	|	END                                  			AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity							AS SalesOpportunity,
	|	DocumentTable.Department					AS Department,
	|	DocumentTable.Manager						AS Manager,
	|	UNDEFINED 									AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 					AS Count,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses) AS BusinessOperation,
	|	TableTypesOfStocks_.GLAccountSettings		AS GLAccountSettings,
	|	TableTypesOfStocks_.RowID		AS RowID,
	|	TableTypesOfStocks_.FinRecordID	AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS DocumentTable
	|		INNER JOIN Document.ReportToMaterialProvider2_5.InventoryKinds AS TableTypesOfStocks_
	|		ON TableTypesOfStocks_.Ref = DocumentTable.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON Dimension.Products = CatalogProducts.Ref
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND TableTypesOfStocks_.ToExpenseAs
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.RecogniseAsExpensesAssets,
		QueryText);
	
	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#Region VATReflection

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	ValueText_ =
	"
	// Works
	|SELECT
	|	HeaderData_.Date                   AS Period,
	|	InventoryTable.Ref              AS Ref,
	|	HeaderData_.BusinessOperation  AS BusinessOperation,
	|	HeaderData_.Organization            AS Organization,
	|	HeaderData_.Department          AS Department,
	|	HeaderData_.Counterparty             AS Counterparty,
	|	HeaderData_.Contract                AS Contract,
	|	UNDEFINED                       AS Shipper,
	|	UNDEFINED                       AS GoodsRecipient,
	|	FALSE                               AS RetailSaleOfGoods,
	|	InventoryTable.Ref              AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED                       AS ImplementationAdjustmentDocument,
	|	UNDEFINED                       AS ConsignedGoodsCustomer,
	|	FALSE                               AS SalesViaCommissionAgent,
	|	FALSE                               AS ErrorCorrection,
	|	FALSE                               AS AdjustmentUnderApprovalOfParties,
	|	InventoryTable.ARAPObject      AS ARAPObject,
	|	UNDEFINED                       AS DocumentSaleAdjustment,
	|	HeaderData_.VATTaxation     AS VATTaxation,
	|	InventoryTable.Products        AS Products,
	|	InventoryTable.Characteristic      AS Characteristic,
	|	VALUE(Catalog.Products.EmptyRef)               AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef)   AS PartnerProducts,
	|	InventoryTable.Series               AS Series,
	|	""""                               AS Content,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN InventoryTable.Count
	|		ELSE InventoryTable.NumberOfPackages
	|	END                              AS Count,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN InventoryTable.Products.UnitOfMeasure
	|		ELSE &QueryTextUnitOfMeasure
	|	END                              AS UnitOfMeasure,
	|	0                                  AS QuantityByGBRN,
	|	0                                  AS ExciseTaxAmount,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	InventoryTable.VATRate           AS VATRate,
	|	VALUE(Catalog.FEACN.EmptyRef) AS FEACNCode,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)        AS InventoryOwnerAttribute,
	|	InventoryTable.LineNumber         AS LineNumber,
	|	InventoryTable.RowID AS RowID,
	|	InventoryTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting    AS BusinessTransactionSetting
	|FROM
	|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS InventoryTable
	|		LEFT JOIN Document.ReportToMaterialProvider2_5 AS HeaderData_
	|		ON InventoryTable.Ref = HeaderData_.Ref
	|		
	|		LEFT JOIN Document.ReportToMaterialProvider2_5.InventoryKinds AS DataOfInventory
	|		ON InventoryTable.Ref = DataOfInventory.Ref
	|			AND InventoryTable.ItemsLocationAttributes = DataOfInventory.ItemsLocationAttributes
	|	
	|WHERE
	|	InventoryTable.Ref IN(&Ref)
	|	AND DataOfInventory.Ref IS NULL
	|	AND InventoryTable.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OperationService),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|
	|UNION ALL
	|
	// Goods
	|SELECT
	|	HeaderData_.Date                   AS Period,
	|	InventoryTable.Ref              AS Ref,
	|	HeaderData_.BusinessOperation  AS BusinessOperation,
	|	HeaderData_.Organization            AS Organization,
	|	HeaderData_.Department          AS Department,
	|	HeaderData_.Counterparty             AS Counterparty,
	|	HeaderData_.Contract                AS Contract,
	|	UNDEFINED                       AS Shipper,
	|	UNDEFINED                       AS GoodsRecipient,
	|	FALSE                               AS RetailSaleOfGoods,
	|	InventoryTable.Ref              AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED                       AS ImplementationAdjustmentDocument,
	|	UNDEFINED                       AS ConsignedGoodsCustomer,
	|	FALSE                               AS SalesViaCommissionAgent,
	|	FALSE                               AS ErrorCorrection,
	|	FALSE                               AS AdjustmentUnderApprovalOfParties,
	|	InventoryTable.ARAPObject      AS ARAPObject,
	|	UNDEFINED                       AS DocumentSaleAdjustment,
	|	HeaderData_.VATTaxation     AS VATTaxation,
	|	Dimension.Products             AS Products,
	|	Dimension.Characteristic           AS Characteristic,
	|	VALUE(Catalog.Products.EmptyRef)               AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef)   AS PartnerProducts,
	|	Dimension.Series                    AS Series,
	|	""""                               AS Content,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN InventoryTable.Count
	|		ELSE InventoryTable.NumberOfPackages
	|	END                              AS Count,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN InventoryTable.ItemsLocationAttributes.Products.UnitOfMeasure
	|		ELSE &QueryTextUnitOfMeasurementInventoryTypes
	|	END                              AS UnitOfMeasure,
	|	InventoryTable.QuantityByGBRN    AS QuantityByGBRN,
	|	0                                  AS ExciseTaxAmount,
	|	InventoryTable.CCDNumber            AS CCDNumber,
	|	InventoryTable.VATRate           AS VATRate,
	|	VALUE(Catalog.FEACN.EmptyRef) AS FEACNCode,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)        AS InventoryOwnerAttribute,
	|	InventoryTable.LineNumber         AS LineNumber,
	|	InventoryTable.FinRecordID AS RowID,
	|	InventoryTable.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting    AS BusinessTransactionSetting
	|FROM
	|	Document.ReportToMaterialProvider2_5.InventoryKinds AS InventoryTable
	|	
	|	LEFT JOIN Document.ReportToMaterialProvider2_5 AS HeaderData_
	|	ON InventoryTable.Ref = HeaderData_.Ref
	|	
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON InventoryTable.ItemsLocationAttributes = Dimension.Ref
	|
	|WHERE
	|	InventoryTable.Ref IN(&Ref)
	|";
	
	ValueText_ = StrReplace(
		ValueText_,
		"&QueryTextUnitOfMeasurementInventoryTypes",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"InventoryTable.Package",
			"InventoryTable.ItemsLocationAttributes.Products"));
	
	ValueText_ = StrReplace(
		ValueText_,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"InventoryTable.Package",
			"InventoryTable.Products"));
	
	VATAccountingERP.ReflectImplementationToClient(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

#EndRegion

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If AccessRight("Update", Metadata.Documents.ReportToMaterialProvider2_5) Then
		
		// Report of completed works
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CustomerInvoiceServices";
		PrintCommand.Presentation = NStr("vi = 'Biên bản nghiệm thu công việc';
										|ru = 'Акт выполненных работ';
										|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
										|it = 'Verbale di consegna dei lavori effettuati';
										|pl = 'Protokół wykonanych prac';
										|tr = 'Müşteri faturası - Hizmetler'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.DefaultPrintForm = True;
		PrintCommand.PrintFormDescription = NStr("vi = 'Biên bản nghiệm thu công việc';
												|ru = 'Акт выполненных работ';
												|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
												|it = 'Verbale di consegna dei lavori effettuati';
												|pl = 'Protokół wykonanych prac';
												|tr = 'Müşteri faturası - Hizmetler'");
		
		// Report On Products And Materials
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "ReportOnProductsAndMaterials";
		PrintCommand.Presentation = NStr("vi = 'Báo cáo về sản phẩm và nguyên vật liệu';
										|ru = 'Отчет о продукции и материалах';
										|en = 'Report on manufactured products and materials'; fa = 'گزارش محصولات تولیدی و مواد';
										|it = 'Report su prodotti e materiali';
										|pl = 'Raport o produkcji i materiałach';
										|tr = 'Ürün ve malzeme raporu'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.DefaultPrintForm = True;
		PrintCommand.PrintFormDescription = NStr("vi = 'Báo cáo về sản phẩm và nguyên vật liệu';
												|ru = 'Отчет о продукции и материалах';
												|en = 'Report on manufactured products and materials'; fa = 'گزارش محصولات تولیدی و مواد';
												|it = 'Report su prodotti e materiali';
												|pl = 'Raport o produkcji i materiałach';
												|tr = 'Ürün ve malzeme raporu'");
		
		If GetFunctionalOption("DoNotUseCommercialInvoicesAndSelectDiscountDisplayOption")
		 Or GetFunctionalOption("DoNotUseCommercialInvoicesAndDoNotSelectDiscountDisplayOption") Then
			
			// Invoice for payment
			PrintCommand = PrintCommands.Add();
			PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
			PrintCommand.Id = "ProformaInvoice";
			PrintCommand.Presentation = NStr("vi = 'Hóa đơn thanh toán';
											|ru = 'Счет на оплату';
											|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
											|it = 'Fattura di pagamento';
											|pl = 'Rachunek do zapłaty';
											|tr = 'Ticari fatura'");
			PrintCommand.CheckPostingBeforePrint = True;
			
			// An invoice for payment with facsimile
			PrintCommand = PrintCommands.Add();
			PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
			PrintCommand.Id = "ProformaInvoice";
			PrintCommand.Presentation = NStr("vi = 'Hóa đơn thanh toán có dấu chữ ký';
											|ru = 'Счет на оплату с факсимиле';
											|en = 'Commercial invoice with facsimile'; fa = 'Commercial invoice with facsimile';
											|it = 'Fattura di pagamento in facsimile';
											|pl = 'Rachunek do płatności z faksymile';
											|tr = 'Kaşeli ticari fatura'");
			PrintCommand.CheckPostingBeforePrint = True;
			PrintCommand.AdditionalParameters.Insert("DisplayFacsimiles", True);
			PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
			PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
			
		EndIf;
		
	EndIf;
	
	ReportToMaterialProvider2_5Localization.AddPrintCommands(PrintCommands);

EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray        - Array          - references to the objects that you want to print.
//  PrintParameters       - Structure       - additional print settings.
//  PrintFormsCollection - ValueTable - generated tabular documents (output parameter).
//  PrintObjects         - ValueList  - The value is a reference to the object,
//                                            the representation is the name of the area in which the object was output (output parameter).
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CustomerInvoiceServices") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CustomerInvoiceServices",
			NStr("vi = 'Biên bản nghiệm thu công việc';
				|ru = 'Акт выполненных работ';
				|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
				|it = 'Verbale di consegna dei lavori effettuati';
				|pl = 'Protokół wykonanych prac';
				|tr = 'Gerçekleştirilen işler raporu'"),
			FormPrintedFormOfActOnProvisionOfServices(ObjectsArray, PrintObjects, PrintParameters));
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ReportOnProductsAndMaterials") Then
		
		SpreadsheetDocument = New SpreadsheetDocument;
		SpreadsheetDocument.PrintParametersName = "Parameters_Seals_ReportToMaterialProvider2_5_ReportOnProductsAndMaterials";
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ReportOnProductsAndMaterials",
			NStr("vi = 'Báo cáo về sản phẩm và nguyên vật liệu';
				|ru = 'Отчет о продукции и материалах';
				|en = 'Report on manufactured products and materials'; fa = 'گزارش محصولات تولیدی و مواد';
				|it = 'Report su prodotti e materiali';
				|pl = 'Raport o produkcji i materiałach';
				|tr = 'Ürün ve malzemelere ilişkin rapor'"),
			ToFormPrintedFormOfReportOnProductsAndMaterials(
				PrintingDataOfMaterialsReport(ObjectsArray),
				PrintObjects,
				SpreadsheetDocument));
		
	EndIf;

	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SetOfDocuments") Then
		
		PrintFormsCollection.Clear();
		CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects);
		
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(
		OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
		
	ReportToMaterialProvider2_5Localization.Print(
		ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

Function GetDataForPrintedInvoiceForm(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	Return DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode);
	
EndFunction

// Receives the print data
// 
// Parameters:
//  ObjectsArray - Array - array of print objects
//  PrintParameters - Structure - print options
// 
// Returns:
//  Structure - LongDesc:
//    * HeaderResults - QueryResult - the sample on the cap
//    * ResultForTabularPart - QueryResult - table-based selection
//
Function GetDataToPrint(ObjectsArray, PrintParameters) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentData.Ref                        AS Ref,
	|	DocumentData.BusinessOperation         AS BusinessOperation,
	|	DocumentData.Number                         AS Number,
	|	DocumentData.Date                          AS Date,
	|	DocumentData.Partner                       AS Partner,
	|	DocumentData.Counterparty                    AS Counterparty,
	|	DocumentData.Organization                   AS Organization,
	|	DocumentData.Organization.Prefix           AS Prefix,
	|	DocumentData.Currency                        AS Currency,
	|	DocumentData.PriceIncludesVAT               AS PriceIncludesVAT,
	|	CASE
	|		WHEN DocumentData.VATTaxation =
	|									VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			THEN FALSE
	|		ELSE TRUE
	|	END                                         AS ConsiderVAT,
	|	DocumentData.AdditionalInformation      AS AdditionalInformation,
	|	DocumentData.AdditionalInformationOfHeader AS AdditionalInformationOfHeader,
	|	DocumentData.CompanyBankAccount     AS BankAccountOfCompany,
	|	DocumentData.CounterpartyBankAccount     AS AccountOfCounterparty,
	|	DocumentData.ProcessingService           AS ProcessingService
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductTable.Ref                            AS Ref,
	|	ProductTable.LineNumber                       AS LineNumber,
	|	ProductTable.Products                      AS Products,
	|	ProductTable.Products.DescriptionFull   AS ProductFullName,
	|	ProductTable.Products.Code                  AS Code,
	|	ProductTable.Products.SKU              AS SKU,
	|	ProductTable.Characteristic                    AS Characteristic,
	|	ProductTable.Characteristic.DescriptionFull AS CharacteristicFullName,
	|	ProductTable.NumberOfPackages                AS Count,
	|	&QueryTextUnitOfMeasureDescription          AS UnitOfMeasure,
	|	ProductTable.Price                              AS Price,
	|	ProductTable.VATRate                         AS VATRate,
	|	ProductTable.Sum                             AS Sum,
	|	ProductTable.VATAmount                          AS VATAmount,
	|	ProductTable.AmountIncludingVAT                         AS AmountIncludingVAT
	|FROM
	|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS ProductTable
	|
	|WHERE
	|	ProductTable.Ref IN (&DocumentsArray)
	|
	|ORDER BY
	|	ProductTable.Ref,
	|	ProductTable.LineNumber
	|
	|TOTALS BY
	|	Ref
	|";
	
	Query.Text =
		StrReplace(
			Query.Text,
			"&QueryTextUnitOfMeasureDescription",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Description", "ProductTable.Package", "ProductTable.Products"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	ResultsArray = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults",          ResultsArray[0]);
	DataStructureForPrinting.Insert("ResultForTabularPart", ResultsArray[1]);
	
	Return DataStructureForPrinting;
	
EndFunction

Function DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	TempTablesManager = New TempTablesManager;
	
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(
		ObjectsArray, TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	ReportsToGiver.Ref                                        AS Ref,
	|	ReportsToGiver.Number                                         AS Number,
	|	ReportsToGiver.Date                                          AS Date,
	|	UNDEFINED                                                 AS DocumentBasis,
	|	ISNULL(ReportsToGiver.CompanyBankAccount.Owner, ReportsToGiver.Organization) AS Organization,
	|	ReportsToGiver.Organization                                   AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription            AS Director,
	|	TableResponsiblePersons.DirectorJobTitle               AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription        AS ChiefAccountant,
	|	CASE
	|		WHEN ReportsToGiver.VATTaxation IN (
	|							VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|							VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN FALSE
	|		ELSE TRUE
	|	END                                                        AS ConsiderVAT,
	|	ReportsToGiver.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	ReportsToGiver.Counterparty                                    AS Counterparty,
	|	ReportsToGiver.Counterparty.LegalEntityIndividual                          AS CounterpartyLegEntInd,
	|	ReportsToGiver.CompanyBankAccount                     AS BankAccount,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.ForeignBank
	|		  OR ReportsToGiver.CompanyBankAccount.CashCurrency <> ReportsToGiver.Organization.LocalAccountingCurrency
	|		  OR ReportsToGiver.CounterpartyBankAccount.ForeignBank
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                        AS PaymentAbroad,
	|	ReportsToGiver.CompanyBankAccount.CashCurrency AS CashCurrency,
	|	
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.ManualBankDetailsChange
	|			THEN ReportsToGiver.CompanyBankAccount.BankNameInt
	|		ELSE ReportsToGiver.CompanyBankAccount.Bank.InternationalDescription
	|	END                                                        AS BankNameInt,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.ManualBankDetailsChange
	|			THEN ReportsToGiver.CompanyBankAccount.BankNameForPaymentsInt
	|		ELSE ReportsToGiver.CompanyBankAccount.TransferBank.InternationalDescription
	|	END                                                        AS BankNameForPaymentsInt,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.ManualBankDetailsChange
	|			THEN ReportsToGiver.CompanyBankAccount.BankSWIFTCode
	|		ELSE ReportsToGiver.CompanyBankAccount.Bank.SWIFTBIC
	|	END                                                        AS BankSWIFTCode,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN ReportsToGiver.CompanyBankAccount.BankSWIFTCodeForPayments
	|		ELSE ReportsToGiver.CompanyBankAccount.TransferBank.SWIFTBIC
	|	END                                                        AS BankSWIFTCodeForPayments,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.ManualBankDetailsChange
	|			THEN ReportsToGiver.CompanyBankAccount.BankAddressInt
	|		ELSE ReportsToGiver.CompanyBankAccount.Bank.InternationalAddress
	|	END                                                        AS BankAddress,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN ReportsToGiver.CompanyBankAccount.BankAddressForPaymentInt
	|		ELSE ReportsToGiver.CompanyBankAccount.TransferBank.InternationalAddress
	|	END                                                        AS TransferBankAddress,
	|	
	|	ReportsToGiver.CompanyBankAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(ReportsToGiver.CompanyBankAccount.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(ReportsToGiver.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN ReportsToGiver.CompanyBankAccount.DigitalRoubleAccountID
	|		ELSE ReportsToGiver.CompanyBankAccount.AccountNumber
	|	END                                                        AS BankAccountNumber,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.ManualBankDetailsChange
	|			THEN ReportsToGiver.CompanyBankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END                                                        AS BICBank,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.ManualBankDetailsChange
	|			THEN ReportsToGiver.CompanyBankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END                                                        AS BankDescription,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.ManualBankDetailsChange
	|			THEN ReportsToGiver.CompanyBankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END                                                        AS BankCorrAccount,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.ManualBankDetailsChange
	|			THEN ReportsToGiver.CompanyBankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END                                                        AS BankCity,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN ReportsToGiver.CompanyBankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END                                                        AS TransferBankBIC,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN ReportsToGiver.CompanyBankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END                                                        AS TransferBankDescription,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN ReportsToGiver.CompanyBankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END                                                        AS TransferBankCorrAccount,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN ReportsToGiver.CompanyBankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END                                                        AS TransferBankCity,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN ReportsToGiver.CompanyBankAccount.BankCityInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END                                                        AS BankCityInt,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN ReportsToGiver.CompanyBankAccount.CountryOfBank
	|		ELSE BankCountries.Ref
	|	END                                                        AS CountryOfBank,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN ReportsToGiver.CompanyBankAccount.BankCityForPaymentsInt
	|		ELSE CorrespondentBankClassifier.CityInternationalFormat
	|	END                                                        AS BankCityForPaymentsInt,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN ReportsToGiver.CompanyBankAccount.CountryOfBankForPayments
	|		ELSE CountriesOfCorrespondentBanksOfRussianFederation.Ref
	|	END                                                        AS CountryOfBankForPayments,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.ManualBankDetailsChange
	|			THEN """"
	|		ELSE ISNULL(BankClassifier.CashSettlementCenterBIC.Description, """")
	|	END                                                        AS NameOfBankSRCC,
	|	CASE
	|		WHEN ReportsToGiver.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN """"
	|		ELSE ISNULL(CorrespondentBankClassifier.CashSettlementCenterBIC.Description, """")
	|	END                                                        AS NameOfBankSRCCForSettlements,
	|	ReportsToGiver.CompanyBankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	ReportsToGiver.PriceIncludesVAT                               AS PriceIncludesVAT,
	|	ReportsToGiver.Currency                                        AS Currency,
	|	ReportsToGiver.Manager.Individual                       AS Manager,
	|	ReportsToGiver.AdditionalInformation                      AS AdditionalInformation,
	|	ReportsToGiver.DocumentAmount                                AS AmountToReturn,
	|	FALSE                                                         AS PartialPayment,
	|	""""                                                         AS PaymentPurposes,
	|	100                                                          AS PayPercentage,
	|	ReportsToGiver.DocumentAmount                                AS DocumentAmount,
	|	UNDEFINED                                                 AS Shipper,
	|	UNDEFINED                                                 AS GoodsRecipient,
	|	CASE
	|		WHEN ReportsToGiver.MaterialProviderOrder <> VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|			THEN ReportsToGiver.MaterialProviderOrder.PaymentID
	|		ELSE """"
	|	END                                                        AS PaymentID,
	|	FALSE                                                         AS InvoiceToBeRefunded
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS ReportsToGiver
	|		
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON ReportsToGiver.Ref = TableResponsiblePersons.Ref
	|		
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON ReportsToGiver.CompanyBankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS BankCountries
	|		ON BankClassifier.CountryCode = BankCountries.Code
	|		
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON ReportsToGiver.CompanyBankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS CountriesOfCorrespondentBanksOfRussianFederation
	|		ON CorrespondentBankClassifier.CountryCode = CountriesOfCorrespondentBanksOfRussianFederation.Code
	|		
	|WHERE
	|	ReportsToGiver.Ref IN(&ObjectsArray)
	|	
	|ORDER BY
	|	ReportsToGiver.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReportToMaterialProvider2_5PaymentScheduleSteps.Ref         AS Ref,
	|	FALSE                                              AS ThisIsDepositForPackage,
	|	ReportToMaterialProvider2_5PaymentScheduleSteps.LineNumber    AS LineNumber,
	|	ReportToMaterialProvider2_5PaymentScheduleSteps.PaymentDate    AS PaymentDate,
	|	ReportToMaterialProvider2_5PaymentScheduleSteps.PaymentPercentage AS PaymentPercentage,
	|	ReportToMaterialProvider2_5PaymentScheduleSteps.PaymentAmount   AS PaymentAmount
	|FROM
	|	Document.ReportToMaterialProvider2_5.PaymentScheduleSteps AS ReportToMaterialProvider2_5PaymentScheduleSteps
	|WHERE
	|	ReportToMaterialProvider2_5PaymentScheduleSteps.Ref IN(&ObjectsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductTable.LineNumber                       AS LineNumber,
	|	ProductTable.Ref                            AS Ref,
	|	ProductTable.Products                      AS Products,
	|	ProductTable.Products.Code                  AS Code,
	|	ProductTable.Products.SKU              AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, ProductTable.Products.DescriptionFull) AS DescriptionFull,
	|	ProductTable.VATRate                         AS VATRate,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(ProductTable.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	""""                                               AS Content,
	|	ProductTable.Price                              AS Price,
	|	ProductTable.Sum                             AS Sum,
	|	ProductTable.VATAmount                          AS VATAmount,
	|	ProductTable.Sum                             AS AmountWithoutADiscount,
	|	0                                                  AS DiscountAmount,
	|	ProductTable.NumberOfPackages                AS Count,
	|	ProductTable.Package                          AS Package,
	|	&QueryTextUnitOfMeasureDescription          AS UnitOfMeasure,
	|	FALSE                                               AS ThisIsReusablePackage
	|FROM
	|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS ProductTable
	|	
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON ProductTable.Products = ProductsPresentations.Ref
	|	AND ProductsPresentations.LanguageCode = &LanguageCode
	|	
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON ProductTable.Characteristic = ItemsCharacteristicsPresentations.Ref
	|	AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode
	|WHERE
	|	ProductTable.Ref IN(&ObjectsArray)
	|	
	|ORDER BY
	|	LineNumber
	|";
	
	Query.Text =
		StrReplace(
			Query.Text,
			"&QueryTextUnitOfMeasureDescription",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Description", "ProductTable.Package", "ProductTable.Products"));
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("LanguageCode", LanguageCode);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults",          RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages",   RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[2]);
	
	Return DataStructureForPrinting;
	
EndFunction

Function FormPrintedFormOfActOnProvisionOfServices(ObjectsArray, PrintObjects, PrintParameters = Undefined)
	
	SetPrivilegedMode(True);
	
	ShowVAT = Constants.DisplayAdditionalVATColumns.Get();
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "Parameters_Seals_ReportToMaterialProvider2_5_Act";
	
	StructureOfResults_ = GetDataToPrint(ObjectsArray, PrintParameters);
	
	PrintData        = StructureOfResults_["HeaderResults"].Select();
	SelectionByDocuments =
		StructureOfResults_["ResultForTabularPart"].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		// We will find services in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		FollowingIsFound = SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		// If there is an empty tabular part of the service in the document, let's move on to the next document
		If FollowingIsFound Then
			SelectingRows = SelectionByDocuments.Select();
			ThereIsVAT = PrintData.ConsiderVAT;
			SelectingRows.Reset();
		Else
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong chứng từ %1 không có dịch vụ. Không cần in biên bản bàn giao dịch vụ.';
					|ru = 'В документе %1 отсутствуют услуги. Печать акта выполненных работ (услуг) не требуется.';
					|en = 'Services are missing in document %1. Printing of ""Customer invoice — Services"" is not required.'; fa = 'Services are missing in document %1. Printing of ""Customer invoice — Services"" is not required.';
					|it = 'Non ci sono servizi nel documento %1. La stampa del verbale di consegna dei lavori (servizi) effettuati non è richiesta.';
					|pl = 'W dokumencie %1 nie ma żadnych usług. Drukowanie zestawienia wykonanych prac (usług) nie jest wymagane.';
					|tr = '%1 Belgesinde herhangi bir hizmet bulunmamaktadır. Gerçekleştirilen işler (hizmet) raporu yazdırmaya gerek yoktur'"),
				PrintData.Ref);
				
			Common.MessageToUser(Text, PrintData.Ref);
			Continue;
			
		EndIf;
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		Template = PrintManagement.PrintFormTemplate("Document.ReportToMaterialProvider2_5.PF_MXL_Act");
		
		// We display the header of the act
		
		TemplateArea = Template.GetArea("Title");
		
		AreaParameters_ = New Structure;
		AreaParameters_.Insert(
			"TitleText",
			TMCommonUseClientServer.GenerateDocumentTitle(PrintData, NStr("vi = 'In biên bản / hóa đơn GTGT';
																			|ru = 'Акт';
																			|en = 'Certificate'; fa = 'گواهی';
																			|it = 'Atto';
																			|pl = 'Protokół';
																			|tr = 'Tutanak'")));
		
		TemplateArea.Parameters.Fill(AreaParameters_);
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(
			SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
		
		SpreadsheetDocument.Put(TemplateArea);
		
		If Not PrintData.AdditionalInformationOfHeader = "" Then
			TemplateArea = Template.GetArea("AdditionalInformationOfHeader");
			TemplateArea.Parameters.AdditionalInformationOfHeader = PrintData.AdditionalInformationOfHeader;
			SpreadsheetDocument.Put(TemplateArea);
		EndIf;
		
		TemplateArea = Template.GetArea("HeaderText");
		
		SpreadsheetDocument.Put(TemplateArea);
				
		// Output the title of the Service table
		
		If ThereIsVAT And ShowVAT Then
			AreaNameHeader  = "HeaderOfTableWithVAT";
			AreaNameString = "StringWithVAT";
		Else
			AreaNameHeader  = "TableHeader";
			AreaNameString = "String";
		EndIf;
		
		TemplateArea = Template.GetArea(AreaNameHeader);
		RowArea = Template.GetArea(AreaNameString);
		
		SpreadsheetDocument.Put(TemplateArea);
		
		If Not PrintData.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
			And Not PrintData.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
			ServiceLineArea = Template.GetArea("LineService");
			ServiceLineArea.Parameters.ProcessingService = TrimAll(PrintData.ProcessingService);
			SpreadsheetDocument.Put(ServiceLineArea);
		EndIf;
		
		Sum       = 0;
		VATAmount    = 0;
		AmountIncludingVAT   = 0;
		LineNumber = 0;
		
		// Output the rows of the Services table
		
		While SelectingRows.Next() Do
			
			LineNumber = LineNumber + 1;
			
			RowArea.Parameters.Fill(SelectingRows);
			
			AreaParameters_ = New Structure;
			AreaParameters_.Insert("LineNumber", LineNumber);
			AreaParameters_.Insert(
				"OwnGoods",
				ProductsClientServer.PresentationOfProductsForPrinting(
					SelectingRows.ProductFullName,
					SelectingRows.CharacteristicFullName));
			
			RowArea.Parameters.Fill(AreaParameters_);
			
			Sum     = Sum + SelectingRows.Sum;
			VATAmount  = VATAmount + SelectingRows.VATAmount;
			AmountIncludingVAT = AmountIncludingVAT + SelectingRows.AmountIncludingVAT;
			
			SpreadsheetDocument.Put(RowArea);
			
		EndDo;
		
		TemplateArea = Template.GetArea("InTotal");
		TemplateArea.Parameters.Total = PrintFormGeneration.SumFormat(Sum);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("TotalVAT_");
		
		TemplateArea.Parameters.TotalVAT = VATAmount;
		If ThereIsVAT Then
			TemplateArea.Parameters.VAT =
				?(PrintData.PriceIncludesVAT, NStr("vi = 'Trong đó thuế GTGT:';
													|ru = 'В том числе НДС:';
													|en = 'Including VAT:'; fa = 'Including VAT:';
													|it = 'IVA compresa:';
													|pl = 'W tym VAT';
													|tr = 'KDV dahil:'"), NStr("vi = 'Thuế GTGT:';
																					|ru = 'Сумма НДС:';
																					|en = 'VAT amount:'; fa = 'مبلغ مالیات بر ارزش افزوده:';
																					|it = 'Importo IVA:';
																					|pl = 'Wartość VAT';
																					|tr = 'KDV tutarı:'"));
		Else
			TemplateArea.Parameters.VAT = NStr("vi = 'Không gồm thuế (GTGT)';
												|ru = 'Без налога (НДС)';
												|en = 'Without tax (VAT)'; fa = 'بدون مالیات (مالیات بر ارزش افزوده)';
												|it = 'senza imposta (IVA)';
												|pl = 'bez podatku (VAT)';
												|tr = 'Vergisiz (KDV)'");
		EndIf;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("TotalWithVAT_");
		If ThereIsVAT Then
			TemplateArea.Parameters.TotalWithVAT = AmountIncludingVAT;
			SpreadsheetDocument.Put(TemplateArea);
		EndIf;
		
		AmountToBeRegistered = Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount);
		TemplateArea = Template.GetArea("AmountInWords");
		
		TotalString = StrTemplate(
							NStr("vi = 'Tổng số công việc được thực hiện (dịch vụ được cung cấp) đối với số tiền %1';
								|ru = 'Всего выполнено работ (оказано услуг) на сумму %1';
								|en = 'Total works performed (services rendered) in the amount of %1'; fa = 'Total works performed (services rendered) in the amount of %1';
								|it = 'Totale lavori completati (servizi forniti) all''importo %1';
								|pl = 'Całkowita ilość wykonanych prac (świadczonych usług) o wartości %1';
								|tr = 'Gerçekleştirilen tüm işler (sağlanan hizmetler) tutarı %1'"),
							PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));
		
		TemplateArea.Parameters.TotalString = TotalString;
		TemplateArea.Parameters.AmountInWords  =
			CurrencyRateOperations.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency);
		SpreadsheetDocument.Put(TemplateArea);
		
		If Not PrintData.AdditionalInformation="" Then
			TemplateArea = Template.GetArea("AdditionalInformation");
			TemplateArea.Parameters.AdditionalInformation = PrintData.AdditionalInformation;
			SpreadsheetDocument.Put(TemplateArea);
		EndIf;
		
		InformationAboutPerformer = PrintFormGeneration.InformationAboutLegalEntity(
									PrintData.Organization, PrintData.Date,, PrintData.BankAccountOfCompany);
			
		CustomerInformation	 = PrintFormGeneration.InformationAboutLegalEntity(
									PrintData.Counterparty, PrintData.Date,, PrintData.AccountOfCounterparty);
		
		TemplateArea = Template.GetArea("Signatures");
		TemplateArea.Parameters.ArtistPresentation = InformationAboutPerformer.OfficialName;
		TemplateArea.Parameters.CustomerPresentation_0 	 = CustomerInformation.OfficialName;
		TemplateArea.Parameters.PerformerSLegalAddress 		 = InformationAboutPerformer.LegalAddress;
		TemplateArea.Parameters.CustomerSLegalAddress 		 = CustomerInformation.LegalAddress;
		TemplateArea.Parameters.TinOfPerformer			 = InformationAboutPerformer.TIN;
		TemplateArea.Parameters.InnOfCustomer			 = CustomerInformation.TIN;
		TemplateArea.Parameters.ContractorSCheckpoint			 = InformationAboutPerformer.CRTR;
		TemplateArea.Parameters.CustomerSCheckpoint			 = CustomerInformation.CRTR;
		TemplateArea.Parameters.ContractorSCurrentAccount = InformationAboutPerformer.AccountNumber;
		TemplateArea.Parameters.CustomerSCurrentAccount	 = CustomerInformation.AccountNumber;
		TemplateArea.Parameters.ArtistSCorAccount		 = InformationAboutPerformer.CorrAccount;
		TemplateArea.Parameters.CustomerSCorAccount		 = CustomerInformation.CorrAccount;
		TemplateArea.Parameters.ContractorSBank			 = InformationAboutPerformer.Bank;
		TemplateArea.Parameters.CustomerSBank			 = CustomerInformation.Bank;
		TemplateArea.Parameters.PerformerSBIC			 = InformationAboutPerformer.BIC;
		TemplateArea.Parameters.CustomerSBIC			 = CustomerInformation.BIC;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

Function PrintingDataOfMaterialsReport(ObjectsArray)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ReportToMaterialProvider2_5.Ref              AS Ref,
	|	ReportToMaterialProvider2_5.Number               AS Number,
	|	ReportToMaterialProvider2_5.Date                AS Date,
	|	ReportToMaterialProvider2_5.Partner             AS Partner,
	|	ReportToMaterialProvider2_5.Counterparty          AS Counterparty,
	|	ReportToMaterialProvider2_5.Organization         AS Organization,
	|	ReportToMaterialProvider2_5.Organization.Prefix AS Prefix
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS ReportToMaterialProvider2_5
	|WHERE
	|	ReportToMaterialProvider2_5.Ref IN (&DocumentsArray)
	|
	|ORDER BY
	|	Ref";
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	Return Query.Execute().Select();
	
EndFunction

// To form a printed form of a report on materials.
// 
// Parameters:
//  PrintData - Array of DocumentRef - Print data
//  PrintObjects - ValueList - Print Objects
//  SpreadsheetDocument - SpreadsheetDocument - Table document
// 
// Returns:
//  SpreadsheetDocument - The generated printed form of the report on materials
Function ToFormPrintedFormOfReportOnProductsAndMaterials(PrintData, PrintObjects, SpreadsheetDocument) Export
	
	SetPrivilegedMode(True);
	
	ColumnOfCodes              = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	Column                   = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes              = ValueIsFilled(Column);
	
	Template = PrintManagement.PrintFormTemplate("Document.ReportToMaterialProvider2_5.PF_MXL_ReportOnProductsAndMaterials");
	
	ScopeOfApplication_10 = Template.Area("OwnGoods");
	If OutputCodes Then
		
		AreaCodesHeader = Template.GetArea("TableHeader|ColumnOfCodes");
		AreaCodesHeader.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
		
		AreaCodesString = Template.GetArea("String|ColumnOfCodes");
		AreaCodesBasement = Template.GetArea("Footer|ColumnOfCodes");
	
	Else
		ScopeOfApplication_10.ColumnWidth = ScopeOfApplication_10.ColumnWidth + Template.Area("ColumnOfCodes").ColumnWidth;
	EndIf;
	
	AreaOfHeaderNumber = Template.GetArea("TableHeader|LineNumber");
	HeaderDataArea = Template.GetArea("TableHeader|OwnGoods");
	AreaEndOfLineHeader = Template.GetArea("TableHeader|EndOfRow");
	
	NumberAreaLine = Template.GetArea("String|LineNumber");
	DataAreaRow = Template.GetArea("String|OwnGoods");
	AreaEndOfLineString = Template.GetArea("String|EndOfRow");
	
	RoomAreaBasement = Template.GetArea("Footer|LineNumber");
	DataAreaBasement = Template.GetArea("Footer|OwnGoods");
	AreaEndOfLineBasement = Template.GetArea("Footer|EndOfRow");
	
	SignatureArea = Template.GetArea("Signatures");
	
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		AccountingPolicyParameters =
			AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
				"FinancialAccountingPolicy",
				PrintData.Organization,
				PrintData.Date);
			
		If Not AccountingPolicyParameters = Undefined
			And AccountingPolicyParameters.InventoryValuationMethod =
				Enums.InventoryValuationMethods.FIFORollingValuation Then
			
			TempTableManager = New TempTablesManager;
			
			CostTreeParameters = CostStructure.CostTreeParameters();
			CostTreeParameters.DynamicReading = False;
			CostTreeParameters.ResultTypeTempTableManager = True;
			CostTreeParameters.TempTablesManager = TempTableManager;
			
			CostTreeParameters.ReportParameters.Cost_Data = 3;
			CostTreeParameters.ReportParameters.Recorders.Add(PrintData.Ref);
			CostTreeParameters.ReportParameters.DeployAdditionalCosts = False;
			CostStructure.BuildCostTree(CostTreeParameters);
			
			CostRequest = New Query;
			CostRequest.TempTablesManager = TempTableManager;
			
			CostRequest.Text =
			"SELECT
			// ManufacturedProduct
			|	CAST(ManufacturedProduct.ProductsAccountingDimension AS Catalog.InventoryLocationAttributeKeys) AS ProductsAccountingDimension,
			|	CAST(SUM(ManufacturedProduct.Count) AS NUMBER(31, 2))                                     AS NumberOfProducts_1,
			|	CAST(ManufacturedProduct.UnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure)               AS UnitOfMeasure
			|INTO CurrentReportMANUFACTUREDProducts
			|FROM
			|	Result AS ManufacturedProduct
			|WHERE
			|	ManufacturedProduct.LineKind = VALUE(Enum.KindsOfCostTreeRows.ProductsBatch)
			|
			|GROUP BY
			// ManufacturedProduct
			|	ManufacturedProduct.ProductsAccountingDimension,
			|	ManufacturedProduct.UnitOfMeasure
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			// ManufacturedProduct
			|	ManufacturedProduct.ProductsAccountingDimension                                                   AS ProductsAccountingDimension,
			|	ManufacturedProduct.ProductsAccountingDimension.Products                                      AS ProductManufacturedProducts,
			|	ManufacturedProduct.ProductsAccountingDimension.Products.DescriptionFull                   AS ProductNameProducts,
			|	ManufacturedProduct.ProductsAccountingDimension.Products.Code                                  AS CodeProduct,
			|	ManufacturedProduct.ProductsAccountingDimension.Products.SKU                              AS ArticleProducts,
			|	ISNULL(ManufacturedProduct.ProductsAccountingDimension.Characteristic.DescriptionFull, """") AS CharacteristicManufacturedProducts,
			|	CAST(MAX(ManufacturedProduct.NumberOfProducts_1) AS NUMBER(31, 2))                  AS NumberOfProducts_1,
			|	REFPRESENTATION(ManufacturedProduct.UnitOfMeasure)                                     AS RepresentationOfBasicUnitOfMeasurementProducts,
			// Cost_
			|	Costs.Products                                      AS OwnGoods,
			|	Costs.Products.DescriptionFull                   AS ProductItemName,
			|	Costs.Products.Code                                  AS Code,
			|	Costs.Products.SKU                              AS SKU,
			|	ISNULL(Costs.Characteristic.DescriptionFull, """") AS Characteristic,
			|	CAST(SUM(Costs.Count) AS NUMBER(31, 2))      AS Count,
			|	REFPRESENTATION(Costs.UnitOfMeasure)             AS PresentationOfBasicUnitOfMeasure
			|FROM
			|	CurrentReportMANUFACTUREDProducts AS ManufacturedProduct
			|	
			|	INNER JOIN Result AS Costs
			|	ON Costs.ProductsAccountingDimension = ManufacturedProduct.ProductsAccountingDimension
			|	AND Costs.LineKind = VALUE(Enum.KindsOfCostTreeRows.LotCosts)
			|	AND VALUETYPE(Costs.BatchCost) = TYPE(Document.GoodsReceiptForStorage)
			|	AND CAST(Costs.BatchCost AS Document.GoodsReceiptForStorage).BusinessOperation =
			|		VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5)
			|
			|GROUP BY
			// ManufacturedProduct
			|	ManufacturedProduct.ProductsAccountingDimension,
			|	ManufacturedProduct.ProductsAccountingDimension.Products,
			|	ManufacturedProduct.ProductsAccountingDimension.Products.DescriptionFull,
			|	ManufacturedProduct.ProductsAccountingDimension.Products.Code,
			|	ManufacturedProduct.ProductsAccountingDimension.Products.SKU,
			|	ISNULL(ManufacturedProduct.ProductsAccountingDimension.Characteristic.DescriptionFull, """"),
			|	REFPRESENTATION(ManufacturedProduct.UnitOfMeasure),
			// Cost_
			|	Costs.Products,
			|	Costs.Products.DescriptionFull,
			|	Costs.Products.Code,
			|	Costs.Products.SKU,
			|	ISNULL(Costs.Characteristic.DescriptionFull, """"),
			|	REFPRESENTATION(Costs.UnitOfMeasure)
			|
			|TOTALS
			|	MAX(ProductManufacturedProducts),
			|	MAX(ProductNameProducts),
			|	MAX(CodeProduct),
			|	MAX(ArticleProducts),
			|	MAX(CharacteristicManufacturedProducts),
			|	MAX(NumberOfProducts_1),
			|	MAX(RepresentationOfBasicUnitOfMeasurementProducts)
			|BY
			|	ProductsAccountingDimension
			|";
			
			ProductSampling = CostRequest.Execute().Select(QueryResultIteration.ByGroups);
			ThereAreMaterialsGiver = ProductSampling.Count() > 0;
			
		Else
			Text =
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chứng từ %1: Đối với doanh nghiệp, đã thiết lập phương thức đánh giá giá trị hàng hóa ""Theo bình quân trong tháng"". Không cho phép in báo cáo.';
						|ru = 'Документ %1: Для организации установлен метод оценки стоимости товаров ""По средней за месяц"". Печать отчета недоступна.';
						|en = '%1 document: The ""Monthly average"" inventory valuation method is set for the company. Cannot print the report.'; fa = '%1 document: The ""Monthly average"" inventory valuation method is set for the company. Cannot print the report.';
						|it = 'Documento %1: per l''azienda è impostato il metodo di valutazione del prezzo delle merci ""Media mensile"". Impossibile stampare il report.';
						|pl = 'Dokument %1: Dla firmy jest ustawiona metoda oszacowania wartości towarów ""Według średniej miesięcznej"". Drukowanie raportu jest niedostępne.';
						|tr = 'Belge %1: İş yeri, malların stok değerleme yöntemini ""Bir aylık ortalama"" olarak belirlemiştir. Raporun yazdırılması mümkün değildir.'"),
					PrintData.Ref);
			Common.MessageToUser(Text, PrintData.Ref);
			Continue;
		EndIf;
		
		If Not ThereAreMaterialsGiver Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chứng từ %1: trong quá trình sản xuất các sản phẩm, vật liệu của nhà thầu không được sử dụng hoặc chi phí không được tính. Không cần in báo cáo';
					|ru = 'Документ %1: при производстве продукции не использовались материалы давальца, либо не рассчитана себестоимость. Печать отчета не требуется';
					|en = 'Document %1: materials of the material provider were not used during production or cost was not calculated.  It is not necessary to print a report.'; fa = 'Document %1: materials of the material provider were not used during production or cost was not calculated.  It is not necessary to print a report.';
					|it = 'Documento %1: durante la fabbricazione di prodotti non sono stati utilizzati i materiali del committente, oppure il costo di produzione non è stato calcolato. Non è richiesta la stampa del report';
					|pl = 'Dokument %1: w produkcji wyrobów nie korzystano z materiałów dostawcy, lub nie został obliczony koszt własny. Druk raportu nie jest wymagany';
					|tr = 'Belge %1: Üretimde herhangi bir sağlayıcı malzemesi kullanılmamış veya üretim maliyeti hesaplanmamıştır. Raporun basılması gerekli değildir'"),
				PrintData.Ref);
			Common.MessageToUser(Text, PrintData.Ref);
			Continue;
		EndIf;
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice
		TemplateArea = Template.GetArea("Title");
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(
			SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
		
		AreaParameters_ = New Structure;
		AreaParameters_.Insert(
			"TitleText",
			TMCommonUseClientServer.GenerateDocumentTitle(
				PrintData,
				NStr("vi = 'Báo cáo về sản phẩm và nguyên vật liệu';
					|ru = 'Отчет о продукции и материалах';
					|en = 'Report on manufactured products and materials'; fa = 'گزارش محصولات تولیدی و مواد';
					|it = 'Report su prodotti e materiali';
					|pl = 'Raport o produkcji i materiałach';
					|tr = 'Ürün ve malzemelere ilişkin rapor'", Common.DefaultLanguageCode())));
		
		AreaParameters_.Insert(
			"PerformerPresentation",
			PrintFormGeneration.OrganizationDescription(
				PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date), 
				"FullDescr"));
		
		AreaParameters_.Insert(
			"Customer_Presentation",
			PrintFormGeneration.OrganizationDescription(
				PrintFormGeneration.InformationAboutLegalEntity(PrintData.Counterparty, PrintData.Date), 
				"FullDescr"));
		
		TemplateArea.Parameters.Fill(AreaParameters_);
		
		SpreadsheetDocument.Put(TemplateArea);
		
		SpreadsheetDocument.Put(AreaOfHeaderNumber);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaCodesHeader);
		EndIf;
		
		SpreadsheetDocument.Join(HeaderDataArea);
		
		SpreadsheetDocument.Join(AreaEndOfLineHeader);
		
		LineNumberProducts = 1;
		
		While ProductSampling.Next() Do
			
			AreaParameters_ = New Structure;
			AreaParameters_.Insert("LineNumber", LineNumberProducts);
			
			NumberAreaLine.Parameters.Fill(AreaParameters_);
			
			SpreadsheetDocument.Put(NumberAreaLine);
			
			If OutputCodes
				And Column = "Code" Then
				AreaCodesString.Parameters.SKU = ProductSampling.CodeProduct;
				SpreadsheetDocument.Join(AreaCodesString);
			ElsIf OutputCodes Then
				AreaCodesString.Parameters.SKU = ProductSampling.ArticleProducts;
				SpreadsheetDocument.Join(AreaCodesString);
			EndIf;
			
			AdditionalParametersProductPresentation =
				ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			DataAreaRow.Parameters.OwnGoods =
				ProductsClientServer.PresentationOfProductsForPrinting(
					TrimAll(ProductSampling.ProductNameProducts),
					TrimAll(ProductSampling.CharacteristicManufacturedProducts),,,
					AdditionalParametersProductPresentation);
			
			SpreadsheetDocument.Join(DataAreaRow);
			
			AreaEndOfLineString.Parameters.Count =
				ProductSampling.NumberOfProducts_1;
			AreaEndOfLineString.Parameters.PresentationOfBasicUnitOfMeasure =
				ProductSampling.RepresentationOfBasicUnitOfMeasurementProducts;
			
			SpreadsheetDocument.Join(AreaEndOfLineString);
			
			LineNumberCost = 1;
			
			CostSampling = ProductSampling.Select();
			While CostSampling.Next() Do
				
				AreaParameters_ = New Structure;
				AreaParameters_.Insert("LineNumber", String(LineNumberProducts) + "." + String(LineNumberCost));
				
				NumberAreaLine.Parameters.Fill(AreaParameters_);
				
				SpreadsheetDocument.Put(NumberAreaLine);
				
				If OutputCodes Then
					AreaCodesString.Parameters.SKU = CostSampling[Column];
					SpreadsheetDocument.Join(AreaCodesString);
				EndIf;
				
				AdditionalParametersProductPresentation =
					ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
				AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
				
				DataAreaRow.Parameters.OwnGoods =
					Chars.Tab + ProductsClientServer.PresentationOfProductsForPrinting(
						TrimAll(CostSampling.ProductItemName),
						TrimAll(CostSampling.Characteristic),,,
						AdditionalParametersProductPresentation);
				
				SpreadsheetDocument.Join(DataAreaRow);
				
				AreaEndOfLineString.Parameters.Fill(CostSampling);
				SpreadsheetDocument.Join(AreaEndOfLineString);
				
				LineNumberCost = LineNumberCost + 1;
				
			EndDo;
			
			LineNumberProducts = LineNumberProducts + 1;
			
		EndDo;
		
		SpreadsheetDocument.Put(RoomAreaBasement);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaCodesBasement);
		EndIf;
		
		SpreadsheetDocument.Join(DataAreaBasement);
		
		SpreadsheetDocument.Join(AreaEndOfLineBasement);
		
		// Print signatures.
		SpreadsheetDocument.Put(SignatureArea);
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

Function CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects) Export
	
	Var AddressOfSetOfPrintedForms;
	
	If TypeOf(PrintParameters) = Type("Structure")
	   And PrintParameters.Property("AddressOfSetOfPrintedForms", AddressOfSetOfPrintedForms) Then
		
		PrintFormsSet = GetFromTempStorage(AddressOfSetOfPrintedForms);
		
	Else
		
		PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrintFormsSet(
									Metadata.Documents.ReportToMaterialProvider2_5.FullName(), ObjectsArray);
		
	EndIf;
		
	If PrintFormsSet = Undefined Then
		Return Undefined;
	EndIf;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(
									PrintFormsCollection, PrintFormsSet, ObjectsArray, "CustomerInvoiceServices");
	
	For Each PrintKit In SetsOfPrintingOnObjects Do
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			FormPrintedFormOfActOnProvisionOfServices(PrintKit.Objects, PrintObjects));
		
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(
									PrintFormsCollection, PrintFormsSet, ObjectsArray, "ReportOnProductsAndMaterials");
	
	For Each PrintKit In SetsOfPrintingOnObjects Do
		
		SpreadsheetDocument = New SpreadsheetDocument;
		SpreadsheetDocument.PrintParametersName = "Parameters_Seals_ReportToMaterialProvider2_5_ReportOnProductsAndMaterials";
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			ToFormPrintedFormOfReportOnProductsAndMaterials(
				PrintingDataOfMaterialsReport(ObjectsArray),
				PrintObjects,
				SpreadsheetDocument));
		
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(
									PrintFormsCollection, PrintFormsSet, ObjectsArray, "ProformaInvoice");
	
	For Each PrintKit In SetsOfPrintingOnObjects Do
		
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.ReportToMaterialProvider2_5", PrintKit.Objects);
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.GeneratePrintedInvoiceForm(
				StructureOfTypes, PrintObjects, PrintParameters));
		
	EndDo;
	
	ReportToMaterialProvider2_5Localization.CreateSetOfPrintedForms(
		ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, PrintFormsSet);
		
	InformationRegisters.ObjectPrintSettings.FormSetOfExternalPrintingPlates(
		"Document.ReportToMaterialProvider2_5", ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects);
	
EndFunction

Function PrintFormsSet() Export
	
	PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrepareSetOfPrintedForms();
	
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(
		PrintFormsSet, "CustomerInvoiceServices",  NStr("vi = 'Biên bản nghiệm thu công việc';
														|ru = 'Акт выполненных работ';
														|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
														|it = 'Verbale di consegna dei lavori effettuati';
														|pl = 'Protokół wykonanych prac';
														|tr = 'Gerçekleştirilen işler raporu'"), 1);
	
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(
		PrintFormsSet, "ReportOnProductsAndMaterials", NStr("vi = 'Báo cáo về sản phẩm và nguyên vật liệu';
															|ru = 'Отчет о продукции и материалах';
															|en = 'Report on manufactured products and materials'; fa = 'گزارش محصولات تولیدی و مواد';
															|it = 'Report su prodotti e materiali';
															|pl = 'Raport o produkcji i materiałach';
															|tr = 'Ürün ve malzemelere ilişkin rapor'"), 1);
	
	If GetFunctionalOption("DoNotUseCommercialInvoicesAndSelectDiscountDisplayOption")
	 Or GetFunctionalOption("DoNotUseCommercialInvoicesAndDoNotSelectDiscountDisplayOption") Then
		
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(
			PrintFormsSet, "ProformaInvoice", NStr("vi = 'Hóa đơn thanh toán';
													|ru = 'Счет на оплату';
													|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
													|it = 'Fattura di pagamento';
													|pl = 'Rachunek do zapłaty';
													|tr = 'Ticari fatura'"), 1);
		
	EndIf;
	
	ReportToMaterialProvider2_5Localization.PrintFormsSet(PrintFormsSet);
		
	Return PrintFormsSet;
	
EndFunction

Function AddCommandsToPrintSetOfDocuments() Export
	Return Not UserRightsCached.ThisIsPartner();
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
			Or AccessRight("View", Metadata.Documents.ReportToMaterialProvider2_5))
		And AccessRight("View", Metadata.Documents.MaterialProviderOrder2_5)
		And (AccessRight("Insert", Metadata.Documents.ReportToMaterialProvider2_5)
			Or AccessRight("Update", Metadata.Documents.ReportToMaterialProvider2_5))
		And GetFunctionalOption("UseTollManufacturing2_5");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	FilterParameters = InvoicesServer.OrderSelectionParameters();
	
	TypesOfOrders = New Array;
	TypesOfOrders.Add("Document.MaterialProviderOrder2_5");
	
	QueriesTexts = New Array;
	QueriesTexts.Add(InvoicesServer.StateRequestText(
								"StatesOfReportsToGivers2_5",
								FilterParameters,
								TypesOfOrders));
	
	QueriesTexts.Add("SELECT
							|	RemnantsOfState.ReferenceOrder AS Ref
							|FROM
							|	TTStateReportsToGivers2_5 AS RemnantsOfState");
	
	Query = New Query;
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	
	ReportsToMaterialProvidersForRegistration2_5 = Query.Execute().Select().Count();
	
	// Filling out cases.
	// Recycling of metal raw materials2_5
	UserTaskParent = ToDoList.Find("ProcessingOfProvidedMaterials2_5", "Id");
	If UserTaskParent = Undefined Then
		UserTaskParent = ToDoList.Add();
		UserTaskParent.Id = "ProcessingOfProvidedMaterials2_5";
		UserTaskParent.Presentation = NStr("vi = 'Gia công sản xuất';
											|ru = 'Переработка давальческого сырья';
											|en = 'Subcontracting services'; fa = 'خدمات پیمانکاری فرعی';
											|it = 'Trasformazione di materie prime del committente';
											|pl = 'Przetwarzanie surowców dostarczonych przez klienta';
											|tr = 'Sağlayıcı hammaddelerinin yeniden işlenmesi'");
		UserTaskParent.Owner      = Metadata.Subsystems.Sales;
	EndIf;
	
	UserTaskParent.HasToDoItems = UserTaskParent.HasToDoItems Or ReportsToMaterialProvidersForRegistration2_5 > 0;
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentPageName",      "ReportsPage");
	FormParameters.Insert("FormAssignmentKey",     "ToDoList");
	FormParameters.Insert("QuickFilterStructure", New Structure);
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "ReportsToMaterialProvidersForRegistration2_5";
	ToDoItem.HasToDoItems       = ReportsToMaterialProvidersForRegistration2_5 > 0;
	ToDoItem.Presentation  = NStr("vi = 'Báo cáo cho các đại lý để đăng ký';
									|ru = 'Отчеты давальцам к оформлению';
									|en = '""Consumption reports — Subcontracting services delivered"" for registration'; fa = '""Consumption reports — Subcontracting services delivered"" for registration';
									|it = 'Report ai prestatori per da formalizzare';
									|pl = 'Raporty dostawcom do wystawienia';
									|tr = 'Düzenlenecek Tüketim raporları - Verilen fason hizmetleri'");
	ToDoItem.Count     = ReportsToMaterialProvidersForRegistration2_5;
	ToDoItem.Important         = False;
	ToDoItem.Form          = "DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices";
	ToDoItem.FormParameters = FormParameters;
	ToDoItem.Owner       = "ProcessingOfProvidedMaterials2_5";
	
EndProcedure

#EndRegion

#Region Other

// Generates the request text that receives the payment schedule for the document
//
// Returns:
//   String   - the generated request text.
//
Function RequestTextTableSettlementsWithCustomersDocumentState()

	QueryText =
	"SELECT ALLOWED
	|	DocumentInvoice.Ref                       AS Document,
	|	DocumentInvoice.LineNumber                  AS LineNumber,
	|	PRESENTATION(DocumentInvoice.PaymentOption) AS PaymentOption,
	|	DocumentInvoice.PaymentDate                  AS PaymentDate,
	|	DocumentInvoice.PaymentAmount                 AS PaymentAmount
	|FROM
	|	Document.ReportToMaterialProvider2_5.PaymentScheduleSteps AS DocumentInvoice
	|	
	|		INNER JOIN ARAPObjects AS ARAPObjects
	|		ON ARAPObjects.ARAPObject = DocumentInvoice.Ref
	|		 AND ARAPObjects.ScheduleIsRequired
	|	
	|UNION ALL
	|	
	|SELECT
	|	DocumentPaymentScheduleSteps.Ref                       AS Document,
	|	DocumentPaymentScheduleSteps.LineNumber                  AS LineNumber,
	|	PRESENTATION(DocumentPaymentScheduleSteps.PaymentOption) AS PaymentOption,
	|	DocumentPaymentScheduleSteps.PaymentDate                  AS PaymentDate,
	|	DocumentPaymentScheduleSteps.PaymentAmount                 AS PaymentAmount
	|FROM
	|	Document.MaterialProviderOrder2_5.PaymentScheduleSteps AS DocumentPaymentScheduleSteps
	|	
	|		INNER JOIN ARAPObjects AS ARAPObjects
	|		ON ARAPObjects.ARAPObject = DocumentPaymentScheduleSteps.Ref
	|		 AND ARAPObjects.ScheduleIsRequired";
	
	Return QueryText;
	
EndFunction 

// Generates the result of a request for outstanding order Balances
//
// Parameters:
//  SelectionData_  - Structure - fields that will be used to select the Balance of orders to fill in
//  AnArrayOfOrders - Array - orders for which balances will be selected
//
// Returns:
//  QueryResult - 
//
Function GetQueryResultsForOrderBalances(SelectionData_, AnArrayOfOrders = Undefined)
	
	Query = New Query;
	Query.SetParameter("FilterByOrders",          AnArrayOfOrders <> Undefined);
	Query.SetParameter("AnArrayOfOrders",           AnArrayOfOrders);
	Query.SetParameter("Recorder",             SelectionData_.Ref);
	Query.SetParameter("Organization",             SelectionData_.Organization);
	Query.SetParameter("Currency",                  SelectionData_.ARAPCurrency);
	Query.SetParameter("Counterparty",              SelectionData_.Counterparty);
	Query.SetParameter("Contract",                 SelectionData_.Contract);
	Query.SetParameter("Partner",                 SelectionData_.Partner);
	Query.SetParameter("SalesOpportunity",                  SelectionData_.SalesOpportunity);
	Query.SetParameter("VATTaxation",      SelectionData_.VATTaxation);
	Query.SetParameter("Warehouse",                   SelectionData_.Warehouse);
	Query.SetParameter("LineOfBusiness", SelectionData_.LineOfBusiness);
	
	If SelectionData_.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5 Then
		Query.SetParameter("BusinessOperation", Enums.BusinessTransactions.TollManufacturing2_5);
	Else
		Query.SetParameter("BusinessOperation", SelectionData_.BusinessOperation);
	EndIf;
	
	Query.SetParameter(
		"UseLinesOfBusiness",
		GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness"));
	
	Query.TempTablesManager = New TempTablesManager();
	
	Query.Text =
	"SELECT ALLOWED
	|	MaterialProviderOrder2_5.Ref AS Ref
	|INTO TheOrdersTable
	|FROM
	|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
	|WHERE
	|	CASE
	|		WHEN &FilterByOrders
	|			THEN MaterialProviderOrder2_5.Ref IN (&AnArrayOfOrders)
	|		ELSE MaterialProviderOrder2_5.Organization           = &Organization
	|			AND MaterialProviderOrder2_5.Currency                = &Currency
	|			AND MaterialProviderOrder2_5.Counterparty            = &Counterparty
	|			AND MaterialProviderOrder2_5.Contract               = &Contract
	|			AND MaterialProviderOrder2_5.Partner               = &Partner
	|			AND MaterialProviderOrder2_5.SalesOpportunity                = &SalesOpportunity
	|			AND MaterialProviderOrder2_5.VATTaxation    = &VATTaxation
	|			AND MaterialProviderOrder2_5.BusinessOperation = &BusinessOperation
	|			AND (NOT &UseLinesOfBusiness
	|				OR MaterialProviderOrder2_5.LineOfBusiness = &LineOfBusiness)
	|			AND (MaterialProviderOrder2_5.Warehouse = &Warehouse
	|				OR &Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|					 AND MaterialProviderOrder2_5.Warehouse IN HIERARCHY (&Warehouse)
	|				OR MaterialProviderOrder2_5.Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
	|			AND MaterialProviderOrder2_5.Posted
	|	END
	|
	|INDEX BY
	|	Ref
	|;
	|SELECT
	|	MIN(TheOrdersTable.Ref.Date) AS Date
	|FROM
	|	TheOrdersTable AS TheOrdersTable";
	Selection = Query.Execute().Select();
	If Selection.Next() And ValueIsFilled(Selection.Date) Then
		Query.SetParameter("StartDate", Selection.Date);
	Else
		Query.SetParameter("StartDate", Date(1,1,1));
	EndIf;

	Query.Text =
	"SELECT
	|	TableOfOrdersToBeProcessed.SalesOrder AS MaterialProviderOrder,
	|	TableOfOrdersToBeProcessed.Products AS Products,
	|	TableOfOrdersToBeProcessed.Characteristic AS Characteristic,
	|	TableOfOrdersToBeProcessed.RowCode AS RowCode,
	|	TableOfOrdersToBeProcessed.Warehouse AS Warehouse,
	|	TableOfOrdersToBeProcessed.Series AS Series,
	|	SUM(TableOfOrdersToBeProcessed.ToRegister) AS Count,
	|	SUM(TableOfOrdersToBeProcessed.Sum) AS Sum
	|INTO BalanceTable
	|FROM
	|	(SELECT
	|		TurnoversByOrders.ReferenceOrder AS SalesOrder,
	|		TurnoversByOrders.Products AS Products,
	|		TurnoversByOrders.Characteristic AS Characteristic,
	|		TurnoversByOrders.RowCode AS RowCode,
	|		TurnoversByOrders.Warehouse AS Warehouse,
	|		TurnoversByOrders.Series AS Series,
	|		(TurnoversByOrders.ForRegistrationQuantityTurnover
	|			- TurnoversByOrders.IssuedQuantityTurnover) AS ToRegister,
	|		(TurnoversByOrders.AmountToBeProcessedTurnover
	|			- TurnoversByOrders.IssuedAmountTurnover) AS Sum
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded1 AS TurnoversByOrders
	|	WHERE
	|		(TurnoversByOrders.ForRegistrationQuantityTurnover
	|			- TurnoversByOrders.IssuedQuantityTurnover) <> 0
	|		OR (TurnoversByOrders.AmountToBeProcessedTurnover
	|			- TurnoversByOrders.IssuedAmountTurnover) <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ShipmentReferences.ReferenceOrder,
	|		ShipmentReferences.Products,
	|		ShipmentReferences.Characteristic,
	|		ShipmentReferences.RowCode,
	|		ShipmentReferences.Warehouse,
	|		ShipmentReferences.Series,
	|		ShipmentReferences.Count,
	|		ShipmentReferences.Sum
	|	FROM
	|		AccumulationRegister.ShipmentAndReturnReferences AS ShipmentReferences
	|	WHERE
	|		ShipmentReferences.Active
	|		AND ShipmentReferences.Period >= &StartDate
	|		AND ShipmentReferences.Factor =
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
	|		AND ShipmentReferences.Recorder = &Recorder
	|		AND ShipmentReferences.ReferenceOrder IN
	|				(SELECT
	|					TheOrdersTable.Ref AS Ref
	|				FROM
	|					TheOrdersTable AS TheOrdersTable)
	|		AND ShipmentReferences.RowCode <> 0) AS TableOfOrdersToBeProcessed
	|
	|GROUP BY
	|	TableOfOrdersToBeProcessed.SalesOrder,
	|	TableOfOrdersToBeProcessed.Products,
	|	TableOfOrdersToBeProcessed.Characteristic,
	|	TableOfOrdersToBeProcessed.RowCode,
	|	TableOfOrdersToBeProcessed.Warehouse,
	|	TableOfOrdersToBeProcessed.Series
	|
	|HAVING
	|	SUM(TableOfOrdersToBeProcessed.ToRegister) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfOrdersOverAndAboveOrder.SalesOrder,
	|	TableOfOrdersOverAndAboveOrder.Products,
	|	TableOfOrdersOverAndAboveOrder.Characteristic,
	|	TableOfOrdersOverAndAboveOrder.RowCode,
	|	TableOfOrdersOverAndAboveOrder.Warehouse,
	|	TableOfOrdersOverAndAboveOrder.Series,
	|	SUM(TableOfOrdersOverAndAboveOrder.ToRegister),
	|	0
	|FROM
	|	(SELECT
	|		TurnoversByOrders.ReferenceOrder AS SalesOrder,
	|		TurnoversByOrders.Products AS Products,
	|		TurnoversByOrders.Characteristic AS Characteristic,
	|		TurnoversByOrders.RowCode AS RowCode,
	|		TurnoversByOrders.Warehouse AS Warehouse,
	|		TurnoversByOrders.Series AS Series,
	|		(TurnoversByOrders.QuantityToBeShippedTurnover
	|			- TurnoversByOrders.IssuedQuantityTurnover) AS ToRegister
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded2 AS TurnoversByOrders
	|	WHERE
	|		(TurnoversByOrders.QuantityToBeShippedTurnover
	|			- TurnoversByOrders.IssuedQuantityTurnover) <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ShipmentReferences.ReferenceOrder,
	|		ShipmentReferences.Products,
	|		ShipmentReferences.Characteristic,
	|		ShipmentReferences.RowCode,
	|		ShipmentReferences.Warehouse,
	|		ShipmentReferences.Series,
	|		ShipmentReferences.Count
	|	FROM
	|		AccumulationRegister.ShipmentAndReturnReferences AS ShipmentReferences
	|	WHERE
	|		ShipmentReferences.Active
	|		AND ShipmentReferences.Period >= &StartDate
	|		AND ShipmentReferences.Recorder = &Recorder
	|		AND ShipmentReferences.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
	|		AND ShipmentReferences.ReferenceOrder IN
	|				(SELECT
	|					TheOrdersTable.Ref AS Ref
	|				FROM
	|					TheOrdersTable AS TheOrdersTable)
	|		AND ShipmentReferences.RowCode = 0) AS TableOfOrdersOverAndAboveOrder
	|
	|GROUP BY
	|	TableOfOrdersOverAndAboveOrder.SalesOrder,
	|	TableOfOrdersOverAndAboveOrder.Products,
	|	TableOfOrdersOverAndAboveOrder.Characteristic,
	|	TableOfOrdersOverAndAboveOrder.RowCode,
	|	TableOfOrdersOverAndAboveOrder.Warehouse,
	|	TableOfOrdersOverAndAboveOrder.Series
	|
	|HAVING
	|	SUM(TableOfOrdersOverAndAboveOrder.ToRegister) > 0
	|
	|INDEX BY
	|	MaterialProviderOrder,
	|	RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TheOrdersTable.Ref AS Ref
	|FROM
	|	TheOrdersTable AS TheOrdersTable
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				Document.MaterialProviderOrder2_5.ManufacturedProduct AS ProductTable
	|			WHERE
	|				ProductTable.Ref = TheOrdersTable.Ref
	|				AND NOT ProductTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|				AND NOT ProductTable.Canceled)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalanceTable.MaterialProviderOrder AS MaterialProviderOrder,
	|	CAST(BalanceTable.MaterialProviderOrder AS Document.MaterialProviderOrder2_5).ARAPObjectSettings AS ARAPObjectSettings,
	|	BalanceTable.Products AS Products,
	|	BalanceTable.Characteristic AS Characteristic,
	|	BalanceTable.RowCode AS RowCode,
	|	BalanceTable.Warehouse AS Warehouse,
	|	ProductTable.Department AS Department,
	|	BalanceTable.Series AS Series,
	|	BalanceTable.MaterialProviderOrder.Purpose AS Purpose,
	|	BalanceTable.Count AS Count,
	|	BalanceTable.Sum AS SumBalance,
	|	ProductTable.DateOfShipment AS DateOfShipment,
	|	ISNULL(ProductTable.Price, 0) AS Price,
	|	ISNULL(ProductTable.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) AS PriceKind,
	|	ISNULL(ProductTable.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS Package,
	|	CASE
	|		WHEN ISNULL(ProductTable.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor
	|	END AS ZoomRatio,
	|	CASE
	|		WHEN ISNULL(ProductTable.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN BalanceTable.Count
	|		ELSE BalanceTable.Count / &QueryTextPackagingFactor
	|	END AS NumberOfPackages,
	|	ISNULL(ProductTable.BatchesIndicationStatus, 0) AS BatchesIndicationStatus,
	|	ProductTable.Count AS QuantityInOrder,
	|	ProductTable.Sum AS Sum,
	|	ProductTable.VATRate AS VATRate,
	|	ProductTable.VATAmount AS VATAmount,
	|	ProductTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	ProductTable.ToExpenseAs AS ToExpenseAs,
	|	ProductTable.Recipient AS Recipient,
	|	ProductTable.ExpenseItem AS ExpenseItem,
	|	ProductTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	ProductTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	BalanceTable.MaterialProviderOrder.ProcessingService AS ProcessingService
	|FROM
	|	BalanceTable AS BalanceTable
	|		LEFT JOIN Document.MaterialProviderOrder2_5.ManufacturedProduct AS ProductTable
	|		ON BalanceTable.MaterialProviderOrder = ProductTable.Ref
	|			AND BalanceTable.RowCode = ProductTable.RowCode";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.BeginOfPeriod = "&StartDate";
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN
		|		(SELECT
		|				TheOrdersTable.Ref AS Ref
		|			FROM
		|				TheOrdersTable AS TheOrdersTable)
		|		AND RowCode <> 0";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
	TableFormationParameters.Indicators = "ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count, Sum";
	
	ShipmentOrdersTurnoverExpanded1 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded1",
		ShipmentOrdersTurnoverExpanded1);
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.BeginOfPeriod = "&StartDate";
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN
		|		(SELECT
		|				TheOrdersTable.Ref AS Ref
		|			FROM
		|				TheOrdersTable AS TheOrdersTable)
		|		AND RowCode = 0";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
	TableFormationParameters.Indicators = "ToShip, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded2",
		ShipmentOrdersTurnoverExpanded2);
	
	Query.Text =
		StrReplace(
			Query.Text,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"ProductTable.Package", "ProductTable.Products"));
	
	SetPrivilegedMode(True);
	
	Return Query.ExecuteBatch();
	
EndFunction

// Returns a table of settlement amounts broken down by container/non-container and broken down by order.
// 
// Parameters:
//  ObjectReference_ - DocumentRef.ReportToMaterialProvider2_5 - The document for which you want to get the data.
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
	|	ManufacturedProduct.MaterialProviderOrder			AS OrderDocument,
	|	ManufacturedProduct.AmountIncludingVAT				AS Sum,
	|	ManufacturedProduct.AmountARAP	AS AmountARAP,
	|	ManufacturedProduct.Products			AS Products,
	|	ManufacturedProduct.RowCode				AS RowCode,
	|	&OrderingCaps						AS MaterialProviderOrder
	|INTO TTManufacturedProduct
	|FROM &ValueTable AS ManufacturedProduct
	|WHERE &LinkCondition_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	CASE WHEN ISNULL(ManufacturedProduct.OrderDocument.Number, """") = """"
	|				THEN ManufacturedProduct.MaterialProviderOrder
	|			ELSE ManufacturedProduct.OrderDocument
	|	END			AS OrderDocument,
	|	CASE WHEN ISNULL(ManufacturedProduct.OrderDocument.Number, """") = """"
	|				THEN ISNULL(ManufacturedProduct.MaterialProviderOrder.DATE, DATETIME(1,1,1))
	|			ELSE ISNULL(ManufacturedProduct.OrderDocument.DATE, DATETIME(1,1,1))
	|	END			AS OrderDate,
	|	CASE WHEN ISNULL(ManufacturedProduct.OrderDocument.Number, """") = """"
	|				THEN ISNULL(ManufacturedProduct.MaterialProviderOrder.ApprovalDate, DATETIME(1,1,1))
	|			ELSE ISNULL(ManufacturedProduct.OrderDocument.ApprovalDate, DATETIME(1,1,1))
	|	END			AS ApprovalDate,
	|	ManufacturedProduct.RowCode = 0 AS ExceedingOrder,
	|	SUM(CASE
	|		WHEN CAST(ManufacturedProduct.Products AS Catalog.Products).ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN ManufacturedProduct.Sum
	|		ELSE 0 
	|	END)			AS PaymentAmount,
	|	SUM(CASE
	|		WHEN CAST(ManufacturedProduct.Products AS Catalog.Products).ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN ManufacturedProduct.AmountARAP
	|		ELSE 0
	|	END)			AS AmountARAP,
	|	0				AS PackageDepositValue,
	|	0				AS AmountARAPByPackage
	|FROM
	|	TTManufacturedProduct AS ManufacturedProduct
	|
	|GROUP BY
	|	CASE WHEN ISNULL(ManufacturedProduct.OrderDocument.Number, """") = """"
	|				THEN ManufacturedProduct.MaterialProviderOrder
	|			ELSE ManufacturedProduct.OrderDocument
	|	END,
	|	CASE WHEN ISNULL(ManufacturedProduct.OrderDocument.Number, """") = """"
	|				THEN ISNULL(ManufacturedProduct.MaterialProviderOrder.DATE, DATETIME(1,1,1))
	|			ELSE ISNULL(ManufacturedProduct.OrderDocument.DATE, DATETIME(1,1,1))
	|	END,
	|	CASE WHEN ISNULL(ManufacturedProduct.OrderDocument.Number, """") = """"
	|				THEN ISNULL(ManufacturedProduct.MaterialProviderOrder.ApprovalDate, DATETIME(1,1,1))
	|			ELSE ISNULL(ManufacturedProduct.OrderDocument.ApprovalDate, DATETIME(1,1,1))
	|	END,
	|	ManufacturedProduct.RowCode = 0
	|";
	
	If AttributesValues = Undefined Then
		Query.Text = StrReplace(Query.Text, "&ValueTable", "Document.ReportToMaterialProvider2_5.ManufacturedProduct");
		Query.Text = StrReplace(Query.Text, "&OrderingCaps", "ManufacturedProduct.Ref.MaterialProviderOrder");
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "ManufacturedProduct.Ref = &Ref");
		Query.SetParameter("Ref",ObjectReference_);
	Else
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "TRUE");
		For Each KeyValue In AttributesValues Do
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

// Returns the base text based on the document data and the specified calculation order
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.ReportToMaterialProvider2_5 - The object of the document for which you need to get the text of the base
//	The order of the calculations is the enumeration of the link.The order of calculations is the order of calculations.
//
// Returns:
//	Structure- Structure with the name, date and number of the foundation.
//
Function BaseStructure(Object)
	
	StructureBase = New Structure;
	StructureBase.Insert("Basis");
	StructureBase.Insert("BaseDocumentNumber");
	StructureBase.Insert("ReferenceDocumentDateForPrintForms");
	
	If Object.ReportOnOrders Then
		
		AnArrayOfOrders = Object.ManufacturedProduct.Unload(, "MaterialProviderOrder").UnloadColumn("MaterialProviderOrder");
		
		Query = New Query(
		"SELECT ALLOWED
		|	GiverSOrders.NumberAccordingToPartnerData AS NumberAccordingToPartnerData,
		|	GiverSOrders.DateAccordingToInformationFromPartner  AS DateAccordingToInformationFromPartner,
		|	GiverSOrders.Number                 AS Number,
		|	GiverSOrders.Date                  AS Date,
		|	&SynonymForOrder                       AS Synonym
		|FROM
		|	Document.MaterialProviderOrder2_5 AS GiverSOrders
		|WHERE
		|	GiverSOrders.Ref IN(&AnArrayOfOrders)
		|");
		
		Query.SetParameter("AnArrayOfOrders", AnArrayOfOrders);
		Query.SetParameter("SynonymForOrder", NStr("vi = 'Đơn hàng của người đặt gia công';
													|ru = 'Заказ давальца';
													|en = 'Subcontracting sales order'; fa = 'سفارش فروش پیمانکاری فرعی';
													|it = 'Ordine del committente';
													|pl = 'Zamówienie dostawcy';
													|tr = 'Tedarikçi siparişi'"));
		Selection = Query.Execute().Select();
		
		TextForOrders = "";
		OneFoundation = Selection.Count() = 1;
		While Selection.Next() Do
			
			If ValueIsFilled(Selection.NumberAccordingToPartnerData) And ValueIsFilled(Selection.DateAccordingToInformationFromPartner) Then
				
				InformationAboutOrder =
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = '%1 số %2 ngày %3';
							|ru = '%1 № %2 от %3';
							|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
							|it = '%1 № %2 от %3';
							|pl = '%1 nr %2 z dnia %3.';
							|tr = '%3 itibarıyla %2 numaralı %1'"),
						Selection.Synonym,
						Selection.NumberAccordingToPartnerData,
						Format(Selection.DateAccordingToInformationFromPartner, "DLF=DD"));
				
				DateForOrders  = Selection.DateAccordingToInformationFromPartner;
				OrderNumber_1 = Selection.NumberAccordingToPartnerData;
				
			Else
				
				InformationAboutOrder =
					TMCommonUseClientServer.GenerateDocumentTitle(Selection, Selection.Synonym);
				
				DateForOrders  = Selection.Date;
				OrderNumber_1 = Selection.Number;
				
			EndIf;
			
			TextForOrders = TextForOrders + ", " + InformationAboutOrder;
			
		EndDo;
		
		StructureBase.Basis      = TrimAll(Mid(TextForOrders, 3));
		StructureBase.ReferenceDocumentDateForPrintForms  = ?(OneFoundation, DateForOrders, "");
		StructureBase.BaseDocumentNumber = ?(OneFoundation, ObjectsPrefixesClientServer.NumberForPrinting(OrderNumber_1), "");
		
		If ValueIsFilled(Object.Contract) Then
			
			ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, "Date, Number");
			ContractDetailsText = StrTemplate(
				NStr("vi = 'theo hợp đồng số %1 ngày %2';
					|ru = 'по договору №%1 от %2';
					|en = 'under contract No. %1 dated %2'; fa = 'under contract No. %1 dated %2';
					|it = 'по договору №%1 от %2';
					|pl = 'pod kontraktem NR %1 od %2';
					|tr = '%2 itibarıyla %1 numaralı sözleşme kapsamında'"),
				ContractDetails_.Number,
				Format(ContractDetails_.Date, "DLF=DD"));
			
			StructureBase.Basis = StructureBase.Basis + NStr("vi = ', nguyên vật việu gia công %1';
															|ru = ', переработка давальческого сырья %1';
															|en = ', processing provided materials %1'; fa = ', processing provided materials %1';
															|it = ', переработка давальческого сырья %1';
															|pl = ', przetwarzanie surowców dostarczanych przez dostawcę %1';
															|tr = ', %1 tedarikçi hammaddelerinin işlenmesi'");
			StructureBase.Basis = StrTemplate(StructureBase.Basis, ContractDetailsText);
			
		EndIf;
		
	Else
		
		Query = New Query(
		"SELECT ALLOWED
		|	CounterpartyContracts.NameForPrinting AS Basis,
		|	CounterpartyContracts.Date AS ReferenceDocumentDateForPrintForms,
		|	CounterpartyContracts.Number AS BaseDocumentNumber
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.Ref = &Ref
		|");
		Query.SetParameter("Ref", Object.Contract);
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			StructureBase.Basis = TrimAll(Selection.Basis);
			StructureBase.ReferenceDocumentDateForPrintForms = Selection.ReferenceDocumentDateForPrintForms;
			StructureBase.BaseDocumentNumber = TrimAll(Selection.BaseDocumentNumber);
		EndIf;
		
	EndIf;
	
	Return StructureBase; // Returning the default value
	
EndFunction

#EndRegion

#Region CreatingHyperlinkInJournal

// Returns the hyperlink text for the transition from the document log to the design workspace.
//
// Parameters:
//  Parameters - Structure - parameters for forming the hyperlink text.
//
// Returns:
//  FormattedString, Undefined - the text of the hyperlink of the transition to the workplace of the registration of transfers.
//
Function CreateHyperlinkToDesign(Parameters) Export
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences)
	 Or Not AccessRight("Read", Metadata.AccumulationRegisters.CompanyGoods) Then
		Return Undefined;
	EndIf;
	
	HyperlinkAnchorText = "DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices/ReportsPage";
	
	ThereAreDocumentsForRegistration = DataProcessors.DocumentsOfReceiptForTollingAll2_5.ThereAreDocumentsForRegistration(
									Parameters, Enums.BusinessTransactions.ReportToMaterialProvider2_5);
	
	ColorOfHyperlink = ?(ThereAreDocumentsForRegistration, Undefined, StyleColors.EmptyTableField);
	
	Return New FormattedString(NStr("vi = 'Báo cáo';
									|ru = 'Отчеты';
									|en = 'Reports'; fa = 'گزارش‌ها';
									|it = 'Report';
									|pl = 'Reports';
									|tr = 'Raporlar'"),, ColorOfHyperlink,, HyperlinkAnchorText);
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Documents.ReportToMaterialProvider2_5.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.14";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("e32c67ac-f0e1-4d8b-9157-fdde810b2341");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.ReportToMaterialProvider2_5.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật chứng từ ""Bảng kê cho người đặt gia công"":';
								|ru = 'Обновление документов ""Отчет давальцу"":';
								|en = 'Update the ""Consumption report — Subcontracting services delivered"" documents:'; fa = 'Update the ""Consumption report — Subcontracting services delivered"" documents:';
								|it = 'Обновление документов ""Отчет давальцу"":';
								|pl = 'Update the ""Consumption report — Subcontracting services delivered"" documents:';
								|tr = '""Tüketim raporu-Verilen fason hizmetleri"" belgelerinin güncellenmesi'"));
	ListOfDescriptions.Add(NStr("ru = '- переносит значение ставки НДС из шапки в табличные части ""Выпускаемая продукция"", ""Виды запасов"".';
								|vi = '- Transfers the VAT rate value from the header to the ""Released products"" and ""Inventory owner attributes"" tables.';
								|en = '- Transfers the VAT rate value from the header to the ""Released products"" and ""Inventory owner attributes"" tables.'; fa = '- Transfers the VAT rate value from the header to the ""Released products"" and ""Inventory owner attributes"" tables.';
								|it = '- Transfers the VAT rate value from the header to the ""Released products"" and ""Inventory owner attributes"" tables.';
								|pl = '- Transfers the VAT rate value from the header to the ""Released products"" and ""Inventory owner attributes"" tables.';
								|tr = '- KDV oranı değerini üst bilgilerinden ""Üretilen Ürünler"" tablo bölümüne aktarır.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.ReportToMaterialProvider2_5.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.ReportToMaterialProvider2_5.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.ReportToMaterialProvider2_5.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.ReportToMaterialProvider2_5";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	DocumentAttributes.Ref AS Ref
	|FROM
	|	(SELECT
	|		DocumentAttributes.Ref AS Ref
	|	FROM
	|		Document.ReportToMaterialProvider2_5 AS DocumentAttributes
	|	WHERE
	|		NOT DocumentAttributes.VATRate = VALUE(Catalog.VATRates.EmptyRef)
	|		AND TRUE IN(
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				Document.ReportToMaterialProvider2_5.ManufacturedProduct AS TableOfGoods
	|			WHERE
	|				TableOfGoods.Ref = DocumentAttributes.Ref
	|				AND TableOfGoods.VATRate = VALUE(Catalog.VATRates.EmptyRef))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentAttributes.Ref AS Ref
	|	FROM
	|		Document.ReportToMaterialProvider2_5 AS DocumentAttributes
	|	WHERE
	|		NOT DocumentAttributes.VATRate = VALUE(Catalog.VATRates.EmptyRef)
	|		AND TRUE IN(
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				Document.ReportToMaterialProvider2_5.InventoryKinds AS TableOfGoods
	|			WHERE
	|				TableOfGoods.Ref = DocumentAttributes.Ref
	|				AND TableOfGoods.VATRate = VALUE(Catalog.VATRates.EmptyRef))
	|	) AS DocumentAttributes
	|";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Document.ReportToMaterialProvider2_5";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
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
	|	UpdatedData.Ref        AS Ref,
	|	DocumentAttributes.DataVersion AS DataVersion,
	// Fill in the VAT rate in the "Manufactured Products" TS
	|	NOT DocumentAttributes.VATRate = VALUE(Catalog.VATRates.EmptyRef)
	|		AND TRUE IN(
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				Document.ReportToMaterialProvider2_5.ManufacturedProduct AS TableOfGoods
	|			WHERE
	|				TableOfGoods.Ref = DocumentAttributes.Ref
	|				AND TableOfGoods.VATRate = VALUE(Catalog.VATRates.EmptyRef)) AS FillInVATRateForManufacturedProducts,
	// Fill in the VAT rate in the TS "Types of inventory"
	|	NOT DocumentAttributes.VATRate = VALUE(Catalog.VATRates.EmptyRef)
	|		AND TRUE IN(
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				Document.ReportToMaterialProvider2_5.InventoryKinds AS TableOfGoods
	|			WHERE
	|				TableOfGoods.Ref = DocumentAttributes.Ref
	|				AND TableOfGoods.VATRate = VALUE(Catalog.VATRates.EmptyRef)) AS FillInVATRateTypesOfInventory
	|FROM
	|	UpdatedData AS UpdatedData
	|
	|	LEFT JOIN Document.ReportToMaterialProvider2_5 AS DocumentAttributes
	|	ON UpdatedData.Ref = DocumentAttributes.Ref
	|";
	
	Query.SetParameter("UpdatedData", UpdatedData);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		ExceptionReason = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			Block.Add(FullObjectName).SetValue("Ref", Selection.Ref);
			Block.Lock();
			
			DocumentObject = InfobaseUpdateTM.CheckGetObject(Selection.Ref, Selection.DataVersion, Parameters.Queue);
			
			If DocumentObject <> Undefined Then
				
				If Selection.FillInVATRateForManufacturedProducts Then
					For Each CurrentData In DocumentObject.ManufacturedProduct Do
						
						If ValueIsFilled(CurrentData.VATRate) Then
							Continue;
						EndIf;

						CurrentData.VATRate = DocumentObject.VATRate;
						
					EndDo;
				EndIf;
				
				If Selection.FillInVATRateTypesOfInventory Then
					For Each CurrentData In DocumentObject.InventoryKinds Do
						
						If ValueIsFilled(CurrentData.VATRate) Then
							Continue;
						EndIf;
						
						CurrentData.VATRate = DocumentObject.VATRate;
						
					EndDo;
				EndIf;
				
			EndIf;
			
			ExceptionReason = "Record";
			
			If DocumentObject.Modified() Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
			If ExceptionReason = "Record" Then
				Raise NStr("ru = 'Не удалось обработать обновление документов ""Отчет давальцу"".';
							|vi = 'Cannot process the update of the ""Consumption reports — Subcontracting services delivered"" documents.';
							|en = 'Cannot process the update of the ""Consumption reports — Subcontracting services delivered"" documents.'; fa = 'Cannot process the update of the ""Consumption reports — Subcontracting services delivered"" documents.';
							|it = 'Cannot process the update of the ""Consumption reports — Subcontracting services delivered"" documents.';
							|pl = 'Cannot process the update of the ""Consumption reports — Subcontracting services delivered"" documents.';
							|tr = '""Tüketim raporu-Verilen fason hizmetleri"" belgelerin güncellenmesi işlenemedi'");
			EndIf;
			
		EndTry;
		
	EndDo;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

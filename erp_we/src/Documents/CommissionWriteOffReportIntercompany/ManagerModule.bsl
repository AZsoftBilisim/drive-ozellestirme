#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization");
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Manager";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Consignee";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Consignee";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"ExternalDocumentName", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CompanyBankAccount", Parameters);

	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Consignee";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Consignee";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"RecipientCompanyBankAccount", Parameters);
	
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
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("HandoverForSafekeeping");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	
	CommissionWriteOffReportIntercompanyLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.CommissionWriteOffReportIntercompany") Then
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
		
		QueryTextGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		QueryTextTableRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers);
		QueryTextTablePurchases(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		AddTextsToReflectSettlements(Query, QueryTexts, Registers);
		
		CommissionWriteOffReportIntercompanyLocalization.AddRequestTexts(Query,
																								QueryTexts,
																								Registers);
	EndIf;
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
	
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
	
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	CommissionWriteOffReportIntercompanyLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create the document "report on Commission between organizations on write-offs".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	CreateBasedOnCommand = Undefined;
	If AccessRight("Insert", Metadata.Documents.CommissionWriteOffReportIntercompany) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.CommissionWriteOffReportIntercompany.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.CommissionWriteOffReportIntercompany);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseCustomerInvoiceIntercompany";
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
	
	Reports.ControlOfCustomerInvoicesIntercompany.AddReportGenerationCommand(ReportsCommands);
	
	CommissionWriteOffReportIntercompanyLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// This function defines the document details.
//
// Parameters:
//  DocumentRef - DocumentRef.CommissionReportIntercompany - link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Consignee AS Consignee,
	|	DocumentData.Consignee AS CompanyRecipient,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|
	|	DocumentData.DocumentAmount AS AmountARAP,
	|	0 AS CommissionAmount,
	|
	|	DocumentData.BeginOfPeriod AS BeginOfPeriod,
	|	DocumentData.EndOfPeriod AS EndOfPeriod,
	|	DocumentData.ARAPAccountingViaSeparateCounterparty AS ARAPAccountingViaSeparateCounterparty,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.SalesContract AS SalesContract,
	|	DocumentData.PurchasingContract AS PurchasingContract
	|FROM
	|	Document.CommissionWriteOffReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.Date;
		Organization = Selection.Organization;
		CompanyRecipient = Selection.CompanyRecipient;
		ARAPCurrency = Selection.ARAPCurrency;
		DocumentAmount = Selection.DocumentAmount;
		AmountARAP = ?(Selection.Posted, Selection.AmountARAP, 0);
		CommissionAmount = ?(Selection.Posted, Selection.CommissionAmount, 0);
		BeginOfPeriod = Selection.BeginOfPeriod;
		EndOfPeriod = Selection.EndOfPeriod;
		ARAPAccountingViaSeparateCounterparty = Selection.ARAPAccountingViaSeparateCounterparty;
		Partner = ?(ARAPAccountingViaSeparateCounterparty, Selection.Partner, Catalogs.Partners.OurEnterprise);
		Counterparty = ?(ARAPAccountingViaSeparateCounterparty, Selection.Counterparty, Selection.Organization);
		LineOfBusiness = Selection.LineOfBusiness;
		ARAPObjectSettings = Selection.ARAPObjectSettings;
		Contract = Selection.Contract;
		SalesContract = Selection.SalesContract;
		PurchasingContract = Selection.PurchasingContract;
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		CompanyRecipient = Catalogs.Companies.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		DocumentAmount = 0;
		AmountARAP = 0;
		CommissionAmount = 0;
		BeginOfPeriod = Undefined;
		EndOfPeriod = Undefined;
		ARAPAccountingViaSeparateCounterparty = False;
		Partner = Catalogs.Partners.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		Contract = Catalogs.IntercompanyContracts.EmptyRef();
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		SalesContract = Catalogs.CounterpartyContracts.EmptyRef();
		PurchasingContract = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	
	AttributesStructure1 = New Structure();
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", CompanyRecipient);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", Enums.BusinessTransactions.CommissionReportIntercompany);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP);
	AttributesStructure1.Insert("CommissionAmount", CommissionAmount);
	AttributesStructure1.Insert("SenderOrganization", Organization);
	AttributesStructure1.Insert("CompanyRecipient", CompanyRecipient);
	AttributesStructure1.Insert("BeginOfPeriod", BeginOfPeriod);
	AttributesStructure1.Insert("EndOfPeriod", EndOfPeriod);
	AttributesStructure1.Insert("ARAPAccountingViaSeparateCounterparty", ARAPAccountingViaSeparateCounterparty);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	AttributesStructure1.Insert("SalesContract", SalesContract);
	AttributesStructure1.Insert("PurchasingContract", PurchasingContract);
	If Not ARAPAccountingViaSeparateCounterparty Then
		AttributesStructure1.Insert("Contract", Contract);
	EndIf;
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	
	Return AttributesStructure1;
EndFunction

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'Bảng kê ký gửi';
							|ru = 'Отчет по комиссии';
							|en = 'Report on commission'; fa = 'گزارش حق‌العمل';
							|it = 'Report sulla commissione';
							|pl = 'Raport o prowizji';
							|tr = 'Komisyon raporu'"));
	CommissionWriteOffReportIntercompanyLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	Return ArrayOfNames
EndFunction

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return CommissionWriteOffReportIntercompanyLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return CommissionWriteOffReportIntercompanyLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// Commission agent's report on write-offs
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "DataProcessor.PrintCommissionReports";
	PrintCommand.Id = "CommissionAgentSReportWriteOff";
	PrintCommand.Presentation = NStr("vi = 'Bảng kê hàng hóa ghi giảm của người nhận ký gửi';
									|ru = 'Отчет комиссионера о списании';
									|en = 'Consignment stock adjustment'; fa = 'تعدیل موجودی امانی';
									|it = 'Report del commissionario sullo storno';
									|pl = 'Raport komisanta ze spisania';
									|tr = 'Zarar yazma ile ilgili konsinye raporu'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.DefaultPrintForm = True;
	PrintCommand.PrintFormDescription = NStr("vi = 'Bảng kê hàng hóa ghi giảm của người nhận ký gửi';
											|ru = 'Отчет комиссионера о списании';
											|en = 'Consignment stock adjustment'; fa = 'تعدیل موجودی امانی';
											|it = 'Report del commissionario sullo storno';
											|pl = 'Raport komisanta ze spisania';
											|tr = 'Konsinye stok düzeltme raporu'");

	CommissionWriteOffReportIntercompanyLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value - the object reference;
//                                            view - name of the area where the object was output (output parameter);
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	CommissionWriteOffReportIntercompanyLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
EndProcedure

// Returns the data required for the printed form "Commission Report".
//
// Parameters:
//  PrintParameters - Structure - advanced print settings;
//  ObjectsArray  - Array    - references to objects that should be printed;
//
// Returns:
//	Structure - It contains data on the header of the document and the tabular part.
//
Function GetDataForPrintedCommissionReportForm(PrintParameters, ObjectsArray) Export
	
	Query = New Query(
	"
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Number AS Number,
	|	DocumentData.Date AS Date,
	|	DocumentData.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	DocumentData.CorrectedDocument.Date AS DateOfDocumentBeingCorrected,
	|	DocumentData.Consignee AS Consignee,
	|	DocumentData.Organization AS Consignor,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CommissionAmount AS CommissionAmount,
	|	"""" AS CommitteeRepresentative,
	|	DocumentData.Manager.Individual AS RepresentativeOfCommissionAgent
	|FROM
	|	Document.CommissionWriteOffReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&DocumentsArray)
	|	AND DocumentData.Posted
	|	AND (NOT DocumentData.ARAPAccountingViaSeparateCounterparty)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref,
	|	DocumentData.Number,
	|	DocumentData.Date,
	|	DocumentData.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	DocumentData.CorrectedDocument.Date AS DateOfDocumentBeingCorrected,
	|	DocumentData.Consignee,
	|	DocumentData.Counterparty,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Currency,
	|	DocumentData.CommissionAmount,
	|	"""",
	|	DocumentData.Manager.Individual
	|FROM
	|	Document.CommissionWriteOffReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&DocumentsArray)
	|	AND DocumentData.Posted
	|	AND DocumentData.ARAPAccountingViaSeparateCounterparty
	|	AND DocumentData.Consignee <> VALUE(Catalog.Companies.ManagementCompany)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref,
	|	DocumentData.IncomingDocumentNumber,
	|	DocumentData.IncomingDocumentDate,
	|	DocumentData.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	DocumentData.CorrectedDocument.Date AS DateOfDocumentBeingCorrected,
	|	DocumentData.Counterparty,
	|	DocumentData.Organization,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Currency,
	|	DocumentData.CommissionAmount,
	|	"""",
	|	DocumentData.Manager.Individual
	|FROM
	|	Document.CommissionWriteOffReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&DocumentsArray)
	|	AND DocumentData.Posted
	|	AND DocumentData.ARAPAccountingViaSeparateCounterparty
	|	AND DocumentData.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	NestedQuery.Ref AS Ref,
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Products.DescriptionFull AS ProductItemName,
	|	NestedQuery.Products.Code AS Code,
	|	NestedQuery.Products.SKU AS SKU,
	|	NestedQuery.UnitOfMeasure.Presentation AS UnitOfMeasurementName,
	|	NestedQuery.Characteristic.DescriptionFull AS Characteristic,
	|	CASE
	|		WHEN ISNULL(NestedQuery.Package, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END AS Package,
	|	NestedQuery.DateOfTaxInvoiceIssuedByCommissionAgent AS TaxInvoiceDate,
	|	NestedQuery.Customer AS Customer,
	|	NestedQuery.Price AS Price,
	|	SUM(NestedQuery.Count) AS Count,
	|	SUM(NestedQuery.ConsignorAmount) AS ConsignorAmount,
	|	SUM(NestedQuery.SalesAmount) AS SalesAmount,
	|	SUM(NestedQuery.CommissionAmount) AS CommissionAmount,
	|	MAX(NestedQuery.LineNumber) AS LineNumber
	|FROM
	|	(SELECT
	|		GoodsTable.Ref AS Ref,
	|		GoodsTable.Products AS Products,
	|		&QueryTextUnitOfMeasure AS UnitOfMeasure,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Package AS Package,
	|		GoodsTable.DateOfTaxInvoiceIssuedByCommissionAgent AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|		GoodsTable.Customer AS Customer,
	|		GoodsTable.NumberOfPackages AS Count,
	|		GoodsTable.Price AS Price,
	|		GoodsTable.AmountIncludingVAT AS ConsignorAmount,
	|		GoodsTable.SalesAmount AS SalesAmount,
	|		GoodsTable.CommissionAmount AS CommissionAmount,
	|		GoodsTable.LineNumber AS LineNumber
	|	FROM
	|		Document.CommissionReportIntercompany.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref IN(&DocumentsArray)
	|		AND GoodsTable.Products.ItemsType IN
	|			(VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Ref,
	|	NestedQuery.Products,
	|	NestedQuery.UnitOfMeasure,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Package,
	|	NestedQuery.Price,
	|	NestedQuery.Products.DescriptionFull,
	|	NestedQuery.Products.Code,
	|	NestedQuery.Products.SKU,
	|	NestedQuery.UnitOfMeasure.Presentation,
	|	NestedQuery.Characteristic.DescriptionFull,
	|	CASE
	|		WHEN ISNULL(NestedQuery.Package, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END,
	|	NestedQuery.DateOfTaxInvoiceIssuedByCommissionAgent,
	|	NestedQuery.Customer
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|TOTALS
	|	SUM(ConsignorAmount),
	|	SUM(SalesAmount),
	|	SUM(CommissionAmount)
	|BY
	|	Ref");
	
	Query.Text = StrReplace(
		Query.Text,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"GoodsTable.Package",
			"GoodsTable.Products"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	Title = NStr("vi = 'Bảng kê hàng hóa của người nhận bán hộ';
				|ru = 'Отчет комиссионера о продажах';
				|en = 'Consignment issue notification'; fa = 'اعلان صدور امانی';
				|it = 'Report del commissionario sulle vendite';
				|pl = 'Raport komisanta ze sprzedaży';
				|tr = 'Konsinye satış raporu'");
	ResultsArray 			= Query.ExecuteBatch();
	HeaderResults			= ResultsArray[0];
	ResultForTabularPart 	= ResultsArray[1];
	DataStructureForPrinting 	= New Structure(
		"HeaderResults, ResultForTabularPart, Title",
		HeaderResults,
		ResultForTabularPart,
		Title);
	
	Return DataStructureForPrinting;
	
EndFunction

// Returns the data needed for printing forms "Report of the Commission on decommissioning".
// 
// Parameters:
// 	PrintParameters - Structure - advanced print settings
// 	ObjectsArray  - Array    - references to objects that should be printed
// 	
// Returns:
//	Structure - Contains data on the header of the document and the tabular part:
// 	* Title - String -
// 	* HeaderResults - QueryResult - 
// 	* ResultForTabularPart - QueryResult - 
//
Function GetDataForPrintedFormCommissionReportOnDebiting(PrintParameters, ObjectsArray) Export
	
	Query = New Query(
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Number AS Number,
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Consignor,
	|	DocumentData.Consignee AS Consignee,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.Currency AS Currency,
	|	"""" AS CommitteeRepresentative,
	|	DocumentData.Manager.Individual AS RepresentativeOfCommissionAgent
	|FROM
	|	Document.CommissionWriteOffReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&DocumentsArray)
	|	AND DocumentData.Posted
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Ref AS Ref,
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Products.DescriptionFull AS ProductItemName,
	|	NestedQuery.Products.Code AS Code,
	|	NestedQuery.Products.SKU AS SKU,
	|	NestedQuery.UnitOfMeasure.Presentation AS UnitOfMeasurementName,
	|	NestedQuery.Characteristic.DescriptionFull AS Characteristic,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END AS Package,
	|	NestedQuery.Price AS Price,
	|	SUM(NestedQuery.Count) AS Count,
	|	SUM(NestedQuery.Sum) AS Sum,
	|	MAX(NestedQuery.LineNumber) AS LineNumber
	|FROM
	|	(SELECT
	|		GoodsTable.Ref AS Ref,
	|		GoodsTable.Products AS Products,
	|		CASE
	|			WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN GoodsTable.Products.UnitOfMeasure
	|			ELSE GoodsTable.Package
	|		END AS UnitOfMeasure,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Package AS Package,
	|		GoodsTable.NumberOfPackages AS Count,
	|		GoodsTable.Price AS Price,
	|		GoodsTable.AmountIncludingVAT AS Sum,
	|		GoodsTable.LineNumber AS LineNumber
	|	FROM
	|		Document.CommissionWriteOffReportIntercompany.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref IN(&DocumentsArray)
	|		AND GoodsTable.Products.ItemsType IN
	|			(VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Ref,
	|	NestedQuery.Products,
	|	NestedQuery.UnitOfMeasure,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Package,
	|	NestedQuery.Price,
	|	NestedQuery.Products.DescriptionFull,
	|	NestedQuery.Products.Code,
	|	NestedQuery.Products.SKU,
	|	NestedQuery.UnitOfMeasure.Presentation,
	|	NestedQuery.Characteristic.DescriptionFull,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|TOTALS
	|	SUM(Sum)
	|BY
	|	Ref");
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"NestedQuery.Package",
			"NestedQuery.Products"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	Title 					= NStr("vi = 'Bảng kê ghi giảm hàng hóa dành cho người đặt ký gửi';
									|ru = 'Отчет комитенту о списании';
									|en = 'Vendor consignment stock adjustment'; fa = 'تعدیل موجودی امانی تأمین‌کننده';
									|it = 'Report al committente sullo storno';
									|pl = 'Raport dla komitenta o spisaniu';
									|tr = 'Tedarikçi konsinye stok ayarlaması'", Common.DefaultLanguageCode());
	ResultsArray 			= Query.ExecuteBatch();
	HeaderResults			= ResultsArray[0];
	ResultForTabularPart 	= ResultsArray[1];
	DataStructureForPrinting 	= New Structure(
		"HeaderResults, ResultForTabularPart, Title",
		HeaderResults,
		ResultForTabularPart,
		Title);
	
	Return DataStructureForPrinting;
	
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
	|	( ValueAllowed(Organization)
	|	OR ValueAllowed(Consignee)
	|	) AND ValueAllowed(Partner)
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

// Returns parameters for filling in VAT taxation.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.CommissionWriteOffReportIntercompany, DocumentObject.CommissionWriteOffReportIntercompany - document of the Commission report between
//																			organizations on write-offs.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.The parameters of the filling of the taxable sales().
//
Function ParametersForFillingInVATTaxation_(Document) Export
	
	DocumentAttributes = New Structure("Date, Organization, Contract, SalesContract, 
										|ARAPAccountingViaSeparateCounterparty, LineOfBusiness");
	
	If TypeOf(Document) = Type("DocumentRef.CommissionWriteOffReportIntercompany") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	FillPropertyValues(FillParameters, DocumentAttributes, "Date, Organization, LineOfBusiness");
	
	FillParameters.Contract    = ?(DocumentAttributes.ARAPAccountingViaSeparateCounterparty,
										DocumentAttributes.SalesContract,
										DocumentAttributes.Contract);
	
	FillParameters.ConsignmentReportFromCustomer = True;
	
	FillParameters.ThisIsOperationBetweenOrganizations = True;
	
	Return FillParameters;
	
EndFunction

// Returns the parameters of the selection of articles and analyst.
//
// Returns:
//	Array - Article and analyst selection options (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//          .
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ArrayOfSelectionParameters = New Array;
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef      = "ExpenseItem";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses   = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region IncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef      = "IncomeItem";
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue   = "DimensionOfRevenue";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	Return ArrayOfSelectionParameters;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
//  Array of See ARAPAccountingServer.MechanismParameters - Array of parameters of the functions of the settlement mechanism.
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"ARAPAccountingViaSeparateCounterparty,
			|SalesContract,
			|PurchasingContract");
		ARAPAccountingViaSeparateCounterparty = StructureFillingData.ARAPAccountingViaSeparateCounterparty;
		SalesContract                    = StructureFillingData.SalesContract;
		PurchasingContract                    = StructureFillingData.PurchasingContract;
	ElsIf FillingData = Undefined Then
		ARAPAccountingViaSeparateCounterparty = False;
		SalesContract                    = Undefined;
		PurchasingContract                    = Undefined;
	Else
		ARAPAccountingViaSeparateCounterparty = FillingData.ARAPAccountingViaSeparateCounterparty;
		SalesContract                    = FillingData.SalesContract;
		PurchasingContract                    = FillingData.PurchasingContract;
	EndIf;
	
	StructuresArray = New Array;
	
	#Region ByCommittee
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	If ARAPAccountingViaSeparateCounterparty Then
		ParametersStructure.Contract                      = "Object.PurchasingContract";
		ParametersStructure.Partner                      = "Object.Partner";
		ParametersStructure.Counterparty                   = "Object.Counterparty";
	Else
		ParametersStructure.Contract                      = "Object.Contract";
		ParametersStructure.Partner                      = Catalogs.Partners.OurEnterprise;
		ParametersStructure.Counterparty                   = "Object.Consignee";
	EndIf;
	
	ContractSettlementProcedure = ?(ValueIsFilled(PurchasingContract),"Object.PurchasingContract.ARAPObjectSettings", Enums.ARAPObjectSettings.ByARAPDocuments);
	ParametersStructure.ARAPObjectSettings = ?(ARAPAccountingViaSeparateCounterparty,
											ContractSettlementProcedure,
											"Object.ARAPObjectSettings");
	
	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetailsWithCustomer";
	
	//It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	ParametersStructure.Terms                       = "";
	
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.FinancialAccountingGroup           = "Object.FinancialAccountingGroup";
	ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
		
	ParametersStructure.FormItems.FinancialAccountingGroup = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	ParametersStructure.FormItems.PaymentSettlement        = "PaymentOffsetSenderForm";
	ParametersStructure.FormItems.InscriptionStages       = "DecorationPaymentStagesSender";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStagesSender";
	
	ParametersStructure.PaymentDate                      = "Object.PaymentDate";
	ParametersStructure.PaymentSchedule                     = "Object.PaymentSchedule";
	
	ParametersStructure.ARAPObject                   = "Object.ARAPObjectForSettlementsWithCommissionAgent";
	
	StructuresArray.Add(ParametersStructure);
	
	#EndRegion
	
	#Region FromCommissionAgent
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	
	ParametersStructure.Organization                      = "Object.Consignee";
	
	If ARAPAccountingViaSeparateCounterparty Then
		ParametersStructure.Contract                      = "Object.SalesContract";
		ParametersStructure.Partner                      = "Object.Partner";
		ParametersStructure.Counterparty                   = "Object.Counterparty";
	Else
		ParametersStructure.Contract                      = "Object.Contract";
		ParametersStructure.Partner                      = Catalogs.Partners.OurEnterprise;
		ParametersStructure.Counterparty                   = "Object.Organization";
	EndIf;
	
	ContractSettlementProcedure = ?(ValueIsFilled(SalesContract),"Object.SalesContract.ARAPObjectSettings", Enums.ARAPObjectSettings.ByARAPDocuments);
	ParametersStructure.ARAPObjectSettings = ?(ARAPAccountingViaSeparateCounterparty,
											ContractSettlementProcedure,
											"Object.ARAPObjectSettings");
	
	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetailsWithVendor";
	
	//It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	ParametersStructure.Terms                       = "";
	
	ParametersStructure.CompanyBankAccount        = "Object.RecipientCompanyBankAccount";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "Object.CashAccountRecipient";
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.FinancialAccountingGroup           = "Object.FinancialAccountingGroupOfRecipient";
	ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
		
	ParametersStructure.FormItems.FinancialAccountingGroup = "FinancialAccountingGroupOfRecipient";
	ParametersStructure.FormItems.PaymentSettlement        = "PaymentOffsetRecipientForm";
	ParametersStructure.FormItems.InscriptionStages       = "DecorationPaymentStagesRecipient";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStagesRecipient";
	
	ParametersStructure.PaymentDate                      = "Object.PaymentDate";
	
	ParametersStructure.ARAPObject                   = "Object.ARAPObjectForSettlementsWithConsignor";
	
	StructuresArray.Add(ParametersStructure);
	
	#EndRegion
	
	Return StructuresArray;
	
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

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If Data.ARAPAccountingViaSeparateCounterparty Then
		TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
			Data, Presentation, StandardProcessing, "CommissionWriteOffReportIntercompany");
	EndIf;
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Clear();
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("Date");
	Fields.Add("Number");
	Fields.Add("ARAPAccountingViaSeparateCounterparty");
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	
	Return DataSources;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = "
	|SELECT
	|	DocumentData.Number AS Number,
	|	DocumentData.Date                              AS Period,
	|	DocumentData.Ref                            AS Ref,
	|	DocumentData.Currency                            AS Currency,
	|	DocumentData.Organization                       AS Organization,
	|	DocumentData.Organization                       AS Consignor,
	|	DocumentData.Consignee                       AS Consignee,
	|	DocumentData.Department                     AS Department,
	|	DocumentData.VATTaxation                AS VATTaxation,
	|	DocumentData.ARAPAccountingViaSeparateCounterparty AS ARAPAccountingViaSeparateCounterparty,
	|	DocumentData.Counterparty                        AS Counterparty,
	|	DocumentData.Contract                           AS Contract,
	|	DocumentData.Manager                          AS Manager,
	|	DocumentData.Author                             AS Author,
	|	DocumentData.IncomeItem                     AS IncomeItem,
	|	DocumentData.DimensionOfRevenue                  AS DimensionOfRevenue,
	|	DocumentData.ExpenseItem                    AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses                 AS DimensionOfExpenses,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	CASE
	|		WHEN DocumentData.ARAPAccountingViaSeparateCounterparty
	|			THEN DocumentData.Partner
	|		ELSE VALUE(Catalog.Partners.OurEnterprise)
	|	END                                             AS Partner,
	|	CASE
	|		WHEN DocumentData.EndOfPeriod = DATETIME(1, 1, 1)
	|				OR DocumentData.EndOfPeriod > DocumentData.Date
	|			THEN DocumentData.Date
	|		ELSE DocumentData.EndOfPeriod
	|	END                                             AS EndOfPeriod,
	|	DocumentData.FinancialAccountingGroup            AS FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness           AS LineOfBusiness,
	|	ISNULL(DocumentData.LineOfBusiness.CostAccounting, FALSE) AS AccountingForLBCosts,
	|	ISNULL(DocumentData.LineOfBusiness.IncomeAccounting, FALSE) AS AccountingForIncomeUnderLB,
	|	ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) AS AccountingForSettlementsWithSuppliersUnderLB,
	|	DocumentData.SalesContract                    AS SalesContract,
	|	DocumentData.PurchasingContract                    AS PurchasingContract,
	|	DocumentData.ARAPObjectForSettlementsWithConsignor         AS ARAPObjectForSettlementsWithConsignor,
	|	DocumentData.ARAPObjectForSettlementsWithCommissionAgent      AS ARAPObjectForSettlementsWithCommissionAgent,
	|	DocumentData.ARAPObjectForSettlementsWithConsignor.UUID AS IDOfPaymentObjectWithPrincipal,
	|	DocumentData.ARAPObjectForSettlementsWithCommissionAgent.UUID AS IDOfPaymentObjectWithCommissionAgent,
	|	DocumentData.PaymentDate                       AS PaymentDate,
	|	DocumentData.IncomingDocumentNumber           AS IncomingDocumentNumber,
	|	DocumentData.IncomingDocumentDate            AS IncomingDocumentDate,
	|	DocumentData.ExternalDocumentName    AS ExternalDocumentName,
	|	DocumentData.Comment                       AS Comment,
	|	DocumentData.DocumentAmount                    AS DocumentAmount,
	|	DocumentData.Posted                          AS Posted,
	|	DocumentData.Patch                       AS Patch,
	|	DocumentData.ReversedDocument              AS ReversedDocument,
	|	DocumentData.CorrectedDocument              AS CorrectedDocument,
	|	DocumentData.CorrectedDocument.Date         AS AdjustmentPeriod_,
	|	DocumentData.DeletionMark                   AS DeletionMark
	|FROM
	|	Document.CommissionWriteOffReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	MetadataIdentifier = Common.MetadataObjectID("Document.CommissionWriteOffReportIntercompany");
	
	CommitteeInformation = NStr("vi = 'Báo cáo từ ""%Consignor%""';
								|ru = 'Отчет от ""%Consignor%""';
								|en = 'Report from ""%Consignor%""'; fa = 'Report from ""%Consignor%""';
								|it = 'Report di ""%Consignor%""';
								|pl = 'Raport od ""%Consignor%""';
								|tr = '""%Consignor%""''dan rapor'", Common.DefaultLanguageCode());
	CommitteeInformation = StrReplace(CommitteeInformation, "%Consignor%", Attributes.Consignor);
	
	CommissionAgentInformation = NStr("vi = 'Báo cáo cho ""%Consignee%""';
										|ru = 'Отчет перед ""%Consignee%""';
										|en = 'Report for ""%Consignee%""'; fa = 'Report for ""%Consignee%""';
										|it = 'Report nei confronti di ""%Consignee%""';
										|pl = 'Raport dla ""%Consignee%""';
										|tr = '''''%Consignee%"" karşısında rapor'", Common.DefaultLanguageCode());
	CommissionAgentInformation = StrReplace(CommissionAgentInformation, "%Consignee%", Attributes.Consignee);
	
	DocumentNumber          = ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number);
	IncomingDocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Attributes.IncomingDocumentNumber);
	
	// setting request parameters by FO and calculated conditions
	Query.SetParameter("ARAPCurrency",              Attributes.Currency);
	Query.SetParameter("MetadataIdentifier",           MetadataIdentifier);
	Query.SetParameter("CommitteeInformation",             CommitteeInformation);
	Query.SetParameter("CommissionAgentInformation",          CommissionAgentInformation);
	Query.SetParameter("DocumentNumber",                    DocumentNumber);
	Query.SetParameter("IncomingDocumentNumber",           IncomingDocumentNumber);
	Query.SetParameter("ExternalDocumentName",    Attributes.ExternalDocumentName);
	Query.SetParameter("EndOfPeriod",                      EndOfDay(Attributes.EndOfPeriod));
	Query.SetParameter("LocalAccountingCurrency",    Attributes.LocalAccountingCurrency);
	Query.SetParameter("ManagementAccountingCurrency",        Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("UseAccountingOfOtherIncomeExpenses",           GetFunctionalOption("UseAccountingOfOtherIncomeExpenses")); 
	Query.SetParameter("ConsignmentReportToVendor",                    Enums.BusinessTransactions.PurchaseInvoiceConsignmentStockLost);
	Query.SetParameter("ConsignmentReportFromCustomer",                 Enums.BusinessTransactions.WriteOffReportFromCommissionAgent);
	Query.SetParameter("BusinessOperation",             Enums.BusinessTransactions.CommissionWriteOffReportIntercompany);
	Query.SetParameter("ReportToCommitteeCatalog",          Catalogs.BusinessTransactionsSettings.PurchaseInvoiceConsignmentStockLost);
	Query.SetParameter("CommissionAgentSReportCatalog",       Catalogs.BusinessTransactionsSettings.WriteOffReportFromCommissionAgent);
	Query.SetParameter("BusinessTransactionSetting",    Catalogs.BusinessTransactionsSettings.CommissionWriteOffReportIntercompany);
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsTransferredToCommissionAgent";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	MIN(InventoryKinds.LineNumber)       AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period                                AS Period,
	|	InventoryKinds.CCDNumber                   AS CCDNumber,
	|	InventoryKinds.AnalysisOfAccountingForTransmittedProducts AS ItemsLocationAttributes,
	|	UNDEFINED                           AS Terms,
	|	&Consignor                              AS Organization,
	|	InventoryKinds.InventoryAttributesOfConsignor        AS InventoryOwnerAttribute,
	|	SUM(InventoryKinds.Count)          AS Count,
	|	SUM(InventoryKinds.QuantityByGBRN)    AS QuantityByGBRN,
	|	&BusinessOperation                 AS BusinessOperation
	|FROM
	|	TTTableTypesOfStocks AS InventoryKinds
	|GROUP BY
	|	InventoryKinds.AnalysisOfAccountingForTransmittedProducts,
	|	InventoryKinds.InventoryAttributesOfConsignor,
	|	InventoryKinds.CCDNumber
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
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber         AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&EndOfPeriod                          AS Period,
	|	&Consignee                           AS Organization,
	|	TableTypesOfStocks_.Currency              AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute          AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.CCDNumber            AS CCDNumber,
	|	&BusinessOperation                 AS BusinessOperation,
	|	0                                      AS RevenueAmount,
	|	0                                      AS RevenueAmountExclVATLocal,
	|	0                                      AS RevenueAmountMan,
	|	0                                      AS QuantityConsumed,
	|	TableTypesOfStocks_.Count          AS QuantityConsumedForIncoiceRegistration,
	|	TableTypesOfStocks_.QuantityByGBRN    AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	TableTypesOfStocks_.InventoryAttributesOfConsignor AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products        AS Products,
	|	TableTypesOfStocks_.Characteristic      AS Characteristic,
	|	
	|	&IDOfPaymentObjectWithPrincipal AS FinRecordID,
	|	&BusinessTransactionSetting          AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID AS RowID
	|	
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|
	|	LEFT JOIN Catalog.InventoryKinds AS TypesOfOwnerStocks
	|	ON TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner = TypesOfOwnerStocks.Ref
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber         AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period                                AS Period,
	|	&Consignee                           AS Organization,
	|	TableTypesOfStocks_.Currency              AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute          AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.CCDNumber            AS CCDNumber,
	|	&BusinessOperation                 AS BusinessOperation,
	|	0                                      AS RevenueAmount,
	|	0                                      AS RevenueAmountExclVATLocal,
	|	0                                      AS RevenueAmountMan,
	|	TableTypesOfStocks_.Count          AS QuantityConsumed,
	|	0                                      AS QuantityConsumedForIncoiceRegistration,
	|	0                                      AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	TableTypesOfStocks_.InventoryAttributesOfConsignor AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products        AS Products,
	|	TableTypesOfStocks_.Characteristic      AS Characteristic,
	|	
	|	&IDOfPaymentObjectWithPrincipal AS FinRecordID,
	|	&BusinessTransactionSetting          AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID AS RowID
	|	
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|
	|	LEFT JOIN Catalog.InventoryKinds AS TypesOfOwnerStocks
	|	ON TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner = TypesOfOwnerStocks.Ref
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|UNION ALL
	|
	|SELECT
	|	Rows.LineNumber                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&EndOfPeriod                          AS Period,
	|	&Organization                           AS Organization,
	|	Rows.Currency                          AS Currency,
	|	Rows.InventoryAttributesOfConsignor             AS InventoryOwnerAttribute,
	|	Dimension.DimensionKey                AS ItemsLocationAttributes,
	|	Rows.CCDNumber                        AS CCDNumber,
	|	&ConsignmentReportToVendor                        AS BusinessOperation,
	|	0                                      AS RevenueAmount,
	|	0                                      AS RevenueAmountExclVATLocal,
	|	0                                      AS RevenueAmountMan,
	|	Rows.Count                      AS QuantityConsumed,
	|	Rows.Count                      AS QuantityConsumedForIncoiceRegistration,
	|	Rows.QuantityByGBRN                AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	Rows.InventoryAttributesOfConsignor             AS CorInventoryOwnerAttribute,
	|	Rows.Products                    AS Products,
	|	Rows.Characteristic                  AS Characteristic,
	|	
	|	&IDOfPaymentObjectWithCommissionAgent AS FinRecordID,
	|	&ReportToCommitteeCatalog             AS BusinessTransactionSetting,
	|	Rows.RowID            AS RowID
	|	
	|FROM
	|	TTTableTypesOfStocks AS Rows
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON Dimension.Products = Rows.Products
	|		AND Dimension.Characteristic = Rows.Characteristic
	|		AND Dimension.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND Dimension.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		AND Dimension.StorageLocation = Rows.InventoryAttributesOfConsignor.GoodsOwner
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	Rows.InventoryAttributesOfConsignor.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND (Rows.InventoryOwnerAttributeOfCompanyGoodsOwner = VALUE(Catalog.InventoryKinds.EmptyRef)
	|		OR Rows.InventoryOwnerAttributeOfCompanyGoodsOwner = Rows.InventoryAttributesOfConsignor)
	|	AND Rows.InventoryAttributesOfConsignor <> Rows.InventoryOwnerAttribute
	|
	|ORDER BY
	|	LineNumber
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
		|	DocumentDataHeader.Consignee AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObjectForSettlementsWithConsignor AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.CommissionWriteOffReportIntercompany AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Consignee AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.CommissionWriteOffReportIntercompany.ARAPDetailsWithVendor AS Table
		|		LEFT JOIN Document.CommissionWriteOffReportIntercompany AS DocumentDataHeader
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
		|	DocumentDataHeader.ARAPObjectForSettlementsWithCommissionAgent AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.CommissionWriteOffReportIntercompany AS DocumentDataHeader
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
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.CommissionWriteOffReportIntercompany.ARAPDetailsWithCustomer AS Table
		|		LEFT JOIN Document.CommissionWriteOffReportIntercompany AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region AddTextsToReflectMutualSettlements
	
	#Region Purchase
	
	TextPurchase = "
		|SELECT
		|	Table.Ref                  AS Ref,
		|	Table.Consignee             AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                           AS Partner,
		|	Table.Date                    AS RecorderDate,
		|	Table.Number                   AS RecorderNumber,
		|
		|	Table.ARAPObjectForSettlementsWithConsignor AS ARAPObject,
		|	Table.PaymentDate             AS PaymentDate,
		|	UNDEFINED                    AS PaymentOption,
		|	CASE 
		|		WHEN Table.ARAPAccountingViaSeparateCounterparty 
		|			THEN ISNULL(ContractsOfCounterpartiesSupplier.Ref, Table.Ref)
		|		ELSE ISNULL(ContractsOfCounterpartiesSupplier.Ref, Table.Ref)
		|	END                           AS PurchaseOrder_,
		|	Table.DocumentAmount          AS Sum,
		|	Table.DocumentAmount          AS AmountARAP,
		|	0                               AS AmountARAPByPackage,
		|
		|	Table.ARAPObjectSettings         AS ARAPObjectSettings,
		|	FALSE                            AS InvoiceForOrders,
		|	Table.Currency                  AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.CommissionWriteOffReportIntercompany) AS BusinessOperation,
		|	Table.PaymentMethod             AS PaymentMethod,
		|	Table.Currency                  AS DocumentCurrency,
		|	Table.Date                    AS DateOfCourse,
		|	UNDEFINED                    AS LinkedDocument
		|FROM
		|	Document.CommissionWriteOffReportIntercompany AS Table
		|
		|	LEFT JOIN Catalog.CounterpartyContracts AS ContractsOfCounterpartiesSupplier
		|	ON Table.PurchasingContract = ContractsOfCounterpartiesSupplier.Ref
		|		AND ContractsOfCounterpartiesSupplier.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|WHERE
		|	Table.Ref IN (&Ref)";
	
	#EndRegion
	
	#Region IncreasePaymentPlan_
	
	TextPaymentPlan_ = "
		|SELECT
		|	Table.Ref                  AS Ref,
		|	Table.Consignee             AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                           AS Partner,
		|	Table.Date                    AS RecorderDate,
		|	Table.Number                   AS RecorderNumber,
		|	Table.PaymentDate             AS PaymentDate,
		|	
		|	Table.ARAPObjectForSettlementsWithConsignor AS ARAPObject,
		|	Table.ARAPObjectSettings           AS ARAPObjectSettings,
		|	FALSE                              AS InvoiceForOrders,
		|	FALSE                              AS ExceedingOrder,
		|	CASE 
		|		WHEN Table.ARAPAccountingViaSeparateCounterparty 
		|			THEN ISNULL(ContractsOfCounterpartiesSupplier.Ref, Table.Ref)
		|		ELSE ISNULL(ContractsOfCounterpartiesSupplier.Ref, Table.Ref)
		|	END                           AS PurchaseOrder_,
		|	Table.DocumentAmount          AS AmountDue,
		|	Table.Currency                  AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.CommissionWriteOffReportIntercompany) AS BusinessOperation,
		|	Table.PaymentMethod             AS PaymentMethod,
		|	Table.Currency                  AS DocumentCurrency,
		|	VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt) AS PaymentOption,
		|	UNDEFINED                           AS LinkedDocument
		|FROM
		|	Document.CommissionWriteOffReportIntercompany AS Table
		|
		|	LEFT JOIN Catalog.CounterpartyContracts AS ContractsOfCounterpartiesSupplier
		|	ON Table.PurchasingContract = ContractsOfCounterpartiesSupplier.Ref
		|		AND ContractsOfCounterpartiesSupplier.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|WHERE
		|	Table.Ref IN (&Ref)";

	#EndRegion
	
	#Region PrepaymentsSettlement
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Consignee                                               AS Organization,
		|	CASE WHEN Table.Ref.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Ref.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                                                                   AS Partner,
		|	
		|	Table.ARAPObject                                                   AS CalculationObjectSource,
		|	Table.Ref.ARAPObjectForSettlementsWithConsignor                                 AS CalculationObjectReceiver,
		|
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	Table.AmountARAP                                              AS AmountARAP,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	Table.Sum                                                            AS Sum,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)               AS BusinessOperation
		|	
		|FROM
		|	Document.CommissionWriteOffReportIntercompany.ARAPDetailsWithVendor AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan_, TextAdvancePaymentOffset);
	
	#EndRegion
	
	#Region AddTextsToReflectSalesSettlements
	
	#Region Sale
	
	TextSale =
		"SELECT
		|	Table.Ref                  AS Ref,
		|	Table.Organization             AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                           AS Partner,
		|	
		|	Table.ARAPObjectForSettlementsWithCommissionAgent AS ARAPObject,
		|	Table.PaymentDate             AS PaymentDate,
		|	CASE 
		|		WHEN Table.ARAPAccountingViaSeparateCounterparty 
		|			THEN ISNULL(CounterpartyContractsClient.Ref, Table.Ref)
		|		ELSE ISNULL(CounterpartyContractsClient.Ref, Table.Ref)
		|	END                           AS SalesOrder_,
		|	FALSE                            AS InvoiceForOrders,
		|	Table.DocumentAmount          AS AmountARAP,
		|	0                               AS AmountARAPByPackage,
		|	Table.DocumentAmount          AS Sum,
		|	
		|	Table.ARAPObjectSettings         AS ARAPObjectSettings,
		|	Table.Date                    AS RecorderDate,
		|	Table.Number                   AS RecorderNumber,
		|	Table.Currency                  AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.CommissionWriteOffReportIntercompany) AS BusinessOperation,
		|	Table.Date                    AS DateOfCourse,
		|	Table.Currency                  AS DocumentCurrency,
		|	VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment) AS PaymentOption,
		|	FALSE                            AS ExceedingOrder,
		|	UNDEFINED                    AS LinkedDocument
		|FROM
		|	Document.CommissionWriteOffReportIntercompany AS Table
		|
		|	LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContractsClient
		|	ON Table.SalesContract = CounterpartyContractsClient.Ref
		|		AND CounterpartyContractsClient.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|WHERE
		|	Table.Ref IN (&Ref)";
	
	#EndRegion
	
	#Region IncreasePaymentPlan
	
	TextPaymentPlanning = "
		|SELECT
		|	Table.Ref                         AS Ref,
		|	Table.Organization                    AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                                  AS Partner,
		|	
		|	Table.Ref.ARAPObjectForSettlementsWithCommissionAgent AS ARAPObject,
		|	Table.Ref.Date                    AS RecorderDate,
		|	Table.Ref.Number                   AS RecorderNumber,
		|	Table.Ref.ARAPObjectSettings         AS ARAPObjectSettings,
		|	Table.Ref.Currency                  AS ARAPCurrency,
		|	Table.Ref.Currency                  AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.CommissionWriteOffReportIntercompany) AS BusinessOperation,
		|	Table.Ref.PaymentMethod             AS PaymentMethod,
		|	
		|	Table.Ref.PaymentDate             AS PaymentDate,
		|	VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment) AS PaymentOption,
		|	Table.DocumentAmount                 AS AmountDue,
		|	
		|	TRUE                                 AS ExcludeDuringControl,
		|	FALSE                                   AS InvoiceForOrders,
		|	CASE 
		|		WHEN Table.ARAPAccountingViaSeparateCounterparty 
		|			THEN ISNULL(CounterpartyContractsClient.Ref, Table.Ref)
		|		ELSE ISNULL(CounterpartyContractsClient.Ref, Table.Ref)
		|	END                                  AS SalesOrder_,
		|	FALSE                                   AS ExceedingOrder,
		|	UNDEFINED                           AS LinkedDocument
		|	
		|FROM
		|	Document.CommissionWriteOffReportIntercompany AS Table
		|
		|	LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContractsClient
		|	ON Table.SalesContract = CounterpartyContractsClient.Ref
		|		AND CounterpartyContractsClient.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|WHERE
		|	Table.Ref IN (&Ref)";
	
	#EndRegion
	
	#Region ApplyingPrepayment
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	CASE WHEN Table.Ref.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Ref.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                                                                    AS Partner,
		|	
		|	Table.ARAPObject                                                   AS CalculationObjectSource,
		|	Table.Ref.ARAPObjectForSettlementsWithCommissionAgent                              AS CalculationObjectReceiver,
		|
		|	Table.Ref.Currency				                                     AS ARAPCurrency,
		|	Table.AmountARAP                                              AS AmountARAP,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	Table.Sum                                                            AS Sum,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)               AS BusinessOperation
		|	
		|FROM
		|	Document.CommissionWriteOffReportIntercompany.ARAPDetailsWithCustomer AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, TextSale, TextPaymentPlanning, TextAdvancePaymentOffset);
	
	#EndRegion
	
EndProcedure

Procedure SetRequestParameterFIFOCommissionAgentSMovingEstimate(Query)
	
	If Query.Parameters.Property("FIFOMovingEstimateOfCommissionAgent") Then
		Return;
	EndIf;
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("FinancialAccountingPolicy",
		Query.Parameters.Consignee,
		BegOfMonth(Query.Parameters.Period));
	
	Query.SetParameter("FIFOMovingEstimateOfCommissionAgent",
		(AccountingPolicyParameters <> Undefined
			And AccountingPolicyParameters.InventoryValuationMethod = Enums.InventoryValuationMethods.FIFORollingValuation));
	
EndProcedure

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	&Consignor AS Organization,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	DocumentData.Department AS Department,
	|	CASE
	|		WHEN &AccountingForIncomeUnderLB THEN
	|			&LineOfBusiness
	|	END AS LineOfBusiness,
	|	DocumentData.IncomeItem AS IncomeItem,
	|	DocumentData.DimensionOfRevenue AS DimensionOfRevenue,
	|	&BusinessOperation AS BusinessOperation,
	|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0
	|	END AS SumMan,
	|	CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		ELSE 0
	|	END AS SumCompl,
	|	
	|	&IDOfPaymentObjectWithCommissionAgent AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.CommissionWriteOffReportIntercompany AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.DocumentAmount <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""InventoryKinds"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.Currency AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.AmountIncludingVAT AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObjectForSettlementsWithCommissionAgent AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.CommissionWriteOffReportIntercompany.InventoryKinds AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure


Function QueryTextTableRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RegisterRecordsProductsIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	&ConsignmentReportFromCustomer AS BusinessOperation,
	|	&Consignor AS Organization,
	|	&Department AS Department,
	|
	|	GoodsTable.AnalysisOfAccountingForTransmittedProducts AS ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness AS ProductLineOfBusiness,
	|	UNDEFINED AS Warehouse,
	|	GoodsTable.InventoryAttributesOfConsignor.InventoryType AS InventoryType,
	|	GoodsTable.InventoryAttributesOfConsignor AS InventoryOwnerAttribute,
	|
	|	&ExpenseItem AS IncomeAndExpenseItem,
	|	CASE
	|		WHEN &AccountingForLBCosts THEN
	|			&LineOfBusiness
	|	END AS LineOfBusinessItems,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
	|
	|	GoodsTable.Count AS Count,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		GoodsTable.InventoryAttributesOfConsignor
	|	ELSE 
	|		GoodsTable.Products
	|	END AS SourceOfProductFinancialAccountingGroup
	|
	|FROM
	|	TTTableTypesOfStocks AS GoodsTable
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.IncomeAccordingToWriteOffReportFromCommissionAgent) AS BusinessOperation,
	|	&Consignor AS Organization,
	|	&Department AS Department,
	|	
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	&Contract AS Contract,
	|	&ARAPObjectForSettlementsWithCommissionAgent AS ARAPObject,
	|	
	|	DocumentData.IncomeItem AS IncomeAndExpenseItem,
	|	CASE 
	|		WHEN &AccountingForIncomeUnderLB THEN
	|			&LineOfBusiness
	|	END AS LineOfBusinessItems,
	|	DocumentData.DimensionOfRevenue AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
	|	0 AS AmountExcludingVAT,
	|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	0 AS LocalAmountExcludingVAT,
	|	
	|	&Currency AS Currency,
	|	DocumentData.DocumentAmount AS AmountInCurrency,
	|	0 AS AmountExcludingVATInCurrency,
	|	
	|	&Currency AS ARAPCurrency,
	|	DocumentData.DocumentAmount AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|	
	|	&ARAPObjectForSettlementsWithCommissionAgent AS SourceOfARAPFinancialAccountingGroup,
	|	&IDOfPaymentObjectWithPrincipal AS FinRecordID
	|FROM
	|	Document.CommissionWriteOffReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.DocumentAmount <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers)
	
	RegisterName = "LotsOfGoodsOfOrganizations";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)        AS RecordType,
	|	&EndOfPeriod                                 AS Period,
	|	&Ref                                       AS Recorder,
	|	&Consignee                                  AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&Ref                                       AS DocumentInflow,
	|	UNDEFINED                                  AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.LotVendorAttributes       AS LotVendorAttributes,
	|	TableTypesOfStocks_.Count                 AS Count,
	|	TableTypesOfStocks_.AmountIncludingVAT                  AS Cost,
	|	TableTypesOfStocks_.AmountExcludingVAT                AS CostExcludingVAT,
	|	TableTypesOfStocks_.SumCompl                  AS LocalCost,
	|	0                                             AS VATLocal,
	|	TableTypesOfStocks_.Products               AS Products,
	|	TableTypesOfStocks_.Characteristic             AS Characteristic,
	|	&BusinessOperation                        AS BusinessOperation,
	|	TRUE                                        AS Primary,
	|	UNDEFINED                                  AS DocumentSource
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	&BatchAccountingVersion21
	|	AND TableTypesOfStocks_.Count > 0
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
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	// Record debt to the consignor 
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.RecordDebtToConsignor) AS BusinessOperation,
	|	&Consignee AS Organization,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	&Partner AS Partner,
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|			THEN &Counterparty
	|		ELSE &Consignor
	|	END AS Counterparty,
	|	UNDEFINED AS Terms,
	|	CASE WHEN &ARAPAccountingViaSeparateCounterparty 
	|		THEN &PurchasingContract
	|		ELSE &Contract
	|	END AS Contract,
	|	UNDEFINED AS OrderDocument,
	|
	|	0 AS Count,
	|
	|	CAST(TableTypesOfStocks_.AmountIncludingVAT * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
	|	CAST((TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount)
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVAT,
	|	CAST(TableTypesOfStocks_.AmountIncludingVAT * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST((TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount)
	|		* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalAmountExcludingVAT,
	|	0 AS DiscountAmount,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|	0 AS AdditExpenseAmount,
	|	0 AS AdditionalExpensesAmountExcludingVAT,
	|
	|	&Currency AS DocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|
	|	&Currency AS ARAPCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInARAPCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInARAPCurrency,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObjectForSettlementsWithConsignor AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	TextSelectionOfAnalystField =
	"SELECT
	|	""InventoryKinds"" 							AS TabularSectionName,
	|	DocumentTable.LineNumber 				AS LineNumber,
	|	DocumentData.Partner						AS Vendor,
	|	DocumentData.Counterparty					AS Counterparty,
	|	DocumentTable.VATRate 					AS VATRate,
	|	DocumentData.VATTaxation 			AS VATTaxation,
	|	VALUE(Enum.AssetKinds.Goods)	AS AssetTaxClass,
	|	0											AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.CommissionWriteOffReportIntercompany.InventoryKinds AS DocumentTable
	|	INNER JOIN Document.CommissionWriteOffReportIntercompany AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	INNER JOIN Catalog.InventoryKinds AS CatInventoryKinds
	|		ON DocumentTable.InventoryOwnerAttribute = CatInventoryKinds.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND CatInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTableTypesOfStocks";
	
	SetRequestParametersCurrencyCoefficients(Query);
	SetSettlementAnalyticsParameters(Query);
	InitializeProductAccountingAnalyticsKeys(Query);
	InitializeTrackingAnalyticsKeysForPartners(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	TableTypesOfStocks_.LineNumber                  AS LineNumber,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                   AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Currency                               AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType                           AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner                  AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory   AS SaleOfAnotherCompanyInventory,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryAttributesOfConsignor <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|			THEN TableTypesOfStocks_.InventoryAttributesOfConsignor
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END AS InventoryAttributesOfConsignor,
	|	TableTypesOfStocks_.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness   	AS LineOfBusiness,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	AnalyticsOfTransferredProduct.DimensionKey        AS AnalysisOfAccountingForTransmittedProducts,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products                          AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic                        AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber                     AS CCDNumber,
	|	TableTypesOfStocks_.Count                   AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN             AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT                    AS AmountIncludingVAT,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVAT,
	|	TableTypesOfStocks_.VATAmount                     AS VATAmount,
	|	CAST(TableTypesOfStocks_.AmountIncludingVAT
	|			* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)
	|	)                                               AS SumCompl,
	|	TableTypesOfStocks_.VATRate                    AS VATRate,
	|	TableTypesOfStocks_.RowID          AS RowID,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryAttributesOfConsignor.GoodsOwner REFS Catalog.Partners
	|			THEN AnalysisOfCalculations.DimensionKey
	|		ELSE &AnalyticsCommitteeCommissioner
	|	END AS AnalysisOfSettlementsWithCommittee
	|INTO TTTableTypesOfStocks
	|FROM
	|	Document.CommissionWriteOffReportIntercompany.InventoryKinds AS TableTypesOfStocks_
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsOfTransferredProduct
	|		ON TableTypesOfStocks_.ItemsLocationAttributes.Products		= AnalyticsOfTransferredProduct.Products
	|			AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic	= AnalyticsOfTransferredProduct.Characteristic
	|			AND VALUE(Catalog.Assignments.EmptyRef)= AnalyticsOfTransferredProduct.Purpose
	|			AND &Consignee				= AnalyticsOfTransferredProduct.StorageLocation
	|			AND VALUE(Catalog.ItemsBatches.EmptyRef)= AnalyticsOfTransferredProduct.Series
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsOfTransferredProduct.ProductCostElement
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfCalculations
	|		ON AnalysisOfCalculations.Organization = TableTypesOfStocks_.Ref.Organization
	|			AND AnalysisOfCalculations.Partner = TableTypesOfStocks_.InventoryAttributesOfConsignor.GoodsOwner
	|			AND AnalysisOfCalculations.Counterparty = TableTypesOfStocks_.InventoryAttributesOfConsignor.Counterparty
	|			AND AnalysisOfCalculations.Contract = TableTypesOfStocks_.InventoryAttributesOfConsignor.Contract
	|			AND AnalysisOfCalculations.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	
	|		LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber 		= TableTypesOfStocks_.LineNumber
	|			AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	RequestPreliminary = New Query("
	|SELECT
	|	GoodsTable.Products	 AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose	 AS Purpose,
	|	GoodsTable.Series			 AS Series,
	|	GoodsTable.Warehouse			 AS Warehouse
	|FROM (
	|	SELECT DISTINCT
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		&EmptyAssignment AS Purpose,
	|		&Series AS Series,
	|		&Consignee AS Warehouse
	|	FROM
	|		Document.CommissionWriteOffReportIntercompany.InventoryKinds AS TableTypesOfStocks_
	|	WHERE
	|		TableTypesOfStocks_.Ref = &Ref
	|
	|	UNION ALL
	|	SELECT
	|		Rows.ItemsLocationAttributes.Products,
	|		Rows.ItemsLocationAttributes.Characteristic,
	|		&EmptyAssignment AS Purpose,
	|		&Series AS Series,
	|		Rows.InventoryAttributesOfConsignor.GoodsOwner AS Warehouse
	|	FROM
	|		Document.CommissionWriteOffReportIntercompany.InventoryKinds AS Rows
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS CommitteeAnalytics
	|		ON CommitteeAnalytics.Products = Rows.ItemsLocationAttributes.Products
	|			AND CommitteeAnalytics.Characteristic = Rows.ItemsLocationAttributes.Characteristic
	|			AND &EmptyAssignment = Rows.ItemsLocationAttributes.Purpose
	|			AND CommitteeAnalytics.Series = Rows.ItemsLocationAttributes.Series
	|			AND CommitteeAnalytics.StorageLocation = Rows.InventoryAttributesOfConsignor.GoodsOwner
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeAnalytics.ProductCostElement
	|	WHERE
	|		Rows.Ref = &Ref
	|		AND CommitteeAnalytics.Products IS NULL
	|		AND NOT Rows.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|		AND Rows.InventoryAttributesOfConsignor.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	) AS GoodsTable
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON GoodsTable.Products = Dimension.Products
	|		AND GoodsTable.Characteristic = Dimension.Characteristic
	|		AND GoodsTable.Purpose = Dimension.Purpose
	|		AND GoodsTable.Series = Dimension.Series
	|		AND GoodsTable.Warehouse = Dimension.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	Dimension.Products IS NULL 
	|
	|GROUP BY
	|	GoodsTable.Warehouse,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series
	|");
	
	RequestPreliminary.SetParameter("Ref", Query.Parameters.Ref);
	RequestPreliminary.SetParameter("Consignee", Query.Parameters.Consignee);
	RequestPreliminary.SetParameter("Department", Query.Parameters.Department);
	RequestPreliminary.SetParameter("Series", Catalogs.ItemsBatches.EmptyRef());
	RequestPreliminary.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	
	Selection = RequestPreliminary.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection)
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Procedure InitializeTrackingAnalyticsKeysForPartners(Query)
	
	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized_") Then
		Return;
	EndIf;
	
	InitializationRequest = New Query("
	|SELECT DISTINCT
	|	GoodsTable.Ref.Organization AS Organization,
	|	GoodsTable.InventoryAttributesOfConsignor.GoodsOwner AS Partner,
	|	GoodsTable.InventoryAttributesOfConsignor.Counterparty AS Counterparty,
	|	GoodsTable.InventoryAttributesOfConsignor.Contract AS Contract,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
	|FROM
	|	Document.CommissionWriteOffReportIntercompany.InventoryKinds AS GoodsTable
	|
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON Dimension.Organization = GoodsTable.Ref.Organization
	|		AND Dimension.Partner = GoodsTable.InventoryAttributesOfConsignor.GoodsOwner
	|		AND Dimension.Counterparty = GoodsTable.InventoryAttributesOfConsignor.Counterparty
	|		AND Dimension.Contract = GoodsTable.InventoryAttributesOfConsignor.Contract
	|		AND Dimension.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	Dimension.DimensionKey IS NULL 
	|	AND GoodsTable.Ref = &Ref
	|	AND GoodsTable.InventoryAttributesOfConsignor.GoodsOwner REFS Catalog.Partners
	|");
	
	InitializationRequest.SetParameter("Ref", Query.Parameters.Ref);
	Selection = InitializationRequest.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection)
	EndDo;
	
	Query.SetParameter("PartnerAccountingAnalyticsKeysInitialized_", True);
	
EndProcedure

Procedure SetSettlementAnalyticsParameters(Query)
	
	If Query.Parameters.Property("AnalyticsCommitteeCommissioner")
		And Query.Parameters.Property("AnalyticsCommissionerCommittee")
		And Query.Parameters.Property("SettlementAnalyticsCommitteeCommissioner")
		And Query.Parameters.Property("MutualSettlementAnalyticsCommissionAgentCommittee") Then
		Return;
	EndIf;
	
	StructureCommitteeCommissioner = New Structure();
	StructureCommitteeCommissioner.Insert("Organization", Query.Parameters.Consignor);
	StructureCommitteeCommissioner.Insert("Partner", Catalogs.Partners.OurEnterprise);
	StructureCommitteeCommissioner.Insert("Counterparty", Query.Parameters.Consignee);
	StructureCommitteeCommissioner.Insert("Contract", Query.Parameters.Contract);
	StructureCommitteeCommissioner.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);
	
	AnalyticsCommitteeCommissioner = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureCommitteeCommissioner);
	
	StructureCommissionerCommittee = New Structure();
	StructureCommissionerCommittee.Insert("Organization", Query.Parameters.Consignee);
	StructureCommissionerCommittee.Insert("Partner", Catalogs.Partners.OurEnterprise);
	StructureCommissionerCommittee.Insert("Counterparty", Query.Parameters.Consignor);
	StructureCommissionerCommittee.Insert("Contract", Query.Parameters.Contract);
	StructureCommissionerCommittee.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);
	
	AnalyticsCommissionerCommittee = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureCommissionerCommittee);

	If Query.Parameters.ARAPAccountingViaSeparateCounterparty Then
		
		StructureCommitteeCommissioner = New Structure();
		StructureCommitteeCommissioner.Insert("Organization", Query.Parameters.Consignor);
		StructureCommitteeCommissioner.Insert("Partner", Query.Parameters.Partner);
		StructureCommitteeCommissioner.Insert("Counterparty", Query.Parameters.Counterparty);
		StructureCommitteeCommissioner.Insert("Contract", Query.Parameters.SalesContract);
		StructureCommitteeCommissioner.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);
		
		SettlementAnalyticsCommitteeCommissioner = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureCommitteeCommissioner);
		
		StructureCommissionerCommittee = New Structure();
		StructureCommissionerCommittee.Insert("Organization", Query.Parameters.Consignee);
		StructureCommissionerCommittee.Insert("Partner", Query.Parameters.Partner);
		StructureCommissionerCommittee.Insert("Counterparty", Query.Parameters.Counterparty);
		StructureCommissionerCommittee.Insert("Contract", Query.Parameters.PurchasingContract);
		StructureCommissionerCommittee.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);
		
		MutualSettlementAnalyticsCommissionAgentCommittee = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureCommissionerCommittee);
	Else
		SettlementAnalyticsCommitteeCommissioner = AnalyticsCommitteeCommissioner;
		MutualSettlementAnalyticsCommissionAgentCommittee = AnalyticsCommissionerCommittee;
	EndIf;
	
	Query.SetParameter("AnalyticsCommitteeCommissioner",               AnalyticsCommitteeCommissioner);
	Query.SetParameter("AnalyticsCommissionerCommittee",               AnalyticsCommissionerCommittee);
	Query.SetParameter("SettlementAnalyticsCommitteeCommissioner", SettlementAnalyticsCommitteeCommissioner);
	Query.SetParameter("MutualSettlementAnalyticsCommissionAgentCommittee", MutualSettlementAnalyticsCommissionAgentCommittee);
	
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Query.Parameters.Currency, 
		Undefined, // ARAPCurrency
		Query.Parameters.Period,
		Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",           Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul",          Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBases", QueryTexts) Then
		QueryTextTTBases(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.RefType                AS RefType,
	|	DocumentData.Organization              AS Organization,
	|	DocumentData.BusinessOperation    AS BusinessOperation,
	|	DocumentData.Partner                  AS Partner,
	|	DocumentData.Counterparty               AS Counterparty,
	|	DocumentData.Contract                  AS Contract,
	|	DocumentData.LineOfBusiness  AS LineOfBusiness,
	|	DocumentData.AdditionalRecord     AS AdditionalRecord,
	|	DocumentData.Department            AS Department,
	|	DocumentData.StorageLocation            AS StorageLocation,
	|	DocumentData.IBDocumentDate          AS IBDocumentDate,
	|	DocumentData.Ref                   AS Ref,
	|	DocumentData.IBDocumentNumber         AS IBDocumentNumber,
	|	DocumentData.EmployeeResponsible            AS EmployeeResponsible,
	|	DocumentData.Author                    AS Author,
	|	DocumentData.Comment              AS Comment,
	|	DocumentData.Currency                   AS Currency,
	|	DocumentData.Sum                    AS Sum,
	|	DocumentData.Status                   AS Status,
	|	DocumentData.Posted                 AS Posted,
	|	DocumentData.DeletionMark          AS DeletionMark,
	|	DocumentData.More            AS More,
	|	DocumentData.SourceDocumentDate  AS SourceDocumentDate,
	|	DocumentData.SourceDocumentNumber AS SourceDocumentNumber,
	|	DocumentData.ReverseTransactionCorrection        AS ReverseTransactionCorrection,
	|	DocumentData.ReversedDocument     AS ReversedDocument,
	|	DocumentData.CorrectedDocument     AS CorrectedDocument,
	|	DocumentData.ExternalDocumentName AS SourceDocumentName,
	|	DocumentData.IBDocumentDate          AS RecordingInAccountingDate,
	|	UNDEFINED                             AS Priority
	|FROM
	|	TTBases AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBases(Query, QueryTexts)
	
	RegisterName = "TTBases";
	
	QueryText =
	"SELECT
	|	TableDocumentRegistry.RefType                          AS RefType,
	|	TableDocumentRegistry.Organization                        AS Organization,
	|	TableDocumentRegistry.BusinessOperation              AS BusinessOperation,
	|	TableDocumentRegistry.Partner                            AS Partner,
	|	TableDocumentRegistry.Counterparty                         AS Counterparty,
	|	MAX(TableDocumentRegistry.Contract)                  AS Contract,
	|	TableDocumentRegistry.LineOfBusiness            AS LineOfBusiness,
	|	MIN(TableDocumentRegistry.AdditionalRecord)      AS AdditionalRecord,
	|	TableDocumentRegistry.Department                      AS Department,
	|	TableDocumentRegistry.StorageLocation                      AS StorageLocation,
	|	TableDocumentRegistry.IBDocumentDate                    AS IBDocumentDate,
	|	TableDocumentRegistry.Ref                             AS Ref,
	|	MAX(TableDocumentRegistry.IBDocumentNumber)         AS IBDocumentNumber,
	|	MAX(TableDocumentRegistry.EmployeeResponsible)            AS EmployeeResponsible,
	|	MAX(TableDocumentRegistry.Author)                    AS Author,
	|	MAX(TableDocumentRegistry.Comment)              AS Comment,
	|	MAX(TableDocumentRegistry.Currency)                   AS Currency,
	|	MAX(TableDocumentRegistry.Sum)                    AS Sum,
	|	MAX(TableDocumentRegistry.Status)                   AS Status,
	|	MAX(TableDocumentRegistry.Posted)                 AS Posted,
	|	MAX(TableDocumentRegistry.DeletionMark)          AS DeletionMark,
	|	MAX(TableDocumentRegistry.More)            AS More,
	|	MAX(TableDocumentRegistry.SourceDocumentDate)  AS SourceDocumentDate,
	|	MAX(TableDocumentRegistry.Patch)              AS ReverseTransactionCorrection,
	|	MAX(TableDocumentRegistry.ReversedDocument)     AS ReversedDocument,
	|	MAX(TableDocumentRegistry.CorrectedDocument)     AS CorrectedDocument,
	|	MAX(TableDocumentRegistry.ExternalDocumentName) AS ExternalDocumentName,
	|	MAX(TableDocumentRegistry.SourceDocumentNumber) AS SourceDocumentNumber
	|INTO TTBases
	|	FROM
	|	(SELECT
	|		DocumentData.Ref             AS Ref,
	|		&Period                            AS IBDocumentDate,
	|		&Number                             AS IBDocumentNumber,
	|		&MetadataIdentifier           AS RefType,
	|		&Consignor                          AS Organization,
	|		&BusinessOperation             AS BusinessOperation,
	|		&Partner                           AS Partner,
	|		&Counterparty                        AS Counterparty,
	|		&Contract                           AS Contract,
	|		UNDEFINED                       AS LineOfBusiness,
	|		UNDEFINED                       AS StorageLocation,
	|		&Department                     AS Department,
	|		&Manager                          AS EmployeeResponsible,
	|		&Author                             AS Author,
	|		CAST(&Comment AS STRING (100)) AS Comment,
	|		&Currency                            AS Currency,
	|		&DocumentAmount                    AS Sum,
	|		UNDEFINED                       AS Status,
	|		&Posted                          AS Posted,
	|		&DeletionMark                   AS DeletionMark,
	|		FALSE                               AS AdditionalRecord,
	|		CAST(&CommissionAgentInformation AS STRING (100)) AS More,
	|		&Period                            AS SourceDocumentDate,
	|		&Patch                       AS Patch,
	|		&ReversedDocument              AS ReversedDocument,
	|		&CorrectedDocument              AS CorrectedDocument,
	|		&ExternalDocumentName    AS ExternalDocumentName,
	|		&DocumentNumber                    AS SourceDocumentNumber
	|	FROM
	|		Document.CommissionWriteOffReportIntercompany AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Ref   AS Ref,
	|		&Period                  AS IBDocumentDate,
	|		&Number                   AS IBDocumentNumber,
	|		&MetadataIdentifier AS RefType,
	|		&Consignee             AS Organization,
	|		&BusinessOperation   AS BusinessOperation,
	|		&Partner                 AS Partner,
	|		&Counterparty              AS Counterparty,
	|		&Contract                 AS Contract,
	|		UNDEFINED             AS LineOfBusiness,
	|		UNDEFINED             AS StorageLocation,
	|		&Department           AS Department,
	|		&Manager                AS EmployeeResponsible,
	|		&Author                   AS Author,
	|		CAST(&Comment AS STRING (100)) AS Comment,
	|		&Currency                  AS Currency,
	|		&DocumentAmount          AS Sum,
	|		UNDEFINED             AS Status,
	|		&Posted                AS Posted,
	|		&DeletionMark         AS DeletionMark,
	|		TRUE                   AS AdditionalRecord,
	|		CAST(&CommitteeInformation AS STRING (100)) AS More,
	|		CASE
	|			WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN &Period
	|			ELSE &IncomingDocumentDate
	|		END                    AS SourceDocumentDate,
	|		&Patch             AS Patch,
	|		&ReversedDocument    AS ReversedDocument,
	|		&CorrectedDocument    AS CorrectedDocument,
	|		CASE
	|			WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN UNDEFINED
	|			ELSE &ExternalDocumentName
	|		END                    AS ExternalDocumentName,
	|		CASE
	|			WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN &DocumentNumber
	|			ELSE &IncomingDocumentNumber
	|		END                    AS SourceDocumentNumber
	|	FROM
	|		Document.CommissionWriteOffReportIntercompany AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref) AS TableDocumentRegistry
	|
	|GROUP BY
	|	TableDocumentRegistry.RefType,
	|	TableDocumentRegistry.Organization,
	|	TableDocumentRegistry.BusinessOperation,
	|	TableDocumentRegistry.Partner,
	|	TableDocumentRegistry.Counterparty,
	|	TableDocumentRegistry.LineOfBusiness,
	|	TableDocumentRegistry.Department,
	|	TableDocumentRegistry.StorageLocation,
	|	TableDocumentRegistry.IBDocumentDate,
	|	TableDocumentRegistry.Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	QueryText = AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses("VariancePeriod");
	QueryText = QueryText + "UNION ALL" + "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	UNDEFINED AS Organization,
	|	&Department AS Department,
	|	&ExpenseItem AS ExpenseItem,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|	0 AS AmountIncludingVATCompl,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	UNDEFINED AS BusinessTransactionSetting,
	|	&AdjustmentPeriod_ AS VariancePeriod
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.CommissionWriteOffReportIntercompany";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	TemporaryTableQueryTexts = New Map();
	
	RequestTextPartenr = "
		|	CASE
		|		WHEN DocumentData.ARAPAccountingViaSeparateCounterparty
		|			THEN DocumentData.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)
		|	END";
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("DocumentNumber",           """""");
	RedefiningParameterCalculation.Insert("CommitteeInformation",    """""");
	RedefiningParameterCalculation.Insert("IncomingDocumentNumber",  """""");
	RedefiningParameterCalculation.Insert("CommissionAgentInformation", """""");
	RedefiningParameterCalculation.Insert("Consignor",                 "DocumentData.Ref.Organization");
	RedefiningParameterCalculation.Insert("Partner",                  RequestTextPartenr);
	
	ParameterValues = New Structure;
	ParameterValues.Insert("BusinessOperation",
		Enums.BusinessTransactions.CommissionWriteOffReportIntercompany);
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		TemporaryTableQueryTexts.Insert("TTBases", QueryTextTTBases(Query, QueryTexts));
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
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
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
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

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	AdditionalParameters.Add("AnalyticsCommitteeCommissioner");
	AdditionalParameters.Add("AnalyticsCommissionerCommittee");
	AdditionalParameters.Add("SettlementAnalyticsCommitteeCommissioner");
	AdditionalParameters.Add("MutualSettlementAnalyticsCommissionAgentCommittee");
	AdditionalParameters.Add("FIFOMovingEstimateOfCommissionAgent");
	
	If Query <> Undefined Then
		SetSettlementAnalyticsParameters(Query);
		SetRequestParameterFIFOCommissionAgentSMovingEstimate(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTableTypesOfStocks");
	AdditionalTables.Add("TTOtherExpenses_");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTableTypesOfStocks(Query, QueryTexts);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[1], QueryTexts) Then
			QueryTextTableTTOtherExpenses_(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region WriteOffForExpensesAssets_Product
	
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
	|	DocumentTable.Organization 							AS Organization,
	|	TableTypesOfStocks_.AnalysisOfAccountingForTransmittedProducts	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryAttributesOfConsignor 					AS InventoryOwnerAttribute,
	|	&VATTaxation										AS VATActivityType,
	|	DocumentTable.VATTaxation						AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	ISNULL(OtherExpenses.CompanyRecipient, UNDEFINED) AS CorCompany,
	|	UNDEFINED 								    			AS CorItemsLocationAttributes,
	|	UNDEFINED				  				    			AS CorInventoryOwnerAttribute,
	|	&ExpenseItem 			    							AS ExpenseItemAssets,
	|	&DimensionOfExpenses    						  			    AS AssetExpenseAnalytics,
	|	UNDEFINED			    								AS CorLineOfBusiness,
	|	TableTypesOfStocks_.AnalysisOfSettlementsWithCommittee 			AS AccountingDimensionByPartners,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED						AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 		AS Count,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.WriteOffReportFromCommissionAgent) AS BusinessOperation,
	|	TableTypesOfStocks_.RowID	 								AS RowID,
	|	TableTypesOfStocks_.RowID 						 			AS FinRecordID,
	|	&CommissionAgentSReportCatalog								 			AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CommissionWriteOffReportIntercompany AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|	LEFT JOIN Catalog.InventoryKinds AS TypesOfCommitteeStocks
	|		ON TypesOfCommitteeStocks.Ref = TableTypesOfStocks_.InventoryAttributesOfConsignor
	|	LEFT JOIN TTOtherExpenses_ AS OtherExpenses
	|		ON OtherExpenses.ExpenseItem = &ExpenseItem
	|		AND OtherExpenses.DimensionOfExpenses = &DimensionOfExpenses
	|WHERE
	|	DocumentTable.Ref IN (&Ref)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.RecogniseAsExpensesAssets,
		QueryText);
	
	#EndRegion

	#Region ExternalReceipt_Product
	
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
	|	DocumentTable.Consignee						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	UNDEFINED										AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	TableTypesOfStocks_.VATActivityType 				AS VATActivityType,
	|	DocumentTable.VATTaxation					AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED					AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	UNDEFINED 									AS RowID,
	|	TableTypesOfStocks_.AmountIncludingVAT					AS Cost,
	|	TableTypesOfStocks_.AmountExcludingVAT					AS CostExcludingVAT,
	|	TableTypesOfStocks_.SumCompl					AS LocalCost,
	|	0                                   			AS VATLocal,
	|	TableTypesOfStocks_.AmountIncludingVAT					AS CostMan,
	|	0 												AS VATManag,
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
	|	VALUE(Enum.BusinessTransactions.PurchaseInvoiceConsignmentStockLost) AS BusinessOperation,
	|	&IDOfPaymentObjectWithPrincipal							 AS FinRecordID,
	|	&ReportToCommitteeCatalog                 							 AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CommissionWriteOffReportIntercompany AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion

	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#Region State

// Calculates the current status of the Commission report on the recipient's side.
//
// Parameters:
//	ReportOnCommission         - DocumentRef.CommissionReportIntercompany - Document whose state needs to be calculated
//	Contract                 - CatalogRef.CounterpartyContracts    - Customer agreement
//	StateOfCalculations       - ClientApplicationForm - The form in which the calculated state will be placed
//	Organization             - Undefined, CatalogRef.Companies - Organization.
//
Procedure CalculateRecipientState(Val ReportOnCommission, Val Contract, StateOfCalculations, Organization=Undefined) Export
	
	FillPropertyValues(StateOfCalculations, StructureOfSettlementStatusRecipient());
	
	If ValueIsFilled(ReportOnCommission) And AccessRight("Read", Metadata.AccumulationRegisters.VendorsARAPAccounting) Then
		SetPrivilegedMode(True);
		Query = New Query("
		|SELECT
		|	CASE
		|		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportOnCommission.Posted
		|				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		|			THEN CAST(ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) AS NUMBER(31,2))
		|		ELSE 0
		|	END AS PaymentAmountRecipient,
		|	CASE
		|		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportOnCommission.Posted
		|				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		|			THEN CAST(ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) * 100 / ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) AS NUMBER(15, 0))
		|		ELSE 0
		|	END AS PaymentPercentageRecipient,
		|	CASE
		|		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportOnCommission.Posted
		|				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		|				AND ISNULL(SettlementsWithSuppliersBalancesAsOfDate.AmountDueBalance, 0) < 0
		|			THEN CAST(-ISNULL(SettlementsWithSuppliersBalancesAsOfDate.AmountDueBalance, 0) AS NUMBER(31,2))
		|		ELSE 0
		|	END AS AmountOfOverduePaymentRecipient,
		|	CASE
		|		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportOnCommission.Posted
		|				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		|			THEN ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0)
		|		ELSE 0
		|	END AS OrderReceiptAmount,
		|	CASE
		|		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportOnCommission.Posted
		|				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		|			THEN CAST(ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) * 100 / ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) AS NUMBER(15, 0))
		|		ELSE 0
		|	END AS PercentageOfOrderReceipt,
		|	CASE
		|		WHEN DocumentReportOnCommission.Posted
		|				AND (ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		|					OR DocumentReportOnCommission.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts))
		|			THEN CAST(ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0) AS NUMBER(31,2))
		|		ELSE 0
		|	END AS AmountOfDebtRecipient,
		|	CASE
		|		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportOnCommission.Posted
		|				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		|			THEN CASE
		|					WHEN ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0) > 0
		|						THEN CAST(ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0) * 100 / ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) AS NUMBER(15, 0))
		|					ELSE CAST(ISNULL(-VendorsARAPAccountingBalance.SumClosingBalance, 0) * 100 / ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) AS NUMBER(15, 0))
		|				END
		|		ELSE 0
		|	END AS PercentageOfDebtRecipient,
		|	CASE
		|		WHEN DocumentReportOnCommission.Posted
		|				AND DocumentReportOnCommission.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|			THEN -VendorsARAPAccountingBalance.AmountDueClosingBalance
		|		ELSE 0
		|	END AS AmountPayableRecipient
		|FROM
		|	Document.CommissionWriteOffReportIntercompany AS DocumentReportOnCommission
		|		LEFT JOIN AccumulationRegister.VendorsARAPAccounting.BalanceAndTurnovers(
		|				,
		|				,
		|				,
		|				,
		|				ARAPObject = &ARAPObject
		|					AND (AccountingDimensionByPartners.Organization = &Organization
		|						OR &Organization = UNDEFINED)) AS VendorsARAPAccountingBalance
		|		ON (TRUE)
		|		LEFT JOIN AccumulationRegister.VendorsARAPAccounting.Balance(
		|				ENDOFPERIOD(&CurrentDate, DAY),
		|				ARAPObject = &ARAPObject
		|					AND (AccountingDimensionByPartners = &Organization
		|						OR &Organization = UNDEFINED)) AS SettlementsWithSuppliersBalancesAsOfDate
		|		ON (TRUE)
		|WHERE
		|	DocumentReportOnCommission.Ref = &ReportOnCommission");
		
		ARAPObject = Common.ObjectAttributeValue(ReportOnCommission, "ARAPObjectForSettlementsWithConsignor");
		
		Query.SetParameter("ReportOnCommission", ReportOnCommission);
		Query.SetParameter("ARAPObject", ARAPObject);
		Query.SetParameter("CurrentDate",  BegOfDay(CurrentSessionDate()));
		Query.SetParameter("Organization", Organization);
		
		Selection = Query.Execute().Select();
		Selection.Next();
		
		FillPropertyValues(StateOfCalculations, Selection);
		
	EndIf;
	
EndProcedure

// Calculates the current status of the Commission report on the sender's side.
//
// Parameters:
//	ReportOnCommission  - DocumentRef.CommissionReportIntercompany - Document whose state needs to be calculated
//	Contract                 - CatalogRef.CounterpartyContracts    - Customer agreement
//	StateOfCalculations       - ClientApplicationForm - The form in which the calculated state will be placed
//	Organization             - CatalogRef.Companies - Organization.
//
Procedure CalculateSenderState(Val ReportOnCommission, Val Contract, StateOfCalculations, Organization) Export
	
	FillPropertyValues(StateOfCalculations, StructureOfSettlementStatusSender());
	
	If ValueIsFilled(ReportOnCommission) And AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting) Then
		Query = New Query("
		|SELECT
		|	CASE
		|		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportOnCommission.Posted
		|				AND DocumentReportOnCommission.DocumentAmount > 0
		|			THEN ISNULL(CustomersARAPAccountingBalance.AmountDueExpense, 0)
		|		ELSE 0
		|	END AS PaymentAmountSender,
		|	CASE
		|		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportOnCommission.Posted
		|				AND  DocumentReportOnCommission.DocumentAmount > 0
		|			THEN CAST(ISNULL(CustomersARAPAccountingBalance.AmountDueExpense, 0) * 100 / DocumentReportOnCommission.DocumentAmount AS NUMBER(15, 0))
		|		ELSE 0
		|	END AS PaymentPercentageSender,
		|	CASE
		|		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportOnCommission.Posted
		|				AND DocumentReportOnCommission.DocumentAmount > 0
		|			THEN CAST(ISNULL(SettlementsWithCustomersBalancesAsOfDateOfRelevance.AmountDueBalance, 0) AS NUMBER(31,2))
		|		ELSE 0
		|	END AS AmountOfOverduePaymentSender,
		|	CASE
		|		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportOnCommission.Posted
		|				AND DocumentReportOnCommission.DocumentAmount > 0
		|			THEN  ISNULL(CustomersARAPAccountingBalance.SumReceipt, 0)
		|		ELSE 0
		|	END AS AmountByShipment,
		|	CASE
		|		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportOnCommission.Posted
		|				AND DocumentReportOnCommission.DocumentAmount > 0
		|			THEN CAST(ISNULL(CustomersARAPAccountingBalance.SumReceipt, 0) * 100 / DocumentReportOnCommission.DocumentAmount AS NUMBER(15, 0))
		|		ELSE 0
		|	END AS OrderShipmentPercentage,
		|	CASE
		|		WHEN DocumentReportOnCommission.Posted
		|				AND ( DocumentReportOnCommission.DocumentAmount > 0
		|					OR DocumentReportOnCommission.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts))
		|			THEN CAST(ISNULL(CustomersARAPAccountingBalance.SumClosingBalance, 0) AS NUMBER(31,2))
		|		ELSE 0
		|	END AS AmountOwedSender,
		|	CASE
		|		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				AND DocumentReportOnCommission.Posted
		|				AND DocumentReportOnCommission.DocumentAmount > 0
		|			THEN CASE
		|					WHEN ISNULL(CustomersARAPAccountingBalance.SumClosingBalance, 0) > 0
		|						THEN CAST(ISNULL(CustomersARAPAccountingBalance.SumClosingBalance, 0) * 100 / DocumentReportOnCommission.DocumentAmount AS NUMBER(15, 0))
		|					ELSE CAST(ISNULL(-CustomersARAPAccountingBalance.SumClosingBalance, 0) * 100 / DocumentReportOnCommission.DocumentAmount AS NUMBER(15, 0))
		|				END
		|		ELSE 0
		|	END AS PercentageOfDebtSender,
		|	CASE
		|		WHEN DocumentReportOnCommission.Posted
		|				AND DocumentReportOnCommission.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|			THEN CustomersARAPAccountingBalance.AmountDueClosingBalance
		|		ELSE 0
		|	END AS AmountPayableSender
		|FROM
		|	Document.CommissionWriteOffReportIntercompany AS DocumentReportOnCommission
		|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.BalanceAndTurnovers(
		|				,
		|				,
		|				,
		|				,
		|				ARAPObject = &ARAPObject
		|					AND (AccountingDimensionByPartners.Organization = &Organization
		|						OR &Organization = UNDEFINED)) AS CustomersARAPAccountingBalance
		|		ON (TRUE)
		|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Balance(
		|				ENDOFPERIOD(&CurrentDate, DAY),
		|				ARAPObject = &ARAPObject
		|					AND (AccountingDimensionByPartners.Organization = &Organization
		|						OR &Organization = UNDEFINED)) AS SettlementsWithCustomersBalancesAsOfDateOfRelevance
		|		ON (TRUE)
		|WHERE
		|	DocumentReportOnCommission.Ref = &ReportOnCommission");
		
		ARAPObject = Common.ObjectAttributeValue(ReportOnCommission, "ARAPObjectForSettlementsWithCommissionAgent");
		
		Query.SetParameter("ReportOnCommission", ReportOnCommission);
		Query.SetParameter("ARAPObject", ARAPObject);
		Query.SetParameter("CurrentDate",  BegOfDay(CurrentSessionDate()));
		Query.SetParameter("Organization", Organization);
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		Selection.Next();
		
		FillPropertyValues(StateOfCalculations, Selection);
		
	EndIf;
	
EndProcedure

// Initializes the calculation state structure.
Function StructureOfSettlementStatusRecipient()
	
	StructureOfStateOfCalculations = New Structure;
	StructureOfStateOfCalculations.Insert("PaymentAmountRecipient", 0);
	StructureOfStateOfCalculations.Insert("OrderReceiptAmount", 0);
	StructureOfStateOfCalculations.Insert("PaymentPercentageRecipient", 0);
	StructureOfStateOfCalculations.Insert("PercentageOfOrderReceipt", 0);
	StructureOfStateOfCalculations.Insert("AmountOfOverduePaymentRecipient", 0);
	StructureOfStateOfCalculations.Insert("AmountOfDebtRecipient", 0);
	StructureOfStateOfCalculations.Insert("PercentageOfDebtRecipient", 0);
	StructureOfStateOfCalculations.Insert("AmountPayableRecipient", 0);
	
	Return StructureOfStateOfCalculations
	
EndFunction

// Initializes the calculation state structure.
//
Function StructureOfSettlementStatusSender()
	
	StructureOfStateOfCalculations = New Structure;
	StructureOfStateOfCalculations.Insert("PaymentAmountSender", 0);
	StructureOfStateOfCalculations.Insert("AmountByShipment", 0);
	StructureOfStateOfCalculations.Insert("PaymentPercentageSender", 0);
	StructureOfStateOfCalculations.Insert("OrderShipmentPercentage", 0);
	StructureOfStateOfCalculations.Insert("AmountOfOverduePaymentSender", 0);
	StructureOfStateOfCalculations.Insert("AmountOwedSender", 0);
	StructureOfStateOfCalculations.Insert("PercentageOfDebtSender", 0);
	StructureOfStateOfCalculations.Insert("AmountPayableSender", 0);
	
	Return StructureOfStateOfCalculations
	
EndFunction

#EndRegion

#Region Posting

#EndRegion

#EndRegion

#EndIf

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
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);	
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Partner, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Manager";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "BankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CashAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "CommissionFeeCalculationMethod";
	Parameters.FillInIf.ObjectFieldsFilledIn = "CommissionFeeCalculationMethod";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "RemunerationPercentage", Parameters);
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "OperationService, CommissionFeeCalculationMethod, VATRateOfRemuneration");
	
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
	DocumentMechanisms.Add("Purchases");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentCorrection");
	
	ConsignmentReportToVendorLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.ConsignmentReportToVendor") Then
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
		
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers);
		QueryTextTablePurchases(Query, QueryTexts, Registers);
		QueryTextTableServicesForRegistrationOfReportsToPrincipal(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
		ConsignmentReportToVendorLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
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
	
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	
	Documents.CustomerCommercialInvoice.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	ConsignmentReportToVendorLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "report to the Commitee (principal) on sales".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.ConsignmentReportToVendor) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ConsignmentReportToVendor.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ConsignmentReportToVendor);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UsePurchaseCommission";
	

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
	
	Reports.StateOfSettlementsWithConsignors.AddReportCommand(ReportsCommands);
	
	Reports.GoodsReceivedByCommissionAgent.AddReportCommand(ReportsCommands);
	
	ConsignmentReportToVendorLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// The procedure fills in arrays of details that depend on the business operation of the document.
//
// Parameters:
//	CommissionFeeCalculationMethod - EnumRef.CommissionFeeCalculationMethods - Selected method for calculating remuneration
//	ArrayOfAllProps - Array - Array of all names of banking details that depend on the business operation
//	ArrayOfOperationDetails - Array - Array of names of banking details used in the selected business operation.
//
Procedure FillInNamesOfBusinessTransactionDetails(CommissionFeeCalculationMethod, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("RemunerationPercentage");
	ArrayOfAllProps.Add("CommissionAmount");
	ArrayOfAllProps.Add("VATRateOfRemuneration");
	ArrayOfAllProps.Add("AmountVATRemuneration");
	ArrayOfAllProps.Add("KeepCommissionFee");
	ArrayOfAllProps.Add("OperationService");
	ArrayOfAllProps.Add("PaymentDate");
	ArrayOfAllProps.Add("Goods.CommissionAmount");
	
	ArrayOfOperationDetails = New Array;
	If CommissionFeeCalculationMethod <> Enums.CommissionFeeCalculationMethods.NotCalculating Then
		ArrayOfOperationDetails.Add("RemunerationPercentage");
		ArrayOfOperationDetails.Add("CommissionAmount");
		ArrayOfOperationDetails.Add("VATRateOfRemuneration");
		ArrayOfOperationDetails.Add("AmountVATRemuneration");
		ArrayOfOperationDetails.Add("KeepCommissionFee");
		ArrayOfOperationDetails.Add("OperationService");
		ArrayOfOperationDetails.Add("PaymentDate");
		ArrayOfOperationDetails.Add("Goods.CommissionAmount");
	EndIf;
	
EndProcedure

// This function defines the document details.
//
// Parameters:
//  DocumentRef - DocumentRef.ConsignmentReportToVendor - link to the document.
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
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|
	|	CASE WHEN DocumentData.KeepCommissionFee THEN
	|		DocumentData.DocumentAmount - DocumentData.CommissionAmount
	|	ELSE
	|		DocumentData.DocumentAmount
	|	END AS AmountARAP,
	|	DocumentData.CommissionAmount AS CommissionAmount,
	|
	|	DocumentData.Posted AS Posted,
	|	DocumentData.BeginOfPeriod AS BeginOfPeriod,
	|	DocumentData.EndOfPeriod AS EndOfPeriod
	|FROM
	|	Document.ConsignmentReportToVendor AS DocumentData
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
		DocumentAmount = Selection.DocumentAmount;
		AmountARAP = ?(Selection.Posted, Selection.AmountARAP, 0);
		CommissionAmount = Selection.CommissionAmount;
		BeginOfPeriod = Selection.BeginOfPeriod;
		EndOfPeriod = Selection.EndOfPeriod;
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		Partner = Catalogs.Partners.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		DocumentAmount = 0;
		AmountARAP = 0;
		CommissionAmount = 0;
		BeginOfPeriod = Undefined;
		EndOfPeriod = Undefined;
	EndIf;
	
	AttributesStructure1 = New Structure();
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("Contract", Contract);
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", Enums.BusinessTransactions.ConsignmentReportToVendor);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP); 
	AttributesStructure1.Insert("CommissionAmount", CommissionAmount);
	AttributesStructure1.Insert("BeginOfPeriod", BeginOfPeriod);
	AttributesStructure1.Insert("EndOfPeriod", EndOfPeriod);
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	
	Return AttributesStructure1;

EndFunction

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return ConsignmentReportToVendorLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return ConsignmentReportToVendorLocalization.RequestTextTTReflectedInLocalAccounting();

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
	|	AND ValueAllowed(Department)";

EndProcedure

// End StandardSubsystems.AccessManagement

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters - Array of parameters of the functions of the settlement mechanism.
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"KeepCommissionFee,
			|CommissionFeeCalculationMethod");
		KeepCommissionFee = StructureFillingData.KeepCommissionFee;
		RemunerationCalculation   = StructureFillingData.CommissionFeeCalculationMethod <> Enums.CommissionFeeCalculationMethods.NotCalculating;
	ElsIf FillingData = Undefined Then
		KeepCommissionFee = False;
		RemunerationCalculation   = False;
	Else
		KeepCommissionFee = FillingData.KeepCommissionFee;
		RemunerationCalculation   = FillingData.CommissionFeeCalculationMethod <> Enums.CommissionFeeCalculationMethods.NotCalculating;
	EndIf;
	
	InfluencingAttributes = "KeepCommissionFee,CommissionFeeCalculationMethod";
	
	StructuresArray = New Array;
	
	#Region CommitteeReport
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
		
	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetailsWithVendor";
	ParametersStructure.DocumentAmount                   = "Object.DocumentAmount";
	
	ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "";
	ParametersStructure.IncomingDocumentDate           = "";
	
	ParametersStructure.FormItems.InscriptionStages       = "DecorationPaymentSteps";
	ParametersStructure.FormItems.PaymentSettlement        = "PaymentSettlement";
	ParametersStructure.FormItems.FinancialAccountingGroup  = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	//Function Payment stages and payment date
	ParametersStructure.PathToTSDataPaymentSteps         = "Object.PaymentScheduleSteps";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStepsText";
	ParametersStructure.PaymentSchedule                     = "";
	ParametersStructure.PropsNameTSAmountWithVAT          = "SalesAmount";
	ParametersStructure.NoPrepaymentControl            = True;
	
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	
	ParametersStructure.InfluencingAttributes = InfluencingAttributes;
	
	StructuresArray.Add(ParametersStructure);
	
	#EndRegion
	
	#Region Remuneration
	
	If RemunerationCalculation Then
		
		ParametersStructure = ARAPAccountingServer.MechanismParameters();
		ParametersStructure.ThisIsSalePurchase                = True;
		ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
		If GetFunctionalOption("NewOnlineARAPAccounting") Then
			ParametersStructure.ARAPObjectSettings              = Enums.ARAPObjectSettings.ByARAPDocuments;
			ParametersStructure.FinancialAccountingGroup       = "Object.Contract.FinancialAccountingGroup";
		Else
			ParametersStructure.ChangesPaymentPlan           = Not KeepCommissionFee;
		EndIf;
		ParametersStructure.ModifiesDeliveryShipmentPlan     = Not KeepCommissionFee;
		
		ParametersStructure.PathToTSData                    = "Object.Goods";
		ParametersStructure.PropsNameTSAmountWithVAT          = "CommissionAmount";
		ParametersStructure.DocumentAmount                   = "Object.CommissionAmount";
		ParametersStructure.PaymentDate                      = "Object.PaymentDate";
		
		ParametersStructure.CourseNumerator                    = "";
		ParametersStructure.CourseDenominator                  = "";
		
		ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetailsWithCustomer";
		
		ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
		ParametersStructure.CounterpartyBankAccount        = "";
		ParametersStructure.Manager                         = "Object.Manager";
		ParametersStructure.IncomingDocumentNumber          = "";
		ParametersStructure.IncomingDocumentDate           = "";
		
		ParametersStructure.FormItems.PaymentSettlement        = "PaymentOffsetByRemuneration";
		
		ParametersStructure.ARAPObject                   = "Object.ARAPObjectRemuneration";
		
		ParametersStructure.KeepCommissionFee           = KeepCommissionFee;
		
		ParametersStructure.InfluencingAttributes = InfluencingAttributes;
		
		StructuresArray.Add(ParametersStructure);
		
	EndIf;
	
	#EndRegion
	
	Return StructuresArray;
	
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

#Region VATAccounting

// Returns the structure of parameters for filling in the purchase VAT tax.
//
// Parameters:
//  Object - DocumentObject.ConsignmentReportToVendor - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export

	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	
	FillParameters.Counterparty = Object.Counterparty;
	FillParameters.Contract = Object.Contract;
	FillParameters.ConsignmentProcurement = True; 
	FillParameters.Period  = Object.Date;
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for registering invoices (issued)
//
// Parameters:
//  Object		- DocumentObject.ConsignmentReportToVendor, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued
//
Function ParametersForRegisteringInvoicesIssued(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	
	RegistrationParameters.Ref					= Object.Ref;
	RegistrationParameters.Date					= Object.Date;
	RegistrationParameters.Organization			= Object.Organization;
	RegistrationParameters.Counterparty				= Object.Counterparty;
	RegistrationParameters.VATTaxation		= Object.VATTaxation;
	
	RegistrationParameters.GoodsSales	= (Not Object.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.NotCalculating);
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

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

// Creates a representation of the metadata object in the main language.
// 
// Returns:
//  String - Presentation of a metadata object in the main language
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	SynonymForInformationDatabaseEntry = NStr(
		"vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
		|ru = 'Отчет комитенту';
		|en = 'Consignment notification'; fa = 'اعلان امانی';
		|it = 'Report al committente';
		|pl = 'Raport dla komitenta';
		|tr = 'Konsinye bildirimi'",
		DefaultLanguageCode);
		
	Return SynonymForInformationDatabaseEntry;
	
EndFunction

#EndRegion

#Region Internal

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName = EmptyRef().Metadata().FullName();
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	
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
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
			RedefiningParameterCalculation);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Date                                         AS Period,
	|	DocumentData.Number                                        AS Number,
	|	DocumentData.Ref                                       AS Ref,
	|	DocumentData.Currency                                       AS Currency,
	|	DocumentData.Organization                                  AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency   AS LocalAccountingCurrency,
	|	DocumentData.Partner                                      AS Partner,
	|	DocumentData.Counterparty                                   AS Counterparty,
	|	DocumentData.OperationService                                       AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.Warehouses.EmptyRef)                     AS Warehouse,
	|	VALUE(Catalog.ItemsBatches.EmptyRef)          AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef)                 AS Purpose,
	|	DocumentData.Contract                                      AS Contract,
	|	DocumentData.Manager                                     AS Manager,
	|	DocumentData.Author                                        AS Author,
	|	CASE WHEN DocumentData.EndOfPeriod = DATETIME(1, 1, 1)
	|	THEN
	|		DocumentData.Date
	|	ELSE
	|		DocumentData.EndOfPeriod
	|	END                                                        AS EndOfPeriod,
	|	DocumentData.Department                                AS Department,
	|	DocumentData.FinancialAccountingGroup                       AS FinancialAccountingGroup,
	|	DocumentData.Terms                                   AS Terms,
	|	DocumentData.LineOfBusiness                      AS LineOfBusiness,
	|	ISNULL(DocumentData.LineOfBusiness.CostAccounting, FALSE) AS AccountingForLBCosts,
	|	ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) AS AccountingForSettlementsWithSuppliersUnderLB,
	|	ISNULL(DocumentData.LineOfBusiness.IncomeAccounting, FALSE) AS AccountingForIncomeUnderLB,
	|	DocumentData.KeepCommissionFee                       AS KeepCommissionFee,
	|	DocumentData.PaymentDate                                  AS PaymentDate,
	|	DocumentData.Comment                                  AS Comment,
	|	DocumentData.DocumentAmount                               AS DocumentAmount,
	|	DocumentData.Posted                                     AS Posted,
	|	DocumentData.DeletionMark                              AS DeletionMark,
	|	DocumentData.ARAPObject                               AS ARAPObject,
	|	DocumentData.ARAPObject.UUID       AS IDARAPObject,
	|	UNDEFINED AS AdjustmentPeriod_
	|FROM
	|	Document.ConsignmentReportToVendor AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("EndOfPeriod",                      EndOfDay(Attributes.EndOfPeriod));
	Query.SetParameter("ARAPCurrency",              Attributes.Currency);
	Query.SetParameter("BusinessOperation",             Enums.BusinessTransactions.ConsignmentReportToVendor);
	Query.SetParameter("BusinessTransactionSetting",    Catalogs.BusinessTransactionsSettings.ConsignmentReportToVendor);
	Query.SetParameter("BusinessOperationRetention",    Enums.BusinessTransactions.RemunerationDeductionByConsignor);
	Query.SetParameter("ManagementAccountingCurrency",        Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", 
	                                                               GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("UseAgentServiceSale", GetFunctionalOption("UseAgentServiceSale"));
	Query.SetParameter("PaymentDateClient",                 Attributes.PaymentDate);
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("NewOnlineARAPAccounting", GetFunctionalOption("NewOnlineARAPAccounting"));

	Query.SetParameter("Ref", DocumentRef);
	Query.Text = "
	|SELECT
	|	MAX(StageData_1.PaymentDate) AS PaymentDate
	|FROM
	|	Document.ConsignmentReportToVendor.PaymentScheduleSteps AS StageData_1
	|WHERE
	|	StageData_1.Ref = &Ref
	|";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("PaymentDateSupplier", Attributes.PaymentDate);

EndProcedure

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	AnalyticsRequest = New Query;
	AnalyticsRequest.Text = 
	"SELECT DISTINCT
	|	Services.Products                                                  AS Products,
	|	Services.Characteristic                                                AS Characteristic,
	|	VALUE(Catalog.Assignments.EmptyRef)                         AS Purpose,
	|	&Series                                                               AS Series,
	|	ISNULL(Services.Characteristic.Principal, Services.Products.Principal) AS Warehouse
	|FROM
	|	Document.ConsignmentReportToVendor.Goods AS Services
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON Services.Products = Dimension.Products
	|		AND Services.Characteristic = Dimension.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = Dimension.Purpose
	|		AND &Series = Dimension.Series
	|		AND ISNULL(Services.Characteristic.Principal, Services.Products.Principal) = Dimension.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	Services.Ref = &Ref
	|	AND ISNULL(Services.Characteristic.Principal, Services.Products.Principal) <> UNDEFINED
	|	AND ISNULL(Services.Characteristic.Principal, Services.Products.Principal) <> &Organization
	|	AND Dimension.DimensionKey IS NULL
	|	AND Services.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)";
	
	AnalyticsRequest.SetParameter("Ref",      Query.Parameters.Ref);
	AnalyticsRequest.SetParameter("Series",       Catalogs.ItemsBatches.EmptyRef());
	AnalyticsRequest.SetParameter("Organization", Query.Parameters.Organization);
	
	Selection = AnalyticsRequest.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Function QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	InitializeProductAccountingAnalyticsKeys(Query);
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                    AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)            AS RecordType,
	|	&Period                                           AS Period,
	|	&Organization                                      AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                     AS InventoryOwnerAttribute,
	|	&Currency                                           AS Currency,
	|	TableTypesOfStocks_.ItemsLocationAttributes     AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber                       AS CCDNumber,
	|	TableTypesOfStocks_.Count                     AS Count,
	|	TableTypesOfStocks_.AmountIncludingVAT                      AS RevenueAmount,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN ISNULL(Amounts.AmountIncludingVATCompl, 0)
	|		ELSE 0
	|	END AS RevenueAmountExclVATLocal,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN ISNULL(Amounts.AmountIncludingVATMan, 0)
	|		ELSE 0
	|	END AS RevenueAmountMan,
	|	0                                                 AS QuantityToRegister,
	|	0                                                 AS QuantityForRegistrationByProductBatchID,
	|	0                                                 AS RevenueAmountToRegister,
	|	TableTypesOfStocks_.CommissionAmount            AS CommissionAmount,
	|	TableTypesOfStocks_.TaxInvoiceDate               AS TaxInvoiceDate,
	|	TableTypesOfStocks_.Customer                     AS Customer,
	|	ISNULL(DocumentsRegistry.IBDocumentNumber, """") AS TaxInvoiceNumber,
	|	&BusinessOperation                            AS BusinessOperation,
	|	&IDARAPObject                     AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RecordDebtToConsignor) AS BusinessTransactionSetting,
	|	DocumentConsignmentReportToVendor.DocumentSales            AS DocumentSales,
	|	TableTypesOfStocks_.RowID            AS RowID
	|FROM
	|	Document.ConsignmentReportToVendor.InventoryKinds AS TableTypesOfStocks_
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TableTypesOfStocks_.CustomerInvoiceIssued = DocumentsRegistry.Ref
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|		INNER JOIN Document.ConsignmentReportToVendor AS DocumentConsignmentReportToVendor
	|		ON DocumentConsignmentReportToVendor.Ref = TableTypesOfStocks_.Ref
	|
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON TableTypesOfStocks_.Ref = Amounts.Ref
	|		AND TableTypesOfStocks_.RowID = Amounts.RowID
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber                    AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)            AS RecordType,
	|	&EndOfPeriod                                     AS Period,
	|	&Organization                                      AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                     AS InventoryOwnerAttribute,
	|	&Currency                                           AS Currency,
	|	TableTypesOfStocks_.ItemsLocationAttributes     AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber                       AS CCDNumber,
	|	0                                                 AS Count,
	|	0                                                 AS RevenueAmount,
	|	0                                                 AS RevenueAmountExclVATLocal,
	|	0                                                 AS RevenueAmountMan,
	|	TableTypesOfStocks_.Count                     AS QuantityToRegister,
	|	TableTypesOfStocks_.QuantityByGBRN               AS QuantityForRegistrationByProductBatchID,
	|	TableTypesOfStocks_.AmountIncludingVAT                      AS RevenueAmountToRegister,
	|	TableTypesOfStocks_.CommissionAmount            AS CommissionAmount,
	|	TableTypesOfStocks_.TaxInvoiceDate               AS TaxInvoiceDate,
	|	TableTypesOfStocks_.Customer                     AS Customer,
	|	ISNULL(DocumentsRegistry.IBDocumentNumber, """") AS TaxInvoiceNumber,
	|	&BusinessOperation                            AS BusinessOperation,
	|	&IDARAPObject                     AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RecordDebtToConsignor) AS BusinessTransactionSetting,
	|	DocumentConsignmentReportToVendor.DocumentSales            AS DocumentSales,
	|	TableTypesOfStocks_.RowID            AS RowID
	|FROM
	|	Document.ConsignmentReportToVendor.InventoryKinds AS TableTypesOfStocks_
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TableTypesOfStocks_.CustomerInvoiceIssued = DocumentsRegistry.Ref
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|		INNER JOIN Document.ConsignmentReportToVendor AS DocumentConsignmentReportToVendor
	|		ON DocumentConsignmentReportToVendor.Ref = TableTypesOfStocks_.Ref
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Query.Parameters.Currency, 
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

Procedure SetParameterForProductAccountingAnalystRequest(Query)
	
	If Query.Parameters.Property("ItemsLocationAttributes") Then
		Return;
	EndIf;
	
	If ValueIsFilled(Query.Parameters.Products) Then
		FieldsStructure = New Structure("Products, Characteristic, Series, Warehouse, Purpose");
		FillPropertyValues(FieldsStructure, Query.Parameters);
		
		Query.SetParameter("ItemsLocationAttributes",
						InformationRegisters.ItemsLocationAttributes.AnalyticsKeyValue(FieldsStructure));
	Else
		Query.SetParameter("ItemsLocationAttributes", Undefined);
	EndIf;
	
EndProcedure

Function QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers)
	
	RegisterName = "RevenueAndCOGS";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	SetRequestParametersCurrencyCoefficients(Query);
	SetParameterForPartnerAccountingAnalyticsRequest(Query);
	SetParameterForProductAccountingAnalystRequest(Query);
	VATAccountingERP.SetParametersForVATRateRequest(Query.Parameters, Query.Parameters.Organization, Query.Parameters.Period);
	
	QueryText =
	"SELECT
	|	&Period                                       AS Period,
	|	&AccountingDimensionByPartners                    AS AccountingDimensionByPartners,
	|	CASE WHEN &AccountingForIncomeUnderLB THEN
	|		&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	UNDEFINED                                  AS SalesOrder,
	|	&ItemsLocationAttributes                   AS ItemsLocationAttributes,
	|	CASE WHEN &AccountingForLBCosts THEN
	|		&LineOfBusiness
	|	END AS ProductLineOfBusiness,
	|	DocumentData.Department                 AS Department,
	|	&AdjustmentPeriod_                          AS AdjustmentPeriod_,
	|	VALUE(Enum.InventoryTypes.OperationService)     AS InventoryType,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
	|	CASE
	|		WHEN DocumentData.VATRateOfRemuneration = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		WHEN DocumentData.VATRateOfRemuneration = &ExportVATRate
	|			THEN VALUE(Enum.VATTaxationTypes.ExportSale)
	|		ELSE
	|			VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END AS VATActivityType,
	|	CASE
	|		WHEN DocumentData.VATRateOfRemuneration = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		WHEN DocumentData.VATRateOfRemuneration = &ExportVATRate
	|			THEN VALUE(Enum.VATTaxationTypes.ExportSale)
	|		ELSE
	|			VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END AS VATTaxation,
	|
	|	&Manager AS Manager,
	|
	|	&BusinessOperation                        AS BusinessOperation,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 
	|		CAST(DocumentData.CommissionAmount 
	|			* &ConversionRateToManCurrency AS NUMBER(31,2))) AS RevenueAmount,
	|
	|	ISNULL(Amounts.AmountExcludingVATMan, 
	|		CAST((DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration)
	|			* &ConversionRateToManCurrency AS NUMBER(31,2))) AS RevenueAmountExcludingVAT,
	|
	|	ISNULL(Amounts.AmountExcludingVATCompl,
	|		CAST((DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration)
	|			* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS RevenueAmountExclVATLocal,
	|
	|	ISNULL(Amounts.AmountIncludingVATCompl,
	|		CAST(DocumentData.CommissionAmount 
	|			* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS RevenueAmountIncludingVATLocal,
	|
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	DocumentData.Contract                  AS Contract,
	|	DocumentData.Terms               AS Terms,
	|
	|	DocumentData.Currency                   AS ARAPCurrency,
	|	DocumentData.CommissionAmount      AS AmountInARAPCurrency,
	|	DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration AS AmountExcludingVATInARAPCurrency,
	|
	|	DocumentData.Currency                   AS DocumentCurrency,
	|	DocumentData.CommissionAmount      AS AmountInDocumentCurrency,
	|	DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration AS AmountExcludingVATInDocumentCurrency,
	|
	|	DocumentData.OperationService                   AS SourceOfProductFinancialAccountingGroup,
	|	DocumentData.ARAPObjectRemuneration AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	DocumentData.DocumentID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	Amounts.VATRate                        AS VATRate
	|	
	|FROM
	|	Document.ConsignmentReportToVendor AS DocumentData
	|	LEFT JOIN 
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON 
	|		DocumentData.Ref = Amounts.Ref
	|		AND Amounts.RowID = """"
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.CommissionAmount <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.RemunerationDeductionByConsignor) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	DocumentData.ARAPObjectRemuneration AS ARAPObject,
	|	&LineOfBusiness AS LineOfBusiness,
	|	
	|	&Partner AS CorPartner,
	|	&Counterparty AS CorCounterparty,
	|	&Contract AS CorContract,
	|	DocumentData.ARAPObject AS CorARAPObject,
	|	&LineOfBusiness AS CorLineOfBusiness,
	|	
	|	ISNULL(Amounts.AmountIncludingVATMan * DocumentData.CommissionAmount/DocumentData.CommissionAmount, 
	|		CAST(DocumentData.CommissionAmount 
	|			* &ConversionRateToManCurrency AS NUMBER(31,2))) AS Sum,
	|	ISNULL(Amounts.AmountExcludingVATMan * DocumentData.CommissionAmount/DocumentData.CommissionAmount, 
	|		CAST((DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration)
	|			* &ConversionRateToManCurrency AS NUMBER(31,2))) AS AmountExcludingVAT,
	|	
	|	ISNULL(Amounts.AmountIncludingVATCompl * DocumentData.CommissionAmount/DocumentData.CommissionAmount,
	|		CAST(DocumentData.CommissionAmount 
	|			* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS SumCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl * DocumentData.CommissionAmount/DocumentData.CommissionAmount,
	|		CAST((DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration)
	|			* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS LocalAmountExcludingVAT,
	|	
	|	&Currency AS Currency,
	|	DocumentData.CommissionAmount AS AmountInCurrency,
	|	DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration AS AmountExcludingVATInCurrency,
	|	
	|	&Currency AS ARAPCurrency,
	|	DocumentData.CommissionAmount AS AmountInARAPCurrency,
	|	DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration AS AmountExcludingVATInARAPCurrency,
	|	
	|	DocumentData.ARAPObjectRemuneration AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.ARAPObject AS CorSourceOfARAPFinancialAccountingGroup,
	|	DocumentData.ARAPObjectRemuneration.UUID AS FinRecordID
	|FROM
	|	Document.ConsignmentReportToVendor AS DocumentData
	|	LEFT JOIN 
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON 
	|		DocumentData.Ref = Amounts.Ref
	|		AND Amounts.RowID = """"
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.CommissionAmount <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ =
	"SELECT
	|	""Covariability"" AS DataSource,
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
	|	DocumentTable.SalesAmount - DocumentTable.AmountSalesVAT AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.AmountSalesVAT AS VATAmount,
	|	DocumentTable.SalesAmount AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|
	|FROM
	|	Document.ConsignmentReportToVendor.Goods AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OperationService),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|
	|UNION ALL
	|
	|SELECT
	|	""Covariability"" AS DataSource,
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
	|	DocumentTable.Ref.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.ConsignmentReportToVendor.InventoryKinds AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	""Remuneration"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.Currency AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	0 AS LineNumber,
	|	UNDEFINED AS RowID,
	|	DocumentTable.CommissionAmount - DocumentTable.AmountVATRemuneration AS AmountExcludingVAT,
	|	DocumentTable.VATRateOfRemuneration AS VATRate,
	|	DocumentTable.AmountVATRemuneration AS VATAmount,
	|	DocumentTable.CommissionAmount AS AmountARAP,
	|	DocumentTable.AmountVATRemuneration AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	CASE 
	|		WHEN DocumentTable.KeepCommissionFee 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObjectRemuneration AS ARAPObject,
	|	CASE 
	|		WHEN DocumentTable.KeepCommissionFee 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecalculateBasedOnARAPData
	|
	|FROM
	|	Document.ConsignmentReportToVendor AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.CommissionAmount <> 0
	|
	|";

	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function QueryTextTablePurchases(Query, QueryTexts, Registers)
	
	RegisterName = "Purchases";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	InitializeProductAccountingAnalyticsKeys(Query);
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	QueryText =
	// Record debt to the consignor 
	"SELECT
	|	&Period                                       AS Period,
	|	VALUE(Enum.BusinessTransactions.RecordDebtToConsignor) AS BusinessOperation,
	|	&Organization                                  AS Organization,
	|	&Department                                AS Department,
	|	&Manager                                     AS Manager,
	|
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Contracts.LineOfBusiness  AS ProductLineOfBusiness,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType      AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|
	|	&Partner                                      AS Partner,
	|	&Counterparty                                   AS Counterparty,
	|	CASE WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|		&LineOfBusiness 
	|	END AS CounterpartyLineOfBusiness,
	|	&Terms                                   AS Terms,
	|	&Contract                                      AS Contract,
	|	UNDEFINED                                  AS OrderDocument,
	|
	|	0                                             AS Count,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)                AS Sum,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)              AS AmountExcludingVAT,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)               AS SumCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)             AS LocalAmountExcludingVAT,
	|	0                                              AS DiscountAmount,
	|
	|	0                                              AS Cost,
	|	0                                              AS CostExcludingVAT,
	|	0                                              AS LocalCost,
	|	0                                              AS AddExpensesForGoods,
	|	0                                              AS AdditionalExpensesExcludingVAT,
	|
	|	&Currency                                        AS DocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT                   AS AmountInDocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|
	|	&Currency                                        AS ARAPCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT                   AS AmountInARAPCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInARAPCurrency,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.ItemsLocationAttributes.Products
	|	END                                          AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObject                                AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	Document.ConsignmentReportToVendor.InventoryKinds AS TableTypesOfStocks_
	|	
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON 
	|		TableTypesOfStocks_.Ref = Amounts.Ref
	|		AND TableTypesOfStocks_.RowID = Amounts.RowID
	|	
	|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|	ON Contracts.Ref = &Contract
	|	
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref"; 
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableServicesForRegistrationOfReportsToPrincipal(Query, QueryTexts, Registers)
	
	RegisterName = "ServicesForRegistrationOfReportsToPrincipal";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	InitializeProductAccountingAnalyticsKeys(Query);
	
	QueryText =
	"SELECT
	|	ToRegister.LineNumber                   AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)    AS RecordType,
	|	&Period                                   AS Period,
	|	&Organization                              AS Organization,
	|	
	|	Dimension.DimensionKey                   AS ItemsLocationAttributes,
	|	&Terms                               AS Terms,
	|	&Currency                                   AS Currency,
	|	ToRegister.Count                    AS Count,
	|	ToRegister.SalesAmount                  AS RevenueAmount,
	|	ToRegister.AmountSalesVAT               AS VATAmount,
	|	CASE
	|		WHEN ISNULL(CAST(&Terms AS Catalog.TermsOfPurchaseFromVendors).RevalueServicesForConsignmentNotification, FALSE)
	|			THEN ISNULL(Amounts.AmountIncludingVATCompl, 0)
	|		ELSE 0
	|	END AS RevenueAmountExclVATLocal,
	|	CASE
	|		WHEN ISNULL(CAST(&Terms AS Catalog.TermsOfPurchaseFromVendors).RevalueServicesForConsignmentNotification, FALSE)
	|			THEN ISNULL(Amounts.AmountIncludingVATMan, 0)
	|		ELSE 0
	|	END AS RevenueAmountMan,
	|	ToRegister.TaxInvoiceDate              AS TaxInvoiceDate,
	|	ISNULL(DocumentsRegistry.IBDocumentNumber, """") AS TaxInvoiceNumber,
	|	ToRegister.Customer                            AS Customer,
	|	
	|	&IDARAPObject                     AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RecordDebtToConsignor) AS BusinessTransactionSetting,
	|	DocumentConsignmentReportToVendor.DocumentSales            AS DocumentSales,
	|	ToRegister.RowID AS RowID
	|FROM
	|	Document.ConsignmentReportToVendor.Goods AS ToRegister
	|	
	|	INNER JOIN Document.ConsignmentReportToVendor AS DocumentConsignmentReportToVendor
	|		ON DocumentConsignmentReportToVendor.Ref = ToRegister.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|	ON
	|		ToRegister.CustomerInvoiceIssued = DocumentsRegistry.Ref
	|		AND NOT DocumentsRegistry.AdditionalRecord
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON Dimension.Products = ToRegister.Products
	|		AND Dimension.Characteristic = ToRegister.Characteristic
	|		AND Dimension.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		AND Dimension.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND Dimension.StorageLocation = ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal)
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON ToRegister.Ref = Amounts.Ref
	|		AND ToRegister.RowID = Amounts.RowID
	|WHERE
	|	ToRegister.Ref = &Ref
	|	AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) <> UNDEFINED
	|	AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) <> &Organization
	|	AND &UseAgentServiceSale
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	TextProducts_1 =
	"SELECT
	|	TableTypesOfStocks_.Ref.Date               AS Period,
	|	TableTypesOfStocks_.Ref                    AS Ref,
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor) AS BusinessOperation,
	|	TableTypesOfStocks_.Ref.Organization        AS Organization,
	|	TableTypesOfStocks_.Ref.Department      AS Department,
	|	TableTypesOfStocks_.Ref.Counterparty         AS Counterparty,
	|	TableTypesOfStocks_.Ref.Contract            AS Contract,
	|	TableTypesOfStocks_.Ref                    AS ConsignmentReportToVendor,
	|	TableTypesOfStocks_.Ref.VATTaxation AS VATTaxation,
	|	TableTypesOfStocks_.VATRate                 AS VATRate,
	|	ItemsLocationAttributes.Products      AS Products,
	|	ItemsLocationAttributes.Characteristic    AS Characteristic,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Customer                AS ConsignedGoodsCustomer,
	|	TableTypesOfStocks_.TaxInvoiceDate          AS DateOfInvoiceIssuedToBuyer,
	|	TableTypesOfStocks_.CustomerInvoiceIssued   AS InvoiceIssuedToBuyer,
	|	&ErrorCorrectionFieldInventoryTypes            AS ErrorCorrection,
	|	TableTypesOfStocks_.RowID       AS RowID
	|FROM
	|	Document.ConsignmentReportToVendor.InventoryKinds AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.Ref.Date                     AS Period,
	|	Goods.Ref                          AS Ref,
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor) AS BusinessOperation,
	|	Goods.Ref.Organization              AS Organization,
	|	Goods.Ref.Department            AS Department,
	|	Goods.Ref.Counterparty               AS Counterparty,
	|	Goods.Ref.Contract                  AS Contract,
	|	Goods.Ref                          AS ConsignmentReportToVendor,
	|	Goods.Ref.VATTaxation       AS VATTaxation,
	|	Goods.VATRate                       AS VATRate,
	|	Goods.Products                    AS Products,
	|	Goods.Characteristic                  AS Characteristic,
	|	UNDEFINED                           AS InventoryOwnerAttribute,
	|	Goods.Customer                      AS ConsignedGoodsCustomer,
	|	Goods.TaxInvoiceDate                AS DateOfInvoiceIssuedToBuyer,
	|	Goods.CustomerInvoiceIssued         AS InvoiceIssuedToBuyer,
	|	&ErrorCorrectionProductsField           AS ErrorCorrection,
	|	Goods.RowID             AS RowID
	|FROM
	|	Document.ConsignmentReportToVendor.Goods AS Goods
	|WHERE
	|	Goods.Ref IN (&Ref)
	|	AND Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|";
	ConsignmentReportToVendorLocalization.RequestTextReflectedInVATAccountingTextProducts(TextProducts_1);
	
	VATAccountingERP.ReflectReportToCommittee(Query, QueryTexts, Registers, TextProducts_1);
	
	TextReward = 
	"SELECT
	|	ConsignmentReportToVendor.Date                    AS Period,
	|	ConsignmentReportToVendor.Ref                  AS Ref,
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor) AS BusinessOperation,
	|	ConsignmentReportToVendor.Organization             AS Organization,
	|	ConsignmentReportToVendor.Department           AS Department,
	|	ConsignmentReportToVendor.Counterparty              AS Counterparty,
	|	ConsignmentReportToVendor.Contract                 AS Contract,
	|	UNDEFINED                           AS Shipper,
	|	UNDEFINED                           AS GoodsRecipient,
	|	FALSE                                   AS RetailSaleOfGoods,
	|	UNDEFINED                           AS ConsignedGoodsCustomer,
	|	FALSE                                   AS SalesViaCommissionAgent,
	|	ConsignmentReportToVendor.Ref                  AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED                           AS ImplementationAdjustmentDocument,
	|	FALSE                                   AS ErrorCorrection,
	|	FALSE                                   AS AdjustmentUnderApprovalOfParties,
	|	ConsignmentReportToVendor.ARAPObjectRemuneration AS ARAPObject,
	|	CASE WHEN VATRateOfRemuneration = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END                                  AS VATTaxation,
	|	
	|	ConsignmentReportToVendor.OperationService                  AS Products,
	|	UNDEFINED                           AS Characteristic,
	|	UNDEFINED                           AS Series,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
	|	VALUE(Catalog.Products.EmptyRef) AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	""""                                   AS Content,
	|	0                                      AS Count,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS UnitOfMeasure,
	|	0                                      AS QuantityByGBRN,
	|	0                                      AS ExciseTaxAmount,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	ConsignmentReportToVendor.VATRateOfRemuneration AS VATRate,
	|	UNDEFINED                           AS FEACNCode,
	|	UNDEFINED                           AS InventoryOwnerAttribute,
	|	1                                      AS LineNumber,
	|	""""                                     AS RowID,
	|	ConsignmentReportToVendor.DocumentID  AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	Document.ConsignmentReportToVendor AS ConsignmentReportToVendor
	|WHERE
	|	ConsignmentReportToVendor.Ref IN (&Ref)
	|	AND ConsignmentReportToVendor.CommissionAmount <> 0
	|	AND NOT (ConsignmentReportToVendor.CommissionFeeCalculationMethod = VALUE(Enum.CommissionFeeCalculationMethods.NotCalculating))
	|";
	VATAccountingERP.ReflectImplementationToClient(Query, QueryTexts, Registers, TextReward);
	
EndProcedure

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObjectRemuneration AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.ConsignmentReportToVendor AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.ConsignmentReportToVendor AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.ConsignmentReportToVendor.ARAPDetailsWithCustomer AS Table
		|		LEFT JOIN Document.ConsignmentReportToVendor AS DocumentDataHeader
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
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.ConsignmentReportToVendor.ARAPDetailsWithVendor AS Table
		|		LEFT JOIN Document.ConsignmentReportToVendor AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region ReportOnCommission
	
	TextSale = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Organization                                                      AS Organization,
		|	Table.Partner                                                          AS Partner,
		|	
		|	Table.Ref.ARAPObjectRemuneration                              AS ARAPObject,
		|	Table.PaymentDate                                                      AS PaymentDate,
		|	UNDEFINED                                                             AS SalesOrder_,
		|	FALSE                                                                     AS InvoiceForOrders,
		|	Table.CommissionAmount                                              AS AmountARAP,
		|	0                                                                        AS AmountARAPByPackage,
		|	Table.CommissionAmount                                              AS Sum,
		|	
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	CASE WHEN &NewOnlineARAPAccounting
		|		THEN VALUE(Enum.BusinessTransactions.ConsignmentNotificationCommissionFee)
		|		ELSE VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor)
		|	END                                                                    AS BusinessOperation,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	UNDEFINED                                                             AS PaymentOption,
		|	FALSE                                                                     AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument
		|FROM
		|	Document.ConsignmentReportToVendor AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND (&NewOnlineARAPAccounting OR NOT Table.KeepCommissionFee AND Table.Ref.CommissionAmount > 0)
		|	AND Table.CommissionAmount <> 0 ";
	
	TextPaymentPlanning = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Organization                                                      AS Organization,
		|	Table.Partner                                                          AS Partner,
		|	
		|	Table.Ref.ARAPObjectRemuneration                              AS ARAPObject,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	CASE WHEN &NewOnlineARAPAccounting
		|		THEN VALUE(Enum.BusinessTransactions.ConsignmentNotificationCommissionFee)
		|		ELSE VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor)
		|	END                                                                    AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                               AS PaymentMethod,
		|	
		|	Table.PaymentDate                                                      AS PaymentDate,
		|	UNDEFINED                                                             AS PaymentOption,
		|	Table.CommissionAmount                                              AS AmountDue,
		|		
		|	TRUE                                                                   AS ExcludeDuringControl,
		|	FALSE                                                                     AS InvoiceForOrders,
		|	UNDEFINED                                                             AS SalesOrder_,
		|	FALSE                                                                     AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument
		|	
		|FROM
		|	Document.ConsignmentReportToVendor AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND (&NewOnlineARAPAccounting OR NOT Table.KeepCommissionFee AND Table.Ref.CommissionAmount > 0)
		|	AND Table.CommissionAmount <> 0 ";
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.ARAPObject                                                   AS CalculationObjectSource,
		|	Table.Ref.ARAPObjectRemuneration                              AS CalculationObjectReceiver,
		|
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	Table.AmountARAP                                              AS AmountARAP,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	Table.Sum                                                            AS Sum,
		|
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)               AS BusinessOperation
		|	
		|FROM
		|	Document.ConsignmentReportToVendor.ARAPDetailsWithCustomer AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND (&NewOnlineARAPAccounting OR NOT Table.Ref.KeepCommissionFee AND Table.Ref.CommissionAmount > 0)
		|	AND Table.Ref.CommissionAmount <> 0 ";

	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, TextSale, TextPaymentPlanning, TextAdvancePaymentOffset);

	#EndRegion
	
	#Region CommissionDeduction
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		TextOfClientSObligation = 
			"SELECT
			|	Table.Ref                                                       AS Ref,
			|	Table.Organization                                                  AS Organization,
			|	Table.Partner                                                      AS Partner,
			|	
			|	Table.Currency                                                       AS ARAPCurrency,
			|	Table.ARAPObjectRemuneration                                 AS ARAPObject,
			|	
			|	Table.CommissionAmount                                          AS AmountARAP,
			|	Table.CommissionAmount                                          AS Sum,
			|	0                                                                    AS ReductionIsPaid,
			|	Table.Date                                                         AS RecorderDate,
			|	Table.Date                                                         AS DateOfCourse,
			|	Table.Number                                                        AS RecorderNumber,
			|	VALUE(Enum.BusinessTransactions.RemunerationDeductionByConsignor) AS BusinessOperation,
			|	UNDEFINED                                                         AS PaymentMethod,
			|	UNDEFINED                                                         AS CashFlowItem,
			|	UNDEFINED                                                         AS ProformaInvoice,
			|	Table.Currency                                                       AS DocumentCurrency,
			|	UNDEFINED                                                         AS LinkedDocument,
			|	Table.DocumentID                                       AS FinRecordID,
			|	VALUE(Catalog.BusinessTransactionsSettings.RemunerationDeductionByConsignor) AS BusinessTransactionSetting
			|FROM
			|	Document.ConsignmentReportToVendor AS Table
			|WHERE
			|	Table.Ref IN (&Ref)
			|	AND Table.CommissionAmount <> 0
			|	AND Table.KeepCommissionFee";
			
		TextOfObligationToSupplier = "
			|SELECT
			|	Table.Ref                                                          AS Ref,
			|	Table.Organization                                                     AS Organization,
			|	Table.Partner                                                         AS Partner,
			|	Table.Date                                                            AS RecorderDate,
			|	Table.Number                                                           AS RecorderNumber,
			|	
			|	Table.Currency                                                          AS ARAPCurrency,
			|	Table.ARAPObject                                                  AS ARAPObject,
			|	Table.CommissionAmount                                            	AS Sum,
			|	Table.CommissionAmount                                            	AS AmountARAP,
			|	0                                                                       AS ReductionIsPaid,
			|	0                                                                       AS IncreaseIsPaid,
			|
			|	VALUE(Enum.BusinessTransactions.RemunerationDeductionByConsignor) AS BusinessOperation,
			|	UNDEFINED		                                                    AS CashFlowItem,
			|	UNDEFINED                                                            AS PaymentRequest,
			|	UNDEFINED                                                            AS PaymentMethod,
			|	Table.Currency                                                          AS DocumentCurrency,
			|	Table.Date                                                            AS DateOfCourse,
			|	DATETIME(1,1,1)                                                        AS MaturityDate,
			|	UNDEFINED                                                            AS LinkedDocument,
			|	Table.DocumentID                                          AS FinRecordID,
			|	VALUE(Catalog.BusinessTransactionsSettings.RemunerationDeductionByConsignor) AS BusinessTransactionSetting
			|FROM
			|	Document.ConsignmentReportToVendor AS Table
			|WHERE
			|	Table.Ref IN (&Ref)
			|	AND Table.KeepCommissionFee
			|	AND Table.CommissionAmount <> 0";
			
		MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.OffsettingOfCounterDebt(Query, QueryTexts, Registers, TextOfClientSObligation, TextOfObligationToSupplier);
	
	Else
		
		TextPayment = 
		"SELECT
		|	Table.Ref                                                       AS Ref,
		|	Table.Organization                                                  AS Organization,
		|	Table.Partner                                                      AS Partner,
		|	
		|	Table.Currency                                                       AS ARAPCurrency,
		|	Table.ARAPObjectRemuneration                                 AS ARAPObject,
		|	
		|	-Table.CommissionAmount                                         AS AmountARAP,
		|	-Table.CommissionAmount                                         AS Sum,
		//IncreaseIsPaid
		|	0                                                                    AS IncreaseIsPaid,
		|	0                                                                    AS ReductionIsPaid,
		|	Table.Date                                                         AS RecorderDate,
		|	Table.Date                                                         AS DateOfCourse,
		|	DATETIME(1,1,1)                                                     AS MaturityDate,
		|	Table.Number                                                        AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor)          AS BusinessOperation,
		|	UNDEFINED                                                         AS PaymentMethod,
		|	UNDEFINED                                                         AS CashFlowItem,
		|	UNDEFINED                                                         AS ProformaInvoice,
		|	Table.Currency                                                       AS DocumentCurrency,
		|	UNDEFINED                                                         AS LinkedDocument,
		|	Table.ARAPObjectRemuneration.UUID         AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.ConsignmentReportToVendor)   AS BusinessTransactionSetting
		|FROM
		|	Document.ConsignmentReportToVendor AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.CommissionAmount < 0
		|	AND NOT Table.KeepCommissionFee";
		
		ARAPAccountingPostingCustomers.CarryingOutPaymentFromClient(Query, QueryTexts, Registers, TextPayment,"2");
		
	EndIf;
		
	#EndRegion
	
	#Region NotCommissionDeduction
	
	TextPurchase = "
		|SELECT
		|	Table.Ref                                                          AS Ref,
		|	Table.Ref.Organization                                              AS Organization,
		|	Table.Ref.Partner                                                  AS Partner,
		|	Table.Ref.Date                                                     AS RecorderDate,
		|	Table.Ref.Number                                                    AS RecorderNumber,
		|	
		|	Table.Ref.ARAPObject                                           AS ARAPObject,
		|	
		|	Table.PaymentDate                                                     AS PaymentDate,
		|	UNDEFINED                                                            AS PaymentOption,
		|	UNDEFINED                                                            AS PurchaseOrder_,
		|	Table.PaymentAmount                                                    AS Sum,
		|	Table.PaymentAmount                                                    AS AmountARAP,
		|	0                                                                       AS AmountARAPByPackage,
		|
		|	Table.Ref.ARAPObjectSettings                                          AS ARAPObjectSettings,
		|	FALSE                                                                    AS InvoiceForOrders,
		|	Table.Ref.Currency                                                   AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor)             AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                              AS PaymentMethod,
		|	Table.Ref.Currency                                                   AS DocumentCurrency,
		|	Table.Ref.Date                                                     AS DateOfCourse,
		|	UNDEFINED                                                            AS LinkedDocument
		|FROM
		|	Document.ConsignmentReportToVendor.PaymentScheduleSteps AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.PaymentAmount > 0
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref                                                          AS Ref,
		|	Table.Ref.Organization                                              AS Organization,
		|	Table.Ref.Partner                                                  AS Partner,
		|	Table.Ref.Date                                                     AS RecorderDate,
		|	Table.Ref.Number                                                    AS RecorderNumber,
		|	
		|	Table.Ref.ARAPObject                                           AS ARAPObject,
		|	
		|	Table.Ref.Date                                                     AS PaymentDate,
		|	UNDEFINED                                                            AS PaymentOption,
		|	UNDEFINED                                                            AS PurchaseOrder_,
		|	Table.SalesAmount                                                    AS Sum,
		|	Table.SalesAmount                                                    AS AmountARAP,
		|	0                                                                       AS AmountARAPByPackage,
		|
		|	Table.Ref.ARAPObjectSettings                                          AS ARAPObjectSettings,
		|	FALSE                                                                    AS InvoiceForOrders,
		|	Table.Ref.Currency                                                   AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor)             AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                              AS PaymentMethod,
		|	Table.Ref.Currency                                                   AS DocumentCurrency,
		|	Table.Ref.Date                                                     AS DateOfCourse,
		|	UNDEFINED                                                            AS LinkedDocument
		|FROM
		|	Document.ConsignmentReportToVendor.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.SalesAmount < 0";
	
	TextPaymentPlan_ = "
		|SELECT
		|	Table.Ref                                                          AS Ref,
		|	Table.Ref.Organization                                              AS Organization,
		|	Table.Ref.Partner                                                  AS Partner,
		|	Table.Ref.Date                                                     AS RecorderDate,
		|	Table.Ref.Number                                                    AS RecorderNumber,
		|	Table.PaymentDate                                                     AS PaymentDate,
		|	
		|	Table.Ref.ARAPObject                                           AS ARAPObject,
		|	Table.Ref.ARAPObjectSettings                                          AS ARAPObjectSettings,
		|	FALSE                                                                    AS InvoiceForOrders,
		|	FALSE                                                                    AS ExceedingOrder,
		|	UNDEFINED                                                            AS PurchaseOrder_,
		|	Table.PaymentAmount                                                    AS AmountDue,
		|	Table.Ref.Currency                                                   AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor)             AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                              AS PaymentMethod,
		|	Table.Ref.Currency                                                   AS DocumentCurrency,
		|	UNDEFINED                                                            AS PaymentOption,
		|	UNDEFINED                                                            AS LinkedDocument
		|FROM
		|	Document.ConsignmentReportToVendor.PaymentScheduleSteps AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.PaymentAmount > 0
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref                                                          AS Ref,
		|	Table.Ref.Organization                                              AS Organization,
		|	Table.Ref.Partner                                                  AS Partner,
		|	Table.Ref.Date                                                     AS RecorderDate,
		|	Table.Ref.Number                                                    AS RecorderNumber,
		|	Table.Ref.Date                                                     AS PaymentDate,
		|	
		|	Table.Ref.ARAPObject                                           AS ARAPObject,
		|	Table.Ref.ARAPObjectSettings                                          AS ARAPObjectSettings,
		|	FALSE                                                                    AS InvoiceForOrders,
		|	FALSE                                                                    AS ExceedingOrder,
		|	UNDEFINED                                                            AS PurchaseOrder_,
		|	Table.SalesAmount                                                    AS AmountDue,
		|	Table.Ref.Currency                                                   AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor)             AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                              AS PaymentMethod,
		|	Table.Ref.Currency                                                   AS DocumentCurrency,
		|	UNDEFINED                                                            AS PaymentOption,
		|	UNDEFINED                                                            AS LinkedDocument
		|FROM
		|	Document.ConsignmentReportToVendor.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.SalesAmount < 0";
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.ARAPObject                                                   AS CalculationObjectSource,
		|	Table.Ref.ARAPObject                                            AS CalculationObjectReceiver,
		|
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	Table.AmountARAP                                              AS AmountARAP,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	Table.Sum                                                            AS Sum,
		|
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)               AS BusinessOperation
		|	
		|FROM
		|	Document.ConsignmentReportToVendor.ARAPDetailsWithVendor AS Table
		|WHERE
		|	Table.Ref IN (&Ref)";
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan_, TextAdvancePaymentOffset);
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		TextPayment = "
		|SELECT
		|	Table.Ref                                                          AS Ref,
		|	Table.Organization                                                     AS Organization,
		|	Table.Partner                                                         AS Partner,
		|	Table.Date                                                            AS RecorderDate,
		|	Table.Number                                                           AS RecorderNumber,
		|	
		|	Table.Currency                                                          AS ARAPCurrency,
		|	Table.ARAPObject                                                  AS ARAPObject,
		|	Table.CommissionAmount                                            	AS Sum,
		|	Table.CommissionAmount                                            	AS AmountARAP,
		|	0                                                                       AS ReductionIsPaid,
		|	0                                                                       AS IncreaseIsPaid,
		|	0                                                                       AS SumMan,
		|	0                                                                       AS SumCompl,
		|
		|	VALUE(Enum.BusinessTransactions.RemunerationDeductionByConsignor) AS BusinessOperation,
		|	UNDEFINED		                                                    AS CashFlowItem,
		|	UNDEFINED                                                            AS PaymentRequest,
		|	UNDEFINED                                                            AS PaymentMethod,
		|	Table.Currency                                                          AS DocumentCurrency,
		|	Table.Date                                                            AS DateOfCourse,
		|	DATETIME(1,1,1)                                                        AS MaturityDate,
		|	UNDEFINED                                                            AS LinkedDocument,
		|	Table.ARAPObjectRemuneration.UUID            AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.RemunerationDeductionByConsignor) AS BusinessTransactionSetting
		|FROM
		|	Document.ConsignmentReportToVendor AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.KeepCommissionFee
		|	AND Table.CommissionAmount <> 0";
	
		MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.MakingPaymentToSupplier(Query, QueryTexts, Registers, TextPayment,"2");
		
	EndIf;
	
	#EndRegion
	
EndProcedure

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	If AccessRight("Update", Metadata.Documents.ConsignmentReportToVendor) Then
		// The act on the provision of services
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "Act";
		PrintCommand.Presentation = NStr("vi = 'Biên bản cung cấp dịch vụ (Hoa hồng ký gửi)';
										|ru = 'Акт об оказании услуг (Комиссионное вознаграждение)';
										|en = 'Certificate of rendered services (Commission)'; fa = 'Certificate of rendered services (Commission)';
										|it = 'Atto di prestazione servizi (Provvigione)';
										|pl = 'Protokół świadczenia usług (Wynagrodzenie prowizyjne)';
										|tr = 'Hizmet tutanağı (Komisyon ücreti)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.DefaultPrintForm = True;
	PrintCommand.PrintFormDescription = NStr("vi = 'Biên bản cung cấp dịch vụ';
											|ru = 'Акт об оказании услуг';
											|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
											|it = 'Atto di prestazione dei servizi';
											|pl = 'Protokół świadczenia usług';
											|tr = 'Hizmet tutanağı'");
	EndIf;

	If Not UserRightsCached.ThisIsPartner() Then
		// Report to the Committee on sales
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommissionReports";
		PrintCommand.Id = "ConsignmentReportFromCustomer";
		PrintCommand.Presentation = NStr("vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
										|ru = 'Отчет комитенту о продажах';
										|en = 'Consignment settlement notification'; fa = 'اعلامیه تسویه امانی';
										|it = 'Report al committente sulle vendite';
										|pl = 'Raport dla komitenta dot. sprzedaży';
										|tr = 'Konsinye uzlaşma bildirimi'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.DefaultPrintForm = True;
	PrintCommand.PrintFormDescription = NStr("vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
											|ru = 'Отчет комитенту о продажах';
											|en = 'Consignment settlement notification'; fa = 'اعلامیه تسویه امانی';
											|it = 'Report al committente sulle vendite';
											|pl = 'Raport dla komitenta dot. sprzedaży';
											|tr = 'Konsinye uzlaşma bildirimi'");
	EndIf;

	ConsignmentReportToVendorLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "Act") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "Act", NStr("vi = 'Biên bản cung cấp dịch vụ';
																								|ru = 'Акт об оказании услуг';
																								|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
																								|it = 'Atto di prestazione dei servizi';
																								|pl = 'Protokół świadczenia usług';
																								|tr = 'Hizmet tutanağı'"), FormPrintedFormOfActOnProvisionOfServices(ObjectsArray, PrintObjects));
	EndIf;
	
	ConsignmentReportToVendorLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function FormPrintedFormOfActOnProvisionOfServices(ObjectsArray, PrintObjects)
	
	Query = New Query("
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Number AS Number,
	|	DocumentData.Date AS Date,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.OperationService.DescriptionFull AS Service_Name,
	|	DocumentData.OperationService.Code AS Code,
	|	DocumentData.OperationService.SKU AS SKU,
	|
	|	DocumentData.CommissionAmount AS Sum,
	|	DocumentData.VATRateOfRemuneration AS VATRate,
	|	DocumentData.AmountVATRemuneration AS VATAmount
	|FROM
	|	Document.ConsignmentReportToVendor AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN (&DocumentsArray)
	|	AND DocumentData.Posted
	|
	|ORDER BY
	|	Ref
	|;
	|");
		
	Query.SetParameter("DocumentsArray", ObjectsArray);
		
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Portrait;
	SpreadsheetDocument.PrintParametersName = "PARAMETERS_PRINTING_ReportToCommittee_ActOnServices";
	
	Template = PrintManagement.PrintFormTemplate("Document.ConsignmentReportToVendor.PF_MXL_CertificateOfServices");
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	
	PrintData = Query.Execute().Select();
	FirstDocument = True;
	While PrintData.Next() Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We output the general details of the header.
		TableHeading = Template.GetArea("Header");
		
		SupplierInformation = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date);
		InformationOnRecipient = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Counterparty, PrintData.Date);
		
		SetParameter(TableHeading, "SupplierPresentation",
			PrintFormGeneration.OrganizationDescription(SupplierInformation, "FullDescr,"));
		SetParameter(TableHeading, "RecipientPresentation1",
			PrintFormGeneration.OrganizationDescription(InformationOnRecipient, "FullDescr,"));
		SetParameter(TableHeading, "TitleText",
			TMCommonUseClientServer.GenerateDocumentTitle(
				PrintData, 
				NStr("vi = 'Biên bản cung cấp dịch vụ';
					|ru = 'Акт об оказании услуг';
					|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
					|it = 'Atto di prestazione dei servizi';
					|pl = 'Protokół świadczenia usług';
					|tr = 'Hizmet tutanağı'", Common.DefaultLanguageCode())));
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TableHeading, PrintData.Ref);
		SpreadsheetDocument.Put(TableHeading);
			
		// Output the table.
		If ValueIsFilled(NameOfCodeColumn) Then
			TemplateArea = Template.GetArea("StringWithCodes");
			SetParameter(TemplateArea, "NameOfCodeColumn", PresentationOfCodesColumn);
			SetParameter(TemplateArea, "SKU", PrintData[NameOfCodeColumn]);
		Else
			TemplateArea = Template.GetArea("String");
		EndIf;
		TemplateArea.Parameters.Fill(PrintData);
		
		SpreadsheetDocument.Put(TemplateArea);	
		
		// We output the details of the basement.
		BasementArea_ = Template.GetArea("Footer");
		
		TextAboutAmountInWords = NStr("vi = 'Số tiền hoa hồng ký gửi là';
										|ru = 'Сумма комиссионного вознаграждения составила';
										|en = 'Commission equals'; fa = 'Commission equals';
										|it = 'Importo della provvigione è di';
										|pl = 'Wysokość wynagrodzenia prowizyjnego wyniosła';
										|tr = 'Komisyon miktarı şu şekildedir'", Common.DefaultLanguageCode()) + " "
			+ ?(PrintData.Sum < 0, NStr("vi = 'trừ';
										|ru = 'минус';
										|en = 'minus'; fa = 'minus';
										|it = 'meno';
										|pl = 'minus';
										|tr = 'eksi'", Common.DefaultLanguageCode()) + " ", "")
			+ ProcessingOfExchangeRatesTM.GenerateAmountInWords(PrintData.Sum, PrintData.Currency) + ","
			+ Chars.LF
			+ NStr("vi = 'Trong đó thuế GTGT (';
					|ru = 'в том числе НДС (';
					|en = 'including VAT ('; fa = 'including VAT (';
					|it = 'compreso IVA (';
					|pl = 'w tym VAT (';
					|tr = 'KDV dahil:'", Common.DefaultLanguageCode())	+ PrintData.VATRate + ") "
			+ Format(PrintData.VATAmount, "NFD=2") + " " + PrintData.Currency;
		
		SetParameter(BasementArea_, "TextAboutAmountInWords", TextAboutAmountInWords);
		
		SpreadsheetDocument.Put(BasementArea_);	
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument,
			RowNumberStart,
			PrintObjects,
			PrintData.Ref);
		
	EndDo;
		
	Return SpreadsheetDocument;

EndFunction

// Returns data for the formation of a printed form of the "Commission Report".
//
// Parameters:
//	PrintParameters - Structure
//	ObjectsArray - Array of DocumentRef.ConsignmentReportToVendor - links to documents for which you need
//																	to get data.
//
// Returns:
//	Structure - a collection of data used when printing the UPD, containing the following properties:
//		* Title - String - Report header.
//		* HeaderResults - QueryResult - general data of the document.
//		* ResultForTabularPart - QueryResult - data of the tabular part of the document.
//		* DocumentTraceabilityData - ValueTable - a table containing information about the traceability of the document, with the following columns:
//			** Ref - DocumentRef.ConsignmentReportToVendor - link to the document.
//			** ThereIsRNPT - Boolean - indicates that the document contains traceability information.
//		* TraceableComponents - ValueTable - - description of the table of information on traceable components, with the following columns:
//			** CCDNumber - CatalogRef.CCDNumbers - link to the RPT number of the kit.
//			** ProductBatchIDNumber - String - product registration number.
//			** QuantityByGBRN - Number - the standard number of components per unit of the kit.
//			** FEACNUnitOfMeasure - String - name of the unit of measurement.
//
Function GetDataForPrintedCommissionReportForm(PrintParameters, ObjectsArray) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DocumentData.Ref					AS Ref,
	|	DocumentData.Number					AS Number,
	|	DocumentData.Date					AS Date,
	|	DocumentData.Counterparty				AS Consignor,
	|	DocumentData.Organization				AS Consignee,
	|	DocumentData.Organization.Prefix		AS Prefix,
	|	DocumentData.Currency					AS Currency,
	|	DocumentData.CommissionAmount		AS CommissionAmount,
	|	""""									AS CommitteeRepresentative,
	|	DocumentData.Manager.Individual	AS RepresentativeOfCommissionAgent
	|FROM
	|	Document.ConsignmentReportToVendor AS DocumentData
	|
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
	|	NestedQuery.Ref												AS Ref,
	|	MAX(NestedQuery.LineNumber)								AS LineNumber,
	|	NestedQuery.ItemsLocationAttributes							AS ItemsLocationAttributes,
	|	NestedQuery.Products										AS Products,
	|	NestedQuery.Products.DescriptionFull						AS ProductItemName,
	|	NestedQuery.Products.Code									AS Code,
	|	NestedQuery.Products.SKU								AS SKU,
	|	NestedQuery.Products.FEACNUnitOfMeasure.Presentation	AS FEACNUnitOfMeasure,
	|	NestedQuery.Characteristic.DescriptionFull					AS Characteristic,
	|	NestedQuery.UnitOfMeasure.Presentation						AS UnitOfMeasurementName,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END																AS Package,
	|	SUM(NestedQuery.Count)									AS Count,
	|	SUM(0)															AS QuantityByGBRN,
	|	NestedQuery.Price												AS Price,
	|	SUM(NestedQuery.ConsignorAmount)								AS ConsignorAmount,
	|	NestedQuery.SellingPrice											AS SellingPrice,
	|	SUM(NestedQuery.SalesAmount)									AS SalesAmount,
	|	SUM(NestedQuery.CommissionAmount)							AS CommissionAmount,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)							AS CCDNumber,
	|	VALUE(Enum.CCDNumberTypes.EmptyRef)					AS CCDNumberType,
	|	""""																AS ProductBatchIDNumber,
	|	NestedQuery.TaxInvoiceDate									AS TaxInvoiceDate,
	|	NestedQuery.Customer											AS Customer
	|FROM
	|	(SELECT
	|		GoodsTable.Ref						AS Ref,
	|		GoodsTable.LineNumber					AS LineNumber,
	|		GoodsTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		GoodsTable.Products					AS Products,
	|		CASE
	|			WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN GoodsTable.Products.UnitOfMeasure
	|			ELSE GoodsTable.Package
	|		END										AS UnitOfMeasure,
	|		GoodsTable.Characteristic				AS Characteristic,
	|		GoodsTable.Package						AS Package,
	|		GoodsTable.NumberOfPackages			AS Count,
	|		GoodsTable.Price							AS Price,
	|		GoodsTable.AmountIncludingVAT						AS ConsignorAmount,
	|		GoodsTable.SellingPrice					AS SellingPrice,
	|		GoodsTable.SalesAmount					AS SalesAmount,
	|		GoodsTable.CommissionAmount			AS CommissionAmount,
	|		GoodsTable.TaxInvoiceDate				AS TaxInvoiceDate,
	|		GoodsTable.Customer					AS Customer
	|	FROM
	|		Document.ConsignmentReportToVendor.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref IN(&DocumentsArray)
	|		AND GoodsTable.Products.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|														VALUE(Enum.ItemsTypes.ReusablePackage),
	|														VALUE(Enum.ItemsTypes.OperationService))
	|	
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Ref,
	|	NestedQuery.ItemsLocationAttributes,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.UnitOfMeasure,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END,
	|	NestedQuery.Price,
	|	NestedQuery.SellingPrice,
	|	NestedQuery.TaxInvoiceDate,
	|	NestedQuery.Customer
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|
	|TOTALS
	|	SUM(ConsignorAmount),
	|	SUM(SalesAmount),
	|	SUM(CommissionAmount)
	|BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	Goods.Ref	AS Ref,
	|	MAX(CASE
	|		WHEN &UseTraceableImportedGoodsAccounting
	|				AND BEGINOFPERIOD(Goods.Ref.Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|				AND ISNULL(Goods.CCDNumber.CCDNumberType, UNDEFINED) IN(VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber),
	|																		VALUE(Enum.CCDNumberTypes.KitRNPT))
	|			THEN TRUE
	|		ELSE FALSE
	|	END)			AS ThereIsRNPT
	|FROM
	|	Document.ConsignmentReportToVendor.InventoryKinds AS Goods
	|
	|WHERE
	|	Goods.Ref IN(&DocumentsArray)
	|
	|GROUP BY
	|	Goods.Ref
	|
	|ORDER BY
	|	Goods.Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT DISTINCT
	|	DocumentTable.CCDNumber							AS CCDNumber,
	|	CASE
	|		WHEN Components.ProductBatchIDNumber.RegistrationNumber = """"
	|			THEN Components.ProductBatchIDNumber
	|		ELSE Components.ProductBatchIDNumber.RegistrationNumber
	|	END												AS ProductBatchIDNumber,
	|	Components.QuantityByGBRN						AS QuantityByGBRN,
	|	Components.FEACNUnitOfMeasure.Presentation	AS FEACNUnitOfMeasure
	|FROM
	|	Document.ConsignmentReportToVendor.InventoryKinds AS DocumentTable
	|		INNER JOIN Catalog.CCDNumbers.TraceableComponents AS Components
	|		ON DocumentTable.CCDNumber = Components.Ref";
	
	Query.Text = StrReplace(Query.Text,
								"&QueryTextPackagingFactor",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"NestedQuery.Package",
									"NestedQuery.Products"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Title = NStr("vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
				|ru = 'Отчет комитенту о продажах';
				|en = 'Consignment settlement notification'; fa = 'اعلامیه تسویه امانی';
				|it = 'Report al committente sulle vendite';
				|pl = 'Raport dla komitenta dot. sprzedaży';
				|tr = 'Konsinye uzlaşma bildirimi'");
	
	ResultsArray = Query.ExecuteBatch();
	
	HeaderResults					= ResultsArray[0]; // QueryResult - 
	ResultForTabularPart			= ResultsArray[1]; // QueryResult - 
	DocumentTraceabilityData	= ResultsArray[2].Unload(); // ValueTable - 
	TraceableComponents			= ResultsArray[3].Unload(); // ValueTable - 
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("Title",							Title);
	DataStructureForPrinting.Insert("HeaderResults",					HeaderResults);
	DataStructureForPrinting.Insert("ResultForTabularPart",			ResultForTabularPart);
	DataStructureForPrinting.Insert("DocumentTraceabilityData",	DocumentTraceabilityData);
	DataStructureForPrinting.Insert("TraceableComponents",		TraceableComponents);
	
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
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("ContactPerson");
	
EndProcedure

// Other

Procedure SetParameter(TemplateArea, ParameterName, ParameterValue)
	TemplateArea.Parameters.Fill(New Structure(ParameterName, ParameterValue));
EndProcedure

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

#Region Posting

#EndRegion

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
	|	UNDEFINED                            AS BusinessOperation,
	|	&Partner                                AS Partner,
	|	&Counterparty                             AS Counterparty,
	|	&Contract                                AS Contract,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	UNDEFINED                            AS StorageLocation,
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
	|	UNDEFINED                            AS More,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&Period                                 AS RecordingInAccountingDate";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf

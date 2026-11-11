
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
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("FinancialInstruments");
	DocumentMechanisms.Add("ImportAccounting");
	
	SigningOfLeaseContractLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure:
//     * Key - String - table name.
//     * Value - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.SigningOfLeaseContract") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		GenerateTTCourses(QueryTexts);
		
		QueryTextTableOtherExpenses(QueryTexts, Registers);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		
		QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts, Registers);
		QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers);
		
		QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers);
		QueryTextTableFALocation(QueryTexts, Registers);
		
		QueryTextTableFACost(QueryTexts, Registers);
		
		QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers);
		QueryTextTableLeasedAsset(QueryTexts, Registers);
		QueryTextTableTermsOfLeaseContracts(QueryTexts, Registers);
		QueryTextTableLeaseServicesPaymentSchedule(QueryTexts, Registers);
		QueryTextTableLeaseServicesAccrualSchedule(QueryTexts, Registers);
		QueryTextTableLeaseInterestAccrualSchedule(QueryTexts, Registers);
		
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(QueryTexts, Registers);
		
		QueryTextTableGoodsForRegistrationOfImportDocuments(QueryTexts, Registers);
		
		SigningOfLeaseContractLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
	EndIf;
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region VATAccounting

// Initializes the parameters for filling in the VAT activity type
//
// Parameters:
//  Object		- DocumentObject.SigningOfLeaseContract, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export
	
	ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, "LineOfBusiness,AssetHolder");
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Contract = Object.Contract;
	FillParameters.LineOfBusiness = ContractDetails_.LineOfBusiness;
	FillParameters.PurchaseOnArticles = True;
	FillParameters.LeasingPropertyOnBalanceSheet =
		(ContractDetails_.AssetHolder = Enums.LeasedAssetHolder.Leaseholder);
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for filling in VAT taxation for purchases
//
// Parameters:
//  Object		- DocumentObject.SigningOfLeaseContract, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases.
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	FillParameters.Counterparty = Object.Counterparty;
	FillParameters.Contract = Object.Contract;
	FillParameters.Period  = Object.Date;
	
	FillParameters.RentalService = True;
	
	If ValueIsFilled(Object.Contract) Then 
		FillParameters.ImportOfGoodsFromCustomsUnion = Catalogs.LeaseContract.RegistrationOfApplicationsForImportOfGoodsFromEAEUIsRequired(Object.Contract);
	EndIf;
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for checking the completion of VAT taxation for purchases
//
// Parameters:
//  Object		- DocumentObject.ReceivingLeaseServices, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  Structure - structure of parameters, See VATAccountingERP.VerificationParametersFillingInDocumentOnVATTaxationPurchases.
//
Function VerificationParametersFillingInDocumentOnVATTaxationPurchases(Object) Export
	
	FillParameters = VATAccountingERP.VerificationParametersFillingInDocumentOnVATTaxationPurchases();
	FillParameters.TabularSectionName = "FA";
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for checking the filling in of the document by type of activity VAT
//
// Parameters:
//  Object		- DocumentObject.ReceivingLeaseServices, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  Structure - structure of parameters, See VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity.
//
Function ParametersForCheckingDocumentFillingByTypeOfActivity(Object) Export
	
	FillParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	FillParameters.TabularSectionName = "FA";
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.FixedAssetsInitialRecognition2_4.AddGenerateCommand(GenerationCommands, 2);
	
	SigningOfLeaseContractLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds the command to create the document "conclusion of a lease agreement".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Order	- Number	- The order of the command.
//
// Returns:
//	- ValueTableRow: See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//	- Undefined
//
Function AddGenerateCommand(GenerationCommands, Order = 0) Export
	If AccessRight("Insert", Metadata.Documents.SigningOfLeaseContract) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.SigningOfLeaseContract.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.SigningOfLeaseContract);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.Order = Order;
		CreateBasedOnCommand.FunctionalOptions = "UseNonCurrentAssets2_4"; 
		
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
		
EndProcedure

#EndRegion

#Region Other

// Determines the cost of rental items in the tax accounting
//
// Parameters:
//  ListOfFA	 - Array - The operating systems that you want to get the cost for.
//  Organization	 - CatalogRef.Companies	 - The organization in which the OS is accepted for accounting.
//  Date		 - Date	- Date of acceptance for accounting.
//
// Returns:
//  Map of KeyAndValue - Contains:
//  	* Key - CatalogRef.Assets - FA
//  	* Value - Number - Cost.
//
Function LeaseItemsCost(ListOfFA, Organization, Date) Export

	FACost = New Map;
	For Each FixedAsset In ListOfFA Do
		FACost.Insert(FixedAsset, 0);
	EndDo;
	
	QueryText = 
	"SELECT
	|	LeasedAsset.FixedAsset AS FixedAsset,
	|	CAST(LeasedAsset.Contract AS Catalog.LeaseContract).ARAPCurrency AS ARAPCurrency,
	|	Companies.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	LeasedAsset.Cost AS Cost
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(
	|			&Date, 
	|			FixedAsset IN(&ListOfFA)
	|			AND State = VALUE(Enum.FixedAssetsStates.LeaseContractsSigned)) AS LeasedAsset
	|
	|		LEFT JOIN Catalog.Companies AS Companies
	|		ON Companies.Ref = &Organization";
	
	Query = New Query(QueryText);
	Query.SetParameter("ListOfFA", ListOfFA);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Date", EndOfDay(?(Date <> '000101010000', Date, CurrentSessionDate())));
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		ZoomRatio = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			Selection.ARAPCurrency, Selection.LocalAccountingCurrency, ?(Date <> '000101010000', Date, CurrentSessionDate()));
			
		FACost.Insert(Selection.FixedAsset, Selection.Cost * ZoomRatio);
		
	EndDo;

	Return FACost;
	
EndFunction

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
			"Contract");
		Contract = StructureFillingData.Contract;
	ElsIf FillingData = Undefined Then
		Contract = Undefined;
	Else
		Contract = FillingData.Contract;
	EndIf;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.ChangesPaymentPlan               = False;
	ParametersStructure.ModifiesDeliveryShipmentPlan     = False;

	#Region OptionalParameters
	
	//Details other than the currency and amount of the document. If it is not filled in, then the currency of the document will be taken for reading.
	ParametersStructure.ARAPCurrency             = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP              = "Object.AmountARAP";
	ParametersStructure.LineOfBusiness          = "";
	ParametersStructure.ARAPObjectSettings                  = "";
	ParametersStructure.PathToTSData                    = "Object.FA";
	ParametersStructure.Terms                       = "";
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.PaymentMethod                      = "";
	ParametersStructure.ForeignCurrencyTransaction                    = "";
	ParametersStructure.PaymentID             = "";
	ParametersStructure.Contract                          = "";
	
	//The details for the object of calculations are used in conducting.
	ParametersStructure.FinancialAccountingGroup           = "";
	ParametersStructure.Department                    = "";
	ParametersStructure.CourseNumerator                    = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                  = "Object.CourseDenominator";
	
	ParametersStructure.FormItems.LabelCurrencies = "CurrencyDecoration";
	ParametersStructure.CurrencyAndExchangeRateDocumentViewOnly = False;
	If Contract <> Undefined Then
		AssetHolder = Common.ObjectAttributeValue(Contract, "AssetHolder");
		ParametersStructure.DocumentCurrencyViewOnly = (AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Lessor"));
	EndIf;
	ParametersStructure.MutualSettlementsCurrencyViewOnly = True;
	
	#EndRegion
	
	Return ParametersStructure;
	
EndFunction

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'Hợp đồng thuê';
							|ru = 'Договор аренды';
							|en = 'Rental contract'; fa = 'قرارداد اجاره';
							|it = 'Contratto di affitto';
							|pl = 'Umowa dzierżawy';
							|tr = 'Kiralama sözleşmesi'"));
	ArrayOfNames.Add(NStr("vi = 'Hợp đồng leasing';
							|ru = 'Договор лизинга';
							|en = 'Financial lease contract'; fa = 'قرارداد اجاره مالی';
							|it = 'Contratto di leasing';
							|pl = 'Umowa leasingu';
							|tr = 'Finansal kiralama sözleşmesi'"));
	Return ArrayOfNames
EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

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

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "SigningOfLeaseContract");
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Clear();
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("Date");
	Fields.Add("Number");
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

#Region Posting

Procedure InitializeTrackingAnalyticsKeysForPartners(Query)
	
	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized_") Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentData.Organization                    AS Organization,
	|	DocumentData.Partner                        AS Partner,
	|	DocumentData.Counterparty                     AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
	|FROM
	|	Document.SigningOfLeaseContract AS DocumentData
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON DocumentData.Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND DocumentData.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|			AND DocumentData.Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = RegisterAccountingAnalyticsForPartners.Contract
	|			AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND RegisterAccountingAnalyticsForPartners.DimensionKey IS NULL";
	
	QueryAnalyst = New Query(QueryText);
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryResult = QueryAnalyst.Execute();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("PartnerAccountingAnalyticsKeysInitialized_", True);
	
EndProcedure

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	Return DataSources;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.SigningOfLeaseContract";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("AssetHolder",
		"DocumentData.Contract.AssetHolder");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		SynonymForDocumentTable = "";
		RequestHasSource = False;
		
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "LeasedAsset" Then
		
		QueryText = QueryTextTableLeasedAsset(QueryTexts, RegisterName);
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
	
	If RegisterName = "DocumentsRegistry"
		Or RegisterName = "FixedAssetsDocuments" Then
		
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

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ =
	"SELECT
	|	""FA"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
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
	|	DocumentTable.AmountAccounting AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.AmountAccounting AS AmountARAP,
	|	DocumentTable.VATAmount AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	FALSE AS RecordedInARAPAccounting,
	|	UNDEFINED AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.SigningOfLeaseContract.FA AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

Procedure GenerateTTCourses(QueryTexts) Export
	
	TableName = "TTCourses";
	
	QueryText =
	"SELECT
	|	ExRates.DateOfCourse AS DateOfCourse,
	|	ExRates.Currency AS Currency,
	|	ExRates.LocalCourse AS LocalCourse,
	|	ExRates.ManSCourse AS ManSCourse,
	|	ExRates.LocalRevaluationRatio AS LocalRevaluationRatio,
	|	ExRates.ManSRevaluationCoefficient AS ManSRevaluationCoefficient,
	|	ExRates.CourseAsOfDocumentDate AS CourseAsOfDocumentDate
	|INTO TTCourses
	|FROM
	|	&CoursesAsOfDocumentDate AS ExRates
	|
	|INDEX BY
	|	DateOfCourse,
	|	Currency,
	|	CourseAsOfDocumentDate";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure FillInInitializationParameters(Query, DocumentRef, AddlParameters)
	
	DocumentsPosting.FillInInitializationParameters(Query, DocumentRef, AddlParameters);
	
	GetDocumentData(Query);

	Query.Text =
	"SELECT
	|	DocumentData.Ref                                     AS Ref,
	|	DocumentData.Date                                       AS Period,
	|	DocumentData.Number                                      AS Number,
	|	DocumentData.Organization                                AS Organization,
	|	DocumentData.Department                              AS Department,
	|	DocumentData.Partner                                    AS Partner,
	|	DocumentData.Counterparty                                 AS Counterparty,
	|	DocumentData.Contract                                    AS Contract,
	|	DocumentData.Contract.ContractType                        AS ContractType,
	|	DocumentData.Contract.AssetHolder                   AS AssetHolder,
	|	DocumentData.Contract.LineOfBusiness            AS LineOfBusiness,
	|	ISNULL(DocumentData.Contract.RecognizeLeasedItemsInLocalAccounting, FALSE) AS RecognizeLeasedItemsInLocalAccounting,
	|	ISNULL(DocumentData.Contract.RecognizeLeasedAssetsInManagementAccounting, FALSE) AS RecognizeLeasedAssetsInManagementAccounting,
	|	DocumentData.GLAccount                                  AS GLAccount,
	|	DocumentData.FinancialAccountingGroup                     AS FinancialAccountingGroup,
	|	DocumentData.ARAPCurrency                       AS ARAPCurrency,
	|	DocumentData.AmountARAP                        AS AmountARAP,
	|	DocumentData.DocumentAmount                             AS DocumentAmount,
	|	DocumentData.Currency                                     AS Currency,
	|	DocumentData.EmployeeResponsible                              AS EmployeeResponsible,
	|	DocumentData.Comment                                AS Comment,
	|	DocumentData.Posted                                   AS Posted,
	|	DocumentData.DeletionMark                            AS DeletionMark,
	|	DocumentData.IncomingDocumentNumber                    AS IncomingDocumentNumber,
	|	DocumentData.IncomingDocumentDate                     AS IncomingDocumentDate,
	|	DocumentData.ExternalDocumentName             AS ExternalDocumentName,
	|	DocumentData.Sum                                      AS Sum,
	|	DocumentData.SecurityDepositAmount               AS SecurityDepositAmount,
	|	DocumentData.LeaseServicesAmount                         AS LeaseServicesAmount,
	|	DocumentData.AmountOfLeaseAssetsByuout                 AS AmountOfLeaseAssetsByuout,
	|	DocumentData.AmountOfVATRepurchaseOfRentalItems              AS AmountOfVATRepurchaseOfRentalItems,
	|	DocumentData.InterestAmount                             AS InterestAmount,
	|	DocumentData.AmountIncludingVAT                                  AS AmountIncludingVAT,
	|	DocumentData.VATAmount                                   AS VATAmount,
	|	DocumentData.VATRate                                  AS VATRate,
	|	ISNULL(DocumentData.VATRate.Rate1, 0)              AS ValueOfVATRate,
	|	DocumentData.TermYears                                    AS TermYears,
	|	DocumentData.TermMonths                                    AS TermMonths,
	|	DocumentData.TermDays                                   AS TermDays,
	|	DocumentData.LeaseStartDate                           AS LeaseStartDate,
	|	DocumentData.DateOfFirstPayment                         AS DateOfFirstPayment,
	|	DocumentData.DateOfFirstSecurityPayment         AS DateOfFirstSecurityPayment,
	|	DocumentData.BuyoutDate                                 AS BuyoutDate,
	|	DocumentData.InterestRate                           AS InterestRate,
	|	DocumentData.PaymentFrequency                         AS PaymentFrequency,
	|	DocumentData.AccrualFrequency                    AS AccrualFrequency,
	|	DocumentData.LeaseItemsCost                   AS LeaseItemsCost,
	|	DocumentData.PaymentForLeaseService                       AS PaymentForLeaseService,
	|	DocumentData.AccrualOfLeaseService                   AS AccrualOfLeaseService,
	|	DocumentData.ExpenseItem                             AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses                          AS DimensionOfExpenses,
	|	DocumentData.AssetsLiabilitiesExpensesDimension           AS AssetsLiabilitiesExpensesDimension,
	|	DocumentData.AssetsLiabilitiesIncomeDimension            AS AssetsLiabilitiesIncomeDimension,
	|	DocumentData.IncomeItem                              AS IncomeItem,
	|	DocumentData.DimensionOfRevenue                           AS DimensionOfRevenue,
	|	DocumentData.PurchaseForActivity                     AS PurchaseForActivity,
	|	DocumentData.DocumentID                     AS DocumentID,
	|	DocumentData.TheInterestAccrualScheduleIsEnteredManually     AS TheInterestAccrualScheduleIsEnteredManually,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.IncomeLedgerAccountsSettings                AS IncomeLedgerAccountsSettings,
	|	DocumentData.ExpenseLedgerAccountsSettings               AS ExpenseLedgerAccountsSettings,
	|	DocumentData.VATTaxation                         AS VATTaxation
	|FROM
	|	Document.SigningOfLeaseContract AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure GetDocumentData(Query)
	
	ListOfRequests = New Array;
	
	#Region DocumentDataDetails
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.SigningOfLeaseContract AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|INDEX BY
	|	Ref
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataFATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.FixedAsset AS AccountingObject
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.SigningOfLeaseContract.FA AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	ValuesOfHoldingParameters = New Structure;
	LeasedAssetAccounting.SupplementValuesOfDocumentParameters(ValuesOfHoldingParameters);

	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.SigningOfLeaseContract"));
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.SigningOfLeaseContract);
	ValuesOfHoldingParameters.Insert("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	ValuesOfHoldingParameters.Insert("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.SigningOfLeaseContract);
	
	ValuesOfHoldingParameters.Insert("BO_GenerationOfLeasedFixedAssetsCost", Enums.BusinessTransactions.GenerationOfLeasedFixedAssetsCost);
	ValuesOfHoldingParameters.Insert("SettingUpHO_FORMINGCostOfLeasedFA", Catalogs.BusinessTransactionsSettings.GenerationOfLeasedFixedAssetsCost);
	
	ValuesOfHoldingParameters.Insert("BO_LeaseLiabilitiesAdjustment", Enums.BusinessTransactions.LeaseLiabilitiesAdjustment);
	ValuesOfHoldingParameters.Insert("SettingUpHO_AdjustingLeaseObligations", Catalogs.BusinessTransactionsSettings.LeaseLiabilitiesAdjustment);
	
	ValuesOfHoldingParameters.Insert("IdApplicationForImportOfGoods", Common.MetadataObjectID("Document.ApplicationForImportationOfGoods"));
	
	ValuesOfHoldingParameters.Insert("BO_RevaluationOfLeaseARAP", Enums.BusinessTransactions.RevaluationOfLeaseARAP);
	ValuesOfHoldingParameters.Insert("SettingUpHO_RevaluationOfLeasePayments", Catalogs.BusinessTransactionsSettings.RevaluationOfLeaseARAP);
	
	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("VNAManagementIsUsed_2_4", NonCurrentAssets.VNAManagementIsUsed_2_4(Attributes.Period));
		
		ValuesOfHoldingParameters.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed",
			LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Attributes.Organization, Attributes.Period, True));
	
		ValuesOfHoldingParameters.Insert("CreatedForTransition",
			LeasedAssetAccounting.CreatedForSwitchingToFSB25_2018(Attributes.Period, Attributes.Organization));
	
		Coefficients = GetCurrencyConversionRates_(Attributes);
		
		ValuesOfHoldingParameters.Insert("ConversionRateToManCurrency", Coefficients.ConversionRateToManCurrency);
		ValuesOfHoldingParameters.Insert("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
		ValuesOfHoldingParameters.Insert("CoursesAsOfDocumentDate", Coefficients.ExRates);
		ValuesOfHoldingParameters.Insert("DocumentBorder", 
												New Boundary(New PointInTime(Attributes.Period, Attributes.Ref), 
																BoundaryType.Excluding));
		
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.Currency, Undefined, Attributes.Period, Attributes.Organization);
		ValuesOfHoldingParameters.Insert("ConversionFactorToManCurrencyAsOfDocumentDate", Coefficients.ConversionRateToManCurrency);
		ValuesOfHoldingParameters.Insert("ConversionFactorToLocalCurrencyAsOfDocumentDate", Coefficients.FactorOfConversionToCurrencyOfRegul);

		//
		ReflectServicesInLocalExpenses = 
			Not ValuesOfHoldingParameters.LeaseAccountingAccordingToFSB25_2018IsUsed
				And Not ValuesOfHoldingParameters.CreatedForTransition
				And Attributes.AssetHolder = Enums.LeasedAssetHolder.Lessor
			Or (ValuesOfHoldingParameters.LeaseAccountingAccordingToFSB25_2018IsUsed
					Or ValuesOfHoldingParameters.CreatedForTransition)
				And Not Attributes.RecognizeLeasedItemsInLocalAccounting;
		ValuesOfHoldingParameters.Insert("ReflectServicesInLocalExpenses", ReflectServicesInLocalExpenses);

		//
		ReflectServicesInManSExpenses = 
			Not ValuesOfHoldingParameters.LeaseAccountingAccordingToFSB25_2018IsUsed
				And Not ValuesOfHoldingParameters.CreatedForTransition
				And Attributes.AssetHolder = Enums.LeasedAssetHolder.Lessor
			Or (ValuesOfHoldingParameters.LeaseAccountingAccordingToFSB25_2018IsUsed
					Or ValuesOfHoldingParameters.CreatedForTransition)
				And Not Attributes.RecognizeLeasedAssetsInManagementAccounting;
		ValuesOfHoldingParameters.Insert("ReflectServicesInManSExpenses", ReflectServicesInManSExpenses);
		
		//
		AccountingParametersForRentalItems = LeasedAssetAccountingClientServer.AccountingParametersForRentalItems(
			ValuesOfHoldingParameters.LeaseAccountingAccordingToFSB25_2018IsUsed, Attributes);
		
		ValuesOfHoldingParameters.Insert("ThereIsMaAccount", AccountingParametersForRentalItems.ThereIsMaAccount);
		ValuesOfHoldingParameters.Insert("ThereIsACAccounting", AccountingParametersForRentalItems.ThereIsACAccounting);
		ValuesOfHoldingParameters.Insert("ThereIsAccountingTa", AccountingParametersForRentalItems.ThereIsAccountingTa);
		
	EndIf;
	
	SigningOfLeaseContractLocalization.SupplementValuesOfParameters(ValuesOfHoldingParameters, Attributes);
	
	Return ValuesOfHoldingParameters;
	
EndFunction

// Get currency conversion rates.
// Taking into account security payments at the rate of payment.
// 
// Parameters:
//  Attributes - Undefined, QueryResultSelection - Attributes
// 
// Returns:
//  Structure - Get Currency Conversion Rates:
// * ConversionRateToManCurrency - Number -
// * FactorOfConversionToCurrencyOfRegul - Number -
// * ExRates - ValueTable -
Function GetCurrencyConversionRates_(Attributes)
	
	// The conclusion of the lease Contract is created in the currency of mutual settlements under the Contract.
	//
	// We consider all previously made security payments in the currencies of mutual settlements, Local and Man at the exchange rate on the date of payment.
	// We consider the FA difference.SummaBU - Security payments in the currency of mutual settlements.
	// The difference is calculated at the exchange rate of Local accounting and Man accounting at the date of the document.
	// We consider the conversion coefficients from the currency of mutual settlements (the document of conclusion of the lease Contract) to the Local and Man currencies, taking into account advances.
	
	ConversionFactor = New Structure("ConversionRateToManCurrency,
											|FactorOfConversionToCurrencyOfRegul,
											|ExRates",
											1,
											1,
											Undefined);
	
	Query = New Query();
	
	QueryText = "SELECT
	|	CASE WHEN FinancialInstrumentsARAPBalance.ARAPDocument REFS Document.BankAccountIssue THEN
	|		BEGINOFPERIOD(CAST(FinancialInstrumentsARAPBalance.ARAPDocument AS Document.BankAccountIssue).Date, DAY)
	|	WHEN FinancialInstrumentsARAPBalance.ARAPDocument REFS Document.CashVoucher THEN
	|		BEGINOFPERIOD(CAST(FinancialInstrumentsARAPBalance.ARAPDocument AS Document.CashVoucher).Date, DAY)
	|	WHEN FinancialInstrumentsARAPBalance.ARAPDocument REFS Document.SourceDocument THEN
	|		BEGINOFPERIOD(CAST(FinancialInstrumentsARAPBalance.ARAPDocument AS Document.SourceDocument).Date, DAY)
	|	ELSE
	|		&DateOfFirstSecurityPayment
	|	END AS PayDate,
	|	FinancialInstrumentsARAPBalance.Currency AS PaymentCurrency
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(&DocumentBorder, Contract = &Contract
	|	AND AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)) AS
	|		FinancialInstrumentsARAPBalance
	|WHERE
	|	FinancialInstrumentsARAPBalance.SumBalance > 0
	|	OR FinancialInstrumentsARAPBalance.SumManBalance > 0
	|	OR FinancialInstrumentsARAPBalance.SumComplBalance > 0";
	
	Query.Text = QueryText;
	
	Query.SetParameter("Contract", Attributes.Contract);
	Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("LocalAccountingCurrency", Attributes.LocalAccountingCurrency);
	Query.SetParameter("CurrencyOfLease", Attributes.Currency);
	Query.SetParameter("Ref", Attributes.Ref);
	Query.SetParameter("DateOfFirstSecurityPayment", Attributes.DateOfFirstSecurityPayment);
	
	Query.SetParameter("DocumentBorder", 
								New Boundary(New PointInTime(Attributes.Period, Attributes.Ref), 
											 BoundaryType.Excluding));
	
	CurrenciesAndPaymentDates = Query.Execute().Unload();
	// We will add the document data, in case there are no payments.
	LineOfConclusionOfLeaseContract = CurrenciesAndPaymentDates.Add();
	LineOfConclusionOfLeaseContract.PayDate = BegOfDay(Attributes.Period); 
	LineOfConclusionOfLeaseContract.PaymentCurrency = Attributes.Currency;
	
	Currencies = CurrenciesAndPaymentDates.UnloadColumn("PaymentCurrency");
	Currencies.Add(Attributes.ARAPCurrency);
	Currencies.Add(Attributes.LocalAccountingCurrency);
	Currencies.Add(Constants.ManagementAccountingCurrency.Get());
	
	Query.SetParameter("ListOfCurrencies", Currencies);
	
	TextOfExchangeRates = "
	|SELECT
	|	&DateOfCourse                            AS DateOfCourse,
	|	CurrencyRatesCut.Currency        AS Currency,
	|	CurrencyRatesCut.CourseNumerator AS CourseNumerator,
	|	CurrencyRatesCut.CourseDenominator AS CourseDenominator
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&DateOfCourse, 
	|														   BaseCurrency = &LocalAccountingCurrency
	|														   AND Currency IN (&ListOfCurrencies)
	|														  ) AS CurrencyRatesCut";
	
	QueryText = "";
	
	// Courses on document dates.
	CoursesForDates = New Array;
	Counter = CurrenciesAndPaymentDates.Count();
	
	CoursesForDates.Add("(");
	For Each PaymentRow In CurrenciesAndPaymentDates Do
		QueryText = StrReplace(TextOfExchangeRates,"&DateOfCourse", Format(PaymentRow.PayDate,"DF='""DATETIME(""yyyy,MM,dd"")""';"));
		CoursesForDates.Add(QueryText);
		Counter = Counter -1;
		
		If Counter > 0 Then
			CoursesForDates.Add("UNION ALL");
		EndIf;	
	EndDo;
	CoursesForDates.Add(")");
	
	TextOfCourseSubquery = StrConcat(CoursesForDates,Chars.LF);
	
	Query.Text = 
	"SELECT DISTINCT
	|	ExchangeRates.DateOfCourse                  AS DateOfCourse,
	|	ExchangeRates.Currency                     AS Currency,
	|	ExchangeRates.CourseNumerator              AS CourseNumerator,
	|	ExchangeRates.CourseDenominator            AS CourseDenominator,
	|	ExchangeRates.DateOfCourse = &DocumentDate AS CourseAsOfDocumentDate
	|INTO ExRates
	|FROM
	|	&Subquery AS ExchangeRates
	|INDEX BY
	|	DateOfCourse,
	|	Currency,
	|	CourseAsOfDocumentDate
	|";
	
	Query.Text = StrReplace(Query.Text, "&Subquery", TextOfCourseSubquery);
	
	Query.SetParameter("DocumentDate", BegOfDay(Attributes.Period));
	
	Query.TempTablesManager = New TempTablesManager();
	Query.Execute();
	
	// Calculation of average rates.
	Query.Text = 
	"SELECT
	|	SUM(CAST(FinancialInstrumentsARAPBalance.SumBalance 
	|		* PaymentRates.CourseNumerator / PaymentRates.CourseDenominator AS NUMBER(31,2)))				AS SumCompl,
	|	SUM(CAST(FinancialInstrumentsARAPBalance.SumBalance * PaymentRates.CourseNumerator
	|		* ManCourses.CourseDenominator / (ManCourses.CourseNumerator * PaymentRates.CourseDenominator) AS NUMBER(31,2)))	AS SumMan,
	|	SUM(CAST(FinancialInstrumentsARAPBalance.SumBalance
	|		* PaymentRates.CourseNumerator * LeaseConclusionCourses.CourseDenominator 
	|		/ (LeaseConclusionCourses.CourseNumerator * PaymentRates.CourseDenominator) AS NUMBER(31,2)))	AS AmountInCurrencyOfConclusion
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(
	|			&DocumentBorder,
	|			Contract = &Contract
	|				AND AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)) AS FinancialInstrumentsARAPBalance
	|		LEFT JOIN ExRates AS PaymentRates
	|		ON FinancialInstrumentsARAPBalance.Currency = PaymentRates.Currency
	|			AND (BEGINOFPERIOD(FinancialInstrumentsARAPBalance.ARAPDocument.Date, DAY) = PaymentRates.DateOfCourse)
	|		LEFT JOIN ExRates AS ManCourses
	|		ON (BEGINOFPERIOD(FinancialInstrumentsARAPBalance.ARAPDocument.Date, DAY) = ManCourses.DateOfCourse)
	|			AND (ManCourses.Currency = &ManagementAccountingCurrency)
	|		LEFT JOIN ExRates AS LeaseConclusionCourses
	|		ON (BEGINOFPERIOD(FinancialInstrumentsARAPBalance.ARAPDocument.Date, DAY) = LeaseConclusionCourses.DateOfCourse)
	|			AND (LeaseConclusionCourses.Currency = &CurrencyOfLease)
	|HAVING
	|	SUM(FinancialInstrumentsARAPBalance.SumBalance * PaymentRates.CourseNumerator) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(SigningOfLeaseContractServiceAccrualSchedule.SecurityPaymentVATAmount) AS SecurityPaymentVATAmount
	|FROM
	|	Document.SigningOfLeaseContract.ServiceAccrualSchedule AS SigningOfLeaseContractServiceAccrualSchedule
	|WHERE
	|	SigningOfLeaseContractServiceAccrualSchedule.Ref = &Ref";
	
	Result = Query.ExecuteBatch();
	
	TotalVATOnSecurityPayments = Result[1].Unload()[0].SecurityPaymentVATAmount;

	SecurityPayments = Result[0].Unload();
	SecurityPayments.Columns.Add("AmountVATCurrencyPayment", Common.TypeDescriptionNumber(31,2));
	
	If SecurityPayments.Total("AmountInCurrencyOfConclusion") > 0 Then
		PaymentsAmounts = SecurityPayments.UnloadColumn("AmountInCurrencyOfConclusion");
		VATAmounts = TMCommonUseClientServer.DistributeProportionally(TotalVATOnSecurityPayments, PaymentsAmounts);
		
		If VATAmounts <> Undefined Then

			SecurityPayments.LoadColumn(VATAmounts, "AmountVATCurrencyPayment");
			
			For Each AdvanceLine_ In SecurityPayments Do
				If AdvanceLine_.AmountInCurrencyOfConclusion <> 0 Then
					
					AdvanceLine_.SumCompl = AdvanceLine_.SumCompl - AdvanceLine_.AmountVATCurrencyPayment
												* (AdvanceLine_.SumCompl / AdvanceLine_.AmountInCurrencyOfConclusion);
					
					AdvanceLine_.SumMan = AdvanceLine_.SumMan - AdvanceLine_.AmountVATCurrencyPayment
												* (AdvanceLine_.SumMan / AdvanceLine_.AmountInCurrencyOfConclusion);
					
					AdvanceLine_.AmountInCurrencyOfConclusion = AdvanceLine_.AmountInCurrencyOfConclusion
															- AdvanceLine_.AmountVATCurrencyPayment;
						
				EndIf;
			EndDo;

		EndIf;
		
		SecurityPayments.GroupBy(,"SumCompl,SumMan,AmountInCurrencyOfConclusion");
	EndIf;
	
	Query.SetParameter("SecurityPayments",SecurityPayments);
	
	Query.Text = 
	"SELECT
	|	T.SumCompl AS SumCompl,
	|	T.SumMan AS SumMan,
	|	T.AmountInCurrencyOfConclusion AS AmountInCurrencyOfConclusion
	|INTO SecurityPayments
	|FROM
	|	&SecurityPayments AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(CAST(SigningOfLeaseContractFA.AmountAccounting * ExRates.CourseNumerator / ExRates.CourseDenominator AS NUMBER(31,2)))	AS SumCompl,
	|	SUM(CAST(SigningOfLeaseContractFA.AmountAccounting * ExRates.CourseNumerator * ManCourses.CourseDenominator
	|		/ (ManCourses.CourseNumerator * ExRates.CourseDenominator) AS NUMBER(31,2)))					AS SumMan,
	|	SUM(SigningOfLeaseContractFA.AmountAccounting) AS AmountInCurrencyOfConclusion,
	|	CAST(MAX(CoursesOfConclusion.CourseNumerator / CoursesOfConclusion.CourseDenominator) AS NUMBER(17,6))	AS CourseOfConclusion,
	|	CAST(MAX(ManSConclusionCourses.CourseNumerator / ManSConclusionCourses.CourseDenominator) AS NUMBER(17,6))	AS ManSCourseOfConclusion
	|INTO ConclusionOfLease
	|FROM
	|	Document.SigningOfLeaseContract.FA AS SigningOfLeaseContractFA
	|		LEFT JOIN ExRates AS ExRates
	|		ON SigningOfLeaseContractFA.Ref.Currency = ExRates.Currency
	|			AND (BEGINOFPERIOD(SigningOfLeaseContractFA.Ref.Date, DAY) = ExRates.DateOfCourse)
	|		LEFT JOIN ExRates AS ManCourses
	|		ON (BEGINOFPERIOD(SigningOfLeaseContractFA.Ref.Date, DAY) = ManCourses.DateOfCourse)
	|			AND (ManCourses.Currency = &ManagementAccountingCurrency)
	|		LEFT JOIN ExRates AS CoursesOfConclusion
	|		ON (BEGINOFPERIOD(SigningOfLeaseContractFA.Ref.Date, DAY) = CoursesOfConclusion.DateOfCourse)
	|			AND (CoursesOfConclusion.Currency = &CurrencyOfLease)
	|		LEFT JOIN ExRates AS ManSConclusionCourses
	|		ON (BEGINOFPERIOD(SigningOfLeaseContractFA.Ref.Date, DAY) = ManSConclusionCourses.DateOfCourse)
	|			AND (ManSConclusionCourses.Currency = &ManagementAccountingCurrency)
	|WHERE
	|	SigningOfLeaseContractFA.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CAST((BaseOfCalculation.ACAmountWithoutLocalSecurity + BaseOfCalculation.LocalCollateralAmount) / CASE
	|		WHEN BaseOfCalculation.AmountInCurrencyOfConclusion = 0
	|			THEN 1
	|		ELSE BaseOfCalculation.AmountInCurrencyOfConclusion
	|	END AS NUMBER(17,6)) AS FactorOfConversionToCurrencyOfRegul,
	|	CAST((BaseOfCalculation.ACAmountWithoutManSCollateral + BaseOfCalculation.ManSCollateralAmount) / CASE
	|		WHEN BaseOfCalculation.AmountInCurrencyOfConclusion = 0
	|			THEN 1
	|		ELSE BaseOfCalculation.AmountInCurrencyOfConclusion
	|	END AS NUMBER(17,6)) AS ConversionRateToManCurrency
	|FROM
	|	(SELECT
	|		CAST((ConclusionOfLease.AmountInCurrencyOfConclusion - ISNULL(SecurityPayments.AmountInCurrencyOfConclusion, 0)) *
	|			ConclusionOfLease.CourseOfConclusion AS NUMBER(31,2)) AS ACAmountWithoutLocalSecurity,
	|		ISNULL(SecurityPayments.SumCompl, 0) AS LocalCollateralAmount,
	|		CAST((ConclusionOfLease.AmountInCurrencyOfConclusion - ISNULL(SecurityPayments.AmountInCurrencyOfConclusion, 0)) *
	|			ConclusionOfLease.CourseOfConclusion / ConclusionOfLease.ManSCourseOfConclusion AS NUMBER(31,2)) AS ACAmountWithoutManSCollateral,
	|		ISNULL(SecurityPayments.SumMan, 0) AS ManSCollateralAmount,
	|		ConclusionOfLease.AmountInCurrencyOfConclusion AS AmountInCurrencyOfConclusion
	|	FROM
	|		ConclusionOfLease AS ConclusionOfLease
	|		LEFT JOIN SecurityPayments AS SecurityPayments
	|		ON (TRUE)) AS BaseOfCalculation
	|";
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		ConversionFactor.ConversionRateToManCurrency  = Selection.ConversionRateToManCurrency;
		ConversionFactor.FactorOfConversionToCurrencyOfRegul = Selection.FactorOfConversionToCurrencyOfRegul;
	EndDo;
	
	// A table of courses, with a revaluation coefficient as of the document date.
	QueryText = "
	|SELECT
	|	ExRates.DateOfCourse																			AS DateOfCourse,
	|	ExRates.Currency																			AS Currency,
	|	CAST(ExRates.CourseNumerator / ExRates.CourseDenominator AS NUMBER(17,6))					AS LocalCourse,
	|	CAST(ExRates.CourseNumerator * ManSExchangeRate.CourseDenominator
	|		/ (ManSExchangeRate.CourseNumerator * ExRates.CourseDenominator) AS NUMBER(17,6))			AS ManSCourse,
	|
	|	CAST(-(LocalRevaluationRate.CourseNumerator / LocalRevaluationRate.CourseDenominator
	|	- (ExRates.CourseNumerator / ExRates.CourseDenominator)) AS NUMBER(17,6))						AS LocalRevaluationRatio,
	|
	|	CAST(-(CurrencyExchangeRateAtDateOfRevaluation.CourseNumerator * ManSRevaluationRate.CourseDenominator
	|		/ (ManSRevaluationRate.CourseNumerator * CurrencyExchangeRateAtDateOfRevaluation.CourseDenominator)
	|		- (ExRates.CourseNumerator * ManSExchangeRate.CourseDenominator)
	|		/ (ManSExchangeRate.CourseNumerator * ExRates.CourseDenominator)) AS NUMBER(17,6))			AS ManSRevaluationCoefficient,
	|
	|	ExRates.CourseAsOfDocumentDate																AS CourseAsOfDocumentDate
	|FROM
	|	ExRates AS ExRates
	|
	|		LEFT JOIN ExRates AS ManSExchangeRate
	|		ON ExRates.DateOfCourse = ManSExchangeRate.DateOfCourse
	|		AND ManSExchangeRate.Currency = &ManagementAccountingCurrency
	|
	|		LEFT JOIN ExRates AS LocalRevaluationRate
	|		ON LocalRevaluationRate.CourseAsOfDocumentDate
	|		AND ExRates.Currency = LocalRevaluationRate.Currency
	|
	|		LEFT JOIN ExRates AS ManSRevaluationRate
	|		ON ManSRevaluationRate.CourseAsOfDocumentDate
	|		AND ManSRevaluationRate.Currency = &ManagementAccountingCurrency
	|
	|		LEFT JOIN ExRates AS CurrencyExchangeRateAtDateOfRevaluation
	|		ON CurrencyExchangeRateAtDateOfRevaluation.CourseAsOfDocumentDate
	|		AND CurrencyExchangeRateAtDateOfRevaluation.Currency = ExRates.Currency
	|";
	
	Query.Text = QueryText;
	
	ExRates = Query.Execute().Unload();
	ConversionFactor.ExRates = ExRates;

	Return ConversionFactor;
EndFunction

#Region RequestTextsForConducting

Function QueryTextTableDocumentsRegistry(QueryTexts, Registers)
	
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
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Partner                                AS Partner,
	|	&Counterparty                             AS Counterparty,
	|	&Contract                                AS Contract,
	|	&Department                          AS Department,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	&Comment                            AS Comment,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&IncomingDocumentDate                 AS SourceDocumentDate,
	|	&IncomingDocumentNumber                AS SourceDocumentNumber,
	|	&ExternalDocumentName         AS SourceDocumentName,
	|	&DocumentAmount                         AS Sum,
	|	&Currency                                 AS Currency,
	|	FALSE                                    AS ReverseTransactionCorrection,
	|	UNDEFINED                            AS ReversedDocument,
	|	UNDEFINED                            AS CorrectedDocument,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0)    AS RecNo,
	|	&Ref                                 AS Ref,
	|	&Period                                 AS Date,
	|	&Organization                            AS Organization,
	|	&Department                          AS Department,
	|	&Posted                               AS Posted,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	TRUE                                  AS RecordInLocalAccounting,
	|	TRUE                                  AS RecordInManAccounting,
	|	FATable.FixedAsset              AS FixedAsset
	|FROM
	|	Document.SigningOfLeaseContract AS DocumentData
	|		LEFT JOIN Document.SigningOfLeaseContract.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                      AS Recorder,
	|	&Period                      AS Period,
	|	&Organization                 AS Organization,
	|	FATable.FixedAsset   AS FixedAsset,
	|	&FinancialAccountingGroup      AS FinancialAccountingGroup,
	|	&GLAccount                   AS GLAccount,
	|	&LineOfBusiness     AS LineOfBusiness
	|FROM
	|	Document.SigningOfLeaseContract.FA AS FATable
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &AssetHolder = VALUE(Enum.LeasedAssetHolder.Lessor)
	|	AND NOT &LeaseAccountingAccordingToFSB25_2018IsUsed
	|	AND NOT &CreatedForTransition";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFALocation(QueryTexts, Registers)
	
	RegisterName = "FALocation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                       AS Recorder,
	|	&Period                       AS Period,
	|	&Organization                  AS Organization,
	|	FATable.FixedAsset    AS FixedAsset,
	|	FATable.Department       AS FixedAssetsLocation,
	|	TRUE                        AS RecordInLocalAccounting,
	|	TRUE                        AS RecordInManAccounting
	|FROM
	|	Document.SigningOfLeaseContract.FA AS FATable
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &AssetHolder = VALUE(Enum.LeasedAssetHolder.Lessor)
	|	AND NOT &LeaseAccountingAccordingToFSB25_2018IsUsed
	|	AND NOT &CreatedForTransition";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFACost(QueryTexts, Registers)

	RegisterName = "FACost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTFixedAssets(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTLeasedFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTLocationOfFA(QueryTexts);
	
	QueryText =
	"SELECT DISTINCT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	&Organization                           AS Organization,
	|	FATable.Department                AS Department,
	|	&Counterparty                            AS Counterparty,
	|	FATable.FixedAsset             AS FixedAsset,
	|	&FinancialAccountingGroup                AS FinancialAccountingGroup,
	|	FATable.AmountAccounting                      AS SecurityDepositValue,
	|	TRUE                                 AS RecordInLocalAccounting,
	|	FALSE                                   AS RecordInManAccounting,
	|	VALUE(Enum.BusinessTransactions.SigningOfLeaseContract) AS BusinessOperation,
	|
	|	FATable.RowID          AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting
	|FROM
	|	TTFixedAssets AS FATable
	|WHERE
	|	&AssetHolder = VALUE(Enum.LeasedAssetHolder.Lessor)
	|	AND &VNAManagementIsUsed_2_4
	|	AND NOT &LeaseAccountingAccordingToFSB25_2018IsUsed
	|	AND NOT &CreatedForTransition
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VALUE(AccumulationRecordType.Expense)    AS RecordType,
	|	&Period                                   AS Period,
	|	&Organization                              AS Organization,
	|	TTLocationOfFA.FixedAssetsLocation       AS Department,
	|	&Counterparty                               AS Counterparty,
	|	FATable.FixedAsset                AS FixedAsset,
	|	TTAccountingFA.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	TTLeasedFA.Cost                AS SecurityDepositValue,
	|	TRUE                                    AS RecordInLocalAccounting,
	|	FALSE                                      AS RecordInManAccounting,
	|	VALUE(Enum.BusinessTransactions.SigningOfLeaseContract) AS BusinessOperation,
	|
	|	FATable.RowID             AS FinRecordID,
	|	&BusinessTransactionSetting           AS BusinessTransactionSetting
	|FROM
	|	Document.SigningOfLeaseContract.FA AS FATable
	|
	|		INNER JOIN TTLeasedFA AS TTLeasedFA
	|		ON TTLeasedFA.FixedAsset = FATable.FixedAsset
	|		
	|		INNER JOIN TTAccountingFA AS TTAccountingFA
	|		ON TTAccountingFA.FixedAsset = FATable.FixedAsset
	|		
	|		INNER JOIN TTLocationOfFA AS TTLocationOfFA
	|		ON TTAccountingFA.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &AssetHolder = VALUE(Enum.LeasedAssetHolder.Lessor)
	|	AND &VNAManagementIsUsed_2_4
	|	AND &CreatedForTransition";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers)
	
	RegisterName = "FinancialInstrumentsARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTrackingAnalyticsKeysForPartners(Query);

	QueryTextTableTTFixedAssets(QueryTexts);
	QueryTextTableTTInterestAmount(QueryTexts);
	QueryTextTableTTVATAmount(QueryTexts);
	QueryTextTableTTAdjustmentOfLeaseLiabilities(QueryTexts);
	
	InitializeTTAdvanceIds(Query,QueryTexts);
	QueryTextTableTTRevaluationOfAdvances(QueryTexts);
	
	ListOfMergeRequests = New Array;
	
	#Region GenerationOfLeasedFixedAssetsCost // Dr 08.04 - Cr 76.07.1
	// At the average rate.
	QueryText = 
	"SELECT
	|	&Period                                                                      AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                       AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	&Contract                                                                     AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations)            AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	&ARAPCurrency                                                        AS Currency,
	|	
	|	FATable.AmountAccounting AS Sum,
	|
	|	CASE
	|		WHEN &ReflectServicesInManSExpenses
	|			THEN 0
	|		ELSE FATable.SumOfUU_WithoutNDS_Man
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN &ReflectServicesInLocalExpenses
	|			THEN 0
	|		ELSE FATable.SumOfBU_WithoutNDS_Local
	|	END AS SumCompl,
	|	
	|	UNDEFINED                                                                 AS ScheduleType,
	|	UNDEFINED                                                                 AS DimensionItem,
	|	FATable.RowID                                                AS RowID,
	|	FATable.RowID                                                AS FinRecordID,
	|	&BO_GenerationOfLeasedFixedAssetsCost                                      AS BusinessOperation,
	|	&SettingUpHO_FORMINGCostOfLeasedFA                             AS BusinessTransactionSetting
	|FROM
	|	TTFixedAssets AS FATable
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	(NOT &ReflectServicesInManSExpenses OR NOT &ReflectServicesInLocalExpenses)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region IncreaseOfLeaseInterest // Dr 76.07.5 - Cr 76.07.1
	// At the exchange rate as of the document date.
	QueryText = 
	"SELECT
	|	&Period                                                                      AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                       AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	&Contract                                                                     AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.Interests)                         AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	&ARAPCurrency                                                        AS Currency,
	|	
	|	TTInterestAmount.Sum AS Sum,
	|
	|	CASE
	|		WHEN &ReflectServicesInManSExpenses
	|			THEN 0
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN TTInterestAmount.Sum
	|		ELSE CAST(TTInterestAmount.Sum * ExRates.ManSCourse
	|						AS NUMBER(31,2))
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN &ReflectServicesInLocalExpenses
	|			THEN 0
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN TTInterestAmount.Sum
	|		ELSE CAST(TTInterestAmount.Sum * ExRates.LocalCourse
	|						AS NUMBER(31,2))
	|	END AS SumCompl,
	|	
	|	UNDEFINED                                                                 AS ScheduleType,
	|	UNDEFINED                                                                 AS DimensionItem,
	|	UNDEFINED                                                                 AS RowID,
	|	&DocumentID                                                      AS FinRecordID,
	|	&BO_IncreaseOfLeaseInterest                                              AS BusinessOperation,
	|	&SettingUpHO_IncreaseInRentalInterest                                     AS BusinessTransactionSetting
	|FROM
	|	TTInterestAmount AS TTInterestAmount
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|
	|		LEFT JOIN TTCourses AS ExRates
	|		ON ExRates.Currency = &ARAPCurrency
	|			AND ExRates.CourseAsOfDocumentDate
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                      AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                       AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	&Contract                                                                     AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations)            AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	&ARAPCurrency                                                        AS Currency,
	|	
	|	TTInterestAmount.Sum AS Sum,
	|
	|	CASE
	|		WHEN &ReflectServicesInManSExpenses
	|			THEN 0
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN TTInterestAmount.Sum
	|		ELSE CAST(TTInterestAmount.Sum * ExRates.ManSCourse AS NUMBER(31,2))
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN &ReflectServicesInLocalExpenses
	|			THEN 0
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN TTInterestAmount.Sum
	|		ELSE CAST(TTInterestAmount.Sum * ExRates.LocalCourse AS NUMBER(31,2))
	|	END AS SumCompl,
	|	
	|	UNDEFINED                                                                 AS ScheduleType,
	|	UNDEFINED                                                                 AS DimensionItem,
	|	UNDEFINED                                                                 AS RowID,
	|	&DocumentID                                                      AS FinRecordID,
	|	&BO_IncreaseOfLeaseInterest                                              AS BusinessOperation,
	|	&SettingUpHO_IncreaseInRentalInterest                                     AS BusinessTransactionSetting
	|FROM
	|	TTInterestAmount AS TTInterestAmount
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|
	|		LEFT JOIN TTCourses AS ExRates
	|		ON ExRates.Currency = &ARAPCurrency
	|			AND ExRates.CourseAsOfDocumentDate";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region IncreaseOfVATOnLease // Dr 76.07.9 - Cr 76.07.1
	// At the exchange rate as of the document date.
	QueryText = 
	"SELECT
	|	&Period                                                                      AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                       AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	&Contract                                                                     AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.VAT)                              AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	&ARAPCurrency                                                        AS Currency,
	|	
	|	TTVATAmount.Sum AS Sum,
	|
	|	CASE
	|		WHEN &ReflectServicesInManSExpenses
	|			THEN 0
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN TTVATAmount.Sum
	|		ELSE CAST(TTVATAmount.Sum * ExRates.ManSCourse AS NUMBER(31,2))
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN &ReflectServicesInLocalExpenses
	|			THEN 0
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN TTVATAmount.Sum
	|		ELSE CAST(TTVATAmount.Sum * ExRates.LocalCourse AS NUMBER(31,2))
	|	END AS SumCompl,
	|	
	|	UNDEFINED                                                                 AS ScheduleType,
	|	UNDEFINED                                                                 AS DimensionItem,
	|	UNDEFINED                                                                 AS RowID,
	|	&DocumentID                                                      AS FinRecordID,
	|	&BO_IncreaseOfVATOnLease                                                    AS BusinessOperation,
	|	&SettingUpHO_IncreaseInRentalVAT                                           AS BusinessTransactionSetting
	|FROM
	|	TTVATAmount AS TTVATAmount
	|		
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON
	|			DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|
	|		LEFT JOIN TTCourses AS ExRates
	|		ON ExRates.Currency = &ARAPCurrency
	|			AND ExRates.CourseAsOfDocumentDate
	|
	|WHERE
	|	(NOT &ReflectServicesInManSExpenses OR NOT &ReflectServicesInLocalExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                      AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                       AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	&Contract                                                                     AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations)            AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	&ARAPCurrency                                                        AS Currency,
	|	
	|	TTVATAmount.Sum AS Sum,
	|
	|	CASE
	|		WHEN &ReflectServicesInManSExpenses
	|			THEN 0
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN TTVATAmount.Sum
	|		ELSE CAST(TTVATAmount.Sum * ExRates.ManSCourse AS NUMBER(31,2))
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN &ReflectServicesInLocalExpenses
	|			THEN 0
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN TTVATAmount.Sum
	|		ELSE CAST(TTVATAmount.Sum * ExRates.LocalCourse AS NUMBER(31,2))
	|	END AS SumCompl,
	|	
	|	UNDEFINED                                                                 AS ScheduleType,
	|	UNDEFINED                                                                 AS DimensionItem,
	|	UNDEFINED                                                                 AS RowID,
	|	&DocumentID                                                      AS FinRecordID,
	|	&BO_IncreaseOfVATOnLease                                                    AS BusinessOperation,
	|	&SettingUpHO_IncreaseInRentalVAT                                           AS BusinessTransactionSetting
	|FROM
	|	TTVATAmount AS TTVATAmount
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|
	|		LEFT JOIN TTCourses AS ExRates
	|		ON ExRates.Currency = &ARAPCurrency
	|			AND ExRates.CourseAsOfDocumentDate
	|
	|WHERE
	|	(NOT &ReflectServicesInManSExpenses OR NOT &ReflectServicesInLocalExpenses)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region LeaseLiabilitiesAdjustment // Dr 91.02 - Cr 76.07.1
	// At the exchange rate as of the document date.
	QueryText =
	"SELECT
	|	&Period                                                                      AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                       AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	&Contract                                                                     AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations)            AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	&ARAPCurrency                                                        AS Currency,
	|	
	|	TTAdjustmentOfLeaseLiabilities.Sum AS Sum,
	|
	|	CASE
	|		WHEN &ReflectServicesInManSExpenses
	|			THEN 0
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN TTAdjustmentOfLeaseLiabilities.Sum
	|		ELSE CAST(TTAdjustmentOfLeaseLiabilities.Sum * ExRates.ManSCourse AS NUMBER(31,2))
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN &ReflectServicesInLocalExpenses
	|			THEN 0
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN TTAdjustmentOfLeaseLiabilities.Sum
	|		ELSE CAST(TTAdjustmentOfLeaseLiabilities.Sum * ExRates.LocalCourse AS NUMBER(31,2))
	|	END AS SumCompl,
	|	
	|	UNDEFINED                                                                 AS ScheduleType,
	|	UNDEFINED                                                                 AS DimensionItem,
	|	UNDEFINED                                                                 AS RowID,
	|	&DocumentID                                                      AS FinRecordID,
	|	&BO_LeaseLiabilitiesAdjustment                                        AS BusinessOperation,
	|	&SettingUpHO_AdjustingLeaseObligations                               AS BusinessTransactionSetting
	|FROM
	|	TTAdjustmentOfLeaseLiabilities AS TTAdjustmentOfLeaseLiabilities
	|		
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON
	|			DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|
	|		LEFT JOIN TTCourses AS ExRates
	|		ON ExRates.Currency = &ARAPCurrency
	|			AND ExRates.CourseAsOfDocumentDate
	|
	|WHERE
	|	TTAdjustmentOfLeaseLiabilities.Sum > 0
	|	AND (NOT &ReflectServicesInManSExpenses OR NOT &ReflectServicesInLocalExpenses)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region LeaseLiabilitiesAdjustment // Dr 76.07.1 - Cr 91.01
	// At the exchange rate as of the document date.
	QueryText =
	"SELECT
	|	&Period                                                                      AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                       AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)                   AS AccountingDimensionByPartners,
	|	&Contract                                                                     AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations)            AS AmountType,
	|	UNDEFINED                                                                 AS ARAPDocument,
	|	&ARAPCurrency                                                        AS Currency,
	|	
	|	-TTAdjustmentOfLeaseLiabilities.Sum                                   AS Sum,
	|
	|	CASE
	|		WHEN &ReflectServicesInManSExpenses
	|			THEN 0
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN -TTAdjustmentOfLeaseLiabilities.Sum
	|		ELSE CAST(-TTAdjustmentOfLeaseLiabilities.Sum * ExRates.ManSCourse AS NUMBER(31,2))
	|	END                                                                        AS SumMan,
	|
	|	CASE
	|		WHEN &ReflectServicesInLocalExpenses
	|			THEN 0
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN -TTAdjustmentOfLeaseLiabilities.Sum
	|		ELSE CAST(-TTAdjustmentOfLeaseLiabilities.Sum * ExRates.LocalCourse AS NUMBER(31,2))
	|	END                                                                        AS SumCompl,
	|	
	|	UNDEFINED                                                                 AS ScheduleType,
	|	UNDEFINED                                                                 AS DimensionItem,
	|	UNDEFINED                                                                 AS RowID,
	|	&DocumentID                                                      AS FinRecordID,
	|	&BO_LeaseLiabilitiesAdjustment                                        AS BusinessOperation,
	|	&SettingUpHO_AdjustingLeaseObligations                               AS BusinessTransactionSetting
	|FROM
	|	TTAdjustmentOfLeaseLiabilities AS TTAdjustmentOfLeaseLiabilities
	|		
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON
	|			DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	
	|		LEFT JOIN TTCourses AS ExRates
	|		ON ExRates.Currency = &ARAPCurrency
	|			AND ExRates.CourseAsOfDocumentDate
	|
	|WHERE
	|	TTAdjustmentOfLeaseLiabilities.Sum < 0
	|	AND (NOT &ReflectServicesInManSExpenses OR NOT &ReflectServicesInLocalExpenses)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region  RevaluationOfAdvancesToCourseOfDocument // Dr 76.37.1 Kt76.37.3
	// By revaluation coefficients. Advance payment amount * (the rate as of the document date is the rate as of the advance payment date).
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                            AS RecordType,
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)        AS AccountingDimensionByPartners,
	|	&Contract                                                          AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations) AS AmountType,
	|	UNDEFINED                                                      AS ARAPDocument,
	|	&ARAPCurrency                                             AS Currency,
	|	0                                                                 AS Sum,
	|	TTRevaluationOfAdvances.AmountOfRevaluationOfMan                            AS SumMan,
	|	TTRevaluationOfAdvances.AmountOfLocalRevaluation                           AS SumCompl,
	|	UNDEFINED                                                      AS ScheduleType,
	|	UNDEFINED                                                      AS DimensionItem,
	|	UNDEFINED                                                      AS RowID,
	|	TTRevaluationOfAdvances.FinRecordID                        AS FinRecordID,
	|	&BO_RevaluationOfLeaseARAP                                    AS BusinessOperation,
	|	&SettingUpHO_RevaluationOfLeasePayments                           AS BusinessTransactionSetting
	|FROM
	|	TTRevaluationOfAdvances AS TTRevaluationOfAdvances
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|		AND DimensionByPartners.Partner = &Partner
	|		AND DimensionByPartners.Counterparty = &Counterparty
	|		AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense)                            AS RecordType,
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)        AS AccountingDimensionByPartners,
	|	&Contract                                                          AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.DepositPayment) AS AmountType,
	|	TTRevaluationOfAdvances.ARAPDocument                             AS ARAPDocument,
	|	&ARAPCurrency                                             AS Currency,
	|	0                                                                 AS Sum,
	|	TTRevaluationOfAdvances.AmountOfRevaluationOfMan                            AS SumMan,
	|	TTRevaluationOfAdvances.AmountOfLocalRevaluation                           AS SumCompl,
	|	UNDEFINED                                                      AS ScheduleType,
	|	UNDEFINED                                                      AS DimensionItem,
	|	UNDEFINED                                                      AS RowID,
	|	TTRevaluationOfAdvances.FinRecordID                        AS FinRecordID,
	|	&BO_RevaluationOfLeaseARAP                                    AS BusinessOperation,
	|	&SettingUpHO_RevaluationOfLeasePayments                           AS BusinessTransactionSetting
	|FROM
	|	TTRevaluationOfAdvances AS TTRevaluationOfAdvances
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|		AND DimensionByPartners.Partner = &Partner
	|		AND DimensionByPartners.Counterparty = &Counterparty
	|		AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers)
	
	RegisterName = "InitialFixedAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                      AS Period,
	|	FATable.FixedAsset   AS FixedAsset,
	|	&Organization                 AS Organization,
	|	&Counterparty                  AS Counterparty,
	|	&Contract                     AS Contract,
	|	FATable.Cost          AS InitialCostLocalAccounting,
	|	&Period                      AS CommissioningDateAC,
	|	&Ref                      AS CommissioningDocumentAC
	|FROM
	|	Document.SigningOfLeaseContract.FA AS FATable
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &AssetHolder = VALUE(Enum.LeasedAssetHolder.Lessor)
	|	AND NOT &LeaseAccountingAccordingToFSB25_2018IsUsed";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Function QueryTextTableLeasedAsset(QueryTexts, Registers)

	RegisterName = "LeasedAsset";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                          AS Period,
	|	FATable.FixedAsset       AS FixedAsset,
	|	FATable.Cost              AS Cost,
	|	FATable.FairValue  AS ParValue,
	|	&Organization                     AS Organization,
	|	&Partner                         AS Partner,
	|	&Counterparty                      AS Counterparty,
	|	&Contract                         AS Contract,
	|
	|	CASE
	|		WHEN &AssetHolder = VALUE(Enum.LeasedAssetHolder.Lessor)
	|					AND &VNAManagementIsUsed_2_4
	|					AND NOT &LeaseAccountingAccordingToFSB25_2018IsUsed
	|					AND NOT &CreatedForTransition
	|			THEN VALUE(Enum.FixedAssetsStates.InLease)
	|		ELSE VALUE(Enum.FixedAssetsStates.LeaseContractsSigned)
	|	END AS State
	|FROM
	|	Document.SigningOfLeaseContract AS DocumentData
	|		INNER JOIN Document.SigningOfLeaseContract.FA AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|WHERE
	|	FATable.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
		
	Return QueryText;
	
EndFunction

Procedure QueryTextTableTermsOfLeaseContracts(QueryTexts, Registers)

	RegisterName = "TermsOfLeaseContracts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                                 AS Recorder,
	|	&Period                                 AS Period,
	|	&Contract                                AS Contract,
	|	&SecurityDepositAmount           AS SecurityDepositAmount,
	|	&LeaseServicesAmount                     AS LeaseServicesAmount,
	|	&AmountOfLeaseAssetsByuout             AS AmountOfLeaseAssetsByuout,
	|	&InterestAmount                         AS InterestAmount,
	|	&VATAmount                               AS VATAmount,
	|	&VATRate                              AS VATRate,
	|	&TermYears                                AS TermYears,
	|	&TermMonths                                AS TermMonths,
	|	&TermDays                               AS TermDays,
	|	&LeaseStartDate                       AS LeaseStartDate,
	|	&DateOfFirstPayment                     AS DateOfFirstPayment,
	|	&DateOfFirstSecurityPayment     AS DateOfFirstSecurityPayment,
	|	&BuyoutDate                             AS BuyoutDate,
	|	&InterestRate                       AS InterestRate,
	|	&PaymentFrequency                     AS PaymentFrequency,
	|	&AccrualFrequency                AS AccrualFrequency,
	|	&LeaseItemsCost               AS LeaseItemsCost,
	|	&PaymentForLeaseService                   AS PaymentForLeaseService,
	|	&AccrualOfLeaseService               AS AccrualOfLeaseService,
	|	&TheInterestAccrualScheduleIsEnteredManually AS TheInterestAccrualScheduleIsEnteredManually,
	|	&Ref                                 AS EffectiveContractTerms,
	|	&VATTaxation                    AS VATTaxation,
	|	VALUE(Enum.CounterpartyContractStates.Valid) AS State
	|FROM
	|	Document.SigningOfLeaseContract AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
		
EndProcedure

Function QueryTextTableLeaseServicesPaymentSchedule(QueryTexts, Registers)
	
	RegisterName = "LeaseServicesPaymentSchedule";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                                 AS ChangeDate,
	|	&Contract                                AS Contract,
	|	&Ref                                 AS EffectiveContractTerms,
	|	ChartTable.Date                     AS Date,
	|	ChartTable.RentalService           AS RentalService,
	|	ChartTable.RentalServiceVAT        AS RentalServiceVAT,
	|	ChartTable.DepositPayment    AS DepositPayment,
	|	ChartTable.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	ChartTable.BuyoutValueVAT     AS BuyoutValueVAT,
	|
	|	CASE 
	|		WHEN ChartTable.Date >= &BuyoutDate
	|			THEN ChartTable.BuyoutValue
	|		ELSE 0
	|	END AS BuyoutValue,
	|
	|	CASE 
	|		WHEN ChartTable.Date < &BuyoutDate
	|			THEN ChartTable.BuyoutValue
	|		ELSE 0
	|	END AS BuyoutValuePrepayment
	|FROM
	|	Document.SigningOfLeaseContract.ServicePaymentSchedule AS ChartTable
	|WHERE
	|	ChartTable.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLeaseServicesAccrualSchedule(QueryTexts, Registers)
	
	RegisterName = "LeaseServicesAccrualSchedule";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                                 AS ChangeDate,
	|	&Contract                                AS Contract,
	|	&Ref                                 AS EffectiveContractTerms,
	|	ChartTable.Date                     AS Date,
	|	ChartTable.RentalService           AS RentalService,
	|	ChartTable.RentalServiceVAT        AS RentalServiceVAT,
	|	ChartTable.DepositPayment    AS DepositPayment,
	|	ChartTable.SecurityPaymentVATAmount AS SecurityPaymentVATAmount,
	|	CASE 
	|		WHEN &BuyoutDate = ChartTable.Date
	|			THEN &AmountOfLeaseAssetsByuout
	|		ELSE 0
	|	END AS BuyoutValue,
	|	CASE 
	|		WHEN &BuyoutDate = ChartTable.Date
	|			THEN &AmountOfVATRepurchaseOfRentalItems
	|		ELSE 0
	|	END AS BuyoutValueVAT
	|FROM
	|	Document.SigningOfLeaseContract.ServiceAccrualSchedule AS ChartTable
	|WHERE
	|	ChartTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                 AS ChangeDate,
	|	&Contract                                AS Contract,
	|	&Ref                                 AS EffectiveContractTerms,
	|	&BuyoutDate                             AS Date,
	|	0                                       AS RentalService,
	|	0                                       AS RentalServiceVAT,
	|	0                                       AS DepositPayment,
	|	0                                       AS SecurityPaymentVATAmount,
	|	&AmountOfLeaseAssetsByuout             AS BuyoutValue,
	|	&AmountOfVATRepurchaseOfRentalItems          AS BuyoutValueVAT
	|FROM
	|	Document.SigningOfLeaseContract AS DocumentData
	|		LEFT JOIN Document.SigningOfLeaseContract.ServiceAccrualSchedule AS ChartTable
	|		ON ChartTable.Ref = DocumentData.Ref
	|			AND ChartTable.Date = DocumentData.BuyoutDate
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND ChartTable.Ref IS NULL
	|	AND &AmountOfLeaseAssetsByuout <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableLeaseInterestAccrualSchedule(QueryTexts, Registers)
	
	RegisterName = "LeaseInterestAccrualSchedule";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                        AS ChangeDate,
	|	&Contract                       AS Contract,
	|	&Ref                        AS EffectiveContractTerms,
	|	ChartTable.Date            AS Date,
	|	SUM(ChartTable.Interests) AS Interests
	|FROM
	|	Document.SigningOfLeaseContract.InterestAccrualSchedule AS ChartTable
	|WHERE
	|	ChartTable.Ref = &Ref
	|GROUP BY
	|	ChartTable.Date";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableOtherExpenses(QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses();
		
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure QueryTextTableOtherIncome(Query, QueryTexts, Registers)

	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;

	QueryTextTableTTAdjustmentOfLeaseLiabilities(QueryTexts);
	
	QueryText =
	"SELECT
	|	&Period                                        AS Period,
	|	&Organization                                   AS Organization,
	|	&Department                                 AS Department,
	|	&LineOfBusiness                       AS LineOfBusiness,
	|	&IncomeItem                                 AS IncomeItem,
	|	&DimensionOfRevenue                              AS DimensionOfRevenue,
	|	-TableRevenue.Sum                           AS Sum,
	|	-TableRevenue.SumMan                        AS SumMan,
	|	-TableRevenue.SumCompl                       AS SumCompl,
	|	0                                              AS PermanentDifference,
	|	-TableRevenue.SumCompl                       AS CostTD,
	|	&DocumentID                        AS FinRecordID,
	|	&BO_LeaseLiabilitiesAdjustment          AS BusinessOperation,
	|	&SettingUpHO_AdjustingLeaseObligations AS BusinessTransactionSetting
	|FROM
	|	TTAdjustmentOfLeaseLiabilities AS TableRevenue
	|WHERE
	|	TableRevenue.Sum < 0
	|	AND VALUETYPE(&IncomeItem) = TYPE(ChartOfCharacteristicTypes.IncomeItems)";

	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)

	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTAdjustmentOfLeaseLiabilities(QueryTexts);
	
	QueryText =
	"// Liabilities.
	|SELECT
	|	&Period                                                         AS Period,
	|	&Organization                                                    AS Organization,
	|	&Department                                                  AS Department,
	|	&LineOfBusiness                                        AS LineOfBusiness,
	|	&IncomeItem                                                  AS AssetRef,
	|	&AssetsLiabilitiesIncomeDimension                                AS Dimension,
	|	&IncomeLedgerAccountsSettings                                    AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|	-TableRevenue.SumCompl                                        AS AmountExcludingVAT,
	|	-TableRevenue.SumCompl                                        AS AmountIncludingVAT,
	|	-TableRevenue.SumCompl                                        AS SumCompl,
	|	-TableRevenue.SumMan                                         AS SumMan,
	|	0                                                               AS PermanentDifference,
	|	0                                                               AS CostTD,
	|	&SettingUpHO_AdjustingLeaseObligations                  AS BusinessTransactionSetting,
	|	&DocumentID                                         AS FinRecordID,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow)   AS SourceKind
	|FROM
	|	TTAdjustmentOfLeaseLiabilities AS TableRevenue
	|WHERE
	|	(TableRevenue.Sum < 0
	|	OR TableRevenue.SumMan < 0)
	|	AND VALUETYPE(&IncomeItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|
	|UNION ALL
	|
	|// Assets.
	|SELECT
	|	&Period                                                        AS Period,
	|	&Organization                                                   AS Organization,
	|	Rows.Department                                           AS Department,
	|	Rows.LineOfBusiness                                 AS LineOfBusiness,
	|	&ExpenseItem                                                AS AssetRef,
	|	&AssetsLiabilitiesExpensesDimension                              AS Dimension,
	|	&ExpenseLedgerAccountsSettings                                  AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|	Rows.AmountExcludingVATCompl                                         AS AmountExcludingVAT,
	|	Rows.AmountIncludingVATCompl                                           AS AmountIncludingVAT,
	|	Rows.AmountExcludingVATCompl                                         AS SumCompl,
	|	Rows.AmountExcludingVATMan                                          AS SumMan,
	|	Rows.PermanentDifference                                       AS PermanentDifference,
	|	Rows.CostTD                                        AS CostTD,
	|	Rows.BusinessTransactionSetting                          AS BusinessTransactionSetting,
	|	Rows.FinRecordID                                  AS FinRecordID,
	|	VALUE(Enum.MovementSourcesKinds.BalanceFlow)  AS SourceKind
	|FROM
	|	TTInitialOtherExpenses AS Rows
	|WHERE
	|	(Rows.AmountExcludingVATCompl <> 0
	|	OR Rows.AmountExcludingVATMan <> 0
	|	OR Rows.PermanentDifference <> 0
	|	OR Rows.CostTD <> 0)
	|	AND VALUETYPE(&ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
EndProcedure

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts, Registers)
	
	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTFixedAssets(QueryTexts);
	
	Text =
	"SELECT
	|	FATable.LineNumber,
	|	
	|	&Ref AS Recorder,
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.RecordExpensesAtExpenseOfOtherAssetsLiabilities) AS BusinessOperation,
	|	&Organization AS Organization,
	|
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceLeasing) AS AssetRef,
	|	&Contract AS AssetsLiabilitiesDimension,
	|
	|	FATable.Department AS DebitBusinessUnit,
	|	&LineOfBusiness AS CorLineOfBusiness,
	|	FATable.ExpenseItem AS CorItem,
	|	FATable.FixedAsset AS CorExpenditureDimension,
	|	
	|	FATable.SumOfUU_SNDS_Man AS Sum,
	|	FATable.SumOfUU_WithoutNDS_Man AS SumMan,
	|	FATable.SumBU_SNDS_Local AS SumCompl,
	|	
	|	&Currency AS Currency,
	|	FATable.AmountAccounting AS AmountInCurrency,
	|	UNDEFINED AS SalaryTransactionKind
	|FROM
	|	TTFixedAssets AS FATable
	|WHERE
	|	&AssetHolder = VALUE(Enum.LeasedAssetHolder.Leaseholder)
	|	OR &LeaseAccountingAccordingToFSB25_2018IsUsed
	|	OR &CreatedForTransition";
	
	QueryTexts.Add(Text, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableGoodsForRegistrationOfImportDocuments(QueryTexts, Registers)
	
	RegisterName = "GoodsForRegistrationOfImportDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf; 
	
	QueryText =
	"SELECT
	|	ENDOFPERIOD(ChartTable.Date, MONTH) AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Ref AS Recorder,
	|	&Organization AS Organization,
	|	&Partner AS Vendor,
	|	&Ref AS DocumentInflow,
	|	&IdApplicationForImportOfGoods AS ImportDocumentType,
	|	0 AS Count,
	|	0 AS QuantityByGBRN,
	|	ChartTable.RentalService + ChartTable.DepositPayment + ChartTable.BuyoutValue AS Sum,
	|	TRUE AS Primary
	|FROM
	|	Document.SigningOfLeaseContract.ServicePaymentSchedule AS ChartTable
	|		INNER JOIN Catalog.LeaseContract AS LeaseContract
	|		ON LeaseContract.Ref = &Contract
	|WHERE
	|	ChartTable.Ref = &Ref
	|	AND LeaseContract.RegisterImportApplications";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

#EndRegion

#Region FormationOfTemporaryTablesForConducting

Procedure QueryTextTableTTInitialOtherExpenses(QueryTexts)
	
		RegisterName = "TTInitialOtherExpenses";
	
	QueryTextTableTTFixedAssets(QueryTexts);
	QueryTextTableTTAdjustmentOfLeaseLiabilities(QueryTexts);
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses());
	
	QueryText = SigningOfLeaseContractLocalization.QueryTextTableTTInitialOtherExpenses();
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	&Period                                AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	
		|	&Organization                           AS Organization,
		|	FATable.Department                AS Department,
		|	FATable.ExpenseItem               AS ExpenseItem,
		|	FATable.FixedAsset             AS DimensionOfExpenses,
		|	&LineOfBusiness               AS LineOfBusiness,
		|	UNDEFINED                           AS VATActivityType,
		|	
		|	CASE
		|		WHEN NOT &ReflectServicesInManSExpenses
		|			THEN FATable.SumOfUU_WithoutNDS_Man
		|		ELSE 0
		|	END                                  AS AmountIncludingVAT,
		|
		|	CASE
		|		WHEN NOT &ReflectServicesInManSExpenses
		|			THEN FATable.SumOfUU_WithoutNDS_Man
		|		ELSE 0
		|	END                                  AS AmountExcludingVAT,
		|
		|	CASE
		|		WHEN NOT &ReflectServicesInManSExpenses
		|			THEN FATable.SumOfUU_WithoutNDS_Man
		|		ELSE 0
		|	END                                  AS AmountExcludingVATMan,
		|
		|	CASE
		|		WHEN NOT &ReflectServicesInLocalExpenses
		|			THEN FATable.SumBU_SNDS_Local
		|		ELSE 0
		|	END                                  AS AmountIncludingVATCompl,
		|
		|	CASE
		|		WHEN NOT &ReflectServicesInLocalExpenses
		|			THEN FATable.SumOfBU_WithoutNDS_Local
		|		ELSE 0
		|	END                                  AS AmountExcludingVATCompl,
		|
		|	0                                      AS PermanentDifference,
		|	0                                      AS CostTD,
		|	
		|	&BO_GenerationOfLeasedFixedAssetsCost AS BusinessOperation,
		|	UNDEFINED                           AS ItemsLocationAttributes,
		|
		|	FATable.RowID          AS FinRecordID,
		|	&SettingUpHO_FORMINGCostOfLeasedFA AS BusinessTransactionSetting
		|FROM
		|	TTFixedAssets AS FATable
		|WHERE
		|	(NOT &ReflectServicesInLocalExpenses OR NOT &ReflectServicesInManSExpenses)";
		
	EndIf;
	ListOfMergeRequests.Add(QueryText);
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Function QueryTextTableTTOtherExpenses_(QueryTexts)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure QueryTextTableTTFixedAssets(QueryTexts)
	
	TableName = "TTFixedAssets";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	// Amounts at the average exchange rate.
	Text = 
	"SELECT
	|	FATable.Ref,
	|	FATable.LineNumber,
	|	FATable.FixedAsset,
	|	FATable.RowID,
	|	FATable.Department AS Department,
	|	FATable.ExpenseItem AS ExpenseItem,
	|	FATable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost) AS DistributionOnVNA,
	|	FATable.AmountAccounting AS AmountAccounting,
	|	FATable.VATAmount AS VATAmount,
	|	FATable.VATRate AS VATRate,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN FATable.AmountAccounting + FATable.VATAmount
	|		ELSE CAST((FATable.AmountAccounting * &ConversionRateToManCurrency + 
	|			FATable.VATAmount * &ConversionFactorToManCurrencyAsOfDocumentDate)  AS NUMBER(31,2))
	|	END AS SumOfUU_SNDS_Man,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN FATable.AmountAccounting
	|		ELSE CAST(FATable.AmountAccounting * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS SumOfUU_WithoutNDS_Man,
	|	
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN FATable.AmountAccounting + FATable.VATAmount
	|		ELSE CAST((FATable.AmountAccounting * &FactorOfConversionToCurrencyOfRegul
	|			+ FATable.VATAmount * &ConversionFactorToLocalCurrencyAsOfDocumentDate) AS NUMBER(31,2))
	|	END AS SumBU_SNDS_Local,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN FATable.AmountAccounting
	|		ELSE CAST(FATable.AmountAccounting * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS SumOfBU_WithoutNDS_Local,
	|	
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN FATable.AmountFA
	|		ELSE CAST(FATable.AmountFA * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS SumNU_WithoutNDS_Local,
	|	
	|	CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN FATable.VATAmount
	|		ELSE CAST(FATable.VATAmount * &ConversionFactorToManCurrencyAsOfDocumentDate AS NUMBER(31,2))
	|	END AS SumOfNDS_Man,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN FATable.VATAmount
	|		ELSE CAST(FATable.VATAmount * &ConversionFactorToLocalCurrencyAsOfDocumentDate AS NUMBER(31,2))
	|	END AS SumOfNDS_Local
	|
	|INTO TTFixedAssets
	|FROM
	|	Document.SigningOfLeaseContract.FA AS FATable
	|	
	|WHERE
	|	FATable.Ref = &Ref";
	
	QueryTexts.Add(Text, TableName, False);
	
EndProcedure

Procedure QueryTextTableTTInterestAmount(QueryTexts)
	
	TableName = "TTInterestAmount";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	Text = 
	"SELECT
	|	SUM(InterestAccrualSchedule.Interests) AS Sum
	|INTO TTInterestAmount
	|FROM
	|	Document.SigningOfLeaseContract.InterestAccrualSchedule AS InterestAccrualSchedule
	|	
	|WHERE
	|	InterestAccrualSchedule.Ref = &Ref
	|	AND (NOT &CreatedForTransition
	|		OR InterestAccrualSchedule.Date > ENDOFPERIOD(&Period, MONTH))";
	
	QueryTexts.Add(Text, TableName);
	
EndProcedure

Procedure QueryTextTableTTVATAmount(QueryTexts)
	
	TableName = "TTVATAmount";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	Text = 
	"SELECT
	|	DocumentData.VATAmount AS Sum
	|INTO TTVATAmount
	|FROM
	|	Document.SigningOfLeaseContract AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND NOT &CreatedForTransition
	|
	|UNION ALL
	|
	|SELECT
	|	SUM(CAST(ServiceAccrualSchedule.RentalService - 100 * ServiceAccrualSchedule.RentalService / (100 + &ValueOfVATRate) AS NUMBER(31, 2)))
	| 
	|		+ SUM(CAST(ServiceAccrualSchedule.DepositPayment - 100 * ServiceAccrualSchedule.DepositPayment / (100 + &ValueOfVATRate) AS NUMBER(31, 2)))
	| 
	|		+ CASE
	|			WHEN &BuyoutDate > ENDOFPERIOD(&Period, MONTH)
	|				THEN CAST(&AmountOfLeaseAssetsByuout - 100 * &AmountOfLeaseAssetsByuout / (100 + &ValueOfVATRate) AS NUMBER(31, 2))
	|			ELSE 0
	|		END AS Sum
	|FROM
	|	Document.SigningOfLeaseContract.ServiceAccrualSchedule AS ServiceAccrualSchedule
	|	
	|WHERE
	|	ServiceAccrualSchedule.Ref = &Ref
	|	AND &CreatedForTransition
	|	AND ServiceAccrualSchedule.Date > ENDOFPERIOD(&Period, MONTH)";
	
	QueryTexts.Add(Text, TableName);
	
EndProcedure

Procedure QueryTextTableTTAdjustmentOfLeaseLiabilities(QueryTexts)
	
	TableName = "TTAdjustmentOfLeaseLiabilities";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	Text = 
	"SELECT
	|	SUM(NestedQuery.Sum) AS Sum,
	|	CASE
	|		WHEN NOT &ThereIsMaAccount
	|			THEN 0
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN SUM(NestedQuery.Sum)
	|		ELSE CAST(SUM(NestedQuery.Sum) * &ConversionRateToManCurrency AS NUMBER(31, 2))
	|	END AS SumMan,
	|	CASE
	|		WHEN NOT &ThereIsACAccounting
	|			THEN 0
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN SUM(NestedQuery.Sum)
	|		ELSE CAST(SUM(NestedQuery.Sum) * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31, 2))
	|	END AS SumCompl
	|INTO TTAdjustmentOfLeaseLiabilities
	|FROM
	|	(SELECT
	|		ServiceAccrualSchedule.RentalService + ServiceAccrualSchedule.DepositPayment -
	|			CAST(ServiceAccrualSchedule.RentalService - 100 * ServiceAccrualSchedule.RentalService / (100 +
	|			&ValueOfVATRate) AS NUMBER(31, 2)) - CAST(ServiceAccrualSchedule.DepositPayment - 100 *
	|			ServiceAccrualSchedule.DepositPayment / (100 + &ValueOfVATRate) AS NUMBER(31, 2)) AS Sum
	|	FROM
	|		Document.SigningOfLeaseContract.ServiceAccrualSchedule AS ServiceAccrualSchedule
	|	WHERE
	|		ServiceAccrualSchedule.Ref = &Ref
	|		AND &CreatedForTransition
	|		AND ServiceAccrualSchedule.Date > ENDOFPERIOD(&Period, MONTH)
	|
	|	UNION ALL
	|
	|	SELECT
	|		-InterestAccrualSchedule.Interests AS Interests
	|	FROM
	|		Document.SigningOfLeaseContract.InterestAccrualSchedule AS InterestAccrualSchedule
	|	WHERE
	|		InterestAccrualSchedule.Ref = &Ref
	|		AND &CreatedForTransition
	|		AND InterestAccrualSchedule.Date > ENDOFPERIOD(&Period, MONTH)
	|
	|	UNION ALL
	|
	|	SELECT
	|		-FATable.NetBookValue AS NetBookValue
	|	FROM
	|		Document.SigningOfLeaseContract.FA AS FATable
	|	WHERE
	|		FATable.Ref = &Ref
	|		AND &CreatedForTransition
	|
	|	UNION ALL
	|
	|	SELECT
	|		Operation.AmountOfLeaseAssetsByuout-Operation.AmountOfVATRepurchaseOfRentalItems AS NetBookValue
	|	FROM
	|		Document.SigningOfLeaseContract AS Operation
	|	WHERE
	|		Operation.Ref = &Ref
	|		AND &CreatedForTransition
	|) AS NestedQuery";
	
	QueryTexts.Add(Text, TableName);
	
EndProcedure

Procedure InitializeTTAdvanceIds(Query,QueryTexts)
	If Query.Parameters.Property("AdvanceIdsAreInitialized") Then
		Return;
	EndIf;

	QueryText =
	"SELECT DISTINCT
	|	Prepayments.ARAPDocument          AS ARAPDocument,
	|	CAST("""" AS STRING(36))     AS FinRecordID
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(&DocumentBorder, Contract = &Contract
	|	AND AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)) AS Prepayments";

	RequestForAdvances = New Query(QueryText);
	RequestForAdvances.SetParameter("DocumentBorder", Query.Parameters.DocumentBorder);
	RequestForAdvances.SetParameter("Contract", Query.Parameters.Contract);
	
	AdvanceIds = RequestForAdvances.Execute().Unload();
	For Each LineOfAdvances In AdvanceIds Do
		
		LineOfAdvances.FinRecordID = String(New UUID());
		
	EndDo;
	
	Query.SetParameter("AdvanceIds", AdvanceIds);
	Query.SetParameter("AdvanceIdsAreInitialized", True);
	
	TableName = "TTAdvanceIds";
	
	Text = "
	|SELECT
	|	AdvanceIds.ARAPDocument       AS ARAPDocument,
	|	AdvanceIds.FinRecordID  AS FinRecordID
	|
	|INTO TTAdvanceIds
	|
	|FROM
	|	&AdvanceIds AS AdvanceIds
	|";
	
	QueryTexts.Add(Text, TableName);
	
	
EndProcedure

// The text of the request for the formation of a temporary table in the reevaluationavance.
// 
// Parameters:
//  QueryTexts - ValueList -
Procedure QueryTextTableTTRevaluationOfAdvances(QueryTexts)
	
	TableName = "TTRevaluationOfAdvances";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	Text = "
	|SELECT
	|	Prepayments.ARAPDocument                                          AS ARAPDocument,
	|
	|	CAST(Prepayments.SumBalance * TTCourses.LocalRevaluationRatio
	|				AS NUMBER(31, 2))                                     AS AmountOfLocalRevaluation,
	|
	|	CAST(Prepayments.SumBalance * TTCourses.ManSRevaluationCoefficient
	|				AS NUMBER(31, 2))                                     AS AmountOfRevaluationOfMan,
	|
	|	TTAdvanceIds.FinRecordID                    AS FinRecordID
	|
	|INTO TTRevaluationOfAdvances
	|
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(&DocumentBorder, Contract = &Contract
	|	AND AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)) AS Prepayments
	|
	|		LEFT JOIN TTCourses AS TTCourses
	|		ON Prepayments.Currency = TTCourses.Currency
	|		AND BEGINOFPERIOD(Prepayments.ARAPDocument.Date, DAY) = TTCourses.DateOfCourse
	|
	|		LEFT JOIN TTAdvanceIds AS TTAdvanceIds
	|		ON Prepayments.ARAPDocument = TTAdvanceIds.ARAPDocument
	|WHERE
	|	Prepayments.SumBalance <> 0
	|	AND NOT TTAdvanceIds.FinRecordID IS NULL
	|	";
	
	QueryTexts.Add(Text, TableName);
	
EndProcedure

#EndRegion

#EndRegion

#Region ConductingLocalAccounting

Function TextOfReflectionInLocalAccounting() Export
	
	Return SigningOfLeaseContractLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return SigningOfLeaseContractLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

#EndRegion

#Region Print

Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = Catalogs.LeaseContract.AddCommandToDecryptPercentageCalculation(PrintCommands);
	PrintCommand.CheckPostingBeforePrint = True;
	PrintManagement.AddCommandVisibilityCondition(PrintCommand, "TheInterestAccrualScheduleIsEnteredManually", False);
	
EndProcedure

#EndRegion

#Region Other

// Returns the details view.
// 
// Parameters:
// 	AssetHolder - EnumRef.LeasedAssetHolder -
// 	ContractType - EnumRef.TypesOfLeaseContracts -
// 	LeaseAccountingAccordingToFSB25_2018IsUsed - Boolean -
// 	
// Returns:
// 	Map - Contains a representation of the details.
Function PresentationOfDetails(AssetHolder, ContractType, LeaseAccountingAccordingToFSB25_2018IsUsed) Export
	
	PresentationOfDetails = New Map;
	
	If LeaseAccountingAccordingToFSB25_2018IsUsed Then
		
		If ContractType = Enums.TypesOfLeaseContracts.Leasing Then
			
			FASum_Header = NStr("vi = 'Số tiền đầu tư của bên cho thuê (không gồm thuế GTGT)';
								|ru = 'Сумма вложений лизингодателя (без НДС)';
								|en = 'Amount of lessor''s investments (excluding VAT)'; fa = 'Amount of lessor''s investments (excluding VAT)';
								|it = 'Importo investimenti del locatore (senza IVA)';
								|pl = 'Wartość inwestycji leasingodawcy (bez VAT)';
								|tr = 'Kiralayanın yatırım tutarı (KDV hariç)'");
			FASum_Hint = "";

		Else
			
			FASum_Header = NStr("vi = 'Giá trị (không gồm thuế GTGT)';
								|ru = 'Стоимость (без НДС)';
								|en = 'Cost (excluding VAT)'; fa = 'بها (بدون مالیات بر ارزش افزوده)';
								|it = 'Costo (Senza IVA)';
								|pl = 'Wartość bez (VAT)';
								|tr = 'Maliyet (KDV hariç)'"); 
			FASum_Hint = NStr("vi = 'Giá trị đối tượng thuê được tính trên cơ sở giá trị hợp lý và không đảm bảo';
								|ru = 'Стоимость предметов аренды, которая рассчитывается на основании справедливой и негарантированной стоимости';
								|en = 'The cost of the rental objects, which is calculated based on the fair and non-guaranteed value'; fa = 'The cost of the rental objects, which is calculated based on the fair and non-guaranteed value';
								|it = 'Costo degli elementi di affitto calcolato in base al valore equo e del valore non garantito';
								|pl = 'Wartość przedmiotów dzierżawy, która jest obliczana na podstawie sprawiedliwej i niegwarantowanej wartości';
								|tr = 'Adil ve garanti edilmeyen değer temelinde hesaplanan kiralık kalemlerin değeri'");

		EndIf;
			
	Else
		
		If AssetHolder = Enums.LeasedAssetHolder.Lessor Then
			
			FASum_Header = NStr("vi = 'Giá trị thế chấp';
								|ru = 'Залоговая стоимость';
								|en = 'Collateral value'; fa = 'ارزش وثیقه';
								|it = 'Costo di cauzione';
								|pl = 'Wartość kaucyjna';
								|tr = 'Teminat değeri'");
			FASum_Hint = NStr("vi = 'Giá trị ban đầu của đối tượng thuê';
								|ru = 'Залоговая стоимость предмета аренды';
								|en = 'Collateral value of rental object'; fa = 'Collateral value of rental object';
								|it = 'Valore di garanzia dell''oggetto di affitto';
								|pl = 'Wartość kaucyjna przedmiotu dzierżawy';
								|tr = 'Kiralanan varlık teminat değeri'");
		Else
			
			FASum_Header = NStr("vi = 'Số tiền đầu tư của bên cho thuê (không gồm thuế GTGT)';
								|ru = 'Сумма вложений лизингодателя (без НДС)';
								|en = 'Amount of lessor''s investments (excluding VAT)'; fa = 'Amount of lessor''s investments (excluding VAT)';
								|it = 'Importo investimenti del locatore (senza IVA)';
								|pl = 'Wartość inwestycji leasingodawcy (bez VAT)';
								|tr = 'Kiralayanın yatırım tutarı (KDV hariç)'");
			FASum_Hint = "";
			
		EndIf;	

	EndIf;
	
	PresentationOfDetails.Insert("FA.Cost_Header", FASum_Header);
	PresentationOfDetails.Insert("FA.Cost_Hint", FASum_Hint);
	
	Return PresentationOfDetails;
	
EndFunction

// Description of the options for selecting articles and analytics in the document.
// 
// Returns:
// 	Structure of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions - 
Function ItemsAndDimensionsSelectionParameters() Export

	ParametersList = New Array;

	#Region Expenses
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef      = "ExpenseItem";
	ChoiceParameters.ArticleType   = "ItemTypeExpenses";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses   = "DimensionOfExpenses";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesExpensesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesExpensesDimension");
	
	ParametersList.Add(ChoiceParameters);
	#EndRegion

	#Region Income
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "IncomeItem";
	ChoiceParameters.ArticleType = "ItemTypeIncome";
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesIncomeDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesIncomeDimension");
	
	ParametersList.Add(ChoiceParameters);
	#EndRegion
	
	Return ParametersList;
	
EndFunction

Function AccountingAccountSettings_() Export
	
	ParametersArray = New Array();
	
	#Region SettingUpPresentationOfExpensesInLocalAccounting
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.GLAccountSettings = "ExpenseLedgerAccountsSettings";
	
	SetupParameters.AssetAndLiabilityItem = "ExpenseItem";
	SetupParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesExpensesDimension";
	
	SetupParameters.Presentation = "PresentationOfTheCostReflectionInTheReglAccounting";
	SetupParameters.ArticleType     = "ItemTypeExpenses";
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("PresentationOfTheCostReflectionInTheReglAccounting");
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
		
	#Region SettingUpPresentationOfExpensesInLocalAccounting
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.GLAccountSettings = "IncomeLedgerAccountsSettings";
	SetupParameters.AssetAndLiabilityItem = "IncomeItem";
	SetupParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesIncomeDimension";
	
	SetupParameters.Presentation = "PresentationOfTheIncomeReflectionInTheReglAccounting";
	SetupParameters.ArticleType     = "ItemTypeIncome";

	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("PresentationOfTheIncomeReflectionInTheReglAccounting");
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction


// Calculate the rate, cost, interest.
// 
// Parameters:
//  Object - DocumentObject.SigningOfLeaseContract
//  ContractDetails_ - Structure
Procedure CalculateRateCostInterest(Object, ContractDetails_) Export

	CalculationParameters = LeasedAssetAccounting.InterestRateCalculationParameters(Object, ContractDetails_);
	CalculationParameters.FATable = Object.FA;
	
	If ContractDetails_.ContractType = PredefinedValue("Enum.TypesOfLeaseContracts.Lease")
		And ContractDetails_.MethodForDeterminingCostOfAssets = PredefinedValue("Enum.MethodsOfDeterminingLeasedAssetCost.Manually") Then
		CalculationParameters.LeaseItemsCost = Object.FA.Total("FairValue") - Object.FA.Total("NonGuaranteedFinalCost");
	Else
		CalculationParameters.LeaseItemsCost = Object.FA.Total("Cost");
	EndIf;
	
	LeasedAssetAccounting.CalculateRateCostInterest(CalculationParameters);
	
	Object.InterestRate = CalculationParameters.InterestRate;
	Object.InterestAmount = CalculationParameters.InterestAmount;
	Object.PresentValue = CalculationParameters.PresentValue;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

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
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("FinancialInstruments");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	
	ReceivingLeaseServicesLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.ReceivingLeaseServices") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef);
		
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);

		RequestTextTableOfVATReflection(Query, QueryTexts, Registers);
	
		ReceivingLeaseServicesLocalization.AddRequestTexts(Query, QueryTexts, Registers);

	EndIf;
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
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
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	// Direct payment is possible only with disabled requests for spending d/s.
	If Not GetFunctionalOption("UsePaymentRequests") Then
		Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
		Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	EndIf;
	
	
EndProcedure

// Adds the command to create the document "receipt of rental services".
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
	
	If AccessRight("Insert", Metadata.Documents.ReceivingLeaseServices) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ReceivingLeaseServices.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ReceivingLeaseServices);
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

#Region AccountingMechanisms

#Region VATAccounting

// Initializes the parameters for filling in the VAT activity type
//
// Parameters:
//  Object		- DocumentObject.ReceivingLeaseServices, FormDataStructure	- the document to get parameters for.
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
//  Object		- DocumentObject.ReceivingLeaseServices, FormDataStructure	- the document to get parameters for.
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
	FillParameters.TabularSectionName = "Accruals";
	FillParameters.BankingDetailsNameExpenseItem = "ExpenseItem";
	FillParameters.ExpenseAnalystDetailsName = "DimensionOfExpenses";
	
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
	FillParameters.TabularSectionName = "Accruals";
	FillParameters.BankingDetailsNameExpenseItem = "ExpenseItem";
	FillParameters.ExpenseAnalystDetailsName = "DimensionOfExpenses";
	FillParameters.DetailsNameItemOfAssetsLiabilities = "ExpenseItem";
	FillParameters.NameOfAssetLiabilityAnalystDetails = "AssetsLiabilitiesDimension";
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for registering invoices (received)
//
// Parameters:
//  Object		- DocumentObject.ReceivingLeaseServices, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived
//
Function ParametersForRegisteringInvoicesReceived(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	RegistrationParameters.Ref = Object.Ref;
	RegistrationParameters.Date = Object.Date;
	RegistrationParameters.Organization = Object.Organization;
	RegistrationParameters.Counterparty = Object.Counterparty;
	RegistrationParameters.VATTaxation = Object.VATTaxation;
	RegistrationParameters.PurchaseOfGoodsWorksServices = True;
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

#Region Other

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
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.ChangesPaymentPlan               = False;
	ParametersStructure.ModifiesDeliveryShipmentPlan     = False;

	#Region OptionalParameters
	
	//Details other than the currency and amount of the document. If it is not filled in, then the currency of the document will be taken for reading.
	ParametersStructure.ARAPCurrency             = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP              = "Object.AmountARAP";;
	ParametersStructure.LineOfBusiness          = "";
	ParametersStructure.ARAPObjectSettings                  = "";
	ParametersStructure.PathToTSData                    = "Object.Accruals";
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
	ParametersStructure.FormItems.LabelCurrencies      = "CurrencyDecoration";
	
	#EndRegion
	
	Return ParametersStructure;
EndFunction

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization, Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"ExternalDocumentName", Parameters);	
	
EndProcedure

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'In biên bản / hóa đơn GTGT';
							|ru = 'Акт';
							|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
							|it = 'Atto';
							|pl = 'Customer invoice — Services';
							|tr = 'Tutanak'"));
	Return ArrayOfNames
EndFunction

#EndRegion

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
#Region FillingOutMonetaryDocumentsOnBasisOfERP
// Get the text to fill in based on.
// 
// Returns:
//  String - The text of the request to be filled in based on
Function GetTextToFillInBasedOn() Export
	
	QueryText = "
	|SELECT
	|	VALUE(Enum.BusinessTransactions.PaymentToLessor)        AS BusinessOperation,
	|	&Ref                                                                AS DocumentBasis,
	|	DocumentData.VATTaxation                                     AS VATTaxation,
	|	DocumentData.Organization                                            AS Organization,
	|	DocumentData.Department                                          AS Department,
	|	
	|	ISNULL(DocumentData.Contract.BankAccount, 
	|		     VALUE(Catalog.CompaniesBankAccounts.EmptyRef)) AS BankAccount,
	|	
	|	DocumentData.Counterparty                                             AS Counterparty,
	|	DocumentData.Partner                                                AS Partner,
	|	
	|	ISNULL(DocumentData.Contract.CounterpartyBankAccount,
	|		VALUE(Catalog.CounterpartyBankAccounts.EmptyRef))     AS CounterpartyBankAccount,
	|	DocumentData.Contract                                                AS LeaseContracts,
	|	DocumentData.Contract                                                AS Contract,
	|	
	|	CASE
	|		WHEN NOT DocumentData.Contract.BankAccount IS NULL
	|			THEN DocumentData.Contract.BankAccount.CashCurrency
	|		ELSE DocumentData.Currency
	|	END                                                                  AS Currency,
	|	
	|	SUM(CASE
	|			WHEN DocumentData.PriceIncludesVAT
	|				THEN TSAccruals.Sum
	|			ELSE TSAccruals.Sum + TSAccruals.VATAmount
	|			END)                                                         AS Sum,
	|	DocumentData.ARAPCurrency                                   AS ARAPCurrency,
	|	SUM(TSAccruals.AmountARAP)                                AS AmountARAP,
	|	VALUE(Enum.TypesOfLeasePayments.RentalService)             AS TypeOfLeasePayment,
	|	DocumentData.Date                                                   AS RequiredPaymentDate,
	|	VALUE(Enum.PaymentForms.BankAccountPayment)                         AS PaymentMethodOfPaymentRequest,
	|	FALSE                                                                   AS PaymentMethodCash,
	|	TRUE                                                                 AS PaymentMethodBankAccount,
	|	UNDEFINED                                                           AS ARAPObject,
	|	UNDEFINED                                                           AS CashAccount,
	|	
	|	ISNULL(DocumentData.Contract.CashFlowItem,
	|		VALUE(Catalog.CashFlowReportItems.EmptyRef))   AS CashFlowItem,
	|		
	|	TSAccruals.VATRate                                                 AS VATRate,
	|	SUM(TSAccruals.VATAmount)                                           AS VATAmount
	|	
	|FROM
	|	Document.ReceivingLeaseServices.Accruals           AS TSAccruals
	|		LEFT JOIN Document.ReceivingLeaseServices AS DocumentData
	|		ON TSAccruals.Ref = DocumentData.Ref
	|		
	|WHERE
	|	DocumentData.Ref = &Ref
	|	
	|GROUP BY
	|	DocumentData.VATTaxation,
	|	DocumentData.Contract,
	|	ISNULL(DocumentData.Contract.BankAccount, VALUE(Catalog.CompaniesBankAccounts.EmptyRef)),
	|	ISNULL(DocumentData.Contract.CounterpartyBankAccount,
	|		VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)),
	|	ISNULL(DocumentData.Contract.CashFlowItem,
	|		VALUE(Catalog.CashFlowReportItems.EmptyRef)),
	|	VALUE(Enum.BusinessTransactions.PaymentForLeaseServices),
	|	DocumentData.Organization,
	|	DocumentData.Department,
	|	DocumentData.Counterparty,
	|	CASE
	|		WHEN NOT DocumentData.Contract.BankAccount IS NULL
	|			THEN DocumentData.Contract.BankAccount.CashCurrency
	|		ELSE DocumentData.Currency
	|	END,
	|	DocumentData.ARAPCurrency,
	|	VALUE(Enum.TypesOfLeasePayments.RentalService),
	|	DocumentData.Date,
	|	VALUE(Enum.PaymentForms.BankAccountPayment),
	|	TSAccruals.VATRate,
	|	DocumentData.Partner
	|";
	
	Return QueryText;
EndFunction

// Fill out a transcript of the receipt of rental services.
// 
// Parameters:
//  Document - DocumentObject
//  QueryResult - QueryResult - query result
//  FillingData - Structure - document filling data corresponding to the selection from the Get textfill function on the basis.
//
Procedure FillInTranscriptOfReceiptOfRentalServices(Document, QueryResult, FillingData) Export
	
	Document.ARAPDetails.Clear();

	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(FillingData.Organization);
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		DecryptionString = Document.ARAPDetails.Add();
		FillPropertyValues(DecryptionString, Selection);
		DecryptionString.Sum = ProcessingOfExchangeRatesTM.ConvertToCurrency(
									DecryptionString.AmountARAP,
									CurrencyOfComplianceAccounting,
									Selection.ARAPCurrency,
									FillingData.Currency,
									CurrentSessionDate(),
									Selection.ARAPObject);
	EndDo;
	
	Document.DocumentAmount = Document.ARAPDetails.Total("Sum");
	
EndProcedure
#EndRegion	

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
		Data, Presentation, StandardProcessing, "ReceivingLeaseServices");
	
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

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.ReceivingLeaseServices";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",        """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
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

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	RegisterName = "DocumentAmountsInAccountingCurrency";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	If DocumentsPosting.ThereIsQueryTable("DocumentAmountsInAccountingCurrency", QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTAmountsOfDocumentsInAccountingCurrencies(QueryTexts);
	
	Text = "
	|////////////////////////////////////////////////////////////////////////////////
	|// Table DocumentAmountsInAccountingCurrency
	|"+
	"SELECT
	|	*
	|FROM
	|	TTAmountsOfDocumentsInAccountingCurrencies";
	
	QueryTexts.Add(Text, RegisterName);
	
EndProcedure

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	
	Query.Text = 
	"SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.PriceIncludesVAT AS PriceIncludesVAT,
	|	DocumentData.Department AS Department,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Contract.AssetHolder AS AssetHolder,
	|	DocumentData.Contract.RecognizeLeasedItemsInLocalAccounting AS RecognizeLeasedItemsInLocalAccounting,
	|	DocumentData.Contract.RecognizeLeasedAssetsInManagementAccounting AS RecognizeLeasedAssetsInManagementAccounting,
	|	DocumentData.Contract.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Contract.ForeignCurrencyTransaction AS CurrencyContract,
	|	DocumentData.PurchaseForActivity AS PurchaseForActivity,
	|	DocumentData.PointInTime AS PointInTime,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Author AS Author,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	DocumentData.IncomingDocumentDate AS IncomingDocumentDate,
	|	DocumentData.ExternalDocumentName AS ExternalDocumentName,
	|	DocumentData.DocumentID AS DocumentID,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Organization.LocalAccountingCurrency AS ComplCurrency,
	|	DocumentData.ActualTransactionDate AS AdjustmentPeriod_
	|FROM
	|	Document.ReceivingLeaseServices AS DocumentData
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

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	ValuesOfHoldingParameters = New Structure;
	LeasedAssetAccounting.SupplementValuesOfDocumentParameters(ValuesOfHoldingParameters);

	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.ReceivingLeaseServices"));
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.ReceivingLeaseServices);
	
	ValuesOfHoldingParameters.Insert("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	ValuesOfHoldingParameters.Insert("CurrencyOfMan", ValuesOfHoldingParameters.ManagementAccountingCurrency);
	ValuesOfHoldingParameters.Insert("UseAccountingOfOtherIncomeExpenses", GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	ValuesOfHoldingParameters.Insert("AssetAndLiabilityItem", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceLeasing);
	
	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		ValuesOfHoldingParameters.Insert("PriceIncludesVAT", ?(Attributes.PriceIncludesVAT, 0, 1));
		
		ValuesOfHoldingParameters.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed",
			LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Attributes.Organization, Attributes.Period));
		
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.Currency, Attributes.ARAPCurrency, Attributes.Period, Attributes.Organization);
		ValuesOfHoldingParameters.Insert("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
		ValuesOfHoldingParameters.Insert("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
		AccountingParametersForRentalItems = LeasedAssetAccountingClientServer.AccountingParametersForRentalItems(
			ValuesOfHoldingParameters.LeaseAccountingAccordingToFSB25_2018IsUsed, Attributes);
	
		ValuesOfHoldingParameters.Insert("ReflectServicesInLocalExpenses", Not AccountingParametersForRentalItems.ThereIsACAccounting);
		ValuesOfHoldingParameters.Insert("ReflectServicesInManSExpenses", Not AccountingParametersForRentalItems.ThereIsMaAccount);
		
		ValuesOfHoldingParameters.Insert("STSIsApplied", False);
		
	EndIf;
	
	ReceivingLeaseServicesLocalization.SupplementValuesOfParameters(Attributes, ValuesOfHoldingParameters);
	
	Return ValuesOfHoldingParameters;
	
EndFunction

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
	|	&Department                          AS Department,
	|	&Partner                                AS Partner,
	|	&Counterparty                             AS Counterparty,
	|	&Contract                                AS Contract,
	|	DocumentData.Contract.LineOfBusiness AS LineOfBusiness,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	&Author                                  AS Author,
	|	&Comment                            AS Comment,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&IncomingDocumentDate                 AS SourceDocumentDate,
	|	&IncomingDocumentNumber                AS SourceDocumentNumber,
	|	&ExternalDocumentName         AS SourceDocumentName,
	|	&DocumentAmount                         AS Sum,
	|	&Currency                                 AS Currency,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|FROM
	|	Document.ReceivingLeaseServices AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryTextTableTTExpenses(Query, QueryTexts);
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	AccrualTable.Department AS Department,
	|	AccrualTable.LineOfBusiness AS LineOfBusiness,
	|	AccrualTable.ExpenseItem AS AssetRef,
	|	AccrualTable.AssetsLiabilitiesDimension AS Dimension,
	|	AccrualTable.AmountExcludingVATMan + AccrualTable.VATAmountMan AS Sum
	|FROM
	|	TTExpenses AS AccrualTable
	|WHERE
	|	AccrualTable.Ref = &Ref
	|	AND AccrualTable.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|
	|UNION ALL
	|	
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceLeasing) AS AssetRef,
	|	&Contract AS Dimension,
	|	AccrualTable.AmountExcludingVATMan + AccrualTable.VATAmountMan AS Sum
	|FROM
	|	TTExpenses AS AccrualTable
	|WHERE
	|	AccrualTable.Ref = &Ref
	|	AND AccrualTable.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	
	|";
	QueryText = QueryText + "UNION ALL"
		+ AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities(False);
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTExpenses(Query, QueryTexts);
	
	Text =
	"SELECT
	|	TableExpenses.LineNumber,
	|	TableExpenses.Period AS Period,
	|	VALUE(Enum.BusinessTransactions.RecordExpensesAtExpenseOfOtherAssetsLiabilities) AS BusinessOperation,
	|	TableExpenses.Organization AS Organization,
	|
	|	TableExpenses.Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&AssetAndLiabilityItem AS AssetRef,
	|	&Contract AS AssetsLiabilitiesDimension,
	|
	|	TableExpenses.Department AS DebitBusinessUnit,
	|	TableExpenses.LineOfBusiness AS CorLineOfBusiness,
	|	TableExpenses.ExpenseItem AS CorItem,
	|	TableExpenses.DimensionOfExpenses AS CorExpenditureDimension,
	|	TableExpenses.AssetsLiabilitiesDimension AS CorDimensionOfAssetsLiabilities,
	|	
	|	TableExpenses.SumMan AS Sum,
	|	CASE
	|		WHEN TableExpenses.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		 OR NOT &CompanyManagementAccounting
	|		 OR TableExpenses.AmountExcludingVATMan = 0
	|			THEN 0
	|		WHEN TableExpenses.VATActivityType IN (
	|					VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|					VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|				AND TableExpenses.ExpenseItem.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.FromDocument)
	|			THEN TableExpenses.AmountExcludingVATMan + TableExpenses.VATAmountMan
	|		ELSE
	|			TableExpenses.AmountExcludingVATMan
	|	END AS SumMan,
	|	CASE 
	|		WHEN TableExpenses.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|			THEN 0
	|		WHEN TableExpenses.VATActivityType IN (
	|					VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|					VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN TableExpenses.SumCompl
	|		ELSE
	|			TableExpenses.AmountExcludingVATCompl
	|	END AS SumCompl,
	|	
	|	&Currency AS Currency,
	|	TableExpenses.AmountIncludingVAT AS AmountInCurrency,
	|	UNDEFINED AS SalaryTransactionKind
	|FROM
	|	TTExpenses AS TableExpenses
	|WHERE
	|	(&ReflectServicesInLocalExpenses 
	|		OR &ReflectServicesInManSExpenses)";
	
	QueryTexts.Add(Text, RegisterName);
	
EndProcedure

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

Procedure QueryTextTableTTInitialRegisteredRecordsOnOtherAssetsLiabilities(Query, QueryTexts)
	
	RegisterName = "TTInitialRegisteredRecordsOnOtherAssetsLiabilities";
	
	QueryTextTableTTExpenses(Query, QueryTexts);
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TableExpenses.Department AS Department,
	|	TableExpenses.LineOfBusiness AS LineOfBusiness,
	|	TableExpenses.ExpenseItem AS AssetRef,
	|	TableExpenses.AssetsLiabilitiesDimension AS Dimension,
	|	TableExpenses.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|	TableExpenses.VATActivityType AS VATActivityType,
	|
	|	TableExpenses.SumCompl AS SumCompl,
	|	TableExpenses.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	TableExpenses.AmountExcludingVATMan + TableExpenses.VATAmountMan AS SumMan,
	|	TableExpenses.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	TableExpenses.AmountExcludingVATMan + TableExpenses.VATAmountMan AS AmountIncludingVAT,
	|	TableExpenses.AmountExcludingVATMan   AS AmountExcludingVAT,
	|	0                               AS PermanentDifference,
	|	TableExpenses.CostTD AS CostTD,
	|
	|	TableExpenses.RowID AS RowID,
	|	TableExpenses.RowID AS FinRecordID,
	|	TableExpenses.BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TTInitialRegisteredRecordsOnOtherAssetsLiabilities
	|FROM
	|	TTExpenses AS TableExpenses
	|WHERE
	|	VALUETYPE(TableExpenses.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers)

	RegisterName = "FinancialInstrumentsARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTrackingAnalyticsKeysForPartners(Query);
	
	QueryTextTableTTAmountsOfDocumentsInAccountingCurrencies(QueryTexts);
	
	ListOfMergeRequests = New Array;
	
	#Region ServiceWithoutVAT // Dt <76.07.1> - Ct <70.07.2, 70.07.3, 70.07.4>
	QueryText =
	"//servicebeznds // Dr <76.07.1> - Cr <70.07.2, 70.07.3, 70.07.4>
	|SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations)       AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	SumTable.AmountWithoutVATOfSettlements                                  AS Sum,
	|
	|	CASE
	|		WHEN NOT &ReflectServicesInManSExpenses
	|			THEN SumTable.AmountExcludingVATMan
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN NOT &ReflectServicesInLocalExpenses
	|			THEN SumTable.AmountExcludingVATCompl
	|		ELSE 0
	|	END AS SumCompl,
	|	
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	AccrualTable.RowID                                   AS RowID,
	|	AccrualTable.RowID                                   AS FinRecordID,
	|
	|	CASE AccrualTable.AccrualType
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalService)
	|			THEN &BO_ReceivingLeaseServices
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN &BO_ReceivingLeaseServices
	|		WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN &BO_DepositPayment
	|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
	|			THEN &BO_VendorInvoiceLeasedAssets
	|	END AS BusinessOperation,
	|
	|	CASE AccrualTable.AccrualType
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalService)
	|			THEN &SettingUpHO_ReceiptOfRentalServices
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN &SettingUpHO_ReceiptOfRentalServices
	|		WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN &SettingUpHO_SecurityPayment
	|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
	|			THEN &SettingUpHO_BuyoutOfLeasedFA
	|	END AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReceivingLeaseServices.Accruals AS AccrualTable
	|
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS SumTable
	|		ON SumTable.RowID = AccrualTable.RowID
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	AccrualTable.Ref = &Ref
	|	AND (NOT &ReflectServicesInLocalExpenses OR NOT &ReflectServicesInManSExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	AccrualTable.AccrualType                                         AS AmountType,
	|	AccrualTable.ARAPDocument                                     AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	SumTable.AmountWithoutVATOfSettlements                                  AS Sum,
	|
	|	CASE
	|		WHEN NOT &ReflectServicesInManSExpenses
	|			THEN SumTable.AmountExcludingVATMan
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN NOT &ReflectServicesInLocalExpenses
	|			THEN SumTable.AmountExcludingVATCompl
	|		ELSE 0
	|	END AS SumCompl,
	|	
	|	VALUE(Enum.FinancialInstrumentScheduleTypes.Accruals)    AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	AccrualTable.RowID                                   AS RowID,
	|	AccrualTable.RowID                                   AS FinRecordID,
	|
	|	CASE AccrualTable.AccrualType
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalService)
	|			THEN &BO_ReceivingLeaseServices
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN &BO_ReceivingLeaseServices
	|		WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN &BO_DepositPayment
	|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
	|			THEN &BO_VendorInvoiceLeasedAssets
	|	END AS BusinessOperation,
	|
	|	CASE AccrualTable.AccrualType
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalService)
	|			THEN &SettingUpHO_ReceiptOfRentalServices
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN &SettingUpHO_ReceiptOfRentalServices
	|		WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN &SettingUpHO_SecurityPayment
	|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
	|			THEN &SettingUpHO_BuyoutOfLeasedFA
	|	END AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReceivingLeaseServices.Accruals AS AccrualTable
	|
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS SumTable
	|		ON SumTable.RowID = AccrualTable.RowID
	|
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	AccrualTable.Ref = &Ref
	|	AND (NOT &ReflectServicesInLocalExpenses OR NOT &ReflectServicesInManSExpenses)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region VATService // Dt <76.07.1> - Ct <76.07.9>
	QueryText =
	"//services // Dr <76.07.1> - Cr <76.07.9>
	|SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.LeaseObligations)       AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	SumTable.AmountVATARAP                                     AS Sum,
	|
	|	CASE
	|		WHEN NOT &ReflectServicesInManSExpenses
	|			THEN SumTable.VATAmountMan
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN NOT &ReflectServicesInLocalExpenses
	|			THEN SumTable.VATAmountCompl
	|		ELSE 0
	|	END AS SumCompl,
	|
	|	UNDEFINED                                                            AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	AccrualTable.RowID                                   AS RowID,
	|	AccrualTable.RowID                                   AS FinRecordID,
	|
	|	CASE AccrualTable.AccrualType
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalService)
	|			THEN &BO_AccrualOfVATInPartOfLeaseService
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN &BO_AccrualOfVATInPartOfLeaseService
	|		WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN &BO_AccrualOfVATInPartOfSecurityPayment
	|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
	|			THEN &BO_AccrualOfVATInPartOfBuyoutValue
	|	END AS BusinessOperation,
	|
	|	CASE AccrualTable.AccrualType
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalService)
	|			THEN &SettingUpHO_AccrualOfNDSVPartOfRentalService
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN &SettingUpHO_AccrualOfNDSVPartOfRentalService
	|		WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN &SettingUpHO_AccrualOfPersonalIncomeTaxPartOfSecurityPayment
	|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
	|			THEN &SettingUpHO_AccrualOfNdsvPartOfRedemptionValue
	|	END AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReceivingLeaseServices.Accruals AS AccrualTable
	|
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS SumTable
	|		ON SumTable.RowID = AccrualTable.RowID
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	AccrualTable.Ref = &Ref
	|	AND (SumTable.AmountVATARAP <> 0
	|		OR SumTable.VATAmountMan <> 0
	|		OR SumTable.VATAmountCompl <> 0)
	|
	|	AND (NOT &ReflectServicesInLocalExpenses OR NOT &ReflectServicesInManSExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.VAT)                         AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	SumTable.AmountVATARAP                                     AS Sum,
	|
	|	CASE
	|		WHEN NOT &ReflectServicesInManSExpenses
	|			THEN SumTable.VATAmountMan
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN NOT &ReflectServicesInLocalExpenses
	|			THEN SumTable.VATAmountCompl
	|		ELSE 0
	|	END AS SumCompl,
	|	
	|	VALUE(Enum.FinancialInstrumentScheduleTypes.Accruals)    AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	AccrualTable.RowID                                   AS RowID,
	|	AccrualTable.RowID                                   AS FinRecordID,
	|
	|	CASE AccrualTable.AccrualType
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalService)
	|			THEN &BO_AccrualOfVATInPartOfLeaseService
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN &BO_AccrualOfVATInPartOfLeaseService
	|		WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN &BO_AccrualOfVATInPartOfSecurityPayment
	|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
	|			THEN &BO_AccrualOfVATInPartOfBuyoutValue
	|	END AS BusinessOperation,
	|
	|	CASE AccrualTable.AccrualType
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalService)
	|			THEN &SettingUpHO_AccrualOfNDSVPartOfRentalService
	|		WHEN VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN &SettingUpHO_AccrualOfNDSVPartOfRentalService
	|		WHEN VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN &SettingUpHO_AccrualOfPersonalIncomeTaxPartOfSecurityPayment
	|		WHEN VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
	|			THEN &SettingUpHO_AccrualOfNdsvPartOfRedemptionValue
	|	END AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReceivingLeaseServices.Accruals AS AccrualTable
	|
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS SumTable
	|		ON SumTable.RowID = AccrualTable.RowID
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	AccrualTable.Ref = &Ref
	|	AND (SumTable.AmountVATARAP <> 0
	|		OR SumTable.VATAmountMan <> 0
	|		OR SumTable.VATAmountCompl <> 0)
	|
	|	AND (NOT &ReflectServicesInLocalExpenses OR NOT &ReflectServicesInManSExpenses)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region VATService // Dt <19.XX> - Ct <70.07.2, 70.07.3, 70.07.4>
	QueryText =
	"//services // Dr <19.xx> - Cr <70.07.2, 70.07.3, 70.07.4>
	|SELECT
	|	AccrualTable.Period AS Period,
	|	AccrualTable.RecordType AS RecordType,
	|	AccrualTable.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	AccrualTable.Contract AS Contract,
	|	AccrualTable.AmountType AS AmountType,
	|	AccrualTable.ARAPDocument AS ARAPDocument,
	|	AccrualTable.Currency AS Currency,
	|	SUM(AccrualTable.Sum) AS Sum,
	|	SUM(AccrualTable.SumMan) AS SumMan,
	|	SUM(AccrualTable.SumCompl) AS SumCompl,
	|	AccrualTable.ScheduleType AS ScheduleType,
	|	AccrualTable.DimensionItem AS DimensionItem,
	|	AccrualTable.RowID AS RowID,
	|	AccrualTable.FinRecordID AS FinRecordID,
	|	AccrualTable.BusinessOperation AS BusinessOperation,
	|	AccrualTable.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	(SELECT
	|		&Period AS Period,
	|		VALUE(AccumulationRecordType.Expense) AS RecordType,
	|		ISNULL(DimensionByPartners.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|		&Contract AS Contract,
	|		AccrualTable.AccrualType AS AmountType,
	|		AccrualTable.ARAPDocument AS ARAPDocument,
	|		&ARAPCurrency AS Currency,
	|		CASE
	|			WHEN NOT &ReflectServicesInLocalExpenses
	|				THEN SumTable.AmountVATARAP
	|			ELSE 0
	|		END AS Sum,
	|		CASE
	|			WHEN NOT &ReflectServicesInManSExpenses
	|				THEN SumTable.VATAmountMan
	|			ELSE 0
	|		END AS SumMan,
	|		CASE
	|			WHEN NOT &ReflectServicesInLocalExpenses
	|				THEN SumTable.VATAmountCompl
	|			ELSE 0
	|		END AS SumCompl,
	|		UNDEFINED AS ScheduleType,
	|		UNDEFINED AS DimensionItem,
	|		AccrualTable.RowID AS RowID,
	|		AccrualTable.RowID AS FinRecordID,
	|		CASE
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.RentalService)
	|				THEN &BO_ReceiptOfVATInPartOfLeaseService
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|				THEN &BO_ReceiptOfVATInPartOfLeaseService
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|				THEN &BO_ReceiptOfVATInPartOfSecurityPayment
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
	|				THEN &BO_ReceiptOfVATInPartOfBuyoutValue
	|		END AS BusinessOperation,
	|		CASE
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.RentalService)
	|				THEN &SettingUpHO_ReceiptOfNDSVPartOfRentalService
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|				THEN &SettingUpHO_ReceiptOfNDSVPartOfRentalService
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|				THEN &SettingUpHO_ReceiptOfPersonalIncomeTaxPartOfSecurityPayment
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
	|				THEN &SetupHO_ReceiptOfNDSVPartOfRedemptionValue
	|		END AS BusinessTransactionSetting
	|	FROM
	|		Document.ReceivingLeaseServices.Accruals AS AccrualTable
	|			LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS SumTable
	|			ON (SumTable.RowID = AccrualTable.RowID)
	|			LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|			ON (DimensionByPartners.Organization = &Organization)
	|				AND (DimensionByPartners.Partner = &Partner)
	|				AND (DimensionByPartners.Counterparty = &Counterparty)
	|				AND (DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef))
	|				AND (DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|	WHERE
	|		AccrualTable.Ref = &Ref
	|		AND (NOT &ReflectServicesInLocalExpenses
	|				OR NOT &ReflectServicesInManSExpenses)
	|		AND (SumTable.AmountVATARAP <> 0
	|				OR SumTable.VATAmountMan <> 0
	|				OR SumTable.VATAmountCompl <> 0)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&Period,
	|		VALUE(AccumulationRecordType.Expense),
	|		ISNULL(DimensionByPartners.DimensionKey, UNDEFINED),
	|		&Contract,
	|		CASE
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|				THEN VALUE(Enum.TypesOfLeasePayments.RentalService)
	|			ELSE AccrualTable.AccrualType
	|		END,
	|		CASE
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|				THEN UNDEFINED
	|			ELSE AccrualTable.ARAPDocument
	|		END,
	|		&ARAPCurrency,
	|		CASE
	|			WHEN &ReflectServicesInLocalExpenses
	|				THEN SumTable.AmountVATARAP
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN &ReflectServicesInManSExpenses
	|				THEN SumTable.VATAmountMan
	|			ELSE 0
	|		END,
	|		CASE
	|			WHEN &ReflectServicesInLocalExpenses
	|				THEN SumTable.VATAmountCompl
	|			ELSE 0
	|		END,
	|		UNDEFINED,
	|		UNDEFINED,
	|		AccrualTable.RowID,
	|		AccrualTable.RowID,
	|		CASE
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.RentalService)
	|				THEN &BO_ReceiptOfVATInPartOfLeaseService
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|				THEN &BO_ReceiptOfVATInPartOfLeaseService
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|				THEN &BO_ReceiptOfVATInPartOfLeaseService
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
	|				THEN &BO_ReceiptOfVATInPartOfBuyoutValue
	|		END,
	|		CASE
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.RentalService)
	|				THEN &SettingUpHO_ReceiptOfNDSVPartOfRentalService
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|				THEN &SettingUpHO_ReceiptOfNDSVPartOfRentalService
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|				THEN &SettingUpHO_ReceiptOfNDSVPartOfRentalService
	|			WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
	|				THEN &SetupHO_ReceiptOfNDSVPartOfRedemptionValue
	|		END
	|	FROM
	|		Document.ReceivingLeaseServices.Accruals AS AccrualTable
	|			LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS SumTable
	|			ON (SumTable.RowID = AccrualTable.RowID)
	|			LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|			ON (DimensionByPartners.Organization = &Organization)
	|				AND (DimensionByPartners.Partner = &Partner)
	|				AND (DimensionByPartners.Counterparty = &Counterparty)
	|				AND (DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef))
	|				AND (DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|	WHERE
	|		AccrualTable.Ref = &Ref
	|		AND (&ReflectServicesInLocalExpenses
	|				OR &ReflectServicesInManSExpenses)
	|		AND (SumTable.AmountVATARAP <> 0
	|				OR SumTable.VATAmountMan <> 0
	|				OR SumTable.VATAmountCompl <> 0)) AS AccrualTable
	|
	|GROUP BY
	|	AccrualTable.FinRecordID,
	|	AccrualTable.BusinessOperation,
	|	AccrualTable.ScheduleType,
	|	AccrualTable.RowID,
	|	AccrualTable.DimensionItem,
	|	AccrualTable.AccountingDimensionByPartners,
	|	AccrualTable.BusinessTransactionSetting,
	|	AccrualTable.Currency,
	|	AccrualTable.ARAPDocument,
	|	AccrualTable.Contract,
	|	AccrualTable.Period,
	|	AccrualTable.RecordType,
	|	AccrualTable.AmountType";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region SecurityPaymentWhenAccountingForBalanceWithVAT // Dt <76.07.2> - Ct <76.07.3>
	QueryText =
	"//secured paymentaccountingthe balance of the social security system // Dr <76.07.2> - Cr <76.07.3>
	|SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Receipt)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.RentalService)              AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	CASE
	|		WHEN &ReflectServicesInLocalExpenses AND &ReflectServicesInManSExpenses
	|			THEN SumTable.AmountARAP
	|		ELSE 0
	|	END  AS Sum,
	|
	|	CASE
	|		WHEN &ReflectServicesInManSExpenses
	|			THEN SumTable.AmountExcludingVATMan + SumTable.VATAmountMan
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN &ReflectServicesInLocalExpenses
	|			THEN SumTable.AmountExcludingVATCompl + SumTable.VATAmountCompl
	|		ELSE 0
	|	END AS SumCompl,
	|	
	|	VALUE(Enum.FinancialInstrumentScheduleTypes.Accruals)    AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	AccrualTable.RowID                                   AS RowID,
	|	AccrualTable.RowID                                   AS FinRecordID,
	|
	|	&BO_SecurityPaymentForOffBalanceAccounting                             AS BusinessOperation,
	|	&SettingUpHO_SecurityPaymentWhenAccountingForBalance                    AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReceivingLeaseServices.Accruals AS AccrualTable
	|
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS SumTable
	|		ON SumTable.RowID = AccrualTable.RowID
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	AccrualTable.Ref = &Ref
	|	AND (&ReflectServicesInLocalExpenses OR &ReflectServicesInManSExpenses)
	|	AND AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.DepositPayment)       AS AmountType,
	|	AccrualTable.ARAPDocument                                     AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	CASE
	|		WHEN &ReflectServicesInLocalExpenses AND &ReflectServicesInManSExpenses
	|			THEN SumTable.AmountARAP
	|		ELSE 0
	|	END  AS Sum,
	|
	|	CASE
	|		WHEN &ReflectServicesInManSExpenses
	|			THEN SumTable.AmountExcludingVATMan + SumTable.VATAmountMan
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN &ReflectServicesInLocalExpenses
	|			THEN SumTable.AmountExcludingVATCompl + SumTable.VATAmountCompl
	|		ELSE 0
	|	END AS SumCompl,
	|	
	|	VALUE(Enum.FinancialInstrumentScheduleTypes.Accruals)    AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	AccrualTable.RowID                                   AS RowID,
	|	AccrualTable.RowID                                   AS FinRecordID,
	|
	|	&BO_SecurityPaymentForOffBalanceAccounting                             AS BusinessOperation,
	|	&SettingUpHO_SecurityPaymentWhenAccountingForBalance                    AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReceivingLeaseServices.Accruals AS AccrualTable
	|
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS SumTable
	|		ON SumTable.RowID = AccrualTable.RowID
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	AccrualTable.Ref = &Ref
	|	AND (&ReflectServicesInLocalExpenses OR &ReflectServicesInManSExpenses)
	|	AND AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region ServiceForExpensesWithoutVAT // Dt <Expenses> - Ct <76.07.2>
	QueryText =
	"//servicesextension // Dr <expenses> - Cr <76.07.2>
	|SELECT
	|	&Period                                                                 AS Period,
	|	VALUE(AccumulationRecordType.Expense)                                  AS RecordType,
	|	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)              AS AccountingDimensionByPartners,
	|	&Contract                                                                AS Contract,
	|	VALUE(Enum.TypesOfLeasePayments.RentalService)              AS AmountType,
	|	UNDEFINED                                                            AS ARAPDocument,
	|	&ARAPCurrency                                                   AS Currency,
	|	
	|	CASE
	|		WHEN &ReflectServicesInLocalExpenses AND &ReflectServicesInManSExpenses
	|			THEN SumTable.AmountWithoutVATOfSettlements
	|		ELSE 0
	|	END  AS Sum,
	|
	|	CASE
	|		WHEN &ReflectServicesInManSExpenses
	|			THEN SumTable.AmountExcludingVATMan
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN &ReflectServicesInLocalExpenses
	|			THEN SumTable.AmountExcludingVATCompl
	|		ELSE 0
	|	END AS SumCompl,
	|	
	|	VALUE(Enum.FinancialInstrumentScheduleTypes.Accruals)    AS ScheduleType,
	|	UNDEFINED                                                            AS DimensionItem,
	|	AccrualTable.RowID                                   AS RowID,
	|	AccrualTable.RowID                                   AS FinRecordID,
	|
	|	&BO_RecordingLeaseServicesInExpenses                                     AS BusinessOperation,
	|	&SettingUpHO_ReflectingRentalServicesInExpenses                            AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReceivingLeaseServices.Accruals AS AccrualTable
	|
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS SumTable
	|		ON SumTable.RowID = AccrualTable.RowID
	|		
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = &Partner
	|			AND DimensionByPartners.Counterparty = &Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|WHERE
	|	AccrualTable.Ref = &Ref
	|
	|	AND (&ReflectServicesInLocalExpenses
	|		OR &ReflectServicesInManSExpenses
	|		OR NOT &ReflectServicesInLocalExpenses
	|			AND &AssetHolder = VALUE(Enum.LeasedAssetHolder.Lessor))";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Procedure RequestTextTableOfVATReflection(Query, QueryTexts, Registers)
	
	ValueText_ =
	"SELECT
	|	AccrualTable.Ref.Date                   AS Period,
	|	AccrualTable.Ref                        AS Ref,
	|	AccrualTable.Ref.Organization            AS Organization,
	|	AccrualTable.Ref.Department          AS Department,
	|	AccrualTable.Ref.Counterparty             AS Counterparty,
	|	AccrualTable.Ref.Contract                AS Contract,
	|	UNDEFINED                                    AS Shipper,
	|	AccrualTable.Ref                        AS DocumentAcquisitions,
	|	AccrualTable.Ref                        AS OriginalTradeDocument,
	|	FALSE                                            AS ErrorCorrection,
	|	FALSE                                            AS AdjustmentUnderApprovalOfParties,
	|	FALSE                                            AS ReduceAmountVATDeduction,
	|	UNDEFINED                                    AS PurchaseAdjustmentDocument,
	|	AccrualTable.Ref.VATTaxation     AS VATTaxation,
	|	AccrualTable.Ref.PurchaseForActivity AS VATActivityType,
	|	AccrualTable.VATRate                     AS VATRate,
	|	UNDEFINED                                    AS Products,
	|	UNDEFINED                                    AS InventoryOwnerAttribute,
	|	UNDEFINED                                    AS CCDNumber,
	|	AccrualTable.Department                 AS AccountingDivision,
	|
	|	CASE
	|		WHEN &AssetHolder = VALUE(Enum.LeasedAssetHolder.Leaseholder)
	|			THEN AccrualTable.Ref.Contract.LineOfBusiness
	|		ELSE AccrualTable.LineOfBusiness
	|	END                                           AS LineOfBusiness,
	|	FALSE                                            AS PurchasePerBatchOfProduction,
	|	UNDEFINED                                    AS LineOfBusinessOfProductionParty,
	|
	|	UNDEFINED                                    AS ToExpenseAs,
	|	AccrualTable.ExpenseItem                AS ExpenseItem,
	|	AccrualTable.DimensionOfExpenses             AS DimensionOfExpenses,
	|	AccrualTable.ExpenseItem                AS ItemOfOtherAssets,
	|	AccrualTable.AssetsLiabilitiesDimension      AS AnalyticsOfOtherAssets,
	|	UNDEFINED                                    AS Purpose,
	|	AccrualTable.RowID           AS RowID,
	|	AccrualTable.RowID           AS FinRecordID,
	|	CASE
	|		WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.RentalService)
	|			OR AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN &SettingUpHO_ReceiptOfNDSVPartOfRentalService
	|		WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|		AND NOT &ReflectServicesInLocalExpenses
	|			THEN &SettingUpHO_ReceiptOfPersonalIncomeTaxPartOfSecurityPayment
	|		WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|		AND &ReflectServicesInLocalExpenses
	|			THEN &SettingUpHO_ReceiptOfNDSVPartOfRentalService
	|		WHEN AccrualTable.AccrualType = VALUE(Enum.TypesOfLeasePayments.BuyoutValue)
	|			THEN &SetupHO_ReceiptOfNDSVPartOfRedemptionValue
	|	END AS BusinessTransactionSetting
	|FROM
	|	Document.ReceivingLeaseServices.Accruals AS AccrualTable
	|WHERE
	|	AccrualTable.Ref = &Ref";
	
	VATAccountingERP.ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

Procedure QueryTextTableTTAdvanceRates(QueryTexts)

	TableName = "TTAdvanceRates";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT DISTINCT
	|	Accruals.ARAPDocument AS ARAPDocument,
	|	&ARAPCurrency AS ARAPCurrency,
	|	ISNULL(DocumentsRegistry.IBDocumentDate, &Period) AS Date
	|INTO PeriodsTable
	|FROM
	|	Document.ReceivingLeaseServices.Accruals AS Accruals
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON Accruals.ARAPDocument = DocumentsRegistry.Ref
	|WHERE
	|	Accruals.Ref = &Ref
	|	AND Accruals.AccrualType IN (
	|		VALUE(Enum.TypesOfLeasePayments.DepositPayment),
	|		VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment))
	|
	|INDEX BY
	|	Date
	|";
	QueryTexts.Add(QueryText, "PeriodsTable");
	
	FinancialInstruments.QueryTextTTCurrencyConversionFactors(QueryTexts);
	
	QueryText =
	"SELECT DISTINCT
	|	PeriodsTable.ARAPDocument AS ARAPDocument,
	|	ISNULL(ExRates.LocalConversionRatio, 1) AS LocalConversionRatio
	|INTO TTAdvanceRates
	|FROM
	|	PeriodsTable
	|		LEFT JOIN TTCurrencyConversionFactors AS ExRates
	|		ON PeriodsTable.Date = ExRates.Date
	|";
	QueryTexts.Add(QueryText, TableName);

EndProcedure

Procedure QueryTextTableTTAmountsOfDocumentsInAccountingCurrencies(QueryTexts)
	
	TableName = "TTAmountsOfDocumentsInAccountingCurrencies";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTAdvanceRates(QueryTexts);
	
	Text =
	"SELECT DISTINCT
	|	Accruals.Ref AS Ref,
	|	&Period AS Period,
	|	&Currency AS Currency,
	|	Accruals.RowID AS RowID,
	|
	|	Accruals.AmountIncludingVAT AS AmountIncludingVAT,
	|	Accruals.AmountIncludingVAT - Accruals.VATAmount AS AmountExcludingVAT,
	|	Accruals.VATRate AS VATRate,
	|	Accruals.VATAmount AS VATAmount,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN Accruals.AmountARAP - Accruals.AmountVATARAP
	|		WHEN &Currency = &LocalAccountingCurrency
	|			THEN Accruals.AmountIncludingVAT - Accruals.VATAmount
	|		WHEN Accruals.AccrualType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|				AND NOT &LeaseAccountingAccordingToFSB25_2018IsUsed
	|				OR Accruals.AccrualType = VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment)
	|			THEN (Accruals.AmountARAP - Accruals.AmountVATARAP) * AdvanceRates.LocalConversionRatio
	|		ELSE (Accruals.AmountIncludingVAT - Accruals.VATAmount) * &FactorOfConversionToCurrencyOfRegul
	|	END AS AmountExcludingVATCompl,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN Accruals.AmountARAP - Accruals.AmountVATARAP
	|		WHEN &Currency = &LocalAccountingCurrency
	|			THEN Accruals.AmountIncludingVAT - Accruals.VATAmount
	|		WHEN Accruals.AccrualType IN (
	|				VALUE(Enum.TypesOfLeasePayments.DepositPayment),
	|				VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment))
	|			THEN (Accruals.AmountARAP - Accruals.AmountVATARAP) * AdvanceRates.LocalConversionRatio
	|		ELSE (Accruals.AmountIncludingVAT - Accruals.VATAmount) * &FactorOfConversionToCurrencyOfRegul
	|	END AS AmountFA,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN Accruals.AmountARAP - Accruals.AmountVATARAP
	|		WHEN &Currency = &LocalAccountingCurrency
	|			THEN Accruals.AmountIncludingVAT - Accruals.VATAmount
	|		WHEN Accruals.AccrualType IN (
	|				VALUE(Enum.TypesOfLeasePayments.DepositPayment),
	|				VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment))
	|			THEN (Accruals.AmountARAP - Accruals.AmountVATARAP) * AdvanceRates.LocalConversionRatio
	|		ELSE (Accruals.AmountIncludingVAT - Accruals.VATAmount) * &FactorOfConversionToCurrencyOfRegul
	|	END AS VATBaseLocal,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|			THEN Accruals.AmountVATARAP
	|		WHEN &Currency = &LocalAccountingCurrency
	|			THEN Accruals.VATAmount
	|		WHEN Accruals.AccrualType IN (
	|				VALUE(Enum.TypesOfLeasePayments.DepositPayment),
	|				VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment))
	|			THEN Accruals.AmountVATARAP * AdvanceRates.LocalConversionRatio
	|		ELSE Accruals.VATAmount * &FactorOfConversionToCurrencyOfRegul
	|	END AS VATAmountCompl,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN Accruals.AmountARAP - Accruals.AmountVATARAP
	|		ELSE 
	|			(Accruals.AmountIncludingVAT - Accruals.VATAmount) * &ConversionRateToManCurrency
	|	END AS AmountExcludingVATMan,
	|
	|	CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN Accruals.AmountVATARAP
	|		ELSE 
	|			Accruals.VATAmount* &ConversionRateToManCurrency
	|	END AS VATAmountMan,
	|
	|	Accruals.AmountARAP AS AmountARAP,
	|	Accruals.AmountARAP - Accruals.AmountVATARAP AS AmountWithoutVATOfSettlements,
	|	Accruals.AmountVATARAP AS AmountVATARAP,
	|	&Currency AS DocumentCurrency,
	|	&ARAPCurrency AS ARAPCurrency,
	|	&Period AS VATBasePeriod,
	|	FALSE AS RecordedInARAPAccounting,
	|	UNDEFINED AS ARAPObject,
	|	UNDEFINED AS PaymentType_,
	|	FALSE AS RecalculateBasedOnARAPData
	|	
	|INTO TTAmountsOfDocumentsInAccountingCurrencies
	|FROM
	|	Document.ReceivingLeaseServices.Accruals AS Accruals
	|		LEFT JOIN TTAdvanceRates AS AdvanceRates
	|		ON Accruals.ARAPDocument = AdvanceRates.ARAPDocument
	|
	|WHERE
	|	Accruals.Ref = &Ref";
	
	QueryTexts.Add(Text, TableName);
	
EndProcedure

Function QueryTextTableTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	If DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		Return "";
	EndIf; 
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	TextSelectionOfAnalystField =
	"SELECT
	|	""Accruals"" 							AS TabularSectionName,
	|	DocumentTable.LineNumber 			AS LineNumber,
	|	UNDEFINED							AS Vendor,
	|	DocumentData.Counterparty				AS Counterparty,
	|	DocumentTable.VATRate 				AS VATRate,
	|	CASE
	|		WHEN ISNULL(ARTICLES__.VATAssetTaxClass, UNDEFINED) IN
	|		  (VALUE(Enum.AssetKinds.FA), VALUE(Enum.AssetKinds.IA))
	|		  AND ISNULL(ARTICLES__.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		  AND ISNULL(ARTICLES__.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|			THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|		WHEN ISNULL(ARTICLES__.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation) 
	|			THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		ELSE DocumentData.PurchaseForActivity
	|	END                               	AS VATTaxation,
	|	CASE
	|		WHEN ISNULL(ARTICLES__.VATAssetTaxClass, VALUE(Enum.AssetKinds.EmptyRef)) <>
	|		  VALUE(Enum.AssetKinds.EmptyRef)
	|			THEN ARTICLES__.VATAssetTaxClass
	|		ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END                               	AS AssetTaxClass,
	|	0										AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.ReceivingLeaseServices.Accruals AS DocumentTable
	|	INNER JOIN Document.ReceivingLeaseServices AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
	|		ON DocumentTable.ExpenseItem = ARTICLES__.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	QueryText = "
	|////////////////////////////////////////////////////////////////////////////////
	|// Table TTTableOfPartyAccountingAnalysts
	|" + QueryText;
	
	QueryTexts[QueryTexts.Count() - 1].Value = QueryText;
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableTTExpenses(Query, QueryTexts)
	
	TableName = "TTExpenses";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTAmountsOfDocumentsInAccountingCurrencies(QueryTexts);
	QueryTextTableTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	
	QueryText = ReceivingLeaseServicesLocalization.QueryTextTableTTExpenses();
	
	If QueryText = Undefined Then
		QueryText =
		"// Amounts excluding VAT.
		|SELECT
		|	&Period                                    AS Period,
		|	&Organization                               AS Organization,
		|	&AdjustmentPeriod_                       AS VariancePeriod,
		|	AccrualTable_.Ref                   AS Ref,
		|	AccrualTable_.LineNumber              AS LineNumber,
		|	AccrualTable_.RowID      AS RowID,
		|	AccrualTable_.ExpenseItem           AS ExpenseItem,
		|	AccrualTable_.DimensionOfExpenses        AS DimensionOfExpenses,
		|	AccrualTable_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	AccrualTable_.GLAccountSettings     AS GLAccountSettings,
		|	AccrualTable_.Department            AS Department,
		|	AccrualTable_.LineOfBusiness  AS LineOfBusiness,
		|	TableOfBatchAccountingAnalysts.AssetTaxClass     AS AssetTaxClass,
		|	&SettingUpHO_ReflectingRentalServicesInExpenses AS BusinessTransactionSetting,
		|
		|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) AS VATActivityType,
		|	TableOfBatchAccountingAnalysts.LotVendorAttributes                    AS LotVendorAttributes,
		|
		|	AccrualTable_.VATRate                AS VATRate,
		|
		|	CASE
		|		WHEN &ReflectServicesInManSExpenses
		|			THEN SumTable.AmountExcludingVATMan + SumTable.VATAmountMan
		|		ELSE 0
		|	END AS SumMan,
		|
		|	CASE
		|		WHEN &ReflectServicesInManSExpenses
		|			THEN SumTable.AmountIncludingVAT
		|		ELSE 0
		|	END AS AmountIncludingVAT,
		|
		|	CASE
		|		WHEN &ReflectServicesInManSExpenses
		|			THEN SumTable.VATAmount
		|		ELSE 0
		|	END AS VATAmount,
		|
		|	CASE
		|		WHEN &ReflectServicesInManSExpenses
		|			THEN SumTable.AmountExcludingVATMan
		|		ELSE 0
		|	END AS AmountExcludingVATMan,
		|
		|	CASE
		|		WHEN &ReflectServicesInManSExpenses
		|			THEN SumTable.VATAmountMan
		|		ELSE 0
		|	END AS VATAmountMan,
		|
		|	CASE
		|		WHEN &ReflectServicesInLocalExpenses
		|			THEN SumTable.AmountExcludingVATCompl + SumTable.VATAmountCompl
		|		ELSE 0
		|	END AS SumCompl,
		|
		|	CASE
		|		WHEN &ReflectServicesInLocalExpenses
		|			THEN SumTable.AmountExcludingVATCompl
		|		ELSE 0
		|	END AS AmountExcludingVATCompl,
		|
		|	CASE
		|		WHEN &ReflectServicesInLocalExpenses
		|			THEN SumTable.VATAmountCompl
		|		ELSE 0
		|	END AS VATAmountCompl,
		|
		|	0 AS CostTD,
		|
		|	SumTable.AmountARAP    AS AmountARAP,
		|	SumTable.AmountVATARAP AS AmountVATARAP
		|
		|INTO TTExpenses
		|
		|FROM
		|	Document.ReceivingLeaseServices.Accruals AS AccrualTable_
		|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS SumTable
		|		ON (SumTable.RowID = AccrualTable_.RowID)
		|		LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
		|		ON (TableOfBatchAccountingAnalysts.LineNumber = AccrualTable_.LineNumber)
		|			AND (TableOfBatchAccountingAnalysts.TabularSectionName = ""Accruals"")
		|WHERE
		|	AccrualTable_.Ref = &Ref
		|	AND (&ReflectServicesInLocalExpenses
		|			OR &ReflectServicesInManSExpenses
		|			OR NOT &ReflectServicesInLocalExpenses
		|				AND &AssetHolder = VALUE(Enum.LeasedAssetHolder.Lessor))
		|
		|UNION ALL
		|
		|// VAT amounts.
		|SELECT
		|	&Period                                    AS Period,
		|	&Organization                               AS Organization,
		|	&AdjustmentPeriod_                       AS VariancePeriod,
		|	AccrualTable_.Ref                   AS Ref,
		|	AccrualTable_.LineNumber              AS LineNumber,
		|	AccrualTable_.RowID      AS RowID,
		|	AccrualTable_.ExpenseItem           AS ExpenseItem,
		|	AccrualTable_.DimensionOfExpenses        AS DimensionOfExpenses,
		|	AccrualTable_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	AccrualTable_.GLAccountSettings     AS GLAccountSettings,
		|	AccrualTable_.Department            AS Department,
		|	AccrualTable_.LineOfBusiness  AS LineOfBusiness,
		|	TableOfBatchAccountingAnalysts.AssetTaxClass     AS AssetTaxClass,
		|	&SettingUpHO_ReceiptOfNDSVPartOfRentalService AS BusinessTransactionSetting,
		|
		|	TableOfBatchAccountingAnalysts.VATTaxation   AS VATActivityType,
		|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
		|
		|	AccrualTable_.VATRate                AS VATRate,
		|
		|	0                          AS SumMan,
		|	SumTable.VATAmount      AS AmountIncludingVAT,
		|	SumTable.VATAmount      AS VATAmount,
		|	0                          AS AmountExcludingVATMan,
		|	SumTable.VATAmountMan   AS VATAmountMan,
		|	SumTable.VATAmountCompl  AS SumCompl,
		|	0                          AS AmountExcludingVATCompl,
		|	SumTable.VATAmountCompl  AS VATAmountCompl,
		|	0                          AS CostTD,
		|	0                          AS AmountARAP,
		|	0                          AS AmountVATARAP
		|FROM
		|	Document.ReceivingLeaseServices.Accruals AS AccrualTable_
		|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS SumTable
		|		ON (SumTable.RowID = AccrualTable_.RowID)
		|		LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
		|		ON (TableOfBatchAccountingAnalysts.LineNumber = AccrualTable_.LineNumber)
		|			AND (TableOfBatchAccountingAnalysts.TabularSectionName = ""Accruals"")
		|WHERE
		|	AccrualTable_.Ref = &Ref";
	EndIf;
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("VariancePeriod");

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
RegisterName = "TTInitialOtherExpenses";
	
	QueryTextTableTTExpenses(Query, QueryTexts);
	
	QueryText = "
	|SELECT
	|	TableExpenses.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableExpenses.VariancePeriod AS VariancePeriod,
	|	TableExpenses.Organization AS Organization,
	|	TableExpenses.Department AS Department,
	|	TableExpenses.LineOfBusiness AS LineOfBusiness,
	|	TableExpenses.ExpenseItem AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableExpenses.VATActivityType AS VATActivityType,
	|
	|	TableExpenses.SumMan AS AmountIncludingVAT,
	|
	|	TableExpenses.AmountExcludingVATMan AS AmountExcludingVAT,
	|	TableExpenses.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	TableExpenses.SumCompl AS AmountIncludingVATCompl,
	|	TableExpenses.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	TableExpenses.CostTD AS CostTD,
	|
	|	&BO_RecordingLeaseServicesInExpenses AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	TableExpenses.RowID AS FinRecordID,
	|	TableExpenses.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	TTExpenses AS TableExpenses
	|WHERE
	|	VALUETYPE(TableExpenses.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND TableExpenses.BusinessTransactionSetting <> &SettingUpHO_ReceiptOfNDSVPartOfRentalService
	|
	|UNION ALL
	|
	|SELECT
	|	TableExpenses.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableExpenses.VariancePeriod AS VariancePeriod,
	|	TableExpenses.Organization AS Organization,
	|	TableExpenses.Department AS Department,
	|	TableExpenses.LineOfBusiness AS LineOfBusiness,
	|	TableExpenses.ExpenseItem AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableExpenses.VATActivityType AS VATActivityType,
	|
	|	0 AS AmountIncludingVAT,
	|
	|	0 AS AmountExcludingVAT,
	|	TableExpenses.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	TableExpenses.SumCompl AS AmountIncludingVATCompl,
	|	TableExpenses.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	TableExpenses.CostTD AS CostTD,
	|
	|	&BO_RecordingLeaseServicesInExpenses AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	TableExpenses.RowID AS FinRecordID,
	|	TableExpenses.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	TTExpenses AS TableExpenses
	|WHERE
	|	VALUETYPE(TableExpenses.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND TableExpenses.BusinessTransactionSetting = &SettingUpHO_ReceiptOfNDSVPartOfRentalService";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

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
	|	Document.ReceivingLeaseServices AS DocumentData
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

#EndRegion

#Region ConductingLocalAccounting

// Returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return ReceivingLeaseServicesLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
// 		String - A string of the request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return ReceivingLeaseServicesLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

#EndRegion

#Region Print

Procedure AddPrintCommands(PrintCommands) Export
	
	
	
EndProcedure

#EndRegion

#Region Other

Function ItemsAndDimensionsSelectionParameters() Export
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Accruals";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ArticleType";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("AccrualsExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("AccrualsDimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AccrualsAssetsLiabilitiesDimension");
	
	Return ChoiceParameters;
	
EndFunction

Function AccountingAccountSettings_(Contract) Export
 
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	
	AvailabilityByOperation = False;
	
	If ValueIsFilled(Contract) Then
		AssetHolder = Common.ObjectAttributeValue(Contract, "AssetHolder");
		If AssetHolder = Enums.LeasedAssetHolder.Lessor Then
			AvailabilityByOperation = True;
		EndIf;
	EndIf;
	
	SetupParameters.AvailabilityByOperation = AvailabilityByOperation;
	SetupParameters.DataPath = "Object.Accruals"; 

	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	SetupParameters.ArticleType     = "ArticleType";
	
	SetupParameters.Organization = "Object.Organization";
	
	SetupParameters.FormItems.Add("AccrualsPresentationOfRecordingInComplAccounting");
	
	Return SetupParameters;
 
EndFunction

#EndRegion

#EndRegion

#EndIf

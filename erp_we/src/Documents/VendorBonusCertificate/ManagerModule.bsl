//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("Rebates");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("FinancialAccounting");
	VendorBonusCertificateLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef.VendorBonusCertificate, DocumentObject.VendorBonusCertificate - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//	ValueList of String - a list of values containing query texts and their names.
//						Returned if the 'Get Request texts' property of the Dopparameters parameter
//						is set to True.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.VendorBonusCertificate") Then
		
		DocumentObject = Document;
		DocumentRef = Document.Ref;
		
	Else
		
		DocumentObject = Document.GetObject();
		DocumentRef = Document;
		
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList; // ValueList of String
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef);
		
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableVendorsARAPAccounting(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableDocumentsRegistry(QueryTexts, Registers, DocumentObject);
		QueryTextTableVendorRebates(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableOtherIncome(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers, DocumentObject);
		
		VendorBonusCertificateLocalization.AddRequestTexts(Query, QueryTexts, Registers, DocumentObject);
		
	EndIf;
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	VendorBonusCertificateLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	VendorBonusCertificateLocalization.AddReportCommands(ReportsCommands, Parameters);
	
	Reports.VendorRebateStatement.AddReportCommand(
		ReportsCommands, Parameters, "StatementOnDeferredExpensedContextActOfAward");
	
EndProcedure

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	VendorBonusCertificateLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

// Description of the logic of access rights restrictions
//
// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowRead
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Counterparty.Partner)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Department, EmptyRef AS TRUE)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ForAllRows(ValueAllowed(Rebates.Partner, EmptyRef AS TRUE, NULL AS TRUE))";
	
EndProcedure

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array of String - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array; // Array of String
	
	NotAttributesToEdit.Add("*");
	
	Return NotAttributesToEdit;
	
EndFunction

// Adds a Command to create a document "Customer Award certificate".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
//
Function AddGenerateCommand(GenerationCommands, Parameters) Export
	
	Result = Undefined;
	
	If AccessRight("Insert", Metadata.Documents.VendorBonusCertificate) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.VendorBonusCertificate.FullName();
		CreateBasedOnCommand.Presentation = Metadata.Documents.VendorBonusCertificate.Synonym;
		CreateBasedOnCommand.WriteMode = "Post";
		
		Result = CreateBasedOnCommand;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject.VendorBonusCertificate, DocumentRef.VendorBonusCertificate, Structure, FormDataStructure - An object or collection for
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
	
	#Region RequiredParameters2
	
	// If all options are false, then this is a payment or a service document.
	ParametersStructure.ThisIsOrder = False;
	ParametersStructure.IsCatalog = False;
	ParametersStructure.ThisIsSalePurchase = True;
	
	// Determines which register the parameters move, which common forms, enumerations and directories to use.
	ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	ParametersStructure.Organization = "Object.Organization";
	
	// With certain values of the document details, he may not change the mutual settlements in terms of payments or shipments.
	// An example is the transfer of goods to the commission.
	
	// If both flags are negative, then the hyperlink "Calculations" is hidden, the amounts of mutual settlements and tabular parts of the mechanism are cleared.
	// If the value is negative, the Offset and Payment stages buttons will be hidden, but it will be possible to change currencies and the exchange rate.
	ParametersStructure.ChangesPaymentPlan = True;
	ParametersStructure.ModifiesDeliveryShipmentPlan = False;
	
	// The date the document was reflected in the system.
	// It is used to get overdue balances for the debt limitation function.
	// Used to get the document's currency rates. 
	// Used to fill in the payment stages and decrypt the default payment.
	ParametersStructure.Date = "Object.Date";
	// The system number of the object
	ParametersStructure.Number = "Object.Number";
	
	// Currency and amount of the transaction. The path to the object's details is required.
	ParametersStructure.DocumentCurrency = "Object.ARAPCurrency";
	ParametersStructure.DocumentAmount = "Object.AmountARAP";
	
	// They are used to generate calculation and analytics objects.
	ParametersStructure.Partner = "Object.Partner";
	ParametersStructure.Counterparty = "Object.Counterparty";
	
	#EndRegion
	
	#Region OptionalParameters
	
	// Details other than the currency and amount of the document. If it is not filled in, then the currency of the document will be taken for reading.
	ParametersStructure.ARAPCurrency = "";
	ParametersStructure.AmountARAP = "";
	ParametersStructure.AmountVATARAP = "";
	ParametersStructure.AmountARAPByPackage = "";
	
	// It is used to generate analytics for the conduct and object of calculations, to determine the schedule for the execution of the contract.
	ParametersStructure.Contract = "Object.Contract";
	//	It is used to obtain the details of the HFC, the order of settlements, currency settlements, payments in the currency when accounting for sales to end customers.
	ParametersStructure.CommissionAgentSAgreement = "";
	// It is used to generate the analysis of the conduct and object of calculations.
	ParametersStructure.LineOfBusiness = "Object.LineOfBusiness";
	
	// The procedure for calculating the document.
	ParametersStructure.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments;
	
	// The total amount with the collateral container. The path to the final indicator of the form (props).
	// It is used to display hyperlinks, edit and fill in the schedule of scheduled payments
	// , edit the payment transcript, etc.
	ParametersStructure.DocumentAmountForm = "";
	
	// The details of the final indicators form containing the amount of the deposit for the container in the currency of the document.
	// It is used in filling out the stages of the payment schedule.
	ParametersStructure.AmountOfDepositForContainerForm = ""; 
	
	// The tabular part, according to which the amount of mutual settlements is distributed, is the "order" field.
	// It is used to display hyperlinks, edit and fill in the schedule of scheduled payments
	// , edit the payment transcript if the Summadocumentform parameter is not filled in.
	// In PM, the objects of calculations for orders are filled in.
	ParametersStructure.PathToTSData = "";
	// The name of the details of the amount with VAT of the tabular part.
	ParametersStructure.PropsNameTSAmountWithVAT = "";
	// The name of the pm item containing the order.
	ParametersStructure.PropsNameTSOrder = "";
	
	// The path to the tabular part of the payment decryption.
	// It is used in the function of offsetting payments, distribution of mutual settlements, distribution of payments.
	ParametersStructure.PathToTSDataPaymentDecryption = "";
	
	// It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	ParametersStructure.Terms = "";
	
	// They are used to determine the value of payments in currency and in the form of editing payment rules.
	ParametersStructure.CompanyBankAccount = "";
	ParametersStructure.CounterpartyBankAccount = "";
	ParametersStructure.CashAccount = "";
	ParametersStructure.PaymentMethod = "";
	ParametersStructure.ForeignCurrencyTransaction = "";
	// It is used in the form of payment rules and for the selection of settlement objects in the decryption of the payment.
	ParametersStructure.PaymentID = "";
	ParametersStructure.VATTaxation = "";
	
	// The storage location of the reference/references to the Calculation Objects directory.
	ParametersStructure.ARAPObject = "Object.ARAPObject";
	
	// The details for the object of calculations are used in conducting.
	ParametersStructure.FinancialAccountingGroup = "Object.FinancialAccountingGroup";
	ParametersStructure.Department = "Object.Department";
	ParametersStructure.Manager = "Object.EmployeeResponsible";
	ParametersStructure.IncomingDocumentNumber = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate = "Object.IncomingDocumentDate";
	
	// Used to determine the object of calculations.
	ParametersStructure.InvoiceForOrders = "";
	
	// It is used when determining the default calculation order and the list of available orders to choose from.
	// Used to determine the object of calculations.
	ParametersStructure.OrderBase = ""; 
	
	// The name of the button that opens the Payment offset assistant for the current set of parameters.
	ParametersStructure.FormItems.PaymentSettlement = "";
	// The name of the table element of the form that displays the amount of settlements.
	// Used to set the conditional design.
	// It should be filled in if the document supports line-by-line manual editing of settlement amounts.
	ParametersStructure.FormItems.AmountOfTSSettlements = "RebatesAmountARAP";
	
	// The name of the form element containing the financial accounting group to reflect the current set of parameters for the BU.
	ParametersStructure.FormItems.FinancialAccountingGroup = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	#EndRegion
	
	#Region EditingPaymentDecryption
	
	// If the transcript is edited in a general form, it is used in the Offset of returns of goods.
	ParametersStructure.FormItems.HyperlinkPaymentDecryption = "";
	
	// If the transcript is being edited in the document.
	// Used in payment distribution.
	ParametersStructure.PaymentsAsPer275FZ = False;
	ParametersStructure.FormItems.ARAPDetails = "";
	ParametersStructure.FormItems.AddToPaymentDecryption = "";
	
	// Selection and selection settings in PM Payment decryption
	
	// To select the balances of settlements by partners with the type of settlements Other relations, without selection by partner.
	ParametersStructure.PartnerOtherRelations = False;
	ParametersStructure.SelectAccountsReceivable = False;
	ParametersStructure.SelectOnlyUnconditionalDebt = False;
	
	#EndRegion
	
	#Region EditingCurrenciesAndCurrencyAmountsOfDocument
	
	// The course of the document is one pair for the document.
	// They are used to calculate the amount of mutual settlements and in the form of editing the currencies and exchange rates of the document.
	ParametersStructure.CourseNumerator = "";
	ParametersStructure.CourseDenominator = "";
	
	// Editing and recalculation of the document amount in the form of currencies and exchange rates is not available,
	// since the amount in the document currency is calculated according to the following conditions
	ParametersStructure.DocumentAmountViewOnly = True;
	
	// The name of the hyperlink displaying the current exchange rate of the document and opening the corresponding form.
	ParametersStructure.FormItems.LabelCurrencies = "CurrencyDecoration";
	
	// It is used when the calling form does not have the Only Review flag, but it is necessary to restrict currency editing.
	ParametersStructure.CurrencyAndExchangeRateDocumentViewOnly = False;
	
	// Are used in the condition through OR with the right to deviate from the terms of sale/purchases.
	ParametersStructure.DocumentCurrencyViewOnly = True;
	ParametersStructure.MutualSettlementsCurrencyViewOnly = ValueIsFilled(Contract);
	
	// If it is not necessary to show the amount and currency of mutual settlements based on the data of the document.
	ParametersStructure.DonTShowCalculations = False;
	// If it is not required to offer recalculation of the amount of the document.
	ParametersStructure.DoNotRecalculateTheAmountOfTheDocument = False;
	
	#EndRegion
	
	#Region ScheduledPaymentScheduleAndPaymentDate
	
	// Function Payment stages and payment date
	ParametersStructure.PathToTSDataPaymentSteps = "";
	ParametersStructure.PaymentDate = "";
	ParametersStructure.PaymentSchedule = "";
	ParametersStructure.ApprovalDate = "";
	ParametersStructure.DateOfShipment = "";
	
	// The name of the hyperlink that displays the current payment rules of the document and opens the Payment Rules form.
	ParametersStructure.FormItems.InscriptionStages = "";
	
	// If you need to restrict the editing of payment melts.
	ParametersStructure.PaymentStagesViewOnly = False;
	// If the order invoice is also true, the extended form of the payment schedule will be displayed, despite the functional option "Simplified form of payment".
	ParametersStructure.InvoiceForSeveralOrdersIsPossible = False;
	// Hides a bank account, cash register, payment in foreign currency and UIP in the form of payment melting, used in self-service.
	ParametersStructure.DoNotSpecifyPaymentSources = False;
	// Set up if you do not need control options Before shipment and before securing in the payment schedule. An example is a commission agent's report.
	ParametersStructure.NoPrepaymentControl = False;
	// If the document has implemented a deferred transfer of ownership, it will allow you to specify the report option "From the date of transfer of ownership"
	ParametersStructure.ThereIsDateOfTransferOfOwnership = False;
	ParametersStructure.DateOfTransferOfTitleToGoods = "";
	
	#EndRegion
	
	#Region MutualSettlementsStatus
	
	// The name of the hyperlink that displays the status of calculations and opens the corresponding report,
	ParametersStructure.FormItems.InscriptionCalculations = "";
	
	#EndRegion
	
	#Region LimitsOnDebtUnderAgreement
	
	// Hyperlink displaying the status of the debt limit
	ParametersStructure.FormItems.DebtLimitationText = "";
	// A picture showing the shipment ban
	ParametersStructure.FormItems.DebtLimitation = "";
	
	#EndRegion
	
	Return ParametersStructure;
	
EndFunction

// Returns parameters for selecting articles in the document.
// 
// Returns:
//	See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "IncomeLiabilityItem";
	ChoiceParameters.ArticleType = "ArticleType";
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeLiabilityItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesDimension");
	
	Return ChoiceParameters;
	
EndFunction

// Returns parameters for setting up accounting accounts in the document.
// 	
// Returns:
// 	Array of See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_() Export
	
	ParametersArray = New Array; // Array of See GLAccountSettingsServer.SetupParameters
	
	#Region SettingUpAccountToReflectDebitingExpenses
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.ArticleType = "ArticleType";
	
	SetupParameters.AssetAndLiabilityItem = "IncomeLiabilityItem";
	
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	SetupParameters.Organization = "Object.Organization";
	
	SetupParameters.FormItems.Add("PresentationOfRecordingInComplAccounting");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return VendorBonusCertificateLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//  String - The text of the request for the temporary reflection table in the regl accounting
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return VendorBonusCertificateLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

// Returns the adapted Query Text of Registered Records by case
// 
// Parameters:
//  RegisterName - String - Name of the register for receiving the adapted request 
// 
// Returns:
//  See InfobaseUpdateTM.ResultOfRequestAdaptation
// 
Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.VendorBonusCertificate";
	SynonymForDocumentTable = "";
	RequestHasSource = True;
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
		
		ExceptionPattern = NStr("vi = 'Trong chứng từ %1 đã không thực hiện việc điều chỉnh văn bản của yêu cầu Lập các chuyển động trong thanh ghi %2.';
								|ru = 'В документе %1 не реализована адаптация текста запроса формирования движений по регистру %2.';
								|en = 'In the %1 document, adaptation of the request for generating records of the %2 register is not implemented.'; fa = 'In the %1 document, adaptation of the request for generating records of the %2 register is not implemented.';
								|it = 'В документе %1 не реализована адаптация текста запроса формирования движений по регистру %2.';
								|pl = 'W dokumencie %1 nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %2.';
								|tr = '%1 belgesinde, %2 kaydına göre hareketlerin düzenlenmesi talebinin metin uyarlaması uygulanmadı.'");
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			ExceptionPattern,
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
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Function GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined, DocumentObject = Undefined) Export
	
	RegisterName = "DocumentAmountsInAccountingCurrency";
	
	If Registers <> Undefined
	   And Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
		
	If DocumentsPosting.ThereIsQueryTable("DocumentAmountsInAccountingCurrency", QueryTexts) Then
		Return "";
	EndIf;
		
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then 
		QueryTextTableTTExchangeRates(Query, QueryTexts, Undefined, DocumentObject);
	EndIf;
	
	QueryText =
	"SELECT
	|	""Bonuses"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	Header.Ref AS Ref,
	|	Header.Organization AS Organization,
	|	Header.Date AS Period,
	|	Header.ARAPCurrency AS Currency,
	|	Header.ARAPCurrency AS ARAPCurrency,
	|	DATETIME(1, 1, 1) AS VATBasePeriod,
	|	Header.Date AS DateOfCourse,
	|	0 AS LineNumber,
	|	Header.DocumentID AS RowID,
	|	Header.AmountARAP AS AmountExcludingVAT,
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|	Header.AmountARAP AS AmountARAP,
	|	Header.AmountARAP AS AmountGiven,
	|	0 AS AmountVATARAP,
	|	CASE
	|		WHEN Header.ARAPCurrency = &LocalAccountingCurrency
	|			THEN Header.AmountARAP
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) / ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) AS NUMBER(31, 2))
	|	END AS AmountExcludingVATCompl,
	|	CASE
	|		WHEN Header.ARAPCurrency = &LocalAccountingCurrency
	|			THEN Header.AmountARAP
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) / ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) AS NUMBER(31, 2))
	|	END AS AmountGivenCompl,
	|	CASE
	|		WHEN Header.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN Header.AmountARAP
	|		WHEN &LocalAccountingCurrency = &ManagementAccountingCurrency
	|			THEN CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyNumerator, 1) / ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyDenominator, 1) AS NUMBER(31, 2))
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyDenominator, 1) / (ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyNumerator, 1)) AS NUMBER(31, 2))
	|	END AS AmountExcludingVATMan,
	|	CASE
	|		WHEN Header.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN Header.AmountARAP
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyDenominator, 1) / (ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyNumerator, 1)) AS NUMBER(31, 2))
	|	END AS AmountGivenMan,
	|	TRUE AS RecordedInARAPAccounting,
	|	Header.ARAPObject AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	DocumentDataHeader AS Header
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON Header.ARAPCurrency = CurrencyExchangeRate.ARAPCurrency
	|			AND Header.ARAPObject = CurrencyExchangeRate.ARAPObject
	|WHERE
	|	Header.Ref IN(&Ref)";
	
	If DocumentObject = Undefined Then
		
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.VendorBonusCertificate");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// Parameters:
//  Query - Query -
//  QueryTexts - ValueList of String -
//  Registers - Undefined - Registers
//  DocumentObject - Undefined, DocumentObject.VendorBonusCertificate - The document object
// 
// Returns:
//  String
//
Function QueryTextTableTTExchangeRates(Query, QueryTexts, Registers, DocumentObject) Export
	
	RegisterName = "TTExchangeRates";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDataOfCalculationObjects", QueryTexts) Then 
		QueryTextTableTTDataOfCalculationObjects(Query, QueryTexts, Undefined, DocumentObject);
	EndIf;
	
	QueryText =
	"SELECT
	|	NestedQuery.ARAPObject AS ARAPObject,
	|	NestedQuery.ARAPCurrency AS ARAPCurrency,
	|	MAX(NestedQuery.RateARAPCurrencyNumerator) AS RateARAPCurrencyNumerator,
	|	MAX(NestedQuery.RateARAPCurrencyDenominator) AS RateARAPCurrencyDenominator,
	|	MAX(NestedQuery.RateManagementAccountingCurrencyNumerator) AS RateManagementAccountingCurrencyNumerator,
	|	MAX(NestedQuery.RateManagementAccountingCurrencyDenominator) AS RateManagementAccountingCurrencyDenominator
	|INTO TTExchangeRates
	|FROM
	|	(SELECT
	|		CalculationObjectData.ARAPObject AS ARAPObject,
	|		CalculationObjectData.ARAPCurrency AS ARAPCurrency,
	|		ExchangeRatesAndCurrenciesOfDocuments.RateARAPCurrencyNumerator AS RateARAPCurrencyNumerator,
	|		ExchangeRatesAndCurrenciesOfDocuments.RateARAPCurrencyDenominator AS RateARAPCurrencyDenominator,
	|		ExchangeRatesAndCurrenciesOfDocuments.RateManagementAccountingCurrencyNumerator AS RateManagementAccountingCurrencyNumerator,
	|		ExchangeRatesAndCurrenciesOfDocuments.RateManagementAccountingCurrencyDenominator AS RateManagementAccountingCurrencyDenominator
	|	FROM
	|		InformationRegister.DocumentCurrenciesAndRates AS ExchangeRatesAndCurrenciesOfDocuments
	|			INNER JOIN TTDataOfCalculationObjects AS CalculationObjectData
	|			ON (CalculationObjectData.Object = ExchangeRatesAndCurrenciesOfDocuments.Document)
	|				AND (CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject,
	|		CalculationObjectData.ARAPCurrency,
	|		ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseNumerator,
	|		ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseDenominator,
	|		0,
	|		0
	|	FROM
	|		InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(
	|				&Period,
	|				Contract IN
	|					(SELECT
	|						CalculationObjectData.Contract
	|					FROM
	|						TTDataOfCalculationObjects AS CalculationObjectData)) AS ExchangeRatesOfSettlementsUnderContractsCutOfLatest
	|			INNER JOIN TTDataOfCalculationObjects AS CalculationObjectData
	|			ON (CalculationObjectData.Contract = ExchangeRatesOfSettlementsUnderContractsCutOfLatest.Contract)
	|				AND (CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject,
	|		CalculationObjectData.ARAPCurrency,
	|		0,
	|		0,
	|		ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseNumerator,
	|		ExchangeRatesOfSettlementsUnderContractsCutOfLatest.CourseDenominator
	|	FROM
	|		InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(
	|				&Period,
	|				Contract IN
	|					(SELECT
	|						CalculationObjectData.Contract
	|					FROM
	|						TTDataOfCalculationObjects AS CalculationObjectData)) AS ExchangeRatesOfSettlementsUnderContractsCutOfLatest
	|			INNER JOIN TTDataOfCalculationObjects AS CalculationObjectData
	|			ON (CalculationObjectData.Contract = ExchangeRatesOfSettlementsUnderContractsCutOfLatest.Contract)
	|				AND (CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract))
	|				AND (CalculationObjectData.ARAPCurrency = &ManagementAccountingCurrency)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject,
	|		CalculationObjectData.ARAPCurrency,
	|		0,
	|		0,
	|		RelativeCourses.CourseNumerator,
	|		RelativeCourses.CourseDenominator
	|	FROM
	|		TTDataOfCalculationObjects AS CalculationObjectData
	|			INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(
	|					&Period,
	|					Currency = &ManagementAccountingCurrency
	|						AND BaseCurrency = &LocalAccountingCurrency) AS RelativeCourses
	|			ON (CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract))
	|				AND (CalculationObjectData.ARAPCurrency <> &ManagementAccountingCurrency)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject,
	|		CalculationObjectData.ARAPCurrency,
	|		RelativeCourses.CourseNumerator,
	|		RelativeCourses.CourseDenominator,
	|		0,
	|		0
	|	FROM
	|		TTDataOfCalculationObjects AS CalculationObjectData
	|			INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(
	|					&Period,
	|					Currency IN
	|							(SELECT
	|								T.ARAPCurrency
	|							FROM
	|								TTDataOfCalculationObjects AS T)
	|						AND BaseCurrency = &LocalAccountingCurrency) AS RelativeCourses
	|			ON (CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.Mutable))
	|				AND (RelativeCourses.Currency = CalculationObjectData.ARAPCurrency)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationObjectData.ARAPObject,
	|		CalculationObjectData.ARAPCurrency,
	|		0,
	|		0,
	|		RelativeCourses.CourseNumerator,
	|		RelativeCourses.CourseDenominator
	|	FROM
	|		TTDataOfCalculationObjects AS CalculationObjectData
	|			INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(
	|					&Period,
	|					Currency = &ManagementAccountingCurrency
	|						AND BaseCurrency = &LocalAccountingCurrency) AS RelativeCourses
	|			ON (CalculationObjectData.ContractRateOption = VALUE(Enum.ContractRateOptions.Mutable))) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.ARAPObject,
	|	NestedQuery.ARAPCurrency
	|
	|INDEX BY
	|	ARAPObject,
	|	ARAPCurrency";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Private

#Region Posting

// Parameters:
//  Query - Query - Query
// 
// Returns:
//  QueryResultSelection - The details of the document:
// * Ref - DocumentRef.VendorBonusCertificate -
// * Date - Date -
// * Number - String -
// * Period - Date -
// * Organization - CatalogRef.Companies -
// * ARAPCurrency - CatalogRef.Currencies
// * IncomeLiabilityItem - ChartOfCharacteristicTypesRef.IncomeItems, ChartOfCharacteristicTypesRef.AssetLiabilityItems - 
//
Function DocumentAttributes(Query)
	
	Query.Text =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Number AS Number,
	|	DocumentData.Date AS Period,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.IncomeLiabilityItem AS IncomeLiabilityItem
	|FROM
	|	DocumentDataHeader AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Return Attributes;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Attributes =	DocumentAttributes(Query);
	
	For Each KeyAndValue In ValuesOfHoldingParameters(Attributes) Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

// Parameters:
//  Attributes - See DocumentAttributes
// 
// Returns:
//  Structure 
//
Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	
	Values.Insert(
		"MetadataIdentifier",
		Common.MetadataObjectID("Document.VendorBonusCertificate"));
	
	Values.Insert(
		"ManagementAccountingCurrency",
		Constants.ManagementAccountingCurrency.Get());
	
	Values.Insert(
		"UseAccountingOfOtherAssetsAndLiabilities",
		GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities"));
	
	Values.Insert(
		"UseAccountingOfOtherIncomeExpenses",
		GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	
	If Attributes <> Undefined Then
		
		Values.Insert(
			"NumberForPrinting",
			ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
		Values.Insert(
			"LocalAccountingCurrency",
			SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
		
		Values.Insert("Ref", Attributes.Ref);
		Values.Insert("Period", Attributes.Period);
		Values.Insert("Organization", Attributes.Organization);
		Values.Insert("IncomeLiabilityItem", Attributes.IncomeLiabilityItem);
		
	EndIf;
	
	Return Values;
	
EndFunction

Function QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then 
		QueryTextTableTTExchangeRates(Query, QueryTexts, Undefined, DocumentObject);
	EndIf;
	
	QueryText =
	"SELECT
	|	Header.Date AS Period,
	|	Header.BusinessOperation AS BusinessOperation,
	|	Header.Organization AS Organization,
	|	Header.Department AS Department,
	|	CASE
	|		WHEN ISNULL(Header.LineOfBusiness.VendorARAP, FALSE)
	|			THEN Header.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS CounterpartyLineOfBusiness,
	|	Header.Partner AS Partner,
	|	Header.Counterparty AS Counterparty,
	|	Header.Contract AS Contract,
	|	Header.ARAPObject AS ARAPObject,
	|	CASE
	|		WHEN ISNULL(Header.LineOfBusiness.VendorARAP, FALSE)
	|			THEN Header.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusinessItems,
	|	Header.IncomeLiabilityItem AS IncomeAndExpenseItem,
	|	Header.DimensionOfRevenue AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	Header.DimensionOfRevenue AS AssetsLiabilitiesDimension,
	|	CASE
	|		WHEN Header.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN Header.AmountARAP
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyDenominator, 1) / (ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyNumerator, 1)) AS NUMBER(31, 2))
	|	END AS Sum,
	|	0 AS AmountExcludingVAT,
	|	CASE
	|		WHEN Header.ARAPCurrency = &LocalAccountingCurrency
	|			THEN Header.AmountARAP
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) / ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) AS NUMBER(31, 2))
	|	END AS SumCompl,
	|	0 AS LocalAmountExcludingVAT,
	|	Header.ARAPCurrency AS Currency,
	|	Header.AmountARAP AS AmountInCurrency,
	|	0 AS AmountExcludingVATInCurrency,
	|	Header.ARAPCurrency AS ARAPCurrency,
	|	Header.AmountARAP AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|	Header.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	Header.DocumentID AS FinRecordID
	|FROM
	|	Document.VendorBonusCertificate AS Header
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON Header.ARAPCurrency = CurrencyExchangeRate.ARAPCurrency
	|			AND Header.ARAPObject = CurrencyExchangeRate.ARAPObject
	|WHERE
	|	Header.Ref IN(&Ref)";
	
	If DocumentObject <> Undefined Then
		
		QueryText = StrReplace(QueryText, "Document.VendorBonusCertificate", "DocumentDataHeader");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then 
		QueryTextTableTTExchangeRates(Query, QueryTexts, Undefined, DocumentObject);
	EndIf;
	
	QueryText =
	"SELECT
	|	Header.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	Header.Organization AS Organization,
	|	Header.Department AS Department,
	|	CASE
	|		WHEN ISNULL(Header.LineOfBusiness.VendorARAP, FALSE)
	|			THEN Header.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness,
	|	Header.IncomeLiabilityItem AS AssetRef,
	|	Header.AssetsLiabilitiesDimension AS Dimension,
	|	Header.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|	CASE
	|		WHEN Header.ARAPCurrency = &LocalAccountingCurrency
	|			THEN Header.AmountARAP
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) / ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) AS NUMBER(31, 2))
	|	END AS SumCompl,
	|	CASE
	|		WHEN Header.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN Header.AmountARAP
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyDenominator, 1) / (ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyNumerator, 1)) AS NUMBER(31, 2))
	|	END AS SumMan,
	|	CASE
	|		WHEN Header.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN Header.AmountARAP
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyDenominator, 1) / (ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyNumerator, 1)) AS NUMBER(31, 2))
	|	END AS AmountIncludingVAT,
	|	CASE
	|		WHEN Header.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN Header.AmountARAP
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyDenominator, 1) / (ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyNumerator, 1)) AS NUMBER(31, 2))
	|	END AS AmountExcludingVAT,
	|	Header.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RecordVendorBonusRebate) AS BusinessTransactionSetting
	|FROM
	|	Document.VendorBonusCertificate AS Header
	|		INNER JOIN ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
	|		ON Header.IncomeLiabilityItem = AssetLiabilityItems.Ref
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON Header.ARAPCurrency = CurrencyExchangeRate.ARAPCurrency
	|			AND Header.ARAPObject = CurrencyExchangeRate.ARAPObject
	|WHERE
	|	&UseAccountingOfOtherAssetsAndLiabilities
	|	AND Header.Ref IN (&Ref)";
	
	If DocumentObject <> Undefined Then
		
		QueryText = StrReplace(QueryText, "Document.VendorBonusCertificate", "DocumentDataHeader");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS IBDocumentDate,
	|	DocumentData.Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS StorageLocation,
	|	DocumentData.Department AS Department,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	CAST(DocumentData.Comment AS STRING(100)) AS Comment,
	|	DocumentData.ARAPCurrency AS Currency,
	|	DocumentData.AmountARAP AS Sum,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	"""" AS More,
	|	DocumentData.IncomingDocumentDate  AS SourceDocumentDate,
	|	DocumentData.IncomingDocumentNumber AS SourceDocumentNumber,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.VendorBonusCertificate AS DocumentData
	|WHERE
	|	DocumentData.Ref IN (&Ref)";
	
	If DocumentObject <> Undefined Then
		
		QueryText = StrReplace(QueryText, "Document.VendorBonusCertificate", "DocumentDataHeader");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableVendorRebates(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "VendorRebates";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(Enum.AccumulationRecordTypes.Expense) AS TypeOfRegisterMovement,
	|	HeaderData_.Date AS Period,
	|	HeaderData_.Organization AS Organization,
	|	HeaderData_.Counterparty AS Counterparty,
	|	TableData.Partner AS Partner,
	|	TableData.Contract AS Contract,
	|	TableData.BeginOfPeriod AS BeginOfPeriod,
	|	TableData.PeriodEnding AS PeriodEnding,
	|	TableData.TermDocument AS TermDocument,
	|	TableData.BonusCurrency AS Currency,
	|	0 AS Accrued,
	|	0 AS ToWriteOff,
	|	0 AS WrittenOff,
	|	TableData.BonusAmount AS Certified
	|FROM
	|	DocumentDataRebates AS TableData
	|		LEFT JOIN DocumentDataHeader AS HeaderData_
	|		ON TableData.Ref = HeaderData_.Ref
	|WHERE
	|	TableData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTDataOfCalculationObjects(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "TTDataOfCalculationObjects";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ARAPObjects.Ref AS ARAPObject,
	|	ARAPObjects.Object AS Object,
	|	ARAPObjects.Contract AS Contract,
	|	Header.ARAPCurrency AS ARAPCurrency,
	|	CASE
	|		WHEN ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|				AND ISNULL(ARAPObjects.Contract.ContractRateOption, VALUE(Enum.ContractRateOptions.Mutable)) = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|			THEN VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|		ELSE ISNULL(ARAPObjects.Contract.ContractRateOption, VALUE(Enum.ContractRateOptions.Mutable))
	|	END AS ContractRateOption
	|INTO TTDataOfCalculationObjects
	|FROM
	|	DocumentDataHeader AS Header
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON Header.ARAPObject = ARAPObjects.Ref
	|WHERE
	|	Header.Ref IN(&Ref)";
	
	If DocumentObject = Undefined Then
		
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.CustomerBonusCertificate");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableVendorsARAPAccounting(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "VendorsARAPAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then 
		QueryTextTableTTExchangeRates(Query, QueryTexts, Undefined, DocumentObject);
	EndIf;
	
	QueryText =
	"SELECT
	|	Header.Date AS Period,
	|	Header.Date AS RecorderDate,
	|	Header.Number AS RecorderNumber,
	|	DATETIME(1, 1, 1) AS PaymentDate,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|	Header.Organization AS Organization,
	|	Header.Counterparty AS Counterparty,
	|	Header.Partner AS Partner,
	|	Header.Contract AS Contract,
	|	CASE WHEN ISNULL(Header.LineOfBusiness.VendorARAP, FALSE)
	|					AND NOT ISNULL(Header.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness, TRUE)
	|			THEN Header.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness,
	|	Header.ARAPObject AS ARAPObject,
	|	Header.ARAPCurrency AS Currency,
	|	Header.AmountARAP AS Sum,
	|	Header.AmountARAP AS AmountDue,
	|	CASE
	|		WHEN Header.ARAPCurrency = &LocalAccountingCurrency
	|			THEN Header.AmountARAP
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) / ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) AS NUMBER(31, 2))
	|	END AS SumCompl,
	|	CASE
	|		WHEN Header.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN Header.AmountARAP
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyDenominator, 1) / (ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyNumerator, 1)) AS NUMBER(31, 2))
	|	END AS SumMan,
	|	VALUE(Enum.SettlementOperations.ARAPAdjustment) AS SettlementTransaction,
	|	Header.BusinessOperation AS BusinessOperation,
	|	VALUE(Enum.PaymentForms.EmptyRef) AS PaymentMethod,
	|	VALUE(Catalog.Currencies.EmptyRef) AS DocumentCurrency,
	|	TRUE AS ExcludeDuringControl,
	|	Header.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RecordVendorBonusRebate) AS BusinessTransactionSetting,
	|	CASE WHEN Header.ARAPCurrency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1)
	|	END AS RateARAPCurrencyNumerator,
	|	CASE WHEN Header.ARAPCurrency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1)
	|	END AS RateARAPCurrencyDenominator,
	|	CASE WHEN Header.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN 0
	|		ELSE ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyNumerator, 1)
	|	END AS ExchangeRateNumeratorOfManSCurrency,
	|	CASE WHEN Header.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN 0
	|		ELSE ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyDenominator, 1)
	|	END AS ExchangeRateDenominatorCurrencyMan,
	|	4 AS TypeOfOperationForSorting,
	|	1 AS OrderOfOperationsWithinDocument
	|FROM
	|	Document.VendorBonusCertificate AS Header
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON Header.Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND Header.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|			AND Header.Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND Header.Contract = RegisterAccountingAnalyticsForPartners.Contract
	|			AND CASE WHEN ISNULL(Header.LineOfBusiness.VendorARAP, FALSE)
	|						AND NOT ISNULL(Header.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness, TRUE)
	|					THEN Header.LineOfBusiness
	|				ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			END = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON Header.ARAPCurrency = CurrencyExchangeRate.ARAPCurrency
	|			AND Header.ARAPObject = CurrencyExchangeRate.ARAPObject
	|WHERE
	|	Header.Ref IN(&Ref)
	|	AND ISNULL(Header.LineOfBusiness.VendorARAP, FALSE)
	|	AND NOT ISNULL(Header.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness, TRUE)
	|
	|UNION ALL
	|
	|SELECT
	|	Header.Date AS Period,
	|	Header.Date AS RecorderDate,
	|	Header.Number AS RecorderNumber,
	|	DATETIME(1, 1, 1) AS PaymentDate,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|	Header.Organization AS Organization,
	|	Header.Counterparty AS Counterparty,
	|	Header.Partner AS Partner,
	|	Header.Contract AS Contract,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	Header.ARAPObject AS ARAPObject,
	|	Header.ARAPCurrency AS Currency,
	|	Header.AmountARAP AS Sum,
	|	Header.AmountARAP AS ToReceive,
	|	CASE
	|		WHEN Header.ARAPCurrency = &LocalAccountingCurrency
	|			THEN Header.AmountARAP
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) / ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) AS NUMBER(31, 2))
	|	END AS SumCompl,
	|	CASE
	|		WHEN Header.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN Header.AmountARAP
	|		WHEN &LocalAccountingCurrency = &ManagementAccountingCurrency
	|			THEN CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyNumerator, 1) / ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyDenominator, 1) AS NUMBER(31, 2))
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyDenominator, 1) / (ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyNumerator, 1)) AS NUMBER(31, 2))
	|	END AS SumMan,
	|	VALUE(Enum.SettlementOperations.ARAPAdjustment) AS SettlementTransaction,
	|	Header.BusinessOperation AS BusinessOperation,
	|	VALUE(Enum.PaymentForms.EmptyRef) AS PaymentMethod,
	|	VALUE(Catalog.Currencies.EmptyRef) AS DocumentCurrency,
	|	TRUE AS ExcludeDuringControl,
	|	Header.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RecordVendorBonusRebate) AS BusinessTransactionSetting,
	|	CASE WHEN Header.ARAPCurrency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1)
	|	END AS RateARAPCurrencyNumerator,
	|	CASE WHEN Header.ARAPCurrency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1)
	|	END AS RateARAPCurrencyDenominator,
	|	CASE WHEN Header.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN 0
	|		ELSE ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyNumerator, 1)
	|	END AS ExchangeRateNumeratorOfManSCurrency,
	|	CASE WHEN Header.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN 0
	|		ELSE ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyDenominator, 1)
	|	END AS ExchangeRateDenominatorCurrencyMan,
	|	4 AS TypeOfOperationForSorting,
	|	1 AS OrderOfOperationsWithinDocument
	|FROM
	|	Document.VendorBonusCertificate AS Header
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON Header.Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND Header.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|			AND Header.Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND Header.Contract = RegisterAccountingAnalyticsForPartners.Contract
	|			AND  RegisterAccountingAnalyticsForPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON Header.ARAPCurrency = CurrencyExchangeRate.ARAPCurrency
	|			AND Header.ARAPObject = CurrencyExchangeRate.ARAPObject
	|WHERE
	|	Header.Ref IN(&Ref)
	|	AND (NOT ISNULL(Header.LineOfBusiness.VendorARAP, FALSE)
	|		OR ISNULL(Header.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness, TRUE))";
	
	If DocumentObject <> Undefined Then
		
		QueryText = StrReplace(QueryText, "Document.VendorBonusCertificate", "DocumentDataHeader");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then 
		QueryTextTableTTExchangeRates(Query, QueryTexts, Undefined, DocumentObject);
	EndIf;
	
	QueryText =
	"SELECT
	|	Header.Date AS Period,
	|	Header.Organization AS Organization,
	|	Header.Department AS Department,
	|	CASE
	|		WHEN ISNULL(Header.LineOfBusiness.VendorARAP, FALSE)
	|			THEN Header.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness,
	|	Header.IncomeLiabilityItem AS IncomeItem,
	|	Header.DimensionOfRevenue AS DimensionOfRevenue,
	|	Header.BusinessOperation AS BusinessOperation,
	|	CASE
	|		WHEN Header.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN Header.AmountARAP
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyDenominator, 1) / (ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyNumerator, 1)) AS NUMBER(31, 2))
	|	END AS Sum,
	|	CASE
	|		WHEN NOT &CompanyManagementAccounting
	|			THEN 0
	|		WHEN Header.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN Header.AmountARAP
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyDenominator, 1) / (ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyNumerator, 1)) AS NUMBER(31, 2))
	|	END AS SumMan,
	|	CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN 0
	|		WHEN Header.ARAPCurrency = &LocalAccountingCurrency
	|			THEN Header.AmountARAP
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) / ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) AS NUMBER(31, 2))
	|	END AS SumCompl,
	|	Header.DocumentID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RecordVendorBonusRebate) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.VendorBonusCertificate AS Header
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON Header.ARAPCurrency = CurrencyExchangeRate.ARAPCurrency
	|			AND Header.ARAPObject = CurrencyExchangeRate.ARAPObject
	|	
	|WHERE
	|	&UseAccountingOfOtherIncomeExpenses
	|	AND Header.IncomeLiabilityItem REFS ChartOfCharacteristicTypes.IncomeItems";
	
	If DocumentObject <> Undefined Then
		
		QueryText = StrReplace(QueryText, "Document.VendorBonusCertificate", "DocumentDataHeader");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then 
		QueryTextTableTTExchangeRates(Query, QueryTexts, Undefined, DocumentObject);
	EndIf;
	
	QueryText =
	"SELECT
	|	Header.Date AS Period,
	|	VALUE(AccumulationRecordType.Expense)  AS RecordType,
	|	Header.Organization AS Organization,
	|	Header.Department AS Department,
	|	CASE
	|		WHEN ISNULL(Header.LineOfBusiness.VendorARAP, FALSE)
	|			THEN Header.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness,
	|	Header.IncomeLiabilityItem AS AssetRef,
	|	CASE
	|		WHEN Header.AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE Header.AssetsLiabilitiesDimension
	|	END AS Dimension,
	|	CASE
	|		WHEN Header.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN Header.AmountARAP
	|		ELSE CAST(Header.AmountARAP * ISNULL(CurrencyExchangeRate.RateARAPCurrencyNumerator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyDenominator, 1) / (ISNULL(CurrencyExchangeRate.RateARAPCurrencyDenominator, 1) * ISNULL(CurrencyExchangeRate.RateManagementAccountingCurrencyNumerator, 1)) AS NUMBER(31, 2))
	|	END AS Sum
	|FROM
	|	Document.VendorBonusCertificate AS Header
	|		LEFT JOIN TTExchangeRates AS CurrencyExchangeRate
	|		ON Header.ARAPCurrency = CurrencyExchangeRate.ARAPCurrency
	|			AND Header.ARAPObject = CurrencyExchangeRate.ARAPObject
	|WHERE
	|	&UseAccountingOfOtherAssetsAndLiabilities
	|	AND Header.IncomeLiabilityItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems";
	
	If DocumentObject <> Undefined Then
		
		QueryText = StrReplace(QueryText, "Document.VendorBonusCertificate", "DocumentDataHeader");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#Region DocumentData

Procedure GetDocumentData(Query, DocumentRef)
	
	ListOfRequests = New Array; // Array of String
	
	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDataTableRetroBonuses(ListOfRequests);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Number AS Number,
	|	DocumentData.IncomingDocumentDate AS IncomingDocumentDate,
	|	DocumentData.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Department AS Department,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.DocumentID AS DocumentID,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	DocumentData.IncomeLiabilityItem AS IncomeLiabilityItem,
	|	DocumentData.DimensionOfRevenue AS DimensionOfRevenue,
	|	DocumentData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.GLAccountSettings AS GLAccountSettings
	|INTO DocumentDataHeader
	|FROM
	|	Document.VendorBonusCertificate AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&Ref)
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDataTableRetroBonuses(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DataTable.Ref AS Ref,
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.TermDocument AS TermDocument,
	|	DataTable.Partner AS Partner,
	|	DataTable.Contract AS Contract,
	|	DataTable.BeginOfPeriod AS BeginOfPeriod,
	|	DataTable.PeriodEnding AS PeriodEnding,
	|	DataTable.BonusCurrency AS BonusCurrency,
	|	DataTable.BonusAmount AS BonusAmount,
	|	DataTable.AmountARAP AS AmountARAP
	|INTO DocumentDataRebates
	|FROM
	|	Document.VendorBonusCertificate.Rebates AS DataTable
	|WHERE
	|	DataTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#EndIf
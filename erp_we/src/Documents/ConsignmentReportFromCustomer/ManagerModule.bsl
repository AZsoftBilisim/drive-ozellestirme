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
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("HandoverForSafekeeping");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AccountingOfWorks");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	
	ConsignmentReportFromCustomerLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

#EndRegion

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);
	
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
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "OperationService, CommissionFeeCalculationMethod");
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "VATRateOfRemuneration", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "CommissionFeeCalculationMethod";
	Parameters.FillInIf.ObjectFieldsFilledIn = "CommissionFeeCalculationMethod";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "RemunerationPercentage", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"ExternalDocumentName", Parameters);	
EndProcedure

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
	
	Documents.IssuedLetterOfAuthority.AddGenerateCommand(GenerationCommands);
	
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.CustomerCommercialInvoice.AddCreateBasedOnInvoiceCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	ConsignmentReportFromCustomerLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "sales agent Report".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.ConsignmentReportFromCustomer) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ConsignmentReportFromCustomer.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ConsignmentReportFromCustomer);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseSalesCommission";
	

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
	
	Reports.StateOfSettlementsWithCommissionAgents.AddReportCommand(ReportsCommands);
	
	Reports.GoodsTransferredToCommissionAgent.AddReportCommand(ReportsCommands);
	
	Reports.GoodsTransferredToCommissionAgent2_5.AddReportCommand(ReportsCommands);
	
	ConsignmentReportFromCustomerLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// The procedure fills in arrays of details that depend on the business operation of the document.
//
// Parameters:
// 	CommissionFeeCalculationMethod - EnumRef.CommissionFeeCalculationMethods
//	Hozyaystvennaya Perechislennye.Business operations - Selected business operation
//	ArrayOfAllProps - Array - Array of all names of banking details that depend on the business operation
//	ArrayOfOperationDetails - Array - Array of names of Bank details used in the selected business operation
//	SelfService - Boolean - Flag for calling from a self-service form
//
Procedure FillInNamesOfBusinessTransactionDetails(CommissionFeeCalculationMethod, ArrayOfAllProps, ArrayOfOperationDetails, SelfService = False) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("RemunerationPercentage");
	ArrayOfAllProps.Add("CommissionAmount");
	ArrayOfAllProps.Add("Goods.CommissionAmount");
	If Not SelfService Then
		ArrayOfAllProps.Add("VATRateOfRemuneration");
		ArrayOfAllProps.Add("AmountVATRemuneration");
		ArrayOfAllProps.Add("KeepCommissionFee");
		ArrayOfAllProps.Add("OperationService");
		ArrayOfAllProps.Add("PaymentDate");
		ArrayOfAllProps.Add("ExpenseItem");
	EndIf;
	
	ArrayOfOperationDetails = New Array;
	If CommissionFeeCalculationMethod <> Enums.CommissionFeeCalculationMethods.NotCalculating Then
		
		ArrayOfOperationDetails.Add("RemunerationPercentage");
		ArrayOfOperationDetails.Add("CommissionAmount");
		ArrayOfOperationDetails.Add("Goods.CommissionAmount");
		If Not SelfService Then
			ArrayOfOperationDetails.Add("VATRateOfRemuneration");
			ArrayOfOperationDetails.Add("AmountVATRemuneration");
			ArrayOfOperationDetails.Add("KeepCommissionFee");
			ArrayOfOperationDetails.Add("OperationService");
			ArrayOfOperationDetails.Add("PaymentDate");
			ArrayOfOperationDetails.Add("ExpenseItem");
		EndIf;
		
	EndIf;
	
EndProcedure

// The function defines the partner specified in the document.
//
// Parameters:
//  DocumentRef - DocumentRef.ConsignmentReportFromCustomer - Link to the document.
//
// Returns:
//	Structure - Partner of the selected document.
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
	|	Document.ConsignmentReportFromCustomer AS DocumentData
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
		CommissionAmount = ?(Selection.Posted, Selection.CommissionAmount, 0);
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
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("Contract", Contract);
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	AttributesStructure1.Insert("SettlementsUnderContract", ARAPObjectSettings);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", Enums.BusinessTransactions.ConsignmentReportFromCustomer);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP);
	AttributesStructure1.Insert("CommissionAmount", CommissionAmount);
	AttributesStructure1.Insert("BeginOfPeriod", BeginOfPeriod);
	AttributesStructure1.Insert("EndOfPeriod", EndOfPeriod);
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	
	Return AttributesStructure1;

EndFunction

// The function returns the structure of the significant details of the document
//
// Returns:
//	Structure - Details of the document.
//
Function StructureOfMeaningfulProps() Export
	
	Return New Structure("
		|Partner,
		|Counterparty,
		|Contract,
		|Organization,
		|Terms,
		|Currency,
		|Department,
		|VATTaxation,
		|PriceIncludesVAT,
		|LineOfBusiness
		|");
	
EndFunction

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.ConsignmentReportFromCustomer - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Contract = Object.Contract;
	FillParameters.LineOfBusiness = Object.LineOfBusiness;
	FillParameters.ConsignmentReportFromCustomer = True;
	
	Return FillParameters;
	
EndFunction

Function ParametersForRegisteringInvoicesToCommissionAgent(Document) Export
	
	Attributes = New Structure("Ref, Date, Counterparty, Organization, VATTaxation, BusinessOperation");		
	
	If TypeOf(Document) = Type("DocumentRef.ConsignmentReportFromCustomer") Then		
		Attributes = Common.ObjectAttributesValues(Document, Attributes);
	Else		
		FillPropertyValues(Attributes, Document);	
	EndIf;
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesToCommissionAgent();
	RegistrationParameters.Ref = Attributes.Ref;
	RegistrationParameters.Organization = Attributes.Organization;
	RegistrationParameters.Counterparty = Attributes.Counterparty;
	RegistrationParameters.VATTaxation = Attributes.VATTaxation;
	
	RegistrationParameters.SalesViaCommissionAgent =
		ConsignmentSalesServer.SalesViaCommissionAgent(Attributes.BusinessOperation);
	RegistrationParameters.Date					= Attributes.Date;
	RegistrationParameters.GoodsSales = True;
	RegistrationParameters.ImplementationOfWorksServices = True;
	
	Return RegistrationParameters;
	
EndFunction

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'Bảng kê hàng bán của người nhận ký gửi';
							|ru = 'Отчет комиссионера';
							|en = 'Consignment issue notification'; fa = 'اعلان صدور امانی';
							|it = 'Report del commissionario';
							|pl = 'Raport komisanta';
							|tr = 'Konsinye raporu'"));
	ConsignmentReportFromCustomerLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	Return ArrayOfNames
EndFunction

// Generates a formatted string to go to the list of commission agents' reports from the forms of document logs
//
// Parameters:
//  Parameters - Structure 
// 
// Returns:
// 	FormattedString 
//
Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	If Not AccessRight("Update", Metadata.Documents.ConsignmentReportFromCustomer) Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Bảng kê hàng bán của người nhận ký gửi';
						|ru = 'Отчеты комиссионеров';
						|en = 'Consignment issue notifications'; fa = 'اعلامیه‌های ارسال امانی';
						|it = 'report dei commissionari';
						|pl = 'Raporty komisantów';
						|tr = 'Konsinye raporları'");
	
	Return New FormattedString(HyperlinkText,,,,"Document.ConsignmentReportFromCustomer.Form.ListForm");
	
EndFunction

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return ConsignmentReportFromCustomerLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return ConsignmentReportFromCustomerLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction
#Region VATAccounting

// Initializes parameters for registering invoices (received)
//
// Parameters:
//  Object		- DocumentObject.ConsignmentReportFromCustomer, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived
//
Function ParametersForRegisteringInvoicesReceived(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	
	RegistrationParameters.Ref				= Object.Ref;
	RegistrationParameters.Date				= Object.Date;
	RegistrationParameters.Organization		= Object.Organization;
	RegistrationParameters.Counterparty			= Object.Counterparty;
	RegistrationParameters.VATTaxation	= Object.VATTaxation;
	
	RegistrationParameters.PurchaseOfGoodsWorksServices = True;	
	
	Return RegistrationParameters;
	
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
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Department)";
	
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
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		Return ParametersMutualSettlementsSelfService(FillingData);
	EndIf;
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"KeepCommissionFee,
			|BusinessOperation,
			|CommissionFeeCalculationMethod");
		KeepCommissionFee = StructureFillingData.KeepCommissionFee;
		BusinessOperation  = StructureFillingData.BusinessOperation;
		RemunerationCalculation   = StructureFillingData.CommissionFeeCalculationMethod <> Enums.CommissionFeeCalculationMethods.NotCalculating;
	ElsIf FillingData = Undefined Then
		KeepCommissionFee = False;
		BusinessOperation  = Enums.BusinessTransactions.EmptyRef();
		RemunerationCalculation   = False;
	Else
		KeepCommissionFee = FillingData.KeepCommissionFee;
		BusinessOperation  = FillingData.BusinessOperation;
		RemunerationCalculation   = FillingData.CommissionFeeCalculationMethod <> Enums.CommissionFeeCalculationMethods.NotCalculating;
	EndIf;
	
	InfluencingAttributes = "KeepCommissionFee,BusinessOperation,CommissionFeeCalculationMethod";
	
	StructuresArray = New Array;
	
	#Region ConsignmentReportFromCustomer
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	ParametersStructure.PropsNameTSAmountWithVAT          = "SalesAmount";
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetailsWithCustomer";
	
	ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
	
	ParametersStructure.FormItems.InscriptionStages       = "DecorationPaymentSteps";
	ParametersStructure.FormItems.PaymentSettlement        = "CreditPaymentForm";
	ParametersStructure.FormItems.FinancialAccountingGroup  = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	//Function Payment stages and payment date
	ParametersStructure.PathToTSDataPaymentSteps         = "Object.PaymentScheduleSteps";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStepsText";
	ParametersStructure.PaymentSchedule                     = "Object.PaymentSchedule";
	ParametersStructure.NoPrepaymentControl            = True;
	
	If BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent Then
		ParametersStructure.CommissionAgentSAgreement          = "Object.Contract";
	EndIf;
	
	ParametersStructure.InfluencingAttributes = InfluencingAttributes;
	
	StructuresArray.Add(ParametersStructure);
	
	#EndRegion
	
	#Region Remuneration
	
	If RemunerationCalculation Then
			
		ParametersStructure = ARAPAccountingServer.MechanismParameters();
		ParametersStructure.ThisIsSalePurchase                = True;
		ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
		If GetFunctionalOption("NewOnlineARAPAccounting") Then
			ParametersStructure.ARAPObjectSettings              = Enums.ARAPObjectSettings.ByARAPDocuments;
			ParametersStructure.FinancialAccountingGroup       = "Object.Contract.FinancialAccountingGroup";
		Else
			ParametersStructure.ChangesPaymentPlan           = Not KeepCommissionFee;
			ParametersStructure.ModifiesDeliveryShipmentPlan = Not KeepCommissionFee;
		EndIf;
		
		ParametersStructure.DocumentAmount                   = "Object.CommissionAmount";
		ParametersStructure.PaymentDate                      = "Object.PaymentDate";
		
		ParametersStructure.CourseNumerator                    = "";
		ParametersStructure.CourseDenominator                  = "";
		
		ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetailsWithVendor";
		
		ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
		ParametersStructure.CounterpartyBankAccount        = "";
		ParametersStructure.Manager                         = "Object.Manager";
		ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
		ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
		ParametersStructure.ARAPObject                   = "Object.ARAPObjectRemuneration";
		ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
			
		ParametersStructure.FormItems.PaymentSettlement        = "PaymentOffsetByRemuneration";
		
		ParametersStructure.KeepCommissionFee           = KeepCommissionFee;
		
		ParametersStructure.InfluencingAttributes = InfluencingAttributes;
		
		StructuresArray.Add(ParametersStructure);
		
	EndIf;
	
	#EndRegion
	
	Return StructuresArray;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters - Array of parameters of the functions of the settlement mechanism.
//
Function ParametersMutualSettlementsSelfService(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"KeepCommissionFee");
		KeepCommissionFee = StructureFillingData.KeepCommissionFee;
	ElsIf FillingData = Undefined Then
		KeepCommissionFee = False;
	Else
		KeepCommissionFee = FillingData.KeepCommissionFee;
	EndIf;
	
	StructuresArray = New Array;
	
	#Region ConsignmentReportFromCustomer
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	ParametersStructure.PropsNameTSAmountWithVAT          = "SalesAmount";
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetailsWithCustomer";
	
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
		
	ParametersStructure.FormItems.InscriptionStages       = "DecorationPaymentSteps";
	
	//Function Payment stages and payment date
	ParametersStructure.PathToTSDataPaymentSteps         = "Object.PaymentScheduleSteps";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStepsText";
	ParametersStructure.PaymentSchedule                     = "Object.PaymentSchedule";
	ParametersStructure.DoNotSpecifyPaymentSources       = True;
	
	StructuresArray.Add(ParametersStructure);
	
	#EndRegion
	
	#Region Remuneration
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	ParametersStructure.ChangesPaymentPlan               = Not KeepCommissionFee;
	ParametersStructure.ModifiesDeliveryShipmentPlan     = Not KeepCommissionFee;
	
	ParametersStructure.DocumentAmount                   = "Object.CommissionAmount";
	
	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetailsWithVendor";
	
	ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.ARAPObject                   = "Object.ARAPObjectRemuneration";
	ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
		
	ParametersStructure.FormItems.PaymentSettlement        = "PaymentOffsetByRemuneration";
	
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

// Creates a representation of the metadata object in the main language.
// 
// Returns:
//  String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	SynonymForInformationDatabaseEntry = NStr(
		"ru = 'Отчет комиссионера';
		|vi = 'Consignment issue notification';
		|en = 'Consignment issue notification'; fa = 'اعلان صدور امانی';
		|it = 'Report del commissionario';
		|pl = 'Raport komisanta';
		|tr = 'Konsinye raporu'",
		DefaultLanguageCode);
		
	Return SynonymForInformationDatabaseEntry;
	
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		StandardProcessing = False;
		If FormType = "ObjectForm" Then
			SelectedForm = "SelfServiceWorkplaceDocumentForm";
		ElsIf FormType = "ListForm" Then
			SelectedForm = "SelfServiceWorkplaceListForm";
		EndIf;
	EndIf;
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "ConsignmentReportFromCustomer");
	
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
	
	If TypeOf(Document) = Type("DocumentObject.ConsignmentReportFromCustomer") Then
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
		
		QueryTextTableGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers);
		QueryTextTableServicesForRegistrationOfReportsToPrincipal(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
		ConsignmentReportFromCustomerLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Number AS Number,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Terms AS Terms,
	|	DocumentData.Department AS Department,
	|	DocumentData.Department.OptionOfAssignedAccountingOfGoods AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.OperationService AS Products,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Manager AS Manager,
	|	DocumentData.Author AS Author,
	|	CASE WHEN DocumentData.EndOfPeriod = DATETIME(1, 1, 1)
	|			OR DocumentData.EndOfPeriod > DocumentData.Date
	|			OR BEGINOFPERIOD(DocumentData.EndOfPeriod, MONTH) < BEGINOFPERIOD(DocumentData.Date, MONTH)
	|			THEN DocumentData.Date
	|		ELSE
	|			DocumentData.EndOfPeriod
	|	END AS EndOfPeriod,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.KeepCommissionFee AS KeepCommissionFee,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.ExternalDocumentName AS ExternalDocumentName,
	|	DocumentData.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	DocumentData.IncomingDocumentDate AS IncomingDocumentDate,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	DocumentData.ARAPObject.UUID AS IDARAPObject,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.ARAPObjectRemuneration AS ARAPObjectRemuneration,
	|	DocumentData.ARAPObjectRemuneration.UUID AS IDARAPObjectReward,
	|	UNDEFINED AS AdjustmentPeriod_
	|FROM
	|	Document.ConsignmentReportFromCustomer AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("Ref", DocumentRef);
	Query.SetParameter("EndOfPeriod", EndOfDay(Attributes.EndOfPeriod));
	Query.SetParameter("ARAPCurrency", Attributes.Currency);
	Query.SetParameter("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.ConsignmentReportFromCustomer);
	Query.SetParameter("BusinessOperationRetention", Enums.BusinessTransactions.CommissionAgentSRemunerationDeduction);
	Query.SetParameter("Contract", Attributes.Contract);
	Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("UseAgentServiceSale", GetFunctionalOption("UseAgentServiceSale"));
	Query.SetParameter("ARAPObject", Attributes.ARAPObject);
	Query.SetParameter("Comment", Attributes.Comment);
	Query.SetParameter("DocumentAmount", Attributes.DocumentAmount);
	Query.SetParameter("Posted", Attributes.Posted);
	Query.SetParameter("DeletionMark", Attributes.DeletionMark);
	Query.SetParameter("ExternalDocumentName", Attributes.ExternalDocumentName);
	Query.SetParameter("IncomingDocumentNumber", Attributes.IncomingDocumentNumber);
	Query.SetParameter("IncomingDocumentDate", Attributes.IncomingDocumentDate);
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("NewOnlineARAPAccounting", GetFunctionalOption("NewOnlineARAPAccounting"));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
		
	Query.SetParameter("Ref", DocumentRef);
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = "
	|SELECT
	|	SeriesTable.Products         AS Products,
	|	SeriesTable.Characteristic       AS Characteristic,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	SeriesTable.Series                AS Series,
	|	SeriesTable.Count           AS Count,
	|	&Partner                          AS Sender,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS WareroomOfSender,
	|	UNDEFINED                            AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS WareroomOfRecipient,
	|	VALUE(Enum.WarehouseTransactions.ShipmentToCustomer) AS WarehouseOperation,
	|	&Ref                           AS Document,
	|	&Period                           AS Period,
	|	&Ref                           AS Recorder,
	|	TRUE AS ThisIsWarehouseRecord
	|FROM
	|	Document.ConsignmentReportFromCustomer.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	VALUE(Catalog.Assignments.EmptyRef),
	|	GoodsTable.Series,
	|	GoodsTable.Count,
	|	&Partner,
	|	VALUE(Catalog.Warerooms.EmptyRef),
	|	UNDEFINED AS Warehouse,
	|	VALUE(Catalog.Warerooms.EmptyRef),
	|	VALUE(Enum.WarehouseTransactions.ShipmentToCustomer),
	|	&Ref,
	|	&Period,
	|	&Ref,
	|	TRUE
	|FROM
	|	Document.ConsignmentReportFromCustomer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Count <> 0
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeProductAccountingAnalyticsKeys(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber						AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)				AS RecordType,
	|	&Period												AS Period,
	|	&Organization										AS Organization,
	|	TableTypesOfStocks_.Currency							AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CommitteeAnalytics				AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Products						AS Products,
	|	TableTypesOfStocks_.Characteristic					AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber							AS CCDNumber,
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)	AS BusinessOperation,
	|	TableTypesOfStocks_.DateOfTaxInvoiceIssuedByCommissionAgent		AS TaxInvoiceDate,
	|	TableTypesOfStocks_.CommissionAgentSTaxInvoiceNumber	AS TaxInvoiceNumber,
	|	TableTypesOfStocks_.Customer						AS Customer,
	|	TableTypesOfStocks_.Count						AS Count,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.Currency = &Currency
	|			THEN TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END												AS RevenueAmount,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN TableTypesOfStocks_.AmountIncludingVATCompl
	|		ELSE 0
	|	END AS RevenueAmountExclVATLocal,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END AS RevenueAmountMan,
	|	TableTypesOfStocks_.Count						AS QuantityToRegister,
	|	TableTypesOfStocks_.QuantityByGBRN					AS QuantityForRegistrationByProductBatchID,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.Currency = &Currency
	|			THEN TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END												AS RevenueAmountToRegister,
	|	&IDARAPObject						AS FinRecordID,
	|	&BusinessTransactionSetting						AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID AS RowID
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN TTExchangeRates AS ExchangeRates
	|		ON TableTypesOfStocks_.Currency = ExchangeRates.Currency
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
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	SetRequestParametersCurrencyCoefficients(Query);
	SetParameterForPartnerAccountingAnalyticsRequest(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	(CASE
	|		WHEN &BatchAccountingVersion22 THEN &Period
	|		ELSE &EndOfPeriod END) AS Period,
	|	&Department AS Department,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|	END AS AccountingSection,
	|	TableTypesOfStocks_.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	(CASE
	|		WHEN &BatchAccountingVersion22 THEN TableTypesOfStocks_.VATActivityType
	|		ELSE UNDEFINED END) AS VATActivityType,
	|
	|	&Manager AS Manager,
	|
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS ProductLineOfBusiness,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|		CAST(TableTypesOfStocks_.AmountIncludingVAT * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END AS Cost,
	|
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|		CAST((TableTypesOfStocks_.AmountIncludingVAT
	|			-TableTypesOfStocks_.VATAmount) 
	|			* &ConversionRateToManCurrency AS NUMBER(31,2)) 
	|	ELSE
	|		0
	|	END AS CostExcludingVAT,
	|
	|	CASE WHEN &CompanyManagementAccounting
	|	 AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|		CAST((TableTypesOfStocks_.AmountIncludingVAT
	|			-TableTypesOfStocks_.VATAmount) 
	|			* &ConversionRateToManCurrency AS NUMBER(31,2)) 
	|	ELSE
	|		0
	|	END AS CostMan,
	|
	|	CAST(
	|		(CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount
	|			ELSE 0
	|		END
	|		+ CASE WHEN &BatchAccountingVersion22
	|			THEN 0
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			THEN TableTypesOfStocks_.CommissionAmount
	|		ELSE TableTypesOfStocks_.CommissionAmount - TableTypesOfStocks_.AmountVATRemuneration
	|		END) * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalCost,
	|
	|	TableTypesOfStocks_.Count AS Count,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, CAST(TableTypesOfStocks_.AmountIncludingVAT
	|		* &ConversionRateToManCurrency AS NUMBER(31,2))) AS RevenueAmount,
	|
	|	ISNULL(Amounts.AmountExcludingVATMan, CAST((TableTypesOfStocks_.AmountIncludingVAT
	|		-TableTypesOfStocks_.VATAmount) 
	|		* &ConversionRateToManCurrency AS NUMBER(31,2))) AS RevenueAmountExcludingVAT,
	|
	|	ISNULL(Amounts.AmountExcludingVATCompl, CAST((TableTypesOfStocks_.AmountIncludingVAT
	|		-TableTypesOfStocks_.VATAmount) 
	|		* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS RevenueAmountExclVATLocal,
	|
	|	ISNULL(Amounts.AmountIncludingVATCompl, CAST(TableTypesOfStocks_.AmountIncludingVAT
	|		* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS RevenueAmountIncludingVATLocal,
	|
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|	0 AS AddExpensesLocal,
	|	0 AS AddExpensesMan,
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|
	|	0 AS SellingExpensesIncludingVAT,
	|	0 AS SellingExpensesExcludingVAT,
	|	0 AS SellingExpensesLocal,
	|	0 AS SellingExpensesMan,
	|
	|	&Partner AS Warehouse,
	|	&Contract AS Contract,
	|	&Terms AS Terms,
	|
	|	&Currency AS ARAPCurrency,
	|	ISNULL(Amounts.AmountARAP, TableTypesOfStocks_.AmountIncludingVAT) AS AmountInARAPCurrency,
	|	ISNULL(Amounts.AmountARAP - Amounts.AmountVATARAP, TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount) AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer) AS BusinessOperation,
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		TableTypesOfStocks_.InventoryOwnerAttribute
	|	ELSE
	|		TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|
	|	&ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.VATRate           AS VATRate
	|	
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = &Ref
	|		AND Amounts.RowID = TableTypesOfStocks_.RowID
	|WHERE
	|	NOT TableTypesOfStocks_.ThisIsTraceableWork
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	(CASE
	|		WHEN &BatchAccountingVersion22 THEN &Period
	|		ELSE &EndOfPeriod END) AS Period,
	|	&Department AS Department,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|	END AS AccountingSection,
	|	TableTypesOfStocks_.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	(CASE
	|		WHEN &BatchAccountingVersion22 THEN TableTypesOfStocks_.VATActivityType
	|		ELSE UNDEFINED END) AS VATActivityType,
	|
	|	&Manager AS Manager,
	|
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS ProductLineOfBusiness,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS CostMan,
	|	0 AS LocalCost,
	|	0 AS Count,
	|	0 AS RevenueAmount,
	|	0 AS RevenueAmountExcludingVAT,
	|	0 AS RevenueAmountExclVATLocal,
	|	0 AS RevenueAmountIncludingVATLocal,
	|
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|	0 AS AddExpensesLocal,
	|	0 AS AddExpensesMan,
	|
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|
	|	CAST(TableTypesOfStocks_.CommissionAmount
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS SellingExpensesIncludingVAT,
	|
	|	CAST((TableTypesOfStocks_.CommissionAmount
	|		- TableTypesOfStocks_.AmountVATRemuneration)
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS SellingExpensesExcludingVAT,
	|
	|	CAST(
	|		CASE WHEN NOT &BatchAccountingVersion22
	|			THEN 0
	|		WHEN &VATTaxation IN (&TypesOfTaxationVATIsIncludedInCost)
	|				AND NOT &GenerateVATChargedWhenIncludingInCost
	|			THEN TableTypesOfStocks_.CommissionAmount
	|		ELSE TableTypesOfStocks_.CommissionAmount - TableTypesOfStocks_.AmountVATRemuneration
	|		END * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SellingExpensesLocal,
	|
	|	CAST(CASE
	|		WHEN NOT &CompanyManagementAccounting
	|		THEN 0
	|		WHEN &VATTaxation IN (&TypesOfTaxationVATIsIncludedInCost)
	|			AND NOT &GenerateVATChargedWhenIncludingInCost
	|		THEN TableTypesOfStocks_.CommissionAmount
	|		ELSE TableTypesOfStocks_.CommissionAmount - TableTypesOfStocks_.AmountVATRemuneration
	|		END * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SellingExpensesMan,
	|
	|	&Partner AS Warehouse,
	|	&Contract AS Contract,
	|	&Terms AS Terms,
	|
	|	&Currency AS ARAPCurrency,
	|	0 AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	0 AS AmountInDocumentCurrency,
	|	0 AS AmountExcludingVATInDocumentCurrency,
	|
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer) AS BusinessOperation,
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		TableTypesOfStocks_.InventoryOwnerAttribute
	|	ELSE
	|		TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|
	|	&ARAPObjectRemuneration AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	&IDARAPObjectReward AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.VATRate AS VATRate
	|	
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	NOT TableTypesOfStocks_.ThisIsTraceableWork
	|	AND (TableTypesOfStocks_.CommissionAmount + TableTypesOfStocks_.AmountVATRemuneration) <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	(CASE
	|		WHEN &BatchAccountingVersion22 THEN &Period
	|		ELSE &EndOfPeriod END) AS Period,
	|	&Department AS Department,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|	END AS AccountingSection,
	|	TableTypesOfStocks_.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	(CASE
	|		WHEN &BatchAccountingVersion22 THEN TableTypesOfStocks_.VATActivityType
	|		ELSE UNDEFINED END) AS VATActivityType,
	|
	|	&Manager AS Manager,
	|
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS ProductLineOfBusiness,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS CostMan,
	|	0 AS LocalCost,
	|	0 AS Count,
	|	0 AS RevenueAmount,
	|	0 AS RevenueAmountExcludingVAT,
	|	0 AS RevenueAmountExclVATLocal,
	|	0 AS RevenueAmountIncludingVATLocal,
	|
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|	0 AS AddExpensesLocal,
	|	0 AS AddExpensesMan,
	|
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|
	|	0 AS SellingExpensesIncludingVAT,
	|
	|	0 AS SellingExpensesExcludingVAT,
	|
	|	CAST(TableTypesOfStocks_.AmountVATRemuneration
	|		* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SellingExpensesLocal,
	|
	|	CAST(TableTypesOfStocks_.AmountVATRemuneration
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS SellingExpensesMan,
	|
	|	&Partner AS Warehouse,
	|	&Contract AS Contract,
	|	&Terms AS Terms,
	|
	|	&Currency AS ARAPCurrency,
	|	0 AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	0 AS AmountInDocumentCurrency,
	|	0 AS AmountExcludingVATInDocumentCurrency,
	|
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer) AS BusinessOperation,
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		TableTypesOfStocks_.InventoryOwnerAttribute
	|	ELSE
	|		TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|
	|	&ARAPObjectRemuneration AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	&IDARAPObjectReward AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses) AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.VATRate AS VATRate
	|	
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	&BatchAccountingVersion22
	|	AND &GenerateVATChargedWhenIncludingInCost
	|	AND &VATTaxation IN (&TypesOfTaxationVATIsIncludedInCost)
	|	AND NOT TableTypesOfStocks_.ThisIsTraceableWork
	|	AND TableTypesOfStocks_.AmountVATRemuneration <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	TableServices.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	&Department AS Department,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	TableServices.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN TableServices.Principal <> UNDEFINED
	|		THEN VALUE(Enum.InventoryTypes.AgentService)
	|		ELSE VALUE(Enum.InventoryTypes.OperationService)
	|	END AS InventoryType,
	|
	|	TableServices.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN TableServices.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END) AS AccountingSection,
	|	TableServices.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	TableServices.VATActivityType AS VATActivityType,
	|
	|	&Manager AS Manager,
	|
	|	TableServices.ItemsLocationAttributes.Purpose.LineOfBusiness AS ProductLineOfBusiness,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	CASE
	|		WHEN TableServices.Principal <> UNDEFINED
	|		THEN CAST(TableServices.AmountIncludingVAT
	|			* &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0
	|	END AS Cost,
	|	CASE
	|		WHEN TableServices.Principal <> UNDEFINED
	|		THEN CAST((TableServices.AmountIncludingVAT - TableServices.VATAmount) 
	|			* &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0
	|	END AS CostExcludingVAT,
	|	CASE
	|		WHEN &CompanyManagementAccounting AND TableServices.Principal <> UNDEFINED
	|		THEN CAST((TableServices.AmountIncludingVAT - TableServices.VATAmount) 
	|			* &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0
	|	END AS CostMan,
	|
	|	CASE
	|		WHEN TableServices.Principal <> UNDEFINED
	|		THEN CAST((TableServices.AmountIncludingVAT - TableServices.VATAmount) 
	|			* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		ELSE 0
	|	END AS LocalCost,
	|
	|	TableServices.Count AS Count,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, CAST(TableServices.AmountIncludingVAT
	|		* &ConversionRateToManCurrency AS NUMBER(31,2))) AS RevenueAmount,
	|
	|	ISNULL(Amounts.AmountExcludingVATMan, CAST((TableServices.AmountIncludingVAT
	|		-TableServices.VATAmount) 
	|		* &ConversionRateToManCurrency AS NUMBER(31,2))) AS RevenueAmountExcludingVAT,
	|
	|	ISNULL(Amounts.AmountExcludingVATCompl, CAST((TableServices.AmountIncludingVAT
	|		-TableServices.VATAmount) 
	|		* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS RevenueAmountExclVATLocal,
	|
	|	ISNULL(Amounts.AmountIncludingVATCompl, CAST(TableServices.AmountIncludingVAT
	|		* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS RevenueAmountIncludingVATLocal,
	|
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|	0 AS AddExpensesLocal,
	|	0 AS AddExpensesMan,
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|
	|	0 AS SellingExpensesIncludingVAT,
	|	0 AS SellingExpensesExcludingVAT,
	|	0 AS SellingExpensesLocal,
	|	0 AS SellingExpensesMan,
	|
	|	&Partner AS Warehouse,
	|	&Contract AS Contract,
	|	&Terms AS Terms,
	|
	|	&Currency AS ARAPCurrency,
	|	ISNULL(Amounts.AmountARAP, TableServices.AmountIncludingVAT) AS AmountInARAPCurrency,
	|	ISNULL(Amounts.AmountARAP - Amounts.AmountVATARAP, TableServices.AmountIncludingVAT - TableServices.VATAmount) AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	TableServices.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	TableServices.AmountIncludingVAT - TableServices.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer) AS BusinessOperation,
	|	TableServices.VATActivityType AS VATTaxation,
	|
	|	TableServices.Products AS SourceOfProductFinancialAccountingGroup,
	|
	|	&ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	TableServices.RowID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting,
	|	TableServices.VATRate           AS VATRate
	|	
	|FROM
	|	TTOperationServices AS TableServices
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = &Ref
	|		AND Amounts.RowID = TableServices.RowID
	|
	|UNION ALL
	|
	|SELECT
	|	TableServices.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	&Department AS Department,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	TableServices.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN TableServices.Principal <> UNDEFINED
	|		THEN VALUE(Enum.InventoryTypes.AgentService)
	|		ELSE VALUE(Enum.InventoryTypes.OperationService)
	|	END AS InventoryType,
	|
	|	TableServices.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN TableServices.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END) AS AccountingSection,
	|	TableServices.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	TableServices.VATActivityType AS VATActivityType,
	|
	|	&Manager AS Manager,
	|
	|	TableServices.ItemsLocationAttributes.Purpose.LineOfBusiness AS ProductLineOfBusiness,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS CostMan,
	|	0 AS LocalCost,
	|	0 AS Count,
	|	0 AS RevenueAmount,
	|	0 AS RevenueAmountExcludingVAT,
	|	0 AS RevenueAmountExclVATLocal,
	|	0 AS RevenueAmountIncludingVATLocal,
	|
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|	0 AS AddExpensesLocal,
	|	0 AS AddExpensesMan,
	|
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|
	|	CAST(TableServices.CommissionAmount
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS SellingExpensesIncludingVAT,
	|
	|	CAST((TableServices.CommissionAmount
	|		- TableServices.AmountVATRemuneration)
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS SellingExpensesExcludingVAT,
	|
	|	CAST((TableServices.CommissionAmount
	|		- TableServices.AmountVATRemuneration)
	|		* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SellingExpensesLocal,
	|
	|	CASE WHEN &CompanyManagementAccounting THEN
	|		CAST((TableServices.CommissionAmount
	|			- TableServices.AmountVATRemuneration)
	|			* &ConversionRateToManCurrency AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END AS SellingExpensesMan,
	|
	|	&Partner AS Warehouse,
	|	&Contract AS Contract,
	|	&Terms AS Terms,
	|
	|	&Currency AS ARAPCurrency,
	|	0 AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	0 AS AmountInDocumentCurrency,
	|	0 AS AmountExcludingVATInDocumentCurrency,
	|
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer) AS BusinessOperation,
	|	TableServices.VATActivityType AS VATTaxation,
	|
	|	TableServices.Products AS SourceOfProductFinancialAccountingGroup,
	|
	|	&ARAPObjectRemuneration AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	&IDARAPObjectReward AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	TableServices.VATRate AS VATRate
	|	
	|FROM
	|	TTOperationServices AS TableServices
	|WHERE
	|	(TableServices.CommissionAmount + TableServices.AmountVATRemuneration) <> 0
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsTransferredToCommissionAgent";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)        AS RecordType,
	|	&EndOfPeriod                                 AS Period,
	|	&Organization                                  AS Organization,
	|	&Partner                                      AS Partner,
	|	&Terms                                   AS Terms,
	|	TableTypesOfStocks_.Products               AS Products,
	|	TableTypesOfStocks_.Characteristic             AS Characteristic,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
	|	TableTypesOfStocks_.Count                 AS Count,
	|	CASE
	|		WHEN &UseTraceableImportedGoodsAccounting
	|				AND BEGINOFPERIOD(&Period, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|			THEN TableTypesOfStocks_.QuantityByGBRN
	|		ELSE 0
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT                  AS RevenueAmount,
	|	TableTypesOfStocks_.CommissionAmount        AS CommissionAmount,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&VATTaxation                           AS VATTaxation
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	NOT &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent)
	|	AND NOT TableTypesOfStocks_.ThisIsTraceableWork
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// This function generates the query text for the table of amounts in the regl currency. accounting's.
//
Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
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
	|	DocumentTable.SalesAmount - DocumentTable.AmountSalesVAT AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.AmountSalesVAT AS VATAmount,
	|	DocumentTable.SalesAmount AS AmountARAP,
	|	DocumentTable.AmountSalesVAT AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|
	|FROM
	|	Document.ConsignmentReportFromCustomer.Goods AS DocumentTable
	|		INNER JOIN Document.ConsignmentReportFromCustomer AS DocumentHeaderData
	|		ON DocumentTable.Ref = DocumentHeaderData.Ref
	|		
	|		INNER JOIN Catalog.Products AS ProductData_1
	|		ON DocumentTable.Products = ProductData_1.Ref
	|		
	|		LEFT JOIN Document.ConsignmentReportFromCustomer.InventoryKinds AS InventoryTable
	|		ON DocumentTable.Ref = InventoryTable.Ref
	|			AND DocumentTable.ItemsLocationAttributes = InventoryTable.ItemsLocationAttributes
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND InventoryTable.Ref IS NULL
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
	|	DocumentTable.VATAmount AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.ConsignmentReportFromCustomer.InventoryKinds AS DocumentTable
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
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObjectRemuneration AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.ConsignmentReportFromCustomer AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.CommissionAmount <> 0
	|";
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
		
EndProcedure

Function QueryTextTableServicesForRegistrationOfReportsToPrincipal(Query, QueryTexts, Registers)
	
	RegisterName = "ServicesForRegistrationOfReportsToPrincipal";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(Query, QueryTexts);
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
	|	ToRegister.TaxInvoiceDate               AS TaxInvoiceDate,
	|	ToRegister.Customer                     AS Customer,
	|	
	|	ToRegister.RowID            AS FinRecordID,
	|	&BusinessTransactionSetting            AS BusinessTransactionSetting,
	|	ToRegister.RowID            AS RowID
	|FROM
	|	TTOperationServices AS ToRegister
	|
	|	LEFT JOIN TTExchangeRates AS ExchangeRates
	|	ON ToRegister.Currency = ExchangeRates.Currency
	|WHERE
	|	ToRegister.Principal <> UNDEFINED
	|ORDER BY
	|	LineNumber
	|";
	
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
	|	VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	&LineOfBusiness AS LineOfBusiness,
	|	
	|	&Partner AS CorPartner,
	|	&Counterparty AS CorCounterparty,
	|	&Contract AS CorContract,
	|	DocumentData.ARAPObjectRemuneration AS CorARAPObject,
	|	&LineOfBusiness AS CorLineOfBusiness,
	|	
	|	CAST(DocumentData.CommissionAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
	|	CAST((DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration) * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVAT,
	|	
	|	CAST(DocumentData.CommissionAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST((DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration) * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalAmountExcludingVAT,
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
	|	Document.ConsignmentReportFromCustomer AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.CommissionAmount <> 0
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
	|	VALUE(Enum.BusinessTransactions.AccountSalesFromCommissionAgentCommissionFee) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	DocumentData.ARAPObjectRemuneration AS ARAPObject,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|	
	|	&LineOfBusiness AS LineOfBusinessItems,
	|	DocumentData.ExpenseItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	CAST(DocumentData.CommissionAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
	|	CAST((DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration) * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVAT,
	|	
	|	CAST(DocumentData.CommissionAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST((DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration) * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalAmountExcludingVAT,
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
	|	DocumentData.ARAPObjectRemuneration.UUID AS FinRecordID
	|FROM
	|	Document.ConsignmentReportFromCustomer AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.CommissionAmount <> 0
	|";
	
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
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Period AS RecorderDate,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	TableServices.Products,
	|	TableServices.Characteristic,
	|	TableServices.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableServices.Count AS Count,
	|	&VATTaxation AS VATTaxation
	|FROM
	|	TTOperationServices AS TableServices
	|WHERE
	|	TableServices.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND TableServices.Principal = UNDEFINED
	|	AND NOT TableServices.TracedGoods
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTTableTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTableTypesOfStocks";
	
	SetRequestParameterVATTaxTypesTaxable(Query);
	InitializeProductAccountingAnalyticsKeys(Query);
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);

	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                  AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products                          AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic                        AS Characteristic,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                   AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType        AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Currency            AS Currency,
	|	TableTypesOfStocks_.CCDNumber                     AS CCDNumber,
	|	TableTypesOfStocks_.Count                   AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN             AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT                    AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount                     AS VATAmount,
	|	TableTypesOfStocks_.CommissionAmount          AS CommissionAmount,
	|	TableTypesOfStocks_.AmountVATRemuneration       AS AmountVATRemuneration,
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)                 AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)               AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)                AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)              AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)                 AS VATAmountCompl,
	|	TableTypesOfStocks_.DateOfTaxInvoiceIssuedByCommissionAgent AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	TableTypesOfStocks_.CommissionAgentSTaxInvoiceNumber AS CommissionAgentSTaxInvoiceNumber,
	|	TableTypesOfStocks_.Customer                   AS Customer,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation                          AS Warehouse,
	|	CommitteeKeys.DimensionKey                    AS CommitteeAnalytics,
	|	SubCommitteeKeys.DimensionKey                 AS SubCommitteeAnalytics,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|			THEN &Manager
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END 											AS FinancialAccountingDimension,
	|	(CASE
	|		WHEN TableTypesOfStocks_.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|				AND &VATTaxation IN (&TypesOfVATTaxable)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END) AS VATActivityType,
	|	TableTypesOfStocks_.RowID          AS RowID,
	|	CASE
	|		WHEN TableTypesOfStocks_.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsTraceableWork,
	|	TableTypesOfStocks_.VATRate AS VATRate
	|
	|INTO TTTableTypesOfStocks
	|FROM
	|	Document.ConsignmentReportFromCustomer.InventoryKinds AS TableTypesOfStocks_
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS CommitteeKeys
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = CommitteeKeys.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = CommitteeKeys.Characteristic
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Purpose = CommitteeKeys.Purpose
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeKeys.Series
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner = CommitteeKeys.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeKeys.ProductCostElement
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS SubCommitteeKeys
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = SubCommitteeKeys.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = SubCommitteeKeys.Characteristic
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Purpose = SubCommitteeKeys.Purpose
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = SubCommitteeKeys.Series
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.GoodsOwner = SubCommitteeKeys.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = SubCommitteeKeys.ProductCostElement
	|
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
	|	Document.ConsignmentReportFromCustomer.Goods AS ToRegister
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
	|				Document.ConsignmentReportFromCustomer.InventoryKinds AS TableTypesOfStocks_
	|			WHERE
	|				TableTypesOfStocks_.Ref = &Ref
	|				AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|			UNION
	|
	|			SELECT DISTINCT
	|				TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.Currency AS Currency
	|			FROM
	|				Document.ConsignmentReportFromCustomer.InventoryKinds AS TableTypesOfStocks_
	|			WHERE
	|				TableTypesOfStocks_.Ref = &Ref
	|				AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|			UNION
	|
	|			SELECT DISTINCT
	|				Services.Currency AS Currency
	|			FROM
	|				TTAgencyServices AS Services
	|			)
	|			AND BaseCurrency = &LocalAccountingCurrency
	|	) AS ExchangeRates
	|
	|	INNER JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Period,
	|			Currency = &Currency AND BaseCurrency = &LocalAccountingCurrency) AS DocumentExchangeRate
	|	ON
	|		TRUE
	|
	|WHERE
	|	DocumentExchangeRate.CourseDenominator <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTOperationServices(Query, QueryTexts)
	
	RegisterName = "TTOperationServices";
	
	SetRequestParameterVATTaxTypesTaxable(Query);
	InitializeProductAccountingAnalyticsKeys(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAgencyServices", QueryTexts) Then
		QueryTextTTAgencyServices(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	TableServices.LineNumber AS LineNumber,
	|	DimensionKeys.DimensionKey AS ItemsLocationAttributes,
	|	PrincipalKeys.DimensionKey AS PrincipalAccountingAnalytics,
	|	CatProducts.ItemsType AS ItemsType,
	|	CatProducts.TracedGoods AS TracedGoods,
	|	TableServices.Products AS Products,
	|	TableServices.Characteristic AS Characteristic,
	|	UNDEFINED AS InventoryOwnerAttribute,
	|
	|	TableServices.Count AS Count,
	|	TableServices.SalesAmount AS AmountIncludingVAT,
	|	TableServices.AmountSalesVAT AS VATAmount,
	|	TableServices.CommissionAmount AS CommissionAmount,
	|	TableServices.AmountVATRemuneration AS AmountVATRemuneration,
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
	|	TableServices.DateOfTaxInvoiceIssuedByCommissionAgent AS TaxInvoiceDate,
	|	TableServices.Customer AS Customer,
	|	ISNULL(AgentServices.Principal, UNDEFINED) AS Principal,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|			THEN &Manager
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END AS FinancialAccountingDimension,
	|	(CASE
	|		WHEN TableServices.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|				AND &VATTaxation IN (&TypesOfVATTaxable)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END) AS VATActivityType,
	|	TableServices.RowID AS RowID,
	|	TableServices.VATRate AS VATRate
	|
	|INTO TTOperationServices
	|FROM
	|	Document.ConsignmentReportFromCustomer.Goods AS TableServices
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionKeys
	|	ON TableServices.Products = DimensionKeys.Products
	|		AND TableServices.Characteristic = DimensionKeys.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = DimensionKeys.Purpose
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = DimensionKeys.Series
	|		AND &Department = DimensionKeys.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = DimensionKeys.ProductCostElement
	|
	|	INNER JOIN Catalog.Products AS CatProducts
	|	ON CatProducts.Ref = TableServices.Products
	|
	|	LEFT JOIN TTAgencyServices AS AgentServices
	|	ON TableServices.Products = AgentServices.Products
	|		AND TableServices.Characteristic = AgentServices.Characteristic
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
	|		ON TableServices.Ref = Amounts.Ref
	|		AND TableServices.RowID = Amounts.RowID
	|
	|WHERE
	|	TableServices.Ref = &Ref
	|	AND CatProducts.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OperationService),
	|		VALUE(Enum.ItemsTypes.Work_5)
	|	)
	|	AND TableServices.ItemsLocationAttributes NOT IN
	|		(SELECT DISTINCT
	|			InventoryKinds.ItemsLocationAttributes
	|		FROM
	|			Document.ConsignmentReportFromCustomer.InventoryKinds AS InventoryKinds
	|		WHERE
	|			InventoryKinds.Ref = &Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	TableServices.LineNumber AS LineNumber,
	|	DimensionKeys.DimensionKey AS ItemsLocationAttributes,
	|	UNDEFINED AS PrincipalAccountingAnalytics,
	|	CatProducts.ItemsType AS ItemsType,
	|	CatProducts.TracedGoods AS TracedGoods,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	TableServices.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	TableServices.Count AS Count,
	|	TableServices.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableServices.VATAmount AS VATAmount,
	|	TableServices.CommissionAmount AS CommissionAmount,
	|	TableServices.AmountVATRemuneration AS AmountVATRemuneration,
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
	|	TableServices.DateOfTaxInvoiceIssuedByCommissionAgent AS TaxInvoiceDate,
	|	TableServices.Customer AS Customer,
	|	UNDEFINED AS Principal,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|			THEN &Manager
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END AS FinancialAccountingDimension,
	|	(CASE
	|		WHEN TableServices.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|				AND &VATTaxation IN (&TypesOfVATTaxable)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END) AS VATActivityType,
	|	TableServices.RowID AS RowID,
	|	TableServices.VATRate AS VATRate
	|FROM
	|	Document.ConsignmentReportFromCustomer.InventoryKinds AS TableServices
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableServices.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionKeys
	|		ON Dimension.Products = DimensionKeys.Products
	|			AND Dimension.Characteristic = DimensionKeys.Characteristic
	|			AND VALUE(Catalog.Assignments.EmptyRef) = DimensionKeys.Purpose
	|			AND VALUE(Catalog.ItemsBatches.EmptyRef) = DimensionKeys.Series
	|			AND &Department = DimensionKeys.StorageLocation
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = DimensionKeys.ProductCostElement
	|		
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON Dimension.Products = CatProducts.Ref
	|	
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON TableServices.Ref = Amounts.Ref
	|			AND TableServices.RowID = Amounts.RowID
	|
	|WHERE
	|	TableServices.Ref = &Ref
	|	AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
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

Procedure SetRequestParametersCurrencyCoefficients(Query) Export
	
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

Procedure InitializeProductAccountingAnalyticsKeys(Query)

	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query("
	|SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Warehouse AS Warehouse
	|FROM
	|	(SELECT DISTINCT
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Purpose AS Purpose,
	|		&Series AS Series,
	|		TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner AS Warehouse
	|	FROM
	|		Document.ConsignmentReportFromCustomer.InventoryKinds AS TableTypesOfStocks_
	|	WHERE
	|		TableTypesOfStocks_.Ref = &Ref
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|		UNION ALL
	|
	|		SELECT
	|			Services.Products AS Products,
	|			Services.Characteristic AS Characteristic,
	|			VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|			&Series AS Series,
	|			ISNULL(Services.Characteristic.Principal, Services.Products.Principal) AS Warehouse
	|		FROM
	|			Document.ConsignmentReportFromCustomer.Goods AS Services
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Services.Products = Dimension.Products
	|				AND Services.Characteristic = Dimension.Characteristic
	|				AND VALUE(Catalog.Assignments.EmptyRef) = Dimension.Purpose
	|				AND &Series = Dimension.Series
	|				AND ISNULL(Services.Characteristic.Principal, Services.Products.Principal) = Dimension.StorageLocation
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			Services.Ref = &Ref
	|			AND ISNULL(Services.Characteristic.Principal, Services.Products.Principal) <> UNDEFINED
	|			AND ISNULL(Services.Characteristic.Principal, Services.Products.Principal) <> &Organization
	|			AND Dimension.DimensionKey IS NULL
	|			AND Services.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|
	|		UNION ALL
	|		
	|		SELECT
	|			Goods.Products                          AS Products,
	|			Goods.Characteristic                        AS Characteristic,
	|			VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|			&Series                                       AS Series,
	|			&Department                               AS Warehouse
	|		FROM
	|			Document.ConsignmentReportFromCustomer.Goods AS Goods
	|		WHERE
	|			Goods.Ref = &Ref
	|			AND Goods.Products.ItemsType IN (
	|				VALUE(Enum.ItemsTypes.OperationService),
	|				VALUE(Enum.ItemsTypes.Work_5)
	|			)
	|) AS GoodsTable
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON
	|		GoodsTable.Products = Dimension.Products
	|		AND GoodsTable.Characteristic = Dimension.Characteristic
	|		AND GoodsTable.Purpose = Dimension.Purpose
	|		AND GoodsTable.Series = Dimension.Series
	|		AND GoodsTable.Warehouse = Dimension.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	Dimension.Products IS NULL 
	|
	|GROUP BY
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series,
	|	GoodsTable.Warehouse
	|");
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Series", Catalogs.ItemsBatches.EmptyRef());
	QueryAnalyst.SetParameter("Department", Query.Parameters.Department);
	QueryAnalyst.SetParameter("Organization", Query.Parameters.Organization);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection)
	EndDo;

	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer) AS BusinessOperation
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.Count > 0
	|	AND (TableTypesOfStocks_.ThisIsTraceableWork
	|		OR &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent))
	|
	|	UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	-TableTypesOfStocks_.Count AS Count,
	|	-TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer) AS BusinessOperation
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.Count < 0
	|	AND (TableTypesOfStocks_.ThisIsTraceableWork
	|		OR &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent))";
	
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
	AdditionalParameters.Add("AccountingDimensionByPartners");
	
	If Query <> Undefined Then
		SetParameterForPartnerAccountingAnalyticsRequest(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTableTypesOfStocks");
	AdditionalTables.Add("TTOperationServices");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTableTypesOfStocks(Query, QueryTexts);
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
	|	(CASE
	|		WHEN &BatchAccountingVersion22 THEN &Period
	|		ELSE &EndOfPeriod END) AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_ 	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType 			AS VATActivityType,
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
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer) 	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 							AS FinRecordID,
	|	&BusinessTransactionSetting									AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ConsignmentReportFromCustomer AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion

	#Region Implementation_Work
	
	QueryText = 
	"SELECT
	// Document description
	|	(CASE
	|		WHEN &BatchAccountingVersion22 THEN &Period
	|		ELSE &EndOfPeriod END) AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_ 	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableServices.ItemsLocationAttributes 		AS ItemsLocationAttributes,
	|	TableServices.InventoryOwnerAttribute 						AS InventoryOwnerAttribute,
	|	TableServices.VATActivityType 				AS VATActivityType,
	|	TableServices.VATActivityType				AS DocumentVATActivityType,
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
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableServices.Count 			AS Count,
	|	TableServices.RowID	AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer) 	AS BusinessOperation,
	|	TableServices.RowID 								AS FinRecordID,
	|	&BusinessTransactionSetting									AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ConsignmentReportFromCustomer AS DocumentTable
	|	INNER JOIN TTOperationServices AS TableServices
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableServices.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND TableServices.Principal = UNDEFINED
	|";
	
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
	|	&AdjustmentPeriod_ 	AS VariancePeriod,
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
	|	&BusinessTransactionSetting									AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ConsignmentReportFromCustomer AS DocumentTable
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

#Region SetOfSeries

//Names of the details that the parameters for specifying the series depend on.
//
// Returns:
//	String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "BusinessOperation,Date";
	
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//	Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//	Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export
	
	NewCommission = ?(Object.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent,
		True, False);
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.ConsignmentReportFromCustomer";
	
	SeriesSpecificationParameters.UseCostAccountingByBatches = NewCommission;
	SeriesSpecificationParameters.UseItemsBatch  = NewCommission;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentToCustomer);
	
	SeriesSpecificationParameters.ThisIsAnInvoice       = True;
	SeriesSpecificationParameters.Date               = Object.Date;
	
	SeriesSpecificationParameters.SelectionPlanning = True;
	SeriesSpecificationParameters.FactOfSelection         = True;
	SeriesSpecificationParameters.WarehouseFieldName       = Undefined;
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	
	SeriesSpecificationParameters.RegisterSeries = ProductsClientServer.ItIsNecessaryToRegisterSeries(
													SeriesSpecificationParameters);
	
	SeriesSpecificationParameters.DocumentOperation_ = Object.BusinessOperation;
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses of specifying series.
//
// Parameters:
//	SeriesSpecificationParameters - Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
// Returns:
//	String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.Products        AS Products,
	|	Goods.Characteristic      AS Characteristic,
	|	Goods.Series               AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Count          AS Count
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	Goods.Products      AS Products,
	|	Goods.Characteristic    AS Characteristic,
	|	Goods.Series             AS Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	SUM(Goods.Count) AS Count
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	SetOfSeries.Products   AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Count     AS Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	SetOfSeries.Products      AS Products,
	|	SetOfSeries.Characteristic    AS Characteristic,
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
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE
	|			CASE
	|				WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN
	|						CASE
	|							WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingOfBatchesInGoodsTransferredToCommissionAgent
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
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON ProductsToRequest.Products = SeriesToRequest.Products
	|			AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	Statuses.LineNumber                          AS LineNumber,
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

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	TextProducts_1 = 
	"SELECT
	|	TableTypesOfStocks_.Ref.Date                   AS Period,
	|	TableTypesOfStocks_.Ref                        AS Ref,
	|	TableTypesOfStocks_.Ref.Organization            AS Organization,
	|	TableTypesOfStocks_.Ref.Department          AS Department,
	|	TableTypesOfStocks_.Ref.Counterparty             AS Counterparty,
	|	TableTypesOfStocks_.Ref.Contract                AS Contract,
	|	TableTypesOfStocks_.Ref.Shipper       AS Shipper,
	|	TableTypesOfStocks_.Ref                        AS ConsignmentReportFromCustomer,
	|	TableTypesOfStocks_.Ref.VATTaxation     AS VATTaxation,
	|	TableTypesOfStocks_.Ref.ARAPObject         AS ARAPObject,
	|	TableTypesOfStocks_.VATRate                     AS VATRate,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.DateOfTaxInvoiceIssuedByCommissionAgent  AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	TableTypesOfStocks_.CommissionAgentSTaxInvoiceNumber AS CommissionAgentSTaxInvoiceNumber,
	|	TableTypesOfStocks_.Customer                    AS ConsignedGoodsCustomer,
	|	TableTypesOfStocks_.RowID           AS RowID,
	|	TableTypesOfStocks_.RowID           AS FinRecordID,
	|	FALSE                                             AS ErrorCorrection,
	|	&BusinessTransactionSetting                  AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.Ref.BusinessOperation  AS BusinessOperation
	|FROM
	|	Document.ConsignmentReportFromCustomer.InventoryKinds AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.Ref.Date                              AS Period,
	|	Goods.Ref                                   AS Ref,
	|	Goods.Ref.Organization                       AS Organization,
	|	Goods.Ref.Department                     AS Department,
	|	Goods.Ref.Counterparty                        AS Counterparty,
	|	Goods.Ref.Contract                           AS Contract,
	|	Goods.Ref.Shipper                  AS Shipper,
	|	Goods.Ref                                   AS ConsignmentReportFromCustomer,
	|	Goods.Ref.VATTaxation                AS VATTaxation,
	|	Goods.Ref.ARAPObject                    AS ARAPObject,
	|	Goods.VATRate                                AS VATRate,
	|	Goods.Products                             AS Products,
	|	Goods.Characteristic                           AS Characteristic,
	|	UNDEFINED                                    AS InventoryOwnerAttribute,
	|	Goods.DateOfTaxInvoiceIssuedByCommissionAgent             AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	Goods.CommissionAgentSTaxInvoiceNumber            AS CommissionAgentSTaxInvoiceNumber,
	|	Goods.Customer                               AS ConsignedGoodsCustomer,
	|	Goods.RowID                      AS RowID,
	|	Goods.RowID                      AS FinRecordID,
	|	FALSE                                            AS ErrorCorrection,
	|	&BusinessTransactionSetting                 AS BusinessTransactionSetting,
	|	Goods.Ref.BusinessOperation             AS BusinessOperation
	|FROM
	|	Document.ConsignmentReportFromCustomer.Goods AS Goods
	|		INNER JOIN Catalog.Products AS ProductData_1
	|		ON Goods.Products = ProductData_1.Ref
	|		
	|		LEFT JOIN Document.ConsignmentReportFromCustomer.InventoryKinds AS InventoryKinds
	|		ON Goods.Ref = InventoryKinds.Ref
	|			AND Goods.ItemsLocationAttributes = InventoryKinds.ItemsLocationAttributes
	|
	|WHERE
	|	Goods.Ref IN (&Ref)
	|	AND Goods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService),
	|											VALUE(Enum.ItemsTypes.Work_5))
	|	AND InventoryKinds.Ref IS NULL
	|";
	VATAccountingERP.ReflectCommissionAgentSReport(Query, QueryTexts, Registers, TextProducts_1);
	
	TextReward = 
	"SELECT
	|	ConsignmentReportFromCustomer.Date                    AS Period,
	|	ConsignmentReportFromCustomer.Ref                  AS Ref,
	|	ConsignmentReportFromCustomer.Organization             AS Organization,
	|	ConsignmentReportFromCustomer.Department           AS Department,
	|	ConsignmentReportFromCustomer.Counterparty              AS Counterparty,
	|	ConsignmentReportFromCustomer.Contract                 AS Contract,
	|	UNDEFINED                              AS Shipper,
	|	ConsignmentReportFromCustomer.Ref                  AS DocumentAcquisitions,
	|	ConsignmentReportFromCustomer.Ref                  AS OriginalTradeDocument,
	|	FALSE                                      AS ErrorCorrection,
	|	FALSE                                      AS AdjustmentUnderApprovalOfParties,
	|	FALSE                                      AS ReduceAmountVATDeduction,
	|	UNDEFINED                              AS PurchaseAdjustmentDocument,
	|	CASE WHEN VATRateOfRemuneration = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END                                     AS VATTaxation,
	|	ConsignmentReportFromCustomer.VATTaxation      AS VATActivityType,
	|
	|	ConsignmentReportFromCustomer.OperationService                  AS Products,
	|	UNDEFINED                              AS Characteristic,
	|	ConsignmentReportFromCustomer.VATRateOfRemuneration AS VATRate,
	|	UNDEFINED                              AS InventoryOwnerAttribute,
	|	UNDEFINED                              AS CCDNumber,
	|	
	|	ConsignmentReportFromCustomer.LineOfBusiness AS LineOfBusiness,
	|	FALSE                                      AS PurchasePerBatchOfProduction,
	|	UNDEFINED                              AS LineOfBusinessOfProductionParty,
	|	UNDEFINED 							  AS ToExpenseAs,
	|	UNDEFINED                              AS ExpenseItem,
	|	UNDEFINED                              AS DimensionOfExpenses,
	|	UNDEFINED                              AS ItemOfOtherAssets,
	|	UNDEFINED                              AS AnalyticsOfOtherAssets,
	|	UNDEFINED                              AS Purpose,
	|	ConsignmentReportFromCustomer.Department           AS AccountingDivision,
	|	""""                                      AS RowID,
	|	&IDARAPObjectReward AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|FROM
	|	Document.ConsignmentReportFromCustomer AS ConsignmentReportFromCustomer
	|WHERE
	|	ConsignmentReportFromCustomer.Ref IN (&Ref)
	|";
	VATAccountingERP.ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, TextReward);

EndProcedure

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.ConsignmentReportFromCustomer AS DocumentDataHeader
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
		|	Document.ConsignmentReportFromCustomer.ARAPDetailsWithCustomer AS Table
		|		LEFT JOIN Document.ConsignmentReportFromCustomer AS DocumentDataHeader
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
		|	DocumentDataHeader.ARAPObjectRemuneration AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.ConsignmentReportFromCustomer AS DocumentDataHeader
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
		|	Document.ConsignmentReportFromCustomer.ARAPDetailsWithVendor AS Table
		|		LEFT JOIN Document.ConsignmentReportFromCustomer AS DocumentDataHeader
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
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.Ref.ARAPObject                                            AS ARAPObject,
		|	Table.PaymentDate                                                      AS PaymentDate,
		|	UNDEFINED                                                             AS SalesOrder_,
		|	FALSE                                                                     AS InvoiceForOrders,
		|	Table.PaymentAmount                                                     AS AmountARAP,
		|	0                                                                        AS AmountARAPByPackage,
		|	Table.PaymentAmount                                                     AS Sum,
		|	
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)           AS BusinessOperation,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	VALUE(Enum.CustomerPaymentControlOptions.CreditAfterShipment)        AS PaymentOption,
		|	FALSE                                                                     AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument
		|FROM
		|	Document.ConsignmentReportFromCustomer.PaymentScheduleSteps AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.PaymentAmount > 0
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.Ref.ARAPObject                                            AS ARAPObject,
		|	Table.Ref.Date                                                      AS PaymentDate,
		|	UNDEFINED                                                             AS SalesOrder_,
		|	FALSE                                                                     AS InvoiceForOrders,
		|	Table.SalesAmount                                                     AS AmountARAP,
		|	0                                                                        AS AmountARAPByPackage,
		|	Table.SalesAmount                                                     AS Sum,
		|	
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)           AS BusinessOperation,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	VALUE(Enum.CustomerPaymentControlOptions.CreditAfterShipment)        AS PaymentOption,
		|	FALSE                                                                     AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument
		|FROM
		|	Document.ConsignmentReportFromCustomer.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.SalesAmount < 0";
	
	TextPaymentPlanning = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.Ref.ARAPObject                                            AS ARAPObject,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)           AS BusinessOperation,
		|	UNDEFINED                                                             AS PaymentMethod,
		|	
		|	Table.PaymentDate                                                      AS PaymentDate,
		|	VALUE(Enum.CustomerPaymentControlOptions.CreditAfterShipment)        AS PaymentOption,
		|	Table.PaymentAmount                                                     AS AmountDue,
		|		
		|	TRUE                                                                   AS ExcludeDuringControl,
		|	FALSE                                                                     AS InvoiceForOrders,
		|	UNDEFINED                                                             AS SalesOrder_,
		|	FALSE                                                                     AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument
		|	
		|FROM
		|	Document.ConsignmentReportFromCustomer.PaymentScheduleSteps AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.PaymentAmount > 0
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.Ref.ARAPObject                                            AS ARAPObject,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)           AS BusinessOperation,
		|	UNDEFINED                                                             AS PaymentMethod,
		|	
		|	Table.Ref.Date                                                      AS PaymentDate,
		|	VALUE(Enum.CustomerPaymentControlOptions.CreditAfterShipment)        AS PaymentOption,
		|	Table.SalesAmount                                                     AS AmountDue,
		|		
		|	TRUE                                                                   AS ExcludeDuringControl,
		|	FALSE                                                                     AS InvoiceForOrders,
		|	UNDEFINED                                                             AS SalesOrder_,
		|	FALSE                                                                     AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument
		|	
		|FROM
		|	Document.ConsignmentReportFromCustomer.Goods AS Table
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
		|	Document.ConsignmentReportFromCustomer.ARAPDetailsWithCustomer AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, TextSale, TextPaymentPlanning, TextAdvancePaymentOffset);
	
	#EndRegion
	
	#Region CommissionDeduction
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
	
		TextOfClientSObligation = 
			"SELECT
			|	Table.Ref                                                      AS Ref,
			|	Table.Organization                                                 AS Organization,
			|	Table.Partner                                                     AS Partner,
			|	Table.Date                                                        AS RecorderDate,
			|	Table.Number                                                       AS RecorderNumber,
			|	
			|	Table.Currency                                                      AS ARAPCurrency,
			|	Table.ARAPObject                                              AS ARAPObject,
			|	
			|	Table.CommissionAmount                                         AS Sum,
			|	Table.CommissionAmount                                         AS AmountARAP,
			|	0                                                                   AS ReductionIsPaid,
			|	0                                                                   AS IncreaseIsPaid,
			|	
			|	UNDEFINED                                                        AS CashFlowItem,
			|	UNDEFINED                                                        AS ProformaInvoice,
			|	UNDEFINED                                                        AS PaymentMethod,
			|	Table.Currency                                                      AS DocumentCurrency,
			|	Table.Date                                                        AS DateOfCourse,
			|	UNDEFINED                                                        AS LinkedDocument,
			|
			|	Table.DocumentID                                      AS FinRecordID,
			|	VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction) AS BusinessOperation,
			|	VALUE(Catalog.BusinessTransactionsSettings.CommissionAgentSRemunerationDeduction) AS BusinessTransactionSetting
			|FROM
			|	Document.ConsignmentReportFromCustomer AS Table
			|WHERE
			|	Table.Ref IN (&Ref)
			|	AND Table.CommissionAmount <> 0
			|	AND Table.KeepCommissionFee";
	
		TextOfObligationToSupplier = 
			"SELECT
			|	Table.Ref                                                      AS Ref,
			|	Table.Organization                                                 AS Organization,
			|	Table.Partner                                                     AS Partner,
			|	Table.Date                                                        AS RecorderDate,
			|	Table.Number                                                       AS RecorderNumber,
			|	
			|	Table.Currency                                                      AS ARAPCurrency,
			|	Table.ARAPObjectRemuneration                                AS ARAPObject,
			|	
			|	Table.CommissionAmount                                         AS Sum,
			|	Table.CommissionAmount                                         AS AmountARAP,
			|	0                                                                   AS ReductionIsPaid,
			|	0                                                                   AS IncreaseIsPaid,
			|	
			|	UNDEFINED                                                        AS CashFlowItem,
			|	UNDEFINED                                                        AS PaymentRequest,
			|	UNDEFINED                                                        AS PaymentMethod,
			|	Table.Currency                                                      AS DocumentCurrency,
			|	Table.Date                                                        AS DateOfCourse,
			|	UNDEFINED                                                        AS LinkedDocument,
			|
			|	Table.DocumentID                                      AS FinRecordID,
			|	VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction) AS BusinessOperation,
			|	VALUE(Catalog.BusinessTransactionsSettings.CommissionAgentSRemunerationDeduction) AS BusinessTransactionSetting
			|FROM
			|	Document.ConsignmentReportFromCustomer AS Table
			|WHERE
			|	Table.Ref IN (&Ref)
			|	AND Table.CommissionAmount <> 0
			|	AND Table.KeepCommissionFee";
			
		MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.OffsettingOfCounterDebt(Query, QueryTexts, Registers, TextOfClientSObligation, TextOfObligationToSupplier);
	
	Else
		
		TextPayment = 
		"SELECT
		|	Table.Ref                                                                   AS Ref,
		|	Table.Organization                                                              AS Organization,
		|	Table.Partner                                                                  AS Partner,
		|	
		|	Table.Currency                                                                   AS ARAPCurrency,
		|	Table.ARAPObject                                                           AS ARAPObject,
		|	
		|	Table.CommissionAmount                                                      AS AmountARAP,
		|	Table.CommissionAmount                                                      AS Sum,
		|	0                                                                                AS IncreaseIsPaid,
		|	0                                                                                AS ReductionIsPaid,
		|	
		|	Table.Date                                                                     AS RecorderDate,
		|	Table.Date                                                                     AS DateOfCourse,
		|	DATETIME(1,1,1)                                                                 AS MaturityDate,
		|	Table.Number                                                                    AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction) AS BusinessOperation,
		|	UNDEFINED                                                                     AS PaymentMethod,
		|	UNDEFINED                                                                     AS CashFlowItem,
		|	UNDEFINED                                                                     AS ProformaInvoice,
		|	Table.Currency                                                                   AS DocumentCurrency,
		|	UNDEFINED                                                                     AS LinkedDocument,
		|	Table.ARAPObject.UUID                                   AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.CommissionAgentSRemunerationDeduction) AS BusinessTransactionSetting
		|FROM
		|	Document.ConsignmentReportFromCustomer AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.CommissionAmount <> 0
		|	AND Table.KeepCommissionFee";
		
		ARAPAccountingPostingCustomers.CarryingOutPaymentFromClient(Query, QueryTexts, Registers, TextPayment, "2");
		
	EndIf;
	
	#EndRegion
	
	#Region NotCommissionDeduction
	
	TextPurchase = "
		|SELECT
		|	Table.Ref                                                 AS Ref,
		|	Table.Organization                                            AS Organization,
		|	Table.Partner                                                AS Partner,
		|	Table.Date                                                   AS RecorderDate,
		|	Table.Number                                                  AS RecorderNumber,
		|	
		|	Table.ARAPObjectRemuneration                           AS ARAPObject,
		|	Table.PaymentDate                                            AS PaymentDate,
		|	UNDEFINED                                                   AS PaymentOption,
		|	UNDEFINED                                                   AS PurchaseOrder_,
		|	Table.CommissionAmount                                    AS Sum,
		|	Table.CommissionAmount                                    AS AmountARAP,
		|	0                                                              AS AmountARAPByPackage,
		|
		|	Table.ARAPObjectSettings                                        AS ARAPObjectSettings,
		|	FALSE                                                           AS InvoiceForOrders,
		|	Table.Currency                                                 AS ARAPCurrency,
		|	CASE WHEN &NewOnlineARAPAccounting AND Table.KeepCommissionFee
		|		THEN VALUE(Enum.BusinessTransactions.AccountSalesFromCommissionAgentCommissionFee)
		|		ELSE VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|	END                                                          AS BusinessOperation,
		|	VALUE(Catalog.BusinessTransactionsSettings.AccountSalesFromCommissionAgentCommissionFee) AS BusinessTransactionSetting,
		|	UNDEFINED                                                   AS PaymentMethod,
		|	Table.Ref.Currency                                          AS DocumentCurrency,
		|	Table.Ref.Date                                            AS DateOfCourse,
		|	UNDEFINED                                                   AS LinkedDocument
		|FROM
		|	Document.ConsignmentReportFromCustomer AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND (&NewOnlineARAPAccounting AND Table.KeepCommissionFee AND Table.Ref.CommissionAmount <> 0
		|		OR NOT Table.KeepCommissionFee AND Table.Ref.CommissionAmount > 0)
		|";
	
	TextPaymentPlan_ = "
		|SELECT
		|	Table.Ref                                                 AS Ref,
		|	Table.Organization                                            AS Organization,
		|	Table.Partner                                                AS Partner,
		|	Table.Date                                                   AS RecorderDate,
		|	Table.Number                                                  AS RecorderNumber,
		|	Table.PaymentDate                                            AS PaymentDate,
		|	
		|	Table.ARAPObjectRemuneration                           AS ARAPObject,
		|	
		|	Table.ARAPObjectSettings                                        AS ARAPObjectSettings,
		|	FALSE                                                           AS InvoiceForOrders,
		|	FALSE                                                           AS ExceedingOrder,
		|	UNDEFINED                                                   AS PurchaseOrder_,
		|	Table.CommissionAmount                                    AS AmountDue,
		|	Table.Currency                                                 AS ARAPCurrency,
		|	CASE WHEN &NewOnlineARAPAccounting AND Table.KeepCommissionFee
		|		THEN VALUE(Enum.BusinessTransactions.AccountSalesFromCommissionAgentCommissionFee)
		|		ELSE VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|	END                                                          AS BusinessOperation,
		|	UNDEFINED                                                   AS PaymentMethod,
		|	Table.Currency                                                 AS DocumentCurrency,
		|	UNDEFINED                                                   AS PaymentOption,
		|	UNDEFINED                                                   AS LinkedDocument
		|FROM
		|	Document.ConsignmentReportFromCustomer AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND (&NewOnlineARAPAccounting AND Table.KeepCommissionFee AND Table.Ref.CommissionAmount <> 0
		|		OR NOT Table.KeepCommissionFee AND Table.Ref.CommissionAmount > 0)
		|";
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                             AS Ref,
		|	Table.Ref.Organization                                 AS Organization,
		|	Table.Ref.Partner                                     AS Partner,
		|	
		|	Table.ARAPObject                                     AS CalculationObjectSource,
		|	Table.Ref.ARAPObjectRemuneration                AS CalculationObjectReceiver,
		|
		|	Table.Ref.Currency                                      AS ARAPCurrency,
		|	Table.AmountARAP                                AS AmountARAP,
		|	Table.Ref.Currency                                      AS DocumentCurrency,
		|	Table.Sum                                              AS Sum,
		|
		|	Table.Ref.Date                                        AS RecorderDate,
		|	Table.Ref.Date                                        AS DateOfCourse,
		|	Table.Ref.Number                                       AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment) AS BusinessOperation
		|	
		|FROM
		|	Document.ConsignmentReportFromCustomer.ARAPDetailsWithVendor AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND (NOT Table.Ref.KeepCommissionFee AND Table.Ref.CommissionAmount > 0 OR &NewOnlineARAPAccounting)
		|	AND Table.Ref.CommissionAmount <> 0
		|";
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan_, TextAdvancePaymentOffset);
	
	TextPayment = "
		|SELECT
		|	Table.Ref                                                 AS Ref,
		|	Table.Organization                                            AS Organization,
		|	Table.Partner                                                AS Partner,
		|	Table.Date                                                   AS RecorderDate,
		|	Table.Number                                                  AS RecorderNumber,
		|	
		|	Table.Currency                                                 AS ARAPCurrency,
		|	Table.ARAPObjectRemuneration                           AS ARAPObject,
		|
		|	-Table.CommissionAmount                                   AS Sum,
		|	-Table.CommissionAmount                                   AS AmountARAP,
		|	0                                                              AS ReductionIsPaid,
		|	0                                                              AS IncreaseIsPaid,
		|	0                                                              AS SumMan,
		|	0                                                              AS SumCompl,
		|
		|	UNDEFINED                                                   AS CashFlowItem,
		|	UNDEFINED                                                   AS PaymentRequest,
		|	UNDEFINED                                                   AS PaymentMethod,
		|	Table.Currency                                                 AS DocumentCurrency,
		|	Table.Date                                                   AS DateOfCourse,
		|	DATETIME(1,1,1)                                               AS MaturityDate,
		|	UNDEFINED                                                   AS LinkedDocument,
		|
		|	Table.ARAPObjectRemuneration.UUID   AS FinRecordID,
		|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer) AS BusinessOperation,
		|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting
		|FROM
		|	Document.ConsignmentReportFromCustomer AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.KeepCommissionFee
		|	AND Table.CommissionAmount < 0";
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.MakingPaymentToSupplier(Query, QueryTexts, Registers, TextPayment,"2");
	
	#EndRegion
	
EndProcedure

//Returns the text of the request for the transferred goods
//
// Returns:
//  String - 
//
Function QueryTextGoodsTransferred() Export

	QueryText = 
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.CCDNumber AS CCDNumber,
	|	Goods.Series AS Series,
	|	Goods.Count AS Count
	|
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|;
	|///////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(Goods.LineNumber) AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.CCDNumber AS CCDNumber,
	|	Goods.Series AS Series,
	|	SUM(Goods.Count) AS Count
	|
	|INTO Goods
	|FROM
	|	TTProducts_1 AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.CCDNumber,
	|	Goods.Series
	|;
	|///////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DimensionKeys.Ref AS Ref
	|INTO DimensionKeys
	|FROM
	|	Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|WHERE
	|	DimensionKeys.StorageLocation = &Contract
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT ALLOWED
	|	GoodsTransferred.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CASE
	|		WHEN &TheCommissionAgentDoesNotKeepRecordsOnTheRNPT
	|		OR NOT ISNULL(GoodsTransferred.ItemsLocationAttributes.Products.TracedGoods, FALSE)
	|			THEN VALUE(Catalog.CCDNumbers.EmptyRef)
	|		ELSE GoodsTransferred.CCDNumber
	|	END AS CCDNumber,
	|	ISNULL(InventoryKinds.InventoryType, VALUE(Enum.InventoryTypes.EmptyRef)) AS InventoryType,
	|	SUM(GoodsTransferred.CountBalance) AS CountBalance
	|INTO GoodsTransferred
	|FROM
	|	(SELECT
	|		GoodsTransferredBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		GoodsTransferredBalance.CCDNumber AS CCDNumber,
	|		GoodsTransferredBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		GoodsTransferredBalance.CountBalance AS CountBalance
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(&Period, ItemsLocationAttributes IN
	|			(SELECT
	|				DimensionKeys.Ref
	|			FROM
	|				DimensionKeys AS DimensionKeys)
	|		AND Organization = &Organization) AS GoodsTransferredBalance
	|
	|	UNION ALL
	|
	|	SELECT
	|		GoodsTransferredToRegistrar.ItemsLocationAttributes,
	|		GoodsTransferredToRegistrar.CCDNumber,
	|		GoodsTransferredToRegistrar.InventoryOwnerAttribute,
	|		CASE
	|			WHEN GoodsTransferredToRegistrar.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -GoodsTransferredToRegistrar.Count
	|			ELSE GoodsTransferredToRegistrar.Count
	|		END
	|	FROM
	|		AccumulationRegister.CompanyGoods AS GoodsTransferredToRegistrar
	|	WHERE
	|		GoodsTransferredToRegistrar.Recorder = &Recorder
	|		AND GoodsTransferredToRegistrar.Active
	|		AND GoodsTransferredToRegistrar.ItemsLocationAttributes IN
	|			(SELECT
	|				DimensionKeys.Ref
	|			FROM
	|				DimensionKeys AS DimensionKeys)
	|		AND GoodsTransferredToRegistrar.Organization = &Organization) AS GoodsTransferred
	|		
	|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON (GoodsTransferred.InventoryOwnerAttribute = InventoryKinds.Ref)
	|	
	|GROUP BY
	|	GoodsTransferred.ItemsLocationAttributes,
	|	CASE
	|		WHEN &TheCommissionAgentDoesNotKeepRecordsOnTheRNPT
	|		OR NOT ISNULL(GoodsTransferred.ItemsLocationAttributes.Products.TracedGoods, FALSE)
	|			THEN VALUE(Catalog.CCDNumbers.EmptyRef)
	|		ELSE GoodsTransferred.CCDNumber
	|	END,
	|	ISNULL(InventoryKinds.InventoryType, VALUE(Enum.InventoryTypes.EmptyRef))
	|	
	|HAVING
	|	SUM(GoodsTransferred.CountBalance) > 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT ALLOWED
	|	ISNULL(DimensionKeys.Products,
	|		VALUE(Catalog.Products.EmptyRef)) AS Products,
	|	ISNULL(DimensionKeys.Characteristic,
	|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS Characteristic,
	|	ISNULL(DimensionKeys.Series,
	|		VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
	|	GoodsTransferred.CCDNumber                     AS CCDNumber,
	|	GoodsTransferred.CCDNumber.OriginCountry AS OriginCountry,
	|	SUM(GoodsTransferred.CountBalance)     AS CountBalance
	|INTO GoodsTransferredBalance
	|FROM
	|	GoodsTransferred AS GoodsTransferred
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON GoodsTransferred.ItemsLocationAttributes = DimensionKeys.Ref
	|
	|		LEFT JOIN Catalog.Products AS Goods
	|		ON DimensionKeys.Products = Goods.Ref
	|
	|WHERE
	|	(NOT &BusinessOperation IN (VALUE(Enum.BusinessTransactions.WriteOffShortagesAtDepositorSExpense),
	|		VALUE(Enum.BusinessTransactions.WriteOffShortagesAtConsignorSExpense))
	|		OR NOT GoodsTransferred.InventoryType IN (VALUE(Enum.InventoryTypes.ConsignedGoods),
	|			VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)))
	|
	|GROUP BY
	|	ISNULL(DimensionKeys.Products, VALUE(Catalog.Products.EmptyRef)),
	|	ISNULL(DimensionKeys.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)),
	|	CASE
	|		WHEN Goods.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE DimensionKeys.Purpose
	|	END,
	|	ISNULL(DimensionKeys.Series, VALUE(Catalog.ItemsBatches.EmptyRef)),
	|	GoodsTransferred.CCDNumber
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	GoodsTransferredBalance.Products AS Products,
	|	GoodsTransferredBalance.Characteristic AS Characteristic,
	|	GoodsTransferredBalance.Series AS Series,
	|	GoodsTransferredBalance.CCDNumber AS CCDNumber,
	|	GoodsTransferredBalance.OriginCountry AS OriginCountry,
	|	GoodsTransferredBalance.CountBalance AS CountBalance,
	|	CASE
	|		WHEN ISNULL(Goods.Count,0) < 0
	|			THEN GoodsTransferredBalance.CountBalance
	|		ELSE GoodsTransferredBalance.CountBalance - ISNULL(Goods.Count,0)
	|	END AS LeftToSelect,
	|	ISNULL(Goods.Count,0) AS QuantityIsSelected,
	|	ISNULL(Goods.Count, 0) AS QuantityInInvoice
	|
	|FROM
	|	GoodsTransferredBalance AS GoodsTransferredBalance
	|
	|	LEFT JOIN
	|		Goods AS Goods
	|	ON
	|		GoodsTransferredBalance.Products = Goods.Products
	|		AND GoodsTransferredBalance.Characteristic = Goods.Characteristic
	|		AND GoodsTransferredBalance.CCDNumber = Goods.CCDNumber
	|		AND GoodsTransferredBalance.Series = Goods.Series
	|
	|ORDER BY
	|	ISNULL(Goods.LineNumber, 99999),
	|	Products,
	|	Characteristic,
	|	Series,
	|	CCDNumber
	|";

	Return QueryText;

EndFunction

// Gets an action handler depending on the business operation
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions, Undefined - 
//
// Returns:
//  CommonModule, DocumentManager - handler manager
//
Function ActionHandler(BusinessOperation = Undefined) Export
	
	Handler = Documents.ConsignmentReportFromCustomer;
	
	Return Handler;
	
EndFunction
#Region ConductingLocalAccounting

#EndRegion
#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	ThisIsPartner = UserRightsCached.ThisIsPartner();
	
	// Commission agent's report on sales
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "DataProcessor.PrintCommissionReports";
	PrintCommand.Id = "ConsignmentReportFromCustomer";
	PrintCommand.Presentation = NStr("vi = 'Bảng kê hàng hóa của người nhận bán hộ';
									|ru = 'Отчет комиссионера о продажах';
									|en = 'Consignment issue notification'; fa = 'اعلان صدور امانی';
									|it = 'Report del commissionario sulle vendite';
									|pl = 'Raport komisanta ze sprzedaży';
									|tr = 'Konsinye satış raporu'");
	PrintCommand.CheckPostingBeforePrint = Not ThisIsPartner;
	PrintCommand.DefaultPrintForm = True;
	PrintCommand.PrintFormDescription = NStr("vi = 'Bảng kê hàng hóa của người nhận ký gửi';
											|ru = 'Отчет комиссионера о продажах';
											|en = 'Consignment issue notification'; fa = 'اعلان صدور امانی';
											|it = 'Report del commissionario sulle vendite';
											|pl = 'Raport komisanta ze sprzedaży';
											|tr = 'Konsinye satış raporu'");

	ConsignmentReportFromCustomerLocalization.AddPrintCommands(PrintCommands);

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
	ConsignmentReportFromCustomerLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
EndProcedure

// Returns data for the formation of a printed form of the "Commission Report".
//
// Parameters:
//	PrintParameters - Structure
//	ObjectsArray - Array of DocumentRef.ConsignmentReportFromCustomer - links to documents for which you need
//																	to get data.
//
// Returns:
//	Structure - a collection of data used when printing the UPD, containing the following properties:
//		* Title - String - Report header.
//		* HeaderResults - QueryResult - general data of the document.
//		* ResultForTabularPart - QueryResult - data of the tabular part of the document.
//		* DocumentTraceabilityData - ValueTable - a table containing information about the traceability of the document, with the following columns:
//			** Ref - DocumentRef.ConsignmentReportFromCustomer - link to the document.
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
	|	DocumentData.Counterparty				AS Consignee,
	|	DocumentData.Organization				AS Consignor,
	|	DocumentData.Organization.Prefix		AS Prefix,
	|	DocumentData.Currency					AS Currency,
	|	DocumentData.CommissionAmount		AS CommissionAmount,
	|	DocumentData.Manager.Individual	AS CommitteeRepresentative,
	|	""""									AS RepresentativeOfCommissionAgent
	|FROM
	|	Document.ConsignmentReportFromCustomer AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|	AND DocumentData.Posted
	|
	|ORDER BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	NestedQuery.Ref												AS Ref,
	|	MAX(NestedQuery.LineNumber)								AS LineNumber,
	|	NestedQuery.Products										AS Products,
	|	NestedQuery.Products.DescriptionFull						AS ProductItemName,
	|	NestedQuery.Products.Code									AS Code,
	|	NestedQuery.Products.SKU								AS SKU,
	|	CASE
	|		WHEN NestedQuery.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND NestedQuery.Products.TracedGoods = TRUE
	|			THEN NestedQuery.Products.UnitOfMeasure.Presentation
	|		ELSE NestedQuery.Products.FEACNUnitOfMeasure.Presentation
	|	END																AS FEACNUnitOfMeasure,
	|	NestedQuery.Characteristic.DescriptionFull					AS Characteristic,
	|	NestedQuery.UnitOfMeasure.Presentation						AS UnitOfMeasurementName,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END																AS Package,
	|	SUM(NestedQuery.Count)									AS Count,
	|	SUM(NestedQuery.QuantityByGBRN)								AS QuantityByGBRN,
	|	NestedQuery.Price												AS Price,
	|	SUM(NestedQuery.ConsignorAmount)								AS ConsignorAmount,
	|	SUM(NestedQuery.SalesAmount)									AS SalesAmount,
	|	SUM(NestedQuery.CommissionAmount)							AS CommissionAmount,
	|	NestedQuery.CCDNumber											AS CCDNumber,
	|	NestedQuery.CCDNumber.CCDNumberType								AS CCDNumberType,
	|	NestedQuery.CCDNumber.Presentation								AS ProductBatchIDNumber,
	|	NestedQuery.DateOfTaxInvoiceIssuedByCommissionAgent						AS TaxInvoiceDate,
	|	NestedQuery.Customer											AS Customer
	|FROM
	|	(SELECT
	|		GoodsTable.Ref						AS Ref,
	|		GoodsTable.LineNumber					AS LineNumber,
	|		GoodsTable.Products					AS Products,
	|		CASE
	|			WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN GoodsTable.Products.UnitOfMeasure
	|			ELSE GoodsTable.Package
	|		END										AS UnitOfMeasure,
	|		GoodsTable.Characteristic				AS Characteristic,
	|		GoodsTable.Package						AS Package,
	|		GoodsTable.NumberOfPackages			AS Count,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(GoodsTable.Ref.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE GoodsTable.QuantityByGBRN
	|		END										AS QuantityByGBRN,
	|		GoodsTable.Price							AS Price,
	|		GoodsTable.AmountIncludingVAT						AS ConsignorAmount,
	|		GoodsTable.SalesAmount					AS SalesAmount,
	|		GoodsTable.CommissionAmount			AS CommissionAmount,
	|		CASE
	|			WHEN NOT &UseTraceableImportedGoodsAccounting
	|					OR BEGINOFPERIOD(GoodsTable.Ref.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				THEN 0
	|			ELSE GoodsTable.CCDNumber
	|		END										AS CCDNumber,
	|		GoodsTable.DateOfTaxInvoiceIssuedByCommissionAgent	AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|		GoodsTable.Customer					AS Customer
	|	FROM
	|		Document.ConsignmentReportFromCustomer.Goods AS GoodsTable
	|	
	|	WHERE
	|		GoodsTable.Ref IN(&ObjectsArray)
	|	
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Ref,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.UnitOfMeasure,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END,
	|	NestedQuery.Price,
	|	NestedQuery.CCDNumber,
	|	NestedQuery.DateOfTaxInvoiceIssuedByCommissionAgent,
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
	|				AND ISNULL(Goods.Ref.Terms.CommissionAgentUsesInventoryAccountingByProductBatchID, FALSE)
	|				AND ISNULL(Goods.CCDNumber.CCDNumberType, UNDEFINED) IN(VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber),
	|																		VALUE(Enum.CCDNumberTypes.KitRNPT))
	|			THEN TRUE
	|		ELSE FALSE
	|	END)			AS ThereIsRNPT
	|FROM
	|	Document.ConsignmentReportFromCustomer.Goods AS Goods
	|
	|WHERE
	|	Goods.Ref IN(&ObjectsArray)
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
	|	Document.ConsignmentReportFromCustomer.Goods AS DocumentTable
	|		INNER JOIN Catalog.CCDNumbers.TraceableComponents AS Components
	|		ON DocumentTable.CCDNumber = Components.Ref";
	
	Query.Text = StrReplace(Query.Text,
								"&QueryTextPackagingFactor",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"NestedQuery.Package",
									"NestedQuery.Products"));
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Title = NStr("vi = 'Bảng kê hàng hóa của người nhận bán hộ';
				|ru = 'Отчет комиссионера о продажах';
				|en = 'Consignment issue notification'; fa = 'اعلان صدور امانی';
				|it = 'Report del commissionario sulle vendite';
				|pl = 'Raport komisanta ze sprzedaży';
				|tr = 'Konsinye satış raporu'", Common.DefaultLanguageCode());
	
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
	|	&BusinessOperation                  AS BusinessOperation,
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
	|	&ExternalDocumentName         AS SourceDocumentName,
	|	&IncomingDocumentDate                 AS SourceDocumentDate,
	|	&IncomingDocumentNumber                AS SourceDocumentNumber,
	|	&Period                                 AS RecordingInAccountingDate";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf
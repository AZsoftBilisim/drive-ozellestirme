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
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization", Parameters);

	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Manager";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
		
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"ExternalDocumentName", Parameters);
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
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	
	RedemptionOfReturnablePackagingFromVendorLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.RedemptionOfReturnablePackagingFromVendor") Then
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
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
		RedemptionOfReturnablePackagingFromVendorLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
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
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	RedemptionOfReturnablePackagingFromVendorLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "Repurchase of returnable containers from the supplier".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.RedemptionOfReturnablePackagingFromVendor) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.RedemptionOfReturnablePackagingFromVendor.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.RedemptionOfReturnablePackagingFromVendor);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseReusablePackage";
	

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
	
	Reports.ARAPAccountingStatementByReturnablePackagingReceived.AddReportCommand(ReportsCommands);
	
	ARAPAccountingServer.PaymentCardWithSupplier_AddDocumentReportCommand(ReportsCommands);
	ARAPAccountingServer.IndebtednessToSuppliers_AddDocumentReportCommand(ReportsCommands);
	
	RedemptionOfReturnablePackagingFromVendorLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// This function determines the details of the selected document.
//
// Parameters:
//  DocumentRef - DocumentRef - Link to the document.
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
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.CourseNumerator AS Rate,
	|	DocumentData.CourseDenominator AS Repetition
	|
	|FROM
	|	Document.RedemptionOfReturnablePackagingFromVendor AS DocumentData
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
		Currency = Selection.Currency;
		ARAPCurrency = Selection.ARAPCurrency;
		BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
		DocumentAmount = Selection.DocumentAmount;
		AmountARAP = ?(Selection.Posted, Selection.AmountARAP, 0);
		Repetition = Selection.Repetition;
		Rate = Selection.Rate;
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		Partner = Catalogs.Partners.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		Currency = Catalogs.Currencies.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
		DocumentAmount = 0;
		AmountARAP = 0;
		Repetition = 1;
		Rate = 1;
	EndIf;
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("Contract", Contract);
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	AttributesStructure1.Insert("Currency", Currency);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", BusinessOperation);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP);
	AttributesStructure1.Insert("Rate", Rate);
	AttributesStructure1.Insert("Repetition", Repetition);
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	
	Return AttributesStructure1;

EndFunction

// Returns the structure of parameters for filling in the purchase VAT tax.
//
// Parameters:
//  Object - DocumentObject.RedemptionOfReturnablePackagingFromVendor - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export

	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	
	FillParameters.Counterparty = Object.Counterparty;
	FillParameters.Contract = Object.Contract;
	FillParameters.Period  = Object.Date;

	FillParameters.RedemptionOfReturnablePackagingFromVendor = True;
	
	Return FillParameters;
	
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
			"DepositForPackageIsRequired");
		DepositForPackageIsRequired = StructureFillingData.DepositForPackageIsRequired;
	ElsIf FillingData = Undefined Then
		DepositForPackageIsRequired = False;
	Else
		DepositForPackageIsRequired = FillingData.DepositForPackageIsRequired;
	EndIf;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                    = True;
	ParametersStructure.PaymentType_                          = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	ParametersStructure.ChangesCalculationsByString               = "NOT DataSource.DepositForPackageIsRequired";
	ParametersStructure.ChangesPaymentPlan                   = Not DepositForPackageIsRequired;
	ParametersStructure.ModifiesDeliveryShipmentPlan         = Not DepositForPackageIsRequired;
	
	ParametersStructure.ARAPCurrency                 = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP                  = "Object.AmountARAP";
	ParametersStructure.AmountARAPByPackage            = ""; 
	
	ParametersStructure.PaymentDate                          = "Object.PaymentDate";
	ParametersStructure.CompanyBankAccount            = "";
	ParametersStructure.CounterpartyBankAccount            = ""; 
	ParametersStructure.CourseNumerator                        = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                      = "Object.CourseDenominator";
	
	ParametersStructure.PathToTSData                        = "Object.Goods";
	
	ParametersStructure.PropsNameTSOrder                  = "";
	ParametersStructure.PathToTSDataPaymentDecryption      = "Object.ARAPDetails";
	
	ParametersStructure.CashAccount                                = "";
	ParametersStructure.Manager                             = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber              = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate               = "Object.IncomingDocumentDate";
	ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
	ParametersStructure.InvoiceForOrders                   = "";
	ParametersStructure.OrderBase                       = "";
	
	ParametersStructure.FormItems.LabelCurrencies          = "CurrencyDecoration";
	ParametersStructure.FormItems.InscriptionStages           = "DecorationPaymentSteps";
	ParametersStructure.FormItems.InscriptionCalculations         = "DecorationSettlementState";
	ParametersStructure.FormItems.PaymentSettlement            = "CreditPaymentForm";
	ParametersStructure.FormItems.AmountOfTSSettlements  = "GoodsAmountARAP";
	ParametersStructure.FormItems.FinancialAccountingGroup  = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	ParametersStructure.PaymentStagesViewOnly            = DepositForPackageIsRequired;
	
	ParametersStructure.PathToTSDataPaymentSteps             = "";
	ParametersStructure.PaymentStepsText                   = "Form.PaymentStepsText";
	ParametersStructure.DocumentAmountForm                  = "";
	ParametersStructure.AmountOfDepositForContainerForm               = "";
	ParametersStructure.InvoiceForSeveralOrdersIsPossible = False;
	ParametersStructure.ARAPObject                       = "Object.ARAPObject";
	
	Return ParametersStructure;
	
EndFunction
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return RedemptionOfReturnablePackagingFromVendorLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return RedemptionOfReturnablePackagingFromVendorLocalization.RequestTextTTReflectedInLocalAccounting();

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
	|	AND ValueAllowed(Partner)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region VATAccounting

// Initializes parameters for registering invoices (received)
//
// Parameters:
//  Object		- DocumentObject.RedemptionOfReturnablePackagingFromVendor, FormDataStructure	- the document to get parameters for.
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
			
	RegistrationParameters.PurchaseOfGoodsWorksServices  = True;
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'Mua lại bao bì luân chuyển';
							|ru = 'Выкуп возвратной тары';
							|en = 'Vendor invoice — returnable packaging'; fa = 'فاکتور تأمین‌کننده — بسته‌بندی برگشتی';
							|it = 'Riscatto dell''imballaggio riutilizzabile';
							|pl = 'Wykup tary zwrotnej';
							|tr = 'İade ambalajların itfası'"));
	RedemptionOfReturnablePackagingFromVendorLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	Return ArrayOfNames
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "RedemptionOfReturnablePackagingFromVendor");
	
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

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.DepositForPackageIsRequired AS DepositForPackageIsRequired,
	|	DocumentData.PaymentDate AS PaymentDate,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.PaymentMethod AS PaymentMethod,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Department AS Department,
	|	DocumentData.Manager AS Manager,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.IncomingDocumentDate AS IncomingDocumentDate,
	|	DocumentData.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	DocumentData.ARAPObject.UUID AS IDARAPObject
	|
	|FROM
	|	Document.RedemptionOfReturnablePackagingFromVendor AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                                        Attributes.Period);
	Query.SetParameter("Number",                                         Attributes.Number);
	Query.SetParameter("Partner",                                       Attributes.Partner);
	Query.SetParameter("Organization",                                   Attributes.Organization);
	Query.SetParameter("Currency",                                        Attributes.Currency);
	Query.SetParameter("DepositForPackageIsRequired",                       Attributes.DepositForPackageIsRequired);
	Query.SetParameter("LocalAccountingCurrency",                Attributes.LocalAccountingCurrency);
	Query.SetParameter("ManagementAccountingCurrency",                    Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("PaymentDate",                                   Attributes.PaymentDate);
	Query.SetParameter("PaymentMethod",                                   Attributes.PaymentMethod);
	Query.SetParameter("ARAPCurrency",                          Attributes.ARAPCurrency);
	Query.SetParameter("Contract",                                       Attributes.Contract);
	Query.SetParameter("IDARAPObject",                  Attributes.IDARAPObject);
	Query.SetParameter("IDOfUnusedFinRecord",          DocumentsPosting.IDOfUnusedFinRecord());
	
	Query.SetParameter("MetadataIdentifier",                       Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("BusinessOperation",                         Enums.BusinessTransactions.PurchaseFromSupplier);
	Query.SetParameter("Counterparty",                                    Attributes.Counterparty);
	Query.SetParameter("LineOfBusiness",                       Attributes.LineOfBusiness);
	Query.SetParameter("Department",                                 Attributes.Department);
	Query.SetParameter("Manager",                                      Attributes.Manager);
	Query.SetParameter("Comment",                                   Attributes.Comment);
	Query.SetParameter("DocumentAmount",                                Attributes.DocumentAmount);
	Query.SetParameter("Posted",                                      Attributes.Posted);
	Query.SetParameter("DeletionMark",                               Attributes.DeletionMark);
	Query.SetParameter("IncomingDocumentNumber",                       Attributes.IncomingDocumentNumber);
	Query.SetParameter("IncomingDocumentDate",                        Attributes.IncomingDocumentDate);
	ContractInformation = Undefined;
	If ValueIsFilled(Attributes.Contract) Then
		ContractInformation = NStr("vi = 'Theo hợp đồng ""%Contract%""';
									|ru = 'По договору ""%Contract%""';
									|en = 'Under the ""%Contract%"" contract'; fa = 'Under the ""%Contract%"" contract';
									|it = 'In base al contratto ""%Contract%""';
									|pl = 'Według umowy ""%Contract%""';
									|tr = '""%Contract%"" sözleşmesi kapsamında'", CommonClientServer.DefaultLanguageCode());
		ContractInformation = StrReplace(ContractInformation, "%Contract%", Attributes.Contract);
	EndIf;
	Query.SetParameter("ContractInformation", ContractInformation);
	
	SetRequestParametersCurrencyCoefficients(Query);
	
EndProcedure

Function QueryTextTableReceivedReturnablePackaging(Query, QueryTexts, Registers)
	
	RegisterName = "ReceivedReturnablePackaging";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	QueryText = "
	|SELECT
	|	GoodsTable.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Count               AS Count,
	|	GoodsTable.AmountIncludingVAT                AS Sum,
	|	&Partner                               AS Partner,
	|	CASE
	|		WHEN GoodsTable.DocumentInflow = VALUE(Document.VendorInvoice.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE GoodsTable.DocumentInflow
	|	END                                  AS DocumentInflow,
	|	TRUE                                 AS Buyout,
	|	&DepositForPackageIsRequired               AS DepositIsRequired,
	|
	|	CASE
	|		WHEN &DepositForPackageIsRequired
	|			THEN &IDOfUnusedFinRecord
	|		ELSE &IDARAPObject
	|	END                                  AS FinRecordID,
	|	CASE
	|		WHEN &DepositForPackageIsRequired
	|			THEN UNDEFINED
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.PurchaseOfReceivedReturnablePackaging)
	|	END                                  AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RedemptionOfReturnablePackagingFromVendor.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""Goods"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
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
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.AmountARAP AS AmountARAP,
	|	DocumentTable.AmountVATARAP AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.RedemptionOfReturnablePackagingFromVendor.Goods AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Query.Parameters.Currency, 
		Query.Parameters.ARAPCurrency,
		Query.Parameters.Period,
		Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",           Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul",          Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If TypeOf(Registers) = Type("Structure") And Registers.Property("VATInvoiced") Then
		Registers.Delete("VATInvoiced");
	EndIf;
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	ValueText_ =
	"SELECT
	|	Goods.Ref.Date AS Period,
	|	Goods.Ref AS Ref,
	|	Goods.Ref.Organization AS Organization,
	|	Goods.Ref.Department AS Department,
	|	Goods.Ref.Counterparty AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS Shipper,
	|	Goods.Ref AS DocumentAcquisitions,
	|	Goods.Ref AS OriginalTradeDocument,
	|	FALSE AS ErrorCorrection,
	|	FALSE AS AdjustmentUnderApprovalOfParties,
	|	FALSE AS ReduceAmountVATDeduction,
	|	UNDEFINED AS PurchaseAdjustmentDocument,
	|	Goods.Ref.VATTaxation AS VATTaxation,
	|	VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) AS VATActivityType,
	|	Goods.VATRate AS VATRate,
	|	Goods.Products AS Products,
	|	UNDEFINED AS InventoryOwnerAttribute,
	|	UNDEFINED AS CCDNumber,
	|	UNDEFINED AS AccountingDivision,
	|	UNDEFINED AS LineOfBusiness,
	|	FALSE AS PurchasePerBatchOfProduction,
	|	UNDEFINED AS LineOfBusinessOfProductionParty,
	|	UNDEFINED AS ToExpenseAs,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS ItemOfOtherAssets,
	|	UNDEFINED AS AnalyticsOfOtherAssets,
	|	UNDEFINED AS Purpose,
	|	Goods.RowID AS RowID,
	|	Goods.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|FROM
	|	Document.RedemptionOfReturnablePackagingFromVendor.Goods AS Goods
	|WHERE
	|	Goods.Ref IN (&Ref)
	|";
	VATAccountingERP.ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, ValueText_);
	
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
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.RedemptionOfReturnablePackagingFromVendor AS DocumentDataHeader
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
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.RedemptionOfReturnablePackagingFromVendor.ARAPDetails AS Table
		|		LEFT JOIN Document.RedemptionOfReturnablePackagingFromVendor AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region Purchase
	
	TextPurchase = "
		|SELECT
		|	Table.Ref                                                      AS Ref,
		|	Table.Ref.Organization                                          AS Organization,
		|	Table.Ref.Partner                                              AS Partner,
		|	Table.Ref.Date                                                 AS RecorderDate,
		|	Table.Ref.Number                                                AS RecorderNumber,
		|
		|	Table.Ref.ARAPObject                                       AS ARAPObject,
		|	Table.Ref.PaymentDate                                          AS PaymentDate,
		|	UNDEFINED                                                        AS PaymentOption,
		|	UNDEFINED                                                        AS PurchaseOrder_,
		|	
		|	Table.AmountIncludingVAT                                                   AS Sum,
		|	Table.AmountARAP                                         AS AmountARAP,
		|	0                                                                   AS AmountARAPByPackage,
		|
		|	Table.Ref.ARAPObjectSettings                                      AS ARAPObjectSettings,
		|	FALSE                                                                AS InvoiceForOrders,
		|	Table.Ref.ARAPCurrency                                 AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)     AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                          AS PaymentMethod,
		|	Table.Ref.Currency                                               AS DocumentCurrency,
		|	Table.Ref.Date                                                 AS DateOfCourse,
		|	UNDEFINED                                                        AS LinkedDocument
		|FROM
		|	Document.RedemptionOfReturnablePackagingFromVendor.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.Ref.DepositForPackageIsRequired
		|";
	
	#EndRegion
	
	#Region IncreasePaymentPlan_
	
	TextPaymentPlan_ = "
		|SELECT
		|	Table.Ref                                                      AS Ref,
		|	Table.Ref.Date                                                 AS RecorderDate,
		|	Table.Ref.Number                                                AS RecorderNumber,
		|	Table.Ref.PaymentDate                    						AS PaymentDate,
		|	Table.Ref.Partner                                              AS Partner,
		|	
		|	Table.Ref.ARAPObject                                       AS ARAPObject,
		|	
		|	Table.Ref.ARAPObjectSettings                                      AS ARAPObjectSettings,
		|	FALSE                                                                AS InvoiceForOrders,
		|	FALSE                                                                AS ExceedingOrder,
		|	UNDEFINED                                                        AS PurchaseOrder_,
		|	Table.AmountARAP                                         AS AmountDue,
		|	Table.Ref.ARAPCurrency                                 AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)     AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                          AS PaymentMethod,
		|	Table.Ref.Currency                                               AS DocumentCurrency,
		|	UNDEFINED                                                        AS PaymentOption,
		|	UNDEFINED                                                        AS LinkedDocument
		|FROM
		|	Document.RedemptionOfReturnablePackagingFromVendor.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.Ref.DepositForPackageIsRequired
		|";

	#EndRegion
	
	#Region PrepaymentsSettlement
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                                     AS Ref,
		|	Table.Ref.Organization                                         AS Organization,
		|	Table.Ref.Partner                                             AS Partner,
		|	
		|	Table.ARAPObject                                             AS CalculationObjectSource,
		|	Table.Ref.ARAPObject                                      AS CalculationObjectReceiver,
		|
		|	Table.Ref.ARAPCurrency                                AS ARAPCurrency,
		|	Table.AmountARAP                                        AS AmountARAP,
		|	Table.Ref.Currency                                              AS DocumentCurrency,
		|	Table.Sum                                                      AS Sum,
		|
		|	Table.Ref.Date                                                AS RecorderDate,
		|	Table.Ref.Date                                                AS DateOfCourse,
		|	Table.Ref.Number                                               AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)         AS BusinessOperation
		|	
		|FROM
		|	Document.RedemptionOfReturnablePackagingFromVendor.ARAPDetails AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.Ref.DepositForPackageIsRequired
		|";
	
	#EndRegion
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan_, TextAdvancePaymentOffset);
	
EndProcedure

#Region Posting

#EndRegion

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.RedemptionOfReturnablePackagingFromVendor";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	ParameterValues.Insert("BusinessOperation",
		Enums.BusinessTransactions.PurchaseFromSupplier);
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		RequestHasSource = False;
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
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
	|	&Comment                            AS Comment,
	|	&Currency                                 AS Currency,
	|	&DocumentAmount                         AS Sum,
	|	UNDEFINED                            AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&ContractInformation                   AS More,
	|	&IncomingDocumentDate                 AS SourceDocumentDate,
	|	FALSE                                    AS ReverseTransactionCorrection,
	|	UNDEFINED                            AS ReversedDocument,
	|	UNDEFINED                            AS CorrectedDocument,
	|	&IncomingDocumentNumber                AS SourceDocumentNumber,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf

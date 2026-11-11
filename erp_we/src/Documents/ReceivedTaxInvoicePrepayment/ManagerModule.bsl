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
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("VATAccounting");
	
	ReceivedTaxInvoicePrepaymentLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection:
//     of Table elements<Register Name> - Assignment tables - a table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ReceivedTaxInvoicePrepayment") Then
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
		
		QueryTextTableVATPrepaymentsToVendor(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableVATRegisterRecords(Query, QueryTexts, Registers);
		
		ReceivedTaxInvoicePrepaymentLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.ReceivedTaxInvoicePrepayment.AddCreateCommandBasedOnCorrectiveInvoice(GenerationCommands);
	If GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals") Then
		Documents.IssuedTaxInvoicePrepayment.AddGenerateCommand(GenerationCommands);
	EndIf;
	ReceivedTaxInvoicePrepaymentLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
EndProcedure

// Adds a command creation of the document "the invoice received (advance)".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  
// Returns:
//  - Undefined - if there is no access right to add invoices received in advance
//  - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.ReceivedTaxInvoicePrepayment) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ReceivedTaxInvoicePrepayment.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ReceivedTaxInvoicePrepayment);
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command creation of the document "the invoice received (advance)".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  
// Returns:
//  - Undefined - if there is no access right to add invoices received in advance
//  - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands 
//
Function AddCreateCommandBasedOnCorrectiveInvoice(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.ReceivedTaxInvoicePrepayment) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "VATAccountingERPClient.CorrectiveInvoiceReceivedAdvance";
		CreateBasedOnCommand.Id = "CorrectiveInvoice";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Hóa đơn GTGT điều chỉnh';
												|ru = 'Исправленный счет-фактура';
												|en = 'Corrected tax invoice'; fa = 'فاکتور مالیاتی اصلاحی';
												|it = 'Fattura rettificata';
												|pl = 'Poprawiona faktura';
												|tr = 'Düzeltilmiş vergi faturası'");
		CreateBasedOnCommand.WriteMode = "Post";
		
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
	
	ReceivedTaxInvoicePrepaymentLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

// Generates tasks for reflection in the sales book.
//
// Parameters:
//  ChangesTable - ValueTable:
//	 * Document - DocumentRef - document for which the settlement status has changed
//	 * Period - Date - change period
//
Procedure CreateTasksForGeneratingVATRegisteredRecords(ChangesTable) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("ChangesTable", ChangesTable);
	Query.Text =
	"SELECT DISTINCT
	|	ChangesTable.Period AS Period,
	|	ChangesTable.Document AS ARAPDocument
	|INTO TTCalculations
	|FROM
	|	&ChangesTable AS ChangesTable
	|INDEX BY
	|	ARAPDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TaxInvoice.DocumentBasis AS TaxInvoice,
	|	TaxInvoice.Organization       AS Organization,
	|	Calculations.Period                AS Month
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS TaxInvoice
	|
	|	INNER JOIN
	|		TTCalculations AS Calculations
	|	ON
	|		Calculations.ARAPDocument = TaxInvoice.DocumentBasis
	|
	|WHERE
	|	TaxInvoice.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentsRegistry.Ref       AS TaxInvoice,
	|	TaxInvoice.Organization       AS Organization,
	|	Calculations.Period                AS Month
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		INNER JOIN TTCalculations AS Calculations
	|		ON DocumentsRegistry.Ref = Calculations.ARAPDocument
	|		INNER JOIN Document.ReceivedTaxInvoicePrepayment AS TaxInvoice
	|		ON DocumentsRegistry.ReversedDocument = TaxInvoice.DocumentBasis
	|WHERE
	|	TaxInvoice.Posted


	|";
	
	Selection = Query.Execute().Select();
	InformationRegisters.JobsForGeneratingVATRecords.CreateRegisterEntriesBasedOnSampleData(Selection);
	
EndProcedure

#Region ConductingLocalAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - The text of the reflection request in the regl. accounting.
//
Function TextOfReflectionInLocalAccounting() Export
	
	QueryText = "";
	ReceivedTaxInvoicePrepaymentLocalization.GenerateReflectionTextInLocalAccounting(QueryText);
	Return QueryText;
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	QueryText = "";
	ReceivedTaxInvoicePrepaymentLocalization.GenerateRequestTextTTForReflectionInLocalAccounting(QueryText);
	Return QueryText;
	
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

// The function creates a representation of the invoice.
//
// Parameters:
//  Number - String - Invoice number.
//  Date - Date - The date of the invoice.
//  Posted - Boolean - Indicates whether the document is being processed.
//  
// Returns:
//	String - Presentation of the invoice.
//
Function InvoicePresentation_(Number, Date, Posted = True) Export
	
	HeaderStructure_ = New Structure;
	HeaderStructure_.Insert("Date", Date);
	HeaderStructure_.Insert("Number", Number);
	
	SubstringsArray = New Array;
	SubstringsArray.Add(TMCommonUseClientServer.GenerateDocumentTitle(HeaderStructure_, NStr("vi = 'Hóa đơn GTGT';
																							|ru = 'Счет-фактура';
																							|en = 'Tax invoice'; fa = 'فاکتور مالیاتی';
																							|it = 'Fattura';
																							|pl = 'Tax invoice';
																							|tr = 'Vergi faturası'")));
	If Not Posted Then
		SubstringsArray.Add(NStr("vi = '(chưa kết chuyển)';
								|ru = '(не проведен)';
								|en = '(not posted)'; fa = '(not posted)';
								|it = '(non registrato)';
								|pl = '(nie zatwierdzony)';
								|tr = '(kaydedilmedi)'"));
	EndIf;
	Presentation = StrConcat(SubstringsArray, " ");
	
	Return Presentation;
	
EndFunction

// Creates a hyperlink to go to the list of documents
// 
// Parameters:
// 	Parameters - Structure - Formatting options for the hyperlink
// Returns:
// 	FormattedString, Undefined - 
Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	If Not AccessRight("Read", Metadata.Documents.ReceivedTaxInvoicePrepayment) Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Danh sách hóa đơn GTGT ứng trước';
						|ru = 'Список счетов-фактур на аванс';
						|en = 'List of tax invoices for advance'; fa = 'List of tax invoices for advance';
						|it = 'Elenco di fatture per anticipo';
						|pl = 'Lista faktur dla zaliczki';
						|tr = 'Avans faturalarının listesi'");
	FullFormName = Metadata.Documents.ReceivedTaxInvoicePrepayment.DefaultListForm.FullName();
	
	Return New FormattedString(HyperlinkText, , StyleColors.HyperlinkColor, , FullFormName);

EndFunction

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ObjectForm" Then
		If GetFunctionalOption("LocalizationRFService") Then
			SelectedForm = "RFDocumentForm";
			StandardProcessing = False;
		Else
			SelectedForm = "DocumentForm";
			StandardProcessing = False;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Internal

// Gets the table on the issued advance payments, and generated invoices.
// 
// Parameters:
//  Organization - CatalogRef.Companies - the organization that you are receiving advances for
//  BeginOfPeriod - Date - the beginning of the period for which advances are received.
//  EndOfPeriod - Date - end of the period for which advances are received.
//  AdditionalParameters - Structure - See AdditionalParametersOfAdvancesIssued()
// 
// Returns:
//  ValueTable - information on advances issued, contains columns:
// * DocumentBasis - DocumentRef - the document of the advance.
// * VATTaxation - EnumRef.VATTaxationTypes - VAT taxation.
// * Number - String - number of the advance document.
// * Date - Date - date of the advance document.
// * Vendor - CatalogRef.Counterparties - the counterparty to whom the advance was issued.
// * DocumentCurrency - CatalogRef.Currencies - currency of the advance payment.
// * VATRate - CatalogRef.VATRates - VAT rate. Can be empty, based on the parameter of "Virusresistant"
// * Organization - CatalogRef.Companies - The company that issued the advance
// * CurrencyAmount - Number - the amount in the advance currency.
// * AmountOfSchedAdvance - Number - the amount of the advance in the regl currency. accounting's.
// * VATAmount - Number - amount of VAT.
// * TaxInvoiceNumber - String - number of invoices registered in the document of the advance.
// * TaxInvoiceDate - Date - date of the invoice registered under the advance document.
// * TaxInvoiceAmount - Number - the amount of the invoice registered under the advance payment document.
// * TaxInvoice - DocumentRef.ReceivedTaxInvoicePrepayment - Link to the invoice registered under the advance document.
Function ReceiveAdvancesIssued(Organization, BeginOfPeriod, EndOfPeriod, AdditionalParameters) Export
	
	PrepaymentsToVendor_ = New ValueTable();
	
	PrepaymentsToVendor_.Columns.Add("DocumentBasis");
	PrepaymentsToVendor_.Columns.Add("TypeOfFoundationDocument");
	PrepaymentsToVendor_.Columns.Add("VATTaxation");
	PrepaymentsToVendor_.Columns.Add("Number");
	PrepaymentsToVendor_.Columns.Add("Date");
	PrepaymentsToVendor_.Columns.Add("Vendor");
	PrepaymentsToVendor_.Columns.Add("LineOfBusiness");
	PrepaymentsToVendor_.Columns.Add("DocumentCurrency");
	PrepaymentsToVendor_.Columns.Add("ARAPObject");
	PrepaymentsToVendor_.Columns.Add("Organization");
	
	PrepaymentsToVendor_.Columns.Add("VATRate");
	
	PrepaymentsToVendor_.Columns.Add("CurrencyAmount");
	PrepaymentsToVendor_.Columns.Add("AmountOfSchedAdvance");
	PrepaymentsToVendor_.Columns.Add("VATAmount");
	
	PrepaymentsToVendor_.Columns.Add("Sfsformed");
	PrepaymentsToVendor_.Columns.Add("Patch");
	PrepaymentsToVendor_.Columns.Add("TaxInvoiceNumber");
	PrepaymentsToVendor_.Columns.Add("TaxInvoiceDate");
	PrepaymentsToVendor_.Columns.Add("TaxInvoiceAmount");
	PrepaymentsToVendor_.Columns.Add("TaxInvoice");
	
	GroupFields = "Vendor, DocumentBasis, TypeOfFoundationDocument, VATTaxation,
						|DocumentCurrency, VATRate, Organization,
						|Number, Date, TaxInvoiceNumber, TaxInvoiceDate, TaxInvoice, Sfsformed, Patch";
	SummationFields = "AmountOfSchedAdvance, VATAmount, CurrencyAmount";

	If AdditionalParameters.InContextOfOR = True Then
		GroupFields = GroupFields + ", ARAPObject";
		SummationFields = SummationFields + ", TaxInvoiceAmount";
	Else
		GroupFields = GroupFields + ", TaxInvoiceAmount";
	EndIf;
	
	If AdditionalParameters.InContextOfNP = True Then
		GroupFields = GroupFields + ", LineOfBusiness";
	EndIf;
	
	If TypeOf(Organization) = Type("Array") And Organization.Count() = 1 Then
		DefaultVATRate                  = VATAccountingERP.DefaultVATRate(Organization[0], EndOfPeriod, True);
		PreferentialVATTaxationIsApplied = VATAccountingLocalization.PreferentialVATTaxationIsApplied(Organization[0], BeginOfPeriod);
	ElsIf TypeOf(Organization) = Type("CatalogRef.Companies") Then
		DefaultVATRate = VATAccountingERP.DefaultVATRate(Organization, EndOfPeriod, True); 
		PreferentialVATTaxationIsApplied = VATAccountingLocalization.PreferentialVATTaxationIsApplied(Organization, BeginOfPeriod);
	Else
		DefaultVATRate = VATAccountingERP.DefaultVATRate(Undefined, EndOfPeriod, True);
		PreferentialVATTaxationIsApplied = False;
	EndIf;
	VATRateIsEmpty = Catalogs.VATRates.EmptyRef();
	
	TempTablesManager = New TempTablesManager;
	
	Result = RequestResultForAdvances(
			BeginOfPeriod,
			EndOfPeriod,
			Organization,
			AdditionalParameters.ARAPDocument,
			TempTablesManager,
			AdditionalParameters.ExcludeJUDAS);
	
	SampleAdvancePayment = Result.Select();
	
	DocumentDataTable_ = DocumentDataTable_(TempTablesManager); // ValueTable - 
	DocumentDataTable_.Indexes.Add("DocumentBasis, ARAPObject");
	
	While SampleAdvancePayment.Next() Do
		
		If Not ValueIsFilled(SampleAdvancePayment.DocumentBasis)
			Or SampleAdvancePayment.AmountOfSchedAdvance = 0
			Or TypeOf(SampleAdvancePayment.Object) = Type("CatalogRef.Complaints") Then
			Continue;
		EndIf;
		
		SubjectToVATAtCustomer = SampleAdvancePayment.VATTaxation =
									Enums.VATTaxationTypes.SubjectToVATAtCustomer;
									
		If PreferentialVATTaxationIsApplied And Not SubjectToVATAtCustomer Then
			Continue;
		EndIf;
		
		FilterStructure1 = New Structure("DocumentBasis, ARAPObject");
		FillPropertyValues(FilterStructure1, SampleAdvancePayment);
		
		ArrayOfBids = New Array;
		ArrayOfCoefficients = New Array;
		
		DocumentData = DocumentDataTable_.FindRows(FilterStructure1);
		For Each String In DocumentData Do
			If SubjectToVATAtCustomer Then
				CurRate_ = DefaultVATRate;
			ElsIf ValueIsFilled(String.VATRate) Then
				CurRate_ = String.VATRate;
			Else
				CurRate_ = DefaultVATRate;
			EndIf;
			ArrayOfBids.Add(CurRate_);
			ArrayOfCoefficients.Add(String.Sum);
		EndDo;
		
		If ArrayOfBids.Count() = 0 Then
			ArrayOfBids.Add(DefaultVATRate);
			ArrayOfCoefficients.Add(1);
		EndIf;
		
		CurrencyAmountAtRates = Common.DistributeAmountInProportionToCoefficients(
			SampleAdvancePayment.CurrencyAmount,
			ArrayOfCoefficients);
		
		BidAmount = Common.DistributeAmountInProportionToCoefficients(
			SampleAdvancePayment.AmountOfSchedAdvance,
			ArrayOfCoefficients);
		
		IndexOf = 0;
		For Each Rate1 In ArrayOfBids Do
			
			Sum = BidAmount[IndexOf];
			CurrencyAmount = CurrencyAmountAtRates[IndexOf];
			IndexOf = IndexOf + 1;
			
			If VATAccountingERP.InsignificantRate(Rate1) Then
				Continue;
			EndIf;
			If Sum = 0 Then
				Continue;
			EndIf;
			
			NewRow = PrepaymentsToVendor_.Add();
			FillPropertyValues(NewRow, SampleAdvancePayment);
			If ValueIsFilled(SampleAdvancePayment.TaxInvoice) Then
				NewRow.Sfsformed = True;
			Else
				NewRow.Sfsformed = False;
			EndIf;

			AdvanceVATRate = Rate1;
			ReceivedTaxInvoicePrepaymentLocalization.SetAdvanceVATRate(AdvanceVATRate);
			
			If SubjectToVATAtCustomer Then
				CurrencyAmount = CurrencyAmount + VATAccountingERPClientServer.CalculateVATAmount(CurrencyAmount, Rate1, False);
				Sum = Sum + VATAccountingERPClientServer.CalculateVATAmount(Sum, Rate1, False);
			EndIf;
			
			NewRow.VATRate       = ?(AdditionalParameters.ByVATRates, AdvanceVATRate, VATRateIsEmpty);
			NewRow.CurrencyAmount   = CurrencyAmount;
			NewRow.AmountOfSchedAdvance = Sum;
			NewRow.VATAmount        = Round(VATAccountingERPClientServer.CalculateVATAmount(
											NewRow.AmountOfSchedAdvance,
											NewRow.VATRate
											), 2);
			
		EndDo;
	
	EndDo;
	
	PrepaymentsToVendor_.GroupBy(GroupFields, SummationFields);
	
	Return PrepaymentsToVendor_;
	
EndFunction

//Returns the number of invoices to be processed.
//
// Parameters:
//	Parameters - Structure:
//	 * CompanyArray - Array - Array of organizations.
//	 * BeginOfPeriod - Date - bottom limit on the date of the Foundation document.
//	 * EndOfPeriod - Date - upper limit on the date of the Foundation document.
//	 * NoPeriodLimit - Boolean - do not limit the date of the foundation document
//
// Returns:
//	Number - the number of invoices to be processed.
//
Function ThereAreInvoicesForRegistration(Parameters) Export
	
	If Parameters.Property("MonthEndTransactions") And Parameters.EndOfPeriod = EndOfQuarter(Parameters.EndOfPeriod) Then
		BeginOfPeriod = BegOfQuarter(Parameters.BeginOfPeriod);
	Else
		BeginOfPeriod = Parameters.BeginOfPeriod;
	EndIf;
	
	AdditionalParameters = AdditionalParametersOfAdvancesIssued();
	AdditionalParameters.ExcludeJUDAS = True;
	
	PrepaymentsFromCustomerLayout = ReceiveAdvancesIssued(Parameters.CompanyArray, BeginOfPeriod, Parameters.EndOfPeriod, AdditionalParameters);
	
	If Parameters.Property("ReturnFullTable") Then
		Return PrepaymentsFromCustomerLayout;
	Else
		Return PrepaymentsFromCustomerLayout.FindRows(New Structure("TaxInvoice", EmptyRef())).Count();
	EndIf;
	
EndFunction

// Additional parameters of advances issued.
// 
// Returns:
//  Structure - Additional Parameters Of Advances Issued:
// * ARAPDocument - DocumentRef, Undefined - The settlement document for which advances are received, If Uncertain, then for all the calculated documents.
// * ByVATRates - Boolean - If True, the columns with the VAT rate and amount will be filled in.
// * InContextOfOR - Boolean - 
// * ExcludeJUDAS - Boolean - 
// * InContextOfNP - Boolean - 
Function AdditionalParametersOfAdvancesIssued() Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ARAPDocument", Undefined);
	AdditionalParameters.Insert("ByVATRates", False);
	AdditionalParameters.Insert("InContextOfOR",        False);
	AdditionalParameters.Insert("ExcludeJUDAS",     False);
	AdditionalParameters.Insert("InContextOfNP",        True);

	Return AdditionalParameters;
	
EndFunction

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;
	
	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref                                AS Ref,
	|	DocumentData.Organization                           AS Organization,
	|	DocumentData.VATTaxation                    AS VATTaxation,
	|	DocumentData.Counterparty                            AS Counterparty,
	|	DocumentData.Counterparty                            AS Vendor,
	|	DocumentData.DocumentBasis                     AS DocumentPayments,
	|	DocumentData.Date                                  AS Date,
	|	DocumentData.Date                                  AS DateReceived,
	|	DocumentData.TransactionKindCode                       AS TransactionKindCode,
	|	DocumentData.DateCreated                       AS Period,
	|	DocumentData.DateCreated                       AS DateCreated,
	|	DocumentData.Number                                 AS Number,
	|	DocumentData.Number                                 AS NumberForPrinting,
	|	DocumentData.DigitallyReceived               AS DigitallyReceived,
	|	DocumentData.Patch                           AS Patch,
	|	DocumentData.CorrectionNumber                      AS CorrectionNumber,
	|	DocumentData.CorrectionDate                       AS CorrectionDate,
	|	DocumentData.BaseDocumentTaxInvoice                  AS BaseDocumentTaxInvoice,
	|	DocumentData.BaseDocumentTaxInvoice.Date             AS DateOfBaseInvoice,
	|	DocumentData.Posted                              AS Posted,
	|	DocumentData.DeletionMark                       AS DeletionMark,
	|	DocumentData.Comment                           AS Comment,
	|	DocumentData.Department                         AS Department,
	|	DocumentData.EmployeeResponsible                         AS EmployeeResponsible,
	|	DocumentData.ManualAdjustmentOfTaxInvoiceRegister          AS ManualAdjustmentOfTaxInvoiceRegister,
	|	DocumentData.Sum                                 AS Sum,
	|	DocumentData.RecordingInAccountingDate                   AS RecordingInAccountingDate,
	|	DocumentData.Organization.LocalAccountingCurrency AS CurrencyOfComplianceAccounting
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("MetadataIdentifier",   Common.MetadataObjectID("Document.ReceivedTaxInvoicePrepayment"));
	Query.SetParameter("CurrencyOfManAccounting",            Constants.ManagementAccountingCurrency.Get());
	
	If TypeOf(Attributes.DocumentPayments) = Type("DocumentRef.SourceDocument") Then
		EnteringResiduesInVU = VATAccountingERPInternal.EnteringResiduesInVU(Attributes.DocumentPayments);
	Else
		EnteringResiduesInVU = False;
	EndIf;
	Query.SetParameter("EnteringResiduesInVU", EnteringResiduesInVU);
	
	SetParametersForPrimaryDocumentDetails(Query);
	
	CorrectionInformation = "";
	If Attributes.Patch
		And ValueIsFilled(Attributes.CorrectionDate)
		And ValueIsFilled(Attributes.CorrectionNumber) Then
		StringPattern = "vi = 'Bản chỉnh sửa %1 ngày %2';
						|ru = 'Исправление %1 от %2';
						|en = 'Correction %1 dated %2';
						|it = 'Correzione %1 di %2';
						|pl = 'Korekta %1 z dn. %2';
						|tr = '%2 tarihli %1 düzeltmesi'"; // @NStr
		CorrectionInformation = StringFunctionsClientServer.SubstituteParametersToString(
										StringPattern,
										Attributes.CorrectionNumber,
										Attributes.CorrectionDate);
	EndIf;
	Query.SetParameter("CorrectionInformation", CorrectionInformation);
	
	If Attributes.Patch
		And ValueIsFilled(Attributes.CorrectionDate)
		And ValueIsFilled(Attributes.DateOfBaseInvoice)
		And BegOfQuarter(Attributes.CorrectionDate) <> BegOfQuarter(Attributes.DateOfBaseInvoice) Then
		Query.SetParameter("FixIsInAnotherQuarter", True);
	Else
		Query.SetParameter("FixIsInAnotherQuarter", False);
	EndIf;
		
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure SetParametersForPrimaryDocumentDetails(Query)
	
	If Query.Parameters.Property("PaymentDocumentNumber") Then
		Return;
	EndIf;
	
	RequestingPrimaryDocumentData = New Query;
	RequestingPrimaryDocumentData.Text =
	"SELECT TOP 1
	|	SourceDocumentsData.Number            AS PaymentDocumentNumber,
	|	SourceDocumentsData.Date             AS PaymentDocumentDate,
	|	SourceDocumentsData.RecorderDate AS ReferenceDocumentDateForCertificate
	|FROM
	|	InformationRegister.SourceDocumentsData AS SourceDocumentsData
	|WHERE
	|	SourceDocumentsData.Organization = &Organization
	|	AND SourceDocumentsData.Document = &DocumentBasis";
	
	RequestingPrimaryDocumentData.SetParameter("Organization",       Query.Parameters.Organization);
	RequestingPrimaryDocumentData.SetParameter("DocumentBasis", Query.Parameters.DocumentPayments);
	
	Result = RequestingPrimaryDocumentData.Execute();
	
	If Result.IsEmpty() Then
		Query.SetParameter("PaymentDocumentNumber", "");
		Query.SetParameter("PaymentDocumentDate",  Date('0001,01,01'));
		Query.SetParameter("ReferenceDocumentDateForCertificate",        Date('0001,01,01'));
	Else
		Selection = Result.Select();
		Selection.Next();
		
		Query.SetParameter("PaymentDocumentNumber", ObjectsPrefixesClientServer.NumberForPrinting(
			Selection.PaymentDocumentNumber, False, True));
		Query.SetParameter("PaymentDocumentDate",  Selection.PaymentDocumentDate);
		Query.SetParameter("ReferenceDocumentDateForCertificate",        Selection.ReferenceDocumentDateForCertificate);
	EndIf;
	
EndProcedure

Procedure InitializeTTAdvances(Query) Export
	
	If Query.Parameters.Property("TTAdvancesInitialized") Then
		Return;
	EndIf;
	
	RequestTTAdvances = New Query;
	RequestTTAdvances.TempTablesManager = Query.TempTablesManager;
	RequestTTAdvances.SetParameter("Ref", Query.Parameters.Ref);
	RequestTTAdvances.SetParameter("ReferenceDocumentDateForCertificate", Query.Parameters.ReferenceDocumentDateForCertificate);
	RequestTTAdvances.SetParameter("CurrencyOfManAccounting", Query.Parameters.CurrencyOfManAccounting);
	RequestTTAdvances.SetParameter("CurrencyOfComplianceAccounting", Query.Parameters.CurrencyOfComplianceAccounting);
	
	RequestTTAdvances.Text = 
	"SELECT
	|	TableAdvances.VATRate AS VATRate,
	|	TableAdvances.LineOfBusiness AS LineOfBusiness,
	|	TableAdvances.RowID AS RowID,
	|	TableAdvances.ARAPObject AS ARAPObject,
	|	SUM(CASE
	|		WHEN TableAdvances.Sum <> 0
	|			THEN (TableAdvances.Sum - TableAdvances.AmountIncludingVATFee) - (TableAdvances.VATAmount - TableAdvances.AmountVATFee)
	|		ELSE 0
	|	END) AS AmountExcludingVAT,
	|	SUM((TableAdvances.VATAmount - TableAdvances.AmountVATFee)) AS VAT,
	|	SUM(CASE
	|		WHEN TableAdvances.Sum <> 0
	|			THEN CASE WHEN ISNULL(CurrencyExchangeRateManAccounting.CourseNumerator, 0) = 0
	|				THEN (TableAdvances.Sum - TableAdvances.AmountIncludingVATFee) - (TableAdvances.VATAmount - TableAdvances.AmountVATFee)
	|				ELSE ((TableAdvances.Sum - TableAdvances.AmountIncludingVATFee) - (TableAdvances.VATAmount - TableAdvances.AmountVATFee))
	|							* CurrencyExchangeRateManAccounting.CourseDenominator / CurrencyExchangeRateManAccounting.CourseNumerator END
	|		ELSE 0
	|	END) AS AmountExcludingVATMan,
	|	SUM(CASE WHEN ISNULL(CurrencyExchangeRateManAccounting.CourseNumerator, 0) = 0
	|		THEN (TableAdvances.VATAmount - TableAdvances.AmountVATFee)
	|		ELSE (TableAdvances.VATAmount - TableAdvances.AmountVATFee) * CurrencyExchangeRateManAccounting.CourseDenominator / CurrencyExchangeRateManAccounting.CourseNumerator
	|	END) AS VATManag
	|INTO TTAdvances
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment.Prepayments AS TableAdvances
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(
	|				&ReferenceDocumentDateForCertificate,
	|				Currency = &CurrencyOfManAccounting AND BaseCurrency = &CurrencyOfComplianceAccounting) AS CurrencyExchangeRateManAccounting
	|			ON &CurrencyOfComplianceAccounting <> &CurrencyOfManAccounting
	|WHERE
	|	TableAdvances.Ref = &Ref
	|
	|GROUP BY
	|	TableAdvances.LineOfBusiness,
	|	TableAdvances.VATRate,
	|	TableAdvances.RowID,
	|	TableAdvances.ARAPObject
	|";
	RequestTTAdvances.Execute();
	
	Query.SetParameter("TTAdvancesInitialized", True);
	
EndProcedure

Function QueryTextTableVATPrepaymentsToVendor(Query, QueryTexts, Registers)
	
	RegisterName = "VATPrepaymentsToVendor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTTAdvances(Query);
	
	QueryText =
	"SELECT
	|	&Date                                                         AS Period,
	|	VALUE(AccumulationRecordType.Expense)                        AS RecordType,
	|	&Organization                                                  AS Organization,
	|	&DocumentPayments                                               AS DocumentPayments,
	|	&Vendor                                                    AS Counterparty,
	|	CASE
	|		WHEN &Patch
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END                                                         AS CorrectedTaxInvoice,
	|	&Department                                                AS Department,
	|	TableAdvances.LineOfBusiness                         AS LineOfBusiness,
	|	TableAdvances.VATRate                                       AS VATRate,
	|	TableAdvances.AmountExcludingVAT                                     AS AmountExcludingVAT,
	|	TableAdvances.VAT                                             AS VAT,
	|	TableAdvances.VATManag                                          AS VATManag,
	|	VALUE(Enum.EventsVATFromPrepayments.DeductionFromPrepaymentToVendor) AS Event,
	|	UNDEFINED                                                  AS PrepaymentsSettlementDocument,
	|	FALSE                                                          AS PeriodEndTransaction,
	|	TableAdvances.RowID                             AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATDeductionFromPrepaymentToVendor) AS BusinessTransactionSetting,
	|	FALSE                                                          AS ReversingEntry,
	|	TableAdvances.ARAPObject                                  AS ARAPObject
	|FROM
	|	TTAdvances AS TableAdvances
	|";
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDataBases(Query, QueryTexts)
	
	RegisterName = "TTDataBases";
	
	QueryText =  "SELECT
	|	DocumentData.Ref AS Ref,
	|	BaseCap.LineOfBusiness AS LineOfBusiness,
	|	CASE BaseCap.BusinessOperation
	|		WHEN VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor)
	|			THEN VALUE(Enum.BusinessTransactions.PaymentToVendor)
	|		WHEN VALUE(Enum.BusinessTransactions.OBEntryUnmatchedIntercompanyPrepayment)
	|			THEN VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.PaymentToVendor)
	|	END AS BusinessOperation,
	|	DocumentData.DocumentBasis AS DocumentBasis,
	|	BaseCap.Warehouse AS StorageLocation,
	|	UNDEFINED AS Contract,
	|	BaseCap.Partner AS Partner
	|INTO TTDataBases
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS DocumentData
	|		INNER JOIN Document.OBEntry AS BaseCap
	|		ON DocumentData.DocumentBasis = BaseCap.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	CASE BaseCap.BusinessOperation
	|		WHEN VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor)
	|			THEN VALUE(Enum.BusinessTransactions.PaymentToVendor)
	|		WHEN VALUE(Enum.BusinessTransactions.OBEntryUnmatchedIntercompanyPrepayment)
	|			THEN VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.PaymentToVendor)
	|	END AS BusinessOperation,
	|	DocumentData.DocumentBasis AS DocumentBasis,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS StorageLocation,
	|	UNDEFINED AS Contract,
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS DocumentData
	|		INNER JOIN Document.OBEntryARAP AS BaseCap
	|		ON DocumentData.DocumentBasis = BaseCap.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	BaseCap.LineOfBusiness AS LineOfBusiness,
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|	DocumentData.DocumentBasis AS DocumentBasis,
	|	UNDEFINED AS StorageLocation,
	|	BaseCap.Contract AS Contract,
	|	BaseCap.Partner AS Partner
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS DocumentData
	|		INNER JOIN Document.SourceDocument AS BaseCap
	|		ON DocumentData.DocumentBasis = BaseCap.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	BaseCap.LineOfBusiness AS LineOfBusiness,
	|	BaseCap.BusinessOperation AS BusinessOperation,
	|	DocumentData.DocumentBasis AS DocumentBasis,
	|	UNDEFINED AS StorageLocation,
	|	BaseCap.Contract AS Contract,
	|	BaseCap.Partner AS Partner
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS DocumentData
	|		INNER JOIN Document.CashVoucher AS BaseCap
	|		ON DocumentData.DocumentBasis = BaseCap.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	BaseCap.LineOfBusiness AS LineOfBusiness,
	|	BaseCap.BusinessOperation AS BusinessOperation,
	|	DocumentData.DocumentBasis AS DocumentBasis,
	|	UNDEFINED AS StorageLocation,
	|	BaseCap.Contract AS Contract,
	|	BaseCap.Partner AS Partner
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS DocumentData
	|		INNER JOIN Document.BankAccountIssue AS BaseCap
	|		ON DocumentData.DocumentBasis = BaseCap.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	UNDEFINED AS LineOfBusiness,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	DocumentData.DocumentBasis AS DocumentBasis,
	|	UNDEFINED AS StorageLocation,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS Partner
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS DocumentData
	|		INNER JOIN Document.ARAPSettlement AS BaseCap
	|		ON DocumentData.DocumentBasis = BaseCap.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	BaseCap.LineOfBusiness AS LineOfBusiness,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	DocumentData.DocumentBasis AS DocumentBasis,
	|	UNDEFINED AS StorageLocation,
	|	BaseCap.Contract AS Contract,
	|	BaseCap.Partner AS Partner
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS DocumentData
	|		INNER JOIN Document.ReturnOfGoodsToVendor AS BaseCap
	|		ON DocumentData.DocumentBasis = BaseCap.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	BaseCap.LineOfBusiness AS LineOfBusiness,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	DocumentData.DocumentBasis AS DocumentBasis,
	|	UNDEFINED AS StorageLocation,
	|	BaseCap.Contract AS Contract,
	|	BaseCap.Partner AS Partner
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS DocumentData
	|		INNER JOIN Document.IntercompanyGoodsReturn AS BaseCap
	|		ON DocumentData.DocumentBasis = BaseCap.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	UNDEFINED AS LineOfBusiness,
	|	VALUE(Enum.BusinessTransactions.AdvanceHolderPaymentToVendor) AS BusinessOperation,
	|	DocumentData.DocumentBasis AS DocumentBasis,
	|	UNDEFINED AS StorageLocation,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS Partner
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS DocumentData
	|		INNER JOIN Document.ExpenseReport AS BaseCap
	|		ON DocumentData.DocumentBasis = BaseCap.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	BaseCap.LineOfBusiness AS LineOfBusiness,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	DocumentData.DocumentBasis AS DocumentBasis,
	|	UNDEFINED AS StorageLocation,
	|	BaseCap.Contract AS Contract,
	|	BaseCap.Partner AS Partner
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS DocumentData
	|		INNER JOIN Document.PurchaseAdjustment AS BaseCap
	|		ON DocumentData.DocumentBasis = BaseCap.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	UNDEFINED AS LineOfBusiness,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	DocumentData.DocumentBasis AS DocumentBasis,
	|	UNDEFINED AS StorageLocation,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS Partner
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS DocumentData
	|		INNER JOIN Document.ARAPAdjustment AS BaseCap
	|		ON DocumentData.DocumentBasis = BaseCap.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	UNDEFINED AS LineOfBusiness,
	|	VALUE(Enum.BusinessTransactions.ARAPAdjustment) AS BusinessOperation,
	|	DocumentData.DocumentBasis AS DocumentBasis,
	|	UNDEFINED AS StorageLocation,
	|	BaseCap.Contract AS Contract,
	|	BaseCap.Partner AS Partner
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS DocumentData
	|		INNER JOIN Document.ARAPAdjustmentFinancialInstruments AS BaseCap
	|		ON DocumentData.DocumentBasis = BaseCap.Ref
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDataBases", QueryTexts) Then
		QueryTextTTDataBases(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref                                  AS Ref,
	|	&Date                                    AS IBDocumentDate,
	|	&Number                                   AS IBDocumentNumber,
	|	&MetadataIdentifier                 AS RefType,
	|	&Organization                             AS Organization,
	|	ISNULL(TableOfBases_.BusinessOperation, VALUE(Enum.BusinessTransactions.PaymentToVendor))
	|	                                         AS BusinessOperation,
	|	TableOfBases_.Partner                 AS Partner,
	|	&Counterparty                              AS Counterparty,
	|	TableOfBases_.Contract                 AS Contract,
	|	TableOfBases_.LineOfBusiness AS LineOfBusiness,
	|	TableOfBases_.StorageLocation           AS StorageLocation,
	|	&Department                           AS Department,
	|	&EmployeeResponsible                           AS EmployeeResponsible,
	|	&Comment                             AS Comment,
	|	DocumentData.Organization.LocalAccountingCurrency AS Currency,
	|	&Sum                                   AS Sum,
	|	UNDEFINED                             AS Status,
	|	&Posted                                AS Posted,
	|	&DeletionMark                         AS DeletionMark,
	|	FALSE                                     AS AdditionalRecord,
	|	&CorrectionInformation                 AS More,
	|	&DateCreated                         AS SourceDocumentDate,
	|	&NumberForPrinting                           AS SourceDocumentNumber,
	|	FALSE                                     AS ReverseTransactionCorrection,
	|	UNDEFINED                             AS ReversedDocument,
	|	UNDEFINED                             AS CorrectedDocument,
	|	&RecordingInAccountingDate                     AS RecordingInAccountingDate,
	|	UNDEFINED                             AS Priority
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS DocumentData
	|		LEFT JOIN TTDataBases AS TableOfBases_
	|		ON DocumentData.Ref = TableOfBases_.Ref
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	TextOfEvent = QueryTexts.Add(QueryText, RegisterName);
	ReceivedTaxInvoicePrepaymentLocalization.AddRequestTextToDocumentRegistry(Query, TextOfEvent, Registers);
	Return QueryText;
	
EndFunction

Function QueryTextTableVATRegisterRecords(Query, QueryTexts, Registers)
	
	RegisterName = "VATRegisterRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTTAdvances(Query);
	
	QueryText =
	"SELECT
	|	&Date AS Period,
	|	&Organization AS Organization,
	|	VALUE(Enum.VATRegisterRecordTypes.Outgoing) AS EntryType,
	|	&Vendor AS Counterparty,
	|	&DocumentPayments AS TaxInvoice,
	|	TableAdvances.VATRate AS VATRate,
	|	VALUE(Enum.AssetKinds.PrepaymentsFromCustomerTaxAgent) AS AssetTaxClass,
	|	TableAdvances.AmountExcludingVAT AS AmountExcludingVAT,
	|	TableAdvances.VAT AS VAT,
	|	TableAdvances.VATManag AS VATManag,
	|	FALSE AS PeriodEndTransaction,
	|	TableAdvances.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AccrueVATFromPrepaymentFromCustomer) AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|FROM
	|	TTAdvances AS TableAdvances
	|WHERE
	|	&VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer)
	|
	|UNION ALL
	|
	|SELECT
	|	&Date AS Period,
	|	&Organization AS Organization,
	|	VALUE(Enum.VATRegisterRecordTypes.Incoming) AS EntryType,
	|	&Vendor AS Counterparty,
	|	&DocumentPayments AS TaxInvoice,
	|	TableAdvances.VATRate AS VATRate,
	|	VALUE(Enum.AssetKinds.PrepaymentsToVendor) AS AssetTaxClass,
	|	TableAdvances.AmountExcludingVAT AS AmountExcludingVAT,
	|	TableAdvances.VAT AS VAT,
	|	TableAdvances.VATManag AS VATManag,
	|	FALSE AS PeriodEndTransaction,
	|	TableAdvances.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATDeductionFromPrepaymentToVendor) AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|FROM
	|	TTAdvances AS TableAdvances
	|";
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.ReceivedTaxInvoicePrepayment";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",           """""");
	RedefiningParameterCalculation.Insert("CorrectionInformation", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		TemporaryTableQueryTexts.Insert("TTDataBases", QueryTextTTDataBases(Query, QueryTexts));
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

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	ReceivedTaxInvoicePrepaymentLocalization.AddPrintCommands(PrintCommands);
	
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
	
	ReceivedTaxInvoicePrepaymentLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters)
	
EndProcedure

#EndRegion

#Region Other

Function RequestResultForAdvances(BeginOfPeriod, EndOfPeriod, Organization, ARAPDocument = Undefined, TempTablesManager, ExcludeJUDAS = False)
	
	If ValueIsFilled(Organization) Then
		BusinessPairs = Organization;
	Else
		AvailableCompanies = Catalogs.Companies.AvailableCompanies();
		CommonClientServer.DeleteAllValueOccurrencesFromArray(
			AvailableCompanies, 
			Catalogs.Companies.ManagementCompany);
		BusinessPairs = AvailableCompanies;
	EndIf;
	
	TempTablesManager = New TempTablesManager;
	
	CalculationParameters = VATAccountingERPInternal.InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes();
	
	CalculationParameters.StartDate                    = BeginOfPeriod;
	CalculationParameters.EndDate                 = EndOfDay(EndOfPeriod);
	CalculationParameters.Companies                   = BusinessPairs;
	CalculationParameters.ARAPDocument             = ARAPDocument;
	CalculationParameters.IncludeFinancialInstrumentData = True; 
	CalculationParameters.ExcludeJUDAS = ExcludeJUDAS;
	
	SetPrivilegedMode(True);
	VATAccountingERPInternal.PrepareVT_AdvancesIssued_Occurrences(TempTablesManager, CalculationParameters);
	SetPrivilegedMode(False);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	Prepayments.Organization             AS Organization,
	|	Prepayments.ARAPDocument       AS DocumentBasis,
	|	Prepayments.ARAPObject          AS ARAPObject,
	|	CASE
	|		WHEN Prepayments.TaxationType IN
	|					(VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer))
	|			THEN Prepayments.TaxationType
	|		ELSE
	|			VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END                          AS VATTaxation,
	|	Prepayments.DocumentCurrency         AS DocumentCurrency,
	|	SUM(Prepayments.AdvanceAmountVal)   AS CurrencyAmount,
	|	SUM(Prepayments.AdvanceAmount)      AS AmountOfSchedAdvance,
	|	Prepayments.Counterparty              AS Vendor,
	|	Prepayments.LineOfBusiness AS LineOfBusiness
	|INTO AdvancesForFormationOfSF
	|FROM
	|	AdvancesIssued_Occurrences AS Prepayments
	|	
	|GROUP BY
	|	Prepayments.Organization,
	|	Prepayments.ARAPDocument,
	|	CASE
	|		WHEN Prepayments.TaxationType IN
	|					(VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer))
	|			THEN Prepayments.TaxationType
	|		ELSE
	|			VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END,
	|	Prepayments.ARAPObject,
	|	Prepayments.Counterparty,
	|	Prepayments.LineOfBusiness,
	|	Prepayments.DocumentCurrency
	|
	|INDEX BY
	|	DocumentBasis
	|
	|;
	|
	|//////////////////////////////////////////////////////////
	|SELECT
	|	PrepaymentsToVendor.Organization                    AS Organization,
	|	PrepaymentsToVendor.DocumentBasis              AS DocumentBasis,
	|	VALUETYPE(PrepaymentsToVendor.DocumentBasis) AS TypeOfFoundationDocument,
	|	PrepaymentsToVendor.VATTaxation             AS VATTaxation,
	|	PrepaymentsToVendor.ARAPObject                 AS ARAPObject,
	|	PrepaymentsToVendor.DocumentCurrency                AS DocumentCurrency,
	|	SUM(PrepaymentsToVendor.CurrencyAmount)           AS CurrencyAmount,
	|	SUM(PrepaymentsToVendor.AmountOfSchedAdvance)         AS AmountOfSchedAdvance,
	|	PrepaymentsToVendor.Vendor                      AS Vendor,
	|	PrepaymentsToVendor.LineOfBusiness        AS LineOfBusiness,
	|	ARAPObjects.Object                        AS Object,
	|	
	|	MAX(ISNULL(SourceDocumentsData.Number, """")) AS Number,
	|	MAX(ISNULL(SourceDocumentsData.Date, DATETIME(1,1,1))) AS Date,
	|	
	|	CASE WHEN RegisterOfDocumentsStorno.Ref IS NULL
	|		THEN ISNULL(ReceivedTaxInvoicePrepayment.Number, """")
	|		ELSE """"
	|	END AS TaxInvoiceNumber,
	|	CASE WHEN RegisterOfDocumentsStorno.Ref IS NULL
	|		THEN ISNULL(ReceivedTaxInvoicePrepayment.DateCreated, DATETIME(1,1,1))
	|		ELSE DATETIME(1,1,1)
	|	END AS TaxInvoiceDate,
	|	CASE WHEN RegisterOfDocumentsStorno.Ref IS NULL
	|		THEN ISNULL(ReceivedTaxInvoicePrepayment.Sum, 0)
	|		ELSE 0
	|	END AS TaxInvoiceAmount,
	|	CASE WHEN RegisterOfDocumentsStorno.Ref IS NULL
	|		THEN ISNULL(ReceivedTaxInvoicePrepayment.Ref, VALUE(Document.ReceivedTaxInvoicePrepayment.EmptyRef))
	|		ELSE VALUE(Document.ReceivedTaxInvoicePrepayment.EmptyRef)
	|	END AS TaxInvoice,
	|	CASE WHEN RegisterOfDocumentsStorno.Ref IS NULL
	|		THEN ISNULL(ReceivedTaxInvoicePrepayment.Patch, FALSE)
	|		ELSE FALSE
	|	END AS Patch
	|
	|FROM
	|	AdvancesForFormationOfSF AS PrepaymentsToVendor
	|	
	|	LEFT JOIN 
	|		Document.ReceivedTaxInvoicePrepayment AS ReceivedTaxInvoicePrepayment
	|	ON 
	|		PrepaymentsToVendor.DocumentBasis = ReceivedTaxInvoicePrepayment.DocumentBasis
	|		AND (CASE
	|				WHEN VALUETYPE(PrepaymentsToVendor.DocumentBasis) = TYPE(Document.OBEntry)
	|					THEN PrepaymentsToVendor.Vendor = ReceivedTaxInvoicePrepayment.Counterparty
	|				ELSE TRUE
	|			END)
	|		AND ReceivedTaxInvoicePrepayment.Posted
	|	
	|	LEFT JOIN 
	|		Document.ReceivedTaxInvoicePrepayment AS InvoiceReceivedCorrection
	|	ON 
	|		ReceivedTaxInvoicePrepayment.DocumentBasis = InvoiceReceivedCorrection.DocumentBasis
	|		AND (CASE
	|				WHEN VALUETYPE(ReceivedTaxInvoicePrepayment.DocumentBasis) = TYPE(Document.OBEntry)
	|					THEN ReceivedTaxInvoicePrepayment.Counterparty = InvoiceReceivedCorrection.Counterparty
	|				ELSE TRUE
	|			END)
	|		AND ReceivedTaxInvoicePrepayment.Ref = InvoiceReceivedCorrection.BaseDocumentTaxInvoice
	|		AND InvoiceReceivedCorrection.Patch
	|		AND InvoiceReceivedCorrection.Posted
	|	
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStorno
	|	ON
	|		RegisterOfDocumentsStorno.RefType = &RefType
	|		AND RegisterOfDocumentsStorno.ReversedDocument = ReceivedTaxInvoicePrepayment.Ref
	|		AND RegisterOfDocumentsStorno.Posted
	|
	|	LEFT JOIN 
	|		InformationRegister.SourceDocumentsData AS SourceDocumentsData
	|	ON 
	|		PrepaymentsToVendor.DocumentBasis = SourceDocumentsData.Document
	|		AND PrepaymentsToVendor.Organization = SourceDocumentsData.Organization
	|
	|	LEFT JOIN 
	|		Catalog.ARAPObjects AS ARAPObjects
	|	ON 
	|		PrepaymentsToVendor.ARAPObject = ARAPObjects.Ref
	|
	|WHERE
	|	InvoiceReceivedCorrection.Ref IS NULL
	|	
	|GROUP BY
	|	PrepaymentsToVendor.Organization,
	|	PrepaymentsToVendor.DocumentBasis,
	|	PrepaymentsToVendor.VATTaxation,
	|	PrepaymentsToVendor.ARAPObject,
	|	PrepaymentsToVendor.DocumentCurrency,
	|	PrepaymentsToVendor.Vendor,
	|	PrepaymentsToVendor.LineOfBusiness,
	|	ARAPObjects.Object,
	|	
	|	CASE WHEN RegisterOfDocumentsStorno.Ref IS NULL
	|		THEN ISNULL(ReceivedTaxInvoicePrepayment.Number, """")
	|		ELSE """"
	|	END,
	|	CASE WHEN RegisterOfDocumentsStorno.Ref IS NULL
	|		THEN ISNULL(ReceivedTaxInvoicePrepayment.DateCreated, DATETIME(1,1,1))
	|		ELSE DATETIME(1,1,1)
	|	END,
	|	CASE WHEN RegisterOfDocumentsStorno.Ref IS NULL
	|		THEN ISNULL(ReceivedTaxInvoicePrepayment.Sum, 0)
	|		ELSE 0
	|	END,
	|	CASE WHEN RegisterOfDocumentsStorno.Ref IS NULL
	|		THEN ISNULL(ReceivedTaxInvoicePrepayment.Ref, VALUE(Document.ReceivedTaxInvoicePrepayment.EmptyRef))
	|		ELSE VALUE(Document.ReceivedTaxInvoicePrepayment.EmptyRef)
	|	END,
	|	CASE WHEN RegisterOfDocumentsStorno.Ref IS NULL
	|		THEN ISNULL(ReceivedTaxInvoicePrepayment.Patch, FALSE)
	|		ELSE FALSE
	|	END
	|";
	
	Query.SetParameter("RefType", Common.MetadataObjectID(EmptyRef().Metadata()));
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

Function DocumentDataTable_(TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	ArrayOfRequestTexts = New Array;
	
	QueryText = 
	"SELECT
	|	AdvancesForFormationOfSF.DocumentBasis AS DocumentBasis,
	|	AdvancesForFormationOfSF.ARAPObject    AS ARAPObject,
	|	Details.VATRate      AS VATRate,
	|	Details.Sum          AS Sum
	|FROM
	|	Document.BankAccountIssue.ARAPDetails AS Details
	|	INNER JOIN
	|		AdvancesForFormationOfSF AS AdvancesForFormationOfSF
	|	ON
	|		Details.Ref = AdvancesForFormationOfSF.DocumentBasis
	|		AND Details.ARAPObject = AdvancesForFormationOfSF.ARAPObject
	|
	|UNION ALL
	|
	|SELECT
	|	AdvancesForFormationOfSF.DocumentBasis AS DocumentBasis,
	|	AdvancesForFormationOfSF.ARAPObject    AS ARAPObject,
	|	Details.VATRate       AS VATRate,
	|	Details.Sum           AS Sum
	|FROM
	|	Document.CashVoucher.ARAPDetails AS Details
	|	INNER JOIN
	|		AdvancesForFormationOfSF AS AdvancesForFormationOfSF
	|	ON
	|		Details.Ref = AdvancesForFormationOfSF.DocumentBasis
	|		AND Details.ARAPObject = AdvancesForFormationOfSF.ARAPObject
	|
	|UNION ALL
	|
	|SELECT
	|	AdvancesForFormationOfSF.DocumentBasis AS DocumentBasis,
	|	AdvancesForFormationOfSF.ARAPObject    AS ARAPObject,
	|	Details.VATRate      AS VATRate,
	|	Details.Sum          AS Sum
	|FROM
	|	Document.BankAccountIssue.ARAPDetails AS Details
	|	INNER JOIN
	|		AdvancesForFormationOfSF AS AdvancesForFormationOfSF
	|	ON
	|		Details.Ref = AdvancesForFormationOfSF.DocumentBasis
	|		AND Details.LeaseContracts = AdvancesForFormationOfSF.ARAPObject
	|
	|UNION ALL
	|
	|SELECT
	|	AdvancesForFormationOfSF.DocumentBasis AS DocumentBasis,
	|	AdvancesForFormationOfSF.ARAPObject    AS ARAPObject,
	|	Details.VATRate       AS VATRate,
	|	Details.Sum           AS Sum
	|FROM
	|	Document.CashVoucher.ARAPDetails AS Details
	|	INNER JOIN
	|		AdvancesForFormationOfSF AS AdvancesForFormationOfSF
	|	ON
	|		Details.Ref = AdvancesForFormationOfSF.DocumentBasis
	|		AND Details.LeaseContracts = AdvancesForFormationOfSF.ARAPObject
	|
	|";
	ArrayOfRequestTexts.Add(QueryText);
	
	ReceivedTaxInvoicePrepaymentLocalization.AddRequestTextsForTheseDocuments(ArrayOfRequestTexts, Query);
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTemplate = 
	"SELECT
	|	Table.DocumentBasis  AS DocumentBasis,
	|	Table.ARAPObject     AS ARAPObject,
	|	Table.VATRate          AS VATRate,
	|	SUM(Table.Sum)       AS Sum
	|FROM
	|	&NestedQuery AS Table
	|
	|GROUP BY
	|	Table.DocumentBasis,
	|	Table.ARAPObject,
	|	Table.VATRate
	|";
	Query.Text = StrReplace(QueryTemplate, "&NestedQuery", "(" + QueryText +")");
	
	SetPrivilegedMode(True);
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#Region CreatingHyperlinkInVATDocumentLog

Function CreateHyperlinkToDesign(Parameters) Export
	
	If Not AccessRight("Update", Metadata.Documents.ReceivedTaxInvoicePrepayment) Then
		Return Undefined;
	EndIf;
	
	Parameters.Insert("CompanyArray",?(ValueIsFilled(Parameters.Organization), 
											TMCommonUseClientServer.Array(Parameters.Organization),
											Undefined));
	
	If Parameters.Property("BriefPresentation") Then
		HyperlinkText = NStr("vi = 'Hóa đơn GTGT đã nhận (ứng trước)';
							|ru = 'Счета-фактуры полученные (аванс)';
							|en = 'Received tax invoices (advance)'; fa = 'صورت‌حساب‌های مالیاتی دریافت‌شده (پیش‌پرداخت)';
							|it = 'Fatture ricevute (pagamento anticipo)';
							|pl = 'Rejestr przygotowanych zamówień (zaliczka)';
							|tr = 'Alınan vergi faturaları (avans)'");
	Else
		HyperlinkText = NStr("vi = 'Hóa đơn GTGT đã nhận (ứng trước)';
							|ru = 'Счета-фактуры полученные (аванс)';
							|en = 'Received tax invoices (advance)'; fa = 'صورت‌حساب‌های مالیاتی دریافت‌شده (پیش‌پرداخت)';
							|it = 'Fatture ricevute (pagamento anticipo)';
							|pl = 'Rejestr przygotowanych zamówień (zaliczka)';
							|tr = 'Alınan vergi faturaları (avans)'");
	EndIf;	
	
	DocumentsCount = ThereAreInvoicesForRegistration(Parameters);
	
	If DocumentsCount = 0 Then
		Return New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,,
			FormNameInvoiceAdvanceReceived());
	Else
		Return New FormattedString(HyperlinkText,,,,
			FormNameInvoiceAdvanceReceived());
	EndIf;
	
EndFunction

Function FormNameInvoiceAdvanceReceived() Export
	
	Return "Document.ReceivedTaxInvoicePrepayment.Form.WorkplaceForm";
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Documents.ReceivedTaxInvoicePrepayment.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.25.31";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("5b454481-1c01-4876-b2e8-a9786e862b1d");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.ReceivedTaxInvoicePrepayment.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật chứng từ ""Hóa đơn GTGT đầu vào (ứng trước)"":';
								|ru = 'Обновление документов ""Счет-фактура полученный (аванс)"":';
								|en = 'Update the ""Received tax invoice (advance)"" documents:'; fa = 'Update the ""Received tax invoice (advance)"" documents:';
								|it = 'Update the ""Received tax invoice (advance)"" documents:';
								|pl = 'Update the ""Received tax invoice (advance)"" documents:';
								|tr = '""Alınan vergi faturası (avans)"" belgesinin güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- điền mục tin ""Ngày phản ánh vào kế toán"" từ ngày nhận, nếu trước đó chưa được điền';
								|ru = '- заполнение реквизита ""Дата отражения в учете"" из даты получения, если не был заполнен ранее';
								|en = '- Fill in the ""Posting date"" attribute from the receipt date if it was not filled in earlier'; fa = '- Fill in the ""Posting date"" attribute from the receipt date if it was not filled in earlier';
								|it = '- Fill in the ""Posting date"" attribute from the receipt date if it was not filled in earlier';
								|pl = '- Fill in the ""Posting date"" attribute from the receipt date if it was not filled in earlier';
								|tr = '- Daha önce doldurulmamışsa, ""Muhasebeye yansıtma tarihi"" alanının alındığı tarihten itibaren doldurulması'"));

	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.ReceivedTaxInvoicePrepayment.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.ReceivedTaxInvoicePrepayment.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	ReceivedTaxInvoicePrepayment.Ref
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS ReceivedTaxInvoicePrepayment
	|WHERE
	|	ReceivedTaxInvoicePrepayment.RecordingInAccountingDate = DATETIME(1, 1, 1)
	|";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
		
	EndIf;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật chứng từ ""Hóa đơn GTGT đầu vào (ứng trước)"":';
								|ru = 'Обновление документов ""Счет-фактура полученный (аванс)"":';
								|en = 'Update the ""Received tax invoice (advance)"" documents:'; fa = 'Update the ""Received tax invoice (advance)"" documents:';
								|it = 'Update the ""Received tax invoice (advance)"" documents:';
								|pl = 'Update the ""Received tax invoice (advance)"" documents:';
								|tr = '""Alınan vergi faturası (avans)"" belgesinin güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- điền mục tin ""Ngày phản ánh vào kế toán"" từ ngày nhận, nếu trước đó chưa được điền';
								|ru = '- заполнение реквизита ""Дата отражения в учете"" из даты получения, если не был заполнен ранее';
								|en = '- Fill in the ""Posting date"" attribute from the receipt date if it was not filled in earlier'; fa = '- Fill in the ""Posting date"" attribute from the receipt date if it was not filled in earlier';
								|it = '- Fill in the ""Posting date"" attribute from the receipt date if it was not filled in earlier';
								|pl = '- Fill in the ""Posting date"" attribute from the receipt date if it was not filled in earlier';
								|tr = '- Daha önce doldurulmamışsa, ""Muhasebeye yansıtma tarihi"" alanının alındığı tarihten itibaren doldurulması'"));
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	DataForUpdate.Ref AS Ref
		|INTO DocumentsTable
		|FROM
		|	&DataForUpdate AS DataForUpdate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentsTable.Ref AS Ref,
		|	DocumentData.DataVersion AS DataVersion,
		|	DocumentData.Date AS Date
		|FROM
		|	DocumentsTable AS DocumentsTable
		|		LEFT JOIN Document.ReceivedTaxInvoicePrepayment AS DocumentData
		|		ON DocumentsTable.Ref = DocumentData.Ref
		|
		|GROUP BY
		|	DocumentsTable.Ref,
		|	DocumentData.DataVersion,
		|	DocumentData.Date";
	
	Query.SetParameter("DataForUpdate", UpdatedData);
	
	SelectionOfDocuments = Query.Execute().Select();
	
	While SelectionOfDocuments.Next() Do
		
		ExceptionReason = 0;
		Recommendation = "";
		
		BeginTransaction();
		
		Try 
			
			ExceptionReason = 1; // IObjectLock
		
			Block = New DataLock;
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", SelectionOfDocuments.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			DocumentObject = InfobaseUpdateTM.CheckGetObject(
					SelectionOfDocuments.Ref, SelectionOfDocuments.DataVersion, Parameters.Queue);
					
			ExceptionReason = 2; // BadData
			Recommendation = NStr("vi = 'Hãy kết chuyển lại chứng từ một cách thủ công.';
									|ru = 'Перепроведите документ вручную.';
									|en = 'Repost the document manually.'; fa = 'Repost the document manually.';
									|it = 'Перепроведите документ вручную.';
									|pl = 'Repost the document manually.';
									|tr = 'Belgeyi manuel olarak yeniden kaydedin.'");
			
			If DocumentObject <> Undefined Then
								
				If Not ValueIsFilled(DocumentObject.RecordingInAccountingDate) Then
					DocumentObject.RecordingInAccountingDate = SelectionOfDocuments.Date;
				EndIf;
				
			EndIf;
			
			ExceptionReason = 3; // Record
				
			If DocumentObject.Modified() Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(SelectionOfDocuments.Ref);
			EndIf;
				
			ObjectsProcessed = ObjectsProcessed + 1;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), SelectionOfDocuments.Ref);
			
			If ExceptionReason = 2 Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					SelectionOfDocuments.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = 3 Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted =
		InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		
		ListOfDescriptions.Add(NStr("vi = 'Tổng số bỏ qua: %1';
									|ru = 'Всего пропущено: %1';
									|en = 'Total skipped: %1'; fa = 'Total skipped: %1';
									|it = 'Всего пропущено: %1';
									|pl = 'Total skipped: %1';
									|tr = 'Toplam atlanan: %1'"));
		MessageText = StrTemplate(StrConcat(ListOfDescriptions, Chars.LF), ObjectsWithIssuesCount);
		Raise MessageText;
		
	Else
		
		MessageTemplate = NStr("vi = 'Đã xử lý nhóm chứng từ ""Hóa đơn GTGT đầu vào (ứng trước)"": %1';
								|ru = 'Обработана порция документов ""Счет-фактура полученный (аванс)"": %1';
								|en = 'A batch of the ""Received tax invoice (advance)"" documents is processed: %1'; fa = 'A batch of the ""Received tax invoice (advance)"" documents is processed: %1';
								|it = 'A batch of the ""Received tax invoice (advance)"" documents is processed: %1';
								|pl = 'A batch of the ""Received tax invoice (advance)"" documents is processed: %1';
								|tr = '""Alınan vergi faturası (avans)"" belge grubu işlendi: %1'");
		MessageText = StrTemplate(MessageTemplate, ObjectsProcessed);
		WriteLogEvent(
			InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Information, , ,
			MessageText);
		
	EndIf;
	
	InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

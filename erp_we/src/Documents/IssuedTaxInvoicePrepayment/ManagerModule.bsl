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
	
	IssuedTaxInvoicePrepaymentLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.IssuedTaxInvoicePrepayment") Then
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
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableVATPrepaymentsFromCustomer(Query, QueryTexts, Registers);
		QueryTextTableVATRegisterRecords(Query, QueryTexts, Registers);

		IssuedTaxInvoicePrepaymentLocalization.AddRequestTexts(Query, QueryTexts, Registers);
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
	
	Documents.VATWritingOffAsExpenses.AddGenerateCommand(GenerationCommands);
	
	Documents.IssuedTaxInvoicePrepayment.AddCreateCommandBasedOnCorrectiveInvoice(GenerationCommands);
	
	IssuedTaxInvoicePrepaymentLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
EndProcedure

// Adds a command creation of the document "the invoice issued (advance)".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddCreateCommandBasedOnCorrectiveInvoice(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.IssuedTaxInvoicePrepayment) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "VATAccountingERPClient.CorrectiveInvoiceIssuedAdvance";
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

// Adds a command creation of the document "the invoice issued (advance)".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.IssuedTaxInvoicePrepayment) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.IssuedTaxInvoicePrepayment.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.IssuedTaxInvoicePrepayment);
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
	
	IssuedTaxInvoicePrepaymentLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

// Returns the incoming number and date of the billing document.
//
// Parameters:
// 	DocumentRef	- DocumentRef - The document whose incoming number and date you want to get
// 	Counterparty		- CatalogRef.Counterparties, Undefined - Counterparty of the table part "calculations by Partners" of the document "input of data".
//
// Returns:
// 	Structure  - Contains:
// 				    * SettlementDocumentNumber - String - document number
// 					* DateOfDocumentInARAPAccounting - Date - document date.
//
Function IncomingDocumentNumberAndDate(DocumentRef, Counterparty = Undefined) Export
	
	ResultStructure1 = New Structure;
	ResultStructure1.Insert("SettlementDocumentNumber", "");
	ResultStructure1.Insert("DateOfDocumentInARAPAccounting" , '00010101');
	
	If TypeOf(DocumentRef) = Type("DocumentRef.BankAccountReceiptNote")
		Or TypeOf(DocumentRef) = Type("DocumentRef.BankAccountIssue") Then
		
		DocumentRefAttributes = Common.ObjectAttributesValues(DocumentRef, "IncomingDocumentNumber, IncomingDocumentDate");
		ResultStructure1.Insert("SettlementDocumentNumber", DocumentRefAttributes.IncomingDocumentNumber);
		ResultStructure1.Insert("DateOfDocumentInARAPAccounting" , DocumentRefAttributes.IncomingDocumentDate);
		
	ElsIf TypeOf(DocumentRef) = Type("DocumentRef.OBEntry") 
		Or TypeOf(DocumentRef) = Type("DocumentRef.OBEntryARAP") Then
		// To enter the balances, the data is stored in the tabular part
		If ValueIsFilled(Counterparty) And TypeOf(Counterparty)  = Type("CatalogRef.Counterparties") Then
			PartnersARAPAccounting = Common.ObjectAttributeValue(DocumentRef, "PartnersARAPAccounting");
			AdvanceLine_ = PartnersARAPAccounting.Unload().Find(Counterparty, "Counterparty");
			If AdvanceLine_ <> Undefined Then
				ResultStructure1.Insert("SettlementDocumentNumber", AdvanceLine_.NumberOfARAPDocument);
				ResultStructure1.Insert("DateOfDocumentInARAPAccounting" , AdvanceLine_.APARDocumentDate);
			EndIf; 
		EndIf; 
		
	Else
		
		DocumentRefAttributes = Common.ObjectAttributesValues(DocumentRef, "Number, Date");
		ResultStructure1.Insert("SettlementDocumentNumber", ObjectsPrefixesClientServer.NumberForPrinting(DocumentRefAttributes.Number, False, True));
		ResultStructure1.Insert("DateOfDocumentInARAPAccounting" , DocumentRefAttributes.Date);
		
	EndIf;
	
	Return ResultStructure1;

EndFunction

// Generates tasks for offline calculation.
//
// Parameters:
//	ChangesTable - ValueTable - Table of changes affecting VAT accounting. Contains columns:
//		* Period - Date - Date of changes
//		* Document - DocumentRef - Document for which data is being changed
//		* Counterparty - CatalogRef.Counterparties - Counterparty for which data is being changed
//
Procedure CreateTasksForGeneratingVATRegisteredRecords(ChangesTable) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("ChangesTable", ChangesTable);
	Query.Text =
	"SELECT DISTINCT
	|	ChangesTable.Period AS Month,
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
	|	Calculations.Month                 AS Month
	|FROM
	|	Document.IssuedTaxInvoicePrepayment AS TaxInvoice
	|
	|	INNER JOIN
	|		TTCalculations AS Calculations
	|	ON
	|		TaxInvoice.DocumentBasis = Calculations.ARAPDocument
	|WHERE
	|	TaxInvoice.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TaxInvoice.DocumentBasis            AS TaxInvoice,
	|	TaxInvoice.Organization                  AS Organization,
	|	GiftCertificateCancellation.Date AS Month
	|FROM
	|	Document.GiftCertificateCancellation AS GiftCertificateCancellation
	|	
	|	INNER JOIN
	|		TTCalculations AS Calculations
	|	ON
	|		GiftCertificateCancellation.Ref = Calculations.ARAPDocument
	|	
	|	INNER JOIN
	|		Document.GiftCertificateCancellation.GiftCertificates AS DocumentData
	|	ON
	|		GiftCertificateCancellation.Ref = DocumentData.Ref
	|	
	|	INNER JOIN
	|		AccumulationRegister.GiftCertificates AS CertificateImplementation
	|	ON
	|		CertificateImplementation.GiftCertificate = DocumentData.GiftCertificate
	|		AND CertificateImplementation.RecordType = VALUE(AccumulationRecordType.Receipt)
	|
	|	INNER JOIN
	|		Document.IssuedTaxInvoicePrepayment AS TaxInvoice
	|	ON
	|		CertificateImplementation.Recorder = TaxInvoice.DocumentBasis
	|		AND TaxInvoice.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TaxInvoice.DocumentBasis      AS TaxInvoice,
	|	TaxInvoice.Organization            AS Organization,
	|	ReturnOfGiftCards.Date AS Month
	|FROM
	|	Document.ReturnOfGiftCards AS ReturnOfGiftCards
	|	
	|	INNER JOIN
	|		Document.ReturnOfGiftCards.GiftCertificates AS DocumentData
	|	ON
	|		ReturnOfGiftCards.Ref = DocumentData.Ref
	|	
	|	INNER JOIN
	|		TTCalculations AS Calculations
	|	ON
	|		DocumentData.Ref = Calculations.ARAPDocument
	|	
	|	INNER JOIN
	|		AccumulationRegister.GiftCertificates AS CertificateImplementation
	|	ON
	|		CertificateImplementation.GiftCertificate = DocumentData.GiftCertificate
	|		AND CertificateImplementation.RecordType = VALUE(AccumulationRecordType.Receipt)
	|
	|	INNER JOIN
	|		Document.IssuedTaxInvoicePrepayment AS TaxInvoice
	|	ON
	|		CertificateImplementation.Recorder = TaxInvoice.DocumentBasis
	|		AND TaxInvoice.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TaxInvoice.DocumentBasis AS TaxInvoice,
	|	TaxInvoice.Organization       AS Organization,
	|	RetailSalesReport.Date  AS Month
	|FROM
	|	Document.RetailSalesReport AS RetailSalesReport
	|	
	|	INNER JOIN
	|		Document.RetailSalesReport.GiftCertificates AS DocumentData
	|	ON
	|		RetailSalesReport.Ref = DocumentData.Ref
	|	
	|	INNER JOIN
	|		TTCalculations AS Calculations
	|	ON
	|		DocumentData.Ref = Calculations.ARAPDocument
	|	
	|	INNER JOIN
	|		AccumulationRegister.GiftCertificates AS CertificateImplementation
	|	ON
	|		CertificateImplementation.GiftCertificate = DocumentData.GiftCertificate
	|		AND CertificateImplementation.RecordType = VALUE(AccumulationRecordType.Receipt)
	|
	|	INNER JOIN
	|		Document.IssuedTaxInvoicePrepayment AS TaxInvoice
	|	ON
	|		CertificateImplementation.Recorder = TaxInvoice.DocumentBasis
	|		AND TaxInvoice.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentsRegistry.Ref,
	|	TaxInvoice.Organization,
	|	Calculations.Month
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		INNER JOIN TTCalculations AS Calculations
	|		ON DocumentsRegistry.Ref = Calculations.ARAPDocument
	|		INNER JOIN Document.IssuedTaxInvoicePrepayment AS TaxInvoice
	|		ON DocumentsRegistry.ReversedDocument = TaxInvoice.DocumentBasis
	|WHERE
	|	TaxInvoice.Posted
	|";
	
	Selection = Query.Execute().Select();
	InformationRegisters.JobsForGeneratingVATRecords.CreateRegisterEntriesBasedOnSampleData(Selection);
	
EndProcedure

// Returns the structure of parameters for selecting data for received advances
//
// Returns:
//	Structure - selection parameters.
//
Function SelectionOfAdvancesReceived() Export
	
	FilterStructure1 = New Structure();
	FilterStructure1.Insert("BeginOfPeriod");
	FilterStructure1.Insert("EndOfPeriod");
	FilterStructure1.Insert("RuleOfPrepaymentFilter");
	FilterStructure1.Insert("DefaultVATRate");
	FilterStructure1.Insert("Organization");
	FilterStructure1.Insert("ARAPDocument");
	
	Return FilterStructure1;
	
EndFunction

// Fills in the received Advances table with data for generating advance invoices.
//
// Parameters:
//	SelectionOfAdvances - Structure - Parameters for selecting received advances
//	PrepaymentsFromCustomerLayout - See TableAdvancesReceived_
//	SettlementDocumentsWithoutInvoice - Array - Filled in with a list of documents for which invoices were not generated.
//
Procedure FillInReceivedAdvancesForSF(SelectionOfAdvances, PrepaymentsFromCustomerLayout, SettlementDocumentsWithoutInvoice = Undefined) Export
	
	BeginOfPeriod        = BegOfDay(SelectionOfAdvances.BeginOfPeriod);
	EndOfPeriod         = EndOfDay(SelectionOfAdvances.EndOfPeriod);
	ARAPDocument    = SelectionOfAdvances.ARAPDocument;
	Organization          = SelectionOfAdvances.Organization;
	DefaultVATTaxation = Enums.VATTaxationTypes.SaleIsSubjectToVAT;
	
	If TypeOf(Organization) = Type("Array") And Organization.Count() = 1 Then
		MainVATRate = VATAccountingERP.DefaultVATRate(Organization[0], SelectionOfAdvances.BeginOfPeriod);
		DefaultVATTaxation = VATAccountingERP.AccountingParametersForOrganization(Organization[0], EndOfPeriod).BasicTaxationVATSales;
	ElsIf TypeOf(Organization) = Type("CatalogRef.Companies") Then
		MainVATRate = VATAccountingERP.DefaultVATRate(Organization, SelectionOfAdvances.BeginOfPeriod);
		DefaultVATTaxation = VATAccountingERP.AccountingParametersForOrganization(Organization, EndOfPeriod).BasicTaxationVATSales;
	Else
		MainVATRate = VATAccountingERP.DefaultVATRate(Undefined, SelectionOfAdvances.BeginOfPeriod);
	EndIf;
	IssuedTaxInvoicePrepaymentLocalization.SetAdvanceVATRate(MainVATRate);
	
	DefaultVATRate = ?(
		ValueIsFilled(SelectionOfAdvances.DefaultVATRate),
		SelectionOfAdvances.DefaultVATRate,
		MainVATRate);
		
	DefaultVATTaxation = ?(
		ValueIsFilled(DefaultVATTaxation),
		DefaultVATTaxation,
		Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		
	RuleOfPrepaymentFilter = Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllExceptSettledDuringDay;
	If ValueIsFilled(SelectionOfAdvances.RuleOfPrepaymentFilter) Then
		RuleOfPrepaymentFilter = SelectionOfAdvances.RuleOfPrepaymentFilter;
	ElsIf TypeOf(Organization) = Type("Array") And Organization.Count() = 1 Then
		VATAccountingSettings = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("VATAccountingSettings",
			Organization[0],
			SelectionOfAdvances.EndOfPeriod,
			True);
		If VATAccountingSettings <> Undefined Then
			RuleOfPrepaymentFilter = VATAccountingSettings.RuleOfPrepaymentFilterToRegisterTaxInvoices;
		EndIf;
	ElsIf TypeOf(Organization) = Type("CatalogRef.Companies") Then
		VATAccountingSettings = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("VATAccountingSettings",
			Organization,
			SelectionOfAdvances.EndOfPeriod,
			True);
		If VATAccountingSettings <> Undefined Then
			RuleOfPrepaymentFilter = VATAccountingSettings.RuleOfPrepaymentFilterToRegisterTaxInvoices;
		EndIf;
	EndIf;
	
	PossibleTypeOfFoundationDocument = Metadata.Documents.IssuedTaxInvoicePrepayment.Attributes.DocumentBasis.Type;
	
	// We will prepare a table of advances for the document, taking into account the rules for selecting advances.
	Prepayments = New ValueTable;
	Prepayments.Columns.Add("Organization",         New TypeDescription("CatalogRef.Companies"));
	Prepayments.Columns.Add("Counterparty",          New TypeDescription("CatalogRef.Counterparties, CatalogRef.Companies"));
	Prepayments.Columns.Add("VATTaxation",  New TypeDescription("EnumRef.VATTaxationTypes"));
	Prepayments.Columns.Add("DocumentBasis",   Metadata.DefinedTypes.BaseDocumentIssuedTaxInvoicePrepayment.Type);
	Prepayments.Columns.Add("DocumentCurrency",     New TypeDescription("CatalogRef.Currencies"));
	Prepayments.Columns.Add("VATRate",           New TypeDescription("CatalogRef.VATRates"));
	Prepayments.Columns.Add("LineOfBusiness", New TypeDescription("CatalogRef.LinesOfBusiness"));
	Prepayments.Columns.Add("EmployeeResponsible",       New TypeDescription("CatalogRef.Users"));
	Prepayments.Columns.Add("Department",       New TypeDescription("CatalogRef.BusinessStructure"));
	Prepayments.Columns.Add("Director",        New TypeDescription("CatalogRef.PersonsResponsibleAndCompanies"));
	Prepayments.Columns.Add("ChiefAccountant",    New TypeDescription("CatalogRef.PersonsResponsibleAndCompanies"));
	Prepayments.Columns.Add("ARAPObject",      New TypeDescription("CatalogRef.ARAPObjects"));
	Prepayments.Columns.Add("RuleOfPrepaymentFilter", New TypeDescription("EnumRef.ProcedureOfRegisteringTaxInvoicesForPrepayment"));
	Prepayments.Columns.Add("Sum",             TMCommonUse.MoneyFieldTypeDescription());
	Prepayments.Columns.Add("VATAmount",          TMCommonUse.MoneyFieldTypeDescription());
	Prepayments.Columns.Add("CurrencyAmount",     TMCommonUse.MoneyFieldTypeDescription());
	
	GroupFields = "Counterparty, DocumentBasis, VATTaxation, Organization, LineOfBusiness, DocumentCurrency,
						|VATRate, EmployeeResponsible, Department, Director, ChiefAccountant, ARAPObject, RuleOfPrepaymentFilter";
	SummationFields = "Sum, VATAmount, CurrencyAmount";
	
	// For new invoices, the values of the Responsible, Department, Manager and Main Accountant fields do
	// not depend on the invoice. Let's calculate them in advance, outside the loop.	
	EmployeeResponsible = Users.CurrentUser();
	Department = SettingsValueCached.UserDivision(EmployeeResponsible);
	ResponsiblePersons = ResponsiblePersonsServer.GetResponsiblePersonsOfOrganization(Organization, EndOfPeriod);
	
	TempTablesManager = New TempTablesManager();
	
	Result = RequestResultForAdvances(
					BeginOfPeriod,
					EndOfPeriod,
					Organization,
					ARAPDocument,
					RuleOfPrepaymentFilter,
					TempTablesManager);
	SampleAdvancePayment = Result.Select();
	
	InvoiceTable_1 = TableOfRegisteredInvoices(TempTablesManager); // ValueTable - 
	InvoiceTable_1.Indexes.Add("TaxInvoice, Counterparty");
	
	DocumentDataTable_ = DocumentDataTable_(TempTablesManager); // ValueTable - 
	DocumentDataTable_.Indexes.Add("DocumentBasis, ARAPObject");
	
	While SampleAdvancePayment.Next() Do
		
		ImplementationOnWayAccordingToSettlementDocuments = IssuedTaxInvoicePrepaymentLocalization.ThisIsImplementationInWayOfSettlementDocuments(SampleAdvancePayment);
		
		If SampleAdvancePayment.DocumentBasis = NULL
			Or SampleAdvancePayment.Sum = 0
			Or ImplementationOnWayAccordingToSettlementDocuments
			Or TypeOf(SampleAdvancePayment.Object) = Type("CatalogRef.Complaints")
			Or SampleAdvancePayment.ConsignmentSales25 Then
			Continue;
		EndIf;
		
		Prepayments.Clear();
		
		DateOfAdvancePayment         = SampleAdvancePayment.DateOfSFFormation;
		SubjectToVATAtCustomer = SampleAdvancePayment.VATTaxation =
									Enums.VATTaxationTypes.SubjectToVATAtCustomer;
		SpaceActivities  = SampleAdvancePayment.VATTaxation =
									Enums.VATTaxationTypes.SpaceActivity;
		
		FilterStructure1 = New Structure("DocumentBasis, ARAPObject");
		FillPropertyValues(FilterStructure1, SampleAdvancePayment);
		
		ArrayOfBids = New Array;
		ArrayOfCoefficients = New Array;
		
		DocumentData = DocumentDataTable_.FindRows(FilterStructure1);
		For Each String In DocumentData Do
			If SubjectToVATAtCustomer Then
				CurRate_ = MainVATRate;
			ElsIf ValueIsFilled(String.VATRate) Then
				CurRate_ = String.VATRate;
			ElsIf ValueIsFilled(SampleAdvancePayment.VATRateUnderAgreement) Then
				CurRate_ = SampleAdvancePayment.VATRateUnderAgreement;
			Else
				CurRate_ = DefaultVATRate;
			EndIf;
			ArrayOfBids.Add(CurRate_);
			ArrayOfCoefficients.Add(String.Sum);
		EndDo;
		
		If ArrayOfBids.Count() = 0 Then
			If SubjectToVATAtCustomer Then
				CurRate_ = MainVATRate;
			ElsIf ValueIsFilled(SampleAdvancePayment.VATRateUnderAgreement) Then
				CurRate_ = SampleAdvancePayment.VATRateUnderAgreement;
			Else
				CurRate_ = DefaultVATRate;
			EndIf;
			ArrayOfBids.Add(CurRate_);
			ArrayOfCoefficients.Add(1);
		EndIf;
		
		CurrencyAmountAtRates = Common.DistributeAmountInProportionToCoefficients(
			SampleAdvancePayment.CurrencyAmount,
			ArrayOfCoefficients);
		
		BidAmount = Common.DistributeAmountInProportionToCoefficients(
			SampleAdvancePayment.Sum,
			ArrayOfCoefficients);
		
		IndexOf = 0;
		For Each Rate1 In ArrayOfBids Do
			
			Sum = BidAmount[IndexOf];
			CurrencyAmount = CurrencyAmountAtRates[IndexOf];
			IndexOf = IndexOf + 1;
			
			If VATAccountingERP.InsignificantRate(Rate1)
				And Not SpaceActivities Then
					Continue;
			EndIf;
			If Sum = 0 Then
				Continue;
			EndIf;
			
			AdvanceVATRate = Rate1;
			IssuedTaxInvoicePrepaymentLocalization.SetAdvanceVATRate(AdvanceVATRate);
			
			VATAmount = VATAccountingERPClientServer.CalculateVATAmount(
											Sum,
											AdvanceVATRate,
											,
											SampleAdvancePayment.VATTaxation);
			If VATAmount = 0
				And Not SpaceActivities
				And Not SubjectToVATAtCustomer Then
					Continue;
			EndIf;
			
			NewRow = Prepayments.Add();
			FillPropertyValues(NewRow, SampleAdvancePayment);
			
			NewRow.VATRate = AdvanceVATRate;
			NewRow.Sum = Sum;
			NewRow.CurrencyAmount = CurrencyAmount;
			NewRow.VATAmount  = VATAmount;
			
			NewRow.EmployeeResponsible = EmployeeResponsible;
			NewRow.Department = Department;
			NewRow.Director = ResponsiblePersons.DirectorRef;
			NewRow.ChiefAccountant = ResponsiblePersons.ChiefAccountantRef; 
			
			If Not ValueIsFilled(NewRow.VATTaxation) Then 
				NewRow.VATTaxation = DefaultVATTaxation;
			EndIf;
			
		EndDo;
		
		If Prepayments.Count() > 1 Then
			Prepayments.GroupBy(GroupFields, SummationFields);
		EndIf;
		
		For Each LineAdvances In Prepayments Do
			
			If PossibleTypeOfFoundationDocument.ContainsType(TypeOf(LineAdvances.DocumentBasis))
				And ValueIsFilled(LineAdvances.DocumentBasis) Then
				
				InvoiceSelection_1 = New Structure();
				InvoiceSelection_1.Insert("DocumentBasis",  LineAdvances.DocumentBasis);
				InvoiceSelection_1.Insert("VATTaxation", LineAdvances.VATTaxation);
				
				SearchResult = InvoiceTable_1.FindRows(InvoiceSelection_1);
				If SearchResult.Count() > 0 And SearchResult[0].Overrepresented Then
					Continue;
				EndIf;
				
				NewRow = PrepaymentsFromCustomerLayout.Add();
				FillPropertyValues(NewRow, LineAdvances);
				
				If SearchResult.Count() = 0 Then
					NewRow.Sfsformed = False;
				Else
					InvoiceAttributes = SearchResult[0];
					NewRow.Sfsformed = True;
					FillPropertyValues(NewRow, InvoiceAttributes,,"ARAPObject,Sum,VATAmount");  
					
					If PrepaymentsFromCustomerLayout.Columns.Find("PaymentAndSettlementDocumentDataIsMissing") <> Undefined Then
						If InvoiceAttributes.SettlementDocumentNumber = ""
							And InvoiceAttributes.DateOfDocumentInARAPAccounting = '00010101' Then
							NewRow.PaymentAndSettlementDocumentDataIsMissing = True;
						EndIf;
					EndIf;
				EndIf; 
				
				If PrepaymentsFromCustomerLayout.Columns.Find("BaseIsStorno") <> Undefined
					And TypeOf(LineAdvances.DocumentBasis) = Type("DocumentRef.ReversingEntry") Then
					NewRow.BaseIsStorno = True;
				EndIf;
				
				If NewRow.DateOfDischarge = '00010101' Then
					NewRow.DateOfDischarge = DateOfAdvancePayment;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	GroupingFieldsTotals = New Array;
	GroupingFieldsTotals.Add("Counterparty, DocumentBasis, ARAPObject, VATTaxation, LineOfBusiness, DocumentCurrency,
		|VATRate, EmployeeResponsible, Department, Director, ChiefAccountant, DateOfDischarge, Sfsformed, Patch, TaxInvoiceAmount,
		|TaxInvoice, RuleOfPrepaymentFilter");
	If Not PrepaymentsFromCustomerLayout.Columns.Find("Organization") = Undefined Then
		GroupingFieldsTotals.Add("Organization");
	EndIf;
	If PrepaymentsFromCustomerLayout.Columns.Find("PaymentAndSettlementDocumentDataIsMissing") <> Undefined Then
		GroupingFieldsTotals.Add("PaymentAndSettlementDocumentDataIsMissing");
	EndIf;
	If PrepaymentsFromCustomerLayout.Columns.Find("BaseIsStorno") <> Undefined Then
		GroupingFieldsTotals.Add("BaseIsStorno");
	EndIf;
	
	PrepaymentsFromCustomerLayout.GroupBy(StrConcat(GroupingFieldsTotals,","), SummationFields);
	
EndProcedure

// Returns the range of customer orders paid for by the invoice base
//
// Parameters:
// 	 PaymentDocument - DocumentRef.BankAccountReceiptNote, DocumentRef.CashAccountReceiptNote - Document for receiving the advance payment.
// 	 VATTaxation - EnumRef.VATTaxationTypes, Undefined - taxation from an invoice
//
// Returns:
// 	 ValueTable - The nomenclature of orders.
//
Function CustomerOrderProducts(PaymentDocument, VATTaxation = Undefined) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	SalesOrder.Ref AS Ref,
	|	SalesOrder.LineOfBusiness AS LineOfBusiness,
	|	ReceiptOfCash.ARAPObject AS ARAPObject
	|INTO SalesOrders
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|		INNER JOIN Document.BankAccountReceiptNote.ARAPDetails AS ReceiptOfCash
	|		ON SalesOrder.Ref = ReceiptOfCash.PaymentPurpose
	|			AND (ReceiptOfCash.Ref = &PaymentDocument)
	|			AND (&VATTaxationIsEmpty OR SalesOrder.VATTaxation = &VATTaxation)
	|
	|UNION
	|
	|SELECT
	|	SalesOrder.Ref,
	|	SalesOrder.LineOfBusiness,
	|	ReceiptOfCash.ARAPObject AS ARAPObject
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|		INNER JOIN Document.BankAccountReceiptNote.ARAPDetails AS ReceiptOfCash
	|		ON SalesOrder.Ref = ReceiptOfCash.ARAPObject.Object
	|			AND (ReceiptOfCash.Ref = &PaymentDocument)
	|			AND (&VATTaxationIsEmpty OR SalesOrder.VATTaxation = &VATTaxation)
	|
	|UNION
	|
	|SELECT
	|	SalesOrder.Ref,
	|	SalesOrder.LineOfBusiness,
	|	ReceiptOfCash.ARAPObject AS ARAPObject
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|		INNER JOIN Document.CashAccountReceiptNote.ARAPDetails AS ReceiptOfCash
	|		ON SalesOrder.Ref = ReceiptOfCash.PaymentPurpose
	|			AND (ReceiptOfCash.Ref = &PaymentDocument)
	|			AND (&VATTaxationIsEmpty OR SalesOrder.VATTaxation = &VATTaxation)
	|
	|UNION
	|
	|SELECT
	|	SalesOrder.Ref,
	|	SalesOrder.LineOfBusiness,
	|	ReceiptOfCash.ARAPObject AS ARAPObject
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|		INNER JOIN Document.CashAccountReceiptNote.ARAPDetails AS ReceiptOfCash
	|		ON SalesOrder.Ref = ReceiptOfCash.ARAPObject.Object
	|			AND (ReceiptOfCash.Ref = &PaymentDocument)
	|			AND (&VATTaxationIsEmpty OR SalesOrder.VATTaxation = &VATTaxation)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS SalesOrder,
	|	Goods.Ref.Currency AS Currency,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.ProductsInSet AS ProductsInSet,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|	Goods.Content AS Content,
	|	Goods.VATRate AS VATRate,
	|	SalesOrders.LineOfBusiness AS LineOfBusiness,
	|	SalesOrders.ARAPObject AS ARAPObject,
	|	SUM(Goods.VATAmount) AS VATAmount,
	|	SUM(Goods.AmountIncludingVAT) AS AmountIncludingVAT
	|FROM
	|	Document.SalesOrder.Goods AS Goods
	|		INNER JOIN SalesOrders AS SalesOrders
	|		ON Goods.Ref = SalesOrders.Ref
	|WHERE
	|	Goods.VATRate.Rate1 > 0
	|	AND NOT Goods.Canceled
	|
	|GROUP BY
	|	Goods.Ref,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Content,
	|	Goods.VATRate,
	|	SalesOrders.LineOfBusiness,
	|	SalesOrders.ARAPObject
	|
	|ORDER BY
	|	ProductsInSet,
	|	ItemVariantOfSet,
	|	Products";
	
	Query.SetParameter("PaymentDocument",        PaymentDocument);
	Query.SetParameter("VATTaxation",       VATTaxation);
	Query.SetParameter("VATTaxationIsEmpty", Not ValueIsFilled(VATTaxation));
	
	Goods = Query.Execute().Unload();
	
	Return Goods;
	
EndFunction

// Distributes advances for the item in proportion to the amount, including the VAT rate.
//
// Parameters:
// 	Prepayments - ValueTable - Advances for distribution
// 	Goods - ValueTable - The item to which you want to allocate
// 	PaymentDocument - DocumentRef - Payment document.
//
Procedure DistributeAdvancesOnGoods(Prepayments, Goods, PaymentDocument) Export
	
	AdvancesToDistribution = Prepayments.Copy();
	AdvancesToDistribution.GroupBy("VATRate, LineOfBusiness, ARAPObject", "Sum, VATAmount");
	
	Attributes = Common.ObjectAttributesValues(PaymentDocument, "Date, Organization");
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Content,
	|	Goods.Currency,
	|	Goods.LineOfBusiness,
	|	Goods.ARAPObject,
	|	Goods.AmountIncludingVAT,
	|	Goods.VATRate,
	|	Goods.VATAmount
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|SELECT
	|	ExchangeRates.Currency AS Currency,
	|	ExchangeRates.CourseNumerator AS CourseNumerator,
	|	ExchangeRates.CourseDenominator AS CourseDenominator
	|INTO ExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Period, Currency IN (
	|			SELECT DISTINCT
	|				Goods.Currency
	|			FROM
	|				Goods) AND BaseCurrency = &BaseCurrency) AS ExchangeRates
	|;
	|
	|SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Content,
	|	CASE
	|		WHEN ProductAttributes.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|				AND ProductAttributes.AccountingFeature IN
	|					(VALUE(Enum.ItemAccountingFeatures.PerformedByCompanyOnAgencyBasis),
	|					VALUE(Enum.ItemAccountingFeatures.PerformedByPartner))
	|			THEN VALUE(Enum.InventoryTypes.AgentService)
	|		WHEN ProductAttributes.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|				OR ProductAttributes.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.InventoryTypes.OperationService)
	|		ELSE VALUE(Enum.InventoryTypes.OwnGoods)
	|	END AS InventoryType,
	|	Goods.Currency,
	|	Goods.LineOfBusiness,
	|	Goods.ARAPObject,
	|	CASE
	|			WHEN Goods.VATRate.Rate1 > 0
	|				AND Goods.VATRate.CalculatedRate = FALSE
	|			THEN Goods.VATRate.RelevantCalculatedRate
	|		ELSE Goods.VATRate
	|	END AS VATRate,
	|	SUM(Goods.AmountIncludingVAT
	|		* ISNULL(ExchangeRates.CourseNumerator, 1) 
	|		/ ISNULL(ExchangeRates.CourseDenominator, 1)) AS AmountIncludingVAT,
	|	SUM(Goods.VATAmount 
	|		* ISNULL(ExchangeRates.CourseNumerator, 1) 
	|		/ ISNULL(ExchangeRates.CourseDenominator, 1)) AS VATAmount 
	|FROM
	|	Goods AS Goods
	|	LEFT JOIN 
	|		ExchangeRates AS ExchangeRates
	|	ON
	|		Goods.Currency = ExchangeRates.Currency
	|	INNER JOIN
	|		Catalog.Products AS ProductAttributes
	|	ON
	|		Goods.Products = ProductAttributes.Ref
	|	
	|GROUP BY
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CASE
	|		WHEN ProductAttributes.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|				AND ProductAttributes.AccountingFeature IN
	|					(VALUE(Enum.ItemAccountingFeatures.PerformedByCompanyOnAgencyBasis),
	|					VALUE(Enum.ItemAccountingFeatures.PerformedByPartner))
	|			THEN VALUE(Enum.InventoryTypes.AgentService)
	|		WHEN ProductAttributes.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|				OR ProductAttributes.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.InventoryTypes.OperationService)
	|		ELSE VALUE(Enum.InventoryTypes.OwnGoods)
	|	END,
	|	Goods.Content,
	|	Goods.Currency,
	|	Goods.LineOfBusiness,
	|	Goods.ARAPObject,
	|	CASE
	|		WHEN Goods.VATRate.Rate1 > 0
	|				AND Goods.VATRate.CalculatedRate = FALSE
	|			THEN Goods.VATRate.RelevantCalculatedRate
	|		ELSE Goods.VATRate
	|	END
	|";
	Query.SetParameter("Goods", Goods);
	Query.SetParameter("Period", Attributes.Date);
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	
	ProductsDatabase = Query.Execute().Unload();
	
	Prepayments.Clear();
	For Each LineOfAdvances In AdvancesToDistribution Do
		
		Filter = New Structure("VATRate,LineOfBusiness, ARAPObject");
		Filter.Insert("VATRate", LineOfAdvances.VATRate);
		Filter.Insert("LineOfBusiness", LineOfAdvances.LineOfBusiness);
		Filter.Insert("ARAPObject", LineOfAdvances.ARAPObject);
		ProductLines_2 = ProductsDatabase.FindRows(Filter);
		
		ArrayOfCoefficients = New Array;
		For Each RowGoods In ProductLines_2 Do
			ArrayOfCoefficients.Add(RowGoods.AmountIncludingVAT);
		EndDo;
		
		If ArrayOfCoefficients.Count() = 0 Then
			NewRow = Prepayments.Add();
			FillPropertyValues(NewRow, LineOfAdvances);
			NewRow.InventoryType = Enums.InventoryTypes.OwnGoods;
		EndIf;
		
		DistributionOfAmount = Common.DistributeAmountInProportionToCoefficients(LineOfAdvances.Sum, ArrayOfCoefficients);
		DistributionOfVATAmount = Common.DistributeAmountInProportionToCoefficients(LineOfAdvances.VATAmount, ArrayOfCoefficients);
		
		IndexOf = 0;
		For Each RowGoods In ProductLines_2 Do
			
			Sum    = ?(DistributionOfAmount    = Undefined, 0, DistributionOfAmount[IndexOf]);
			VATAmount = ?(DistributionOfVATAmount = Undefined, 0, DistributionOfVATAmount[IndexOf]);
			If Sum = 0 Then
				IndexOf = IndexOf + 1;
				Continue;
			EndIf;
			
			NewRow = Prepayments.Add();
			FillPropertyValues(NewRow, RowGoods);
			NewRow.Sum    = Sum;
			NewRow.VATAmount = VATAmount;
			NewRow.LineOfBusiness = LineOfAdvances.LineOfBusiness; 
			NewRow.ARAPObject = LineOfAdvances.ARAPObject;
			IndexOf = IndexOf + 1;
		EndDo;
		
	EndDo;
	
EndProcedure

// Returns the advance table for generating invoices
// 
// Returns:
// 	ValueTable - LongDesc:
// 		* Sfsformed - Boolean -
// 		* Counterparty - CatalogRef.Counterparties, CatalogRef.Companies -
// 		* Sum - Number - 
// 		* VATRate - CatalogRef.VATRates -
// 		* VATAmount - Number -
// 		* DocumentBasis - DocumentRef - 
// 		* DateOfDischarge - Date -
// 		* DocumentCurrency - CatalogRef.Currencies -
// 		* CurrencyAmount - Number -
// 		* TaxInvoiceAmount - Number -
// 		* TaxInvoice - DocumentRef.IssuedTaxInvoicePrepayment -
//
Function TableAdvancesReceived_() Export
	
	PrepaymentsFromCustomerLayout = New ValueTable;
	PrepaymentsFromCustomerLayout.Columns.Add("Sfsformed",            New TypeDescription("Boolean"));
	PrepaymentsFromCustomerLayout.Columns.Add("Patch",              New TypeDescription("Boolean"));
	PrepaymentsFromCustomerLayout.Columns.Add("Counterparty",               New TypeDescription("CatalogRef.Counterparties, CatalogRef.Companies"));
	PrepaymentsFromCustomerLayout.Columns.Add("VATTaxation",       New TypeDescription("EnumRef.VATTaxationTypes"));
	PrepaymentsFromCustomerLayout.Columns.Add("LineOfBusiness",  New TypeDescription("CatalogRef.LinesOfBusiness"));
	PrepaymentsFromCustomerLayout.Columns.Add("Sum",                    TMCommonUse.MoneyFieldTypeDescription());
	PrepaymentsFromCustomerLayout.Columns.Add("VATRate",                New TypeDescription("CatalogRef.VATRates"));
	PrepaymentsFromCustomerLayout.Columns.Add("VATAmount",                 TMCommonUse.MoneyFieldTypeDescription());
	PrepaymentsFromCustomerLayout.Columns.Add("DocumentBasis",        Metadata.DefinedTypes.BaseDocumentIssuedTaxInvoicePrepayment.Type);
	PrepaymentsFromCustomerLayout.Columns.Add("DateOfDischarge",              New TypeDescription("Date"));
	PrepaymentsFromCustomerLayout.Columns.Add("DocumentCurrency",          New TypeDescription("CatalogRef.Currencies"));
	PrepaymentsFromCustomerLayout.Columns.Add("CurrencyAmount",            TMCommonUse.MoneyFieldTypeDescription());
	PrepaymentsFromCustomerLayout.Columns.Add("TaxInvoiceAmount",        TMCommonUse.MoneyFieldTypeDescription());
	PrepaymentsFromCustomerLayout.Columns.Add("TaxInvoice",              New TypeDescription("DocumentRef.IssuedTaxInvoicePrepayment"));
	
	PrepaymentsFromCustomerLayout.Columns.Add("Organization",         New TypeDescription("CatalogRef.Companies"));
	PrepaymentsFromCustomerLayout.Columns.Add("EmployeeResponsible",       New TypeDescription("CatalogRef.Users"));
	PrepaymentsFromCustomerLayout.Columns.Add("Department",       New TypeDescription("CatalogRef.BusinessStructure"));
	PrepaymentsFromCustomerLayout.Columns.Add("Director",        New TypeDescription("CatalogRef.PersonsResponsibleAndCompanies"));
	PrepaymentsFromCustomerLayout.Columns.Add("ChiefAccountant",    New TypeDescription("CatalogRef.PersonsResponsibleAndCompanies"));
	PrepaymentsFromCustomerLayout.Columns.Add("ARAPObject",      New TypeDescription("CatalogRef.ARAPObjects"));
	PrepaymentsFromCustomerLayout.Columns.Add("RuleOfPrepaymentFilter", New TypeDescription("EnumRef.ProcedureOfRegisteringTaxInvoicesForPrepayment"));
	
	Return PrepaymentsFromCustomerLayout;
	
EndFunction

// Returns the number of invoices to be processed, or a table of advance payment data.
//
// Parameters:
//	Parameters - Structure - with the following properties:
//	* CompanyArray - Array of CatalogRef.Companies - Array of organizations.
//	* BeginOfPeriod - Date - bottom limit on the date of the Foundation document.
//	* EndOfPeriod - Date - upper limit on the date of the Foundation document.
//	* NoPeriodLimit - Boolean - do not limit the date of the Foundation document.
//	* ReturnFullTable - Boolean - return the full table of advances.
//
// Returns:
//	Number, ValueTable - the number of invoices to be processed, the advance data table.
//
Function ThereAreInvoicesForRegistration(Parameters) Export
	
	RuleOfPrepaymentFilter = Undefined;
	RulesForSelectionOfAdvances = New Map;
	If TypeOf(Parameters.CompanyArray) = Type("CatalogRef.Companies") Then
		VATAccountingSettings = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("VATAccountingSettings",
					Parameters.CompanyArray,
					Parameters.EndOfPeriod,
					True);
		If VATAccountingSettings <> Undefined Then
			RulesForSelectionOfAdvances.Insert(VATAccountingSettings.RuleOfPrepaymentFilterToRegisterTaxInvoices, Parameters.CompanyArray);
		EndIf;
	ElsIf TypeOf(Parameters.CompanyArray) = Type("Array") Then
		For Each Organization In Parameters.CompanyArray Do
			VATAccountingSettings = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("VATAccountingSettings",
						Organization,
						Parameters.EndOfPeriod,
						True);
			If VATAccountingSettings <> Undefined Then     
				If RulesForSelectionOfAdvances.Get(VATAccountingSettings.RuleOfPrepaymentFilterToRegisterTaxInvoices) = Undefined Then
					CompanyArray = New Array;
					CompanyArray.Add(Organization);
					RulesForSelectionOfAdvances.Insert(VATAccountingSettings.RuleOfPrepaymentFilterToRegisterTaxInvoices, CompanyArray);
				Else
					RulesForSelectionOfAdvances[VATAccountingSettings.RuleOfPrepaymentFilterToRegisterTaxInvoices].Add(Organization);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	AdvancesReceivedAreGeneral = TableAdvancesReceived_();
	
	For Each Rule In RulesForSelectionOfAdvances Do
		
		RuleOfPrepaymentFilter = Rule.Key;
		CompanyArray = Rule.Value;
	
		If RuleOfPrepaymentFilter = Undefined Then
			RuleOfPrepaymentFilter = Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffBeforeQuarterEnd;
		EndIf;
		If (RuleOfPrepaymentFilter = Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffBeforeQuarterEnd
				Or RuleOfPrepaymentFilter = Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffWithinFiveCalendarDays)
				And EndOfMonth(Parameters.EndOfPeriod) <> EndOfQuarter(Parameters.EndOfPeriod) Then
			Continue;
		ElsIf RuleOfPrepaymentFilter = Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.DoNotRegisterTaxInvoices Then
			Continue;
		EndIf;
		
		PrepaymentsFromCustomerLayout = TableAdvancesReceived_();   
		
		SelectionOfAdvances = New Structure; 
		SelectionOfAdvances.Insert("BeginOfPeriod", Parameters.BeginOfPeriod);
		SelectionOfAdvances.Insert("EndOfPeriod", Parameters.EndOfPeriod);
		SelectionOfAdvances.Insert("ARAPDocument", Undefined);
		SelectionOfAdvances.Insert("Organization", CompanyArray);
		SelectionOfAdvances.Insert("DefaultVATRate", Undefined);
		SelectionOfAdvances.Insert("RuleOfPrepaymentFilter", RuleOfPrepaymentFilter);

		FillInReceivedAdvancesForSF(SelectionOfAdvances, PrepaymentsFromCustomerLayout);
		
		TMCommonUse.AddRowsToTable(AdvancesReceivedAreGeneral, PrepaymentsFromCustomerLayout);
		
	EndDo;
	
	If Parameters.Property("ReturnFullTable") Then
		Return AdvancesReceivedAreGeneral;
	Else
		Return AdvancesReceivedAreGeneral.FindRows(New Structure("Sfsformed", False)).Count();
	EndIf;
	
EndFunction

// Returns the Attributes of the advance invoice and its actual correction according to the payment document.
//
// Parameters:
// 	PaymentDocument - DocumentRef - Payment document.
// 	Organization - CatalogRef.Companies - The company of the payment document.
//
// Returns:
//	Structure - Attributes of the invoice.
//
Function AdvancesOnPaymentDocument(PaymentDocument, Organization) Export
	
	Return IssuedTaxInvoicePrepaymentLocalization.AdvancesOnPaymentDocument(PaymentDocument, Organization);
	
EndFunction

#Region ConductingLocalAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - The text of the reflection request in the regl. accounting.
//
Function TextOfReflectionInLocalAccounting() Export
	QueryText = "";
	IssuedTaxInvoicePrepaymentLocalization.GenerateReflectionTextInLocalAccounting(QueryText);
	Return QueryText;
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in the regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	QueryText = "";
	IssuedTaxInvoicePrepaymentLocalization.GenerateRequestTextTTForReflectionInLocalAccounting(QueryText);
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
//  Number - String - Invoice number
//  Date - Date - Invoice date
//  Posted - Boolean - Whether the document is being held
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
								|tr = '(onaylanmadı)'"));
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
	
	If Not AccessRight("Read", Metadata.Documents.IssuedTaxInvoicePrepayment) Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Danh sách hóa đơn GTGT ứng trước';
						|ru = 'Список счетов-фактур на аванс';
						|en = 'List of tax invoices for advance'; fa = 'List of tax invoices for advance';
						|it = 'Elenco di fatture per anticipo';
						|pl = 'Lista faktur dla zaliczki';
						|tr = 'Avans faturalarının listesi'");
	FullFormName = Metadata.Documents.IssuedTaxInvoicePrepayment.DefaultListForm.FullName();
	
	Return New FormattedString(HyperlinkText, , StyleColors.HyperlinkColor, , FullFormName);

EndFunction

// Standard subsystems.Versioning objects
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

Procedure InitializeTTTableAdvances(Query) Export
	
	If Query.Parameters.Property("TTTableAdvancesInitialized") Then
		Return;
	EndIf;
	
	RequestTTTableAdvances = New Query;
	RequestTTTableAdvances.TempTablesManager = Query.TempTablesManager;
	
	RequestTTTableAdvances.SetParameter("Ref",                 Query.Parameters.Ref);
	RequestTTTableAdvances.SetParameter("Organization",            Query.Parameters.Organization);
	RequestTTTableAdvances.SetParameter("Customer",             Query.Parameters.Customer);
	RequestTTTableAdvances.SetParameter("DocumentPayments",         Query.Parameters.DocumentPayments);
	RequestTTTableAdvances.SetParameter("PrepaymentReceiptDate",    Query.Parameters.PrepaymentReceiptDate);
	RequestTTTableAdvances.SetParameter("InventoryTypesOwn", Query.Parameters.InventoryTypesOwn);
	RequestTTTableAdvances.SetParameter("CurrencyOfComplianceAccounting",        Query.Parameters.CurrencyOfComplianceAccounting);
	RequestTTTableAdvances.SetParameter("CurrencyOfManAccounting",         Query.Parameters.CurrencyOfManAccounting);
	
	RequestTTTableAdvances.Text =
	"SELECT
	|	&PrepaymentReceiptDate                                  AS Period,
	|	&Organization                                          AS Organization,
	|	&DocumentPayments                                       AS TaxInvoice,
	|	&Customer                                           AS Customer,
	|	&DocumentPayments                                       AS DocumentPayments,
	|	&PrepaymentReceiptDate                                  AS PayDate,
	|	&PrepaymentReceiptDate                                  AS EventDate,
	|	TableAdvances.VATRate                               AS VATRate,
	|	CASE 
	|		WHEN TableAdvances.InventoryType IN (&InventoryTypesOwn) 
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                 AS ReflectVATInAccounting,
	|	
	|	SUM(TableAdvances.VATAmount)                         AS VAT,
	|	SUM(CASE WHEN TableAdvances.Sum = 0
	|			THEN 0
	|		ELSE TableAdvances.Sum - TableAdvances.VATAmount
	|	END)                                                AS AmountExcludingVAT,
	|	SUM(CASE WHEN ISNULL(CurrencyExchangeRateManAccounting.CourseNumerator, 0) = 0
	|		THEN TableAdvances.VATAmount
	|		ELSE TableAdvances.VATAmount * CurrencyExchangeRateManAccounting.CourseDenominator / CurrencyExchangeRateManAccounting.CourseNumerator
	|	END) AS VATManag,
	|	SUM(CASE WHEN TableAdvances.Sum = 0 THEN 0
	|		WHEN ISNULL(CurrencyExchangeRateManAccounting.CourseNumerator, 0) = 0 THEN TableAdvances.Sum - TableAdvances.VATAmount
	|		ELSE (TableAdvances.Sum - TableAdvances.VATAmount) * CurrencyExchangeRateManAccounting.CourseDenominator / CurrencyExchangeRateManAccounting.CourseNumerator
	|	END)                                                AS AmountExcludingVATMan,
	|	
	|	TableAdvances.Ref.SettlementDocumentNumber AS PaymentDocumentNumber,
	|	TableAdvances.Ref.DateOfDocumentInARAPAccounting  AS PaymentDocumentDate,
	|	TableAdvances.Ref.VATTaxation               AS VATTaxation,
	|	TableAdvances.Ref.Department                    AS Department,
	|	TableAdvances.LineOfBusiness                 AS LineOfBusiness,
	|	TableAdvances.RowID                     AS RowID,
	|	TableAdvances.ARAPObject                          AS ARAPObject
	|INTO TTTableAdvances
	|FROM
	|	Document.IssuedTaxInvoicePrepayment.Prepayments AS TableAdvances
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&PrepaymentReceiptDate, Currency = &CurrencyOfManAccounting AND BaseCurrency = &CurrencyOfComplianceAccounting) AS CurrencyExchangeRateManAccounting
	|			ON &CurrencyOfComplianceAccounting <> &CurrencyOfManAccounting
	|	
	|WHERE
	|	TableAdvances.Ref = &Ref
	|	AND &Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|
	|GROUP BY
	|	CASE 
	|		WHEN TableAdvances.InventoryType IN (&InventoryTypesOwn) 
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	TableAdvances.VATRate,
	|	TableAdvances.LineOfBusiness,
	|	TableAdvances.RowID,
	|	TableAdvances.Ref,
	|	TableAdvances.ARAPObject";
	
	RequestTTTableAdvances.Execute();
	
	Query.SetParameter("TTTableAdvancesInitialized", True);
	
EndProcedure

#Region CreatingHyperlinkInVATDocumentLog

Function CreateHyperlinkToDesign(Parameters) Export
	
	If Not AccessRight("Update", Metadata.Documents.IssuedTaxInvoicePrepayment) Then
		Return Undefined;
	EndIf;
	
	Parameters.Insert("CompanyArray",?(ValueIsFilled(Parameters.Organization), 
											TMCommonUseClientServer.Array(Parameters.Organization),
											Undefined));
	
	If Parameters.Property("BriefPresentation") Then
		HyperlinkText = NStr("vi = 'Hóa đơn GTGT đã xuất (ứng trước)';
							|ru = 'СФ выданные (аванс)';
							|en = 'Issued invoices (advance)'; fa = 'Issued invoices (advance)';
							|it = 'Fatture emesse (anticipo)';
							|pl = 'Wystawione faktury (zaliczka)';
							|tr = 'Fatura düzenlendi (avans)'");
	Else
		HyperlinkText = NStr("vi = 'Hóa đơn GTGT đã phát hành (ứng trước)';
							|ru = 'Счета-фактуры выданные (аванс)';
							|en = 'Issued tax invoices (advance)'; fa = 'صورت‌حساب‌های مالیاتی صادرشده (پیش‌پرداخت)';
							|it = 'Fatture emesse (anticipo)';
							|pl = 'Wydane faktury (zaliczka)';
							|tr = 'Faturalar düzenlendi (avans)'");
	EndIf;	
	
	DocumentsCount = ThereAreInvoicesForRegistration(Parameters);
	
	If DocumentsCount = 0 Then
		Return New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,,
			FormNameInvoiceAdvanceIssued());
	Else
		Return New FormattedString(HyperlinkText,,,,
			FormNameInvoiceAdvanceIssued());
	EndIf;
	
EndFunction

Function FormNameInvoiceAdvanceIssued() Export
	
	Return "Document.IssuedTaxInvoicePrepayment.Form.WorkplaceForm";
	
EndFunction

#EndRegion

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
	|	DocumentData.Ref                                                            AS Ref,
	|	DocumentData.Date                                                              AS Period,
	|	DocumentData.Organization                                                       AS Organization,
	|	DocumentData.Counterparty                                                        AS Counterparty,
	|	DocumentData.Counterparty                                                        AS Customer,
	|	DocumentData.DocumentBasis                                                 AS DocumentPayments,
	|	DocumentData.DocumentBasis                                                 AS DocumentBasis,
	|	DocumentData.RuleOfPrepaymentFilter                                               AS RuleOfPrepaymentFilter,
	|	DocumentData.PrepaymentReceiptDate                                               AS PrepaymentReceiptDate,
	|	DocumentData.IssueDate                                                   AS IssueDate,
	|	DocumentData.Number                                                             AS Number,
	|	DocumentData.Date                                                              AS Date,
	|	DocumentData.IssuedInElectronicFormat                                         AS IssuedInElectronicFormat,
	|	DocumentData.Patch                                                       AS Patch,
	|	DocumentData.CorrectionNumber                                                  AS CorrectionNumber,
	|	DocumentData.BaseDocumentTaxInvoice                                              AS BaseDocumentTaxInvoice,
	|	DocumentData.BaseDocumentTaxInvoice.Date                                         AS DateOfBaseInvoice,
	|	DocumentData.BaseDocumentTaxInvoice.Number                                        AS BaseInvoiceNumber,
	|	DocumentData.Corrective                                                  AS Corrective,
	|	DocumentData.Department                                                     AS Department,
	|	DocumentData.EmployeeResponsible                                                     AS EmployeeResponsible,
	|	DocumentData.ManualAdjustmentOfTaxInvoiceRegister                                      AS ManualAdjustmentOfTaxInvoiceRegister,
	|	DocumentData.Posted                                                          AS Posted,
	|	DocumentData.Sum                                                             AS Sum,
	|	DocumentData.Comment                                                       AS Comment,
	|	DocumentData.DeletionMark                                                   AS DeletionMark,
	|	DocumentData.TransactionKindCode                                                   AS TransactionKindCode,
	|	DocumentData.CommissionAgreement.Counterparty                                        AS Consignee
	|FROM
	|	Document.IssuedTaxInvoicePrepayment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
		
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("InventoryTypesOwn",     VATAccountingERPInternal.InventoryTypesOwn());
	Query.SetParameter("MetadataIdentifier",    Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("Currency",                     SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	Query.SetParameter("CurrencyOfComplianceAccounting",            SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	Query.SetParameter("CurrencyOfManAccounting",             Constants.ManagementAccountingCurrency.Get());
	
	NumberForPrinting = Attributes.Number;
	IssuedTaxInvoicePrepaymentLocalization.SetNumberToPrint(NumberForPrinting, Attributes);
	Query.SetParameter("NumberForPrinting", NumberForPrinting);
	
	If TypeOf(Attributes.DocumentBasis) = Type("DocumentRef.OBEntry")
		Or TypeOf(Attributes.DocumentBasis) = Type("DocumentRef.OBEntryARAP")
		Or TypeOf(Attributes.DocumentBasis) = Type("DocumentRef.SourceDocument") Then
		OBEntry = True;
		EnteringResiduesInVU = VATAccountingERPInternal.EnteringResiduesInVU(Attributes.DocumentBasis);
	Else
		OBEntry = False;
		EnteringResiduesInVU = False;
	EndIf;
	Query.SetParameter("OBEntry",            OBEntry);
	Query.SetParameter("EnteringResiduesInVU", EnteringResiduesInVU);
	
	CorrectionInformation = "";
	If Attributes.Patch
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
									Attributes.Period);
	EndIf;
	Query.SetParameter("CorrectionInformation", CorrectionInformation);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure


Function QueryTextTableVATPrepaymentsFromCustomer(Query, QueryTexts, Registers)
	
	RegisterName = "VATPrepaymentsFromCustomer";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTTTableAdvances(Query);
	
	QueryText =
	"SELECT
	|	CASE 
	|		WHEN &Patch 
	|			THEN &Period
	|		ELSE TableAdvances.Period
	|	END AS Period,
	|	TableAdvances.Organization AS Organization,
	|	TableAdvances.DocumentPayments AS DocumentPayments,
	|	TableAdvances.Customer AS Counterparty,
	|	CASE
	|		WHEN &Patch
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END AS CorrectedTaxInvoice,
	|	TableAdvances.Department AS Department,
	|	TableAdvances.LineOfBusiness AS LineOfBusiness,
	|	TableAdvances.VATRate AS VATRate,
	|	TableAdvances.AmountExcludingVAT AS AmountExcludingVAT,
	|	TableAdvances.VAT AS VAT,
	|	TableAdvances.VATManag AS VATManag,
	|	VALUE(Enum.EventsVATFromPrepayments.AccrualFromPrepaymentFromCustomer) AS Event,
	|	UNDEFINED AS PrepaymentsSettlementDocument,
	|	FALSE AS PeriodEndTransaction,
	|	TableAdvances.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AccrueVATFromPrepaymentFromCustomer) AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry,
	|	TableAdvances.ARAPObject AS ARAPObject
	|FROM
	|	TTTableAdvances AS TableAdvances
	|WHERE
	|	TableAdvances.ReflectVATInAccounting
	|";
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableVATRegisterRecords(Query, QueryTexts, Registers)
	
	RegisterName = "VATRegisterRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTTTableAdvances(Query);
	
	QueryText =
	"SELECT
	|	CASE 
	|		WHEN &Patch 
	|			THEN &Period
	|		ELSE TableAdvances.Period
	|	END AS Period,
	|	TableAdvances.Organization AS Organization,
	|	VALUE(Enum.VATRegisterRecordTypes.Outgoing) AS EntryType,
	|	TableAdvances.Customer AS Counterparty,
	|	TableAdvances.DocumentPayments AS TaxInvoice,
	|	TableAdvances.VATRate AS VATRate,
	|	VALUE(Enum.AssetKinds.PrepaymentsFromCustomer) AS AssetTaxClass,
	|	TableAdvances.AmountExcludingVAT AS AmountExcludingVAT,
	|	TableAdvances.VAT AS VAT,
	|	TableAdvances.VATManag AS VATManag,
	|	FALSE AS PeriodEndTransaction,
	|	TableAdvances.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AccrueVATFromPrepaymentFromCustomer) AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|FROM
	|	TTTableAdvances AS TableAdvances
	|WHERE
	|	TableAdvances.ReflectVATInAccounting
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
	|	&Ref AS Ref,
	|	&Period AS IBDocumentDate,
	|	&Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization AS Organization,
	|	CASE VALUETYPE(&DocumentPayments)
	|		WHEN TYPE(Document.OBEntry)
	|			THEN CASE ISNULL(DocumentData.DocumentBasis.BusinessOperation,
	|				VALUE(Enum.BusinessTransactions.EmptyRef))
	|				WHEN VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer)
	|					THEN VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|				WHEN VALUE(Enum.BusinessTransactions.OBEntryUnmatchedIntercompanyPrepayment)
	|					THEN VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany)
	|				ELSE VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|			END
	|		WHEN TYPE(Document.OBEntryARAP)
	|			THEN CASE ISNULL(DocumentData.DocumentBasis.BusinessOperation,
	|				VALUE(Enum.BusinessTransactions.EmptyRef))
	|				WHEN VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer)
	|					THEN VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|				WHEN VALUE(Enum.BusinessTransactions.OBEntryUnmatchedIntercompanyPrepayment)
	|					THEN VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany)
	|				ELSE VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|			END
	|		WHEN TYPE(Document.SourceDocument)
	|			THEN VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|		WHEN TYPE(Document.GiftCertificateSale)
	|			THEN VALUE(Enum.BusinessTransactions.GiftCertificateSale)
	|		WHEN TYPE(Document.PaymentCardTransaction)
	|			THEN VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|		WHEN TYPE(Document.ARAPSettlement)
	|			THEN VALUE(Enum.BusinessTransactions.ARAPAdjustment)
	|		WHEN TYPE(Document.ReturnOfGoodsFromCustomer)
	|			THEN VALUE(Enum.BusinessTransactions.ARAPAdjustment)
	|		WHEN TYPE(Document.IntercompanyGoodsReturn)
	|			THEN VALUE(Enum.BusinessTransactions.ARAPAdjustment)
	|		WHEN TYPE(Document.SaleAdjustment)
	|			THEN VALUE(Enum.BusinessTransactions.ARAPAdjustment)
	|		WHEN TYPE(Document.CashAccountReceiptNote)
	|			THEN CAST(DocumentData.DocumentBasis AS Document.CashAccountReceiptNote).BusinessOperation
	|		WHEN TYPE(Document.BankAccountReceiptNote)
	|			THEN CAST(DocumentData.DocumentBasis AS
	|				Document.BankAccountReceiptNote).BusinessOperation
	|		ELSE VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|	END AS BusinessOperation,
	|	ISNULL(DocumentData.DocumentBasis.Partner, VALUE(Catalog.Partners.EmptyRef)) AS Partner,
	|	&Counterparty AS Counterparty,
	|	CASE
	|		WHEN VALUETYPE(&DocumentPayments) = TYPE(Document.ReturnOfGoodsFromCustomer)
	|		OR VALUETYPE(&DocumentPayments) = TYPE(Document.IntercompanyGoodsReturn)
	|		OR VALUETYPE(&DocumentPayments) = TYPE(Document.SaleAdjustment)
	|			THEN ISNULL(DocumentData.DocumentBasis.Contract, UNDEFINED)
	|		ELSE UNDEFINED
	|	END AS Contract,
	|	ISNULL(DocumentData.DocumentBasis.LineOfBusiness,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	ISNULL(DocumentData.DocumentBasis.Warehouse, VALUE(Catalog.Warehouses.EmptyRef)) AS StorageLocation,
	|	&Department AS Department,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	&Comment AS Comment,
	|	DocumentData.Organization.LocalAccountingCurrency AS Currency,
	|	&Sum AS Sum,
	|	UNDEFINED AS Status,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	&CorrectionInformation AS More,
	|	&Period AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.IssuedTaxInvoicePrepayment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	TextOfEvent = QueryTexts.Add(QueryText, RegisterName);
	IssuedTaxInvoicePrepaymentLocalization.AddRequestTextToDocumentRegistry(Query, TextOfEvent, Registers);
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.IssuedTaxInvoicePrepayment";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",           """""");
	RedefiningParameterCalculation.Insert("CorrectionInformation", """""");
	RedefiningParameterCalculation.Insert("DocumentPayments", "DocumentData.DocumentBasis");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
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

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	IssuedTaxInvoicePrepaymentLocalization.AddPrintCommands(PrintCommands);
	
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
	
	IssuedTaxInvoicePrepaymentLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters)
	
EndProcedure

Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Counterparty";
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty.Partner");
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// Returns the result of a request for advances received from customers to generate advance invoices.
//
// Parameters:
// 	BeginOfPeriod - Date - Start of the period for which you need to find advances
// 	EndOfPeriod - Date - End of the period for which you need to find advances
// 	Organization - CatalogRef.Companies - Organization for selection
// 	ARAPDocument - DocumentRef - Payment document for selection.
// 	TempTablesManager - TempTablesManager - 
// 	
// Returns:
// QueryResult   - contains data on the advances received.
//
Function RequestResultForAdvances(BeginOfPeriod, EndOfPeriod, Organization, ARAPDocument, AdvanceSelectionRule, TempTablesManager)
	
	If ValueIsFilled(Organization) Then
		BusinessPairs = Organization;
	Else
		AvailableCompanies = Catalogs.Companies.AvailableCompanies();
		CommonClientServer.DeleteAllValueOccurrencesFromArray(
			AvailableCompanies, 
			Catalogs.Companies.ManagementCompany);
		BusinessPairs = AvailableCompanies;
	EndIf;
	
	CalculationParameters = VATAccountingERPInternal.InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes();
	
	CalculationParameters.StartDate                    = BeginOfPeriod;
	CalculationParameters.EndDate                 = EndOfDay(EndOfPeriod);
	CalculationParameters.Companies                   = BusinessPairs;
	CalculationParameters.ARAPDocument             = ARAPDocument;
	CalculationParameters.AdvanceSelectionRule          = AdvanceSelectionRule;
	CalculationParameters.EnableGiftCertificateData = True;
	
	SetPrivilegedMode(True);
	VATAccountingERPInternal.PrepareVT_AdvancesReceived(TempTablesManager, CalculationParameters);
	SetPrivilegedMode(False);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
	"SELECT
	|	AdvancesForFormationOfSF.Organization AS Organization,
	|	AdvancesForFormationOfSF.LineOfBusiness AS LineOfBusiness,
	|	AdvancesForFormationOfSF.ARAPObject AS ARAPObject,
	|	CASE
	|		WHEN AdvancesForFormationOfSF.TaxationType IN(
	|					VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer),
	|					VALUE(Enum.VATTaxationTypes.EmptyRef),
	|					VALUE(Enum.VATTaxationTypes.PreferentialVATTaxationOnSTS),
	|					VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|			THEN AdvancesForFormationOfSF.TaxationType
	|		ELSE
	|			VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END AS VATTaxation,
	|	MAX(AdvancesForFormationOfSF.DateOfSFFormation) AS DateOfSFFormation,
	|	AdvancesForFormationOfSF.Counterparty AS Counterparty,
	|	AdvancesForFormationOfSF.ARAPDocument AS DocumentBasis,
	|	AdvancesForFormationOfSF.DocumentCurrency AS DocumentCurrency,
	|	AdvancesForFormationOfSF.Contract.VATRate AS VATRateUnderAgreement,
	|	SUM(AdvancesForFormationOfSF.SumCurr) AS CurrencyAmount,
	|	SUM(AdvancesForFormationOfSF.Sum) AS Sum
	|INTO AdvancesForFormationOfSF
	|FROM
	|	BaseNDS_AdvancesReceived AS AdvancesForFormationOfSF
	|
	|GROUP BY
	|	AdvancesForFormationOfSF.Organization,
	|	AdvancesForFormationOfSF.LineOfBusiness,
	|	AdvancesForFormationOfSF.ARAPObject,
	|	CASE
	|		WHEN AdvancesForFormationOfSF.TaxationType IN(
	|					VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer),
	|					VALUE(Enum.VATTaxationTypes.EmptyRef),
	|					VALUE(Enum.VATTaxationTypes.PreferentialVATTaxationOnSTS),
	|					VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|			THEN AdvancesForFormationOfSF.TaxationType
	|		ELSE
	|			VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END,
	|	AdvancesForFormationOfSF.Counterparty,
	|	AdvancesForFormationOfSF.ARAPDocument,
	|	AdvancesForFormationOfSF.DocumentCurrency,
	|	AdvancesForFormationOfSF.Contract.VATRate
	|
	|HAVING
	|	SUM(AdvancesForFormationOfSF.SumCurr) > 0
	|
	|INDEX BY
	|	DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP BaseNDS_AdvancesReceived
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AdvancesForFormationOfSF.Organization             AS Organization,
	|	AdvancesForFormationOfSF.LineOfBusiness AS LineOfBusiness,
	|	AdvancesForFormationOfSF.ARAPObject          AS ARAPObject,
	|	AdvancesForFormationOfSF.VATTaxation      AS VATTaxation,
	|	AdvancesForFormationOfSF.DateOfSFFormation      AS DateOfSFFormation,
	|	CASE
	|		WHEN CAST(AdvancesForFormationOfSF.ARAPObject.Contract AS Catalog.CounterpartyContracts).ContractType
	|				= VALUE(Enum.ContractTypes.SalesViaCommissionAgent)
	|			THEN CAST(AdvancesForFormationOfSF.ARAPObject.Contract AS Catalog.CounterpartyContracts).Counterparty
	|			ELSE AdvancesForFormationOfSF.Counterparty
	|	END                                           AS Counterparty,
	|	AdvancesForFormationOfSF.DocumentBasis       AS DocumentBasis,
	|	AdvancesForFormationOfSF.DocumentCurrency         AS DocumentCurrency,
	|	AdvancesForFormationOfSF.VATRateUnderAgreement 	AS VATRateUnderAgreement,
	|	AdvancesForFormationOfSF.CurrencyAmount           AS CurrencyAmount,
	|	AdvancesForFormationOfSF.Sum                   AS Sum,
	|	AdvancesForFormationOfSF.ARAPObject.Object   AS Object,
	|	ISNULL(CAST(AdvancesForFormationOfSF.ARAPObject.OBJECT
	|			AS Catalog.CounterpartyContracts).ConsignmentSales25, FALSE) AS ConsignmentSales25,
	|	CAST(AdvancesForFormationOfSF.ARAPObject.OBJECT AS Document.CustomerInvoice).BusinessOperation AS BusinessOperation,
	|	CAST(AdvancesForFormationOfSF.ARAPObject.OBJECT AS Document.CustomerInvoice).ARAPObjectSettings AS ARAPObjectSettings
	|FROM
	|	AdvancesForFormationOfSF AS AdvancesForFormationOfSF
	|
	|ORDER BY
	|	DateOfSFFormation
	|";
	
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
	|	Document.CashAccountReceiptNote.ARAPDetails AS Details
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
	|	Document.BankAccountReceiptNote.ARAPDetails AS Details
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
	|	Document.PaymentCardTransaction.ARAPDetails AS Details
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
	|	Goods.VATRate            AS VATRate,
	|	Goods.Sum                AS Sum
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS Goods
	|	INNER JOIN
	|		AdvancesForFormationOfSF AS AdvancesForFormationOfSF
	|	ON
	|		Goods.Ref = AdvancesForFormationOfSF.DocumentBasis
	|
	|UNION ALL
	|
	|SELECT
	|	AdvancesForFormationOfSF.DocumentBasis AS DocumentBasis,
	|	AdvancesForFormationOfSF.ARAPObject    AS ARAPObject,
	|	CASE
	|		WHEN Details.Ref.VATTaxation IN (VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII),
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				VALUE(Enum.VATTaxationTypes.SalesByPatent))
	|			THEN VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		ELSE VALUE(Catalog.VATRates.EmptyRef)
	|	END                       AS VATRate,
	|	Details.Sum           AS Sum
	|FROM
	|	Document.GiftCertificateSale.GiftCertificates AS Details
	|	INNER JOIN
	|		AdvancesForFormationOfSF AS AdvancesForFormationOfSF
	|	ON
	|		Details.Ref = AdvancesForFormationOfSF.DocumentBasis
	|		AND Details.ARAPObject = AdvancesForFormationOfSF.ARAPObject
	|";
	ArrayOfRequestTexts.Add(QueryText);
	
	IssuedTaxInvoicePrepaymentLocalization.AddRequestTextsForTheseDocuments(ArrayOfRequestTexts, Query);
	
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

Function TableOfRegisteredInvoices(TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = 
	"SELECT
	|	IssuedTaxInvoicePrepayment.Ref             AS TaxInvoice,
	|	IssuedTaxInvoicePrepayment.Date               AS DateOfDischarge,
	|	IssuedTaxInvoicePrepayment.DocumentBasis  AS DocumentBasis,
	|	IssuedTaxInvoicePrepayment.VATTaxation AS VATTaxation,
	|	CASE
	|		WHEN IssuedTaxInvoicePrepayment.Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE IssuedTaxInvoicePrepayment.Counterparty
	|	END                                         AS Counterparty,
	|	TableAdvances.VATRate                       AS VATRate,
	|	IssuedTaxInvoicePrepayment.EmployeeResponsible        AS EmployeeResponsible,
	|	IssuedTaxInvoicePrepayment.Department        AS Department,
	|	IssuedTaxInvoicePrepayment.Director         AS Director,
	|	IssuedTaxInvoicePrepayment.ChiefAccountant     AS ChiefAccountant,
	|	IssuedTaxInvoicePrepayment.Sum                AS TaxInvoiceAmount,
	|	SUM(TableAdvances.Sum)                    AS Sum,
	|	SUM(TableAdvances.VATAmount)                 AS VATAmount,
	|	TableAdvances.ARAPObject                  AS ARAPObject,
	|	FALSE                                          AS Overrepresented,
	|	IssuedTaxInvoicePrepayment.RuleOfPrepaymentFilter  AS RuleOfPrepaymentFilter,
	|	IssuedTaxInvoicePrepayment.Patch          AS Patch,
	|	IssuedTaxInvoicePrepayment.SettlementDocumentNumber AS SettlementDocumentNumber,
	|	IssuedTaxInvoicePrepayment.DateOfDocumentInARAPAccounting  AS DateOfDocumentInARAPAccounting
	|FROM
	|	Document.IssuedTaxInvoicePrepayment AS IssuedTaxInvoicePrepayment
	|	
	|	INNER JOIN
	|		Document.IssuedTaxInvoicePrepayment.Prepayments AS TableAdvances
	|	ON
	|		IssuedTaxInvoicePrepayment.Ref = TableAdvances.Ref
	|
	|	LEFT JOIN 
	|		Document.IssuedTaxInvoicePrepayment AS InvoiceAdvancePaymentCorrection
	|	ON 
	|		IssuedTaxInvoicePrepayment.DocumentBasis = InvoiceAdvancePaymentCorrection.DocumentBasis
	|		AND IssuedTaxInvoicePrepayment.Counterparty= InvoiceAdvancePaymentCorrection.Counterparty
	|		AND IssuedTaxInvoicePrepayment.Ref = InvoiceAdvancePaymentCorrection.BaseDocumentTaxInvoice
	|		AND InvoiceAdvancePaymentCorrection.Patch
	|		AND InvoiceAdvancePaymentCorrection.Posted
	|WHERE
	|	IssuedTaxInvoicePrepayment.DocumentBasis IN
	|			(SELECT DISTINCT
	|				AdvancesForFormationOfSF.DocumentBasis
	|			FROM
	|				AdvancesForFormationOfSF AS AdvancesForFormationOfSF)
	|	AND IssuedTaxInvoicePrepayment.Posted
	|	AND IssuedTaxInvoicePrepayment.VATTaxation IN
	|			(VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT),
	|			VALUE(Enum.VATTaxationTypes.PreferentialVATTaxationOnSTS),
	|			VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer),
	|			VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|	AND InvoiceAdvancePaymentCorrection.Ref IS NULL
	|	AND NOT TRUE IN 
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		WHERE
	|			DocumentsRegistry.RefType = &RefType
	|			AND DocumentsRegistry.ReversedDocument = IssuedTaxInvoicePrepayment.Ref
	|			AND DocumentsRegistry.Posted)
	|
	|GROUP BY
	|	IssuedTaxInvoicePrepayment.Ref,
	|	IssuedTaxInvoicePrepayment.Date,
	|	IssuedTaxInvoicePrepayment.DocumentBasis,
	|	IssuedTaxInvoicePrepayment.VATTaxation,
	|	CASE
	|		WHEN IssuedTaxInvoicePrepayment.Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE IssuedTaxInvoicePrepayment.Counterparty
	|	END,
	|	TableAdvances.VATRate,
	|	IssuedTaxInvoicePrepayment.EmployeeResponsible,
	|	IssuedTaxInvoicePrepayment.Department,
	|	IssuedTaxInvoicePrepayment.Director,
	|	IssuedTaxInvoicePrepayment.ChiefAccountant,
	|	IssuedTaxInvoicePrepayment.Sum,
	|	TableAdvances.ARAPObject,
	|	IssuedTaxInvoicePrepayment.RuleOfPrepaymentFilter,
	|	IssuedTaxInvoicePrepayment.Patch,
	|	IssuedTaxInvoicePrepayment.SettlementDocumentNumber,
	|	IssuedTaxInvoicePrepayment.DateOfDocumentInARAPAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	IssuedTaxInvoicePrepayment.Ref             AS TaxInvoice,
	|	IssuedTaxInvoicePrepayment.Date               AS DateOfDischarge,
	|	CommitteesAdvances.ARAPDocument          AS DocumentBasis,
	|	IssuedTaxInvoicePrepayment.VATTaxation AS VATTaxation,
	|	CASE
	|		WHEN IssuedTaxInvoicePrepayment.Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE IssuedTaxInvoicePrepayment.Counterparty
	|	END                                         AS Counterparty,
	|	TableAdvances.VATRate                       AS VATRate,
	|	IssuedTaxInvoicePrepayment.EmployeeResponsible        AS EmployeeResponsible,
	|	IssuedTaxInvoicePrepayment.Department        AS Department,
	|	IssuedTaxInvoicePrepayment.Director         AS Director,
	|	IssuedTaxInvoicePrepayment.ChiefAccountant     AS ChiefAccountant,
	|	IssuedTaxInvoicePrepayment.Sum                AS TaxInvoiceAmount,
	|	SUM(TableAdvances.Sum)                    AS Sum,
	|	SUM(TableAdvances.VATAmount)                 AS VATAmount,
	|	TableAdvances.ARAPObject                  AS ARAPObject,
	|	TRUE                                        AS Overrepresented,
	|	IssuedTaxInvoicePrepayment.RuleOfPrepaymentFilter  AS AdvanceSelectionRule,
	|	IssuedTaxInvoicePrepayment.Patch          AS Patch,
	|	IssuedTaxInvoicePrepayment.SettlementDocumentNumber AS SettlementDocumentNumber,
	|	IssuedTaxInvoicePrepayment.DateOfDocumentInARAPAccounting  AS DateOfDocumentInARAPAccounting
	|FROM
	|	Document.IssuedTaxInvoicePrepayment.ConsignorSPrincipalSARAPDocuments AS CommitteesAdvances
	|	
	|	INNER JOIN
	|		Document.IssuedTaxInvoicePrepayment AS IssuedTaxInvoicePrepayment
	|	ON
	|		IssuedTaxInvoicePrepayment.Ref = CommitteesAdvances.Ref
	|
	|	INNER JOIN
	|		Document.IssuedTaxInvoicePrepayment.Prepayments AS TableAdvances
	|	ON
	|		IssuedTaxInvoicePrepayment.Ref = TableAdvances.Ref
	|
	|	LEFT JOIN 
	|		Document.IssuedTaxInvoicePrepayment AS InvoiceAdvancePaymentCorrection
	|	ON 
	|		IssuedTaxInvoicePrepayment.DocumentBasis = InvoiceAdvancePaymentCorrection.DocumentBasis
	|		AND IssuedTaxInvoicePrepayment.Counterparty= InvoiceAdvancePaymentCorrection.Counterparty
	|		AND IssuedTaxInvoicePrepayment.Ref = InvoiceAdvancePaymentCorrection.BaseDocumentTaxInvoice
	|		AND InvoiceAdvancePaymentCorrection.Patch
	|		AND InvoiceAdvancePaymentCorrection.Posted
	|WHERE
	|	CommitteesAdvances.ARAPDocument IN
	|			(SELECT DISTINCT
	|				AdvancesForFormationOfSF.DocumentBasis
	|			FROM
	|				AdvancesForFormationOfSF AS AdvancesForFormationOfSF)
	|	AND IssuedTaxInvoicePrepayment.Posted
	|	AND IssuedTaxInvoicePrepayment.VATTaxation IN (
	|			VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT),
	|			VALUE(Enum.VATTaxationTypes.PreferentialVATTaxationOnSTS))
	|	AND InvoiceAdvancePaymentCorrection.Ref IS NULL
	|	AND NOT TRUE IN 
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		WHERE
	|			DocumentsRegistry.RefType = &RefType
	|			AND DocumentsRegistry.ReversedDocument = IssuedTaxInvoicePrepayment.Ref
	|			AND DocumentsRegistry.Posted)
	|
	|GROUP BY
	|	IssuedTaxInvoicePrepayment.Ref,
	|	IssuedTaxInvoicePrepayment.Date,
	|	CommitteesAdvances.ARAPDocument,
	|	IssuedTaxInvoicePrepayment.VATTaxation,
	|	CASE
	|		WHEN IssuedTaxInvoicePrepayment.Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE IssuedTaxInvoicePrepayment.Counterparty
	|	END,
	|	TableAdvances.VATRate,
	|	IssuedTaxInvoicePrepayment.EmployeeResponsible,
	|	IssuedTaxInvoicePrepayment.Department,
	|	IssuedTaxInvoicePrepayment.Director,
	|	IssuedTaxInvoicePrepayment.ChiefAccountant,
	|	IssuedTaxInvoicePrepayment.Sum,
	|	TableAdvances.ARAPObject,
	|	IssuedTaxInvoicePrepayment.RuleOfPrepaymentFilter,
	|	IssuedTaxInvoicePrepayment.Patch,
	|	IssuedTaxInvoicePrepayment.SettlementDocumentNumber,
	|	IssuedTaxInvoicePrepayment.DateOfDocumentInARAPAccounting
	|";
	Query.SetParameter("RefType", Common.MetadataObjectID(EmptyRef().Metadata()));
	SetPrivilegedMode(True);
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#EndRegion

#EndIf

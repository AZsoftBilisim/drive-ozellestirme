#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Fills in the data access restriction.
//
// Parameters:
//   Restriction - Structure - an object containing the text of the access restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ForAllRows(ValueAllowed(Content.Individual, NULL AS TRUE))
	|	AND ValueAllowed(Organization)
	|	AND ValueAllowed(Department)";

EndProcedure
	
// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region Posting

// Returns additional sources of data for register Registered Records.
//
// Parameters:
//   RegisterName - String - name of the register for which data sources are requested
//
// Returns:
// Map of String, Arbitrary - The data sources for register Register Records are
Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;
	Return DataSources;

EndFunction

// Generates the adapted Query Text for the Register Records of the document "Vedomosti Payment" according to the specified register.
//
// Parameters:
//   RegisterName - String - name of the register for which the request is generated
//
// Returns:
//  See InfobaseUpdateTM.ResultOfRequestAdaptation
//
Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;

	FullDocumentName = "Document.PayrollStatementHR";
	SynonymForDocumentTable = "";
	ParameterValues = ValuesOfHoldingParameters();

	RedefiningParameterCalculation = New Structure;

	RequestHasSource = True;

	If RegisterName = "DocumentsRegistry" Then

		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		RequestHasSource = False;
		
	Else
		ExceptionText = NStr(
			"vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
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
			QueryText, FullDocumentName, SynonymForDocumentTable, RequestHasSource,
			RedefiningParameterCalculation);

	Else

		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable, RedefiningParameterCalculation);

	EndIf;

	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;

	Return Result;

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)

	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	Attributes.Ref AS Ref,
	|	Attributes.Posted AS Posted,
	|	Attributes.Date AS Date,
	|	Attributes.Number AS Number,
	|	Attributes.Organization AS Organization,
	|	Attributes.Department AS Department,
	|	Attributes.PaymentMethodHR AS PaymentMethodHR,
	|	Attributes.KindOfPayment AS KindOfPayment,
	|	Attributes.DateOfPayment AS DateOfPayment,
	|	Attributes.Bank AS Bank,
	|	Attributes.EmployeeResponsible AS EmployeeResponsible,
	|	Attributes.Comment AS Comment,
	|	Attributes.DeletionMark AS DeletionMark
	|FROM
	|	Document.PayrollStatementHR AS Attributes
	|WHERE
	|	Attributes.Ref = &Ref";

	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();

	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;

	Query.SetParameter("IDOfUnusedFinRecord",
		DocumentsPosting.IDOfUnusedFinRecord());
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(Type(
		"DocumentRef.PayrollStatementHR")));
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));

EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	Values = New Structure;
	Values.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.PayrollStatementHR"));
	Values.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	If Attributes <> Undefined Then

		Values.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));

	EndIf;

	Return Values;

EndFunction

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
	//
	// Parameters:
	//  DocumentMechanisms - Array of String- list of names of accounting mechanisms that will be
	//              registered in the tracking mechanism.
	//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export

	DocumentMechanisms.Add("PayrollAccountingHR");
	DocumentMechanisms.Add("DocumentsRegistry");

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

	If TypeOf(Document) = Type("DocumentObject.PayrollStatementHR") Then
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
		QueryTextPayrollCalculations(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	EndIf;
		
		////////////////////////////////////////////////////////////////////////////
		// We will get tables for movements

	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);

EndFunction

Function QueryTextPayrollCalculations(Query, QueryTexts, Registers)

	RegisterName = "PayrollCalculationsHR";

	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	PayrollStatementHRContent.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	PayrollStatementHR.Date AS Period,
	|	PayrollStatementHR.Organization AS Organization,
	|	PayrollStatementHR.Department AS Department,
	|	PayrollStatementHRContent.Individual AS Individual,
	|	VALUE(Catalog.TypesOfEmployeeCompensations.Payroll) AS ARAPType,
	|	0 AS Sum,
	|	0 AS SumMan,
	|	0 AS SumCompl,
	|	PayrollStatementHRContent.ToBePaid AS AmountToBePaid,
	|	&IDOfUnusedFinRecord AS FinRecordID
	|FROM
	|	Document.PayrollStatementHR.Content AS PayrollStatementHRContent
	|		INNER JOIN Document.PayrollStatementHR AS PayrollStatementHR
	|		ON PayrollStatementHRContent.Ref = PayrollStatementHR.Ref
	|WHERE
	|	PayrollStatementHRContent.Ref = &Ref";

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
	|	&Ref									AS Ref,
	|	UNDEFINED							AS RecordSeparator,
	|	&Date									AS IBDocumentDate,
	|	&Number									AS IBDocumentNumber,
	|	&MetadataIdentifier				AS RefType,
	|	&Organization							AS Organization,
	|	UNDEFINED 							AS BusinessOperation,
	|	UNDEFINED							AS LineOfBusiness,
	|	&Department							AS Department,
	|	&EmployeeResponsible							AS EmployeeResponsible,
	|	&Comment							AS Comment,
	|	UNDEFINED							AS Currency,
	|	UNDEFINED							AS Sum,
	|	&Posted								AS Posted,
	|	&DeletionMark						AS DeletionMark,
	|	FALSE									AS AdditionalRecord,
	|	""""									AS More,
	|	&Date									AS SourceDocumentDate,
	|	&NumberForPrinting							AS SourceDocumentNumber,
	|	UNDEFINED							AS StorageLocation,
	|	FALSE									AS ReverseTransactionCorrection,
	|	UNDEFINED							AS ReversedDocument,
	|	UNDEFINED							AS CorrectedDocument,
	|	&Date									AS RecordingInAccountingDate,
	|	UNDEFINED							AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;

EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - ValueTable - for the composition of the fields, see the Print Management function.Create a collection of print commands.
//
Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PF_MXL_Statement";
	PrintCommand.Presentation = NStr("vi = 'In';
									|ru = 'Печать';
									|en = 'Print'; fa = 'چاپ';
									|it = 'Stampa';
									|pl = 'Print';
									|tr = 'Yazdır'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	PayrollStatementHRLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If Not PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PF_MXL_Statement") Then
		Return;
	EndIf;
	
	DataForPrint = GenerateRequestForPrinting(ObjectsArray);
	If DataForPrint.IsEmpty() Then
		Return;
	EndIf;
	SelectionByDocuments = DataForPrint.Select(QueryResultIteration.ByGroups);
	
	While SelectionByDocuments.Next() Do
		SpreadsheetDocument = New SpreadsheetDocument;
		CashAccountStatement = SelectionByDocuments.PaymentMethodHR = Enums.PaymentMethodsHR.CashAccount;
		TemplateName = ?(CashAccountStatement, "PF_MXL_CashAccountStatement", "PF_MXL_BankPaySheet");
		CreatePrintedFormStatement(SelectionByDocuments, CashAccountStatement, TemplateName, SpreadsheetDocument);
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "PF_MXL_Statement",
		"Print", SpreadsheetDocument);
	EndDo;
	
	PayrollStatementHRLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);

EndProcedure

Function GenerateRequestForPrinting(ObjectsArray)

	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	PayrollStatementHR.Ref AS Ref,
	|	PayrollStatementHR.Organization AS Organization,
	|	PayrollStatementHR.Department AS Department,
	|	Statement_Composition.LineNumber AS LineNumber,
	|	Statement_Composition.Individual AS Individual,
	|	Statement_Composition.Individual.Description AS Description,
	|	Statement_Composition.ToBePaid AS Sum,
	|	Statement_Composition.BankAccount.AccountNumber AS BankAccount,
	|	PayrollStatementHR.Director AS Director,
	|	PayrollStatementHR.JobTitleExecutive AS JobTitleExecutive,
	|	PayrollStatementHR.Currency AS Currency,
	|	PayrollStatementHR.Number AS Number,
	|	PayrollStatementHR.Date AS Date,
	|	PayrollStatementHR.DateOfPayment AS DateOfPayment,
	|	PayrollStatementHR.SumByDocument AS SumByDocument,
	|	PayrollStatementHR.PaymentMethodHR AS PaymentMethodHR
	|FROM
	|	Document.PayrollStatementHR AS PayrollStatementHR
	|		INNER JOIN Document.PayrollStatementHR.Content AS Statement_Composition
	|		ON PayrollStatementHR.Ref = Statement_Composition.Ref
	|WHERE
	|	PayrollStatementHR.Ref IN(&ObjectsArray)
	|	AND PayrollStatementHR.Posted
	|
	|ORDER BY
	|	PayrollStatementHR.Date
	|TOTALS
	|	MAX(Organization),
	|	MAX(Department),
	|	MAX(Director),
	|	MAX(JobTitleExecutive),
	|	MAX(Currency),
	|	MAX(Number),
	|	MAX(Date),
	|	MAX(DateOfPayment),
	|	MAX(SumByDocument),
	|	MAX(PaymentMethodHR)
	|BY
	|	Ref";

	Query.SetParameter("ObjectsArray", ObjectsArray);
	QueryResult = Query.Execute();
	Return QueryResult;

EndFunction

Procedure CreatePrintedFormStatement(DocumentData, CashAccountStatement, TemplateName, SpreadsheetDocument) Export
	
	SpreadsheetDocument.ReadOnly = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Portrait;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PrintParametersKey = "PRINT_OPTIONS_PayrollStatementHR_Print"+TemplateName;
	Template = PrintManagement.PrintFormTemplate(
	"Document.PayrollStatementHR."+TemplateName);
	
	AreaStructure = New Structure("Organization, Department, Currency");
	FillPropertyValues(AreaStructure, DocumentData);
	AreaStructure.Insert("RegistryNumber", ObjectsPrefixesClientServer.NumberForPrinting(DocumentData.Number));
	AreaStructure.Insert("Date", Format(DocumentData.Date, "DLF=D"));
	
	Area = Template.GetArea("DocumentHeader");
	FillPropertyValues(Area.Parameters, AreaStructure);
	SpreadsheetDocument.Put(Area);
	
	Area = Template.GetArea("Header");
	SpreadsheetDocument.Put(Area);
	
	Area = Template.GetArea("String");
	AreaStructure = New Structure("LineNumber, BankAccount, LASTFIRSTNAME");
	AreaStructure.Insert("EmployeeCode");
	AreaStructure.Insert("Sum");
	SelectionByLines = DocumentData.Select();
	LineCounter = 0;
	While SelectionByLines.Next() Do
		FillPropertyValues(AreaStructure, SelectionByLines);
		LineCounter = LineCounter + 1;
		AreaStructure.Insert("LineCounter", LineCounter);
		AreaStructure.Insert("Description", SelectionByLines.Description);
		FillPropertyValues(Area.Parameters, AreaStructure);
		SpreadsheetDocument.Put(Area);
	EndDo;
	
	Area = Template.GetArea("Footer");
	AreaStructure = New Structure("SumByDocument",DocumentData.SumByDocument);
	AreaStructure.Insert("DirectorJobTitle", DocumentData.JobTitleExecutive);
	AreaStructure.Insert("Director", PersonsTM.IndividualShortName(DocumentData.Director, DocumentData.Date));
	FillPropertyValues(Area.Parameters, AreaStructure);
	SpreadsheetDocument.Put(Area);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
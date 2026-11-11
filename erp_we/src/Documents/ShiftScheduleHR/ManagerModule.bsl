#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation
	
// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ForAllRows(ValueAllowed(DataOnTime.Employee.Individual, NULL AS TRUE))
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
//   Map - The data sources for register Register Records are
Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;
	Return DataSources;

EndFunction

// Generates the adapted Query Text for the Registered Records of the document "Shift schedule ZIK" according to the specified register.
//
// Parameters:
//   RegisterName - String - name of the register for which the request is generated
//
// Returns:
//   Structure - result of query adaptation with Query Text and parameter values
Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;

	FullDocumentName = "Document.ShiftScheduleHR";
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

// Fills in the request parameters for initializing the data of the document "Shift schedule ZIK".
//
// Parameters:
//   Query - Query - the request object that the parameters are set to
//   DocumentRef - DocumentRef.ShiftScheduleHR - link to the document for which the parameters are filled in
Procedure FillInInitializationParameters(Query, DocumentRef) Export

	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	Attributes.Ref AS Ref,
	|	Attributes.Posted AS Posted,
	|	Attributes.Date AS Date,
	|	Attributes.Number AS Number,
	|	ENDOFPERIOD(Attributes.BeginningDateOfPeriod, DAY) AS Period,
	|	Attributes.Organization AS Organization,
	|	Attributes.Department AS Department,
	|	Attributes.InputOption AS InputOption,
	|	Attributes.BeginningDateOfPeriod AS BeginningDateOfPeriod,
	|	Attributes.EndingDateOfPeriod AS EndingDateOfPeriod,
	|	Attributes.EmployeeResponsible AS EmployeeResponsible,
	|	Attributes.Approved_1 AS Approved_1,
	|	Attributes.Comment AS Comment,
	|	Attributes.DeletionMark AS DeletionMark
	|FROM
	|	Document.ShiftScheduleHR AS Attributes
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
		"DocumentRef.ShiftScheduleHR")));
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));

EndProcedure

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export

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
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export

	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;

	If TypeOf(Document) = Type("DocumentObject.ShiftScheduleHR") Then
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
	EndIf;
		
		////////////////////////////////////////////////////////////////////////////
		// We will get tables for movements

	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);

EndFunction

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID(
		"Document.ShiftScheduleHR"));

	If Attributes <> Undefined Then

		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(
			Attributes.Number));

	EndIf;

	Return ValuesOfHoldingParameters;

EndFunction
#EndRegion

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
	|	UNDEFINED							AS BusinessOperation,
	|	UNDEFINED							AS LineOfBusiness,
	|	&Department							AS Department,
	|	&EmployeeResponsible							AS EmployeeResponsible,
	|	&Comment                            AS Comment,
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
	|	UNDEFINED                            AS Priority";

	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;

EndFunction

#Region DocumentPrintingProcedures

// Adds print commands to the list of commands.
//
// Parameters:
//   PrintCommands - ValueTable - List of print Commands to which a new Command is added
Procedure AddPrintCommands(PrintCommands) Export

	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PF_MXL_ShiftScheduleHR";
	PrintCommand.Presentation = NStr("vi = 'In';
									|ru = 'Печать';
									|en = 'Print'; fa = 'چاپ';
									|it = 'Stampa';
									|pl = 'Print';
									|tr = 'Yazdır'");
	PrintCommand.CheckPostingBeforePrint = True;

EndProcedure

// Forms printed forms
	//
	// Parameters:
	//  (input)
	//    ObjectsArray  - Array of DocumentRef.ShiftScheduleHR    - references to objects that should be printed;
	//    PrintParameters - Structure - advanced print settings;
	//  (output)
	//   PrintFormsCollection - ValueTable - generated tabular documents.
	//   PrintObjects         - ValueList  - value - the object reference;
	//                                             view - name of the area where the object was displayed;
	//   OutputParameters       - Structure       - additional parameters of generated table documents.
	//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export

	If Not PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PF_MXL_ShiftScheduleHR") Then
		Return;
	EndIf;

	DataForPrint = GetQueryDataForPrintedGraphForms(ObjectsArray, PrintParameters);
	DataTree = DataForPrint.Unload(QueryResultIteration.ByGroups);
	For Each LinkString_ In DataTree.Rows Do
		SpreadsheetDocument = New SpreadsheetDocument;
		CreatePrintedFormOfGraph(LinkString_, SpreadsheetDocument);
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "PF_MXL_ShiftScheduleHR", NStr(
			"ru = 'Сменный график';
			|vi = 'Shift schedule';
			|en = 'Shift schedule'; fa = 'برنامه شیفت';
			|it = 'Shift schedule';
			|pl = 'Shift schedule';
			|tr = 'Vardiya takvimi'"), SpreadsheetDocument);
	EndDo;

EndProcedure

Function CreatePrintedFormOfGraph(DataOnTime, SpreadsheetDocument)

	SpreadsheetDocument.ReadOnly = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Landscape;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PrintParametersKey = "PRINTPARAMETERS_ShiftScheduleZIK_ShiftScheduleHRPrinting";
	Template = PrintManagement.PrintFormTemplate(
		"Document.ShiftScheduleHR.PF_MXL_ShiftScheduleHR");

	HeaderStructure_ = New Structure("Organization, Department");
	FillPropertyValues(HeaderStructure_, DataOnTime);
	HeaderStructure_.Insert("DocumentNumber", ObjectsPrefixesClientServer.NumberForPrinting(DataOnTime.Number));
	HeaderStructure_.Insert("DocumentDate", Format(DataOnTime.DocumentDate, "DLF=D"));

	HeaderStructure_.Insert("Approved_1", PersonsClientServer.InitialsAndLastName(DataOnTime.Approved_1));
	HeaderStructure_.Insert("ApprovedJobTitle", DataOnTime.ApprovedJobTitle);
	HeaderStructure_.Insert("PeriodAsString", StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'На период с %1 по %2';
			|vi = 'For period from %1 to %2';
			|en = 'For period from %1 to %2'; fa = 'For period from %1 to %2';
			|it = 'For period from %1 to %2';
			|pl = 'For period from %1 to %2';
			|tr = '%1 - %2dönemi için'"), Format(DataOnTime.BeginningDateOfPeriod, "DLF=D"), Format(
		DataOnTime.EndingDateOfPeriod, "DLF=D")));

	Area = Template.GetArea("Header");
	FillPropertyValues(Area.Parameters, HeaderStructure_);
	SpreadsheetDocument.Put(Area);

	TablePeriods = TimeTrackingServer.CreateSeparatePeriodTable(
		DataOnTime.BeginningDateOfPeriod, DataOnTime.EndingDateOfPeriod);

	HeaderStructure_.Insert("Period", EndOfDay(DataOnTime.EndingDateOfPeriod));
	HeaderStructure_.Insert("TablePeriods", TablePeriods);
	HeaderStructure_.Insert("ByDays", DataOnTime.ByDays);
	HeaderStructure_.Insert("IsReport", False);
	
	TimeTrackingServer.OutputShiftScheduleDataToTabularDocument(
		HeaderStructure_, DataOnTime, SpreadsheetDocument, Template);

	Return SpreadsheetDocument;

EndFunction

// Generates data for printed Forms of the shift schedule.
//
// Parameters:
//   ObjectsArray - Array of DocumentRef - links to documents Changeable Graphics
//   PrintParameters - Structure - print options
//
// Returns:
//   QueryResult - result of a request with data for printed Forms
Function GetQueryDataForPrintedGraphForms(ObjectsArray, PrintParameters) Export

	Query = New Query;
	Query.Text =
	"SELECT
	|	ShiftScheduleHR.Ref AS Ref,
	|	ShiftScheduleHR.Number AS Number,
	|	ShiftScheduleHR.Date AS Date,
	|	ShiftScheduleHR.Organization AS Organization,
	|	ShiftScheduleHR.EndingDateOfPeriod AS EndingDateOfPeriod,
	|	ShiftScheduleHR.BeginningDateOfPeriod AS BeginningDateOfPeriod,
	|	ShiftScheduleHR.Approved_1 AS Approved_1,
	|	ShiftScheduleHR.Department AS Department,
	|	ShiftScheduleHR.InputOption AS InputOption
	|INTO HeaderData_
	|FROM
	|	Document.ShiftScheduleHR AS ShiftScheduleHR
	|WHERE
	|	ShiftScheduleHR.Ref IN(&DocumentsArray)
	|	AND ShiftScheduleHR.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShiftScheduleHRDataOnTime.Ref AS Ref,
	|	ShiftScheduleHRDataOnTime.LineNumberEmployee AS LineNumberEmployee,
	|	ShiftScheduleHRDataOnTime.Employee AS Employee,
	|	ShiftScheduleHRDataOnTime.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	ShiftScheduleHRDataOnTime.Date AS Date
	|INTO TSData
	|FROM
	|	HeaderData_ AS HeaderData_
	|		INNER JOIN Document.ShiftScheduleHR.DataOnTime AS ShiftScheduleHRDataOnTime
	|		ON HeaderData_.Ref = ShiftScheduleHRDataOnTime.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	HeaderData_.Approved_1 AS Approved_1,
	|	MAX(EmploymentRecord.JobTitle) AS JobTitle
	|INTO HRData
	|FROM
	|	HeaderData_ AS HeaderData_
	|		INNER JOIN InformationRegister.EmploymentRecord AS EmploymentRecord
	|		ON HeaderData_.Organization = EmploymentRecord.Organization
	|			AND HeaderData_.Date >= EmploymentRecord.Period
	|			AND (EmploymentRecord.WorksInBusinessUnit)
	|			AND HeaderData_.Approved_1 = EmploymentRecord.Employee.Individual
	|
	|GROUP BY
	|	HeaderData_.Approved_1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HeaderData_.Ref AS Ref,
	|	HeaderData_.Number AS Number,
	|	HeaderData_.Date AS DocumentDate,
	|	HeaderData_.Organization AS Organization,
	|	HeaderData_.Department AS Department,
	|	HeaderData_.EndingDateOfPeriod AS EndingDateOfPeriod,
	|	HeaderData_.BeginningDateOfPeriod AS BeginningDateOfPeriod,
	|	HeaderData_.Approved_1 AS Approved_1,
	|	ISNULL(HRData.JobTitle, VALUE(Catalog.JobTitles.EmptyRef)) AS ApprovedJobTitle,
	|	TSData.LineNumberEmployee AS LineNumberEmployee,
	|	TSData.Employee AS Employee,
	|	TSData.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	TSData.Date AS Date,
	|	DATEDIFF(HeaderData_.BeginningDateOfPeriod, HeaderData_.EndingDateOfPeriod, DAY) AS NumberOfDays,
	|	CASE
	|		WHEN HeaderData_.InputOption = VALUE(Enum.OptionsForEnteringShiftSchedules.ByDays)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ByDays
	|FROM
	|	HeaderData_ AS HeaderData_
	|		INNER JOIN TSData AS TSData
	|		ON HeaderData_.Ref = TSData.Ref
	|		LEFT JOIN HRData AS HRData
	|		ON HeaderData_.Approved_1 = HRData.Approved_1
	|TOTALS
	|	MAX(Number),
	|	MAX(DocumentDate),
	|	MAX(Organization),
	|	MAX(Department),
	|	MAX(EndingDateOfPeriod),
	|	MIN(BeginningDateOfPeriod),
	|	MIN(Approved_1),
	|	MAX(ApprovedJobTitle),
	|	MAX(NumberOfDays),
	|	MAX(ByDays)
	|BY
	|	Ref";

	Query.SetParameter("Ref", ObjectsArray);

	Query.SetParameter("DocumentsArray", ObjectsArray);
	Return Query.Execute();

EndFunction

#EndRegion

#EndRegion

#EndIf
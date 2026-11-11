#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Fills in the access restriction
//
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
// Map - The data sources for register Register Records are
Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;
	Return DataSources;

EndFunction

// Generates the adapted Query Text for the Registered Records of the document "HR Time Table" according to the specified register.
//
// Parameters:
//   RegisterName - String - name of the register for which the request is generated
//
// Returns:
// QueryResult - result of query adaptation with Query Text and parameter values
Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;

	FullDocumentName = "Document.TimesheetHR";
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
			|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
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
	|	Attributes.BeginningDateOfPeriod AS BeginningDateOfPeriod,
	|	Attributes.EndingDateOfPeriod AS EndingDateOfPeriod,
	|	Attributes.InputOption AS InputOption,
	|	Attributes.EmployeeResponsible AS EmployeeResponsible,
	|	Attributes.Approved_1 AS Approved_1,
	|	Attributes.Comment AS Comment,
	|	Attributes.DeletionMark AS DeletionMark
	|FROM
	|	Document.TimesheetHR AS Attributes
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
		"DocumentRef.TimesheetHR")));
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));

EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID(
		"Document.TimesheetHR"));

	If Attributes <> Undefined Then

		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(
			Attributes.Number));

	EndIf;

	Return ValuesOfHoldingParameters;

EndFunction

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
	//
	// Parameters:
	//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
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

	If TypeOf(Document) = Type("DocumentObject.TimesheetHR") Then
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

		QueryTextDataOnTime(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	EndIf;
		
		////////////////////////////////////////////////////////////////////////////
		// We will get tables for movements

	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);

EndFunction

Function QueryTextDataOnTime(Query, QueryTexts, Registers)

	RegisterName = "DataOnEmployeeTimesheet";

	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	QueryText =
	"SELECT
	|	ReportCard_TimeData.Date AS Period,
	|	ReportCard_TimeData.Ref.Organization AS Organization,
	|	ReportCard_TimeData.Employee AS Employee,
	|	ReportCard_TimeData.TimeKind AS TimeKind,
	|	ReportCard_TimeData.Days AS Days,
	|	ReportCard_TimeData.Hours1 AS Hours1
	|FROM
	|	Document.TimesheetHR.DataOnTime AS ReportCard_TimeData
	|WHERE
	|	ReportCard_TimeData.Ref = &Ref
	|	AND NOT (ReportCard_TimeData.Hours1 = 0
	|	AND ReportCard_TimeData.Days = 0)";

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

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PF_MXL_Timesheet";
	PrintCommand.Presentation = NStr("ru = 'Табель';
									|vi = 'Timesheet';
									|en = 'Timesheet'; fa = 'کارکرد';
									|it = 'Timesheet';
									|pl = 'Timesheet';
									|tr = 'Puantaj'");
	PrintCommand.CheckPostingBeforePrint = True;

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export

	If Not PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PF_MXL_Timesheet") Then
		Return;
	EndIf;

	DataForPrint = GenerateRequestForPrinting(ObjectsArray);
	If DataForPrint.IsEmpty() Then
		Return;
	EndIf;
	DataTree = DataForPrint.Unload(QueryResultIteration.ByGroups);

	For Each LinkString_ In DataTree.Rows Do
		SpreadsheetDocument = New SpreadsheetDocument;
		If LinkString_.InputOption = Enums.TimesheetInputOptions.ByDays Then
			CreatePrintedFormOfReportCardByDay(LinkString_, SpreadsheetDocument);
		Else
			ToFormPrintedFormOfReportCardInSummary(LinkString_, SpreadsheetDocument);
		EndIf;
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "PF_MXL_Timesheet",
			"TimeCard", SpreadsheetDocument);
	EndDo;

EndProcedure

Function GenerateRequestForPrinting(ObjectsArray)

	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	ReportCard_TimeData.Ref AS Ref,
	|	ReportCard_TimeData.Ref.Organization AS Organization,
	|	ReportCard_TimeData.LineNumberEmployee AS LineNumberEmployee,
	|	ReportCard_TimeData.Employee AS Employee,
	|	ReportCard_TimeData.TimeKind AS TimeKind,
	|	ReportCard_TimeData.Date AS Date,
	|	ReportCard_TimeData.Hours1 AS Hours1,
	|	ReportCard_TimeData.Days AS Days,
	|	ReportCard_TimeData.Ref.BeginningDateOfPeriod AS BeginningDateOfPeriod,
	|	ReportCard_TimeData.Ref.EndingDateOfPeriod AS EndingDateOfPeriod,
	|	ReportCard_TimeData.Employee.Individual AS Individual
	|INTO DataOnTime
	|FROM
	|	Document.TimesheetHR.DataOnTime AS ReportCard_TimeData
	|WHERE
	|	ReportCard_TimeData.Ref IN (&ObjectsArray)
	|	AND ReportCard_TimeData.Ref.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DataOnTime.Employee AS Employee,
	|	DataOnTime.Organization AS Organization,
	|	DataOnTime.BeginningDateOfPeriod AS BeginningDateOfPeriod,
	|	DataOnTime.EndingDateOfPeriod AS EndingDateOfPeriod,
	|	DataOnTime.Ref AS Ref
	|INTO TimeDataIsGrouped
	|FROM
	|	DataOnTime AS DataOnTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TimesheetHR.Ref AS Ref,
	|	TimesheetHR.Date AS Date,
	|	TimesheetHR.Number AS Number,
	|	TimesheetHR.Organization AS Organization,
	|	TimesheetHR.Department AS Department,
	|	TimesheetHR.BeginningDateOfPeriod AS BeginningDateOfPeriod,
	|	TimesheetHR.EndingDateOfPeriod AS EndingDateOfPeriod,
	|	TimesheetHR.InputOption AS InputOption,
	|	TimesheetHR.Approved_1 AS Approved_1
	|INTO Header
	|FROM
	|	Document.TimesheetHR AS TimesheetHR
	|WHERE
	|	TimesheetHR.Ref IN (&ObjectsArray)
	|	AND TimesheetHR.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(EmploymentRecord.Period) AS Period,
	|	TimeDataIsGrouped.Ref AS Ref,
	|	EmploymentRecord.Employee AS Employee,
	|	EmploymentRecord.Organization AS Organization
	|INTO MaximumFromPersonnelHistory
	|FROM
	|	TimeDataIsGrouped AS TimeDataIsGrouped
	|		INNER JOIN InformationRegister.EmploymentRecord AS EmploymentRecord
	|		ON TimeDataIsGrouped.Organization = EmploymentRecord.Organization
	|		AND TimeDataIsGrouped.Employee = EmploymentRecord.Employee
	|		AND TimeDataIsGrouped.EndingDateOfPeriod >= EmploymentRecord.Period
	|WHERE
	|	EmploymentRecord.WorksInBusinessUnit
	|GROUP BY
	|	EmploymentRecord.Employee,
	|	EmploymentRecord.Organization,
	|	TimeDataIsGrouped.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	EmploymentRecord.Period,
	|	Header.Ref,
	|	EmploymentRecord.Employee,
	|	Header.Organization
	|FROM
	|	Header AS Header
	|		INNER JOIN InformationRegister.EmploymentRecord AS EmploymentRecord
	|		ON Header.Organization = EmploymentRecord.Organization
	|		AND Header.Approved_1 = EmploymentRecord.Employee.Individual
	|		AND Header.Date >= EmploymentRecord.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MaximumFromPersonnelHistory.Ref AS Ref,
	|	MaximumFromPersonnelHistory.Employee AS Employee,
	|	MaximumFromPersonnelHistory.Organization AS Organization,
	|	MaximumFromPersonnelHistory.Period AS Period,
	|	EmploymentRecord.JobTitle AS JobTitle,
	|	EmploymentRecord.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	MaximumFromPersonnelHistory.Employee.Individual AS Individual
	|INTO PersonnelData
	|FROM
	|	MaximumFromPersonnelHistory AS MaximumFromPersonnelHistory
	|		INNER JOIN InformationRegister.EmploymentRecord AS EmploymentRecord
	|		ON MaximumFromPersonnelHistory.Period = EmploymentRecord.Period
	|		AND MaximumFromPersonnelHistory.Organization = EmploymentRecord.Organization
	|		AND MaximumFromPersonnelHistory.Employee = EmploymentRecord.Employee
	|WHERE
	|	EmploymentRecord.WorksInBusinessUnit
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Header.Ref AS Ref,
	|	Header.Date AS DocumentDate,
	|	Header.Number AS Number,
	|	Header.Organization AS Organization,
	|	Header.Department AS Department,
	|	Header.BeginningDateOfPeriod AS BeginningDateOfPeriod,
	|	Header.EndingDateOfPeriod AS EndingDateOfPeriod,
	|	Header.InputOption AS InputOption,
	|	Header.Approved_1 AS Approved_1,
	|	PersonnelDataCaps.JobTitle.Presentation AS ApprovedJobTitle,
	|	DataOnTime.Employee AS Employee,
	|	DataOnTime.LineNumberEmployee AS LineNumberEmployee,
	|	DataOnTime.TimeKind AS TimeKind,
	|	DataOnTime.Date AS Date,
	|	CASE
	|		WHEN DataOnTime.TimeKind.UnitOfMeasure = VALUE(Enum.TimeMeasureUnits.HOUR)
	|			THEN DataOnTime.Hours1
	|		ELSE DataOnTime.Days * DataOnTime.TimeKind.NumberOfHoursPerDay
	|	END AS Hours1,
	|	DataOnTime.Days AS Days,
	|	PersonnelDataTS.Employee.Code AS EmployeeCode,
	|	ISNULL(PersonnelDataTS.JobTitle, VALUE(Catalog.JobTitles.EmptyRef)) AS JobTitle,
	|	ISNULL(PersonnelDataTS.JobTitle.Presentation, """") AS JobTitlePresentation,
	|	CASE
	|		WHEN DataOnTime.TimeKind.LetterCode = """"
	|			THEN ""?""
	|		ELSE DataOnTime.TimeKind.LetterCode
	|	END AS LetterCode,
	|	DataOnTime.TimeKind.Numeric_Code AS Numeric_Code,
	|	DataOnTime.TimeKind.UnitOfMeasure AS UnitOfMeasure,
	|	DataOnTime.TimeKind.NumberOfHoursPerDay AS NumberOfHoursPerDay,
	|	DataOnTime.TimeKind.WorkingTime AS WorkingTime,
	|	DataOnTime.Individual AS Individual,
	|	DataOnTime.Individual.Description AS IndividualName,
	|	CASE
	|		WHEN FullNameOfPersonsSliceLast.LastName IS NULL
	|			THEN """"
	|		ELSE """" + FullNameOfPersonsSliceLast.LastName + CASE
	|			WHEN FullNameOfPersonsSliceLast.Initials = """"
	|				THEN """"
	|			ELSE "" "" + FullNameOfPersonsSliceLast.Initials
	|		END
	|	END AS LastFirstName
	|FROM
	|	Header AS Header
	|		INNER JOIN DataOnTime AS DataOnTime
	|			LEFT JOIN PersonnelData AS PersonnelDataTS
	|			ON DataOnTime.Ref = PersonnelDataTS.Ref
	|			AND DataOnTime.Organization = PersonnelDataTS.Organization
	|			AND DataOnTime.Employee = PersonnelDataTS.Employee
	|			LEFT JOIN InformationRegister.FullNameOfPersons.SliceLast AS FullNameOfPersonsSliceLast
	|			ON DataOnTime.Individual = FullNameOfPersonsSliceLast.Individual
	|		ON Header.Ref = DataOnTime.Ref
	|		LEFT JOIN PersonnelData AS PersonnelDataCaps
	|		ON Header.Ref = PersonnelDataCaps.Ref
	|		AND Header.Organization = PersonnelDataCaps.Organization
	|		AND Header.Approved_1 = PersonnelDataCaps.Individual
	|
	|ORDER BY
	|	Ref,
	|	LineNumberEmployee,
	|	DocumentDate
	|TOTALS
	|	MAX(DocumentDate),
	|	MAX(Number),
	|	MAX(Organization),
	|	MAX(Department),
	|	MAX(BeginningDateOfPeriod),
	|	MAX(EndingDateOfPeriod),
	|	MAX(InputOption),
	|	MAX(Approved_1),
	|	MAX(ApprovedJobTitle),
	|	MAX(LineNumberEmployee),
	|	MAX(Date),
	|	SUM(Hours1),
	|	SUM(Days),
	|	MAX(EmployeeCode),
	|	MAX(JobTitle),
	|	MAX(IndividualName),
	|	MAX(LastFirstName)
	|BY
	|	Ref,
	|	Employee";

	Query.SetParameter("ObjectsArray", ObjectsArray);
	QueryResult = Query.Execute();
	Return QueryResult;

EndFunction

// Generates a printed Form of a time table by day.
//
// Parameters:
//   DataOnTime - Structure - data for the formation of a printed Form
//   SpreadsheetDocument - SpreadsheetDocument - the document in which the printed Form will be displayed
//
// Returns:
//   SpreadsheetDocument - generated printed report card Form
Function CreatePrintedFormOfReportCardByDay(DataOnTime, SpreadsheetDocument) Export

	SpreadsheetDocument.ReadOnly = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Landscape;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PrintParametersKey = "PRINTPARAMETERS_Timesheet_TimesheetByDay";
	Template = PrintManagement.PrintFormTemplate(
		"Document.TimesheetHR.TimesheetByDay");

	HeaderStructure_ = New Structure("Organization, Department");
	FillPropertyValues(HeaderStructure_, DataOnTime);
	HeaderStructure_.Insert("DocumentNumber", ObjectsPrefixesClientServer.NumberForPrinting(DataOnTime.Number));
	HeaderStructure_.Insert("DocumentDate", Format(DataOnTime.DocumentDate, "DLF=D"));
	HeaderStructure_.Insert("BeginOfPeriod", Format(DataOnTime.BeginningDateOfPeriod, "DLF=D"));
	HeaderStructure_.Insert("PeriodEnding", Format(DataOnTime.EndingDateOfPeriod, "DLF=D"));

	Area = Template.GetArea("Header");
	FillPropertyValues(Area.Parameters, HeaderStructure_);
	SpreadsheetDocument.Put(Area);

	TablePeriods = TimeTrackingServer.CreateSeparatePeriodTable(DataOnTime.BeginningDateOfPeriod,
		DataOnTime.EndingDateOfPeriod);

	TimeTrackingServer.OutputTimesheetDataToTabularDocument(TablePeriods, DataOnTime,
		SpreadsheetDocument, Template);

	Area = Template.GetArea("Footer");
	Area.Parameters.ApprovedJobTitle = DataOnTime.ApprovedJobTitle;
	Area.Parameters.Approved_1 = PersonsClientServer.InitialsAndLastName(DataOnTime.Approved_1);
	SpreadsheetDocument.Put(Area);

	Return SpreadsheetDocument;

EndFunction

// Generates a printed Form of a summary time table.
//
// Parameters:
//   DataOnTime - Structure - data for the formation of a printed Form
//   SpreadsheetDocument - SpreadsheetDocument - the document in which the printed Form will be displayed
//
// Returns:
//   SpreadsheetDocument - generated printed Form
// Generates a printed Form of a summary time table.
//
Function ToFormPrintedFormOfReportCardInSummary(DataOnTime, SpreadsheetDocument) Export

	SpreadsheetDocument.ReadOnly = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Landscape;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PrintParametersKey = "PRINTPARAMETERS_Timesheet_Timesheet_SummaryTimesheetPrinting";
	Template = PrintManagement.PrintFormTemplate(
		"Document.TimesheetHR.TimesheetSummary");

	HeaderStructure_ = New Structure("Organization, Department");
	FillPropertyValues(HeaderStructure_, DataOnTime);
	HeaderStructure_.Insert("DocumentNumber", ObjectsPrefixesClientServer.NumberForPrinting(DataOnTime.Number));
	HeaderStructure_.Insert("DocumentDate", Format(DataOnTime.DocumentDate, "DLF=D"));
	HeaderStructure_.Insert("BeginOfPeriod", Format(DataOnTime.BeginningDateOfPeriod, "DLF=D"));
	HeaderStructure_.Insert("PeriodEnding", Format(DataOnTime.EndingDateOfPeriod, "DLF=D"));

	Area = Template.GetArea("Header");
	FillPropertyValues(Area.Parameters, HeaderStructure_);
	SpreadsheetDocument.Put(Area);

	Area = Template.GetArea("TableHeader");
	SpreadsheetDocument.Put(Area);

	Area = Template.GetArea("TableRow");
	FixedStringStructure = New FixedStructure("LineNumber, EmployeeJobTitle, EmployeeCode, BottomLineDays, BottomLineHours",
		1, , "", "", "");
	LineNumber = 0;
	For Each DataByEmployee In DataOnTime.Rows Do
		LineNumber = LineNumber + 1;
		StringStructure = New Structure(FixedStringStructure);
		StringStructure.LineNumber = LineNumber;
		If ValueIsFilled(DataByEmployee.LastFirstName) Then
			StringStructure.EmployeeJobTitle = DataByEmployee.LastFirstName + " (" + DataByEmployee.JobTitle + ")";
		Else
			StringStructure.EmployeeJobTitle = PersonsClientServer.InitialsAndLastName(
				DataByEmployee.IndividualName) + " (" + DataByEmployee.JobTitle + ")";
		EndIf;

		StringStructure.EmployeeCode = DataByEmployee.EmployeeCode;
		OutputTextHours = "";
		OutputTextDays 	= "";
		For Each TimeTypeData In DataByEmployee.Rows Do
			If ValueIsFilled(TimeTypeData.Hours1) Then
				OutputTextHours = OutputTextHours + ?(OutputTextHours = "", "", "/");
				OutputTextHours = OutputTextHours + TimeTypeData.LetterCode + TimeTypeData.Hours1;
			EndIf;
			If ValueIsFilled(TimeTypeData.Days) Then
				OutputTextDays = OutputTextDays + ?(OutputTextDays = "", "", "/");
				OutputTextDays = OutputTextDays + TimeTypeData.LetterCode + TimeTypeData.Days;
			EndIf;
		EndDo;
		StringStructure.BottomLineHours = OutputTextHours;
		StringStructure.BottomLineDays	 = OutputTextDays;
		FillPropertyValues(Area.Parameters, StringStructure);
		SpreadsheetDocument.Put(Area);
	EndDo;

	Area = Template.GetArea("Footer");
	Area.Parameters.ApprovedJobTitle = DataOnTime.ApprovedJobTitle;
	Area.Parameters.Approved_1 = PersonsClientServer.InitialsAndLastName(DataOnTime.Approved_1);
	SpreadsheetDocument.Put(Area);

	Return SpreadsheetDocument;

EndFunction

#EndRegion

#EndRegion

#EndIf
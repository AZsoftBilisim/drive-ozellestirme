
#Region Public

// Returns a list of employees who were registered with the organization during the specified period.
//
// Parameters:
//   FilterStructure1 - Structure - contains selection parameters. Description:
//     Period start - Date - The beginning of the period
//     End of period - Date - end of period
//     Company - Directory link.Companies - company
//     Business unit - Directory Link.The structure of the enterprise is a subdivision.
//
// Returns:
//   ValueTable - list of working employees - Description:
//   * Employee - CatalogRef.EmployeesHR - An employee working in a given period
Function GetWorkingEmployees(FilterStructure1) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED DISTINCT
	|	PersonnelHistory_Accepted.Employee AS Employee
	|INTO AllReceived
	|FROM
	|	InformationRegister.EmploymentRecord.SliceLast(
	|			&PeriodEnding,
	|			Organization = &Organization
	|				AND CASE
	|					WHEN &Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|						THEN TRUE
	|					ELSE Department = &Department
	|				END
	|				AND CASE
	|					WHEN &Employee = VALUE(Catalog.EmployeesHR.EmptyRef)
	|						THEN TRUE
	|					ELSE Employee IN (&Employee)
	|				END
	|				AND NOT EventKind = VALUE(Enum.HREventKindsPayrollAndHumanResources.Dismissal)) AS PersonnelHistory_Accepted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	PersonnelHistory_Dismissed.Employee AS Employee
	|INTO AllFired
	|FROM
	|	InformationRegister.EmploymentRecord.SliceLast(
	|			&PeriodEnding,
	|			Period <= &BeginOfPeriod
	|				AND Organization = &Organization
	|				AND CASE
	|					WHEN &Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|						THEN TRUE
	|					ELSE Department = &Department
	|				END
	|				AND EventKind = VALUE(Enum.HREventKindsPayrollAndHumanResources.Dismissal)
	|				AND Employee IN
	|					(SELECT DISTINCT
	|						AllReceived.Employee
	|					FROM
	|						AllReceived)) AS PersonnelHistory_Dismissed
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllReceived.Employee AS Employee
	|FROM
	|	AllReceived AS AllReceived
	|		LEFT JOIN AllFired AS AllFired
	|		ON AllReceived.Employee = AllFired.Employee
	|WHERE
	|	AllFired.Employee IS NULL";
	
	QueryOptions = Query.FindParameters();
	For Each Parameter In QueryOptions Do
		Query.SetParameter(Parameter.Name, FilterStructure1[Parameter.Name])
	EndDo;
	QueryResult = Query.Execute();
	Return QueryResult.Unload();
	
EndFunction

// Processes the selection of employees for Forms containing the "Schedule to Dates" table.
//
// Parameters:
//   Form - ClientApplicationForm - A Form containing a schedule by date
//   ListOfEmployees - Array of CatalogRef.EmployeesHR - List of employees to process
Procedure ScheduleByDateSelectionProcessing(Form, ListOfEmployees) Export
	
	UploadingSchedule = Form.ScheduleByDate.Unload(,"LineNumber, Employee");
	LineNumber = MaximumLineNumber(UploadingSchedule);
	NumberOfMeasurements = Form.NumberOfMeasurements;
	SelectedMeasurements  = Form.SelectedMeasurements;
	For Each Employee In ListOfEmployees Do
		If UploadingSchedule.Find(Employee, "Employee") = Undefined Then
			NewRow = Form.ScheduleByDate.Add();
			NewRow.Employee = Employee;
			LineNumber = LineNumber + 1;
			NewRow.LineNumber = LineNumber;
			If StrFind(Form.FormName, "TimesheetHR") > 0 Then
				For DimensionsCounter = 1 To NumberOfMeasurements Do
					NewRow["Dimension" + DimensionsCounter] = SelectedMeasurements[DimensionsCounter - 1].Value;
				EndDo;
			EndIf;
			Form.Modified = True;
		EndIf;
	EndDo;
	
EndProcedure

#Region Timekeeping

// Fills in the list of selected measurements based on time data.
// Parameters:
//  DataOnTime       - FormDataCollection - Data containing time information.
//  SelectedMeasurements  - ValueList of Arbitrary  - A list to fill with the selected measurements.
//  FieldName             - String              - The name of the field for which dimensions are selected.
Procedure FillInSelectedDimensions(DataOnTime, SelectedMeasurements, FieldName) Export
	
	Query = New Query;
	QueryText = 
	"SELECT DISTINCT
	|	DataOnTime.TimeKind AS Dimension
	|INTO Dimensions
	|FROM
	|	&DataOnTime AS DataOnTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Dimensions.Dimension AS Dimension
	|FROM
	|	Dimensions AS Dimensions
	|
	|ORDER BY
	|	Dimensions.Dimension";
	Query.Text = StrReplace(QueryText, "TimeKind", FieldName);
	Query.SetParameter("DataOnTime", DataOnTime.Unload(,FieldName));
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If ValueIsFilled(Selection.Dimension) Then
			SelectedMeasurements.Add(Selection.Dimension);
		EndIf;
	EndDo;
	
EndProcedure

// Checks the intersection of object data with other documents.
//
// Parameters:
//   ObjectData - Structure - Contains object data for checking the intersection.
//
// Returns:
//   Boolean - True if an intersection is detected, otherwise False.
Function CheckIntersectionWithOtherDocuments(ObjectData) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	EmployeesHR.Employee AS Employee,
	|	EmployeesHR.Date AS Date
	|INTO DataOnTime
	|FROM
	|	&EmployeeTable AS EmployeesHR
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataOnTime.Employee AS Employee,
	|	MIN(DataOnTime.Date) AS DateMin,
	|	MAX(DataOnTime.Date) AS DateMax
	|INTO TimeDataMinMax
	|FROM
	|	DataOnTime AS DataOnTime
	|
	|GROUP BY
	|	DataOnTime.Employee
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DocumentHeader.Ref AS Ref
	|INTO DocumentsInPeriod
	|FROM
	|	Document.ShiftScheduleHR AS DocumentHeader
	|WHERE
	|	DocumentHeader.Posted
	|	AND NOT DocumentHeader.Ref = &Ref
	|	AND DocumentHeader.Organization = &Organization
	|	AND (&BeginningDateOfPeriod BETWEEN DocumentHeader.BeginningDateOfPeriod AND DocumentHeader.EndingDateOfPeriod
	|			OR &EndingDateOfPeriod BETWEEN DocumentHeader.BeginningDateOfPeriod AND DocumentHeader.EndingDateOfPeriod)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DocumentDataOnTime.Ref.Presentation AS Document,
	|	DocumentDataOnTime.Employee.Presentation AS Employee
	|FROM
	|	DocumentsInPeriod AS DocumentsInPeriod
	|		INNER JOIN Document.ShiftScheduleHR.DataOnTime AS DocumentDataOnTime
	|			INNER JOIN TimeDataMinMax AS TimeDataMinMax
	|			ON DocumentDataOnTime.Employee = TimeDataMinMax.Employee
	|				AND DocumentDataOnTime.Date >= TimeDataMinMax.DateMin
	|				AND DocumentDataOnTime.Date <= TimeDataMinMax.DateMax
	|		ON DocumentsInPeriod.Ref = DocumentDataOnTime.Ref
	|
	|GROUP BY
	|	DocumentDataOnTime.Employee.Presentation,
	|	DocumentDataOnTime.Ref.Presentation";
	
	Query.Text = StrReplace(Query.Text, "ShiftScheduleHR", ObjectData.ObjectName);
	QueryOptions = Query.FindParameters();
	For Each Parameter In QueryOptions Do
		Query.SetParameter(Parameter.Name, ObjectData[Parameter.Name])
	EndDo;
	
	Try
		QueryResult = Query.Execute();
	Except
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Ошибка при выполнении запроса: %1';
			|vi = 'Request error: %1';
			|en = 'Request error: %1'; fa = 'Request error: %1';
			|it = 'Request error: %1';
			|pl = 'Request error: %1';
			|tr = 'Sorgu yürütülürken hata oluştu: %1'"), ErrorDescription());
		Raise MessageText;
	EndTry;
	
	If QueryResult.IsEmpty() Then
		Return False;
	EndIf;
	
	Selection = QueryResult.Select();
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
	NStr("ru = 'По следующим сотрудникам уже есть проведенный документ на совпадающие даты:';
		|vi = 'For the following employees, there is already a posted document for matching dates:';
		|en = 'For the following employees, there is already a posted document for matching dates:'; fa = 'For the following employees, there is already a posted document for matching dates:';
		|it = 'For the following employees, there is already a posted document for matching dates:';
		|pl = 'For the following employees, there is already a posted document for matching dates:';
		|tr = 'Aşağıdaki çalışanlar için çakışan tarihlerde kaydedilmiş belge mevcut:'"), ObjectData.ObjectPresentation);
	Common.MessageToUser(MessageText);
	While Selection.Next() Do
		Common.MessageToUser(Selection.Employee+" ("+Selection.Document+")");
	EndDo;
	
	Return True;
	
EndFunction

#Region CrossTableProcedures

// Handles period changes on the Form
//
// Parameters:
//  Form   - ClientApplicationForm - The Form on which the period values are located.
//
Procedure WhenChangingPeriodsOnServer(Form) Export

	AttributeName = "TimeIntervals";
	TablePeriods = Form.FormAttributeToValue(AttributeName, Type("ValueTable"));
	FillInPeriodTable(TablePeriods, Form.Object.BeginningDateOfPeriod,
		Form.Object.EndingDateOfPeriod);
	UpdateCrossTableStructure(Form, TablePeriods);

EndProcedure

// Creates a table of periods on the Form.
//
// Parameters:
//   Form - ClientApplicationForm - The Form on which the period table is created
//   PeriodTableName - String - the name of the period table that will be created on the Form
Procedure CreatePeriodTable(Form, Val PeriodTableName) Export 
	
	TopLevelDetails = Form.GetAttributes();
	
	DescriptionOfVTTypes = New TypeDescription("ValueTable");
	TypesDetailsNumber = Common.TypeDescriptionNumber(10, 0);
	TypesDetailsString = New TypeDescription("String");
	TypesDetailsDate = Common.DateTypeDetails(DateFractions.Date);
	
	// Creating table details
	AttributesToBeAdded = New Array();
	PropsExist = False;
	For Each Attribute In TopLevelDetails Do		
		If Attribute.Name = PeriodTableName Then
			PropsExist = True;
			Break;
		EndIf;
	EndDo;
	If Not PropsExist Then
		Attribute = New FormAttribute(PeriodTableName, DescriptionOfVTTypes);
		AttributesToBeAdded.Add(Attribute);
		
		Attribute = New FormAttribute("ColumnNumber", TypesDetailsNumber, PeriodTableName);
		AttributesToBeAdded.Add(Attribute);
		
		Attribute = New FormAttribute("ColumnName", TypesDetailsString, PeriodTableName);
		AttributesToBeAdded.Add(Attribute);
		
		Attribute = New FormAttribute("Date", TypesDetailsDate, PeriodTableName);
		AttributesToBeAdded.Add(Attribute);
		
		Attribute = New FormAttribute("DateAsString", TypesDetailsString, PeriodTableName);
		AttributesToBeAdded.Add(Attribute);
		
		Attribute = New FormAttribute("DateDayOfWeekString", TypesDetailsString, PeriodTableName);
		AttributesToBeAdded.Add(Attribute);
	EndIf;
	
	If AttributesToBeAdded.Count() > 0 Then
		Form.ChangeAttributes(AttributesToBeAdded);
	EndIf;
	
EndProcedure

// The procedure fills in a table of periods, sequentially by dates with a periodicity of a day, to obtain fields and their headers.
//
// Parameters:
//  TablePeriods - ValueTable - See CreatePeriodTable
//  StartDate     - Date - start date of the period
//  EndDate  - Date - Period end date
Procedure FillInPeriodTable(TablePeriods, Val StartDate, Val EndDate) Export 
	
	For Each PeriodString_ In TablePeriods Do
		PeriodString_.ColumnNumber = -1;
	EndDo;
	
	If Not ValueIsFilled(StartDate) Or Not ValueIsFilled(EndDate) Then		
		Return;
	EndIf;
	
	AddingDate = StartDate;
	CurrentPeriod = 1;
	
	While AddingDate <= EndDate Do
		FoundRows = TablePeriods.FindRows(New Structure("Date", AddingDate));
		If FoundRows.Count() = 0 Then
			NewRow = TablePeriods.Add();
			NewRow.ColumnName = DateToString(AddingDate);
		Else
			NewRow = FoundRows[0];
		EndIf;
		NewRow.ColumnNumber = CurrentPeriod;
		CurrentPeriod = CurrentPeriod + 1;
		NewRow.Date = AddingDate;
		NewRow.DateAsString				= Format(AddingDate, NStr("ru = 'ДФ=''дд.ММ''';
																	|vi = 'DF=''MM/dd''';
																	|en = 'DF=''MM/dd'''; fa = 'DF=''MM/dd''';
																	|it = 'DF=''MM/dd''';
																	|pl = 'DF=''MM/dd''';
																	|tr = 'DF=''gg.AA'''"));
		NewRow.DateDayOfWeekString	= Format(AddingDate, NStr("ru = 'ДФ=''дд.ММ''';
																|vi = 'DF=''MM/dd''';
																|en = 'DF=''MM/dd'''; fa = 'DF=''MM/dd''';
																|it = 'DF=''MM/dd''';
																|pl = 'DF=''MM/dd''';
																|tr = 'DF=''gg.AA'''"))
			+" ("+Format(AddingDate, NStr("ru = 'ДФ=''ддд''';
											|vi = 'DF=''ddd''';
											|en = 'DF=''ddd'''; fa = 'DF=''ddd''';
											|it = 'DF=''ddd''';
											|pl = 'DF=''ddd''';
											|tr = 'DF=''ggg'''"))+".)";
		AddingDate = EndOfDay(AddingDate) + 1;
	EndDo;
	
	LinesToDelete = TablePeriods.FindRows(New Structure("ColumnNumber",-1));
	For Each RowToDelete In LinesToDelete Do
		TablePeriods.Delete(RowToDelete);
	EndDo;
	
	TablePeriods.Sort("Date");
	
EndProcedure

// Updates the structure of the cross-table in Form.
//
// Parameters:
//  Form         - ClientApplicationForm - The Form in which the cross-table structure needs to be updated.
//  TablePeriods - ValueTable - A table with periods.
Procedure UpdateCrossTableStructure(Form, TablePeriods) Export
	
	If Form = Undefined Or TablePeriods = Undefined Then
		Raise NStr("ru = 'Не указаны необходимые параметры';
					|vi = 'Required parameters are not specified';
					|en = 'Required parameters are not specified'; fa = 'Required parameters are not specified';
					|it = 'Required parameters are not specified';
					|pl = 'Required parameters are not specified';
					|tr = 'Gerekli parametreler belirtilmemiş'");
	EndIf;
	
	OutputParameters = New Structure;
	AddDefaultSettings(OutputParameters, Form, TablePeriods);
	AddOutputParametersForDocuments(OutputParameters, Form);
	AddDimensionsToOutputParameters(OutputParameters);
	UpdateCrosstabOutputStructure(Form, OutputParameters);
	
	Form.ValueToFormAttribute(TablePeriods, "TimeIntervals");
	
EndProcedure

// Copies data from a cross-table to an object.
// Parameters:
//   Object - DocumentObject - the object to which the data is copied
//   Form - ClientApplicationForm - The Form from which the data is taken for copying
Procedure CopyFromCrossTable(Object, Form) Export
	
	ConversionParameters = CrossTableConversionParameters(Form);
	If TypeOf(Object) = Type("DocumentObject.TimesheetHR") Then
		ConversionParameters.Insert("Employee", Form.Employee);
		If Form.OneEmployeeHasBeenSelected Then 
			FillInTableFromCrossTable_ReportCardOneEmployeeByDay(Object.DataOnTime, Form.ScheduleByDate, 
			ConversionParameters);
		Else
			FillInTableFromCrossTable_ReportCard(Object.DataOnTime, Form.ScheduleByDate, 
			ConversionParameters);
		EndIf;
	Else
		FillInTableFromCrossTable_ShiftSchedule(Object.DataOnTime, Form.ScheduleByDate, 
		ConversionParameters);
	EndIf;
	
EndProcedure

// Copies object data to the Form cross-table.
//
// Parameters:
//   Object - DocumentObject - an object containing a time data table whose data is copied to a cross-table
//   Form - ClientApplicationForm - Form containing a cross-table of timesheets for candidates to fill out
Procedure CopyToCrossTable(Object, Form) Export
	
	If Form.SelectedMeasurements.Count()=0 Then
		Return;
	EndIf;
	
	ConversionParameters = CrossTableConversionParameters(Form);
	
	LinesWithoutDate = Object.DataOnTime.FindRows(New Structure("Date", Date(1,1,1)));
	For Each TSRow In LinesWithoutDate Do
		TSRow.Date = Object.BeginningDateOfPeriod;
	EndDo;
	
	TopLevelDetails = Form.GetAttributes();
	For Each Attribute In TopLevelDetails Do
		If StrFind(Attribute.Name, "Total")>0 Then
			Form[Attribute.Name] = 0;
		EndIf;
	EndDo;
	CrossTable = Form.ScheduleByDate;
	ConversionParameters.Insert("ByDays", 				Form.ByDays);
	ConversionParameters.Insert("NumberOfMeasurements", Form.NumberOfMeasurements);
	ConversionParameters.Insert("Organization", 		Object.Organization);
	ConversionParameters.Insert("Period", 				Object.EndingDateOfPeriod);
	If TypeOf(Object.Ref) = Type("DocumentRef.TimesheetHR") Then  
		If Form.OneEmployeeHasBeenSelected Then  
			ConversionParameters.Insert("Employee", 	Form.Employee);
			FillInCrossTableFromTable_ReportCardForOneEmployee(Form, CrossTable, 
			Object.DataOnTime, ConversionParameters);
		Else  
			FillInCrossTableFromTable_ReportCardForSeveralEmployees(Form, CrossTable, 
			Object.DataOnTime, ConversionParameters);
		EndIf;
	Else
		FillInCrossTableFromTable_ShiftSchedule(Form, CrossTable, Object.DataOnTime, ConversionParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region ReportsAndPrinting

// Displays the report card data in a tabular document. Used in the document and report.
//
// Parameters:
//   TablePeriods - ValueTable - Table with periods for output
//   DataOnTime - ValueTable - Employee time data
//   SpreadsheetDocument - SpreadsheetDocument - Document for data output
//   Template - SpreadsheetDocument - Template for creating a tabular document
Procedure OutputTimesheetDataToTabularDocument(TablePeriods, DataOnTime, SpreadsheetDocument, Template) Export	
	
	NumberOfLinesToOutput = DivisionWithRoundingUp(TablePeriods.Count(), 16);
	LineNumber_Beginning = "";
	LineNumber_End = "";
	FullName_Start = "";
	FullName_End = "";
	EmployeeID_Start = "";
	EmployeeID_End = "";
	TotalDays_Start = "";
	BottomLineDays_End = "";
	TotalHours_Start = "";
	BottomLineHours_End = "";
	
	For LineCounter = 1 To NumberOfLinesToOutput Do
		If LineCounter = 1 Then
			Area				= Template.GetArea("TableHeader_Top|Column_LineNumber");
			LineNumber_Beginning 	= SpreadsheetDocument.Put(Area);
			Area				= Template.GetArea("TableHeader_Top|Column_FullName");
			FullName_Start			= SpreadsheetDocument.Join(Area);
			Area				= Template.GetArea("TableHeader_Top|Column_EmployeeID");
			EmployeeID_Start 	= SpreadsheetDocument.Join(Area);
			Area				= Template.GetArea("TableHeader_Top|Column_Dates");
			SpreadsheetDocument.Join(Area);
			Area				= Template.GetArea("TableHeader_Top|Column_Total");
			SpreadsheetDocument.Join(Area);
		EndIf;
		Span = GetRangeOfLinesForBlock(TablePeriods.Count(), LineCounter);
		
		Area				= Template.GetArea("TableHeader_Bottom|Column_LineNumber");
		LineNumber_End	= SpreadsheetDocument.Put(Area);
		Area				= Template.GetArea("TableHeader_Bottom|Column_FullName");
		FullName_End			= SpreadsheetDocument.Join(Area);
		Area				= Template.GetArea("TableHeader_Bottom|Column_EmployeeID");
		EmployeeID_End		= SpreadsheetDocument.Join(Area);
		Area				= Template.GetArea("TableHeader_Bottom|Column_Dates");
		ParameterCounter = 1;
		For CounterDate = Span.Begin To Span.End Do
			Area.Parameters["Date" + ParameterCounter] = TablePeriods.Get(CounterDate - 1).DateAsString;
			ParameterCounter = ParameterCounter + 1;
		EndDo;
		
		While ParameterCounter <= 16 Do
			Area.Parameters["Date" + ParameterCounter] = "X";
			ParameterCounter = ParameterCounter + 1;
		EndDo;
		SpreadsheetDocument.Join(Area);
		Area = Template.GetArea("TableHeader_Bottom|Column_TotalDays");
		BottomLineDays_End 	= SpreadsheetDocument.Join(Area);
		If LineCounter = 1 Then
			TotalDays_Start = BottomLineDays_End;
		EndIf;
		Area = Template.GetArea("TableHeader_Bottom|Column_TotalHours");
		BottomLineHours_End = SpreadsheetDocument.Join(Area);
		If LineCounter = 1 Then
			TotalHours_Start = BottomLineHours_End;
		EndIf;
	EndDo;
	MergeAreas(LineNumber_Beginning, LineNumber_End, SpreadsheetDocument);
	MergeAreas(FullName_Start, FullName_End, SpreadsheetDocument);
	MergeAreas(EmployeeID_Start, EmployeeID_End, SpreadsheetDocument);
	MergeAreas(TotalDays_Start, BottomLineDays_End, SpreadsheetDocument);
	MergeAreas(TotalHours_Start, BottomLineHours_End, SpreadsheetDocument);
	
	FixedStringStructure = New FixedStructure("LineNumber, EmployeeJobTitle, EmployeeCode, BottomLineDays, BottomLineHours",
	1, , "", 0, 0);
	LineNumber = 0;
	For Each DataByEmployee In DataOnTime.Rows Do 
		LineNumber = LineNumber +1;
		StringStructure = New Structure(FixedStringStructure);
		StringStructure.LineNumber = LineNumber;
		If ValueIsFilled(DataByEmployee.LastFirstName) Then
			StringStructure.EmployeeJobTitle = DataByEmployee.LastFirstName + " (" + DataByEmployee.JobTitle + ")";
		Else
			StringStructure.EmployeeJobTitle = DataByEmployee.IndividualName + " ("
				+ DataByEmployee.JobTitle + ")";
		EndIf;
		StringStructure.EmployeeCode = DataByEmployee.EmployeeCode;
		
		LineNumber_Beginning = "";
		LineNumber_End = "";
		FullName_Start = "";
		FullName_End = "";
		EmployeeID_Start = "";
		EmployeeID_End = "";
		TotalDays_Start = "";
		BottomLineDays_End = "";
		TotalHours_Start = "";
		BottomLineHours_End = "";
		TextOfResultsDays = "";
		TextOfResultsHours = "";
		MatchingTotalsHours = New Map;
		MatchingTotalsDays  = New Map;
		For LineCounter = 1 To NumberOfLinesToOutput Do
			Span = GetRangeOfLinesForBlock(TablePeriods.Count(), LineCounter);
			Area	= Template.GetArea("TableRow|Column_LineNumber");
			FillPropertyValues(Area.Parameters, StringStructure);
			If LineCounter = 1 Then
				LineNumber_Beginning = SpreadsheetDocument.Put(Area);
			Else
				LineNumber_End	= SpreadsheetDocument.Put(Area);
			EndIf;
			Area = Template.GetArea("TableRow|Column_FullName");
			FillPropertyValues(Area.Parameters, StringStructure);
			If LineCounter = 1 Then
				FullName_Start = SpreadsheetDocument.Join(Area);
			Else
				FullName_End  = SpreadsheetDocument.Join(Area);
			EndIf;
			
			Area = Template.GetArea("TableRow|Column_EmployeeID");
			FillPropertyValues(Area.Parameters, StringStructure);
			If LineCounter = 1 Then
				EmployeeID_Start	= SpreadsheetDocument.Join(Area);
			Else
				EmployeeID_End 	= SpreadsheetDocument.Join(Area);
			EndIf;
			
			Area = Template.GetArea("TableRow|Column_Dates");
			ParameterCounter = 1;
			For CounterDate = Span.Begin To Span.End Do
				OutputText_ = "";
				CurrentDate = TablePeriods.Get(CounterDate - 1).Date;
				
				DataArrayForDate = DataByEmployee.Rows.FindRows(New Structure("Date", CurrentDate));
				For Each DataAsOfTheDate In DataArrayForDate Do
					If ValueIsFilled(DataAsOfTheDate.Hours1) Then
						If MatchingTotalsHours[DataAsOfTheDate.LetterCode] = Undefined Then  
							MatchingTotalsHours.Insert(DataAsOfTheDate.LetterCode, DataAsOfTheDate.Hours1);
						Else
							MatchingTotalsHours[DataAsOfTheDate.LetterCode] = 
							MatchingTotalsHours[DataAsOfTheDate.LetterCode] + DataAsOfTheDate.Hours1;
						EndIf;
						OutputText_ = OutputText_ + ?(OutputText_ = "", "", "/");
						OutputText_ = OutputText_ + DataAsOfTheDate.LetterCode + DataAsOfTheDate.Hours1;
						StringStructure.BottomLineHours = StringStructure.BottomLineHours + DataAsOfTheDate.Hours1;
					EndIf;
					If ValueIsFilled(DataAsOfTheDate.Days) Then
						If MatchingTotalsDays[DataAsOfTheDate.LetterCode] = Undefined Then  
							MatchingTotalsDays.Insert(DataAsOfTheDate.LetterCode, DataAsOfTheDate.Days);
						Else
							MatchingTotalsDays[DataAsOfTheDate.LetterCode] = 
							MatchingTotalsDays[DataAsOfTheDate.LetterCode] + DataAsOfTheDate.Days;
						EndIf;
					EndIf;
				EndDo;
				If DataArrayForDate.Count() > 0 Then
					StringStructure.BottomLineDays = StringStructure.BottomLineDays + 1;
				Else
					OutputText_ = NStr("ru = 'Вых.';
										|vi = 'Off';
										|en = 'Off'; fa = 'Off';
										|it = 'Off';
										|pl = 'Off';
										|tr = 'Tatil'");
				EndIf;
				
				If DataArrayForDate.Count() >= 3 Then
					Area.CurrentArea.HorizontalAlign = HorizontalAlign.Justify;
				Else
					Area.CurrentArea.HorizontalAlign = HorizontalAlign.Center;
				EndIf;
				
				Area.Parameters["Date" + ParameterCounter] = OutputText_;
				ParameterCounter = ParameterCounter + 1;
			EndDo;
			
			While ParameterCounter <= 16 Do
				Area.Parameters["Date" + ParameterCounter] = "X";
				ParameterCounter = ParameterCounter + 1;
			EndDo;
			SpreadsheetDocument.Join(Area);
			
			Area = Template.GetArea("TableRow|Column_TotalDays");
			FillPropertyValues(Area.Parameters, StringStructure);
			
			BottomLineDays_End 	= SpreadsheetDocument.Join(Area);
			If LineCounter = 1 Then
				TotalDays_Start = BottomLineDays_End;
			EndIf;
			Area = Template.GetArea("TableRow|Column_TotalHours");
			FillPropertyValues(Area.Parameters, StringStructure);
			BottomLineHours_End 	= SpreadsheetDocument.Join(Area);
			If LineCounter = 1 Then
				TotalHours_Start = BottomLineHours_End;
			EndIf;
		EndDo;
		
		For Each KeyAndValue In MatchingTotalsDays Do  
			If Not TextOfResultsDays = "" Then
				TextOfResultsDays = TextOfResultsDays+"/";
			EndIf;
			TextOfResultsDays = TextOfResultsDays+KeyAndValue.Key+KeyAndValue.Value;
		EndDo;
		For Each KeyAndValue In MatchingTotalsHours Do
			If Not TextOfResultsHours = "" Then
				TextOfResultsHours = TextOfResultsHours+"/";
			EndIf;
			TextOfResultsHours = TextOfResultsHours+KeyAndValue.Key+KeyAndValue.Value;
		EndDo;
		
		MergeAreas(LineNumber_Beginning, LineNumber_End, SpreadsheetDocument);
		MergeAreas(FullName_Start, FullName_End, SpreadsheetDocument);
		MergeAreas(EmployeeID_Start, EmployeeID_End, SpreadsheetDocument);
		UnitedArea = MergeAreas(TotalDays_Start, BottomLineDays_End, SpreadsheetDocument);
		UnitedArea.Text = TextOfResultsDays;
		UnitedArea = MergeAreas(TotalHours_Start, BottomLineHours_End, SpreadsheetDocument);
		UnitedArea.Text = TextOfResultsHours;
	EndDo;
	
EndProcedure

// Displays shift schedule data in a tabular document. Used in the document and report.
//
// Parameters:
//   ConversionParameters - Structure - parameters for data conversion
//   DataOnTime - TabularSection - Time Data
//   SpreadsheetDocument - SpreadsheetDocument - Document for data output
//   Template - SpreadsheetDocument - Template for creating a tabular document
Procedure OutputShiftScheduleDataToTabularDocument(ConversionParameters, DataOnTime, SpreadsheetDocument, Template) Export	
	
	IsReport = False;
	ConversionParameters.Property("IsReport", IsReport);
	ErrorHeaderText = ?(IsReport, NStr("ru = 'Вывод отчета не возможен';
										|vi = 'Cannot output the report';
										|en = 'Cannot output the report'; fa = 'Cannot output the report';
										|it = 'Cannot output the report';
										|pl = 'Cannot output the report';
										|tr = 'Rapor görüntülenemiyor'"), NStr("ru = 'Печать невозможна';
																				|vi = 'Printing is not available';
																				|en = 'Printing is not available'; fa = 'Printing is not available';
																				|it = 'Printing is not available';
																				|pl = 'Printing is not available';
																				|tr = 'Yazdırma mümkün değil'"));

	TablePeriods = ConversionParameters.TablePeriods;
	ByDays = ConversionParameters.ByDays;
	
	If TypeOf(DataOnTime) = Type("ValueTreeRow") Then
		TSData = UploadTimeDataToTableOfValues(DataOnTime);
	ElsIf TypeOf(DataOnTime) = Type("ValueTable") Then
		TSData = DataOnTime.Copy();
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1: ошибка определения типа данных';
																			|vi = '%1: data type identification error';
																			|en = '%1: data type identification error'; fa = '%1: data type identification error';
																			|it = '%1: data type identification error';
																			|pl = '%1: data type identification error';
																			|tr = '%1: veri türü belirleme hatası'"), ErrorHeaderText);
	EndIf;
	SelectedMeasurements = New ValueList;
	ArrayOfDimensions_ = Common.UnloadColumn(TSData, "WorkScheduleCalendar", True);
	MeasurementsData = Common.ObjectsAttributesValues(ArrayOfDimensions_, "Ref, Description, ShortName");
	If MeasurementsData.Count() = 0 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = '%1: в документе не заполнены графики работы';
																			|vi = '%1: the work schedules are not filled in the document';
																			|en = '%1: the work schedules are not filled in the document'; fa = '%1: the work schedules are not filled in the document';
																			|it = '%1: the work schedules are not filled in the document';
																			|pl = '%1: the work schedules are not filled in the document';
																			|tr = '%1: belgede çalışma takvimleri doldurulmamış'"), ErrorHeaderText);;
	EndIf;
	For Each KeyAndValue In MeasurementsData Do
		Presentation = ?(ValueIsFilled(KeyAndValue.Value.ShortName), 
		KeyAndValue.Value.ShortName, KeyAndValue.Value.Description);
		SelectedMeasurements.Add(KeyAndValue.Key, Presentation);
	EndDo;
	SelectedMeasurements.SortByPresentation(SortDirection.Asc);
	
	TypesDetailsString = New TypeDescription("String");
	TypesDetailsNumber	= New TypeDescription("Number");
	TypesDetailsDate 	= Common.DateTypeDetails(DateFractions.Date);
	GraphColumnType 	= ?(ByDays, New TypeDescription("CatalogRef.Calendars"), New TypeDescription("Boolean"));
	
	ScheduleByDate = New ValueTable;
	ScheduleByDate.Columns.Add("Employee",  		New TypeDescription("CatalogRef.EmployeesHR"));
	ScheduleByDate.Columns.Add("Date",		 		TypesDetailsDate);
	ScheduleByDate.Columns.Add("LASTFIRSTNAME", 		 		TypesDetailsString);
	ScheduleByDate.Columns.Add("EmployeeCode",	TypesDetailsString);
	ScheduleByDate.Columns.Add("JobTitle",	 		TypesDetailsString);
	ScheduleByDate.Columns.Add("Shift", 	 		TypesDetailsString);
	ScheduleByDate.Columns.Add("LineNumber",		TypesDetailsString);
	
	TotalsData = New Structure;
	NumberOfMeasurements = SelectedMeasurements.Count();
	If ByDays Then
		For Each RowPeriod In TablePeriods Do
			ScheduleByDate.Columns.Add("Dimension"+1+"_"+RowPeriod.ColumnName, GraphColumnType);
			TotalsData.Insert("ScheduleByDate"+"ColumnSummary_"+"_Dimension"+1+"_"+RowPeriod.ColumnName, 0);
		EndDo;
		ScheduleByDate.Columns.Add("LineSummary"+1, TypesDetailsNumber);
		TotalsData.Insert("ScheduleByDate"+"OverallTotalByLine"+1, 0)
	Else
		For DimensionsCounter=1 To NumberOfMeasurements Do
			For Each RowPeriod In TablePeriods Do
				ScheduleByDate.Columns.Add("Dimension"+DimensionsCounter+"_"+RowPeriod.ColumnName, GraphColumnType);
				TotalsData.Insert("ScheduleByDate"+"ColumnSummary_"+"_Dimension"+DimensionsCounter+"_"+RowPeriod.ColumnName, 0);
			EndDo;
			ScheduleByDate.Columns.Add("LineSummary"+1+"_Dimension"+DimensionsCounter, TypesDetailsNumber);
			TotalsData.Insert("ScheduleByDate"+"OverallTotalByLine"+1+"_Dimension"+DimensionsCounter, 0);
		EndDo;
	EndIf;
	
	ConversionParameters.Insert("SelectedMeasurements",  SelectedMeasurements);
	ConversionParameters.Insert("NumberOfMeasurements", NumberOfMeasurements);
	FillInCrossTableFromTable_ShiftSchedule(TotalsData, ScheduleByDate, TSData, ConversionParameters);
	
	AreaLineNumber		= Template.GetArea("TableHeader_Date|Column_Number");
	AreaFullName				= Template.GetArea("TableHeader_Date|Column_FullName");
	AreaEmployeeID	= Template.GetArea("TableHeader_Date|Column_EmployeeID");
	AreaDate  			= Template.GetArea("TableHeader_Date|Column_Date");
	Area_Shift			= Template.GetArea("TableHeader_Change|Column_Date");
	ScopeOfApplication_1 			= Template.GetArea("TableHeader_Date|Column_Total");
	
	DaysCount = TablePeriods.Count();
	MaxColumnsPerPage = DetermineMaximumNumberOfColumns(TablePeriods, ByDays, SelectedMeasurements);
	NumberOfLinesToOutput = DivisionWithRoundingUp(DaysCount, MaxColumnsPerPage);
	
	LineNumber_Beginning = "";
	LineNumber_End = "";
	FullName_Start = "";
	FullName_End = "";
	EmployeeID_Start = "";
	EmployeeID_End = "";
	BottomLine_Beginning = "";
	Result_End = "";
	NumberOfSubstrings = ?(ByDays, 1, 2);
	NumberOfMeasurements = ?(ByDays, 1, NumberOfMeasurements);
	For RangeCounter=1 To NumberOfLinesToOutput Do 
		Span = GetRangeOfLinesForBlock(DaysCount, RangeCounter, MaxColumnsPerPage);
		For LineCounter=1 To NumberOfSubstrings Do
			LineNumber_Output = SpreadsheetDocument.Put(AreaLineNumber);
			FullName_Withdrawal = SpreadsheetDocument.Join(AreaFullName);
			EmployeeID_Output = SpreadsheetDocument.Join(AreaEmployeeID);
			ParameterCounter = 1;
			For CounterDate = Span.Begin To Span.End Do
				If LineCounter=1 Then
					StartingAddress = Undefined;
					FinalAddress  = Undefined;
					For DimensionsCounter=1 To NumberOfMeasurements Do 
						CurrentDate = TablePeriods.Get(CounterDate - 1).DateAsString;
						AreaDate.Parameters["Date"] = CurrentDate;
						OutputArea2 = SpreadsheetDocument.Join(AreaDate);
						If DimensionsCounter=1 Then
							StartingAddress = OutputArea2;
						EndIf;
						If DimensionsCounter = NumberOfMeasurements Then
							FinalAddress  = OutputArea2;
						EndIf;
					EndDo;
					If Not ByDays And NumberOfMeasurements>1 Then
						MergeAreas(StartingAddress, FinalAddress, SpreadsheetDocument);
					EndIf;
				Else  
					For DimensionsCounter=1 To NumberOfMeasurements Do 
						Area_Shift.Parameters.Shift = SelectedMeasurements.Get(DimensionsCounter-1).Presentation;
						OutputArea2 = SpreadsheetDocument.Join(Area_Shift);
						OutputArea2.HorizontalAlign = 
						?(StrLen(Area_Shift.Parameters.Shift)>5, 
						HorizontalAlign.Justify, HorizontalAlign.Center);
					EndDo;
				EndIf;
				ParameterCounter = ParameterCounter + 1;
			EndDo;
			
			While ParameterCounter <= MaxColumnsPerPage Do
				If LineCounter=1 Then
					StartingAddress = Undefined;
					FinalAddress  = Undefined;
					For DimensionsCounter=1 To NumberOfMeasurements Do 
						AreaDate.Parameters["Date"] = "X";
						OutputArea2 = SpreadsheetDocument.Join(AreaDate);
						If DimensionsCounter=1 Then
							StartingAddress = OutputArea2;
						EndIf;
						If DimensionsCounter = NumberOfMeasurements Then
							FinalAddress = OutputArea2;
						EndIf;
				EndDo;
				If NumberOfMeasurements>1 Then
						MergeAreas(StartingAddress, FinalAddress, SpreadsheetDocument);
					EndIf;
				Else
					For DimensionsCounter=1 To NumberOfMeasurements Do
						Area_Shift.Parameters.Shift = "X";
						OutputArea2 = SpreadsheetDocument.Join(Area_Shift);
					EndDo;
				EndIf;
				ParameterCounter = ParameterCounter + 1;
			EndDo;
			
			Result_Conclusion = SpreadsheetDocument.Join(ScopeOfApplication_1);
			If LineCounter=1 And RangeCounter=1 Then
				LineNumber_Beginning = LineNumber_Output;
				FullName_Start = FullName_Withdrawal;
				EmployeeID_Start = EmployeeID_Output;
				BottomLine_Beginning = Result_Conclusion;
			ElsIf LineCounter=NumberOfSubstrings And RangeCounter=NumberOfLinesToOutput Then
				LineNumber_End = LineNumber_Output;
				FullName_End = FullName_Withdrawal;
				EmployeeID_End = EmployeeID_Output;
				Result_End = Result_Conclusion;
			EndIf;
		EndDo;
		MergeAreas(LineNumber_Beginning, LineNumber_End, SpreadsheetDocument);
		MergeAreas(FullName_Start, FullName_End, SpreadsheetDocument);
		MergeAreas(EmployeeID_Start, EmployeeID_End, SpreadsheetDocument);
		MergeAreas(BottomLine_Beginning, Result_End, SpreadsheetDocument);
	EndDo;
	
	LineNumber_Beginning = "";
	LineNumber_End = "";
	FullName_Start = "";
	FullName_End = "";
	EmployeeID_Start = "";
	EmployeeID_End = "";
	BottomLine_Beginning = "";
	Result_End = "";
	
	AreaLineNumber 		= Template.GetArea("TableRow|Column_Number");
	AreaFullName				= Template.GetArea("TableRow|Column_FullName");
	AreaEmployeeID 	= Template.GetArea("TableRow|Column_EmployeeID");
	AreaDateChange		= Template.GetArea("TableRow|Column_Date");
	ScopeOfApplication_1		 		= Template.GetArea("TableRow|Column_Total");
	
	FixedStringStructure = New FixedStructure("LineNumber, EmployeeJobTitle, EmployeeCode, Shift, Total");
	BackColor = WebColors.LightGreen;
	ScheduleCounter = 1;
	For Each ScheduleRow In ScheduleByDate Do
		StringStructure = New Structure(FixedStringStructure);
		StringStructure.LineNumber = ScheduleCounter;
		StringStructure.EmployeeJobTitle 
		= PersonsClientServer.InitialsAndLastName(ScheduleRow.LASTFIRSTNAME)+" ("+ScheduleRow.JobTitle+")";
		StringStructure.EmployeeCode = ScheduleRow.EmployeeCode;
		StringStructure.Total = 0;
		
		For RangeCounter=1 To NumberOfLinesToOutput Do 
			Span = GetRangeOfLinesForBlock(DaysCount, RangeCounter, MaxColumnsPerPage);
			
			FillPropertyValues(AreaLineNumber.Parameters, StringStructure);
			LineNumber_Output = SpreadsheetDocument.Put(AreaLineNumber);
			FillPropertyValues(AreaFullName.Parameters, StringStructure);
			FullName_Withdrawal = SpreadsheetDocument.Join(AreaFullName);
			FillPropertyValues(AreaEmployeeID.Parameters, StringStructure);
			EmployeeID_Output = SpreadsheetDocument.Join(AreaEmployeeID);
			ParameterCounter = 1;
			For CounterDate = Span.Begin To Span.End Do 
				ColumnName = TablePeriods.Get(CounterDate - 1).ColumnName;
				If ByDays Then
					ChangeInSchedule = ScheduleRow["Dimension"+1+"_"+ColumnName];
					CurrentShift = SelectedMeasurements.FindByValue(ChangeInSchedule);
					If CurrentShift = Undefined Then
						StringStructure.Shift 	= "";
					Else
						StringStructure.Shift 	= CurrentShift.Presentation;
						StringStructure.Total 	= StringStructure.Total +1;
					EndIf;	
					FillPropertyValues(AreaDateChange.Parameters, StringStructure);
					OutputArea2 = SpreadsheetDocument.Join(AreaDateChange);
					OutputArea2.HorizontalAlign = 
					?(StrLen(StringStructure.Shift)>5, HorizontalAlign.Justify, HorizontalAlign.Center);
				Else
					For DimensionsCounter=1 To NumberOfMeasurements Do
						ChangeInSchedule = ScheduleRow["Dimension"+DimensionsCounter+"_"+ColumnName];
						OutputArea2 = SpreadsheetDocument.Join(AreaDateChange);
						If ChangeInSchedule Then
							OutputArea2.BackColor = BackColor;
							StringStructure.Total = StringStructure.Total + 1;
						EndIf;
					EndDo;
				EndIf;
				ParameterCounter = ParameterCounter + 1;
			EndDo;
			
			While ParameterCounter <= MaxColumnsPerPage Do
				For DimensionsCounter=1 To NumberOfMeasurements Do
					AreaDateChange.Parameters.Shift = "";
					OutputArea2 = SpreadsheetDocument.Join(AreaDateChange);
				EndDo;
				ParameterCounter = ParameterCounter + 1;
			EndDo;
			
			FillPropertyValues(ScopeOfApplication_1.Parameters, StringStructure);
			Result_Conclusion = SpreadsheetDocument.Join(ScopeOfApplication_1);
			
			If RangeCounter=1 Then
				LineNumber_Beginning = LineNumber_Output;
				FullName_Start = FullName_Withdrawal;
				EmployeeID_Start = EmployeeID_Output;
				BottomLine_Beginning = Result_Conclusion;
			ElsIf RangeCounter=NumberOfLinesToOutput Then
				LineNumber_End = LineNumber_Output;
				FullName_End = FullName_Withdrawal;
				EmployeeID_End = EmployeeID_Output;
				Result_End = Result_Conclusion;
			EndIf;
		EndDo;
		BottomLine_Beginning.Text = StringStructure.Total;
		MergeAreas(LineNumber_Beginning, LineNumber_End, SpreadsheetDocument);
		MergeAreas(FullName_Start, FullName_End, SpreadsheetDocument);
		MergeAreas(EmployeeID_Start, EmployeeID_End, SpreadsheetDocument);
		MergeAreas(BottomLine_Beginning, Result_End, SpreadsheetDocument);
		ScheduleCounter = ScheduleCounter+1;
	EndDo;
	
EndProcedure

#EndRegion  

#EndRegion

// Defines the job title of an individual in the company on a given date.
//
// Parameters:
//   Person - CatalogRef.Persons - The person for whom the job title is determined
//   Organization - CatalogRef.Companies - The company where the job title is defined
//   Date - Date - The date on which the job title is determined
//
// Returns:
//   Structure - Contains the job title and its Presentation:
//	* JobTitle - CatalogRef.JobTitles - Job title of an individual
//	* Presentation - String - Presentation of the job title of an individual
//
Function DetermineJobTitleOfIndividual(Person, Organization, Date)  Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	EmploymentRecordSliceLast.JobTitle AS JobTitle,
	|	EmploymentRecordSliceLast.JobTitle.Presentation AS JobTitlePresentation
	|FROM
	|	InformationRegister.EmploymentRecord.SliceLast(
	|			&Period,
	|			Organization = &Organization
	|				AND Employee.Individual = &Person
	|				AND WorksInBusinessUnit) AS EmploymentRecordSliceLast";
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Period", Date);
	Query.SetParameter("Person", Person);
	
	Selection = Query.Execute().Select();
	
	JobTitleStructure  = New Structure("JobTitle, Presentation", 
	Catalogs.JobTitles.EmptyRef(), "");
	If Selection.Next() Then
		JobTitleStructure.Insert("JobTitle", 	Selection.JobTitle);
		JobTitleStructure.Insert("Presentation", Selection.JobTitlePresentation);
	EndIf ;
	Return JobTitleStructure;
	
EndFunction

// Returns the names of form elements in the current configuration language
//
// Returns:
//   Structure:
//     * ReadOnly - String - name of the form property for the "View Only" mode
//     * ShowInFooter - String - name of the form property to display in the basement
//     * FormFieldType - String - name of the form property for the field type
//     * ChoiceButton - String - name of the form property for the selection button
//     * ListChoiceMode - String - name of the form property for the selection mode from the list
//     * ShowInHeader - String - name of the form property to display in the header
//     * ItemHorizontalLocation - String - name of the shape property for the horizontal position
//     * MaxValue - String - name of the form property for the maximum value.
//     * ClearButton - String - name of the form property for the clear button
//     * TitleFont - String - name of the form property for the header font
//     * FooterFont - String - name of the form property for the basement font
//     * IFRSEntries - String - name of the reflection button in IFRS
//     * IFRSEntriesExtendedTooltip - String - the name of the reflection button in IFRS Extended Tooltip
//     * ShowInList - String - name of the show in list button
//     * ShowInListExtendedTooltip - String - the name of the show in the list button Extended Tooltip
Function GetNamesOfFormElements() Export

	Russian = Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.Russian;

	Structure = New Structure;
	Structure.Insert("ReadOnly", ?(Russian, "ReadOnly", "ReadOnly"));

	Structure.Insert("ShowInFooter", ?(Russian, "ShowInFooter", "ShowInFooter"));
	Structure.Insert("FormFieldType", ?(Russian, "Kind", "Type"));
	Structure.Insert("ChoiceButton", ?(Russian, "ChoiceButton", "ChoiceButton"));
	Structure.Insert("ListChoiceMode", ?(Russian, "ListChoiceMode", "ListChoiceMode"));
	Structure.Insert("ShowInHeader", ?(Russian, "ShowInHeader", "ShowInHeader"));
	Structure.Insert("ItemHorizontalLocation", ?(Russian, "HorizontalAlign", "HorizontalAlign"));
	Structure.Insert("MaxValue", ?(Russian, "MaxValue", "MaxValue"));
	Structure.Insert("ClearButton", ?(Russian, "ClearButton", "ClearButton"));
	Structure.Insert("TitleFont", ?(Russian, "TitleFont", "TitleFont"));
	Structure.Insert("FooterFont", ?(Russian, "FooterFont", "FooterFont"));
	
	Structure.Insert("IFRSEntries", ?(Russian,
		"FormProcessingReflectionOfDocumentsInInternationalAccountingEntriesOfDocumentOfOperationalAccounting",
		"FormDataProcessorDocumentPostingInFinancialAccountingAccountingEntries"));
	Structure.Insert("IFRSEntriesExtendedTooltip", ?(Russian,
		"FormProcessingReflectionOfDocumentsInInternationalAccountingEntriesOfDocumentOfOperationalAccountingExtendedTooltip",
		"FormDataProcessorDocumentPostingInFinancialAccountingAccountingEntriesExtendedTooltip"));
	Structure.Insert("ShowInList", ?(Russian, "FormShowPayrollReflectionInFinancialAccountingInList2_5",
		"FormShowInListPostingPayrollExpensesInFinancialAccounting2_5"));
	Structure.Insert("ShowInListExtendedTooltip", ?(Russian,
		"FormShowPayrollReflectionInFinancialAccountingInList2_5ExtendedTooltip",
		"FormShowInListPostingPayrollExpensesInFinancialAccounting2_5ExtendedTooltip"));
	
	Return Structure;

EndFunction

#EndRegion

#Region Private

Procedure AddDefaultSettings(OutputParameters, Form, TablePeriods)
	
	If TypeOf(OutputParameters) <> Type("Structure") Then
		OutputParameters = New Structure;
	EndIf;

	OutputParameters.Insert("OneEmployeeHasBeenSelected",			False);
	OutputParameters.Insert("NameOfCrossTableProps",	"ScheduleByDate");
	OutputParameters.Insert("CrossTableFormElement", 	"ScheduleByDate");
	OutputParameters.Insert("UsePeriods",		 	True);
	OutputParameters.Insert("PeriodsTable", 		 	TablePeriods);
	OutputParameters.Insert("ByDays", 					 	Form.ByDays);
	OutputParameters.Insert("SelectedMeasurements",		 	Form.SelectedMeasurements);
	OutputParameters.Insert("NumberOfMeasurements",		 	Form.NumberOfMeasurements);
	OutputParameters.Insert("ColumnsGroup",			ColumnsGroup.Horizontal);
	OutputParameters.Insert("GroupingTotals",			ColumnsGroup.Horizontal);
	OutputParameters.Insert("PredefinedDetails", 	"LineNumber, Date, Employee");
	
EndProcedure 

Procedure AddOutputParametersForDocuments(OutputParameters, Form)

	ItemsNames = GetNamesOfFormElements();
	
	BoldFont = StyleFonts["BoldFont"];
	PropertiesOfTotals = New Structure;
	PropertiesOfTotals.Insert("Format",	"NLZ=");
	PropertiesOfTotals.Insert(ItemsNames.FormFieldType,	FormFieldType.InputField);
	PropertiesOfTotals.Insert("Width",	10);
	PropertiesOfTotals.Insert("Font", 			BoldFont);
	PropertiesOfTotals.Insert(ItemsNames.TitleFont, 	BoldFont);
	PropertiesOfTotals.Insert(ItemsNames.FooterFont, 	BoldFont);
	PropertiesOfTotals.Insert("UsePresentation",	False);
	PropertiesOfTotals.Insert("SummaryHeader", 				NStr("ru = 'Итог';
																	|vi = 'Total';
																	|en = 'Total'; fa = 'جمع کل';
																	|it = 'Total';
																	|pl = 'Total';
																	|tr = 'Toplam'"));
	PropertiesOfTotals.Insert("HorizontalAlign",		ItemHorizontalLocation.Auto);
	PropertiesOfTotals.Insert("ShowInHeader",				False);
	
	OutputParameters.Insert("DocumentType", ?(StrFind(Form.FormName, "TimesheetHR") > 0,
		"TimesheetHR", "ShiftScheduleHR"));
	OutputParameters.Insert("GroupSelectedDimensions", "ScheduleByDateGroupSelectedMeasurements");
	OutputParameters.Insert("ParentGroupSummary",		 "ScheduleByDateGroupTotal");
	
	StructureOfResults = New Structure;
	If OutputParameters.DocumentType = "TimesheetHR" Then
		OutputParameters.Insert("OneEmployeeHasBeenSelected", Form.OneEmployeeHasBeenSelected);
		OutputParameters.Insert("UsePeriods", ?(OutputParameters.OneEmployeeHasBeenSelected, False, True));
		OutputParameters.Insert("TypeOfTotals", 			Common.TypeDescriptionNumber(5, 1, AllowedSign.Nonnegative));
		OutputParameters.Insert("TotalsCount", 	2);
		OutputParameters.Insert("DetailedResults", 		?(OutputParameters.ByDays, True, False));

		If OutputParameters.ByDays And Not OutputParameters.OneEmployeeHasBeenSelected Then
			OutputParameters.Insert("ColumnsGroup", ColumnsGroup.Vertical);
			OutputParameters.Insert("DetailedResults", True);
			If OutputParameters.SelectedMeasurements.Count() < 2 Then
				OutputParameters.GroupingTotals = ColumnsGroup.Horizontal;
			Else
				OutputParameters.GroupingTotals = ColumnsGroup.Vertical;
			EndIf;
		Else
			OutputParameters.Insert("UsePeriods", False);
			OutputParameters.Insert("DetailedResults", 		False);
			PropertiesOfTotals.Insert("HorizontalAlign", ItemHorizontalLocation.Left);
		EndIf;
		PropertiesOfTotals.Insert("SummaryHeader", NStr("ru = 'Часы';
														|vi = 'Hours';
														|en = 'Hours'; fa = 'ساعت';
														|it = 'Hours';
														|pl = 'Hours';
														|tr = 'Saatler'"));
		StructureOfResults.Insert("Hours1", PropertiesOfTotals);
		PropertiesOfTotals2 = Common.CopyRecursive(PropertiesOfTotals);
		PropertiesOfTotals2.Insert("SummaryHeader", NStr("ru = 'Дни';
														|vi = 'Days';
														|en = 'Days'; fa = 'روز';
														|it = 'Days';
														|pl = 'Days';
														|tr = 'Günler'"));
		StructureOfResults.Insert("Days",  PropertiesOfTotals2);
	Else
		OutputParameters.Insert("TypeOfTotals", New TypeDescription("Number"));
		OutputParameters.Insert("TotalsCount", 1);
		OutputParameters.Insert("DetailedResults", ?(OutputParameters.ByDays, False, True));
		OutputParameters.Insert("DisplayGroupOfTotalsInHeader", ?(OutputParameters.ByDays, False, True));
		OutputParameters.Insert("ParentGroupSummary", "ScheduleByDateGroupTotal");
		
		PropertiesOfTotals.Insert("UsePresentation", True);
		For Each Dimension In OutputParameters.SelectedMeasurements Do
			PropertiesOfTotals.Insert("Width", Max(PropertiesOfTotals.Width, StrLen(Dimension.Presentation)));
		EndDo;
		StructureOfResults.Insert("Total", PropertiesOfTotals);
	EndIf;
	OutputParameters.Insert("StructureOfResults", StructureOfResults);

EndProcedure

// Supplements the output parameters with data on the properties of dimensions and form elements, depending on the document type and display mode.
//
// Parameters:
//   OutputParameters - Structure - contains output settings, including document type, flag by day, and flag for selecting one employee
//   The dimension structure - The structure - contains the properties of the dimensions that will be used when outputting data
//   Element properties - Structure - contains the properties of the form element that will be used when outputting data
//   Only View is a Boolean flag indicating that the form element will be viewable only
//   Display in the basement - Line - a line indicating that the form element will be displayed in the basement
//   View - Form field view - the type of form field that will be used when outputting data
//   The selection button is a Boolean flag indicating that the form element will have a selection button
//   The open button is a Boolean flag indicating that the form element will have an open button
//   The Cleanup button is a Boolean flag indicating that the form element will have a cleanup button
//   The List selection mode is a Boolean flag indicating that the form element will have a selection mode from the list.
//
Procedure AddDimensionsToOutputParameters(OutputParameters)
	
	ItemsNames = GetNamesOfFormElements();
	
	DimensionStructure = New Structure;
	PropertiesDimension  = New Structure;
	FillInDefaultDimensionProperties(PropertiesDimension, OutputParameters);
	ItemProperties = New Structure;
	ItemProperties.Insert(ItemsNames.ReadOnly,		False);
	ItemProperties.Insert(ItemsNames.ShowInFooter,	True);
	ItemProperties.Insert(ItemsNames.FormFieldType,			FormFieldType.InputField);
	ItemProperties.Insert(ItemsNames.ChoiceButton,			False);
	ItemProperties.Insert(ItemsNames.ListChoiceMode,	False);
	
	If OutputParameters.DocumentType = "TimesheetHR" Then
		PropertiesDimension.Insert("GroupPresentation", 	"");
		PropertiesDimension.Insert("CreateOutsidePeriods",	True);
		ItemProperties.Insert("Format", 				"NLZ=");
		If OutputParameters.ByDays Then
			ItemProperties.Insert(ItemsNames.MaxValue, 24);
		Else
			ItemProperties.Insert(ItemsNames.MaxValue, 999);
		EndIf;
		If OutputParameters.ByDays And Not OutputParameters.OneEmployeeHasBeenSelected Then  
			ItemProperties.Insert("Width", 5);
			
			PropertiesDimension.Insert("GroupPresentation", 			NStr("ru = 'Вид времени, Ед.изм.';
																			|vi = 'Work time type, unit of measure';
																			|en = 'Work time type, unit of measure'; fa = 'Work time type, unit of measure';
																			|it = 'Work time type, unit of measure';
																			|pl = 'Work time type, unit of measure';
																			|tr = 'Zaman türü, Ölçü birimi'"));
			PropertiesDimension.Insert("TypeOutsidePeriods",				
			New TypeDescription("CatalogRef.PayCodesHR"));
			PropertiesDimension.Insert("GroupingOutsidePeriods", 		ColumnsGroup.Vertical);
			PropertiesDimension.Insert("GroupingWithinPeriods", 	ColumnsGroup.Vertical);
			PropertiesDimension.Insert("DisplayInHeaderOutsideOfPeriods",	False);
			PropertiesDimension.Insert("DisplayInHeaderWithinPeriods",False);
			PropertiesDimension.Insert("OnlyViewOutsidePeriods",		True);
			
			AdditionalColumn = New Structure;
			AdditionalColumn.Insert("ColumnName", 		"UnitOfMeasurementDimension");
			AdditionalColumn.Insert("Path", 			"UnitOfMeasure");
			AdditionalColumn.Insert("Title", 		NStr("ru = 'Ед.изм.';
															|vi = 'UOM';
															|en = 'UOM'; fa = 'UOM';
															|it = 'UOM';
															|pl = 'UOM';
															|tr = 'Ölçü birimi'"));
			AdditionalColumn.Insert("ShowInHeader", False);
			AdditionalColumn.Insert("Width", 			3);
			PropertiesDimension.Insert("AdditionalColumn", AdditionalColumn);
		Else
			PropertiesDimension.Insert("CreateOutsidePeriods",		True);
			PropertiesDimension.Insert("CreateWithinPeriods",	False);
			PropertiesDimension.Insert("GroupingOutsidePeriods", 	ColumnsGroup.Horizontal);
			For Each RowOfContent In PropertiesDimension.DimensionComposition Do
				DimensionData =
				Common.ObjectAttributesValues(RowOfContent.Value, "Description, UnitOfMeasure");
				RowOfContent.Presentation = DimensionData.Description +" ("+DimensionData.UnitOfMeasure+".)";
			EndDo;
		EndIf;
	Else
		If OutputParameters.ByDays Then
			PropertiesDimension.Insert("TypeWithinPeriods",					New TypeDescription("CatalogRef.Calendars"));
			PropertiesDimension.Insert("LimitWithinPeriods",		True);
			PropertiesDimension.Insert("DisplayInHeaderWithinPeriods",	False);
			ItemProperties.Insert(ItemsNames.ClearButton,			True);
			ItemProperties.Insert(ItemsNames.ListChoiceMode,	True);
		Else
			PropertiesDimension.Insert("TypeWithinPeriods",				New TypeDescription("Boolean"));
			PropertiesDimension.Insert("DisplayGroupOfTotalsInHeader", 	False);
			ItemProperties.Insert(ItemsNames.FormFieldType, FormFieldType.CheckBoxField);
			If PropertiesDimension.Count = 1 Then
				ItemProperties.Insert(ItemsNames.ShowInHeader, False);
				ItemProperties.Insert("Width", 5);
				ItemProperties.Insert(ItemsNames.ItemHorizontalLocation, ItemHorizontalLocation.Center);
			EndIf;
		EndIf;
	EndIf;
	PropertiesDimension.Insert("ItemProperties", 	ItemProperties);
	DimensionStructure.Insert("Dimension"+"1", 	PropertiesDimension);
	OutputParameters.Insert("DimensionStructure",	DimensionStructure);
	
EndProcedure  

Procedure FillInDefaultDimensionProperties(PropertiesDimension, OutputParameters)
	
	PropertiesDimension.Insert("TypeOutsidePeriods", 				
	Common.TypeDescriptionNumber(15,1,AllowedSign.Nonnegative));
	PropertiesDimension.Insert("TypeWithinPeriods", 			
	Common.TypeDescriptionNumber(15,1,AllowedSign.Nonnegative));
	PropertiesDimension.Insert("DimensionComposition",				OutputParameters.SelectedMeasurements);
	PropertiesDimension.Insert("CreateOutsidePeriods",			False);
	// Determines whether to expand the dimension for each date
	PropertiesDimension.Insert("CreateWithinPeriods",		True);
	// Only one value will be created for each day. Used in a shift schedule/by day.
	PropertiesDimension.Insert("LimitWithinPeriods",	False);
	PropertiesDimension.Insert("DisplayGroupOfTotalsInHeader", 	False);
	PropertiesDimension.Insert("GroupingOutsidePeriods", 		ColumnsGroup.Horizontal);
	PropertiesDimension.Insert("GroupingWithinPeriods", 	ColumnsGroup.Horizontal);
	PropertiesDimension.Insert("DisplayInHeaderOutsideOfPeriods",	True);
	PropertiesDimension.Insert("DisplayInHeaderWithinPeriods",True);
	PropertiesDimension.Insert("OnlyViewOutsidePeriods",		False);
	PropertiesDimension.Insert("OnlyViewInsidePeriods",	False);
	PropertiesDimension.Insert("Count", 					OutputParameters.SelectedMeasurements.Count());
	
EndProcedure

Procedure CreateUpdateBankingDetails(Parameters, Val AttributeName, TableAttribute, Title="", UpdateAlways=False);
	
	If TableAttribute Then
		If Parameters.MatchingTableAttributes[AttributeName] = True And Not UpdateAlways Then
			CommonClientServer.DeleteValueFromArray(
			Parameters.AttributesToBeDeleted, Parameters.NameOfCrossTableProps+"."+AttributeName);
		Else
			If Not AttributeIsIncludedInArray(AttributeName, Parameters.AttributesToBeAdded) Then
				Attribute = New FormAttribute(AttributeName, Parameters.Type, Parameters.NameOfCrossTableProps, Title);
				Parameters.AttributesToBeAdded.Add(Attribute);
			EndIf;
		EndIf;
	Else
		AttributeName = Parameters.NameOfCrossTableProps+AttributeName;
		If Parameters.MatchingTopLevelDetails[AttributeName] = True And Not UpdateAlways Then
			CommonClientServer.DeleteValueFromArray(Parameters.AttributesToBeDeleted, AttributeName);
		Else  
			If Not AttributeIsIncludedInArray(AttributeName, Parameters.AttributesToBeAdded) Then
				Attribute = New FormAttribute(AttributeName, Parameters.Type,, Title);
				Parameters.AttributesToBeAdded.Add(Attribute);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Checks whether the Attribute is included in the array of Attributes
//
// Parameters:
//  AttributeName - String - name of the Attribute for verification
//  AttributesArray - Array of Arbitrary - array of search Attributes
//
// Returns:
//  Boolean - is the Attribute included in the array
//
Function AttributeIsIncludedInArray(AttributeName, AttributesArray)
	
	If TypeOf(AttributesArray) <> Type("Array") Then
		//@skip-check module-nstr-camelcase
		Raise StrTemplate(NStr("ru = 'Параметр %1 должен быть типа Массив';
								|vi = 'The %1 parameter must be of the Array type';
								|en = 'The %1 parameter must be of the Array type'; fa = 'The %1 parameter must be of the Array type';
								|it = 'The %1 parameter must be of the Array type';
								|pl = 'The %1 parameter must be of the Array type';
								|tr = '%1 parametresi Dizi türünde olmalıdır'"), AttributeName);
	EndIf;

	If TypeOf(AttributeName) <> Type("String") Then
		//@skip-check module-nstr-camelcase
		Raise StrTemplate(NStr("ru = 'Параметр %1 должен быть типа Строка';
								|vi = 'The %1 parameter must be of the String type';
								|en = 'The %1 parameter must be of the String type'; fa = 'The %1 parameter must be of the String type';
								|it = 'The %1 parameter must be of the String type';
								|pl = 'The %1 parameter must be of the String type';
								|tr = '%1 parametresi Dize türünde olmalıdır'"), AttributeName);
	EndIf;
	
	For Each Attribute In AttributesArray Do
		If Attribute["Name"] = AttributeName Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Procedure UpdateCrosstabOutputStructure(Form, Parameters)
	
	#Region ChangingFormDetails
	
	NameOfCrossTableProps = Parameters.NameOfCrossTableProps;
	CrossTableFormElement = Parameters.CrossTableFormElement;
	PeriodsTable 		 = Parameters.PeriodsTable;
	
	AttributesToBeAdded 	= New Array();
	AttributesToBeDeleted 		= New Array();
	TopLevelDetails = Form.GetAttributes();
	TableAttributes 		= Form.GetAttributes(NameOfCrossTableProps);
	
	DescriptionOfTypesTotals =  Parameters.TypeOfTotals;
	
	PredefinedDetails = Parameters.PredefinedDetails;
	For Each Attribute In TableAttributes Do 
		If StrFind(PredefinedDetails, Attribute.Name)=0 Then
			AttributesToBeDeleted.Add(NameOfCrossTableProps+"." + Attribute.Name);
		EndIf;
	EndDo;
	
	MatchingTopLevelDetails = New Map;
	For Each Attribute In TopLevelDetails Do
		MatchingTopLevelDetails.Insert(Attribute.Name, True);
	EndDo;
	
	MatchingTableAttributes = New Map;
	For Each Attribute In TableAttributes Do
		MatchingTableAttributes.Insert(Attribute.Name, True);
	EndDo;
	
	#Region CreatingPropsOutsideOfPeriods
	
	ParametersForUpdatingBankingDetails = New Structure;
	ParametersForUpdatingBankingDetails.Insert("MatchingTopLevelDetails", 	MatchingTopLevelDetails);
	ParametersForUpdatingBankingDetails.Insert("MatchingTableAttributes", 		MatchingTableAttributes);
	ParametersForUpdatingBankingDetails.Insert("AttributesToBeAdded", 					AttributesToBeAdded);
	ParametersForUpdatingBankingDetails.Insert("AttributesToBeDeleted", 					AttributesToBeDeleted);
	ParametersForUpdatingBankingDetails.Insert("NameOfCrossTableProps", 				NameOfCrossTableProps);
	
	For Each FieldStructure In Parameters.DimensionStructure Do
		
		If Not FieldStructure.Value.CreateOutsidePeriods Then
			Continue;
		EndIf;
		
		DimensionsCounter=0;
		For Each Dimension In FieldStructure.Value.DimensionComposition Do
			DimensionsCounter= DimensionsCounter+1;
			
			ParametersForUpdatingBankingDetails.Insert("Type", FieldStructure.Value.TypeOutsidePeriods);
			AttributeName = "Dimension"+DimensionsCounter;
			CreateUpdateBankingDetails(ParametersForUpdatingBankingDetails, AttributeName, True, Dimension.Presentation, True);
			
			ParametersForUpdatingBankingDetails.Insert("Type", DescriptionOfTypesTotals);
			AttributeName = "ColumnSummary_"+"_Dimension"+DimensionsCounter;
			CreateUpdateBankingDetails(ParametersForUpdatingBankingDetails, AttributeName, False, Dimension.Presentation);
			
			If Parameters.DetailedResults Then
				TotalCounter=0;
				For Each TotalStructure In Parameters.StructureOfResults Do 
					TotalCounter = TotalCounter+1;
					AttributeName = "ColumnSummary_"+TotalCounter+"_Dimension"+DimensionsCounter;
					CreateUpdateBankingDetails(ParametersForUpdatingBankingDetails, AttributeName, False, Dimension.Presentation);
					Title = ?(TotalStructure.Value.UsePresentation, Dimension.Presentation, TotalStructure.Value.SummaryHeader);
					
					AttributeName = "LineSummary"+TotalCounter+"_Dimension"+DimensionsCounter;
					CreateUpdateBankingDetails(ParametersForUpdatingBankingDetails, AttributeName, True, Dimension.Presentation);
					
					AttributeName = "OverallTotalByLine"+TotalCounter+"_Dimension"+DimensionsCounter;
					CreateUpdateBankingDetails(ParametersForUpdatingBankingDetails, AttributeName, False, Title);
				EndDo;
			EndIf;
		EndDo;
		
		If Not Parameters.DetailedResults Then
			ParametersForUpdatingBankingDetails.Insert("Type", DescriptionOfTypesTotals);
			TotalCounter=0;
			For Each TotalStructure In Parameters.StructureOfResults Do 
				TotalCounter = TotalCounter+1;
				Title = TotalStructure.Value.SummaryHeader;
				AttributeName = "LineSummary"+TotalCounter;
				CreateUpdateBankingDetails(ParametersForUpdatingBankingDetails, AttributeName, True, Title);
				
				AttributeName = "OverallTotalByLine"+TotalCounter;
				CreateUpdateBankingDetails(ParametersForUpdatingBankingDetails, AttributeName, False, Title);
			EndDo;
		EndIf;
	EndDo;
	
	#EndRegion	
	
	#Region CreatingAttributesByPeriod
	
	For Each FieldStructure In Parameters.DimensionStructure Do
		If Not FieldStructure.Value.CreateWithinPeriods Then
			Continue;
		EndIf;
		
		DimensionsCounter = 0;
		For Each Dimension In FieldStructure.Value.DimensionComposition Do
			DimensionsCounter = DimensionsCounter + 1;
			For Each PeriodString_ In PeriodsTable Do
				If DimensionsCounter>1 And FieldStructure.Value.LimitWithinPeriods Then
					Continue;
				EndIf;
				
				ParametersForUpdatingBankingDetails.Insert("Type", FieldStructure.Value.TypeWithinPeriods);
				AttributeName = "Dimension"+DimensionsCounter +"_"+ PeriodString_.ColumnName;
				CreateUpdateBankingDetails(ParametersForUpdatingBankingDetails, AttributeName, True, Dimension.Presentation, True);
				
				ParametersForUpdatingBankingDetails.Insert("Type", DescriptionOfTypesTotals);
				AttributeName = "ColumnSummary_"+"_Dimension"+DimensionsCounter +"_"+ PeriodString_.ColumnName;
				CreateUpdateBankingDetails(ParametersForUpdatingBankingDetails, AttributeName, False, Dimension.Presentation);
			EndDo;
			
			If Parameters.DetailedResults Then
				TotalCounter=0;
				For Each TotalStructure In Parameters.StructureOfResults Do 
					TotalCounter = TotalCounter+1;
					AttributeName = "LineSummary"+TotalCounter+"_Dimension"+DimensionsCounter;
					If AttributesToBeAdded.Find(AttributeName) = Undefined Then
						CreateUpdateBankingDetails(ParametersForUpdatingBankingDetails, AttributeName, True, Dimension.Presentation);
					EndIf;
					
					AttributeName = "OverallTotalByLine"+TotalCounter+"_Dimension"+DimensionsCounter;
					If AttributesToBeAdded.Find(AttributeName) = Undefined Then
						CreateUpdateBankingDetails(ParametersForUpdatingBankingDetails, AttributeName, False, Title);
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		
		If Not Parameters.DetailedResults Then
			ParametersForUpdatingBankingDetails.Insert("Type", DescriptionOfTypesTotals);
			TotalCounter=0;
			For Each TotalStructure In Parameters.StructureOfResults Do 
				TotalCounter = TotalCounter+1;
				Title = TotalStructure.Value.SummaryHeader;
				AttributeName = "LineSummary"+TotalCounter;
				CreateUpdateBankingDetails(ParametersForUpdatingBankingDetails, AttributeName, True, Title);
				
				AttributeName = "OverallTotalByLine"+TotalCounter;
				CreateUpdateBankingDetails(ParametersForUpdatingBankingDetails, AttributeName, False, Title);
			EndDo;
		EndIf;
	EndDo;
	
	#EndRegion
	
	Form.ChangeAttributes(AttributesToBeAdded, AttributesToBeDeleted);
	#EndRegion
	
	#Region ChangingFormElements
	
	If Not ValueIsFilled(CrossTableFormElement) Then
		Return;
	EndIf;
	
	#Region DeletingUnusedFormElements
	
	ItemsToRemove = New Array();
	CrossTable = Form.Items[CrossTableFormElement];
	
	ItemsToRemove = New Array();
	CrossTable = Form.Items[CrossTableFormElement];
	For Each CurItem In CrossTable.ChildItems Do
		ElementFound_ = False;
		For Each PeriodString_ In PeriodsTable Do
			If StrFind(CurItem.Name, CrossTableFormElement + "Group_"+PeriodString_.ColumnName) Then
				ItemsToRemove.Add(CurItem);
				ElementFound_ = True;
				Break;
			EndIf;
		EndDo;
		If ElementFound_ Then
			Continue;
		EndIf;
		
		If CurItem.Name = NameOfCrossTableProps+"GroupFixedColumn" Then
			For Each CurItem2 In CurItem.ChildItems Do
				If CurItem2.Name = NameOfCrossTableProps+"GroupSelectedDimensions" Then
					For Each CurItem3 In CurItem2.ChildItems Do
						ItemsToRemove.Add(CurItem3);
					EndDo;
				EndIf;
			EndDo;
		EndIf;
		
		If CurItem.Name = NameOfCrossTableProps+"TotalGroup" Then
			For Each CurItem2 In CurItem.ChildItems Do
				ItemsToRemove.Add(CurItem2);
			EndDo;
		EndIf;
		
		If StrFind(CurItem.Name, "Dimension") > 0 Then
			ItemsToRemove.Add(CurItem);
		EndIf;
	EndDo;
	
	For Each ItemToRemove In ItemsToRemove Do
		Form.Items.Delete(ItemToRemove);
	EndDo;
	
	#EndRegion
	
	#Region CreatingItemsOutsideOfPeriods
	
	FieldOwner = Form.Items[CrossTableFormElement];
	GroupOutsidePeriod = Form.Items.Find(Parameters.GroupSelectedDimensions);
	
	DimensionsCounter = 0;
	For Each FieldStructure In Parameters.DimensionStructure Do
		If Not FieldStructure.Value.CreateOutsidePeriods Then
			Continue;
		EndIf;
		DimensionsCounter = DimensionsCounter+1;
		GroupOutsidePeriod.Title 			= FieldStructure.Value.GroupPresentation;
		GroupOutsidePeriod.ShowInHeader 	= ValueIsFilled(GroupOutsidePeriod.Title);
		GroupOutsidePeriod.ReadOnly		= FieldStructure.Value.OnlyViewOutsidePeriods;
		ThereIsAddColumn = FieldStructure.Value.Property("AdditionalColumn");
		If FieldStructure.Value.Count>1 Then
			GroupOutsidePeriod = Form.Items.Find(CrossTableFormElement + "DimensionGroup_"+DimensionsCounter);
			If GroupOutsidePeriod = Undefined Then
				GroupOutsidePeriod = Form.Items.Add(CrossTableFormElement + "DimensionGroup_"+DimensionsCounter,
				Type("FormGroup"), Form.Items[Parameters.GroupSelectedDimensions]);
			EndIf;
			GroupOutsidePeriod.ShowInHeader 	= False;
			GroupOutsidePeriod.Group 		= FieldStructure.Value.GroupingOutsidePeriods;
		EndIf;
		GroupOutsidePeriod.FixingInTable 	= ?(GroupOutsidePeriod.Group =
		ColumnsGroup.Vertical, FixingInTable.None, GroupOutsidePeriod.FixingInTable);
		
		CompositionAccount=0;
		For Each Dimension In FieldStructure.Value.DimensionComposition Do
			CompositionAccount = CompositionAccount+1;
			
			If ThereIsAddColumn Then
				AdditionalParent = Form.Items.Find(CrossTableFormElement + "AdditionalDimensionGroup_"+CompositionAccount);
				If AdditionalParent = Undefined Then
					AdditionalParent = Form.Items.Add(CrossTableFormElement + "AdditionalDimensionGroup_"+CompositionAccount,
					Type("FormGroup"), GroupOutsidePeriod);
				EndIf;
				AdditionalParent.ShowInHeader = False;
				AdditionalParent.Group = ColumnsGroup.InCell;
			EndIf;
			
			Item = Form.Items.Find(CrossTableFormElement + "Dimension"+CompositionAccount);
			If Item = Undefined Then
				Item = Form.Items.Add(CrossTableFormElement + "Dimension"+CompositionAccount, Type("FormField"),
				?(ThereIsAddColumn, AdditionalParent, GroupOutsidePeriod));
				Item.Type = FormFieldType.InputField;
				Item.DataPath = NameOfCrossTableProps+".Dimension"+ CompositionAccount;
			EndIf;
			Item.Title = Dimension.Presentation;
			Item.ShowInHeader = FieldStructure.Value.DisplayInHeaderOutsideOfPeriods;
			Item.FooterDataPath = NameOfCrossTableProps+"ColumnSummary_"+"_Dimension"+CompositionAccount;
			If FieldStructure.Value.Property("ItemProperties")
			And TypeOf(FieldStructure.Value.ItemProperties) = Type("Structure") Then
				FillPropertyValues(Item, FieldStructure.Value.ItemProperties);
			EndIf;
			
			// Unit
			If FieldStructure.Value.Property("AdditionalColumn") Then
				TagName = NameOfCrossTableProps+FieldStructure.Value.AdditionalColumn.ColumnName+CompositionAccount;
				Item = Form.Items.Find(TagName);
				If Item = Undefined Then 
					Item = Form.Items.Add(TagName, Type("FormField"), AdditionalParent);
					Item.Type = FormFieldType.InputField;
					Item.DataPath =
					NameOfCrossTableProps+".Dimension"+ CompositionAccount+"."+FieldStructure.Value.AdditionalColumn.Path;
					FillPropertyValues(Item, FieldStructure.Value.AdditionalColumn);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	#EndRegion
	
	#Region CreatingElementsWithinPeriods
	
	For Each FieldStructure In Parameters.DimensionStructure Do 
		If Not FieldStructure.Value.CreateWithinPeriods Then
			Continue;
		EndIf;
		
		For Each PeriodString_ In PeriodsTable Do 
			GroupName = CrossTableFormElement + "Group_"+PeriodString_.ColumnName;
			PeriodGroup_ = Form.Items.Find(GroupName);
			If PeriodGroup_ = Undefined Then
				PeriodGroup_ = Form.Items.Add(CrossTableFormElement + "Group_"+PeriodString_.ColumnName, 
				Type("FormGroup"), FieldOwner);
			EndIf;
			PeriodGroup_.Group		= FieldStructure.Value.GroupingWithinPeriods;
			PeriodGroup_.Title			= PeriodString_.DateAsString;
			PeriodGroup_.ShowInHeader	= ValueIsFilled(PeriodGroup_.Title);
			PeriodGroup_.ReadOnly	= FieldStructure.Value.OnlyViewInsidePeriods;
			PeriodGroup_.HeaderHorizontalAlign = ItemHorizontalLocation.Center;
			
			DimensionsCounter=0;
			For Each Dimension In FieldStructure.Value.DimensionComposition Do
				DimensionsCounter = DimensionsCounter+1;
				If DimensionsCounter>1 And FieldStructure.Value.LimitWithinPeriods Then
					Continue;
				EndIf;
				Item = Form.Items.Add(CrossTableFormElement +"Dimension"+DimensionsCounter+"_"+PeriodString_.ColumnName, 
				Type("FormField"), PeriodGroup_);
				Item.Title = Dimension.Presentation;
				Item.ShowInHeader = FieldStructure.Value.DisplayInHeaderWithinPeriods;
				Item.DataPath = NameOfCrossTableProps+".Dimension"+DimensionsCounter+"_"+PeriodString_.ColumnName;
				Item.FooterDataPath = 
				NameOfCrossTableProps+"ColumnSummary_"+"_Dimension"+DimensionsCounter+"_"+PeriodString_.ColumnName;
				Item.Type = FormFieldType.InputField;
				If FieldStructure.Value.Property("ItemProperties") 
				And TypeOf(FieldStructure.Value.ItemProperties) = Type("Structure") Then
					FillPropertyValues(Item, FieldStructure.Value.ItemProperties);
					If FieldStructure.Value.ItemProperties.ListChoiceMode Then
						Item.ChoiceList.LoadValues(FieldStructure.Value.DimensionComposition.UnloadValues());
					EndIf;	
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	#EndRegion 
	
	#Region CreatingSummaryItems
	
	// Line totals + total 
	ParentGroupSummary = Form.Items[Parameters.ParentGroupSummary];
	TotalsGroup = ParentGroupSummary;
	TotalsGroup.Group = Parameters.GroupingTotals;
	
	If Parameters.DetailedResults Then
		For Each FieldStructure In Parameters.DimensionStructure Do
			DimensionsCounter=0;
			For Each Dimension In FieldStructure.Value.DimensionComposition Do
				DimensionsCounter= DimensionsCounter+1;
				If Parameters.NumberOfMeasurements>1 Then
					TotalsGroup = Form.Items.Find(CrossTableFormElement + "TotalsGroup"+DimensionsCounter);
					If TotalsGroup = Undefined Then
						TotalsGroup = Form.Items.Add(
						CrossTableFormElement + "TotalsGroup"+DimensionsCounter, Type("FormGroup"), ParentGroupSummary);
					EndIf;
					TotalsGroup.Group = ColumnsGroup.Horizontal;
					TotalsGroup.Title = NStr("ru = 'Итог';
											|vi = 'Total';
											|en = 'Total'; fa = 'جمع کل';
											|it = 'Total';
											|pl = 'Total';
											|tr = 'Toplam'");
					TotalsGroup.ShowInHeader = FieldStructure.Value.DisplayGroupOfTotalsInHeader;
				EndIf;
				
				TotalCounter=0;
				For Each TotalStructure In Parameters.StructureOfResults Do
					TotalCounter = TotalCounter+1;
					TagName = NameOfCrossTableProps + "LineSummary"+TotalCounter+"_Dimension"+DimensionsCounter;
					Item = Form.Items.Find(TagName);
					Title = ?(TotalStructure.Value.UsePresentation, 
					Dimension.Presentation, TotalStructure.Value.SummaryHeader);
					If Not Item = Undefined Then 
						Item.Title = Title;
						Item.ShowInHeader =
						Parameters.GroupingTotals = ColumnsGroup.Horizontal Or DimensionsCounter<2;
						Continue;
					EndIf;
					Item = Form.Items.Add(TagName, Type("FormField"), TotalsGroup);
					FillPropertyValues(Item, TotalStructure.Value);
					Item.DataPath = NameOfCrossTableProps+"."+"LineSummary"+TotalCounter+"_Dimension"+DimensionsCounter;
					Item.FooterDataPath = NameOfCrossTableProps+"OverallTotalByLine"+TotalCounter+"_Dimension"+DimensionsCounter;
					Item.Title = Title;
					Item.ShowInHeader =
					Parameters.GroupingTotals = ColumnsGroup.Horizontal Or DimensionsCounter<2;
				EndDo;
			EndDo;
		EndDo;	
	Else  
		DimensionsCounter=0;
		For Each FieldStructure In Parameters.DimensionStructure Do
			DimensionsCounter= DimensionsCounter+1;
			If Parameters.NumberOfMeasurements>1 Then
				TotalsGroup = Form.Items.Find(CrossTableFormElement + "TotalsGroup"+DimensionsCounter);
				If TotalsGroup = Undefined Then
					TotalsGroup = Form.Items.Add(
					CrossTableFormElement + "TotalsGroup"+DimensionsCounter, Type("FormGroup"), ParentGroupSummary);
				EndIf;
				TotalsGroup.Group = Parameters.GroupingTotals;
				TotalsGroup.Title = NStr("ru = 'Итог';
										|vi = 'Total';
										|en = 'Total'; fa = 'جمع کل';
										|it = 'Total';
										|pl = 'Total';
										|tr = 'Toplam'");
				TotalsGroup.ShowInHeader = False;
			EndIf;
			
			TotalCounter=0;
			For Each TotalStructure In Parameters.StructureOfResults Do 
				TotalCounter = TotalCounter+1;
				TagName = NameOfCrossTableProps + "LineSummary"+TotalCounter;
				Item = Form.Items.Find(TagName);
				Title = TotalStructure.Value.SummaryHeader;
				If Not Item = Undefined Then 
					Item.Title = Title;
					Item.ShowInHeader = ?(DimensionsCounter=1, ValueIsFilled(Title), False);
					Continue;
				EndIf;
				Item = Form.Items.Add(TagName, Type("FormField"), TotalsGroup);
				FillPropertyValues(Item, TotalStructure.Value);
				Item.DataPath = NameOfCrossTableProps+"."+"LineSummary"+TotalCounter;
				Item.FooterDataPath = NameOfCrossTableProps+"OverallTotalByLine"+TotalCounter;
				Item.Title = Title;
				Item.ShowInHeader = DimensionsCounter<2 And ValueIsFilled(Title);
			EndDo;
		EndDo;
	EndIf;
	
	#EndRegion
	
	#EndRegion
	
EndProcedure

Function CrossTableConversionParameters(Form)
	
	TablePeriods = Form.FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	
	StructureOfPeriodDetails = New Structure("Date","Date");
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Dimension",?(StrFind(Form.FormName, "TimesheetHR")>0, "TimeKind", "WorkScheduleCalendar"));
	
	GroupFields = "LineNumberEmployee, Employee";
	
	ConversionParameters = New Structure;
	ConversionParameters.Insert("TablePeriods",              TablePeriods);
	ConversionParameters.Insert("StructureOfPeriodDetails",  StructureOfPeriodDetails);
	ConversionParameters.Insert("AttributesStructure1",         AttributesStructure1);
	ConversionParameters.Insert("GroupFields",             GroupFields);
	ConversionParameters.Insert("DocumentType", 				?(StrFind(Form.FormName, 
	"TimesheetHR")>0, "TimesheetHR", "ShiftScheduleHR"));
	ConversionParameters.Insert("ByDays", 						Form.ByDays);
	ConversionParameters.Insert("SelectedMeasurements", 			Form.SelectedMeasurements);
	ConversionParameters.Insert("MeasurementsData", 			Form.MeasurementsData);
	ConversionParameters.Insert("NumberOfMeasurements", 		Form.NumberOfMeasurements);
	ConversionParameters.Insert("BeginningDateOfPeriod", 			Form.Object.BeginningDateOfPeriod);
	ConversionParameters.Insert("EndingDateOfPeriod", 		Form.Object.EndingDateOfPeriod);
	
	Return ConversionParameters;
	
EndFunction

Procedure FillInTableFromCrossTable_ReportCard(TableObject_, CrossTable, Parameters)
	
	TablePeriods             = Parameters.TablePeriods;
	AttributesStructure1        = Parameters.AttributesStructure1;
	TotalRowsOfPeriodsTable   = TablePeriods.Count();
	
	ArrayOfRowsTableObject   = New Array;
	
	NewRowStructureObjectTable = New Structure();
	For Each Column In TableObject_.Unload(New Structure).Columns Do
		NewRowStructureObjectTable.Insert(Column.Name);
	EndDo;
	
	ConformityOfMeasurements = New Map;
	Counter = 1;
	For Each Dimension In Parameters.SelectedMeasurements Do
		ConformityOfMeasurements.Insert(Counter, Dimension.Value);
		Counter = Counter+1;
	EndDo;
	
	CounterOfCrossTableRows = 0;
	For Each CrossTableRow In CrossTable Do
		If Parameters.ByDays Then
			ArrayOfStringsIsEmpty = True;
			ThisIsServiceLine = False;
			For Each StringPeriod In TablePeriods Do
				
				For DimensionsCounter=1 To Parameters.SelectedMeasurements.Count() Do
					CurMeasurement_ = CrossTableRow["Dimension"+DimensionsCounter];
					MeaningDimension1 = CrossTableRow["Dimension"+DimensionsCounter+"_"+StringPeriod.ColumnName];
					
					If Not ValueIsFilled(CurMeasurement_) Or Not ValueIsFilled(MeaningDimension1) Then
						// Adding a service line so that lines without data do not disappear from the document
						If StringPeriod.ColumnNumber = TotalRowsOfPeriodsTable And ArrayOfStringsIsEmpty Then
							ThisIsServiceLine = True;
						Else
							Continue;
						EndIf;
					EndIf;
					
					NewRowObjectTable = Common.CopyRecursive(NewRowStructureObjectTable);
					FillPropertyValues(NewRowObjectTable,CrossTableRow);
					
					NewRowObjectTable.LineNumberEmployee  = CounterOfCrossTableRows;
					NewRowObjectTable[AttributesStructure1.Dimension] = CurMeasurement_;
					NewRowObjectTable["Date"] = StringPeriod.Date;
					
					DimensionData = Parameters.MeasurementsData.Get(DimensionsCounter-1);
					If DimensionData.UnitOfMeasure = Enums.TimeMeasureUnits.Hour Then 
						NewRowObjectTable["Hours1"] = MeaningDimension1;
						NewRowObjectTable["Days"] = ?(ThisIsServiceLine, 0, 1);
					Else 
						NewRowObjectTable["Hours1"] = MeaningDimension1*DimensionData.NumberOfHoursPerDay;
						NewRowObjectTable["Days"]  = MeaningDimension1;
					EndIf;
					ArrayOfRowsTableObject.Add(NewRowObjectTable);
					ArrayOfStringsIsEmpty = False;
				EndDo;
			EndDo;
			
		Else 
			For DimensionsCounter=1 To Parameters.SelectedMeasurements.Count() Do
				NewRowObjectTable = Common.CopyRecursive(NewRowStructureObjectTable);
				FillPropertyValues(NewRowObjectTable, CrossTableRow);
				NewRowObjectTable.LineNumberEmployee  = CounterOfCrossTableRows;
				NewRowObjectTable["TimeKind"] = ConformityOfMeasurements.Get(DimensionsCounter);	
				NewRowObjectTable["Date"] = Parameters.EndingDateOfPeriod;
				DimensionData = Parameters.MeasurementsData.Get(DimensionsCounter-1);
				If DimensionData.UnitOfMeasure = Enums.TimeMeasureUnits.Hour Then 
					NewRowObjectTable["Hours1"] = CrossTableRow["Dimension"+DimensionsCounter];
					NewRowObjectTable["Days"] = 0;
				Else 
					NewRowObjectTable["Hours1"] = CrossTableRow["Dimension"+DimensionsCounter]*DimensionData.NumberOfHoursPerDay;
					NewRowObjectTable["Days"]  = CrossTableRow["Dimension"+DimensionsCounter];
				EndIf;
				ArrayOfRowsTableObject.Add(NewRowObjectTable);
			EndDo;	
		EndIf;
		
		CounterOfCrossTableRows = CounterOfCrossTableRows+1;
	EndDo;
	
	TableObject_.Clear();
	For Each String In ArrayOfRowsTableObject Do
		If ValueIsFilled(String[AttributesStructure1.Dimension]) Then
			FillPropertyValues(TableObject_.Add(), String);
		EndIf;
	EndDo;
	
EndProcedure 

Procedure FillInTableFromCrossTable_ReportCardOneEmployeeByDay(TableObject_, CrossTable, Parameters)

	AttributesStructure1      = Parameters.AttributesStructure1;
	
	ArrayOfRowsTableObject = New Array;
	
	NewRowStructureObjectTable = New Structure();
	For Each Column In TableObject_.Unload(New Structure).Columns Do
		NewRowStructureObjectTable.Insert(Column.Name);
	EndDo;
	
	ConformityOfMeasurements = New Map;
	Counter = 1;
	For Each Dimension In Parameters.SelectedMeasurements Do
		ConformityOfMeasurements.Insert(Counter, Dimension.Value);
		Counter = Counter+1;
	EndDo;
	
	CounterOfCrossTableRows = 0;
	For Each CrossTableRow In CrossTable Do  
		For DimensionsCounter=1 To Parameters.SelectedMeasurements.Count() Do
			If Not ValueIsFilled(CrossTableRow["Dimension"+DimensionsCounter]) Then
				Continue;
			EndIf;
			NewRowObjectTable = Common.CopyRecursive(NewRowStructureObjectTable);
			FillPropertyValues(NewRowObjectTable, CrossTableRow);
			NewRowObjectTable.LineNumberEmployee = CounterOfCrossTableRows;
			NewRowObjectTable["TimeKind"] = ConformityOfMeasurements.Get(DimensionsCounter);
			NewRowObjectTable["Date"] = DetermineDateFromView(Parameters.ByDays, CrossTableRow.Date, Parameters.TablePeriods);
			DimensionData = Parameters.MeasurementsData.Get(DimensionsCounter-1);
			If DimensionData.UnitOfMeasure = Enums.TimeMeasureUnits.Hour Then 
				NewRowObjectTable["Hours1"] = CrossTableRow["Dimension"+DimensionsCounter];
				NewRowObjectTable["Days"] = 1;
			Else 
				NewRowObjectTable["Hours1"] = CrossTableRow["Dimension"+DimensionsCounter]*DimensionData.NumberOfHoursPerDay;
				NewRowObjectTable["Days"]  = CrossTableRow["Dimension"+DimensionsCounter];
			EndIf;
			ArrayOfRowsTableObject.Add(NewRowObjectTable);
		EndDo;	
		CounterOfCrossTableRows = CounterOfCrossTableRows+1;
	EndDo;
	
	TableObject_.Clear();
	For Each String In ArrayOfRowsTableObject Do
		If ValueIsFilled(String[AttributesStructure1.Dimension]) Then
			NewRow = TableObject_.Add();
			FillPropertyValues(NewRow, String);
			NewRow.Employee = Parameters.Employee;
		EndIf;
	EndDo;
	
EndProcedure

Function DetermineDateFromView(ByDays, DateAsString, TablePeriods)
	
	If ByDays Then  
		TheStructureOfTheSearch = New Structure("DateDayOfWeekString", DateAsString);
	Else
		TheStructureOfTheSearch = New Structure("Date", Date(DateAsString));
	EndIf;
	RowsArray = TablePeriods.FindRows(TheStructureOfTheSearch);
	If RowsArray.Count()>0 Then
		Return RowsArray[0].Date;
	Else
		Return Date(1,1,1);
	EndIf;
	
EndFunction

Procedure FillInTableFromCrossTable_ShiftSchedule(TableObject_, CrossTable, Parameters)
	
	TablePeriods			= Parameters.TablePeriods;
	AttributesStructure1		= Parameters.AttributesStructure1;
	
	ArrayOfRowsTableObject = New Array;
	
	NewRowStructureObjectTable = New Structure();
	For Each Column In TableObject_.Unload(New Structure).Columns Do
		NewRowStructureObjectTable.Insert(Column.Name);
	EndDo;
	
	ConformityOfMeasurements = New Map;
	Counter = 1;
	For Each Dimension In Parameters.SelectedMeasurements Do
		ConformityOfMeasurements.Insert(Counter, Dimension.Value);
		Counter = Counter+1;
	EndDo;
	
	CounterOfCrossTableRows = 0;
	NumberOfMeasurements = ?(Parameters.ByDays, 1, Parameters.NumberOfMeasurements);
	EmployeesWithData = New Array;
	For Each CrossTableRow In CrossTable Do  
		For DimensionsCounter=1 To NumberOfMeasurements Do
			For Each StringPeriod In TablePeriods Do
				MeaningDimension = CrossTableRow["Dimension"+DimensionsCounter+"_"+StringPeriod.ColumnName];
				If Not ValueIsFilled(MeaningDimension) Or MeaningDimension = False Then
					// Adding a service line so that lines without data do not disappear from the document
					If StringPeriod.ColumnNumber>1 Then
						Continue;
					EndIf;
				EndIf;
				
				NewRowObjectTable = Common.CopyRecursive(NewRowStructureObjectTable);
				FillPropertyValues(NewRowObjectTable,CrossTableRow);
				
				NewRowObjectTable.LineNumberEmployee  = CounterOfCrossTableRows;
				If Parameters.ByDays Then
					NewRowObjectTable[AttributesStructure1.Dimension] = MeaningDimension;
				Else
					NewRowObjectTable[AttributesStructure1.Dimension] = 
					?(MeaningDimension, ConformityOfMeasurements[DimensionsCounter], Catalogs.Calendars.EmptyRef());
				EndIf;
				If ValueIsFilled(NewRowObjectTable[AttributesStructure1.Dimension]) Then
					EmployeesWithData.Add(NewRowObjectTable.Employee);
				EndIf;
				NewRowObjectTable["Date"] = StringPeriod.Date;
				ArrayOfRowsTableObject.Add(NewRowObjectTable);
			EndDo;
		EndDo;
		CounterOfCrossTableRows = CounterOfCrossTableRows+1;
	EndDo;
	
	TableObject_.Clear();
	For Each String In ArrayOfRowsTableObject Do  
		If ValueIsFilled(String[AttributesStructure1.Dimension]) Then
			FillPropertyValues(TableObject_.Add(), String);
		Else
			// There is no need to add an empty row if there is at least one non-empty entry
			If EmployeesWithData.Find(String.Employee) = Undefined Then
				FillPropertyValues(TableObject_.Add(), String);
			EndIf;
		EndIf
	EndDo;
	TableObject_.Sort("LineNumberEmployee, Date");
	
EndProcedure 

// Converting a Table to a Cross-table with transferring the values of the period details to the columns of the cross-table.
//
// Parameters:
//   Form - ClientApplicationForm - the form in which the cross-table is located
//   CrossTable - ValueTable - cross-table to fill in
//   Table - ValueTable, FormTable - table with time data
//   Parameters - Structure - parameters for filling in the cross-table
Procedure FillInCrossTableFromTable_ReportCardForSeveralEmployees(Form, CrossTable, Table, Parameters) 
	
	Query = New Query;
	Query.Text = QueryTextForCompletingCrossTable_ReportCardForSeveralEmployees();
	Query.SetParameter("Organization", 		Parameters.Organization);
	Query.SetParameter("Period", 			Parameters.Period);
	Query.SetParameter("SelectedMeasurements", Parameters.SelectedMeasurements.UnloadValues());
	
	If TypeOf(Table) = Type("ValueTable") Then
		Query.SetParameter("DataOnTime", Table);
	Else
		Query.SetParameter("DataOnTime", Table.Unload());
	EndIf;
	Query.SetParameter("DataByPeriods", Parameters.TablePeriods);
	QueryResult = Query.Execute();
	
	CrossTable.Clear();
	
	DimensionNumbers = New Map;
	DimensionsCounter = 1;
	For Each Dimension In Parameters.SelectedMeasurements Do
		DimensionNumbers.Insert(Dimension.Value, DimensionsCounter);
		DimensionsCounter = DimensionsCounter+1;
	EndDo;
	
	FetchingLineNumbers = QueryResult.Select(QueryResultIteration.ByGroups);
	While FetchingLineNumbers.Next() Do 
		NewLineCross = CrossTable.Add();
		
		If Parameters.ByDays Then
			For Each KeyAndValue In DimensionNumbers Do
				NewLineCross["Dimension"+KeyAndValue.Value] = KeyAndValue.Key;
			EndDo;
		EndIf;
		Selection = FetchingLineNumbers.Select();
		While Selection.Next() Do
			FillPropertyValues(NewLineCross, Selection);
			If Not ValueIsFilled(Selection.Dimension) Then
				Continue;
			EndIf;
			DimensionData = Parameters.MeasurementsData[DimensionNumbers[Selection.Dimension]-1];
			ColumnNameDimension= "Dimension"+DimensionNumbers[Selection.Dimension];
			
			If Parameters.ByDays Then
				If DimensionData.UnitOfMeasure = Enums.TimeMeasureUnits.Hour Then
					NewLineCross[ColumnNameDimension+"_"+Selection.ColumnName] = Selection.Hours1;
					If DimensionData.WorkingTime Then
						NewLineCross["LineSummary"+"1_"+ColumnNameDimension] =
						NewLineCross["LineSummary"+"1_"+ColumnNameDimension] + Selection.Hours1;
					EndIf;
				Else
					NewLineCross[ColumnNameDimension+"_"+Selection.ColumnName] = Selection.Days;
					If DimensionData.WorkingTime Then
						NewLineCross["LineSummary"+"1_"+ColumnNameDimension] =
						NewLineCross["LineSummary"+"1_"+ColumnNameDimension] + Selection.Days*DimensionData.NumberOfHoursPerDay;
						NewLineCross["LineSummary"+"2_"+ColumnNameDimension] =
						NewLineCross["LineSummary"+"2_"+ColumnNameDimension] + Selection.Days;
					EndIf;
				EndIf;
			Else
				If DimensionData.UnitOfMeasure = Enums.TimeMeasureUnits.Hour Then
					NewLineCross[ColumnNameDimension] = NewLineCross[ColumnNameDimension] + Selection.Hours1;
					If DimensionData.WorkingTime Then
						NewLineCross["LineSummary"+"1"] = NewLineCross["LineSummary"+"1"] + Selection.Hours1;
					EndIf;
				Else
					NewLineCross[ColumnNameDimension] = NewLineCross[ColumnNameDimension] + Selection.Days;
					If DimensionData.WorkingTime Then
						NewLineCross["LineSummary"+"1"] = 
						NewLineCross["LineSummary"+"1"] + Selection.Days*DimensionData.NumberOfHoursPerDay;
						NewLineCross["LineSummary"+"2"] = 
						NewLineCross["LineSummary"+"2"] + Selection.Days;
					EndIf;
				EndIf;	
			EndIf;	
		EndDo;
	EndDo;
	
	If Parameters.ByDays Then
		For DimensionsCounter=1 To Parameters.NumberOfMeasurements Do 
			Form["ScheduleByDate"+"OverallTotalByLine"+"1"+"_Dimension"+DimensionsCounter] = 
			CrossTable.Total("LineSummary"+"1"+"_Dimension"+DimensionsCounter);
			Form["ScheduleByDate"+"OverallTotalByLine"+"2"+"_Dimension"+DimensionsCounter] = 
			CrossTable.Total("LineSummary"+"2"+"_Dimension"+DimensionsCounter);
			
			For Each StringPeriod In Parameters.TablePeriods Do  
				Form["ScheduleByDate"+"ColumnSummary_"+"_Dimension"+DimensionsCounter+"_"+StringPeriod.ColumnName] = 
				CrossTable.Total("Dimension"+DimensionsCounter+"_"+StringPeriod.ColumnName);
			EndDo;
		EndDo;
	Else
		Form["ScheduleByDate"+"OverallTotalByLine"+"1"] = CrossTable.Total("LineSummary"+"1");
		Form["ScheduleByDate"+"OverallTotalByLine"+"2"] = CrossTable.Total("LineSummary"+"2");
		For CompositionAccount=1 To Parameters.SelectedMeasurements.Count() Do 
			Form["ScheduleByDate"+"ColumnSummary_"+"_Dimension"+CompositionAccount]	=  CrossTable.Total("Dimension"+CompositionAccount);
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillInCrossTableFromTable_ReportCardForOneEmployee(Form, CrossTable, Table, Parameters) 
	
	Query = New Query;
	If Parameters.ByDays Then
		Query.Text = QueryTextForCompletingCrossTable_ReportCardForOneEmployeeByDay();
	Else
		Query.Text = QueryTextForFillingInCrossTable_ReportCardForOneEmployeeInSummary();
	EndIf;
	Query.SetParameter("Organization", 		Parameters.Organization);
	Query.SetParameter("Period", 			Parameters.Period);
	Query.SetParameter("SelectedMeasurements", Parameters.SelectedMeasurements.UnloadValues());
	Query.SetParameter("Employee", 			Parameters.Employee);
	
	If TypeOf(Table) = Type("ValueTable") Then
		Query.SetParameter("DataOnTime", Table);
	Else
		Query.SetParameter("DataOnTime", Table.Unload());
	EndIf;
	Query.SetParameter("DataByPeriods", Parameters.TablePeriods);
	QueryResult = Query.Execute();
	
	CrossTable.Clear();
	
	DimensionNumbers = New Map;
	DimensionsCounter = 1;
	For Each Dimension In Parameters.SelectedMeasurements Do
		DimensionNumbers.Insert(Dimension.Value, DimensionsCounter);
		DimensionsCounter = DimensionsCounter+1;
	EndDo;
	
	If Parameters.ByDays Then 
		SelectionByDay = QueryResult.Select(QueryResultIteration.ByGroups);
		While SelectionByDay.Next() Do
			NewLineCross = CrossTable.Add();
			NewLineCross.Employee = Parameters.Employee;
			NewLineCross.Date = Format(SelectionByDay.Date, NStr("ru = 'ДФ=''дд.ММ''';
																|vi = 'DF=''MM/dd''';
																|en = 'DF=''MM/dd'''; fa = 'DF=''MM/dd''';
																|it = 'DF=''MM/dd''';
																|pl = 'DF=''MM/dd''';
																|tr = 'DF=''gg.AA'''"))
			+" ("+Format(SelectionByDay.Date, NStr("ru = 'ДФ=''ддд''';
													|vi = 'DF=''ddd''';
													|en = 'DF=''ddd'''; fa = 'DF=''ddd''';
													|it = 'DF=''ddd''';
													|pl = 'DF=''ddd''';
													|tr = 'DF=''ggg'''"))+".)";
			Selection = SelectionByDay.Select();
			While Selection.Next() Do
				If Not ValueIsFilled(Selection.Dimension) Then
					Continue;
				EndIf;
				DimensionData = Parameters.MeasurementsData[DimensionNumbers[Selection.Dimension]-1];
				ColumnNameDimension= "Dimension"+DimensionNumbers[Selection.Dimension];
				
				If DimensionData.UnitOfMeasure = Enums.TimeMeasureUnits.Hour Then
					NewLineCross[ColumnNameDimension] = NewLineCross[ColumnNameDimension] + Selection.Hours1;
					If DimensionData.WorkingTime Then
						NewLineCross["LineSummary"+"1"] = NewLineCross["LineSummary"+"1"] + Selection.Hours1;
					EndIf;
				Else 
					NewLineCross[ColumnNameDimension] = NewLineCross[ColumnNameDimension] + Selection.Days;
					If DimensionData.WorkingTime Then
						NewLineCross["LineSummary"+"1"] = 
						NewLineCross["LineSummary"+"1"] + Selection.Days*DimensionData.NumberOfHoursPerDay;
						NewLineCross["LineSummary"+"2"] = 
						NewLineCross["LineSummary"+"2"] + Selection.Days;
					EndIf;
				EndIf;
			EndDo;
		EndDo;
	Else
		Selection = QueryResult.Select();
		NewLineCross = CrossTable.Add();
		NewLineCross.Employee = Parameters.Employee;
		NewLineCross.Date = Parameters.Period;
		While Selection.Next() Do
			DimensionData = Parameters.MeasurementsData[DimensionNumbers[Selection.Dimension]-1];
			ColumnNameDimension= "Dimension"+DimensionNumbers[Selection.Dimension];
			
			If DimensionData.UnitOfMeasure = Enums.TimeMeasureUnits.Hour Then
				NewLineCross[ColumnNameDimension] = NewLineCross[ColumnNameDimension] + Selection.Hours1;
				If DimensionData.WorkingTime Then
					NewLineCross["LineSummary"+"1"] = NewLineCross["LineSummary"+"1"] + Selection.Hours1;
				EndIf;
			Else 
				NewLineCross[ColumnNameDimension] = NewLineCross[ColumnNameDimension] + Selection.Days;
				If DimensionData.WorkingTime Then
					NewLineCross["LineSummary"+"1"] = 
					NewLineCross["LineSummary"+"1"] + Selection.Days*DimensionData.NumberOfHoursPerDay;
					NewLineCross["LineSummary"+"2"] = 
					NewLineCross["LineSummary"+"2"] + Selection.Days;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	Form["ScheduleByDate"+"OverallTotalByLine"+"1"] = CrossTable.Total("LineSummary"+"1");
	Form["ScheduleByDate"+"OverallTotalByLine"+"2"] = CrossTable.Total("LineSummary"+"2");
	For CompositionAccount=1 To Parameters.SelectedMeasurements.Count() Do 
		Form["ScheduleByDate"+"ColumnSummary_"+"_Dimension"+CompositionAccount]	=  CrossTable.Total("Dimension"+CompositionAccount);
	EndDo;
	
EndProcedure

Procedure FillInCrossTableFromTable_ShiftSchedule(Form, CrossTable, Table, Parameters) 
	
	Query = New Query();
	If Parameters.ByDays Then
		Query.Text = QueryTextForFillingInCrossTable_ShiftScheduleByDay();
	Else
		Query.Text = QueryTextForFillingInCrossTable_ShiftScheduleByShift();
	EndIf;
	
	If GetFunctionalOption("UseMultipleCompanies") Then
		Query.Text = StrReplace(Query.Text, "FilterOrganization", "Organization = &Organization");
		Query.SetParameter("Organization", Parameters.Organization);
	Else
		Query.SetParameter("FilterOrganization", True);
	EndIf;
	
	Query.SetParameter("Period", 			EndOfDay(Parameters.Period));
	Query.SetParameter("SelectedMeasurements", Parameters.SelectedMeasurements.UnloadValues());
	If TypeOf(Table) = Type("ValueTable") Then
		Query.SetParameter("DataOnTime", Table);
	Else
		Query.SetParameter("DataOnTime", Table.Unload());
	EndIf;
	Query.SetParameter("DataByPeriods", Parameters.TablePeriods);
	QueryResult = Query.Execute();
	
	CrossTable.Clear();
	
	If Parameters.ByDays Then
		// When switching to the day mode from the shift mode, it is necessary to split the days into separate lines.
		FetchingLineNumbers = QueryResult.Select(QueryResultIteration.ByGroups);
		While FetchingLineNumbers.Next() Do
			DimensionSampling = FetchingLineNumbers.Select(QueryResultIteration.ByGroups);
			While DimensionSampling.Next() Do
				Selection = DimensionSampling.Select();
				NewLineCross = CrossTable.Add();
				While Selection.Next() Do
					FillPropertyValues(NewLineCross, Selection);
					NewLineCross["Dimension"+1+"_"+Selection.ColumnName] = Selection.Dimension;
					NewLineCross["LineSummary"+1] = NewLineCross["LineSummary"+1]+1;
					AttributeName = "ScheduleByDate"+"ColumnSummary_"+"_Dimension"+1+"_"+Selection.ColumnName;
					Form[AttributeName] = Form[AttributeName] + 1;
				EndDo;
				NewLineCross.LineNumber = CrossTable.Count();
			EndDo;
		EndDo;	 
		
		AttributeName = "ScheduleByDate"+"OverallTotalByLine"+1;
		ColumnName = "LineSummary"+1;
		Form[AttributeName] = CrossTable.Total(ColumnName);
	Else
		DimensionNumbers = New Map;
		DimensionsCounter = 1;
		For Each Dimension In Parameters.SelectedMeasurements Do
			DimensionNumbers.Insert(Dimension.Value, DimensionsCounter);
			DimensionsCounter = DimensionsCounter+1;
		EndDo;
		
		FetchingLineNumbers = QueryResult.Select(QueryResultIteration.ByGroups);
		LineCounter = 1;
		While FetchingLineNumbers.Next() Do 
			NewLineCross = CrossTable.Add();
			NewLineCross.LineNumber = LineCounter;
			DimensionSampling = FetchingLineNumbers.Select(QueryResultIteration.ByGroups);
			While DimensionSampling.Next() Do
				Selection = DimensionSampling.Select();
				While Selection.Next() Do
					FillPropertyValues(NewLineCross, Selection);
					RootOfName = "Dimension"+DimensionNumbers[DimensionSampling.Dimension];
					ColumnNameDimension= RootOfName+"_"+Selection.ColumnName;
					NewLineCross[ColumnNameDimension] = ?(ValueIsFilled(Selection.Dimension), True, False);
					NewLineCross["LineSummary"+1+"_"+RootOfName] = NewLineCross["LineSummary"+1+"_"+RootOfName]+ 1;
					AttributeName = "ScheduleByDate"+"ColumnSummary_"+"_"+RootOfName+"_"+Selection.ColumnName;
					Form[AttributeName] = Form[AttributeName] + 1;
				EndDo;
			EndDo;
			LineCounter = LineCounter + 1;
		EndDo;
		
		For DimensionsCounter=1 To Parameters.NumberOfMeasurements Do
			AttributeName = "ScheduleByDate"+"OverallTotalByLine"+1+"_Dimension"+DimensionsCounter;
			ColumnName = "LineSummary"+"1"+"_Dimension"+DimensionsCounter;
			Form[AttributeName] = CrossTable.Total(ColumnName);
		EndDo;
	EndIf;
	
EndProcedure

Function QueryTextForCompletingCrossTable_ReportCardForSeveralEmployees()
	
	Return "SELECT
	        |	DataOnTime.Date AS Date,
	        |	DataOnTime.Employee AS Employee,
	        |	DataOnTime.TimeKind AS Dimension,
	        |	DataOnTime.LineNumberEmployee AS LineNumberEmployee,
	        |	DataOnTime.Hours1 AS Hours1,
	        |	DataOnTime.Days AS Days
	        |INTO TT
	        |FROM
	        |	&DataOnTime AS DataOnTime
	        |WHERE
	        |	DataOnTime.TimeKind IN(&SelectedMeasurements)
	        |;
	        |
	        |////////////////////////////////////////////////////////////////////////////////
	        |SELECT
	        |	DataByPeriods.Date AS Date,
	        |	DataByPeriods.ColumnName AS ColumnName
	        |INTO TT_TimeIntervals
	        |FROM
	        |	&DataByPeriods AS DataByPeriods
	        |;
	        |
	        |////////////////////////////////////////////////////////////////////////////////
	        |SELECT
	        |	TT.LineNumberEmployee + 1 AS LineNumber,
	        |	TT.Employee AS Employee,
	        |	TT.Dimension AS Dimension,
	        |	TT.Date AS Date,
	        |	ISNULL(TT_TimeIntervals.ColumnName, """") AS ColumnName,
	        |	TT.LineNumberEmployee AS LineNumberEmployee,
	        |	EmployeesHR.Presentation AS LastFirstName,
	        |	EmployeesHR.Code AS EmployeeCode,
	        |	TT.Hours1 AS Hours1,
	        |	TT.Days AS Days
	        |FROM
	        |	TT AS TT
	        |		INNER JOIN TT_TimeIntervals AS TT_TimeIntervals
	        |		ON TT.Date = TT_TimeIntervals.Date
	        |		LEFT JOIN Catalog.EmployeesHR AS EmployeesHR
	        |		ON TT.Employee = EmployeesHR.Ref
	        |
	        |ORDER BY
	        |	LineNumberEmployee
	        |TOTALS BY
	        |	LineNumberEmployee";
	
EndFunction

Function QueryTextForCompletingCrossTable_ReportCardForOneEmployeeByDay()
	
	Return "SELECT
	        |	DataOnTime.Date AS Date,
	        |	DataOnTime.Employee AS Employee,
	        |	DataOnTime.TimeKind AS Dimension,
	        |	DataOnTime.LineNumberEmployee AS LineNumberEmployee,
	        |	DataOnTime.Hours1 AS Hours1,
	        |	DataOnTime.Days AS Days
	        |INTO TT
	        |FROM
	        |	&DataOnTime AS DataOnTime
	        |WHERE
	        |	DataOnTime.TimeKind IN(&SelectedMeasurements)
	        |	AND DataOnTime.Employee = &Employee
	        |;
	        |
	        |////////////////////////////////////////////////////////////////////////////////
	        |SELECT
	        |	DataByPeriods.Date AS Date,
	        |	DataByPeriods.DateDayOfWeekString AS DateDayOfWeekString,
	        |	DataByPeriods.ColumnName AS ColumnName
	        |INTO TT_TimeIntervals
	        |FROM
	        |	&DataByPeriods AS DataByPeriods
	        |;
	        |
	        |////////////////////////////////////////////////////////////////////////////////
	        |SELECT
	        |	TT.LineNumberEmployee + 1 AS LineNumber,
	        |	TT.Employee AS Employee,
	        |	TT.Dimension AS Dimension,
	        |	TT_TimeIntervals.Date AS Date,
	        |	ISNULL(TT_TimeIntervals.ColumnName, """") AS ColumnName,
	        |	TT.LineNumberEmployee AS LineNumberEmployee,
	        |	EmployeesHR.Presentation AS LastFirstName,
	        |	EmployeesHR.Code AS EmployeeCode,
	        |	TT.Hours1 AS Hours1,
	        |	TT.Days AS Days,
	        |	WEEKDAY(TT_TimeIntervals.Date) AS WeekDay,
	        |	TT_TimeIntervals.DateDayOfWeekString AS DateDayOfWeekString
	        |FROM
	        |	TT_TimeIntervals AS TT_TimeIntervals
	        |		LEFT JOIN TT AS TT
	        |			LEFT JOIN Catalog.EmployeesHR AS EmployeesHR
	        |			ON TT.Employee = EmployeesHR.Ref
	        |		ON (TT.Date = TT_TimeIntervals.Date)
	        |
	        |ORDER BY
	        |	Date
	        |TOTALS BY
	        |	Date";
	
EndFunction

Function QueryTextForFillingInCrossTable_ReportCardForOneEmployeeInSummary()
	
	Return "SELECT
	|	DataOnTime.Employee AS Employee,
	|	DataOnTime.TimeKind AS Dimension,
	|	DataOnTime.LineNumberEmployee AS LineNumberEmployee,
	|	DataOnTime.Hours1 AS Hours1,
	|	DataOnTime.Days AS Days
	|INTO TT
	|FROM
	|	&DataOnTime AS DataOnTime
	|WHERE
	|	DataOnTime.TimeKind IN(&SelectedMeasurements)
	|	AND DataOnTime.Employee = &Employee
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1 AS LineNumber,
	|	TT.Employee AS Employee,
	|	TT.Dimension AS Dimension,
	|	MIN(TT.LineNumberEmployee) AS LineNumberEmployee,
	|	SUM(TT.Hours1) AS Hours1,
	|	SUM(TT.Days) AS Days
	|FROM
	|	TT AS TT
	|
	|GROUP BY
	|	TT.Employee,
	|	TT.Dimension";
	
EndFunction

Function QueryTextForFillingInCrossTable_ShiftScheduleByDay()
	
	Return "SELECT
	        |	DataOnTime.Date AS Date,
	        |	DataOnTime.Employee AS Employee,
	        |	DataOnTime.WorkScheduleCalendar AS Dimension,
	        |	DataOnTime.LineNumberEmployee AS LineNumberEmployee
	        |INTO TT
	        |FROM
	        |	&DataOnTime AS DataOnTime
	        |WHERE
	        |	DataOnTime.WorkScheduleCalendar IN(&SelectedMeasurements)
	        |;
	        |
	        |////////////////////////////////////////////////////////////////////////////////
	        |SELECT
	        |	DataByPeriods.Date AS Date,
	        |	DataByPeriods.ColumnName AS ColumnName
	        |INTO TT_TimeIntervals
	        |FROM
	        |	&DataByPeriods AS DataByPeriods
	        |;
	        |
	        |////////////////////////////////////////////////////////////////////////////////
	        |SELECT
	        |	TT.LineNumberEmployee + 1 AS LineNumber,
	        |	TT.Employee AS Employee,
	        |	TT.Dimension AS Dimension,
	        |	TT.Date AS Date,
	        |	ISNULL(TT_TimeIntervals.ColumnName, """") AS ColumnName,
	        |	TT.LineNumberEmployee AS LineNumberEmployee,
	        |	EmployeesHR.Presentation AS LastFirstName,
	        |	EmployeesHR.Code AS EmployeeCode,
	        |	ISNULL(EmploymentRecordSliceLast.JobTitle, VALUE(Catalog.JobTitles.EmptyRef)) AS JobTitle
	        |FROM
	        |	TT AS TT
	        |		INNER JOIN TT_TimeIntervals AS TT_TimeIntervals
	        |		ON TT.Date = TT_TimeIntervals.Date
	        |		LEFT JOIN InformationRegister.EmploymentRecord.SliceLast(
	        |				&Period,
	        |				&FilterOrganization
	        |					AND Employee IN
	        |						(SELECT DISTINCT
	        |							TT.Employee
	        |						FROM
	        |							TT)) AS EmploymentRecordSliceLast
	        |		ON TT.Employee = EmploymentRecordSliceLast.Employee
	        |		LEFT JOIN Catalog.EmployeesHR AS EmployeesHR
	        |		ON TT.Employee = EmployeesHR.Ref
	        |
	        |ORDER BY
	        |	LineNumberEmployee
	        |TOTALS BY
	        |	LineNumberEmployee,
	        |	Dimension";
	
EndFunction

Function QueryTextForFillingInCrossTable_ShiftScheduleByShift()
	
	Return "SELECT
	|	DataOnTime.Date AS Date,
	|	DataOnTime.Employee AS Employee,
	|	DataOnTime.WorkScheduleCalendar AS Dimension,
	|	DataOnTime.LineNumberEmployee AS LineNumberEmployee
	|INTO TT
	|FROM
	|	&DataOnTime AS DataOnTime
	|WHERE
	|	DataOnTime.WorkScheduleCalendar IN(&SelectedMeasurements)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.Employee AS Employee,
	|	MIN(TT.LineNumberEmployee) AS LineNumberEmployee
	|INTO VT_Grouped
	|FROM
	|	TT AS TT
	|
	|GROUP BY
	|	TT.Employee
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataByPeriods.Date AS Date,
	|	DataByPeriods.ColumnName AS ColumnName
	|INTO TT_TimeIntervals
	|FROM
	|	&DataByPeriods AS DataByPeriods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VT_Grouped.LineNumberEmployee AS LineNumberEmployee,
	|	VT_Grouped.Employee AS Employee,
	|	TT.Dimension AS Dimension,
	|	ISNULL(TT_TimeIntervals.ColumnName, """") AS ColumnName,
	|	EmployeesHR.Presentation AS LastFirstName,
	|	EmployeesHR.Code AS EmployeeCode,
	|	ISNULL(EmploymentRecordSliceLast.JobTitle.Presentation, """") AS JobTitle
	|FROM
	|	VT_Grouped AS VT_Grouped
	|		LEFT JOIN TT AS TT
	|			LEFT JOIN TT_TimeIntervals AS TT_TimeIntervals
	|			ON TT.Date = TT_TimeIntervals.Date
	|		ON VT_Grouped.Employee = TT.Employee
	|		LEFT JOIN Catalog.EmployeesHR AS EmployeesHR
	|		ON VT_Grouped.Employee = EmployeesHR.Ref
	|		LEFT JOIN InformationRegister.EmploymentRecord.SliceLast(
	|				&Period,
	|				&FilterOrganization
	|					AND Employee IN
	|						(SELECT DISTINCT
	|							TT.Employee
	|						FROM
	|							TT)) AS EmploymentRecordSliceLast
	|		ON VT_Grouped.Employee = EmploymentRecordSliceLast.Employee
	|
	|ORDER BY
	|	LineNumberEmployee
	|TOTALS BY
	|	LineNumberEmployee,
	|	Dimension";
	
EndFunction

// Defines the maximum number of columns allowed for displaying periods.
//
// Parameters:
//   TablePeriods - ValueTable - table with period data
//   ByDays - Boolean - whether to display by day
//   SelectedMeasurements - Array - list of selected measurements
//
// Returns:
//   Number - Maximum Number Of Columns
Function DetermineMaximumNumberOfColumns(TablePeriods, ByDays, SelectedMeasurements)
	
	If ByDays Then
		NumberOfColumns_ = Min(TablePeriods.Count(), 16);
	Else
		NumberOfColumns_ = Min(TablePeriods.Count(), 16/SelectedMeasurements.Count());
	EndIf;
	
	Return NumberOfColumns_;
	
EndFunction

Function MaximumLineNumber(Table)
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	Table.LineNumber AS LineNumber
	|INTO TT
	|FROM
	|	&Table AS Table
	|
	|ORDER BY
	|	LineNumber DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.LineNumber AS LineNumber
	|FROM
	|	TT AS TT";
	Query.SetParameter("Table", Table);
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		Return Selection.LineNumber;
	EndIf;
	
	Return 0;
	
EndFunction

// Performs division with the result rounded up.
//
// Parameters:
//   Divisible - Number - the number to be divided
//   Divisor - Number - the number by which the division is performed
//
// Returns:
//   Number - the result of division with rounding up
Function DivisionWithRoundingUp(Divisible, Divisor)
	
	If Divisor = 0 Then
		Raise NStr("ru = 'Деление на ноль невозможно';
					|vi = 'Cannot divide by zero';
					|en = 'Cannot divide by zero'; fa = 'Cannot divide by zero';
					|it = 'Cannot divide by zero';
					|pl = 'Cannot divide by zero';
					|tr = 'Sıfıra bölme mümkün değil'");
	EndIf;
	
	Result = Int(Divisible / Divisor);
	
	// If there is a Balance, increase the result by 1
	If Divisible % Divisor > 0 Then
		Result = Result + 1;
	EndIf;
	
	Return Result;
	
EndFunction

// Removes all characters except digits from the source string.
//
// Parameters:
//   InitialString - String - A string from which you need to remove all characters except numbers
//
// Returns:
//   String - A string containing only numbers from the original string
Function NumbersString(InitialString)
	
	Result = StrConcat(StrSplit(InitialString, StrConcat(StrSplit(InitialString,"1234567890", False)), False));
	
	Return Result;
	
EndFunction

//Converts the date to a string of numbers without extra characters. Does not depend on localization. Accuracy is up to a day.
//
// Parameters:
//   Date - Date - Original date for conversion
//
// Returns:
//   String - A string representing a date in the YYYY MMDD format
Function DateToString(Date)
	
	Year = NumbersString(Year(Date));
	Month = String(Month(Date));
	If StrLen(Month)=1 Then
		Month = "0"+Month;
	EndIf;
	Day = String(Day(Date));
	If StrLen(Day)=1 Then
		Day = "0"+Day;
	EndIf;
	
	Return Year+Month+Day;
	
EndFunction

// Returns the row range for the specified block when splitting the table into blocks.
//
// Parameters:
//   RowsCount - Number - Total Number Of Rows
//   BlockNumber     - Number - The number of the block to get the row range for
//   BlockSize    - Number - Number of lines in one block (16 by default)
//
// Returns:
//   Structure - Contains the beginning and end of the row range for the specified block
Function GetRangeOfLinesForBlock(RowsCount, BlockNumber, BlockSize = 16) 
	
	// Checking whether the block number is correct
	MaxBlock = DivisionWithRoundingUp(RowsCount, BlockSize);

	If BlockNumber < 1 Or BlockNumber > MaxBlock Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"ru = 'Неверный номер блока. Допустимо от 1 до %1';
			|vi = 'Invalid block number. Allowed from 1 to %1';
			|en = 'Invalid block number. Allowed from 1 to %1'; fa = 'Invalid block number. Allowed from 1 to %1';
			|it = 'Invalid block number. Allowed from 1 to %1';
			|pl = 'Invalid block number. Allowed from 1 to %1';
			|tr = 'Geçersiz blok numarası. 1 ile %1 arasında olmalıdır'"), MaxBlock);
	EndIf;

	StartOfRange_ = (BlockNumber - 1) * BlockSize + 1;
	RangeEnd = Min(BlockNumber * BlockSize, RowsCount);

	Return New Structure("Begin, End", StartOfRange_, RangeEnd);

EndFunction

Function MergeAreas(Val InitialArea, Val Final_Area, SpreadsheetDocument, VertAlign = "Center")

	If Not ValueIsFilled(InitialArea) Or Not ValueIsFilled(Final_Area) Then
		Return Undefined;
	EndIf;

	StartingAddress = InitialArea.Name;
	FinalAddress = Final_Area.Name;

	StartingAddress 	= StrSplit(StartingAddress, ":").Get(0);
	FinalAddress 	= StrSplit(FinalAddress, ":").Get(1);
	AreaIsCommon 	= SpreadsheetDocument.Area(StartingAddress + ":" + FinalAddress);
	AreaIsCommon.Merge();
	AreaIsCommon.VerticalAlign = VerticalAlign[VertAlign];

	Return AreaIsCommon;

EndFunction

// Unloads data from a row in the value tree to a table of values.
//
// Parameters:
//  TreeRow - ValueTreeRow - a row in the value tree whose data needs to be uploaded.
//
// Returns:
//  ValueTable - a table containing data from a row in the value tree. Description:
//   * LineNumberEmployee - Number
//   * Employee - CatalogRef.EmployeesHR
//   * WorkScheduleCalendar - CatalogRef.Calendars
//   * TimeKind - CatalogRef.PayCodesHR
//   * Date - Date
//
Function UploadTimeDataToTableOfValues(TreeRow) Export
	
	If TreeRow = Undefined Then
		Raise NStr("ru = 'Ошибка при полученни данных о времени';
					|vi = 'Error when receiving time data';
					|en = 'Error when receiving time data'; fa = 'Error when receiving time data';
					|it = 'Error when receiving time data';
					|pl = 'Error when receiving time data';
					|tr = 'Zaman verileri alınırken hata oluştu'");
	EndIf;
	
	ValueTable = New ValueTable;
	For Each Column In TreeRow.Owner().Columns Do
		ValueTable.Columns.Add(Column.Name, Column.ValueType, Column.Title);
	EndDo;
	
	For Each TreeRow In TreeRow.Rows Do
		NewRow = ValueTable.Add();
		FillPropertyValues(NewRow, TreeRow);
	EndDo;
	
	Return ValueTable;
	
EndFunction

// Creates a period table based on the specified date range.
//
// Parameters:
//   BeginningDateOfPeriod - Date - start date of the period
//   EndingDateOfPeriod - Date - end date of the period
//
// Returns:
//   ValueTable - a table with periods. Description:
//   * ColumnNumber - Number
//   * ColumnName - String
//   * Date - Date
//   * DateAsString - String
//   * DateDayOfWeekString - String
Function CreateSeparatePeriodTable(BeginningDateOfPeriod, EndingDateOfPeriod) Export
	
	AddingDate 	= BeginningDateOfPeriod;
	EndDate 	= EndingDateOfPeriod;
	
	TypesDetailsNumber = Common.TypeDescriptionNumber(10, 0);
	TypesDetailsString = New TypeDescription("String");
	TypesDetailsDate = Common.DateTypeDetails(DateFractions.Date);
	
	TablePeriods = New ValueTable;
	TablePeriods.Columns.Add("ColumnNumber",TypesDetailsNumber);
	TablePeriods.Columns.Add("ColumnName",  TypesDetailsString);
	TablePeriods.Columns.Add("Date", 	   TypesDetailsDate);
	TablePeriods.Columns.Add("DateAsString",   		TypesDetailsString);
	TablePeriods.Columns.Add("DateDayOfWeekString",TypesDetailsString);
	
	CurrentPeriod = 1;
	While AddingDate <= EndDate Do
		FoundRows = TablePeriods.FindRows(New Structure("Date", AddingDate));
		If FoundRows.Count() = 0 Then
			NewRow = TablePeriods.Add();
			NewRow.ColumnName = DateToString(AddingDate);
		Else
			NewRow = FoundRows[0];
		EndIf;
		NewRow.ColumnNumber = CurrentPeriod;
		CurrentPeriod = CurrentPeriod + 1;
		NewRow.Date = AddingDate;
		NewRow.DateAsString				= Format(AddingDate, NStr("ru = 'ДФ=''дд.ММ''';
																	|vi = 'DF=''MM/dd''';
																	|en = 'DF=''MM/dd'''; fa = 'DF=''MM/dd''';
																	|it = 'DF=''MM/dd''';
																	|pl = 'DF=''MM/dd''';
																	|tr = 'DF=''gg.AA'''"));
		NewRow.DateDayOfWeekString 	= Format(AddingDate, NStr("ru = 'ДФ=''дд.ММ''';
																|vi = 'DF=''MM/dd''';
																|en = 'DF=''MM/dd'''; fa = 'DF=''MM/dd''';
																|it = 'DF=''MM/dd''';
																|pl = 'DF=''MM/dd''';
																|tr = 'DF=''gg.AA'''"))
			+" ("+Format(AddingDate, NStr("ru = 'ДФ=''ддд''';
											|vi = 'DF=''ddd''';
											|en = 'DF=''ddd'''; fa = 'DF=''ddd''';
											|it = 'DF=''ddd''';
											|pl = 'DF=''ddd''';
											|tr = 'DF=''ggg'''"))+".)";
		AddingDate = AddingDate+24*3600;
	EndDo;
	
	TablePeriods.Sort("Date");
	
	Return TablePeriods;
	
EndFunction

#EndRegion

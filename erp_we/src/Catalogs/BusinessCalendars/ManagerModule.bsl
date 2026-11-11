///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// CloudTechnology.ExportImportData

// Returns the catalog attributes
//  that naturally form a catalog item key.
//
// Returns:
//  Array - Array of attribute names used to generate a natural key.
//
Function NaturalKeyFields() Export
	
	Result = New Array();
	
	Result.Add("Code");
	
	Return Result;
	
EndFunction

// End CloudTechnology.ExportImportData

// StandardSubsystems.Print

// Generates print forms.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lịch sản xuất ""%1"" vào năm %2';
				|ru = 'Производственный календарь ""%1"" на %2 год';
				|en = 'Business calendar ""%1"" for %2'; fa = 'Business calendar ""%1"" for %2';
				|it = 'Calendario di produzione ""%1"" per l''anno %2 ';
				|pl = 'Kalendarz produkcyjny ""%1"" na rok %2';
				|tr = '%2 yılı için ""%1"" çalışma takvimi'"), 
			PrintParameters.BusinessCalendar,
			Format(PrintParameters.YearNumber, "NG=;"));
		ModulePrintManager = Common.CommonModule("PrintManagement");
		ModulePrintManager.OutputSpreadsheetDocumentToCollection(
				PrintFormsCollection,
				"BusinessCalendar", 
				Title,
				BusinessCalendarPrintForm(PrintParameters),
				,
				"Catalog.BusinessCalendars.PF_MXL_BusinessCalendar");
	EndIf;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#Region Internal

// Detects the last day for which the data of the specified business calendar is filled in.
//
// Parameters:
//  BusinessCalendar - CatalogRef.BusinessCalendars - a calendar.
//
// Returns:
//  Date - a date until which the business calendar is filled in. Undefined if the calendar is not filled in.
//
Function BusinessCalendarFillingEndDate(BusinessCalendar) Export
	
	Query = New Query;
	Query.SetParameter("BusinessCalendar", BusinessCalendar);
	Query.Text = 
		"SELECT
		|	MAX(BusinessCalendarData.Date) AS Date
		|FROM
		|	InformationRegister.BusinessCalendarData AS BusinessCalendarData
		|WHERE
		|	BusinessCalendarData.BusinessCalendar = &BusinessCalendar
		|
		|HAVING
		|	MAX(BusinessCalendarData.Date) IS NOT NULL ";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Date;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns information on the day type for each business calendar date.
//
// Parameters:
//  BusinessCalendar - CatalogRef.BusinessCalendars - a current catalog item.
//  Years - Number, Array of Number - a number of the year for which the business calendar is to be read.
//
// Returns:
//  ValueTable
//
Function BusinessCalendarData(BusinessCalendar, Val Years) Export
	
	If TypeOf(Years) <> Type("Array") Then
		Years = CommonClientServer.ValueInArray(Years);
	EndIf;
	
	Query = New Query;
	Query.SetParameter("BusinessCalendar", BusinessCalendar);
	Query.SetParameter("Years", Years);
	Query.Text =
		"SELECT
		|	BusinessCalendarData.Year AS Year,
		|	BusinessCalendarData.Date AS Date,
		|	BusinessCalendarData.DayKind AS DayKind,
		|	BusinessCalendarData.ReplacementDate AS ReplacementDate
		|FROM
		|	InformationRegister.BusinessCalendarData AS BusinessCalendarData
		|WHERE
		|	BusinessCalendarData.Year IN(&Years)
		|	AND BusinessCalendarData.BusinessCalendar = &BusinessCalendar
		|
		|ORDER BY
		|	BusinessCalendarData.Date";
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#Region Private

// Updates the Business calendars catalog from an XML file.
//
// Parameters:
//  CalendarsTable	 - ValueTable	 - a table with business calendar details.
//
Procedure UpdateBusinessCalendars(CalendarsTable) Export
	
	If CalendarsTable.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ClassifierTable", CalendarsTable);
	Query.Text = 
		"SELECT
		|	CAST(ClassifierTable.Code AS STRING(2)) AS Code,
		|	CAST(ClassifierTable.Base AS STRING(2)) AS CodeOfBasicCalendar,
		|	CAST(ClassifierTable.Description AS STRING(100)) AS Description
		|INTO ClassifierTable
		|FROM
		|	&ClassifierTable AS ClassifierTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ClassifierTable.Code AS Code,
		|	ClassifierTable.CodeOfBasicCalendar AS CodeOfBasicCalendar,
		|	ClassifierTable.Description AS Description,
		|	BusinessCalendars.Ref AS Ref,
		|	ISNULL(BusinessCalendars.Code, """") AS BusinessCalendarCode1,
		|	ISNULL(BusinessCalendars.Description, """") AS BusinessCalendarDescription,
		|	ISNULL(BusinessCalendars.BasicCalendar.Code, """") AS BusinessCalendarBasicCode
		|FROM
		|	ClassifierTable AS ClassifierTable
		|		LEFT JOIN Catalog.BusinessCalendars AS BusinessCalendars
		|		ON ClassifierTable.Code = BusinessCalendars.Code
		|
		|ORDER BY
		|	CodeOfBasicCalendar";
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		If TrimAll(Selection.Code) = TrimAll(Selection.BusinessCalendarCode1)
			And TrimAll(Selection.Description) = TrimAll(Selection.BusinessCalendarDescription) 
			And TrimAll(Selection.CodeOfBasicCalendar) = TrimAll(Selection.BusinessCalendarBasicCode) Then
			Continue;
		EndIf;
		If Not ValueIsFilled(Selection.Ref) Then
			If Not Common.DataSeparationEnabled() And ValueIsFilled(Selection.CodeOfBasicCalendar) Then
				// Dependent calendars are not created automatically upon update in the local mode.
				Continue;
			EndIf;
		EndIf;
		BeginTransaction();
		Try
			If Not ValueIsFilled(Selection.Ref) Then
				CatalogObject = CreateItem();
			Else
				DataLock = New DataLock;
				LockItem = DataLock.Add("Catalog.BusinessCalendars");
				LockItem.SetValue("Ref", Selection.Ref);
				DataLock.Lock();
				CatalogObject = Selection.Ref.GetObject();
			EndIf;
			FillBusinessCalendar(CatalogObject, Selection);
			WriteBusinessCalendar(CatalogObject);
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
EndProcedure

// Updates business calendar data by a data table.
// 
// Parameters:
//  DataTable - ValueTable - business calendars data.
// 
// Returns:
//  ValueTable - Changes of business calendar data:
//   * BusinessCalendarCode - String - a changed calendar code,
//   * Year - Number - a year for which the calendar was changed.
//
Function UpdateBusinessCalendarsData(Val DataTable) Export
	
	ChangesTable = BusinessCalendarsChangesTable();
	
	UpdateBusinessCalendarsBasicData(DataTable, ChangesTable);
	
	UpdateDependentBusinessCalendarsData(ChangesTable);
	
	Return ChangesTable;
	
EndFunction

Function UpdateNonWorkDaysPeriods(PeriodsTable) Export
	
	ChangesTable = BusinessCalendarsChangesTable();
	
	// ACC:96 -off The result must contain unique values.
	
	Query = New Query;
	Query.SetParameter("PeriodsTable", PeriodsTable);
	Query.Text = 
		"SELECT
		|	ClassifierTable.BusinessCalendarCode AS CalendarCode,
		|	ClassifierTable.PeriodNumber AS PeriodNumber,
		|	ClassifierTable.StartDate AS StartDate,
		|	ClassifierTable.EndDate AS EndDate,
		|	ClassifierTable.Basis AS Basis
		|INTO TTClassifierTable
		|FROM
		|	&PeriodsTable AS ClassifierTable
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	BusinessCalendars.Ref AS BusinessCalendar,
		|	ClassifierTable.CalendarCode AS BusinessCalendarCode
		|INTO TTCalendarChanges
		|FROM
		|	TTClassifierTable AS ClassifierTable
		|		INNER JOIN Catalog.BusinessCalendars AS BusinessCalendars
		|		ON ClassifierTable.CalendarCode = BusinessCalendars.Code
		|		LEFT JOIN InformationRegister.CalendarNonWorkDaysPeriods AS NonWorkDaysPeriods
		|		ON BusinessCalendars.Ref = NonWorkDaysPeriods.BusinessCalendar
		|		AND ClassifierTable.PeriodNumber = NonWorkDaysPeriods.PeriodNumber
		|		AND ClassifierTable.StartDate = NonWorkDaysPeriods.StartDate
		|		AND ClassifierTable.EndDate = NonWorkDaysPeriods.EndDate
		|		AND ClassifierTable.Basis = NonWorkDaysPeriods.Basis
		|WHERE
		|	NonWorkDaysPeriods.PeriodNumber IS NULL
		|
		|UNION
		|
		|SELECT
		|	NonWorkDaysPeriods.BusinessCalendar AS BusinessCalendar,
		|	NonWorkDaysPeriods.BusinessCalendar.Code AS BusinessCalendarCode
		|FROM
		|	InformationRegister.CalendarNonWorkDaysPeriods AS NonWorkDaysPeriods
		|		LEFT JOIN TTClassifierTable AS ClassifierTable
		|		ON ClassifierTable.CalendarCode = NonWorkDaysPeriods.BusinessCalendar.Code
		|		AND ClassifierTable.PeriodNumber = NonWorkDaysPeriods.PeriodNumber
		|		AND ClassifierTable.StartDate = NonWorkDaysPeriods.StartDate
		|		AND ClassifierTable.EndDate = NonWorkDaysPeriods.EndDate
		|		AND ClassifierTable.Basis = NonWorkDaysPeriods.Basis
		|WHERE
		|	ClassifierTable.PeriodNumber IS NULL
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CalendarsChanges.BusinessCalendar AS BusinessCalendar,
		|	CalendarsChanges.BusinessCalendarCode AS BusinessCalendarCode,
		|	YEAR(ClassifierTable.StartDate) AS Year,
		|	ClassifierTable.PeriodNumber,
		|	ClassifierTable.StartDate AS StartDate,
		|	ClassifierTable.EndDate AS EndDate,
		|	ClassifierTable.Basis AS Basis
		|FROM
		|	TTCalendarChanges AS CalendarsChanges
		|		INNER JOIN TTClassifierTable AS ClassifierTable
		|		ON ClassifierTable.CalendarCode = CalendarsChanges.BusinessCalendarCode
		|ORDER BY
		|	CalendarsChanges.BusinessCalendar,
		|	ClassifierTable.PeriodNumber";
	
	// ACC:96-on
	
	DataLock = New DataLock;
	DataLock.Add("InformationRegister.CalendarNonWorkDaysPeriods");
	BeginTransaction();
	Try
		DataLock.Lock();
		Selection = Query.Execute().Select();
		While Selection.NextByFieldValue("BusinessCalendar") Do
			RecordSet = InformationRegisters.CalendarNonWorkDaysPeriods.CreateRecordSet();
			While Selection.Next() Do
				FillPropertyValues(RecordSet.Add(), Selection);
				FillPropertyValues(ChangesTable.Add(), Selection);
			EndDo;
			RecordSet.Filter.BusinessCalendar.Set(Selection.BusinessCalendar);
			If InfobaseUpdate.IsCallFromUpdateHandler() Then
				InfobaseUpdate.WriteRecordSet(RecordSet);
				Continue;
			EndIf;
			RecordSet.Write();
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	ChangesTable.GroupBy("BusinessCalendarCode, Year");
	
	Return ChangesTable;
	
EndFunction

// The function prepares a result of filling in a business calendar
// with default data.
// If the configuration contains a template with predefined
// business calendar data for this year, the template data is used,
// otherwise, business calendar data is based on
// information about holidays and effective holiday replacement rules.
// 
// Parameters:
//  CalendarCode1 - String - a calendar code
//  YearNumber - Number - a year number.
//  BasicCalendarCode - String - a source calendar code
// 
// Returns:
//  ValueTable - The result of filling the default business calendar:
//   * BusinessCalendarCode - String
//   * DayKind - EnumRef.BusinessCalendarDaysKinds
//   * Year - Number
//   * Date - Date
//   * ReplacementDate - Date
//
Function BusinessCalendarDefaultFillingResult(CalendarCode1, YearNumber, Val BasicCalendarCode = Undefined) Export
	
	DaysKinds = New Map;
	ShiftedDays = New Map;
	
	// Use the template data (if present).
	// If a base calendar is specified, get its data.
	CalendarsCodes = New Array;
	CalendarsCodes.Add(CalendarCode1);
	HasBasicCalendar = False;
	If BasicCalendarCode <> Undefined Then
		CalendarsCodes.Add(BasicCalendarCode);
		HasBasicCalendar = True;
	EndIf;
	
	// Select template data from both calendars.
	// Get only holidays and substitutes.
	TemplateData = DefaultBusinessCalendarsData(CalendarsCodes, False);
	
	RowFilter = New Structure("BusinessCalendarCode,Year");
	RowFilter.Year = YearNumber;
	
	HasCalendarData = False;
	RowFilter.BusinessCalendarCode = CalendarCode1;
	CalendarData = TemplateData.FindRows(RowFilter);
	If CalendarData.Count() > 0 Then
		HasCalendarData = True;
		FillDaysKindsWithCalendarData(CalendarData, DaysKinds, ShiftedDays);
	EndIf;
	
	// Check if the template contains basic calendar data.
	HasBasicCalendarData = False;
	If HasBasicCalendar Then
		RowFilter.BusinessCalendarCode = BasicCalendarCode;
		CalendarData = TemplateData.FindRows(RowFilter);
		If CalendarData.Count() > 0 Then
			HasBasicCalendarData = True;
			If Not HasCalendarData Then
				FillDaysKindsWithCalendarData(CalendarData, DaysKinds, ShiftedDays);
			EndIf;
		EndIf;
	EndIf;
	
	// Add default data for other days.
	DayDate = Date(YearNumber, 1, 1);
	While DayDate <= Date(YearNumber, 12, 31) Do
		If DaysKinds[DayDate] = Undefined Then
			DaysKinds.Insert(DayDate, DayKindByDate(DayDate));
		EndIf;
		DayDate = DayDate + DayLength();
	EndDo;
	
	// If there are no data in the template, fill in permanent holidays.
	If Not HasCalendarData Then
		If HasBasicCalendar And HasBasicCalendarData Then
			// Request permanent holidays of the basic calendar only if they are missing in the template.
			BasicCalendarCode = Undefined;
		EndIf;
		FillPermanentHolidays(DaysKinds, ShiftedDays, YearNumber, CalendarCode1, BasicCalendarCode);
	EndIf;
	
	// Convert them to table.
	BusinessCalendarData = NewBusinessCalendarsData();
	For Each KeyAndValue In DaysKinds Do
		NewRow = BusinessCalendarData.Add();
		NewRow.Date = KeyAndValue.Key;
		NewRow.DayKind = KeyAndValue.Value;
		ReplacementDate = ShiftedDays[NewRow.Date];
		If ReplacementDate <> Undefined Then
			NewRow.ReplacementDate = ReplacementDate;
		EndIf;
		NewRow.Year = YearNumber;
		NewRow.BusinessCalendarCode = CalendarCode1;
	EndDo;
	
	BusinessCalendarData.Sort("Date");
	
	Return BusinessCalendarData;
	
EndFunction

Function BusinessCalendarsDefaultFillingResult(CalendarsCodes) Export
	
	Query = New Query;
	Query.SetParameter("CalendarsCodes", CalendarsCodes);
	Query.Text = 
		"SELECT
		|	BusinessCalendars.Ref AS Ref,
		|	BusinessCalendars.Code AS CalendarCode1,
		|	BusinessCalendars.BasicCalendar AS BasicCalendar,
		|	BusinessCalendars.BasicCalendar.Code AS BasicCalendarCode
		|FROM
		|	Catalog.BusinessCalendars AS BusinessCalendars
		|WHERE
		|	BusinessCalendars.Code IN(&CalendarsCodes)";
	QueryResult = Query.Execute();
	
	// Request data of all calendars from the template to determine years to be filled in.
	TemplateDataCodes = QueryResult.Unload().UnloadColumn("CalendarCode1");
	TemplateData = DefaultBusinessCalendarsData(TemplateDataCodes, False);
	
	DataTable = NewBusinessCalendarsData();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		RowFilter = New Structure("BusinessCalendarCode");
		RowFilter.BusinessCalendarCode = Selection.CalendarCode1;
		TemplateCalendarData = TemplateData.FindRows(RowFilter);
		YearsNumbers = Common.UnloadColumn(TemplateCalendarData, "Year", True);
		CurrentYear = Year(CurrentSessionDate());
		If YearsNumbers.Find(CurrentYear) = Undefined Then
			// Add the current year by default.
			YearsNumbers.Add(CurrentYear);
		EndIf;
		For Each YearNumber In YearsNumbers Do
			CalendarData = BusinessCalendarDefaultFillingResult(Selection.CalendarCode1, YearNumber, Selection.BasicCalendarCode);
			CommonClientServer.SupplementTable(CalendarData, DataTable);
		EndDo;
	EndDo;
	
	Return DataTable;
	
EndFunction

// Converts data of 1C-supplied business calendars.
//
// Parameters:
//   CalendarsCodes - Array - an optional parameter, an array, if it is not specified, all available data will be got from the template.
//   GenerateFullSet - Boolean - if false, only data on differences from the default calendar will be generated.
//
// Returns:
//   See BusinessCalendarsDataFromXML.
//
Function BusinessCalendarsDataFromTemplate(CalendarsCodes = Undefined, GenerateFullSet = True) Export
	
	If Metadata.DataProcessors.Find("FillCalendarSchedules") = Undefined Then
		Return NewBusinessCalendarsData();
	EndIf;
	
	ModuleFillingInCalendarSchedules = Common.CommonModule("DataProcessors.FillCalendarSchedules");
	TextDocument = ModuleFillingInCalendarSchedules.GetTemplate("BusinessCalendarsData");
	
	XMLData1 = Common.ReadXMLToTable(TextDocument.GetText());
	
	CalendarsTable = BusinessCalendarsFromTemplate();
	
	Return BusinessCalendarsDataFromXML(XMLData1, CalendarsTable, CalendarsCodes, GenerateFullSet);
	
EndFunction

// Converts business calendar data presented as XML.
//
// Parameters:
//   XMLData1 - Structure - extracted from an XML file using the Common.ReadXMLToTable method.
//   CalendarsTable - ValueTable - a list of business calendars supported in the application.
//   CalendarsCodes - Array - if it is not set, the filter will not be set.
//   GenerateFullSet - Boolean - if false, only data on differences from the default calendar will be generated.
//
// Returns:
//  ValueTable:
//   * BusinessCalendarCode - String
//   * DayKind - EnumRef.BusinessCalendarDaysKinds
//   * Year - Number
//   * Date - Date
//   * ReplacementDate - Date
//
Function BusinessCalendarsDataFromXML(Val XMLData1, CalendarsTable, CalendarsCodes = Undefined, GenerateFullSet = True) Export
	
	DataTable = NewBusinessCalendarsData();
	
	ClassifierTable = XMLData1.Data;
	If ClassifierTable.Count() = 0 Then
		Return DataTable;
	EndIf;
	
	CalendarsYears = ClassifierTable.Copy(, "Calendar,Year");
	CalendarsYears.GroupBy("Calendar,Year");
	AddCalendarsYearsAccordingToTheCalendarTable(CalendarsYears, CalendarsTable);
	CalendarsYears.Sort("Calendar, Year");
	
	RowFilter = New Structure("Calendar,Year");
	For Each Combination In CalendarsYears Do
		If CalendarsCodes <> Undefined And CalendarsCodes.Find(Combination.Calendar) = Undefined Then
			Continue;
		EndIf;
		YearDates = New Map;
		FillPropertyValues(RowFilter, Combination);
		CalendarDataRows = ClassifierTable.FindRows(RowFilter);
		For Each ClassifierRow In CalendarDataRows Do
			NewRow = DataTable.Add();
			NewRow.BusinessCalendarCode = ClassifierRow.Calendar;
			NewRow.DayKind = Enums.BusinessCalendarDaysKinds[ClassifierRow.DayType];
			NewRow.Year = Number(ClassifierRow.Year);
			NewRow.Date = Date(ClassifierRow.Date);
			If ValueIsFilled(ClassifierRow.SwapDate) Then
				NewRow.ReplacementDate = Date(ClassifierRow.SwapDate);
			EndIf;
			
			YearDates.Insert(NewRow.Date, True);
		EndDo;
		BasicCalendarCode = BasicCalendarCode(Combination.Calendar, CalendarsTable);
		If BasicCalendarCode <> Undefined Then
			RowFilter.Calendar = BasicCalendarCode;
			CalendarDataRows = ClassifierTable.FindRows(RowFilter);
			For Each ClassifierRow In CalendarDataRows Do
				ClassifierRow.Calendar = Combination.Calendar;
				
				FilterParameters = New Structure("BusinessCalendarCode,Date");
				FilterParameters.BusinessCalendarCode = ClassifierRow.Calendar;
				FilterParameters.Date = Date(ClassifierRow.Date);
				FoundRows = DataTable.FindRows(FilterParameters);
				If FoundRows.Count() > 0 Then
					ClassifierRow.Calendar = BasicCalendarCode;
					If NewRow <> Undefined Then
						YearDates.Insert(NewRow.Date, True);
					EndIf;
					Continue;
				EndIf;
				
				NewRow = DataTable.Add();
				NewRow.BusinessCalendarCode = ClassifierRow.Calendar;
				NewRow.DayKind = Enums.BusinessCalendarDaysKinds[ClassifierRow.DayType];
				NewRow.Year = Number(ClassifierRow.Year);
				NewRow.Date = Date(ClassifierRow.Date);
				If ValueIsFilled(ClassifierRow.SwapDate) Then
					NewRow.ReplacementDate = Date(ClassifierRow.SwapDate);
				EndIf;
				
				ClassifierRow.Calendar = BasicCalendarCode;
				If NewRow <> Undefined Then
					YearDates.Insert(NewRow.Date, True);
				EndIf;
			EndDo;
		EndIf;
		If Not GenerateFullSet Then
			Continue;
		EndIf;
		YearNumber = Number(Combination.Year);
		DayDate = Date(YearNumber, 1, 1);
		While DayDate <= Date(YearNumber, 12, 31) Do
			If YearDates[DayDate] = Undefined Then
				NewRow = DataTable.Add();
				NewRow.BusinessCalendarCode = Combination.Calendar;
				NewRow.Year = YearNumber;
				NewRow.Date = DayDate;
				NewRow.DayKind = DayKindByDate(DayDate);
			EndIf;
			DayDate = DayDate + DayLength();
		EndDo;
	EndDo;
	
	Return DataTable;
	
EndFunction

Function NonWorkDaysPeriodsFromXML(Val XMLData1, CalendarsTable) Export
	
	DataTable = NewNonWorkDaysPeriodsTable();
	
	TemplateData1 = XMLData1.Data;
	For Each TemplateString In TemplateData1 Do
		AddNonWorkPeriodToTableFromTemplate(DataTable.Add(), TemplateString);
		DependentCalendarsCodes = DependentCalendarsCodes(TemplateString.Calendar, CalendarsTable);
		For Each DependentCalendarCode In DependentCalendarsCodes Do
			If TemplateData1.FindRows(New Structure("Calendar", DependentCalendarCode)).Count() <> 0 Then
				Continue;
			EndIf;
			NewRow = DataTable.Add();
			AddNonWorkPeriodToTableFromTemplate(NewRow, TemplateString);
			NewRow.BusinessCalendarCode = DependentCalendarCode;
		EndDo;
	EndDo;
	
	DataTable.Sort("BusinessCalendarCode, PeriodNumber");
	
	Return DataTable;
	
EndFunction

Procedure AddCalendarsYearsAccordingToTheCalendarTable(CalendarsYears_, CalendarsTable)

	CalendarsYears_.Sort("Calendar, Year");
	For Each CalendarRow In CalendarsTable Do
		CalendarYears = CalendarsYears_.FindRows(New Structure("Calendar", CalendarRow.Code));
		YearsOfTheBaseCalendar = CalendarsYears_.FindRows(New Structure("Calendar", CalendarRow.Base));
		If CalendarYears.Count() = 0 Then
			// The template contains no data on this calendar. Instead, take the basic calendar.
			If YearsOfTheBaseCalendar.Count() = 0 Then
				// The basic calendar contains no data. Add only the current-year data.
				AddACalendarYear(CalendarsYears_, CalendarRow.Code, Year(CurrentSessionDate()));
				Continue;
			EndIf;
			For Each TheBaseLine In YearsOfTheBaseCalendar Do
				AddACalendarYear(CalendarsYears_, CalendarRow.Code, TheBaseLine.Year);
			EndDo;
			Continue;
		EndIf;
		// Populate for all years from the basic calendar but not earlier than the minimal year in the calendar.
		MinimumYear = CalendarYears[0].Year;
		Years = Common.UnloadColumn(CalendarYears, "Year");
		For Each TheBaseLine In YearsOfTheBaseCalendar Do
			If TheBaseLine.Year >= MinimumYear And Years.Find(TheBaseLine.Year) = Undefined Then
				AddACalendarYear(CalendarsYears_, CalendarRow.Code, TheBaseLine.Year);
			EndIf;
		EndDo;
	EndDo;

EndProcedure

Procedure AddACalendarYear(CalendarsYears_, CalendarCode1, Year)
	NewRow = CalendarsYears_.Add();
	NewRow.Calendar = CalendarCode1;
	NewRow.Year = Format(Year, "NG=");
EndProcedure

Procedure AddNonWorkPeriodToTableFromTemplate(TableRow, TemplateString)
	TableRow.BusinessCalendarCode = TemplateString.Calendar;
	TableRow.PeriodNumber = Number(TemplateString.Order);
	TableRow.StartDate = Date(TemplateString.StartDate);
	TableRow.EndDate = Date(TemplateString.EndDate);
	TableRow.Basis = TemplateString.Description;
EndProcedure

Function NonWorkDaysPeriodsFromTemplate() Export
	
	If Metadata.DataProcessors.Find("FillCalendarSchedules") = Undefined Then
		Return NewNonWorkDaysPeriodsTable();
	EndIf;
	
	ModuleFillingInCalendarSchedules = Common.CommonModule("DataProcessors.FillCalendarSchedules");
	TextDocument = ModuleFillingInCalendarSchedules.GetTemplate("NonWorkDaysPeriods");
	PeriodsTable = Common.ReadXMLToTable(TextDocument.GetText());
	
	CalendarsTable = BusinessCalendarsFromTemplate();
	Return NonWorkDaysPeriodsFromXML(PeriodsTable, CalendarsTable);
	
EndFunction

// Gets the table with 1C-supplied business calendars.
//
// Returns:
//   ValueTable
//
Function BusinessCalendarsFromTemplate() Export
	
	If Metadata.DataProcessors.Find("FillCalendarSchedules") = Undefined Then
		Return New ValueTable;
	EndIf;
	
	ModuleFillingInCalendarSchedules = Common.CommonModule("DataProcessors.FillCalendarSchedules");
	TextDocument = ModuleFillingInCalendarSchedules.GetTemplate("BusinessCalendars");
	CalendarsTable = Common.ReadXMLToTable(TextDocument.GetText()).Data;
	
	Return CalendarsTable;
	
EndFunction

Procedure FillDefaultBusinessCalendarsTimeConsumingOperation(Parameters, ResultAddress) Export
	
	Calendars = DefaultBusinessCalendars();
	PutToTempStorage(Calendars, ResultAddress);
	
EndProcedure

Procedure UpdateBusinessCalendarsBasicData(DataTable, CalendarsChanges)
	
	If DataTable.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ClassifierTable", DataTable);
	Query.Text = 
		"SELECT
		|	ClassifierTable.BusinessCalendarCode AS CalendarCode,
		|	ClassifierTable.Date AS Date,
		|	ClassifierTable.Year AS Year,
		|	ClassifierTable.DayKind AS DayKind,
		|	ClassifierTable.ReplacementDate AS ReplacementDate
		|INTO TTClassifierTable
		|FROM
		|	&ClassifierTable AS ClassifierTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	BusinessCalendars.Ref AS BusinessCalendar,
		|	ClassifierTable.CalendarCode AS BusinessCalendarCode,
		|	ClassifierTable.Year AS Year
		|INTO TTCalendarChanges
		|FROM
		|	TTClassifierTable AS ClassifierTable
		|		INNER JOIN Catalog.BusinessCalendars AS BusinessCalendars
		|		ON ClassifierTable.CalendarCode = BusinessCalendars.Code
		|		LEFT JOIN InformationRegister.BusinessCalendarData AS BusinessCalendarData
		|		ON (BusinessCalendars.Ref = BusinessCalendarData.BusinessCalendar)
		|			AND ClassifierTable.Year = BusinessCalendarData.Year
		|			AND ClassifierTable.Date = BusinessCalendarData.Date
		|			AND ClassifierTable.DayKind = BusinessCalendarData.DayKind
		|			AND ClassifierTable.ReplacementDate = BusinessCalendarData.ReplacementDate
		|WHERE
		|	BusinessCalendarData.DayKind IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CalendarsChanges.BusinessCalendar AS BusinessCalendar,
		|	CalendarsChanges.BusinessCalendarCode AS BusinessCalendarCode,
		|	CalendarsChanges.Year AS Year,
		|	ClassifierTable.Date AS Date,
		|	ClassifierTable.DayKind AS DayKind,
		|	ClassifierTable.ReplacementDate AS ReplacementDate
		|FROM
		|	TTCalendarChanges AS CalendarsChanges
		|		INNER JOIN TTClassifierTable AS ClassifierTable
		|		ON (ClassifierTable.CalendarCode = CalendarsChanges.BusinessCalendarCode)
		|			AND (ClassifierTable.Year = CalendarsChanges.Year)
		|
		|ORDER BY
		|	CalendarsChanges.BusinessCalendar,
		|	Year";
	
	Block = New DataLock();
	Block.Add("InformationRegister.BusinessCalendarData");
	BeginTransaction();
	Try
		Block.Lock();
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then
			CommitTransaction();
			Return;
		EndIf;
		Selection = QueryResult.Select();
		While Selection.NextByFieldValue("BusinessCalendar") Do
			While Selection.NextByFieldValue("Year") Do
				RecordSet = InformationRegisters.BusinessCalendarData.CreateRecordSet();
				While Selection.Next() Do
					FillPropertyValues(RecordSet.Add(), Selection);
				EndDo;
				FillPropertyValues(CalendarsChanges.Add(), Selection);
				RecordSet.Filter.BusinessCalendar.Set(Selection.BusinessCalendar);
				RecordSet.Filter.Year.Set(Selection.Year);
				If InfobaseUpdate.IsCallFromUpdateHandler() Then
					InfobaseUpdate.WriteRecordSet(RecordSet);
					Continue;
				EndIf;
				RecordSet.Write();
			EndDo;
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	CalendarsChanges.GroupBy("BusinessCalendarCode, Year");
	
EndProcedure

Procedure UpdateDependentBusinessCalendarsData(CalendarsChanges) Export
	
	If CalendarsChanges.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("CalendarsChanges", CalendarsChanges);
	Query.SetParameter("DependentCalendarsUpdateStartYear", 2018);
	Query.Text = 
		"SELECT
		|	CalendarsChanges.BusinessCalendarCode AS BusinessCalendarCode,
		|	CalendarsChanges.Year AS Year
		|INTO TTCalendarChanges
		|FROM
		|	&CalendarsChanges AS CalendarsChanges
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DependentCalendars.Ref AS BusinessCalendar,
		|	DependentCalendars.Code AS Code,
		|	BasicCalendarChanges.Year AS Year,
		|	DependentCalendars.BasicCalendar.Code AS BasicCalendarCode
		|FROM
		|	Catalog.BusinessCalendars AS DependentCalendars
		|		INNER JOIN TTCalendarChanges AS BasicCalendarChanges
		|		ON DependentCalendars.BasicCalendar.Code = BasicCalendarChanges.BusinessCalendarCode
		|			AND (DependentCalendars.BasicCalendar <> VALUE(Catalog.BusinessCalendars.EmptyRef))
		|			AND (BasicCalendarChanges.Year >= &DependentCalendarsUpdateStartYear)
		|		LEFT JOIN TTCalendarChanges AS DependentCalendarChanges
		|		ON (DependentCalendarChanges.BusinessCalendarCode = DependentCalendars.Code)
		|			AND (DependentCalendarChanges.Year = BasicCalendarChanges.Year)
		|WHERE
		|	DependentCalendarChanges.Year IS NULL";
		
	Block = New DataLock();
	Block.Add(Metadata.Catalogs.BusinessCalendars.FullName());
	
	BeginTransaction();
	Try
		Block.Lock();
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			CodesOfDependent = QueryResult.Unload().UnloadColumn("Code");
			TemplateData = DefaultBusinessCalendarsData(CodesOfDependent, False);
			RowFilter = New Structure(
				"BusinessCalendarCode,
				|Year");
			Selection = QueryResult.Select();
			While Selection.Next() Do
				RowFilter.BusinessCalendarCode = Selection.Code;
				RowFilter.Year = Selection.Year;
				FoundRows = TemplateData.FindRows(RowFilter);
				If FoundRows.Count() > 0 Then
					// If the template contains data, it is not to be refilled.
					Continue;
				EndIf;
				CalendarData = BusinessCalendarDefaultFillingResult(Selection.Code, Selection.Year, Selection.BasicCalendarCode);
				CalendarData.Columns.Add("BusinessCalendar");
				CalendarData.FillValues(Selection.BusinessCalendar, "BusinessCalendar");
				RecordSet = InformationRegisters.BusinessCalendarData.CreateRecordSet();
				RecordSet.Load(CalendarData);
				RecordSet.Filter.BusinessCalendar.Set(Selection.BusinessCalendar);
				RecordSet.Filter.Year.Set(Selection.Year);
				If InfobaseUpdate.IsCallFromUpdateHandler() Then
					InfobaseUpdate.WriteRecordSet(RecordSet);
				Else
					RecordSet.Write();
				EndIf;
				// Add it to the changes table.
				NewRow = CalendarsChanges.Add();
				NewRow.BusinessCalendarCode = Selection.Code;
				NewRow.Year = Selection.Year;
			EndDo;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Defines a source of the current list of supported business calendars (template or classifier delivery).
//
// Returns:
//   ValueTable
//
Function DefaultBusinessCalendars() Export
	
	If CalendarSchedules.CalendarsVersion() >= CalendarSchedules.LoadedCalendarsVersion() Then
		Return BusinessCalendarsFromTemplate();
	EndIf;
	
	Try
		Return BusinessCalendarsFromClassifierFile();
	Except
		EventName = NStr("vi = 'Lịch biểu.Nhận lịch từ bảng mã hiệu';
						|ru = 'Календарные графики.Получение календарей из классификатора';
						|en = 'Calendar schedules.Get calendars from classifier'; fa = 'Calendar schedules.Get calendars from classifier';
						|it = 'Calendari. Ottenimento dei calendari dal classificatore';
						|pl = 'Harmonogramy kalendarzowe.Pobieranie kalendarzy z klasyfikatora';
						|tr = 'Takvim programları. Sınıflandırıcıdan takvim al'", Common.DefaultLanguageCode());
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhận danh sách lịch sản xuất từ bảng mã hiệu.
                  |Danh sách lịch được nhận từ khuôn in trong bộ cài đặt.
                  |%1';
                  |ru = 'Не удалось получить список производственных календарей из классификатора.
                  |Список календарей получен из поставляемого макета.
                  |%1';
                  |en = 'Cannot get business calendars from the classifier.
                  |The calendars are retrieved from a built-in template.
                  |%1'; fa = 'Cannot get business calendars from the classifier.
                  |The calendars are retrieved from a built-in template.
                  |%1';
                  |it = 'Non è stato possibile ottenere l''elenco dei calendari produttivi dal classificatori.
                  |L''elenco dei calendari è ottenuto dal layout fornito.
                  |%1';
                  |pl = 'Pobieranie listy kalendarzy produkcyjnych z klasyfikatora nie powiodło się.
                  |Lista kalendarzy została pobrana z dostarczanego szablonu.
                  |%1';
                  |tr = 'Bir sınıflandırıcıdan çalışma takvimleri listesi alınamadı. 
                  |Takvim listesi sağlanan şablondan alınmıştır.
                  |%1'"), 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		WriteLogEvent(EventName, EventLogLevel.Error, , , MessageText);
	EndTry;
	
	Return BusinessCalendarsFromTemplate();
	
EndFunction

// Defines a source of relevant business calendar data (template or classifier delivery).
//
// Parameters:
//   CalendarsCodes - Array
//   GenerateFullSet - Boolean - if True, missing template data will be filled in for each day.
//
// Returns:
//   See Catalogs.BusinessCalendars.BusinessCalendarsDataFromXML.
//
Function DefaultBusinessCalendarsData(CalendarsCodes = Undefined, GenerateFullSet = True) Export
	
	If CalendarSchedules.CalendarsVersion() >= CalendarSchedules.LoadedCalendarsVersion() Then
		Return BusinessCalendarsDataFromTemplate(CalendarsCodes, GenerateFullSet);
	EndIf;
	
	Return BusinessCalendarsDataFromClassifierFile(CalendarsCodes, GenerateFullSet);
	
EndFunction

Function BusinessCalendarsFromClassifierFile()
	
	ClassifierData = CalendarSchedules.ClassifierData();
	
	CalendarsTable = ClassifierData["BusinessCalendars"].Data;
	
	Return CalendarsTable;

EndFunction

Function BusinessCalendarsDataFromClassifierFile(CalendarsCodes = Undefined, GenerateFullSet = True)
	
	ClassifierData = CalendarSchedules.ClassifierData();
	
	Return BusinessCalendarsDataFromXML(
		ClassifierData["BusinessCalendarsData"], 
		ClassifierData["BusinessCalendars"].Data,
		CalendarsCodes, 
		GenerateFullSet);
	
EndFunction

Function DefaultNonWorkDaysPeriods() Export
	
	If CalendarSchedules.CalendarsVersion() >= CalendarSchedules.LoadedCalendarsVersion() Then
		Return NonWorkDaysPeriodsFromTemplate();
	EndIf;
	
	Return NonWorkDaysPeriodsFromClassifierFile();
	
EndFunction

Function NonWorkDaysPeriodsFromClassifierFile()
	
	ClassifierData = CalendarSchedules.ClassifierData();
	
	Return NonWorkDaysPeriodsFromXML(
		ClassifierData["NonWorkDaysPeriods"], 
		ClassifierData["BusinessCalendars"].Data);
	
EndFunction

// Generates a value table to describe changes of business calendar data.
//
Function BusinessCalendarsChangesTable()
	
	ChangesTable = New ValueTable;
	ChangesTable.Columns.Add("BusinessCalendarCode", New TypeDescription("String", , New StringQualifiers(3)));
	ChangesTable.Columns.Add("Year", New TypeDescription("Number", New NumberQualifiers(4)));
	
	Return ChangesTable;
	
EndFunction

// The procedure records data of one business calendar for one year.
//
// Parameters:
//  BusinessCalendar - CatalogRef.BusinessCalendars - a current catalog item.
//  YearNumber - Number - a number of the year for which the business calendar is to be recorded.
//  BusinessCalendarData - See Catalogs.BusinessCalendars.BusinessCalendarData
//
Procedure WriteBusinessCalendarData(BusinessCalendar, YearNumber, BusinessCalendarData) Export
	
	RecordSet = InformationRegisters.BusinessCalendarData.CreateRecordSet();
	
	For Each KeyAndValue In BusinessCalendarData Do
		FillPropertyValues(RecordSet.Add(), KeyAndValue);
	EndDo;
	
	FilterValues = New Structure("BusinessCalendar, Year", BusinessCalendar, YearNumber);
	
	For Each KeyAndValue In FilterValues Do
		RecordSet.Filter[KeyAndValue.Key].Set(KeyAndValue.Value);
	EndDo;
	
	For Each SetRow In RecordSet Do
		FillPropertyValues(SetRow, FilterValues);
	EndDo;
	
	RecordSet.Write(True);
	
	UpdateConditions = WorkScheduleUpdateConditions(BusinessCalendar, YearNumber);
	CalendarSchedules.DistributeBusinessCalendarsDataChanges(UpdateConditions);
	
EndProcedure

// Defines a map between business calendar day kinds and appearance color
// of this day in the calendar field.
// 
// Returns:
//  Map - a map between day kinds and appearance colors.
//
Function BusinessCalendarDayKindsAppearanceColors() Export
	
	AppearanceColors = New Map;
	
	AppearanceColors.Insert(Enums.BusinessCalendarDaysKinds.Work,			StyleColors.BusinessCalendarDayKindWorkdayColor);
	AppearanceColors.Insert(Enums.BusinessCalendarDaysKinds.Saturday,			StyleColors.BusinessCalendarDayKindSaturdayColor);
	AppearanceColors.Insert(Enums.BusinessCalendarDaysKinds.Sunday,		StyleColors.BusinessCalendarDayKindSundayColor);
	AppearanceColors.Insert(Enums.BusinessCalendarDaysKinds.Preholiday,	StyleColors.BusinessCalendarDayKindDayPreholidayColor);
	AppearanceColors.Insert(Enums.BusinessCalendarDaysKinds.Holiday,			StyleColors.BusinessCalendarDayKindHolidayColor);
	
	Return AppearanceColors;
	
EndFunction

// The function creates a list of all possible business calendar day kinds 
// according to metadata of the BusinessCalendarDaysKinds enumeration.
// 
// Returns:
//  ValueList - a list containing an enumeration value and its synonym as a presentation.
//
Function DayKindsList() Export
	
	DayKindsList = New ValueList;
	
	For Each DayKindMetadata In Metadata.Enums.BusinessCalendarDaysKinds.EnumValues Do
		DayKindsList.Add(Enums.BusinessCalendarDaysKinds[DayKindMetadata.Name], DayKindMetadata.Synonym);
	EndDo;
	
	Return DayKindsList;
	
EndFunction

// The function creates an array of business calendars available
// for using, for example, as a template.
//
// Returns:
//  Array - the list of business calendars
//
Function BusinessCalendarsList() Export

	Query = New Query(
	"SELECT
	|	BusinessCalendars.Ref
	|FROM
	|	Catalog.BusinessCalendars AS BusinessCalendars
	|WHERE
	|	(NOT BusinessCalendars.DeletionMark)");
		
	BusinessCalendarsList = New Array;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		BusinessCalendarsList.Add(Selection.Ref);
	EndDo;
	
	Return BusinessCalendarsList;
	
EndFunction

// Fills in an array of holidays according to a business calendar 
// for a specific calendar year.
//
Function BusinessCalendarHolidays(BusinessCalendarCode, YearNumber)
	
	Holidays = New ValueTable;
	Holidays.Columns.Add("Date", New TypeDescription("Date"));
	Holidays.Columns.Add("ShiftHoliday", New TypeDescription("Boolean"));
	Holidays.Columns.Add("AddPreholiday", New TypeDescription("Boolean"));
	Holidays.Columns.Add("NonWorkingOnly", New TypeDescription("Boolean"));
	
	If Metadata.DataProcessors.Find("FillCalendarSchedules") <> Undefined Then
		ModuleFillingInCalendarSchedules = Common.CommonModule("DataProcessors.FillCalendarSchedules");
		ModuleFillingInCalendarSchedules.FillInHolidays(BusinessCalendarCode, YearNumber, Holidays);
	EndIf;
	
	Return Holidays;
	
EndFunction

Function WorkScheduleUpdateConditions(BusinessCalendar, Year)
	
	UpdateConditions = BusinessCalendarsChangesTable();
	
	NewRow = UpdateConditions.Add();
	NewRow.BusinessCalendarCode = Common.ObjectAttributeValue(BusinessCalendar, "Code");
	NewRow.Year = Year;

	Return UpdateConditions;
	
EndFunction

Function DayLength()
	Return 24 * 3600;
EndFunction

// Returns:
//  ValueTable:
//   * BusinessCalendarCode - String 
//   * DayKind - EnumRef.BusinessCalendarDaysKinds 
//   * Year - Number 
//   * Date - Date 
//   * ReplacementDate - Date 
//
Function NewBusinessCalendarsData() Export
	
	DataTable = New ValueTable;
	DataTable.Columns.Add("BusinessCalendarCode", New TypeDescription("String", ,
		New StringQualifiers(2)));
	DataTable.Columns.Add("DayKind", New TypeDescription("EnumRef.BusinessCalendarDaysKinds"));
	DataTable.Columns.Add("Year", New TypeDescription("Number"));
	DataTable.Columns.Add("Date", New TypeDescription("Date"));
	DataTable.Columns.Add("ReplacementDate", New TypeDescription("Date"));
	Return DataTable;
	
EndFunction	

// Returns:
//  ValueTable:
//   * BusinessCalendarCode - String
//   * PeriodNumber - Number
//   * StartDate - Date
//   * EndDate - Date
//   * Basis - String
//
Function NewNonWorkDaysPeriodsTable()

	DataTable = New ValueTable;
	DataTable.Columns.Add("BusinessCalendarCode", New TypeDescription("String", ,
		New StringQualifiers(2)));
	DataTable.Columns.Add("PeriodNumber", New TypeDescription("Number"));
	DataTable.Columns.Add("StartDate", New TypeDescription("Date"));
	DataTable.Columns.Add("EndDate", New TypeDescription("Date"));
	DataTable.Columns.Add("Basis", New TypeDescription("String", , New StringQualifiers(150)));
	Return DataTable;
	
EndFunction

Procedure FillPermanentHolidays(DaysKinds, ShiftedDays, YearNumber, CalendarCode1, BasicCalendarCode = Undefined)
	
	// If not, fill in holidays and their replacements.
	Holidays = BusinessCalendarHolidays(CalendarCode1, YearNumber);
	// Fill the table with next year's holidays as they influence this year. 
	// For example, Dec 31 is a holiday eve.
	NextYearHolidays = BusinessCalendarHolidays(CalendarCode1, YearNumber + 1);
	CommonClientServer.SupplementTable(NextYearHolidays, Holidays);
	
	If BasicCalendarCode <> Undefined Then
		// Add basic calendar holidays to the table as well.
		BasicCalendarHolidays = BusinessCalendarHolidays(BasicCalendarCode, YearNumber);
		CommonClientServer.SupplementTable(BasicCalendarHolidays, Holidays);
		NextYearHolidays = BusinessCalendarHolidays(BasicCalendarCode, YearNumber + 1);
		CommonClientServer.SupplementTable(NextYearHolidays, Holidays);
	EndIf;
	
	// When a public holiday falls on a weekend, the weekend is moved to the next working day. 
	// Except for the weekends that fall on Christmas and New Year holidays. 
	// (Applicable for the Russian Federation.) 
	// 	
	
	For Each TableRow In Holidays Do
		PublicHoliday = TableRow.Date;
		// Mark the day as a preholiday (holiday eve). 
		// 
		If TableRow.AddPreholiday Then
			PreholidayDate = PublicHoliday - DayLength();
			If Year(PreholidayDate) = YearNumber Then
				// Skip pre-holiday days of another year.
				If DaysKinds[PreholidayDate] = Enums.BusinessCalendarDaysKinds.Work 
					And Holidays.Find(PreholidayDate, "Date") = Undefined Then
					DaysKinds.Insert(PreholidayDate, Enums.BusinessCalendarDaysKinds.Preholiday);
				EndIf;
			EndIf;
		EndIf;
		If Year(PublicHoliday) <> YearNumber Then
			// Also skip holidays of another year.
			Continue;
		EndIf;
		If DaysKinds[PublicHoliday] <> Enums.BusinessCalendarDaysKinds.Work 
			And TableRow.ShiftHoliday Then
			// If a public holiday falls on a weekend and is substituted, 
			// move the holiday to the next working day. 
			// 
			DayDate = PublicHoliday;
			While True Do
				DayDate = DayDate + DayLength();
				If DaysKinds[DayDate] = Enums.BusinessCalendarDaysKinds.Work 
					And Holidays.Find(DayDate, "Date") = Undefined Then
					DaysKinds.Insert(DayDate, DaysKinds[PublicHoliday]);
					ShiftedDays.Insert(DayDate, PublicHoliday);
					ShiftedDays.Insert(PublicHoliday, DayDate);
					Break;
				EndIf;
			EndDo;
		EndIf;
		If TableRow.NonWorkingOnly Then
			DaysKinds.Insert(PublicHoliday, Enums.BusinessCalendarDaysKinds.Nonworking);
		Else
			DaysKinds.Insert(PublicHoliday, Enums.BusinessCalendarDaysKinds.Holiday);
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillDaysKindsWithCalendarData(CalendarData, DaysKinds, ShiftedDays)
	
	For Each DataString1 In CalendarData Do
		DaysKinds.Insert(DataString1.Date, DataString1.DayKind);
		If ValueIsFilled(DataString1.ReplacementDate) Then
			ShiftedDays.Insert(DataString1.Date, DataString1.ReplacementDate);
		EndIf;
	EndDo;
	
EndProcedure

Function DayKindByDate(Date)
	
	WeekDayNumber = WeekDay(Date);
	
	If WeekDayNumber <= 5 Then
		Return Enums.BusinessCalendarDaysKinds.Work;
	EndIf;
	
	If WeekDayNumber = 6 Then
		Return Enums.BusinessCalendarDaysKinds.Saturday;
	EndIf;
	
	If WeekDayNumber = 7 Then
		Return Enums.BusinessCalendarDaysKinds.Sunday;
	EndIf;
	
EndFunction

Function BasicCalendarCode(CalendarCode1, CalendarClassifier)
	
	CalendarRow = CalendarClassifier.Find(CalendarCode1, "Code");
	
	If CalendarRow = Undefined Then
		Return Undefined;
	EndIf;
	
	If Not ValueIsFilled(CalendarRow["Base"]) Then
		Return Undefined;
	EndIf;
	
	Return CalendarRow["Base"];
	
EndFunction

Function DependentCalendarsCodes(BasicCalendarCode, CalendarClassifier)
	Return Common.UnloadColumn(
		CalendarClassifier.FindRows(New Structure("Base", BasicCalendarCode)), "Code");
EndFunction

Procedure FillBusinessCalendar(CatalogObject, Selection)
	
	CatalogObject.Code = TrimAll(Selection.Code);
	CatalogObject.Description = TrimAll(Selection.Description);
	If ValueIsFilled(Selection.CodeOfBasicCalendar) Then
		CatalogObject.BasicCalendar = FindByCode(Selection.CodeOfBasicCalendar);
	EndIf;
	
EndProcedure

Procedure WriteBusinessCalendar(CatalogObject)
	
	If InfobaseUpdate.IsCallFromUpdateHandler() Then
		InfobaseUpdate.WriteObject(CatalogObject);
		Return;
	EndIf;
	
	CatalogObject.Write();
	
EndProcedure

#Region BusinessCalendarPrintForm

Function BusinessCalendarPrintForm(PrintFormPreparationParameters)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	Template = GetTemplate("PF_MXL_BusinessCalendar");
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		Template = ModulePrintManager.PrintFormTemplate("Catalog.BusinessCalendars.PF_MXL_BusinessCalendar");
	EndIf;
	
	BusinessCalendar = PrintFormPreparationParameters.BusinessCalendar;
	YearNumber = PrintFormPreparationParameters.YearNumber;
	
	PrintTitle = Template.GetArea("Title");
	PrintTitle.Parameters.BusinessCalendar = BusinessCalendar;
	PrintTitle.Parameters.Year = Format(YearNumber, "NG=");
	SpreadsheetDocument.Put(PrintTitle);
	
	// Initial values regardless of query execution result.
	ForYear = IndicatorsGroupDetails();
	
	NonWorkPeriods = CalendarSchedules.NonWorkDaysPeriods(
		BusinessCalendar, New StandardPeriod(Date(YearNumber, 1, 1), Date(YearNumber, 12, 31)));
	NonWorkDates = New Array;
	Presentation = "";
	For Each NonWorkPeriod In NonWorkPeriods Do
		CommonClientServer.SupplementArray(NonWorkDates, NonWorkPeriod.Dates);
		Presentation = Presentation + ?(IsBlankString(Presentation), "", Chars.LF) + NonWorkPeriod.Presentation;
	EndDo;
	If NonWorkPeriods.Count() > 0 Then
		WarningArea = Template.GetArea("NonWorkPeriods");
		WarningArea.Parameters.Presentation = Presentation;
		SpreadsheetDocument.Put(WarningArea);
	EndIf;
	
	NonWorkdayKinds = New Array;
	NonWorkdayKinds.Add(Enums.BusinessCalendarDaysKinds.Saturday);
	NonWorkdayKinds.Add(Enums.BusinessCalendarDaysKinds.Sunday);
	NonWorkdayKinds.Add(Enums.BusinessCalendarDaysKinds.Holiday);
	NonWorkdayKinds.Add(Enums.BusinessCalendarDaysKinds.Nonworking);
	
	Query = New Query;
	Query.SetParameter("Year", YearNumber);
	Query.SetParameter("BusinessCalendar", BusinessCalendar);
	Query.SetParameter("NonWorkDates", NonWorkDates);
	Query.Text = 
		"SELECT
		|	YEAR(CalendarData.Date) AS CalendarYear,
		|	QUARTER(CalendarData.Date) AS CalendarQuarter,
		|	MONTH(CalendarData.Date) AS CalendarMonth,
		|	COUNT(DISTINCT CalendarData.Date) AS CalendarDays,
		|	SUM(CASE
		|			WHEN CalendarData.Date IN (&NonWorkDates)
		|				THEN 1
		|			ELSE 0
		|		END) AS NonWorkPeriodsDays,
		|	CalendarData.DayKind AS DayKind
		|FROM
		|	InformationRegister.BusinessCalendarData AS CalendarData
		|WHERE
		|	CalendarData.Year = &Year
		|	AND CalendarData.BusinessCalendar = &BusinessCalendar
		|
		|GROUP BY
		|	CalendarData.DayKind,
		|	YEAR(CalendarData.Date),
		|	QUARTER(CalendarData.Date),
		|	MONTH(CalendarData.Date)
		|
		|ORDER BY
		|	CalendarYear,
		|	CalendarQuarter,
		|	CalendarMonth
		|TOTALS BY
		|	CalendarYear,
		|	CalendarQuarter,
		|	CalendarMonth";
	Result = Query.Execute();
	
	SelectionByYear = Result.Select(QueryResultIteration.ByGroups);
	While SelectionByYear.Next() Do
		SelectionByQuarter = SelectionByYear.Select(QueryResultIteration.ByGroups);
		While SelectionByQuarter.Next() Do
			QuarterNumber = Template.GetArea("Quarter");
			QuarterNumber.Parameters.QuarterNumber = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 quý';
																													|ru = '%1 квартал';
																													|en = 'quarter %1'; fa = 'quarter %1';
																													|it = '%1 trimestre';
																													|pl = '%1 kwartał';
																													|tr = '%1 çeyrek'"), SelectionByQuarter.CalendarQuarter);
			SpreadsheetDocument.Put(QuarterNumber);
			QuarterHeader = Template.GetArea("QuarterHeader");
			SpreadsheetDocument.Put(QuarterHeader);
			ForQuarter = IndicatorsGroupDetails();
			If SelectionByQuarter.CalendarQuarter = 1 
				Or SelectionByQuarter.CalendarQuarter = 3 Then
				ForHalfYear = IndicatorsGroupDetails();
			EndIf;
			If SelectionByQuarter.CalendarQuarter = 1 Then
				ForYear = IndicatorsGroupDetails();
			EndIf;
			SelectionByMonth = SelectionByQuarter.Select(QueryResultIteration.ByGroups);
			While SelectionByMonth.Next() Do
				ForMonth = IndicatorsGroupDetails();
				SelectionByDayKind = SelectionByMonth.Select(QueryResultIteration.Linear);
				While SelectionByDayKind.Next() Do
					If NonWorkdayKinds.Find(SelectionByDayKind.DayKind) <> Undefined Then
						CumulateValue(ForMonth.Main.WeekendDays, SelectionByDayKind.CalendarDays);
						CumulateValue(ForMonth.Nonworking.WeekendDays, SelectionByDayKind.NonWorkPeriodsDays);
					ElsIf SelectionByDayKind.DayKind = Enums.BusinessCalendarDaysKinds.Work Then 
						CumulateValue(ForMonth.Main.WorkingTime40, SelectionByDayKind.CalendarDays * 8);
						CumulateValue(ForMonth.Main.WorkingTime36, SelectionByDayKind.CalendarDays * 36 / 5);
						CumulateValue(ForMonth.Main.WorkingTime24, SelectionByDayKind.CalendarDays * 24 / 5);
						CumulateValue(ForMonth.Main.Workdays, SelectionByDayKind.CalendarDays);
						CumulateValue(ForMonth.Nonworking.WorkingTime40, SelectionByDayKind.NonWorkPeriodsDays * 8);
						CumulateValue(ForMonth.Nonworking.WorkingTime36, SelectionByDayKind.NonWorkPeriodsDays * 36 / 5);
						CumulateValue(ForMonth.Nonworking.WorkingTime24, SelectionByDayKind.NonWorkPeriodsDays * 24 / 5);
						CumulateValue(ForMonth.Nonworking.Workdays, SelectionByDayKind.NonWorkPeriodsDays);
					ElsIf SelectionByDayKind.DayKind = Enums.BusinessCalendarDaysKinds.Preholiday Then
						CumulateValue(ForMonth.Main.WorkingTime40, SelectionByDayKind.CalendarDays * 7);
						CumulateValue(ForMonth.Main.WorkingTime36, SelectionByDayKind.CalendarDays * (36 / 5 - 1));
						CumulateValue(ForMonth.Main.WorkingTime24, SelectionByDayKind.CalendarDays * (24 / 5 - 1));
						CumulateValue(ForMonth.Main.Workdays, SelectionByDayKind.CalendarDays);
						CumulateValue(ForMonth.Nonworking.WorkingTime40, SelectionByDayKind.NonWorkPeriodsDays * 7);
						CumulateValue(ForMonth.Nonworking.WorkingTime36, SelectionByDayKind.NonWorkPeriodsDays * (36 / 5 - 1));
						CumulateValue(ForMonth.Nonworking.WorkingTime24, SelectionByDayKind.NonWorkPeriodsDays * (24 / 5 - 1));
						CumulateValue(ForMonth.Nonworking.Workdays, SelectionByDayKind.NonWorkPeriodsDays);
					EndIf;
					CumulateValue(ForMonth.Main.CalendarDays, SelectionByDayKind.CalendarDays);
					CumulateValue(ForMonth.Nonworking.WeekendDays, - SelectionByDayKind.NonWorkPeriodsDays);
				EndDo;
				CumulateColumn(ForQuarter, ForMonth);
				CumulateColumn(ForHalfYear, ForMonth);
				CumulateColumn(ForYear, ForMonth);
				MonthColumn = Template.GetArea("MonthColumn");
				FillAreaParameters(MonthColumn.Parameters, ForMonth);
				MonthColumn.Parameters.MonthName = Format(Date(YearNumber, SelectionByMonth.CalendarMonth, 1), "DF='MMMM'"); // ACC:1367
				SpreadsheetDocument.Join(MonthColumn);
			EndDo;
			MonthColumn = Template.GetArea("MonthColumn");
			FillAreaParameters(MonthColumn.Parameters, ForQuarter);
			MonthColumn.Parameters.MonthName = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 quý';
					|ru = '%1 квартал';
					|en = 'quarter %1'; fa = 'quarter %1';
					|it = '%1 trimestre';
					|pl = '%1 kwartał';
					|tr = '%1 çeyrek'"), SelectionByQuarter.CalendarQuarter);
			SpreadsheetDocument.Join(MonthColumn);
			If SelectionByQuarter.CalendarQuarter = 2 
				Or SelectionByQuarter.CalendarQuarter = 4 Then 
				MonthColumn = Template.GetArea("MonthColumn");
				FillAreaParameters(MonthColumn.Parameters, ForHalfYear);
				MonthColumn.Parameters.MonthName = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 nửa năm';
						|ru = '%1 полугодие';
						|en = 'half year %1'; fa = 'half year %1';
						|it = '%1 mezzo anno';
						|pl = '%1 półrocze';
						|tr = '%1 yarıyıl'"), SelectionByQuarter.CalendarQuarter / 2);
				SpreadsheetDocument.Join(MonthColumn);
			EndIf;
		EndDo;
		MonthColumn = Template.GetArea("MonthColumn");
		FillAreaParameters(MonthColumn.Parameters, ForYear);
		MonthColumn.Parameters.MonthName = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 năm';
				|ru = '%1 год';
				|en = 'year %1'; fa = 'year %1';
				|it = '%1 anno';
				|pl = '%1 rok';
				|tr = '%1 yıl'"), Format(SelectionByYear.CalendarYear, "NG="));
		SpreadsheetDocument.Join(MonthColumn);
	EndDo;
	
	MonthColumn = Template.GetArea("MonthAverage");
	FillAreaParameters(MonthColumn.Parameters, ForYear);
	MonthColumn.Parameters.MonthName = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 năm';
																									|ru = '%1 год';
																									|en = 'year %1'; fa = 'year %1';
																									|it = '%1 anno';
																									|pl = '%1 rok';
																									|tr = '%1 yıl'"), Format(YearNumber, "NG="));
	SpreadsheetDocument.Put(MonthColumn);
	
	MonthColumn = Template.GetArea("MonthColumnAverage");
	MonthColumn.Parameters.WorkingTime40 = Format(ForYear.Main.WorkingTime40 / 12, "NFD=2; NG=0");
	MonthColumn.Parameters.WorkingTime36 = Format(ForYear.Main.WorkingTime36 / 12, "NFD=2; NG=0");
	MonthColumn.Parameters.WorkingTime24 = Format(ForYear.Main.WorkingTime24 / 12, "NFD=2; NG=0");
	MonthColumn.Parameters.MonthName = NStr("vi = 'Số lượng trung bình tháng';
											|ru = 'Среднемесячное количество';
											|en = 'Average per month'; fa = 'میانگین ماهانه';
											|it = 'Importo mensile medio';
											|pl = 'Średnia miesięczna ilość';
											|tr = 'Ortalama aylık miktar'");
	SpreadsheetDocument.Join(MonthColumn);
	
	Return SpreadsheetDocument;
	
EndFunction

Function IndicatorsGroupDetails()
	LongDesc = New Structure("Main, Nonworking");
	LongDesc.Main = ColumnDetails();
	LongDesc.Nonworking = ColumnDetails();
	Return LongDesc;
EndFunction

Function ColumnDetails()
	LongDesc = New Structure(
		"CalendarDays,
		|Workdays,
		|WeekendDays,
		|WorkingTime40,
		|WorkingTime36,
		|WorkingTime24");
	LongDesc.CalendarDays = 0;
	LongDesc.Workdays = 0;
	LongDesc.WeekendDays = 0;
	LongDesc.WorkingTime40 = 0;
	LongDesc.WorkingTime36 = 0;
	LongDesc.WorkingTime24 = 0;
	Return LongDesc;
EndFunction

Procedure CumulateColumn(Column1, Column2)
	For Each Groups In Column1 Do
		For Each Indicators In Groups.Value Do
			Column1[Groups.Key][Indicators.Key] = Column1[Groups.Key][Indicators.Key] + Column2[Groups.Key][Indicators.Key];
		EndDo
	EndDo;
EndProcedure

Procedure CumulateValue(Accumulated, Value)
	Accumulated = Accumulated + Value;
EndProcedure

Procedure FillAreaParameters(Parameters, IndicatorsGroup)
	
	Parameters.Fill(IndicatorsGroup.Main);
	
	Indicators = New Array;
	Indicators.Add("CalendarDays");
	Indicators.Add("Workdays");
	Indicators.Add("WeekendDays");
	Indicators.Add("WorkingTime40");
	Indicators.Add("WorkingTime36");
	Indicators.Add("WorkingTime24");
	
	ParameterValues = New Structure;
	For Each Factor In Indicators Do
		If ValueIsFilled(IndicatorsGroup.Nonworking[Factor]) Then
			ParameterValues.Insert(Factor, 
				StringFunctionsClientServer.SubstituteParametersToString(
					"%1 (%2)", 
					IndicatorsGroup.Main[Factor],
					IndicatorsGroup.Main[Factor] - IndicatorsGroup.Nonworking[Factor]));
		EndIf;
	EndDo;
	
	If ParameterValues.Count() > 0 Then
		Parameters.Fill(ParameterValues);
	EndIf;

EndProcedure

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("FillDefaultBusinessCalendarsTimeConsumingOperation", True);
	
EndProcedure

#EndRegion

#EndIf
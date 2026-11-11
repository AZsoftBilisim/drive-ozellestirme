#Region Internal

// Blocks data for editing in the Form
// 
// Parameters:
// 	IndividualRef - CatalogRef.Persons - Link to a reference list item
// 	PersonDataVersion - String - version of the object being blocked
// 	FormUUID - UUID - Unique identifier of the form
// 
// Returns:
// Boolean - returns the blocking flag
//
Function LockIndividualOnEditAtServer(IndividualRef, PersonDataVersion, FormUUID) Export
	Try
		LockDataForEdit(IndividualRef, PersonDataVersion, FormUUID);
	Except
		Return False;
	EndTry;
	Return True;
EndFunction

#Region EmployeesHR

// Blocks data for editing in the Form
//
// Parameters:
//  Form - ClientApplicationForm - the form from which the check is called:
//  	* Object - CatalogObject.EmployeesHR
//  	* Individual - CatalogObject.Persons - data of an individual
// 	Cancel - Boolean - The flag of failure
// 	StandardProcessing - Boolean - Standard processing flag
// 
Procedure EmployeesWhenCreatingAtServer(Form, Cancel, StandardProcessing) Export

	Object = Form.Object;
	
	ObjectAttributesValues = Common.ObjectAttributesValues(Object.Individual, "LASTFIRSTNAME, Description");
	Form.Individual.LastFirstName = ObjectAttributesValues.LastFirstName;
	Form.Individual.Description = ObjectAttributesValues.Description;
	Object.Description = ObjectAttributesValues.Description;
	
	Parameters = Form.Parameters;
	CreateNewAccessValue = Parameters.Key.IsEmpty();

	If CreateNewAccessValue Then
		Form.PersonIsBlocked = True;
	EndIf;

	// Opening the Form of an existing employee
	If Not CreateNewAccessValue Then
		Individual = Object.Individual;
		FillInEmployeeSFormWithData(Form, Individual);
	EndIf;
	
EndProcedure

// Called when creating a Employees directory list Form at server
// 
// Parameters:
//  Form - ClientApplicationForm
// 	Cancel - Boolean - The flag of failure
// 	StandardProcessing - Boolean - Standard processing flag
// 
Procedure EmployeesWhenCreatingListFormAtServer(Form, Cancel, StandardProcessing) Export
	
	CatalogsPayrollAndHumanResourcesServerOverridable.EmployeesWhenCreatingListFormAtServer(Form, Cancel, StandardProcessing)
	
EndProcedure	

// Called before writing the Employees directory element Form at server
// 
// Parameters:
//  Form - ClientApplicationForm
// 	Cancel - Boolean - The flag of failure
// 
Procedure EmployeesBeforeWritingItemFormAtServer(Form, Cancel) Export
	
	CatalogsPayrollAndHumanResourcesServerOverridable.EmployeesBeforeWritingItemFormAtServer(Form, Cancel);
	
EndProcedure	

// Called when creating the Employees Directory element Form at server
// 
// Parameters:
//  Form - ClientApplicationForm - the form from which the check is called:
//  	* Object - CatalogObject.EmployeesHR
//  	* Individual - CatalogObject.Persons - data of an individual
//  	
// 	Cancel - Boolean - The flag of failure
// 	StandardProcessing - Boolean - Standard processing flag
// 
Procedure EmployeesWhenCreatingAtServerElementForm(Form, Cancel, StandardProcessing) Export

	Object = Form.Object;
	
	ObjectAttributesValues = Common.ObjectAttributesValues(Object.Individual, "LASTFIRSTNAME, Description");
	Form.Individual.LastFirstName = ObjectAttributesValues.LastFirstName;
	Form.Individual.Description = ObjectAttributesValues.Description;
	
	Parameters = Form.Parameters;
	CreateNewAccessValue = Parameters.Key.IsEmpty();

	If CreateNewAccessValue Then
		Form.PersonIsBlocked = True;
	EndIf;

	// Opening the Form of an existing employee.
	If Not CreateNewAccessValue Then
		Individual = Object.Individual;
		FillInEmployeeSFormWithData(Form, Individual);
	EndIf;
	
	CatalogsPayrollAndHumanResourcesServerOverridable.EmployeesWhenCreatingAtServerElementForm(Form, Cancel, StandardProcessing);
	
EndProcedure

// Called when creating the Personal Data Form at server in the Employees Directory
// 
// Parameters:
//  Form - ClientApplicationForm
//  Individual - CatalogRef.Persons - Link to a person
// 
Procedure WhenCreatingEmployeeSPersonalDataATServer(Form, Individual) Export

	Individual  = Form.Individual;

	FillInEmployeeSPersonalDataFormWithData(Form, Individual);

	CatalogsPayrollAndHumanResourcesServerOverridable.WhenCreatingEmployeeSPersonalDataATServer(Form, Individual)
	
EndProcedure 

// Called when writing to the information register of the Information Register Documents of individuals
// 
// Parameters:
//  Form - ClientApplicationForm
//  Individual - CatalogRef.Persons - Link to a person
// 
Procedure WriteDownIdentityDocument(Form, Individual) Export
	
	SetRecord = Form.DocumentsPersons;

	CurrentRecordManager = InformationRegisters.DocumentsPersons.CreateRecordManager();
	FillPropertyValues(CurrentRecordManager, SetRecord); 
	CurrentRecordManager.Person = Individual;
	CurrentRecordManager.ThisIsAnIdentityDocument = True;
	CurrentRecordManager.Write(True);

	CatalogsPayrollAndHumanResourcesServerOverridable.WriteDownIdentityDocument(Form, Individual)

EndProcedure	

// Called when reading the Personnel Data Form at server in the Employees Directory
// 
// Parameters:
//  Form - ClientApplicationForm
//  CurrentObject - CatalogObject.EmployeesHR - Link to employee person
// 
Procedure EmployeesWhenReadingATServer(Form, CurrentObject) Export  
	
	StructureOfPersonnelData = OperationalAccountingOfManufacturingPayrollAndHumanResources.PersonnelHistoryOfEmployee(CurrentObject.ParentCompany, 
														CurrentObject.Ref, Common.CurrentUserDate()); 
																					
	Form.CurrentDepartment = StructureOfPersonnelData.Department;
	Form.CurrentJobTitle = StructureOfPersonnelData.JobTitle;
	Form.CurWorkSchedule = StructureOfPersonnelData.WorkScheduleCalendar;
	Form.CurrentTypeOfEmployment = StructureOfPersonnelData.EmploymentKind;
	Form.CurrentBasicAccrual = StructureOfPersonnelData.AccrualDeduction;
	Form.CurrentValueOfBasicAccrual = StructureOfPersonnelData.ValueOfAccrualAndDeduction;
	Form.DateOfAdmission = StructureOfPersonnelData.DateOfAdmission;
	Form.DateOfDismissal = StructureOfPersonnelData.DateOfDismissal;
	Form.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(CurrentObject.ParentCompany);
	
EndProcedure

#EndRegion

#Region JobTitles

// Called when creating a form for the list of Catalog Positions
// 
// Parameters:
//  Form - ClientApplicationForm
// 	Cancel - Boolean - The flag of failure
// 	StandardProcessing - Boolean - Standard processing flag
// 
Procedure JobTitlesWhenCreatingListForm(Form, Cancel, StandardProcessing) Export

	CatalogsPayrollAndHumanResourcesServerOverridable.JobTitlesWhenCreatingListForm(Form, Cancel, StandardProcessing);

EndProcedure

// Called when creating the Form of the Job Title Directory element
// 
// Parameters:
//  Form - ClientApplicationForm
// 	Cancel - Boolean - The flag of failure
// 	StandardProcessing - Boolean - Standard processing flag
// 
Procedure PostsWhenCreatingElementForm(Form, Cancel, StandardProcessing) Export

	CatalogsPayrollAndHumanResourcesServerOverridable.PostsWhenCreatingElementForm(Form, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region Persons

// Returns a list of individuals with the specified full name.
//
// Parameters:
//   SearchParameters - Structure - contains search parameters:
//     * LastFirstName - String - full name of the individual to search for
//
// Returns:
//   Array of CatalogRef.Persons - individuals found
//
Function SimilarIndividuals(SearchParameters) Export

	Query = New Query;
	Query.Text = 
	"SELECT
	|	Persons.Ref AS Individual
	|FROM
	|	Catalog.Persons AS Persons
	|WHERE
	|	Persons.Description = &LastFirstName";
	
	Query.SetParameter("LASTFIRSTNAME", SearchParameters.LastFirstName);
	
	Result = Query.Execute().Select();
	
	IndividualsArray = New Array;
	
	While Result.Next() Do
		IndividualsArray.Add(Result.Individual);
	EndDo;
	
	Return IndividualsArray;
	
EndFunction

#EndRegion

#Region Work_Schedules

// Constructor of parameters for filling in the work schedule.
//
// Returns:
//   Structure:
//     * BusinessCalendar - Undefined - production calendar
//     * FillingMethod - EnumRef.WorkScheduleFillingMethods - method of filling in the work schedule
//     * FillingTemplate - Undefined - filling template
//     * WorkScheduleCalendar - Undefined - work schedule
//     * WorkSchedule - Undefined - Work schedule
//     * ConsiderHolidays - Undefined - whether holidays are counted
//     * ConsiderNonWorkPeriods - Undefined - whether to account for non-working periods
//     * NonWorkPeriods - Array of Undefined - array of non-working periods
//     * StartingDate - Undefined - Reference date
//
Function ParametersOfFillingNorms() Export

	FillParameters = New Structure;
	FillParameters.Insert("FillingMethod", Enums.WorkScheduleFillingMethods.ByWeeks);
	FillParameters.Insert("NonWorkPeriods", New Array);
	FillParameters.Insert("BusinessCalendar", Undefined);
	FillParameters.Insert("FillingTemplate", Undefined);
	FillParameters.Insert("WorkScheduleCalendar", Undefined);
	FillParameters.Insert("WorkSchedule", Undefined);
	FillParameters.Insert("ConsiderHolidays", Undefined);
	FillParameters.Insert("ConsiderNonWorkPeriods", Undefined);
	FillParameters.Insert("StartingDate", Undefined);
	
	Return FillParameters;
	
EndFunction

// Generates data on working hours according to the work schedule for the specified period in accordance with the filling settings.
//
// Parameters:
//   StartDate - Date - the beginning of the data generation period.
//   EndDate - Date - end of the period. If not specified, it is detected automatically.
//   FillParameters - Structure:
//     * FillingTemplate - Array of Structure - template to fill in.
//     * BusinessCalendar - CatalogRef.BusinessCalendars - link to the production calendar.
//     * FillingMethod - EnumRef.WorkScheduleFillingMethods - filling method.
//     * NonWorkPeriods - Array of Structure - periods of non-working days.
//
// Returns:
//   Map of KeyAndValue:
//    * Key - Undefined
//    * Value - Undefined:
//
Function GetStandardsForWorkSchedule(StartDate, EndDate, FillParameters) Export

	DaysIncludedInSchedule = New Map;

	If FillParameters.FillingTemplate.Count() = 0 Then
		Return DaysIncludedInSchedule;
	EndIf;

	If Not ValueIsFilled(EndDate) Then
		// If the end date is not specified, then fill in before the end of the year.
		EndDate = EndOfYear(StartDate);
		If ValueIsFilled(FillParameters.BusinessCalendar) Then
			// If the production calendar is specified, then we fill it up to the "end" of its fullness.
			FillingEndDate = Catalogs.BusinessCalendars.BusinessCalendarFillingEndDate(
				FillParameters.BusinessCalendar);
			If FillingEndDate <> Undefined And FillingEndDate > EndDate Then
				EndDate = FillingEndDate;
			EndIf;
		EndIf;
	EndIf;

	If ValueIsFilled(FillParameters.BusinessCalendar) Then
		FillParameters.NonWorkPeriods = CalendarSchedules.NonWorkDaysPeriods(
			FillParameters.BusinessCalendar, New StandardPeriod(StartDate, EndDate));
	EndIf;

	Years = YearsInTheInterval(StartDate, EndDate);
	If FillParameters.FillingMethod = Enums.WorkScheduleFillingMethods.ByWeeks Then
		Return NormsIncludedInScheduleByWeek(Years, FillParameters, StartDate, EndDate);
	Else
		Return NormsIncludedInScheduleOfArbitraryLength(Years, FillParameters, StartDate, EndDate);
	EndIf;

EndFunction

#EndRegion

#EndRegion

#Region Private

// Calculates working time norms (days, hours) by time types for a date range based on a template and schedule.
//
// Parameters:
//   Years - Array of Number - years for which the calculation is performed
//   FillParameters - Structure - fill-in settings containing a template, schedule, and production calendar settings
//   StartDate - Date - Start Of Settlement Period
//   EndDate - Date - End Of Settlement Period
//
// Returns:
//   ValueTable - norms of time in the context of types of working time:
//     * PayCode - CatalogRef.PayCodesHR - Type Of Working Time
//     * StandardDays - Number - number of days
//     * StandardHours - Number - number of hours
//
Function NormsIncludedInScheduleByWeek(Years, FillParameters, 
	Val StartDate = Undefined, Val EndDate = Undefined)
	
	NormsByTypeOfTime = New ValueTable();
	NormsByTypeOfTime.Columns.Add("PayCode", New TypeDescription("CatalogRef.PayCodesHR"));
	NormsByTypeOfTime.Columns.Add("StandardDays", Common.TypeDescriptionNumber(10));
	NormsByTypeOfTime.Columns.Add("StandardHours", Common.TypeDescriptionNumber(10));
	
	FillByBusinessCalendar = ValueIsFilled(FillParameters.BusinessCalendar);
	
	If FillByBusinessCalendar Then
		BusinessCalendarData = Catalogs.BusinessCalendars.BusinessCalendarData(
			FillParameters.BusinessCalendar, Years);
		BusinessCalendarData.Indexes.Add("Year");
		BusinessCalendarData.Indexes.Add("Date");
		YearsCalendarIsNotFilledIn = New Array;
		For Each Year In Years Do
			If BusinessCalendarData.FindRows(New Structure("Year", Year)).Count() 
				<> DayOfYear(Date(Year, 12, 31)) Then
				// If the production calendar is specified but filled in incorrectly, week-by-week filling is not supported.
				YearsCalendarIsNotFilledIn.Add(Year);
			EndIf;
		EndDo;
	EndIf;
	
	DayDate = StartDate;
	While DayDate <= EndDate Do
		DayNumber = WeekDay(DayDate);
		If FillByBusinessCalendar Then
			If YearsCalendarIsNotFilledIn.Find(Year(DayDate)) <> Undefined Then
				DayDate = AddAYear(DayDate);
				Continue;
			EndIf;
			If FillParameters.ConsiderHolidays Or FillParameters.NonWorkPeriods.Count() > 0 Then 
				DayData = BusinessCalendarData.FindRows(New Structure("Date", DayDate))[0];
				DayNumber = TemplateDayNumber(DayData, FillParameters);
			EndIf;
		EndIf;
		If DayNumber <> Undefined Then
			DayRow = FillParameters.FillingTemplate[DayNumber - 1]; 
			If DayRow.DayAddedToSchedule Then   
				
				If FillParameters.WorkSchedule.Count() > 0 Then 
					ArrayOfTimeTypes = New Array;
					
					For Each CurrentRow In FillParameters.WorkSchedule Do
						
						If Not CurrentRow.DayNumber = DayNumber Then
							Continue;
						EndIf;	
						NewRow = NormsByTypeOfTime.Add();
						NewRow.PayCode = CurrentRow.TimeKind;
						NewRow.StandardHours = (CurrentRow.EndTime - CurrentRow.BeginTime)/60/60;
						If ArrayOfTimeTypes.Find(NewRow.PayCode) = Undefined Then
							ArrayOfTimeTypes.Add(NewRow.PayCode);  
						EndIf;	
					EndDo;
					
					// For each type of time, add the norm of days 1
					For Each CurrentStringIsArray In ArrayOfTimeTypes Do
						NewRow = NormsByTypeOfTime.Add();
						NewRow.PayCode = CurrentStringIsArray;
						NewRow.StandardDays = 1;
						
					EndDo;	
					
				Else
					
					NewRow = NormsByTypeOfTime.Add();
					NewRow.PayCode = Catalogs.PayCodesHR.EmptyRef();
					NewRow.StandardDays = 1;
					NewRow.StandardHours = 0; 
					
				EndIf;	
				
			EndIf;
		EndIf;
		DayDate = AddADay(DayDate);
	EndDo;
	
	NormsByTypeOfTime.GroupBy("PayCode", "StandardDays,StandardHours");
	
	Return NormsByTypeOfTime;
	
EndFunction

Function NormsIncludedInScheduleOfArbitraryLength(Years, FillParameters, 
	Val StartDate = Undefined, Val EndDate = Undefined)
	
	NormsByTypeOfTime = New ValueTable();
	NormsByTypeOfTime.Columns.Add("PayCode", New TypeDescription("CatalogRef.PayCodesHR"));
	NormsByTypeOfTime.Columns.Add("StandardDays", Common.TypeDescriptionNumber(10));
	NormsByTypeOfTime.Columns.Add("StandardHours", Common.TypeDescriptionNumber(10));
	NormsByTypeOfTime.Columns.Add("Date", Common.DateTypeDetails(DateFractions.Date));
	
	DayDate = FillParameters.StartingDate;
	While DayDate <= EndDate Do
		For Each DayRow In FillParameters.FillingTemplate Do
			If DayDate > EndDate Then
				Break;
			EndIf;
			If DayRow.DayAddedToSchedule 
				And DayDate >= StartDate Then
				
				DayNumber = DayRow.LineNumber;
				If FillParameters.WorkSchedule.Count() > 0 Then 
					ArrayOfTimeTypes = New Array;
					
					For Each CurrentRow In FillParameters.WorkSchedule Do
						
						If Not CurrentRow.DayNumber = DayNumber Then
							Continue;
						EndIf;	
						NewRow = NormsByTypeOfTime.Add();
						NewRow.PayCode = CurrentRow.TimeKind; 
						NewRow.Date = DayDate;
						NewRow.StandardHours = (CurrentRow.EndTime - CurrentRow.BeginTime)/60/60;
						If ArrayOfTimeTypes.Find(NewRow.PayCode) = Undefined Then
							ArrayOfTimeTypes.Add(NewRow.PayCode);  
						EndIf;	
					EndDo;
					
					// For each type of time, add the norm of days 1
					For Each CurrentStringIsArray In ArrayOfTimeTypes Do
						NewRow = NormsByTypeOfTime.Add();
						NewRow.Date = DayDate;
						NewRow.PayCode = CurrentStringIsArray;
						NewRow.StandardDays = 1;
						
					EndDo;	
					
				Else
				
					NewRow = NormsByTypeOfTime.Add();
					NewRow.PayCode = Catalogs.PayCodesHR.EmptyRef();
					NewRow.Date = DayDate;
					NewRow.StandardDays = 1;
					NewRow.StandardHours = 0; 
					
				EndIf;	
				
			EndIf;
			DayDate = AddADay(DayDate);
		EndDo;
	EndDo;
	
	If Not FillParameters.ConsiderHolidays And FillParameters.NonWorkPeriods.Count() = 0 Then  
		NormsByTypeOfTime.GroupBy("PayCode", "StandardDays,StandardHours");
		Return NormsByTypeOfTime;
	EndIf;
	
	// We exclude the dates of holidays.
	
	BusinessCalendarData = Catalogs.BusinessCalendars.BusinessCalendarData(
		FillParameters.BusinessCalendar, Years);
	If BusinessCalendarData.Count() = 0 Then
		NormsByTypeOfTime.GroupBy("PayCode", "StandardDays,StandardHours");
		Return NormsByTypeOfTime;
	EndIf;

	Filter = New Structure("Date");
	
	If FillParameters.ConsiderNonWorkPeriods Then 
		BusinessCalendarData.Indexes.Add("Date"); 
		For Each NonWorkPeriod In FillParameters.NonWorkPeriods Do

			For Each Date In NonWorkPeriod.Dates Do
				Filter.Date = Date;
				FoundRows = NormsByTypeOfTime.FindRows(Filter);
				For Each CurrentRow In FoundRows Do
					NormsByTypeOfTime.Delete(CurrentRow);	
				EndDo;

			EndDo;
		EndDo;
	EndIf;
	
	If FillParameters.ConsiderHolidays Then
		BusinessCalendarData.Indexes.Add("DayKind");
		RowFilter = New Structure("DayKind");
		RowFilter.DayKind = Enums.BusinessCalendarDaysKinds.Holiday;
		HolidaysData = BusinessCalendarData.FindRows(RowFilter);
		For Each DayData In HolidaysData Do

			Filter.Date = DayData.Date;
			FoundRows = NormsByTypeOfTime.FindRows(Filter);
			For Each CurrentRow In FoundRows Do
				NormsByTypeOfTime.Delete(CurrentRow);	
			EndDo;
			
		EndDo;
		NonWorkPeriodsDates = New Array;
		RowFilter.DayKind = Enums.BusinessCalendarDaysKinds.Nonworking;
		NonWorkDaysData = BusinessCalendarData.FindRows(RowFilter);
		If NonWorkDaysData.Count() > 0 Then
			If Not FillParameters.ConsiderNonWorkPeriods Then
				For Each NonWorkPeriod In FillParameters.NonWorkPeriods Do
					CommonClientServer.SupplementArray(NonWorkPeriodsDates, NonWorkPeriod.Dates);
				EndDo;
			EndIf;
		EndIf;
		For Each DayData In NonWorkDaysData Do
			If NonWorkPeriodsDates.Find(DayData.Date) = Undefined Then

				Filter.Date = DayData.Date;
				FoundRows = NormsByTypeOfTime.FindRows(Filter);
				For Each CurrentRow In FoundRows Do
					NormsByTypeOfTime.Delete(CurrentRow);	
				EndDo;
				
			EndIf;
		EndDo;
	EndIf;
	
	NormsByTypeOfTime.GroupBy("PayCode", "StandardDays,StandardHours");
	
	Return NormsByTypeOfTime;
	
EndFunction

Procedure FillInEmployeeSFormWithData(Form, Individual)
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	Persons.TIN AS TIN,
	|	Persons.Gender AS Gender,
	|	Persons.Description AS Description,
	|	Persons.LastName AS LastName,
	|	Persons.LastFirstName AS LastFirstName,
	|	Persons.Name AS Name,
	|	Persons.MiddleName AS MiddleName,
	|	Persons.BirthDate AS BirthDate
	|FROM
	|	Catalog.Persons AS Persons
	|WHERE
	|	Persons.Ref = &Individual";
	
	Query.SetParameter("Individual", Individual);
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then    
		ParametersOfIndividual = Result.Select();
		ParametersOfIndividual.Next();
		
		FillPropertyValues(Form.Individual, ParametersOfIndividual);
		FillPropertyValues(Form.FullNameOfPersons, ParametersOfIndividual);
	
	EndIf;
	
EndProcedure	

Procedure FillInEmployeeSPersonalDataFormWithData(Form, Individual)
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	DocumentsPersonsSliceLast.DocumentKind AS DocumentKind,
	|	DocumentsPersonsSliceLast.DateOfIssue1 AS DateOfIssue1,
	|	DocumentsPersonsSliceLast.ValidityPeriod AS ValidityPeriod,
	|	DocumentsPersonsSliceLast.IssuedBy AS IssuedBy,
	|	DocumentsPersonsSliceLast.Presentation AS Presentation,
	|	DocumentsPersonsSliceLast.CountryOfIssue AS CountryOfIssue,
	|	DocumentsPersonsSliceLast.Series AS Series,
	|	DocumentsPersonsSliceLast.Number AS Number,
	|	DocumentsPersonsSliceLast.Period AS Period,
	|	DocumentsPersonsSliceLast.LastNameInLatin AS LastNameInLatin,
	|	DocumentsPersonsSliceLast.NameInLatin AS NameInLatin
	|FROM
	|	InformationRegister.DocumentsPersons.SliceLast(&Date, Person = &Individual
	|	AND ThisIsAnIdentityDocument) AS DocumentsPersonsSliceLast";
	
	Query.SetParameter("Individual", Individual);
	Query.SetParameter("Date", CurrentSessionDate());
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then    
		ParametersOfIdentityDocument = Result.Select();
		ParametersOfIdentityDocument.Next();
		
		FillPropertyValues(Form.DocumentsPersons, ParametersOfIdentityDocument);
	
	EndIf;
	
EndProcedure

Function TemplateDayNumber(DayData, FillParameters)
	
	DayKind = DayData.DayKind;
	If ThisDateInNonWorkPeriod(DayData.Date, FillParameters.NonWorkPeriods) Then
		If FillParameters.ConsiderNonWorkPeriods Then
			Return Undefined;
		EndIf;
		If DayKind = Enums.BusinessCalendarDaysKinds.Nonworking Then
			DayKind = Enums.BusinessCalendarDaysKinds.Work;
		EndIf;
	EndIf;
	
	If DayKind = Enums.BusinessCalendarDaysKinds.Work 
		Or DayKind = Enums.BusinessCalendarDaysKinds.Preholiday Then
		DayDate = DayData.Date;
		If ValueIsFilled(DayData.ReplacementDate) Then
			DayDate = DayData.ReplacementDate;
		EndIf;
		Return WeekDay(DayDate);
	EndIf;
	
	If DayKind = Enums.BusinessCalendarDaysKinds.Saturday Then
		Return 6;
	EndIf;
	
	If DayKind = Enums.BusinessCalendarDaysKinds.Sunday Then
		Return 7;
	EndIf;

	If DayKind = Enums.BusinessCalendarDaysKinds.Holiday 
		Or DayKind = Enums.BusinessCalendarDaysKinds.Nonworking Then
		If FillParameters.ConsiderHolidays Then
			Return Undefined;
		EndIf;
	EndIf;

	Return WeekDay(DayData.Date);
	
EndFunction

Function ThisDateInNonWorkPeriod(Date, NonWorkPeriods)
	
	For Each NonWorkPeriod In NonWorkPeriods Do
		If NonWorkPeriod.Dates.Find(Date) <> Undefined Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
		
EndFunction

Function DayDurationInSeconds()
	Return 24 * 60 * 60;
EndFunction

Function AddADay(Date, OfDays = 1)
	Return Date + OfDays * DayDurationInSeconds();
EndFunction

Function AddAYear(Date)
	Return AddMonth(Date, 12);
EndFunction

Function YearsInTheInterval(StartDate, EndDate)
	
	Years = New Array;
	
	CurrentYear = Year(StartDate);
	While CurrentYear <= Year(EndDate) Do
		Years.Add(CurrentYear);
		CurrentYear = CurrentYear + 1;
	EndDo;
	
	Return Years;

EndFunction

#EndRegion

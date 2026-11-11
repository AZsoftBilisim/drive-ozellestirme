#Region Private

// Parameters:
//  Form - ClientApplicationForm
//  DateOfWork - Date
Procedure AddDataForEmployeeRecruitment(Form, DateOfWork) Export
	
	//++ WE
	
	AccountingForLaborCostsByEmployees = ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(DateOfWork);
	UsePersonnelAccounting           = GetFunctionalOption("PayrollAndHumanResourcesWE");
	
	If Not AccessRight("Read", Metadata.Catalogs.EmployeesHR)
			Or Not (UsePersonnelAccounting
			Or AccountingForLaborCostsByEmployees) Then
		Return;
	EndIf;
	
	Form.Items.CompanyGroup.Visible = True;
	
	If AccountingForLaborCostsByEmployees Then
		
		QueryText = "
		   |	SELECT
           |	Individuals.Ref AS Ref,
           |	Individuals.Code AS Code,
           |	Individuals.BirthDate AS BirthDate,
           |	Individuals.Gender AS Gender,
           |	Individuals.LastFirstName AS LastFirstName,
           |	Individuals.NameClarification AS NameClarification,
           |	Individuals.LastName AS LastName,
           |	Individuals.Name AS Name,
           |	Individuals.MiddleName AS MiddleName,
           |	EmployeesHR.Code AS TabNumber,
           |	EmployeesHR.Description AS Description,
           |	MatchingData.JobTitle AS JobTitle,
           |	MatchingData.Department AS Department,
           |	MatchingData.Organization AS Organization,
           |	MatchingData.Employee AS Employee,
           |	MatchingData.Period AS DateOfAdmission,
           |	MatchingData.WorksInBusinessUnit AS WorksInBusinessUnit
           |FROM
           |	InformationRegister.EmploymentRecord.SliceLast(
           |			CASE
           |				WHEN &WorkingOnDate
           |					THEN &DateOfWork
           |				ELSE DATETIME(1, 1, 1)
           |			END,
           |			) AS MatchingData
           |		INNER JOIN Catalog.EmployeesHR AS EmployeesHR
           |		ON MatchingData.Employee = EmployeesHR.Ref
           |		LEFT JOIN Catalog.Persons AS Individuals
           |		ON (Individuals.Ref = MatchingData.Employee.Individual)
           |WHERE
           |	(&WorkingOnDate
           |				AND MatchingData.EndDate <= &DateOfWork
           |			OR NOT &WorkingOnDate)
           |	AND MatchingData.WorksInBusinessUnit
           |	AND NOT MatchingData.EventKind = VALUE(Enum.HREventKindsPayrollAndHumanResources.Dismissal)";
		
		ListProperties = Common.DynamicListPropertiesStructure();
		
		ListProperties.QueryText = QueryText;
		ListProperties.MainTable = "";
		ListProperties.DynamicDataRead = False;
		
		Common.SetDynamicListProperties(Form.Items.Employees, ListProperties);
		
		CommonClientServer.SetDynamicListParameter(
			Form.Employees,
			"DateOfWork",
			?(ValueIsFilled(DateOfWork), DateOfWork, CurrentSessionDate()));
		
		CommonClientServer.SetDynamicListParameter(
			Form.Employees,
			"WorkingOnDate",
			Boolean(Form.WorkingOnDate));
		
		Form.Items.EmployeesDateOfAdmission.Visible = True;
		Form.Items.EmployeesEmployee.Visible = True;
		Form.Items.EmployeesDescription.Visible = False;
	EndIf;
		
	Form.Items.EmployeesDepartment.Visible            = True;
	Form.Items.EmployeesOrganization.Visible              = True;
	Form.Items.EmployeesDepartment_Company.Visible = True;
	Form.Items.EmployeesJobTitle.Visible                = True;
	Form.Items.EmployeesTabNumber.Visible                 = True;
	Form.Items.EmployeesCode.Visible                      = False;
	//-- WE
	
EndProcedure

// Returns up-to-date employee HR information by
// organization and employee.
//
// Parameters:
//   Organization - CatalogRef.Companies - Company for the cut
//   Employee - CatalogRef.EmployeesHR - Employee for the cut
//   SliceDate - Date - Cut date
//
// Returns:
//   Structure - Structure with personnel data
Function PersonnelHistoryOfEmployee(Organization, Employee, SliceDate) Export
	
	StructureOfPersonnelData = New Structure;
	StructureOfPersonnelData.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
	StructureOfPersonnelData.Insert("JobTitle", Catalogs.JobTitles.EmptyRef());
	StructureOfPersonnelData.Insert("WorkScheduleCalendar", Catalogs.Calendars.EmptyRef());  
	StructureOfPersonnelData.Insert("EventKind", Enums.HREventKindsPayrollAndHumanResources.EmptyRef());
	StructureOfPersonnelData.Insert("EmploymentKind", Enums.EmploymentKindsPayrollAndHumanResources.EmptyRef());
	StructureOfPersonnelData.Insert("EndDate", Date('00010101'));
	StructureOfPersonnelData.Insert("DateOfAdmission", Date('00010101'));
	StructureOfPersonnelData.Insert("DateOfDismissal", Date('00010101'));
	StructureOfPersonnelData.Insert("AccrualDeduction", Catalogs.AccrualAndDeductionKinds.EmptyRef());
	StructureOfPersonnelData.Insert("ValueOfAccrualAndDeduction", 0);
	StructureOfPersonnelData.Insert("Prepayment_", 0);
	StructureOfPersonnelData.Insert("TimeKindForNorms", Catalogs.PayCodesHR.EmptyRef());
	
	Query = New Query(
	"SELECT
	|	EmploymentRecordSliceLast.Department AS Department,
	|	EmploymentRecordSliceLast.JobTitle AS JobTitle,
	|	EmploymentRecordSliceLast.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	EmploymentRecordSliceLast.EventKind AS EventKind,
	|	EmploymentRecordSliceLast.EmploymentKind AS EmploymentKind,
	|	EmploymentRecordSliceLast.EndDate AS EndDate,
	|	RegularAccrualsAndDeductionsHRSliceLast.AccrualDeduction AS AccrualDeduction,
	|	RegularAccrualsAndDeductionsHRSliceLast.Value AS ValueOfAccrualAndDeduction,
	|	RegularAccrualsAndDeductionsHRSliceLast.Prepayment_ AS Prepayment_,
	|	EmploymentRecordSliceLast.Period AS Period,
	|	RegularAccrualsAndDeductionsHRSliceLast.TimeKindForNorms AS TimeKindForNorms,
	|	EmploymentRecordSliceFirst.Period AS DateOfAdmission,
	|	PersonnelHistoryHRSectionOfLastFired.Period AS DateOfDismissal
	|FROM
	|	InformationRegister.EmploymentRecord.SliceLast(&SliceDate, Organization = &Organization
	|	AND Employee = &Employee
	|	AND WorksInBusinessUnit) AS EmploymentRecordSliceLast
	|		LEFT JOIN InformationRegister.RegularAccrualsAndDeductionsHR.SliceLast(&SliceDate,
	|			Organization = &Organization
	|		AND Employee = &Employee) AS RegularAccrualsAndDeductionsHRSliceLast
	|		ON RegularAccrualsAndDeductionsHRSliceLast.Organization = EmploymentRecordSliceLast.Organization
	|		AND RegularAccrualsAndDeductionsHRSliceLast.Department = EmploymentRecordSliceLast.Department
	|		AND RegularAccrualsAndDeductionsHRSliceLast.Employee = EmploymentRecordSliceLast.Employee
	|		LEFT JOIN InformationRegister.EmploymentRecord.SliceFirst(, Organization = &Organization
	|		AND Employee = &Employee
	|		AND EventKind = VALUE(Enum.HREventKindsPayrollAndHumanResources.Reception)) AS EmploymentRecordSliceFirst
	|		ON EmploymentRecordSliceFirst.Organization = EmploymentRecordSliceLast.Organization
	|		AND EmploymentRecordSliceFirst.Employee = EmploymentRecordSliceLast.Employee
	|		LEFT JOIN InformationRegister.EmploymentRecord.SliceLast(, Organization = &Organization
	|		AND Employee = &Employee
	|		AND EventKind = VALUE(Enum.HREventKindsPayrollAndHumanResources.Dismissal)) AS PersonnelHistoryHRSectionOfLastFired
	|		ON PersonnelHistoryHRSectionOfLastFired.Organization = EmploymentRecordSliceLast.Organization
	|		AND PersonnelHistoryHRSectionOfLastFired.Employee = EmploymentRecordSliceLast.Employee
	|WHERE
	|	RegularAccrualsAndDeductionsHRSliceLast.BasicEarnings
	|	AND RegularAccrualsAndDeductionsHRSliceLast.Valid
	|
	|ORDER BY
	|	Period DESC");
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Employee", Employee);
	Query.SetParameter("SliceDate", SliceDate-1);  
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
	
		Selection = Query.Execute().Select();
	
		Selection.Next();
	
		FillPropertyValues(StructureOfPersonnelData, Selection);
		
	EndIf;

	Return StructureOfPersonnelData;

EndFunction

// Fills in the table with accruals or deductions, depending on the accrual method specified in the parameters
//
// Parameters:
//   TableOfAccrualsOfDeductions - ValueTable - A table of values or a tabular part of accruals or deductions
//   ItIsADeduction - Boolean - Parameter for unloading accruals or deductions
//   Employee - CatalogRef.EmployeesHR - Employee for the cut
//   Department - CatalogRef.BusinessStructure - Subdivision for the slice
//   Organization - CatalogRef.Companies - Company for the cut
//   SliceDate - Date - Cut date
//
Procedure FillInTableWithAccrualsOrDeductionsAsOfDate(TableOfAccrualsOfDeductions, ItIsADeduction, Employee, Department, Organization, SliceDate = Undefined, Currency = Undefined) Export
	
	If Not ValueIsFilled(SliceDate) Then 
		SliceDate = CurrentSessionDate();
	EndIf;
	
	TableOfAccrualsOfDeductions.Clear();
	
	Query = New Query(
	"SELECT
	|	CASE
	|		WHEN &ItIsADeduction
	|			THEN UNDEFINED
	|		ELSE RegularAccrualsAndDeductionsHRSliceLast.AccrualDeduction
	|	END AS Accrual,
	|	CASE
	|		WHEN &ItIsADeduction
	|			THEN RegularAccrualsAndDeductionsHRSliceLast.AccrualDeduction
	|		ELSE UNDEFINED
	|	END AS Retention,
	|	RegularAccrualsAndDeductionsHRSliceLast.Value AS Value
	|FROM
	|	InformationRegister.RegularAccrualsAndDeductionsHR.SliceLast(
	|			&SliceDate,
	|			Organization = &Organization
	|				AND Department = &Department
	|				AND Employee = &Employee
	|				AND AccrualDeduction.ItIsADeduction = &ItIsADeduction
	|				AND Valid
	|				AND NOT BasicEarnings) AS RegularAccrualsAndDeductionsHRSliceLast");
	
	Query.SetParameter("ItIsADeduction", ItIsADeduction);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Employee", Employee);
	Query.SetParameter("Department", Department);
	Query.SetParameter("SliceDate", SliceDate);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			Page1 = TableOfAccrualsOfDeductions.Add();
			
			FillPropertyValues(Page1, Selection);
			
			If ItIsADeduction Then
				Page1.ValueDescription = DocumentsPayrollAndHumanResourcesServer.DetermineOrderOfCalculationOfRetentionByLine(Selection.Retention, Currency);
			Else
				Page1.ValueDescription = DocumentsPayrollAndHumanResourcesServer.DetermineProcedureForCalculatingAccrualByLine(Selection.Accrual, Currency);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// Fills in the table with accruals or deductions, depending on the accrual method specified in the parameters
//
// Parameters:
//   Tables of deduction of deductions - Tables of assignments - Table of values or tabular part of accruals or deductions
//   is a deduction - Boolean parameter for unloading accruals or deductions
//   Employee - Directory link.Employees - Employee for the cut
//   Business unit - Directory Link.Enterprise Structurethe subdivision for the slice
//   Company - Directory link.Companies - The Company for the cut
//   Cut Data - Date - Date of the cut
//
Procedure CheckWorkingEmployees(AuditedEmployees, ParametersForGettingEmployees, Cancel, MessageParameters) Export
	
	Query = New Query(
	"SELECT
	|	EmployeesHR.Ref AS Ref
	|INTO TT_Employees
	|FROM
	|	Catalog.EmployeesHR AS EmployeesHR
	|WHERE
	|	EmployeesHR.Ref IN (&EmployeesHR)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EmployeesHR.Ref AS Employee
	|FROM
	|	TT_Employees AS EmployeesHR
	|		LEFT JOIN InformationRegister.EmploymentRecord.SliceLast(&EndDate, Organization = &Organization) AS
	|			JobReceptions
	|		ON EmployeesHR.Ref = JobReceptions.Employee
	|WHERE
	|	JobReceptions.Period IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	EmployeesHR.Ref
	|FROM
	|	TT_Employees AS EmployeesHR
	|		LEFT JOIN InformationRegister.EmploymentRecord.SliceLast(&EndDate, Organization = &Organization
	|		AND EventKind = VALUE(Enum.HREventKindsPayrollAndHumanResources.Reception)) AS JobReceptions
	|		ON EmployeesHR.Ref = JobReceptions.Employee
	|		LEFT JOIN InformationRegister.EmploymentRecord.SliceLast(&EndDate, Organization = &Organization
	|		AND EventKind = VALUE(Enum.HREventKindsPayrollAndHumanResources.Dismissal)) AS Layoffs
	|		ON EmployeesHR.Ref = Layoffs.Employee
	|WHERE
	|	NOT Layoffs.Period IS NULL
	|	AND ISNULL(Layoffs.Period, DATETIME(3999, 12, 31, 23, 59, 59)) > &StartDate");
		
		Query.SetParameter("StartDate", ParametersForGettingEmployees.BeginOfPeriod);
		Query.SetParameter("EndDate", ParametersForGettingEmployees.PeriodEnding);
		Query.SetParameter("Organization", ParametersForGettingEmployees.Organization);
		Query.SetParameter("EmployeesHR", AuditedEmployees);
		
		QueryResult = Query.Execute();
		
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			If ParametersForGettingEmployees.BeginOfPeriod = ParametersForGettingEmployees.PeriodEnding
				Or (ValueIsFilled(ParametersForGettingEmployees.BeginOfPeriod)
				And Not ValueIsFilled(ParametersForGettingEmployees.PeriodEnding)) Then
			
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Сотрудник %1 не работает в организации %2 на дату %3 г.';
						|vi = 'Employee %1 does not work for the ""%2"" company as of %3';
						|en = 'Employee %1 does not work for the ""%2"" company as of %3'; fa = 'Employee %1 does not work for the ""%2"" company as of %3';
						|it = 'Employee %1 does not work for the ""%2"" company as of %3';
						|pl = 'Employee %1 does not work for the ""%2"" company as of %3';
						|tr = 'Çalışan %1, %3 tarihi itibarıyla %2 iş yerinde çalışmıyor.'"),
							Selection.Employee, ParametersForGettingEmployees.Organization,
							Format(ParametersForGettingEmployees.BeginOfPeriod, "DLF=D"));
				
			Else
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Сотрудник %1 не работает в организации %2 за период с %3 г. по %4 г.';
						|vi = 'Employee %1 does not work for the ""%2"" company for the period from %3 to %4';
						|en = 'Employee %1 does not work for the ""%2"" company for the period from %3 to %4'; fa = 'Employee %1 does not work for the ""%2"" company for the period from %3 to %4';
						|it = 'Employee %1 does not work for the ""%2"" company for the period from %3 to %4';
						|pl = 'Employee %1 does not work for the ""%2"" company for the period from %3 to %4';
						|tr = 'Çalışan %1, %3 - %4 döneminde %2 iş yerinde çalışmıyor.'"),
						Selection.Employee, ParametersForGettingEmployees.Organization,
						Format(ParametersForGettingEmployees.BeginOfPeriod, "DLF=D"),
						Format(ParametersForGettingEmployees.PeriodEnding, "DLF=D"));
				
			EndIf;
			
			Common.MessageToUser(ErrorText, , MessageParameters.FieldNameEmployee, MessageParameters.ObjectName, Cancel);
			
		EndDo;
	
EndProcedure

#EndRegion

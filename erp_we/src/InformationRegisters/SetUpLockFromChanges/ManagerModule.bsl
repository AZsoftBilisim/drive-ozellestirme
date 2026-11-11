// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Information about period blocking settings
// 1. All organizations are blocked and there are no tasks - the period is blocked.
// 2. Organizations are blocked and there are no tasks - the period cannot be calculated.
// 3. No organization is blocked - the period is unblocked, you can calculate it.
// 4. Some organizations have been blocked, but there are tasks in the blocked period - an error, the period cannot be calculated.
// 
// Parameters:
//  Companies - Array of CatalogRef.Companies - Companies
//  Period - Date, Undefined - Period
//  IBUpdate - Boolean - called from the information security update handler
// 
// Returns:
//  Structure - Information About Blocking Changes:
// * TableOfLocks - ValueTable:
// 	** Organization - CatalogRef.Companies -
// 	** BlockingPeriod - Date -
// 	** TasksPeriod - Date -
// 	** PossibleBlockingPeriod - Date -
// 	** ChangeDate - Date -
// 	** EmployeeResponsible - CatalogRef.Users -
// 	** Comment - String -
// * UseMechanismToBlockChanges - Boolean -
// * ThereAreTasksInBlockedPeriod - Boolean -
// * PeriodIsBlockedForAllCompanies - Boolean -
// * PeriodIsBlockedForCompanies - Boolean -
// * PeriodIsNotBlocked - Boolean -
// * PeriodCanBeBlocked - Boolean -
// * ThereAreBlockages - Boolean -
// * SettlementStartDate - Date -
// * BlockedBusinesses - Array of CatalogRef.Companies -
// * NotBlockedBusinesses - Array of CatalogRef.Companies -
// * TableOfTasksToClose - ValueTable:
// 	** Organization - CatalogRef.Companies -
// 	** FirstPeriod - Date -
// 	** RegisterName - String -
// 	** Operation - CatalogRef.MonthEndClosingOperations -
Function InformationAboutBlockingChanges(Companies, Period = Undefined, IBUpdate = False) Export

	SetPrivilegedMode(True);

	TableOfLocks = New ValueTable;
	TableOfLocks.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	TableOfLocks.Columns.Add("BlockingPeriod", New TypeDescription("Date"));
	TableOfLocks.Columns.Add("TasksPeriod", New TypeDescription("Date"));
	TableOfLocks.Columns.Add("PossibleBlockingPeriod", New TypeDescription("Date"));
	TableOfLocks.Columns.Add("ChangeDate", New TypeDescription("Date"));
	TableOfLocks.Columns.Add("EmployeeResponsible", New TypeDescription("CatalogRef.Users"));
	TableOfLocks.Columns.Add("Comment", New TypeDescription("String"));
	
	Result = New Structure;
	Result.Insert("TableOfLocks", TableOfLocks);
	Result.Insert("TableOfTasksToClose", New ValueTable);
	Result.Insert("UseMechanismToBlockChanges", IBUpdate Or UseMechanismToBlockChanges());
	Result.Insert("ThereAreTasksInBlockedPeriod", False); // Scenario 4
	Result.Insert("PeriodIsBlockedForAllCompanies", True); // Scenario 1, 3
	Result.Insert("PeriodIsBlockedForCompanies", False); // Scenario 2
	Result.Insert("PeriodIsNotBlocked", False);
	Result.Insert("PeriodCanBeBlocked", True);
	Result.Insert("ThereAreBlockages", False);
	Result.Insert("SettlementStartDate", Date(1,1,1));
	Result.Insert("BlockedBusinesses", New Array);
	Result.Insert("NotBlockedBusinesses", New Array);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Companies", Companies);
	Query.SetParameter("UnusedMonthClosingOperations", Catalogs.MonthEndClosingOperations.UnusedOperations());
	Query.SetParameter("UseMechanismToBlockChanges", Result.UseMechanismToBlockChanges);
	
	#Region FormationOfTemporaryTables
	
	QueryText =
	"SELECT TOP 0
	|	"""" AS RegisterName,
	|	UNDEFINED AS Operation,
	|	UNDEFINED AS Organization,
	|	DATETIME(1,1,1,0,0,0) AS Month
	|INTO TTJobs
	|";
	
	If Result.UseMechanismToBlockChanges Then
		
		
		QueryTemplate =
		"SELECT
		|	&ShortRegisterName AS RegisterName,
		|	&NameOfOperationField AS Operation,
		|	T.Organization AS Organization,
		|	BEGINOFPERIOD(MIN(T.FieldNamePeriod), MONTH) AS Month
		|FROM
		|	FullRegisterName AS T
		|	LEFT JOIN Constants ON TRUE
		|WHERE
		|	T.Organization IN (&Companies)
		|	AND &AdditionalConditions
		|GROUP BY
		|	T.Organization,
		|	&NameOfOperationField
		|";
		
		TaskRegisters = MonthEndTransactionsServer.TaskRegistersForEndOfMonth();
		
		For Each KeyAndValue In TaskRegisters Do
			
			If KeyAndValue.Value = False Then
				Continue; // Register Is Not Used
			EndIf;
			
			MetaRegister = KeyAndValue.Key;
			
			TextConnection_ = "";
			NameOfOperationField = "UNDEFINED";
			AdditionalConditions = "TRUE";
			FieldNamePeriod = "Month";
			
			If MetaRegister = Metadata.InformationRegisters.JobsForMonthEndClosing Then
				
				AdditionalConditions = "NOT T.Operation IN (&UnusedMonthClosingOperations)
					|";
				
				
				NameOfOperationField = "T.Operation";
				
			
			ElsIf MetaRegister = Metadata.InformationRegisters.DocumentPostingInFinancialAccounting Then

				AdditionalConditions = "T.Status IN (
					|		VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting),
					|		VALUE(Enum.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined),
					|		VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting),
					|		VALUE(Enum.StatusesOfPostingsInFinancialAccounting.PendingPostingInLocalAccounting),
					|		VALUE(Enum.StatusesOfPostingsInFinancialAccounting.DoubleEntryOfFinancialRegistersIsBroken))";
				FieldNamePeriod = "DateRecord";
			EndIf;
			
			TextOfCurrentRequest = StrReplace(QueryTemplate, "&ShortRegisterName", """" + MetaRegister.Name + """");
			TextOfCurrentRequest = StrReplace(TextOfCurrentRequest, "FullRegisterName", MetaRegister.FullName());
			TextOfCurrentRequest = StrReplace(TextOfCurrentRequest, "&NameOfOperationField", NameOfOperationField);
			TextOfCurrentRequest = StrReplace(TextOfCurrentRequest, "FieldNamePeriod", FieldNamePeriod);
			TextOfCurrentRequest = StrReplace(TextOfCurrentRequest, "&AdditionalConditions", AdditionalConditions);
			TextOfCurrentRequest = StrReplace(TextOfCurrentRequest, "LEFT JOIN Constants ON TRUE", TextConnection_);
			
			QueryText = QueryText
				+ "
				|UNION ALL
				|
				|"
				+ TextOfCurrentRequest;
				
		EndDo;

		QueryText = QueryText
			 + "
				|INDEX BY
				|	Organization";
		
	EndIf;
	
	Query.Text = QueryText;
	Query.Execute();
	
	Query.Text  =
	"SELECT
	|	T.Organization AS Organization,
	|	T.Month AS FirstPeriod,
	|	T.RegisterName AS RegisterName,
	|	T.Operation AS Operation
	|FROM
	|	TTJobs AS T
	|ORDER BY
	|	Organization,
	|	FirstPeriod,
	|	RegisterName,
	|	Operation
	|";
	
	#EndRegion
	
	Result.Insert("TableOfTasksToClose", Query.Execute().Unload());
	
	Query.Text =
	"SELECT
	|	Companies.Ref AS Organization,
	|	BEGINOFPERIOD(MIN(ISNULL(Jobs.Month, DATETIME(1, 1, 1, 0, 0, 0))), MONTH) AS TasksPeriod,
	|	BEGINOFPERIOD(MIN(ISNULL(Locks.LockUntil, DATETIME(1, 1, 1, 0, 0, 0))), MONTH) AS BlockingPeriod,
	|	Locks.ChangeDate,
	|	Locks.EmployeeResponsible,
	|	Locks.Comment
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN TTJobs AS Jobs
	|		ON Companies.Ref = Jobs.Organization
	|		LEFT JOIN InformationRegister.SetUpLockFromChanges AS Locks
	|		ON Companies.Ref = Locks.Organization
	|		AND &UseMechanismToBlockChanges
	|WHERE
	|	Companies.Ref IN (&Companies)
	|GROUP BY
	|	Companies.Ref,
	|	Locks.ChangeDate,
	|	Locks.EmployeeResponsible,
	|	Locks.Comment";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		NwRw = TableOfLocks.Add();
		FillPropertyValues(NwRw, Selection);
		
		If Not ValueIsFilled(NwRw.TasksPeriod) Then
			NwRw.PossibleBlockingPeriod = AddMonth(BegOfMonth(CurrentSessionDate()), ?(IBUpdate, -2, -1));
		Else
			NwRw.PossibleBlockingPeriod = AddMonth(BegOfMonth(NwRw.TasksPeriod), ?(IBUpdate, -2, -1));
		EndIf;
		
		ThereIsErrorInLock = ValueIsFilled(NwRw.TasksPeriod) And ValueIsFilled(NwRw.BlockingPeriod) And NwRw.TasksPeriod <= NwRw.BlockingPeriod;
		If ThereIsErrorInLock Then
			Result.ThereAreTasksInBlockedPeriod = True; // this is an error in the installed lock
		EndIf;
		
		If ValueIsFilled(NwRw.BlockingPeriod) Then
			Result.SettlementStartDate = Max(Result.SettlementStartDate, EndOfMonth(NwRw.BlockingPeriod) + 1);
		EndIf;
		
		Result.ThereAreBlockages = Result.ThereAreBlockages Or ValueIsFilled(NwRw.BlockingPeriod);
		
		If ValueIsFilled(Period) Then
			
			If BegOfMonth(Period) > NwRw.BlockingPeriod Then
				Result.PeriodIsBlockedForAllCompanies = False; // The Period Is Not Blocked
			ElsIf ValueIsFilled(NwRw.BlockingPeriod) Then
				Result.PeriodIsBlockedForCompanies = True;
			EndIf;

			If Result.PeriodCanBeBlocked Then
				Result.PeriodCanBeBlocked =
					Not Result.ThereAreTasksInBlockedPeriod
					And (Not ValueIsFilled(NwRw.TasksPeriod)
						Or BegOfMonth(Period) < NwRw.TasksPeriod);
			EndIf;
			
			If BegOfMonth(Period) <= NwRw.BlockingPeriod Then
				Result.BlockedBusinesses.Add(NwRw.Organization);
			Else
				Result.NotBlockedBusinesses.Add(NwRw.Organization);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If Result.PeriodIsBlockedForAllCompanies Then
		Result.PeriodIsBlockedForCompanies = False; // blocked by all
	EndIf;
	
	Result.PeriodIsNotBlocked =
		Not Result.PeriodIsBlockedForAllCompanies
		And Not Result.PeriodIsBlockedForCompanies
		And Not Result.ThereAreTasksInBlockedPeriod;
		
	If Result.PeriodCanBeBlocked Then
		Result.PeriodCanBeBlocked =
			Not Result.PeriodIsBlockedForAllCompanies;
	EndIf;
	
	Return Result;
	
EndFunction

// Dates of blocking by organization.
// 
// Parameters:
//  Companies - Array of CatalogRef.Companies - Companies
// 
// Returns:
//  Map of KeyAndValue:
//		*Key - CatalogRef.Companies - Organization
//		*Value - Date - date of blocking
Function BlockingDatesByCompanies(Companies) Export

	SetPrivilegedMode(True);

	DatesByCompany = New Map;
	
	If Not UseMechanismToBlockChanges() Then

		For Each Organization In Companies Do
			DatesByCompany.Insert(Organization, Date(1,1,1));
		EndDo;
		
		Return DatesByCompany;
		
	EndIf;
		
	Query = New Query;
	Query.Text =
	"SELECT
	|	Companies.Ref AS Organization,
	|	ISNULL(Locks.LockUntil, DATETIME(1,1,1,0,0,0)) AS LockUntil
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN InformationRegister.SetUpLockFromChanges AS Locks
	|		ON Companies.Ref = Locks.Organization
	|WHERE
	|	Companies.Ref IN (&Companies)";
	
	Query.SetParameter("Companies", Companies);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		DatesByCompany.Insert(Selection.Organization, Selection.LockUntil);
	EndDo;
	
	Return DatesByCompany;
	
EndFunction

// The first/last unblocked period.
// 
// Parameters:
//  Companies - Array of CatalogRef.Companies - Companies
//  First - Boolean - gets the first unblocked period, otherwise - the last
//  	Default value: True.
// 
// Returns:
//  Date - The first/last (depending on the parameter) unblocked period
Function UnblockedPeriod(Companies, First = True) Export
	
	SetPrivilegedMode(True);

	If Not UseMechanismToBlockChanges() Then
		Return Date(1,1,1,0,0,0);
	EndIf;
		
	Query = New Query;
	Query.Text =
	"SELECT
	|	MIN(Locks.LockUntil) AS LockUntil
	|FROM
	|	InformationRegister.SetUpLockFromChanges AS Locks
	|WHERE
	|	Locks.Organization IN (&Companies)";
	
	Query.Text = StrReplace(Query.Text, "MIN", ?(First, "MIN", "MAX"));
	Query.SetParameter("Companies", Companies);
	
	Selection = Query.Execute().Select();
	If Selection.Next() And Not ValueIsFilled(Selection.LockUntil) Then
		Return Date(1,1,1,0,0,0);
	EndIf;
	
	Return BegOfMonth(AddMonth(Selection.LockUntil, 1));
	
EndFunction

// Use a mechanism to block changes.
// 
// Returns:
//  Boolean - 
Function UseMechanismToBlockChanges() Export
	
	ParameterValues = CalculationOfCostCached.ValuesOfTechnologicalParameters(
		Catalogs.MonthEndClosingOperations.EmptyRef());
	
	Return ParameterValues.UseMechanismToBlockChanges;
	
EndFunction

// Check the locks before starting the calculation.
// 
// Parameters:
//  CompanyArray - Array of CatalogRef.Companies - array of organizations
//  Period - Date - Period
Procedure CheckLocksBeforeStartingCalculation(CompanyArray, Period) Export
	
	Lock_Settings = InformationAboutBlockingChanges(CompanyArray, Period);
	
	IsPeriodLocked = Not Lock_Settings.ThereAreTasksInBlockedPeriod And Lock_Settings.PeriodIsBlockedForAllCompanies;
	
	If IsPeriodLocked Then
		
		 ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		 	NStr("vi = 'Không thể tính kỳ phong tỏa %1 theo doanh nghiệp %2';
					|ru = 'Невозможен расчет заблокированного период %1 по организациям %2';
					|en = 'Cannot calculate the locked period %1 by the %2 companies'; fa = 'Cannot calculate the locked period %1 by the %2 companies';
					|it = 'Невозможен расчет заблокированного период %1 по организациям %2';
					|pl = 'Cannot calculate the locked period %1 by the %2 companies';
					|tr = 'İş yerleri %2 tarafından engellenen %1 dönemi hesaplanamıyor'"),
			MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Period),
			CostCalculationAppliedAlgorithms.CalculatedCompanies(Lock_Settings.BlockedBusinesses, ", "));
		 
		 Raise ErrorText; // the calculation cannot be started
		 
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#EndRegion

#EndIf

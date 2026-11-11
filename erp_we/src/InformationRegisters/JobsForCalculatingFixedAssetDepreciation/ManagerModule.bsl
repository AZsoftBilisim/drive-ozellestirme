#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Increases the task number in a constant.
// 
// Returns:
//  Number - The previous task number.
//
Function IncreaseTaskNumber() Export
	
	Return MonthEndTransactionsServer.IncreaseTaskNumber(Metadata.Constants.NumberOfJobForCalculatingFixedAssetDepreciation.Name);
	
EndFunction

// Returns the period from which depreciation is to be calculated.
//
// Parameters:
//  CompaniesList	 - Array	 - Array of organizations.
// 
// Returns:
//  Date - The beginning of the month for which the depreciation calculation is required.
//
Function CalculationStart(CompaniesList) Export
	
	QueryText =
	"SELECT
	|	ISNULL(MIN(Jobs.Month), DATETIME(1, 1, 1)) AS CalculationStart
	|FROM
	|	InformationRegister.JobsForCalculatingFixedAssetDepreciation AS Jobs
	|WHERE
	|	Jobs.JobNumber <= &JobNumber
	|	AND Jobs.Organization IN (&CompaniesList)";
	
	Query = New Query(QueryText);
	Query.SetParameter("CompaniesList", CompaniesList);
	Query.SetParameter("JobNumber", CurTaskNumber());
	Selection = Query.Execute().Select();
	
	Selection.Next();
	
	Return Selection.CalculationStart;
	
EndFunction

// Reads the records of the register into a temporary table for the specified period according to selections.
//
// Parameters:
//  BeginOfPeriod	 - Date	- Start of the data sampling period.
//  PeriodEnding - Date	- End of the data sampling period.
//  JobNumber	 - Number	- Job number.
//	Companies - Array of CatalogRef.Companies - Filter by organization.
// 
// Returns:
//  Structure - Contains Properties:
//		* CompaniesList - Array of CatalogRef.Companies - Organizations that have tasks for them.
//		* BeginOfPeriod - Date - Date of the first task.
//		* TempTablesManager - TempTablesManager - Contains a temporary task table for the account.
//
Function JobsForCalculating(BeginOfPeriod, PeriodEnding, JobNumber, Companies) Export

	QueryText =
	"SELECT
	|	Jobs.Month,
	|	Jobs.PackageNumber,
	|	Jobs.Organization,
	|	Jobs.JobNumber,
	|	Jobs.Document
	|
	|INTO JobsForCalculating
	|
	|FROM
	|	InformationRegister.JobsForCalculatingFixedAssetDepreciation AS Jobs
	|
	|WHERE
	|	(Jobs.Month >= &BeginOfPeriod 
	|		OR &BeginOfPeriod = DATETIME(1,1,1))
	|	AND (Jobs.Month <= &PeriodEnding
	|		OR &PeriodEnding = DATETIME(1,1,1))
	|
	|	AND Jobs.JobNumber <= &JobNumber
	|	AND (Jobs.Organization IN (&Companies)
	|			OR &ByAllCompanies)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	JobsForCalculating.Organization
	|FROM
	|	JobsForCalculating AS JobsForCalculating
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(MIN(JobsForCalculating.Month), DATETIME(1,1,1)) AS BeginOfPeriod
	|FROM
	|	JobsForCalculating AS JobsForCalculating
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("PeriodEnding", PeriodEnding);
	Query.SetParameter("JobNumber", JobNumber);
	Query.SetParameter("Companies", Companies);
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(Companies));
	
	Result = Query.ExecuteBatch();
	Selection = Result[Result.UBound()].Select();
	Selection.Next();
	
	JobsForCalculating = New Structure;
	JobsForCalculating.Insert("CompaniesList", Result[Result.UBound()-1].Unload().UnloadColumn("Organization"));
	JobsForCalculating.Insert("BeginOfPeriod", Selection.BeginOfPeriod);
	JobsForCalculating.Insert("TempTablesManager", Query.TempTablesManager);
	
	Return JobsForCalculating;
	
EndFunction

// Determines whether the calculation is necessary for the specified period.
//
// Parameters:
//  CompaniesList	 - Array	 - List of organizations.
//  Period				 - Date		 - The period being checked.
// 
// Returns:
//  Boolean - True if calculation is required.
//
Function CalculationIsRequired(CompaniesList, Period) Export

	If Not NonCurrentAssets.VNAManagementIsUsed() Then
		Return False;
	EndIf;
	
	QueryText = NonCurrentAssetsLocalization.QueryTextRequiresFADepreciationCalculation(Period);
	
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT TOP 1
		|	1 AS Field1
		|FROM
		|	InformationRegister.AccountingProcedureForOSBU.SliceLast(
		|			&Period, 
		|			Organization IN (&Organization)
		|				AND (CorrectionDate = DATETIME(1,1,1)
		|					OR CorrectionDate >= &Period)) AS DepreciationAccrual
		|WHERE
		|	DepreciationAccrual.DepreciationAccrualAccounting
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	1
		|FROM
		|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
		|			&Period, 
		|			Organization IN (&Organization)
		|				AND (CorrectionDate = DATETIME(1,1,1)
		|					OR CorrectionDate >= &Period)) AS DepreciationAccrual
		|WHERE
		|	DepreciationAccrual.AccrueDepreciationOrAmortization
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	1
		|FROM
		|	InformationRegister.AccountingProcedureForOSBU AS DepreciationAccrual
		|WHERE
		|	DepreciationAccrual.DepreciationAccrualAccounting
		|	AND DepreciationAccrual.Organization IN(&Organization)
		|	AND DepreciationAccrual.Period >= &Period
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	1
		|FROM
		|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting AS DepreciationAccrual
		|WHERE
		|	DepreciationAccrual.AccrueDepreciationOrAmortization
		|	AND DepreciationAccrual.Organization IN(&Organization)
		|	AND DepreciationAccrual.Period >= &Period
		|";
	
	EndIf; 
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", CompaniesList);
	If FixedAssetDepreciationCalculation.DepreciationMayAccrueFromDateOfAcceptanceForAccounting(CompaniesList, Period) Then
		Query.SetParameter("Period", EndOfMonth(Period));
	Else	
		Query.SetParameter("Period", BegOfMonth(Period));
	EndIf;
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	Return Not QueryResult.IsEmpty();

EndFunction
 
// Records successful execution of operation.
// 
// Parameters:
//  Period - Date - Period
//  CompaniesList - Array - List of organizations
//  NumberBeforeSettlement - Number - Number Before Settlement
//  DepreciationPackages - ValueTable - Depreciation packages
Procedure FixCalculation(Period, CompaniesList, NumberBeforeSettlement, DepreciationPackages = Undefined) Export

	SetPrivilegedMode(True);
	
	// Adding records for the next period
	TasksForNextPeriod = TasksForNextPeriod(Period, CompaniesList, NumberBeforeSettlement, DepreciationPackages);
	If TasksForNextPeriod <> Undefined Then
		For Each Selection In TasksForNextPeriod Do
			NewRecord = CreateRecordManager();
			FillPropertyValues(NewRecord, Selection);
			NewRecord.JobNumber = NumberBeforeSettlement;
			NewRecord.Write(True);
		EndDo;
	EndIf; 
	
	// Deleting tasks that were calculated for
	If DepreciationPackages <> Undefined Then
		
		QueryText =
		"SELECT DISTINCT
		|	DepreciationPackages.Organization AS Organization,
		|	DepreciationPackages.PackageNumber AS PackageNumber
		|INTO DepreciationPackages
		|FROM
		|	&DepreciationPackages AS DepreciationPackages
		|
		|INDEX BY
		|	Organization,
		|	PackageNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Jobs.Month AS Month,
		|	Jobs.PackageNumber AS PackageNumber,
		|	Jobs.Organization AS Organization,
		|	Jobs.JobNumber AS JobNumber
		|FROM
		|	InformationRegister.JobsForCalculatingFixedAssetDepreciation AS Jobs
		|WHERE
		|	Jobs.Month BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND Jobs.JobNumber <= &JobNumber
		|	AND (Jobs.Organization, Jobs.PackageNumber) IN
		|		(SELECT
		|			DepreciationPackages.Organization,
		|			DepreciationPackages.PackageNumber
		|		FROM
		|			DepreciationPackages AS DepreciationPackages)";
		
	Else
		
		QueryText =
		"SELECT DISTINCT
		|	Jobs.Month AS Month,
		|	Jobs.PackageNumber AS PackageNumber,
		|	Jobs.Organization AS Organization,
		|	Jobs.JobNumber AS JobNumber
		|
		|FROM
		|	InformationRegister.JobsForCalculatingFixedAssetDepreciation AS Jobs
		|
		|WHERE
		|	Jobs.Month BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND Jobs.JobNumber <= &JobNumber
		|	AND Jobs.Organization IN (&CompaniesList)
		|";
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("BeginOfPeriod", BegOfMonth(Period));
	Query.SetParameter("PeriodEnding", EndOfMonth(Period));
	Query.SetParameter("JobNumber", NumberBeforeSettlement);
	Query.SetParameter("CompaniesList", CompaniesList);
	Query.SetParameter("DepreciationPackages", DepreciationPackages);
	
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		Set = CreateRecordSet();
		Set.Filter.Month.Set(Selection.Month);
		Set.Filter.PackageNumber.Set(Selection.PackageNumber);
		Set.Filter.Organization.Set(Selection.Organization);
		Set.Filter.JobNumber.Set(Selection.JobNumber);
		Set.Write(); 
	EndDo;
		
EndProcedure

// This method creates register entries with the parameters received by the request.
//
// Parameters:
//	Selection - QueryResultSelection - a sample of the data to generate the records.
//  JobNumber - Number - task number; if omitted, the value from the corresponding constant will be set.
//
Procedure CreateRegisterEntriesBasedOnSampleData(Selection, JobNumber = Undefined) Export
	
	If ExchangePlans.MasterNode() <> Undefined Then
		// In RIB, this register is processed only in the main node.
		Return;
	EndIf;
	
	If Selection.Count() = 0 Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		FieldsStructure = New Structure("Month, Organization, PackageNumber, Document");
		
		If JobNumber = Undefined Then
			JobNumber = CurTaskNumber();
		EndIf;
		
		While Selection.Next() Do
			
			FillPropertyValues(FieldsStructure, Selection);
			
			CreateRegisterEntry(
				FieldsStructure.Month, 
				FieldsStructure.Document, 
				FieldsStructure.Organization, 
				FieldsStructure.PackageNumber, 
				JobNumber);
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(NStr("vi = 'Kết chuyển cuối tháng';
							|ru = 'Закрытие месяца';
							|en = 'Month-end closing'; fa = 'بستن پایان ماه';
							|it = 'Chiusura del mese';
							|pl = 'Zamknięcie miesiąca';
							|tr = 'Ay sonu kapanışı'", 
			Common.DefaultLanguageCode()), EventLogLevel.Error, , , ErrorText);
		
		Raise ErrorText;
		
	EndTry;
	
EndProcedure

// Adds a new task.
//
// Parameters:
//  TaskPeriod	 - Date - The month in which the task is added.
//  DocumentJobs	 - DocumentRef - The document that was modified to create the task.
//  Organization		 - CatalogRef.Companies - The organization that the task is being added to.
//  PackageNumber		 - Number - Number of the fixed asset package.
//  JobNumber	 - Number - Job number.
//
Procedure CreateRegisterEntry(TaskPeriod, DocumentJobs, Organization, PackageNumber, JobNumber = Undefined) Export
				
	SetPrivilegedMode(True);
	
	If ExchangePlans.MasterNode() <> Undefined Then
		// In RIB, this register is processed only in the main node.
		Return;
	EndIf;
	
	// Let's write down the tasks
	BeginTransaction();
	Try
	
		If JobNumber = Undefined Then
			JobNumber = CurTaskNumber();
		EndIf; 
		
		RecordSet = InformationRegisters.JobsForCalculatingFixedAssetDepreciation.CreateRecordManager();
		RecordSet.Month        = BegOfMonth(TaskPeriod);
		RecordSet.PackageNumber  = PackageNumber;
		RecordSet.Organization  = Organization;
		RecordSet.Document     = DocumentJobs;
		RecordSet.JobNumber = JobNumber;
		RecordSet.Write(True);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorText = DetailErrorDescription(ErrorInfo());
		Raise ErrorText;
	EndTry; 
	
EndProcedure

// See PeriodClosingDatesOverridable.FillDataSourcesForPeriodClosingCheck
Procedure DescriptionOfRegistersForControlOfDatesOfProhibitionOfChange(DataSources) Export
	
	PeriodClosingDates.AddRow(DataSources, "InformationRegister.AssetActivityRecords", "Period", "RoutineOperations");
	
EndProcedure

// Returns a list of metadata objects that are used for generating register entries.
//
//Returns:
// Array of MetadataObject
Function IncomingMechanismData() Export
	
	IncomingData = New Array;
	IncomingData.Add(Metadata.AccumulationRegisters.FACost);

	IncomingData.Add(Metadata.InformationRegisters.LeasedAsset);
	IncomingData.Add(Metadata.InformationRegisters.FALocation);
	IncomingData.Add(Metadata.InformationRegisters.AssetActivityRecords);
	IncomingData.Add(Metadata.InformationRegisters.OSBUDepreciationParameters);
	IncomingData.Add(Metadata.InformationRegisters.FixedAssetDepreciationParametersManagementAccounting);
	IncomingData.Add(Metadata.InformationRegisters.InitialFixedAssetsInformation);
	IncomingData.Add(Metadata.InformationRegisters.FixedAssetsAccountingProcedure);
	IncomingData.Add(Metadata.InformationRegisters.AccountingProcedureForOSBU);
	IncomingData.Add(Metadata.InformationRegisters.FixedAssetsAccountingProcedureManagementAccounting);
	
	Return IncomingData;
	
EndFunction

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

#EndRegion

#EndRegion

#Region Private

Function CurTaskNumber()
	SetPrivilegedMode(True);
	CurTaskNumber = Constants.NumberOfJobForCalculatingFixedAssetDepreciation.Get();
	SetPrivilegedMode(False);
	Return CurTaskNumber;
EndFunction

Function TasksForNextPeriod(Period, CompaniesList, NumberBeforeSettlement, DepreciationPackages)

	If Not NonCurrentAssets.VNAManagementIsUsed() Then
		Return Undefined;
	EndIf;
	
	// Tasks for the next month, if at the beginning of the month there are objects for which depreciation is charged
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("BeginningOfNextMonth", EndOfMonth(Period) + 1);
	Query.SetParameter("EndOfNextMonth", EndOfMonth(EndOfMonth(Period) + 1));
	Query.SetParameter("EndOfMonth", EndOfMonth(Period));
	Query.SetParameter("CompaniesList", CompaniesList);
	Query.SetParameter("DepreciationPackages", DepreciationPackages);
	Query.SetParameter("UseFASelection", DepreciationPackages <> Undefined);

	ListOfRequests = New Array;
	
	If DepreciationPackages <> Undefined Then
		
		QueryText =
		"SELECT DISTINCT
		|	DepreciationPackages.Organization AS Organization,
		|	DepreciationPackages.PackageNumber AS PackageNumber
		|
		|INTO DepreciationPackages
		|
		|FROM
		|	&DepreciationPackages AS DepreciationPackages
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DepreciationPackages.Organization AS Organization, 
		|	DepreciationPackages.FixedAsset AS FixedAsset
		|
		|INTO FilterFA
		|
		|FROM
		|	InformationRegister.FixedAssetDepreciationPackages AS DepreciationPackages
		|
		|WHERE
		|	(Organization, PackageNumber) IN 
		|		(SELECT
		|			DepreciationPackages.Organization, 
		|			DepreciationPackages.PackageNumber
		|		FROM
		|			DepreciationPackages AS DepreciationPackages)
		|
		|INDEX BY
		|	FixedAsset,
		|	Organization";
		
	Else
		
		QueryText =
		"SELECT
		|	UNDEFINED AS Organization,
		|	UNDEFINED AS PackageNumber
		|
		|INTO DepreciationPackages
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	UNDEFINED AS Organization,
		|	UNDEFINED AS FixedAsset
		|INTO FilterFA
		|";
		
	EndIf;
	ListOfRequests.Add(QueryText);
	
	QueryText = 
	"SELECT DISTINCT
	|	DepreciationAccrual.Organization,
	|	DepreciationAccrual.PackageNumber,
	|	&BeginningOfNextMonth AS Month
	|FROM
	|	(SELECT
	|		DepreciationAccrual.Organization,
	|		ISNULL(DepreciationPackages.PackageNumber, 0) AS PackageNumber
	|	FROM
	|		InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
	|			&EndOfMonth, 
	|			CorrectionDate = DATETIME(1,1,1)
	|				AND Organization IN (&CompaniesList)
	|				AND (NOT &UseFASelection
	|					OR (Organization, FixedAsset) IN 
	|							(SELECT
	|								FilterFA.Organization, 
	|								FilterFA.FixedAsset
	|							FROM
	|								FilterFA AS FilterFA))) AS DepreciationAccrual
	|
	|			LEFT JOIN InformationRegister.FixedAssetDepreciationPackages AS DepreciationPackages
	|			ON DepreciationPackages.Organization = DepreciationAccrual.Organization
	|				AND DepreciationPackages.FixedAsset = DepreciationAccrual.FixedAsset
	|	WHERE
	|		DepreciationAccrual.AccrueDepreciationOrAmortization
	|
	|	UNION ALL
	|
	|	SELECT
	|		DepreciationAccrual.Organization AS Organization,
	|		ISNULL(DepreciationPackages.PackageNumber, 0) AS PackageNumber
	|	FROM
	|		InformationRegister.AccountingProcedureForOSBU.SliceLast(
	|			&EndOfMonth, 
	|			CorrectionDate = DATETIME(1,1,1)
	|				AND Organization IN (&CompaniesList)
	|				AND (NOT &UseFASelection
	|					OR (Organization, FixedAsset) IN 
	|							(SELECT
	|								FilterFA.Organization, 
	|								FilterFA.FixedAsset
	|							FROM
	|								FilterFA AS FilterFA))) AS DepreciationAccrual
	|
	|			LEFT JOIN InformationRegister.FixedAssetDepreciationPackages AS DepreciationPackages
	|			ON DepreciationPackages.Organization = DepreciationAccrual.Organization
	|				AND DepreciationPackages.FixedAsset = DepreciationAccrual.FixedAsset
	|	WHERE
	|		(DepreciationAccrual.DepreciationAccrualAccounting
	|			OR DepreciationAccrual.DepreciationAccrualTaxAccounting)
	|
	|	UNION ALL
	|
	|	SELECT
	|		FixedAssetsDepreciationCharge.Organization AS Organization,
	|		FixedAssetsDepreciationCharge.PackageNumber AS PackageNumber
	|	FROM
	|		Document.FixedAssetsDepreciationCharge2_4 AS FixedAssetsDepreciationCharge
	|
	|	WHERE
	|		FixedAssetsDepreciationCharge.Date BETWEEN &BeginningOfNextMonth AND &EndOfNextMonth
	|		AND FixedAssetsDepreciationCharge.Posted
	|		AND FixedAssetsDepreciationCharge.Organization IN (&CompaniesList)
	|		AND (NOT &UseFASelection
	|			OR (FixedAssetsDepreciationCharge.Organization, FixedAssetsDepreciationCharge.PackageNumber) IN 
	|					(SELECT
	|						DepreciationPackages.Organization, 
	|						DepreciationPackages.PackageNumber
	|					FROM
	|						DepreciationPackages AS DepreciationPackages))
	|
	|	) AS DepreciationAccrual
	|";
	ListOfRequests.Add(QueryText);
	
	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	SetPrivilegedMode(True);
	TasksForNextPeriod = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	If TasksForNextPeriod.Count() <> 0 Then
		Return TasksForNextPeriod;
	EndIf;
	
	// tasks for the next month in which depreciation is calculated

	Query.Text = 
	"SELECT
	|	DepreciationAccrual.Organization,
	|	DepreciationAccrual.PackageNumber,
	|	DATETIME(1, 1, 1) AS Month,
	|	ISNULL(MIN(DepreciationAccrual.Period), DATETIME(1, 1, 1)) AS Period
	|FROM
	|	(SELECT
	|		DepreciationAccrual.Organization AS Organization,
	|		ISNULL(DepreciationPackages.PackageNumber, 0) AS PackageNumber,
	|		BEGINOFPERIOD(DepreciationAccrual.Period, MONTH) AS Period
	|	FROM
	|		InformationRegister.FixedAssetsAccountingProcedureManagementAccounting AS DepreciationAccrual
	|
	|			LEFT JOIN InformationRegister.FixedAssetDepreciationPackages AS DepreciationPackages
	|			ON DepreciationPackages.Organization = DepreciationAccrual.Organization
	|				AND DepreciationPackages.FixedAsset = DepreciationAccrual.FixedAsset
	|	WHERE
	|		DepreciationAccrual.AccrueDepreciationOrAmortization
	|		AND DepreciationAccrual.Organization IN (&CompaniesList)
	|		AND DepreciationAccrual.Period >= &BeginningOfNextMonth
	|		AND DepreciationAccrual.CorrectionDate = DATETIME(1,1,1)
	|
	|		AND (NOT &UseFASelection
	|				OR (DepreciationAccrual.Organization, DepreciationAccrual.FixedAsset) IN 
	|						(SELECT
	|							FilterFA.Organization, 
	|							FilterFA.FixedAsset
	|						FROM
	|							FilterFA AS FilterFA))
	|
	|	UNION ALL
	|
	|	SELECT
	|		DepreciationAccrual.Organization,
	|		ISNULL(DepreciationPackages.PackageNumber, 0) AS PackageNumber,
	|		BEGINOFPERIOD(DepreciationAccrual.Period, MONTH) AS Period
	|	FROM
	|		InformationRegister.AccountingProcedureForOSBU AS DepreciationAccrual
	|
	|			LEFT JOIN InformationRegister.FixedAssetDepreciationPackages AS DepreciationPackages
	|			ON DepreciationPackages.Organization = DepreciationAccrual.Organization
	|				AND DepreciationPackages.FixedAsset = DepreciationAccrual.FixedAsset
	|	WHERE
	|		(DepreciationAccrual.DepreciationAccrualAccounting
	|			OR DepreciationAccrual.DepreciationAccrualTaxAccounting)
	|		AND DepreciationAccrual.Organization IN (&CompaniesList)
	|		AND DepreciationAccrual.Period >= &BeginningOfNextMonth
	|		AND DepreciationAccrual.CorrectionDate = DATETIME(1,1,1)
	|
	|		AND (NOT &UseFASelection
	|				OR (DepreciationAccrual.Organization, DepreciationAccrual.FixedAsset) IN 
	|						(SELECT
	|							FilterFA.Organization, 
	|							FilterFA.FixedAsset
	|						FROM
	|							FilterFA AS FilterFA))
	|
	|	UNION ALL
	|
	|	SELECT
	|		FixedAssetsDepreciationCharge.Organization AS Organization,
	|		FixedAssetsDepreciationCharge.PackageNumber AS PackageNumber,
	|		BEGINOFPERIOD(FixedAssetsDepreciationCharge.Date, MONTH) AS Period
	|	FROM
	|		Document.FixedAssetsDepreciationCharge2_4 AS FixedAssetsDepreciationCharge
	|
	|	WHERE
	|		FixedAssetsDepreciationCharge.Date >= &BeginningOfNextMonth
	|		AND FixedAssetsDepreciationCharge.Posted
	|		AND FixedAssetsDepreciationCharge.Organization IN (&CompaniesList)
	|
	|		AND (NOT &UseFASelection
	|			OR (FixedAssetsDepreciationCharge.Organization, FixedAssetsDepreciationCharge.PackageNumber) IN 
	|					(SELECT
	|						DepreciationPackages.Organization, 
	|						DepreciationPackages.PackageNumber
	|					FROM
	|						DepreciationPackages AS DepreciationPackages))
	|
	|	) AS DepreciationAccrual
	|
	|GROUP BY
	|	DepreciationAccrual.Organization,
	|	DepreciationAccrual.PackageNumber
	|
	|HAVING
	|	ISNULL(MIN(DepreciationAccrual.Period), DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1)
	|";

	SetPrivilegedMode(True);
	TasksForNextPeriod = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	For Each TaskData_ In TasksForNextPeriod Do
		
		If FixedAssetDepreciationCalculation.DepreciationMayAccrueFromDateOfAcceptanceForAccounting(TaskData_.Organization, TaskData_.Period) Then
			TaskData_.Month = TaskData_.Period;
		Else
			TaskData_.Month = AddMonth(TaskData_.Period, 1);
		EndIf;
		
	EndDo;
	
	Return TasksForNextPeriod;

EndFunction

#EndRegion

#EndIf
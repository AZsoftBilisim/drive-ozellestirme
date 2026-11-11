#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Increases the task number in a constant.
// 
// Returns:
//  Number - The previous task number.
//
Function IncreaseTaskNumber() Export
	
	Return MonthEndTransactionsServer.IncreaseTaskNumber(Metadata.Constants.NumberOfJobForCalculatingIntangibleAssetAmortization.Name);
	
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
	|	InformationRegister.JobsForCalculatingIntangibleAssetAmortization AS Jobs
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
	|	InformationRegister.JobsForCalculatingIntangibleAssetAmortization AS Jobs
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
	
	QueryText = NonCurrentAssetsLocalization.QueryTextRequiresCalculationOfIaDepreciation(Period);
	
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT TOP 1
		|	1 AS Field1
		|FROM
		|	InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast(
		|			&Period, 
		|			Organization IN (&Organization)) AS DepreciationAccrual
		|WHERE
		|	DepreciationAccrual.DepreciationAccrualAccounting
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	1
		|FROM
		|	InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(
		|			&Period, 
		|			Organization IN (&Organization)) AS DepreciationAccrual
		|WHERE
		|	DepreciationAccrual.AccrueDepreciationOrAmortization
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	1
		|FROM
		|	InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting AS DepreciationAccrual
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
		|	InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting AS DepreciationAccrual
		|WHERE
		|	DepreciationAccrual.AccrueDepreciationOrAmortization
		|	AND DepreciationAccrual.Organization IN(&Organization)
		|	AND DepreciationAccrual.Period >= &Period
		|";
	
	EndIf; 
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", CompaniesList);
	If IntangibleAssetAmortizationCalculation.DepreciationMayAccrueFromDateOfAcceptanceForAccounting(CompaniesList, Period) Then
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
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Jobs.Month AS Month,
		|	Jobs.PackageNumber AS PackageNumber,
		|	Jobs.Organization AS Organization,
		|	Jobs.JobNumber AS JobNumber
		|FROM
		|	InformationRegister.JobsForCalculatingIntangibleAssetAmortization AS Jobs
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
		|	InformationRegister.JobsForCalculatingIntangibleAssetAmortization AS Jobs
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
		
		ErrorText    = DetailErrorDescription(ErrorInfo());
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tạo nhiệm vụ tính khấu hao tài sản cố định vô hình cho %1 trong doanh nghiệp %2 do: %3';
				|ru = 'Не удалось сформировать задание к расчету амортизации НМА за %1 в организации %2 по причине: %3';
				|en = 'Cannot generate a job to calculate intangible asset amortization for %1 in company %2. Reason: %3'; fa = 'Cannot generate a job to calculate intangible asset amortization for %1 in company %2. Reason: %3';
				|it = 'Impossibile creare un task per il calcolo dell''ammortamento dei Beni Immateriali per %1 nell''azienda %2 a causa di: %3';
				|pl = 'Nie udało się utworzyć zadanie do kalkulacja amortyzacji wartości niematerialnych za %1 w firmie %2 z powodu: %3';
				|tr = '%2 iş yerinde %1 kapsamında maddi olmayan varlık amortismanını hesaplama görevi şu nedenden dolayı oluşturulamadı: %3'"),
			Selection.Month,
			Selection.Organization,
			ErrorText);
			
		WriteLogEvent(NStr("vi = 'Kết chuyển cuối tháng';
							|ru = 'Закрытие месяца';
							|en = 'Month-end closing'; fa = 'بستن پایان ماه';
							|it = 'Chiusura del mese';
							|pl = 'Zamknięcie miesiąca';
							|tr = 'Ay sonu kapanışı'", CommonClientServer.DefaultLanguageCode()), EventLogLevel.Error, , , MessageText);
		
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
		
		RecordSet = InformationRegisters.JobsForCalculatingIntangibleAssetAmortization.CreateRecordManager();
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
	
	PeriodClosingDates.AddRow(DataSources, "AccumulationRegister.IntangibleAssetsOperatingTime", "Period", "RoutineOperations", "Organization");
	PeriodClosingDates.AddRow(DataSources, "InformationRegister.InitialIntangibleAssetsInformation", "Period", "RoutineOperations", "Organization");
	PeriodClosingDates.AddRow(DataSources, "InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting", "Period", "RoutineOperations", "Organization");
	PeriodClosingDates.AddRow(DataSources, "InformationRegister.IADepreciationParametersBookkeepingAndTaxAccounting", "Period", "RoutineOperations", "Organization");
	
EndProcedure

// Returns a list of metadata objects that are used for generating register entries.
//
//Returns:
// Array of MetadataObject
Function IncomingMechanismData() Export
	
	IncomingData = New Array;
	IncomingData.Add(Metadata.AccumulationRegisters.IntangibleAssetsOperatingTime);
	IncomingData.Add(Metadata.AccumulationRegisters.IACost);

	IncomingData.Add(Metadata.InformationRegisters.IntangibleAssetsRegistrationPlace);
	IncomingData.Add(Metadata.InformationRegisters.IADepreciationParametersBookkeepingAndTaxAccounting);
	IncomingData.Add(Metadata.InformationRegisters.IntangibleAssetAmortizationParametersManagementAccounting);
	IncomingData.Add(Metadata.InformationRegisters.InitialIntangibleAssetsInformation);
	IncomingData.Add(Metadata.InformationRegisters.IntangibleAssetsAccountingProcedure);
	IncomingData.Add(Metadata.InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting);
	IncomingData.Add(Metadata.InformationRegisters.IntangibleAssetsAccountingProcedureManagementAccounting);
	
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
	CurTaskNumber = Constants.NumberOfJobForCalculatingIntangibleAssetAmortization.Get();
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
	Query.SetParameter("UseIASelection", DepreciationPackages <> Undefined);

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
		|	DepreciationPackages.IntangibleAsset AS IntangibleAsset
		|
		|INTO FilterFA
		|
		|FROM
		|	InformationRegister.IntangibleAssetAmortizationPackages AS DepreciationPackages
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
		|	IntangibleAsset,
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
		|	UNDEFINED AS IntangibleAsset
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
	|		InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(
	|			&EndOfMonth, 
	|			Organization IN (&CompaniesList)
	|				AND (NOT &UseIASelection
	|					OR (Organization, IntangibleAsset) IN 
	|							(SELECT
	|								FilterFA.Organization, 
	|								FilterFA.IntangibleAsset
	|							FROM
	|								FilterFA AS FilterFA))) AS DepreciationAccrual
	|
	|			LEFT JOIN InformationRegister.IntangibleAssetAmortizationPackages AS DepreciationPackages
	|			ON DepreciationPackages.Organization = DepreciationAccrual.Organization
	|				AND DepreciationPackages.IntangibleAsset = DepreciationAccrual.IntangibleAsset
	|	WHERE
	|		DepreciationAccrual.AccrueDepreciationOrAmortization
	|
	|	UNION ALL
	|
	|	SELECT
	|		DepreciationAccrual.Organization AS Organization,
	|		ISNULL(DepreciationPackages.PackageNumber, 0) AS PackageNumber
	|	FROM
	|		InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast(
	|			&EndOfMonth, 
	|			Organization IN (&CompaniesList)
	|				AND (NOT &UseIASelection
	|					OR (Organization, IntangibleAsset) IN 
	|							(SELECT
	|								FilterFA.Organization, 
	|								FilterFA.IntangibleAsset
	|							FROM
	|								FilterFA AS FilterFA))) AS DepreciationAccrual
	|
	|			LEFT JOIN InformationRegister.IntangibleAssetAmortizationPackages AS DepreciationPackages
	|			ON DepreciationPackages.Organization = DepreciationAccrual.Organization
	|				AND DepreciationPackages.IntangibleAsset = DepreciationAccrual.IntangibleAsset
	|	WHERE
	|		(DepreciationAccrual.DepreciationAccrualAccounting
	|			OR DepreciationAccrual.DepreciationAccrualTaxAccounting)
	|
	|	UNION ALL
	|
	|	SELECT
	|		IntangibleAssetsAmortizationCharge.Organization AS Organization,
	|		IntangibleAssetsAmortizationCharge.PackageNumber AS PackageNumber
	|	FROM
	|		Document.IntangibleAssetsAmortizationCharge2_4 AS IntangibleAssetsAmortizationCharge
	|
	|	WHERE
	|		IntangibleAssetsAmortizationCharge.Date BETWEEN &BeginningOfNextMonth AND &EndOfNextMonth
	|		AND IntangibleAssetsAmortizationCharge.Posted
	|		AND IntangibleAssetsAmortizationCharge.Organization IN (&CompaniesList)
	|		AND (NOT &UseIASelection
	|			OR (IntangibleAssetsAmortizationCharge.Organization, IntangibleAssetsAmortizationCharge.PackageNumber) IN 
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
	|		InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting AS DepreciationAccrual
	|
	|			LEFT JOIN InformationRegister.IntangibleAssetAmortizationPackages AS DepreciationPackages
	|			ON DepreciationPackages.Organization = DepreciationAccrual.Organization
	|				AND DepreciationPackages.IntangibleAsset = DepreciationAccrual.IntangibleAsset
	|	WHERE
	|		DepreciationAccrual.AccrueDepreciationOrAmortization
	|		AND DepreciationAccrual.Organization IN (&CompaniesList)
	|		AND DepreciationAccrual.Period >= &BeginningOfNextMonth
	|
	|		AND (NOT &UseIASelection
	|				OR (DepreciationAccrual.Organization, DepreciationAccrual.IntangibleAsset) IN 
	|						(SELECT
	|							FilterFA.Organization, 
	|							FilterFA.IntangibleAsset
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
	|		InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting AS DepreciationAccrual
	|
	|			LEFT JOIN InformationRegister.IntangibleAssetAmortizationPackages AS DepreciationPackages
	|			ON DepreciationPackages.Organization = DepreciationAccrual.Organization
	|				AND DepreciationPackages.IntangibleAsset = DepreciationAccrual.IntangibleAsset
	|	WHERE
	|		(DepreciationAccrual.DepreciationAccrualAccounting
	|			OR DepreciationAccrual.DepreciationAccrualTaxAccounting)
	|		AND DepreciationAccrual.Organization IN (&CompaniesList)
	|		AND DepreciationAccrual.Period >= &BeginningOfNextMonth
	|
	|		AND (NOT &UseIASelection
	|				OR (DepreciationAccrual.Organization, DepreciationAccrual.IntangibleAsset) IN 
	|						(SELECT
	|							FilterFA.Organization, 
	|							FilterFA.IntangibleAsset
	|						FROM
	|							FilterFA AS FilterFA))
	|
	|	UNION ALL
	|
	|	SELECT
	|		IntangibleAssetsAmortizationCharge.Organization AS Organization,
	|		IntangibleAssetsAmortizationCharge.PackageNumber AS PackageNumber,
	|		BEGINOFPERIOD(IntangibleAssetsAmortizationCharge.Date, MONTH) AS Period
	|	FROM
	|		Document.IntangibleAssetsAmortizationCharge2_4 AS IntangibleAssetsAmortizationCharge
	|
	|	WHERE
	|		IntangibleAssetsAmortizationCharge.Date >= &BeginningOfNextMonth
	|		AND IntangibleAssetsAmortizationCharge.Posted
	|		AND IntangibleAssetsAmortizationCharge.Organization IN (&CompaniesList)
	|
	|		AND (NOT &UseIASelection
	|			OR (IntangibleAssetsAmortizationCharge.Organization, IntangibleAssetsAmortizationCharge.PackageNumber) IN 
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
		
		If IntangibleAssetAmortizationCalculation.DepreciationMayAccrueFromDateOfAcceptanceForAccounting(TaskData_.Organization, TaskData_.Period) Then
			TaskData_.Month = TaskData_.Period;
		Else
			TaskData_.Month = AddMonth(TaskData_.Period, 1);
		EndIf;
		
	EndDo;
	
	Return TasksForNextPeriod;

EndFunction

#EndRegion

#EndIf
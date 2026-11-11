#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Increases the task number in a constant.
// 
// Returns:
//  Number - The previous task number.
//
Function IncreaseTaskNumber() Export
	
	Return MonthEndTransactionsServer.IncreaseTaskNumber(Metadata.Constants.JobNumberForGeneratingFixedAssetRecords.Name);
	
EndFunction

// Reads the records of the register into a temporary table for the specified period according to selections.
//
// Parameters:
//	BeginOfPeriod - Date - Start of the data sampling period.
//	PeriodEnding - Date - End of the data sampling period.
//	TaskNumberBeforeCalculation - Number -
//	Companies - Array of CatalogRef.Companies - Filter by organization.
//
// Returns:
//	Structure:
//		* CompaniesList - Array of CatalogRef.Companies - Organizations that have tasks for them.
//		* BeginOfPeriod - Date - The beginning of the task period.
//		* TempTablesManager - TempTablesManager - Contains a temporary task table for the account.
//
Function JobsForCalculating(BeginOfPeriod, PeriodEnding, TaskNumberBeforeCalculation, Companies) Export

	QueryText =
	"SELECT
	|	Jobs.Month               AS Month,
	|	Jobs.AccountingObject         AS AccountingObject,
	|	Jobs.Organization         AS Organization,
	|	Jobs.JobNumber        AS JobNumber,
	|	Jobs.Document            AS Document
	|
	|INTO JobsForCalculating
	|
	|FROM
	|	InformationRegister.JobsForGeneratingFixedAssetRecords AS Jobs
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
	|
	|INDEX BY
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(MIN(JobsForCalculating.Month), DATETIME(1,1,1)) AS BeginOfPeriod
	|FROM
	|	JobsForCalculating AS JobsForCalculating
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	JobsForCalculating.Organization
	|FROM
	|	JobsForCalculating AS JobsForCalculating";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("PeriodEnding", PeriodEnding);
	Query.SetParameter("JobNumber", TaskNumberBeforeCalculation);
	Query.SetParameter("Companies", Companies);
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(Companies));
	
	Result = Query.ExecuteBatch();
	
	Selection = Result[Result.UBound()-1].Select();
	If Selection.Next() Then
		BeginningOfTaskPeriod = Selection.BeginOfPeriod;
	Else
		BeginningOfTaskPeriod = '000101010000';
	EndIf;
	
	JobsForCalculating = New Structure;
	JobsForCalculating.Insert("CompaniesList", Result[Result.UBound()].Unload().UnloadColumn("Organization"));
	JobsForCalculating.Insert("BeginOfPeriod", BeginningOfTaskPeriod);
	JobsForCalculating.Insert("TempTablesManager", Query.TempTablesManager);
	
	Return JobsForCalculating;
	
EndFunction

// This method creates register entries with the parameters received by the request.
//
// Parameters:
//  Selection		 - QueryResultSelection - a sample of the data to generate the records.
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
		
		FieldsStructure = New Structure("Month, Organization, AccountingObject, Document");
		
		If JobNumber = Undefined Then
			JobNumber = CurTaskNumber();
		EndIf;
		
		While Selection.Next() Do
			
			If Not ValueIsFilled(Selection.AccountingObject) Then
				Continue;
			EndIf;	
					
			FillPropertyValues(FieldsStructure, Selection);
			
			CreateRegisterEntry(
				FieldsStructure.Month, 
				FieldsStructure.Document, 
				FieldsStructure.Organization, 
				FieldsStructure.AccountingObject, 
				JobNumber);
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorText    = DetailErrorDescription(ErrorInfo());
		MessageText = StrTemplate(
			NStr("vi = 'Không thể xây dựng một nhiệm vụ để đổi giá trị hàng tồn kho cho %1 trong doanh nghiệp %2 do: %3';
				|ru = 'Не удалось сформировать задание к погашению стоимости ТМЦ за %1 в организации %2 по причине: %3';
				|en = 'Cannot generate a job for repayment of inventory for %1 in the %2 company. Reason: %3'; fa = 'Cannot generate a job for repayment of inventory for %1 in the %2 company. Reason: %3';
				|it = 'Impossibile creare un task per il rimborso del valore dei beni per %1 nell''azienda %2 a causa di:%3';
				|pl = 'Nie udało się utworzyć zadanie do zwrotu kosztów wartości towarowo-materialnych za %1 w firmie %2 z powodu: %3';
				|tr = '%2 iş yerinde %1 kapsamında stok maliyetini ödemek için görev oluşturmak şu nedenden dolayı oluşturulamadı: %3'"),
			Selection.Month,
			Selection.Organization,
			ErrorText);
			
		WriteLogEvent(
			NStr("vi = 'Kết chuyển cuối tháng';
				|ru = 'Закрытие месяца';
				|en = 'Month-end closing'; fa = 'بستن پایان ماه';
				|it = 'Chiusura del mese';
				|pl = 'Zamknięcie miesiąca';
				|tr = 'Ay sonu kapanışı'", CommonClientServer.DefaultLanguageCode()), 
			EventLogLevel.Error,,, 
			MessageText);
			
		Raise ErrorText;
			
	EndTry;
	
EndProcedure

// Creates register entries based on the table of tasks and formationmovement.
//
// Parameters:
//  TempTablesManager	- TempTablesManager - a sample of the data to generate the records.
//  JobNumber - Number - task number; if omitted, the value from the corresponding constant will be set.
//
Procedure CreateRegisterEntriesOnTemporaryTable(TempTablesManager, JobNumber = Undefined) Export
	
	If ExchangePlans.MasterNode() <> Undefined Then
		// In RIB, this register is processed only in the main node.
		Return;
	EndIf;
	
	QueryText =
	"SELECT DISTINCT
	|	Jobs.Document AS Document
	|FROM
	|	TTTasksForFormationOfRegisteredRecordsOfVNA AS Jobs";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock();
		BlockingField = Block.Add("InformationRegister.JobsForGeneratingFixedAssetRecords");
		BlockingField.DataSource = QueryResult;
		BlockingField.UseFromDataSource("Document", "Document");
		Block.Lock();
		
		If JobNumber = Undefined Then
			JobNumber = CurTaskNumber();
		EndIf;
		
		QueryText = 
		"SELECT
		|	Jobs.Organization AS Organization,
		|	Jobs.Document AS Document,
		|	Jobs.AccountingObject AS AccountingObject,
		|	BEGINOFPERIOD(Jobs.Month, MONTH) AS Month
		|
		|FROM
		|	TTTasksForFormationOfRegisteredRecordsOfVNA AS Jobs
		|
		|WHERE
		|	NOT TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			InformationRegister.JobsForGeneratingFixedAssetRecords AS RegisterData
		|		WHERE
		|			RegisterData.Organization = Jobs.Organization
		|			AND RegisterData.Document = Jobs.Document
		|			AND RegisterData.AccountingObject = Jobs.AccountingObject
		|			AND RegisterData.Month = Jobs.Month
		|			AND RegisterData.JobNumber = &JobNumber)
		|";
		
		Query = New Query(QueryText);
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("JobNumber", JobNumber);
		TaskRequestResult = Query.Execute();
		
		RecordSet = CreateRecordSet();
		
		Selection = TaskRequestResult.Select();
		While Selection.Next() Do
			
			If Not ValueIsFilled(Selection.AccountingObject) Then
				Continue;
			EndIf;	
			
			RegisterRecord = RecordSet.Add();
			FillPropertyValues(RegisterRecord, Selection);
			RegisterRecord.Month = BegOfMonth(Selection.Month);
			RegisterRecord.JobNumber = JobNumber;
			
		EndDo;
			
		If RecordSet.Modified() Then
			RecordSet.Write(False);
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		MessageText = ErrorProcessing.ErrorDescriptionForUser(ErrorInfo());
			
		WriteLogEvent(
			NStr("vi = 'Kết chuyển cuối tháng';
				|ru = 'Закрытие месяца';
				|en = 'Month-end closing'; fa = 'بستن پایان ماه';
				|it = 'Chiusura del mese';
				|pl = 'Zamknięcie miesiąca';
				|tr = 'Ay sonu kapanışı'", Common.DefaultLanguageCode()), 
			EventLogLevel.Error,,, 
			MessageText);
			
		Raise MessageText;
			
	EndTry;
	
EndProcedure

// Records successful execution of operation.
//
// Parameters:
//  Period - Date -
//  CompaniesList - Array - 
//  NumberBeforeSettlement - Number - 
//  TempTablesManager - TempTablesManager - 
//  ObjectsTableName - String -
//
Procedure FixCalculation(Period, CompaniesList, NumberBeforeSettlement, TempTablesManager, ObjectsTableName) Export
	
	SetPrivilegedMode(True);

	CreateTasksForNextPeriod(
		EndOfMonth(Period) + 1, CompaniesList, TempTablesManager, ObjectsTableName);

	DeleteTasks(Period, CompaniesList, NumberBeforeSettlement, TempTablesManager, ObjectsTableName);
	
EndProcedure

// Returns the period from which data becomes irrelevant for this month closing operation.
//
// Parameters:
//  CompaniesList	 - Array	 - Array of organizations that are monitored for relevance.
// 
// Returns:
//  Date - The beginning of the month for which the closing of the month is irrelevant.
//
Function CalculationStart(CompaniesList) Export
	
	QueryText =
	"SELECT
	|	ISNULL(MIN(Jobs.Month), DATETIME(1, 1, 1)) AS CalculationStart
	|FROM
	|	InformationRegister.JobsForGeneratingFixedAssetRecords AS Jobs
	|WHERE
	|	Jobs.Organization IN (&CompaniesList)";
	
	Query = New Query(QueryText);
	Query.SetParameter("CompaniesList", CompaniesList);
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection.CalculationStart;
	
EndFunction

// See PeriodClosingDatesOverridable.FillDataSourcesForPeriodClosingCheck
Procedure DescriptionOfRegistersForControlOfDatesOfProhibitionOfChange(DataSources) Export
	
	PeriodClosingDates.AddRow(DataSources, Metadata.AccumulationRegisters.FACost.FullName(),
		"Period", "FinancialOutline", "Organization");
		
	PeriodClosingDates.AddRow(DataSources, Metadata.AccumulationRegisters.FixedAssetsDepreciationCharge.FullName(),
		"Period", "FinancialOutline", "Organization");
		
	PeriodClosingDates.AddRow(DataSources, Metadata.AccumulationRegisters.IACost.FullName(),
		"Period", "FinancialOutline", "Organization");
		
	PeriodClosingDates.AddRow(DataSources, Metadata.AccumulationRegisters.IntangibleAssetsAmortizationCharge.FullName(),
		"Period", "FinancialOutline", "Organization");
	
EndProcedure

// Returns a list of metadata objects that are used for generating register entries.
//
//Returns:
// Array of MetadataObject
Function IncomingMechanismData() Export
	
	IncomingData = New Array;
	IncomingData.Add(Metadata.AccumulationRegisters.IntangibleAssetsAmortizationCharge);
	IncomingData.Add(Metadata.AccumulationRegisters.FixedAssetsDepreciationCharge);
	IncomingData.Add(Metadata.AccumulationRegisters.InvestmentInRent);
	IncomingData.Add(Metadata.AccumulationRegisters.IACost);
	IncomingData.Add(Metadata.AccumulationRegisters.FACost);
	
	IncomingData.Add(Metadata.InformationRegisters.LeasedAsset);
	IncomingData.Add(Metadata.InformationRegisters.FALocation);
	IncomingData.Add(Metadata.InformationRegisters.IntangibleAssetsRegistrationPlace);
	IncomingData.Add(Metadata.InformationRegisters.IADepreciationParametersBookkeepingAndTaxAccounting);
	IncomingData.Add(Metadata.InformationRegisters.IntangibleAssetAmortizationParametersManagementAccounting);
	IncomingData.Add(Metadata.InformationRegisters.OSBUDepreciationParameters);
	IncomingData.Add(Metadata.InformationRegisters.FixedAssetDepreciationParametersManagementAccounting);
	IncomingData.Add(Metadata.InformationRegisters.InitialIntangibleAssetsInformation);
	IncomingData.Add(Metadata.InformationRegisters.AssetsLeasedOut);
	IncomingData.Add(Metadata.InformationRegisters.IntangibleAssetsAccountingProcedure);
	IncomingData.Add(Metadata.InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting);
	IncomingData.Add(Metadata.InformationRegisters.IntangibleAssetsAccountingProcedureManagementAccounting);
	IncomingData.Add(Metadata.InformationRegisters.FixedAssetsAccountingProcedure);
	IncomingData.Add(Metadata.InformationRegisters.AccountingProcedureForOSBU);
	IncomingData.Add(Metadata.InformationRegisters.FixedAssetsAccountingProcedureManagementAccounting);
	
	IncomingData.Add(Metadata.Documents.CustomerInvoiceServicesAndAssets);
	
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
	CurTaskNumber = Constants.JobNumberForGeneratingFixedAssetRecords.Get();
	SetPrivilegedMode(False);
	Return CurTaskNumber;
	
EndFunction

Procedure DeleteTasks(Period, CompaniesList, NumberBeforeSettlement, TempTablesManager, ObjectsTableName)
	
	ListOfRequests = New Array;
	
	If TempTablesManager.Tables.Find("ProcessedOneData") = Undefined Then
		
		QueryText = 
		"SELECT
		|	UNDEFINED AS Ref,
		|	UNDEFINED AS AccountingObject,
		|	FALSE AS HasErrors
		|INTO ProcessedOneData
		|
		|INDEX BY
		|	Ref
		|";
		
		ListOfRequests.Add(QueryText);
		
	EndIf;

	QueryText =
	"SELECT
	|	Jobs.Month AS Month,
	|	Jobs.Organization AS Organization,
	|	Jobs.AccountingObject AS AccountingObject,
	|	Jobs.JobNumber AS JobNumber,
	|	Jobs.Document AS Document
	|
	|FROM
	|	InformationRegister.JobsForGeneratingFixedAssetRecords AS Jobs
	|
	|WHERE
	|	Jobs.Month <= &PeriodEnding
	|	AND Jobs.JobNumber <= &JobNumber
	|	AND Jobs.Organization IN (&CompaniesList)
	|
	|	AND Jobs.AccountingObject IN
	|		(SELECT
	|			ListOfObjects.AccountingObject
	|		FROM
	|			ListOfObjects AS ListOfObjects)
	|
	|	AND NOT TRUE IN 
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			ProcessedOneData AS ProcessedOneData
	|		WHERE
	|			ProcessedOneData.AccountingObject = Jobs.AccountingObject
	|			AND ProcessedOneData.HasErrors)
	|";
	ListOfRequests.Add(QueryText);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	QueryText = StrReplace(QueryText, "ListOfObjects", ObjectsTableName);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("PeriodEnding", EndOfMonth(Period));
	Query.SetParameter("CompaniesList", CompaniesList);
	Query.SetParameter("JobNumber", NumberBeforeSettlement);
	
	Result = Query.Execute();
	
	Set = CreateRecordSet();
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		If Set.Count() >= 1000 Then
			Set.Write(ReplacementMode.Delete);
			Set.Clear(); 
		EndIf;
		
		NewRecord = Set.Add();
		FillPropertyValues(NewRecord, Selection);
		
	EndDo;
	
	If Set.Count() <> 0 Then
		Set.Write(ReplacementMode.Delete); 
	EndIf;
	
EndProcedure

Procedure CreateTasksForNextPeriod(BeginningOfNextMonth, CompaniesList, TempTablesManager, ObjectsTableName)
	
	QueryText =
	"SELECT
	|	ISNULL(MIN(DocumentsData.Date), DATETIME(1, 1, 1)) AS Month,
	|	DocumentsData.Organization AS Organization,
	|	DocumentsData.AccountingObject AS AccountingObject,
	|	&JobNumber AS JobNumber
	|FROM
	|	(SELECT
	|		BEGINOFPERIOD(FixedAssetsDocuments.Date, MONTH) AS Date,
	|		FixedAssetsDocuments.Organization AS Organization,
	|		FixedAssetsDocuments.FixedAsset AS AccountingObject
	|	FROM
	|		InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|	WHERE
	|		FixedAssetsDocuments.Date >= &BeginningOfNextMonth
	|		AND FixedAssetsDocuments.Posted
	|		AND FixedAssetsDocuments.RefType IN(&DocumentIDs)
	|		AND FixedAssetsDocuments.Organization IN (&CompaniesList)
	|		AND FixedAssetsDocuments.FixedAsset IN
	|				(SELECT
	|					ListOfObjects.AccountingObject
	|				FROM
	|					ListOfObjects AS ListOfObjects)
	|
	|	UNION ALL
	|
	|	SELECT
	|		BEGINOFPERIOD(IntangibleAssetsDocuments.Date, MONTH) AS Date,
	|		IntangibleAssetsDocuments.Organization AS Organization,
	|		IntangibleAssetsDocuments.IntangibleAsset AS AccountingObject
	|	FROM
	|		InformationRegister.IntangibleAssetsDocuments AS IntangibleAssetsDocuments
	|	WHERE
	|		IntangibleAssetsDocuments.Date >= &BeginningOfNextMonth
	|		AND IntangibleAssetsDocuments.Posted
	|		AND IntangibleAssetsDocuments.RefType IN(&DocumentIDs)
	|		AND IntangibleAssetsDocuments.Organization IN (&CompaniesList)
	|		AND IntangibleAssetsDocuments.IntangibleAsset IN
	|				(SELECT
	|					ListOfObjects.AccountingObject
	|				FROM
	|					ListOfObjects AS ListOfObjects)
	|
	|	) AS DocumentsData
	|
	|GROUP BY
	|	DocumentsData.Organization,
	|	DocumentsData.AccountingObject
	|
	|HAVING
	|	ISNULL(MIN(DocumentsData.Date), DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1)
	|";
	
	QueryText = StrReplace(QueryText, "ListOfObjects", ObjectsTableName);

	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("JobNumber", CurTaskNumber());
	Query.SetParameter("BeginningOfNextMonth", BeginningOfNextMonth);
	Query.SetParameter("CompaniesList", CompaniesList);
	
	Query.SetParameter(
		"DocumentIDs", 
		NonCurrentAssetsCached.IdsOfDocumentsForGeneratingDeferredTraffic());
	
	Query.SetParameter(
		"BusinessOperationsForWhichCostIsCalculated", 
		FACostCalculation.BusinessOperationsForWhichCostIsCalculated());
	 
	Result = Query.Execute();
	
	Set = CreateRecordSet();

	Selection = Result.Select();
	While Selection.Next() Do
		NewRecord = Set.Add();
		FillPropertyValues(NewRecord, Selection);
	EndDo;
	
	If Set.Count() <> 0 Then
		Set.Write(ReplacementMode.Merge); 
	EndIf;
	
EndProcedure

Procedure CreateRegisterEntry(TaskPeriod, DocumentJobs, Organization, AccountingObject, JobNumber)
				
	SetPrivilegedMode(True);
	
	If ExchangePlans.MasterNode() <> Undefined Then
		// In RIB, this register is processed only in the main node.
		Return;
	EndIf;
	
	BeginTransaction();
	Try
	
		RecordSet = InformationRegisters.JobsForGeneratingFixedAssetRecords.CreateRecordManager();
		RecordSet.Month        = BegOfMonth(TaskPeriod);
		RecordSet.AccountingObject  = AccountingObject;
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

#EndRegion

#EndIf

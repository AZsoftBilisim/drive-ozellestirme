#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - a recordable document.
//  Properties - See DocumentsPosting.DocumentProperties.
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism.
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.ImpairmentFA);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.CGUComposition);
	
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.ImpairmentFA);
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.CGUComposition);
		
	EndIf;
	
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.ImpairmentFA);
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns request texts for reversing movements when correcting documents.
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
//  Map of KeyAndValue - Correspondence of the full register name to the text of the reversal request:
//   * Key - String - table name;
//   * Value - String - Query text
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	QueriesTexts = New Map();
	
	Return QueriesTexts;
	
EndFunction


// The procedure for the formation of movements according to subordinate registers of depreciation of the VNA.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables.
//   RegisterRecords - RegisterRecordsCollection - a collection of sets of records of document movements.
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Metadata.AccumulationRegisters.ImpairmentFA.Name);
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Metadata.InformationRegisters.CGUComposition.Name);
	
EndProcedure

// Procedure for forming movements in independent registers of fixed assets.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables.
//	Document - DocumentRef - link to the document.
//	TempTablesManager - TempTablesManager - manager of temporary document tables.
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure WriteData(TablesForRegisteredRecords, Document, TempTablesManager, Cancel) Export

	Return;
	
EndProcedure

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//  Map of KeyAndValue - matching table names, case changes, and query texts:
//   * Key - String - table name;
//   * Value - String - Query text
//
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	MatchingQueryTexts.Insert("ImpairmentFAUpdate", 
										  AccumulationRegisters.ImpairmentFA.RequestTextMonitoringBanDate(Query));
	
	Return MatchingQueryTexts;
	
EndFunction

#Region RequestTextsForTasksAtEndOfMonth

// Complements the request text of the mechanism for generating monthly closing tasks.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 	QueryText - String - a string with the request text.
// 	TempTablesQueryText - String - a string containing the text of a temporary table query.
// 	TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
//	Document - DocumentRef, Structure -
Procedure AddTextOfRequestForTasksByEndOfMonth(Query, QueryText, TempTablesQueryText, TemporaryTableNames, Document) Export

	If Not GetFunctionalOption("UseFixedAssetImpairment") Then
		Return;
	EndIf;
	
	If Not TypeOf(Document) = Type("Structure") 
		Or Document.Property("Date") And ValueIsFilled(Document.Date) Then
		Query.SetParameter("BeginOfPeriod", BegOfMonth(Document.Date));
	Else
		Return;
	EndIf;
	
	MatchingRequests = MatchingRequestsToControlRegisters(Query);
	
	For Each MapItem In MatchingRequests Do
		MonthEndTransactionsServer.AddTableNamesForTasks(Query, MapItem.Key);
		MonthEndTransactionsServer.AddTaskRequestText(MapItem.Key,
			MapItem.Value,
			Query.TempTablesManager.Tables,
			QueryText,
			TempTablesQueryText,
			TemporaryTableNames);
	EndDo;
	
EndProcedure

#EndRegion

// Generates tasks for the closing of the month according to the registers of the TaskaccOUntingaMortisationOS,
// 													TasksacCOuntsamOrtizationiNMA,
// 													The task of the formation of the movement is unknown.
// 
// Parameters:
// 	Document - DocumentObject -
// 	TablesData - See DocumentsPosting.OldStructureTableData.
Procedure CreateTasksForEndOfMonthUsingOSNMA(Document, TablesData) Export
	
	If TablesData.TempTablesManager.Tables.Find("ChangesTableImpairmentFA") = Undefined Then
		Return;
	EndIf;
	
	Query =  New Query;
	Query.TempTablesManager = TablesData.TempTablesManager;
	Query.SetParameter("Period", BegOfMonth(AddMonth(Document.Date, 1)));
	
	Query.Text = 
	"SELECT
	|	&Period AS Month,
	|	TableVNA.Organization,
	|	ISNULL(FixedAssetDepreciationPackages.PackageNumber, 0) AS PackageNumber
	|FROM
	|	ChangesTableImpairmentFA AS TableVNA
	|		INNER JOIN Catalog.Assets AS Assets
	|		ON TableVNA.NonCurrentAsset = Assets.Ref
	|		LEFT JOIN InformationRegister.FixedAssetDepreciationPackages AS FixedAssetDepreciationPackages
	|		ON TableVNA.NonCurrentAsset = FixedAssetDepreciationPackages.FixedAsset
	|		AND TableVNA.Organization = FixedAssetDepreciationPackages.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Period AS Month,
	|	TableVNA.Organization AS Organization,
	|	ISNULL(IntangibleAssetAmortizationPackages.PackageNumber, 0) AS PackageNumber
	|FROM
	|	ChangesTableImpairmentFA AS TableVNA
	|		INNER JOIN Catalog.IntangibleAssets AS IntangibleAssets
	|		ON TableVNA.NonCurrentAsset = IntangibleAssets.Ref
	|		LEFT JOIN InformationRegister.IntangibleAssetAmortizationPackages AS IntangibleAssetAmortizationPackages
	|		ON TableVNA.NonCurrentAsset = IntangibleAssetAmortizationPackages.IntangibleAsset
	|		AND TableVNA.Organization = IntangibleAssetAmortizationPackages.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	&Period AS Month,
	|	TableVNA.Organization AS Organization,
	|	TableVNA.NonCurrentAsset AS AccountingObject
	|FROM
	|	ChangesTableImpairmentFA AS TableVNA
	|";
	
	QueryResult = Query.ExecuteBatch();
	
	InformationRegisters.JobsForCalculatingFixedAssetDepreciation.CreateRegisterEntriesBasedOnSampleData(QueryResult[0].Select());
	InformationRegisters.JobsForCalculatingIntangibleAssetAmortization.CreateRegisterEntriesBasedOnSampleData(QueryResult[1].Select());
	InformationRegisters.JobsForGeneratingFixedAssetRecords.CreateRegisterEntriesBasedOnSampleData(QueryResult[2].Select());
	
EndProcedure

#EndRegion

#Region MonthEndTransactions

#Region CreatingMonthClosingStages

// Adds a stage to the monthly closing stages table.
// The elements of this table are the elements of the second level in the tree of stages in the form of the closing of the month.
// Called from the closing of the month server.Fill in the description of the closing steps of the month (the table of the steps).
// 
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth).
// 	CurrentParent - String - group ID.
Procedure AddStage_FormationOfRegisteredRecordsOnDevaluationOfVNA(StepsTable, CurrentParent) Export

	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable,
															CurrentParent,
															Catalogs.MonthEndClosingOperations.ImpairmentFA);
	
		NewRow.MultilingualName = "vi = 'Giảm giá tài sản dài hạn';
									|ru = 'Обесценение ВНА';
									|en = 'Fixed assets impairment';
									|it = 'Svalutazione attivi non correnti';
									|pl = 'Utrata wartości aktywów nieobrotowych';
									|tr = 'Duran Varlık değer kaybı'"; // @NStr-1
	NewRow.TextExecute = NStr("vi = 'Lập báo cáo';
								|ru = 'Сформировать';
								|en = 'Generate'; fa = 'ایجاد';
								|it = 'Generare';
								|pl = 'Generate';
								|tr = 'Oluştur'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"ImpairmentFAServer.Use_FormationOfRegisteredRecordsOnDepreciationOfVNA");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"ImpairmentFAServer.Perform_GenerationOfImpairmentFARegisteredRecords");

EndProcedure

#EndRegion

#Region HandlersForMonthClosingStages

#Region Stage_FormationOfRegisteredRecordsForDevaluationOfVNA

// Determines the status of the operation "Formation of movement and impairment".
// 
// Parameters:
//  HandlerParameters - Structure - Handler Parameters
Procedure Use_FormationOfRegisteredRecordsOnDepreciationOfVNA(HandlerParameters) Export

	// With the use of HPA disabled, the operation does not make sense.
	If Not GetFunctionalOption("UseNonCurrentAssets2_4") Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Kế toán tài sản dài hạn bị vô hiệu hóa.';
				|ru = 'Учет внеоборотных активов отключен.';
				|en = 'Accounting of fixed assets disabled.'; fa = 'Accounting of fixed assets disabled.';
				|it = 'La contabilità degli attivi non circolanti è disattivata.';
				|pl = 'Ewidencja aktyw pozaobrotowych jest odłączona.';
				|tr = 'Duran varlıkların muhasebeleştirilmesi devre dışı bırakılmıştır.'", Common.DefaultLanguageCode()));
		
		Return;
		
	EndIf;
		
	If Not GetFunctionalOption("UseFixedAssetImpairment") Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Đã vô hiệu hóa việc tính khấu hao tài sản dài hạn.';
				|ru = 'Учет обесценения внеоборотных активов отключен.';
				|en = 'Accounting of fixed asset impairment is disabled.'; fa = 'Accounting of fixed asset impairment is disabled.';
				|it = 'Il calcolo della svalutazione degli attivi non correnti è disattivato.';
				|pl = 'Ewidencja utrata wartości aktywów nieobrotowych jest wyłączona.';
				|tr = 'Duran varlıkların değer düşüklüğünün muhasebeleştirilmesi devre dışı bırakılır.'", Common.DefaultLanguageCode()));
		
		Return;
		
	EndIf;
		
	If MonthEndTransactionsServer.StageCalculationIsNotRequired(HandlerParameters.Data_Stage) Then
		Return;
	EndIf;
	
	MonthEndTransactionsServer.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, True);
	
EndProcedure

// Performs the operation "Formation of movement and devaluation".
// 
// Parameters:
//  HandlerParameters - Structure - Handler Parameters
Procedure Perform_GenerationOfImpairmentFARegisteredRecords(HandlerParameters) Export
		
	CalculationParameters = HandlerParameters.CalculationParameters;
	
 	BeginOfPeriod = MonthEndTransactionsServer.CalculationStart(HandlerParameters.Data_Stage.Code, CalculationParameters.EndOfPeriod,,
		CalculationParameters.CompanyArray);
		
	HasErrors = False;
	
	SpecificGravityMeasurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
					"CommonModule.ImpairmentFAServer.ImpairmentOfVNAFacilities");
	TotalAmountOfData = 0;
	
	MeasurementIsDocumented = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
	"CommonModule.ImpairmentFAServer.ClosingOfMonthIsDocumented");
	DocumentsCount = 0;
	
	While BeginOfPeriod <= CalculationParameters.EndOfPeriod Do
		
		MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("MonthEndTransactions." 
			+ String(HandlerParameters.Data_Stage.Code));
		
		PeriodEnding = EndOfMonth(BeginOfPeriod);
		AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(BeginOfPeriod, CalculationParameters.CompanyArray);
		TaskNumberBeforeCalculation = MonthEndTransactionsServer.IncreaseTaskNumber();
		
		// Stage 1. Preparation of work with tasks.
		
		BeginTransaction();
		
		Try
			MonthEndTransactionsServer.BlockTaskRegister(TaskNumberBeforeCalculation, AvailableCompanies,
				HandlerParameters.Data_Stage.Code);
			CalculationDataForMonth = MonthEndTransactionsServer.MonthlyTasks(BeginOfPeriod, PeriodEnding, TaskNumberBeforeCalculation,
				AvailableCompanies, HandlerParameters.Data_Stage.Code);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr(
					"vi = 'Khi thực hiện hạch toán trong kỳ %1, đã xảy ra lỗi:
					|%2';
					|ru = 'При выполнении расчета за период %1 произошла ошибка:
					|%2';
					|en = 'An error occurred when calculating for the %1 period:
					|%2'; fa = 'An error occurred when calculating for the %1 period:
					|%2';
					|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
					|%2';
					|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
					|%2';
					|tr = 'Dönem %1 için hesaplama yapılırken bir hata oluştu:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(BeginOfPeriod),
				DetailErrorDescription(ErrorInfo()));
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(HandlerParameters, ErrorText,
				AvailableCompanies, BeginOfPeriod);
		EndTry;
		
		// Stage 2. Calculation by organizations and period.
		
		BeginTransaction();
		
		Try
			
			Query = New Query();
			Query.TempTablesManager = CalculationDataForMonth.TemporaryTable;
			Query.Text = 
			"SELECT 
			|	COUNT(DISTINCT BorderCache.Document) AS Count
			|FROM BorderCache AS BorderCache
			|";
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				DataVolume = Selection.Count;
				DocumentsCount = DocumentsCount + Selection.Count;
			EndIf;
			
			PerformImpairmentReclassification(CalculationDataForMonth);
				
			CommitTransaction();
			
			Query.Text = "SELECT
			|	COUNT(ImpairmentFA.NonCurrentAsset) AS TotalAmountOfData
			|FROM
			|	BorderCache AS BorderCache
			|		INNER JOIN AccumulationRegister.ImpairmentFA AS ImpairmentFA
			|		ON BorderCache.Document = ImpairmentFA.Recorder";
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				TotalAmountOfData = TotalAmountOfData + Selection.TotalAmountOfData;
			EndIf;
			
		Except
			
			RollbackTransaction();
			
			HasErrors = True;
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr(
					"vi = 'Đã thực hiện giảm giá tài sản dài hạn trong kỳ %1 bị lỗi:
					|%2';
					|ru = 'Выполнение обесценения ВНА за период %1 завершилось с ошибкой:
					|%2';
					|en = 'Fixed asset impairment for the %1 period is completed with an error:
					|%2'; fa = 'Fixed asset impairment for the %1 period is completed with an error:
					|%2';
					|it = 'Esecuzione svalutazione degli attivi non correnti per il periodo %1 eseguita con errori:
					|%2';
					|pl = 'Wykonanie utraty wartości aktywów niematerialnych za okres %1 zostało zakończone z błędem:
					|%2';
					|tr = 'Dönem %1 için duran varlıkların değer kaybı bir hatayla sona erdi:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(BeginOfPeriod),
				DetailErrorDescription(ErrorInfo()));
				
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(HandlerParameters, ErrorText,
				CalculationDataForMonth.Organization, BeginOfPeriod);
		EndTry;
		
		
		If HasErrors Then
			Break;
		EndIf;
		
		// Stage 3. Completion of work with tasks.
		
		MonthEndTransactionsServer.DeleteTasksToBeCalculatedForCurPeriod(HandlerParameters, CalculationDataForMonth);
		
		BeginOfPeriod = PeriodEnding + 1;
		
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume/10);
			
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(SpecificGravityMeasurement, TotalAmountOfData);
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementIsDocumented, DocumentsCount);
		
EndProcedure

#EndRegion

#EndRegion

#EndRegion


#Region InterfaceManagement

// Set the parameters of the EGDS selection.
// It is used in the documents MOVEMENT_2_4 and MOVEMENT_2_4 to set the selection of the owner of the EGDS.
// 
// Parameters:
//  CGU - FormField - EGDS.
//  Object - DocumentObject.FATransfer2_4 - Document.
Procedure SetCGUSelectionParameters(CGU, Object) Export
	
	If ValueIsFilled(Object.CompanyRecipient) Then
		DataPath = "Object.CompanyRecipient";
	Else
		DataPath = "Object.Organization";
	EndIf;

	FilterByCompany = New Array();
	OrganizationSelectionElement = New ChoiceParameterLink("Filter.Owner", 
															 DataPath, 
															 LinkedValueChangeMode.Clear);
															 
	FilterByCompany.Add(OrganizationSelectionElement);
	
	CGU.ChoiceParameterLinks = New FixedArray(FilterByCompany);
	
EndProcedure


// Get the HPA EGDS on the date.
// 
// Parameters:
//  Organization - CatalogRef.Companies - Organization.
//  NonCurrentAsset - CatalogRef.Assets, CatalogRef.IntangibleAssets - Non-current asset.
//  Date - Date
// 
// Returns:
//  CatalogRef.CashGeneratingUnits - EGDS VNA on the specified date.
Function GetEGDSVNAOnDate(Organization, NonCurrentAsset, Date) Export
	
	CGU = Catalogs.CashGeneratingUnits.EmptyRef();
	
	Query = New Query;
	
	Query.Text =
	"SELECT
	|	CGUCompositionSliceLast.CGU AS CGU
	|FROM
	|	InformationRegister.CGUComposition.SliceLast(&Date, NonCurrentAsset = &NonCurrentAsset
	|	AND Organization = &Organization) AS CGUCompositionSliceLast";
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("NonCurrentAsset", NonCurrentAsset);
	Query.SetParameter("Date", Date);
	
	Result = Query.Execute();

	If Result.IsEmpty() Then
		Return CGU;
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		Return Selection.CGU;
	EndDo;

EndFunction


// Establish the visibility of the impairment data in the report.
// When the Use Impairment functional option is disabled
// , the system removes columns from the report with names beginning with Impairment.
// 
// Parameters:
//  MainCircuitSettings - DataCompositionSettings - . 
Procedure EstablishVisibilityOfImpairmentDataInReport(MainCircuitSettings) Export
	
	For Each BranchOfSettingsTree In MainCircuitSettings.Selection.Items Do

		UseFixedAssetImpairment = GetFunctionalOption("UseFixedAssetImpairment");

		If GetFunctionalOption("UseFixedAssetImpairment") = Undefined Then
			UseFixedAssetImpairment = False;
		EndIf;

		DisableUseOfImpairment(BranchOfSettingsTree, UseFixedAssetImpairment);

	EndDo;
	
EndProcedure

#EndRegion

#Region ImpairmentInOrganizationsWithBranches

// Get the company for impairment.
// 
// Parameters:
//  Organization - CatalogRef.Companies - The company you want to get the data for.
// 
// Returns:
//  Array of CatalogRef.Companies -  For a branch office, returns an array of 1 element - the transferred branch
// 											  office. For the parent organization, returns an array from the parent company 
//											  and all its branches office.
Function GetOrganizationsForImpairment(Organization) Export

	CompaniesList = New Array;
	CompaniesList.Add(Organization);
	
	ParentCompany = Common.ObjectAttributeValue(Organization, "ParentCompany");
	
	If Organization = ParentCompany Then
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Companies.Ref AS Organization
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.ParentCompany = &ParentCompany
		|	AND Companies.Ref <> &ParentCompany";
		
		Query.SetParameter("ParentCompany", ParentCompany);
		
		Result = Query.Execute();
		Selection = Result.Select();
		While Selection.Next() Do
			CompaniesList.Add(Selection.Organization);
		EndDo;
	EndIf;
	
	Return CompaniesList;

EndFunction

#EndRegion

#EndRegion

#Region Private

#Region JobsForMonthEndClosing

Function MatchingRequestsToControlRegisters(Query)
	
	MatchingQueryTexts = New Map();
	MatchingQueryTexts.Insert("FACostUpdate", QueryTextFACost(Query));
	MatchingQueryTexts.Insert("IACostUpdate", QueryTextIACost(Query));
	MatchingQueryTexts.Insert("FixedAssetsDepreciationChargeUpdate", QueryTextFixedAssetsDepreciationCharge(Query));
	MatchingQueryTexts.Insert("IntangibleAssetsAmortizationChargeUpdate", QueryTextIntangibleAssetsAmortizationCharge(Query));
	MatchingQueryTexts.Insert("ChangesTableImpairmentFA", RequestTextImpairmentInTermsOfTask(Query));
	MatchingQueryTexts.Insert("CGUCompositionUpdate", QueryTextCGUCompositionUpdate(Query));
	Return MatchingQueryTexts;
	
EndFunction

Function QueryTextFACost(Query)
	
	QueryText =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(ImpairmentDocuments.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.ImpairmentFA) AS Operation,
	|	Table.Organization AS Organization,
	|	ImpairmentDocuments.Recorder AS Document
	|FROM
	|	FACostUpdate AS Table
	|		INNER JOIN AccumulationRegister.ImpairmentFA AS ImpairmentDocuments
	|		ON ImpairmentDocuments.Organization = Table.Organization
	|		AND ImpairmentDocuments.NonCurrentAsset = Table.FixedAsset
	|		AND ImpairmentDocuments.Period >= &BeginOfPeriod
	|		AND ImpairmentDocuments.Active
	|
	|UNION
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(Table.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.ImpairmentFA) AS Operation,
	|	Table.Organization AS Organization,
	|	Table.Document AS Document
	|FROM
	|	FACostUpdate AS Table 
	|		INNER JOIN AccumulationRegister.ImpairmentFA.Balance(&BeginOfPeriod, (Organization, NonCurrentAsset) IN
	|		(SELECT
	|			FATable.Organization,
	|			FATable.FixedAsset
	|		FROM
	|			FACostUpdate AS FATable)) AS ImpairmentFABalance
	|		ON Table.Organization = ImpairmentFABalance.Organization
	|		AND Table.FixedAsset = ImpairmentFABalance.NonCurrentAsset
	|	";

	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_
	
EndFunction

Function QueryTextIACost(Query)
	
	QueryText =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(ImpairmentDocuments.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.ImpairmentFA) AS Operation,
	|	Table.Organization AS Organization,
	|	ImpairmentDocuments.Recorder AS Document
	|FROM
	|	IACostUpdate AS Table
	|	 INNER JOIN AccumulationRegister.ImpairmentFA AS ImpairmentDocuments
	|			ON 	ImpairmentDocuments.Organization = Table.Organization
	|				AND ImpairmentDocuments.NonCurrentAsset = Table.IntangibleAsset
	|				AND ImpairmentDocuments.Period >= &BeginOfPeriod
	|				AND ImpairmentDocuments.Active
	|UNION
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(Table.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.ImpairmentFA) AS Operation,
	|	Table.Organization AS Organization,
	|	Table.Document AS Document
	|FROM
	|	IACostUpdate AS Table 
	|		INNER JOIN AccumulationRegister.ImpairmentFA.Balance(&BeginOfPeriod, (Organization, NonCurrentAsset) IN
	|		(SELECT
	|			TableOfIA.Organization,
	|			TableOfIA.IntangibleAsset
	|		FROM
	|			IACostUpdate AS TableOfIA)) AS ImpairmentFABalance
	|		ON Table.Organization = ImpairmentFABalance.Organization
	|		AND Table.IntangibleAsset = ImpairmentFABalance.NonCurrentAsset
	|";

	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_
	
EndFunction

Function QueryTextFixedAssetsDepreciationCharge(Query)
	
	QueryText =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(ImpairmentDocuments.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.ImpairmentFA) AS Operation,
	|	Table.Organization AS Organization,
	|	ImpairmentDocuments.Recorder AS Document
	|FROM
	|	FixedAssetsDepreciationChargeUpdate AS Table
	|	 INNER JOIN AccumulationRegister.ImpairmentFA AS ImpairmentDocuments
	|			ON 	ImpairmentDocuments.Organization = Table.Organization
	|				AND ImpairmentDocuments.NonCurrentAsset = Table.FixedAsset
	|				AND ImpairmentDocuments.Period >= &BeginOfPeriod
	|				AND ImpairmentDocuments.Active
	|		
	|";

	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_
	
EndFunction

Function QueryTextIntangibleAssetsAmortizationCharge(Query)
	
	QueryText =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(ImpairmentDocuments.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.ImpairmentFA) AS Operation,
	|	Table.Organization AS Organization,
	|	ImpairmentDocuments.Recorder AS Document
	|FROM
	|	IntangibleAssetsAmortizationChargeUpdate AS Table
	|	 INNER JOIN AccumulationRegister.ImpairmentFA AS ImpairmentDocuments
	|			ON 	ImpairmentDocuments.Organization = Table.Organization
	|				AND ImpairmentDocuments.NonCurrentAsset = Table.IntangibleAsset
	|				AND ImpairmentDocuments.Period >= &BeginOfPeriod
	|				AND ImpairmentDocuments.Active
	|";

	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_
	
EndFunction

Function RequestTextImpairmentInTermsOfTask(Query)
	
	QueryText =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(ImpairmentFA.Ref.Date, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.ImpairmentFA) AS Operation,
	|	Table.Organization AS Organization,
	|	ImpairmentFA.Ref AS Document
	|FROM
	|	ChangesTableImpairmentFA AS Table
	|		INNER JOIN Document.ImpairmentFA.CashGeneratingUnits AS ImpairmentFA
	|		ON ImpairmentFA.CGU = Table.CGU
	|		AND ImpairmentFA.Ref.Posted
	|		AND DATEDIFF(&BeginOfPeriod, ImpairmentFA.Ref.Date, MONTH) > 0
	|
	|UNION
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(ImpairmentFA.Ref.Date, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.ImpairmentFA) AS Operation,
	|	Table.Organization AS Organization,
	|	ImpairmentFA.Ref AS Document
	|FROM
	|	ChangesTableImpairmentFA AS Table
	|		INNER JOIN Document.ImpairmentFA.FixedAssets AS ImpairmentFA
	|		ON ImpairmentFA.FixedAsset = Table.NonCurrentAsset
	|		AND ImpairmentFA.Ref.Posted
	|		AND DATEDIFF(&BeginOfPeriod, ImpairmentFA.Ref.Date, MONTH) > 0
	|
	|UNION
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(ImpairmentFA.Ref.Date, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.ImpairmentFA) AS Operation,
	|	Table.Organization AS Organization,
	|	ImpairmentFA.Ref AS Document
	|FROM
	|	ChangesTableImpairmentFA AS Table
	|		INNER JOIN Document.ImpairmentFA.IntangibleAssets AS ImpairmentFA
	|		ON ImpairmentFA.IntangibleAsset = Table.NonCurrentAsset
	|		AND ImpairmentFA.Ref.Posted
	|		AND DATEDIFF(&BeginOfPeriod, ImpairmentFA.Ref.Date, MONTH) > 0
	|";

	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_
	
EndFunction

Function QueryTextCGUCompositionUpdate(Query)
	
	QueryText =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(Table.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.ImpairmentFA) AS Operation,
	|	Table.Organization AS Organization,
	|
	|	// When transferring a document to a previous period, a task is generated in the original period with an empty document
	|	// and a task in the new period with a link to the document.
	|	// When transferring a document to a future period, 2 tasks are generated with a link to the document.
	|	CASE
	|		WHEN BEGINOFPERIOD(Table.Period, MONTH) > BEGINOFPERIOD(Table.Document.DATE, MONTH)
	|			THEN UNDEFINED 
	|			ELSE Table.Document
	|		END  AS Document
	|		
	|FROM
	|	CGUCompositionUpdate AS Table
	|";

	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_
	
EndFunction

#EndRegion

// 
// Parameters:
//  ListOfRequests - Array - List of requests
//  TTUsed - Array - Temporary Tables Used
Procedure ToSupplementParametersOfDelayedFormationOfRegisteredRecorded(ListOfRequests, TTUsed) Export
	
	TTUsed.Add("TT_ImpairmentFA");
	
	#Region TT_ImpairmentFA
	
	QueryText = 
	"SELECT
	|	ImpairmentFA.Organization AS Organization,
	|	ImpairmentFA.NonCurrentAsset AS AccountingObject,
	|	-ImpairmentFA.ImpairmenManBalance AS ImpairmenMan,
	|	-ImpairmentFA.ImpairmentLocalAssetsBalance AS ImpairmentLocalAssets,
	|	-ImpairmentFA.LossFromImpairmentMgmtBalance AS LossFromImpairmentMgmt,
	|	-ImpairmentFA.LossFromImpairmentLocalBalance AS LossFromImpairmentLocal,
	|	ImpairmentFA.CGU AS CGU
	|INTO ImpairmentFA_Balance
	|FROM
	|	AccumulationRegister.ImpairmentFA.Balance(&BegOfMonth, (Organization, NonCurrentAsset) IN
	|		(SELECT
	|			DataForCalculation.Organization,
	|			DataForCalculation.AccountingObject
	|		FROM
	|			TTDataToBeCalculated AS DataForCalculation)) AS ImpairmentFA
	|
	|INDEX BY
	|	AccountingObject,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ImpairmentFA.Period AS Period,
	|	ImpairmentFA.Recorder AS Recorder,
	|	ImpairmentFA.Organization AS Organization,
	|	ImpairmentFA.NonCurrentAsset AS AccountingObject,
	|	ImpairmentFA.CGU AS CGU,
	|
	|	CASE
	|		WHEN ImpairmentFA.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN ImpairmentFA.ImpairmenMan
	|		ELSE -ImpairmentFA.ImpairmenMan
	|	END AS ImpairmenMan,
	|
	|	CASE
	|		WHEN ImpairmentFA.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN ImpairmentFA.ImpairmentLocalAssets
	|		ELSE -ImpairmentFA.ImpairmentLocalAssets
	|	END AS ImpairmentLocalAssets,
	|
	|	CASE
	|		WHEN ImpairmentFA.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN ImpairmentFA.LossFromImpairmentLocal
	|		ELSE -ImpairmentFA.LossFromImpairmentLocal
	|	END AS LossFromImpairmentLocal,
	|
	|	CASE
	|		WHEN ImpairmentFA.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN ImpairmentFA.LossFromImpairmentMgmt
	|		ELSE -ImpairmentFA.LossFromImpairmentMgmt
	|	END AS LossFromImpairmentMgmt
	|
	|INTO DevaluationOfVNA_RegisteredRecords
	|
	|FROM
	|	AccumulationRegister.ImpairmentFA AS ImpairmentFA
	|
	|WHERE
	|	ImpairmentFA.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND ImpairmentFA.Active
	|
	|	AND (ImpairmentFA.Organization, ImpairmentFA.NonCurrentAsset) IN
	|		(SELECT
	|			DataForCalculation.Organization,
	|			DataForCalculation.AccountingObject
	|		FROM
	|			TTDataToBeCalculated AS DataForCalculation)
	|
	|	AND NOT ImpairmentFA.Recorder IN
	|		(SELECT
	|			DataForCalculation.Ref
	|		FROM
	|			TTDataToBeCalculated AS DataForCalculation)
	|	AND NOT ImpairmentFA.BusinessTransactionSetting IN (
	|			VALUE(Catalog.BusinessTransactionsSettings.AdjustmentForFAImpairment),
	|			VALUE(Catalog.BusinessTransactionsSettings.AdjustmentForIAImpairment)
	|			)
	|
	|INDEX BY
	|	AccountingObject,
	|	Organization
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|// Registered Recorded movements made by the depreciation regulatory document. There may be both before and after the document changing the amount of impairment.
	|SELECT
	|	ImpairmentFA.Period AS Period,
	|	ImpairmentFA.Recorder AS Recorder,
	|	ImpairmentFA.Organization AS Organization,
	|	ImpairmentFA.NonCurrentAsset AS AccountingObject,
	|	ImpairmentFA.CGU AS CGU,
	|
	|	CASE
	|		WHEN ImpairmentFA.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN ImpairmentFA.ImpairmenMan
	|		ELSE -ImpairmentFA.ImpairmenMan
	|	END AS ImpairmenMan,
	|
	|	CASE
	|		WHEN ImpairmentFA.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN ImpairmentFA.ImpairmentLocalAssets
	|		ELSE -ImpairmentFA.ImpairmentLocalAssets
	|	END AS ImpairmentLocalAssets,
	|
	|	CASE
	|		WHEN ImpairmentFA.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN ImpairmentFA.LossFromImpairmentLocal
	|		ELSE -ImpairmentFA.LossFromImpairmentLocal
	|	END AS LossFromImpairmentLocal,
	|
	|	CASE
	|		WHEN ImpairmentFA.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN ImpairmentFA.LossFromImpairmentMgmt
	|		ELSE -ImpairmentFA.LossFromImpairmentMgmt
	|	END AS LossFromImpairmentMgmt
	|
	|INTO ImpairmentDUEToRegisteredRecordsOfDepreciation
	|
	|FROM
	|	AccumulationRegister.ImpairmentFA AS ImpairmentFA
	|
	|WHERE
	|	ImpairmentFA.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND ImpairmentFA.Active
	|
	|	AND (ImpairmentFA.Organization, ImpairmentFA.NonCurrentAsset) IN
	|		(SELECT
	|			DataForCalculation.Organization,
	|			DataForCalculation.AccountingObject
	|		FROM
	|			TTDataToBeCalculated AS DataForCalculation)
	|
	|	AND NOT ImpairmentFA.Recorder IN
	|		(SELECT
	|			DataForCalculation.Ref
	|		FROM
	|			TTDataToBeCalculated AS DataForCalculation)
	|	AND ImpairmentFA.BusinessTransactionSetting IN (
	|			VALUE(Catalog.BusinessTransactionsSettings.AdjustmentForFAImpairment),
	|			VALUE(Catalog.BusinessTransactionsSettings.AdjustmentForIAImpairment)
	|			)
	|
	|INDEX BY
	|	AccountingObject,
	|	Organization
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataForCalculation.Ref AS Ref,
	|	DataForCalculation.Date,
	|	DataForCalculation.Organization AS Organization,
	|	DataForCalculation.AccountingObject AS AccountingObject,
	|
	|	MAX(DataForCalculation.CGU) AS CGU,
	|
	|	SUM(DataForCalculation.ImpairmenMan) AS ImpairmenMan,
	|	SUM(DataForCalculation.ImpairmentLocalAssets) AS ImpairmentLocalAssets,
	|
	|	SUM(DataForCalculation.LossFromImpairmentMgmt) AS LossFromImpairmentMgmt,
	|	SUM(DataForCalculation.LossFromImpairmentLocal) AS LossFromImpairmentLocal
	|
	|INTO TT_ImpairmentFA
	|
	|FROM
	|	(SELECT
	|		DataForCalculation.Ref AS Ref,
	|		DataForCalculation.Date AS Date,
	|		DataForCalculation.Organization AS Organization,
	|		DataForCalculation.AccountingObject AS AccountingObject,
	|		ImpairmentFA.CGU AS CGU,
	|		ISNULL(ImpairmentFA.ImpairmenMan, 0) AS ImpairmenMan,
	|		ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) AS ImpairmentLocalAssets,
	|		ISNULL(ImpairmentFA.LossFromImpairmentMgmt, 0) AS LossFromImpairmentMgmt,
	|		ISNULL(ImpairmentFA.LossFromImpairmentLocal, 0) AS LossFromImpairmentLocal
	|	FROM
	|		TTDataToBeCalculated AS DataForCalculation
	|
	|			LEFT JOIN ImpairmentFA_Balance AS ImpairmentFA
	|			ON (ImpairmentFA.AccountingObject = DataForCalculation.AccountingObject)
	|				AND (ImpairmentFA.Organization = DataForCalculation.Organization)
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataForCalculation.Ref,
	|		DataForCalculation.Date,
	|		DataForCalculation.Organization,
	|		DataForCalculation.AccountingObject,
	|		ImpairmentFA.CGU AS CGU,
	|		ISNULL(ImpairmentFA.ImpairmenMan, 0) AS ImpairmenMan,
	|		ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) AS ImpairmentLocalAssets,
	|		ISNULL(ImpairmentFA.LossFromImpairmentMgmt, 0) AS LossFromImpairmentMgmt,
	|		ISNULL(ImpairmentFA.LossFromImpairmentLocal, 0) AS LossFromImpairmentLocal
	|	FROM
	|		TTDataToBeCalculated AS DataForCalculation
	|
	|			LEFT JOIN DevaluationOfVNA_RegisteredRecords AS ImpairmentFA
	|			ON ImpairmentFA.AccountingObject = DataForCalculation.AccountingObject
	|				AND ImpairmentFA.Organization = DataForCalculation.Organization
	|				AND ImpairmentFA.Recorder <> DataForCalculation.Ref
	|				AND ImpairmentFA.Period <= DataForCalculation.Date
	|	
	|	UNION ALL
	|
	|	SELECT
	|		DataForCalculation.Ref,
	|		DataForCalculation.Date,
	|		DataForCalculation.Organization,
	|		DataForCalculation.AccountingObject,
	|		ImpairmentFA.CGU AS CGU,
	|		ISNULL(ImpairmentFA.ImpairmenMan, 0) AS ImpairmenMan,
	|		ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) AS ImpairmentLocalAssets,
	|		ISNULL(ImpairmentFA.LossFromImpairmentMgmt, 0) AS LossFromImpairmentMgmt,
	|		ISNULL(ImpairmentFA.LossFromImpairmentLocal, 0) AS LossFromImpairmentLocal
	|	FROM
	|		TTDataToBeCalculated AS DataForCalculation
	|
	|			LEFT JOIN ImpairmentDUEToRegisteredRecordsOfDepreciation AS ImpairmentFA
	|			ON ImpairmentFA.AccountingObject = DataForCalculation.AccountingObject
	|				AND ImpairmentFA.Organization = DataForCalculation.Organization
	|				AND ImpairmentFA.Recorder <> DataForCalculation.Ref
	|
	|	) AS DataForCalculation
	|
	|GROUP BY
	|	DataForCalculation.Ref,
	|	DataForCalculation.Date,
	|	DataForCalculation.Organization,
	|	DataForCalculation.AccountingObject
	|
	|HAVING
	|	SUM(DataForCalculation.ImpairmenMan) <> 0
	|	OR SUM(DataForCalculation.ImpairmentLocalAssets) <> 0
	|	OR SUM(DataForCalculation.LossFromImpairmentMgmt) <> 0
	|	OR SUM(DataForCalculation.LossFromImpairmentLocal) <> 0
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject,
	|	Organization";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
EndProcedure

// Generates the Query Text of the VT_OBESENIEVNA table.
// 
// Parameters:
//  Query - Query -
//  QueryTexts - ValueList of String -
//  TableName - String, Undefined - 
Procedure QueryTextEmptyTableDepreciationIn(Query, QueryTexts, TableName = Undefined) Export

	If TableName = Undefined Then
		TableName = "TT_ImpairmentFA";
	EndIf; 
	
	If Query.TempTablesManager <> Undefined
		And Query.TempTablesManager.Tables.Find(TableName) <> Undefined Then
		Return;
	EndIf;
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	QueryText =
	"SELECT
	|	NULL AS Ref,
	|	DATETIME(1,1,1) AS Date,
	|	NULL AS Organization,
	|	NULL AS AccountingObject,
	|	NULL AS CGU,
	|	0 AS ImpairmenMan,
	|	0 AS ImpairmentLocalAssets,
	|	0 AS LossFromImpairmentMgmt,
	|	0 AS LossFromImpairmentLocal
	|INTO TT_ImpairmentFA";
	
	QueryText = StrReplace(QueryText, "TT_ImpairmentFA", TableName);
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure PerformImpairmentReclassification(CalculationDataForMonth)
	
	TempTablesManager = CalculationDataForMonth.TemporaryTable;
	ExecutionParameters = New Structure("ReturnDocumentsToReflection,GenerateJobs", True, True);
	
	RequestDocuments = New Query();
	RequestDocuments.TempTablesManager = TempTablesManager;
	RequestDocuments.SetParameter("BoundaryOfResidues",
		New Boundary(BegOfMonth(CalculationDataForMonth.CalculationPeriod)-1, BoundaryType.Including));
	RequestDocuments.Text = 
	"// Priority 1 Cur Documents.
	|
	|SELECT DISTINCT
	|	FixedAssetsDocuments.FixedAsset AS NonCurrentAsset,
	|	BorderCache.Document             AS Ref,
	|	1                              AS Priority,
	|	FixedAssetsDocuments.Organization      AS Organization,
	|	FixedAssetsDocuments.Date             AS Date
	|
	|INTO VNAObjects_Preliminary
	|
	|FROM
	|	InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|
	|		INNER JOIN BorderCache AS BorderCache
	|		ON FixedAssetsDocuments.Ref = BorderCache.Document
	|		AND FixedAssetsDocuments.Posted
	|		AND NOT FixedAssetsDocuments.Ref REFS Document.ImpairmentFA
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	IntangibleAssetsDocuments.IntangibleAsset  AS NonCurrentAsset,
	|	BorderCache.Document                  AS Ref,
	|	1                                   AS Priority,
	|	IntangibleAssetsDocuments.Organization          AS Organization,
	|	IntangibleAssetsDocuments.Date                 AS Date
	|FROM
	|	InformationRegister.IntangibleAssetsDocuments AS IntangibleAssetsDocuments
	|		INNER JOIN BorderCache AS BorderCache
	|		ON IntangibleAssetsDocuments.Ref = BorderCache.Document
	|		AND IntangibleAssetsDocuments.Posted
	|		AND NOT IntangibleAssetsDocuments.Ref REFS Document.ImpairmentFA
	|
	|UNION ALL
	|
	|// Priority 2 documents The Impairment of The HPA.
	|
	|SELECT DISTINCT
	|	FixedAssetsDocuments.FixedAsset  AS NonCurrentAsset,
	|	BorderCache.Document              AS Ref,
	|	2                               AS Priority,
	|	ImpairmentFA.Organization      AS Organization,
	|	ImpairmentFA.Date             AS Date
	|FROM
	|	BorderCache AS BorderCache   
	|	
	|		INNER JOIN Document.ImpairmentFA AS ImpairmentFA
	|		ON (ImpairmentFA.Ref = BorderCache.Document)
	|		AND (ImpairmentFA.Posted) 
	|		
	|		LEFT JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|		ON ImpairmentFA.Ref = FixedAssetsDocuments.Ref
	|		AND (ImpairmentFA.Posted)
	|
	|WHERE
	|	FixedAssetsDocuments.FixedAsset IS NOT NULL 
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	IntangibleAssetsDocuments.IntangibleAsset   AS NonCurrentAsset,
	|	BorderCache.Document                   AS Ref,
	|	2                                    AS Priority,
	|	ImpairmentFA.Organization           AS Organization,
	|	ImpairmentFA.Date                  AS Date
	|FROM
	|	BorderCache AS BorderCache 
	|	
	|		INNER JOIN Document.ImpairmentFA AS ImpairmentFA
	|		ON (ImpairmentFA.Ref = BorderCache.Document)
	|		AND (ImpairmentFA.Posted) 
	|		
	|		LEFT JOIN InformationRegister.IntangibleAssetsDocuments AS IntangibleAssetsDocuments
	|		ON (ImpairmentFA.Ref = IntangibleAssetsDocuments.Ref)
	|		AND (ImpairmentFA.Posted)
	|
	|WHERE
	|	IntangibleAssetsDocuments.IntangibleAsset IS NOT NULL 
	|
	|INDEX BY
	|	Ref,
	|	NonCurrentAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	NodesComponents.SubAssetComponent AS SubAssetComponent
	|INTO NodesOfFixedAssets
	|FROM
	|	InformationRegister.SubAssetsComponentsOfDepreciation AS NodesComponents
	|		INNER JOIN VNAObjects_Preliminary AS VNAObjects
	|		ON NodesComponents.FixedAsset = VNAObjects.NonCurrentAsset
	|
	|INDEX BY
	|	SubAssetComponent
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VNAObjects.Ref AS Ref,
	|	MAX(SubAssetsComponentsOfDepreciation.Period) AS Period,
	|	SubAssetsComponentsOfDepreciation.SubAssetComponent AS SubAssetComponent
	|INTO MaximaOfComponentNodes
	|FROM
	|	InformationRegister.SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
	|		INNER JOIN NodesOfFixedAssets AS NodesOfFixedAssets
	|		ON SubAssetsComponentsOfDepreciation.SubAssetComponent = NodesOfFixedAssets.SubAssetComponent
	|		INNER JOIN VNAObjects_Preliminary AS VNAObjects
	|		ON SubAssetsComponentsOfDepreciation.Period <= VNAObjects.Date
	|
	|GROUP BY
	|	VNAObjects.Ref,
	|	SubAssetsComponentsOfDepreciation.SubAssetComponent
	|
	|INDEX BY
	|	Period,
	|	SubAssetComponent
	|;
	|
	|//////////////////////////////////////////////////////////////
	|DROP NodesOfFixedAssets
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VNAObjects.NonCurrentAsset AS NonCurrentAsset,
	|	VNAObjects.Ref AS Ref,
	|	VNAObjects.Priority AS Priority,
	|	VNAObjects.Organization AS Organization,
	|	VNAObjects.Date AS Date
	|INTO VNAObjects
	|FROM
	|	VNAObjects_Preliminary AS VNAObjects
	|WHERE
	|	VNAObjects.NonCurrentAsset <> UNDEFINED
	|
	|UNION ALL
	|
	|SELECT
	|	SubAssetsComponentsOfDepreciation.SubAssetComponent AS NonCurrentAsset,
	|	VNAObjects.Ref AS Ref,
	|	VNAObjects.Priority AS Priority,
	|	VNAObjects.Organization AS Organization,
	|	VNAObjects.Date AS Date
	|FROM
	|	VNAObjects_Preliminary AS VNAObjects
	|		INNER JOIN MaximaOfComponentNodes AS MaximaOfComponentNodes
	|		ON VNAObjects.Ref = MaximaOfComponentNodes.Ref
	|		INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
	|		ON MaximaOfComponentNodes.Period = SubAssetsComponentsOfDepreciation.Period
	|		AND MaximaOfComponentNodes.SubAssetComponent = SubAssetsComponentsOfDepreciation.SubAssetComponent
	|		AND VNAObjects.NonCurrentAsset = SubAssetsComponentsOfDepreciation.FixedAsset
	|WHERE
	|	VNAObjects.NonCurrentAsset <> UNDEFINED
	|
	|INDEX BY
	|	Ref,
	|	NonCurrentAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// A list of non-current assets for which it makes sense to calculate impairment.
	|SELECT
	|	ImpairmentBalances.NonCurrentAsset AS NonCurrentAsset
	|INTO ImpairmentBalances
	|FROM
	|	AccumulationRegister.ImpairmentFA.Balance(&BoundaryOfResidues) AS ImpairmentBalances
	|
	|INDEX BY
	|	NonCurrentAsset
	|;
	|//////////////////////////////////////////////////////////////
	|DROP VNAObjects_Preliminary
	|;
	|
	|//////////////////////////////////////////////////////////////
	|DROP MaximaOfComponentNodes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	VNAObjects.Priority,
	|	VNAObjects.Ref,
	|	VNAObjects.Organization,
	|	VNAObjects.Date
	|FROM
	|	VNAObjects AS VNAObjects
	|		LEFT JOIN ImpairmentBalances AS ImpairmentBalances
	|		ON VNAObjects.NonCurrentAsset = ImpairmentBalances.NonCurrentAsset
	|WHERE
	|	NOT VALUETYPE(VNAObjects.Ref) IN (TYPE(Document.PreparingForIntangibleAssetSale2_4),
	|										TYPE(Document.PreparingForFixedAssetSale2_4),
	|										TYPE(Document.DisposeIntangibleAssets2_4),
	|										TYPE(Document.DisposeFixedAssets2_4),
	|										TYPE(Document.SplitFixedAssets),
	|										TYPE(Document.MergeOfFixedAssets),
	|										TYPE(Document.EntryOfCapitalAssetsBalance2_4),
	|										TYPE(Document.OBEntrySubAssetsAndComponentsOfDepreciation),
	|										TYPE(Document.FARevaluation2_4),
	|										TYPE(Document.IARevaluation2_4))
	|	AND (VNAObjects.Ref REFS Document.ImpairmentFA
	|		OR NOT ImpairmentBalances.NonCurrentAsset IS NULL)
	|ORDER BY
	|	Priority,
	|	Date,
	|	Ref";
	
	Selection = RequestDocuments.Execute().Select();
	
	TTUsed = "BorderCache,VNAObjects";
	
	While Selection.Next() Do
		
		TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);
		
		// We filter out documents that are not registrars of impairment.
		RecordSetIsEmpty = AccumulationRegisters.ImpairmentFA.CreateRecordSet();
		TypesOfLoggers = RecordSetIsEmpty.Filter.Recorder.ValueType.Types(); // array of types. 
		If TypesOfLoggers.Find(TypeOf(Selection.Ref)) = Undefined Then
			Continue;
		EndIf;	

		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("Ref", Selection.Ref);
		Query.SetParameter("Organization", Selection.Organization);
		Query.SetParameter("Period", ?(Selection.Priority = 1, Selection.Date,EndOfMonth(Selection.Date)));
		
		// We take the remaining depreciation at the time before the document.
		Query.SetParameter("BoundaryOfResidues", New Boundary(Selection.Ref.PointInTime(),BoundaryType.Excluding));
		
		// The composition of the EGDS is taken at the time before the document.
		Query.SetParameter("DocumentBorder", New Boundary(Selection.Ref.PointInTime(),BoundaryType.Excluding));
		
		// We take the values of the new accounting analysts at the time after the document.
		Query.SetParameter("BoundaryOfAnalytics", New Boundary(Selection.Ref.PointInTime(),BoundaryType.Including));
		
		QueryTexts = New ValueList;
		QueryTextTTNewAnalyticsVNA(QueryTexts);
		QueryTextTTNewCGU(QueryTexts);
		QueryTextTTOldCGU(QueryTexts);
		QueryTextTTReflectionOfIncomeExpenses(QueryTexts);
		QueryTextImpairmentFA(Query, QueryTexts);
		
		If TypeOf(Selection.Ref) = TypeOf(Documents.ImpairmentFA.EmptyRef()) Then
			QueryTextCostOfFADuringRevaluation(Query, QueryTexts);
			QueryTextDepreciationOfFADuringRevaluation(Query, QueryTexts);
			QueryTextIACostDuringRevaluation(Query, QueryTexts);
			QueryTextIntangibleAssetAmortizationChargeDuringRevaluation(Query, QueryTexts);
		EndIf;
		
		QueryTextOtherExpenses(Query, QueryTexts);
		QueryTextOtherIncome(Query, QueryTexts);
		QueryTextRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts);
		
		TablesForRegisteredRecords = DocumentsPosting.InitializeDocumentDataForPosting(Query,
																								QueryTexts,
																								Undefined);
		
		DocumentObject = DocumentsPosting.DocumentEmulation(Selection.Ref, Selection.Date);
		DeferredFARecordGeneration.SetFlagForOperation(DocumentObject);
		
		NonCurrentAssetsInternal.WriteMotionTables(TablesForRegisteredRecords, DocumentObject, TempTablesManager, False);

		ManagementAccountingPostingServer.UpdateRegisteredRecordsOfAssetsLiabilities(Selection.Ref, Selection.Ref.GetObject().RegisterRecords);
		NonCurrentAssetsInternal.UpdateRegisteredRecordsOfAssetsLiabilities(Selection.Ref);
		
		If ExecutionParameters.GenerateJobs 
				And TypeOf(Selection.Ref) <> Type("DocumentRef.ImpairmentFA") Then
			DocumentsPosting.CreateTasksForDeferredRegisteredRecords(DocumentObject, TempTablesManager);
		EndIf;
		
		If ExecutionParameters.ReturnDocumentsToReflection Then
			NonCurrentAssetsInternal.ReturnDocumentsToReflection(
				Selection.Ref, Selection.Organization, Selection.Date, TablesForRegisteredRecords);
		EndIf;

		
	EndDo;
		
EndProcedure

// Disable the use of depreciation.
// 
// Parameters:
//  BranchOfSettingsTree - DataCompositionSelectedFieldGroup, DataCompositionSelectedField, DataCompositionAutoSelectedField - A branch of the settings tree.
Procedure DisableUseOfImpairment(BranchOfSettingsTree, UseFixedAssetImpairment)
	
	// The user can manually disable the impairment fields in the report.
	// Therefore, we will calculate the mode of use of the field in Min (the current mode of use of the field, use the value).
	
	ImpairmentSearchString = NStr("vi = 'Giảm giá';
									|ru = 'Обесценение';
									|en = 'Impairment'; fa = 'کاهش ارزش';
									|it = 'Svalutazione';
									|pl = 'Utrata wartości';
									|tr = 'Değer kaybı'");

	If Find(BranchOfSettingsTree.Title, ImpairmentSearchString) <> 0 Then
		BranchOfSettingsTree.Use = Min(BranchOfSettingsTree.Use, UseFixedAssetImpairment);
	EndIf;

	If TypeOf(BranchOfSettingsTree) = Type("DataCompositionSelectedField") Then

		If BranchOfSettingsTree.Field <> Undefined And Find(BranchOfSettingsTree.Field, ImpairmentSearchString) <> 0 Then
			BranchOfSettingsTree.Use = Min(BranchOfSettingsTree.Use, UseFixedAssetImpairment);
		EndIf;

		Return; // This is the final element of the tree
	EndIf;
	
	For Each BranchElement In BranchOfSettingsTree.Items Do
		If TypeOf(BranchElement) = Type("DataCompositionSelectedField") Then
			// This is the final element of the settings tree branch
			
			// By title
			If Find(BranchElement.Title, ImpairmentSearchString) <> 0 Then
				BranchElement.Use = Min(BranchElement.Use, UseFixedAssetImpairment);
			EndIf;
			
			// By field
			If BranchElement.Field <> Undefined And Find(BranchElement.Field, ImpairmentSearchString) <> 0 Then
				BranchOfSettingsTree.Use = Min(BranchOfSettingsTree.Use, UseFixedAssetImpairment);
			EndIf;

		Else
			// This is a branch of the settings tree
			// By title
			If Find(BranchElement.Title, ImpairmentSearchString) <> 0 Then
				BranchElement.Use = Min(BranchElement.Use, UseFixedAssetImpairment);
			EndIf;
			
			If BranchElement.Items.Count() > 0 Then
				For Each Item In BranchElement.Items Do
					DisableUseOfImpairment(Item, UseFixedAssetImpairment); // Recursive call.
				EndDo;
			EndIf;

		EndIf;

	EndDo;

EndProcedure

Procedure InitializeTTBalancesForReclassification(Query, QueryTexts)

	If Query.Parameters.Property("TTBalancesForReclassificationInitialized") Then
		Return;
	EndIf;
	
	RequestForImpairmentBalances = New Query;
	RequestForImpairmentBalances.TempTablesManager = Query.TempTablesManager;
	
	RequestForImpairmentBalances.SetParameter("DocumentBorder", Query.Parameters.DocumentBorder);
	RequestForImpairmentBalances.SetParameter("Ref",           Query.Parameters.Ref);
	RequestForImpairmentBalances.SetParameter("Period",           Query.Parameters.Period);

	DocumentOrganizations = New Array;
	If Query.Parameters.Ref.Metadata().Attributes.Find("Organization") <> Undefined Then
		 DocumentOrganizations.Add(Common.ObjectAttributeValue(Query.Parameters.Ref, "Organization"));
	EndIf;
	If Query.Parameters.Ref.Metadata().Attributes.Find("CompanyRecipient") <> Undefined Then
		 DocumentOrganizations.Add(Common.ObjectAttributeValue(Query.Parameters.Ref, "CompanyRecipient"));
	 EndIf;
	 
	RequestForImpairmentBalances.SetParameter("DocumentOrganizations", DocumentOrganizations);
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettingsCached.AccountingSettingsForNonCurrentAssets(
									Query.Parameters.Organization,
									Query.Parameters.Period); 
									
	// we take the accrual procedure for FA and IA separately.
	DepreciationProcedureFAMan =  AccountingPolicyParameters.ProcedureOfFixedAssetDepreciationCharge;
	ProcedureOfFixedAssetDepreciationChargeLocal = AccountingPolicyParameters.ProcedureOfFixedAssetDepreciationChargeLocal; 
	DepreciationProcedureIAMan =  AccountingPolicyParameters.ProcedureOfIntangibleAssetAmortizationCharge;
	ProcedureOfIntangibleAssetAmortizationChargeLocal = AccountingPolicyParameters.ProcedureOfIntangibleAssetAmortizationChargeLocal;
	
	RequestForImpairmentBalances.SetParameter("DepreciationProcedureFAMan", DepreciationProcedureFAMan);
	RequestForImpairmentBalances.SetParameter("ProcedureOfFixedAssetDepreciationChargeLocal",ProcedureOfFixedAssetDepreciationChargeLocal);
	RequestForImpairmentBalances.SetParameter("DepreciationProcedureIAMan", DepreciationProcedureIAMan);
	RequestForImpairmentBalances.SetParameter("ProcedureOfIntangibleAssetAmortizationChargeLocal",ProcedureOfIntangibleAssetAmortizationChargeLocal);
	
	RequestForImpairmentBalances.Text =
	" // When Depreciation is CALCULATED from the 1st of the next month, impairment is carried out according
	| // to the first document in the month, because depreciation is calculated according to measurements as of THE State at
	| // the beginning of the month.
	|
	| // For accounting policy, amortize the cost of the BHA taking into account the impairment and charge an additional impairment adjustment.
	|SELECT
	|	ImpairmentFA.Organization AS Organization,
	|	ImpairmentFA.NonCurrentAsset AS NonCurrentAsset,
	|	ImpairmentFA.CGU AS CGU,
	|	ImpairmentFA.Department AS Department,
	|	ImpairmentFA.LineOfBusiness AS LineOfBusiness,
	|	ImpairmentFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	CASE
	|		WHEN &ProcedureOfFixedAssetDepreciationChargeLocal = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|			THEN ImpairmentFA.ImpairmentLocalAssets
	|		ELSE 0
	|	END AS ImpairmentLocalAssets,
	|
	|	CASE
	|		WHEN &DepreciationProcedureFAMan = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|			THEN ImpairmentFA.ImpairmenMan
	|		ELSE 0
	|	END AS ImpairmenMan,
	|
	|	CASE
	|		WHEN &ProcedureOfFixedAssetDepreciationChargeLocal = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|			THEN ImpairmentFA.LossFromImpairmentLocal
	|		ELSE 0
	|	END AS LossFromImpairmentLocal,
	|
	|	CASE
	|		WHEN &DepreciationProcedureFAMan = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|			THEN ImpairmentFA.LossFromImpairmentMgmt
	|		ELSE 0
	|	END AS LossFromImpairmentMgmt,
	|	1 AS ID
	|
	|INTO ImpairmentOnDepreciationOf_Line
	|
	|FROM
	|	AccumulationRegister.ImpairmentFA AS ImpairmentFA
	|
	|WHERE
	|	(ImpairmentFA.Recorder REFS Document.FixedAssetsDepreciationCharge2_4
	|			OR ImpairmentFA.Recorder REFS Document.IntangibleAssetsAmortizationCharge2_4)
	|	AND ImpairmentFA.Period = ENDOFPERIOD(&Period, MONTH)
	|	AND ImpairmentFA.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND ImpairmentFA.Organization IN (&DocumentOrganizations)
	|	AND ImpairmentFA.NonCurrentAsset REFS Catalog.Assets
	|
	|UNION ALL
	|
	|SELECT
	|	ImpairmentFA.Organization AS Organization,
	|	ImpairmentFA.NonCurrentAsset AS NonCurrentAsset,
	|	ImpairmentFA.CGU AS CGU,
	|	ImpairmentFA.Department AS Department,
	|	ImpairmentFA.LineOfBusiness AS LineOfBusiness,
	|	ImpairmentFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	CASE
	|		WHEN &ProcedureOfIntangibleAssetAmortizationChargeLocal = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|			THEN ImpairmentFA.ImpairmentLocalAssets
	|		ELSE 0
	|	END AS ImpairmentLocalAssets,
	|
	|	CASE
	|		WHEN &DepreciationProcedureIAMan = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|			THEN ImpairmentFA.ImpairmenMan
	|		ELSE 0
	|	END AS ImpairmenMan,
	|
	|	CASE
	|		WHEN &ProcedureOfIntangibleAssetAmortizationChargeLocal = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|			THEN ImpairmentFA.LossFromImpairmentLocal
	|		ELSE 0
	|	END AS LossFromImpairmentLocal,
	|
	|	CASE
	|		WHEN &DepreciationProcedureIAMan = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|			THEN ImpairmentFA.LossFromImpairmentMgmt
	|		ELSE 0
	|	END AS LossFromImpairmentMgmt,
	|	2 AS ID
	|
	|FROM
	|	AccumulationRegister.ImpairmentFA AS ImpairmentFA
	|
	|WHERE
	|	(ImpairmentFA.Recorder REFS Document.FixedAssetsDepreciationCharge2_4
	|			OR ImpairmentFA.Recorder REFS Document.IntangibleAssetsAmortizationCharge2_4)
	|	AND ImpairmentFA.Period = ENDOFPERIOD(&Period, MONTH)
	|	AND ImpairmentFA.Organization IN (&DocumentOrganizations)
	|	AND ImpairmentFA.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND ImpairmentFA.NonCurrentAsset REFS Catalog.IntangibleAssets
	|
	|UNION ALL
	|
	| // For accounting policy, amortize the full cost and reverse the impairment adjustment.
	|SELECT
	|	ImpairmentFA.Organization AS Organization,
	|	ImpairmentFA.NonCurrentAsset AS NonCurrentAsset,
	|	ImpairmentFA.CGU AS CGU,
	|	ImpairmentFA.Department AS Department,
	|	ImpairmentFA.LineOfBusiness AS LineOfBusiness,
	|	ImpairmentFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	CASE
	|		WHEN &ProcedureOfFixedAssetDepreciationChargeLocal = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|			THEN -ImpairmentFA.ImpairmentLocalAssets
	|		ELSE 0
	|	END AS ImpairmentLocalAssets,
	|
	|	CASE
	|		WHEN &DepreciationProcedureFAMan = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|			THEN -ImpairmentFA.ImpairmenMan
	|		ELSE 0
	|	END AS ImpairmenMan,
	|
	|	CASE
	|		WHEN &ProcedureOfFixedAssetDepreciationChargeLocal = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|			THEN -ImpairmentFA.LossFromImpairmentLocal
	|		ELSE 0
	|	END AS LossFromImpairmentLocal,
	|
	|	CASE
	|		WHEN &DepreciationProcedureFAMan = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|			THEN -ImpairmentFA.LossFromImpairmentMgmt
	|		ELSE 0
	|	END AS LossFromImpairmentMgmt,
	|	3 AS ID
	|
	|FROM
	|	AccumulationRegister.ImpairmentFA AS ImpairmentFA
	|
	|WHERE
	|	(ImpairmentFA.Recorder REFS Document.FixedAssetsDepreciationCharge2_4
	|			OR ImpairmentFA.Recorder REFS Document.IntangibleAssetsAmortizationCharge2_4)
	|	AND ImpairmentFA.Period = ENDOFPERIOD(&Period, MONTH)
	|	AND ImpairmentFA.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND ImpairmentFA.Organization IN (&DocumentOrganizations)
	|	AND ImpairmentFA.NonCurrentAsset REFS Catalog.Assets
	|
	|UNION ALL
	|
	|SELECT
	|	ImpairmentFA.Organization AS Organization,
	|	ImpairmentFA.NonCurrentAsset AS NonCurrentAsset,
	|	ImpairmentFA.CGU AS CGU,
	|	ImpairmentFA.Department AS Department,
	|	ImpairmentFA.LineOfBusiness AS LineOfBusiness,
	|	ImpairmentFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	CASE
	|		WHEN &ProcedureOfIntangibleAssetAmortizationChargeLocal = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|			THEN -ImpairmentFA.ImpairmentLocalAssets
	|		ELSE 0
	|	END AS ImpairmentLocalAssets,
	|
	|	CASE
	|		WHEN &DepreciationProcedureIAMan = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|			THEN -ImpairmentFA.ImpairmenMan
	|		ELSE 0
	|	END AS ImpairmenMan,
	|
	|	CASE
	|		WHEN &ProcedureOfIntangibleAssetAmortizationChargeLocal = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|			THEN -ImpairmentFA.LossFromImpairmentLocal
	|		ELSE 0
	|	END AS LossFromImpairmentLocal,
	|
	|	CASE
	|		WHEN &DepreciationProcedureIAMan = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|			THEN -ImpairmentFA.LossFromImpairmentMgmt
	|		ELSE 0
	|	END AS LossFromImpairmentMgmt,
	|	4 AS ID
	|
	|FROM
	|	AccumulationRegister.ImpairmentFA AS ImpairmentFA
	|
	|WHERE
	|	(ImpairmentFA.Recorder REFS Document.FixedAssetsDepreciationCharge2_4
	|			OR ImpairmentFA.Recorder REFS Document.IntangibleAssetsAmortizationCharge2_4)
	|	AND ImpairmentFA.Period = ENDOFPERIOD(&Period, MONTH)
	|	AND ImpairmentFA.Organization IN (&DocumentOrganizations)
	|	AND ImpairmentFA.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND ImpairmentFA.NonCurrentAsset REFS Catalog.IntangibleAssets
	|
	|INDEX BY
	|	Organization,
	|	NonCurrentAsset,
	|	CGU,
	|	Department,
	|	LineOfBusiness,
	|	FinancialAccountingGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DepreciationImpairment.Organization AS Organization,
	|	DepreciationImpairment.NonCurrentAsset AS NonCurrentAsset,
	|	DepreciationImpairment.CGU AS CGU,
	|	DepreciationImpairment.Department AS Department,
	|	DepreciationImpairment.LineOfBusiness AS LineOfBusiness,
	|	DepreciationImpairment.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	SUM(DepreciationImpairment.ImpairmentLocalAssets) AS ImpairmentLocalAssets,
	|	SUM(DepreciationImpairment.ImpairmenMan) AS ImpairmenMan,
	|	SUM(DepreciationImpairment.LossFromImpairmentLocal) AS LossFromImpairmentLocal,
	|	SUM(DepreciationImpairment.LossFromImpairmentMgmt) AS LossFromImpairmentMgmt
	|
	|INTO DepreciationImpairment
	|
	|FROM 
	|	ImpairmentOnDepreciationOf_Line AS DepreciationImpairment
	|
	|GROUP BY
	|	DepreciationImpairment.Organization,
	|	DepreciationImpairment.NonCurrentAsset,
	|	DepreciationImpairment.CGU,
	|	DepreciationImpairment.Department,
	|	DepreciationImpairment.LineOfBusiness,
	|	DepreciationImpairment.FinancialAccountingGroup
	|
	|INDEX BY
	|	Organization,
	|	NonCurrentAsset,
	|	CGU,
	|	Department,
	|	LineOfBusiness,
	|	FinancialAccountingGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ImpairmentFABalance.NonCurrentAsset AS NonCurrentAsset,
	|	ImpairmentFABalance.CGU AS CGU,
	|	ImpairmentFABalance.Organization AS Organization,
	|	ImpairmentFABalance.Organization.ParentCompany AS ParentCompany,
	|	ImpairmentFABalance.Department AS Department,
	|	ImpairmentFABalance.LineOfBusiness AS LineOfBusiness,
	|	ImpairmentFABalance.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	-ImpairmentFABalance.ImpairmentLocalAssetsBalance -
	|				ISNULL(DepreciationImpairment.ImpairmentLocalAssets, 0) AS ImpairmentLocalAssets,
	|
	|	-ImpairmentFABalance.ImpairmenManBalance -
	|				ISNULL(DepreciationImpairment.ImpairmenMan, 0) AS ImpairmenMan,
	|
	|	-ImpairmentFABalance.LossFromImpairmentLocalBalance -
	|				ISNULL(DepreciationImpairment.LossFromImpairmentLocal, 0) AS LossFromImpairmentLocal,
	|
	|	-ImpairmentFABalance.LossFromImpairmentMgmtBalance -
	|				ISNULL(DepreciationImpairment.LossFromImpairmentMgmt, 0) AS LossFromImpairmentMgmt,
	|
	|	ISNULL(DepreciationImpairment.ImpairmentLocalAssets, 0) AS ImpairmentInDepreciationOfLocal,
	|	ISNULL(DepreciationImpairment.ImpairmenMan, 0)  AS ImpairmentDuringDepreciationOfMan
	|
	|FROM
	|	AccumulationRegister.ImpairmentFA.Balance(
	|			&DocumentBorder,
	|			Organization IN (&DocumentOrganizations) 
	|			AND
	|			NonCurrentAsset IN
	|				(SELECT
	|					T.NonCurrentAsset
	|				FROM
	|					VNAObjects AS T
	|				WHERE
	|					T.Ref = &Ref)) AS ImpairmentFABalance 
	|
	|		LEFT JOIN DepreciationImpairment AS DepreciationImpairment
	|		ON ImpairmentFABalance.Organization = DepreciationImpairment.Organization
	|			AND ImpairmentFABalance.NonCurrentAsset = DepreciationImpairment.NonCurrentAsset
	|			AND ImpairmentFABalance.CGU = DepreciationImpairment.CGU
	|			AND ImpairmentFABalance.Department = DepreciationImpairment.Department
	|			AND ImpairmentFABalance.LineOfBusiness = DepreciationImpairment.LineOfBusiness
	|			AND ImpairmentFABalance.FinancialAccountingGroup = DepreciationImpairment.FinancialAccountingGroup
	|";
	
	ImpairmentBalances = RequestForImpairmentBalances.Execute().Unload();
	
	TMCommonUse.AddRowIDToTable(ImpairmentBalances, "FinRecordID", "String");
	
	RequestForImpairmentBalances.SetParameter("ImpairmentBalances", ImpairmentBalances);
	
	RequestForImpairmentBalances.Text =
	"
	|SELECT
	|	ImpairmentBalances.FinRecordID AS FinRecordID,
	|	ImpairmentBalances.Organization AS Organization,
	|	ImpairmentBalances.ParentCompany AS ParentCompany,
	|	ImpairmentBalances.NonCurrentAsset AS NonCurrentAsset,
	|	ImpairmentBalances.Department AS Department,
	|	ImpairmentBalances.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ImpairmentBalances.LineOfBusiness AS LineOfBusiness,
	|	ImpairmentBalances.CGU AS CGU,
	|	ImpairmentBalances.ImpairmentLocalAssets AS ImpairmentLocalAssets,
	|	ImpairmentBalances.ImpairmenMan AS ImpairmenMan,
	|	ImpairmentBalances.LossFromImpairmentLocal AS LossFromImpairmentLocal,
	|	ImpairmentBalances.LossFromImpairmentMgmt AS LossFromImpairmentMgmt,
	|	ImpairmentBalances.ImpairmentInDepreciationOfLocal,
	|	ImpairmentBalances.ImpairmentDuringDepreciationOfMan
	|INTO TTBalancesForReclassification
	|FROM
	|	&ImpairmentBalances AS ImpairmentBalances
	|INDEX BY
	|	NonCurrentAsset
	|";
	RequestForImpairmentBalances.Execute();
	
	Query.SetParameter("TTBalancesForReclassificationInitialized", True);
	
EndProcedure

Procedure InitializeTTBalancesForRecovery(Query, QueryTexts)

	If Query.Parameters.Property("TTRemainsToRestoreInitialized") Then
		Return;
	EndIf;
	
	RequestForImpairmentBalances = New Query;
	RequestForImpairmentBalances.TempTablesManager = Query.TempTablesManager;
	
	RequestForImpairmentBalances.SetParameter("BoundaryOfResidues", Query.Parameters.BoundaryOfResidues);
	RequestForImpairmentBalances.SetParameter("Ref",          Query.Parameters.Ref);
	
	RequestForImpairmentBalances.Text = 
	"SELECT
	|	ImpairmentFABalance.NonCurrentAsset AS NonCurrentAsset,
	|	ImpairmentFABalance.CGU,
	|	ImpairmentFABalance.Organization AS Organization,
	|	ImpairmentFABalance.Department,
	|	ImpairmentFABalance.LineOfBusiness,
	|	ImpairmentFABalance.FinancialAccountingGroup,
	|	-ImpairmentFABalance.ImpairmentLocalAssetsBalance AS ImpairmentLocalAssets,
	|	-ImpairmentFABalance.ImpairmenManBalance AS ImpairmenMan,
	|	-ImpairmentFABalance.LossFromImpairmentLocalBalance AS LossFromImpairmentLocal,
	|	-ImpairmentFABalance.LossFromImpairmentMgmtBalance AS LossFromImpairmentMgmt
	|FROM
	|	AccumulationRegister.ImpairmentFA.Balance(&BoundaryOfResidues, NonCurrentAsset IN
	|		(SELECT
	|			T.NonCurrentAsset
	|		FROM
	|			VNAObjects AS T
	|		WHERE
	|			T.Ref = &Ref)
	|	) AS ImpairmentFABalance
	|";
	
	ImpairmentBalances = RequestForImpairmentBalances.Execute().Unload();
	
	TMCommonUse.AddRowIDToTable(ImpairmentBalances, "FinRecordID", "String");
	
	RequestForImpairmentBalances.SetParameter("ImpairmentBalances", ImpairmentBalances);
	
	RequestForImpairmentBalances.Text =
	"
	|SELECT
	|	ImpairmentBalances.FinRecordID AS FinRecordID,
	|	ImpairmentBalances.Organization AS Organization,
	|	ImpairmentBalances.NonCurrentAsset AS NonCurrentAsset,
	|	ImpairmentBalances.Department AS Department,
	|	ImpairmentBalances.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	ImpairmentBalances.LineOfBusiness AS LineOfBusiness,
	|	ImpairmentBalances.CGU AS CGU,
	|	ImpairmentBalances.ImpairmentLocalAssets AS ImpairmentLocalAssets,
	|	ImpairmentBalances.ImpairmenMan AS ImpairmenMan,
	|	ImpairmentBalances.LossFromImpairmentLocal AS LossFromImpairmentLocal,
	|	ImpairmentBalances.LossFromImpairmentMgmt AS LossFromImpairmentMgmt
	|INTO TTResiduesToRecover
	|FROM
	|	&ImpairmentBalances AS ImpairmentBalances
	|INDEX BY
	|	NonCurrentAsset
	|";
	RequestForImpairmentBalances.Execute();
	
	Query.SetParameter("TTRemainsToRestoreInitialized", True);
	
EndProcedure

Procedure InitializeTTAccrualRecovery(Query, QueryTexts)
	
	If Query.Parameters.Property("TTAccrualRecoveryInitialized") Then
		Return;
	EndIf;
	
	Accruals = AccumulationRegisters.ImpairmentFA.CreateRecordSet().UnloadColumns();
	Accruals.Columns.Delete("Active");
	
	NumberType = New TypeDescription("Number");
	// Columns for cost and depreciation registers.
	Accruals.Columns.Add("CostRevaluationReserve", NumberType);
	Accruals.Columns.Add("CostRevaluationReserveLocal", NumberType);
	Accruals.Columns.Add("DepreciationRevaluationReserve", NumberType);
	Accruals.Columns.Add("DepreciationRevaluationReserveLocal", NumberType);
	// Columns for changes in cost reserve and depreciation.
	Accruals.Columns.Add("ChangeInCostReserve", NumberType);
	Accruals.Columns.Add("ChangeInReserveOfCostOfLocal", NumberType);
	Accruals.Columns.Add("ChangeInDepreciationReserve", NumberType);
	Accruals.Columns.Add("ChangeInDepreciationReserveLocal", NumberType);
	
	Recovery = Accruals.Copy();
	
	RequestToChargeRecovery = New Query;
	RequestToChargeRecovery.TempTablesManager = Query.TempTablesManager;
	
	RequestToChargeRecovery.SetParameter("Organization",      Query.Parameters.Organization);
	RequestToChargeRecovery.SetParameter("BoundaryOfResidues",  Query.Parameters.BoundaryOfResidues);
	RequestToChargeRecovery.SetParameter("DocumentBorder", Query.Parameters.DocumentBorder);
	RequestToChargeRecovery.SetParameter("BoundaryOfAnalytics", Query.Parameters.BoundaryOfAnalytics);
	RequestToChargeRecovery.SetParameter("Period",           Query.Parameters.Period);
	RequestToChargeRecovery.SetParameter("Ref",           Query.Parameters.Ref);
	
	RequestToChargeRecovery.Text = 
	"// The parent company with all its branch offices or only the branch office.
	|// As part of the assets included in the CGU of the parent company, there may be 
	|// assets belonging to branch offices.
	|// In the CGU of branch offices - the assets of only branch offices.
	|SELECT
	|	Companies.Ref AS Organization
	|INTO CompaniesList
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.ParentCompany = &Organization
	|
	|UNION
	|
	|SELECT
	|	Companies.Ref AS Organization
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.Ref = &Organization
	|;//0
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// The recoverable amount according to the document is the impairment of BHA.
	|SELECT
	|	ImpairmentFA.CGU                     AS NonCurrentAsset,
	|	ImpairmentFA.RecoverableAmountLocal AS RecoverableAmountLocal,
	|	ImpairmentFA.RecoverableAmountMan  AS RecoverableAmountMan
	|
	|INTO TTRecoverableAmountOfImpairmentDocument
	|
	|FROM
	|	Document.ImpairmentFA.CashGeneratingUnits AS ImpairmentFA
	|WHERE
	|	ImpairmentFA.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	ImpairmentFA.FixedAsset           AS NonCurrentAsset,
	|	ImpairmentFA.RecoverableAmountLocal   AS RecoverableAmountLocal,
	|	ImpairmentFA.RecoverableAmountMan    AS RecoverableAmountMan
	|FROM
	|	Document.ImpairmentFA.FixedAssets AS ImpairmentFA
	|WHERE
	|	ImpairmentFA.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	ImpairmentFA.IntangibleAsset        AS NonCurrentAsset,
	|	ImpairmentFA.RecoverableAmountLocal   AS RecoverableAmountLocal,
	|	ImpairmentFA.RecoverableAmountMan    AS RecoverableAmountMan
	|FROM
	|	Document.ImpairmentFA.IntangibleAssets AS ImpairmentFA
	|WHERE
	|	ImpairmentFA.Ref = &Ref
	|
	|INDEX BY
	|	NonCurrentAsset
	|;//1
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// The list of assets included in the CGU specified in the document Impairment of the HPA.
	|// According to the list of companies, at the time before the document, the Depreciation of the HPA.
	|SELECT
	|	CGUCompositionSliceLast.NonCurrentAsset AS NonCurrentAsset,
	|	CGUCompositionSliceLast.Organization AS Organization,
	|	CGUCompositionSliceLast.CGU AS CGU
	|INTO ListOfCGUAssets
	|FROM
	|	InformationRegister.CGUComposition.SliceLast(&DocumentBorder, ) AS CGUCompositionSliceLast
	|		INNER JOIN CompaniesList AS CompaniesList
	|		ON (CompaniesList.Organization = CGUCompositionSliceLast.Organization)
	|		INNER JOIN Document.ImpairmentFA.CashGeneratingUnits AS ListOfCGUDocuments
	|		ON (ListOfCGUDocuments.CGU = CGUCompositionSliceLast.CGU
	|			AND ListOfCGUDocuments.Ref = &Ref)
	|	WHERE
	|		CGUCompositionSliceLast.CGU <> VALUE(Catalog.CashGeneratingUnits.EmptyRef)
	|INDEX BY 
	|	CGU,
	|	NonCurrentAsset
	|;//2
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// The recoverable amount of assets included in the CGU is calculated according to the CGU and the list of companies.
	|// For independent assets that are not included in the CGU - for the specified company.
	|SELECT
	|	ListOfCGUAssets.NonCurrentAsset                AS NonCurrentAsset,
	|	TTRecoverableAmountOfImpairmentDocument.NonCurrentAsset    AS CGU,
	|	ListOfCGUAssets.Organization
	|	
	|INTO DepreciableVNA_Preliminary
	|
	|FROM
	|	TTRecoverableAmountOfImpairmentDocument AS TTRecoverableAmountOfImpairmentDocument
	|		INNER JOIN ListOfCGUAssets AS ListOfCGUAssets
	|		ON (ListOfCGUAssets.CGU = TTRecoverableAmountOfImpairmentDocument.NonCurrentAsset)
	|
	|UNION ALL
	|
	|SELECT
	|	TTRecoverableAmount.NonCurrentAsset                              AS NonCurrentAsset,
	|	VALUE(Catalog.CashGeneratingUnits.EmptyRef) AS CGU,
	|	&Organization AS Organization
	|FROM
	|	TTRecoverableAmountOfImpairmentDocument AS TTRecoverableAmount
	|WHERE
	|	NOT TTRecoverableAmount.NonCurrentAsset REFS Catalog.CashGeneratingUnits
	|
	|INDEX BY
	|	NonCurrentAsset
	|;//3
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// Nodes and components of depreciated non-current assets.
	|SELECT DISTINCT
	|	NodesComponents.SubAssetComponent AS SubAssetComponent,
	|	NodesComponents.FixedAsset AS FixedAsset
	|	
	|INTO NodesOfFixedAssets
	|
	|FROM
	|	InformationRegister.SubAssetsComponentsOfDepreciation AS NodesComponents
	|		INNER JOIN DepreciableVNA_Preliminary AS DepreciableVNA
	|		ON NodesComponents.FixedAsset = DepreciableVNA.NonCurrentAsset
	|
	|INDEX BY
	|	SubAssetComponent,
	|	FixedAsset
	|;//4
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// All BHA objects with their nodes and components for the calculation of impairment.
	|SELECT DISTINCT
	|	DepreciableVNA.NonCurrentAsset AS NonCurrentAsset,
	|	DepreciableVNA.CGU              AS CGU,
	|	DepreciableVNA.Organization
	|	
	|INTO DepreciableVNA
	|
	|FROM
	|	DepreciableVNA_Preliminary AS DepreciableVNA
	|
	|UNION
	|
	|SELECT DISTINCT
	|	NodesComponents.SubAssetComponent        AS NonCurrentAsset,
	|	DepreciableVNA.CGU              AS CGU,
	|	DepreciableVNA.Organization
	|FROM
	|	DepreciableVNA_Preliminary AS DepreciableVNA
	|		INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation.SliceLast(
	|				&Period,
	|				SubAssetComponent IN
	|					(SELECT
	|						NodeTable_.SubAssetComponent AS SubAssetComponent
	|					FROM
	|						NodesOfFixedAssets AS NodeTable_)) AS NodesComponents
	|		ON DepreciableVNA.NonCurrentAsset = NodesComponents.FixedAsset
	|
	|INDEX BY
	|	NonCurrentAsset,
	|	Organization
	|;//5
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// Calculation of the book cost as Cost - Depreciation - Previously accrued impairment (taking into account the Registered Recorded current impairment document BHA).
	|SELECT
	|	MAX(BookValue.Organization)                  AS Organization,
	|	BookValue.NonCurrentAsset                      AS NonCurrentAsset,
	|	MAX(BookValue.Department)                AS Department,
	|	MAX(BookValue.FinancialAccountingGroup)       AS FinancialAccountingGroup,
	|	MAX(BookValue.LineOfBusiness)      AS LineOfBusiness,
	|	SUM(BookValue.LocalCost)                   AS LocalCost,                 // Book Value
	|	SUM(BookValue.CostMan)                    AS CostMan,
	|	SUM(BookValue.ImpairmentLocalAssets)                 AS ImpairmentLocalAssets,               // Previously accrued impairment (91+83 accounts)
	|	SUM(BookValue.ImpairmenMan)                  AS ImpairmenMan,
	|
	|	SUM(BookValue.CostRevaluationReserve)       AS CostRevaluationReserve,
	|	SUM(BookValue.CostRevaluationReserveLocal)   AS CostRevaluationReserveLocal,
	|	SUM(BookValue.DepreciationRevaluationReserve)       AS DepreciationRevaluationReserve,
	|	SUM(BookValue.DepreciationRevaluationReserveLocal)   AS DepreciationRevaluationReserveLocal,
	|
	|	SUM(BookValue.LossFromImpairmentMgmt)          AS LossFromImpairmentMgmt,
	|	SUM(BookValue.LossFromImpairmentLocal)         AS LossFromImpairmentLocal       // 91 accounts
	|	
	|	
	|INTO TTBookValue
	|
	|FROM
	|	(SELECT
	|		FACostBalance.Organization                AS Organization,
	|		FACostBalance.FixedAsset           AS NonCurrentAsset,
	|		FACostBalance.Department              AS Department,
	|		FACostBalance.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|		FACostBalance.LineOfBusiness    AS LineOfBusiness,
	|		
	|		FACostBalance.LocalCostBalance
	|				+ FACostBalance.CostTargetFinancingBalance AS LocalCost,
	|				
	|		FACostBalance.CostBalance           AS CostMan,
	|
	|		0                                             AS ImpairmentLocalAssets,
	|		0                                             AS ImpairmenMan,
	|
	|		FACostBalance.CostRevaluationReserveBalance     AS CostRevaluationReserve,
	|		FACostBalance.CostRevaluationReserveLocalBalance AS CostRevaluationReserveLocal,
	|		
	|		0     AS DepreciationRevaluationReserve,
	|		0     AS DepreciationRevaluationReserveLocal,
	|		
	|		0 AS LossFromImpairmentMgmt,
	|		0 AS LossFromImpairmentLocal
	|
	|	FROM
	|		AccumulationRegister.FACost.Balance(
	|				&BoundaryOfResidues,
	|				FixedAsset IN
	|					(SELECT
	|						T.NonCurrentAsset
	|					FROM
	|						DepreciableVNA AS T)) AS FACostBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		FixedAssetsDepreciationChargeBalance.Organization,
	|		FixedAssetsDepreciationChargeBalance.FixedAsset,
	|		FixedAssetsDepreciationChargeBalance.Department,
	|		FixedAssetsDepreciationChargeBalance.FinancialAccountingGroup,
	|		FixedAssetsDepreciationChargeBalance.LineOfBusiness,
	|		
	|		FixedAssetsDepreciationChargeBalance.DepreciationLocalBalance
	|				+ FixedAssetsDepreciationChargeBalance.FixedAssetDepreciationTargetFinancingBalance,
	|				
	|		FixedAssetsDepreciationChargeBalance.DepreciationBalance,
	|
	|		0                     AS ImpairmentLocalAssets,
	|		0                     AS ImpairmenMan,
	|		
	|		0     AS CostRevaluationReserve,
	|		0     AS CostRevaluationReserveLocal,
	|
	|		FixedAssetsDepreciationChargeBalance.DepreciationRevaluationReserveBalance     AS DepreciationRevaluationReserve,
	|		FixedAssetsDepreciationChargeBalance.DepreciationRevaluationReserveLocalBalance AS DepreciationRevaluationReserveLocal,
	|
	|		0 AS LossFromImpairmentMgmt,
	|		0 AS LossFromImpairmentLocal
	|
	|	FROM
	|		AccumulationRegister.FixedAssetsDepreciationCharge.Balance(
	|				&BoundaryOfResidues,
	|				FixedAsset IN
	|					(SELECT
	|						T.NonCurrentAsset
	|					FROM
	|						DepreciableVNA AS T)) AS FixedAssetsDepreciationChargeBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		IACostBalance.Organization,
	|		IACostBalance.IntangibleAsset,
	|		IACostBalance.Department,
	|		IACostBalance.FinancialAccountingGroup,
	|		IACostBalance.LineOfBusiness,
	|		
	|		IACostBalance.LocalCostBalance
	|				+ IACostBalance.CostTargetFinancingBalance,
	|				
	|		IACostBalance.CostBalance,
	|
	|		0 AS ImpairmentLocalAssets,
	|		0 AS ImpairmenMan,
	|
	|		IACostBalance.CostRevaluationReserveBalance     AS CostRevaluationReserve,
	|		IACostBalance.CostRevaluationReserveLocalBalance AS CostRevaluationReserveLocal,
	|
	|		0     AS DepreciationRevaluationReserve,
	|		0     AS DepreciationRevaluationReserveLocal,
	|
	|		0 AS LossFromImpairmentMgmt,
	|		0 AS LossFromImpairmentLocal
	|
	|	FROM
	|		AccumulationRegister.IACost.Balance(
	|				&BoundaryOfResidues,
	|				IntangibleAsset IN
	|					(SELECT
	|						T.NonCurrentAsset
	|					FROM
	|						DepreciableVNA AS T)) AS IACostBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		IntangibleAssetsAmortizationChargeBalance.Organization,
	|		IntangibleAssetsAmortizationChargeBalance.IntangibleAsset,
	|		IntangibleAssetsAmortizationChargeBalance.Department,
	|		IntangibleAssetsAmortizationChargeBalance.FinancialAccountingGroup,
	|		IntangibleAssetsAmortizationChargeBalance.LineOfBusiness,
	|		
	|		IntangibleAssetsAmortizationChargeBalance.DepreciationLocalBalance
	|				+ IntangibleAssetsAmortizationChargeBalance.FixedAssetDepreciationTargetFinancingBalance,
	|				
	|		IntangibleAssetsAmortizationChargeBalance.DepreciationBalance,
	|
	|		0 AS ImpairmentLocalAssets,
	|		0 AS ImpairmenMan,
	|		
	|		0     AS CostRevaluationReserve,
	|		0     AS CostRevaluationReserveLocal,
	|
	|		IntangibleAssetsAmortizationChargeBalance.DepreciationRevaluationReserveBalance     AS DepreciationRevaluationReserve,
	|		IntangibleAssetsAmortizationChargeBalance.DepreciationRevaluationReserveLocalBalance AS DepreciationRevaluationReserveLocal,
	|
	|		0 AS LossFromImpairmentMgmt,
	|		0 AS LossFromImpairmentLocal
	|
	|	FROM
	|		AccumulationRegister.IntangibleAssetsAmortizationCharge.Balance(
	|				&BoundaryOfResidues,
	|				IntangibleAsset IN
	|					(SELECT
	|						T.NonCurrentAsset
	|					FROM
	|						DepreciableVNA AS T)) AS IntangibleAssetsAmortizationChargeBalance
	|	
	|	UNION ALL
	|	
	|// Balances of previously accrued impairment.
	|	SELECT
	|		ImpairmentFABalance.Organization,
	|		ImpairmentFABalance.NonCurrentAsset,
	|		ImpairmentFABalance.Department,
	|		ImpairmentFABalance.FinancialAccountingGroup,
	|		ImpairmentFABalance.LineOfBusiness,
	|		0,
	|		0,
	|
	|		-ImpairmentFABalance.ImpairmentLocalAssetsBalance AS ImpairmentLocalAssets,
	|		-ImpairmentFABalance.ImpairmenManBalance  AS ImpairmenMan,
	|
	|		0 AS CostRevaluationReserve,
	|		0 AS CostRevaluationReserveLocal,
	|
	|		0 AS DepreciationRevaluationReserve,
	|		0 AS DepreciationRevaluationReserveLocal,
	|
	|		-ImpairmentFABalance.LossFromImpairmentMgmtBalance  AS LossFromImpairmentMgmt,
	|		-ImpairmentFABalance.LossFromImpairmentLocalBalance AS LossFromImpairmentLocal
	|
	|	FROM
	|		AccumulationRegister.ImpairmentFA.Balance(
	|				&BoundaryOfAnalytics,
	|				NonCurrentAsset IN
	|					(SELECT
	|						T.NonCurrentAsset
	|					FROM
	|						DepreciableVNA AS T)) AS ImpairmentFABalance
	|	
	|UNION ALL
	|	
	|	SELECT
	|		MovementImpairment.Organization,
	|		MovementImpairment.NonCurrentAsset,
	|		MovementImpairment.Department,
	|		MovementImpairment.FinancialAccountingGroup,
	|		MovementImpairment.LineOfBusiness,
	|		0,
	|		0,
	|		
	|		CASE
	|			WHEN MovementImpairment.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN MovementImpairment.ImpairmentLocalAssets
	|			ELSE -MovementImpairment.ImpairmentLocalAssets
	|		END,
	|		
	|		CASE
	|			WHEN MovementImpairment.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN MovementImpairment.ImpairmenMan
	|			ELSE -MovementImpairment.ImpairmenMan
	|		END,
	|
	|		0 AS CostRevaluationReserve,
	|		0 AS CostRevaluationReserveLocal,
	|
	|		0 AS DepreciationRevaluationReserve,
	|		0 AS DepreciationRevaluationReserveLocal,
	|
	|		CASE
	|			WHEN MovementImpairment.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN MovementImpairment.LossFromImpairmentMgmt
	|			ELSE -MovementImpairment.LossFromImpairmentMgmt
	|		END AS LossFromImpairmentMgmt,
	|
	|		CASE
	|			WHEN MovementImpairment.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN MovementImpairment.LossFromImpairmentLocal
	|			ELSE -MovementImpairment.LossFromImpairmentLocal
	|		END AS LossFromImpairmentLocal
	|
	|	FROM
	|		AccumulationRegister.ImpairmentFA AS MovementImpairment
	|	WHERE
	|		MovementImpairment.Recorder = &Ref
	|		AND MovementImpairment.Active
	|		AND MovementImpairment.NonCurrentAsset IN
	|				(SELECT
	|					T.NonCurrentAsset
	|				FROM
	|					DepreciableVNA AS T)
	|) AS BookValue
	|
	|GROUP BY
	|	BookValue.NonCurrentAsset
	|
	|INDEX BY
	|	NonCurrentAsset
	|;//6
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// The book value and recoverable amount of HPA Objects that are not included in the CGU.
	|SELECT
	|	TTBookValue.Organization                AS Organization,
	|	TTBookValue.NonCurrentAsset          AS NonCurrentAsset,
	|	TTBookValue.Department              AS Department,
	|	TTBookValue.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|	TTBookValue.LineOfBusiness    AS LineOfBusiness,
	|	TTRecoverableAmount.RecoverableAmountLocal  AS RecoverableAmountLocal,
	|	TTRecoverableAmount.RecoverableAmountMan   AS RecoverableAmountMan,
	|	TTBookValue.LocalCost              AS LocalCost,
	|	TTBookValue.CostMan               AS CostMan,
	|	TTBookValue.ImpairmentLocalAssets            AS ImpairmentLocalAssets,
	|	TTBookValue.ImpairmenMan             AS ImpairmenMan,
	|
	|	TTBookValue.CostRevaluationReserve            AS RevaluationReserveForMan,
	|	TTBookValue.CostRevaluationReserveLocal        AS CostRevaluationReserveLocal,
	|	-TTBookValue.DepreciationRevaluationReserve          AS RevaluationReserveForManDepreciation,
	|	-TTBookValue.DepreciationRevaluationReserveLocal      AS DepreciationRevaluationReserveLocal,
	|
	|	TTBookValue.LossFromImpairmentMgmt     AS LossFromImpairmentMgmt,
	|	TTBookValue.LossFromImpairmentLocal    AS LossFromImpairmentLocal,
	|	
	|	VALUE(Catalog.CashGeneratingUnits.EmptyRef) AS CGU
	|FROM
	|	TTBookValue AS TTBookValue
	|		INNER JOIN TTRecoverableAmountOfImpairmentDocument AS TTRecoverableAmount
	|		ON (TTRecoverableAmount.NonCurrentAsset = TTBookValue.NonCurrentAsset)
	|		LEFT JOIN ListOfCGUAssets AS ListOfCGUAssets
	|		ON ListOfCGUAssets.NonCurrentAsset = TTBookValue.NonCurrentAsset
	|WHERE
	|	ListOfCGUAssets.NonCurrentAsset IS NULL
	|;//7
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// Liquidation obligations of depreciation units and components with negative cost.
	|SELECT
	|	TTBookValue.Organization               AS Organization,
	|	NodesComponents.FixedAsset                 AS NonCurrentAsset,
	|	NodesComponents.SubAssetComponent                    AS LOComponent,
	|	TTBookValue.Department             AS Department,
	|	TTBookValue.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	TTBookValue.LineOfBusiness   AS LineOfBusiness,
	|	TTBookValue.LocalCost             AS LocalCost,
	|	TTBookValue.CostMan              AS CostMan,
	|
	|	TTBookValue.ImpairmentLocalAssets           AS ImpairmentLocalAssets,
	|	TTBookValue.ImpairmenMan            AS ImpairmenMan,
	|
	|	TTBookValue.CostRevaluationReserve          AS RevaluationReserveForMan,
	|	TTBookValue.CostRevaluationReserveLocal      AS CostRevaluationReserveLocal,
	|	TTBookValue.DepreciationRevaluationReserve          AS RevaluationReserveForManDepreciation,
	|	TTBookValue.DepreciationRevaluationReserveLocal      AS DepreciationRevaluationReserveLocal
	|
	|INTO TTLiquidationLiabilitiesNegativeCost
	|
	|FROM
	|	TTBookValue AS TTBookValue
	|		INNER JOIN NodesOfFixedAssets AS NodesComponents
	|		ON NodesComponents.SubAssetComponent = TTBookValue.NonCurrentAsset
	|WHERE
	|	NodesComponents.SubAssetComponent.ConsiderResidualLiabilityValue
	|	AND (TTBookValue.LocalCost < 0
	|		OR TTBookValue.CostMan < 0)
	|
	|INDEX BY
	|	NonCurrentAsset,
	|	LOComponent
	|;//8
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// The book cost TT of the VNA included in the CGU, taking into account liquidation obligations.
	|//	1) The cost of orizatelnye LO should be taken into account in the cost of the FA-owners.
	|//		If there are several LO for one FA, this is taken into account.
	|//	2) The cost of positive LO does not change.
	|SELECT
	|	TTBookValue.Organization               AS Organization,
	|	TTBookValue.NonCurrentAsset         AS NonCurrentAsset,
	|	TTBookValue.Department             AS Department,
	|	TTBookValue.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	TTBookValue.LineOfBusiness   AS LineOfBusiness,
	|
	|	MAX(TTBookValue.LocalCost)
	|		+ SUM(CASE 
	|					WHEN ISNULL(TTNegativeCostLO.LocalCost,0) > 0
	|					THEN 0 
	|					ELSE ISNULL(TTNegativeCostLO.LocalCost,0)
	|				END)
	|		AS LocalCost,
	|
	|	MAX(TTBookValue.CostMan)
	|		+ SUM(CASE 
	|					WHEN ISNULL(TTNegativeCostLO.CostMan,0) > 0
	|					THEN 0 
	|					ELSE ISNULL(TTNegativeCostLO.CostMan,0)
	|				END)
	|		AS CostMan,
	|
	|	MAX(TTBookValue.ImpairmentLocalAssets) AS ImpairmentLocalAssets,
	|	MAX(TTBookValue.ImpairmenMan)  AS ImpairmenMan,
	|
	|	MAX(TTBookValue.CostRevaluationReserve)            AS RevaluationReserveForMan,
	|	MAX(TTBookValue.CostRevaluationReserveLocal)        AS CostRevaluationReserveLocal,
	|	MAX(TTBookValue.DepreciationRevaluationReserve)          AS RevaluationReserveForManDepreciation,
	|	MAX(TTBookValue.DepreciationRevaluationReserveLocal)      AS DepreciationRevaluationReserveLocal,
	|
	|	MAX(TTBookValue.LossFromImpairmentMgmt)    AS LossFromImpairmentMgmt,
	|	MAX(TTBookValue.LossFromImpairmentLocal)   AS LossFromImpairmentLocal
	|
	|INTO TTBookCostOfCGU
	|
	|FROM
	|	TTBookValue AS TTBookValue
	|		LEFT JOIN TTLiquidationLiabilitiesNegativeCost AS LOFilter
	|		ON TTBookValue.NonCurrentAsset = LOFilter.LOComponent
	|
	|		LEFT JOIN TTLiquidationLiabilitiesNegativeCost AS TTNegativeCostLO
	|		ON TTBookValue.NonCurrentAsset = TTNegativeCostLO.NonCurrentAsset
	|		
	|WHERE
	|	LOFilter.LOComponent IS NULL
	|
	|GROUP BY
	|	TTBookValue.Organization,
	|	TTBookValue.NonCurrentAsset,
	|	TTBookValue.Department,
	|	TTBookValue.FinancialAccountingGroup,
	|	TTBookValue.LineOfBusiness 
	|
	|UNION ALL
	|
	|// Zeroing the cost of negative LO. Positive LO is unchanged.
	|SELECT
	|	TTLONegativeCost.Organization               AS Organization,
	|	TTLONegativeCost.LOComponent               AS NonCurrentAsset,
	|	TTLONegativeCost.Department             AS Department,
	|	TTLONegativeCost.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	TTLONegativeCost.LineOfBusiness   AS LineOfBusiness,
	|
	|	CASE WHEN TTLONegativeCost.LocalCost < 0
	|			THEN 0 
	|			ELSE TTLONegativeCost.LocalCost
	|			END AS LocalCost,
	|
	|	CASE WHEN TTLONegativeCost.CostMan < 0
	|			THEN 0 
	|			ELSE TTLONegativeCost.CostMan
	|			END AS CostMan,
	|
	|	TTLONegativeCost.ImpairmentLocalAssets           AS ImpairmentLocalAssets,
	|	TTLONegativeCost.ImpairmenMan            AS ImpairmenMan,
	|
	|	0 AS RevaluationReserveForMan,
	|	0 AS CostRevaluationReserveLocal,
	|	0 AS RevaluationReserveForManDepreciation,
	|	0 AS DepreciationRevaluationReserveLocal,
	|	0 AS LossFromImpairmentMgmt,
	|	0 AS LossFromImpairmentLocal
	|FROM
	|	TTLiquidationLiabilitiesNegativeCost AS TTLONegativeCost
	|
	|INDEX BY
	|	NonCurrentAsset
	|;//9
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// Liquidation cost.
	|SELECT
	|	NCAParameters.NonCurrentAsset                  AS NonCurrentAsset,
	|	SUM(NCAParameters.ResidualValueLocal) AS ResidualValueLocal,
	|	SUM(NCAParameters.LiquidationValueOfMan)  AS LiquidationValueOfMan
	|	
	|INTO TTLiquidationValue
	|
	|FROM
	|	(SELECT
	|		NCAParameters.IntangibleAsset         AS NonCurrentAsset,
	|		NCAParameters.ResidualValueLocal AS ResidualValueLocal,
	|		0                                        AS LiquidationValueOfMan
	|	FROM
	|		InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting.SliceLast(
	|				&BoundaryOfResidues,
	|				IntangibleAsset IN
	|					(SELECT
	|						T.NonCurrentAsset
	|					FROM
	|						DepreciableVNA AS T)) AS NCAParameters
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NCAParameters.IntangibleAsset     AS NonCurrentAsset,
	|		0                                    AS ResidualValueLocal,
	|		NCAParameters.ResidualValueMan AS LiquidationValueOfMan
	|	FROM
	|		InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting.SliceLast(
	|				&BoundaryOfResidues,
	|				IntangibleAsset IN
	|					(SELECT
	|						T.NonCurrentAsset
	|					FROM
	|						DepreciableVNA AS T)) AS NCAParameters
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NCAParameters.FixedAsset        AS NonCurrentAsset,
	|		NCAParameters.ResidualValueMan AS ResidualValueLocal,
	|		0                                    AS LiquidationValueOfMan
	|	FROM
	|		InformationRegister.OSBUDepreciationParameters.SliceLast(
	|				&BoundaryOfResidues,
	|				FixedAsset IN
	|					(SELECT
	|						T.NonCurrentAsset
	|					FROM
	|						DepreciableVNA AS T)) AS NCAParameters
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NCAParameters.FixedAsset        AS NonCurrentAsset,
	|		0                                    AS ResidualValueLocal,
	|		NCAParameters.ResidualValueMan AS LiquidationValueOfMan
	|	FROM
	|		InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(
	|				&BoundaryOfResidues,
	|				FixedAsset IN
	|					(SELECT
	|						T.NonCurrentAsset
	|					FROM
	|						DepreciableVNA AS T)) AS NCAParameters) AS NCAParameters
	|
	|GROUP BY
	|	NCAParameters.NonCurrentAsset
	|
	|INDEX BY
	|	NonCurrentAsset
	|;//10
	|
	|////////////////////////////////////////////////////////////////////////////////
	|//A table for calculating the impairment of HPA included in the CGU, taking into account liquidation obligations.
	|SELECT DISTINCT
	|	TTBookValue.Organization               AS Organization,
	|	TTBookValue.NonCurrentAsset         AS NonCurrentAsset,
	|	TTBookValue.Department             AS Department,
	|	TTBookValue.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	TTBookValue.LineOfBusiness   AS LineOfBusiness,
	|	TTRecoverableAmount.RecoverableAmountLocal AS RecoverableAmountLocal,
	|	TTRecoverableAmount.RecoverableAmountMan  AS RecoverableAmountMan,
	|	TTBookValue.LocalCost             AS LocalCost,
	|	TTBookValue.CostMan              AS CostMan,
	|	
	|	CASE
	|		WHEN NOT NodesOfFixedAssets.SubAssetComponent IS NULL
	|				AND ISNULL(TTLiquidationLiabilitiesNegativeCost.CostMan, 0) < 0
	|			THEN 0 // This is a component with a negative value, impairment cannot be allocated to it
	|		WHEN TTBookValue.LocalCost 
	|				- ISNULL(TTLiquidationValue.ResidualValueLocal, 0)
	|				+ ISNULL(TTLiquidationLiabilitiesNegativeCost.LocalCost, 0) > 0
	|			THEN TTBookValue.LocalCost 
	|					- ISNULL(TTLiquidationValue.ResidualValueLocal, 0)
	|					+ ISNULL(TTLiquidationLiabilitiesNegativeCost.LocalCost, 0)
	|		ELSE TTBookValue.LocalCost
	|	END AS LocalDistributionBase,
	|	
	|	CASE
	|		WHEN NOT NodesOfFixedAssets.SubAssetComponent IS NULL
	|				AND ISNULL(TTLiquidationLiabilitiesNegativeCost.CostMan, 0) < 0
	|			THEN 0 // This is a component with a negative value, impairment cannot be allocated to it
	|		WHEN TTBookValue.CostMan 
	|				- ISNULL(TTLiquidationValue.LiquidationValueOfMan, 0)
	|				+ ISNULL(TTLiquidationLiabilitiesNegativeCost.CostMan, 0) > 0
	|			THEN TTBookValue.CostMan 
	|					- ISNULL(TTLiquidationValue.LiquidationValueOfMan, 0)
	|					+ ISNULL(TTLiquidationLiabilitiesNegativeCost.CostMan, 0)
	|		ELSE TTBookValue.CostMan
	|	END AS ManDistributionBase,
	|	
	|	TTBookValue.ImpairmentLocalAssets           AS ImpairmentLocalAssets,
	|	TTBookValue.ImpairmenMan            AS ImpairmenMan,
	|
	|	TTBookValue.RevaluationReserveForMan         AS RevaluationReserveForMan,
	|	TTBookValue.CostRevaluationReserveLocal        AS CostRevaluationReserveLocal,
	|	-TTBookValue.RevaluationReserveForManDepreciation       AS RevaluationReserveForManDepreciation,
	|	-TTBookValue.DepreciationRevaluationReserveLocal      AS DepreciationRevaluationReserveLocal,
	|
	|	TTBookValue.LossFromImpairmentMgmt    AS LossFromImpairmentMgmt,
	|	TTBookValue.LossFromImpairmentLocal   AS LossFromImpairmentLocal,
	|
	|	TTRecoverableAmount.NonCurrentAsset        AS CGU
	|INTO DataOnCGU
	|
	|FROM
	|	TTRecoverableAmountOfImpairmentDocument AS TTRecoverableAmount
	|	
	|		INNER JOIN DepreciableVNA AS DepreciatedCGU
	|		ON (DepreciatedCGU.CGU = TTRecoverableAmount.NonCurrentAsset)
	|		
	|		INNER JOIN TTBookCostOfCGU AS TTBookValue
	|		ON (DepreciatedCGU.NonCurrentAsset = TTBookValue.NonCurrentAsset)
	|		
	|		LEFT JOIN TTLiquidationValue AS TTLiquidationValue
	|		ON (DepreciatedCGU.NonCurrentAsset = TTLiquidationValue.NonCurrentAsset)
	|		
	|		LEFT JOIN TTLiquidationLiabilitiesNegativeCost AS TTLiquidationLiabilitiesNegativeCost
	|		ON (TTRecoverableAmount.NonCurrentAsset = TTLiquidationLiabilitiesNegativeCost.NonCurrentAsset)
	|
	|		LEFT JOIN NodesOfFixedAssets AS NodesOfFixedAssets
	|		ON (TTRecoverableAmount.NonCurrentAsset = NodesOfFixedAssets.SubAssetComponent)
	|;//11
	|
	|SELECT
	|	DataOnCGU.Organization AS Organization,
	|	DataOnCGU.CGU        AS CGU,
	|	DataOnCGU.RecoverableAmountLocal AS RecoverableAmountLocal,
	|	DataOnCGU.RecoverableAmountMan  AS RecoverableAmountMan,
	|	SUM(DataOnCGU.LocalCost)     AS LocalCost,
	|	SUM(DataOnCGU.CostMan)     AS CostMan
	|FROM
	|	DataOnCGU AS DataOnCGU
	|GROUP BY
	|	DataOnCGU.Organization,
	|	DataOnCGU.CGU,
	|	DataOnCGU.RecoverableAmountLocal,
	|	DataOnCGU.RecoverableAmountMan
	|;//12
	|
	|SELECT
	|	DataOnCGU.Organization AS Organization,
	|	DataOnCGU.NonCurrentAsset AS NonCurrentAsset,
	|	DataOnCGU.Department AS Department,
	|	DataOnCGU.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DataOnCGU.LineOfBusiness AS LineOfBusiness,
	|	DataOnCGU.RecoverableAmountLocal AS RecoverableAmountLocal,
	|	DataOnCGU.RecoverableAmountMan AS RecoverableAmountMan,
	|	DataOnCGU.LocalCost AS LocalCost,
	|	DataOnCGU.CostMan AS CostMan,
	|	DataOnCGU.LocalDistributionBase AS LocalDistributionBase,
	|	DataOnCGU.ManDistributionBase AS ManDistributionBase,
	|	DataOnCGU.ImpairmentLocalAssets AS ImpairmentLocalAssets,
	|	DataOnCGU.ImpairmenMan AS ImpairmenMan,
	|	DataOnCGU.RevaluationReserveForMan         AS RevaluationReserveForMan,
	|	DataOnCGU.CostRevaluationReserveLocal        AS CostRevaluationReserveLocal,
	|	DataOnCGU.RevaluationReserveForManDepreciation       AS RevaluationReserveForManDepreciation,
	|	DataOnCGU.DepreciationRevaluationReserveLocal      AS DepreciationRevaluationReserveLocal,
	|	DataOnCGU.LossFromImpairmentMgmt    AS LossFromImpairmentMgmt,
	|	DataOnCGU.LossFromImpairmentLocal   AS LossFromImpairmentLocal,
	|	DataOnCGU.CGU AS CGU
	|FROM
	|	DataOnCGU AS DataOnCGU
	|//13
	|";
	
	Result = RequestToChargeRecovery.ExecuteBatch();
	
	// VNA, not included in the CGU.
	OSNMAData = Result[7].Unload(); // ValueTable - 

	For Each OSNMString In OSNMAData Do
		
		LocalAccrualAmount = 0;
		AmountOfManAccrual = 0;
		LocalRecoveryAmount = 0;
		AmountOfManRecovery = 0;
		AccrualOfImpairmentLossLocal = 0;
		AccrualOfImpairmentLossMan  = 0;
		RecoveryLocalImpairmentLoss = 0;
		RecoveryOfImpairmentLossMan  = 0;
		
		LocalReAssessmentReserve = ?(OSNMString.CostRevaluationReserveLocal - OSNMString.DepreciationRevaluationReserveLocal > 0
								And OSNMString.CostRevaluationReserveLocal > 0,
									OSNMString.CostRevaluationReserveLocal - OSNMString.DepreciationRevaluationReserveLocal, // There was an additional assessment
									0);										   // There was a markdown
									
		ReserveOfManSReEvaluation  = ?(OSNMString.RevaluationReserveForMan - OSNMString.RevaluationReserveForManDepreciation > 0
								And OSNMString.RevaluationReserveForMan > 0,
									OSNMString.RevaluationReserveForMan - OSNMString.RevaluationReserveForManDepreciation,  // There was an additional assessment
									0);										   // There was a markdown
									
		CostTakingIntoAccountPreviousImpairmentOfLocal = OSNMString.LocalCost - OSNMString.ImpairmentLocalAssets;
		CostTakingIntoAccountPreviousImpairmentOfMan = OSNMString.CostMan - OSNMString.ImpairmenMan;
		
		If OSNMString.RecoverableAmountLocal <> 0 
			And OSNMString.RecoverableAmountLocal < CostTakingIntoAccountPreviousImpairmentOfLocal Then
			// Devalue in regl.
			LocalAccrualAmount = CostTakingIntoAccountPreviousImpairmentOfLocal - OSNMString.RecoverableAmountLocal; // Total amount of impairment
			
			// The amount in the 83rd account is defined as the difference between the amount of impairment and the impairment loss,
			// but can not be greater than the reserve of revaluation.
			AccrualOfImpairmentLossLocal = ?(LocalReAssessmentReserve <= 0,
													LocalAccrualAmount, // All impairment on 91 accounts.
													?(LocalReAssessmentReserve <= LocalAccrualAmount,  // Impairment on the 83rd account:
														LocalAccrualAmount - LocalReAssessmentReserve, // Partially.
														0));										  // Completely.
												
		EndIf;
		
		If OSNMString.RecoverableAmountLocal = 0 Then
			// Full recovery.
			LocalRecoveryAmount = OSNMString.ImpairmentLocalAssets;          // Total amount of impairment
			RecoveryLocalImpairmentLoss = OSNMString.LossFromImpairmentLocal;  //The amount of impairment previously recorded on account 91.02.
			
		ElsIf OSNMString.RecoverableAmountLocal > CostTakingIntoAccountPreviousImpairmentOfLocal Then
			// We restore within the limits of the remaining depreciation of regl.
			LocalRecoveryAmount = 
				Min(OSNMString.RecoverableAmountLocal - OSNMString.LocalCost + OSNMString.ImpairmentLocalAssets, 
					OSNMString.ImpairmentLocalAssets);
					
			RecoveryLocalImpairmentLoss = ?(LocalRecoveryAmount <= OSNMString.LossFromImpairmentLocal,
											LocalRecoveryAmount,  // Recovery in the amount of previously recognized loss as of 91.01 
											OSNMString.LossFromImpairmentLocal); // There is a delta between the full amount of impairment 
											 									  // and the impairment loss equal to the amount of account 83
											
		EndIf;
		
		If OSNMString.RecoverableAmountMan <> 0
			And OSNMString.RecoverableAmountMan < CostTakingIntoAccountPreviousImpairmentOfMan Then
			// Devalue in upr.
			AmountOfManAccrual = CostTakingIntoAccountPreviousImpairmentOfMan - OSNMString.RecoverableAmountMan ;
			
			// The amount in the 83rd account is defined as the difference between the amount of impairment and the impairment loss,
			// but can not be greater than the reserve of revaluation.
			AccrualOfImpairmentLossMan = ?(ReserveOfManSReEvaluation <= 0,
													AmountOfManAccrual, // All impairment on 91 accounts.
													?(ReserveOfManSReEvaluation <= AmountOfManAccrual,  // Impairment on the 83rd account:
														AmountOfManAccrual - ReserveOfManSReEvaluation, // Partially.
														0));										// Completely.
												
		EndIf;
		
		If OSNMString.RecoverableAmountMan = 0 Then
			// Full recovery.
			AmountOfManRecovery = OSNMString.ImpairmenMan;
			RecoveryOfImpairmentLossMan = OSNMString.LossFromImpairmentMgmt;
			
		ElsIf OSNMString.RecoverableAmountMan > CostTakingIntoAccountPreviousImpairmentOfMan Then
			// We restore within the limits of the remaining depreciation of the Upr.
			AmountOfManRecovery = 
				Min(OSNMString.RecoverableAmountMan - OSNMString.CostMan + OSNMString.ImpairmenMan, 
					OSNMString.ImpairmenMan);
			
			RecoveryOfImpairmentLossMan = ?(AmountOfManRecovery <= OSNMString.LossFromImpairmentMgmt,
											AmountOfManRecovery,  // Recovery in the amount of previously recognized loss as of 91.01 
											OSNMString.LossFromImpairmentMgmt); // There is a delta between the full amount of impairment 
																				 // and the impairment loss equal to the amount of account 83
											 
		EndIf;
		
		If LocalAccrualAmount <> 0 Or AmountOfManAccrual <> 0 Then
		// Accrual.
			AccrualLine = Accruals.Add();
			FillPropertyValues(AccrualLine, OSNMString);
			AccrualLine.ImpairmentLocalAssets = LocalAccrualAmount;
			AccrualLine.ImpairmenMan = AmountOfManAccrual;
			AccrualLine.LossFromImpairmentLocal = AccrualOfImpairmentLossLocal;
			AccrualLine.LossFromImpairmentMgmt  = AccrualOfImpairmentLossMan;
		
		// Change in the cost reserve for Cost and depreciation registers.
			If OSNMString.RevaluationReserveForMan > 0 Then
				ImpairmentForCalculationOfRevaluationReserveMan = Min(AccrualLine.ImpairmenMan, ReserveOfManSReEvaluation);
				
				AccrualLine.ChangeInCostReserve = 
								Round(ImpairmentForCalculationOfRevaluationReserveMan / 
										(1 - OSNMString.RevaluationReserveForManDepreciation / 
												OSNMString.RevaluationReserveForMan), 
									2);

				AccrualLine.ChangeInDepreciationReserve = 
									ImpairmentForCalculationOfRevaluationReserveMan
									- AccrualLine.ChangeInCostReserve;
			EndIf;

			If OSNMString.CostRevaluationReserveLocal > 0 Then
				ImpairmentForCalculationOfRevaluationReserveLocal = Min(AccrualLine.ImpairmentLocalAssets, LocalReAssessmentReserve);
				
				AccrualLine.ChangeInReserveOfCostOfLocal = 
								Round(ImpairmentForCalculationOfRevaluationReserveLocal / 
										(1 - OSNMString.DepreciationRevaluationReserveLocal / 
												OSNMString.CostRevaluationReserveLocal), 
								2);

				AccrualLine.ChangeInDepreciationReserveLocal = 
									ImpairmentForCalculationOfRevaluationReserveLocal
									- AccrualLine.ChangeInReserveOfCostOfLocal;
			EndIf;
		EndIf;
		
		If LocalRecoveryAmount <> 0 Or AmountOfManRecovery <> 0 Then
			// Recovery.
			RecoveryString = Recovery.Add();
			FillPropertyValues(RecoveryString, OSNMString);
			RecoveryString.ImpairmentLocalAssets = LocalRecoveryAmount;
			RecoveryString.ImpairmenMan = AmountOfManRecovery;
			RecoveryString.LossFromImpairmentLocal = RecoveryLocalImpairmentLoss;
			RecoveryString.LossFromImpairmentMgmt  = RecoveryOfImpairmentLossMan;
			
			// Change in the cost reserve for Cost and depreciation registers. 
			// The entire amount of impairment goes to the Cost.
			RecoveryString.ChangeInCostReserve = Max(AmountOfManRecovery - RecoveryOfImpairmentLossMan, 0);
			RecoveryString.ChangeInDepreciationReserve = 0;
			RecoveryString.ChangeInReserveOfCostOfLocal = Max(LocalRecoveryAmount - RecoveryLocalImpairmentLoss, 0);
			RecoveryString.ChangeInDepreciationReserveLocal = 0;
		EndIf;
		
	EndDo;
	
	// VNA, included in the CGU.
	DataOnCGU = Result[13].Unload(); // ValueTable - 
	
	// For companies with branch offices, it is required to distribute the total amount of impairment between the branch offices, 
	// and already within the branch offices to distribute the impairment by assets.
	
	DataByBranches = Result[12].Unload(); // ValueTable -
	ListOfCGU = DataByBranches.Copy(,"CGU");
	ListOfCGU.GroupBy("CGU","");
	
	CGUTable = DataOnCGU.Copy(, "Organization, CGU, RecoverableAmountLocal, RecoverableAmountMan, LocalCost, CostMan");
	CGUTable.Clear();
	
	For Each CGUListLine In ListOfCGU Do
		
		ToDistributionByCGU = DataByBranches.Copy(New Structure("CGU", CGUListLine.CGU));
		
		DistributedReimbursableNetInitialCostLocal = TMCommonUseClientServer.DistributeProportionally(
													ToDistributionByCGU.Get(0).RecoverableAmountLocal,
													ToDistributionByCGU.UnloadColumn("LocalCost"));
													
		DistributedRecoverableNetInitialCostCo = TMCommonUseClientServer.DistributeProportionally(
													ToDistributionByCGU.Get(0).RecoverableAmountMan,
													ToDistributionByCGU.UnloadColumn("CostMan"));
		
		If DistributedReimbursableNetInitialCostLocal <> Undefined Then 
			ToDistributionByCGU.LoadColumn(DistributedReimbursableNetInitialCostLocal, "RecoverableAmountLocal");
		EndIf;
		If DistributedRecoverableNetInitialCostCo <> Undefined Then
			ToDistributionByCGU.LoadColumn(DistributedRecoverableNetInitialCostCo, "RecoverableAmountMan");
		EndIf;
		
		CommonClientServer.SupplementTable(ToDistributionByCGU, CGUTable);
	EndDo;
	
	For Each CGULine In CGUTable Do
		
		FilterStructure1 = New Structure("CGU, Organization", CGULine.CGU, CGULine.Organization);
		LinesInTable = DataOnCGU.FindRows(FilterStructure1);
		CGUImpairmentTable = DataOnCGU.Copy(LinesInTable,); // by company.
		
		LocalCost = CGUImpairmentTable.Total("LocalCost");
		CostMan = CGUImpairmentTable.Total("CostMan");
		
		// We re-calculate the new amount of depreciation of the CGU, distribute it to the HPA and 
		// charge / restore it for each HPA, depending on whether the amount has decreased or increased.
		If CGULine.RecoverableAmountLocal <> 0 
			And CGULine.RecoverableAmountLocal < LocalCost Then
			AmountOfLocalPropertyImpairment = LocalCost - CGULine.RecoverableAmountLocal;
		Else
			AmountOfLocalPropertyImpairment = 0;
		EndIf;
		
		If CGULine.RecoverableAmountMan <> 0
			And CGULine.RecoverableAmountMan < CostMan Then
			AmountOfManImpairment = CostMan - CGULine.RecoverableAmountMan;
		Else
			AmountOfManImpairment = 0;
		EndIf;
		
		// Tables of impairment allocated to the HPA in proportion to the book cost
		// , taking into account liquidation obligations.
		LocalFees = TMCommonUseClientServer.DistributeProportionally(
			AmountOfLocalPropertyImpairment,
			CGUImpairmentTable.UnloadColumn("LocalDistributionBase"));
		ManCharges = TMCommonUseClientServer.DistributeProportionally(
			AmountOfManImpairment,
			CGUImpairmentTable.UnloadColumn("ManDistributionBase"));
			
		For Each LineBNA In CGUImpairmentTable Do
			IndexOf = CGUImpairmentTable.IndexOf(LineBNA);
			
			LocalReAssessmentReserve = ?(LineBNA.CostRevaluationReserveLocal - LineBNA.DepreciationRevaluationReserveLocal > 0
									And LineBNA.CostRevaluationReserveLocal > 0,
									LineBNA.CostRevaluationReserveLocal - LineBNA.DepreciationRevaluationReserveLocal,
									0);
			ReserveOfManSReEvaluation  = ?(LineBNA.RevaluationReserveForMan - LineBNA.RevaluationReserveForManDepreciation > 0
									And LineBNA.RevaluationReserveForMan > 0,
									LineBNA.RevaluationReserveForMan - LineBNA.RevaluationReserveForManDepreciation,
									0);
			
			If LocalFees <> Undefined Then
				If LocalFees[IndexOf] > LineBNA.ImpairmentLocalAssets Then //we charge
					AccrualLine = Accruals.Add();
					FillPropertyValues(AccrualLine, LineBNA);
					AccrualLine.ImpairmentLocalAssets = LocalFees[IndexOf] - LineBNA.ImpairmentLocalAssets;
					
					// The amount in the 83rd account is defined as the difference between the amount of impairment and the impairment loss,
					// but can not be greater than the reserve of revaluation.
					AccrualLine.LossFromImpairmentLocal = ?(LocalReAssessmentReserve <= 0,
													AccrualLine.ImpairmentLocalAssets, // All impairment on 91 accounts.
													?(LocalReAssessmentReserve <= AccrualLine.ImpairmentLocalAssets,  // Impairment on the 83rd account:
														AccrualLine.ImpairmentLocalAssets - LocalReAssessmentReserve, // Partially.
														0));										// Completely.
												
					AccrualLine.ImpairmenMan = 0;
					AccrualLine.LossFromImpairmentMgmt = 0;

					// Change in the cost reserve for Cost and depreciation registers.
					AccrualLine.ChangeInCostReserve = 0;
					AccrualLine.ChangeInDepreciationReserve = 0;
					
					If LineBNA.CostRevaluationReserveLocal > 0 Then
						ImpairmentForCalculationOfRevaluationReserveLocal = Min(AccrualLine.ImpairmentLocalAssets, LocalReAssessmentReserve);
						
						AccrualLine.ChangeInReserveOfCostOfLocal = Round(ImpairmentForCalculationOfRevaluationReserveLocal 
																				/ (1 - LineBNA.DepreciationRevaluationReserveLocal 
																						/ LineBNA.CostRevaluationReserveLocal),
																			2);
																	
						AccrualLine.ChangeInDepreciationReserveLocal = 
											ImpairmentForCalculationOfRevaluationReserveLocal
											- AccrualLine.ChangeInReserveOfCostOfLocal;
					EndIf;
					
		
				ElsIf LineBNA.ImpairmentLocalAssets > LocalFees[IndexOf] Then //restoring
					RecoveryString = Recovery.Add();
					FillPropertyValues(RecoveryString, LineBNA);
					RecoveryString.ImpairmentLocalAssets = LineBNA.ImpairmentLocalAssets - LocalFees[IndexOf];
					
					LocalRecoveryAmount = Min(LocalFees[IndexOf] - LineBNA.LocalDistributionBase + LineBNA.ImpairmentLocalAssets, 
													LineBNA.ImpairmentLocalAssets);
	
					RecoveryString.LossFromImpairmentLocal = ?(LocalRecoveryAmount <= LineBNA.LossFromImpairmentLocal,
											LocalRecoveryAmount,  // Recovery in the amount of previously recognized loss as of 91.01 
											LineBNA.LossFromImpairmentLocal); // There is a delta between the full amount of impairment 
																				// and the impairment loss equal to the amount of account 83
											 
					RecoveryString.ImpairmenMan = 0;
					RecoveryString.LossFromImpairmentMgmt = 0;
					// Change in the cost reserve for Cost and depreciation registers. 
					// The entire amount goes to the Cost.
					RecoveryString.ChangeInCostReserve = 0;
					RecoveryString.ChangeInDepreciationReserve = 0;
					RecoveryString.ChangeInReserveOfCostOfLocal = Max(LocalRecoveryAmount - RecoveryString.LossFromImpairmentLocal, 0);
					RecoveryString.ChangeInDepreciationReserveLocal = 0;
					
				EndIf;
			Else
				If LineBNA.ImpairmentLocalAssets > 0 Then //restoring it completely
					RecoveryString = Recovery.Add();
					FillPropertyValues(RecoveryString, LineBNA);
					RecoveryString.ImpairmentLocalAssets = LineBNA.ImpairmentLocalAssets;
					RecoveryString.LossFromImpairmentLocal = LineBNA.LossFromImpairmentLocal;
					
					RecoveryString.ImpairmenMan = 0;
					RecoveryString.LossFromImpairmentMgmt = 0;
					
					// Change in the cost reserve for Cost and depreciation registers. 
					// The entire amount goes to the Cost.
					RecoveryString.ChangeInCostReserve = 0;
					RecoveryString.ChangeInDepreciationReserve = 0;
					RecoveryString.ChangeInReserveOfCostOfLocal = Max(LocalRecoveryAmount - RecoveryString.LossFromImpairmentLocal, 0);
					RecoveryString.ChangeInDepreciationReserveLocal = 0;
					
				EndIf;
			EndIf;
			
			If ManCharges <> Undefined Then
				If ManCharges[IndexOf] > LineBNA.ImpairmenMan Then //We charge.
					AccrualLine = Accruals.Add();
					FillPropertyValues(AccrualLine, LineBNA);
					AccrualLine.ImpairmenMan = ManCharges[IndexOf] - LineBNA.ImpairmenMan;
					
					AccrualLine.LossFromImpairmentMgmt = ?(ReserveOfManSReEvaluation >= AccrualLine.ImpairmenMan,
											0,
											AccrualLine.ImpairmenMan - ReserveOfManSReEvaluation); //The amount of impairment recorded on account 91.02.
					// The amount in the 83rd account is defined as the difference between the amount of impairment and the impairment loss,
					// but can not be greater than the reserve of revaluation.
					AccrualLine.LossFromImpairmentMgmt = ?(ReserveOfManSReEvaluation <= 0,
													AccrualLine.ImpairmenMan, // All impairment on 91 accounts.
													?(ReserveOfManSReEvaluation <= AccrualLine.ImpairmenMan,  // Impairment on the 83rd account:
														AccrualLine.ImpairmenMan - ReserveOfManSReEvaluation, // Partially.
														0));										 		 // Completely.
												
					AccrualLine.ImpairmentLocalAssets = 0;
					AccrualLine.LossFromImpairmentLocal = 0;
					
					// Change in the cost reserve for Cost and depreciation registers.
					If LineBNA.RevaluationReserveForMan > 0 Then
						ImpairmentForCalculationOfRevaluationReserveMan = Min(AccrualLine.ImpairmenMan, ReserveOfManSReEvaluation);
						
						AccrualLine.ChangeInCostReserve = Round(ImpairmentForCalculationOfRevaluationReserveMan 
																			/ (1 - LineBNA.RevaluationReserveForManDepreciation 
																					/ LineBNA.RevaluationReserveForMan),
																		2);
																	
						AccrualLine.ChangeInDepreciationReserve = 
														ImpairmentForCalculationOfRevaluationReserveMan
														- AccrualLine.ChangeInCostReserve;
					EndIf;

					AccrualLine.ChangeInReserveOfCostOfLocal = 0;
					AccrualLine.ChangeInDepreciationReserveLocal = 0;
					
				ElsIf LineBNA.ImpairmenMan > ManCharges[IndexOf] Then //Restoring.
					RecoveryString = Recovery.Add();
					FillPropertyValues(RecoveryString, LineBNA);
					RecoveryString.ImpairmenMan = LineBNA.ImpairmenMan - ManCharges[IndexOf];
					
					AmountOfManRecovery = Min(ManCharges[IndexOf] - LineBNA.ManDistributionBase + LineBNA.ImpairmenMan, 
													LineBNA.ImpairmenMan);
	
					RecoveryString.LossFromImpairmentMgmt = ?(AmountOfManRecovery <= LineBNA.LossFromImpairmentMgmt,
											AmountOfManRecovery,  // Recovery in the amount of previously recognized loss as of 91.01 
											LineBNA.LossFromImpairmentMgmt); // There is a delta between the full amount of impairment 
																			   // and the impairment loss equal to the amount of account 83
											 	
					RecoveryString.ImpairmentLocalAssets = 0;
					RecoveryString.LossFromImpairmentLocal = 0;
					
					// Change in the cost reserve for Cost and depreciation registers. 
					// The entire amount goes to the Cost.
					RecoveryString.ChangeInCostReserve = Max(AmountOfManRecovery - RecoveryString.LossFromImpairmentMgmt, 0);
					RecoveryString.ChangeInDepreciationReserve = 0;
					RecoveryString.ChangeInReserveOfCostOfLocal = 0;
					RecoveryString.ChangeInDepreciationReserveLocal = 0;
					
				EndIf;
			Else
				If LineBNA.ImpairmenMan > 0 Then // We restore it completely.
					RecoveryString = Recovery.Add();
					FillPropertyValues(RecoveryString, LineBNA);
					RecoveryString.ImpairmenMan = LineBNA.ImpairmenMan;
					RecoveryString.LossFromImpairmentMgmt = LineBNA.LossFromImpairmentMgmt;
					
					RecoveryString.ImpairmentLocalAssets = 0;
					RecoveryString.LossFromImpairmentLocal = 0;
					
					// Change in the cost reserve for Cost and depreciation registers. 
					// The entire amount goes to the Cost.
					RecoveryString.ChangeInCostReserve = Max(AmountOfManRecovery - RecoveryString.LossFromImpairmentMgmt, 0);
					RecoveryString.ChangeInDepreciationReserve = 0;
					RecoveryString.ChangeInReserveOfCostOfLocal = 0;
					RecoveryString.ChangeInDepreciationReserveLocal = 0;
					
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	// Let's collapse the Accrual and Recovery tables.
	ArrayOfGroupingColumns = New Array;
	ArrayOfSummationColumns = New Array;
	For Each Column In Accruals.Columns Do
		If StrOccurrenceCount(Column.Name, "Impairment") = 0
				And StrOccurrenceCount(Column.Name, "LossImpairment") = 0
				And StrOccurrenceCount(Column.Name, "ReserveFactor") = 0
				And StrOccurrenceCount(Column.Name, "ChangeInReserve") = 0 Then
			ArrayOfGroupingColumns.Add(Column.Name);
		Else
			ArrayOfSummationColumns.Add(Column.Name);
		EndIf;
	EndDo;
	
	GroupingColumns  = StrConcat(ArrayOfGroupingColumns , ",");
	TotalingColumns = StrConcat(ArrayOfSummationColumns, ",");

	Accruals.GroupBy(GroupingColumns,TotalingColumns);
	Recovery.GroupBy(GroupingColumns,TotalingColumns);

	TMCommonUse.AddRowIDToTable(Accruals, "FinRecordID", "String");
	TMCommonUse.AddRowIDToTable(Recovery, "FinRecordID", "String");
	
	RequestToChargeRecovery.SetParameter("Accruals", Accruals);
	RequestToChargeRecovery.SetParameter("Recovery", Recovery);
	
	RequestToChargeRecovery.Text =
	"
	|SELECT
	|	Accruals.FinRecordID AS FinRecordID,
	|	Accruals.Organization AS Organization,
	|	Accruals.NonCurrentAsset AS NonCurrentAsset,
	|	Accruals.Department AS Department,
	|	Accruals.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Accruals.LineOfBusiness AS LineOfBusiness,
	|	Accruals.CGU AS CGU,
	|	Accruals.ImpairmentLocalAssets AS ImpairmentLocalAssets,
	|	Accruals.ImpairmenMan AS ImpairmenMan,
	|	Accruals.LossFromImpairmentLocal AS LossFromImpairmentLocal,
	|	Accruals.LossFromImpairmentMgmt AS LossFromImpairmentMgmt,
	|	Accruals.ChangeInCostReserve AS ChangeInReserveOfCostOfMan,
	|	-Accruals.ChangeInDepreciationReserve AS ChangeInDepreciationReserveMan,
	|	Accruals.ChangeInReserveOfCostOfLocal AS ChangeInReserveOfCostOfLocal,
	|	-Accruals.ChangeInDepreciationReserveLocal AS ChangeInDepreciationReserveLocal
	|INTO TTAccruals
	|FROM
	|	&Accruals AS Accruals
	|WHERE
	|	Accruals.ImpairmentLocalAssets <> 0
	|	OR Accruals.ImpairmenMan <> 0
	|INDEX BY
	|	Organization,
	|	NonCurrentAsset
	|;
	|SELECT
	|	Recovery.FinRecordID AS FinRecordID,
	|	Recovery.Organization AS Organization,
	|	Recovery.NonCurrentAsset AS NonCurrentAsset,
	|	Recovery.Department AS Department,
	|	Recovery.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Recovery.LineOfBusiness AS LineOfBusiness,
	|	Recovery.CGU AS CGU,
	|	Recovery.ImpairmentLocalAssets AS ImpairmentLocalAssets,
	|	Recovery.ImpairmenMan AS ImpairmenMan,
	|	Recovery.LossFromImpairmentLocal AS LossFromImpairmentLocal,
	|	Recovery.LossFromImpairmentMgmt AS LossFromImpairmentMgmt,
	|	Recovery.ChangeInCostReserve AS ChangeInReserveOfCostOfMan,
	|	-Recovery.ChangeInDepreciationReserve AS ChangeInDepreciationReserveMan,
	|	Recovery.ChangeInReserveOfCostOfLocal AS ChangeInReserveOfCostOfLocal,
	|	-Recovery.ChangeInDepreciationReserveLocal AS ChangeInDepreciationReserveLocal
	|INTO TTRecovery
	|FROM
	|	&Recovery AS Recovery
	|WHERE
	|	Recovery.ImpairmentLocalAssets <> 0
	|	OR Recovery.ImpairmenMan <> 0
	|INDEX BY
	|	Organization,
	|	NonCurrentAsset
	|";
	RequestToChargeRecovery.Execute();
	
	Query.SetParameter("TTAccrualRecoveryInitialized", True);
	
EndProcedure

Procedure QueryTextTTNewAnalyticsVNA(QueryTexts)

	TableName = "TTNewAnalyticsVNA";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	FATable.NonCurrentAsset                 AS NonCurrentAsset,
	|	AccountingProcedure.FinancialAccountingGroup         AS FinancialAccountingGroup,
	|	AccountingProcedure.LineOfBusiness        AS LineOfBusiness,
	|	FALocation.Organization               AS Organization,
	|	FALocation.Organization.ParentCompany AS ParentCompany,
	|	FALocation.FixedAssetsLocation           AS Department,
	|	ISNULL(InitialInformation.CommissioningDateAC, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1) AS RecordInLocalAccounting,
	|	ISNULL(InitialInformation.CommissioningDateMA, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1) AS RecordInManAccounting
	|	
	|INTO TTNewAnalyticsVNA
	|FROM
	|	VNAObjects AS FATable
	|		LEFT JOIN InformationRegister.InitialFixedAssetsInformation.SliceLast(
	|			&BoundaryOfAnalytics,
	|			Organization = &Organization
	|				AND FixedAsset IN
	|					(SELECT
	|						ListOfFA.NonCurrentAsset
	|					FROM
	|						VNAObjects AS ListOfFA
	|					WHERE
	|						ListOfFA.Ref = &Ref)
	|		) AS InitialInformation
	|		ON FATable.NonCurrentAsset = InitialInformation.FixedAsset
	|
	|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
	|			&BoundaryOfAnalytics,
	|			FixedAsset IN
	|					(SELECT
	|						ListOfFA.NonCurrentAsset
	|					FROM
	|						VNAObjects AS ListOfFA
	|					WHERE
	|						ListOfFA.Ref = &Ref)
	|		) AS AccountingProcedure
	|		ON FATable.NonCurrentAsset = AccountingProcedure.FixedAsset
	|
	|		LEFT JOIN InformationRegister.FALocation.SliceLast(
	|			&BoundaryOfAnalytics,
	|			FixedAsset IN
	|					(SELECT
	|						ListOfFA.NonCurrentAsset
	|					FROM
	|						VNAObjects AS ListOfFA
	|					WHERE
	|						ListOfFA.Ref = &Ref)
	|		) AS FALocation
	|		ON FATable.NonCurrentAsset = FALocation.FixedAsset
	|WHERE
	|	FATable.Ref = &Ref
	|	AND NOT FALocation.Organization IS NULL
	|	
	|UNION ALL
	|	
	|SELECT DISTINCT
	|	TableOfIA.NonCurrentAsset                AS IntangibleAsset,
	|	AccountingProcedure.FinancialAccountingGroup         AS FinancialAccountingGroup,
	|	AccountingProcedure.LineOfBusiness        AS LineOfBusiness,
	|	PlaceOfRegistration.Organization                      AS Organization,
	|	PlaceOfRegistration.Organization.ParentCompany  AS ParentCompany,
	|	PlaceOfRegistration.Department                    AS Department,
	|	ISNULL(InitialInformation.DateOfRecognitionAccounting, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1) AS RecordInLocalAccounting,
	|	ISNULL(InitialInformation.DateOfRecognitionManagementAccounting, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1) AS RecordInManAccounting
	|	
	|FROM
	|	VNAObjects AS TableOfIA
	|		LEFT JOIN InformationRegister.InitialIntangibleAssetsInformation.SliceLast(
	|				&BoundaryOfAnalytics,
	|				Organization = &Organization
	|				AND IntangibleAsset IN
	|					(SELECT
	|						ListOfIA.NonCurrentAsset
	|					FROM
	|						VNAObjects AS ListOfIA
	|					WHERE
	|						ListOfIA.Ref = &Ref)
	|		) AS InitialInformation
	|		ON TableOfIA.NonCurrentAsset = InitialInformation.IntangibleAsset
	|
	|		LEFT JOIN InformationRegister.IntangibleAssetsAccountingProcedure.SliceLast(
	|				&BoundaryOfAnalytics,
	|				Organization = &Organization
	|				AND IntangibleAsset IN
	|					(SELECT
	|						ListOfIA.NonCurrentAsset
	|					FROM
	|						VNAObjects AS ListOfIA
	|					WHERE
	|						ListOfIA.Ref = &Ref)
	|		) AS AccountingProcedure
	|		ON TableOfIA.NonCurrentAsset = AccountingProcedure.IntangibleAsset
	|
	|		LEFT JOIN InformationRegister.IntangibleAssetsRegistrationPlace.SliceLast(
	|				&BoundaryOfAnalytics,
	|				Organization = &Organization
	|				AND IntangibleAsset IN
	|					(SELECT
	|						ListOfIA.NonCurrentAsset
	|					FROM
	|						VNAObjects AS ListOfIA
	|					WHERE
	|						ListOfIA.Ref = &Ref)
	|		) AS PlaceOfRegistration
	|		ON TableOfIA.NonCurrentAsset = PlaceOfRegistration.IntangibleAsset
	|WHERE
	|	TableOfIA.Ref = &Ref
	|	AND NOT PlaceOfRegistration.Organization IS NULL
	|
	|INDEX BY
	|	NonCurrentAsset
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTTNewCGU(QueryTexts)

		TableName = "TTNewCGU";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	CGUCompositionSliceLast.Organization       AS Organization,
	|	CGUCompositionSliceLast.NonCurrentAsset AS NonCurrentAsset,
	|	CGUCompositionSliceLast.CGU              AS CGU
	|INTO TTNewCGU
	|FROM
	|	InformationRegister.CGUComposition.SliceLast(
	|			&BoundaryOfAnalytics,
	|				NonCurrentAsset IN
	|					(SELECT
	|						ListOfFA.NonCurrentAsset
	|					FROM
	|						VNAObjects AS ListOfFA
	|					WHERE
	|						ListOfFA.Ref = &Ref)
	|		) AS CGUCompositionSliceLast 
	|
	|INDEX BY
	|	Organization,
	|	NonCurrentAsset,
	|	CGU
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTTOldCGU(QueryTexts)

	TableName = "TTOldCGU";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	CGUCompositionSliceLast.NonCurrentAsset AS NonCurrentAsset,
	|	CGUCompositionSliceLast.CGU
	|INTO TTOldCGU
	|FROM
	|	InformationRegister.CGUComposition.SliceLast(
	|			&DocumentBorder,
	|			Organization = &Organization
	|				AND NonCurrentAsset IN
	|					(SELECT
	|						ListOfFA.NonCurrentAsset
	|					FROM
	|						VNAObjects AS ListOfFA
	|					WHERE
	|						ListOfFA.Ref = &Ref)
	|		) AS CGUCompositionSliceLast
	|
	|INDEX BY
	|	NonCurrentAsset,
	|	CGU
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTTReflectionOfIncomeExpenses(QueryTexts)

	TableName = "TTReflectionOfIncomeExpenses";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	RecentDocuments.NonCurrentAsset AS NonCurrentAsset,
	|	MAX(ImpairmentFA.ExpenseItem) AS ExpenseItem,
	|	MAX(ImpairmentFA.DimensionOfExpenses) AS DimensionOfExpenses,
	|	MAX(ImpairmentFA.IncomeItem) AS IncomeItem,
	|	MAX(ImpairmentFA.DimensionOfRevenue) AS DimensionOfRevenue
	|INTO TTReflectionOfIncomeExpenses
	|FROM
	|	(SELECT
	|		ImpairmentDocuments.NonCurrentAsset,
	|		MAX(ImpairmentDocuments.Date) AS Date
	|	FROM
	|		(SELECT
	|			ImpairmentFA.Ref.Date AS Date,
	|			Table.NonCurrentAsset AS NonCurrentAsset,
	|			ImpairmentFA.Ref AS Document
	|		FROM
	|			VNAObjects AS Table
	|				LEFT JOIN TTOldCGU AS TTOldCGU
	|				ON TTOldCGU.NonCurrentAsset = Table.NonCurrentAsset
	|				LEFT JOIN Document.ImpairmentFA.CashGeneratingUnits AS ImpairmentFA
	|				ON ImpairmentFA.CGU = TTOldCGU.CGU
	|				AND ImpairmentFA.Ref.Organization = Table.Organization
	|				AND ImpairmentFA.Ref.Posted
	|				AND ImpairmentFA.Ref.Date <= &Period
	|
	|		UNION ALL
	|
	|		SELECT
	|			ImpairmentFA.Ref.Date AS Date,
	|			Table.NonCurrentAsset AS NonCurrentAsset,
	|			ImpairmentFA.Ref AS Document
	|		FROM
	|			VNAObjects AS Table
	|				LEFT JOIN Document.ImpairmentFA.FixedAssets AS ImpairmentFA
	|				ON ImpairmentFA.FixedAsset = Table.NonCurrentAsset
	|				AND ImpairmentFA.Ref.Organization = Table.Organization
	|				AND ImpairmentFA.Ref.Posted
	|				AND ImpairmentFA.Ref.Date <= &Period
	|
	|		UNION ALL
	|
	|		SELECT DISTINCT
	|			ImpairmentFA.Ref.Date AS Date,
	|			Table.NonCurrentAsset AS NonCurrentAsset,
	|			ImpairmentFA.Ref AS Document
	|		FROM
	|			VNAObjects AS Table
	|				LEFT JOIN Document.ImpairmentFA.IntangibleAssets AS ImpairmentFA
	|				ON ImpairmentFA.IntangibleAsset = Table.NonCurrentAsset
	|				AND ImpairmentFA.Ref.Organization = Table.Organization
	|				AND ImpairmentFA.Ref.Posted
	|				AND ImpairmentFA.Ref.Date <= &Period) AS ImpairmentDocuments
	|	GROUP BY
	|		ImpairmentDocuments.NonCurrentAsset) AS RecentDocuments
	|
	|		LEFT JOIN Document.ImpairmentFA AS ImpairmentFA
	|		ON ImpairmentFA.Date = RecentDocuments.Date
	|
	|GROUP BY
	|	RecentDocuments.NonCurrentAsset
	|
	|INDEX BY
	|	NonCurrentAsset
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

// The Query Text of the VNA impairment.
// 
// Parameters:
//  Query - Query
//  QueryTexts - ValueList of String - Request texts
Procedure QueryTextImpairmentFA(Query, QueryTexts)
	
	RegisterName = "ImpairmentFA";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	InitializeTTBalancesForReclassification(Query, QueryTexts);
	InitializeTTBalancesForRecovery(Query, QueryTexts);
	InitializeTTAccrualRecovery(Query, QueryTexts);

	QueryText = 
	"// Reclassification of analytics. 
	|// Moving the OS/IA, changing the parameters of the OS/IA accounting.
	|// Recovery of impairment based on the old set of analytics.
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
	|	TTImpairmentBalances.NonCurrentAsset       AS NonCurrentAsset,
	|	TTImpairmentBalances.CGU                    AS CGU,
	|	TTImpairmentBalances.Organization             AS Organization,
	|	TTImpairmentBalances.Department           AS Department,
	|	TTImpairmentBalances.LineOfBusiness AS LineOfBusiness,
	|	TTImpairmentBalances.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	TTImpairmentBalances.ImpairmentLocalAssets         AS ImpairmentLocalAssets,
	|	TTImpairmentBalances.ImpairmenMan          AS ImpairmenMan,
	|	TTImpairmentBalances.LossFromImpairmentLocal AS LossFromImpairmentLocal,
	|	TTImpairmentBalances.LossFromImpairmentMgmt  AS LossFromImpairmentMgmt,
	|
	|	CASE
	|		WHEN TTImpairmentBalances.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfFA)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfIA)
	|	END AS BusinessTransactionSetting,
	|
	|	TTImpairmentBalances.FinRecordID   AS FinRecordID,
	|	1 AS ID // Reclassification of impairment analytics, an old set of measurements
	|FROM
	|	TTBalancesForReclassification AS TTImpairmentBalances
	|		LEFT JOIN TTNewAnalyticsVNA AS TTNewAnalyticsVNA
	|		ON TTNewAnalyticsVNA.NonCurrentAsset = TTImpairmentBalances.NonCurrentAsset 
	|
	|WHERE
	|	(TTNewAnalyticsVNA.FinancialAccountingGroup <> TTImpairmentBalances.FinancialAccountingGroup
	|	OR TTNewAnalyticsVNA.LineOfBusiness <> TTImpairmentBalances.LineOfBusiness
	|	OR TTNewAnalyticsVNA.Department <> TTImpairmentBalances.Department
	|	
	|	// Full match of analytics, movement within the organization with branches.
	|	OR (TTImpairmentBalances.ParentCompany = TTNewAnalyticsVNA.ParentCompany
	|			AND TTImpairmentBalances.Organization <> TTNewAnalyticsVNA.Organization) 
	|)
	|	AND (TTNewAnalyticsVNA.RecordInLocalAccounting
	|	OR TTNewAnalyticsVNA.RecordInManAccounting)
	|
	|UNION ALL
	|
	|// Reclassification of analytics. 
	|// Moving the OS/IA, changing the parameters of the OS/IA accounting.
	|// Accrual of impairment for a new set of analytics.
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TTImpairmentBalances.NonCurrentAsset,
	|	ISNULL(TTNewCGU.CGU, VALUE(Catalog.CashGeneratingUnits.EmptyRef)) AS CGU,
	|	TTNewAnalyticsVNA.Organization,  // When moving to another organization, the recipient organization
	|	TTNewAnalyticsVNA.Department,
	|	TTNewAnalyticsVNA.LineOfBusiness,
	|	TTNewAnalyticsVNA.FinancialAccountingGroup,
	|	TTImpairmentBalances.ImpairmentLocalAssets,
	|	TTImpairmentBalances.ImpairmenMan,
	|	TTImpairmentBalances.LossFromImpairmentLocal AS LossFromImpairmentLocal,
	|	TTImpairmentBalances.LossFromImpairmentMgmt  AS LossFromImpairmentMgmt,
	|	CASE
	|		WHEN TTImpairmentBalances.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfFA)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfIA)
	|	END AS BusinessTransactionSetting,
	|	TTImpairmentBalances.FinRecordID,
	|	2 AS ID // Reclassification of impairment analytics, a new set of measurements
	|FROM
	|	TTBalancesForReclassification AS TTImpairmentBalances
	|		LEFT JOIN TTNewAnalyticsVNA AS TTNewAnalyticsVNA
	|		ON TTNewAnalyticsVNA.NonCurrentAsset = TTImpairmentBalances.NonCurrentAsset 
	|	
	|		LEFT JOIN TTNewCGU AS TTNewCGU
	|		ON TTNewCGU.NonCurrentAsset = TTNewAnalyticsVNA.NonCurrentAsset
	|			AND TTNewCGU.Organization = TTNewAnalyticsVNA.Organization
	|WHERE
	|	(TTNewAnalyticsVNA.FinancialAccountingGroup <> TTImpairmentBalances.FinancialAccountingGroup
	|	OR TTNewAnalyticsVNA.LineOfBusiness <> TTImpairmentBalances.LineOfBusiness
	|	OR TTNewAnalyticsVNA.Department <> TTImpairmentBalances.Department
	|	
	|	// Full match of analytics, movement within the organization with branches.
	|	OR (TTImpairmentBalances.ParentCompany = TTNewAnalyticsVNA.ParentCompany
	|			AND TTImpairmentBalances.Organization <> TTNewAnalyticsVNA.Organization) 
	|)
	|	AND (TTNewAnalyticsVNA.RecordInLocalAccounting
	|	OR TTNewAnalyticsVNA.RecordInManAccounting) 
	|
	|UNION ALL
	|
	|// Restoration upon retirement from the EGDS.
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TTImpairmentBalances.NonCurrentAsset,
	|	TTImpairmentBalances.CGU,
	|	TTImpairmentBalances.Organization,
	|	TTImpairmentBalances.Department,
	|	TTImpairmentBalances.LineOfBusiness,
	|	TTImpairmentBalances.FinancialAccountingGroup,
	|	TTImpairmentBalances.ImpairmentLocalAssets,
	|	TTImpairmentBalances.ImpairmenMan,
	|	TTImpairmentBalances.LossFromImpairmentLocal AS LossFromImpairmentLocal,
	|	TTImpairmentBalances.LossFromImpairmentMgmt  AS LossFromImpairmentMgmt,
	|	CASE
	|		WHEN TTImpairmentBalances.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversalOfFAImpairment)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReversalOfIAImpairment)
	|	END AS BusinessTransactionSetting,
	|	TTImpairmentBalances.FinRecordID,
	|	3 AS ID // Restoration upon retirement from the EGDS
	|FROM
	|	TTResiduesToRecover AS TTImpairmentBalances
	|		INNER JOIN TTNewCGU AS TTNewCGU
	|		ON TTNewCGU.NonCurrentAsset = TTImpairmentBalances.NonCurrentAsset
	|			AND TTNewCGU.CGU = TTImpairmentBalances.CGU
	|			AND TTNewCGU.Organization = TTImpairmentBalances.Organization
	|WHERE
	|	TTNewCGU.NonCurrentAsset IS NULL
	|
	|UNION ALL
	|
	|// Recovery when included in the composition of the BHA CGU, previously depreciated independently.
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TTImpairmentBalances.NonCurrentAsset,
	|	TTImpairmentBalances.CGU,
	|	TTImpairmentBalances.Organization,
	|	TTImpairmentBalances.Department,
	|	TTImpairmentBalances.LineOfBusiness,
	|	TTImpairmentBalances.FinancialAccountingGroup,
	|	TTImpairmentBalances.ImpairmentLocalAssets,
	|	TTImpairmentBalances.ImpairmenMan,
	|	TTImpairmentBalances.LossFromImpairmentLocal AS LossFromImpairmentLocal,
	|	TTImpairmentBalances.LossFromImpairmentMgmt  AS LossFromImpairmentMgmt,
	|	CASE
	|		WHEN TTImpairmentBalances.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversalOfFAImpairment)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReversalOfIAImpairment)
	|	END AS BusinessTransactionSetting,
	|	TTImpairmentBalances.FinRecordID,
	|	4 AS ID // Recovery when included in the composition of the BHA CGU, previously depreciated independently.
	|FROM
	|	TTResiduesToRecover AS TTImpairmentBalances
	|		INNER JOIN TTNewCGU AS TTNewCGU
	|		ON TTNewCGU.NonCurrentAsset = TTImpairmentBalances.NonCurrentAsset
	|			AND TTNewCGU.Organization = TTImpairmentBalances.Organization
	|			AND TTNewCGU.CGU <> VALUE(Catalog.CashGeneratingUnits.EmptyRef)
	|WHERE
	|	TTImpairmentBalances.CGU = VALUE(Catalog.CashGeneratingUnits.EmptyRef) // The CGU Balance is not filled in,
	|	AND TTNewCGU.CGU <> VALUE(Catalog.CashGeneratingUnits.EmptyRef)       // and the new CGU is full
	|
	|UNION ALL
	|
	|// Restoration after specifying the new recoverable amount.
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TTRecovery.NonCurrentAsset,
	|	TTRecovery.CGU,
	|	TTRecovery.Organization,
	|	TTRecovery.Department,
	|	TTRecovery.LineOfBusiness,
	|	TTRecovery.FinancialAccountingGroup,
	|	TTRecovery.ImpairmentLocalAssets,
	|	TTRecovery.ImpairmenMan,
	|	TTRecovery.LossFromImpairmentLocal,
	|	TTRecovery.LossFromImpairmentMgmt,
	|	CASE
	|		WHEN TTRecovery.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversalOfFAImpairment)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReversalOfIAImpairment)
	|	END AS BusinessTransactionSetting,
	|	TTRecovery.FinRecordID,
	|	5 AS ID // Recovery after specifying a new recoverable amount
	|FROM
	|	TTRecovery AS TTRecovery
	|WHERE
	|	TTRecovery.ImpairmentLocalAssets <> 0 
	|	OR TTRecovery.ImpairmenMan <> 0
	|
	|UNION ALL
	|
	|// Accrual after specifying the new recoverable amount.
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TTAccruals.NonCurrentAsset,
	|	TTAccruals.CGU,
	|	TTAccruals.Organization,
	|	TTAccruals.Department,
	|	TTAccruals.LineOfBusiness,
	|	TTAccruals.FinancialAccountingGroup,
	|	TTAccruals.ImpairmentLocalAssets,
	|	TTAccruals.ImpairmenMan,
	|	TTAccruals.LossFromImpairmentLocal,
	|	TTAccruals.LossFromImpairmentMgmt,
	|	CASE
	|		WHEN TTAccruals.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.FAImpairment)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ImpairmentIA)
	|	END AS BusinessTransactionSetting,
	|	TTAccruals.FinRecordID,
	|	6 AS ID // Accrual after the new recoverable amount is indicated
	|FROM
	|	TTAccruals AS TTAccruals
	|WHERE
	|	TTAccruals.ImpairmentLocalAssets <> 0 
	|	OR TTAccruals.ImpairmenMan <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName, False);

EndProcedure

Procedure QueryTextOtherExpenses(Query, QueryTexts)

	RegisterName = "OtherExpenses";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	InitializeTTAccrualRecovery(Query, QueryTexts);

	QueryText = 
	"SELECT
	|	OtherExpenses.Period AS Period,
	|	OtherExpenses.RecordType AS RecordType,
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.Department AS Department,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|	OtherExpenses.ExpenseItem AS ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	OtherExpenses.SumCompl AS SumCompl,
	|	OtherExpenses.Sum AS Sum,
	|	OtherExpenses.SumMan AS SumMan,
	|	OtherExpenses.AmountExcludingVAT AS AmountExcludingVAT,
	|	OtherExpenses.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	OtherExpenses.FinRecordID AS FinRecordID,
	|	OtherExpenses.BusinessOperation AS BusinessOperation,
	|	OtherExpenses.PermanentDifference AS PermanentDifference,
	|	OtherExpenses.CostTD AS CostTD,
	|	OtherExpenses.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	OtherExpenses.AccountCr AS AccountCr,
	|	OtherExpenses.AmountOfOtherAssets AS AmountOfOtherAssets,
	|	OtherExpenses.RegistrationWithTaxAuthority AS RegistrationWithTaxAuthority,
	|	OtherExpenses.DocumentRegisterRecords AS DocumentRegisterRecords,
	|	OtherExpenses.CorExpenseItem AS CorExpenseItem,
	|	OtherExpenses.CorCompany AS CorCompany,
	|	OtherExpenses.CostShare AS CostShare,
	|	OtherExpenses.DebitBusinessUnit AS DebitBusinessUnit,
	|	OtherExpenses.CorExpenditureDimension AS CorExpenditureDimension,
	|	OtherExpenses.ProductsGroup AS ProductsGroup,
	|	OtherExpenses.CorCostElement AS CorCostElement,
	|	OtherExpenses.CalculationOfCost AS CalculationOfCost,
	|	OtherExpenses.LotCalculation AS LotCalculation,
	|	OtherExpenses.RowID AS RowID,
	|	OtherExpenses.CorLineOfBusiness AS CorLineOfBusiness,
	|	OtherExpenses.CorProvisionObject AS CorProvisionObject,
	|	OtherExpenses.AdjReserveKind AS AdjReserveKind,
	|	OtherExpenses.SourceKind AS SourceKind,
	|	OtherExpenses.ReversingEntry AS ReversingEntry,
	|	OtherExpenses.DocumentCalculation AS DocumentCalculation,
	|	OtherExpenses.MonthEndClosingMode AS MonthEndClosingMode,
	|	OtherExpenses.VariancePeriod AS VariancePeriod
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|WHERE
	|	OtherExpenses.Recorder = &Ref
	|	AND NOT OtherExpenses.BusinessTransactionSetting IN (VALUE(Catalog.BusinessTransactionsSettings.FAImpairment), 
	|														 VALUE(Catalog.BusinessTransactionsSettings.ImpairmentIA))
	|
	|UNION
	|
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Receipt),
	|	TTAccruals.Organization,
	|	TTAccruals.Department,
	|	TTAccruals.LineOfBusiness,
	|	ISNULL(ImpairmentFA.ExpenseItem, TTReflectionOfIncomeExpenses.ExpenseItem),
	|	ISNULL(ImpairmentFA.DimensionOfExpenses, TTReflectionOfIncomeExpenses.DimensionOfExpenses),
	|	TTAccruals.LossFromImpairmentLocal,
	|	TTAccruals.LossFromImpairmentMgmt,
	|	TTAccruals.LossFromImpairmentMgmt,
	|	TTAccruals.LossFromImpairmentMgmt,
	|	CASE
	|		WHEN TTAccruals.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.FAImpairment)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ImpairmentIA)
	|	END,
	|	TTAccruals.FinRecordID,
	|	CASE
	|		WHEN TTAccruals.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(Enum.BusinessTransactions.FAImpairment)
	|		ELSE VALUE(Enum.BusinessTransactions.ImpairmentIA)
	|	END,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL
	|FROM
	|	TTAccruals AS TTAccruals
	|		LEFT JOIN TTReflectionOfIncomeExpenses AS TTReflectionOfIncomeExpenses
	|		ON (TTReflectionOfIncomeExpenses.NonCurrentAsset = TTAccruals.NonCurrentAsset)
	|		LEFT JOIN Document.ImpairmentFA AS ImpairmentFA
	|		ON (ImpairmentFA.Ref = &Ref)
	|WHERE
	|	(TTAccruals.ImpairmentLocalAssets <> 0
	|			OR TTAccruals.ImpairmenMan <> 0)";
	
	QueryTexts.Add(QueryText, RegisterName, False);
	
EndProcedure

Procedure QueryTextOtherIncome(Query, QueryTexts)

	RegisterName = "OtherIncome";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	InitializeTTBalancesForRecovery(Query, QueryTexts);
	InitializeTTAccrualRecovery(Query, QueryTexts);

	QueryText = 
	"SELECT
	|	OtherIncome.Period AS Period,
	|	OtherIncome.Organization AS Organization,
	|	OtherIncome.Department AS Department,
	|	OtherIncome.LineOfBusiness AS LineOfBusiness,
	|	OtherIncome.IncomeItem AS IncomeItem,
	|	OtherIncome.DimensionOfRevenue AS DimensionOfRevenue,
	|	OtherIncome.SumCompl AS SumCompl,
	|	OtherIncome.Sum AS Sum,
	|	OtherIncome.SumMan AS SumMan,
	|	OtherIncome.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	OtherIncome.FinRecordID AS FinRecordID,
	|	OtherIncome.BusinessOperation AS BusinessOperation,
	|	OtherIncome.CalculationOfCost AS CalculationOfCost,
	|	OtherIncome.CorLineOfBusiness AS CorLineOfBusiness,
	|	OtherIncome.ReversingEntry AS ReversingEntry,
	|	OtherIncome.DocumentCalculation AS DocumentCalculation,
	|	OtherIncome.MonthEndClosingMode AS MonthEndClosingMode,
	|	1 AS ID // Other income, except for the recovery of impairment
	|FROM
	|	AccumulationRegister.OtherIncome AS OtherIncome
	|WHERE
	|	OtherIncome.Recorder = &Ref
	|	AND NOT OtherIncome.BusinessTransactionSetting IN (
	|			VALUE(Catalog.BusinessTransactionsSettings.ReversalOfFAImpairment), 
	|			VALUE(Catalog.BusinessTransactionsSettings.ReversalOfIAImpairment)
	|														)
	|
	|UNION
	|
	|SELECT
	|	&Period,
	|	TTImpairmentBalances.Organization,
	|	TTImpairmentBalances.Department,
	|	TTImpairmentBalances.LineOfBusiness,
	|	ISNULL(ImpairmentFA.IncomeItem, TTReflectionOfIncomeExpenses.IncomeItem),
	|	ISNULL(ImpairmentFA.DimensionOfRevenue, TTReflectionOfIncomeExpenses.DimensionOfRevenue),
	|	TTImpairmentBalances.LossFromImpairmentLocal,
	|	TTImpairmentBalances.LossFromImpairmentMgmt,
	|	TTImpairmentBalances.LossFromImpairmentMgmt,
	|
	|	CASE
	|		WHEN TTImpairmentBalances.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversalOfFAImpairment)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReversalOfIAImpairment)
	|	END,
	|
	|	TTImpairmentBalances.FinRecordID,
	|
	|	CASE
	|		WHEN TTImpairmentBalances.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(Enum.BusinessTransactions.ReversalOfFAImpairment)
	|		ELSE VALUE(Enum.BusinessTransactions.ReversalOfIAImpairment)
	|	END, 
	|
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	2 AS ID // Restoration of impairment according to the impairment document when changing the CGU
	|FROM
	|	TTResiduesToRecover AS TTImpairmentBalances
	|		INNER JOIN TTNewCGU AS TTNewCGU
	|		ON (TTNewCGU.NonCurrentAsset = TTImpairmentBalances.NonCurrentAsset)
	|			AND (TTNewCGU.CGU = TTImpairmentBalances.CGU)
	|		LEFT JOIN TTReflectionOfIncomeExpenses AS TTReflectionOfIncomeExpenses
	|		ON (TTReflectionOfIncomeExpenses.NonCurrentAsset = TTImpairmentBalances.NonCurrentAsset)
	|		LEFT JOIN Document.ImpairmentFA AS ImpairmentFA
	|		ON (ImpairmentFA.Ref = &Ref)
	|WHERE
	|	TTNewCGU.NonCurrentAsset IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	&Period,
	|	TTRecovery.Organization,
	|	TTRecovery.Department,
	|	TTRecovery.LineOfBusiness,
	|	ISNULL(ImpairmentFA.IncomeItem, TTReflectionOfIncomeExpenses.IncomeItem),
	|	ISNULL(ImpairmentFA.DimensionOfRevenue, TTReflectionOfIncomeExpenses.DimensionOfRevenue),
	|	TTRecovery.LossFromImpairmentLocal,
	|	TTRecovery.LossFromImpairmentMgmt,
	|	TTRecovery.LossFromImpairmentMgmt, 
	|
	|	CASE
	|		WHEN TTRecovery.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversalOfFAImpairment)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReversalOfIAImpairment)
	|	END,
	|
	|	TTRecovery.FinRecordID,  
	|
	|	CASE
	|		WHEN TTRecovery.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(Enum.BusinessTransactions.ReversalOfFAImpairment)
	|		ELSE VALUE(Enum.BusinessTransactions.ReversalOfIAImpairment)
	|	END,
	|
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	3 AS ID // Recovery of impairment when the amount of impairment is changed by the document of impairment
	|FROM
	|	TTRecovery AS TTRecovery
	|		LEFT JOIN TTReflectionOfIncomeExpenses AS TTReflectionOfIncomeExpenses
	|		ON (TTReflectionOfIncomeExpenses.NonCurrentAsset = TTRecovery.NonCurrentAsset)
	|		LEFT JOIN Document.ImpairmentFA AS ImpairmentFA
	|		ON (ImpairmentFA.Ref = &Ref)
	|WHERE
	|	(TTRecovery.LossFromImpairmentLocal <> 0
	|			OR TTRecovery.LossFromImpairmentMgmt <> 0)";
	
	QueryTexts.Add(QueryText, RegisterName, False);
	
EndProcedure

Procedure QueryTextRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	InitializeTTBalancesForRecovery(Query, QueryTexts);
	InitializeTTBalancesForReclassification(Query, QueryTexts);
	InitializeTTAccrualRecovery(Query, QueryTexts);
	
	QueryText = 
	"SELECT
	|	RecordsIncomeExpensesOtherAssetsLiabilities.Period AS Period,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.BusinessOperation AS BusinessOperation,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.Organization AS Organization,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.Department AS Department,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.LineOfBusiness AS LineOfBusiness,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.AssetRef AS AssetRef,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.DimensionOfRevenue AS DimensionOfRevenue,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.DimensionOfExpenses AS DimensionOfExpenses,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.DebitBusinessUnit AS DebitBusinessUnit,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.CorLineOfBusiness AS CorLineOfBusiness,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.CorFinancialAccountingGroup AS CorFinancialAccountingGroup,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.CorItem AS CorItem,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.CorIncomeDimension AS CorIncomeDimension,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.CorExpenditureDimension AS CorExpenditureDimension,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.CorDimensionOfAssetsLiabilities AS CorDimensionOfAssetsLiabilities,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.CorCompany AS CorCompany,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.Sum AS Sum,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.SumMan AS SumMan,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.SumCompl AS SumCompl,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.Counterparty,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.CorCounterparty,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.Currency,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.AmountInCurrency,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.SalaryTransactionKind,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.CalculationMethod,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.NotSubjectToPersonalIncomeTax,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.DocumentRegisterRecords,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.CalculationOfCost,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.ReversingEntry,
	|	RecordsIncomeExpensesOtherAssetsLiabilities.SourceKind
	|FROM
	|	AccumulationRegister.RecordsIncomeExpensesOtherAssetsLiabilities AS RecordsIncomeExpensesOtherAssetsLiabilities
	|WHERE
	|	RecordsIncomeExpensesOtherAssetsLiabilities.Recorder = &Ref
	|	AND NOT RecordsIncomeExpensesOtherAssetsLiabilities.BusinessOperation IN
	|	(VALUE(Enum.BusinessTransactions.ReclassificationOfFA),
	|		VALUE(Enum.BusinessTransactions.ReclassificationOfIA),
	|		VALUE(Enum.BusinessTransactions.ReversalOfFAImpairment),
	|		VALUE(Enum.BusinessTransactions.ReversalOfIAImpairment),
	|		VALUE(Enum.BusinessTransactions.FAImpairment),
	|		VALUE(Enum.BusinessTransactions.ImpairmentIA))
	|
	|UNION
	|
	|SELECT
	|	&Period,
	|	CASE
	|		WHEN TTImpairmentBalances.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(Enum.BusinessTransactions.ReclassificationOfFA)
	|		ELSE VALUE(Enum.BusinessTransactions.ReclassificationOfIA)
	|	END,
	|	TTImpairmentBalances.Organization,
	|	TTNewAnalyticsVNA.Department,
	|	TTNewAnalyticsVNA.LineOfBusiness,
	|	TTNewAnalyticsVNA.FinancialAccountingGroup,
	|	CASE
	|		WHEN TTImpairmentBalances.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets)
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceIntangibleAssets)
	|	END,
	|	UNDEFINED,
	|	UNDEFINED,
	|	TTImpairmentBalances.NonCurrentAsset,
	|	TTImpairmentBalances.Department,
	|	TTImpairmentBalances.LineOfBusiness,
	|	TTImpairmentBalances.FinancialAccountingGroup,
	|	CASE
	|		WHEN TTImpairmentBalances.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets)
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceIntangibleAssets)
	|	END,
	|	UNDEFINED,
	|	UNDEFINED,
	|	TTImpairmentBalances.NonCurrentAsset,
	|	TTImpairmentBalances.Organization,
	|	TTImpairmentBalances.ImpairmenMan,
	|	TTImpairmentBalances.ImpairmenMan,
	|	TTImpairmentBalances.ImpairmentLocalAssets,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL
	|FROM
	|	TTBalancesForReclassification AS TTImpairmentBalances
	|		LEFT JOIN TTNewAnalyticsVNA AS TTNewAnalyticsVNA
	|		ON TTNewAnalyticsVNA.NonCurrentAsset = TTImpairmentBalances.NonCurrentAsset
	|		INNER JOIN TTNewCGU AS TTNewCGU
	|		ON TTNewCGU.NonCurrentAsset = TTImpairmentBalances.NonCurrentAsset
	|		AND TTNewCGU.CGU = TTImpairmentBalances.CGU
	|WHERE
	|	(TTNewAnalyticsVNA.FinancialAccountingGroup <> TTImpairmentBalances.FinancialAccountingGroup
	|	OR TTNewAnalyticsVNA.LineOfBusiness <> TTImpairmentBalances.LineOfBusiness
	|	OR TTNewAnalyticsVNA.Department <> TTImpairmentBalances.Department)
	|	AND (TTNewAnalyticsVNA.RecordInLocalAccounting
	|	OR TTNewAnalyticsVNA.RecordInManAccounting)
	|
	|UNION ALL
	|// Restoration upon retirement from the EGDS
	|SELECT
	|	&Period,
	|	CASE
	|		WHEN TTImpairmentBalances.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(Enum.BusinessTransactions.ReversalOfFAImpairment)
	|		ELSE VALUE(Enum.BusinessTransactions.ReversalOfIAImpairment)
	|	END AS BusinessOperation,
	|	TTImpairmentBalances.Organization AS Organization,
	|	TTImpairmentBalances.Department AS Department,
	|	TTImpairmentBalances.LineOfBusiness AS LineOfBusiness,
	|	TTImpairmentBalances.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	CASE
	|		WHEN TTImpairmentBalances.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets)
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceIntangibleAssets)
	|	END AS AssetRef,
	|	UNDEFINED AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	TTImpairmentBalances.NonCurrentAsset AS AssetsLiabilitiesDimension,
	|	TTImpairmentBalances.Department AS DebitBusinessUnit,
	|	TTImpairmentBalances.LineOfBusiness AS CorLineOfBusiness,
	|	TTImpairmentBalances.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|	ISNULL(ImpairmentFA.IncomeItem, TTReflectionOfIncomeExpenses.IncomeItem) AS CorItem,
	|	ISNULL(ImpairmentFA.DimensionOfRevenue, TTReflectionOfIncomeExpenses.DimensionOfRevenue) AS CorIncomeDimension,
	|	UNDEFINED AS CorExpenditureDimension,
	|	TTImpairmentBalances.NonCurrentAsset AS CorDimensionOfAssetsLiabilities,
	|	TTImpairmentBalances.Organization AS CorCompany,
	|	TTImpairmentBalances.ImpairmenMan AS Sum,
	|	TTImpairmentBalances.ImpairmenMan AS SumMan,
	|	TTImpairmentBalances.ImpairmentLocalAssets AS SumCompl,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL
	|FROM
	|	TTResiduesToRecover AS TTImpairmentBalances
	|		LEFT JOIN TTReflectionOfIncomeExpenses AS TTReflectionOfIncomeExpenses
	|		ON TTReflectionOfIncomeExpenses.NonCurrentAsset = TTImpairmentBalances.NonCurrentAsset
	|		LEFT JOIN Document.ImpairmentFA AS ImpairmentFA
	|		ON ImpairmentFA.Ref = &Ref
	|		INNER JOIN TTNewCGU AS TTNewCGU
	|		ON TTNewCGU.NonCurrentAsset = TTImpairmentBalances.NonCurrentAsset
	|		AND TTNewCGU.CGU = TTImpairmentBalances.CGU
	|WHERE
	|	TTNewCGU.NonCurrentAsset IS NULL
	|
	|UNION ALL
	|// Recovery after specifying a new recoverable amount
	|SELECT
	|	&Period,
	|	CASE
	|		WHEN TTRecovery.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(Enum.BusinessTransactions.ReversalOfFAImpairment)
	|		ELSE VALUE(Enum.BusinessTransactions.ReversalOfIAImpairment)
	|	END AS BusinessOperation,
	|	TTRecovery.Organization AS Organization,
	|	TTRecovery.Department AS Department,
	|	TTRecovery.LineOfBusiness AS LineOfBusiness,
	|	TTRecovery.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	CASE
	|		WHEN TTRecovery.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets)
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceIntangibleAssets)
	|	END AS AssetRef,
	|	UNDEFINED AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	TTRecovery.NonCurrentAsset AS AssetsLiabilitiesDimension,
	|	TTRecovery.Department AS DebitBusinessUnit,
	|	TTRecovery.LineOfBusiness AS CorLineOfBusiness,
	|	TTRecovery.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|	ISNULL(ImpairmentFA.IncomeItem, TTReflectionOfIncomeExpenses.IncomeItem) AS CorItem,
	|	ISNULL(ImpairmentFA.DimensionOfRevenue, TTReflectionOfIncomeExpenses.DimensionOfRevenue) AS CorIncomeDimension,
	|	UNDEFINED AS CorExpenditureDimension,
	|	UNDEFINED AS CorDimensionOfAssetsLiabilities,
	|	TTRecovery.Organization AS CorCompany,
	|	TTRecovery.ImpairmenMan AS Sum,
	|	TTRecovery.ImpairmenMan AS SumMan,
	|	TTRecovery.ImpairmentLocalAssets AS SumCompl,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL
	|FROM
	|	TTRecovery AS TTRecovery
	|		LEFT JOIN TTReflectionOfIncomeExpenses AS TTReflectionOfIncomeExpenses
	|		ON TTReflectionOfIncomeExpenses.NonCurrentAsset = TTRecovery.NonCurrentAsset
	|		LEFT JOIN Document.ImpairmentFA AS ImpairmentFA
	|		ON ImpairmentFA.Ref = &Ref
	|WHERE
	|	TTRecovery.ImpairmentLocalAssets <> 0
	|	OR TTRecovery.ImpairmenMan <> 0
	|
	|UNION ALL
	|// Accrual after the new recoverable amount is indicated
	|SELECT
	|	&Period,
	|	CASE
	|		WHEN TTAccruals.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(Enum.BusinessTransactions.FAImpairment)
	|		ELSE VALUE(Enum.BusinessTransactions.ImpairmentIA)
	|	END AS BusinessOperation,
	|	TTAccruals.Organization AS Organization,
	|	TTAccruals.Department AS Department,
	|	TTAccruals.LineOfBusiness AS LineOfBusiness,
	|	TTAccruals.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	CASE
	|		WHEN TTAccruals.NonCurrentAsset REFS Catalog.Assets
	|			THEN VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets)
	|		ELSE VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceIntangibleAssets)
	|	END AS AssetRef,
	|	UNDEFINED AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	TTAccruals.NonCurrentAsset AS AssetsLiabilitiesDimension,
	|	TTAccruals.Department AS DebitBusinessUnit,
	|	TTAccruals.LineOfBusiness AS CorLineOfBusiness,
	|	TTAccruals.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|	ISNULL(ImpairmentFA.ExpenseItem, TTReflectionOfIncomeExpenses.ExpenseItem) AS CorItem,
	|	UNDEFINED AS CorIncomeDimension,
	|	ISNULL(ImpairmentFA.DimensionOfExpenses, TTReflectionOfIncomeExpenses.DimensionOfExpenses) AS CorExpenditureDimension,
	|	UNDEFINED AS CorDimensionOfAssetsLiabilities,
	|	TTAccruals.Organization AS CorCompany,
	|	TTAccruals.ImpairmenMan AS Sum,
	|	TTAccruals.ImpairmenMan AS SumMan,
	|	TTAccruals.ImpairmentLocalAssets AS SumCompl,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL
	|FROM
	|	TTAccruals AS TTAccruals
	|		LEFT JOIN TTReflectionOfIncomeExpenses AS TTReflectionOfIncomeExpenses
	|		ON TTReflectionOfIncomeExpenses.NonCurrentAsset = TTAccruals.NonCurrentAsset
	|		LEFT JOIN Document.ImpairmentFA AS ImpairmentFA
	|		ON ImpairmentFA.Ref = &Ref
	|WHERE
	|	TTAccruals.ImpairmentLocalAssets <> 0
	|	OR TTAccruals.ImpairmenMan <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

#Region CostAndDepreciationOfRevaluation
// Changes in the revaluation reserve in the cost and depreciation registers.
Procedure QueryTextCostOfFADuringRevaluation(Query, QueryTexts)
	RegisterName = "FACost";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
		QueryText = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense)        AS RecordType,
	|	TTAccruals.Organization                AS Organization,
	|	TTAccruals.NonCurrentAsset           AS FixedAsset,
	|	TTAccruals.Department              AS Department,
	|	TTAccruals.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|	TTAccruals.LineOfBusiness    AS LineOfBusiness,
	|	UNDEFINED                            AS Leaseholder,
	|
	|	TTAccruals.ChangeInReserveOfCostOfMan     AS CostRevaluationReserve,
	|	TTAccruals.ChangeInReserveOfCostOfLocal AS CostRevaluationReserveLocal,
	|
	|	-TTAccruals.ChangeInReserveOfCostOfMan 
	|		+ TTAccruals.ChangeInDepreciationReserveMan      AS CostGainMA, // Reserve for additional assessment
	|
	|	-TTAccruals.ChangeInReserveOfCostOfLocal 
	|		+ TTAccruals.ChangeInDepreciationReserveLocal     AS CostGainLocal,
	|
	|	TTAccruals.FinRecordID AS FinRecordID,
	|	VALUE(Enum.BusinessTransactions.FAImpairment) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.FAImpairment) AS BusinessTransactionSetting
	|		
	|FROM
	|	TTAccruals AS TTAccruals
	|	
	|WHERE
	|	TTAccruals.NonCurrentAsset REFS Catalog.Assets
	|	AND
	|		(TTAccruals.ChangeInReserveOfCostOfMan <> 0
	|			OR TTAccruals.ChangeInReserveOfCostOfLocal  <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt)        AS RecordType,
	|	TTRecovery.Organization                AS Organization,
	|	TTRecovery.NonCurrentAsset           AS FixedAsset,
	|	TTRecovery.Department              AS Department,
	|	TTRecovery.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|	TTRecovery.LineOfBusiness    AS LineOfBusiness,
	|	UNDEFINED                            AS Leaseholder,
	|
	|	TTRecovery.ChangeInReserveOfCostOfMan     AS CostRevaluationReserve,
	|	TTRecovery.ChangeInReserveOfCostOfLocal AS CostRevaluationReserveLocal,
	|
	|	-TTRecovery.ChangeInReserveOfCostOfMan 
	|		+ TTRecovery.ChangeInDepreciationReserveMan      AS CostGainMA, // Reserve for additional assessment
	|
	|	-TTRecovery.ChangeInReserveOfCostOfLocal 
	|		+ TTRecovery.ChangeInDepreciationReserveLocal     AS CostGainLocal,
	|
	|	TTRecovery.FinRecordID AS FinRecordID,
	|	VALUE(Enum.BusinessTransactions.ReversalOfFAImpairment) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReversalOfFAImpairment) AS BusinessTransactionSetting
	|		
	|FROM
	|	TTRecovery AS TTRecovery
	|	
	|WHERE
	|	TTRecovery.NonCurrentAsset REFS Catalog.Assets
	|	AND
	|		(TTRecovery.ChangeInReserveOfCostOfMan <> 0
	|			OR TTRecovery.ChangeInReserveOfCostOfLocal  <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextDepreciationOfFADuringRevaluation(Query, QueryTexts)
		RegisterName = "FixedAssetsDepreciationCharge";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt)        AS RecordType,
	|	TTAccruals.Organization                AS Organization,
	|	TTAccruals.NonCurrentAsset           AS FixedAsset,
	|	TTAccruals.Department              AS Department,
	|	TTAccruals.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|	TTAccruals.LineOfBusiness    AS LineOfBusiness,
	|
	|	TTAccruals.ChangeInDepreciationReserveMan     AS DepreciationRevaluationReserve,
	|	TTAccruals.ChangeInDepreciationReserveLocal AS DepreciationRevaluationReserveLocal,
	|
	|	TTAccruals.FinRecordID AS FinRecordID,
	|	VALUE(Enum.BusinessTransactions.FAImpairment) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.FAImpairment) AS BusinessTransactionSetting
	|		
	|FROM
	|	 TTAccruals AS TTAccruals
	|	
	|WHERE
	|	TTAccruals.NonCurrentAsset REFS Catalog.Assets
	|	AND
	|		(TTAccruals.ChangeInDepreciationReserveMan <> 0
	|			OR TTAccruals.ChangeInDepreciationReserveLocal  <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
EndProcedure

Procedure QueryTextIACostDuringRevaluation(Query, QueryTexts)
	
	RegisterName = "IACost";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense)         AS RecordType,
	|	TTAccruals.Organization                AS Organization,
	|	TTAccruals.NonCurrentAsset           AS IntangibleAsset,
	|	TTAccruals.Department              AS Department,
	|	TTAccruals.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|	TTAccruals.LineOfBusiness    AS LineOfBusiness,
	|
	|	TTAccruals.ChangeInReserveOfCostOfMan     AS CostRevaluationReserve,
	|	TTAccruals.ChangeInReserveOfCostOfLocal AS CostRevaluationReserveLocal,
	|
	|	-TTAccruals.ChangeInReserveOfCostOfMan 
	|		+ TTAccruals.ChangeInDepreciationReserveMan      AS CostGainMA, // Reserve for additional assessment
	|
	|	-TTAccruals.ChangeInReserveOfCostOfLocal 
	|		+ TTAccruals.ChangeInDepreciationReserveLocal     AS CostGainLocal,
	|
	|	TTAccruals.FinRecordID AS FinRecordID,
	|	VALUE(Enum.BusinessTransactions.ImpairmentIA) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.ImpairmentIA) AS BusinessTransactionSetting
	|		
	|FROM
	|	TTAccruals AS TTAccruals
	|	
	|WHERE
	|	TTAccruals.NonCurrentAsset REFS Catalog.IntangibleAssets
	|	AND
	|		(TTAccruals.ChangeInReserveOfCostOfMan <> 0
	|			OR TTAccruals.ChangeInReserveOfCostOfLocal  <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt)        AS RecordType,
	|	TTRecovery.Organization                AS Organization,
	|	TTRecovery.NonCurrentAsset           AS IntangibleAsset,
	|	TTRecovery.Department              AS Department,
	|	TTRecovery.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|	TTRecovery.LineOfBusiness    AS LineOfBusiness,
	|
	|	TTRecovery.ChangeInReserveOfCostOfMan     AS CostRevaluationReserve,
	|	TTRecovery.ChangeInReserveOfCostOfLocal AS CostRevaluationReserveLocal,
	|
	|	-TTRecovery.ChangeInReserveOfCostOfMan
	|		+ TTRecovery.ChangeInDepreciationReserveMan     AS CostGainMA, // Reserve for additional assessment
	|
	|	-TTRecovery.ChangeInReserveOfCostOfLocal
	|		+ TTRecovery.ChangeInDepreciationReserveLocal AS CostGainLocal,
	|
	|	TTRecovery.FinRecordID AS FinRecordID,
	|	VALUE(Enum.BusinessTransactions.ReversalOfIAImpairment) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReversalOfIAImpairment) AS BusinessTransactionSetting
	|		
	|FROM
	|	TTRecovery AS TTRecovery
	|	
	|WHERE
	|	TTRecovery.NonCurrentAsset REFS Catalog.IntangibleAssets
	|	AND
	|		(TTRecovery.ChangeInReserveOfCostOfMan <> 0
	|			OR TTRecovery.ChangeInReserveOfCostOfLocal  <> 0)";
	
	QueryTexts.Add(QueryText, RegisterName);

EndProcedure

Procedure QueryTextIntangibleAssetAmortizationChargeDuringRevaluation(Query, QueryTexts)
		RegisterName = "IntangibleAssetsAmortizationCharge";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt)        AS RecordType,
	|	TTAccruals.Organization                AS Organization,
	|	TTAccruals.NonCurrentAsset           AS IntangibleAsset,
	|	TTAccruals.Department              AS Department,
	|	TTAccruals.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|	TTAccruals.LineOfBusiness    AS LineOfBusiness,
	|
	|	TTAccruals.ChangeInDepreciationReserveMan     AS DepreciationRevaluationReserve,
	|
	|	TTAccruals.ChangeInDepreciationReserveLocal AS DepreciationRevaluationReserveLocal,
	|
	|	TTAccruals.FinRecordID AS FinRecordID,
	|	VALUE(Enum.BusinessTransactions.ImpairmentIA) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.ImpairmentIA) AS BusinessTransactionSetting
	|		
	|FROM
	|	TTAccruals AS TTAccruals
	|	
	|WHERE
	|	TTAccruals.NonCurrentAsset REFS Catalog.IntangibleAssets
	|	AND
	|		(TTAccruals.ChangeInDepreciationReserveMan <> 0
	|			OR TTAccruals.ChangeInDepreciationReserveLocal  <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
EndProcedure

#EndRegion

#EndRegion

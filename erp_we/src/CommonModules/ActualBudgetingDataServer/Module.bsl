#Region Public

// Complements the structure of the parameters for reflecting the records of accumulation registers in financial accounting.
// 
// Parameters:
// 	ReflectionParameters - See FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting.
// 
Procedure ToSupplementParametersOfReflectionOfRegisteredRecordsInFinancialAccounting(ReflectionParameters) Export
	
	ReflectionParameters.Insert("ThisIsVATRegister", False);
	ReflectionParameters.Insert("TypeOfAccountingData", PredefinedValue("Enum.AccountingDataTypes.EmptyRef"));
	ReflectionParameters.Insert("StructureOfAnalytics", New Structure);
	ReflectionParameters.Insert("Indicators", New Map);
	ReflectionParameters.Insert("DataPathDopSettingUpHouseholdOfOperation", "");
	
EndProcedure

#EndRegion

#Region Private

#Region EventSubscriptions

Procedure MarkDocumentForRecordingInBudgetingBeforeSavingDocument(Source, Cancel, WriteMode, PostingMode) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;

	SetPrivilegedMode(True);
	
	If Not YouNeedToPutDocumentInTaskQueue(Source) Then
		Return;
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting
	 Or WriteMode = DocumentWriteMode.UndoPosting Then
		For Each RegisterRecords In Source.RegisterRecords Do
			RegisterRecords.AdditionalProperties.Insert("NotReflectedInBudgeting", True);
		EndDo;
	EndIf;
	
EndProcedure

Procedure CancelDocumentForRecordingInBudgetingWhileSavingRecordSet(Source, Cancel, WriteMode) Export
	Var JobNumber;
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Source.AdditionalProperties.Property("NotReflectedInBudgeting") Then
		Return;
	EndIf;
	
	If Not YouNeedToPutDocumentInTaskQueue(Source) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	
	Try
		HasChanges = False;
		
		Recorders = Source.Unload(, "Recorder");
		Recorders.GroupBy("Recorder");
		
		For Each Recorder In Recorders.UnloadColumn("Recorder") Do
			RecordSet = SetOfReflectionRecordsInBudgeting(JobNumber, Recorder);
			RecordSet.Read();
			
			TimeIntervals = Source.Unload(, "Period");
			For Each PeriodString_ In TimeIntervals Do
				PeriodString_.Period = BegOfDay(PeriodString_.Period);
			EndDo;
			TimeIntervals.GroupBy("Period");
			
			For Each PeriodString_ In TimeIntervals Do
				AddReflectionRecordInBudgeting(RecordSet, JobNumber, Recorder, PeriodString_.Period, HasChanges);
			EndDo;
			
			If Not TimeIntervals.Count() Then
				AddReflectionRecordInBudgeting(RecordSet, JobNumber, Recorder, Date(1, 1, 1), HasChanges);
			EndIf;
			
			If HasChanges Then
				RecordSet.Write();
			EndIf;
		
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		LREvent = NStr("vi = 'Lập ngân sách';
						|ru = 'Бюджетирование';
						|en = 'Budgeting'; fa = 'بودجه‌بندی';
						|it = 'Budgeting';
						|pl = 'Budżetowanie';
						|tr = 'Bütçeleme'", Common.DefaultLanguageCode())
			+ "." + NStr("vi = 'Phản ánh sự kiện';
						|ru = 'Отражение факта';
						|en = 'Actual value record'; fa = 'Actual value record';
						|it = 'Riporto fatto';
						|pl = 'Odzwierciedlenie faktu';
						|tr = 'Bilgilerin yansıtılması'", Common.DefaultLanguageCode());
		WriteLogEvent(LREvent,
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

Procedure MarkADocumentForRecordingInBudgetingDuringPosting(Source, Cancel, WriteMode) Export
	Var JobNumber, HasChanges;
	
	SetPrivilegedMode(True);
	
	If Not YouNeedToPutDocumentInTaskQueue(Source) Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		HasChanges = False;
		
		Recorder = Source.Ref;
		RecordSet = SetOfReflectionRecordsInBudgeting(JobNumber, Recorder);
		
		AllPeriods = New ValueTable;
		AllPeriods.Columns.Add("Period", Common.DateTypeDetails(DateFractions.Date));
		
		For Each RegisterRecords In Source.RegisterRecords Do
			RegisterMetadata = Metadata.FindByType(TypeOf(RegisterRecords));
			If Common.IsAccountingRegister(RegisterMetadata)
				Or Common.IsAccumulationRegister(RegisterMetadata) Then
				TimeIntervals = RegisterRecords.Unload(, "Period"); // ValueTable - 
				TimeIntervals.GroupBy("Period");
				CommonClientServer.SupplementTable(TimeIntervals, AllPeriods);
			EndIf;
		EndDo;
		
		AllPeriods.GroupBy("Period");
		
		For Each PeriodString_ In AllPeriods Do
			AddReflectionRecordInBudgeting(RecordSet, JobNumber, Recorder, PeriodString_.Period, HasChanges);
		EndDo;
		
		If Not AllPeriods.Count() Then
			AddReflectionRecordInBudgeting(RecordSet, JobNumber, Recorder, Date(1, 1, 1), HasChanges);
		EndIf;
		
		If HasChanges Then
			RecordSet.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		LREvent = NStr("vi = 'Lập ngân sách';
						|ru = 'Бюджетирование';
						|en = 'Budgeting'; fa = 'بودجه‌بندی';
						|it = 'Budgeting';
						|pl = 'Budżetowanie';
						|tr = 'Bütçeleme'", Common.DefaultLanguageCode())
			+ "." + NStr("vi = 'Phản ánh sự kiện';
						|ru = 'Отражение факта';
						|en = 'Actual value record'; fa = 'Actual value record';
						|it = 'Riporto fatto';
						|pl = 'Odzwierciedlenie faktu';
						|tr = 'Bilgilerin yansıtılması'", Common.DefaultLanguageCode());
		WriteLogEvent(LREvent,
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	If Not Cancel And HasChanges And Constants.UpdateStoredActualBudgetingDataWhenPostingDocuments.Get() Then
		ReflectDocumentsAsBackgroundTask(,,False);
	EndIf;
	
EndProcedure

// Marks the document for reflection in budgeting.
// 
// Parameters:
// 	Source - DocumentObject - 
// 	Cancel - Boolean - 
Procedure MarkDocumentForBudgetingWhenDeletingIt(Source, Cancel) Export
	Var JobNumber;
	
	SetPrivilegedMode(True);
	
	If Not YouNeedToPutDocumentInTaskQueue(Source) Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		HasChanges = False;
		
		Recorder = Source.Ref;
		RecordSet = SetOfReflectionRecordsInBudgeting(JobNumber, Recorder);
		AddReflectionRecordInBudgeting(RecordSet, JobNumber, Recorder, Date(1, 1, 1), HasChanges);
		
		If HasChanges Then
			RecordSet.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		LREvent = NStr("vi = 'Lập ngân sách';
						|ru = 'Бюджетирование';
						|en = 'Budgeting'; fa = 'بودجه‌بندی';
						|it = 'Budgeting';
						|pl = 'Budżetowanie';
						|tr = 'Bütçeleme'", Common.DefaultLanguageCode())
			+ "." + NStr("vi = 'Phản ánh sự kiện';
						|ru = 'Отражение факта';
						|en = 'Actual value record'; fa = 'Actual value record';
						|it = 'Riporto fatto';
						|pl = 'Odzwierciedlenie faktu';
						|tr = 'Bilgilerin yansıtılması'", Common.DefaultLanguageCode());
		WriteLogEvent(LREvent,
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	If Not Cancel And HasChanges And	Constants.UpdateStoredActualBudgetingDataWhenPostingDocuments.Get() Then
		ReflectDocumentsAsBackgroundTask(,,False);
	EndIf;
	
EndProcedure

#EndRegion

Function SetOfReflectionRecordsInBudgeting(JobNumber, Recorder)
	
	JobNumber = 0;
	
	Block = New DataLock;
	LockItem = Block.Add();
	LockItem.Region = "InformationRegister.JobsForPostingInBudgeting";
	LockItem.SetValue("JobNumber", JobNumber);
	LockItem.SetValue("Document",     Recorder);
	LockItem.Mode = DataLockMode.Exclusive;
	Block.Lock();
	
	RecordSet = InformationRegisters.JobsForPostingInBudgeting.CreateRecordSet();
	RecordSet.Filter.JobNumber.Set(JobNumber);
	RecordSet.Filter.Document.Set(Recorder);
	
	Return RecordSet;
	
EndFunction

Procedure AddReflectionRecordInBudgeting(RecordSet, JobNumber, Recorder, RecordPeriod, HasChanges)
	
	For Each Record In RecordSet Do
		If Record.RecordPeriod = RecordPeriod Then
			Return;
		EndIf;
	EndDo;
	
	Record = RecordSet.Add();
	Record.JobNumber = JobNumber;
	Record.Document = Recorder;
	Record.RecordPeriod = RecordPeriod;
	Record.DocumentKindName = Metadata.FindByType(TypeOf(Recorder)).Name;
	
	HasChanges = True;
	
EndProcedure

Procedure PerformOfflineCalculations(DocumentsForSettlement, Val EndDate = Undefined) Export
	
	If Not ValueIsFilled(EndDate) Then
		EndDate = EndOfMonth(CurrentSessionDate());
	EndIf;
	CalculationEnd = EndOfMonth(EndDate)+1;
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		Query = New Query("
		|SELECT DISTINCT
		|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS Calculations
		|WHERE
		|	Calculations.Recorder IN (&DocumentsToBeReflected)
		|	AND Calculations.Active
		|");
		
		Query.SetParameter("DocumentsToBeReflected", DocumentsForSettlement);
		SupplierAnalyticsArray = Query.Execute().Unload().UnloadColumn("AccountingDimensionByPartners");
		
		If SupplierAnalyticsArray.Count() > 0 Then
			CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
			CalculationAnalysts.AccountingAnalyticsForPartners = SupplierAnalyticsArray;
			ARAPAllocationServerCall.DistributeAllSettlementsWithSuppliers(CalculationEnd, CalculationAnalysts);
		EndIf;
		
		Query = New Query("
		|SELECT DISTINCT
		|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS Calculations
		|WHERE
		|	Calculations.Recorder IN (&DocumentsToBeReflected)
		|	AND Calculations.Active
		|");
		
		Query.SetParameter("DocumentsToBeReflected", DocumentsForSettlement);
		ArrayOfCustomerAnalytics = Query.Execute().Unload().UnloadColumn("AccountingDimensionByPartners");
		
		If ArrayOfCustomerAnalytics.Count() > 0 Then
			CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
			CalculationAnalysts.AccountingAnalyticsForPartners = ArrayOfCustomerAnalytics;
			ARAPAllocationServerCall.DistributeAllSettlementsWithCustomers(CalculationEnd, CalculationAnalysts);
		EndIf;
		
	EndIf;
	
	If DocumentsForSettlement.Count() > 0 Then
		ExecutionParameters = FinancialAccountingByBalanceSheetRegisterData.ParametersForOfflineCalculations();
		ExecutionParameters.EndDate = EndDate;
		ExecutionParameters.DocumentsForSettlement = DocumentsForSettlement;
		ExecutionParameters.ThreadsCount = NumberOfReflectionStreamsInBudgeting();
		FinancialAccountingByBalanceSheetRegisterData.PerformOfflineCalculations(ExecutionParameters);
	EndIf;
	
	If GetFunctionalOption("UseExcisableGoods")
		And DocumentsForSettlement.Count() > 0 Then
			BackdateJobQueue.CompleteTasksInNonOperationalQueueBasedOnListOfDocuments(
				DocumentsForSettlement, Catalogs.BackdateJobKinds.RecordExciseRegisterRecords);
	EndIf;
	
EndProcedure

#Region ManagingOfflineCalculations

Function NumberOfReflectionStreamsInBudgeting()
	
	NumberOfThreadsWithSeparation = 1;
	NumberOfThreadsWithoutSeparation = 6;
	
	If Not MultithreadedReflectionIsPossible() Then
		ThreadsCount = 1;
	ElsIf Common.DataSeparationEnabled() Then
		ThreadsCount = NumberOfThreadsWithSeparation;
	Else
		ThreadsCount = NumberOfThreadsWithoutSeparation;
	EndIf;
	
	Return ThreadsCount;
	
EndFunction

Function MultithreadedReflectionIsPossible()
	
	SetPrivilegedMode(True);
	
	Return Not Common.DebugMode()
		And Not Common.FileInfobase()
		And AccumulationRegisters.ActualBudgetingData.GetTotalsSplittingMode();
	
EndFunction

#EndRegion


// Returns the flag for whether the document (logger) should be added to the budgeting reflection queue.
// 
// Parameters:
// 	Source - DocumentObject, AccumulationRegisterRecordSet -
// Returns:
// 	Boolean - True, if you need to put the document in the budgeting reflection queue
Function YouNeedToPutDocumentInTaskQueue(Source)
	Var FOCacheUseBudgeting;
	
	If Source.AdditionalProperties.Property("UseBudgeting", FOCacheUseBudgeting) Then
		If FOCacheUseBudgeting = False Then
			Return False;
		EndIf;
	EndIf;
	
	If Not GetFunctionalOption("UseBudgeting") Then
		Source.AdditionalProperties.Insert("UseBudgeting", False);
		Return False;
	EndIf;
	
	If ExchangePlans.MasterNode() <> Undefined Then
		Return False;
	EndIf;
	
	If Source.DataExchange.Load Then
		If Not ValueIsFilled(Source.DataExchange.Sender) Then
			Return False;
		EndIf;
	EndIf;
	
	If TypeOf(Source) = Type("AccumulationRegisterRecordSet.ActualBudgetingData") Then
		Return False;
	EndIf;
	
	If TypeOf(Source) = Type("AccumulationRegisterRecordSet.BudgetTurnovers") Then
		Return False;
	EndIf;
	
	If TypeOf(Source) = Type("AccumulationRegisterRecordSet.LimitsByBudgetingData") Then
		Return False;
	EndIf;
	
	If TypeOf(Source) = Type("DocumentObject.BudgetEntryForm") Then
		Return False;
	ElsIf TypeOf(Source) = Type("DocumentObject.ReversingEntry")
		And (TypeOf(Source.ReversedDocument) = Type("DocumentRef.OBEntry")
		Or TypeOf(Source.ReversedDocument) = Type("DocumentRef.OBEntryARAP")) Then
		Return False;
	EndIf;
	
	ObjectMetadata = Source.Metadata(); // MetadataObjectAccumulationRegister, MetadataObjectDocument -
	IsAccumulationRegister = Metadata.AccumulationRegisters.Contains(ObjectMetadata);
	IsAccountingRegister = Metadata.AccountingRegisters.Contains(ObjectMetadata);
	If IsAccumulationRegister Or IsAccountingRegister Then
		If Source.Count() > 0 Then
			Recorder = Source[0].Recorder;
		Else
			Recorder = Source.Filter.Recorder.Value;
		EndIf;
		ActualDataLoggers = Metadata.AccumulationRegisters.ActualBudgetingData.StandardAttributes.Recorder.Type;
		
		If Not ActualDataLoggers.ContainsType(TypeOf(Recorder)) Then
			Return False;
		EndIf;
		
		If Not Source.Count() Then
			DeletionMark = Common.ObjectAttributeValue(Recorder, "DeletionMark");
			If DeletionMark = Undefined Or DeletionMark = True Then
				Return False;
			EndIf;
			Query = New Query();
			Query.Text = 
			"SELECT TOP 1
				|	1
				|FROM
				|	&Table AS Table
				|WHERE
				|	Table.Recorder = &Recorder";
			If IsAccumulationRegister Then
				Query.Text = StrReplace(Query.Text, "&Table", "AccumulationRegister." + ObjectMetadata.Name);
			Else
				Query.Text = StrReplace(Query.Text, "&Table", "AccountingRegister." + ObjectMetadata.Name);
			EndIf;
			Query.SetParameter("Recorder", Recorder);
			If Query.Execute().IsEmpty() Then
				Return False;
			EndIf;
		EndIf;
		
		If TypeOf(Recorder) = Type("DocumentRef.ReversingEntry") Then
			ReversedDocument = Common.ObjectAttributeValue(Recorder, "ReversedDocument");
			If TypeOf(ReversedDocument) = Type("DocumentRef.OBEntry")
				Or TypeOf(ReversedDocument) = Type("DocumentRef.OBEntryARAP") Then
				Return False;
			EndIf;
		EndIf;
	EndIf;
	
	If Metadata.Documents.Contains(ObjectMetadata) Then
		ActualDataLoggers = Metadata.AccumulationRegisters.ActualBudgetingData.StandardAttributes.Recorder.Type;
		If Not ActualDataLoggers.ContainsType(TypeOf(Source.Ref)) Then
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

// Returns an array of types of documents for which actual data is collected according to the rule
//
// Parameters:
//  RuleDescription_ - CatalogObject.ActualDataQueryRulesByBudgetFlowItems, ValueTableRow - Rule For Obtaining A Fact
//  DocumentNameCache - ValueTable:
//   * Rule - CatalogRef.ActualDataQueryRulesByBudgetFlowItems
//   * DocumentKind - CatalogRef.MetadataObjectIDs
// Returns:
//  Array of CatalogRef.MetadataObjectIDs
//
Function DetermineTypesOfDCSDocuments(RuleDescription_, DocumentNameCache = Undefined) Export
	
	If TypeOf(RuleDescription_) = Type("CatalogObject.ActualDataQueryRulesByBudgetFlowItems") Then
		Query = New Query;
		Query.Text =
		"SELECT
			|	DocumentNameCacheForProcessingByRule.DocumentKind AS DocumentKind
			|FROM
			|	InformationRegister.DocumentNameCacheForProcessingByRule AS DocumentNameCacheForProcessingByRule
			|WHERE
			|	DocumentNameCacheForProcessingByRule.Rule = &Rule";
		
		Query.SetParameter("Rule", RuleDescription_.Ref);
		DocumentsKindsArray = Query.Execute().Unload().UnloadColumn("DocumentKind");
		Rule = RuleDescription_.Ref;
		DataSource = RuleDescription_.DataSource;
	Else
		DocumentsKindsArray = DocumentNameCache.Copy(New Structure("Rule", RuleDescription_.Rule), "DocumentKind").UnloadColumn("DocumentKind");
		Rule = RuleDescription_.Rule;
		DataSource = RuleDescription_.DataSourceXO;
	EndIf;
	
	If DocumentsKindsArray.Count() Then
		Return DocumentsKindsArray;
	EndIf;
	
	If RuleDescription_.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
		And GetFunctionalOption("SettingUpRulesForObtainingFactsFromCorrespondingRegisters")
		And (Not GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems")
		Or RuleDescription_.RuleType <> Enums.ActualBudgetingDataQueryRuleType.ActualData) Then
		DocumentsKindsArray = DataSourcesServer.ArrayOfTypesOfDocumentsByDataSource(DataSource);
		If RuleDescription_.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.AmountToBePaid
			Or RuleDescription_.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.AmountToBePaidWithinLimit
			Or RuleDescription_.TransactionAmountSource = Enums.IndicatorsOfAnalyticalRegisters.AmountToBePaidAboveLimit Then
			DocumentsKindsArray.Add(Common.MetadataObjectID(Metadata.Documents.ApplicationForBusinessTrip));
			DocumentsKindsArray.Add(Common.MetadataObjectID(Metadata.Documents.PaymentRequest));
		EndIf;
	Else
		DCS = DataSourcesServer.DataLayoutRules(RuleDescription_);
		If DCS = Undefined Then
			Return Undefined;
		EndIf;
		
		DocumentsKindsArray = New Array;
		For Each Set In DCS.DataSets Do
			If TypeOf(Set) <> Type("DataCompositionSchemaDataSetQuery") Then
				DocumentsKindsArray.Add(Catalogs.MetadataObjectIDs.EmptyRef());
				Break;
			Else
				MetadataOfDocumentTypes = New Array;
				QuerySchema = New QuerySchema;
				QuerySchema.SetQueryText(Set.Query);
				For Each QueryPackage In QuerySchema.QueryBatch Do
					If TypeOf(QueryPackage) = Type("QuerySchemaTableDropQuery") Then
						Continue;
					EndIf;
					For Each Column In QueryPackage.Columns Do
						If Lower(Column.Alias) <> Lower("Recorder") Then
							Continue;
						EndIf;
						For Each Type In Column.ValueType.Types() Do
							TypeMetadata = Metadata.FindByType(Type);
							If Common.IsDocument(TypeMetadata) Then
								MetadataOfDocumentTypes.Add(TypeMetadata);
							EndIf;
						EndDo;
					EndDo;
				EndDo;
				If MetadataOfDocumentTypes.Count() > 0 Then
					DocumentsKindsArray = TMCommonUseClientServer.ConvertMatchOrStructureToArray(
						Common.MetadataObjectIDs(MetadataOfDocumentTypes), False);
				EndIf;
			EndIf;
		EndDo;
		
		If Not DocumentsKindsArray.Count() Then
			DocumentsKindsArray.Add(Catalogs.MetadataObjectIDs.EmptyRef());
		EndIf;
		
	EndIf;
	
	DocumentsKinds = New ValueTable;
	DocumentsKinds.Columns.Add("Rule");
	DocumentsKinds.Columns.Add("DocumentKind");
	
	For Each DocumentKind In DocumentsKindsArray Do
		NewRow = DocumentsKinds.Add();
		NewRow.DocumentKind = DocumentKind;
		NewRow.Rule = Rule;
	EndDo;
	
	DocumentsKinds.GroupBy("Rule, DocumentKind", "");
	
	RecordSet = InformationRegisters.DocumentNameCacheForProcessingByRule.CreateRecordSet();
	RecordSet.Filter.Rule.Set(Rule);
	RecordSet.Load(DocumentsKinds);
	RecordSet.Write();
	
	Return DocumentsKinds.UnloadColumn("DocumentKind");
	
EndFunction

// Generates Registered Records according to the register of actual data budgeting according to the table of documents
//
// Parameters:
//  DocumentsForProcessing_ - ValueTable:
//   *JobNumber - Number
//   *Document - DocumentRef
//   *DocumentKind - CatalogRef.MetadataObjectIDs - type of document
//  ProcessedDocumentsCount - Number - performance measurement counter
//  DocumentsKinds - Array of CatalogRef.MetadataObjectIDs, Undefined
//  Rule - Reference link.Rules for receiving actual data of the State budgets, undetermined
//
Procedure GenerateRegisteredRecordsBasedOnBudgetingFactRegister(DocumentsForProcessing_, ProcessedDocumentsCount, Val DocumentsKinds = Undefined, Rule = Undefined)
	
	Query = New Query;
	Query.Text =
	"SELECT
		|	DocumentNameCacheForProcessingByRule.Rule,
		|	DocumentNameCacheForProcessingByRule.DocumentKind AS DocumentKind
		|FROM
		|	InformationRegister.DocumentNameCacheForProcessingByRule AS DocumentNameCacheForProcessingByRule
		|WHERE
		|	&RuleCondition";
	If ValueIsFilled(Rule) Then
		Query.Text = StrReplace(Query.Text, "&RuleCondition", "DocumentNameCacheForProcessingByRule.Rule = &Rule"); // Query-part
		Query.SetParameter("Rule", Rule);
	Else
		Query.Text = StrReplace(Query.Text, "&RuleCondition", "TRUE");
	EndIf;
	
	QueryResult = Query.Execute();
	DocumentNameCache = QueryResult.Unload();
	
	DocumentsForProcessing_.Indexes.Add("DocumentKind");
	DocumentsForProcessing_.Columns.Add("Comment", New TypeDescription("String"));
	DocumentsForProcessing_.Columns.Add("Error", New TypeDescription("Boolean"));
	DocumentsForProcessing_.Indexes.Add("Error");
	
	FactGettingParameters = ParametersForGettingFactByReportSettings();
	RecordAccessTable = BudgetingServer.FactTableTemplateForBudgetItems(FactGettingParameters);
	RecordAccessTable.Columns.Add("Rule");
	
	If ValueIsFilled(Rule) Then
		
		QueriesTexts = New Array;
		QueriesTexts.Add("
			|SELECT
			|	DocumentsForProcessing_.Document AS Document
			|INTO DocumentsForProcessing_
			|FROM
			|	&DocumentsForProcessing_ AS DocumentsForProcessing_
			|
			|INDEX BY
			|	Document");
		
		QueriesTexts.Add("
			|SELECT
			|	*
			|FROM
			|	AccumulationRegister.ActualBudgetingData AS ActualBudgetingData
			|		INNER JOIN DocumentsForProcessing_ AS DocumentsForProcessing_
			|		ON ActualBudgetingData.Recorder = DocumentsForProcessing_.Document
			|WHERE
			|	ActualBudgetingData.Rule <> &Rule");
		
		Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		Query.SetParameter("Rule", Rule);
		Query.SetParameter("DocumentsForProcessing_", DocumentsForProcessing_);
		
		TableOfRecordSetsByOtherRules = Query.Execute().Unload();
		TableOfRecordSetsByOtherRules.Indexes.Add("Recorder");
	
	EndIf;
	
	DCSRules = DataSourcesCached.GettingCatalogTemplate("ActualDataQueryRulesByBudgetFlowItems", "ActualDataQueryRules_");
	DCSRules = DataCompositionServer.CopyDataLayoutDiagram(DCSRules); // DataCompositionSchema -
	RecalculatedFields = New Map;
	RecalculatedFields.Insert("IndicatorExpressionAmountCurrency", """""");
	RecalculatedFields.Insert("IndicatorExpressionAmountCurrencyMan", """""");
	RecalculatedFields.Insert("IndicatorExpressionAmountCurrencyCompl", """""");
	RecalculatedFields.Insert("IndicatorExpressionAmountCorCurrency", """""");
	RecalculatedFields.Insert("IndicatorExpressionCount", """""");
	RecalculatedFields.Insert("AmountIndicatorExpressions", "Undefined");
	
	For Each FieldToEval In DCSRules.CalculatedFields Do
		OverridingExpression = RecalculatedFields.Get(FieldToEval.DataPath);
		If Not OverridingExpression = Undefined Then
			FieldToEval.Expression = OverridingExpression;
		EndIf;
	EndDo;
	
	Settings = DCSRules.DefaultSettings;
	
	FinancialReportingServer.SetFilter(Settings.Filter, "CachingOfRuleResults", True);
	FinancialReportingServer.SetFilter(Settings.Filter, "BudgetBalanceItem", , DataCompositionComparisonType.NotFilled);
	If ValueIsFilled(Rule) Then
		FinancialReportingServer.SetFilter(Settings.Filter, "Rule", Rule);
	EndIf;
	If (GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems")
		Or GetFunctionalOption("SettingUpRulesForObtainingFactsFromCorrespondingRegisters"))
		And Not GetFunctionalOption("ControllingLimitsBasedOnBudgetingData2_4") Then
		FinancialReportingServer.SetFilter(Settings.Filter, "Rule.RuleType",
			Enums.ActualBudgetingDataQueryRuleType.ActualData);
	EndIf;
	FinancialReportingServer.NewOrder(Settings, "TypeOfAccountingDataReceipt");
	FinancialReportingServer.NewOrder(Settings, "TypeOfAccountingDataExpense");
	FinancialReportingServer.NewOrder(Settings, "DataSourceXO");
	FinancialReportingServer.NewOrder(Settings, "ValidFrom");
	FinancialReportingServer.NewOrder(Settings, "ValidTo");
	
	RulesTable = FinancialReportingServer.UploadDCSResults(DCSRules, Settings); // ValueTable -
	
	RulesTable.Columns.Add("DataSourceObjectType");
	RulesTable.FillValues(Type("CatalogRef.ActualDataQueryRulesByBudgetFlowItems"), "DataSourceObjectType");
	
	DefineTypesOfDocuments = (DocumentsKinds = Undefined);
	DocumentsToBeProcessedAccordingToRule = Undefined;
	DocumentsToBeProcessedAccordingToRules = Undefined;
	CorrespondencesTable = Undefined;
	ParametersOfPreviousIteration = New Structure("DataSourceXO, ValidFrom, ValidTo, DocumentsKinds");
	
	ParametersOfFormationOfCorrespondenceRegisters = New Structure;
	
	If GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems") Then
		
		DocumentsToBeProcessedAccordingToRules = DocumentsForProcessing_.Copy();
		DocumentsToBeProcessedAccordingToRules.Columns.Add("Period", Common.DateTypeDetails(DateFractions.DateTime));
		DocumentsToBeProcessedAccordingToRules.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
		DocumentsToBeProcessedAccordingToRules.Columns.Add("BudgetFlowItem", New TypeDescription("CatalogRef.BudgetFlowItems"));
		DocumentsToBeProcessedAccordingToRules.Columns.Add("Rule", New TypeDescription("CatalogRef.ActualDataQueryRulesByBudgetFlowItems"));
		
		FactOnItemsOfAssetsLiabilities = ActualBudgetingDataByAssetAndLiabilityItems.ActualDataOfOperationalAccounting(
			DocumentsToBeProcessedAccordingToRules, FactGettingParameters, RulesTable);
			
	ElsIf GetFunctionalOption("SettingUpRulesForObtainingFactsFromCorrespondingRegisters") Then
		
		RulesTable.Columns.Add("CorrespondencesTable");
		
		ParametersOfFormationOfCorrespondenceRegisters.Insert("TempTablesManager", New TempTablesManager);;
		ParametersOfFormationOfCorrespondenceRegisters.Insert("VATRegisters", New Array);
		ParametersOfFormationOfCorrespondenceRegisters.Insert("RegistersWithoutManSum", New Array);
		ParametersOfFormationOfCorrespondenceRegisters.Insert("RegistersWithoutSumLocal", New Array);
		ParametersOfFormationOfCorrespondenceRegisters.Insert("FillParameters", CorrespondenceFillingParameters());
		ParametersOfFormationOfCorrespondenceRegisters.Insert("StructureOfAnalyticsTables", New Structure);
		
		DocumentsForProcessing_.Columns.Add("Period", New TypeDescription("Date", , , New DateQualifiers(DateFractions.DateTime)));
		DocumentsForProcessing_.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
		
	EndIf;
	
	For Each RuleDescription_ In RulesTable Do
		
		If DefineTypesOfDocuments Then
			DocumentsKinds = DetermineTypesOfDCSDocuments(RuleDescription_, DocumentNameCache);
		EndIf;
		
		If DocumentsKinds = Undefined Then
			DefaultLanguageCode = Common.DefaultLanguageCode();
			LREvent = NStr("vi = 'Quy tắc lập ngân sách không được thực thi';
							|ru = 'Не выполнено правило бюджетирования';
							|en = 'Budgeting rule is not executed'; fa = 'Budgeting rule is not executed';
							|it = 'Regola di budgeting non eseguita';
							|pl = 'Nie jest spełniona zasada budżetowania';
							|tr = 'Bütçeleme kuralı tamamlanmamış'", DefaultLanguageCode);
			MessageText = NStr("vi = 'Chưa thực hiện quy tắc lập ngân sách, bởi vì không xác định sơ đồ dàn dựng dữ liệu của nhận dữ liệu';
								|ru = 'Не выполнено правило бюджетирования, т.к. не определена СКД получения данных';
								|en = 'Budgeting rule is not executed as data receipt DCS is not determined'; fa = 'Budgeting rule is not executed as data receipt DCS is not determined';
								|it = 'Regola di budgeting non eseguita, poiché non è definito un Sistema di Composizione dei Dati (SKD) per la ricezione dei dati';
								|pl = 'Nie jest spełniona zasada budżetowania, ponieważ nie masz SKD uzyskania danych';
								|tr = 'Veri alımında kullanılan Veri Oluşturma Sistemi belirtilmediği için bütçeleme kuralı tamamlanmamış'", DefaultLanguageCode);
			WriteLogEvent(
				LREvent,,,
				RuleDescription_.Rule,
				MessageText);
			Continue;
		EndIf;
		
		If ParametersOfPreviousIteration.DocumentsKinds = Undefined
			Or Not TMCommonUseClientServer.ArraysAreEqual(DocumentsKinds, ParametersOfPreviousIteration.DocumentsKinds, False) Then
			TheStructureOfTheSearch = New Structure("Error", False);
			If DocumentsKinds.Find(Catalogs.MetadataObjectIDs.EmptyRef()) <> Undefined Then
				DocumentsToBeProcessedAccordingToRule = DocumentsForProcessing_.Copy(TheStructureOfTheSearch);
			Else
				DocumentsToBeProcessedAccordingToRule = DocumentsForProcessing_.CopyColumns();
				For Each DocumentKind In DocumentsKinds Do
					TheStructureOfTheSearch.Insert("DocumentKind", DocumentKind);
					FoundRows = DocumentsForProcessing_.FindRows(TheStructureOfTheSearch);
					For Each FoundRow In FoundRows Do
						NewRow = DocumentsToBeProcessedAccordingToRule.Add();
						FillPropertyValues(NewRow, FoundRow);
					EndDo;
				EndDo;
			EndIf;
			ParametersOfPreviousIteration.DocumentsKinds = Common.CopyRecursive(DocumentsKinds);
		EndIf;
		
		NumberOfDocumentsToBeProcessed = DocumentsToBeProcessedAccordingToRule.Count();
		If NumberOfDocumentsToBeProcessed = 0 Then
			// There are no documents to be processed according to the rule
			Continue;
		EndIf;
		
		FactGettingParameters = ParametersForGettingFactByReportSettings(RuleDescription_);
		
		If RuleDescription_.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
			And RuleDescription_.RuleType = Enums.ActualBudgetingDataQueryRuleType.ActualData
			And GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems") Then
			Continue;
		ElsIf RuleDescription_.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
			And ParametersOfFormationOfCorrespondenceRegisters.Property("TempTablesManager")
			And Not DataSourcesCached.UsedSKD_BudgetExecution(RuleDescription_.TransactionAmountSource,
			RuleDescription_.TypeOfAccountingDataExpense) Then
			If RuleDescription_.DataSourceXO = ParametersOfPreviousIteration.DataSourceXO
				And RuleDescription_.ValidFrom = ParametersOfPreviousIteration.ValidFrom
				And RuleDescription_.ValidTo = ParametersOfPreviousIteration.ValidTo Then
				If CorrespondencesTable <> Undefined Then
					RuleDescription_.CorrespondencesTable = CorrespondencesTable.Copy();
				EndIf;
			Else
				CorrespondencesTable = GetTableOfCorrespondenceOfBalanceRegisters(
					DocumentsToBeProcessedAccordingToRule, FactGettingParameters, RuleDescription_, ParametersOfFormationOfCorrespondenceRegisters);
				If CorrespondencesTable = Undefined Then
					If DocumentsToBeProcessedAccordingToRule.Find(Common.MetadataObjectID(
						Metadata.Documents.MovementOfOtherAssetsAndLiabilities), "DocumentKind") <> Undefined
						And (RuleDescription_.TypeOfAccountingDataReceipt = Enums.AccountingDataTypes.OtherAssetsLiabilities
						Or RuleDescription_.TypeOfAccountingDataExpense = Enums.AccountingDataTypes.OtherAssetsLiabilities) Then
						CorrespondencesTable = GetTableOfCorrespondenceOfOtherAssetsLiabilities(
						DocumentsToBeProcessedAccordingToRule, FactGettingParameters, RuleDescription_);
					EndIf;
				EndIf;
				If CorrespondencesTable <> Undefined Then
					RuleDescription_.CorrespondencesTable = CorrespondencesTable.Copy();
				EndIf;
				FillPropertyValues(ParametersOfPreviousIteration, RuleDescription_);
			EndIf;
			// There may have been correspondence errors - they need to be fixed for investigation
			TheStructureOfTheSearch = New Structure("Error", True);
			For Each LineDocument In DocumentsToBeProcessedAccordingToRule.FindRows(TheStructureOfTheSearch) Do
				If Not IsBlankString(LineDocument.Comment) Then
					NewRow = RecordAccessTable.Add();
					FillPropertyValues(NewRow, LineDocument);
					FillPropertyValues(NewRow, RuleDescription_);
					NewRow.Recorder = LineDocument.Document;
					NewRow.Currency = SettingsValueCached.ManagementAccountingCurrency();
				EndIf;
				DocumentsForProcessing_.Find(LineDocument.Document, "Document").Error = True;
				DocumentsToBeProcessedAccordingToRule.Delete(LineDocument);
			EndDo;
			If RuleDescription_.CorrespondencesTable = Undefined Then
				Continue;
			EndIf;
		Else
			DocumentsList = New ValueList;
			DocumentsList.LoadValues(DocumentsToBeProcessedAccordingToRule.UnloadColumn("Document"));
			DCSRules_ = DataSourcesServer.DataLayoutRules(RuleDescription_);
			DataCompositionSettings = DCSRules_.DefaultSettings;
			FinancialReportingServer.SetFilter(DataCompositionSettings.Filter, "Recorder",
				DocumentsList, DataCompositionComparisonType.InList);
			If RuleDescription_.NameOfTheDataSourceTemplate = "CashFlowToPayment" Then
				FinancialReportingServer.SetFilter(DataCompositionSettings.Filter, "DataSource",
				RuleDescription_.DataSource, DataCompositionComparisonType.Equal);
			EndIf;
			FactGettingParameters.AdditionalSelection = DataCompositionSettings;
		EndIf;
		
		// Let's prepare a fact table
		FactOnBudgetItems = BudgetingServer.FactTableTemplateForBudgetItems(FactGettingParameters);
	
		// We will get the fact in accordance with the rules
		BudgetingServer.FactOfArticleOfBudgetsAccordingToRule(RuleDescription_, FactGettingParameters, FactOnBudgetItems);
		
		// Duplicates of lines with the Budget Execution scenario should be deleted, since there is no Scenario dimension in the budget cache
		If RuleDescription_.RuleType
			= Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData Then
			LinesBudgetExecution = FactOnBudgetItems.FindRows(New Structure("Scenario",
				Catalogs.BudgetingScenarios.BudgetFulfillment));
			For Each LineBudgetExecution In LinesBudgetExecution Do
				FactOnBudgetItems.Delete(LineBudgetExecution);
			EndDo;
		EndIf;
		
		FactOnBudgetItems.Columns.Add("Rule");
		FactOnBudgetItems.FillValues(RuleDescription_.Rule, "Rule");
		
		CommonClientServer.SupplementTable(FactOnBudgetItems, RecordAccessTable);
		
		ProcessedDocumentsCount = ProcessedDocumentsCount + NumberOfDocumentsToBeProcessed;
		
	EndDo;
	
	If GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems") Then
		If FactOnItemsOfAssetsLiabilities.Count() > 0 Then
			CommonClientServer.SupplementTable(FactOnItemsOfAssetsLiabilities, RecordAccessTable);
		EndIf;
		
		// There may have been correspondence errors - they need to be fixed for investigation
		TheStructureOfTheSearch = New Structure("Error", True);
		Documents_With_Errors = DocumentsToBeProcessedAccordingToRules.FindRows(TheStructureOfTheSearch);
		
		For Each LineDocument In Documents_With_Errors Do
			If Not IsBlankString(LineDocument.Comment) Then
				NewRow = RecordAccessTable.Add();
				FillPropertyValues(NewRow, LineDocument);
				NewRow.Recorder = LineDocument.Document;
				NewRow.Currency = SettingsValueCached.ManagementAccountingCurrency();
			EndIf;
			
			TheStructureOfTheSearch = New Structure("Document", LineDocument.Document);
			NotProcessedDocuments = DocumentsForProcessing_.FindRows(TheStructureOfTheSearch);
			
			For Each RawDocument In NotProcessedDocuments Do
				RawDocument.Error = True;
				If Not IsBlankString(LineDocument.Comment) Then
					RawDocument.Comment = RawDocument.Comment
						+ ?(IsBlankString(RawDocument.Comment), "", Chars.LF)
						+ LineDocument.Comment;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	If ParametersOfFormationOfCorrespondenceRegisters.Property("TempTablesManager") Then
		ParametersOfFormationOfCorrespondenceRegisters.TempTablesManager.Close();
	EndIf;
	
	ConvertSetTableToRecord(RecordAccessTable);
	
	If ValueIsFilled(Rule) Then
		Counter = 0;
		While Counter < DocumentsForProcessing_.Count() Do
			If RecordAccessTable.Find(DocumentsForProcessing_[Counter].Document, "Recorder") = Undefined Then
				DocumentsForProcessing_.Delete(Counter);
			Else
				Counter = Counter + 1;
			EndIf;
		EndDo;
		CommonClientServer.SupplementTable(RecordAccessTable, TableOfRecordSetsByOtherRules);
		RecordAccessTable = TableOfRecordSetsByOtherRules;
	EndIf;
	
	For Each DocumentLine In DocumentsForProcessing_ Do
		
		If Not DocumentLine.Document.Metadata().RegisterRecords.Contains(
				Metadata.AccumulationRegisters.ActualBudgetingData) Then
			Continue;
		EndIf;
		
		RecordSet = AccumulationRegisters.ActualBudgetingData.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(DocumentLine.Document);
		LoggerRegisteredRecords = RecordAccessTable.FindRows(New Structure("Recorder", DocumentLine.Document));
		CommonClientServer.SupplementTable(LoggerRegisteredRecords, RecordSet);
		RecordSet.Write(True);
		
	EndDo;

EndProcedure

Procedure ConvertSetTableToRecord(RecordAccessTable)
	
	RecordAccessTable.Columns.Add("Active");
	RecordAccessTable.FillValues(True, "Active");
	RecordAccessTable.Indexes.Add("Recorder");
	
	For Each TableRow In RecordAccessTable Do
		If ValueIsFilled(TableRow.StorageCurrency) Then
			TableRow.Currency = TableRow.StorageCurrency;
			TableRow.AmountInCurrency = TableRow.AmountInStorageCurrency;
		ElsIf ValueIsFilled(TableRow.CurrencyFunctional) Then
			TableRow.Currency = TableRow.CurrencyFunctional;
		EndIf;
	EndDo;
	
EndProcedure

Function ParametersForGettingFactByReportSettings(RuleDescription_ = Undefined)
	
	Parameters = BudgetingServer.TemplateForGettingFactParameters();
	If RuleDescription_ <> Undefined Then
		BeginOfPeriod    = RuleDescription_.ValidFrom;
		PeriodEnding = RuleDescription_.ValidTo;
		If Not ValueIsFilled(PeriodEnding) Then
			// Setting the period end parameter for queries that have a physical register table as the data source.
			PeriodEnding = Date(3999, 12, 31, 23, 59, 59);
		EndIf;
		Parameters.Period = New StandardPeriod(BeginOfPeriod, PeriodEnding);
	EndIf;
	Parameters.ByCompanies = True;
	Parameters.ByBusinessUnits = True;
	Parameters.ByRegistrar = True;
	Parameters.ReturnManAndLocalAmounts = True;
	
	Parameters.Periodicity = Enums.Periodicity.Day;
	
	Return Parameters; 
	
EndFunction

Procedure ReflectDocumentsInBudgeting(BeginOfPeriod = Undefined, EndOfPeriod = Undefined,
	DocumentsKinds = Undefined, Rule = Undefined) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DocumentPostingInBudgeting);
	
	SetPrivilegedMode(True);
	
	Block = New DataLock;
	LockItem = Block.Add("Constant.NumberOfJobForPostingInBudgeting");
	LockItem.Mode = DataLockMode.Shared;
	
	BeginTransaction();
	
	Try
		Block.Lock();
		CurTaskNumber = Constants.NumberOfJobForPostingInBudgeting.Get();
		CommitTransaction();
	Except
		RollbackTransaction();
		LREvent = NStr("vi = 'Lập ngân sách';
						|ru = 'Бюджетирование';
						|en = 'Budgeting'; fa = 'بودجه‌بندی';
						|it = 'Budgeting';
						|pl = 'Budżetowanie';
						|tr = 'Bütçeleme'", Common.DefaultLanguageCode())
			+ "." + NStr("vi = 'Phản ánh sự kiện';
						|ru = 'Отражение факта';
						|en = 'Actual value record'; fa = 'Actual value record';
						|it = 'Riporto fatto';
						|pl = 'Odzwierciedlenie faktu';
						|tr = 'Bilgilerin yansıtılması'", Common.DefaultLanguageCode());
		WriteLogEvent(LREvent,
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Return;
	EndTry;

	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
		|	JobsForPostingInBudgeting.JobNumber,
		|	JobsForPostingInBudgeting.Document AS Document,
		|	JobsForPostingInBudgeting.RecordPeriod,
		|	JobsForPostingInBudgeting.DocumentKindName
		|FROM
		|	InformationRegister.JobsForPostingInBudgeting AS JobsForPostingInBudgeting
		|WHERE
		|	JobsForPostingInBudgeting.JobNumber = 0
		|TOTALS BY
		|	Document";
	
	Selection = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	If GetFunctionalOption("SettingUpRulesForObtainingFactsFromCorrespondingRegisters")
	 Or GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems") Then
		DocumentsForSettlement = New Array;
		While Selection.Next() Do
			DocumentsForSettlement.Add(Selection.Document);
		EndDo;
		PerformOfflineCalculations(DocumentsForSettlement, EndOfPeriod);
		Selection.Reset();
	EndIf;
	
	While Selection.Next() Do
		
		BeginTransaction();
		
		Try
			Block = New DataLock;
			LockItem = Block.Add();
			LockItem.Region = "InformationRegister.JobsForPostingInBudgeting";
			LockItem.SetValue("JobNumber", 0);
			LockItem.SetValue("Document",     Selection.Document);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			RecordSet = InformationRegisters.JobsForPostingInBudgeting.CreateRecordSet();
			RecordSet.Filter.JobNumber.Set(0);
			RecordSet.Filter.Document.Set(Selection.Document);
			RecordSet.Write();
			
			RecordSet = InformationRegisters.JobsForPostingInBudgeting.CreateRecordSet();
			RecordSet.Filter.JobNumber.Set(CurTaskNumber);
			RecordSet.Filter.Document.Set(Selection.Document);
			
			SelectionDetailRecords = Selection.Select(QueryResultIteration.ByGroupsWithHierarchy);

			While SelectionDetailRecords.Next() Do
				Record = RecordSet.Add();
				FillPropertyValues(Record,SelectionDetailRecords);
				Record.JobNumber = CurTaskNumber;
			EndDo;
			
			If RecordSet.Count() > 0 Then
				RecordSet.Write();
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			LREvent = NStr("vi = 'Lập ngân sách';
							|ru = 'Бюджетирование';
							|en = 'Budgeting'; fa = 'بودجه‌بندی';
							|it = 'Budgeting';
							|pl = 'Budżetowanie';
							|tr = 'Bütçeleme'", Common.DefaultLanguageCode())
				+ "." + NStr("vi = 'Phản ánh sự kiện';
							|ru = 'Отражение факта';
							|en = 'Actual value record'; fa = 'Actual value record';
							|it = 'Riporto fatto';
							|pl = 'Odzwierciedlenie faktu';
							|tr = 'Bilgilerin yansıtılması'", Common.DefaultLanguageCode());
			WriteLogEvent(LREvent,
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Continue;
		EndTry;

	EndDo;
	
	PartialReflectionOfDocuments = BeginOfPeriod <> Undefined Or EndOfPeriod <> Undefined;
	
	BeginTransaction();
	
	Try
	
		Block = New DataLock;
		LockItem = Block.Add("Constant.NumberOfJobForPostingInBudgeting");
		LockItem.Mode = DataLockMode.Exclusive;
		
		Block.Lock();
		CurTaskNumber = Constants.NumberOfJobForPostingInBudgeting.Get();
		
		Query = New Query;
		If PartialReflectionOfDocuments Then
			TempTablesManager = New TempTablesManager;
			PlaceDocumentsForReflectionInTemporaryTable(BeginOfPeriod, EndOfPeriod, TempTablesManager, DocumentsKinds);
			Query.TempTablesManager = TempTablesManager;
		EndIf;
		
		Query.Text =
		"SELECT
			|	MIN(JobsForPostingInBudgeting.JobNumber) AS JobNumber
			|INTO TaskToProcess
			|FROM
			|	InformationRegister.JobsForPostingInBudgeting AS JobsForPostingInBudgeting
			|WHERE
			|	JobsForPostingInBudgeting.JobNumber <= &JobNumber AND JobsForPostingInBudgeting.JobNumber <> 0
			|	AND &FilterForDocuments
			|INDEX BY
			|	JobNumber
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT TOP 10001
			|	JobsForPostingInBudgeting.Document,
			|	JobsForPostingInBudgeting.JobNumber,
			|	MetadataObjectIDs.Ref AS DocumentKind
			|FROM
			|	TaskToProcess AS TaskToProcess
			|		LEFT JOIN InformationRegister.JobsForPostingInBudgeting AS JobsForPostingInBudgeting
			|		ON TaskToProcess.JobNumber = JobsForPostingInBudgeting.JobNumber
			|		INNER JOIN Catalog.MetadataObjectIDs AS MetadataObjectIDs
			|		ON JobsForPostingInBudgeting.DocumentKindName = MetadataObjectIDs.Name
			|WHERE
			|	NOT JobsForPostingInBudgeting.JobNumber IS NULL
			|	AND MetadataObjectIDs.Parent IN
			|		(SELECT TOP 1
			|			ParentsOfMetadataObjects.Ref
			|		FROM
			|			Catalog.MetadataObjectIDs AS ParentsOfMetadataObjects
			|		WHERE
			|			ParentsOfMetadataObjects.Parent = VALUE(Catalog.MetadataObjectIDs.EmptyRef)
			|			AND ParentsOfMetadataObjects.Name = &Documents
			|		)
			|	AND &FilterForDocuments";
			
		If PartialReflectionOfDocuments Then
			Query.Text = StrReplace(Query.Text, "&FilterForDocuments", "Document IN (SELECT Document FROM DocumentsToBeReflected)");
		Else
			Query.Text = StrReplace(Query.Text, "&FilterForDocuments", "TRUE");
		EndIf;
		
		If GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems") Then
			Query.Text = StrReplace(Query.Text, "TOP 10001", "TOP 1001");
			NumberOfDocumentsPerServing = 1001;
		Else
			NumberOfDocumentsPerServing = 10001;
		EndIf;
		
		Query.SetParameter("JobNumber", CurTaskNumber);
		Query.SetParameter("Documents", "Documents");
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty()
		 Or CurTaskNumber = 0 Then
			CurTaskNumber = CurTaskNumber + 1;
			Constants.NumberOfJobForPostingInBudgeting.Set(CurTaskNumber);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		LREvent = NStr("vi = 'Lập ngân sách';
						|ru = 'Бюджетирование';
						|en = 'Budgeting'; fa = 'بودجه‌بندی';
						|it = 'Budgeting';
						|pl = 'Budżetowanie';
						|tr = 'Bütçeleme'", Common.DefaultLanguageCode())
			+ "." + NStr("vi = 'Phản ánh sự kiện';
						|ru = 'Отражение факта';
						|en = 'Actual value record'; fa = 'Actual value record';
						|it = 'Riporto fatto';
						|pl = 'Odzwierciedlenie faktu';
						|tr = 'Bilgilerin yansıtılması'", Common.DefaultLanguageCode());
		WriteLogEvent(LREvent,
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	
		Return;
	EndTry;
	
	If QueryResult.IsEmpty() And CurTaskNumber <> 0 Then
		Return;
	EndIf;
	
	ThereIsSomethingToProcess = True;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("CommonModule.ActualBudgetingDataServer.ReflectDocumentsInBudgeting");
	TotalNumberOfProcessedDocuments = 0;
	
	While ThereIsSomethingToProcess Do
		
		DocumentsForProcessing_ = QueryResult.Unload();
		BatchBeingProcessed = DocumentsForProcessing_.Count() = NumberOfDocumentsPerServing;
		
		ProcessedDocumentsCount = 0;
		GenerateRegisteredRecordsBasedOnBudgetingFactRegister(DocumentsForProcessing_, ProcessedDocumentsCount, DocumentsKinds, Rule);
		TotalNumberOfProcessedDocuments = TotalNumberOfProcessedDocuments + ProcessedDocumentsCount;
		
		RecordSet = InformationRegisters.JobsForPostingInBudgeting.CreateRecordSet();
		If BatchBeingProcessed Or PartialReflectionOfDocuments Then
			
			BeginTransaction();

			Try
				
				For Each DocumentLine In DocumentsForProcessing_ Do
								
					Block = New DataLock;
					LockItem = Block.Add();
					LockItem.Region = "InformationRegister.JobsForPostingInBudgeting";
					LockItem.SetValue("JobNumber",	DocumentLine.JobNumber);
					LockItem.SetValue("Document",		DocumentLine.Document);
					LockItem.Mode = DataLockMode.Exclusive;
					Block.Lock();
				
					RecordSet.Filter.JobNumber.Set(DocumentLine.JobNumber);
					RecordSet.Filter.Document.Set(DocumentLine.Document);
					RecordSet.Write();				
							
				EndDo;
				
				CommitTransaction();
				
			Except
				RollbackTransaction();
				LREvent = NStr("vi = 'Lập ngân sách';
								|ru = 'Бюджетирование';
								|en = 'Budgeting'; fa = 'بودجه‌بندی';
								|it = 'Budgeting';
								|pl = 'Budżetowanie';
								|tr = 'Bütçeleme'", Common.DefaultLanguageCode())
					+ "." + NStr("vi = 'Phản ánh sự kiện';
								|ru = 'Отражение факта';
								|en = 'Actual value record'; fa = 'Actual value record';
								|it = 'Riporto fatto';
								|pl = 'Odzwierciedlenie faktu';
								|tr = 'Bilgilerin yansıtılması'", Common.DefaultLanguageCode());
				WriteLogEvent(LREvent,
					EventLogLevel.Error,,,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, TotalNumberOfProcessedDocuments);
				Return;
			EndTry;
		
		Else
			
			BeginTransaction();
			
			Try
				Block = New DataLock;
				LockItem = Block.Add();
				LockItem.Region = "InformationRegister.JobsForPostingInBudgeting";
				LockItem.SetValue("JobNumber", DocumentsForProcessing_[0].JobNumber);
				LockItem.Mode = DataLockMode.Exclusive;
				Block.Lock();
				
				RecordSet.Filter.JobNumber.Set(DocumentsForProcessing_[0].JobNumber);
				RecordSet.Write();
				
				CommitTransaction();
			Except
				RollbackTransaction();
				LREvent = NStr("vi = 'Lập ngân sách';
								|ru = 'Бюджетирование';
								|en = 'Budgeting'; fa = 'بودجه‌بندی';
								|it = 'Budgeting';
								|pl = 'Budżetowanie';
								|tr = 'Bütçeleme'", Common.DefaultLanguageCode())
					+ "." + NStr("vi = 'Phản ánh sự kiện';
								|ru = 'Отражение факта';
								|en = 'Actual value record'; fa = 'Actual value record';
								|it = 'Riporto fatto';
								|pl = 'Odzwierciedlenie faktu';
								|tr = 'Bilgilerin yansıtılması'", Common.DefaultLanguageCode());
				WriteLogEvent(LREvent,
					EventLogLevel.Error,,,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, TotalNumberOfProcessedDocuments);
				Return;
			EndTry;

		EndIf;
		
		If PartialReflectionOfDocuments Then
			TempTablesManager.Close();
			TempTablesManager = New TempTablesManager;
			PlaceDocumentsForReflectionInTemporaryTable(BeginOfPeriod, EndOfPeriod, TempTablesManager);
			Query.TempTablesManager = TempTablesManager;
		EndIf;
		
		QueryResult = Query.Execute();
		ThereIsSomethingToProcess = Not QueryResult.IsEmpty();
		
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, TotalNumberOfProcessedDocuments);
	
EndProcedure

Function ThereAreStoredItemRulesForBudgetView(BudgetProfile)
	Query = New Query;
	Query.SetParameter("BudgetProfile", BudgetProfile);
	Query.Text = 
	"SELECT
	|	CASE
	|		WHEN BudgetProfilesItemAndIndicatorCache.ItemIndicator REFS Catalog.BudgetFlowItems
	|			THEN ""BudgetFlowItems""
	|		WHEN BudgetProfilesItemAndIndicatorCache.ItemIndicator REFS Catalog.BudgetBalanceItems
	|			THEN ""BudgetBalanceItems""
	|	END AS ObjectKind,
	|	BudgetProfilesItemAndIndicatorCache.ItemIndicator AS ItemIndicator
	|INTO BudgetItemsAndIndicators
	|FROM
	|	Catalog.BudgetProfiles.ItemAndIndicatorCache AS BudgetProfilesItemAndIndicatorCache
	|WHERE
	|	BudgetProfilesItemAndIndicatorCache.Ref = &BudgetProfile
	|	AND (BudgetProfilesItemAndIndicatorCache.ItemIndicator REFS Catalog.BudgetFlowItems
	|			OR BudgetProfilesItemAndIndicatorCache.ItemIndicator REFS Catalog.BudgetBalanceItems)
	|
	|INDEX BY
	|	ObjectKind,
	|	ItemIndicator
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ActualDataQueryRulesByBudgetFlowItems.CachingOfRuleResults AS CachingOfRuleResults
	|FROM
	|	BudgetItemsAndIndicators AS BudgetItemsAndIndicators
	|		INNER JOIN Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
	|		ON (BudgetItemsAndIndicators.ObjectKind = ""BudgetFlowItems"")
	|			AND BudgetItemsAndIndicators.ItemIndicator = ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem
	|WHERE
	|	ActualDataQueryRulesByBudgetFlowItems.CachingOfRuleResults
	|
	|UNION ALL
	|
	|SELECT
	|	ActualDataQueryRulesByBudgetFlowItems.CachingOfRuleResults
	|FROM
	|	BudgetItemsAndIndicators AS BudgetItemsAndIndicators
	|		INNER JOIN Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|		ON (BudgetItemsAndIndicators.ObjectKind = ""BudgetBalanceItems"")
	|			AND BudgetItemsAndIndicators.ItemIndicator = CalculationsRules.Receiver
	|			AND (NOT CalculationsRules.DeletionMark)
	|			AND (CalculationsRules.Status = VALUE(Enum.BudgetingRuleStatuses.Valid))
	|		INNER JOIN Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
	|		ON (CalculationsRules.Source = ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem)
	|WHERE
	|	ActualDataQueryRulesByBudgetFlowItems.CachingOfRuleResults";
	
	Result = Query.Execute();
	ThereAreStoredRules = Not Result.IsEmpty();
	
	Return ThereAreStoredRules;
EndFunction

Function ThereAreStoredRulesOfArticlesAndIndicators(BudgetFlowItem, BudgetBalanceItem)
	Query = New Query;
	Query.SetParameter("BudgetFlowItem", BudgetFlowItem);
	Query.SetParameter("BudgetBalanceItem", BudgetBalanceItem);
	Query.Text = 
	"SELECT
	|	ActualDataQueryRulesByBudgetFlowItems.CachingOfRuleResults AS CachingOfRuleResults
	|FROM
	|	Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
	|WHERE
	|	ActualDataQueryRulesByBudgetFlowItems.CachingOfRuleResults
	|	AND ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem = &BudgetFlowItem
	|
	|UNION ALL
	|
	|SELECT
	|	ActualDataQueryRulesByBudgetFlowItems.CachingOfRuleResults
	|FROM
	|	Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS CalculationsRules
	|		INNER JOIN Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
	|		ON CalculationsRules.Source = ActualDataQueryRulesByBudgetFlowItems.BudgetFlowItem
	|			AND (NOT CalculationsRules.DeletionMark)
	|			AND (CalculationsRules.Status = VALUE(Enum.BudgetingRuleStatuses.Valid))
	|WHERE
	|	CalculationsRules.Receiver = &BudgetBalanceItem
	|	AND ActualDataQueryRulesByBudgetFlowItems.CachingOfRuleResults
	|	AND (CalculationsRules.Source = &BudgetFlowItem
	|			OR &BudgetFlowItem = UNDEFINED)";
	
	Result = Query.Execute();
	ThereAreStoredRules = Not Result.IsEmpty();
	
	Return ThereAreStoredRules;
EndFunction

Procedure DeduceRelevanceOfReflectionOfActualData(ResultDocument, AuxProperties, CheckActiveTasks) Export
	
	NeedInscription = AuxProperties.Property("NumberOfDocumentsToBeReflectedInBudgeting");
	
	If CheckActiveTasks Then
		Var_Key = "DocumentPostingInBudgeting";
		
		Filter = New Structure();
		Filter.Insert("Key", Var_Key);
		Filter.Insert("State", BackgroundJobState.Active);
		
		ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
		
		If ActiveTasks.Count() = 0 Then
			NeedInscription = False;
		EndIf;
	EndIf;
	
	If NeedInscription Then
		BudgetProfile = Undefined;
		BudgetFlowItem = Undefined;
		BudgetBalanceItem = Undefined;
		If AuxProperties.Property("CheckingStoredRulesBudgetView", BudgetProfile) Then
			NeedInscription = ThereAreStoredItemRulesForBudgetView(BudgetProfile);
		Else
			AuxProperties.Property("CheckingStoredRulesAndBudgets_", BudgetFlowItem);
			AuxProperties.Property("CheckingStoredRulesAndBudgets", BudgetBalanceItem);
			If BudgetFlowItem <> Undefined Or BudgetBalanceItem <> Undefined Then
				NeedInscription = ThereAreStoredRulesOfArticlesAndIndicators(BudgetFlowItem, BudgetBalanceItem);
			EndIf;
		EndIf;
	EndIf;
	
	If NeedInscription Then
		WarningTable_ = New SpreadsheetDocument;
		AreaWarning = WarningTable_.Area(1,1,1,1);
		PieceOfText = New Array;
		PieceOfText.Add(NStr("vi = 'Đang chờ ghi vào ngân sách %1 chứng từ .';
							|ru = 'Отражения в бюджетировании ожидает %1 документов.';
							|en = '%1 documents await recording in budgeting.'; fa = '%1 documents await recording in budgeting.';
							|it = 'La riflessione nel budgeting richiede %1 documenti.';
							|pl = 'Odbicia budżetowania czeka %1 dokumentów.';
							|tr = 'Bütçelemenin yansıtılması %1 belge bekliyor.'"));
		If CheckActiveTasks Then
			PieceOfText.Add(NStr("vi = 'Nhiệm vụ phân phối từ %2 đến %3 đã được đưa ra.';
								|ru = 'Запущено задание по распределению расчетов с %2 по %3.';
								|en = 'Job for allocating settlements from %2 to %3 is started.'; fa = 'Job for allocating settlements from %2 to %3 is started.';
								|it = 'Task per la distribuzione dei pagamenti da %2 a %3 avviato.';
								|pl = 'Uruchomione zadanie do spraw rozliczeń z %2 po %3.';
								|tr = 'Rapor dağılımına göre %2 itibarıyla %3 tarihine kadar görev başlatıldı.'"));
			PieceOfText.Add(NStr("vi = 'Bạn sẽ được đề nghị tạo lại báo cáo sau khi ghi.';
								|ru = 'После отражения Вам будет предложено переформировать отчет.';
								|en = 'You will be offered to rebuild the report after recording.'; fa = 'You will be offered to rebuild the report after recording.';
								|it = 'Dopo la riflessione, Vi sarà proposto di creare nuovamente il report.';
								|pl = 'Po odbiciu zostanie wyświetlony monit o ponownym formowaniu raportu.';
								|tr = 'Yansıtıldıktan sonra raporun tekrar oluşturmanızı öneririz.'"));
		Else
			PieceOfText.Add(NStr("vi = 'Cần khởi động nhiệm vụ về phản ánh trong kỳ từ %2 đến %3.';
								|ru = 'Необходимо запустить задание по отражению за период с %2 по %3.';
								|en = 'Start the job of recording from %2 to %3.'; fa = 'Start the job of recording from %2 to %3.';
								|it = 'Необходимо запустить задание по отражению за период с %2 по %3.';
								|pl = 'Start the job of recording from %2 to %3.';
								|tr = 'Необходимо запустить задание по отражению за период с %2 по %3.'"));
		EndIf;
		WarningText = StrConcat(PieceOfText, Chars.LF);
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			WarningText,
			AuxProperties.NumberOfDocumentsToBeReflectedInBudgeting,
			Format(AuxProperties.BeginOfPeriod, "DLF=D"),
			Format(AuxProperties.EndOfPeriod, "DLF=D"));
		AreaWarning.Text = WarningText;
		AreaWarning.TextColor = StyleColors.NegativeTextColor;
		If CheckActiveTasks Then
			AreaHeight = 1;
		Else
			HyperlinkArea = WarningTable_.Area(2,1,2,1);
			HyperlinkArea.Text = NStr("vi = 'Hiển thị';
										|ru = 'Отразить';
										|en = 'Record'; fa = 'ثبت';
										|it = 'Отразить';
										|pl = 'Record';
										|tr = 'Отразить'");
			HyperlinkArea.TextColor = StyleColors.HyperlinkColor;
			HyperlinkArea.Font = New Font(HyperlinkArea.Font,,,,,True);
			HyperlinkArea.Hyperlink = True;
			AreaHeight = 2;
		EndIf;
		ResultDocument.InsertArea(WarningTable_.Area(1, , AreaHeight, ),
			ResultDocument.Area(1, , AreaHeight, ), SpreadsheetDocumentShiftType.Vertical);
	Else
		AuxProperties.Delete("NumberOfDocumentsToBeReflectedInBudgeting");
		AuxProperties.Delete("BeginOfPeriod");
		AuxProperties.Delete("EndOfPeriod");
	EndIf;
	
EndProcedure

Procedure PlaceDocumentsForReflectionInTemporaryTable(Val BeginOfPeriod, Val EndOfPeriod, TempTablesManager, DocumentsKinds = Undefined) Export
	
	Query = New Query("SELECT DISTINCT
		|	Jobs.Document AS Document
		|INTO PeriodDocuments
		|FROM
		|	InformationRegister.JobsForPostingInBudgeting AS Jobs
		|WHERE
		|	Jobs.RecordPeriod BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Jobs.DocumentKindName IN (&NamesOfDocumentTypes)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Jobs.Document
		|INTO DocumentsWithEmptyPeriod
		|FROM
		|	InformationRegister.JobsForPostingInBudgeting AS Jobs
		|WHERE
		|	Jobs.RecordPeriod = DATETIME(1, 1, 1)
		|	AND Jobs.DocumentKindName IN (&NamesOfDocumentTypes)
		|
		|INDEX BY
		|	Jobs.Document
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	DocumentsWithEmptyPeriod.Document AS Document
		|INTO DocumentsToBeReflected
		|FROM
		|	DocumentsWithEmptyPeriod AS DocumentsWithEmptyPeriod
		|		LEFT JOIN AccumulationRegister.ActualBudgetingData AS ActualBudgetingData
		|		ON DocumentsWithEmptyPeriod.Document = ActualBudgetingData.Recorder
		|WHERE
		|	ActualBudgetingData.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|
		|UNION
		|
		|SELECT
		|	PeriodDocuments.Document
		|FROM
		|	PeriodDocuments AS PeriodDocuments");
	
	Query.TempTablesManager = TempTablesManager;
	
	If Not ValueIsFilled(BeginOfPeriod) Then
		BeginOfPeriod = Date(1,1,1);
	EndIf;

	If Not ValueIsFilled(EndOfPeriod) Then
		EndOfPeriod = Date(3999, 12, 31, 23, 59, 59);
	EndIf;
	
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	
	If DocumentsKinds <> Undefined Then
		Query.SetParameter("NamesOfDocumentTypes",
			TMCommonUseClientServer.ConvertMatchOrStructureToArray(
			Common.ObjectsAttributeValue(DocumentsKinds, "Name"), False));
	Else
		Query.Text = StrReplace(Query.Text, "Jobs.DocumentKindName IN (&NamesOfDocumentTypes)", "TRUE");
	EndIf;
	
	Query.Execute();
	
EndProcedure

Procedure ReflectDocumentsAsBackgroundTask(BeginOfPeriod = Undefined, EndOfPeriod = Undefined, WaitForExecution = True) Export
	
	SetPrivilegedMode(True);
	
	Var_Key = "DocumentPostingInBudgeting" + "_" + TrimAll(New UUID);
	
	Filter = New Structure();
	Filter.Insert("Key", Var_Key);
	Filter.Insert("State", BackgroundJobState.Active);
	
	ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	
	If ActiveTasks.Count() > 0 Then
		Return;
	EndIf;
	
	JobDescription = NStr("vi = 'Đang thực hiện phản ánh chứng từ trong việc lập ngân sách';
							|ru = 'Выполняется отражение документов в бюджетировании';
							|en = 'Recording documents in budgeting'; fa = 'Recording documents in budgeting';
							|it = 'Riflessione dei documenti nel budgeting in corso.';
							|pl = 'Wykonywane odbicie dokumentów w budżetowaniu';
							|tr = 'Bütçelemede belgenin yansıtılması gerçekleştiriliyor'");
	
	ExportProcedureParameters = New Array();
	ExportProcedureParameters.Add(BeginOfPeriod);
	ExportProcedureParameters.Add(EndOfPeriod);
	
	JobParameters = New Array();
	JobParameters.Add("ActualBudgetingDataServer.ReflectDocumentsInBudgeting");
	JobParameters.Add(ExportProcedureParameters);
	
	If Common.FileInfobase() Then
		Try
			// The file database has a restriction on getting a list of background tasks.
			BackgroundJob = BackgroundJobs.Execute("Common.ExecuteConfigurationMethod", JobParameters, Var_Key, JobDescription);
		Except
			Return;
		EndTry;
	Else
		BackgroundJob = BackgroundJobs.Execute("Common.ExecuteConfigurationMethod", JobParameters, Var_Key, JobDescription);
	EndIf;
	
	If WaitForExecution Then
		Try
			BackgroundJob.WaitForCompletion(1);
		Except
			LREvent = NStr("vi = 'Đang thực hiện phản ánh chứng từ trong việc lập ngân sách';
							|ru = 'Выполнение отражения документов в бюджетировании';
							|en = 'Post the documents in budgeting'; fa = 'Post the documents in budgeting';
							|it = 'Esecuzione della riflessione dei documenti nel budgeting';
							|pl = 'Wykonanie odbicia dokumentów w budżetowaniu';
							|tr = 'Bütçelemede belgenin yansıtılması gerçekleştiriliyor'", Common.DefaultLanguageCode());
			WriteLogEvent(LREvent,
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
EndProcedure

#Region FactAccordingToCorrespondenceOfResidualFinancialRegisters

// Returns a fact table based on the results of correspondence between balance registers.
//
// Parameters:
//  DocumentsForProcessing_ - ValueTable
//  FactGettingParameters - Structure - parameters for getting the fact, including:
//   * Period - StandardPeriod
//  RuleDescription_ - ValueTableRow:
//   * DataSourceXO - CatalogRef.BusinessTransactionsSettings
//   * TypeOfAccountingDataReceipt - EnumRef.AccountingDataTypes
//   * TypeOfAccountingDataExpense - EnumRef.AccountingDataTypes
//  CorrespondenceGenerationParameters - Structure:
//   * TempTablesManager - TempTablesManager
//   * VATRegisters - Array of String - VAT registers
//   * RegistersWithoutManSum - Array of String - registers without the SummaUpr indicator
//   * RegistersWithoutSumLocal - Array of String - registers without the sumregl indicator
//
// Returns:
//  ValueTable
Function GetTableOfCorrespondenceOfBalanceRegisters(DocumentsForProcessing_, FactGettingParameters, RuleDescription_, CorrespondenceGenerationParameters)

	ResidualFinancialRegisters = New Map;
	
	DocumentsKinds = DocumentsForProcessing_.Copy(, "DocumentKind");
	DocumentsKinds.GroupBy("DocumentKind");
	For Each LineDocument In DocumentsKinds Do
		ResidualFinancialRegistersByTypeOfDocument = BudgetingCached.ResidualFinancialRegistersByTypeOfDocument(
			LineDocument.DocumentKind);
		For Each KeyAndValue In ResidualFinancialRegistersByTypeOfDocument Do
			ResidualFinancialRegisters.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
	EndDo;
	
	QueryOptions = New Structure;
	QueryOptions.Insert("BeginOfPeriod", FactGettingParameters.Period.StartDate);
	QueryOptions.Insert("EndOfPeriod", FactGettingParameters.Period.EndDate);
	QueryOptions.Insert("SettingUpBusinessTransaction", RuleDescription_.DataSourceXO);
	QueryOptions.Insert("SettingsOfHouseholdOfOperationsForReplacement",
		BudgetingCached.BusinessTransactionsSettingsForReplacement());
	QueryOptions.Insert("Recorder", Undefined);
	QueryOptions.Insert("IndicatorsForCorrespondingRegisters",
		DataSourcesCached.IndicatorsForCorrespondingRegisters());
	QueryOptions.Insert("RegistersOfRecoveryOfCalculationsOnStorno",
		FinancialAccountingByBalanceSheetRegisterData.RegistersOfRecoveryOfCalculationsOnStorno());
	QueryOptions.Insert("RegistersWithSelectionByIndicators",
		FinancialAccountingByBalanceSheetRegisterData.RegistersWithSelectionByIndicators());

	Query = FinancialAccountingByBalanceSheetRegisterData.RequestingDataFromFinancialRegisters(QueryOptions,
		CorrespondenceGenerationParameters.TempTablesManager);
	CorDataSources = Query.Parameters.CorDataSources; // ValueTable -
	CorDataSources.Columns.Delete("AccountingObject");
	CorDataSources.Columns.Add("Factor",
		New TypeDescription("EnumRef.IndicatorsOfAnalyticalRegisters"));
	CorDataSources.Columns.Add("RegisterName", New TypeDescription("String", ,
		New StringQualifiers(500)));
	Query.Parameters.Insert("VATRegisters", Common.CopyRecursive(CorrespondenceGenerationParameters.VATRegisters));
	Query.Parameters.Insert("RegistersWithoutManSum", Common.CopyRecursive(CorrespondenceGenerationParameters.RegistersWithoutManSum));
	Query.Parameters.Insert("RegistersWithoutSumLocal", Common.CopyRecursive(CorrespondenceGenerationParameters.RegistersWithoutSumLocal));
	
	QueriesTexts = New Array();
	RequestTextsForRegisterEntries = Undefined;
	
	ThereAreDocumentsForReflection = ThereAreDocumentsForFormationOfCorrespondenceRecordsRegisters(DocumentsForProcessing_, Query, QueriesTexts);
	If ThereAreDocumentsForReflection Then
		
		Query.Parameters.AnalyticsSampleRegisters.Clear();
		
		RequestTextsForRegisterEntries = RequestTextsForRegisterEntries(Query, ResidualFinancialRegisters);
		
		If RequestTextsForRegisterEntries.Count() = 0 Then
			FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "DocumentsForProcessing_");
			FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "DocumentsToBeReflected");
			Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
			Query.Execute();
			Return Undefined;
		EndIf;
		
		CorrespondenceGenerationParameters.Insert("VATRegisters", Common.CopyRecursive(Query.Parameters.VATRegisters));
		CorrespondenceGenerationParameters.Insert("RegistersWithoutManSum", Common.CopyRecursive(Query.Parameters.RegistersWithoutManSum));
		CorrespondenceGenerationParameters.Insert("RegistersWithoutSumLocal", Common.CopyRecursive(Query.Parameters.RegistersWithoutSumLocal));
		
		QueriesTexts.Add(RequestTextForCorrespondenceRecords(RequestTextsForRegisterEntries));
		
		GenerateCorrespondencesOfRegisterEntries(Query, QueriesTexts);
		
		AllocateUnbalancedCorrespondenceResources(Query, QueriesTexts);
		
		CheckCorrespondenceErrors(DocumentsForProcessing_, Query, QueriesTexts);
	
	ElsIf Query.TempTablesManager.Tables.Find("MovementCache") = Undefined
		Or QueryOptions.SettingsOfHouseholdOfOperationsForReplacement.Find(RuleDescription_.DataSourceXO) <> Undefined Then
		
		// Documents without correspondence from balance registers (Cash expense requests, business trip requests, etc.)
		// do not need to be processed. Such documents are not included in the selection and are missing from the cache.
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "DocumentsForProcessing_");
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "DocumentsToBeReflected");
		Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		Query.Execute();
		Return Undefined;
		
	EndIf;
	
	ProcessRegisterCorrespondencesAndPutThemInCache(Query, QueriesTexts);
	
	IndexOffset = 0;
	GenerateCorrespondenceAnalyticsRequestsAndPutThemInCache(Query, QueriesTexts, RequestTextsForRegisterEntries, IndexOffset);
	
	If ThereAreDocumentsForReflection Then
		ProcessDocumentCache(Query, QueriesTexts, IndexOffset);
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.DestroyTemporaryTables(Query, QueriesTexts);
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Results = Query.ExecuteBatch();
	QueriesTexts.Clear();
	
	IndexOfMovementQueryResult = 0;
	AnalyticsTables = CorrespondenceGenerationParameters.StructureOfAnalyticsTables;
	If ThereAreDocumentsForReflection Then
		For Each KeyAndValue In Query.Parameters.AnalyticsSampleRegisters Do
			DimensionTable = AnalyticsQueryTable(Results[KeyAndValue.Value]);
			If AnalyticsTables.Property(KeyAndValue.Key)
				And KeyAndValue.Key = Query.Parameters.NameOfRegisterOfServiceAccountingObjects Then
				TMCommonUse.AddRowsToTable(AnalyticsTables[KeyAndValue.Key], DimensionTable);
			Else
				AnalyticsTables.Insert(KeyAndValue.Key, DimensionTable);
			EndIf;
			If KeyAndValue.Value >= IndexOfMovementQueryResult Then
				IndexOfMovementQueryResult = KeyAndValue.Value + 1;
			EndIf;
		EndDo;
		
		SelectionOfDocuments = Results[IndexOfMovementQueryResult+1+IndexOffset].Select();
		TheStructureOfTheSearch = New Structure("Document");
		While SelectionOfDocuments.Next() Do
			// There is no correspondence on the documents - such documents should be excluded from the sample in the future
			TheStructureOfTheSearch.Document = SelectionOfDocuments.Document;
			LineDocument = DocumentsForProcessing_.FindRows(TheStructureOfTheSearch)[0];
			LineDocument.Error = True;
		EndDo;
	EndIf;
	
	CorrespondenceOfRegisters = Results[IndexOfMovementQueryResult];
	If CorrespondenceOfRegisters.IsEmpty() Then
		Return Undefined;
	EndIf;
	SelectionOfCorrespondence = CorrespondenceOfRegisters.Select();
	ResultOfMovement = Results[IndexOfMovementQueryResult+1];
	MotionSampling_ = ResultOfMovement.Select();
	
	TheStructureOfTheSearch = New Structure("RegisterNameDr, RegisterNameCr");
	
	CorrespondencesTable = Undefined;
	CorrespondenceAnalytics = New Structure("DimensionDr, DimensionCr, CorDimension", New Array, New Array,
		New Map);
	CorrespondenceParameters = New Structure;
	SummaryResources = New Map;
	CorrespondenceReverses = New Array;
	DataToFill = New Structure("AnalyticsLines_Dr, AnalyticsLines_Cr");
	
	// 1 - the main correspondence table is formed (the types of accounting data coincide with the business of operation) with analytics fields
	// 2 - summary and quantitative indicators of other correspondence tables are recorded in the main table
	For Counter = 1 To 2 Do
		
		If Counter = 2 And CorrespondencesTable = Undefined Then
			Raise StrTemplate(NStr(
				"vi = 'Sai tùy chỉnh kiểu dữ liệu ghi nhận Thu nhập và Chi phí đối với giao dịch kinh tế %1.';
				|ru = 'Некорректно настроены типы данных учета Приход и Расход для хозяйственной операции %1.';
				|en = 'The Income and Expense accounting data types for the %1 business transaction are configured incorrectly.'; fa = 'The Income and Expense accounting data types for the %1 business transaction are configured incorrectly.';
				|it = 'Некорректно настроены типы данных учета Приход и Расход для хозяйственной операции %1.';
				|pl = 'The Income and Expense accounting data types for the %1 business transaction are configured incorrectly.';
				|tr = '%1 ticari işlemi için Gelir ve Gider muhasebe veri türleri yanlış ayarlandı.'"),
				RuleDescription_.DataSourceXO);
		EndIf;
		
		SelectionOfCorrespondence.Reset();
		While SelectionOfCorrespondence.Next() Do
			
			If SelectionOfCorrespondence.RegisterNameDr = Query.Parameters.NameOfRegisterOfServiceAccountingObjects
				Or Not ValueIsFilled(RuleDescription_.TypeOfAccountingDataReceipt) Then
				TypeOfAccountingDataDr = RuleDescription_.TypeOfAccountingDataReceipt;
				ReflectionParametersDr = Undefined;
			Else
				ReflectionParametersDr = ResidualFinancialRegisters.Get(SelectionOfCorrespondence.RegisterNameDr);
				ReflectionParametersDr.Insert("RegisterName", SelectionOfCorrespondence.RegisterNameDr);
				TypeOfAccountingDataDr = ReflectionParametersDr.TypeOfAccountingData;
			EndIf;
			If SelectionOfCorrespondence.RegisterNameCr = Query.Parameters.NameOfRegisterOfServiceAccountingObjects
				Or Not ValueIsFilled(RuleDescription_.TypeOfAccountingDataExpense) Then
				TypeOfAccountingDataCr = RuleDescription_.TypeOfAccountingDataExpense;
				ReflectionParametersCr = Undefined;
			Else
				ReflectionParametersCr = ResidualFinancialRegisters.Get(SelectionOfCorrespondence.RegisterNameCr);
				ReflectionParametersCr.Insert("RegisterName", SelectionOfCorrespondence.RegisterNameCr);
				TypeOfAccountingDataCr = ReflectionParametersCr.TypeOfAccountingData;
			EndIf;
			MainTable = (TypeOfAccountingDataDr = RuleDescription_.TypeOfAccountingDataReceipt
				And TypeOfAccountingDataCr = RuleDescription_.TypeOfAccountingDataExpense);
			If Not MainTable And SelectionOfCorrespondence.InvertCorrespondence Then
				MainTable = (TypeOfAccountingDataDr = RuleDescription_.TypeOfAccountingDataExpense Or ReflectionParametersDr = Undefined)
				And (TypeOfAccountingDataCr = RuleDescription_.TypeOfAccountingDataReceipt Or ReflectionParametersCr = Undefined);
				ReverseCorrespondence = True;
			ElsIf TypeOfAccountingDataDr = TypeOfAccountingDataCr And SelectionOfCorrespondence.InvertCorrespondence Then
				ReverseCorrespondence = True;
			Else
				ReverseCorrespondence = False;
			EndIf;
			If Counter = 1 And Not MainTable Then
				Continue;
			ElsIf Counter = 2 And MainTable Then
				Continue;
			EndIf;
			If MainTable And CorrespondencesTable = Undefined Then
				CorrespondencesTable = DataSourcesServer.TableOfCorrespondenceRegisters(
					RuleDescription_.DataSourceXO, CorrespondenceAnalytics);
			EndIf;
			If Counter = 2 Then
				InitialAmountOfResources = SummaryResources.Count();
				If ReverseCorrespondence Then
					CorrespondenceKey = SelectionOfCorrespondence.RegisterNameCr + SelectionOfCorrespondence.RegisterNameDr;
					CorrespondenceReverses.Add(CorrespondenceKey);
				Else
					CorrespondenceKey = SelectionOfCorrespondence.RegisterNameDr + SelectionOfCorrespondence.RegisterNameCr;
				EndIf;
				If CorrespondencesTable.Indexes.Count() = 0 Then
					CorrespondencesTable.Indexes.Add(RegisterCorrespondenceSearchFields());
				EndIf;
			EndIf;
			AddMetricsToCorrespondenceTable(CorrespondencesTable, ReflectionParametersCr,
				ReflectionParametersDr, SummaryResources, Query.Parameters, MainTable);
			If Counter = 2 Then
				NewNumberOfResources = SummaryResources.Count();
				If NewNumberOfResources = InitialAmountOfResources
					And ReflectionParametersDr <> Undefined
					And ReflectionParametersCr <> Undefined
					// It is possible to transfer amounts from one indicator to another - in this case, the indicators have already been added to the main correspondence
					And SelectionOfCorrespondence.RegisterNameDr <> SelectionOfCorrespondence.RegisterNameCr
					// Correspondence reversals are possible - in this case, indicators may have already been added
					And CorrespondenceReverses.Find(CorrespondenceKey) = Undefined Then
					// In this case, the amounts are not added to the reflection of the fact
					Continue;
				EndIf;
			EndIf;
			CorrespondenceParameters.Insert("MainTable", MainTable);
			CorrespondenceParameters.Insert("ReverseCorrespondence", ReverseCorrespondence);
			
			ColumnsOfAnalyticsTableDr = AnalyticsTables[SelectionOfCorrespondence["RegisterName" + ?(
				ReverseCorrespondence, "Cr", "Dr")]].CopyColumns(); // ValueTable -
			ColumnsOfAnalyticsTableCr = AnalyticsTables[SelectionOfCorrespondence["RegisterName" + ?(
				ReverseCorrespondence, "Dr", "Cr")]].CopyColumns(); // ValueTable -
			CorrespondenceParameters.Insert("AdjustingAnalyticsDr", AdjustingColumnsOfCorrespondenceAnalytics(
				ColumnsOfAnalyticsTableDr.Columns, "Dr", CorrespondenceAnalytics));
			CorrespondenceParameters.Insert("AdjustingAnalyticsCr", AdjustingColumnsOfCorrespondenceAnalytics(
				ColumnsOfAnalyticsTableCr.Columns, "Cr", CorrespondenceAnalytics));
			
			CorrespondenceParameters.Insert("FilterByIndicator", Not ((SelectionOfCorrespondence.RegisterNameDr = Query.Parameters.NameOfRegisterOfServiceAccountingObjects
				Or Query.Parameters.RegistersOfRecoveryOfCalculationsOnStorno.Find(SelectionOfCorrespondence.RegisterNameDr)
				<> Undefined) And (SelectionOfCorrespondence.RegisterNameCr = Query.Parameters.NameOfRegisterOfServiceAccountingObjects
				Or Query.Parameters.RegistersOfRecoveryOfCalculationsOnStorno.Find(SelectionOfCorrespondence.RegisterNameCr)
				<> Undefined)));
			
			MotionSampling_.Reset();
			FillPropertyValues(TheStructureOfTheSearch, SelectionOfCorrespondence);
			While MotionSampling_.FindNext(TheStructureOfTheSearch) Do
				DataToFill.AnalyticsLines_Dr = TrafficAnalyticsLines(MotionSampling_, AnalyticsTables,
					Query.Parameters, "Dr", CorrespondenceParameters);
				DataToFill.AnalyticsLines_Cr = TrafficAnalyticsLines(MotionSampling_, AnalyticsTables,
					Query.Parameters, "Cr", CorrespondenceParameters);
				
				EntriesErrors = New Array;
				
				If Not FinancialAccountingByBalanceSheetRegisterData.CheckingEqualityOfBalanceResources(MotionSampling_,
					DataToFill.AnalyticsLines_Dr, Query.Parameters, ?(ReverseCorrespondence, "Cr", "Dr")) Then
					EntriesErrors.Add(StrTemplate(NStr(
						"vi = 'Lỗi khi chọn đối tượng phân tích đối với bản ghi của biểu ghi ""%1"" với tên định danh %2.';
						|ru = 'Ошибка при подборе аналитики к записи регистра ""%1"" с идентификатором %2.';
						|en = 'An error occurred while picking a dimension for the ""%1"" register record with ID %2.'; fa = 'An error occurred while picking a dimension for the ""%1"" register record with ID %2.';
						|it = 'Ошибка при подборе аналитики к записи регистра ""%1"" с идентификатором %2.';
						|pl = 'An error occurred while picking a dimension for the ""%1"" register record with ID %2.';
						|tr = '%2 kimlikli ""%1"" kayıt girişinin boyutu seçilirken hata oluştu.'",
						Common.DefaultLanguageCode()), Common.ObjectPresentation(
						Metadata.AccumulationRegisters[MotionSampling_["RegisterName" + ?(ReverseCorrespondence, "Cr", "Dr")]]),
						MotionSampling_.FinRecordID));
				EndIf;

				If Not FinancialAccountingByBalanceSheetRegisterData.CheckingEqualityOfBalanceResources(MotionSampling_,
					DataToFill.AnalyticsLines_Cr, Query.Parameters, ?(ReverseCorrespondence, "Dr", "Cr")) Then
					EntriesErrors.Add(StrTemplate(NStr(
						"vi = 'Lỗi khi chọn đối tượng phân tích đối với bản ghi của biểu ghi ""%1"" với tên định danh %2.';
						|ru = 'Ошибка при подборе аналитики к записи регистра ""%1"" с идентификатором %2.';
						|en = 'An error occurred while picking a dimension for the ""%1"" register record with ID %2.'; fa = 'An error occurred while picking a dimension for the ""%1"" register record with ID %2.';
						|it = 'Ошибка при подборе аналитики к записи регистра ""%1"" с идентификатором %2.';
						|pl = 'An error occurred while picking a dimension for the ""%1"" register record with ID %2.';
						|tr = '%2 kimlikli ""%1"" kayıt girişinin boyutu seçilirken hata oluştu.'",
						Common.DefaultLanguageCode()), Common.ObjectPresentation(
						Metadata.AccumulationRegisters[MotionSampling_["RegisterName" + ?(ReverseCorrespondence, "Dr", "Cr")]]),
						MotionSampling_.FinRecordID));
				EndIf;

				If DataToFill.AnalyticsLines_Dr.Count() > 1
					And DataToFill.AnalyticsLines_Cr.Count() > 1 Then
					EntriesErrors.Add(StrTemplate(NStr(
						"vi = 'Các bản ghi của biểu ghi ""%1"" và ""%2"" với tên định danh %3 có mối liên hệ ""nhiều với nhiều"".';
						|ru = 'Записи регистров ""%1"" и ""%2"" с идентификатором %3 имеют отношение ""многие ко многим"".';
						|en = 'Records of registers ""%1"" and ""%2"" with ID %3 have the Many-to-Many relationship.'; fa = 'Records of registers ""%1"" and ""%2"" with ID %3 have the Many-to-Many relationship.';
						|it = 'Voci di registro ""%1"" e ""%2"" con ID %3 hanno relazione ""molti verso molti"".';
						|pl = 'Wpisy rejestrów ""%1"" i ""%2"" z identyfikatorem %3 mają stosunek ""wiele do wielu"".';
						|tr = '%3 kimlikli ""%1"" ve ""%2"" kayıt girişlerinin ""çoktan çok olana"" ilişkisi var.'",
						Common.DefaultLanguageCode()), Common.ObjectPresentation(
						Metadata.AccumulationRegisters[MotionSampling_["RegisterName" + ?(ReverseCorrespondence, "Cr", "Dr")]]),
						Common.ObjectPresentation(
						Metadata.AccumulationRegisters[MotionSampling_["RegisterName" + ?(ReverseCorrespondence, "Dr", "Cr")]]),
						MotionSampling_.FinRecordID));
				EndIf;

				If EntriesErrors.Count() > 0 Then
					ErrorText = "";
					EntriesErrors = CommonClientServer.CollapseArray(EntriesErrors);
					For Each TransactionError In EntriesErrors Do
						ErrorText = ErrorText + ?(IsBlankString(ErrorText), "", Chars.LF) + TransactionError;
					EndDo;
					DocumentStrings = DocumentsForProcessing_.FindRows(New Structure("Document",
						MotionSampling_.Recorder));
					For Each LineDocument In DocumentStrings Do
						FillPropertyValues(LineDocument, MotionSampling_);
						LineDocument.Error = True;
						LineDocument.Comment = ErrorText;
					EndDo;
					Continue;
				Else
					AddRowsToCorrespondenceTable(CorrespondencesTable, MotionSampling_, DataToFill,
						CorrespondenceAnalytics, CorrespondenceParameters, SummaryResources, CorrespondenceGenerationParameters);
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	CorrespondencesTable.Indexes.Clear();
	
	SelectionOfCorrespondence.Reset();
	
	TotalTotalResources = New Array;
	For Each SumResource In SummaryResources Do
		TotalTotalResources.Add(SumResource.Value.NameOfManIndicator);
		TotalTotalResources.Add(SumResource.Value.NameOfIndicatorIsLocal);
		If SumResource.Value.Property("IndicatorNameShaft") Then
			TotalTotalResources.Add(SumResource.Value.IndicatorNameShaft);
		EndIf;
	EndDo;
	
	// In some cases, Receipt and expense in correspondence with official accounting objects.
	// In this case, you need to collapse the table.
	If SelectionOfCorrespondence.Count() > 1
		And Not SelectionOfCorrespondence.FindNext(New Structure("Order", 1)) Then
		ReFillInCorrespondenceTableForAnalyticsReceiptsExpenses(CorrespondencesTable, CorrespondenceAnalytics,
			TotalTotalResources);
	EndIf;
	
	// Composite sum resources are added sequentially
	For Counter = 1 To 3 Do
		CompositeSumResources = DataSourcesServer.CompositeSumResources(TotalTotalResources, Counter);
		For Each KeyAndValue In CompositeSumResources Do
			If CorrespondencesTable.Columns.Find(KeyAndValue.Key) = Undefined Then
				CorrespondencesTable.Columns.Add(KeyAndValue.Key, CorrespondenceGenerationParameters.FillParameters.MoneyFieldTypeDescription);
				TotalTotalResources.Add(KeyAndValue.Key);
			EndIf;
			If IsBlankString(KeyAndValue.Value) Then
				Continue;
			EndIf;
			For Each TableRow In CorrespondencesTable Do
				If Counter < 3 Then
					For Each ColumnName In KeyAndValue.Value Do
						TableRow[KeyAndValue.Key] = TableRow[KeyAndValue.Key] + TableRow[ColumnName];
					EndDo;
				Else
					For Each ColumnName In KeyAndValue.Value Do
						If StrFind(ColumnName, "-") > 0 Then
							ColumnName = StrReplace(ColumnName, "-", "");
							ResourceFactor = -1;
						Else
							ResourceFactor = 1;
						EndIf;
						TableRow[KeyAndValue.Key] = TableRow[KeyAndValue.Key] + TableRow[ColumnName] * ResourceFactor;
					EndDo;
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	AdjustTotalResources(CorrespondencesTable, RuleDescription_.TypeOfAccountingDataReceipt, RuleDescription_.TypeOfAccountingDataExpense, TotalTotalResources);
	
	GroupingFields = StrSplit(RegisterCorrespondenceSearchFields(), ",", );
	CommonClientServer.SupplementArray(GroupingFields, CorrespondenceAnalytics.DimensionCr, True);
	CommonClientServer.SupplementArray(GroupingFields, CorrespondenceAnalytics.DimensionDr, True);
	If CorrespondencesTable.Columns.Find("Currency") <> Undefined Then
		GroupingFields.Add("Currency");
	EndIf;
	If CorrespondencesTable.Columns.Find("Count") <> Undefined Then
		TotalTotalResources.Add("Count");
		If CorrespondencesTable.Columns.Find("CorQuantity") <> Undefined Then
			TotalTotalResources.Add("CorQuantity");
		EndIf;
	EndIf;
	CorrespondencesTable.GroupBy(StrConcat(GroupingFields, ","), StrConcat(TotalTotalResources, ","));
	
	If CorrespondencesTable.Columns.Find("Department") = Undefined Then
		CorrespondencesTable.Columns.Add("Department",
			New TypeDescription("CatalogRef.BusinessStructure"));
	EndIf;
	If CorrespondencesTable.Columns.Find("IncomeExpenseBusinessUnit") <> Undefined Then
		CorrespondencesTable.LoadColumn(CorrespondencesTable.UnloadColumn(
			"IncomeExpenseBusinessUnit"), "Department");
	ElsIf CorrespondencesTable.Columns.Find("DivisionOfAssetsLiabilities") <> Undefined Then
		CorrespondencesTable.LoadColumn(CorrespondencesTable.UnloadColumn(
			"DivisionOfAssetsLiabilities"), "Department");
	EndIf;
	
	Return CorrespondencesTable;
	
EndFunction

Function ThereAreDocumentsForFormationOfCorrespondenceRecordsRegisters(DocumentsForProcessing_, Query, QueriesTexts)

	QueriesTexts.Add("
	|SELECT
	|	DocumentsForProcessing_.Document AS Recorder
	|INTO DocumentsForProcessing_
	|FROM
	|	&DocumentsForProcessing_ AS DocumentsForProcessing_
	|
	|INDEX BY
	|	Recorder");
	
	If Query.TempTablesManager.Tables.Find("DocumentCache") <> Undefined Then
		QueriesTexts.Add("
		|SELECT
		|	DocumentsForProcessing_.Recorder AS Recorder
		|INTO DocumentsToBeReflected
		|FROM
		|	DocumentsForProcessing_ AS DocumentsForProcessing_
		|WHERE
		|	NOT DocumentsForProcessing_.Recorder REFS Document.PaymentRequest
		|	AND NOT DocumentsForProcessing_.Recorder REFS Document.ApplicationForBusinessTrip
		|	AND NOT TRUE IN
		|				(SELECT TOP 1
		|					TRUE
		|				FROM
		|					DocumentCache AS DocumentCache
		|				WHERE
		|					DocumentCache.Recorder = DocumentsForProcessing_.Recorder
		|					AND DocumentCache.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod)
		|
		|INDEX BY
		|	Recorder");
	Else
		QueriesTexts.Add("
		|SELECT
		|	DocumentsForProcessing_.Recorder
		|INTO DocumentsToBeReflected
		|FROM
		|	DocumentsForProcessing_ AS DocumentsForProcessing_
		|WHERE
		|	NOT DocumentsForProcessing_.Recorder REFS Document.PaymentRequest
		|	AND NOT DocumentsForProcessing_.Recorder REFS Document.ApplicationForBusinessTrip
		|
		|INDEX BY
		|	Recorder");
	EndIf;
	
	Query.SetParameter("DocumentsForProcessing_", DocumentsForProcessing_);
	
	Return FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, QueriesTexts, "DocumentsToBeReflected");

EndFunction

Procedure ReFillInCorrespondenceTableForAnalyticsReceiptsExpenses(CorrespondencesTable, CorrespondenceAnalytics, SummaryResources)
	
	CorrespondencesTableReceipt = CorrespondencesTable.CopyColumns();
	CorrespondencesTableExpense = CorrespondencesTable.CopyColumns();
	DimensionReceipt = StrConcat(CorrespondenceAnalytics.DimensionDr, ",");
	DimensionExpense = StrConcat(CorrespondenceAnalytics.DimensionCr, ",");
	
	Counter = 0;
	While Counter < CorrespondencesTable.Count() Do
		TableRow = CorrespondencesTable[Counter];
		ThisReceipt = False;
		ThisExpense = False;
		For Each Dimension In CorrespondenceAnalytics.DimensionDr Do
			If ValueIsFilled(TableRow[Dimension]) Then
				ThisReceipt = True;
				Break;
			EndIf;
		EndDo;
		For Each Dimension In CorrespondenceAnalytics.DimensionCr Do
			If ValueIsFilled(TableRow[Dimension]) Then
				ThisExpense = True;
				Break;
			EndIf;
		EndDo;
		If ThisReceipt = ThisExpense Then
			Counter = Counter + 1;
			Continue;
		EndIf;
		If ThisReceipt Then
			NewRow = CorrespondencesTableReceipt.Add();
		Else
			NewRow = CorrespondencesTableExpense.Add();
		EndIf;
		FillPropertyValues(NewRow, TableRow);
		CorrespondencesTable.Delete(Counter);
	EndDo;
	
	TotalResourcesByLine = TMCommonUseClientServer.ConvertArrayToStructureOrMatch(SummaryResources, True);
	
	If CorrespondencesTableReceipt.Count() > 0
		And CorrespondencesTableExpense.Count() > 0 Then
		CounterReceipt = 0;
		While CounterReceipt < CorrespondencesTableReceipt.Count() Do
			StringReceipt = CorrespondencesTableReceipt[CounterReceipt];
			CounterExpense = 0;
			While CounterExpense < CorrespondencesTableExpense.Count() Do
				ResourceBalanceReceipt = 0;
				ResourceBalanceExpense = 0;
				StringExpense = CorrespondencesTableExpense[CounterExpense];
				For Each Resource In SummaryResources Do
					TotalResourcesByLine[Resource] = Min(StringReceipt[Resource], StringExpense[Resource]);
					StringReceipt[Resource] = StringReceipt[Resource] - TotalResourcesByLine[Resource];
					ResourceBalanceReceipt = ResourceBalanceReceipt + StringReceipt[Resource];
					StringExpense[Resource] = StringExpense[Resource] - TotalResourcesByLine[Resource];
					ResourceBalanceExpense = ResourceBalanceExpense + StringExpense[Resource];
				EndDo;
				NewRow = CorrespondencesTable.Add();
				FillPropertyValues(NewRow, StringReceipt, "Period,Recorder,Organization,Currency");
				FillPropertyValues(NewRow, StringReceipt, DimensionReceipt);
				FillPropertyValues(NewRow, StringExpense, DimensionExpense);
				FillPropertyValues(NewRow, TotalResourcesByLine);
				If ResourceBalanceExpense = 0 Then
					CorrespondencesTableExpense.Delete(CounterExpense);
				Else
					CounterExpense = CounterExpense + 1;
				EndIf;
				If ResourceBalanceReceipt = 0 Then
					Break;
				EndIf;
			EndDo;
			If ResourceBalanceReceipt = 0 Then
				CorrespondencesTableReceipt.Delete(CounterReceipt);
			Else
				CounterReceipt = CounterReceipt + 1;
			EndIf;
		EndDo;
	EndIf;
	
	For Each StringReceipt In CorrespondencesTableReceipt Do
		NewRow = CorrespondencesTable.Add();
		FillPropertyValues(NewRow, StringReceipt);
	EndDo;
	For Each StringExpense In CorrespondencesTableExpense Do
		NewRow = CorrespondencesTable.Add();
		FillPropertyValues(NewRow, StringExpense);
	EndDo;
	
EndProcedure

Procedure AdjustTotalResources(CorrespondencesTable, TypeOfAccountingDataReceipt, TypeOfAccountingDataExpense, SummaryResources)
	
	AccountingDataTypes = New Array;
	AccountingDataTypes.Add(TypeOfAccountingDataReceipt);
	If TypeOfAccountingDataExpense <> TypeOfAccountingDataReceipt Then
		AccountingDataTypes.Add(TypeOfAccountingDataExpense);
	EndIf;
	
	ReplaceableSumResources = New Map;
	// Replacement with double removal
	ReplaceableSumResources.Insert("CostWithVATMan", "CostMan");
	ReplaceableSumResources.Insert("AmountOfAdditionalExpensesAmountWithVATMan", "AmountOfAdditionalExpenseAmountOfMan");
	
	For Each ReplaceableResource In ReplaceableSumResources Do
		If CorrespondencesTable.Columns.Find(ReplaceableResource.Key) <> Undefined Then
			CorrespondencesTable.Columns.Delete(ReplaceableResource.Value);
			CorrespondencesTable.Columns[ReplaceableResource.Key].Name = ReplaceableResource.Value;
			SummaryResources.Delete(SummaryResources.Find(ReplaceableResource.Key));
		EndIf;
	EndDo;
	
	ReplaceableSumResources.Clear();
	// Replacement without double removal
	ReplaceableSumResources.Insert("Cost_WithVATMan", "ManagementCost");
	
	If AccountingDataTypes.Find(Enums.AccountingDataTypes.Counterparties) <> Undefined Then
		If AccountingDataTypes.Find(Enums.AccountingDataTypes.Cash) = Undefined Then
			ReplaceableSumResources.Insert("ManPaymentAmount", "SumMan");
			ReplaceableSumResources.Insert("PaymentAmountLocal", "SumCompl");
			ReplaceableSumResources.Insert("PaymentAmountShaft", "SumCurr");
		Else
			ReplaceableSumResources.Insert("SumMan", "ManPaymentAmount");
			ReplaceableSumResources.Insert("SumCompl", "PaymentAmountLocal");
			ReplaceableSumResources.Insert("SumCurr", "PaymentAmountShaft");
		EndIf;
		If TypeOfAccountingDataReceipt = Enums.AccountingDataTypes.Products Then
			ReplaceableSumResources.Insert("Cost_WithVATMan", "AmountExcludingVATMan");
			ReplaceableSumResources.Insert("CostLocal", "AmountExcludingVATCompl");
		EndIf;
	EndIf;
	
	For Each ReplaceableResource In ReplaceableSumResources Do
		If CorrespondencesTable.Columns.Find(ReplaceableResource.Key) <> Undefined Then
			If CorrespondencesTable.Columns.Find(ReplaceableResource.Value) = Undefined Then
				CorrespondencesTable.Columns[ReplaceableResource.Key].Name = ReplaceableResource.Value;
				SummaryResources.Add(ReplaceableResource.Value);
			Else
				For Each TableRow In CorrespondencesTable.FindRows(New Structure(ReplaceableResource.Value, 0)) Do
					TableRow[ReplaceableResource.Value] = TableRow[ReplaceableResource.Key];
				EndDo;
				CorrespondencesTable.Columns.Delete(ReplaceableResource.Key);
			EndIf;
			SummaryResources.Delete(SummaryResources.Find(ReplaceableResource.Key));
		EndIf;
	EndDo;
	
EndProcedure

Function AnalyticsQueryTable(QueryResult)
	
	QueryTable = QueryResult.Unload();
	RequiredIndexFields = "Period,Recorder,FinRecordID,RowID,RegisterName,Organization";
	
	QueryTable.Indexes.Add(RequiredIndexFields + ",ThisIsDebit,ThisIsReverseTransaction,Factor");
	QueryTable.Indexes.Add(RequiredIndexFields + ",ThisIsLoan,ThisIsReverseTransaction,Factor");
	QueryTable.Indexes.Add(RequiredIndexFields + ",SettingUpBusinessTransaction,ThisIsDebit,ThisIsReverseTransaction,Factor");
	QueryTable.Indexes.Add(RequiredIndexFields + ",SettingUpBusinessTransaction,ThisIsLoan,ThisIsReverseTransaction,Factor");
	
	Return QueryTable;
	
EndFunction

Function TrafficAnalyticsLines(MotionSampling_, AnalyticsTables, QueryOptions, DrCr, CorrespondenceParameters)
	
	BalancedDrCr = ?(DrCr = "Dr", "Cr", "Dr");
	ReverseCorrespondence = CorrespondenceParameters.ReverseCorrespondence;
	
	RegisterName = MotionSampling_["RegisterName" + ?(ReverseCorrespondence, BalancedDrCr, DrCr)];
	
	TheStructureOfTheSearch = New Structure();
	TheStructureOfTheSearch.Insert("Period", MotionSampling_.Period);
	TheStructureOfTheSearch.Insert("Recorder", MotionSampling_.Recorder);
	TheStructureOfTheSearch.Insert("FinRecordID", MotionSampling_.FinRecordID);
	TheStructureOfTheSearch.Insert("RowID", MotionSampling_["RowID" + ?(ReverseCorrespondence, BalancedDrCr, DrCr)]);
	TheStructureOfTheSearch.Insert("RegisterName", RegisterName);
	TheStructureOfTheSearch.Insert("Organization", MotionSampling_.Organization);
	
	If MotionSampling_.TakeIntoAccountBusinessTransaction Then
		TheStructureOfTheSearch.Insert("SettingUpBusinessTransaction", MotionSampling_.SettingUpBusinessTransaction);
	EndIf;
	
	If DrCr = "Dr" Then
		TheStructureOfTheSearch.Insert(?(ReverseCorrespondence, "ThisIsDebit", "ThisIsLoan"), False);
	Else
		TheStructureOfTheSearch.Insert(?(ReverseCorrespondence, "ThisIsLoan", "ThisIsDebit"), False);
	EndIf;
	
	TheStructureOfTheSearch.Insert("ThisIsReverseTransaction",
		?(ReverseCorrespondence, MotionSampling_["ThisIsReverseTransaction"+BalancedDrCr], MotionSampling_["ThisIsReverseTransaction" + DrCr]));
	
	If CorrespondenceParameters.FilterByIndicator Then
		TheStructureOfTheSearch.Insert("Factor", MotionSampling_["Factor" + ?(ReverseCorrespondence, BalancedDrCr, DrCr)]);
	EndIf;
	
	AnalyticsLines_ = AnalyticsTables[RegisterName].Copy(TheStructureOfTheSearch); // ValueTable -
	
	PerformAdditionalSelectionOfAnalyticsRows(MotionSampling_, AnalyticsLines_, DrCr);
	
	CorrespondenceAnalyticsCompliance = CorrespondenceParameters["AdjustingAnalytics"+DrCr];
	For Each KeyAndValue In CorrespondenceAnalyticsCompliance Do
		AnalyticsLines_.Columns[KeyAndValue.Key].Name = KeyAndValue.Value;
	EndDo;
	
	Return AnalyticsLines_;
	
EndFunction

// The selection conditions in this procedure must correspond to the additional conditions for joining records in the correspondence formation procedure
//
Procedure PerformAdditionalSelectionOfAnalyticsRows(MotionSampling_, AnalyticsLines_, DrCr)
	
	If Not MotionSampling_.TakeIntoAccountBusinessTransaction Then
		RowsCount = AnalyticsLines_.Count();
		For ReverseIndex = 1 To RowsCount Do
			AnalyticsLine_ = AnalyticsLines_[RowsCount - ReverseIndex];
			If ValueIsFilled(AnalyticsLine_.SettingUpBusinessTransaction)
				And AnalyticsLine_.SettingUpBusinessTransaction <> MotionSampling_.SettingUpBusinessTransaction Then
				// When generating correspondence with VAT accounting registers of operations, the setting of household of operations may be empty
				// and differ from the setting of household operations in the analyst lines
				If Not (AnalyticsLine_.Factor = Enums.IndicatorsOfAnalyticalRegisters.VATAmount
					And Not ValueIsFilled(MotionSampling_.SettingUpBusinessTransaction)) Then
					AnalyticsLines_.Delete(AnalyticsLine_);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	SelectAnalyticsRowsByAmounts(MotionSampling_, AnalyticsLines_, DrCr);
	
EndProcedure

Procedure SelectAnalyticsRowsByAmounts(MotionSampling_, AnalyticsLines_, DrCr)
	
	If AnalyticsLines_.Count() > 1
	And Not MotionSampling_["ComplexEntry" + DrCr] Then
		AnalyticsWithMovementSums = New Array();
		
		For Each AnalyticsLine_ In AnalyticsLines_ Do
			If AnalyticsLine_.SumMan = MotionSampling_["AmountOfManMovement" + DrCr]
			   And AnalyticsLine_.SumCompl = MotionSampling_["AmountOfLocalTraffic" + DrCr] Then
				AnalyticsWithMovementSums.Add(AnalyticsLine_);
			EndIf;
		EndDo;
		
		If AnalyticsWithMovementSums.Count() = 1 Then
			RowsCount = AnalyticsLines_.Count();
			For ReverseIndex = 1 To RowsCount Do
				AnalyticsLine_ = AnalyticsLines_[RowsCount - ReverseIndex];
				If AnalyticsLine_ <> AnalyticsWithMovementSums[0] Then
					AnalyticsLines_.Delete(AnalyticsLine_);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

Function CorrespondenceFillingParameters()

	FillParameters = New Structure;
	FillParameters.Insert("SearchFields", RegisterCorrespondenceSearchFields());
	FillParameters.Insert("ServiceRegisterName", FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects());
	FillParameters.Insert("ResourcesParameters", DataSourcesCached.ParametersOfAmountAndQuantityOfResources());
	FillParameters.Insert("MoneyFieldTypeDescription", CurrencyRateOperations.MoneyFieldTypeDescription());
	
	Return FillParameters;

EndFunction

Function AdjustingColumnsOfCorrespondenceAnalytics(ColumnsOfAnalyticsTable, DrCr, CorrespondenceAnalytics)
	
	AdjustingColumns = New Map;
	
	ArrayAnalytics = CorrespondenceAnalytics["Dimension" + DrCr];
	CorDimension = CorrespondenceAnalytics.CorDimension;
	For Each NameOfAnalytics In ArrayAnalytics Do
		If ColumnsOfAnalyticsTable.Find(NameOfAnalytics) <> Undefined Then
			Continue;
		ElsIf CorDimension.Get(NameOfAnalytics) <> Undefined Then
			AdjustedAnalyticsName = CorDimension[NameOfAnalytics];
			If ColumnsOfAnalyticsTable.Find(AdjustedAnalyticsName) <> Undefined Then
				AdjustingColumns.Insert(AdjustedAnalyticsName, NameOfAnalytics);
			EndIf;
		ElsIf StrFind(NameOfAnalytics, "LineOfBusiness") > 0 And NameOfAnalytics <> "LineOfBusiness" Then
			AdjustingColumns.Insert("LineOfBusiness", NameOfAnalytics);
		ElsIf NameOfAnalytics = "IncomeExpenseBusinessUnit" Or NameOfAnalytics = "DivisionOfAssetsLiabilities" Then
			AdjustingColumns.Insert("Department", NameOfAnalytics);
		ElsIf NameOfAnalytics = "AssetRef" And ColumnsOfAnalyticsTable.Find("IncomeAndExpenseItem") <> Undefined Then
			AdjustingColumns.Insert("IncomeAndExpenseItem", "AssetRef");
		EndIf;
	EndDo;
	
	Return AdjustingColumns;
	
EndFunction

Procedure AddMetricsToCorrespondenceTable(CorrespondencesTable, ReflectionParametersCr, ReflectionParametersDr,
	SummaryResources, QueryOptions, MainTable)
	
	Indicators = New Array;
	
	If Not ((ReflectionParametersCr = Undefined
		Or QueryOptions.RegistersOfRecoveryOfCalculationsOnStorno.Find(ReflectionParametersCr.RegisterName) <> Undefined)
		And (ReflectionParametersDr = Undefined
		Or QueryOptions.RegistersOfRecoveryOfCalculationsOnStorno.Find(ReflectionParametersDr.RegisterName) <> Undefined)) Then
	
		If ReflectionParametersCr <> Undefined Then
			For Each Factor In ReflectionParametersCr.Indicators Do
				If QueryOptions.IndicatorsForCorrespondingRegisters.Find(Factor.Key) = Undefined
					Or ReflectionParametersDr <> Undefined
					And ReflectionParametersDr.Indicators.Get(Factor.Key) <> Undefined
					And ReflectionParametersCr.RegisterName <> ReflectionParametersDr.RegisterName Then
					Indicators.Add(Factor.Key);
				EndIf;
			EndDo;
			If MainTable And ReflectionParametersCr.ResourcesQuantity.Count() > 0
				And CorrespondencesTable.Columns.Find("Count") = Undefined Then
				CorrespondencesTable.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers(15,3)));
			EndIf;
		Else
			ServiceIndicators = DataSourcesCached.DefaultAmountIndicatorsByDataSource(QueryOptions.SettingUpBusinessTransaction);
			For Each Factor In ServiceIndicators Do
				Indicators.Add(Factor);
			EndDo;
		EndIf;
		
		If ReflectionParametersDr <> Undefined Then
			For Each Factor In ReflectionParametersDr.Indicators Do
				If Indicators.Find(Factor.Key) <> Undefined Then
					Continue;
				ElsIf QueryOptions.IndicatorsForCorrespondingRegisters.Find(Factor.Key) = Undefined Then
					Indicators.Add(Factor.Key);
				EndIf;
			EndDo;
			If MainTable And ReflectionParametersDr.ResourcesQuantity.Count() > 0 Then
				If CorrespondencesTable.Columns.Find("Count") = Undefined Then
					CorrespondencesTable.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers(15,3)));
				ElsIf CorrespondencesTable.Columns.Find("CorQuantity") = Undefined Then
					CorrespondencesTable.Columns.Add("CorQuantity", CorrespondencesTable.Columns.Count.ValueType);
				EndIf;
			EndIf;
		Else
			ServiceIndicators = DataSourcesCached.DefaultAmountIndicatorsByDataSource(QueryOptions.SettingUpBusinessTransaction);
			For Each Factor In ServiceIndicators Do
				If Indicators.Find(Factor) = Undefined Then
					Indicators.Add(Factor);
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	If Indicators.Count() = 0 Then
		Indicators.Add(Enums.IndicatorsOfAnalyticalRegisters.Sum);
	EndIf;
	
	MoneyFieldTypeDescription = CurrencyRateOperations.MoneyFieldTypeDescription();
	IndicatorsNames = DataSourcesCached.NamesOfSummaryIndicators();
	For Each Factor In Indicators Do
		IndicatorName = IndicatorsNames.Get(Factor);
		If IndicatorName = Undefined Then
			Continue;
		EndIf;
		NameOfManIndicator = IndicatorName.Man;
		NameOfIndicatorIsLocal = IndicatorName.Compl;
		IndicatorNameShaft = IndicatorName.Curr;
		If CorrespondencesTable.Columns.Find(NameOfManIndicator) = Undefined Then
			CorrespondencesTable.Columns.Add(NameOfManIndicator, MoneyFieldTypeDescription);
			CorrespondencesTable.Columns.Add(NameOfIndicatorIsLocal, MoneyFieldTypeDescription);
			SummaryResources.Insert(Factor, New Structure("NameOfManIndicator, NameOfIndicatorIsLocal", NameOfManIndicator, NameOfIndicatorIsLocal));
			If ReflectionParametersCr <> Undefined And ReflectionParametersCr.ShaftResources.Count() > 0
				Or ReflectionParametersDr <> Undefined And ReflectionParametersDr.ShaftResources.Count() > 0 Then
				CorrespondencesTable.Columns.Add(IndicatorNameShaft, MoneyFieldTypeDescription);
				SummaryResources[Factor].Insert("IndicatorNameShaft", IndicatorNameShaft);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure AddRowsToCorrespondenceTable(CorrespondencesTable, MotionSampling_, DataToFill,
	CorrespondenceAnalytics, CorrespondenceParameters, SummaryResources, CorrespondenceGenerationParameters)
	
	AnalyticsLines_Dr = DataToFill.AnalyticsLines_Dr;
	AnalyticsLines_Cr = DataToFill.AnalyticsLines_Cr;
	
	MainTable = CorrespondenceParameters.MainTable;
	ReverseCorrespondence = CorrespondenceParameters.ReverseCorrespondence;
	
	SearchFields = CorrespondenceGenerationParameters.FillParameters.SearchFields;
	ServiceRegisterName = CorrespondenceGenerationParameters.FillParameters.ServiceRegisterName;
	ResourcesParameters = CorrespondenceGenerationParameters.FillParameters.ResourcesParameters;
	
	If AnalyticsLines_Dr.Count() > 1	Or AnalyticsLines_Cr.Count() > 1 Then
		If AnalyticsLines_Dr.Count() > 1 Then
			ManyAnalysts = New Structure("DrCr,AnalyticsLines_", "Dr", AnalyticsLines_Dr);
			OneDimension = New Structure("DrCr,AnalyticsLines_", "Cr", AnalyticsLines_Cr);
		Else
			OneDimension = New Structure("DrCr,AnalyticsLines_", "Dr", AnalyticsLines_Dr);
			ManyAnalysts = New Structure("DrCr,AnalyticsLines_", "Cr", AnalyticsLines_Cr);
		EndIf;
	ElsIf MotionSampling_["RegisterName" + ?(ReverseCorrespondence, "Cr", "Dr")] = ServiceRegisterName Then
		ManyAnalysts = New Structure("DrCr,AnalyticsLines_", "Cr", AnalyticsLines_Cr);
		OneDimension = New Structure("DrCr,AnalyticsLines_", "Dr", AnalyticsLines_Dr);
	Else
		ManyAnalysts = New Structure("DrCr,AnalyticsLines_", "Dr", AnalyticsLines_Dr);
		OneDimension = New Structure("DrCr,AnalyticsLines_", "Cr", AnalyticsLines_Cr);
	EndIf;
	
	If ReverseCorrespondence Then
		ManyAnalysts.Insert("DrCr", ?(ManyAnalysts.DrCr = "Dr", "Cr", "Dr"));
		OneDimension.Insert("DrCr", ?(OneDimension.DrCr = "Dr", "Cr", "Dr"));
	EndIf;
	ResourcesOfManyAnalysts = FinancialAccountingByBalanceSheetRegisterData.RecalculatedResourcesOfManyAnalysts(
		MotionSampling_, ManyAnalysts, ResourcesParameters);
	SingleAnalyticsResources = FinancialAccountingByBalanceSheetRegisterData.DistributedResourcesOfSingleAnalytics(
		MotionSampling_, OneDimension, ResourcesOfManyAnalysts, ResourcesParameters);
	If ReverseCorrespondence Then
		ManyAnalysts.Insert("DrCr", ?(ManyAnalysts.DrCr = "Dr", "Cr", "Dr"));
		OneDimension.Insert("DrCr", ?(OneDimension.DrCr = "Dr", "Cr", "Dr"));
	EndIf;
	
	ZoomRatio = ?(ReverseCorrespondence Or MotionSampling_.InvertEntriy And MotionSampling_.RegisterNameDr = MotionSampling_.RegisterNameCr, -1, 1);
	
	For Counter = 1 To ManyAnalysts.AnalyticsLines_.Count() Do
		
		AnalyticsLine_ = ManyAnalysts.AnalyticsLines_[Counter-1];
		If MainTable Then
			NewRow = CorrespondencesTable.Add();
			FillPropertyValues(NewRow, MotionSampling_, SearchFields);
			If AnalyticsLine_.RegisterName <> ServiceRegisterName Then
				FillPropertyValues(NewRow, AnalyticsLine_, StrConcat(CorrespondenceAnalytics["Dimension"
					+ ManyAnalysts.DrCr], ","));
			EndIf;
			If OneDimension.AnalyticsLines_[0].RegisterName <> ServiceRegisterName Then
				FillPropertyValues(NewRow, OneDimension.AnalyticsLines_[0], StrConcat(
					CorrespondenceAnalytics["Dimension" + OneDimension.DrCr], ","));
			EndIf;
			If ValueIsFilled(MotionSampling_.RowIDDr)
				And StrLen(MotionSampling_.RowIDDr) = 36 Then
				NewRow.FinRecordID = MotionSampling_.RowIDDr;
			ElsIf ValueIsFilled(MotionSampling_.RowIDCr)
				And StrLen(MotionSampling_.RowIDCr) = 36 Then
				NewRow.FinRecordID = MotionSampling_.RowIDCr;
			EndIf;
			If ValueIsFilled(AnalyticsLine_.Currency) Then
				NewRow.Currency = AnalyticsLine_.Currency;
				If ValueIsFilled(SingleAnalyticsResources[Counter-1].Currency)
					And CorrespondencesTable.Columns.Find("CorrespondingCurency") <> Undefined Then
					NewRow.CorrespondingCurency = SingleAnalyticsResources[Counter-1].Currency;
				EndIf;
			Else
				NewRow.Currency = SingleAnalyticsResources[Counter-1].Currency;
			EndIf;
			If CorrespondencesTable.Columns.Find("PaymentDivision") <> Undefined
				And Not ValueIsFilled(NewRow.PaymentDivision) Then
				If CorrespondencesTable.Columns.Find("CorDivisionOfPayment") <> Undefined Then
					NewRow.PaymentDivision = NewRow.CorDivisionOfPayment;
				Else
					NewRow.PaymentDivision = NewRow.Department;
				EndIf;
			EndIf;
		Else
			TheStructureOfTheSearch = New Structure(SearchFields);
			FillPropertyValues(TheStructureOfTheSearch, MotionSampling_);
			If ValueIsFilled(MotionSampling_.RowIDDr) Then
				TheStructureOfTheSearch.FinRecordID = MotionSampling_.RowIDDr;
			ElsIf ValueIsFilled(MotionSampling_.RowIDCr) Then
				TheStructureOfTheSearch.FinRecordID = MotionSampling_.RowIDCr;
			EndIf;
			ThisIsTransferOfAmount = MotionSampling_.RegisterNameDr = MotionSampling_.RegisterNameCr
				And ValueIsFilled(MotionSampling_.FactorDr)
				And ValueIsFilled(MotionSampling_.FactorCr)
				And MotionSampling_.FactorDr <> MotionSampling_.FactorCr;
			If ThisIsTransferOfAmount Then
				TheStructureOfTheSearch.Delete("Period");
			EndIf;
			FoundRows = CorrespondencesTable.FindRows(TheStructureOfTheSearch);
			If FoundRows.Count() = 0 Then
				Return;
			EndIf;
			NewRow = FoundRows[0];
		EndIf;
		ArrayOfIndicators = New Array;
		If MotionSampling_.RegisterNameDr <> ServiceRegisterName Then
			ArrayOfIndicators.Add(MotionSampling_.FactorDr);
		Else
			ServiceIndicators = DataSourcesCached.DefaultAmountIndicatorsByDataSource(
				MotionSampling_.SettingUpBusinessTransaction);
			ArrayOfIndicators.Add(ServiceIndicators[0]);
		EndIf;
		If MotionSampling_.RegisterNameCr <> ServiceRegisterName Then
			ArrayOfIndicators.Add(MotionSampling_.FactorCr);
		Else
			ServiceIndicators = DataSourcesCached.DefaultAmountIndicatorsByDataSource(
				MotionSampling_.SettingUpBusinessTransaction);
			ArrayOfIndicators.Add(ServiceIndicators[0]);
		EndIf;
		ArrayOfIndicators = CommonClientServer.CollapseArray(ArrayOfIndicators);
		// There can be only one empty indicator - then the SummaUpr, SummaRegl, SummaVal columns are used
		If ArrayOfIndicators.Count() > 1 Then
			CommonClientServer.DeleteValueFromArray(ArrayOfIndicators,
				Enums.IndicatorsOfAnalyticalRegisters.EmptyRef());
			If ArrayOfIndicators.Find(Enums.IndicatorsOfAnalyticalRegisters.Sum) <> Undefined
				And (MotionSampling_.RegisterNameDr = ServiceRegisterName
				Or MotionSampling_.RegisterNameCr = ServiceRegisterName)
				And ArrayOfIndicators.Count() > 1 Then
				// If an indicator is set for the main register, then the Sum indicator is not needed for the service register
				CommonClientServer.DeleteValueFromArray(ArrayOfIndicators,
					Enums.IndicatorsOfAnalyticalRegisters.Sum);
			EndIf;
		EndIf;
		For Each Factor In ArrayOfIndicators Do
			If Not MainTable And ThisIsTransferOfAmount And Factor = MotionSampling_.FactorCr Then
				TransferCoefficientOfAmount = -1;
			Else
				TransferCoefficientOfAmount = 1;
			EndIf;
			If ValueIsFilled(Factor) Then
				IndicatorNames = SummaryResources.Get(Factor);
			Else
				IndicatorNames = SummaryResources.Get(Enums.IndicatorsOfAnalyticalRegisters.Sum);
			EndIf;
			NewRow[IndicatorNames.NameOfManIndicator] = ?(Not MainTable, NewRow[IndicatorNames.NameOfManIndicator], 0)
				+ ResourcesOfManyAnalysts[Counter - 1].SumMan * ZoomRatio * TransferCoefficientOfAmount;
			NewRow[IndicatorNames.NameOfIndicatorIsLocal] = ?(Not MainTable, NewRow[IndicatorNames.NameOfIndicatorIsLocal], 0)
				+ ResourcesOfManyAnalysts[Counter - 1].SumCompl * ZoomRatio * TransferCoefficientOfAmount;
			If IndicatorNames.Property("IndicatorNameShaft")
				And CorrespondencesTable.Columns.Find(IndicatorNames.IndicatorNameShaft) <> Undefined Then
				If ValueIsFilled(AnalyticsLine_.SumCurr) Then
					NewRow[IndicatorNames.IndicatorNameShaft] = ?(Not MainTable, NewRow[IndicatorNames.IndicatorNameShaft], 0)
						+ ResourcesOfManyAnalysts[Counter - 1].SumCurr * ZoomRatio * TransferCoefficientOfAmount;
				Else
					NewRow[IndicatorNames.IndicatorNameShaft] = ?(Not MainTable, NewRow[IndicatorNames.IndicatorNameShaft], 0)
						+ SingleAnalyticsResources[Counter - 1].SumCurr * ZoomRatio * TransferCoefficientOfAmount;
				EndIf;
			EndIf;
		EndDo;
		If CorrespondencesTable.Columns.Find("Count") <> Undefined Then
			If CorrespondencesTable.Columns.Find("CorQuantity") <> Undefined Then
				If MotionSampling_["Quantitative"+?(ReverseCorrespondence, "Dr", "Cr")] Then
					NewRow.Count = ?(ManyAnalysts.DrCr = "Dr", SingleAnalyticsResources[Counter
						- 1].Count, ResourcesOfManyAnalysts[Counter - 1].Count) * ZoomRatio;
				EndIf;
				If MotionSampling_["Quantitative"+?(ReverseCorrespondence, "Cr", "Dr")] Then
					NewRow.CorQuantity = ?(ManyAnalysts.DrCr = "Dr", ResourcesOfManyAnalysts[Counter
						- 1].Count, SingleAnalyticsResources[Counter - 1].Count) * ZoomRatio;
				EndIf;
				If Not ValueIsFilled(NewRow.Count) And ValueIsFilled(NewRow.CorQuantity) Then
					NewRow.Count = NewRow.CorQuantity;
					NewRow.CorQuantity = 0;
				EndIf;
			ElsIf MotionSampling_.QuantitativeDr Or MotionSampling_.QuantitativeCr Then
				NewRow.Count = ?(ValueIsFilled(AnalyticsLine_.Count), ResourcesOfManyAnalysts[Counter
					- 1].Count, SingleAnalyticsResources[Counter - 1].Count) * ZoomRatio;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Function RegisterCorrespondenceSearchFields()
	
	Return "Period,Recorder,Organization,FinRecordID";
	
EndFunction

#Region RequestTextsForProcessingRegisterRegisteredRecords

Procedure ProcessAndConnectMovementTables(Query, QueriesTexts)
	
	CollapseRegisteredRecordsByKeyFields(Query, QueriesTexts, "Dr");
	CollapseRegisteredRecordsByKeyFields(Query, QueriesTexts, "Cr");
	
	IdentifyComplexTransactionsWithIndicationOfCorSources(Query, QueriesTexts);
	
	AddDataSourceIDs(QueriesTexts, Query.Parameters, "Dr");
	AddDataSourceIDs(QueriesTexts, Query.Parameters, "Cr");
	
	AddTotalsForTransactionsAndFinancialRecords(QueriesTexts, "Dr");
	AddTotalsForTransactionsAndFinancialRecords(QueriesTexts, "Cr");
	
	ConnectRegisteredRecordsByKeyFields(Query, QueriesTexts);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRegisteredRecordsWithDebitTotals");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRegisteredRecordsWithCreditTotals");
	
EndProcedure

Procedure CollapseRegisteredRecordsByKeyFields(Query, QueriesTexts, DrCr)
	
	QueryText = "
	|SELECT
	|	TTRegisterRegisteredRecordsDrCr.Period AS Period,
	|	TTRegisterRegisteredRecordsDrCr.RegisterName AS RegisterName,
	|	TTRegisterRegisteredRecordsDrCr.ThisIsDrCr AS ThisIsDrCr,
	|	TTRegisterRegisteredRecordsDrCr.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	TTRegisterRegisteredRecordsDrCr.Recorder AS Recorder,
	|	TTRegisterRegisteredRecordsDrCr.Organization AS Organization,
	|	TTRegisterRegisteredRecordsDrCr.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	TTRegisterRegisteredRecordsDrCr.FinRecordID AS FinRecordID,
	|	TTRegisterRegisteredRecordsDrCr.RowID AS RowID,
	|	TTRegisterRegisteredRecordsDrCr.VATActivityType AS VATActivityType,
	|	TTRegisterRegisteredRecordsDrCr.Currency AS Currency,
	|	TTRegisterRegisteredRecordsDrCr.Factor AS Factor,
	|	TTRegisterRegisteredRecordsDrCr.AdditionalSetupOfHouseholdOperations AS AdditionalSetupOfHouseholdOperations,
	|	TTRegisterRegisteredRecordsDrCr.PropsStorno AS PropsStorno,
	|	MAX(TTRegisterRegisteredRecordsDrCr.RecNo) AS RecNo,
	|	SUM(TTRegisterRegisteredRecordsDrCr.SumMan) AS SumMan,
	|	SUM(TTRegisterRegisteredRecordsDrCr.SumCompl) AS SumCompl,
	|	SUM(TTRegisterRegisteredRecordsDrCr.SumCurr) AS SumCurr,
	|	SUM(TTRegisterRegisteredRecordsDrCr.Count) AS Count
	|INTO TTFoldedRegisteredRecordsDrCr
	|FROM
	|	TTRegisterRegisteredRecordsDrCr AS TTRegisterRegisteredRecordsDrCr
	|GROUP BY
	|	TTRegisterRegisteredRecordsDrCr.Period,
	|	TTRegisterRegisteredRecordsDrCr.Recorder,
	|	TTRegisterRegisteredRecordsDrCr.FinRecordID,
	|	TTRegisterRegisteredRecordsDrCr.RegisterName,
	|	TTRegisterRegisteredRecordsDrCr.Organization,
	|	TTRegisterRegisteredRecordsDrCr.SettingUpBusinessTransaction,
	|	TTRegisterRegisteredRecordsDrCr.RowID,
	|	TTRegisterRegisteredRecordsDrCr.VATActivityType,
	|	TTRegisterRegisteredRecordsDrCr.Currency,
	|	TTRegisterRegisteredRecordsDrCr.Factor,
	|	TTRegisterRegisteredRecordsDrCr.ThisIsDrCr,
	|	TTRegisterRegisteredRecordsDrCr.AdditionalSetupOfHouseholdOperations,
	|	TTRegisterRegisteredRecordsDrCr.ThisIsReverseTransaction,
	|	TTRegisterRegisteredRecordsDrCr.PropsStorno
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	RegisterName,
	|	Organization,
	|	SettingUpBusinessTransaction";
	ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	
	QueriesTexts.Add(QueryText);
	
	MotionTableName = "TTRegisterRegisteredRecordsDrCr";
	ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(MotionTableName, DrCr);
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, MotionTableName);
	
EndProcedure

Procedure IdentifyComplexTransactionsWithIndicationOfCorSources(Query, QueriesTexts)
	
	If Query.TempTablesManager.Tables.Find("TTCorDataSources") = Undefined Then
		QueriesTexts.Add("
		|SELECT
		|	CorDataSources.Factor AS Factor,
		|	CorDataSources.RegisterName AS RegisterName,
		|	CorDataSources.CorDataSource AS CorRegisterName,
		|	CorDataSources.Id AS Id,
		|	CorDataSources.CorID AS CorID
		|INTO TTCorDataSources
		|FROM
		|	&CorDataSources AS CorDataSources
		|INDEX BY
		|	Factor,
		|	RegisterName
		|");
		
		QueriesTexts.Add("
		|SELECT
		|	CorDataSources.Factor AS Factor,
		|	CorDataSources.RegisterName AS RegisterName,
		|	CorDataSources.Id AS Id
		|INTO TTIdsOfCorDataSources
		|FROM
		|	TTCorDataSources AS CorDataSources
		|GROUP BY
		|	CorDataSources.Factor,
		|	CorDataSources.RegisterName,
		|	CorDataSources.Id
		|INDEX BY
		|	Factor,
		|	RegisterName
		|");
	EndIf;
	
	QueriesTexts.Add("
	|SELECT
	|	DirectDebit.Period AS Period,
	|	DirectDebit.Organization AS Organization,
	|	DirectDebit.Recorder AS Recorder,
	|	DirectDebit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	DirectDebit.FinRecordID AS FinRecordID,
	|	CorDataSources.CorRegisterName AS CorRegisterName,
	|	CorDataSources.CorID AS CorID,
	|	COUNT(DISTINCT DirectDebit.Factor) AS NumberOfIndicators,
	|	COUNT(DISTINCT DirectDebit.RegisterName) AS NumberOfRegisters
	|INTO TTTransactionIDsDebit
	|FROM
	|	TTCollapsedRegisteredRecordsDebit AS DirectDebit
	|	INNER JOIN TTCorDataSources AS CorDataSources
	|		ON DirectDebit.Factor = CorDataSources.Factor
	|		AND DirectDebit.RegisterName = CorDataSources.RegisterName
	|GROUP BY
	|	DirectDebit.Period,
	|	DirectDebit.Recorder,
	|	DirectDebit.FinRecordID,
	|	DirectDebit.Organization,
	|	DirectDebit.SettingUpBusinessTransaction,
	|	CorDataSources.CorRegisterName,
	|	CorDataSources.CorID
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	CorRegisterName,
	|	Organization,
	|	SettingUpBusinessTransaction
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	MovementCredit.Period AS Period,
	|	MovementCredit.Organization AS Organization,
	|	MovementCredit.Recorder AS Recorder,
	|	MovementCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	MovementCredit.FinRecordID AS FinRecordID,
	|	CorDataSources.CorRegisterName AS CorRegisterName,
	|	CorDataSources.CorID AS CorID,
	|	COUNT(DISTINCT MovementCredit.Factor) AS NumberOfIndicators,
	|	COUNT(DISTINCT MovementCredit.RegisterName) AS NumberOfRegisters
	|INTO TTTransactionIDsCredit
	|FROM
	|	TTRolledUpMotionCredit AS MovementCredit
	|	INNER JOIN TTCorDataSources AS CorDataSources
	|		ON MovementCredit.Factor = CorDataSources.Factor
	|		AND MovementCredit.RegisterName = CorDataSources.RegisterName
	|GROUP BY
	|	MovementCredit.Period,
	|	MovementCredit.Recorder,
	|	MovementCredit.FinRecordID,
	|	MovementCredit.Organization,
	|	MovementCredit.SettingUpBusinessTransaction,
	|	CorDataSources.CorRegisterName,
	|	CorDataSources.CorID
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	CorRegisterName,
	|	Organization,
	|	SettingUpBusinessTransaction
	|");
	
	QueriesTexts.Add("
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	TTTransactionIDsDebit AS IdsOfDebitTransactions
	|WHERE
	|	IdsOfDebitTransactions.NumberOfIndicators > 1
	|	AND IdsOfDebitTransactions.NumberOfRegisters > 1
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	TTTransactionIDsCredit AS TransactionIDs_
	|WHERE
	|	TransactionIDs_.NumberOfIndicators > 1
	|	AND TransactionIDs_.NumberOfRegisters > 1
	|");
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	QueriesTexts.Clear();
	
	Results = Query.ExecuteBatch();
	HasComplexEntries = Not Results[Results.UBound()].IsEmpty();
	
	If Not HasComplexEntries Then
		Query.Text = "
		|SELECT TOP 1
		|	DirectDebit.Period AS Period,
		|	DirectDebit.RegisterName AS RegisterName,
		|	DirectDebit.Organization AS Organization,
		|	DirectDebit.Recorder AS Recorder,
		|	DirectDebit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
		|	DirectDebit.FinRecordID AS FinRecordID,
		|	COUNT(DISTINCT DirectDebit.Factor) AS NumberOfIndicators,
		|	COUNT(DISTINCT DirectDebit.RegisterName) AS NumberOfRegisters
		|FROM
		|	TTCollapsedRegisteredRecordsDebit AS DirectDebit
		|	INNER JOIN TTTransactionIDsCredit AS TransactionIDs_
		|		ON DirectDebit.Period = TransactionIDs_.Period
		|		 AND DirectDebit.Recorder = TransactionIDs_.Recorder
		|		 AND DirectDebit.FinRecordID = TransactionIDs_.FinRecordID
		|		 AND DirectDebit.RegisterName = TransactionIDs_.CorRegisterName
		|		 AND DirectDebit.Organization = TransactionIDs_.Organization
		|		 AND CASE
		|			WHEN DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
		|				AND TransactionIDs_.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
		|				THEN DirectDebit.SettingUpBusinessTransaction = TransactionIDs_.SettingUpBusinessTransaction
		|			ELSE TRUE
		|		 END
		|GROUP BY
		|	DirectDebit.Period,
		|	DirectDebit.Recorder,
		|	DirectDebit.FinRecordID,
		|	DirectDebit.RegisterName,
		|	DirectDebit.Organization,
		|	DirectDebit.SettingUpBusinessTransaction
		|HAVING
		|	COUNT(DISTINCT DirectDebit.Factor) > 1
		|	AND COUNT(DISTINCT DirectDebit.RegisterName) > 1
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	MovementCredit.Period AS Period,
		|	MovementCredit.RegisterName AS RegisterName,
		|	MovementCredit.Organization AS Organization,
		|	MovementCredit.Recorder AS Recorder,
		|	MovementCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
		|	MovementCredit.FinRecordID AS FinRecordID,
		|	COUNT(DISTINCT MovementCredit.Factor) AS NumberOfIndicators,
		|	COUNT(DISTINCT MovementCredit.RegisterName) AS NumberOfRegisters
		|FROM
		|	TTRolledUpMotionCredit AS MovementCredit
		|	INNER JOIN TTTransactionIDsDebit AS IdsOfDebitTransactions
		|		ON MovementCredit.Period = IdsOfDebitTransactions.Period
		|		 AND MovementCredit.Recorder = IdsOfDebitTransactions.Recorder
		|		 AND MovementCredit.FinRecordID = IdsOfDebitTransactions.FinRecordID
		|		 AND MovementCredit.RegisterName = IdsOfDebitTransactions.CorRegisterName
		|		 AND MovementCredit.Organization = IdsOfDebitTransactions.Organization
		|		 AND CASE
		|			WHEN MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
		|				AND IdsOfDebitTransactions.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
		|				THEN MovementCredit.SettingUpBusinessTransaction = IdsOfDebitTransactions.SettingUpBusinessTransaction
		|			ELSE TRUE
		|		 END
		|GROUP BY
		|	MovementCredit.Period,
		|	MovementCredit.Recorder,
		|	MovementCredit.FinRecordID,
		|	MovementCredit.RegisterName,
		|	MovementCredit.Organization,
		|	MovementCredit.SettingUpBusinessTransaction
		|HAVING
		|	COUNT(DISTINCT MovementCredit.Factor) > 1
		|	AND COUNT(DISTINCT MovementCredit.RegisterName) > 1
		|";
		
		Result = Query.Execute();
		HasComplexEntries = Not Result.IsEmpty();
	EndIf;
	
	If Not HasComplexEntries Then
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTTransactionIDsDebit");
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTTransactionIDsCredit");
	EndIf;
	
	Query.Parameters.ComplexTransactionsWithIndicationOfCorSources = HasComplexEntries;
	
EndProcedure

Procedure AddDataSourceIDs(QueriesTexts, QueryOptions, DrCr)
	
	QueryText = "
	|SELECT
	|	RegisterRegisteredRecords_1.Period AS Period,
	|	RegisterRegisteredRecords_1.RecNo AS RecNo,
	|	RegisterRegisteredRecords_1.RegisterName AS RegisterName,
	|	RegisterRegisteredRecords_1.Factor AS Factor,
	|	RegisterRegisteredRecords_1.ThisIsDrCr AS ThisIsDrCr,
	|	RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRegisteredRecords_1.Organization AS Organization,
	|	RegisterRegisteredRecords_1.Recorder AS Recorder,
	|	RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
	|	RegisterRegisteredRecords_1.RowID AS RowID,
	|	RegisterRegisteredRecords_1.VATActivityType AS VATActivityType,
	|	RegisterRegisteredRecords_1.AdditionalSetupOfHouseholdOperations AS AdditionalSetupOfHouseholdOperations,
	|	RegisterRegisteredRecords_1.Currency AS Currency,
	|	RegisterRegisteredRecords_1.SumMan AS SumMan,
	|	RegisterRegisteredRecords_1.SumCompl AS SumCompl,
	|	RegisterRegisteredRecords_1.SumCurr AS SumCurr,
	|	RegisterRegisteredRecords_1.Count AS Count,
	|	RegisterRegisteredRecords_1.PropsStorno AS PropsStorno,
	|	&ThereAreCorDataSources AS ThereAreCorDataSources,
	|	&IDOfCorOfDataSources AS IDOfCorOfDataSources
	|INTO TTRegisteredRecordsDrCr
	|FROM
	|	TTFoldedRegisteredRecordsDrCr AS RegisterRegisteredRecords_1
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	SettingUpBusinessTransaction,
	|	Organization,
	|	IDOfCorOfDataSources
	|";
	
	If QueryOptions.ComplexTransactionsWithIndicationOfCorSources Then
		QueryText = StrReplace(QueryText,
			"TTFoldedRegisteredRecordsDrCr AS RegisterRegisteredRecords_1",
			"TTFoldedRegisteredRecordsDrCr AS RegisterRegisteredRecords_1
			|	LEFT JOIN TTIdsOfCorDataSources AS IdsOfCorDataSources
			|		ON RegisterRegisteredRecords_1.Factor = IdsOfCorDataSources.Factor
			|		AND RegisterRegisteredRecords_1.RegisterName = IdsOfCorDataSources.RegisterName");
		
		QueryText = StrReplace(QueryText,
			"INTO TTRegisteredRecordsDrCr",
			"INTO TTRegisterRegisteredRecordsDrCr");
		
		QueryText = StrReplace(QueryText,
			"INDEX BY
			|	Period,
			|	Recorder,
			|	FinRecordID,",
			"INDEX BY
			|	Period,
			|	Recorder,
			|	FinRecordID,
			|	RegisterName,");
		
		ThereAreCorDataSources = "NOT IdsOfCorDataSources.Id IS NULL";
		IDOfCorOfDataSources = "ISNULL(IdsOfCorDataSources.Id, """")";
	Else
		ThereAreCorDataSources = "TRUE IN
			|		(SELECT TOP 1
			|			TRUE
			|		FROM
			|			TTIdsOfCorDataSources AS IdsOfCorDataSources
			|		WHERE
			|			IdsOfCorDataSources.Factor = RegisterRegisteredRecords_1.Factor
			|			AND IdsOfCorDataSources.RegisterName = RegisterRegisteredRecords_1.RegisterName
			|		)";
		IDOfCorOfDataSources = """""";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ThereAreCorDataSources", ThereAreCorDataSources);
	QueryText = StrReplace(QueryText, "&IDOfCorOfDataSources", IDOfCorOfDataSources);
	
	ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	MotionTableName = "TTFoldedRegisteredRecordsDrCr";
	ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(MotionTableName, DrCr);
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, MotionTableName);
	
	If QueryOptions.ComplexTransactionsWithIndicationOfCorSources Then
		QueryText = "
		|SELECT
		|	RegisterRegisteredRecords_1.Period AS Period,
		|	RegisterRegisteredRecords_1.RecNo AS RecNo,
		|	RegisterRegisteredRecords_1.RegisterName AS RegisterName,
		|	RegisterRegisteredRecords_1.Factor AS Factor,
		|	RegisterRegisteredRecords_1.ThisIsDrCr AS ThisIsDrCr,
		|	RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
		|	RegisterRegisteredRecords_1.Organization AS Organization,
		|	RegisterRegisteredRecords_1.Recorder AS Recorder,
		|	RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
		|	RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
		|	RegisterRegisteredRecords_1.RowID AS RowID,
		|	RegisterRegisteredRecords_1.VATActivityType AS VATActivityType,
		|	RegisterRegisteredRecords_1.AdditionalSetupOfHouseholdOperations AS AdditionalSetupOfHouseholdOperations,
		|	RegisterRegisteredRecords_1.Currency AS Currency,
		|	RegisterRegisteredRecords_1.SumMan AS SumMan,
		|	RegisterRegisteredRecords_1.SumCompl AS SumCompl,
		|	RegisterRegisteredRecords_1.SumCurr AS SumCurr,
		|	RegisterRegisteredRecords_1.Count AS Count,
		|	RegisterRegisteredRecords_1.PropsStorno AS PropsStorno,
		|	RegisterRegisteredRecords_1.ThereAreCorDataSources AS ThereAreCorDataSources,
		|	CASE
		|		WHEN RegisterRegisteredRecords_1.IDOfCorOfDataSources <> """"
		|			THEN RegisterRegisteredRecords_1.IDOfCorOfDataSources
		|		ELSE ISNULL(CorTransactionIds.CorID, """")
		|	END AS IDOfCorOfDataSources
		|INTO TTRegisteredRecordsDrCr
		|FROM
		|	TTRegisterRegisteredRecordsDrCr AS RegisterRegisteredRecords_1
		|	LEFT JOIN TTCtTransactionIdsDrCr AS CorTransactionIds
		|		ON RegisterRegisteredRecords_1.Period = CorTransactionIds.Period
		|		 AND RegisterRegisteredRecords_1.Recorder = CorTransactionIds.Recorder
		|		 AND RegisterRegisteredRecords_1.FinRecordID = CorTransactionIds.FinRecordID
		|		 AND RegisterRegisteredRecords_1.RegisterName = CorTransactionIds.CorRegisterName
		|		 AND RegisterRegisteredRecords_1.Organization = CorTransactionIds.Organization
		|		 AND CASE
		|			WHEN RegisterRegisteredRecords_1.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
		|				AND CorTransactionIds.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
		|				THEN RegisterRegisteredRecords_1.SettingUpBusinessTransaction = CorTransactionIds.SettingUpBusinessTransaction
		|			ELSE TRUE
		|		 END
		|INDEX BY
		|	Period,
		|	Recorder,
		|	FinRecordID,
		|	SettingUpBusinessTransaction,
		|	Organization,
		|	IDOfCorOfDataSources
		|";
		
		ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
		QueriesTexts.Add(QueryText);
		
		MotionTableName = "TTRegisterRegisteredRecordsDrCr";
		ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(MotionTableName, DrCr);
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, MotionTableName);
		
		MotionTableName = "TTCtTransactionIdsDrCr";
		ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(MotionTableName, DrCr);
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, MotionTableName);
	EndIf;
	
EndProcedure

Procedure AddTotalsForTransactionsAndFinancialRecords(QueriesTexts, DrCr)
	
	QueryText = "
	|SELECT
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.Organization AS Organization,
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRecords.FinRecordID AS FinRecordID,
	|	RegisterRecords.IDOfCorOfDataSources AS IDOfCorOfDataSources,
	|	COUNT(RegisterRecords.FinRecordID) AS NumberOfFinRecords,
	|	SUM(RegisterRecords.SumMan) AS SumMan,
	|	SUM(RegisterRecords.SumCompl) AS SumCompl,
	|	MAX(RegisterRecords.SumMan = 0 AND RegisterRecords.SumCompl = 0) AS ThereIsZeroBalance
	|INTO TTResultsOfOperations
	|FROM
	|	TTRegisteredRecordsDrCr AS RegisterRecords
	|WHERE
	|	NOT RegisterRecords.Factor IN (&IndicatorsForCorrespondingRegisters)
	|GROUP BY
	|	RegisterRecords.Period,
	|	RegisterRecords.Recorder,
	|	RegisterRecords.FinRecordID,
	|	RegisterRecords.Organization,
	|	RegisterRecords.SettingUpBusinessTransaction,
	|	RegisterRecords.IDOfCorOfDataSources
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization,
	|	SettingUpBusinessTransaction,
	|	IDOfCorOfDataSources
	|";
	
	ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	QueryText = "
	|SELECT
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.Organization AS Organization,
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.FinRecordID AS FinRecordID,
	|	COUNT(RegisterRecords.FinRecordID) AS NumberOfFinRecords,
	|	SUM(RegisterRecords.SumMan) AS SumMan,
	|	SUM(RegisterRecords.SumCompl) AS SumCompl,
	|	MAX(RegisterRecords.SumMan = 0 AND RegisterRecords.SumCompl = 0) AS ThereIsZeroBalance
	|INTO TTResultsForFinRecords
	|FROM
	|	TTRegisteredRecordsDrCr AS RegisterRecords
	|WHERE
	|	NOT RegisterRecords.Factor IN (&IndicatorsForCorrespondingRegisters)
	|	AND RegisterRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTMotionCorDrCr AS MotionCor
	|		WHERE
	|			MotionCor.Period = RegisterRecords.Period
	|			AND MotionCor.Recorder = RegisterRecords.Recorder
	|			AND MotionCor.FinRecordID = RegisterRecords.FinRecordID
	|			AND MotionCor.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			AND MotionCor.Organization = RegisterRecords.Organization
	|			AND MotionCor.ThisIsCorDrCr
	|			AND NOT MotionCor.Factor IN (&IndicatorsForCorrespondingRegisters)
	|		)
	|	AND NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTMotionCorDrCr AS MotionCor
	|			LEFT JOIN TTCorDataSources AS CorDataSources
	|				ON CorDataSources.Factor = RegisterRecords.Factor
	|				AND CorDataSources.RegisterName = RegisterRecords.RegisterName
	|			LEFT JOIN TTCorDataSources AS DataSources
	|				ON DataSources.Factor = MotionCor.Factor
	|				AND DataSources.RegisterName = MotionCor.RegisterName
	|		WHERE
	|			MotionCor.Period = RegisterRecords.Period
	|			AND MotionCor.Recorder = RegisterRecords.Recorder
	|			AND MotionCor.FinRecordID = RegisterRecords.FinRecordID
	|			AND MotionCor.SettingUpBusinessTransaction = RegisterRecords.SettingUpBusinessTransaction
	|			AND MotionCor.Organization = RegisterRecords.Organization
	|			AND MotionCor.ThisIsCorDrCr
	|			AND (MotionCor.Factor <> RegisterRecords.Factor OR MotionCor.RegisterName <> RegisterRecords.RegisterName OR MotionCor.ThisIsReverseTransaction = RegisterRecords.ThisIsReverseTransaction)
	|			AND CASE
	|				WHEN NOT DataSources.Factor IS NULL
	|					THEN DataSources.CorRegisterName = RegisterRecords.RegisterName
	|				WHEN NOT CorDataSources.Factor IS NULL
	|					THEN CorDataSources.CorRegisterName = MotionCor.RegisterName
	|				ELSE TRUE
	|			END
	|			AND NOT MotionCor.Factor IN (&IndicatorsForCorrespondingRegisters)
	|		)
	|GROUP BY
	|	RegisterRecords.Period,
	|	RegisterRecords.Recorder,
	|	RegisterRecords.FinRecordID,
	|	RegisterRecords.Organization
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization
	|";
	
	ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	QueryText = "
	|SELECT
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.RecNo AS RecNo,
	|	RegisterRecords.RegisterName AS RegisterName,
	|	RegisterRecords.ThisIsDrCr AS ThisIsDrCr,
	|	RegisterRecords.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRecords.Organization AS Organization,
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRecords.AdditionalSetupOfHouseholdOperations AS AdditionalSetupOfHouseholdOperations,
	|	RegisterRecords.FinRecordID AS FinRecordID,
	|	RegisterRecords.RowID AS RowID,
	|	RegisterRecords.VATActivityType AS VATActivityType,
	|	RegisterRecords.Currency AS Currency,
	|	RegisterRecords.Factor AS Factor,
	|	RegisterRecords.SumMan AS SumMan,
	|	RegisterRecords.SumCompl AS SumCompl,
	|	RegisterRecords.SumCurr AS SumCurr,
	|	RegisterRecords.Count AS Count,
	|	RegisterRecords.PropsStorno AS PropsStorno,
	|	RegisterRecords.ThereAreCorDataSources AS ThereAreCorDataSources,
	|	ISNULL(ResultsForOperations.NumberOfFinRecords, 0) AS NumberOfOperationRecords,
	|	ISNULL(ResultsForOperations.SumMan, 0) AS TransactionManAmount,
	|	ISNULL(ResultsForOperations.SumCompl, 0) AS AmountOfLocalTransaction,
	|	ISNULL(ResultsForOperations.ThereIsZeroBalance, FALSE) AS ThereIsZeroBalanceOfOperation,
	|	ISNULL(ResultsForFinRecords.NumberOfFinRecords, 0) AS NumberOfEntriesFinEntries,
	|	ISNULL(ResultsForFinRecords.SumMan, 0) AS AmountOfManFinRecord,
	|	ISNULL(ResultsForFinRecords.SumCompl, 0) AS AmountOfLocalFinRecord,
	|	ISNULL(ResultsForFinRecords.ThereIsZeroBalance, FALSE) AS ThereIsZeroBalanceOfFinRecord,
	|	VALUETYPE(RegisterRecords.Recorder) AS TypeOfRegistrar
	|INTO TTRegisteredRecordsWithDrCrTotals
	|FROM
	|	TTRegisteredRecordsDrCr AS RegisterRecords
	|	LEFT JOIN TTResultsOfOperations AS ResultsForOperations
	|		ON RegisterRecords.Period = ResultsForOperations.Period
	|		 AND RegisterRecords.Recorder = ResultsForOperations.Recorder
	|		 AND RegisterRecords.FinRecordID = ResultsForOperations.FinRecordID
	|		 AND RegisterRecords.Organization = ResultsForOperations.Organization
	|		 AND RegisterRecords.SettingUpBusinessTransaction = ResultsForOperations.SettingUpBusinessTransaction
	|		 AND RegisterRecords.IDOfCorOfDataSources = ResultsForOperations.IDOfCorOfDataSources
	|	LEFT JOIN TTResultsForFinRecords AS ResultsForFinRecords
	|		ON RegisterRecords.Period = ResultsForFinRecords.Period
	|		 AND RegisterRecords.Recorder = ResultsForFinRecords.Recorder
	|		 AND RegisterRecords.FinRecordID = ResultsForFinRecords.FinRecordID
	|		 AND RegisterRecords.Organization = ResultsForFinRecords.Organization
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization,
	|	SettingUpBusinessTransaction,
	|	Factor
	|";
	
	ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTResultsOfOperations");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTResultsForFinRecords");
	
EndProcedure

Procedure ConnectRegisteredRecordsByKeyFields(Query, QueriesTexts)
	
	QueryText = "
	|SELECT
	|	ISNULL(DirectDebit.Period, MovementCredit.Period) AS Period,
	|	ISNULL(DirectDebit.RecNo, 0) AS RecNoDr,
	|	ISNULL(MovementCredit.RecNo, 0) AS RecNoCr,
	|	CASE
	|		WHEN NOT DirectDebit.RegisterName IS NULL
	|			THEN DirectDebit.RegisterName
	|		WHEN MovementCredit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects)
	|			THEN &NameOfRegisterOfServiceAccountingObjects
	|		ELSE """"
	|	END AS RegisterNameDr,
	|	CASE
	|		WHEN NOT MovementCredit.RegisterName IS NULL
	|			THEN MovementCredit.RegisterName
	|		WHEN DirectDebit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects)
	|			THEN &NameOfRegisterOfServiceAccountingObjects
	|		ELSE """"
	|	END AS RegisterNameCr,
	|	ISNULL(DirectDebit.AdditionalSetupOfHouseholdOperations, VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)) AS AdditionalSetupOfHouseholdOperationsDr,
	|	ISNULL(MovementCredit.AdditionalSetupOfHouseholdOperations, VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)) AS AdditionalSetupOfHouseholdOperationsCr,
	|	ISNULL(DirectDebit.ThisIsReverseTransaction, FALSE) AS ThisIsReverseTransactionDr,
	|	ISNULL(MovementCredit.ThisIsReverseTransaction, FALSE) AS ThisIsReverseTransactionCr,
	|	CASE
	|		WHEN DirectDebit.Organization IS NULL
	|			THEN MovementCredit.Organization
	|		WHEN MovementCredit.Organization IS NULL
	|			THEN DirectDebit.Organization
	|		WHEN DirectDebit.Organization = VALUE(Catalog.Companies.EmptyRef)
	|			THEN MovementCredit.Organization
	|		ELSE DirectDebit.Organization
	|	END AS Organization,
	|	ISNULL(DirectDebit.Recorder, MovementCredit.Recorder) AS Recorder,
	|	CASE
	|		WHEN DirectDebit.SettingUpBusinessTransaction IS NULL
	|			THEN MovementCredit.SettingUpBusinessTransaction
	|		WHEN MovementCredit.SettingUpBusinessTransaction IS NULL
	|			THEN DirectDebit.SettingUpBusinessTransaction
	|		WHEN DirectDebit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN MovementCredit.SettingUpBusinessTransaction
	|		ELSE DirectDebit.SettingUpBusinessTransaction
	|	END AS SettingUpBusinessTransaction,
	|	ISNULL(DirectDebit.FinRecordID, MovementCredit.FinRecordID) AS FinRecordID,
	|	ISNULL(DirectDebit.RowID, """") AS RowIDDr,
	|	ISNULL(MovementCredit.RowID, """") AS RowIDCr,
	|	ISNULL(DirectDebit.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) AS VATActivityTypeDr,
	|	ISNULL(MovementCredit.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) AS VATActivityTypeCr,
	|	ISNULL(DirectDebit.Currency, VALUE(Catalog.Currencies.EmptyRef)) AS CurrencyDr,
	|	ISNULL(MovementCredit.Currency, VALUE(Catalog.Currencies.EmptyRef)) AS CurrencyCr,
	|	CASE
	|		WHEN (DirectDebit.RegisterName IN (&RegistersOfRecoveryOfCalculationsOnStorno)
	|			OR MovementCredit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects))
	|			AND (MovementCredit.RegisterName IN (&RegistersOfRecoveryOfCalculationsOnStorno)
	|			OR DirectDebit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects))
	|			AND (NOT DirectDebit.RegisterName IN (&RegistersWithSelectionByIndicators)
	|			OR NOT MovementCredit.RegisterName IN (&RegistersWithSelectionByIndicators))
	|			THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.EmptyRef)
	|		ELSE ISNULL(DirectDebit.Factor, VALUE(Enum.IndicatorsOfAnalyticalRegisters.EmptyRef))
	|	END AS FactorDr,
	|	CASE
	|		WHEN (DirectDebit.RegisterName IN (&RegistersOfRecoveryOfCalculationsOnStorno)
	|			OR MovementCredit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects))
	|			AND (MovementCredit.RegisterName IN (&RegistersOfRecoveryOfCalculationsOnStorno)
	|			OR DirectDebit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects))
	|			AND (NOT DirectDebit.RegisterName IN (&RegistersWithSelectionByIndicators)
	|			OR NOT MovementCredit.RegisterName IN (&RegistersWithSelectionByIndicators))
	|			THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.EmptyRef)
	|		ELSE ISNULL(MovementCredit.Factor, VALUE(Enum.IndicatorsOfAnalyticalRegisters.EmptyRef))
	|	END AS FactorCr,
	|	ISNULL(DirectDebit.SumMan, 0) AS AmountOfManMovementDr,
	|	ISNULL(MovementCredit.SumMan, 0) AS AmountOfManMovementCr,
	|	ISNULL(DirectDebit.SumCompl, 0) AS AmountOfLocalTrafficDr,
	|	ISNULL(MovementCredit.SumCompl, 0) AS AmountOfLocalTrafficCr,
	|	ISNULL(DirectDebit.SumCurr, 0) AS AmountOfMovementShaftDr,
	|	ISNULL(MovementCredit.SumCurr, 0) AS AmountOfMovementCrShaft,
	|	ISNULL(DirectDebit.Count, 0) AS AmountOfDrMovement,
	|	ISNULL(MovementCredit.Count, 0) AS CrMotionCount,
	|	ISNULL(DirectDebit.PropsStorno, FALSE) AS PropsStornoDr,
	|	ISNULL(MovementCredit.PropsStorno, FALSE) AS PropsStornoCr,
	|	CASE
	|		WHEN DirectDebit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN CASE
	|				WHEN NOT ISNULL(MovementCredit.NumberOfEntriesFinEntries, 0) > 1
	|					THEN FALSE
	|				WHEN ISNULL(DirectDebit.SumMan, 0) = ISNULL(MovementCredit.AmountOfManFinRecord, 0)
	|				  OR ISNULL(DirectDebit.SumCompl, 0) = ISNULL(MovementCredit.AmountOfLocalFinRecord, 0)
	|					THEN ISNULL(DirectDebit.SumMan, 0) <> ISNULL(MovementCredit.SumMan, 0)
	|					  OR ISNULL(DirectDebit.SumCompl, 0) <> ISNULL(MovementCredit.SumCompl, 0)
	|					  OR ISNULL(MovementCredit.ThereIsZeroBalanceOfFinRecord, FALSE)
	|				ELSE FALSE
	|			END
	|		WHEN NOT (ISNULL(DirectDebit.NumberOfOperationRecords, 0) = 1 AND ISNULL(MovementCredit.NumberOfOperationRecords, 0) > 1)
	|			THEN FALSE
	|		WHEN ISNULL(DirectDebit.TransactionManAmount, 0) = ISNULL(MovementCredit.TransactionManAmount, 0)
	|		  OR ISNULL(DirectDebit.AmountOfLocalTransaction, 0) = ISNULL(MovementCredit.AmountOfLocalTransaction, 0)
	|			THEN ISNULL(DirectDebit.SumMan, 0) <> ISNULL(MovementCredit.SumMan, 0)
	|			  OR ISNULL(DirectDebit.SumCompl, 0) <> ISNULL(MovementCredit.SumCompl, 0)
	|			  OR ISNULL(MovementCredit.ThereIsZeroBalanceOfOperation, FALSE)
	|		ELSE FALSE
	|	END AS ComplexEntryDr,
	|	CASE
	|		WHEN MovementCredit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN CASE
	|				WHEN NOT ISNULL(DirectDebit.NumberOfEntriesFinEntries, 0) > 1
	|					THEN FALSE
	|				WHEN ISNULL(DirectDebit.AmountOfManFinRecord, 0) = ISNULL(MovementCredit.SumMan, 0)
	|				  OR ISNULL(DirectDebit.AmountOfLocalFinRecord, 0) = ISNULL(MovementCredit.SumCompl, 0)
	|					THEN ISNULL(DirectDebit.SumMan, 0) <> ISNULL(MovementCredit.SumMan, 0)
	|					  OR ISNULL(DirectDebit.SumCompl, 0) <> ISNULL(MovementCredit.SumCompl, 0)
	|					  OR ISNULL(DirectDebit.ThereIsZeroBalanceOfFinRecord, FALSE)
	|				ELSE FALSE
	|			END
	|		WHEN NOT (ISNULL(DirectDebit.NumberOfOperationRecords, 0) > 1 AND ISNULL(MovementCredit.NumberOfOperationRecords, 0) = 1)
	|			THEN FALSE
	|		WHEN ISNULL(DirectDebit.TransactionManAmount, 0) = ISNULL(MovementCredit.TransactionManAmount, 0)
	|		  OR ISNULL(DirectDebit.AmountOfLocalTransaction, 0) = ISNULL(MovementCredit.AmountOfLocalTransaction, 0)
	|			THEN ISNULL(DirectDebit.SumMan, 0) <> ISNULL(MovementCredit.SumMan, 0)
	|			  OR ISNULL(DirectDebit.SumCompl, 0) <> ISNULL(MovementCredit.SumCompl, 0)
	|			  OR ISNULL(DirectDebit.ThereIsZeroBalanceOfOperation, FALSE)
	|		ELSE FALSE
	|	END AS ComplexEntryCr,
	|	CASE
	|		WHEN DirectDebit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|		  OR MovementCredit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS TakeIntoAccountBusinessTransaction,
	|	CASE
	|		WHEN DirectDebit.SumMan IS NULL
	|			THEN CASE
	|				WHEN MovementCredit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects)
	|					THEN MovementCredit.SumMan
	|				ELSE 0
	|			END
	|		WHEN DirectDebit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN CASE
	|				WHEN DirectDebit.SumMan <> ISNULL(MovementCredit.AmountOfManFinRecord, 0)
	|					THEN DirectDebit.SumMan
	|				WHEN ISNULL(MovementCredit.NumberOfEntriesFinEntries, 0) > 1
	|					THEN ISNULL(MovementCredit.SumMan, 0)
	|				ELSE DirectDebit.SumMan
	|			END
	|		WHEN DirectDebit.Factor IN (&IndicatorsForCorrespondingRegisters)
	|			AND MovementCredit.Factor IN (&IndicatorsForCorrespondingRegisters)
	|			THEN CASE
	|				WHEN DirectDebit.SumMan > 0 AND DirectDebit.SumMan > MovementCredit.SumMan
	|					THEN MovementCredit.SumMan
	|				WHEN DirectDebit.SumMan < 0 AND DirectDebit.SumMan < MovementCredit.SumMan
	|					THEN MovementCredit.SumMan
	|			ELSE DirectDebit.SumMan
	|		END
	|		WHEN DirectDebit.TransactionManAmount <> ISNULL(MovementCredit.TransactionManAmount, 0)
	|			THEN DirectDebit.SumMan
	|		WHEN DirectDebit.NumberOfOperationRecords = 1 AND ISNULL(MovementCredit.NumberOfOperationRecords, 0) > 1
	|			THEN ISNULL(MovementCredit.SumMan, 0)
	|		ELSE DirectDebit.SumMan
	|	END AS SumManDr,
	|	CASE
	|		WHEN MovementCredit.SumMan IS NULL
	|			THEN CASE
	|				WHEN DirectDebit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects)
	|					THEN DirectDebit.SumMan
	|				ELSE 0
	|			END
	|		WHEN MovementCredit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN CASE
	|				WHEN ISNULL(DirectDebit.AmountOfManFinRecord, 0) <> MovementCredit.SumMan
	|					THEN MovementCredit.SumMan
	|				WHEN ISNULL(DirectDebit.NumberOfEntriesFinEntries, 0) > 1
	|					THEN ISNULL(DirectDebit.SumMan, 0)
	|				ELSE MovementCredit.SumMan
	|			END
	|		WHEN DirectDebit.Factor IN (&IndicatorsForCorrespondingRegisters)
	|			AND MovementCredit.Factor IN (&IndicatorsForCorrespondingRegisters)
	|			THEN CASE
	|				WHEN DirectDebit.SumMan > 0 AND DirectDebit.SumMan > MovementCredit.SumMan
	|					THEN MovementCredit.SumMan
	|				WHEN DirectDebit.SumMan < 0 AND DirectDebit.SumMan < MovementCredit.SumMan
	|					THEN MovementCredit.SumMan
	|			ELSE DirectDebit.SumMan
	|		END
	|		WHEN ISNULL(DirectDebit.TransactionManAmount, 0) <> MovementCredit.TransactionManAmount
	|			THEN MovementCredit.SumMan
	|		WHEN ISNULL(DirectDebit.NumberOfOperationRecords, 0) > 1 AND MovementCredit.NumberOfOperationRecords = 1
	|			THEN ISNULL(DirectDebit.SumMan, 0)
	|		ELSE MovementCredit.SumMan
	|	END AS SumManCr,
	|	CASE
	|		WHEN DirectDebit.SumCompl IS NULL
	|			THEN CASE
	|				WHEN MovementCredit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects)
	|					THEN MovementCredit.SumCompl
	|				ELSE 0
	|			END
	|		WHEN DirectDebit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN CASE
	|				WHEN DirectDebit.SumCompl <> ISNULL(MovementCredit.AmountOfLocalFinRecord, 0)
	|					THEN DirectDebit.SumCompl
	|				WHEN ISNULL(MovementCredit.NumberOfEntriesFinEntries, 0) > 1
	|					THEN ISNULL(MovementCredit.SumCompl, 0)
	|				ELSE DirectDebit.SumCompl
	|			END
	|		WHEN DirectDebit.AmountOfLocalTransaction <> ISNULL(MovementCredit.AmountOfLocalTransaction, 0)
	|			THEN DirectDebit.SumCompl
	|		WHEN DirectDebit.NumberOfOperationRecords = 1 AND ISNULL(MovementCredit.NumberOfOperationRecords, 0) > 1
	|			THEN ISNULL(MovementCredit.SumCompl, 0)
	|		ELSE DirectDebit.SumCompl
	|	END AS SumComplDr,
	|	CASE
	|		WHEN MovementCredit.SumCompl IS NULL
	|			THEN CASE
	|				WHEN DirectDebit.TypeOfRegistrar IN (&TypesOfRegistrarsOfServiceAccountingObjects)
	|					THEN DirectDebit.SumCompl
	|				ELSE 0
	|			END
	|		WHEN MovementCredit.SettingUpBusinessTransaction = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN CASE
	|				WHEN ISNULL(DirectDebit.AmountOfLocalFinRecord, 0) <> MovementCredit.SumCompl
	|					THEN MovementCredit.SumCompl
	|				WHEN ISNULL(DirectDebit.NumberOfEntriesFinEntries, 0) > 1
	|					THEN ISNULL(DirectDebit.SumCompl, 0)
	|				ELSE MovementCredit.SumCompl
	|			END
	|		WHEN ISNULL(DirectDebit.AmountOfLocalTransaction, 0) <> MovementCredit.AmountOfLocalTransaction
	|			THEN MovementCredit.SumCompl
	|		WHEN ISNULL(DirectDebit.NumberOfOperationRecords, 0) > 1 AND ISNULL(MovementCredit.NumberOfOperationRecords, 0) = 1
	|			THEN ISNULL(DirectDebit.SumCompl, 0)
	|		ELSE MovementCredit.SumCompl
	|	END AS SumComplCr
	|INTO TableOfCorrespondenceOfRegisteredRecordsOfRegisters
	|FROM
	|	TTRegisteredRecordsWithDebitTotals AS DirectDebit
	|	FULL JOIN TTRegisteredRecordsWithCreditTotals AS MovementCredit
	|	ON DirectDebit.Period = MovementCredit.Period
	|	AND DirectDebit.Recorder = MovementCredit.Recorder
	|	AND DirectDebit.FinRecordID = MovementCredit.FinRecordID
	|	AND DirectDebit.Organization = MovementCredit.Organization
	|	AND NOT DirectDebit.TypeOfRegistrar IN (&TypesOfResidueEntryDocuments)
	|	AND NOT MovementCredit.TypeOfRegistrar IN (&TypesOfResidueEntryDocuments)
	|	AND CASE
	|		WHEN DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			AND MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN DirectDebit.SettingUpBusinessTransaction = MovementCredit.SettingUpBusinessTransaction
	// correspondence of records with filled and empty XO settings is allowed if there are no other correspondence with the same XO for a record with filled XO
	|		WHEN DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTCredit AS CreditOnlyRegisteredRecords
	|					LEFT JOIN TTCorDataSources AS CorDataSources
	|						ON CorDataSources.Factor = DirectDebit.Factor
	|						AND CorDataSources.RegisterName = DirectDebit.RegisterName
	|					LEFT JOIN TTCorDataSources AS DataSources
	|						ON DataSources.Factor = CreditOnlyRegisteredRecords.Factor
	|						AND DataSources.RegisterName = CreditOnlyRegisteredRecords.RegisterName
	|				WHERE
	|					CreditOnlyRegisteredRecords.Period = DirectDebit.Period
	|					AND CreditOnlyRegisteredRecords.Recorder = DirectDebit.Recorder
	|					AND CreditOnlyRegisteredRecords.FinRecordID = DirectDebit.FinRecordID
	|					AND CreditOnlyRegisteredRecords.SettingUpBusinessTransaction = DirectDebit.SettingUpBusinessTransaction
	|					AND CreditOnlyRegisteredRecords.Organization = DirectDebit.Organization
	|					AND CreditOnlyRegisteredRecords.ThisIsLoan
	|					AND NOT CreditOnlyRegisteredRecords.Factor IN (&IndicatorsForCorrespondingRegisters)
	|					AND (CreditOnlyRegisteredRecords.Factor <> DirectDebit.Factor OR CreditOnlyRegisteredRecords.RegisterName <> DirectDebit.RegisterName OR CreditOnlyRegisteredRecords.ThisIsReverseTransaction = DirectDebit.ThisIsReverseTransaction)
	|					AND CASE
	|						WHEN NOT DataSources.Factor IS NULL
	|							THEN DataSources.CorRegisterName = DirectDebit.RegisterName
	|						WHEN NOT CorDataSources.Factor IS NULL
	|							THEN CorDataSources.CorRegisterName = CreditOnlyRegisteredRecords.RegisterName
	|						ELSE TRUE
	|					END
	|				)
	// correspondence of records with filled and empty XO settings is allowed if there are no other correspondence with the same XO for a record with filled XO
	|		WHEN MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTDebit AS DebitOnlyRegisteredRecords
	|					LEFT JOIN TTCorDataSources AS CorDataSources
	|						ON CorDataSources.Factor = MovementCredit.Factor
	|						AND CorDataSources.RegisterName = MovementCredit.RegisterName
	|					LEFT JOIN TTCorDataSources AS DataSources
	|						ON DataSources.Factor = DebitOnlyRegisteredRecords.Factor
	|						AND DataSources.RegisterName = DebitOnlyRegisteredRecords.RegisterName
	|				WHERE
	|					DebitOnlyRegisteredRecords.Period = MovementCredit.Period
	|					AND DebitOnlyRegisteredRecords.Recorder = MovementCredit.Recorder
	|					AND DebitOnlyRegisteredRecords.FinRecordID = MovementCredit.FinRecordID
	|					AND DebitOnlyRegisteredRecords.SettingUpBusinessTransaction = MovementCredit.SettingUpBusinessTransaction
	|					AND DebitOnlyRegisteredRecords.Organization = MovementCredit.Organization
	|					AND DebitOnlyRegisteredRecords.ThisIsDebit
	|					AND NOT DebitOnlyRegisteredRecords.Factor IN (&IndicatorsForCorrespondingRegisters)
	|					AND (DebitOnlyRegisteredRecords.Factor <> MovementCredit.Factor OR DebitOnlyRegisteredRecords.RegisterName <> MovementCredit.RegisterName OR DebitOnlyRegisteredRecords.ThisIsReverseTransaction = MovementCredit.ThisIsReverseTransaction)
	|					AND CASE
	|						WHEN NOT DataSources.Factor IS NULL
	|							THEN DataSources.CorRegisterName = MovementCredit.RegisterName
	|						WHEN NOT CorDataSources.Factor IS NULL
	|							THEN CorDataSources.CorRegisterName = DebitOnlyRegisteredRecords.RegisterName
	|						ELSE TRUE
	|					END
	|				)
	// correspondence of records with empty XO settings is prohibited if both form complex transactions with other records
	|		WHEN DirectDebit.NumberOfEntriesFinEntries > 1 AND MovementCredit.NumberOfEntriesFinEntries > 1
	|			THEN FALSE
	// correspondence of records with empty XO settings is prohibited if one forms complex transactions, and for the other there is correspondence with a filled XO setting
	|		WHEN DirectDebit.NumberOfEntriesFinEntries > 1
	|			THEN NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTDebit AS DebitOnlyRegisteredRecords
	|				WHERE
	|					DebitOnlyRegisteredRecords.Period = MovementCredit.Period
	|					AND DebitOnlyRegisteredRecords.Recorder = MovementCredit.Recorder
	|					AND DebitOnlyRegisteredRecords.FinRecordID = MovementCredit.FinRecordID
	|					AND DebitOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|					AND DebitOnlyRegisteredRecords.Organization = MovementCredit.Organization
	|					AND DebitOnlyRegisteredRecords.ThisIsDebit
	|					AND NOT DebitOnlyRegisteredRecords.Factor IN (&IndicatorsForCorrespondingRegisters)
	|					AND (DebitOnlyRegisteredRecords.Factor <> MovementCredit.Factor OR DebitOnlyRegisteredRecords.RegisterName <> MovementCredit.RegisterName OR DebitOnlyRegisteredRecords.ThisIsReverseTransaction = MovementCredit.ThisIsReverseTransaction)
	|				)
	// correspondence of records with empty XO settings is prohibited if one forms complex transactions, and for the other there is correspondence with a filled XO setting
	|		WHEN MovementCredit.NumberOfEntriesFinEntries > 1
	|			THEN NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTCredit AS CreditOnlyRegisteredRecords
	|				WHERE
	|					CreditOnlyRegisteredRecords.Period = DirectDebit.Period
	|					AND CreditOnlyRegisteredRecords.Recorder = DirectDebit.Recorder
	|					AND CreditOnlyRegisteredRecords.FinRecordID = DirectDebit.FinRecordID
	|					AND CreditOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|					AND CreditOnlyRegisteredRecords.Organization = DirectDebit.Organization
	|					AND CreditOnlyRegisteredRecords.ThisIsLoan
	|					AND NOT CreditOnlyRegisteredRecords.Factor IN (&IndicatorsForCorrespondingRegisters)
	|					AND (CreditOnlyRegisteredRecords.Factor <> DirectDebit.Factor OR CreditOnlyRegisteredRecords.RegisterName <> DirectDebit.RegisterName OR CreditOnlyRegisteredRecords.ThisIsReverseTransaction = DirectDebit.ThisIsReverseTransaction)
	|				)
	// correspondence of records with empty XO settings is prohibited if there are correspondences with filled XO settings for both
	|		ELSE NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTDebit AS DebitOnlyRegisteredRecords
	|			WHERE
	|				DebitOnlyRegisteredRecords.Period = MovementCredit.Period
	|				AND DebitOnlyRegisteredRecords.Recorder = MovementCredit.Recorder
	|				AND DebitOnlyRegisteredRecords.FinRecordID = MovementCredit.FinRecordID
	|				AND DebitOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|				AND DebitOnlyRegisteredRecords.Organization = MovementCredit.Organization
	|				AND DebitOnlyRegisteredRecords.ThisIsDebit
	|				AND NOT DebitOnlyRegisteredRecords.Factor IN (&IndicatorsForCorrespondingRegisters)
	|				AND (DebitOnlyRegisteredRecords.Factor <> MovementCredit.Factor OR DebitOnlyRegisteredRecords.RegisterName <> MovementCredit.RegisterName OR DebitOnlyRegisteredRecords.ThisIsReverseTransaction = MovementCredit.ThisIsReverseTransaction)
	|			)
	|		AND NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTCredit AS CreditOnlyRegisteredRecords
	|			WHERE
	|				CreditOnlyRegisteredRecords.Period = DirectDebit.Period
	|				AND CreditOnlyRegisteredRecords.Recorder = DirectDebit.Recorder
	|				AND CreditOnlyRegisteredRecords.FinRecordID = DirectDebit.FinRecordID
	|				AND CreditOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|				AND CreditOnlyRegisteredRecords.Organization = DirectDebit.Organization
	|				AND CreditOnlyRegisteredRecords.ThisIsLoan
	|				AND NOT CreditOnlyRegisteredRecords.Factor IN (&IndicatorsForCorrespondingRegisters)
	|				AND (CreditOnlyRegisteredRecords.Factor <> DirectDebit.Factor OR CreditOnlyRegisteredRecords.RegisterName <> DirectDebit.RegisterName OR CreditOnlyRegisteredRecords.ThisIsReverseTransaction = DirectDebit.ThisIsReverseTransaction)
	|			)
	|	 END
	|	AND CASE
	|		WHEN DirectDebit.RegisterName = MovementCredit.RegisterName
	|			AND NOT DirectDebit.RegisterName IN (&RegistersOfRecoveryOfCalculationsOnStorno)
	|			AND DirectDebit.Factor <> VALUE(Enum.IndicatorsOfAnalyticalRegisters.EmptyRef)
	|			AND MovementCredit.Factor <> VALUE(Enum.IndicatorsOfAnalyticalRegisters.EmptyRef)
	|			AND DirectDebit.ThisIsReverseTransaction = MovementCredit.ThisIsReverseTransaction
	|			THEN DirectDebit.Factor = MovementCredit.Factor
	|		ELSE TRUE
	|	END
	|	AND CASE
	|		WHEN DirectDebit.RegisterName IN (&RegistersWithSelectionByIndicators)
	|			AND MovementCredit.RegisterName IN (&RegistersWithSelectionByIndicators)
	|			AND DirectDebit.ThisIsReverseTransaction = MovementCredit.ThisIsReverseTransaction
	|			AND NOT VALUETYPE(DirectDebit.Recorder) = TYPE(Document.CostCalculationRecorder)
	|			THEN DirectDebit.Factor = MovementCredit.Factor
	|		ELSE TRUE
	|	END
	|	AND CASE
	|		WHEN DirectDebit.Factor IN (&IndicatorsForCorrespondingRegisters)
	|			THEN DirectDebit.Factor = MovementCredit.Factor
	|		ELSE TRUE
	|	END
	|	AND CASE
	|		WHEN MovementCredit.Factor IN (&IndicatorsForCorrespondingRegisters)
	|			THEN MovementCredit.Factor = DirectDebit.Factor
	|		ELSE TRUE
	|	END
	|	 AND CASE
	// correspondence of the records of the circulating registers with themselves is always prohibited
	|		WHEN NOT DirectDebit.ThisIsDebit AND NOT MovementCredit.ThisIsLoan
	|			THEN FALSE
	// Correspondence records are limited in the description of the debit indicator
	|		WHEN DirectDebit.ThereAreCorDataSources
	|			THEN TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTCorDataSources AS CorDataSources
	|				WHERE
	|					CorDataSources.Factor = DirectDebit.Factor
	|					AND CorDataSources.RegisterName = DirectDebit.RegisterName
	|					AND CorDataSources.CorRegisterName = MovementCredit.RegisterName
	|				)
	// Correspondence records are limited in the description of the credit score
	|		WHEN MovementCredit.ThereAreCorDataSources
	|			THEN TRUE IN 
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTCorDataSources AS CorDataSources
	|				WHERE
	|					CorDataSources.Factor = MovementCredit.Factor
	|					AND CorDataSources.RegisterName = MovementCredit.RegisterName
	|					AND CorDataSources.CorRegisterName = DirectDebit.RegisterName
	|				)
	// this is part of the correct complex correspondence "one to many" by debit
	|		WHEN DirectDebit.NumberOfOperationRecords = 1 AND MovementCredit.NumberOfOperationRecords > 1
	|			AND DirectDebit.TransactionManAmount = MovementCredit.TransactionManAmount
	|			AND DirectDebit.AmountOfLocalTransaction = MovementCredit.AmountOfLocalTransaction
	|			THEN TRUE
	// this is part of the correct complex many-to-one correspondence on the loan
	|		WHEN DirectDebit.NumberOfOperationRecords > 1 AND MovementCredit.NumberOfOperationRecords = 1
	|			AND DirectDebit.TransactionManAmount = MovementCredit.TransactionManAmount
	|			AND DirectDebit.AmountOfLocalTransaction = MovementCredit.AmountOfLocalTransaction
	|			THEN TRUE
	// correspondence of direct and reverse entries within the same register is allowed if there are no correspondence with other objects or the same sign of reverse and the amounts of upr and regl for the reverse
	|		WHEN DirectDebit.RegisterName = MovementCredit.RegisterName AND DirectDebit.Factor = MovementCredit.Factor AND DirectDebit.ThisIsReverseTransaction AND NOT MovementCredit.ThisIsReverseTransaction
	|			THEN NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTCredit AS CreditOnlyRegisteredRecords
	|				WHERE
	|					CreditOnlyRegisteredRecords.Period = DirectDebit.Period
	|					AND CreditOnlyRegisteredRecords.Recorder = DirectDebit.Recorder
	|					AND CreditOnlyRegisteredRecords.FinRecordID = DirectDebit.FinRecordID
	|					AND CreditOnlyRegisteredRecords.Organization = DirectDebit.Organization
	|					AND CreditOnlyRegisteredRecords.ThisIsLoan
	|					AND CASE
	|						WHEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							AND DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							THEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction = DirectDebit.SettingUpBusinessTransaction
	|						ELSE TRUE
	|					END
	|					AND ((CreditOnlyRegisteredRecords.RegisterName <> DirectDebit.RegisterName
	|						OR CreditOnlyRegisteredRecords.Factor <> DirectDebit.Factor
	|						OR CreditOnlyRegisteredRecords.ThisIsReverseTransaction = DirectDebit.ThisIsReverseTransaction)
	|						OR
	|						(CreditOnlyRegisteredRecords.RegisterName = DirectDebit.RegisterName
	|						AND CreditOnlyRegisteredRecords.Factor = DirectDebit.Factor
	|						AND CreditOnlyRegisteredRecords.ThisIsReverseTransaction <> DirectDebit.ThisIsReverseTransaction
	|						AND CreditOnlyRegisteredRecords.SumMan = DirectDebit.SumMan
	|						AND CreditOnlyRegisteredRecords.SumCompl = DirectDebit.SumCompl
	|						AND CreditOnlyRegisteredRecords.SumMan <> MovementCredit.SumMan
	|						AND CreditOnlyRegisteredRecords.SumCompl <> MovementCredit.SumCompl)
	|					)
	|				)
	// correspondence of direct and reverse entries within the same register is allowed if there are no correspondence with other objects or the same sign of reverse and the amounts of upr and regl for the reverse
	|		WHEN DirectDebit.RegisterName = MovementCredit.RegisterName AND DirectDebit.Factor = MovementCredit.Factor AND NOT DirectDebit.ThisIsReverseTransaction AND MovementCredit.ThisIsReverseTransaction
	|			THEN NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTDebit AS DebitOnlyRegisteredRecords
	|				WHERE
	|					DebitOnlyRegisteredRecords.Period = MovementCredit.Period
	|					AND DebitOnlyRegisteredRecords.Recorder = MovementCredit.Recorder
	|					AND DebitOnlyRegisteredRecords.FinRecordID = MovementCredit.FinRecordID
	|					AND DebitOnlyRegisteredRecords.Organization = MovementCredit.Organization
	|					AND DebitOnlyRegisteredRecords.ThisIsDebit
	|					AND CASE
	|						WHEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							AND MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							THEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction = MovementCredit.SettingUpBusinessTransaction
	|						ELSE TRUE
	|					END
	|					AND ((DebitOnlyRegisteredRecords.RegisterName <> MovementCredit.RegisterName
	|						OR DebitOnlyRegisteredRecords.Factor <> MovementCredit.Factor
	|						OR DebitOnlyRegisteredRecords.ThisIsReverseTransaction = MovementCredit.ThisIsReverseTransaction)
	|						OR
	|						(DebitOnlyRegisteredRecords.RegisterName = MovementCredit.RegisterName
	|						AND DebitOnlyRegisteredRecords.Factor = MovementCredit.Factor
	|						AND DebitOnlyRegisteredRecords.ThisIsReverseTransaction <> MovementCredit.ThisIsReverseTransaction
	|						AND DebitOnlyRegisteredRecords.SumMan = MovementCredit.SumMan
	|						AND DebitOnlyRegisteredRecords.SumCompl = MovementCredit.SumCompl
	|						AND DebitOnlyRegisteredRecords.SumMan <> DirectDebit.SumMan
	|						AND DebitOnlyRegisteredRecords.SumCompl <> DirectDebit.SumCompl)
	|					)
	|				)
	// correspondence of records within the same register has priority for records with the same accounting objects and amounts of upr and regl
	|		WHEN DirectDebit.RegisterName = MovementCredit.RegisterName AND DirectDebit.ThisIsReverseTransaction = MovementCredit.ThisIsReverseTransaction
	|			THEN NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTCredit AS CreditOnlyRegisteredRecords
	|				WHERE
	|					CreditOnlyRegisteredRecords.Period = DirectDebit.Period
	|					AND CreditOnlyRegisteredRecords.Recorder = DirectDebit.Recorder
	|					AND CreditOnlyRegisteredRecords.FinRecordID = DirectDebit.FinRecordID
	|					AND CreditOnlyRegisteredRecords.Organization = DirectDebit.Organization
	|					AND CreditOnlyRegisteredRecords.ThisIsLoan
	|					AND CASE
	|						WHEN DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							AND MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							THEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction = DirectDebit.SettingUpBusinessTransaction
	|						WHEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							AND DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							THEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction = DirectDebit.SettingUpBusinessTransaction
	|						ELSE TRUE
	|					END
	|					AND CreditOnlyRegisteredRecords.RegisterName = DirectDebit.RegisterName
	|					AND CreditOnlyRegisteredRecords.Factor = DirectDebit.Factor
	|					AND CreditOnlyRegisteredRecords.ThisIsReverseTransaction = DirectDebit.ThisIsReverseTransaction
	|					AND CreditOnlyRegisteredRecords.SumMan = DirectDebit.SumMan
	|					AND CreditOnlyRegisteredRecords.SumCompl = DirectDebit.SumCompl
	|					AND (CreditOnlyRegisteredRecords.RegisterName <> MovementCredit.RegisterName
	|						OR CreditOnlyRegisteredRecords.Factor <> MovementCredit.Factor
	|						OR
	|						(CreditOnlyRegisteredRecords.RegisterName = MovementCredit.RegisterName
	|						AND CreditOnlyRegisteredRecords.Factor = MovementCredit.Factor
	|						AND CreditOnlyRegisteredRecords.SumMan <> MovementCredit.SumMan
	|						AND CreditOnlyRegisteredRecords.SumCompl <> MovementCredit.SumCompl)
	|					AND NOT (MovementCredit.SumMan = 0 AND MovementCredit.SumCompl = 0)
	|					)
	|				)
	|			AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTDebit AS DebitOnlyRegisteredRecords
	|				WHERE
	|					DebitOnlyRegisteredRecords.Period = MovementCredit.Period
	|					AND DebitOnlyRegisteredRecords.Recorder = MovementCredit.Recorder
	|					AND DebitOnlyRegisteredRecords.FinRecordID = MovementCredit.FinRecordID
	|					AND DebitOnlyRegisteredRecords.Organization = MovementCredit.Organization
	|					AND DebitOnlyRegisteredRecords.ThisIsDebit
	|					AND CASE
	|						WHEN DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							AND MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							THEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction = MovementCredit.SettingUpBusinessTransaction
	|						WHEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							AND MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							THEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction = MovementCredit.SettingUpBusinessTransaction
	|						ELSE TRUE
	|					END
	|					AND DebitOnlyRegisteredRecords.RegisterName = MovementCredit.RegisterName
	|					AND DebitOnlyRegisteredRecords.Factor = MovementCredit.Factor
	|					AND DebitOnlyRegisteredRecords.ThisIsReverseTransaction = MovementCredit.ThisIsReverseTransaction
	|					AND DebitOnlyRegisteredRecords.SumMan = MovementCredit.SumMan
	|					AND DebitOnlyRegisteredRecords.SumCompl = MovementCredit.SumCompl
	|					AND (DebitOnlyRegisteredRecords.RegisterName <> DirectDebit.RegisterName
	|						OR DebitOnlyRegisteredRecords.Factor <> DirectDebit.Factor
	|						OR
	|						(DebitOnlyRegisteredRecords.RegisterName = DirectDebit.RegisterName
	|						AND DebitOnlyRegisteredRecords.Factor = DirectDebit.Factor
	|						AND DebitOnlyRegisteredRecords.SumMan <> DirectDebit.SumMan
	|						AND DebitOnlyRegisteredRecords.SumCompl <> DirectDebit.SumCompl)
	|					)
	|					AND NOT (DirectDebit.SumMan = 0 AND DirectDebit.SumCompl = 0)
	|				)
	// other cases of many-to-many relationships, priority for records with the same amounts of upr and regl
	|		WHEN DirectDebit.NumberOfOperationRecords > 1 AND MovementCredit.NumberOfOperationRecords > 1
	|			THEN NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTCredit AS CreditOnlyRegisteredRecords
	|				WHERE
	|					CreditOnlyRegisteredRecords.Period = DirectDebit.Period
	|					AND CreditOnlyRegisteredRecords.Recorder = DirectDebit.Recorder
	|					AND CreditOnlyRegisteredRecords.FinRecordID = DirectDebit.FinRecordID
	|					AND CreditOnlyRegisteredRecords.Organization = DirectDebit.Organization
	|					AND CreditOnlyRegisteredRecords.ThisIsLoan
	|					AND CASE
	|						WHEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							AND DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							THEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction = DirectDebit.SettingUpBusinessTransaction
	|						ELSE TRUE
	|					END
	|					AND CreditOnlyRegisteredRecords.SumMan = DirectDebit.SumMan
	|					AND CreditOnlyRegisteredRecords.SumCompl = DirectDebit.SumCompl
	|					AND CreditOnlyRegisteredRecords.SumMan <> MovementCredit.SumMan
	|					AND CreditOnlyRegisteredRecords.SumCompl <> MovementCredit.SumCompl
	|				)
	|			AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTDebit AS DebitOnlyRegisteredRecords
	|				WHERE
	|					DebitOnlyRegisteredRecords.Period = MovementCredit.Period
	|					AND DebitOnlyRegisteredRecords.Recorder = MovementCredit.Recorder
	|					AND DebitOnlyRegisteredRecords.FinRecordID = MovementCredit.FinRecordID
	|					AND DebitOnlyRegisteredRecords.Organization = MovementCredit.Organization
	|					AND DebitOnlyRegisteredRecords.ThisIsDebit
	|					AND CASE
	|						WHEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							AND MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|							THEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction = MovementCredit.SettingUpBusinessTransaction
	|						ELSE TRUE
	|					END
	|					AND DebitOnlyRegisteredRecords.SumMan = MovementCredit.SumMan
	|					AND DebitOnlyRegisteredRecords.SumCompl = MovementCredit.SumCompl
	|					AND DebitOnlyRegisteredRecords.SumMan <> DirectDebit.SumMan
	|					AND DebitOnlyRegisteredRecords.SumCompl <> DirectDebit.SumCompl
	|				)
	|		ELSE TRUE
	|	 END
	|WHERE
	|	CASE
	|		WHEN DirectDebit.Recorder IS NULL
	|			THEN CASE
	// we do not output a record with zero balance resources
	|				WHEN MovementCredit.SumMan = 0 AND MovementCredit.SumCompl = 0
	|					THEN FALSE
	// the record of the residual register is always output
	|				WHEN MovementCredit.ThisIsLoan
	|					THEN TRUE
	// we do not output a record with zero balance resources
	|				WHEN DirectDebit.SumMan = 0 AND DirectDebit.SumCompl = 0
	|					THEN FALSE
	// the record of the residual register is always output
	|				WHEN DirectDebit.ThisIsDebit
	|					THEN TRUE
	// we do not output the reverse register entry if there is correspondence with another expenditure movement for it
	|				ELSE NOT TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						TTCredit AS CreditOnlyRegisteredRecords
	|						LEFT JOIN TTCorDataSources AS CorDataSources
	|							ON CreditOnlyRegisteredRecords.RegisterName = CorDataSources.CorRegisterName
	|							 AND MovementCredit.ThereAreCorDataSources
	|					WHERE
	|						CreditOnlyRegisteredRecords.Period = MovementCredit.Period
	|						AND CreditOnlyRegisteredRecords.Recorder = MovementCredit.Recorder
	|						AND CreditOnlyRegisteredRecords.FinRecordID = MovementCredit.FinRecordID
	|						AND CreditOnlyRegisteredRecords.Organization = MovementCredit.Organization
	|						AND CreditOnlyRegisteredRecords.ThisIsLoan
	|						AND CASE
	|							WHEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|								AND MovementCredit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|								THEN CreditOnlyRegisteredRecords.SettingUpBusinessTransaction = MovementCredit.SettingUpBusinessTransaction
	|							ELSE TRUE
	|						END
	|						AND CASE
	|							WHEN NOT CorDataSources.Factor IS NULL
	|								THEN CorDataSources.Factor = MovementCredit.Factor
	|								AND CorDataSources.RegisterName = MovementCredit.RegisterName
	|							ELSE NOT MovementCredit.TypeOfRegistrar IN (&TypesOfRetailSalesDocuments)
	|						END
	|					)
	|					AND NOT MovementCredit.TypeOfRegistrar IN (&TypesOfRetailReturnsDocuments)
	|			END
	|		WHEN MovementCredit.Recorder IS NULL
	|			THEN CASE
	// we do not output a record with zero balance resources
	|				WHEN DirectDebit.SumMan = 0 AND DirectDebit.SumCompl = 0
	|					THEN FALSE
	// the record of the residual register is always output
	|				WHEN DirectDebit.ThisIsDebit
	|					THEN TRUE
	// we do not output the reverse register entry if there is correspondence with another incoming movement for it
	|				ELSE NOT TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						TTDebit AS DebitOnlyRegisteredRecords
	|						LEFT JOIN TTCorDataSources AS CorDataSources
	|							ON DebitOnlyRegisteredRecords.RegisterName = CorDataSources.CorRegisterName
	|							 AND DirectDebit.ThereAreCorDataSources
	|					WHERE
	|						DebitOnlyRegisteredRecords.Period = DirectDebit.Period
	|						AND DebitOnlyRegisteredRecords.Recorder = DirectDebit.Recorder
	|						AND DebitOnlyRegisteredRecords.FinRecordID = DirectDebit.FinRecordID
	|						AND DebitOnlyRegisteredRecords.Organization = DirectDebit.Organization
	|						AND DebitOnlyRegisteredRecords.ThisIsDebit
	|						AND CASE
	|							WHEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|								AND DirectDebit.SettingUpBusinessTransaction <> VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|								THEN DebitOnlyRegisteredRecords.SettingUpBusinessTransaction = DirectDebit.SettingUpBusinessTransaction
	|							ELSE TRUE
	|						END
	|						AND CASE
	|							WHEN NOT CorDataSources.Factor IS NULL
	|								THEN CorDataSources.Factor = DirectDebit.Factor
	|								AND CorDataSources.RegisterName = DirectDebit.RegisterName
	|							ELSE NOT DirectDebit.TypeOfRegistrar IN (&TypesOfRetailReturnsDocuments)
	|						END
	|					)
	|					AND NOT DirectDebit.TypeOfRegistrar IN (&TypesOfRetailSalesDocuments)
	|			END
	|		ELSE TRUE
	|	END
	|	AND CASE
	|			WHEN DirectDebit.NumberOfOperationRecords > 1
	|					AND MovementCredit.NumberOfOperationRecords > 1
	|					AND ISNULL(DirectDebit.SumCurr, 0) <> 0
	|					AND ISNULL(MovementCredit.SumCurr, 0) <> 0
	|					AND ISNULL(DirectDebit.SumCurr, 0) = ISNULL(MovementCredit.SumCurr, 0)
	|				THEN ISNULL(DirectDebit.SumMan, 0) = ISNULL(MovementCredit.SumMan, 0)
	|						OR ISNULL(DirectDebit.SumCompl, 0) = ISNULL(MovementCredit.SumCompl, 0)
	|			ELSE TRUE
	|		END
	|	AND CASE
	|		WHEN DirectDebit.Factor IN (&IndicatorsForCorrespondingRegisters)
	|			OR MovementCredit.Factor IN (&IndicatorsForCorrespondingRegisters)
	|			THEN DirectDebit.RegisterName <> MovementCredit.RegisterName
	|		ELSE TRUE
	|	END
	|	AND CASE
	|			WHEN DirectDebit.Factor IN (VALUE(Enum.IndicatorsOfAnalyticalRegisters.Cost), VALUE(Enum.IndicatorsOfAnalyticalRegisters.CostExcludingVAT))
	|					AND MovementCredit.Factor IN (VALUE(Enum.IndicatorsOfAnalyticalRegisters.AdditExpenseAmount), VALUE(Enum.IndicatorsOfAnalyticalRegisters.AdditionalExpensesAmountExcludingVAT))
	|				THEN ISNULL(DirectDebit.SumMan, 0) = ISNULL(MovementCredit.SumMan, 0)
	|						OR ISNULL(DirectDebit.SumCompl, 0) = ISNULL(MovementCredit.SumCompl, 0)
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN DirectDebit.Factor IN (VALUE(Enum.IndicatorsOfAnalyticalRegisters.AdditExpenseAmount), VALUE(Enum.IndicatorsOfAnalyticalRegisters.AdditionalExpensesAmountExcludingVAT))
	|					AND MovementCredit.Factor IN (VALUE(Enum.IndicatorsOfAnalyticalRegisters.Cost), VALUE(Enum.IndicatorsOfAnalyticalRegisters.CostExcludingVAT))
	|				THEN ISNULL(DirectDebit.SumMan, 0) = ISNULL(MovementCredit.SumMan, 0)
	|						OR ISNULL(DirectDebit.SumCompl, 0) = ISNULL(MovementCredit.SumCompl, 0)
	|			ELSE TRUE
	|		END
	|
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization,
	|	ThisIsReverseTransactionDr,
	|	ThisIsReverseTransactionCr
	|";
	
	TableOfCorrespondenceOfRegisteredRecordsOfRegisters = Query.Parameters.TableOfCorrespondenceOfRegisteredRecordsOfRegisters;
	
	If Query.TempTablesManager.Tables.Find(TableOfCorrespondenceOfRegisteredRecordsOfRegisters) <> Undefined Then
		TableOfCorrespondenceOfRegisteredRecordsOfRegisters = TableOfCorrespondenceOfRegisteredRecordsOfRegisters + "1";
		Query.Parameters.TableOfCorrespondenceOfRegisteredRecordsOfRegisters = TableOfCorrespondenceOfRegisteredRecordsOfRegisters;
	EndIf;
	
	QueryText = StrReplace(QueryText, "TableOfCorrespondenceOfRegisteredRecordsOfRegisters", TableOfCorrespondenceOfRegisteredRecordsOfRegisters);
	QueriesTexts.Add(QueryText);
	
EndProcedure

Procedure ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr)
	
	If DrCr = "Dr" Then
		ThisIsDrCr = "ThisIsDebit";
		ThisIsCorDrCr = "ThisIsLoan";
		TTRegisteredRecordsDrCr = "TTDebit";
		TTMotionCorDrCr = "TTCredit";
		TTRegisteredRecordsWithDrCrTotals = "TTRegisteredRecordsWithDebitTotals";
		TTRegisterRegisteredRecordsDrCr = "TTMovementRegistersDebit";
		TTFoldedRegisteredRecordsDrCr = "TTCollapsedRegisteredRecordsDebit";
		TTMovementRegistersReverseDrCr = "TTRegisterRegisteredRecordsReverseDebit";
		TTCorMovementRegistersReverseDrCr = "TTMovementRegistersReverseCredit";
		TTCtTransactionIdsDrCr = "TTTransactionIDsCredit";
	Else
		ThisIsDrCr = "ThisIsLoan";
		ThisIsCorDrCr = "ThisIsDebit";
		TTRegisteredRecordsDrCr = "TTCredit";
		TTMotionCorDrCr = "TTDebit";
		TTRegisteredRecordsWithDrCrTotals = "TTRegisteredRecordsWithCreditTotals";
		TTRegisterRegisteredRecordsDrCr = "TTMovementRegistersCredit";
		TTFoldedRegisteredRecordsDrCr = "TTRolledUpMotionCredit";
		TTMovementRegistersReverseDrCr = "TTMovementRegistersReverseCredit";
		TTCorMovementRegistersReverseDrCr = "TTRegisterRegisteredRecordsReverseDebit";
		TTCtTransactionIdsDrCr = "TTTransactionIDsDebit";
	EndIf;
	
	QueryText = StrReplace(QueryText, "ThisIsDrCr", ThisIsDrCr);
	QueryText = StrReplace(QueryText, "ThisIsCorDrCr", ThisIsCorDrCr);
	QueryText = StrReplace(QueryText, "TTRegisteredRecordsDrCr", TTRegisteredRecordsDrCr);
	QueryText = StrReplace(QueryText, "TTMotionCorDrCr", TTMotionCorDrCr);
	QueryText = StrReplace(QueryText, "TTRegisteredRecordsWithDrCrTotals", TTRegisteredRecordsWithDrCrTotals);
	QueryText = StrReplace(QueryText, "TTRegisterRegisteredRecordsDrCr", TTRegisterRegisteredRecordsDrCr);
	QueryText = StrReplace(QueryText, "TTFoldedRegisteredRecordsDrCr", TTFoldedRegisteredRecordsDrCr);
	QueryText = StrReplace(QueryText, "TTMovementRegistersReverseDrCr", TTMovementRegistersReverseDrCr);
	QueryText = StrReplace(QueryText, "TTCorMovementRegistersReverseDrCr", TTCorMovementRegistersReverseDrCr);
	QueryText = StrReplace(QueryText, "TTCtTransactionIdsDrCr", TTCtTransactionIdsDrCr);
	
EndProcedure

#EndRegion

#Region TextsOfCorrespondenceGenerationRequests

Function CaseRecordRequestTextTemplate()
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	&RegisterName AS RegisterName,
	|	&Factor AS Factor,
	|	&ThisIsDebit AS ThisIsDebit,
	|	&ThisIsLoan AS ThisIsLoan,
	|	&ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	&AnalyticsSelectionFields,
	|	&Recorder AS Recorder,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	&AdditionalSetupOfHouseholdOperations AS AdditionalSetupOfHouseholdOperations,
	|	&FinRecordID AS FinRecordID,
	|	&RowID AS RowID,
	|	&VATActivityType AS OfficialTypeOfActivityVAT,
	|	&Currency AS Currency,
	|	&SumMan AS SumMan,
	|	&SumCompl AS SumCompl,
	|	&SumCurr AS SumCurr,
	|	&Count AS Count,
	|	&PropsStorno AS PropsStorno
	|INTO NameOfRegisterCacheTable
	|FROM
	|	&DataSource
	|WHERE
	|	&Active
	|	AND &FinRecordID <> &IDOfUnusedFinRecord
	|	AND &ConditionLogger
	|	AND &ResourceValueCondition
	|	AND &ConditionDocumentsToBeDeleted
	|	AND &ConditionAdditionalSelection
	|	AND &Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|GROUP BY
	|	&Period,
	|	&Factor,
	|	&ThisIsDebit,
	|	&ThisIsLoan,
	|	&ThisIsReverseTransaction,
	|	&AnalyticsFieldGroup,
	|	&Recorder,
	|	&Organization,
	|	&Department,
	|	&LineOfBusiness,
	|	&SettingUpBusinessTransaction,
	|	&AdditionalSetupOfHouseholdOperations,
	|	&FinRecordID,
	|	&RowID,
	|	&Currency,
	|	&PropsStorno
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextsForRegisterEntries(Query, ResidualFinancialRegisters)
	
	RegisterRequestsTexts = New Structure();
	
	RegisterTypeRevolutions = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers;
	AccumulationRegistersMetadata = Metadata.AccumulationRegisters;
	
	For Each KeyAndValue In ResidualFinancialRegisters Do
		
		RegisterName = KeyAndValue.Key;
		MotionReflectionParameters = KeyAndValue.Value;
		If Not ValueIsFilled(MotionReflectionParameters.TypeOfAccountingData) Then
			Continue;
		EndIf;
		RegisterMetadata = Metadata.AccumulationRegisters[RegisterName];
		
		If Not IsBlankString(MotionReflectionParameters.DebitCondition)
		 Or Not IsBlankString(MotionReflectionParameters.ConditionCredit) Then
			DebitCondition  = MotionReflectionParameters.DebitCondition;
			ConditionCredit = MotionReflectionParameters.ConditionCredit;
		ElsIf RegisterMetadata.RegisterType = RegisterTypeRevolutions Then
			DebitCondition  = "FALSE";
			ConditionCredit = "FALSE";
		ElsIf MotionReflectionParameters.InversionOfRegisteredRecords Then
			DebitCondition  = "&RecordType = VALUE(AccumulationRecordType.Expense)";
			ConditionCredit = "&RecordType = VALUE(AccumulationRecordType.Receipt)";
		Else
			DebitCondition  = "&RecordType = VALUE(AccumulationRecordType.Receipt)";
			ConditionCredit = "&RecordType = VALUE(AccumulationRecordType.Expense)";
		EndIf;
		
		ExpressionIsDebit = "CASE
		|		WHEN &ThisIsReverseTransaction
		|			THEN &ConditionCredit
		|		ELSE &DebitCondition
		|	END";
		
		ExpressionIsLoan = "CASE
		|		WHEN &ThisIsReverseTransaction
		|			THEN &DebitCondition
		|		ELSE &ConditionCredit
		|	END";
		
		MotionReflectionParameters.Insert("ExpressionIsDebit", ExpressionIsDebit);
		MotionReflectionParameters.Insert("ExpressionIsLoan", ExpressionIsLoan);
		
		MetricResourceKeys = New Map;
		
		For Each IndicatorLine_ In MotionReflectionParameters.Indicators Do
			
			IndicatorLine_.Value.Insert("Factor", IndicatorLine_.Key);
			IndicatorLine_.Value.Insert("RegisterName", RegisterName);
			FinancialAccountingByBalanceSheetRegisterData.FillInCorDataSources(Query.Parameters, IndicatorLine_.Value);
			
			AllResources = New Array;
			CommonClientServer.SupplementArray(AllResources, IndicatorLine_.Value.ManResources);
			CommonClientServer.SupplementArray(AllResources, IndicatorLine_.Value.LocalResources);
			ResourceKey = StrConcat(AllResources, ",");
			
			If MetricResourceKeys[ResourceKey] <> Undefined Then
				ErrorText = NStr("vi = 'Các số đo %1 bị trùng lặp ở các chỉ tiêu của biểu ghi %2';
								|ru = 'Ресурсы %1 дублируются у показателей регистра %2';
								|en = 'The %1 resources are duplicated for the %2 register indicators'; fa = 'The %1 resources are duplicated for the %2 register indicators';
								|it = 'Ресурсы %1 дублируются у показателей регистра %2';
								|pl = 'The %1 resources are duplicated for the %2 register indicators';
								|tr = '%1 kaynakları, %2 kayıt göstergelerinde çoğaltılmaktadır'");
				Raise StrTemplate(ErrorText, ResourceKey, RegisterName);
			Else
				MetricResourceKeys.Insert(ResourceKey, IndicatorLine_.Value);
			EndIf;
			
		EndDo;
		
		If MetricResourceKeys.Count() = 0 Then
			IndicatorSelectionFields = SampleRowsOfFieldsBasedOnIndicatorDescription(MotionReflectionParameters);
		Else
			IndicatorSelectionFields = New Structure;
			SelectionFieldNames = Enums.IndicatorsOfAnalyticalRegisters.SampleFieldsBasedOnIndicatorDescription();
			
			For Each FieldName In SelectionFieldNames Do
				IndicatorSelectionFields.Insert(FieldName, New Map());
			EndDo;
			
			ResourceKeyNumber = 0;
			
			For Each MetricResourceKey In MetricResourceKeys Do
				ResourceKeyNumber = ResourceKeyNumber + 1;
				
				RowsOfSelectionOfAccountingObjectFields = SampleRowsOfFieldsBasedOnIndicatorDescription(MotionReflectionParameters,
					MetricResourceKey.Value);
				
				For Each KeyAndValue In IndicatorSelectionFields Do
					FieldSelectionString_ = RowsOfSelectionOfAccountingObjectFields[KeyAndValue.Key];
					If KeyAndValue.Value[FieldSelectionString_] = Undefined Then
						KeyAndValue.Value.Insert(FieldSelectionString_, New Array());
					EndIf;
					KeyAndValue.Value[FieldSelectionString_].Add(ResourceKeyNumber);
				EndDo;
			EndDo;
			
			For Each FieldName In SelectionFieldNames Do
				SampleRowsFields = IndicatorSelectionFields[FieldName];
				IndicatorSelectionField = FinancialAccountingByBalanceSheetRegisterData.FieldValueSelectionString(SampleRowsFields);
				IndicatorSelectionFields.Insert(FieldName, IndicatorSelectionField);
			EndDo;
		EndIf;
		
		PathsToFieldData = FinancialAccountingByBalanceSheetRegisterData.DescriptionsOfPathsToRegisterFieldData(MotionReflectionParameters);
		
		If MotionReflectionParameters.ThisIsVATRegister
			And Query.Parameters.VATRegisters.Find(RegisterName) = Undefined Then
			Query.Parameters.VATRegisters.Add(RegisterName);
		EndIf;
		
		If FinancialAccountingByBalanceSheetRegisterData.ResourceIsMissingOrMayBeEmpty(MotionReflectionParameters.ManResources)
			And Query.Parameters.RegistersWithoutManSum.Find(RegisterName) = Undefined Then
			Query.Parameters.RegistersWithoutManSum.Add(RegisterName);
		EndIf;
		
		If FinancialAccountingByBalanceSheetRegisterData.ResourceIsMissingOrMayBeEmpty(MotionReflectionParameters.LocalResources)
			And Query.Parameters.RegistersWithoutSumLocal.Find(RegisterName) = Undefined Then
			Query.Parameters.RegistersWithoutSumLocal.Add(RegisterName);
		EndIf;
		
		DataSource = StrTemplate("AccumulationRegister.%1 AS RegisterTable", RegisterName) + "
			|	INNER JOIN DocumentsToBeReflected AS PortionOfDocuments
			|		ON &Recorder = PortionOfDocuments.Recorder";
		ConditionDocumentsToBeDeleted = FinancialAccountingByBalanceSheetRegisterData.ConditionLineDocumentsToBeDeleted(RegisterMetadata);
		
		If MetricResourceKeys.Count() > 1 Then
			FinancialAccountingByBalanceSheetRegisterData.AddRepeaterToDataSource(DataSource,
				MetricResourceKeys.Count());
		EndIf;
		
		ConditionLogger = FinancialAccountingByBalanceSheetRegisterData.ConditionStringLogger(Query.Parameters);
		ConditionAdditionalSelection = FinancialAccountingByBalanceSheetRegisterData.StringAdditionalSelection(MotionReflectionParameters);
		If RegisterName = AccumulationRegistersMetadata.CustomersARAPAccountingByDueDates.Name Then
			ConditionAdditionalSelection = ?(IsBlankString(ConditionAdditionalSelection), "", ConditionAdditionalSelection) + StrReplace("
			|	AND CASE
			|		WHEN DataSourceAlias.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
			|			THEN DataSourceAlias.AccountingDimensionByPartners.Organization <> VALUE(Catalog.Companies.ManagementCompany)
			|		ELSE TRUE
			|	END",
			"DataSourceAlias",
			MotionReflectionParameters.DataSourceAlias);
		ElsIf RegisterName = AccumulationRegistersMetadata.VendorsARAPAccountingByDueDates.Name Then
			ConditionAdditionalSelection = ?(IsBlankString(ConditionAdditionalSelection), "", ConditionAdditionalSelection) + StrReplace("
			|	AND CASE
			|		WHEN DataSourceAlias.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
			|			THEN DataSourceAlias.AccountingDimensionByPartners.Organization <> VALUE(Catalog.Companies.ManagementCompany)
			|		ELSE TRUE
			|	END",
			"DataSourceAlias",
			MotionReflectionParameters.DataSourceAlias);
		EndIf;
		If Query.TempTablesManager.Tables.Find("DocumentCache") <> Undefined Then
			ConditionAdditionalSelection = ?(IsBlankString(ConditionAdditionalSelection), "", ConditionAdditionalSelection) + "
			|	AND NOT TRUE IN
			|			(SELECT TOP 1
			|				TRUE
			|			FROM
			|				DocumentCache AS DocumentCache
			|			WHERE
			|				DocumentCache.Recorder = &Recorder
			|				AND DocumentCache.Period = &Period)";
		EndIf;
		
		QueryText = CaseRecordRequestTextTemplate();
		
		If MetricResourceKeys.Count() > 1 Then
			FinancialAccountingByBalanceSheetRegisterData.AddRepeaterToDimensionFields(QueryText);
		EndIf;
		
		QueryText = StrReplace(QueryText, "&LineOfBusiness", PathsToFieldData.LineOfBusiness);
		QueryText = StrReplace(QueryText, "&FinRecordID", IndicatorSelectionFields.FinRecordID);
		QueryText = StrReplace(QueryText, "&SettingUpBusinessTransaction", PathsToFieldData.SettingUpBusinessTransaction);
		QueryText = StrReplace(QueryText, "&RowID", IndicatorSelectionFields.RowID);
		QueryText = StrReplace(QueryText, "&ThisIsDebit", IndicatorSelectionFields.ThisIsDebit);
		QueryText = StrReplace(QueryText, "&ThisIsLoan", IndicatorSelectionFields.ThisIsLoan);
		QueryText = StrReplace(QueryText, "&ThisIsReverseTransaction", IndicatorSelectionFields.ThisIsReverseTransaction);
		QueryText = StrReplace(QueryText, "&SumMan", IndicatorSelectionFields.SumMan);
		QueryText = StrReplace(QueryText, "&SumCompl", IndicatorSelectionFields.SumCompl);
		QueryText = StrReplace(QueryText, "&SumCurr", IndicatorSelectionFields.SumCurr);
		QueryText = StrReplace(QueryText, "&Count", IndicatorSelectionFields.Count);
		QueryText = StrReplace(QueryText, "&ResourceValueCondition", IndicatorSelectionFields.ResourceValueCondition);
		
		QueryText = StrReplace(QueryText, "&DataSource", DataSource);
		QueryText = StrReplace(QueryText, "&DebitCondition", DebitCondition);
		QueryText = StrReplace(QueryText, "&ConditionCredit", ConditionCredit);
		QueryText = StrReplace(QueryText, "&ConditionLogger", ConditionLogger);
		QueryText = StrReplace(QueryText, "&ConditionDocumentsToBeDeleted", ConditionDocumentsToBeDeleted);
		QueryText = StrReplace(QueryText, "&ConditionAdditionalSelection", ConditionAdditionalSelection);
		QueryText = StrReplace(QueryText, "&RegisterName", FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(RegisterName));
		QueryText = StrReplace(QueryText, "&Currency", PathsToFieldData.Currency);
		QueryText = StrReplace(QueryText, "&Recorder", PathsToFieldData.Recorder);
		QueryText = StrReplace(QueryText, "&Organization", PathsToFieldData.Organization);
		QueryText = StrReplace(QueryText, "&Department", PathsToFieldData.Department);
		QueryText = StrReplace(QueryText, "&VATActivityType", StrTemplate("MAX(%1)", PathsToFieldData.VATActivityType));
		QueryText = StrReplace(QueryText, "&PropsStorno", PathsToFieldData.PropsStorno);
		QueryText = StrReplace(QueryText, "&AdditionalSetupOfHouseholdOperations", PathsToFieldData.AdditionalSetupOfHouseholdOperations);
		
		QueryText = StrReplace(QueryText, "&Factor", IndicatorSelectionFields.Factor);
		
		QueryText = StrReplace(QueryText, "&RequestParameterRegistrar", "&Recorder");
		QueryText = StrReplace(QueryText, "&RequestParameterOrganization", "&Organization");
		
		QueryText = StrReplace(QueryText, "&Period", FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias("Period"));
		QueryText = StrReplace(QueryText, "&Active", FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias("Active"));
		QueryText = StrReplace(QueryText, "&RecordType", FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias("RecordType"));
		
		If RegisterName = AccumulationRegistersMetadata.CustomersARAPAccountingByDueDates.Name Then
			TextOfNestedTable = "(" + StrReplace(QueryText, "INTO NameOfRegisterCacheTable", "") + ")";
			
			// delete after error correction 00-00450915
			AccrualOfClientSAdvancePaymentUponReturn = "(RegisterTable.ThisIsLoan
			|	AND RegisterTable.Factor = VALUE(Enum.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan)
			|	AND RegisterTable.SettingUpBusinessTransaction IN (
			|		VALUE(Catalog.BusinessTransactionsSettings.EmptyRef),
			|		VALUE(Catalog.BusinessTransactionsSettings.AccrualOfAccountsPayable))
			|	AND VALUETYPE(RegisterTable.Recorder) IN (
			|		TYPE(Document.ReturnOfGoodsFromCustomer),
			|		TYPE(Document.SaleAdjustment),
			|		TYPE(Document.ARAPAdjustment)))";
			
			// delete 00-00556880 and 00-00570173 after fixing the cause of the error
			CustomerPrepaymentSettlementDuringAdjustment = "(RegisterTable.ThisIsDebit
			|	AND RegisterTable.Factor = VALUE(Enum.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan)
			|	AND RegisterTable.SettingUpBusinessTransaction IN (
			|		VALUE(Catalog.BusinessTransactionsSettings.AccrualOfAccountsReceivable),
			|		VALUE(Catalog.BusinessTransactionsSettings.APWriteOff))
			|	AND VALUETYPE(RegisterTable.Recorder) IN (
			|		TYPE(Document.ARAPAdjustment)))";
			
			QueryText = "
			|SELECT
			|	RegisterTable.Period AS Period,
			|	RegisterTable.RegisterName AS RegisterName,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN CASE
			|				WHEN &AccrualOfClientSAdvancePaymentUponReturn
			|					THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount)
			|				WHEN &CustomerPrepaymentSettlementDuringAdjustment
			|					THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount)
			|				ELSE RegisterTable.Factor
			|			END
			|		WHEN &AccrualOfClientSAdvancePaymentUponReturn
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount)
			|				ELSE VALUE(Enum.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan)
			|			END
			|		WHEN &CustomerPrepaymentSettlementDuringAdjustment
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan)
			|				ELSE VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount)
			|			END
			|		ELSE RegisterTable.Factor
			|	END AS Factor,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.ThisIsDebit
			|		ELSE PartsOfDoubleEntry.DrCr = &Dr
			|	END AS ThisIsDebit,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.ThisIsLoan
			|		ELSE PartsOfDoubleEntry.DrCr = &Cr
			|	END AS ThisIsLoan,
			|	RegisterTable.ThisIsReverseTransaction AS ThisIsReverseTransaction,
			|	&NestedTableAnalyticsFields,
			|	RegisterTable.Recorder AS Recorder,
			|	RegisterTable.Organization AS Organization,
			|	RegisterTable.Department AS Department,
			|	RegisterTable.LineOfBusiness AS LineOfBusiness,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.SettingUpBusinessTransaction
			|		WHEN &AccrualOfClientSAdvancePaymentUponReturn
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentFromCustomer)
			|		WHEN &CustomerPrepaymentSettlementDuringAdjustment
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.CustomerPrepaymentSettlement)
			|		ELSE RegisterTable.SettingUpBusinessTransaction
			|	END AS SettingUpBusinessTransaction,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.AdditionalSetupOfHouseholdOperations
			|		WHEN &AccrualOfClientSAdvancePaymentUponReturn
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentFromCustomer)
			|		WHEN &CustomerPrepaymentSettlementDuringAdjustment
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.CustomerPrepaymentSettlement)
			|		ELSE RegisterTable.AdditionalSetupOfHouseholdOperations
			|	END AS AdditionalSetupOfHouseholdOperations,
			|	RegisterTable.FinRecordID AS FinRecordID,
			|	RegisterTable.RowID AS RowID,
			|	RegisterTable.OfficialTypeOfActivityVAT AS OfficialTypeOfActivityVAT,
			|	RegisterTable.Currency AS Currency,
			|	SUM(RegisterTable.SumMan) AS SumMan,
			|	SUM(RegisterTable.SumCompl) AS SumCompl,
			|	SUM(RegisterTable.SumCurr) AS SumCurr,
			|	SUM(RegisterTable.Count) AS Count,
			|	RegisterTable.PropsStorno AS PropsStorno
			|FROM
			|	&TextOfNestedTable AS RegisterTable
			|	,
			|	(SELECT
			|		UNDEFINED AS DrCr
			|	UNION ALL
			|	SELECT
			|		&Dr AS DrCr
			|	UNION ALL
			|	SELECT
			|		&Cr AS DrCr
			|	) AS PartsOfDoubleEntry
			|WHERE
			|	PartsOfDoubleEntry.DrCr = UNDEFINED
			|	OR &AccrualOfClientSAdvancePaymentUponReturn
			|	OR &CustomerPrepaymentSettlementDuringAdjustment
			|GROUP BY
			|	RegisterTable.Period,
			|	RegisterTable.RegisterName,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN CASE
			|				WHEN &AccrualOfClientSAdvancePaymentUponReturn
			|					THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount)
			|				WHEN &CustomerPrepaymentSettlementDuringAdjustment
			|					THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount)
			|				ELSE RegisterTable.Factor
			|			END
			|		WHEN &AccrualOfClientSAdvancePaymentUponReturn
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount)
			|				ELSE VALUE(Enum.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan)
			|			END
			|		WHEN &CustomerPrepaymentSettlementDuringAdjustment
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan)
			|				ELSE VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount)
			|			END
			|		ELSE RegisterTable.Factor
			|	END,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.ThisIsDebit
			|		ELSE PartsOfDoubleEntry.DrCr = &Dr
			|	END,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.ThisIsLoan
			|		ELSE PartsOfDoubleEntry.DrCr = &Cr
			|	END,
			|	RegisterTable.ThisIsReverseTransaction,
			|	&NestedTableAnalyticsGroup,
			|	RegisterTable.Recorder,
			|	RegisterTable.Organization,
			|	RegisterTable.Department,
			|	RegisterTable.LineOfBusiness,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.SettingUpBusinessTransaction
			|		WHEN &AccrualOfClientSAdvancePaymentUponReturn
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentFromCustomer)
			|		WHEN &CustomerPrepaymentSettlementDuringAdjustment
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.CustomerPrepaymentSettlement)
			|		ELSE RegisterTable.SettingUpBusinessTransaction
			|	END,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.AdditionalSetupOfHouseholdOperations
			|		WHEN &AccrualOfClientSAdvancePaymentUponReturn
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentFromCustomer)
			|		WHEN &CustomerPrepaymentSettlementDuringAdjustment
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.CustomerPrepaymentSettlement)
			|		ELSE RegisterTable.AdditionalSetupOfHouseholdOperations
			|	END,
			|	RegisterTable.FinRecordID,
			|	RegisterTable.RowID,
			|	RegisterTable.OfficialTypeOfActivityVAT,
			|	RegisterTable.Currency,
			|	RegisterTable.PropsStorno
			|";
			
			QueryText = StrReplace(QueryText, "&TextOfNestedTable", TextOfNestedTable);
			QueryText = StrReplace(QueryText, "&AccrualOfClientSAdvancePaymentUponReturn", AccrualOfClientSAdvancePaymentUponReturn);
			QueryText = StrReplace(QueryText, "&CustomerPrepaymentSettlementDuringAdjustment", CustomerPrepaymentSettlementDuringAdjustment);
			
		ElsIf RegisterName = AccumulationRegistersMetadata.VendorsARAPAccountingByDueDates.Name Then
			TextOfNestedTable = "(" + StrReplace(QueryText, "INTO NameOfRegisterCacheTable", "") + ")";
			
			// delete after error correction 00-00453822
			AccrualOfAdvancePaymentToSupplierUponReturn = "(RegisterTable.ThisIsDebit
			|	AND RegisterTable.Factor = VALUE(Enum.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan)
			|	AND RegisterTable.SettingUpBusinessTransaction IN (
			|		VALUE(Catalog.BusinessTransactionsSettings.EmptyRef),
			|		VALUE(Catalog.BusinessTransactionsSettings.AccrualOfAccountsReceivable))
			|	AND VALUETYPE(RegisterTable.Recorder) IN (
			|		TYPE(Document.ReturnOfGoodsToVendor),
			|		TYPE(Document.PurchaseAdjustment),
			|		TYPE(Document.ARAPAdjustment)))";
			
			// delete 00-00556880 and 00-00570173 after fixing the cause of the error
			VendorPrepaymentSettlementDuringAdjustment = "(RegisterTable.ThisIsLoan
			|	AND RegisterTable.Factor = VALUE(Enum.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan)
			|	AND RegisterTable.SettingUpBusinessTransaction IN (
			|		VALUE(Catalog.BusinessTransactionsSettings.AccrualOfAccountsPayable),
			|		VALUE(Catalog.BusinessTransactionsSettings.ARWriteOff))
			|	AND VALUETYPE(RegisterTable.Recorder) IN (
			|		TYPE(Document.ARAPAdjustment)))";
			
			QueryText = "
			|SELECT
			|	RegisterTable.Period AS Period,
			|	RegisterTable.RegisterName AS RegisterName,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN CASE
			|				WHEN &AccrualOfAdvancePaymentToSupplierUponReturn
			|					THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount)
			|				WHEN &VendorPrepaymentSettlementDuringAdjustment
			|					THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount)
			|				ELSE RegisterTable.Factor
			|			END
			|		WHEN &AccrualOfAdvancePaymentToSupplierUponReturn
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan)
			|				ELSE VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount)
			|			END
			|		WHEN &VendorPrepaymentSettlementDuringAdjustment
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount)
			|				ELSE VALUE(Enum.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan)
			|			END
			|		ELSE RegisterTable.Factor
			|	END AS Factor,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.ThisIsDebit
			|		ELSE PartsOfDoubleEntry.DrCr = &Dr
			|	END AS ThisIsDebit,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.ThisIsLoan
			|		ELSE PartsOfDoubleEntry.DrCr = &Cr
			|	END AS ThisIsLoan,
			|	RegisterTable.ThisIsReverseTransaction AS ThisIsReverseTransaction,
			|	&NestedTableAnalyticsFields,
			|	RegisterTable.Recorder AS Recorder,
			|	RegisterTable.Organization AS Organization,
			|	RegisterTable.Department AS Department,
			|	RegisterTable.LineOfBusiness AS LineOfBusiness,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.SettingUpBusinessTransaction
			|		WHEN &AccrualOfAdvancePaymentToSupplierUponReturn
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentToVendor)
			|		WHEN &VendorPrepaymentSettlementDuringAdjustment
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.VendorPrepaymentSettlement)
			|		ELSE RegisterTable.SettingUpBusinessTransaction
			|	END AS SettingUpBusinessTransaction,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.AdditionalSetupOfHouseholdOperations
			|		WHEN &AccrualOfAdvancePaymentToSupplierUponReturn
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentToVendor)
			|		WHEN &VendorPrepaymentSettlementDuringAdjustment
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.VendorPrepaymentSettlement)
			|		ELSE RegisterTable.AdditionalSetupOfHouseholdOperations
			|	END AS AdditionalSetupOfHouseholdOperations,
			|	RegisterTable.FinRecordID AS FinRecordID,
			|	RegisterTable.RowID AS RowID,
			|	RegisterTable.OfficialTypeOfActivityVAT AS OfficialTypeOfActivityVAT,
			|	RegisterTable.Currency AS Currency,
			|	SUM(RegisterTable.SumMan) AS SumMan,
			|	SUM(RegisterTable.SumCompl) AS SumCompl,
			|	SUM(RegisterTable.SumCurr) AS SumCurr,
			|	SUM(RegisterTable.Count) AS Count,
			|	RegisterTable.PropsStorno AS PropsStorno
			|FROM
			|	&TextOfNestedTable AS RegisterTable
			|	,
			|	(SELECT
			|		UNDEFINED AS DrCr
			|	UNION ALL
			|	SELECT
			|		&Dr AS DrCr
			|	UNION ALL
			|	SELECT
			|		&Cr AS DrCr
			|	) AS PartsOfDoubleEntry
			|WHERE
			|	PartsOfDoubleEntry.DrCr = UNDEFINED
			|	OR &AccrualOfAdvancePaymentToSupplierUponReturn
			|	OR &VendorPrepaymentSettlementDuringAdjustment
			|GROUP BY
			|	RegisterTable.Period,
			|	RegisterTable.RegisterName,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN CASE
			|				WHEN &AccrualOfAdvancePaymentToSupplierUponReturn
			|					THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount)
			|				WHEN &VendorPrepaymentSettlementDuringAdjustment
			|					THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount)
			|				ELSE RegisterTable.Factor
			|			END
			|		WHEN &AccrualOfAdvancePaymentToSupplierUponReturn
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan)
			|				ELSE VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount)
			|			END
			|		WHEN &VendorPrepaymentSettlementDuringAdjustment
			|			THEN CASE
			|				WHEN PartsOfDoubleEntry.DrCr = &Dr
			|					THEN VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount)
			|				ELSE VALUE(Enum.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan)
			|			END
			|		ELSE RegisterTable.Factor
			|	END,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.ThisIsDebit
			|		ELSE PartsOfDoubleEntry.DrCr = &Dr
			|	END,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.ThisIsLoan
			|		ELSE PartsOfDoubleEntry.DrCr = &Cr
			|	END,
			|	RegisterTable.ThisIsReverseTransaction,
			|	&NestedTableAnalyticsGroup,
			|	RegisterTable.Recorder,
			|	RegisterTable.Organization,
			|	RegisterTable.Department,
			|	RegisterTable.LineOfBusiness,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.SettingUpBusinessTransaction
			|		WHEN &AccrualOfAdvancePaymentToSupplierUponReturn
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentToVendor)
			|		WHEN &VendorPrepaymentSettlementDuringAdjustment
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.VendorPrepaymentSettlement)
			|		ELSE RegisterTable.SettingUpBusinessTransaction
			|	END,
			|	CASE
			|		WHEN PartsOfDoubleEntry.DrCr = UNDEFINED
			|			THEN RegisterTable.AdditionalSetupOfHouseholdOperations
			|		WHEN &AccrualOfAdvancePaymentToSupplierUponReturn
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentToVendor)
			|		WHEN &VendorPrepaymentSettlementDuringAdjustment
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.VendorPrepaymentSettlement)
			|		ELSE RegisterTable.AdditionalSetupOfHouseholdOperations
			|	END,
			|	RegisterTable.FinRecordID,
			|	RegisterTable.RowID,
			|	RegisterTable.OfficialTypeOfActivityVAT,
			|	RegisterTable.Currency,
			|	RegisterTable.PropsStorno
			|";
			
			QueryText = StrReplace(QueryText, "&TextOfNestedTable", TextOfNestedTable);
			QueryText = StrReplace(QueryText, "&AccrualOfAdvancePaymentToSupplierUponReturn", AccrualOfAdvancePaymentToSupplierUponReturn);
			QueryText = StrReplace(QueryText, "&VendorPrepaymentSettlementDuringAdjustment", VendorPrepaymentSettlementDuringAdjustment);
		EndIf;

		
		RegisterRequestsTexts.Insert(RegisterName, QueryText);
		
	EndDo;
	
	Return RegisterRequestsTexts;
	
EndFunction

Function RequestTextForCorrespondenceRecords(RequestTextsForRegisterEntries)
	
	QueriesTexts = New Array();
	
	For Each KeyAndValue In RequestTextsForRegisterEntries Do
		QueriesTexts.Add(KeyAndValue.Value);
	EndDo;
	
	QueryText = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText = StrReplace(QueryText, "INTO NameOfRegisterCacheTable", "");
	
	QueryText = StrReplace(QueryText, "&AnalyticsSelectionFields", "//AnalyticsSelectionFields");
	QueryText = StrReplace(QueryText, "&AnalyticsFieldGroup", "//AnalyticsFieldGroup");
	
	QueryText = StrReplace(QueryText, "&NestedTableAnalyticsFields", "//NestedTableAnalyticsFields");
	QueryText = StrReplace(QueryText, "&NestedTableAnalyticsGroup", "//NestedTableAnalyticsGroup");
	
	SelectionFieldsToDelete = StrSplit("Department,LineOfBusiness", ",");
	IndexingFields = StrSplit("ThisIsDebit,ThisIsLoan", ",");
	FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(QueryText, SelectionFieldsToDelete , IndexingFields, "TTMovementRegisters");

	Return QueryText;
	
EndFunction

Procedure GenerateCorrespondencesOfRegisterEntries(Query, QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	RECORDAUTONUMBER() AS RecNo,
	|	RegisterRegisteredRecords_1.Period AS Period,
	|	RegisterRegisteredRecords_1.RegisterName AS RegisterName,
	|	RegisterRegisteredRecords_1.Factor AS Factor,
	|	RegisterRegisteredRecords_1.ThisIsDebit AS ThisIsDebit,
	|	RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRegisteredRecords_1.Recorder AS Recorder,
	|	RegisterRegisteredRecords_1.Organization AS Organization,
	|	RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRegisteredRecords_1.AdditionalSetupOfHouseholdOperations AS AdditionalSetupOfHouseholdOperations,
	|	RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
	|	RegisterRegisteredRecords_1.RowID AS RowID,
	|	RegisterRegisteredRecords_1.OfficialTypeOfActivityVAT AS VATActivityType,
	|	RegisterRegisteredRecords_1.Currency AS Currency,
	|	CASE
	|		WHEN RegisterRegisteredRecords_1.SumMan <> 0
	|			THEN RegisterRegisteredRecords_1.SumMan
	|		WHEN NOT RegisterRegisteredRecords_1.RegisterName IN (&RegistersWithoutManSum)
	|			THEN RegisterRegisteredRecords_1.SumMan
	|		WHEN RegisterRegisteredRecords_1.Currency = &ManagementAccountingCurrency
	|			THEN RegisterRegisteredRecords_1.SumCurr
	|		WHEN RegisterRegisteredRecords_1.Organization.LocalAccountingCurrency = &ManagementAccountingCurrency
	|			THEN CASE
	|				WHEN RegisterRegisteredRecords_1.SumCompl <> 0
	|					THEN RegisterRegisteredRecords_1.SumCompl
	|				WHEN ISNULL(RegisterRegisteredRecords_1.Currency, VALUE(Catalog.Currencies.EmptyRef)) = VALUE(Catalog.Currencies.EmptyRef)
	|					THEN RegisterRegisteredRecords_1.SumCurr
	|				ELSE RegisterRegisteredRecords_1.SumMan
	|			END
	|		ELSE RegisterRegisteredRecords_1.SumMan
	|	END AS SumMan,
	|	CASE
	|		WHEN RegisterRegisteredRecords_1.SumCompl <> 0
	|			THEN RegisterRegisteredRecords_1.SumCompl
	|		WHEN NOT RegisterRegisteredRecords_1.RegisterName IN (&RegistersWithoutSumLocal)
	|			THEN RegisterRegisteredRecords_1.SumCompl
	|		WHEN RegisterRegisteredRecords_1.Currency = RegisterRegisteredRecords_1.Organization.LocalAccountingCurrency
	|			THEN RegisterRegisteredRecords_1.SumCurr
	|		WHEN RegisterRegisteredRecords_1.Organization.LocalAccountingCurrency = &ManagementAccountingCurrency
	|			AND RegisterRegisteredRecords_1.SumMan <> 0
	|			THEN RegisterRegisteredRecords_1.SumMan
	|		WHEN ISNULL(RegisterRegisteredRecords_1.Currency, VALUE(Catalog.Currencies.EmptyRef)) = VALUE(Catalog.Currencies.EmptyRef)
	|			THEN RegisterRegisteredRecords_1.SumCurr
	|		ELSE RegisterRegisteredRecords_1.SumCompl
	|	END AS SumCompl,
	|	RegisterRegisteredRecords_1.SumCurr AS SumCurr,
	|	RegisterRegisteredRecords_1.Count AS Count,
	|	RegisterRegisteredRecords_1.PropsStorno AS PropsStorno
	|INTO TTMovementRegistersDebit
	|FROM
	|	TTMovementRegisters AS RegisterRegisteredRecords_1
	|WHERE
	|	NOT RegisterRegisteredRecords_1.ThisIsLoan
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	RECORDAUTONUMBER() AS RecNo,
	|	RegisterRegisteredRecords_1.Period AS Period,
	|	RegisterRegisteredRecords_1.RegisterName AS RegisterName,
	|	RegisterRegisteredRecords_1.Factor AS Factor,
	|	RegisterRegisteredRecords_1.ThisIsLoan AS ThisIsLoan,
	|	RegisterRegisteredRecords_1.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRegisteredRecords_1.Recorder AS Recorder,
	|	RegisterRegisteredRecords_1.Organization AS Organization,
	|	RegisterRegisteredRecords_1.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRegisteredRecords_1.AdditionalSetupOfHouseholdOperations AS AdditionalSetupOfHouseholdOperations,
	|	RegisterRegisteredRecords_1.FinRecordID AS FinRecordID,
	|	RegisterRegisteredRecords_1.RowID AS RowID,
	|	RegisterRegisteredRecords_1.OfficialTypeOfActivityVAT AS VATActivityType,
	|	RegisterRegisteredRecords_1.Currency AS Currency,
	|	CASE
	|		WHEN RegisterRegisteredRecords_1.SumMan <> 0
	|			THEN RegisterRegisteredRecords_1.SumMan
	|		WHEN NOT RegisterRegisteredRecords_1.RegisterName IN (&RegistersWithoutManSum)
	|			THEN RegisterRegisteredRecords_1.SumMan
	|		WHEN RegisterRegisteredRecords_1.Currency = &ManagementAccountingCurrency
	|			THEN RegisterRegisteredRecords_1.SumCurr
	|		WHEN RegisterRegisteredRecords_1.Organization.LocalAccountingCurrency = &ManagementAccountingCurrency
	|			THEN CASE
	|				WHEN RegisterRegisteredRecords_1.SumCompl <> 0
	|					THEN RegisterRegisteredRecords_1.SumCompl
	|				WHEN ISNULL(RegisterRegisteredRecords_1.Currency, VALUE(Catalog.Currencies.EmptyRef)) = VALUE(Catalog.Currencies.EmptyRef)
	|					THEN RegisterRegisteredRecords_1.SumCurr
	|				ELSE RegisterRegisteredRecords_1.SumMan
	|			END
	|		ELSE RegisterRegisteredRecords_1.SumMan
	|	END AS SumMan,
	|	CASE
	|		WHEN RegisterRegisteredRecords_1.SumCompl <> 0
	|			THEN RegisterRegisteredRecords_1.SumCompl
	|		WHEN NOT RegisterRegisteredRecords_1.RegisterName IN (&RegistersWithoutSumLocal)
	|			THEN RegisterRegisteredRecords_1.SumCompl
	|		WHEN RegisterRegisteredRecords_1.Currency = RegisterRegisteredRecords_1.Organization.LocalAccountingCurrency
	|			THEN RegisterRegisteredRecords_1.SumCurr
	|		WHEN RegisterRegisteredRecords_1.Organization.LocalAccountingCurrency = &ManagementAccountingCurrency
	|			AND RegisterRegisteredRecords_1.SumMan <> 0
	|			THEN RegisterRegisteredRecords_1.SumMan
	|		WHEN ISNULL(RegisterRegisteredRecords_1.Currency, VALUE(Catalog.Currencies.EmptyRef)) = VALUE(Catalog.Currencies.EmptyRef)
	|			THEN RegisterRegisteredRecords_1.SumCurr
	|		ELSE RegisterRegisteredRecords_1.SumCompl
	|	END AS SumCompl,
	|	RegisterRegisteredRecords_1.SumCurr AS SumCurr,
	|	RegisterRegisteredRecords_1.Count AS Count,
	|	RegisterRegisteredRecords_1.PropsStorno AS PropsStorno
	|INTO TTMovementRegistersCredit
	|FROM
	|	TTMovementRegisters AS RegisterRegisteredRecords_1
	|WHERE
	|	NOT RegisterRegisteredRecords_1.ThisIsDebit
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMovementRegisters");
	
	ProcessAndConnectMovementTables(Query, QueriesTexts);
	
	IdentifyCorrespondenceErrors(QueriesTexts, Query.Parameters, True);
	
	If FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, QueriesTexts, "TTCorrespondenceErrors") Then
		DetermineMaximumNumberOfMovementRecords(QueriesTexts);
		
		RestoreRegisteredRecordsOfErroneousCorrespondence(QueriesTexts, Query.Parameters, "Dr");
		RestoreRegisteredRecordsOfErroneousCorrespondence(QueriesTexts, Query.Parameters, "Cr");
		
		IdentifyRegistersWithReverseRegisteredRecords(QueriesTexts);
		
		ReplaceReverseMovementWithReverse(QueriesTexts, "Dr");
		ReplaceReverseMovementWithReverse(QueriesTexts, "Cr");
		
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCorrespondenceErrors");
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMaximumNumberOfEntries");
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRegisterRegisteredRecordsReverseDebit");
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMovementRegistersReverseCredit");
		
		TableOfCorrespondenceOfRegisteredRecordsOfRegisters = Query.Parameters.TableOfCorrespondenceOfRegisteredRecordsOfRegisters;
		
		ProcessAndConnectMovementTables(Query, QueriesTexts);
		
		IdentifyCorrespondenceWithoutErrors(QueriesTexts, Query.Parameters);
		DetermineReverseToReverseReplacementRegisters(QueriesTexts);
		
		If FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, QueriesTexts, "TTCorrespondenceWithoutErrors") Then
			ReplaceCorrespondenceReverseWithReverse(QueriesTexts,
				Query.Parameters.TableOfCorrespondenceOfRegisteredRecordsOfRegisters,
				TableOfCorrespondenceOfRegisteredRecordsOfRegisters);
			
			TableOfReverseReplacementRegisters = Query.TempTablesManager.Tables.Find("TTReverseToReverseReplacementRegisters");
			TableOfReverseReplacementRegisters = TableOfReverseReplacementRegisters.GetData().Unload();
			Query.Parameters.ReverseToReverseReplacementRegisters = TableOfReverseReplacementRegisters.UnloadColumn("RegisterName");
		Else
			Query.Parameters.TableOfCorrespondenceOfRegisteredRecordsOfRegisters = TableOfCorrespondenceOfRegisteredRecordsOfRegisters;
		EndIf;
		
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCorrespondenceWithoutErrors");
		
	Else
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCorrespondenceErrors");
		AddEmptyTableOfReverseReplacementDocuments(QueriesTexts);
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTDebit");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCredit");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCorDataSources");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTIdsOfCorDataSources");
	
	RestoreStornoCalculationsIfNecessary(Query, QueriesTexts);
	
	QueryText = "
	|SELECT
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.RecNoDr AS RecNoDr,
	|	RegisteredRecordsDebitCredit.RecNoCr AS RecNoCr,
	|	0 AS ComplexRecordNumber,
	|	RegisteredRecordsDebitCredit.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsDebitCredit.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsDebitCredit.FactorDr AS FactorDr,
	|	RegisteredRecordsDebitCredit.FactorCr AS FactorCr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	ISNULL(RegisteredRecordsDebitCredit.Organization, VALUE(Catalog.Companies.EmptyRef)) AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsDebitCredit.AdditionalSetupOfHouseholdOperationsDr AS AdditionalSetupOfHouseholdOperationsDr,
	|	RegisteredRecordsDebitCredit.AdditionalSetupOfHouseholdOperationsCr AS AdditionalSetupOfHouseholdOperationsCr,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	RegisteredRecordsDebitCredit.RowIDDr AS RowIDDr,
	|	RegisteredRecordsDebitCredit.RowIDCr AS RowIDCr,
	|	RegisteredRecordsDebitCredit.VATActivityTypeDr AS VATActivityTypeDr,
	|	RegisteredRecordsDebitCredit.VATActivityTypeCr AS VATActivityTypeCr,
	|	RegisteredRecordsDebitCredit.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsDebitCredit.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsDebitCredit.AmountOfMovementShaftDr AS AmountOfMovementShaftDr,
	|	RegisteredRecordsDebitCredit.AmountOfMovementCrShaft AS AmountOfMovementCrShaft,
	|	RegisteredRecordsDebitCredit.AmountOfDrMovement AS AmountOfDrMovement,
	|	RegisteredRecordsDebitCredit.CrMotionCount AS CrMotionCount,
	|	RegisteredRecordsDebitCredit.PropsStornoDr AS PropsStornoDr,
	|	RegisteredRecordsDebitCredit.PropsStornoCr AS PropsStornoCr,
	|	RegisteredRecordsDebitCredit.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsDebitCredit.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsDebitCredit.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SumManDr <> 0
	|			THEN RegisteredRecordsDebitCredit.SumManDr
	|		WHEN NOT RegisteredRecordsDebitCredit.RegisterNameDr IN (&RegistersWithoutManSum)
	|			THEN RegisteredRecordsDebitCredit.SumManDr
	|		WHEN RegisteredRecordsDebitCredit.SumComplDr = RegisteredRecordsDebitCredit.SumComplCr
	|			AND NOT RegisteredRecordsDebitCredit.ComplexEntryCr
	|			THEN RegisteredRecordsDebitCredit.SumManCr
	|		ELSE RegisteredRecordsDebitCredit.SumManDr
	|	END AS SumManDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SumManCr <> 0
	|			THEN RegisteredRecordsDebitCredit.SumManCr
	|		WHEN NOT RegisteredRecordsDebitCredit.RegisterNameCr IN (&RegistersWithoutManSum)
	|			THEN RegisteredRecordsDebitCredit.SumManCr
	|		WHEN RegisteredRecordsDebitCredit.SumComplDr = RegisteredRecordsDebitCredit.SumComplCr
	|			AND NOT RegisteredRecordsDebitCredit.ComplexEntryDr
	|			THEN RegisteredRecordsDebitCredit.SumManDr
	|		ELSE RegisteredRecordsDebitCredit.SumManCr
	|	END AS SumManCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SumComplDr <> 0
	|			THEN RegisteredRecordsDebitCredit.SumComplDr
	|		WHEN NOT RegisteredRecordsDebitCredit.RegisterNameDr IN (&RegistersWithoutSumLocal)
	|			THEN RegisteredRecordsDebitCredit.SumComplDr
	|		WHEN RegisteredRecordsDebitCredit.SumManDr = RegisteredRecordsDebitCredit.SumManCr
	|			AND NOT RegisteredRecordsDebitCredit.ComplexEntryCr
	|			THEN RegisteredRecordsDebitCredit.SumComplCr
	|		ELSE RegisteredRecordsDebitCredit.SumComplDr
	|	END AS SumComplDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SumComplCr <> 0
	|			THEN RegisteredRecordsDebitCredit.SumComplCr
	|		WHEN NOT RegisteredRecordsDebitCredit.RegisterNameCr IN (&RegistersWithoutSumLocal)
	|			THEN RegisteredRecordsDebitCredit.SumComplCr
	|		WHEN RegisteredRecordsDebitCredit.SumManDr = RegisteredRecordsDebitCredit.SumManCr
	|			AND NOT RegisteredRecordsDebitCredit.ComplexEntryDr
	|			THEN RegisteredRecordsDebitCredit.SumComplDr
	|		ELSE RegisteredRecordsDebitCredit.SumComplCr
	|	END AS SumComplCr
	|INTO TTMovementDebitCredit
	|FROM
	|	TableOfCorrespondenceOfRegisteredRecordsOfRegisters AS RegisteredRecordsDebitCredit
	|";
	
	If Query.Parameters.RestoreCalculationsForStorno Then
		QueryTextOfStornoCalculations = "
		|SELECT
		|	SettlementsWithCustomersOnStorno.Period AS Period,
		|	0 AS RecNoDr,
		|	0 AS RecNoCr,
		|	0 AS ComplexRecordNumber,
		|	SettlementsWithCustomersOnStorno.RegisterName AS RegisterNameDr,
		|	SettlementsWithCustomersOnStorno.RegisterName AS RegisterNameCr,
		|	SettlementsWithCustomersOnStorno.FactorDr AS FactorDr,
		|	SettlementsWithCustomersOnStorno.FactorCr AS FactorCr,
		|	SettlementsWithCustomersOnStorno.ThisIsReverseTransaction AS ThisIsReverseTransactionDr,
		|	SettlementsWithCustomersOnStorno.ThisIsReverseTransaction AS ThisIsReverseTransactionCr,
		|	SettlementsWithCustomersOnStorno.Organization AS Organization,
		|	SettlementsWithCustomersOnStorno.Recorder AS Recorder,
		|	SettlementsWithCustomersOnStorno.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
		|	SettlementsWithCustomersOnStorno.AdditionalSetupOfHouseholdOperationsDr AS AdditionalSetupOfHouseholdOperationsDr,
		|	SettlementsWithCustomersOnStorno.AdditionalSetupOfHouseholdOperationsCr AS AdditionalSetupOfHouseholdOperationsCr,
		|	SettlementsWithCustomersOnStorno.FinRecordID AS FinRecordID,
		|	SettlementsWithCustomersOnStorno.RowID AS RowIDDr,
		|	SettlementsWithCustomersOnStorno.RowID AS RowIDCr,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeDr,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeCr,
		|	SettlementsWithCustomersOnStorno.Currency AS CurrencyDr,
		|	SettlementsWithCustomersOnStorno.Currency AS CurrencyCr,
		|	SettlementsWithCustomersOnStorno.SumManDr AS AmountOfManMovementDr,
		|	SettlementsWithCustomersOnStorno.SumManCr AS AmountOfManMovementCr,
		|	SettlementsWithCustomersOnStorno.SumComplDr AS AmountOfLocalTrafficDr,
		|	SettlementsWithCustomersOnStorno.SumComplCr AS AmountOfLocalTrafficCr,
		|	SettlementsWithCustomersOnStorno.SumCurrDr AS AmountOfMovementShaftDr,
		|	SettlementsWithCustomersOnStorno.SumCurrCr AS AmountOfMovementCrShaft,
		|	0 AS AmountOfDrMovement,
		|	0 AS CrMotionCount,
		|	SettlementsWithCustomersOnStorno.PropsStorno AS PropsStornoDr,
		|	SettlementsWithCustomersOnStorno.PropsStorno AS PropsStornoCr,
		|	FALSE AS ComplexEntryDr,
		|	FALSE AS ComplexEntryCr,
		|	TRUE AS TakeIntoAccountBusinessTransaction,
		|	SettlementsWithCustomersOnStorno.SumManDr AS SumManDr,
		|	SettlementsWithCustomersOnStorno.SumManCr AS SumManCr,
		|	SettlementsWithCustomersOnStorno.SumComplDr AS SumComplDr,
		|	SettlementsWithCustomersOnStorno.SumComplCr AS SumComplCr
		|FROM
		|	TTSettlementsWithCustomersOnStorno AS SettlementsWithCustomersOnStorno
		|
		|UNION ALL
		|
		|SELECT
		|	SettlementsWithSuppliersOnStorno.Period AS Period,
		|	0 AS RecNoDr,
		|	0 AS RecNoCr,
		|	0 AS ComplexRecordNumber,
		|	SettlementsWithSuppliersOnStorno.RegisterName AS RegisterNameDr,
		|	SettlementsWithSuppliersOnStorno.RegisterName AS RegisterNameCr,
		|	SettlementsWithSuppliersOnStorno.FactorDr AS FactorDr,
		|	SettlementsWithSuppliersOnStorno.FactorCr AS FactorCr,
		|	SettlementsWithSuppliersOnStorno.ThisIsReverseTransaction AS ThisIsReverseTransactionDr,
		|	SettlementsWithSuppliersOnStorno.ThisIsReverseTransaction AS ThisIsReverseTransactionCr,
		|	SettlementsWithSuppliersOnStorno.Organization AS Organization,
		|	SettlementsWithSuppliersOnStorno.Recorder AS Recorder,
		|	SettlementsWithSuppliersOnStorno.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
		|	SettlementsWithSuppliersOnStorno.AdditionalSetupOfHouseholdOperationsDr AS AdditionalSetupOfHouseholdOperationsDr,
		|	SettlementsWithSuppliersOnStorno.AdditionalSetupOfHouseholdOperationsCr AS AdditionalSetupOfHouseholdOperationsCr,
		|	SettlementsWithSuppliersOnStorno.FinRecordID AS FinRecordID,
		|	SettlementsWithSuppliersOnStorno.RowID AS RowIDDr,
		|	SettlementsWithSuppliersOnStorno.RowID AS RowIDCr,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeDr,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeCr,
		|	SettlementsWithSuppliersOnStorno.Currency AS CurrencyDr,
		|	SettlementsWithSuppliersOnStorno.Currency AS CurrencyCr,
		|	SettlementsWithSuppliersOnStorno.SumManDr AS AmountOfManMovementDr,
		|	SettlementsWithSuppliersOnStorno.SumManCr AS AmountOfManMovementCr,
		|	SettlementsWithSuppliersOnStorno.SumComplDr AS AmountOfLocalTrafficDr,
		|	SettlementsWithSuppliersOnStorno.SumComplCr AS AmountOfLocalTrafficCr,
		|	SettlementsWithSuppliersOnStorno.SumCurrDr AS AmountOfMovementShaftDr,
		|	SettlementsWithSuppliersOnStorno.SumCurrCr AS AmountOfMovementCrShaft,
		|	0 AS AmountOfDrMovement,
		|	0 AS CrMotionCount,
		|	SettlementsWithSuppliersOnStorno.PropsStorno AS PropsStornoDr,
		|	SettlementsWithSuppliersOnStorno.PropsStorno AS PropsStornoCr,
		|	FALSE AS ComplexEntryDr,
		|	FALSE AS ComplexEntryCr,
		|	TRUE AS TakeIntoAccountBusinessTransaction,
		|	SettlementsWithSuppliersOnStorno.SumManDr AS SumManDr,
		|	SettlementsWithSuppliersOnStorno.SumManCr AS SumManCr,
		|	SettlementsWithSuppliersOnStorno.SumComplDr AS SumComplDr,
		|	SettlementsWithSuppliersOnStorno.SumComplCr AS SumComplCr
		|FROM
		|	TTSettlementsWithSuppliersOnStorno AS SettlementsWithSuppliersOnStorno
		|";
		
		QueryText = QueryText
			+ TMCommonUse.QuerySeparatorInJoin()
			+ QueryTextOfStornoCalculations;
	EndIf;
	
	QueryText = QueryText + "
	|INDEX BY
	|	Recorder,
	|	RowIDDr,
	|	RowIDCr,
	|	CurrencyDr,
	|	CurrencyCr,
	|	ComplexEntryDr,
	|	ComplexEntryCr
	|";
	
	QueryText = StrReplace(QueryText,
		"TableOfCorrespondenceOfRegisteredRecordsOfRegisters",
		Query.Parameters.TableOfCorrespondenceOfRegisteredRecordsOfRegisters);
	
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts,
		Query.Parameters.TableOfCorrespondenceOfRegisteredRecordsOfRegisters);
	
EndProcedure

Procedure AllocateUnbalancedCorrespondenceResources(Query, QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	DocumentAmountsInAccountingCurrency.Recorder AS Recorder,
	|	DocumentAmountsInAccountingCurrency.RowID AS RowID,
	|	DocumentAmountsInAccountingCurrency.ARAPCurrency AS ARAPCurrency,
	|	DocumentAmountsInAccountingCurrency.Currency AS Currency,
	|	DocumentAmountsInAccountingCurrency.AmountExcludingVAT AS AmountExcludingVAT,
	|	DocumentAmountsInAccountingCurrency.VATAmount AS VATAmount,
	|	DocumentAmountsInAccountingCurrency.AmountARAP AS AmountARAP,
	|	DocumentAmountsInAccountingCurrency.AmountVATARAP AS AmountVATARAP
	|INTO TTAmountsOfDocumentsInAccountingCurrencies
	|FROM
	|	InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
	|WHERE
	// Disabled before implementation in budgeting of accounting objects
	|	FALSE
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTMovementDebitCredit AS RegisteredRecordsDebitCredit
	|		WHERE
	|			RegisteredRecordsDebitCredit.Recorder = DocumentAmountsInAccountingCurrency.Recorder
	|			AND (RegisteredRecordsDebitCredit.ComplexEntryDr OR RegisteredRecordsDebitCredit.ComplexEntryCr)
	|		)
	|	AND DocumentAmountsInAccountingCurrency.RecordedInARAPAccounting
	|	AND DocumentAmountsInAccountingCurrency.ARAPCurrency <> &ManagementAccountingCurrency
	|	AND (DocumentAmountsInAccountingCurrency.ARAPCurrency = DocumentAmountsInAccountingCurrency.Currency
	|		OR DocumentAmountsInAccountingCurrency.AmountVATARAP <> 0)
	|INDEX BY
	|	Recorder,
	|	RowID,
	|	ARAPCurrency
	|");
	
	QueryText = "
	|SELECT
	|	RECORDAUTONUMBER() AS LineNumber,
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.RecNoDr AS RecNoDr,
	|	RegisteredRecordsDebitCredit.RecNoCr AS RecNoCr,
	|	RegisteredRecordsDebitCredit.ComplexRecordNumber AS ComplexRecordNumber,
	|	RegisteredRecordsDebitCredit.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsDebitCredit.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsDebitCredit.FactorDr AS FactorDr,
	|	RegisteredRecordsDebitCredit.FactorCr AS FactorCr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsDebitCredit.AdditionalSetupOfHouseholdOperationsDr AS AdditionalSetupOfHouseholdOperationsDr,
	|	RegisteredRecordsDebitCredit.AdditionalSetupOfHouseholdOperationsCr AS AdditionalSetupOfHouseholdOperationsCr,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	RegisteredRecordsDebitCredit.RowIDDr AS RowIDDr,
	|	RegisteredRecordsDebitCredit.RowIDCr AS RowIDCr,
	|	RegisteredRecordsDebitCredit.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsDebitCredit.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsDebitCredit.PropsStornoDr AS PropsStornoDr,
	|	RegisteredRecordsDebitCredit.PropsStornoCr AS PropsStornoCr,
	|	RegisteredRecordsDebitCredit.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsDebitCredit.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsDebitCredit.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisteredRecordsDebitCredit.SumManDr AS SumManDr,
	|	RegisteredRecordsDebitCredit.SumManCr AS SumManCr,
	|	RegisteredRecordsDebitCredit.SumComplDr AS SumComplDr,
	|	RegisteredRecordsDebitCredit.SumComplCr AS SumComplCr,
	|	RegisteredRecordsDebitCredit.AmountOfMovementShaftDr AS DistributableAmountShaftDr,
	|	RegisteredRecordsDebitCredit.AmountOfMovementCrShaft AS DistributableAmountOfCrShaft,
	|	RegisteredRecordsDebitCredit.AmountOfDrMovement AS DistributableAmountOfDr,
	|	RegisteredRecordsDebitCredit.CrMotionCount AS DistributableNumberOfCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SettingUpBusinessTransaction IN (&BusinessTransactionsWithoutAccountingInForeignCurrency)
	|			THEN FALSE
	|		WHEN RegisteredRecordsDebitCredit.CurrencyDr = VALUE(Catalog.Currencies.EmptyRef)
	|			THEN FALSE
	|		WHEN NOT RegisteredRecordsDebitCredit.ComplexEntryDr
	|			THEN FALSE
	|		WHEN RegisteredRecordsDebitCredit.CurrencyDr = &ManagementAccountingCurrency
	|			THEN FALSE
	|		WHEN RegisteredRecordsDebitCredit.CurrencyDr = RegisteredRecordsDebitCredit.Organization.LocalAccountingCurrency
	|			THEN FALSE
	|		WHEN AmountsInDrCurrencies.RowID IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereIsSumDistributionDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SettingUpBusinessTransaction IN (&BusinessTransactionsWithoutAccountingInForeignCurrency)
	|			THEN FALSE
	|		WHEN RegisteredRecordsDebitCredit.CurrencyCr = VALUE(Catalog.Currencies.EmptyRef)
	|			THEN FALSE
	|		WHEN NOT RegisteredRecordsDebitCredit.ComplexEntryCr
	|			THEN FALSE
	|		WHEN RegisteredRecordsDebitCredit.CurrencyCr = &ManagementAccountingCurrency
	|			THEN FALSE
	|		WHEN RegisteredRecordsDebitCredit.CurrencyCr = RegisteredRecordsDebitCredit.Organization.LocalAccountingCurrency
	|			THEN FALSE
	|		WHEN AmountsInCrCurrencies.RowID IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereIsSumDistributionCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SettingUpBusinessTransaction IN (&BusinessTransactionsWithoutAccountingInForeignCurrency)
	|			THEN 0
	|		WHEN RegisteredRecordsDebitCredit.CurrencyDr = VALUE(Catalog.Currencies.EmptyRef)
	|			THEN 0
	|		WHEN NOT RegisteredRecordsDebitCredit.ComplexEntryDr
	|			THEN RegisteredRecordsDebitCredit.AmountOfMovementShaftDr
	|		WHEN RegisteredRecordsDebitCredit.CurrencyDr = &ManagementAccountingCurrency
	|			THEN RegisteredRecordsDebitCredit.SumManDr
	|		WHEN RegisteredRecordsDebitCredit.CurrencyDr = RegisteredRecordsDebitCredit.Organization.LocalAccountingCurrency
	|			THEN RegisteredRecordsDebitCredit.SumComplDr
	|		WHEN AmountsInDrCurrencies.RowID IS NULL
	|			THEN CAST(CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfManMovementDr <> 0
	|					THEN RegisteredRecordsDebitCredit.AmountOfMovementShaftDr * RegisteredRecordsDebitCredit.SumManDr / RegisteredRecordsDebitCredit.AmountOfManMovementDr
	|				WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr <> 0
	|					THEN RegisteredRecordsDebitCredit.AmountOfMovementShaftDr * RegisteredRecordsDebitCredit.SumComplDr / RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr
	|				ELSE 0
	|			END AS NUMBER(31, 2))
	|		WHEN RegisteredRecordsDebitCredit.VATActivityTypeDr IN (&TypesOfTaxationExcludingVAT)
	|		  OR RegisteredRecordsDebitCredit.VATActivityTypeCr IN (&TypesOfTaxationExcludingVAT)
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.RegisterNameCr IN (&VATRegisters)
	|					THEN 0
	|				WHEN AmountsInDrCurrencies.ARAPCurrency = AmountsInDrCurrencies.Currency
	|					THEN AmountsInDrCurrencies.AmountExcludingVAT + AmountsInDrCurrencies.VATAmount
	|				ELSE AmountsInDrCurrencies.AmountARAP
	|			END * CASE
	|				WHEN AmountsInDrCurrencies.AmountExcludingVAT < 0 OR AmountsInDrCurrencies.VATAmount < 0
	|					THEN -1
	|				ELSE 1
	|			END
	|		WHEN RegisteredRecordsDebitCredit.RegisterNameCr IN (&VATRegisters)
	|			THEN CASE
	|				WHEN AmountsInDrCurrencies.ARAPCurrency = AmountsInDrCurrencies.Currency
	|					THEN AmountsInDrCurrencies.VATAmount
	|				ELSE AmountsInDrCurrencies.AmountVATARAP
	|			END * CASE
	|				WHEN AmountsInDrCurrencies.VATAmount < 0
	|					THEN -1
	|				ELSE 1
	|			END
	|		ELSE CASE
	|			WHEN AmountsInDrCurrencies.ARAPCurrency = AmountsInDrCurrencies.Currency
	|				THEN AmountsInDrCurrencies.AmountExcludingVAT
	|			ELSE AmountsInDrCurrencies.AmountARAP - AmountsInDrCurrencies.AmountVATARAP
	|		END * CASE
	|			WHEN AmountsInDrCurrencies.AmountExcludingVAT < 0
	|				THEN -1
	|			ELSE 1
	|		END
	|	END AS SumCurrDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.SettingUpBusinessTransaction IN (&BusinessTransactionsWithoutAccountingInForeignCurrency)
	|			THEN 0
	|		WHEN RegisteredRecordsDebitCredit.CurrencyCr = VALUE(Catalog.Currencies.EmptyRef)
	|			THEN 0
	|		WHEN NOT RegisteredRecordsDebitCredit.ComplexEntryCr
	|			THEN RegisteredRecordsDebitCredit.AmountOfMovementCrShaft
	|		WHEN RegisteredRecordsDebitCredit.CurrencyCr = &ManagementAccountingCurrency
	|			THEN RegisteredRecordsDebitCredit.SumManCr
	|		WHEN RegisteredRecordsDebitCredit.CurrencyCr = RegisteredRecordsDebitCredit.Organization.LocalAccountingCurrency
	|			THEN RegisteredRecordsDebitCredit.SumComplCr
	|		WHEN AmountsInCrCurrencies.RowID IS NULL
	|			THEN CAST(CASE
	|				WHEN RegisteredRecordsDebitCredit.AmountOfManMovementCr <> 0
	|					THEN RegisteredRecordsDebitCredit.AmountOfMovementCrShaft * RegisteredRecordsDebitCredit.SumManCr / RegisteredRecordsDebitCredit.AmountOfManMovementCr
	|				WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr <> 0
	|					THEN RegisteredRecordsDebitCredit.AmountOfMovementCrShaft * RegisteredRecordsDebitCredit.SumComplCr / RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr
	|				ELSE 0
	|			END AS NUMBER(31, 2))
	|		WHEN RegisteredRecordsDebitCredit.VATActivityTypeCr IN (&TypesOfTaxationExcludingVAT)
	|		  OR RegisteredRecordsDebitCredit.VATActivityTypeDr IN (&TypesOfTaxationExcludingVAT)
	|			THEN CASE
	|				WHEN RegisteredRecordsDebitCredit.RegisterNameDr IN (&VATRegisters)
	|					THEN 0
	|				WHEN AmountsInCrCurrencies.ARAPCurrency = AmountsInCrCurrencies.Currency
	|					THEN AmountsInCrCurrencies.AmountExcludingVAT + AmountsInCrCurrencies.VATAmount
	|				ELSE AmountsInCrCurrencies.AmountARAP
	|			END * CASE
	|				WHEN AmountsInCrCurrencies.AmountExcludingVAT < 0 OR AmountsInCrCurrencies.VATAmount < 0
	|					THEN -1
	|				ELSE 1
	|			END
	|		WHEN RegisteredRecordsDebitCredit.RegisterNameDr IN (&VATRegisters)
	|			THEN CASE
	|				WHEN AmountsInCrCurrencies.ARAPCurrency = AmountsInCrCurrencies.Currency
	|					THEN AmountsInCrCurrencies.VATAmount
	|				ELSE AmountsInCrCurrencies.AmountVATARAP
	|			END * CASE
	|				WHEN AmountsInCrCurrencies.VATAmount < 0
	|					THEN -1
	|				ELSE 1
	|			END
	|		ELSE CASE
	|			WHEN AmountsInCrCurrencies.ARAPCurrency = AmountsInCrCurrencies.Currency
	|				THEN AmountsInCrCurrencies.AmountExcludingVAT
	|			ELSE AmountsInCrCurrencies.AmountARAP - AmountsInCrCurrencies.AmountVATARAP
	|		END * CASE
	|			WHEN AmountsInCrCurrencies.AmountExcludingVAT < 0
	|				THEN -1
	|			ELSE 1
	|		END
	|	END AS SumCurrCr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.AmountOfDrMovement = 0
	|			THEN FALSE
	|		WHEN NOT RegisteredRecordsDebitCredit.ComplexEntryDr
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereIsQuantityDistributionDr,
	|	CASE
	|		WHEN RegisteredRecordsDebitCredit.CrMotionCount = 0
	|			THEN FALSE
	|		WHEN NOT RegisteredRecordsDebitCredit.ComplexEntryCr
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereIsQuantityDistributionCr,
	|	CAST(CASE
	|		WHEN RegisteredRecordsDebitCredit.AmountOfDrMovement = 0
	|			THEN RegisteredRecordsDebitCredit.AmountOfDrMovement
	|		WHEN NOT RegisteredRecordsDebitCredit.ComplexEntryDr
	|			THEN RegisteredRecordsDebitCredit.AmountOfDrMovement
	|		WHEN RegisteredRecordsDebitCredit.AmountOfManMovementDr <> 0
	|			THEN RegisteredRecordsDebitCredit.AmountOfDrMovement * RegisteredRecordsDebitCredit.SumManDr / RegisteredRecordsDebitCredit.AmountOfManMovementDr
	|		WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr <> 0
	|			THEN RegisteredRecordsDebitCredit.AmountOfDrMovement * RegisteredRecordsDebitCredit.SumComplDr / RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr
	|		ELSE 0
	|	END AS NUMBER(15, 3)) AS CountDr,
	|	CAST(CASE
	|		WHEN RegisteredRecordsDebitCredit.CrMotionCount = 0
	|			THEN RegisteredRecordsDebitCredit.CrMotionCount
	|		WHEN NOT RegisteredRecordsDebitCredit.ComplexEntryCr
	|			THEN RegisteredRecordsDebitCredit.CrMotionCount
	|		WHEN RegisteredRecordsDebitCredit.AmountOfManMovementCr <> 0
	|			THEN RegisteredRecordsDebitCredit.CrMotionCount * RegisteredRecordsDebitCredit.SumManCr / RegisteredRecordsDebitCredit.AmountOfManMovementCr
	|		WHEN RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr <> 0
	|			THEN RegisteredRecordsDebitCredit.CrMotionCount * RegisteredRecordsDebitCredit.SumComplCr / RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr
	|		ELSE 0
	|	END AS NUMBER(15, 3)) AS CountCr
	|INTO TTDistributionOfUnbalancedAssets
	|FROM
	|	TTMovementDebitCredit AS RegisteredRecordsDebitCredit
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS AmountsInDrCurrencies
	|		ON RegisteredRecordsDebitCredit.Recorder = AmountsInDrCurrencies.Recorder
	|		 AND RegisteredRecordsDebitCredit.RowIDCr = AmountsInDrCurrencies.RowID
	|		 AND RegisteredRecordsDebitCredit.CurrencyDr = AmountsInDrCurrencies.ARAPCurrency
	|		 AND RegisteredRecordsDebitCredit.ComplexEntryDr
	|		 AND NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTDocumentsReplacingReverseWithReverse AS ReverseReplacementDocuments
	|			WHERE
	|				ReverseReplacementDocuments.Period = RegisteredRecordsDebitCredit.Period
	|				AND ReverseReplacementDocuments.Recorder = RegisteredRecordsDebitCredit.Recorder
	|				AND ReverseReplacementDocuments.FinRecordID = RegisteredRecordsDebitCredit.FinRecordID
	|				AND ReverseReplacementDocuments.Organization = RegisteredRecordsDebitCredit.Organization
	|			)
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS AmountsInCrCurrencies
	|		ON RegisteredRecordsDebitCredit.Recorder = AmountsInCrCurrencies.Recorder
	|		 AND RegisteredRecordsDebitCredit.RowIDDr = AmountsInCrCurrencies.RowID
	|		 AND RegisteredRecordsDebitCredit.CurrencyCr = AmountsInCrCurrencies.ARAPCurrency
	|		 AND RegisteredRecordsDebitCredit.ComplexEntryCr
	|		 AND NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTDocumentsReplacingReverseWithReverse AS ReverseReplacementDocuments
	|			WHERE
	|				ReverseReplacementDocuments.Period = RegisteredRecordsDebitCredit.Period
	|				AND ReverseReplacementDocuments.Recorder = RegisteredRecordsDebitCredit.Recorder
	|				AND ReverseReplacementDocuments.FinRecordID = RegisteredRecordsDebitCredit.FinRecordID
	|				AND ReverseReplacementDocuments.Organization = RegisteredRecordsDebitCredit.Organization
	|			)
	|INDEX BY
	|	LineNumber,
	|	RecNoDr,
	|	RecNoCr,
	|	ComplexRecordNumber
	|";
	
	QueriesTexts.Add(QueryText);

	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMovementDebitCredit");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTAmountsOfDocumentsInAccountingCurrencies");
	
	FinancialAccountingByBalanceSheetRegisterData.AddTableOfSumRoundingErrors(QueriesTexts,
		"TTErrorCorrectionSumsShaftDr", "DistributableAmountShaftDr", "SumCurrDr");
	FinancialAccountingByBalanceSheetRegisterData.AddTableOfSumRoundingErrors(QueriesTexts,
		"TTErrorCorrectionSumsShaftCr", "DistributableAmountOfCrShaft", "SumCurrCr");

	FinancialAccountingByBalanceSheetRegisterData.AddRoundingErrorTable(QueriesTexts,
		"TTErrorCorrectionOfDrQuantities", "DistributableAmountOfDr", "CountDr");
	FinancialAccountingByBalanceSheetRegisterData.AddRoundingErrorTable(QueriesTexts,
		"TTErrorCorrectionOfCrQuantities", "DistributableNumberOfCr", "CountCr");
	
	QueriesTexts.Add("
	|SELECT
	|	DistributionOfUnbalancedAssets.Period AS Period,
	|	DistributionOfUnbalancedAssets.LineNumber AS RecNo,
	|	DistributionOfUnbalancedAssets.RecNoDr AS RecNoDr,
	|	DistributionOfUnbalancedAssets.RecNoCr AS RecNoCr,
	|	DistributionOfUnbalancedAssets.RegisterNameDr AS RegisterNameDr,
	|	DistributionOfUnbalancedAssets.RegisterNameCr AS RegisterNameCr,
	|	DistributionOfUnbalancedAssets.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	DistributionOfUnbalancedAssets.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	DistributionOfUnbalancedAssets.Organization AS Organization,
	|	DistributionOfUnbalancedAssets.Recorder AS Recorder,
	|	DistributionOfUnbalancedAssets.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	DistributionOfUnbalancedAssets.AdditionalSetupOfHouseholdOperationsDr AS AdditionalSetupOfHouseholdOperationsDr,
	|	DistributionOfUnbalancedAssets.AdditionalSetupOfHouseholdOperationsCr AS AdditionalSetupOfHouseholdOperationsCr,
	|	DistributionOfUnbalancedAssets.FinRecordID AS FinRecordID,
	|	DistributionOfUnbalancedAssets.RowIDDr AS RowIDDr,
	|	DistributionOfUnbalancedAssets.RowIDCr AS RowIDCr,
	|	DistributionOfUnbalancedAssets.CurrencyDr AS CurrencyDr,
	|	DistributionOfUnbalancedAssets.CurrencyCr AS CurrencyCr,
	|	DistributionOfUnbalancedAssets.FactorDr AS FactorDr,
	|	DistributionOfUnbalancedAssets.FactorCr AS FactorCr,
	|	DistributionOfUnbalancedAssets.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	DistributionOfUnbalancedAssets.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	DistributionOfUnbalancedAssets.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	DistributionOfUnbalancedAssets.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	DistributionOfUnbalancedAssets.PropsStornoDr AS PropsStornoDr,
	|	DistributionOfUnbalancedAssets.PropsStornoCr AS PropsStornoCr,
	|	DistributionOfUnbalancedAssets.ComplexEntryDr AS ComplexEntryDr,
	|	DistributionOfUnbalancedAssets.ComplexEntryCr AS ComplexEntryCr,
	|	DistributionOfUnbalancedAssets.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	DistributionOfUnbalancedAssets.SumManDr AS SumManDr,
	|	DistributionOfUnbalancedAssets.SumManCr AS SumManCr,
	|	DistributionOfUnbalancedAssets.SumComplDr AS SumComplDr,
	|	DistributionOfUnbalancedAssets.SumComplCr AS SumComplCr,
	|	DistributionOfUnbalancedAssets.SumCurrDr + ISNULL(CorrectionOfErrorsInDrShaft.RoundingError, 0) AS SumCurrDr,
	|	DistributionOfUnbalancedAssets.SumCurrCr + ISNULL(CorrectionOfErrorsInCRShaft.RoundingError, 0) AS SumCurrCr,
	|	DistributionOfUnbalancedAssets.CountDr + ISNULL(CorrectionOfDrQuantityErrors.RoundingError, 0) AS CountDr,
	|	DistributionOfUnbalancedAssets.CountCr + ISNULL(CorrectionOfCrQuantityErrors.RoundingError, 0) AS CountCr
	|INTO TTMovementDebitCredit
	|FROM
	|	TTDistributionOfUnbalancedAssets AS DistributionOfUnbalancedAssets
	|	LEFT JOIN TTErrorCorrectionSumsShaftDr AS CorrectionOfErrorsInDrShaft
	|		ON DistributionOfUnbalancedAssets.RecNoDr = CorrectionOfErrorsInDrShaft.RecNoDr
	|		 AND DistributionOfUnbalancedAssets.LineNumber = CorrectionOfErrorsInDrShaft.LineNumber
	|	LEFT JOIN TTErrorCorrectionSumsShaftCr AS CorrectionOfErrorsInCRShaft
	|		ON DistributionOfUnbalancedAssets.RecNoCr = CorrectionOfErrorsInCRShaft.RecNoCr
	|		 AND DistributionOfUnbalancedAssets.LineNumber = CorrectionOfErrorsInCRShaft.LineNumber
	|	LEFT JOIN TTErrorCorrectionOfDrQuantities AS CorrectionOfDrQuantityErrors
	|		ON DistributionOfUnbalancedAssets.RecNoDr = CorrectionOfDrQuantityErrors.RecNoDr
	|		 AND DistributionOfUnbalancedAssets.LineNumber = CorrectionOfDrQuantityErrors.LineNumber
	|	LEFT JOIN TTErrorCorrectionOfCrQuantities AS CorrectionOfCrQuantityErrors
	|		ON DistributionOfUnbalancedAssets.RecNoCr = CorrectionOfCrQuantityErrors.RecNoCr
	|		 AND DistributionOfUnbalancedAssets.LineNumber = CorrectionOfCrQuantityErrors.LineNumber
	|INDEX BY
	|	RecNoDr,
	|	RecNoCr
	|");
	
	DeletedTemporaryTables = New Array();
	DeletedTemporaryTables.Add("TTDistributionOfUnbalancedAssets");
	DeletedTemporaryTables.Add("TTErrorCorrectionSumsShaftDr");
	DeletedTemporaryTables.Add("TTErrorCorrectionSumsShaftCr");
	DeletedTemporaryTables.Add("TTErrorCorrectionOfDrQuantities");
	DeletedTemporaryTables.Add("TTErrorCorrectionOfCrQuantities");

	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, DeletedTemporaryTables);
	
EndProcedure

Procedure CheckCorrespondenceErrors(DocumentsForProcessing_, Query, QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.RegisterNameDr AS RegisterNameDr,
	|	RegisterRecords.RegisterNameCr AS RegisterNameCr,
	|	RegisterRecords.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisterRecords.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisterRecords.Organization AS Organization,
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRecords.FinRecordID AS FinRecordID,
	|	RegisterRecords.SumManDr AS SumManDr,
	|	RegisterRecords.SumManCr AS SumManCr,
	|	RegisterRecords.SumComplDr AS SumComplDr,
	|	RegisterRecords.SumComplCr AS SumComplCr
	|INTO TTCorrespondenceErrors
	|FROM
	|	TTMovementDebitCredit AS RegisterRecords
	|WHERE
	|	RegisterRecords.RegisterNameDr = """"
	|	OR RegisterRecords.RegisterNameCr = """"
	|	OR RegisterRecords.FinRecordID = """"
	|	OR RegisterRecords.SumManDr <> RegisterRecords.SumManCr
	|	OR RegisterRecords.SumComplDr <> RegisterRecords.SumComplCr
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	SettingUpBusinessTransaction,
	|	Organization
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	CorrespondencesErrors.Period AS Period,
	|	CorrespondencesErrors.RegisterNameDr AS RegisterNameDr,
	|	CorrespondencesErrors.RegisterNameCr AS RegisterNameCr,
	|	ISNULL(OtherAssetsLiabilitiesDr.AssetRef, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) AS AssetAndLiabilityItemDr,
	|	ISNULL(OtherAssetsLiabilitiesCr.AssetRef, VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)) AS AssetAndLiabilityItemCr,
	|	CorrespondencesErrors.Organization AS Organization,
	|	CorrespondencesErrors.Recorder AS Recorder,
	|	CorrespondencesErrors.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	CorrespondencesErrors.FinRecordID AS FinRecordID,
	|	CorrespondencesErrors.SumManDr AS SumManDr,
	|	CorrespondencesErrors.SumManCr AS SumManCr,
	|	CorrespondencesErrors.SumComplDr AS SumComplDr,
	|	CorrespondencesErrors.SumComplCr AS SumComplCr
	|FROM
	|	TTCorrespondenceErrors AS CorrespondencesErrors
	|	LEFT JOIN AccumulationRegister.OtherAssetsAndLiabilitiesRecords AS OtherAssetsLiabilitiesDr
	|		ON CorrespondencesErrors.Period = OtherAssetsLiabilitiesDr.Period
	|		 AND CorrespondencesErrors.Recorder = OtherAssetsLiabilitiesDr.Recorder
	|		 AND CorrespondencesErrors.FinRecordID = OtherAssetsLiabilitiesDr.FinRecordID
	|		 AND CorrespondencesErrors.SettingUpBusinessTransaction = OtherAssetsLiabilitiesDr.BusinessTransactionSetting
	|		 AND CorrespondencesErrors.Organization = OtherAssetsLiabilitiesDr.Organization
	|		 AND OtherAssetsLiabilitiesDr.DebitCredit = CASE
	|			WHEN CorrespondencesErrors.ThisIsReverseTransactionDr
	|				THEN VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit)
	|			ELSE VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit)
	|		 END
	|	LEFT JOIN AccumulationRegister.OtherAssetsAndLiabilitiesRecords AS OtherAssetsLiabilitiesCr
	|		ON CorrespondencesErrors.Period = OtherAssetsLiabilitiesCr.Period
	|		 AND CorrespondencesErrors.Recorder = OtherAssetsLiabilitiesCr.Recorder
	|		 AND CorrespondencesErrors.FinRecordID = OtherAssetsLiabilitiesCr.FinRecordID
	|		 AND CorrespondencesErrors.SettingUpBusinessTransaction = OtherAssetsLiabilitiesCr.BusinessTransactionSetting
	|		 AND CorrespondencesErrors.Organization = OtherAssetsLiabilitiesCr.Organization
	|		 AND OtherAssetsLiabilitiesCr.DebitCredit = CASE
	|			WHEN CorrespondencesErrors.ThisIsReverseTransactionCr
	|				THEN VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit)
	|			ELSE VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit)
	|		 END
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	CorrespondencesErrors.Period AS Period,
	|	CorrespondencesErrors.Organization AS Organization,
	|	CorrespondencesErrors.Recorder AS Recorder
	|FROM
	|	TTCorrespondenceErrors AS CorrespondencesErrors
	|GROUP BY
	|	CorrespondencesErrors.Period,
	|	CorrespondencesErrors.Recorder,
	|	CorrespondencesErrors.Organization
	|");
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Results = Query.ExecuteBatch();
	QueriesTexts.Clear();
	
	AccumulationRegistersMetadata = Metadata.AccumulationRegisters;
	
	RegisterMetadata = AccumulationRegistersMetadata.ActualBudgetingData;
	
	Selection = Results[Results.UBound() - 1].Select();
	TransactionSelection_ = Results[Results.UBound()].Select();
	
	While TransactionSelection_.Next() Do
		EntriesErrors = New Array;
		
		TheStructureOfTheSearch = New Structure("Period,Organization,Recorder");
		FillPropertyValues(TheStructureOfTheSearch, TransactionSelection_);
		
		Selection.Reset();
		While Selection.FindNext(TheStructureOfTheSearch) Do
			
			If Not ValueIsFilled(Selection.FinRecordID) Then
				
				ErrorText = NStr("vi = 'Chưa điền tên định danh bản ghi tài chính vào %1';
								|ru = 'Не заполнен идентификатор фин.записи в %1';
								|en = 'Financial record ID is required in %1'; fa = 'Financial record ID is required in %1';
								|it = 'Identificativo di registrazione finanziaria in %1 non compilato';
								|pl = 'Nie wypełniono identyfikatora wpisu finansowego w %1';
								|tr = '%1''de mali kayıt kimliği doldurulmadı'");
				If Not ValueIsFilled(Selection.RegisterNameDr)
					Or Selection.RegisterNameDr = FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
					ErrorText = StrTemplate(ErrorText, StrTemplate(NStr("vi = 'biểu ghi ""%1""';
																		|ru = 'регистре ""%1""';
																		|en = 'the ""%1"" register'; fa = 'the ""%1"" register';
																		|it = 'registro ""%1""';
																		|pl = 'rejestrze ""%1""';
																		|tr = '""%1"" kaydında'"),
						Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameCr])));
				ElsIf Not ValueIsFilled(Selection.RegisterNameCr)
					Or Selection.RegisterNameCr =  FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
					ErrorText = StrTemplate(ErrorText, StrTemplate(NStr("vi = 'biểu ghi ""%1""';
																		|ru = 'регистре ""%1""';
																		|en = 'the ""%1"" register'; fa = 'the ""%1"" register';
																		|it = 'registro ""%1""';
																		|pl = 'rejestrze ""%1""';
																		|tr = '""%1"" kaydında'"),
						Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameDr])));
				ElsIf Selection.RegisterNameDr = Selection.RegisterNameCr Then
					ErrorText = StrTemplate(ErrorText, StrTemplate(NStr("vi = 'biểu ghi ""%1""';
																		|ru = 'регистре ""%1""';
																		|en = 'the ""%1"" register'; fa = 'the ""%1"" register';
																		|it = 'registro ""%1""';
																		|pl = 'rejestrze ""%1""';
																		|tr = '""%1"" kaydında'"),
						Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameDr])));
				Else
					ErrorText = StrTemplate(ErrorText, StrTemplate(NStr("vi = 'biểu ghi ""%1"" và ""%2""';
																		|ru = 'регистрах ""%1"" и ""%2""';
																		|en = 'the ""%1"" and ""%2"" registers'; fa = 'the ""%1"" and ""%2"" registers';
																		|it = 'registri ""%1"" e ""%2""';
																		|pl = 'rejestrach ""%1"" i ""%2""';
																		|tr = '""%1"" ve ""%2"" kayıtlarında'"),
						Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameDr]),
						Common.ObjectPresentation(AccumulationRegistersMetadata[Selection.RegisterNameCr])));
				EndIf;
				EntriesErrors.Add(ErrorText);
				
			ElsIf Not ValueIsFilled(Selection.RegisterNameDr) Then
				
				ErrorText = StrTemplate(NStr(
					"vi = 'Không tìm thấy đối ứng cho bản ghi của biểu ghi ""%1"" với tên định danh %2';
					|ru = 'Не найдена корреспонденция для записи регистра ""%1"" с идентификатором %2';
					|en = 'Correspondence for the ""%1"" register record with the %2 ID is not found'; fa = 'Correspondence for the ""%1"" register record with the %2 ID is not found';
					|it = 'Corrispondenza per la registrazione del registro ""%1"" con identificativo %2 non trovata';
					|pl = 'Nie znaleziono korespondencji dla wpisu rejestru ""%1"" z identyfikatorem %2';
					|tr = '%2 kimlikli ''""%1"" kayıt girişi için yazışma bulunamadı'",
					Common.DefaultLanguageCode()), Common.ObjectPresentation(
					AccumulationRegistersMetadata[Selection.RegisterNameCr]), Selection.FinRecordID);
				EntriesErrors.Add(ErrorText);
				
			ElsIf Not ValueIsFilled(Selection.RegisterNameCr) Then
				
				ErrorText = StrTemplate(NStr(
					"vi = 'Không tìm thấy đối ứng cho bản ghi của biểu ghi ""%1"" với tên định danh %2';
					|ru = 'Не найдена корреспонденция для записи регистра ""%1"" с идентификатором %2';
					|en = 'Correspondence for the ""%1"" register record with the %2 ID is not found'; fa = 'Correspondence for the ""%1"" register record with the %2 ID is not found';
					|it = 'Corrispondenza per la registrazione del registro ""%1"" con identificativo %2 non trovata';
					|pl = 'Nie znaleziono korespondencji dla wpisu rejestru ""%1"" z identyfikatorem %2';
					|tr = '%2 kimlikli ''""%1"" kayıt girişi için yazışma bulunamadı'",
					Common.DefaultLanguageCode()), Common.ObjectPresentation(
					AccumulationRegistersMetadata[Selection.RegisterNameDr]), Selection.FinRecordID);
				EntriesErrors.Add(ErrorText);
				
			Else
				
				If Selection.SumManDr <> Selection.SumManCr Then
					If Selection.RegisterNameDr
						= FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
						ErrorText = StrTemplate(NStr(
							"vi = 'Số tiền kế toán quản trị bên nợ và bên có theo tên định danh ""%1"" không trùng nhau';
							|ru = 'Не совпадают суммы управленческого учета дебета и кредита по идентификатору ""%1""';
							|en = 'Debit and credit amounts in management accounting for ID %1 do not match'; fa = 'Debit and credit amounts in management accounting for ID %1 do not match';
							|it = 'Не совпадают суммы управленческого учета дебета и кредита по идентификатору ""%1""';
							|pl = 'Debit and credit amounts in management accounting for ID %1 do not match';
							|tr = 'Yönetim muhasebesi borç ve alacak tutarları ""%1"" kimliğine göre eşleşmiyor'",
							Common.DefaultLanguageCode()), Selection.FinRecordID);
					Else
						ErrorText = StrTemplate(NStr(
							"vi = 'Số tiền kế toán quản trị các bản ghi của biểu ghi ""%1"" và ""%2"" có tên định danh %3 không trùng nhau';
							|ru = 'Не совпадают суммы управленческого учета записей регистров ""%1"" и ""%2"" с идентификатором %3';
							|en = 'The amounts of management accounting of the ""%1"" and ""%2"" register records with the %3 ID do not match'; fa = 'The amounts of management accounting of the ""%1"" and ""%2"" register records with the %3 ID do not match';
							|it = 'Gli importi in contabilità gestionale delle registrazioni dei registri ""%1"" e ""%2"" non corrispondono all''identificativo %3';
							|pl = 'Różnią się wartości ewidencji zarządczej wpisów rejestrów ""%1"" i ""%2"" i identyfikatora %3';
							|tr = '""%1''"" ve ""%2"" genel muhasebe girişlerinin yönetim muhasebesi tutarları, %3 kimliğiyle eşleşmiyor'",
							Common.DefaultLanguageCode()), Common.ObjectPresentation(
							AccumulationRegistersMetadata[Selection.RegisterNameDr]), Common.ObjectPresentation(
							AccumulationRegistersMetadata[Selection.RegisterNameCr]), Selection.FinRecordID);
					EndIf;
					EntriesErrors.Add(ErrorText);
				EndIf;

				If Selection.SumComplDr <> Selection.SumComplCr Then
					If Selection.RegisterNameDr
						= FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects() Then
						ErrorText = StrTemplate(NStr(
							"vi = 'Số tiền kế toán quản trị bên nợ và bên có theo tên định danh ""%1"" không trùng nhau';
							|ru = 'Не совпадают суммы регламентированного учета дебета и кредита по идентификатору ""%1""';
							|en = 'Debit and credit amounts in local accounting for ID %1 do not match'; fa = 'Debit and credit amounts in local accounting for ID %1 do not match';
							|it = 'Не совпадают суммы регламентированного учета дебета и кредита по идентификатору ""%1""';
							|pl = 'Debit and credit amounts in local accounting for ID %1 do not match';
							|tr = 'Yerel muhasebe borç ve alacak tutarları ""%1"" kimliğine göre eşleşmiyor'",
							Common.DefaultLanguageCode()), Selection.FinRecordID);
					Else
						ErrorText = StrTemplate(NStr(
							"vi = 'Số tiền kế toán quản trị các bản ghi của biểu ghi ""%1"" và ""%2"" với tên định danh %3 không trùng nhau';
							|ru = 'Не совпадают суммы регламентированного учета записей регистров ""%1"" и ""%2"" с идентификатором %3';
							|en = 'The amounts of local accounting of the ""%1"" and ""%2"" register records with the %3 ID do not match'; fa = 'The amounts of local accounting of the ""%1"" and ""%2"" register records with the %3 ID do not match';
							|it = 'Gli importi in contabilità regolamentata delle registrazioni dei registri ""%1"" e ""%2"" non corrispondono all''identificativo %3';
							|pl = 'Różnią się wartości ewidencji reglamentowanej wpisów rejestrów ""%1"" i ""%2"" i identyfikatora %3';
							|tr = '""%1''"" ve ""%2"" genel muhasebe girişlerinin yerel muhasebesi tutarları, %3 kimliğiyle eşleşmiyor'",
							Common.DefaultLanguageCode()), Common.ObjectPresentation(
							AccumulationRegistersMetadata[Selection.RegisterNameDr]), Common.ObjectPresentation(
							AccumulationRegistersMetadata[Selection.RegisterNameCr]), Selection.FinRecordID);
					EndIf;
					EntriesErrors.Add(ErrorText);
				EndIf;
			EndIf;
			
		EndDo;
		
		If EntriesErrors.Count() > 0 Then
			ErrorText = "";
			EntriesErrors = CommonClientServer.CollapseArray(EntriesErrors);
			For Each TransactionError In EntriesErrors Do
				ErrorText = ErrorText + ?(IsBlankString(ErrorText), "", Chars.LF) + TransactionError;
			EndDo;
			DocumentLines = DocumentsForProcessing_.FindRows(New Structure("Document", TransactionSelection_.Recorder));
			For Each LineDocument In DocumentLines Do
				FillPropertyValues(LineDocument, TransactionSelection_);
				LineDocument.Error = True;
				LineDocument.Comment = ErrorText;
			EndDo;
		EndIf;
		
	EndDo;
	
	QueriesTexts.Add("
	|SELECT
	|	CorrespondencesErrors.Period AS Period,
	|	CorrespondencesErrors.Organization AS Organization,
	|	CorrespondencesErrors.Recorder AS Recorder
	|INTO TTLoggersWithErrors
	|FROM
	|	TTCorrespondenceErrors AS CorrespondencesErrors
	|GROUP BY
	|	CorrespondencesErrors.Period,
	|	CorrespondencesErrors.Recorder,
	|	CorrespondencesErrors.Organization
	|INDEX BY
	|	Period,
	|	Recorder,
	|	Organization
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCorrespondenceErrors");

	QueriesTexts.Add("
	|SELECT
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.RegisterNameDr AS RegisterNameDr,
	|	RegisterRecords.RegisterNameCr AS RegisterNameCr,
	|	RegisterRecords.Organization AS Organization,
	|	RegisterRecords.Recorder AS Recorder,
	|	CASE
	|		WHEN RegisterRecords.AdditionalSetupOfHouseholdOperationsDr = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			AND RegisterRecords.AdditionalSetupOfHouseholdOperationsCr = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			AND (RegisterRecords.FactorDr = VALUE(Enum.IndicatorsOfAnalyticalRegisters.VATAmount)
	|			OR RegisterRecords.FactorCr = VALUE(Enum.IndicatorsOfAnalyticalRegisters.VATAmount))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|		ELSE RegisterRecords.SettingUpBusinessTransaction
	|	END AS SettingUpBusinessTransaction,
	|	CASE
	|		WHEN RegisterRecords.AdditionalSetupOfHouseholdOperationsDr = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN RegisterRecords.AdditionalSetupOfHouseholdOperationsCr
	|		WHEN RegisterRecords.AdditionalSetupOfHouseholdOperationsCr = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|			THEN RegisterRecords.AdditionalSetupOfHouseholdOperationsDr
	|		WHEN RegisterRecords.AdditionalSetupOfHouseholdOperationsDr <> RegisterRecords.SettingUpBusinessTransaction
	|			THEN CASE
	|				WHEN RegisterRecords.FactorDr = VALUE(Enum.IndicatorsOfAnalyticalRegisters.VATAmount)
	|					THEN RegisterRecords.AdditionalSetupOfHouseholdOperationsCr
	|				ELSE RegisterRecords.AdditionalSetupOfHouseholdOperationsDr
	|			END
	|		ELSE RegisterRecords.AdditionalSetupOfHouseholdOperationsCr
	|	END AS AdditionalSetupOfHouseholdOperations,
	|	RegisterRecords.FinRecordID AS FinRecordID,
	|	RegisterRecords.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisterRecords.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisterRecords.ThisIsReverseTransactionDr OR RegisterRecords.ThisIsReverseTransactionCr AS InvertEntriy,
	|	RegisterRecords.RowIDDr AS RowIDDr,
	|	RegisterRecords.RowIDCr AS RowIDCr,
	|	RegisterRecords.CurrencyDr AS CurrencyDr,
	|	RegisterRecords.CurrencyCr AS CurrencyCr,
	|	NOT RegisterRecords.CurrencyDr IS NULL AS Currency1Dr,
	|	NOT RegisterRecords.CurrencyCr IS NULL AS Currency1Cr,
	|	RegisterRecords.FactorDr AS FactorDr,
	|	RegisterRecords.FactorCr AS FactorCr,
	|	RegisterRecords.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisterRecords.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisterRecords.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisterRecords.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisterRecords.ComplexEntryDr AS ComplexEntryDr,
	|	RegisterRecords.ComplexEntryCr AS ComplexEntryCr,
	|	RegisterRecords.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisterRecords.SumManDr AS SumMan,
	|	RegisterRecords.SumComplDr AS SumCompl,
	|	RegisterRecords.SumCurrDr AS SumCurrDr,
	|	RegisterRecords.SumCurrCr AS SumCurrCr,
	|	RegisterRecords.CountDr AS CountDr,
	|	RegisterRecords.CountCr AS CountCr
	|INTO TTMovement
	|FROM
	|	TTMovementDebitCredit AS RegisterRecords
	|WHERE
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTLoggersWithErrors AS LoggersWithErrors
	|		WHERE
	|			LoggersWithErrors.Period = RegisterRecords.Period
	|			AND LoggersWithErrors.Recorder = RegisterRecords.Recorder
	|			AND LoggersWithErrors.Organization = RegisterRecords.Organization
	|		)");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMovementDebitCredit");

EndProcedure

Procedure ProcessDocumentCache(Query, QueriesTexts, IndexOffset)
	
	IndexOffset = IndexOffset + 2;
	If Query.TempTablesManager.Tables.Find("DocumentCache") <> Undefined Then
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "DocumentCache");
		IndexOffset = IndexOffset + 1;
	EndIf;
	
	QueriesTexts.Add("
	|SELECT DISTINCT
	|	MovementCache.Recorder,
	|	MovementCache.Period
	|INTO DocumentCache
	|FROM
	|	MovementCache AS MovementCache
	|INDEX BY
	|	Recorder,
	|	Period");
	If Query.Parameters.InitialTemporaryTables.Find("DocumentCache") = Undefined Then
		Query.Parameters.InitialTemporaryTables.Add("DocumentCache");
	EndIf;
	
	QueriesTexts.Add("
	|SELECT
	|	DocumentsToBeReflected.Recorder AS Document
	|FROM
	|	DocumentsToBeReflected AS DocumentsToBeReflected
	|WHERE
	|	&BeginOfPeriod = DATETIME(1, 1, 1)
	|	AND &EndOfPeriod = DATETIME(3999, 12, 31, 23, 59, 59)
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					DocumentCache AS DocumentCache
	|				WHERE
	|					DocumentCache.Recorder = DocumentsToBeReflected.Recorder)
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TTLoggersWithErrors AS TTLoggersWithErrors
	|				WHERE
	|					TTLoggersWithErrors.Recorder = DocumentsToBeReflected.Recorder)");
	
EndProcedure

Procedure ProcessRegisterCorrespondencesAndPutThemInCache(Query, QueriesTexts)
	
	If QueriesTexts.Count() > 0 Then
		Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		Query.Execute();
		QueriesTexts.Clear();
	EndIf;
	
	TTManagerTables = Query.TempTablesManager.Tables;
	
	If TTManagerTables.Find("TTMovement") <> Undefined Then
		
		If TTManagerTables.Find("MovementCache") <> Undefined Then
			
			QueriesTexts.Add("
			|SELECT
			|	*
			|INTO NewCacheOfRegisteredRecords
			|FROM
			|	TTMovement
			|
			|UNION ALL
			|
			|SELECT
			|	*
			|FROM
			|	MovementCache");
			
			FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "MovementCache");
			
			QueriesTexts.Add("
			|SELECT
			|	*
			|INTO MovementCache
			|FROM
			|	NewCacheOfRegisteredRecords
			|INDEX BY
			|	Recorder,
			|	Period");
			
			FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "NewCacheOfRegisteredRecords");
			
		Else
			QueriesTexts.Add("
			|SELECT
			|	*
			|INTO MovementCache
			|FROM
			|	TTMovement
			|INDEX BY
			|	Recorder,
			|	Period");
		EndIf;
		
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMovement");
		
		If Query.Parameters.InitialTemporaryTables.Find("MovementCache") = Undefined Then
			Query.Parameters.InitialTemporaryTables.Add("MovementCache");
		EndIf;
		
	EndIf;
	
	QueriesTexts.Add("
	|SELECT
	|	*
	|INTO TTOfRegisteredRecordsWithHouseholdOfOperations
	|FROM
	|	MovementCache AS MovementCache
	|WHERE
	|	MovementCache.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				DocumentsForProcessing_ AS DocumentsForProcessing_
	|			WHERE
	|				DocumentsForProcessing_.Recorder = MovementCache.Recorder)
	|
	|INDEX BY
	|	Period,
	|	Recorder,
	|	Organization,
	|	FinRecordID,
	|	RowIDDr,
	|	RowIDCr
	|	");
	
	QueriesTexts.Add("
	|SELECT
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.RegisterNameDr AS RegisterNameDr,
	|	RegisterRecords.RegisterNameCr AS RegisterNameCr,
	|	RegisterRecords.Organization AS Organization,
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRecords.AdditionalSetupOfHouseholdOperations AS AdditionalSetupOfHouseholdOperations,
	|	RegisterRecords.FinRecordID AS FinRecordID,
	|	RegisterRecords.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisterRecords.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisterRecords.ThisIsReverseTransactionDr
	|		OR RegisterRecords.ThisIsReverseTransactionCr AS InvertEntriy,
	|	RegisterRecords.RowIDDr AS RowIDDr,
	|	RegisterRecords.RowIDCr AS RowIDCr,
	|	RegisterRecords.CurrencyDr AS CurrencyDr,
	|	RegisterRecords.CurrencyCr AS CurrencyCr,
	|	NOT RegisterRecords.CurrencyDr IS NULL AS Currency1Dr,
	|	NOT RegisterRecords.CurrencyCr IS NULL AS Currency1Cr,
	|	RegisterRecords.FactorDr AS FactorDr,
	|	RegisterRecords.FactorCr AS FactorCr,
	|	RegisterRecords.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisterRecords.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisterRecords.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisterRecords.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisterRecords.ComplexEntryDr AS ComplexEntryDr,
	|	RegisterRecords.ComplexEntryCr AS ComplexEntryCr,
	|	RegisterRecords.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisterRecords.SumMan AS SumMan,
	|	RegisterRecords.SumCompl AS SumCompl,
	|	RegisterRecords.SumCurrDr AS SumCurrDr,
	|	RegisterRecords.SumCurrCr AS SumCurrCr,
	|	RegisterRecords.CountDr AS CountDr,
	|	RegisterRecords.CountCr AS CountCr,
	|	RegisterRecords.CountDr <> 0 AS QuantitativeDr,
	|	RegisterRecords.CountCr <> 0 AS QuantitativeCr
	|INTO TTMovement
	|FROM
	|	TTOfRegisteredRecordsWithHouseholdOfOperations AS RegisterRecords
	|WHERE
	|	(NOT RegisterRecords.SettingUpBusinessTransaction IN (&SettingsOfHouseholdOfOperationsForReplacement)
	|			OR &SettingUpBusinessTransaction IN (&SettingsOfHouseholdOfOperationsForReplacement))
	|
	|UNION ALL
	|
	|SELECT
	|	RegisterRecords.Period,
	|	RegisterRecords.RegisterNameDr,
	|	RegisterRecords.RegisterNameCr,
	|	RegisterRecords.Organization,
	|	RegisterRecords.Recorder,
	|	RegisterRecords.SettingUpBusinessTransaction,
	|	RegisteredRecordsWithHouseholdOFOperations.AdditionalSetupOfHouseholdOperations,
	|	RegisterRecords.FinRecordID,
	|	RegisterRecords.ThisIsReverseTransactionDr,
	|	RegisterRecords.ThisIsReverseTransactionCr,
	|	RegisteredRecordsWithHouseholdOFOperations.ThisIsReverseTransactionDr
	|		OR RegisteredRecordsWithHouseholdOFOperations.ThisIsReverseTransactionCr,
	|	RegisterRecords.RowIDDr,
	|	RegisterRecords.RowIDCr,
	|	RegisterRecords.CurrencyDr,
	|	RegisterRecords.CurrencyCr,
	|	NOT RegisterRecords.CurrencyDr IS NULL,
	|	NOT RegisterRecords.CurrencyCr IS NULL,
	|	RegisterRecords.FactorDr,
	|	RegisterRecords.FactorCr,
	|	RegisterRecords.AmountOfManMovementDr,
	|	RegisterRecords.AmountOfManMovementCr,
	|	RegisterRecords.AmountOfLocalTrafficDr,
	|	RegisterRecords.AmountOfLocalTrafficCr,
	|	RegisterRecords.ComplexEntryDr,
	|	RegisterRecords.ComplexEntryCr,
	|	RegisterRecords.TakeIntoAccountBusinessTransaction,
	|	RegisterRecords.SumMan,
	|	RegisterRecords.SumCompl,
	|	RegisterRecords.SumCurrDr,
	|	RegisterRecords.SumCurrCr,
	|	RegisterRecords.CountDr,
	|	RegisterRecords.CountCr,
	|	RegisterRecords.CountDr <> 0,
	|	RegisterRecords.CountCr <> 0
	|FROM
	|	TTOfRegisteredRecordsWithHouseholdOfOperations AS RegisterRecords
	|		INNER JOIN TTOfRegisteredRecordsWithHouseholdOfOperations AS RegisteredRecordsWithHouseholdOFOperations
	|		ON RegisterRecords.Period = RegisteredRecordsWithHouseholdOFOperations.Period
	|			AND RegisterRecords.Recorder = RegisteredRecordsWithHouseholdOFOperations.Recorder
	|			AND RegisterRecords.Organization = RegisteredRecordsWithHouseholdOFOperations.Organization
	|			AND RegisterRecords.FinRecordID = RegisteredRecordsWithHouseholdOFOperations.FinRecordID
	|			AND RegisterRecords.RowIDDr = RegisteredRecordsWithHouseholdOFOperations.RowIDDr
	|			AND RegisterRecords.RowIDCr = RegisteredRecordsWithHouseholdOFOperations.RowIDCr
	|			AND RegisterRecords.SettingUpBusinessTransaction <> RegisteredRecordsWithHouseholdOFOperations.SettingUpBusinessTransaction
	|WHERE
	|	RegisterRecords.SettingUpBusinessTransaction IN(&SettingsOfHouseholdOfOperationsForReplacement)
	|	AND RegisterRecords.SettingUpBusinessTransaction <> &SettingUpBusinessTransaction
	|
	|INDEX BY
	|	AdditionalSetupOfHouseholdOperations");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTOfRegisteredRecordsWithHouseholdOfOperations");
	
EndProcedure

Procedure CreateTableOfRegisteredRecordsOfServiceAccountingObjects(Query, QueriesTexts)
	
	QueryText = "
	|SELECT
	|	TRUE AS ThisIsDebit,
	|	FALSE AS ThisIsLoan,
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.RegisterNameDr AS RegisterName,
	|	RegisterRecords.FactorDr AS Factor,
	|	RegisterRecords.ThisIsReverseTransactionDr AS ThisIsReverseTransaction,
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.Organization AS Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	RegisterRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRecords.FinRecordID AS FinRecordID,
	|	RegisterRecords.RowIDDr AS RowID,
	|	RegisterRecords.CurrencyDr AS Currency,
	|	SUM(RegisterRecords.SumMan) AS SumMan,
	|	SUM(RegisterRecords.SumCompl) AS SumCompl,
	|	SUM(RegisterRecords.SumCurrDr) AS SumCurr,
	|	SUM(RegisterRecords.CountDr) AS Count
	|INTO PlacementTable
	|FROM
	|	TTMovement AS RegisterRecords
	|WHERE
	|	RegisterRecords.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|GROUP BY
	|	RegisterRecords.Period,
	|	RegisterRecords.Recorder,
	|	RegisterRecords.FinRecordID,
	|	RegisterRecords.RowIDDr,
	|	RegisterRecords.FactorDr,
	|	RegisterRecords.RegisterNameDr,
	|	RegisterRecords.ThisIsReverseTransactionDr,
	|	RegisterRecords.Organization,
	|	RegisterRecords.SettingUpBusinessTransaction,
	|	RegisterRecords.CurrencyDr
	|
	|UNION ALL
	|
	|SELECT
	|	FALSE AS ThisIsDebit,
	|	TRUE AS ThisIsLoan,
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.RegisterNameCr AS RegisterName,
	|	RegisterRecords.FactorCr AS Factor,
	|	RegisterRecords.ThisIsReverseTransactionCr AS ThisIsReverseTransaction,
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.Organization AS Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	RegisterRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRecords.FinRecordID AS FinRecordID,
	|	RegisterRecords.RowIDCr AS RowID,
	|	RegisterRecords.CurrencyCr AS Currency,
	|	SUM(RegisterRecords.SumMan) AS SumMan,
	|	SUM(RegisterRecords.SumCompl) AS SumCompl,
	|	SUM(RegisterRecords.SumCurrCr) AS SumCurr,
	|	SUM(RegisterRecords.CountCr) AS Count
	|FROM
	|	TTMovement AS RegisterRecords
	|WHERE
	|	RegisterRecords.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects
	|GROUP BY
	|	RegisterRecords.Period,
	|	RegisterRecords.Recorder,
	|	RegisterRecords.FinRecordID,
	|	RegisterRecords.RowIDCr,
	|	RegisterRecords.FactorCr,
	|	RegisterRecords.RegisterNameCr,
	|	RegisterRecords.ThisIsReverseTransactionCr,
	|	RegisterRecords.Organization,
	|	RegisterRecords.SettingUpBusinessTransaction,
	|	RegisterRecords.CurrencyCr
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	RowID,
	|	Factor,
	|	Organization,
	|	SettingUpBusinessTransaction
	|";
	
	QueryText = StrReplace(QueryText, "PlacementTable", "tt"
		+ FinancialAccountingByBalanceSheetRegisterData.NameOfRegisterOfServiceAccountingObjects());
	QueriesTexts.Add(QueryText);
	
EndProcedure

Procedure GenerateCorrespondenceAnalyticsRequestsAndPutThemInCache(Query, QueriesTexts, RegisterRequestsTexts, IndexOffset)
	
	DeletedTemporaryTables = New Array();
	IndexOfResultOfAnalyticsQuery = 0;
	
	If RegisterRequestsTexts <> Undefined Then
		
		SelectionFieldsToDelete = StrSplit("OfficialTypeOfActivityVAT,PropsStorno,AdditionalSetupOfHouseholdOperations", ",");
		ReverseIndexFields = StrSplit("Period,Recorder,FinRecordID,Organization", ",");
	
		CreateTableOfRegisteredRecordsOfServiceAccountingObjects(Query, QueriesTexts);
		
		QueriesTexts.Add("
		|SELECT
		|	RegisterRecords.RegisterName AS RegisterName
		|FROM
		|	(SELECT
		|		RegisterRecords.RegisterNameDr AS RegisterName
		|	FROM
		|		TTMovement AS RegisterRecords
		|	
		|	UNION ALL
		|	
		|	SELECT RegisterRecords.RegisterNameCr AS RegisterName
		|	FROM
		|		TTMovement AS RegisterRecords) AS RegisterRecords
		|
		|GROUP BY
		|	RegisterRecords.RegisterName");
		
	EndIf;
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	QueriesTexts.Clear();
	Results = Query.ExecuteBatch();
	
	If RegisterRequestsTexts <> Undefined Then
		
		FetchingRegisterName = Results[Results.Count()-1].Select();
		While FetchingRegisterName.Next() Do
			
			RegisterTableName = FetchingRegisterName.RegisterName;
			NameOfRegisterCacheTable = StrReplace("AnalyticsCache_RegisterName", "RegisterName", RegisterTableName);
			TableNameNewRegisterCache = StrReplace("NewAnalyticsCache_RegisterName", "RegisterName", RegisterTableName);
			If RegisterTableName = Query.Parameters.NameOfRegisterOfServiceAccountingObjects Then
				RegisterTableName = "";
				NameOfRegisterCacheTable = "";
				TableNameNewRegisterCache = "";
			EndIf;
			
			RowsOfAnalyticsFields = New Array;
			RowsOfAnalyticsGroups = New Array;
			
			AddRegisterAnalyticsFields(RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterTableName);
			
			TemporaryRegisterTableName = "tt" + FetchingRegisterName.RegisterName;
			
			If Query.TempTablesManager.Tables.Find(TemporaryRegisterTableName) = Undefined Then
				RegisterRequestText = RegisterRequestsTexts[RegisterTableName];
				AddAnalyticsFieldsToQueryText(RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterRequestText);
				
				If Query.Parameters.ReverseToReverseReplacementRegisters.Find(RegisterTableName) <> Undefined Then
					FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(RegisterRequestText,
						SelectionFieldsToDelete, , TemporaryRegisterTableName);
					QueriesTexts.Add(RegisterRequestText);
					DeletedTemporaryTables.Add(TemporaryRegisterTableName);
					IndexOfResultOfAnalyticsQuery = IndexOfResultOfAnalyticsQuery + 1;
					IndexOffset = IndexOffset + 1;
					
					RegisterRequestText = TextOfAnalyticsSampleFromTemporaryTable(True);
					RegisterRequestText = StrReplace(RegisterRequestText, "&DataSource", TemporaryRegisterTableName);
				Else
					FinancialAccountingByBalanceSheetRegisterData.ChangeSelectionFields(RegisterRequestText, SelectionFieldsToDelete, , "NameOfRegisterCacheTable");
				EndIf;
				
				If Query.Parameters.RestoreCalculationsForStorno
					And Query.Parameters.RegistersOfRecoveryOfCalculationsOnStorno.Find(RegisterTableName) <> Undefined Then
					AddTableForRestoringCalculationsForStorno(RegisterRequestText, RegisterTableName);
				EndIf;
			Else
				RegisterRequestText = TextOfAnalyticsSampleFromTemporaryTable();
				If IsBlankString(RegisterTableName) Then
					RegisterRequestText = StrReplace(RegisterRequestText, "INTO NameOfRegisterCacheTable", "");
					AddCustomAnalyticsFieldsToQueryText(RowsOfAnalyticsFields, RowsOfAnalyticsGroups);
				EndIf;
				RegisterRequestText = StrReplace(RegisterRequestText, "&DataSource", TemporaryRegisterTableName);
			EndIf;
			
			AddAnalyticsFieldsToQueryText(RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterRequestText);
			
			If Not IsBlankString(RegisterTableName) Then
				If Query.TempTablesManager.Tables.Find(NameOfRegisterCacheTable) <> Undefined Then
					QueriesTexts.Add(StrReplace(RegisterRequestText, "NameOfRegisterCacheTable", TableNameNewRegisterCache)
						+ TMCommonUse.QuerySeparatorInJoin() + StrReplace("
						|SELECT
						|	*
						|FROM
						|	NameOfRegisterCacheTable", "NameOfRegisterCacheTable", NameOfRegisterCacheTable));
					FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, NameOfRegisterCacheTable);
					QueryText = "
					|SELECT
					|	*
					|INTO NameOfRegisterCacheTable
					|FROM
					|	TableNameNewRegisterCache
					|INDEX BY
					|	Recorder,
					|	Period";
					QueryText = StrReplace(QueryText, "NameOfRegisterCacheTable", NameOfRegisterCacheTable);
					QueryText = StrReplace(QueryText, "TableNameNewRegisterCache", TableNameNewRegisterCache);
					QueriesTexts.Add(QueryText);
					FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, TableNameNewRegisterCache);
					IndexOfResultOfAnalyticsQuery = IndexOfResultOfAnalyticsQuery + 4;
				Else
					IndexBy = "INDEX BY"; //@Query-part
					If StrFind(RegisterRequestText, IndexBy, SearchDirection.FromEnd) = 0 Then
						RegisterRequestText = RegisterRequestText + "
						|INDEX BY
						|	Recorder,
						|	Period";
					EndIf;
					QueriesTexts.Add(StrReplace(RegisterRequestText, "NameOfRegisterCacheTable", NameOfRegisterCacheTable));
					IndexOfResultOfAnalyticsQuery = IndexOfResultOfAnalyticsQuery + 1;
				EndIf;
			EndIf;
			
			If Not IsBlankString(NameOfRegisterCacheTable) Then
				RegisterRequestText = StrReplace("
				|SELECT
				|	*
				|FROM
				|	NameOfRegisterCacheTable AS NameOfRegisterCacheTable
				|WHERE
				|	NameOfRegisterCacheTable.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
				|	AND TRUE IN
				|			(SELECT TOP 1
				|				TRUE
				|			FROM
				|				DocumentsForProcessing_ AS DocumentsForProcessing_
				|			WHERE
				|				DocumentsForProcessing_.Recorder = NameOfRegisterCacheTable.Recorder)", "NameOfRegisterCacheTable", NameOfRegisterCacheTable);
				If Query.Parameters.InitialTemporaryTables.Find(NameOfRegisterCacheTable) = Undefined Then
					Query.Parameters.InitialTemporaryTables.Add(NameOfRegisterCacheTable);
				EndIf;
			EndIf;
			
			QueriesTexts.Add(RegisterRequestText);
			Query.Parameters.AnalyticsSampleRegisters.Insert(FetchingRegisterName.RegisterName, IndexOfResultOfAnalyticsQuery);
			IndexOfResultOfAnalyticsQuery = IndexOfResultOfAnalyticsQuery + 1;
			
		EndDo;
		
	EndIf;
	
	QueriesTexts.Add("
	|SELECT
	|	RegisterRecords.RegisterNameDr AS RegisterNameDr,
	|	RegisterRecords.RegisterNameCr AS RegisterNameCr,
	|	MIN(RegisterRecords.InvertEntriy) AS InvertCorrespondence,
	|	CASE
	|		WHEN RegisterRecords.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|				OR RegisterRecords.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects
	|			THEN 2
	|		WHEN RegisterRecords.RegisterNameDr IN (&RegistersOfRecoveryOfCalculationsOnStorno)
	|				AND RegisterRecords.RegisterNameCr IN (&RegistersOfRecoveryOfCalculationsOnStorno)
	|			THEN 2
	|		ELSE 1
	|	END AS Order
	|FROM
	|	TTMovement AS RegisterRecords
	|WHERE
	|	RegisterRecords.AdditionalSetupOfHouseholdOperations = &SettingUpBusinessTransaction
	|
	|GROUP BY
	|	RegisterRecords.RegisterNameDr,
	|	RegisterRecords.RegisterNameCr
	|
	|ORDER BY
	|	Order");
	
	QueriesTexts.Add("
	|SELECT
	|	*
	|FROM
	|	TTMovement AS RegisterRecords
	|WHERE
	|	RegisterRecords.AdditionalSetupOfHouseholdOperations = &SettingUpBusinessTransaction");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, DeletedTemporaryTables);
	
EndProcedure

#EndRegion

#Region TextsOfRequestsForErrorCorrectionOfCorrespondenceWithReverse

Procedure IdentifyCorrespondenceErrors(QueriesTexts, QueryOptions, ReverseErrors = False)
	
	QueryText = "
	|SELECT
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID
	|INTO TTCorrespondenceErrors
	|FROM
	|	TableOfCorrespondenceOfRegisteredRecordsOfRegisters AS RegisteredRecordsDebitCredit
	|WHERE
	|	(RegisteredRecordsDebitCredit.RegisterNameDr = """"
	|		OR RegisteredRecordsDebitCredit.RegisterNameCr = """"
	|		OR (RegisteredRecordsDebitCredit.SumManDr <> RegisteredRecordsDebitCredit.SumManCr
	|			AND NOT RegisteredRecordsDebitCredit.RegisterNameDr IN (&RegistersWithoutManSum)
	|			AND NOT RegisteredRecordsDebitCredit.RegisterNameCr IN (&RegistersWithoutManSum))
	|		OR (RegisteredRecordsDebitCredit.SumComplDr <> RegisteredRecordsDebitCredit.SumComplCr
	|			AND NOT RegisteredRecordsDebitCredit.RegisterNameDr IN (&RegistersWithoutSumLocal)
	|			AND NOT RegisteredRecordsDebitCredit.RegisterNameCr IN (&RegistersWithoutSumLocal)))
	|	AND RegisteredRecordsDebitCredit.FinRecordID <> """"
	|	AND &TheseAreReverseRegisteredRecords
	|GROUP BY
	|	RegisteredRecordsDebitCredit.Period,
	|	RegisteredRecordsDebitCredit.Recorder,
	|	RegisteredRecordsDebitCredit.FinRecordID,
	|	RegisteredRecordsDebitCredit.Organization
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization
	|";
	
	If ReverseErrors Then
		TheseAreReverseRegisteredRecords = "TRUE IN 
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			TableOfCorrespondenceOfRegisteredRecordsOfRegisters AS ReverseRegisteredRecords
		|		WHERE
		|			ReverseRegisteredRecords.Period = RegisteredRecordsDebitCredit.Period
		|			AND ReverseRegisteredRecords.Recorder = RegisteredRecordsDebitCredit.Recorder
		|			AND ReverseRegisteredRecords.FinRecordID = RegisteredRecordsDebitCredit.FinRecordID
		|			AND ReverseRegisteredRecords.Organization = RegisteredRecordsDebitCredit.Organization
		|			AND (ReverseRegisteredRecords.ThisIsReverseTransactionDr OR ReverseRegisteredRecords.ThisIsReverseTransactionCr)
		|		)";
	Else
		TheseAreReverseRegisteredRecords = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&TheseAreReverseRegisteredRecords", TheseAreReverseRegisteredRecords);
	QueryText = StrReplace(QueryText, "TableOfCorrespondenceOfRegisteredRecordsOfRegisters", QueryOptions.TableOfCorrespondenceOfRegisteredRecordsOfRegisters);
	QueriesTexts.Add(QueryText);
	
EndProcedure

Procedure DetermineMaximumNumberOfMovementRecords(QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	MAX(MaximumRecordNumbers.RecNo) AS RecNo
	|INTO TTMaximumNumberOfEntries
	|FROM
	|	(SELECT
	|		MAX(DirectDebit.RecNo) AS RecNo
	|	FROM
	|		TTDebit AS DirectDebit
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		MAX(MovementCredit.RecNo) AS RecNo
	|	FROM
	|		TTCredit AS MovementCredit
	|	) AS MaximumRecordNumbers
	|");
	
EndProcedure

Procedure RestoreRegisteredRecordsOfErroneousCorrespondence(QueriesTexts, QueryOptions, DrCr)
	
	QueryText = "
	|SELECT
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.RegisterName AS RegisterName,
	|	RegisterRecords.Factor AS Factor,
	|	RegisterRecords.ThisIsDrCr AS ThisIsDrCr,
	|	RegisterRecords.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisterRecords.Organization AS Organization,
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterRecords.AdditionalSetupOfHouseholdOperations AS AdditionalSetupOfHouseholdOperations,
	|	RegisterRecords.FinRecordID AS FinRecordID,
	|	RegisterRecords.RowID AS RowID,
	|	RegisterRecords.VATActivityType AS VATActivityType,
	|	RegisterRecords.Currency AS Currency,
	|	RegisterRecords.SumMan AS SumMan,
	|	RegisterRecords.SumCompl AS SumCompl,
	|	RegisterRecords.SumCurr AS SumCurr,
	|	RegisterRecords.Count AS Count,
	|	RegisterRecords.PropsStorno AS PropsStorno
	|INTO TTMovementRegistersReverseDrCr
	|FROM
	|	TTRegisteredRecordsDrCr AS RegisterRecords
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTCorrespondenceErrors AS CorrespondencesErrors
	|		WHERE
	|			CorrespondencesErrors.Period = RegisterRecords.Period
	|			AND CorrespondencesErrors.Recorder = RegisterRecords.Recorder
	|			AND CorrespondencesErrors.FinRecordID = RegisterRecords.FinRecordID
	|			AND CorrespondencesErrors.Organization = RegisterRecords.Organization
	|		)
	|INDEX BY
	|	ThisIsReverseTransaction
	|";
	
	ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	MotionTableName = "TTRegisteredRecordsDrCr";
	ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(MotionTableName, DrCr);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, MotionTableName);
	
EndProcedure

Procedure IdentifyRegistersWithReverseRegisteredRecords(QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT DISTINCT
	|	MovementReverseDr.Period AS Period,
	|	MovementReverseDr.RegisterName AS RegisterName,
	|	MovementReverseDr.Organization AS Organization,
	|	MovementReverseDr.Recorder AS Recorder,
	|	MovementReverseDr.FinRecordID AS FinRecordID
	|INTO TTRegistersWithReverseRegisteredRecords
	|FROM
	|	TTRegisterRegisteredRecordsReverseDebit AS MovementReverseDr
	|WHERE
	|	MovementReverseDr.ThisIsReverseTransaction
	|
	|UNION
	|
	|SELECT DISTINCT
	|	MovementReverseCr.Period AS Period,
	|	MovementReverseCr.RegisterName AS RegisterName,
	|	MovementReverseCr.Organization AS Organization,
	|	MovementReverseCr.Recorder AS Recorder,
	|	MovementReverseCr.FinRecordID AS FinRecordID
	|FROM
	|	TTMovementRegistersReverseCredit AS MovementReverseCr
	|WHERE
	|	MovementReverseCr.ThisIsReverseTransaction
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization
	|");
	
EndProcedure

Procedure ReplaceReverseMovementWithReverse(QueriesTexts, DrCr)
	
	QueryText = "
	|SELECT
	|	MovementReverse.Period AS Period,
	|	MovementReverse.RegisterName AS RegisterName,
	|	MovementReverse.Factor AS Factor,
	|	MovementReverse.ThisIsDrCr AS ThisIsDrCr,
	|	MovementReverse.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	MovementReverse.Organization AS Organization,
	|	MovementReverse.Recorder AS Recorder,
	|	MovementReverse.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	MovementReverse.AdditionalSetupOfHouseholdOperations AS AdditionalSetupOfHouseholdOperations,
	|	MovementReverse.FinRecordID AS FinRecordID,
	|	MovementReverse.RowID AS RowID,
	|	MovementReverse.VATActivityType AS VATActivityType,
	|	MovementReverse.Currency AS Currency,
	|	MovementReverse.SumMan AS SumMan,
	|	MovementReverse.SumCompl AS SumCompl,
	|	MovementReverse.SumCurr AS SumCurr,
	|	MovementReverse.Count AS Count,
	|	MovementReverse.PropsStorno AS PropsStorno
	|INTO TTMovementOfRegistersIsReversed
	|FROM
	|	TTMovementRegistersReverseDrCr AS MovementReverse
	|WHERE
	|	NOT MovementReverse.ThisIsReverseTransaction
	|
	|UNION ALL
	|
	|SELECT
	|	MovementReverse.Period AS Period,
	|	MovementReverse.RegisterName AS RegisterName,
	|	MovementReverse.Factor AS Factor,
	|	MovementReverse.ThisIsCorDrCr AS ThisIsDrCr,
	|	NOT MovementReverse.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	MovementReverse.Organization AS Organization,
	|	MovementReverse.Recorder AS Recorder,
	|	MovementReverse.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	MovementReverse.AdditionalSetupOfHouseholdOperations AS AdditionalSetupOfHouseholdOperations,
	|	MovementReverse.FinRecordID AS FinRecordID,
	|	MovementReverse.RowID AS RowID,
	|	MovementReverse.VATActivityType AS VATActivityType,
	|	MovementReverse.Currency AS Currency,
	|	- MovementReverse.SumMan AS SumMan,
	|	- MovementReverse.SumCompl AS SumCompl,
	|	- MovementReverse.SumCurr AS SumCurr,
	|	- MovementReverse.Count AS Count,
	|	MovementReverse.PropsStorno AS PropsStorno
	|FROM
	|	TTCorMovementRegistersReverseDrCr AS MovementReverse
	|WHERE
	|	MovementReverse.ThisIsReverseTransaction
	|";
	
	ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	QueryText = "
	|SELECT
	|	RECORDAUTONUMBER() AS RecNo,
	|	RegisteredRecordsAreReversed.Period AS Period,
	|	RegisteredRecordsAreReversed.RegisterName AS RegisterName,
	|	RegisteredRecordsAreReversed.Factor AS Factor,
	|	RegisteredRecordsAreReversed.ThisIsDrCr AS ThisIsDrCr,
	|	RegisteredRecordsAreReversed.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisteredRecordsAreReversed.Organization AS Organization,
	|	RegisteredRecordsAreReversed.Recorder AS Recorder,
	|	RegisteredRecordsAreReversed.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsAreReversed.AdditionalSetupOfHouseholdOperations AS AdditionalSetupOfHouseholdOperations,
	|	RegisteredRecordsAreReversed.FinRecordID AS FinRecordID,
	|	RegisteredRecordsAreReversed.RowID AS RowID,
	|	RegisteredRecordsAreReversed.VATActivityType AS VATActivityType,
	|	RegisteredRecordsAreReversed.Currency AS Currency,
	|	SUM(RegisteredRecordsAreReversed.SumMan) AS SumMan,
	|	SUM(RegisteredRecordsAreReversed.SumCompl) AS SumCompl,
	|	SUM(RegisteredRecordsAreReversed.SumCurr) AS SumCurr,
	|	SUM(RegisteredRecordsAreReversed.Count) AS Count,
	|	RegisteredRecordsAreReversed.PropsStorno AS PropsStorno
	|INTO TTRolledUpRegisteredRecordsAreReversed
	|FROM
	|	TTMovementOfRegistersIsReversed AS RegisteredRecordsAreReversed
	|GROUP BY
	|	RegisteredRecordsAreReversed.Period,
	|	RegisteredRecordsAreReversed.RegisterName,
	|	RegisteredRecordsAreReversed.Factor,
	|	RegisteredRecordsAreReversed.ThisIsDrCr,
	|	RegisteredRecordsAreReversed.ThisIsReverseTransaction,
	|	RegisteredRecordsAreReversed.Organization,
	|	RegisteredRecordsAreReversed.Recorder,
	|	RegisteredRecordsAreReversed.SettingUpBusinessTransaction,
	|	RegisteredRecordsAreReversed.AdditionalSetupOfHouseholdOperations,
	|	RegisteredRecordsAreReversed.FinRecordID,
	|	RegisteredRecordsAreReversed.RowID,
	|	RegisteredRecordsAreReversed.VATActivityType,
	|	RegisteredRecordsAreReversed.Currency,
	|	RegisteredRecordsAreReversed.PropsStorno
	|";
	
	ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTMovementOfRegistersIsReversed");
	
	QueryText = "
	|SELECT
	|	RegisteredRecordsAreReversed.RecNo + MaximumNumberOfRecords.RecNo AS RecNo,
	|	RegisteredRecordsAreReversed.Period AS Period,
	|	RegisteredRecordsAreReversed.RegisterName AS RegisterName,
	|	RegisteredRecordsAreReversed.Factor AS Factor,
	|	RegisteredRecordsAreReversed.ThisIsDrCr AS ThisIsDrCr,
	|	RegisteredRecordsAreReversed.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	RegisteredRecordsAreReversed.Organization AS Organization,
	|	RegisteredRecordsAreReversed.Recorder AS Recorder,
	|	RegisteredRecordsAreReversed.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsAreReversed.AdditionalSetupOfHouseholdOperations AS AdditionalSetupOfHouseholdOperations,
	|	RegisteredRecordsAreReversed.FinRecordID AS FinRecordID,
	|	RegisteredRecordsAreReversed.RowID AS RowID,
	|	RegisteredRecordsAreReversed.VATActivityType AS VATActivityType,
	|	RegisteredRecordsAreReversed.Currency AS Currency,
	|	RegisteredRecordsAreReversed.SumMan AS SumMan,
	|	RegisteredRecordsAreReversed.SumCompl AS SumCompl,
	|	RegisteredRecordsAreReversed.SumCurr AS SumCurr,
	|	RegisteredRecordsAreReversed.Count AS Count,
	|	RegisteredRecordsAreReversed.PropsStorno AS PropsStorno
	|INTO TTRegisterRegisteredRecordsDrCr
	|FROM
	|	TTRolledUpRegisteredRecordsAreReversed AS RegisteredRecordsAreReversed
	|	,
	|	TTMaximumNumberOfEntries AS MaximumNumberOfRecords
	|";
	
	ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr);
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRolledUpRegisteredRecordsAreReversed");
	
EndProcedure

Procedure IdentifyCorrespondenceWithoutErrors(QueriesTexts, QueryOptions)
	
	IdentifyCorrespondenceErrors(QueriesTexts, QueryOptions);
	
	QueryText = "
	|SELECT
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.RecNoDr AS RecNoDr,
	|	RegisteredRecordsDebitCredit.RecNoCr AS RecNoCr,
	|	RegisteredRecordsDebitCredit.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsDebitCredit.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsDebitCredit.AdditionalSetupOfHouseholdOperationsDr AS AdditionalSetupOfHouseholdOperationsDr,
	|	RegisteredRecordsDebitCredit.AdditionalSetupOfHouseholdOperationsCr AS AdditionalSetupOfHouseholdOperationsCr,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	RegisteredRecordsDebitCredit.RowIDDr AS RowIDDr,
	|	RegisteredRecordsDebitCredit.RowIDCr AS RowIDCr,
	|	RegisteredRecordsDebitCredit.VATActivityTypeDr AS VATActivityTypeDr,
	|	RegisteredRecordsDebitCredit.VATActivityTypeCr AS VATActivityTypeCr,
	|	RegisteredRecordsDebitCredit.FactorDr AS FactorDr,
	|	RegisteredRecordsDebitCredit.FactorCr AS FactorCr,
	|	RegisteredRecordsDebitCredit.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsDebitCredit.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsDebitCredit.AmountOfMovementShaftDr AS AmountOfMovementShaftDr,
	|	RegisteredRecordsDebitCredit.AmountOfMovementCrShaft AS AmountOfMovementCrShaft,
	|	RegisteredRecordsDebitCredit.AmountOfDrMovement AS AmountOfDrMovement,
	|	RegisteredRecordsDebitCredit.CrMotionCount AS CrMotionCount,
	|	RegisteredRecordsDebitCredit.PropsStornoDr AS PropsStornoDr,
	|	RegisteredRecordsDebitCredit.PropsStornoCr AS PropsStornoCr,
	|	RegisteredRecordsDebitCredit.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsDebitCredit.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsDebitCredit.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisteredRecordsDebitCredit.SumManDr AS SumManDr,
	|	RegisteredRecordsDebitCredit.SumManCr AS SumManCr,
	|	RegisteredRecordsDebitCredit.SumComplDr AS SumComplDr,
	|	RegisteredRecordsDebitCredit.SumComplCr AS SumComplCr
	|INTO TTCorrespondenceWithoutErrors
	|FROM
	|	TableOfCorrespondenceOfRegisteredRecordsOfRegisters AS RegisteredRecordsDebitCredit
	|WHERE
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTCorrespondenceErrors AS CorrespondencesErrors
	|		WHERE
	|			CorrespondencesErrors.Period = RegisteredRecordsDebitCredit.Period
	|			AND CorrespondencesErrors.Recorder = RegisteredRecordsDebitCredit.Recorder
	|			AND CorrespondencesErrors.FinRecordID = RegisteredRecordsDebitCredit.FinRecordID
	|			AND CorrespondencesErrors.Organization = RegisteredRecordsDebitCredit.Organization
	|		)
	|";
	
	QueryText = StrReplace(QueryText, "TableOfCorrespondenceOfRegisteredRecordsOfRegisters", QueryOptions.TableOfCorrespondenceOfRegisteredRecordsOfRegisters);
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTCorrespondenceErrors");
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, QueryOptions.TableOfCorrespondenceOfRegisteredRecordsOfRegisters);
	
EndProcedure

Procedure DetermineReverseToReverseReplacementRegisters(QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	CorrespondenceWithoutErrors.Period AS Period,
	|	CorrespondenceWithoutErrors.Organization AS Organization,
	|	CorrespondenceWithoutErrors.Recorder AS Recorder,
	|	CorrespondenceWithoutErrors.FinRecordID AS FinRecordID
	|INTO TTDocumentsReplacingReverseWithReverse
	|FROM
	|	TTCorrespondenceWithoutErrors AS CorrespondenceWithoutErrors
	|GROUP BY
	|	CorrespondenceWithoutErrors.Period,
	|	CorrespondenceWithoutErrors.Recorder,
	|	CorrespondenceWithoutErrors.FinRecordID,
	|	CorrespondenceWithoutErrors.Organization
	|INDEX BY
	|	Period,
	|	Recorder,
	|	FinRecordID,
	|	Organization
	|");
	
	QueriesTexts.Add("
	|SELECT DISTINCT
	|	ReverseRegisters.RegisterName AS RegisterName
	|INTO TTReverseToReverseReplacementRegisters
	|FROM
	|	TTRegistersWithReverseRegisteredRecords AS ReverseRegisters
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTDocumentsReplacingReverseWithReverse AS ReverseReplacementDocuments
	|		WHERE
	|			ReverseReplacementDocuments.Period = ReverseRegisters.Period
	|			AND ReverseReplacementDocuments.Recorder = ReverseRegisters.Recorder
	|			AND ReverseReplacementDocuments.FinRecordID = ReverseRegisters.FinRecordID
	|			AND ReverseReplacementDocuments.Organization = ReverseRegisters.Organization
	|		)
	|");
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRegistersWithReverseRegisteredRecords");
	
EndProcedure

Procedure ReplaceCorrespondenceReverseWithReverse(QueriesTexts,
	CreatedTableOfCorrespondenceRegisteredRecords, DeletedTableOfCorrespondenceRegisteredRecords)
	
	QueryText = "
	|SELECT
	|	RegisteredRecordsDebitCredit.Period AS Period,
	|	RegisteredRecordsDebitCredit.RecNoDr AS RecNoDr,
	|	RegisteredRecordsDebitCredit.RecNoCr AS RecNoCr,
	|	RegisteredRecordsDebitCredit.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsDebitCredit.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsDebitCredit.FactorDr AS FactorDr,
	|	RegisteredRecordsDebitCredit.FactorCr AS FactorCr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsDebitCredit.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsDebitCredit.Organization AS Organization,
	|	RegisteredRecordsDebitCredit.Recorder AS Recorder,
	|	RegisteredRecordsDebitCredit.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsDebitCredit.AdditionalSetupOfHouseholdOperationsDr AS AdditionalSetupOfHouseholdOperationsDr,
	|	RegisteredRecordsDebitCredit.AdditionalSetupOfHouseholdOperationsCr AS AdditionalSetupOfHouseholdOperationsCr,
	|	RegisteredRecordsDebitCredit.FinRecordID AS FinRecordID,
	|	RegisteredRecordsDebitCredit.RowIDDr AS RowIDDr,
	|	RegisteredRecordsDebitCredit.RowIDCr AS RowIDCr,
	|	RegisteredRecordsDebitCredit.VATActivityTypeDr AS VATActivityTypeDr,
	|	RegisteredRecordsDebitCredit.VATActivityTypeCr AS VATActivityTypeCr,
	|	RegisteredRecordsDebitCredit.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsDebitCredit.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsDebitCredit.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsDebitCredit.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsDebitCredit.AmountOfMovementShaftDr AS AmountOfMovementShaftDr,
	|	RegisteredRecordsDebitCredit.AmountOfMovementCrShaft AS AmountOfMovementCrShaft,
	|	RegisteredRecordsDebitCredit.AmountOfDrMovement AS AmountOfDrMovement,
	|	RegisteredRecordsDebitCredit.CrMotionCount AS CrMotionCount,
	|	RegisteredRecordsDebitCredit.PropsStornoDr AS PropsStornoDr,
	|	RegisteredRecordsDebitCredit.PropsStornoCr AS PropsStornoCr,
	|	RegisteredRecordsDebitCredit.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsDebitCredit.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsDebitCredit.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisteredRecordsDebitCredit.SumManDr AS SumManDr,
	|	RegisteredRecordsDebitCredit.SumManCr AS SumManCr,
	|	RegisteredRecordsDebitCredit.SumComplDr AS SumComplDr,
	|	RegisteredRecordsDebitCredit.SumComplCr AS SumComplCr
	|INTO CreatedTableOfCorrespondenceRegisteredRecords
	|FROM
	|	DeletedTableOfCorrespondenceRegisteredRecords AS RegisteredRecordsDebitCredit
	|WHERE
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTDocumentsReplacingReverseWithReverse AS ReverseReplacementDocuments
	|		WHERE
	|			ReverseReplacementDocuments.Period = RegisteredRecordsDebitCredit.Period
	|			AND ReverseReplacementDocuments.Recorder = RegisteredRecordsDebitCredit.Recorder
	|			AND ReverseReplacementDocuments.FinRecordID = RegisteredRecordsDebitCredit.FinRecordID
	|			AND ReverseReplacementDocuments.Organization = RegisteredRecordsDebitCredit.Organization
	|		)
	|
	|UNION ALL
	|
	|SELECT
	|	RegisteredRecordsWithoutErrors.Period AS Period,
	|	RegisteredRecordsWithoutErrors.RecNoDr AS RecNoDr,
	|	RegisteredRecordsWithoutErrors.RecNoCr AS RecNoCr,
	|	RegisteredRecordsWithoutErrors.RegisterNameDr AS RegisterNameDr,
	|	RegisteredRecordsWithoutErrors.RegisterNameCr AS RegisterNameCr,
	|	RegisteredRecordsWithoutErrors.FactorDr AS FactorDr,
	|	RegisteredRecordsWithoutErrors.FactorCr AS FactorCr,
	|	RegisteredRecordsWithoutErrors.ThisIsReverseTransactionDr AS ThisIsReverseTransactionDr,
	|	RegisteredRecordsWithoutErrors.ThisIsReverseTransactionCr AS ThisIsReverseTransactionCr,
	|	RegisteredRecordsWithoutErrors.Organization AS Organization,
	|	RegisteredRecordsWithoutErrors.Recorder AS Recorder,
	|	RegisteredRecordsWithoutErrors.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisteredRecordsWithoutErrors.AdditionalSetupOfHouseholdOperationsDr AS SettingUpBusinessTransactionDr,
	|	RegisteredRecordsWithoutErrors.AdditionalSetupOfHouseholdOperationsCr AS SettingUpBusinessTransactionCr,
	|	RegisteredRecordsWithoutErrors.FinRecordID AS FinRecordID,
	|	RegisteredRecordsWithoutErrors.RowIDDr AS RowIDDr,
	|	RegisteredRecordsWithoutErrors.RowIDCr AS RowIDCr,
	|	RegisteredRecordsWithoutErrors.VATActivityTypeDr AS VATActivityTypeDr,
	|	RegisteredRecordsWithoutErrors.VATActivityTypeCr AS VATActivityTypeCr,
	|	RegisteredRecordsWithoutErrors.CurrencyDr AS CurrencyDr,
	|	RegisteredRecordsWithoutErrors.CurrencyCr AS CurrencyCr,
	|	RegisteredRecordsWithoutErrors.AmountOfManMovementDr AS AmountOfManMovementDr,
	|	RegisteredRecordsWithoutErrors.AmountOfManMovementCr AS AmountOfManMovementCr,
	|	RegisteredRecordsWithoutErrors.AmountOfLocalTrafficDr AS AmountOfLocalTrafficDr,
	|	RegisteredRecordsWithoutErrors.AmountOfLocalTrafficCr AS AmountOfLocalTrafficCr,
	|	RegisteredRecordsWithoutErrors.AmountOfMovementShaftDr AS AmountOfMovementShaftDr,
	|	RegisteredRecordsWithoutErrors.AmountOfMovementCrShaft AS AmountOfMovementCrShaft,
	|	RegisteredRecordsWithoutErrors.AmountOfDrMovement AS AmountOfDrMovement,
	|	RegisteredRecordsWithoutErrors.CrMotionCount AS CrMotionCount,
	|	RegisteredRecordsWithoutErrors.PropsStornoDr AS PropsStornoDr,
	|	RegisteredRecordsWithoutErrors.PropsStornoCr AS PropsStornoCr,
	|	RegisteredRecordsWithoutErrors.ComplexEntryDr AS ComplexEntryDr,
	|	RegisteredRecordsWithoutErrors.ComplexEntryCr AS ComplexEntryCr,
	|	RegisteredRecordsWithoutErrors.TakeIntoAccountBusinessTransaction AS TakeIntoAccountBusinessTransaction,
	|	RegisteredRecordsWithoutErrors.SumManDr AS SumManDr,
	|	RegisteredRecordsWithoutErrors.SumManCr AS SumManCr,
	|	RegisteredRecordsWithoutErrors.SumComplDr AS SumComplDr,
	|	RegisteredRecordsWithoutErrors.SumComplCr AS SumComplCr
	|FROM
	|	TTCorrespondenceWithoutErrors AS RegisteredRecordsWithoutErrors
	|";
	
	QueryText = StrReplace(QueryText, "CreatedTableOfCorrespondenceRegisteredRecords", CreatedTableOfCorrespondenceRegisteredRecords);
	QueryText = StrReplace(QueryText, "DeletedTableOfCorrespondenceRegisteredRecords", DeletedTableOfCorrespondenceRegisteredRecords);
	QueriesTexts.Add(QueryText);
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, DeletedTableOfCorrespondenceRegisteredRecords);
	
EndProcedure

Procedure AddEmptyTableOfReverseReplacementDocuments(QueriesTexts)
	
	QueriesTexts.Add("
	|SELECT
	|	DATETIME(0001, 01, 01) AS Period,
	|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
	|	CAST("""" AS STRING(36)) AS FinRecordID,
	|	UNDEFINED AS Recorder
	|INTO TTDocumentsReplacingReverseWithReverse
	|WHERE
	|	FALSE
	|");
	
EndProcedure

#EndRegion

#Region TextsOfRequestsToRestorePaymentsForStorno

Procedure RestoreStornoCalculationsIfNecessary(Query, QueriesTexts)
	
	If Not Query.Parameters.RestoreCalculationsForStorno Then
		Return;
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentsRegistry.Organization AS Organization,
	|	DocumentsRegistry.Ref AS DocumentReversingEntry,
	|	DocumentsRegistry.IBDocumentDate AS Period,
	|	DocumentsRegistry.ReversedDocument AS ReversedDocument
	|INTO TTRegisterOfDocumentsStorno
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|	INNER JOIN DocumentsToBeReflected AS DocumentsToBeReflected
	|		ON DocumentsRegistry.Ref = DocumentsToBeReflected.Recorder
	|WHERE
	|	DocumentsRegistry.Posted
	|	AND DocumentsRegistry.ReverseTransactionCorrection
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|	AND &ConditionsForSelectionOfDocuments
	|	AND NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TableOfCorrespondenceOfRegisteredRecordsOfRegisters AS RegisteredRecordsDebitCredit
	|		WHERE
	|			RegisteredRecordsDebitCredit.Period = DocumentsRegistry.IBDocumentDate
	|			AND RegisteredRecordsDebitCredit.Recorder = DocumentsRegistry.Ref
	|			AND RegisteredRecordsDebitCredit.RegisterNameDr IN (&RegistersOfRecoveryOfCalculationsOnStorno)
	|			AND RegisteredRecordsDebitCredit.RegisterNameCr IN (&RegistersOfRecoveryOfCalculationsOnStorno)
	|			AND &OrganizationSelectionCriteria
	|		)
	|INDEX BY
	|	DocumentReversingEntry,
	|	ReversedDocument
	|";
	
	OrganizationSelectionCriteria = "RegisteredRecordsDebitCredit.Organization = DocumentsRegistry.Organization";
	OrganizationSelectionField = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Catalogs.Companies.EmptyRef());
	
	LinesOfConditionsForSelectionOfDocuments = New Array();
	
	If Query.Parameters.StartDate > '00010101' Then
		LinesOfConditionsForSelectionOfDocuments.Add("DocumentsRegistry.IBDocumentDate >= &StartDate");
	EndIf;
	
	If Query.Parameters.EndDate > '00010101' Then
		LinesOfConditionsForSelectionOfDocuments.Add("DocumentsRegistry.IBDocumentDate <= &EndDate");
	EndIf;
	
	If TypeOf(Query.Parameters.Recorder) = Type("Array") Then
		LinesOfConditionsForSelectionOfDocuments.Add("DocumentsRegistry.Ref IN (&Recorder)");
	ElsIf ValueIsFilled(Query.Parameters.Recorder) Then
		LinesOfConditionsForSelectionOfDocuments.Add("DocumentsRegistry.Ref = &Recorder");
	EndIf;
	
	If LinesOfConditionsForSelectionOfDocuments.Count() > 0 Then
		LineSplitter = Chars.LF + Chars.Tab + "And ";
		ConditionsForSelectionOfDocuments = StrConcat(LinesOfConditionsForSelectionOfDocuments, LineSplitter);
	Else
		ConditionsForSelectionOfDocuments = "TRUE";
	EndIf;
		
	QueryText = StrReplace(QueryText, "&Organization", OrganizationSelectionField);
	QueryText = StrReplace(QueryText, "&ConditionsForSelectionOfDocuments", ConditionsForSelectionOfDocuments);
	QueryText = StrReplace(QueryText, "&OrganizationSelectionCriteria", OrganizationSelectionCriteria);
	QueryText = StrReplace(QueryText, "TableOfCorrespondenceOfRegisteredRecordsOfRegisters", Query.Parameters.TableOfCorrespondenceOfRegisteredRecordsOfRegisters);
	
	QueriesTexts.Add(QueryText);
	
	If Not FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, QueriesTexts, "TTRegisterOfDocumentsStorno") Then
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRegisterOfDocumentsStorno");
		Query.Parameters.RestoreCalculationsForStorno = False;
		Return;
	EndIf;
	
	#Region ReversePrepaymentFromCustomer
	
	QueryText = "
	|SELECT
	|	RegisterData.Period AS Period,
	|	""CustomersARAPAccountingByDueDates"" AS RegisterName,
	|	VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount) AS FactorDr,
	|	VALUE(Enum.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan) AS FactorCr,
	|	FALSE AS ThisIsReverseTransaction,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentFromCustomer) AS SettingUpBusinessTransaction,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentFromCustomer) AS AdditionalSetupOfHouseholdOperations,
	|	"""" AS FinRecordID,
	|	"""" AS RowID,
	|	FALSE AS PropsStorno,
	|	RegisterData.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	RegisterData.ARAPObject AS ARAPObject,
	|	RegisterData.Recorder AS ARAPDocument,
	|	RegisterData.Currency AS Currency,
	|	&OtherFieldsSourcesOfExtdimension,
	|	SUM(RegisterData.ARAPMan) AS SumManDr,
	|	SUM(RegisterData.PrepaymentMan) AS SumManCr,
	|	SUM(RegisterData.DebtLocal) AS SumComplDr,
	|	SUM(RegisterData.PrepaymentLocal) AS SumComplCr,
	|	SUM(RegisterData.Debt) AS SumCurrDr,
	|	SUM(RegisterData.Prepayment) AS SumCurrCr
	|INTO TTSettlementsWithCustomersOnStorno
	|FROM
	|	(SELECT
	|		DocumentsRegistry.Period AS Period,
	|		DocumentsRegistry.DocumentReversingEntry AS Recorder,
	|		CustomersARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		CustomersARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|		CustomersARAPAccountingByDueDates.Currency AS Currency,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.Debt 
	|			ELSE CustomersARAPAccountingByDueDates.Debt 
	|		END AS Debt,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.DebtLocal 
	|			ELSE CustomersARAPAccountingByDueDates.DebtLocal 
	|		END AS DebtLocal,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.ARAPMan 
	|			ELSE CustomersARAPAccountingByDueDates.ARAPMan 
	|		END AS ARAPMan,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.Prepayment 
	|			ELSE CustomersARAPAccountingByDueDates.Prepayment 
	|		END AS Prepayment,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.PrepaymentLocal 
	|			ELSE CustomersARAPAccountingByDueDates.PrepaymentLocal 
	|		END AS PrepaymentLocal,
	|		-CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -CustomersARAPAccountingByDueDates.PrepaymentMan 
	|			ELSE CustomersARAPAccountingByDueDates.PrepaymentMan 
	|		END AS PrepaymentMan
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
	|		INNER JOIN TTRegisterOfDocumentsStorno AS DocumentsRegistry
	|		ON CustomersARAPAccountingByDueDates.DocumentRecorder = DocumentsRegistry.ReversedDocument
	|		 AND CustomersARAPAccountingByDueDates.AccountingDimensionByPartners.Organization = DocumentsRegistry.Organization
	|	WHERE
	|		NOT CustomersARAPAccountingByDueDates.ReversingEntry
	|
	|	UNION ALL
	|
	|	SELECT
	|		DocumentsRegistry.Period AS Period,
	|		DocumentsRegistry.DocumentReversingEntry AS Recorder,
	|		CustomersARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		CustomersARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|		CustomersARAPAccountingByDueDates.Currency AS Currency,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.Debt 
	|			ELSE CustomersARAPAccountingByDueDates.Debt 
	|		END AS Debt,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.DebtLocal 
	|			ELSE CustomersARAPAccountingByDueDates.DebtLocal 
	|		END AS DebtLocal,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.ARAPMan 
	|			ELSE CustomersARAPAccountingByDueDates.ARAPMan 
	|		END AS ARAPMan,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.Prepayment 
	|			ELSE CustomersARAPAccountingByDueDates.Prepayment 
	|		END AS Prepayment,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.PrepaymentLocal 
	|			ELSE CustomersARAPAccountingByDueDates.PrepaymentLocal 
	|		END AS PrepaymentLocal,
	|		CASE
	|			WHEN CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -CustomersARAPAccountingByDueDates.PrepaymentMan 
	|			ELSE CustomersARAPAccountingByDueDates.PrepaymentMan 
	|		END AS PrepaymentMan
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
	|		INNER JOIN TTRegisterOfDocumentsStorno AS DocumentsRegistry
	|		ON CustomersARAPAccountingByDueDates.DocumentRecorder = DocumentsRegistry.DocumentReversingEntry
	|		 AND CustomersARAPAccountingByDueDates.AccountingDimensionByPartners.Organization = DocumentsRegistry.Organization
	|	WHERE
	|		CustomersARAPAccountingByDueDates.ReversingEntry
	|	) AS RegisterData
	|GROUP BY
	|	RegisterData.Period,
	|	RegisterData.Recorder,
	|	RegisterData.AccountingDimensionByPartners,
	|	RegisterData.ARAPObject,
	|	RegisterData.Currency
	|HAVING
	|	SUM(RegisterData.Debt) <> 0 OR SUM(RegisterData.Prepayment) <> 0
	|";
	
	ExistingFieldsSourcesOfExtdimension = New Array();
	ExistingFieldsSourcesOfExtdimension.Add("AccountingDimensionByPartners");
	ExistingFieldsSourcesOfExtdimension.Add("ARAPObject");
	ExistingFieldsSourcesOfExtdimension.Add("Currency");
	ExistingFieldsSourcesOfExtdimension.Add("ARAPDocument");
	
	OtherFieldsSourcesOfExtdimension = New Array();
	SampleTextsForOtherFields = New Array();
	LineSplitter = "," + Chars.LF + Chars.Tab;
	AccountingReflectionParameters = AccumulationRegisters.CustomersARAPAccountingByDueDates.ParametersForReflectingRegisteredRecordsInFinancialAccounting(); // See the parametersreflection of movement in the financial account
	If AccountingReflectionParameters.StructureOfAnalytics.Count() = 0 Then
		AccountingReflectionParameters.StructureOfAnalytics = DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(AccountingReflectionParameters.TypeOfAccountingData);
	EndIf;
	
	For Each DimDetails In AccountingReflectionParameters.StructureOfAnalytics Do
		DataPathParts = StrSplit(DimDetails.Value.DataPath, ".");
		CaseFieldName = DataPathParts[0];
		If ExistingFieldsSourcesOfExtdimension.Find(CaseFieldName) = Undefined
			And OtherFieldsSourcesOfExtdimension.Find(CaseFieldName) = Undefined Then
			OtherFieldsSourcesOfExtdimension.Add(CaseFieldName);
			SampleTextsForOtherFields.Add("UNDEFINED AS " + CaseFieldName);
		EndIf;
	EndDo;
	
	QueryText = StrReplace(QueryText, "&OtherFieldsSourcesOfExtdimension", ?(SampleTextsForOtherFields.Count() = 0, "UNDEFINED", StrConcat(SampleTextsForOtherFields, LineSplitter)));
	
	QueriesTexts.Add(QueryText);
	
	If FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, QueriesTexts, "TTSettlementsWithCustomersOnStorno") Then
		TMCommonUse.AddIDsToTemporaryTable(
			"TTSettlementsWithCustomersOnStorno",
			Query.TempTablesManager,
			"FinRecordID");
	EndIf;
	
	#EndRegion
	
	#Region ReversePrepaymentToVendor
	
	QueryText = "
	|SELECT
	|	RegisterData.Period AS Period,
	|	""VendorsARAPAccountingByDueDates"" AS RegisterName,
	|	VALUE(Enum.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan) AS FactorDr,
	|	VALUE(Enum.IndicatorsOfAnalyticalRegisters.PostpaymentAmount) AS FactorCr,
	|	FALSE AS ThisIsReverseTransaction,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.AccountingDimensionByPartners.Organization AS Organization,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentToVendor) AS SettingUpBusinessTransaction,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReversePrepaymentToVendor) AS AdditionalSetupOfHouseholdOperations,
	|	"""" AS FinRecordID,
	|	"""" AS RowID,
	|	FALSE AS PropsStorno,
	|	RegisterData.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	RegisterData.ARAPObject AS ARAPObject,
	|	RegisterData.Recorder AS ARAPDocument,
	|	RegisterData.Currency AS Currency,
	|	&OtherFieldsSourcesOfExtdimension,
	|	SUM(RegisterData.PrepaymentMan) AS SumManDr,
	|	SUM(RegisterData.ARAPMan) AS SumManCr,
	|	SUM(RegisterData.PrepaymentLocal) AS SumComplDr,
	|	SUM(RegisterData.DebtLocal) AS SumComplCr,
	|	SUM(RegisterData.Prepayment) AS SumCurrDr,
	|	SUM(RegisterData.Debt) AS SumCurrCr
	|INTO TTSettlementsWithSuppliersOnStorno
	|FROM
	|	(SELECT
	|		DocumentsRegistry.Period AS Period,
	|		DocumentsRegistry.DocumentReversingEntry AS Recorder,
	|		VendorsARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		VendorsARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|		VendorsARAPAccountingByDueDates.Currency AS Currency,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.Debt 
	|			ELSE VendorsARAPAccountingByDueDates.Debt 
	|		END AS Debt,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.DebtLocal 
	|			ELSE VendorsARAPAccountingByDueDates.DebtLocal 
	|		END AS DebtLocal,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.ARAPMan 
	|			ELSE VendorsARAPAccountingByDueDates.ARAPMan 
	|		END AS ARAPMan,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.Prepayment 
	|			ELSE VendorsARAPAccountingByDueDates.Prepayment 
	|		END AS Prepayment,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.PrepaymentLocal 
	|			ELSE VendorsARAPAccountingByDueDates.PrepaymentLocal 
	|		END AS PrepaymentLocal,
	|		-CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -VendorsARAPAccountingByDueDates.PrepaymentMan 
	|			ELSE VendorsARAPAccountingByDueDates.PrepaymentMan 
	|		END AS PrepaymentMan
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates
	|		INNER JOIN TTRegisterOfDocumentsStorno AS DocumentsRegistry
	|		ON VendorsARAPAccountingByDueDates.DocumentRecorder = DocumentsRegistry.ReversedDocument
	|		 AND VendorsARAPAccountingByDueDates.AccountingDimensionByPartners.Organization = DocumentsRegistry.Organization
	|	WHERE
	|		NOT VendorsARAPAccountingByDueDates.ReversingEntry
	|
	|	UNION ALL
	|
	|	SELECT
	|		DocumentsRegistry.Period AS Period,
	|		DocumentsRegistry.DocumentReversingEntry AS Recorder,
	|		VendorsARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		VendorsARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|		VendorsARAPAccountingByDueDates.Currency AS Currency,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.Debt 
	|			ELSE VendorsARAPAccountingByDueDates.Debt 
	|		END AS Debt,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.DebtLocal 
	|			ELSE VendorsARAPAccountingByDueDates.DebtLocal 
	|		END AS DebtLocal,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.ARAPMan 
	|			ELSE VendorsARAPAccountingByDueDates.ARAPMan 
	|		END AS ARAPMan,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.Prepayment 
	|			ELSE VendorsARAPAccountingByDueDates.Prepayment 
	|		END AS Prepayment,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.PrepaymentLocal 
	|			ELSE VendorsARAPAccountingByDueDates.PrepaymentLocal 
	|		END AS PrepaymentLocal,
	|		CASE
	|			WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -VendorsARAPAccountingByDueDates.PrepaymentMan 
	|			ELSE VendorsARAPAccountingByDueDates.PrepaymentMan 
	|		END AS PrepaymentMan
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates
	|		INNER JOIN TTRegisterOfDocumentsStorno AS DocumentsRegistry
	|		ON VendorsARAPAccountingByDueDates.DocumentRecorder = DocumentsRegistry.DocumentReversingEntry
	|		 AND VendorsARAPAccountingByDueDates.AccountingDimensionByPartners.Organization = DocumentsRegistry.Organization
	|	WHERE
	|		VendorsARAPAccountingByDueDates.ReversingEntry
	|	) AS RegisterData
	|GROUP BY
	|	RegisterData.Period,
	|	RegisterData.Recorder,
	|	RegisterData.AccountingDimensionByPartners,
	|	RegisterData.ARAPObject,
	|	RegisterData.Currency
	|HAVING
	|	SUM(RegisterData.Debt) <> 0 OR SUM(RegisterData.Prepayment) <> 0
	|";
	
	ExistingFieldsSourcesOfExtdimension = New Array();
	ExistingFieldsSourcesOfExtdimension.Add("AccountingDimensionByPartners");
	ExistingFieldsSourcesOfExtdimension.Add("ARAPObject");
	ExistingFieldsSourcesOfExtdimension.Add("Currency");
	ExistingFieldsSourcesOfExtdimension.Add("ARAPDocument");
	
	OtherFieldsSourcesOfExtdimension = New Array();
	SampleTextsForOtherFields = New Array();
	LineSplitter = "," + Chars.LF + Chars.Tab;
	AccountingReflectionParameters = AccumulationRegisters.VendorsARAPAccountingByDueDates.ParametersForReflectingRegisteredRecordsInFinancialAccounting(); // See the parametersreflection of movement in the financial account
	If AccountingReflectionParameters.StructureOfAnalytics.Count() = 0 Then
		AccountingReflectionParameters.StructureOfAnalytics = DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(
			AccountingReflectionParameters.TypeOfAccountingData);
	EndIf;
	
	For Each DimDetails In AccountingReflectionParameters.StructureOfAnalytics Do
		DataPathParts = StrSplit(DimDetails.Value.DataPath, ".");
		CaseFieldName = DataPathParts[0];
		If ExistingFieldsSourcesOfExtdimension.Find(CaseFieldName) = Undefined
			And OtherFieldsSourcesOfExtdimension.Find(CaseFieldName) = Undefined Then
			OtherFieldsSourcesOfExtdimension.Add(CaseFieldName);
			SampleTextsForOtherFields.Add("UNDEFINED AS " + CaseFieldName);
		EndIf;
	EndDo;
	
	QueryText = StrReplace(QueryText, "&OtherFieldsSourcesOfExtdimension", ?(SampleTextsForOtherFields.Count()
		= 0, "UNDEFINED", StrConcat(SampleTextsForOtherFields, LineSplitter)));
	
	QueriesTexts.Add(QueryText);
	
	If FinancialAccountingByBalanceSheetRegisterData.HasRecordsInTemporaryTable(Query, QueriesTexts, "TTSettlementsWithSuppliersOnStorno") Then
		TMCommonUse.AddIDsToTemporaryTable(
			"TTSettlementsWithSuppliersOnStorno",
			Query.TempTablesManager,
			"FinRecordID");
	EndIf;
	
	#EndRegion
	
	FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRegisterOfDocumentsStorno");
	
	If Query.Parameters.RestoreCalculationsForStorno Then
		Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		Query.ExecuteBatch();
		QueriesTexts.Clear();
		
		If TMCommonUse.TemporaryTableSize(Query.TempTablesManager, "TTSettlementsWithCustomersOnStorno") > 0 Then
			TMCommonUse.AddIDsToTemporaryTable(
				"TTSettlementsWithCustomersOnStorno",
				Query.TempTablesManager,
				"FinRecordID");
		EndIf;
		
		If TMCommonUse.TemporaryTableSize(Query.TempTablesManager, "TTSettlementsWithSuppliersOnStorno") > 0 Then
			TMCommonUse.AddIDsToTemporaryTable(
				"TTSettlementsWithSuppliersOnStorno",
				Query.TempTablesManager,
				"FinRecordID");
		EndIf;
	EndIf;
	
EndProcedure

Procedure AddTableForRestoringCalculationsForStorno(RegisterRequestText, RegisterName)
	
	QueryText = "
	|SELECT
	|	RegisterTable.Period AS Period,
	|	RegisterTable.RegisterName AS RegisterName,
	|	RegisterTable.FactorDr AS Factor,
	|	TRUE AS ThisIsDebit,
	|	FALSE AS ThisIsLoan,
	|	RegisterTable.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	&AnalyticsSelectionFields,
	|	RegisterTable.Recorder AS Recorder,
	|	RegisterTable.Organization AS Organization,
	|	RegisterTable.ARAPObject.Department AS Department,
	|	RegisterTable.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	RegisterTable.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterTable.FinRecordID AS FinRecordID,
	|	RegisterTable.RowID AS RowID,
	|	RegisterTable.Currency AS Currency,
	|	RegisterTable.SumManDr AS SumMan,
	|	RegisterTable.SumComplDr AS SumCompl,
	|	RegisterTable.SumCurrDr AS SumCurr,
	|	0 AS Count
	|FROM
	|	&DataSource AS RegisterTable
	|
	|UNION ALL
	|
	|SELECT
	|	RegisterTable.Period AS Period,
	|	RegisterTable.RegisterName AS RegisterName,
	|	RegisterTable.FactorCr AS Factor,
	|	FALSE AS ThisIsDebit,
	|	TRUE AS ThisIsLoan,
	|	RegisterTable.ThisIsReverseTransaction AS ThisIsReverseTransaction,
	|	&AnalyticsSelectionFields,
	|	RegisterTable.Recorder AS Recorder,
	|	RegisterTable.Organization AS Organization,
	|	RegisterTable.ARAPObject.Department AS Department,
	|	RegisterTable.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	RegisterTable.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
	|	RegisterTable.FinRecordID AS FinRecordID,
	|	RegisterTable.RowID AS RowID,
	|	RegisterTable.Currency AS Currency,
	|	RegisterTable.SumManCr AS SumMan,
	|	RegisterTable.SumComplCr AS SumCompl,
	|	RegisterTable.SumCurrCr AS SumCurr,
	|	0 AS Count
	|FROM
	|	&DataSource AS RegisterTable
	|";
	
	If RegisterName = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Name Then
		DataSource = "TTSettlementsWithCustomersOnStorno";
	Else
		DataSource = "TTSettlementsWithSuppliersOnStorno";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&DataSource", DataSource);
	
	IndexBy = "INDEX BY"; //@Query-part
	
	If StrFind(RegisterRequestText, IndexBy, SearchDirection.FromEnd) = 0 Then
		RegisterRequestText = RegisterRequestText
			+ TMCommonUse.QuerySeparatorInJoin()
			+ QueryText;
	Else
		RegisterRequestText = StrReplace(RegisterRequestText, IndexBy,
			TMCommonUse.QuerySeparatorInJoin()
			+ QueryText
			+ IndexBy);
	EndIf;
	
EndProcedure

#EndRegion

#Region TextsOfCorrespondenceAnalyticsRequests

Function TextOfAnalyticsSampleFromTemporaryTable(ReplacingReverseWithReverse = False)
	
	If ReplacingReverseWithReverse Then
		QueryText = "
		|SELECT
		|	RegisterTable.Period AS Period,
		|	RegisterTable.RegisterName AS RegisterName,
		|	RegisterTable.Factor AS Factor,
		|	CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.ThisIsDebit
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN NOT RegisterTable.ThisIsDebit
		|		ELSE RegisterTable.ThisIsDebit
		|	END AS ThisIsDebit,
		|	CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.ThisIsLoan
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN NOT RegisterTable.ThisIsLoan
		|		ELSE RegisterTable.ThisIsLoan
		|	END AS ThisIsLoan,
		|	CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.ThisIsReverseTransaction
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN NOT RegisterTable.ThisIsReverseTransaction
		|		ELSE RegisterTable.ThisIsReverseTransaction
		|	END AS ThisIsReverseTransaction,
		|	&NestedTableAnalyticsFields,
		|	RegisterTable.Recorder AS Recorder,
		|	RegisterTable.Organization AS Organization,
		|	RegisterTable.Department AS Department,
		|	RegisterTable.LineOfBusiness AS LineOfBusiness,
		|	RegisterTable.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
		|	RegisterTable.FinRecordID AS FinRecordID,
		|	RegisterTable.RowID AS RowID,
		|	RegisterTable.Currency AS Currency,
		|	SUM(CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.SumMan
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN -RegisterTable.SumMan
		|		ELSE RegisterTable.SumMan
		|	END) AS SumMan,
		|	SUM(CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.SumCompl
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN -RegisterTable.SumCompl
		|		ELSE RegisterTable.SumCompl
		|	END) AS SumCompl,
		|	SUM(CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.SumCurr
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN -RegisterTable.SumCurr
		|		ELSE RegisterTable.SumCurr
		|	END) AS SumCurr,
		|	SUM(CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.Count
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN -RegisterTable.Count
		|		ELSE RegisterTable.Count
		|	END) AS Count
		|INTO NameOfRegisterCacheTable
		|FROM
		|	&DataSource AS RegisterTable
		|	LEFT JOIN TTDocumentsReplacingReverseWithReverse AS ReverseReplacementDocuments
		|		ON RegisterTable.Period = ReverseReplacementDocuments.Period
		|		 AND RegisterTable.Recorder = ReverseReplacementDocuments.Recorder
		|		 AND RegisterTable.FinRecordID = ReverseReplacementDocuments.FinRecordID
		|		 AND RegisterTable.Organization = ReverseReplacementDocuments.Organization
		|GROUP BY
		|	RegisterTable.Period,
		|	RegisterTable.RegisterName,
		|	RegisterTable.Factor,
		|	CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.ThisIsDebit
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN NOT RegisterTable.ThisIsDebit
		|		ELSE RegisterTable.ThisIsDebit
		|	END,
		|	CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.ThisIsLoan
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN NOT RegisterTable.ThisIsLoan
		|		ELSE RegisterTable.ThisIsLoan
		|	END,
		|	CASE
		|		WHEN ReverseReplacementDocuments.Recorder IS NULL
		|			THEN RegisterTable.ThisIsReverseTransaction
		|		WHEN RegisterTable.ThisIsReverseTransaction
		|			THEN NOT RegisterTable.ThisIsReverseTransaction
		|		ELSE RegisterTable.ThisIsReverseTransaction
		|	END,
		|	&NestedTableAnalyticsGroup,
		|	RegisterTable.Recorder,
		|	RegisterTable.Organization,
		|	RegisterTable.Department,
		|	RegisterTable.LineOfBusiness,
		|	RegisterTable.SettingUpBusinessTransaction,
		|	RegisterTable.FinRecordID,
		|	RegisterTable.RowID,
		|	RegisterTable.Currency
		|";
	Else
		QueryText = "
		|SELECT
		|	RegisterTable.Period AS Period,
		|	RegisterTable.RegisterName AS RegisterName,
		|	RegisterTable.Factor AS Factor,
		|	RegisterTable.ThisIsDebit AS ThisIsDebit,
		|	RegisterTable.ThisIsLoan AS ThisIsLoan,
		|	RegisterTable.ThisIsReverseTransaction AS ThisIsReverseTransaction,
		|	&AnalyticsSelectionFields,
		|	RegisterTable.Recorder AS Recorder,
		|	RegisterTable.Organization AS Organization,
		|	RegisterTable.Department AS Department,
		|	RegisterTable.LineOfBusiness AS LineOfBusiness,
		|	RegisterTable.SettingUpBusinessTransaction AS SettingUpBusinessTransaction,
		|	RegisterTable.FinRecordID AS FinRecordID,
		|	RegisterTable.RowID AS RowID,
		|	RegisterTable.Currency AS Currency,
		|	RegisterTable.SumMan AS SumMan,
		|	RegisterTable.SumCompl AS SumCompl,
		|	RegisterTable.SumCurr AS SumCurr,
		|	RegisterTable.Count AS Count
		|INTO NameOfRegisterCacheTable
		|FROM
		|	&DataSource AS RegisterTable
		|";
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region ServiceProceduresAndFunctionsForGeneratingQueryTexts

Function SampleRowsOfFieldsBasedOnIndicatorDescription(MotionReflectionParameters, DescriptionIndicator = Undefined) Export
	
	SelectionFields1 = New Structure(StrConcat(
		Enums.IndicatorsOfAnalyticalRegisters.SampleFieldsBasedOnIndicatorDescription(), ","));
	
	SourceAlias = MotionReflectionParameters.DataSourceAlias;
	
	If DescriptionIndicator <> Undefined Then
		Factor = DescriptionIndicator.Factor;
	Else
		Factor = Enums.IndicatorsOfAnalyticalRegisters.EmptyRef();
	EndIf;
	
	SelectionFields1.Factor = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Factor);
	
	If DescriptionIndicator <> Undefined And Not IsBlankString(DescriptionIndicator.DataPathRecordFinID) Then
		SelectionFields1.FinRecordID = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(
			DescriptionIndicator.DataPathRecordFinID);
	Else
		SelectionFields1.FinRecordID = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(
			MotionReflectionParameters.DataPathRecordFinID, SourceAlias);
	EndIf;
	If DescriptionIndicator <> Undefined And Not IsBlankString(DescriptionIndicator.DataPathRowId) Then
		SelectionFields1.RowID = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(
			DescriptionIndicator.DataPathRowId, SourceAlias);
	ElsIf Not IsBlankString(MotionReflectionParameters.DataPathRowId) Then
		SelectionFields1.RowID = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(
			MotionReflectionParameters.DataPathRowId, SourceAlias);
	Else
		SelectionFields1.RowID = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(
			MotionReflectionParameters.DataPathRowId);
	EndIf;
	If DescriptionIndicator <> Undefined And Not IsBlankString(DescriptionIndicator.ExpressionIsDebit) Then
		SelectionFields1.ThisIsDebit = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(
			DescriptionIndicator.ExpressionIsDebit, SourceAlias);
	ElsIf MotionReflectionParameters.ExpressionIsDebit = "FALSE" Then
		SelectionFields1.ThisIsDebit = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(False);
	Else
		SelectionFields1.ThisIsDebit = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(
			MotionReflectionParameters.ExpressionIsDebit, SourceAlias);
	EndIf;
	If DescriptionIndicator <> Undefined And Not IsBlankString(DescriptionIndicator.ExpressionIsLoan) Then
		SelectionFields1.ThisIsLoan = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(
			DescriptionIndicator.ExpressionIsLoan, SourceAlias);
	ElsIf MotionReflectionParameters.ExpressionIsLoan = "FALSE" Then
		SelectionFields1.ThisIsLoan = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(False);
	Else
		SelectionFields1.ThisIsLoan = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(
			MotionReflectionParameters.ExpressionIsLoan, SourceAlias);
	EndIf;
	
	If DescriptionIndicator <> Undefined
		And DescriptionIndicator.ManResources.Count() > 0 Then
		ManResource = FinancialAccountingByBalanceSheetRegisterData.ResourceSelectionString(DescriptionIndicator.ManResources);
	Else
		ManResource = FinancialAccountingByBalanceSheetRegisterData.ResourceSelectionString(MotionReflectionParameters.ManResources);
	EndIf;
	If DescriptionIndicator <> Undefined
		And DescriptionIndicator.LocalResources.Count() > 0 Then
		LocalResource = FinancialAccountingByBalanceSheetRegisterData.ResourceSelectionString(DescriptionIndicator.LocalResources);
	Else
		LocalResource = FinancialAccountingByBalanceSheetRegisterData.ResourceSelectionString(MotionReflectionParameters.LocalResources);
	EndIf;
	If DescriptionIndicator <> Undefined
		And DescriptionIndicator.ShaftResources.Count() > 0 Then
		ShaftResource = FinancialAccountingByBalanceSheetRegisterData.ResourceSelectionString(DescriptionIndicator.ShaftResources);
	Else
		ShaftResource = FinancialAccountingByBalanceSheetRegisterData.ResourceSelectionString(MotionReflectionParameters.ShaftResources);
	EndIf;
	If DescriptionIndicator <> Undefined
		And DescriptionIndicator.ResourcesQuantity.Count() > 0 Then
		ResourceQuantity = FinancialAccountingByBalanceSheetRegisterData.ResourceSelectionString(DescriptionIndicator.ResourcesQuantity);
	Else
		ResourceQuantity = FinancialAccountingByBalanceSheetRegisterData.ResourceSelectionString(MotionReflectionParameters.ResourcesQuantity);
	EndIf;
	
	AmountSampleTemplate = "CASE
	|		WHEN SUM(&Resource) < 0
	|			THEN -SUM(&Resource)
	|		ELSE SUM(&Resource)
	|	END";
	
	ConditionsOfStorno = New Array();
	ConditionsAreNotZero = New Array();
	
	SelectionFields1.SumMan = ResourceAmountSelectionString(ManResource, AmountSampleTemplate, ConditionsOfStorno, ConditionsAreNotZero);
	SelectionFields1.SumCompl = ResourceAmountSelectionString(LocalResource, AmountSampleTemplate, ConditionsOfStorno, ConditionsAreNotZero);
	SelectionFields1.SumCurr = ResourceAmountSelectionString(ShaftResource, AmountSampleTemplate, ConditionsOfStorno, ConditionsAreNotZero);
	SelectionFields1.Count = ResourceAmountSelectionString(ResourceQuantity, AmountSampleTemplate, ConditionsOfStorno, ConditionsAreNotZero);
	
	If ConditionsOfStorno.Count() = 0 Then
		ConditionsOfStorno.Add("FALSE");
	EndIf;
	
	If ConditionsAreNotZero.Count() = 0 Then
		ConditionsAreNotZero.Add("FALSE");
	EndIf;
	
	SelectionFields1.ThisIsReverseTransaction = "(" + StrConcat(ConditionsOfStorno, " OR ") + ")";
	SelectionFields1.ResourceValueCondition = "(" + StrConcat(ConditionsAreNotZero, " OR ") + ")";
	
	Return SelectionFields1;
	
EndFunction

Function ResourceAmountSelectionString(ResourceSelectionString, AmountSampleTemplate, ConditionsOfStorno, ConditionsAreNotZero)
	
	If ResourceSelectionString = "0" Then
		SumSelectionString = "0";
	Else
		SumSelectionString = StrReplace(AmountSampleTemplate, "&Resource", ResourceSelectionString);
	EndIf;
	
	If ResourceSelectionString <> "0" Then
		ConditionsOfStorno.Add(ResourceSelectionString + " < 0");
	EndIf;
	
	If ResourceSelectionString <> "0" Then
		ConditionsAreNotZero.Add(ResourceSelectionString + " <> 0");
	EndIf;
	
	Return SumSelectionString;
	
EndFunction

Procedure AddRegisterAnalyticsFields(RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterName)
	
	ExistingSelectionFields = New Array();
	ExistingSelectionFields.Add("Organization");
	ExistingSelectionFields.Add("Department");
	ExistingSelectionFields.Add("LineOfBusiness");
	ExistingSelectionFields.Add("Currency");
	
	If Not IsBlankString(RegisterName) Then
		RegisterManager = AccumulationRegisters[RegisterName]; // AccumulationRegisterManager -
		AccountingReflectionParameters = RegisterManager.ParametersForReflectingRegisteredRecordsInFinancialAccounting(); // See FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting
		
		RegisterAnalyticsStructure = AccountingReflectionParameters.StructureOfAnalytics; // See DataSourcesCached.AnalyticsStructureByTypeOfAccountingData
		If RegisterAnalyticsStructure.Count() = 0 Then
			RegisterAnalyticsStructure = DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(AccountingReflectionParameters.TypeOfAccountingData);
		EndIf;
		For Each DimDetails In RegisterAnalyticsStructure Do
			FieldName = DimDetails.Key;
			If ExistingSelectionFields.Find(FieldName) = Undefined Then
				If DimDetails.Value.Property("Value") Then
					DataPath = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(DimDetails.Value.Value);
				Else
					DataPath = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(DimDetails.Value.DataPath);
				EndIf;
				RowsOfAnalyticsFields.Add(DataPath + " AS " + FieldName);
				RowsOfAnalyticsGroups.Add(DataPath);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure AddAnalyticsFieldsToQueryText(RowsOfAnalyticsFields, RowsOfAnalyticsGroups, RegisterRequestText)

	LineSplitter = "," + Chars.LF + Chars.Tab;
	
	If RowsOfAnalyticsFields.Count() > 0 Then
		TextOfAnalyticsFields = StrConcat(RowsOfAnalyticsFields, LineSplitter);
	Else
		TextOfAnalyticsFields = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Undefined);
	EndIf;
	
	If RowsOfAnalyticsGroups.Count() > 0 Then
		TextOfAnalyticsGroup = StrConcat(RowsOfAnalyticsGroups, LineSplitter);
	Else
		TextOfAnalyticsGroup = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Undefined);
	EndIf;
	
	RegisterRequestText = StrReplace(RegisterRequestText, "&AnalyticsSelectionFields", TextOfAnalyticsFields);
	RegisterRequestText = StrReplace(RegisterRequestText, "&AnalyticsFieldGroup", TextOfAnalyticsGroup);
	
	If StrFind(RegisterRequestText, "&NestedTableAnalyticsFields") > 0 Then
		Separator = " AS ";
		SeparatorLength = StrLen(Separator);
		
		NestedTableFields = New Array();
		NestedTableGroups = New Array();
		
		For Each FieldSelectionString_ In RowsOfAnalyticsFields Do
			SeparatorPosition = StrFind(FieldSelectionString_, Separator, SearchDirection.FromEnd);
			FieldAlias = Mid(FieldSelectionString_, SeparatorPosition + SeparatorLength);
			
			DataPath = FinancialAccountingByBalanceSheetRegisterData.DataPathWithSourceAlias(FieldAlias);
			
			NestedTableFields.Add(DataPath + " AS " + FieldAlias);
			NestedTableGroups.Add(DataPath);
		EndDo;
	
		If NestedTableFields.Count() > 0 Then
			TextOfAnalyticsFields = StrConcat(NestedTableFields, LineSplitter);
		Else
			TextOfAnalyticsFields = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Undefined);
		EndIf;
		
		If NestedTableGroups.Count() > 0 Then
			TextOfAnalyticsGroup = StrConcat(NestedTableGroups, LineSplitter);
		Else
			TextOfAnalyticsGroup = FinancialAccountingByBalanceSheetRegisterData.ValueSelectionString(Undefined);
		EndIf;
		
		RegisterRequestText = StrReplace(RegisterRequestText, "&NestedTableAnalyticsFields", TextOfAnalyticsFields);
		RegisterRequestText = StrReplace(RegisterRequestText, "&NestedTableAnalyticsGroup", TextOfAnalyticsGroup);
	EndIf;
	
EndProcedure

Procedure AddCustomAnalyticsFieldsToQueryText(RowsOfAnalyticsFields, RowsOfAnalyticsGroups)
	
	AnalyticsField_ = "CASE
		|	WHEN VALUETYPE(RegisterTable.Recorder) IN (&TypesOfRetailSalesDocuments)
		|		THEN VALUE(Catalog.Partners.RetailCustomer)
		|	ELSE UNDEFINED
		|	END";
	RowsOfAnalyticsFields.Add(AnalyticsField_ + " AS Partner");
	RowsOfAnalyticsGroups.Add(AnalyticsField_);
	AnalyticsField_ = "CASE
		|	WHEN VALUETYPE(RegisterTable.Recorder) IN (&TypesOfRetailSalesDocuments)
		|		THEN VALUE(Catalog.Counterparties.RetailCustomer)
		|	ELSE UNDEFINED
		|	END";
	RowsOfAnalyticsFields.Add(AnalyticsField_ + " AS Counterparty");
	RowsOfAnalyticsGroups.Add(AnalyticsField_);
	
EndProcedure

#EndRegion

#Region Other

Function GetTableOfCorrespondenceOfOtherAssetsLiabilities(DocumentsForProcessing_, FactGettingParameters, RuleDescription_)
	
	DocumentsToBeProcessedAccordingToRule = DocumentsForProcessing_.Copy(New Structure("DocumentKind",
		Common.MetadataObjectID(Metadata.Documents.MovementOfOtherAssetsAndLiabilities)));
	If DocumentsToBeProcessedAccordingToRule.Count() = 0 Then
		Return Undefined;
	EndIf;

	DCSRegisteredRecordsOfOtherAssetsLiabilities = DataSourcesCached.GettingCatalogTemplate(
		"ActualDataQueryRulesByBudgetFlowItems", "FlowOfOtherAssetsAndLiabilities");
	DCSRegisteredRecordsOfOtherAssetsLiabilities = DataCompositionServer.CopyDataLayoutDiagram(
		DCSRegisteredRecordsOfOtherAssetsLiabilities); // DataCompositionSchema -

	Settings = DCSRegisteredRecordsOfOtherAssetsLiabilities.DefaultSettings;
	FinancialReportingServer.SetFilter(Settings.Filter, "Period", FactGettingParameters.Period.StartDate,
		DataCompositionComparisonType.GreaterOrEqual);
	FinancialReportingServer.SetFilter(Settings.Filter, "Period", FactGettingParameters.Period.EndDate,
		DataCompositionComparisonType.LessOrEqual);
	FinancialReportingServer.SetFilter(Settings.Filter, "SettingUpBusinessTransaction",
		RuleDescription_.DataSourceXO, DataCompositionComparisonType.Equal);
	DocumentsList = New ValueList;
	DocumentsList.LoadValues(DocumentsToBeProcessedAccordingToRule.UnloadColumn("Document"));
	FinancialReportingServer.SetFilter(Settings.Filter, "Recorder", DocumentsList,
		DataCompositionComparisonType.InList);

	DataTable = FinancialReportingServer.UploadDCSResults(DCSRegisteredRecordsOfOtherAssetsLiabilities, Settings); // ValueTable -
	If DataTable.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	TypesOfAccountingDataMatch = (RuleDescription_.TypeOfAccountingDataReceipt = RuleDescription_.TypeOfAccountingDataExpense);
	
	For Counter = 1 To 2 Do
		RecordType = ?(Counter = 1, "Receipt", "Expense");
		If RuleDescription_["TypeOfAccountingData" + RecordType] = Enums.AccountingDataTypes.IncomeExpenses Then
			DataTable.Columns["Department" + RecordType].Name = ?(TypesOfAccountingDataMatch, ?(Counter = 1,
				"DebitBusinessUnit", "Department"), "IncomeExpenseBusinessUnit");
			DataTable.Columns["LineOfBusiness" + RecordType].Name = ?(TypesOfAccountingDataMatch, ?(Counter
				= 1, "CorLineOfBusiness", "LineOfBusiness"), "LineOfBusinessOfIncomeExpenses");
			DataTable.Columns["IncomeAndExpenseItem" + RecordType].Name = ?(TypesOfAccountingDataMatch And Counter
				= 1, "CorIncomeExpenseItem", "IncomeAndExpenseItem");
			DataTable.Columns["DimensionOfRevenue" + RecordType].Name = ?(TypesOfAccountingDataMatch And Counter = 1,
				"CorIncomeDimension", "DimensionOfRevenue");
			DataTable.Columns["DimensionOfExpenses" + RecordType].Name = ?(TypesOfAccountingDataMatch And Counter = 1,
				"CorExpenditureDimension", "DimensionOfExpenses");
			DataTable.Columns.Delete("AssetAndLiabilityItem" + RecordType);
			DataTable.Columns.Delete("AssetsLiabilitiesDimension" + RecordType);
		Else
			DataTable.Columns["Department" + RecordType].Name = ?(TypesOfAccountingDataMatch, ?(Counter = 1,
				"DebitBusinessUnit", "Department"), "DivisionOfAssetsLiabilities");
			DataTable.Columns["LineOfBusiness" + RecordType].Name = ?(TypesOfAccountingDataMatch, ?(Counter
				= 1, "CorLineOfBusiness", "LineOfBusiness"), "LineOfBusinessOfAssetsLiabilities");
			DataTable.Columns["AssetAndLiabilityItem" + RecordType].Name = ?(TypesOfAccountingDataMatch And Counter
				= 1, "CorArticleOfAssetsLiabilities", "AssetAndLiabilityItem");
			DataTable.Columns["AssetsLiabilitiesDimension" + RecordType].Name = ?(TypesOfAccountingDataMatch And Counter
				= 1, "CorDimensionOfAssetsLiabilities", "AssetsLiabilitiesDimension");
			DataTable.Columns.Delete("IncomeAndExpenseItem" + RecordType);
			DataTable.Columns.Delete("DimensionOfRevenue" + RecordType);
			DataTable.Columns.Delete("DimensionOfExpenses" + RecordType);
		EndIf;
	EndDo;
	
	Return DataTable;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

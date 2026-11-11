#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load
	 Or CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	// In some documents, a Contract in online RegisteredRecords with a quantity is filled in with an empty link and remains so,
	// and when caching calculated sum Registered Records, empty links are reduced to an empty value (undefined),
	// which causes gaps in the "Contract" dimension to appear.
	// Typification of settlement movements takes place in See CostCalculationAppliedAlgorithms.CacheGeneratedRegisteredRecordsFromTemporaryTables
// ()
	For Each Record In ThisObject Do
		If Not ValueIsFilled(Record.Contract)
		 And Record.Contract <> Undefined Then
			Record.Contract = Undefined;
		EndIf;
	EndDo;
	
	If CostCalculationAppliedAlgorithms.GenerateRegisteredRecordsOfCostAccountingRegisters(ThisObject) Then
		
		// Let's keep the primary movements unchanged.
		SaveUnchangedPrimaryRegisteredRecords();
		
		// Let's save the calculated movements for the periods in which there are primary movements.
		CostCalculationAppliedAlgorithms.SaveRegisteredRecordsGeneratedByCalculationOfBatchesAndCosts(ThisObject, Replacing);
		
	EndIf;
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	// The current state of the set is placed in a temporary table
	// in order to get a change in the new set relative to the current one when writing.
	
	QueryTextsForGettingChangeTable = 
		MonthEndTransactionsServer.QueryTextsForCaseChangeTable(Metadata(), Filter);
	
	Query = New Query;
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text = QueryTextsForGettingChangeTable.InitialDataSampleText;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
	AdditionalProperties.Insert("SampleTextOfChangeTable", QueryTextsForGettingChangeTable.SampleTextOfChangeTable);
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		CreateNonOperationalQueueJobsWhenWriting();
		Return;
	EndIf;

	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
	 Or ExchangePlans.MasterNode() <> Undefined Then
		CreateNonOperationalQueueJobsWhenWriting();
		Return;
	ElsIf CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	CreateNonOperationalQueueJobsWhenWriting();
	
	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and is placed in a temporary table for subsequent recording in the task registers.
	Query = New Query;
	Query.Text = AdditionalProperties.SampleTextOfChangeTable;
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.Execute();
	
EndProcedure

#EndRegion

#Region Private

Procedure SaveUnchangedPrimaryRegisteredRecords()
	
	If CalculationOfCostCached.ValuesOfTechnologicalParameters().DoNotSaveCalculatedRegisteredRecords
	 Or AdditionalProperties.Property("DoNotSaveCalculatedRegisteredRecords") Then
		Return;
	EndIf;
	
	TypesOfResidueInput = OBEntryServer.AvailableTypesOfResidueInput();
	If TypesOfResidueInput.Find(TypeOf(Filter.Recorder.Value)) <> Undefined Then
		Return; // his movements are not adjusted by party accounting
	EndIf;
	
	If AdditionalProperties.Property("RecorderDate") Then
		RecorderDate = AdditionalProperties.RecorderDate;
	Else
		RecorderDate = Common.ObjectAttributeValue(Filter.Recorder.Value, "Date");
	EndIf;
	
	If Not CalculationOfCostCached.BatchAccountingVersion22(BegOfMonth(RecorderDate)) Then
		Return;
	EndIf;
	
	RecordsTable = ThisObject.Unload();
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Recorder", 				Filter.Recorder.Value);
	Query.SetParameter("RecordSet", 				RecordsTable);
	
	#Region QueryTextTemplates
	
	// We will prepare templates for the formation of query texts.
	ExceptionFields = New Structure("LineNumber, Active, Recorder, PointInTime");
	PartyFields     = New Structure("Lot, LotVendorAttributes, FinancialAccountingDimension, VATActivityType, CalculationIsNotCompleted");
	
	CaseFieldText_ = "";
	CaseFieldTextWithMinus = "";
	CaseFieldTextWithoutLots = "";
	TextOfDimensionFieldWithoutBatches = "";
	TextOfSummationField = "";
	ConditionFieldText = "";
	
	For Each CurrentColumn In RecordsTable.Columns Do
		
		If ExceptionFields.Property(CurrentColumn.Name) Then
			Continue;
		EndIf;
		
		ThisIsSummableField = Metadata().Resources.Find(CurrentColumn.Name) <> Undefined
			Or (Metadata().Attributes.Find(CurrentColumn.Name) <> Undefined
				And CurrentColumn.ValueType.ContainsType(Type("Number")));
		 
		CaseFieldText_ = CaseFieldText_ + ?(CaseFieldText_ = "", "", ",
			|	") + "T." + CurrentColumn.Name;
		CaseFieldTextWithMinus = CaseFieldTextWithMinus + ?(CaseFieldTextWithMinus = "", "", ",
			|	") + ?(ThisIsSummableField, "-", "") + "T." + CurrentColumn.Name;
			
		If ThisIsSummableField Then
			
			TextOfSummationField = TextOfSummationField + ?(TextOfSummationField = "", "", ",
				|	") + "SUM(T." + CurrentColumn.Name + ") AS " + CurrentColumn.Name;
			ConditionFieldText = ConditionFieldText + ?(ConditionFieldText = "", "", "
				|	OR ") + "SUM(T." + CurrentColumn.Name + ") <> 0";
			
		Else
			
			If Not PartyFields.Property(CurrentColumn.Name) Then
				
				CaseFieldTextWithoutLots = CaseFieldTextWithoutLots + ?(CaseFieldTextWithoutLots = "", "", ",
					|	") + "T." + CurrentColumn.Name;
				TextOfDimensionFieldWithoutBatches = TextOfDimensionFieldWithoutBatches + ?(TextOfDimensionFieldWithoutBatches = "", "", ",
					|	") + "T." + CurrentColumn.Name;
					
			Else
				
				CaseFieldTextWithoutLots = CaseFieldTextWithoutLots + ?(CaseFieldTextWithoutLots = "", "", ",
					|	") + "CASE WHEN T.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
					|		THEN T." + CurrentColumn.Name
					+ " ELSE UNDEFINED END AS " + CurrentColumn.Name;
				TextOfDimensionFieldWithoutBatches = TextOfDimensionFieldWithoutBatches + ?(TextOfDimensionFieldWithoutBatches = "", "", ",
					|	") + "CASE WHEN T.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
					|		THEN T." + CurrentColumn.Name
					+ " ELSE UNDEFINED END";
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	#EndRegion
	
	#Region CreatingTemporaryTables
	
	// Let's analyze the presence of altered primary movements in the context of periods (months).
	QueryTextTemplate2 =
	"SELECT
	|	&TextCaseFieldSelection
	|INTO TTRecordset
	|FROM
	|	&RecordSet AS T
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	&CaseFieldTextWithoutLots,
	|	&TextOfSummationField
	|INTO TTModifiedRegisteredRecords
	|FROM
	|
	|(SELECT
	|	CatProducts.ItemsType,
	|	TRUE AS InformationSecurityRegisteredRecords,
	|	&TextCaseFieldSelection
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS T
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS NomenclatureAnalysts
	|		ON T.ItemsLocationAttributes = NomenclatureAnalysts.Ref
	|	LEFT JOIN Catalog.Products AS CatProducts
	|		ON NomenclatureAnalysts.Products = CatProducts.Ref
	|WHERE
	|	T.Recorder = &Recorder
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|
	|UNION ALL
	|
	|SELECT
	|	CatProducts.ItemsType,
	|	FALSE AS InformationSecurityRegisteredRecords,
	|	&CaseFieldTextWithMinus
	|FROM
	|	TTRecordset AS T
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS NomenclatureAnalysts
	|		ON T.ItemsLocationAttributes = NomenclatureAnalysts.Ref
	|	LEFT JOIN Catalog.Products AS CatProducts
	|		ON NomenclatureAnalysts.Products = CatProducts.Ref
	|WHERE
	|	NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|) AS T
	|
	|GROUP BY
	|	&TextOfDimensionFieldWithoutBatches
	|HAVING
	|	&ConditionFieldText
	|	OR MAX(T.InformationSecurityRegisteredRecords) = FALSE
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	T.Period AS Period,
	|	MAX(T.ThereAreAlteredRegisteredRecords) AS ThereAreAlteredRegisteredRecords
	|INTO TTPeriodsOfRegisteredRecords
	|FROM
	|	(SELECT DISTINCT
	|		BEGINOFPERIOD(T.Period, MONTH) AS Period,
	|		FALSE AS ThereAreAlteredRegisteredRecords
	|	FROM
	|		TTRecordset AS T
	|	
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		BEGINOFPERIOD(T.Period, MONTH) AS Period,
	|		TRUE AS ThereAreAlteredRegisteredRecords
	|	FROM
	|		TTModifiedRegisteredRecords AS T
	|	) AS T
	|
	|GROUP BY
	|	T.Period
	|;
	|";
	
	Query.Text = StringFunctionsClientServer.SubstituteParametersToString(
		QueryTextTemplate2,
		CaseFieldText_,
		CaseFieldTextWithMinus,
		CaseFieldTextWithoutLots,
		TextOfSummationField,
		TextOfDimensionFieldWithoutBatches,
		ConditionFieldText);
		
	Query.Text = StrReplace(QueryTextTemplate2, "&TextCaseFieldSelection", CaseFieldText_);
	Query.Text = StrReplace(Query.Text, "&CaseFieldTextWithMinus", CaseFieldTextWithMinus);
	Query.Text = StrReplace(Query.Text, "&CaseFieldTextWithoutLots", CaseFieldTextWithoutLots);
	Query.Text = StrReplace(Query.Text, "&TextOfSummationField", TextOfSummationField);
	Query.Text = StrReplace(Query.Text, "&TextOfDimensionFieldWithoutBatches", TextOfDimensionFieldWithoutBatches);
	Query.Text = StrReplace(Query.Text, "&ConditionFieldText", ConditionFieldText);
		
	Query.Execute(); // let's form temporary tables with a description of the movements
	
	#EndRegion
	
	#Region PopulatingRecordSet
	
	// We will take the movements of the unchanged periods from the IB,
	// and the movements of the changed periods and calculated movements are from a set of records.
	QueryTextTemplate2 =
	"SELECT
	|	&Recorder AS Recorder,
	|	&CaseFieldText_
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS T
	|WHERE
	|	T.Recorder = &Recorder
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND BEGINOFPERIOD(T.Period, MONTH) IN
	|		(SELECT T.Period
	|		 FROM TTPeriodsOfRegisteredRecords AS T
	|		 WHERE NOT T.ThereAreAlteredRegisteredRecords)
	|
	|UNION ALL
	|
	|SELECT
	|	&Recorder AS Recorder,
	|	&CaseFieldText_
	|FROM
	|	TTRecordset AS T
	|WHERE
	|	NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND BEGINOFPERIOD(T.Period, MONTH) IN
	|		(SELECT T.Period
	|		 FROM TTPeriodsOfRegisteredRecords AS T
	|		 WHERE T.ThereAreAlteredRegisteredRecords)
	|";
	
	Query.Text = StrReplace(QueryTextTemplate2, "&CaseFieldText_", CaseFieldText_);
	
	RecordsTable = Query.Execute().Unload();
	
	ThisObject.Load(RecordsTable);
	
	#EndRegion
	
EndProcedure

#Region BackdateJobQueue

Procedure CreateNonOperationalQueueJobsWhenWriting()
	
	If AdditionalProperties.Property("DeferredPosting")
	 Or CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject)
	 Or Not CalculationOfCostCached.ThereAreDistributionSettingsForLinesOfBusiness()
	 Or Not BackdateJobQueue.CreationOfNonOperationalQueueTasksIsAvailable(ThisObject)
	 Or ThisObject.Count() = 0 Then
		Return;
	EndIf;
	
	If Not GetFunctionalOption("GenerateFinancialResult") 
	 Or Not GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
		Return;
	EndIf;
	
	TimeIntervals = ThisObject.Unload(, "Period");
	TimeIntervals.Indexes.Add("Period");
	TimeIntervals.GroupBy("Period");
	TimeIntervals.Sort("Period");
	
	If Not CalculationOfCostCached.BatchAccountingVersion22(BegOfMonth(TimeIntervals[0].Period)) Then
		Return;
	EndIf;

	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Text =
	"SELECT DISTINCT
	|	T.Recorder AS Document,
	|	T.Period AS TaskPeriod,
	|	T.AccountingDimensionByPartners.Organization AS Organization,
	|	VALUE(Catalog.BackdateJobKinds.DistributionOfSalesByLinesOfBusiness) AS JobKind
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS T
	|WHERE
	|	T.Recorder = &Recorder
	|	AND T.CounterpartyLineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|";

	DataForRegisteringTasks = Query.Execute().Unload();

	BackdateJobQueue.CreateNonOperationalQueueJobsWhenRecordingRecordset(
		ThisObject,
		Undefined,
		DataForRegisteringTasks);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf


#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If TypeOf(Parameters.CommandParameter) <> Type("DocumentRef.BudgetEntryForm") Then
		Cancel = True;
		Return;
	EndIf;
	
	StructureOfBudgetParameters = Common.ObjectAttributesValues(Parameters.CommandParameter,
		BudgetingClientServer.NamesOfBudgetAttributes());
	Period = New StandardPeriod(StructureOfBudgetParameters.Date, StructureOfBudgetParameters.Date);
	StructureOfBudgetParameters.Delete("Date");
	
	BudgetProfileDisplayParameters = BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView(
		StructureOfBudgetParameters.BudgetProfile, Enums.ModesOfBudgetReportGeneration.Document);
	ItemParameterCache = BudgetingServer.FillCacheOfArticleParameters(BudgetProfileDisplayParameters);
	StructureOfBudgetParameters.Delete("BudgetProfile");
	
	ArticlesAndTargets = New Array;
	NumberOfAnalysts = 0;
	RecordByCurrency = False;
	RecordByQuantity = False;
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For Each KeyAndValue In ItemParameterCache Do
		ArticlesAndTargets.Add(KeyAndValue.Key);
		For Counter = NumberOfAnalysts + 1 To MaximumNumberOfAnalysts Do
			If ValueIsFilled(KeyAndValue.Value["DimensionKind"+Counter]) Then
				NumberOfAnalysts = Counter;
			EndIf;
		EndDo;
		If Not RecordByCurrency Then
			RecordByCurrency = KeyAndValue.Value.RecordByCurrency;
		EndIf;
		If Not RecordByQuantity Then
			RecordByQuantity = KeyAndValue.Value.RecordByQuantity;
		EndIf;
	EndDo;
	StructureOfBudgetParameters.Insert("ArticlesAndTargets", ArticlesAndTargets);
	
	DCS = Documents.BudgetEntryForm.GetTemplate("AdjustmentDataCompositionSchemaByBudgetFlowItems");
	For Each Parameter In StructureOfBudgetParameters Do
		DataCompositionServer.SetDCSParameter(DCS, Parameter.Key, Parameter.Value);
	EndDo;
	AddressOfDataCompositionSchema = PutToTempStorage(DCS, UUID);
	
	Settings = DCS.DefaultSettings;
	
	ScenarioCurrency = Common.ObjectAttributeValue(StructureOfBudgetParameters.Scenario, "Currency");
	MatchingCurrencies = New Map;
	MatchingCurrencies.Insert("1", TrimAll(ScenarioCurrency));
	DataCompositionServer.SetHeadersOfSelectedFields(Settings.Selection.Items, MatchingCurrencies);
	
	ReportsServer.InitializeSettingsComposer(SettingsComposer, DCS);
	SettingsComposer.LoadSettings(Settings);
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "Period", Period, True);
	
	For Counter = NumberOfAnalysts + 1 To MaximumNumberOfAnalysts Do
		DataCompositionServer.RemoveDimensionFromAllReportSettings(SettingsComposer, "Dimension"+Counter);
	EndDo;
	If Not RecordByCurrency Then
		DataCompositionServer.RemoveDimensionFromAllReportSettings(SettingsComposer, "Currency");
		FieldNamesToDelete = StrSplit(
			"AmountInCurrencyOpeningBalance,AmountInCurrencyTurnover,AmountInCurrencyClosingBalance,AmountInCurrencyPercentage", ",");
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(SettingsComposer, FieldNamesToDelete);
	EndIf;
	If Not RecordByQuantity Then
		FieldNamesToDelete = StrSplit(
			"CountOpeningBalance,CountTurnover,CountClosingBalance,QuantityPercentage", ",");
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(SettingsComposer, FieldNamesToDelete);
	EndIf;
	
	DetailsDataAddress = PutToTempStorage(Undefined, UUID);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodOnChange(Item)
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "Period", Period, True);
	
EndProcedure

&AtClient
Procedure TabDocumentDecryptionProcessing(Item, Details, StandardProcessing, AdditionalParameters)
	
	StandardProcessing = False;
	
	DetailsValue = BudgetingServerCall.ReportDetailsData(Details, DetailsDataAddress);
	If DetailsValue.MainAction = DataCompositionDetailsProcessingAction.OpenValue Then
		For Each KeyAndValue In DetailsValue.DecryptionFields Do
			ShowValue(, KeyAndValue.Value);
			Break;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"Document.BudgetEntryForm.Form.BudgetAdjustmentsAndCorrections.Generate",,
		True);
	
	ClearMessages();
	
	TimeConsumingOperation = GenerateAdjustmentReportForBudgetItems();
	
	If TimeConsumingOperation <> Undefined Then
		CallbackOnCompletion = New CallbackDescription("AfterEndOfTask", ThisObject);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputMessages = True;
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function PrepareReportParameters()
	
	ReportParameters = Common.CopyRecursive(StructureOfBudgetParameters);
	ReportParameters.Insert("DataCompositionSchema", GetFromTempStorage(AddressOfDataCompositionSchema));
	ReportParameters.Insert("DataCompositionSettings", SettingsComposer.GetSettings());
	
	Return ReportParameters;
	
EndFunction

&AtServer
Function GenerateAdjustmentReportForBudgetItems()
	
	If ValueIsFilled(JobID) Then
		TimeConsumingOperations.CancelJobExecution(JobID);
	EndIf;
	
	If Not CheckFilling() Then 
		Return Undefined;
	EndIf;
	
	JobID = Undefined;
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
	
	ReportParameters = PrepareReportParameters();
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr(
		"vi = 'Nhận dữ liệu về điều chỉnh và chỉnh sửa ngân sách';
		|ru = 'Получение данных по корректировкам и исправлениям бюджета';
		|en = 'Getting budget adjustment and correction data'; fa = 'Getting budget adjustment and correction data';
		|it = 'Получение данных по корректировкам и исправлениям бюджета';
		|pl = 'Getting budget adjustment and correction data';
		|tr = 'Bütçe değişikliklerine ve düzeltmelerine dair verilerin elde edilmesi'");
	
	StorageAddress = PutToTempStorage(Undefined, UUID);

	TimeConsumingOperation = TimeConsumingOperations.ExecuteProcedure(
		ExecutionParameters,
		"Documents.BudgetEntryForm.GetDataOnBudgetAdjustmentsCorrections",
		ReportParameters, StorageAddress);

	Return TimeConsumingOperation;

EndFunction

&AtServer
Procedure LoadPreparedData()
	
	BudgetData = GetFromTempStorage(StorageAddress);
	Result = BudgetData.ResultDocument;
	DetailsDataAddress = PutToTempStorage(BudgetData.DetailsData, UUID);
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
	
EndProcedure

&AtClient
Procedure AfterEndOfTask(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("Structure") Then
		
		If Result.Property("Messages") And Result.Messages <> Undefined Then
			For Each Message In Result.Messages Do
				Message.Message();
			EndDo;
		EndIf;
		
		If Result.Property("Status") Then
			If Result.Status = "Error" Then
				CommonClient.MessageToUser(Result.BriefErrorDescription);
			ElsIf Result.Status = "Completed2" Then
				JobID = Undefined;
				LoadPreparedData();
			EndIf;
		EndIf;
	EndIf;

EndProcedure

#EndRegion
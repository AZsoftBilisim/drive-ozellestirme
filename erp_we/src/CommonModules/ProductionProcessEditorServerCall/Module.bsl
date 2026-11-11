////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of the Production Process Editor
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region ProductionStage

// Returns parameters of the Standard stage process.
// 
// Parameters:
//  Stage - DocumentRef.ProductionStage2_2
// 
// Returns:
//  See ProductionProcessEditorClientServer.ProcessParametersConstructor 
Function StandardStageProcessTechnology(Stage) Export
	
	Return ParametersOfTechnicalProcessOfStage(Stage, True);
	
EndFunction

Function ParametersOfTechnicalProcessOfStage(Stage, StandardProcessTechnology = False) Export
	
	TechProcessParameters = ProductionProcessEditorClientServer.ProcessParametersConstructor();
	
	QueryText = "
	|SELECT
	|	&TechProcessParameters
	|FROM
	|	Document.ProductionStage2_2 AS DocumentAttributes
	|		LEFT JOIN InformationRegister.TechnologicalProcessesOfProductionStages AS TechnicalProcess
	|		ON DocumentAttributes.Ref = TechnicalProcess.Stage
	|			AND NOT &StandardProcessTechnology
	|WHERE
	|	DocumentAttributes.Ref = &Stage
	|";
	
	QueryText = StrReplace(QueryText,
		"&TechProcessParameters",
		ProductionProcessEditor.QueryTextParametersOfTechnicalProcessOfStage());
		
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Stage", Stage);
	Query.SetParameter("StandardProcessTechnology", StandardProcessTechnology);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(TechProcessParameters, Selection);
	EndIf;
	
	Return TechProcessParameters;
	
EndFunction

Procedure SwitchToIndividualProcessTechnology(Stage, Cancel) Export
	
	QueryText = "
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.ProductionOperation2_2 AS T
	|WHERE
	|	T.Posted
	|	AND T.Stage = &Stage
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE
	|FROM
	|	InformationRegister.OperationsToCreateShiftTasks AS T
	|WHERE
	|	T.Stage = &Stage
	|	AND T.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Stage", Stage);
	
	If Not Query.Execute().IsEmpty() Then
		Common.MessageToUser(
			NStr("vi = 'Công đoạn này đã có các thao tác được chỉ định. Không thể chuyển sang chế độ riêng biệt.';
				|ru = 'У этапа есть назначенные операции. Переключение в индивидуальный режим невозможно.';
				|en = 'The stage has assigned operations. Cannot switch to individual mode.'; fa = 'The stage has assigned operations. Cannot switch to individual mode.';
				|it = 'The stage has assigned operations. Cannot switch to individual mode.';
				|pl = 'The stage has assigned operations. Cannot switch to individual mode.';
				|tr = 'Aşamanın atanan işlemleri vardır. Özelleştirilmiş moda geçiş mümkün değildir.'"),,,,Cancel);
		Return;
	EndIf;
	
	Data_Stage = Documents.ProductionStage2_2.DataForCalculatingOperationQueue(Stage, False)[Stage];
	
	If Data_Stage.TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.Individual_ Then
		Common.MessageToUser(
			NStr("vi = 'Quy trình công nghệ của công đoạn này đã ở chế độ riêng biệt.';
				|ru = 'Технологический процесс этапа уже находится в индивидуальном режиме.';
				|en = 'The technological process of the stage is already in individual mode.'; fa = 'The technological process of the stage is already in individual mode.';
				|it = 'The technological process of the stage is already in individual mode.';
				|pl = 'The technological process of the stage is already in individual mode.';
				|tr = 'Aşamanın teknolojik süreci halihazırda özelleştirilmiş moddadır.'"),,,,Cancel);
		Return;
	EndIf;
	
	Data_Stage.Insert("Operations", InformationRegisters.QueueOfProductionOperations.ListOfOperationsAccordingToStageData(Data_Stage));
	
	BeginTransaction();
	Try
		
		Record = InformationRegisters.TechnologicalProcessesOfProductionStages.CreateRecordManager();
		Record.Stage = Stage;
		Record.Read();
		If Not Record.Selected() Then
			Record.Stage = Stage;
		EndIf;
		Record.TechnologicalProcess = Undefined;
		Record.TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.Individual_;
		Record.TechnologicalProcessFactor = 1;
		Record.Write();
		
		InformationRegisters.QueueOfProductionOperations.CalculateQueueBasedOnStageData(
			Stage, Data_Stage, InformationRegisters.QueueOfProductionOperations.QueueCalculationParameters());
		
		CommitTransaction();
	Except
		RollbackTransaction();
		MessageText = StrTemplate(NStr("vi = 'Lỗi tính toán hàng đợi các giao dịch của công đoạn. %1';
										|ru = 'Ошибка расчета очереди операций этапа. %1';
										|en = 'An error occurred while calculating the stage operation queue. %1'; fa = 'An error occurred while calculating the stage operation queue. %1';
										|it = 'An error occurred while calculating the stage operation queue. %1';
										|pl = 'An error occurred while calculating the stage operation queue. %1';
										|tr = 'Aşama işlemleri kuyruğu hesaplanırken hata oluştu. %1'"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Common.MessageToUser(MessageText,,,,Cancel);
		Cancel = True;
	EndTry;
	
EndProcedure

#EndRegion

#Region TechnologicalOperation

// The data of the choice of operation according to the classifier.
// 
// Parameters:
//  FieldForSearch - String
//  Text - String
// 
// Returns:
//  ValueList of CatalogRef.ManufacturingOperationClassifier
Function ClassifierOperationSelectionData(FieldForSearch, Text) Export
	
	ChoiceData = New ValueList;
	
	If Not IsBlankString(Text) Then
	
		QueryText = "
		|SELECT ALLOWED TOP 51
		|	Classifier.Ref       AS Ref,
		|	Classifier.Code          AS Code,
		|	Classifier.Description AS Description
		|FROM
		|	Catalog.ManufacturingOperationClassifier AS Classifier
		|WHERE
		|	&FieldForSearch LIKE &SearchText
		|	AND NOT Classifier.IsFolder
		|	AND NOT Classifier.DeletionMark
		|
		|ORDER BY
		|	&FieldForSearch";
		
		QueryText = StrReplace(QueryText,
			"&FieldForSearch",
			StrTemplate("Classifier.%1", FieldForSearch));
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("SearchText", Text+"%");
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			ChoiceData.Add(Selection.Ref, StrTemplate("%1 (%2)", Selection.Description, Selection.Code));
			
		EndDo;
	
	EndIf;
	
	Return ChoiceData;
	
EndFunction

#EndRegion

#Region Editor

// Start recording process data.
// 
// Parameters:
//  DataToEndEditing - Structure - data to create
//  UID - UUID
// 
// Returns:
//  See TimeConsumingOperations.ExecuteInBackground
Function StartRecordingProcessData(DataToEndEditing, UID) Export
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UID);
	ExecutionParameters.RunInBackground    = True;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = ProductionProcessEditorClientServer.BackgroundDataRecordingOperation();
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.ProductionProcessEditor.RecordEditorDataInBackground",
		GetFromTempStorage(DataToEndEditing.AddressOfProcessRecordingParameters),
		ExecutionParameters);
	
EndFunction

// Start creating a typical process technology.
// 
// Parameters:
//  DataForCreatingTechnicalProcess - Structure - data to create
//  UID - UUID
// 
// Returns:
//  See TimeConsumingOperations.ExecuteInBackground
Function StartCreatingTypicalProcessTechnology(DataForCreatingTechnicalProcess, UID) Export
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UID);
	ExecutionParameters.RunInBackground    = True;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = ProductionProcessEditorClientServer.BackgroundOperationCreatingProcess();
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.ProductionProcessEditor.CreateTypicalTechnicalProcessInBackground",
		GetFromTempStorage(DataForCreatingTechnicalProcess.AddressOfParametersForCreatingTypicalTechnicalProcess),
		ExecutionParameters);
	
EndFunction

#EndRegion

#EndRegion
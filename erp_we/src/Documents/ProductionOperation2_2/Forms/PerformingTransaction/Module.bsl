
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("Mode",                    Mode);
	Parameters.Property("ProductionOperation", ProductionOperation);
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Operation");
	AttributesStructure1.Insert("OperationName_", "Description");
	AttributesStructure1.Insert("OperationAsOutputReference");
	AttributesStructure1.Insert("QuantityToPerform");
	AttributesStructure1.Insert("OperationID");
	AttributesStructure1.Insert("Organization");
	AttributesStructure1.Insert("Department");
	AttributesStructure1.Insert("RoutesOperationDate", "Date");
	AttributesStructure1.Insert("RoutingOperationCompletionOfExecution", "ExecutionEnd");
	AttributesStructure1.Insert("ShiftTask");
	AttributesStructure1.Insert("ShiftTaskDate", "ShiftTask.Date");
	
	For Each KeyAndValue In AttributesStructure1 Do
		If Parameters.Property(KeyAndValue.Key, ThisObject[KeyAndValue.Key]) Then
			AttributesStructure1.Delete(KeyAndValue.Key);
		EndIf;
	EndDo;
	
	If AttributesStructure1.Count() > 0 Then
		ValueOfBankingDetails = Common.ObjectAttributesValues(ProductionOperation, AttributesStructure1);
		FillPropertyValues(ThisObject, ValueOfBankingDetails);
	EndIf;
	
	If Not ValueIsFilled(OperationName_) Then
		OperationName_ = Operation;
	EndIf;
	
	If Not Parameters.Property("UnitOfMeasurePresentation", UnitOfMeasurePresentation) Then
		UnitOfMeasurePresentation = ProductionManagementClientServer.PresentationOfUnitOfOperation(
			Undefined,
			QuantityToPerform);
	EndIf;
	
	FillInListOfDefectiveGoodsReasons();
	
	FillInListOfPreviousOperations(Parameters);
	
	CustomizeFormElements();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CountOnChange(Item)
	
	PreviousOperationsCalculateAmountToBePerformed(ThisObject);
	
	CalculateAttributeRecalculateStandards(ThisObject);
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure ReasonOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPreviousOperations_

&AtClient
Procedure PreviousOperations_MarkOnChange(Item)
	
	CurrentData = Items.PreviousOperations_.CurrentData;
	
	PreviousOperations_Count = PreviousOperations_Count + ?(CurrentData.Mark, 1, -1);
	
EndProcedure

&AtClient
Procedure PerformPreviousOperationsWhenChanging(Item)
	
	CurrentData = Items.PreviousOperations_.CurrentData; 
	
	CurrentData.NumberOfManualInput = ?(CurrentData.Count = 0, False, True);
	
EndProcedure

&AtClient
Procedure PreviousOperations_PerformerStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.PreviousOperations_.CurrentData; // FormDataCollectionItem
	
	CallbackDescription = New CallbackDescription("PreviousOperationsOfOperationsStartSelectionEnd", ThisObject);
	
	ProductionClient.OpenArtistSelectionForm(
		Organization, Department, CurrentData.Performer, DateForDeterminingContractor(),, CallbackDescription);
	
EndProcedure

&AtClient
Procedure PreviousOperations_PerformerAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(
			ChoiceData, Text, Department, DateForDeterminingContractor());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PreviousOperations_PerformerTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(
			ChoiceData, Text, Department, DateForDeterminingContractor());
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	AllocateBalance("QuantityIsReady");
	
EndProcedure

&AtClient
Procedure DefectiveGoods(Command)
	
	AllocateBalance("DefectiveGoodsCount");
	
EndProcedure

&AtClient
Procedure Canceled(Command)
	
	AllocateBalance("CountCanceled");
	
EndProcedure

&AtClient
Procedure Apply(Command)
	
	If CheckAttributesFilling() Then
		
		Result = New Structure;
		Result.Insert("ProtocolEntries", New Array);
		Result.Insert("RecalculateStandards", RecalculateStandards);
		
		If DefectiveGoodsCount > 0 Then
			
			If Mode = "Perform" Or Mode = "ExecuteControl" Then
				PreviousState = "QuantityToPerform";
			ElsIf Mode = "OnControl" Then
				PreviousState = "QuantityUnderRevision";
			EndIf;
			
			NewAction = ProductionAccountingClientServer.RecordProtocolConstructor("DefectiveGoods");
			NewAction.PreviousState = PreviousState;
			NewAction.Count  = DefectiveGoodsCount;
			NewAction.Comment = DefectsReason;
			Result.ProtocolEntries.Add(NewAction);
			
		EndIf;
		
		If QuantityIsReady > 0 Then
			
			If Mode = "Perform" Or Mode = "ExecuteControl" Then
				NewAction = ProductionAccountingClientServer.RecordProtocolConstructor("Perform");
				NewAction.Count  = QuantityIsReady;
				Result.ProtocolEntries.Add(NewAction);
			EndIf;
			
			If Mode = "ExecuteControl" Then
				NewAction = ProductionAccountingClientServer.RecordProtocolConstructor("Control");
				NewAction.Count  = QuantityIsReady;
				Result.ProtocolEntries.Add(NewAction);
			EndIf;
			
			If Mode = "OnControl" Then
				NewAction = ProductionAccountingClientServer.RecordProtocolConstructor("PresentForControl");
				NewAction.Count  = QuantityIsReady;
				Result.ProtocolEntries.Add(NewAction);
			EndIf;
			
		EndIf;
		
		If CountCanceled > 0 Then
			
			NewAction = ProductionAccountingClientServer.RecordProtocolConstructor("Cancel");
			NewAction.Count = CountCanceled;
			Result.ProtocolEntries.Add(NewAction);
			
		EndIf;
		
		If PreviousOperations_.Count() > 0
			And PreviousOperationsHaveNumberToPerform(ThisObject) > 0 Then
			StartPerformingPreviousOperations(Result);
		Else
			Close(Result);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckAll(Command)
	
	For Each String In PreviousOperations_ Do
		String.Mark = True;
	EndDo;
	
	PreviousOperations_Count = PreviousOperations_.Count();
	
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	For Each String In PreviousOperations_ Do
		String.Mark = False;
	EndDo;
	
	PreviousOperations_Count = 0;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	If Mode = "OnControl" Then
		
		ThereArePreviousOperations = False;
		
		Items.GroupCanceled.Visible = False;
		Items.Canceled.Visible = False;
		
		Title = StrTemplate(NStr("vi = 'Trình bày để kiểm soát giao dịch ""%1""';
								|ru = 'Предъявление к контролю операции ""%1""';
								|en = 'Present the ""%1"" operation for control'; fa = 'Present the ""%1"" operation for control';
								|it = 'Presentazione al controllo dell''operazione ""%1""';
								|pl = 'Przedstawienie do kontroli operacji ""%1""';
								|tr = '""%1"" işleminin kontrole sunulması'"), OperationName_);
		
	Else
		
		ThereArePreviousOperations = PreviousOperations_.Count() > 0;
		
		Title = StrTemplate(NStr("vi = 'Thực hiện giao dịch ""%1""';
								|ru = 'Выполнение операции ""%1""';
								|en = 'Execute the ""%1"" operation'; fa = 'Execute the ""%1"" operation';
								|it = 'Esecuzione operazioni ""%1""';
								|pl = 'Wykonanie operacji ""%1""';
								|tr = '""%1"" işleminin gerçekleştirilmesi'"), OperationName_);
		
	EndIf;
	
	Items.CurCurrentOperationGroup.ShowTitle = ThereArePreviousOperations;
	Items.GroupOfOperationsToBePerformed.Visible = ThereArePreviousOperations;
	
	SetUpMarriageReflectionElements();
	
	SetUpRecalculateStandardsSwitch();
	
	WindowOptionsKey = StrTemplate("%1%2", FormName, ?(ThereArePreviousOperations,"1","2"));
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If Initialize
		Or AttributesStructure1.Property("Count") Then
			
		UpdateQuantityToDistribution(Form);
		
		Items.DefectiveGoodsCount.MaxValue      = Form.DefectiveGoodsCount + Form.QuantityToDistribution;
		Items.QuantityIsReady.MaxValue    = Form.QuantityIsReady + Form.QuantityToDistribution;
		Items.CountCanceled.MaxValue  = Form.CountCanceled + Form.QuantityToDistribution;
		
		Items.GroupQuickCommands.Enabled         = Form.QuantityToDistribution > 0;
		Items.FormApply.Enabled = (Form.QuantityIsReady > 0 Or Form.DefectiveGoodsCount > 0 Or Form.CountCanceled > 0);
		
	EndIf;
	
	If Initialize
		Or AttributesStructure1.Property("InfoBar") Then
			
			Items.InformationPanelGroup.Visible = ValueIsFilled(Items.InfoBarLabel.Title);
			
	EndIf;
	
EndProcedure

&AtServer
Procedure SetUpMarriageReflectionElements()
	
	Items.DefectiveGoods.Enabled = OperationAsOutputReference;
	Items.DefectiveGoodsGroup.Enabled = OperationAsOutputReference;
	
	If Not OperationAsOutputReference Then
		Items.InfoBarLabel.Title = Documents.ProductionOperation2_2.WarningTextUnavailabilityOfMarriageReflection();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetUpRecalculateStandardsSwitch()
	
	Settings = Documents.ProductionOperation2_2.RecalculateStandardsSwitchSettings(ProductionOperation);
	
	Items.RecalculateStandards.Visible = Settings.Visible;
	Items.RecalculateStandards.Title = Settings.Title;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateQuantityToDistribution(Form)
	
	Form.QuantityToDistribution = Form.QuantityToPerform
		- Form.DefectiveGoodsCount
		- Form.QuantityIsReady
		- Form.CountCanceled;
	
EndProcedure

&AtClient
Procedure AllocateBalance(Var_AttributeName)
	
	ThisObject[Var_AttributeName] = ThisObject[Var_AttributeName] + QuantityToDistribution;
	CurrentItem = Items[Var_AttributeName];
	
	PreviousOperationsCalculateAmountToBePerformed(ThisObject);
	
	CalculateAttributeRecalculateStandards(ThisObject);
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInListOfDefectiveGoodsReasons()
	
	QueryText = "
	|SELECT TOP 50
	|	Table.Comment AS Comment
	|FROM
	|	Document.ProductionOperation2_2.Protocol AS Table
	|WHERE
	|	Table.Event = VALUE(Enum.RoutingOperationProtocolEvents.DefectiveGoods)
	|	AND Table.Comment <> """"
	|	AND Table.Ref.Posted
	|ORDER BY
	|	Table.Date DESC
	|";
	
	Query = New Query(QueryText);
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		While Selection.Next() Do
			CurrentList = Items.DefectsReason.ChoiceList;
			If CurrentList.FindByValue(Selection.Comment) = Undefined Then
				CurrentList.Add(Selection.Comment);
				If CurrentList.Count() >= 5 Then
					Break;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Function CheckAttributesFilling()
	
	TextQuantityExceeded = NStr("vi = 'Vượt quá số lượng được phép thực hiện';
								|ru = 'Превышено доступное к выполнению количество';
								|en = 'The quantity available for execution is exceeded'; fa = 'The quantity available for execution is exceeded';
								|it = 'Numero disponibile per l''esecuzione superato';
								|pl = 'Przekroczono dostępną do wykonania ilość';
								|tr = 'Gerçekleştirilebilecek mevcut miktar aşıldı'");
	
	HasErrors = False;
	
	If (DefectiveGoodsCount + QuantityIsReady + CountCanceled) > QuantityToPerform Then
		CommonClient.MessageToUser(
			TextQuantityExceeded,,
			"QuantityToPerform",,
			HasErrors);
	EndIf;
	
	For Each String In PreviousOperations_ Do
		If String.Mark
				And String.Count > String.canExecute Then
			CommonClient.MessageToUser(
				TextQuantityExceeded,,
				StrTemplate("PreviousOperations_[%1].Count", PreviousOperations_.IndexOf(String)),,
				HasErrors);
		EndIf;
	EndDo;
	
	For Each String In PreviousOperations_ Do

	EndDo;
	
	Return Not HasErrors;
	
EndFunction

&AtServer
Procedure FillInListOfPreviousOperations(Var_Parameters) 
	
	If Mode = "OnControl"
			Or Var_Parameters.UseShiftTasks Then
		Return;
	EndIf;
	
	RequestTextParameters = InformationRegisters.QueueOfProductionOperations.RequestTextParametersQueueOfOperations();
	RequestTextParameters.ExecutionIndicators = True;
	RequestTextParameters.ExtendedAttributesOfOperations = True;
	RequestTextParameters.OutputTableName = "TTQueue";
	RequestTextParameters.Filters.Add("Queue.Stage = &Stage");
	
	QueryText = InformationRegisters.QueueOfProductionOperations.QueryTextOperationQueue(RequestTextParameters) + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	T.Required2                                    AS Required2,
	|	T.Scheduled - T.RepetitionIsRequired          AS Scheduled,
	|	&Processed                                    AS Processed
	|
	|FROM
	|	TTQueue AS T
	|WHERE
	|	T.OperationID = &OperationID
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Operation                                          AS Operation,
	|	T.ProductionOperation                          AS ProductionOperation,
	|	T.OperationID                             AS OperationID,
	|	T.Description                                      AS Description,
	|	T.OperationNumber                                     AS OperationNumber,
	|
	|	&Stage                                               AS Stage,
	|	&Department                                      AS Department,
	|	&Performer                                        AS Performer,
	|	CASE
	|		WHEN ISNULL(T.Operation.ProductionArea, VALUE(Catalog.ProductionSites.EmptyRef)) <> VALUE(Catalog.ProductionSites.EmptyRef) THEN
	|			T.Operation.ProductionArea
	|		ELSE &ProductionArea
	|	END                                               AS ProductionArea,
	|
	|	T.Required2                                         AS Required2,
	|	T.Scheduled - T.RepetitionIsRequired               AS Scheduled,
	|	&Processed                                         AS Processed,
	|	&canExecute                                     AS canExecute
	|
	|FROM
	|	TTQueue AS T
	|
	|	INNER JOIN TTQueue AS CurrentOperation
	|	ON CurrentOperation.OperationID = &OperationID
	|		AND T.OperationNumber < CurrentOperation.OperationNumber
	|
	|WHERE
	|	&canExecute > 0
	|
	|ORDER BY
	|	T.OperationNumber
	|";
	
	TextCanBeExecuted = "(T.Scheduled - T.RepetitionIsRequired) - &Processed";
	TextProcessed     = "(T.Completed2 + T.DefectiveGoods + T.UnderControl + T.UnderRevision + T.Skipped3)";
	
	QueryText = StrReplace(QueryText, "&canExecute", TextCanBeExecuted);
	QueryText = StrReplace(QueryText, "&Processed", TextProcessed);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Operation",              Operation);
	Query.SetParameter("OperationID", OperationID);
	Query.SetParameter("Stage",                  Var_Parameters.Stage);
	Query.SetParameter("Department",         Var_Parameters.Department);
	Query.SetParameter("Performer",           Var_Parameters.Performer);
	Query.SetParameter("ProductionArea",               Var_Parameters.ProductionArea);
	Query.SetParameter("QuantityToPerform", QuantityToPerform);
	
	Results = Query.ExecuteBatch();
	
	Selection = Results[Results.UBound()-1].Select();
	Selection.Next();
	CurOperationData = New Structure("Required2,Scheduled,Processed");
	FillPropertyValues(CurOperationData, Selection);
	
	PreviousOperations_.Load(Results[Results.UBound()].Unload());
	
EndProcedure

&AtClientAtServerNoContext
Procedure PreviousOperationsCalculateAmountToBePerformed(Form)
	
	If Not Form.ThereArePreviousOperations Then
		Return;
	EndIf;
	
	ZoomRatio = (Form.CurOperationData.Processed + Form.QuantityIsReady + Form.DefectiveGoodsCount) / Form.CurOperationData.Scheduled;
	
	For Each String In Form.PreviousOperations_ Do
		If Not String.NumberOfManualInput Then
			RowCoefficient = String.Processed/String.Scheduled;
			If ZoomRatio > RowCoefficient Then
				String.Count = Min(String.Scheduled * (ZoomRatio-RowCoefficient), String.canExecute);
			Else
				String.Count = 0;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function PreviousOperationsHaveNumberToPerform(Form)
	
	For Each String In Form.PreviousOperations_ Do
		If String.Mark And String.Count > 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Procedure StartPerformingPreviousOperations(ExecutionResult)
	
	If TimeConsumingOperation <> Undefined Then
		Return;
	EndIf;
	
	StartPerformingPreviousOperationsOnServer();
	
	If TimeConsumingOperation <> Undefined Then
		
		CallbackDescription = New CallbackDescription(
			"ExecutionOfPreviousOperationsEnd",
			ThisObject,
			ExecutionResult);
			
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = True;
		IdleParameters.MessageText = NStr("vi = 'Đang thực hiện các giao dịch trước đó...';
											|ru = 'Выполняются предыдущие операции...';
											|en = 'Previous operations are being executed...'; fa = 'Previous operations are being executed...';
											|it = 'Precedenti operazioni in corso...';
											|pl = 'Są wykonywane poprzednie operacje...';
											|tr = 'Önceki işlemler gerçekleştiriliyor...'");
		
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			CallbackDescription,
			IdleParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StartPerformingPreviousOperationsOnServer()
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground              = True;
	ExecutionParameters.WaitCompletion           = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Thực hiện trình tự các giao dịch trước đó.';
														|ru = 'Выполнение последовательности предыдущих операций.';
														|en = 'Perform a sequence of previous operations.'; fa = 'Perform a sequence of previous operations.';
														|it = 'Esecuzione sequenza operazioni precedenti.';
														|pl = 'Wykonanie sekwencji poprzednich operacji.';
														|tr = 'Önceki işlemlerin sırasının gerçekleştirilmesi.'");
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("TransactionTable", PreviousOperations_.Unload());
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Documents.ProductionOperation2_2.PerformSequenceOfPreviousOperationsInBackground",
		ProcedureParameters,
		ExecutionParameters);
	
EndProcedure

&AtClient
Procedure ExecutionOfPreviousOperationsEnd(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	If ExecutionOfPreviousOperationsEndOnServer(Result.ResultAddress) Then
	
		Close(AdditionalParameters);
		
	Else
		
		Message = New UserMessage();
		Message.Text = NStr("vi = 'Lỗi thực hiện các giao dịch sản xuất.
								|Xem chi tiết trong nhật ký sự kiện.';
								|ru = 'Ошибка выполнения производственных операций.
								|См. подробности в журнале регистрации.';
								|en = 'An error occurred while performing routing operations.
								|For more information, see the event log.'; fa = 'An error occurred while performing routing operations.
								|For more information, see the event log.';
								|it = 'Errore di esecuzione delle operazioni di produzione.
								|Per i dettagli, consultare il registro degli eventi.';
								|pl = 'Błąd wykonania operacji produkcyjnych.
								|Patrz szczegóły w dzienniku rejestracji.';
								|tr = 'Rota işlemlerinin gerçekleştirilme hatası.
								|Ayrıntılar için olay günlüğüne bakın.'");
		Message.Message();
		
	EndIf;
	
EndProcedure

&AtServer
Function ExecutionOfPreviousOperationsEndOnServer(StorageAddress)
	
	Return GetFromTempStorage(StorageAddress);
	
EndFunction

&AtClientAtServerNoContext
Procedure CalculateAttributeRecalculateStandards(Form)
	
	If Not Form.Items.RecalculateStandards.Visible Then
		Return;
	EndIf;
	
	If Form.DefectiveGoodsCount Or Form.CountCanceled Then
		Form.RecalculateStandards = True;
	EndIf;
	
EndProcedure

&AtClient
Function DateForDeterminingContractor()
	
	Date = RoutingOperationCompletionOfExecution;
	If Not ValueIsFilled(Date) And ValueIsFilled(ShiftTaskDate) Then
		Date = ShiftTaskDate;
	ElsIf Not ValueIsFilled(Date) Then
		Date = RoutesOperationDate;
	EndIf;
	
	Return Date;
	
EndFunction

&AtServerNoContext
Procedure PerformerGettingSelectionData(ChoiceData, Text, Department, Date)
	
	ChoiceData = New ValueList;
	FilterParameters = New Structure("Department, Date");
	FilterParameters.Department = Department;
	FilterParameters.Date = Date;
	ProductionServer.FillInSelectionDataWhenEnteringArtist(ChoiceData, Text, FilterParameters);
	
EndProcedure

&AtClient
Procedure PreviousOperationsOfOperationsStartSelectionEnd(Result, Var_Parameters) Export
	
	CurrentData = Items.PreviousOperations_.CurrentData;
	
	If CurrentData <> Undefined
		And ValueIsFilled(Result) Then
		
		CurrentData.Performer = Result;
		Modified = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Not Parameters.Property("ProductionOrder", ProductionOrder) Then
		ExceptionText = NStr("vi = 'Chưa truyền tham số bắt buộc';
							|ru = 'Не переданы обязательные параметры';
							|en = 'Required parameters are not passed'; fa = 'Required parameters are not passed';
							|it = 'Non sono indicati i parametri necessari';
							|pl = 'Nie są przekazane wymagane parametry';
							|tr = 'Zorunlu parametreler belirtilmedi'");
		Raise ExceptionText;
	EndIf;

	CheckAndOutputSpecificationSelectionErrors();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If StartAwaitingLongAction Then
		
		AttachIdleHandler("StartAwaitingLongAction", 0.1, True);
		
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SpreadsheetDocumentDetailProcessing(Item, Details, StandardProcessing)
	
	StandardProcessing = False;
	
	SettingsSource = New DataCompositionAvailableSettingsSource(SchemaURL);
	
	DetailProcessing = New DataCompositionDetailsProcess(
		ExplanationAddress, SettingsSource);
	
	AvailableAction = New Array;
	AvailableAction.Add(DataCompositionDetailsProcessingAction.OpenValue);
	
	CallbackDescription = New CallbackDescription(
		"ResultDetailProcessingCompletion", ThisObject);
	
	DetailProcessing.ShowActionChoice(
		CallbackDescription,
		Details,
		AvailableAction,
		,
		True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	CheckAndDisplayErrorsInSelectionOfSpecificationsOnClient();
	
EndProcedure

&AtClient
Procedure PickUpSpecifications(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;

	PickUpSpecificationsOnServer();
	
	Notify("Write_ProductionOrder", New Structure("ProductionOrder", ProductionOrder));
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

#Region CheckAndOutputErrors

&AtClient
Procedure CheckAndDisplayErrorsInSelectionOfSpecificationsOnClient() Export
	
	CheckAndOutputSpecificationSelectionErrors();
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckAndOutputSpecificationSelectionErrors()
	
	SpreadsheetDocument.Clear();
	
	CancelLongRunningOperation();
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ProductionOrder", ProductionOrder);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Kiểm tra và hiển thị lỗi chọn bảng kê chi tiết nguồn lực';
			|ru = 'Проверка и вывод ошибок подбора ресурсных спецификаций';
			|en = 'Check and display errors of picking of bills of materials'; fa = 'Check and display errors of picking of bills of materials';
			|it = 'Verifica e conclusione errori di selezione delle specifiche delle risorse';
			|pl = 'Sprawdzenie i wyświetlenie błędów wyboru specyfikacji zasobów';
			|tr = 'Ürün reçetelerinin seçiminde hataların kontrol edilmesi ve görüntülenmesi'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"InformationRegisters.OrderStructureCalculationProtocol.CheckAndOutputSpecificationSelectionErrors",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		TimeConsumingOperationIdleHandler = HandlerCheckAndDisplayErrorsInSelectionOfSpecificationsDelayed();
		StartAwaitingLongAction = True;
		
	Else
		
		CheckAndDisplayErrorsInSelectionOfSpecificationsDelayed(TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function HandlerCheckAndDisplayErrorsInSelectionOfSpecificationsDelayed()
	
	Return "CheckAndOutputSpecificationSelectionErrorsCompletion";
	
EndFunction

&AtClient
Procedure CheckAndOutputSpecificationSelectionErrorsCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Not ValueIsFilled(Result) Then
		ClearTabularDocument();
		Return;
	EndIf;
	
	CheckAndDisplayErrorsInSelectionOfSpecificationsDelayed(Result);
	
EndProcedure

&AtServer
Procedure CheckAndDisplayErrorsInSelectionOfSpecificationsDelayed(Result)
	
	ClearTabularDocument();
	
	If Result.Status = "Completed2" Then
		
		FillingData = GetFromTempStorage(Result.ResultAddress);
		
		If TypeOf(FillingData) = Type("Structure") Then
			
			SpreadsheetDocument = FillingData.SpreadsheetDocument;
			
			SchemaURL       = PutToTempStorage(FillingData.DataCompositionSchema, UUID);
			ExplanationAddress = PutToTempStorage(FillingData.DetailsData, UUID);
			
			Items.SpreadsheetDocument.ViewScalingMode = ViewScalingMode.Normal;
			
		EndIf;
	
	ElsIf Result.Status = "Error" Then
		
		Raise Result.BriefErrorDescription;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region PickUpSpecifications

&AtServer
Procedure PickUpSpecificationsOnServer()
	
	CancelLongRunningOperation();
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Chọn bảng kê chi tiết nguồn lực trong đơn hàng sản xuất';
			|ru = 'Подбор ресурсных спецификаций в заказах на производство';
			|en = 'Pick bills of materials in production orders'; fa = 'Pick bills of materials in production orders';
			|it = 'Selezione delle specifiche delle risorse negli ordini di produzione';
			|pl = 'Wybór specyfikacji zasobów w zleceniach produkcyjnych';
			|tr = 'Üretim emirlerinde ürün reçetelerinin seçimi'");
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ProductionOrder", ProductionOrder);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"InformationRegisters.OrderStructureCalculationProtocol.PickUpSpecificationsOnHold",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		TimeConsumingOperationIdleHandler = HandlerPickUpSpecificationsOnHold();
		StartAwaitingLongAction = True;
		
	Else
		
		ProcessResultOfSelectionOfSpecifications(ThisObject, TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function HandlerPickUpSpecificationsOnHold()
	
	Return "PickUpSpecificationsOnHoldCompletion";
	
EndFunction

&AtClientAtServerNoContext
Procedure ProcessResultOfSelectionOfSpecifications(Form, Result)
	
	If Result.Status = "Completed2" Then
		
		FillingData = GetFromTempStorage(Result.ResultAddress);
		
		If TypeOf(FillingData) = Type("Structure") Then
			
			ProcessedItemsCount = FillingData.ProcessedItemsCount;
			
			If ProcessedItemsCount > 0 Then
				
				Form.UserNotificationExplanation = StrTemplate(NStr("vi = 'Đã chọn %1 bảng kê chi tiết';
																	|ru = 'Подобранно %1 спецификаций';
																	|en = '%1 bills of materials are picked'; fa = '%1 bills of materials are picked';
																	|it = 'Selezionato %1 specifiche';
																	|pl = 'Wybrano %1 specyfikacji';
																	|tr = '%1 ürün reçetesi seçildi'"), FillingData.ProcessedItemsCount);
				Form.UserNotificationHeader = NStr("vi = 'Đã chọn bảng kê chi tiết';
													|ru = 'Выполнен подбор спецификаций';
													|en = 'Bills of materials are picked'; fa = 'Bills of materials are picked';
													|it = 'Selezione specifiche eseguita';
													|pl = 'Dokonano wyboru specyfikacji';
													|tr = 'Ürün reçetesi seçimi gerçekleştirildi'");
				
			Else
				
				Form.UserNotificationExplanation = NStr("vi = 'Chưa chọn bảng kê chi tiết nào';
														|ru = 'Ни одна спецификация не подобрана';
														|en = 'No bill of materials is picked'; fa = 'No bill of materials is picked';
														|it = 'Non è stata selezionata nessuna specifica';
														|pl = 'Nie wybrano ani jednej specyfikacji';
														|tr = 'Herhangi bir ürün reçetesi seçilmedi'");
				Form.UserNotificationHeader = NStr("vi = 'Chưa chọn bảng kê chi tiết';
													|ru = 'Не выполнен подбор спецификаций';
													|en = 'Bills of materials are not picked'; fa = 'Bills of materials are not picked';
													|it = 'Non è stato eseguita la selezione delle specifiche';
													|pl = 'Nie wykonano wyboru specyfikacji';
													|tr = 'Ürün reçetesi seçimi gerçekleştirilmedi'");
				
			EndIf;
			
		EndIf;
		
	Else
		
		If Result.Status = "Error" Then
			
			Raise Result.BriefErrorDescription;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PickUpSpecificationsOnHoldCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Not Result = Undefined Then
		
		ProcessResultOfSelectionOfSpecifications(ThisObject, Result);
		
		NotifyUserOfProcessingResults();
		
		CheckAndDisplayErrorsInSelectionOfSpecificationsOnClient();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyUserOfProcessingResults()
	
	If ValueIsFilled(UserNotificationHeader) Then
		
		ShowUserNotification(UserNotificationHeader,,UserNotificationExplanation, PictureLib.Information32);
		
		UserNotificationHeader = "";
		UserNotificationExplanation = "";
		
	EndIf;
	
	Notify("Write_ProductionOrder", New Structure("ProductionOrder", ProductionOrder));
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure ClearTabularDocument()
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.SpreadsheetDocument, "DontUse");
	SpreadsheetDocument.Clear();
	
EndProcedure

&AtServer
Procedure CancelLongRunningOperation()
	
	If Not TimeConsumingOperation = Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
EndProcedure

&AtClient
Procedure StartAwaitingLongAction()
	
	CallbackOnCompletion = New CallbackDescription(TimeConsumingOperationIdleHandler, ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	
	If TimeConsumingOperationIdleHandler = HandlerCheckAndDisplayErrorsInSelectionOfSpecificationsDelayed() Then
		
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.SpreadsheetDocument, "ReportGeneration");
		IdleParameters.OutputIdleWindow = False;
		
	EndIf;
	
	TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			CallbackOnCompletion,
			IdleParameters);
	
	StartAwaitingLongAction = False;
	
EndProcedure

&AtClient
Procedure ResultDetailProcessingCompletion(ChosenAction, ChosenActionParameter, AdditionalParameters) Export
	
	If ValueIsFilled(ChosenActionParameter) And ThisIsDocumentCatalogLink(ChosenActionParameter) Then
		
		ShowValue(, ChosenActionParameter);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ThisIsDocumentCatalogLink(Value)
	
	ValueType = TypeOf(Value);
	
	Return Catalogs.AllRefsType().ContainsType(ValueType) Or Documents.AllRefsType().ContainsType(ValueType);
	
EndFunction

#EndRegion

#EndRegion

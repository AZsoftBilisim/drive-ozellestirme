
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("ReferenceOrder", ReferenceOrder) Then
		UpdateDataOnServer();
	EndIf;
	
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
Procedure ReferenceOrderOnChange(Item)
	
	StatePresentation = Items.SpreadsheetDocument.StatePresentation;
	StatePresentation.Visible = True;
	StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	StatePresentation.Picture = New Picture;
	StatePresentation.Text = NStr("vi = 'Dữ liệu không phù hợp. Nhấp vào ''''Cập nhật'''' để nhận dữ liệu.';
									|ru = 'Данные неактуальны. Нажмите ""Обновить"" для получения данных.';
									|en = 'Irrelevant data. Click Update to receive data.'; fa = 'Irrelevant data. Click Update to receive data.';
									|it = 'I dati non sono pertinenti. Fare clic su ""Aggiorna"" per acquisire i dati.';
									|pl = 'Dane są nieaktualne. Kliknij ""Aktualizuj"" w celu uzyskania danych.';
									|tr = 'Veriler güncel değil. Verileri almak için ""Güncelle""ye tıklayın.'");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSpreadsheetDocument

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
	
	If CheckFilling() Then
		UpdateDataOnClient();
	EndIf;
	
EndProcedure

&AtClient
Procedure RescheduleSupplyDates(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	RescheduleSecurityDatesOnServer();
	NotifyUserOfProcessingResults();
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region UpdatingData

&AtClient
Procedure UpdateDataOnClient()
	
	UpdateDataOnServer();
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDataOnServer()
	
	If Not ValueIsFilled(ReferenceOrder) Then
		SpreadsheetDocument.Clear();
		Return;
	EndIf;
	
	CancelLongRunningOperation();
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ReferenceOrder", ReferenceOrder);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Điền danh sách công đoạn để chuyển ngày giao nguyên vật liệu';
			|ru = 'Заполнение списка этапов для переноса дат отгрузки материалов';
			|en = 'Populating the list of stages for materials shipment dates transfer'; fa = 'Populating the list of stages for materials shipment dates transfer';
			|it = 'Compilazione dell''elenco delle fasi per modificare le date di spedizione dei materiali';
			|pl = 'Wypełnienie listy etapów do przeniesienia dat wysyłki materiałów';
			|tr = 'Malzeme sevkiyat tarihlerinin aktarımı için aşama listesinin doldurulması'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.RescheduleRequestedSupplyDateOfProductionStages.ReadAndOutputStagesOfOrder",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		TimeConsumingOperationIdleHandler = DataUpdateHandler();
		StartAwaitingLongAction = True;
		
	Else
		
		ProcessResultOfUpdatingDataInBackground(TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function DataUpdateHandler()
	
	Return "UpdateBackgroundDataEnd";
	
EndFunction

&AtClient
Procedure UpdateBackgroundDataEnd(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Not ValueIsFilled(Result) Then
		ClearTabularDocument();
		Return;
	EndIf;
	
	ProcessResultOfUpdatingDataInBackground(Result);
	
EndProcedure

&AtServer
Procedure ProcessResultOfUpdatingDataInBackground(Result)
	
	ClearTabularDocument();
	
	If Result.Status = "Completed2" Then
		
		FillingData = GetFromTempStorage(Result.ResultAddress);
		
		If TypeOf(FillingData) = Type("Structure") Then
			
			SpreadsheetDocument = FillingData.SpreadsheetDocument;
			
			SchemaURL       = PutToTempStorage(FillingData.DataCompositionSchema, UUID);
			ExplanationAddress = PutToTempStorage(FillingData.DetailsData, UUID);
			
		EndIf;
	
	ElsIf Result.Status = "Error" Then
		
		Raise Result.BriefErrorDescription;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DataProcessing

&AtServer
Procedure RescheduleSecurityDatesOnServer()
	
	CancelLongRunningOperation();
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Chuyển ngày giao nguyên vật liệu trong các công đoạn sản xuất';
			|ru = 'Перенос дат отгрузки материалов в этапах производства';
			|en = 'Materials shipment dates transfer in production stages'; fa = 'Materials shipment dates transfer in production stages';
			|it = 'Modifica delle date di spedizione dei materiali nelle fasi di produzione';
			|pl = 'Przeniesienie dat wysyłki materiałów w etapach produkcji';
			|tr = 'Üretim aşamalarında malzeme sevkiyat tarihlerinin taşınması'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.RescheduleRequestedSupplyDateOfProductionStages.RescheduleRequestedSupplyDates",
		ReferenceOrder,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		TimeConsumingOperationIdleHandler = "RescheduleCollateralDatesInBackgroundEnd";
		StartAwaitingLongAction = True;
		
	Else
		
		ProcessResultOfTransferringSecurityDatesInBackground(ThisObject, TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
		UpdateDataOnServer();
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ProcessResultOfTransferringSecurityDatesInBackground(Form, Result)
	
	If Result.Status = "Completed2" Then
		
		FillingData = GetFromTempStorage(Result.ResultAddress);
		If TypeOf(FillingData) = Type("Structure") Then
			
			ProcessedItemsCount = FillingData.ProcessedItemsCount;
			
			If ProcessedItemsCount > 0 Then
				
				Form.MessageText = StrTemplate(
					NStr("vi = 'Đã xử lý %1 trên %2 chứng từ';
						|ru = 'Обработано %1 из %2 документов';
						|en = 'Processed %1 of %2 documents'; fa = 'Processed %1 of %2 documents';
						|it = 'Elaborati %1 da %2 documenti';
						|pl = 'Przetworzono %1 z %2 dokumentów';
						|tr = '%2 belgeden %1 işlendi'"),
					FillingData.ProcessedItemsCount,
					FillingData.TotalCount1);
				
				Form.TitleText = NStr("vi = 'Ngày giao hàng đã thay đổi';
										|ru = 'Даты отгрузки изменены';
										|en = 'Shipment dates changed'; fa = 'Shipment dates changed';
										|it = 'Date di spedizione modificate';
										|pl = 'Daty wysyłki zostały zmienione';
										|tr = 'Sevkiyat tarihleri değişti'");
				
			Else
				
				Form.MessageText = NStr("vi = 'Không có chứng từ để xử lý';
										|ru = 'Отсутствуют документы для обработки';
										|en = 'No documents to process'; fa = 'No documents to process';
										|it = 'Non ci sono documenti da elaborare';
										|pl = 'Brak dokumentów dla przetwarzania';
										|tr = 'İşlenecek belge bulunmamaktadır'");
				Form.TitleText = NStr("vi = 'Ngày giao hàng không thay đổi';
										|ru = 'Даты отгрузки не изменены';
										|en = 'Shipment dates not changed'; fa = 'Shipment dates not changed';
										|it = 'Date di spedizione non modificate';
										|pl = 'Daty wysyłki nie zostały zmienione';
										|tr = 'Sevkiyat tarihleri değişmedi'");
				
			EndIf;
			
		EndIf;
		
	Else
		
		If Result.Status = "Error" Then
			
			Raise Result.BriefErrorDescription;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RescheduleCollateralDatesInBackgroundEnd(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Not Result = Undefined Then
		
		ProcessResultOfTransferringSecurityDatesInBackground(ThisObject, Result);
		NotifyUserOfProcessingResults();
		
		UpdateDataOnClient();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyUserOfProcessingResults()
	
	If ValueIsFilled(MessageText) Then
		
		ShowUserNotification(
			TitleText,
			,
			MessageText,
			PictureLib.Information32);
		
		MessageText = "";
		TitleText = "";
		
	EndIf;
	
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
	
	If TimeConsumingOperationIdleHandler = DataUpdateHandler() Then
		
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
	
	If ValueIsFilled(ChosenActionParameter)
		And ThisIsDocumentCatalogLink(ChosenActionParameter) Then
		
		ShowValue(, ChosenActionParameter);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ThisIsDocumentCatalogLink(Value)
	
	ValueType = TypeOf(Value);
	
	Return Catalogs.AllRefsType().ContainsType(ValueType)
		Or Documents.AllRefsType().ContainsType(ValueType);
	
EndFunction

#EndRegion

#EndRegion


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

	CheckAndDeduceProductSeparationErrors();
	
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
	
	CheckAndOutputErrorsOfProductSeparationOnClient();
	
EndProcedure

&AtClient
Procedure ShouldRecalculate(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;

	RecalculateAtServer();
	
	Notify("Write_ProductionOrder", New Structure("ProductionOrder", ProductionOrder));
	
	Close();
	
EndProcedure

&AtClient
Procedure CompleteCalculation(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	OrderStructureClient.StartRecalculatingOrderStructure(ProductionOrder);
	
	Notify("Write_ProductionOrder", New Structure("ProductionOrder", ProductionOrder));
	
	Close();

EndProcedure

#EndRegion

#Region Private

#Region CheckAndOutputErrors

&AtClient
Procedure CheckAndOutputErrorsOfProductSeparationOnClient() Export
	
	CheckAndDeduceProductSeparationErrors();
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckAndDeduceProductSeparationErrors()
	
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
		"InformationRegisters.OrderStructureCalculationProtocol.CheckAndDeduceProductSeparationErrors",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		TimeConsumingOperationIdleHandler = HandlerCheckAndOutputErrorsOfProductSeparationOnDelayedBasis();
		StartAwaitingLongAction = True;
		
	Else
		
		CheckAndOutputErrorsOfProductSeparationOnDelayedBasis(TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function HandlerCheckAndOutputErrorsOfProductSeparationOnDelayedBasis()
	
	Return "CheckAndDeduceProductSeparationErrorsCompletion";
	
EndFunction

&AtClient
Procedure CheckAndDeduceProductSeparationErrorsCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Not ValueIsFilled(Result) Then
		ClearTabularDocument();
		Return;
	EndIf;
	
	CheckAndOutputErrorsOfProductSeparationOnDelayedBasis(Result);
	
EndProcedure

&AtServer
Procedure CheckAndOutputErrorsOfProductSeparationOnDelayedBasis(Result)
	
	ClearTabularDocument();
	
	If Result.Status = "Completed2" Then
		
		FillingData = GetFromTempStorage(Result.ResultAddress);
		
		If TypeOf(FillingData) = Type("Structure") Then
			
			SpreadsheetDocument = FillingData.SpreadsheetDocument;
	
			SchemaURL       = PutToTempStorage(FillingData.DataCompositionSchema, UUID);
			ExplanationAddress = PutToTempStorage(FillingData.DetailsData, UUID);
			
			Items.SpreadsheetDocument.ViewScalingMode = ViewScalingMode.Normal;
			
			ConfigureFormSCommandPanel(FillingData.ErrorsTypes);
			
		EndIf;
	
	ElsIf Result.Status = "Error" Then
		
		Raise Result.BriefErrorDescription;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ShouldRecalculate

&AtServer
Procedure RecalculateAtServer()
	
	CancelLongRunningOperation();
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	
	ExecutionParameters.BackgroundJobDescription =
			NStr("vi = 'Tính lại bảng kê chi tiết nguồn lực trong các đơn hàng sản xuất';
				|ru = 'Перерасчет ресурсных спецификаций в заказах на производство';
				|en = 'Recalculation of bills of materials in production orders'; fa = 'Recalculation of bills of materials in production orders';
				|it = 'Ricalcolo delle specifiche delle risorse negli ordini di produzione';
				|pl = 'Przeliczenie specyfikacji zasobów w zleceniach produkcyjnych';
				|tr = 'Üretim emirlerinde ürün reçetelerinin yeniden hesaplanması'");
		
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ProductionOrder", ProductionOrder);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"InformationRegisters.OrderStructureCalculationProtocol.RecalculateSpecificationsDeferred",
		ProcedureParameters,
		ExecutionParameters);

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
	
	If TimeConsumingOperationIdleHandler = HandlerCheckAndOutputErrorsOfProductSeparationOnDelayedBasis() Then
		
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

&AtServer
Procedure ConfigureFormSCommandPanel(ErrorsTypes)
	
	NeedFullCalculation = False;
	
	If ErrorsTypes.Find(Enums.ErrorsTypesOfProductionOrderStructureCalculation.ExplosionError) <> Undefined Then
		NeedFullCalculation = True
	EndIf;
	
	Items.FormShouldRecalculate.Visible = Not NeedFullCalculation;
	Items.FormShouldRecalculate.DefaultButton = Not NeedFullCalculation;
	Items.FormCompleteCalculation.DefaultButton = NeedFullCalculation;
	Items.FormCompleteCalculation.LocationInCommandBar = ?(NeedFullCalculation,
			ButtonLocationInCommandBar.InCommandBarAndInAdditionalSubmenu, ButtonLocationInCommandBar.InAdditionalSubmenu);
	
EndProcedure

#EndRegion

#EndRegion

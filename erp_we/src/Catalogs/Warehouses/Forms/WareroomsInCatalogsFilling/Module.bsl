#Region Variables

&AtClient
Var IdleHandlerParameters; //Parameters of the wait handler that checks the completion of the background task

&AtClient
Var AskQuestionBeforeClosing; //To pass to the handler before closing, a sign of the need for a question.

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	Warehouse = Parameters.Warehouse;
	
	ObjectsNames = Catalogs.Warehouses.NamesOfObjectsWithEmptySpace(Warehouse);
	
	FilledCatalogs = "";
	ThereAreWorkingAreas   = False;
	ThereAreReferenceCells = False;
	ThereIsStorageOfLeftovers = False;
	
	For Each ArrRow In ObjectsNames Do
		
		If ArrRow = "StorageBins" Then
			Text = "- " + Metadata.Catalogs.StorageBins.ListPresentation + Chars.LF;
		ElsIf ArrRow = "WarehouseZones" Then
			Text = "- " + Metadata.Catalogs.WarehouseZones.ListPresentation + Chars.LF;
			ThereAreWorkingAreas   = True;
		ElsIf ArrRow = "StorageAreas" Then
			Text = "- " + Metadata.Catalogs.StorageAreas.ListPresentation + Chars.LF;
			ThereIsStorageOfLeftovers = True;
		ElsIf ArrRow = "GoodsPlacementRules" Then
			Text = "- " + Metadata.InformationRegisters.GoodsPlacementRules.ListPresentation + Chars.LF;
			ThereIsStorageOfLeftovers = True;
		ElsIf ArrRow = "PlaceProductsInStorageBins" Then
			Text = "- " + Metadata.InformationRegisters.PlaceProductsInStorageBins.ListPresentation + Chars.LF;
			ThereAreReferenceCells = True;
		Else
			Text = "";
		EndIf;
		FilledCatalogs = FilledCatalogs + Text;
	EndDo;
	
	ArrayOfSelections = New Array;
	
	If ThereAreWorkingAreas Then
		ChoiceParameter = New ChoiceParameter("WarehouseZoneUsage", Enums.UseIsDeterminedInWarerooms.Use);
		ArrayOfSelections.Add(ChoiceParameter);
	EndIf;
	
	If ThereIsStorageOfLeftovers Then
		ChoiceParameter = New ChoiceParameter("CustomizeBinLocationWarehousing", Enums.SettingsOfBinLocationWarehousing.CellsBalance);
		ArrayOfSelections.Add(ChoiceParameter);
	ElsIf ThereAreReferenceCells Then
		ChoiceParameter = New ChoiceParameter("CustomizeBinLocationWarehousing", Enums.SettingsOfBinLocationWarehousing.BinsReferenceAddress);
		ArrayOfSelections.Add(ChoiceParameter);
	EndIf;
	
	Items.Premise.ChoiceParameters = New FixedArray(ArrayOfSelections);
	
	SetVisibilityOnServer();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit
		And AskQuestionBeforeClosing Then
		
		Cancel = True;
		WarningText = NStr("vi = 'Công việc của trợ giúp điền mục tin ""Nhà kho"" trong các danh mục sẽ bị ngắt.';
							|ru = 'Работа помощника по заполнению реквизита ""Помещение"" в справочниках будет прервана.';
							|en = 'Wizard filling in the Wareroom attribute in catalogs will be stopped.'; fa = 'Wizard filling in the Wareroom attribute in catalogs will be stopped.';
							|it = 'Il lavoro dell''assistente per riempire il requisito ""Stanza"" richiesta nell''elenco verrà interrotto.';
							|pl = 'Praca asystenta wypełniania atrybutu ""Pomieszczenie"" w katalogach zostanie przerwana.';
							|tr = 'rSihirbaz kataloglarındaki ""Depolama alanı"" özniteliğini doldurma işi kesintiye uğrayacaktır.'");
		Return;
		
	EndIf;
	
	If ClosingInProgress Then
		
		If Not AskQuestionBeforeClosing Then
			Return;
		EndIf;
		
		NString = NStr("vi = 'Kết thúc công việc với trợ giúp?';
						|ru = 'Завершить работу с помощником?';
						|en = 'Close the wizard?'; fa = 'Close the wizard?';
						|it = 'Terminare la sessione di lavoro con l''assistente?';
						|pl = 'Zakończyć pracę z asystentem?';
						|tr = 'Sihirbaz ile çalışma sonlandırılsın mı?'");
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), NString, QuestionDialogMode.YesNo, ,DialogReturnCode.No);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Yes Then
		ClosingInProgress = True;
		Close();
	EndIf;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	AskQuestionBeforeClosing = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure NextCommand(Command)
	ClearMessages();
	
	If Not ValueIsFilled(Premise) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Nhà kho"".';
							|ru = 'Не заполнено поле ""Помещение"".';
							|en = '""Wareroom"" is required.'; fa = '""Wareroom"" is required.';
							|it = 'Non è compilato il campo ""Locale"".';
							|pl = 'Nie wypełniono pola ""Pomieszczenie"".';
							|tr = '""Depolama alanı"" alanı doldurulmadı.'");
		
		CommonClientServer.MessageToUser(MessageText,,"Premise");
		Return;
	EndIf;
	
	AttachIdleHandler("CatalogProcessing", 0.1, True);
	
	Items.PanelMain.CurrentPage  = Items.PageProcessingState;
	Items.NavigationPanel.CurrentPage = Items.NavigationWaitPage;
	
EndProcedure

&AtClient
Procedure DoneCommand(Command)
	Close();
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	Close();
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CreateBackupClick(Item)
	// IB backup
	OpenForm("DataProcessor.IBBackup.Form");

EndProcedure 

&AtServer
Procedure SetVisibilityOnServer()
	
	VisibilityValue = GetFunctionalOption("UseDataSynchronization");
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"DataSynchronization",
		"Visible",
		VisibilityValue);
	
EndProcedure

&AtServer
Function CatalogProcessingServer()
	
	FillParameters = New Structure;
	FillParameters.Insert("Warehouse",Warehouse);
	FillParameters.Insert("Premise",Premise);
	
	JobDescription = NStr("vi = 'Điền nhà kho vào các danh mục theo kho ""%Warehouse%"".';
							|ru = 'Заполнение помещения в справочниках по складу ""%Warehouse%"".';
							|en = 'Fill in a wareroom in catalogs for the ""%Warehouse%"" warehouse.'; fa = 'Fill in a wareroom in catalogs for the ""%Warehouse%"" warehouse.';
							|it = 'Riempimento dei locali negli elenchi del magazzino ""%Warehouse%"".';
							|pl = 'Wypełnianie pomieszczenia w katalogach wg magazynu ""%Warehouse%"".';
							|tr = '""%Warehouse%"" ambarına göre kataloglardaki mekanların doldurulması.'");
	JobDescription = StrReplace(JobDescription, "%Warehouse%", Warehouse);
		
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	
	Result = TimeConsumingOperations.ExecuteInBackground(
		"Catalogs.Warehouses.FillInRoomInCatalog", 
		FillParameters,
		ExecutionParameters);
	
	Return Result;
	
EndFunction

&AtClient
Procedure CatalogProcessing()
	
	Result = CatalogProcessingServer();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	CallbackOnCompletion = New CallbackDescription("CompleteProcessing", ThisObject);

	TimeConsumingOperationsClient.WaitCompletion(Result, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtClient
Procedure CompleteProcessing(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		Items.PanelMain.CurrentPage  = Items.PageCompletion;
		Items.NavigationPanel.CurrentPage = Items.NavigationEndPage;
		Items.DoneCommand.DefaultButton = True;
		AskQuestionBeforeClosing = False;
		Notify("Warehouses_FilledRoomInCatalogsAndRegisters");
	EndIf;
	
EndProcedure

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion


#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	DocumentTypesUsed = New Array();
	DocumentTypesUsed.Add(Type("DocumentRef.ReverseVATAccrual"));
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.FormCommandBarGroup;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	BeginOfPeriod = BegOfMonth(CurrentSessionDate());
	EndOfPeriod = EndOfMonth(CurrentSessionDate());
	
	List.Parameters.SetParameterValue("RefType",
		Common.MetadataObjectID("Document.ReverseVATAccrual"));
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateListForOrder();
	SetDynamicListSelection_();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DetailedInformationClick(Item)
		
	FormParameters = New Structure;
	
	CurrentDate = CommonClient.SessionDate();
	FormParameters.Insert("StartDate"   , BegOfDay(CurrentDate));
	FormParameters.Insert("EndDate", EndOfDay(CurrentDate));
	FormParameters.Insert("Data", DataForLC());
	
	FilterByLevel = New ValueList;
	FilterByLevel.Add("Error", "Error");
	FormParameters.Insert("Level", FilterByLevel);
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	
EndProcedure

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	UpdatedList_4();
	Items.ReferencesOrganization.Visible = Not ValueIsFilled(Organization);
	
EndProcedure

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdatedList_4();
	
EndProcedure

&AtClient
Procedure EndOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdatedList_4();
	
EndProcedure

&AtClient
Procedure FilterCounterpartyOnChange(Item)
	
	UpdatedList_4();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure


&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList


&AtClient
Procedure ReferencesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.References.CurrentData;
	If CurrentData = Undefined Then
		
		Return;
		
	EndIf;
	
	If Field.Name = "ReferencesDocumentBasis" Then
		
		ValueToOpen = CurrentData.DocumentBasis;
		
	ElsIf Field.Name = "ReferencesCounterparty" Then
		
		ValueToOpen = CurrentData.Counterparty;
		
	Else
		
		Return;
		
	EndIf;
	
	ShowValue(,ValueToOpen);
	
EndProcedure


#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Conducting_Storno"
			Or EventName = "Write_ReversingEntry"
			Or EventName = "Write_ARAPAdjustment" Then
		
		Items.List.Refresh();
		
	ElsIf EventName = "DocumentForCalculatingReverseVATHasBeenCreated"
		And Parameter.Property("DocumentBasis") Then
		
		RowsForDeletion = References.FindRows(New Structure("DocumentBasis", Parameter.DocumentBasis));
		For Each RowForDeletion In RowsForDeletion Do
			
			References.Delete(RowForDeletion);
			
		EndDo;
		
		UpdatePageTitleForLayout();
		Items.List.Refresh();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.List, Title);
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.List, Title);
	
EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.List, Title);
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Items.List, Title);
	
EndProcedure


&AtClient
Procedure SelectPeriod(Command)
	
	Notification = New CallbackDescription("SelectPeriodCompletion", ThisObject);
		
	TMCommonUseClient.EditPeriod(
		ThisObject,
		New Structure("BeginOfPeriod, EndOfPeriod", "StartDate", "EndDate"),
		Notification);
	
EndProcedure

// Parameters:
// 	Period - StandardPeriod - Selected period
// 	AdditionalParameters - Arbitrary - contains additional parameters
&AtClient
Procedure SelectPeriodCompletion(Period, AdditionalParameters) Export
	
	If Period <> Undefined Then
		
		BeginOfPeriod = Period.StartDate;
		EndOfPeriod = Period.EndDate;
		
		UpdatedList_4();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.List);
	
EndProcedure

&AtClient
Procedure ListCreate(Command)
	
	FillingValues = New Structure("Organization, Counterparty", Organization, Counterparty);
	ParametersStructure = New Structure("FillingValues", FillingValues);
	OpenForm("Document.ReverseVATAccrual.ObjectForm", ParametersStructure);
	
EndProcedure

&AtClient
Procedure CreateVATCharge(Command)
	
	CurrentData = Items.References.CurrentData;
	If CurrentData = Undefined Then
		
		Return;
		
	EndIf;
	
	FormParameters = New Structure("Basis", CurrentData.DocumentBasis);
	OpenForm("Document.ReverseVATAccrual.ObjectForm", FormParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdatedList_4()
	
	SetDynamicListSelection_();
	UpdateListForOrder();
	
EndProcedure

&AtServer
Procedure SetDynamicListSelection_()
	
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization,
													DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	CommonClientServer.SetDynamicListFilterItem(List, "Counterparty", Counterparty,
													DataCompositionComparisonType.Equal,,ValueIsFilled(Counterparty));
	CommonClientServer.SetDynamicListParameter(List, "BeginOfPeriod", BeginOfPeriod);
	CommonClientServer.SetDynamicListParameter(List, "EndOfPeriod", EndOfPeriod);
	
EndProcedure

&AtClient
Procedure UpdateListForOrder()
	
	Items.PagesListOfOrders.CurrentPage = Items.PageListOfOrdersWaiting;
	
	ExecutionResult = StartBackgroundExecution();
	If ExecutionResult.Status = "Completed2" 
		Or ExecutionResult.Status = "Error" Then
		
		FillInTableOfOrders(ExecutionResult);
		Return;
		
	EndIf;
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	NotificationOfCompletionOfDocumentVerificationStatusUpdate = New CallbackDescription("ProcessResultOfUpdatingListOfOrders", ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(ExecutionResult, NotificationOfCompletionOfDocumentVerificationStatusUpdate, IdleParameters);
	
EndProcedure

&AtServer
Function StartBackgroundExecution()
	
	ProcessingParameters = Documents.ReverseVATAccrual.ParametersForCreatingListOfDocumentsForCalculatingReverseVAT();
	ProcessingParameters.Organization = Organization;
	ProcessingParameters.Counterparty = Counterparty;
	ProcessingParameters.BeginOfPeriod = BeginOfPeriod;
	ProcessingParameters.EndOfPeriod = EndOfPeriod;
	
	BackgroundJobParameters = TimeConsumingOperations.FunctionExecutionParameters(ThisObject.UUID);
	BackgroundJobResult = TimeConsumingOperations.ExecuteFunction(BackgroundJobParameters, "Documents.ReverseVATAccrual.UpdateListOfOrders", ProcessingParameters);
	
	Return BackgroundJobResult;
	
EndFunction

&AtClient
Procedure ProcessResultOfUpdatingListOfOrders(Result, AdditionalParameters) Export
	
	If Not Result = Undefined Then
		
		FillInTableOfOrders(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTableOfOrders(Result)
	
	FillInTableOfOrdersOnServer(Result);
	UpdatePageTitleForLayout();
	
EndProcedure

&AtServer
Procedure FillInTableOfOrdersOnServer(Result)
	
	If Result.Status = "Completed2" Then
		
		QueryResult = GetFromTempStorage(Result.ResultAddress);
		References.Load(QueryResult.Unload());
		References.Sort("Date");
		
		Items.PagesListOfOrders.CurrentPage = Items.ListOfOrdersPage;
		
	ElsIf Result.Status = "Error" Then
		
		Summary = Result.BriefErrorDescription;
		WriteLogEvent(NStr("vi = 'Không thể điền danh sách lệnh để tính thuế GTGT ngược';
							|ru = 'Не удалось заполнить список распоряжений для начисления реверсивного НДС';
							|en = 'Cannot fill the list of orders to accrue the reverse VAT charge'; fa = 'Cannot fill the list of orders to accrue the reverse VAT charge';
							|it = 'Non è stato possibile compilare l''elenco di disposizioni per calcolare IVA inversa';
							|pl = 'Nie udało się wypełnić listy zamówień do naliczenia odwrotnego VAT';
							|tr = 'Ters KDV tahakkuku için sipariş listesi doldurulamadı'", Common.DefaultLanguageCode()),
							EventLogLevel.Error,,DataForLC(),Result.DetailErrorDescription);
		
		Items.PagesListOfOrders.CurrentPage = Items.OrderListPageError;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function DataForLC()
	
	Return NStr("vi = 'Điền danh sách lệnh để tính thuế GTGT ngược';
				|ru = 'Заполнение списка распоряжений для начисления реверсивного НДС';
				|en = 'Fill the list of orders to accrue the reverse VAT charge'; fa = 'Fill the list of orders to accrue the reverse VAT charge';
				|it = 'Compilazione dell''elenco disposizioni per il calcolo dell''IVA inversa';
				|pl = 'Wypełnienie listy zamówień do naliczenia odwrotnego VAT ';
				|tr = 'Ters KDV tahakkuku için sipariş listesinin doldurulması'");
	
EndFunction

&AtClient
Procedure UpdatePageTitleForLayout()
	
	TitleText = NStr("vi = 'Cần lập chứng từ';
					|ru = 'К оформлению';
					|en = 'To register'; fa = 'برای ثبت';
					|it = 'In formalizzazione';
					|pl = 'Do zarejestrowania';
					|tr = 'Düzenlenecek'");
	NumberOfReferences = References.Count();
	If NumberOfReferences = 0 Then
		
		Items.PageOfOrder.Title = TitleText;
		
	Else
		
		Items.PageOfOrder.Title = StringFunctionsClientServer.SubstituteParametersToString("%1 (%2)", 
																							TitleText,
																							NumberOfReferences);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_F_EndOfPeriod" Then
		EndOfPeriodOnChange(Items.EndOfPeriod);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion


#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(
		ThisObject, "DocumentsList.Date", Items.Date.Name);
	
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	FillPropertyValues(ThisObject, Settings);
	
	CommonClientServer.SetDynamicListFilterItem(
		DocumentsList,
		"Employee",
		EmployeeFilter,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(EmployeeFilter)
	);
	
	CommonClientServer.SetDynamicListFilterItem(
		DocumentsList,
		"EndDate",
		BusinessTripDate,
		DataCompositionComparisonType.LessOrEqual,,
		ValueIsFilled(BusinessTripDate)
	);
	
	CommonClientServer.SetDynamicListFilterItem(
		DocumentsList,
		"Status",
		StatusFilter,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(StatusFilter)
	);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_BankAccountIssue"
		Or EventName = "Write_CashVoucher" Then
		Items.DocumentsList.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure EmployeeFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		DocumentsList,
		"EmployeePresentation",
		EmployeeFilter,
		DataCompositionComparisonType.Contains,,
		ValueIsFilled(EmployeeFilter));
	
EndProcedure

&AtClient
Procedure BusinessTripDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	CommonClientServer.SetDynamicListFilterItem(
		DocumentsList,
		"EndDate",
		BusinessTripDate,
		DataCompositionComparisonType.LessOrEqual,,
		ValueIsFilled(BusinessTripDate));
	
EndProcedure

&AtClient
Procedure StatusFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		DocumentsList,
		"Status",
		StatusFilter,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(StatusFilter)
	);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.DocumentsList);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.DocumentsList);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.DocumentsList);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure ChangeStatus_(Command)
	
	SetStatus(Command.Name, Command.Name);
	
EndProcedure

&AtClient
Procedure DownloadBookingDetails(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure SendToSmartWay(Command)
	
	Return;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetStatus(Status, StatusName)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.DocumentsList);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = StrTemplate(NStr("vi = 'Các đơn hàng được chọn trong danh sách sẽ có trạng thái ""%1"". Tiếp tục?';
								|ru = 'У выделенных в списке заявок будет установлен статус ""%1"". Продолжить?';
								|en = 'Status ""%1"" will be set for the requests selected in the list. Continue?'; fa = 'Status ""%1"" will be set for the requests selected in the list. Continue?';
								|it = 'Per le domande selezionate nell''elenco sarà impostato lo stato ""%1Continuare?';
								|pl = 'Dla wybranych na liście zleceń będzie ustawiony status ""%1"". Kontynuować?';
								|tr = 'Başvuru listesinde seçilenlerin durumu ""%1"" olarak ayarlanacaktır. Devam edilsin mi?'"), StatusName);
	Notification = New CallbackDescription("SetStatusCompletion", ThisObject,
		New Structure("SelectedRows, Status, StatusName", SelectedRows, Status, StatusName));
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetStatusCompletion(Result, AdditionalParameters) Export
	
	Response = Result;
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	SelectedRows = AdditionalParameters.SelectedRows;
	Status           = AdditionalParameters.Status;
	StatusName       = AdditionalParameters.StatusName;

	ClearMessages();	
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, Status);
	
	TMCommonUseClient.NotifyUserAboutSettingStatus(
		Items.DocumentsList, ProcessedItemsCount, SelectedRows.Count(), StatusName);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.DocumentsList);
EndProcedure
//End StandardSubsystems.AttachableCommands


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
	If Item.Name = "sh_ShamsiInput_F_BusinessTripDate" Then
		BusinessTripDateOnChange(Items.BusinessTripDate);
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

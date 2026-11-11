
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
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);


	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure ChangeStatus_(Command)
	StatusName = ?(Command.Name = "AmountDue", NStr("vi = 'Cần thanh toán';
													|ru = 'К оплате';
													|en = 'Scheduled'; fa = 'برنامه‌ریزی‌شده';
													|it = 'К оплате';
													|pl = 'Do płatności';
													|tr = 'Ödenecek tutar'"), Command.Name);
	SetStatus(Command.Name, StatusName);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetStatus(Status, StatusName)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = StrTemplate(NStr("vi = 'Các yêu cầu được chọn trong danh sách sẽ có trạng thái ""%1"". Tiếp tục?';
								|ru = 'У выделенных в списке заявок будет установлен статус ""%1"". Продолжить?';
								|en = 'Status ""%1"" will be set for the requests selected in the list. Continue?'; fa = 'Status ""%1"" will be set for the requests selected in the list. Continue?';
								|it = 'У выделенных в списке заявок будет установлен статус ""%1"". Продолжить?';
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
		Items.List, ProcessedItemsCount, SelectedRows.Count(), StatusName);
	
EndProcedure

#EndRegion

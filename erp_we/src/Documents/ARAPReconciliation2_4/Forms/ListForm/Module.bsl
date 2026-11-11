
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If ValueIsFilled(Parameters.FormCaption) Then
		Title = Parameters.FormCaption;
	EndIf;
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	CommonClientServer.SetDynamicListFilterItem(List, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
	LayoutParameter = List.Parameters.FindParameterValue(New DataCompositionParameter("ProhibitedPaymentTypes"));
	If LayoutParameter <> Undefined Then
		LayoutParameter.Use = True;
		LayoutParameter.Value.LoadValues(Documents.ARAPReconciliation2_4.ProhibitedPaymentTypes());
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	SetVisibilityOfElementsOnServer();
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	Manager = Settings.Get("Manager");
	Status = Settings.Get("Status");
	
	CommonClientServer.SetDynamicListFilterItem(List, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	CommonClientServer.SetDynamicListFilterItem(List, "Status", Status, DataCompositionComparisonType.Equal,, ValueIsFilled(Status));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StatusFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Status", Status, DataCompositionComparisonType.Equal,, ValueIsFilled(Status));
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Not CreationOfReconciliationSettlementsIsAvailable Then
		Cancel = True;
		Return;
	EndIf;
	
	If Not Copy Then
		Cancel = True;
		OpenForm("Document.ARAPReconciliation2_4.Form.FormOfReconciliationWizard",
			,
			ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure ManagerSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
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

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure SetTheStatusCreated(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ShowQueryBox(New CallbackDescription("SetTheStatusCreatedCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), NStr("vi = 'Sẽ đặt trạng thái ""Đã tạo mới"" cho các chứng từ được chọn trong danh sách. Tiếp tục?';
																																		|ru = 'У выделенных в списке документов будет установлен статус ""Создана"". Продолжить?';
																																		|en = 'Status of the documents selected in the list will be set to Created. Continue?'; fa = 'Status of the documents selected in the list will be set to Created. Continue?';
																																		|it = 'У выделенных в списке документов будет установлен статус ""Создана"". Продолжить?';
																																		|pl = 'Dla dokumentów zaznaczonych na liście zostanie ustawiony status ""Utworzona"". Kontynuować?';
																																		|tr = 'Listedeki seçili belgelerin durumu ""Oluşturuldu"" olarak ayarlanacaktır. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusCreatedCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    If Response <> DialogReturnCode.Yes Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "CreatedOn_");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Đã tạo mới';
																												|ru = 'Создана';
																												|en = 'Created'; fa = 'ایجادشده';
																												|it = 'Создана';
																												|pl = 'Created';
																												|tr = 'Oluşturuldu'"));

EndProcedure

&AtClient
Procedure SetTheStatusOnReconciliation(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ShowQueryBox(New CallbackDescription("SetTheStatusOnReconciliationCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), NStr("vi = 'Sẽ đặt trạng thái ""Đang đối chiếu"" cho các chứng từ được chọn trong danh sách. Tiếp tục?';
																																					|ru = 'У выделенных в списке документов будет установлен статус ""На сверке"". Продолжить?';
																																					|en = 'Status of the documents selected in the list will be set to ""In reconciliation"". Continue?'; fa = 'Status of the documents selected in the list will be set to ""In reconciliation"". Continue?';
																																					|it = 'У выделенных в списке документов будет установлен статус ""На сверке"". Продолжить?';
																																					|pl = 'Dla dokumentów zaznaczonych na liście zostanie ustawiony status ""Na weryfikacji"". Kontynuować?';
																																					|tr = 'Listedeki seçili belgelerin durumu ""Mutabakatta"" olarak ayarlanacaktır. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusOnReconciliationCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    If Response <> DialogReturnCode.Yes Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "OnReconciliation");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Đang đối chiếu';
																												|ru = 'На сверке';
																												|en = 'In reconciliation'; fa = 'در حال تطبیق';
																												|it = 'На сверке';
																												|pl = 'Na weryfikacji';
																												|tr = 'Mutabakatta'"));

EndProcedure

&AtClient
Procedure SetTheVerifiedStatus(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ShowQueryBox(New CallbackDescription("SetTheVerifiedStatusCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), NStr("vi = 'Sẽ đặt trạng thái ""Đã đối chiếu"" cho các chứng từ được chọn trong danh sách. Tiếp tục?';
																																			|ru = 'У выделенных в списке документов будет установлен статус ""Сверена"". Продолжить?';
																																			|en = 'Status of the documents selected in the list will be set to Reconciled. Continue?'; fa = 'Status of the documents selected in the list will be set to Reconciled. Continue?';
																																			|it = 'У выделенных в списке документов будет установлен статус ""Сверена"". Продолжить?';
																																			|pl = 'Dla dokumentów zaznaczonych na liście zostanie ustawiony status ""Zweryfikowane"". Kontynuować?';
																																			|tr = 'Listedeki seçili belgelerin durumu ""Uzlaşıldı"" olarak ayarlanacaktır. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheVerifiedStatusCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    If Response <> DialogReturnCode.Yes Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "Reconciled");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Đã đối chiếu';
																												|ru = 'Сверена';
																												|en = 'Reconciled'; fa = 'تطبیق‌شده';
																												|it = 'Сверена';
																												|pl = 'Reconciled';
																												|tr = 'Uzlaşıldı'"));

EndProcedure

&AtClient
Procedure CreateANewOne(Command)
	
	OpenForm("Document.ARAPReconciliation2_4.Form.DocumentForm");
	
EndProcedure

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

#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtClient
Function GetLinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ARAPReconciliation2_4.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = GetLinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtServer
Procedure SetVisibilityOfElementsOnServer()
	
	CreationOfReconciliationSettlementsIsAvailable = AccessRight("Insert", Metadata.Documents.ARAPReconciliation2_4)
		And Not GetFunctionalOption("NewOnlineARAPAccounting");
	
	ItemArray = New Array;
	ItemArray.Add("CreateDocumentList");
	ItemArray.Add("ListButtonAssistant");
	ItemArray.Add("ListCopyButton");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", CreationOfReconciliationSettlementsIsAvailable);

EndProcedure

#EndRegion

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	ListProperties = Common.DynamicListPropertiesStructure();
	
	ListProperties.QueryText = StrReplace(
		TransactionsDocument.QueryText,
		"&PresentationStage",
		Documents.ProductionStage2_2.QueryTextPresentationStage("OperationsOverridable.Stage"));
	Common.SetDynamicListProperties(Items.TransactionsDocument, ListProperties);
	
	OperationsRegisterQueryText = StrReplace(
		OperationsRegister.QueryText,
		"&PresentationStage",
		Documents.ProductionStage2_2.QueryTextPresentationStage("OperationsOverridable.Stage"));
	OperationsRegisterQueryText = StrReplace(
		OperationsRegisterQueryText,
		"&RunTime",
		InformationRegisters.OperationsToCreateShiftTasks.QueryTextOperationTime_("OperationsOverridable"));
	ListProperties.QueryText = OperationsRegisterQueryText;
	Common.SetDynamicListProperties(Items.OperationsRegister, ListProperties);
	
	ConfigureListSelection();
	
	// Visibility of commands to change an object
	VisibilityOfCommands = AccessRight("Update", Metadata.Documents.ShiftTask);
	
	Items.SetTheGeneratingStatus.Visible  = VisibilityOfCommands;
	Items.SetTheGeneratedStatus.Visible = VisibilityOfCommands;
	Items.SetClosedStatus.Visible      = VisibilityOfCommands;
	
	// Availability of commands to change the register
	HasUpdateRight = AccessRight("Update", Metadata.InformationRegisters.OperationsToCreateShiftTasks)
		And AccessRight("Update", Metadata.Documents.ShiftTask);
	
	Items.OperationsRegisterSelectionOfOperations.Visible = HasUpdateRight;
	Items.OperationsRegister.ReadOnly           = Not HasUpdateRight;
	
	// Visibility of commands for changing production operations
	VisibilityOfCommands = AccessRight("Update", Metadata.Documents.ProductionOperation2_2);
	
	Items.OperationsDocumentSelectionOfOperations.Visible = VisibilityOfCommands;
	
	Items.TransactionDocumentToSetTheStatusToRunning.Visible = VisibilityOfCommands;
	Items.TransactionDocumentToSetTheStatusToCompleted.Visible   = VisibilityOfCommands;
	Items.TransactionDocumentToSetTheStatusToFailed.Visible = VisibilityOfCommands;
	Items.TransactionDocumentToSetTheStatusToSkipped.Visible   = VisibilityOfCommands;
	
	Items.OperationsDocumentContextMenuSetStatusInProgress.Visible = VisibilityOfCommands;
	Items.OperationsDocumentContextMenuSetStatusCompleted.Visible   = VisibilityOfCommands;
	Items.OperationsDocumentContextMenuSetStatusFailed.Visible = VisibilityOfCommands;
	Items.OperationsDocumentContextMenuSetStatusSkipped.Visible   = VisibilityOfCommands;
	
	Items.TransactionDocumentToAssignTheWorkCenter.Visible            = VisibilityOfCommands;
	Items.TransactionDocumentToCancelTheAssignmentOfAWorkCenter.Visible = VisibilityOfCommands;
	
	Items.OperationsDocumentContextMenuAssignWorkCenter.Visible            = VisibilityOfCommands;
	Items.OperationsDocumentContextMenuCancelWorkCenterAssignment.Visible = VisibilityOfCommands;
	
	TransactionsDocument.SettingsComposer.Settings.AdditionalProperties.Insert(
		"UseOperationExecutionControl", GetFunctionalOption("UseOperationExecutionControl"));
	
	// Synchronizing the presentation of Statuses and headers of the corresponding commands
	Items.SetTheGeneratingStatus.Title = String(Enums.ShiftTaskStatuses.BeingGenerated);
	Items.SetTheGeneratedStatus.Title = String(Enums.ShiftTaskStatuses.Generated_);
	Items.SetClosedStatus.Title = String(Enums.ShiftTaskStatuses.Closed);
	
	// Peripherals
	TMCommonUse.CustomizePeripherals(ThisForm);
	// End Peripherals
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TransactionsDocument.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters.CommandBar = Items.OperationsDocumentCommands;
	PlacementParameters.GroupsPrefix = "TransactionsDocument";
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);	
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Peripherals
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	// End Peripherals
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	// Peripherals
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	// End Peripherals
	
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
	
	If EventName = "Write_ProductionOperation2_2" Then
		
		WhenChangingOperations(ThisObject);
		
	EndIf;
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement	
	
	OnReadCreateAtServer();
	
	If OperationsFromRegister(Object.Status) Then
		Items.OperationsRegister.Refresh();
	Else
		Items.TransactionsDocument.Refresh();
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ConfigureListSelection();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DepartmentOnChange(Item)
	
	DivisionWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure DecorationDocumentStatusesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = HyperlinkValueIsIndicatedInCreatedStatus() Then
		
		OperationStatusFilter = PredefinedValue("Enum.ProductionOperationStatuses.CreatedOn_");
		
	ElsIf FormattedStringURL = HyperlinkValueSelectionInProgressStatus() Then
		
		OperationStatusFilter = PredefinedValue("Enum.ProductionOperationStatuses.Running");
		
	ElsIf FormattedStringURL = HyperlinkValueIsDisplayedWithStatusCompleted() Then
		
		OperationStatusFilter = PredefinedValue("Enum.ProductionOperationStatuses.Executed");
		
	ElsIf FormattedStringURL = HyperlinkValueSelectionWithFailedStatus() Then
		
		OperationStatusFilter = PredefinedValue("Enum.ProductionOperationStatuses.NotExecuted");
		
	ElsIf FormattedStringURL = HyperlinkValueIsDisplayedWithSkippedStatus() Then
		
		OperationStatusFilter = PredefinedValue("Enum.ProductionOperationStatuses.IsSkipped");
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		TransactionsDocument,
		"Status",
		OperationStatusFilter,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(OperationStatusFilter));
	
	ConfigureDependentFormElements(ThisForm, "OperationStatusFilter");
	
EndProcedure

&AtClient
Procedure DecorationSelectionDescriptionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = ValueOfDisableStatusSelectionHyperlink() Then
		
		OperationStatusFilter = Undefined;
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		TransactionsDocument,
		"Status",
		OperationStatusFilter,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(OperationStatusFilter));
	
	ConfigureDependentFormElements(ThisForm, "OperationStatusFilter");
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdditionalPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperationsRegister

&AtClient
Procedure OperationsRegisterSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(RowSelected) = Type("DynamicListGroupRow") Then
		Return;
	EndIf;
	
	If Field.Name = "OperationsRegisterOperationDescription"
		Or Field.Name = "OperationsRegisterOperation" Then
		If ValueIsFilled(Item.CurrentData.Operation) Then
			ShowValue(, Item.CurrentData.Operation);
		ElsIf ValueIsFilled(Item.CurrentData.ProductionOperation) Then
			ShowValue(, Item.CurrentData.ProductionOperation);
		EndIf;
	ElsIf Field.Name = "OperationsRegisterPerformer" Then
		ShowValue(, Item.CurrentData.Performer);
	ElsIf Field.Name = "OperationsRegisterWorkCenter" Then
		ShowValue(, Item.CurrentData.WorkCenter);
	ElsIf Field.Name = "OperationsRegisterWorkCenterType" Then
		ShowValue(, Item.CurrentData.WorkCenterType);
	ElsIf Field.Name = "OperationsRegisterStagePresentation"
		Or Field.Name = "OperationsRegisterStage" Then
		ShowValue(, Item.CurrentData.Stage);
	ElsIf Field.Name = "OperationsRegisterReferenceOrder" Then
		ShowValue(, Item.CurrentData.ReferenceOrder);
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationsRegisterBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	If Object.Ref.IsEmpty() Or Not Object.Posted Or Modified Then
		
		QueryText = NStr("vi = 'Chỉ có thể thay đổi giao dịch sau khi ghi lại chứng từ.
			|Ghi lại và tiếp tục?';
			|ru = 'Изменение операций возможно только после записи документа.
			|Записать и продолжить?';
			|en = 'You can change operations only after saving the document. 
			|Save and continue?'; fa = 'You can change operations only after saving the document. 
			|Save and continue?';
			|it = 'Modifica delle operazioni è possibile solo dopo la registrazione del documento. 
			| Registrare e continuare?';
			|pl = 'Zmiana operacji jest możliwa tylko po zapisaniu dokumentu.
			|Zapisać i kontynuować?';
			|tr = 'İşlemin değiştirilmesi ancak belge kaydedildikten sonra mümkündür.
			|Kaydedilsin ve devam edilsin mi?'");
		
		CallbackDescription = New CallbackDescription("WriteDocumentAndAddOperationsToEnd",
			ThisObject);
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		OpenFormForAddingOperations(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationsRegisterBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	OperationKeys = CheckGetOperationsForChanges();
	
	If OperationKeys = Undefined Then
		Return;
	EndIf;
	
	If Modified Then
		
		QueryText = NStr("vi = 'Chỉ có thể thay đổi giao dịch sau khi ghi lại chứng từ.
			|Ghi lại và tiếp tục?';
			|ru = 'Изменение операций возможно только после записи документа.
			|Записать и продолжить?';
			|en = 'You can change operations only after saving the document. 
			|Save and continue?'; fa = 'You can change operations only after saving the document. 
			|Save and continue?';
			|it = 'Modifica delle operazioni è possibile solo dopo la registrazione del documento. 
			| Registrare e continuare?';
			|pl = 'Zmiana operacji jest możliwa tylko po zapisaniu dokumentu.
			|Zapisać i kontynuować?';
			|tr = 'İşlemin değiştirilmesi ancak belge kaydedildikten sonra mümkündür.
			|Kaydedilsin ve devam edilsin mi?'");
	    
		CallbackDescription = New CallbackDescription("WriteDocumentAndModifyOperationsEnd",
			ThisObject,
			New Structure("OperationKeys", OperationKeys));
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		
		OpenOperationsChangeForm(OperationKeys);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationsRegisterBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	OperationKeys = CheckGetOperationsForChanges();
	
	If OperationKeys <> Undefined Then
		
		ClearMessages();
		
		DeleteOperations(OperationKeys);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTransactionsDocument

&AtClient
Procedure TransactionsDocumentOnActivateRow(Item)
	
	ConfigureDependentFormElements(ThisForm, "OperationsDocumentCurLine");
	
EndProcedure

&AtClient
Procedure TransactionsDocumentSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	ProductionManagementClient.OpenOperationDocumentForm(RowSelected);
EndProcedure

&AtServerNoContext
Procedure TransactionsDocumentOnGetDataAtServer(TagName, Settings, Rows)
	
	If Not Settings.AdditionalProperties.Property("UseOperationExecutionControl")
		Or Not Settings.AdditionalProperties.UseOperationExecutionControl Then
		Return;
	EndIf;
	
	ProductionAccounting.SetStatusRegistrationInListOfProductionOperations(Rows);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


#Region TransactionsDocument

&AtClient
Procedure TransactionDocumentToSetTheStatusToRunning(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.TransactionsDocument);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ProductionAccountingClient.SetProductionOperationStatus(
		SelectedRows,
		"Running",
		Object.Department);
	
EndProcedure

&AtClient
Procedure TransactionDocumentToSetTheStatusToCompleted(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.TransactionsDocument);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ProductionAccountingClient.SetProductionOperationStatus(
		SelectedRows,
		"Executed",
		Object.Department);
	
EndProcedure

&AtClient
Procedure TransactionDocumentToSetTheStatusToFailed(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.TransactionsDocument);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ClearMessages();
	
	NewStatus = "NotExecuted";
	
	For Each Ref In SelectedRows Do
		RowData = Items.TransactionsDocument.RowData(Ref);
		ConfirmationParameters = ProductionAccountingClient.ConfirmationWhenSettingStatusOfOperation(
			RowData, NewStatus, SelectedRows.Count() > 0);
		If ConfirmationParameters <> Undefined Then
			ConfirmationParameters.Insert("OperationKeys", SelectedRows);
			CallbackDescription = New CallbackDescription(
				"ConfirmationWhenSettingStatusOfOperationsEnd", ThisObject, ConfirmationParameters);
			ShowQueryBox(CallbackDescription, ConfirmationParameters.QueryText, ConfirmationParameters.QuestionDialogMode);
			Return;
		EndIf;
	EndDo;
	
	ProductionAccountingClient.SetProductionOperationStatus(
		SelectedRows,
		NewStatus,
		Object.Department);
	
EndProcedure

&AtClient
Procedure TransactionDocumentToSetTheStatusToSkipped(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.TransactionsDocument);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ClearMessages();
	
	NewStatus = "IsSkipped";
	ConfirmationParameters = Undefined;
	
	For Each Ref In SelectedRows Do
		RowData = Items.TransactionsDocument.RowData(Ref);
		If Not RowData.Skippable Then
			ShowMessageBox(, NStr("vi = 'Không thể bỏ qua các giao dịch đã chọn.';
									|ru = 'Выделенные операции не могут быть пропущены.';
									|en = 'Selected operations cannot be skipped.'; fa = 'Selected operations cannot be skipped.';
									|it = 'Le operazioni selezionate non possono essere omesse.';
									|pl = 'Wyróżnionych operacji nie można pominąć.';
									|tr = 'Belirtilen işlemler atlanamaz.'"));
			Return;
		EndIf;
		If ConfirmationParameters = Undefined Then
			ConfirmationParameters = ProductionAccountingClient.ConfirmationWhenSettingStatusOfOperation(
				RowData, NewStatus, SelectedRows.Count() > 0);
		EndIf;
	EndDo;
	
	If ConfirmationParameters <> Undefined Then
		ConfirmationParameters.Insert("OperationKeys", SelectedRows);
		CallbackDescription = New CallbackDescription(
			"ConfirmationWhenSettingStatusOfOperationsEnd", ThisObject, ConfirmationParameters);
		ShowQueryBox(CallbackDescription, ConfirmationParameters.QueryText, ConfirmationParameters.QuestionDialogMode);
		Return;
	EndIf;
	
	ProductionAccountingClient.SetProductionOperationStatus(
		SelectedRows,
		NewStatus,
		Object.Department);
	
EndProcedure

&AtClient
Procedure TransactionDocumentToAssignTheWorkCenter(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.TransactionsDocument);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	WorkCenterType = Undefined;
	
	For Each Ref In SelectedRows Do
		
		RowData = Items.TransactionsDocument.RowData(Ref);
			
		If Not RowData.WorkCenterType.IsEmpty() Then
			
			If WorkCenterType = Undefined Then
					
				WorkCenterType = RowData.WorkCenterType;
				
			ElsIf WorkCenterType <> RowData.WorkCenterType Then
				
				ShowMessageBox(, NStr("vi = 'Đã chọn các thao tác có dạng nguồn lực sản xuất khác nhau';
										|ru = 'Выбраны операции с различными видами рабочих центров';
										|en = 'Operations with different work center types are selected'; fa = 'Operations with different work center types are selected';
										|it = 'Sono selezionate le operazioni con tipi di centri di lavoro diversi';
										|pl = 'Wybrano operacje z różnymi rodzajami stanowisk pracy';
										|tr = 'Farklı türde iş merkezleri olan işlemler seçildi'"));
				Return;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Filter = New Structure;
	If Not Object.Department.IsEmpty() Then
		Filter.Insert("Department", Object.Department);
	EndIf;
	If WorkCenterType <> Undefined Then
		Filter.Insert("WorkCenterType", WorkCenterType);
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("ChooseSetupOption", True);
	FormParameters.Insert("Filter", Filter);
	
	AddlParameters = New Structure;
	AddlParameters.Insert("Operations", SelectedRows);
	
	CallbackDescription = New CallbackDescription(
		"OperationsDocumentAssignWorkCenterCompletion",
		ThisObject, AddlParameters);
	
	OpenForm("Catalog.WorkCenters.ChoiceForm",
		FormParameters,
		ThisObject,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OperationsDocumentAssignWorkCenterCompletion(ClosingResult, AddlParameters) Export
	
	If ClosingResult <> Undefined Then
		
		If TypeOf(ClosingResult) = Type("Structure") Then
			DocumentOperationsAssignWorkCenterOnServer(AddlParameters.Operations,
				ClosingResult.WorkCenter,
				ClosingResult.SetupSettings);
		Else
			DocumentOperationsAssignWorkCenterOnServer(AddlParameters.Operations, ClosingResult);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TransactionDocumentToCancelTheAssignmentOfAWorkCenter(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.TransactionsDocument);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	DocumentOperationsAssignWorkCenterOnServer(
		SelectedRows,
		PredefinedValue("Catalog.WorkCenters.EmptyRef"));
	
EndProcedure

&AtServer
Procedure DocumentOperationsAssignWorkCenterOnServer(Operations, WorkCenter, SetupSettings = Undefined)
	
	Documents.ProductionOperation2_2.AssignWorkCenterToOperations(Operations, WorkCenter, SetupSettings);
	
	Items.TransactionsDocument.Refresh();
	
EndProcedure

#EndRegion

#Region AttachableCommands

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	If StrFind(Command.Name, "TransactionsDocument") = 0 Then
		AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	Else
		AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.TransactionsDocument);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure SetTheGeneratingStatus(Command)
	
	If Object.Ref.IsEmpty() Or Modified Then
		
		QueryText = NStr("vi = 'Để thay đổi trạng thái, cần ghi lại chứng từ.
			|Ghi lại và tiếp tục?';
			|ru = 'Для изменения статуса требуется записать документ.
			|Записать и продолжить?';
			|en = 'To change status, it is required to save the document. 
			|Save and continue?'; fa = 'To change status, it is required to save the document. 
			|Save and continue?';
			|it = 'Per modificare lo stato è necessario registrare il documento. 
			| Registrare e continuare?';
			|pl = 'Dla zmiany statusu trzeba zapisać doku
			|Zapisać i kontynuować?';
			|tr = 'Durumun değiştirilmesi için belgeyi kaydetmeniz gerekmektedir.
			|Kaydedilsin ve devam edilsin mi?'");
		
		CallbackDescription = New CallbackDescription(
			"WriteDocumentAndSetStatusToCompletion",
			ThisObject,
			New Structure("IsNew", Object.Ref.IsEmpty()));
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		
		SetStatus(PredefinedValue("Enum.ShiftTaskStatuses.BeingGenerated"));
	
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocumentAndSetStatusToCompletion(QuestionResult, AddlParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Write() Then
		
		SetStatus(PredefinedValue("Enum.ShiftTaskStatuses.BeingGenerated"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetTheGeneratedStatus(Command)
	
	If Object.Ref.IsEmpty() Or Modified Then
		
		QueryText = NStr("vi = 'Để thay đổi trạng thái, cần ghi lại chứng từ.
			|Ghi lại và tiếp tục?';
			|ru = 'Для изменения статуса требуется записать документ.
			|Записать и продолжить?';
			|en = 'To change status, it is required to save the document. 
			|Save and continue?'; fa = 'To change status, it is required to save the document. 
			|Save and continue?';
			|it = 'Per modificare lo stato è necessario registrare il documento. 
			| Registrare e continuare?';
			|pl = 'Dla zmiany statusu trzeba zapisać doku
			|Zapisać i kontynuować?';
			|tr = 'Durumun değiştirilmesi için belgeyi kaydetmeniz gerekmektedir.
			|Kaydedilsin ve devam edilsin mi?'");
		
		CallbackDescription = New CallbackDescription("WriteDocumentAndSetStatusGeneratedCompletion",
			ThisObject);
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		
		If AssignmentProcedureIsViolated(Object.Ref) Then
			
			OpenWarningBrokenAssignmentOrder(
				PredefinedValue("Enum.ShiftTaskStatuses.Generated_"));
				
		Else
			
			SetStatus(PredefinedValue("Enum.ShiftTaskStatuses.Generated_"));
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocumentAndSetStatusGeneratedCompletion(QuestionResult, AddlParameters) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Write() Then
		
		If AssignmentProcedureIsViolated(Object.Ref) Then
			
			OpenWarningBrokenAssignmentOrder(
				PredefinedValue("Enum.ShiftTaskStatuses.Generated_"));
				
		Else
			
			SetStatus(PredefinedValue("Enum.ShiftTaskStatuses.Generated_"));
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetClosedStatus(Command)
	
	If Object.Ref.IsEmpty() Or Modified Then
		
		QueryText = NStr("vi = 'Để thay đổi trạng thái, cần ghi lại chứng từ.
			|Ghi lại và tiếp tục?';
			|ru = 'Для изменения статуса требуется записать документ.
			|Записать и продолжить?';
			|en = 'To change status, it is required to save the document. 
			|Save and continue?'; fa = 'To change status, it is required to save the document. 
			|Save and continue?';
			|it = 'Per modificare lo stato è necessario registrare il documento. 
			| Registrare e continuare?';
			|pl = 'Dla zmiany statusu trzeba zapisać doku
			|Zapisać i kontynuować?';
			|tr = 'Durumun değiştirilmesi için belgeyi kaydetmeniz gerekmektedir.
			|Kaydedilsin ve devam edilsin mi?'");
		
		CallbackDescription = New CallbackDescription("WriteDocumentAndSetStatusToClosed", ThisObject);
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		
		CheckPerformActionsBeforeSettingClosedStatus();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocumentAndSetStatusToClosed(QuestionResult, AddlParameters) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Write() Then
		
		CheckPerformActionsBeforeSettingClosedStatus();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PickOperations(Command)
	
	If Object.Ref.IsEmpty() Or Not Object.Posted Or Modified Then
		
		QueryText = NStr("vi = 'Chỉ có thể thay đổi giao dịch sau khi ghi lại chứng từ.
			|Ghi lại và tiếp tục?';
			|ru = 'Изменение операций возможно только после записи документа.
			|Записать и продолжить?';
			|en = 'You can change operations only after saving the document. 
			|Save and continue?'; fa = 'You can change operations only after saving the document. 
			|Save and continue?';
			|it = 'Modifica delle operazioni è possibile solo dopo la registrazione del documento. 
			| Registrare e continuare?';
			|pl = 'Zmiana operacji jest możliwa tylko po zapisaniu dokumentu.
			|Zapisać i kontynuować?';
			|tr = 'İşlemin değiştirilmesi ancak belge kaydedildikten sonra mümkündür.
			|Kaydedilsin ve devam edilsin mi?'");
		
		CallbackDescription = New CallbackDescription("WriteDocumentAndPickUpOperationEnd",
			ThisObject);
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		
		OpenFormForAddingOperations(True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocumentAndPickUpOperationEnd(QuestionResult, AddlParameters) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
		
		OpenFormForAddingOperations(True);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region DataProcessing

&AtServer
Procedure DeleteOperations(OperationKeys)
	
	InformationRegisters.OperationsToCreateShiftTasks.DeleteKeyOperations(OperationKeys);
	
	WhenChangingOperations(ThisObject);
	
EndProcedure

&AtClient
Procedure SetStatus(Status)
	
	ClearMessages();
	
	StartWaiting = SetStatusInBackground(Status);
	
	If StartWaiting Then
		
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			New CallbackDescription("SetStatusInBackgroundCompletion", ThisObject),
			TimeConsumingOperationsClient.IdleParameters(ThisObject));
		
	Else
		
		NotifyAboutChangeInShiftTask();
		
	EndIf;
	
EndProcedure

&AtServer
Function SetStatusInBackground(Status)
	
	UnlockFormDataForEdit();
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Ref", Object.Ref);
	ProcedureParameters.Insert("Status", Status);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Đặt trạng thái của một công việc thay đổi';
			|ru = 'Установка статуса сменному заданию';
			|en = 'Set status for shift task'; fa = 'Set status for shift task';
			|it = 'Impostazione dello stato del task di turno';
			|pl = 'Ustawienie statusu dla zadania zmianowego';
			|tr = 'Vardiyalı göreve durumun yapılandırılması'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Documents.ShiftTask.SetStatusInBackground",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		StartWaiting = True;
		
	Else
		
		ProcessResultOfSettingStatusInBackground(TimeConsumingOperation);
		
		StartWaiting = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
	Return StartWaiting;
	
EndFunction

#EndRegion

#Region Assistants

&AtClient
Procedure OpenOperationsChangeForm(OperationKeys)
	
	FormParameters = New Structure;
	FormParameters.Insert("Department", Object.Department);
	FormParameters.Insert("OperationKeys", OperationKeys);
	FormParameters.Insert("ShiftTask", Object.Ref);
	
	OpenForm("DataProcessor.GenerateShiftTasks.Form.OperationAssignment1",
		FormParameters,
		ThisObject,
		UUID,,,
		New CallbackDescription("OperationsChangeRegisterCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OperationsChangeRegisterCompletion(ClosingResult, AddlParameters) Export
	
	If ClosingResult <> Undefined Then
		
		WhenChangingOperations(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenClosingAssistant()
	
	CallbackDescription = New CallbackDescription("MonthEndClosingWizardCompletion",
		ThisObject);
	
	OpenForm("Document.ShiftTask.Form.MonthEndClosingWizard",
		New Structure("Ref", Object.Ref),
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure MonthEndClosingWizardCompletion(ClosingResult, AddlParameters) Export
	
	If TypeOf(ClosingResult) = Type("Boolean") And ClosingResult Then
		
		SetStatus(PredefinedValue("Enum.ShiftTaskStatuses.Closed"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenFormForAddingOperations(PickMode)
	
	OpenForm(
		"DataProcessor.GenerateShiftTasks.Form.AddOperationsToDocument",
		New Structure("ShiftTask, PickMode", Object.Ref, PickMode),
		ThisForm,
		UUID,,,
		New CallbackDescription("AddingOperationsCompletion", ThisForm),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddingOperationsCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult <> Undefined Then
		
		Read();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenWarningBrokenAssignmentOrder(NewStatus)
	
	CallbackDescription = New CallbackDescription("WarningAssignmentOrderHasBeenViolatedCompletion",
		ThisObject,
		New Structure("Status", NewStatus));
	
	OpenForm("Document.ShiftTask.Form.AssignmentProcedureIsViolated",
		New Structure("Ref", Object.Ref),
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure WarningAssignmentOrderHasBeenViolatedCompletion(ClosingResult, AddlParameters) Export
	
	If TypeOf(ClosingResult) = Type("Boolean") And ClosingResult Then
		
		SetStatus(AddlParameters.Status);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region StandardSubsystems

// StandardSubsystems.Peripherals
&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		If Items.Pages.CurrentPage = Items.PageTransactionsDocument Then
			Items.TransactionsDocument.CurrentRow = ReferencesArrray[0];
			If Items.TransactionsDocument.CurrentRow = Undefined Then
				ShowValue(Undefined, ReferencesArrray[0]);
			EndIf;
		Else
			ShowValue(Undefined, ReferencesArrray[0]);
		EndIf;
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ProductionOperation2_2.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction
// End StandardSubsystems.Peripherals

// StandardSubsystems.Properties 
&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);

EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Operations register - unit of execution time Second
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OperationsRegisterRunTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OperationsRegister.ExecutionTimeUnitOfMeasure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TimeMeasureUnits.Second;
	
	Item.Appearance.SetParameterValue("Format", StrTemplate("NFD=1; NF='Ч %1'", NStr("vi = 'giây';
																					|ru = 'сек';
																					|en = 'sec'; fa = 'ثانیه';
																					|it = 'sec';
																					|pl = 'sec';
																					|tr = 'sn.'"))); // @Format-2
	
	// Operations register - unit of execution time Minute
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OperationsRegisterRunTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OperationsRegister.ExecutionTimeUnitOfMeasure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TimeMeasureUnits.Minute;
	
	Item.Appearance.SetParameterValue("Format", StrTemplate("NFD=1; NF='Ч %1'", NStr("vi = 'phút';
																					|ru = 'мин';
																					|en = 'min'; fa = 'دقیقه';
																					|it = 'min';
																					|pl = 'min';
																					|tr = 'dk.'"))); // @Format-2
	
	// Operations register - unit of execution time Hour
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OperationsRegisterRunTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OperationsRegister.ExecutionTimeUnitOfMeasure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TimeMeasureUnits.Hour;
	
	Item.Appearance.SetParameterValue("Format", StrTemplate("NFD=1; NF='Ч %1'", NStr("vi = 'giờ';
																					|ru = 'ч';
																					|en = 'h'; fa = 'ساعت';
																					|it = 'ore';
																					|pl = 'godz.';
																					|tr = 'sa.'"))); // @Format-2
	
	// Operations register - unit of execution time Day
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OperationsRegisterRunTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OperationsRegister.ExecutionTimeUnitOfMeasure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TimeMeasureUnits.Days1;
	
	Item.Appearance.SetParameterValue("Format", StrTemplate("NFD=1; NF='Ч %1'", NStr("vi = 'ngày';
																					|ru = 'сут';
																					|en = 'd'; fa = 'روز';
																					|it = '24 ore';
																					|pl = 'dob.';
																					|tr = 'gün'"))); // @Format-2
	
	// Operations register - stage representation
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OperationsRegisterStage.Name);
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("OperationsRegister.PresentationStage"));
	
	// Operations register - red text color for lines with a broken assignment order
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OperationsRegister.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OperationsRegister.AssignmentProcedureIsViolated");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	// Operations document - unit of execution time Second
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.TransactionsDocumentRunTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsDocument.ExecutionTimeUnitOfMeasure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TimeMeasureUnits.Second;
	
	Item.Appearance.SetParameterValue("Format", StrTemplate("NFD=1; NF='Ч %1'", NStr("vi = 'giây';
																					|ru = 'сек';
																					|en = 'sec'; fa = 'ثانیه';
																					|it = 'sec';
																					|pl = 'sec';
																					|tr = 'sn.'"))); // @Format-2
	
	// Operations document - unit of execution time Minute
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.TransactionsDocumentRunTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsDocument.ExecutionTimeUnitOfMeasure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TimeMeasureUnits.Minute;
	
	Item.Appearance.SetParameterValue("Format", StrTemplate("NFD=1; NF='Ч %1'", NStr("vi = 'phút';
																					|ru = 'мин';
																					|en = 'min'; fa = 'دقیقه';
																					|it = 'min';
																					|pl = 'min';
																					|tr = 'dk.'"))); // @Format-2
	
	// Operations document - unit of execution time Hour
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.TransactionsDocumentRunTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsDocument.ExecutionTimeUnitOfMeasure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TimeMeasureUnits.Hour;
	
	Item.Appearance.SetParameterValue("Format", StrTemplate("NFD=1; NF='Ч %1'", NStr("vi = 'giờ';
																					|ru = 'ч';
																					|en = 'h'; fa = 'ساعت';
																					|it = 'ore';
																					|pl = 'godz.';
																					|tr = 'sa.'"))); // @Format-2
	
	// Operations document - unit of execution time Day
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.TransactionsDocumentRunTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransactionsDocument.ExecutionTimeUnitOfMeasure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TimeMeasureUnits.Days1;
	
	Item.Appearance.SetParameterValue("Format", StrTemplate("NFD=1; NF='Ч %1'", NStr("vi = 'ngày';
																					|ru = 'сут';
																					|en = 'd'; fa = 'روز';
																					|it = '24 ore';
																					|pl = 'dob.';
																					|tr = 'gün'"))); // @Format-2
	
	// Operations document - stage representation
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.TransactionsDocumentStage.Name);
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("TransactionsDocument.PresentationStage"));
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	FillInDetailsForDivision();
	
	FillPropertyValues(ThisObject,
		ResultsForOperations(Object.Ref, Object.Status));
		
	InactiveHyperlinkColor = StyleColors.EmptyTableField;
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtServer
Procedure DivisionWhenChangedOnServer()
	
	FillInDetailsForDivision();
	
	If Not Object.Shift.IsEmpty()
		And (Not UseShifts
			Or DivisionShifts.Find(Object.Shift) = Undefined) Then
		Object.Shift = Undefined;
	EndIf;
	
	ConfigureDependentFormElements(ThisForm, "Department");
	
EndProcedure

&AtServer
Procedure FillInDetailsForDivision()
	
	DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(Object.Department);
	UseShifts = DivisionParameters.UseShifts;
	DivisionShifts = New FixedArray(DivisionParameters.WorkSchedules);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Object = Form.Object;
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	// Selection by division in the lists
	If AttributesStructure1.Property("Department") 
		Or Initialize Then
		
		Items.Shift.Visible = Form.UseShifts;
		
		Form.SetFormFunctionalOptionParameters(New Structure("Department", Object.Department));
		
		ParametersArray = New Array;
		ParametersArray.Add(New ChoiceParameter("Filter.Ref", Form.DivisionShifts));
		Items.Shift.ChoiceParameters = New FixedArray(ParametersArray);
		
	EndIf;
	
	If AttributesStructure1.Property("Status") 
		Or Initialize Then
		
		OperationsFromRegister = OperationsFromRegister(Object.Status);
		
		Items.PageOperationsRegister.Visible = OperationsFromRegister;
		Items.OperationsRegister.Visible = OperationsFromRegister;
		
		Items.PageTransactionsDocument.Visible = Not OperationsFromRegister;
		Items.TransactionsDocument.Visible = Not OperationsFromRegister;
		Items.OperationsDocumentCommands.Visible = Not OperationsFromRegister;
		
		Items.SetTheGeneratingStatus.Enabled = Object.Status <> PredefinedValue(
			"Enum.ShiftTaskStatuses.BeingGenerated");
		Items.SetTheGeneratedStatus.Enabled = Object.Status <> PredefinedValue(
			"Enum.ShiftTaskStatuses.Generated_");
		
		DocumentClosed = Object.Status = PredefinedValue("Enum.ShiftTaskStatuses.Closed");
		
		Items.SetClosedStatus.Enabled = Not DocumentClosed;
		Items.OperationsDocumentSelectionOfOperations.Enabled = Not DocumentClosed;
		Items.TransactionsDocument.ReadOnly = DocumentClosed;
		
	EndIf;
	
	If AttributesStructure1.Property("Status")
		Or AttributesStructure1.Property("OperationsDocumentCurLine")
		Or Initialize Then
		
		CommandsAvailability = Items.TransactionsDocument.CurrentRow <> Undefined
			And Object.Status <> PredefinedValue("Enum.ShiftTaskStatuses.Closed");
		
		Items.TransactionDocumentToSetTheStatusToRunning.Enabled = CommandsAvailability;
		Items.TransactionDocumentToSetTheStatusToCompleted.Enabled = CommandsAvailability;
		Items.TransactionDocumentToSetTheStatusToFailed.Enabled = CommandsAvailability;
		Items.TransactionDocumentToSetTheStatusToSkipped.Enabled = CommandsAvailability;
		
		Items.OperationsDocumentContextMenuSetStatusInProgress.Enabled = CommandsAvailability;
		Items.OperationsDocumentContextMenuSetStatusCompleted.Enabled = CommandsAvailability;
		Items.OperationsDocumentContextMenuSetStatusFailed.Enabled = CommandsAvailability;
		Items.OperationsDocumentContextMenuSetStatusSkipped.Enabled = CommandsAvailability;
		
		Items.TransactionDocumentToAssignTheWorkCenter.Enabled = CommandsAvailability;
		Items.TransactionDocumentToCancelTheAssignmentOfAWorkCenter.Enabled = CommandsAvailability;
		
		Items.OperationsDocumentContextMenuAssignWorkCenter.Enabled = CommandsAvailability;
		Items.OperationsDocumentContextMenuCancelWorkCenterAssignment.Enabled = CommandsAvailability;
		
	EndIf;
	
	If AttributesStructure1.Property("Status")
		Or AttributesStructure1.Property("TransactionsDocument")
		Or Initialize Then
		
		If OperationsFromRegister(Object.Status) Then
			
			Items.DecorationDocumentStatuses.Visible = False;
			
		Else
			
			RowsArray = New Array;
		    RowsArray.Add(NStr("vi = 'Trong trạng thái';
								|ru = 'В статусе';
								|en = 'In the status'; fa = 'در وضعیت';
								|it = 'Nello stato';
								|pl = 'W statusie';
								|tr = 'Durumda'"));
			RowsArray.Add(" ");
			
			// CreatedOn_
			Content = ?(Form.InTheCreatedStatus = 0, NStr("vi = 'Ngày tạo';
															|ru = 'Создана';
															|en = 'Created'; fa = 'ایجادشده';
															|it = 'Creata';
															|pl = 'Utworzona';
															|tr = 'Oluşturuldu'"),
				StrTemplate(NStr("vi = 'Đã tạo (%1)';
								|ru = 'Создана (%1)';
								|en = 'Created (%1)'; fa = 'Created (%1)';
								|it = 'Creata (%1)';
								|pl = 'Utworzona (%1)';
								|tr = 'Oluşturuldu (%1)'"), Form.InTheCreatedStatus));
			TextColor = ?(Form.InTheCreatedStatus = 0, Form.InactiveHyperlinkColor, Undefined);
			
			TeamSelection = New FormattedString(
				Content,,
				TextColor,,
				HyperlinkValueIsIndicatedInCreatedStatus());
			
			RowsArray.Add(TeamSelection);
						
			RowsArray.Add(", ");
			
			// Running
			Content = ?(Form.InTheStatusInProgress = 0, NStr("vi = 'Đang thực hiện';
															|ru = 'Выполняется';
															|en = 'Running'; fa = 'در حال اجرا';
															|it = 'In esecuzione';
															|pl = 'Trwa wykonywanie';
															|tr = 'Gerçekleştiriliyor'"),
				StrTemplate(NStr("vi = 'Đang thực hiện (%1)';
								|ru = 'Выполняется (%1)';
								|en = 'Running (%1)'; fa = 'Running (%1)';
								|it = 'In esecuzione (%1)';
								|pl = 'Wykonuje się (%1)';
								|tr = 'Gerçekleştiriliyor (%1)'"), Form.InTheStatusInProgress));
			TextColor = ?(Form.InTheStatusInProgress = 0, Form.InactiveHyperlinkColor, Undefined);
			
			TeamSelection = New FormattedString(
				Content,,
				TextColor,,
				HyperlinkValueSelectionInProgressStatus());
				
			RowsArray.Add(TeamSelection);
			
			RowsArray.Add(", ");
			
			// Executed
			Content = ?(Form.InPerformedStatus = 0, NStr("vi = 'Đã thực hiện';
														|ru = 'Выполнена';
														|en = 'Completed'; fa = 'تکمیل‌شده';
														|it = 'Completata';
														|pl = 'Wykonana';
														|tr = 'Gerçekleştirildi'"),
				StrTemplate(NStr("vi = 'Đã thực hiện (%1)';
								|ru = 'Выполнена (%1)';
								|en = 'Executed (%1)'; fa = 'Executed (%1)';
								|it = 'Eseguita (%1)';
								|pl = 'Wykonana (%1)';
								|tr = 'Gerçekleştirildi (%1)'"), Form.InPerformedStatus));
			TextColor = ?(Form.InPerformedStatus = 0, Form.InactiveHyperlinkColor, Undefined);
			
			TeamSelection = New FormattedString(
				Content,,
				TextColor,,
				HyperlinkValueIsDisplayedWithStatusCompleted());
				
			RowsArray.Add(TeamSelection);
			
			RowsArray.Add(", ");
			
			// Not executed
			Content = ?(Form.InNotPerformedStatus = 0, NStr("vi = 'Chưa thực hiện';
															|ru = 'Не выполнена';
															|en = 'Failed'; fa = 'ناموفق';
															|it = 'Non eseguito';
															|pl = 'Nie wykonana';
															|tr = 'Gerçekleştirilmedi'"),
				StrTemplate(NStr("vi = 'Không thành công (%1)';
								|ru = 'Не выполнена (%1)';
								|en = 'Not executed (%1)'; fa = 'Not executed (%1)';
								|it = 'Non eseguito (%1)';
								|pl = 'Nie wykonana (%1)';
								|tr = 'Gerçekleştirilmedi (%1)'"), Form.InNotPerformedStatus));
			TextColor = ?(Form.InNotPerformedStatus = 0, Form.InactiveHyperlinkColor, Undefined);
			
			TeamSelection = New FormattedString(
				Content,,
				TextColor,,
				HyperlinkValueSelectionWithFailedStatus());
				
			RowsArray.Add(TeamSelection);
			
			RowsArray.Add(", ");
			
			// IsSkipped
			Content = ?(Form.InTheSkippedStatus = 0, NStr("vi = 'Bỏ qua';
															|ru = 'Пропущена';
															|en = 'Skipped'; fa = 'ردشده';
															|it = 'Omessa';
															|pl = 'Pominięta';
															|tr = 'Atlandı'"),
				StrTemplate(NStr("vi = 'Bỏ qua (%1)';
								|ru = 'Пропущена (%1)';
								|en = 'Skipped (%1)'; fa = 'Skipped (%1)';
								|it = 'Omessa (%1)';
								|pl = 'Pominięta (%1)';
								|tr = 'Atlandı (%1)'"), Form.InTheSkippedStatus));
			TextColor = ?(Form.InTheSkippedStatus = 0, Form.InactiveHyperlinkColor, Undefined);
			
			TeamSelection = New FormattedString(
				Content,,
				TextColor,,
				HyperlinkValueIsDisplayedWithSkippedStatus());
				
			RowsArray.Add(TeamSelection);
			
			//
			
			Items.DecorationDocumentStatuses.Title = New FormattedString(RowsArray);
			Items.DecorationDocumentStatuses.Visible = True;
			
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("Status") 
		Or AttributesStructure1.Property("OperationStatusFilter") 
		Or Initialize Then
		
		If Not Form.OperationStatusFilter.IsEmpty()
			And Not OperationsFromRegister(Object.Status) Then
			
			RowsArray = New Array;
			
			RowsArray.Add(
				StrTemplate(NStr("vi = 'Đã thiết lập lọc theo giao dịch ở trạng thái %1';
								|ru = 'Установлен отбор по операциям в статусе %1';
								|en = 'Filter is set by operations in the %1 status'; fa = 'Filter is set by operations in the %1 status';
								|it = 'È stata impostata selezione per operazioni con lo stato %1';
								|pl = 'Ustawiono selekcję wg operacji w statusie %1';
								|tr = '%1 durumunda işlemlere göre filtre yapılandırıldı'"),
				Form.OperationStatusFilter)
				);
			
			RowsArray.Add(" (");
			
			RowsArray.Add(New FormattedString(NStr("vi = 'ngắt kết nối';
													|ru = 'отключить';
													|en = 'disable'; fa = 'disable';
													|it = 'disattivare';
													|pl = 'disable';
													|tr = 'devre dışı bırak'"),,,, 
				ValueOfDisableStatusSelectionHyperlink()));
			
			RowsArray.Add(")");
			
			Items.DecorationSelectionDescription.Title = New FormattedString(RowsArray);
			Items.DecorationSelectionDescription.Visible = True;
			
		Else
			
			Items.DecorationSelectionDescription.Visible = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureListSelection()
	
	CommonClientServer.SetDynamicListFilterItem(
		OperationsRegister,
		"ShiftTask",
		?(ValueIsFilled(Object.Ref), Object.Ref, Null),
		DataCompositionComparisonType.Equal,,
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		TransactionsDocument,
		"ShiftTask",
		?(ValueIsFilled(Object.Ref), Object.Ref, Null),
		DataCompositionComparisonType.Equal,,
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		TransactionsDocument,
		"Department",
		Object.Department,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Object.Department));
	
EndProcedure

&AtClient
Function CheckGetOperationsForChanges()
	
	If Items.OperationsRegister.SelectedRows.Count() = 0 Then
		
		Result = Undefined;
		
		ShowMessageBox(, NStr("vi = 'Không có Giao dịch nào được chọn để hoàn thành hành động';
								|ru = 'Не выбраны операции для выполнения действия';
								|en = 'Operations to execute the action are not selected'; fa = 'Operations to execute the action are not selected';
								|it = 'Nessuna operazione selezionata per eseguire l''azione';
								|pl = 'Nie wybrano operacji dla wykonania czynności';
								|tr = 'Eylemin gerçekleştirilmesi için herhangi bir işlem seçilmedi'"));
		
	Else
		
		Result = New Array;
		
		For Each String In Items.OperationsRegister.SelectedRows Do
			
			If TypeOf(String) = Type("DynamicListGroupRow") Then
				
				ShowMessageBox(, NStr("vi = 'Thao tác không thể được thực hiện trên một dòng nhóm danh sách.';
										|ru = 'Действие не может быть выполнено для строки группировки списка';
										|en = 'Action cannot be executed for the list grouping row'; fa = 'Action cannot be executed for the list grouping row';
										|it = 'L''operazione non può essere eseguita per la riga di raggruppamento dell''elenco';
										|pl = 'Czynność nie może być wykonana dla wiersza grupowania listy';
										|tr = 'Liste gruplandırma satırı için eylem gerçekleştirilemez'"));
				
				Result = Undefined;
				Break;
				
			Else
				
				Result.Add(String);
				
			EndIf;
		
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure WriteDocumentAndAddOperationsToEnd(QuestionResult, AddlParameters) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
		
		OpenFormForAddingOperations(False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocumentAndModifyOperationsEnd(QuestionResult, AddlParameters) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
		
		OpenOperationsChangeForm(AddlParameters.OperationKeys);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure WhenChangingOperations(Form)
	
	FillPropertyValues(Form,
		ResultsForOperations(Form.Object.Ref, Form.Object.Status));
	
	If OperationsFromRegister(Form.Object.Status) Then
		
		Form.Items.OperationsRegister.Refresh();
		
	Else
		
		Form.Items.TransactionsDocument.Refresh();
		
		ConfigureDependentFormElements(Form, "TransactionsDocument");
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ResultsForOperations(Ref, Status)
	
	Result = New Structure;
	Result.Insert("TotalTime",          0);
	Result.Insert("OperationsCount",  0);
	Result.Insert("InPerformedStatus",   0);
	Result.Insert("InTheStatusInProgress", 0);
	Result.Insert("InNotPerformedStatus", 0);
	Result.Insert("InTheCreatedStatus",     0);
	Result.Insert("InTheSkippedStatus",   0);
	
	If Ref.IsEmpty() Then
		Return Result;
	EndIf;
	
	If OperationsFromRegister(Status) Then
		
		QueryText = 
			"SELECT
			|	SUM(
			|		&OperationTime_
			|			* CASE Operations.TimeUnitsOfMeasure
			|				WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
			|					THEN 60
			|				WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
			|					THEN 3600
			|				WHEN VALUE(Enum.TimeMeasureUnits.DAY)
			|					THEN 86400
			|				WHEN VALUE(Enum.TimeMeasureUnits.Days1)
			|					THEN 86400
			|				ELSE 1
			|			END
			|	)        AS TimeSeconds,
			|	SUM(1) AS OperationsCount
			|FROM
			|	InformationRegister.OperationsToCreateShiftTasks AS Operations
			|WHERE
			|	Operations.ShiftTask = &Ref
			|
			|HAVING
			|	SUM(1) IS NOT NULL ";
		
		QueryText = StrReplace(
			QueryText,
			"&OperationTime_",
			InformationRegisters.OperationsToCreateShiftTasks.QueryTextOperationTime_("Operations"));
		
		ListOfProperties = "OperationsCount";
		
	Else
		
		QueryText = 
			"SELECT
			|	SUM(CASE Operations.ExecutionTimeUnitOfMeasure
			|			WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
			|				THEN Operations.RunTime * 60
			|			WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
			|				THEN Operations.RunTime * 3600
			|			WHEN VALUE(Enum.TimeMeasureUnits.DAY)
			|				THEN Operations.RunTime * 86400
			|			WHEN VALUE(Enum.TimeMeasureUnits.Days1)
			|				THEN Operations.RunTime * 86400
			|			ELSE Operations.RunTime
			|		END) AS TimeSeconds,
			|	SUM(1)   AS OperationsCount,
			|	SUM(CASE
			|			WHEN Operations.Status = VALUE(Enum.ProductionOperationStatuses.CreatedOn_)
			|				THEN 1
			|			ELSE 0
			|		END) AS InTheCreatedStatus,
			|	SUM(CASE
			|			WHEN Operations.Status = VALUE(Enum.ProductionOperationStatuses.Running)
			|				THEN 1
			|			ELSE 0
			|		END) AS InTheStatusInProgress,
			|	SUM(CASE
			|			WHEN Operations.Status = VALUE(Enum.ProductionOperationStatuses.Executed)
			|				THEN 1
			|			ELSE 0
			|		END) AS InPerformedStatus,
			|	SUM(CASE
			|			WHEN Operations.Status = VALUE(Enum.ProductionOperationStatuses.NotExecuted)
			|				THEN 1
			|			ELSE 0
			|		END) AS InNotPerformedStatus,
			|	SUM(CASE
			|			WHEN Operations.Status = VALUE(Enum.ProductionOperationStatuses.IsSkipped)
			|				THEN 1
			|			ELSE 0
			|		END) AS InTheSkippedStatus
			|FROM
			|	Document.ProductionOperation2_2 AS Operations
			|WHERE
			|	Operations.ShiftTask = &Ref
			|
			|HAVING
			|	SUM(1) IS NOT NULL ";
		
		ListOfProperties = "OperationsCount,InTheCreatedStatus,InTheStatusInProgress,InPerformedStatus,InNotPerformedStatus,InTheSkippedStatus";
		
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		Result.TotalTime = ProductionPlanningClientServer.GetTimeInUnit(
			Selection.TimeSeconds,
			Enums.TimeMeasureUnits.Hour);
			
		FillPropertyValues(Result, Selection, ListOfProperties);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function OperationsFromRegister(Status)
	
	Return Status = PredefinedValue("Enum.ShiftTaskStatuses.BeingGenerated");
	
EndFunction

&AtClient
Procedure SetStatusInBackgroundCompletion(Result, AddlParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		
		ProcessResultOfSettingStatusInBackground(Result);
		
		NotifyAboutChangeInShiftTask();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultOfSettingStatusInBackground(Result)
	
	Read();
	
	If Result.Status = "Error" Then
		
		ResultStructure = GetFromTempStorage(Result.ResultAddress);
		
		If TypeOf(ResultStructure) = Type("Structure") And ResultStructure.Property("Messages") Then
			
			For Each Message In ResultStructure.Messages Do
			
				Message.TargetID = UUID;
				Message.Message();
				
			EndDo;
			
		EndIf;
		
		Raise Result.BriefErrorDescription;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function HyperlinkValueIsIndicatedInCreatedStatus()
	
	Return "#SelectOperationsWithCreatedStatus";
	
EndFunction

&AtClientAtServerNoContext
Function HyperlinkValueSelectionInProgressStatus()
	
	Return "#SelectOperationsWithInProgressStatus";
	
EndFunction

&AtClientAtServerNoContext
Function HyperlinkValueIsDisplayedWithStatusCompleted()
	
	Return "#SelectOperationsWithCompletedStatus";
	
EndFunction

&AtClientAtServerNoContext
Function HyperlinkValueSelectionWithFailedStatus()
	
	Return "#SelectOperationsWithFailedStatus";
	
EndFunction

&AtClientAtServerNoContext
Function HyperlinkValueIsDisplayedWithSkippedStatus()
	
	Return "#SelectOperationsWithSkippedStatus";
	
EndFunction

&AtClientAtServerNoContext
Function ValueOfDisableStatusSelectionHyperlink()
	
	Return "#DisableOperationStatusSelection";
	
EndFunction

&AtClient
Procedure CheckPerformActionsBeforeSettingClosedStatus()
	
	Actions = ActionsBeforeSettingClosedStatus(Object.Ref);
	
	If Actions.OperationControlFailed Then
		
		ShowMessageBox(, NStr("vi = 'Trong nhiệm vụ theo ca có các giao dịch được kiểm soát mà chưa vượt qua kiểm soát.
		|Trước khi đóng nhiệm vụ theo ca, cần thực hiện kiểm soát các giao dịch này.';
		|ru = 'В сменном задании присутствуют контролируемые операции, не прошедшие контроль.
		|Перед закрытием сменного задания необходимо произвести контроль данных операций.';
		|en = 'A shift task contains controlled operations that have not passed the control.
		|Control these operations before closing the shift task.'; fa = 'A shift task contains controlled operations that have not passed the control.
		|Control these operations before closing the shift task.';
		|it = 'Nel compito di turno vi sono operazioni controllate che non hanno superato il controllo.
		|PRima di chiudere il compito di turno è necessario eseguire il controllo di questa operazione.';
		|pl = 'W zadaniu zmiany są kontrolowane operacje, które nie przeszły kontroli.
		|Przed zamknięciem zadania zmiany należy przeprowadzić kontrolę tych operacji.';
		|tr = 'Vardiyalı görevde, kontrolü geçmeyen kontrollü işlemler bulunmaktadır.
		|Vardiyalı görevi kapatmadan önce bu işlemleri kontrol etmeniz gerekmektedir.'"));
		
	ElsIf Actions.WarnBrokenOrder Then
		
		OpenWarningBrokenAssignmentOrder(
			PredefinedValue("Enum.ShiftTaskStatuses.Closed"));
		
	ElsIf Actions.OpenClosingAssistant Then
		
		OpenClosingAssistant();
		
	Else
		
		SetStatus(PredefinedValue("Enum.ShiftTaskStatuses.Closed"));
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ActionsBeforeSettingClosedStatus(Ref)
	
	Result = New Structure("OperationControlFailed, WarnBrokenOrder, OpenClosingAssistant", False, False, False);
	
	If ThereAreControlledOperationsThatHaveNotPassedControl(Ref) Then
		
		Result.OperationControlFailed = True;
	
	ElsIf AssignmentProcedureIsViolated(Ref) Then
		
		Result.WarnBrokenOrder = True;
		
	Else
		
		Result.OpenClosingAssistant = YouNeedToCloseJobUsingHelper(Ref);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function ThereAreControlledOperationsThatHaveNotPassedControl(Ref)
	
	UseOperationExecutionControl = GetFunctionalOption("UseOperationExecutionControl");
	If Not UseOperationExecutionControl Then
		Return False;
	EndIf;
	
	QueryText = 
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.ProductionOperation2_2 AS Operations
	|WHERE
	|	Operations.Posted
	|	AND Operations.ShiftTask = &ShiftTask
	|	AND Operations.Control = VALUE(Enum.ManufacturingOperationControlOptions.Required2)
	|	AND (Operations.Status NOT IN (
	|				VALUE(Enum.ProductionOperationStatuses.Executed),
	|				VALUE(Enum.ProductionOperationStatuses.NotExecuted),
	|				VALUE(Enum.ProductionOperationStatuses.IsSkipped))
	|			OR Operations.FollowUp > 0
	|			OR Operations.QuantityUnderRevision > 0)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("ShiftTask", Ref);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtServerNoContext
Function AssignmentProcedureIsViolated(Ref)
	
	Query = New Query(
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS OperationsToCreateShiftTasks
		|WHERE
		|	OperationsToCreateShiftTasks.ShiftTask = &Ref
		|	AND OperationsToCreateShiftTasks.AssignmentProcedureIsViolated");
	Query.SetParameter("Ref", Ref);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtServerNoContext
Function YouNeedToCloseJobUsingHelper(Ref)
	
	Result = False;
	
	Query = New Query(
		"SELECT
		|	ProductionOperation2_2.Ref                        AS Ref,
		|
		|	ProductionOperation2_2.Status = &CreatedOn_
		|		OR ProductionOperation2_2.Status = &Running AS CloseOperations,
		|
		|	ProductionOperation2_2.Status = &CreatedOn_             AS ThatSAll,
		|	ProductionOperation2_2.Status = &Running         AS EverythingIsExecuted
		|	
		|FROM
		|	Document.ProductionOperation2_2 AS ProductionOperation2_2
		|WHERE
		|	ProductionOperation2_2.Posted
		|	AND ProductionOperation2_2.ShiftTask = &ShiftTask
		|TOTALS
		|	MAX(CloseOperations),
		|	MIN(ThatSAll),
		|	MIN(EverythingIsExecuted)
		|BY
		|	OVERALL");
	
	Query.SetParameter("ShiftTask", Ref);
	Query.SetParameter("CreatedOn_", Enums.ProductionOperationStatuses.CreatedOn_);
	Query.SetParameter("Running", Enums.ProductionOperationStatuses.Running);
	
	SampleResults = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	If SampleResults.Next() Then
		
		If SampleResults.CloseOperations Then
			
			If SampleResults.ThatSAll Or SampleResults.EverythingIsExecuted Then
				
				References = New Array;
				
				Selection = SampleResults.Select();
				While Selection.Next() Do
					References.Add(Selection.Ref);
				EndDo;
				
				GeneralPurposeTMServerCall.SetStatusOfDocuments(
					References,
					"Executed");
				
			Else
				
				Result = True;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure NotifyAboutChangeInShiftTask()
	
	NotifyChanged(Object.Ref);
	
	NotificationParameter1 = New Structure;
	NotificationParameter1.Insert("Department", Object.Department);
	NotificationParameter1.Insert("Ref",        Object.Ref);
	
	If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
		NotificationSource = FormOwner.UUID;
	Else
		NotificationSource = UUID;
	EndIf;
	
	Notify("Write_ShiftTask", NotificationParameter1, NotificationSource);
	
EndProcedure

&AtClient
Procedure ConfirmationWhenSettingStatusOfOperationsEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If AdditionalParameters.EventBeingConfirmed = ProductionAccountingClientServer.Confirmation_CancellationOfIndicators()
		And QuestionResult = DialogReturnCode.Yes Then
			
		ProductionAccountingClient.SetProductionOperationStatus(
			AdditionalParameters.OperationKeys, AdditionalParameters.NewStatus, Object.Department);
			
	ElsIf AdditionalParameters.EventBeingConfirmed = ProductionAccountingClientServer.Confirmation_CreatingIndividualOperation() Then
		
		If QuestionResult = DialogReturnCode.Yes Then
			For Each OperationKey In AdditionalParameters.OperationKeys Do
				RowData = Items.TransactionsDocument.RowData(OperationKey);
				If ProductionProcessEditorClientServer.ThisOperationIsIndividual(RowData) Then
					OpenForm("Document.ProductionOperation2_2.Form.DocumentForm",
						New Structure("CopyingValue", RowData.Ref),
						ThisObject, RowData.Ref);
				EndIf;
			EndDo;
		EndIf;
		ProductionAccountingClient.SetProductionOperationStatus(
			AdditionalParameters.OperationKeys, AdditionalParameters.NewStatus, Object.Department);
		
	EndIf;
	
EndProcedure

#EndRegion

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

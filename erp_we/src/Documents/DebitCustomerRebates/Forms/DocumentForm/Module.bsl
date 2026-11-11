//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnCreatReadAtServer();
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		ReadOnly = True;
		
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnCreatReadAtServer();
		
	EndIf;
	
	SetHeader();
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SetHeader();
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
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

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.ShowConfirmationForClosingFormWithFiles(ThisObject, Cancel, Exit, Object.Ref);
	If Cancel Then
		Return;
	EndIf;
	// End StandardSubsystems.FilesOperations
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StatusOnChange(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDrillDownDebits

&AtClient
Procedure DrillDownDebitsBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure DrillDownDebitsAfterDeleteRow(Item)
	
	If Object.DrillDownDebits.Count() = 0 Then
		
		Object.Currency = PredefinedValue("Catalog.Currencies.EmptyRef");
		DocumentCurrency = Object.Currency;
		
	EndIf;
	
	CalculateTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure DecryptionOfPartnerDebitsStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure DecryptionOfPartnerDebitsClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure DecryptionOfWriteOffConditionsDocumentStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure DecryptionOfWriteOffConditionsDocumentClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure DecryptionOfDebitsAmountOnChange(Item)
	
	CalculateTotals(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);

EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);

EndProcedure

&AtClient
Procedure PickUpByBalance(Command)
	
	ClearMessages();
	Cancel = False;
	FieldKind = "Field";
	MessageKind = "FillType";
	
	If Not ValueIsFilled(Object.Organization) Then
		
		FieldName = NStr("vi = 'Doanh nghiệp';
						|ru = 'Организация';
						|en = 'Company'; fa = 'Company';
						|it = 'Организация';
						|pl = 'Firma';
						|tr = 'İş yeri'");
		MessageText = CommonClientServer.FillingErrorText(FieldKind, MessageKind, FieldName);
		CommonClient.MessageToUser(MessageText,, "Object.Organization",, Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(Object.Counterparty) Then
		
		FieldName = NStr("vi = 'Đối tác';
						|ru = 'Контрагент';
						|en = 'Counterparty'; fa = 'طرف حساب';
						|it = 'Контрагент';
						|pl = 'Kontrahent';
						|tr = 'Cari hesap'");
		MessageText = CommonClientServer.FillingErrorText(FieldKind, MessageKind, FieldName);
		CommonClient.MessageToUser(MessageText,, "Object.Counterparty",, Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(Object.Date) Then
		
		FieldName = NStr("vi = 'Ngày';
						|ru = 'Дата';
						|en = 'Date'; fa = 'تاریخ';
						|it = 'Дата';
						|pl = 'Date';
						|tr = 'Tarih'");
		MessageText = CommonClientServer.FillingErrorText(FieldKind, MessageKind, FieldName);
		CommonClient.MessageToUser(MessageText,, "Object.Date",, Cancel);
		
	EndIf;
	
	If Not Cancel Then
		
		PickUpAccruedRB();
		
	EndIf;
	
EndProcedure

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties

// StandardSubsystems.AttachableCommands

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

// StandardSubsystems.FilesOperations

// Parameters:
//  Command - FormCommand - executed command.
//
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
	
EndProcedure

// End StandardSubsystems.FilesOperations

// IntegrationWith1CDocumentManagementSubsystem

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

&AtServer
Procedure OnCreatReadAtServer()
	
	DocumentCurrency = Object.Currency;
	CalculateTotals(ThisObject);
	
EndProcedure

#Region Other

&AtClientAtServerNoContext
Procedure CalculateTotals(Form)
	
	Object = Form.Object;
	AmountTotal = Object.DrillDownDebits.Total("Sum");
	Form.AmountTotal = AmountTotal;
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure SetHeader()
	
	AutoTitle = False;
	Title = RebatesServer.DocumentTitle(
		Object.Ref, Object.Number, Object.Date);
	
EndProcedure

#EndRegion

#Region SelectionByStock

&AtClient
Async Procedure PickUpAccruedRB()
	
	QuestionIsRequired = False;
	If Object.Posted Then
		
		QuestionIsRequired = True;
		QueryText = NStr("vi = 'Trước khi chọn phương án tính, cần hủy kết chuyển chứng từ. Tiếp tục?';
						|ru = 'Перед подбором начислений необходимо отменить проведение документа. Продолжить?';
						|en = 'Before you pick accruals, unpost the document. Continue?'; fa = 'Before you pick accruals, unpost the document. Continue?';
						|it = 'Перед подбором начислений необходимо отменить проведение документа. Продолжить?';
						|pl = 'Before you pick accruals, unpost the document. Continue?';
						|tr = 'Tahakkukları seçmeden önce belge işlemini iptal etmelisiniz. Devam edilsin mi?'");
		
	EndIf;
	
	If QuestionIsRequired Then
		
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
		If Response = DialogReturnCode.No Then
			Return;
		Else
			
			If Object.Posted Then
				Write(New Structure("WriteMode", DocumentWriteMode.UndoPosting));
			EndIf;
			
		EndIf;
		
	EndIf;
	
	PickUpAccruedRBContinue();
	
EndProcedure

&AtClient
Procedure PickUpAccruedRBContinue()
	
	AddressOfTableOfSelectedRows = AddressOfTableOfSelectedRows();
	
	PickingParameters = New Structure;
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("Counterparty", Object.Counterparty);
	PickingParameters.Insert("AddressOfTableOfSelectedRows", AddressOfTableOfSelectedRows);
	PickingParameters.Insert("ChoiceMode", True);
	PickingParameters.Insert("UpdateDate", Object.Date);
	
	If ValueIsFilled(Object.Currency) Then
		PickingParameters.Insert("Currency", Object.Currency);
	EndIf;
	Notification = New CallbackDescription("PickUpAccruedRBCompletion", ThisObject);
	
	OpenForm("AccumulationRegister.CustomerRebates.Form.FormForPickingByBalance",
		PickingParameters, ThisObject,,,, Notification);
	
EndProcedure

&AtServer
Function AddressOfTableOfSelectedRows()
	
	Table_SelectedRows = Object.DrillDownDebits.Unload();
	Table_SelectedRows.Columns.Add("DocumentSelected", New TypeDescription("Boolean"));
	Table_SelectedRows.Columns.Add("Check", New TypeDescription("Boolean"));
	Table_SelectedRows.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	
	For Each TableRow In Table_SelectedRows Do
		
		TableRow.DocumentSelected = True;
		TableRow.Check = True;
		TableRow.Currency = Object.Currency;
		
	EndDo;
	AddressOfTableOfSelectedRows = PutToTempStorage(Table_SelectedRows, UUID);
	
	Return AddressOfTableOfSelectedRows;
	
EndFunction

// Parameters:
//  Result - Undefined, String - 
//  AdditionalParameters - Arbitrary -
//
&AtClient
Procedure PickUpAccruedRBCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined
	   And IsTempStorageURL(Result) Then
		
		ProcessingSelectionOfAccrualDocuments(Result);
		CalculateTotals(ThisObject);
		Modified = True;
		
	EndIf;
	
EndProcedure

// Parameters:
//  AddressInStorage - String - Address in the store
//
&AtServer
Procedure ProcessingSelectionOfAccrualDocuments(Val AddressInStorage)
	
	BalanceTable = TableOfSelectedBalances(AddressInStorage);
	DeleteFromTempStorage(AddressInStorage);
	Object.DrillDownDebits.Clear();
	
	If BalanceTable.Count() > 0
	   And Not ValueIsFilled(Object.Currency) Then
		Object.Currency = BalanceTable[0].Currency;
	EndIf;
	
	Object.DrillDownDebits.Load(BalanceTable);
	
	If Object.DrillDownDebits.Count() = 0 Then
		Object.Currency = Catalogs.Currencies.EmptyRef();
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

// Parameters:
//  AddressInStorage - String - Address in the store
// 
// Returns:
//  ValueTable:
//   * TermDocument - DocumentRef.ConditionsOfCustomerRebates
//   * Partner - CatalogRef.Partners
//   * ValidOnDate - Date
//   * ValidTo - Date
//   * Sum - DefinedType.MonetaryAmountNonNegative
//   * Currency - CatalogRef.Currencies
//
&AtServer
Function TableOfSelectedBalances(AddressInStorage)
	
	Return GetFromTempStorage(AddressInStorage);
	
EndFunction

#EndRegion

#Region StandardSubsystems_PlugInCommands

// StandardSubsystems.AttachableCommands

// The Attachable one continues to execute the Commands on the server.
// 
// Parameters:
//  ExecutionParameters - Structure -
//  AdditionalParameters - Structure -
//
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#Region StandardSubsystems_Properties

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

//@skip-check module-unused-method - implicit call from the property managementmiclient.Post-loadingadditional requirements
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

// End StandardSubsystems.Properties

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

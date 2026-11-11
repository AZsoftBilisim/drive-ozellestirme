
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	SetListRequestText();
	
	SetVisibility1();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "ClosingOrders" Then
		Items.List.Refresh();
	EndIf; 
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnChange(Item)
	
	ProvisionInDocumentsClient.ListOnChange(ThisObject, "Document.InventoryConsumptionOrder");
	
EndProcedure

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
// End StandardSubsystems.AttachableCommands


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure SetTheClosedStatus(Command)
	
	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	
	If HighlightedLinks.Count() = 0 Then
		
		Return;
		
	EndIf;
	
	ClosureStructure = New Structure;
	OrderList = New ValueList;
	OrderList.LoadValues(HighlightedLinks);
	ClosureStructure.Insert("Orders",                       OrderList);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm", ClosureStructure,
					ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SetTheStatusToExecute(Command)
	
	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	
	If HighlightedLinks.Count() = 0 Then
		
		Return;
		
	EndIf;
	
	QueryText = NStr("vi = 'Đặt trạng thái ""Cần thực hiện"" đối với các đơn hàng được chọn trong danh sách. Tiếp tục?';
					|ru = 'У выделенных в списке заказов будет установлен статус ""К выполнению"". Продолжить?';
					|en = 'The ""Confirmed"" status will be set for the selected orders. Continue?'; fa = 'The ""Confirmed"" status will be set for the selected orders. Continue?';
					|it = 'Agli ordini selezionati nell''elenco verrà assegnato lo stato ""Da eseguire"". Continuare?';
					|pl = 'U wybranych w liście zamówień ustawiono status ""К выполнению"". Kontynuować?';
					|tr = 'Listede belirtilen siparişler için ""Gerçekleştirilecek"" durumu ayarlanacaktır. Devam edilsin mi?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("SetTheStatusToExecuteCompletion", ThisObject, New Structure("HighlightedLinks", HighlightedLinks)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusToExecuteCompletion(QuestionResult, AdditionalParameters) Export
    
    HighlightedLinks = AdditionalParameters.HighlightedLinks;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        
        Return;
        
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(HighlightedLinks, "ForCompletion");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, HighlightedLinks.Count(), NStr("vi = 'Cần thực hiện';
																													|ru = 'К выполнению';
																													|en = 'Confirmed'; fa = 'تأییدشده';
																													|it = 'Da eseguire';
																													|pl = 'Do wykonania';
																													|tr = 'Gerçekleştirilecek'"));

EndProcedure

&AtClient
Procedure SetTheStatusForApproval(Command)
	
	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	
	If HighlightedLinks.Count() = 0 Then
		
		Return;
		
	EndIf;
	
	QueryText = NStr("vi = 'Trong các đơn hàng được chọn của danh sách đơn hàng, sẽ đặt trạng thái ""Chờ thống nhất"". Tiếp tục?';
					|ru = 'У выделенных в списке заказов будет установлен статус ""На согласовании"". Продолжить?';
					|en = 'The ""Pending approval"" status will be set for the orders selected in the list. Continue?'; fa = 'The ""Pending approval"" status will be set for the orders selected in the list. Continue?';
					|it = 'У выделенных в списке заказов будет установлен статус ""На согласовании"". Продолжить?';
					|pl = 'The ""Pending approval"" status will be set for the orders selected in the list. Continue?';
					|tr = 'Listede vurgulanan siparişlerin durumu ""Onay bekliyor"" olacaktır. Devam edilsin mi?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("SetTheStatusForApprovalCompletion", ThisObject, New Structure("HighlightedLinks", HighlightedLinks)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusForApprovalCompletion(QuestionResult, AdditionalParameters) Export

	HighlightedLinks = AdditionalParameters.HighlightedLinks;

	Response = QuestionResult;

	If Response = DialogReturnCode.No Then

		Return;

	EndIf;

	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(HighlightedLinks,
		"AwaitingApproval");
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount,
		HighlightedLinks.Count(), NStr("vi = 'Cần thống nhất';
										|ru = 'На согласовании';
										|en = 'Pending approval'; fa = 'در انتظار تأیید';
										|it = 'In fase di definizione';
										|pl = 'Na uzgodnieniu';
										|tr = 'Onay bekliyor'"));
	
	ResultOfActions = SupplyInDocumentsServerCall.PerformActionInOrderList(
		HighlightedLinks,
		"rollback_Actions_Ship",
		UUID);
		
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	AdditionalParameters = New Structure("Form,Orders",
		ThisObject, HighlightedLinks);
	TimeConsumingOperationsClient.WaitCompletion(ResultOfActions,
		New CallbackDescription("CommandProcessingCompletion", ThisObject, AdditionalParameters),
		IdleParameters);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Internal

&AtClient
Procedure CommandProcessingCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		
		Return;
		
	ElsIf Result.Status = "Error" Then
		
		ShowMessageBox(, Result.BriefErrorDescription);
		
	Else
		
		Form = AdditionalParameters.Form;
		ResultOfActions = GetFromTempStorage(Result.ResultAddress);
		Form.OrdersToCheckTheInventoryAllocationTask.LoadValues(AdditionalParameters.Orders);
		Form.AttachIdleHandler("Attachable_CheckWhetherInventoryAllocationTaskIsCompletedForOrders", 1, True);
		ProvisionInDocumentsClient.ReportResultsOfActionsInOrderList(ResultOfActions);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Other

&AtServer
Procedure SetListRequestText()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, List);
	
	If AccessRight("Read", Metadata.InformationRegisters.StatusesOfInternalOrders) Then
		
		ListProperties.QueryText =
		"SELECT
		|	DocumentInventoryConsumptionOrder.Ref,
		|	DocumentInventoryConsumptionOrder.DeletionMark,
		|	DocumentInventoryConsumptionOrder.Number,
		|	DocumentInventoryConsumptionOrder.Date,
		|	DocumentInventoryConsumptionOrder.Posted,
		|	DocumentInventoryConsumptionOrder.Comment,
		|	DocumentInventoryConsumptionOrder.Organization,
		|	DocumentInventoryConsumptionOrder.EmployeeResponsible,
		|	DocumentInventoryConsumptionOrder.Department,
		|	DocumentInventoryConsumptionOrder.Warehouse,
		|	DocumentInventoryConsumptionOrder.Status,
		|	DocumentInventoryConsumptionOrder.Priority,
		|	DocumentInventoryConsumptionOrder.MaximumRowCode,
		|	DocumentInventoryConsumptionOrder.SalesOpportunity,
		|	DocumentInventoryConsumptionOrder.BusinessOperation,
		|	DocumentInventoryConsumptionOrder.DateOfShipment,
		|	DocumentInventoryConsumptionOrder.NotShipInInstallments,
		|	DocumentInventoryConsumptionOrder.Purpose,
		|	DocumentInventoryConsumptionOrder.DocumentBasis,
		|	DocumentInventoryConsumptionOrder.ReusablePackageFillingStatus,
		|	DocumentInventoryConsumptionOrder.PointInTime,
		|	DocumentInventoryConsumptionOrder.Author,
		|	DocumentInventoryConsumptionOrder.Goods,
		|	CASE
		|		WHEN NOT DocumentInventoryConsumptionOrder.Posted
		|			THEN VALUE(Enum.StatusesOfInternalOrders.EmptyRef)
		|		ELSE ISNULL(StatusesOfInternalOrders.State, VALUE(Enum.StatusesOfInternalOrders.Closed))
		|	END AS State,
		|	ISNULL(StatusesOfInternalOrders.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice, FALSE) AS ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice
		|FROM
		|	Document.InventoryConsumptionOrder AS DocumentInventoryConsumptionOrder
		|		LEFT JOIN InformationRegister.StatusesOfInternalOrders AS StatusesOfInternalOrders
		|		ON (StatusesOfInternalOrders.OrderDocument = DocumentInventoryConsumptionOrder.Ref)";
		
	Else
		
		ListProperties.QueryText =
		"SELECT
		|	DocumentInventoryConsumptionOrder.Ref,
		|	DocumentInventoryConsumptionOrder.DeletionMark,
		|	DocumentInventoryConsumptionOrder.Number,
		|	DocumentInventoryConsumptionOrder.Date,
		|	DocumentInventoryConsumptionOrder.Posted,
		|	DocumentInventoryConsumptionOrder.Comment,
		|	DocumentInventoryConsumptionOrder.Organization,
		|	DocumentInventoryConsumptionOrder.EmployeeResponsible,
		|	DocumentInventoryConsumptionOrder.Department,
		|	DocumentInventoryConsumptionOrder.Warehouse,
		|	DocumentInventoryConsumptionOrder.Status,
		|	DocumentInventoryConsumptionOrder.Priority,
		|	DocumentInventoryConsumptionOrder.MaximumRowCode,
		|	DocumentInventoryConsumptionOrder.SalesOpportunity,
		|	DocumentInventoryConsumptionOrder.BusinessOperation,
		|	DocumentInventoryConsumptionOrder.DateOfShipment,
		|	DocumentInventoryConsumptionOrder.NotShipInInstallments,
		|	DocumentInventoryConsumptionOrder.Purpose,
		|	DocumentInventoryConsumptionOrder.DocumentBasis,
		|	DocumentInventoryConsumptionOrder.ReusablePackageFillingStatus,
		|	DocumentInventoryConsumptionOrder.PointInTime,
		|	DocumentInventoryConsumptionOrder.Author,
		|	DocumentInventoryConsumptionOrder.Goods
		|FROM
		|	Document.InventoryConsumptionOrder AS DocumentInventoryConsumptionOrder";
		
	EndIf;
	
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	ThereIsChangeAccess = AccessRight("Update", Metadata.Documents.InventoryConsumptionOrder);
	
	Items.SetTheStatusForApproval.Visible = ThereIsChangeAccess
		And GetFunctionalOption("UseStatusesOfInventoryConsumptionOrders");
	Items.SetTheStatusToExecute.Visible = ThereIsChangeAccess
		And GetFunctionalOption("UseStatusesOfInventoryConsumptionOrders");
	Items.SetTheClosedStatus.Visible = ThereIsChangeAccess
		And GetFunctionalOption("UseStatusesOfInventoryConsumptionOrders");
	
	If Not AccessRight("Read", Metadata.InformationRegisters.StatusesOfInternalOrders) Then
		Items.State.Visible = False;
	EndIf;
	
	Items.ListShipByOrder.Visible = ThereIsChangeAccess;
	Items.ListReserveAnOrder.Visible = ThereIsChangeAccess;
	Items.ListToSupplyOrder.Visible = ThereIsChangeAccess;
	Items.ListReserveAsReceivedOrder.Visible = ThereIsChangeAccess;
	Items.ListDoNotSupplyOrder.Visible = ThereIsChangeAccess;
	
EndProcedure

&AtClient
Procedure Attachable_CheckWhetherInventoryAllocationTaskIsCompletedForOrders()
	ProvisionInDocumentsClient.CheckWhetherInventoryAllocationTaskIsCompletedForOrders(ThisObject, Items.List);
EndProcedure

#EndRegion

#Region Performance

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.InventoryConsumptionOrder.ListForm.Item.List.Selection");
	
EndProcedure

#EndRegion

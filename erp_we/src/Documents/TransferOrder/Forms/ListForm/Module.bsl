
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	SetListRequestText();  
	
	If ValueIsFilled(Parameters.FormCaption) Then
		Title = Parameters.FormCaption;
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(
		List, "CurrentDayStart", BegOfDay(CurrentSessionDate()), True);
	
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
	
	ProvisionInDocumentsClient.ListOnChange(ThisObject, "Document.TransferOrder.EmptyRef");
	
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
Procedure CreateOrderForInternalGoodsTransfer(Command)
	
	BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices");
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Basis", New Structure("BusinessOperation", BusinessOperation));
	OpenForm("Document.TransferOrder.ObjectForm", ParametersStructure1, Items.List);
	
EndProcedure

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
	
	QueryText = NStr("vi = 'Trong các đơn hàng đã chọn trong danh sách sẽ đặt trạng thái ""Cần thực hiện"". Tiếp tục?';
					|ru = 'У выделенных в списке заказов будет установлен статус ""К выполнению"". Продолжить?';
					|en = 'The ""For completion"" status will be set for the selected orders. Continue?'; fa = 'The ""For completion"" status will be set for the selected orders. Continue?';
					|it = 'Agli ordini selezionati nell''elenco verrà assegnato lo stato ""Da eseguire"". Continuare?';
					|pl = 'U wybranych w liście zamówień ustawiono status ""К выполнению"". Kontynuować?';
					|tr = 'Listede seçilen siparişler ""Tamamlanacak"" durumuna ayarlanacaktır. Devam edilsin mi?'");
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
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, HighlightedLinks.Count(),
    NStr("vi = 'Cần thực hiện';
		|ru = 'К выполнению';
		|en = 'Ready for fulfillment'; fa = 'آماده اجرا';
		|it = 'Da eseguire';
		|pl = 'Do wykonania';
		|tr = 'Gerçekleştirilecek'"));

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

#EndRegion

#Region Other

&AtServer
Procedure SetListRequestText()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, List);
	
	If AccessRight("Read", Metadata.InformationRegisters.StatusesOfInternalOrders) Then
		
		ListProperties.QueryText =
		"SELECT
		|	DocumentTransferOrder.Ref,
		|	DocumentTransferOrder.DeletionMark,
		|	DocumentTransferOrder.Number,
		|	DocumentTransferOrder.Date,
		|	DocumentTransferOrder.Posted,
		|	DocumentTransferOrder.TransferDurationDays,
		|	DocumentTransferOrder.RequestedDeliveryDate,
		|	DocumentTransferOrder.Comment,
		|	DocumentTransferOrder.MaximumRowCode,
		|	DocumentTransferOrder.Organization,
		|	DocumentTransferOrder.CompanyRecipient,
		|	DocumentTransferOrder.EmployeeResponsible,
		|	DocumentTransferOrder.Department,
		|	DocumentTransferOrder.SalesOpportunity,
		|	DocumentTransferOrder.SourceWarehouse,
		|	DocumentTransferOrder.DestinationWarehouse,
		|	DocumentTransferOrder.Status,
		|	DocumentTransferOrder.Priority,
		|	DocumentTransferOrder.BusinessOperation,
		|	DocumentTransferOrder.Purpose,
		|	DocumentTransferOrder.DocumentBasis,
		|	DocumentTransferOrder.ReusablePackageFillingStatus,
		|	DocumentTransferOrder.PointInTime,
		|	DocumentTransferOrder.Author,
		|	CASE
		|		WHEN NOT DocumentTransferOrder.Posted
		|			THEN VALUE(Enum.StatusesOfInternalOrders.EmptyRef)
		|		ELSE ISNULL(StatusesOfInternalOrders.State, VALUE(Enum.StatusesOfInternalOrders.Closed))
		|	END AS State,
		|	ISNULL(StatusesOfInternalOrders.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice, FALSE) AS ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice
		|FROM
		|	Document.TransferOrder AS DocumentTransferOrder
		|		LEFT JOIN InformationRegister.StatusesOfInternalOrders AS StatusesOfInternalOrders
		|		ON (StatusesOfInternalOrders.OrderDocument = DocumentTransferOrder.Ref)";
		
	Else
		
		ListProperties.QueryText =
		"SELECT
		|	DocumentTransferOrder.Ref,
		|	DocumentTransferOrder.DeletionMark,
		|	DocumentTransferOrder.Number,
		|	DocumentTransferOrder.Date,
		|	DocumentTransferOrder.Posted,
		|	DocumentTransferOrder.TransferDurationDays,
		|	DocumentTransferOrder.RequestedDeliveryDate,
		|	DocumentTransferOrder.Comment,
		|	DocumentTransferOrder.MaximumRowCode,
		|	DocumentTransferOrder.Organization,
		|	DocumentTransferOrder.CompanyRecipient,
		|	DocumentTransferOrder.EmployeeResponsible,
		|	DocumentTransferOrder.Department,
		|	DocumentTransferOrder.SalesOpportunity,
		|	DocumentTransferOrder.SourceWarehouse,
		|	DocumentTransferOrder.DestinationWarehouse,
		|	DocumentTransferOrder.Status,
		|	DocumentTransferOrder.Priority,
		|	DocumentTransferOrder.BusinessOperation,
		|	DocumentTransferOrder.Purpose,
		|	DocumentTransferOrder.DocumentBasis,
		|	DocumentTransferOrder.ReusablePackageFillingStatus,
		|	DocumentTransferOrder.Author,
		|	DocumentTransferOrder.PointInTime
		|FROM
		|	Document.TransferOrder AS DocumentTransferOrder";
		
	EndIf;
	
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	ThereIsChangeAccess = AccessRight("Update", Metadata.Documents.TransferOrder);
	AccessRightInsert = Documents.TransferOrder.AccessRightInsert();
	
	UseAdvancedDemandFulfillment = GetFunctionalOption("UseAdvancedDemandFulfillment");
	UseBranchOfficesWithSeparateBalanceSheets = GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets");
	
	ThereIsCommandToCreateAccordingToNeeds = AccessRightInsert And UseAdvancedDemandFulfillment;
	ThereIsCommandToCreateInternalTransfer = AccessRightInsert And UseBranchOfficesWithSeparateBalanceSheets;
	ThereIsGroupOfCreationCommands = ThereIsCommandToCreateAccordingToNeeds Or ThereIsCommandToCreateInternalTransfer;
	
	CommonClientServer.SetFormItemProperty(Items, "FormCreate", "Visible",
		Not ThereIsGroupOfCreationCommands);
	CommonClientServer.SetFormItemProperty(Items,
		"ListCreate",
		"Visible",
		ThereIsGroupOfCreationCommands And Not ThereIsCommandToCreateInternalTransfer);
	CommonClientServer.SetFormItemProperty(Items,
		"CreateAProductTransferOrder",
		"Visible",
		ThereIsCommandToCreateInternalTransfer);
	Items.CreateOrderForInternalGoodsTransfer.Visible = ThereIsCommandToCreateInternalTransfer;
	CommonClientServer.SetFormItemProperty(Items,
		"FormGeneralTheTeamFormationOfTheTransferOrdersAccordingToNeeds",
		"Visible",
		ThereIsCommandToCreateAccordingToNeeds);
	
	Items.SetTheStatusToExecute.Visible = ThereIsChangeAccess
		And GetFunctionalOption("UseStatusesOfTransferOrders");
	Items.SetTheClosedStatus.Visible = ThereIsChangeAccess
		And GetFunctionalOption("UseStatusesOfTransferOrders");
	
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
		"Document.TransferOrder.ListForm.Item.List.Selection");
	
EndProcedure

#EndRegion


#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	SetListRequestText();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	SetVisibility1();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnChange(Item)
	
	ProvisionInDocumentsClient.ListOnChange(ThisObject, "Document.ByAssemblyDisassemblyOrder");
	
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

	ShowQueryBox(New CallbackDescription("SetTheStatusToExecuteCompletion", ThisObject, New Structure("HighlightedLinks", HighlightedLinks)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ShipByOrder(Command)
	
	ProvisionInDocumentsClient.PerformActionInListOfOrdersOfDifferentTypes(
		"ACTION_LOAD",
		Items.List,
		PredefinedValue("Document.ByAssemblyDisassemblyOrder.EmptyRef"),
		ThisObject);
	
EndProcedure

&AtClient
Procedure ReserveAnOrder(Command)
	
	ProvisionInDocumentsClient.PerformActionInListOfOrdersOfDifferentTypes(
		"ACTION_RESERVE",
		Items.List,
		PredefinedValue("Document.ByAssemblyDisassemblyOrder.EmptyRef"),
		ThisObject);
	
EndProcedure

&AtClient
Procedure ToSupplyOrder(Command)
	
	ProvisionInDocumentsClient.PerformActionInListOfOrdersOfDifferentTypes(
		"ACTION_COOPERATION",
		Items.List,
		PredefinedValue("Document.ByAssemblyDisassemblyOrder.EmptyRef"),
		ThisObject);
	
EndProcedure

&AtClient
Procedure ReserveAsReceivedOrder(Command)
	
	ProvisionInDocumentsClient.PerformActionInListOfOrdersOfDifferentTypes(
		"ACTION_RESERVATION_REFERENCES",
		Items.List,
		PredefinedValue("Document.ByAssemblyDisassemblyOrder.EmptyRef"),
		ThisObject);
	
EndProcedure

&AtClient
Procedure DoNotSupplyOrder(Command)
	
	ProvisionInDocumentsClient.PerformActionInListOfOrdersOfDifferentTypes(
		"ACTION_NOTABLE",
		Items.List,
		PredefinedValue("Document.ByAssemblyDisassemblyOrder.EmptyRef"),
		ThisObject);

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

#Region OtherItems

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "ClosingOrders" Then
		Items.List.Refresh();
	EndIf; 
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result)
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
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

#EndRegion

#Region SettingActions

&AtClient
Procedure PerformActionInListOfOrdersOfDifferentTypesCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		
		Return;
		
	ElsIf Result.Status = "Error" Then
		
		ShowMessageBox(, Result.BriefErrorDescription);
		
	Else
		
		OrdersToCheckTheInventoryAllocationTask.LoadValues(AdditionalParameters.Orders);
		AttachIdleHandler("Attachable_CheckWhetherInventoryAllocationTaskIsCompletedForOrders", 1, True);
		ResultOfActions = GetFromTempStorage(Result.ResultAddress);
		ProvisionInDocumentsClient.ReportResultsOfActionsInOrderList(ResultOfActions);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetListRequestText()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, List);
	
	If AccessRight("Read", Metadata.InformationRegisters.StatusesOfInternalOrders) Then
		
		ListProperties.QueryText =
		"SELECT
		|	DocumentByAssemblyDisassemblyOrder.Ref,
		|	DocumentByAssemblyDisassemblyOrder.DeletionMark,
		|	DocumentByAssemblyDisassemblyOrder.Number,
		|	DocumentByAssemblyDisassemblyOrder.Date,
		|	DocumentByAssemblyDisassemblyOrder.Priority,
		|	DocumentByAssemblyDisassemblyOrder.Posted,
		|	DocumentByAssemblyDisassemblyOrder.Organization,
		|	DocumentByAssemblyDisassemblyOrder.Warehouse,
		|	DocumentByAssemblyDisassemblyOrder.DocumentBasis,
		|	DocumentByAssemblyDisassemblyOrder.EmployeeResponsible,
		|	DocumentByAssemblyDisassemblyOrder.Status,
		|	DocumentByAssemblyDisassemblyOrder.Products,
		|	DocumentByAssemblyDisassemblyOrder.Characteristic,
		|	DocumentByAssemblyDisassemblyOrder.Package,
		|	DocumentByAssemblyDisassemblyOrder.NumberOfPackages,
		|	DocumentByAssemblyDisassemblyOrder.Count,
		|	DocumentByAssemblyDisassemblyOrder.BusinessOperation,
		|	DocumentByAssemblyDisassemblyOrder.Comment,
		|	DocumentByAssemblyDisassemblyOrder.AssemblyDisassemblyStart,
		|	DocumentByAssemblyDisassemblyOrder.AssemblyDisassemblyEnd,
		|	DocumentByAssemblyDisassemblyOrder.RequestedDeliveryDate,
		|	DocumentByAssemblyDisassemblyOrder.AssemblyDisassemblyDurationDays,
		|	DocumentByAssemblyDisassemblyOrder.MaximumRowCode,
		|	DocumentByAssemblyDisassemblyOrder.ProductKit,
		|	DocumentByAssemblyDisassemblyOrder.SalesOpportunity,
		|	DocumentByAssemblyDisassemblyOrder.Department,
		|	DocumentByAssemblyDisassemblyOrder.BatchesIndicationStatus,
		|	DocumentByAssemblyDisassemblyOrder.Purpose,
		|	DocumentByAssemblyDisassemblyOrder.AssignmentGoods,
		|	DocumentByAssemblyDisassemblyOrder.Series,
		|	DocumentByAssemblyDisassemblyOrder.SupplyOption,
		|	DocumentByAssemblyDisassemblyOrder.NumberOfPackagesCanceled,
		|	DocumentByAssemblyDisassemblyOrder.CountCanceled,
		|	DocumentByAssemblyDisassemblyOrder.Goods,
		|	DocumentByAssemblyDisassemblyOrder.SetOfSeries,
		|	DocumentByAssemblyDisassemblyOrder.PointInTime,
		|	DocumentByAssemblyDisassemblyOrder.Author,
		|	CASE
		|		WHEN NOT DocumentByAssemblyDisassemblyOrder.Posted
		|			THEN VALUE(Enum.StatusesOfInternalOrders.EmptyRef)
		|		ELSE ISNULL(StatusesOfInternalOrders.State, VALUE(Enum.StatusesOfInternalOrders.Closed))
		|	END AS State,
		|	ISNULL(StatusesOfInternalOrders.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice, FALSE) AS ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS DocumentByAssemblyDisassemblyOrder
		|		LEFT JOIN InformationRegister.StatusesOfInternalOrders AS StatusesOfInternalOrders
		|		ON (StatusesOfInternalOrders.OrderDocument = DocumentByAssemblyDisassemblyOrder.Ref)";
		
	Else
		
		ListProperties.QueryText =
		"SELECT
		|	DocumentByAssemblyDisassemblyOrder.Ref,
		|	DocumentByAssemblyDisassemblyOrder.DeletionMark,
		|	DocumentByAssemblyDisassemblyOrder.Number,
		|	DocumentByAssemblyDisassemblyOrder.Date,
		|	DocumentByAssemblyDisassemblyOrder.Priority,
		|	DocumentByAssemblyDisassemblyOrder.Posted,
		|	DocumentByAssemblyDisassemblyOrder.Organization,
		|	DocumentByAssemblyDisassemblyOrder.Warehouse,
		|	DocumentByAssemblyDisassemblyOrder.DocumentBasis,
		|	DocumentByAssemblyDisassemblyOrder.EmployeeResponsible,
		|	DocumentByAssemblyDisassemblyOrder.Status,
		|	DocumentByAssemblyDisassemblyOrder.Products,
		|	DocumentByAssemblyDisassemblyOrder.Characteristic,
		|	DocumentByAssemblyDisassemblyOrder.Package,
		|	DocumentByAssemblyDisassemblyOrder.NumberOfPackages,
		|	DocumentByAssemblyDisassemblyOrder.Count,
		|	DocumentByAssemblyDisassemblyOrder.BusinessOperation,
		|	DocumentByAssemblyDisassemblyOrder.Comment,
		|	DocumentByAssemblyDisassemblyOrder.AssemblyDisassemblyStart,
		|	DocumentByAssemblyDisassemblyOrder.AssemblyDisassemblyEnd,
		|	DocumentByAssemblyDisassemblyOrder.RequestedDeliveryDate,
		|	DocumentByAssemblyDisassemblyOrder.AssemblyDisassemblyDurationDays,
		|	DocumentByAssemblyDisassemblyOrder.MaximumRowCode,
		|	DocumentByAssemblyDisassemblyOrder.ProductKit,
		|	DocumentByAssemblyDisassemblyOrder.SalesOpportunity,
		|	DocumentByAssemblyDisassemblyOrder.Department,
		|	DocumentByAssemblyDisassemblyOrder.BatchesIndicationStatus,
		|	DocumentByAssemblyDisassemblyOrder.Purpose,
		|	DocumentByAssemblyDisassemblyOrder.AssignmentGoods,
		|	DocumentByAssemblyDisassemblyOrder.Series,
		|	DocumentByAssemblyDisassemblyOrder.SupplyOption,
		|	DocumentByAssemblyDisassemblyOrder.NumberOfPackagesCanceled,
		|	DocumentByAssemblyDisassemblyOrder.CountCanceled,
		|	DocumentByAssemblyDisassemblyOrder.Goods,
		|	DocumentByAssemblyDisassemblyOrder.SetOfSeries,
		|	DocumentByAssemblyDisassemblyOrder.Author,
		|	DocumentByAssemblyDisassemblyOrder.PointInTime
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS DocumentByAssemblyDisassemblyOrder";
		
	EndIf;
	
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	ThereIsChangeAccess = AccessRight("Update", Metadata.Documents.ByAssemblyDisassemblyOrder);
	AccessRightInsert = Documents.ByAssemblyDisassemblyOrder.AccessRightInsert();
	
	UseAssemblyDisassemblyPlanning = GetFunctionalOption("UseAssemblyDisassemblyPlanning");
	UseAdvancedDemandFulfillment = GetFunctionalOption("UseAdvancedDemandFulfillment");
	
	ThereIsCommandToCreateAccordingToNeeds = AccessRightInsert And UseAdvancedDemandFulfillment;
	ThereIsCommandToCreateBuildPlan = AccessRightInsert And UseAssemblyDisassemblyPlanning;
	ThereIsGroupOfCreationCommands = ThereIsCommandToCreateAccordingToNeeds Or ThereIsCommandToCreateBuildPlan;
	
	CommonClientServer.SetFormItemProperty(Items,
		"CreateListForm",
		"Visible",
		Not ThereIsGroupOfCreationCommands);
	CommonClientServer.SetFormItemProperty(Items,
		"FormCreate",
		"Visible",
		ThereIsGroupOfCreationCommands);
	CommonClientServer.SetFormItemProperty(Items,
		"FormGeneralTheTeamFormationOfOrdersForAssemblyAndDisassemblyAccordingToPlan",
		"Visible",
		ThereIsCommandToCreateBuildPlan);
	CommonClientServer.SetFormItemProperty(Items,
		"FormGeneralTheTeamFormationOfOrdersForAssemblyAndDisassemblyNeeds",
		"Visible",
		ThereIsCommandToCreateAccordingToNeeds);
	
	Items.SetTheStatusToExecute.Visible = ThereIsChangeAccess
		And GetFunctionalOption("UseStatusesOfAssemblyOrders");
	Items.SetTheClosedStatus.Visible = ThereIsChangeAccess
		And GetFunctionalOption("UseStatusesOfAssemblyOrders");
	
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
		"Document.ByAssemblyDisassemblyOrder.ListForm.Item.List.Selection");
	
EndProcedure

#EndRegion

#EndRegion
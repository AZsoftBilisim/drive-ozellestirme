
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetConditionalAppearance();
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetVisibilityWhenCreatingOnServer();
	
	FilterParameters = FormDataSettingsStorage.Load("OrderToProcessor2_5Workplace", "FilterParameters");
	If ValueIsFilled(FilterParameters) Then
		FillPropertyValues(ThisForm, FilterParameters);
	EndIf;
	
	// Let's work out the opening of the form from the "Current affairs" form
	If Parameters.Property("QuickFilterStructure") Then
		If Parameters.QuickFilterStructure.Property("Manager") Then
			FilterManager = Parameters.QuickFilterStructure.Manager;
		EndIf;
		If Parameters.QuickFilterStructure.Property("Priority") Then
			FilterPriority = Parameters.QuickFilterStructure.Priority;
		EndIf;
	EndIf; 
	
	QueryText = QueryTextTheListForRegistration();
	If QueryText <> "" Then
		
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.MainTable = "";
		ListProperties.DynamicDataRead = False;
		ListProperties.QueryText = QueryText;
		Common.SetDynamicListProperties(Items.TheListForRegistration, ListProperties);
		SetListParametersForLayout();
		
	EndIf;
	WhenSettingQueryText();
	
	SetCurrentPage();
	
	UseStatuses = GetFunctionalOption("UseTollingOrderStatuses2_5");
	
	#Region StandardProcedures
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	#EndRegion

	#Region StandardProcedures
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.ListCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	#EndRegion
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	Return; // empty handler
	
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
	
	If EventName = "ClosingOrders" Then
		Items.List.Refresh();
	EndIf;
	If EventName = "Write_SubcontractOrder2_5"
		Or EventName = "Write_ProductionStages"
		Then
		WhenRecordingOrders();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Manager",
		FilterManager,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterManager));
		
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure FilterPriorityOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Priority",
		FilterPriority,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterPriority));
		
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure FilterPeriodOnChange(Item)
	
	WhenChangingSelections();
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	WhenChangingSelections();
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ListOfOrders_OnChange(Item)
	
	WhenChangingSelections();
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure FilterTollerOnChange(Item)
	
	WhenChangingSelections();
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure HyperlinkSalesLogURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.OpenLog(LogParameters());
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnChange(Item)
	
	DocumentNames = New Array();
	DocumentNames.Add("Document.SubcontractOrder2_5");
	DocumentNames.Add("Document.ProductionStage2_2");
	ProvisionInDocumentsClient.ListOnChange(ThisObject, StrConcat(DocumentNames, ","));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTheListForRegistration

&AtClient
Procedure TheListForRegistrationSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.TheListForRegistration.CurrentData;
	If CurrentData <> Undefined Then
		ShowValue(,CurrentData.ReferenceOrder); 
	EndIf;
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShipByOrder(Command)
	
	ClearMessages();
	
	AllOrders = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	ResultOfActions = PerformActionInOrderList(AllOrders, UUID);
	
	If ProvisionInDocumentsClient.ResultOfPerformingActionsNeedQuestion(ResultOfActions) Then
		
		ActionCode = "ACTION_LOAD";
		ProcedureParameters = New Structure();
		ProcedureParameters.Insert("Orders", AllOrders);
		ProcedureParameters.Insert("ActionCode", ActionCode);
		ProcedureParameters.Insert("Form", ThisObject);
		ProcedureParameters.Insert("EmbeddingParameters", Undefined);
		CallbackDescription = New CallbackDescription("AfterQuestionInOrderList", ThisObject, ProcedureParameters);
		
		ProvisionInDocumentsClient.ShowQuestionUncheckShipByOneDateForListOfOrders(
			AllOrders,
			ActionCode,
			ResultOfActions,
			ThisObject,
			CallbackDescription);
			
	Else
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		AdditionalParameters = New Structure("Form,Orders",
			ThisObject, AllOrders);
		TimeConsumingOperationsClient.WaitCompletion(ResultOfActions,
			New CallbackDescription("AfterQuestionInOrderListCompletion", ProvisionInDocumentsClient, AdditionalParameters),
			IdleParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReserveAnOrder(Command)
	
	ProvisionInDocumentsClient.PerformActionInListOfOrdersOfDifferentTypes(
		"ACTION_RESERVE",
		Items.List,
		PredefinedValue("Document.SubcontractOrder2_5.EmptyRef"),
		ThisObject);
	
EndProcedure

&AtClient
Procedure ToSupplyOrder(Command)
	
	ProvisionInDocumentsClient.PerformActionInListOfOrdersOfDifferentTypes(
		"ACTION_COOPERATION",
		Items.List,
		PredefinedValue("Document.SubcontractOrder2_5.EmptyRef"),
		ThisObject);
	
EndProcedure

&AtClient
Procedure ReserveAsReceivedOrder(Command)
	
	ProvisionInDocumentsClient.PerformActionInListOfOrdersOfDifferentTypes(
		"ACTION_RESERVATION_REFERENCES",
		Items.List,
		PredefinedValue("Document.SubcontractOrder2_5.EmptyRef"),
		ThisObject);
	
EndProcedure

&AtClient
Procedure DoNotSupplyOrder(Command)
	
	ProvisionInDocumentsClient.PerformActionInListOfOrdersOfDifferentTypes(
		"ACTION_NOTABLE",
		Items.List,
		PredefinedValue("Document.SubcontractOrder2_5.EmptyRef"),
		ThisObject);
	
EndProcedure

&AtClient
Procedure TransferedEarlier(Command)
	
	ProvisionInDocumentsClient.PerformActionInListOfOrdersOfDifferentTypes(
		"ACTION_TRANSMITTED",
		Items.List,
		PredefinedValue("Document.SubcontractOrder2_5.EmptyRef"),
		ThisObject);
	
EndProcedure


&AtClient
Procedure SetTheStatusNotAgreed_5(Command)
	
	SetOrderStatus("NotApproved", NStr("vi = 'Không thống nhất';
										|ru = 'Не согласован';
										|en = 'Not approved'; fa = 'تأییدنشده';
										|it = 'Non concordato';
										|pl = 'Nieuzgodniony';
										|tr = 'Onaylanmadı'"));
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure SetTheStatusForExecution(Command)
	
	SetOrderStatus("ForFulfillment", NStr("vi = 'Chờ thực hiện';
											|ru = 'К исполнению';
											|en = 'Accept'; fa = 'پذیرش';
											|it = 'Da eseguire';
											|pl = 'Do wykonania';
											|tr = 'Yürütülecek'"));
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure SetTheClosedStatus(Command)
	
	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If HighlightedLinks.Count() = 0 Then
		Return;
	EndIf;
	
	OrderList = New ValueList;
	OrderList.LoadValues(HighlightedLinks);
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       OrderList);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm", ClosureStructure,
					ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure CreateTollingOrder(Command)
	RowsIDs = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.TheListForRegistration);
	If RowsIDs.Count() = 0 Then
		Return;
	EndIf; 
	
	StringsList = New Array;
	For Each RowID In RowsIDs Do
		RowData = Items.TheListForRegistration.RowData(RowID);
		StringsList.Add(RowData);
	EndDo;
	
	FillingData = ProcessingByThirdPartiesClient.DataForGeneratingOrdersToProcessors2_5(StringsList);
	
	If FillingData <> Undefined Then
		FormParameters = New Structure("Basis", FillingData);
		OpenForm("Document.SubcontractOrder2_5.ObjectForm", FormParameters, ThisForm);
	EndIf; 
	
	Return; // empty handler
	
EndProcedure

#Region AttachableCommands

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
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
Procedure Attachable_CheckWhetherInventoryAllocationTaskIsCompletedForOrders()
	ProvisionInDocumentsClient.CheckWhetherInventoryAllocationTaskIsCompletedForOrders(ThisObject, Items.List);
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region VisibleEnabled

&AtServer
Procedure SetVisibilityWhenCreatingOnServer()
	
	ThereIsChangeAccess = AccessRight("Update", Metadata.Documents.SubcontractOrder2_5);
	AccessRightInsert = AccessRight("Insert", Metadata.Documents.SubcontractOrder2_5);
	UseAdvancedDemandFulfillment = GetFunctionalOption("UseAdvancedDemandFulfillment");
	
	FormElementsAreInvisible = New Array;
	ElementsOfRightsForm  = New Array;
	ElementsOfRightsForm.Add("ListCopy");
	ElementsOfRightsForm.Add("ListContextMenuCopy");
	ElementsOfRightsForm.Add("PageOfTheOrderForRegistration");
	
	If UseAdvancedDemandFulfillment Then
		
		ElementsOfRightsForm.Add("TheGroupListToCreateANew");
		ElementsOfRightsForm.Add("GenerationOfTollingOrdersByDemands");
		
		FormElementsAreInvisible.Add("ListCreate");
		FormElementsAreInvisible.Add("ListContextMenuCreate");
		
	Else
		
		ElementsOfRightsForm.Add("ListCreate");
		ElementsOfRightsForm.Add("ListContextMenuCreate");
		
		FormElementsAreInvisible.Add("TheGroupListToCreateANew");
		FormElementsAreInvisible.Add("GenerationOfTollingOrdersByDemands");
		
	EndIf;
	
	For Each CurItem In FormElementsAreInvisible Do
		CommonClientServer.SetFormItemProperty(Items, CurItem, "Visible", False);
	EndDo;
	
	For Each CurItem In ElementsOfRightsForm Do
		CommonClientServer.SetFormItemProperty(
			Items,
			CurItem,
			"Visible",
			AccessRightInsert);
	EndDo;
	
	Items.Pages.PagesRepresentation =
		?(GetFunctionalOption("UseProduction")
			And AccessRightInsert,
		FormPagesRepresentation.TabsOnTop,
		FormPagesRepresentation.None);
	
	Items.ListShipByOrder.Visible = ThereIsChangeAccess;
	Items.ListReserveAnOrder.Visible = ThereIsChangeAccess;
	Items.ListToSupplyOrder.Visible = ThereIsChangeAccess;
	Items.ListReserveAsReceivedOrder.Visible = ThereIsChangeAccess;
	Items.ListDoNotSupplyOrder.Visible = ThereIsChangeAccess;
	Items.ListTransferedEarlier.Visible = ThereIsChangeAccess;
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.SubcontractOrder2_5.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Ref = ReferencesArrray[0];
		Items.List.CurrentRow = Ref;
		ShowValue(,ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
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

&AtServerNoContext
Function PerformActionInOrderList(AllOrders, UUID)
	
	EmbeddingParameters = Documents.SubcontractOrder2_5.AvailableRemainingEmbeddingOptions();
	NeedQuestion = ProvisionInDocumentsServer.NeedQuestionAboutShippingByOneDate(EmbeddingParameters, AllOrders);
	
	FillParameters = Undefined;
	
	Result = New Structure();
	Result.Insert("NeedQuestion", NeedQuestion);
	DateWhenTheNewLinesWereShipped = BegOfDay(CurrentSessionDate());
	Result.Insert("DateWhenTheNewLinesWereShipped", DateWhenTheNewLinesWereShipped);
	
	If Not Result.NeedQuestion Then
		
		ProcedureParameters = New Structure();
		ProcedureParameters.Insert("FillParameters", FillParameters);
		ProcedureParameters.Insert("Orders", AllOrders);
		ProcedureParameters.Insert("ActionCode", "ACTION_LOAD");
		ProcedureParameters.Insert("EmbeddingParameters", Undefined);
		Result = PerformActionForOrdersAfterQuestionByBackgroundTask(ProcedureParameters, UUID);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function PerformActionForOrdersAfterQuestionByBackgroundTask(ProcedureParameters, UUID)
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Thực hiện thao tác đảm bảo trong danh sách đơn hàng';
														|ru = 'Выполнение действия обеспечения в списке заказов';
														|en = 'Executing a provisioning action on the order list'; fa = 'Executing a provisioning action on the order list';
														|it = 'Esecuzione dell''azione di approvvigionamento nell''elenco degli ordini';
														|pl = 'Wykonanie czynności zaopatrzenia na liście zamówień';
														|tr = 'Bir sipariş listesinde tedarik işlemi gerçekleştirme'");
	
	Return TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters,
		"Documents.SubcontractOrder2_5.PerformActionForOrdersAfterQuestion",
		ProcedureParameters);
	
EndFunction

&AtClient
Procedure AfterQuestionInOrderList(Response, ParametersForCopying) Export
	
	ProcedureParameters = CommonClient.CopyRecursive(ParametersForCopying);
	Form = ParametersForCopying.Form;
	ProcedureParameters.Delete("Form");
	
	FillParameters = New Structure();
	FillParameters.Insert("UncheckShipByOneDateFlag", Response = "DialogReturnCode_Yes");
	FillParameters.Insert("FillShippingDateWithSingleDate", Response = "DialogReturnCode_No");
	ProcedureParameters.Insert("FillParameters", FillParameters);
	ResultOfActions = PerformActionForOrdersAfterQuestionByBackgroundTask(
		ProcedureParameters, UUID);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	AdditionalParameters = New Structure("Form,Orders",
		Form, ProcedureParameters.Orders);
	TimeConsumingOperationsClient.WaitCompletion(ResultOfActions,
		New CallbackDescription("AfterQuestionInOrderListCompletion", ProvisionInDocumentsClient, AdditionalParameters),
		IdleParameters);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	Documents.SubcontractOrder2_5.SetConditionalListAppearance(List);
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisForm, 
		"TheListForRegistrationCharacteristic",
		"TheListForRegistration.ItemVariantsAreUsed");
																			 
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(
		ThisObject, "List.Date", Items.ListDate.Name);
		
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(
		ThisObject, "TheListForRegistration.ReferenceDate", Items.TheListForRegistrationReferenceDate.Name);
	
	// The processor is not specified
	#Region ListForRegistration_Partner
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheListForRegistrationPartner.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TheListForRegistration.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra>';
													|ru = '<не указан>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non specificato>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	#EndRegion
	
	// The start date is overdue
	#Region ListForRegistration_Start
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheListForRegistrationBegin.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TheListForRegistration.LaunchDateIsOverdue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetCurrentPage()
	
	CurrentPageName = "";
	
	If Parameters.Property("CurrentPageName", CurrentPageName) Then
		If ValueIsFilled(CurrentPageName) Then
			CurrentItem = Items[CurrentPageName];
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingSelections()
	
	WhenSettingQueryText();
	SetListParametersForLayout();
	
EndProcedure

&AtServer
Procedure WhenRecordingOrders()
	
	SetListSelectionsForLayout();
	SetListParametersForLayout();
	Items.TheListForRegistration.Refresh();
	
EndProcedure

&AtServer
Procedure WhenSettingQueryText()
	
	SaveSelectionParameters();
	SetListSelections();
	SetListSelectionsForLayout();
	
EndProcedure

&AtServer
Function ThereIsSelectionByOrder()
	
	ThereIsSelectionByOrder = False;
	
	For Each CollectionItem In ListOfOrders_ Do
		
		If ValueIsFilled(CollectionItem.Value) Then
			ThereIsSelectionByOrder = True;
			Break;
		EndIf;
		
	EndDo;
	
	Return ThereIsSelectionByOrder;
	
EndFunction

&AtServer
Function QueryTextTheListForRegistration()
	
	QueryText = "";
	
	If GetFunctionalOption("UseProductionManagement2_2") Then
		
		QueriesTexts = New Array();
		QueryText = 
			"SELECT
			|	ProcessingOnScheduleOverridable.Organization AS Organization,
			|	ProcessingOnScheduleOverridable.Ref AS ReferenceOrder,
			|	ProcessingOnScheduleOverridable.ReferenceOrder AS ProductionOrder,
			|	VALUETYPE(ProcessingOnScheduleOverridable.Ref) AS TypeOfOrder_,
			|	ProcessingOnScheduleOverridable.Number AS TheNumberOfTheOrder,
			|	ProcessingOnScheduleOverridable.Date AS ReferenceDate,
			|	ProcessingOnScheduleOverridable.Department AS Department,
			|	ProcessingOnScheduleOverridable.Stage.Partner AS Partner,
			|	ProcessingOnScheduleOverridable.ProductionIssueForActivity AS PurchaseForActivity,
			|	CASE
			|		WHEN &TheProductionScheduleIsPlanned
			|				AND NOT ProductionSchedule.Stage IS NULL 
			|			THEN ProductionSchedule.Begin
			|		WHEN TargetOrderStructureSchedule.Begin IS NOT NULL
			|			THEN TargetOrderStructureSchedule.Begin
			|		ELSE DATEADD(ProcessingOnScheduleOverridable.ReferenceOrder.EarliestStartDate, SECOND, ISNULL(StandardProductionSchedule.DurationBeforeStart, 0))
			|	END AS Begin,
			|	CASE
			|		WHEN &TheProductionScheduleIsPlanned
			|				AND NOT ProductionSchedule.Stage IS NULL 
			|			THEN ProductionSchedule.Begin < &CurrentDate
			|		WHEN TargetOrderStructureSchedule.Begin IS NOT NULL
			|			THEN TargetOrderStructureSchedule.Begin < &CurrentDate
			|		ELSE DATEADD(ProcessingOnScheduleOverridable.ReferenceOrder.EarliestStartDate, SECOND, ISNULL(StandardProductionSchedule.DurationBeforeStart, 0)) < &CurrentDate
			|	END LaunchDateIsOverdue,
			|	ProcessingOnScheduleOverridable.LineOfBusiness AS LineOfBusiness,
			|	ProcessingOnScheduleOverridable.GoodsReceiptOption AS GoodsReceiptOption,
			|	ProcessingOnScheduleOverridable.DynamicStructure AS DynamicStructure
			|INTO TT_Orders
			|FROM
			|	Document.ProductionStage2_2 AS ProcessingOnScheduleOverridable
			|
			|		LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS ProductionSchedule
			|		ON &TheProductionScheduleIsPlanned
			|			AND ProductionSchedule.ProductionOrder = ProcessingOnScheduleOverridable.ReferenceOrder
			|			AND ProductionSchedule.Stage = ProcessingOnScheduleOverridable.Ref
			|			AND ProductionSchedule.ScheduleStatus = &StatusWorkingSchedule
			|
			|		LEFT JOIN InformationRegister.StandardScheduleOfProductionStages AS StandardProductionSchedule
			|		ON ProcessingOnScheduleOverridable.Ref = StandardProductionSchedule.ProductionStage
			|
			|		LEFT JOIN InformationRegister.TargetOrderStructureSchedule AS TargetOrderStructureSchedule
			|		ON NOT &TheProductionScheduleIsPlanned
			|			AND ProcessingOnScheduleOverridable.Ref = TargetOrderStructureSchedule.Stage
			|WHERE
			|	ProcessingOnScheduleOverridable.Posted
			|	AND ProcessingOnScheduleOverridable.ProductionByThirdParty
			|	AND NOT ProcessingOnScheduleOverridable.Status IN (
			|		VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated),
			|		VALUE(Enum.StatusesOfProductionStages2_2.Generated1))
			|	AND ProcessingOnScheduleOverridable.SubcontractOrder = UNDEFINED
			|	AND (&StartDate = DATETIME(1, 1, 1)
			|			OR CASE
			|					WHEN &TheProductionScheduleIsPlanned
			|							AND NOT ProductionSchedule.Stage IS NULL 
			|						THEN ProductionSchedule.Begin
			|					ELSE DATEADD(ProcessingOnScheduleOverridable.ReferenceOrder.EarliestStartDate, SECOND, ISNULL(StandardProductionSchedule.DurationBeforeStart, 0))
			|				END >= &StartDate)
			|	AND (&EndDate = DATETIME(1, 1, 1)
			|			OR CASE
			|					WHEN &TheProductionScheduleIsPlanned
			|							AND NOT ProductionSchedule.Stage IS NULL 
			|						THEN ProductionSchedule.Begin
			|					ELSE DATEADD(ProcessingOnScheduleOverridable.ReferenceOrder.EarliestStartDate, SECOND, ISNULL(StandardProductionSchedule.DurationBeforeStart, 0))
			|				END <= &EndDate)
			|";
		QueriesTexts.Add(QueryText);
		
		NameOfRegisterInformationAboutItemInProduction = "AccumulationRegister.InventoryAndDemands";
		QueryText = 
			"SELECT
			|	ProductsInProduction.Recorder AS Stage,
			|	MIN(ProductsInProduction.LineNumber) AS LineNumber
			|INTO TTProductsInProductionLineNumbers
			|FROM
			|	AccumulationRegister.InventoryAndDemands AS ProductsInProduction
			|WHERE
			|	ProductsInProduction.Recorder IN
			|			(SELECT
			|				TT_Orders.ReferenceOrder AS Recorder
			|			FROM
			|				TT_Orders)
			|	AND ProductsInProduction.Active 
			|		AND (ProductsInProduction.Received_1 > 0 OR ProductsInProduction.Ordered > 0)
			|
			|GROUP BY
			|	ProductsInProduction.Recorder
			|"; 
		QueriesTexts.Add(QueryText);
		
		QueryText = 
			"SELECT
			|	TT_Orders.Organization AS Organization,
			|	TT_Orders.ReferenceOrder AS ReferenceOrder,
			|	TT_Orders.ProductionOrder AS ProductionOrder,
			|	TT_Orders.TypeOfOrder_ AS TypeOfOrder_,
			|	TT_Orders.TheNumberOfTheOrder AS TheNumberOfTheOrder,
			|	TT_Orders.ReferenceDate AS ReferenceDate,
			|	TT_Orders.Department AS Department,
			|	TT_Orders.Partner AS Partner,
			|	TT_Orders.PurchaseForActivity AS PurchaseForActivity,
			|	ProductsInProduction.Products AS Products,
			|	ProductsInProduction.Characteristic AS Characteristic,
			|	ProductsInProduction.Warehouse AS Warehouse,
			|	TT_Orders.Begin AS Begin,
			|	CASE
			|		WHEN ProductsInProduction.Products.UseVariants IN
			|			(
			|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
			|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
			|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
			|			)
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS ItemVariantsAreUsed,
			|	TT_Orders.LaunchDateIsOverdue AS LaunchDateIsOverdue,
			|	TT_Orders.LineOfBusiness AS LineOfBusiness,
			|	TT_Orders.GoodsReceiptOption AS GoodsReceiptOption,
			|	TT_Orders.DynamicStructure AS DynamicStructure
			|FROM
			|	TT_Orders AS TT_Orders
			|
			|		LEFT JOIN TTProductsInProductionLineNumbers AS TTProductsInProductionLineNumbers
			|		ON TT_Orders.ReferenceOrder = TTProductsInProductionLineNumbers.Stage
			|
			|		LEFT JOIN NameOfRegisterInformationAboutItemInProduction AS ProductsInProduction
			|		ON TTProductsInProductionLineNumbers.Stage = ProductsInProduction.Recorder
			|			AND TTProductsInProductionLineNumbers.LineNumber = ProductsInProduction.LineNumber
			|";
		QueryText = StrReplace(QueryText, "NameOfRegisterInformationAboutItemInProduction", NameOfRegisterInformationAboutItemInProduction);
		QueriesTexts.Add(QueryText);
		
		QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtServer
Procedure SetListSelections()
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Department",  FilterDepartment, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterDepartment));
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Priority", FilterPriority, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterPriority));
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Manager", FilterManager, DataCompositionComparisonType.Equal,, ValueIsFilled(FilterManager));
		
EndProcedure

&AtServer
Procedure SetListSelectionsForLayout()
	
	CommonClientServer.SetDynamicListFilterItem(
		TheListForRegistration,
		"Partner",
		FilterToller,,, 
		ValueIsFilled(FilterToller));
		
	CommonClientServer.SetDynamicListFilterItem(
		TheListForRegistration,
		"Department",
		FilterDepartment,,,
		ValueIsFilled(FilterDepartment));
		
EndProcedure

&AtServer
Procedure SetListParametersForLayout()
	
	CommonClientServer.SetDynamicListParameter(
		TheListForRegistration,
		"ListOfOrders_",
		ListOfOrders_.UnloadValues());
		
	CommonClientServer.SetDynamicListParameter(
		TheListForRegistration,
		"CurrentDate",
		CurrentSessionDate());
		
	CommonClientServer.SetDynamicListParameter(
		TheListForRegistration,
		"StartDate",
		FilterPeriod.StartDate);
		
	CommonClientServer.SetDynamicListParameter(
		TheListForRegistration,
		"EndDate",
		FilterPeriod.EndDate);
		
	CommonClientServer.SetDynamicListParameter(
		TheListForRegistration,
		"FilterByReference",
		ThereIsSelectionByOrder());
		
	CommonClientServer.SetDynamicListParameter(
		TheListForRegistration,
		"StatusWorkingSchedule",
		InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
		
	CommonClientServer.SetDynamicListParameter(
		TheListForRegistration,
		"TheProductionScheduleIsPlanned",
		ProductionManagementCached.TheProductionScheduleIsUsed());
	
EndProcedure

&AtClient
Procedure SetOrderStatus(NewStatus, StatusName)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các giấy ủy quyền đã chọn từ danh sách sẽ đặt trạng thái ""%StatusName%"". Tiếp tục?';
					|ru = 'У выделенных в списке заказов будет установлен статус ""%StatusName%"". Продолжить?';
					|en = 'Status ""%StatusName%"" will be set for the orders selected in the list. Continue?'; fa = 'Status ""%StatusName%"" will be set for the orders selected in the list. Continue?';
					|it = 'Per gli ordini selezionati nell''elenco sarà impostato lo stato ""%StatusName%"". Continuare?';
					|pl = 'Dla wybranych w liście zamówień będzie ustawiony status %StatusName%. Kontynuować?';
					|tr = 'Listede belirtilen siparişler için ""%StatusName%"" durumu ayarlanacaktır. Devam edilsin mi?'");
	QueryText = StrReplace(QueryText, "%StatusName%", StatusName);
	AddlParameters = New Structure("SelectedRows, StatusName, NewStatus", SelectedRows, StatusName, NewStatus);
	CallbackDescription = New CallbackDescription("SetOrderStatusCompletion", ThisObject, AddlParameters);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetOrderStatusCompletion(QuestionResult, AdditionalParameters) Export
	
    SelectedRows = AdditionalParameters.SelectedRows;
    StatusName = AdditionalParameters.StatusName;
    NewStatus = AdditionalParameters.NewStatus;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, NewStatus);
    
    TMCommonUseClient.NotifyUserAboutSettingStatus(
		    Items.List,
		    ProcessedItemsCount,
		    SelectedRows.Count(),
		    StatusName);
	
EndProcedure

&AtServer
Procedure SaveSelectionParameters()

	FilterParameters = New Structure("FilterToller,FilterManager,FilterPeriod,FilterDepartment,FilterPriority");

	FillPropertyValues(FilterParameters, ThisForm);
	FormDataSettingsStorage.Save("OrderToProcessor2_5Workplace", "FilterParameters", FilterParameters);

EndProcedure

&AtClient
Function LogParameters()
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Department",	FilterDepartment);
	QuickFilterStructure.Insert("Manager",		FilterManager);
	
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure",	QuickFilterStructure);
	LogParameters.Insert("WorkplaceName",			"DocumentsOfTransferToTollingAll2_5");
	LogParameters.Insert("FormAssignmentKey",		"SubcontractingServicesReceivedAllDocuments");
	LogParameters.Insert("JournalSynonym",				NStr("vi = 'Chứng từ chuyển vào gia công';
																|ru = 'Документы передачи в переработку';
																|en = 'External subcontracting — All documents'; fa = 'پیمانکاری فرعی خارجی — همه اسناد';
																|it = 'Documenti di consegna in trasformazione';
																|pl = 'Dokumenty przekazania do przetwórstwa';
																|tr = 'Fason üretim belgeleri'"));
	
	Return LogParameters;
	
EndFunction

#EndRegion

#EndRegion

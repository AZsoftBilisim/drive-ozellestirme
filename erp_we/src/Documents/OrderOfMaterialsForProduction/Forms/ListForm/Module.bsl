
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		
		Return;
		
	EndIf;
	
	FiltersStructure = Undefined;
	If Parameters.Property("FiltersStructure", FiltersStructure) Then
		QuickFilterStructure = New Structure;
		
		If FiltersStructure.Property("Department", FilterDepartment) Then
			QuickFilterStructure.Insert("Department", FilterDepartment);
		EndIf;
	Else
		Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Department", FilterDepartment, QuickFilterStructure);
	
	ThereIsChangeAccess = AccessRight("Update", Metadata.Documents.OrderOfMaterialsForProduction);
	UseProductionPlanning = GetFunctionalOption("UseProductionPlanning");
	EnabledOnlyProductionManagement21And22 = GetFunctionalOption("EnabledOnlyProductionManagement21And22");
	AccessRightInsert = Documents.OrderOfMaterialsForProduction.AccessRightInsert();
	FormationOfOrdersOfMaterialsOnNeedsIsAvailable = 
		GetFunctionalOption("UseAdvancedDemandFulfillment")
		And GetFunctionalOption("UseProductionManagement2_2");
	
	Items.ListShipByOrder.Visible = ThereIsChangeAccess;
	Items.ListReserveAnOrder.Visible = ThereIsChangeAccess;
	Items.ListToSupplyOrder.Visible = ThereIsChangeAccess;
	Items.ListReserveAsReceivedOrder.Visible = ThereIsChangeAccess;
	Items.ListDoNotSupplyOrder.Visible = ThereIsChangeAccess;
	
	CreateSubmenuVisibility = AccessRightInsert 
		And (EnabledOnlyProductionManagement21And22
			Or UseProductionPlanning
			Or FormationOfOrdersOfMaterialsOnNeedsIsAvailable);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"GroupListCreate",
		"Visible",
		CreateSubmenuVisibility);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"CreateCommand",
		"Visible",
		Not CreateSubmenuVisibility And AccessRightInsert);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"ListCopy",
		"Visible",
		AccessRightInsert);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"CreateOrder",
		"Visible",
		Not EnabledOnlyProductionManagement21And22);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"CreateOrderToDepartment",
		"Visible",
		EnabledOnlyProductionManagement21And22);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"CreateAnOrderInThePantry",
		"Visible",
		EnabledOnlyProductionManagement21And22);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"ListGeneralTeamCreatingOrdersForMaterialsBasedOnNeeds", 
		"Visible",
		FormationOfOrdersOfMaterialsOnNeedsIsAvailable);
	
	Items.GroupSetStatus.Visible = AccessRight("Update", Metadata.Documents.OrderOfMaterialsForProduction);
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

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If QuickFilterStructure = Undefined Then
		SetSelectionByDivision(ThisForm);
	EndIf;
	SetSelectionByResponsible(ThisForm);
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	If QuickFilterStructure <> Undefined Then
		Settings.Delete("FilterDepartment");
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	SetSelectionByDivision(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterEmployeeResponsibleOnChange(Item)
	
	SetSelectionByResponsible(ThisForm);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnChange(Item)
	
	ProvisionInDocumentsClient.ListOnChange(ThisObject, "Document.OrderOfMaterialsForProduction");
	
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
Procedure CreateOrderToDepartment(Command)
	
	HeaderAttributes = New Structure;
	HeaderAttributes.Insert("ProductionManagement2_2", False);
	HeaderAttributes.Insert("Department", FilterDepartment);
	
	BasisParameters = New Structure;
	BasisParameters.Insert("HeaderAttributes", HeaderAttributes);
	
	OpenForm("Document.OrderOfMaterialsForProduction.ObjectForm", New Structure("Basis", BasisParameters));
	
EndProcedure

&AtClient
Procedure CreateAnOrderInThePantry(Command)
	
	HeaderAttributes = New Structure;
	HeaderAttributes.Insert("ProductionManagement2_2", True);
	HeaderAttributes.Insert("Department", FilterDepartment);
	
	BasisParameters = New Structure;
	BasisParameters.Insert("HeaderAttributes", HeaderAttributes);
	
	OpenForm("Document.OrderOfMaterialsForProduction.ObjectForm", New Structure("Basis", BasisParameters));
	
EndProcedure

&AtClient
Procedure SetTheStatusToExecute(Command)
	
	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	
	If HighlightedLinks.Count() = 0 Then
		
		Return;
		
	EndIf;
	
	QueryText = NStr("vi = 'Trong các đơn hàng đã chọn trong danh sách sẽ đặt trạng thái ""Cần thực hiện"". Tiếp tục?';
					|ru = 'У выделенных в списке заказов будет установлен статус ""К выполнению"". Продолжить?';
					|en = 'The ""Released"" status will be set for the selected orders. Continue?'; fa = 'The ""Released"" status will be set for the selected orders. Continue?';
					|it = 'Agli ordini selezionati nell''elenco verrà assegnato lo stato ""Da eseguire"". Continuare?';
					|pl = 'U wybranych w liście zamówień ustawiono status ""К выполнению"". Kontynuować?';
					|tr = 'Listede belirtilen siparişler için ""Gerçekleştirmeye hazır"" durumu ayarlanacaktır. Devam edilsin mi?'");
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
																													|en = 'Released'; fa = 'آزادشده';
																													|it = 'Da eseguire';
																													|pl = 'Do wykonania';
																													|tr = 'Gerçekleştirmeye hazır'"));

EndProcedure

&AtClient
Procedure SetTheClosedStatus(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"Document.OrderOfMaterialsForProduction.ListForm.Command.SetTheClosedStatus");
	
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
	
EndProcedure

#Region Other

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

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	#Region ShopPantry_Text
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShopFloorStockroom.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ProductionManagement2_2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	#EndRegion
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByDivision(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"Department",
		Form.FilterDepartment,,,
		ValueIsFilled(Form.FilterDepartment));

EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByResponsible(Form)

	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"EmployeeResponsible",
		Form.FilterEmployeeResponsible,,,
		ValueIsFilled(Form.FilterEmployeeResponsible));

EndProcedure

&AtClient
Procedure Attachable_CheckWhetherInventoryAllocationTaskIsCompletedForOrders()
	ProvisionInDocumentsClient.CheckWhetherInventoryAllocationTaskIsCompletedForOrders(ThisObject, Items.List);
EndProcedure

#EndRegion

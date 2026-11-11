
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	#Region Filters
	
	FiltersStructure = Undefined;
	
	If Parameters.Property("FiltersStructure", FiltersStructure) Then
		
		QuickFilterStructure = New Structure;
		
		If FiltersStructure.Property("Status", Status) Then
			QuickFilterStructure.Insert("Status", Status);
		EndIf;
		
		If FiltersStructure.Property("Priority", Priority) Then
			QuickFilterStructure.Insert("Priority", Priority);
		EndIf;
		
		If FiltersStructure.Property("Department", Department) Then
			QuickFilterStructure.Insert("Department", Department);
		EndIf;
		
		If FiltersStructure.Property("EmployeeResponsible", EmployeeResponsible) Then
			QuickFilterStructure.Insert("EmployeeResponsible", EmployeeResponsible);
		EndIf;
		
	Else
		
		Parameters.Property("QuickFilterStructure", QuickFilterStructure);
		
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Status", Status, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Priority", Priority, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Department", Department, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "EmployeeResponsible", EmployeeResponsible, QuickFilterStructure);
	
	#EndRegion
	
	#Region UniversalMechanisms
	
	ToDoListOverridable.OnCreateAtServer(ThisForm, List);
	
	// Peripherals
	TMCommonUse.CustomizePeripherals(ThisForm);
	// End Peripherals
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.CommandBarGlobalCommands);
	// End IntegrationWith1CDocumentManagementSubsystem


	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	#EndRegion
	
	CustomizeFormElements();
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Peripherals
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	// End Peripherals
	
	
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
	
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If QuickFilterStructure <> Undefined Then
		Settings.Delete("Department");
		Settings.Delete("EmployeeResponsible");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Department", Department, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "EmployeeResponsible", EmployeeResponsible, QuickFilterStructure, Settings);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StatusFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Status", Status, DataCompositionComparisonType.Equal,, ValueIsFilled(Status));
	
EndProcedure

&AtClient
Procedure PrioritySelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Priority", Priority, DataCompositionComparisonType.Equal,, ValueIsFilled(Priority));
	
EndProcedure

&AtClient
Procedure DepartmentFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Department", Department, DataCompositionComparisonType.Equal,, ValueIsFilled(Department));
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "EmployeeResponsible", EmployeeResponsible, DataCompositionComparisonType.Equal,, ValueIsFilled(EmployeeResponsible));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListOnChange(Item)
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.StatusPresentation Then
	EndIf;
	
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
Procedure OpenOrderQueue(Command)
	
	FiltersStructure = New Structure;
	FiltersStructure.Insert("Priority",     Priority);
	FiltersStructure.Insert("Department", Department);
	FiltersStructure.Insert("EmployeeResponsible", EmployeeResponsible);
	
	ProductionManagementClient.OpenOrderQueue(FiltersStructure, Items.List.CurrentRow);
	
EndProcedure

&AtClient
Procedure SetTheStatusToProduction(Command)
	
	SelectedRows = SelectedOrders();
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Các đơn hàng được tô sáng trong danh sách sẽ được đặt thành trạng thái sản xuất. Tiếp tục?';
					|ru = 'У выделенных в списке заказов будет установлен статус ""К производству"". Продолжить?';
					|en = 'Status of the orders selected in the list will be set to For production. Continue?'; fa = 'Status of the orders selected in the list will be set to For production. Continue?';
					|it = 'Per gli ordini selezionati nell''elenco verrà impostato lo stato ""Da produrre"". Continuare?';
					|pl = 'Dla zamówień zaznaczonych na liście zostanie ustawiony status ""К производству"". Kontynuować?';
					|tr = 'Listede belirtilen siparişler için ""Üretilecek"" durumu ayarlanacaktır. Devam edilsin mi?'");
	
	AdditionalParameters = New Structure("SelectedRows", SelectedRows);
	
	CallbackDescription = New CallbackDescription(
		"SetTheStatusToProductionCompletion", 
		ThisObject, AdditionalParameters);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusToProductionCompletion(QuestionResult, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "ToProduce");
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Để sản xuất';
																												|ru = 'К производству';
																												|en = 'For production'; fa = 'برای تولید';
																												|it = 'Da produrre';
																												|pl = 'Do produkcji';
																												|tr = 'Üretilecek'"));
	
EndProcedure

&AtClient
Procedure SetTheClosedStatus(Command)
	
	SelectedRows = SelectedOrders();
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Các đơn hàng được tô sáng trong danh sách sẽ được đặt thành Đã đóng. Tiếp tục?';
					|ru = 'У выделенных в списке заказов будет установлен статус ""Закрыт"". Продолжить?';
					|en = 'Status of the orders selected in the list will be set to Closed. Continue?'; fa = 'Status of the orders selected in the list will be set to Closed. Continue?';
					|it = 'Per gli ordini selezionati nella lista sarà impostato lo stato ""Chiuso"". Continuare?';
					|pl = 'W wydzielonych w liście zamówieniach będzie ustawiony status ""Закрыт"". Kontynuować?';
					|tr = 'Listede belirtilen siparişler için ""Kapalı"" durumu ayarlanacaktır. Devam edilsin mi?'");
	
	AdditionalParameters = New Structure("SelectedRows", SelectedRows);
	
	CallbackDescription = New CallbackDescription(
		"SetTheClosedStatusCompletion", 
		ThisObject, AdditionalParameters);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheClosedStatusCompletion(QuestionResult, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "Closed", New Structure("OrderFulfillmentControl"));
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Đã đóng';
																												|ru = 'Закрыт';
																												|en = 'Closed'; fa = 'بسته‌شده';
																												|it = 'Chiuso';
																												|pl = 'Closed';
																												|tr = 'Kapalı'"));
	
EndProcedure

&AtClient
Procedure ListRefresh(Command)
	
	ListUpdateOnServer();
	
EndProcedure

&AtServer
Procedure ListUpdateOnServer()
	
	SetConditionalAppearanceOfPriorityField();
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List.SelectedRows);
	
EndProcedure

#Region Universal_

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

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result)
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region FormMaintenance

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	// Priority
	SetConditionalAppearanceOfPriorityField();
	
	// start of production
	ProductionManagement.SetConditionalAppearanceOfProductionDateField(ThisObject, "List", "ProductionStart");
	
	// The requirements date
	ProductionManagement.SetConditionalAppearanceOfProductionDateField(ThisObject, "List", "DemandDate");
	
	// Date
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);

	#Region TheClosedStatus
	
	Item = ConditionalAppearance.Items.Add();

	Item.Fields.Items.Add().Field = New DataCompositionField(Items.List.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("List.Status");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = OrderStatusClosed();
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfPriorityField()
	
	ProductionManagement.SetConditionalAppearanceOfPriorityField(ThisObject, "List", "Priority", "Priority", True, "Priority", "PrioritySelection");
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	AccessRightInsert = Documents.ProductionOrder2_2.AccessRightInsert();
	
	UseCreateSubmenu = GetFunctionalOption("UseAdvancedDemandFulfillment")
							  Or GetFunctionalOption("UseProductionPlanning");
	
	CommonClientServer.SetFormItemProperty(Items, "SubmenuListGroupCreate", "Visible", AccessRightInsert And UseCreateSubmenu);
	CommonClientServer.SetFormItemProperty(Items, "CreateNewList",         "Visible", AccessRightInsert And Not UseCreateSubmenu);
	CommonClientServer.SetFormItemProperty(Items, "ListCopy",          "Visible", AccessRightInsert);
	
	Items.GroupSetStatus.Visible = Documents.ProductionOrder2_2.AccessRightUpdate();
	Items.QueueOfOrders.Visible = Documents.ProductionOrder2_2.QueueManagementIsAvailable();
	
	MultipleDivisionsAreUsed = Catalogs.BusinessStructure.MultipleDispatcherUnitsAreUsed();
	
	Items.DepartmentFilter.Visible = MultipleDivisionsAreUsed;
	Items.Department.Visible      = MultipleDivisionsAreUsed;
	
	Items.ProductionProcessType.Visible = ProductDataManagement.DescriptionOfManufacturingProcessTypeIsAvailable();
	
	ChangeSelectedAvailable = ProductionServer.CommandChangeSelectedIsAvailable(Metadata.Documents.ProductionOrder2_2);
	Items.ListChangeSelectedItems.Visible                = ChangeSelectedAvailable;
	Items.ListContextMenuChangeSelectedItems.Visible = ChangeSelectedAvailable;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Function SelectedOrders()

	Return TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);

EndFunction

&AtClientAtServerNoContext
Function OrderStatusClosed()
	
	Return PredefinedValue("Enum.ProductionOrderStatuses2_2.Closed");
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ProductionOrder2_2.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

#EndRegion

#EndRegion

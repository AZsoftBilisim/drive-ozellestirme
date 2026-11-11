
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	SetVisibility1();
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Status", Status, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Department", Department, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "RMActivity", RMActivity, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "EmployeeResponsible", EmployeeResponsible, QuickFilterStructure);
	
	UseInventoryConsumptionForMultipleOrders = GetFunctionalOption("UseInventoryConsumptionForMultipleOrders");
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GroupOfStandardCommands);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);

	ObjectsVersioning.OnCreateAtServer(ThisObject);

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Status", Status, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Department", Department, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "RMActivity", RMActivity, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "EmployeeResponsible", EmployeeResponsible, QuickFilterStructure, Settings);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ClosingOrders"
		Or EventName = "Write_File" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StatusOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Status", Status, DataCompositionComparisonType.Equal,, ValueIsFilled(Status));
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Department", Department, DataCompositionComparisonType.Equal,, ValueIsFilled(Department));
	
EndProcedure

&AtClient
Procedure RMActivityOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "RMActivity", RMActivity, DataCompositionComparisonType.Equal,, ValueIsFilled(RMActivity));
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "EmployeeResponsible", EmployeeResponsible, DataCompositionComparisonType.Equal,, ValueIsFilled(EmployeeResponsible));
	
EndProcedure

&AtClient
Procedure FilterPriorityOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Priority", Priority, DataCompositionComparisonType.Equal,, ValueIsFilled(Priority));
	
EndProcedure

&AtClient
Procedure FilterPriorityClearing(Item, StandardProcessing)
	If Not ValueIsFilled(Priority) Then
		StandardProcessing = False;
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnChange(Item)
	
	ProvisionInDocumentsClient.ListOnChange(ThisObject, "Document.RMOrder");
	
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
Procedure SetTheStatusCreated(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các đơn hàng sửa chữa đã chọn trong danh sách sẽ đặt trạng thái ""Đã tạo"".
	|Theo các đơn hàng đã đưa vào xử lý có thể lập chứng từ. Tiếp tục?';
	|ru = 'У выделенных в списке заказов на ремонт будет установлен статус ""Создан"".
	|По принятым в работу заказам могут быть оформлены документы. Продолжить?';
	|en = 'The ""Created"" status will be set for R&M orders selected in the list.
	|Documents can be registered against the orders in progress. Continue?'; fa = 'The ""Created"" status will be set for R&M orders selected in the list.
	|Documents can be registered against the orders in progress. Continue?';
	|it = 'Per gli ordini di manutenzione selezionati nell''elenco verrà impostato lo stato ""Creato"".
	| Per gli ordini accettati per l''esecuzione possono essere formalizzati i documenti. Continuare?';
	|pl = 'Dla wybranych w liście zamówień na remont będzie ustawiony status ""Создан"".
	|Według przyjętych do pracy zamówień mogą być sporządzone dokumenty. Kontynuować?';
	|tr = 'Listede seçilen onarım emirleri ""Oluşturuldu"" durumuna sahip olacaktır. 
	| Kabul edilen emirler için belgeler düzenlenebilir. Devam edilsin mı?'");
	ShowQueryBox(New CallbackDescription("SetTheStatusCreatedCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusCreatedCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    If QuestionResult = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "Created");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), "Created");

EndProcedure

&AtClient
Procedure SetTheStatusToExecute(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Các lệnh sửa chữa được tô sáng trong danh sách sẽ có trạng thái ""Cần thực hiện"". Tiếp tục?';
					|ru = 'У выделенных в списке заказов на ремонт будет установлен статус ""К выполнению"". Продолжить?';
					|en = '""Queued"" status will be set for the selected R&M orders. Continue?'; fa = '""Queued"" status will be set for the selected R&M orders. Continue?';
					|it = 'Agli ordini di manutenzione selezionati nell''elenco verrà assegnato lo stato ""Da eseguire"". Continuare?';
					|pl = 'Dla wybranych w liście zamówień na remont ustawiono status ""К выполнению"". Kontynuować?';
					|tr = 'Listede vurgulanan onarım siparişlerinin durumu ""Vadesi Geldi"" olacaktır. Devam edilsin mi?'");
	ShowQueryBox(New CallbackDescription("SetTheStatusToExecuteCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusToExecuteCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    If QuestionResult = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "ForCompletion");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Cần thực hiện';
																												|ru = 'К выполнению';
																												|en = 'Queued'; fa = 'در صف';
																												|it = 'Da eseguire';
																												|pl = 'Do wykonania';
																												|tr = 'Gerçekleştirilecek'"));

EndProcedure

&AtClient
Procedure SetStatusInProgress(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Các đơn hàng sửa chữa được tô sáng trong danh sách sẽ có trạng thái ""Đang thực hiện"". Tiếp tục?';
					|ru = 'У выделенных в списке заказов на ремонт будет установлен статус ""Выполняется"". Продолжить?';
					|en = '""In progress"" status will be set for the selected R&M orders. Continue?'; fa = '""In progress"" status will be set for the selected R&M orders. Continue?';
					|it = 'Agli ordini di manutenzione selezionati nell''elenco verrà assegnato lo stato ""In esecuzione"". Continuare?';
					|pl = 'Dla wybranych w liście zamówień na remont ustawiono status ""Выполняется"". Kontynuować?';
					|tr = 'Listede vurgulanan onarım siparişlerinin durumu ""Devam ed"" olacaktır. Devam edilsin mi?'");
	ShowQueryBox(New CallbackDescription("SetStatusInProgressCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetStatusInProgressCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    If QuestionResult = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "Running");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), "Running");

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
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
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

#EndRegion

#Region Private

&AtServer
Procedure SetVisibility1()
	
	ThereIsChangeAccess = AccessRight("Update", Metadata.Documents.RMOrder);
	Items.ListShipByOrder.Visible = ThereIsChangeAccess;
	Items.ListReserveAnOrder.Visible = ThereIsChangeAccess;
	Items.ListToSupplyOrder.Visible = ThereIsChangeAccess;
	Items.ListReserveAsReceivedOrder.Visible = ThereIsChangeAccess;
	Items.ListDoNotSupplyOrder.Visible = ThereIsChangeAccess;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	// Conditional design of the dynamic list "List"
	ListOfConditionalAppearance = List.SettingsComposer.Settings.ConditionalAppearance;
	ListOfConditionalAppearance.Items.Clear();
	
	// The document has a high priority
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Chứng từ có mức ưu tiên cao';
							|ru = 'Документ имеет высокий приоритет';
							|en = 'High priority document'; fa = 'سند با اولویت بالا';
							|it = 'Il documento ha priorità alta';
							|pl = 'Dokument ma wysoki priorytet';
							|tr = 'Belge yüksek önceliğe sahiptir'");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.Priorities.GetTopPriority();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeletionMark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.HighPriorityDocument);
	
	// The document has a low priority
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Chứng từ có mức ưu tiên thấp';
							|ru = 'Документ имеет низкий приоритет';
							|en = 'Low priority document'; fa = 'Low priority document';
							|it = 'Il documento ha priorità bassa';
							|pl = 'Dokument ma niski priorytet';
							|tr = 'Belge düşük önceliğe sahiptir'");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.Priorities.GetLowerPriority();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeletionMark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.LowDocumentPriority);
	
EndProcedure

&AtClient
Procedure Attachable_CheckWhetherInventoryAllocationTaskIsCompletedForOrders()
	ProvisionInDocumentsClient.CheckWhetherInventoryAllocationTaskIsCompletedForOrders(ThisObject, Items.List);
EndProcedure

#EndRegion

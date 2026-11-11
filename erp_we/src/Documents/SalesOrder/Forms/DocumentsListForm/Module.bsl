
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If ValueIsFilled(Parameters.FormCaption) Then
		Title = Parameters.FormCaption;
	EndIf;

	UseReasonsForSalesOrderCancellations = GetFunctionalOption("UseReasonsForSalesOrderCancellations");
	UseSimplifiedPaymentScheme        = GetFunctionalOption("UseSimplifiedPaymentSchemeInSales");
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	List.Parameters.SetParameterValue("UpdateDate",               BegOfDay(CurrentSessionDate()));
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(Items.FilterDueDate_2.ChoiceList);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Manager", Manager, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Priority", Priority, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByRelevanceWhenCreatingOnServer(List, Relevance, Items.FilterDueDate_2.ChoiceList, EventDate, QuickFilterStructure);
	
	If ListSelectionsClientServer.YouNeedToSelectByStateWhenCreatingOnServer(State, QuickFilterStructure) Then
		SetSelectionByStateServer();
	EndIf;
	
	CommonClientServer.SupplementList(Items.FilterState.ChoiceList,
		Enums.SalesOrderStates.ListOfAvailableStatesOfOrders());
	
	UseSaleByMultipleOrders = GetFunctionalOption("UseSaleByMultipleOrders");
	UseCustomerInvoicesForSeveralOrders = GetFunctionalOption("UseCustomerInvoicesForSeveralOrders");
	UseShipmentByRowsInSalesOrder = GetFunctionalOption("UseShipmentByRowsInSalesOrder");
	UseWarehouseManagemantSystemForGoodsIssue = GetFunctionalOption("UseWarehouseManagemantSystemForGoodsIssue");
	
	SetItemsVisibility();
	If Not UseShipmentByRowsInSalesOrder Then
		Items.SetTheStatusToExecute.Title = NStr("vi = 'Trong dự phòng';
												|ru = 'В резерве';
												|en = 'In reserve'; fa = 'در رزرو';
												|it = 'In riserva';
												|pl = 'W rezerwie';
												|tr = 'Rezervde'");
	EndIf;
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	
	
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(New CallbackDescription("NotificationProcessingCompletion", ThisObject, New Structure("EventName", EventName)), EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
            Return;
		EndIf;
	EndIf;
	// End Peripherals
	


	HandlingFragmentAlerts(EventName);
	
	If EventName = "Write_SalesOrder"
		Or EventName = "ClosingOrders" Then
		// StandardSubsystems.AttachableCommands
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
		// End StandardSubsystems.AttachableCommands
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessingCompletion(Result, AdditionalParameters) Export
    
    EventName = AdditionalParameters.EventName;
    
    
    HandlingFragmentAlerts(EventName);

EndProcedure

&AtClient
Procedure HandlingFragmentAlerts(Val EventName)
    
	If EventName = "PaymentCredited" 
		Or SalesClient.ChangedPaymentDocumentsForCustomers(EventName) 
		Or EventName = "ClosingOrders" Then
        Items.List.Refresh();
    EndIf;    

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Manager", Manager, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Priority", Priority, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByRelevanceWhenLoadingFromSettings(List, Relevance, Items.FilterDueDate_2.ChoiceList, EventDate, QuickFilterStructure, Settings);

	If ListSelectionsClientServer.YouNeedToSelectByStateWhenLoadingFromSettings(State, QuickFilterStructure, Settings) Then
		SetSelectionByStateServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterStateOnChange(Item)
	
	SetSelectionByStateServer();
	
EndProcedure

&AtClient
Procedure FilterDueDate_2OnChange(Item)

	ListSelectionsClientServer.WhenChangingRelevanceSelection(List, Relevance, EventDate, Items.FilterDueDate_2.ChoiceList);
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));

EndProcedure

&AtClient
Procedure FilterPriorityOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Priority", Priority, DataCompositionComparisonType.Equal,, ValueIsFilled(Priority));

EndProcedure

&AtClient
Procedure FilterDueDate_2ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TMCommonUseClient.WhenSelectingRelevanceSelection(
		ValueSelected, 
		StandardProcessing, 
		ThisForm,
		List, 
		"Relevance",
		"FilterDueDate_2",
		"EventDate");
	
EndProcedure

&AtClient
Procedure FilterCompletionDateCleaningUp(Item, StandardProcessing)
	
	ListSelectionsClientServer.WhenClearingSelectionByRelevance(List, Relevance, EventDate, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManagerClearing(Item, StandardProcessing)
	If Not ValueIsFilled(Manager) Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure FilterPriorityClearing(Item, StandardProcessing)
	If Not ValueIsFilled(Priority) Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure FilterStateClearing(Item, StandardProcessing)
	If State = Undefined Then
		StandardProcessing = False;
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnChange(Item)
	
	ProvisionInDocumentsClient.ListOnChange(ThisObject, "Document.SalesOrder");
	
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
Procedure SetTheStatusForApproval(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Đối với các đơn hàng đã chọn trong danh sách sẽ thiết lập trạng thái ""Cần thống nhất"".
		|Có thể lập chứng từ theo các đơn hàng đã tiếp nhận để thực hiện. Tiếp tục?';
		|ru = 'У выделенных в списке заказов будет установлен статус ""На согласовании"".
		|По принятым к выполнению заказам могут быть оформлены документы. Продолжить?';
		|en = 'Status ""Pending approval"" will be set for the orders selected in the list.
		|Documents might be registered for the released orders. Continue?'; fa = 'Status ""Pending approval"" will be set for the orders selected in the list.
		|Documents might be registered for the released orders. Continue?';
		|it = 'Per gli ordini selezionati nell''elenco verrà impostato lo stato ""In fase di definizione"".
		| Per gli ordini accettati per l''esecuzione possono essere formalizzati i documenti. Continuare?';
		|pl = 'Dla wydzielonych w liście zamówień będzie ustawiony status ""На согласовании"".
		|Według przyjętych do wypełnienia zamówień mogą być sporządzone dokumenty. Kontynuować?';
		|tr = 'Listede seçili emirler ""Onay bekliyor"" durumuna getirilecektir.
		|Gerçekleştirilmek üzere kabul edilen emirler belgelenebilir. Devam edilsin mi?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("SetTheStatusForApprovalCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusForApprovalCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "NotApproved");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Cần thống nhất';
																												|ru = 'На согласовании';
																												|en = 'Pending approval'; fa = 'در انتظار تأیید';
																												|it = 'In fase di definizione';
																												|pl = 'Na uzgodnieniu';
																												|tr = 'Onay bekliyor'"));

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure SetTheStatusToExecute(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	If UseShipmentByRowsInSalesOrder Then
		StatusName = NStr("vi = 'Cần thực hiện';
							|ru = 'К выполнению';
							|en = 'Ready for fulfillment'; fa = 'آماده اجرا';
							|it = 'Da eseguire';
							|pl = 'Do wykonania';
							|tr = 'Karşılanmaya hazır'");
	Else
		StatusName = NStr("vi = 'Trong dự phòng';
							|ru = 'В резерве';
							|en = 'In reserve'; fa = 'در رزرو';
							|it = 'In riserva';
							|pl = 'W rezerwie';
							|tr = 'Rezervde'");
	EndIf;
	
	QueryText = NStr("vi = 'Trong các giấy ủy quyền mà được tách ra từ danh sách sẽ đặt trạng thái  ""%StatusName%"". Tiếp tục?';
					|ru = 'У выделенных в списке заказов будет установлен статус ""%StatusName%"". Продолжить?';
					|en = 'Status ""%StatusName%"" will be set for the orders selected in the list. Continue?'; fa = 'Status ""%StatusName%"" will be set for the orders selected in the list. Continue?';
					|it = 'Per gli ordini selezionati nell''elenco sarà impostato lo stato ""%StatusName%"". Continuare?';
					|pl = 'Dla wybranych w liście zamówień będzie ustawiony status %StatusName%. Kontynuować?';
					|tr = 'Sipariş listesinde seçili siparişlerin durumu ""%StatusName%"" olarak ayarlanacaktır. Devam edilsin mi?'");
	QueryText = StrReplace(QueryText, "%StatusName%", StatusName);
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("SetTheStatusToExecuteCompletion", ThisObject, New Structure("SelectedRows, StatusName", SelectedRows, StatusName)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusToExecuteCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    StatusName = AdditionalParameters.StatusName;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "ToSupply");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), StatusName);

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure SetTheStatusForShipment(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các đơn hàng đã chọn trong danh sách sẽ đặt trạng thái ""Cần giao hàng"". Tiếp tục?';
					|ru = 'У выделенных в списке заказов будет установлен статус ""К отгрузке"". Продолжить?';
					|en = 'Status ""To ship"" will be set for the orders selected in the list. Continue?'; fa = 'Status ""To ship"" will be set for the orders selected in the list. Continue?';
					|it = 'Per gli ordini selezionati nell''elenco verrà impostato lo stato ""Da spedire"". Continuare?';
					|pl = 'Dla wydzielonych w liście zamówień będzie ustawiony status ""К отгрузке"". Kontynuować?';
					|tr = 'Sipariş listesinde seçili siparişlerin durumu ""Sevk edilecek"" olarak ayarlanacaktır. Devam edilsin mi?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("SetTheStatusForShipmentCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusForShipmentCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "ToShip");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Cần giao hàng';
																												|ru = 'К отгрузке';
																												|en = 'To ship'; fa = 'برای ارسال';
																												|it = 'Da spedire';
																												|pl = 'Do wysłania';
																												|tr = 'Sevk edilecek'"));

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure SetTheClosedStatus(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ClosureStructure = New Structure;
	OrderList = New ValueList;
	OrderList.LoadValues(SelectedRows);
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
	
	ClearMessages();
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




&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.SalesOrder.DocumentsListForm.Item.List.Selection");
	
	If Field.Name = "ListOrderShipmentPercentage" Or Field.Name = "ListState" Then
		
		CurrentData = Items.List.CurrentData;
		If Not CurrentData = Undefined Then
			
			StandardProcessing = False;
			DocumentsList = New ValueList;
			DocumentsList.Add(CurrentData.Ref);
			
			If OrderAsAProformaInvoice(CurrentData.Ref) Then
				Return;
			EndIf;
			
			OpenForm("Report.DocumentFulfillmentStatus.Form.ReportForm", 
			             New Structure("IncomingDocuments", DocumentsList), 
			             ThisForm,
			             False);
		
		EndIf;
		
	EndIf;
	
	If Field = Items.StatusPresentation Then
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

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
	
	If GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
	
		// Color highlighting of the "Closed" status
		Item = ListOfConditionalAppearance.Items.Add();
		Item.Presentation = NStr("vi = 'Tách trạng thái ""Đã đóng"" bằng màu';
								|ru = 'Выделение цветом состояния ""Закрыт""';
								|en = 'Highlighting the ""Closed"" state'; fa = 'Highlighting the ""Closed"" state';
								|it = 'Evidenziamento con il colore dello stato ""Chiuso""';
								|pl = 'Wyróżnienie kolorem statusu ""Закрыт""';
								|tr = '""Kapalı"" durumunun vurgu rengi'");
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("State");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.SalesOrderStates.Closed;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
		
		// hiding the State and totals for orders created in the "order as invoice" mode
		Item = ListOfConditionalAppearance.Items.Add();
		Item.Presentation = NStr("vi = 'Ẩn trạng thái và tổng kết theo đơn hàng mà được tạo trong chế độ ""Đơn hàng như hóa đơn""';
								|ru = 'Скрытие состояния и итогов по заказам, созданных в режиме ""Заказ как счет""';
								|en = 'Hide the state and totals by the orders created in the ""Order as a commercial invoice"" mode'; fa = 'Hide the state and totals by the orders created in the ""Order as a commercial invoice"" mode';
								|it = 'Скрытие состояния и итогов по заказам, созданных в режиме ""Заказ как счет""';
								|pl = 'Hide the state and totals by the orders created in the ""Order as a commercial invoice"" mode';
								|tr = '""Fatura olarak sipariş"" modunda oluşturulan siparişlerin durumunu ve toplamlarını gizleme'");
		
		Item.Fields.Items.Add().Field = New DataCompositionField("State");
		Item.Fields.Items.Add().Field = New DataCompositionField("CustomerAccountsReceivable");
		Item.Fields.Items.Add().Field = New DataCompositionField("AccountsPayableOfCompany");
		Item.Fields.Items.Add().Field = New DataCompositionField("DebtPercentage");
		Item.Fields.Items.Add().Field = New DataCompositionField("PayPercentage");
		Item.Fields.Items.Add().Field = New DataCompositionField("PayAmount");
		Item.Fields.Items.Add().Field = New DataCompositionField("LatePaymentAmount");
		Item.Fields.Items.Add().Field = New DataCompositionField("AmountByShipment");
		Item.Fields.Items.Add().Field = New DataCompositionField("OrderShipmentPercentage");
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ThisIsOrderAsInvoice");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
		Item.Appearance.SetParameterValue("Text", NStr("vi = '-';
														|ru = '-';
														|en = '-'; fa = '-';
														|it = '-';
														|pl = '-';
														|tr = '-'"));
		
	EndIf;
	
	
	// Highlighting an overdue order in color
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Tách đơn hàng quá hạn bằng màu';
							|ru = 'Выделение цветом просроченного заказа';
							|en = 'Highlighting overdue order'; fa = 'Highlighting overdue order';
							|it = 'Evidenziamento con il colore di un ordine scaduto';
							|pl = 'Wyróżnienie kolorem zaległego zamówienia';
							|tr = 'Vadesi geçmiş siparişin vurgu rengi'");
	
	Item.Fields.Items.Add().Field = New DataCompositionField("State");
	Item.Fields.Items.Add().Field = New DataCompositionField("EventDate");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Overdue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDocument);
	
	// Hiding order totals when accounting for settlements under contracts or invoices
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Ẩn tổng số theo đơn hàng khi ghi nhận hạch toán theo hợp đồng hoặc hóa đơn';
							|ru = 'Скрытие итогов по заказу при учете расчетов по договорам или накладным';
							|en = 'Hide order totals while accounting settlements of contracts or invoices'; fa = 'Hide order totals while accounting settlements of contracts or invoices';
							|it = 'Nascondere i totali dell''ordine durante i calcoli in base ai contratti o bolle';
							|pl = 'Ukrycie wyników według zamówienia przy uwzględnieniu rozliczeń według kontraktów lub faktur';
							|tr = 'Sözleşme veya irsaliye ödemelerini muhasebeleştirirken sipariş toplamlarını gizleme'");
	
	Item.Fields.Items.Add().Field = New DataCompositionField("CustomerAccountsReceivable");
	Item.Fields.Items.Add().Field = New DataCompositionField("AccountsPayableOfCompany");
	Item.Fields.Items.Add().Field = New DataCompositionField("DebtPercentage");
	Item.Fields.Items.Add().Field = New DataCompositionField("PayPercentage");
	Item.Fields.Items.Add().Field = New DataCompositionField("PayAmount");
	Item.Fields.Items.Add().Field = New DataCompositionField("LatePaymentAmount");
	Item.Fields.Items.Add().Field = New DataCompositionField("AmountByShipment");
	Item.Fields.Items.Add().Field = New DataCompositionField("OrderShipmentPercentage");
	
	ListOfCalculationOrders = New ValueList();
	ListOfCalculationOrders.Add(Enums.ARAPObjectSettings.ByOrders);
	ListOfCalculationOrders.Add(Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ARAPObjectSettings");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ListOfCalculationOrders;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '-';
													|ru = '-';
													|en = '-'; fa = '-';
													|it = '-';
													|pl = '-';
													|tr = '-'"));
	

	ConditionalAppearance.Items.Clear();
	
	// Changing the status view, depending on the enabled options.
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Thay đổi cách trình bày trạng thái, tùy thuộc vào tùy chọn đã bật.';
							|ru = 'Изменение представления статуса, в зависимости от включенных опций.';
							|en = 'Change status presentation depending on the enabled options.'; fa = 'Change status presentation depending on the enabled options.';
							|it = 'Modifica della visualizzazione di stato, a seconda delle opzioni attive.';
							|pl = 'Zmiana prezentacji statusu, w zależności od włączonych opcji.';
							|tr = 'Etkinleştirilen seçeneklere bağlı olarak durum görünümünün değiştirilmesi.'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SalesOrderStatuses.ToSupply;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseShipmentByRowsInSalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Cần thực hiện';
													|ru = 'К выполнению';
													|en = 'Ready for fulfillment'; fa = 'آماده اجرا';
													|it = 'Da eseguire';
													|pl = 'Do wykonania';
													|tr = 'Karşılanmaya hazır'"));

	// Changing the status view, depending on the enabled options.
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Thay đổi cách trình bày trạng thái, tùy thuộc vào tùy chọn đã bật.';
							|ru = 'Изменение представления статуса, в зависимости от включенных опций.';
							|en = 'Change status presentation depending on the enabled options.'; fa = 'Change status presentation depending on the enabled options.';
							|it = 'Modifica della visualizzazione di stato, a seconda delle opzioni attive.';
							|pl = 'Zmiana prezentacji statusu, w zależności od włączonych opcji.';
							|tr = 'Etkinleştirilen seçeneklere bağlı olarak durum görünümünün değiştirilmesi.'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SalesOrderStatuses.ToSupply;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseShipmentByRowsInSalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Trong dự phòng';
													|ru = 'В резерве';
													|en = 'In reserve'; fa = 'در رزرو';
													|it = 'In riserva';
													|pl = 'W rezerwie';
													|tr = 'Rezervde'"));
	
	

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.ListDate.Name);


EndProcedure

&AtServerNoContext
Function OrderAsAProformaInvoice(OrderDocument)
	
	Return Common.ObjectAttributeValue(OrderDocument, "ThisIsOrderAsInvoice");
	
EndFunction

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.SalesOrder.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Val Notification, Data)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Ref = ReferencesArrray[0];
		Items.List.CurrentRow = Ref;
		ShowValue(New CallbackDescription("ProcessBarcodesCompletion", ThisObject, New Structure("Data, Notification", Data, Notification)), Ref);
        Return;
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
	ProcessBarcodesFragment(Notification);
EndProcedure

&AtClient
Procedure ProcessBarcodesCompletion(AdditionalParameters) Export
    
    Data = AdditionalParameters.Data;
    Notification = AdditionalParameters.Notification;
    
    
    ProcessBarcodesFragment(Notification);

EndProcedure

&AtClient
Procedure ProcessBarcodesFragment(Val Notification)
    
    RunCallback(Notification);

EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CheckWhetherInventoryAllocationTaskIsCompletedForOrders()
	ProvisionInDocumentsClient.CheckWhetherInventoryAllocationTaskIsCompletedForOrders(ThisObject, Items.List);
EndProcedure

&AtServer
Procedure SetSelectionByStateServer()
	
	If State = "AllOpened" Then
		
		CommonClientServer.SetDynamicListFilterItem(List, "State", Enums.SalesOrderStates.Closed, DataCompositionComparisonType.NotEqual,, True);
		CommonClientServer.SetDynamicListFilterItem(List, "DeletionMark", False,,, True);
		
	ElsIf State = "AllPaymentPending" Then
		
		StateArray = New Array();
		StateArray.Add(Enums.SalesOrderStates.PendingAdvanceBeforeSupply);
		StateArray.Add(Enums.SalesOrderStates.PendingPrepaymentBeforeShipment);
		StateArray.Add(Enums.SalesOrderStates.PendingPaymentAfterShipment);
		
		CommonClientServer.SetDynamicListFilterItem(List, "State", StateArray, DataCompositionComparisonType.InList,, True);
		CommonClientServer.SetDynamicListFilterItem(List, "DeletionMark", False,,, True);
		
	ElsIf State = "AllExecutionPending" Then
		
		StateArray = New Array();
		StateArray.Add(Enums.SalesOrderStates.PendingApproval);
		StateArray.Add(Enums.SalesOrderStates.ReadyForSupply);
		StateArray.Add(Enums.SalesOrderStates.PendingSupply);
		StateArray.Add(Enums.SalesOrderStates.ReadyToShip);
		StateArray.Add(Enums.SalesOrderStates.DuringShipment);
		StateArray.Add(Enums.SalesOrderStates.TransferOfTitleToGoodsIsExpected);
		StateArray.Add(Enums.SalesOrderStates.ReadyForClosure);
		
		CommonClientServer.SetDynamicListFilterItem(List, "State", StateArray, DataCompositionComparisonType.InList,, True);
		CommonClientServer.SetDynamicListFilterItem(List, "DeletionMark", False,,, True);
		
	Else
		
		CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
		CommonClientServer.SetDynamicListFilterItem(List, "DeletionMark",,,, False);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetItemsVisibility()
	
	ThereIsChangeAccess = AccessRight("Update", Metadata.Documents.SalesOrder);
	UseAdvancedFeaturesOfSalesOrder = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	UseShipmentByRowsInSalesOrder = GetFunctionalOption("UseShipmentByRowsInSalesOrder");
	
	Items.SetTheStatusForShipment.Visible = UseAdvancedFeaturesOfSalesOrder
													And Not UseShipmentByRowsInSalesOrder;
	
	Items.ListPayAmount.Visible             = UseAdvancedFeaturesOfSalesOrder;
	Items.ListPayPercentage.Visible           = UseAdvancedFeaturesOfSalesOrder;
	Items.ListAmountByShipment.Visible           = UseAdvancedFeaturesOfSalesOrder;
	Items.ListOrderShipmentPercentage.Visible         = UseAdvancedFeaturesOfSalesOrder;
	Items.ListAccountsPayableOfCompany.Visible                 = UseAdvancedFeaturesOfSalesOrder;
	Items.ListCustomerAccountsReceivable.Visible             = UseAdvancedFeaturesOfSalesOrder;
	Items.ListDebtPercentage.Visible            = UseAdvancedFeaturesOfSalesOrder;
	Items.ListEventDate.Visible             = UseAdvancedFeaturesOfSalesOrder;
	Items.ListState.Visible               = UseAdvancedFeaturesOfSalesOrder;
	Items.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice.Visible = UseAdvancedFeaturesOfSalesOrder;
	
	Items.SetTheClosedStatus.Visible        = AccessRight("Update",Metadata.Documents.SalesOrder);
	
	SoftwareCommandsAreVisible = UseShipmentByRowsInSalesOrder And ThereIsChangeAccess;
	Items.ListShipByOrder.Visible = SoftwareCommandsAreVisible;
	Items.ListReserveAnOrder.Visible = SoftwareCommandsAreVisible;
	Items.ListToSupplyOrder.Visible = SoftwareCommandsAreVisible;
	Items.ListReserveAsReceivedOrder.Visible = SoftwareCommandsAreVisible;
	Items.ListDoNotSupplyOrder.Visible = SoftwareCommandsAreVisible;
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"ListSupplyForecastOfOrderList",
		"Visible",
		UseShipmentByRowsInSalesOrder);
	
EndProcedure

&AtClient
Procedure HyperlinkSalesLogURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("FormAssignmentKey", "");
	FormParameters.Insert("FormUniqueID", False);
	
	NameOfFormToOpen_ = "DataProcessor.LogOfSalesDocuments.Form.DocumentsList";
	
	OpenForm(NameOfFormToOpen_, FormParameters,, FormParameters.FormUniqueID);
	
EndProcedure


#Region SettingUpSetOfDocuments

&AtClient
Procedure GetASetOfDocumentsSetup(Command)
	
	ObjectKey = "DataProcessor.LogOfSalesDocuments.Form.ToRegisterInvoices/CurrentData";
	
	Notification = New CallbackDescription("GetASetOfDocumentsSetupCompletion", ThisObject, ObjectKey);
	
	FormParameters = SalesServerCall.GetASetOfDocumentsSetup(ObjectKey);
	OpenForm("DataProcessor.LogOfSalesDocuments.Form.ParametersOfSalesDocumentCreation", FormParameters,
		ThisForm, , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure GetASetOfDocumentsSetupCompletion(Result, ObjectKey) Export 
	
	If Result <> Undefined Then
		SalesServerCall.SaveDocumentSetSettings(Result, ObjectKey);
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#EndRegion

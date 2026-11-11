
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	UseStatuses               = GetFunctionalOption("UsePurchaseOrderStatuses");
	UseSimplifiedPaymentScheme = GetFunctionalOption("UseSimplifiedPaymentSchemeInPurchasing");
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	List.Parameters.SetParameterValue("LowestPriority", Catalogs.Priorities.GetLowerPriority());
	List.Parameters.SetParameterValue("HighestPriority", Catalogs.Priorities.GetTopPriority());
	List.Parameters.SetParameterValue("UpdateDate", BegOfDay(CurrentSessionDate()));
	List.Parameters.SetParameterValue("UseStatuses", UseStatuses);
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(Items.FilterDueDate_2.ChoiceList);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Manager", Manager, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Priority", Priority, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByRelevanceWhenCreatingOnServer(List, Relevance, Items.FilterDueDate_2.ChoiceList, EventDate, QuickFilterStructure);
	
	If ListSelectionsClientServer.YouNeedToSelectByStateWhenCreatingOnServer(State, QuickFilterStructure) Then
		SetSelectionByStateServer();
	EndIf;
	
	FillSelectionSelectionListByServerState(Items.FilterState.ChoiceList, UseStatuses, UseSimplifiedPaymentScheme);
	UseReceiptForMultipleOrders = GetFunctionalOption("UseReceiptForMultipleOrders");
	
	Items.FormTheGroupList.Visible = Documents.PurchaseOrder.AccessRightInsert();

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
EndProcedure

&AtClient
Procedure NotificationProcessingCompletion(Result, AdditionalParameters) Export
    
    EventName = AdditionalParameters.EventName;
    
    
    HandlingFragmentAlerts(EventName);

EndProcedure

&AtClient
Procedure HandlingFragmentAlerts(Val EventName)
	
	If EventName = "PaymentCredited" 
		Or PurchasesClient.SupplierPaymentDocumentsChanged(EventName)
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
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));

EndProcedure

&AtClient
Procedure FilterPriorityOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Priority", Priority, DataCompositionComparisonType.Equal,, ValueIsFilled(Priority));

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

&AtClient
Procedure HyperlinkPurchaseHistoryURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("FormAssignmentKey", "");
	OpenForm("DataProcessor.LogOfPurchaseDocuments.Form.DocumentsList", FormParameters);
	
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

#EndRegion

#Region EventHandlersForTableElements

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.PurchaseOrder.DocumentsListForm.Item.List.Selection");
	
	If Field.Name = "ListState" Then
		
		CurrentData = Items.List.CurrentData;
		If Not CurrentData = Undefined Then
			
			StandardProcessing = False;
			DocumentsList = New ValueList;
			DocumentsList.Add(CurrentData.Ref);
			
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

#Region FormCommandsEventHandlers

&AtClient
Procedure SetTheStatusNotAgreed_5(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các đơn hàng đã chọn trong danh sách sẽ đặt trạng thái ""Chưa điều chỉnh"". Theo các đơn hàng đã đưa vào xử lý có thể lập chứng từ. Tiếp tục?';
					|ru = 'У выделенных в списке заказов будет установлен статус ""Не согласован"". По принятым в работу заказам могут быть оформлены документы. Продолжить?';
					|en = 'The status of the selected orders will change to Not approved. The accepted orders can be processed. Continue?'; fa = 'The status of the selected orders will change to Not approved. The accepted orders can be processed. Continue?';
					|it = 'Per gli ordini selezionati nell''elenco verrà impostato lo stato ""Non concordato"". Per gli ordini accettati per l''esecuzione possono essere formalizzati i documenti. Continuare?';
					|pl = 'Dla wybranych w liście zamówień będzie ustawiony status ""Не согласован"". Według przyjętych do pracy zamówień mogą być sporządzone dokumenty. Kontynuować?';
					|tr = 'Listede seçili siparişler ""Beklemede"" durumuna ayarlanacaktır. Kabul edilen siparişler için belgeler düzenlenebilir. Devam edilsin mi?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("SetTheStatusNotAgreed_5Completion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusNotAgreed_5Completion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "NotApproved");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Không thống nhất';
																												|ru = 'Не согласован';
																												|en = 'Not approved'; fa = 'تأییدنشده';
																												|it = 'Non concordato';
																												|pl = 'Nieuzgodniony';
																												|tr = 'Beklemede'"));

EndProcedure

&AtClient
Procedure SetTheStatusOfTheAgreed_3(Command)

	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các đơn hàng đã chọn trong danh sách đã đặt trạng thái ""Đã điều chỉnh"". Tiếp tục?';
					|ru = 'У выделенных в списке заказов будет установлен статус ""Согласован"". Продолжить?';
					|en = 'The status of the selected orders will change to Approved. Continue?'; fa = 'The status of the selected orders will change to Approved. Continue?';
					|it = 'Per gli ordini selezionati nella lista sarà impostato lo stato ""Concordato"". Continuare?';
					|pl = 'Dla wybranych w liście zamówień będzie ustawiony status ""Согласован"". Kontynuować?';
					|tr = 'Sipariş listesinde seçili siparişlerin durumu ""Kabul Edildi"" olarak ayarlanacaktır. Devam edilsin mi?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("SetTheStatusOfTheAgreed_3Completion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusOfTheAgreed_3Completion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "Approved");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Đã thống nhất';
																												|ru = 'Согласован';
																												|en = 'Approved'; fa = 'تأییدشده';
																												|it = 'Concordato';
																												|pl = 'Approved';
																												|tr = 'Onaylandı'"));

EndProcedure

&AtClient
Procedure SetTheStatusToConfirmed(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các đơn hàng đã chọn trong danh sách đã đặt trạng thái ""Xác nhận"". Tiếp tục?';
					|ru = 'У выделенных в списке заказов будет установлен статус ""Подтвержден"". Продолжить?';
					|en = 'The status of the selected orders will change to Confirmed. Continue?'; fa = 'The status of the selected orders will change to Confirmed. Continue?';
					|it = 'Per gli ordini selezionati nella lista sarà impostato lo stato ""Confermato"". Continuare?';
					|pl = 'Dla wybranych w liście zamówień będzie ustawiony status ""Подтвержден"". Kontynuować?';
					|tr = 'Sipariş listesinde seçili siparişlerin durumu ""Teyit edildi"" olarak ayarlanacaktır. Devam edilsin mi?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("SetTheStatusToConfirmedCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusToConfirmedCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "Confirmed_");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Đã xác nhận';
																												|ru = 'Подтвержден';
																												|en = 'Confirmed'; fa = 'تأییدشده';
																												|it = 'Confermato';
																												|pl = 'Confirmed';
																												|tr = 'Teyit edildi'"));

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
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.PurchaseOrderStates.Closed;

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
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.PurchaseOrderStates.Closed;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.LowDocumentPriority);
	
	If GetFunctionalOption("UsePurchaseOrderStatuses") Then
		
		// Color highlighting of the "Closed" status
		Item = ListOfConditionalAppearance.Items.Add();
		Item.Presentation = NStr("vi = 'Tách trạng thái ""Đã đóng"" bằng màu';
								|ru = 'Выделение цветом состояния ""Закрыт""';
								|en = 'Highlight closed orders'; fa = 'Highlight closed orders';
								|it = 'Evidenziamento con il colore dello stato ""Chiuso""';
								|pl = 'Wyróżnienie kolorem statusu ""Закрыт""';
								|tr = '""Kapalı"" durumunun vurgu rengi'");
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("State");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.PurchaseOrderStates.Closed;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
		
	EndIf;
	
	// Highlighting an overdue order in color
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Tách đơn hàng quá hạn bằng màu';
							|ru = 'Выделение цветом просроченного заказа';
							|en = 'Highlight overdue orders'; fa = 'Highlight overdue orders';
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
	
	// Hiding order totals during contract calculations
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Ẩn tổng số theo đơn hàng khi hạch toán theo hợp đồng';
							|ru = 'Скрытие итогов по заказу при расчетах по договору';
							|en = 'Hide totals for contract settlements'; fa = 'Hide totals for contract settlements';
							|it = 'Nascondere i totali per un ordine durante i calcoli per un contratto';
							|pl = 'Ukrycie wyników według zamówienia podczas rozliczeń według kontraktu';
							|tr = 'Sözleşme mutabakatları sırasında sipariş toplamlarını gizleme'");
	
	Item.Fields.Items.Add().Field = New DataCompositionField("DebtOfSupplier");
	Item.Fields.Items.Add().Field = New DataCompositionField("AccountsPayableOfCompany");
	Item.Fields.Items.Add().Field = New DataCompositionField("DebtPercentage");
	Item.Fields.Items.Add().Field = New DataCompositionField("PayPercentage");
	Item.Fields.Items.Add().Field = New DataCompositionField("PercentageOfOrderReceipt");
	Item.Fields.Items.Add().Field = New DataCompositionField("PayAmount");
	Item.Fields.Items.Add().Field = New DataCompositionField("OrderReceiptAmount");
	Item.Fields.Items.Add().Field = New DataCompositionField("LatePaymentAmount");
	Item.Fields.Items.Add().Field = New DataCompositionField("PercentageOfOrderReceipt");
	Item.Fields.Items.Add().Field = New DataCompositionField("OrderReceiptAmount");
	
	ListOfCalculationOrders = New ValueList();
	ListOfCalculationOrders.Add(Enums.ARAPObjectSettings.ByOrders);
	ListOfCalculationOrders.Add(Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ARAPObjectSettings");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ListOfCalculationOrders;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '-';
													|ru = '-';
													|en = '-'; fa = '-';
													|it = '-';
													|pl = '-';
													|tr = '-'"));
	

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.ListDate.Name);
	
	PurchasesServer.SetConditionalAppearanceOfOperationOfOrderToSupplier(ThisObject);
	
EndProcedure


#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.PurchaseOrder.EmptyRef"));
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

&AtServerNoContext
Procedure FillSelectionSelectionListByServerState(ChoiceList, UseStatuses, UseSimplifiedPaymentScheme)
	
	ChoiceList.Add("AllOpened", NStr("vi = 'Tất cả đã mở';
									|ru = 'Все открытые';
									|en = 'Open orders'; fa = 'سفارش‌های باز';
									|it = 'Tutti aperti';
									|pl = 'Wszystkie otwarte';
									|tr = 'Tümü açık'"));
	ChoiceList.Add("AllPaymentPending", NStr("vi = 'Tất cả đang chờ thanh toán';
											|ru = 'Все ожидающие оплаты';
											|en = 'Unpaid orders'; fa = 'Unpaid orders';
											|it = 'Tutti in attesa di pagamento';
											|pl = 'Wszystkie oczekujące płatności';
											|tr = 'Bekleyen ödemelerin tümü'"));
	ChoiceList.Add("AllExecutionPending", NStr("vi = 'Tất cả đang chờ thực hiện';
												|ru = 'Все ожидающие исполнения';
												|en = 'Unfulfilled orders'; fa = 'سفارش‌های اجرانشده';
												|it = 'Tutti in attesa di esecuzione';
												|pl = 'Wszystkie oczekujące wykonania';
												|tr = 'Bekleyen gerçekleştirmelerin tümü'"));
	
	If UseStatuses Then
		For Each CurValue In Enums.PurchaseOrderStates Do
			ChoiceList.Add(CurValue, CurValue);
		EndDo;
	Else
		ChoiceList.Add(Enums.PurchaseOrderStates.PendingAdvanceBeforeConfirmation);
		ChoiceList.Add(Enums.PurchaseOrderStates.PendingPrepaymentBeforePurchase);
		ChoiceList.Add(Enums.PurchaseOrderStates.PendingReceipt);
		ChoiceList.Add(Enums.PurchaseOrderStates.PendingPaymentAfterReceipt);
		ChoiceList.Add(Enums.PurchaseOrderStates.Closed);
	EndIf;
	
	If UseSimplifiedPaymentScheme Then
		
		StageExpectedAdvanceBeforeConfirmation = ChoiceList.FindByValue(Enums.PurchaseOrderStates.PendingAdvanceBeforeConfirmation);
		If StageExpectedAdvanceBeforeConfirmation <> Undefined Then
			ChoiceList.Delete(StageExpectedAdvanceBeforeConfirmation);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionByStateServer()
	
	If State = "AllOpened" Then
		
		CommonClientServer.SetDynamicListFilterItem(List, "State", Enums.PurchaseOrderStates.Closed, DataCompositionComparisonType.NotEqual,, True);
		CommonClientServer.SetDynamicListFilterItem(List, "DeletionMark", False,,, True);
		
	ElsIf State = "AllPaymentPending" Then
		
		StateArray = New Array();
		
		StateArray.Add(Enums.PurchaseOrderStates.PendingAdvanceBeforeConfirmation);
		StateArray.Add(Enums.PurchaseOrderStates.PendingPrepaymentBeforePurchase);
		StateArray.Add(Enums.PurchaseOrderStates.PendingPaymentAfterReceipt);
		
		CommonClientServer.SetDynamicListFilterItem(List, "State", StateArray, DataCompositionComparisonType.InList,, True);
		CommonClientServer.SetDynamicListFilterItem(List, "DeletionMark", False,,, True);
		
	ElsIf State = "AllExecutionPending" Then
		
		StateArray = New Array();
		StateArray.Add(Enums.PurchaseOrderStates.PendingApproval);
		StateArray.Add(Enums.PurchaseOrderStates.PendingConfirmation);
		StateArray.Add(Enums.PurchaseOrderStates.ReadyForReceipt);
		StateArray.Add(Enums.PurchaseOrderStates.PendingReceipt);
		StateArray.Add(Enums.PurchaseOrderStates.ReadyForClosure);
		
		CommonClientServer.SetDynamicListFilterItem(List, "State", StateArray, DataCompositionComparisonType.InList,, True);
		CommonClientServer.SetDynamicListFilterItem(List, "DeletionMark", False,,, True);
		
	Else
		
		CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
		CommonClientServer.SetDynamicListFilterItem(List, "DeletionMark",,,, False);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

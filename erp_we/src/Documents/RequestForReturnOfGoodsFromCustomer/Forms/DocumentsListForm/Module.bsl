
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If ValueIsFilled(Parameters.FormCaption) Then
		Title = Parameters.FormCaption;
	EndIf;
	
	SetConditionalAppearance();
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	UseSimplifiedPaymentScheme = GetFunctionalOption("UseSimplifiedPaymentSchemeInSales");
	
	List.Parameters.SetParameterValue("UpdateDate",               BegOfDay(CurrentSessionDate()));
	UseWarehouseManagemantSystemForGoodsIssue = GetFunctionalOption("UseWarehouseManagemantSystemForGoodsIssue");
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(Items.FilterDueDate_2.ChoiceList);	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Manager", Manager, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Priority", Priority, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByRelevanceWhenCreatingOnServer(List, Relevance, Items.FilterDueDate_2.ChoiceList, EventDate, QuickFilterStructure);
	
	If ListSelectionsClientServer.YouNeedToSelectByStateWhenCreatingOnServer(State, QuickFilterStructure) Then
		SetSelectionByStateServer();
	EndIf;
	
	FillInListOfBusinessOperations();
	FillSelectionSelectionListByServerState(Items.FilterState.ChoiceList, UseSimplifiedPaymentScheme);
	UseSaleByMultipleOrders = GetFunctionalOption("UseSaleByMultipleOrders");
	UseCustomerInvoicesForSeveralOrders = GetFunctionalOption("UseCustomerInvoicesForSeveralOrders");
	
	SetItemsVisibility();
	UseShipmentByRowsInSalesOrder = GetFunctionalOption("UseShipmentByRowsInSalesOrder");
	If Not UseShipmentByRowsInSalesOrder Then
		Items.ListSetTheStatusToExecute.Title = NStr("vi = 'Trong dự phòng';
													|ru = 'В резерве';
													|en = 'In reserve'; fa = 'در رزرو';
													|it = 'In riserva';
													|pl = 'W rezerwie';
													|tr = 'Rezervde'");
	EndIf;
	
	AddingIsAvailable = AccessRight("Insert", Metadata.Documents.RequestForReturnOfGoodsFromCustomer);
	UseSalesCommission = GetFunctionalOption("UseSalesCommission");
	UseRetailSales = GetFunctionalOption("UseRetailSales");
	
	Items.GroupCreate.Visible = AddingIsAvailable And (UseSalesCommission Or UseRetailSales);
	If AddingIsAvailable Then
		Items.ListCreate.Visible = Not UseSalesCommission And Not UseRetailSales;
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
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "ListOrderShipmentPercentage" Or Field.Name = "ListState" Then
		
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
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnChange(Item)
	
	ProvisionInDocumentsClient.ListOnChange(ThisObject, "Document.RequestForReturnOfGoodsFromCustomer");
	
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
	
	QueryText = NStr("vi = 'Đối với các đề nghị đã chọn trong danh sách sẽ thiết lập trạng thái ""Cần thống nhất"". 
		|Có thể lập chứng từ theo các đề nghị đã tiếp nhận để thực hiện. Tiếp tục?';
		|ru = 'У выделенных в списке заявок будет установлен статус ""На согласовании"". 
		|По принятым к выполнению заявкам могут быть оформлены документы. Продолжить?';
		|en = 'Status ""Pending approval"" will be set for the requests selected in the list.
		|Documents might be registered for the requests accepted for processing. Continue?'; fa = 'Status ""Pending approval"" will be set for the requests selected in the list.
		|Documents might be registered for the requests accepted for processing. Continue?';
		|it = 'Per le domande selezionate nell''elenco verrà impostato lo stato ""In fase di definizione"". 
		| Per gli ordini accettati per l''esecuzione possono essere formalizzati i documenti. Continuare?';
		|pl = 'Dla wybranych w liście zleceń będzie ustawiony status ""На согласовании"". 
		|Według przyjętych do wypełnienia zleceń mogą być sporządzone dokumenty. Kontynuować?';
		|tr = 'Listede seçili talepler ""Onay bekliyor"" durumuna ayarlanacaktır.
		| Kabul edilen talepler belgelenebilir. Devam edilsin mi?'");
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
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "NotAgreedUpon");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Cần thống nhất';
																												|ru = 'На согласовании';
																												|en = 'Pending approval'; fa = 'در انتظار تأیید';
																												|it = 'In fase di definizione';
																												|pl = 'Na uzgodnieniu';
																												|tr = 'Onay bekliyor'"));

EndProcedure

&AtClient
Procedure SetTheStatusForRefund(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các đơn hàng đã chọn trong danh sách sẽ đặt trạng thái ""Cần trả lại"". Tiếp tục?';
					|ru = 'У выделенных в списке заявок будет установлен статус ""К возврату"". Продолжить?';
					|en = 'Status ""For return"" will be set for the requests selected in the list. Continue?'; fa = 'Status ""For return"" will be set for the requests selected in the list. Continue?';
					|it = 'Alle domande selezionate nell''elenco verrà assegnato lo stato ""Per il reso"". Continuare?';
					|pl = 'Dla wybranych w liście zleceń będzie ustawiony status ""К возврату"". Kontynuować?';
					|tr = 'Talep listesinde seçilenler ""İade edilecek"" olarak ayarlanacaktır. Devam edilsin mi?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("SetTheStatusForRefundCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusForRefundCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "ForReturn");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Cần trả lại';
																												|ru = 'К возврату';
																												|en = 'For return'; fa = 'برای برگشت';
																												|it = 'In restituzione';
																												|pl = 'Do zwrotu';
																												|tr = 'İade edilmek üzere'"));

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
	
	QueryText = NStr("vi = 'Trong đơn hàng đã chọn từ danh sách sẽ đặt trạng thái ""%StatusName%"". Tiếp tục?';
					|ru = 'У выделенных в списке заявок будет установлен статус ""%StatusName%"". Продолжить?';
					|en = 'Status ""%StatusName%"" will be set for the requests selected in the list. Continue?'; fa = 'Status ""%StatusName%"" will be set for the requests selected in the list. Continue?';
					|it = 'Per le domande selezionate nell''elenco sarà impostato lo stato ""%StatusName%"". Continuare?';
					|pl = 'Dla wybranych w liście zleceń będzie ustawiony status %StatusName%. Kontynuować?';
					|tr = 'Talep listesinde seçili siparişlerin durumu ""%StatusName%"" olarak ayarlanacaktır. Devam edilsin mi?'");
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

EndProcedure

&AtClient
Procedure SetTheStatusForShipment(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các đơn hàng đã chọn trong danh sách sẽ đặt trạng thái ""Cần giao hàng"". Tiếp tục?';
					|ru = 'У выделенных в списке заявок будет установлен статус ""К отгрузке"". Продолжить?';
					|en = 'Status ""To ship"" will be set for the requests selected in the list. Continue?'; fa = 'Status ""To ship"" will be set for the requests selected in the list. Continue?';
					|it = 'Per le domande selezionate nell''elenco verrà impostato lo stato ""Da spedire"". Continuare?';
					|pl = 'Dla wybranych w liście zleceń będzie ustawiony status ""К отгрузке"". Kontynuować?';
					|tr = 'Talep listesinde seçili siparişlerin durumu ""Sevk edilecek"" olarak ayarlanacaktır. Devam edilsin mi?'");
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

EndProcedure

&AtClient
Procedure ToSetTheStatusToRejected(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các đơn hàng đã chọn trong danh sách sẽ đặt trạng thái ""Hủy bỏ"". Tiếp tục?';
					|ru = 'У выделенных в списке заявок будет установлен статус ""Отклонена"". Продолжить?';
					|en = 'Status of the requests selected in the list will be set to Rejected. Continue?'; fa = 'Status of the requests selected in the list will be set to Rejected. Continue?';
					|it = 'Per le domande selezionate nell''elenco sarà impostato lo stato ""Respinta"". Continuare?';
					|pl = 'Dla wybranych w liście zleceń będzie ustawiony status  ""Отклонена"". Kontynuować?';
					|tr = 'Talep listesinde seçilenlerin durumu ""Reddedildi"" olarak ayarlanacaktır. Devam edilsin mi?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("ToSetTheStatusToRejectedCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ToSetTheStatusToRejectedCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "IsRejected");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Bị từ chối';
																												|ru = 'Отклонена';
																												|en = 'Rejected'; fa = 'ردشده';
																												|it = 'Respinta';
																												|pl = 'Rejected';
																												|tr = 'Reddedildi'"));

EndProcedure

&AtClient
Procedure ToSetTheStatusToCompleted(Command)
	
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

&AtClient
Procedure CreateRequestOnReturnFromConsignee(Command)
	
	CreateRequestForReturnOfGoodsFromClient(0);
	
EndProcedure

&AtClient
Procedure CreateRequestOnReturnFromRetailCustomer(Command)
	
	CreateRequestForReturnOfGoodsFromClient(1);
	
EndProcedure

&AtClient
Procedure ToCreateAnApplicationForTheReturnOfTheKeeper(Command)
	
	CreateRequestForReturnOfGoodsFromClient(2);
	
EndProcedure

&AtClient
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
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInListByHierarchy;
	ItemFilter.RightValue = New ValueList;
	ItemFilter.RightValue.ValueType = New TypeDescription("EnumRef.StatesOfRequestsForReturnOfGoodsFromCustomers");
	ItemFilter.RightValue.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.Executed);
	ItemFilter.RightValue.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.IsRejected);

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
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInListByHierarchy;
	ItemFilter.RightValue = New ValueList;
	ItemFilter.RightValue.ValueType = New TypeDescription("EnumRef.StatesOfRequestsForReturnOfGoodsFromCustomers");
	ItemFilter.RightValue.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.Executed);
	ItemFilter.RightValue.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.IsRejected);

	Item.Appearance.SetParameterValue("BackColor", StyleColors.LowDocumentPriority);
	
	If GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
	
		// Color highlighting of the "Completed" status
		Item = ListOfConditionalAppearance.Items.Add();
		Item.Presentation = NStr("vi = 'Tách chọn bằng màu đối với trạng thái ""Đã thực hiện""';
								|ru = 'Выделение цветом состояния ""Выполнена""';
								|en = 'Highlight the ""Completed"" state'; fa = 'Highlight the ""Completed"" state';
								|it = 'Evidenziamento con il colore dello stato ""Completata""';
								|pl = 'Wyróżnienie kolorem statusu ""Выполнена""';
								|tr = '""Gerçekleştirildi"" durumunun renkli olarak vurgulanması'");
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("State");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.Executed;
		
		// hiding the State and totals for orders created in the "order as invoice" mode
		Item = ListOfConditionalAppearance.Items.Add();
		Item.Presentation = NStr("vi = 'Ẩn trạng thái và tổng số theo yêu cầu mà được tạo trong chế độ ""Đơn hàng như hóa đơn""';
								|ru = 'Скрытие состояния и итогов по заявкам, созданных в режиме ""Заказ как счет""';
								|en = 'Hide the state and totals by the requests created in the ""Order as a commercial invoice"" mode'; fa = 'Hide the state and totals by the requests created in the ""Order as a commercial invoice"" mode';
								|it = 'Скрытие состояния и итогов по заявкам, созданных в режиме ""Заказ как счет""';
								|pl = 'Hide the state and totals by the requests created in the ""Order as a commercial invoice"" mode';
								|tr = '""Fatura olarak sipariş"" modunda oluşturulan taleplerin durumunu ve toplamlarını gizleme'");
		
		Item.Fields.Items.Add().Field = New DataCompositionField("State");
		Item.Fields.Items.Add().Field = New DataCompositionField("CustomerAccountsReceivable");
		Item.Fields.Items.Add().Field = New DataCompositionField("AccountsPayableOfCompany");
		Item.Fields.Items.Add().Field = New DataCompositionField("DebtPercentage");
		Item.Fields.Items.Add().Field = New DataCompositionField("PayPercentage");
		Item.Fields.Items.Add().Field = New DataCompositionField("PayAmount");
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
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
	// Highlighting an overdue application in color
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Tách chọn bằng màu đối với giấy đề nghị quá hạn';
							|ru = 'Выделение цветом просроченной заявки';
							|en = 'Highlight overdue request'; fa = 'Highlight overdue request';
							|it = 'Evidenziamento con il colore della domanda scaduta';
							|pl = 'Wyróżnienie kolorem zaległych zleceń';
							|tr = 'Gecikmiş bir talebin vurgu rengi'");
	
	Item.Fields.Items.Add().Field = New DataCompositionField("State");
	Item.Fields.Items.Add().Field = New DataCompositionField("EventDate");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Overdue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDocument);
	
	// Color highlighting of the "Rejected" status
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Tách chọn bằng màu đối với trạng thái ""Đã hủy""';
							|ru = 'Выделение цветом состояния ""Отклонена""';
							|en = 'Highlighting the ""Rejected"" state'; fa = 'Highlighting the ""Rejected"" state';
							|it = 'Evidenziamento con il colore dello stato ""Respinta""';
							|pl = 'Wyróżnienie kolorem statusu ""Отклонена""';
							|tr = '""Reddedildi"" durumunun renkli olarak vurgulanması'");
	
	Item.Fields.Items.Add().Field = New DataCompositionField("State");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.IsRejected;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	Item.Appearance.SetParameterValue("Font", New Font(StyleFonts.NormalTextFont,,,,,,True));
	
	// Hiding the results of the application when accounting for settlements under contracts
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Ẩn tổng số theo giấy đề nghị trả hàng khi ghi nhận hạch toán theo hợp đồng';
							|ru = 'Скрытие итогов по заявке при учете расчетов по договорам';
							|en = 'Hide request totals while accounting settlements of the contracts'; fa = 'Hide request totals while accounting settlements of the contracts';
							|it = 'Nascondere i totali per una richiesta durante i calcoli per i contratti';
							|pl = 'Ukrycie wyników według zlecenia przy uwzględnieniu rozliczeń według kontraktów';
							|tr = 'Sözleşme hesapları muhasebeleştirilirken teklif toplamlarının gizlenmesi'");
	
	Item.Fields.Items.Add().Field = New DataCompositionField("PayAmount");
	Item.Fields.Items.Add().Field = New DataCompositionField("LatePaymentAmount");
	Item.Fields.Items.Add().Field = New DataCompositionField("AccountsPayableOfCompany");
	Item.Fields.Items.Add().Field = New DataCompositionField("DebtPercentage");
	Item.Fields.Items.Add().Field = New DataCompositionField("PayPercentage");
	Item.Fields.Items.Add().Field = New DataCompositionField("CustomerAccountsReceivable");
	Item.Fields.Items.Add().Field = New DataCompositionField("OrderShipmentPercentage");
	Item.Fields.Items.Add().Field = New DataCompositionField("AmountByShipment");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ARAPObjectSettings");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ARAPObjectSettings.ByOrders;
	
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
	ItemFilter.RightValue = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply;

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
	ItemFilter.RightValue = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply;

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

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.RequestForReturnOfGoodsFromCustomer.EmptyRef"));
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
		ShowValue(New CallbackDescription("ProcessBarcodesCompletion", ThisObject, New Structure("Data, Notification", Data, Notification)), ReferencesArrray[0]);
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
Procedure FillInListOfBusinessOperations()
	
	BusinessTransactionList.Clear();
	BusinessTransactionList.Add(Enums.BusinessTransactions.ReturnFromCommissionAgent);
	BusinessTransactionList.Add(Enums.BusinessTransactions.ReturnFromRetailCustomer);
	BusinessTransactionList.Add(Enums.BusinessTransactions.ReturnFromCustodian);
	
EndProcedure

&AtClient
Procedure CreateRequestForReturnOfGoodsFromClient(BusinessOperationIndex)

	BusinessOperation = BusinessTransactionList[BusinessOperationIndex].Value;

	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Basis", New Structure("BusinessOperation", BusinessOperation));
	OpenForm("Document.RequestForReturnOfGoodsFromCustomer.ObjectForm", ParametersStructure1, Items.List);

EndProcedure

&AtServerNoContext
Procedure FillSelectionSelectionListByServerState(ChoiceList, UseSimplifiedPaymentScheme)
	
	ChoiceList.Add("AllOpened", NStr("vi = 'Tất cả đã mở';
									|ru = 'Все открытые';
									|en = 'All open'; fa = 'All open';
									|it = 'Tutti aperti';
									|pl = 'Wszystkie otwarte';
									|tr = 'Tümü açık'"));
	ChoiceList.Add("AllPaymentPending", NStr("vi = 'Tất cả đang chờ thanh toán';
											|ru = 'Все ожидающие оплаты';
											|en = 'All pending payment'; fa = 'All pending payment';
											|it = 'Tutti in attesa di pagamento';
											|pl = 'Wszystkie oczekujące płatności';
											|tr = 'Bekleyen ödemelerin tümü'"));
	ChoiceList.Add("AllExecutionPending", NStr("vi = 'Tất cả đang chờ thực hiện';
												|ru = 'Все ожидающие исполнения';
												|en = 'Placed'; fa = 'جای‌گذاری‌شده';
												|it = 'Tutti in attesa di esecuzione';
												|pl = 'Wszystkie oczekujące wykonania';
												|tr = 'Bekleyen gerçekleştirmelerin tümü'"));
	
	ChoiceList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingApproval);
	ChoiceList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.ReadyForReturn);
	If Not UseSimplifiedPaymentScheme Then
		ChoiceList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingAdvanceOrReturnBeforeSupply);
	EndIf;
	ChoiceList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.ReadyForSupply_);
	ChoiceList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingPrepaymentOrReturnBeforeShipment);
	ChoiceList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingSupply);
	ChoiceList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.ReadyForShipment);
	ChoiceList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.DuringShipment);
	ChoiceList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingPaymentOrReturnAfterShipment);
	If GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompletePayment") 
		Or GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompleteShipment") Then
		ChoiceList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingExecution_);
	EndIf;
	ChoiceList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.Executed);
	ChoiceList.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.IsRejected);
	
EndProcedure

&AtServer
Procedure SetSelectionByStateServer()
	
	If State = "AllOpened" Then
		
		StateArray = New Array();
		StateArray.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.Executed);
		StateArray.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.IsRejected);
		
		CommonClientServer.SetDynamicListFilterItem(List, "State", StateArray, DataCompositionComparisonType.NotInList,, True);
		CommonClientServer.SetDynamicListFilterItem(List, "DeletionMark", False,,, True);
		
	ElsIf State = "AllPaymentPending" Then
		
		StateArray = New Array();
		StateArray.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingAdvanceOrReturnBeforeSupply);
		StateArray.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingPrepaymentOrReturnBeforeShipment);
		StateArray.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingPaymentOrReturnAfterShipment);
		
		CommonClientServer.SetDynamicListFilterItem(List, "State", StateArray, DataCompositionComparisonType.InList,, True);
		CommonClientServer.SetDynamicListFilterItem(List, "DeletionMark", False,,, True);
		
	ElsIf State = "AllExecutionPending" Then
		
		StateArray = New Array();
		StateArray.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingApproval);
		StateArray.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.ReadyForSupply_);
		StateArray.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingSupply);
		StateArray.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.ReadyForShipment);
		StateArray.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.DuringShipment);
		StateArray.Add(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingExecution_);
		
		CommonClientServer.SetDynamicListFilterItem(List, "State", StateArray, DataCompositionComparisonType.InList,, True);
		CommonClientServer.SetDynamicListFilterItem(List, "DeletionMark", False,,, True);
		
	Else
		
		CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
		CommonClientServer.SetDynamicListFilterItem(List, "DeletionMark",,,, False);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetItemsVisibility()
	
	ThereIsChangeAccess = AccessRight("Update", Metadata.Documents.RequestForReturnOfGoodsFromCustomer);
	UseAdvancedFeaturesOfSalesOrder = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	UseShipmentByRowsInSalesOrder = GetFunctionalOption("UseShipmentByRowsInSalesOrder");
	Items.ListSetTheStatusForShipment.Visible = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder")
													And Not UseShipmentByRowsInSalesOrder;
	
	Items.ListPayAmount.Visible             = UseAdvancedFeaturesOfSalesOrder;
	Items.ListPayPercentage.Visible           = UseAdvancedFeaturesOfSalesOrder;
	Items.ListAmountByShipment.Visible           = UseAdvancedFeaturesOfSalesOrder;
	Items.ListOrderShipmentPercentage.Visible         = UseAdvancedFeaturesOfSalesOrder;
	Items.ListAccountsPayableOfCompany.Visible                 = UseAdvancedFeaturesOfSalesOrder;
	Items.ListCustomerAccountsReceivable.Visible             = UseAdvancedFeaturesOfSalesOrder;
	Items.ListDebtPercentage.Visible            = UseAdvancedFeaturesOfSalesOrder;
	Items.FilterEventDate.Visible              = UseAdvancedFeaturesOfSalesOrder;
	Items.ListState.Visible               = UseAdvancedFeaturesOfSalesOrder;
	Items.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice.Visible = UseAdvancedFeaturesOfSalesOrder;
	
	SoftwareCommandsAreVisible = UseShipmentByRowsInSalesOrder And ThereIsChangeAccess;
	Items.ListShipByOrder.Visible = SoftwareCommandsAreVisible;
	Items.ListReserveAnOrder.Visible = SoftwareCommandsAreVisible;
	Items.ListReserveAsReceivedOrder.Visible = SoftwareCommandsAreVisible;
	Items.ListToSupplyOrder.Visible = SoftwareCommandsAreVisible;
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

#EndRegion

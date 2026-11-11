
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	List.Parameters.SetParameterValue("UpdateDate",               BegOfDay(CurrentSessionDate()));
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(Items.FilterDueDate_2.ChoiceList);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Manager", Manager, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Priority", Priority, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByRelevanceWhenCreatingOnServer(
		List,
		Relevance,
		Items.FilterDueDate_2.ChoiceList,
		EventDate,
		QuickFilterStructure);
	
	If ListSelectionsClientServer.YouNeedToSelectByStateWhenCreatingOnServer(State, QuickFilterStructure) Then
		SetSelectionByStateServer();
	EndIf;
	
	SetItemsVisibility();
	UseWarehouseManagemantSystemForGoodsIssue = GetFunctionalOption("UseWarehouseManagemantSystemForGoodsIssue");
	
	FillSelectionSelectionListByServerState(Items.FilterState.ChoiceList);

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.AttachableCommands
	

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.ListCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem

	TMCommonUse.CustomizePeripherals(ThisForm);
	
	UseStatuses = GetFunctionalOption("UseStatusesOfMaterialProviderOrders2_5");
	Items.GroupSetStatus.Visible = UseStatuses;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	EndIf;
	
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
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Manager  = Settings.Get("Manager");
	Priority = Settings.Get("Priority");
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Manager",
		Manager,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Manager));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Priority",
		Priority,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Priority));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterStateOnChange(Item)
	
	SetSelectionByStateServer();
	
EndProcedure

&AtClient
Procedure FilterStateClearing(Item, StandardProcessing)
	If State = Undefined Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure FilterDueDate_2OnChange(Item)

	ListSelectionsClientServer.WhenChangingRelevanceSelection(List, Relevance, EventDate);
	
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
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Manager",
		Manager,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Manager));
	
EndProcedure

&AtClient
Procedure ManagerClearing(Item, StandardProcessing)
	If Not ValueIsFilled(Manager) Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure FilterPriorityOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Priority",
		Priority,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Priority));
	
EndProcedure

&AtClient
Procedure FilterPriorityClearing(Item, StandardProcessing)
	If Not ValueIsFilled(Priority) Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure HyperlinkJournalOfAcceptanceForProcessingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Manager", Manager);
	
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	LogParameters.Insert("WorkplaceName",		 "DocumentsOfReceiptForTollingAll2_5");
	LogParameters.Insert("FormAssignmentKey",	 TollingSchemeClientServer.AssignmentKeyDocumentsOfAcceptanceForProcessing());
	LogParameters.Insert("JournalSynonym",			 NStr("vi = 'Chứng từ tiếp nhận vào gia công';
															|ru = 'Документы приема в переработку';
															|en = 'External subcontracting'; fa = 'پیمانکاری فرعی خارجی';
															|it = 'Documenti di accettazione in trasformazione';
															|pl = 'Dokumenty odbioru do przetwórstwa';
															|tr = 'İşlenecek kabul belgeleri'"));
	
	TMCommonUseClient.OpenLog(LogParameters);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MaterialProviderOrder2_5.ListForm.Item.List.Selection");
	
	If Field.Name = "OrderShipmentPercentage" Or Field.Name = "State" Then
		
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

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisForm);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListOnChange(Item)
	
	ProvisionInDocumentsClient.ListOnChange(ThisForm, "Document.MaterialProviderOrder2_5");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region PlugIns

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisForm, ExecutionParameters, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisForm, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisForm, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result)
	AttachableCommands.ExecuteCommand(ThisForm, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_CheckWhetherInventoryAllocationTaskIsCompletedForOrders()
	ProvisionInDocumentsClient.CheckWhetherInventoryAllocationTaskIsCompletedForOrders(ThisForm, Items.List);
EndProcedure

#EndRegion

&AtClient
Procedure SetTheStatusNotAgreed_5(Command)
	
	SetOrderStatus("NotApproved", NStr("vi = 'Không thống nhất';
										|ru = 'Не согласован';
										|en = 'Not approved'; fa = 'تأییدنشده';
										|it = 'Non concordato';
										|pl = 'Nieuzgodniony';
										|tr = 'Beklemede'"));
	
EndProcedure

&AtClient
Procedure SetTheStatusOfTheAgreed_3(Command)
	
	SetOrderStatus("Approved", NStr("vi = 'Đã thống nhất';
									|ru = 'Согласован';
									|en = 'Approved'; fa = 'تأییدشده';
									|it = 'Concordato';
									|pl = 'Uzgodniony';
									|tr = 'Onaylandı'"));
	
EndProcedure

&AtClient
Procedure SetTheStatusForShipment(Command)
	
	SetOrderStatus("ToShip", NStr("vi = 'Cần giao hàng';
									|ru = 'К отгрузке';
									|en = 'To ship'; fa = 'برای ارسال';
									|it = 'Da spedire';
									|pl = 'Do wysłania';
									|tr = 'Sevk edilecek'"));
	
EndProcedure

&AtClient
Procedure SetTheStatusToProduction(Command)
	
	SetOrderStatus("ToProduce", NStr("vi = 'Cần sản xuất';
									|ru = 'К производству';
									|en = 'For production'; fa = 'برای تولید';
									|it = 'Da produrre';
									|pl = 'Do produkcji';
									|tr = 'Üretilecek'"));
	
EndProcedure

&AtClient
Procedure SetTheClosedStatus(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MaterialProviderOrder2_5.ListForm.Command.SetTheClosedStatus");
	
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
					|tr = 'Sipariş listesinde seçili siparişlerin durumu ""%StatusName%"" olarak ayarlanacaktır. Devam edilsin mi?'");
	QueryText = StrReplace(QueryText, "%StatusName%", StatusName);
	
	NotificationParameters = New Structure("SelectedRows, StatusName, NewStatus", SelectedRows, StatusName, NewStatus);
	
	Notification = New CallbackDescription("SetOrderStatusCompletion", ThisObject, NotificationParameters);
	
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	
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
	Items.List, ProcessedItemsCount, SelectedRows.Count(), StatusName);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetItemsVisibility()
	
	ThereIsChangeAccess = AccessRight("Update", Metadata.Documents.MaterialProviderOrder2_5);
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
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisForm, "List.Date", Items.ListDate.Name);
	
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
	
	// The Ready to Provide status is displayed as Ready for Production
	Item = ListOfConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField("State");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SalesOrderStates.ReadyForSupply;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfMaterialProviderOrders.Approved;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Sẵn sàng cho sản xuất';
													|ru = 'Готов к производству';
													|en = 'Ready for production'; fa = 'Ready for production';
													|it = 'Pronto alla produzione';
													|pl = 'Gotowy do produkcji';
													|tr = 'Üretime hazır'"));
	
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
	Item.Appearance.SetParameterValue("Text", NStr("vi = '—';
													|ru = '—';
													|en = '—'; fa = '—';
													|it = '—';
													|pl = '—';
													|tr = '—'"));
	
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
		StateArray.Add(Enums.SalesOrderStates.ReadyForClosure);
		
		CommonClientServer.SetDynamicListFilterItem(List, "State", StateArray, DataCompositionComparisonType.InList,, True);
		CommonClientServer.SetDynamicListFilterItem(List, "DeletionMark", False,,, True);
		
	Else
		
		CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
		CommonClientServer.SetDynamicListFilterItem(List, "DeletionMark",,,, False);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure FillSelectionSelectionListByServerState(ChoiceList)
	
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
	
	ChoiceList.Add(Enums.SalesOrderStates.PendingApproval);
	ChoiceList.Add(Enums.SalesOrderStates.PendingAdvanceBeforeSupply);
	ChoiceList.Add(Enums.SalesOrderStates.ReadyForSupply);
	ChoiceList.Add(Enums.SalesOrderStates.PendingPrepaymentBeforeShipment);
	ChoiceList.Add(Enums.SalesOrderStates.PendingSupply);
	ChoiceList.Add(Enums.SalesOrderStates.ReadyToShip);
	ChoiceList.Add(Enums.SalesOrderStates.DuringShipment);
	ChoiceList.Add(Enums.SalesOrderStates.PendingPaymentAfterShipment);
	If GetFunctionalOption("DoNotCloseMaterialProviderOrdersWithoutCompletePayment2_5") 
	 Or GetFunctionalOption("DoNotCloseMaterialProviderOrdersWithoutCompleteFulfillment2_5") Then
		ChoiceList.Add(Enums.SalesOrderStates.ReadyForClosure);
	EndIf;
	ChoiceList.Add(Enums.SalesOrderStates.Closed);
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.MaterialProviderOrder2_5.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
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

#EndRegion

#EndRegion

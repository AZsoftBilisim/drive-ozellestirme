
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	UseReasonsForSalesOrderCancellations = GetFunctionalOption("UseReasonsForSalesOrderCancellations");
	UseShipmentByRowsInSalesOrder = GetFunctionalOption("UseShipmentByRowsInSalesOrder");
	
	Items.ListSetTheStatusForShipment.Visible = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder")
													And Not UseShipmentByRowsInSalesOrder;
	If Not UseShipmentByRowsInSalesOrder Then
		Items.ListSetTheStatusToExecute.Title = NStr("vi = 'Trong dự phòng';
													|ru = 'В резерве';
													|en = 'In reserve'; fa = 'در رزرو';
													|it = 'In riserva';
													|pl = 'W rezerwie';
													|tr = 'Rezervde'");
	EndIf;
	
	
	FillInListOfBusinessOperations();
	
	Items.GroupCreate.Visible = AccessRight("Insert", Metadata.Documents.RequestForReturnOfGoodsFromCustomer);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
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
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Manager  = Settings.Get("Manager");
	Priority = Settings.Get("Priority");
	
	CommonClientServer.SetDynamicListFilterItem(List, "Manager",  Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	CommonClientServer.SetDynamicListFilterItem(List, "Priority", Priority, DataCompositionComparisonType.Equal,, ValueIsFilled(Priority));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Manager",  Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));

EndProcedure

&AtClient
Procedure FilterPriorityOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Priority", Priority, DataCompositionComparisonType.Equal,, ValueIsFilled(Priority));

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

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
	
	QueryText = NStr("vi = 'Trong các đơn hàng đã chọn trong danh sách sẽ đặt trạng thái ""Đã thực hiện"". Tiếp tục?';
					|ru = 'У выделенных в списке заявок будет установлен статус ""Выполнена"". Продолжить?';
					|en = 'The ""Completed"" status will be set for the requests selected in the list. Continue?'; fa = 'The ""Completed"" status will be set for the requests selected in the list. Continue?';
					|it = 'Alle domande selezionate nell''elenco verrà assegnato lo stato ""Completata"". Continuare?';
					|pl = 'Dla wybranych w liście zleceń będzie ustawiony status  ""Выполнена"". Kontynuować?';
					|tr = 'Talep listesinde seçilenlerin durumu ""Gerçekleştirildi"" olarak ayarlanacaktır. Devam edilsin mi?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("ToSetTheStatusToCompletedCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ToSetTheStatusToCompletedCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "Executed", New Structure("ApplicationExecutionControl"));
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Đã thực hiện';
																												|ru = 'Выполнена';
																												|en = 'Completed'; fa = 'تکمیل‌شده';
																												|it = 'Completata';
																												|pl = 'Completed';
																												|tr = 'Gerçekleştirildi'"));

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
Procedure ProcessBarcodes(Data)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

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

#EndRegion

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result)
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

#EndRegion

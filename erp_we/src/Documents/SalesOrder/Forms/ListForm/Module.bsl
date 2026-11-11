
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	TMCommonUse.CustomizePeripherals(ThisForm);
	
	UseReasonsForSalesOrderCancellations = GetFunctionalOption("UseReasonsForSalesOrderCancellations");
	UseShipmentByRowsInSalesOrder = GetFunctionalOption("UseShipmentByRowsInSalesOrder");
	
	Items.SetTheStatusForShipment.Visible = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder")
													And Not UseShipmentByRowsInSalesOrder;
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
	
	
	
	If EventName = "Write_SalesOrder" Then
		// StandardSubsystems.AttachableCommands
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
		// End StandardSubsystems.AttachableCommands
	EndIf;
	
	If EventName = "ClosingOrders" Then
		Items.List.Refresh();
		
		// StandardSubsystems.AttachableCommands
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
		// End StandardSubsystems.AttachableCommands
	EndIf;
	
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
// End StandardSubsystems.AttachableCommands


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure SetTheStatusForApproval(Command)
	
	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If HighlightedLinks.Count() = 0 Then
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

	ShowQueryBox(New CallbackDescription("SetTheStatusForApprovalCompletion", ThisObject, New Structure("HighlightedLinks", HighlightedLinks)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusForApprovalCompletion(QuestionResult, AdditionalParameters) Export
    
    HighlightedLinks = AdditionalParameters.HighlightedLinks;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(HighlightedLinks, "NotApproved");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, HighlightedLinks.Count(), NStr("vi = 'Cần thống nhất';
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
	
	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If HighlightedLinks.Count() = 0 Then
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

	ShowQueryBox(New CallbackDescription("SetTheStatusToExecuteCompletion", ThisObject, New Structure("HighlightedLinks, StatusName", HighlightedLinks, StatusName)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusToExecuteCompletion(QuestionResult, AdditionalParameters) Export
    
    HighlightedLinks = AdditionalParameters.HighlightedLinks;
    StatusName = AdditionalParameters.StatusName;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(HighlightedLinks, "ToSupply");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, HighlightedLinks.Count(), StatusName);

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure SetTheStatusForShipment(Command)
	
	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If HighlightedLinks.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các đơn hàng đã chọn trong danh sách sẽ đặt trạng thái ""Cần giao hàng"". Tiếp tục?';
					|ru = 'У выделенных в списке заказов будет установлен статус ""К отгрузке"". Продолжить?';
					|en = 'Status ""To ship"" will be set for the orders selected in the list. Continue?'; fa = 'Status ""To ship"" will be set for the orders selected in the list. Continue?';
					|it = 'Per gli ordini selezionati nell''elenco verrà impostato lo stato ""Da spedire"". Continuare?';
					|pl = 'Dla wydzielonych w liście zamówień będzie ustawiony status ""К отгрузке"". Kontynuować?';
					|tr = 'Sipariş listesinde seçili siparişlerin durumu ""Sevk edilecek"" olarak ayarlanacaktır. Devam edilsin mi?'");
	Response = Undefined;

	ShowQueryBox(New CallbackDescription("SetTheStatusForShipmentCompletion", ThisObject, New Structure("HighlightedLinks", HighlightedLinks)), QueryText,QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetTheStatusForShipmentCompletion(QuestionResult, AdditionalParameters) Export
    
    HighlightedLinks = AdditionalParameters.HighlightedLinks;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(HighlightedLinks, "ToShip");
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, ProcessedItemsCount, HighlightedLinks.Count(), NStr("vi = 'Cần giao hàng';
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


#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.SalesOrder.EmptyRef"));
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

#EndRegion


#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	If Not Parameters.Property("FormAssignmentKey", PurposeUseKey)
	 Or Not ValueIsFilled(PurposeUseKey) Then
		PurposeUseKey = TollingSchemeClientServer.AssignmentKeyDocumentsOfAcceptanceForProcessing();
	EndIf;
	
	If Parameters.Property("References") Then
		References.LoadValues(Parameters.References);
	EndIf;
	
	CurrentPageName = Undefined;
	If Parameters.Property("CurrentPageName", CurrentPageName)
	   And ValueIsFilled(CurrentPageName) Then
		Items.Pages.CurrentPage = Items[CurrentPageName];
		CurrentItem = Items.Pages.CurrentPage;
	EndIf;
	
	UseReceiptForMultipleOrders =
		GetFunctionalOption("UseReceiptForMultipleOrders");
	
	RestoreSettings(Parameters);
	SetSelectionByOrganization();
	SetSelectionByWarehouse();
	
	FillInDocumentMetadata();
	ConfigureFormByRightsAndFunctionalOptions();
	
	UpdateTransfers    = True;
	UpdateReceipts = True;
	UpdatingReportsIsRequired      = True;
	UpdateReturns    = True;
	
	RefreshCurPageOnServer();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	// Initializing saved selections
	TransfersStatesOnChange(Undefined);
	ReceiptStatusWhenChanged(Undefined);
	ReportStateOnChange(Undefined);
	StatusReturnsOnChange(Undefined);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit
	   And PurposeUseKey <> "ToDoList"
	   And PurposeUseKey <> "InputOnBasis" Then
		ShouldSaveSettings();
	EndIf;
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
		
		Return;
		
	EndIf;
	// End Peripherals
	
	If EventName = "Write_MaterialProviderOrder2_5" Then
		
		UpdateTransfers    = True;
		UpdateReceipts = True;
		UpdatingReportsIsRequired      = True;
		
	ElsIf EventName = "Write_GoodsShipmentFromStorage" Then
		
		UpdateTransfers = True;
		
	ElsIf EventName = "Write_GoodsReceiptForStorage" Then
		
		UpdateReceipts = True;
		
	ElsIf EventName = "Write_ReportToMaterialProvider2_5" Then
		
		UpdatingReportsIsRequired = True;
		
	ElsIf EventName = "Write_GoodsShipmentFromStorage" Then
		
		UpdateReturns = True;
		
	ElsIf EventName = "Write_GoodsIssueNote" Then
		
		UpdateTransfers = True;
		
	ElsIf EventName = "Write_GoodsReceiptNote" Then
		
		UpdateReceipts = True;
		UpdateReturns    = True;
		
	ElsIf EventName = "Accept_FormOfCreatedDocuments" Then
		
		UpdateTransfers    = True;
		UpdateReceipts = True;
		UpdatingReportsIsRequired      = True;
		UpdateReturns    = True;
		
	ElsIf EventName = "ChangingPage_KRegistrationReception" Then
		
		CurrentItem = Items[Parameter];
		
	Else
		Return;
	EndIf;
	
	RefreshCurPage();
	
	If ValueIsFilled(References)
	   And ListTransferReferences.Count() = 0
	   And ListReceiptReferences.Count() = 0 Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If Parameters.Property("QuickFilterStructure") Then
		
		If Parameters.QuickFilterStructure.Property("Organization") Then
			Settings.Delete("Organization");
		EndIf;
		
		If Parameters.QuickFilterStructure.Property("Warehouse") Then
			Settings.Delete("Warehouse");
		EndIf;
		
		If Parameters.QuickFilterStructure.Property("Manager") Then
			Settings.Delete("Manager");
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	
	UpdateTransfers    = True;
	UpdateReceipts = True;
	UpdatingReportsIsRequired      = True;
	UpdateReturns    = True;
	
	RefreshCurPage();
	
EndProcedure

&AtClient
Procedure TransfersStatesOnChange(Item)
	
	RowFilter = New Structure;
	
	If ValueIsFilled(StatusOfTheTransferInvoice) Then
		RowFilter.Insert("InvoiceStatus", Number(StatusOfTheTransferInvoice));
	EndIf;
	
	If ValueIsFilled(GoodsIssueNoteState) Then
		RowFilter.Insert("GoodsIssueNoteState", Number(GoodsIssueNoteState));
	EndIf;
	
	Items.ListTransferReferences.RowFilter = New FixedStructure(RowFilter);
	
EndProcedure

&AtClient
Procedure ReceiptStatusWhenChanged(Item)
	
	RowFilter = New Structure;
	
	If ValueIsFilled(ReceiptInvoiceStatus) Then
		RowFilter.Insert("InvoiceStatus", Number(ReceiptInvoiceStatus));
	EndIf;
	
	If ValueIsFilled(GoodsReceiptNoteState) Then
		RowFilter.Insert("GoodsReceiptNoteState", Number(GoodsReceiptNoteState));
	EndIf;
	
	Items.ListReceiptReferences.RowFilter = New FixedStructure(RowFilter);
	
EndProcedure

&AtClient
Procedure ReportStateOnChange(Item)
	
	RowFilter = New Structure;
	
	If ValueIsFilled(ReportState) Then
		RowFilter.Insert("ReportState", Number(ReportState));
	EndIf;
	
	Items.ListReportReferences.RowFilter = New FixedStructure(RowFilter);
	
EndProcedure

&AtClient
Procedure StatusReturnsOnChange(Item)
	
	RowFilter = New Structure;
	
	If ValueIsFilled(StatusOfTheShipmentReturnOrder) Then
		RowFilter.Insert("GoodsIssueNoteState", Number(StatusOfTheShipmentReturnOrder));
	EndIf;
	
	Items.ListReferencesForRawMaterialReturn.RowFilter = New FixedStructure(RowFilter);
	
EndProcedure

&AtClient
Procedure AHyperlinkJournalProcessingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	TMCommonUseClient.OpenLog(LogParameters());
	
EndProcedure

&AtClient
Procedure ListOrdersSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure IssueOnTransferOrders(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices.Command.IssueOnTransferOrders");
	
	SelectedRows = Items.ListTransferReferences.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ListOfOrders_ = New Array;
	
	For Each String In SelectedRows Do
		
		FoundRow = Items.ListTransferReferences.RowData(String);
		
		StructureOfOrders = New Structure;
		StructureOfOrders.Insert("Ref",			 FoundRow.Ref);
		StructureOfOrders.Insert("InvoiceStatus", FoundRow.InvoiceStatus);
		StructureOfOrders.Insert("NoteState",	 FoundRow.GoodsIssueNoteState);
		
		ListOfOrders_.Add(StructureOfOrders);
		
	EndDo;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form",						 ThisObject);
	AdditionalParameters.Insert("ReferencesArrray",				 ListOfOrders_);
	AdditionalParameters.Insert("ByNotes",					 False);
	AdditionalParameters.Insert("Warehouse",						 Warehouse);
	AdditionalParameters.Insert("CreateSalesDocument",	 False);
	AdditionalParameters.Insert("TheDesignSettingsAreSaved", True);
	AdditionalParameters.Insert("NameOfFormCreatedDocuments",  "CommonForm.CreatedDocumentForm");
	FillInFormParametersOfCreatedDocuments(
		AdditionalParameters,
		PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5"));
	AdditionalParameters.Insert(
		"KeyOfSystemSettingsObject",
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices/CurrentData");
	AdditionalParameters.Insert(
		"ObjectKey",
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices/CurrentData");
	
	SalesClient.GenerateSetOfDocumentsChallenge(Undefined, AdditionalParameters);
	
	Notify("Write_GoodsShipmentFromStorage");
	
EndProcedure

&AtClient
Procedure ArrangeForTheShipmentOfTheTransfer(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices.Command.ArrangeForTheShipmentOfTheTransfer");
	
	SelectedRows = Items.ListTransferReferences.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ListOfOrders_ = New Array;
	
	For Each String In SelectedRows Do
		
		FoundRow = Items.ListTransferReferences.RowData(String);
		
		StructureOfOrders = New Structure;
		StructureOfOrders.Insert("Ref",			 FoundRow.Ref);
		StructureOfOrders.Insert("InvoiceStatus", FoundRow.InvoiceStatus);
		StructureOfOrders.Insert("NoteState",	 FoundRow.GoodsIssueNoteState);
		
		ListOfOrders_.Add(StructureOfOrders);
		
	EndDo;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form",						 ThisObject);
	AdditionalParameters.Insert("ReferencesArrray",				 ListOfOrders_);
	AdditionalParameters.Insert("ByNotes",					 True);
	AdditionalParameters.Insert("Warehouse",						 Warehouse);
	AdditionalParameters.Insert("CreateSalesDocument",	 False);
	AdditionalParameters.Insert("TheDesignSettingsAreSaved", True);
	AdditionalParameters.Insert("NameOfFormCreatedDocuments",  "CommonForm.CreatedDocumentForm");
	FillInFormParametersOfCreatedDocuments(
		AdditionalParameters,
		PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5"));
	AdditionalParameters.Insert(
		"KeyOfSystemSettingsObject",
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices/CurrentData");
	AdditionalParameters.Insert(
		"ObjectKey",
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices/CurrentData");
	
	SalesClient.GenerateSetOfDocumentsChallenge(Undefined, AdditionalParameters);
	
	Notify("Write_GoodsShipmentFromStorage");
	
EndProcedure

&AtClient
Procedure PlaceOrdersForReceipts(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices.Command.PlaceOrdersForReceipts");
	
	SelectedRows = Items.ListReceiptReferences.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ParametersOfCreatedDocuments = IssueInvoicesForOrdersOnServer(
										PutToTempStorage(SelectedRows, UUID));
	
	ProcessResultOfPaperwork(ParametersOfCreatedDocuments, "Write_GoodsReceiptForStorage");
	
EndProcedure

&AtClient
Procedure IssueOnReceiptOfReceipt(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices.Command.IssueOnReceiptOfReceipt");
	
	SelectedRows = Items.ListReceiptReferences.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ParametersOfCreatedDocuments = MakePurchasesOnServerByOrders(
										PutToTempStorage(SelectedRows, UUID));
	
	ProcessResultOfPaperwork(ParametersOfCreatedDocuments, "Write_GoodsReceiptForStorage");
	
EndProcedure

&AtClient
Procedure RegisterReports(Command)
	
	Var ErrorList;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices.Command.RegisterReports");
	
	SelectedRows = Items.ListReportReferences.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	GroupsOfOrders = New Structure;
	GroupsOfOrders.Insert("Orders",   New Structure("AnArrayOfOrders, Warehouses", New Array, New Array));
	GroupsOfOrders.Insert("Contracts", New Structure("AnArrayOfOrders, Warehouses", New Array, New Array));
	
	For Each RowID In SelectedRows Do
		
		CurrentRow = ListReportReferences.FindByID(RowID);
		
		If ValueIsFilled(CurrentRow.Ref) Then
			GroupsOfOrders.Orders.AnArrayOfOrders.Add(CurrentRow.Ref);
		Else
			
			GroupsOfOrders.Contracts.AnArrayOfOrders.Add(CurrentRow.Contract);
			
			If GroupsOfOrders.Contracts.Warehouses.Find(CurrentRow.Warehouse) = Undefined Then
				GroupsOfOrders.Contracts.Warehouses.Add(CurrentRow.Warehouse);
			EndIf;
			
		EndIf;
			
	EndDo;

	If GroupsOfOrders.Contracts.Warehouses.Count() > 1 Then
		
		CommonClientServer.AddUserError(
			ErrorList,
			"Object.ListReportReferences",
			NStr("vi = 'Không hỗ trợ tạo báo cáo <không có đơn hàng> theo nhiều kho.';
				|ru = 'Оформление отчета <без заказа> по нескольким складам не поддерживается.';
				|en = 'Registration of a report <without an order> by several warehouses is not supported.'; fa = 'Registration of a report <without an order> by several warehouses is not supported.';
				|it = 'Formalizzazione del report <senza ordine> non supportata per più magazzini.';
				|pl = 'Wygenerowanie raportu <bez zamówienia> dla kilku magazynów nie jest obsługiwane.';
				|tr = 'Birden fazla depoda <sipariş olmadan> raporlama desteklenmez.'"),
			Undefined);
		
	Else
		
		ReferenceArray = New Array;
		
		For Each GroupOfOrders In GroupsOfOrders Do
			
			ValueOfOrderGroup = GroupOfOrders.Value;
			
			AnArrayOfOrders = ValueOfOrderGroup.AnArrayOfOrders;
			
			If AnArrayOfOrders.Count() = 0 Then
				Continue;
			EndIf;
			
			PopulationFields = New Structure;
			If ValueOfOrderGroup.Warehouses.Count() > 0 Then
				PopulationFields.Insert("Warehouse", ValueOfOrderGroup.Warehouses[0]);
			EndIf;
			
			OrderData_3 = New Structure;
			OrderData_3.Insert("NameOfDocumentBeingProcessed", "ReportToMaterialProvider2_5");
			OrderData_3.Insert("PopulationFields",			PopulationFields);
			OrderData_3.Insert("AnArrayOfOrders",			AnArrayOfOrders);
			OrderData_3.Insert("KeyHeaderFields");
			OrderData_3.Insert("KeyFieldsOfHeaderAdapted");
			
			ReferenceArray.Add(OrderData_3);
			
		EndDo;
		
		FormParameters = New Structure;
		FillInFormParametersOfCreatedDocuments(
			FormParameters,
			// We pass the "type" of the issued document, and not its specific household. of operation.
			PredefinedValue("Enum.BusinessTransactions.ReportToMaterialProvider2_5"),
			PurposeUseKey);
		
		ParametersOfCreatedDocuments = GenerateReportsOnServer(
											ReferenceArray,
											FormParameters,
											ErrorList,
											"Object.ListReportReferences");
		
		If Not ParametersOfCreatedDocuments.Cancel Then
			InvoicesClient.OpenFormForCreatedDocuments(ParametersOfCreatedDocuments, ThisObject);
		EndIf;
		
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(ErrorList);
	
EndProcedure

&AtClient
Procedure ToArrangeForTheShipmentOfReturns(Command)
	
	Var ErrorList;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices.Command.IssueRefundsUponAcceptance");
	
	SelectedRows = Items.ListReferencesForRawMaterialReturn.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	WarehouseOrders = InvoicesClient.DataForProcessingOrders(
												ListReferencesForRawMaterialReturn,
												SelectedRows,
												"Warehouse",
												ErrorList,
												"Object.ListReferencesForRawMaterialReturn",
												MetadataOfDocuments);
	
	If ValueIsFilled(WarehouseOrders) Then
		
		FormParameters = New Structure;
		FillInFormParametersOfCreatedDocuments(
			FormParameters,
			PredefinedValue("Enum.BusinessTransactions.ReturnToMaterialProvider2_5"),
			PurposeUseKey);
		
		ParametersOfCreatedDocuments = InvoicesServerCall.IssueInvoicesForOrders_(
																WarehouseOrders,
																FormParameters,
																ErrorList,
																"Object.ListReferencesForRawMaterialReturn");
		
		InvoicesClient.OpenFormForCreatedDocuments(ParametersOfCreatedDocuments, ThisForm);
		
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(ErrorList);
	
EndProcedure

&AtClient
Procedure StateOfTransferExecution(Command)
	
	OpenDocumentExecutionStateReport("ListTransferReferences", ListTransferReferences);
	
EndProcedure

&AtClient
Procedure ReceiptExecutionState(Command)
	
	OpenDocumentExecutionStateReport("ListReceiptReferences", ListReceiptReferences);
	
EndProcedure

&AtClient
Procedure ProgressStatusReports(Command)
	
	OpenDocumentExecutionStateReport("ListReportReferences", ListReportReferences);
	
EndProcedure

&AtClient
Procedure UpdateTheTransferOrderList(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices.Command.UpdateTheTransferOrderList");
	
	UpdateListOfTransferRequestsOnServer();
	
EndProcedure

&AtClient
Procedure UpdateTheListOfOrdersForAdmission(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices.Command.UpdateTheListOfOrdersForAdmission");
	
	UpdateListOfReceiptRequestsOnServer();
	
EndProcedure

&AtClient
Procedure UpdateTheListOfOrdersForReports(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices.Command.UpdateTheListOfOrdersForReports");
	
	UpdateListOfLinksToReportsOnServer();
	
EndProcedure

&AtClient
Procedure UpdateTheListOfOrdersForTheReturnOfRawMaterials_3(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices.Command.UpdateTheListOfOrdersForTheReturnOfRawMaterials_3");
	
	UpdateListOfOrdersForReturnOfRawMaterialsOnServer();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region FormSettingsItem

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Documents have a high priority
	HighestPriority = Catalogs.Priorities.GetTopPriority();
	
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Chuyển giao có mức độ ưu tiên cao';
							|ru = 'Передача имеет высокий приоритет';
							|en = 'Transfer is in high priority'; fa = 'Transfer is in high priority';
							|it = 'La consegna ha una priorità elevata';
							|pl = 'Transmisja ma wysoki priorytet';
							|tr = 'Transfer yüksek önceliğe sahiptir'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListTransferReferences.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListTransferReferences.Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = HighestPriority;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.HighPriorityDocument);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Tiếp nhận có mức độ ưu tiên cao';
							|ru = 'Поступление имеет высокий приоритет';
							|en = 'Receipt is in high priority'; fa = 'Receipt is in high priority';
							|it = 'L''arrivo ha una priorità elevata';
							|pl = 'Wpłata ma wysoki priorytet';
							|tr = 'Kabul yüksek önceliğe sahiptir'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListReceiptReferences.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListReceiptReferences.Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = HighestPriority;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.HighPriorityDocument);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Báo cáo có mức độ ưu tiên cao';
							|ru = 'Отчет имеет высокий приоритет';
							|en = 'Report is in high priority'; fa = 'Report is in high priority';
							|it = 'Il report ha una priorità elevata';
							|pl = 'Raport ma wysoki priorytet';
							|tr = 'Rapor yüksek önceliğe sahiptir'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListReportReferences.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListReportReferences.Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = HighestPriority;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.HighPriorityDocument);
	
	// Documents have a low priority
	LowestPriority = Catalogs.Priorities.GetLowerPriority();
	
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Chuyển giao có mức độ ưu tiên thấp';
							|ru = 'Передача имеет низкий приоритет';
							|en = 'Transfer is in low priority'; fa = 'Transfer is in low priority';
							|it = 'La consegna ha una priorità bassa';
							|pl = 'Transmisja ma niski priorytet';
							|tr = 'Transfer düşük önceliğe sahiptir'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListTransferReferences.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListTransferReferences.Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = LowestPriority;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.LowDocumentPriority);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Tiếp nhận có mức độ ưu tiên thấp';
							|ru = 'Поступление имеет низкий приоритет';
							|en = 'Receipt is in low priority'; fa = 'Receipt is in low priority';
							|it = 'L''arrivo ha una priorità bassa';
							|pl = 'Wpłata ma niski priorytet';
							|tr = 'Kabul düşük önceliğe sahiptir'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListReceiptReferences.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListReceiptReferences.Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = LowestPriority;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.LowDocumentPriority);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Báo cáo có mức độ ưu tiên thấp';
							|ru = 'Отчет имеет низкий приоритет';
							|en = 'Report is in low priority'; fa = 'Report is in low priority';
							|it = 'Il report ha una priorità bassa';
							|pl = 'Raport ma niski priorytet';
							|tr = 'Rapor düşük önceliğe sahiptir'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListReportReferences.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListReportReferences.Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = LowestPriority;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.LowDocumentPriority);
	
	// Report to material provider
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListReportReferencesTypeOfOrder_.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListReportReferences.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có đơn hàng>';
													|ru = '<без заказа>';
													|en = '<without order>'; fa = '<بدون سفارش>';
													|it = '<senza ordine>';
													|pl = '<bez zamówienia>';
													|tr = '<sipariş verilmeden>.'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListReportReferencesContract.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListReportReferences.Contract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có hợp đồng>';
													|ru = '<без договора>';
													|en = '<without contract>'; fa = '<بدون قرارداد>';
													|it = '<senza contratto>';
													|pl = '<bez kontraktu>';
													|tr = '<anlaşma olmadan>.'"));
	
	//
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(
		ThisObject, "ListTransferReferences.Date", "ListTransferReferencesDate");
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(
		ThisObject, "ListReceiptReferences.Date", "ListReceiptReferencesDate");
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(
		ThisObject, "ListReportReferences.Date", "ListReportReferencesDate");
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(
		ThisObject, "ListReferencesForRawMaterialReturn.Date", "ListReferencesForRawMaterialReturnDate");
	
EndProcedure

&AtServer
Procedure ConfigureFormByRightsAndFunctionalOptions()
	
	If Not AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus) Then
		
		Items.AListOfOrdersForTheTransferExecutionState.Visible    = False;
		Items.ListReferencesForRegistrationExecutionState.Visible  = False;
		Items.AListOfOrdersOnTheReportingStatusOfImplementation.Visible      = False;
		
	EndIf;
	
	If Not GetFunctionalOption("UseWarehouseManagemantSystemForGoodsIssue")
	 Or Not AccessRight("Read", Metadata.AccumulationRegisters.GoodsForIssue) Then
	 	
		Items.ListOfTransferOrdersToIssueByOrder.Title = NStr("vi = 'Lập chứng từ';
																|ru = 'Оформить';
																|en = 'Register'; fa = 'ثبات';
																|it = 'Formalizzare';
																|pl = 'Sporządź';
																|tr = 'Düzenle'");
		Items.Move(Items.TransferCommandGroup, Items.TransferStatusGroup);
		
		InvoicesServer.FillInInvoiceStates(Items.StatusOfTheTransferInvoice.ChoiceList, True);
		
		Items.GoodsIssueNoteState.Visible                          = False;
		Items.AListOfOrdersForATransferToArrangeForTheShipment.Visible     = False;
		Items.AListOfTheOrderToTransferTheOrderStatus.Visible        = False;
		Items.RawMaterialReturnsPage.Visible                              = False;
		
	Else
		
		InvoicesServer.FillInInvoiceStates(Items.StatusOfTheTransferInvoice.ChoiceList);
		InvoicesServer.FillOrderStates(Items.GoodsIssueNoteState.ChoiceList);
		InvoicesServer.FillOrderStates(Items.StatusOfTheShipmentReturnOrder.ChoiceList, True);
		
	EndIf;
	
	If Not GetFunctionalOption("UseWarehouseManagemantSystemForGoodsReceipt")
	 Or Not AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive) Then
	 	
		Items.ListOfReceiptOrdersIssueByOrder.Title = NStr("vi = 'Lập chứng từ';
															|ru = 'Оформить';
															|en = 'Register'; fa = 'ثبات';
															|it = 'Formalizzare';
															|pl = 'Sporządź';
															|tr = 'Düzenle'");
		Items.Move(Items.ReceiptTeamGroup, Items.ReceiptStatusGroup);
		
		InvoicesServer.FillInInvoiceStates(Items.ReceiptInvoiceStatus.ChoiceList, True);
		
		Items.GoodsReceiptNoteState.Visible                           = False;
		Items.ListOfOrdersForReceiptToIssueOnAcceptance.Visible   = False;
		Items.AListOfOrdersOnReceiptOfTheOrderStatus.Visible     = False;
		
	Else
		
		InvoicesServer.FillInInvoiceStates(Items.ReceiptInvoiceStatus.ChoiceList);
		InvoicesServer.FillOrderStates(Items.GoodsReceiptNoteState.ChoiceList);
		
	EndIf;
	
	ViewingOrders = AccessRight("View", Metadata.Documents.MaterialProviderOrder2_5);
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences)
	 Or Not AccessRight("View", Metadata.Documents.GoodsShipmentFromStorage)
	 Or Not ViewingOrders Then
		
		Items.ProductTransferPage.Visible                          = False;
		
	ElsIf Not AccessRight("Insert", Metadata.Documents.GoodsShipmentFromStorage) Then
		
		Items.ListOfTransferOrdersToIssueByOrder.Enabled    = False;
		Items.AListOfOrdersForATransferToArrangeForTheShipment.Enabled   = False;
		
	EndIf;
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.PurchaseOrders)
	 Or Not AccessRight("View", Metadata.Documents.GoodsReceiptForStorage)
	 Or Not ViewingOrders Then
		
		Items.RawMaterialReceiptPage.Visible                           = False;
		
	ElsIf Not AccessRight("Insert", Metadata.Documents.GoodsReceiptForStorage) Then
		
		Items.ListOfReceiptOrdersIssueByOrder.Enabled = False;
		Items.ListOfOrdersForReceiptToIssueOnAcceptance.Enabled = False;
		
	EndIf;
	
	If Not AccessRight("Read", Metadata.Documents.ReportToMaterialProvider2_5)
	 Or Not ViewingOrders Then
		
		Items.ReportsPage.Visible                                     = False;
		
	Else
		
		ChoiceList = Items.ReportState.ChoiceList;
		ChoiceList.Clear();
		ChoiceList.Add("1", NStr("vi = 'Tạo báo cáo';
								|ru = 'Создать отчет';
								|en = 'Create a report'; fa = 'Create a report';
								|it = 'Creare un report';
								|pl = 'Utwórz raport';
								|tr = 'Rapor oluştur'"),    False, PictureLib.CreateInvoice);
		ChoiceList.Add("2", NStr("vi = 'Hoàn thành báo cáo';
								|ru = 'Дооформить отчет';
								|en = 'Finish creating the report'; fa = 'Finish creating the report';
								|it = 'Completare il report';
								|pl = 'Dokończyć raport';
								|tr = 'Raporu tamamlayın'"), False, PictureLib.CreateInvoiceOnUninvoicedDeliveries);
		
		If Not AccessRight("Insert", Metadata.Documents.ReportToMaterialProvider2_5) Then
			Items.ListOfOrdersForReports.Enabled            = False;
		EndIf;
		
	EndIf;
	
	If Not AccessRight("View", Metadata.Documents.GoodsShipmentFromStorage) Then
		
		Items.RawMaterialReturnsPage.Visible                              = False;
		
	ElsIf Not AccessRight("Insert", Metadata.Documents.GoodsShipmentFromStorage) Then
		
		Items.AListOfOrdersForTheReturnOfRawMaterialsToMake.Enabled         = False;
		
	EndIf;
	
	If ValueIsFilled(References) Then
		
		AutoTitle = False;
		Title = StrTemplate(
						NStr("vi = 'Chứng từ tiếp nhận vào gia công (%1) (cần lập)';
							|ru = 'Документы приема в переработку (%1) (к оформлению)';
							|en = 'External subcontracting — Unregistered documents (%1)'; fa = 'External subcontracting — Unregistered documents (%1)';
							|it = 'Documenti di accettazione in trasformazione (%1) (da formalizzare)';
							|pl = 'Dokumenty odbioru do przetwórstwa (%1) (do rejestracji)';
							|tr = 'İşlenecek kabul belgeleri (%1) (düzenleme için)'"),
						Lower(Items.Pages.CurrentPage.Title));
		
		Items.GroupFilters.Visible                           = False;
		Items.Pages.PagesRepresentation                      = FormPagesRepresentation.None;
		
		Items.StatusOfTheTransferInvoice.TitleLocation    = FormItemTitleLocation.Top;
		Items.GoodsIssueNoteState.TitleLocation     = FormItemTitleLocation.Top;
		Items.ReceiptInvoiceStatus.TitleLocation = FormItemTitleLocation.Top;
		Items.GoodsReceiptNoteState.TitleLocation      = FormItemTitleLocation.Top;
		
		Items.AListOfOrdersForATransferCertificate.Visible    = True;
		Items.AListOfOrdersForAdmissionHelp.Visible = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region RegistrationOfInvoice

&AtServer
Function IssueInvoicesForOrdersOnServer(AddressSelectedLines)
	
	ListOfOrders_ = ListReceiptReferences.Unload(New Array);
	
	RowsSelected = GetFromTempStorage(AddressSelectedLines);
	For Each RowID In RowsSelected Do
		FillPropertyValues(
			ListOfOrders_.Add(),
			ListReceiptReferences.FindByID(RowID));
	EndDo;
	
	FormParameters = New Structure;
	ErrorList   = Undefined;
	
	DocumentsByTypesOfInvoices = OrderTablesSeparatedByKeyFields(ListOfOrders_, ErrorList);
	NumberOfTables = DocumentsByTypesOfInvoices.Count();
	
	If NumberOfTables > 0 Then
		
		FormParameters = ?(NumberOfTables = 1,
							IssueInvoiceAccordingToTable(DocumentsByTypesOfInvoices),
							CreateInvoicesAccordingToTables(DocumentsByTypesOfInvoices, ErrorList));
		
	Else
		
		CommonClientServer.AddUserError(
			ErrorList, 
			"Object.ListReceiptReferences",
			NStr("vi = 'Không có chứng từ đã được lựa chọn có thể được ban hành theo đơn đặt hàng.';
				|ru = 'Не выбрано ни одного документа, который можно было бы оформить по заказам';
				|en = 'No documents that can be registered under orders are selected'; fa = 'No documents that can be registered under orders are selected';
				|it = 'Non è selezionato alcun documento formalizzabile in base agli ordini';
				|pl = 'Nie wybrano żadnego dokumentu, który można byłoby utworzyć wg zamówień';
				|tr = 'Sipariş üzerine oluşturulacak bir belge seçilmedi'"));
		
	EndIf;
	
	FormParameters.Insert("ErrorList", ErrorList);
	
	Return FormParameters;
	
EndFunction

&AtServer
Function IssueInvoiceAccordingToTable(DocumentsByTypesOfInvoices)
	
	FormSettings = New Structure;
	
	MetaOfDocument = Metadata.Documents.GoodsReceiptForStorage;
	DocumentName  = MetaOfDocument.Name;
	
	Orders = DocumentsByTypesOfInvoices[0].UnloadColumn("Ref");
	
	HeaderAttributes = New Structure;
	If Not PurchasesServerCall.GenerateReceiptFillingData(Orders, DocumentName, HeaderAttributes) Then
		Return FormSettings;
	EndIf;
	
	CreatedDocuments = New Array;
	CreatedDocuments.Add(Undefined);
	
	FormParameters = New Structure;
	FormParameters.Insert("WarehouseForReceipt",  Undefined);
	FormParameters.Insert("HeaderAttributes",	 HeaderAttributes);
	FormParameters.Insert("DocumentBasis", Orders);
	
	FormSettings.Insert("FormName", "Document.GoodsReceiptForStorage.ObjectForm");
	FormSettings.Insert("Parameters", New Structure);
	FormSettings.Parameters.Insert("Basis",			FormParameters);
	FormSettings.Parameters.Insert("CreatedDocuments", CreatedDocuments);
	
	Return FormSettings;
	
EndFunction

&AtServer
Function CreateInvoicesAccordingToTables(DocumentsByTypesOfInvoices, ErrorList)
	
	ParametersStructure = New Structure;
	
	MetaOfDocument = Metadata.Documents.GoodsReceiptForStorage;
	DocumentName	 = MetaOfDocument.Name;
	DocumentSynonym = MetaOfDocument.Synonym;
	
	CreatedDocuments = New Array;
	
	For Each Table In DocumentsByTypesOfInvoices Do
		
		Orders = Table.UnloadColumn("Ref");
		
		HeaderAttributes = New Structure;
		If Not PurchasesServerCall.GenerateReceiptFillingData(Orders, DocumentName, HeaderAttributes) Then
			Return ParametersStructure;
		EndIf;
		
		FillingData = New Structure;
		FillingData.Insert("WarehouseForReceipt",  Undefined);
		FillingData.Insert("HeaderAttributes",	   HeaderAttributes);
		FillingData.Insert("DocumentBasis", Orders);
		
		DocumentObject = Documents.GoodsReceiptForStorage.CreateDocument();
		DocumentObject.Fill(FillingData);
		DocumentObject.Date = CurrentSessionDate();
		
		DocumentObject.Write(DocumentWriteMode.Write);
		
		UserWorkHistory.Add(DocumentObject.Ref);
		CreatedDocuments.Add(New Structure("Document", DocumentObject.Ref));
		
		If DocumentObject.CheckFilling() Then
			Try
				DocumentObject.Write(DocumentWriteMode.Posting);
			Except
				CommonClientServer.AddUserError(
					ErrorList,
					"Object.ListReferencesForRegistration",
					StrTemplate(NStr("vi = 'Không thể kết chuyển chứng từ %1';
									|ru = 'Не удалось провести документ %1';
									|en = 'Cannot post the %1 document'; fa = 'Cannot post the %1 document';
									|it = 'Non è stato possibile pubblicare il documento %1';
									|pl = 'Nie udało się zatwierdzić dokumentu %1';
									|tr = 'Belge kaydedilemedi %1'"), DocumentObject));
			EndTry;
		EndIf;
		
	EndDo;
	
	ParametersStructure.Insert("Parameters", New Structure("CreatedDocuments", CreatedDocuments));
	ParametersStructure.Insert("FormName", "CommonForm.CreatedDocumentForm");
	FillInFormParametersOfCreatedDocuments(
		ParametersStructure.Parameters,
		PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5"));
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Function OrderTablesSeparatedByKeyFields(ListOfOrders_, ErrorList)
	
	KeyFields = "Partner,Counterparty,Contract,Organization,Currency,Department";
	
	StructureKeyFields = New Structure(KeyFields);
	StructureKeyFields.Insert("InvoiceStatus");
	
	SplitTable = Undefined;
	SeparationFields	   = "Ref,Warehouse,BusinessOperation,InvoiceStatus";
	
	ArrayOfTables = New Array;
	
	ListOfOrders_.Sort("Ref, Warehouse, InvoiceStatus");
	
	For Each String In ListOfOrders_ Do
		
		ErrorText = "";
		
		If String.InvoiceStatus = 0 Then
			
			ErrorText = NStr("vi = 'Đối với lệnh %1 đã tạo hóa đơn.';
							|ru = 'Для распоряжения %1 уже создана накладная.';
							|en = 'An invoice has already been created for the %1 reference.'; fa = 'An invoice has already been created for the %1 reference.';
							|it = 'Per la disposizione %1 è già creata una bolla.';
							|pl = 'Dla zamówienia %1 jest już utworzony list przewozowy.';
							|tr = '%1 emri için bir irsaliye zaten oluşturuldu.'");
			
		ElsIf String.InvoiceStatus = 4 Then
			
			ErrorText =
				NStr("vi = 'Lệnh %1 là hóa đơn. Không thể phát hành hóa đơn cho hóa đơn.';
					|ru = 'Распоряжение %1 является накладной. Невозможно оформить накладную по накладной.';
					|en = 'Reference %1 is an invoice. Cannot register an invoice for the invoice.'; fa = 'Reference %1 is an invoice. Cannot register an invoice for the invoice.';
					|it = 'La disposizione %1 è una fattura. Impossibile emettere una fattura per fattura.';
					|pl = 'Zamówienie %1 jest listem przewozowym. Niemożliwe jest sporządzenie listu przewozowego wg listu przewozowego.';
					|tr = '%1 emri bir irsaliyeye denk gelir. Bir irsaliye üzerine düzenlenme yapmak mümkün değildir.'");
			
		EndIf;
		
		If ValueIsFilled(ErrorText) Then
			
			CommonClientServer.AddUserError(
				ErrorList, "Object.ListReceiptReferences", StrTemplate(ErrorText, String.Ref));
			
			Continue;
			
		EndIf;
		
		If SplitTable = Undefined 
		 Or Not UseReceiptForMultipleOrders
		 Or Not TMCommonUseClientServer.StructuresAreEqual(StructureKeyFields, String, KeyFields) Then
			
			SplitTable = ListOfOrders_.CopyColumns(SeparationFields);
			ArrayOfTables.Add(SplitTable);
			
			FillPropertyValues(StructureKeyFields, String);
			
		EndIf;
		
		FillPropertyValues(SplitTable.Add(), String);
		
	EndDo;
	
	Return ArrayOfTables;
	
EndFunction

#EndRegion

#Region ExecutionByOrders

&AtServer
Function MakePurchasesOnServerByOrders(AddressSelectedLines)
	
	ListOfOrders_ = ReceiptOrderTemplate();
	ListOfOrders_.Columns.Add("ThereAreRegisteredReceipts", New TypeDescription("Boolean"));
	
	RowsSelected = GetFromTempStorage(AddressSelectedLines);
	For Each RowID In RowsSelected Do
		
		FillPropertyValues(
			ListOfOrders_.Add(),
			ListReceiptReferences.FindByID(RowID));
			
	EndDo;
	
	FormParameters = New Structure;
	ErrorList   = Undefined;
	
	DocumentsByTypesOfInvoices =
		TablesOfAcquisitionsDividedByKeyFieldsForOrders(ListOfOrders_, ErrorList);
	NumberOfTables = DocumentsByTypesOfInvoices.Count();
	
	If NumberOfTables > 0 Then
		
		FormParameters = ?(NumberOfTables = 1,
							MakeAcquisitionUsingOrderControlTable(DocumentsByTypesOfInvoices),
							IssueNumberOfAcquisitionsAccordingToOrderControlTables(DocumentsByTypesOfInvoices, ErrorList));
		
	Else
		
		CommonClientServer.AddUserError(
			ErrorList, 
			"Object.ListReceiptReferences",
			NStr("vi = 'Không thể chọn một chứng từ nào mà có thể tạo theo đơn hàng';
				|ru = 'Не выбрано ни одного документа, который можно было бы оформить по заказам';
				|en = 'No documents that can be registered under orders are selected'; fa = 'No documents that can be registered under orders are selected';
				|it = 'Non è selezionato alcun documento formalizzabile in base agli ordini';
				|pl = 'Nie wybrano żadnego dokumentu, który można byłoby utworzyć wg zamówień';
				|tr = 'Sipariş üzerine oluşturulacak bir belge seçilmedi'"));
		
	EndIf;
	
	FormParameters.Insert("ErrorList", ErrorList);
	
	Return FormParameters;
	
EndFunction


// Receipt order template.
// 
// Returns:
//  ValueTable - with columns:
//   * Ref - DocumentRef.GoodsReceiptForStorage -
//
&AtServer
Function ReceiptOrderTemplate()
	
	Return ListReceiptReferences.Unload(New Array);
	
EndFunction

// Makes the purchase according to the order control table.
// 
// Parameters:
//  DocumentsByTypesOfInvoices - Array of See ReceiptOrderTemplate
// 
// Returns:
//  Structure - Make An Acquisition Using The Order Control Table:
//   * Parameters - Structure - Contains:
//     ** Basis - Structure - Contains:
//         *** DocumentBasis - DocumentRef.GoodsReceiptForStorage -
//         *** WarehouseForReceipt  - CatalogRef.Warehouses -
//         *** FillByWarehouseDocument - Boolean -
//     ** FillByWarehouseDocument - Boolean -
//   * FormName - String -
//
&AtServer
Function MakeAcquisitionUsingOrderControlTable(DocumentsByTypesOfInvoices)
	
	FormSettings = New Structure;
	FormParameters = New Structure;
	
	MetaOfDocument = Metadata.Documents.GoodsReceiptForStorage;
	DocumentName  = MetaOfDocument.Name;
	
	DocumentsTable = DocumentsByTypesOfInvoices[0];
	SelectedRow  = DocumentsTable[0];
	Orders			  = DocumentsTable.UnloadColumn("Ref");
	
	FullNameOfOrder = ?(SelectedRow.Ref = Undefined,
								"", 
								SelectedRow.Ref.Metadata().FullName());
								
	InvoiceFullName    = Metadata.Documents.GoodsReceiptForStorage.FullName();
	
	If FullNameOfOrder = InvoiceFullName Then
		
		CorrectiveDocument = DocumentCorrection.LastCorrectiveDocument(SelectedRow.Ref);
		
		If CorrectiveDocument = Undefined Then
			FormParameters.Insert("Key",              SelectedRow.Ref);
			FormParameters.Insert("FillByWarehouseDocument", True);
		Else
			FormParameters.Insert("ThereIsFix", True);
			FormParameters.Insert("Key",            CorrectiveDocument.Ref);
			FormParameters.Insert("FormName",        "Document.GoodsReceiptForStorage.ObjectForm");
		EndIf;
		
		NameOfRegistrationForm = "Document.GoodsReceiptForStorage.Form.DocumentForm";
	
	ElsIf SelectedRow.ThereAreRegisteredReceipts Then
		
		HeaderAttributes = New Structure;
		If Not PurchasesServerCall.GenerateReceiptFillingData(Orders, DocumentName, HeaderAttributes) Then
			Return FormSettings;
		EndIf;
		
		RenewalFormSettings = InvoicesServer.SettingsOfInvoiceReissueForm();
		RenewalFormSettings.NameOfTheInvoiceForm   = "Document.GoodsReceiptForStorage.ObjectForm";
		RenewalFormSettings.ShippingSlip = False;
		RenewalFormSettings.ReceivingDocument  = True;
		RenewalFormSettings.Title = NStr("vi = 'Cấp lại chứng từ cho các đơn hàng đã chọn';
										|ru = 'Переоформление документов по выбранным распоряжениям';
										|en = 'Reregister documents for the selected references'; fa = 'Reregister documents for the selected references';
										|it = 'La formalizzazione sostitutiva dei documenti per disposizioni selezionate';
										|pl = 'Ponowna rejestracja dokumentów wg wybranych zamówień';
										|tr = 'Seçilen emirler için belgelerin yeniden düzenlenmesi'");
		
		FormParameters.Insert("FormSettings", RenewalFormSettings);
		FormParameters.Insert("Orders",		  Orders);
		FormParameters.Insert("HeaderAttributes", HeaderAttributes);
		FormParameters.Insert("Warehouse",		  SelectedRow.Warehouse);
		
		NameOfRegistrationForm = "CommonForm.ReregisterInvoicesByReferences";
		
	Else
		
		FillingData = New Structure;
		FillingData.Insert("DocumentBasis", SelectedRow.Ref);
		FillingData.Insert("WarehouseForReceipt",  SelectedRow.Warehouse);
		FillingData.Insert("FillByWarehouseDocument", True);
		
		FormParameters = New Structure;
		FormParameters.Insert("Basis",		 FillingData);
		FormParameters.Insert("FillByWarehouseDocument", True);
		
		NameOfRegistrationForm = "Document.GoodsReceiptForStorage.ObjectForm";
		
	EndIf;
	
	CreatedDocuments = New Array;
	CreatedDocuments.Add(Undefined);
	
	FormParameters.Insert("CreatedDocuments", CreatedDocuments);
	
	FormSettings.Insert("Parameters", FormParameters);
	FormSettings.Insert("FormName",  NameOfRegistrationForm);
	
	Return FormSettings;
	
EndFunction

&AtServer
Function IssueNumberOfAcquisitionsAccordingToOrderControlTables(DocumentsByTypesOfInvoices, ErrorList)
	
	ParametersStructure = New Structure;
	
	MetaOfDocument = Metadata.Documents.GoodsReceiptForStorage;
	DocumentName	 = MetaOfDocument.Name;
	DocumentSynonym = MetaOfDocument.Synonym;
	
	CreatedDocuments = New Array;
	
	For Each Table In DocumentsByTypesOfInvoices Do
		
		Orders = Table.UnloadColumn("Ref");
		
		HeaderAttributes = New Structure;
		If Not PurchasesServerCall.GenerateReceiptFillingData(Orders, DocumentName, HeaderAttributes) Then
			Return ParametersStructure;
		EndIf;
		
		FillingData = New Structure;
		FillingData.Insert("DocumentBasis", Orders);
		FillingData.Insert("HeaderAttributes",    HeaderAttributes);
		FillingData.Insert("WarehouseForReceipt",  Table[0].Warehouse);
		FillingData.Insert("FillByWarehouseDocument", True);
		
		DocumentObject = Documents.GoodsReceiptForStorage.CreateDocument();
		DocumentObject.Fill(FillingData);
		DocumentObject.Date = CurrentSessionDate();
		
		DocumentObject.Write(DocumentWriteMode.Write);
		
		UserWorkHistory.Add(DocumentObject.Ref);
		CreatedDocuments.Add(New Structure("Document", DocumentObject.Ref));
		
		If DocumentObject.CheckFilling() Then
			Try
				DocumentObject.Write(DocumentWriteMode.Posting);
			Except
				CommonClientServer.AddUserError(
					ErrorList,
					"Object.ListReferencesForRegistration",
					StrTemplate(NStr("vi = 'Không thể kết chuyển chứng từ %1';
									|ru = 'Не удалось провести документ %1';
									|en = 'Cannot post the %1 document'; fa = 'Cannot post the %1 document';
									|it = 'Non è stato possibile pubblicare il documento %1';
									|pl = 'Nie udało się zatwierdzić dokumentu %1';
									|tr = 'Belge kaydedilemedi %1'"), DocumentObject));
			EndTry;
		EndIf;
		
	EndDo;
	
	ParametersStructure.Insert("Parameters", New Structure("CreatedDocuments", CreatedDocuments));
	ParametersStructure.Insert("FormName", "CommonForm.CreatedDocumentForm");
	FillInFormParametersOfCreatedDocuments(
		ParametersStructure.Parameters,
		PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5"));
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Function TablesOfAcquisitionsDividedByKeyFieldsForOrders(ListOfOrders_, ErrorList) 
	
	KeyFields = "Partner,Counterparty,Contract,Organization,SalesOpportunity,Currency,Department,BusinessOperation";
	
	CurrentKeys = New Structure(KeyFields);
	CurrentKeys.Insert("GoodsReceiptNoteState");
	CurrentKeys.Insert("ThereAreRegisteredReceipts");
	
	SplitTable = Undefined;
	SeparationFields	   = "Ref, Warehouse, BusinessOperation, GoodsReceiptNoteState, ThereAreRegisteredReceipts";

	ArrayOfTables = New Array;
	
	ListOfOrders_.Sort("Ref, Warehouse, GoodsReceiptNoteState");
	
	ThereAreRegisteredReceipts = False;
	
	For Each String In ListOfOrders_ Do
		
		If String.ShippingSlip And String.ReceivingDocument Then
			
			ByNotes = NStr("vi = 'theo giao hàng (tiếp nhận)';
							|ru = 'по отгрузке (приемке)';
							|en = 'by shipment (receiving)'; fa = 'by shipment (receiving)';
							|it = 'in base alla spedizione (accettazione)';
							|pl = 'wg wysyłki (odbioru)';
							|tr = 'sevkiyata göre (tedarik)'");
			
		ElsIf String.ShippingSlip Then
			
			ByNotes = NStr("vi = 'theo giao hàng';
							|ru = 'по отгрузке';
							|en = 'by shipment'; fa = 'by shipment';
							|it = 'per la spedizione';
							|pl = 'wg wysyłki';
							|tr = 'sevkiyata göre'");
			
		ElsIf String.ReceivingDocument Then
			
			ByNotes = NStr("vi = 'theo tiếp nhận';
							|ru = 'по приемке';
							|en = 'by receipt'; fa = 'by receipt';
							|it = 'accettazione';
							|pl = 'wg odbioru';
							|tr = 'tedariğe göre'");
			
		EndIf;
		
		ErrorText = "";
		
		If (String.GoodsIssueNoteState = 0 Or Not String.ShippingSlip)
		   And (String.GoodsReceiptNoteState = 0 Or Not String.ReceivingDocument) Then
			
			ErrorText = StrTemplate(NStr("vi = 'Đối với lệnh %1, không thể tạo hóa đơn %2,
												|bởi vì lệnh tương ứng với hóa đơn.';
												|ru = 'Для распоряжения %1 невозможно оформить накладную %2,
												|т.к. ордера соответствуют накладным.';
												|en = 'Cannot register the %2 invoice for the %1 reference 
												| as notes correspond to the invoices.'; fa = 'Cannot register the %2 invoice for the %1 reference 
												| as notes correspond to the invoices.';
												|it = 'Per la disposizione %1 non è possibile formalizzare la bolla %2,
												| poiché i mandati corrispondono alle bolle.';
												|pl = 'Dla zamówienia %1 niemożliwe jest utworzenie listu przewozowego %2,
												| ponieważ zlecenia odpowiadają listom przewozowym.';
												|tr = 'Emirler irsaliyelere karşılık geldiğinden,
												| %1 emri için bir %2 irsaliye düzenlemek mümkün değildir.'"), String.Ref, ByNotes);
			
		ElsIf (String.GoodsIssueNoteState = 1 Or Not String.ShippingSlip)
				And (String.GoodsReceiptNoteState = 1 Or Not String.ReceivingDocument) Then
			
			ErrorText = StrTemplate(NStr("vi = 'Đối với lệnh %1 không thể tạo hóa đơn %2,
												|bởi vì không có lệnh nào.';
												|ru = 'Для распоряжения %1 невозможно оформить накладную %2,
												|т.к. нет ни одного ордера.';
												|en = 'Cannot register the %2 invoice for the %1 reference 
												| as there are no goods issues/receipts.'; fa = 'Cannot register the %2 invoice for the %1 reference 
												| as there are no goods issues/receipts.';
												|it = 'Per la disposizione %1 non è possibile formalizzare la bolla %2,
												|poiché non vi sono mandati.';
												|pl = 'Dla zamówienia %1 niemożliwe jest sporządzenie listu przewozowego %2,
												| ponieważ nie ma żadnego zlecenia.';
												|tr = 'Hiçbir emir olmadığından,
												| %1 emri için bir %2 irsaliye düzenlemek mümkün değildir.'"), String.Ref, ByNotes);
			
		ElsIf (String.GoodsIssueNoteState = 4 Or Not String.ShippingSlip)
				And (String.GoodsReceiptNoteState = 4 Or Not String.ReceivingDocument) Then
			
			ErrorText = StrTemplate(NStr("vi = 'Đối với lệnh %1 không thể tạo hóa đơn %2,
												|bởi vì không sử dụng lệnh.';
												|ru = 'Для распоряжения %1 невозможно оформить накладную %2,
												|т.к. ордера не используются.';
												|en = 'Cannot register the %2 invoice for the %1 reference 
												| as goods issues/receipts are not used.'; fa = 'Cannot register the %2 invoice for the %1 reference 
												| as goods issues/receipts are not used.';
												|it = 'Per la disposizione %1 non è possibile formalizzare la bolla%2,
												|poiché non sono utilizzati i mandati.';
												|pl = 'Dla zamówienia %1 niemożliwe jest sporządzenie listu przewozowego %2,
												| ponieważ zlecenia nie są stosowane.';
												|tr = 'Emir kullanılmadığından,
												|%1 emri için bir %2 irsaliye düzenlemek mümkün değildir.'"), String.Ref, ByNotes);
			
		Else
			
			String.ThereAreRegisteredReceipts = DeterminePresenceOfIssuedInvoices(String.Ref, String.Warehouse);
			
			If String.ThereAreRegisteredReceipts <> ThereAreRegisteredReceipts And ArrayOfTables.Count() > 0 Then
				
				ErrorText =
					StrTemplate(NStr("vi = 'Trong chế độ đóng gói có thể tạo chứng từ mới hoặc điền lại.
										  |Không thể xử lý chứng từ %1, hãy chọn riêng chứng từ đó.';
										  |ru = 'В пакетном режиме можно или создавать новые документы или перезаполнять.
										  |Документ %1 не будет обработан, выберете его отдельно.';
										  |en = 'You can either create new documents or refill them in batch mode.
										  |Document %1 will not be processed, select it separately.'; fa = 'You can either create new documents or refill them in batch mode.
										  |Document %1 will not be processed, select it separately.';
										  |it = 'In modalità batch si possono creare nuovi documenti o ricompilare documenti.
										  |Il documento %1 non sarà elaborato, selezionatelo separatamente.';
										  |pl = 'W trybie pakietowym można lub utwarzać nowe dokumenty lub ponownie wypełniać.
										  |Dokument %1 nie będzie przetworzony, wybierz go oddzielnie.';
										  |tr = 'Toplu modda, yeni belgeler oluşturabilir veya bunları yeniden doldurabilirsiniz.
										  | İşlenmeyecek %1 belgeyi ayrı olarak seçin.'", String.Ref));
				
			Else
				
				ThereAreRegisteredReceipts = String.ThereAreRegisteredReceipts;
				
			EndIf;
			
		EndIf;
		
		If ValueIsFilled(ErrorText) Then
			
			CommonClientServer.AddUserError(
				ErrorList, "Object.ListReceiptReferences",ErrorText);
			
			Continue;
			
		EndIf;
		
		If SplitTable = Undefined 
		 Or Not UseReceiptForMultipleOrders
		 Or Not TMCommonUseClientServer.StructuresAreEqual(CurrentKeys, String, KeyFields) Then
			
			SplitTable = ListOfOrders_.CopyColumns(SeparationFields);
			ArrayOfTables.Add(SplitTable);
			
			FillPropertyValues(CurrentKeys, String);
			
		EndIf;
		
		FillPropertyValues(SplitTable.Add(), String);
		
	EndDo;
	
	If ArrayOfTables.Count() > 1 And ThereAreRegisteredReceipts Then
		
		ArrayOfTables = New Array;
		
		CommonClientServer.AddUserError(
			ErrorList,
			"Object.ListReceiptReferences",
			NStr("vi = 'Chỉ có thể tạo lại hóa đơn theo các đơn hàng mà có các mục tin quan trọng giống nhau.';
				|ru = 'Переоформлять накладные можно только по заказам, имеющим одинаковые значимые реквизиты.';
				|en = 'The notes can be reissued only for orders with the same important attributes.'; fa = 'The notes can be reissued only for orders with the same important attributes.';
				|it = 'Le lettere di vettura possono essere riemesse solo per gli ordini che hanno gli stessi requisiti significativi.';
				|pl = 'Ponownie sporządzać faktury można tylko wg zamówień, mających jednakowe znaczne atrybuty.';
				|tr = 'Yalnızca eşit önemde özniteliklere sahip siparişler için yeniden irsaliye düzenleyebilirsiniz.'"));
		
	EndIf;
	
	Return ArrayOfTables;
	
EndFunction

#EndRegion

#Region GoodsReceipt

&AtServer
Function DeterminePresenceOfIssuedInvoices(DirectLink, Warehouse)
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	OrdersTable.PurchaseOrder AS OrderDocument,
	|	OrdersTable.Recorder	  AS Invoice
	|FROM
	|	AccumulationRegister.PurchaseOrders AS OrdersTable
	|WHERE
	|	OrdersTable.Warehouse                      = &Warehouse
	|	AND OrdersTable.PurchaseOrder          = &DirectLink
	|	AND VALUETYPE(OrdersTable.Recorder) = TYPE(Document.GoodsReceiptForStorage)
	|	AND OrdersTable.Products.ItemsType IN (
	|										VALUE(Enum.ItemsTypes.OwnGoods),
	|										VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&DirectLink    AS OrderDocument,
	|	Documentreceivings.Ref AS Invoice
	|FROM
	|	Document.GoodsReceiptForStorage AS Documentreceivings
	|		INNER JOIN Document.GoodsReceiptForStorage.Goods AS AcceptanceGoods
	|		ON Documentreceivings.Ref = AcceptanceGoods.Ref
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS StornoDocuments
	|		ON StornoDocuments.ReversedDocument = Documentreceivings.Ref
	|		 AND NOT StornoDocuments.AdditionalRecord
	|WHERE
	|	Documentreceivings.Posted
	|	AND AcceptanceGoods.Warehouse     = &Warehouse
	|	AND Documentreceivings.Contract = &DirectLink
	|	AND StornoDocuments.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToReceiveBalance.DocumentInflow                    AS DocumentInflow,
	|	GoodsToReceiveBalance.Products                           AS Products,
	|	GoodsToReceiveBalance.Characteristic                         AS Characteristic,
	|	GoodsToReceiveBalance.Purpose                             AS Purpose,
	|	GoodsToReceiveBalance.Series                                  AS Series,
	|	GoodsToReceiveBalance.ToRegisterGoodsReceiptsBalance AS Count
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			DocumentInflow = &DirectLink
	|			AND Warehouse = &Warehouse) AS GoodsToReceiveBalance
	|WHERE
	|	GoodsToReceiveBalance.ToRegisterGoodsReceiptsBalance <> 0";
	
	Query.SetParameter("DirectLink", DirectLink);
	Query.SetParameter("Warehouse",				Warehouse);
	
	SetPrivilegedMode(True);
	QueryResults = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	CreateInvoices = QueryResults[0].Unload();
	
	Return Not QueryResults[1].IsEmpty() And CreateInvoices.Count() > 0;
	
EndFunction

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array;
	
	If Items.Pages.CurrentPage = Items.ProductTransferPage Then
		
		Managers.Add(PredefinedValue("Document.MaterialProviderOrder2_5.EmptyRef"));
		Managers.Add(PredefinedValue("Document.GoodsShipmentFromStorage.EmptyRef"));
		
	ElsIf Items.Pages.CurrentPage = Items.RawMaterialReceiptPage Then
		
		Managers.Add(PredefinedValue("Document.MaterialProviderOrder2_5.EmptyRef"));
		Managers.Add(PredefinedValue("Document.GoodsReceiptForStorage.EmptyRef"));
		
	ElsIf Items.Pages.CurrentPage = Items.ReportsPage Then
		
		Managers.Add(PredefinedValue("Document.MaterialProviderOrder2_5.EmptyRef"));
		
	ElsIf Items.Pages.CurrentPage = Items.RawMaterialReturnsPage Then
		
		Managers.Add(PredefinedValue("Document.GoodsShipmentFromStorage.EmptyRef"));
		
	EndIf;
	
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	
	If ReferencesArrray.Count() > 0 Then
		
		If Items.Pages.CurrentPage = Items.ProductTransferPage Then
			
			CurrentList = "ListTransferReferences";
			
		ElsIf Items.Pages.CurrentPage = Items.RawMaterialReceiptPage Then
			
			CurrentList = "ListReceiptReferences";
			
		ElsIf Items.Pages.CurrentPage = Items.ReportsPage Then
			
			CurrentList = "ListReportReferences";
			
		ElsIf Items.Pages.CurrentPage = Items.RawMaterialReturnsPage Then
			
			CurrentList = "ListReferencesForRawMaterialReturn";
			
		EndIf;
		
		Ref = ReferencesArrray[0];
		
		RowsArray = ThisObject[CurrentList].FindRows(New Structure("Ref", Ref));
		
		If RowsArray.Count() > 0 Then
			Items[CurrentList].CurrentRow = RowsArray[0].GetID();
		EndIf;
		
		ShowValue(Undefined, Ref);
		
	Else
		
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region UpdateList_

&AtServer
Procedure UpdateListOfTransferRequestsOnServer()
	
	CurrentOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5;
	CurrentRow   = Items.ListTransferReferences.CurrentRow;
	
	CurrentDocument = Undefined;
	If CurrentRow <> Undefined Then
		CurrentDocument = ListTransferReferences.FindByID(CurrentRow).Ref;
	EndIf;
	
	FilterParameters = InvoicesServer.OrderSelectionParameters(Organization,, Warehouse,, Manager);
	
	QueriesTexts = QueriesTexts(FilterParameters, CurrentOperation);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.Text = QueriesTexts.StatusCalculationQueryText;
	
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	
	BusinessTransactions = New Array;
	BusinessTransactions.Add(CurrentOperation);
	BusinessTransactions.Add(TollingSchemeClientServer.ContractBusinessTransaction());
	BusinessTransactions.Add(Enums.BusinessTransactions.Subcontracting2_5);
	BusinessTransactions.Add(Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5);
	BusinessTransactions.Add(Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5);
	BusinessTransactions.Add(Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5);
	
	Query.SetParameter("OperationIssuedByHousehold", CurrentOperation);
	Query.SetParameter("CurrentDayStart",		BegOfDay(CurrentSessionDate()));
	Query.SetParameter("BusinessTransaction",			BusinessTransactions);
	Query.SetParameter("Organization",			CompaniesList.UnloadValues());
	Query.SetParameter("Warehouse",					WarehousesList.UnloadValues());
	Query.SetParameter("Manager",				Manager);
	Query.SetParameter("References",			References.UnloadValues());
	
	Query.Execute();
	
	Query.Text = QueriesTexts.TextOfDirectiveListRequest;
	
	SetPrivilegedMode(True);
	DocumentsTable = Query.Execute().Unload();
	TMCommonUse.ProcessMultilingualColumnOfTableOfValues(DocumentsTable);
	ListTransferReferences.Load(DocumentsTable);
	SetPrivilegedMode(False);
	
	If CurrentDocument <> Undefined Then
		
		RowsArray = ListTransferReferences.FindRows(New Structure("Ref", CurrentDocument));
		If RowsArray.Count() > 0 Then
			Items.ListTransferReferences.CurrentRow = RowsArray[0].GetID();
		EndIf;
		
	EndIf;
	
	UpdateTransfers = False;
	
EndProcedure

&AtServer
Procedure UpdateListOfReceiptRequestsOnServer()
	
	CurrentOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;
	CurrentRow   = Items.ListReceiptReferences.CurrentRow;
	
	CurrentDocument = Undefined;
	If CurrentRow <> Undefined Then
		CurrentDocument = ListReceiptReferences.FindByID(CurrentRow).Ref;
	EndIf;
	
	FilterParameters = InvoicesServer.OrderSelectionParameters(Organization,, Warehouse, CurrentOperation, Manager);
	QueriesTexts  = QueriesTexts(FilterParameters, CurrentOperation);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.Text = QueriesTexts.StatusCalculationQueryText;
	
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	
	BusinessTransactions = New Array;
	BusinessTransactions.Add(CurrentOperation);
	BusinessTransactions.Add(TollingSchemeClientServer.ContractBusinessTransaction());
	BusinessTransactions.Add(Enums.BusinessTransactions.Subcontracting2_5);
	BusinessTransactions.Add(Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5);
	BusinessTransactions.Add(Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5);
	BusinessTransactions.Add(Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5);
	
	Query.SetParameter("OperationIssuedByHousehold", CurrentOperation);
	Query.SetParameter("CurrentDayStart",		BegOfDay(CurrentSessionDate()));
	Query.SetParameter("BusinessTransaction",			BusinessTransactions);
	Query.SetParameter("Organization",			CompaniesList.UnloadValues());
	Query.SetParameter("Warehouse",					WarehousesList.UnloadValues());
	Query.SetParameter("Manager",				Manager);
	Query.SetParameter("References",			References.UnloadValues());
	
	Query.Execute();
	
	Query.Text = QueriesTexts.TextOfDirectiveListRequest;
	
	SetPrivilegedMode(True);
	DocumentsTable = Query.Execute().Unload();
	TMCommonUse.ProcessMultilingualColumnOfTableOfValues(DocumentsTable);
	ListReceiptReferences.Load(DocumentsTable);
	SetPrivilegedMode(False);
	
	If CurrentDocument <> Undefined Then
		
		RowsArray = ListReceiptReferences.FindRows(New Structure("Ref", CurrentDocument));
		If RowsArray.Count() > 0 Then
			Items.ListReceiptReferences.CurrentRow = RowsArray[0].GetID();
		EndIf;
		
	EndIf;
	
	UpdateReceipts = False;
	
EndProcedure

&AtServer
Procedure UpdateListOfLinksToReportsOnServer()
	
	CurrentRow   = Items.ListReportReferences.CurrentRow;
	
	CurrentDocument = Undefined;
	If CurrentRow <> Undefined Then
		CurrentDocument = ListReportReferences.FindByID(CurrentRow).Ref;
	EndIf;
	
	FilterParameters = InvoicesServer.OrderSelectionParameters(Organization,, Warehouse,, Manager);
	
	TypesOfOrders = New Array;
	TypesOfOrders.Add("Document.MaterialProviderOrder2_5");
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.Text =
		InvoicesServer.StateRequestText("StatesOfReportsToGivers2_5", FilterParameters, TypesOfOrders);
	
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	
	Query.SetParameter("Organization", CompaniesList.UnloadValues());
	Query.SetParameter("Warehouse",		 WarehousesList.UnloadValues());
	Query.SetParameter("Manager",	 Manager);
	
	Query.Execute();
	
	Query.Text =
	"SELECT
	|	RemnantsOfState.Contract                                                        AS Contract,
	|	DocumentsRegistry.IBDocumentNumber                                               AS Number,
	|	DocumentsRegistry.IBDocumentDate                                                AS Date,
	|	VALUETYPE(DocumentsRegistry.Ref)                                            AS TypeOfOrder_,
	|	RemnantsOfState.State                                                      AS ReportState,
	|	DocumentsRegistry.Sum                                                          AS DocumentAmount,
	|	DocumentsRegistry.Currency                                                         AS Currency,
	|	DocumentsRegistry.Partner                                                        AS Partner,
	|	DocumentsRegistry.Counterparty.Key                                                AS Counterparty,
	|	DocumentsRegistry.Organization                                                    AS Organization,
	|	DocumentsRegistry.Department                                                  AS Department,
	|	DocumentsRegistry.EmployeeResponsible                                                  AS Manager,
	|	RemnantsOfState.ReferenceOrder                                                   AS Ref,
	|	RemnantsOfState.Warehouse                                                          AS Warehouse,
	|	DocumentsRegistry.More                                                  AS More,
	|	CAST(RemnantsOfState.ReferenceOrder AS Document.MaterialProviderOrder2_5).Priority AS Priority
	|FROM
	|	TTStateReportsToGivers2_5 AS RemnantsOfState
	|		INNER JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON RemnantsOfState.ReferenceOrder = DocumentsRegistry.Ref
	|		 AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	RemnantsOfState.ReferenceOrder <> VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	RemnantsOfState.Contract                         AS Contract,
	|	UNDEFINED                                     AS Number,
	|	DATETIME(1, 1, 1)                               AS Date,
	|	UNDEFINED                                     AS TypeOfOrder_,
	|	RemnantsOfState.State                       AS ReportState,
	|	UNDEFINED                                     AS DocumentAmount,
	|	CounterpartyContracts.ARAPCurrency        AS Currency,
	|	CounterpartyContracts.Partner                     AS Partner,
	|	CounterpartyContracts.Counterparty                  AS Counterparty,
	|	CounterpartyContracts.Organization                 AS Organization,
	|	CounterpartyContracts.Department               AS Department,
	|	CounterpartyContracts.Manager                    AS Manager,
	|	VALUE(Document.MaterialProviderOrder2_5.EmptyRef) AS Ref,
	|	RemnantsOfState.Warehouse                           AS Warehouse,
	|	UNDEFINED                                     AS More,
	|	UNDEFINED                                     AS Priority
	|FROM
	|	TTStateReportsToGivers2_5 AS RemnantsOfState
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON RemnantsOfState.Contract = CounterpartyContracts.Ref
	|WHERE
	|	RemnantsOfState.ReferenceOrder = VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|
	|ORDER BY
	|	Contract DESC,
	|	Date";
	
	SetPrivilegedMode(True);
	DocumentsTable = Query.Execute().Unload();
	TMCommonUse.ProcessMultilingualColumnOfTableOfValues(DocumentsTable);
	ListReportReferences.Load(DocumentsTable);
	SetPrivilegedMode(False);
	
	If CurrentDocument <> Undefined Then
		
		RowsArray = ListReportReferences.FindRows(New Structure("Ref", CurrentDocument));
		If RowsArray.Count() > 0 Then
			Items.ListReportReferences.CurrentRow = RowsArray[0].GetID();
		EndIf;
		
	EndIf;
	
	UpdatingReportsIsRequired = False;
	
EndProcedure

&AtServer
Procedure UpdateListOfOrdersForReturnOfRawMaterialsOnServer()
	
	CurrentOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5;
	CurrentRow   = Items.ListReferencesForRawMaterialReturn.CurrentRow;
	
	CurrentDocument = Undefined;
	If CurrentRow <> Undefined Then
		CurrentDocument = ListReferencesForRawMaterialReturn.FindByID(CurrentRow).Ref;
	EndIf;
	
	FilterParameters = InvoicesServer.OrderSelectionParameters(Organization,, Warehouse, CurrentOperation, Manager);
	
	QueriesTexts = QueriesTexts(FilterParameters, CurrentOperation);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.Text = QueriesTexts.StatusCalculationQueryText;
	
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	
	BusinessTransactions = New Array;
	BusinessTransactions.Add(CurrentOperation);
	BusinessTransactions.Add(TollingSchemeClientServer.ContractBusinessTransaction());
	BusinessTransactions.Add(Enums.BusinessTransactions.Subcontracting2_5);
	BusinessTransactions.Add(Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5);
	BusinessTransactions.Add(Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5);
	BusinessTransactions.Add(Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5);
	
	Query.SetParameter("OperationIssuedByHousehold", CurrentOperation);
	Query.SetParameter("CurrentDayStart",		BegOfDay(CurrentSessionDate()));
	Query.SetParameter("BusinessTransaction",			BusinessTransactions);
	Query.SetParameter("Organization",			CompaniesList.UnloadValues());
	Query.SetParameter("Warehouse",					WarehousesList.UnloadValues());
	Query.SetParameter("Manager",				Manager);
	
	Query.Execute();
	
	Query.Text = QueriesTexts.TextOfDirectiveListRequest;
	
	SetPrivilegedMode(True);
	DocumentsTable = Query.Execute().Unload();
	TMCommonUse.ProcessMultilingualColumnOfTableOfValues(DocumentsTable);
	ListReferencesForRawMaterialReturn.Load(DocumentsTable);
	SetPrivilegedMode(False);
	
	If CurrentDocument <> Undefined Then
		
		RowsArray = ListReferencesForRawMaterialReturn.FindRows(New Structure("Ref", CurrentDocument));
		If RowsArray.Count() > 0 Then
			Items.ListReferencesForRawMaterialReturn.CurrentRow = RowsArray[0].GetID();
		EndIf;
		
	EndIf;
	
	UpdateReturns = False;
	
EndProcedure

#EndRegion

#Region SavedFormSettings

&AtServer
Procedure RestoreSettings(Var_Parameters)
	
	If Var_Parameters.Property("QuickFilterStructure") Then
		FillPropertyValues(ThisObject, FormSettings(Var_Parameters.QuickFilterStructure));
	ElsIf Var_Parameters.Property("Filter") Then
		
		FormSettings = FormSettings(Var_Parameters.Filter);
		FillPropertyValues(ThisObject, FormSettings);
		
		If TypeOf(FormSettings.Organization) = Type("Array")
			And FormSettings.Organization.Count() = 1 Then
			Organization = FormSettings.Organization[0];
		EndIf;
		
	Else
		
		SettingsFromStorage = Common.CommonSettingsStorageLoad(
									"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.DocumentsList",
									PurposeUseKey);
		
		If TypeOf(SettingsFromStorage) = Type("Structure") Then
			FillPropertyValues(ThisObject, FormSettings(SettingsFromStorage));
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	Common.CommonSettingsStorageSave(
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.DocumentsList",
		PurposeUseKey,
		FormSettings(ThisForm));
	
EndProcedure

&AtServer
Function FormSettings(SettingsSource)
	
	AttributesToSaveNames =
	"Organization,
	|Warehouse,
	|Manager,
	|StatusOfTheTransferInvoice,
	|ReceiptInvoiceStatus,
	|GoodsIssueNoteState,
	|GoodsReceiptNoteState,
	|StatusOfTheShipmentReturnOrder,
	|ReportState";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, SettingsSource);
	
	Return Settings;
	
EndFunction

#EndRegion

#Region Other

&AtClient
Procedure ProcessResultOfPaperwork(ParametersOfCreatedDocuments, EventName)
	
	CommonClientServer.ReportErrorsToUser(ParametersOfCreatedDocuments.ErrorList);
	
	NumberOfDocumentsCreated = 0;
	
	If ParametersOfCreatedDocuments.Property("Parameters") Then
		
		If ParametersOfCreatedDocuments.Parameters.Property("ThereIsFix") Then
			
			InvoicesClient.WarningAboutPresenceOfFix(ParametersOfCreatedDocuments.Parameters.Key,
				ParametersOfCreatedDocuments.Parameters.FormName);
		
		Else
		
			CreatedDocuments = ParametersOfCreatedDocuments.Parameters.CreatedDocuments;
		
			NumberOfDocumentsCreated = CreatedDocuments.Count();
		
			ShowUserNotification(
				NStr("vi = 'Tạo chứng từ';
					|ru = 'Создание документов';
					|en = 'Create documents'; fa = 'ایجاد اسناد';
					|it = 'Creazione documenti';
					|pl = 'Utworzenie dokumentów';
					|tr = 'Belgelerin oluşturulması'"),,
				StrTemplate(NStr("vi = 'Đã tạo chứng từ: %1';
								|ru = 'Создано документов: %1';
								|en = 'Created documents: %1'; fa = 'Created documents: %1';
								|it = 'Documenti creati: %1';
								|pl = 'Utworzono dokumentów: %1';
								|tr = 'Oluşturulan belgeler: %1'"), NumberOfDocumentsCreated));
			
		EndIf;
		
	EndIf;
	
	If NumberOfDocumentsCreated > 0 Then
		
		If NumberOfDocumentsCreated > 1
		 Or CreatedDocuments.Find(Undefined) = Undefined Then
			Notify(EventName);
		EndIf;
		
		If ParametersOfCreatedDocuments.Property("FormName") Then
			OpenForm(ParametersOfCreatedDocuments.FormName, ParametersOfCreatedDocuments.Parameters, ThisObject);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	SetSelectionByOrganization();
	
	UpdateTransfers    = True;
	UpdateReceipts = True;
	UpdatingReportsIsRequired      = True;
	UpdateReturns    = True;
	
	RefreshCurPageOnServer();
	
EndProcedure

&AtServer
Procedure WarehouseWhenChangedOnServer()
	
	SetSelectionByWarehouse();
	
	UpdateTransfers    = True;
	UpdateReceipts = True;
	UpdateReturns    = True;
	
	RefreshCurPageOnServer();
	
EndProcedure

&AtServer
Procedure SetSelectionByOrganization()

	CompaniesList.Clear();
	
	If ValueIsFilled(Organization) Then
		
		CompaniesList.LoadValues(
			Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Organization));
		
		CompaniesList.Add(Organization);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionByWarehouse()
	
	WarehousesList = WarehousesServer.ListOfSubordinateWarehouses(Warehouse);
	
EndProcedure

&AtServerNoContext
Function GenerateReportsOnServer(GroupingOrders, FormParametersForCreatedDocuments, ErrorList, ErrorField)
	
	ParametersOfCreatedDocuments = New Structure("Cancel, FormName, Parameters", False);
	
	For Each GroupOfOrders In GroupingOrders Do
		
		NameOfDocumentBeingProcessed = GroupOfOrders.NameOfDocumentBeingProcessed;
		OrderMetadata = GroupOfOrders.AnArrayOfOrders[0].Metadata();
		
		FillPropertyValues(
			GroupOfOrders, KeyFieldsOfHeader(NameOfDocumentBeingProcessed, OrderMetadata));
		
	EndDo;
	
	InvoicesServer.GroupDocumentsByKeyFieldsInCollection(
		GroupingOrders, "AnArrayOfOrders", "KeyHeaderFields", "KeyFieldsOfHeaderAdapted");
	
	If GroupingOrders.Count() = 1 And GroupingOrders[0].AnArrayOfOrders.Count() = 1 Then
		
		GroupOfOrders 		 = GroupingOrders[0];
		CurrentOrder		 = GroupOfOrders.AnArrayOfOrders[0];
		NameOfDocumentBeingProcessed = GroupOfOrders.NameOfDocumentBeingProcessed;
		
		InvoiceManager = Documents[NameOfDocumentBeingProcessed];
				
		FillParameters = InvoiceManager.DocumentFillingParameters();
		HeaderAttributes = InvoiceManager.InvoiceFillingData(CurrentOrder, GroupOfOrders.PopulationFields);
		
		InvoiceManager.InitializeFillingParameters(FillParameters, HeaderAttributes, CurrentOrder);
		
		ParametersOfCreatedDocuments.Cancel = (HeaderAttributes = Undefined);
		ParametersOfCreatedDocuments.FormName = "Document." + NameOfDocumentBeingProcessed + ".ObjectForm";
		ParametersOfCreatedDocuments.Parameters = New Structure("Basis", FillParameters);
		
	Else
		
		CreatedDocuments = InvoicesServer.GenerateDocumentsOnOrders(
												GroupingOrders, ErrorList, ErrorField);
		
		If Not ValueIsFilled(CreatedDocuments) Then
			Return Undefined;
		EndIf;
		
		Owner = Users.AuthorizedUser();
		
		SetPrivilegedMode(True);
		
		Common.WriteDataToSecureStorage(
							Owner, CreatedDocuments, FormParametersForCreatedDocuments.DataKey);
		
		SetPrivilegedMode(False);
		
		ParametersOfCreatedDocuments.FormName  = "CommonForm.CreatedDocumentForm";
		ParametersOfCreatedDocuments.Parameters = FormParametersForCreatedDocuments;
		ParametersOfCreatedDocuments.Insert("NumberOfDocumentsCreated", CreatedDocuments.Count());
		
	EndIf;
	
	Return ParametersOfCreatedDocuments;
	
EndFunction

&AtClient
Procedure OpenDocumentExecutionStateReport(TableName, FormTable)
	
	If Items[TableName].SelectedRows.Count() = 0 Then
		
		ShowMessageBox(, NStr("vi = 'Chưa chọn dòng nào. Không thể thực hiện lệnh.';
								|ru = 'Не выделено ни одной строки. Выполнение команды невозможно.';
								|en = 'No lines are selected. Cannot execute the command.'; fa = 'No lines are selected. Cannot execute the command.';
								|it = 'Nessuna riga selezionata. Il comando non può essere eseguito.';
								|pl = 'Nie wybrano ani jednego wierszu. Wykonanie polecenia jest niemożliwe.';
								|tr = 'Hiçbir satır vurgulandı. Komut çalıştırılamıyor.'"));
		
	Else
		
		DocumentsList = New ValueList;
		
		For Each Id In Items[TableName].SelectedRows Do
			
			TableRow = FormTable.FindByID(Id);
			
			If TypeOf(TableRow.Ref) = Type("DocumentRef.MaterialProviderOrder2_5") Then
				DocumentsList.Add(TableRow.Ref);
			EndIf;
			
		EndDo;
		
		If DocumentsList.Count() = 0 Then
			ShowMessageBox(, NStr("vi = 'Việc thực hiện lệnh chỉ có thể đối với các đơn đặt hàng của người đặt gia công.';
									|ru = 'Выполнение команды возможно только для заказов давальца.';
									|en = 'Command can be performed only for subcontracting sales orders.'; fa = 'Command can be performed only for subcontracting sales orders.';
									|it = 'L''esecuzione del comando è possibile solo per gli ordini di committente.';
									|pl = 'Wykonanie polecenia jest możliwe tylko dla zamówień dawcy.';
									|tr = 'Komut yalnızca siparişi verenin siparişleri için yerine getirilebilir.'"));
			Return;
		EndIf;
		
		OpenForm(
			"Report.DocumentFulfillmentStatus.Form.ReportForm",
			New Structure("IncomingDocuments", DocumentsList));
		
	EndIf;

EndProcedure

&AtClient
Function LogParameters()
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization", Organization);
	QuickFilterStructure.Insert("Warehouse",		Warehouse);
	QuickFilterStructure.Insert("Manager",	Manager);
	
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	LogParameters.Insert("WorkplaceName",		 "DocumentsOfReceiptForTollingAll2_5");
	LogParameters.Insert("JournalSynonym",			 NStr("vi = 'Chứng từ tiếp nhận vào gia công';
															|ru = 'Документы приема в переработку';
															|en = 'External subcontracting'; fa = 'پیمانکاری فرعی خارجی';
															|it = 'Documenti di accettazione in trasformazione';
															|pl = 'Dokumenty odbioru do przetwórstwa';
															|tr = 'İşlenecek kabul belgeleri'"));
	LogParameters.Insert(
		"FormAssignmentKey",
		TollingSchemeClientServer.AssignmentKeyDocumentsOfAcceptanceForProcessing());
	
	Return LogParameters;
	
EndFunction

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices.Item.Pages.OnCurrentPageChange");
	
	RefreshCurPage();
	
EndProcedure

&AtClient
Procedure RefreshCurPage()
	
	If Items.Pages.CurrentPage = Items.ProductTransferPage
	   And UpdateTransfers Then
		
		UpdateListOfTransferRequestsOnServer();
		
	ElsIf Items.Pages.CurrentPage = Items.RawMaterialReceiptPage
			And UpdateReceipts Then
		
		UpdateListOfReceiptRequestsOnServer();
		
	ElsIf Items.Pages.CurrentPage = Items.ReportsPage
			And UpdatingReportsIsRequired Then
		
		UpdateListOfLinksToReportsOnServer();
		
	ElsIf Items.Pages.CurrentPage = Items.RawMaterialReturnsPage
			And UpdateReturns Then
		
		UpdateListOfOrdersForReturnOfRawMaterialsOnServer();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshCurPageOnServer()
	
	If Items.Pages.CurrentPage = Items.ProductTransferPage
	   And UpdateTransfers Then
		
		UpdateListOfTransferRequestsOnServer();
		
	ElsIf Items.Pages.CurrentPage = Items.RawMaterialReceiptPage
			And UpdateReceipts Then
		
		UpdateListOfReceiptRequestsOnServer();
		
	ElsIf Items.Pages.CurrentPage = Items.ReportsPage
			And UpdatingReportsIsRequired Then
		
		UpdateListOfLinksToReportsOnServer();
		
	ElsIf Items.Pages.CurrentPage = Items.RawMaterialReturnsPage
			And UpdateReturns Then
		
		UpdateListOfOrdersForReturnOfRawMaterialsOnServer();
		
	EndIf;
	
EndProcedure

&AtServer
Function QueriesTexts(FilterParameters, BusinessTransaction)
	
	BsnsTransactions = New Array;
	BsnsTransactions.Add(BusinessTransaction);
	
	Package     = New Array;
	Selection   = New Array;
	
	States1 = InvoicesServer.StatesByBusinessTransactions(BsnsTransactions);
	
	For Each KZ In States1 Do
		
		Package.Add(InvoicesServer.StateRequestText(KZ.Key, FilterParameters, KZ.Value));
		
		If KZ.Key = "StatesOfSpendingOrders" Then
			
			QueryText =
			"SELECT
			|	StatesOfSpendingOrders.ReferenceOrder AS ReferenceOrder,
			|	StatesOfSpendingOrders.Warehouse        AS Warehouse,
			|	UNDEFINED                           AS Priority,
			|	CASE
			|		WHEN VALUETYPE(StatesOfSpendingOrders.ReferenceOrder) = TYPE(Document.MaterialProviderOrder2_5)
			|			THEN 0
			|		ELSE 4
			|	END                                  AS InvoiceStatus,
			|	StatesOfSpendingOrders.State    AS StateOfSpendingOrder,
			|	4                                      AS StatusOfTheReceiptOrder,
			|	TRUE                                 AS ShippingSlip,
			|	FALSE                                   AS ReceivingDocument
			|FROM
			|	TTStateOfSpendingOrders AS StatesOfSpendingOrders";
			
		ElsIf KZ.Key = "StatesOfIncomingOrders" Then
			
			QueryText =
			"SELECT
			|	StatesOfIncomingOrders.ReferenceOrder AS ReferenceOrder,
			|	StatesOfIncomingOrders.Warehouse        AS Warehouse,
			|	UNDEFINED                           AS Priority,
			|	CASE
			|		WHEN VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.MaterialProviderOrder2_5)
			|			THEN 0
			|		ELSE 4
			|	END                                  AS InvoiceStatus,
			|	4                                      AS StateOfSpendingOrder,
			|	StatesOfIncomingOrders.State    AS StatusOfTheReceiptOrder,
			|	FALSE                                   AS ShippingSlip,
			|	TRUE                                 AS ReceivingDocument
			|FROM
			|	TTStateOfIncomingOrders AS StatesOfIncomingOrders";
			
		ElsIf KZ.Key = "TransfersStates" Then
			
			QueryText =
			"SELECT
			|	TransfersStates.ReferenceOrder AS ReferenceOrder,
			|	TransfersStates.Warehouse        AS Warehouse,
			|	MaterialProviderOrder2_5.Priority    AS Priority,
			|	TransfersStates.State    AS InvoiceStatus,
			|	CASE
			|		WHEN CatWarehousesSender.Ref IS NULL
			|			THEN 4
			|		WHEN TransfersStates.State = 1
			|			THEN 1
			|		ELSE 0
			|	END                          AS StateOfSpendingOrder,
			|	4                              AS StatusOfTheReceiptOrder,
			|	TRUE                         AS ShippingSlip,
			|	FALSE                           AS ReceivingDocument
			|FROM
			|	TTTransfersState AS TransfersStates
			|		
			|		LEFT JOIN Catalog.Warehouses AS CatWarehousesSender
			|		ON CatWarehousesSender.Ref = TransfersStates.Warehouse
			|		 AND CatWarehousesSender.UseWarehouseManagemantSystemForGoodsIssue
			|		 AND CatWarehousesSender.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDayStart
			|		
			|		LEFT JOIN Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
			|		ON TransfersStates.ReferenceOrder = MaterialProviderOrder2_5.Ref";
			
		ElsIf KZ.Key = "RevenueStates" Then
			
			QueryText =
			"SELECT
			|	RevenueStates.ReferenceOrder AS ReferenceOrder,
			|	RevenueStates.Warehouse        AS Warehouse,
			|	MaterialProviderOrder2_5.Priority        AS Priority,
			|	RevenueStates.State    AS InvoiceStatus,
			|	4                                 AS StateOfSpendingOrder,
			|	CASE
			|		WHEN CatWarehousesRecipient.Ref IS NULL
			|		  OR MaterialProviderOrder2_5.GoodsReceiptOption =
			|				VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
			|			THEN 4
			|		WHEN RevenueStates.State = 1
			|			THEN 1
			|		ELSE 0
			|	END                             AS StatusOfTheReceiptOrder,
			|	FALSE                              AS ShippingSlip,
			|	TRUE                            AS ReceivingDocument
			|FROM
			|	TTStateReceipts AS RevenueStates
			|		
			|		LEFT JOIN Catalog.Warehouses AS CatWarehousesRecipient
			|		ON CatWarehousesRecipient.Ref = RevenueStates.Warehouse
			|		 AND CatWarehousesRecipient.UseWarehouseManagemantSystemForGoodsReceipt
			|		 AND CatWarehousesRecipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDayStart
			|		
			|		LEFT JOIN Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
			|		ON RevenueStates.ReferenceOrder = MaterialProviderOrder2_5.Ref";
			
		EndIf;
		
		Selection.Add(QueryText);
		
	EndDo;
	
	StatusCalculationQueryText = StrConcat(Package, Common.QueryBatchSeparator());
	
	TextOfDirectiveListRequest =
	"SELECT
	|	NestedQuery.ReferenceOrder                        AS Ref,
	|	NestedQuery.Warehouse                               AS Warehouse,
	|	MAX(NestedQuery.Priority)                 AS Priority,
	|	MAX(NestedQuery.InvoiceStatus)        AS InvoiceStatus,
	|	MAX(NestedQuery.StateOfSpendingOrder) AS GoodsIssueNoteState,
	|	MAX(NestedQuery.StatusOfTheReceiptOrder) AS GoodsReceiptNoteState,
	|	MAX(NestedQuery.ShippingSlip)       AS ShippingSlip,
	|	MAX(NestedQuery.ReceivingDocument)        AS ReceivingDocument
	|INTO TTRemainsOfState
	|FROM
	|	QueryTextNested AS NestedQuery
	|WHERE
	|	&ContextOfOrders
	|
	|GROUP BY
	|	NestedQuery.ReferenceOrder,
	|	NestedQuery.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsRegistry.IBDocumentNumber          AS Number,
	|	DocumentsRegistry.IBDocumentDate           AS Date,
	|	VALUETYPE(DocumentsRegistry.Ref)       AS TypeOfOrder_,
	|	RemnantsOfState.InvoiceStatus        AS InvoiceStatus,
	|	RemnantsOfState.GoodsIssueNoteState AS GoodsIssueNoteState,
	|	RemnantsOfState.GoodsReceiptNoteState  AS GoodsReceiptNoteState,
	|	RemnantsOfState.ShippingSlip       AS ShippingSlip,
	|	RemnantsOfState.ReceivingDocument        AS ReceivingDocument,
	|	DocumentsRegistry.Sum                     AS DocumentAmount,
	|	DocumentsRegistry.Currency                    AS Currency,
	|	DocumentsRegistry.Partner                   AS Partner,
	|	DocumentsRegistry.Counterparty.Key           AS Counterparty,
	|	DocumentsRegistry.Contract                   AS Contract,
	|	DocumentsRegistry.Organization               AS Organization,
	|	DocumentsRegistry.Department             AS Department,
	|	RemnantsOfState.Warehouse                     AS Warehouse,
	|	DocumentsRegistry.EmployeeResponsible             AS Manager,
	|	RemnantsOfState.Ref                    AS Ref,
	|	DocumentsRegistry.More             AS More,
	|	&OperationIssuedByHousehold                    AS BusinessOperation,
	|	RemnantsOfState.Priority                 AS Priority
	|FROM
	|	TTRemainsOfState AS RemnantsOfState
	|		
	|		INNER JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON RemnantsOfState.Ref = DocumentsRegistry.Ref
	|		 AND NOT DocumentsRegistry.AdditionalRecord
	|		
	|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
	|		ON RemnantsOfState.Warehouse = CatWarehouses.Ref
	|
	|ORDER BY
	|	Date";
	
	TextOfDirectiveListRequest =
		StrReplace(
			TextOfDirectiveListRequest,
			"QueryTextNested",
			StrTemplate("(%1)", StrConcat(Selection, TMCommonUse.QuerySeparatorInJoin())));
	
	TextOfDirectiveListRequest =
		StrReplace(
			TextOfDirectiveListRequest,
			"&ContextOfOrders",
			?(ValueIsFilled(References), "NestedQuery.ReferenceOrder IN (&References)", "TRUE"));
	
	StructureOfQueryTexts_ = New Structure;
	StructureOfQueryTexts_.Insert("StatusCalculationQueryText",   StatusCalculationQueryText);
	StructureOfQueryTexts_.Insert("TextOfDirectiveListRequest", TextOfDirectiveListRequest);
	
	Return StructureOfQueryTexts_;
	
EndFunction

&AtServer
Procedure FillInDocumentMetadata()
	
	String = MetadataOfDocuments.Add();
	String.BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5;
	String.FullDocumentName	 = Metadata.Documents.GoodsShipmentFromStorage.FullName();
	String.Handler			 = "ReturnToMaterialProvider";
	
EndProcedure


// Fills in the parameters of the "General form.The form of the created documents".
//
// Parameters:
//  FormParameters        - Structure
//  BusinessOperation - EnumRef.BusinessTransactions
//  DataKey            - Undefined, String- PurposeUseKey
//
&AtClientAtServerNoContext
Procedure FillInFormParametersOfCreatedDocuments(FormParameters, BusinessOperation, DataKey = Undefined)
	
	FormParameters.Insert("VisibleColumns",	 New Array);
	FormParameters.Insert("UpdateEvents", New Array);
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReportToMaterialProvider2_5")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnToMaterialProvider2_5") Then
		FormParameters.Insert("DataKey",	 DataKey);
	EndIf;
	
	FormParameters.VisibleColumns.Add("Number");
	FormParameters.VisibleColumns.Add("Date");
	FormParameters.VisibleColumns.Add("ValueType");
	FormParameters.VisibleColumns.Add("Partner");
	FormParameters.VisibleColumns.Add("Counterparty");
	FormParameters.VisibleColumns.Add("Contract");
	FormParameters.VisibleColumns.Add("Organization");
	FormParameters.VisibleColumns.Add("Department");
	FormParameters.VisibleColumns.Add("Warehouse");
	FormParameters.VisibleColumns.Add("More");
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReportToMaterialProvider2_5")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5") Then
		FormParameters.VisibleColumns.Add("DocumentAmount");
		FormParameters.VisibleColumns.Add("Currency");
	EndIf;
	
	FormParameters.UpdateEvents.Add("Write_GoodsShipmentFromStorage");
	FormParameters.UpdateEvents.Add("Write_GoodsReceiptForStorage");
	FormParameters.UpdateEvents.Add("Write_ReportToMaterialProvider2_5");
	
EndProcedure

&AtServerNoContext
Function KeyFieldsOfHeader(NameOfGenerationDocument, MetadataObject_Order)
	
	ManagerOfDocument = Documents[NameOfGenerationDocument];
	KeyHeaderFields = ManagerOfDocument.KeyFieldsOfHeader();
	
	KeyFieldsOfHeaderAdapted = KeyHeaderFields;
	
	OrderManager_ = Common.ObjectManagerByFullName(MetadataObject_Order.FullName());
	ReplaceableDetails = New Structure;
	
	If ManagerOfDocument = Documents.ReportToMaterialProvider2_5 And OrderManager_ = Catalogs.CounterpartyContracts Then
		
		ReplaceableDetails.Insert("Currency",			"ARAPCurrency");
		ReplaceableDetails.Insert("Contract",			"Ref");
		ReplaceableDetails.Insert("Warehouse",			"UNDEFINED");
		ReplaceableDetails.Insert("SalesOpportunity",			"UNDEFINED");
		ReplaceableDetails.Insert("PriceIncludesVAT", "UNDEFINED");
		ReplaceableDetails.Insert("ARAPObjectSettings", "UNDEFINED");
		
	EndIf;
	
	If ValueIsFilled(ReplaceableDetails) Then
		
		ArrayOfKeyFieldsAdapted = StrSplit(KeyFieldsOfHeaderAdapted, ",", False);
		
		FieldsCount = ArrayOfKeyFieldsAdapted.Count();
		IndexOf = 0;
		ReplacementValue = Undefined;
		
		While IndexOf < FieldsCount Do
			
			KeyFieldAdapted = StrReplace(ArrayOfKeyFieldsAdapted[IndexOf], Chars.LF, "");
			
			If ReplaceableDetails.Property(KeyFieldAdapted, ReplacementValue) Then
				
				ArrayOfKeyFieldsAdapted[IndexOf] = StrTemplate("%1%2 AS %3",
																		Chars.LF,
																		ReplacementValue,
																		KeyFieldAdapted);
				
			EndIf;
			
			IndexOf = IndexOf + 1;
			
		EndDo;
		
		KeyFieldsOfHeaderAdapted = StrConcat(ArrayOfKeyFieldsAdapted, ",");
		
	EndIf;
	
	StructureOfKeyFields = New Structure;
	StructureOfKeyFields.Insert("KeyHeaderFields",			   KeyHeaderFields);
	StructureOfKeyFields.Insert("KeyFieldsOfHeaderAdapted", KeyFieldsOfHeaderAdapted);
	
	Return StructureOfKeyFields;
	
EndFunction

#EndRegion

#EndRegion

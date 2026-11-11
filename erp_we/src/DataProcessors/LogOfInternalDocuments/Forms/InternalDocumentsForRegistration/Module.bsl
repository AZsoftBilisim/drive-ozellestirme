
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
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	If IsBlankString(Parameters.FormAssignmentKey) Then
		PurposeUseKey = DefaultFormAssignmentKey();
	Else
		PurposeUseKey = Parameters.FormAssignmentKey;
	EndIf;
	
	If PurposeUseKey = DefaultFormAssignmentKey() Then
		SettingsKey = "";
	Else
		SettingsKey = PurposeUseKey;
	EndIf;
	
	If Parameters.Property("References") Then
		References.LoadValues(Parameters.References);
	EndIf;
	
	RestoreSettings(Parameters);
	SetSelectionByOrganization();
	
	VTBusinessTransactionsAndDocumentTypes = TMCommonUse.AvailableBusinessTransactionsAndDocuments(
		DataProcessors.LogOfInternalDocuments.DescriptionOfOperationsAndDocumentTypes(
			BusinessTransactionsAndDocuments.Unload(New Array)).Copy(
				New Structure("HyperlinkCalculationManagerForRegistration", "DataProcessor.LogOfInternalDocuments")),
		FilterBusinessTransactions, FilterDocumentTypes, SettingsKey);
	
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	
	ConfigureFormByRightsAndFunctionalOptions();
	
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	TheConditionOfTheDocumentsWhenYouChange(Undefined);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit And PurposeUseKey <> "ToDoList" And PurposeUseKey <> "InputOnBasis" Then
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
	EndIf;
	// End Peripherals
	
	If EventName = "Write_InventoryConsumptionOrder"
		Or EventName = "Write_TransferOrder"
		Or EventName = "Write_ByAssemblyDisassemblyOrder"
		Or EventName = "Write_InventoryConsumption"
		Or EventName = "Write_InventoryTransfer"
		Or EventName = "Write_AssemblyFromComponents"
		Or EventName = "Write_OtherGoodsRecordingAsReceived"
		Or EventName = "Write_OrderOfMaterialsForProduction"
		Or EventName = "Write_MaterialTransferToProduction" 
		Or EventName = "Write_MovementOfProductsAndMaterials"
		Or EventName = "Write_RMOrder"
		Or EventName = "Write_ProductionOrder"
		Or EventName = "Write_ProductionStages"
		Or EventName = "Write_GoodsIssueNote"
		Or EventName = "Write_GoodsReceiptNote"
		Or EventName = "Accept_FormOfCreatedDocuments" Then
		
		UpdateListOfRequestsForRegistrationOnServer();
		
		If ValueIsFilled(References) And ListReferencesForRegistration.Count() = 0
				And (
					EventName = "Write_InventoryConsumption"
					Or EventName = "Write_InventoryTransfer"
					Or EventName = "Write_AssemblyFromComponents"
					Or EventName = "Write_MaterialTransferToProduction"
					Or EventName = "Write_MovementOfProductsAndMaterials"
					Or EventName = "Accept_FormOfCreatedDocuments")
				And Parameter.IdOfOwnerSForm = UUID Then
			Close();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.LogOfInternalDocuments.Form.InternalDocumentsForRegistration.Item.Organization.OnChange");
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	WarehouseWhenChangedOnServer();
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	ManagerForChangesOnServer();
EndProcedure

&AtClient
Procedure TheConditionOfTheDocumentsWhenYouChange(Item)
	
	RowFilter = New Structure;
	
	If Not IsBlankString(InvoiceStatus) Then
		RowFilter.Insert("InvoiceStatus", Number(InvoiceStatus));
	EndIf;
	If Not IsBlankString(GoodsIssueNoteState) Then
		RowFilter.Insert("GoodsIssueNoteState", Number(GoodsIssueNoteState));
	EndIf;
	If Not IsBlankString(GoodsReceiptNoteState) Then
		RowFilter.Insert("GoodsReceiptNoteState", Number(GoodsReceiptNoteState));
	EndIf;
	
	Items.ListReferencesForRegistration.RowFilter = New FixedStructure(RowFilter);
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure HelpTextFilterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure();
	FormParameters.Insert("AvailableBusinessTransactionsAndDocuments", PlaceBusinessTransactionsAndDocumentsInTemporaryStorage());
	FormParameters.Insert("SettingsKey", PurposeUseKey);
	FormParameters.Insert("FormKey", DefaultFormAssignmentKey());
	
	OpenForm("Catalog.BusinessTransactionsSettings.Form.FormOfFilterSetting",
		FormParameters,,,,,
		New CallbackDescription("EstablishSelectionsForBusinessTransactionsAndDocuments", 
		ThisObject));
	
EndProcedure

&AtClient
Procedure EstablishSelectionsForBusinessTransactionsAndDocuments(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(ValueSelected) = Type("String") Then
		StandardProcessing = False;
		
		AddressOfAvailableBusinessTransactionsAndDocuments = ValueSelected;
		
		SelectionOperationTypeSelectionProcessingServer(AddressOfAvailableBusinessTransactionsAndDocuments);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure HyperlinkInternalDocumentsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.OpenLog(LogParameters());
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RegisterByOrders(Command)
	
	Var ErrorList;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.LogOfInternalDocuments.Form.InternalDocumentsForRegistration.Command.RegisterByOrders");
	
	SelectedRows = Items.ListReferencesForRegistration.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(
		SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	GroupingOrders = InvoicesClient.DataForPlacingOrders(ListReferencesForRegistration,
		SelectedRows, "BusinessOperation,Warehouse,Sender,Recipient,Department",
		ErrorList, "Object.ListReferencesForRegistration", BusinessTransactionsAndDocuments);
	
	CommonClientServer.ReportErrorsToUser(ErrorList);
	
	If ValueIsFilled(GroupingOrders) Then
		
		ProcedureParameters = New Structure();
		ProcedureParameters.Insert("GroupingOrders", GroupingOrders);
		ProcedureParameters.Insert("FormParametersForCreatedDocuments", FormParametersForCreatedDocuments());
		ProcedureParameters.Insert("ErrorField", "Object.ListReferencesForRegistration");

		JobDescription = NStr("vi = 'Tạp chí chứng từ nội bộ: Thi hành lệnh';
								|ru = 'Журнал внутренних документов: Оформление по заказам';
								|en = 'Journal of internal document: Registration by orders'; fa = 'Journal of internal document: Registration by orders';
								|it = 'Il registro di documenti interni: Registrazione in base agli ordini';
								|pl = 'Dziennik dokumentów wewnętrznych: Sporządzenie zgodnie z zamówieniami';
								|tr = 'Dahili belgeler günlüğü: Siparişlere göre düzenleme'");
		
		TimeConsumingOperation = PerformActionsInBackground(
			HowToIssueInvoicesForOrders(),
			ProcedureParameters,
			JobDescription);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation,
			New CallbackDescription("PerformActionsInBackgroundCompletion", ThisObject), IdleParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure IssueOnShipmentAcceptance(Command)
	
	Var ErrorList;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.LogOfInternalDocuments.Form.InternalDocumentsForRegistration.Command.IssueOnShipmentAcceptance");
	
	SelectedRows = Items.ListReferencesForRegistration.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(
		SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	GroupingOrders = InvoicesClient.DataForProcessingOrders(ListReferencesForRegistration,
		SelectedRows, "BusinessOperation,Warehouse,Sender,Recipient",
		ErrorList, "Object.ListReferencesForRegistration", BusinessTransactionsAndDocuments);
	
	CommonClientServer.ReportErrorsToUser(ErrorList);
	
	If ValueIsFilled(GroupingOrders) Then
		
		ProcedureParameters = New Structure();
		ProcedureParameters.Insert("GroupingOrders", GroupingOrders);
		ProcedureParameters.Insert("FormParametersForCreatedDocuments", FormParametersForCreatedDocuments());
		ProcedureParameters.Insert("ErrorField", "Object.ListReferencesForRegistration");

		JobDescription = NStr("vi = 'Nhật ký chứng từ nội bộ: lập chứng từ cho xuất hàng/nhập hàng';
								|ru = 'Журнал внутренних документов: Оформление по отгрузке/приемке';
								|en = 'Journal of internal documents: Registration of shipment/receipt'; fa = 'Journal of internal documents: Registration of shipment/receipt';
								|it = 'Il registro di documenti interni: Registrazione in base alla spedizione/accettazione';
								|pl = 'Dziennik dokumentów wewnętrznych: Sporządzenie zgodnie z wysyłką/przyjęciem';
								|tr = 'Dahili belgeler günlüğü: Sevkiyat / kabule göre düzenleme'");
		
		TimeConsumingOperation = PerformActionsInBackground(
			HowToIssueInvoicesForOrders_(),
			ProcedureParameters,
			JobDescription);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation,
			New CallbackDescription("PerformActionsInBackgroundCompletion", ThisObject), IdleParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RegisterDiscrepancyCertificate(Command)
	
	Var ErrorList;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.LogOfInternalDocuments.Form.InternalDocumentsForRegistration.Command.RegisterDiscrepancyCertificate");
	
	SelectedRows = Items.ListReferencesForRegistration.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(
		SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	Orders = New Array;
	Invoices = New Array;
	For Each RowID In SelectedRows Do
		
		String = ListReferencesForRegistration.FindByID(RowID);
		ErrorText = "";
		
		If TypeOf(String.Ref) = Type("DocumentRef.TransferOrder") Then
			If String.InvoiceStatus = 1 Then
				ErrorText = NStr("vi = 'Đối với lệnh %1, không thể lập biên bản chênh lệch, bởi vì không có hóa đơn nào.';
								|ru = 'Для распоряжения %1 невозможно оформить акт о расхождениях, т.к. нет ни одной накладной.';
								|en = 'Cannot prepare a discrepancy report for the %1 reference as there are no invoices.'; fa = 'Cannot prepare a discrepancy report for the %1 reference as there are no invoices.';
								|it = 'Per la disposizione %1 è impossibile emettere un atto di divergenze, poiché non c''è alcun documento di trasporto.';
								|pl = 'Dla zamówienia %1 jest niemożliwie zarejestrować protokół o odchyleniu, ponieważ nie ma ani jednej faktury.';
								|tr = 'Emir için %1 bir tutarsızlık raporu hazırlamak imkansızdır, çünkü hiç bir irsaliye mevcut değildir.'");
				ErrorText = StrTemplate(ErrorText, String.Ref);
			Else
				Orders.Add(String.Ref);
			EndIf;
		ElsIf TypeOf(String.Ref) = Type("DocumentRef.InventoryTransfer") Then
			Invoices.Add(String.Ref);
		Else
			ErrorText = NStr("vi = 'Đối với lệnh %1, không thể lập biên bản chênh lệch, bởi vì nó không phải là chứng từ điều chuyển hàng hóa nội bộ.';
							|ru = 'Для распоряжения %1 невозможно оформить акт о расхождениях, т.к. оно не является перемещением товаров.';
							|en = 'Cannot prepare a discrepancy report for the %1 reference as it is not a goods transfer.'; fa = 'Cannot prepare a discrepancy report for the %1 reference as it is not a goods transfer.';
							|it = 'Per la disposizione %1 è impossibile emettere un atto di divergenze, poiché essa non fa parte di movimentazione delle merci.';
							|pl = 'Dla zamówienia %1 jest niemożliwie zarejestrować protokół o odchyleniu, ponieważ ono nie jest przemieszczeniem towarów.';
							|tr = 'Emir için %1 bir tutarsızlık raporu hazırlamak imkansızdır, çünkü mal transferi değildir.'");
			ErrorText = StrTemplate(ErrorText, String.Ref);
		EndIf;
		
		If Not IsBlankString(ErrorText) Then
			CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration", ErrorText, Undefined);
		EndIf;
	EndDo;
	
	If ValueIsFilled(Invoices) Or ValueIsFilled(Orders) Then
	
		ProcedureParameters = New Structure();
		ProcedureParameters.Insert("Invoices", Invoices);
		ProcedureParameters.Insert("Orders",    Orders);
		ProcedureParameters.Insert("FormParametersForCreatedDocuments", FormParametersForCreatedDocuments(True));
		ProcedureParameters.Insert("ErrorField", "Object.ListReferencesForRegistration");

		JobDescription = NStr("vi = 'Nhật ký chứng từ nội bộ: Lập biên bản chênh lệch';
								|ru = 'Журнал внутренних документов: Оформление актов о расхождениях';
								|en = 'Journal of internal documents: Registration of discrepancy reports'; fa = 'Journal of internal documents: Registration of discrepancy reports';
								|it = 'Il registo di documenti interni: Registrazione di atti sulle discrepanze';
								|pl = 'Dziennik dokumentów wewnętrznych: Sporządzenie protokołów o odchyleniu';
								|tr = 'Dahili belgeler günlüğü: Tutarsızlık raporu düzenleme'");
		
		TimeConsumingOperation = PerformActionsInBackground(
			HowToIssueActsOnDiscrepancies(),
			ProcedureParameters,
			JobDescription);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation,
			New CallbackDescription("PerformActionsInBackgroundCompletion", ThisObject), IdleParameters);
		
	ElsIf Items.ListReferencesForRegistration.SelectedRows.Count() > 1 Then
		
		ErrorText = NStr("vi = 'Chưa chọn chứng từ nào mà có thể lập biên bản chênh lệch.';
						|ru = 'Не выбрано ни одного документа, для которого можно было бы оформить акт о расхождениях.';
						|en = 'No documents are selected for which a discrepancy report can be created.'; fa = 'No documents are selected for which a discrepancy report can be created.';
						|it = 'Non è stato selezionato alcun documento, per il quale è possibile emettere un atto di divergenze.';
						|pl = 'Nie wybrano ani jednego dokumentu, dla którego można byłoby zarejestrować protokół o odchyleniu.';
						|tr = 'Tutarsızlık raporu düzenlemenin mümkün olacağı hiçbir belge seçilmedi.'");
		CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration", ErrorText, Undefined);
		
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(ErrorList);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.LogOfInternalDocuments.Form.InternalDocumentsForRegistration.Command.Refresh");
	
	UpdateListOfRequestsForRegistrationOnServer();
	
EndProcedure

&AtClient
Procedure ExecutionState(Command)
	
	If Items.ListReferencesForRegistration.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Không một dòng nào được chọn. Thực thi lệnh là không thể.';
								|ru = 'Не выделено ни одной строки. Выполнение команды невозможно.';
								|en = 'No lines are selected. Cannot execute the command.'; fa = 'No lines are selected. Cannot execute the command.';
								|it = 'Nessuna riga selezionata. Il comando non può essere eseguito.';
								|pl = 'Nie wybrano ani jednego wierszu. Wykonanie polecenia jest niemożliwe.';
								|tr = 'Hiçbir satır vurgulanmadı. Komut çalıştırılamıyor.'"));
	Else
		DocumentsList = New ValueList;
		For Each Id In Items.ListReferencesForRegistration.SelectedRows Do
			TableRow = ListReferencesForRegistration.FindByID(Id);
			If TypeOf(TableRow.Ref) = Type("DocumentRef.InventoryConsumptionOrder")
				Or TypeOf(TableRow.Ref) = Type("DocumentRef.InventoryConsumption")
				Or TypeOf(TableRow.Ref) = Type("DocumentRef.OrderOfMaterialsForProduction")
				Or TypeOf(TableRow.Ref) = Type("DocumentRef.RMOrder")
				Or TypeOf(TableRow.Ref) = Type("DocumentRef.TransferOrder")
				Or TypeOf(TableRow.Ref) = Type("DocumentRef.InventoryTransfer")
				Or TypeOf(TableRow.Ref) = Type("DocumentRef.ByAssemblyDisassemblyOrder")
				Or TypeOf(TableRow.Ref) = Type("DocumentRef.AssemblyFromComponents") Then
				DocumentsList.Add(TableRow.Ref);
			EndIf;
		EndDo;
		
		If DocumentsList.Count() = 0 Then
			ShowMessageBox(, NStr("vi = 'Đối với chứng từ đã chọn, không hỗ trợ báo cáo. Không thể thực hiện lệnh.';
									|ru = 'Для выбранных документов отчет не поддерживается. Выполнение команды невозможно.';
									|en = 'Report is not supported for the selected documents. Cannot run the command.'; fa = 'Report is not supported for the selected documents. Cannot run the command.';
									|it = 'Il report non è supportato per i documenti selezionati. Il comando non può essere eseguito.';
									|pl = 'Dla wybranych dokumentów raport nie jest obsługiwany. Wykonanie polecenia jest niemożliwe.';
									|tr = 'Rapor, seçilen belgeler için desteklenmiyor. Komut çalıştırılamıyor.'"));
			Return;
		EndIf;
		
		OpenForm("Report.DocumentFulfillmentStatus.Form.ReportForm",
			New Structure("IncomingDocuments", DocumentsList));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region ExecutingCommandsInBackground

&AtClient
Procedure PerformActionsInBackgroundCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf Result.Status = "Error" Then
		ShowMessageBox(, Result.BriefErrorDescription);
	Else
		BackgroundExecutionResult = GetFromTempStorage(Result.ResultAddress);
		ParametersOfCreatedDocuments = BackgroundExecutionResult.ParametersOfCreatedDocuments;
		InvoicesClient.OpenFormForCreatedDocuments(ParametersOfCreatedDocuments, ThisObject);
		CommonClientServer.ReportErrorsToUser(BackgroundExecutionResult.ErrorList);
	EndIf;
	
EndProcedure

&AtServer
Function PerformActionsInBackground(Action, ProcedureParameters, JobDescription)
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	
	If Action = HowToIssueInvoicesForOrders_() Then
		
		Return TimeConsumingOperations.ExecuteInBackground(
			"InvoicesServer.IssueInvoicesForOrdersInBackground_",
			ProcedureParameters,
			ExecutionParameters);
		
	ElsIf Action = HowToIssueInvoicesForOrders() Then
	
		Return TimeConsumingOperations.ExecuteInBackground(
			"InvoicesServer.IssueInvoicesForOrdersInBackground",
			ProcedureParameters,
			ExecutionParameters);
			
	ElsIf Action = HowToIssueActsOnDiscrepancies() Then
	
		Return TimeConsumingOperations.ExecuteInBackground(
			"InvoicesServer.IssueReportsOnDiscrepanciesInBackground",
			ProcedureParameters,
			ExecutionParameters);
			
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function HowToIssueInvoicesForOrders_()
	
	Return "HowToIssueInvoicesForOrders_";
	
EndFunction

&AtClientAtServerNoContext
Function HowToIssueInvoicesForOrders()
	
	Return "HowToIssueInvoicesForOrders";
	
EndFunction

&AtClientAtServerNoContext
Function HowToIssueActsOnDiscrepancies()
	
	Return "HowToIssueActsOnDiscrepancies";
	
EndFunction

#EndRegion

#Region FormSettingsItem

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListReferencesForRegistration.Date", "ListReferencesForRegistrationDate");
	
EndProcedure

&AtServer
Procedure ConfigureFormByRightsAndFunctionalOptions()
	
	Items.ListReferencesForRegistrationExecutionState.Visible = AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus);
	
	If Not GetFunctionalOption("UseWarehouseManagemantSystemForGoodsIssue")
		Or Not AccessRight("Read", Metadata.AccumulationRegisters.GoodsForIssue) Then
		Items.GoodsIssueNoteState.Visible = False;
		Items.ListOfOrdersForProcessingTheStateOfTheExpenditureOrder.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseWarehouseManagemantSystemForGoodsReceipt")
		Or Not AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive) Then
		Items.GoodsReceiptNoteState.Visible = False;
		Items.ListOfOrdersForProcessingTheStatusOfTheReceiptOrder.Visible = False;
	EndIf;
	
	If Items.GoodsIssueNoteState.Visible Or Items.GoodsReceiptNoteState.Visible Then
		InvoicesServer.FillInInvoiceStates(Items.InvoiceStatus.ChoiceList);
		InvoicesServer.FillOrderStates(Items.GoodsIssueNoteState.ChoiceList);
		InvoicesServer.FillOrderStates(Items.GoodsReceiptNoteState.ChoiceList);
		
		AvailabilityOfDiscrepancyCertificates = GetFunctionalOption("UseNonConformanceCertificatesFollowingTransfer")
			And AccessRight("Insert", Metadata.Documents.DiscrepancyReportFollowingTransfer);
	Else
		InvoicesServer.FillInInvoiceStates(Items.InvoiceStatus.ChoiceList, True);
		
		Items.ListOfOrdersForRegistrationIssueOnShipmentAcceptance.Visible = False;
		AvailabilityOfDiscrepancyCertificates = False;
		
		Items.ListReferencesForRegistrationRegisterByOrders.Title = NStr("vi = 'Lập chứng từ';
																		|ru = 'Оформить';
																		|en = 'Register'; fa = 'ثبات';
																		|it = 'Preparare';
																		|pl = 'Register';
																		|tr = 'Düzenle'");
		Items.Move(Items.DocumentTeamGroup, Items.AGroupOfStateDocuments);
	EndIf;
	
	If ValueIsFilled(References) Then
		Items.GroupFilters.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailability()
	
	HaveRightsToCreate = BusinessTransactionsAndDocuments.FindRows(New Structure("Filter, AccessRightInsert", True, True)).Count() > 0;
	
	Items.ListReferencesForRegistrationRegisterByOrders.Enabled = HaveRightsToCreate;
	Items.ListOfOrdersForRegistrationIssueOnShipmentAcceptance.Enabled = HaveRightsToCreate;
	
	Items.ListOfOrdersForRegistrationIssueAReportOnDiscrepancies.Visible = AvailabilityOfDiscrepancyCertificates
		And BusinessTransactionsAndDocuments.FindRows(New Structure("Filter, DocumentType", True, Type("DocumentRef.InventoryTransfer"))).Count() > 0;
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	BarcodingOfPrintFormsServerCall.LinkToListItemByBarcode(
		Barcode, BusinessTransactionsAndDocuments.Unload());
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		
		Ref = ReferencesArrray[0];
		
		Found4 = ListReferencesForRegistration.FindRows(New Structure("Ref", Ref));
		If ValueIsFilled(Found4) Then
			Items.ListReferencesForRegistration.CurrentRow = Found4[0].GetID();
		EndIf;
		ShowValue(Undefined, Ref);
		
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

&AtServer
Procedure SelectionOperationTypeSelectionProcessingServer(AddressOfBusinessTransactionsAndDocuments)
	
	VTBusinessTransactionsAndDocumentTypes = GetFromTempStorage(AddressOfBusinessTransactionsAndDocuments);
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	TMCommonUse.FillInSelectionsAccordingToTableOfBusinessTransactionsAndDocumentTypes(VTBusinessTransactionsAndDocumentTypes, FilterBusinessTransactions, FilterDocumentTypes);
	
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes);
	
EndProcedure

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "InternalInventoryTransfers";
	
EndFunction

&AtServer
Function PlaceBusinessTransactionsAndDocumentsInTemporaryStorage()
	Return PutToTempStorage(BusinessTransactionsAndDocuments.Unload(), UUID);
EndFunction

&AtClient
Function LogParameters()
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",	Organization);
	QuickFilterStructure.Insert("Warehouse",		Warehouse);
	QuickFilterStructure.Insert("Manager",	Manager);
	QuickFilterStructure.Insert("FilterDocumentTypes",			FilterDocumentTypes);
	QuickFilterStructure.Insert("FilterBusinessTransactions",	FilterBusinessTransactions);
	
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure",	QuickFilterStructure);
	LogParameters.Insert("WorkplaceName",			"LogOfInternalDocuments");
	LogParameters.Insert("FormAssignmentKey",		PurposeUseKey);
	LogParameters.Insert("JournalSynonym",				NStr("vi = 'Chứng từ nội bộ';
																|ru = 'Внутренние документы';
																|en = 'Internal documents'; fa = 'اسناد داخلی';
																|it = 'Documenti interni';
																|pl = 'Dokumenty wewnętrzne';
																|tr = 'Dahili belgeler'"));
	
	Return LogParameters;
	
EndFunction

Procedure ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes)
	
	DefaultTitle = NStr("vi = 'Chứng từ nội bộ (cần lập)';
						|ru = 'Внутренние документы (к оформлению)';
						|en = 'Issue internal documents'; fa = 'صدور اسناد داخلی';
						|it = 'Documenti interni (per formalizzazione)';
						|pl = 'Dokumenty na rozchód materiałów  (do wystawienia)';
						|tr = 'Dahili belgeler (düzenlenecek)'");
	WorkplaceData = TMCommonUse.WorkplaceData(VTBusinessTransactionsAndDocumentTypes,
		DefaultFormAssignmentKey(), DefaultTitle);
	
	Title = WorkplaceData.WorkplaceTitle;
	If Title <> DefaultTitle Then
		Title = Title + " " + NStr("vi = '(để lập)';
									|ru = '(к оформлению)';
									|en = '(for registration)'; fa = '(for registration)';
									|it = '(per formalizzazione)';
									|pl = '(do rejestracji)';
									|tr = '(düzenlenecek)'");
	EndIf;
	
	GenerateQueryTexts();
	UpdateListOfRequestsForRegistrationOnServer();
	
	SetVisibilityAvailability();
	
	TMCommonUse.FormInscriptionSelection(Items.HelpTextFilter.Title,
		BusinessTransactionsAndDocuments, FilterDocumentTypes, FilterBusinessTransactions);
	
EndProcedure

#Region SavedFormSettings

&AtServer
Procedure RestoreSettings(Var_Parameters)
	
	If Var_Parameters.Property("QuickFilterStructure") Then
		FillPropertyValues(ThisForm, FormSettings(Var_Parameters.QuickFilterStructure));
		
		UseSettingsUpload = Var_Parameters.UseDownloadOfSavedSettings;
		ExcludeProperties_            = "Organization, Warehouse, Manager";
	Else
		UseSettingsUpload = True;
		ExcludeProperties_            = "";
	EndIf;
	
	If UseSettingsUpload Then
		SettingsFromStorage = Common.CommonSettingsStorageLoad("DataProcessor.LogOfInternalDocuments.Form.InternalDocumentsForRegistration", PurposeUseKey);
	
		If TypeOf(SettingsFromStorage) = Type("Structure") Then
			FillPropertyValues(ThisForm, FormSettings(SettingsFromStorage),, ExcludeProperties_);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	Common.CommonSettingsStorageSave("DataProcessor.LogOfInternalDocuments.Form.InternalDocumentsForRegistration",
		PurposeUseKey, FormSettings(ThisForm));
	
EndProcedure

&AtServer
Function FormSettings(SettingsSource)
	
	AttributesToSaveNames =
		"Organization,
		|Warehouse,
		|Manager,
		|InvoiceStatus,
		|GoodsIssueNoteState,
		|GoodsReceiptNoteState,
		|FilterBusinessTransactions,
		|FilterDocumentTypes";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, SettingsSource);
	
	Return Settings;
	
EndFunction

#EndRegion

&AtServer
Procedure UpdateListOfRequestsForRegistrationOnServer()
	
	If Items.ListReferencesForRegistration.CurrentRow <> Undefined Then
		CurrentDocument = ListReferencesForRegistration.FindByID(Items.ListReferencesForRegistration.CurrentRow).Ref;
	Else
		CurrentDocument = Undefined;
	EndIf;
	
	Query = New Query(StatusCalculationQueryText);
	FilterParameters = InvoicesServer.OrderSelectionParameters(Organization,, Warehouse, FilterBusinessTransactions, Manager);
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	Query.TempTablesManager = New TempTablesManager;
	
	OrderTypes = New Array;
	OrderTypes.Add(Type("DocumentRef.InventoryConsumptionOrder"));
	OrderTypes.Add(Type("DocumentRef.TransferOrder"));
	OrderTypes.Add(Type("DocumentRef.ByAssemblyDisassemblyOrder"));
	OrderTypes.Add(Type("DocumentRef.OrderOfMaterialsForProduction"));
	OrderTypes.Add(Type("DocumentRef.RMOrder"));
	OrderTypes.Add(Type("DocumentRef.ProductionStage2_2"));
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("Organization",       CompaniesList.UnloadValues());
	Query.SetParameter("Warehouse",             Warehouse);
	Query.SetParameter("Manager",          Manager);
	Query.SetParameter("BusinessTransaction",       FilterBusinessTransactions.UnloadValues());
	Query.SetParameter("OrderTypes",       OrderTypes);
	Query.SetParameter("References",      References.UnloadValues());
	
	Query.Execute();
	
	Query.Text = TextOfDirectiveListRequest;
	Query.SetParameter("SelectByOrder", ValueIsFilled(References));
	Query.SetParameter("ActsOfDivergenceAreAvailable", AvailabilityOfDiscrepancyCertificates);
	
	Query.Text = TextOfDirectiveListRequest;
	
	SetPrivilegedMode(True);
	ListReferencesForRegistration.Load(Query.Execute().Unload());
	SetPrivilegedMode(False);
	
	If CurrentDocument <> Undefined Then
		Found4 = ListReferencesForRegistration.FindRows(New Structure("Ref", CurrentDocument));
		If ValueIsFilled(Found4) Then
			Items.ListReferencesForRegistration.CurrentRow = Found4[0].GetID();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	SetSelectionByOrganization();
	
	GenerateQueryTexts();
	UpdateListOfRequestsForRegistrationOnServer();
	
EndProcedure

&AtServer
Procedure SetSelectionByOrganization()

	CompaniesList.Clear();
	If ValueIsFilled(Organization) Then
		CompaniesList.LoadValues(Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Organization));
		CompaniesList.Add(Organization);
	EndIf;
	
EndProcedure

&AtServer
Procedure WarehouseWhenChangedOnServer()
	
	GenerateQueryTexts();
	UpdateListOfRequestsForRegistrationOnServer();
	
EndProcedure

&AtServer
Procedure ManagerForChangesOnServer()
	
	GenerateQueryTexts();
	UpdateListOfRequestsForRegistrationOnServer();
	
EndProcedure

&AtServer
Procedure GenerateQueryTexts()
	
	FilterParameters = InvoicesServer.OrderSelectionParameters(Organization,, Warehouse, FilterBusinessTransactions, Manager);
	
	Package = New Array;
	Selection = New Array;
	States1 = InvoicesServer.StatesByBusinessTransactions(FilterBusinessTransactions.UnloadValues());
	For Each KZ In States1 Do
		Package.Add(InvoicesServer.StateRequestText(KZ.Key, FilterParameters, KZ.Value));
		
		If KZ.Key = "StatesOfSpendingOrders" Then
			Selection.Add(
			"SELECT
			|	StatesOfSpendingOrders.ReferenceOrder AS ReferenceOrder,
			|	StatesOfSpendingOrders.Warehouse AS Warehouse,
			|	StatesOfSpendingOrders.Warehouse AS Sender,
			|	CASE
			|		WHEN VALUETYPE(StatesOfSpendingOrders.ReferenceOrder) = TYPE(Document.InventoryConsumptionOrder)
			|			OR VALUETYPE(StatesOfSpendingOrders.ReferenceOrder) = TYPE(Document.RMOrder)
			|			THEN UNDEFINED
			|		ELSE StatesOfSpendingOrders.Recipient
			|	END AS Recipient,
			|	CASE
			|		WHEN VALUETYPE(StatesOfSpendingOrders.ReferenceOrder) = TYPE(Document.ProductionStage2_2)
			|			THEN VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
			|		WHEN VALUETYPE(StatesOfSpendingOrders.ReferenceOrder) = TYPE(Document.RMOrder)
			|			THEN VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
			|		WHEN TRUE
			|			THEN NULL
			|	END AS BusinessTransaction,
			|	CASE
			|		WHEN VALUETYPE(StatesOfSpendingOrders.ReferenceOrder) IN (&OrderTypes)
			|			THEN 0
			|		ELSE 4
			|	END AS InvoiceStatus,
			|	StatesOfSpendingOrders.State AS StateOfSpendingOrder,
			|	CASE
			|		WHEN CatWarehousesRecipient.Ref IS NULL
			|				OR CASE
			|					WHEN VALUETYPE(StatesOfSpendingOrders.ReferenceOrder) = TYPE(Document.TransferOrder)
			|						THEN CAST(StatesOfSpendingOrders.ReferenceOrder AS Document.TransferOrder).GoodsReceiptOption
			|					WHEN VALUETYPE(StatesOfSpendingOrders.ReferenceOrder) = TYPE(Document.ByAssemblyDisassemblyOrder)
			|						THEN CAST(StatesOfSpendingOrders.ReferenceOrder AS Document.ByAssemblyDisassemblyOrder).GoodsReceiptOption
			|					WHEN VALUETYPE(StatesOfSpendingOrders.ReferenceOrder) = TYPE(Document.ProductionStage2_2)
			|						THEN CAST(StatesOfSpendingOrders.ReferenceOrder AS Document.ProductionStage2_2).GoodsReceiptOption
			|				END = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
			|			THEN 4
			|		ELSE 0
			|	END AS StatusOfTheReceiptOrder,
			|	TRUE AS ShippingSlip,
			|	FALSE AS ReceivingDocument
			|FROM
			|	TTStateOfSpendingOrders AS StatesOfSpendingOrders
			|		LEFT JOIN Catalog.Warehouses AS CatWarehousesRecipient
			|		ON (CatWarehousesRecipient.Ref = StatesOfSpendingOrders.Recipient)
			|			AND (CatWarehousesRecipient.UseWarehouseManagemantSystemForGoodsReceipt)
			|			AND (CatWarehousesRecipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDayStart)");
		ElsIf KZ.Key = "StatesOfIncomingOrders" Then
			Selection.Add(
			"SELECT
			|	StatesOfIncomingOrders.ReferenceOrder AS ReferenceOrder,
			|	StatesOfIncomingOrders.Warehouse AS Warehouse,
			|	CASE
			|		WHEN VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.OtherGoodsRecordingAsReceived)
			|			THEN UNDEFINED
			|		ELSE StatesOfIncomingOrders.Sender
			|	END AS Sender,
			|	StatesOfIncomingOrders.Warehouse AS Recipient,
			|	CASE
			|		WHEN VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.ProductionStage2_2)
			|			THEN StatesOfIncomingOrders.BusinessTransaction
			|		WHEN TRUE
			|			THEN NULL
			|	END AS BusinessTransaction,
			|	CASE
			|		WHEN VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) IN (&OrderTypes)
			|			THEN 0
			|		ELSE 4
			|	END AS InvoiceStatus,
			|	CASE
			|		WHEN CatWarehousesSender.Ref IS NULL
			|				OR CASE
			|					WHEN VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.AssemblyFromComponents)
			|						THEN CASE
			|								WHEN CAST(StatesOfIncomingOrders.ReferenceOrder AS Document.AssemblyFromComponents).ByAssemblyDisassemblyOrder = VALUE(Document.ByAssemblyDisassemblyOrder.EmptyRef)
			|									THEN UNDEFINED
			|								ELSE CAST(StatesOfIncomingOrders.ReferenceOrder AS Document.AssemblyFromComponents).GoodsReceiptOption
			|							END
			|					WHEN VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.MovementOfProductsAndMaterials)
			|						THEN CAST(StatesOfIncomingOrders.ReferenceOrder AS Document.MovementOfProductsAndMaterials).GoodsReceiptOption
			|				END = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
			|			THEN 4
			|		ELSE 0
			|	END AS StateOfSpendingOrder,
			|	StatesOfIncomingOrders.State AS StatusOfTheReceiptOrder,
			|	FALSE AS ShippingSlip,
			|	TRUE AS ReceivingDocument
			|FROM
			|	TTStateOfIncomingOrders AS StatesOfIncomingOrders
			|		LEFT JOIN Catalog.Warehouses AS CatWarehousesSender
			|		ON (CatWarehousesSender.Ref = StatesOfIncomingOrders.Sender)
			|			AND (CatWarehousesSender.UseWarehouseManagemantSystemForGoodsIssue)
			|			AND (CatWarehousesSender.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDayStart)
			|WHERE
			|	VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) <> TYPE(Document.TransferOrder)
			|	AND VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) <> TYPE(Document.InventoryTransfer)
			|	AND NOT (VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.OrderOfMaterialsForProduction)
			|			AND CAST(StatesOfIncomingOrders.ReferenceOrder AS Document.OrderOfMaterialsForProduction).ProductionManagement2_2)
			|	AND NOT (VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.MovementOfProductsAndMaterials)
			|			AND CAST(StatesOfIncomingOrders.ReferenceOrder AS Document.MovementOfProductsAndMaterials).BusinessOperation IN(
			|						VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom),
			|						VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom),
			|						VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom),
			|						VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProducts),
			|						VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices)))
			|
			|UNION ALL
			|
			|SELECT
			|	StatesOfIncomingOrders.ReferenceOrder,
			|	StatesOfIncomingOrders.Sender,
			|	StatesOfIncomingOrders.Sender,
			|	StatesOfIncomingOrders.Warehouse,
			|	NULL,
			|	CASE
			|		WHEN VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) IN (&OrderTypes)
			|			THEN 0
			|		ELSE 4
			|	END,
			|	CASE
			|		WHEN CatWarehousesSender.Ref IS NULL
			|				OR CASE
			|					WHEN VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.InventoryTransfer)
			|						THEN CASE
			|								WHEN NOT CAST(StatesOfIncomingOrders.ReferenceOrder AS Document.InventoryTransfer).TransferAgainstOrders
			|									THEN UNDEFINED
			|								ELSE CAST(StatesOfIncomingOrders.ReferenceOrder AS Document.InventoryTransfer).GoodsReceiptOption
			|							END
			|					WHEN VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.MovementOfProductsAndMaterials)
			|						THEN CAST(StatesOfIncomingOrders.ReferenceOrder AS Document.MovementOfProductsAndMaterials).GoodsReceiptOption
			|				END = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
			|			THEN 4
			|		ELSE 0
			|	END,
			|	StatesOfIncomingOrders.State,
			|	TRUE,
			|	FALSE
			|FROM
			|	TTStateOfIncomingOrders AS StatesOfIncomingOrders
			|		LEFT JOIN Catalog.Warehouses AS CatWarehousesSender
			|		ON (CatWarehousesSender.Ref = StatesOfIncomingOrders.Sender)
			|			AND (CatWarehousesSender.UseWarehouseManagemantSystemForGoodsIssue)
			|			AND (CatWarehousesSender.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDayStart)
			|WHERE
			|	VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.TransferOrder)
			|		OR VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.InventoryTransfer)
			|	OR (VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.OrderOfMaterialsForProduction)
			|			AND CAST(StatesOfIncomingOrders.ReferenceOrder AS Document.OrderOfMaterialsForProduction).ProductionManagement2_2)
			|	OR (VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) = TYPE(Document.MovementOfProductsAndMaterials)
			|			AND CAST(StatesOfIncomingOrders.ReferenceOrder AS Document.MovementOfProductsAndMaterials).BusinessOperation IN(
			|						VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom),
			|						VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom),
			|						VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom),
			|						VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProducts),
			|						VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices)))
			|");
		ElsIf KZ.Key = "MovementStates" Then
			Selection.Add(
			"SELECT
			|	MovementStates.ReferenceOrder AS ReferenceOrder,
			|	DocTransferOrder.SourceWarehouse AS Warehouse,
			|	DocTransferOrder.SourceWarehouse AS Sender,
			|	DocTransferOrder.DestinationWarehouse AS Recipient,
			|	NULL AS BusinessTransaction,
			|	MovementStates.State AS InvoiceStatus,
			|	CASE
			|		WHEN CatWarehousesSender.Ref IS NULL
			|			THEN 4
			|		WHEN MovementStates.State = 1
			|			THEN 1
			|		ELSE 0
			|	END AS StateOfSpendingOrder,
			|	CASE
			|		WHEN CatWarehousesRecipient.Ref IS NULL
			|				OR DocTransferOrder.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
			|			THEN 4
			|		WHEN MovementStates.State = 1
			|			THEN 1
			|		ELSE 0
			|	END AS StatusOfTheReceiptOrder,
			|	TRUE AS ShippingSlip,
			|	FALSE AS ReceivingDocument
			|FROM
			|	TTMovementStates AS MovementStates
			|		LEFT JOIN Document.TransferOrder AS DocTransferOrder
			|		ON MovementStates.ReferenceOrder = DocTransferOrder.Ref
			|		LEFT JOIN Catalog.Warehouses AS CatWarehousesSender
			|		ON (CatWarehousesSender.Ref = DocTransferOrder.SourceWarehouse)
			|			AND (CatWarehousesSender.UseWarehouseManagemantSystemForGoodsIssue)
			|			AND (CatWarehousesSender.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDayStart)
			|		LEFT JOIN Catalog.Warehouses AS CatWarehousesRecipient
			|		ON (CatWarehousesRecipient.Ref = DocTransferOrder.DestinationWarehouse)
			|			AND (CatWarehousesRecipient.UseWarehouseManagemantSystemForGoodsReceipt)
			|			AND (CatWarehousesRecipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDayStart)");
		ElsIf KZ.Key = "AssemblyStates" Then
			Selection.Add(
			"SELECT
			|	AssemblyStates.ReferenceOrder AS ReferenceOrder,
			|	DocByAssemblyDisassemblyOrder.Warehouse AS Warehouse,
			|	DocByAssemblyDisassemblyOrder.Warehouse AS Sender,
			|	DocByAssemblyDisassemblyOrder.Warehouse AS Recipient,
			|	NULL AS BusinessTransaction,
			|	AssemblyStates.State AS InvoiceStatus,
			|	CASE
			|		WHEN CatWarehousesSender.Ref IS NULL
			|			THEN 4
			|		WHEN AssemblyStates.State = 1
			|			THEN 1
			|		ELSE 0
			|	END AS StateOfSpendingOrder,
			|	CASE
			|		WHEN CatWarehousesRecipient.Ref IS NULL
			|				OR DocByAssemblyDisassemblyOrder.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
			|			THEN 4
			|		WHEN AssemblyStates.State = 1
			|			THEN 1
			|		ELSE 0
			|	END AS StatusOfTheReceiptOrder,
			|	TRUE AS ShippingSlip,
			|	TRUE AS ReceivingDocument
			|FROM
			|	TTStatesOfAssemblies AS AssemblyStates
			|		LEFT JOIN Document.ByAssemblyDisassemblyOrder AS DocByAssemblyDisassemblyOrder
			|		ON AssemblyStates.ReferenceOrder = DocByAssemblyDisassemblyOrder.Ref
			|		LEFT JOIN Catalog.Warehouses AS CatWarehousesSender
			|		ON (CatWarehousesSender.Ref = DocByAssemblyDisassemblyOrder.Warehouse)
			|			AND (CatWarehousesSender.UseWarehouseManagemantSystemForGoodsIssue)
			|			AND (CatWarehousesSender.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDayStart)
			|		LEFT JOIN Catalog.Warehouses AS CatWarehousesRecipient
			|		ON (CatWarehousesRecipient.Ref = DocByAssemblyDisassemblyOrder.Warehouse)
			|			AND (CatWarehousesRecipient.UseWarehouseManagemantSystemForGoodsReceipt)
			|			AND (CatWarehousesRecipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDayStart)");
		ElsIf KZ.Key = "StatesOfDomesticConsumption" Then
			Selection.Add(
			"SELECT
			|	StatesOfDomesticConsumption.ReferenceOrder AS ReferenceOrder,
			|	StatesOfDomesticConsumption.Warehouse AS Warehouse,
			|	StatesOfDomesticConsumption.Warehouse AS Sender,
			|	UNDEFINED AS Recipient,
			|	CASE
			|		WHEN VALUETYPE(StatesOfDomesticConsumption.ReferenceOrder) = TYPE(Document.RMOrder)
			|			THEN VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
			|		WHEN TRUE
			|			THEN NULL
			|	END AS BusinessTransaction,
			|	StatesOfDomesticConsumption.State AS InvoiceStatus,
			|	CASE
			|		WHEN CatWarehousesSender.Ref IS NULL
			|			THEN 4
			|		WHEN StatesOfDomesticConsumption.State = 1
			|			THEN 1
			|		ELSE 0
			|	END AS StateOfSpendingOrder,
			|	4 AS StatusOfTheReceiptOrder,
			|	TRUE AS ShippingSlip,
			|	FALSE AS ReceivingDocument
			|FROM
			|	TTStateOfInternalConsumption AS StatesOfDomesticConsumption
			|		LEFT JOIN Catalog.Warehouses AS CatWarehousesSender
			|		ON (CatWarehousesSender.Ref = StatesOfDomesticConsumption.Warehouse)
			|			AND (CatWarehousesSender.UseWarehouseManagemantSystemForGoodsIssue)
			|			AND (CatWarehousesSender.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDayStart)");
		ElsIf KZ.Key = "StatesOfTransfersToProduction" Then
			Selection.Add(
			"SELECT
			|	StatesOfTransfersToProduction.ReferenceOrder AS ReferenceOrder,
			|	StatesOfTransfersToProduction.Warehouse AS Warehouse,
			|	StatesOfTransfersToProduction.Warehouse AS Sender,
			|	StatesOfTransfersToProduction.Recipient AS Recipient,
			|	CASE
			|		WHEN VALUETYPE(StatesOfTransfersToProduction.ReferenceOrder) = TYPE(Document.ProductionStage2_2)
			|			THEN VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
			|		WHEN TRUE
			|			THEN NULL
			|	END AS BusinessTransaction,
			|	StatesOfTransfersToProduction.State AS InvoiceStatus,
			|	CASE
			|		WHEN CatWarehousesSender.Ref IS NULL
			|			THEN 4
			|		WHEN StatesOfTransfersToProduction.State = 1
			|			THEN 1
			|		ELSE 0
			|	END AS StateOfSpendingOrder,
			|	4 AS StatusOfTheReceiptOrder,
			|	TRUE AS ShippingSlip,
			|	FALSE AS ReceivingDocument
			|FROM
			|	TTStatesOfTransfersToProduction AS StatesOfTransfersToProduction
			|		LEFT JOIN Catalog.Warehouses AS CatWarehousesSender
			|		ON (CatWarehousesSender.Ref = StatesOfTransfersToProduction.Warehouse)
			|			AND (CatWarehousesSender.UseWarehouseManagemantSystemForGoodsIssue)
			|			AND (CatWarehousesSender.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDayStart)");
		ElsIf KZ.Key = "StatesOfTransfersFromProduction" Then
			Selection.Add(
			"SELECT
			|	StatesOfTransfersFromProduction.ReferenceOrder AS ReferenceOrder,
			|	StatesOfTransfersFromProduction.Warehouse AS Warehouse,
			|	StatesOfTransfersFromProduction.Sender AS Sender,
			|	StatesOfTransfersFromProduction.Warehouse AS Recipient,
			|	StatesOfTransfersFromProduction.BusinessTransaction AS BusinessTransaction,
			|	StatesOfTransfersFromProduction.State AS InvoiceStatus,
			|	4 AS StateOfSpendingOrder,
			|	CASE
			|		WHEN CatWarehousesRecipient.Ref IS NULL
			|				OR DocProductionStage.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
			|			THEN 4
			|		WHEN StatesOfTransfersFromProduction.State = 1
			|			THEN 1
			|		ELSE 0
			|	END AS StatusOfTheReceiptOrder,
			|	FALSE AS ShippingSlip,
			|	TRUE AS ReceivingDocument
			|FROM
			|	TTTransfersStateOfTransferFromProduction AS StatesOfTransfersFromProduction
			|		LEFT JOIN Document.ProductionStage2_2 AS DocProductionStage
			|		ON StatesOfTransfersFromProduction.ReferenceOrder = DocProductionStage.Ref
			|		LEFT JOIN Catalog.Warehouses AS CatWarehousesRecipient
			|		ON (CatWarehousesRecipient.Ref = StatesOfTransfersFromProduction.Warehouse)
			|			AND (CatWarehousesRecipient.UseWarehouseManagemantSystemForGoodsReceipt)
			|			AND (CatWarehousesRecipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDayStart)");
		EndIf;
		
	EndDo;
	
	StatusCalculationQueryText = StrConcat(Package, Common.QueryBatchSeparator());
	
	TextOfDirectiveListRequest =
		StrReplace(
		"SELECT
		|	NestedQuery.ReferenceOrder AS Ref,
		|	NestedQuery.Warehouse AS Warehouse,
		|	NestedQuery.Sender AS Sender,
		|	NestedQuery.Recipient AS Recipient,
		|	NestedQuery.BusinessTransaction AS BusinessTransaction,
		|	MAX(NestedQuery.InvoiceStatus) AS InvoiceStatus,
		|	MAX(NestedQuery.StateOfSpendingOrder) AS GoodsIssueNoteState,
		|	MAX(NestedQuery.StatusOfTheReceiptOrder) AS GoodsReceiptNoteState,
		|	MAX(NestedQuery.ShippingSlip) AS ShippingSlip,
		|	MAX(NestedQuery.ReceivingDocument) AS ReceivingDocument
		|INTO TTRemainsOfState
		|FROM
		|	QueryTextNested AS NestedQuery
		|WHERE
		|	NOT &SelectByOrder OR NestedQuery.ReferenceOrder IN (&References)
		|
		|GROUP BY
		|	NestedQuery.ReferenceOrder,
		|	NestedQuery.Warehouse,
		|	NestedQuery.Sender,
		|	NestedQuery.Recipient,
		|	NestedQuery.BusinessTransaction
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentsRegistry.IBDocumentNumber AS Number,
		|	ISNULL(DocumentsRegistry.IBDocumentDate, DATETIME(1,1,1)) AS Date,
		|	VALUETYPE(DocumentsRegistry.Ref) AS TypeOfOrder_,
		|	RemnantsOfState.InvoiceStatus AS InvoiceStatus,
		|	RemnantsOfState.GoodsIssueNoteState AS GoodsIssueNoteState,
		|	RemnantsOfState.GoodsReceiptNoteState AS GoodsReceiptNoteState,
		|	RemnantsOfState.ShippingSlip AS ShippingSlip,
		|	RemnantsOfState.ReceivingDocument AS ReceivingDocument,
		|	DocumentsRegistry.Organization AS Organization,
		|	DocumentsRegistry.Department AS Department,
		|	RemnantsOfState.Warehouse AS Warehouse,
		|	RemnantsOfState.Sender AS Sender,
		|	RemnantsOfState.Recipient AS Recipient,
		|	DocumentsRegistry.EmployeeResponsible AS Manager,
		|	ISNULL(RemnantsOfState.BusinessTransaction, DocumentsRegistry.BusinessOperation) AS BusinessOperation,
		|	RemnantsOfState.Ref AS Ref,
		|	DocumentsRegistry.Comment AS Comment
		|FROM
		|	TTRemainsOfState AS RemnantsOfState
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|		ON RemnantsOfState.Ref = DocumentsRegistry.Ref
		|			AND (NOT DocumentsRegistry.AdditionalRecord)
		|WHERE
		|	CASE WHEN VALUETYPE(RemnantsOfState.Ref) IN(
		|					TYPE(Document.TransferOrder),
		|					TYPE(Document.InventoryTransfer)) THEN
		|				NOT &SelectByWarehouse OR RemnantsOfState.Warehouse IN (&Warehouse)
		|				AND (&ActsOfDivergenceAreAvailable
		|					OR RemnantsOfState.InvoiceStatus <> 0 AND RemnantsOfState.InvoiceStatus <> 4
		|					OR RemnantsOfState.GoodsIssueNoteState <> 0 AND RemnantsOfState.GoodsIssueNoteState <> 4)
		|			WHEN VALUETYPE(RemnantsOfState.Ref) = TYPE(Document.OrderOfMaterialsForProduction)
		|					AND CAST(RemnantsOfState.Ref AS Document.OrderOfMaterialsForProduction).ProductionManagement2_2 THEN
		|				NOT &SelectByWarehouse OR RemnantsOfState.Warehouse IN (&Warehouse)
		|			WHEN VALUETYPE(RemnantsOfState.Ref) = TYPE(Document.MovementOfProductsAndMaterials)
		|					AND CAST(RemnantsOfState.Ref AS Document.MovementOfProductsAndMaterials).BusinessOperation IN(
		|						VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom),
		|						VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom),
		|						VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom),
		|						VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProducts),
		|						VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices)) THEN
		|				NOT &SelectByWarehouse OR RemnantsOfState.Warehouse IN (&Warehouse)
		|			ELSE		
		|				TRUE
		|			END
		|
		|ORDER BY
		|	Date", "QueryTextNested", "(" + StrConcat(Selection, TMCommonUse.QuerySeparatorInJoin()) + ")");
	
EndProcedure

&AtClient
Function FormParametersForCreatedDocuments(ActOfDivergenceIsDrawnUp = False)
	
	FormParameters = New Structure("DataKey, VisibleColumns, UpdateEvents",
		PurposeUseKey, New Array, New Array);
	
	FormParameters.VisibleColumns.Add("Number");
	FormParameters.VisibleColumns.Add("Date");
	FormParameters.VisibleColumns.Add("ValueType");
	FormParameters.VisibleColumns.Add("BusinessOperation");
	FormParameters.VisibleColumns.Add("Organization");
	FormParameters.VisibleColumns.Add("Warehouse");
	FormParameters.VisibleColumns.Add("Department");
	If ActOfDivergenceIsDrawnUp
		Or BusinessTransactionsAndDocuments.FindRows(New Structure("Filter, StatusesAreUsed", True, True)).Count() <> 0 Then
		FormParameters.VisibleColumns.Add("Status");
	EndIf;
	FormParameters.VisibleColumns.Add("More");
	
	FormParameters.UpdateEvents.Add("Write_DiscrepancyReportFollowingTransfer");
	FormParameters.UpdateEvents.Add("Write_InventoryConsumption");
	FormParameters.UpdateEvents.Add("Write_InventoryTransfer");
	FormParameters.UpdateEvents.Add("Write_AssemblyFromComponents");
	FormParameters.UpdateEvents.Add("Write_MaterialTransferToProduction");
	FormParameters.UpdateEvents.Add("Write_MovementOfProductsAndMaterials");
	Return FormParameters;
	
EndFunction

#EndRegion

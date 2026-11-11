
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	If IsBlankString(Parameters.FormAssignmentKey) Then
		PurposeUseKey = DefaultFormAssignmentKey();
	Else
		PurposeUseKey = Parameters.FormAssignmentKey;
	EndIf;
	
	If Parameters.Property("References") Then
		References.LoadValues(Parameters.References);
	EndIf;
	
	If Parameters.Property("CurrentPageName") And ValueIsFilled(Parameters.CurrentPageName) Then
		Items.Pages.CurrentPage = Items[Parameters.CurrentPageName];
		CurrentItem = Items.Pages.CurrentPage;
	EndIf;
	
	RestoreSettings(Parameters);
	SetSelectionByOrganization();
	SetSelectionByWarehouse();
	
	FillInDocumentMetadata();
	ConfigureFormByRightsAndFunctionalOptions();
	
	UpdateTransfers = True;
	UpdateReceipts = True;
	UpdatingReportsIsRequired = True;
	UpdateReturns = True;
	
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
		Return;
	EndIf;
	// End Peripherals
	
	If EventName = "Write_SubcontractOrder2_5" Then
		
		UpdateTransfers    = True;
		UpdateReceipts = True;
		UpdatingReportsIsRequired      = True;
		
	ElsIf EventName = "Accept_FormOfCreatedDocuments"
		Or EventName = "SetDeleteMark_JournalOfDocumentsTransferredToProcessing2_5"
		Or EventName = "CancellationOf_JournalOfDocumentsOfTransferToProcessing2_5"
		Or EventName = "ToCarryOut_JournalOfDocumentsOfTransferToProcessing2_5"
		Or EventName = "IssuedSalesDocument"
			And (Source.FormName = "DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.DocumentsList"
				Or Source.FormName = "DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices") Then
		
		If Source.FormName = "DataProcessor.LogOfSalesDocuments.Form.FormCreatedDocuments"
			Or EventName = "IssuedSalesDocument"
				And (Source.FormName = "DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.DocumentsList"
					Or Source.FormName = "DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices") Then
			
			UpdateTransfers    = True;
			
		ElsIf Source.FormName = "CommonForm.CreatedDocumentForm" Then
			
			UpdatingReportsIsRequired      = True;
			UpdateReceipts = True;
			
		Else
			
			UpdateTransfers    = True;
			UpdateReceipts = True;
			UpdatingReportsIsRequired      = True;
		
		EndIf;
		
	ElsIf EventName = "Write_TransferOfGoodsToBailee" Then
		
		UpdateTransfers    = True;
		
	ElsIf EventName = "Write_ReceiptOfGoodsFromCustodian" Then
		
		UpdateReceipts = True;
		UpdateReturns    = True;
		
	ElsIf EventName = "Write_SubcontractorReport2_5" Then
		
		UpdatingReportsIsRequired      = True;
		
	ElsIf EventName = "Write_GoodsIssueNote" Then
		
		UpdateTransfers    = True;
		
	ElsIf EventName = "Write_GoodsReceiptNote" Then
		
		UpdateReceipts = True;
		UpdateReturns    = True;
		
	ElsIf EventName = "ChangingPage_ToDesignTransfer" Then
		
		CurrentItem = Items[Parameter];
		
	Else
		Return;
	EndIf;
	
	RefreshCurPage();
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	// If the selections are already loaded from the parameters
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
	
	If Not IsBlankString(StatusOfTheTransferInvoice) Then
		RowFilter.Insert("InvoiceStatus", Number(StatusOfTheTransferInvoice));
	EndIf;
	If Not IsBlankString(GoodsIssueNoteState) Then
		RowFilter.Insert("GoodsIssueNoteState", Number(GoodsIssueNoteState));
	EndIf;
	
	Items.ListTransferReferences.RowFilter = New FixedStructure(RowFilter);
	
EndProcedure

&AtClient
Procedure ReceiptStatusWhenChanged(Item)
	
	RowFilter = New Structure;
	
	If Not IsBlankString(ReceiptInvoiceStatus) Then
		RowFilter.Insert("InvoiceStatus", Number(ReceiptInvoiceStatus));
	EndIf;
	If Not IsBlankString(GoodsReceiptNoteState) Then
		RowFilter.Insert("GoodsReceiptNoteState", Number(GoodsReceiptNoteState));
	EndIf;
	
	Items.ListReceiptReferences.RowFilter = New FixedStructure(RowFilter);
	
EndProcedure

&AtClient
Procedure ReportStateOnChange(Item)
	
	If Not IsBlankString(StateOfReportInvoice) Then
		RowFilter = New FixedStructure("InvoiceStatus", Number(StateOfReportInvoice));
	Else
		RowFilter = Undefined;
	EndIf;
	
	Items.ListReportReferences.RowFilter = RowFilter;
	
EndProcedure

&AtClient
Procedure StatusReturnsOnChange(Item)
	
	If Not IsBlankString(StatusOfTheOrderForAcceptanceReturn) Then
		RowFilter = New FixedStructure("GoodsReceiptNoteState", Number(StatusOfTheOrderForAcceptanceReturn));
	Else
		RowFilter = Undefined;
	EndIf;
	
	Items.ListReferencesForRawMaterialReturn.RowFilter = RowFilter;
	
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

#Region ApplyAppearance

&AtClient
Procedure PlaceTransfersOnOrders(Command)
	
	SelectedRows = Items.ListTransferReferences.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ByNotes = False;
	
	FillInListOfOrdersAccordingToForm("ListTransferReferences");
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", ThisForm);
	AdditionalParameters.Insert("ReferencesArrray", ListOfOrders_);
	AdditionalParameters.Insert("ByNotes", ByNotes);
	AdditionalParameters.Insert("Warehouse", DedicatedWarehouses("ListTransferReferences"));
	AdditionalParameters.Insert("ObjectKey", "DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices/CurrentData");
	
	SalesClient.GenerateSetOfDocumentsChallenge(Undefined, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure MakeTransfersByShipment(Command)
	
	Var ErrorList;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices.Command.MakeTransfersByShipment");
	
	SelectedRows = Items.ListTransferReferences.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	WarehouseOrders =
		InvoicesClient.DataForProcessingOrders(
			ListTransferReferences,
			SelectedRows,
			"Warehouse",
			ErrorList,
			"Object.ListTransferReferences",
			MetadataOfDocuments);
	
	If ValueIsFilled(WarehouseOrders) Then
		
		ParametersOfCreatedDocuments = InvoicesServerCall.IssueInvoicesForOrders_(
											WarehouseOrders,
											FormParametersForCreatedDocuments(),
											ErrorList,
											"Object.ListTransferReferences");
											
		InvoicesClient.OpenFormForCreatedDocuments(ParametersOfCreatedDocuments, ThisForm);
		
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(ErrorList);
	
EndProcedure

&AtClient
Procedure IssueReceiptsForOrders(Command)
	
	Var ErrorList;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices.Command.IssueReceiptsForOrders");
	
	SelectedRows = Items.ListReceiptReferences.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	WarehouseOrders =
		InvoicesClient.DataForPlacingOrders(
			ListReceiptReferences,
			SelectedRows,
			"Warehouse",
			ErrorList,
			"Object.ListReceiptReferences",
			MetadataOfDocuments);
	
	If ValueIsFilled(WarehouseOrders) Then
		
		ParametersOfCreatedDocuments =
			InvoicesServerCall.IssueInvoicesForOrders(
				WarehouseOrders,
				FormParametersForCreatedDocuments(),
				ErrorList,
				"Object.ListReceiptReferences");
		
		InvoicesClient.OpenFormForCreatedDocuments(ParametersOfCreatedDocuments, ThisForm);
		
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(ErrorList);
	
EndProcedure

&AtClient
Procedure IssueReceiptsForAcceptance(Command)
	
	Var ErrorList;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices.Command.IssueReceiptsForAcceptance");
	
	SelectedRows = Items.ListReceiptReferences.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(
		SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	WarehouseOrders = InvoicesClient.DataForProcessingOrders(
								ListReceiptReferences,
								SelectedRows,
								"Warehouse",
								ErrorList,
								"Object.ListReceiptReferences",
								MetadataOfDocuments);
	
	If ValueIsFilled(WarehouseOrders) Then
		
		ParametersOfCreatedDocuments = InvoicesServerCall.IssueInvoicesForOrders_(
											WarehouseOrders,
											FormParametersForCreatedDocuments(),
											ErrorList,
											"Object.ListReceiptReferences");
											
		InvoicesClient.OpenFormForCreatedDocuments(ParametersOfCreatedDocuments, ThisForm);
		
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(ErrorList);
	
EndProcedure

&AtClient
Procedure RegisterReports(Command)
	
	Var ErrorList;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices.Command.RegisterReports");
	
	SelectedRows = Items.ListReportReferences.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	Orders      = New Array;
	Overall      = New Array;
	For Each RowID In SelectedRows Do
		
		Data = ListReportReferences.FindByID(RowID);
		
		If TypeOf(Data.Ref) = Type("DocumentRef.SubcontractOrder2_5") Then
			Orders.Add(Data.Ref);
		ElsIf TypeOf(Data.Ref) = Type("CatalogRef.CounterpartyContracts") Then
			
			HeaderAttributes = New Structure("Organization, Partner, Contract", Data.Organization, Data.Partner, Data.Contract);
			Overall.Add(
				New Structure("ByOrders, HeaderAttributes, AnArrayOfOrders", False, HeaderAttributes, New Array));
				
		EndIf;
		
	EndDo;
	
	If Overall.Count() = 1 And Not ValueIsFilled(Orders) Then
		
		ParametersOfCreatedDocuments = New Structure("FormName, Parameters");
		ParametersOfCreatedDocuments.FormName = "Document.SubcontractorReport2_5.ObjectForm";
		ParametersOfCreatedDocuments.Parameters = New Structure("Basis", Overall[0]);
		InvoicesClient.OpenFormForCreatedDocuments(ParametersOfCreatedDocuments, ThisForm);
		
	Else
		
		If Not Overall.Count() = 0 Then
			ErrorText =
				NStr("vi = 'Không hỗ trợ lập báo cáo theo nhiều doanh nghiệp\gười nhận gia công\hợp đồng.';
					|ru = 'Оформление отчета по нескольким организациям\переработчика\договорам не поддерживается.';
					|en = 'Report registration for several companies\of subcontractor\contracts is unavailable.'; fa = 'Report registration for several companies\of subcontractor\contracts is unavailable.';
					|it = 'Formalizzazione report per diverse aziende \elaboratore\accordi non supportata.';
					|pl = 'Tworzenie raportu według kilku firm\przetwórcy\umów nie jest obsługiwane.';
					|tr = 'Birden fazla iş yeri\fason üretici\sözleşme için rapor düzenleme desteklenmemektedir.'");
			CommonClientServer.AddUserError(ErrorList, "Object.ListReportReferences",
				ErrorText, Undefined);
		EndIf;
		
		If ValueIsFilled(Orders) Then
			
			ParametersOfCreatedDocuments =
				GenerateReportsOnServer(
					Orders,
					FormParametersForCreatedDocuments("RegisterReports"),
					ErrorList,
					"Object.ListReportReferences");
			
			InvoicesClient.OpenFormForCreatedDocuments(ParametersOfCreatedDocuments, ThisForm);
			
		Else
			
			ErrorText = NStr("vi = 'Chưa chọn chứng từ nào mà có thể lập bảng kê của người nhận gia công.';
							|ru = 'Не выбрано ни одного документа, для которого можно было бы оформить отчет переработчика.';
							|en = 'No document for which ""Subcontracting services notification received"" can be registered is selected.'; fa = 'No document for which ""Subcontracting services notification received"" can be registered is selected.';
							|it = 'Non è stato selezionato un singolo documento per il quale potrebbe essere formalizzato un report del subfornitore.';
							|pl = 'Nie wybrano ani jednego dokumentu, dla którego można by złożyć raport przetwornika.';
							|tr = 'Alınan fason hizmetleri bildiriminin düzenlenebileceği herhangi bir belge seçilmedi.'");
			CommonClientServer.AddUserError(ErrorList, "ListReportReferences", ErrorText, Undefined);
		
		EndIf;
		
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(ErrorList);
	
EndProcedure

&AtClient
Procedure IssueRefundsOnAcceptance(Command)
	
	Var ErrorList;
	
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
		
		ParametersOfCreatedDocuments = InvoicesServerCall.IssueInvoicesForOrders_(
											WarehouseOrders,
											FormParametersForCreatedDocuments(),
											ErrorList,
											"Object.ListReferencesForRawMaterialReturn");
											
		InvoicesClient.OpenFormForCreatedDocuments(ParametersOfCreatedDocuments, ThisForm);
		
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(ErrorList);
	
EndProcedure

#EndRegion

#Region SettingUpSetOfDocuments

&AtClient
Procedure GetASetOfDocumentsSetup(Command)
	
	ObjectKey = "DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices/CurrentData";
	
	Notification = New CallbackDescription("GetASetOfDocumentsSetupCompletion", ThisObject, ObjectKey);
	
	FormParameters = SalesServerCall.GetASetOfDocumentsSetup(ObjectKey);
	OpenForm(
		"DataProcessor.LogOfSalesDocuments.Form.ParametersOfSalesDocumentCreation",
		FormParameters,
		ThisForm,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure GetASetOfDocumentsSetupCompletion(Result, ObjectKey) Export 
	
	If Result <> Undefined Then
		SalesServerCall.SaveDocumentSetSettings(Result, ObjectKey);
	EndIf;

EndProcedure

#EndRegion

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
		"DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices.Command.UpdateTheTransferOrderList");
	
	UpdateListOfTransferRequestsOnServer();
	
EndProcedure

&AtClient
Procedure UpdateTheListOfOrdersForAdmission(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices.Command.UpdateTheListOfOrdersForAdmission");
	
	UpdateListOfReceiptRequestsOnServer();
	
EndProcedure

&AtClient
Procedure UpdateTheListOfOrdersForReports(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices.Command.UpdateTheListOfOrdersForReports");
	
	UpdateListOfLinksToReportsOnServer();
	
EndProcedure

&AtClient
Procedure UpdateTheListOfOrdersForTheReturnOfRawMaterials_3(Command)
	
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
	
	////
	
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Tiếp nhận có mức độ ưu tiên cao';
							|ru = 'Поступление имеет высокий приоритет';
							|en = 'Receipt is in high priority'; fa = 'Receipt is in high priority';
							|it = 'L''arrivo ha una priorità elevata';
							|pl = 'Wpłata ma wysoki priorytet';
							|tr = 'Giriş, yüksek önceliğe sahiptir'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListReceiptReferences.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListReceiptReferences.Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = HighestPriority;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.HighPriorityDocument);
	
	////
	
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
	
	////
	
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Tiếp nhận có mức độ ưu tiên thấp';
							|ru = 'Поступление имеет низкий приоритет';
							|en = 'Receipt is in low priority'; fa = 'Receipt is in low priority';
							|it = 'L''arrivo ha una priorità bassa';
							|pl = 'Wpłata ma niski priorytet';
							|tr = 'Giriş, düşük önceliğe sahiptir'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListReceiptReferences.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListReceiptReferences.Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = LowestPriority;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.LowDocumentPriority);
	
	////
	
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
	
	////
	
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Báo cáo không có lệnh';
							|ru = 'Отчет без распоряжения';
							|en = 'Report without reference'; fa = 'Report without reference';
							|it = 'Report senza disposizione';
							|pl = 'Raport bez zamówienia';
							|tr = 'Talimatsız rapor'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListReportReferencesTypeOfOrder_.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListReportReferences.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Undefined;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có lệnh>';
													|ru = '<без распоряжения>';
													|en = '<without reference>'; fa = '<without reference>';
													|it = '<senza disposizione>';
													|pl = '<bez zamówienia>';
													|tr = '<talimatsız>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	////
	
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Trường báo cáo không được sử dụng';
							|ru = 'Отчет поле не используется';
							|en = 'The Report field is not used'; fa = 'The Report field is not used';
							|it = 'Campo report non viene utilizzato';
							|pl = 'Raport pole nie jest używane';
							|tr = 'Rapor alanı kullanılmamaktadır'");
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListReportReferencesNumber.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListReportReferencesDate.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListReportReferencesDocumentAmount.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListReportReferencesCurrency.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListReportReferencesCounterparty.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListReportReferencesDepartment.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListReportReferencesManager.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListReportReferencesMore.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListReportReferencesRef.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListReportReferences.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Undefined;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	////
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListTransferReferences.Date",     "ListTransferReferencesDate");
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListReceiptReferences.Date",  "ListReceiptReferencesDate");
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListReportReferences.Date",       "ListReportReferencesDate");
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListReferencesForRawMaterialReturn.Date", "ListReferencesForRawMaterialReturnDate");
	
	////
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListTransferReferencesOrganization.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListReceiptReferencesOrganization.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListReportReferencesOrganization.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListReferencesForRawMaterialReturnOrganization.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Organization");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	////
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListTransferReferencesWarehouse.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListReceiptReferencesWarehouse.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListReferencesForRawMaterialReturnWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	////
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListTransferReferencesManager.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListReceiptReferencesManager.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListReportReferencesManager.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListReferencesForRawMaterialReturnManager.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Manager");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtServer
Procedure ConfigureFormByRightsAndFunctionalOptions()
	
	If Not AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus) Then
		
		Items.AListOfOrdersForTheTransferExecutionState.Visible = False;
		Items.ListOfReceiptOrdersStateOfExecution.Visible = False;
		Items.AListOfOrdersOnTheReportingStatusOfImplementation.Visible = False;
		
	EndIf;
	
	If Not GetFunctionalOption("UseWarehouseManagemantSystemForGoodsIssue")
		Or Not AccessRight("Read", Metadata.AccumulationRegisters.GoodsForIssue) Then
		
		Items.ListOfTransferOrdersIssueTransfersByOrders.Title = NStr("vi = 'Lập chứng từ';
																		|ru = 'Оформить';
																		|en = 'Register'; fa = 'ثبات';
																		|it = 'Preparare';
																		|pl = 'Sporządź';
																		|tr = 'Düzenle'");
		Items.Move(Items.TransferCommandGroup, Items.TransferStatusGroup);
		
		InvoicesServer.FillInInvoiceStates(Items.StatusOfTheTransferInvoice.ChoiceList, True);
		
		Items.GoodsIssueNoteState.Visible = False;
		Items.ListOfTransferOrdersForShipmentTransfers.Visible = False;
		Items.AListOfTheOrderToTransferTheOrderStatus.Visible = False;
		
	Else
		
		InvoicesServer.FillInInvoiceStates(Items.StatusOfTheTransferInvoice.ChoiceList);
		InvoicesServer.FillOrderStates(Items.GoodsIssueNoteState.ChoiceList);
		
	EndIf;
	
	If Not GetFunctionalOption("UseWarehouseManagemantSystemForGoodsReceipt")
		Or Not AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive) Then
		
		Items.ListOfReceiptOrdersIssueReceiptsForOrders.Title = NStr("vi = 'Lập chứng từ';
																	|ru = 'Оформить';
																	|en = 'Register'; fa = 'ثبات';
																	|it = 'Preparare';
																	|pl = 'Sporządź';
																	|tr = 'Düzenle'");
		Items.Move(Items.ReceiptTeamGroup, Items.ReceiptStatusGroup);
		
		InvoicesServer.FillInInvoiceStates(Items.ReceiptInvoiceStatus.ChoiceList, True);
		
		Items.GoodsReceiptNoteState.Visible = False;
		Items.ListOfOrdersForReceiptIssueReceiptsForAcceptance.Visible = False;
		Items.AListOfOrdersOnReceiptOfTheOrderStatus.Visible = False;
		Items.RawMaterialReturnsPage.Visible =  False;
		
	Else
		
		InvoicesServer.FillInInvoiceStates(Items.ReceiptInvoiceStatus.ChoiceList);
		InvoicesServer.FillOrderStates(Items.GoodsReceiptNoteState.ChoiceList);
		InvoicesServer.FillOrderStates(Items.StatusOfTheOrderForAcceptanceReturn.ChoiceList, True);
		
	EndIf;
	
	ViewingOrders = AccessRight("View", Metadata.Documents.SubcontractOrder2_5);
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences)
		Or Not AccessRight("View", Metadata.Documents.TransferOfGoodsToBailee) 
		Or Not ViewingOrders Then
		Items.RawMaterialTransferPage.Visible = False;
	ElsIf Not AccessRight("Insert", Metadata.Documents.TransferOfGoodsToBailee) Then
		
		Items.ListOfTransferOrdersIssueTransfersByOrders.Enabled = False;
		Items.ListOfTransferOrdersForShipmentTransfers.Enabled = False;
		
	EndIf;
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.PurchaseOrders)
		Or Not AccessRight("View", Metadata.Documents.ReceiptOfGoodsFromCustodian)
		Or Not ViewingOrders Then
		Items.PageReceipts.Visible = False;
	ElsIf Not AccessRight("Insert", Metadata.Documents.ReceiptOfGoodsFromCustodian) Then
		
		Items.ListOfReceiptOrdersIssueReceiptsForOrders.Enabled = False;
		Items.ListOfOrdersForReceiptIssueReceiptsForAcceptance.Enabled = False;
		
	EndIf;
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.PurchaseOrders)
		Or Not AccessRight("View", Metadata.Documents.SubcontractorReport2_5)
		Or Not ViewingOrders Then
		Items.ReportsPage.Visible = False;
	Else
		
		ChoiceList = Items.StateOfReportInvoice.ChoiceList;
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
								|tr = 'Raporu tamamla'"), False, PictureLib.CreateInvoiceOnUninvoicedDeliveries);
		
		If Not AccessRight("Insert", Metadata.Documents.SubcontractorReport2_5) Then
			Items.ListOfOrdersForReports.Enabled = False;
		EndIf;
		
	EndIf;
	
	If Not AccessRight("View", Metadata.Documents.ReceiptOfGoodsFromCustodian) Then
		Items.RawMaterialReturnsPage.Visible = False;
	ElsIf Not AccessRight("Insert", Metadata.Documents.ReceiptOfGoodsFromCustodian) Then
		Items.ListOfOrdersForReturnOfRawMaterialsIssueReturnsOnAcceptance.Enabled = False;
	EndIf;
	
	If ValueIsFilled(References) Then
		
		Items.GroupFilters.Visible = False;
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
		
		Items.StatusOfTheTransferInvoice.TitleLocation = FormItemTitleLocation.Top;
		Items.GoodsIssueNoteState.TitleLocation = FormItemTitleLocation.Top;
		Items.ReceiptInvoiceStatus.TitleLocation = FormItemTitleLocation.Top;
		Items.GoodsReceiptNoteState.TitleLocation = FormItemTitleLocation.Top;
		
		Items.AListOfOrdersForATransferCertificate.Visible = True;
		Items.AListOfOrdersForAdmissionHelp.Visible = True;
		
		AutoTitle = False;
		Title =
			StrTemplate(
				NStr("vi = 'Chứng từ chuyển vào gia công (%1) (cần lập chứng từ)';
					|ru = 'Документы передачи в переработку (%1) (к оформлению)';
					|en = 'External subcontracting documents registration (%1)'; fa = 'External subcontracting documents registration (%1)';
					|it = 'Documenti di consegna in trasformazione (%1) (da formalizzare)';
					|pl = 'Dokumenty przekazania do przetwórstwa (%1) (do rejestracji)';
					|tr = 'Fason üretim transfer belgeleri (%1) (düzenlenecek)'"),
				Lower(Items.Pages.CurrentPage.Title));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array;
	
	If Items.Pages.CurrentPage = Items.RawMaterialTransferPage Then
		
		Managers.Add(PredefinedValue("Document.SubcontractOrder2_5.EmptyRef"));
		Managers.Add(PredefinedValue("Document.TransferOfGoodsToBailee.EmptyRef"));
		
	ElsIf Items.Pages.CurrentPage = Items.PageReceipts Then
		
		Managers.Add(PredefinedValue("Document.SubcontractOrder2_5.EmptyRef"));
		Managers.Add(PredefinedValue("Document.ReceiptOfGoodsFromCustodian.EmptyRef"));
		
	ElsIf Items.Pages.CurrentPage = Items.ReportsPage Then
		
		Managers.Add(PredefinedValue("Document.SubcontractOrder2_5.EmptyRef"));
		Managers.Add(PredefinedValue("Document.ReceiptOfGoodsFromCustodian.EmptyRef"));
		
	ElsIf Items.Pages.CurrentPage = Items.RawMaterialReturnsPage Then
	
		Managers.Add(PredefinedValue("Document.ReceiptOfGoodsFromCustodian.EmptyRef"));
		
	EndIf;
	
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		
		Ref = ReferencesArrray[0];
		If Items.Pages.CurrentPage = Items.RawMaterialTransferPage Then
			CurrentList = "ListTransferReferences";
		ElsIf Items.Pages.CurrentPage = Items.PageReceipts Then
			CurrentList = "ListReceiptReferences";
		ElsIf Items.Pages.CurrentPage = Items.ReportsPage Then
			CurrentList = "ListReportReferences";
		ElsIf Items.Pages.CurrentPage = Items.RawMaterialReturnsPage Then
			CurrentList = "ListReferencesForRawMaterialReturn";
		EndIf;
		
		Found4 = ThisForm[CurrentList].FindRows(New Structure("Ref", Ref));
		FormTable = Items[CurrentList]; // FormTable
		If ValueIsFilled(Found4) Then
			FormTable.CurrentRow = Found4[0].GetID();
		EndIf;
		ShowValue(Undefined, Ref);
		
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region ApplyAppearance

&AtClient
Function LogParameters()
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",	Organization);
	QuickFilterStructure.Insert("Warehouse",		Warehouse);
	QuickFilterStructure.Insert("Manager",	Manager);
	
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure",	QuickFilterStructure);
	LogParameters.Insert("WorkplaceName",			"DocumentsOfTransferToTollingAll2_5");
	LogParameters.Insert("FormAssignmentKey",		"SubcontractingServicesReceivedAllDocuments");
	LogParameters.Insert("JournalSynonym",				NStr("vi = 'Chứng từ chuyển giao vào gia công';
																|ru = 'Документы передачи в переработку';
																|en = 'External subcontracting — All documents'; fa = 'پیمانکاری فرعی خارجی — همه اسناد';
																|it = 'Documenti di consegna in trasformazione';
																|pl = 'Dokumenty przekazania do przetwórstwa';
																|tr = 'Fason üretim transfer belgeleri'"));
	
	Return LogParameters;
	
EndFunction

&AtClient
Procedure FillInListOfOrdersAccordingToForm(TagName)

	SelectedRows = Items[TagName].SelectedRows;
	
	ListOfOrders_.Clear();
	For Each String In SelectedRows Do
		FillPropertyValues(ListOfOrders_.Add(), Items[TagName].RowData(String));
	EndDo;
	
EndProcedure

&AtClient
Function DedicatedWarehouses(TagName)
	
	Result = New Array;
	
	SelectedRows = Items[TagName].SelectedRows;
	For Each String In SelectedRows Do
		Result.Add(Items[TagName].RowData(String).Warehouse);
	EndDo;
	
	Result = CommonClientServer.CollapseArray(Result);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region UpdateList_

&AtServer
Procedure UpdateListOfTransferRequestsOnServer()
	
	If Items.ListTransferReferences.CurrentRow <> Undefined Then
		CurrentDocument = ListTransferReferences.FindByID(Items.ListTransferReferences.CurrentRow).Ref;
	Else
		CurrentDocument = Undefined;
	EndIf;
	
	FilterParameters =
		InvoicesServer.OrderSelectionParameters(
			Organization,,
			Warehouse,
			Enums.BusinessTransactions.TransferToToller2_5,
			Manager);
	
	QueriesTexts = QueriesTexts(FilterParameters, Enums.BusinessTransactions.TransferToToller2_5);
	
	Query = New Query(QueriesTexts.StatusCalculationQueryText);
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("BusinessTransaction", Enums.BusinessTransactions.TransferToToller2_5);
	Query.SetParameter("HouseholdRegistryOperation", Enums.BusinessTransactions.TransferToToller2_5);
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("Organization", CompaniesList.UnloadValues());
	Query.SetParameter("Warehouse", WarehousesList.UnloadValues());
	Query.SetParameter("Manager", Manager);
	Query.SetParameter("References", References.UnloadValues());
	
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	
	Query.Execute();
	
	Query.Text = QueriesTexts.TextOfDirectiveListRequest;
	
	SetPrivilegedMode(True);
	DocumentsTable = Query.Execute().Unload();
	TMCommonUse.ProcessMultilingualColumnOfTableOfValues(DocumentsTable);
	ListTransferReferences.Load(DocumentsTable);
	SetPrivilegedMode(False);
	
	If CurrentDocument <> Undefined Then
		Found4 = ListTransferReferences.FindRows(New Structure("Ref", CurrentDocument));
		If ValueIsFilled(Found4) Then
			Items.ListTransferReferences.CurrentRow = Found4[0].GetID();
		EndIf;
	EndIf;
	
	UpdateTransfers = False;
	
EndProcedure

&AtServer
Procedure UpdateListOfReceiptRequestsOnServer()
	
	If Items.ListReceiptReferences.CurrentRow <> Undefined Then
		CurrentDocument = ListReceiptReferences.FindByID(Items.ListReceiptReferences.CurrentRow).Ref;
	Else
		CurrentDocument = Undefined;
	EndIf;
	
	FilterParameters =
		InvoicesServer.OrderSelectionParameters(
			Organization,,
			Warehouse,
			Enums.BusinessTransactions.ReceiptFromToller2_5,
			Manager);
	
	QueriesTexts = QueriesTexts(FilterParameters, Enums.BusinessTransactions.ReceiptFromToller2_5);
	
	Query = New Query(QueriesTexts.StatusCalculationQueryText);
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("BusinessTransaction", Enums.BusinessTransactions.ReceiptFromToller2_5);
	Query.SetParameter("HouseholdRegistryOperation", Enums.BusinessTransactions.ReceiptFromToller2_5);
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("Organization", CompaniesList.UnloadValues());
	Query.SetParameter("Warehouse", WarehousesList.UnloadValues());
	Query.SetParameter("Manager", Manager);
	Query.SetParameter("References", References.UnloadValues());
	
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	
	Query.Execute();
	
	Query.Text = QueriesTexts.TextOfDirectiveListRequest;
	
	SetPrivilegedMode(True);
	DocumentsTable = Query.Execute().Unload();
	TMCommonUse.ProcessMultilingualColumnOfTableOfValues(DocumentsTable);
	ListReceiptReferences.Load(DocumentsTable);
	SetPrivilegedMode(False);
	
	If CurrentDocument <> Undefined Then
		Found4 = ListReceiptReferences.FindRows(New Structure("Ref", CurrentDocument));
		If ValueIsFilled(Found4) Then
			Items.ListReceiptReferences.CurrentRow = Found4[0].GetID();
		EndIf;
	EndIf;
	
	UpdateReceipts = False;
	
EndProcedure

&AtServer
Procedure UpdateListOfLinksToReportsOnServer()
	
	If Items.ListReportReferences.CurrentRow <> Undefined Then
		CurrentDocument = ListReportReferences.FindByID(Items.ListReportReferences.CurrentRow).Ref;
	Else
		CurrentDocument = Undefined;
	EndIf;
	
	ProductionOperationsAtProcessor2_5 = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ProductionByToller2_5);
	
	FilterParameters =
		InvoicesServer.OrderSelectionParameters(
			Organization,,,
			ProductionOperationsAtProcessor2_5,
			Manager);
	
	QueriesTexts = QueriesTexts(FilterParameters, ProductionOperationsAtProcessor2_5);
	
	Query = New Query(QueriesTexts.StatusCalculationQueryText);
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("BusinessTransaction", ProductionOperationsAtProcessor2_5);
	Query.SetParameter("HouseholdRegistryOperation", Enums.BusinessTransactions.ProductionByToller2_5);
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("Organization", CompaniesList.UnloadValues());
	Query.SetParameter("Manager", Manager);
	Query.SetParameter("References", References.UnloadValues());
	
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	
	Query.Execute();
	
	Query.Text = QueriesTexts.TextOfDirectiveListRequest;
	
	SetPrivilegedMode(True);
	DocumentsTable = Query.Execute().Unload();
	TMCommonUse.ProcessMultilingualColumnOfTableOfValues(DocumentsTable);
	ListReportReferences.Load(DocumentsTable);
	SetPrivilegedMode(False);
	
	If CurrentDocument <> Undefined Then
		Found4 = ListReportReferences.FindRows(New Structure("Ref", CurrentDocument));
		If ValueIsFilled(Found4) Then
			Items.ListReportReferences.CurrentRow = Found4[0].GetID();
		EndIf;
	EndIf;
	
	UpdatingReportsIsRequired = False;
	
EndProcedure

&AtServer
Procedure UpdateListOfOrdersForReturnOfRawMaterialsOnServer()
	
	If Items.ListReferencesForRawMaterialReturn.CurrentRow <> Undefined Then
		CurrentDocument = ListReferencesForRawMaterialReturn.FindByID(Items.ListReferencesForRawMaterialReturn.CurrentRow).Ref;
	Else
		CurrentDocument = Undefined;
	EndIf;
	
	FilterParameters =
		InvoicesServer.OrderSelectionParameters(
			Organization,,
			Warehouse,
			Enums.BusinessTransactions.ReturnFromProcessingCompany2_5,
			Manager);
	
	QueriesTexts = QueriesTexts(FilterParameters, Enums.BusinessTransactions.ReturnFromProcessingCompany2_5);
	
	Query = New Query(QueriesTexts.StatusCalculationQueryText);
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("BusinessTransaction", Enums.BusinessTransactions.ReturnFromProcessingCompany2_5);
	Query.SetParameter("HouseholdRegistryOperation", Enums.BusinessTransactions.ReturnFromProcessingCompany2_5);
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("Organization", CompaniesList.UnloadValues());
	Query.SetParameter("Warehouse", WarehousesList.UnloadValues());
	Query.SetParameter("Manager", Manager);
	
	If ValueIsFilled(References) Then
		Query.SetParameter("References", References);
	EndIf;
	
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	
	Query.Execute();
	
	Query.Text = QueriesTexts.TextOfDirectiveListRequest;
	
	SetPrivilegedMode(True);
	DocumentsTable = Query.Execute().Unload();
	TMCommonUse.ProcessMultilingualColumnOfTableOfValues(DocumentsTable);
	ListReferencesForRawMaterialReturn.Load(DocumentsTable);
	SetPrivilegedMode(False);
	
	If CurrentDocument <> Undefined Then
		Found4 = ListReferencesForRawMaterialReturn.FindRows(New Structure("Ref", CurrentDocument));
		If ValueIsFilled(Found4) Then
			Items.ListReferencesForRawMaterialReturn.CurrentRow = Found4[0].GetID();
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
			"DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices", PurposeUseKey);
		If TypeOf(SettingsFromStorage) = Type("Structure") Then
			FillPropertyValues(ThisObject, FormSettings(SettingsFromStorage));
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	Common.CommonSettingsStorageSave("DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices",
		PurposeUseKey, FormSettings(ThisForm));
	
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
		|StatusOfTheOrderForAcceptanceReturn,
		|ReportState";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, SettingsSource);
	
	Return Settings;
	
EndFunction

#EndRegion

#Region Other

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
		CompaniesList.LoadValues(Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Organization));
		CompaniesList.Add(Organization);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionByWarehouse()
	
	WarehousesList = WarehousesServer.ListOfSubordinateWarehouses(Warehouse);
	
EndProcedure

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "SubcontractingServicesReceivedAllDocuments";
	
EndFunction

&AtServerNoContext
Function GenerateReportsOnServer(Orders, FormParametersForCreatedDocuments, ErrorList, ErrorField)
	
	ParametersOfCreatedDocuments = New Structure("FormName, Parameters");
	
	If Orders.Count() = 1 Then
		ParametersOfCreatedDocuments.FormName = "Document.SubcontractorReport2_5.ObjectForm";
		ParametersOfCreatedDocuments.Parameters = New Structure("Basis", Orders[0]);
	Else
		
		InvoicesServer.GroupDocumentsByKeyFields(Orders, "Ref");
		
		Group = New Structure("NameOfDocumentBeingProcessed, AnArrayOfOrders, PopulationFields",
			Metadata.Documents.SubcontractorReport2_5.Name, Orders, New Structure);
		
		GroupingOrders = New Array(1);
		GroupingOrders[0] = Group;
		
		CreatedDocuments = InvoicesServer.GenerateDocumentsOnOrders(GroupingOrders, ErrorList, ErrorField);
		
		If Not ValueIsFilled(CreatedDocuments) Then
			Return Undefined;
		EndIf;
		
		Owner = Users.AuthorizedUser();
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Owner, CreatedDocuments, FormParametersForCreatedDocuments.DataKey);
		SetPrivilegedMode(False);
		
		ParametersOfCreatedDocuments.FormName = "CommonForm.CreatedDocumentForm";
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
								|tr = 'Herhangi bir satır belirtilmedi. Komutun gerçekleştirilmesi mümkün değildir.'"));
	Else
		DocumentsList = New ValueList;
		For Each Id In Items[TableName].SelectedRows Do
			TableRow = FormTable.FindByID(Id);
			If TypeOf(TableRow.Ref) = Type("DocumentRef.SubcontractOrder2_5") Then
				DocumentsList.Add(TableRow.Ref);
			EndIf;
		EndDo;
		
		If DocumentsList.Count() = 0 Then
			ShowMessageBox(, NStr("vi = 'Chỉ có thể thực hiện lệnh đối với đơn hàng nhận gia công.';
									|ru = 'Выполнение команды возможно только для заказов переработчику.';
									|en = 'Command can be performed only for subcontracting purchase orders.'; fa = 'Command can be performed only for subcontracting purchase orders.';
									|it = 'L''esecuzione del comando è possibile solo per gli ordini al subfornitore.';
									|pl = 'Wykonanie polecenia jest możliwe tylko dla zamówień przetwórcy.';
									|tr = 'Komutun gerçekleştirilmesi sadece fason üretici satın alma siparişleri için mümkündür.'"));
			Return;
		EndIf;
		
		OpenForm("Report.DocumentFulfillmentStatus.Form.ReportForm",
			New Structure("IncomingDocuments", DocumentsList));
		
	EndIf;

EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices.Item.Pages.OnCurrentPageChange");
	
	RefreshCurPage();
	
EndProcedure

&AtClient
Procedure RefreshCurPage()
	
	If Items.Pages.CurrentPage = Items.RawMaterialTransferPage And UpdateTransfers Then
		
		UpdateListOfTransferRequestsOnServer();
		
	ElsIf Items.Pages.CurrentPage = Items.PageReceipts And UpdateReceipts Then
		
		UpdateListOfReceiptRequestsOnServer();
		
	ElsIf Items.Pages.CurrentPage = Items.ReportsPage And UpdatingReportsIsRequired Then
		
		UpdateListOfLinksToReportsOnServer();
		
	ElsIf Items.Pages.CurrentPage = Items.RawMaterialReturnsPage And UpdateReturns Then
		
		UpdateListOfOrdersForReturnOfRawMaterialsOnServer();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshCurPageOnServer()
	
	If Items.Pages.CurrentPage = Items.RawMaterialTransferPage And UpdateTransfers Then
		
		UpdateListOfTransferRequestsOnServer();
		
	ElsIf Items.Pages.CurrentPage = Items.PageReceipts And UpdateReceipts Then
		
		UpdateListOfReceiptRequestsOnServer();
		
	ElsIf Items.Pages.CurrentPage = Items.ReportsPage And UpdatingReportsIsRequired Then
		
		UpdateListOfLinksToReportsOnServer();
		
	ElsIf Items.Pages.CurrentPage = Items.RawMaterialReturnsPage And UpdateReturns Then
		
		UpdateListOfOrdersForReturnOfRawMaterialsOnServer();
		
	EndIf;
	
EndProcedure

&AtServer
Function QueriesTexts(FilterParameters, BusinessTransaction)
	
	QueriesTexts =
		DataProcessors.DocumentsOfTransferToTollingAll2_5.QueriesTexts(
			FilterParameters,
			BusinessTransaction,
			True,
			References);
	
	RequestTextsOfOrderList = New Array;
	RequestTextsOfOrderList.Add(QueriesTexts.TextOfDirectiveListRequest);
	RequestTextsOfOrderList.Add(
		"SELECT
		|	CASE
		|		WHEN VALUETYPE(RemnantsOfState.Ref) = TYPE(Catalog.CounterpartyContracts)
		|			THEN CatCounterpartyContracts.Number
		|		ELSE DocumentsRegistry.IBDocumentNumber
		|	END                                          AS Number,
		|	CASE
		|		WHEN VALUETYPE(RemnantsOfState.Ref) = TYPE(Catalog.CounterpartyContracts)
		|			THEN CatCounterpartyContracts.Date
		|		ELSE DocumentsRegistry.IBDocumentDate
		|	END                                          AS Date,
		|	VALUETYPE(RemnantsOfState.Ref)           AS TypeOfOrder_,
		|	RemnantsOfState.InvoiceStatus            AS InvoiceStatus,
		|	RemnantsOfState.GoodsIssueNoteState     AS GoodsIssueNoteState,
		|	RemnantsOfState.GoodsReceiptNoteState      AS GoodsReceiptNoteState,
		|	RemnantsOfState.ShippingSlip           AS ShippingSlip,
		|	RemnantsOfState.ReceivingDocument            AS ReceivingDocument,
		|	ISNULL(DocumentsRegistry.Sum, 0)            AS DocumentAmount,
		|	CASE
		|		WHEN VALUETYPE(RemnantsOfState.Ref) = TYPE(Catalog.CounterpartyContracts)
		|			THEN CatCounterpartyContracts.ARAPCurrency
		|		ELSE DocumentsRegistry.Currency
		|	END                                          AS Currency,
		|	CASE
		|		WHEN VALUETYPE(RemnantsOfState.Ref) = TYPE(Catalog.CounterpartyContracts)
		|			THEN CatCounterpartyContracts.Partner
		|		ELSE DocumentsRegistry.Partner
		|	END                                          AS Partner,
		|	CASE
		|		WHEN VALUETYPE(RemnantsOfState.Ref) = TYPE(Catalog.CounterpartyContracts)
		|			THEN CatCounterpartyContracts.Counterparty
		|		ELSE DocumentsRegistry.Counterparty.Key
		|	END                                          AS Counterparty,
		|	CASE
		|		WHEN VALUETYPE(RemnantsOfState.Ref) = TYPE(Catalog.CounterpartyContracts)
		|			THEN RemnantsOfState.Ref
		|		ELSE DocumentsRegistry.Contract
		|	END                                          AS Contract,
		|	CASE
		|		WHEN VALUETYPE(RemnantsOfState.Ref) = TYPE(Catalog.CounterpartyContracts)
		|			THEN CatCounterpartyContracts.Organization
		|		ELSE DocumentsRegistry.Organization
		|	END                                          AS Organization,
		|	CASE
		|		WHEN VALUETYPE(RemnantsOfState.Ref) = TYPE(Catalog.CounterpartyContracts)
		|			THEN CatCounterpartyContracts.Department
		|		ELSE DocumentsRegistry.Department
		|	END                                          AS Department,
		|	RemnantsOfState.Warehouse                         AS Warehouse,
		|	CASE
		|		WHEN VALUETYPE(RemnantsOfState.Ref) = TYPE(Catalog.CounterpartyContracts)
		|			THEN CatCounterpartyContracts.LineOfBusiness
		|		ELSE DocumentsRegistry.LineOfBusiness
		|	END                                          AS LineOfBusiness,
		|	CASE
		|		WHEN VALUETYPE(RemnantsOfState.Ref) = TYPE(Catalog.CounterpartyContracts)
		|			THEN CatCounterpartyContracts.Manager
		|		ELSE DocumentsRegistry.EmployeeResponsible
		|	END                                          AS Manager,
		|	RemnantsOfState.Ref                        AS Ref,
		|	ISNULL(DocumentsRegistry.More, """") AS More,
		|	&HouseholdRegistryOperation                            AS BusinessOperation,
		|	RemnantsOfState.Priority                     AS Priority
		|FROM
		|	TTRemainsOfState AS RemnantsOfState
		|	
		|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|	ON DocumentsRegistry.Ref = RemnantsOfState.Ref
		|	AND NOT DocumentsRegistry.AdditionalRecord
		|	
		|	LEFT JOIN Catalog.CounterpartyContracts AS CatCounterpartyContracts
		|	ON CatCounterpartyContracts.Ref = RemnantsOfState.Ref
		|
		|ORDER BY
		|	Date");
	
	QueriesTexts.TextOfDirectiveListRequest = StrConcat(RequestTextsOfOrderList, Common.QueryBatchSeparator());
	
	Return QueriesTexts;
	
EndFunction

&AtServer
Procedure FillInDocumentMetadata()
	
	String = MetadataOfDocuments.Add();
	String.BusinessOperation		= Enums.BusinessTransactions.TransferToToller2_5;
	String.FullDocumentName			= Metadata.Documents.TransferOfGoodsToBailee.FullName();
	String.Handler					= "TransferToToller";
	String.KeyHeaderFields			= TransferToToller.KeyFieldsOfHeader();
	String.TitleOfTheReissueForm	= NStr("vi = 'Lập lại chứng từ chuyển giao nguyên liệu cho người nhận gia công theo các lệnh đã chọn';
											|ru = 'Переоформление передачи сырья переработчику по выбранным распоряжениям';
											|en = 'Reregister ""Goods issue — Subcontracting services received"" for the selected references'; fa = 'Reregister ""Goods issue — Subcontracting services received"" for the selected references';
											|it = 'La formalizzazione sostitutiva di consegna delle materie prime al subfornitore per disposizioni selezionate';
											|pl = 'Ponowna rejestracja przesyłania surowców przetwórcy w wybranych zamówieniach';
											|tr = 'Hammaddelerin fason üreticiye transferinin seçilen talimatlara göre yeniden düzenlenmesi'");
	
	String = MetadataOfDocuments.Add();
	String.BusinessOperation		= Enums.BusinessTransactions.ReceiptFromToller2_5;
	String.FullDocumentName			= Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName();
	String.Handler					= "ReceiptFromToller";
	String.KeyHeaderFields			= ReceiptFromToller.KeyFieldsOfHeader();
	String.TitleOfTheReissueForm	= NStr("vi = 'Lập lại chứng từ tiếp nhận từ người nhận gia công theo các lệnh đã chọn';
											|ru = 'Переоформление поступления от переработчика по выбранным распоряжениям';
											|en = 'Reregister ""Goods receipt — Subcontracting services received"" for the selected references'; fa = 'Reregister ""Goods receipt — Subcontracting services received"" for the selected references';
											|it = 'La formalizzazione sostitutiva dell''arrivo dal subfornitore per disposizioni selezionate';
											|pl = 'Ponowna rejestracja wpłaty od przetwórcy w wybranych zamówieniach';
											|tr = 'Fason üreticiden girenlerin, seçilen talimatlara göre yeniden düzenlenmesi'");
	
	String = MetadataOfDocuments.Add();
	String.BusinessOperation		= Enums.BusinessTransactions.ReturnFromProcessingCompany2_5;
	String.FullDocumentName			= Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName();
	String.Handler					= "ReturnFromProcessingCompany";
	
EndProcedure

&AtClient
Function FormParametersForCreatedDocuments(CommandName = Undefined)
	
	FormParameters = New Structure("DataKey, VisibleColumns, UpdateEvents",
		PurposeUseKey, New Array, New Array);
	
	FormParameters.VisibleColumns.Add("Number");
	FormParameters.VisibleColumns.Add("Date");
	FormParameters.VisibleColumns.Add("ValueType");
	FormParameters.VisibleColumns.Add("DocumentAmount");
	FormParameters.VisibleColumns.Add("Currency");
	FormParameters.VisibleColumns.Add("Partner");
	FormParameters.VisibleColumns.Add("Counterparty");
	FormParameters.VisibleColumns.Add("Contract");
	FormParameters.VisibleColumns.Add("Organization");
	FormParameters.VisibleColumns.Add("Department");
	
	If CommandName <> "RegisterReports" Then
		FormParameters.VisibleColumns.Add("Warehouse");	
	EndIf;	
	
	FormParameters.VisibleColumns.Add("More");
	
	FormParameters.UpdateEvents.Add("Write_TransferOfGoodsToBailee");
	FormParameters.UpdateEvents.Add("Write_ReceiptOfGoodsFromCustodian");
	FormParameters.UpdateEvents.Add("Write_SubcontractorReport2_5");
	
	Return FormParameters;
	
EndFunction

#EndRegion

#EndRegion

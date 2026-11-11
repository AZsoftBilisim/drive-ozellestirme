
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	TMCommonUse.CustomizePeripherals(ThisForm);
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("Warehouse", Warehouse);
		QuickFilterStructure.Property("Organization", Organization);
		QuickFilterStructure.Property("NoteState", NoteState);
		QuickFilterStructure.Property("PurchaseState", PurchaseState);
		QuickFilterStructure.Property("PurchaseReceiptState", PurchaseReceiptState);
		QuickFilterStructure.Property("GoodsReceiptState", GoodsReceiptState);
		QuickFilterStructure.Property("Ref", References);
	EndIf;
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = TextOfRequestForListOfAcceptanceOrders();
	ListProperties.MainTable = "";
	ListProperties.DynamicDataRead = Undefined;
	Common.SetDynamicListProperties(Items.ListReceivingReferences, ListProperties);
	
	FillSelectionListsByState();
	SetDinListParameters();
#Region SelectionsWhenCreatedOnServer
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReferencesForRegistration, "Organization", Organization, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReceivingReferences, "Organization", Organization, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReceiptReferences, "Organization", Organization, QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReceivingReferences,
		"NoteState", 
		?(ValueIsFilled(NoteState), Number(NoteState), NoteState),
		QuickFilterStructure,,,
		True);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReferencesForRegistration,
		"PurchaseState", 
		?(ValueIsFilled(PurchaseState), Number(PurchaseState), PurchaseState),
		QuickFilterStructure,,,
		True);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReceiptReferences,
		"PurchaseReceiptState", 
		?(ValueIsFilled(PurchaseReceiptState), Number(PurchaseReceiptState), PurchaseReceiptState),
		QuickFilterStructure,,,
		True);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReceiptReferences,
		"GoodsReceiptState", 
		?(ValueIsFilled(GoodsReceiptState), Number(GoodsReceiptState), GoodsReceiptState),
		QuickFilterStructure,,,
		True);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReceivingReferences, 
		"Ref",
		?(Parameters.Property("CurrentPageName")
			And Parameters.CurrentPageName = "PageReceivingReferences"
			And ValueIsFilled(References), References, Undefined),
		QuickFilterStructure,,
		DataCompositionComparisonType.InList);
		
#EndRegion
	
	UseCustodyDuringPurchase = False;
	UseReceiptForMultipleOrders = GetFunctionalOption("UseReceiptForMultipleOrders");
	UsePurchaseOrders = GetFunctionalOption("UsePurchaseOrders");
	UseWarehouseManagemantSystemForGoodsReceipt = GetFunctionalOption("UseWarehouseManagemantSystemForGoodsReceipt");
	UseGoodsReceipts = GetFunctionalOption("UseUninvoicedDeliveries")
		Or GetFunctionalOption("UseGoodsInTransitFromVendors");
	UseCustodyDuringPurchase = GetFunctionalOption(
		"UseCustodyDuringPurchase");
	
	RightToAddAPurchase = AccessRight("Insert", Metadata.Documents.VendorInvoice);
	RightToAddGoodsReceiving = False;
	RightToAddGoodsReceiving = AccessRight("Insert", Metadata.Documents.GoodsReceiptForStorage);
	
	Items.AListOfOrdersForExecutionToCreateThePurchaseOfGoodsAndServices.Visible = RightToAddAPurchase;
	Items.ToArrangeThePurchaseOfGoodsAccordingToTheOrder.Visible = RightToAddAPurchase;
	Items.ListReferencesForRegistrationCurrency.Visible = GetFunctionalOption("UseMultipleCurrencies");
	
	Items.ListOfOrdersForRegistrationIssueAReportOnDiscrepancies.Visible
		= AccessRight("Insert", Metadata.Documents.DiscrepancyReportFollowingReceipt);
		
	Items.RegisterGoodsReceipt.Visible
		= AccessRight("Insert", Metadata.Documents.ReceiptOfGoodsToWarehouse);
	
	Items.PageOfTheOrderForRegistration.Visible = UsePurchaseOrders;
	Items.PageReceivingReferences.Visible = UseWarehouseManagemantSystemForGoodsReceipt;
	Items.ReceiptOrderPage.Visible = UseGoodsReceipts;
	Items.IssueWriteOffOfDiscrepanciesReceiptPurchase.Visible 
		= AccessRight("Insert",Metadata.Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase);
	
	RightToReadStateOfExecutionOfDocuments = AccessRight("Use", Metadata.Reports.DocumentFulfillmentStatus);
	Items.ListReferencesForRegistrationExecutionState.Visible = RightToReadStateOfExecutionOfDocuments;
	Items.ListOfAcceptanceOrdersExecutionStatusAcceptance.Visible = RightToReadStateOfExecutionOfDocuments;
	
	If UseCustodyDuringPurchase Then
		Items.PageOfTheOrderForRegistration.Title = NStr("vi = 'Chờ tạo chứng từ mua (nhập hàng)';
														|ru = 'К оформлению приобретения (приемки)';
														|en = 'Register by references'; fa = 'ثبت بر اساس مراجع';
														|it = 'Acquisti (accettazioni) da formalizzare';
														|pl = 'Do rejestracji zakupu (przyjęcia)';
														|tr = 'Satın alımın düzenlenmesi (kabul)'");
	EndIf;
	
	CustomizeFormByWarehouse();
	CustomizeWithLinkSeeAlso();
	SetCurrentPage();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

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
			ProcessBarcodes(TMPeripheralsClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "Write_VendorInvoice"
		Or EventName = "Write_GoodsReceiptForStorage"
		Or EventName = "Write_PurchaseOrder" Then
		
		UpdateFormTable(Items.PageOfTheOrderForRegistration, Items.ListReferencesForRegistration);
		
	EndIf;
	
	If EventName = "Write_GoodsReceiptNote"
		Or EventName = "Write_VendorInvoice"
		Or EventName = "Write_UninvoicedReceipt"
		Or EventName = "Write_GoodsReceiptForStorage"
		Or EventName = "Write_PurchaseOrder" 
		Or EventName = "Record_WriteOffOfDiscrepancies" Then
		
		UpdateFormTable(Items.ReceiptOrderPage, Items.ListReceiptReferences);
		UpdateFormTable(Items.PageReceivingReferences, Items.ListReceivingReferences);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("Warehouse", Warehouse);
		Settings.Delete("Warehouse");
		QuickFilterStructure.Property("Organization", Organization);
		Settings.Delete("Organization");
		QuickFilterStructure.Property("NoteState", NoteState);
		Settings.Delete("NoteState");
		QuickFilterStructure.Property("PurchaseState", PurchaseState);
		Settings.Delete("PurchaseState");
		QuickFilterStructure.Property("GoodsReceiptState", GoodsReceiptState);
		Settings.Delete("GoodsReceiptState");
		QuickFilterStructure.Property("PurchaseReceiptState", PurchaseReceiptState);
		Settings.Delete("PurchaseReceiptState");
	Else
		Warehouse = Settings.Get("Warehouse");
		Organization = Settings.Get("Organization");
		NoteState    = Settings.Get("NoteState");
		PurchaseState = Settings.Get("PurchaseState");
		GoodsReceiptState = Settings.Get("GoodsReceiptState");
		PurchaseReceiptState = Settings.Get("PurchaseReceiptState");
	EndIf;
	
	CustomizeFormByWarehouse();
	
	ArrayOfLists = New Array;
	ArrayOfLists.Add("ListReceivingReferences");
	ArrayOfLists.Add("ListReferencesForRegistration");
	ArrayOfLists.Add("ListReceiptReferences");
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ListForm", ThisForm);
	FilterParameters.Insert("ArrayOfLists", ArrayOfLists);
	FilterParameters.Insert("ColumnName", "Organization");
	FilterParameters.Insert("Value", Organization);
	FilterParameters.Insert("Settings", Settings);
	
	ListSelectionsClientServer.SetSelectionsByListValueWhenLoadingFromSettings(FilterParameters, QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ListReceivingReferences,
		"NoteState",
		?(ValueIsFilled(NoteState), Number(NoteState), NoteState),
		QuickFilterStructure,
		Settings,
		ValueIsFilled(NoteState),
		,
		True);
		
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ListReferencesForRegistration,
		"PurchaseState",
		?(ValueIsFilled(PurchaseState), Number(PurchaseState), PurchaseState),
		QuickFilterStructure,
		Settings,
		ValueIsFilled(PurchaseState),
		,
		True);
		
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ListReceiptReferences,
		"PurchaseReceiptState",
		?(ValueIsFilled(PurchaseReceiptState), Number(PurchaseReceiptState), PurchaseReceiptState),
		QuickFilterStructure,
		Settings,
		ValueIsFilled(PurchaseReceiptState),
		,
		True);
		
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ListReceiptReferences,
		"GoodsReceiptState",
		?(ValueIsFilled(GoodsReceiptState), Number(GoodsReceiptState), GoodsReceiptState),
		QuickFilterStructure,
		Settings,
		ValueIsFilled(GoodsReceiptState),
		,
		True);
		
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	
	CustomizeFormByWarehouse();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		ListReferencesForRegistration,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Organization));
	CommonClientServer.SetDynamicListFilterItem(
		ListReceivingReferences,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Organization));
	CommonClientServer.SetDynamicListFilterItem(
		ListReceiptReferences,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Organization));
	
	Items.ListReferencesForRegistration.SelectedRows.Clear();
	Items.ListReceivingReferences.SelectedRows.Clear();
	Items.ListReceiptReferences.SelectedRows.Clear();
	
EndProcedure

&AtClient
Procedure ListReferencesForRegistrationSelection(Item, RowSelected, Field, StandardProcessing)
	ShowValue(Undefined, Item.CurrentData.Ref);
EndProcedure

&AtClient
Procedure NoteStateOnChange(Item)
	State = ?(ValueIsFilled(NoteState), Number(NoteState), 0);
	
	CommonClientServer.SetDynamicListFilterItem(ListReceivingReferences,
		"NoteState",
		State,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(NoteState));
EndProcedure

&AtClient
Procedure PurchaseStateOnChange(Item)
	
	State = ?(ValueIsFilled(PurchaseState), Number(PurchaseState), 0);
	
	CommonClientServer.SetDynamicListFilterItem(ListReferencesForRegistration,
		"PurchaseState",
		State,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(PurchaseState));
		
EndProcedure

&AtClient
Procedure GoodsReceiptStateOnChange(Item)
	
	State = ?(ValueIsFilled(GoodsReceiptState), Number(GoodsReceiptState), 0);
	
	CommonClientServer.SetDynamicListFilterItem(ListReceiptReferences,
		"GoodsReceiptState",
		State,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(GoodsReceiptState));
	
EndProcedure

&AtClient
Procedure PurchaseReceiptStateOnChange(Item)
	
	State = ?(ValueIsFilled(PurchaseReceiptState), Number(PurchaseReceiptState), 0);
	
	CommonClientServer.SetDynamicListFilterItem(ListReceiptReferences,
		"PurchaseReceiptState",
		State,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(PurchaseReceiptState));
		
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	If CurrentPage = Items.PageOfTheOrderForRegistration Then 
		// &PerformanceMeasurement
		PerformanceMonitorClient.StartTimeMeasurement(True,
			"DataProcessor.LogOfPurchaseDocuments.Form.InvoicesForRegistrationList.PageOfTheOrderForRegistration");
	ElsIf CurrentPage = Items.ReceiptOrderPage Then 
		// &PerformanceMeasurement
		PerformanceMonitorClient.StartTimeMeasurement(True,
			"DataProcessor.LogOfPurchaseDocuments.Form.InvoicesForRegistrationList.ReceiptOrderPage");
	ElsIf CurrentPage = Items.PageReceivingReferences Then 
		// &PerformanceMeasurement
		PerformanceMonitorClient.StartTimeMeasurement(True,
			"DataProcessor.LogOfPurchaseDocuments.Form.InvoicesForRegistrationList.PageReceivingReferences");
	EndIf;
EndProcedure

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",Organization);
	QuickFilterStructure.Insert("Warehouse",Warehouse);
	
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure",QuickFilterStructure);
	LogParameters.Insert("PurposeUseKey","Invoices");
		
	LogParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	
	OpenForm(FormattedStringURL, LogParameters); 
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ToCreateAPurchaseOfGoodsAndServices(Command)
	
	OrderListElement = Items.ListReferencesForRegistration;
	
	SelectedRows = OrderListElement.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(
				SelectedRows,
				LogParameters("Invoices")) Then
		Return;
	EndIf;
		
	ClearMessages();
	
	ListOfOrders_.Clear();
	For Each String In SelectedRows Do
		FoundRow = Items.ListReferencesForRegistration.RowData(String);
		AddedRow = ListOfOrders_.Add();
		FillPropertyValues(AddedRow, FoundRow);
	EndDo;
	
	// Selecting an action option and returning the result in the form of the name of the form to be opened and its incoming parameters.
	ParametersOfCreatedDocuments = IssueInvoicesForOrdersOnServer();
	
	CommonClientServer.ReportErrorsToUser(ParametersOfCreatedDocuments.ErrorList);
	
	If ParametersOfCreatedDocuments.Property("TextOfQuestionToUser") Then
		
		ShowQueryBox(
			New CallbackDescription(ParametersOfCreatedDocuments.UserResponseProcessingProcedure, ThisObject, ParametersOfCreatedDocuments),
				ParametersOfCreatedDocuments.TextOfQuestionToUser, QuestionDialogMode.YesNo);
		
	ElsIf ParametersOfCreatedDocuments.Property("FormName") Then
		
		If ParametersOfCreatedDocuments.Parameters.Property("CreatedDocuments") Then
			
			NotificationText1 = NStr("vi = 'Chứng từ đã tạo: %1';
									|ru = 'Создано документов: %1';
									|en = 'Created documents: %1'; fa = 'Created documents: %1';
									|it = 'Documenti creati: %1';
									|pl = 'Utworzono dokumentów: %1';
									|tr = 'Oluşturulan belgeler: %1'");
			If ParametersOfCreatedDocuments.Parameters.CreatedDocuments.Count() > 0 Then
				NotificationText1 = StrTemplate(NotificationText1, ParametersOfCreatedDocuments.Parameters.CreatedDocuments.Count());
				ShowUserNotification(NStr("vi = 'Tạo chứng từ';
											|ru = 'Создание документов';
											|en = 'Create documents'; fa = 'ایجاد اسناد';
											|it = 'Creazione documenti';
											|pl = 'Utworzenie dokumentów';
											|tr = 'Belgelerin oluşturulması'"), , NotificationText1);
			Else
				NotificationText1 = StrTemplate(NotificationText1, 0);
				ShowUserNotification(NStr("vi = 'Tạo chứng từ';
											|ru = 'Создание документов';
											|en = 'Create documents'; fa = 'ایجاد اسناد';
											|it = 'Creazione documenti';
											|pl = 'Utworzenie dokumentów';
											|tr = 'Belgelerin oluşturulması'"), , NotificationText1);
				Return;
			EndIf;
			
			ParametersOfCreatedDocuments.Parameters.Delete("CreatedDocuments");
			
		EndIf;
		
		OpenForm(ParametersOfCreatedDocuments.FormName, ParametersOfCreatedDocuments.Parameters, ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure RegisterDiscrepancyCertificate(Command)
	
	SelectedRows = Items.ListReceivingReferences.SelectedRows;
	
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(
				SelectedRows,
				LogParameters("DiscrepancyReportFollowingReceipt")) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ListOfOrders_.Clear();
	
	For Each String In SelectedRows Do
		
		FoundRow = Items.ListReceivingReferences.RowData(String);
		AddedRow = ListOfOrders_.Add();
		FillPropertyValues(AddedRow, FoundRow);
		
	EndDo;
	
	ParametersOfCreatedDocuments = IssueReportsOnServer();
	
	CommonClientServer.ReportErrorsToUser(ParametersOfCreatedDocuments.ErrorList);
	
	If ParametersOfCreatedDocuments.Property("TextOfQuestionToUser") Then
		
		ShowQueryBox(
			New CallbackDescription(ParametersOfCreatedDocuments.UserResponseProcessingProcedure, ThisObject, ParametersOfCreatedDocuments),
				ParametersOfCreatedDocuments.TextOfQuestionToUser, QuestionDialogMode.YesNo);
		
	ElsIf ParametersOfCreatedDocuments.Property("FormName") Then
		
		If ParametersOfCreatedDocuments.Parameters.Property("CreatedDocuments") Then
			
			NotificationText1 = NStr("vi = 'Chứng từ đã tạo: %1';
									|ru = 'Создано документов: %1';
									|en = 'Created documents: %1'; fa = 'Created documents: %1';
									|it = 'Documenti creati: %1';
									|pl = 'Utworzono dokumentów: %1';
									|tr = 'Oluşturulan belgeler: %1'");
			If ParametersOfCreatedDocuments.Parameters.CreatedDocuments.Count() > 0 Then
				NotificationText1 = StrTemplate(NotificationText1, ParametersOfCreatedDocuments.Parameters.CreatedDocuments.Count());
				ShowUserNotification(NStr("vi = 'Tạo chứng từ';
											|ru = 'Создание документов';
											|en = 'Create documents'; fa = 'ایجاد اسناد';
											|it = 'Creazione documenti';
											|pl = 'Utworzenie dokumentów';
											|tr = 'Belgelerin oluşturulması'"), , NotificationText1);
			Else
				NotificationText1 = StrTemplate(NotificationText1, 0);
				ShowUserNotification(NStr("vi = 'Tạo chứng từ';
											|ru = 'Создание документов';
											|en = 'Create documents'; fa = 'ایجاد اسناد';
											|it = 'Creazione documenti';
											|pl = 'Utworzenie dokumentów';
											|tr = 'Belgelerin oluşturulması'"), , NotificationText1);
				Return;
			EndIf;
			
			ParametersOfCreatedDocuments.Parameters.Delete("CreatedDocuments");
			
		EndIf;
		
		OpenForm(ParametersOfCreatedDocuments.FormName, ParametersOfCreatedDocuments.Parameters, ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecutionState(Command)
	CurrentData = Items.ListReferencesForRegistration.CurrentData;
	If CurrentData = Undefined 
		Or TypeOf(CurrentData.Ref) = Type("CatalogRef.TermsOfPurchaseFromVendors")
		Or TypeOf(CurrentData.Ref) = Type("CatalogRef.CounterpartyContracts") Then
		
		WarningText = NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chọn.';
							|ru = 'Команда не может быть выполнена для указанного объекта.';
							|en = 'Command cannot be executed for the specified object.'; fa = 'Command cannot be executed for the specified object.';
							|it = 'Il comando non può essere eseguito per l''oggetto indicato.';
							|pl = 'Nie można wykonać polecenia dla określonego obiektu.';
							|tr = 'Komut, belirtilen nesne için yürütülemiyor.'");
		ShowMessageBox(Undefined, WarningText);
		Return;
		
	EndIf;
	DocumentsList = New ValueList;
	DocumentsList.Add(CurrentData.Ref);
	OpenForm("Report.DocumentFulfillmentStatus.Form.ReportForm", New Structure("IncomingDocuments", DocumentsList));
EndProcedure

&AtClient
Procedure TheStateRunArrival(Command)
	CurrentData = Items.ListReceiptReferences.CurrentData;
	If CurrentData = Undefined 
		Or TypeOf(CurrentData.Ref) = Type("CatalogRef.TermsOfPurchaseFromVendors")
		Or TypeOf(CurrentData.Ref) = Type("CatalogRef.CounterpartyContracts") Then
		
		WarningText = NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chọn.';
							|ru = 'Команда не может быть выполнена для указанного объекта.';
							|en = 'Command cannot be executed for the specified object.'; fa = 'Command cannot be executed for the specified object.';
							|it = 'Il comando non può essere eseguito per l''oggetto indicato.';
							|pl = 'Nie można wykonać polecenia dla określonego obiektu.';
							|tr = 'Komut, belirtilen nesne için yürütülemiyor.'");
		ShowMessageBox(Undefined, WarningText);
		Return;
		
	EndIf;
	DocumentsList = New ValueList;
	DocumentsList.Add(CurrentData.Ref);
	OpenForm("Report.DocumentFulfillmentStatus.Form.ReportForm", New Structure("IncomingDocuments", DocumentsList));
EndProcedure

&AtClient
Procedure StatusOfCompletionAcceptance(Command)
	CurrentData = Items.ListReceivingReferences.CurrentData;
	If CurrentData = Undefined 
		Or TypeOf(CurrentData.Ref) = Type("CatalogRef.TermsOfPurchaseFromVendors")
		Or TypeOf(CurrentData.Ref) = Type("CatalogRef.CounterpartyContracts") Then
		
		WarningText = NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chọn.';
							|ru = 'Команда не может быть выполнена для указанного объекта.';
							|en = 'Command cannot be executed for the specified object.'; fa = 'Command cannot be executed for the specified object.';
							|it = 'Il comando non può essere eseguito per l''oggetto indicato.';
							|pl = 'Nie można wykonać polecenia dla określonego obiektu.';
							|tr = 'Komut, belirtilen nesne için yürütülemiyor.'");
		ShowMessageBox(Undefined, WarningText);
		Return;
		
	EndIf;
	DocumentsList = New ValueList;
	DocumentsList.Add(CurrentData.Ref);
	OpenForm("Report.DocumentFulfillmentStatus.Form.ReportForm", New Structure("IncomingDocuments", DocumentsList));
EndProcedure

&AtClient
Procedure RegisterByReceiving(Command)
	
	SelectedRows = Items.ListReceivingReferences.SelectedRows;
	
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(
				SelectedRows,
				LogParameters("Invoices")) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ListOfOrders_.Clear();
	
	For Each String In SelectedRows Do
		
		FoundRow = Items.ListReceivingReferences.RowData(String);
		AddedRow = ListOfOrders_.Add();
		FillPropertyValues(AddedRow, FoundRow);
		
	EndDo;
	
	ParametersOfCreatedDocuments = MakePurchasesOnServerByOrders();
	
	CommonClientServer.ReportErrorsToUser(ParametersOfCreatedDocuments.ErrorList);
	
	If ParametersOfCreatedDocuments.Property("TextOfQuestionToUser") Then
		
		ShowQueryBox(
			New CallbackDescription(ParametersOfCreatedDocuments.UserResponseProcessingProcedure, ThisObject, ParametersOfCreatedDocuments),
				ParametersOfCreatedDocuments.TextOfQuestionToUser, QuestionDialogMode.YesNo);
		
	ElsIf ParametersOfCreatedDocuments.Property("FormName") Then
		
		If ParametersOfCreatedDocuments.Parameters.Property("CreatedDocuments") Then
			
			NotificationText1 = NStr("vi = 'Chứng từ đã tạo: %1';
									|ru = 'Создано документов: %1';
									|en = 'Created documents: %1'; fa = 'Created documents: %1';
									|it = 'Documenti creati: %1';
									|pl = 'Utworzono dokumentów: %1';
									|tr = 'Oluşturulan belgeler: %1'");
			If ParametersOfCreatedDocuments.Parameters.CreatedDocuments.Count() > 0 Then
				NotificationText1 = StrTemplate(NotificationText1, ParametersOfCreatedDocuments.Parameters.CreatedDocuments.Count());
				ShowUserNotification(NStr("vi = 'Tạo chứng từ';
											|ru = 'Создание документов';
											|en = 'Create documents'; fa = 'ایجاد اسناد';
											|it = 'Creazione documenti';
											|pl = 'Utworzenie dokumentów';
											|tr = 'Belgelerin oluşturulması'"), , NotificationText1);
			Else
				NotificationText1 = StrTemplate(NotificationText1, 0);
				ShowUserNotification(NStr("vi = 'Tạo chứng từ';
											|ru = 'Создание документов';
											|en = 'Create documents'; fa = 'ایجاد اسناد';
											|it = 'Creazione documenti';
											|pl = 'Utworzenie dokumentów';
											|tr = 'Belgelerin oluşturulması'"), , NotificationText1);
				Return;
			EndIf;
			
			ParametersOfCreatedDocuments.Parameters.Delete("CreatedDocuments");
			
		EndIf;
		
		OpenForm(ParametersOfCreatedDocuments.FormName, ParametersOfCreatedDocuments.Parameters, ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure RegisterGoodsReceipt(Command)
	
	ArrangeReceiptOfGoodsServices();
	
EndProcedure

&AtClient
Procedure ToArrangeThePurchaseOfGoodsAccordingToTheOrder(Command)
	
	OrderListElement = Items.ListReceiptReferences;
	
	SelectedRows = OrderListElement.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(
				SelectedRows,
				LogParameters("Invoices")) Then
		Return;
	EndIf;
		
	ClearMessages();
	
	ListOfOrders_.Clear();
	For Each String In SelectedRows Do
		FoundRow = Items.ListReceiptReferences.RowData(String);
		AddedRow = ListOfOrders_.Add();
		FillPropertyValues(AddedRow, FoundRow);
	EndDo;
	
	// Selecting an action option and returning the result in the form of the name of the form to be opened and its incoming parameters.
	ParametersOfCreatedDocuments = PlacePurchasesByOrdersOnServer();
	
	CommonClientServer.ReportErrorsToUser(ParametersOfCreatedDocuments.ErrorList);
	
	If ParametersOfCreatedDocuments.Property("TextOfQuestionToUser") Then
		
		ShowQueryBox(
			New CallbackDescription(ParametersOfCreatedDocuments.UserResponseProcessingProcedure, ThisObject, ParametersOfCreatedDocuments),
				ParametersOfCreatedDocuments.TextOfQuestionToUser, QuestionDialogMode.YesNo);
		
	ElsIf ParametersOfCreatedDocuments.Property("FormName") Then
		
		If ParametersOfCreatedDocuments.Parameters.Property("CreatedDocuments") Then
			
			NotificationText1 = NStr("vi = 'Chứng từ đã tạo: %1';
									|ru = 'Создано документов: %1';
									|en = 'Created documents: %1'; fa = 'Created documents: %1';
									|it = 'Documenti creati: %1';
									|pl = 'Utworzono dokumentów: %1';
									|tr = 'Oluşturulan belgeler: %1'");
			If ParametersOfCreatedDocuments.Parameters.CreatedDocuments.Count() > 0 Then
				NotificationText1 = StrTemplate(NotificationText1, ParametersOfCreatedDocuments.Parameters.CreatedDocuments.Count());
				ShowUserNotification(NStr("vi = 'Tạo chứng từ';
											|ru = 'Создание документов';
											|en = 'Create documents'; fa = 'ایجاد اسناد';
											|it = 'Creazione documenti';
											|pl = 'Utworzenie dokumentów';
											|tr = 'Belgelerin oluşturulması'"), , NotificationText1);
			Else
				NotificationText1 = StrTemplate(NotificationText1, 0);
				ShowUserNotification(NStr("vi = 'Tạo chứng từ';
											|ru = 'Создание документов';
											|en = 'Create documents'; fa = 'ایجاد اسناد';
											|it = 'Creazione documenti';
											|pl = 'Utworzenie dokumentów';
											|tr = 'Belgelerin oluşturulması'"), , NotificationText1);
				Return;
			EndIf;
			
			ParametersOfCreatedDocuments.Parameters.Delete("CreatedDocuments");
			
		EndIf;
		
		OpenForm(ParametersOfCreatedDocuments.FormName, ParametersOfCreatedDocuments.Parameters, ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure IssueWriteOffOfDiscrepanciesReceiptPurchase(Command)
	OrderListElement = Items.ListReceiptReferences;
	SelectedRows = OrderListElement.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(
				SelectedRows,
				LogParameters("Invoices")) Then
		Return;
	EndIf;
		
	ClearMessages();
	
	ListOfOrders_.Clear();
	For Each String In SelectedRows Do
		FoundRow = Items.ListReceiptReferences.RowData(String);
		AddedRow = ListOfOrders_.Add();
		FillPropertyValues(AddedRow, FoundRow);
	EndDo;
	// Selecting an action option and returning the result in the form of the name of the form to be opened and its incoming parameters.
	ParametersOfCreatedDocuments = IssueWriteOffOfDiscrepanciesOnServer();
	
	CommonClientServer.ReportErrorsToUser(ParametersOfCreatedDocuments.ErrorList);
	
	If ParametersOfCreatedDocuments.Property("TextOfQuestionToUser") Then
		
		ShowQueryBox(
			New CallbackDescription(ParametersOfCreatedDocuments.UserResponseProcessingProcedure, ThisObject, ParametersOfCreatedDocuments),
				ParametersOfCreatedDocuments.TextOfQuestionToUser, QuestionDialogMode.YesNo);
		
	ElsIf ParametersOfCreatedDocuments.Property("FormName") Then
		
		If ParametersOfCreatedDocuments.Parameters.Property("CreatedDocuments") Then
			
			NotificationText1 = NStr("vi = 'Chứng từ đã tạo: %1';
									|ru = 'Создано документов: %1';
									|en = 'Created documents: %1'; fa = 'Created documents: %1';
									|it = 'Documenti creati: %1';
									|pl = 'Utworzono dokumentów: %1';
									|tr = 'Oluşturulan belgeler: %1'");
			If ParametersOfCreatedDocuments.Parameters.CreatedDocuments.Count() > 0 Then
				NotificationText1 = StrTemplate(NotificationText1, ParametersOfCreatedDocuments.Parameters.CreatedDocuments.Count());
				ShowUserNotification(NStr("vi = 'Tạo chứng từ';
											|ru = 'Создание документов';
											|en = 'Create documents'; fa = 'ایجاد اسناد';
											|it = 'Creazione documenti';
											|pl = 'Utworzenie dokumentów';
											|tr = 'Belgelerin oluşturulması'"), , NotificationText1);
			Else
				NotificationText1 = StrTemplate(NotificationText1, 0);
				ShowUserNotification(NStr("vi = 'Tạo chứng từ';
											|ru = 'Создание документов';
											|en = 'Create documents'; fa = 'ایجاد اسناد';
											|it = 'Creazione documenti';
											|pl = 'Utworzenie dokumentów';
											|tr = 'Belgelerin oluşturulması'"), , NotificationText1);
				Return;
			EndIf;
			
			ParametersOfCreatedDocuments.Parameters.Delete("CreatedDocuments");
			
		EndIf;
		
		OpenForm(ParametersOfCreatedDocuments.FormName, ParametersOfCreatedDocuments.Parameters, ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure ArrangeReceiptOfServices(Command)
	
	ArrangeReceiptOfGoodsServices(True);
	
EndProcedure


#EndRegion

#Region Private

&AtClient
Procedure ArrangeReceiptOfGoodsServices(TheseAreServices = False)
	OrderListElement = Items.ListReceiptReferences;
	
	SelectedRows = OrderListElement.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(
				SelectedRows,
				LogParameters("Invoices")) Then
		Return;
	EndIf;
		
	ClearMessages();
	
	ListOfOrders_.Clear();
	For Each String In SelectedRows Do
		FoundRow = Items.ListReceiptReferences.RowData(String);
		AddedRow = ListOfOrders_.Add();
		FillPropertyValues(AddedRow, FoundRow);
	EndDo;
	
	// Selecting an action option and returning the result in the form of the name of the form to be opened and its incoming parameters.
	ParametersOfCreatedDocuments = IssueReceiptsForOrdersOnServer(TheseAreServices);
	
	CommonClientServer.ReportErrorsToUser(ParametersOfCreatedDocuments.ErrorList);
	
	If ParametersOfCreatedDocuments.Property("TextOfQuestionToUser") Then
		
		ShowQueryBox(
			New CallbackDescription(ParametersOfCreatedDocuments.UserResponseProcessingProcedure, ThisObject, ParametersOfCreatedDocuments),
				ParametersOfCreatedDocuments.TextOfQuestionToUser, QuestionDialogMode.YesNo);
		
	ElsIf ParametersOfCreatedDocuments.Property("FormName") Then
		
		If ParametersOfCreatedDocuments.Parameters.Property("CreatedDocuments") Then
			
			NotificationText1 = NStr("vi = 'Đã tạo %1 chứng từ';
									|ru = 'Создано документов: %1';
									|en = 'Created documents: %1'; fa = 'Created documents: %1';
									|it = 'Documenti creati: %1';
									|pl = 'Utworzono dokumentów: %1';
									|tr = 'Oluşturulan belgeler: %1'");
			If ParametersOfCreatedDocuments.Parameters.CreatedDocuments.Count() > 0 Then
				NotificationText1 = StrTemplate(NotificationText1, ParametersOfCreatedDocuments.Parameters.CreatedDocuments.Count());
				ShowUserNotification(NStr("vi = 'Tạo chứng từ';
											|ru = 'Создание документов';
											|en = 'Create documents'; fa = 'ایجاد اسناد';
											|it = 'Creazione documenti';
											|pl = 'Utworzenie dokumentów';
											|tr = 'Belgelerin oluşturulması'"), , NotificationText1);
			Else
				NotificationText1 = StrTemplate(NotificationText1, 0);
				ShowUserNotification(NStr("vi = 'Tạo chứng từ';
											|ru = 'Создание документов';
											|en = 'Create documents'; fa = 'ایجاد اسناد';
											|it = 'Creazione documenti';
											|pl = 'Utworzenie dokumentów';
											|tr = 'Belgelerin oluşturulması'"), , NotificationText1);
				Return;
			EndIf;
			
			ParametersOfCreatedDocuments.Parameters.Delete("CreatedDocuments");
			
		EndIf;
		
		OpenForm(ParametersOfCreatedDocuments.FormName, ParametersOfCreatedDocuments.Parameters, ThisForm);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	// Conditional design of the dynamic list "List of assignments"
	ListOfConditionalAppearance = ListReferencesForRegistration.SettingsComposer.Settings.ConditionalAppearance;
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
	
	//
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject,
																	"ListReferencesForRegistration.Date",
																	"ListReferencesForRegistrationDate");
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject,
																	"ListReceiptReferences.Date",
																	"ListReceiptReferencesDate");
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject,
																	"ListReceivingReferences.Date",
																	"ListReceivingReferencesDate");
	SetConditionalAppearanceOfLists();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfLists()
	
	// BT Procurement of the supplier of the Delivery Invoice - Presentation as "Purchase from a supplier (invoice of delivery)"
	PresentationPurchasingFromSupplier = NStr("vi = 'Mua hàng từ một nhà cung cấp (Giao hàng chưa có hóa đơn)';
												|ru = 'Закупка у поставщика (неотфактурованная поставка)';
												|en = 'Purchase from vendor (GRNI)'; fa = 'خرید از تأمین‌کننده (کالای دریافت‌شده بدون فاکتور)';
												|it = 'Закупка у поставщика (неотфактурованная поставка)';
												|pl = 'Zakup u dostawcy (niefakturowana dostawa)';
												|tr = 'Tedarikçiden satın alma (teslim edilmemiş teslimat)'");
	
	// BT Procurementaaesfakturovka Delivery - Presentation as "Import from the EAEU (invoice delivery)"
	PresentationImportFromEAEU = NStr("vi = 'Nhập khẩu từ liên minh kinh tế Á-Âu (cung cấp không có hóa đơn)';
										|ru = 'Ввоз из ЕАЭС (неотфактурованная поставка)';
										|en = 'Import from EAEU (GRNI)'; fa = 'واردات از EAEU (کالای دریافت‌شده بدون فاکتور)';
										|it = 'Ввоз из ЕАЭС (неотфактурованная поставка)';
										|pl = 'Wwóz z EWG (niefakturowana dostawa)';
										|tr = 'AEB''DEN ithalat (teslim edilmemiş teslimat)'");
	
	//ListReferencesForRegistration
	ListOfOrderForRegistrationOfUO = ListReferencesForRegistration.SettingsComposer.Settings.ConditionalAppearance;
	Item = ListOfOrderForRegistrationOfUO.Items.Add();
	Item.Presentation = PresentationPurchasingFromSupplier;
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("BusinessOperation");
	CommonClientServer.AddCompositionItem(Item.Filter, "BusinessOperation", DataCompositionComparisonType.Equal,
			Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	Item.Appearance.SetParameterValue("Text", PresentationPurchasingFromSupplier);
	
	Item = ListOfOrderForRegistrationOfUO.Items.Add();
	Item.Presentation = PresentationImportFromEAEU;
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("BusinessOperation");
	CommonClientServer.AddCompositionItem(Item.Filter, "BusinessOperation", DataCompositionComparisonType.Equal,
			Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	Item.Appearance.SetParameterValue("Text", PresentationImportFromEAEU);
	
	//ListReceiptReferences
	ListOfOrdersForAdmissionTo = ListReceiptReferences.SettingsComposer.Settings.ConditionalAppearance;
	Item = ListOfOrdersForAdmissionTo.Items.Add();
	Item.Presentation = PresentationPurchasingFromSupplier;
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("BusinessOperation");
	CommonClientServer.AddCompositionItem(Item.Filter, "BusinessOperation", DataCompositionComparisonType.Equal,
			Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	Item.Appearance.SetParameterValue("Text", PresentationPurchasingFromSupplier);
	
	Item = ListOfOrdersForAdmissionTo.Items.Add();
	Item.Presentation = PresentationImportFromEAEU;
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("BusinessOperation");
	CommonClientServer.AddCompositionItem(Item.Filter, "BusinessOperation", DataCompositionComparisonType.Equal,
			Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	Item.Appearance.SetParameterValue("Text", PresentationImportFromEAEU);
	
	//ListReceivingReferences
	ListOfOrderForAcceptanceOfUO = ListReceivingReferences.SettingsComposer.Settings.ConditionalAppearance;
	Item = ListOfOrderForAcceptanceOfUO.Items.Add();
	Item.Presentation = PresentationPurchasingFromSupplier;
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("BusinessOperation");
	CommonClientServer.AddCompositionItem(Item.Filter, "BusinessOperation", DataCompositionComparisonType.Equal,
			Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	Item.Appearance.SetParameterValue("Text", PresentationPurchasingFromSupplier);
	
	Item = ListOfOrderForAcceptanceOfUO.Items.Add();
	Item.Presentation = PresentationImportFromEAEU;
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("BusinessOperation");
	CommonClientServer.AddCompositionItem(Item.Filter, "BusinessOperation", DataCompositionComparisonType.Equal,
			Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	Item.Appearance.SetParameterValue("Text", PresentationImportFromEAEU);
	
EndProcedure
#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.VendorInvoice.EmptyRef"));
	Managers.Add(PredefinedValue("Document.GoodsReceiptForStorage.EmptyRef"));
	Managers.Add(PredefinedValue("Document.PurchaseOrder.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		
		Ref = ReferencesArrray[0];
		If TypeOf(Ref) = Type("DocumentRef.PurchaseOrder") Then
			Items.ListReferencesForRegistration.CurrentRow = Ref;
			Items.Pages.CurrentPage = Items.Pages.ChildItems.PageOfTheOrderForRegistration;
		EndIf;
		
		ShowValue(Undefined, Ref);
		
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

#Region GoodsReceipt

&AtServer
Function DeterminePresenceOfIssuedInvoices(DirectLink,
												Warehouse,
												BusinessOperation,
												FillingByOrders = True,
												ReceiptOfGoods = False,
												ThisIsRegistrationOfAcquisitionOfIncome = False)
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	OrdersTable.PurchaseOrder	AS OrderDocument,
	|	OrdersTable.Recorder		AS Invoice
	|FROM
	|	AccumulationRegister.PurchaseOrders AS OrdersTable
	|WHERE
	|	&FillingByOrders
	|	AND NOT &ReceiptOfGoods
	|	AND OrdersTable.Warehouse = &Warehouse
	|	AND OrdersTable.PurchaseOrder = &DirectLink
	|	AND VALUETYPE(OrdersTable.Recorder) IN (TYPE(Document.VendorInvoice),
	|												TYPE(Document.GoodsReceiptForStorage))
	|	AND OrdersTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|													VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&DirectLink			AS OrderDocument,
	|	DocumentAcquisitions.Ref	AS Invoice
	|FROM
	|	Document.VendorInvoice AS DocumentAcquisitions
	|		INNER JOIN Document.VendorInvoice.Goods AS AcquisitionGoods
	|		ON DocumentAcquisitions.Ref = AcquisitionGoods.Ref
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS StornoDocuments
	|		ON StornoDocuments.ReversedDocument = DocumentAcquisitions.Ref
	|			AND NOT StornoDocuments.AdditionalRecord
	|WHERE
	|	&FillingByOrders
	|	AND NOT &ReceiptOfGoods
	|	AND DocumentAcquisitions.Posted
	|	AND AcquisitionGoods.Warehouse = &Warehouse
	|	AND (DocumentAcquisitions.Terms = &DirectLink
	|		OR DocumentAcquisitions.Contract = &DirectLink)
	|	AND StornoDocuments.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentInflow.ReferenceOrder	AS OrderDocument,
	|	DocumentInflow.Ref			AS Invoice
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse AS DocumentInflow
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS StornoDocuments
	|		ON StornoDocuments.ReversedDocument = DocumentInflow.Ref
	|			AND NOT StornoDocuments.AdditionalRecord
	|WHERE
	|	&FillingByOrders
	|	AND DocumentInflow.Posted
	|	AND DocumentInflow.Warehouse = &Warehouse
	|	AND DocumentInflow.ReferenceOrder = &DirectLink
	|	AND DocumentInflow.BusinessOperation = &ReceiptOperation
	|	AND StornoDocuments.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	GoodsToReceive.DocumentInflow	AS OrderDocument,
	|	GoodsToReceive.Recorder			AS Invoice
	|FROM
	|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
	|WHERE
	|	NOT &FillingByOrders
	|	AND GoodsToReceive.Warehouse = &Warehouse
	|	AND GoodsToReceive.DocumentInflow = &DirectLink
	|	AND GoodsToReceive.BusinessOperation = &BusinessOperation
	|	AND GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Expense)
	|GROUP BY
	|	GoodsToReceive.DocumentInflow,
	|	GoodsToReceive.Recorder
	|HAVING
	|	SUM(GoodsToReceive.ToRegisterReceiptsByInvoices) > 0
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&DirectLink		AS OrderDocument,
	|	Documentreceivings.Ref	AS Invoice
	|FROM
	|	Document.GoodsReceiptForStorage AS Documentreceivings
	|		INNER JOIN Document.GoodsReceiptForStorage.Goods AS AcceptanceGoods
	|		ON Documentreceivings.Ref = AcceptanceGoods.Ref
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS StornoDocuments
	|		ON StornoDocuments.ReversedDocument = Documentreceivings.Ref
	|			AND NOT StornoDocuments.AdditionalRecord
	|WHERE
	|	&FillingByOrders
	|	AND Documentreceivings.Posted
	|	AND AcceptanceGoods.Warehouse = &Warehouse
	|	AND (Documentreceivings.Terms = &DirectLink
	|		OR Documentreceivings.Contract = &DirectLink)
	|	AND StornoDocuments.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToReceiveBalance.DocumentInflow	AS DocumentInflow,
	|	GoodsToReceiveBalance.Products			AS Products,
	|	GoodsToReceiveBalance.Characteristic		AS Characteristic,
	|	GoodsToReceiveBalance.Purpose			AS Purpose,
	|	GoodsToReceiveBalance.Series					AS Series,
	|	GoodsToReceiveBalance.ToRegisterGoodsReceiptsBalance AS Count
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			DocumentInflow = &DirectLink
	|			AND Warehouse = &Warehouse) AS GoodsToReceiveBalance
	|WHERE
	|	&FillingByOrders
	|	AND GoodsToReceiveBalance.ToRegisterGoodsReceiptsBalance <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsToReceiveBalance.DocumentInflow	AS DocumentInflow,
	|	GoodsToReceiveBalance.Products			AS Products,
	|	GoodsToReceiveBalance.Characteristic		AS Characteristic,
	|	GoodsToReceiveBalance.Purpose			AS Purpose,
	|	GoodsToReceiveBalance.Series					AS Series,
	|	GoodsToReceiveBalance.ToRegisterReceiptsByInvoicesBalance AS Count
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			DocumentInflow = &DirectLink
	|			AND Warehouse = &Warehouse) AS GoodsToReceiveBalance
	|WHERE
	|	NOT &FillingByOrders
	|	AND GoodsToReceiveBalance.ToRegisterReceiptsByInvoicesBalance <> 0";
	
	PairsOfSeparatePurchaseOperations	= PurchasesServer.PairsOfSeparatePurchaseOperations(True);
	ReceiptOperation				= PairsOfSeparatePurchaseOperations.Get(BusinessOperation);
	
	Query.SetParameter("DirectLink",				DirectLink);
	Query.SetParameter("Warehouse",							Warehouse);
	Query.SetParameter("BusinessOperation",			BusinessOperation);
	Query.SetParameter("ReceiptOperation",			ReceiptOperation);
	Query.SetParameter("FillingByOrders",			FillingByOrders);
	Query.SetParameter("ReceiptOfGoods",	ReceiptOfGoods);
	
	SetPrivilegedMode(True);
	QueryResults = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	CreateInvoices = QueryResults[0].Unload();
	
	AddressInvoiceTableInTemporaryStorage	= PutToTempStorage(CreateInvoices);
	SettingsOfInvoiceReissueForm		= SettingsOfInvoiceReissueForm(DirectLink,
																						Warehouse,
																						BusinessOperation,
																						ThisIsRegistrationOfAcquisitionOfIncome);
	
	Return Not QueryResults[1].IsEmpty()
			And CreateInvoices.Count() > 0;
	
EndFunction

&AtServer
Function DetailsOfAgreementHeader(DirectLink)
	
	BasicContractDetails	= "Organization, Counterparty, Partner, Department, BusinessOperation";
	ContractDetails_			= Common.ObjectAttributesValues(DirectLink,
																			BasicContractDetails);
	
	Return ContractDetails_;
	
EndFunction

&AtServer
Function SettingsOfInvoiceReissueForm(DirectLink,
												Warehouse,
												BusinessOperation,
												ThisIsRegistrationOfAcquisitionOfIncome = False)
	
	FillingData = New Structure;
	BusinessTransactionsReceiptOfGoods = BusinessTransactionsReceiptOfGoods();
	
	FormSettings = InvoicesServer.SettingsOfInvoiceReissueForm();
	FormSettings.Title			= NStr("vi = 'Gia hạn các chứng từ mua hàng cho các đơn đặt hàng đã chọn';
										|ru = 'Переоформление документов закупки по выбранным распоряжениям';
										|en = 'Reregister purchase documents according to the selected references'; fa = 'Reregister purchase documents according to the selected references';
										|it = 'La formalizzazione sostitutiva dell''acquisto per disposizioni selezionate';
										|pl = 'Ponowne przygotowanie dokumentów zakupu dla wybranych zamówień';
										|tr = 'Seçilen siparişlere göre satın alma belgelerinin yeniden düzenlenmesi'");
	FormSettings.NameOfTheInvoiceForm	= "Document.VendorInvoice.Form.DocumentForm";
	
	If BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		FormSettings.NameOfTheInvoiceForm = "Document.GoodsReceiptForStorage.Form.DocumentForm";
	EndIf;
	
	If Not ThisIsRegistrationOfAcquisitionOfIncome
		And BusinessTransactionsReceiptOfGoods.Find(BusinessOperation) <> Undefined Then
			
		FillingData.Insert("DocumentBasis",				DirectLink);
		FillingData.Insert("WarehouseForReceipt",				Warehouse);
		FillingData.Insert("EconomicOperationOfAcceptance",	BusinessOperation);
		FillingData.Insert("FillByWarehouseDocument",				True);
		
		FormSettings.NameOfTheInvoiceForm				= "Document.ReceiptOfGoodsToWarehouse.Form.DocumentForm";
		FormSettings.ThisIsTheReceiptOfGoodsDocument	= True;
		
		
	ElsIf TypeOf(DirectLink) = Type("CatalogRef.TermsOfPurchaseFromVendors")
		Or TypeOf(DirectLink) = Type("CatalogRef.CounterpartyContracts") Then
		
		FillingData.Insert("DocumentBasis",	DirectLink);
		FillingData.Insert("WarehouseForReceipt",	Warehouse);
		
	EndIf;
	
	FormSettings.FillingData		= FillingData;
	FormSettings.ShippingSlip	= False;
	FormSettings.ReceivingDocument	= True;
	
	Return FormSettings;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure FillSelectionListsByState()
	
	ChoiceList = Items.NoteState.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add("1", NStr("vi = 'Đã nhập kho nhưng chưa tạo mua hàng';
							|ru = 'Оформлены ордера, не оформлены накладные';
							|en = 'Goods received not yet invoiced'; fa = 'Goods received not yet invoiced';
							|it = 'I mandati sono formalizzati, le bolle non sono formalizzate';
							|pl = 'Są przygotowane zlecenia, nie są przygotowane faktury';
							|tr = 'Düzenlenen siparişler, düzenlenmeyen irsaliyeler'"), False, PictureLib.CreateInvoice);
	ChoiceList.Add("5", NStr("vi = 'Đã tạo mua hàng nhưng chưa nhập kho';
							|ru = 'Не оформлены ордера, оформлены накладные';
							|en = 'Goods invoiced not yet received'; fa = 'Goods invoiced not yet received';
							|it = 'I mandati non sono formalizzati, le bolle sono formalizzate';
							|pl = 'Nie są przygotowane zlecenia, są przygotowane faktury';
							|tr = 'Düzenlenmeyen siparişler, düzenlenen irsaliyeler'"), False, PictureLib.PendingGoodsReceiptIssue);
	ChoiceList.Add("3", NStr("vi = 'Chênh lệch giữa nhập kho và mua hàng';
							|ru = 'Ордера не соответствуют накладным';
							|en = 'Received vs invoiced mismatch'; fa = 'Received vs invoiced mismatch';
							|it = 'I mandati non corrispondono alle bolle';
							|pl = 'Zlecenia nie pokrywają się z fakturami';
							|tr = 'Siparişler irsaliyeler ile eşleşmiyor'"), False, PictureLib.DiscrepancyOfGoodsNoteAndInvoice);
	
	ChoiceList = Items.PurchaseState.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add("1", NStr("vi = 'Tạo hóa đơn bán hàng';
							|ru = 'Создать накладную';
							|en = 'Create invoice'; fa = 'ایجاد فاکتور';
							|it = 'Creare una bolla';
							|pl = 'Utwórz list przewozowy';
							|tr = 'İrsaliye oluştur'"),False, PictureLib.CreateInvoice);
	ChoiceList.Add("2", NStr("vi = 'Gia hạn hóa đơn';
							|ru = 'Дооформить накладную';
							|en = 'Finish creating invoice'; fa = 'پایان ایجاد فاکتور';
							|it = 'Completare la bolla';
							|pl = 'Sporządź do końca list przewozowy';
							|tr = 'İrsaliyeyi tamamla'"),False, PictureLib.CreateInvoiceOnUninvoicedDeliveries);
	
	ChoiceList = Items.GoodsReceiptState.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add("0", NStr("vi = 'Doanh thu theo đơn đặt hàng';
							|ru = 'Поступления соответствуют распоряжениям';
							|en = 'Receipts correspond to references'; fa = 'Receipts correspond to references';
							|it = 'Gli arrivi corrispondono alle disposizioni';
							|pl = 'Wpływy pokrywają się z zamówieniami';
							|tr = 'Makbuzlar siparişlere uygundur'"), False, PictureLib.InvoiceIsRegistered);
	ChoiceList.Add("1", NStr("vi = 'Tạo chứng từ thu';
							|ru = 'Создать поступление';
							|en = 'Create receipt'; fa = 'ایجاد رسید';
							|it = 'Creare una disposizione';
							|pl = 'Utworzyć wpłatę';
							|tr = 'Makbuz oluştur'"),False, PictureLib.CreateInvoice);
	ChoiceList.Add("3", NStr("vi = 'Doanh thu không tuân thủ đơn đặt hàng';
							|ru = 'Поступления не соответствуют распоряжениям';
							|en = 'Receipts do not correspond to references'; fa = 'Receipts do not correspond to references';
							|it = 'Gli arrivi non corrispondono alle disposizioni';
							|pl = 'Wpływy nie pokrywają się z zamówieniami';
							|tr = 'Makbuzlar siparişlere uygun değil'"), False, PictureLib.DiscrepancyOfGoodsNoteAndInvoice);
	
	ChoiceList = Items.PurchaseReceiptState.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add("0", NStr("vi = 'Mua lại phù hợp với tiếp nhận';
							|ru = 'Приобретения соответствуют поступлениям';
							|en = 'Invoices correspond to receipts'; fa = 'Invoices correspond to receipts';
							|it = 'Gli acquisti corrispondono alle disposizioni';
							|pl = 'Nabycia pokrywają się z wpłatami';
							|tr = 'Satın alımlar makbuzlara karşılık gelmektedir'"), False, PictureLib.InvoiceIsRegistered);
	ChoiceList.Add("1", NStr("vi = 'Mua lại không được thực hiện';
							|ru = 'Не оформлены приобретения';
							|en = 'Invoices not registered'; fa = 'Invoices not registered';
							|it = 'Non sono formalizzati gli acquisti';
							|pl = 'Nie są zarejestrowane nabycia';
							|tr = 'Herhangi bir satın alım düzenlenmemiştir'"), False, PictureLib.CreateInvoice);
	ChoiceList.Add("3", NStr("vi = 'Mua lại không phù hợp với tiếp nhận';
							|ru = 'Приобретения не соответствуют поступлениям';
							|en = 'Invoices do not correspond to receipts'; fa = 'Invoices do not correspond to receipts';
							|it = 'Gli acquisti non corrispondono agli arrivi';
							|pl = 'Nabycia nie pokrywają się z wpłatami';
							|tr = 'Satın alımlar makbuzlara karşılık gelmemektedir'"), False, PictureLib.DiscrepancyOfGoodsNoteAndInvoice);
	
EndProcedure

&AtServer
Procedure SetCurrentPage()
	
	CurrentPageName = "";
	
	If Parameters.Property("CurrentPageName", CurrentPageName) Then
		If ValueIsFilled(CurrentPageName) Then
			Items.Pages.CurrentPage = Items[CurrentPageName];
		EndIf;
	Else
		If Not Documents.VendorInvoice.ThereAreOrdersForRegistration(Organization,Warehouse)
			And Documents.VendorInvoice.ThereAreOrdersForAcceptance(Organization,Warehouse) Then
			Items.Pages.CurrentPage = Items.PageReceivingReferences;
		ElsIf UsePurchaseOrders Then	
			Items.Pages.CurrentPage =	Items.PageOfTheOrderForRegistration;
		ElsIf UseGoodsReceipts Then
			Items.Pages.CurrentPage =	Items.ReceiptOrderPage;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure CustomizeFormByWarehouse()
	
	FilterWarehouses = WarehousesServer.ListOfSubordinateWarehouses(Warehouse);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListReferencesForRegistration,
		"Warehouse",
		FilterWarehouses,
		DataCompositionComparisonType.InList,
		,
		FilterWarehouses.Count() > 0);
	CommonClientServer.SetDynamicListFilterItem(
		ListReceivingReferences,
		"Warehouse",
		FilterWarehouses,
		DataCompositionComparisonType.InList,
		,
		FilterWarehouses.Count() > 0);
	
	If FilterWarehouses.Count() > 0 Then
		
		FilterWarehouses.Add(Catalogs.Warehouses.EmptyRef());
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		ListReceiptReferences,
		"Warehouse",
		FilterWarehouses,
		DataCompositionComparisonType.InList,
		,
		FilterWarehouses.Count() > 0);
		
	ThereIsOrderForReceiptWarehouse = WarehousesServer.ThereIsOrderForReceiptWarehouse(Warehouse,CurrentSessionDate());
	RightToReadBalanceOfGoodsForReceipt = AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive);
	AcceptanceAvailability = ThereIsOrderForReceiptWarehouse And RightToReadBalanceOfGoodsForReceipt;
	
	Items.NoteState.Visible = AcceptanceAvailability;
	Items.PageReceivingReferences.Visible = AcceptanceAvailability;
	Items.ListReferencesForRegistrationRegisterByReceiving.Visible = AcceptanceAvailability
																		And (RightToAddAPurchase
																			Or RightToAddGoodsReceiving);
	
	If AcceptanceAvailability Then
		Items.ListReceivingReferences.SelectedRows.Clear();
		Items.ListReceivingReferencesCurrency.Visible = GetFunctionalOption("UseMultipleCurrencies");
	EndIf;
	
	If (Not ThereIsOrderForReceiptWarehouse And Not UseGoodsReceipts)
		Or Not UsePurchaseOrders Then
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
	Else
		Items.Pages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
	EndIf;
	
	If UsePurchaseOrders Then	
		Items.Pages.CurrentPage =	Items.PageOfTheOrderForRegistration;	
	ElsIf UseGoodsReceipts Then
		Items.Pages.CurrentPage =	Items.ReceiptOrderPage;		
	EndIf;
	
	Items.ListReferencesForRegistration.SelectedRows.Clear();
	Items.ListReceiptReferences.SelectedRows.Clear();
	
EndProcedure

&AtClient
Function LogParameters(Var_PurposeUseKey)
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",Organization);
	QuickFilterStructure.Insert("Warehouse",Warehouse);
	
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure",QuickFilterStructure);
	LogParameters.Insert("WorkplaceName","LogOfPurchaseDocuments");
	LogParameters.Insert("FormAssignmentKey",Var_PurposeUseKey);
	LogParameters.Insert("JournalSynonym",NStr("vi = 'Chứng từ mua hàng';
												|ru = 'Документы закупки';
												|en = 'Purchase documents'; fa = 'اسناد خرید';
												|it = 'Documenti d''acquisto';
												|pl = 'Dokument zakupu';
												|tr = 'Satın alma belgeleri'"));
	
	Return LogParameters;
	
EndFunction

&AtServer
Procedure SetDinListParameters()
	ListReceiptReferences.Parameters.SetParameterValue("ListOfBusinessTransactions", BusinessTransactionsReceiptOfGoods());
EndProcedure

&AtClientAtServerNoContext
Function BusinessTransactionsReceiptOfGoods()
	
	ListOfBusinessTransactions = New Array;
	ListOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery"));
	ListOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit"));
	ListOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit"));
	ListOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt"));
	
	ListOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery"));
	ListOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit"));
	ListOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit"));
	ListOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery"));
	
	ListOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit"));
	ListOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ImportGoodsInTransit"));
	
	Return ListOfBusinessTransactions
EndFunction

&AtClientAtServerNoContext
Function BusinessTransactionsProhibitedInActOnDiscrepancies()
	
	ListOfBusinessTransactions = New Array;
	
	ListOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit"));
	ListOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.ImportGoodsInTransit"));
	
	Return ListOfBusinessTransactions
EndFunction

&AtServer
Function TextOfRequestForListOfAcceptanceOrders()
	
	QueryText =
	"SELECT ALLOWED
	|	Table.DocumentInflow		AS DocumentInflow,
	|	Table.DocumentInflow		AS DocumentInflow1,
	|	Table.Warehouse					AS Warehouse,
	|	Table.Warehouse					AS Warehouse1,
	|	Table.BusinessOperation	AS BusinessOperation,
	|	Table.BusinessOperation	AS BusinessOperation1,
	|	Table.Products			AS Products,
	|	Table.Products			AS Products1,
	|	Table.Characteristic			AS Characteristic,
	|	Table.Characteristic			AS Characteristic1,
	|	Table.Purpose				AS Purpose,
	|	Table.Purpose				AS Purpose1,
	|	Table.Series					AS Series,
	|	Table.Series					AS Series1
	|INTO TueRemainingItemsToBeReceived
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			DocumentInflow REFS Document.PurchaseOrder
	|				OR DocumentInflow REFS Document.VendorInvoice
	|				OR DocumentInflow REFS Document.GoodsReceiptForStorage
	
	|					AND CAST(DocumentInflow AS Document.GoodsReceiptForStorage).BusinessOperation <>
	|						VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5)
	
	|				OR DocumentInflow REFS Catalog.CounterpartyContracts
	|				OR DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|			{(Warehouse) AS Warehouse}
	|	) AS Table
	|WHERE
	|	Table.ToRegisterGoodsReceiptsBalance <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	Table.DocumentInflow		AS DocumentInflow,
	|	Table.Warehouse					AS Warehouse,
	|	Table.BusinessOperation	AS BusinessOperation
	|INTO TueReceiptDocuments
	|FROM
	|	(SELECT
	|		StockBalance.DocumentInflow		AS DocumentInflow,
	|		StockBalance.Warehouse					AS Warehouse,
	|		StockBalance.BusinessOperation	AS BusinessOperation,
	|		StockBalance.Products				AS Products,
	|		StockBalance.Characteristic			AS Characteristic,
	|		StockBalance.Purpose				AS Purpose,
	|		StockBalance.Series					AS Series
	|	FROM
	|		TueRemainingItemsToBeReceived AS StockBalance
	|	) AS Table
	|
	|INDEX BY
	|	DocumentInflow,
	|	Warehouse,
	|	BusinessOperation
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	GoodsToReceive.DocumentInflow AS DocumentInflow,
	|	GoodsToReceive.Warehouse AS Warehouse,
	|	GoodsToReceive.BusinessOperation AS BusinessOperation
	|INTO TueThereAreOrders_3
	|FROM
	|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
	|WHERE
	|	GoodsToReceive.Active
	|	AND GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND (GoodsToReceive.DocumentInflow, GoodsToReceive.Warehouse, GoodsToReceive.BusinessOperation) IN
	|		(SELECT
	|			Table.DocumentInflow,
	|			Table.Warehouse,
	|			Table.BusinessOperation
	|		FROM
	|			TueReceiptDocuments AS Table
	|		)
	|GROUP BY
	|	GoodsToReceive.DocumentInflow,
	|	GoodsToReceive.Warehouse,
	|	GoodsToReceive.BusinessOperation
	|HAVING
	|	SUM(GoodsToReceive.ToRegisterGoodsReceipts) > 0
	|	
	|INDEX BY
	|	DocumentInflow,
	|	Warehouse,
	|	BusinessOperation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	GoodsToReceive.DocumentInflow AS DocumentInflow,
	|	GoodsToReceive.Warehouse AS Warehouse,
	|	GoodsToReceive.BusinessOperation AS BusinessOperation
	|INTO TueThereAreReceipts
	|FROM
	|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
	|WHERE
	|	GoodsToReceive.Active
	|	AND GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND (GoodsToReceive.DocumentInflow, GoodsToReceive.Warehouse, GoodsToReceive.BusinessOperation) IN
	|		(SELECT
	|			Table.DocumentInflow,
	|			Table.Warehouse,
	|			Table.BusinessOperation
	|		FROM
	|			TueReceiptDocuments AS Table
	|		)
	|GROUP BY
	|	GoodsToReceive.DocumentInflow,
	|	GoodsToReceive.Warehouse,
	|	GoodsToReceive.BusinessOperation
	|HAVING
	|	SUM(GoodsToReceive.ToRegisterGoodsReceipts) > 0
	|	
	|INDEX BY
	|	DocumentInflow,
	|	Warehouse,
	|	BusinessOperation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Table.DocumentInflow		AS DocumentInflow,
	|	Table.Warehouse					AS Warehouse,
	|	Table.BusinessOperation	AS BusinessOperation,
	|	MAX(CASE
	|				WHEN TableTTThereAreReceipts.DocumentInflow IS NULL
	|					THEN 1
	|				WHEN TableHasOrders.DocumentInflow IS NULL
	|					THEN 5
	|				ELSE 3
	|		END)						AS NoteState
	|INTO TueOrderStatus
	|FROM
	|	TueRemainingItemsToBeReceived AS Table
	|		LEFT JOIN TueThereAreOrders_3 AS TableHasOrders
	|		ON TableHasOrders.DocumentInflow = Table.DocumentInflow
	|			AND TableHasOrders.Warehouse = Table.Warehouse
	|			AND TableHasOrders.BusinessOperation = Table.BusinessOperation
	|		
	|		LEFT JOIN TueThereAreReceipts AS TableTTThereAreReceipts
	|		ON TableTTThereAreReceipts.DocumentInflow = Table.DocumentInflow
	|			AND TableTTThereAreReceipts.Warehouse = Table.Warehouse
	|			AND TableTTThereAreReceipts.BusinessOperation = Table.BusinessOperation
	|
	|GROUP BY
	|	Table.DocumentInflow,
	|	Table.Warehouse,
	|	Table.BusinessOperation
	|
	|INDEX BY
	|	DocumentInflow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Ref
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.CounterpartyContracts
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.CounterpartyContracts).Ref
	|		ELSE DocumentsRegistry.Ref
	|	END										AS Ref,
	|	VALUETYPE(TableOfOrders.DocumentInflow.Ref) AS TypeOfOrder_,
	|	CASE
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Number
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.CounterpartyContracts
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.CounterpartyContracts).Number
	|		ELSE DocumentsRegistry.IBDocumentNumber
	|	END										AS Number,
	|	CASE
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Date
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.CounterpartyContracts
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.CounterpartyContracts).Date
	|		ELSE DocumentsRegistry.IBDocumentDate
	|	END										AS Date,
	|	CASE
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Partner
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.CounterpartyContracts
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.CounterpartyContracts).Partner
	|		ELSE DocumentsRegistry.Partner
	|	END										AS Partner,
	|	CASE
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Counterparty
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.CounterpartyContracts
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.CounterpartyContracts).Counterparty
	|		ELSE CAST(DocumentsRegistry.Counterparty.Key AS Catalog.Counterparties)
	|	END										AS Counterparty,
	|	TableOfOrders.BusinessOperation	AS BusinessOperation,
	|	CASE
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Organization
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.CounterpartyContracts
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.CounterpartyContracts).Organization
	|		ELSE DocumentsRegistry.Organization
	|	END										AS Organization,
	|	TableOfOrders.Warehouse					AS Warehouse,
	|	DocumentsRegistry.Sum						AS DocumentAmount,
	|	CASE
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Currency
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.CounterpartyContracts
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.CounterpartyContracts).ARAPCurrency
	|		ELSE DocumentsRegistry.Currency
	|	END										AS Currency,
	|	CASE
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Manager
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.CounterpartyContracts
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.CounterpartyContracts).Manager
	|		ELSE DocumentsRegistry.EmployeeResponsible
	|	END										AS Manager,
	|	CASE
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).DeletionMark
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.CounterpartyContracts
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.CounterpartyContracts).DeletionMark
	|		ELSE DocumentsRegistry.DeletionMark
	|	END										AS DeletionMark,
	|	TableOfOrders.NoteState			AS NoteState,
	|	CASE
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.CounterpartyContracts
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.CounterpartyContracts).Ref
	|		ELSE DocumentsRegistry.Contract
	|	END AS Contract,
	|	CASE
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN VALUE(Enum.ARAPObjectSettings.EmptyRef)
	|		WHEN TableOfOrders.DocumentInflow REFS Catalog.CounterpartyContracts
	|			THEN CAST(TableOfOrders.DocumentInflow AS Catalog.CounterpartyContracts).ARAPObjectSettings
	|		ELSE DocumentsRegistry.Ref.ARAPObjectSettings
	|	END AS ARAPObjectSettings
	|
	|INTO TTTempTable
	|FROM
	|	TueOrderStatus AS TableOfOrders
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TableOfOrders.DocumentInflow = DocumentsRegistry.Ref
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	NOT TableOfOrders.DocumentInflow.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTempTable.Ref					AS Ref,
	|	TTTempTable.TypeOfOrder_			AS TypeOfOrder_,
	|	TTTempTable.Number					AS Number,
	|	TTTempTable.Date						AS Date,
	|	TTTempTable.Partner					AS Partner,
	|	TTTempTable.Counterparty				AS Counterparty,
	|	TTTempTable.BusinessOperation	AS BusinessOperation,
	|	TTTempTable.Organization				AS Organization,
	|	TTTempTable.Warehouse					AS Warehouse,
	|	TTTempTable.DocumentAmount			AS DocumentAmount,
	|	TTTempTable.Currency					AS Currency,
	|	TTTempTable.Manager					AS Manager,
	|	TTTempTable.DeletionMark			AS DeletionMark,
	|	TTTempTable.NoteState			AS NoteState,
	|	TTTempTable.Contract					AS Contract,
	|	TTTempTable.ARAPObjectSettings			AS ARAPObjectSettings
	|FROM
	|	TTTempTable AS TTTempTable";
	
	Return QueryText;
	
EndFunction

&AtServer
Procedure CustomizeWithLinkSeeAlso()
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("PurposeUseKey", "Invoices");
	
	ArrayCalculationManagersSeeAlsoInWork = New Array();
	ArrayCalculationManagersSeeAlsoInWork.Add("DataProcessor.LogOfPurchaseDocuments");
		
	SeeAlsoInProgress = TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayCalculationManagersSeeAlsoInWork, GenerationParameters);
	Items.SeeAlsoInProgress.Visible = ValueIsFilled(SeeAlsoInProgress);
	
EndProcedure

// Parameters:
//  Page - PanelPage
//  FormTable - FormTable
&AtClientAtServerNoContext
Procedure UpdateFormTable(Page, FormTable)
	
	If Page.Visible Then
		FormTable.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region RegistrationOfInvoice

&AtServer
Function IssueInvoicesForOrdersOnServer()
	
	Var ErrorList;
	
	// Breakdown of selected documents into groups
	DocumentsByTypesOfInvoices = OrderTablesSeparatedByKeyFields(ListOfOrders_, ErrorList);
	TotalTables = DocumentsByTypesOfInvoices.Count();
	
	If TotalTables > 0 Then
		
		// When placing orders, a new invoice is always created
		
		// The form of the created invoice opens, if the key fields of the selected lines match, and
		// the functional option allows Otherwise, a form with a list of created invoices opens.
		
		If DocumentsByTypesOfInvoices.Count() > 1 Then
			// Batch
			FormParameters = CreateInvoicesAccordingToTables(DocumentsByTypesOfInvoices, ErrorList);
		ElsIf DocumentsByTypesOfInvoices.Count() = 1 Then
			// Individually
			FormParameters = IssueInvoiceAccordingToTable(DocumentsByTypesOfInvoices, ErrorList);
		EndIf;
		
	ElsIf ListOfOrders_.Count() > 1 Then
		
		// Errors occurred when processing documents in batch mode
		
		ErrorText = NStr("vi = 'Không có chứng từ nào được chọn có thể được thực thi %1';
						|ru = 'Не выбрано ни одного документа, который можно было бы оформить %1';
						|en = 'No document which could be registered is selected %1'; fa = 'No document which could be registered is selected %1';
						|it = 'Non è stato selezionato alcun documento da formalizzare %1';
						|pl = 'Nie wybrano ani jednego dokumentu, który można byłoby zarejestrować %1';
						|tr = 'Düzenlenmek üzere hiçbir belge seçilmemiştir %1'");
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'theo đơn đặt hàng';
																							|ru = 'по заказам';
																							|en = 'on orders'; fa = 'on orders';
																							|it = 'per ordini';
																							|pl = 'wg zamówień';
																							|tr = 'siparişlere ilişkin'"));
		
		CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",ErrorText, Undefined);
		
	EndIf;
	
	If Not ValueIsFilled(FormParameters) Then
		FormParameters = New Structure();
	Else 
		UpdateFormTable(Items.PageOfTheOrderForRegistration, Items.ListReferencesForRegistration);
	EndIf;
	
	FormParameters.Insert("ErrorList", ErrorList);
	
	Return FormParameters;
	
EndFunction

// Parameters:
// 	DocumentsByTypesOfInvoices - Array of See SplitTableTemplate_
//
&AtServer
Function CreateInvoicesAccordingToTables(DocumentsByTypesOfInvoices, ErrorList)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("FormName", "DataProcessor.LogOfPurchaseDocuments.Form.FormCreatedDocuments");
	
	CreatedDocuments = New ValueList();
	
	For Each Table In DocumentsByTypesOfInvoices Do
		
		FirstRow = Table[0];
		If FirstRow.PurchaseState > 0 Then
			
			InvoiceFullName = FullNameOfInvoiceForBusinessTransaction(FirstRow.BusinessOperation);
			
			InvoiceManager = Common.ObjectManagerByFullName(InvoiceFullName);
			InvoiceMetadata = Metadata.FindByFullName(InvoiceFullName);
			
			Orders = Table.UnloadColumn("Ref");
			
			HeaderAttributes = New Structure;
			If Not PurchasesServerCall.GenerateReceiptFillingData(Orders, InvoiceMetadata.Name, HeaderAttributes) Then
				Return Undefined;
			EndIf;
			
			FillingData = New Structure;
			FillingData.Insert("WarehouseForReceipt",  Undefined);
			
			FillingData.Insert("HeaderAttributes",    HeaderAttributes);
			FillingData.Insert("DocumentBasis", Orders);
			
			DocumentObject = InvoiceManager.CreateDocument();
			DocumentObject.Fill(FillingData);
			
			SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(DocumentObject, InvoiceManager);
			ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters);
			
			DocumentObject.Date = CurrentSessionDate();
			
			DocumentWritten = True;
			
			Try
				DocumentObject.Write(DocumentWriteMode.Write)
			Except
				DocumentWritten = False;
				
				ErrorText = NStr("vi = 'Không thể tạo chứng từ %1 trên cơ sở chứng từ %2';
								|ru = 'Не удалось создать документ %1 на основании документа %2';
								|en = 'Cannot create document %1 based on document %2'; fa = 'Cannot create document %1 based on document %2';
								|it = 'Non è stato possibile creare un documento %1 in base al documento %2';
								|pl = 'Nie udało się stworzyć dokument %1 na podstawie dokumentu %2';
								|tr = '%2belgesine dayalı %1 belgesi oluşturulamadı'");
				
				ErrorText = StrTemplate(ErrorText, InvoiceMetadata.Synonym, Orders[0]);
				CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",
					ErrorText + " " + DocumentObject.Ref, Undefined);
			EndTry;
			
			If DocumentWritten Then
				// Add an entry to the user's work history.
				UserWorkHistory.Add(DocumentObject.Ref);
				CreatedDocuments.Add(DocumentObject.Ref);
				If DocumentObject.CheckFilling() Then
					Try
						DocumentObject.Write(DocumentWriteMode.Posting);
					Except
						ErrorText = NStr("vi = 'Không thể kết chuyển chứng từ';
										|ru = 'Не удалось провести документ';
										|en = 'Cannot post the document'; fa = 'Cannot post the document';
										|it = 'Non è possibile registrare il documento';
										|pl = 'Nie udało się zaksięgować dokument';
										|tr = 'Belge kaydedilemedi'");
						CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",
							ErrorText + " " + DocumentObject.Ref, Undefined);
					EndTry;
				Else
					ErrorText = NStr("vi = 'Không thể kết chuyển chứng từ';
									|ru = 'Не удалось провести документ';
									|en = 'Cannot post the document'; fa = 'Cannot post the document';
									|it = 'Non è possibile registrare il documento';
									|pl = 'Nie udało się zaksięgować dokument';
									|tr = 'Belge kaydedilemedi'");
					CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",
						ErrorText + " " + DocumentObject.Ref, Undefined);
				EndIf;
			EndIf;
			
		EndIf;
	EndDo;
	
	SetPrivilegedMode(True);
	Common.WriteDataToSecureStorage(Users.AuthorizedUser(),
														CreatedDocuments.UnloadValues(),
														"FormCreatedPurchaseDocuments");
	SetPrivilegedMode(False);
	
	FormParameters = New Structure("CreatedDocuments", CreatedDocuments);
	
	ParametersStructure.Insert("Parameters", FormParameters);
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Function IssueInvoiceAccordingToTable(DocumentsByTypesOfInvoices, ErrorList)
	
	CreatedDocuments = New ValueList();
	
	DocumentsTable = DocumentsByTypesOfInvoices[0]; // See SplitTableTemplate_
	SelectedRow = DocumentsTable[0];
	
	InvoiceFullName = FullNameOfInvoiceForBusinessTransaction(SelectedRow.BusinessOperation);
	InvoiceMetadata = Metadata.FindByFullName(InvoiceFullName);
	
	NameOfTheInvoiceForm = "Document." + InvoiceMetadata.Name + ".Form.DocumentForm";
	
	FormSettings = New Structure();
	FormParameters = New Structure();
	
	FormSettings.Insert("FormName", NameOfTheInvoiceForm);
	
	Orders = DocumentsTable.UnloadColumn("Ref");
	
	OrdersWaybills = New Array();
	For Each ReferenceOrder In Orders Do
		If FullNamesOfInvoices.FindByValue(ReferenceOrder.Metadata().FullName()) <> Undefined Then
			OrdersWaybills.Add(ReferenceOrder);
		EndIf;
	EndDo;
	
	Cancel = False;
		
	HeaderAttributes = New Structure;
	If Not PurchasesServerCall.GenerateReceiptFillingData(Orders, InvoiceMetadata.Name, HeaderAttributes) Then
		Cancel = True;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("WarehouseForReceipt",  Undefined);
	
	FormParameters.Insert("HeaderAttributes",    HeaderAttributes);
	FormParameters.Insert("DocumentBasis", Orders);
	
	// To display a message about the number of documents created
	CreatedDocuments.Add(PredefinedValue("Document." + InvoiceMetadata.Name + ".EmptyRef"));
	
	//Form parameters.Insert("Created documents", created documents);
	ParametersWithBase = New Structure("Basis", FormParameters);
	
	FormSettings.Insert("Parameters", ParametersWithBase);
	
	If Cancel Then
		Return Undefined;
	Else
		Return FormSettings;
	EndIf;
	
EndFunction

// Parameters:
// 	ListOfOrders_ - FormDataCollection - LongDesc
// 	ErrorList - ValueList - 
// Returns:
// 	Array - An array of See SplitTableTemplate_
&AtServer
Function OrderTablesSeparatedByKeyFields(ListOfOrders_, ErrorList) 
	KeyFields = "Department,Partner,Counterparty,Contract,Organization,Warehouse,Terms,"
		+"BusinessOperation,ARAPCurrency,VATTaxation,PriceIncludesVAT,"
		+"ARAPObjectSettings,ToReturnReusablePackage,LineOfBusiness,GoodsReceiptOption";
	
	CurrentKeys = New Structure(KeyFields);
	CurrentKeys.Insert("InvoiceFullName");
	CurrentKeys.Insert("PurchaseState");
	
	SplitTableTemplate = SplitTableTemplate_();
	
	SplitTable = Undefined;
	ArrayOfTables = New Array();
	
	ListOfOrders_.Sort("Ref, Warehouse, PurchaseState");
	
	BatchMode = ListOfOrders_.Count() > 1;
	
	For Each String In ListOfOrders_ Do
		
		If String.Ref = Undefined Then
			FullNameOfOrder = "";
		Else
			FullNameOfOrder = String.Ref.Metadata().FullName();
		EndIf; 
		
		InvoiceFullName = FullNameOfInvoiceForBusinessTransaction(String.BusinessOperation);
		
		ErrorText = "";
		AbortStringProcessing = False;
		
		If BatchMode And InvoiceFullName = FullNameOfOrder Then
			
			ErrorText = NStr("vi = 'Đối với đơn hàng %1, không thể điền lại hóa đơn với các đơn hàng khác. Chọn một đơn đặt hàng riêng.';
							|ru = 'Для распоряжения %1 невозможно перезаполнить накладную вместе с другими распоряжениями. Выберите распоряжение отдельно.';
							|en = 'Cannot refill the invoice with other references for reference %1. Select a reference separately.'; fa = 'Cannot refill the invoice with other references for reference %1. Select a reference separately.';
							|it = 'Per la disposizione %1 non è possibile ricompilare la bolla insieme alle altre disposizioni. Selezionare una disposizione separata.';
							|pl = 'Dla zamówienia %1 nie można wypełnić ponownie fakturę wraz z innymi zamówieniami. Wybierz zamówienie oddzielnie.';
							|tr = 'Bir sipariş için,%1 irsaliyeyi diğer siparişlerle birlikte yeniden doldurmak mümkün değildir. Siparişi ayrı olarak seçin.'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String.Ref);
			
			AbortStringProcessing = True;
			
		Else // execution by orders
			
			If String.PurchaseState = 0 Then
				
				ErrorText = NStr("vi = 'Một hóa đơn đã được tạo cho lệnh %1';
								|ru = 'Для распоряжения %1 уже создана накладная';
								|en = 'An invoice has already been created for the %1 reference'; fa = 'An invoice has already been created for the %1 reference';
								|it = 'Per la disposizione %1 è già creata una bolla';
								|pl = 'Dla zamówienia %1 została już utworzona faktura';
								|tr = '%1 emri için bir konşimento zaten oluşturuldu.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String.Ref);
				AbortStringProcessing = True;
				
			EndIf;
			
		EndIf;

		If Not IsBlankString(ErrorText) Then
			CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",ErrorText, Undefined);
		EndIf;
		
		If AbortStringProcessing Then
			Continue;
		EndIf;
		
		// Creating a new table in the following cases:
		// 1. The table has never been created yet
		// 2. It is forbidden to group several orders into one invoice
		// 3. The order is an invoice or the key fields are different (for example, 
		//	orders with different warehouses cannot be grouped into one invoice).
		
		If SplitTable = Undefined 
			Or Not UseReceiptForMultipleOrders
			Or InvoiceFullName <> CurrentKeys.InvoiceFullName 
			Or Not TMCommonUseClientServer.StructuresAreEqual(CurrentKeys,String,KeyFields) Then
			
			SplitTable = SplitTableTemplate.Copy();
			ArrayOfTables.Add(SplitTable); // Passing a reference to the current table to the array
			
			FillPropertyValues(CurrentKeys, String);
			CurrentKeys.InvoiceFullName = InvoiceFullName;
		EndIf;
		
		NewRow = SplitTable.Add();
		FillPropertyValues(NewRow, String);
		
	EndDo;
	
	Return ArrayOfTables;
	
EndFunction

&AtServer
Function FullNameOfInvoiceForBusinessTransaction(BusinessOperation)
	
	InvoiceFullName = Metadata.Documents.VendorInvoice.FullName();
	
	If BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then 
		InvoiceFullName = Metadata.Documents.GoodsReceiptForStorage.FullName();
	EndIf;
	
	Return InvoiceFullName;
	
EndFunction

// Returns:
// 	ValueTable:
// * Ref - DocumentRef
// * Warehouse - CatalogRef.Warehouses
// * BusinessOperation - EnumRef.BusinessTransactions
// * PurchaseState - Number
&AtServerNoContext
Function SplitTableTemplate_()
	
	SplitTableTemplate = New ValueTable();
	SplitTableTemplate.Columns.Add("Ref", Documents.AllRefsType());
	SplitTableTemplate.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	SplitTableTemplate.Columns.Add("BusinessOperation", New TypeDescription("EnumRef.BusinessTransactions"));
	SplitTableTemplate.Columns.Add("PurchaseState", New TypeDescription("Number"));

	Return SplitTableTemplate;
	
EndFunction

#EndRegion

#Region ExecutionByOrders

&AtServer
Function MakePurchasesOnServerByOrders()
	
	Var ErrorList;
	
	// Breakdown of selected documents into groups
	DocumentsByTypesOfInvoices = TablesOfAcquisitionsDividedByKeyFieldsForOrders(ListOfOrders_, ErrorList);
	TotalTables = DocumentsByTypesOfInvoices.Count();
	
	If TotalTables > 0 Then
		
		If DocumentsByTypesOfInvoices.Count() > 1 Then
			// Batch
			FormParameters = IssueNumberOfAcquisitionsAccordingToOrderControlTables(DocumentsByTypesOfInvoices, ErrorList);
		ElsIf DocumentsByTypesOfInvoices.Count() = 1 Then
			// Individually
			FormParameters = MakeAcquisitionUsingOrderControlTable(DocumentsByTypesOfInvoices, ErrorList);
		EndIf;
	ElsIf ListOfOrders_.Count() > 1 Then
		
		// Errors occurred when processing documents in batch mode
		
		ErrorText = NStr("vi = 'Chưa chọn chứng từ nào mà có thể lập %1';
						|ru = 'Не выбрано ни одного документа, который можно было бы оформить %1';
						|en = 'No document which could be registered is selected %1'; fa = 'No document which could be registered is selected %1';
						|it = 'Non è stato selezionato alcun documento da formalizzare %1';
						|pl = 'Nie wybrano ani jednego dokumentu, który można byłoby zarejestrować %1';
						|tr = 'Düzenlenmek üzere hiçbir belge seçilmemiştir %1'");
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'theo đơn hàng';
																							|ru = 'по заказам';
																							|en = 'on orders'; fa = 'on orders';
																							|it = 'per ordini';
																							|pl = 'wg zamówień';
																							|tr = 'siparişlere ilişkin'"));
		
		CommonClientServer.AddUserError(ErrorList, "Object.ListReceivingReferences",ErrorText, Undefined);
		
	EndIf;
	
	If Not ValueIsFilled(FormParameters) Then
		FormParameters = New Structure();
	Else 
		UpdateFormTable(Items.PageReceivingReferences, Items.ListReceivingReferences);
	EndIf;
	
	FormParameters.Insert("ErrorList", ErrorList);
	
	Return FormParameters;
	
EndFunction

// Parameters:
// 	ListOfOrders_ - FormDataCollection - LongDesc
// 	ErrorList - ValueList - 
// Returns:
// 	Array - An array of See SplitTableTemplate_
&AtServer
Function TablesOfAcquisitionsDividedByKeyFieldsForOrders(ListOfOrders_, ErrorList) 
	KeyFields = "Department,Partner,Counterparty,Contract,Organization,Warehouse,Terms,"
		+"BusinessOperation,ARAPCurrency,VATTaxation,PriceIncludesVAT,"
		+"ARAPObjectSettings,ToReturnReusablePackage,LineOfBusiness,GoodsReceiptOption,ThereAreRegisteredReceipts,NoteState,TypeOfOrder_";
		
	CurrentKeys = New Structure(KeyFields);
	CurrentKeys.Insert("InvoiceFullName");
	CurrentKeys.Insert("PurchaseState");
	
	SplitTableTemplate = SplitOrderControlTableTemplate();
	
	SplitTable = Undefined;
	ArrayOfTables = New Array();
	
	ListOfOrders_.Sort("Ref, Warehouse, PurchaseState, TypeOfOrder_");
	
	BatchMode = ListOfOrders_.Count() > 1;
	
	BusinessTransactionsReceiptOfGoods = BusinessTransactionsReceiptOfGoods();
	
	ThereAreRegisteredReceipts = False;
	
	For Each String In ListOfOrders_ Do
		
		If String.Ref = Undefined Then
			FullNameOfOrder = "";
		Else
			FullNameOfOrder = String.Ref.Metadata().FullName();
		EndIf; 
		InvoiceFullName = FullNameOfInvoiceForBusinessTransaction(String.BusinessOperation);
		
		ErrorText = "";
		AbortStringProcessing = False;
		
		
		If String.NoteState = 5 Then
			
			ErrorText = NStr("vi = 'Việc tràn chấp nhận %1 là không bắt buộc, vì không có đơn đặt hàng.';
							|ru = 'Перезаполнение по приемке %1 не требуется, так как нет ни одного ордера.';
							|en = 'It is not required to refill %1 receipt as there are no goods receipts.'; fa = 'It is not required to refill %1 receipt as there are no goods receipts.';
							|it = 'Ricompilazione dell''accettazione %1 non è richiesta perché no c''è alcun mandato.';
							|pl = 'Ponowne wypełnienie dla przyjęcia %1 nie jest wymagane, ponieważ nie ma ani jednego zlecenia.';
							|tr = 'Emir olmadığı için %1kabulüne ilişkin yeniden doldurmaya gerek yoktur.'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String.Ref);
			AbortStringProcessing = True;
			
		ElsIf BusinessTransactionsReceiptOfGoods.Find(String.BusinessOperation) <> Undefined Then
			
			String.ThereAreRegisteredReceipts = DeterminePresenceOfIssuedInvoices(String.Ref,
																				String.Warehouse,
																				String.BusinessOperation,
																				True,
																				True);
			
			If String.ThereAreRegisteredReceipts <> ThereAreRegisteredReceipts
				And ArrayOfTables.Count() > 0 Then
				
				ErrorText = NStr("vi = 'Trong chế độ đóng gói có thể tạo chứng từ mới hoặc điền lại.
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
					| İşlenmeyecek %1 belgeyi ayrı olarak seçin.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String.Ref);
				AbortStringProcessing = True;
			Else
				
				ThereAreRegisteredReceipts = String.ThereAreRegisteredReceipts
			EndIf;
			
		ElsIf TypeOf(String.Ref) = Type("DocumentRef.PurchaseOrder")
			Or TypeOf(String.Ref) = Type("CatalogRef.CounterpartyContracts")
			Or TypeOf(String.Ref) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
			
			String.ThereAreRegisteredReceipts = DeterminePresenceOfIssuedInvoices(String.Ref,
																			String.Warehouse,
																			String.BusinessOperation);
			
			If String.ThereAreRegisteredReceipts <> ThereAreRegisteredReceipts
				And ArrayOfTables.Count() > 0 Then
				
				ErrorText = NStr("vi = 'Trong chế độ đóng gói có thể tạo chứng từ mới hoặc điền lại.
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
					| İşlenmeyecek %1 belgeyi ayrı olarak seçin.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String.Ref);
				AbortStringProcessing = True;
			Else
				
				ThereAreRegisteredReceipts = String.ThereAreRegisteredReceipts;
			EndIf;
			
		ElsIf BatchMode And InvoiceFullName = FullNameOfOrder Then
			
			ErrorText = NStr("vi = 'Đối với đơn hàng %1, không thể điền lại hóa đơn với các đơn hàng khác. Chọn một đơn đặt hàng riêng.';
							|ru = 'Для распоряжения %1 невозможно перезаполнить накладную вместе с другими распоряжениями. Выберите распоряжение отдельно.';
							|en = 'Cannot refill the invoice with other references for reference %1. Select a reference separately.'; fa = 'Cannot refill the invoice with other references for reference %1. Select a reference separately.';
							|it = 'Per la disposizione %1 non è possibile ricompilare la bolla insieme alle altre disposizioni. Selezionare una disposizione separata.';
							|pl = 'Dla zamówienia %1 nie można wypełnić ponownie fakturę wraz z innymi zamówieniami. Wybierz zamówienie oddzielnie.';
							|tr = 'Bir sipariş için,%1 irsaliyeyi diğer siparişlerle birlikte yeniden doldurmak mümkün değildir. Siparişi ayrı olarak seçin.'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String.Ref);
			
			AbortStringProcessing = True;
			
		ElsIf Not (String.NoteState = 1
			And BusinessTransactionsReceiptOfGoods.Find(String.BusinessOperation) = Undefined
			And TypeOf(String.Ref) <> Type("DocumentRef.VendorInvoice"))
			And Not TypeOf(String.Ref) = Type("DocumentRef.VendorInvoice")
			And Not TypeOf(String.Ref) = Type("DocumentRef.GoodsReceiptForStorage")Then
			
			ErrorText = NStr("vi = 'Chứng từ %1 không yêu cầu chấp nhận hoặc mua lại';
							|ru = 'По документу %1 не требуется оформление приемки или приобретения';
							|en = 'The document %1 does not require a receipt or purchase'; fa = 'The document %1 does not require a receipt or purchase';
							|it = 'Per il documento %1 non è richiesta la registrazione dell''accettazione o acquisto';
							|pl = 'Dla dokumentu %1 nie wymaga się sporządzenie przyjęcia lub nabycia';
							|tr = '%1belgesi için bir kabul veya satın alım düzenlemesi gerekmemektedir'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String.Ref);
			AbortStringProcessing = True;
			
		EndIf;
		
		If AbortStringProcessing Then
			CommonClientServer.AddUserError(ErrorList, "Object.ListReceivingReferences",ErrorText, Undefined);
			Continue;
		EndIf;
		
		If SplitTable = Undefined 
			Or Not UseReceiptForMultipleOrders
			Or InvoiceFullName <> CurrentKeys.InvoiceFullName 
			Or Not TMCommonUseClientServer.StructuresAreEqual(CurrentKeys,String,KeyFields) Then
			
			SplitTable = SplitTableTemplate.Copy();
			ArrayOfTables.Add(SplitTable);
			
			FillPropertyValues(CurrentKeys, String);
			CurrentKeys.InvoiceFullName = InvoiceFullName;
		EndIf;
		
		NewRow = SplitTable.Add();
		FillPropertyValues(NewRow, String);
		
	EndDo;
	
	If ArrayOfTables.Count() > 1 And ThereAreRegisteredReceipts Then
		ArrayOfTables = New Array();
		ErrorText = NStr("vi = 'Bạn chỉ có thể phát hành lại hóa đơn cho các đơn hàng có cùng chi tiết quan trọng.';
						|ru = 'Переоформлять накладные можно только по заказам, имеющим одинаковые значимые реквизиты.';
						|en = 'The notes can be reissued only for orders with the same important attributes.'; fa = 'The notes can be reissued only for orders with the same important attributes.';
						|it = 'Le lettere di vettura possono essere riemesse solo per gli ordini che hanno gli stessi requisiti significativi.';
						|pl = 'Ponownie sporządzać faktury można tylko wg zamówień, mających jednakowe znaczne atrybuty.';
						|tr = 'Yalnızca eşit önemde özniteliklere sahip siparişler için yeniden irsaliye düzenleyebilirsiniz.'");
		CommonClientServer.AddUserError(ErrorList, "Object.ListReceivingReferences",ErrorText, Undefined);
	EndIf;
	
	Return ArrayOfTables;
	
EndFunction

&AtServer
Function IssueNumberOfAcquisitionsAccordingToOrderControlTables(DocumentsByTypesOfInvoices, ErrorList)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("FormName", "DataProcessor.LogOfPurchaseDocuments.Form.FormCreatedDocuments");
	
	CreatedDocuments = New ValueList();
	
	BusinessTransactionsReceiptOfGoods = BusinessTransactionsReceiptOfGoods();
	
	For Each Table In DocumentsByTypesOfInvoices Do
		
		FirstRow = Table[0];

		If BusinessTransactionsReceiptOfGoods.Find(FirstRow.BusinessOperation) <> Undefined Then
			InvoiceFullName = "Document.ReceiptOfGoodsToWarehouse";
		Else
			InvoiceFullName = FullNameOfInvoiceForBusinessTransaction(FirstRow.BusinessOperation);
		EndIf;
		
		InvoiceManager = Common.ObjectManagerByFullName(InvoiceFullName);
		InvoiceMetadata = Metadata.FindByFullName(InvoiceFullName);
		
		Orders = Table.UnloadColumn("Ref");
		
		If InvoiceFullName = "Document.ReceiptOfGoodsToWarehouse" Then
			
			For Each DocumentBasisForReceiptOfGoodsInWarehouse In Orders Do
				
				
				FillingData = New Structure;
				FillingData.Insert("DocumentBasis",            DocumentBasisForReceiptOfGoodsInWarehouse);
				FillingData.Insert("WarehouseForReceipt",             FirstRow.Warehouse);
				FillingData.Insert("EconomicOperationOfAcceptance", FirstRow.BusinessOperation);
				FillingData.Insert("FillByWarehouseDocument",            True);
				
				CreateDocumentOnServer(DocumentBasisForReceiptOfGoodsInWarehouse, InvoiceManager,
					InvoiceMetadata, FillingData, CreatedDocuments, ErrorList);
				
			EndDo;
			
		Else
			
			FillingData = New Structure;
			FillingData.Insert("DocumentBasis",            Orders);
			FillingData.Insert("WarehouseForReceipt",             FirstRow.Warehouse);
			FillingData.Insert("EconomicOperationOfAcceptance", FirstRow.BusinessOperation);
			FillingData.Insert("FillByWarehouseDocument",            True);
			
			CreateDocumentOnServer(Orders[0], InvoiceManager, InvoiceMetadata, FillingData, CreatedDocuments, ErrorList);
		EndIf;
				
	EndDo;
	
	SetPrivilegedMode(True);
	Common.WriteDataToSecureStorage(Users.AuthorizedUser(),
														CreatedDocuments.UnloadValues(),
														"FormCreatedPurchaseDocuments");
	SetPrivilegedMode(False);
	
	FormParameters = New Structure("CreatedDocuments", CreatedDocuments);
	
	ParametersStructure.Insert("Parameters", FormParameters);
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Procedure CreateDocumentOnServer(DocumentBasis, ManagerOfDocument, MetadataOfDocument, FillingData, CreatedDocuments, ErrorList)
	
	DocumentObject = ManagerOfDocument.CreateDocument();
	DocumentObject.Fill(FillingData);
	
	DocumentObject.Date = CurrentSessionDate();
	
	If DocumentObject.CheckFilling() Then
		
		DocumentObject.Write(DocumentWriteMode.Write);
		
		// Add an entry to the user's work history.
		UserWorkHistory.Add(DocumentObject.Ref);
		
		
		Try
			DocumentObject.Write(DocumentWriteMode.Posting);
			CreatedDocuments.Add(DocumentObject.Ref);
		Except
			ErrorText = NStr("vi = 'Không thể kết chuyển chứng từ';
							|ru = 'Не удалось провести документ';
							|en = 'Cannot post the document'; fa = 'Cannot post the document';
							|it = 'Non è possibile registrare il documento';
							|pl = 'Nie udało się zaksięgować dokument';
							|tr = 'Belge kaydedilemedi'");
			CommonClientServer.AddUserError(ErrorList, "Object.ListReceivingReferences",
				ErrorText + " " + DocumentObject.Ref, Undefined);
		EndTry;
		
	Else
		ErrorText = NStr("vi = 'Không thể tạo chứng từ %1 trên cơ sở chứng từ %2';
						|ru = 'Не удалось создать документ %1 на основании документа %2';
						|en = 'Cannot create document %1 based on document %2'; fa = 'Cannot create document %1 based on document %2';
						|it = 'Non è stato possibile creare un documento %1 in base al documento %2';
						|pl = 'Nie udało się stworzyć dokument %1 na podstawie dokumentu %2';
						|tr = '%2belgesine dayalı ""%1"" oluşturulamadı.'");
		ErrorText = StrTemplate(ErrorText, MetadataOfDocument.Synonym, DocumentBasis);
		CommonClientServer.AddUserError(ErrorList, "Object.ListReceivingReferences",
			ErrorText + " " + DocumentObject.Ref, Undefined);
	EndIf;
		
EndProcedure

&AtServer
Function MakeAcquisitionUsingOrderControlTable(DocumentsByTypesOfInvoices, ErrorList)
	
	CreatedDocuments = New ValueList();
	
	DocumentsTable = DocumentsByTypesOfInvoices[0]; // See SplitTableTemplate_
	SelectedRow = DocumentsTable[0];
	
	BusinessTransactionsReceiptOfGoods = BusinessTransactionsReceiptOfGoods();
	
	If SelectedRow.Ref = Undefined Then
		FullNameOfOrder = "";
	Else
		FullNameOfOrder = SelectedRow.Ref.Metadata().FullName();
	EndIf;
	
	If Not SelectedRow.ThereAreRegisteredReceipts
		And BusinessTransactionsReceiptOfGoods.Find(SelectedRow.BusinessOperation) <> Undefined Then
		
		InvoiceFullName = "Document.ReceiptOfGoodsToWarehouse";
	Else
		InvoiceFullName = FullNameOfInvoiceForBusinessTransaction(SelectedRow.BusinessOperation);
	EndIf;
	
	InvoiceMetadata = Metadata.FindByFullName(InvoiceFullName);
	
	NameOfTheInvoiceForm = "Document." + InvoiceMetadata.Name + ".Form.DocumentForm";
	
	FormSettings = New Structure();
	FormParameters = New Structure();
	
	FormSettings.Insert("FormName", NameOfTheInvoiceForm);
	
	Orders = DocumentsTable.UnloadColumn("Ref");
	
	OrdersWaybills = New Array();
	For Each ReferenceOrder In Orders Do
		If ReferenceOrder = Undefined Then
			YourFullName = "";
		Else
			YourFullName = ReferenceOrder.Metadata().FullName();
		EndIf;
		If FullNamesOfInvoices.FindByValue(YourFullName) <> Undefined Then
			OrdersWaybills.Add(ReferenceOrder);
		EndIf;
	EndDo;
	
	Cancel = False;
	
	If FullNameOfOrder = InvoiceFullName Then
		
		ParametersWithBase = New Structure("Key, FillByWarehouseDocument", SelectedRow.Ref, True);
		
	ElsIf SelectedRow.ThereAreRegisteredReceipts Then
		
		
		FormSettings.Insert("FormName", "CommonForm.ReregisterInvoicesByReferences");
		
		HeaderAttributes = New Structure;
		
		If TypeOf(SelectedRow.Ref) = Type("DocumentRef.PurchaseOrder") Then
			Cancel = Not PurchasesServerCall.GenerateReceiptFillingData(Orders, InvoiceMetadata.Name, HeaderAttributes);
		ElsIf TypeOf(SelectedRow.Ref) = Type("CatalogRef.CounterpartyContracts") Then
			HeaderAttributes = DetailsOfAgreementHeader(SelectedRow.Ref);
		ElsIf TypeOf(SelectedRow.Ref) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
			HeaderAttributes = PurchasesServerCall.GetPurchaseTermsAndConditions(Orders[0]);
			HeaderAttributes.BusinessOperation = SelectedRow.BusinessOperation;
		Else
			HeaderAttributes = PurchasesServerCall.GetPurchaseTermsAndConditions(Orders);
			HeaderAttributes.BusinessOperation = SelectedRow.BusinessOperation;
		EndIf;
		
		ParametersWithBase = New Structure;
		ParametersWithBase.Insert("Orders",         Orders);
		ParametersWithBase.Insert("HeaderAttributes", HeaderAttributes);
		ParametersWithBase.Insert("Warehouse",          SelectedRow.Warehouse);
		ParametersWithBase.Insert("FormSettings", SettingsOfInvoiceReissueForm);
		
		// To display a message about the number of documents created
		CreatedDocuments.Add(PredefinedValue("Document." + InvoiceMetadata.Name + ".EmptyRef"));
		
	ElsIf InvoiceFullName = "Document.ReceiptOfGoodsToWarehouse"
		And Orders.Count() > 1 Then
		
		InvoiceManager = Common.ObjectManagerByFullName(InvoiceFullName);
		
		CreatedDocuments = New ValueList();
		
			For Each DocumentBasisForReceiptOfGoodsInWarehouse In Orders Do
				
				FillingData = New Structure;
				FillingData.Insert("DocumentBasis",            DocumentBasisForReceiptOfGoodsInWarehouse);
				FillingData.Insert("WarehouseForReceipt",             SelectedRow.Warehouse);
				FillingData.Insert("EconomicOperationOfAcceptance", SelectedRow.BusinessOperation);
				FillingData.Insert("FillByWarehouseDocument",            True);
				
				CreateDocumentOnServer(DocumentBasisForReceiptOfGoodsInWarehouse, InvoiceManager,
					InvoiceMetadata, FillingData, CreatedDocuments, ErrorList);
				
			EndDo;
			
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Users.AuthorizedUser(),
														CreatedDocuments.UnloadValues(),
														"FormCreatedPurchaseDocuments");
		SetPrivilegedMode(False);
	
		ParametersWithBase = New Structure("CreatedDocuments", CreatedDocuments);
		
		FormSettings.Insert("FormName", "DataProcessor.LogOfPurchaseDocuments.Form.FormCreatedDocuments");
	
	Else
		
		FormParameters = New Structure;
		FormParameters.Insert("DocumentBasis",            SelectedRow.Ref);
		FormParameters.Insert("WarehouseForReceipt",             SelectedRow.Warehouse);
		FormParameters.Insert("EconomicOperationOfAcceptance", SelectedRow.BusinessOperation);
		FormParameters.Insert("FillByWarehouseDocument",            True);
		
		ParametersWithBase = New Structure("Basis, FillByWarehouseDocument", FormParameters, True);
		
		// To display a message about the number of documents created
		CreatedDocuments.Add(PredefinedValue("Document." + InvoiceMetadata.Name + ".EmptyRef"));
		
	EndIf;
	
	
	FormSettings.Insert("Parameters", ParametersWithBase);
	
	If Cancel Then
		Return Undefined;
	Else
		Return FormSettings;
	EndIf;
	
EndFunction

&AtServer
Function IssueReportsOnServer()
	
	Var ErrorList;
	
	// Breakdown of selected documents into groups
	DocumentsByTypesOfInvoices = AcquisitionTablesSeparatedByKeyFields(ListOfOrders_, ErrorList);
	TotalTables = DocumentsByTypesOfInvoices.Count();
	
	If TotalTables > 0 Then
		
		If DocumentsByTypesOfInvoices.Count() > 1 Then
			// Batch
			FormParameters = IssueNumberOfActsAccordingToTables(DocumentsByTypesOfInvoices, ErrorList);
		ElsIf DocumentsByTypesOfInvoices.Count() = 1 Then
			// Individually
			FormParameters = IssueReportAccordingToTable(DocumentsByTypesOfInvoices, ErrorList);
		EndIf;
	ElsIf ListOfOrders_.Count() > 1 Then
		
		// Errors occurred when processing documents in batch mode
		
		ErrorText = NStr("vi = 'Không có chứng từ nào được chọn có thể được thực thi %1';
						|ru = 'Не выбрано ни одного документа, который можно было бы оформить %1';
						|en = 'No document which could be registered is selected %1'; fa = 'No document which could be registered is selected %1';
						|it = 'Non è stato selezionato alcun documento da formalizzare %1';
						|pl = 'Nie wybrano ani jednego dokumentu, który można byłoby zarejestrować %1';
						|tr = 'Düzenlenmek üzere hiçbir belge seçilmemiştir %1'");
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'theo đơn đặt hàng';
																							|ru = 'по заказам';
																							|en = 'on orders'; fa = 'on orders';
																							|it = 'per ordini';
																							|pl = 'wg zamówień';
																							|tr = 'siparişlere ilişkin'"));
		
		CommonClientServer.AddUserError(ErrorList, "Object.ListReceivingReferences",ErrorText, Undefined);
		
	EndIf;
	
	If Not ValueIsFilled(FormParameters) Then
		FormParameters = New Structure();
	Else 
		UpdateFormTable(Items.PageReceivingReferences, Items.ListReceivingReferences);
	EndIf;
	
	FormParameters.Insert("ErrorList", ErrorList);
	
	Return FormParameters;
	
EndFunction

// Parameters:
// 	ListOfOrders_ - FormDataCollection - LongDesc
// 	ErrorList - ValueList - 
// Returns:
// 	Array - An array of See SplitTableTemplateForAct
&AtServer
Function AcquisitionTablesSeparatedByKeyFields(ListOfOrders_, ErrorList) 
	KeyFields = "Organization,Counterparty,VATTaxation,Partner,Currency,BusinessOperation,PriceIncludesVAT,Contract,Terms,Department";
	
	CurrentKeys = New Structure(KeyFields);
	CurrentKeys.Insert("InvoiceFullName");
	CurrentKeys.Insert("PurchaseState");
	
	SplitTableTemplate = SplitTableTemplateForAct();
	
	SplitTable = Undefined;
	ArrayOfTables = New Array();
	
	ListOfOrders_.Sort("Ref, Warehouse, PurchaseState, TypeOfOrder_");
	
	BusinessTransactionsProhibitedInActOnDiscrepancies = BusinessTransactionsProhibitedInActOnDiscrepancies();
	
	ArrayOfDocumentTypesReceipts = New Array;
	ArrayOfDocumentTypesReceipts.Add(Type("DocumentRef.VendorInvoice"));
	ArrayOfDocumentTypesReceipts.Add(Type("DocumentRef.GoodsReceiptForStorage"));
	
	For Each String In ListOfOrders_ Do
		
		InvoiceFullName = FullNameOfInvoiceForBusinessTransaction(String.BusinessOperation);
		
		ErrorText = "";
		AbortStringProcessing = False;
		
		If ArrayOfDocumentTypesReceipts.Find(TypeOf(String.Ref)) = Undefined Then
			If UseCustodyDuringPurchase Then
				ErrorText = NStr("vi = 'Đối với lệnh %1 không thể tạo biên bản chênh lệch.
					|Hãy chọn dòng có kiểu lệnh ""Tiếp nhận hàng hóa và dịch vụ"" hoặc ""Nhập hàng vào kho"".';
					|ru = 'Для распоряжения %1 невозможно создать акт о расхождениях.
					|Выберите строку с типом распоряжения ""Приобретение товаров и услуг"" или ""Приемка товаров на хранение"".';
					|en = 'You cannot create a discrepancy report for the reference %1.
					|Select a line with reference of ""Vendor invoice"" or ""VMI procurement"" type.'; fa = 'You cannot create a discrepancy report for the reference %1.
					|Select a line with reference of ""Vendor invoice"" or ""VMI procurement"" type.';
					|it = 'Per la disposizione %1 impossibile creare l''atto sulle discrepanze. 
					| Seleziona la riga con il tipo di disposizione ""Acquisto di merci e servizi"" o ""Accettazione di merci in deposito"".';
					|pl = 'Dla zamówienia %1 niemożliwe jest utworzenie protokołu o odchyleniu.
					|Wybierz wiersz o typie zamówienia ""Nabycie towarów i usług"" lub ""Przyjęcie towarów do przechowywania"".';
					|tr = 'Bir sipariş için %1 tutarsızlık raporu oluşturulamıyor.
					| ""Satın alma faturası"" veya ""Mal girişi"" sipariş türüne sahip satırı seçin.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String.Ref);
				AbortStringProcessing = True;
			Else
				ErrorText = NStr("vi = 'Đối với lệnh %1 không thể tạo biên bản chênh lệch.
					|Hãy chọn dòng có kiểu lệnh ""Mua hàng hóa và dịch vụ"".';
					|ru = 'Для распоряжения %1 невозможно создать акт о расхождениях.
					|Выберите строку с типом распоряжения ""Приобретение товаров и услуг"".';
					|en = 'You cannot create a discrepancy report for the reference %1.
					|Select a line with reference of ""Vendor invoice"" type.'; fa = 'You cannot create a discrepancy report for the reference %1.
					|Select a line with reference of ""Vendor invoice"" type.';
					|it = 'Per la disposizione %1 impossibile creare l''atto di discrepanze.
					| Seleziona la riga con il tipo di disposizione ""Acquisto di merci e servizi"".';
					|pl = 'Dla zamówienia %1 niemożliwe jest utworzenie protokołu o odchyleniu.
					|Wybierz wiersz o typie zamówienia  ""Nabycie towarów i usług"".';
					|tr = 'Bir sipariş için %1 tutarsızlık raporu oluşturulamıyor.
					| ""Satın alma faturası"" sipariş türüne sahip satırı seçin.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String.Ref);
				AbortStringProcessing = True;
			EndIf;
			
		ElsIf BusinessTransactionsProhibitedInActOnDiscrepancies.Find(String.BusinessOperation) <> Undefined Then
			NameOfAct = ?(TypeOf(String.Ref) = Type("DocumentRef.VendorInvoice"),
				NStr("vi = 'nhập hàng';
					|ru = 'приемки';
					|en = 'receipts'; fa = 'receipts';
					|it = 'di accettazione';
					|pl = 'odbiory';
					|tr = 'kabuller'"),
				NStr("vi = 'nhập hàng';
					|ru = 'приемки';
					|en = 'receipts'; fa = 'receipts';
					|it = 'di accettazione';
					|pl = 'odbiory';
					|tr = 'kabuller'"));
			
			ErrorText = NStr("vi = 'Không thể lập chứng từ ""Biên bản chênh lệch sau %1 ""trên cơ sở lệnh %2 với giao dịch ""%3 "".';
							|ru = 'Невозможно оформить документ ""Акт о расхождениях после %1"" на основании распоряжения %2 с операцией ""%3"".';
							|en = 'Cannot register the ""Discrepancy report following %1"" based on the %2 reference with the ""%3"" operation.'; fa = 'Cannot register the ""Discrepancy report following %1"" based on the %2 reference with the ""%3"" operation.';
							|it = 'È impossibile formalizzare il documento ""Atto di divergenze dopo %1"" in base alla disposizione %2 con operazione ""%3"".';
							|pl = 'Nie można zarejestrować dokumentu ""Protokół o odchyleniu po %1"" na podstawie zamówienia %2 z operacją ""%3"".';
							|tr = '""%3"" işlemi ile ""%2"" siparişi temelinde bir ""%1sonrası tutarsızlık raporu"" düzenlemek mümkün değildir.'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
				NameOfAct,
				String(String.Ref),
				String(String.BusinessOperation));
			AbortStringProcessing = True;
			
		EndIf;
		
		If Not IsBlankString(ErrorText) Then
			CommonClientServer.AddUserError(ErrorList, "Object.ListReceivingReferences",ErrorText, Undefined);
		EndIf;
		
		If AbortStringProcessing Then
			Continue;
		EndIf;
		
		If SplitTable = Undefined 
			Or Not UseReceiptForMultipleOrders
			Or InvoiceFullName <> CurrentKeys.InvoiceFullName 
			Or Not TMCommonUseClientServer.StructuresAreEqual(CurrentKeys,String,KeyFields) Then
			
			SplitTable = SplitTableTemplate.Copy();
			ArrayOfTables.Add(SplitTable);
			
			FillPropertyValues(CurrentKeys, String);
			CurrentKeys.InvoiceFullName = InvoiceFullName;
		EndIf;
		
		NewRow = SplitTable.Add();
		FillPropertyValues(NewRow, String);
		
	EndDo;
	
	Return ArrayOfTables;
	
EndFunction

&AtServer
Function IssueNumberOfActsAccordingToTables(DocumentsByTypesOfInvoices, ErrorList)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("FormName", "DataProcessor.LogOfPurchaseDocuments.Form.FormCreatedDocuments");
	
	CreatedDocuments = New ValueList();
	
	For Each Table In DocumentsByTypesOfInvoices Do
		
		FirstRow = Table[0];
		
		FullNameOfAct = Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName();
		ActManager = Common.ObjectManagerByFullName(FullNameOfAct);
		ActMetadata = Metadata.FindByFullName(FullNameOfAct);
		
		Orders = Table.UnloadColumn("Ref");
		
		HeaderAttributes = New Structure;
		If Not PurchasesServerCall.GenerateReceiptFillingData(Orders, ActMetadata.Name, HeaderAttributes) Then
			Return Undefined;
		EndIf;
		
		FillingData = New Structure;
		FillingData.Insert("DocumentBasis", Orders);
		FillingData.Insert("BasisType", FirstRow.TypeOfOrder_);
		
		DocumentObject = ActManager.CreateDocument();
		DocumentObject.Fill(FillingData);
		
		DocumentObject.Date = CurrentSessionDate();
		
		If DocumentObject.CheckFilling() Then
			
			DocumentObject.Write(DocumentWriteMode.Write);
			
			// Add an entry to the user's work history.
			UserWorkHistory.Add(DocumentObject.Ref);
			CreatedDocuments.Add(DocumentObject.Ref);
			
			Try
				DocumentObject.Write(DocumentWriteMode.Posting);
			Except
				ErrorText = NStr("vi = 'Không thể kết chuyển chứng từ';
								|ru = 'Не удалось провести документ';
								|en = 'Cannot post the document'; fa = 'Cannot post the document';
								|it = 'Non è possibile registrare il documento';
								|pl = 'Nie udało się zaksięgować dokument';
								|tr = 'Belge kaydedilemedi'");
				CommonClientServer.AddUserError(ErrorList, "Object.ListReceivingReferences",
					ErrorText + " " + DocumentObject.Ref, Undefined);
			EndTry;
			
		Else
			ErrorText = NStr("vi = 'Không thể tạo chứng từ %1 trên cơ sở chứng từ %2';
							|ru = 'Не удалось создать документ %1 на основании документа %2';
							|en = 'Cannot create document %1 based on document %2'; fa = 'Cannot create document %1 based on document %2';
							|it = 'Non è stato possibile creare un documento %1 in base al documento %2';
							|pl = 'Nie udało się stworzyć dokument %1 na podstawie dokumentu %2';
							|tr = '%2belgesine dayalı %1 belgesi oluşturulamadı.'");
			ErrorText = StrTemplate(ErrorText, ActMetadata.Synonym, Orders[0]);
			CommonClientServer.AddUserError(ErrorList, "Object.ListReceivingReferences",
				ErrorText + " " + DocumentObject.Ref, Undefined);
		EndIf;
			
	EndDo;
	
	SetPrivilegedMode(True);
	Common.WriteDataToSecureStorage(Users.AuthorizedUser(),
														CreatedDocuments.UnloadValues(),
														"FormCreatedPurchaseDocuments");
	SetPrivilegedMode(False);
	
	FormParameters = New Structure("CreatedDocuments", CreatedDocuments);
	
	ParametersStructure.Insert("Parameters", FormParameters);
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Function IssueReportAccordingToTable(DocumentsByTypesOfInvoices, ErrorList)
	
	CreatedDocuments = New ValueList();
	
	DocumentsTable = DocumentsByTypesOfInvoices[0];
	SelectedRow = DocumentsTable[0];
	
	FullNameOfAct = Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName();
	ActMetadata = Metadata.FindByFullName(FullNameOfAct);
	
	ReportFormName_ = "Document." + ActMetadata.Name + ".Form.DocumentForm";
	
	FormSettings = New Structure();
	FormParameters = New Structure();
	
	FormSettings.Insert("FormName", ReportFormName_);
	
	Orders = DocumentsTable.UnloadColumn("Ref");
	
	OrdersWaybills = New Array();
	For Each ReferenceOrder In Orders Do
		If FullNamesOfInvoices.FindByValue(ReferenceOrder.Metadata().FullName()) <> Undefined Then
			OrdersWaybills.Add(ReferenceOrder);
		EndIf;
	EndDo;
	
	Cancel = False;
		
	HeaderAttributes = New Structure;
	If Not PurchasesServerCall.GenerateReceiptFillingData(Orders, ActMetadata.Name, HeaderAttributes) Then
		Cancel = True;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("WarehouseForReceipt",  Undefined);
	FormParameters.Insert("HeaderAttributes",    HeaderAttributes);
	FormParameters.Insert("DocumentBasis", Orders);
	FormParameters.Insert("BasisType",      SelectedRow.TypeOfOrder_);
	
	// To display a message about the number of documents created
	CreatedDocuments.Add(PredefinedValue("Document." + ActMetadata.Name + ".EmptyRef"));
	
	//Form parameters.Insert("Created documents", created documents);
	ParametersWithBase = New Structure("Basis, RefillByReceiving", FormParameters, True);
	
	FormSettings.Insert("Parameters", ParametersWithBase);
	
	If Cancel Then
		Return Undefined;
	Else
		Return FormSettings;
	EndIf;
	
EndFunction

// Returns:
// 	ValueTable - LongDesc:
// * Ref - DocumentRef - 
// * BusinessOperation - EnumRef.BusinessTransactions -
// * PurchaseState - Number -
// * TypeOfOrder_ - Type -
&AtServerNoContext
Function SplitTableTemplateForAct()
	
	SplitTableTemplate = New ValueTable();
	SplitTableTemplate.Columns.Add("Ref", Documents.AllRefsType());
	//The template is separated by a table.Columns.Add("Warehouse", A new description of types("Reference Link.Warehouses"));
	SplitTableTemplate.Columns.Add("BusinessOperation", New TypeDescription("EnumRef.BusinessTransactions"));
	//The template is separated by a table.Columns.Add("Acquisition States", New Type Description("Number"));
	SplitTableTemplate.Columns.Add("TypeOfOrder_", New TypeDescription("Type"));
	
	Return SplitTableTemplate;
	
EndFunction

// Returns:
// 	ValueTable:
// * Ref - DocumentRef
// * Warehouse - CatalogRef.Warehouses
// * BusinessOperation - EnumRef.BusinessTransactions
// * PurchaseState - Number
// * ThereAreRegisteredReceipts - Boolean
&AtServerNoContext
Function SplitOrderControlTableTemplate()
	
	ListOfTypes= New Array;
	ListOfTypes.Add(Catalogs.AllRefsType());
	ListOfTypes.Add(Documents.AllRefsType());
	
	SplitTableTemplate = New ValueTable();
	SplitTableTemplate.Columns.Add("Ref", New TypeDescription(ListOfTypes));
	SplitTableTemplate.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	SplitTableTemplate.Columns.Add("BusinessOperation", New TypeDescription("EnumRef.BusinessTransactions"));
	SplitTableTemplate.Columns.Add("PurchaseState", New TypeDescription("Number"));
	SplitTableTemplate.Columns.Add("ThereAreRegisteredReceipts", New TypeDescription("Boolean"));

	Return SplitTableTemplate;
	
EndFunction

#EndRegion

#Region ToReceiptFormalization

&AtServer
Function IssueReceiptsForOrdersOnServer(TheseAreServices)
	
	Var ErrorList;
	
	// Breakdown of selected documents into groups
	DocumentsByTypesOfInvoices = TablesOfOrdersSeparatedByKeyFieldsForReceipts(ListOfOrders_, ErrorList, TheseAreServices);
	TotalTables = DocumentsByTypesOfInvoices.Count();
	
	If TotalTables > 0 Then
		
		If DocumentsByTypesOfInvoices.Count() > 1 Then
			// Batch
			FormParameters = IssueNumberOfReceiptsAccordingToTables(DocumentsByTypesOfInvoices, ErrorList, TheseAreServices);
		ElsIf DocumentsByTypesOfInvoices.Count() = 1 Then
			// Individually
			FormParameters = IssueReceiptAccordingToTable(DocumentsByTypesOfInvoices, ErrorList, TheseAreServices);
		EndIf;
	ElsIf ListOfOrders_.Count() > 1 Then
		
		// Errors occurred when processing documents in batch mode
		
		ErrorText = NStr("vi = 'Không có chứng từ nào được chọn có thể được thực thi %1';
						|ru = 'Не выбрано ни одного документа, который можно было бы оформить %1';
						|en = 'No document which could be registered is selected %1'; fa = 'No document which could be registered is selected %1';
						|it = 'Non è stato selezionato alcun documento da formalizzare %1';
						|pl = 'Nie wybrano ani jednego dokumentu, który można byłoby zarejestrować %1';
						|tr = 'Düzenlenmek üzere hiçbir belge seçilmemiştir %1'");
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'theo đơn đặt hàng';
																							|ru = 'по заказам';
																							|en = 'on orders'; fa = 'on orders';
																							|it = 'per ordini';
																							|pl = 'wg zamówień';
																							|tr = 'siparişlere ilişkin'"));
		
		CommonClientServer.AddUserError(ErrorList, "Object.ListReceiptReferences",ErrorText, Undefined);
		
	EndIf;
	
	If Not ValueIsFilled(FormParameters) Then
		FormParameters = New Structure();
	Else 
		UpdateFormTable(Items.ReceiptOrderPage, Items.ListReceiptReferences);
	EndIf;
	
	FormParameters.Insert("ErrorList", ErrorList);
	
	Return FormParameters;
	
EndFunction

// Parameters:
// 	DocumentsByTypesOfInvoices - Array of See SplitTableTemplateForReceiptRegistration
&AtServer
Function IssueNumberOfReceiptsAccordingToTables(DocumentsByTypesOfInvoices, ErrorList, TheseAreServices)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("FormName", "DataProcessor.LogOfPurchaseDocuments.Form.FormCreatedDocuments");
	
	CreatedDocuments = New ValueList();
	
	For Each Table In DocumentsByTypesOfInvoices Do
		
		FirstRow = Table[0];
		
		FillingData = New Structure;
		FillingData.Insert("DocumentBasis",				FirstRow.Ref);
		FillingData.Insert("EconomicOperationOfAcceptance",	FirstRow.BusinessOperation);
		FillingData.Insert("FillInUsingInvoice",			FirstRow.FillInUsingInvoice);
		
		If Not TheseAreServices Then
			FillingData.Insert("WarehouseForReceipt", FirstRow.Warehouse);
			
			DocumentManager = Documents.ReceiptOfGoodsToWarehouse;
		Else
			DocumentManager = Documents.ReceiptOfServicesToBusinessUnit;
		EndIf;
		
		DocumentObject = DocumentManager.CreateDocument();
		DocumentObject.Fill(FillingData);
		DocumentObject.Date = CurrentSessionDate();
		
		If Not TheseAreServices Then
			SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(DocumentObject, DocumentManager);
			ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters);
		EndIf;
		
		DocumentWritten = True;
		
		Try
			DocumentObject.Write(DocumentWriteMode.Write)
		Except
			DocumentWritten = False;
			
			If TheseAreServices Then
				ErrorText = NStr("vi = 'Không thể tạo chứng từ ""Tiếp nhận dịch vụ vào bộ phận"" trên cơ sở chứng từ %1';
								|ru = 'Не удалось создать документ ""Поступления услуг в подразделение"" на основании документа %1';
								|en = 'Cannot create the ""Receipts of services to business unit"" document based on the %1 document'; fa = 'Cannot create the ""Receipts of services to business unit"" document based on the %1 document';
								|it = 'Не удалось создать документ ""Поступления услуг в подразделение"" на основании документа %1';
								|pl = 'Cannot create the ""Receipts of services to business unit"" document based on the %1 document';
								|tr = '%1 belgesine dayalı olarak ""Departmana hizmet makbuzları"" belgesi oluşturulamadı'");
			Else
				ErrorText = NStr("vi = 'Không thể tạo chứng từ Biên nhận hàng hóa trên cơ sở chứng từ %1';
								|ru = 'Не удалось создать документ ""Поступления товаров"" на основании документа %1';
								|en = 'It was not possible to create the ""Goods pick-up from customer"" document based on the document %1'; fa = 'It was not possible to create the ""Goods pick-up from customer"" document based on the document %1';
								|it = 'Impossibile creare il documento ""Arrivo di merci"" in base al documento %1';
								|pl = 'Nie udało się utworzyć dokumentu ""Wpływ towarów"" na podstawie dokumentu %1';
								|tr = '%1 belgesine dayalı olarak ""İrsaliye makbuzu"" oluşturulamadı'");
			EndIf;
			
			ErrorText = StrTemplate(ErrorText, FirstRow.Ref);
			CommonClientServer.AddUserError(
				ErrorList,
				"Object.ListReferencesForRegistration",
				ErrorText + " " + DocumentObject.Ref,
				Undefined);
		EndTry;
		
		If DocumentWritten Then
			// Add an entry to the user's work history.
			UserWorkHistory.Add(DocumentObject.Ref);
			CreatedDocuments.Add(DocumentObject.Ref);
			
			If DocumentObject.CheckFilling() Then
				Try
					DocumentObject.Write(DocumentWriteMode.Posting);
				Except
					ErrorText = NStr("vi = 'Không thể kết chuyển chứng từ';
									|ru = 'Не удалось провести документ';
									|en = 'Cannot post the document'; fa = 'Cannot post the document';
									|it = 'Non è possibile registrare il documento';
									|pl = 'Nie udało się zaksięgować dokument';
									|tr = 'Belge kaydedilemedi'");
					CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",
						ErrorText + " " + DocumentObject.Ref, Undefined);
				EndTry;
			EndIf;
		EndIf;
			
	EndDo;
	
	SetPrivilegedMode(True);
	Common.WriteDataToSecureStorage(Users.AuthorizedUser(),
														CreatedDocuments.UnloadValues(),
														"FormCreatedPurchaseDocuments");
	SetPrivilegedMode(False);
	
	FormParameters = New Structure("CreatedDocuments", CreatedDocuments);
	
	ParametersStructure.Insert("Parameters", FormParameters);
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Function IssueReceiptAccordingToTable(DocumentsByTypesOfInvoices, ErrorList, TheseAreServices)
	
	CreatedDocuments = New ValueList();
	
	DocumentsTable = DocumentsByTypesOfInvoices[0]; // See SplitTableTemplateForReceiptRegistration
	SelectedRow = DocumentsTable[0];
	
	If TheseAreServices Then
		
		NameOfTheInvoiceForm = "Document.ReceiptOfServicesToBusinessUnit.Form.DocumentForm";
		
	Else
		
		NameOfTheInvoiceForm = "Document.ReceiptOfGoodsToWarehouse.Form.DocumentForm";
		
	EndIf;
	
	FormSettings = New Structure();
	FormParameters = New Structure();
	
	FormSettings.Insert("FormName", NameOfTheInvoiceForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("DocumentBasis",            SelectedRow.Ref);
	FormParameters.Insert("FillInUsingInvoice",         SelectedRow.FillInUsingInvoice);
	FormParameters.Insert("EconomicOperationOfAcceptance", SelectedRow.BusinessOperation);
	
	If Not TheseAreServices Then
		
		FormParameters.Insert("WarehouseForReceipt",             SelectedRow.Warehouse);
		
	EndIf;
	
	// To display a message about the number of documents created
	If TheseAreServices Then
		
		CreatedDocuments.Add(PredefinedValue("Document.ReceiptOfServicesToBusinessUnit.EmptyRef"));
		
	Else
		
		CreatedDocuments.Add(PredefinedValue("Document.ReceiptOfGoodsToWarehouse.EmptyRef"));
		
	EndIf;
	
	ParametersWithBase = New Structure("Basis", FormParameters);
	
	FormSettings.Insert("Parameters", ParametersWithBase);
	
	Return FormSettings;
	
EndFunction

// Parameters:
// 	ListOfOrders_ - FormDataCollection - LongDesc
// 	ErrorList - ValueList - 
// Returns:
// 	Array - An array of See SplitTableTemplateForReceiptRegistration
&AtServer
Function TablesOfOrdersSeparatedByKeyFieldsForReceipts(ListOfOrders_, ErrorList, TheseAreServices)
	KeyFields = "Ref";
	
	CurrentKeys = New Structure(KeyFields);
	CurrentKeys.Insert("InvoiceFullName");
	CurrentKeys.Insert("PurchaseState");
	
	SplitTableTemplate = SplitTableTemplateForReceiptRegistration();
	
	SplitTable = Undefined;
	ArrayOfTables = New Array();
	
	ListOfOrders_.Sort(KeyFields);
	
	If TheseAreServices Then
		
		ErrorTemplate = NStr("vi = 'Theo lệnh %1 không cần tạo chứng từ ""Tiếp nhận dịch vụ"".';
							|ru = 'По распоряжению %1 оформление документа ""Поступление услуг"" не требуется.';
							|en = 'The ""Receipt of services"" document is not required by the %1 reference.'; fa = 'The ""Receipt of services"" document is not required by the %1 reference.';
							|it = 'По распоряжению %1 оформление документа ""Поступление услуг"" не требуется.';
							|pl = 'The ""Receipt of services"" document is not required by the %1 reference.';
							|tr = '""Hizmet makbuzu"" belgesinin bir %1siparişi kapsamında düzenlenmesi gerekmemektedir.'");
		
	Else
		
		ErrorTemplate = NStr("vi = 'Theo đơn đặt hàng %1, việc thực hiện chứng từ Nhận hàng hóa Nhận là không bắt buộc.';
							|ru = 'По распоряжению %1 оформление документа ""Поступление товаров"" не требуется.';
							|en = 'The ""Goods pick-up from customer"" document is not required by the %1 reference.'; fa = 'The ""Goods pick-up from customer"" document is not required by the %1 reference.';
							|it = 'Non è necessario emettere il documento ""Arrivo di merci"" per la disposizione %1.';
							|pl = 'Dla zamówienia %1 sporządzenie dokumentu ""Wpływ towarów"" nie jest wymagane.';
							|tr = '""İrsaliye"" belgesinin bir sipariş kapsamında%1 düzenlenmesi gerekmemektedir.'");
		
	EndIf;
	
	For Each String In ListOfOrders_ Do
		
		AbortStringProcessing = False;
		String.FillInUsingInvoice = True;
		
		If (Not TheseAreServices
			And Not String.ThereAreProducts_)
			Or (TheseAreServices
			And Not String.ThereAreServices) Then
			
			AbortStringProcessing = True;
			
		ElsIf String.GoodsReceiptState = 0
			Or String.ReferenceReceiptState = 0 Then
			
			AbortStringProcessing = True;
			
		ElsIf String.PurchaseReceiptState = 1
			Or (String.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt")
				Or String.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery")) Then
			
			String.FillInUsingInvoice = False;
			
		ElsIf (Not String.FillInUsingInvoice
				And String.PurchaseReceiptState = 3)
			Or String.PurchaseReceiptState = 0 Then
			
			AbortStringProcessing = True;
			
		EndIf;
		
		If AbortStringProcessing Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, String.Ref);
			CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",ErrorText, Undefined);
			Continue;
		EndIf;
		
		If SplitTable = Undefined 
			Or Not UseReceiptForMultipleOrders
			Or Not TMCommonUseClientServer.StructuresAreEqual(CurrentKeys,String,KeyFields) Then
			
			SplitTable = SplitTableTemplate.Copy();
			ArrayOfTables.Add(SplitTable);
			
			FillPropertyValues(CurrentKeys, String);
		EndIf;
		
		NewRow = SplitTable.Add();
		FillPropertyValues(NewRow, String);
		
	EndDo;
	
	Return ArrayOfTables;
	
EndFunction

&AtServer
Function PlacePurchasesByOrdersOnServer()
	
	Var ErrorList;
	
	// Breakdown of selected documents into groups
	DocumentsByTypesOfInvoices = TablesOfOrdersSeparatedByKeyFieldsForAcquisitions(ListOfOrders_, ErrorList);
	TotalTables = DocumentsByTypesOfInvoices.Count();
	
	If TotalTables > 0 Then
		
		If DocumentsByTypesOfInvoices.Count() > 1 Then
			// Batch
			FormParameters = ArrangeNumberOfAcquisitionsAccordingToTables(DocumentsByTypesOfInvoices, ErrorList);
		ElsIf DocumentsByTypesOfInvoices.Count() = 1 Then
			// Individually
			FormParameters = IssuePurchaseAccordingToTable(DocumentsByTypesOfInvoices, ErrorList);
		EndIf;
	ElsIf ListOfOrders_.Count() > 1 Then
		
		// Errors occurred when processing documents in batch mode
		
		ErrorText = NStr("vi = 'Không có chứng từ nào được chọn có thể được thực thi %1';
						|ru = 'Не выбрано ни одного документа, который можно было бы оформить %1';
						|en = 'No document which could be registered is selected %1'; fa = 'No document which could be registered is selected %1';
						|it = 'Non è stato selezionato alcun documento da formalizzare %1';
						|pl = 'Nie wybrano ani jednego dokumentu, który można byłoby zarejestrować %1';
						|tr = 'Düzenlenmek üzere hiçbir belge seçilmemiştir %1'");
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'theo đơn đặt hàng';
																							|ru = 'по заказам';
																							|en = 'on orders'; fa = 'on orders';
																							|it = 'per ordini';
																							|pl = 'wg zamówień';
																							|tr = 'siparişlere ilişkin'"));
		
		CommonClientServer.AddUserError(ErrorList, "Object.ListReceiptReferences",ErrorText, Undefined);
		
	EndIf;
	
	If Not ValueIsFilled(FormParameters) Then
		FormParameters = New Structure();
	Else 
		UpdateFormTable(Items.ReceiptOrderPage, Items.ListReceiptReferences);
	EndIf;
	
	FormParameters.Insert("ErrorList", ErrorList);
	
	Return FormParameters;
	
EndFunction

&AtServer
Function ArrangeNumberOfAcquisitionsAccordingToTables(DocumentsByTypesOfInvoices, ErrorList)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("FormName", "DataProcessor.LogOfPurchaseDocuments.Form.FormCreatedDocuments");
	
	CreatedDocuments = New ValueList();
	
	For Each Table In DocumentsByTypesOfInvoices Do
		
		FirstRow = Table[0];//ValueTableRow
		
		Orders = Table.UnloadColumn("Ref");
		
		HeaderAttributes = New Structure;
		If Not PurchasesServerCall.GenerateReceiptFillingData(Orders, "VendorInvoice", HeaderAttributes) Then
			Return Undefined;
		EndIf;
		
		FillingData = New Structure;
		FillingData.Insert("HeaderAttributes",               HeaderAttributes);
		If TypeOf(FirstRow.Ref) = Type("CatalogRef.CounterpartyContracts")
			Or TypeOf(FirstRow.Ref) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
			FillingData.Insert("DocumentBasis",            FirstRow.Ref);
		Else
			FillingData.Insert("DocumentBasis",            Orders);
		EndIf;
		FillingData.Insert("WarehouseForReceipt",             FirstRow.Warehouse);
		FillingData.Insert("EconomicOperationOfAcceptance", FirstRow.BusinessOperation);
		FillingData.Insert("FillByWarehouseDocument",            True);
		
		DocumentObject = Documents.VendorInvoice.CreateDocument();
		DocumentObject.Fill(FillingData);
		
		DocumentObject.Date = CurrentSessionDate();
		
		If DocumentObject.CheckFilling() Then
			
			DocumentObject.Write(DocumentWriteMode.Write);
			
			// Add an entry to the user's work history.
			UserWorkHistory.Add(DocumentObject.Ref);
			CreatedDocuments.Add(DocumentObject.Ref);
			
			Try
				DocumentObject.Write(DocumentWriteMode.Posting);
			Except
				ErrorText = NStr("vi = 'Không thể kết chuyển chứng từ';
								|ru = 'Не удалось провести документ';
								|en = 'Cannot post the document'; fa = 'Cannot post the document';
								|it = 'Non è possibile registrare il documento';
								|pl = 'Nie udało się zaksięgować dokument';
								|tr = 'Belge kaydedilemedi'");
				CommonClientServer.AddUserError(ErrorList, "Object.ListReceivingReferences",
					ErrorText + " " + DocumentObject.Ref, Undefined);
			EndTry;
			
		Else
			ErrorText = NStr("vi = 'Không thể tạo chứng từ ""Mua hàng hóa và dịch vụ"" trên cơ sở chứng từ %1';
							|ru = 'Не удалось создать документ ""Приобретение товаров и услуг"" на основании документа %1';
							|en = 'Cannot create the ""Vendor invoice"" document on the basis of document %1'; fa = 'Cannot create the ""Vendor invoice"" document on the basis of document %1';
							|it = 'Impossibile creare il documento ""Acquisto di merci e servizi"" in base al documento %1';
							|pl = 'Nie udało się utworzyć dokumentu ""Nabycie towarów i usług"" na podstawie dokumentu %1';
							|tr = '%1 belgesine dayalı olarak ""Satın alma faturası"" belgesi oluşturulamadı'");
			ErrorText = StrTemplate(ErrorText, Orders[0]);
			CommonClientServer.AddUserError(ErrorList, "Object.ListReceivingReferences",
				ErrorText + " " + DocumentObject.Ref, Undefined);
		EndIf;
		
	EndDo;
	
	SetPrivilegedMode(True);
	Common.WriteDataToSecureStorage(Users.AuthorizedUser(),
														CreatedDocuments.UnloadValues(),
														"FormCreatedPurchaseDocuments");
	SetPrivilegedMode(False);
	
	FormParameters = New Structure("CreatedDocuments", CreatedDocuments);
	
	ParametersStructure.Insert("Parameters", FormParameters);
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Function IssuePurchaseAccordingToTable(DocumentsByTypesOfInvoices, ErrorList)
	
	CreatedDocuments = New ValueList();
	
	DocumentsTable = DocumentsByTypesOfInvoices[0]; // See SplitOrderControlTableTemplate
	SelectedRow = DocumentsTable[0];
	
	Orders = DocumentsTable.UnloadColumn("Ref");
	
	FormSettings = New Structure();
	
	NameOfTheInvoiceForm = "Document.VendorInvoice.Form.DocumentForm";
	FormSettings.Insert("FormName", NameOfTheInvoiceForm);
	
	Cancel = False;
	
	If TypeOf(SelectedRow.Ref) = Type("DocumentRef.VendorInvoice") Then
		
		ParametersWithBase = New Structure("Key, FillByWarehouseDocument", SelectedRow.Ref, True);
		
	ElsIf SelectedRow.ThereAreRegisteredReceipts Then
		
		FormSettings.Insert("FormName", "CommonForm.ReregisterInvoicesByReferences");
		
		HeaderAttributes = New Structure;
		
		If TypeOf(SelectedRow.Ref) = Type("DocumentRef.PurchaseOrder") Then
			Cancel = Not PurchasesServerCall.GenerateReceiptFillingData(Orders, "VendorInvoice", HeaderAttributes);
		ElsIf TypeOf(SelectedRow.Ref) = Type("CatalogRef.CounterpartyContracts") Then
			HeaderAttributes = DetailsOfAgreementHeader(SelectedRow.Ref);
		Else
			HeaderAttributes = PurchasesServerCall.GetPurchaseTermsAndConditions(Orders);
			HeaderAttributes.BusinessOperation = SelectedRow.BusinessOperation;
		EndIf;
		
		ParametersWithBase = New Structure;
		ParametersWithBase.Insert("Orders",         Orders);
		ParametersWithBase.Insert("HeaderAttributes", HeaderAttributes);
		ParametersWithBase.Insert("Warehouse",          SelectedRow.Warehouse);
		ParametersWithBase.Insert("FormSettings", SettingsOfInvoiceReissueForm);
		
	Else
		
		HeaderAttributes = New Structure;
		If Not PurchasesServerCall.GenerateReceiptFillingData(Orders, "VendorInvoice", HeaderAttributes) Then
			Cancel = True;
		EndIf;
		
		FormParameters = New Structure;
		FormParameters.Insert("HeaderAttributes",               HeaderAttributes);
		If TypeOf(SelectedRow.Ref) = Type("CatalogRef.CounterpartyContracts")
			Or TypeOf(SelectedRow.Ref) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
			FormParameters.Insert("DocumentBasis",            SelectedRow.Ref);
		Else
			FormParameters.Insert("DocumentBasis",            Orders);
		EndIf;
		FormParameters.Insert("WarehouseForReceipt",             SelectedRow.Warehouse);
		FormParameters.Insert("EconomicOperationOfAcceptance", SelectedRow.BusinessOperation);
		
		// To display a message about the number of documents created
		CreatedDocuments.Add(PredefinedValue("Document.VendorInvoice.EmptyRef"));
		
		ParametersWithBase = New Structure("Basis, FillByWarehouseDocument", FormParameters, True);
	EndIf;
	
	FormSettings.Insert("Parameters", ParametersWithBase);
	
	If Cancel Then
		Return Undefined;
	Else
		Return FormSettings;
	EndIf;
	
EndFunction

// Parameters:
// 	ListOfOrders_ - FormDataCollection - LongDesc
// 	ErrorList - ValueList - 
// Returns:
// 	Array - An array of See SplitOrderControlTableTemplate
&AtServer
Function TablesOfOrdersSeparatedByKeyFieldsForAcquisitions(ListOfOrders_, ErrorList) 
	KeyFields = "Department,Partner,Counterparty,Contract,Organization,Warehouse,Terms,"
		+"BusinessOperation,ARAPCurrency,VATTaxation,PriceIncludesVAT,"
		+"ARAPObjectSettings,ToReturnReusablePackage,LineOfBusiness,GoodsReceiptOption,TypeOfOrder_";
	
	CurrentKeys = New Structure(KeyFields);
	CurrentKeys.Insert("InvoiceFullName");
	CurrentKeys.Insert("PurchaseState");
	
	SplitTableTemplate = SplitOrderControlTableTemplate();
	
	SplitTable = Undefined;
	ArrayOfTables = New Array();
	
	ListOfOrders_.Sort(KeyFields);
	
	BatchMode = ListOfOrders_.Count() > 1;
	
	ErrorTemplate = NStr("vi = 'Theo lệnh %1 không cần lập chứng từ ""Mua hàng"".';
						|ru = 'По распоряжению %1 оформление документа ""Приобретение товаров"" не требуется.';
						|en = 'The ""Vendor invoice"" document by the %1 reference is not required.'; fa = 'The ""Vendor invoice"" document by the %1 reference is not required.';
						|it = 'Non è necessario emettere il documento ""Acquisto di merci"" per la disposizione %1.';
						|pl = 'Dla zamówienia %1 sporządzenie dokumentu ""Nabycie towarów"" nie jest wymagane.';
						|tr = '""İrsaliye makbuzu"" belgesinin bir sipariş kapsamında%1 düzenlenmesi gerekmemektedir.'");
	
	ThereAreRegisteredReceipts = False;
	
	For Each String In ListOfOrders_ Do
		
		If TypeOf(String.Ref) = Type("CatalogRef.CounterpartyContracts") Then
			String.Contract = String.Ref;
		ElsIf TypeOf(String.Ref) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
			String.Terms = String.Ref;
		EndIf;
		
		AbortStringProcessing = False;
		
		If BatchMode And TypeOf(String.Ref) = Type("DocumentRef.VendorInvoice") Then
			
			ErrorText = NStr("vi = 'Đối với đơn hàng %1, không thể điền lại đơn hàng với các đơn hàng khác. Chọn một đơn đặt hàng riêng.';
							|ru = 'Для распоряжения %1 невозможно перезаполнить приобретение вместе с другими распоряжениями. Выберите распоряжение отдельно.';
							|en = 'Cannot refill purchase with other references for the %1 reference. Select reference separately.'; fa = 'Cannot refill purchase with other references for the %1 reference. Select reference separately.';
							|it = 'Per la disposizione %1 impossibile ricompilare l''acquisto con le altre disposizioni. Selezionare la disposizione separatamente.';
							|pl = 'Dla zamówienia %1 jest niemożliwe ponowne wypełnienie nabycie wraz z innymi zamówieniami. Wybierz zamówienie oddzielnie.';
							|tr = 'Bir sipariş için,%1 satın alma işlemini diğer siparişlerle birlikte yeniden doldurmak mümkün değildir. Siparişi ayrı olarak seçin.'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String.Ref);
			
			AbortStringProcessing = True;
			
		ElsIf String.PurchaseReceiptState = 0
			Or (String.PurchaseReceiptState = 1
				And String.GoodsReceiptState = 1)
			Or (String.GoodsReceiptState = 1
				And String.PurchaseReceiptState = 3) Then
				
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, String.Ref);
			AbortStringProcessing = True;
				
		ElsIf TypeOf(String.Ref) = Type("DocumentRef.PurchaseOrder")
			Or TypeOf(String.Ref) = Type("CatalogRef.CounterpartyContracts")
			Or TypeOf(String.Ref) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
			
			If String.PurchaseReceiptState = 3 Then
				String.ThereAreRegisteredReceipts = DeterminePresenceOfIssuedInvoices(String.Ref,
														String.Warehouse,
														String.BusinessOperation,
														False,
														False,
														True);
														
				If String.ThereAreRegisteredReceipts <> ThereAreRegisteredReceipts
					And ArrayOfTables.Count() > 0 Then
					
					ErrorText = NStr("vi = 'Trong chế độ đóng gói có thể tạo chứng từ mới hoặc điền lại.
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
						| İşlenmeyecek %1 belgeyi ayrı olarak seçin.'");
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String.Ref);
					AbortStringProcessing = True;
				Else
					
					ThereAreRegisteredReceipts = String.ThereAreRegisteredReceipts
				EndIf;
				
			ElsIf Not String.PurchaseReceiptState = 1 Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, String.Ref);
				AbortStringProcessing = True;
				
			EndIf;
			
		ElsIf Not TypeOf(String.Ref) = Type("DocumentRef.VendorInvoice") Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, String.Ref);
			AbortStringProcessing = True;
			
		EndIf;
		
		If AbortStringProcessing Then
			CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",ErrorText, Undefined);
			Continue;
		EndIf;
		
		If SplitTable = Undefined 
			Or Not UseReceiptForMultipleOrders
			Or Not TMCommonUseClientServer.StructuresAreEqual(CurrentKeys,String,KeyFields) Then
			
			SplitTable = SplitTableTemplate.Copy();
			ArrayOfTables.Add(SplitTable);
			
			FillPropertyValues(CurrentKeys, String);
		EndIf;
		
		NewRow = SplitTable.Add();
		FillPropertyValues(NewRow, String);
		
	EndDo;
	
	Return ArrayOfTables;
	
EndFunction

&AtServer
Function IssueWriteOffOfDiscrepanciesOnServer()
	
	Var ErrorList;
	
	// Breakdown of selected documents into groups
	DocumentsByTypesOfInvoices = TablesOfOrdersSeparatedByKeyFieldsForWriteOffDiscrepancies(ListOfOrders_, ErrorList);
	TotalTables = DocumentsByTypesOfInvoices.Count();
	
	If TotalTables > 0 Then
		
		If DocumentsByTypesOfInvoices.Count() > 1 Then
			// Batch
			FormParameters = IssueNumberOfWriteOffDiscrepanciesInTables(DocumentsByTypesOfInvoices, ErrorList);
		ElsIf DocumentsByTypesOfInvoices.Count() = 1 Then
			// Individually
			FormParameters = IssueWriteOffOfDiscrepanciesInTable(DocumentsByTypesOfInvoices, ErrorList);
		EndIf;
	ElsIf ListOfOrders_.Count() > 1 Then
		
		// Errors occurred when processing documents in batch mode
		
		ErrorText = NStr("vi = 'Chưa chọn chứng từ nào mà có thể lập chứng từ %1';
						|ru = 'Не выбрано ни одного документа, который можно было бы оформить %1';
						|en = 'No document which could be registered is selected %1'; fa = 'No document which could be registered is selected %1';
						|it = 'Non è stato selezionato alcun documento da formalizzare %1';
						|pl = 'Nie wybrano ani jednego dokumentu, który można byłoby zarejestrować %1';
						|tr = 'Düzenlenmek üzere hiçbir belge seçilmemiştir %1'");
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NStr("vi = 'theo đơn đặt hàng';
																							|ru = 'по заказам';
																							|en = 'on orders'; fa = 'on orders';
																							|it = 'per ordini';
																							|pl = 'wg zamówień';
																							|tr = 'siparişlere ilişkin'"));
		
		CommonClientServer.AddUserError(ErrorList, "Object.ListReceiptReferences",ErrorText, Undefined);
		
	EndIf;
	
	If Not ValueIsFilled(FormParameters) Then
		FormParameters = New Structure();
	Else 
		UpdateFormTable(Items.ReceiptOrderPage, Items.ListReceiptReferences);
	EndIf;
	
	FormParameters.Insert("ErrorList", ErrorList);
	
	Return FormParameters;

EndFunction

// Parameters:
// 	DocumentsByTypesOfInvoices - Array of See SplitTableTemplateForReceiptRegistration
&AtServer
Function IssueNumberOfWriteOffDiscrepanciesInTables(DocumentsByTypesOfInvoices, ErrorList)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("FormName", "DataProcessor.LogOfPurchaseDocuments.Form.FormCreatedDocuments");
	
	CreatedDocuments = New ValueList();
	
	For Each Table In DocumentsByTypesOfInvoices Do
		
		FirstRow = Table[0];
		
		FillingData = New Structure;
		FillingData.Insert("DocumentBasis",      FirstRow.Ref);
		
		DocumentObject = Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.CreateDocument();
		DocumentObject.Fill(FillingData);
		
		DocumentObject.Date = CurrentSessionDate();
		
		If DocumentObject.CheckFilling() Then
			
			DocumentObject.Write(DocumentWriteMode.Write);
			
			// Add an entry to the user's work history.
			UserWorkHistory.Add(DocumentObject.Ref);
			CreatedDocuments.Add(DocumentObject.Ref);
			
			Try
				DocumentObject.Write(DocumentWriteMode.Posting);
			Except
				ErrorText = NStr("vi = 'Không thể kết chuyển chứng từ';
								|ru = 'Не удалось провести документ';
								|en = 'Cannot post the document'; fa = 'Cannot post the document';
								|it = 'Non è possibile registrare il documento';
								|pl = 'Nie udało się zaksięgować dokument';
								|tr = 'Belge kaydedilemedi'");
				CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",
					ErrorText + " " + DocumentObject.Ref, Undefined);
			EndTry;
			
		Else
			ErrorText = NStr("vi = 'Không thể tạo chứng từ ""Ghi giảm chênh lệch giữa tiếp nhận và mua hàng"" dựa trên chứng từ %1';
							|ru = 'Не удалось создать документ ""Списание расхождений между поступлением и приобретением"" на основании документа %1';
							|en = 'Cannot create the ""Write off discrepancies between receipt and purchase"" document based on the ""%1"" document'; fa = 'Cannot create the ""Write off discrepancies between receipt and purchase"" document based on the ""%1"" document';
							|it = 'Не удалось создать документ ""Списание расхождений между поступлением и приобретением"" на основании документа %1';
							|pl = 'Cannot create the ""Write off discrepancies between receipt and purchase"" document based on the ""%1"" document';
							|tr = '%1 belgesine dayanarak ""Makbuzlarla satın almalar arasındaki tutarsızlıkların gider yazılması"" belgesi oluşturulamadı'");
			ErrorText = StrTemplate(ErrorText, FirstRow.Ref);
			CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",
				ErrorText + " " + DocumentObject.Ref, Undefined);
		EndIf;
			
	EndDo;
	
	SetPrivilegedMode(True);
	Common.WriteDataToSecureStorage(Users.AuthorizedUser(),
														CreatedDocuments.UnloadValues(),
														"FormCreatedPurchaseDocuments");
	SetPrivilegedMode(False);
	
	FormParameters = New Structure("CreatedDocuments", CreatedDocuments);
	
	ParametersStructure.Insert("Parameters", FormParameters);
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Function IssueWriteOffOfDiscrepanciesInTable(DocumentsByTypesOfInvoices, ErrorList)
	
	CreatedDocuments = New ValueList();
	
	DocumentsTable = DocumentsByTypesOfInvoices[0]; // See SplitTableTemplateForReceiptRegistration
	SelectedRow = DocumentsTable[0];
	
	NameOfDocumentForm = "Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Form.DocumentForm";
	
	FormSettings = New Structure();
	FormParameters = New Structure();
	
	FormSettings.Insert("FormName", NameOfDocumentForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("DocumentBasis",            SelectedRow.Ref);
	FormParameters.Insert("Warehouse",						SelectedRow.Warehouse);
	
	// To display a message about the number of documents created
	CreatedDocuments.Add(PredefinedValue("Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.EmptyRef"));
	
	ParametersWithBase = New Structure("Basis", FormParameters);
	
	FormSettings.Insert("Parameters", ParametersWithBase);
	
	Return FormSettings;
	
EndFunction

// Parameters:
// 	ListOfOrders_ - FormDataCollection - LongDesc
// 	ErrorList - ValueList - 
// Returns:
// 	Array - An array of See SplitTableTemplateForReceiptRegistration
&AtServer
Function TablesOfOrdersSeparatedByKeyFieldsForWriteOffDiscrepancies(ListOfOrders_, ErrorList) 
	KeyFields = "Ref";
	
	CurrentKeys = New Structure(KeyFields);
	CurrentKeys.Insert("InvoiceFullName");
	CurrentKeys.Insert("PurchaseState");
	
	SplitTableTemplate = SplitTableTemplateForReceiptRegistration();
	
	SplitTable = Undefined;
	ArrayOfTables = New Array();
	
	ListOfOrders_.Sort(KeyFields);
	
	ErrorTemplate = NStr("vi = 'Theo lệnh %1 không nên tạo chứng từ ""Ghi giảm chênh lệch giữa tiếp nhận và mua hàng"".';
						|ru = 'По распоряжению %1 оформление документа ""Списание расхождений между поступлением и приобретением"" не требуется.';
						|en = 'According to reference %1, you do not need to register the ""Write off discrepancies between receipt and purchase"" document.'; fa = 'According to reference %1, you do not need to register the ""Write off discrepancies between receipt and purchase"" document.';
						|it = 'По распоряжению %1 оформление документа ""Списание расхождений между поступлением и приобретением"" не требуется.';
						|pl = 'According to reference %1, you do not need to register the ""Write off discrepancies between receipt and purchase"" document.';
						|tr = '%1 talimatına göre, ""Giriş ve edinme arasındaki tutarsızlıkların gider yazılması"" belgesinin düzenlenmesi gerekli değildir.'");
	
	For Each String In ListOfOrders_ Do
		
		AbortStringProcessing = False;
		String.FillInUsingInvoice = True;
		
		If String.PurchaseReceiptState = 1
			Or (String.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt")
				Or String.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery")) Then
			
			String.FillInUsingInvoice = False;
			
		ElsIf (Not String.FillInUsingInvoice
				And String.PurchaseReceiptState = 3)
			Or String.PurchaseReceiptState = 0 Then
			
			AbortStringProcessing = True;
			
		EndIf;
		
		If AbortStringProcessing Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, String.Ref);
			CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",ErrorText, Undefined);
			Continue;
		EndIf;
		
		If SplitTable = Undefined 
			Or Not UseReceiptForMultipleOrders
			Or Not TMCommonUseClientServer.StructuresAreEqual(CurrentKeys,String,KeyFields) Then
			
			SplitTable = SplitTableTemplate.Copy();
			ArrayOfTables.Add(SplitTable);
			
			FillPropertyValues(CurrentKeys, String);
		EndIf;
		
		NewRow = SplitTable.Add();
		FillPropertyValues(NewRow, String);
		
	EndDo;
	
	Return ArrayOfTables;
	
EndFunction

// Returns:
// 	ValueTable:
// * Ref - DocumentRef, CatalogRef - 
// * Warehouse - CatalogRef.Warehouses
// * BusinessOperation - EnumRef.BusinessTransactions
// * FillInUsingInvoice - Boolean
&AtServerNoContext
Function SplitTableTemplateForReceiptRegistration()
	
	ListOfTypes= New Array;
	ListOfTypes.Add(Catalogs.AllRefsType());
	ListOfTypes.Add(Documents.AllRefsType());
	
	SplitTableTemplate = New ValueTable();
	SplitTableTemplate.Columns.Add("Ref", New TypeDescription(ListOfTypes));
	SplitTableTemplate.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	SplitTableTemplate.Columns.Add("BusinessOperation", New TypeDescription("EnumRef.BusinessTransactions"));
	SplitTableTemplate.Columns.Add("FillInUsingInvoice", New TypeDescription("Boolean"));

	Return SplitTableTemplate;
	
EndFunction

#EndRegion


#EndRegion

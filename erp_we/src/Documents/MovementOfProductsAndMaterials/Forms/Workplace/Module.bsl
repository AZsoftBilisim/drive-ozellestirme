
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
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
	
	RightToViewTheDocumentExecutionStates = 
		AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus);
	
	RestoreSettings(Parameters);
	SetSelectionByOrganization();
	
	VTBusinessTransactionsAndDocumentTypes = TMCommonUse.AvailableBusinessTransactionsAndDocuments(DescriptionOfOperationsAndDocumentTypes(),
		FilterBusinessTransactions, FilterDocumentTypes, SettingsKey);
	
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	
	ConfigureFormByRightsAndFunctionalOptions();
	
	Title = NStr("vi = 'Chứng từ sản xuất (để lập)';
				|ru = 'Документы производства (к оформлению)';
				|en = 'Transfer of materials from/to production'; fa = 'انتقال مواد از/به تولید';
				|it = 'I documenti della produzione (da formalizzare)';
				|pl = 'Dokumenty proudkucji (do sporządzenia)';
				|tr = 'Üretim belgeleri (düzenlenecek)'");
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
	
	If EventName = "Write_GoodsReceiptNote"
		Or EventName = "Write_OrderOfMaterialsForProduction"
		Or EventName = "Write_MovementOfProductsAndMaterials"
		Or EventName = "Write_ProductionStages"
		Or EventName = "Write_GoodsIssueNote"
		Or EventName = "Accept_FormOfCreatedDocuments" Then
		
		UpdateListOfRequestsForRegistrationOnServer();
		
		If ValueIsFilled(References) And ListReferencesForRegistration.Count() = 0
				And (EventName = "Write_MovementOfProductsAndMaterials"
						Or EventName = "Accept_FormOfCreatedDocuments")
				And Parameter.IdOfOwnerSForm = UUID Then
			Close();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GenerationModeOnChange(Item)
	
	If ModeOfGenerationPriorToChange <> GenerationMode Then
		UpdateListOfRequestsForRegistration();
		SetVisibilityOfStateOfProgressButton(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MovementOfProductsAndMaterials.Form.Workplace.Item.Organization.OnChange");
	
	OrganizationWhenChangedOnServer(GenerationMode);
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	UpdateListOfRequestsForRegistration();
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	UpdateListOfRequestsForRegistration();
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	UpdateListOfRequestsForRegistration();
EndProcedure

&AtClient
Procedure TheConditionOfTheDocumentsWhenYouChange(Item)
	
	RowFilter = New Structure;
	
	If Not IsBlankString(InvoiceStatus) Then
		RowFilter.Insert("InvoiceStatus", Number(InvoiceStatus));
	EndIf;
	If Not IsBlankString(NoteState) Then
		RowFilter.Insert("NoteState", Number(NoteState));
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
		AddressOfAvailableBusinessTransactionsAndDocuments = ValueSelected;
		SelectionOperationTypeSelectionProcessingServer(AddressOfAvailableBusinessTransactionsAndDocuments);
	EndIf;
	
EndProcedure

&AtClient
Procedure HyperlinkProductionDocumentsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
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
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MovementOfProductsAndMaterials.Form.Workplace.Command.RegisterByOrders");
	
	SelectedRows = Items.ListReferencesForRegistration.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(
		SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ListOfProperties = "BusinessOperation,Sender,Recipient";
	ListOfProperties = "BusinessOperation,InternalSubcontracting,MaterialProviderCompany,Sender,Recipient";
	GroupingOrders =
		InvoicesClient.DataForPlacingOrders(
			ListReferencesForRegistration,
			SelectedRows,
			ListOfProperties,
			ErrorList,
			"Object.ListReferencesForRegistration",
			BusinessTransactionsAndDocuments, GenerationMode = 1);
	
	If ValueIsFilled(GroupingOrders) Then
		
		ParametersOfCreatedDocuments = InvoicesServerCall.IssueInvoicesForOrders(GroupingOrders,
			FormParametersForCreatedDocuments(), ErrorList,"Object.ListReferencesForRegistration");
		InvoicesClient.OpenFormForCreatedDocuments(ParametersOfCreatedDocuments, ThisForm);
		
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(ErrorList);
	
EndProcedure

&AtClient
Procedure IssueOnShipmentAcceptance(Command)
	
	Var ErrorList;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MovementOfProductsAndMaterials.Form.Workplace.Command.IssueOnShipmentAcceptance");
	
	SelectedRows = Items.ListReferencesForRegistration.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(
		SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	GroupingOrders = InvoicesClient.DataForProcessingOrders(ListReferencesForRegistration,
		SelectedRows, "BusinessOperation,Sender,Recipient",
		ErrorList, "Object.ListReferencesForRegistration", 
		BusinessTransactionsAndDocuments, GenerationMode = 1);
	
	If ValueIsFilled(GroupingOrders) Then
		
		ParametersOfCreatedDocuments =
			InvoicesServerCall.IssueInvoicesForOrders_(
				GroupingOrders,
				FormParametersForCreatedDocuments(),
				ErrorList,
				"Object.ListReferencesForRegistration");
		
		InvoicesClient.OpenFormForCreatedDocuments(ParametersOfCreatedDocuments, ThisForm);
		
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(ErrorList);
	
EndProcedure

&AtClient
Procedure ExecutionState(Command)
	
	If Items.ListReferencesForRegistration.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Không một dòng nào được chọn. Thực thi lệnh là không thể.';
								|ru = 'Не выделено ни одной строки. Выполнение команды невозможно.';
								|en = 'No lines are selected. Cannot execute the command.'; fa = 'No lines are selected. Cannot execute the command.';
								|it = 'Nessuna riga selezionata. Il comando non può essere eseguito.';
								|pl = 'Nie wybrano ani jednego wierszu. Wykonanie polecenia jest niemożliwe.';
								|tr = 'Herhangi bir satır belirtilmedi. Komutun gerçekleştirilmesi mümkün değildir.'"));
	Else
		DocumentsList = New ValueList;
		For Each Id In Items.ListReferencesForRegistration.SelectedRows Do
			TableRow = ListReferencesForRegistration.FindByID(Id);
			If TypeOf(TableRow.Ref) = Type("DocumentRef.OrderOfMaterialsForProduction") Then
				DocumentsList.Add(TableRow.Ref);
			EndIf;
		EndDo;
		
		If DocumentsList.Count() = 0 Then
			ShowMessageBox(, NStr("vi = 'Việc thực hiện của nhóm chỉ có thể đối với các đơn đặt hàng vật liệu trong sản xuất.';
									|ru = 'Выполнение команды возможно только для заказов материалов в производство.';
									|en = 'Command can be performed only for material orders for shop floor stockroom.'; fa = 'Command can be performed only for material orders for shop floor stockroom.';
									|it = 'Il comando può essere eseguito solo per gli ordini dei materiali per la produzione.';
									|pl = 'Wykonanie polecenia jest możliwe tylko dla zamówień materiałów do produkcji.';
									|tr = 'Komutların gerçekleştirilmesi sadece üretime malzeme siparişleri için mümkündür.'"));
			Return;
		EndIf;
		
		OpenForm("Report.DocumentFulfillmentStatus.Form.ReportForm",
			New Structure("IncomingDocuments", DocumentsList));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.MovementOfProductsAndMaterials.Form.Workplace.Command.Refresh");
	
	UpdateListOfRequestsForRegistrationOnServer();
	
EndProcedure

#EndRegion

#Region Private

#Region FormSettingsItem

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListReferencesForRegistration.Date", "ListReferencesForRegistrationDate");
	
EndProcedure

&AtServer
Procedure ConfigureFormByRightsAndFunctionalOptions()
	
	SetVisibilityOfStateOfProgressButton(ThisForm);
	
	If (Not GetFunctionalOption("UseWarehouseManagemantSystemForGoodsIssue")
			Or Not AccessRight("Read", Metadata.AccumulationRegisters.GoodsForIssue))
		And (Not GetFunctionalOption("UseWarehouseManagemantSystemForGoodsReceipt")
			Or Not AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive)) Then
		Items.NoteState.Visible = False;
		Items.ListReferencesForRegistrationNoteState.Visible = False;
		
		Items.ListReferencesForRegistrationRegisterByOrders.Title = NStr("vi = 'Tạo';
																		|ru = 'Оформить';
																		|en = 'Register'; fa = 'ثبات';
																		|it = 'Preparare';
																		|pl = 'Register';
																		|tr = 'Düzenle'");
		Items.Move(Items.DocumentTeamGroup, Items.AGroupOfStateDocuments);
		
		InvoicesServer.FillInInvoiceStates(Items.InvoiceStatus.ChoiceList, True);
	Else
		InvoicesServer.FillInInvoiceStates(Items.InvoiceStatus.ChoiceList);
		InvoicesServer.FillOrderStates(Items.NoteState.ChoiceList);
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
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityOfStateOfProgressButton(Form)
	
	Form.Items.ListReferencesForRegistrationExecutionState.Visible = 
		Form.RightToViewTheDocumentExecutionStates And Form.GenerationMode = 0;
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Return BarcodingOfPrintFormsServerCall.LinkToListItemByBarcode(
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
Function DescriptionOfOperationsAndDocumentTypes()
	
	VTBusinessTransactionsAndDocumentTypes = BusinessTransactionsAndDocuments.Unload(New Array);
	
	AvailableDocumentOperations = Documents.MovementOfProductsAndMaterials.TransactionList();
	
	DefaultProperties = New Structure(
		"PurposeUseKey,WorkplaceTitle,DocumentType,FullDocumentName,StatusesAreUsed,
		|AddButtonCreate,KeyHeaderFields, TitleOfTheReissueForm");
	
	DefaultProperties.PurposeUseKey  = "";
	DefaultProperties.WorkplaceTitle       = NStr("vi = 'Chứng từ nội bộ (chuyển động của Hàng hóa và nguyên vật liệu)';
													|ru = 'Внутренние документы (движения продукции и материалов)';
													|en = 'Internal documents (transfer of products and materials)'; fa = 'Internal documents (transfer of products and materials)';
													|it = 'Documenti interni (movimentazioni dei prodotti e materiali)';
													|pl = 'Dokumenty wewnętrzne (przepływy produkcji i materiałów)';
													|tr = 'Dahili belgeler (imal edilen ürün ve malzeme hareketleri)'");
	DefaultProperties.DocumentType                 = Type("DocumentRef.MovementOfProductsAndMaterials");
	DefaultProperties.FullDocumentName           = Metadata.Documents.MovementOfProductsAndMaterials.FullName();
	DefaultProperties.StatusesAreUsed          = GetFunctionalOption("UseStatusesOfProductsAndMaterialsMovements");
	DefaultProperties.AddButtonCreate        = True;
	DefaultProperties.KeyHeaderFields            = Documents.MovementOfProductsAndMaterials.KeyFieldsOfHeader();
	DefaultProperties.TitleOfTheReissueForm = "";
	
	CurrentOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation = CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		String.TitleOfTheReissueForm = "";
		
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation = CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		String.TitleOfTheReissueForm = "";
		
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation = CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		String.TitleOfTheReissueForm = NStr("vi = 'Gia hạn chuyển đến kho tại xưởng theo lệnh đã chọn';
											|ru = 'Переоформление передачи в кладовую по выбранным распоряжениям';
											|en = 'Reregister transfer to storeroom for the selected references'; fa = 'Reregister transfer to storeroom for the selected references';
											|it = 'La formalizzazione sostitutiva di consegna al deposito per disposizioni selezionate';
											|pl = 'Ponowne sporządzenie przekazania do komórki według wybranych zamówień';
											|tr = 'Seçilen talimatlara göre ambara transferin yeniden düzenlenmesi'");
		
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.MaterialTransferToProduction;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation = CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		String.TitleOfTheReissueForm = NStr("vi = 'Gia hạn chuyển giao cho sản xuất theo lệnh đã chọn';
											|ru = 'Переоформление передачи в производство по выбранным распоряжениям';
											|en = 'Reregister transfer to production for the selected references'; fa = 'Reregister transfer to production for the selected references';
											|it = 'La formalizzazione sostitutiva di consegna in produzione per disposizioni selezionate';
											|pl = 'Ponowne sporządzenie przekazania do produkcji według wybranych zamówień';
											|tr = 'Seçilen talimatlara göre üretime transferin yeniden düzenlenmesi'");
		String.KeyHeaderFields = Documents.MovementOfProductsAndMaterials.KeyFieldsOfStageOrderHeader();
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation = CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		String.TitleOfTheReissueForm = NStr("vi = 'Gia hạn hoàn trả từ sản xuất theo lệnh đã chọn';
											|ru = 'Переоформление возврата из производства по выбранным распоряжениям';
											|en = 'Reregister return from production by selected references'; fa = 'Reregister return from production by selected references';
											|it = 'La formalizzazione sostitutiva del reso dalla produzione per disposizioni selezionate';
											|pl = 'Ponowne sporządzenie zwrotu z produkcji według wybranych zamówień';
											|tr = 'Seçilen talimatlara göre üretimden iadenin yeniden düzenlenmesi'");
		String.KeyHeaderFields = Documents.MovementOfProductsAndMaterials.KeyFieldsOfStageOrderHeader();
	EndIf;
	
	CurrentOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction;
	If AvailableDocumentOperations.FindByValue(CurrentOperation) <> Undefined Then
		
		String = VTBusinessTransactionsAndDocumentTypes.Add();
		String.BusinessOperation = CurrentOperation;
		FillPropertyValues(String, DefaultProperties);
		String.TitleOfTheReissueForm = NStr("vi = 'Gia hạn chuyển từ sản xuất theo lệnh đã chọn';
											|ru = 'Переоформление передачи из производства по выбранным распоряжениям';
											|en = 'Reregister transfer from production for the selected references'; fa = 'Reregister transfer from production for the selected references';
											|it = 'La formalizzazione sostitutiva di consegna dalla produzione per disposizioni selezionate';
											|pl = 'Ponowne sporządzenie przekazania z produkcji według wybranych zamówień';
											|tr = 'Seçilen talimatlara göre üretimden transferin yeniden düzenlenmesi'");
		String.KeyHeaderFields = Documents.MovementOfProductsAndMaterials.KeyFieldsOfStageOrderHeader();
	EndIf;
	
	Return VTBusinessTransactionsAndDocumentTypes;
	
EndFunction

&AtServer
Procedure SelectionOperationTypeSelectionProcessingServer(AddressOfBusinessTransactionsAndDocuments)
	
	VTBusinessTransactionsAndDocumentTypes = GetFromTempStorage(AddressOfBusinessTransactionsAndDocuments);
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	TMCommonUse.FillInSelectionsAccordingToTableOfBusinessTransactionsAndDocumentTypes(VTBusinessTransactionsAndDocumentTypes, FilterBusinessTransactions, FilterDocumentTypes);
	
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes);
	
EndProcedure

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "ProductionDocumentsAll";
	
EndFunction

&AtServer
Function PlaceBusinessTransactionsAndDocumentsInTemporaryStorage()
	Return PutToTempStorage(BusinessTransactionsAndDocuments.Unload(), UUID);
EndFunction

&AtClient
Function LogParameters()
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",		Organization);
	QuickFilterStructure.Insert("Department",	Department);
	QuickFilterStructure.Insert("Manager",		Manager);
	QuickFilterStructure.Insert("FilterDocumentTypes",			FilterDocumentTypes);
	QuickFilterStructure.Insert("FilterBusinessTransactions",	FilterBusinessTransactions);
	
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure",	QuickFilterStructure);
	LogParameters.Insert("WorkplaceName",			"LogOfProductionDocuments");
	LogParameters.Insert("FormAssignmentKey",		PurposeUseKey);
	LogParameters.Insert("JournalSynonym",				NStr("vi = 'Chứng từ sản xuất';
																|ru = 'Документы производства';
																|en = 'Production documents'; fa = 'اسناد تولید';
																|it = 'Documenti di produzione';
																|pl = 'Dokumenty produkcji';
																|tr = 'Üretim belgeleri'"));
	
	Return LogParameters;
	
EndFunction

&AtServer
Procedure ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes)

	UpdateListOfRequestsForRegistration();
	
	SetVisibilityAvailability();
	
	TMCommonUse.FormInscriptionSelection(Items.HelpTextFilter.Title,
		BusinessTransactionsAndDocuments, FilterDocumentTypes, FilterBusinessTransactions);
	
EndProcedure

#Region SavedFormSettings

&AtServer
Procedure RestoreSettings(Var_Parameters)
	
	QuickFilterStructure = Undefined;
	Var_Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	If QuickFilterStructure <> Undefined Then
		FillPropertyValues(ThisForm, FormSettings(QuickFilterStructure));
	EndIf;

	SettingsFromStorage = Common.CommonSettingsStorageLoad(
		"Document.MovementOfProductsAndMaterials.Form.Workplace", PurposeUseKey);
	
	If TypeOf(SettingsFromStorage) = Type("Structure") Then
		
		FillPropertyValues(
			ThisForm, 
			FormSettings(SettingsFromStorage), 
			?(QuickFilterStructure = Undefined, Undefined, "GenerationMode"));
				
	EndIf;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	Common.CommonSettingsStorageSave("Document.MovementOfProductsAndMaterials.Form.Workplace",
		PurposeUseKey, FormSettings(ThisForm));
	
EndProcedure

&AtServer
Function FormSettings(SettingsSource)
	
	AttributesToSaveNames =
		"GenerationMode,
		|Organization,
		|Department,
		|Warehouse,
		|Manager,
		|InvoiceStatus,
		|NoteState,
		|FilterBusinessTransactions,
		|FilterDocumentTypes";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, SettingsSource);
	
	Return Settings;
	
EndFunction

#EndRegion

&AtServer
Procedure UpdateListOfRequestsForRegistration()
	
	If ModeOfGenerationPriorToChange <> GenerationMode Then
		ModeOfGenerationPriorToChange = GenerationMode;
		Items.GroupProductCharacteristic.Visible = GenerationMode = 1;
		Items.ListReferencesForRegistrationToRegister.Visible = GenerationMode = 1;
	EndIf;
	
	GenerateQueryTexts();
	UpdateListOfRequestsForRegistrationOnServer();
	
EndProcedure	

&AtServer
Procedure UpdateListOfRequestsForRegistrationOnServer()
	
	If Items.ListReferencesForRegistration.CurrentRow <> Undefined Then
		CurrentDocument = ListReferencesForRegistration.FindByID(Items.ListReferencesForRegistration.CurrentRow).Ref;
	Else
		CurrentDocument = Undefined;
	EndIf;
	
	Query = New Query(StatusCalculationQueryText);
	FilterParameters = InvoicesServer.OrderSelectionParameters(Organization,,, FilterBusinessTransactions, Manager);
	InvoicesServer.AddSelectionParametersForDocumentRegistry(Query, FilterParameters);
	Query.TempTablesManager = New TempTablesManager;
	
	OrderTypes = New Array;
	OrderTypes.Add(Type("DocumentRef.OrderOfMaterialsForProduction"));
	OrderTypes.Add(Type("DocumentRef.ProductionStage2_2"));
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("Organization",       CompaniesList.UnloadValues());
	Query.SetParameter("Department",     Department);
	Query.SetParameter("Warehouse",             Warehouse);
	Query.SetParameter("Manager",          Manager);
	Query.SetParameter("BusinessTransaction",       FilterBusinessTransactions.UnloadValues());
	Query.SetParameter("OrderTypes",       OrderTypes);
	Query.SetParameter("References",      References.UnloadValues());
	
	Query.Execute();
	
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
Procedure OrganizationWhenChangedOnServer(DataGenerationMode)
	
	SetSelectionByOrganization();
	
	UpdateListOfRequestsForRegistration();
	
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
Procedure GenerateQueryTexts()
	
	FilterParameters = InvoicesServer.OrderSelectionParameters(Organization, Department, Warehouse, FilterBusinessTransactions, Manager);
	
	// States are always obtained in the context of the nomenclature.
	ReplacementParameters = New Structure("ProductsField");
	
	// The totals are collapsed depending on the display mode.
	DataReplacementOptions = ?(GenerationMode > 0, ReplacementParameters, Undefined);
	
	Package = New Array;
	Selection = New Array;
	States1 = InvoicesServer.StatesByBusinessTransactions(FilterBusinessTransactions.UnloadValues());
	ThereAreStatesOfTransfersFromProduction = States1.Property("StatesOfTransfersFromProduction");
	For Each KZ In States1 Do
		Package.Add(InvoicesServer.StateRequestText(KZ.Key, FilterParameters, KZ.Value,, ReplacementParameters));
		
		If KZ.Key = "StatesOfSpendingOrders" Then
			
			QueryText =
			"SELECT
			|	StatesOfSpendingOrders.ReferenceOrder AS ReferenceOrder,
			|	&Fields AS Fields,
			|	StatesOfSpendingOrders.Warehouse AS Sender,
			|	StatesOfSpendingOrders.Recipient AS Recipient,
			|	CASE
			|		WHEN VALUETYPE(StatesOfSpendingOrders.ReferenceOrder) = TYPE(Document.ProductionStage2_2)
			|			THEN VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
			|		WHEN TRUE
			|			THEN NULL
			|	END AS BusinessTransaction,
			|	CASE
			|		WHEN VALUETYPE(StatesOfSpendingOrders.ReferenceOrder) IN (&OrderTypes)
			|			THEN 0
			|		ELSE 4
			|	END AS InvoiceStatus,
			|	StatesOfSpendingOrders.State AS StateOfSpendingOrder,
			|	4 AS StatusOfTheReceiptOrder,
			|	TRUE AS ShippingSlip,
			|	FALSE AS ReceivingDocument,
			|	0 AS ToRegister
			|FROM
			|	TTStateOfSpendingOrders AS StatesOfSpendingOrders
			|		LEFT JOIN Catalog.Warehouses AS CatWarehousesRecipient
			|		ON (CatWarehousesRecipient.Ref = StatesOfSpendingOrders.Recipient)
			|			AND (CatWarehousesRecipient.UseWarehouseManagemantSystemForGoodsReceipt)
			|			AND (CatWarehousesRecipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDayStart)";
			
			InvoicesServer.ConfigureProductsField(
				QueryText, DataReplacementOptions, "&Fields AS Fields,", "StatesOfSpendingOrders");
			
			Selection.Add(QueryText);
			
		ElsIf KZ.Key = "StatesOfIncomingOrders" Then
			
			QueryText =
			"SELECT
			|	StatesOfIncomingOrders.ReferenceOrder AS ReferenceOrder,
			|	&Fields AS Fields,
			|	StatesOfIncomingOrders.Sender AS Sender,
			|	StatesOfIncomingOrders.Warehouse AS Recipient,
			|	StatesOfIncomingOrders.BusinessTransaction AS BusinessTransaction,
			|	CASE
			|		WHEN VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) IN (&OrderTypes)
			|			THEN 0
			|		ELSE 4
			|	END AS InvoiceStatus,
			|	4 AS StateOfSpendingOrder,
			|	StatesOfIncomingOrders.State AS StatusOfTheReceiptOrder,
			|	FALSE AS ShippingSlip,
			|	TRUE AS ReceivingDocument,
			|	0 AS ToRegister
			|FROM
			|	TTStateOfIncomingOrders AS StatesOfIncomingOrders
			|	
			|	LEFT JOIN Catalog.Warehouses AS CatWarehousesSender
			|	ON CatWarehousesSender.Ref = StatesOfIncomingOrders.Sender
			|	AND CatWarehousesSender.UseWarehouseManagemantSystemForGoodsIssue
			|	AND CatWarehousesSender.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDayStart
			|";
			
			InvoicesServer.ConfigureProductsField(
				QueryText, DataReplacementOptions, "&Fields AS Fields,", "StatesOfIncomingOrders");
			If ThereAreStatesOfTransfersFromProduction Then
				
				TableDetails = 
					RequestSchemes.TableDetails(
						Type("QuerySchemaTempTableDescription"),
						"TTTransfersStateOfTransferFromProduction",
						"StatesOfTransfersFromProduction",
						"ReferenceOrder, Products, Characteristic, Warehouse, Sender, BusinessTransaction");
				
				IConnectionShort =
					RequestSchemes.IConnectionShort(
						TableDetails,
						"&ConnectionConditionText",
						QuerySchemaJoinType.Inner);
				
				QueryText =
					RequestSchemes.AddConnectionToRequest(
						QueryText,
						"StatesOfIncomingOrders",
						IConnectionShort);
				
				QueryText =
					StrReplace(
						QueryText,
						"&ConnectionConditionText",
						"StatesOfTransfersFromProduction.ReferenceOrder = StatesOfIncomingOrders.ReferenceOrder
						// The connection according to the nomenclature is always performed to minimize duplication of lines for the transfer
						// of products from production and the return of materials from production. Duplication may occur
						// due to different households. operations in warehouse and production records.
						|	AND StatesOfTransfersFromProduction.Products   = StatesOfIncomingOrders.Products
						|	AND StatesOfTransfersFromProduction.Characteristic = StatesOfIncomingOrders.Characteristic
						|	AND StatesOfTransfersFromProduction.Warehouse = StatesOfIncomingOrders.Warehouse
						|	AND StatesOfTransfersFromProduction.Sender = StatesOfIncomingOrders.Sender
						|	AND StatesOfTransfersFromProduction.BusinessTransaction = StatesOfIncomingOrders.BusinessTransaction");
				
			EndIf;
			Selection.Add(QueryText);
			If ThereAreStatesOfTransfersFromProduction Then
				// We will get the status of registration of receipt orders for the return of materials from production
				QueryText =
				"SELECT
				|	StatesOfIncomingOrders.ReferenceOrder AS ReferenceOrder,
				|	&Fields AS Fields,
				|	StatesOfIncomingOrders.Sender AS Sender,
				|	StatesOfIncomingOrders.Warehouse AS Recipient,
				|	VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction) AS BusinessTransaction,
				|	CASE
				|		WHEN VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) IN (&OrderTypes)
				|			THEN 0
				|		ELSE 4
				|	END AS InvoiceStatus,
				|	4 AS StateOfSpendingOrder,
				|	StatesOfIncomingOrders.State AS StatusOfTheReceiptOrder,
				|	FALSE AS ShippingSlip,
				|	TRUE AS ReceivingDocument,
				|	0 AS ToRegister
				|FROM
				|	TTStateOfIncomingOrders AS StatesOfIncomingOrders
				|	
				|	INNER JOIN TTTransfersStateOfTransferFromProduction AS StatesOfTransfersFromProduction
				|	ON StatesOfTransfersFromProduction.ReferenceOrder = StatesOfIncomingOrders.ReferenceOrder
				// The connection according to the nomenclature is always performed to minimize duplication of lines for the transfer
				// of products from production and the return of materials from production. Duplication may occur
				// due to different households. operations in warehouse and production records.
				|	AND StatesOfTransfersFromProduction.Products   = StatesOfIncomingOrders.Products
				|	AND StatesOfTransfersFromProduction.Characteristic = StatesOfIncomingOrders.Characteristic
				|	AND StatesOfTransfersFromProduction.Warehouse = StatesOfIncomingOrders.Warehouse
				|	AND StatesOfTransfersFromProduction.Sender = StatesOfIncomingOrders.Sender
				|	AND StatesOfTransfersFromProduction.BusinessTransaction = VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction)
				|	
				|	LEFT JOIN Catalog.Warehouses AS CatWarehousesSender
				|	ON CatWarehousesSender.Ref = StatesOfIncomingOrders.Sender
				|	AND CatWarehousesSender.UseWarehouseManagemantSystemForGoodsIssue
				|	AND CatWarehousesSender.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDayStart
				|";
				
				InvoicesServer.ConfigureProductsField(
					QueryText, DataReplacementOptions, "&Fields AS Fields,", "StatesOfIncomingOrders");
				
				Selection.Add(QueryText);
				
				// We will get the status of registration of incoming orders, according to which all invoices are issued
				QueryText =
				"SELECT
				|	StatesOfIncomingOrders.ReferenceOrder AS ReferenceOrder,
				|	&Fields AS Fields,
				|	StatesOfIncomingOrders.Sender AS Sender,
				|	StatesOfIncomingOrders.Warehouse AS Recipient,
				|	StatesOfIncomingOrders.BusinessTransaction AS BusinessTransaction,
				|	CASE
				|		WHEN VALUETYPE(StatesOfIncomingOrders.ReferenceOrder) IN (&OrderTypes)
				|			THEN 0
				|		ELSE 4
				|	END AS InvoiceStatus,
				|	4 AS StateOfSpendingOrder,
				|	StatesOfIncomingOrders.State AS StatusOfTheReceiptOrder,
				|	FALSE AS ShippingSlip,
				|	TRUE AS ReceivingDocument,
				|	0 AS ToRegister
				|FROM
				|	TTStateOfIncomingOrders AS StatesOfIncomingOrders
				|	
				|	LEFT JOIN TTTransfersStateOfTransferFromProduction AS StatesOfTransfersFromProduction
				|	ON StatesOfTransfersFromProduction.ReferenceOrder = StatesOfIncomingOrders.ReferenceOrder
				// The connection according to the nomenclature is always performed to minimize duplication of lines for the transfer
				// of products from production and the return of materials from production. Duplication may occur
				// due to different households. operations in warehouse and production records.
				|	AND StatesOfTransfersFromProduction.Products   = StatesOfIncomingOrders.Products
				|	AND StatesOfTransfersFromProduction.Characteristic = StatesOfIncomingOrders.Characteristic
				|	AND StatesOfTransfersFromProduction.Warehouse = StatesOfIncomingOrders.Warehouse
				|	AND StatesOfTransfersFromProduction.Sender = StatesOfIncomingOrders.Sender
				|	AND StatesOfTransfersFromProduction.BusinessTransaction = StatesOfIncomingOrders.BusinessTransaction
				|	
				|	LEFT JOIN Catalog.Warehouses AS CatWarehousesSender
				|	ON CatWarehousesSender.Ref = StatesOfIncomingOrders.Sender
				|	AND CatWarehousesSender.UseWarehouseManagemantSystemForGoodsIssue
				|	AND CatWarehousesSender.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDayStart
				|
				|WHERE
				|	StatesOfTransfersFromProduction.ReferenceOrder IS NULL
				|";
				
				InvoicesServer.ConfigureProductsField(
					QueryText, DataReplacementOptions, "&Fields AS Fields,", "StatesOfIncomingOrders");
				
				Selection.Add(QueryText);
				
			EndIf;
		ElsIf KZ.Key = "StatesOfTransfersToProduction" Then
			
			QueryText =
			"SELECT
			|	StatesOfTransfersToProduction.ReferenceOrder AS ReferenceOrder,
			|	&Fields AS Fields,
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
			|	FALSE AS ReceivingDocument,
			|	StatesOfTransfersToProduction.ToRegister AS ToRegister
			|FROM
			|	TTStatesOfTransfersToProduction AS StatesOfTransfersToProduction
			|		LEFT JOIN Catalog.Warehouses AS CatWarehousesSender
			|		ON (CatWarehousesSender.Ref = StatesOfTransfersToProduction.Warehouse)
			|			AND (CatWarehousesSender.UseWarehouseManagemantSystemForGoodsIssue)
			|			AND (CatWarehousesSender.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDayStart)";
			
			InvoicesServer.ConfigureProductsField(
				QueryText, DataReplacementOptions, "&Fields AS Fields,", "StatesOfTransfersToProduction");
			
			Selection.Add(QueryText);
		ElsIf KZ.Key = "StatesOfTransfersFromProduction" Then
			
			QueryText =
			"SELECT
			|	StatesOfTransfersFromProduction.ReferenceOrder AS ReferenceOrder,
			|	&Fields AS Fields,
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
			|	TRUE AS ReceivingDocument,
			|	StatesOfTransfersFromProduction.ToRegister AS ToRegister
			|FROM
			|	TTTransfersStateOfTransferFromProduction AS StatesOfTransfersFromProduction
			|		LEFT JOIN Document.ProductionStage2_2 AS DocProductionStage
			|		ON StatesOfTransfersFromProduction.ReferenceOrder = DocProductionStage.Ref
			|		LEFT JOIN Catalog.Warehouses AS CatWarehousesRecipient
			|		ON (CatWarehousesRecipient.Ref = StatesOfTransfersFromProduction.Warehouse)
			|			AND (CatWarehousesRecipient.UseWarehouseManagemantSystemForGoodsReceipt)
			|			AND (CatWarehousesRecipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDayStart)";
			
			InvoicesServer.ConfigureProductsField(
				QueryText, DataReplacementOptions, "&Fields AS Fields,", "StatesOfTransfersFromProduction");
			
			Selection.Add(QueryText);
		EndIf;
		
	EndDo;
	
	StatusCalculationQueryText = StrConcat(Package, Common.QueryBatchSeparator());
	
	TextOfDirectiveListRequest =
		"SELECT
		|	NestedQuery.ReferenceOrder                        AS Ref,
		|	&Fields AS Fields,
		|	NestedQuery.Sender                         AS Sender,
		|	NestedQuery.Recipient                          AS Recipient,
		|	NestedQuery.BusinessTransaction                         AS BusinessTransaction,
		|	MAX(NestedQuery.InvoiceStatus)        AS InvoiceStatus,
		|	MAX(NestedQuery.StateOfSpendingOrder) AS GoodsIssueNoteState,
		|	MAX(NestedQuery.StatusOfTheReceiptOrder) AS GoodsReceiptNoteState,
		|	MAX(NestedQuery.ShippingSlip)       AS ShippingSlip,
		|	MAX(NestedQuery.ReceivingDocument)        AS ReceivingDocument,
		|	SUM(NestedQuery.ToRegister)                  AS ToRegister
		|INTO TTRemainsOfState
		|FROM
		|	QueryTextNested AS NestedQuery
		|WHERE
		|	&ContextOfOrders
		|
		|GROUP BY
		|	NestedQuery.ReferenceOrder,
		|	&Fields,
		|	NestedQuery.Sender,
		|	NestedQuery.Recipient,
		|	NestedQuery.BusinessTransaction
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentsRegistry.IBDocumentNumber                                              AS Number,
		|	ISNULL(DocumentsRegistry.IBDocumentDate, DATETIME(1,1,1))                   AS Date,
		|	VALUETYPE(DocumentsRegistry.Ref)                                           AS TypeOfOrder_,
		|	RemnantsOfState.InvoiceStatus                                            AS InvoiceStatus,
		|	CASE
		|		WHEN RemnantsOfState.GoodsIssueNoteState < RemnantsOfState.GoodsReceiptNoteState
		|			THEN RemnantsOfState.GoodsIssueNoteState
		|		ELSE RemnantsOfState.GoodsReceiptNoteState
		|	END                                                                          AS NoteState,
		|	RemnantsOfState.GoodsIssueNoteState                                     AS GoodsIssueNoteState,
		|	RemnantsOfState.GoodsReceiptNoteState                                      AS GoodsReceiptNoteState,
		|	RemnantsOfState.ShippingSlip                                           AS ShippingSlip,
		|	RemnantsOfState.ReceivingDocument                                            AS ReceivingDocument,
		|	RemnantsOfState.ToRegister                                                   AS ToRegister,
		|	DocumentsRegistry.Organization                                                   AS Organization,
		|	DocumentsRegistry.Department                                                 AS Department,
		|	RemnantsOfState.Sender                                                   AS Sender,
		|	RemnantsOfState.Recipient                                                    AS Recipient,
		|	DocumentsRegistry.EmployeeResponsible                                                 AS Manager,
		|	DocumentsRegistry.Author                                                         AS Author,
		|	ISNULL(RemnantsOfState.BusinessTransaction, DocumentsRegistry.BusinessOperation) AS BusinessOperation,
		|	&RemnantsOfFieldState AS RemnantsOfFieldState,
		|	DocProductionStage.InternalSubcontracting                                      AS InternalSubcontracting,
		|	DocProductionStage.MaterialProviderCompany                                         AS MaterialProviderCompany,
		|	RemnantsOfState.Ref                                                        AS Ref
		|FROM
		|	TTRemainsOfState AS RemnantsOfState
		|
		|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|	ON RemnantsOfState.Ref = DocumentsRegistry.Ref
		|	AND NOT DocumentsRegistry.AdditionalRecord
		|	
		|	LEFT JOIN Document.ProductionStage2_2 AS DocProductionStage
		|	ON DocProductionStage.Ref = RemnantsOfState.Ref
		|
		|ORDER BY
		|	Date,
		|	Ref
		|";
	
	InvoicesServer.ConfigureProductsField(
		TextOfDirectiveListRequest, DataReplacementOptions, "&Fields AS Fields,", "NestedQuery",,, "&Fields,");
	
	InvoicesServer.ConfigureProductsField(
		TextOfDirectiveListRequest,
		DataReplacementOptions,
		"&RemnantsOfFieldState AS RemnantsOfFieldState,",
		"RemnantsOfState");
	
	TextOfDirectiveListRequest =
		StrReplace(
			TextOfDirectiveListRequest,
			"QueryTextNested",
			"(" + StrConcat(Selection, TMCommonUse.QuerySeparatorInJoin()) + ")");
	
	TextOfDirectiveListRequest =
		StrReplace(
			TextOfDirectiveListRequest,
			"&ContextOfOrders",
			?(ValueIsFilled(References),
				"NestedQuery.ReferenceOrder IN (&References)",
				"TRUE"));
	
EndProcedure

&AtClient
Function FormParametersForCreatedDocuments()
	
	FormParameters = New Structure("DataKey, VisibleColumns, UpdateEvents",
		PurposeUseKey, New Array, New Array);
	
	FormParameters.VisibleColumns.Add("Number");
	FormParameters.VisibleColumns.Add("Date");
	FormParameters.VisibleColumns.Add("ValueType");
	FormParameters.VisibleColumns.Add("BusinessOperation");
	FormParameters.VisibleColumns.Add("Organization");
	FormParameters.VisibleColumns.Add("Department");
	FormParameters.VisibleColumns.Add("LineOfBusiness");
	If BusinessTransactionsAndDocuments.FindRows(New Structure("Filter, StatusesAreUsed", True, True)).Count() <> 0 Then
		FormParameters.VisibleColumns.Add("Status");
	EndIf;
	FormParameters.VisibleColumns.Add("More");
	
	FormParameters.UpdateEvents.Add("Write_MovementOfProductsAndMaterials");
	
	Return FormParameters;
	
EndFunction

#EndRegion

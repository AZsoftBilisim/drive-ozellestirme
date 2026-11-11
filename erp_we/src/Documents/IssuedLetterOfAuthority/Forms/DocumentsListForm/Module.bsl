
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.AvailabilityOfOrdersGoods And Not Parameters.AvailabilityOfDSOrders Then
		Parameters.AvailabilityOfOrdersGoods = True;
		Parameters.AvailabilityOfDSOrders = True;
	EndIf;
	
	If Parameters.AvailabilityOfOrdersGoods Then
		AvailabilityOfOrdersGoods = GetFunctionalOption("UseAuthorizationLettersForInventoryReceipt")
			And (GetFunctionalOption("UsePurchaseOrders")
				Or GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers"))
			And AccessRight("Read", Metadata.AccumulationRegisters.PurchaseOrders)
			And AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences)
			And AccessRight("Insert", Metadata.Documents.IssuedLetterOfAuthority);
	EndIf;
	If Parameters.AvailabilityOfDSOrders Then
		AvailabilityOfDSOrders = GetFunctionalOption("UseAuthorizationLettersForInventoryReceipt")
		And AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting)
		And AccessRight("Read", Metadata.AccumulationRegisters.VendorsARAPAccounting)
		And AccessRight("Insert", Metadata.Documents.IssuedLetterOfAuthority);
	EndIf;
	
	If Not AvailabilityOfDSOrders And Not AvailabilityOfOrdersGoods Then
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	If Not Parameters.Property("FormCaption", Title) Then
		Title = NStr("vi = 'Giấy ủy quyền';
					|ru = 'Доверенности';
					|en = 'Authorization letters'; fa = 'وکالت‌نامه‌ها';
					|it = 'Deleghe';
					|pl = 'Uprawnienia';
					|tr = 'Yetki belgeleri'");
	EndIf;
	SetConditionalAppearance();
	SetConditionalAppearanceOfCash();
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	InitializeListOfOperations();
	
	ListLettersOfAuthority.Parameters.SetParameterValue("UpdateDate", BegOfDay(CurrentSessionDate()));
	ListLettersOfAuthority.Parameters.SetParameterValue("Positions_2", NStr("vi = 'mục';
																			|ru = 'поз.';
																			|en = 'pos.'; fa = 'قلم';
																			|it = 'pos.';
																			|pl = 'pos.';
																			|tr = 'pozisyon'"));
	TextNoReceiptOfTheDS = NStr("vi = 'Không thu tiền';
								|ru = 'Нет поступления ДС';
								|en = 'No cash receipt'; fa = 'No cash receipt';
								|it = 'Nessun entrata di fondi monetari';
								|pl = 'Brak wpłaty środków pieniężnych';
								|tr = 'Nakit makbuzu yok'");
	TextNoGoodsReceived = NStr("vi = 'Không tiếp nhận hàng hóa';
								|ru = 'Нет поступления товаров (МЦ)';
								|en = 'No goods receipt (tangible assets)'; fa = 'No goods receipt (tangible assets)';
								|it = 'Nessun entrata delle merci (beni e materiali)';
								|pl = 'Brak wpływu towarów (wartości materialnych)';
								|tr = 'Mal makbuzu yok (envanter)'");
	TheTextIsTheReceiptOfGoods = NStr("vi = 'Có tiếp nhận hàng hóa';
										|ru = 'Есть поступления товаров (МЦ)';
										|en = 'There are goods receipts (tangible assets)'; fa = 'There are goods receipts (tangible assets)';
										|it = 'Ci sono gli arrivi delle merci (beni e materiali)';
										|pl = 'Są wpływy towarów (wartości materialnych)';
										|tr = 'Mal makbuzu mevcut (envanter)'");
	TextFullReceiptOfTheDS = NStr("vi = 'Đã thu tiền đầy đủ';
									|ru = 'ДС поступили полностью';
									|en = 'Cash received in full'; fa = 'Cash received in full';
									|it = 'I fondi monetari entrati completamente';
									|pl = 'Środki pieniężne wpłyneły w całości';
									|tr = 'Nakit tam olarak alındı'");
	TextPartialReceiptOfDS = NStr("vi = 'Đã thu một phần';
									|ru = 'ДС поступили частично';
									|en = 'Cash partially received'; fa = 'Cash partially received';
									|it = 'I fondi monetari entrati parzialmente';
									|pl = 'Środki pieniężne wpłynęły częściowo';
									|tr = 'Nakit kısmen alındı'");
	ListLettersOfAuthority.Parameters.SetParameterValue("TextNoReceiptOfTheDS",
		TextNoReceiptOfTheDS);
	ListLettersOfAuthority.Parameters.SetParameterValue("TextNoGoodsReceived",
		TextNoGoodsReceived);
	ListLettersOfAuthority.Parameters.SetParameterValue("TheTextIsTheReceiptOfGoods",
		TheTextIsTheReceiptOfGoods);
	ListLettersOfAuthority.Parameters.SetParameterValue("TextFullReceiptOfTheDS",
		TextFullReceiptOfTheDS);
	ListLettersOfAuthority.Parameters.SetParameterValue("TextPartialReceiptOfDS",
		TextPartialReceiptOfDS);
	Items.FilterExecution.ChoiceList.Clear();
	Items.FilterExecution.ChoiceList.Add("", NStr("vi = 'Tất cả';
													|ru = 'Все';
													|en = 'All'; fa = 'همه';
													|it = 'Tutti';
													|pl = 'All';
													|tr = 'Tümü'"));
	Items.FilterExecution.ChoiceList.Add(TextNoReceiptOfTheDS, TextNoReceiptOfTheDS);
	Items.FilterExecution.ChoiceList.Add(TextNoGoodsReceived, TextNoGoodsReceived);
	Items.FilterExecution.ChoiceList.Add(TextPartialReceiptOfDS, TextPartialReceiptOfDS);
	Items.FilterExecution.ChoiceList.Add(TextFullReceiptOfTheDS, TextFullReceiptOfTheDS);
	Items.FilterExecution.ChoiceList.Add(TheTextIsTheReceiptOfGoods, TheTextIsTheReceiptOfGoods);
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	Parameters.Property("LetterOfAuthorityExistence", LetterOfAuthorityExistence);
	If QuickFilterStructure <> Undefined Then
		CommonClientServer.SetDynamicListFilterItem(ListLettersOfAuthority,
			"DeletionMark", False,,, True);
	EndIf;
	ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(Items.FilterDueDate_2.ChoiceList);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListLettersOfAuthority,
		"State", State, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListLettersOfAuthority,
		"EmployeeResponsible", EmployeeResponsible, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListLettersOfAuthority,
		"Person", Person, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByRelevanceWhenCreatingOnServer(ListLettersOfAuthority,
		Relevance, Items.FilterDueDate_2.ChoiceList, EventDate, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReferencesForRegistration,
		"ThereIsLetterOfAuthority", False, QuickFilterStructure, LetterOfAuthorityExistence);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReferencesForCashRegistration,
		"ThereIsLetterOfAuthority", False, QuickFilterStructure, LetterOfAuthorityExistence);
	If AvailabilityOfOrdersGoods And AvailabilityOfDSOrders Then
		AuthorizationLetterType = "";
	Else
		If AvailabilityOfOrdersGoods Then
			AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveGoods;
		EndIf;
		If AvailabilityOfDSOrders Then
			AuthorizationLetterType = Enums.TypesOfIssuedLettersOfAuthority.ToReceiveCash;
		EndIf;
	EndIf;
	CommonClientServer.SetDynamicListFilterItem(ListLettersOfAuthority,
		"AuthorizationLetterType", AuthorizationLetterType, DataCompositionComparisonType.Equal,, ValueIsFilled(AuthorizationLetterType));
	CommonClientServer.SetDynamicListFilterItem(ListLettersOfAuthority,
		"PaymentsReceiptsFilter", CompletenessOfExecution, DataCompositionComparisonType.Equal,,
		Not CompletenessOfExecution ="");
	SetCurrentPage();
	
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	TMCommonUseClientServer.SetFormItemProperty(Items,
		"ListReferencesForRegistrationCurrency", "Visible", UseMultipleCurrencies);
	TMCommonUseClientServer.SetFormItemProperty(Items,
		"ListReferencesForCashRegistrationCurrency", "Visible", UseMultipleCurrencies);
	
	StatusAvailable = UserRightsCached.WriteIssuedAuthorizationLetterInItsFinalStatus();
	Items.GroupSetStatus.Visible = StatusAvailable;
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
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
	
	If EventName = "Write_PurchaseOrder" Or EventName = "Entry_PowerOfAttorneyToReceiveGoods" Then
		Items.ListLettersOfAuthority.Refresh();
		If Items.PageOfTheOrderForRegistration.Visible Then
			Items.ListReferencesForRegistration.Refresh();
		EndIf;
	EndIf;
	If EventName = "Write_SalesOrder" Or EventName = "Entry_PowerOfAttorneyToReceiveCash" Then
		Items.ListLettersOfAuthority.Refresh();
		If Items.PageOfTheOrderForRegistrationOfTheDS.Visible Then
			Items.ListReferencesForCashRegistration.Refresh();
		EndIf;
	EndIf;
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
	
	Settings.Delete("OrderStatus_3");
	If QuickFilterStructure = Undefined Then
		LetterOfAuthorityExistence = Settings.Get("LetterOfAuthorityExistence");
	Else
		Settings.Delete("LetterOfAuthorityExistence");
	EndIf;
	If QuickFilterStructure = Undefined Or Not QuickFilterStructure.Property("EmployeeResponsible") Then
		ValueFromSettings = Settings.Get("EmployeeResponsible");
		If ValueIsFilled(ValueFromSettings) Then
			EmployeeResponsible = ValueFromSettings;
		EndIf;
	EndIf;
	ListSelectionsClientServer.SelectionByRelevanceWhenLoadingFromSettings(ListLettersOfAuthority,
		Relevance, Items.FilterDueDate_2.ChoiceList, EventDate, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ListLettersOfAuthority,
		"EmployeeResponsible", EmployeeResponsible, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ListLettersOfAuthority,
		"Person", Person, QuickFilterStructure, Settings);
	If ListSelectionsClientServer.YouNeedToSelectByStateWhenLoadingFromSettings(State,
		QuickFilterStructure, Settings) Then
		CommonClientServer.SetDynamicListFilterItem(ListLettersOfAuthority,
			"State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	EndIf;
	If Not ValueIsFilled(State) Then
		CommonClientServer.SetDynamicListFilterItem(ListLettersOfAuthority,
			"DeletionMark",,,, False);
	Else
		CommonClientServer.SetDynamicListFilterItem(ListLettersOfAuthority,
			"DeletionMark", False,,, True);
	EndIf;
	CommonClientServer.SetDynamicListFilterItem(ListReferencesForRegistration,
		"ThereIsLetterOfAuthority" ,False, DataCompositionComparisonType.Equal,, LetterOfAuthorityExistence);
	CommonClientServer.SetDynamicListFilterItem(ListReferencesForCashRegistration,
		"ThereIsLetterOfAuthority" ,False, DataCompositionComparisonType.Equal,, LetterOfAuthorityExistence);
	If Not ValueIsFilled(AuthorizationLetterType) Then
		AuthorizationLetterType = Settings.Get("AuthorizationLetterType");
		CommonClientServer.SetDynamicListFilterItem(ListLettersOfAuthority,
		"AuthorizationLetterType", AuthorizationLetterType, DataCompositionComparisonType.Equal,, ValueIsFilled(AuthorizationLetterType));
	Else
		Settings.Delete("AuthorizationLetterType");
	EndIf;
	If Not ValueIsFilled(CompletenessOfExecution) Then
		CompletenessOfExecution = Settings.Get("CompletenessOfExecution");
		CommonClientServer.SetDynamicListFilterItem(ListLettersOfAuthority,
		"PaymentsReceiptsFilter", CompletenessOfExecution, DataCompositionComparisonType.Equal,, ValueIsFilled(CompletenessOfExecution));
	Else
		Settings.Delete("CompletenessOfExecution");
	EndIf;
	
	// Filter by household.operations
	ListOfOperationsForCash = Settings.Get("CashTransactionList");
	ListOfOperationsForProducts = Settings.Get("OperationListGoods");
	
	InitializeListOfOperations();
	
	If ListOfOperationsForCash <> Undefined Then
		For Each Operation In ListOfOperationsForCash Do
			If Operation.Check Then
				ListOperation_ = CashTransactionList.FindByValue(Operation.Value);
				If ListOperation_ <> Undefined Then
					ListOperation_.Check = True;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	BusinessOperationPresentation = TransactionListPresentation(CashTransactionList);
	
	SetDynamicListSelectionByBusinessTransaction(ListReferencesForCashRegistration, CashTransactionList);
	
	If ListOfOperationsForProducts <> Undefined Then
		For Each Operation In ListOfOperationsForProducts Do
			If Operation.Check Then
				ListOperation_ = OperationListGoods.FindByValue(Operation.Value);
				If ListOperation_ <> Undefined Then
					ListOperation_.Check = True;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	BusinessOperationGoodsPresentation = TransactionListPresentation(OperationListGoods);
	
	SetDynamicListSelectionByBusinessTransaction(ListReferencesForRegistration, OperationListGoods);
	
	SetVisibilityAvailabilityOfOrderColumns();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure EmployeeResponsibleOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ListLettersOfAuthority,
		"EmployeeResponsible", EmployeeResponsible, DataCompositionComparisonType.Equal,, ValueIsFilled(EmployeeResponsible));
EndProcedure

&AtClient
Procedure PersonOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ListLettersOfAuthority,
		"Person", Person, DataCompositionComparisonType.Equal,, ValueIsFilled(Person));
EndProcedure

&AtClient
Procedure FilterStateOnChange(Item)
	
	If Not ValueIsFilled(State) Then
		CommonClientServer.SetDynamicListFilterItem(ListLettersOfAuthority,
			"DeletionMark",,,, False);
	Else
		CommonClientServer.SetDynamicListFilterItem(ListLettersOfAuthority,
			"DeletionMark", False,,, True);
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(ListLettersOfAuthority,
		"State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
EndProcedure

&AtClient
Procedure FilterDueDate_2OnChange(Item)

	ListSelectionsClientServer.WhenChangingRelevanceSelection(ListLettersOfAuthority, Relevance, EventDate, Items.FilterDueDate_2.ChoiceList);
EndProcedure

&AtClient
Procedure FilterDueDate_2ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TMCommonUseClient.WhenSelectingRelevanceSelection(
		ValueSelected,
		StandardProcessing,
		ThisForm,
		ListLettersOfAuthority,
		"Relevance",
		"FilterDueDate_2",
		"EventDate");
EndProcedure

&AtClient
Procedure FilterCompletionDateCleaningUp(Item, StandardProcessing)
	
	ListSelectionsClientServer.WhenClearingSelectionByRelevance(ListLettersOfAuthority,
		Relevance, EventDate, StandardProcessing);
EndProcedure

&AtClient
Procedure LetterOfAuthorityExistenceOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ListReferencesForRegistration,
		"ThereIsLetterOfAuthority", False, DataCompositionComparisonType.Equal,, LetterOfAuthorityExistence);
	CommonClientServer.SetDynamicListFilterItem(ListReferencesForCashRegistration,
		"ThereIsLetterOfAuthority", False, DataCompositionComparisonType.Equal,, LetterOfAuthorityExistence);
EndProcedure

&AtClient
Procedure AvailabilityOfAPowerOfAttorneyDSOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ListReferencesForRegistration,
		"ThereIsLetterOfAuthority", False, DataCompositionComparisonType.Equal,, LetterOfAuthorityExistence);
	CommonClientServer.SetDynamicListFilterItem(ListReferencesForCashRegistration,
		"ThereIsLetterOfAuthority", False, DataCompositionComparisonType.Equal,, LetterOfAuthorityExistence);
EndProcedure

&AtClient
Procedure FilterTypeOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		ListLettersOfAuthority, "AuthorizationLetterType", AuthorizationLetterType,
		DataCompositionComparisonType.Equal,, ValueIsFilled(AuthorizationLetterType));
EndProcedure

&AtClient
Procedure FilterTypeClearing(Item, StandardProcessing)
	
	CommonClientServer.SetDynamicListFilterItem(
		ListLettersOfAuthority, "AuthorizationLetterType", AuthorizationLetterType,
		DataCompositionComparisonType.Equal,, ValueIsFilled(AuthorizationLetterType));
EndProcedure

&AtClient
Procedure BusinessOperationSubmissionSelectionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure("TransactionList, Title", CashTransactionList, NStr("vi = 'Giao dịch';
																						|ru = 'Операции';
																						|en = 'Transactions'; fa = 'تراکنش‌ها';
																						|it = 'Operazioni';
																						|pl = 'Operacje';
																						|tr = 'İşlemler'"));
	OpenForm("Enum.BusinessTransactions.Form.SelectionFormOfTransaction",
		FormParameters, Item);
EndProcedure

&AtClient
Procedure BusinessOperationSubmissionSelectionClearing(Item, StandardProcessing)
	
	CashTransactionList.FillChecks(False);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListReferencesForCashRegistration,
		"BusinessOperation",
		Undefined,
		DataCompositionComparisonType.InList,,
		False);
EndProcedure

&AtClient
Procedure BusinessOperationSubmissionSelectionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("ValueList") Then
		
		CashTransactionList = ValueSelected;
		
	ElsIf TypeOf(ValueSelected) = Type("EnumRef.BusinessTransactions") Then
		
		For Each ListItem In CashTransactionList Do
			ListItem.Check = (ListItem.Value = ValueSelected);
		EndDo;
	EndIf;
	
	BusinessOperationPresentation = TransactionListPresentation(CashTransactionList);
	
	SetDynamicListSelectionByBusinessTransaction(ListReferencesForCashRegistration, CashTransactionList);
EndProcedure

&AtClient
Procedure BusinessOperationGoodsPresentationSelectionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure("TransactionList, Title", OperationListGoods, NStr("vi = 'Giao dịch';
																						|ru = 'Операции';
																						|en = 'Transactions'; fa = 'تراکنش‌ها';
																						|it = 'Operazioni';
																						|pl = 'Operacje';
																						|tr = 'İşlemler'"));
	OpenForm("Enum.BusinessTransactions.Form.SelectionFormOfTransaction",
		FormParameters, Item);
EndProcedure

&AtClient
Procedure BusinessOperationGoodsPresentationSelectionClearing(Item, StandardProcessing)
	
	OperationListGoods.FillChecks(False);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListReferencesForRegistration,
		"BusinessOperation",
		Undefined,
		DataCompositionComparisonType.InList,,
		False);
EndProcedure

&AtClient
Procedure BusinessOperationGoodsPresentationSelectionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("ValueList") Then
		
		OperationListGoods = ValueSelected;
		
	ElsIf TypeOf(ValueSelected) = Type("EnumRef.BusinessTransactions") Then
		
		For Each ListItem In OperationListGoods Do
			ListItem.Check = (ListItem.Value = ValueSelected);
		EndDo;
	EndIf;
	
	BusinessOperationGoodsPresentation = TransactionListPresentation(OperationListGoods);
	
	SetDynamicListSelectionByBusinessTransaction(ListReferencesForRegistration, OperationListGoods);
EndProcedure

&AtClient
Procedure HyperlinkPurchaseHistoryURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("FormAssignmentKey", "");
	OpenForm("DataProcessor.LogOfPurchaseDocuments.Form.DocumentsList", FormParameters);
	
EndProcedure

&AtClient
Procedure HyperlinkSalesLogURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("FormAssignmentKey", "");
	OpenForm("DataProcessor.LogOfSalesDocuments.Form.DocumentsList", FormParameters);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListLettersOfAuthority

&AtClient
Procedure ListLettersOfAuthorityOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListReferencesForRegistration

&AtClient
Procedure ListReferencesForRegistrationSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.ListReferencesForRegistration.CurrentData = Undefined Then
		Return;
	EndIf;
	
	ShowValue(Undefined, Items.ListReferencesForRegistration.CurrentData.Ref);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListReferencesForCashRegistration

&AtClient
Procedure ListReferencesForCashRegistrationSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.ListReferencesForCashRegistration.CurrentData = Undefined Then
		Return;
	EndIf;
	
	ShowValue(Undefined, Items.ListReferencesForCashRegistration.CurrentData.Ref);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetTheIssuedStatus(Command)
	
	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.ListLettersOfAuthority);
	If HighlightedLinks.Count() = 0 Then
		Return;
	EndIf;
	
	QuestionTitle = NStr("vi = 'Đặt trạng thái giấy ủy quyền';
						|ru = 'Установка статуса доверенностей';
						|en = 'Set status of authorization letters'; fa = 'Set status of authorization letters';
						|it = 'Assegnazione stato alle deleghe';
						|pl = 'Ustawienie statusu pełnomocnictw';
						|tr = 'Yetki belgelerinin durumunun ayarlanması'");
	QueryText = NStr("vi = 'Giấy ủy quyềnđược nêu bật trong danh sách sẽ được đặt thành ""Đã ban hành"". Cài đặt?';
					|ru = 'У выделенных в списке доверенностей будет установлен статус ""Выдана"". Установить?';
					|en = 'Status of authorization letters selected in the list will be set to Issued. Set the status?'; fa = 'Status of authorization letters selected in the list will be set to Issued. Set the status?';
					|it = 'Alle deleghe selezionate nell''elenco verrà assegnato lo stato ""Rilasciata"". Assegnare?';
					|pl = 'Dla wybranych w liście pełnomocnictw będzie utawiony status ""Выдана"". Ustawić?';
					|tr = 'Listede seçili yetki belgelerinin durumu ""Verildi"" olarak ayarlanacaktır. Ayarlansın mı?'");
	CallbackDescription = New CallbackDescription("SetTheIssuedStatusCompletion", ThisObject,
		New Structure("HighlightedLinks", HighlightedLinks));
	ButtonsList = New ValueList();
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Thiết lập';
												|ru = 'Установить';
												|en = 'Set'; fa = 'مجموعه';
												|it = 'Impostare';
												|pl = 'Set';
												|tr = 'Ayarla'"));
	ButtonsList.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отменить';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annullare';
													|pl = 'Cancel';
													|tr = 'İptal et'"));
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList,, DialogReturnCode.Cancel, QuestionTitle);
EndProcedure

&AtClient
Procedure SetTheIssuedStatusCompletion(Val QuestionResult = Undefined, Val AdditionalParameters = Undefined) Export
	
	HighlightedLinks = AdditionalParameters.HighlightedLinks;
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(HighlightedLinks, "Issued");
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.ListLettersOfAuthority, ProcessedItemsCount,
		HighlightedLinks.Count(), NStr("vi = 'Đã chi';
										|ru = 'Выдана';
										|en = 'Issued'; fa = 'صادرشده';
										|it = 'Rilasciata';
										|pl = 'Issued';
										|tr = 'Verildi'"));
EndProcedure

&AtClient
Procedure SetTheUsedStatus(Command)
	
	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.ListLettersOfAuthority);
	If HighlightedLinks.Count() = 0 Then
		Return;
	EndIf;
	
	QuestionTitle = NStr("vi = 'Đặt trạng thái giấy ủy quyền';
						|ru = 'Установка статуса доверенностей';
						|en = 'Set status of authorization letters'; fa = 'Set status of authorization letters';
						|it = 'Assegnazione stato alle deleghe';
						|pl = 'Ustawienie statusu pełnomocnictw';
						|tr = 'Yetki belgelerinin durumunun ayarlanması'");
	QueryText = NStr("vi = 'Giấy ủy quyềnđ ược nêu bật trong danh sách sẽ được đặt thành ""Được sử dụng"". Cài đặt?';
					|ru = 'У выделенных в списке доверенностей будет установлен статус ""Использована"". Установить?';
					|en = 'Status of the authorization letters selected in the list will be set to Used. Set?'; fa = 'Status of the authorization letters selected in the list will be set to Used. Set?';
					|it = 'Alle deleghe selezionate nell''elenco verrà assegnato lo stato ""Utilizzata"". Assegnare?';
					|pl = 'Dla wybranych w liście pełnomocnictw będzie ustawiony status ""Использована"". Ustawić?';
					|tr = 'Listede seçili yetki belgelerinin durumu ""Kullanıldı"" olarak ayarlanacaktır. Ayarlansın mı?'");
	CallbackDescription = New CallbackDescription("SetTheUsedStatusCompletion", ThisObject,
		New Structure("HighlightedLinks", HighlightedLinks));
	ButtonsList = New ValueList();
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Thiết lập';
												|ru = 'Установить';
												|en = 'Set'; fa = 'مجموعه';
												|it = 'Impostare';
												|pl = 'Set';
												|tr = 'Ayarla'"));
	ButtonsList.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отменить';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annullare';
													|pl = 'Cancel';
													|tr = 'İptal et'"));
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList,, DialogReturnCode.Cancel, QuestionTitle);
EndProcedure

&AtClient
Procedure SetTheUsedStatusCompletion(Val QuestionResult = Undefined, Val AdditionalParameters = Undefined) Export
	
	HighlightedLinks = AdditionalParameters.HighlightedLinks;
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(
	Items.ListLettersOfAuthority.SelectedRows, "Used_3");
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.ListLettersOfAuthority, ProcessedItemsCount,
		HighlightedLinks.Count(), NStr("vi = 'Được sử dụng';
										|ru = 'Использована';
										|en = 'Used'; fa = 'استفاده‌شده';
										|it = 'Utilizzata';
										|pl = 'Used';
										|tr = 'Kullanıldı'"));
EndProcedure

&AtClient
Procedure SetTheStatusNotUsed(Command)
	
	HighlightedLinks =TMCommonUseClient.CheckGetLinksHighlightedInList(Items.ListLettersOfAuthority);
	If HighlightedLinks.Count() = 0 Then
		Return;
	EndIf;
	
	QuestionTitle = NStr("vi = 'Đặt trạng thái giấy ủy quyền';
						|ru = 'Установка статуса доверенностей';
						|en = 'Set status of authorization letters'; fa = 'Set status of authorization letters';
						|it = 'Assegnazione stato alle deleghe';
						|pl = 'Ustawienie statusu pełnomocnictw';
						|tr = 'Yetki belgelerinin durumunun ayarlanması'");
	QueryText = NStr("vi = 'Giấy ủy quyền được nêu bật trong danh sách sẽ được đặt thành ""Không được sử dụng"". Cài đặt?';
					|ru = 'У выделенных в списке доверенностей будет установлен статус ""Не использована"". Установить?';
					|en = 'Status of the authorization letters selected in the list will be set to Not used. Set?'; fa = 'Status of the authorization letters selected in the list will be set to Not used. Set?';
					|it = 'Alle deleghe selezionate nell''elenco verrà assegnato lo stato ""Non utilizzata"". Assegnare?';
					|pl = 'Dla wybranych w liście pełnomocnictw będzie ustawiony status ""Не использована"". Ustawić?';
					|tr = 'Listede seçili yetki belgelerinin durumu ""Kullanılmadı"" olarak ayarlanacaktır. Ayarlansın mı?'");
	CallbackDescription = New CallbackDescription("SetTheStatusNotUsedCompletion", ThisObject,
		New Structure("HighlightedLinks", HighlightedLinks));
	ButtonsList = New ValueList();
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Thiết lập';
												|ru = 'Установить';
												|en = 'Set'; fa = 'مجموعه';
												|it = 'Impostare';
												|pl = 'Set';
												|tr = 'Ayarla'"));
	ButtonsList.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отменить';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annullare';
													|pl = 'Cancel';
													|tr = 'İptal et'"));
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList,, DialogReturnCode.Cancel, QuestionTitle);
EndProcedure

&AtClient
Procedure SetTheStatusNotUsedCompletion(Val QuestionResult = Undefined, Val AdditionalParameters = Undefined) Export
	
	HighlightedLinks = AdditionalParameters.HighlightedLinks;
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(
	Items.ListLettersOfAuthority.SelectedRows, "NotUsed_3");
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.ListLettersOfAuthority, ProcessedItemsCount,
		HighlightedLinks.Count(), NStr("vi = 'Không sử dụng';
										|ru = 'Не использована';
										|en = 'Not used'; fa = 'استفاده نمی‌شود';
										|it = 'Non utilizzata';
										|pl = 'Niewykorzystane';
										|tr = 'Kullanılmadı'"));
EndProcedure

&AtClient
Procedure SetTheStatusToCanceled_4(Command)
	
	HighlightedLinks =TMCommonUseClient.CheckGetLinksHighlightedInList(Items.ListLettersOfAuthority);
	If HighlightedLinks.Count() = 0 Then
		Return;
	EndIf;
	
	QuestionTitle = NStr("vi = 'Đặt trạng thái giấy ủy quyền';
						|ru = 'Установка статуса доверенностей';
						|en = 'Set status of authorization letters'; fa = 'Set status of authorization letters';
						|it = 'Assegnazione stato alle deleghe';
						|pl = 'Ustawienie statusu pełnomocnictw';
						|tr = 'Yetki belgelerinin durumunun ayarlanması'");
	QueryText = NStr("vi = 'Giấy ủy quyền được nêu bật trong danh sách sẽ được đặt thành ""Đã hủy"". Cài đặt?';
					|ru = 'У выделенных в списке доверенностей будет установлен статус ""Аннулирована"". Установить?';
					|en = 'Status of the authorization letters selected in the list will be set to Canceled. Set?'; fa = 'Status of the authorization letters selected in the list will be set to Canceled. Set?';
					|it = 'Alle deleghe selezionate nell''elenco verrà assegnato lo stato ""Annullata"". Assegnare?';
					|pl = 'Dla wybranych w liście pełnomocnictw będzie utawiony status ""Аннулирована"". Ustawić?';
					|tr = 'Listede seçili yetki belgelerinin durumu ""İptal edildi"" olarak ayarlanacaktır. Ayarlansın mı?'");
	CallbackDescription = New CallbackDescription("SetTheStatusToCanceled_4Completion", ThisObject,
		New Structure("HighlightedLinks", HighlightedLinks));
	ButtonsList = New ValueList();
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Thiết lập';
												|ru = 'Установить';
												|en = 'Set'; fa = 'مجموعه';
												|it = 'Impostare';
												|pl = 'Set';
												|tr = 'Ayarla'"));
	ButtonsList.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отменить';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annullare';
													|pl = 'Cancel';
													|tr = 'İptal et'"));
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList,, DialogReturnCode.Cancel, QuestionTitle);
EndProcedure

&AtClient
Procedure SetTheStatusToCanceled_4Completion(Val QuestionResult = Undefined, Val AdditionalParameters = Undefined) Export
	
	HighlightedLinks = AdditionalParameters.HighlightedLinks;
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(
	Items.ListLettersOfAuthority.SelectedRows, "Cancelled__");
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.ListLettersOfAuthority, ProcessedItemsCount,
		HighlightedLinks.Count(), NStr("vi = 'Đã hủy';
										|ru = 'Аннулирована';
										|en = 'Canceled'; fa = 'لغوشده';
										|it = 'Annullata';
										|pl = 'Canceled';
										|tr = 'İptal Edildi'"));
EndProcedure

&AtClient
Procedure SetThePartiallyUsedStatus(Command)
	
	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.ListLettersOfAuthority);
	If HighlightedLinks.Count() = 0 Then
		Return;
	EndIf;
	
	QuestionTitle = NStr("vi = 'Đặt trạng thái giấy ủy quyền';
						|ru = 'Установка статуса доверенностей';
						|en = 'Set status of authorization letters'; fa = 'Set status of authorization letters';
						|it = 'Assegnazione stato alle deleghe';
						|pl = 'Ustawienie statusu pełnomocnictw';
						|tr = 'Yetki belgelerinin durumunun ayarlanması'");
	QueryText = NStr("vi = 'Sẽ đặt trạng thái ""Sử dụng một phần"" cho các giấy ủy quyền được chọn trong danh sách. Đặt ngay?';
					|ru = 'У выделенных в списке доверенностей будет установлен статус ""Использована частично"". Установить?';
					|en = 'The status of the authorization letters selected in the list will be set to ""Partially used"". Do you want to set this status?'; fa = 'The status of the authorization letters selected in the list will be set to ""Partially used"". Do you want to set this status?';
					|it = 'Alle deleghe selezionate nell''elenco verrà assegnato lo stato ""Utilizzata parzialmente"". Assegnare?';
					|pl = 'Dla wybranych w liście pełnomocnictw będzie utawiony status ""Использована частично"". Ustawić?';
					|tr = 'Listede seçili yetki belgelerinin durumu ""Kısmen kullanıldı"" olarak ayarlanacaktır. Ayarlansın mı?'");
	CallbackDescription = New CallbackDescription("SetThePartiallyUsedStatusCompletion", ThisObject,
		New Structure("HighlightedLinks", HighlightedLinks));
	ButtonsList = New ValueList();
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Thiết lập';
												|ru = 'Установить';
												|en = 'Set'; fa = 'مجموعه';
												|it = 'Impostare';
												|pl = 'Set';
												|tr = 'Ayarla'"));
	ButtonsList.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отменить';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annullare';
													|pl = 'Cancel';
													|tr = 'İptal et'"));
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList,, DialogReturnCode.Cancel, QuestionTitle);
EndProcedure

&AtClient
Procedure SetThePartiallyUsedStatusCompletion(Val QuestionResult = Undefined, Val AdditionalParameters = Undefined) Export
	
	HighlightedLinks = AdditionalParameters.HighlightedLinks;
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(
	Items.ListLettersOfAuthority.SelectedRows, "UsedPartially");
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.ListLettersOfAuthority, ProcessedItemsCount,
		HighlightedLinks.Count(), NStr("vi = 'Sử dụng một phần';
										|ru = 'Использована частично';
										|en = 'Used partially'; fa = 'استفاده‌شده به‌طور جزئی';
										|it = 'Utilizzata parzialmente';
										|pl = 'Wykorzystane częściowo';
										|tr = 'Kısmen kullanıldı'"));
EndProcedure

&AtClient
Procedure ToCalculateStatus(Command)
	
	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.ListLettersOfAuthority);
	
	If HighlightedLinks.Count() Then
		QuestionTitle = NStr("vi = 'Tính toán tình trạng quyền hạn của luật sư';
							|ru = 'Расчет статуса доверенностей';
							|en = 'Calculate status of authorization letters'; fa = 'Calculate status of authorization letters';
							|it = 'Calcolo stato deleghe';
							|pl = 'Rozliczenie statusu pełnomocnictw';
							|tr = 'Yetki belgelerinin durumunun hesaplanması'");
		If HighlightedLinks.Count() > 0 Then
			TextSTARTOfQuestion = NStr("vi = 'Quyền hạn của luật sư được nêu bật trong danh sách';
										|ru = 'У выделенных в списке доверенностей';
										|en = 'Authorization letters selected in the list'; fa = 'Authorization letters selected in the list';
										|it = 'Alle deleghe selezionate nell''elenco';
										|pl = 'Dla wydzielonych w liście pełnomocnictw';
										|tr = 'Listede seçili yetki belgeleri'");
			AddlParameters = New Structure("HighlightedLinks", HighlightedLinks);
		Else
			TextSTARTOfQuestion = NStr("vi = 'Giấy ủy quyền cho tháng trước';
										|ru = 'У доверенностей за последний месяц';
										|en = 'Of authorization letters for the last month'; fa = 'Of authorization letters for the last month';
										|it = 'Alle deleghe per ultimo mese';
										|pl = 'Dla pełnomocnictw za ostatni miesiąc';
										|tr = 'Geçen aya ait yetki belgeleri'");
			AddlParameters = New Structure("HighlightedLinks", New Array());
		EndIf;
		
		QueryText = StrTemplate(NStr("vi = '%1 trong trạng thái ""Đã chi"" và ""Được sử dụng một phần"", trạng thái sẽ được tính toán lại. Tính toán?';
									|ru = '%1 в статусе ""Выдана"" и ""Использована частично"" будет пересчитан статус. Рассчитать?';
									|en = '%1 status will be recalculated in the Issued and Used partially status. Calculate?'; fa = '%1 status will be recalculated in the Issued and Used partially status. Calculate?';
									|it = '%1 nello stato ""Rilasciata"" e ""Parzialmente utilizzata"" verrà ricalcolato lo stato. Calcolare?';
									|pl = '%1 w statusie ""Выдана"" i ""Использована частично"" będzie przeliczony status. Rozliczyć?';
									|tr = '%1""Verildi"" ve ""Kısmen kullanıldı"" durumundaki veriler yeniden hesaplanacaktır. Hesaplansın mı?'"),
			TextSTARTOfQuestion);
		
		CallbackDescription = New CallbackDescription("ToCalculateStatusCompletion", ThisObject, AddlParameters);
		ButtonsList = New ValueList();
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Tính toán';
													|ru = 'Рассчитать';
													|en = 'Calculate'; fa = 'محاسبه';
													|it = 'Calcolare';
													|pl = 'Calculate';
													|tr = 'Hesapla'"));
		ButtonsList.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
														|ru = 'Отменить';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Annullare';
														|pl = 'Cancel';
														|tr = 'İptal et'"));
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList,, DialogReturnCode.Cancel, QuestionTitle);
	EndIf;
	
EndProcedure

&AtClient
Procedure ToCalculateStatusCompletion(Val QuestionResult = Undefined, Val AdditionalParameters = Undefined) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	SelectedDocuments.LoadValues(AdditionalParameters.HighlightedLinks);
	
	CreateBackgroundTaskStatusCalculation();
EndProcedure

&AtClient
Procedure CreateAPowerOfAttorneyToReceiveGoods(Command)
	
	CurrentData = Items.ListReferencesForRegistration.CurrentData;
	If CurrentData = Undefined Then
		WarningText = NStr("vi = 'Hãy chỉ ra lệnh để tạo giấy ủy quyền';
							|ru = 'Укажите распоряжение для формирования доверенности';
							|en = 'Specify a reference to generate an authorization letter'; fa = 'Specify a reference to generate an authorization letter';
							|it = 'Specificare la disposizione per generazione della delega';
							|pl = 'Wskaż zamówienie do utworzenia pełnomocnictwa';
							|tr = 'Yetki belgesi oluşturmak için sırayı belirtin'");
		ShowMessageBox(Undefined, WarningText);
		Return;
	EndIf;
	
	StructureBase = New Structure("DocumentBasis", CurrentData.Ref);
	OpenForm("Document.IssuedLetterOfAuthority.Form.DocumentForm", New Structure("Basis", StructureBase));
EndProcedure

&AtClient
Procedure CreateAPowerOfAttorneyToReceiveTheDS(Command)
	
	CurrentData = Items.ListReferencesForCashRegistration.CurrentData;
	If CurrentData = Undefined Then
		WarningText = NStr("vi = 'Hãy chỉ ra lệnh để tạo giấy ủy quyền';
							|ru = 'Укажите распоряжение для формирования доверенности';
							|en = 'Specify a reference to generate an authorization letter'; fa = 'Specify a reference to generate an authorization letter';
							|it = 'Specificare la disposizione per generazione della delega';
							|pl = 'Wskaż zamówienie do utworzenia pełnomocnictwa';
							|tr = 'Yetki belgesi oluşturmak için sırayı belirtin'");
		ShowMessageBox(Undefined, WarningText);
		Return;
	EndIf;
	
	StructureBase = New Structure("DocumentBasis, ForCash",CurrentData.Ref, True);
	OpenForm("Document.IssuedLetterOfAuthority.Form.DocumentForm", New Structure("Basis", StructureBase));
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.ListLettersOfAuthority);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.ListLettersOfAuthority, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListLettersOfAuthority);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure ListLettersOfAuthoritySelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.StatusPresentation Then
	EndIf;
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command,
		ThisForm, Items.ListLettersOfAuthority);
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure InitializeListOfOperations()
	
	Operations = Enums.BusinessTransactions;
	
	CashTransactionList.Clear();
	CashTransactionList.Add(Operations.CashReceiptFromCustomer,
		NStr("vi = 'Nhận thanh toán từ khách hàng';
			|ru = 'Поступление оплаты от клиента';
			|en = 'Customer payment'; fa = 'Customer payment';
			|it = 'Pervenimento di pagamento dal cliente';
			|pl = 'Wpływ płatności od klienta';
			|tr = 'Müşteriden ödeme alınması'"));
	CashTransactionList.Add(Operations.RefundFromVendor,
		NStr("vi = 'Nhận lại tiền từ nhà cung cấp';
			|ru = 'Возврат денежных средств от поставщика';
			|en = 'Refund from vendor'; fa = 'Refund from vendor';
			|it = 'Rimborsi dal fornitore';
			|pl = 'Zwrot środków pieniężnych od dostawcy';
			|tr = 'Bir tedarikçiden para iadesi'"));
	
	Items.BusinessOperationSubmissionSelection.ChoiceList.Clear();
	For Each Operation In CashTransactionList Do
		Items.BusinessOperationSubmissionSelection.ChoiceList.Add(Operation.Value, Operation.Presentation);
	EndDo;
	
	OperationListGoods.Clear();
	OperationListGoods.Add(Operations.SchedulingOfPurchaseOrder);
	OperationListGoods.Add(Operations.ReturnOfGoodsFromCustomer, NStr("vi = 'Nhận hàng bán bị trả lại';
																		|ru = 'Возврат товаров от клиента';
																		|en = 'Sales return'; fa = 'برگشت از فروش';
																		|it = 'Resi delle merci dal cliente';
																		|pl = 'Zwrot towarów od klienta';
																		|tr = 'Müşteriden mal iadesi'"));
	OperationListGoods.Add(Operations.PurchaseFromSupplier, NStr("vi = 'Mua hàng từ nhà cung cấp';
																|ru = 'Закупка у поставщика';
																|en = 'Purchase from vendor'; fa = 'خرید از تأمین‌کننده';
																|it = 'Acquisto dal fornitore';
																|pl = 'Zakup u dostawcy';
																|tr = 'Tedarikçiden satın alma'"));
	
	
	OperationListGoods.Add(
		Operations.TollManufacturing2_5,
		NStr("vi = 'Sản xuất sản phẩm từ nguyên liệu gia công';
			|ru = 'Производство продукции из давальческого сырья';
			|en = 'Subcontracting'; fa = 'پیمانکاری فرعی';
			|it = 'Subcontracting';
			|pl = 'Subcontracting';
			|tr = 'Sağlayıcı hammaddelerinden üretim'"));
	
	OperationListGoods.Add(
		Operations.Subcontracting2_5,
		NStr("vi = 'Sản xuất sản phẩm từ nguyên liệu gia công';
			|ru = 'Производство продукции из давальческого сырья';
			|en = 'Subcontracting'; fa = 'پیمانکاری فرعی';
			|it = 'Subcontracting';
			|pl = 'Subcontracting';
			|tr = 'Sağlayıcı hammaddelerinden üretim'"));
	
	OperationListGoods.Add(
		Operations.RepairProductsFromProvidedMaterials2_5,
		NStr("vi = 'Sửa chữa sản phẩm từ nguyên liệu gia công';
			|ru = 'Ремонт продукции из давальческого сырья';
			|en = 'Repair products from provided materials'; fa = 'تعمیر محصولات از مواد ارائه‌شده';
			|it = 'Repair products from provided materials';
			|pl = 'Repair products from provided materials';
			|tr = 'Sağlayıcı hammaddelerinden ürün bakım onarımı'"));
	
	OperationListGoods.Add(
		Operations.PerformWorksUsingProvidedMaterials2_5,
		NStr("vi = 'Thực hiện công việc có sử dụng nguyên liệu gia công';
			|ru = 'Выполнение работ с использованием давальческого сырья';
			|en = 'Perform works using provided materials'; fa = 'انجام کارها با استفاده از مواد ارائه‌شده';
			|it = 'Perform works using provided materials';
			|pl = 'Perform works using provided materials';
			|tr = 'Sağlayıcı hammaddeleri kullanarak çalışma yapma'"));
	
	OperationListGoods.Add(
		Operations.PerformRMUsingProvidedMaterials2_5,
		NStr("vi = 'Thực hiện công việc sửa chữa có sử dụng nguyên liệu gia công';
			|ru = 'Выполнение ремонтных работ с использованием давальческого сырья';
			|en = 'Perform R&M using provided materials'; fa = 'انجام تعمیر و نگهداری با استفاده از مواد ارائه‌شده';
			|it = 'Perform R&M using provided materials';
			|pl = 'Perform R&M using provided materials';
			|tr = 'Sağlayıcı hammaddeleri kullanarak bakım onarım çalışmaları yapma'"));
	
	OperationListGoods.Add(Operations.ProductionByToller2_5,
		NStr("vi = 'Sản xuất của người nhận gia công';
			|ru = 'Производство у переработчика';
			|en = 'External subcontracting'; fa = 'پیمانکاری فرعی خارجی';
			|it = 'Produzione presso il subfornitore';
			|pl = 'Produkcja u przetwórcy';
			|tr = 'Fason üreticide üretim'"));
		
	If GetFunctionalOption("UseImportOfGoodsFromCustomsUnion") Then
		OperationListGoods.Add(Operations.ProductionByToller2_5,
			NStr("vi = 'Sản xuất tại bên nhận gia công (ở các nước EAEU)';
				|ru = 'Производство у переработчика (в странах ЕАЭС)';
				|en = 'Production by subcontractor (in the EAEU countries)'; fa = 'تولید توسط پیمانکار فرعی (در کشورهای EAEU)';
				|it = 'Produzione presso il gestore (nei paesi dell''UEE)';
				|pl = 'Produkcja u przetwórcy (w krajach EUG)';
				|tr = 'fason üreticide üretim (AEB ülkelerinde)'"));	
	EndIf;
	Items.BusinessOperationGoodsPresentationSelection.ChoiceList.Clear();
	For Each Operation In OperationListGoods Do
		Items.BusinessOperationGoodsPresentationSelection.ChoiceList.Add(Operation.Value,
			Operation.Presentation);
	EndDo;
EndProcedure

&AtClientAtServerNoContext
Function TransactionListPresentation(TransactionList)
	
	TransactionListPresentation = "";
	For Each ListItem In TransactionList Do
		If ListItem.Check Then
			TransactionListPresentation = TransactionListPresentation
				+ ?(ValueIsFilled(TransactionListPresentation), ", ", "")
				+ ?(ValueIsFilled(ListItem.Presentation), ListItem.Presentation, ListItem.Value);
		EndIf;
	EndDo;
	
	Return TransactionListPresentation;
EndFunction

&AtServer
Procedure SetVisibilityAvailabilityOfOrderColumns()
	
	MultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	MultipleWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	PartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	Items.ListReferencesForRegistrationCounterparty.Visible = 
		Items.ListReferencesForRegistrationCounterparty.Visible And Not PartnersAsCounterparties;
	Items.ListReferencesForCashRegistrationCounterparty.Visible = 
		Items.ListReferencesForCashRegistrationCounterparty.Visible And Not PartnersAsCounterparties;
		
	Items.ListReferencesForRegistrationOrganization.Visible = 
		Items.ListReferencesForRegistrationOrganization.Visible And MultipleCompanies;
	Items.ListReferencesForCashRegistrationOrganization.Visible = 
		Items.ListReferencesForCashRegistrationOrganization.Visible And MultipleCompanies;
		
	Items.ListReferencesForRegistrationWarehouse.Visible = 
		Items.ListReferencesForRegistrationWarehouse.Visible And MultipleWarehouses;
EndProcedure

&AtClientAtServerNoContext
Procedure SetDynamicListSelectionByBusinessTransaction(DynamicList, ListOfBusinessTransactions)
	
	SelectedOperations = New Array;
	For Each ListItem In ListOfBusinessTransactions Do
		If ListItem.Check Then
			SelectedOperations.Add(ListItem.Value);
		EndIf;
	EndDo;
	CommonClientServer.SetDynamicListFilterItem(
		DynamicList,
		"BusinessOperation",
		SelectedOperations,
		DataCompositionComparisonType.InList,,
		SelectedOperations.Count());
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	QueryText = Documents.IssuedLetterOfAuthority.TextOfRequestForOrdersForGoods();
	
	If Not ValueIsFilled(QueryText) Then
		AvailabilityOfOrdersGoods = False;
	EndIf;
	
	Items.PageOfTheOrderForRegistration.Visible = AvailabilityOfOrdersGoods;
	If Not AvailabilityOfOrdersGoods Then
		Return;
	EndIf;
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.ListReferencesForRegistration, ListProperties);
	
	If ListReferencesForRegistration.Parameters.FindParameterValue(New DataCompositionParameter("UseAdvancedFeaturesOfSalesOrder")) <> Undefined Then
		ListReferencesForRegistration.Parameters.SetParameterValue("UseAdvancedFeaturesOfSalesOrder",
			GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	EndIf;
			
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
	
	// A power of attorney has been issued according to the document
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Có giấy ủy quyền';
							|ru = 'Есть доверенность';
							|en = 'There is authorization letter'; fa = 'وکالت‌نامه وجود دارد';
							|it = 'C''è una delega';
							|pl = 'Jest pełnomocnictwo';
							|tr = 'Yetki belgesi bulunuyor'");
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThereIsLetterOfAuthority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject,
		"ListReferencesForRegistration.Date", Items.ListReferencesForRegistrationDate.Name);
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfCash()
	
	QueryText = Documents.IssuedLetterOfAuthority.TextOfRequestForCashOrders();
	If Not ValueIsFilled(QueryText) Then
		AvailabilityOfDSOrders = False;
	EndIf;
	
	Items.PageOfTheOrderForRegistrationOfTheDS.Visible = AvailabilityOfDSOrders;
	If Not AvailabilityOfDSOrders Then
		Return;
	EndIf;
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.ListReferencesForCashRegistration, ListProperties);
	
	If ListReferencesForCashRegistration.Parameters.FindParameterValue(New DataCompositionParameter("UseAdvancedFeaturesOfSalesOrder")) <> Undefined Then
		ListReferencesForCashRegistration.Parameters.SetParameterValue("UseAdvancedFeaturesOfSalesOrder",
			GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	EndIf;
	
	// Conditional design of the dynamic list of "ListspOryazheniyanAoFormleniyeDS"
	ListOfConditionalAppearance = ListReferencesForCashRegistration.SettingsComposer.Settings.ConditionalAppearance;
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
	
	// A power of attorney has been issued according to the document
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Có giấy ủy quyền';
							|ru = 'Есть доверенность';
							|en = 'There is an authorization letter'; fa = 'There is an authorization letter';
							|it = 'C''è una delega';
							|pl = 'Jest pełnomocnictwo';
							|tr = 'Yetki belgesi bulunuyor'");
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThereIsLetterOfAuthority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject,
		"ListReferencesForCashRegistration.Date", Items.ListReferencesForCashRegistrationDate.Name);
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.IssuedLetterOfAuthority.EmptyRef"));
	Managers.Add(PredefinedValue("Document.PurchaseOrder.EmptyRef"));
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
		Ref = ReferencesArrray[0];
		If TypeOf(Ref) = Type("DocumentRef.PurchaseOrder") Then
			Items.ListReferencesForRegistration.CurrentRow = Ref;
			Items.Pages.CurrentPage = Items.Pages.ChildItems.PageOfTheOrderForRegistration;
		ElsIf TypeOf(Ref) = Type("DocumentRef.IssuedLetterOfAuthority") Then
			Items.ListLettersOfAuthority.CurrentRow = Ref;
			Items.Pages.CurrentPage = Items.Pages.ChildItems.PowerOfAttorneyPageForReceivingGoods;
		ElsIf TypeOf(Ref) = Type("DocumentRef.SalesOrder") Then
			Items.ListReferencesForCashRegistration.CurrentRow = Ref;
			Items.Pages.CurrentPage = Items.Pages.ChildItems.PageOfTheOrderForRegistrationOfTheDS;
		EndIf;
		ShowValue(Undefined, Ref);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetCurrentPage()
	
	CurrentPageName = "";
	If Parameters.Property("CurrentPageName", CurrentPageName) Then
		If ValueIsFilled(CurrentPageName) Then
			CurrentItem = Items[CurrentPageName];
		EndIf;
	EndIf;
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject,
		"ListLettersOfAuthority.Date", Items.ListDate.Name);
EndProcedure

&AtClient
Procedure Filterexecution_OnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ListLettersOfAuthority,
		"PaymentsReceiptsFilter", CompletenessOfExecution, DataCompositionComparisonType.Equal,,
		Not CompletenessOfExecution ="");
EndProcedure

#EndRegion

#Region StatusCalculation

&AtClient
Procedure ProcessCompletionOfStatusCalculation(StorageAddress)
	
	ClearMessages();
	
	ProcessedItemsCount = GetFromTempStorage(StorageAddress);
	TotalCount1 = SelectedDocuments.Count();
	
	SelectedDocuments.Clear();
	
	NotifyAboutStatusCalculation(Items.ListLettersOfAuthority, ProcessedItemsCount, TotalCount1);
EndProcedure

&AtClient
Procedure NotifyAboutStatusCalculation(DocumentsList, ProcessedItemsCount, TotalCount1)
	
	If ProcessedItemsCount > 0 Then
		
		If DocumentsList <> Undefined Then
			DocumentsList.Refresh();
		EndIf;
		If TotalCount1 = 0 Then
			If ProcessedItemsCount = 1 Then
				MessageText = NStr("vi = 'Đối với 1 giấy ủy quyền cho tháng trước, trạng thái được tính.';
									|ru = 'Для 1 доверенности за последний месяц статус рассчитан.';
									|en = 'Status is calculated for 1 authorization letter during the last month.'; fa = 'Status is calculated for 1 authorization letter during the last month.';
									|it = 'Per 1 delega per ultimo mese è calcolato lo stato.';
									|pl = 'Dla 1 pełnomocnictwa za ostatni miesiąc status jest rozliczony.';
									|tr = 'Geçen aya ait yetki belgesi için durum hesaplandı.'");
			Else
				MessageText = NStr("vi = 'Đối với %1 giấy ủy quyền cho tháng trước, trạng thái được tính.';
									|ru = 'Для %1 доверенностей за последний месяц статус рассчитан.';
									|en = 'The status is calculated for %1 authorization letters for the last month.'; fa = 'The status is calculated for %1 authorization letters for the last month.';
									|it = 'Per %1 deleghe per ultimo mese è calcolato lo stato.';
									|pl = 'Dla %1 pełnomocnictw za ostatni miesiąc status jest rozliczony.';
									|tr = 'Geçen aya ait %1yetki belgesi için durum hesaplandı'");
				MessageText = StrTemplate(MessageText, ProcessedItemsCount);
			EndIf;
		Else
			MessageText = NStr("vi = 'Đối với %1 của %2 trong số các thư ủy quyền được chọn trong danh sách, trạng thái được tính.';
								|ru = 'Для %1 из %2 выделенных в списке доверенностей статус рассчитан.';
								|en = 'Status is calculated for %1 from %2 authorization letters selected in the list.'; fa = 'Status is calculated for %1 from %2 authorization letters selected in the list.';
								|it = 'Per %1 di %2 deleghe selezionate nell''elenco delle deleghe è calcolato lo stato.';
								|pl = 'Dla %1 z %2 wybranych w liście pełnomocnictw status jest rozliczony.';
								|tr = 'Yetki belgesi listesinde vurgulanan ""%2""nin ""%1""sı için durum belirlendi.'");
			MessageText = StrTemplate(MessageText, ProcessedItemsCount, TotalCount1);
		EndIf;
	Else
		MessageText = NStr("vi = 'Trạng thái này không được tính cho bất kỳ giấy ủy quyền.';
							|ru = 'Статус не рассчитан ни для одной доверенности.';
							|en = 'Status is not calculated for authorization letters.'; fa = 'Status is not calculated for authorization letters.';
							|it = 'Lo stato non è calcolato per alcuna delega.';
							|pl = 'Nie rozliczono statusu ani dla jednego pełnomocnictwa.';
							|tr = 'Hiçbir yetki belgesi için durum hesaplanmadı.'");
	EndIf;
	
	CommonClientServer.MessageToUser(MessageText);
EndProcedure

&AtClient
Procedure CreateBackgroundTaskStatusCalculation()

	Items.ListLettersOfAuthorityToCalculateStatus.Title = NStr("vi = 'Đang tính toán ...';
																|ru = 'Идет расчет...';
																|en = 'Calculating...'; fa = 'Calculating...';
																|it = 'Calcolo in corso...';
																|pl = 'Trwa rozliczenie...';
																|tr = 'Hesaplanıyor...'");
	BackgroundJob = CreateBackgroundJobOnServer(SelectedDocuments.UnloadValues(), UUID);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackOnCompletion = New CallbackDescription("TaskCalculationOfStatusesNotification", ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(
		BackgroundJob, CallbackOnCompletion, IdleParameters);
		
EndProcedure

&AtClient
Procedure TaskCalculationOfStatusesNotification(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		ProcessCompletionOfStatusCalculation(Result.ResultAddress);
		Items.ListLettersOfAuthorityToCalculateStatus.Title = NStr("vi = 'Tính trạng thái';
																	|ru = 'Рассчитать статус';
																	|en = 'Calculate status'; fa = 'محاسبه وضعیت';
																	|it = 'Calcolare lo stato';
																	|pl = 'Rozlicz status';
																	|tr = 'Durumu hesapla'");
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CreateBackgroundJobOnServer(DocumentsArray, UUID)
	
	MethodParameters = New Structure();
	MethodParameters.Insert("DocumentsArray", DocumentsArray);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tính toán tình trạng quyền hạn của luật sư trong nền';
														|ru = 'Расчет статусов доверенностей в фоне';
														|en = 'Calculate statuses of authorization letters in the background'; fa = 'Calculate statuses of authorization letters in the background';
														|it = 'Calcolo di stati deleghe in background';
														|pl = 'Rozliczenie statusów pełnomocnictw w tle';
														|tr = 'Yetki belgelerinin arka plandaki durumunun hesaplanması'");
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground("Documents.IssuedLetterOfAuthority.CalculateStatusOfPowersOfAttorney",
		MethodParameters, ExecutionParameters);
	
	Return BackgroundJob;
EndFunction

#EndRegion

#EndRegion
